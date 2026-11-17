import SwiftUI
import Combine

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
    private var dynamics = ClickDynamics()
    private var releaseWork: DispatchWorkItem?
    private var burstWork: DispatchWorkItem?

    func move(to point: CGPoint) { position = point }
    func tick(at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        dynamics.decay(at: time)
        if abs(energy - dynamics.energy) > 0.005 { energy = dynamics.energy }
    }

    @discardableResult
    func tap(settings: TappySettings) -> Double {
        energy = dynamics.record(at: ProcessInfo.processInfo.systemUptime)
        impact = (0.16 + 0.84 * energy) * settings.mood
        guard settings.animateOnClick else { return energy }
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

    func reset() {
        releaseWork?.cancel(); burstWork?.cancel()
        dynamics = ClickDynamics()
        isTapping = false; burstVisible = false; energy = 0; impact = 0
    }
}
