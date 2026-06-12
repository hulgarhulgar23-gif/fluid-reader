import Foundation

struct CustomPromptInput: Equatable {
    let id: String
    let title: String
    let prompt: String
}

struct PromptTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    let prompt: String
    let systemImage: String
    let keywords: [String]

    static let builtIn: [PromptTemplate] = [
        PromptTemplate(
            id: "summarize",
            title: "Summary",
            prompt: "Summarize this in a short, clear way.",
            systemImage: "text.badge.checkmark",
            keywords: ["summary", "summarize", "short", "tldr", "recap"]
        ),
        PromptTemplate(
            id: "simple",
            title: "Simple",
            prompt: "Explain this with simple words. Keep it short.",
            systemImage: "lightbulb",
            keywords: ["simple", "explain", "easy", "eli5"]
        ),
        PromptTemplate(
            id: "notes",
            title: "Notes",
            prompt: "Turn this into short bullet notes.",
            systemImage: "list.bullet.rectangle",
            keywords: ["notes", "bullets", "meeting", "minutes"]
        ),
        PromptTemplate(
            id: "actions",
            title: "Action Items",
            prompt: "Find action items. Keep each one short and clear.",
            systemImage: "checklist",
            keywords: ["action", "todo", "tasks", "next", "steps", "followup"]
        ),
        PromptTemplate(
            id: "rewrite",
            title: "Rewrite",
            prompt: "Rewrite this in clear, polished English. Keep the meaning.",
            systemImage: "pencil.line",
            keywords: ["rewrite", "polish", "edit", "writing"]
        ),
        PromptTemplate(
            id: "reply",
            title: "Reply",
            prompt: "Draft a short, clear reply. Keep it helpful and ready to send.",
            systemImage: "envelope",
            keywords: ["reply", "email", "message", "draft", "respond"]
        ),
        PromptTemplate(
            id: "launch-post",
            title: "Launch",
            prompt: "Draft a short launch post with hook, proof, and CTA.",
            systemImage: "megaphone.fill",
            keywords: ["launch", "announcement", "post", "gtm"]
        ),
        PromptTemplate(
            id: "english",
            title: "English",
            prompt: "Translate this to clear English.",
            systemImage: "globe",
            keywords: ["translate", "english", "language"]
        ),
        PromptTemplate(
            id: "mongolian",
            title: "Mongolian",
            prompt: "Translate this to clear Mongolian. Keep the meaning.",
            systemImage: "globe",
            keywords: ["translate", "mongolian", "mongol", "mn", "language"]
        ),
        PromptTemplate(
            id: "code-help",
            title: "Code Help",
            prompt: "Explain this code or error in simple words. Give the next step.",
            systemImage: "chevron.left.forwardslash.chevron.right",
            keywords: ["code", "error", "debug", "programming", "fix", "bug", "stacktrace"]
        ),
        PromptTemplate(
            id: "questions",
            title: "Questions",
            prompt: "List the main questions I should ask about this.",
            systemImage: "questionmark.bubble",
            keywords: ["questions", "ask", "review"]
        )
    ]

    static func all(customTitle: String, customPrompt: String) -> [PromptTemplate] {
        all(customPrompts: [
            CustomPromptInput(id: "custom", title: customTitle, prompt: customPrompt)
        ])
    }

    static func all(customPrompts: [CustomPromptInput]) -> [PromptTemplate] {
        builtIn + customPrompts.compactMap(custom)
    }

    static func custom(customTitle: String, customPrompt: String) -> PromptTemplate? {
        custom(CustomPromptInput(id: "custom", title: customTitle, prompt: customPrompt))
    }

    static func custom(_ input: CustomPromptInput) -> PromptTemplate? {
        let prompt = clean(input.prompt)
        guard !prompt.isEmpty else { return nil }

        return PromptTemplate(
            id: cleanID(input.id),
            title: clean(input.title).isEmpty ? "Custom" : clean(input.title),
            prompt: prompt,
            systemImage: "wand.and.stars",
            keywords: ["custom", "prompt"]
        )
    }

    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanID(_ value: String) -> String {
        let cleanValue = clean(value)
        return cleanValue.isEmpty ? "custom" : cleanValue
    }
}
