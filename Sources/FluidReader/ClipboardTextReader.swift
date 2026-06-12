import AppKit

enum ClipboardTextReader {
    static func clean(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.isEmpty ? nil : cleanText
    }

    @MainActor
    static func readClipboardText(from pasteboard: NSPasteboard = .general) -> String? {
        clean(pasteboard.string(forType: .string))
    }
}
