import Cocoa

/// Explicit tracking lets a second press on the status icon dismiss the menu.
@MainActor final class StatusMenuController: NSObject, NSMenuDelegate {
    private weak var button: NSStatusBarButton?
    private let menu: NSMenu
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private(set) var isOpen = false
    private var ignorePressUntil = 0.0

    init(button: NSStatusBarButton, menu: NSMenu) {
        self.button = button; self.menu = menu
        super.init()
        button.target = self
        button.action = #selector(toggleMenu)
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        menu.delegate = self
    }
    @objc private func toggleMenu() {
        // AppKit can forward the same status-button press after menu tracking
        // has ended. Do not let that press immediately reopen the menu.
        guard ProcessInfo.processInfo.systemUptime >= ignorePressUntil else { return }
        if isOpen { menu.cancelTrackingWithoutAnimation(); return }
        guard let button else { return }
        button.highlight(true)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY - 5), in: button)
        button.highlight(false)
        stopMonitoring()
        isOpen = false
    }
    func menuWillOpen(_ menu: NSMenu) {
        isOpen = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.isOpen, self.pointerIsOverButton else { return event }
            self.dismissFromStatusPress()
            return nil
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.isOpen, self.pointerIsOverButton else { return }
            self.dismissFromStatusPress()
        }
    }
    private func dismissFromStatusPress() {
        ignorePressUntil = ProcessInfo.processInfo.systemUptime + 0.15
        menu.cancelTrackingWithoutAnimation()
    }
    func menuDidClose(_ menu: NSMenu) {
        isOpen = false
        button?.highlight(false)
        stopMonitoring()
    }
    private var pointerIsOverButton: Bool {
        guard let button, let window = button.window else { return false }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        return frame.contains(NSEvent.mouseLocation)
    }
    private func stopMonitoring() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }; localMonitor = nil
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }; globalMonitor = nil
    }
}
