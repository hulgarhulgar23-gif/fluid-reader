import Foundation

enum AIWorkspaceFilter: String, CaseIterable, Identifiable {
    case ready
    case builtIn
    case custom
    case scripts
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ready:
            return "Ready"
        case .builtIn:
            return "Built-In"
        case .custom:
            return "Custom"
        case .scripts:
            return "Scripts"
        case .all:
            return "All"
        }
    }
}

struct AIWorkspaceSummary: Equatable {
    let hubActionCount: Int
    let builtInPromptCount: Int
    let customPromptCount: Int
    let scriptCommandCount: Int
    let readyActionCount: Int
    let totalActionCount: Int
    let llmReady: Bool

    var promptCommandCount: Int {
        builtInPromptCount + customPromptCount
    }

    var llmStatusTitle: String {
        llmReady ? "Ready" : "Needs LLM"
    }

    var askAnythingSubtitle: String {
        if llmReady {
            let commandNoun = promptCommandCount == 1 ? "command" : "commands"
            return "Ask about current, selected, clipboard, or picked text · \(promptCommandCount) AI \(commandNoun) ready"
        }
        return "Ask about current, selected, clipboard, or picked text"
    }

    var bestLocalActionSubtitle: String {
        guard promptCommandCount > 0 || scriptCommandCount > 0 else {
            return "Route a natural-language request to local AI commands or scripts"
        }

        guard promptCommandCount > 0 else {
            return "Route a natural-language request to local AI commands or scripts"
        }

        let commandNoun = promptCommandCount == 1 ? "command" : "commands"
        return "Route across \(promptCommandCount) AI \(commandNoun) and local scripts"
    }

    var settingsSubtitle: String {
        let promptNoun = promptCommandCount == 1 ? "AI command" : "AI commands"
        let scriptNoun = scriptCommandCount == 1 ? "script" : "scripts"
        return "Manage \(promptCommandCount) \(promptNoun) and \(scriptCommandCount) local \(scriptNoun)"
    }
}

struct AIWorkspaceCatalog {
    static let hubActionIDs: Set<String> = [
        "ask-anything",
        "run-best-local-action"
    ]
    fileprivate static let promptActionPrefix = "prompt-"
    fileprivate static let customPromptActionPrefix = "prompt-custom"

    private let actions: [CommandPaletteAction]
    private let summaryValue: AIWorkspaceSummary

    init(
        actions: [CommandPaletteAction],
        llmReady: Bool
    ) {
        var seenActionIDs = Set<String>()
        let dedupedRelevantActions = actions.filter { action in
            guard Self.isRelevant(action) else { return false }
            return seenActionIDs.insert(action.id).inserted
        }

        self.actions = dedupedRelevantActions

        let builtInPromptCount = dedupedRelevantActions.filter { Self.isBuiltInPromptAction($0) }.count
        let customPromptCount = dedupedRelevantActions.filter { Self.isCustomPromptAction($0) }.count
        let scriptCommandCount = dedupedRelevantActions.filter { Self.isScriptAction($0) }.count
        let readyActionCount = dedupedRelevantActions.filter(\.isEnabled).count
        let hubActionCount = actions.filter { Self.hubActionIDs.contains($0.id) }.count

        summaryValue = AIWorkspaceSummary(
            hubActionCount: hubActionCount,
            builtInPromptCount: builtInPromptCount,
            customPromptCount: customPromptCount,
            scriptCommandCount: scriptCommandCount,
            readyActionCount: readyActionCount,
            totalActionCount: dedupedRelevantActions.count,
            llmReady: llmReady
        )
    }

    static func summary(
        promptTemplates: [PromptTemplate],
        scriptCommands: [ScriptCommandItem],
        llmEnabled: Bool,
        apiKey: String,
        hubActionCount: Int = hubActionIDs.count
    ) -> AIWorkspaceSummary {
        let customPromptCount = promptTemplates.filter { template in
            template.id.hasPrefix("custom")
        }.count
        let builtInPromptCount = max(0, promptTemplates.count - customPromptCount)
        let readyPromptCount = llmEnabled && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? promptTemplates.count
            : 0

        return AIWorkspaceSummary(
            hubActionCount: hubActionCount,
            builtInPromptCount: builtInPromptCount,
            customPromptCount: customPromptCount,
            scriptCommandCount: scriptCommands.count,
            readyActionCount: readyPromptCount + scriptCommands.count,
            totalActionCount: promptTemplates.count + scriptCommands.count,
            llmReady: llmEnabled && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        )
    }

    var summary: AIWorkspaceSummary {
        summaryValue
    }

    func count(for filter: AIWorkspaceFilter) -> Int {
        filteredActions(for: filter).count
    }

    func rows(
        for filter: AIWorkspaceFilter,
        query: String,
        emptyQueryLimit: Int? = nil
    ) -> [CommandPaletteAction] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredActions = filteredActions(for: filter)

        guard !cleanQuery.isEmpty else {
            guard let emptyQueryLimit,
                  emptyQueryLimit > 0,
                  filteredActions.count > emptyQueryLimit else {
                return filteredActions
            }

            return Array(filteredActions.prefix(emptyQueryLimit))
        }

        return Array(
            CommandPaletteAction
                .filter(filteredActions, query: cleanQuery)
                .prefix(14)
        )
    }

    func shouldShowBrowseLimitHint(
        for filter: AIWorkspaceFilter,
        query: String,
        emptyQueryLimit: Int
    ) -> Bool {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.isEmpty else { return false }
        guard emptyQueryLimit > 0 else { return false }
        return filteredActions(for: filter).count > emptyQueryLimit
    }

    func metadataTitles(for action: CommandPaletteAction) -> [String] {
        var titles: [String] = []

        if Self.isBuiltInPromptAction(action) {
            titles.append("Built-In")
        } else if Self.isCustomPromptAction(action) {
            titles.append("Custom")
        } else if Self.isScriptAction(action) {
            titles.append("Script")
        }

        if action.isEnabled {
            titles.append("Ready")
        } else if Self.isPromptAction(action) {
            titles.append("Needs LLM")
        } else if Self.isScriptAction(action) {
            titles.append("Needs Fix")
        }

        return titles
    }

    fileprivate static func isRelevant(_ action: CommandPaletteAction) -> Bool {
        isPromptAction(action) || isScriptAction(action)
    }

    fileprivate static func isPromptAction(_ action: CommandPaletteAction) -> Bool {
        action.id.hasPrefix(promptActionPrefix)
    }

    fileprivate static func isCustomPromptAction(_ action: CommandPaletteAction) -> Bool {
        action.id.hasPrefix(customPromptActionPrefix)
    }

    fileprivate static func isBuiltInPromptAction(_ action: CommandPaletteAction) -> Bool {
        isPromptAction(action) && !isCustomPromptAction(action)
    }

    fileprivate static func isScriptAction(_ action: CommandPaletteAction) -> Bool {
        action.sourceKind == .script
    }

    private func filteredActions(
        for filter: AIWorkspaceFilter
    ) -> [CommandPaletteAction] {
        actions.filter { action in
            filter.matches(action)
        }
    }
}

private extension AIWorkspaceFilter {
    func matches(_ action: CommandPaletteAction) -> Bool {
        switch self {
        case .ready:
            return action.isEnabled
        case .builtIn:
            return AIWorkspaceCatalog.isBuiltInPromptAction(action)
        case .custom:
            return AIWorkspaceCatalog.isCustomPromptAction(action)
        case .scripts:
            return AIWorkspaceCatalog.isScriptAction(action)
        case .all:
            return true
        }
    }
}
