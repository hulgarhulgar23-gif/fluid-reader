import XCTest
@testable import FluidReader

final class ReaderHistoryTests: XCTestCase {
    func testHistoryItemCleansAndPreviewsText() throws {
        let item = try XCTUnwrap(ReaderHistoryItem.make(
            text: "  First line\nSecond line  ",
            answer: "  "
        ))

        XCTAssertEqual(item.text, "First line\nSecond line")
        XCTAssertEqual(item.answer, "")
        XCTAssertEqual(item.preview, "First line Second line")
        XCTAssertEqual(item.detail, "Text")
    }

    @MainActor
    func testReaderStateSavesDedupesAndLimitsHistory() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)

        for index in 0..<25 {
            state.remember(text: "Text \(index)")
        }
        state.remember(text: "Text 10")

        XCTAssertEqual(state.recentItems.count, 20)
        XCTAssertEqual(state.recentItems.first?.text, "Text 10")
        XCTAssertEqual(state.recentItems.filter { $0.text == "Text 10" }.count, 1)

        let reloadedState = ReaderState(defaults: defaults)
        XCTAssertEqual(reloadedState.recentItems.count, 20)
        XCTAssertEqual(reloadedState.recentItems.first?.text, "Text 10")
    }

    @MainActor
    func testReaderStateSavesDedupesAndLimitsSnippets() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)

        for index in 0..<55 {
            state.saveSnippet(text: "Snippet \(index)")
        }
        state.saveSnippet(text: "Snippet 10")

        XCTAssertEqual(state.snippets.count, 50)
        XCTAssertEqual(state.snippets.first?.text, "Snippet 10")
        XCTAssertEqual(state.snippets.filter { $0.text == "Snippet 10" }.count, 1)

        let reloadedState = ReaderState(defaults: defaults)
        XCTAssertEqual(reloadedState.snippets.count, 50)
        XCTAssertEqual(reloadedState.snippets.first?.text, "Snippet 10")
    }

    @MainActor
    func testPinnedSnippetsStayAboveNewerSnippets() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        let first = try XCTUnwrap(state.saveSnippet(text: "First snippet"))
        state.saveSnippet(text: "Second snippet")

        XCTAssertEqual(state.snippets.map(\.text), ["Second snippet", "First snippet"])
        XCTAssertTrue(state.setSnippetPinned(first, isPinned: true))
        XCTAssertEqual(state.snippets.map(\.text), ["First snippet", "Second snippet"])
        XCTAssertTrue(state.snippets.first?.isPinned == true)

        state.saveSnippet(text: "Third snippet")
        XCTAssertEqual(state.snippets.map(\.text), ["First snippet", "Third snippet", "Second snippet"])

        let reloadedState = ReaderState(defaults: defaults)
        XCTAssertEqual(reloadedState.snippets.map(\.text), ["First snippet", "Third snippet", "Second snippet"])
        XCTAssertTrue(reloadedState.snippets.first?.isPinned == true)

        XCTAssertTrue(state.setSnippetPinned(first, isPinned: false))
        XCTAssertFalse(state.snippets.first?.isPinned == true)
    }

    @MainActor
    func testOldSnippetDataLoadsAsUnpinned() throws {
        let defaults = try makeDefaults()
        let oldSnippet = OldSnippetItem(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1),
            text: "Old snippet"
        )
        defaults.set(try JSONEncoder().encode([oldSnippet]), forKey: "readerSnippetItems")

        let state = ReaderState(defaults: defaults)

        XCTAssertEqual(state.snippets.map(\.text), ["Old snippet"])
        XCTAssertTrue(state.snippets.allSatisfy { !$0.isPinned })
    }

    @MainActor
    func testRestoreAndClearHistory() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        state.remember(text: "Saved text", answer: "Saved answer")

        let item = try XCTUnwrap(state.recentItems.first)
        state.restore(item)

        XCTAssertEqual(state.lastText, "Saved text")
        XCTAssertEqual(state.answerText, "Saved answer")
        XCTAssertNil(state.lastImageData)

        state.clearHistory()
        XCTAssertTrue(state.recentItems.isEmpty)
        XCTAssertTrue(ReaderState(defaults: defaults).recentItems.isEmpty)
    }

    @MainActor
    func testClearSnippets() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        state.saveSnippet(text: "Saved snippet")

        state.clearSnippets()

        XCTAssertTrue(state.snippets.isEmpty)
        XCTAssertTrue(ReaderState(defaults: defaults).snippets.isEmpty)
        XCTAssertEqual(state.petMessage, "Snippets cleared.")
    }

    @MainActor
    func testDeleteSnippetRemovesOnlyOneItem() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        let first = try XCTUnwrap(state.saveSnippet(text: "First snippet"))
        let second = try XCTUnwrap(state.saveSnippet(text: "Second snippet"))

        XCTAssertTrue(state.deleteSnippet(first))

        XCTAssertEqual(state.snippets.map(\.text), ["Second snippet"])
        XCTAssertEqual(ReaderState(defaults: defaults).snippets.map(\.text), ["Second snippet"])
        XCTAssertFalse(state.deleteSnippet(first))
        XCTAssertTrue(state.deleteSnippet(second))
        XCTAssertTrue(ReaderState(defaults: defaults).snippets.isEmpty)
        XCTAssertEqual(state.petMessage, "Deleted snippet.")
    }

    @MainActor
    func testUseSnippetLoadsItIntoReader() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        let snippet = try XCTUnwrap(state.saveSnippet(text: "Saved snippet"))
        state.answerText = "Old answer"
        state.lastImageData = Data([1, 2, 3])
        state.errorText = "Old error"
        state.isWorking = true

        state.useSnippet(snippet)

        XCTAssertEqual(state.lastText, "Saved snippet")
        XCTAssertEqual(state.answerText, "")
        XCTAssertNil(state.lastImageData)
        XCTAssertEqual(state.errorText, "")
        XCTAssertFalse(state.isWorking)
        XCTAssertEqual(state.snippets.map(\.text), ["Saved snippet"])
        XCTAssertEqual(state.petMessage, "Loaded snippet.")
    }

    @MainActor
    func testRenameSnippetPersistsCustomTitle() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        let snippet = try XCTUnwrap(state.saveSnippet(text: "Original snippet text"))

        XCTAssertTrue(state.renameSnippet(snippet, title: "  Standup Note  "))
        XCTAssertEqual(state.snippets.first?.title, "Standup Note")
        XCTAssertEqual(state.snippets.first?.preview, "Standup Note")

        let reloadedState = ReaderState(defaults: defaults)
        XCTAssertEqual(reloadedState.snippets.first?.title, "Standup Note")
    }

    @MainActor
    func testEditSnippetTextUpdatesSnippetAndDedupesByText() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        let first = try XCTUnwrap(state.saveSnippet(text: "First snippet"))
        _ = try XCTUnwrap(state.saveSnippet(text: "Second snippet"))

        XCTAssertTrue(state.editSnippetText(first, text: "Second snippet"))
        XCTAssertEqual(state.snippets.count, 1)
        XCTAssertEqual(state.snippets.first?.text, "Second snippet")
    }

    @MainActor
    func testEditSnippetTextRejectsEmptyText() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        let snippet = try XCTUnwrap(state.saveSnippet(text: "Saved snippet"))

        XCTAssertFalse(state.editSnippetText(snippet, text: "   "))
        XCTAssertEqual(state.snippets.first?.text, "Saved snippet")
    }

    @MainActor
    func testClearCurrentKeepsHistory() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        state.remember(text: "Saved text")
        state.lastText = "Current text"
        state.answerText = "Current answer"
        state.lastImageData = Data([1, 2, 3])
        state.errorText = "Error"
        state.isWorking = true

        state.clearCurrent()

        XCTAssertEqual(state.lastText, "")
        XCTAssertEqual(state.answerText, "")
        XCTAssertNil(state.lastImageData)
        XCTAssertEqual(state.errorText, "")
        XCTAssertFalse(state.isWorking)
        XCTAssertEqual(state.recentItems.count, 1)
        XCTAssertTrue(state.snippets.isEmpty)
        XCTAssertEqual(state.petMessage, "Reader cleared.")
    }

    @MainActor
    func testClearLocalReaderDataClearsCurrentHistoryAndSnippets() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        state.remember(text: "Saved text", answer: "Saved answer")
        state.saveSnippet(text: "Saved snippet")
        state.lastText = "Current text"
        state.answerText = "Current answer"
        state.lastImageData = Data([1, 2, 3])
        state.errorText = "Error"
        state.isWorking = true

        state.clearLocalReaderData()

        XCTAssertEqual(state.lastText, "")
        XCTAssertEqual(state.answerText, "")
        XCTAssertNil(state.lastImageData)
        XCTAssertEqual(state.errorText, "")
        XCTAssertFalse(state.isWorking)
        XCTAssertTrue(state.recentItems.isEmpty)
        XCTAssertTrue(state.snippets.isEmpty)
        XCTAssertTrue(ReaderState(defaults: defaults).recentItems.isEmpty)
        XCTAssertTrue(ReaderState(defaults: defaults).snippets.isEmpty)
        XCTAssertEqual(state.petMessage, "Local reader data cleared.")
    }

    @MainActor
    func testSilentClearDoesNotChangePetMessage() throws {
        let defaults = try makeDefaults()
        let state = ReaderState(defaults: defaults)
        state.petSay("Keep this", mood: .happy)
        state.remember(text: "Saved text")

        state.clearHistory(announce: false)

        XCTAssertTrue(state.recentItems.isEmpty)
        XCTAssertEqual(state.petMessage, "Keep this")
        XCTAssertEqual(state.petMood, .happy)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private struct OldSnippetItem: Codable {
    let id: UUID
    let createdAt: Date
    let text: String
}
