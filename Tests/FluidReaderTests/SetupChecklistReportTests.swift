import XCTest
@testable import FluidReader

final class SetupChecklistReportTests: XCTestCase {
    func testMissingRequiredPermissionsNeedAction() {
        let report = SetupChecklistReport.make(
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            llmEnabled: false,
            apiKeySet: false,
            saveRecentItems: true,
            launchAtLoginState: .disabled
        )

        XCTAssertEqual(report.actionNeededCount, 2)
        XCTAssertEqual(report.summary, "2 setup steps need attention.")
        XCTAssertEqual(report.focusedItems.map(\.id), ["screen-recording", "accessibility"])
        XCTAssertEqual(report.items.first { $0.id == "screen-recording" }?.state, .actionNeeded)
        XCTAssertEqual(
            report.items.first { $0.id == "screen-recording" }?.detail,
            "Turn on Fluid Reader in Screen Recording. Quit and reopen if macOS still blocks it."
        )
        XCTAssertEqual(report.items.first { $0.id == "accessibility" }?.action, .accessibilitySettings)
        XCTAssertEqual(
            report.items.first { $0.id == "accessibility" }?.detail,
            "Turn on Fluid Reader in Accessibility. Quit and reopen if commands still fail."
        )
        XCTAssertEqual(report.items.first { $0.id == "llm" }?.state, .optional)
    }

    func testReadyLocalReadingHasClearSummary() {
        let report = SetupChecklistReport.make(
            screenRecordingAllowed: true,
            accessibilityTrusted: true,
            llmEnabled: false,
            apiKeySet: false,
            saveRecentItems: true,
            saveClipboardHistory: true,
            launchAtLoginState: .enabled
        )

        XCTAssertEqual(report.actionNeededCount, 0)
        XCTAssertEqual(report.summary, "Ready for local reading.")
        XCTAssertEqual(report.focusedItems.map(\.id), [
            "screen-recording",
            "accessibility",
            "launch-at-login",
            "recent-items",
            "clipboard-history"
        ])
        XCTAssertEqual(report.items.first { $0.id == "launch-at-login" }?.state, .ready)
        XCTAssertEqual(report.items.first { $0.id == "recent-items" }?.state, .ready)
        XCTAssertEqual(report.items.first { $0.id == "clipboard-history" }?.state, .ready)
    }

    func testLLMEnabledWithoutAPIKeyNeedsAction() {
        let report = SetupChecklistReport.make(
            screenRecordingAllowed: true,
            accessibilityTrusted: true,
            llmEnabled: true,
            apiKeySet: false,
            saveRecentItems: false,
            launchAtLoginState: .requiresApproval
        )

        XCTAssertEqual(report.actionNeededCount, 2)
        XCTAssertEqual(report.items.first { $0.id == "llm" }?.detail, "Add an API key so ask actions can run.")
        XCTAssertEqual(report.items.first { $0.id == "llm" }?.action, .appSettings)
        XCTAssertEqual(report.items.first { $0.id == "launch-at-login" }?.state, .actionNeeded)
        XCTAssertEqual(report.items.first { $0.id == "recent-items" }?.state, .optional)
        XCTAssertEqual(report.items.first { $0.id == "clipboard-history" }?.state, .optional)
    }

    func testOptionalItemsUseCanSkipCopy() {
        let report = SetupChecklistReport.make(
            screenRecordingAllowed: true,
            accessibilityTrusted: true,
            llmEnabled: false,
            apiKeySet: false,
            saveRecentItems: false,
            launchAtLoginState: .disabled
        )

        let optionalItems = report.items.filter { $0.state == .optional }
        XCTAssertTrue(optionalItems.allSatisfy { $0.state.title == "Can skip" })
        XCTAssertEqual(report.items.first { $0.id == "llm" }?.detail, "Local mode works without LLM.")
        XCTAssertEqual(
            report.items.first { $0.id == "auto-paste-picked-text" }?.detail,
            "Off. You can turn it on later."
        )
        XCTAssertEqual(
            report.items.first { $0.id == "auto-paste-llm-answers" }?.detail,
            "Off. You can turn it on later."
        )
        XCTAssertEqual(report.items.first { $0.id == "recent-items" }?.detail, "Off. You can turn it on later.")
        XCTAssertEqual(report.items.first { $0.id == "clipboard-history" }?.detail, "Off. You can turn it on later.")
    }

    func testAutoPastePickedTextNeedsAccessibilityWhenEnabled() {
        let report = SetupChecklistReport.make(
            screenRecordingAllowed: true,
            accessibilityTrusted: false,
            llmEnabled: false,
            apiKeySet: false,
            autoPastePickedText: true,
            saveRecentItems: true,
            launchAtLoginState: .disabled
        )

        let item = report.items.first { $0.id == "auto-paste-picked-text" }
        XCTAssertEqual(item?.state, .actionNeeded)
        XCTAssertEqual(item?.action, .accessibilitySettings)
        XCTAssertEqual(
            item?.detail,
            "Turn on Fluid Reader in Accessibility. Quit and reopen if paste still fails."
        )
    }

    func testAutoPasteLLMAnswersNeedsAccessibilityWhenEnabled() {
        let report = SetupChecklistReport.make(
            screenRecordingAllowed: true,
            accessibilityTrusted: false,
            llmEnabled: true,
            apiKeySet: true,
            autoPasteLLMAnswers: true,
            saveRecentItems: true,
            launchAtLoginState: .enabled
        )

        let item = report.items.first { $0.id == "auto-paste-llm-answers" }
        XCTAssertEqual(item?.state, .actionNeeded)
        XCTAssertEqual(item?.action, .accessibilitySettings)
        XCTAssertEqual(
            item?.detail,
            "Turn on Fluid Reader in Accessibility. Quit and reopen if paste still fails."
        )
    }
}
