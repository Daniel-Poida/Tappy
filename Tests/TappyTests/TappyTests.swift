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
        }
        print("PASS: \(checks) assertions — click dynamics, audio, characters, geometry and multi-display coordinates")
    }
}
