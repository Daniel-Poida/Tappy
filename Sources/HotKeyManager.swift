import Cocoa
import CoreGraphics

class HotKeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private static var action: (() -> Void)?

    init(action: @escaping () -> Void) {
        HotKeyManager.action = action

        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                HotKeyManager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: nil
        ) else { return }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    private static func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        let control = flags.contains(.maskControl)
        let option = flags.contains(.maskAlternate)
        let pKey: Int64 = 35 // Virtual keycode for "P" on ANSI keyboards

        if control && option && keyCode == pKey {
            DispatchQueue.main.async {
                action?()
            }
            return nil // Suppress the original event
        }

        return Unmanaged.passUnretained(event)
    }
}
