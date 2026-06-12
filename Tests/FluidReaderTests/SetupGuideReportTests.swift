import XCTest
@testable import FluidReader

final class SetupGuideReportTests: XCTestCase {
    func testMarkdownIncludesShortcutsPermissionsAndUsefulCommands() {
        let report = SetupGuideReport(
            screenRecordingAllowed: true,
            accessibilityTrusted: false,
            llmEnabled: false,
            autoCopyNewText: true,
            autoPastePickedText: true,
            autoPasteLLMAnswers: true,
            saveRecentItems: true,
            saveClipboardHistory: true,
            launchAtLoginState: .disabled,
            savedItemCount: 14,
            activityLogItemCount: 9
        )

        let markdown = report.markdown()

        XCTAssertTrue(markdown.contains("# Fluid Reader Setup Guide"))
        XCTAssertTrue(markdown.contains("⌥⇧Space: Commands"))
        XCTAssertTrue(markdown.contains("⌥⌘O: Auto Bundle status"))
        XCTAssertTrue(markdown.contains("⌥⌘L: Launch Rescue Auto status"))
        XCTAssertTrue(markdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("- Screen Recording: Yes"))
        XCTAssertTrue(markdown.contains("- Accessibility: No"))
        XCTAssertTrue(markdown.contains("- LLM: off"))
        XCTAssertTrue(markdown.contains("- Auto-copy: on"))
        XCTAssertTrue(markdown.contains("- Auto-paste pick: on"))
        XCTAssertTrue(markdown.contains("- Auto-paste answer: on"))
        XCTAssertTrue(markdown.contains("- Recent items: on"))
        XCTAssertTrue(markdown.contains("- Clipboard history: on"))
        XCTAssertTrue(markdown.contains("- Launch at login: Off -"))
        XCTAssertTrue(markdown.contains("Does not open at sign-in."))
        XCTAssertTrue(markdown.contains("Read Selected Text"))
        XCTAssertTrue(markdown.contains("Search Web"))
        XCTAssertTrue(markdown.contains("Ask Anything"))
        XCTAssertTrue(markdown.contains("## Share"))
        XCTAssertTrue(markdown.contains("Saved 14 items, 9 safe events."))
        XCTAssertTrue(markdown.contains("#productivity #opensource"))
    }

    func testMarkdownDoesNotIncludePrivateReaderContent() {
        let report = SetupGuideReport(
            screenRecordingAllowed: false,
            accessibilityTrusted: false,
            llmEnabled: true,
            autoCopyNewText: false,
            autoPastePickedText: false,
            autoPasteLLMAnswers: false,
            saveRecentItems: false,
            saveClipboardHistory: false,
            launchAtLoginState: .enabled,
            savedItemCount: 0,
            activityLogItemCount: 0
        )

        let markdown = report.markdown()

        XCTAssertTrue(markdown.contains("No API keys or private content."))
        XCTAssertFalse(markdown.contains("selected text:"))
        XCTAssertFalse(markdown.contains("sk-test"))
        XCTAssertFalse(markdown.contains("private recent item"))
    }

    func testWinRecapClampsNegativeCountsAndUsesStyleZero() {
        let recap = SetupGuideReport.winRecap(savedItemCount: -1, activityLogItemCount: -2)

        XCTAssertTrue(recap.contains("Fluid Reader win"))
        XCTAssertTrue(recap.contains("Saved items: 0"))
        XCTAssertTrue(recap.contains("Safe events: 0"))
    }

    func testWinRecapUsesStyleOne() {
        let recap = SetupGuideReport.winRecap(savedItemCount: 1, activityLogItemCount: 0)

        XCTAssertTrue(recap.contains("Fluid Reader on macOS."))
        XCTAssertTrue(recap.contains("Saved 1, events 0."))
    }

    func testWinRecapUsesStyleTwo() {
        let recap = SetupGuideReport.winRecap(savedItemCount: 2, activityLogItemCount: 0)

        XCTAssertTrue(recap.contains("Local-first Fluid Reader flow."))
        XCTAssertTrue(recap.contains("Saved 2 items, 0 safe events."))
    }

    func testWinRecapPackIncludesThreeVariants() {
        let recapPack = SetupGuideReport.winRecapPack(savedItemCount: 4, activityLogItemCount: 5)

        XCTAssertTrue(recapPack.contains("# Fluid Reader Win Recap Pack"))
        XCTAssertTrue(recapPack.contains("## Variant 1"))
        XCTAssertTrue(recapPack.contains("## Variant 2"))
        XCTAssertTrue(recapPack.contains("## Variant 3"))
        XCTAssertTrue(recapPack.contains("Saved items: 4"))
        XCTAssertTrue(recapPack.contains("Saved 4, events 5."))
        XCTAssertTrue(recapPack.contains("Saved 4 items, 5 safe events."))
    }

