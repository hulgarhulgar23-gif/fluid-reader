import XCTest
@testable import FluidReader

final class WindowCustomizationCatalogTests: XCTestCase {
    func testSummaryTracksProfileGapCycleAndWindowHotkeys() {
        let catalog = WindowCustomizationCatalog(
            actions: [
                CommandPaletteAction(
                    id: "window-settings",
                    title: "Window Settings",
                    systemImage: "slider.horizontal.3",
                    group: .window,
                    run: {}
                ),
                CommandPaletteAction(
                    id: FrontWindowLayoutCommand.leftHalf.actionID,
                    title: FrontWindowLayoutCommand.leftHalf.title,
                    systemImage: FrontWindowLayoutCommand.leftHalf.systemImage,
                    group: .window,
                    run: {}
                ),
                CommandPaletteAction(
                    id: FrontWindowLayoutCommand.maximize.actionID,
                    title: FrontWindowLayoutCommand.maximize.title,
                    systemImage: FrontWindowLayoutCommand.maximize.systemImage,
                    group: .window,
                    run: {}
                ),
                CommandPaletteAction(
                    id: FrontWindowCycleProfile.focus.actionID,
                    title: FrontWindowCycleProfile.focus.commandTitle,
                    systemImage: FrontWindowCycleProfile.focus.systemImage,
                    group: .window,
                    run: {}
                )
            ],
            hotKeyActionIDs: ["window-settings", FrontWindowLayoutCommand.leftHalf.actionID],
            activeProfile: .focus,
            activeCycleCommands: [.leftHalf, .center, .rightHalf, .maximize],
            gapPoints: 16
        )

        XCTAssertEqual(
            catalog.summary,
            WindowCustomizationSummary(
                activeProfileTitle: "Focus",
                gapPoints: 16,
                activeCycleCommandCount: 4,
                customizedHotKeyCount: 2,
                totalActionCount: 4
            )
        )
    }

    func testRowsFilterCycleLayoutsProfilesAndCustomizedHotkeys() {
        let actions = [
            CommandPaletteAction(
                id: "window-settings",
                title: "Window Settings",
                systemImage: "slider.horizontal.3",
                group: .window,
                run: {}
            ),
            CommandPaletteAction(
                id: FrontWindowLayoutCommand.leftHalf.actionID,
                title: FrontWindowLayoutCommand.leftHalf.title,
                systemImage: FrontWindowLayoutCommand.leftHalf.systemImage,
                group: .window,
                run: {}
            ),
            CommandPaletteAction(
                id: FrontWindowLayoutCommand.center.actionID,
                title: FrontWindowLayoutCommand.center.title,
                systemImage: FrontWindowLayoutCommand.center.systemImage,
                group: .window,
                run: {}
            ),
            CommandPaletteAction(
                id: FrontWindowLayoutCommand.cycleLayout.actionID,
                title: FrontWindowLayoutCommand.cycleLayout.title,
                systemImage: FrontWindowLayoutCommand.cycleLayout.systemImage,
                group: .window,
                run: {}
            ),
            CommandPaletteAction(
                id: FrontWindowLayoutCommand.moveToNextDisplay.actionID,
                title: FrontWindowLayoutCommand.moveToNextDisplay.title,
                systemImage: FrontWindowLayoutCommand.moveToNextDisplay.systemImage,
                group: .window,
                run: {}
            ),
            CommandPaletteAction(
                id: FrontWindowCycleProfile.focus.actionID,
                title: FrontWindowCycleProfile.focus.commandTitle,
                systemImage: FrontWindowCycleProfile.focus.systemImage,
                group: .window,
                run: {}
            )
        ]

        let catalog = WindowCustomizationCatalog(
            actions: actions,
            hotKeyActionIDs: [FrontWindowLayoutCommand.moveToNextDisplay.actionID],
            activeProfile: .focus,
            activeCycleCommands: [.leftHalf, .center, .rightHalf, .maximize],
            gapPoints: 0
        )

        XCTAssertEqual(
            catalog.rows(for: .customized, query: "").map(\.id),
            [FrontWindowLayoutCommand.moveToNextDisplay.actionID]
        )
        XCTAssertEqual(
            Set(catalog.rows(for: .cycle, query: "").map(\.id)),
            Set([
                "window-settings",
                FrontWindowLayoutCommand.leftHalf.actionID,
                FrontWindowLayoutCommand.center.actionID,
                FrontWindowLayoutCommand.cycleLayout.actionID,
                FrontWindowLayoutCommand.moveToNextDisplay.actionID
            ])
        )
        XCTAssertEqual(
            catalog.rows(for: .profiles, query: "").map(\.id),
            [FrontWindowCycleProfile.focus.actionID]
        )
        XCTAssertEqual(
            Set(catalog.rows(for: .layouts, query: "").map(\.id)),
            Set([
                FrontWindowLayoutCommand.leftHalf.actionID,
                FrontWindowLayoutCommand.center.actionID
            ])
        )
    }

    func testBrowseLimitHintOnlyAppliesToEmptyNonCustomizedWindowFilters() {
        let actions = FrontWindowLayoutCommand.cycleEligibleCommands.map { command in
            CommandPaletteAction(
                id: command.actionID,
                title: command.title,
                systemImage: command.systemImage,
                group: .window,
                run: {}
            )
        }

        let catalog = WindowCustomizationCatalog(
            actions: actions,
            hotKeyActionIDs: [],
            activeProfile: .full,
            activeCycleCommands: FrontWindowLayoutCommand.cycleEligibleCommands,
            gapPoints: 12
        )

        XCTAssertTrue(
            catalog.shouldShowBrowseLimitHint(for: .all, query: "", emptyQueryLimit: 5)
        )
        XCTAssertEqual(
            catalog.rows(for: .all, query: "", emptyQueryLimit: 5).count,
            5
        )
        XCTAssertFalse(
            catalog.shouldShowBrowseLimitHint(for: .all, query: "maximize", emptyQueryLimit: 5)
        )
        XCTAssertEqual(
            catalog.rows(for: .all, query: "maximize", emptyQueryLimit: 5).first?.id,
            FrontWindowLayoutCommand.maximize.actionID
        )
    }
}
