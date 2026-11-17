import SwiftUI

private let mint = Color(red: 0.38, green: 0.86, blue: 0.69)
private let ink = Color(red: 0.12, green: 0.16, blue: 0.18)

struct PreferencesView: View {
    @ObservedObject private var settings = TappySettings.shared
    @ObservedObject var overlay: CursorOverlayWindow
    @StateObject private var preview = CursorState()
    @State private var background = "Split"
    @State private var accessMessage = false
    let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PointerArtwork(shadow: false).frame(width: 30, height: 42)
                Text("tappy").font(.system(size: 28, weight: .heavy, design: .rounded)).tracking(-1)
                Text("1.1").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 7).padding(.vertical, 4).background(ink.opacity(0.07), in: Capsule())
                Spacer()
                HStack(spacing: 7) {
                    Circle().fill(overlay.isActive ? mint : .gray).frame(width: 7, height: 7)
                    Text(overlay.isActive ? "On stage" : "Taking a break").font(.system(size: 12, weight: .medium))
                    Toggle("Enable Tappy", isOn: Binding(get: { overlay.isActive }, set: { $0 ? overlay.activate() : overlay.deactivate() }))
                        .labelsHidden().toggleStyle(.switch).tint(mint)
                }
            }.padding(.horizontal, 26).padding(.vertical, 16)
            Rectangle().fill(ink.opacity(0.08)).frame(height: 1)
            HStack(alignment: .top, spacing: 26) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Small cursor.\nMain character energy.")
                        .font(.system(size: 26, weight: .bold, design: .rounded)).tracking(-0.7).lineSpacing(1)
                    Text("Give every click a little personality.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                    previewStage
                    HStack {
                        Text("TRY IT OUT").font(.system(size: 10, weight: .bold)).tracking(1)
                        Spacer()
                        Text("Click faster. Get louder.").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<20) { i in
                            Capsule().fill(Double(i) / 20 < preview.energy ? mint : ink.opacity(0.09)).frame(height: 5)
                        }
                    }.accessibilityLabel("Click energy").accessibilityValue("\(Int(preview.energy * 100)) percent")
                    Picker("Preview background", selection: $background) {
                        Text("Light").tag("Light"); Text("Split").tag("Split"); Text("Dark").tag("Dark")
                    }.pickerStyle(.segmented)
                }.frame(width: 290)
                VStack(alignment: .leading, spacing: 18) {
                    sectionTitle("01", "Pick your character")
                    HStack(spacing: 7) {
                        ForEach(PointerStyle.allCases) { style in
                            Button {
                                settings.pointerStyle = style
                                preview.reset()
                                previewTap()
                            } label: {
                                VStack(spacing: 5) {
                                    PointerArtwork(style: style, shadow: false).frame(width: 53, height: 74)
                                    Text(style.title).font(.system(size: 10, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 9)
                                .background(settings.pointerStyle == style ? mint.opacity(0.18) : Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(settings.pointerStyle == style ? mint.opacity(0.95) : ink.opacity(0.1), lineWidth: settings.pointerStyle == style ? 2 : 1))
                            }.buttonStyle(.plain).accessibilityLabel(style.title)
                                .accessibilityAddTraits(settings.pointerStyle == style ? .isSelected : [])
                        }
                    }
                    HStack {
                        Text(settings.pointerStyle.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
                        Spacer(minLength: 2)
                    }
                    divider
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("02", "Set the energy")
                        HStack {
                            Text("Tap personality").font(.system(size: 12, weight: .medium))
                            Spacer(); Text(moodLabel).font(.system(size: 11, weight: .semibold)).foregroundStyle(ink.opacity(0.6))
                        }
                        Slider(value: $settings.mood, in: 0...1).tint(mint).accessibilityLabel("Tap personality")
                        HStack { Text("A gentle nudge"); Spacer(); Text("Full cartoon") }.font(.system(size: 10)).foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            Text("Size").font(.system(size: 12, weight: .medium)).frame(width: 32, alignment: .leading)
                            Slider(value: $settings.pointerSize, in: 0.65...1.6).tint(mint).accessibilityLabel("Pointer size")
                            Text("\(Int(settings.pointerSize * 100))%").font(.system(size: 11, design: .monospaced)).frame(width: 34)
                        }
                    }
                    divider
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("03", "Make it yours")
                        settingToggle("Cartoon animation", subtitle: "Squash, stretch & a little drama", value: $settings.animateOnClick)
                        settingToggle("Soft shadow", subtitle: "A little depth on every background", value: $settings.shadowEnabled)
                        settingToggle("Sound on tap", subtitle: settings.soundStyle.rawValue + " · unique to this hand", value: $settings.soundEnabled)
                        HStack(spacing: 10) {
                            Image(systemName: "speaker.fill").font(.system(size: 11)).foregroundStyle(.secondary)
                            Slider(value: $settings.volume, in: 0...1).tint(mint).disabled(!settings.soundEnabled).accessibilityLabel("Sound volume")
                            Image(systemName: "speaker.wave.3.fill").font(.system(size: 11)).foregroundStyle(.secondary)
                            Button { SoundManager.shared.playKnock(energy: 0.5) } label: { Image(systemName: "play.fill") }
                                .buttonStyle(.plain).help("Preview this hand’s sound").accessibilityLabel("Preview sound")
                        }
                    }
                }.frame(width: 383)
            }.padding(26)
            Spacer(minLength: 0)
            Rectangle().fill(ink.opacity(0.08)).frame(height: 1)
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(overlay.presentationMode ? "Presentation mode is on" : "Ready for your next big idea.").font(.system(size: 11, weight: .semibold))
                    Text("Share your entire screen to include Tappy.").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Button(overlay.presentationMode ? "End presentation" : "Presentation mode") {
                    if !overlay.setPresentation(!overlay.presentationMode) { accessMessage = true }
                }.buttonStyle(.bordered).controlSize(.small)
                Text("⌃⌥T").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                Rectangle().fill(ink.opacity(0.15)).frame(width: 1, height: 22).padding(.horizontal, 4)
                Text("Toggle  ⌃⌥P").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            }.padding(.horizontal, 26).padding(.vertical, 15)
        }
        .frame(width: 751, height: 727)
        .foregroundStyle(ink)
        .background(Color(red: 0.97, green: 0.97, blue: 0.94))
        .preferredColorScheme(.light)
        .onReceive(timer) { _ in preview.tick() }
        .alert("Presentation mode needs Accessibility", isPresented: $accessMessage) {
            Button("Open Accessibility Settings") { CursorOverlayWindow.requestAccessibility() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Allow Tappy in System Settings → Privacy & Security → Accessibility. Presentation mode blocks mouse clicks; ⌃⌥T turns it off. Your keyboard remains available.") }
    }

    private var previewStage: some View {
        Button(action: previewTap) {
            ZStack {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        if background != "Dark" { Color(red: 0.91, green: 0.92, blue: 0.88) }
                        if background != "Light" { Color(red: 0.13, green: 0.17, blue: 0.20) }
                    }
                    Path { p in
                        for x in stride(from: 14.0, to: proxy.size.width, by: 18) {
                            for y in stride(from: 14.0, to: proxy.size.height, by: 18) { p.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5)) }
                        }
                    }.fill(Color.gray.opacity(0.25))
                }
                VStack {
                    HStack {
                        if background != "Dark" { Text("LIGHT").foregroundStyle(ink.opacity(0.45)) }
                        Spacer()
                        if background != "Light" { Text("DARK").foregroundStyle(.white.opacity(0.45)) }
                    }.font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.4)
                    Spacer()
                    Text("\(settings.pointerStyle.title) · \(settings.soundStyle.rawValue)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 11).padding(.vertical, 7)
                        .background(.regularMaterial, in: Capsule())
                }.padding(16)
                TapBurst(impact: preview.impact, visible: preview.burstVisible, style: settings.pointerStyle).position(x: 137, y: 83)
                PointerSprite(style: settings.pointerStyle, size: min(1.35, settings.pointerSize * 1.14), tapping: preview.isTapping,
                              impact: preview.impact, shadow: settings.shadowEnabled).position(x: 137, y: 83)
            }
            .frame(width: 290, height: 313)
            .clipShape(RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(ink.opacity(0.12)))
        }.buttonStyle(.plain).accessibilityLabel("Test pointer. Click repeatedly to increase energy.")
    }
    private func previewTap() {
        let energy = preview.tap(settings: settings)
        // The global overlay already handles this click when enabled.
        if !overlay.isActive { SoundManager.shared.playKnock(energy: energy) }
    }
    private var moodLabel: String {
        ["Subtle", "Easygoing", "Playful", "Expressive", "Extra"][min(4, Int(settings.mood * 4.99))]
    }
    private var divider: some View { Rectangle().fill(ink.opacity(0.09)).frame(height: 1) }
    private func sectionTitle(_ number: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text(number).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ink.opacity(0.4))
            Text(title).font(.system(size: 14, weight: .bold))
        }
    }
    private func settingToggle(_ title: String, subtitle: String, value: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle(title, isOn: value).labelsHidden().toggleStyle(.switch).controlSize(.small).tint(mint)
        }
    }
}
