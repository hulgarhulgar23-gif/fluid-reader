import XCTest
@testable import FluidReader

final class IssueSupportBundleTests: XCTestCase {
    func testMarkdownIncludesIssueSectionsSupportInfoAndActivityLog() {
        let bundle = IssueSupportBundle(
            supportInfo: Self.supportInfo(activityLogItemCount: 1),
            activityLogItems: [
                ActivityLogItem(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    createdAt: Date(timeIntervalSince1970: 0),
                    category: "llm",
                    detail: "missing-api-key"
                )
            ]
        )

        let markdown = bundle.markdown()

        XCTAssertTrue(markdown.contains("# Fluid Reader Issue"))
        XCTAssertTrue(markdown.contains("## What happened?"))
        XCTAssertTrue(markdown.contains("## Problem type"))
        XCTAssertTrue(markdown.contains("app"))
        XCTAssertTrue(markdown.contains("## Launch Rescue Snapshot"))
        XCTAssertTrue(markdown.contains("Auto trigger: No auto trigger recorded yet."))
        XCTAssertTrue(markdown.contains("Auto follow-up: No follow-up run recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."))
        XCTAssertTrue(markdown.contains("# Fluid Reader Support Info"))
        XCTAssertTrue(markdown.contains("log 1"))
        XCTAssertTrue(markdown.contains("Launch Pack Trend: No opportunities yet; first pressure card starts baseline."))
        XCTAssertTrue(markdown.contains("Launch Pack Mode Shifts: No mode transitions yet."))
        XCTAssertTrue(markdown.contains("Launch Pack Mode Momentum: Neutral."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Trigger: No auto trigger recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Trigger Time: No auto trigger time recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Follow-up: No follow-up run recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Follow-up Time: No auto trigger time recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Follow-up Coach: Baseline mode · run follow-up to seed outcomes."))
        XCTAssertTrue(markdown.contains("# Fluid Reader Activity Log"))
        XCTAssertTrue(markdown.contains("1970-01-01T00:00:00Z | llm | missing-api-key"))
    }

    func testMarkdownIncludesLaunchPackTrendSummaryForPressureContext() {
        let bundle = IssueSupportBundle(
            supportInfo: Self.supportInfo(
                activityLogItemCount: 0,
                pressureOpportunities: 5,
                pressureConversions: 3,
                pressureStreak: 2,
                pressureBestStreak: 4,
                pressureLastTone: "Watch",
                modeTransitionCount: 3,
                modeTransitionLatest: "cooling-to-rebuilding",
                modeMomentumStreak: 2,
                launchRescueAutoTriggerReason: "urgency-high",
                launchRescueAutoTriggerAt: Date(timeIntervalSince1970: 1_700_000_000),
                launchRescueAutoFollowupReason: "urgency-high",
                launchRescueAutoFollowupCommandID: "run-fame-next-move-copy-drafts",
                launchRescueAutoFollowupAt: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            activityLogItems: []
        )

        let markdown = bundle.markdown()

        XCTAssertTrue(markdown.contains("Launch Pack Pressure: wins 3/5 (60%), streak x2, best x4, tone Watch"))
        XCTAssertTrue(markdown.contains("Launch Pack Trend: Rebuilding at x2; 2 from best x4."))
        XCTAssertTrue(markdown.contains("Launch Pack Mode Shifts: 3 total; latest Cooling -> Rebuilding."))
        XCTAssertTrue(markdown.contains("Launch Pack Mode Momentum: Upshift streak x2."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Trigger: Urgency High escalation."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Trigger Time: 2023-11-14T22:13:20Z"))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Follow-up: Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation."))
        XCTAssertTrue(markdown.contains("Launch Rescue Auto Follow-up Time: 2023-11-14T22:13:20Z"))
        XCTAssertTrue(markdown.contains("Auto trigger: Urgency High escalation."))
        XCTAssertTrue(markdown.contains("Auto trigger time: 2023-11-14T22:13:20Z"))
        XCTAssertTrue(markdown.contains("Auto follow-up: Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation."))
        XCTAssertTrue(markdown.contains("Auto follow-up time: 2023-11-14T22:13:20Z"))
        XCTAssertTrue(markdown.contains("Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet."))
        XCTAssertTrue(markdown.contains("Launch Rescue Follow-up Coach: Baseline mode · run follow-up to seed outcomes."))
    }

    func testMarkdownHandlesEmptyActivityLog() {
        let bundle = IssueSupportBundle(
            supportInfo: Self.supportInfo(activityLogItemCount: 0),
            activityLogItems: []
        )

        let markdown = bundle.markdown()

        XCTAssertTrue(markdown.contains("## Activity log"))
        XCTAssertTrue(markdown.contains("No activity log events yet."))
    }

    func testMarkdownLimitsActivityLogForIssuePaste() {
        let items = (0..<25).map { index in
            ActivityLogItem(
                id: UUID(),
                createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
                category: "command",
                detail: "event-\(index)"
            )
        }
        let bundle = IssueSupportBundle(
            supportInfo: Self.supportInfo(activityLogItemCount: items.count),
            activityLogItems: items
        )

        let markdown = bundle.markdown()

        XCTAssertTrue(markdown.contains("event-0"))
        XCTAssertTrue(markdown.contains("event-19"))
        XCTAssertFalse(markdown.contains("event-20"))
        XCTAssertTrue(markdown.contains("5 older safe events not included"))
    }

    func testMarkdownWarnsAgainstPrivateData() {
        let bundle = IssueSupportBundle(
            supportInfo: Self.supportInfo(activityLogItemCount: 0),
            activityLogItems: []
        )

        let markdown = bundle.markdown()

        XCTAssertTrue(markdown.contains("No API keys or private content."))
        XCTAssertFalse(markdown.contains("selected text:"))
        XCTAssertFalse(markdown.contains("sk-test"))
        XCTAssertFalse(markdown.contains("https://internal.example"))
    }

    private static func supportInfo(
        activityLogItemCount: Int,
        pressureOpportunities: Int = 0,
        pressureConversions: Int = 0,
        pressureStreak: Int = 0,
        pressureBestStreak: Int = 0,
        pressureLastTone: String = "None",
        modeTransitionCount: Int = 0,
        modeTransitionLatest: String = "none-to-none",
        modeMomentumStreak: Int = 0,
        launchRescueAutoTriggerReason: String = "none",
        launchRescueAutoTriggerAt: Date? = nil,
        launchRescueAutoFollowupReason: String = "none",
        launchRescueAutoFollowupCommandID: String = "none",
        launchRescueAutoFollowupAt: Date? = nil
    ) -> SupportInfoReport {
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
            activityLogItemCount: activityLogItemCount,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            bestChannelLaunchPackPressureOpportunities: pressureOpportunities,
            bestChannelLaunchPackPressureConversions: pressureConversions,
            bestChannelLaunchPackPressureConversionStreak: pressureStreak,
            bestChannelLaunchPackPressureBestStreak: pressureBestStreak,
            bestChannelLaunchPackPressureLastTone: pressureLastTone,
            bestChannelLaunchPackPressureModeTransitionCount: modeTransitionCount,
            bestChannelLaunchPackPressureModeTransitionLatest: modeTransitionLatest,
            bestChannelLaunchPackPressureModeMomentumStreak: modeMomentumStreak,
            launchRescueBurstLastAutoTriggerReason: launchRescueAutoTriggerReason,
            launchRescueBurstLastAutoTriggerAt: launchRescueAutoTriggerAt,
            launchRescueBurstLastFollowupReason: launchRescueAutoFollowupReason,
            launchRescueBurstLastFollowupCommandID: launchRescueAutoFollowupCommandID,
            launchRescueBurstLastFollowupAt: launchRescueAutoFollowupAt
        )
    }
}
