import Cocoa
import Carbon

/// Carbon hotkeys keep the emergency shortcuts available without Accessibility access.
final class HotKeyManager {
    private var handler: EventHandlerRef?
    private var keys: [EventHotKeyRef] = []
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
            if id.id == 1 { manager.toggle() } else if id.id == 2 { manager.presentation() }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handler)
        for (id, code) in [(UInt32(1), UInt32(kVK_ANSI_P)), (UInt32(2), UInt32(kVK_ANSI_T))] {
            var key: EventHotKeyRef?
            if RegisterEventHotKey(code, UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x54505059, id: id),
                                   GetApplicationEventTarget(), 0, &key) == noErr, let key { keys.append(key) }
        }
    }
    deinit { keys.forEach { UnregisterEventHotKey($0) }; if let handler { RemoveEventHandler(handler) } }
}
