import XCTest
@testable import FluidReader

final class ActivityLogTests: XCTestCase {
    func testRecordKeepsNewestItemsAndLimitsCount() {
        let defaults = makeDefaults()
        let store = ActivityLogStore(defaults: defaults, storageKey: "activity")

        for index in 0..<85 {
            store.record(
                category: "command",
                detail: "event \(index)",
                at: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }

        XCTAssertEqual(store.items.count, ActivityLogStore.maxItemCount)
        XCTAssertEqual(store.items.first?.detail, "event 84")
        XCTAssertEqual(store.items.last?.detail, "event 5")
    }

    func testRecordPersistsItems() {
        let defaults = makeDefaults()
        let firstStore = ActivityLogStore(defaults: defaults, storageKey: "activity")
        firstStore.record(category: "app", detail: "launched", at: Date(timeIntervalSince1970: 10))

        let secondStore = ActivityLogStore(defaults: defaults, storageKey: "activity")

        XCTAssertEqual(secondStore.items.count, 1)
        XCTAssertEqual(secondStore.items.first?.category, "app")
        XCTAssertEqual(secondStore.items.first?.detail, "launched")
    }

    func testClearRemovesItems() {
        let defaults = makeDefaults()
        let store = ActivityLogStore(defaults: defaults, storageKey: "activity")
        store.record(category: "app", detail: "launched")

        store.clear()
        let reloadedStore = ActivityLogStore(defaults: defaults, storageKey: "activity")

        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(reloadedStore.items.isEmpty)
    }

    func testCommandSafeIDHidesRecentItemID() {
        XCTAssertEqual(ActivityLogCommand.safeID("recent-\(UUID().uuidString)"), "recent-item")
        XCTAssertEqual(ActivityLogCommand.safeID("snippet-\(UUID().uuidString)"), "snippet-item")
        XCTAssertEqual(ActivityLogCommand.safeID("use-snippet-\(UUID().uuidString)"), "snippet-item")
        XCTAssertEqual(ActivityLogCommand.safeID("paste-snippet-\(UUID().uuidString)"), "snippet-item")
        XCTAssertEqual(ActivityLogCommand.safeID("delete-snippet-\(UUID().uuidString)"), "snippet-item")
        XCTAssertEqual(ActivityLogCommand.safeID("pin-snippet-\(UUID().uuidString)"), "snippet-item")
        XCTAssertEqual(ActivityLogCommand.safeID("edit-snippet-\(UUID().uuidString)"), "snippet-item")
        XCTAssertEqual(ActivityLogCommand.safeID("quick-link-\(UUID().uuidString)"), "quick-link-item")
        XCTAssertEqual(ActivityLogCommand.safeID("copy-quick-link-\(UUID().uuidString)"), "quick-link-item")
        XCTAssertEqual(ActivityLogCommand.safeID("delete-quick-link-\(UUID().uuidString)"), "quick-link-item")
        XCTAssertEqual(ActivityLogCommand.safeID("pin-quick-link-\(UUID().uuidString)"), "quick-link-item")
        XCTAssertEqual(ActivityLogCommand.safeID("edit-quick-link-\(UUID().uuidString)"), "quick-link-item")
        XCTAssertEqual(ActivityLogCommand.safeID("clipboard-history-\(UUID().uuidString)"), "clipboard-history-item")
        XCTAssertEqual(ActivityLogCommand.safeID("use-clipboard-history-\(UUID().uuidString)"), "clipboard-history-item")
        XCTAssertEqual(ActivityLogCommand.safeID("paste-clipboard-history-\(UUID().uuidString)"), "clipboard-history-item")
        XCTAssertEqual(ActivityLogCommand.safeID("delete-clipboard-history-\(UUID().uuidString)"), "clipboard-history-item")
        XCTAssertEqual(ActivityLogCommand.safeID("app-launch-privateapp"), "app-launch")
        XCTAssertEqual(ActivityLogCommand.safeID("copy-support-info"), "copy-support-info")
    }

    func testRecordMakesValuesOneLine() {
        let defaults = makeDefaults()
        let store = ActivityLogStore(defaults: defaults, storageKey: "activity")

        store.record(category: "command\nrun", detail: "copy\t\tactivity\nlog")

        XCTAssertEqual(store.items.first?.category, "command run")
        XCTAssertEqual(store.items.first?.detail, "copy activity log")
    }

    func testLoadSanitizesPersistedCategoryAndDetailValues() throws {
        let defaults = makeDefaults()
        let longCategory = String(repeating: "a", count: 140)
        let seededItems = [
            ActivityLogItem(
                id: UUID(),
                createdAt: Date(timeIntervalSince1970: 1),
                category: " \n\t ",
                detail: " \r\n "
            ),
            ActivityLogItem(
                id: UUID(),
                createdAt: Date(timeIntervalSince1970: 2),
                category: "command\nrun",
                detail: "copy\t\tactivity\nlog"
            ),
            ActivityLogItem(
                id: UUID(),
                createdAt: Date(timeIntervalSince1970: 3),
                category: longCategory,
                detail: "ok"
            )
        ]
        defaults.set(try JSONEncoder().encode(seededItems), forKey: "activity")

        let store = ActivityLogStore(defaults: defaults, storageKey: "activity")

        XCTAssertEqual(store.items.count, 3)
        XCTAssertEqual(store.items[0].category, "event")
        XCTAssertEqual(store.items[0].detail, "ok")
        XCTAssertEqual(store.items[1].category, "command run")
        XCTAssertEqual(store.items[1].detail, "copy activity log")
        XCTAssertEqual(store.items[2].category, "\(String(repeating: "a", count: 120))...")
    }

    func testMarkdownIncludesSafeNoteAndEvents() {
        let items = [
            ActivityLogItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                createdAt: Date(timeIntervalSince1970: 0),
                category: "command",
                detail: "copy-support-info"
            )
        ]

        let markdown = ActivityLogReport.markdown(items: items)

        XCTAssertTrue(markdown?.contains("# Fluid Reader Activity Log") == true)
        XCTAssertTrue(markdown?.contains("No API keys or private content.") == true)
        XCTAssertTrue(markdown?.contains("1970-01-01T00:00:00Z | command | copy-support-info") == true)
        XCTAssertFalse(markdown?.contains("sk-test") == true)
        XCTAssertFalse(markdown?.contains("https://internal.example") == true)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "FluidReaderActivityLogTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
