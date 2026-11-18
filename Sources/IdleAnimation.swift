import SwiftUI
import Cocoa

enum IdleAnimationSchedule {
    /// Play once at each idle interval boundary, then remain still until the next.
    static func phase(idleFor: Double, interval: Double, duration: Double, enabled: Bool) -> Double? {
        let interval = max(0.001, interval)
        guard enabled, idleFor.isFinite, idleFor >= interval else { return nil }
        let elapsed = idleFor.truncatingRemainder(dividingBy: interval)
        return elapsed < min(duration, interval) ? elapsed : nil
    }
}

enum InputIdleTime {
    private static var sampledAt = -1.0
    private static var sampledIdle = 0.0
    /// Read only event timestamps, without monitoring keyboard contents or asking for access.
    static var seconds: Double {
        let now = ProcessInfo.processInfo.systemUptime
        if sampledAt >= 0, now - sampledAt < 0.05 { return sampledIdle + now - sampledAt }
        let types: [CGEventType] = [.keyDown, .mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown,
         .leftMouseDragged, .rightMouseDragged, .scrollWheel]
        sampledIdle = types.map { type in
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: type)
        }.min() ?? 0
        sampledAt = now
        return sampledIdle
    }
}

struct IdlePose {
    let cycle: Double
    init(time: Double) { cycle = max(0, time) }
    static func duration(for style: PointerStyle) -> Double { style == .classic ? 2.6 : 1.15 }
    private var tossCycle: Double { cycle }
    /// A complete toss includes anticipation, release, one revolution, and a catch.
    var flight: Double {
        guard tossCycle >= 0.35 && tossCycle <= 1.05 else { return 0 }
        return (tossCycle - 0.35) / 0.7
    }
    var isFlying: Bool { tossCycle > 0.35 && tossCycle < 1.05 }
    var lift: Double { isFlying ? sin(flight * .pi) * 33 : 0 }
    var rotation: Double { isFlying ? flight * 360 : 0 }
    var handMix: Double {
        // Hand off to the original closed grip exactly on landing. Crossfading
        // an open palm over a closed glove here produces two overlapping hands.
        guard tossCycle < 1.05 else { return 0 }
        func smooth(_ x: Double) -> Double { let t = min(1, max(0, x)); return t*t*(3 - 2*t) }
        return smooth((tossCycle - 0.2) / 0.15)
    }
    var fidgetWeights: [Double] {
        let keyframes: [(Double, Int)] = [(0, 0), (0.4, 0), (0.6, 1), (1.05, 1), (1.25, 2),
                                         (1.7, 2), (1.9, 1), (2.35, 1), (2.6, 0), (4.4, 0)]
        for i in 0..<(keyframes.count - 1) where cycle >= keyframes[i].0 && cycle <= keyframes[i + 1].0 {
            let a = keyframes[i], b = keyframes[i + 1]
            let raw = (cycle - a.0) / max(0.001, b.0 - a.0)
            let t = raw * raw * (3 - 2 * raw)
            var weights = [0.0, 0, 0]
            weights[a.1] += 1 - t; weights[b.1] += t
            return weights
        }
        return [1, 0, 0]
    }
}

enum IdleImages {
    static let names = ["ClassicWave", "ClassicFist", "Catch", "MoonWandObject", "StarWandObject", "WizardWandObject"]
    static let images: [String: NSImage] = {
        var result: [String: NSImage] = [:]
        for name in names {
            let appURL = Bundle.main.resourceURL?.appendingPathComponent("Tappy_Tappy.bundle/Hands/Idle/\(name).png")
            if let appURL, let image = NSImage(contentsOf: appURL) { result[name] = image; continue }
            #if SWIFT_PACKAGE
            let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Hands/Idle")
            #else
            let url: URL? = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/Resources/Hands/Idle/\(name).png")
            #endif
            if let url, let image = NSImage(contentsOf: url) { result[name] = image }
        }
        return result
    }()
    static let bitmaps = images.compactMapValues(PointerBitmap.decode)
}

enum IdlePointerArtwork {
    static func draw(style: PointerStyle, time: Double, in context: inout GraphicsContext, availableTopRoom: Double) {
        let pose = IdlePose(time: time)
        guard let normal = PointerImages.bitmaps[style] else { return }
        if style == .classic {
            let weights = pose.fidgetWeights
            PointerArtwork.draw(normal, style: style, in: &context, opacity: weights[0])
            if let wave = IdleImages.bitmaps["ClassicWave"] { PointerArtwork.draw(wave, style: style, in: &context, opacity: weights[1]) }
            if let fist = IdleImages.bitmaps["ClassicFist"] { PointerArtwork.draw(fist, style: style, in: &context, opacity: weights[2]) }
        } else {
            let mix = pose.handMix
            PointerArtwork.draw(normal, style: style, in: &context, opacity: 1 - mix)
            if mix > 0, let hand = IdleImages.bitmaps["Catch"],
               let object = IdleImages.bitmaps[PointerImages.filename(style) + "Object"] {
                context.drawLayer { layer in
                    layer.opacity = mix
                    let lift = min(pose.lift, max(0, availableTopRoom - 10))
                    var flying = layer
                    flying.translateBy(x: 50, y: 65 - lift)
                    flying.rotate(by: .degrees(pose.rotation))
                    flying.translateBy(x: -50, y: -65)
                    PointerBitmap.draw(object, in: &flying)
                    layer.translateBy(x: PointerGeometry.wrist(style).x - 48.5, y: PointerGeometry.cuffBottom(style) - 127.5)
                    PointerArtwork.draw(hand, style: .wizardWand, in: &layer)
                }
            }
        }
    }
}
