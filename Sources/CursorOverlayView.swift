import Cocoa

/// The live overlay owns one backing surface. Every update replaces its entire
/// transparent frame; no SwiftUI transition can retain a second pointer layer.
final class CursorOverlayView: NSView {
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { false }
    private var currentFrame: CursorOverlayFrame?
    private var motion = CursorTapMotion()
    private var lastBurst: Int?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layerContentsRedrawPolicy = .onSetNeedsDisplay
        layer?.isOpaque = false
        layer?.backgroundColor = CGColor(gray: 0, alpha: 0)
        layer?.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(state: CursorState, settings: TappySettings, at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        if let lastBurst, state.burstTrigger != lastBurst { motion.record(at: time) }
        lastBurst = state.burstTrigger
        if !settings.animateOnClick { motion.reset() }
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let figure = PointerFigure(position: state.position, style: settings.pointerStyle, size: settings.pointerSize,
            impact: state.impact, shadow: settings.shadowEnabled, reduceMotion: reduceMotion, lean: state.lean,
            lowerOpacity: settings.armOpacity, extensionFraction: settings.armExtension,
            idleTime: state.idleTime, availableTopRoom: state.position.y,
            phase: reduceMotion ? 0 : motion.phase(at: time))
        currentFrame = CursorOverlayFrame(figure: figure, burstOpacity: motion.burstOpacity(at: time))
        needsDisplay = true
    }
    func reset() { motion.reset(); lastBurst = nil; currentFrame = nil; needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        CursorOverlayFrame.draw(currentFrame, in: context, canvas: bounds.size)
    }
}

struct CursorOverlayFrame {
    var figure: PointerFigure
    var burstOpacity: Double = 0
    static func draw(_ frame: Self?, in context: CGContext, canvas: CGSize) {
        context.saveGState()
        // Clear the old cursor, including its shadow and arm, before drawing.
        context.clear(CGRect(origin: .zero, size: canvas))
        if let frame {
            TapBurst.draw(in: context, position: frame.figure.position, impact: frame.figure.impact,
                          style: frame.figure.style, opacity: frame.burstOpacity)
            frame.figure.draw(in: context, canvas: canvas)
        }
        context.restoreGState()
    }
}

/// Explicit monotonic-time motion for the native surface. Repeated taps restart
/// from the current phase, including spring overshoot, without another layer.
struct CursorTapMotion {
    private var startedAt: TimeInterval?
    private var initialPhase = 0.0
    mutating func record(at time: TimeInterval) { initialPhase = phase(at: time); startedAt = time }
    mutating func reset() { startedAt = nil; initialPhase = 0 }
    func phase(at time: TimeInterval) -> Double {
        guard let startedAt else { return 0 }
        let elapsed = max(0, time - startedAt)
        if elapsed < 0.045 { let t = elapsed / 0.045; return initialPhase + (1 - initialPhase) * t * t }
        if elapsed < 0.075 { return 1 }
        let t = elapsed - 0.075
        guard t < 1.5 else { return 0 }
        let frequency = sqrt(280.0 - 36)
        return exp(-6 * t) * (cos(frequency * t) + 6 / frequency * sin(frequency * t))
    }
    func burstOpacity(at time: TimeInterval) -> Double {
        guard let startedAt else { return 0 }
        let elapsed = max(0, time - startedAt)
        if elapsed < 0.07 { return elapsed / 0.07 }
        if elapsed < 0.13 { return 1 }
        return max(0, 1 - (elapsed - 0.13) / 0.18)
    }
}
