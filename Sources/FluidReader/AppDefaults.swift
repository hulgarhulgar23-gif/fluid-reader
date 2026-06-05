import Foundation

enum AppDefaults {
    static let llmModel = "gpt-5.4-mini"
    static let cloudVoiceModel = "gpt-4o-mini-tts"
    static let cloudVoiceName = "alloy"
    static let cloudVoiceInstructions = "Speak in a warm, calm, clear voice. Keep a natural pace."

    static let screenRecordingSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    )

    static func value(_ value: String, fallback: String) -> String {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }
}
