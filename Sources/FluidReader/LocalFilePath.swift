import Foundation

enum LocalFilePath {
    static let titleLimit = 72

    static func makeActions(
        query: String,
        open: @escaping (URL) -> Void,
        reveal: @escaping (URL) -> Void
    ) -> [CommandPaletteAction] {
        guard let url = url(from: query) else { return [] }

        let title = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
        let preview = FreeformPrompt.preview(title, limit: titleLimit)
        return [
            CommandPaletteAction(
                id: "inline-open-path",
                title: "Open Path: \(preview)",
                subtitle: url.path,
                systemImage: "folder",
                sourceKind: .path,
                keywords: ["open", "file", "folder", "path", "finder", query],
                canFavorite: false
            ) {
                open(url)
            },
            CommandPaletteAction(
                id: "inline-reveal-path",
                title: "Reveal Path: \(preview)",
                subtitle: url.path,
                systemImage: "folder.badge.questionmark",
                sourceKind: .path,
                keywords: ["reveal", "show", "file", "folder", "path", "finder", query],
                canFavorite: false
            ) {
                reveal(url)
            }
        ]
    }

    static func url(from text: String, fileManager: FileManager = .default) -> URL? {
        guard let path = normalizedPath(from: text),
              fileManager.fileExists(atPath: path) else {
            return nil
        }

        return URL(fileURLWithPath: path).standardizedFileURL
    }

    static func normalizedPath(from text: String) -> String? {
        let cleanText = stripMatchingQuotes(text.trimmingCharacters(in: .whitespacesAndNewlines))
            .replacingOccurrences(of: "\\ ", with: " ")
        guard !cleanText.isEmpty,
              cleanText.rangeOfCharacter(from: .newlines) == nil else {
            return nil
        }

        if let url = URL(string: cleanText), url.isFileURL {
            return url.path
        }

        let expandedPath = (cleanText as NSString).expandingTildeInPath
        guard expandedPath.hasPrefix("/") else { return nil }
        return expandedPath
    }

    private static func stripMatchingQuotes(_ text: String) -> String {
        guard text.count >= 2,
              let first = text.first,
              let last = text.last,
              first == last,
              ["\"", "'"].contains(first) else {
            return text
        }

        return String(text.dropFirst().dropLast())
    }
}
