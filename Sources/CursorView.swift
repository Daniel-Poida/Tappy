import SwiftUI

struct CursorView: View {
    @StateObject private var settings = PokeySettings.shared
    @State private var position: CGPoint = .zero
    @State private var isTapping: Bool = false
    @State private var burstTrigger: Int = 0
    @State private var energy: Double = 0.0

    private let clickHistory = ClickHistory()

    var body: some View {
        ZStack {
            handView
                .scaleEffect(handScale, anchor: .top)
                .rotationEffect(handRotation)
                .position(position)
                .animation(.easeOut(duration: 0.08), value: isTapping)

            BurstView(intensity: burstIntensity + energy)
                .position(position)
                .opacity(isTapping ? 1 : 0)
                .scaleEffect(isTapping ? 1.0 : 0.1, anchor: .center)
                .animation(.easeOut(duration: 0.15), value: isTapping)
                .id(burstTrigger)
        }
        .ignoresSafeArea()
    }

    private var handView: some View {
        HandShape(style: settings.pointerStyle)
            .fill(Color.white)
            .overlay(
                HandShape(style: settings.pointerStyle)
                    .stroke(Color.black, lineWidth: 3)
            )
            .frame(width: 90, height: 130)
    }

    private var handScale: CGFloat {
        let base = isTapping ? 0.85 : 1.0
        let punch = isTapping ? CGFloat(energy * 0.4) : 0
        return base - punch
    }

    private var handRotation: Angle {
        .degrees(-15 + (isTapping ? energy * 10 : 0))
    }

    private var burstIntensity: Double {
        settings.mood * 0.6 + 0.2
    }

    func move(to point: CGPoint) {
        position = point
    }

    func tap() {
        clickHistory.record()
        energy = clickHistory.energy()

        isTapping = true
        burstTrigger += 1

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            isTapping = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            energy = clickHistory.energy()
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
        let rate = max(0, min(1, 1.0 - (avg / 0.4)))
        return rate
    }

    private func prune() {
        let cutoff = Date().addingTimeInterval(-1.0)
        clicks.removeAll { $0 < cutoff }
    }
}

struct BurstView: View {
    let intensity: Double

    var body: some View {
        let rayCount = max(6, Int(intensity * 18))
        GeometryReader { _ in
            ZStack {
                ForEach(0..<rayCount, id: \.self) { i in
                    BurstRay(index: i, total: rayCount)
                        .fill(Color.white)
                        .overlay(BurstRay(index: i, total: rayCount).stroke(Color.black, lineWidth: 1))
                        .frame(width: 8 + intensity * 12, height: 24 + intensity * 30)
                        .rotationEffect(.degrees(Double(i) / Double(rayCount) * 360))
                }
            }
        }
        .frame(width: 140, height: 140)
    }
}

struct BurstRay: Shape {
    let index: Int
    let total: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.3, y: rect.minY + rect.height * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.midX + rect.width * 0.3, y: rect.minY + rect.height * 0.3),
                          control: CGPoint(x: rect.midX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct HandShape: Shape {
    let style: PointerStyle

    func path(in rect: CGRect) -> Path {
        switch style {
        case .tinyHand:
            return pointingHandPath(in: rect)
        case .catPaw:
            return catPawPath(in: rect)
        case .middleChild:
            return middleFingerPath(in: rect)
        }
    }

    private func pointingHandPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let tipX = w * 0.55
        let tipY = h * 0.02
        let fingerWidth = w * 0.22
        let fingerLen = h * 0.55

        path.move(to: CGPoint(x: tipX, y: tipY))
        path.addQuadCurve(to: CGPoint(x: tipX + fingerWidth / 2, y: tipY + fingerLen * 0.9),
                          control: CGPoint(x: tipX + fingerWidth * 0.6, y: tipY + fingerLen * 0.4))

        let midX = tipX + fingerWidth * 0.85
        let midY = tipY + fingerLen * 0.75
        path.addEllipse(in: CGRect(x: midX - fingerWidth * 0.35, y: midY, width: fingerWidth * 0.75, height: fingerWidth * 0.9))
        path.addEllipse(in: CGRect(x: midX + fingerWidth * 0.25, y: midY + fingerWidth * 0.45, width: fingerWidth * 0.7, height: fingerWidth * 0.85))
        path.addEllipse(in: CGRect(x: midX + fingerWidth * 0.55, y: midY + fingerWidth * 0.95, width: fingerWidth * 0.6, height: fingerWidth * 0.8))

        path.addQuadCurve(to: CGPoint(x: tipX - fingerWidth / 2, y: tipY + fingerLen * 0.9),
                          control: CGPoint(x: tipX - fingerWidth, y: midY + fingerLen * 0.3))
        path.addQuadCurve(to: CGPoint(x: tipX, y: tipY),
                          control: CGPoint(x: tipX - fingerWidth * 0.6, y: tipY + fingerLen * 0.4))

        path.move(to: CGPoint(x: tipX - fingerWidth * 0.4, y: midY + fingerWidth * 1.2))
        path.addLine(to: CGPoint(x: tipX + fingerWidth * 1.6, y: midY + fingerWidth * 2.4))
        path.addQuadCurve(to: CGPoint(x: tipX + fingerWidth * 2.0, y: midY + fingerWidth * 3.0),
                          control: CGPoint(x: tipX + fingerWidth * 2.2, y: midY + fingerWidth * 2.5))
        path.addLine(to: CGPoint(x: tipX - fingerWidth * 0.2, y: midY + fingerWidth * 2.0))
        path.closeSubpath()

        return path
    }

    private func catPawPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let center = CGPoint(x: w * 0.5, y: h * 0.45)
        let padRadius = w * 0.28

        path.addEllipse(in: CGRect(x: center.x - padRadius, y: center.y - padRadius,
                                   width: padRadius * 2, height: padRadius * 2))

        for i in -1...1 {
            let toeX = center.x + CGFloat(i) * padRadius * 0.7
            let toeY = center.y - padRadius * 1.1
            path.addEllipse(in: CGRect(x: toeX - padRadius * 0.28, y: toeY - padRadius * 0.35,
                                       width: padRadius * 0.56, height: padRadius * 0.7))
        }

        path.move(to: CGPoint(x: center.x - padRadius * 0.6, y: center.y + padRadius * 0.7))
        path.addLine(to: CGPoint(x: center.x + padRadius * 0.2, y: center.y + padRadius * 2.2))
        path.addQuadCurve(to: CGPoint(x: center.x + padRadius * 0.6, y: center.y + padRadius * 2.0),
                          control: CGPoint(x: center.x + padRadius * 0.7, y: center.y + padRadius * 2.4))
        path.addLine(to: CGPoint(x: center.x - padRadius * 0.2, y: center.y + padRadius * 0.6))
        path.closeSubpath()

        return path
    }

    private func middleFingerPath(in rect: CGRect) -> Path {
        var path = pointingHandPath(in: rect)
        // Same hand, but the middle finger is raised higher visually by scaling
        // For simplicity reuse the pointing hand path.
        return path
    }
}
