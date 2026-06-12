import XCTest
@testable import FluidReader

final class FameSnapshotArchiveTests: XCTestCase {
    func testTimestampUsesExpectedFormat() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 12, minute: 34))!

        XCTAssertEqual(FameSnapshotArchive.timestamp(now: date, calendar: calendar), "20260609-1234")
    }

    func testSaveCreatesSnapshotFilesWithStableNames() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderSnapshotTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 8, minute: 5))!

        let saved = try FameSnapshotArchive.save(
            sprintMarkdown: """
            # Fluid Reader Fame Sprint Today
            Date: 2026-06-09 (Day 2)
            Stage: Momentum
            Score target: 28
            """,
            packMarkdown: "# Pack",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(saved.directoryURL, tempDirectory)
        XCTAssertEqual(saved.sprintURL.lastPathComponent, "fame-sprint-20260609-0805.md")
        XCTAssertEqual(saved.packURL.lastPathComponent, "fame-pack-20260609-0805.md")
        XCTAssertEqual(saved.ledgerURL.lastPathComponent, "fame-snapshot-ledger.md")
        XCTAssertTrue(try String(contentsOf: saved.sprintURL).contains("# Fluid Reader Fame Sprint Today"))
        XCTAssertEqual(try String(contentsOf: saved.packURL), "# Pack")

        let ledger = try String(contentsOf: saved.ledgerURL)
        XCTAssertTrue(ledger.contains("# Fluid Reader Fame Snapshot Ledger"))
        XCTAssertTrue(ledger.contains("| 20260609-0805 | Momentum | 28 | Day 2 | fame-sprint-20260609-0805.md | fame-pack-20260609-0805.md |"))
    }

    func testSaveAppendsLedgerRows() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderSnapshotTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date1 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 8, minute: 5))!
        let date2 = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 9, minute: 6))!

        _ = try FameSnapshotArchive.save(
            sprintMarkdown: """
            Date: 2026-06-09 (Day 2)
            Stage: Momentum
            Score target: 28
            """,
            packMarkdown: "# Pack 1",
            now: date1,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let second = try FameSnapshotArchive.save(
            sprintMarkdown: """
            Date: 2026-06-10 (Day 3)
            Stage: Authority
            Score target: 40
            """,
            packMarkdown: "# Pack 2",
            now: date2,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let ledger = try String(contentsOf: second.ledgerURL)
        XCTAssertTrue(ledger.contains("| 20260609-0805 | Momentum | 28 | Day 2 | fame-sprint-20260609-0805.md | fame-pack-20260609-0805.md |"))
        XCTAssertTrue(ledger.contains("| 20260610-0906 | Authority | 40 | Day 3 | fame-sprint-20260610-0906.md | fame-pack-20260610-0906.md |"))
    }

    func testSaveCommandCenterCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderCommandCenterTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 7, minute: 4))!

        let url = try FameSnapshotArchive.saveCommandCenter(
            markdown: "# Fluid Reader Fame Command Center",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-command-center-20260611-0704.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Command Center")
    }

    func testSaveNextMoveHandoffCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderNextMoveHandoffTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 8, minute: 8))!

        let url = try FameSnapshotArchive.saveNextMoveHandoff(
            markdown: "# Fluid Reader Fame Next-Move Handoff",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-next-move-handoff-20260611-0808.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Next-Move Handoff")
    }

    func testSaveNextMoveDraftPackCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderNextMoveDraftPackTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 8, minute: 19))!

        let url = try FameSnapshotArchive.saveNextMoveDraftPack(
            markdown: "# Fluid Reader Fame Next-Move Draft Pack",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-next-move-draft-pack-20260611-0819.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Next-Move Draft Pack")
    }

    func testSaveWarRoomCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderWarRoomArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 8, minute: 41))!

        let url = try FameSnapshotArchive.saveWarRoom(
            markdown: "# Founder Fame War Room",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-war-room-20260611-0841.md")
        XCTAssertEqual(try String(contentsOf: url), "# Founder Fame War Room")
    }

    func testSaveDailyCheckpointCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderDailyCheckpointTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 6, minute: 33))!

        let url = try FameSnapshotArchive.saveDailyCheckpoint(
            markdown: "# Fluid Reader Daily Fame Checkpoint",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-daily-checkpoint-20260612-0633.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Daily Fame Checkpoint")
    }

    func testSaveDailyScorecardCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderDailyScorecardTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 6, minute: 45))!

        let url = try FameSnapshotArchive.saveDailyScorecard(
            markdown: "# Fluid Reader Daily Fame Scorecard",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-daily-scorecard-20260612-0645.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Daily Fame Scorecard")
    }

    func testSaveOnboardingScorecardCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderOnboardingScorecardTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 7, minute: 12))!

        let url = try FameSnapshotArchive.saveOnboardingScorecard(
            markdown: "# Fluid Reader First-Week Fame Scorecard",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-onboarding-scorecard-20260612-0712.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader First-Week Fame Scorecard")
    }

    func testSaveOnboardingDailyBriefCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderOnboardingDailyBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 7, minute: 26))!

        let url = try FameSnapshotArchive.saveOnboardingDailyBrief(
            markdown: "# Fluid Reader First-Week Daily Brief",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-onboarding-daily-brief-20260612-0726.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader First-Week Daily Brief")
    }

    func testSavePulseNudgeCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderPulseNudgeTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 7, minute: 41))!

        let url = try FameSnapshotArchive.savePulseNudge(
            markdown: "# Fluid Reader Fame Pulse Nudge",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-pulse-nudge-20260613-0741.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Pulse Nudge")
    }

    func testSaveOnboardingNudgeCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderOnboardingNudgeTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 2))!

        let url = try FameSnapshotArchive.saveOnboardingNudge(
            markdown: "# Fluid Reader Fame Onboarding Nudge",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-onboarding-nudge-20260613-0802.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Onboarding Nudge")
    }

    func testSaveRecoverySprintCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRecoverySprintTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 22))!

        let url = try FameSnapshotArchive.saveRecoverySprint(
            markdown: "# Fluid Reader Fame Recovery Sprint",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-recovery-sprint-20260613-0822.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Recovery Sprint")
    }

    func testSaveRecoveryChecklistCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRecoveryChecklistTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 33))!

        let url = try FameSnapshotArchive.saveRecoveryChecklist(
            markdown: "# Fluid Reader 2h Recovery Checklist",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-recovery-checklist-20260613-0833.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader 2h Recovery Checklist")
    }

    func testSaveRecoveryProofPackCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRecoveryProofPackTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 44))!

        let url = try FameSnapshotArchive.saveRecoveryProofPack(
            markdown: "# Fluid Reader Recovery Proof Pack",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-recovery-proof-pack-20260613-0844.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Recovery Proof Pack")
    }

    func testSaveRiskTimelineCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRiskTimelineArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 9, minute: 14))!

        let url = try FameSnapshotArchive.saveRiskTimeline(
            markdown: "# Fluid Reader Fame Risk Timeline",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-risk-timeline-20260613-0914.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Risk Timeline")
    }

    func testSaveOperatorDashboardCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderOperatorDashboardArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 9, minute: 36))!

        let url = try FameSnapshotArchive.saveOperatorDashboard(
            markdown: "# Fluid Reader Fame Operator Dashboard",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-operator-dashboard-20260613-0936.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Operator Dashboard")
    }

    func testSaveMorningBriefCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderMorningBriefArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 9, minute: 48))!

        let url = try FameSnapshotArchive.saveMorningBrief(
            markdown: "# Fluid Reader Morning Fame Brief",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-morning-brief-20260613-0948.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Morning Fame Brief")
    }

    func testSaveMiddayBriefCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderMiddayBriefArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 12, minute: 8))!

        let url = try FameSnapshotArchive.saveMiddayBrief(
            markdown: "# Fluid Reader Midday Fame Brief",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-midday-brief-20260613-1208.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Midday Fame Brief")
    }

    func testSaveEveningBriefCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderEveningBriefArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 21, minute: 26))!

        let url = try FameSnapshotArchive.saveEveningBrief(
            markdown: "# Fluid Reader Evening Fame Brief",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-evening-brief-20260613-2126.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Evening Fame Brief")
    }

    func testSaveEscalationNudgeCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderEscalationNudgeArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 22, minute: 41))!

        let url = try FameSnapshotArchive.saveEscalationNudge(
            markdown: "# Fluid Reader Fame Escalation Nudge",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-escalation-nudge-20260613-2241.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Escalation Nudge")
    }

    func testSaveBreakthroughForecastCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderBreakthroughForecastArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 23, minute: 12))!

        let url = try FameSnapshotArchive.saveBreakthroughForecast(
            markdown: "# Fluid Reader Fame Breakthrough Forecast",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-breakthrough-forecast-20260613-2312.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Breakthrough Forecast")
    }

    func testSaveDailyMissionCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderDailyMissionArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 5))!

        let url = try FameSnapshotArchive.saveDailyMission(
            markdown: "# Fluid Reader Daily Fame Mission",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-daily-mission-20260614-0605.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Daily Fame Mission")
    }

    func testSaveNarrativeLabCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderNarrativeLabArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 12))!

        let url = try FameSnapshotArchive.saveNarrativeLab(
            markdown: "# Founder Fame Narrative Lab",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-narrative-lab-20260614-0712.md")
        XCTAssertEqual(try String(contentsOf: url), "# Founder Fame Narrative Lab")
    }

    func testSaveSpotlightPackCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderSpotlightPackArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 36))!

        let url = try FameSnapshotArchive.saveSpotlightPack(
            markdown: "# Founder Fame Spotlight Pack",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-spotlight-pack-20260614-0736.md")
        XCTAssertEqual(try String(contentsOf: url), "# Founder Fame Spotlight Pack")
    }

    func testSaveLaunchDayScriptCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchDayScriptArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 2))!

        let url = try FameSnapshotArchive.saveLaunchDayScript(
            markdown: "# Founder Fame Launch Day Script",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-launch-day-script-20260614-0802.md")
        XCTAssertEqual(try String(contentsOf: url), "# Founder Fame Launch Day Script")
    }

    func testSaveLaunchCountdownCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchCountdownArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 17))!

        let url = try FameSnapshotArchive.saveLaunchCountdown(
            markdown: "# Founder Fame Launch Countdown",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-launch-countdown-20260614-0817.md")
        XCTAssertEqual(try String(contentsOf: url), "# Founder Fame Launch Countdown")
    }

    func testSaveLaunchRescueBurstCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchRescueBurstArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 31))!

        let url = try FameSnapshotArchive.saveLaunchRescueBurst(
            markdown: "# Fluid Reader Launch Rescue Burst",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-launch-rescue-burst-20260614-0831.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Launch Rescue Burst")
    }

    func testSaveLaunchControlBriefCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchControlBriefArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 44))!

        let url = try FameSnapshotArchive.saveLaunchControlBrief(
            markdown: "# Fluid Reader Launch Control Brief",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-launch-control-brief-20260614-0844.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Launch Control Brief")
    }

    func testSaveLaunchRescueSnapshotCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchRescueSnapshotArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 51))!

        let url = try FameSnapshotArchive.saveLaunchRescueSnapshot(
            markdown: "# Fluid Reader Launch Rescue Snapshot",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-launch-rescue-snapshot-20260614-0851.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Launch Rescue Snapshot")
    }

    func testLatestRecoverySprintURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRecoveryTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 22))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 10, minute: 45))!

        _ = try FameSnapshotArchive.saveRecoverySprint(
            markdown: "# Early Recovery",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveRecoverySprint(
            markdown: "# Late Recovery",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestRecoverySprintURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestRecoverySprintURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRecoveryEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestRecoverySprintURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestRecoveryChecklistURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRecoveryChecklistTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 33))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 10, minute: 19))!

        _ = try FameSnapshotArchive.saveRecoveryChecklist(
            markdown: "# Early Recovery Checklist",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveRecoveryChecklist(
            markdown: "# Late Recovery Checklist",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestRecoveryChecklistURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestRecoveryChecklistURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRecoveryChecklistEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestRecoveryChecklistURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestRecoveryProofPackURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRecoveryProofPackTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 8, minute: 44))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 11, minute: 7))!

        _ = try FameSnapshotArchive.saveRecoveryProofPack(
            markdown: "# Early Recovery Proof Pack",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveRecoveryProofPack(
            markdown: "# Late Recovery Proof Pack",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestRecoveryProofPackURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestRecoveryProofPackURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRecoveryProofPackEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestRecoveryProofPackURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestCommandCenterURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCommandCenterTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 5, minute: 18))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 41))!

        _ = try FameSnapshotArchive.saveCommandCenter(
            markdown: "# Early Command Center",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveCommandCenter(
            markdown: "# Late Command Center",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestCommandCenterURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestCommandCenterURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCommandCenterEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestCommandCenterURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestNextMoveHandoffURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestNextMoveHandoffTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 4))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 9))!

        _ = try FameSnapshotArchive.saveNextMoveHandoff(
            markdown: "# Early Next-Move Handoff",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveNextMoveHandoff(
            markdown: "# Late Next-Move Handoff",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestNextMoveHandoffURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestNextMoveHandoffURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestNextMoveHandoffEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestNextMoveHandoffURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestNextMoveDraftPackURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestNextMoveDraftPackTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 12))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 21))!

        _ = try FameSnapshotArchive.saveNextMoveDraftPack(
            markdown: "# Early Next-Move Draft Pack",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveNextMoveDraftPack(
            markdown: "# Late Next-Move Draft Pack",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestNextMoveDraftPackURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestNextMoveDraftPackURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestNextMoveDraftPackEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestNextMoveDraftPackURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestDailyCheckpointURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestDailyCheckpointTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 5))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 44))!

        _ = try FameSnapshotArchive.saveDailyCheckpoint(
            markdown: "# Early Daily Checkpoint",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveDailyCheckpoint(
            markdown: "# Late Daily Checkpoint",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestDailyCheckpointURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestDailyCheckpointURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestDailyCheckpointEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestDailyCheckpointURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestRiskTimelineURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRiskTimelineTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 22))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 31))!

        _ = try FameSnapshotArchive.saveRiskTimeline(
            markdown: "# Early Risk Timeline",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveRiskTimeline(
            markdown: "# Late Risk Timeline",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestRiskTimelineURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestRiskTimelineURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestRiskTimelineEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestRiskTimelineURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestPulseNudgeURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestPulseNudgeTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 41))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 18))!

        _ = try FameSnapshotArchive.savePulseNudge(
            markdown: "# Early Pulse Nudge",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.savePulseNudge(
            markdown: "# Late Pulse Nudge",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestPulseNudgeURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestPulseNudgeURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestPulseNudgeEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestPulseNudgeURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestOnboardingNudgeURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOnboardingNudgeTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 5, minute: 54))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 11))!

        _ = try FameSnapshotArchive.saveOnboardingNudge(
            markdown: "# Early Onboarding Nudge",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveOnboardingNudge(
            markdown: "# Late Onboarding Nudge",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestOnboardingNudgeURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestOnboardingNudgeURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOnboardingNudgeEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestOnboardingNudgeURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestDailyScorecardURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestDailyScorecardTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 5))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 44))!

        _ = try FameSnapshotArchive.saveDailyScorecard(
            markdown: "# Early Daily Scorecard",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveDailyScorecard(
            markdown: "# Late Daily Scorecard",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestDailyScorecardURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestDailyScorecardURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestDailyScorecardEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestDailyScorecardURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestOnboardingScorecardURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOnboardingScorecardTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 16))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 57))!

        _ = try FameSnapshotArchive.saveOnboardingScorecard(
            markdown: "# Early First-Week Scorecard",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveOnboardingScorecard(
            markdown: "# Late First-Week Scorecard",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestOnboardingScorecardURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestOnboardingScorecardURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOnboardingScorecardEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestOnboardingScorecardURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestOnboardingDailyBriefURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOnboardingDailyBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 21))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 39))!

        _ = try FameSnapshotArchive.saveOnboardingDailyBrief(
            markdown: "# Early First-Week Daily Brief",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveOnboardingDailyBrief(
            markdown: "# Late First-Week Daily Brief",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestOnboardingDailyBriefURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestOnboardingDailyBriefURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOnboardingDailyBriefEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestOnboardingDailyBriefURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestOperatorDashboardURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOperatorDashboardTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 12))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 3))!

        _ = try FameSnapshotArchive.saveOperatorDashboard(
            markdown: "# Early Operator Dashboard",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveOperatorDashboard(
            markdown: "# Late Operator Dashboard",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestOperatorDashboardURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestOperatorDashboardURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestOperatorDashboardEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestOperatorDashboardURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestMorningBriefURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestMorningBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 38))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 57))!

        _ = try FameSnapshotArchive.saveMorningBrief(
            markdown: "# Early Morning Brief",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveMorningBrief(
            markdown: "# Late Morning Brief",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestMorningBriefURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestMorningBriefURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestMorningBriefEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestMorningBriefURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestMiddayBriefURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestMiddayBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 11, minute: 12))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 13, minute: 44))!

        _ = try FameSnapshotArchive.saveMiddayBrief(
            markdown: "# Early Midday Brief",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveMiddayBrief(
            markdown: "# Late Midday Brief",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestMiddayBriefURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestMiddayBriefURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestMiddayBriefEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestMiddayBriefURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestEveningBriefURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestEveningBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 20, minute: 8))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 22, minute: 19))!

        _ = try FameSnapshotArchive.saveEveningBrief(
            markdown: "# Early Evening Brief",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveEveningBrief(
            markdown: "# Late Evening Brief",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestEveningBriefURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestEveningBriefURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestEveningBriefEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestEveningBriefURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestEscalationNudgeURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestEscalationNudgeTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 19, minute: 2))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 21, minute: 53))!

        _ = try FameSnapshotArchive.saveEscalationNudge(
            markdown: "# Early Escalation Nudge",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveEscalationNudge(
            markdown: "# Late Escalation Nudge",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestEscalationNudgeURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestEscalationNudgeURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestEscalationNudgeEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestEscalationNudgeURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestBreakthroughForecastURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestBreakthroughForecastTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 21, minute: 3))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 23, minute: 17))!

        _ = try FameSnapshotArchive.saveBreakthroughForecast(
            markdown: "# Early Breakthrough Forecast",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveBreakthroughForecast(
            markdown: "# Late Breakthrough Forecast",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestBreakthroughForecastURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestBreakthroughForecastURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestBreakthroughForecastEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestBreakthroughForecastURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestDailyMissionURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestDailyMissionTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 6, minute: 5))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 41))!

        _ = try FameSnapshotArchive.saveDailyMission(
            markdown: "# Early Daily Mission",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveDailyMission(
            markdown: "# Late Daily Mission",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestDailyMissionURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestDailyMissionURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestDailyMissionEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestDailyMissionURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestNarrativeLabURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestNarrativeLabTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 12))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 9, minute: 2))!

        _ = try FameSnapshotArchive.saveNarrativeLab(
            markdown: "# Early Narrative Lab",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveNarrativeLab(
            markdown: "# Late Narrative Lab",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestNarrativeLabURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestNarrativeLabURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestNarrativeLabEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestNarrativeLabURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestSpotlightPackURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestSpotlightPackTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 7, minute: 36))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10, minute: 4))!

        _ = try FameSnapshotArchive.saveSpotlightPack(
            markdown: "# Early Spotlight Pack",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveSpotlightPack(
            markdown: "# Late Spotlight Pack",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestSpotlightPackURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestSpotlightPackURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestSpotlightPackEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestSpotlightPackURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestLaunchDayScriptURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchDayScriptTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 2))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10, minute: 22))!

        _ = try FameSnapshotArchive.saveLaunchDayScript(
            markdown: "# Early Launch Day Script",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveLaunchDayScript(
            markdown: "# Late Launch Day Script",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestLaunchDayScriptURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestLaunchDayScriptURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchDayScriptEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestLaunchDayScriptURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestLaunchCountdownURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchCountdownTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 17))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10, minute: 29))!

        _ = try FameSnapshotArchive.saveLaunchCountdown(
            markdown: "# Early Launch Countdown",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveLaunchCountdown(
            markdown: "# Late Launch Countdown",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestLaunchCountdownURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestLaunchCountdownURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchCountdownEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestLaunchCountdownURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestLaunchRescueBurstURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchRescueBurstTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 31))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10, minute: 47))!

        _ = try FameSnapshotArchive.saveLaunchRescueBurst(
            markdown: "# Early Launch Rescue Burst",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveLaunchRescueBurst(
            markdown: "# Late Launch Rescue Burst",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestLaunchRescueBurstURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestLaunchRescueBurstURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchRescueBurstEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestLaunchRescueBurstURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestLaunchControlBriefURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchControlBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 44))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10, minute: 53))!

        _ = try FameSnapshotArchive.saveLaunchControlBrief(
            markdown: "# Early Launch Control Brief",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveLaunchControlBrief(
            markdown: "# Late Launch Control Brief",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestLaunchControlBriefURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestLaunchControlBriefURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchControlBriefEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestLaunchControlBriefURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testLatestLaunchRescueSnapshotURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchRescueSnapshotTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 8, minute: 51))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 11, minute: 3))!

        _ = try FameSnapshotArchive.saveLaunchRescueSnapshot(
            markdown: "# Early Launch Rescue Snapshot",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveLaunchRescueSnapshot(
            markdown: "# Late Launch Rescue Snapshot",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestLaunchRescueSnapshotURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestLaunchRescueSnapshotURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestLaunchRescueSnapshotEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestLaunchRescueSnapshotURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testSaveCadenceMomentumBriefCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderCadenceMomentumBriefArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 11, minute: 9))!

        let url = try FameSnapshotArchive.saveCadenceMomentumBrief(
            markdown: "# Fluid Reader Cadence Momentum Brief",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-cadence-momentum-brief-20260614-1109.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Cadence Momentum Brief")
    }

    func testLatestCadenceMomentumBriefURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCadenceMomentumBriefTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10, minute: 12))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 12, minute: 46))!

        _ = try FameSnapshotArchive.saveCadenceMomentumBrief(
            markdown: "# Early Cadence Momentum Brief",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveCadenceMomentumBrief(
            markdown: "# Late Cadence Momentum Brief",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestCadenceMomentumBriefURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestCadenceMomentumBriefURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCadenceMomentumBriefEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestCadenceMomentumBriefURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testSaveCadenceShareLineCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderCadenceShareLineArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 8, minute: 37))!

        let url = try FameSnapshotArchive.saveCadenceShareLine(
            markdown: "# Fluid Reader Cadence Share Line",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-cadence-share-line-20260615-0837.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Cadence Share Line")
    }

    func testLatestCadenceShareLineURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCadenceShareLineTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 8, minute: 2))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 9, minute: 41))!

        _ = try FameSnapshotArchive.saveCadenceShareLine(
            markdown: "# Early Cadence Share Line",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveCadenceShareLine(
            markdown: "# Late Cadence Share Line",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestCadenceShareLineURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestCadenceShareLineURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCadenceShareLineEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestCadenceShareLineURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testSaveCadenceSharePackCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderCadenceSharePackArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 10, minute: 6))!

        let url = try FameSnapshotArchive.saveCadenceSharePack(
            markdown: "# Fluid Reader Cadence Share Pack",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-cadence-share-pack-20260615-1006.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Cadence Share Pack")
    }

    func testLatestCadenceSharePackURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCadenceSharePackTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 9, minute: 4))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 11, minute: 48))!

        _ = try FameSnapshotArchive.saveCadenceSharePack(
            markdown: "# Early Cadence Share Pack",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveCadenceSharePack(
            markdown: "# Late Cadence Share Pack",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestCadenceSharePackURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestCadenceSharePackURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestCadenceSharePackEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestCadenceSharePackURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testSaveExceptionalLoopRecapCreatesFileWithStableName() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderExceptionalLoopRecapArchiveTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 7, minute: 22))!

        let url = try FameSnapshotArchive.saveExceptionalLoopRecap(
            markdown: "# Fluid Reader Fame Exceptional Loop Recap",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(url.lastPathComponent, "fame-exceptional-loop-recap-20260616-0722.md")
        XCTAssertEqual(try String(contentsOf: url), "# Fluid Reader Fame Exceptional Loop Recap")
    }

    func testLatestExceptionalLoopRecapURLReturnsNewestFile() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestExceptionalLoopRecapTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let earlyDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 7, minute: 5))!
        let lateDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 8, minute: 43))!

        _ = try FameSnapshotArchive.saveExceptionalLoopRecap(
            markdown: "# Early Exceptional Loop Recap",
            now: earlyDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )
        let lateURL = try FameSnapshotArchive.saveExceptionalLoopRecap(
            markdown: "# Late Exceptional Loop Recap",
            now: lateDate,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        let latest = try FameSnapshotArchive.latestExceptionalLoopRecapURL(baseDirectory: tempDirectory)
        XCTAssertEqual(latest?.lastPathComponent, lateURL.lastPathComponent)
    }

    func testLatestExceptionalLoopRecapURLReturnsNilWhenMissing() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestExceptionalLoopRecapEmpty-\(UUID().uuidString)")
        let latest = try FameSnapshotArchive.latestExceptionalLoopRecapURL(baseDirectory: tempDirectory)
        XCTAssertNil(latest)
    }

    func testSaveAutoPulseFilesCreatesAllArtifacts() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderAutoPulseTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 5, minute: 18))!

        let files = try FameSnapshotArchive.saveAutoPulseFiles(
            checkpointMarkdown: "# Fluid Reader Daily Fame Checkpoint",
            pulseNudgeMarkdown: "# Fluid Reader Fame Pulse Nudge",
            scorecardMarkdown: "# Fluid Reader Daily Fame Scorecard",
            dashboardMarkdown: "# Fluid Reader Fame Operator Dashboard",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(files.checkpointURL.lastPathComponent, "fame-daily-checkpoint-20260614-0518.md")
        XCTAssertEqual(files.pulseNudgeURL.lastPathComponent, "fame-pulse-nudge-20260614-0518.md")
        XCTAssertEqual(files.scorecardURL.lastPathComponent, "fame-daily-scorecard-20260614-0518.md")
        XCTAssertEqual(files.dashboardURL.lastPathComponent, "fame-operator-dashboard-20260614-0518.md")
        XCTAssertEqual(try String(contentsOf: files.checkpointURL), "# Fluid Reader Daily Fame Checkpoint")
        XCTAssertEqual(try String(contentsOf: files.pulseNudgeURL), "# Fluid Reader Fame Pulse Nudge")
        XCTAssertEqual(try String(contentsOf: files.scorecardURL), "# Fluid Reader Daily Fame Scorecard")
        XCTAssertEqual(try String(contentsOf: files.dashboardURL), "# Fluid Reader Fame Operator Dashboard")
    }

    func testSaveOpsBundleFilesCreatesAllArtifacts() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderOpsBundleTests-\(UUID().uuidString)")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 5, minute: 18))!

        let files = try FameSnapshotArchive.saveOpsBundleFiles(
            commandCenterMarkdown: "# Fluid Reader Fame Command Center",
            checkpointMarkdown: "# Fluid Reader Daily Fame Checkpoint",
            riskTimelineMarkdown: "# Fluid Reader Fame Risk Timeline",
            pulseNudgeMarkdown: "# Fluid Reader Fame Pulse Nudge",
            now: date,
            calendar: calendar,
            baseDirectory: tempDirectory
        )

        XCTAssertEqual(files.commandCenterURL.lastPathComponent, "fame-command-center-20260614-0518.md")
        XCTAssertEqual(files.checkpointURL.lastPathComponent, "fame-daily-checkpoint-20260614-0518.md")
        XCTAssertEqual(files.riskTimelineURL.lastPathComponent, "fame-risk-timeline-20260614-0518.md")
        XCTAssertEqual(files.pulseNudgeURL.lastPathComponent, "fame-pulse-nudge-20260614-0518.md")
        XCTAssertEqual(try String(contentsOf: files.commandCenterURL), "# Fluid Reader Fame Command Center")
        XCTAssertEqual(try String(contentsOf: files.checkpointURL), "# Fluid Reader Daily Fame Checkpoint")
        XCTAssertEqual(try String(contentsOf: files.riskTimelineURL), "# Fluid Reader Fame Risk Timeline")
        XCTAssertEqual(try String(contentsOf: files.pulseNudgeURL), "# Fluid Reader Fame Pulse Nudge")
    }
}
