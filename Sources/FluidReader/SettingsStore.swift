import AVFoundation
import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private var isLoading = true

    @Published var voiceIdentifier: String {
        didSet { save("voiceIdentifier", voiceIdentifier) }
    }

    @Published var speechRate: Double {
        didSet { save("speechRate", speechRate) }
    }

    @Published var speechPitch: Double {
        didSet { save("speechPitch", speechPitch) }
    }

    @Published var speechVolume: Double {
        didSet { save("speechVolume", speechVolume) }
    }

    @Published var readAfterPick: Bool {
        didSet { save("readAfterPick", readAfterPick) }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet { save("soundEffectsEnabled", soundEffectsEnabled) }
    }

    @Published var effectVolume: Double {
        didSet { save("effectVolume", effectVolume) }
    }

    @Published var soundStyle: String {
        didSet { save("soundStyle", soundStyle) }
    }

    @Published var feelIntensity: Double {
        didSet { save("feelIntensity", feelIntensity) }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { save("hapticFeedbackEnabled", hapticFeedbackEnabled) }
    }

    @Published var ocrLanguageCode: String {
        didSet { save("ocrLanguageCode", ocrLanguageCode) }
    }

    @Published var llmEnabled: Bool {
        didSet { save("llmEnabled", llmEnabled) }
    }

    @Published var llmModel: String {
        didSet { save("llmModel", llmModel) }
    }

    @Published var openAIAPIKey: String {
        didSet {
            guard !isLoading else { return }
            KeychainStore.set(openAIAPIKey, service: "FluidReader", account: "openai-api-key")
        }
    }

    @Published var useCloudVoiceForLLM: Bool {
        didSet { save("useCloudVoiceForLLM", useCloudVoiceForLLM) }
    }

    @Published var cloudVoiceModel: String {
        didSet { save("cloudVoiceModel", cloudVoiceModel) }
    }

    @Published var cloudVoiceName: String {
        didSet { save("cloudVoiceName", cloudVoiceName) }
    }

    @Published var cloudVoiceInstructions: String {
        didSet { save("cloudVoiceInstructions", cloudVoiceInstructions) }
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .sorted { left, right in
                if left.language == right.language {
                    return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
                }
                return left.language.localizedCaseInsensitiveCompare(right.language) == .orderedAscending
            }
    }

    private init() {
        defaults.register(defaults: [
            "speechRate": 0.48,
            "speechPitch": 1.0,
            "speechVolume": 0.92,
            "readAfterPick": true,
            "soundEffectsEnabled": true,
            "effectVolume": 0.72,
            "soundStyle": "glass",
            "feelIntensity": 0.84,
            "hapticFeedbackEnabled": true,
            "ocrLanguageCode": "en-US",
            "llmEnabled": false,
            "llmModel": AppDefaults.llmModel,
            "useCloudVoiceForLLM": false,
            "cloudVoiceModel": AppDefaults.cloudVoiceModel,
            "cloudVoiceName": AppDefaults.cloudVoiceName,
            "cloudVoiceInstructions": AppDefaults.cloudVoiceInstructions
        ])

        voiceIdentifier = defaults.string(forKey: "voiceIdentifier") ?? Self.defaultVoiceIdentifier()
        speechRate = defaults.double(forKey: "speechRate")
        speechPitch = defaults.double(forKey: "speechPitch")
        speechVolume = defaults.double(forKey: "speechVolume")
        readAfterPick = defaults.bool(forKey: "readAfterPick")
        soundEffectsEnabled = defaults.bool(forKey: "soundEffectsEnabled")
        effectVolume = defaults.double(forKey: "effectVolume")
        soundStyle = defaults.string(forKey: "soundStyle") ?? "glass"
        feelIntensity = defaults.double(forKey: "feelIntensity")
        hapticFeedbackEnabled = defaults.bool(forKey: "hapticFeedbackEnabled")
        ocrLanguageCode = defaults.string(forKey: "ocrLanguageCode") ?? "en-US"
        llmEnabled = defaults.bool(forKey: "llmEnabled")
        llmModel = defaults.string(forKey: "llmModel") ?? AppDefaults.llmModel
        openAIAPIKey = KeychainStore.get(service: "FluidReader", account: "openai-api-key") ?? ""
        useCloudVoiceForLLM = defaults.bool(forKey: "useCloudVoiceForLLM")
        cloudVoiceModel = defaults.string(forKey: "cloudVoiceModel") ?? AppDefaults.cloudVoiceModel
        cloudVoiceName = defaults.string(forKey: "cloudVoiceName") ?? AppDefaults.cloudVoiceName
        cloudVoiceInstructions = defaults.string(forKey: "cloudVoiceInstructions")
            ?? AppDefaults.cloudVoiceInstructions
        isLoading = false
    }

    private func save<T>(_ key: String, _ value: T) {
        guard !isLoading else { return }
        defaults.set(value, forKey: key)
    }

    private static func defaultVoiceIdentifier() -> String {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferredNames = ["Ava", "Nicky", "Samantha", "Zoe", "Allison", "Karen", "Moira", "Daniel"]

        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        let scoredVoice = englishVoices.max { left, right in
            scoreVoice(left, preferredNames: preferredNames) < scoreVoice(right, preferredNames: preferredNames)
        }

        if let scoredVoice {
            return scoredVoice.identifier
        }

        if let englishVoice = englishVoices.first {
            return englishVoice.identifier
        }

        return voices.first?.identifier ?? ""
    }

    private static func scoreVoice(
        _ voice: AVSpeechSynthesisVoice,
        preferredNames: [String]
    ) -> Int {
        let loweredName = voice.name.lowercased()
        let preferredRank = preferredNames.firstIndex {
            loweredName.contains($0.lowercased())
        }
        let preferredScore = preferredRank.map { 80 - $0 } ?? 0
        let languageScore = voice.language == "en-US" ? 16 : 8
        let qualityScore = voice.quality.rawValue * 100

        return qualityScore + preferredScore + languageScore
    }
}
