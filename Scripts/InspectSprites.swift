import Foundation
import ImageIO
import CoreGraphics
for filename in CommandLine.arguments.dropFirst() {
    let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: filename) as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let w = image.width, h = image.height
    var bytes = [UInt8](repeating: 0, count: w * h * 4)
    let ctx = CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    var minY = h, maxY = 0, minX = w, maxX = 0
    for y in 0..<h { for x in 0..<w where bytes[(y * w + x) * 4 + 3] > 220 {
        minY = min(minY,y); maxY = max(maxY,y); minX = min(minX,x); maxX = max(maxX,x)
    } }
    print(filename, w, h, "bounds", minX, minY, maxX, maxY)
    for y in [minY + 3, Int(Double(h) * 0.90), Int(Double(h) * 0.92), Int(Double(h) * 0.94)] {
        let xs = (0..<w).filter { bytes[(y * w + $0) * 4 + 3] > 220 }
        print("row",y,"x",xs.first ?? -1, xs.last ?? -1)
    }
}
