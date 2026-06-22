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
                sourceKind: .web,
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
            sourceKind: .web,
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
            sourceKind: .web,
            keywords: [cleanQuery, cleanURL],
            canFavorite: false
        ) {
            copy(cleanURL)
        }
    }

    static func makeSaveQuickLinkAction(
        query: String,
        existingItems: [QuickLinkItem],
        save: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        let cleanQuery = cleanedQuery(query)
        guard let item = QuickLinkItem.make(urlString: cleanQuery),
              !existingItems.contains(where: { $0.urlString == item.urlString }) else {
            return nil
        }

        return CommandPaletteAction(
            id: "inline-save-quick-link",
            title: "Save Link: \(FreeformPrompt.preview(item.displayURL, limit: titleLimit))",
            subtitle: "Add to Quick Links",
            systemImage: "link.badge.plus",
            sourceKind: .link,
            keywords: [cleanQuery, item.title, item.urlString, "link", "quick link", "bookmark"],
            canFavorite: false
        ) {
            save(item.urlString)
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
        // URLComponents leaves "+" unescaped in query values, but servers
        // decode "+" as a space. Escape it so queries like "c++ tutorial"
        // reach DuckDuckGo intact. (Spaces are already encoded as %20 here,
        // so every remaining "+" came from the user's text.)
        if let encodedQuery = components?.percentEncodedQuery {
            components?.percentEncodedQuery = encodedQuery.replacingOccurrences(of: "+", with: "%2B")
        }
        return components?.url
    }

    static func webURL(from text: String) -> URL? {
        var candidate = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty,
              candidate.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return nil
        }

        let lowercased = candidate.lowercased()
        let hasExplicitScheme = lowercased.contains("://")
        if !hasExplicitScheme, candidate.contains(".") {
            candidate = "https://\(candidate)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              // Reject embedded credentials ("apple.com@evil.com") so a string
              // that looks like a trusted domain cannot open a different host.
              url.user == nil,
              url.password == nil,
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        if !hasExplicitScheme {
            // Avoid URL-ifying dotted tokens like "3.14" or "1.2.3": only
            // treat the text as a URL when the synthesized host ends in an
            // alphabetic top-level domain.
            let topLevelDomain = host.split(separator: ".").last ?? ""
            guard topLevelDomain.count >= 2, topLevelDomain.allSatisfy(\.isLetter) else {
                return nil
            }
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
