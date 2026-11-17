import Cocoa
import SwiftUI
import CoreGraphics
import ApplicationServices

class CursorOverlayWindow: NSWindow {
    private var cursorView = CursorView()
    private var trackingTimer: Timer?
    private var clickMonitor: Any?

    private static weak var sharedInstance: CursorOverlayWindow?

    var isActive: Bool = false
    var presentationMode: Bool = false {
        didSet {
            ignoresMouseEvents = !presentationMode
        }
    }

    init() {
        let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        super.init(contentRect: frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)

        CursorOverlayWindow.sharedInstance = self

        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.cursorWindow)))
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: cursorView)
        hostingView.frame = frame
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView
    }

    func toggle() {
        isActive.toggle()
        if isActive {
            updateFrameForCursor()
            makeKeyAndOrderFront(nil)
            orderFrontRegardless()
            startTracking()
            hideSystemCursor()
        } else {
            orderOut(nil)
            stopTracking()
            showSystemCursor()
        }
    }

    func deactivate() {
        isActive = false
        orderOut(nil)
        stopTracking()
        showSystemCursor()
    }

    private func updateFrameForCursor() {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let frame = screen?.frame {
            setFrame(frame, display: true)
        }
    }

    private func hideSystemCursor() {
        CGDisplayHideCursor(CGMainDisplayID())
    }

    private func showSystemCursor() {
        CGDisplayShowCursor(CGMainDisplayID())
    }

    private func startTracking() {
        // Timer-based cursor tracking: works without Accessibility
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateCursorPosition()
        }
        trackingTimer?.tolerance = 1.0 / 120.0

        // Global click monitor: requires Accessibility, but won't show a dialog if denied
        if CursorOverlayWindow.accessibilityEnabled() {
            clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.cursorView.tap()
                SoundManager.shared.playKnock()
            }
        }
    }

    private func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil

        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    private func updateCursorPosition() {
        let mouseLocation = NSEvent.mouseLocation

        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
            if self.frame != screen.frame {
                setFrame(screen.frame, display: false)
            }
            let converted = convertToWindowCoordinates(mouseLocation, screen: screen)
            cursorView.move(to: converted)
        } else if let screen = NSScreen.main {
            let converted = convertToWindowCoordinates(mouseLocation, screen: screen)
            cursorView.move(to: converted)
        }
    }

    private func convertToWindowCoordinates(_ point: NSPoint, screen: NSScreen) -> CGPoint {
        let windowY = screen.frame.height - (point.y - screen.frame.origin.y)
        let windowX = point.x - screen.frame.origin.x
        return CGPoint(x: windowX, y: windowY)
    }

    // MARK: - Presentation Mode

    override func mouseDown(with event: NSEvent) {
        if presentationMode {
            cursorView.tap()
            SoundManager.shared.playKnock()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        if presentationMode {
            cursorView.tap()
            SoundManager.shared.playKnock()
        }
    }

    // MARK: - Accessibility

    static func accessibilityEnabled() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
