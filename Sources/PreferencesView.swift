import SwiftUI

struct PreferencesView: View {
    @ObservedObject private var settings: TappySettings
    @ObservedObject var overlay: CursorOverlayWindow
    @StateObject private var preview = CursorState()
    @State private var background = "Split"
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var palette: TappyPalette { TappyPalette(scheme: colorScheme) }
    private var ink: Color { palette.ink }
    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

    init(overlay: CursorOverlayWindow, settings: TappySettings = .shared) {
        self.overlay = overlay; self.settings = settings
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PointerArtwork(shadow: false).frame(width: 30, height: 42)
                Text("tappy").font(.system(size: 28, weight: .heavy, design: .rounded)).tracking(-1)
                Text(AppVersion.short).font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 7).padding(.vertical, 4).background(ink.opacity(0.07), in: Capsule())
                Spacer()
                Picker("Appearance", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { Text($0.title).tag($0) }
                }.pickerStyle(.menu).labelsHidden().frame(width: 108)
                HStack(spacing: 7) {
                    Circle().fill(overlay.isActive ? Color.accentColor : .gray).frame(width: 7, height: 7)
                    Text(overlay.isActive ? "On stage" : "Taking a break").font(.system(size: 12, weight: .medium))
                    Toggle("Enable Tappy", isOn: Binding(get: { overlay.isActive }, set: { $0 ? overlay.activate() : overlay.deactivate() }))
                        .labelsHidden().toggleStyle(.switch)
                }
            }.padding(.horizontal, 26).padding(.vertical, 16)
            divider
            HStack(alignment: .top, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    characterPicker
                    previewStage
                    HStack {
                        Text("TRY IT OUT").font(.system(size: 10, weight: .bold)).tracking(1)
                        Spacer()
                        Text("Click faster. Get louder.").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<20) { i in Capsule().fill(Double(i) / 20 < preview.energy ? Color.accentColor : ink.opacity(0.09)).frame(height: 5) }
                    }.accessibilityLabel("Click energy").accessibilityValue("\(Int(preview.energy * 100)) percent")
                    Picker("Preview background", selection: $background) {
                        Text("Light").tag("Light"); Text("Split").tag("Split"); Text("Dark").tag("Dark")
                    }.pickerStyle(.segmented).labelsHidden()
                }.frame(width: 290)
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 9) {
                        sectionTitle("02", "Pointer")
                        sliderRow("Tap energy", value: $settings.mood, range: 0...1, display: moodLabel)
                        Text("A gentle nudge → full cartoon").font(.system(size: 10)).foregroundStyle(.secondary)
                        sliderRow("Size", value: $settings.pointerSize, range: 0.65...1.6, display: "\(Int(settings.pointerSize * 100))%")
                        sliderRow("Forearm opacity", value: $settings.armOpacity, range: 0...1, display: "\(Int(settings.armOpacity * 100))%")
                        sliderRow("Forearm length", value: $settings.armExtension, range: 0...1,
                                  display: settings.armExtension < 0.01 ? "Minimum" : settings.armExtension > 0.99 ? "Full screen" : "\(Int(settings.armExtension * 100))%")
                    }
                    divider
                    VStack(alignment: .leading, spacing: 9) {
                        sectionTitle("03", "Sound & effects")
                        compactToggle("Cartoon animation", value: $settings.animateOnClick)
                        compactToggle("Soft shadow", value: $settings.shadowEnabled)
                        compactToggle("Sound on tap", value: $settings.soundEnabled)
                        Text(settings.soundStyle.rawValue + " · unique to this hand").font(.system(size: 10)).foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text("Volume").font(.system(size: 12, weight: .medium)).frame(width: 102, alignment: .leading)
                            Slider(value: $settings.volume, in: 0...1).disabled(!settings.soundEnabled).accessibilityLabel("Sound volume")
                            Button { SoundManager.shared.playKnock(energy: 0.5) } label: { Image(systemName: "play.fill").font(.system(size: 11)) }
                                .buttonStyle(.plain).help("Preview this hand’s sound").accessibilityLabel("Preview sound").frame(width: 58)
                        }
                    }
                    divider
                    VStack(alignment: .leading, spacing: 9) {
                        sectionTitle("04", "While you’re away")
                        compactToggle("Idle animation", value: $settings.idleEnabled)
                        HStack(spacing: 8) {
                            Text("Start after").font(.system(size: 12, weight: .medium)).frame(width: 102, alignment: .leading)
                            Slider(value: $settings.idleDelay, in: 3...60, step: 1)
                                .disabled(!settings.idleEnabled).accessibilityLabel("Idle animation delay")
                            Text("\(Int(settings.idleDelay)) sec").font(.system(size: 10, design: .monospaced)).frame(width: 58, alignment: .trailing)
                        }
                        Button("Preview idle animation") { preview.previewIdle() }
                            .disabled(!settings.idleEnabled || reduceMotion).controlSize(.small)
                        Text("Stops as soon as you move, click or type.").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.frame(width: 383, height: 540, alignment: .top)
            }.padding(26)
            Spacer(minLength: 0)
            divider
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(overlay.presentationMode ? "Presentation mode is on" : "Ready for your next big idea.").font(.system(size: 11, weight: .semibold))
                    Text(overlay.presentationMode ? "Clicks are protected. Press ⌃⌥T to exit." : "Share your entire screen to include Tappy.")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Button(overlay.presentationMode ? "End presentation" : "Presentation mode") { overlay.setPresentation(!overlay.presentationMode) }
                    .buttonStyle(.bordered).controlSize(.small)
                Text("⌃⌥T").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                Rectangle().fill(ink.opacity(0.15)).frame(width: 1, height: 22).padding(.horizontal, 4)
                Text("Toggle  ⌃⌥P").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
            }.padding(.horizontal, 26).padding(.vertical, 15)
        }
        .frame(width: 751, height: 727)
        .foregroundStyle(ink).background(palette.background)
        .preferredColorScheme(settings.theme.colorScheme)
        .onReceive(timer) { _ in preview.tick(systemIdle: InputIdleTime.seconds, settings: settings, reduceMotion: reduceMotion) }
    }
    private var characterPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("01", "Pick your character")
            HStack(spacing: 6) {
                ForEach(PointerStyle.allCases) { style in
                    Button {
                        settings.pointerStyle = style
                        preview.reset(); previewTap()
                    } label: {
                        VStack(spacing: 4) {
                            PointerArtwork(style: style, shadow: false).frame(width: 44, height: 62)
                            Text(style.title).font(.system(size: 9, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                        }.frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(settings.pointerStyle == style ? Color.accentColor.opacity(0.12) : palette.card, in: RoundedRectangle(cornerRadius: 11))
                            .overlay(RoundedRectangle(cornerRadius: 11).stroke(settings.pointerStyle == style ? Color.accentColor : ink.opacity(0.12), lineWidth: settings.pointerStyle == style ? 2 : 1))
                    }.buttonStyle(.plain).accessibilityLabel(style.title)
                        .accessibilityAddTraits(settings.pointerStyle == style ? .isSelected : [])
                }
            }
            Text(settings.pointerStyle.subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
        }
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
                PointerArm(position: CGPoint(x: 137, y: 55), style: settings.pointerStyle,
                           size: min(1.3, settings.pointerSize * 1.1), tapping: preview.isTapping, impact: preview.impact,
                           shadow: settings.shadowEnabled, reduceMotion: reduceMotion, lean: preview.lean,
                           lowerOpacity: settings.armOpacity, extensionFraction: settings.armExtension)
                VStack {
                    HStack {
                        if background != "Dark" { Text("LIGHT").foregroundStyle(Color.black.opacity(0.45)) }
                        Spacer()
                        if background != "Light" { Text("DARK").foregroundStyle(.white.opacity(0.45)) }
                    }.font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.4)
                    Spacer()
                    Text("\(settings.pointerStyle.title) · \(settings.soundStyle.rawValue)")
                        .font(.system(size: 10, weight: .medium)).padding(.horizontal, 11).padding(.vertical, 7)
                        .background(.regularMaterial, in: Capsule())
                }.padding(16)
                TapBurst(impact: preview.impact, visible: preview.burstVisible, style: settings.pointerStyle).position(x: 137, y: 55)
                PointerSprite(style: settings.pointerStyle, size: min(1.3, settings.pointerSize * 1.1), tapping: preview.isTapping,
                              impact: preview.impact, shadow: settings.shadowEnabled, reduceMotion: reduceMotion, lean: preview.lean,
                              idleTime: preview.idleTime, availableTopRoom: 55).position(x: 137, y: 55)
            }.frame(width: 290, height: 275).clipShape(RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).stroke(ink.opacity(0.12)))
        }.buttonStyle(.plain).accessibilityLabel("Test pointer. Click repeatedly to increase energy.")
            .accessibilityValue(preview.idleTime == nil ? "Ready" : "Idle animation playing")
            .onContinuousHover { phase in
                if case .active(let point) = phase {
                    preview.noteActivity(); preview.trackOrientation(at: point, canvas: CGSize(width: 290, height: 275))
                }
            }
    }
    private func previewTap() {
        let energy = preview.tap(settings: settings)
        if !overlay.isActive { SoundManager.shared.playKnock(energy: energy) }
    }
    private var moodLabel: String { ["Subtle", "Easygoing", "Playful", "Expressive", "Extra"][min(4, Int(settings.mood * 4.99))] }
    private var divider: some View { Rectangle().fill(ink.opacity(0.09)).frame(height: 1) }
    private func sectionTitle(_ number: String, _ title: String) -> some View {
        HStack(spacing: 8) {
            Text(number).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(ink.opacity(0.4))
            Text(title).font(.system(size: 14, weight: .bold))
        }
    }
    private func compactToggle(_ title: String, value: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.system(size: 12, weight: .medium)); Spacer()
            Toggle(title, isOn: value).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }
    }
    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, display: String) -> some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 12, weight: .medium)).frame(width: 102, alignment: .leading)
            Slider(value: value, in: range).accessibilityLabel(title == "Size" ? "Pointer size" : title)
            Text(display).font(.system(size: 10, design: .monospaced)).lineLimit(1).minimumScaleFactor(0.8).frame(width: 58, alignment: .trailing)
        }
    }
}
