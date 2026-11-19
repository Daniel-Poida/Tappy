import SwiftUI
import Cocoa

/// Sprite coordinates use a 100 × 140 local canvas. Images are never stretched.
enum PointerGeometry {
    static func tip(_ style: PointerStyle) -> CGPoint {
        switch style {
        case .classic: return FingerCelArtwork.tip(style) ?? CGPoint(x: 48.8, y: 7.2)
        case .moonWand: return CGPoint(x: 50, y: 1.9)
        case .starWand: return CGPoint(x: 50, y: 2.4)
        case .wizardWand: return CGPoint(x: 50, y: 4.1)
        case .witch: return FingerCelArtwork.tip(style) ?? CGPoint(x: 57.5, y: 4)
        case .finnSword: return CGPoint(x: 50, y: 2.7)
        case .redLightsaber, .greenLightsaber: return CGPoint(x: 50, y: 5.2)
        }
    }
    static func middleTip(_ style: PointerStyle) -> CGPoint {
        FingerCelArtwork.tip(style, middle: true) ?? (style == .witch ? CGPoint(x: 60.16, y: 4.47) : CGPoint(x: 55.69, y: 7.26))
    }
    static func wrist(_ style: PointerStyle) -> CGPoint {
        CGPoint(x: style == .classic ? 49.5 : style == .witch ? 49.3 : [.wizardWand, .finnSword, .redLightsaber, .greenLightsaber].contains(style) ? 48.5 : 50, y: wristRim(style) - 2)
    }
    /// Clip at the cuff, before the straight wrist painted into each source PNG.
    static func cuffBottom(_ style: PointerStyle) -> CGFloat {
        switch style {
        case .classic: return 123.5
        case .moonWand: return 128
        case .starWand, .wizardWand, .finnSword, .redLightsaber, .greenLightsaber: return 127.5
        case .witch: return 130
        }
    }
    static func wristRim(_ style: PointerStyle) -> CGFloat {
        switch style {
        case .classic: return 117.5
        case .moonWand: return 127
        case .starWand: return 126.3
        case .wizardWand, .finnSword, .redLightsaber, .greenLightsaber: return 126.8
        case .witch: return 119.5
        }
    }
    static func gloveClip(_ style: PointerStyle) -> Path {
        let center = wrist(style).x
        let half = (wristWidth(style) + 3) / 2
        // Cut out the painted wrist from its opening, retaining the curved cuff
        // on both sides. A flat bottom crop leaves a rigid black neck attached.
        var path = Path(CGRect(x: -20, y: -100, width: 140, height: 100 + wristRim(style)))
        path.addRect(CGRect(x: -20, y: wristRim(style), width: center - half + 20, height: cuffBottom(style) - wristRim(style)))
        path.addRect(CGRect(x: center + half, y: wristRim(style), width: 120 - center - half, height: cuffBottom(style) - wristRim(style)))
        return path
    }
    static func wristWidth(_ style: PointerStyle) -> CGFloat { style.isFingerHand ? 15.8 : [.wizardWand, .finnSword, .redLightsaber, .greenLightsaber].contains(style) ? 12.5 : 10.2 }
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
        switch style { case .classic: return "Classic"; case .moonWand: return "MoonWand"; case .starWand: return "StarWand"; case .wizardWand: return "WizardWand"; case .witch: return "Witch"; case .finnSword: return "FinnSword"; case .redLightsaber: return "RedLightsaber"; case .greenLightsaber: return "GreenLightsaber" }
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
    static let bitmaps = images.compactMapValues(PointerBitmap.decode)
}

