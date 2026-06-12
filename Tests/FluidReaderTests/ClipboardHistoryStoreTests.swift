import XCTest
@testable import FluidReader

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
    func testItemCleansTextAndBuildsPreview() throws {
        let item = try XCTUnwrap(ClipboardHistoryItem.make(text: "  Hello clipboard\n"))

        XCTAssertEqual(item.text, "Hello clipboard")
        XCTAssertEqual(item.preview, "Hello clipboard")
        XCTAssertNil(ClipboardHistoryItem.make(text: "  \n"))
    }

    func testStoreSavesDedupesLimitsAndPersistsItems() throws {
        let defaults = makeDefaults()
        let store = ClipboardHistoryStore(defaults: defaults, storageKey: "history")

        for index in 0..<55 {
            store.remember(
                text: "Clip \(index)",
                createdAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        store.remember(text: "Clip 10", createdAt: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(store.items.count, ClipboardHistoryStore.itemLimit)
        XCTAssertEqual(store.items.first?.text, "Clip 10")
        XCTAssertEqual(store.items.filter { $0.text == "Clip 10" }.count, 1)

        let reloadedStore = ClipboardHistoryStore(defaults: defaults, storageKey: "history")
        XCTAssertEqual(reloadedStore.items.first?.text, "Clip 10")
        XCTAssertEqual(reloadedStore.items.count, ClipboardHistoryStore.itemLimit)
    }

    func testDeleteAndClearItems() throws {
        let defaults = makeDefaults()
        let store = ClipboardHistoryStore(defaults: defaults, storageKey: "history")
        let first = try XCTUnwrap(store.remember(text: "First"))
        let second = try XCTUnwrap(store.remember(text: "Second"))

        XCTAssertTrue(store.delete(first))
        XCTAssertEqual(store.items.map(\.text), ["Second"])
        XCTAssertFalse(store.delete(first))

        XCTAssertTrue(store.delete(second))
        XCTAssertTrue(ClipboardHistoryStore(defaults: defaults, storageKey: "history").items.isEmpty)

        store.remember(text: "Third")
        store.clear()
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(ClipboardHistoryStore(defaults: defaults, storageKey: "history").items.isEmpty)
    }

    func testLongTextIsCapped() throws {
        let longText = String(repeating: "a", count: ClipboardHistoryStore.maxTextLength + 10)
        let item = try XCTUnwrap(ClipboardHistoryItem.make(text: longText))

        XCTAssertEqual(item.text.count, ClipboardHistoryStore.maxTextLength)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "FluidReaderClipboardHistoryStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
