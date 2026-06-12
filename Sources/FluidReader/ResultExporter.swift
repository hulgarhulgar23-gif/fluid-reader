import Foundation

struct ResultExportDocument: Equatable {
    let title: String
    let fileName: String
    let allowedFileTypes: [String]
    let contents: String

    static func textDocument(text: String, title: String, fileNamePrefix: String) -> ResultExportDocument? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        return ResultExportDocument(
            title: title,
            fileName: "\(fileName(from: fileNamePrefix, fallback: "fluid-reader-text")).txt",
            allowedFileTypes: ["txt"],
            contents: cleanText
        )
    }

    static func markdownDocument(text: String, answer: String) -> ResultExportDocument? {
        let cleanText = clean(text)
        let cleanAnswer = clean(answer)
        guard !cleanText.isEmpty || !cleanAnswer.isEmpty else { return nil }

        var sections: [String] = ["# Fluid Reader Result"]

        if !cleanText.isEmpty {
            sections.append("## Selected Text\n\n\(cleanText)")
        }

        if !cleanAnswer.isEmpty {
            sections.append("## Answer\n\n\(cleanAnswer)")
        }

        return ResultExportDocument(
            title: "Save Result",
            fileName: "\(fileName(from: cleanText.isEmpty ? cleanAnswer : cleanText, fallback: "fluid-reader-result")).md",
            allowedFileTypes: ["md"],
            contents: sections.joined(separator: "\n\n")
        )
    }

    static func markdownQuote(text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        return cleanText
            .components(separatedBy: .newlines)
            .map { line in line.isEmpty ? ">" : "> \(line)" }
            .joined(separator: "\n")
    }

    static func markdownCodeBlock(text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        let fence = codeFence(for: cleanText)
        return "\(fence)\n\(cleanText)\n\(fence)"
    }

    static func markdownLink(url: URL) -> String? {
        guard let host = url.host, !host.isEmpty else { return nil }

        var title = host
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !path.isEmpty {
            title += "/\(path)"
        }

        return "[\(escapeMarkdownLinkTitle(title))](\(url.absoluteString))"
    }

    static func recentItemsDocument(_ items: [ReaderHistoryItem]) -> ResultExportDocument? {
        guard !items.isEmpty else { return nil }

        let sections = items.enumerated().compactMap { index, item -> String? in
            var itemSections: [String] = ["## \(index + 1). \(item.preview)"]

            if !item.text.isEmpty {
                itemSections.append("### Text\n\n\(item.text)")
            }

            if !item.answer.isEmpty {
                itemSections.append("### Answer\n\n\(item.answer)")
            }

            guard itemSections.count > 1 else { return nil }
            return itemSections.joined(separator: "\n\n")
        }

        guard !sections.isEmpty else { return nil }

        return ResultExportDocument(
            title: "Save Recent Items",
            fileName: "fluid-reader-recent-items.md",
            allowedFileTypes: ["md"],
            contents: (["# Fluid Reader Recent Items"] + sections).joined(separator: "\n\n")
        )
    }

    static func snippetsDocument(_ items: [ReaderSnippetItem]) -> ResultExportDocument? {
        guard !items.isEmpty else { return nil }

        let sections = items.enumerated().map { index, item in
            "## \(index + 1). \(item.preview)\n\n\(item.text)"
        }

        return ResultExportDocument(
            title: "Save Snippets",
            fileName: "fluid-reader-snippets.md",
            allowedFileTypes: ["md"],
            contents: (["# Fluid Reader Snippets"] + sections).joined(separator: "\n\n")
        )
    }

    static func quickLinksDocument(_ items: [QuickLinkItem]) -> ResultExportDocument? {
        guard !items.isEmpty else { return nil }

        let sections = items.enumerated().map { index, item in
            "## \(index + 1). \(item.preview)\n\n[\(escapeMarkdownLinkTitle(item.title))](\(item.urlString))"
        }

        return ResultExportDocument(
            title: "Save Quick Links",
            fileName: "fluid-reader-quick-links.md",
            allowedFileTypes: ["md"],
            contents: (["# Fluid Reader Quick Links"] + sections).joined(separator: "\n\n")
        )
    }

    static func clipboardHistoryDocument(_ items: [ClipboardHistoryItem]) -> ResultExportDocument? {
        guard !items.isEmpty else { return nil }

        let sections = items.enumerated().map { index, item in
            "## \(index + 1). \(item.preview)\n\n\(item.text)"
        }

        return ResultExportDocument(
            title: "Save Clipboard History",
            fileName: "fluid-reader-clipboard-history.md",
            allowedFileTypes: ["md"],
            contents: (["# Fluid Reader Clipboard History"] + sections).joined(separator: "\n\n")
        )
    }

    static func fileName(from text: String, fallback: String) -> String {
        let cleanText = clean(text)
            .lowercased()
            .replacingOccurrences(of: "\n", with: " ")

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -_"))
        let filtered = cleanText.unicodeScalars.map { scalar in
            allowedCharacters.contains(scalar) ? Character(scalar) : "-"
        }

        let collapsed = String(filtered)
            .split(whereSeparator: { $0.isWhitespace || $0 == "-" || $0 == "_" })
            .prefix(8)
            .joined(separator: "-")

        guard !collapsed.isEmpty else { return fallback }
        return String(collapsed.prefix(48))
    }

    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func escapeMarkdownLinkTitle(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "[", with: "\\[")
            .replacingOccurrences(of: "]", with: "\\]")
    }

    private static func codeFence(for text: String) -> String {
        var longestRun = 0
        var currentRun = 0

        for character in text {
            if character == "`" {
                currentRun += 1
                longestRun = max(longestRun, currentRun)
            } else {
                currentRun = 0
            }
        }

        return String(repeating: "`", count: max(3, longestRun + 1))
    }
}

struct ImageExportDocument: Equatable {
    let title: String
    let fileName: String
    let allowedFileTypes: [String]
    let data: Data

    static func pngDocument(data: Data?, fileNamePrefix: String = "fluid-reader-image") -> ImageExportDocument? {
        guard let data, !data.isEmpty else { return nil }

        return ImageExportDocument(
            title: "Save Image",
            fileName: "\(ResultExportDocument.fileName(from: fileNamePrefix, fallback: "fluid-reader-image")).png",
            allowedFileTypes: ["png"],
            data: data
        )
    }
}
