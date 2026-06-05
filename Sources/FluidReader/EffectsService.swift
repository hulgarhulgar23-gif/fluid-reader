import AppKit
import AVFoundation
import Foundation

@MainActor
final class EffectsService {
    static let availableStyles = ["soft", "glass", "jackpot"]

    enum Effect: Hashable {
        case wake
        case drawStart
        case capture
        case success
        case scanTick
        case tap
        case error
    }

    private struct Tone {
        let frequency: Double
        let start: Double
        let duration: Double
        let gain: Double
    }

    private struct SoundKey: Hashable {
        let effect: Effect
        let style: String
    }

    private var soundCache: [SoundKey: Data] = [:]
    private var players: [AVAudioPlayer] = []
    private var warmPlayer: AVAudioPlayer?
    private var didWarmAudioPath = false

    func preload(style: String) {
        let style = normalizedStyle(style)
        for effect in [Effect.wake, .drawStart, .capture, .success, .scanTick, .tap, .error] {
            let key = SoundKey(effect: effect, style: style)
            soundCache[key] = soundCache[key] ?? makeSound(for: effect, style: style)
        }
    }

    func preloadAllStyles() {
        for style in Self.availableStyles {
            preload(style: style)
        }
    }

    func warmAudioPath() {
        guard !didWarmAudioPath else { return }
        didWarmAudioPath = true

        do {
            let player = try AVAudioPlayer(data: makeWav(duration: 0.025, tones: []))
            player.volume = 0
            player.prepareToPlay()
            warmPlayer = player
            player.play()

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 180_000_000)
                await MainActor.run {
                    self?.warmPlayer = nil
                }
            }
        } catch {
            warmPlayer = nil
        }
    }

    func play(_ effect: Effect, settings: SettingsStore) {
        guard settings.soundEffectsEnabled else { return }
        warmAudioPath()
        players.removeAll { !$0.isPlaying }

        do {
            let style = normalizedStyle(settings.soundStyle)
            let key = SoundKey(effect: effect, style: style)
            let data = soundCache[key] ?? makeSound(for: effect, style: style)
            soundCache[key] = data

            let player = try AVAudioPlayer(data: data)
            let intensity = max(0.20, min(1.0, settings.feelIntensity))
            let lift = 0.56 + intensity * 0.44
            player.volume = Float(min(1.0, settings.effectVolume * lift))
            player.prepareToPlay()
            players.append(player)
            player.play()
        } catch {
            NSSound.beep()
        }
    }

    func haptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic, settings: SettingsStore) {
        guard settings.hapticFeedbackEnabled else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }

    func hit(_ effect: Effect, settings: SettingsStore, haptic pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        play(effect, settings: settings)
        haptic(pattern, settings: settings)

        if effect == .success, settings.hapticFeedbackEnabled, settings.feelIntensity > 0.78 {
            Task {
                try? await Task.sleep(nanoseconds: 82_000_000)
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        }
    }

    private func makeSound(for effect: Effect, style: String) -> Data {
        let style = normalizedStyle(style)

        switch (effect, style) {
        case (.wake, "soft"):
            return makeWav(
                duration: 0.14,
                tones: [
                    Tone(frequency: 493.88, start: 0.00, duration: 0.07, gain: 0.24),
                    Tone(frequency: 739.99, start: 0.04, duration: 0.08, gain: 0.16)
                ]
            )
        case (.wake, "jackpot"):
            return makeWav(
                duration: 0.18,
                tones: [
                    Tone(frequency: 587.33, start: 0.00, duration: 0.06, gain: 0.36),
                    Tone(frequency: 880.00, start: 0.045, duration: 0.08, gain: 0.30),
                    Tone(frequency: 1174.66, start: 0.10, duration: 0.07, gain: 0.18)
                ]
            )
        case (.wake, _):
            return makeWav(
                duration: 0.16,
                tones: [
                    Tone(frequency: 587.33, start: 0.00, duration: 0.08, gain: 0.46),
                    Tone(frequency: 880.00, start: 0.04, duration: 0.10, gain: 0.34)
                ]
            )

        case (.drawStart, "soft"):
            return makeWav(
                duration: 0.08,
                tones: [
                    Tone(frequency: 659.25, start: 0.00, duration: 0.045, gain: 0.18),
                    Tone(frequency: 987.77, start: 0.02, duration: 0.045, gain: 0.10)
                ]
            )
        case (.drawStart, "jackpot"):
            return makeWav(
                duration: 0.10,
                tones: [
                    Tone(frequency: 880.00, start: 0.00, duration: 0.045, gain: 0.26),
                    Tone(frequency: 1320.00, start: 0.025, duration: 0.055, gain: 0.17)
                ]
            )
        case (.drawStart, _):
            return makeWav(
                duration: 0.09,
                tones: [
                    Tone(frequency: 740.00, start: 0.00, duration: 0.05, gain: 0.28),
                    Tone(frequency: 1174.66, start: 0.02, duration: 0.05, gain: 0.18)
                ]
            )

        case (.capture, "soft"):
            return makeWav(
                duration: 0.11,
                tones: [
                    Tone(frequency: 554.37, start: 0.00, duration: 0.055, gain: 0.24),
                    Tone(frequency: 830.61, start: 0.04, duration: 0.060, gain: 0.16)
                ]
            )
        case (.capture, "jackpot"):
            return makeWav(
                duration: 0.14,
                tones: [
                    Tone(frequency: 659.25, start: 0.00, duration: 0.050, gain: 0.30),
                    Tone(frequency: 987.77, start: 0.04, duration: 0.065, gain: 0.26),
                    Tone(frequency: 1480.00, start: 0.085, duration: 0.045, gain: 0.12)
                ]
            )
        case (.capture, _):
            return makeWav(
                duration: 0.13,
                tones: [
                    Tone(frequency: 659.25, start: 0.00, duration: 0.06, gain: 0.36),
                    Tone(frequency: 987.77, start: 0.04, duration: 0.08, gain: 0.28)
                ]
            )

        case (.success, "soft"):
            return makeWav(
                duration: 0.38,
                tones: [
                    Tone(frequency: 493.88, start: 0.00, duration: 0.070, gain: 0.16),
                    Tone(frequency: 587.33, start: 0.070, duration: 0.080, gain: 0.18),
                    Tone(frequency: 739.99, start: 0.145, duration: 0.120, gain: 0.20),
                    Tone(frequency: 987.77, start: 0.235, duration: 0.125, gain: 0.12)
                ]
            )
        case (.success, "jackpot"):
            return makeWav(
                duration: 0.52,
                tones: [
                    Tone(frequency: 392.00, start: 0.00, duration: 0.040, gain: 0.18),
                    Tone(frequency: 493.88, start: 0.050, duration: 0.045, gain: 0.20),
                    Tone(frequency: 587.33, start: 0.100, duration: 0.050, gain: 0.22),
                    Tone(frequency: 783.99, start: 0.155, duration: 0.080, gain: 0.30),
                    Tone(frequency: 1046.50, start: 0.225, duration: 0.115, gain: 0.28),
                    Tone(frequency: 1567.98, start: 0.315, duration: 0.135, gain: 0.18),
                    Tone(frequency: 2093.00, start: 0.410, duration: 0.085, gain: 0.10)
                ]
            )
        case (.success, _):
            return makeWav(
                duration: 0.46,
                tones: [
                    Tone(frequency: 440.00, start: 0.00, duration: 0.045, gain: 0.20),
                    Tone(frequency: 554.37, start: 0.055, duration: 0.050, gain: 0.22),
                    Tone(frequency: 659.25, start: 0.110, duration: 0.055, gain: 0.24),
                    Tone(frequency: 880.00, start: 0.165, duration: 0.120, gain: 0.31),
                    Tone(frequency: 1318.51, start: 0.230, duration: 0.130, gain: 0.24),
                    Tone(frequency: 1760.00, start: 0.320, duration: 0.120, gain: 0.14)
                ]
            )

        case (.scanTick, "soft"):
            return makeWav(
                duration: 0.045,
                tones: [
                    Tone(frequency: 987.77, start: 0.00, duration: 0.030, gain: 0.12)
                ]
            )
        case (.scanTick, "jackpot"):
            return makeWav(
                duration: 0.060,
                tones: [
                    Tone(frequency: 1318.51, start: 0.00, duration: 0.034, gain: 0.21),
                    Tone(frequency: 2637.02, start: 0.008, duration: 0.026, gain: 0.10)
                ]
            )
        case (.scanTick, _):
            return makeWav(
                duration: 0.055,
                tones: [
                    Tone(frequency: 1174.66, start: 0.00, duration: 0.035, gain: 0.20),
                    Tone(frequency: 2349.32, start: 0.006, duration: 0.026, gain: 0.08)
                ]
            )

        case (.tap, "soft"):
            return makeWav(
                duration: 0.05,
                tones: [
                    Tone(frequency: 740.00, start: 0.00, duration: 0.035, gain: 0.14)
                ]
            )
        case (.tap, "jackpot"):
            return makeWav(
                duration: 0.065,
                tones: [
                    Tone(frequency: 1046.50, start: 0.00, duration: 0.040, gain: 0.22),
                    Tone(frequency: 2093.00, start: 0.010, duration: 0.030, gain: 0.08)
                ]
            )
        case (.tap, _):
            return makeWav(
                duration: 0.06,
                tones: [
                    Tone(frequency: 950.00, start: 0.00, duration: 0.04, gain: 0.22)
                ]
            )

        case (.error, "soft"):
            return makeWav(
                duration: 0.16,
                tones: [
                    Tone(frequency: 329.63, start: 0.00, duration: 0.08, gain: 0.18),
                    Tone(frequency: 277.18, start: 0.06, duration: 0.08, gain: 0.12)
                ]
            )
        case (.error, "jackpot"):
            return makeWav(
                duration: 0.20,
                tones: [
                    Tone(frequency: 349.23, start: 0.00, duration: 0.09, gain: 0.28),
                    Tone(frequency: 293.66, start: 0.06, duration: 0.11, gain: 0.22)
                ]
            )
        case (.error, _):
            return makeWav(
                duration: 0.18,
                tones: [
                    Tone(frequency: 349.23, start: 0.00, duration: 0.10, gain: 0.26),
                    Tone(frequency: 293.66, start: 0.06, duration: 0.10, gain: 0.20)
                ]
            )
        }
    }

    private func normalizedStyle(_ style: String) -> String {
        let clean = style.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean == "soft" || clean == "jackpot" {
            return clean
        }
        return "glass"
    }

    private func makeWav(duration: Double, tones: [Tone]) -> Data {
        let sampleRate = 44_100
        let frameCount = Int(duration * Double(sampleRate))
        var samples = [Int16]()
        samples.reserveCapacity(frameCount)

        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            var mixed = 0.0

            for tone in tones {
                let localTime = time - tone.start
                guard localTime >= 0, localTime <= tone.duration else { continue }

                let progress = localTime / tone.duration
                let attack = min(1.0, progress / 0.10)
                let release = pow(max(0.0, 1.0 - progress), 1.65)
                let envelope = attack * release
                let shimmer = sin(2.0 * .pi * tone.frequency * 2.01 * time) * 0.12
                let wave = sin(2.0 * .pi * tone.frequency * time) + shimmer
                mixed += wave * envelope * tone.gain
            }

            let soft = tanh(mixed)
            samples.append(Int16(max(-1.0, min(1.0, soft)) * Double(Int16.max)))
        }

        var data = Data()
        let byteCount = samples.count * MemoryLayout<Int16>.size

        data.append("RIFF".data(using: .ascii)!)
        appendUInt32(UInt32(36 + byteCount), to: &data)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        appendUInt32(16, to: &data)
        appendUInt16(1, to: &data)
        appendUInt16(1, to: &data)
        appendUInt32(UInt32(sampleRate), to: &data)
        appendUInt32(UInt32(sampleRate * MemoryLayout<Int16>.size), to: &data)
        appendUInt16(UInt16(MemoryLayout<Int16>.size), to: &data)
        appendUInt16(16, to: &data)
        data.append("data".data(using: .ascii)!)
        appendUInt32(UInt32(byteCount), to: &data)

        samples.withUnsafeBufferPointer { buffer in
            data.append(UnsafeBufferPointer(start: buffer.baseAddress, count: buffer.count))
        }

        return data
    }

    private func appendUInt16(_ value: UInt16, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }

    private func appendUInt32(_ value: UInt32, to data: inout Data) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
    }
}