    func testLaunchKitIncludesChannelSectionsAndProof() {
        let launchKit = SetupGuideReport.launchKit(savedItemCount: 6, activityLogItemCount: 4)

        XCTAssertTrue(launchKit.contains("# Fluid Reader Launch Kit"))
        XCTAssertTrue(launchKit.contains("## Positioning"))
        XCTAssertTrue(launchKit.contains("## Hooks"))
        XCTAssertTrue(launchKit.contains("## X Post"))
        XCTAssertTrue(launchKit.contains("## LinkedIn Post"))
        XCTAssertTrue(launchKit.contains("## PH / IH Blurb"))
        XCTAssertTrue(launchKit.contains("## 7-Day Sprint"))
        XCTAssertTrue(launchKit.contains("D1-7:"))
        XCTAssertTrue(launchKit.contains("## KPI Targets"))
        XCTAssertTrue(launchKit.contains("- Clips: 4"))
        XCTAssertTrue(launchKit.contains("- Replies: 20"))
        XCTAssertTrue(launchKit.contains("- DMs: 10"))
        XCTAssertTrue(launchKit.contains("## 30s Demo"))
        XCTAssertTrue(launchKit.contains("## CTA"))
        XCTAssertTrue(launchKit.contains("Saved: 6, events: 4."))
        XCTAssertTrue(launchKit.contains("Momentum: 10."))
        XCTAssertTrue(launchKit.contains("⌥⇧Space"))
        XCTAssertTrue(launchKit.contains("#macOS #productivity #opensource"))
    }

    func testLaunchKitClampsNegativeCounts() {
        let launchKit = SetupGuideReport.launchKit(savedItemCount: -2, activityLogItemCount: -9)

        XCTAssertTrue(launchKit.contains("Saved: 0, events: 0."))
        XCTAssertTrue(launchKit.contains("Momentum: 1."))
        XCTAssertTrue(launchKit.contains("- Clips: 3"))
        XCTAssertTrue(launchKit.contains("- Replies: 10"))
        XCTAssertTrue(launchKit.contains("- DMs: 5"))
    }

    func testExperimentBoardIncludesRankingSignalsAndTargets() {
        let board = SetupGuideReport.experimentBoard(savedItemCount: 7, activityLogItemCount: 2)

        XCTAssertTrue(board.contains("# Fluid Reader Fame Board"))
        XCTAssertTrue(board.contains("## Snapshot"))
        XCTAssertTrue(board.contains("Saved 7, events 2, momentum 9, fame 19 (Spark)."))
        XCTAssertTrue(board.contains("## Top 5 Experiments"))
        XCTAssertTrue(board.contains("1) Activation Fix"))
        XCTAssertTrue(board.contains("Raise weekly events to 7."))
        XCTAssertTrue(board.contains("2) 30s Command Race"))
        XCTAssertTrue(board.contains("Goal: 3 clips."))
        XCTAssertTrue(board.contains("Goal: 13 replies + 3 demos."))
        XCTAssertTrue(board.contains("Ship daily; share via Copy Fame Board."))
    }

    func testExperimentBoardClampsCountsAndCanPrioritizeDistribution() {
        let clamped = SetupGuideReport.experimentBoard(savedItemCount: -3, activityLogItemCount: -1)
        XCTAssertTrue(clamped.contains("Saved 0, events 0, momentum 1, fame 3 (Spark)."))

        let distribution = SetupGuideReport.experimentBoard(savedItemCount: 3, activityLogItemCount: 6)
        XCTAssertTrue(distribution.contains("1) Distribution Remix"))
        XCTAssertTrue(distribution.contains("Ship 3 remixes + 13 replies."))
    }

    func testFameSprintIncludesScoreStageAndDailyTargets() {
        let sprint = SetupGuideReport.fameSprint(savedItemCount: 8, activityLogItemCount: 7)

        XCTAssertTrue(sprint.contains("# Fluid Reader Fame Sprint"))
        XCTAssertTrue(sprint.contains("Push to 28 fame points (Momentum)."))
        XCTAssertTrue(sprint.contains("Ship 5 clips, 19 replies, 15 proof moments this week."))
        XCTAssertTrue(sprint.contains("## 7-Day Cadence"))
        XCTAssertTrue(sprint.contains("## Board Snapshot"))
        XCTAssertTrue(sprint.contains("# Fluid Reader Fame Board"))
        XCTAssertTrue(sprint.contains("Saved 8, events 7, momentum 15, fame 28 (Momentum)."))
        XCTAssertTrue(sprint.contains("## Top 5 Experiments"))
    }

    func testFameSprintClampsNegativeCountsAndSupportsAuthorityStage() {
        let clamped = SetupGuideReport.fameSprint(savedItemCount: -4, activityLogItemCount: -2)
        XCTAssertTrue(clamped.contains("Push to 3 fame points (Spark)."))
        XCTAssertTrue(clamped.contains("Saved 0, events 0, momentum 1, fame 3 (Spark)."))
        XCTAssertTrue(clamped.contains("Ship daily; share via Copy Fame Board."))
    }

