import SwiftUI
import Combine
import Cocoa

enum PointerButton {
    case primary, secondary, other
    init(event: NSEvent) {
        self = event.buttonNumber == 1 ? .secondary : event.buttonNumber == 0 ? .primary : .other
    }
}

/// Monotonic-time click energy. It decays continuously after a click, even at rest.
struct ClickDynamics {
    private(set) var energy: Double = 0
    private var lastClick: TimeInterval?
    private var lastUpdate: TimeInterval?

    mutating func decay(at time: TimeInterval) {
        if let lastUpdate { energy *= exp(-max(0, time - lastUpdate) / 0.48) }
        lastUpdate = time
        if energy < 0.002 { energy = 0 }
    }

    mutating func record(at time: TimeInterval) -> Double {
        decay(at: time)
        if let lastClick, time - lastClick < 0.55 {
            let speed = max(0, 1 - (time - lastClick) / 0.55)
            energy = min(1, energy + 0.24 + speed * 0.36)
        } else { energy = 0 }
        lastClick = time
        return energy
    }
}

final class CursorState: ObservableObject {
    @Published var position: CGPoint = .zero
    @Published var isTapping = false
    @Published var burstTrigger = 0
    @Published var energy = 0.0
    @Published var impact = 0.0
    @Published var burstVisible = false
    @Published var lean = -8.0
    @Published var idleTime: Double?
    @Published private(set) var fingerWeights: [Double]?
    var fingerPose: FingerPose? {
        guard let fingerWeights else { return nil }
        return FingerPose.allCases.max { fingerWeights[$0.rawValue] < fingerWeights[$1.rawValue] }
    }
    private var secondaryPressed = false
    private var secondaryGesture = SecondaryFingerGesture()
    private var orientation = PointerOrientation()
    private var lastActivity = ProcessInfo.processInfo.systemUptime
    private var idlePreviewStart: TimeInterval?
    private var dynamics = ClickDynamics()
    private var releaseWork: DispatchWorkItem?
    private var burstWork: DispatchWorkItem?

    func move(to point: CGPoint, canvas: CGSize? = nil) {
        if point != position { noteActivity() }
        position = point
        if let canvas { trackOrientation(at: point, canvas: canvas) }
    }
    func trackOrientation(at point: CGPoint, canvas: CGSize, time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        let next = orientation.update(point: point, canvas: canvas, at: time)
        if abs(lean - next) > 0.025 { lean = next }
    }
    func tick(at time: TimeInterval = ProcessInfo.processInfo.systemUptime, systemIdle: Double? = nil,
              settings: TappySettings = .shared, reduceMotion: Bool = false, secondaryDown: Bool? = nil) {
        if secondaryPressed, secondaryDown == false { release(button: .secondary, at: time) }
        let nextFingers = secondaryGesture.weights(at: time)
        if nextFingers != fingerWeights { fingerWeights = nextFingers }
        dynamics.decay(at: time)
        if abs(energy - dynamics.energy) > 0.005 { energy = dynamics.energy }
        if let start = idlePreviewStart, settings.idleEnabled, !reduceMotion {
            if time - start > 0.3, let systemIdle, systemIdle < 0.06 { noteActivity(at: time); return }
            if time - start < IdlePose.duration(for: settings.pointerStyle) { idleTime = time - start; return }
            noteActivity(at: time)
        }
        let idleFor = max(0, min(time - lastActivity, systemIdle ?? .infinity))
        let next = IdleAnimationSchedule.phase(idleFor: idleFor, interval: settings.idleDelay,
                                               duration: IdlePose.duration(for: settings.pointerStyle),
                                               enabled: settings.idleEnabled && !reduceMotion)
        if next != idleTime { idleTime = next }
    }
    func noteActivity(at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        lastActivity = time; idlePreviewStart = nil
        if idleTime != nil { idleTime = nil }
    }
    func previewIdle() {
        idlePreviewStart = ProcessInfo.processInfo.systemUptime
        idleTime = 0
    }

    @discardableResult
    func tap(settings: TappySettings, button: PointerButton = .primary,
             at time: TimeInterval = ProcessInfo.processInfo.systemUptime, reduceMotion: Bool = false) -> Double {
        noteActivity(at: time)
        secondaryPressed = button == .secondary
        if secondaryPressed { secondaryGesture.press(at: time, animated: settings.animateOnClick && !reduceMotion) }
        else { secondaryGesture.release(at: time) }
        fingerWeights = secondaryGesture.weights(at: time)
        energy = dynamics.record(at: time)
        impact = (0.16 + 0.84 * energy) * settings.mood
        guard settings.animateOnClick && !reduceMotion else { return energy }
        releaseWork?.cancel()
        burstWork?.cancel()
        burstVisible = false
        burstTrigger += 1
        withAnimation(.easeIn(duration: 0.045)) { isTapping = true }
        withAnimation(.easeOut(duration: 0.07)) { burstVisible = true }
        let release = DispatchWorkItem { [weak self] in
            withAnimation(.interpolatingSpring(stiffness: 280, damping: 12)) { self?.isTapping = false }
        }
        releaseWork = release
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.075, execute: release)
        let burst = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.18)) { self?.burstVisible = false }
        }
        burstWork = burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13, execute: burst)
        return energy
    }

    func release(button: PointerButton, at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard button == .secondary, secondaryPressed else { return }
        secondaryPressed = false
        secondaryGesture.release(at: time)
    }

    func reset() {
        releaseWork?.cancel(); burstWork?.cancel()
        dynamics = ClickDynamics()
        orientation = PointerOrientation()
        lean = -8
        noteActivity()
        isTapping = false; burstVisible = false; energy = 0; impact = 0
        secondaryPressed = false; secondaryGesture.reset(); fingerWeights = nil
    }
}

/// Position gives the hand a natural angle; velocity adds a small, damped lag.
struct PointerOrientation {
    private(set) var angle = -8.0
    private var previousPoint: CGPoint?
    private var previousTime: TimeInterval?
    mutating func update(point: CGPoint, canvas: CGSize, at time: TimeInterval) -> Double {
        let dt = min(0.1, max(0.001, time - (previousTime ?? time - 1.0 / 90)))
        let x = min(1, max(0, point.x / max(1, canvas.width)))
        var motion = 0.0
        if let previousPoint, let previousTime, time > previousTime {
            let velocity = (point.x - previousPoint.x) / max(0.001, time - previousTime)
            motion = min(10, max(-10, velocity * 0.008))
        }
        let target = min(34, max(-34, -28 + x * 48 + motion))
        angle += (target - angle) * (1 - exp(-dt / 0.12))
        previousPoint = point; previousTime = time
        return angle
    }
}
