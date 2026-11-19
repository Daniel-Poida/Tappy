import AVFoundation
import Foundation

/// Pre-rendered, deterministic PCM: no file I/O or player allocation on click.
final class SoundManager {
    static let shared = SoundManager()
    private var players: [TapSound: [AVAudioPlayer]] = [:]
    private var nextVoice: [TapSound: Int] = [:]

    init() {
        for style in TapSound.allCases {
            players[style] = (0..<8).compactMap { _ in
                guard let player = try? AVAudioPlayer(data: SoundSynthesis.wav(style: style)) else { return nil }
                player.enableRate = true
                player.prepareToPlay()
                return player
            }
        }
    }

    static func gain(energy: Double, volume: Double, mood: Double) -> Float {
        let master = min(1.0, max(0.0, volume))
        let energyGain = min(1.0, max(0.0, energy))
        let personality = min(1.0, max(0.0, mood))
        return Float(master * (0.35 + 0.65 * energyGain * personality))
    }

    func playKnock(energy: Double = 0, settings: TappySettings = .shared) {
        guard settings.soundEnabled, let pool = players[settings.soundStyle], !pool.isEmpty else { return }
        let index = nextVoice[settings.soundStyle, default: 0] % pool.count
        nextVoice[settings.soundStyle] = index + 1
        let player = pool[index]
        player.stop()
        player.currentTime = 0
        player.volume = Self.gain(energy: energy, volume: settings.volume, mood: settings.mood)
        player.rate = Float(1 + energy * settings.mood * 0.18)
        player.play()
    }
}

enum SoundSynthesis {
    static let sampleRate = 44100
    static func wav(style: TapSound) -> Data {
        let count = Int(Double(sampleRate) * 0.22)
        var data = Data()
        func append<T: FixedWidthInteger>(_ number: T) {
            var value = number.littleEndian
            withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
        }
        data.append(contentsOf: "RIFF".utf8); append(UInt32(count * 2 + 36))
        data.append(contentsOf: "WAVEfmt ".utf8); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: "data".utf8); append(UInt32(count * 2))
        var seed: UInt32 = 42
        for i in 0..<count {
            let t = Double(i) / Double(sampleRate)
            seed = 1664525 &* seed &+ 1013904223
            let noise = Double(seed) / Double(UInt32.max) * 2 - 1
            let sample: Double
            switch style {
            case .knock:
                sample = (sin(2 * .pi * 520 * t) * 0.65 + sin(2 * .pi * 1170 * t) * 0.22) * exp(-t * 42)
                    + noise * exp(-t * 180) * 0.25
            case .moon:
                sample = (sin(2 * .pi * 880 * t) + sin(2 * .pi * 1320 * t) * 0.45 + sin(2 * .pi * 1760 * t) * 0.2) * exp(-t * 19) * 0.5
            case .star:
                let phase = 2 * Double.pi * (1100 * t + 1400 * t * t)
                sample = (sin(phase) * 0.6 + sin(phase * 1.5) * 0.2) * exp(-t * 23) + noise * exp(-t * 90) * 0.08
            case .spell:
                let phase = 2 * Double.pi * (300 * t + 2500 * t * t)
                sample = (noise * 0.3 * exp(-t * 30) + sin(phase) * exp(-t * 20) * 0.55) * min(1, t * 180)
            case .witch:
                let phase = 2 * Double.pi * (210 * t - 210 * t * t + 0.65 * sin(2 * .pi * 22 * t))
                sample = (sin(phase) * 0.47 + sin(phase * 1.51) * 0.19 + noise * 0.18) * exp(-t * 17) * min(1, t * 140)
            case .sword:
                sample = (sin(2 * .pi * 980 * t) * 0.45 + sin(2 * .pi * 2170 * t) * 0.27 + sin(2 * .pi * 3410 * t) * 0.13) * exp(-t * 24) + noise * exp(-t * 150) * 0.1
            case .redSaber:
                let phase = 2 * Double.pi * (105 * t + 1450 * t * t)
                sample = (sin(phase) * 0.5 + sin(phase * 2) * 0.18 + noise * 0.2) * exp(-t * 19) * min(1, t * 170)
            case .greenSaber:
                let phase = 2 * Double.pi * (370 * t - 600 * t * t)
                sample = (sin(phase) * 0.45 + sin(phase * 1.98) * 0.2 + noise * 0.13) * exp(-t * 17) * min(1, t * 160)
            }
            let attack = min(1, t / 0.0015)
            let tail = min(1, (Double(count - i) / Double(sampleRate)) / 0.01)
            append(Int16(max(-1, min(1, sample * attack * tail)) * 0.88 * Double(Int16.max)))
        }
        return data
    }
}
