import Cocoa
import SwiftUI
import CoreGraphics

class CursorOverlayWindow: NSWindow {
    private var cursorView = CursorView()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

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
            setFrame(NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080), display: true)
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

    private func hideSystemCursor() {
        CGDisplayHideCursor(CGMainDisplayID())
    }

    private func showSystemCursor() {
        CGDisplayShowCursor(CGMainDisplayID())
    }

    private func startTracking() {
        guard eventTap == nil else { return }

        let eventMask = (1 << CGEventType.mouseMoved.rawValue)
            | (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.rightMouseDragged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                CursorOverlayWindow.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: nil
        ) else {
            DispatchQueue.main.async {
                self.showPermissionsAlert()
            }
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func stopTracking() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    private func showPermissionsAlert() {
        let alert = NSAlert()
        alert.messageText = "Tappy needs Accessibility access"
        alert.informativeText = "To track your cursor and clicks across the screen, Tappy needs Accessibility permissions. Please enable it in System Settings → Privacy & Security → Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    private static func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .mouseMoved, .leftMouseDragged, .rightMouseDragged:
            let point = event.location
            DispatchQueue.main.async {
                sharedInstance?.cursorView.move(to: CGPoint(x: point.x, y: point.y))
            }
            return Unmanaged.passUnretained(event)
        case .leftMouseDown, .rightMouseDown:
            DispatchQueue.main.async {
                sharedInstance?.cursorView.tap()
                SoundManager.shared.playKnock()
            }
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
    }
}
