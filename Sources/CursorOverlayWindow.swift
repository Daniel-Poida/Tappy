import Cocoa
import SwiftUI

final class CursorOverlayWindow: NSWindow, ObservableObject {
    private static weak var activeOverlay: CursorOverlayWindow?
    private let surface = CursorOverlayView(frame: .zero)
    let cursorState = CursorState()
    @Published private(set) var isActive = false
    @Published private(set) var presentationMode = false
    private var trackingTimer: Timer?
    private var clickMonitor: Any?
    private var localMonitor: Any?
    private var cursorRefreshPending = false
    private var presentationShields: [PresentationShieldWindow] = []
    private let systemCursor = SystemCursorController()
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
        surface.frame = NSRect(origin: .zero, size: frame.size)
        surface.autoresizingMask = [.width, .height]
        contentView = surface
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspend), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(suspend), name: NSWorkspace.willSleepNotification, object: nil)
        for name in [NSWorkspace.didActivateApplicationNotification, NSWorkspace.activeSpaceDidChangeNotification, NSWorkspace.screensDidWakeNotification] {
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(cursorContextChanged), name: name, object: nil)
        }
        for name in [NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(cursorContextChanged), name: name, object: nil)
        }
    }

    func toggle() { isActive ? deactivate() : activate() }
    func activate() {
        guard !isActive else { return }
        Self.activeOverlay?.deactivate()
        Self.activeOverlay = self
        isActive = true
        updateCursorPosition()
        surface.update(state: cursorState, settings: .shared)
        orderFrontRegardless()
        startTracking()
        systemCursor.setHidden(true)
        onChange?()
    }
    func deactivate() {
        setPresentation(false)
        isActive = false
        if Self.activeOverlay === self { Self.activeOverlay = nil }
        surface.reset()
        orderOut(nil)
        trackingTimer?.invalidate(); trackingTimer = nil
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }; clickMonitor = nil
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }; localMonitor = nil
        systemCursor.setHidden(false)
        cursorState.reset()
        onChange?()
    }
    @objc private func suspend() { deactivate() }
    @objc private func cursorContextChanged() { systemCursor.refresh(force: true) }

    @discardableResult
    func setPresentation(_ enabled: Bool) -> Bool {
        guard enabled != presentationMode else { return true }
        if !enabled {
            presentationMode = false
            presentationShields.forEach { $0.orderOut(nil) }
            presentationShields.removeAll()
            onChange?()
            return true
        }
        guard !NSScreen.screens.isEmpty else { return false }
        activate()
        rebuildPresentationShields()
        presentationMode = !presentationShields.isEmpty
        onChange?()
        return presentationMode
    }

    private func rebuildPresentationShields() {
        let next = NSScreen.screens.map { screen in
            PresentationShieldWindow(screen: screen, onRelease: { [weak self] button in
                self?.cursorState.release(button: button)
            }) { [weak self] button in self?.tap(button: button) }
        }
        next.forEach { $0.orderFrontRegardless() }
        presentationShields.forEach { $0.orderOut(nil) }
        presentationShields = next
        orderFrontRegardless()
    }
    @objc private func screensChanged() {
        if presentationMode {
            rebuildPresentationShields()
            presentationMode = !presentationShields.isEmpty
            onChange?()
        }
        if isActive {
            updateCursorPosition()
            surface.update(state: cursorState, settings: .shared)
            systemCursor.refresh(force: true)
        }
    }

    private func tap(button: PointerButton = .primary) {
        updateCursorPosition()
        let energy = cursorState.tap(settings: .shared, button: button,
                                     reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        SoundManager.shared.playKnock(energy: energy)
        surface.update(state: cursorState, settings: .shared)
    }
    private func startTracking() {
        let timer = Timer(timeInterval: 1.0 / 90, repeats: true) { [weak self] _ in
            let moved = self?.updateCursorPosition() ?? false
            self?.systemCursor.refresh(cursorMoved: moved)
            self?.cursorState.tick(systemIdle: InputIdleTime.seconds,
                                    reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
                                    secondaryDown: CGEventSource.buttonState(.combinedSessionState, button: .right))
            if let self { self.surface.update(state: self.cursorState, settings: .shared) }
        }
        timer.tolerance = 0.002
        RunLoop.main.add(timer, forMode: .common)
        trackingTimer = timer
        // Mouse-only monitoring does not request keyboard/Accessibility access.
        let buttons: Set<NSEvent.EventType> = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        let releases: Set<NSEvent.EventType> = [.leftMouseUp, .rightMouseUp, .otherMouseUp]
        let events: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown,
            .leftMouseUp, .rightMouseUp, .otherMouseUp,
            .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel]
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: events) { [weak self] event in
            guard let self else { return }
            self.reassertCursorAfterMouseEvent()
            if !self.presentationMode {
                if buttons.contains(event.type) { self.tap(button: PointerButton(event: event)) }
                if releases.contains(event.type) { self.cursorState.release(button: PointerButton(event: event)) }
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: events) { [weak self] event in
            guard let self else { return event }
            self.reassertCursorAfterMouseEvent()
            if !self.presentationMode {
                if buttons.contains(event.type) { self.tap(button: PointerButton(event: event)) }
                if releases.contains(event.type) { self.cursorState.release(button: PointerButton(event: event)) }
            }
            return event
        }
    }
    private func reassertCursorAfterMouseEvent() {
        guard isActive, !cursorRefreshPending else { return }
        cursorRefreshPending = true
        // Coalesce events and reassert after the current cursor-owner update,
        // without showing a second frame or accumulating hide requests.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.cursorRefreshPending = false
            guard self.isActive else { return }
            self.systemCursor.refresh(force: true)
        }
    }

    @discardableResult private func updateCursorPosition() -> Bool {
        let point = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main else { return false }
        let next = Self.localPosition(point, frame: screen.frame)
        let moved = frame != screen.frame || hypot(next.x - cursorState.position.x, next.y - cursorState.position.y) > 0.01
        if frame != screen.frame { setFrame(screen.frame, display: false) }
        cursorState.move(to: next, canvas: screen.frame.size)
        return moved
    }
    static func localPosition(_ point: NSPoint, frame: NSRect) -> CGPoint {
        CGPoint(x: point.x - frame.minX, y: frame.maxY - point.y)
    }
}
