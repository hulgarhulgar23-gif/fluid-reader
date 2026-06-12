import AppKit
import XCTest
@testable import FluidReader

@MainActor
final class CommandPaletteWindowTests: XCTestCase {
    func testShowCallsOnShowCallback() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        var showCount = 0
        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] },
            onShow: { showCount += 1 }
        )

        window.show()
        window.toggle()

        XCTAssertEqual(showCount, 1)
    }

    func testToggleCallsOnShowOnlyWhenOpening() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        var showCount = 0
        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] },
            onShow: { showCount += 1 }
        )

        window.toggle()
        window.toggle()
        window.toggle()
        window.toggle()

        XCTAssertEqual(showCount, 2)
    }

    func testVisibilityTracksShowAndHideTransitions() throws {
        _ = NSApplication.shared

        let state = ReaderState(defaults: try makeDefaults())
        let settings = SettingsStore.shared
        let window = CommandPaletteWindow(
            state: state,
            settings: settings,
            actions: { [] }
        )

        XCTAssertFalse(window.isVisible)

        window.show()
        XCTAssertTrue(window.isVisible)

        window.requestRefresh()

        window.toggle()
        XCTAssertFalse(window.isVisible)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
