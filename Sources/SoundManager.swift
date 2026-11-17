import AudioToolbox
import Foundation

class SoundManager {
    static let shared = SoundManager()

    private var soundURL: URL?

    init() {
        soundURL = generateKnockSound()
    }

    func playKnock() {
        guard TappySettings.shared.soundEnabled else { return }
        guard let url = soundURL else { return }

        var soundID: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        guard status == noErr else { return }

        AudioServicesPlaySystemSound(soundID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }

    private func generateKnockSound() -> URL? {
        let sampleRate: Double = 44100
        let duration: Double = 0.12
        let numSamples = Int(sampleRate * duration)

        var data = Data()
        data.reserveCapacity(numSamples * 2 + 44)

        let bytesPerSample = 2
        let byteRate = Int(sampleRate) * bytesPerSample
        let dataSize = numSamples * bytesPerSample

        data.append("RIFF".data(using: .ascii)!)
        data.append(littleEndian: UInt32(dataSize + 36))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        data.append(littleEndian: UInt32(16))
        data.append(littleEndian: UInt16(1))
        data.append(littleEndian: UInt16(1))
        data.append(littleEndian: UInt32(sampleRate))
        data.append(littleEndian: UInt32(byteRate))
        data.append(littleEndian: UInt16(bytesPerSample))
        data.append(littleEndian: UInt16(16))
        data.append("data".data(using: .ascii)!)
        data.append(littleEndian: UInt32(dataSize))

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 35.0)
            let tone = sin(2.0 * .pi * 650.0 * t) * envelope
            let click = (Double.random(in: -1.0...1.0) * exp(-t * 120.0)) * 0.3
            let sample = max(-1.0, min(1.0, tone + click))
            let value = Int16(sample * 0.6 * Double(Int16.max))
            data.append(littleEndian: value)
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pokey-knock.wav")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

private extension Data {
    mutating func append<T: FixedWidthInteger>(littleEndian value: T) {
        var value = value
        withUnsafePointer(to: &value) {
            self.append(UnsafeBufferPointer(start: $0, count: 1))
        }
    }
}
