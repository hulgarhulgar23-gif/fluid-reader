import AppKit
import XCTest
@testable import FluidReader

@MainActor
final class FrontAppPasterTests: XCTestCase {
    func testCleanTrimsText() {
        XCTAssertEqual(FrontAppPaster.clean("  hello  "), "hello")
    }

    func testCleanRejectsBlankText() {
        XCTAssertNil(FrontAppPaster.clean("  \n  "))
        XCTAssertNil(FrontAppPaster.clean(nil))
    }

    func testPasteStopsWhenAccessibilityIsMissing() async {
        let result = await FrontAppPaster.paste(
            "hello",
            to: nil,
            accessibilityTrusted: { false },
            postPasteShortcut: { true },
            activationDelayNanoseconds: 0,
            restoreDelayNanoseconds: 0
        )

        XCTAssertEqual(result, .accessibilityNotAllowed)
    }

    func testPasteStopsWhenTargetAppIsMissing() async {
        let result = await FrontAppPaster.paste(
            "hello",
            to: nil,
            accessibilityTrusted: { true },
            postPasteShortcut: { true },
            activationDelayNanoseconds: 0,
            restoreDelayNanoseconds: 0
        )

        XCTAssertEqual(result, .noTargetApplication)
    }

    func testPasteboardSnapshotRestoresString() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("FrontAppPasterTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)

        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString("new clipboard", forType: .string)

        snapshot.restore(to: pasteboard)

        XCTAssertEqual(pasteboard.string(forType: .string), "old clipboard")
    }

    func testPasteboardSnapshotSkipsRestoreWhenAnotherWriterIntervened() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("FrontAppPasterTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)

        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString("our paste text", forType: .string)
        let ourChangeCount = pasteboard.changeCount

        // Another writer (e.g. the user copying) modifies the pasteboard
        // before our delayed restore runs.
        pasteboard.clearContents()
        pasteboard.setString("user's new clipboard", forType: .string)

        XCTAssertFalse(snapshot.restore(to: pasteboard, ifChangeCountEquals: ourChangeCount))
        XCTAssertEqual(pasteboard.string(forType: .string), "user's new clipboard")
    }

    func testPasteboardSnapshotRestoresWhenChangeCountMatches() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("FrontAppPasterTests-\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)

        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        pasteboard.clearContents()
        pasteboard.setString("our paste text", forType: .string)
        let ourChangeCount = pasteboard.changeCount

        XCTAssertTrue(snapshot.restore(to: pasteboard, ifChangeCountEquals: ourChangeCount))
        XCTAssertEqual(pasteboard.string(forType: .string), "old clipboard")
    }
}