    func testFamePackIncludesRecapLaunchSprintAndPresets() {
        let pack = SetupGuideReport.famePack(
            savedItemCount: 5,
            activityLogItemCount: 3,
            cadenceExecutionKitCurrentStreak: 4,
            cadenceExecutionKitBestStreak: 7,
            primaryChannel: "YouTube",
            backupChannel: "Podcast"
        )

        XCTAssertTrue(pack.contains("# Fluid Reader Fame Pack"))
        XCTAssertTrue(pack.contains("Saved 5, events 3, momentum 8."))
        XCTAssertTrue(pack.contains("Cadence kit streak: x4 (best x7)."))
        XCTAssertTrue(pack.contains("# Fluid Reader Win Recap Pack"))
        XCTAssertTrue(pack.contains("# Fluid Reader Launch Kit"))
        XCTAssertTrue(pack.contains("# Fluid Reader Fame Sprint"))
        XCTAssertTrue(pack.contains("Fame command presets"))
        XCTAssertTrue(pack.contains("run-fame-sprint"))
        XCTAssertTrue(pack.contains("run-fame-sprint-snapshot"))
        XCTAssertTrue(pack.contains("run-fame-next-move"))
        XCTAssertTrue(pack.contains("run-fame-next-move-cadence-execution-kit"))
        XCTAssertTrue(pack.contains("run-fame-next-move-copy-drafts"))
        XCTAssertTrue(pack.contains("run-fame-weekly-rollup"))
        XCTAssertTrue(pack.contains("run-fame-24h-queue"))
        XCTAssertTrue(pack.contains("run-fame-command-center"))
        XCTAssertTrue(pack.contains("run-fame-daily-checkpoint"))
        XCTAssertTrue(pack.contains("run-fame-pulse-nudge"))
        XCTAssertTrue(pack.contains("open-latest-next-move-handoff"))
        XCTAssertTrue(pack.contains("open-latest-next-move-draft-pack"))
        XCTAssertTrue(pack.contains("copy-next-move-drafts"))
        XCTAssertTrue(pack.contains("copy-next-move-launch-now-sequence"))
        XCTAssertTrue(pack.contains("copy-next-move-cadence-execution-kit"))
        XCTAssertTrue(pack.contains("copy-next-move-cadence-post-queue"))
        XCTAssertTrue(pack.contains("copy-next-move-reply-ladder"))
        XCTAssertTrue(pack.contains("copy-next-move-cadence-post"))
        XCTAssertTrue(pack.contains("copy-next-move-x-draft"))
        XCTAssertTrue(pack.contains("copy-next-move-bluesky-draft"))
        XCTAssertTrue(pack.contains("copy-next-move-linkedin-draft"))
        XCTAssertTrue(pack.contains("copy-next-move-cadence-step"))
        XCTAssertTrue(pack.contains("open-fame-snapshot-folder"))
        XCTAssertTrue(pack.contains("copy-founder-command-presets"))
        XCTAssertTrue(pack.contains(#"--primary-channel "YouTube" --backup-channel "Podcast""#))
    }

    func testFamePackClampsNegativeCounts() {
        let pack = SetupGuideReport.famePack(savedItemCount: -7, activityLogItemCount: -2)

        XCTAssertTrue(pack.contains("Saved 0, events 0, momentum 1."))
        XCTAssertTrue(pack.contains("Cadence kit streak: not started."))
        XCTAssertTrue(pack.contains("Push to 3 fame points (Spark)."))
        XCTAssertTrue(pack.contains("Saved: 0, events: 0."))
    }

    func testFameSprintTodayUsesMondayDayOneMission() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 8, hour: 10))!

        let today = SetupGuideReport.fameSprintToday(
            savedItemCount: 8,
            activityLogItemCount: 7,
            now: date,
            calendar: calendar
        )

        XCTAssertTrue(today.contains("# Fluid Reader Fame Sprint Today"))
        XCTAssertTrue(today.contains("Date: 2026-06-08 (Day 1)"))
        XCTAssertTrue(today.contains("Stage: Momentum"))
        XCTAssertTrue(today.contains("Score target: 28"))
        XCTAssertTrue(today.contains("Day 1: Run Pick and Read"))
        XCTAssertTrue(today.contains("Day 2: Publish one hook remix and reply to 6 builders."))
        XCTAssertTrue(today.contains("Ship toward 5 clips and 19 replies this week"))
    }

    func testFameSprintTodayWrapsToDaySevenOnSundayAndClampsCounts() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 12))!

        let today = SetupGuideReport.fameSprintToday(
            savedItemCount: -3,
            activityLogItemCount: -1,
            now: date,
            calendar: calendar
        )

        XCTAssertTrue(today.contains("Date: 2026-06-14 (Day 7)"))
        XCTAssertTrue(today.contains("Stage: Spark"))
        XCTAssertTrue(today.contains("Score target: 3"))
        XCTAssertTrue(today.contains("Day 7: Share Copy Fame Board, pick top experiment, and reset next sprint."))
        XCTAssertTrue(today.contains("Day 1: Run Pick and Read, post one demo clip, and share Copy Win Recap."))
        XCTAssertTrue(today.contains("Ship toward 3 clips and 8 replies this week"))
        XCTAssertTrue(today.contains("Capture 5 proof moments"))
    }

}
