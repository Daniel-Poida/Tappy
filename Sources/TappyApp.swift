import Cocoa
import SwiftUI

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
    private var hotKey: HotKeyManager?
    private var prefsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        overlay = CursorOverlayWindow()
        overlay.onChange = { [weak self] in self?.updateMenu() }
        setupMenuBar()
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
        let title = NSMenuItem(title: "Tappy 1.1", action: nil, keyEquivalent: "")
        menu.addItem(title); menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Enable Tappy", action: #selector(toggle), keyEquivalent: "p"))
        menu.item(at: 2)?.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(NSMenuItem(title: "Presentation Mode", action: #selector(togglePresentationMode), keyEquivalent: "t"))
        menu.item(at: 3)?.keyEquivalentModifierMask = [.control, .option]
        menu.addItem(.separator())
        let styles = NSMenu(title: "Character")
        for (index, style) in PointerStyle.allCases.enumerated() {
            let item = NSMenuItem(title: style.title, action: #selector(selectStyle(_:)), keyEquivalent: "")
            item.tag = index; item.target = self; styles.addItem(item)
        }
        let character = NSMenuItem(title: "Character", action: nil, keyEquivalent: ""); character.submenu = styles; menu.addItem(character)
        menu.addItem(NSMenuItem(title: "Sound on Tap", action: #selector(toggleSound), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Tappy", action: #selector(quit), keyEquivalent: "q"))
        for item in menu.items where item.action != nil { item.target = self }
        statusItem?.menu = menu
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenu), name: UserDefaults.didChangeNotification, object: nil)
        updateMenu()
    }
    @objc private func toggle() { overlay.toggle() }
    @objc private func togglePresentationMode() {
        if !overlay.setPresentation(!overlay.presentationMode) {
            showPreferences()
            let alert = NSAlert()
            alert.messageText = "Allow Accessibility for Presentation Mode"
            alert.informativeText = "Tappy needs Accessibility to prevent clicks reaching other apps. Enable it in System Settings, then press ⌃⌥T again. ⌃⌥T also exits presentation mode; ⌃⌥P disables Tappy."
            alert.addButton(withTitle: "Open Settings"); alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn { CursorOverlayWindow.requestAccessibility() }
        }
    }
    @objc private func selectStyle(_ sender: NSMenuItem) { TappySettings.shared.pointerStyle = PointerStyle.allCases[sender.tag]; updateMenu() }
    @objc private func toggleSound() { TappySettings.shared.soundEnabled.toggle(); updateMenu() }
    @objc private func updateMenu() {
        guard let overlay, let menu = statusItem?.menu else { return }
        statusItem?.button?.image = AssetExporter.menuIcon(active: overlay.isActive, presentation: overlay.presentationMode)
        statusItem?.button?.toolTip = "Tappy 1.1 · \(overlay.isActive ? "On" : "Off") · ⌃⌥P"
        menu.item(at: 2)?.title = overlay.isActive ? "Disable Tappy" : "Enable Tappy"
        menu.item(at: 2)?.state = overlay.isActive ? .on : .off
        menu.item(at: 3)?.state = overlay.presentationMode ? .on : .off
        menu.item(at: 6)?.state = TappySettings.shared.soundEnabled ? .on : .off
        for item in menu.item(at: 5)?.submenu?.items ?? [] {
            item.state = PointerStyle.allCases[item.tag] == TappySettings.shared.pointerStyle ? .on : .off
        }
    }
    @objc private func showPreferences() {
        if prefsWindow == nil {
            let view = PreferencesView(overlay: overlay)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 751, height: 727),
                                  styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
            window.title = "Tappy"
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: view.padding(.top, 24).background(Color(red: 0.97, green: 0.97, blue: 0.94)))
            window.setContentSize(NSSize(width: 751, height: 751))
            window.center(); prefsWindow = window
        }
        prefsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc private func quit() { overlay.deactivate(); NSApp.terminate(nil) }
}
