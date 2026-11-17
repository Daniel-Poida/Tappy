import SwiftUI
import Cocoa

/// Sprite coordinates use a 100 × 140 local canvas. Images are never stretched.
enum PointerGeometry {
    static func tip(_ style: PointerStyle) -> CGPoint {
        switch style {
        case .classic: return CGPoint(x: 48.8, y: 7.2)
        case .moonWand: return CGPoint(x: 50, y: 1.9)
        case .starWand: return CGPoint(x: 50, y: 2.4)
        case .wizardWand: return CGPoint(x: 50, y: 4.1)
        }
    }
    static func wrist(_ style: PointerStyle) -> CGPoint {
        CGPoint(x: style == .classic ? 49.5 : style == .wizardWand ? 48.5 : 50, y: 128)
    }
    static func wristWidth(_ style: PointerStyle) -> CGFloat { style == .classic ? 15.8 : style == .wizardWand ? 12.5 : 10.2 }
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
    // A separate simplified outline keeps the small monochrome menu icon crisp.
    static func outline(_ style: PointerStyle) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 46, y: 8))
        p.addCurve(to: CGPoint(x: 59, y: 23), control1: CGPoint(x: 56, y: 8), control2: CGPoint(x: 61, y: 14))
        p.addLine(to: CGPoint(x: 55, y: 57))
        p.addCurve(to: CGPoint(x: 72, y: 61), control1: CGPoint(x: 68, y: 48), control2: CGPoint(x: 74, y: 53))
        p.addCurve(to: CGPoint(x: 89, y: 75), control1: CGPoint(x: 84, y: 55), control2: CGPoint(x: 94, y: 64))
        p.addCurve(to: CGPoint(x: 77, y: 111), control1: CGPoint(x: 95, y: 91), control2: CGPoint(x: 86, y: 103))
        p.addLine(to: CGPoint(x: 77, y: 126))
        p.addQuadCurve(to: CGPoint(x: 38, y: 126), control: CGPoint(x: 57, y: 135))
        p.addLine(to: CGPoint(x: 37, y: 111))
        p.addCurve(to: CGPoint(x: 15, y: 83), control1: CGPoint(x: 24, y: 105), control2: CGPoint(x: 23, y: 92))
        p.addCurve(to: CGPoint(x: 31, y: 65), control1: CGPoint(x: 0, y: 76), control2: CGPoint(x: 14, y: 54))
        p.addLine(to: CGPoint(x: 34, y: 69)); p.addLine(to: CGPoint(x: 34, y: 23))
        p.addCurve(to: CGPoint(x: 46, y: 8), control1: CGPoint(x: 34, y: 12), control2: CGPoint(x: 39, y: 8))
        p.closeSubpath(); return p
    }
    static func creases(_ style: PointerStyle) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 39, y: 114)); p.addQuadCurve(to: CGPoint(x: 75, y: 114), control: CGPoint(x: 57, y: 122))
        for x in [48.0, 60, 72] {
            p.move(to: CGPoint(x: x, y: 81)); p.addQuadCurve(to: CGPoint(x: x + 3, y: 97), control: CGPoint(x: x + 5, y: 89))
        }
        return p
    }
}

enum PointerImages {
    static func filename(_ style: PointerStyle) -> String {
        switch style { case .classic: return "Classic"; case .moonWand: return "MoonWand"; case .starWand: return "StarWand"; case .wizardWand: return "WizardWand" }
    }
    static let images: [PointerStyle: NSImage] = {
        var result: [PointerStyle: NSImage] = [:]
        for style in PointerStyle.allCases {
            let name = filename(style)
            // Resolve the bundle inside the application first; the SwiftPM accessor also
            // supports running directly from .build during development.
            let appURL = Bundle.main.resourceURL?.appendingPathComponent("Tappy_Tappy.bundle/Hands/\(name).png")
            if let appURL, let image = NSImage(contentsOf: appURL) {
                result[style] = image
                continue
            }
            #if SWIFT_PACKAGE
            let devURL = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Hands")
            #else
            let devURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/Resources/Hands/\(name).png")
            #endif
            if let url = [appURL, devURL].compactMap({ $0 }).first(where: { FileManager.default.fileExists(atPath: $0.path) }),
               let image = NSImage(contentsOf: url) { result[style] = image }
        }
        return result
    }()
}

