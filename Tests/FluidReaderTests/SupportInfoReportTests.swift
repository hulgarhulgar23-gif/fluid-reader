import XCTest
@testable import FluidReader

final class SupportInfoReportTests: XCTestCase {
    func testMarkdownIncludesUsefulSafeFields() {
        let report = SupportInfoReport(
            appVersion: "1.2.3",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "en-US",
            llmEnabled: true,
            llmProvider: "OpenAI",
            llmModel: "gpt-test",
            apiKeySet: true,
            readAfterPick: true,
            autoCopyNewText: true,
            autoPastePickedText: true,
            autoPasteLLMAnswers: true,
            saveRecentItems: false,
            saveClipboardHistory: true,
            readerAlwaysOnTop: true,
            launchAtLoginState: .enabled,
            screenRecordingAllowed: true,
            accessibilityTrusted: false,
            recentItemCount: 3,
            snippetItemCount: 2,
            quickLinkItemCount: 4,
            clipboardHistoryItemCount: 5,
            activityLogItemCount: 7,
            hasReaderText: true,
            hasReaderImage: false,
            hasAnswer: true,
            hasError: true
        )

        let markdown = report.markdown()

        XCTAssertTrue(markdown.contains("# Fluid Reader Support Info"))
        XCTAssertTrue(markdown.contains("- Version: 1.2.3"))
        XCTAssertTrue(markdown.contains("- macOS: macOS 14.0"))
        XCTAssertTrue(markdown.contains("- OCR: en-US"))
        XCTAssertTrue(markdown.contains("- LLM: Yes, OpenAI, gpt-test, key Yes"))
        XCTAssertTrue(markdown.contains("- Flow: read Yes, copy Yes, paste pick Yes, paste answer Yes"))
        XCTAssertTrue(markdown.contains("- Saved: recent No, clipboard Yes, pinned Yes"))
        XCTAssertTrue(markdown.contains("- Counts: recent 3, snippets 2, links 4, clipboard 5, log 7"))
        XCTAssertTrue(markdown.contains("- Reader: text Yes, image No, answer Yes, error Yes"))
        XCTAssertTrue(markdown.contains("- Launch Pack Pressure: wins 0/0 (0%), streak x0, best x0, tone None"))
        XCTAssertTrue(markdown.contains("- Launch Pack Trend: No opportunities yet; first pressure card starts baseline."))
        XCTAssertTrue(markdown.contains("- Launch Pack Mode Shifts: No mode transitions yet."))
        XCTAssertTrue(markdown.contains("- Launch Pack Mode Momentum: Neutral."))
        XCTAssertTrue(markdown.contains("- Exceptional Loop Outcomes: wins 0/0 (0%), win streak x0, recovery streak x0, last focus None, last run No auto trigger time recorded yet."))
        XCTAssertTrue(markdown.contains("- Exceptional Loop Trend: Outcome trend: warming up."))
        XCTAssertTrue(markdown.contains("- Exceptional Loop Top Win Lane: none yet"))
        XCTAssertTrue(markdown.contains("- Exceptional Loop Top Recovery Lane: none yet"))
        XCTAssertTrue(markdown.contains("- Exceptional Loop Recovery Next Action: none yet"))
        XCTAssertTrue(markdown.contains("- Exceptional Loop Auto Recovery Lane: Auto recovery lane: Not armed (no eligible lane telemetry yet)."))
        XCTAssertTrue(
            markdown.contains(
                "- Exceptional Loop Auto Recovery Recommendation: \(AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(recommendation: nil, currentMissesRequired: AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired, currentFailureStreakRequired: AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired, currentCooldownMinutes: AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes))"
            )
        )
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Trigger: No auto trigger recorded yet."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Trigger Time: No auto trigger time recorded yet."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Follow-up: No follow-up run recorded yet."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Follow-up Time: No auto trigger time recorded yet."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Follow-up Route Decision: Default route Run Launch Control Brief."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Coach: Baseline mode · run follow-up to seed outcomes."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."))
        XCTAssertTrue(markdown.contains("- Login: On"))
        XCTAssertTrue(markdown.contains("- Screen Recording: Yes"))
        XCTAssertTrue(markdown.contains("- Accessibility: No"))
    }

    func testMarkdownStatesSensitiveDataIsNotIncluded() {
        let report = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false
        )

        let markdown = report.markdown()

