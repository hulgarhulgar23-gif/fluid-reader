import XCTest
@testable import FluidReader

final class NotesWorkspaceCatalogTests: XCTestCase {
    func testSummaryTracksPinnedNamedAndQuickCaptureNotes() {
        let notes = [
            ReaderSnippetItem.make(text: "First note", title: "Daily Plan", isPinned: true)!,
            ReaderSnippetItem.make(text: "Second note", title: "", isPinned: false)!,
            ReaderSnippetItem.make(text: "Third note", title: "Ideas", isPinned: false)!
        ]

        XCTAssertEqual(
            NotesWorkspaceCatalog.summary(notes),
            NotesWorkspaceSummary(
                totalCount: 3,
                pinnedCount: 1,
                titledCount: 2,
                quickCaptureCount: 1
            )
        )
        XCTAssertEqual(
            NotesWorkspaceCatalog.summary(notes).actionSubtitle,
            "Browse 3 saved notes · 1 pinned in one local workspace"
        )
    }

    func testFilteredNotesSupportsPinnedNamedQuickCaptureAndSearch() {
        let pinnedNamed = ReaderSnippetItem.make(text: "Design review notes", title: "Design Review", isPinned: true)!
        let quickCapture = ReaderSnippetItem.make(text: "capture this from launcher", title: "", isPinned: false)!
        let named = ReaderSnippetItem.make(text: "Follow up with team", title: "Follow Up", isPinned: false)!
        let notes = [pinnedNamed, quickCapture, named]

        XCTAssertEqual(
            NotesWorkspaceCatalog.filteredNotes(notes, query: "", filter: .pinned).map(\.id),
            [pinnedNamed.id]
        )
        XCTAssertEqual(
            Set(NotesWorkspaceCatalog.filteredNotes(notes, query: "", filter: .titled).map(\.id)),
            Set([pinnedNamed.id, named.id])
        )
        XCTAssertEqual(
            NotesWorkspaceCatalog.filteredNotes(notes, query: "", filter: .quickCapture).map(\.id),
            [quickCapture.id]
        )
        XCTAssertEqual(
            NotesWorkspaceCatalog.filteredNotes(notes, query: "design", filter: .all).map(\.id),
            [pinnedNamed.id]
        )
        XCTAssertEqual(
            NotesWorkspaceCatalog.filteredNotes(notes, query: "quick capture", filter: .quickCapture).map(\.id),
            [quickCapture.id]
        )
    }
}
