import Foundation

enum InlineQueryNormalizer {
    static func normalize(
        _ query: String,
        prefixes: [String]
    ) -> String {
        var cleaned = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")

        if cleaned.hasSuffix("?") {
            cleaned.removeLast()
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        for prefix in prefixes where cleaned.hasPrefix(prefix) {
            cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }

        return cleaned
    }
}
