import SwiftUI

/// Original vectors, shared by the cursor, the preview and both application icons.
enum PointerGeometry {
    static func tip(_ style: PointerStyle) -> CGPoint {
        CGPoint(x: style == .classic ? 43 : 50, y: 7)
    }

    static func outline(_ style: PointerStyle) -> Path {
        var p = Path()
        if style != .classic {
            // A curled cartoon glove holding a wand, with a distinct thumb and cuff.
            p.move(to: CGPoint(x: 45, y: 76))
            p.addCurve(to: CGPoint(x: 68, y: 77), control1: CGPoint(x: 49, y: 65), control2: CGPoint(x: 65, y: 67))
            p.addCurve(to: CGPoint(x: 77, y: 87), control1: CGPoint(x: 77, y: 73), control2: CGPoint(x: 82, y: 80))
            p.addCurve(to: CGPoint(x: 82, y: 100), control1: CGPoint(x: 87, y: 86), control2: CGPoint(x: 88, y: 94))
            p.addCurve(to: CGPoint(x: 72, y: 117), control1: CGPoint(x: 87, y: 108), control2: CGPoint(x: 77, y: 113))
            p.addLine(to: CGPoint(x: 74, y: 129))
            p.addQuadCurve(to: CGPoint(x: 35, y: 129), control: CGPoint(x: 55, y: 137))
            p.addLine(to: CGPoint(x: 35, y: 116))
            p.addCurve(to: CGPoint(x: 22, y: 94), control1: CGPoint(x: 27, y: 109), control2: CGPoint(x: 20, y: 100))
            p.addCurve(to: CGPoint(x: 34, y: 80), control1: CGPoint(x: 15, y: 81), control2: CGPoint(x: 25, y: 72))
            p.addLine(to: CGPoint(x: 45, y: 87))
            p.addLine(to: CGPoint(x: 45, y: 76))
        } else {
            p.move(to: CGPoint(x: 43, y: 7))
            p.addCurve(to: CGPoint(x: 52, y: 17), control1: CGPoint(x: 48, y: 7), control2: CGPoint(x: 52, y: 10))
            p.addLine(to: CGPoint(x: 52, y: 54))
            p.addCurve(to: CGPoint(x: 66, y: 59), control1: CGPoint(x: 61, y: 49), control2: CGPoint(x: 67, y: 51))
            p.addCurve(to: CGPoint(x: 79, y: 66), control1: CGPoint(x: 74, y: 54), control2: CGPoint(x: 81, y: 58))
            p.addCurve(to: CGPoint(x: 91, y: 78), control1: CGPoint(x: 88, y: 62), control2: CGPoint(x: 92, y: 69))
            p.addCurve(to: CGPoint(x: 78, y: 109), control1: CGPoint(x: 92, y: 94), control2: CGPoint(x: 84, y: 101))
            p.addLine(to: CGPoint(x: 79, y: 124))
            p.addQuadCurve(to: CGPoint(x: 39, y: 124), control: CGPoint(x: 59, y: 133))
            p.addLine(to: CGPoint(x: 38, y: 110))
            p.addCurve(to: CGPoint(x: 18, y: 80), control1: CGPoint(x: 29, y: 104), control2: CGPoint(x: 23, y: 88))
            p.addCurve(to: CGPoint(x: 18, y: 60), control1: CGPoint(x: 8, y: 71), control2: CGPoint(x: 9, y: 62))
            p.addCurve(to: CGPoint(x: 34, y: 69), control1: CGPoint(x: 24, y: 57), control2: CGPoint(x: 30, y: 62))
            p.addLine(to: CGPoint(x: 34, y: 18))
            p.addCurve(to: CGPoint(x: 43, y: 7), control1: CGPoint(x: 34, y: 11), control2: CGPoint(x: 37, y: 7))
        }
        p.closeSubpath()
        return p
    }

