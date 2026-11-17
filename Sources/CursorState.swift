import SwiftUI
import Combine

final class CursorState: ObservableObject {
    @Published var position: CGPoint = .zero
    @Published var isTapping: Bool = false
    @Published var burstTrigger: Int = 0
    @Published var energy: Double = 0.0

    private let clickHistory = ClickHistory()

    func move(to point: CGPoint) {
        position = point
    }

    func tap(settings: TappySettings) {
        guard settings.animateOnClick else { return }
        clickHistory.record()
        energy = clickHistory.energy()
        isTapping = true
        burstTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.isTapping = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.energy = self?.clickHistory.energy() ?? 0
        }
    }
}

private class ClickHistory {
    private var clicks: [Date] = []

    func record() {
        clicks.append(Date())
        prune()
    }

    func energy() -> Double {
        prune()
        guard clicks.count >= 2 else { return 0 }
        let intervals = zip(clicks, clicks.dropFirst()).map { $1.timeIntervalSince($0) }
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        return max(0, min(1, 1.0 - (avg / 0.4)))
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-1.0)
        clicks.removeAll { $0 < cutoff }
    }
}
