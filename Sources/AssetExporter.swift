import Cocoa
import SwiftUI
import ImageIO

struct AppIconArtwork: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 112, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.65, green: 0.98, blue: 0.80), Color(red: 0.24, green: 0.73, blue: 0.61)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 112, style: .continuous).strokeBorder(.white.opacity(0.45), lineWidth: 4))
                .padding(20)
            Circle().fill(.white.opacity(0.17)).frame(width: 350).offset(x: 75, y: -80)
            ForEach(0..<3) { i in
                PointerGeometry.star(center: CGPoint(x: [127.0, 370, 117][i], y: [150.0, 119, 307][i]), radius: [24.0, 17, 12][i], points: 4)
                    .fill(Color(red: 0.12, green: 0.24, blue: 0.23))
            }
            ZStack(alignment: .topLeading) {
                PointerFigure(position: CGPoint(x: 249, y: 81), style: .classic, size: 2.6, shadow: false, lowerOpacity: 1)
            }.clipShape(RoundedRectangle(cornerRadius: 112, style: .continuous).inset(by: 20))
        }.frame(width: 512, height: 512)
    }
}

struct PointerContactSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline) {
                Text("tappy").font(.system(size: 42, weight: .heavy, design: .rounded))
                Text("\(AppVersion.short) / POLISHED POINTERS").font(.system(size: 12, weight: .bold, design: .monospaced)).tracking(2)
            }
            Text("Eight characters. Every click, a little louder.").font(.system(size: 17)).foregroundStyle(.secondary)
            VStack(spacing: 24) {
                ForEach(PointerStyle.rows.indices, id: \.self) { row in
                    HStack(spacing: 16) {
                        ForEach(PointerStyle.rows[row]) { style in
                            VStack(spacing: 14) {
                                ZStack {
                                    HStack(spacing: 0) { Color(red: 0.91, green: 0.92, blue: 0.88); Color(red: 0.12, green: 0.16, blue: 0.19) }
                                    PointerFigure(position: CGPoint(x: 96, y: 34), style: style, size: 1.15)
                                }.frame(width: 205, height: 244).clipShape(RoundedRectangle(cornerRadius: 20))
                                Text(style.title).font(.system(size: 16, weight: .bold))
                                Text(style.sound.rawValue).font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }.padding(36).background(Color(red: 0.97, green: 0.97, blue: 0.94)).foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.18)).environment(\.colorScheme, .light)
    }
}

struct IdleContactSheet: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Tappy \(AppVersion.short) · idle animation frames").font(.system(size: 22, weight: .bold))
            ForEach(PointerStyle.allCases) { style in
                HStack(spacing: 12) {
                    Text(style.title).font(.system(size: 14, weight: .medium)).frame(width: 90)
                    ForEach(style.isFingerHand ? [0.1, 0.45, 0.9, 1.3, 1.8, 2.2, 2.65] : [0.1, 0.48, 0.7, 1.0], id: \.self) { time in
                        VStack(spacing: 5) {
                        Text(style.isFingerHand ? fingerLabel(time) : String(format: "%.2f s", time)).font(.system(size: 11, weight: .medium))
                        ZStack(alignment: .topLeading) {
                            Color(nsColor: .controlBackgroundColor)
                            PointerFigure(position: CGPoint(x: 65, y: 35), style: style, size: 0.85, lowerOpacity: 0.2,
                                          idleTime: style.isFingerHand ? time / FingerAnimationTiming.playbackRate : time, availableTopRoom: 80)
                        }.frame(width: 140, height: 220).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }.padding(24).background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .light)
    }
    private func fingerLabel(_ time: Double) -> String {
        switch time {
        case ..<0.3: return "1"
        case ..<0.7: return "1 + 2"
        case ..<1.1: return "1 + 2 + 3"
        case ..<1.6: return "Fist"
        case ..<2.0: return "2"
        case ..<2.5: return "Fist"
        default: return "1"
        }
    }
}