struct PointerPose {
    var style: PointerStyle
    var size: Double = 1
    var tapping = false
    var impact: Double = 0
    var reduceMotion = false
    var lean: Double = -10
    var scaleX: Double { scaleX(at: tapping ? 1 : 0) }
    var scaleY: Double { scaleY(at: tapping ? 1 : 0) }
    var angle: Double { angle(at: tapping ? 1 : 0) }
    func scaleX(at progress: Double) -> Double { 1 + progress * (0.03 + impact * 0.20) }
    func scaleY(at progress: Double) -> Double { 1 - progress * (0.09 + impact * 0.22) }
    func angle(at progress: Double) -> Double { reduceMotion ? 0 : lean + progress * (14 + impact * 15) }
    func offset(of point: CGPoint, progress: Double? = nil) -> CGPoint {
        let progress = progress ?? (tapping ? 1 : 0)
        let tip = PointerGeometry.tip(style)
        let x = (point.x - tip.x) * size * scaleX(at: progress)
        let y = (point.y - tip.y) * size * scaleY(at: progress)
        let radians = angle(at: progress) * .pi / 180
        return CGPoint(x: x * Darwin.cos(radians) - y * Darwin.sin(radians), y: x * Darwin.sin(radians) + y * Darwin.cos(radians))
    }
}

struct PointerArtwork: View {
    var style: PointerStyle = .classic
    var shadow = true
    var lifted = false
    var body: some View {
        Canvas { context, size in
            guard let image = PointerImages.images[style] else { return }
            context.scaleBy(x: size.width / 100, y: size.height / 140)
            if shadow { context.addFilter(.shadow(color: .black.opacity(lifted ? 0.30 : 0.23), radius: lifted ? 4 : 2, x: 3, y: lifted ? 7 : 3)) }
            context.drawLayer { layer in
                // Trim the rounded wrist cap so the live forearm joins the glove seamlessly.
                layer.clip(to: Path(CGRect(x: -20, y: 0, width: 140, height: 130)))
                layer.draw(Image(nsImage: image), in: CGRect(x: -20, y: 0, width: 140, height: 140))
            }
        }.accessibilityHidden(true)
    }
}

struct PointerSprite: View {
    let style: PointerStyle
    var size: Double = 1
    var tapping = false
    var impact: Double = 0
    var shadow = true
    var reduceMotion = false
    var lean: Double = -10
    var idleTime: Double?
    var availableTopRoom: Double = 100
    var body: some View {
        let tip = PointerGeometry.tip(style)
        let anchor = UnitPoint(x: tip.x / 100, y: tip.y / 140)
        let pose = PointerPose(style: style, size: size, tapping: tapping, impact: impact, reduceMotion: reduceMotion, lean: lean)
        Group {
            if let idleTime, !reduceMotion {
                IdlePointerArtwork(style: style, time: idleTime, shadow: shadow, availableTopRoom: availableTopRoom)
            } else {
                PointerArtwork(style: style, shadow: shadow, lifted: !tapping)
            }
        }
            .frame(width: 100 * size, height: 140 * size)
            .scaleEffect(x: pose.scaleX, y: pose.scaleY, anchor: anchor)
            .rotationEffect(.degrees(pose.angle), anchor: anchor)
            .offset(x: (50 - tip.x) * size, y: (70 - tip.y) * size)
    }
}

