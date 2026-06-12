import XCTest
@testable import FluidReader

final class TroubleshootingGuideReportTests: XCTestCase {
    func testMarkdownIncludesStatusAndCommonFixes() {
        let report = TroubleshootingGuideReport(
            screenRecordingAllowed: true,
            accessibilityTrusted: false,
            llmEnabled: true,
            apiKeySet: false,
            activityLogItemCount: 4
        )

        let markdown = report.markdown()

        XCTAssertTrue(markdown.contains("# Fluid Reader Troubleshooting Guide"))
        XCTAssertTrue(markdown.contains("- Screen Recording: Yes"))
        XCTAssertTrue(markdown.contains("- Accessibility: No"))
        XCTAssertTrue(markdown.contains("- LLM: On"))
        XCTAssertTrue(markdown.contains("- API key set: No"))
        XCTAssertTrue(markdown.contains("- Activity log item count: 4"))
        XCTAssertTrue(markdown.contains("Read Clipboard Text"))
        XCTAssertTrue(markdown.contains("Paste Last Text"))
        XCTAssertTrue(markdown.contains("Window Maximize"))
        XCTAssertTrue(markdown.contains("Copy Issue Bundle"))
    }

    func testMarkdownDoesNotIncludePrivateReaderContent() {
        let report = TroubleshootingGuideReport(
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            llmEnabled: false,
            apiKeySet: false,
            activityLogItemCount: 0
        )

        let markdown = report.markdown()

        XCTAssertTrue(markdown.contains("No API keys or private content."))
        XCTAssertFalse(markdown.contains("selected text:"))
        XCTAssertFalse(markdown.contains("sk-test"))
        XCTAssertFalse(markdown.contains("https://internal.example"))
    }
}
