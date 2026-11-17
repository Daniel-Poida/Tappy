import Foundation
import AVFoundation
import Cocoa

// Standalone checks run with the macOS Command Line Tools, without requiring Xcode/XCTest.
@main struct TappyChecks {
    static func main() throws {
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError("FAIL: \(message)") }; checks += 1
        }
        var dynamics = ClickDynamics()
        expect(dynamics.record(at: 0) == 0, "First click is gentle")
        let second = dynamics.record(at: 0.1), third = dynamics.record(at: 0.2)
        expect(second > 0.4, "Quick second click builds energy")
        expect(third > second, "Repeated clicks increase energy")
        expect(dynamics.record(at: 2) == 0, "Pause resets click intensity")
        _ = dynamics.record(at: 2.08); _ = dynamics.record(at: 2.16)
        dynamics.decay(at: 6)
        expect(dynamics.energy == 0, "Energy decays while idle")
        for i in 0..<1000 { expect((0...1).contains(dynamics.record(at: 10 + Double(i) * 0.005)), "Energy remains bounded") }
        var slow = ClickDynamics(), fast = ClickDynamics()
        for i in 0..<4 { _ = slow.record(at: Double(i) * 0.45); _ = fast.record(at: Double(i) * 0.1) }
        expect(fast.energy > slow.energy, "Faster clicking is more expressive")
        let quiet = SoundManager.gain(energy: 0, volume: 0.6, mood: 1)
        let loud = SoundManager.gain(energy: 1, volume: 0.6, mood: 1)
        expect(loud > quiet * 2 && loud <= 0.6, "Energy increases loudness within master volume")
        expect(SoundManager.gain(energy: 1, volume: 0, mood: 1) == 0, "Master mute works")
        expect(SoundManager.gain(energy: 0, volume: 0.6, mood: 1) == quiet, "Quiet clicks return to baseline")
        expect(PointerStyle.allCases.count == 4, "Exactly four characters")
        expect(Set(PointerStyle.allCases.map { $0.sound.rawValue }).count == 4, "Every hand has its own sound")
        expect(PointerStyle(rawValue: "Cat paw") == nil && PointerStyle(rawValue: "Middle child") == nil, "Old characters removed")
        var sounds = Set<Data>()
        for style in TapSound.allCases {
            let data = SoundSynthesis.wav(style: style)
            expect(String(data: data.prefix(4), encoding: .ascii) == "RIFF", "Valid WAV header")
            let player = try AVAudioPlayer(data: data)
            expect(abs(player.duration - 0.22) < 0.001 && player.numberOfChannels == 1, "PCM decodes correctly")
            var peak = 0
            for offset in stride(from: 44, to: data.count - 1, by: 2) {
                let sample = Int16(bitPattern: UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8))
                peak = max(peak, abs(Int(sample)))
            }
            expect(peak > 5000 && peak < Int(Int16.max), "Sound is audible and not clipped")
            sounds.insert(data)
        }
        expect(sounds.count == 4, "Sound waveforms are distinct")
        let left = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        expect(CursorOverlayWindow.localPosition(CGPoint(x: -1000, y: 700), frame: left) == CGPoint(x: 920, y: 380), "Display left of main screen")
        let above = CGRect(x: 0, y: 1080, width: 2560, height: 1440)
        expect(CursorOverlayWindow.localPosition(CGPoint(x: 200, y: 2400), frame: above) == CGPoint(x: 200, y: 120), "Display above main screen")
        for style in PointerStyle.allCases {
            expect(CGRect(x: 0, y: 0, width: 100, height: 140).contains(PointerGeometry.outline(style).boundingRect), "Artwork stays within canvas")
            expect(CGRect(x: 0, y: 0, width: 100, height: 140).contains(PointerGeometry.tip(style)), "Hotspot stays within canvas")
            expect(PointerImages.images[style] != nil, "Production artwork loads for every character")
            for size in [0.65, 1.0, 1.6] {
                for impact in [0.0, 0.5, 1.0] {
                    for tapping in [false, true] {
                        let pose = PointerPose(style: style, size: size, tapping: tapping, impact: impact)
                        expect(pose.offset(of: PointerGeometry.tip(style)) == .zero, "Animation keeps the click hotspot fixed")
                    }
                }
            }
        }
        for lower in [0.0, 0.2, 0.6, 1.0] {
            expect(ForearmGeometry.opacity(at: 0, lowerOpacity: lower) == 1, "Wrist stays opaque")
            expect(ForearmGeometry.opacity(at: 1, lowerOpacity: lower) == 0, "Forearm has a fully transparent end")
            expect(abs(ForearmGeometry.opacity(at: 0.4, lowerOpacity: lower) - lower) < 0.001, "Slider controls lower forearm opacity")
            var previous = 1.0
            for i in 0...100 {
                let alpha = ForearmGeometry.opacity(at: Double(i) / 100, lowerOpacity: lower)
                expect(alpha <= previous + 0.000001 && (0...1).contains(alpha), "Forearm fades smoothly without becoming opaque again")
                previous = alpha
            }
        }
        for style in PointerStyle.allCases {
            for lean in [-28.0, 0.0, 24.0] {
                for size in [0.65, 1.0, 1.6] {
                    let pose = PointerPose(style: style, size: size, tapping: true, impact: 1, lean: lean)
                    for phase in [0.0, 0.25, 0.5, 0.75, 1.0] {
                        let geometry = ForearmGeometry(position: CGPoint(x: 100, y: 20), pose: pose, progress: phase)
                        expect(abs(hypot(geometry.end.x - geometry.start.x, geometry.end.y - geometry.start.y) - 190 * size) < 0.001, "Forearm length stays finite at every angle and click phase")
                        let wrist = PointerGeometry.wrist(style)
                        let offset = pose.offset(of: CGPoint(x: wrist.x, y: wrist.y - 3), progress: phase)
                        expect(hypot(geometry.start.x - 100 - offset.x, geometry.start.y - 20 - offset.y) < 0.001, "Wrist and forearm share exactly the same animated transform")
                        expect(pose.offset(of: PointerGeometry.tip(style), progress: phase) == .zero, "Continuous animation keeps click hotspot fixed")
                    }
                }
            }
        }
        var orientation = PointerOrientation()
        for height in [720.0, 1080.0, 2160.0] {
            for size in [0.65, 1.0, 1.6] {
                for lean in [-28.0, 0.0, 24.0] {
                    let short = ForearmGeometry.resolvedLength(extensionFraction: 0, canvasHeight: height, wristY: 150, size: size, lean: lean)
                    let full = ForearmGeometry.resolvedLength(extensionFraction: 1, canvasHeight: height, wristY: 150, size: size, lean: lean)
                    let middle = ForearmGeometry.resolvedLength(extensionFraction: 0.5, canvasHeight: height, wristY: 150, size: size, lean: lean)
                    expect(short == 190, "Minimum length matches the existing short forearm")
                    expect(full >= short && abs(middle - (short + full) / 2) < 0.001, "Length slider interpolates continuously")
                    expect(150 + full * size * Darwin.cos(lean * 0.65 * .pi / 180) >= height + 69.99, "Maximum length reaches the bottom as in 1.1")
                }
            }
        }
        for i in 0..<120 { _ = orientation.update(point: CGPoint(x: 20, y: 30), canvas: CGSize(width: 1920, height: 1080), at: Double(i) / 90) }
        let leftLean = orientation.angle
        var previousAngle = leftLean
        for i in 120..<240 {
            let angle = orientation.update(point: CGPoint(x: 1900, y: 30), canvas: CGSize(width: 1920, height: 1080), at: Double(i) / 90)
            expect(abs(angle - previousAngle) < 8 && abs(angle) <= 34, "Motion lean stays damped and bounded")
            previousAngle = angle
        }
        expect(leftLean < -20 && orientation.angle > 15, "Pointer orientation changes across the screen")
        var shieldTaps = 0
        let shield = PresentationShieldView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)) { shieldTaps += 1 }
        expect(shield.hitTest(CGPoint(x: 20, y: 20)) === shield && shield.hitTest(CGPoint(x: 200, y: 200)) == nil, "Presentation shield captures its screen area")
        expect(shield.acceptsFirstMouse(for: nil) && !shield.acceptsFirstResponder, "Presentation accepts clicks without taking keyboard focus")
        for type: NSEvent.EventType in [.leftMouseDown, .rightMouseDown, .otherMouseDown] {
            let event = NSEvent.mouseEvent(with: type, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
            switch type { case .leftMouseDown: shield.mouseDown(with: event); case .rightMouseDown: shield.rightMouseDown(with: event); default: shield.otherMouseDown(with: event) }
        }
        expect(shieldTaps == 3, "Every mouse button produces a presentation tap")
        let diskVersion = try String(contentsOfFile: "VERSION", encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        expect(diskVersion == AppVersion.short, "Source and installer versions agree")
        var idle = IdleAnimationClock()
        expect(idle.update(idleFor: 9, delay: 10, enabled: true, at: 100) == nil, "Idle animation waits for the configured delay")
        expect(idle.update(idleFor: 10, delay: 10, enabled: true, at: 101) == 0, "Idle animation starts at the threshold")
        expect(idle.update(idleFor: 12, delay: 10, enabled: true, at: 103) == 2, "Idle animation progresses with monotonic time")
        expect(idle.update(idleFor: 0, delay: 10, enabled: true, at: 104) == nil, "Any input cancels idle immediately")
        expect(idle.update(idleFor: 10, delay: 10, enabled: false, at: 114) == nil, "Idle animation can be disabled")
        expect(idle.update(idleFor: 20, delay: 10, enabled: true, at: 124) == 0, "Idle restarts from the first frame after interruption")
        for name in IdleImages.names { expect(IdleImages.images[name] != nil, "All idle animation layers are bundled") }
        for i in 0..<450 {
            let pose = IdlePose(time: Double(i) / 100)
            expect(abs(pose.fidgetWeights.reduce(0, +) - 1) < 0.000001, "Finger pose crossfades preserve opacity")
            expect(pose.fidgetWeights.allSatisfy { (0...1).contains($0) }, "Finger pose weights remain valid")
            expect(pose.lift >= 0 && pose.lift <= 33 && pose.rotation >= 0 && pose.rotation <= 360, "Wand toss remains bounded")
        }
        expect(IdlePose(time: 0.35).lift < 0.001 && IdlePose(time: 1.05).lift < 0.001, "Wand returns to the glove at the catch")
        expect(abs(IdlePose(time: 0.7).lift - 33) < 0.001, "Wand reaches the peak halfway through the quick toss")
        expect(IdlePose(time: 1.04).handMix == 1 && IdlePose(time: 1.05).handMix == 0 && IdlePose(time: 1.1).handMix == 0,
               "Catch switches to one coherent closed grip without overlapping palms")
        print("PASS: \(checks) assertions — click dynamics, audio, characters, geometry and multi-display coordinates")
    }
}
