import XCTest
@testable import FluidReader

final class FreeformPromptTests: XCTestCase {
    func testCleanTrimsPrompt() {
        XCTAssertEqual(FreeformPrompt.clean("  What does this mean? \n"), "What does this mean?")
    }

    func testCleanLimitsLongPrompt() {
        let prompt = String(repeating: "a", count: FreeformPrompt.maxLength + 8)

        XCTAssertEqual(FreeformPrompt.clean(prompt).count, FreeformPrompt.maxLength)
    }

    func testCleanKeepsBlankPromptBlank() {
        XCTAssertTrue(FreeformPrompt.clean(" \n\t ").isEmpty)
    }

    func testPreviewCompactsWhitespaceAndLimitsLength() {
        XCTAssertEqual(
            FreeformPrompt.preview("  What\n\n does   this mean for me?  ", limit: 16),
            "What does this m..."
        )
    }
}
