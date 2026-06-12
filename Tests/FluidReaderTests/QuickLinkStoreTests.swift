import XCTest
@testable import FluidReader

final class QuickLinkStoreTests: XCTestCase {
    func testQuickLinkItemNormalizesWebURLWithoutScheme() throws {
        let item = try XCTUnwrap(QuickLinkItem.make(urlString: "  example.com/docs  "))

        XCTAssertEqual(item.urlString, "https://example.com/docs")
        XCTAssertEqual(item.title, "example.com docs")
        XCTAssertEqual(item.preview, "example.com docs")
        XCTAssertEqual(item.displayURL, "https://example.com/docs")
    }

    func testQuickLinkItemKeepsCustomTitleAndMailtoURL() throws {
        let item = try XCTUnwrap(QuickLinkItem.make(
            urlString: "mailto:help@example.com",
            title: "Support"
        ))

        XCTAssertEqual(item.urlString, "mailto:help@example.com")
        XCTAssertEqual(item.title, "Support")
    }

    func testQuickLinkItemRejectsInvalidText() {
        XCTAssertNil(QuickLinkItem.make(urlString: "not a link"))
        XCTAssertNil(QuickLinkItem.make(urlString: "ftp://example.com/file"))
        XCTAssertNil(QuickLinkItem.make(urlString: "https://"))
        XCTAssertNil(QuickLinkItem.make(urlString: "mailto:"))
    }

    @MainActor
    func testStoreSavesDedupesLimitsAndPersistsLinks() throws {
        let defaults = try makeDefaults()
        let store = QuickLinkStore(defaults: defaults, storageKey: "links")

        for index in 0..<55 {
            store.saveLink(urlString: "https://example.com/\(index)")
        }
        store.saveLink(urlString: "https://example.com/10")

        XCTAssertEqual(store.items.count, 50)
        XCTAssertEqual(store.items.first?.urlString, "https://example.com/10")
        XCTAssertEqual(store.items.filter { $0.urlString == "https://example.com/10" }.count, 1)

        let reloadedStore = QuickLinkStore(defaults: defaults, storageKey: "links")
        XCTAssertEqual(reloadedStore.items.count, 50)
        XCTAssertEqual(reloadedStore.items.first?.urlString, "https://example.com/10")
    }

    @MainActor
    func testPinnedLinksStayAboveNewerLinks() throws {
        let defaults = try makeDefaults()
        let store = QuickLinkStore(defaults: defaults, storageKey: "links")
        let first = try XCTUnwrap(store.saveLink(urlString: "https://example.com/first"))
        store.saveLink(urlString: "https://example.com/second")

        XCTAssertEqual(store.items.map(\.urlString), [
            "https://example.com/second",
            "https://example.com/first"
        ])
        XCTAssertTrue(store.setPinned(first, isPinned: true))
        XCTAssertEqual(store.items.map(\.urlString), [
            "https://example.com/first",
            "https://example.com/second"
        ])
        XCTAssertTrue(store.items.first?.isPinned == true)

        store.saveLink(urlString: "https://example.com/third")
        XCTAssertEqual(store.items.map(\.urlString), [
            "https://example.com/first",
            "https://example.com/third",
            "https://example.com/second"
        ])

        let reloadedStore = QuickLinkStore(defaults: defaults, storageKey: "links")
        XCTAssertEqual(reloadedStore.items.map(\.urlString), [
            "https://example.com/first",
            "https://example.com/third",
            "https://example.com/second"
        ])
        XCTAssertTrue(reloadedStore.items.first?.isPinned == true)

        XCTAssertTrue(store.setPinned(first, isPinned: false))
        XCTAssertFalse(store.items.first?.isPinned == true)
    }

    @MainActor
    func testOldLinkDataLoadsAsUnpinned() throws {
        let defaults = try makeDefaults()
        let oldLink = OldQuickLinkItem(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1),
            title: "Old link",
            urlString: "https://example.com/old"
        )
        defaults.set(try JSONEncoder().encode([oldLink]), forKey: "links")

        let store = QuickLinkStore(defaults: defaults, storageKey: "links")

        XCTAssertEqual(store.items.map(\.urlString), ["https://example.com/old"])
        XCTAssertTrue(store.items.allSatisfy { !$0.isPinned })
    }

    @MainActor
    func testDeleteAndClearLinks() throws {
        let defaults = try makeDefaults()
        let store = QuickLinkStore(defaults: defaults, storageKey: "links")
        let first = try XCTUnwrap(store.saveLink(urlString: "https://example.com/first"))
        let second = try XCTUnwrap(store.saveLink(urlString: "https://example.com/second"))

        XCTAssertTrue(store.delete(first))
        XCTAssertEqual(store.items.map(\.urlString), ["https://example.com/second"])
        XCTAssertEqual(QuickLinkStore(defaults: defaults, storageKey: "links").items.map(\.urlString), ["https://example.com/second"])
        XCTAssertFalse(store.delete(first))

        store.clear()
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(QuickLinkStore(defaults: defaults, storageKey: "links").items.isEmpty)
        XCTAssertNotNil(second.url)
    }

    @MainActor
    func testUpdateTitleTrimsAndPersists() throws {
        let defaults = try makeDefaults()
        let store = QuickLinkStore(defaults: defaults, storageKey: "links")
        let item = try XCTUnwrap(store.saveLink(urlString: "https://example.com/docs"))

        XCTAssertTrue(store.updateTitle(item, title: "  Team Docs  "))
        XCTAssertEqual(store.items.first?.title, "Team Docs")

        let reloadedStore = QuickLinkStore(defaults: defaults, storageKey: "links")
        XCTAssertEqual(reloadedStore.items.first?.title, "Team Docs")
    }

    @MainActor
    func testUpdateURLKeepsTitleAndDedupesByURL() throws {
        let defaults = try makeDefaults()
        let store = QuickLinkStore(defaults: defaults, storageKey: "links")
        let first = try XCTUnwrap(store.saveLink(urlString: "https://example.com/first", title: "First Link"))
        _ = try XCTUnwrap(store.saveLink(urlString: "https://example.com/second", title: "Second Link"))

        XCTAssertTrue(store.updateURL(first, urlString: "https://example.com/second"))
        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.urlString, "https://example.com/second")
        XCTAssertEqual(store.items.first?.title, "First Link")
    }

    @MainActor
    func testUpdateURLRejectsInvalidValue() throws {
        let defaults = try makeDefaults()
        let store = QuickLinkStore(defaults: defaults, storageKey: "links")
        let item = try XCTUnwrap(store.saveLink(urlString: "https://example.com/docs"))

        XCTAssertFalse(store.updateURL(item, urlString: "not a url"))
        XCTAssertEqual(store.items.first?.urlString, "https://example.com/docs")
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderQuickLinkStoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private struct OldQuickLinkItem: Codable {
    let id: UUID
    let createdAt: Date
    let title: String
    let urlString: String
}
