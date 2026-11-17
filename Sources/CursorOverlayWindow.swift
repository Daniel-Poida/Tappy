import Cocoa
import SwiftUI
import CoreGraphics

class CursorOverlayWindow: NSWindow {
    private var cursorView = CursorView()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var trackingTimer: Timer?

    private static weak var sharedInstance: CursorOverlayWindow?

    var isActive: Bool = false

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
        // Timer-based fallback: works without Accessibility
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateCursorPosition()
        }
        trackingTimer?.tolerance = 1.0 / 120.0

        // Try to set up a CGEvent tap for click detection (requires Accessibility)
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)

        if let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                CursorOverlayWindow.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: nil
        ) {
            eventTap = tap
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            if let source = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            }
            CGEvent.tapEnable(tap: tap, enable: true)
        } else {
            // Fallback click monitor (may also require Accessibility, but try anyway)
            NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.cursorView.tap()
                SoundManager.shared.playKnock()
            }
        }
    }

    private func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    private func updateCursorPosition() {
        let mouseLocation = NSEvent.mouseLocation

        // Find which screen the cursor is on and move the window there
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
        // NSEvent.mouseLocation uses bottom-left origin relative to the full desktop.
        // SwiftUI .position inside the overlay window uses top-left origin.
        let windowY = screen.frame.height - (point.y - screen.frame.origin.y)
        let windowX = point.x - screen.frame.origin.x
        return CGPoint(x: windowX, y: windowY)
    }

    private static func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .leftMouseDown || type == .rightMouseDown {
            DispatchQueue.main.async {
                sharedInstance?.cursorView.tap()
                SoundManager.shared.playKnock()
            }
        }
        return Unmanaged.passUnretained(event)
    }
}
