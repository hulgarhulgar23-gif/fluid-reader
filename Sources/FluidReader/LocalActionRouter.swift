import Foundation

enum LocalActionRouter {
    static let minimumScore = 18

    struct Candidate: Equatable {
        enum Kind: Equatable {
            case prompt(PromptTemplate)
            case script(ScriptCommandItem)
        }

        let id: String
        let title: String
        let subtitle: String
        let keywords: [String]
        let kind: Kind
        let isEnabled: Bool
        let disabledReason: String?
    }

    struct Route: Equatable {
        let candidate: Candidate
        let score: Int
        let matchedTerms: [String]
    }

    private struct ScoreBreakdown {
        let score: Int
        let matchedTerms: [String]
    }

    private static let stopWords: Set<String> = [
        "a", "an", "and", "at", "best", "by", "can", "command", "commands", "do",
        "for", "from", "i", "if", "in", "into", "it", "local", "me", "my", "of",
        "on", "or", "our", "please", "run", "script", "scripts", "that", "the",
        "this", "to", "with", "your"
    ]

    private static let promptIntentTokens: Set<String> = [
        "action", "actions", "answer", "ask", "bullet", "bullets", "code", "debug",
        "draft", "edit", "eli5", "english", "explain", "fix", "launch", "minutes",
        "mongolian", "note", "notes", "question", "questions", "recap", "reply",
        "rewrite", "simple", "summarize", "summary", "tldr", "translate"
    ]

    private static let scriptIntentTokens: Set<String> = [
        "automation", "automate", "build", "checklist", "deploy", "export", "format",
        "helper", "import", "lint", "publish", "refresh", "release", "reload",
        "reveal", "sync", "test"
    ]

    static func bestRoute(
        for intent: String,
        candidates: [Candidate]
    ) -> Route? {
        let cleanIntent = FreeformPrompt.clean(intent)
        let queryText = normalizedText(cleanIntent)
        let queryTokens = significantTokens(in: cleanIntent)
        let queryTokenSet = Set(queryTokens)
        let queryBigrams = Set(bigrams(queryTokens))

        guard !queryText.isEmpty, !queryTokens.isEmpty else { return nil }

        let rankedRoutes = candidates.compactMap { candidate -> Route? in
            let breakdown = score(
                candidate,
                queryText: queryText,
                queryTokenSet: queryTokenSet,
                queryBigrams: queryBigrams
            )
            guard breakdown.score >= minimumScore else { return nil }
            return Route(
                candidate: candidate,
                score: breakdown.score,
                matchedTerms: breakdown.matchedTerms
            )
        }

        return rankedRoutes.sorted { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            if lhs.candidate.isEnabled != rhs.candidate.isEnabled {
                return lhs.candidate.isEnabled && !rhs.candidate.isEnabled
            }
            let lhsTitleLength = normalizedText(lhs.candidate.title).count
            let rhsTitleLength = normalizedText(rhs.candidate.title).count
            if lhsTitleLength != rhsTitleLength {
                return lhsTitleLength < rhsTitleLength
            }
            return lhs.candidate.title.localizedCaseInsensitiveCompare(rhs.candidate.title) == .orderedAscending
        }.first
    }

    private static func score(
        _ candidate: Candidate,
        queryText: String,
        queryTokenSet: Set<String>,
        queryBigrams: Set<String>
    ) -> ScoreBreakdown {
        let titleText = normalizedText(candidate.title)
        let titleTokens = significantTokens(in: candidate.title)
        let subtitleTokens = significantTokens(in: candidate.subtitle)
        let keywordPhrases = candidate.keywords
            .map(normalizedText)
            .filter { !$0.isEmpty }
        let keywordTokens = Set(candidate.keywords.flatMap(significantTokens(in:)))
        let titleTokenSet = Set(titleTokens)
        let subtitleTokenSet = Set(subtitleTokens)
        let titleBigrams = Set(bigrams(titleTokens))
        let keywordBigrams = Set(keywordPhrases.flatMap { bigrams(tokens(inNormalized: $0)) })

        var score = 0
        var matchedTerms = Set<String>()

        if titleText == queryText {
            score += 220
            matchedTerms.insert(titleText)
        } else if titleTokens.count > 1, !titleText.isEmpty, queryText.contains(titleText) {
            score += 120
            matchedTerms.insert(titleText)
        }

        for phrase in keywordPhrases where phrase.contains(" ") && queryText.contains(phrase) {
            score += 72
            matchedTerms.insert(phrase)
        }

        for bigram in titleBigrams where queryBigrams.contains(bigram) {
            score += 28
            matchedTerms.insert(bigram.replacingOccurrences(of: "|", with: " "))
        }

        for bigram in keywordBigrams where queryBigrams.contains(bigram) {
            score += 20
            matchedTerms.insert(bigram.replacingOccurrences(of: "|", with: " "))
        }

        for token in queryTokenSet {
            if titleTokenSet.contains(token) {
                score += 18
                matchedTerms.insert(token)
            }
            if keywordTokens.contains(token) {
                score += 14
                matchedTerms.insert(token)
            }
            if subtitleTokenSet.contains(token) {
                score += 6
                matchedTerms.insert(token)
            }
        }

        if queryTokenSet.count == 1,
           let onlyToken = queryTokenSet.first,
           keywordTokens.contains(onlyToken) {
            score += 8
        }

        switch candidate.kind {
        case .prompt:
            let queryPromptSignalCount = promptIntentTokens.intersection(queryTokenSet).count
            let candidatePromptSignalCount = promptIntentTokens
                .intersection(titleTokenSet.union(keywordTokens))
                .count
            score += min(queryPromptSignalCount, candidatePromptSignalCount) * 6
        case .script:
            let queryScriptSignalCount = scriptIntentTokens.intersection(queryTokenSet).count
            let candidateScriptSignalCount = scriptIntentTokens
                .intersection(titleTokenSet.union(keywordTokens))
                .count
            score += min(queryScriptSignalCount, candidateScriptSignalCount) * 6
        }

        if !candidate.isEnabled {
            score -= 4
        }

        return ScoreBreakdown(
            score: score,
            matchedTerms: matchedTerms.sorted()
        )
    }

    private static func significantTokens(in text: String) -> [String] {
        tokens(inNormalized: normalizedText(text)).filter { token in
            guard token.count > 1 else { return false }
            return !stopWords.contains(token)
        }
    }

    private static func tokens(inNormalized text: String) -> [String] {
        text
            .split(whereSeparator: \.isWhitespace)
            .map { canonicalToken(String($0)) }
            .filter { !$0.isEmpty }
    }

    private static func bigrams(_ tokens: [String]) -> [String] {
        guard tokens.count > 1 else { return [] }
        return zip(tokens, tokens.dropFirst()).map { "\($0)|\($1)" }
    }

    private static func canonicalToken(_ rawToken: String) -> String {
        let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard token.count > 2 else { return token }
        if token.hasSuffix("ies"), token.count > 4 {
            return String(token.dropLast(3)) + "y"
        }
        if token.hasSuffix("ing"), token.count > 5 {
            return String(token.dropLast(3))
        }
        if token.hasSuffix("ed"), token.count > 4 {
            return String(token.dropLast(2))
        }
        if token.hasSuffix("s"), token.count > 3 {
            return String(token.dropLast())
        }
        return token
    }

    private static func normalizedText(_ value: String) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(String(scalar)) : Character(" ")
        }
        return String(scalars)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