/// Decode once on the CPU. Drawing a SwiftUI Image from a lazy NSImage during
/// rapid animation can defer the bitmap while its vector forearm is already ready.
enum PointerBitmap {
    static func decode(_ image: NSImage) -> CGImage? {
        guard let source = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let context = CGContext(data: nil, width: source.width, height: source.height,
                  bitsPerComponent: 8, bytesPerRow: source.width * 4,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.draw(source, in: CGRect(x: 0, y: 0, width: source.width, height: source.height))
        return context.makeImage()
    }
    static func draw(_ image: CGImage, in context: inout GraphicsContext, opacity: Double = 1, clip: Path? = nil) {
        context.withCGContext { cg in draw(image, in: cg, opacity: opacity, clip: clip) }
    }
    static func draw(_ image: CGImage, in cg: CGContext, opacity: Double = 1, clip: Path? = nil) {
        cg.saveGState()
        if let clip { cg.addPath(clip.cgPath); cg.clip() }
        cg.setAlpha(opacity)
        cg.interpolationQuality = .high
        cg.translateBy(x: -20, y: 140)
        cg.scaleBy(x: 140 / CGFloat(image.width), y: -140 / CGFloat(image.height))
        cg.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        cg.restoreGState()
    }
}

struct PointerPose {
    var style: PointerStyle
    var size: Double = 1
    var tapping = false
    var impact: Double = 0
    var reduceMotion = false
    var lean: Double = -10
    var hotspot: CGPoint?
    var scaleX: Double { scaleX(at: tapping ? 1 : 0) }
    var scaleY: Double { scaleY(at: tapping ? 1 : 0) }
    var angle: Double { angle(at: tapping ? 1 : 0) }
    func scaleX(at progress: Double) -> Double { 1 + progress * (0.03 + impact * 0.20) }
    func scaleY(at progress: Double) -> Double { 1 - progress * (0.09 + impact * 0.22) }
    func angle(at progress: Double) -> Double { reduceMotion ? 0 : lean + progress * (14 + impact * 15) }
    func transform(position: CGPoint = .zero, progress: Double) -> CGAffineTransform {
        let tip = hotspot ?? PointerGeometry.tip(style)
        return CGAffineTransform(translationX: position.x, y: position.y)
            .rotated(by: angle(at: progress) * .pi / 180)
            .scaledBy(x: size * scaleX(at: progress), y: size * scaleY(at: progress))
            .translatedBy(x: -tip.x, y: -tip.y)
    }
    func offset(of point: CGPoint, progress: Double? = nil) -> CGPoint {
        point.applying(transform(progress: progress ?? (tapping ? 1 : 0)))
    }
}

struct PointerArtwork: View {
    var style: PointerStyle = .classic
    var shadow = true
    var lifted = false
    static func draw(_ image: CGImage, style: PointerStyle, in context: inout GraphicsContext, opacity: Double = 1) {
        PointerBitmap.draw(image, in: &context, opacity: opacity, clip: PointerGeometry.gloveClip(style))
    }
    var body: some View {
        Canvas { context, size in
            guard let image = PointerImages.bitmaps[style] else { return }
            context.scaleBy(x: size.width / 100, y: size.height / 140)
            if shadow { context.addFilter(.shadow(color: .black.opacity(lifted ? 0.30 : 0.23), radius: lifted ? 4 : 2, x: 3, y: lifted ? 7 : 3)) }
            Self.draw(image, style: style, in: &context)
        }.accessibilityHidden(true)
    }
}

/// Finite forearm geometry; length is independent of screen height.
struct ForearmGeometry {
    let start: CGPoint
    let end: CGPoint
    let path: Path
    init(position: CGPoint, pose: PointerPose, progress: Double, length: Double = 190) {
        let wrist = PointerGeometry.wrist(pose.style)
        let offset = pose.offset(of: wrist, progress: progress)
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

/// A single animated phase and Canvas transform drive both halves of the wrist.
/// Rendering together also applies the shadow to the joined silhouette only.
struct PointerFigure: View, Animatable {
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
    var idleTime: Double?
    var availableTopRoom: Double = 100
    var phase: Double?
    var fingerWeights: [Double]?
    var animatableData: Double {
        get { phase ?? (tapping ? 1 : 0) }
        set { phase = newValue }
    }
    func draw(in context: CGContext, canvas: CGSize) {
        let progress = style.isFingerHand && fingerWeights != nil ? 0 : phase ?? (tapping ? 1.0 : 0.0)
        let secondary = style.isFingerHand ? fingerWeights : nil
        let middleWeight = secondary?[FingerPose.middle.rawValue] ?? 0
        let indexTip = PointerGeometry.tip(style), middleTip = PointerGeometry.middleTip(style)
        let activeTip = CGPoint(x: indexTip.x + (middleTip.x - indexTip.x) * middleWeight,
                                y: indexTip.y + (middleTip.y - indexTip.y) * middleWeight)
        let pose = PointerPose(style: style, size: size, tapping: tapping, impact: impact, reduceMotion: reduceMotion, lean: lean,
                               hotspot: secondary == nil ? nil : activeTip)
        let wristOffset = pose.offset(of: PointerGeometry.wrist(style), progress: progress)
        let length = ForearmGeometry.resolvedLength(extensionFraction: extensionFraction, canvasHeight: canvas.height,
            wristY: position.y + wristOffset.y, size: size, lean: reduceMotion ? 0 : lean)
        let arm = ForearmGeometry(position: position, pose: pose, progress: progress, length: max(extensionLength, length))
        let fractions: [CGFloat] = [0, 0.08, 0.16, 0.22, 0.68, 0.78, 0.9, 1]
        func gradient(white: CGFloat, opacity: Double) -> CGGradient {
            let colors = fractions.map { CGColor(gray: white, alpha: opacity * ForearmGeometry.opacity(at: $0, lowerOpacity: lowerOpacity)) }
            return CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(), colors: colors as CFArray, locations: fractions)!
        }
        context.saveGState()
        if shadow { context.setShadow(offset: CGSize(width: 3 * size, height: 5 * size), blur: 3 * size, color: CGColor(gray: 0, alpha: 0.23)) }
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.saveGState()
        context.addPath(arm.path.cgPath)
        context.setLineWidth(2.5 * size)
        context.replacePathWithStrokedPath(); context.clip()
        context.drawLinearGradient(gradient(white: 1, opacity: 0.85), start: arm.start, end: arm.end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context.restoreGState()
        context.saveGState()
        context.addPath(arm.path.cgPath); context.clip()
        context.drawLinearGradient(gradient(white: 0, opacity: 1), start: arm.start, end: arm.end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context.restoreGState()
        context.concatenate(pose.transform(position: position, progress: progress))
        if let secondary {
            IdlePointerArtwork.drawFingers(style: style, weights: secondary, in: context)
        } else if let idleTime, !reduceMotion {
            IdlePointerArtwork.draw(style: style, time: idleTime, in: context,
                availableTopRoom: availableTopRoom / max(0.1, size))
        } else if style.isFingerHand {
            FingerCelArtwork.draw(style:style,weights:FingerPose.index.weights,in:context)
        } else if let image = PointerImages.bitmaps[style] {
            PointerBitmap.draw(image, in: context, clip: PointerGeometry.gloveClip(style))
        }
        context.endTransparencyLayer()
        context.restoreGState()
    }
    var body: some View {
        Canvas { context, canvas in
            context.withCGContext { draw(in: $0, canvas: canvas) }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
