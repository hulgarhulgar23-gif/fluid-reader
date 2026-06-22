import AppKit
import XCTest
@testable import FluidReader

@MainActor
final class CommandPaletteWindowTests: XCTestCase {
    func testBaseActionIDsUseBrowseActionsWhenIdle() {
        let allActions = [
            CommandPaletteAction(id: "pick-and-read", title: "Pick and Read", systemImage: "lasso", run: {}),
            CommandPaletteAction(id: "run-fame-sprint", title: "Run Fame Sprint", systemImage: "bolt.circle", run: {})
        ]
        let browseActions = [
            CommandPaletteAction(id: "pick-and-read", title: "Pick and Read", systemImage: "lasso", run: {})
        ]

        XCTAssertEqual(
            CommandPaletteWindow.baseActionIDsForSearchState(
                allActions: allActions,
                browseActions: browseActions,
                searchQuery: "   ",
                hasScopedQuery: false,
                activeGroup: nil
            ),
            ["pick-and-read"]
        )
    }

    func testBaseActionIDsUseFullActionsWhenSearching() {
        let allActions = [
            CommandPaletteAction(id: "pick-and-read", title: "Pick and Read", systemImage: "lasso", run: {}),
            CommandPaletteAction(id: "run-fame-sprint", title: "Run Fame Sprint", systemImage: "bolt.circle", run: {})
        ]
        let browseActions = [
            CommandPaletteAction(id: "pick-and-read", title: "Pick and Read", systemImage: "lasso", run: {})
        ]

        XCTAssertEqual(
            CommandPaletteWindow.baseActionIDsForSearchState(
                allActions: allActions,
                browseActions: browseActions,
                searchQuery: "sprint",
                hasScopedQuery: false,
                activeGroup: nil
            ),
            ["pick-and-read", "run-fame-sprint"]
        )
    }

    func testBaseActionIDsUseFullActionsWhenScopedWithoutQuery() {
        let allActions = [
            CommandPaletteAction(id: "pick-and-read", title: "Pick and Read", systemImage: "lasso", run: {}),
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                systemImage: "bolt.circle",
                group: .support,
                run: {}
            )
        ]
        let browseActions = [
            CommandPaletteAction(id: "pick-and-read", title: "Pick and Read", systemImage: "lasso", run: {})
        ]

