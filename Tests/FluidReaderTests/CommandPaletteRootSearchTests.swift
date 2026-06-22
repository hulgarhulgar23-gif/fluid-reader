import XCTest
@testable import FluidReader

final class CommandPaletteRootSearchTests: XCTestCase {
    func testBlankQueryReturnsNoDynamicRootSearchActions() {
        let actions = CommandPaletteRootSearch.makeActions(
            query: "   ",
            apps: [],
            folders: [],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )

        XCTAssertTrue(actions.isEmpty)
    }

    func testMatchingAppQueryBuildsAppLauncherAction() {
        let safari = AppLaunchItem(name: "Safari", url: URL(fileURLWithPath: "/Applications/Safari.app"))
        var copiedText: String?
        var revealedURL: URL?

        let actions = CommandPaletteRootSearch.makeActions(
            query: "safari",
            apps: [safari],
            folders: [],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in },
            revealURL: { revealedURL = $0 },
            copyText: { copiedText = $0 }
        )

        XCTAssertEqual(actions.map(\.id), ["app-launch-safari"])
        XCTAssertEqual(actions.first?.title, "Open App: Safari")
        XCTAssertEqual(actions.first?.group, .open)
        XCTAssertEqual(actions.first?.sourceKind, .app)
        XCTAssertEqual(actions.first?.secondaryActions.map(\.title), ["Reveal App in Finder", "Copy App Path"])

        actions.first?.secondaryActions[0].run()
        XCTAssertEqual(revealedURL?.path, safari.url.path)

        actions.first?.secondaryActions[1].run()
        XCTAssertEqual(copiedText, safari.url.path)
    }

    func testMatchingFolderSnippetAndRecentQueriesBuildWorkspaceActions() throws {
        let downloads = CommonFolderItem(
            id: "downloads",
            title: "Downloads",
            url: URL(fileURLWithPath: "/Users/test/Downloads", isDirectory: true),
            keywords: ["downloads", "files"]
        )
        let snippet = try XCTUnwrap(
            ReaderSnippetItem.make(
                text: "Daily standup notes and blockers",
                title: "Daily Standup"
            )
        )
        let recent = try XCTUnwrap(
            ReaderHistoryItem.make(text: "Follow up with design team on launcher polish")
        )

        let folderActions = CommandPaletteRootSearch.makeActions(
            query: "downloads",
            apps: [],
            folders: [downloads],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )
        XCTAssertEqual(folderActions.first?.id, "folder-downloads")
        XCTAssertEqual(folderActions.first?.sourceKind, .folder)

        let snippetActions = CommandPaletteRootSearch.makeActions(
            query: "standup",
            apps: [],
            folders: [],
            snippets: [snippet],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )
        XCTAssertEqual(snippetActions.first?.sourceKind, .snippet)
        XCTAssertTrue(snippetActions.first?.title.contains("Daily Standup") == true)

        let recentActions = CommandPaletteRootSearch.makeActions(
            query: "launcher polish",
            apps: [],
            folders: [],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [recent],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )
        XCTAssertEqual(recentActions.first?.sourceKind, .recent)
        XCTAssertTrue(recentActions.first?.title.contains("launcher polish") == true)
    }

    func testMatchingQuickLinkAndClipboardQueriesBuildSavedActions() throws {
        let quickLink = try XCTUnwrap(QuickLinkItem.make(
            urlString: "https://manual.raycast.com/search-bar",
            title: "Raycast Search Bar",
            isPinned: true
        ))
        let clipboardHistoryItem = try XCTUnwrap(ClipboardHistoryItem.make(
            text: "quiet launcher behavior checklist"
        ))

        let quickLinkActions = CommandPaletteRootSearch.makeActions(
            query: "raycast search",
            apps: [],
            folders: [],
            snippets: [],
            quickLinks: [quickLink],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )
        XCTAssertEqual(quickLinkActions.first?.sourceKind, .link)
        XCTAssertTrue(quickLinkActions.first?.title.contains("Raycast Search Bar") == true)

        let clipboardActions = CommandPaletteRootSearch.makeActions(
            query: "launcher behavior",
            apps: [],
            folders: [],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [clipboardHistoryItem],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )
        XCTAssertEqual(clipboardActions.first?.sourceKind, .clipboard)
        XCTAssertTrue(clipboardActions.first?.title.contains("launcher behavior") == true)
    }

    func testSnippetActionsMatchNoteKeywordAndExposeWorkspaceActions() throws {
        let snippet = try XCTUnwrap(
            ReaderSnippetItem.make(
                text: "Launch helper checklist",
                title: "Launch Helper"
            )
        )
        var pinnedItem: ReaderSnippetItem?
        var pinnedValue: Bool?
        var openedWorkspace = false

        let actions = CommandPaletteRootSearch.makeActions(
            query: "note",
            apps: [],
            folders: [],
            snippets: [snippet],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openNotesWorkspace: { openedWorkspace = true },
            setSnippetPinned: { item, isPinned in
                pinnedItem = item
                pinnedValue = isPinned
            },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )

        XCTAssertEqual(actions.first?.sourceKind, .snippet)
        XCTAssertEqual(
            actions.first?.secondaryActions.map(\.title),
            ["Copy Snippet Text", "Pin Note", "Open Notes Workspace"]
        )

        actions.first?.secondaryActions[1].run()
        XCTAssertEqual(pinnedItem, snippet)
        XCTAssertEqual(pinnedValue, true)

        actions.first?.secondaryActions[2].run()
        XCTAssertTrue(openedWorkspace)
    }

    func testMatchingFileQueryBuildsIndexedFileAction() throws {
        let homeDirectory = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        let fileURL = homeDirectory
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("Launch Plan.md")
        let fileItem = try XCTUnwrap(LocalFileSearchItem.make(url: fileURL, homeDirectory: homeDirectory))
        var openedFile: LocalFileSearchItem?

        let fileActions = CommandPaletteRootSearch.makeActions(
            query: "launch plan",
            apps: [],
            folders: [],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in },
            files: [fileItem],
            openFile: { openedFile = $0 }
        )

        XCTAssertEqual(fileActions.first?.sourceKind, .file)
        XCTAssertEqual(fileActions.first?.title, "Open File: Launch Plan.md")
        XCTAssertEqual(fileActions.first?.subtitle, "~/Documents")
        XCTAssertEqual(fileActions.first?.secondaryActions.map(\.title), ["Reveal File in Finder", "Copy File Path"])

        fileActions.first?.run()
        XCTAssertEqual(openedFile, fileItem)
    }

    func testExactAppMatchBeatsGenericOpenAppCommand() {
        let genericAction = CommandPaletteAction(
            id: "open-app",
            title: "Open App",
            subtitle: "Launch an installed app",
            systemImage: "app.badge",
            keywords: ["launcher", "app", "spotlight"],
            run: {}
        )
        let safari = AppLaunchItem(name: "Safari", url: URL(fileURLWithPath: "/Applications/Safari.app"))
        let dynamicActions = CommandPaletteRootSearch.makeActions(
            query: "safari",
            apps: [safari],
            folders: [],
            snippets: [],
            quickLinks: [],
            clipboardHistory: [],
            recentItems: [],
            openApp: { _ in },
            openFolder: { _ in },
            useSnippet: { _ in },
            openQuickLink: { _ in },
            copyClipboardHistory: { _ in },
            restoreRecentItem: { _ in }
        )

        let ranked = CommandPaletteAction.filter([genericAction] + dynamicActions, query: "safari")
        XCTAssertEqual(ranked.first?.id, "app-launch-safari")
    }
}
