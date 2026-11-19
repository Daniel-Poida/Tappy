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

enum FingerPose: Int, CaseIterable {
    case index, two, three, fist, middle
    var weights: [Double] { Self.allCases.map { $0 == self ? 1 : 0 } }
}

enum FingerAnimationTiming {
    static let playbackRate = 1.5
}

/// The same fist is the bridge on press and release. Short clicks still show
/// the middle finger once; a new press starts from the currently drawn pose.
struct SecondaryFingerGesture {
    private var pressedAt: TimeInterval?
    private var returningAt: TimeInterval?
    private var initialWeights = FingerPose.index.weights
    private var animated = true
    mutating func press(at time: TimeInterval, animated: Bool = true) {
        initialWeights = weights(at: time) ?? FingerPose.index.weights
        self.animated = animated
        pressedAt = time; returningAt = nil
    }
    mutating func release(at time: TimeInterval) {
        guard let pressedAt, returningAt == nil else { return }
        returningAt = max(time, pressedAt + (animated ? 0.40 / FingerAnimationTiming.playbackRate : 0))
    }
    mutating func reset() { pressedAt = nil; returningAt = nil; initialWeights = FingerPose.index.weights }
    func weights(at time: TimeInterval) -> [Double]? {
        guard let pressedAt else { return nil }
        if !animated {
            if let returningAt, time >= returningAt + 0.16 { return nil }
            return FingerPose.middle.weights
        }
        func blend(_ from: [Double], _ to: FingerPose, _ progress: Double) -> [Double] {
            let raw = min(1, max(0, progress)), t = raw * raw * (3 - 2 * raw)
            return zip(from, to.weights).map { $0 * (1 - t) + $1 * t }
        }
        if let returningAt, time >= returningAt {
            let elapsed = (time - returningAt) * FingerAnimationTiming.playbackRate
            if elapsed < 0.10 { return blend(FingerPose.middle.weights, .fist, elapsed / 0.10) }
            if elapsed < 0.20 { return FingerPose.fist.weights }
            if elapsed < 0.32 { return blend(FingerPose.fist.weights, .index, (elapsed - 0.20) / 0.12) }
            return nil
        }
        let elapsed = max(0, time - pressedAt) * FingerAnimationTiming.playbackRate
        if elapsed < 0.10 { return blend(initialWeights, .fist, elapsed / 0.10) }
        if elapsed < 0.20 { return FingerPose.fist.weights }
        if elapsed < 0.32 { return blend(FingerPose.fist.weights, .middle, (elapsed - 0.20) / 0.12) }
        return FingerPose.middle.weights
    }
}

struct IdlePose {
    let cycle: Double
    init(time: Double) { cycle = max(0, time) }
    static func duration(for style: PointerStyle) -> Double { style.isFingerHand ? 2.8 / FingerAnimationTiming.playbackRate : 1.15 }
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
        let fingerCycle = cycle * FingerAnimationTiming.playbackRate
        let keyframes: [(Double, FingerPose)] = [
            (0, .index), (0.20, .index), (0.32, .two), (0.64, .two),
            (0.76, .three), (1.08, .three), (1.20, .fist), (1.48, .fist),
            (1.60, .middle), (1.98, .middle), (2.10, .fist), (2.36, .fist),
            (2.50, .index), (2.80, .index)
        ]
        for i in 0..<(keyframes.count - 1) where fingerCycle >= keyframes[i].0 && fingerCycle <= keyframes[i + 1].0 {
            let a = keyframes[i], b = keyframes[i + 1]
            let raw = (fingerCycle - a.0) / max(0.001, b.0 - a.0)
            let t = raw * raw * (3 - 2 * raw)
            var weights = Array(repeating: 0.0, count: FingerPose.allCases.count)
            weights[a.1.rawValue] += 1 - t; weights[b.1.rawValue] += t
            return weights
        }
        return [1, 0, 0, 0, 0]
    }
}

enum IdleImages {
    static let names = ["Catch", "MoonWandObject", "StarWandObject", "WizardWandObject", "FinnSwordObject", "RedLightsaberObject", "GreenLightsaberObject"]
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
    static func drawFingers(style: PointerStyle, weights: [Double], in context: CGContext) {
        FingerCelArtwork.draw(style:style,weights:weights,in:context)
    }
    static func draw(style: PointerStyle, time: Double, in context: CGContext, availableTopRoom: Double) {
        let pose = IdlePose(time: time)
        guard let normal = PointerImages.bitmaps[style] else { return }
        if style.isFingerHand {
            // Timing chooses one whole painted hand, including its thumb and cuff.
            drawFingers(style: style, weights: pose.fidgetWeights, in: context)
        } else {
            let mix = pose.handMix
            PointerBitmap.draw(normal, in: context, opacity: 1 - mix, clip: PointerGeometry.gloveClip(style))
            if mix > 0, let hand = IdleImages.bitmaps["Catch"],
               let object = IdleImages.bitmaps[PointerImages.filename(style) + "Object"] {
                context.saveGState()
                context.setAlpha(mix)
                context.beginTransparencyLayer(auxiliaryInfo: nil)
                let lift = min(pose.lift, max(0, availableTopRoom - 10))
                context.saveGState()
                context.translateBy(x: 50, y: 65 - lift)
                context.rotate(by: pose.rotation * .pi / 180)
                context.translateBy(x: -50, y: -65)
                context.clip(to: CGRect(x: 25, y: -100, width: 50, height: 280))
                PointerBitmap.draw(object, in: context)
                context.restoreGState()
                context.translateBy(x: PointerGeometry.wrist(style).x - 48.5, y: PointerGeometry.cuffBottom(style) - 127.5)
                PointerBitmap.draw(hand, in: context, clip: PointerGeometry.gloveClip(.wizardWand))
                context.endTransparencyLayer()
                context.restoreGState()
            }
        }
    }
}