    static func creases(_ style: PointerStyle) -> Path {
        var p = Path()
        func curve(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) { p.move(to: a); p.addQuadCurve(to: b, control: c) }
        if style == .classic {
            curve(CGPoint(x: 39, y: 112), CGPoint(x: 77, y: 112), CGPoint(x: 57, y: 119))
            curve(CGPoint(x: 31, y: 73), CGPoint(x: 44, y: 87), CGPoint(x: 46, y: 72))
            curve(CGPoint(x: 53, y: 58), CGPoint(x: 55, y: 77), CGPoint(x: 51, y: 70))
            curve(CGPoint(x: 68, y: 64), CGPoint(x: 69, y: 80), CGPoint(x: 65, y: 73))
            curve(CGPoint(x: 80, y: 72), CGPoint(x: 79, y: 84), CGPoint(x: 77, y: 80))
            curve(CGPoint(x: 47, y: 94), CGPoint(x: 65, y: 96), CGPoint(x: 57, y: 90))
        } else {
            curve(CGPoint(x: 36, y: 117), CGPoint(x: 72, y: 119), CGPoint(x: 54, y: 125))
            curve(CGPoint(x: 35, y: 90), CGPoint(x: 52, y: 100), CGPoint(x: 54, y: 84))
            curve(CGPoint(x: 60, y: 80), CGPoint(x: 61, y: 89), CGPoint(x: 56, y: 85))
            curve(CGPoint(x: 73, y: 90), CGPoint(x: 58, y: 96), CGPoint(x: 62, y: 88))
            curve(CGPoint(x: 78, y: 101), CGPoint(x: 62, y: 106), CGPoint(x: 67, y: 100))
        }
        return p
    }

    static func star(center: CGPoint, radius: CGFloat, points: Int = 5) -> Path {
        var p = Path()
        for i in 0..<(points * 2) {
            let a = Double(i) * .pi / Double(points) - .pi / 2
            let r = i % 2 == 0 ? radius : radius * 0.46
            let v = CGPoint(x: center.x + CGFloat(Darwin.cos(a)) * r, y: center.y + CGFloat(Darwin.sin(a)) * r)
            if i == 0 { p.move(to: v) } else { p.addLine(to: v) }
        }
        p.closeSubpath(); return p
    }
}

struct PointerArtwork: View {
    var style: PointerStyle = .classic
    var shadow = true
    var lifted = false
    private let ink = Color(red: 0.12, green: 0.14, blue: 0.17)
    private let gold = Color(red: 1, green: 0.77, blue: 0.24)
    private let pink = Color(red: 0.98, green: 0.40, blue: 0.65)

