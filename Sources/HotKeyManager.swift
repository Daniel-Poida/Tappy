import Cocoa
import Carbon

/// Carbon hotkeys keep the emergency shortcuts available without Accessibility access.
final class HotKeyManager {
    private var handler: EventHandlerRef?
    private var keys: [EventHotKeyRef] = []
    private var localMonitor: Any?
    private var lastInvocation: [UInt32: TimeInterval] = [:]
    private let toggle: () -> Void
    private let presentation: () -> Void

    init(toggle: @escaping () -> Void, presentation: @escaping () -> Void) {
        self.toggle = toggle; self.presentation = presentation
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, context in
            guard let event, let context else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(context).takeUnretainedValue()
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            manager.invoke(id.id)
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        for (id, code) in [(UInt32(1), UInt32(kVK_ANSI_P)), (UInt32(2), UInt32(kVK_ANSI_T))] {
            var key: EventHotKeyRef?
            if RegisterEventHotKey(code, UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x54505059, id: id),
                                   GetApplicationEventTarget(), 0, &key) == noErr, let key { keys.append(key) }
        }
        // App-targeted keyboard events (including accessibility automation) do not
        // pass through Carbon's global hotkey dispatch. Handle these locally too.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags
            guard flags.contains(.control), flags.contains(.option),
                  !flags.contains(.command), !flags.contains(.shift),
                  event.keyCode == kVK_ANSI_P || event.keyCode == kVK_ANSI_T else { return event }
            if !event.isARepeat { self?.invoke(event.keyCode == kVK_ANSI_P ? 1 : 2) }
            return nil
        }
    }
    private func invoke(_ id: UInt32) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastInvocation[id, default: -1] > 0.2 else { return }
        lastInvocation[id] = now
        if id == 1 { toggle() } else if id == 2 { presentation() }
    }
    deinit {
        keys.forEach { UnregisterEventHotKey($0) }
        if let handler { RemoveEventHandler(handler) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }
}
