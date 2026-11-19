import Cocoa

/// A non-activating mouse shield preserves the presenter's keyboard focus.
/// Mouse interception is performed by our own windows, so no Accessibility
/// permission check or permission prompt is necessary when toggling the mode.
final class PresentationShieldWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(screen: NSScreen, onRelease: @escaping (PointerButton) -> Void = { _ in }, onTap: @escaping (PointerButton) -> Void) {
        super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.cursorWindow)) - 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        contentView = PresentationShieldView(frame: NSRect(origin: .zero, size: screen.frame.size), onRelease: onRelease, onTap: onTap)
    }
}

final class PresentationShieldView: NSView {
    let onTap: (PointerButton) -> Void
    let onRelease: (PointerButton) -> Void
    init(frame: NSRect, onRelease: @escaping (PointerButton) -> Void = { _ in }, onTap: @escaping (PointerButton) -> Void) {
        self.onTap = onTap; self.onRelease = onRelease; super.init(frame: frame)
    }
    required init?(coder: NSCoder) { nil }
    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func accessibilityPerformPress() -> Bool {
        guard accessibilityRole() == .button else { return false }
        onTap(.primary); onRelease(.primary)
        return true
    }
    override func hitTest(_ point: NSPoint) -> NSView? { bounds.contains(point) ? self : nil }
    override func mouseDown(with event: NSEvent) { onTap(.primary) }
    override func rightMouseDown(with event: NSEvent) { onTap(.secondary) }
    override func otherMouseDown(with event: NSEvent) { onTap(.other) }
    override func mouseUp(with event: NSEvent) { onRelease(.primary) }
    override func rightMouseUp(with event: NSEvent) { onRelease(.secondary) }
    override func otherMouseUp(with event: NSEvent) { onRelease(.other) }
    override func mouseDragged(with event: NSEvent) {}
    override func rightMouseDragged(with event: NSEvent) {}
    override func otherMouseDragged(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {}
    override func pressureChange(with event: NSEvent) {}
}