    var body: some View {
        Canvas { context, size in
            context.scaleBy(x: size.width / 100, y: size.height / 140)
            if shadow {
                context.addFilter(.shadow(color: .black.opacity(lifted ? 0.38 : 0.30), radius: lifted ? 6 : 3,
                                          x: lifted ? 4 : 2, y: lifted ? 9 : 4))
            }
            context.drawLayer { layer in
                func draw(_ path: Path, _ color: Color, width: Double = 2.8) {
                    layer.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: width + 3.5, lineCap: .round, lineJoin: .round))
                    layer.fill(path, with: .color(color))
                    layer.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                }
                if style != .classic {
                    let stem = Path(roundedRect: CGRect(x: 45, y: 37, width: 10, height: 68), cornerRadius: 4)
                    draw(stem, style == .wizardWand ? Color(red: 0.39, green: 0.24, blue: 0.18) : pink)
                    if style == .moonWand {
                        // Crescent, winged jewel and pink handle.
                        var crescent = Path()
                        crescent.move(to: CGPoint(x: 26, y: 14))
                        crescent.addCurve(to: CGPoint(x: 50, y: 53), control1: CGPoint(x: 11, y: 35), control2: CGPoint(x: 28, y: 53))
                        crescent.addCurve(to: CGPoint(x: 74, y: 14), control1: CGPoint(x: 73, y: 53), control2: CGPoint(x: 90, y: 35))
                        crescent.addCurve(to: CGPoint(x: 50, y: 39), control1: CGPoint(x: 77, y: 32), control2: CGPoint(x: 65, y: 39))
                        crescent.addCurve(to: CGPoint(x: 26, y: 14), control1: CGPoint(x: 35, y: 39), control2: CGPoint(x: 23, y: 32))
                        crescent.closeSubpath()
                        draw(crescent, gold)
                        draw(PointerGeometry.star(center: CGPoint(x: 50, y: 14), radius: 7, points: 4), gold, width: 1.7)
                        for x: CGFloat in [23, 57] {
                            var wing = Path(); wing.move(to: CGPoint(x: x, y: 46)); wing.addLine(to: CGPoint(x: x - 6, y: 36))
                            wing.addQuadCurve(to: CGPoint(x: x + 20, y: 48), control: CGPoint(x: x + 19, y: 38)); wing.closeSubpath()
                            draw(wing, .white, width: 2)
                        }
                        draw(Path(ellipseIn: CGRect(x: 40, y: 36, width: 21, height: 21)), pink, width: 2)
                        draw(PointerGeometry.star(center: CGPoint(x: 50.5, y: 46), radius: 7), gold, width: 1.4)
                    } else if style == .starWand {
                        draw(Path(ellipseIn: CGRect(x: 22, y: 11, width: 56, height: 56)), Color(red: 0.65, green: 0.53, blue: 0.95))
                        draw(PointerGeometry.star(center: CGPoint(x: 50, y: 34), radius: 27), gold)
                        for x: CGFloat in [8, 71] {
                            var wing = Path(); wing.move(to: CGPoint(x: x + 13, y: 36)); wing.addLine(to: CGPoint(x: x, y: 26))
                            wing.addQuadCurve(to: CGPoint(x: x + 11, y: 55), control: CGPoint(x: x - 3, y: 48)); wing.closeSubpath()
                            draw(wing, .white, width: 2)
                        }
                        // A tiny heart on the handle.
                        var heart = Path(); heart.move(to: CGPoint(x: 50, y: 70))
                        heart.addCurve(to: CGPoint(x: 50, y: 59), control1: CGPoint(x: 35, y: 59), control2: CGPoint(x: 44, y: 52))
                        heart.addCurve(to: CGPoint(x: 50, y: 70), control1: CGPoint(x: 57, y: 52), control2: CGPoint(x: 65, y: 59))
                        draw(heart, pink, width: 1.5)
                    } else {
                        var wand = Path(); wand.move(to: CGPoint(x: 50, y: 7)); wand.addLine(to: CGPoint(x: 54, y: 72))
                        wand.addLine(to: CGPoint(x: 44, y: 72)); wand.closeSubpath()
                        draw(wand, Color(red: 0.49, green: 0.32, blue: 0.22), width: 2.5)
                        var grain = Path(); grain.move(to: CGPoint(x: 47, y: 51)); grain.addLine(to: CGPoint(x: 51, y: 56))
                        grain.move(to: CGPoint(x: 47, y: 60)); grain.addLine(to: CGPoint(x: 52, y: 65))
                        layer.stroke(grain, with: .color(gold.opacity(0.8)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                }
                let outline = PointerGeometry.outline(style)
                layer.stroke(outline, with: .color(.white), style: StrokeStyle(lineWidth: 6.5, lineJoin: .round))
                layer.fill(outline, with: .linearGradient(Gradient(colors: [.white, Color(red: 0.83, green: 0.88, blue: 0.91)]),
                    startPoint: CGPoint(x: 25, y: 35), endPoint: CGPoint(x: 90, y: 140)))
                layer.stroke(outline, with: .color(ink), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                layer.stroke(PointerGeometry.creases(style), with: .color(ink.opacity(0.8)), style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
            }
        }
        .accessibilityHidden(true)
    }
}

struct PointerSprite: View {
    let style: PointerStyle
    var size: Double = 1
    var tapping = false
    var impact: Double = 0
    var shadow = true
    var reduceMotion = false

    var body: some View {
        let tip = PointerGeometry.tip(style)
        let anchor = UnitPoint(x: tip.x / 100, y: tip.y / 140)
        PointerArtwork(style: style, shadow: shadow, lifted: !tapping)
            .frame(width: 100 * size, height: 140 * size)
            .scaleEffect(x: tapping ? 1.03 + impact * 0.20 : 1,
                         y: tapping ? 0.91 - impact * 0.22 : 1, anchor: anchor)
            .rotationEffect(.degrees(reduceMotion ? 0 : (tapping ? 4 + impact * 15 : -10)), anchor: anchor)
            .offset(x: (50 - tip.x) * size, y: (70 - tip.y) * size)
    }
}
