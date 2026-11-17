import Cocoa
import SwiftUI

@main
struct TappyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlay: CursorOverlayWindow?
    private var statusItem: NSStatusItem?
    private var hotKey: HotKeyManager?
    private var prefsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        overlay = CursorOverlayWindow()
        setupMenuBar()
        hotKey = HotKeyManager { [weak self] in
            self?.toggle()
        }

        toggle()
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlay?.deactivate()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "hand.point.up.fill", accessibilityDescription: "Tappy")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Tappy", action: #selector(toggle), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func toggle() {
        overlay?.toggle()
        updateIcon()
    }

    private func updateIcon() {
        let active = overlay?.isActive ?? false
        statusItem?.button?.image = NSImage(systemSymbolName: active ? "hand.point.up.fill" : "hand.raised.slash.fill",
                                            accessibilityDescription: active ? "Tappy active" : "Tappy inactive")
    }

    @objc private func showPreferences() {
        if prefsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
                                  styleMask: [.titled, .closable],
                                  backing: .buffered,
                                  defer: false)
            window.title = "Tappy Preferences"
            window.center()
            window.contentView = NSHostingView(rootView: PreferencesView())
            prefsWindow = window
        }
        prefsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        overlay?.deactivate()
        NSApplication.shared.terminate(nil)
    }
}

struct PreferencesView: View {
    @StateObject private var settings = TappySettings.shared

    var body: some View {
        Form {
            Section {
                Picker("Pointer style", selection: $settings.pointerStyle) {
                    ForEach(PointerStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section {
                VStack(alignment: .leading) {
                    Text("Pointer mood")
                    HStack {
                        Text("Shy finger")
                        Slider(value: $settings.mood, in: 0...1)
                        Text("In your face")
                    }
                }
            }

            Section {
                Toggle("Animate on click", isOn: $settings.animateOnClick)
                Toggle("Play knock sound", isOn: $settings.soundEnabled)
            }

            Section {
                HStack {
                    Text("Toggle hotkey")
                    Spacer()
                    Text("⌃⌥P")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 320, height: 280)
    }
}
