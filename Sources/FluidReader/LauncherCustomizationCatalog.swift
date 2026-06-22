import Foundation

enum LauncherCustomizationFilter: String, CaseIterable, Identifiable {
    case customized
    case platform
    case ai
    case window
    case scripts
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .customized:
            return "Customized"
        case .platform:
            return "Platform"
        case .ai:
            return "AI"
        case .window:
            return "Windows"
        case .scripts:
            return "Scripts"
        case .all:
            return "All"
        }
    }
}

struct LauncherCustomizationSummary: Equatable {
    let customizedShortcutCount: Int
    let aliasedCommandCount: Int
    let hotKeyCommandCount: Int
    let customizedCommandCount: Int
    let indexedRootCount: Int
    let totalCommandCount: Int

    var hasCustomizedCommands: Bool {
        customizedCommandCount > 0
    }

    var hasAnyCustomization: Bool {
        customizedShortcutCount > 0 || customizedCommandCount > 0
    }
}

struct LauncherCustomizationCatalog {
    private let actions: [CommandPaletteAction]
    private let currentActionIDs: Set<String>
    private let aliasActionIDs: Set<String>
    private let hotKeyActionIDs: Set<String>
    private let dedicatedShortcutIDs: Set<String>
    private let indexedRootCount: Int

    init(
        actions: [CommandPaletteAction],
        aliasActionIDs: Set<String>,
        hotKeyActionIDs: Set<String>,
        dedicatedShortcutIDs: Set<String> = Set(LauncherHotKeyCatalog.all.map(\.id)),
        indexedRootCount: Int
    ) {
        var seenActionIDs = Set<String>()
        let dedupedActions = actions.filter { action in
            seenActionIDs.insert(action.id).inserted
        }

        self.actions = dedupedActions
        currentActionIDs = Set(dedupedActions.map(\.id))
        self.aliasActionIDs = aliasActionIDs
        self.hotKeyActionIDs = hotKeyActionIDs
        self.dedicatedShortcutIDs = dedicatedShortcutIDs
        self.indexedRootCount = max(0, indexedRootCount)
    }

    var summary: LauncherCustomizationSummary {
        let customizedShortcutCount = hotKeyActionIDs.intersection(dedicatedShortcutIDs).count
        let aliasedCommandCount = currentAliasedActionIDs.count
        let hotKeyCommandCount = currentCommandHotKeyActionIDs.count
        let customizedCommandCount = customizedCommandActionIDs.count

        return LauncherCustomizationSummary(
            customizedShortcutCount: customizedShortcutCount,
            aliasedCommandCount: aliasedCommandCount,
            hotKeyCommandCount: hotKeyCommandCount,
            customizedCommandCount: customizedCommandCount,
            indexedRootCount: indexedRootCount,
            totalCommandCount: actions.count
        )
    }

    func count(for filter: LauncherCustomizationFilter) -> Int {
        filteredActions(for: filter).count
    }

    func rows(
        for filter: LauncherCustomizationFilter,
        query: String,
        emptyQueryLimit: Int? = nil
    ) -> [CommandPaletteAction] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredActions = filteredActions(for: filter)

        guard !cleanQuery.isEmpty else {
            let browseActions: [CommandPaletteAction]
            if filter == .customized {
                browseActions = filteredActions.sorted {
                    $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
            } else {
                browseActions = filteredActions
            }

            guard let emptyQueryLimit,
                  filter != .customized,
                  emptyQueryLimit > 0,
                  browseActions.count > emptyQueryLimit else {
                return browseActions
            }

            return Array(browseActions.prefix(emptyQueryLimit))
        }

        return Array(
            CommandPaletteAction
                .filter(filteredActions, query: cleanQuery)
                .prefix(14)
        )
    }

    func shouldShowBrowseLimitHint(
        for filter: LauncherCustomizationFilter,
        query: String,
        emptyQueryLimit: Int
    ) -> Bool {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.isEmpty else { return false }
        guard filter != .customized else { return false }
        guard emptyQueryLimit > 0 else { return false }
        return filteredActions(for: filter).count > emptyQueryLimit
    }

    private var currentAliasedActionIDs: Set<String> {
        aliasActionIDs.intersection(currentActionIDs)
    }

    private var currentCommandHotKeyActionIDs: Set<String> {
        hotKeyActionIDs
            .subtracting(dedicatedShortcutIDs)
            .intersection(currentActionIDs)
    }

    private var customizedCommandActionIDs: Set<String> {
        currentAliasedActionIDs.union(currentCommandHotKeyActionIDs)
    }

    private func filteredActions(
        for filter: LauncherCustomizationFilter
    ) -> [CommandPaletteAction] {
        actions.filter { action in
            filter.matches(action, customizedActionIDs: customizedCommandActionIDs)
        }
    }
}

private extension LauncherCustomizationFilter {
    func matches(
        _ action: CommandPaletteAction,
        customizedActionIDs: Set<String>
    ) -> Bool {
        switch self {
        case .customized:
            return customizedActionIDs.contains(action.id)
        case .platform:
            guard action.sourceKind != .script else { return false }
            switch action.resolvedGroup {
            case .core, .text, .saved, .open, .settings:
                return true
            case .ask, .window, .support:
                return false
            }
        case .ai:
            return action.resolvedGroup == .ask
        case .window:
            return action.resolvedGroup == .window
        case .scripts:
            return action.sourceKind == .script
        case .all:
            return true
        }
    }
}
