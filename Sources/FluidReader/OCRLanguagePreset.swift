import Foundation

struct OCRLanguagePreset: Identifiable, Equatable {
    let id: String
    let title: String
    let languageCode: String
    let keywords: [String]

    static let presets: [OCRLanguagePreset] = [
        OCRLanguagePreset(id: "auto", title: "Auto", languageCode: "", keywords: ["detect", "automatic"]),
        OCRLanguagePreset(id: "english", title: "English", languageCode: "en-US", keywords: ["english", "en"]),
        OCRLanguagePreset(id: "spanish", title: "Spanish", languageCode: "es-ES", keywords: ["spanish", "es"]),
        OCRLanguagePreset(id: "french", title: "French", languageCode: "fr-FR", keywords: ["french", "fr"]),
        OCRLanguagePreset(id: "german", title: "German", languageCode: "de-DE", keywords: ["german", "de"]),
        OCRLanguagePreset(id: "portuguese", title: "Portuguese", languageCode: "pt-BR", keywords: ["portuguese", "pt"]),
        OCRLanguagePreset(id: "chinese-simplified", title: "Chinese Simplified", languageCode: "zh-Hans", keywords: ["chinese", "simplified", "zh"]),
        OCRLanguagePreset(id: "chinese-traditional", title: "Chinese Traditional", languageCode: "zh-Hant", keywords: ["chinese", "traditional", "zh"]),
        OCRLanguagePreset(id: "japanese", title: "Japanese", languageCode: "ja-JP", keywords: ["japanese", "ja"]),
        OCRLanguagePreset(id: "korean", title: "Korean", languageCode: "ko-KR", keywords: ["korean", "ko"]),
        OCRLanguagePreset(id: "russian", title: "Russian", languageCode: "ru-RU", keywords: ["russian", "ru"])
    ]

    static func title(for languageCode: String) -> String {
        let cleanCode = clean(languageCode)
        if let preset = presets.first(where: { $0.languageCode == cleanCode }) {
            return preset.title
        }
        return cleanCode.isEmpty ? "Auto" : cleanCode
    }

    static func normalized(_ languageCode: String) -> String {
        clean(languageCode)
    }

    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