        XCTAssertTrue(markdown.contains("No API keys or private content."))
        XCTAssertFalse(markdown.contains("selected text:"))
        XCTAssertFalse(markdown.contains("sk-test"))
        XCTAssertFalse(markdown.contains("https://internal.example"))
    }

    func testLaunchRescueSnapshotMarkdownIncludesBaselineStatusLines() {
        let report = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false
        )

        let snapshot = report.launchRescueSnapshotMarkdown()

        XCTAssertTrue(snapshot.contains("- Auto trigger: No auto trigger recorded yet."))
        XCTAssertTrue(snapshot.contains("- Auto trigger time: No auto trigger time recorded yet."))
        XCTAssertTrue(snapshot.contains("- Auto follow-up: No follow-up run recorded yet."))
        XCTAssertTrue(snapshot.contains("- Auto follow-up time: No auto trigger time recorded yet."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Auto Follow-up Route Decision: Default route Run Launch Control Brief."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Follow-up Coach: Baseline mode · run follow-up to seed outcomes."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."))
    }

    func testLaunchRescueSnapshotMarkdownIncludesContextualTelemetry() {
        let report = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            launchRescueBurstLastAutoTriggerReason: "urgency-high",
            launchRescueBurstLastAutoTriggerAt: Date(timeIntervalSince1970: 1_700_000_000),
            launchRescueBurstLastFollowupReason: "urgency-high",
            launchRescueBurstLastFollowupCommandID: "run-fame-next-move-copy-drafts",
            launchRescueBurstLastFollowupAt: Date(timeIntervalSince1970: 1_700_000_000),
            launchRescueFollowupRouteDecisionStatusTitle: "Launch Rescue Auto Follow-up Route Decision: Default route Run Fame Next Move + Copy Draft Pack.",
            launchRescueFollowupOutcomeScoreboardStatusTitle: "Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago.",
            launchRescueFollowupOutcomeCoachStatusTitle: "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago.",
            launchRescueFollowupOutcomeMomentumStatusTitle: "Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →"
        )

        let snapshot = report.launchRescueSnapshotMarkdown()

        XCTAssertTrue(snapshot.contains("- Auto trigger: Urgency High escalation."))
        XCTAssertTrue(snapshot.contains("- Auto trigger time: 2023-11-14T22:13:20Z"))
        XCTAssertTrue(snapshot.contains("- Auto follow-up: Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation."))
        XCTAssertTrue(snapshot.contains("- Auto follow-up time: 2023-11-14T22:13:20Z"))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Auto Follow-up Route Decision: Default route Run Fame Next Move + Copy Draft Pack."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."))
        XCTAssertTrue(snapshot.contains("- Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →"))
    }

    func testLaunchRescueSnapshotMarkdownUsesCanonicalAppDelegateFormatter() {
        let triggerAt = Date(timeIntervalSince1970: 1_700_000_000)
        let report = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            launchRescueBurstLastAutoTriggerReason: "urgency-high",
            launchRescueBurstLastAutoTriggerAt: triggerAt,
            launchRescueBurstLastFollowupReason: "urgency-high",
            launchRescueBurstLastFollowupCommandID: "run-fame-next-move-copy-drafts",
            launchRescueBurstLastFollowupAt: triggerAt,
            launchRescueFollowupRouteDecisionStatusTitle: "Launch Rescue Auto Follow-up Route Decision: Default route Run Fame Next Move + Copy Draft Pack.",
            launchRescueAutoSelfHealStatusTitle: "Launch Rescue Auto Self-Heal: No self-heal telemetry recorded yet for Urgency High escalation.",
            launchRescueFollowupOutcomeScoreboardStatusTitle: "Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago.",
            launchRescueFollowupOutcomeCoachStatusTitle: "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago.",
            launchRescueFollowupOutcomeMomentumStatusTitle: "Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →"
        )

        XCTAssertEqual(
            report.launchRescueSnapshotMarkdown(),
            AppDelegate.launchRescueSnapshotMarkdown(
                autoTriggerSummary: AppDelegate.launchRescueAutoTriggerSummary("urgency-high"),
                autoTriggerAtSummary: AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(triggerAt),
                autoFollowupSummary: AppDelegate.launchRescueAutoFollowupRunSummary(
                    commandID: "run-fame-next-move-copy-drafts",
                    reasonToken: "urgency-high"
                ),
                autoFollowupAtSummary: AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(triggerAt),
                followupRouteDecisionStatusTitle: "Launch Rescue Auto Follow-up Route Decision: Default route Run Fame Next Move + Copy Draft Pack.",
                autoSelfHealStatusTitle: "Launch Rescue Auto Self-Heal: No self-heal telemetry recorded yet for Urgency High escalation.",
                followupScoreboardStatusTitle: "Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago.",
                followupCoachStatusTitle: "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago.",
                followupMomentumStatusTitle: "Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →"
            )
        )
    }

    func testMarkdownLaunchPackTrendSummariesCoverBuildRebuildAndCoolingStates() {
        let buildingReport = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            bestChannelLaunchPackPressureOpportunities: 4,
            bestChannelLaunchPackPressureConversions: 4,
            bestChannelLaunchPackPressureConversionStreak: 4,
            bestChannelLaunchPackPressureBestStreak: 4,
            bestChannelLaunchPackPressureLastTone: "Alert"
        )

        XCTAssertTrue(
            buildingReport.markdown().contains(
                "- Launch Pack Trend: Building with active x4; next target x5."
            )
        )

        let rebuildingReport = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            bestChannelLaunchPackPressureOpportunities: 8,
            bestChannelLaunchPackPressureConversions: 5,
            bestChannelLaunchPackPressureConversionStreak: 2,
            bestChannelLaunchPackPressureBestStreak: 5,
            bestChannelLaunchPackPressureLastTone: "Watch"
        )

        XCTAssertTrue(
            rebuildingReport.markdown().contains(
                "- Launch Pack Trend: Rebuilding at x2; 3 from best x5."
            )
        )

        let coolingReport = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            bestChannelLaunchPackPressureOpportunities: 8,
            bestChannelLaunchPackPressureConversions: 5,
            bestChannelLaunchPackPressureConversionStreak: 0,
            bestChannelLaunchPackPressureBestStreak: 5,
            bestChannelLaunchPackPressureLastTone: "Watch"
        )

        XCTAssertTrue(
            coolingReport.markdown().contains(
                "- Launch Pack Trend: Cooling after last miss; recover toward best x5."
            )
        )
    }

    func testMarkdownLaunchPackModeShiftSummaryFormatsCountAndLatestTransition() {
        let report = SupportInfoReport(
            appVersion: "Development",
            macOSVersion: "macOS 14.0",
            ocrLanguage: "Auto",
            llmEnabled: false,
            llmProvider: "OpenAI",
            llmModel: "Default",
            apiKeySet: false,
            readAfterPick: false,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            readerAlwaysOnTop: false,
            launchAtLoginState: .disabled,
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            recentItemCount: 0,
            snippetItemCount: 0,
            quickLinkItemCount: 0,
            clipboardHistoryItemCount: 0,
            activityLogItemCount: 0,
            hasReaderText: false,
            hasReaderImage: false,
            hasAnswer: false,
            hasError: false,
            bestChannelLaunchPackPressureOpportunities: 8,
            bestChannelLaunchPackPressureConversions: 5,
            bestChannelLaunchPackPressureConversionStreak: 2,
            bestChannelLaunchPackPressureBestStreak: 5,
            bestChannelLaunchPackPressureLastTone: "Watch",
            bestChannelLaunchPackPressureModeTransitionCount: 4,
            bestChannelLaunchPackPressureModeTransitionLatest: "rebuilding-to-compounding",
            bestChannelLaunchPackPressureModeMomentumStreak: 3,
            launchRescueBurstLastAutoTriggerReason: "momentum-alert"
        )

        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Pack Mode Shifts: 4 total; latest Rebuilding -> Compounding."
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Pack Mode Momentum: Upshift streak x3."
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Trigger: Cooldown momentum alert streak."
            )
        )
    }

    @MainActor
    func testMakeReadsLaunchRescueAutoTriggerReasonFromDefaults() {
        let defaults = makeDefaults()
        defaults.set(
            "  MOMENTUM-ALERT  ",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(report.launchRescueBurstLastAutoTriggerReason, "momentum-alert")
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Trigger: Cooldown momentum alert streak."
            )
        )
    }

    @MainActor
    func testMakeNormalizesUnknownLaunchRescueAutoTriggerReasonToNone() {
        let defaults = makeDefaults()
        defaults.set(
            "unexpected-token",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(report.launchRescueBurstLastAutoTriggerReason, "none")
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Trigger: No auto trigger recorded yet."
            )
        )
    }

    @MainActor
    func testMakeParsesLaunchRescueAutoTriggerReasonFromActivityDetailContract() {
        let defaults = makeDefaults()
        defaults.set(
            "  RUN-FAME-LAUNCH-RESCUE-BURST-AUTO-TRIGGER-URGENCY-CRITICAL  ",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(report.launchRescueBurstLastAutoTriggerReason, "urgency-critical")
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Trigger: Urgency Critical escalation."
            )
        )
    }

    @MainActor
    func testMakeReadsLaunchRescueAutoTriggerAtFromDefaults() {
        let defaults = makeDefaults()
        let triggerAt = Date(timeIntervalSince1970: 1_700_000_000)
        defaults.set(
            triggerAt.timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(report.launchRescueBurstLastAutoTriggerAt, triggerAt)
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Trigger Time: 2023-11-14T22:13:20Z"
            )
        )
    }

    @MainActor
    func testMakeNormalizesInvalidLaunchRescueAutoTriggerAtToUnknown() {
        let defaults = makeDefaults()
        defaults.set(
            "not-a-timestamp",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertNil(report.launchRescueBurstLastAutoTriggerAt)
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Trigger Time: No auto trigger time recorded yet."
            )
        )
    }

    @MainActor
    func testMakeReadsLaunchRescueAutoFollowupTelemetryFromDefaults() {
        let defaults = makeDefaults()
        defaults.set(
            "  MOMENTUM-ALERT  ",
            forKey: AppDefaults.fameLaunchRescueBurstLastFollowupReasonKey
        )
        defaults.set(
            " run-fame-launch-rescue-burst ",
            forKey: AppDefaults.fameLaunchRescueBurstLastFollowupCommandIDKey
        )
        defaults.set(
            1_700_000_000.0,
            forKey: AppDefaults.fameLaunchRescueBurstLastFollowupAtKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(report.launchRescueBurstLastFollowupReason, "momentum-alert")
        XCTAssertEqual(report.launchRescueBurstLastFollowupCommandID, "run-fame-launch-rescue-burst")
        XCTAssertEqual(report.launchRescueBurstLastFollowupAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Follow-up: Run Launch Rescue Burst · reason: Cooldown momentum alert streak."
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Follow-up Time: 2023-11-14T22:13:20Z"
            )
        )
    }

    @MainActor
    func testMakeDerivesLaunchRescueAutoSelfHealStatusFromRecentMatchingActivityLog() {
        let defaults = makeDefaults()
        defaults.set(
            "urgency-critical",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )
        let selfHealDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "healed"
        )
        defaults.set(
            try? JSONEncoder().encode([
                ActivityLogItem(
                    id: UUID(),
                    createdAt: Date().addingTimeInterval(-90),
                    category: "support",
                    detail: selfHealDetail
                )
            ]),
            forKey: ActivityLogStore.defaultStorageKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Launch Rescue Auto Self-Heal: Recovered missing artifacts"
            )
        )
        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Route: Run Launch Rescue Burst"
            )
        )
        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Reason: Urgency Critical escalation."
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Auto Self-Heal: Recovered missing artifacts"
            )
        )
    }

    @MainActor
    func testMakeDerivesLaunchRescueAutoSelfHealStatusAsStaleForMatchingOldActivityLog() {
        let defaults = makeDefaults()
        defaults.set(
            "urgency-critical",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )
        let selfHealDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "failed"
        )
        defaults.set(
            try? JSONEncoder().encode([
                ActivityLogItem(
                    id: UUID(),
                    createdAt: Date().addingTimeInterval(-(40 * 60)),
                    category: "support",
                    detail: selfHealDetail
                )
            ]),
            forKey: ActivityLogStore.defaultStorageKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Launch Rescue Auto Self-Heal: Last matching check is stale"
            )
        )
        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Route: Run Launch Rescue Burst"
            )
        )
        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Reason: Urgency Critical escalation."
            )
        )
    }

    @MainActor
    func testMakeDerivesLaunchRescueAutoSelfHealStatusAsReasonWaitWhenLatestActivityMismatches() {
        let defaults = makeDefaults()
        defaults.set(
            "urgency-critical",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )
        let selfHealDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-high",
            routeCommandID: "run-fame-next-move-copy-drafts",
            outcome: "ready"
        )
        defaults.set(
            try? JSONEncoder().encode([
                ActivityLogItem(
                    id: UUID(),
                    createdAt: Date().addingTimeInterval(-60),
                    category: "support",
                    detail: selfHealDetail
                )
            ]),
            forKey: ActivityLogStore.defaultStorageKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "Launch Rescue Auto Self-Heal: Latest check tracked Urgency High escalation."
            )
        )
        XCTAssertTrue(
            report.launchRescueAutoSelfHealStatusTitle.contains(
                "waiting for Urgency Critical escalation."
            )
        )
    }

    @MainActor
    func testMakeReadsLaunchRescueFollowupOutcomeScoreboardFromDefaults() {
        let defaults = makeDefaults()
        let now = Date()
        let lastOutcomeAt = now.addingTimeInterval(-(20 * 60))
        let lastFailureAt = now.addingTimeInterval(-(3 * 60 * 60))
        let history = [
            AppDelegate.LaunchRescueFollowupOutcomeSample(
                recordedAt: now.addingTimeInterval(-(20 * 60)).timeIntervalSince1970,
                wasSuccess: true
            ),
            AppDelegate.LaunchRescueFollowupOutcomeSample(
                recordedAt: now.addingTimeInterval(-(2 * 60 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.LaunchRescueFollowupOutcomeSample(
                recordedAt: now.addingTimeInterval(-(32 * 60 * 60)).timeIntervalSince1970,
                wasSuccess: true
            )
        ]
        defaults.set(
            7,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        )
        defaults.set(
            5,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        )
        defaults.set(
            lastOutcomeAt.timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        )
        defaults.set(
            lastOutcomeAt.timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey
        )
        defaults.set(
            lastFailureAt.timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey
        )
        defaults.set(
            try? JSONEncoder().encode(history),
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 5/7 success (71%)"
            )
        )
        XCTAssertTrue(
            report.launchRescueFollowupOutcomeScoreboardStatusTitle.contains("Freshness ")
        )
        XCTAssertTrue(
            report.launchRescueFollowupOutcomeCoachStatusTitle.contains(
                "Launch Rescue Follow-up Coach: Stable lane · keep route and ship first block fast · Freshness "
            )
        )
        XCTAssertEqual(
            report.launchRescueFollowupOutcomeMomentumStatusTitle,
            "Launch Rescue Follow-up Momentum: Stable · CD 30m · Steady →"
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Follow-up Momentum: Stable · CD 30m · Steady →"
            )
        )
    }

    @MainActor
    func testMakeReadsExceptionalLoopOutcomeStatusFromDefaults() {
        let defaults = makeDefaults()
        defaults.set(5, forKey: AppDefaults.fameExceptionalLoopOutcomeTotalCountKey)
        defaults.set(3, forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey)
        defaults.set(2, forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey)
        defaults.set(0, forKey: AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey)
        defaults.set(
            "run-fame-cadence-autopilot-loop",
            forKey: AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey
        )
        defaults.set(
            Date().addingTimeInterval(-(7 * 60)).timeIntervalSince1970,
            forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(
            report.fameExceptionalLoopOutcomeStatusTitle,
            "Outcome trend: win lane x2 · 60% hit rate."
        )
        XCTAssertTrue(
            report.fameExceptionalLoopOutcomeSummary.contains(
                "wins 3/5 (60%), win streak x2, recovery streak x0"
            )
        )
        XCTAssertTrue(
            report.fameExceptionalLoopOutcomeSummary.contains(
                "last focus Run Cadence Autopilot Loop"
            )
        )
        XCTAssertTrue(
            report.fameExceptionalLoopOutcomeSummary.contains(
                "last run "
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Trend: Outcome trend: win lane x2 · 60% hit rate."
            )
        )
    }

    @MainActor
    func testMakeReadsExceptionalLoopLaneSummariesFromCommandHistory() {
        let defaults = makeDefaults()
        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(9 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: now.addingTimeInterval(-(6 * 60)).timeIntervalSince1970,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(3 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: now.addingTimeInterval(-(1 * 60)).timeIntervalSince1970,
                wasSuccess: true
            )
        ]
        defaults.set(
            try? JSONEncoder().encode(history),
            forKey: AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(
            report.fameExceptionalLoopTopWinLaneSummary,
            "\(AppDelegate.fameExceptionalLoopCommandTitle("run-fame-cadence-autopilot-loop")) 3/3 (100%), streak x3"
        )
        XCTAssertEqual(
            report.fameExceptionalLoopTopRecoveryLaneSummary,
            "\(AppDelegate.fameExceptionalLoopCommandTitle("run-fame-next-move-copy-drafts")) misses 2/2, streak x2"
        )
        XCTAssertEqual(
            report.fameExceptionalLoopRecoveryNextActionSummary,
            "\(AppDelegate.fameExceptionalLoopCommandTitle("run-fame-next-move-copy-drafts")) (2/2 misses, streak x2)"
        )
        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneStatusSummary,
            "Auto recovery lane: Not armed (2/2 misses, streak x2)."
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Top Win Lane: \(report.fameExceptionalLoopTopWinLaneSummary)"
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Top Recovery Lane: \(report.fameExceptionalLoopTopRecoveryLaneSummary)"
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Recovery Next Action: \(report.fameExceptionalLoopRecoveryNextActionSummary)"
            )
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Auto Recovery Lane: \(report.fameExceptionalLoopAutoRecoveryLaneStatusSummary)"
            )
        )
        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        )
        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Auto Recovery Tuning: arms at \(report.fameExceptionalLoopAutoRecoveryLaneMissesRequired)+ misses and streak x\(report.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired), cooldown \(report.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes)m"
            )
        )
        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary,
            "Need at least 3 recovery-lane attempts before adaptive tuning can calibrate (current 3+ misses, streak x2, cooldown 20m)."
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Auto Recovery Recommendation: \(report.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary)"
            )
        )
    }

    @MainActor
    func testMakeReadsExceptionalLoopAutoRecoveryLaneCooldownStatusFromDefaults() {
        let defaults = makeDefaults()
        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(9 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(6 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(
            try? JSONEncoder().encode(history),
            forKey: AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        )
        defaults.set(
            now.addingTimeInterval(-60).timeIntervalSince1970,
            forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneStatusSummary,
            "Auto recovery lane: Cooling down 19m before Run Next Move + Copy Draft Pack."
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Auto Recovery Lane: \(report.fameExceptionalLoopAutoRecoveryLaneStatusSummary)"
            )
        )
        XCTAssertEqual(
            report.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary,
            "Suggested 2+ misses, streak x1, cooldown 10m from telemetry (current 3+ misses, streak x2, cooldown 20m). Lane is slipping (3/3 misses, streak x3); lower arming thresholds."
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Exceptional Loop Auto Recovery Recommendation: \(report.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary)"
            )
        )
    }

    @MainActor
    func testMakeReadsLaunchRescueFollowupCoachCooldownStateFromDefaults() {
        let defaults = makeDefaults()
        let now = Date()
        let lastOutcomeAt = now.addingTimeInterval(-(12 * 60))
        let history = [
            AppDelegate.LaunchRescueFollowupOutcomeSample(
                recordedAt: now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.LaunchRescueFollowupOutcomeSample(
                recordedAt: now.addingTimeInterval(-(20 * 60)).timeIntervalSince1970,
                wasSuccess: true
            ),
            AppDelegate.LaunchRescueFollowupOutcomeSample(
                recordedAt: now.addingTimeInterval(-(40 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(
            "urgency-high",
            forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        )
        defaults.set(
            6,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        )
        defaults.set(
            2,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        )
        defaults.set(
            lastOutcomeAt.timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        )
        defaults.set(
            2,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        )
        defaults.set(
            now.addingTimeInterval(-(5 * 60)).timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
        )
        defaults.set(
            20,
            forKey: AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
        )
        defaults.set(
            try? JSONEncoder().encode(history),
            forKey: AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        )

        let report = SupportInfoReport.make(
            settings: SettingsStore.shared,
            state: ReaderState(defaults: defaults),
            defaults: defaults
        )

        XCTAssertTrue(
            report.launchRescueFollowupOutcomeCoachStatusTitle.contains(
                "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down "
            )
        )
        XCTAssertTrue(
            report.launchRescueFollowupOutcomeCoachStatusTitle.contains(" of 20m after ")
        )
        XCTAssertTrue(
            report.markdown().contains(
                "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down "
            )
        )
        XCTAssertTrue(
            report.launchRescueFollowupOutcomeMomentumStatusTitle.contains(
                "Launch Rescue Follow-up Momentum: Recovery x2 · CD "
            )
        )
        XCTAssertTrue(
            report.launchRescueFollowupOutcomeMomentumStatusTitle.contains("/20m · Accelerating ↓")
        )
        XCTAssertTrue(
            report.markdown().contains(
                "- Launch Rescue Follow-up Momentum: Recovery x2 · CD "
            )
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "FluidReaderSupportInfoReportTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