        XCTAssertEqual(
            CommandPaletteWindow.baseActionIDsForSearchState(
                allActions: allActions,
                browseActions: browseActions,
                searchQuery: "",
                hasScopedQuery: true,
                activeGroup: .support
            ),
            ["pick-and-read", "run-fame-sprint"]
        )
    }

    func testLauncherHomeSectionsPreferStartAndSpaces() {
        let sections = CommandPaletteWindow.launcherHomeSections(
            availableActionIDs: [
                "pick-and-read",
                "screenshot-line",
                "ask-anything",
                "run-best-local-action",
                "open-notes-workspace",
                "open-extensions-workspace",
                "window-settings",
                "setup-checklist",
                "settings"
            ]
        )

        XCTAssertEqual(
            sections,
            [
                CommandPaletteLauncherHomeSection(
                    title: "Start",
                    actionIDs: [
                        "pick-and-read",
                        "screenshot-line",
                        "ask-anything",
                        "run-best-local-action"
                    ]
                ),
                CommandPaletteLauncherHomeSection(
                    title: "Spaces",
                    actionIDs: [
                        "open-notes-workspace",
                        "open-extensions-workspace",
                        "window-settings",
                        "setup-checklist"
                    ]
                )
            ]
        )
    }

    func testLauncherHomeUtilityActionIDsKeepManagementControlsCompact() {
        XCTAssertEqual(
            CommandPaletteWindow.launcherHomeUtilityActionIDs(
                availableActionIDs: [
                    "pick-and-read",
                    "show-reader",
                    "refresh-app-launcher",
                    "toggle-menu-bar-item",
                    "settings",
                    "copy-setup-guide"
                ]
            ),
            [
                "show-reader",
                "refresh-app-launcher",
                "toggle-menu-bar-item",
                "settings"
            ]
        )
    }

    func testNormalizedSelectionIDFallsBackToFirstAction() {
        XCTAssertEqual(
            CommandPaletteWindow.normalizedSelectionID(
                actionIDs: ["pick-and-read", "ask-anything"],
                currentID: nil
            ),
            "pick-and-read"
        )
        XCTAssertEqual(
            CommandPaletteWindow.normalizedSelectionID(
                actionIDs: ["pick-and-read", "ask-anything"],
                currentID: "ask-anything"
            ),
            "ask-anything"
        )
        XCTAssertEqual(
            CommandPaletteWindow.normalizedSelectionID(
                actionIDs: ["pick-and-read", "ask-anything"],
                currentID: "missing"
            ),
            "pick-and-read"
        )
    }

    func testShiftedSelectionIDWrapsForwardAndBackward() {
        let ids = ["pick-and-read", "ask-anything", "settings"]

        XCTAssertEqual(
            CommandPaletteWindow.shiftedSelectionID(
                actionIDs: ids,
                currentID: "settings",
                offset: 1
            ),
            "pick-and-read"
        )
        XCTAssertEqual(
            CommandPaletteWindow.shiftedSelectionID(
                actionIDs: ids,
                currentID: "pick-and-read",
                offset: -1
            ),
            "settings"
        )
    }

    func testQueryByApplyingScopePrefixesPlainSearchText() {
        XCTAssertEqual(
            CommandPaletteWindow.queryByApplyingScope(
                "app:",
                currentQuery: "Safari"
            ),
            "app: Safari"
        )
        XCTAssertEqual(
            CommandPaletteWindow.queryByApplyingScope(
                "file:",
                currentQuery: "   "
            ),
            "file: "
        )
    }

    func testQueryByApplyingScopeReplacesExistingScopeButKeepsSearchText() {
        XCTAssertEqual(
            CommandPaletteWindow.queryByApplyingScope(
                "note:",
                currentQuery: "app: Safari"
            ),
            "note: Safari"
        )
        XCTAssertEqual(
            CommandPaletteWindow.queryByApplyingScope(
                "tile:",
                currentQuery: "route: deploy preview"
            ),
            "tile: deploy preview"
        )
    }

    func testBrowseSummaryCountFormattingUsesCompactUnits() {
        XCTAssertEqual(CommandPaletteBrowseSummary.compactCountLabel(0), "0")
        XCTAssertEqual(CommandPaletteBrowseSummary.compactCountLabel(24), "24")
        XCTAssertEqual(CommandPaletteBrowseSummary.compactCountLabel(999), "999")
        XCTAssertEqual(CommandPaletteBrowseSummary.compactCountLabel(1_250), "1.3k")
        XCTAssertEqual(CommandPaletteBrowseSummary.compactCountLabel(12_400), "12k")
        XCTAssertEqual(CommandPaletteBrowseSummary.compactCountLabel(1_200_000), "1.2m")
    }

    func testCompactLayoutMetricsShrinkPaletteAndActionPanel() {
        let standard = CommandPaletteWindow.layoutMetrics(isCompact: false)
        let compact = CommandPaletteWindow.layoutMetrics(isCompact: true)

        XCTAssertLessThan(compact.preferredContentSize.width, standard.preferredContentSize.width)
        XCTAssertLessThan(compact.preferredContentSize.height, standard.preferredContentSize.height)
        XCTAssertLessThan(compact.bodyMinSize.width, standard.bodyMinSize.width)
        XCTAssertLessThan(compact.bodyMinSize.height, standard.bodyMinSize.height)
        XCTAssertLessThan(compact.actionPanelWidth, standard.actionPanelWidth)
        XCTAssertLessThan(compact.rowVerticalPadding, standard.rowVerticalPadding)
    }

    func testRefreshLayoutUsesCompactModeSetting() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        let originalCompactMode = settings.launcherCompactMode
        defer { settings.launcherCompactMode = originalCompactMode }
        settings.launcherCompactMode = false

        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] }
        )

        window.show()

        let standardMetrics = CommandPaletteWindow.layoutMetrics(isCompact: false)
        XCTAssertEqual(window.currentWindowContentSize?.width ?? 0, standardMetrics.preferredContentSize.width, accuracy: 1)
        XCTAssertEqual(window.currentWindowContentSize?.height ?? 0, standardMetrics.preferredContentSize.height, accuracy: 1)

        settings.launcherCompactMode = true
        window.refreshLayout()

        let compactMetrics = CommandPaletteWindow.layoutMetrics(isCompact: true)
        XCTAssertEqual(window.currentWindowContentSize?.width ?? 0, compactMetrics.preferredContentSize.width, accuracy: 1)
        XCTAssertEqual(window.currentWindowContentSize?.height ?? 0, compactMetrics.preferredContentSize.height, accuracy: 1)

        window.toggle()
    }

    func testShowCallsOnShowCallback() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        var showCount = 0
        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] },
            onShow: { showCount += 1 }
        )

        window.show()
        window.toggle()

        XCTAssertEqual(showCount, 1)
    }

    func testToggleCallsOnShowOnlyWhenOpening() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        var showCount = 0
        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] },
            onShow: { showCount += 1 }
        )

        window.toggle()
        window.toggle()
        window.toggle()
        window.toggle()

        XCTAssertEqual(showCount, 2)
    }

    func testVisibilityTracksShowAndHideTransitions() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] }
        )

        XCTAssertFalse(window.isVisible)

        window.show()
        XCTAssertTrue(window.isVisible)

        window.requestRefresh()

        window.toggle()
        XCTAssertFalse(window.isVisible)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
