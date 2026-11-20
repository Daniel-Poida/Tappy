import Foundation
import AVFoundation
import Cocoa
import SwiftUI

// Standalone checks run with the macOS Command Line Tools, without requiring Xcode/XCTest.
@main struct TappyChecks {
    @MainActor static func main() throws {
        if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--guard-client-exit" {
            let guardClient = SystemArrowGuard(helper: URL(fileURLWithPath: CommandLine.arguments[2]))
            guard guardClient.start() else { exit(1) }
            // Exit without Swift cleanup: exercise kernel pipe-EOF recovery.
            withExtendedLifetime(guardClient) { exit(0) }
        }
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
        expect(PointerStyle.allCases.count == 8, "Exactly eight characters")
        expect(Set(PointerStyle.allCases.map { $0.sound.rawValue }).count == 8, "Every hand has its own sound")
        expect(PointerStyle(rawValue: "Cat paw") == nil && PointerStyle(rawValue: "Middle child") == nil, "Old characters removed")
        expect(PointerStyle.rows == [[.classic, .moonWand, .starWand, .wizardWand], [.witch, .finnSword, .redLightsaber, .greenLightsaber]],
               "New characters occupy the second row in the requested order")
        expect(PointerStyle.rows.flatMap { $0 } == PointerStyle.allCases, "Every character appears once in the picker")
        for style in PointerStyle.allCases { expect(PointerStyle(rawValue: style.rawValue) == style, "Character selection can be restored from saved settings") }
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
        expect(sounds.count == 8, "Sound waveforms are distinct")
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
                        expect(hypot(pose.offset(of: PointerGeometry.tip(style)).x, pose.offset(of: PointerGeometry.tip(style)).y) < 1e-9, "Animation keeps the click hotspot fixed")
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
                        let offset = pose.offset(of: wrist, progress: phase)
                        expect(hypot(geometry.start.x - 100 - offset.x, geometry.start.y - 20 - offset.y) < 0.001, "Wrist and forearm share exactly the same animated transform")
                        expect(hypot(pose.offset(of: PointerGeometry.tip(style), progress: phase).x, pose.offset(of: PointerGeometry.tip(style), progress: phase).y) < 1e-9, "Continuous animation keeps click hotspot fixed")
                    }
                }
            }
        }
        // Render the actual production Canvas at intermediate and spring rebound
        // phases: a geometric endpoint check alone missed the old split animation.
        _ = NSApplication.shared
        for style in PointerStyle.allCases {
            let artwork = ImageRenderer(content: PointerArtwork(style: style, shadow: false).frame(width: 200, height: 280))
            let glove = NSBitmapImageRep(cgImage: artwork.cgImage!)
            for y in Int(ceil(PointerGeometry.wristRim(style) * 2)) + 1..<280 {
                expect(glove.colorAt(x: Int(PointerGeometry.wrist(style).x * 2), y: y)!.alphaComponent < 0.01,
                       "Baked straight wrist is clipped from the rendered glove")
            }
            for lean in [-34.0, 0, 34] {
                for phase in [-0.15, 0, 0.25, 0.5, 0.75, 1.0, 1.1] {
                    let position = CGPoint(x: 330, y: 25)
                    let figure = ImageRenderer(content: PointerFigure(position: position, style: style, size: 2,
                        impact: 1, shadow: false, lean: lean, lowerOpacity: 1, phase: phase).frame(width: 650, height: 600))
                    let bitmap = NSBitmapImageRep(cgImage: figure.cgImage!)
                    let pose = PointerPose(style: style, size: 2, impact: 1, lean: lean)
                    let transform = pose.transform(position: position, progress: phase)
                    for localY in stride(from: PointerGeometry.wristRim(style) - 1, through: PointerGeometry.cuffBottom(style) + 8, by: 0.5) {
                        let point = CGPoint(x: PointerGeometry.wrist(style).x, y: localY).applying(transform)
                        expect(bitmap.colorAt(x: Int(point.x.rounded()), y: Int(point.y.rounded()))!.alphaComponent > 0.95,
                               "No transparent gap across cuff during tap or spring rebound: \(style), \(phase), \(lean), \(localY)")
                    }
                }
            }
        }
        for style in PointerStyle.allCases {
            expect(PointerImages.bitmaps[style] != nil, "Every glove has a predecoded bitmap")
            // Consecutive fast-click frames, with changing energy and direction.
            // Check both the bitmap palm and its connected wrist on every frame.
            for frame in 0..<36 {
                let phase = sin(Double(frame) * 0.8) * 0.65 + 0.45
                let lean = sin(Double(frame) * 0.3) * 34
                let impact = Double(frame % 9) / 8
                let position = CGPoint(x: 270, y: 25)
                let renderer = ImageRenderer(content: PointerFigure(position: position, style: style, size: 1.6,
                    impact: impact, shadow: false, lean: lean, lowerOpacity: 1, phase: phase).frame(width: 550, height: 500))
                let bitmap = NSBitmapImageRep(cgImage: renderer.cgImage!)
                let transform = PointerPose(style: style, size: 1.6, impact: impact, lean: lean).transform(position: position, progress: phase)
                for local in [CGPoint(x: 50, y: 100), CGPoint(x: PointerGeometry.wrist(style).x, y: PointerGeometry.wristRim(style) + 1)] {
                    let point = local.applying(transform)
                    expect(bitmap.colorAt(x: Int(point.x.rounded()), y: Int(point.y.rounded()))!.alphaComponent > 0.95,
                           "Bitmap glove and forearm are present together in rapid-click frames")
                }
            }
        }
        // Reuse the very same backing memory while moving, shrinking, changing
        // characters and interrupting taps. Every frame must equal a fresh draw.
        func frameContext() -> CGContext {
            CGContext(data: nil, width: 460, height: 520, bitsPerComponent: 8, bytesPerRow: 460 * 4,
                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        }
        func pixels(_ context: CGContext) -> Data {
            Data(bytes: context.data!, count: context.bytesPerRow * context.height)
        }
        let reused = frameContext()
        for step in 0..<36 {
            let style = PointerStyle.allCases[step % PointerStyle.allCases.count]
            let frame = CursorOverlayFrame(figure: PointerFigure(position: CGPoint(x: 160 + step % 3 * 30, y: 20),
                style: style, size: step % 2 == 0 ? 1.6 : 0.65, impact: 1,
                shadow: step % 3 != 0, lean: step % 2 == 0 ? -28 : 30,
                lowerOpacity: Double(step % 5) / 4, extensionFraction: step % 2 == 0 ? 1 : 0,
                idleTime: step % 5 == 0 ? 0.7 : nil, phase: Double(step % 6) / 5), burstOpacity: step % 2 == 0 ? 1 : 0)
            CursorOverlayFrame.draw(frame, in: reused, canvas: CGSize(width: 460, height: 520))
            let fresh = frameContext()
            CursorOverlayFrame.draw(frame, in: fresh, canvas: CGSize(width: 460, height: 520))
            expect(pixels(reused) == pixels(fresh), "Changing settings never retains the previous cursor frame")
        }
        CursorOverlayFrame.draw(nil, in: reused, canvas: CGSize(width: 460, height: 520))
        expect(pixels(reused).allSatisfy { $0 == 0 }, "Disabling clears every previous pointer pixel")
        // Deliver movement between animation ticks: the rendered frame must
        // follow the newest subpixel position without advancing the artwork.
        var movingFrame = CursorOverlayFrame(figure: PointerFigure(position: CGPoint(x: 150, y: 30),
            style: .starWand, size: 1.2, impact: 0.7, shadow: true, lean: 17,
            lowerOpacity: 0.4, extensionFraction: 1, phase: 0.65), burstOpacity: 0.8)
        for position in [CGPoint(x: 160.125, y: 20.75), CGPoint(x: 300.5, y: 40.25),
                         CGPoint(x: 80.25, y: 125.5), CGPoint(x: 260.75, y: 15.125)] {
            movingFrame.move(to: position, idleTime: nil)
            expect(movingFrame.figure.position == position && movingFrame.figure.availableTopRoom == position.y,
                   "Mouse delivery updates exact position and top clearance without an animation tick")
            expect(movingFrame.figure.phase == 0.65 && movingFrame.figure.lean == 17 && movingFrame.burstOpacity == 0.8,
                   "Mouse delivery leaves the current animation phase and angle unchanged")
            CursorOverlayFrame.draw(movingFrame, in: reused, canvas: CGSize(width: 460, height: 520))
            let expected = CursorOverlayFrame(figure: PointerFigure(position: position, style: .starWand,
                size: 1.2, impact: 0.7, shadow: true, lean: 17, lowerOpacity: 0.4, extensionFraction: 1,
                availableTopRoom: position.y, phase: 0.65), burstOpacity: 0.8)
            let fresh = frameContext()
            CursorOverlayFrame.draw(expected, in: fresh, canvas: CGSize(width: 460, height: 520))
            expect(pixels(reused) == pixels(fresh), "Movement draws one joined pointer at the latest position, without retaining its previous pixels")
        }
        movingFrame.figure.idleTime = 0.5
        movingFrame.move(to: CGPoint(x: 200, y: 30), idleTime: nil)
        expect(movingFrame.figure.idleTime == nil, "Movement cancels the displayed idle pose immediately")
        let fineMotionState = CursorState()
        fineMotionState.previewIdle()
        fineMotionState.move(to: CGPoint(x: 0.02, y: 0.02))
        expect(fineMotionState.idleTime == nil, "Fine high-rate mouse increments cancel idle without waiting for a larger polled delta")
        for sample in 0..<1000 {
            movingFrame.move(to: CGPoint(x: Double(sample) / 4, y: 20.5), idleTime: nil)
        }
        expect(movingFrame.figure.position == CGPoint(x: 249.75, y: 20.5) && movingFrame.figure.phase == 0.65,
               "High-rate movement retains only the latest position, independently of animation timing")
        var motion = CursorTapMotion()
        expect(motion.phase(at: 0) == 0 && motion.burstOpacity(at: 0) == 0, "Native cursor starts at rest")
        motion.record(at: 1)
        expect(motion.phase(at: 1) == 0 && abs(motion.phase(at: 1.05) - 1) < 0.001, "Tap compresses once from its current pose")
        let interrupted = motion.phase(at: 1.1)
        motion.record(at: 1.1)
        expect(abs(motion.phase(at: 1.1) - interrupted) < 0.001, "Rapid click interruption preserves the current wrist phase")
        expect(motion.phase(at: 3) == 0 && motion.burstOpacity(at: 3) == 0, "Motion settles and impact disappears")
        motion.reset()
        expect(motion.phase(at: 1) == 0, "Disabling cancels the native click animation")
        let lockPath = FileManager.default.temporaryDirectory.appendingPathComponent("Tappy-instance-test-\(UUID().uuidString).lock")
        let firstInstance = SingleInstance(path: lockPath.path), secondInstance = SingleInstance(path: lockPath.path)
        expect(firstInstance.acquire() && firstInstance.acquire(), "First instance owns a stable lock")
        expect(!secondInstance.acquire(), "Second process cannot own the cursor at the same time")
        firstInstance.release()
        expect(secondInstance.acquire(), "Lock is available after the original process exits")
        secondInstance.release()
        try FileManager.default.removeItem(at: lockPath)
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
        var shieldButtons: [PointerButton] = []
        var shieldReleases: [PointerButton] = []
        let shield = PresentationShieldView(frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            onRelease: { shieldReleases.append($0) }) { button in shieldTaps += 1; shieldButtons.append(button) }
        expect(shield.hitTest(CGPoint(x: 20, y: 20)) === shield && shield.hitTest(CGPoint(x: 200, y: 200)) == nil, "Presentation shield captures its screen area")
        expect(shield.acceptsFirstMouse(for: nil) && !shield.acceptsFirstResponder, "Presentation accepts clicks without taking keyboard focus")
        expect(shield.trackingAreas.contains { $0.options.contains([.mouseMoved, .activeAlways, .inVisibleRect]) },
               "The non-activating presentation surface receives hover movement for event-driven following")
        for type: NSEvent.EventType in [.leftMouseDown, .rightMouseDown, .otherMouseDown] {
            let event = NSEvent.mouseEvent(with: type, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
            switch type { case .leftMouseDown: shield.mouseDown(with: event); case .rightMouseDown: shield.rightMouseDown(with: event); default: shield.otherMouseDown(with: event) }
        }
        expect(shieldTaps == 3, "Every mouse button produces a presentation tap")
        expect(shieldButtons == [.primary, .secondary, .other], "Presentation mode preserves right-button identity")
        let rightRelease = NSEvent.mouseEvent(with: .rightMouseUp, location: .zero, modifierFlags: [], timestamp: 0,
            windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 0)!
        shield.rightMouseUp(with: rightRelease)
        expect(shieldReleases == [.secondary], "Presentation mode releases the secondary finger gesture")
        let diskVersion = try String(contentsOfFile: "VERSION", encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        expect(diskVersion == AppVersion.short, "Source and installer versions agree")
        for style in PointerStyle.allCases {
            let duration = IdlePose.duration(for: style)
            for interval in [3.0, 10.0, 30.0, 60.0] {
                func phase(_ idleFor: Double, enabled: Bool = true) -> Double? {
                    IdleAnimationSchedule.phase(idleFor: idleFor, interval: interval, duration: duration, enabled: enabled)
                }
                expect(phase(interval - 0.01) == nil, "First animation waits for the full configured interval")
                for repetition in 1...5 {
                    let boundary = interval * Double(repetition)
                    expect(phase(boundary) == 0, "One animation starts at every idle interval boundary")
                    expect(abs((phase(boundary + 0.5) ?? -1) - 0.5) < 0.000001, "Single animation progresses normally")
                    expect(phase(boundary + duration + 0.01) == nil, "Pointer stays still after one animation")
                    expect(phase(boundary + interval - 0.01) == nil, "No repeat before the next configured boundary")
                }
                expect(phase(0) == nil, "Input resets the interval countdown")
                expect(phase(interval, enabled: false) == nil, "Idle animation can be disabled")
            }
        }
        for name in IdleImages.names { expect(IdleImages.images[name] != nil, "All idle animation layers are bundled") }
        let fingerSequence: [(Double, FingerPose)] = [(0.1, .index), (0.45, .two), (0.9, .three),
            (1.3, .fist), (1.8, .middle), (2.2, .fist), (2.65, .index)]
        let fingerRate = FingerAnimationTiming.playbackRate
        expect(IdlePose.duration(for: .classic) < 2 && IdlePose.duration(for: .witch) < 2, "The complete finger sequence finishes in under two seconds")
        for (time, finger) in fingerSequence {
            let weights = IdlePose(time: time / fingerRate).fidgetWeights
            expect(weights[finger.rawValue] == 1 && weights.filter { $0 > 0 }.count == 1,
                   "Idle finger order is index, two, three, fist, middle, fist, index")
        }
        let clickDefaultsName = "Tappy-finger-tests-\(UUID().uuidString)"
        let clickDefaults = UserDefaults(suiteName: clickDefaultsName)!
        defer { clickDefaults.removePersistentDomain(forName: clickDefaultsName) }
        let clickSettings = TappySettings(defaults: clickDefaults)
        let clickState = CursorState()
        _ = clickState.tap(settings: clickSettings, button: .secondary, at: 10)
        clickState.tick(at: 10 + 0.085 / fingerRate, systemIdle: 0, settings: clickSettings, secondaryDown: true)
        expect(clickState.fingerPose == .fist && clickState.idleTime == nil, "Right-click first closes the index hand into a fist")
        clickState.tick(at: 10 + 0.34 / fingerRate, systemIdle: 0, settings: clickSettings, secondaryDown: true)
        expect(clickState.fingerPose == .middle, "The middle finger emerges from the fist on right-click")
        clickState.tick(at: 15, systemIdle: 0, settings: clickSettings, secondaryDown: true)
        expect(clickState.fingerPose == .middle, "Middle finger stays selected while the right button is held")
        clickState.release(button: .secondary, at: 15)
        clickState.tick(at: 15 + 0.1 / fingerRate, systemIdle: 0, settings: clickSettings)
        expect(clickState.fingerPose == .fist, "The middle finger closes into a fist on release")
        clickState.tick(at: 15 + 0.4 / fingerRate, systemIdle: 0, settings: clickSettings)
        expect(clickState.fingerPose == nil, "Right-button release restores the index gesture")
        _ = clickState.tap(settings: clickSettings, button: .secondary, at: 20)
        _ = clickState.tap(settings: clickSettings, button: .primary, at: 20 + 0.05 / fingerRate)
        clickState.tick(at: 20 + 0.55 / fingerRate, systemIdle: 0, settings: clickSettings)
        expect(clickState.fingerPose == .fist, "A primary click returns from the secondary gesture through a fist")
        clickState.tick(at: 20 + 0.8 / fingerRate, systemIdle: 0, settings: clickSettings)
        expect(clickState.fingerPose == nil, "The interrupted secondary gesture finishes at the index hand")
        clickSettings.animateOnClick = false
        _ = clickState.tap(settings: clickSettings, button: .secondary, at: 30)
        expect(clickState.fingerPose == .middle, "Right-button identity remains visible with click motion disabled")
        clickState.tick(at: 30.1, systemIdle: 0, settings: clickSettings, reduceMotion: true, secondaryDown: false)
        clickState.tick(at: 30.3, systemIdle: 0, settings: clickSettings, reduceMotion: true)
        expect(clickState.fingerPose == nil, "Hardware button state recovers a lost right-button release event")
        var quickSecondary = SecondaryFingerGesture()
        quickSecondary.press(at: 0); quickSecondary.release(at: 0.02)
        for (time, finger) in [(0.15, FingerPose.fist), (0.35, .middle), (0.55, .fist)] {
            expect(quickSecondary.weights(at: time / fingerRate) == finger.weights,
                   "A quick right-click visits fist, middle, fist in order")
        }
        expect(quickSecondary.weights(at: 0.73 / fingerRate) == nil, "Quick right-click returns to the index hand without looping")
        for startOffset in [0.0, 0.003, 0.008, 0.015] {
            var gesture = SecondaryFingerGesture()
            gesture.press(at: startOffset); gesture.release(at: startOffset + 0.02)
            var firstFistFrames = 0, returnFistFrames = 0
            for frame in 0..<36 {
                let time = Double(frame) / 60
                if let weights = gesture.weights(at: time), FingerCelArtwork.index(for: weights) == 9 {
                    if time < startOffset + 0.4 / fingerRate { firstFistFrames += 1 }
                    else { returnFistFrames += 1 }
                }
            }
            expect(firstFistFrames >= 3 && returnFistFrames >= 3,
                   "Faster right-clicks retain at least three visible fist frames in each direction at 60 Hz")
        }
        var repeatedSecondary = SecondaryFingerGesture()
        repeatedSecondary.press(at: 0); repeatedSecondary.release(at: 0.22 / fingerRate)
        let beforeRepeat = repeatedSecondary.weights(at: 0.29 / fingerRate)
        repeatedSecondary.press(at: 0.29 / fingerRate)
        expect(repeatedSecondary.weights(at: 0.29 / fingerRate) == beforeRepeat, "A repeated right-click preserves the current drawn pose")
        func fingerBitmap(_ style: PointerStyle, _ weights: [Double]) -> NSBitmapImageRep {
            let context=CGContext(data:nil,width:420,height:420,bitsPerComponent:8,bytesPerRow:1680,
                space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.translateBy(x:0,y:420);context.scaleBy(x:3,y:-3);context.translateBy(x:20,y:0)
            FingerCelArtwork.draw(style:style,weights:weights,in:context)
            return NSBitmapImageRep(cgImage:context.makeImage()!)
        }
        for style in [PointerStyle.classic, .witch] {
            let frames = FingerCelArtwork.frames[style] ?? []
            expect(frames.count == 16, "Each finger hand has sixteen complete painted cels")
            for cel in frames {
                expect(abs(cel.rect.width / CGFloat(cel.image.width) - cel.rect.height / CGFloat(cel.image.height)) < 0.000001,
                       "Registration preserves the whole cel's proportions")
                expect(abs(cel.cuffWidth - frames[0].cuffWidth) < 0.000001 && cel.wrist == frames[0].wrist,
                       "Every cel has the same registered cuff width and wrist anchor")
            }
            var distinctFrames = Set<Data>()
            for sample in FingerCelArtwork.samples.prefix(15) {
                let image = fingerBitmap(style, sample)
                distinctFrames.insert(Data(bytes: image.bitmapData!, count: image.bytesPerRow * image.pixelsHigh))
                for point in [CGPoint(x: 50, y: 90), CGPoint(x: 50, y: 104), CGPoint(x: 50, y: 111)] {
                    expect(image.colorAt(x: Int((point.x + 20) * 3), y: Int(point.y * 3))!.alphaComponent > 0.98,
                           "Complete painted cels retain an opaque palm and cuff")
                }
            }
            expect(distinctFrames.count == 15, "Every intermediate cel has its own painted shape")
            for amount in stride(from: 0.0, through: 1.0, by: 0.05) {
                let sample = zip(FingerPose.index.weights, FingerPose.fist.weights).map { $0 * (1 - amount) + $1 * amount }
                expect([0, 14, 13, 9].contains(FingerCelArtwork.index(for: sample)),
                       "Index folding selects only whole index-to-fist cels")
            }
        }
        for (pose, index) in [(FingerPose.index, 0), (.two, 3), (.three, 6), (.fist, 9), (.middle, 12)] {
            expect(FingerCelArtwork.index(for: pose.weights) == index, "Held gestures select the intended whole cel")
        }
        for time in [0.1, 0.15, 0.19] {
            expect(FingerCelArtwork.index(for: quickSecondary.weights(at: time / fingerRate)!) == 9,
                   "The actual painted fist remains visible throughout the first right-click pause")
            expect(FingerCelArtwork.index(for: quickSecondary.weights(at: (time + 0.4) / fingerRate)!) == 9,
                   "The actual painted fist remains visible throughout the return pause")
        }
        for style: PointerStyle in [.classic, .witch] {
            for time in fingerSequence.map(\.0) + [0.26, 0.70, 1.14, 1.54, 2.04, 2.43] {
                let position = CGPoint(x: 280, y: 25)
                let figure = PointerFigure(position: position, style: style, size: 2, shadow: false, lean: 0,
                                           lowerOpacity: 1, idleTime: time / fingerRate)
                let renderer = ImageRenderer(content: figure.frame(width: 600, height: 500))
                let bitmap = NSBitmapImageRep(cgImage: renderer.cgImage!)
                let transform = PointerPose(style: style, size: 2, lean: 0).transform(position: position, progress: 0)
                for y in [100, PointerGeometry.wristRim(style) - 1, PointerGeometry.wristRim(style) + 1] {
                    let point = CGPoint(x: PointerGeometry.wrist(style).x, y: y).applying(transform)
                    expect(bitmap.colorAt(x: Int(point.x.rounded()), y: Int(point.y.rounded()))!.alphaComponent > 0.98,
                           "Finger changes keep the palm, cuff and arm opaque and connected")
                }
            }
            for phase in [0.0, 0.5, 1.0, -0.15] {
                let tip = PointerGeometry.middleTip(style)
                let pose = PointerPose(style: style, size: 1.6, impact: 1, lean: 24, hotspot: tip)
                let fixedTip = tip.applying(pose.transform(position: CGPoint(x: 200, y: 30), progress: phase))
                expect(hypot(fixedTip.x - 200, fixedTip.y - 30) < 0.00001, "Right-click stays anchored to the second fingertip")
            }
        }
        for i in 0..<450 {
            let pose = IdlePose(time: Double(i) / 100)
            expect(abs(pose.fidgetWeights.reduce(0, +) - 1) < 0.000001, "Finger timing weights stay normalized")
            expect(pose.fidgetWeights.allSatisfy { (0...1).contains($0) }, "Finger pose weights remain valid")
            expect(pose.lift >= 0 && pose.lift <= 33 && pose.rotation >= 0 && pose.rotation <= 360, "Wand toss remains bounded")
        }
        expect(IdlePose(time: 0.35).lift < 0.001 && IdlePose(time: 1.05).lift < 0.001, "Wand returns to the glove at the catch")
        expect(abs(IdlePose(time: 0.7).lift - 33) < 0.001, "Wand reaches the peak halfway through the quick toss")
        expect(IdlePose(time: 1.04).handMix == 1 && IdlePose(time: 1.05).handMix == 0 && IdlePose(time: 1.1).handMix == 0,
               "Catch switches to one coherent closed grip without overlapping palms")
        for time in [2.2, 4.4, 60.7, 120.7] {
            let pose = IdlePose(time: time)
            expect(!pose.isFlying && pose.handMix == 0 && pose.rotation == 0, "Wand poses do not loop by themselves")
        }
        expect(IdlePose(time: 60.8).fidgetWeights == [1, 0, 0, 0, 0], "Finger poses do not loop by themselves")
        let cursorBackend = FakeCursorBackend()
        let systemCursor = SystemCursorController(backend: cursorBackend)
        systemCursor.setHidden(true)
        expect(cursorBackend.backgroundEnabled && !cursorBackend.visible && cursorBackend.depth == 1, "Background cursor control hides the system pointer")
        expect(cursorBackend.arrowTransparent, "System arrow image is protected before hiding the cursor")
        expect(cursorBackend.captureCursorTransparent, "Capture receives a transparent current image even with the Quartz cursor hidden")
        cursorBackend.captureCursorTransparent = false // Another app publishes a normal cursor image.
        systemCursor.refresh(cursorMoved: true, at: ProcessInfo.processInfo.systemUptime + 1)
        expect(cursorBackend.captureCursorTransparent && cursorBackend.depth == 1,
               "Mouse movement repairs the capture image without accumulating hide calls")
        let captureRefreshStart = ProcessInfo.processInfo.systemUptime + 3
        let previousCapturePublishes = cursorBackend.capturePublishes
        for frame in 0..<120 { systemCursor.refresh(at: captureRefreshStart + Double(frame) / 120) }
        expect((4...6).contains(cursorBackend.capturePublishes - previousCapturePublishes),
               "A stationary capture cursor is refreshed at most five times per second")
        cursorBackend.captureCursorTransparent = false
        systemCursor.refresh(at: captureRefreshStart + 1.3)
        expect(cursorBackend.captureCursorTransparent, "Heartbeat repairs a changed cursor image when the mouse is stationary")
        cursorBackend.reportHidden = true
        let initialShows = cursorBackend.showCalls
        for i in 0..<120 {
            cursorBackend.dockForceShow()
            systemCursor.refresh(force: true, cursorMoved: true, at: ProcessInfo.processInfo.systemUptime + Double(i) / 90)
            expect(cursorBackend.arrowTransparent && cursorBackend.depth == 1, "A forced Dock show cannot expose the original arrow image")
        }
        expect(cursorBackend.showCalls == initialShows, "Dock tracking does not repeatedly show a correctly hidden cursor")
        cursorBackend.reportHidden = false
        for i in 0..<100 { systemCursor.refresh(at: ProcessInfo.processInfo.systemUptime + Double(i) / 100) }
        expect(cursorBackend.hideCalls - cursorBackend.showCalls == 1 && cursorBackend.depth == 1, "Tracking keeps exactly one outstanding hide request")
        for _ in 0..<20 {
            cursorBackend.visible = true // Simulate WindowServer restoring it after an app/Space change.
            systemCursor.refresh(force: true)
            expect(!cursorBackend.visible && cursorBackend.depth == 1, "Application transitions re-hide the pointer with one balanced request")
        }
        systemCursor.setHidden(false)
        expect(cursorBackend.visible && cursorBackend.depth == 0 && !cursorBackend.backgroundEnabled, "Disabling Tappy fully restores the system pointer")
        expect(!cursorBackend.arrowTransparent, "Disabling Tappy restores the original arrow image")
        expect(!cursorBackend.captureCursorTransparent, "Disabling Tappy restores the current cursor image for capture")
        systemCursor.setHidden(false)
        expect(cursorBackend.showCalls == cursorBackend.hideCalls, "Repeated disable does not over-show the system cursor")
        cursorBackend.hideSucceeds = false
        systemCursor.setHidden(true)
        expect(!systemCursor.ownsHide && cursorBackend.depth == 0, "Failed hides are not recorded as successful")
        cursorBackend.hideSucceeds = true
        systemCursor.refresh(force: true)
        expect(systemCursor.ownsHide && cursorBackend.depth == 1, "A failed hide is retried")
        cursorBackend.showSucceeds = false
        systemCursor.setHidden(false)
        expect(systemCursor.ownsHide && cursorBackend.backgroundEnabled, "A failed restore remains owned for recovery")
        expect(cursorBackend.captureCursorTransparent, "An unsuccessful hide release retains capture protection until recovery")
        cursorBackend.showSucceeds = true
        systemCursor.refresh(force: true)
        expect(!systemCursor.ownsHide && cursorBackend.depth == 0 && cursorBackend.visible, "Pending restore recovers after a context change")
        let cleanupBackend = FakeCursorBackend()
        do { let controller = SystemCursorController(backend: cleanupBackend); controller.setHidden(true) }
        expect(cleanupBackend.depth == 0 && cleanupBackend.visible, "Controller cleanup restores its cursor request")
        expect(!cleanupBackend.arrowTransparent, "Controller cleanup restores the original arrow image")
        expect(!cleanupBackend.captureCursorTransparent, "Controller cleanup restores the current capture image")
        let transparentCaptureCursor = CaptureCursorImage.make()!
        let captureBitmap = NSBitmapImageRep(cgImage: transparentCaptureCursor.image.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
        expect(captureBitmap.pixelsWide == 16 && captureBitmap.pixelsHigh == 16 && transparentCaptureCursor.hotSpot == .zero,
               "Capture receives a valid nonempty cursor image and hotspot")
        for y in 0..<captureBitmap.pixelsHigh {
            for x in 0..<captureBitmap.pixelsWide {
                expect(captureBitmap.colorAt(x: x, y: y)!.alphaComponent == 0, "Every capture cursor pixel is transparent")
            }
        }
        let staleBackend = FakeCursorBackend()
        staleBackend.arrowControlAvailable = false
        let staleController = SystemCursorController(backend: staleBackend)
        staleController.setHidden(true)
        staleBackend.visibilityAvailable = true
        staleBackend.reportHidden = true
        var time = ProcessInfo.processInfo.systemUptime
        for _ in 0..<120 {
            staleBackend.visible = true // Dock restores a visible arrow, flag stays false.
            time += 0.012
            staleController.refresh(cursorMoved: true, at: time)
            expect(!staleBackend.visible && staleBackend.depth == 1, "Dock hover repairs the cursor even when visibility reports hidden")
        }
        staleBackend.visible = true
        time += 0.21
        staleController.refresh(at: time)
        expect(!staleBackend.visible && staleBackend.depth == 1, "Heartbeat repairs a delayed Dock cursor reset after movement stops")
        staleBackend.visible = true
        staleController.refresh(force: true, at: time)
        expect(!staleBackend.visible && staleBackend.depth == 1, "Forced context refresh ignores a stale hidden flag")
        staleController.setHidden(false)
        expect(staleBackend.visible && staleBackend.depth == 0, "Dock recovery restores the normal cursor completely on disable")
        let unknownBackend = FakeCursorBackend()
        unknownBackend.visibilityAvailable = false
        let unknownController = SystemCursorController(backend: unknownBackend)
        unknownController.setHidden(true)
        unknownController.refresh(force: true)
        expect(unknownBackend.depth == 1, "Unavailable visibility detection refreshes without accumulating hides")
        unknownController.setHidden(false)
        expect(unknownBackend.depth == 0, "Fallback hides remain balanced")
        let fixtureRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: fixtureRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }
        let fixture = fixtureRoot.appendingPathComponent("cursor-guard-fixture")
        try """
        #!/bin/sh
        printf 'started\\n' >> "$0.starts"
        printf '1'
        /bin/cat > /dev/null
        printf 'restored' > "$0.restored"
        printf '2'

        """.write(to: fixture, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: fixture.path)
        let marker = fixture.appendingPathExtension("restored")
        let lease = SystemArrowGuard(helper: fixture)
        expect(lease.start() && lease.isActive, "Arrow guard waits for installation acknowledgement")
        expect(lease.start(), "Repeated activation reuses the same restore owner")
        let starts = try String(contentsOf: fixture.appendingPathExtension("starts"), encoding: .utf8)
        expect(starts == "started\n", "Only one helper starts per activation")
        expect(lease.stop(), "Disable waits for the restoration acknowledgement")
        expect(FileManager.default.fileExists(atPath: marker.path), "Disable closes the lifetime pipe and restores the arrow")
        try FileManager.default.removeItem(at: marker)
        do { let cleanup = SystemArrowGuard(helper: fixture); expect(cleanup.start(), "Cleanup fixture starts") }
        expect(FileManager.default.fileExists(atPath: marker.path), "Client destruction restores the arrow")
        try FileManager.default.removeItem(at: marker)
        let abrupt = Process()
        abrupt.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        abrupt.arguments = ["--guard-client-exit", fixture.path]
        try abrupt.run(); abrupt.waitUntilExit()
        let deadline = Date().addingTimeInterval(2)
        while !FileManager.default.fileExists(atPath: marker.path), Date() < deadline { Thread.sleep(forTimeInterval: 0.01) }
        expect(abrupt.terminationStatus == 0 && FileManager.default.fileExists(atPath: marker.path),
               "Parent exit without cleanup still restores through pipe EOF")
        print("PASS: \(checks) assertions — click dynamics, audio, characters, geometry and multi-display coordinates")
    }
}


private final class FakeCursorBackend: CursorVisibilityBackend {
    var visible = true
    var visibilityAvailable = true
    var reportHidden = false
    var backgroundEnabled = false
    var arrowTransparent = false
    var arrowControlAvailable = true
    var captureCursorTransparent = false
    var capturePublishes = 0
    var depth = 0
    var hideCalls = 0
    var showCalls = 0
    var hideSucceeds = true
    var showSucceeds = true
    var isVisible: Bool? { visibilityAvailable ? (reportHidden ? false : visible) : nil }
    func setBackgroundControl(_ enabled: Bool) -> Bool { backgroundEnabled = enabled; return true }
    func setArrowTransparent(_ transparent: Bool) -> Bool {
        guard arrowControlAvailable else { return false }
        arrowTransparent = transparent
        return true
    }
    func dockForceShow() { visible = true }
    func setCaptureCursorTransparent(_ transparent: Bool) {
        captureCursorTransparent = transparent
        if transparent { capturePublishes += 1 }
    }
    func hide() -> Bool {
        guard hideSucceeds else { return false }
        hideCalls += 1; depth += 1; visible = false; return true
    }
    func show() -> Bool {
        guard showSucceeds else { return false }
        showCalls += 1; depth -= 1; visible = depth == 0; return true
    }
}
