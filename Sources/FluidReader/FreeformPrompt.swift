import Foundation

enum FreeformPrompt {
    static let maxLength = 2_000

    static func clean(_ value: String) -> String {
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanValue.count > maxLength else { return cleanValue }
        return String(cleanValue.prefix(maxLength))
    }

    static func preview(_ value: String, limit: Int) -> String {
        let cleanValue = clean(value)
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        guard cleanValue.count > limit else { return cleanValue }
        return "\(cleanValue.prefix(limit))..."
    }
}
