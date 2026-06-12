import Foundation

enum ClipboardUtility {
    static func uuidString(_ uuid: UUID = UUID()) -> String {
        uuid.uuidString.lowercased()
    }

    static func isoTimestamp(_ date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func localISOTimestamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        formattedDate(date, timeZone: timeZone, format: "yyyy-MM-dd'T'HH:mm:ssXXXXX")
    }

    static func dateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        formattedDate(date, timeZone: timeZone, format: "yyyy-MM-dd")
    }

    static func dateTimeStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        formattedDate(date, timeZone: timeZone, format: "yyyy-MM-dd-HHmm")
    }

    static func utcDateTimeStamp(_ date: Date = Date()) -> String {
        dateTimeStamp(date, timeZone: TimeZone(secondsFromGMT: 0) ?? .current)
    }

    static func relativeDateStamp(days: Int, from date: Date = Date(), timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let targetDate = calendar.date(byAdding: .day, value: days, to: date) ?? date
        return dateStamp(targetDate, timeZone: timeZone)
    }

    static func weekStartDateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        weekDateStamp(date, timeZone: timeZone, offsetFromMonday: 0)
    }

    static func weekEndDateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        weekDateStamp(date, timeZone: timeZone, offsetFromMonday: 6)
    }

    private static func weekDateStamp(_ date: Date, timeZone: TimeZone, offsetFromMonday: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let weekday = calendar.component(.weekday, from: date)
        let daysSinceMonday = (weekday + 5) % 7
        let targetDate = calendar.date(byAdding: .day, value: offsetFromMonday - daysSinceMonday, to: date) ?? date
        return dateStamp(targetDate, timeZone: timeZone)
    }

    static func monthStartDateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        "\(dateStamp(date, timeZone: timeZone).prefix(8))01"
    }

    static func monthEndDateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let dayCount = calendar.range(of: .day, in: .month, for: date)?.count ?? 31
        return "\(dateStamp(date, timeZone: timeZone).prefix(8))\(dayCount)"
    }

    static func quarterStartDateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        quarterDateStamp(date, timeZone: timeZone, end: false)
    }

    static func quarterEndDateStamp(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        quarterDateStamp(date, timeZone: timeZone, end: true)
    }

    private static func quarterDateStamp(_ date: Date, timeZone: TimeZone, end: Bool) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let index = (calendar.component(.month, from: date) - 1) / 3
        let month = String(format: "%02d", index * 3 + (end ? 3 : 1))
        let day = end ? (index == 0 || index == 3 ? "31" : "30") : "01"
        return "\(dateStamp(date, timeZone: timeZone).prefix(5))\(month)-\(day)"
    }

    private static func formattedDate(_ date: Date, timeZone: TimeZone, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func unixTimestamp(_ date: Date = Date()) -> String {
        String(Int(date.timeIntervalSince1970.rounded(.down)))
    }

    static func timeZoneSummary(_ timeZone: TimeZone = .current) -> String {
        "\(timeZone.identifier) \(timeZoneOffset(timeZone))"
    }

    static func timeZoneOffset(_ timeZone: TimeZone = .current) -> String {
        let minutes = timeZone.secondsFromGMT() / 60
        let sign = minutes < 0 ? "-" : "+"
        let absoluteMinutes = abs(minutes)
        return "UTC\(sign)\(String(format: "%02d:%02d", absoluteMinutes / 60, absoluteMinutes % 60))"
    }

    static func urlEncode(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return cleanText.addingPercentEncoding(withAllowedCharacters: allowed)
    }

    static func urlDecode(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }
        return cleanText.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }

    static func cleanURL(_ text: String) -> String? {
        var candidate = clean(text)
        guard !candidate.isEmpty,
              candidate.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return nil
        }

        let lowercased = candidate.lowercased()
        guard !lowercased.hasPrefix("mailto:") else { return nil }
        if !lowercased.contains("://"), candidate.contains(".") {
            candidate = "https://\(candidate)"
        }

        guard var components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host,
              !host.isEmpty else {
            return nil
        }

        components.scheme = scheme
        components.queryItems = components.queryItems?.filter { item in
            !Self.trackingQueryNames.contains(item.name.lowercased())
        }
        if components.queryItems?.isEmpty == true {
            components.queryItems = nil
        }

        return components.url?.absoluteString
    }

    static func extractURLs(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty, let regex = urlCandidateRegex else { return nil }

        var seen = Set<String>()
        var urls: [String] = []

        let range = NSRange(cleanText.startIndex..<cleanText.endIndex, in: cleanText)
        for match in regex.matches(in: cleanText, range: range) {
            guard let candidateRange = Range(match.range, in: cleanText),
                  let url = cleanURL(trimURLWrapper(String(cleanText[candidateRange]))),
                  seen.insert(url).inserted else {
                continue
            }
            urls.append(url)
        }

        return urls.isEmpty ? nil : urls.joined(separator: "\n")
    }

    static func extractDomains(_ text: String) -> String? {
        guard let urls = extractURLs(text) else { return nil }

        var seen = Set<String>()
        var domains: [String] = []

        for url in urls.components(separatedBy: .newlines) {
            guard let host = URLComponents(string: url)?.host?.lowercased(),
                  seen.insert(host).inserted else {
                continue
            }
            domains.append(host)
        }

        return domains.isEmpty ? nil : domains.joined(separator: "\n")
    }

    static func extractEmails(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty, let regex = emailCandidateRegex else { return nil }

        var seen = Set<String>()
        var emails: [String] = []

        let range = NSRange(cleanText.startIndex..<cleanText.endIndex, in: cleanText)
        for match in regex.matches(in: cleanText, range: range) {
            guard let candidateRange = Range(match.range, in: cleanText) else { continue }

            let email = String(cleanText[candidateRange]).lowercased()
            guard seen.insert(email).inserted else { continue }
            emails.append(email)
        }

        return emails.isEmpty ? nil : emails.joined(separator: "\n")
    }

    static func base64Encode(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty, let data = cleanText.data(using: .utf8) else { return nil }
        return data.base64EncodedString()
    }

    static func base64Decode(_ text: String) -> String? {
        let cleanText = clean(text)
            .filter { !$0.isWhitespace }
        guard !cleanText.isEmpty,
              let data = Data(base64Encoded: String(cleanText)),
              let decoded = String(data: data, encoding: .utf8),
              !decoded.isEmpty else {
            return nil
        }
        return decoded
    }

    static func prettyJSON(_ text: String) -> String? {
        jsonString(text, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }

    static func minifyJSON(_ text: String) -> String? {
        jsonString(text, options: [.sortedKeys, .withoutEscapingSlashes])
    }

    private static func jsonString(_ text: String, options: JSONSerialization.WritingOptions) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty, let data = cleanText.data(using: .utf8) else { return nil }

        guard let object = try? JSONSerialization.jsonObject(with: data),
              JSONSerialization.isValidJSONObject(object),
              let output = try? JSONSerialization.data(
                withJSONObject: object,
                options: options
              ) else {
            return nil
        }

        return String(data: output, encoding: .utf8)
    }

    static func slugify(_ text: String) -> String? {
        let foldedText = clean(text)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        var pieces: [String] = []
        var current = ""

        for character in foldedText {
            if character.isLetter || character.isNumber {
                current.append(character)
            } else if !current.isEmpty {
                pieces.append(current)
                current = ""
            }
        }

        if !current.isEmpty {
            pieces.append(current)
        }

        let slug = pieces.joined(separator: "-")
        return slug.isEmpty ? nil : slug
    }

    static func snakeCasedText(_ text: String) -> String? {
        slugify(text)?.replacingOccurrences(of: "-", with: "_")
    }

    static func constantCasedText(_ text: String) -> String? {
        snakeCasedText(text)?.uppercased()
    }

    static func camelCasedText(_ text: String) -> String? {
        guard let slug = slugify(text) else { return nil }
        let parts = slug.split(separator: "-")
        guard let first = parts.first else { return nil }

        return ([String(first)] + parts.dropFirst().map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }).joined()
    }

    static func pascalCasedText(_ text: String) -> String? {
        guard let camel = camelCasedText(text), let first = camel.first else { return nil }
        return first.uppercased() + camel.dropFirst()
    }

    static func uppercasedText(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }
        return cleanText.uppercased()
    }

    static func lowercasedText(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }
        return cleanText.lowercased()
    }

    static func titleCasedText(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }
        return cleanText.lowercased().localizedCapitalized
    }

    static func singleSpacedText(_ text: String) -> String? {
        let words = text.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return nil }
        return words.joined(separator: " ")
    }

    static func stripANSI(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        var output = ""
        output.reserveCapacity(cleanText.count)
        var iterator = cleanText.unicodeScalars.makeIterator()

        while let scalar = iterator.next() {
            guard scalar.value == 27 else {
                output.unicodeScalars.append(scalar)
                continue
            }

            guard let bracket = iterator.next() else {
                output.unicodeScalars.append(scalar)
                continue
            }
            guard bracket.value == 91 else {
                output.unicodeScalars.append(scalar)
                output.unicodeScalars.append(bracket)
                continue
            }

            while let next = iterator.next() {
                if (64...126).contains(next.value) {
                    break
                }
            }
        }

        let cleanOutput = clean(output)
        return cleanOutput.isEmpty ? nil : cleanOutput
    }

    static func trimmedLines(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }
        return lines.joined(separator: "\n")
    }

    static func joinedLines(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }
        return lines.joined(separator: " ")
    }

    static func reversedLines(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }
        return lines.reversed().joined(separator: "\n")
    }

    static func sortedLines(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }
        return lines.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .joined(separator: "\n")
    }

    static func uniqueLines(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }

        var seen = Set<String>()
        let unique = lines.filter { line in
            seen.insert(line).inserted
        }
        return unique.joined(separator: "\n")
    }

    static func markdownChecklist(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }

        return lines
            .map { "- [ ] \($0)" }
            .joined(separator: "\n")
    }

    static func markdownBullets(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }

        return lines
            .map { "- \($0)" }
            .joined(separator: "\n")
    }

    static func markdownNumberedList(_ text: String) -> String? {
        let lines = cleanLines(text)
        guard !lines.isEmpty else { return nil }

        return lines
            .enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n")
    }

    static func markdownTable(_ text: String) -> String? {
        guard let rows = delimitedRows(text), rows.count >= 2 else { return nil }

        let divider = Array(repeating: "---", count: rows[0].count)
        return ([rows[0].map(markdownTableCell), divider] + rows.dropFirst().map { $0.map(markdownTableCell) })
            .map(markdownTableRow)
            .joined(separator: "\n")
    }

    static func cleanCSV(_ text: String) -> String? {
        guard let rows = delimitedRows(text) else { return nil }
        return rows
            .map { $0.map(csvCell).joined(separator: ",") }
            .joined(separator: "\n")
    }

    static func textStats(_ text: String) -> String? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        let lineCount = cleanText.components(separatedBy: .newlines).count
        let wordCount = cleanText.split(whereSeparator: \.isWhitespace).count
        let characterCount = cleanText.count

        return [
            countText(lineCount, singular: "line", plural: "lines"),
            countText(wordCount, singular: "word", plural: "words"),
            countText(characterCount, singular: "character", plural: "characters")
        ].joined(separator: ", ")
    }

    private static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func trimURLWrapper(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: "<>()[]{}\"'`.,;:!?"))
    }

    private static func cleanLines(_ text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { clean($0) }
            .filter { !$0.isEmpty }
    }

    private static func trimBlankEdges(_ lines: [String]) -> [String] {
        guard let firstIndex = lines.firstIndex(where: { !$0.isEmpty }),
              let lastIndex = lines.lastIndex(where: { !$0.isEmpty }) else {
            return []
        }
        return Array(lines[firstIndex...lastIndex])
    }

    private static func countText(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private static func delimitedRows(_ text: String) -> [[String]]? {
        let lines = cleanLines(text)
        guard let firstLine = lines.first else { return nil }

        let delimiter = firstLine.contains("\t") ? "\t" : ","
        guard firstLine.contains(delimiter) else { return nil }

        let rows = lines.map {
            $0.components(separatedBy: delimiter).map { clean($0) }
        }
        guard let columnCount = rows.first?.count,
              columnCount >= 2,
              rows.allSatisfy({ $0.count == columnCount }) else {
            return nil
        }

        return rows
    }

    private static func markdownTableCell(_ text: String) -> String {
        text.replacingOccurrences(of: "|", with: "\\|")
    }

    private static func markdownTableRow(_ cells: [String]) -> String {
        "| \(cells.joined(separator: " | ")) |"
    }

    private static func csvCell(_ text: String) -> String {
        guard text.contains(",") || text.contains("\"") else { return text }
        return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static let trackingQueryNames: Set<String> = [
        "fbclid",
        "gclid",
        "igshid",
        "mc_cid",
        "mc_eid",
        "msclkid",
        "ref",
        "spm",
        "utm_campaign",
        "utm_content",
        "utm_medium",
        "utm_source",
        "utm_term"
    ]

    private static let urlCandidateRegex = try? NSRegularExpression(
        pattern: "(https?://[^\\s<>()\\[\\]{}\"'`]+|(?<![@\\w.-])(?:[a-z0-9-]+\\.)+[a-z]{2,}(?:/[^\\s<>()\\[\\]{}\"'`]*)?)",
        options: [.caseInsensitive]
    )

    private static let emailCandidateRegex = try? NSRegularExpression(
        pattern: "(?<![a-z0-9._%+-])[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}(?![a-z0-9_%+-])",
        options: [.caseInsensitive]
    )

}
