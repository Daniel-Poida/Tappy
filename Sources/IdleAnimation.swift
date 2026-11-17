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
}

struct IdlePointerArtwork: View {
    let style: PointerStyle
    let time: Double
    var shadow = true
    var availableTopRoom: Double = 100
    var body: some View {
        let pose = IdlePose(time: time)
        GeometryReader { bounds in
        Canvas { context, _ in
            context.translateBy(x: 150, y: 150)
            context.scaleBy(x: bounds.size.width / 100, y: bounds.size.height / 140)
            if shadow { context.addFilter(.shadow(color: .black.opacity(0.25), radius: 3, x: 3, y: 5)) }
            func draw(_ image: NSImage, in target: inout GraphicsContext, opacity: Double = 1) {
                target.drawLayer { layer in
                    layer.opacity = opacity
                    layer.clip(to: Path(CGRect(x: -20, y: -100, width: 140, height: 230)))
                    layer.draw(Image(nsImage: image), in: CGRect(x: -20, y: 0, width: 140, height: 140))
                }
            }
            guard let normal = PointerImages.images[style] else { return }
            if style == .classic {
                let weights = pose.fidgetWeights
                draw(normal, in: &context, opacity: weights[0])
                if let wave = IdleImages.images["ClassicWave"] { draw(wave, in: &context, opacity: weights[1]) }
                if let fist = IdleImages.images["ClassicFist"] { draw(fist, in: &context, opacity: weights[2]) }
            } else {
                let mix = pose.handMix
                draw(normal, in: &context, opacity: 1 - mix)
                if mix > 0, let hand = IdleImages.images["Catch"],
                   let object = IdleImages.images[PointerImages.filename(style) + "Object"] {
                    context.drawLayer { layer in
                        layer.opacity = mix
                        let lift = min(pose.lift, max(0, availableTopRoom / max(0.1, bounds.size.height / 140) - 10))
                        var flying = layer
                        flying.translateBy(x: 50, y: 65 - lift)
                        flying.rotate(by: .degrees(pose.rotation))
                        flying.translateBy(x: -50, y: -65)
                        flying.draw(Image(nsImage: object), in: CGRect(x: -20, y: 0, width: 140, height: 140))
                        draw(hand, in: &layer)
                    }
                }
            }
        }.frame(width: bounds.size.width + 300, height: bounds.size.height + 300).offset(x: -150, y: -150)
        }.accessibilityHidden(true)
    }
}
