import SwiftUI

struct CursorView: View {
    @ObservedObject private var settings = TappySettings.shared
    @ObservedObject var state: CursorState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            TapBurst(impact: state.impact, visible: state.burstVisible, style: settings.pointerStyle, reduceMotion: reduceMotion)
                .position(state.position)
            PointerSprite(style: settings.pointerStyle, size: settings.pointerSize, tapping: state.isTapping,
                          impact: state.impact, shadow: settings.shadowEnabled, reduceMotion: reduceMotion)
                .position(state.position)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct TapBurst: View {
    var impact: Double
    var visible: Bool
    var style: PointerStyle = .classic
    var reduceMotion = false
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let accent: Color = style == .moonWand ? .pink : style == .starWand ? .yellow : style == .wizardWand ? .cyan : Color(red: 0.45, green: 0.93, blue: 0.74)
            let count = 7 + Int(impact * 6)
            for i in 0..<count {
                let angle = Double(i) / Double(count) * .pi * 2
                let inner = 13.0 + impact * 7
                let outer = inner + 8 + impact * 23 * (i % 2 == 0 ? 1 : 0.6)
                var ray = Path()
                ray.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                ray.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                context.stroke(ray, with: .color(.white), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                context.stroke(ray, with: .color(Color(red: 0.12, green: 0.15, blue: 0.18)), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                context.stroke(ray, with: .color(impact > 0.8 ? .yellow : accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                if style != .classic && i % 2 == 0 {
                    let star = PointerGeometry.star(center: CGPoint(x: center.x + cos(angle) * (outer + 8), y: center.y + sin(angle) * (outer + 8)), radius: 3 + impact * 4, points: 4)
                    context.stroke(star, with: .color(.white), lineWidth: 3)
                    context.fill(star, with: .color(accent))
                }
            }
        }
        .frame(width: 130, height: 130)
        .scaleEffect(visible || reduceMotion ? 1 : 0.6)
        .opacity(visible ? 1 : 0)
        .accessibilityHidden(true)
    }
}
