import Cocoa

/// Each sample is one complete painted hand. Only a constant uniform scale and
/// translation register its cuff; no fingers are cut, warped or crossfaded.
enum FingerCelArtwork {
    struct Registration: Decodable {
        let width, center, opening, cuffWidth, tipX, tipY: Double
    }
    struct Cel {
        let image: CGImage
        let rect: CGRect
        let tip: CGPoint
        let wrist: CGPoint
        let cuffWidth: Double
    }
    static func resource(_ name: String, extension ext: String) -> URL? {
        let relative = "Hands/Idle/Frames/\(name).\(ext)"
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Tappy_Tappy.bundle/\(relative)"),
           FileManager.default.fileExists(atPath: url.path) { return url }
        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Hands/Idle/Frames")
        #else
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/Resources/\(relative)")
        #endif
    }
    static let frames: [PointerStyle: [Cel]] = {
        guard let url = resource("Registration", extension: "json"), let data = try? Data(contentsOf: url),
              let registrations = try? JSONDecoder().decode([String: Registration].self, from: data) else { return [:] }
        var result: [PointerStyle: [Cel]] = [:]
        for style: PointerStyle in [.classic, .witch] {
            let name = PointerImages.filename(style)
            guard let reference = registrations[name] else { continue }
            let wrist = CGPoint(x: -20 + 140 * reference.center / reference.width,
                                y: 140 * reference.opening / reference.width)
            let cuffWidth = 140 * reference.cuffWidth / reference.width
            var cels: [Cel] = []
            for page in ["A", "B", "C", "D"] {
                guard let url = resource(name + page, extension: "png"), let image = NSImage(contentsOf: url),
                      let sheet = PointerBitmap.decode(image), sheet.width == sheet.height, sheet.width % 2 == 0 else { break }
                let size = sheet.width / 2
                for cell in 0..<4 {
                    guard let registration = registrations[name + page + String(cell)],
                          let bitmap = sheet.cropping(to: CGRect(x: cell % 2 * size, y: cell / 2 * size, width: size, height: size)) else { break }
                    let scale = cuffWidth / registration.cuffWidth
                    let origin = CGPoint(x: wrist.x - registration.center * scale,
                                         y: wrist.y - registration.opening * scale)
                    cels.append(Cel(image: bitmap,
                        rect: CGRect(origin: origin, size: CGSize(width: Double(size) * scale, height: Double(size) * scale)),
                        tip: CGPoint(x: origin.x + registration.tipX * scale, y: origin.y + registration.tipY * scale),
                        wrist: wrist, cuffWidth: cuffWidth))
                }
            }
            if cels.count == 16 { result[style] = cels }
        }
        return result
    }()

    /// The atlas contains the five held gestures and eleven painted in-betweens.
    /// Weights describe timing only; rendering selects exactly one opaque cel.
    static let samples: [[Double]] = {
        func blend(_ a: FingerPose, _ b: FingerPose, _ amount: Double) -> [Double] {
            zip(a.weights, b.weights).map { $0 * (1 - amount) + $1 * amount }
        }
        return [FingerPose.index.weights,
            blend(.index, .two, 0.25), blend(.index, .two, 0.65), FingerPose.two.weights,
            blend(.two, .three, 0.25), blend(.two, .three, 0.65), FingerPose.three.weights,
            blend(.three, .fist, 0.35), blend(.three, .fist, 0.70), FingerPose.fist.weights,
            blend(.fist, .middle, 0.35), blend(.fist, .middle, 0.70), FingerPose.middle.weights,
            blend(.fist, .index, 0.35), blend(.fist, .index, 0.70), FingerPose.index.weights]
    }()
    static func index(for weights: [Double]) -> Int {
        guard weights.count == FingerPose.allCases.count, weights.allSatisfy(\.isFinite) else { return 0 }
        return samples.indices.min { a, b in
            func distance(_ index: Int) -> Double { zip(samples[index], weights).reduce(0) { $0 + pow($1.0 - $1.1, 2) } }
            return distance(a) < distance(b)
        } ?? 0
    }
    static func tip(_ style: PointerStyle, middle: Bool = false) -> CGPoint? {
        frames[style]?[middle ? 12 : 0].tip
    }
    static func draw(style: PointerStyle, weights: [Double], in context: CGContext) {
        guard style.isFingerHand else { return }
        guard let cel = frames[style]?[index(for: weights)] else {
            if let image = PointerImages.bitmaps[style] { PointerBitmap.draw(image, in: context, clip: PointerGeometry.gloveClip(style)) }
            return
        }
        context.saveGState()
        context.addPath(PointerGeometry.gloveClip(style).cgPath); context.clip()
        context.interpolationQuality = .high
        context.translateBy(x: cel.rect.minX, y: cel.rect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(cel.image, in: CGRect(origin: .zero, size: cel.rect.size))
        context.restoreGState()
    }
}
