import Cocoa
import SwiftUI
import ApplicationServices

final class CursorOverlayWindow: NSWindow, ObservableObject {
    let cursorState = CursorState()
    @Published private(set) var isActive = false
    @Published private(set) var presentationMode = false
    private var trackingTimer: Timer?
    private var clickMonitor: Any?
    private var localMonitor: Any?
    private var eventTap: CFMachPort?
    private var tapSource: CFRunLoopSource?
    private var cursorHidden = false
    var onChange: (() -> Void)?

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init() {
        let frame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.cursorWindow)))
        backgroundColor = .clear; isOpaque = false; hasShadow = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        let view = NSHostingView(rootView: CursorView(state: cursorState))
        view.frame = NSRect(origin: .zero, size: frame.size)
        view.autoresizingMask = [.width, .height]
        contentView = view
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspend), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspend), name: NSWorkspace.willSleepNotification, object: nil)
    }

    func toggle() { isActive ? deactivate() : activate() }
    func activate() {
        guard !isActive else { return }
        isActive = true
        updateCursorPosition()
        orderFrontRegardless()
        startTracking()
        if !cursorHidden { CGDisplayHideCursor(CGMainDisplayID()); cursorHidden = true }
        onChange?()
    }
    func deactivate() {
        setPresentation(false)
        isActive = false
        orderOut(nil)
        trackingTimer?.invalidate(); trackingTimer = nil
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }; clickMonitor = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }; localMonitor = nil
        if cursorHidden { CGDisplayShowCursor(CGMainDisplayID()); cursorHidden = false }
        cursorState.reset()
        onChange?()
    }
    @objc private func suspend() { deactivate() }

    @discardableResult
    func setPresentation(_ enabled: Bool) -> Bool {
        if !enabled {
            presentationMode = false
            if let eventTap { CGEvent.tapEnable(tap: eventTap, enable: false) }
            if let tapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), tapSource, .commonModes) }
            if let eventTap { CFMachPortInvalidate(eventTap) }
            eventTap = nil; tapSource = nil
            onChange?()
            return true
        }
        guard !presentationMode else { return true }
        guard Self.accessibilityEnabled() else { return false }
        let types: [CGEventType] = [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
                                   .otherMouseDown, .otherMouseUp, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask, callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let overlay = Unmanaged<CursorOverlayWindow>.fromOpaque(context).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    // Fail open: a disabled tap must never leave the UI claiming clicks are protected.
                    DispatchQueue.main.async { overlay.setPresentation(false) }
                    return Unmanaged.passUnretained(event)
                }
                guard overlay.presentationMode else { return Unmanaged.passUnretained(event) }
                if type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown { overlay.tap() }
                return nil
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        eventTap = tap
        tapSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let tapSource { CFRunLoopAddSource(CFRunLoopGetMain(), tapSource, .commonModes) }
        presentationMode = true
        activate()
        CGEvent.tapEnable(tap: tap, enable: true)
        onChange?()
        return true
    }

    private func tap() {
        updateCursorPosition()
        let energy = cursorState.tap(settings: .shared)
        SoundManager.shared.playKnock(energy: energy)
    }
    private func startTracking() {
        let timer = Timer(timeInterval: 1.0 / 90, repeats: true) { [weak self] _ in
            self?.updateCursorPosition(); self?.cursorState.tick()
        }
        timer.tolerance = 0.002
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
        // Mouse-only monitors work without requesting keyboard monitoring permissions.
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            guard self?.presentationMode == false else { return }; self?.tap()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard self?.presentationMode == false else { return event }; self?.tap(); return event
        }
    }
    private func updateCursorPosition() {
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main else { return }
        if frame != screen.frame { setFrame(screen.frame, display: false) }
        cursorState.move(to: Self.localPosition(point, frame: screen.frame))
    }
    static func localPosition(_ point: NSPoint, frame: NSRect) -> CGPoint {
        CGPoint(x: point.x - frame.minX, y: frame.maxY - point.y)
    }
    static func accessibilityEnabled() -> Bool { AXIsProcessTrusted() }
    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
