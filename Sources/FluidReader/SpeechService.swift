import AppKit
import AVFoundation
import Foundation

@MainActor
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, settings: SettingsStore) {
        stop()

        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: cleanText)
        utterance.rate = Float(settings.speechRate)
        utterance.pitchMultiplier = Float(settings.speechPitch)
        utterance.volume = Float(settings.speechVolume)

        if let voice = AVSpeechSynthesisVoice(identifier: settings.voiceIdentifier) {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    func playAudioData(_ data: Data) {
        stop()

        do {
            let player = try AVAudioPlayer(data: data)
            audioPlayer = player
            player.delegate = self
            player.prepareToPlay()
            player.play()
        } catch {
            NSSound.beep()
        }
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
    }
}
