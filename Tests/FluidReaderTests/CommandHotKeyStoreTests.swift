import XCTest
@testable import FluidReader

final class CommandHotKeyStoreTests: XCTestCase {
    func testParseSupportsSymbolsAndTextFormats() {
        XCTAssertEqual(CommandHotKeyShortcut.parse("⌥⌘p")?.displayText, "⌥⌘P")
        XCTAssertEqual(CommandHotKeyShortcut.parse("cmd+shift+p")?.displayText, "⇧⌘P")
        XCTAssertEqual(CommandHotKeyShortcut.parse("control+option+space")?.displayText, "⌃⌥Space")
    }

    func testSetShortcutNormalizesAndPersistsValidText() throws {
        let defaults = try makeDefaults()
        let store = CommandHotKeyStore(defaults: defaults)

        XCTAssertTrue(store.setShortcutText(actionID: "pick-and-read", shortcutText: "cmd+shift+p"))
        XCTAssertEqual(store.shortcutText(for: "pick-and-read"), "⇧⌘P")
        XCTAssertEqual(store.parsedShortcut(for: "pick-and-read")?.displayText, "⇧⌘P")

        let reloadedStore = CommandHotKeyStore(defaults: defaults)
        XCTAssertEqual(reloadedStore.shortcutText(for: "pick-and-read"), "⇧⌘P")
    }

    func testDuplicateShortcutMovesToLatestCommand() throws {
        let defaults = try makeDefaults()
        let store = CommandHotKeyStore(defaults: defaults)

        XCTAssertTrue(store.setShortcutText(actionID: "pick-and-read", shortcutText: "cmd+shift+p"))
        XCTAssertTrue(store.setShortcutText(actionID: "settings", shortcutText: "⌘⇧P"))

        XCTAssertEqual(store.shortcutText(for: "pick-and-read"), "")
        XCTAssertEqual(store.shortcutText(for: "settings"), "⇧⌘P")
    }

    func testBindingsSkipInvalidEntries() throws {
        let defaults = try makeDefaults()
        let store = CommandHotKeyStore(defaults: defaults)

        XCTAssertTrue(store.setShortcutText(actionID: "pick-and-read", shortcutText: "not-a-hotkey"))
        XCTAssertTrue(store.setShortcutText(actionID: "settings", shortcutText: "⌥⌘P"))

        XCTAssertEqual(store.bindings().map(\.actionID), ["settings"])
        XCTAssertEqual(
            store.validationMessage(for: "pick-and-read"),
            "Use a modifier plus key, like ⌥⌘P or cmd+shift+p."
        )
    }

    func testValidationFlagsConflictWithDefaultLauncherShortcut() throws {
        let defaults = try makeDefaults()
        let store = CommandHotKeyStore(defaults: defaults)

        XCTAssertTrue(
            store.setShortcutText(
                actionID: "settings",
                shortcutText: LauncherHotKeyCatalog.commands.defaultShortcutDisplayText
            )
        )

        XCTAssertTrue(store.hasConflict(for: "settings"))
        XCTAssertEqual(
            store.validationMessage(for: "settings"),
            "Conflicts with Commands: \(LauncherHotKeyCatalog.commands.defaultShortcutDisplayText)."
        )
    }

    func testLauncherDefinitionValidationFlagsConflictWithOtherLauncherShortcut() throws {
        let defaults = try makeDefaults()
        let store = CommandHotKeyStore(defaults: defaults)

        XCTAssertTrue(
            store.setShortcutText(
                actionID: LauncherHotKeyCatalog.commands.id,
                shortcutText: LauncherHotKeyCatalog.screenshot.defaultShortcutDisplayText
            )
        )

        XCTAssertTrue(store.hasConflict(for: LauncherHotKeyCatalog.commands.id))
        XCTAssertEqual(
            LauncherHotKeyCatalog.commands.validationMessage(using: store),
            "Conflicts with Screenshot: \(LauncherHotKeyCatalog.screenshot.defaultShortcutDisplayText)."
        )
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.CommandHotKeyStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
