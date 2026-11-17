import Cocoa
import SwiftUI

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
            PointerArtwork(shadow: true, lifted: true)
                .frame(width: 272, height: 381)
                .rotationEffect(.degrees(-14)).offset(x: 10, y: 35)
        }.frame(width: 512, height: 512)
    }
}

struct PointerContactSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .firstTextBaseline) {
                Text("tappy").font(.system(size: 42, weight: .heavy, design: .rounded))
                Text("1.1 / THE MAGIC UPDATE").font(.system(size: 12, weight: .bold, design: .monospaced)).tracking(2)
            }
            Text("Four characters. Every click, a little louder.").font(.system(size: 17)).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ForEach(PointerStyle.allCases) { style in
                    VStack(spacing: 14) {
                        ZStack {
                            HStack(spacing: 0) { Color(red: 0.91, green: 0.92, blue: 0.88); Color(red: 0.12, green: 0.16, blue: 0.19) }
                            PointerArtwork(style: style, lifted: true).frame(width: 126, height: 176).rotationEffect(.degrees(-8))
                        }.frame(width: 205, height: 244).clipShape(RoundedRectangle(cornerRadius: 20))
                        Text(style.title).font(.system(size: 16, weight: .bold))
                        Text(style.sound.rawValue).font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                }
            }
        }.padding(36).background(Color(red: 0.97, green: 0.97, blue: 0.94)).foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.18)).environment(\.colorScheme, .light)
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
            try data.write(to: root.appendingPathComponent("Tappy-1.1-preview.png"))
        }
        for style in TapSound.allCases {
            try SoundSynthesis.wav(style: style).write(to: root.appendingPathComponent(style.rawValue.replacingOccurrences(of: " ", with: "-").lowercased() + ".wav"))
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