private struct FingerAnimationPreview: View {
    let time: Double
    var secondary = false
    private var secondaryWeights: [Double]? {
        var gesture=SecondaryFingerGesture();gesture.press(at:0);gesture.release(at:0.55)
        return gesture.weights(at:time)
    }
    var body: some View {
        VStack(spacing: 12) {
            Text(secondary ? "Right click: 1 → Fist → 2 → Fist → 1" : "1 → 1+2 → 1+2+3 → Fist → 2 → Fist → 1").font(.system(size: 16, weight: .semibold))
            HStack(spacing: 16) {
                ForEach([PointerStyle.classic, .witch]) { style in
                    VStack(spacing: 6) {
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: 0) { Color(white: 0.95); Color(white: 0.14) }
                            PointerFigure(position: CGPoint(x: 120, y: 20), style: style, size: 1.45, shadow: true,
                                          lean: 0, lowerOpacity: 0.3, idleTime: secondary ? nil : time,
                                          fingerWeights: secondary ? secondaryWeights : nil)
                        }.frame(width: 260, height: 310).clipShape(RoundedRectangle(cornerRadius: 15))
                        Text(style.title).font(.system(size: 14, weight: .medium))
                    }
                }
            }
        }.padding(18).background(Color.white).foregroundStyle(.black)
    }
}

private struct FingerCelContactSheet: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach([PointerStyle.classic, .witch]) { style in
                Text(style.title).font(.system(size: 22, weight: .bold))
                ForEach(0..<4) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<4) { column in
                            let index = row * 4 + column
                            VStack {
                                Canvas { context, _ in
                                    context.fill(Path(CGRect(x: 0, y: 0, width: 100, height: 280)), with: .color(Color(white: 0.93)))
                                    context.fill(Path(CGRect(x: 100, y: 0, width: 100, height: 280)), with: .color(Color(white: 0.14)))
                                    context.withCGContext { cg in
                                        cg.translateBy(x: 25, y: 20); cg.scaleBy(x: 1.5, y: 1.5)
                                        FingerCelArtwork.draw(style: style, weights: FingerCelArtwork.samples[index], in: cg)
                                    }
                                }.frame(width: 200, height: 280)
                                Text("Cel \(index)").font(.system(size: 12, design: .monospaced))
                            }
                        }
                    }
                }
            }
        }.padding(20).background(Color.white).foregroundStyle(.black)
    }
}

/// Enlarged frames make cuff continuity visible throughout compression and rebound.
struct TapContactSheet: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Tappy \(AppVersion.short) · wrist joint / tap and rebound").font(.system(size: 22, weight: .bold))
            HStack {
                Text("Phase").frame(width: 90)
                ForEach([0.0, 0.5, 1.0, -0.15], id: \.self) { phase in
                    Text(String(format: "%.2f", phase)).frame(width: 220)
                }
            }
            ForEach(PointerStyle.allCases) { style in
                HStack(spacing: 12) {
                    Text(style.title).font(.system(size: 14, weight: .medium)).frame(width: 90)
                    ForEach([0.0, 0.5, 1.0, -0.15], id: \.self) { phase in
                        ZStack {
                            HStack(spacing: 0) { Color(white: 0.94); Color(white: 0.13) }
                            PointerFigure(position: CGPoint(x: 92, y: -65), style: style, size: 2.2,
                                          impact: 1, lean: -24, lowerOpacity: 1, phase: phase)
                        }.frame(width: 220, height: 300).clipped()
                    }
                }
            }
        }.padding(24).background(Color(nsColor: .windowBackgroundColor)).environment(\.colorScheme, .light)
    }
}

