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
            PointerFigure(position: state.position, style: settings.pointerStyle, size: settings.pointerSize,
                          tapping: state.isTapping, impact: state.impact, shadow: settings.shadowEnabled, reduceMotion: reduceMotion,
                          lean: state.lean, lowerOpacity: settings.armOpacity, extensionFraction: settings.armExtension,
                          idleTime: state.idleTime, availableTopRoom: state.position.y)
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
    static func draw(in context: CGContext, position: CGPoint, impact: Double, style: PointerStyle, opacity: Double) {
        guard opacity > 0 else { return }
        context.saveGState()
        context.setAlpha(opacity)
        context.translateBy(x: position.x, y: position.y)
        let scale = 0.6 + 0.4 * opacity
        context.scaleBy(x: scale, y: scale)
        let accent: CGColor = style == .moonWand ? NSColor.systemPink.cgColor : style == .starWand ? NSColor.systemYellow.cgColor : style == .wizardWand ? NSColor.systemCyan.cgColor : CGColor(red: 0.45, green: 0.93, blue: 0.74, alpha: 1)
        for i in 0..<(7 + Int(impact * 6)) {
            let angle = Double(i) / Double(7 + Int(impact * 6)) * .pi * 2
            let inner = 13 + impact * 7
            let outer = inner + 8 + impact * 23 * (i % 2 == 0 ? 1 : 0.6)
            let a = CGPoint(x: cos(angle) * inner, y: sin(angle) * inner)
            let b = CGPoint(x: cos(angle) * outer, y: sin(angle) * outer)
            context.setLineCap(.round)
            for (color, width) in [(NSColor.white.cgColor, 7.0), (CGColor(red: 0.12, green: 0.15, blue: 0.18, alpha: 1), 4.5), (impact > 0.8 ? NSColor.systemYellow.cgColor : accent, 2.0)] {
                context.setStrokeColor(color); context.setLineWidth(width)
                context.move(to: a); context.addLine(to: b); context.strokePath()
            }
            if style != .classic && i % 2 == 0 {
                let star = PointerGeometry.star(center: CGPoint(x: cos(angle) * (outer + 8), y: sin(angle) * (outer + 8)), radius: 3 + impact * 4, points: 4)
                context.addPath(star.cgPath); context.setStrokeColor(NSColor.white.cgColor); context.setLineWidth(3); context.strokePath()
                context.addPath(star.cgPath); context.setFillColor(accent); context.fillPath()
            }
        }
        context.restoreGState()
    }
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