/// Finite forearm geometry; length is independent of screen height.
struct ForearmGeometry {
    let start: CGPoint
    let end: CGPoint
    let path: Path
    init(position: CGPoint, pose: PointerPose, progress: Double, length: Double = 190) {
        let wrist = PointerGeometry.wrist(pose.style)
        let offset = pose.offset(of: CGPoint(x: wrist.x, y: wrist.y - 3), progress: progress)
        start = CGPoint(x: position.x + offset.x, y: position.y + offset.y)
        let angle = pose.angle(at: progress) * .pi / 180
        let baseAngle = (pose.reduceMotion ? 0 : pose.lean * 0.65) * .pi / 180
        let reach = min(20000, max(80, length)) * pose.size
        end = CGPoint(x: start.x - Darwin.sin(baseAngle) * reach, y: start.y + Darwin.cos(baseAngle) * reach)
        let c1 = CGPoint(x: start.x - Darwin.sin(angle) * reach * 0.34, y: start.y + Darwin.cos(angle) * reach * 0.34)
        let c2 = CGPoint(x: end.x + Darwin.sin(baseAngle) * reach * 0.28, y: end.y - Darwin.cos(baseAngle) * reach * 0.28)
        let half = PointerGeometry.wristWidth(pose.style) * 0.5
        var left: [CGPoint] = [], right: [CGPoint] = []
        for i in 0...40 {
            let t = Double(i) / 40, u = 1 - t
            let x = u*u*u*start.x + 3*u*u*t*c1.x + 3*u*t*t*c2.x + t*t*t*end.x
            let y = u*u*u*start.y + 3*u*u*t*c1.y + 3*u*t*t*c2.y + t*t*t*end.y
            let dx = 3*u*u*(c1.x-start.x) + 6*u*t*(c2.x-c1.x) + 3*t*t*(end.x-c2.x)
            let dy = 3*u*u*(c1.y-start.y) + 6*u*t*(c2.y-c1.y) + 3*t*t*(end.y-c2.y)
            let tangent = max(0.001, hypot(dx, dy))
            let radius = pose.size * (half * pose.scaleX(at: progress) * (1 - t) + 1.5 * t)
            left.append(CGPoint(x: x - dy/tangent*radius, y: y + dx/tangent*radius))
            right.append(CGPoint(x: x + dy/tangent*radius, y: y - dx/tangent*radius))
        }
        var shape = Path(); shape.addLines(left + right.reversed()); shape.closeSubpath(); path = shape
    }
    static func opacity(at fraction: Double, lowerOpacity: Double) -> Double {
        let t = min(1, max(0, fraction)), lower = min(1, max(0, lowerOpacity))
        func smooth(_ v: Double) -> Double { let x = min(1, max(0, v)); return x*x*(3 - 2*x) }
        if t < 0.22 { return 1 - (1 - lower) * smooth(t / 0.22) }
        return lower * (1 - smooth((t - 0.68) / 0.32))
    }
    /// Zero keeps the 1.2 short arm; one reaches below the current screen.
    static func resolvedLength(extensionFraction: Double, canvasHeight: Double, wristY: Double, size: Double, lean: Double) -> Double {
        let fraction = min(1, max(0, extensionFraction))
        let cosine = max(0.5, Darwin.cos(lean * 0.65 * .pi / 180))
        let full = max(190, (canvasHeight + 70 - wristY) / (cosine * max(0.01, size)))
        return 190 + (full - 190) * fraction
    }
}

/// The glove, outline and shadow all fade together along the lower forearm.
struct PointerArm: View, Animatable {
    var position: CGPoint
    var style: PointerStyle
    var size: Double = 1
    var tapping = false
    var impact: Double = 0
    var shadow = true
    var reduceMotion = false
    var lean: Double = -10
    var lowerOpacity: Double = 0.2
    var extensionFraction: Double = 0
    var extensionLength: Double = 190
    var phase: Double = -1
    var animatableData: Double {
        get { phase < 0 ? (tapping ? 1 : 0) : phase }
        set { phase = newValue }
    }
    var body: some View {
        let progress = phase < 0 ? (tapping ? 1.0 : 0.0) : phase
        Canvas { context, canvas in
            let pose = PointerPose(style: style, size: size, tapping: tapping, impact: impact, reduceMotion: reduceMotion, lean: lean)
            let wrist = PointerGeometry.wrist(style)
            let wristOffset = pose.offset(of: CGPoint(x: wrist.x, y: wrist.y - 3), progress: progress)
            let length = ForearmGeometry.resolvedLength(extensionFraction: extensionFraction, canvasHeight: canvas.height,
                wristY: position.y + wristOffset.y, size: size, lean: reduceMotion ? 0 : lean)
            let arm = ForearmGeometry(position: position, pose: pose, progress: progress, length: max(extensionLength, length))
            let fractions = [0.0, 0.08, 0.16, 0.22, 0.68, 0.78, 0.9, 1.0]
            let fill = Gradient(stops: fractions.map { .init(color: Color.black.opacity(ForearmGeometry.opacity(at: $0, lowerOpacity: lowerOpacity)), location: $0) })
            let stroke = Gradient(stops: fractions.map { .init(color: Color.white.opacity(0.85 * ForearmGeometry.opacity(at: $0, lowerOpacity: lowerOpacity)), location: $0) })
            if shadow { context.addFilter(.shadow(color: .black.opacity(0.18), radius: 3, x: 3, y: 5)) }
            context.drawLayer { layer in
                layer.stroke(arm.path, with: .linearGradient(stroke, startPoint: arm.start, endPoint: arm.end), lineWidth: 2.5)
                layer.fill(arm.path, with: .linearGradient(fill, startPoint: arm.start, endPoint: arm.end))
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
