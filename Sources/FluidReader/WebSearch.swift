import Foundation

enum WebSearch {
    static let minimumQueryLength = 2
    static let titleLimit = 72

    static func makeAction(
        query: String,
        open: @escaping (URL) -> Void
    ) -> CommandPaletteAction? {
        let cleanQuery = cleanedQuery(query)
        guard cleanQuery.count >= minimumQueryLength else { return nil }

        if let url = webURL(from: cleanQuery) {
            return CommandPaletteAction(
                id: "inline-open-url",
                title: "Open URL: \(FreeformPrompt.preview(cleanQuery, limit: titleLimit))",
                subtitle: "Open in your default browser",
                systemImage: "safari",
                keywords: [cleanQuery],
                canFavorite: false
            ) {
                open(url)
            }
        }

        guard let url = searchURL(for: cleanQuery) else { return nil }
        return CommandPaletteAction(
            id: "inline-web-search",
            title: "Search Web: \(FreeformPrompt.preview(cleanQuery, limit: titleLimit))",
            subtitle: "Search with DuckDuckGo",
            systemImage: "magnifyingglass.circle",
            keywords: [cleanQuery],
            canFavorite: false
        ) {
            open(url)
        }
    }

    static func makeCleanURLAction(
        query: String,
        copy: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        let cleanQuery = cleanedQuery(query)
        guard let cleanURL = ClipboardUtility.cleanURL(cleanQuery),
              cleanURL != webURL(from: cleanQuery)?.absoluteString else {
            return nil
        }

        return CommandPaletteAction(
            id: "inline-clean-url",
            title: "Clean URL: \(FreeformPrompt.preview(cleanURL, limit: titleLimit))",
            subtitle: "Copy without tracking",
            systemImage: "link.badge.minus",
            keywords: [cleanQuery, cleanURL],
            canFavorite: false
        ) {
            copy(cleanURL)
        }
    }

    static func markdownLink(from query: String) -> String? {
        let cleanQuery = cleanedQuery(query)
        guard let url = webURL(from: cleanQuery),
              let link = ResultExportDocument.markdownLink(url: url) else {
            return nil
        }

        return link
    }

    static func searchURL(for query: String) -> URL? {
        let cleanQuery = cleanedQuery(query)
        guard cleanQuery.count >= minimumQueryLength else { return nil }

        var components = URLComponents(string: "https://duckduckgo.com/")
        components?.queryItems = [URLQueryItem(name: "q", value: cleanQuery)]
        return components?.url
    }

    static func webURL(from text: String) -> URL? {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty,
              candidate.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return nil
        }

        let lowercased = candidate.lowercased()
        if !lowercased.contains("://"), candidate.contains(".") {
            candidate = "https://\(candidate)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        return url
    }

    private static func cleanedQuery(_ query: String) -> String {
        FreeformPrompt.clean(query)
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
