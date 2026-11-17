import Cocoa
import SwiftUI
import Combine

@main @MainActor
enum TappyMain {
    static func main() {
        if let index = CommandLine.arguments.firstIndex(of: "--export-assets"), CommandLine.arguments.count > index + 1 {
            do { try AssetExporter.export(to: CommandLine.arguments[index + 1]) }
            catch { fputs("Asset export failed: \(error)\n", stderr); exit(1) }
            return
        }
        TappyApp.main()
    }
}

struct TappyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings { EmptyView() } }
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: CursorOverlayWindow!
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var statusMenuController: StatusMenuController?
    private var soundMenuItem: NSMenuItem?
    private var hotKey: HotKeyManager?
    private var prefsWindow: NSWindow?
    private var appearanceObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlay = CursorOverlayWindow()
        overlay.onChange = { [weak self] in self?.updateMenu() }
        setupMenuBar()
        appearanceObserver = TappySettings.shared.$theme.removeDuplicates().sink { [weak self] theme in
            NSApp.appearance = theme.appearance
            self?.prefsWindow?.appearance = theme.appearance
            self?.updateMenu()
        }
        hotKey = HotKeyManager(toggle: { [weak self] in self?.toggle() }, presentation: { [weak self] in self?.togglePresentationMode() })
        _ = SoundManager.shared
        showPreferences()
    }
    func applicationWillTerminate(_ notification: Notification) { overlay?.deactivate() }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPreferences(); return false
    }
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        let title = NSMenuItem(title: "Tappy \(AppVersion.short)", action: nil, keyEquivalent: "")
        menu.addItem(title); menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Enable Tappy", action: #selector(toggle), keyEquivalent: "p"))
        menu.item(at: 2)?.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(NSMenuItem(title: "Presentation Mode", action: #selector(togglePresentationMode), keyEquivalent: "t"))
        menu.item(at: 3)?.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(.separator())
        let sound = NSMenuItem(title: "Sound on Tap", action: #selector(toggleSound), keyEquivalent: "")
        soundMenuItem = sound; menu.addItem(sound)
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Tappy", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items where item.action != nil { item.target = self }
        statusMenu = menu
        if let button = statusItem?.button { statusMenuController = StatusMenuController(button: button, menu: menu) }
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenu), name: UserDefaults.didChangeNotification, object: nil)
        updateMenu()
    }
    @objc private func toggle() { overlay.toggle() }
    @objc private func togglePresentationMode() {
        overlay.setPresentation(!overlay.presentationMode)
    }
    @objc private func toggleSound() { TappySettings.shared.soundEnabled.toggle(); updateMenu() }
    @objc private func updateMenu() {
        guard let overlay, let menu = statusMenu else { return }
        statusItem?.button?.image = AssetExporter.menuIcon(active: overlay.isActive, presentation: overlay.presentationMode)
        statusItem?.button?.toolTip = "Tappy \(AppVersion.short) · \(overlay.isActive ? "On" : "Off") · ⌃⌥P"
        menu.item(at: 2)?.title = overlay.isActive ? "Disable Tappy" : "Enable Tappy"
        menu.item(at: 2)?.state = overlay.isActive ? .on : .off
        menu.item(at: 3)?.state = overlay.presentationMode ? .on : .off
        soundMenuItem?.state = TappySettings.shared.soundEnabled ? .on : .off
    }
    @objc private func showPreferences() {
        if prefsWindow == nil {
            let view = PreferencesView(overlay: overlay)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 751, height: 727),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "Tappy"
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.appearance = TappySettings.shared.theme.appearance
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: view)
            window.setContentSize(NSSize(width: 751, height: 727))
            window.center(); prefsWindow = window
        }
        prefsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc private func quit() { overlay.deactivate(); NSApp.terminate(nil) }
}
