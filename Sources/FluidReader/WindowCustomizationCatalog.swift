import Foundation

enum WindowCustomizationFilter: String, CaseIterable, Identifiable {
    case customized
    case cycle
    case layouts
    case profiles
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .customized:
            return "Customized"
        case .cycle:
            return "Cycle"
        case .layouts:
            return "Layouts"
        case .profiles:
            return "Profiles"
        case .all:
            return "All"
        }
    }
}

struct WindowCustomizationSummary: Equatable {
    let activeProfileTitle: String
    let gapPoints: Int
    let activeCycleCommandCount: Int
    let customizedHotKeyCount: Int
    let totalActionCount: Int

    var gapTitle: String {
        gapPoints == 0 ? "Off" : "\(gapPoints) pt"
    }
}

struct WindowCustomizationCatalog {
    fileprivate static let settingsActionID = "window-settings"
    fileprivate static let profileActionIDs = Set(FrontWindowCycleProfile.allCases.map(\.actionID))
    fileprivate static let layoutActionIDs = Set(FrontWindowLayoutCommand.cycleEligibleCommands.map(\.actionID))
    fileprivate static let cycleUtilityActionIDs: Set<String> = [
        FrontWindowLayoutCommand.cycleLayout.actionID,
        FrontWindowLayoutCommand.cycleLayoutBackward.actionID,
        FrontWindowLayoutCommand.undoLastMove.actionID,
        FrontWindowLayoutCommand.moveToNextDisplay.actionID,
        FrontWindowLayoutCommand.moveToPreviousDisplay.actionID,
        settingsActionID
    ]

    private let actions: [CommandPaletteAction]
    private let currentActionIDs: Set<String>
    private let hotKeyActionIDs: Set<String>
    private let activeCycleActionIDs: Set<String>
    private let activeProfileActionID: String
    private let summaryValue: WindowCustomizationSummary

    init(
        actions: [CommandPaletteAction],
        hotKeyActionIDs: Set<String>,
        activeProfile: FrontWindowCycleProfile,
        activeCycleCommands: [FrontWindowLayoutCommand],
        gapPoints: Int
    ) {
        var seenActionIDs = Set<String>()
        let dedupedActions = actions.filter { action in
            seenActionIDs.insert(action.id).inserted
        }

        self.actions = dedupedActions
        currentActionIDs = Set(dedupedActions.map(\.id))
        self.hotKeyActionIDs = hotKeyActionIDs
        activeCycleActionIDs = Set(activeCycleCommands.map(\.actionID))
        activeProfileActionID = activeProfile.actionID
        summaryValue = WindowCustomizationSummary(
            activeProfileTitle: activeProfile.title,
            gapPoints: max(0, gapPoints),
            activeCycleCommandCount: activeCycleCommands.count,
            customizedHotKeyCount: hotKeyActionIDs.intersection(currentActionIDs).count,
            totalActionCount: dedupedActions.count
        )
    }

    var summary: WindowCustomizationSummary {
        summaryValue
    }

    func count(for filter: WindowCustomizationFilter) -> Int {
        filteredActions(for: filter).count
    }

    func rows(
        for filter: WindowCustomizationFilter,
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
        for filter: WindowCustomizationFilter,
        query: String,
        emptyQueryLimit: Int
    ) -> Bool {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.isEmpty else { return false }
        guard filter != .customized else { return false }
        guard emptyQueryLimit > 0 else { return false }
        return filteredActions(for: filter).count > emptyQueryLimit
    }

    func isActiveCycleAction(_ actionID: String) -> Bool {
        activeCycleActionIDs.contains(actionID)
    }

    func isProfileAction(_ actionID: String) -> Bool {
        Self.profileActionIDs.contains(actionID)
    }

    func isLayoutAction(_ actionID: String) -> Bool {
        Self.layoutActionIDs.contains(actionID)
    }

    func isCycleUtilityAction(_ actionID: String) -> Bool {
        Self.cycleUtilityActionIDs.contains(actionID)
    }

    func isActiveProfileAction(_ actionID: String) -> Bool {
        activeProfileActionID == actionID
    }

    private func filteredActions(
        for filter: WindowCustomizationFilter
    ) -> [CommandPaletteAction] {
        actions.filter { action in
            filter.matches(
                actionID: action.id,
                hotKeyActionIDs: hotKeyActionIDs.intersection(currentActionIDs),
                activeCycleActionIDs: activeCycleActionIDs
            )
        }
    }
}

private extension WindowCustomizationFilter {
    func matches(
        actionID: String,
        hotKeyActionIDs: Set<String>,
        activeCycleActionIDs: Set<String>
    ) -> Bool {
        switch self {
        case .customized:
            return hotKeyActionIDs.contains(actionID)
        case .cycle:
            return activeCycleActionIDs.contains(actionID)
                || WindowCustomizationCatalog
                    .cycleUtilityActionIDs
                    .contains(actionID)
        case .layouts:
            return WindowCustomizationCatalog.layoutActionIDs.contains(actionID)
        case .profiles:
            return WindowCustomizationCatalog.profileActionIDs.contains(actionID)
        case .all:
            return true
        }
    }
}
