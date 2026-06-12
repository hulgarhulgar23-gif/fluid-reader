import XCTest
@testable import FluidReader

final class FameSnapshotRollupTests: XCTestCase {
    func testParseLedgerReadsRowsAndSortsByTimestamp() {
        let ledger = """
        # Fluid Reader Fame Snapshot Ledger
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260610-0906 | Authority | 40 | Day 3 | fame-sprint-20260610-0906.md | fame-pack-20260610-0906.md |
        | 20260609-0805 | Momentum | 28 | Day 2 | fame-sprint-20260609-0805.md | fame-pack-20260609-0805.md |
        """

        let entries = FameSnapshotRollup.parseLedger(ledger)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].timestamp, "20260609-0805")
        XCTAssertEqual(entries[1].timestamp, "20260610-0906")
        XCTAssertEqual(entries[0].score, 28)
        XCTAssertEqual(entries[1].stage, "Authority")
    }

    func testMarkdownSummarizesWindowAndRecommendation() {
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0805.md",
                packFileName: "fame-pack-20260609-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-0906.md",
                packFileName: "fame-pack-20260610-0906.md"
            )
        ]

        let markdown = FameSnapshotRollup.markdown(entries: entries, windowSize: 7)

        XCTAssertTrue(markdown.contains("# Fluid Reader Weekly Fame Rollup"))
        XCTAssertTrue(markdown.contains("Snapshots analyzed: 2."))
        XCTAssertTrue(markdown.contains("Latest: 20260610-0906 | Authority | score 40 | Day 3."))
        XCTAssertTrue(markdown.contains("Score trend: +12"))
        XCTAssertTrue(markdown.contains("Average score: 34."))
        XCTAssertTrue(markdown.contains("Stage mix: Authority 1, Momentum 1, Spark 0."))
        XCTAssertTrue(markdown.contains("Protect authority"))
        XCTAssertTrue(markdown.contains("## Best Experiments This Week"))
        XCTAssertTrue(markdown.contains("1) Distribution Remix"))
    }

    func testMarkdownHandlesNoSnapshots() {
        let markdown = FameSnapshotRollup.markdown(entries: [])

        XCTAssertTrue(markdown.contains("No snapshots yet."))
        XCTAssertTrue(markdown.contains("Run `Run Fame Sprint + Save Snapshot` to start tracking."))
    }

    func testMarkdownIncludesScoreSparkline() {
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Spark",
                score: 10,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Momentum",
                score: 20,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260611-1007",
                stage: "Authority",
                score: 30,
                day: "Day 3",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let markdown = FameSnapshotRollup.markdown(entries: entries, windowSize: 7)

        XCTAssertTrue(markdown.contains("Score sparkline: ▁▅█"))
    }

    func testMarkdownCanPrioritizeActivationWhenTrendIsDown() {
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Spark",
                score: 12,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Spark",
                score: 9,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let markdown = FameSnapshotRollup.markdown(entries: entries, windowSize: 7)

        XCTAssertTrue(markdown.contains("Score trend: -3"))
        XCTAssertTrue(markdown.contains("1) Activation Fix"))
        XCTAssertTrue(markdown.contains("Score is flat/down"))
    }

    func testMarkdownFromLedgerReadsFile() throws {
        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRollupTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Momentum | 28 | Day 2 | a.md | b.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let markdown = FameSnapshotRollup.markdownFromLedger(at: ledgerURL)

        XCTAssertTrue(markdown.contains("Latest: 20260609-0805 | Momentum | score 28 | Day 2."))
    }

    func testActionQueueIncludesPriorityBlocks() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let queue = FameSnapshotRollup.actionQueue(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(queue.contains("# Fluid Reader 24h Fame Action Queue"))
        XCTAssertTrue(queue.contains("Date: 2026-06-09"))
        XCTAssertTrue(queue.contains("## Priority Queue"))
        XCTAssertTrue(queue.contains("1) Distribution Remix"))
        XCTAssertTrue(queue.contains("0-2h:"))
        XCTAssertTrue(queue.contains("2-8h:"))
        XCTAssertTrue(queue.contains("8-24h:"))
        XCTAssertTrue(queue.contains("Daily Guardrails"))
    }

    func testActionQueueHandlesNoSnapshots() {
        let queue = FameSnapshotRollup.actionQueue(entries: [])

        XCTAssertTrue(queue.contains("No snapshots yet."))
        XCTAssertTrue(queue.contains("Run `Run Fame Sprint + Save Snapshot` first, then run this queue."))
    }

    func testActionQueueFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderQueueTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Spark | 12 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 9 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let queue = FameSnapshotRollup.actionQueueFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(queue.contains("Score trend window: -3"))
        XCTAssertTrue(queue.contains("1) Activation Fix"))
    }

    func testCommandCenterIncludesState72hPlanAndTargets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let commandCenter = FameSnapshotRollup.commandCenter(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(commandCenter.contains("# Fluid Reader Fame Command Center"))
        XCTAssertTrue(commandCenter.contains("Date: 2026-06-09"))
        XCTAssertTrue(commandCenter.contains("## State"))
        XCTAssertTrue(commandCenter.contains("Trajectory: Breakout lane"))
        XCTAssertTrue(commandCenter.contains("Score sparkline:"))
        XCTAssertTrue(commandCenter.contains("## 72h Execution Plan"))
        XCTAssertTrue(commandCenter.contains("1) 2026-06-09 — Distribution Remix"))
        XCTAssertTrue(commandCenter.contains("## 24h Targets"))
        XCTAssertTrue(commandCenter.contains("## Risks to Close"))
        XCTAssertTrue(commandCenter.contains("No API keys or private content."))
    }

    func testCommandCenterHandlesNoSnapshots() {
        let commandCenter = FameSnapshotRollup.commandCenter(entries: [])

        XCTAssertTrue(commandCenter.contains("No snapshots yet."))
        XCTAssertTrue(commandCenter.contains("Run `Run Fame Sprint + Save Snapshot` first, then run command center."))
    }

    func testCommandCenterFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderCommandCenterTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Spark | 12 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 9 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let commandCenter = FameSnapshotRollup.commandCenterFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(commandCenter.contains("Score trend: -3"))
        XCTAssertTrue(commandCenter.contains("Risk level: Medium"))
        XCTAssertTrue(commandCenter.contains("Lead experiment: Activation Fix"))
    }

    func testOperatorDashboardIncludesPulseScorecardQueueAndTrail() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 9))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 20,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Spark",
                score: 15,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]

        let dashboard = FameSnapshotRollup.operatorDashboard(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(dashboard.contains("# Fluid Reader Fame Operator Dashboard"))
        XCTAssertTrue(dashboard.contains("Date: 2026-06-12"))
        XCTAssertTrue(dashboard.contains("## Pulse Radar"))
        XCTAssertTrue(dashboard.contains("Pulse risk: Critical"))
        XCTAssertTrue(dashboard.contains("## Daily Scorecard"))
        XCTAssertTrue(dashboard.contains("Next action:"))
        XCTAssertTrue(dashboard.contains("## 24h Execution Queue"))
        XCTAssertTrue(dashboard.contains("1) Activation Fix"))
        XCTAssertTrue(dashboard.contains("## Artifact Trail"))
        XCTAssertTrue(dashboard.contains("Open Latest Operator Dashboard"))
    }

    func testOperatorDashboardHandlesNoSnapshots() {
        let dashboard = FameSnapshotRollup.operatorDashboard(entries: [])

        XCTAssertTrue(dashboard.contains("No snapshots yet."))
        XCTAssertTrue(dashboard.contains("Run `Run Fame Sprint + Save Snapshot` first, then run operator dashboard."))
    }

    func testOperatorDashboardFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 9))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderOperatorDashboardTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Spark | 12 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 9 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let dashboard = FameSnapshotRollup.operatorDashboardFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(dashboard.contains("Pulse risk: High"))
        XCTAssertTrue(dashboard.contains("Latest sprint file: c.md"))
        XCTAssertTrue(dashboard.contains("Latest pack file: d.md"))
    }

    func testBreakthroughForecastIncludesScenarioTableAndCommandStack() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 8, minute: 15))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 24,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Momentum",
                score: 30,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Momentum",
                score: 35,
                day: "Day 3",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let forecast = FameSnapshotRollup.breakthroughForecast(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(forecast.contains("# Fluid Reader Fame Breakthrough Forecast"))
        XCTAssertTrue(forecast.contains("Forecast horizon: next 7 days."))
        XCTAssertTrue(forecast.contains("## 7-Day Stage Outlook"))
        XCTAssertTrue(forecast.contains("| Base |"))
        XCTAssertTrue(forecast.contains("Next target: Authority at score 40."))
        XCTAssertTrue(forecast.contains("Primary command: `run-fame-command-center`"))
        XCTAssertTrue(forecast.contains("`run-fame-breakthrough-forecast`"))
        XCTAssertTrue(forecast.contains("`open-latest-breakthrough-forecast`"))
    }

    func testBreakthroughForecastHandlesNoSnapshots() {
        let forecast = FameSnapshotRollup.breakthroughForecast(entries: [])

        XCTAssertTrue(forecast.contains("No snapshots yet."))
        XCTAssertTrue(forecast.contains("Run `Run Fame Sprint + Save Snapshot` first, then run breakthrough forecast."))
    }

    func testBreakthroughForecastFromLedgerCanPrioritizeRecovery() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 8, minute: 15))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderBreakthroughForecastTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260608-0805 | Spark | 14 | Day 1 | a.md | b.md |
        | 20260609-0906 | Spark | 12 | Day 2 | c.md | d.md |
        | 20260610-1007 | Spark | 9 | Day 3 | e.md | f.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let forecast = FameSnapshotRollup.breakthroughForecastFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(forecast.contains("Baseline: 20260610-1007 | Spark | score 9 | Day 3"))
        XCTAssertTrue(forecast.contains("Primary command: `run-fame-recovery-sprint`"))
        XCTAssertTrue(forecast.contains("Forecast confidence: Low"))
    }

    func testDailyMissionIncludesThreeHourPlanAndCommandStack() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 8, minute: 15))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260610-0805",
                stage: "Momentum",
                score: 24,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260611-0906",
                stage: "Momentum",
                score: 32,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260612-1007",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let mission = FameSnapshotRollup.dailyMission(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(mission.contains("# Fluid Reader Daily Fame Mission"))
        XCTAssertTrue(mission.contains("## 3-Hour Mission"))
        XCTAssertTrue(mission.contains("0-20m: Run `run-fame-breakthrough-forecast`"))
        XCTAssertTrue(mission.contains("`run-fame-24h-queue`"))
        XCTAssertTrue(mission.contains("`open-fame-snapshot-folder`"))
    }

    func testDailyMissionHandlesNoSnapshots() {
        let mission = FameSnapshotRollup.dailyMission(entries: [])

        XCTAssertTrue(mission.contains("No snapshots yet."))
        XCTAssertTrue(mission.contains("Run `Run Fame Sprint + Save Snapshot` first, then run daily mission."))
    }

    func testDailyMissionFromLedgerCanPrioritizeRecovery() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 8, minute: 15))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderDailyMissionTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260610-0805 | Spark | 18 | Day 1 | a.md | b.md |
        | 20260611-0906 | Spark | 13 | Day 2 | c.md | d.md |
        | 20260612-1007 | Spark | 9 | Day 3 | e.md | f.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let mission = FameSnapshotRollup.dailyMissionFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(mission.contains("Pulse risk: High"))
        XCTAssertTrue(mission.contains("0-20m: Run `run-fame-recovery-sprint`"))
    }

    func testMorningBriefIncludesLaunchChecklistAndCommandStack() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 7, minute: 30))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 20,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Spark",
                score: 15,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]

        let brief = FameSnapshotRollup.morningBrief(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(brief.contains("# Fluid Reader Morning Fame Brief"))
        XCTAssertTrue(brief.contains("Date: 2026-06-12"))
        XCTAssertTrue(brief.contains("## Pulse Snapshot"))
        XCTAssertTrue(brief.contains("Pulse risk: Critical"))
        XCTAssertTrue(brief.contains("## Must-Ship Checklist"))
        XCTAssertTrue(brief.contains("## Command Stack"))
        XCTAssertTrue(brief.contains("run-fame-morning-brief"))
        XCTAssertTrue(brief.contains("open-latest-operator-dashboard"))
        XCTAssertTrue(brief.contains("## Today Target"))
    }

    func testMorningBriefHandlesNoSnapshots() {
        let brief = FameSnapshotRollup.morningBrief(entries: [])

        XCTAssertTrue(brief.contains("No snapshots yet."))
        XCTAssertTrue(brief.contains("Run `Run Fame Sprint + Save Snapshot` first, then run morning brief."))
    }

    func testMorningBriefFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 9))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderMorningBriefTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Spark | 12 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 9 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let brief = FameSnapshotRollup.morningBriefFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(brief.contains("Pulse risk: High"))
        XCTAssertTrue(brief.contains("run-fame-recovery-sprint"))
        XCTAssertTrue(brief.contains("Average score window: 11 (-3 trend)"))
    }

    func testMiddayBriefIncludesDecisionGateAndCommandStack() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 13, minute: 15))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 20,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Spark",
                score: 15,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]

        let brief = FameSnapshotRollup.middayBrief(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(brief.contains("# Fluid Reader Midday Fame Brief"))
        XCTAssertTrue(brief.contains("Date: 2026-06-12"))
        XCTAssertTrue(brief.contains("## Midday Pulse Check"))
        XCTAssertTrue(brief.contains("## Decision Gate"))
        XCTAssertTrue(brief.contains("Primary command now: `run-fame-recovery-sprint`"))
        XCTAssertTrue(brief.contains("## Command Stack"))
        XCTAssertTrue(brief.contains("run-fame-midday-brief"))
        XCTAssertTrue(brief.contains("open-latest-midday-brief"))
    }

    func testMiddayBriefHandlesNoSnapshots() {
        let brief = FameSnapshotRollup.middayBrief(entries: [])

        XCTAssertTrue(brief.contains("No snapshots yet."))
        XCTAssertTrue(brief.contains("Run `Run Fame Sprint + Save Snapshot` first, then run midday brief."))
    }

    func testEveningBriefIncludesCloseoutAndTomorrowLaunch() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 21, minute: 10))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let brief = FameSnapshotRollup.eveningBrief(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(brief.contains("# Fluid Reader Evening Fame Brief"))
        XCTAssertTrue(brief.contains("Date: 2026-06-12"))
        XCTAssertTrue(brief.contains("## Day Close Snapshot"))
        XCTAssertTrue(brief.contains("## Tomorrow 08:00 Launch"))
        XCTAssertTrue(brief.contains("## Command Stack"))
        XCTAssertTrue(brief.contains("run-fame-evening-brief"))
        XCTAssertTrue(brief.contains("open-latest-evening-brief"))
    }

    func testEveningBriefFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 11, hour: 22))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderEveningBriefTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Spark | 12 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 9 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let brief = FameSnapshotRollup.eveningBriefFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(brief.contains("Pulse risk: High"))
        XCTAssertTrue(brief.contains("First command: `run-fame-recovery-sprint`"))
        XCTAssertTrue(brief.contains("run-fame-morning-brief"))
    }

    func testDailyCheckpointIncludesKPIDeltaStatusAndExecutionBlock() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let checkpoint = FameSnapshotRollup.dailyCheckpoint(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(checkpoint.contains("# Fluid Reader Daily Fame Checkpoint"))
        XCTAssertTrue(checkpoint.contains("Date: 2026-06-09"))
        XCTAssertTrue(checkpoint.contains("## KPI Delta"))
        XCTAssertTrue(checkpoint.contains("Score delta vs previous: +12"))
        XCTAssertTrue(checkpoint.contains("Score sparkline:"))
        XCTAssertTrue(checkpoint.contains("## Status"))
        XCTAssertTrue(checkpoint.contains("Risk level: Low"))
        XCTAssertTrue(checkpoint.contains("Lead experiment: Distribution Remix"))
        XCTAssertTrue(checkpoint.contains("## Priority Execution Block"))
        XCTAssertTrue(checkpoint.contains("## Alerts"))
    }

    func testDailyCheckpointHandlesNoSnapshots() {
        let checkpoint = FameSnapshotRollup.dailyCheckpoint(entries: [])

        XCTAssertTrue(checkpoint.contains("No snapshots yet."))
        XCTAssertTrue(checkpoint.contains("Run `Run Fame Sprint + Save Snapshot` first, then run checkpoint."))
    }

    func testDailyCheckpointFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderDailyCheckpointTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Spark | 12 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 9 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let checkpoint = FameSnapshotRollup.dailyCheckpointFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(checkpoint.contains("Score delta vs previous: -3"))
        XCTAssertTrue(checkpoint.contains("Risk level: Medium"))
        XCTAssertTrue(checkpoint.contains("Lead experiment: Activation Fix"))
    }

    func testDailyScorecardIncludesRiskDeltaAndRecommendedAction() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 9, hour: 10))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let scorecard = FameSnapshotRollup.dailyScorecard(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(scorecard.contains("# Fluid Reader Daily Fame Scorecard"))
        XCTAssertTrue(scorecard.contains("Date: 2026-06-09"))
        XCTAssertTrue(scorecard.contains("Score delta vs previous: +12"))
        XCTAssertTrue(scorecard.contains("Score trend window: +12"))
        XCTAssertTrue(scorecard.contains("Risk level: Low"))
        XCTAssertTrue(scorecard.contains("Compounding authority. Stay consistent and amplify winners."))
        XCTAssertTrue(scorecard.contains("Suggested action: Run Fame Command Center"))
        XCTAssertTrue(scorecard.contains("Why now: Risk is low; use command center to turn momentum into a 72h breakout plan."))
    }

    func testDailyScorecardHandlesNoSnapshots() {
        let scorecard = FameSnapshotRollup.dailyScorecard(entries: [])

        XCTAssertTrue(scorecard.contains("No snapshots yet."))
        XCTAssertTrue(scorecard.contains("Run `Run Fame Sprint + Save Snapshot` first, then run scorecard."))
    }

    func testDailyScorecardStateCanRecommendCommandCenterWhenRiskLow() {
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Momentum",
                score: 28,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Authority",
                score: 40,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let state = FameSnapshotRollup.dailyScorecardState(entries: entries, windowSize: 7)

        XCTAssertEqual(state.riskLevel, "Low")
        XCTAssertEqual(state.scoreDelta, 12)
        XCTAssertEqual(state.nextActionTitle, "Run Fame Command Center")
        XCTAssertFalse(state.recommendsRecovery)
    }

    func testDailyScorecardStateCanRecommendRecoveryWhenRiskHigh() {
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260609-0805",
                stage: "Spark",
                score: 20,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-0906",
                stage: "Spark",
                score: 12,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let state = FameSnapshotRollup.dailyScorecardState(entries: entries, windowSize: 7)

        XCTAssertEqual(state.riskLevel, "High")
        XCTAssertEqual(state.scoreDelta, -8)
        XCTAssertEqual(state.nextActionTitle, "Run Fame Recovery Sprint")
        XCTAssertTrue(state.recommendsRecovery)
    }

    func testPulseNudgeIncludesStreakRiskAndMustShipAlert() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 9))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 20,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Spark",
                score: 15,
                day: "Day 3",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let nudge = FameSnapshotRollup.pulseNudge(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(nudge.contains("# Fluid Reader Fame Pulse Nudge"))
        XCTAssertTrue(nudge.contains("Snapshot streak: 3 day(s)"))
        XCTAssertTrue(nudge.contains("Days since last snapshot: 2"))
        XCTAssertTrue(nudge.contains("Risk level: Critical"))
        XCTAssertTrue(nudge.contains("Score sparkline:"))
        XCTAssertTrue(nudge.contains("MUST SHIP in next 2h"))
        XCTAssertTrue(nudge.contains("## Immediate Action"))
    }

    func testPulseNudgeHandlesNoSnapshots() {
        let nudge = FameSnapshotRollup.pulseNudge(entries: [])

        XCTAssertTrue(nudge.contains("No snapshots yet."))
        XCTAssertTrue(nudge.contains("Run `Run Fame Sprint + Save Snapshot` first, then run pulse nudge."))
    }

    func testRecoverySprintIncludesTriggerPlanAndTargets() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 9))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 20,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Spark",
                score: 15,
                day: "Day 3",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let recovery = FameSnapshotRollup.recoverySprint(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(recovery.contains("# Fluid Reader Fame Recovery Sprint"))
        XCTAssertTrue(recovery.contains("Risk level: Critical"))
        XCTAssertTrue(recovery.contains("Score sparkline:"))
        XCTAssertTrue(recovery.contains("Must-ship alert: MUST SHIP in next 2h"))
        XCTAssertTrue(recovery.contains("## 6h Recovery Plan"))
        XCTAssertTrue(recovery.contains("Escalation lane: Red lane"))
        XCTAssertTrue(recovery.contains("## Recovery Targets"))
        XCTAssertTrue(recovery.contains("Proof loops to ship today: 2"))
        XCTAssertTrue(recovery.contains("Run `Run Fame Pulse Nudge` to verify risk dropped."))
    }

    func testRecoverySprintHandlesNoSnapshots() {
        let recovery = FameSnapshotRollup.recoverySprint(entries: [])

        XCTAssertTrue(recovery.contains("No snapshots yet."))
        XCTAssertTrue(recovery.contains("Run `Run Fame Sprint + Save Snapshot` first, then run recovery sprint."))
    }

    func testRecoveryChecklistIncludesTwoHourExecutionBoard() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 10, minute: 20))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260612-0805",
                stage: "Authority",
                score: 40,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260612-0906",
                stage: "Spark",
                score: 17,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let checklist = FameSnapshotRollup.recoveryChecklist(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(checklist.contains("# Fluid Reader 2h Recovery Checklist"))
        XCTAssertTrue(checklist.contains("Pulse risk: High"))
        XCTAssertTrue(checklist.contains("Transition status: escalated Low -> High"))
        XCTAssertTrue(checklist.contains("## 0-20 Minutes"))
        XCTAssertTrue(checklist.contains("## 20-60 Minutes"))
        XCTAssertTrue(checklist.contains("## 60-120 Minutes"))
        XCTAssertTrue(checklist.contains("`run-fame-recovery-checklist`"))
        XCTAssertTrue(checklist.contains("`open-latest-recovery-checklist`"))
    }

    func testRecoveryChecklistHandlesNoSnapshots() {
        let checklist = FameSnapshotRollup.recoveryChecklist(entries: [])

        XCTAssertTrue(checklist.contains("No snapshots yet."))
        XCTAssertTrue(checklist.contains("Run `Run Fame Sprint + Save Snapshot` first, then run recovery checklist."))
    }

    func testRecoveryProofPackIncludesPostReplyCheckpointAndCommandStack() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 10, minute: 20))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260612-0805",
                stage: "Authority",
                score: 40,
                day: "Day 2",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260612-0906",
                stage: "Spark",
                score: 17,
                day: "Day 3",
                sprintFileName: "c.md",
                packFileName: "d.md"
            )
        ]

        let pack = FameSnapshotRollup.recoveryProofPack(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(pack.contains("# Fluid Reader Recovery Proof Pack"))
        XCTAssertTrue(pack.contains("## Post-Ready Proof"))
        XCTAssertTrue(pack.contains("## Reply Sprint Snippets"))
        XCTAssertTrue(pack.contains("## Checkpoint Update"))
        XCTAssertTrue(pack.contains("Pulse risk High, transition escalated Low -> High"))
        XCTAssertTrue(pack.contains("`run-fame-recovery-proof-pack`"))
        XCTAssertTrue(pack.contains("`open-latest-recovery-proof-pack`"))
        XCTAssertTrue(pack.contains("No API keys or private content."))
    }

    func testRecoveryProofPackHandlesNoSnapshots() {
        let pack = FameSnapshotRollup.recoveryProofPack(entries: [])

        XCTAssertTrue(pack.contains("No snapshots yet."))
        XCTAssertTrue(pack.contains("Run `Run Fame Sprint + Save Snapshot` first, then run recovery proof pack."))
    }

    func testPulseNudgeFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderPulseNudgeTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Momentum | 28 | Day 2 | a.md | b.md |
        | 20260610-0906 | Authority | 40 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let nudge = FameSnapshotRollup.pulseNudgeFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(nudge.contains("Risk level: Low"))
        XCTAssertTrue(nudge.contains("Lead experiment: Distribution Remix"))
        XCTAssertTrue(nudge.contains("Days since last snapshot: 0"))
    }

    func testRecoverySprintFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRecoverySprintTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Momentum | 28 | Day 2 | a.md | b.md |
        | 20260610-0906 | Authority | 40 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let recovery = FameSnapshotRollup.recoverySprintFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(recovery.contains("Risk level: Low"))
        XCTAssertTrue(recovery.contains("Lead experiment: Distribution Remix"))
        XCTAssertTrue(recovery.contains("## Recovery Targets"))
    }

    func testRecoveryChecklistFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRecoveryChecklistTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260610-0805 | Authority | 40 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 17 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let checklist = FameSnapshotRollup.recoveryChecklistFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(checklist.contains("Pulse risk: High"))
        XCTAssertTrue(checklist.contains("Transition status: escalated Low -> High"))
        XCTAssertTrue(checklist.contains("run-fame-sprint-snapshot"))
    }

    func testRecoveryProofPackFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRecoveryProofPackTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260610-0805 | Authority | 40 | Day 2 | a.md | b.md |
        | 20260610-0906 | Spark | 17 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let pack = FameSnapshotRollup.recoveryProofPackFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(pack.contains("Pulse risk High, transition escalated Low -> High"))
        XCTAssertTrue(pack.contains("run-fame-sprint-snapshot"))
        XCTAssertTrue(pack.contains("open-latest-recovery-proof-pack"))
    }

    func testRiskTimelineIncludesTransitionsAndCurrentPulse() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 13, hour: 9))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 25,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260612-1007",
                stage: "Spark",
                score: 15,
                day: "Day 5",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let timeline = FameSnapshotRollup.riskTimeline(
            entries: entries,
            windowSize: 14,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(timeline.contains("# Fluid Reader Fame Risk Timeline"))
        XCTAssertTrue(timeline.contains("init Low"))
        XCTAssertTrue(timeline.contains("escalated Low -> High"))
        XCTAssertTrue(timeline.contains("escalated High -> Critical"))
        XCTAssertTrue(timeline.contains("Risk now: High"))
        XCTAssertTrue(timeline.contains("Current transition: improved Critical -> High"))
        XCTAssertTrue(timeline.contains("Score sparkline:"))
        XCTAssertTrue(timeline.contains("Run `Open Latest Recovery Sprint` to reopen your latest saved plan."))
    }

    func testRiskTimelineHandlesNoSnapshots() {
        let timeline = FameSnapshotRollup.riskTimeline(entries: [])

        XCTAssertTrue(timeline.contains("No snapshots yet."))
        XCTAssertTrue(timeline.contains("Run `Run Fame Sprint + Save Snapshot` first, then run risk timeline."))
    }

    func testRiskTimelineFromLedgerReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderRiskTimelineTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Momentum | 28 | Day 2 | a.md | b.md |
        | 20260610-0906 | Authority | 40 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let timeline = FameSnapshotRollup.riskTimelineFromLedger(
            at: ledgerURL,
            windowSize: 14,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(timeline.contains("20260610-0906 | score 40"))
        XCTAssertTrue(timeline.contains("Risk now: Low"))
        XCTAssertTrue(timeline.contains("Current transition: steady"))
    }

    func testPulseBundleFromLedgerIncludesCheckpointAndNudge() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderPulseBundleTests-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260609-0805 | Momentum | 28 | Day 2 | a.md | b.md |
        | 20260610-0906 | Authority | 40 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let bundle = FameSnapshotRollup.pulseBundleFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(bundle.checkpointMarkdown.contains("# Fluid Reader Daily Fame Checkpoint"))
        XCTAssertTrue(bundle.checkpointMarkdown.contains("Score delta vs previous: +12"))
        XCTAssertTrue(bundle.pulseNudgeMarkdown.contains("# Fluid Reader Fame Pulse Nudge"))
        XCTAssertTrue(bundle.pulseNudgeMarkdown.contains("Risk level: Low"))
    }

    func testPulseAlertSignalCanDetectCriticalRisk() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 9))!
        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Momentum",
                score: 20,
                day: "Day 1",
                sprintFileName: "a.md",
                packFileName: "b.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Spark",
                score: 18,
                day: "Day 2",
                sprintFileName: "c.md",
                packFileName: "d.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Spark",
                score: 15,
                day: "Day 3",
                sprintFileName: "e.md",
                packFileName: "f.md"
            )
        ]

        let signal = FameSnapshotRollup.pulseAlertSignal(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(signal?.riskLevel, "Critical")
        XCTAssertEqual(signal?.streakDays, 3)
        XCTAssertEqual(signal?.daysSinceLastSnapshot, 2)
        XCTAssertEqual(signal?.leadExperiment, "Activation Fix")
        XCTAssertTrue(signal?.mustShipAlert.contains("MUST SHIP in next 2h") == true)
    }

    func testPulseAlertSignalFromLedgerReturnsNilForEmptyLedger() throws {
        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderPulseAlertEmpty-\(UUID().uuidString).md")
        try "".write(to: ledgerURL, atomically: true, encoding: .utf8)

        let signal = FameSnapshotRollup.pulseAlertSignalFromLedger(at: ledgerURL)
        XCTAssertNil(signal)
    }

    func testPulseWidgetStateCanRenderUnknownAndRiskStates() {
        let unknown = FameSnapshotRollup.pulseWidgetState(signal: nil)
        XCTAssertEqual(unknown.riskLevel, "Unknown")
        XCTAssertEqual(unknown.title, "Pulse Risk: Unknown")
        XCTAssertEqual(unknown.symbolName, "questionmark.circle")

        let highSignal = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "Must ship today",
            streakDays: 2,
            daysSinceLastSnapshot: 1,
            leadExperiment: "Activation Fix"
        )
        let high = FameSnapshotRollup.pulseWidgetState(signal: highSignal)
        XCTAssertEqual(high.riskLevel, "High")
        XCTAssertEqual(high.title, "Pulse Risk: High — Recovery")
        XCTAssertEqual(high.symbolName, "exclamationmark.triangle")
        XCTAssertTrue(high.detail.contains("Streak 2d"))
        XCTAssertTrue(high.detail.contains("Must ship today"))
    }

    func testPulseWidgetStateFromLedgerUsesLatestSignal() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 12, hour: 9))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderPulseWidgetState-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260608-0805 | Momentum | 20 | Day 1 | a.md | b.md |
        | 20260609-0906 | Spark | 18 | Day 2 | c.md | d.md |
        | 20260610-1007 | Spark | 15 | Day 3 | e.md | f.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let widget = FameSnapshotRollup.pulseWidgetStateFromLedger(
            at: ledgerURL,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(widget.riskLevel, "Critical")
        XCTAssertEqual(widget.title, "Pulse Risk: Critical — MUST SHIP")
        XCTAssertEqual(widget.symbolName, "exclamationmark.triangle.fill")
        XCTAssertTrue(widget.detail.contains("MUST SHIP"))
    }

    func testPulseRiskTransitionCanDetectEscalationAndRecovery() {
        let medium = FamePulseAlertSignal(
            riskLevel: "Medium",
            mustShipAlert: "Ship one proof post",
            streakDays: 2,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Activation Fix"
        )
        let critical = FamePulseAlertSignal(
            riskLevel: "Critical",
            mustShipAlert: "MUST SHIP now",
            streakDays: 4,
            daysSinceLastSnapshot: 2,
            leadExperiment: "Activation Fix"
        )
        let low = FamePulseAlertSignal(
            riskLevel: "Low",
            mustShipAlert: "Protect streak",
            streakDays: 5,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Distribution Remix"
        )

        let escalated = FameSnapshotRollup.pulseRiskTransition(previous: medium, next: critical)
        XCTAssertEqual(escalated?.fromRiskLevel, "Medium")
        XCTAssertEqual(escalated?.toRiskLevel, "Critical")
        XCTAssertEqual(escalated?.isEscalation, true)

        let recovered = FameSnapshotRollup.pulseRiskTransition(previous: critical, next: low)
        XCTAssertEqual(recovered?.fromRiskLevel, "Critical")
        XCTAssertEqual(recovered?.toRiskLevel, "Low")
        XCTAssertEqual(recovered?.isEscalation, false)
    }

    func testPulseRiskTransitionHandlesUnknownAndStableLevels() {
        let medium = FamePulseAlertSignal(
            riskLevel: "Medium",
            mustShipAlert: "Ship one proof post",
            streakDays: 2,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Activation Fix"
        )
        let high = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "Must ship today",
            streakDays: 2,
            daysSinceLastSnapshot: 1,
            leadExperiment: "Activation Fix"
        )

        XCTAssertNil(FameSnapshotRollup.pulseRiskTransition(previous: nil, next: nil))
        XCTAssertNil(FameSnapshotRollup.pulseRiskTransition(previous: medium, next: medium))

        let calibration = FameSnapshotRollup.pulseRiskTransition(previous: nil, next: medium)
        XCTAssertEqual(calibration?.fromRiskLevel, "Unknown")
        XCTAssertEqual(calibration?.toRiskLevel, "Medium")
        XCTAssertEqual(calibration?.isEscalation, false)

        let firstHigh = FameSnapshotRollup.pulseRiskTransition(previous: nil, next: high)
        XCTAssertEqual(firstHigh?.fromRiskLevel, "Unknown")
        XCTAssertEqual(firstHigh?.toRiskLevel, "High")
        XCTAssertEqual(firstHigh?.isEscalation, true)
    }

    func testNextMoveHandoffIncludesActionPulseAndOwnerDraft() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 18, hour: 15, minute: 45))!

        let signal = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "Must ship today",
            streakDays: 2,
            daysSinceLastSnapshot: 1,
            leadExperiment: "Activation Fix"
        )
        let transition = FamePulseRiskTransition(
            fromRiskLevel: "Medium",
            toRiskLevel: "High",
            isEscalation: true
        )
        let scorecard = FameDailyScorecardState(
            riskLevel: "High",
            scoreDelta: -3,
            title: "Daily Scorecard: 18 (-3 vs prev)",
            detail: "Trend -3 · Spark · Sparkline ▁▃█",
            recommendation: "Performance dip. Enter recovery mode with proof-first output.",
            nextActionTitle: "Run Fame Recovery Sprint",
            nextActionSummary: "Risk is elevated, so execute a must-ship recovery block now.",
            recommendsRecovery: true
        )

        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-recovery-sprint",
            commandLabel: "Recovery Sprint",
            signal: signal,
            transition: transition,
            scorecard: scorecard,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(handoff.contains("<!-- founder-fame-next-move-handoff -->"))
        XCTAssertTrue(handoff.contains("# Founder Fame Next Move Handoff"))
        XCTAssertTrue(handoff.contains("Date: 2026-06-18"))
        XCTAssertTrue(handoff.contains("Action: Run Fame Next Move"))
        XCTAssertTrue(handoff.contains("Selected command: Recovery Sprint (`run-fame-recovery-sprint`)"))
        XCTAssertTrue(handoff.contains("Pulse risk: High (escalated Medium -> High)"))
        XCTAssertTrue(handoff.contains("Owner update: Ran `Run Fame Next Move`"))
        XCTAssertTrue(handoff.contains("X draft (<=280): Pulse High (escalated Medium -> High)."))
        XCTAssertTrue(handoff.contains("Bluesky draft (<=300): Pulse High (escalated Medium -> High)."))
        XCTAssertTrue(handoff.contains("LinkedIn draft: Founder ops update: pulse risk High"))
        XCTAssertTrue(handoff.contains("Checklist comment draft: Artifact link: [paste next-move handoff link]"))
        XCTAssertTrue(handoff.contains("No API keys or private content."))
    }

    func testNextMoveHandoffCanFallbackWithoutSignal() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 12,
            title: "Daily Scorecard: 40 (+12 vs prev)",
            detail: "Trend +12 · Authority · Sparkline ▁▅█",
            recommendation: "Compounding authority. Stay consistent and amplify winners.",
            nextActionTitle: "Run Fame Command Center",
            nextActionSummary: "Risk is low; use command center to turn momentum into a 72h breakout plan.",
            recommendsRecovery: false
        )

        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: nil,
            transition: nil,
            scorecard: scorecard
        )

        XCTAssertTrue(handoff.contains("Pulse risk: Low (steady)"))
        XCTAssertTrue(handoff.contains("Must-ship alert: Save a snapshot to activate pulse alerts."))
        XCTAssertTrue(handoff.contains("Lead experiment: n/a"))
        XCTAssertTrue(handoff.contains("Suggested next action: Run Fame Command Center"))
        XCTAssertTrue(handoff.contains("X draft (<=280): Pulse Low (steady)."))
        XCTAssertTrue(handoff.contains("Bluesky draft (<=300): Pulse Low (steady)."))
        XCTAssertTrue(handoff.contains("LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a."))
        XCTAssertTrue(handoff.contains("Checklist comment draft: Artifact link: [paste next-move handoff link]"))
    }

    func testNextMoveHandoffXDraftCanClampToCharacterLimit() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "High",
            scoreDelta: -8,
            title: "Daily Scorecard: 12 (-8 vs prev)",
            detail: "Trend -8 · Spark · Sparkline ▁▂▁",
            recommendation: "Performance dip. Enter recovery mode with proof-first output.",
            nextActionTitle: String(repeating: "Ship proof loop now ", count: 16),
            nextActionSummary: "Risk is elevated, so execute a must-ship recovery block now.",
            recommendsRecovery: true
        )

        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-recovery-sprint",
            commandLabel: String(repeating: "Recovery Sprint ", count: 12),
            signal: FamePulseAlertSignal(
                riskLevel: "High",
                mustShipAlert: "Must ship today",
                streakDays: 2,
                daysSinceLastSnapshot: 1,
                leadExperiment: "Activation Fix"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Medium",
                toRiskLevel: "High",
                isEscalation: true
            ),
            scorecard: scorecard
        )

        let xDraftPrefix = "X draft (<=280): "
        let xDraftLine = handoff
            .split(separator: "\n")
            .first(where: { $0.hasPrefix(xDraftPrefix) })
            .map(String.init)
        XCTAssertNotNil(xDraftLine)

        let xDraft = xDraftLine?.replacingOccurrences(of: xDraftPrefix, with: "") ?? ""
        XCTAssertLessThanOrEqual(xDraft.count, 280)
        XCTAssertTrue(xDraft.hasSuffix("…"))
    }

    func testNextMoveHandoffDraftsCanParseAllDraftLines() {
        let handoff = """
        <!-- founder-fame-next-move-handoff -->
        # Founder Fame Next Move Handoff

        X draft (<=280): Pulse High (escalated Medium -> High). Ran Run Fame Next Move -> Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic
        Bluesky draft (<=300): Pulse High (escalated Medium -> High). Executed Recovery Sprint. Next action: Run Fame Recovery Sprint. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk High (escalated Medium -> High); lead experiment Activation Fix. Executed Recovery Sprint. Next action: Run Fame Recovery Sprint.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Recovery Sprint (run-fame-recovery-sprint); next action: Run Fame Recovery Sprint.
        """

        let drafts = FameSnapshotRollup.nextMoveHandoffDrafts(from: handoff)

        XCTAssertEqual(
            drafts,
            FameNextMoveHandoffDrafts(
                xDraft: "Pulse High (escalated Medium -> High). Ran Run Fame Next Move -> Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic",
                blueskyDraft: "Pulse High (escalated Medium -> High). Executed Recovery Sprint. Next action: Run Fame Recovery Sprint. #buildinpublic",
                linkedInDraft: "Founder ops update: pulse risk High (escalated Medium -> High); lead experiment Activation Fix. Executed Recovery Sprint. Next action: Run Fame Recovery Sprint.",
                checklistCommentDraft: "Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Recovery Sprint (run-fame-recovery-sprint); next action: Run Fame Recovery Sprint."
            )
        )
    }

    func testNextMoveDraftPackCanFormatSectionedClipboardText() {
        let handoff = """
        X draft (<=280): Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic
        Bluesky draft (<=300): Pulse Low (steady). Executed Command Center. Next action: Run Fame Command Center. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center).
        """

        let pack = FameSnapshotRollup.nextMoveDraftPack(from: handoff)

        XCTAssertEqual(
            pack,
            """
            X:
            Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic

            Bluesky:
            Pulse Low (steady). Executed Command Center. Next action: Run Fame Command Center. #buildinpublic

            LinkedIn:
            Founder ops update: pulse risk Low (steady); lead experiment n/a.

            Checklist:
            Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center).
            """
        )
    }

    func testNextMoveDraftPackCanAddFollowUpVariantsWhenMetadataIsPresent() {
        let handoff = """
        # Founder Fame Next Move Handoff

        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        Pulse risk: High (escalated Medium -> High)
        Must-ship alert: Must ship today
        Suggested next action: Run Fame Recovery Sprint
        X draft (<=280): Pulse High (escalated Medium -> High). Ran Run Fame Next Move -> Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic
        Bluesky draft (<=300): Pulse High (escalated Medium -> High). Executed Recovery Sprint. Next action: Run Fame Recovery Sprint. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk High (escalated Medium -> High); lead experiment Activation Fix. Executed Recovery Sprint. Next action: Run Fame Recovery Sprint.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Recovery Sprint (run-fame-recovery-sprint); next action: Run Fame Recovery Sprint.
        """

        let pack = FameSnapshotRollup.nextMoveDraftPack(from: handoff)

        XCTAssertTrue(pack?.contains("X Follow-up:") == true)
        XCTAssertTrue(pack?.contains("Bluesky Follow-up:") == true)
        XCTAssertTrue(pack?.contains("X Hook Variants:") == true)
        XCTAssertTrue(pack?.contains("Bluesky Hook Variants:") == true)
        XCTAssertTrue(pack?.contains("LinkedIn Comment:") == true)
        XCTAssertTrue(pack?.contains("LinkedIn Hook Variants:") == true)
        XCTAssertTrue(pack?.contains("Recommended Hook Variant (Risk + Momentum-aware):") == true)
        XCTAssertTrue(pack?.contains("Reply Opener:") == true)
        XCTAssertTrue(
            pack?.contains(
                "Follow-up: Must ship today. Ran Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "Follow-up signal (High): Must ship today. Ran Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- A) Hook: Must ship today. Ran Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- X: B — Pulse High: executed Recovery Sprint. Next action: Run Fame Recovery Sprint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- Why: Risk is elevated, so signal-forward urgency hooks are most actionable."
            ) == true
        )
        XCTAssertTrue(pack?.contains("Publishing Cadence (Next 60m):") == true)
        XCTAssertTrue(
            pack?.contains(
                "- Focus: Stabilize risk quickly, then widen distribution."
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- 0-15m: Post X B, then queue X Follow-up with the same alert framing."
            ) == true
        )
    }

    func testNextMoveDraftPackCanRecommendBuilderLogHooksWhenRiskIsLow() {
        let handoff = """
        # Founder Fame Next Move Handoff

        Selected command: Command Center (`run-fame-command-center`)
        Pulse risk: Low (steady)
        Must-ship alert: Keep momentum and publish one proof loop
        Suggested next action: Run Fame Command Center
        X draft (<=280): Pulse Low (steady). Ran Run Fame Next Move -> Command Center. Next: Run Fame Command Center. #buildinpublic
        Bluesky draft (<=300): Pulse Low (steady). Executed Command Center. Next action: Run Fame Command Center. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a. Executed Command Center. Next action: Run Fame Command Center.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center); next action: Run Fame Command Center.
        """

        let pack = FameSnapshotRollup.nextMoveDraftPack(from: handoff)

        XCTAssertTrue(
            pack?.contains(
                "- X: C — Builder log: Command Center completed. Keep momentum and publish one proof loop Next up Run Fame Command Center. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- LinkedIn: A — Hook: Keep momentum and publish one proof loop. We executed Command Center, and next action is Run Fame Command Center."
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- Why: Risk is low and momentum is strong, so X/Bluesky compound with builder logs while LinkedIn leads with proof-first framing."
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- Focus: Compound momentum with proof-first storytelling."
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- 0-15m: Post LinkedIn A to anchor the proof narrative."
            ) == true
        )
    }

    func testNextMoveDraftPackCanUseWatchlistMixForMediumRisk() {
        let handoff = """
        # Founder Fame Next Move Handoff

        Selected command: Daily Checkpoint (`run-fame-daily-checkpoint`)
        Pulse risk: Medium (steady)
        Must-ship alert: Keep shipping one proof loop today
        Suggested next action: Run Fame Daily Checkpoint
        X draft (<=280): Pulse Medium (steady). Ran Run Fame Next Move -> Daily Checkpoint. Next: Run Fame Daily Checkpoint. #buildinpublic
        Bluesky draft (<=300): Pulse Medium (steady). Executed Daily Checkpoint. Next action: Run Fame Daily Checkpoint. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk Medium (steady); lead experiment n/a. Executed Daily Checkpoint. Next action: Run Fame Daily Checkpoint.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Daily Checkpoint (run-fame-daily-checkpoint); next action: Run Fame Daily Checkpoint.
        """

        let pack = FameSnapshotRollup.nextMoveDraftPack(from: handoff)

        XCTAssertTrue(
            pack?.contains(
                "- X: A — Hook: Keep shipping one proof loop today. Ran Daily Checkpoint. Next: Run Fame Daily Checkpoint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- Bluesky: A — Hook: Keep shipping one proof loop today. We ran Daily Checkpoint. Next action: Run Fame Daily Checkpoint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- LinkedIn: B — Operator update: pulse risk is Medium; Daily Checkpoint is complete. Next step: Run Fame Daily Checkpoint."
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- Why: Risk is watchlist-level, so X/Bluesky stay balanced while LinkedIn leads with operator context."
            ) == true
        )
        XCTAssertTrue(
            pack?.contains(
                "- Focus: Protect cadence while validating resonance."
            ) == true
        )
    }

    func testNextMoveFirstCadenceStepCanPrioritizeUrgencyXWhenRiskIsHigh() {
        let handoff = """
        # Founder Fame Next Move Handoff

        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        Pulse risk: High (escalated Medium -> High)
        Must-ship alert: Must ship today
        Suggested next action: Run Fame Recovery Sprint
        X draft (<=280): Pulse High (escalated Medium -> High). Ran Run Fame Next Move -> Recovery Sprint. Next: Run Fame Recovery Sprint. #buildinpublic
        Bluesky draft (<=300): Pulse High (escalated Medium -> High). Executed Recovery Sprint. Next action: Run Fame Recovery Sprint. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk High (escalated Medium -> High); lead experiment Activation Fix. Executed Recovery Sprint. Next action: Run Fame Recovery Sprint.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Recovery Sprint (run-fame-recovery-sprint); next action: Run Fame Recovery Sprint.
        """

        let firstStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoff)

        XCTAssertTrue(firstStep?.contains("First Cadence Step (0-15m):") == true)
        XCTAssertTrue(firstStep?.contains("Channel: X (B)") == true)
        XCTAssertTrue(
            firstStep?.contains(
                "Draft: Pulse High: executed Recovery Sprint. Next action: Run Fame Recovery Sprint. #buildinpublic"
            ) == true
        )
        XCTAssertTrue(firstStep?.contains("Cadence focus: Stabilize risk quickly, then widen distribution.") == true)
        XCTAssertTrue(
            firstStep?.contains("Next (15-30m): Post Bluesky B and carry forward the must-ship signal.") == true
        )
    }

    func testNextMoveFirstCadenceStepCanLeadWithLinkedInWhenMomentumIsStrong() {
        let handoff = """
        # Founder Fame Next Move Handoff

        Selected command: Command Center (`run-fame-command-center`)
        Pulse risk: Low (steady)
        Must-ship alert: Keep momentum and publish one proof loop
        Suggested next action: Run Fame Command Center
        X draft (<=280): Pulse Low (steady). Ran Run Fame Next Move -> Command Center. Next: Run Fame Command Center. #buildinpublic
        Bluesky draft (<=300): Pulse Low (steady). Executed Command Center. Next action: Run Fame Command Center. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a. Executed Command Center. Next action: Run Fame Command Center.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center); next action: Run Fame Command Center.
        """

        let firstStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoff)

        XCTAssertTrue(firstStep?.contains("Channel: LinkedIn (A)") == true)
        XCTAssertTrue(
            firstStep?.contains(
                "Draft: Hook: Keep momentum and publish one proof loop. We executed Command Center, and next action is Run Fame Command Center."
            ) == true
        )
        XCTAssertTrue(firstStep?.contains("Cadence focus: Compound momentum with proof-first storytelling.") == true)
        XCTAssertTrue(firstStep?.contains("Next (15-30m): Post X C as the fast amplification layer.") == true)
    }

    func testNextMoveFirstCadenceStepCanFallbackToLegacyXDraft() {
        let handoff = """
        X draft (<=280): Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center).
        """

        let firstStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoff)

        XCTAssertEqual(
            firstStep,
            """
            First Cadence Step (0-15m):
            Channel: X
            Draft: Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic
            """
        )
    }

    func testNextMoveHandoffDraftsFallbackBlueskyToXForLegacyArtifacts() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic
        LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a.
        Checklist comment draft: Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center).
        """

        let drafts = FameSnapshotRollup.nextMoveHandoffDrafts(from: handoff)

        XCTAssertEqual(
            drafts,
            FameNextMoveHandoffDrafts(
                xDraft: "Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic",
                blueskyDraft: "Pulse Low (steady). Ran Run Fame Next Move -> Command Center. #buildinpublic",
                linkedInDraft: "Founder ops update: pulse risk Low (steady); lead experiment n/a.",
                checklistCommentDraft: "Artifact link: [paste next-move handoff link] | Owner update: Ran Run Fame Next Move -> Command Center (run-fame-command-center)."
            )
        )
    }

    func testNextMoveHandoffDraftsReturnsNilWhenRequiredLinesMissing() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Pulse Low (steady). Ran Run Fame Next Move -> Command Center.
        LinkedIn draft: Founder ops update: pulse risk Low (steady); lead experiment n/a.
        """

        XCTAssertNil(FameSnapshotRollup.nextMoveHandoffDrafts(from: handoff))
        XCTAssertNil(FameSnapshotRollup.nextMoveDraftPack(from: handoff))
    }

    func testEscalationNudgeCanPrioritizeRecoveryWhenRiskEscalates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 18, hour: 14, minute: 30))!

        let transition = FamePulseRiskTransition(
            fromRiskLevel: "Medium",
            toRiskLevel: "Critical",
            isEscalation: true
        )
        let signal = FamePulseAlertSignal(
            riskLevel: "Critical",
            mustShipAlert: "MUST SHIP in next 2h",
            streakDays: 3,
            daysSinceLastSnapshot: 2,
            leadExperiment: "Activation Fix"
        )

        let nudge = FameSnapshotRollup.escalationNudge(
            transition: transition,
            signal: signal,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(nudge.title, "Fame Escalation Nudge: Critical")
        XCTAssertTrue(nudge.requiresImmediateRecovery)
        XCTAssertEqual(nudge.primaryCommandID, "run-fame-recovery-sprint")
        XCTAssertEqual(nudge.secondaryCommandID, "run-fame-risk-timeline")
        XCTAssertTrue(nudge.markdown.contains("# Fluid Reader Fame Escalation Nudge"))
        XCTAssertTrue(nudge.markdown.contains("Status: Escalated Medium -> Critical"))
        XCTAssertTrue(nudge.markdown.contains("`run-fame-escalation-nudge`"))
        XCTAssertTrue(nudge.markdown.contains("`open-latest-escalation-nudge`"))
    }

    func testEscalationNudgeCanStayOnOffenseWhenRiskStable() {
        let signal = FamePulseAlertSignal(
            riskLevel: "Low",
            mustShipAlert: "Protect streak",
            streakDays: 8,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Distribution Remix"
        )

        let nudge = FameSnapshotRollup.escalationNudge(
            transition: nil,
            signal: signal
        )

        XCTAssertEqual(nudge.title, "Fame Escalation Nudge: Stable")
        XCTAssertFalse(nudge.requiresImmediateRecovery)
        XCTAssertEqual(nudge.primaryCommandID, "run-fame-daily-checkpoint")
        XCTAssertEqual(nudge.secondaryCommandID, "run-fame-operator-dashboard")
        XCTAssertTrue(nudge.markdown.contains("Status: Steady Low"))
    }

    func testEscalationNudgeFromLedgerHandlesNoSnapshots() throws {
        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderEscalationNoSnapshots-\(UUID().uuidString).md")
        try "".write(to: ledgerURL, atomically: true, encoding: .utf8)

        let nudge = FameSnapshotRollup.escalationNudgeFromLedger(at: ledgerURL)
        XCTAssertTrue(nudge.markdown.contains("No snapshots yet."))
        XCTAssertEqual(nudge.primaryCommandID, "run-fame-sprint-snapshot")
    }

    func testNarrativeLabCanGenerateRouteBoardFromEntries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 11, minute: 30))!

        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Spark",
                score: 18,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Momentum",
                score: 31,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Authority",
                score: 43,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]

        let lab = FameSnapshotRollup.narrativeLab(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(lab.contains("# Founder Fame Narrative Lab"))
        XCTAssertTrue(lab.contains("Date: 2026-06-10"))
        XCTAssertTrue(lab.contains("Lead route: Distribution Remix"))
        XCTAssertTrue(lab.contains("## Narrative Route Board"))
        XCTAssertTrue(lab.contains("1) Distribution Remix"))
        XCTAssertTrue(lab.contains("`run-fame-command-center`"))
        XCTAssertTrue(lab.contains("X draft (<=280):"))
        XCTAssertTrue(lab.contains("No API keys or private content."))
    }

    func testNarrativeLabCanHandleNoSnapshots() throws {
        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderNarrativeLabNoSnapshots-\(UUID().uuidString).md")
        try "".write(to: ledgerURL, atomically: true, encoding: .utf8)

        let lab = FameSnapshotRollup.narrativeLabFromLedger(at: ledgerURL)
        XCTAssertTrue(lab.contains("No snapshots yet."))
        XCTAssertTrue(lab.contains("Run `Run Fame Sprint + Save Snapshot` first, then run narrative lab."))
    }

    func testSpotlightPackCanGenerateChannelDraftsFromEntries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 12, minute: 5))!

        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Spark",
                score: 19,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Momentum",
                score: 30,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Authority",
                score: 42,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]

        let pack = FameSnapshotRollup.spotlightPack(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(pack.contains("# Founder Fame Spotlight Pack"))
        XCTAssertTrue(pack.contains("Date: 2026-06-10"))
        XCTAssertTrue(pack.contains("## Primary Spotlight Route"))
        XCTAssertTrue(pack.contains("Route winner: Distribution Remix"))
        XCTAssertTrue(pack.contains("## Channel Drafts"))
        XCTAssertTrue(pack.contains("X primary (<=280):"))
        XCTAssertTrue(pack.contains("Partner DM draft:"))
        XCTAssertTrue(pack.contains("run-fame-spotlight-pack"))
        XCTAssertTrue(pack.contains("open-latest-spotlight-pack"))
    }

    func testSpotlightPackCanHandleNoSnapshots() throws {
        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderSpotlightPackNoSnapshots-\(UUID().uuidString).md")
        try "".write(to: ledgerURL, atomically: true, encoding: .utf8)

        let pack = FameSnapshotRollup.spotlightPackFromLedger(at: ledgerURL)
        XCTAssertTrue(pack.contains("No snapshots yet."))
        XCTAssertTrue(pack.contains("Run `Run Fame Sprint + Save Snapshot` first, then run spotlight pack."))
    }

    func testLaunchDayScriptCanGenerateTimelineFromEntries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 13, minute: 40))!

        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Spark",
                score: 20,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Momentum",
                score: 33,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Authority",
                score: 45,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]

        let script = FameSnapshotRollup.launchDayScript(
            entries: entries,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertTrue(script.contains("# Founder Fame Launch Day Script"))
        XCTAssertTrue(script.contains("Date: 2026-06-10"))
        XCTAssertTrue(script.contains("Launch route: Distribution Remix"))
        XCTAssertTrue(script.contains("## Launch Timeline (180m)"))
        XCTAssertTrue(script.contains("T-20m: Publish X primary draft:"))
        XCTAssertTrue(script.contains("Launch anchor: 2026-06-10 14:25 (local)"))
        XCTAssertTrue(script.contains("## Operator Checklist"))
        XCTAssertTrue(script.contains("## Reply Ladder"))
        XCTAssertTrue(script.contains("run-fame-launch-day-script"))
        XCTAssertTrue(script.contains("run-fame-launch-countdown"))
        XCTAssertTrue(script.contains("open-latest-launch-day-script"))
        XCTAssertTrue(script.contains("open-latest-launch-countdown"))
    }

    func testLaunchDayScriptCanHandleNoSnapshots() throws {
        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchDayScriptNoSnapshots-\(UUID().uuidString).md")
        try "".write(to: ledgerURL, atomically: true, encoding: .utf8)

        let script = FameSnapshotRollup.launchDayScriptFromLedger(at: ledgerURL)
        XCTAssertTrue(script.contains("No snapshots yet."))
        XCTAssertTrue(script.contains("Run `Run Fame Sprint + Save Snapshot` first, then run launch day script."))
    }

    func testLaunchCountdownCanUseLatestLaunchScriptTimeline() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let scriptNow = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 13, minute: 40))!

        let entries = [
            FameSnapshotRollupEntry(
                timestamp: "20260608-0805",
                stage: "Spark",
                score: 20,
                day: "Day 1",
                sprintFileName: "fame-sprint-20260608-0805.md",
                packFileName: "fame-pack-20260608-0805.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260609-0906",
                stage: "Momentum",
                score: 33,
                day: "Day 2",
                sprintFileName: "fame-sprint-20260609-0906.md",
                packFileName: "fame-pack-20260609-0906.md"
            ),
            FameSnapshotRollupEntry(
                timestamp: "20260610-1007",
                stage: "Authority",
                score: 45,
                day: "Day 3",
                sprintFileName: "fame-sprint-20260610-1007.md",
                packFileName: "fame-pack-20260610-1007.md"
            )
        ]
        let script = FameSnapshotRollup.launchDayScript(
            entries: entries,
            windowSize: 7,
            now: scriptNow,
            calendar: calendar
        )
        let countdownNow = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 14, minute: 5))!
        let countdown = FameSnapshotRollup.launchCountdown(
            launchScript: script,
            now: countdownNow,
            calendar: calendar
        )

        XCTAssertTrue(countdown.contains("# Founder Fame Launch Countdown"))
        XCTAssertTrue(countdown.contains("Countdown: T-20m"))
        XCTAssertTrue(countdown.contains("Launch route: Distribution Remix"))
        XCTAssertTrue(countdown.contains("Next action now: T-20m: Publish X primary draft:"))
        XCTAssertTrue(countdown.contains("## Timeline Status"))
        XCTAssertTrue(countdown.contains("[do now] T-20m"))
        XCTAssertTrue(countdown.contains("run-fame-launch-countdown"))
        XCTAssertTrue(countdown.contains("open-latest-launch-countdown"))
    }

    func testLaunchCountdownCanHandleMissingTimeline() {
        let countdown = FameSnapshotRollup.launchCountdown(
            launchScript: "# Founder Fame Launch Day Script\n\nNo snapshots yet."
        )

        XCTAssertTrue(countdown.contains("No launch timeline found."))
        XCTAssertTrue(countdown.contains("Run `Run Fame Launch Day Script` first, then run launch countdown."))
    }

    func testLaunchCountdownFromLaunchScriptReadsFile() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let countdownNow = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10, hour: 14, minute: 5))!
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLaunchCountdownScript-\(UUID().uuidString).md")
        let script = """
        # Founder Fame Launch Day Script

        Date: 2026-06-10
        Launch route: Distribution Remix
        Pulse risk: Low
        Must-ship alert: Ship one proof loop.
        Launch anchor: 2026-06-10 14:25 (local)

        ## Launch Timeline (180m)
        - T-45m: Prep
        - T-20m: Publish
        - T+10m: Reply
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let countdown = FameSnapshotRollup.launchCountdownFromLaunchScript(
            at: scriptURL,
            now: countdownNow,
            calendar: calendar
        )

        XCTAssertTrue(countdown.contains("# Founder Fame Launch Countdown"))
        XCTAssertTrue(countdown.contains("Countdown: T-20m"))
        XCTAssertTrue(countdown.contains("Next action now: T-20m: Publish"))
    }

    func testLaunchCountdownStatusCanParseHeadlineFields() {
        let countdown = """
        # Founder Fame Launch Countdown

        Countdown: T-20m
        Pulse risk: Low
        Launch route: Distribution Remix
        Next action now: T-20m: Publish X primary draft: Ship proof now.
        """

        let status = FameSnapshotRollup.launchCountdownStatus(from: countdown)
        XCTAssertEqual(status?.countdown, "T-20m")
        XCTAssertEqual(status?.pulseRisk, "Low")
        XCTAssertEqual(status?.launchRoute, "Distribution Remix")
        XCTAssertEqual(status?.nextAction, "T-20m: Publish X primary draft: Ship proof now.")
    }

    func testLaunchCountdownStatusReturnsNilWhenRequiredFieldsMissing() {
        let countdown = """
        # Founder Fame Launch Countdown

        Pulse risk: Low
        Launch route: Distribution Remix
        """
        XCTAssertNil(FameSnapshotRollup.launchCountdownStatus(from: countdown))
    }

    func testLatestPulseRiskTransitionFromLedgerCanDetectEscalation() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 14, hour: 10))!

        let ledgerURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLatestPulseTransition-\(UUID().uuidString).md")
        let ledger = """
        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        | 20260614-0805 | Authority | 40 | Day 2 | a.md | b.md |
        | 20260614-0906 | Spark | 17 | Day 3 | c.md | d.md |
        """
        try ledger.write(to: ledgerURL, atomically: true, encoding: .utf8)

        let pair = FameSnapshotRollup.latestPulseRiskTransitionFromLedger(
            at: ledgerURL,
            windowSize: 7,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(pair?.transition.fromRiskLevel, "Low")
        XCTAssertEqual(pair?.transition.toRiskLevel, "High")
        XCTAssertEqual(pair?.transition.isEscalation, true)
        XCTAssertEqual(pair?.signal.riskLevel, "High")
    }

    func testPulseRiskMenuTitleCoversRiskLevels() {
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuTitle(signal: nil),
            "Pulse Risk: Unknown (save snapshot)"
        )
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuDetail(signal: nil),
            "Streak: n/a · Lead: n/a"
        )

        let critical = FamePulseAlertSignal(
            riskLevel: "Critical",
            mustShipAlert: "MUST SHIP now",
            streakDays: 3,
            daysSinceLastSnapshot: 2,
            leadExperiment: "Activation Fix"
        )
        let high = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "Must ship today",
            streakDays: 2,
            daysSinceLastSnapshot: 1,
            leadExperiment: "Activation Fix"
        )
        let medium = FamePulseAlertSignal(
            riskLevel: "Medium",
            mustShipAlert: "Keep streak alive",
            streakDays: 1,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Reply Engine"
        )
        let low = FamePulseAlertSignal(
            riskLevel: "Low",
            mustShipAlert: "Protect streak",
            streakDays: 5,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Distribution Remix"
        )

        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuTitle(signal: critical),
            "Pulse Risk: Critical — MUST SHIP"
        )
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuTitle(signal: high),
            "Pulse Risk: High — Recovery"
        )
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuTitle(signal: medium),
            "Pulse Risk: Medium"
        )
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuTitle(signal: low),
            "Pulse Risk: Low"
        )
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuDetail(signal: critical),
            "Streak 3d · Since snapshot 2d · Lead Activation Fix"
        )
        XCTAssertEqual(
            FameSnapshotRollup.pulseRiskMenuDetail(signal: low),
            "Streak 5d · Since snapshot 0d · Lead Distribution Remix"
        )
    }
}