@MainActor enum AssetExporter {
    static func export(to path: String) throws {
        let root = URL(fileURLWithPath: path)
        let iconset = root.appendingPathComponent("Tappy.iconset")
        try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
        for size in [16, 32, 128, 256, 512] {
            for scale in [1, 2] {
                let renderer = ImageRenderer(content: AppIconArtwork().scaleEffect(CGFloat(size) / 512, anchor: .topLeading).frame(width: CGFloat(size), height: CGFloat(size), alignment: .topLeading))
                renderer.scale = CGFloat(scale)
                guard let cg = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
                let rep = NSBitmapImageRep(cgImage: cg)
                guard let data = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                let filename = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
                try data.write(to: iconset.appendingPathComponent(filename))
            }
        }
        let sheet = ImageRenderer(content: PointerContactSheet())
        sheet.scale = 2
        if let cg = sheet.cgImage, let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) {
            try data.write(to: root.appendingPathComponent("Tappy-\(AppVersion.short)-preview.png"))
        }
        let idleSheet = ImageRenderer(content: IdleContactSheet())
        idleSheet.scale = 2
        if let cg = idleSheet.cgImage, let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) {
            try data.write(to: root.appendingPathComponent("Tappy-\(AppVersion.short)-idle-preview.png"))
        }
        let celSheet = ImageRenderer(content: FingerCelContactSheet())
        if let cg = celSheet.cgImage, let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) {
            try data.write(to: root.appendingPathComponent("Tappy-\(AppVersion.short)-cels.png"))
        }
        for secondary in [false,true] {
        let frames = secondary ? 22 : 48
        let gifURL = root.appendingPathComponent("Tappy-\(AppVersion.short)-\(secondary ? "right-click" : "fingers").gif")
        guard let gif = CGImageDestinationCreateWithURL(gifURL as CFURL, "com.compuserve.gif" as CFString, frames, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationSetProperties(gif, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for frame in 0..<frames {
            let renderer = ImageRenderer(content: FingerAnimationPreview(time: Double(frame) * 0.05, secondary:secondary))
            guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
            CGImageDestinationAddImage(gif, image, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.05]] as CFDictionary)
        }
        guard CGImageDestinationFinalize(gif) else { throw CocoaError(.fileWriteUnknown) }
        }
        let tapSheet = ImageRenderer(content: TapContactSheet())
        tapSheet.scale = 2
        if let cg = tapSheet.cgImage, let data = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) {
            try data.write(to: root.appendingPathComponent("Tappy-\(AppVersion.short)-tap-preview.png"))
        }
        for style in TapSound.allCases {
            try SoundSynthesis.wav(style: style).write(to: root.appendingPathComponent(style.rawValue.replacingOccurrences(of: " ", with: "-").lowercased() + ".wav"))
        }
        try exportSettingsPreviews(to: root)
    }

    private static func exportSettingsPreviews(to root: URL) throws {
        _ = NSApplication.shared
        let originalAppearance = NSApp.appearance
        defer { NSApp.appearance = originalAppearance }
        for theme in [AppTheme.light, .dark] {
            NSApp.appearance = theme.appearance
            let settings = TappySettings(defaults: ArtworkPreviewDefaults())
            settings.theme = theme
            settings.pointerStyle = theme == .light ? .witch : .greenLightsaber
            let overlay = CursorOverlayWindow()
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 751, height: 727),
                                  styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = theme.appearance
            window.isReleasedWhenClosed = false
            let view = NSHostingView(rootView: PreferencesView(overlay: overlay, settings: settings))
            view.frame = NSRect(x: 0, y: 0, width: 751, height: 727)
            window.contentView = view
            view.layoutSubtreeIfNeeded()
            view.displayIfNeeded()
            guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { throw CocoaError(.fileWriteUnknown) }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            guard let data = bitmap.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
            try data.write(to: root.appendingPathComponent("Tappy-\(AppVersion.short)-settings-\(theme.rawValue).png"))
            window.contentView = nil
            window.close()
        }
    }

    static func menuIcon(active: Bool, presentation: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 24, height: 22), flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.saveGState()
            ctx.translateBy(x: 4, y: 1)
            ctx.scaleBy(x: 0.15, y: 0.15)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setLineWidth(7.5); ctx.setLineJoin(.round); ctx.setLineCap(.round)
            ctx.addPath(PointerGeometry.outline(.classic).cgPath); ctx.strokePath()
            ctx.setLineWidth(5)
            ctx.addPath(PointerGeometry.creases(.classic).cgPath); ctx.strokePath()
            ctx.restoreGState()
            ctx.setStrokeColor(NSColor.black.cgColor); ctx.setLineWidth(1.4); ctx.setLineCap(.round)
            if !active {
                ctx.move(to: CGPoint(x: 3, y: 19)); ctx.addLine(to: CGPoint(x: 20, y: 3)); ctx.strokePath()
            } else {
                for (a, b) in [(CGPoint(x: 5, y: 3), CGPoint(x: 3, y: 1)), (CGPoint(x: 16, y: 3), CGPoint(x: 19, y: 1)), (CGPoint(x: 19, y: 7), CGPoint(x: 22, y: 7))] {
                    ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
                }
            }
            if presentation { ctx.fillEllipse(in: CGRect(x: 19, y: 16, width: 4, height: 4)) }
            return true
        }
        image.isTemplate = true
        return image
    }
}

/// Screenshot generation must never change the user's saved preferences.
private final class ArtworkPreviewDefaults: UserDefaults {
    private var values: [String: Any] = [:]
    override func register(defaults: [String: Any]) { for (key, value) in defaults where values[key] == nil { values[key] = value } }
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
    override func object(forKey key: String) -> Any? { values[key] }
    override func string(forKey key: String) -> String? { values[key] as? String }
    override func double(forKey key: String) -> Double { (values[key] as? NSNumber)?.doubleValue ?? 0 }
    override func bool(forKey key: String) -> Bool { (values[key] as? NSNumber)?.boolValue ?? false }
}
