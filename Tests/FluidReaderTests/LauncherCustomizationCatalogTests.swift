import XCTest
@testable import FluidReader

final class LauncherCustomizationCatalogTests: XCTestCase {
    func testSummarySeparatesDedicatedShortcutOverridesFromCommandCustomizations() {
        let catalog = LauncherCustomizationCatalog(
            actions: [
                CommandPaletteAction(
                    id: "pick-and-read",
                    title: "Pick and Read",
                    systemImage: "selection.pin.in.out",
                    group: .core,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "screenshot-line",
                    title: "Screenshot",
                    systemImage: "camera.viewfinder",
                    group: .core,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "open-notes-workspace",
                    title: "Open Notes Workspace",
                    systemImage: "note.text",
                    group: .saved,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "script-disk-space",
                    title: "Disk Space",
                    systemImage: "terminal",
                    group: .core,
                    sourceKind: .script,
                    run: {}
                )
            ],
            aliasActionIDs: ["open-notes-workspace", "ghost-alias"],
            hotKeyActionIDs: [
                "launcher-shortcut-commands",
                "pick-and-read",
                "open-notes-workspace",
                "script-disk-space",
                "ghost-hotkey"
            ],
            indexedRootCount: 4
        )

        XCTAssertEqual(
            catalog.summary,
            LauncherCustomizationSummary(
                customizedShortcutCount: 2,
                aliasedCommandCount: 1,
                hotKeyCommandCount: 2,
                customizedCommandCount: 2,
                indexedRootCount: 4,
                totalCommandCount: 4
            )
        )
    }

    func testRowsIncludeHotkeyOnlyCommandsAndFilterScriptsSeparately() {
        let catalog = LauncherCustomizationCatalog(
            actions: [
                CommandPaletteAction(
                    id: "open-notes-workspace",
                    title: "Open Notes Workspace",
                    systemImage: "note.text",
                    group: .saved,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "ask-anything",
                    title: "Ask Anything",
                    systemImage: "sparkles",
                    group: .ask,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "window-left-half",
                    title: "Window Left Half",
                    systemImage: "rectangle.lefthalf.filled",
                    group: .window,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "script-disk-space",
                    title: "Disk Space",
                    systemImage: "terminal",
                    group: .core,
                    sourceKind: .script,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "copy-win-recap",
                    title: "Copy Win Recap",
                    systemImage: "doc.on.doc",
                    group: .support,
                    run: {}
                )
            ],
            aliasActionIDs: [],
            hotKeyActionIDs: ["window-left-half"],
            indexedRootCount: 2
        )

        XCTAssertEqual(
            catalog.rows(for: .customized, query: "").map(\.id),
            ["window-left-half"]
        )
        XCTAssertEqual(
            catalog.rows(for: .scripts, query: "").map(\.id),
            ["script-disk-space"]
        )
        XCTAssertEqual(
            catalog.rows(for: .platform, query: "").map(\.id),
            ["open-notes-workspace"]
        )
    }

    func testBrowseLimitHintOnlyAppliesToEmptyNonCustomizedFilters() {
        let actions = (0..<20).map { index in
            CommandPaletteAction(
                id: "platform-\(index)",
                title: "Platform \(index)",
                systemImage: "gearshape",
                group: .settings,
                run: {}
            )
        }
        let catalog = LauncherCustomizationCatalog(
            actions: actions,
            aliasActionIDs: [],
            hotKeyActionIDs: [],
            indexedRootCount: 3
        )

        XCTAssertTrue(
            catalog.shouldShowBrowseLimitHint(for: .platform, query: "", emptyQueryLimit: 5)
        )
        XCTAssertEqual(
            catalog.rows(for: .platform, query: "", emptyQueryLimit: 5).count,
            5
        )
        XCTAssertFalse(
            catalog.shouldShowBrowseLimitHint(for: .platform, query: "platform 12", emptyQueryLimit: 5)
        )
        XCTAssertEqual(
            catalog.rows(for: .platform, query: "platform 12", emptyQueryLimit: 5).first?.id,
            "platform-12"
        )
    }
}
