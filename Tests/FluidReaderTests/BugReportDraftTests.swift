import XCTest
@testable import FluidReader

final class BugReportDraftTests: XCTestCase {
    func testMarkdownIncludesIssueSectionsAndSupportInfo() {
        let draft = BugReportDraft(supportInfo: Self.supportInfo(hasError: true))
        let markdown = draft.markdown()

        XCTAssertTrue(markdown.contains("## What happened?"))
        XCTAssertTrue(markdown.contains("## What did you expect?"))
        XCTAssertTrue(markdown.contains("## Steps"))
        XCTAssertTrue(markdown.contains("## Problem type"))
        XCTAssertTrue(markdown.contains("screen/OCR"))
        XCTAssertTrue(markdown.contains("## Launch Rescue Snapshot"))
        XCTAssertTrue(markdown.contains("- Auto trigger: No auto trigger recorded yet."))
        XCTAssertTrue(markdown.contains("- Auto follow-up: No follow-up run recorded yet."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."))
        XCTAssertTrue(markdown.contains("# Fluid Reader Support Info"))
        XCTAssertTrue(markdown.contains("error Yes"))
    }

    func testMarkdownWarnsAgainstPrivateData() {
        let draft = BugReportDraft(supportInfo: Self.supportInfo(hasError: false))
        let markdown = draft.markdown()

        XCTAssertTrue(markdown.contains("No API keys or private content."))
        XCTAssertFalse(markdown.contains("selected text:"))
        XCTAssertFalse(markdown.contains("sk-test"))
        XCTAssertFalse(markdown.contains("https://internal.example"))
    }

    private static func supportInfo(hasError: Bool) -> SupportInfoReport {
        SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: true,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: true,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: true,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 2,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: hasError
        )
    }
}
