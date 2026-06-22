import XCTest
@testable import FluidReader

final class SavedWorkspaceCatalogTests: XCTestCase {
    func testSummaryTracksNotesLinksClipboardAndRecent() {
        let notes = [
            ReaderSnippetItem.make(text: "Ship launcher polish", title: "Launch Plan", isPinned: true)!,
            ReaderSnippetItem.make(text: "Quick capture", title: "", isPinned: false)!
        ]
        let links = [
            QuickLinkItem.make(urlString: "https://manual.raycast.com/search-bar", title: "Raycast Search", isPinned: true)!,
            QuickLinkItem.make(urlString: "https://openai.com", title: "OpenAI", isPinned: false)!
        ]
        let clipboardItems = [
            ClipboardHistoryItem.make(text: "clipboard note")!
        ]
        let recentItems = [
            ReaderHistoryItem.make(text: "reader text", answer: "answer")!
        ]

        XCTAssertEqual(
            SavedWorkspaceCatalog.summary(
                notes: notes,
                quickLinks: links,
                clipboardHistory: clipboardItems,
                recentItems: recentItems,
                clipboardEnabled: true,
                recentEnabled: true
            ),
            SavedWorkspaceSummary(
                noteCount: 2,
                pinnedNoteCount: 1,
                linkCount: 2,
                pinnedLinkCount: 1,
                clipboardCount: 1,
                recentCount: 1,
                totalCount: 6,
                clipboardEnabled: true,
                recentEnabled: true
            )
        )
    }

    func testActionSubtitleExpandsToBroaderSavedSurface() {
        let summary = SavedWorkspaceCatalog.summary(
            notes: [ReaderSnippetItem.make(text: "A", title: "Title")!],
            quickLinks: [QuickLinkItem.make(urlString: "https://example.com", title: "Example")!],
            clipboardHistory: [ClipboardHistoryItem.make(text: "clipboard")!],
            recentItems: [],
            clipboardEnabled: true,
            recentEnabled: true
        )

        XCTAssertEqual(
            summary.actionSubtitle,
            "Browse 1 note · 1 link · 1 clipboard in one local workspace"
        )
    }

    func testFilteredItemsSupportNotesLinksClipboardRecentAndPinned() {
        let note = ReaderSnippetItem.make(text: "Daily standup notes", title: "Daily Standup", isPinned: true)!
        let link = QuickLinkItem.make(
            urlString: "https://manual.raycast.com/search-bar",
            title: "Raycast Search",
            isPinned: false
        )!
        let clipboardItem = ClipboardHistoryItem.make(text: "clipboard note text")!
        let recentItem = ReaderHistoryItem.make(text: "recent launcher text")!

        let items = SavedWorkspaceCatalog.items(
            notes: [note],
            quickLinks: [link],
            clipboardHistory: [clipboardItem],
            recentItems: [recentItem]
        )

        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "", filter: .notes).map(\.id),
            [SavedWorkspaceItem.note(note).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "", filter: .links).map(\.id),
            [SavedWorkspaceItem.link(link).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "", filter: .clipboard).map(\.id),
            [SavedWorkspaceItem.clipboard(clipboardItem).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "", filter: .recent).map(\.id),
            [SavedWorkspaceItem.recent(recentItem).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "", filter: .pinned).map(\.id),
            [SavedWorkspaceItem.note(note).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "raycast search", filter: .all).map(\.id),
            [SavedWorkspaceItem.link(link).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "clipboard text", filter: .all).map(\.id),
            [SavedWorkspaceItem.clipboard(clipboardItem).id]
        )
        XCTAssertEqual(
            SavedWorkspaceCatalog.filteredItems(items, query: "recent launcher", filter: .all).map(\.id),
            [SavedWorkspaceItem.recent(recentItem).id]
        )
    }
}
