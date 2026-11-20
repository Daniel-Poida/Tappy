import Cocoa
import Darwin

// Read-only diagnostic for the image read by WebRTC's macOS cursor monitor.
// Run from the repository root: swift Tools/InspectCaptureCursor.swift
_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)
guard let cursor = NSCursor.currentSystem,
      let image = cursor.image.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let context = CGContext(data: nil, width: image.width, height: image.height,
          bitsPerComponent: 8, bytesPerRow: image.width * 4,
          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    print("Current cursor image is unavailable; this does not establish capture visibility.")
    exit(1)
}
context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
let opaque = (0..<(image.width * image.height)).filter { pixels[$0 * 4 + 3] > 0 }.count
print("Current system cursor: \(image.width)×\(image.height), \(opaque) nontransparent pixels")
