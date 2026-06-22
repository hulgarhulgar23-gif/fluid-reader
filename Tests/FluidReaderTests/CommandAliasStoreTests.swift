import XCTest
@testable import FluidReader

final class CommandAliasStoreTests: XCTestCase {
    func testSetAliasesNormalizesAndPersistsValues() throws {
        let defaults = try makeDefaults()
        let store = CommandAliasStore(defaults: defaults)

        XCTAssertTrue(store.setAliases(
            actionID: "pick-and-read",
            aliasText: "  Screen Grab  , quick pick,\nSCREEN GRAB  "
        ))

        XCTAssertEqual(
            store.aliases(for: "pick-and-read"),
            ["Screen Grab", "quick pick"]
        )

        let reloadedStore = CommandAliasStore(defaults: defaults)
        XCTAssertEqual(
            reloadedStore.aliases(for: "pick-and-read"),
            ["Screen Grab", "quick pick"]
        )
    }

    func testSettingAliasesMovesDuplicateAliasOffPreviousCommand() throws {
        let defaults = try makeDefaults()
        let store = CommandAliasStore(defaults: defaults)

        XCTAssertTrue(store.setAliases(actionID: "pick-and-read", aliasText: "capture"))
        XCTAssertTrue(store.setAliases(actionID: "settings", aliasText: "capture, prefs"))

        XCTAssertEqual(store.aliases(for: "pick-and-read"), [])
        XCTAssertEqual(store.aliases(for: "settings"), ["capture", "prefs"])
    }

    func testClearAliasesRemovesStoredEntry() throws {
        let defaults = try makeDefaults()
        let store = CommandAliasStore(defaults: defaults)

        XCTAssertTrue(store.setAliases(actionID: "settings", aliasText: "prefs"))
        XCTAssertTrue(store.clearAliases(actionID: "settings"))
        XCTAssertEqual(store.aliases(for: "settings"), [])
        XCTAssertFalse(store.clearAliases(actionID: "settings"))
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.CommandAliasStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
