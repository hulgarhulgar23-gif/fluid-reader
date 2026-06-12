import Foundation

struct FameSnapshotRollupEntry: Equatable {
    let timestamp: String
    let stage: String
    let score: Int
    let day: String
    let sprintFileName: String
    let packFileName: String
}

struct FameAutoPulseBundle: Equatable {
    let checkpointMarkdown: String
    let pulseNudgeMarkdown: String
}

struct FamePulseAlertSignal: Equatable {
    let riskLevel: String
    let mustShipAlert: String
    let streakDays: Int
    let daysSinceLastSnapshot: Int
    let leadExperiment: String
}

struct FamePulseRiskTransition: Equatable {
    let fromRiskLevel: String
    let toRiskLevel: String
    let isEscalation: Bool
}

struct FamePulseEscalationNudge: Equatable {
    let title: String
    let transitionStatus: String
    let primaryCommandID: String
    let secondaryCommandID: String
    let requiresImmediateRecovery: Bool
    let markdown: String
}

struct FamePulseWidgetState: Equatable {
    let riskLevel: String
    let title: String
    let detail: String
    let symbolName: String

    static let unknown = FamePulseWidgetState(
        riskLevel: "Unknown",
        title: "Pulse Risk: Unknown",
        detail: "Save a snapshot to unlock pulse tracking.",
        symbolName: "questionmark.circle"
    )
}

struct FameDailyScorecardState: Equatable {
    let riskLevel: String
    let scoreDelta: Int
    let title: String
    let detail: String
    let recommendation: String
    let nextActionTitle: String
    let nextActionSummary: String
    let recommendsRecovery: Bool

    static let unknown = FameDailyScorecardState(
        riskLevel: "Unknown",
        scoreDelta: 0,
        title: "Daily Scorecard: No snapshots",
        detail: "Save a snapshot to unlock scorecard insights.",
        recommendation: "Run `Run Fame Sprint + Save Snapshot` first.",
        nextActionTitle: "Run Fame Sprint + Save Snapshot",
        nextActionSummary: "Create your first daily baseline.",
        recommendsRecovery: false
    )
}

struct FameNextMoveHandoffDrafts: Equatable {
    let xDraft: String
    let blueskyDraft: String
    let linkedInDraft: String
    let checklistCommentDraft: String
}

struct FameLaunchCountdownStatus: Equatable {
    let countdown: String
    let nextAction: String
    let launchRoute: String
    let pulseRisk: String
}

private typealias NextMoveDraftPackMetadata = (
    selectedCommand: String,
    riskLevel: String,
    nextAction: String,
    mustShipAlert: String,
    leadExperiment: String,
    scorecard: String
)

private typealias NextMoveRecommendedHookVariant = (
    xIndex: Int,
    blueskyIndex: Int,
    linkedInIndex: Int,
    xToken: String,
    blueskyToken: String,
    linkedInToken: String,
    reason: String
)

private typealias NextMovePublishingCadence = (
    focus: String,
    firstWindow: String,
    secondWindow: String,
    thirdWindow: String,
    fourthWindow: String,
    reason: String
)

enum FameSnapshotRollup {
    static func parseLedger(_ markdown: String) -> [FameSnapshotRollupEntry] {
        markdown
            .components(separatedBy: .newlines)
            .compactMap(parseRow)
            .sorted { $0.timestamp < $1.timestamp }
    }

    static func markdown(entries: [FameSnapshotRollupEntry], windowSize: Int = 7) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Weekly Fame Rollup

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` to start tracking.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let recommendation = recommendationLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend
        )
        let bestExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let experimentLines = bestExperiments.enumerated().map { index, experiment in
            "\(index + 1)) \(experiment.title) (score \(experiment.score))\n- Why: \(experiment.why)\n- Next: \(experiment.nextMove)"
        }.joined(separator: "\n\n")
        let rows = recentEntries.reversed().map { entry in
            "| \(entry.timestamp) | \(entry.stage) | \(entry.score) | \(entry.day) |"
        }.joined(separator: "\n")

        return """
        # Fluid Reader Weekly Fame Rollup

        Window: last \(safeWindowSize) snapshots.
        Snapshots analyzed: \(recentEntries.count).
        Latest: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day).
        Score trend: \(signed(scoreTrend)) (latest vs oldest in window).
        Score sparkline: \(scoreSparklineValue)
        Average score: \(averageScore).
        Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount).

        ## Recommendation
        \(recommendation)

        ## Best Experiments This Week
        \(experimentLines)

        ## Recent Snapshots
        | Timestamp | Stage | Score | Day |
        | --- | --- | --- | --- |
        \(rows)

        No API keys or private content.
        """
    }

    static func markdownFromLedger(at ledgerURL: URL, windowSize: Int = 7) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return markdown(entries: parseLedger(text), windowSize: windowSize)
    }

    static func actionQueue(entries: [FameSnapshotRollupEntry], windowSize: Int = 7, now: Date = Date(), calendar: Calendar = .current) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader 24h Fame Action Queue

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run this queue.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        let actionBlocks = rankedExperiments.enumerated().map { index, experiment in
            let plan = actionTemplate(for: experiment.title)
            return """
            \(index + 1)) \(experiment.title) (score \(experiment.score))
            - 0-2h: \(plan.quick)
            - 2-8h: \(plan.focus)
            - 8-24h: \(plan.publish)
            - Win signal: \(plan.winSignal)
            """
        }.joined(separator: "\n\n")

        return """
        # Fluid Reader 24h Fame Action Queue

        Date: \(today)
        Latest snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day).
        Score trend window: \(signed(scoreTrend))
        Score sparkline: \(scoreSparklineValue)
        Queue source: \(recentEntries.count) snapshots.

        ## Priority Queue
        \(actionBlocks)

        ## Daily Guardrails
        - Keep one proof loop shipping every 24h.
        - Run one focused reply block before posting.
        - Save a snapshot after execution to update ranking.

        No API keys or private content.
        """
    }

    static func actionQueueFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return actionQueue(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func commandCenter(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Fame Command Center

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run command center.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"

        let trajectory = trajectoryLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            authorityCount: authorityCount
        )
        let riskLevel = riskLevelLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            sparkCount: sparkCount,
            authorityCount: authorityCount
        )
        let guardrail = recommendationLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend
        )
        let computedRiskLines = riskLines(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            sparkCount: sparkCount,
            authorityCount: authorityCount
        )
        let riskMarkdown = computedRiskLines.map { "- \($0)" }.joined(separator: "\n")

        let proofLoopTarget = max(1, min(4, (latestEntry.score + 11) / 12))
        let replyTarget = max(10, min(40, latestEntry.score + 6))
        let distributionTarget = max(2, min(8, momentumCount + authorityCount + (scoreTrend > 0 ? 1 : 0)))

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dayDates = (0..<3).compactMap {
            calendar.date(byAdding: .day, value: $0, to: now)
        }
        let dayPlans = dayDates.enumerated().map { index, date in
            let experiment = rankedExperiments[min(index, rankedExperiments.count - 1)]
            let plan = actionTemplate(for: experiment.title)
            return """
            \(index + 1)) \(dateFormatter.string(from: date)) — \(experiment.title)
            - Execute: \(plan.focus)
            - Publish: \(plan.publish)
            - Win signal: \(plan.winSignal)
            """
        }.joined(separator: "\n\n")

        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Fame Command Center

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## State
        - Latest: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Score trend: \(signed(scoreTrend))
        - Score sparkline: \(scoreSparklineValue)
        - Average score: \(averageScore)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Trajectory: \(trajectory)
        - Lead experiment: \(leadExperiment)
        - Risk level: \(riskLevel)

        ## 72h Execution Plan
        \(dayPlans)

        ## 24h Targets
        - Proof loops: \(proofLoopTarget)
        - High-signal replies: \(replyTarget)
        - Distribution touches: \(distributionTarget)
        - Guardrail: \(guardrail)

        ## Risks to Close
        \(riskMarkdown)

        No API keys or private content.
        """
    }

    static func commandCenterFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return commandCenter(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func operatorDashboard(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Fame Operator Dashboard

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run operator dashboard.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let backupExperiment = rankedExperiments.dropFirst().first?.title ?? leadExperiment
        let leadPlan = actionTemplate(for: leadExperiment)
        let backupPlan = actionTemplate(for: backupExperiment)

        let scorecard = dailyScorecardState(entries: recentEntries, windowSize: safeWindowSize)
        let pulseSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = pulseSignal?.riskLevel ?? "Unknown"
        let pulseAlert = pulseSignal?.mustShipAlert ?? "Save a snapshot to activate pulse alerts."
        let pulseStreak = pulseSignal.map { "\($0.streakDays) day(s)" } ?? "n/a"
        let pulseDaysSinceSnapshot = pulseSignal.map { "\($0.daysSinceLastSnapshot)" } ?? "n/a"
        let pulseLeadExperiment = pulseSignal?.leadExperiment ?? leadExperiment

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Fame Operator Dashboard

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Pulse Radar
        - Pulse risk: \(pulseRisk)
        - Must-ship alert: \(pulseAlert)
        - Snapshot streak: \(pulseStreak)
        - Days since snapshot: \(pulseDaysSinceSnapshot)
        - Lead experiment: \(pulseLeadExperiment)

        ## Daily Scorecard
        - \(scorecard.title)
        - Detail: \(scorecard.detail)
        - Recommendation: \(scorecard.recommendation)
        - Next action: \(scorecard.nextActionTitle) — \(scorecard.nextActionSummary)

        ## 24h Execution Queue
        1) \(leadExperiment)
        - 0-2h: \(leadPlan.quick)
        - 2-8h: \(leadPlan.focus)
        - 8-24h: \(leadPlan.publish)
        - Win signal: \(leadPlan.winSignal)

        2) \(backupExperiment)
        - 0-2h: \(backupPlan.quick)
        - 2-8h: \(backupPlan.focus)
        - 8-24h: \(backupPlan.publish)
        - Win signal: \(backupPlan.winSignal)

        ## Artifact Trail
        - Latest snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Latest sprint file: \(latestEntry.sprintFileName)
        - Latest pack file: \(latestEntry.packFileName)
        - Fast reopen: `Open Latest Recovery Sprint`, `Open Latest Daily Scorecard`, `Open Latest Operator Dashboard`

        No API keys or private content.
        """
    }

    static func operatorDashboardFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return operatorDashboard(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func breakthroughForecast(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Fame Breakthrough Forecast

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run breakthrough forecast.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))
        let stageLift = latestEntry.stage == "Authority" ? 3 : (latestEntry.stage == "Momentum" ? 2 : 1)
        let trendPerSnapshot = Double(scoreTrend) / Double(max(1, recentEntries.count - 1))
        let rawBaseDelta = Int(round(trendPerSnapshot * 5.0)) + stageLift
        let baseDelta = max(-8, min(18, rawBaseDelta))
        let conservativeDelta = max(-8, baseDelta - 4)
        let upsideDelta = min(26, baseDelta + 6)

        let conservativeScore = max(0, latestEntry.score + conservativeDelta)
        let baseScore = max(0, latestEntry.score + baseDelta)
        let upsideScore = max(0, latestEntry.score + upsideDelta)

        let conservativeStage = forecastStage(for: conservativeScore)
        let baseStage = forecastStage(for: baseScore)
        let upsideStage = forecastStage(for: upsideScore)
        let confidence = breakthroughForecastConfidence(scoreTrend: scoreTrend, baseDelta: baseDelta, latestStage: latestEntry.stage)

        let target = breakthroughTarget(for: latestEntry.score)
        let etaDays = breakthroughETAInDays(
            currentScore: latestEntry.score,
            targetScore: target.scoreThreshold,
            projectedDelta: baseDelta
        )

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)
        let etaLine: String
        if let etaDays {
            let etaDate = calendar.date(byAdding: .day, value: etaDays, to: now) ?? now
            etaLine = "\(dateFormatter.string(from: etaDate)) (about \(etaDays) day\(etaDays == 1 ? "" : "s"))"
        } else {
            etaLine = "Not reachable on current trajectory (run recovery + checkpoint)."
        }

        let scorecard = dailyScorecardState(entries: recentEntries, windowSize: safeWindowSize)
        let primaryCommand = scorecard.recommendsRecovery ? "run-fame-recovery-sprint" : "run-fame-command-center"
        let secondaryCommand = baseDelta < 0 ? "run-fame-24h-queue" : "run-fame-weekly-rollup"
        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: recentEntries.filter { $0.stage == "Authority" }.count,
            momentumCount: recentEntries.filter { $0.stage == "Momentum" }.count,
            sparkCount: recentEntries.filter { $0.stage == "Spark" }.count
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"

        let recoveryMix = scorecard.recommendsRecovery ? 40 : (baseDelta < 0 ? 30 : 15)
        let proofMix = scorecard.recommendsRecovery ? 35 : (baseDelta >= 6 ? 25 : 35)
        let distributionMix = max(15, 100 - recoveryMix - proofMix)

        return """
        # Fluid Reader Fame Breakthrough Forecast

        Date: \(today)
        Forecast horizon: next 7 days.
        Baseline: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        Trend velocity: \(signed(scoreTrend)) over \(recentEntries.count) snapshots (avg \(signed(Int(round(trendPerSnapshot)))) per snapshot).
        Score sparkline: \(scoreSparklineValue)
        Forecast confidence: \(confidence)

        ## 7-Day Stage Outlook
        | Scenario | Projected Score | Projected Stage | Signal |
        | --- | --- | --- | --- |
        | Conservative | \(conservativeScore) (\(signed(conservativeDelta))) | \(conservativeStage) | \(forecastScenarioSignal(delta: conservativeDelta, stage: conservativeStage)) |
        | Base | \(baseScore) (\(signed(baseDelta))) | \(baseStage) | \(forecastScenarioSignal(delta: baseDelta, stage: baseStage)) |
        | Upside | \(upsideScore) (\(signed(upsideDelta))) | \(upsideStage) | \(forecastScenarioSignal(delta: upsideDelta, stage: upsideStage)) |

        ## Breakthrough Trigger
        - Next target: \(target.stageName) at score \(target.scoreThreshold).
        - Base-path ETA: \(etaLine)
        - Lead experiment to compound now: \(leadExperiment)
        - Primary command: `\(primaryCommand)`
        - Secondary command: `\(secondaryCommand)`

        ## Execution Mix (Next 7 Days)
        - Recovery / risk containment: \(recoveryMix)% effort.
        - Proof-loop shipping: \(proofMix)% effort.
        - Distribution compounding: \(distributionMix)% effort.
        - Guardrail: Save one fresh snapshot after each must-ship block.

        ## Command Stack
        - `run-fame-breakthrough-forecast`
        - `\(primaryCommand)`
        - `\(secondaryCommand)`
        - `run-fame-daily-scorecard`
        - `run-fame-sprint-snapshot`
        - `open-latest-breakthrough-forecast`

        No API keys or private content.
        """
    }

    static func breakthroughForecastFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return breakthroughForecast(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func dailyMission(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Daily Fame Mission

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run daily mission.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let scorecard = dailyScorecardState(entries: recentEntries, windowSize: safeWindowSize)
        let pulseSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = pulseSignal?.riskLevel ?? scorecard.riskLevel
        let primaryCommand = dailyMissionPrimaryCommand(scorecard: scorecard, pulseRisk: pulseRisk)
        let secondaryCommand = scorecard.scoreDelta >= 0 ? "run-fame-next-move" : "run-fame-daily-checkpoint"
        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = pulseSignal?.leadExperiment ?? rankedExperiments.first?.title ?? "Builder Thread"
        let leadPlan = actionTemplate(for: leadExperiment)
        let mustShipAlert = pulseSignal?.mustShipAlert ?? "Save one fresh snapshot after your next ship block."

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Daily Fame Mission

        Date: \(today)
        Snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        Pulse risk: \(pulseRisk)
        Must-ship alert: \(mustShipAlert)
        Lead experiment: \(leadExperiment)
        Scorecard recommendation: \(scorecard.recommendation)

        ## 3-Hour Mission
        - 0-20m: Run `\(primaryCommand)` and lock the first publish block.
        - 20-90m: Ship lead lane \(leadExperiment) — \(leadPlan.publish)
        - 90-180m: Run `\(secondaryCommand)`, then save one fresh snapshot.
        - Guardrail: \(mustShipAlert)

        ## Command Stack
        - `run-fame-24h-queue`
        - `\(primaryCommand)`
        - `\(secondaryCommand)`
        - `run-fame-daily-scorecard`
        - `run-fame-breakthrough-forecast`
        - `open-fame-snapshot-folder`

        No API keys or private content.
        """
    }

    static func dailyMissionFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return dailyMission(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func morningBrief(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Morning Fame Brief

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run morning brief.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let leadPlan = actionTemplate(for: leadExperiment)

        let scorecard = dailyScorecardState(entries: recentEntries, windowSize: safeWindowSize)
        let pulseSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = pulseSignal?.riskLevel ?? "Unknown"
        let pulseAlert = pulseSignal?.mustShipAlert ?? "Save a snapshot to activate pulse alerts."
        let streakText = pulseSignal.map { "\($0.streakDays) day(s)" } ?? "n/a"
        let daysSinceSnapshotText = pulseSignal.map { "\($0.daysSinceLastSnapshot)" } ?? "n/a"
        let pulseLeadExperiment = pulseSignal?.leadExperiment ?? leadExperiment
        let needsRecovery = scorecard.recommendsRecovery || pulseRisk == "High" || pulseRisk == "Critical"
        let firstShipCommand = needsRecovery ? "run-fame-recovery-sprint" : "run-fame-daily-checkpoint"
        let recoveryTriggerLine = needsRecovery
            ? "Risk is High now, so run recovery sprint before noon if first publish misses."
            : "If pulse risk escalates to High/Critical, run `Run Fame Recovery Sprint` immediately."

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Morning Fame Brief

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Pulse Snapshot
        - Pulse risk: \(pulseRisk)
        - Must-ship alert: \(pulseAlert)
        - Snapshot streak: \(streakText)
        - Days since snapshot: \(daysSinceSnapshotText)
        - Lead experiment: \(pulseLeadExperiment)

        ## Must-Ship Checklist
        - 0-15m: Run `Run Fame Operator Dashboard` and confirm risk + scorecard.
        - 15-45m: Prime the lead lane \(leadExperiment) — \(leadPlan.quick)
        - 45-90m: Publish first proof loop — \(leadPlan.publish)
        - 90m+: Run `\(scorecard.nextActionTitle)` and save fresh snapshot.
        - Recovery trigger: \(recoveryTriggerLine)

        ## Command Stack
        - `run-fame-morning-brief`
        - `run-fame-operator-dashboard`
        - `\(firstShipCommand)`
        - `run-fame-sprint-snapshot`
        - `open-latest-operator-dashboard`

        ## Today Target
        - Score focus: \(scorecard.title)
        - Recommendation: \(scorecard.recommendation)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Average score window: \(averageScore) (\(signed(scoreTrend)) trend)

        No API keys or private content.
        """
    }

    static func morningBriefFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return morningBrief(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func middayBrief(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Midday Fame Brief

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run midday brief.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let backupExperiment = rankedExperiments.dropFirst().first?.title ?? leadExperiment
        let leadPlan = actionTemplate(for: leadExperiment)
        let backupPlan = actionTemplate(for: backupExperiment)

        let scorecard = dailyScorecardState(entries: recentEntries, windowSize: safeWindowSize)
        let pulseSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = pulseSignal?.riskLevel ?? "Unknown"
        let pulseAlert = pulseSignal?.mustShipAlert ?? "Save a snapshot to activate pulse alerts."
        let streakText = pulseSignal.map { "\($0.streakDays) day(s)" } ?? "n/a"
        let daysSinceSnapshotText = pulseSignal.map { "\($0.daysSinceLastSnapshot)" } ?? "n/a"

        let needsRecovery = scorecard.recommendsRecovery || pulseRisk == "High" || pulseRisk == "Critical"
        let decisionCommand: String
        let decisionReason: String
        if needsRecovery {
            decisionCommand = "run-fame-recovery-sprint"
            decisionReason = "Risk is \(pulseRisk) and recovery path protects must-ship momentum."
        } else if scoreTrend < 0 {
            decisionCommand = "run-fame-daily-scorecard"
            decisionReason = "Trend is negative, so recalibrate before the afternoon publish block."
        } else {
            decisionCommand = "run-fame-24h-queue"
            decisionReason = "Momentum is stable; scale distribution and proof-loop throughput."
        }
        let escalationLine = needsRecovery
            ? "Run pulse nudge after shipping to verify risk drops."
            : "If pulse risk flips to High/Critical, switch immediately to `Run Fame Recovery Sprint`."

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Midday Fame Brief

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Midday Pulse Check
        - Pulse risk: \(pulseRisk)
        - Must-ship alert: \(pulseAlert)
        - Snapshot streak: \(streakText)
        - Days since snapshot: \(daysSinceSnapshotText)
        - Score focus: \(scorecard.title)

        ## Decision Gate
        - Primary command now: `\(decisionCommand)`
        - Reason: \(decisionReason)
        - Escalation: \(escalationLine)

        ## Afternoon Ship Plan
        - Lane A: \(leadExperiment) — \(leadPlan.focus)
        - Lane B: \(backupExperiment) — \(backupPlan.focus)
        - Distribution close: \(leadPlan.publish)
        - Win signal: \(leadPlan.winSignal)

        ## Command Stack
        - `run-fame-midday-brief`
        - `run-fame-operator-dashboard`
        - `\(decisionCommand)`
        - `run-fame-sprint-snapshot`
        - `open-latest-midday-brief`
        - `open-latest-operator-dashboard`

        ## 18:00 Close Goal
        - Average score window: \(averageScore) (\(signed(scoreTrend)) trend)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Target: Save one fresh snapshot before end of day.

        No API keys or private content.
        """
    }

    static func middayBriefFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return middayBrief(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func eveningBrief(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Evening Fame Brief

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run evening brief.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let backupExperiment = rankedExperiments.dropFirst().first?.title ?? leadExperiment
        let leadPlan = actionTemplate(for: leadExperiment)

        let scorecard = dailyScorecardState(entries: recentEntries, windowSize: safeWindowSize)
        let pulseSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = pulseSignal?.riskLevel ?? "Unknown"
        let pulseAlert = pulseSignal?.mustShipAlert ?? "Save a snapshot to activate pulse alerts."
        let streakText = pulseSignal.map { "\($0.streakDays) day(s)" } ?? "n/a"

        let needsRecovery = scorecard.recommendsRecovery || pulseRisk == "High" || pulseRisk == "Critical"
        let firstMorningCommand = needsRecovery ? "run-fame-recovery-sprint" : "run-fame-operator-dashboard"
        let morningGuardrail = needsRecovery
            ? "Start tomorrow with recovery sprint before publishing."
            : "Start tomorrow with operator dashboard, then run morning brief."

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Evening Fame Brief

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Day Close Snapshot
        - Latest: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Pulse risk: \(pulseRisk)
        - Must-ship alert: \(pulseAlert)
        - Snapshot streak: \(streakText)
        - Score focus: \(scorecard.title)

        ## Closeout Checklist
        - Save end-of-day baseline with `run-fame-sprint-snapshot`.
        - Capture final score/risk in `run-fame-daily-scorecard`.
        - Close strongest lane \(leadExperiment) — \(leadPlan.publish)
        - Reopen artifacts as needed with `open-latest-evening-brief` and `open-latest-morning-brief`.

        ## Tomorrow 08:00 Launch
        - First command: `\(firstMorningCommand)`
        - Warm-up lane: \(leadExperiment) — \(leadPlan.quick)
        - Backup lane: \(backupExperiment)
        - Guardrail: \(morningGuardrail)
        - Recommendation carryover: \(scorecard.recommendation)

        ## Command Stack
        - `run-fame-evening-brief`
        - `run-fame-sprint-snapshot`
        - `run-fame-morning-brief`
        - `\(firstMorningCommand)`
        - `open-latest-evening-brief`
        - `open-latest-morning-brief`

        ## Next-Day Target
        - Average score window: \(averageScore) (\(signed(scoreTrend)) trend)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Ship one new proof loop before lunch.

        No API keys or private content.
        """
    }

    static func eveningBriefFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return eveningBrief(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func dailyCheckpoint(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Daily Fame Checkpoint

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run checkpoint.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let previousEntry = recentEntries.count > 1 ? recentEntries[recentEntries.count - 2] : nil
        let baselineScore = previousEntry?.score ?? latestEntry.score
        let scoreDelta = latestEntry.score - baselineScore
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let deltaVsAverage = latestEntry.score - averageScore
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let scoreTrend = latestEntry.score - recentEntries[0].score

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let leadPlan = actionTemplate(for: leadExperiment)

        let status = checkpointStatusLine(
            latestEntry: latestEntry,
            scoreDelta: scoreDelta,
            deltaVsAverage: deltaVsAverage
        )
        let riskLevel = riskLevelLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            sparkCount: sparkCount,
            authorityCount: authorityCount
        )
        let guardrail = recommendationLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend
        )
        var alerts = riskLines(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            sparkCount: sparkCount,
            authorityCount: authorityCount
        )
        if previousEntry == nil {
            alerts.insert("Need one more saved snapshot to confirm day-over-day trend.", at: 0)
        }
        let alertsMarkdown = alerts.map { "- \($0)" }.joined(separator: "\n")

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        let previousLine: String
        let stageTransition: String
        if let previousEntry {
            previousLine = "\(previousEntry.timestamp) | \(previousEntry.stage) | score \(previousEntry.score) | \(previousEntry.day)"
            stageTransition = "\(previousEntry.stage) -> \(latestEntry.stage)"
        } else {
            previousLine = "Not enough history yet."
            stageTransition = latestEntry.stage
        }

        return """
        # Fluid Reader Daily Fame Checkpoint

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## KPI Delta
        - Latest: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Previous: \(previousLine)
        - Score delta vs previous: \(signed(scoreDelta))
        - Score delta vs average: \(signed(deltaVsAverage))
        - Score sparkline: \(scoreSparklineValue)
        - Stage transition: \(stageTransition)

        ## Status
        - Momentum status: \(status)
        - Risk level: \(riskLevel)
        - Lead experiment: \(leadExperiment)
        - Guardrail: \(guardrail)

        ## Priority Execution Block
        - 0-2h: \(leadPlan.quick)
        - 2-8h: \(leadPlan.focus)
        - 8-24h: \(leadPlan.publish)
        - Win signal: \(leadPlan.winSignal)

        ## Alerts
        \(alertsMarkdown)

        No API keys or private content.
        """
    }

    static func dailyCheckpointFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return dailyCheckpoint(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func dailyScorecard(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Daily Fame Scorecard

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run scorecard.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let previousEntry = recentEntries.count > 1 ? recentEntries[recentEntries.count - 2] : nil
        let baselineScore = previousEntry?.score ?? latestEntry.score
        let scoreDelta = latestEntry.score - baselineScore
        let scoreTrend = latestEntry.score - recentEntries[0].score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let leadExperiment = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        ).first?.title ?? "Builder Thread"
        let riskLevel = riskLevelLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            sparkCount: sparkCount,
            authorityCount: authorityCount
        )
        let recommendation = checkpointStatusLine(
            latestEntry: latestEntry,
            scoreDelta: scoreDelta,
            deltaVsAverage: latestEntry.score - averageScore
        )

        let nextActionTitle = recommendedDailyScorecardActionTitle(riskLevel: riskLevel)
        let nextActionSummary = recommendedDailyScorecardActionSummary(riskLevel: riskLevel)

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)
        let previousLine: String
        if let previousEntry {
            previousLine = "\(previousEntry.timestamp) | \(previousEntry.stage) | score \(previousEntry.score)"
        } else {
            previousLine = "Not enough history yet."
        }

        return """
        # Fluid Reader Daily Fame Scorecard

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Score Snapshot
        - Latest: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Previous: \(previousLine)
        - Score delta vs previous: \(signed(scoreDelta))
        - Score trend window: \(signed(scoreTrend))
        - Score sparkline: \(scoreSparklineValue)
        - Risk level: \(riskLevel)
        - Lead experiment: \(leadExperiment)

        ## Recommendation
        - \(recommendation)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)

        ## Next Action
        - Suggested action: \(nextActionTitle)
        - Why now: \(nextActionSummary)

        No API keys or private content.
        """
    }

    static func dailyScorecardFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return dailyScorecard(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func dailyScorecardState(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7
    ) -> FameDailyScorecardState {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))
        guard !recentEntries.isEmpty else { return .unknown }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let previousEntry = recentEntries.count > 1 ? recentEntries[recentEntries.count - 2] : nil
        let baselineScore = previousEntry?.score ?? latestEntry.score
        let scoreDelta = latestEntry.score - baselineScore
        let scoreTrend = latestEntry.score - recentEntries[0].score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let riskLevel = riskLevelLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            sparkCount: sparkCount,
            authorityCount: authorityCount
        )
        let recommendation = checkpointStatusLine(
            latestEntry: latestEntry,
            scoreDelta: scoreDelta,
            deltaVsAverage: latestEntry.score - averageScore
        )
        let nextActionTitle = recommendedDailyScorecardActionTitle(riskLevel: riskLevel)
        let nextActionSummary = recommendedDailyScorecardActionSummary(riskLevel: riskLevel)

        return FameDailyScorecardState(
            riskLevel: riskLevel,
            scoreDelta: scoreDelta,
            title: "Daily Scorecard: \(latestEntry.score) (\(signed(scoreDelta)) vs prev)",
            detail: "Trend \(signed(scoreTrend)) · \(latestEntry.stage) · Sparkline \(scoreSparklineValue)",
            recommendation: recommendation,
            nextActionTitle: nextActionTitle,
            nextActionSummary: nextActionSummary,
            recommendsRecovery: riskLevel == "High"
        )
    }

    static func dailyScorecardStateFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7
    ) -> FameDailyScorecardState {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return dailyScorecardState(
            entries: parseLedger(text),
            windowSize: windowSize
        )
    }

    static func pulseNudge(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Fame Pulse Nudge

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run pulse nudge.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let leadPlan = actionTemplate(for: leadExperiment)

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = calendar.timeZone
        dayFormatter.dateFormat = "yyyyMMdd"

        let displayFormatter = DateFormatter()
        displayFormatter.calendar = calendar
        displayFormatter.locale = Locale(identifier: "en_US_POSIX")
        displayFormatter.timeZone = calendar.timeZone
        displayFormatter.dateFormat = "yyyy-MM-dd"

        let snapshotDays = recentEntries.compactMap {
            snapshotDayDate(from: $0.timestamp, formatter: dayFormatter)
        }
        let uniqueSnapshotDays = Array(Set(snapshotDays.map { calendar.startOfDay(for: $0) })).sorted()
        let latestSnapshotDay = uniqueSnapshotDays.last ?? calendar.startOfDay(for: now)
        let streakDays = currentStreakDays(dates: uniqueSnapshotDays, calendar: calendar)
        let daysSinceLastSnapshot = max(
            0,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: latestSnapshotDay),
                to: calendar.startOfDay(for: now)
            ).day ?? 0
        )

        let riskLevel = pulseRiskLevel(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            daysSinceLastSnapshot: daysSinceLastSnapshot
        )
        let streakStatus = streakStatusLine(streakDays: streakDays)
        let mustShipAlert = pulseMustShipAlert(
            riskLevel: riskLevel,
            scoreTrend: scoreTrend,
            daysSinceLastSnapshot: daysSinceLastSnapshot
        )
        let guardrail = recommendationLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend
        )

        let today = displayFormatter.string(from: now)
        let latestSnapshotDateText = displayFormatter.string(from: latestSnapshotDay)

        return """
        # Fluid Reader Fame Pulse Nudge

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Streak Health
        - Snapshot streak: \(streakDays) day(s)
        - Days since last snapshot: \(daysSinceLastSnapshot)
        - Last snapshot day: \(latestSnapshotDateText)
        - Risk level: \(riskLevel)
        - Streak status: \(streakStatus)
        - Must-ship alert: \(mustShipAlert)

        ## Immediate Action
        - Lead experiment: \(leadExperiment)
        - 0-2h: \(leadPlan.quick)
        - 2-8h: \(leadPlan.focus)
        - 8-24h: \(leadPlan.publish)
        - Win signal: \(leadPlan.winSignal)

        ## Recovery Signals
        - Latest snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Score trend window: \(signed(scoreTrend))
        - Score sparkline: \(scoreSparklineValue)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Guardrail: \(guardrail)
        - Next check: Run `Run Daily Fame Checkpoint` after shipping.

        No API keys or private content.
        """
    }

    static func recoverySprint(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Fame Recovery Sprint

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run recovery sprint.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let leadPlan = actionTemplate(for: leadExperiment)

        let signal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let riskLevel = signal?.riskLevel ?? pulseRiskLevel(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            daysSinceLastSnapshot: 0
        )
        let mustShipAlert = signal?.mustShipAlert ?? pulseMustShipAlert(
            riskLevel: riskLevel,
            scoreTrend: scoreTrend,
            daysSinceLastSnapshot: 0
        )
        let streakDays = signal?.streakDays ?? 1
        let daysSinceLastSnapshot = signal?.daysSinceLastSnapshot ?? 0

        let proofLoopTarget: Int
        let replyTarget: Int
        switch riskLevel {
        case "Critical":
            proofLoopTarget = 2
            replyTarget = 30
        case "High":
            proofLoopTarget = 2
            replyTarget = 24
        case "Medium":
            proofLoopTarget = 1
            replyTarget = 18
        default:
            proofLoopTarget = 1
            replyTarget = 12
        }
        let distributionTarget = max(2, min(10, momentumCount + authorityCount + (riskLevel == "Low" ? 1 : 0)))

        let escalationLane: String
        switch riskLevel {
        case "Critical":
            escalationLane = "Red lane: publish within 2h, then lock replies before new creation."
        case "High":
            escalationLane = "Orange lane: ship one proof loop before adding any new experiment."
        case "Medium":
            escalationLane = "Yellow lane: bias toward proof-first output and keep cadence strict."
        default:
            escalationLane = "Green lane: protect momentum while tightening distribution quality."
        }

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Fame Recovery Sprint

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Trigger
        - Latest snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Score trend window: \(signed(scoreTrend))
        - Score sparkline: \(scoreSparklineValue)
        - Risk level: \(riskLevel)
        - Must-ship alert: \(mustShipAlert)
        - Snapshot streak: \(streakDays) day(s), \(daysSinceLastSnapshot) day(s) since last snapshot
        - Lead experiment: \(leadExperiment)

        ## 6h Recovery Plan
        - 0-30m: \(leadPlan.quick)
        - 30-120m: \(leadPlan.focus)
        - 2-6h: \(leadPlan.publish)
        - Win signal: \(leadPlan.winSignal)
        - Escalation lane: \(escalationLane)

        ## Recovery Targets
        - Proof loops to ship today: \(proofLoopTarget)
        - High-signal replies: \(replyTarget)
        - Distribution touches: \(distributionTarget)
        - Stage mix check: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)

        ## Close The Loop
        - Save one fresh snapshot before day end.
        - Run `Run Daily Fame Checkpoint` after shipping.
        - Run `Run Fame Pulse Nudge` to verify risk dropped.

        No API keys or private content.
        """
    }

    static func recoverySprintFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return recoverySprint(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func recoveryChecklist(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader 2h Recovery Checklist

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run recovery checklist.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let backupExperiment = rankedExperiments.dropFirst().first?.title ?? leadExperiment
        let leadPlan = actionTemplate(for: leadExperiment)
        let backupPlan = actionTemplate(for: backupExperiment)

        let transitionPair = latestPulseRiskTransition(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let signal = transitionPair?.signal ?? pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let riskLevel = signal?.riskLevel ?? "Unknown"
        let mustShipAlert = signal?.mustShipAlert ?? "Ship one proof loop and save a fresh snapshot."
        let transitionStatus = pulseRiskTransitionLabel(transitionPair?.transition)
        let needsRecovery = riskLevel == "High" || riskLevel == "Critical"
        let primaryCommand = needsRecovery ? "run-fame-recovery-sprint" : "run-fame-daily-checkpoint"
        let checkpointCommand = needsRecovery ? "run-fame-daily-scorecard" : "run-fame-daily-checkpoint"
        let escalationGuardrail = needsRecovery
            ? "Do not add new experiments until one proof loop ships."
            : "Risk is controlled; recover quality and keep cadence strict."

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader 2h Recovery Checklist

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Recovery Trigger
        - Latest snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        - Pulse risk: \(riskLevel)
        - Transition status: \(transitionStatus)
        - Must-ship alert: \(mustShipAlert)
        - Lead experiment: \(leadExperiment)

        ## 0-20 Minutes
        - Run `\(primaryCommand)` and commit to first ship lane.
        - Prime lane: \(leadPlan.quick)
        - Guardrail: \(escalationGuardrail)

        ## 20-60 Minutes
        - Publish lead lane: \(leadPlan.focus)
        - Backup lane: \(backupExperiment) — \(backupPlan.quick)
        - Reply sweep: \(leadPlan.publish)

        ## 60-120 Minutes
        - Run `\(checkpointCommand)` to verify risk + score movement.
        - Save evidence with `run-fame-sprint-snapshot`.
        - Reopen recovery artifacts with `open-latest-recovery-sprint` and `open-latest-recovery-checklist`.

        ## Command Stack
        - `run-fame-recovery-checklist`
        - `\(primaryCommand)`
        - `\(checkpointCommand)`
        - `run-fame-sprint-snapshot`
        - `open-latest-recovery-checklist`

        ## Success Signal
        - Average score window: \(averageScore) (\(signed(scoreTrend)) trend)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Target: One shipped proof loop plus one saved snapshot in next 2h.

        No API keys or private content.
        """
    }

    static func recoveryChecklistFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return recoveryChecklist(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func recoveryProofPack(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Recovery Proof Pack

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run recovery proof pack.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let backupExperiment = rankedExperiments.dropFirst().first?.title ?? leadExperiment
        let leadPlan = actionTemplate(for: leadExperiment)
        let backupPlan = actionTemplate(for: backupExperiment)

        let transitionPair = latestPulseRiskTransition(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let signal = transitionPair?.signal ?? pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let riskLevel = signal?.riskLevel ?? "Unknown"
        let mustShipAlert = signal?.mustShipAlert ?? "Ship one proof loop and save a fresh snapshot."
        let transitionStatus = pulseRiskTransitionLabel(transitionPair?.transition)
        let urgencyPrefix = (riskLevel == "High" || riskLevel == "Critical")
            ? "Must-ship update:"
            : "Momentum update:"
        let checkpointCommand = (riskLevel == "High" || riskLevel == "Critical")
            ? "run-fame-daily-scorecard"
            : "run-fame-daily-checkpoint"

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Fluid Reader Recovery Proof Pack

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Post-Ready Proof
        - Hook: \(urgencyPrefix) \(mustShipAlert)
        - Build: Today we execute \(leadExperiment) first, then reinforce with \(backupExperiment).
        - Evidence: Latest snapshot \(latestEntry.timestamp) is score \(latestEntry.score) (\(signed(scoreTrend)) trend).
        - CTA: Follow for the next recovery checkpoint in 2h.

        ## Reply Sprint Snippets
        - "Appreciate this—shipping \(leadExperiment) now and reporting results in 2h."
        - "Great point. We are prioritizing proof-first output before any new experiment."
        - "We are tracking transition \(transitionStatus) and tightening execution cadence."

        ## Checkpoint Update
        - Internal status: Pulse risk \(riskLevel), transition \(transitionStatus).
        - Operator note: \(leadPlan.quick)
        - Distribution note: \(backupPlan.publish)
        - Next command: `\(checkpointCommand)` then `run-fame-sprint-snapshot`.

        ## Command Stack
        - `run-fame-recovery-proof-pack`
        - `run-fame-recovery-checklist`
        - `\(checkpointCommand)`
        - `run-fame-sprint-snapshot`
        - `open-latest-recovery-proof-pack`

        ## Tracking Baseline
        - Average score window: \(averageScore)
        - Stage mix: Authority \(authorityCount), Momentum \(momentumCount), Spark \(sparkCount)
        - Target: One post + ten replies + one saved snapshot in next 2h.

        No API keys or private content.
        """
    }

    static func recoveryProofPackFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return recoveryProofPack(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func riskTimeline(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 14,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Fluid Reader Fame Risk Timeline

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run risk timeline.

            No API keys or private content.
            """
        }

        let baselineEntry = recentEntries[0]
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = calendar.timeZone
        dayFormatter.dateFormat = "yyyyMMdd"

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var previousSignal: FamePulseAlertSignal?
        var timelineLines: [String] = []
        for (index, entry) in recentEntries.enumerated() {
            let prefixEntries = Array(recentEntries.prefix(index + 1))
            let scoreTrend = entry.score - baselineEntry.score
            let averageScore = Int(
                round(
                    Double(prefixEntries.map(\.score).reduce(0, +))
                        / Double(prefixEntries.count)
                )
            )
            let authorityCount = prefixEntries.filter { $0.stage == "Authority" }.count
            let momentumCount = prefixEntries.filter { $0.stage == "Momentum" }.count
            let sparkCount = prefixEntries.filter { $0.stage == "Spark" }.count
            let leadExperiment = bestExperiments(
                recentEntries: prefixEntries,
                scoreTrend: scoreTrend,
                averageScore: averageScore,
                authorityCount: authorityCount,
                momentumCount: momentumCount,
                sparkCount: sparkCount
            ).first?.title ?? "Builder Thread"

            let daysSincePreviousSnapshot: Int
            if index == 0 {
                daysSincePreviousSnapshot = 0
            } else {
                let currentDate = snapshotDayDate(from: entry.timestamp, formatter: dayFormatter)
                let previousDate = snapshotDayDate(from: recentEntries[index - 1].timestamp, formatter: dayFormatter)
                if let currentDate, let previousDate {
                    let gapDays = calendar.dateComponents(
                        [.day],
                        from: calendar.startOfDay(for: previousDate),
                        to: calendar.startOfDay(for: currentDate)
                    ).day ?? 0
                    daysSincePreviousSnapshot = max(0, gapDays - 1)
                } else {
                    daysSincePreviousSnapshot = 0
                }
            }

            let riskLevel = pulseRiskLevel(
                latestEntry: entry,
                scoreTrend: scoreTrend,
                daysSinceLastSnapshot: daysSincePreviousSnapshot
            )
            let mustShipAlert = pulseMustShipAlert(
                riskLevel: riskLevel,
                scoreTrend: scoreTrend,
                daysSinceLastSnapshot: daysSincePreviousSnapshot
            )
            let signal = FamePulseAlertSignal(
                riskLevel: riskLevel,
                mustShipAlert: mustShipAlert,
                streakDays: index + 1,
                daysSinceLastSnapshot: daysSincePreviousSnapshot,
                leadExperiment: leadExperiment
            )

            let transitionLabel = pulseRiskTransitionLabel(
                pulseRiskTransition(previous: previousSignal, next: signal)
            )
            timelineLines.append(
                "- \(entry.timestamp) | score \(entry.score) | \(entry.stage) | trend \(signed(scoreTrend)) | \(transitionLabel) | lead \(leadExperiment)"
            )
            previousSignal = signal
        }

        let currentSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let currentTransitionLabel = pulseRiskTransitionLabel(
            pulseRiskTransition(previous: previousSignal, next: currentSignal)
        )
        let currentRiskLevel = currentSignal?.riskLevel ?? "Unknown"
        let currentMustShipAlert = currentSignal?.mustShipAlert
            ?? "Run `Run Fame Sprint + Save Snapshot` to activate pulse alerts."
        let currentStreak = currentSignal?.streakDays ?? 0
        let currentDaysSince = currentSignal?.daysSinceLastSnapshot ?? 0

        return """
        # Fluid Reader Fame Risk Timeline

        Date: \(dateFormatter.string(from: now))
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).

        ## Timeline
        \(timelineLines.joined(separator: "\n"))

        ## Current Pulse
        - Risk now: \(currentRiskLevel)
        - Current transition: \(currentTransitionLabel)
        - Snapshot streak: \(currentStreak)d
        - Since snapshot: \(currentDaysSince)d
        - Score sparkline: \(scoreSparklineValue)
        - Current alert: \(currentMustShipAlert)

        ## Recovery Shortcut
        - Run `Run Fame Recovery Sprint` to create a must-ship recovery plan.
        - Run `Open Latest Recovery Sprint` to reopen your latest saved plan.

        No API keys or private content.
        """
    }

    static func riskTimelineFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 14,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return riskTimeline(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func pulseNudgeFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return pulseNudge(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func pulseBundleFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FameAutoPulseBundle {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        let entries = parseLedger(text)
        return FameAutoPulseBundle(
            checkpointMarkdown: dailyCheckpoint(
                entries: entries,
                windowSize: windowSize,
                now: now,
                calendar: calendar
            ),
            pulseNudgeMarkdown: pulseNudge(
                entries: entries,
                windowSize: windowSize,
                now: now,
                calendar: calendar
            )
        )
    }

    static func pulseAlertSignal(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FamePulseAlertSignal? {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))
        guard !recentEntries.isEmpty else { return nil }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count
        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = Locale(identifier: "en_US_POSIX")
        dayFormatter.timeZone = calendar.timeZone
        dayFormatter.dateFormat = "yyyyMMdd"
        let snapshotDays = recentEntries.compactMap {
            snapshotDayDate(from: $0.timestamp, formatter: dayFormatter)
        }
        let uniqueSnapshotDays = Array(Set(snapshotDays.map { calendar.startOfDay(for: $0) })).sorted()
        let latestSnapshotDay = uniqueSnapshotDays.last ?? calendar.startOfDay(for: now)
        let streakDays = currentStreakDays(dates: uniqueSnapshotDays, calendar: calendar)
        let daysSinceLastSnapshot = max(
            0,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: latestSnapshotDay),
                to: calendar.startOfDay(for: now)
            ).day ?? 0
        )

        let riskLevel = pulseRiskLevel(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            daysSinceLastSnapshot: daysSinceLastSnapshot
        )
        let mustShipAlert = pulseMustShipAlert(
            riskLevel: riskLevel,
            scoreTrend: scoreTrend,
            daysSinceLastSnapshot: daysSinceLastSnapshot
        )

        return FamePulseAlertSignal(
            riskLevel: riskLevel,
            mustShipAlert: mustShipAlert,
            streakDays: streakDays,
            daysSinceLastSnapshot: daysSinceLastSnapshot,
            leadExperiment: leadExperiment
        )
    }

    static func pulseAlertSignalFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FamePulseAlertSignal? {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return pulseAlertSignal(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func pulseWidgetState(signal: FamePulseAlertSignal?) -> FamePulseWidgetState {
        guard let signal else { return .unknown }

        let symbolName: String
        switch signal.riskLevel {
        case "Critical":
            symbolName = "exclamationmark.triangle.fill"
        case "High":
            symbolName = "exclamationmark.triangle"
        case "Medium":
            symbolName = "bolt.badge.clock"
        default:
            symbolName = "checkmark.circle.fill"
        }

        return FamePulseWidgetState(
            riskLevel: signal.riskLevel,
            title: pulseRiskMenuTitle(signal: signal),
            detail: "\(pulseRiskMenuDetail(signal: signal)) · \(signal.mustShipAlert)",
            symbolName: symbolName
        )
    }

    static func pulseWidgetStateFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FamePulseWidgetState {
        pulseWidgetState(
            signal: pulseAlertSignalFromLedger(
                at: ledgerURL,
                windowSize: windowSize,
                now: now,
                calendar: calendar
            )
        )
    }

    static func pulseRiskTransition(
        previous: FamePulseAlertSignal?,
        next: FamePulseAlertSignal?
    ) -> FamePulseRiskTransition? {
        guard let next else { return nil }

        let fromRiskLevel = previous?.riskLevel ?? "Unknown"
        let toRiskLevel = next.riskLevel
        guard fromRiskLevel != toRiskLevel else { return nil }

        let fromOrder = pulseRiskOrder(level: fromRiskLevel)
        let toOrder = pulseRiskOrder(level: toRiskLevel)
        let isEscalation: Bool
        if fromRiskLevel == "Unknown" {
            isEscalation = toOrder >= pulseRiskOrder(level: "High")
        } else {
            isEscalation = toOrder > fromOrder
        }

        return FamePulseRiskTransition(
            fromRiskLevel: fromRiskLevel,
            toRiskLevel: toRiskLevel,
            isEscalation: isEscalation
        )
    }

    static func pulseRiskMenuTitle(signal: FamePulseAlertSignal?) -> String {
        guard let signal else {
            return "Pulse Risk: Unknown (save snapshot)"
        }

        switch signal.riskLevel {
        case "Critical":
            return "Pulse Risk: Critical — MUST SHIP"
        case "High":
            return "Pulse Risk: High — Recovery"
        case "Medium":
            return "Pulse Risk: Medium"
        default:
            return "Pulse Risk: Low"
        }
    }

    static func pulseRiskMenuDetail(signal: FamePulseAlertSignal?) -> String {
        guard let signal else {
            return "Streak: n/a · Lead: n/a"
        }

        return "Streak \(signal.streakDays)d · Since snapshot \(signal.daysSinceLastSnapshot)d · Lead \(signal.leadExperiment)"
    }

    static func nextMoveHandoff(
        commandID: String,
        commandLabel: String,
        signal: FamePulseAlertSignal?,
        transition: FamePulseRiskTransition?,
        scorecard: FameDailyScorecardState,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let riskLevel = signal?.riskLevel ?? scorecard.riskLevel
        let transitionStatus = pulseRiskTransitionLabel(transition)
        let mustShipAlert = signal?.mustShipAlert ?? "Save a snapshot to activate pulse alerts."
        let leadExperiment = signal?.leadExperiment ?? "n/a"
        let streakText = signal.map { "\($0.streakDays)d" } ?? "n/a"
        let sinceSnapshotText = signal.map { "\($0.daysSinceLastSnapshot)d" } ?? "n/a"
        let nextActionLine = compactLine(scorecard.nextActionTitle)
        let ownerUpdatePlainLine = "Ran Run Fame Next Move -> \(commandLabel) (\(commandID)); next action: \(nextActionLine)."
        let ownerUpdateLine = "Ran `Run Fame Next Move` → `\(commandLabel)` (\(commandID)); next action: \(scorecard.nextActionTitle)."
        let xDraft = clampedLine(
            "Pulse \(riskLevel) (\(transitionStatus)). Ran Run Fame Next Move -> \(commandLabel). Next: \(nextActionLine). #buildinpublic",
            maxLength: 280
        )
        let blueskyDraft = clampedLine(
            "Pulse \(riskLevel) (\(transitionStatus)). Executed \(commandLabel). Next action: \(nextActionLine). #buildinpublic",
            maxLength: 300
        )
        let linkedInDraft = compactLine(
            "Founder ops update: pulse risk \(riskLevel) (\(transitionStatus)); lead experiment \(leadExperiment). Executed \(commandLabel). Next action: \(nextActionLine)."
        )
        let checklistCommentDraft = compactLine(
            "Artifact link: [paste next-move handoff link] | Owner update: \(ownerUpdatePlainLine)"
        )

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        <!-- founder-fame-next-move-handoff -->
        # Founder Fame Next Move Handoff

        Date: \(today)

        Action: Run Fame Next Move
        Selected command: \(commandLabel) (`\(commandID)`)
        Pulse risk: \(riskLevel) (\(transitionStatus))
        Must-ship alert: \(mustShipAlert)
        Lead experiment: \(leadExperiment)
        Streak: \(streakText), since snapshot: \(sinceSnapshotText)
        Scorecard: \(scorecard.title)
        Suggested next action: \(scorecard.nextActionTitle)
        Owner update: \(ownerUpdateLine)
        X draft (<=280): \(xDraft)
        Bluesky draft (<=300): \(blueskyDraft)
        LinkedIn draft: \(linkedInDraft)
        Checklist comment draft: \(checklistCommentDraft)

        No API keys or private content.
        """
    }

    static func nextMoveHandoffDrafts(from handoff: String) -> FameNextMoveHandoffDrafts? {
        guard let xDraft = extractPrefixedLine(prefix: "X draft (<=280):", from: handoff),
              let linkedInDraft = extractPrefixedLine(prefix: "LinkedIn draft:", from: handoff),
              let checklistCommentDraft = extractPrefixedLine(prefix: "Checklist comment draft:", from: handoff) else {
            return nil
        }
        let blueskyDraft = extractPrefixedLine(prefix: "Bluesky draft (<=300):", from: handoff) ?? xDraft

        return FameNextMoveHandoffDrafts(
            xDraft: xDraft,
            blueskyDraft: blueskyDraft,
            linkedInDraft: linkedInDraft,
            checklistCommentDraft: checklistCommentDraft
        )
    }

    static func nextMoveDraftPack(from handoff: String) -> String? {
        guard let drafts = nextMoveHandoffDrafts(from: handoff) else { return nil }
        guard let metadata = nextMoveHandoffDraftPackMetadata(from: handoff) else {
            return """
            X:
            \(drafts.xDraft)

            Bluesky:
            \(drafts.blueskyDraft)

            LinkedIn:
            \(drafts.linkedInDraft)

            Checklist:
            \(drafts.checklistCommentDraft)
            """
        }

        let xFollowUp = clampedLine(
            "Follow-up: \(metadata.mustShipAlert). Ran \(metadata.selectedCommand). Next: \(metadata.nextAction). #buildinpublic",
            maxLength: 280
        )
        let blueskyFollowUp = clampedLine(
            "Follow-up signal (\(metadata.riskLevel)): \(metadata.mustShipAlert). Ran \(metadata.selectedCommand). Next: \(metadata.nextAction). #buildinpublic",
            maxLength: 300
        )
        let linkedInComment = compactLine(
            "Operator comment: \(metadata.mustShipAlert). We executed \(metadata.selectedCommand) and next action is \(metadata.nextAction). If you ran this loop, what metric would you watch first?"
        )
        let replyOpener = compactLine(
            "Quick check: we just ran \(metadata.selectedCommand) and next step is \(metadata.nextAction). What should we pressure-test first?"
        )
        let hookVariants = nextMoveHookVariants(metadata: metadata)
        let recommendedVariant = nextMoveRecommendedHookVariant(metadata: metadata)
        let cadence = nextMovePublishingCadence(
            metadata: metadata,
            recommendedVariant: recommendedVariant
        )

        return """
        X:
        \(drafts.xDraft)

        X Follow-up:
        \(xFollowUp)

        Bluesky:
        \(drafts.blueskyDraft)

        Bluesky Follow-up:
        \(blueskyFollowUp)

        X Hook Variants:
        - A) \(hookVariants.x[0])
        - B) \(hookVariants.x[1])
        - C) \(hookVariants.x[2])

        Bluesky Hook Variants:
        - A) \(hookVariants.bluesky[0])
        - B) \(hookVariants.bluesky[1])
        - C) \(hookVariants.bluesky[2])

        LinkedIn:
        \(drafts.linkedInDraft)

        LinkedIn Comment:
        \(linkedInComment)

        LinkedIn Hook Variants:
        - A) \(hookVariants.linkedIn[0])
        - B) \(hookVariants.linkedIn[1])
        - C) \(hookVariants.linkedIn[2])

        Recommended Hook Variant (Risk + Momentum-aware):
        - X: \(recommendedVariant.xToken) — \(hookVariants.x[recommendedVariant.xIndex])
        - Bluesky: \(recommendedVariant.blueskyToken) — \(hookVariants.bluesky[recommendedVariant.blueskyIndex])
        - LinkedIn: \(recommendedVariant.linkedInToken) — \(hookVariants.linkedIn[recommendedVariant.linkedInIndex])
        - Why: \(recommendedVariant.reason)

        Publishing Cadence (Next 60m):
        - Focus: \(cadence.focus)
        - 0-15m: \(cadence.firstWindow)
        - 15-30m: \(cadence.secondWindow)
        - 30-45m: \(cadence.thirdWindow)
        - 45-60m: \(cadence.fourthWindow)
        - Why this sequence: \(cadence.reason)

        Checklist:
        \(drafts.checklistCommentDraft)

        Reply Opener:
        \(replyOpener)
        """
    }

    static func nextMoveFirstCadenceStep(from handoff: String) -> String? {
        guard let drafts = nextMoveHandoffDrafts(from: handoff) else { return nil }

        guard let metadata = nextMoveHandoffDraftPackMetadata(from: handoff) else {
            return """
            First Cadence Step (0-15m):
            Channel: X
            Draft: \(drafts.xDraft)
            """
        }

        let hookVariants = nextMoveHookVariants(metadata: metadata)
        let recommendedVariant = nextMoveRecommendedHookVariant(metadata: metadata)
        let cadence = nextMovePublishingCadence(
            metadata: metadata,
            recommendedVariant: recommendedVariant
        )
        let firstStep = nextMoveFirstCadenceHook(
            metadata: metadata,
            hookVariants: hookVariants,
            recommendedVariant: recommendedVariant
        )

        return """
        First Cadence Step (0-15m):
        Channel: \(firstStep.channel) (\(firstStep.token))
        Draft: \(firstStep.draft)

        Cadence focus: \(cadence.focus)
        Next (15-30m): \(cadence.secondWindow)
        """
    }

    static func narrativeLab(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Founder Fame Narrative Lab

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run narrative lab.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let trajectory = trajectoryLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            authorityCount: authorityCount
        )

        let signal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = signal?.riskLevel
            ?? riskLevelLine(
                latestEntry: latestEntry,
                scoreTrend: scoreTrend,
                sparkCount: sparkCount,
                authorityCount: authorityCount
            )
        let mustShipAlert = signal?.mustShipAlert ?? "Ship one proof loop and save one fresh snapshot today."

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        let routeBlocks = rankedExperiments.enumerated().map { index, experiment in
            let plan = actionTemplate(for: experiment.title)
            let commandID = narrativePrimaryCommandID(
                experimentTitle: experiment.title,
                pulseRisk: pulseRisk
            )
            let routeLabel: String
            switch index {
            case 0:
                routeLabel = "Primary lane"
            case 1:
                routeLabel = "Backup lane"
            default:
                routeLabel = "Wildcard lane"
            }
            let drafts = narrativeRouteDrafts(
                experimentTitle: experiment.title,
                plan: plan,
                latestEntry: latestEntry,
                pulseRisk: pulseRisk,
                trajectory: trajectory
            )

            return """
            \(index + 1)) \(experiment.title) — \(routeLabel)
            - Why now: \(experiment.why)
            - Primary command: `\(commandID)`
            - Quick block: \(plan.quick)
            - Publish beat: \(plan.publish)
            - Win signal: \(plan.winSignal)
            - Proof source: \(latestEntry.packFileName)
            - X draft (<=280): \(drafts.xDraft)
            - LinkedIn draft: \(drafts.linkedInDraft)
            - Reply opener: \(drafts.replyOpener)
            """
        }.joined(separator: "\n\n")

        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"

        return """
        # Founder Fame Narrative Lab

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed).
        Current snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        Score trend: \(signed(scoreTrend)) · Sparkline \(scoreSparklineValue) · Average \(averageScore)
        Pulse risk: \(pulseRisk)
        Trajectory: \(trajectory)
        Must-ship alert: \(mustShipAlert)
        Lead route: \(leadExperiment)

        ## Narrative Route Board
        \(routeBlocks)

        ## Command Stack
        - `run-fame-narrative-lab`
        - `run-fame-next-move`
        - `run-fame-daily-scorecard`
        - `open-latest-narrative-lab`

        No API keys or private content.
        """
    }

    static func narrativeLabFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return narrativeLab(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func spotlightPack(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Founder Fame Spotlight Pack

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run spotlight pack.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let signal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = signal?.riskLevel
            ?? riskLevelLine(
                latestEntry: latestEntry,
                scoreTrend: scoreTrend,
                sparkCount: sparkCount,
                authorityCount: authorityCount
            )
        let mustShipAlert = signal?.mustShipAlert ?? "Ship one proof loop and save one fresh snapshot today."
        let trajectory = trajectoryLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            authorityCount: authorityCount
        )

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadExperiment = rankedExperiments.first?.title ?? "Builder Thread"
        let leadWhy = rankedExperiments.first?.why
            ?? "Prioritize one proof-first narrative loop and compound it through distribution."
        let leadPlan = actionTemplate(for: leadExperiment)
        let primaryCommandID = narrativePrimaryCommandID(
            experimentTitle: leadExperiment,
            pulseRisk: pulseRisk
        )
        let drafts = spotlightDrafts(
            route: leadExperiment,
            latestEntry: latestEntry,
            pulseRisk: pulseRisk,
            mustShipAlert: mustShipAlert,
            trajectory: trajectory,
            leadPlan: leadPlan
        )
        let replyLadder = spotlightReplyLadder(
            route: leadExperiment,
            leadPlan: leadPlan,
            pulseRisk: pulseRisk
        ).enumerated().map { index, line in
            "\(index + 1)) \(line)"
        }.joined(separator: "\n")

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        return """
        # Founder Fame Spotlight Pack

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed)
        Current snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        Score trend: \(signed(scoreTrend)) · Sparkline \(scoreSparklineValue) · Average \(averageScore)
        Pulse risk: \(pulseRisk)
        Trajectory: \(trajectory)
        Must-ship alert: \(mustShipAlert)

        ## Primary Spotlight Route
        - Route winner: \(leadExperiment)
        - Why now: \(leadWhy)
        - Primary command: `\(primaryCommandID)`
        - First execution block: \(leadPlan.quick)
        - Publish beat: \(leadPlan.publish)
        - Win signal: \(leadPlan.winSignal)
        - Proof source: \(latestEntry.packFileName)

        ## Channel Drafts
        - X primary (<=280): \(drafts.xPrimary)
        - X follow-up (<=280): \(drafts.xFollowUp)
        - LinkedIn draft: \(drafts.linkedIn)
        - Partner DM draft: \(drafts.partnerDM)
        - Checklist comment draft: \(drafts.checklistComment)

        ## Reply Ladder
        \(replyLadder)

        ## Command Stack
        - `run-fame-spotlight-pack`
        - `run-fame-narrative-lab`
        - `run-fame-next-move-copy-drafts`
        - `open-latest-spotlight-pack`

        No API keys or private content.
        """
    }

    static func spotlightPackFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return spotlightPack(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func launchDayScript(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return """
            # Founder Fame Launch Day Script

            No snapshots yet.
            Run `Run Fame Sprint + Save Snapshot` first, then run launch day script.

            No API keys or private content.
            """
        }

        let latestEntry = recentEntries[recentEntries.count - 1]
        let oldestEntry = recentEntries[0]
        let scoreTrend = latestEntry.score - oldestEntry.score
        let averageScore = Int(round(Double(recentEntries.map(\.score).reduce(0, +)) / Double(recentEntries.count)))
        let scoreSparklineValue = scoreSparkline(scores: recentEntries.map(\.score))

        let authorityCount = recentEntries.filter { $0.stage == "Authority" }.count
        let momentumCount = recentEntries.filter { $0.stage == "Momentum" }.count
        let sparkCount = recentEntries.filter { $0.stage == "Spark" }.count

        let signal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let pulseRisk = signal?.riskLevel
            ?? riskLevelLine(
                latestEntry: latestEntry,
                scoreTrend: scoreTrend,
                sparkCount: sparkCount,
                authorityCount: authorityCount
            )
        let mustShipAlert = signal?.mustShipAlert ?? "Ship one proof loop and save one fresh snapshot today."
        let trajectory = trajectoryLine(
            latestEntry: latestEntry,
            scoreTrend: scoreTrend,
            authorityCount: authorityCount
        )

        let rankedExperiments = bestExperiments(
            recentEntries: recentEntries,
            scoreTrend: scoreTrend,
            averageScore: averageScore,
            authorityCount: authorityCount,
            momentumCount: momentumCount,
            sparkCount: sparkCount
        )
        let leadRoute = rankedExperiments.first?.title ?? "Builder Thread"
        let leadWhy = rankedExperiments.first?.why
            ?? "Prioritize one proof-first narrative loop and compound it through distribution."
        let leadPlan = actionTemplate(for: leadRoute)
        let primaryCommandID = narrativePrimaryCommandID(
            experimentTitle: leadRoute,
            pulseRisk: pulseRisk
        )
        let drafts = spotlightDrafts(
            route: leadRoute,
            latestEntry: latestEntry,
            pulseRisk: pulseRisk,
            mustShipAlert: mustShipAlert,
            trajectory: trajectory,
            leadPlan: leadPlan
        )
        let replyLadder = spotlightReplyLadder(
            route: leadRoute,
            leadPlan: leadPlan,
            pulseRisk: pulseRisk
        )

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)
        let launchAnchor = now.addingTimeInterval(45 * 60)
        let anchorFormatter = DateFormatter()
        anchorFormatter.calendar = calendar
        anchorFormatter.locale = Locale(identifier: "en_US_POSIX")
        anchorFormatter.timeZone = calendar.timeZone
        anchorFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let launchAnchorLine = anchorFormatter.string(from: launchAnchor)

        return """
        # Founder Fame Launch Day Script

        Date: \(today)
        Window: last \(safeWindowSize) snapshots (\(recentEntries.count) analyzed)
        Current snapshot: \(latestEntry.timestamp) | \(latestEntry.stage) | score \(latestEntry.score) | \(latestEntry.day)
        Score trend: \(signed(scoreTrend)) · Sparkline \(scoreSparklineValue) · Average \(averageScore)
        Pulse risk: \(pulseRisk)
        Trajectory: \(trajectory)
        Launch route: \(leadRoute)
        Route thesis: \(leadWhy)
        Must-ship alert: \(mustShipAlert)
        Launch anchor: \(launchAnchorLine) (local)

        ## Launch Timeline (180m)
        - T-45m: Run `\(primaryCommandID)` and lock proof source (`\(latestEntry.packFileName)`).
        - T-20m: Publish X primary draft: \(drafts.xPrimary)
        - T+10m: Reply ladder seed: \(replyLadder[0])
        - T+35m: Publish X follow-up draft: \(drafts.xFollowUp)
        - T+70m: Publish LinkedIn draft: \(drafts.linkedIn)
        - T+110m: Send partner DM draft: \(drafts.partnerDM)
        - T+150m: Post checklist comment: \(drafts.checklistComment)

        ## Operator Checklist
        - [ ] Proof asset and metrics screenshot attached.
        - [ ] Primary X post live with first reply pinned.
        - [ ] Follow-up and LinkedIn posts shipped on schedule.
        - [ ] Partner co-amplification DM sent to top collaborators.
        - [ ] Final checkpoint update posted in launch checklist.

        ## Reply Ladder
        1) \(replyLadder[0])
        2) \(replyLadder[1])
        3) \(replyLadder[2])
        4) \(replyLadder[3])
        5) \(replyLadder[4])

        ## Command Stack
        - `run-fame-launch-day-script`
        - `run-fame-launch-countdown`
        - `run-fame-spotlight-pack`
        - `run-fame-narrative-lab`
        - `run-fame-next-move-copy-drafts`
        - `open-latest-launch-day-script`
        - `open-latest-launch-countdown`

        No API keys or private content.
        """
    }

    static func launchDayScriptFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return launchDayScript(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func launchCountdown(
        launchScript: String,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let timelineEvents = parseLaunchTimelineEvents(from: launchScript)
        guard !timelineEvents.isEmpty else {
            return """
            # Founder Fame Launch Countdown

            No launch timeline found.
            Run `Run Fame Launch Day Script` first, then run launch countdown.

            ## Command Stack
            - `run-fame-launch-countdown`
            - `run-fame-launch-day-script`
            - `open-latest-launch-day-script`

            No API keys or private content.
            """
        }

        let launchAnchor = launchAnchorDate(from: launchScript, now: now, calendar: calendar)
        let countdownMinutes = Int((now.timeIntervalSince(launchAnchor) / 60).rounded())
        let currentCountdown = launchOffsetLabel(minutes: countdownMinutes)

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let nowLine = dateFormatter.string(from: now)
        let anchorLine = dateFormatter.string(from: launchAnchor)

        let pulseRisk = extractPrefixedLine(prefix: "Pulse risk: ", from: launchScript) ?? "Unknown"
        let launchRoute = extractPrefixedLine(prefix: "Launch route: ", from: launchScript) ?? "Builder Thread"
        let mustShipAlert = extractPrefixedLine(prefix: "Must-ship alert: ", from: launchScript)
            ?? "Ship one proof loop and save one fresh snapshot today."

        let nextEvent = timelineEvents.first {
            launchAnchor.addingTimeInterval(TimeInterval($0.offsetMinutes * 60)) >= now
        } ?? timelineEvents.last!
        let nextAction = "\(launchOffsetLabel(minutes: nextEvent.offsetMinutes)): \(nextEvent.action)"

        let statusLines = timelineEvents.enumerated().map { index, event in
            let dueDate = launchAnchor.addingTimeInterval(TimeInterval(event.offsetMinutes * 60))
            let minutesUntil = Int((dueDate.timeIntervalSince(now) / 60).rounded())
            let status = launchCountdownStatusPhrase(minutesUntil: minutesUntil)
            return "\(index + 1)) [\(status)] \(launchOffsetLabel(minutes: event.offsetMinutes)) — \(event.action)"
        }.joined(separator: "\n")

        return """
        # Founder Fame Launch Countdown

        Now: \(nowLine) (local)
        Countdown: \(currentCountdown)
        Launch anchor: \(anchorLine) (local)
        Pulse risk: \(pulseRisk)
        Launch route: \(launchRoute)
        Must-ship alert: \(mustShipAlert)
        Next action now: \(nextAction)

        ## Timeline Status
        \(statusLines)

        ## Command Stack
        - `run-fame-launch-countdown`
        - `run-fame-launch-day-script`
        - `open-latest-launch-day-script`
        - `open-latest-launch-countdown`

        No API keys or private content.
        """
    }

    static func launchCountdownFromLaunchScript(
        at launchScriptURL: URL,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let text = (try? String(contentsOf: launchScriptURL, encoding: .utf8)) ?? ""
        return launchCountdown(
            launchScript: text,
            now: now,
            calendar: calendar
        )
    }

    static func launchCountdownStatus(from countdown: String) -> FameLaunchCountdownStatus? {
        guard let countdownLabel = extractPrefixedLine(prefix: "Countdown: ", from: countdown),
              let nextAction = extractPrefixedLine(prefix: "Next action now: ", from: countdown) else {
            return nil
        }

        let launchRoute = extractPrefixedLine(prefix: "Launch route: ", from: countdown) ?? "Builder Thread"
        let pulseRisk = extractPrefixedLine(prefix: "Pulse risk: ", from: countdown) ?? "Unknown"
        return FameLaunchCountdownStatus(
            countdown: countdownLabel,
            nextAction: nextAction,
            launchRoute: launchRoute,
            pulseRisk: pulseRisk
        )
    }

    static func latestPulseRiskTransition(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (transition: FamePulseRiskTransition, signal: FamePulseAlertSignal)? {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))
        guard !recentEntries.isEmpty else { return nil }
        guard let currentSignal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        ) else {
            return nil
        }

        let previousSignal: FamePulseAlertSignal?
        if recentEntries.count > 1 {
            previousSignal = pulseAlertSignal(
                entries: Array(recentEntries.dropLast()),
                windowSize: safeWindowSize,
                now: now,
                calendar: calendar
            )
        } else {
            previousSignal = nil
        }

        guard let transition = pulseRiskTransition(previous: previousSignal, next: currentSignal) else {
            return nil
        }
        return (transition: transition, signal: currentSignal)
    }

    static func latestPulseRiskTransitionFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (transition: FamePulseRiskTransition, signal: FamePulseAlertSignal)? {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return latestPulseRiskTransition(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    static func escalationNudge(
        transition: FamePulseRiskTransition?,
        signal: FamePulseAlertSignal?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FamePulseEscalationNudge {
        let riskLevel = signal?.riskLevel ?? "Unknown"
        let transitionStatus: String
        if let transition {
            if transition.fromRiskLevel == "Unknown" {
                transitionStatus = "Calibrated at \(transition.toRiskLevel)"
            } else if transition.isEscalation {
                transitionStatus = "Escalated \(transition.fromRiskLevel) -> \(transition.toRiskLevel)"
            } else {
                transitionStatus = "Improved \(transition.fromRiskLevel) -> \(transition.toRiskLevel)"
            }
        } else {
            transitionStatus = "Steady \(riskLevel)"
        }

        let isEscalating = transition?.isEscalation == true && transition?.fromRiskLevel != "Unknown"
        let isRiskElevated = riskLevel == "High" || riskLevel == "Critical"
        let requiresImmediateRecovery = isEscalating || isRiskElevated
        let primaryCommandID = requiresImmediateRecovery ? "run-fame-recovery-sprint" : "run-fame-daily-checkpoint"
        let secondaryCommandID = requiresImmediateRecovery ? "run-fame-risk-timeline" : "run-fame-operator-dashboard"

        let title: String
        if isEscalating && riskLevel == "Critical" {
            title = "Fame Escalation Nudge: Critical"
        } else if isEscalating || riskLevel == "High" {
            title = "Fame Escalation Nudge: High"
        } else if riskLevel == "Medium" {
            title = "Fame Escalation Nudge: Medium"
        } else {
            title = "Fame Escalation Nudge: Stable"
        }

        let signalAlert = signal?.mustShipAlert ?? "Save a snapshot to activate pulse alerts."
        let leadExperiment = signal?.leadExperiment ?? "n/a"
        let streakText = signal.map { "\($0.streakDays)d" } ?? "n/a"
        let daysSinceSnapshotText = signal.map { "\($0.daysSinceLastSnapshot)d" } ?? "n/a"
        let actionReason = requiresImmediateRecovery
            ? "Recovery is prioritized because risk is \(riskLevel) and trajectory needs containment."
            : "Risk is stable; stay on offense and protect cadence."
        let escalationLine = requiresImmediateRecovery
            ? "Execute recovery block immediately, then save a fresh snapshot."
            : "No immediate escalation. Keep shipping and save one fresh snapshot today."

        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: now)

        let markdown = """
        # Fluid Reader Fame Escalation Nudge

        Date: \(today)
        Status: \(transitionStatus)
        Pulse risk now: \(riskLevel)

        ## Pulse Snapshot
        - Must-ship alert: \(signalAlert)
        - Lead experiment: \(leadExperiment)
        - Snapshot streak: \(streakText)
        - Since snapshot: \(daysSinceSnapshotText)

        ## Recovery Decision
        - Primary command: `\(primaryCommandID)`
        - Secondary command: `\(secondaryCommandID)`
        - Why: \(actionReason)
        - Guardrail: \(escalationLine)

        ## Next 90 Minutes
        - 0-15m: Run `\(primaryCommandID)` and execute first must-ship block.
        - 15-45m: Run `\(secondaryCommandID)` to confirm transition source and risk path.
        - 45-90m: Run `run-fame-daily-scorecard`, then `run-fame-sprint-snapshot`.
        - Reopen latest recovery plan with `open-latest-recovery-sprint`.

        ## Command Stack
        - `run-fame-escalation-nudge`
        - `\(primaryCommandID)`
        - `\(secondaryCommandID)`
        - `run-fame-daily-scorecard`
        - `run-fame-sprint-snapshot`
        - `open-latest-escalation-nudge`

        No API keys or private content.
        """

        return FamePulseEscalationNudge(
            title: title,
            transitionStatus: transitionStatus,
            primaryCommandID: primaryCommandID,
            secondaryCommandID: secondaryCommandID,
            requiresImmediateRecovery: requiresImmediateRecovery,
            markdown: markdown
        )
    }

    static func escalationNudge(
        entries: [FameSnapshotRollupEntry],
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FamePulseEscalationNudge {
        let safeWindowSize = max(1, windowSize)
        let recentEntries = Array(entries.suffix(safeWindowSize))

        guard !recentEntries.isEmpty else {
            return FamePulseEscalationNudge(
                title: "Fame Escalation Nudge: Unknown",
                transitionStatus: "No snapshots",
                primaryCommandID: "run-fame-sprint-snapshot",
                secondaryCommandID: "run-fame-operator-dashboard",
                requiresImmediateRecovery: false,
                markdown: """
                # Fluid Reader Fame Escalation Nudge

                No snapshots yet.
                Run `Run Fame Sprint + Save Snapshot` first, then run escalation nudge.

                No API keys or private content.
                """
            )
        }

        let signal = pulseAlertSignal(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )
        let transition = latestPulseRiskTransition(
            entries: recentEntries,
            windowSize: safeWindowSize,
            now: now,
            calendar: calendar
        )?.transition
        return escalationNudge(
            transition: transition,
            signal: signal,
            now: now,
            calendar: calendar
        )
    }

    static func escalationNudgeFromLedger(
        at ledgerURL: URL,
        windowSize: Int = 7,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> FamePulseEscalationNudge {
        let text = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        return escalationNudge(
            entries: parseLedger(text),
            windowSize: windowSize,
            now: now,
            calendar: calendar
        )
    }

    private static func parseRow(_ line: String) -> FameSnapshotRollupEntry? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("|"), trimmed.hasSuffix("|") else { return nil }

        let columns = trimmed
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard columns.count >= 8 else { return nil }

        let timestamp = String(columns[1])
        if timestamp.isEmpty || timestamp == "Timestamp" || timestamp == "---" {
            return nil
        }

        let stage = String(columns[2])
        let scoreValue = String(columns[3])
        let day = String(columns[4])
        let sprintFileName = String(columns[5])
        let packFileName = String(columns[6])
        let score = Int(scoreValue.filter(\.isNumber)) ?? 0

        return FameSnapshotRollupEntry(
            timestamp: timestamp,
            stage: stage,
            score: score,
            day: day,
            sprintFileName: sprintFileName,
            packFileName: packFileName
        )
    }

    private static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private static func scoreSparkline(scores: [Int]) -> String {
        guard !scores.isEmpty else { return "-" }

        let symbols = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
        guard let minScore = scores.min(), let maxScore = scores.max() else {
            return "-"
        }
        guard minScore != maxScore else {
            return String(repeating: "▅", count: scores.count)
        }

        let range = Double(maxScore - minScore)
        return scores.map { score in
            let normalized = Double(score - minScore) / range
            let rawIndex = Int(round(normalized * Double(symbols.count - 1)))
            let clampedIndex = max(0, min(symbols.count - 1, rawIndex))
            return symbols[clampedIndex]
        }.joined()
    }

    private static func pulseRiskTransitionLabel(_ transition: FamePulseRiskTransition?) -> String {
        guard let transition else { return "steady" }

        if transition.fromRiskLevel == "Unknown" {
            return "init \(transition.toRiskLevel)"
        }
        if transition.isEscalation {
            return "escalated \(transition.fromRiskLevel) -> \(transition.toRiskLevel)"
        }
        return "improved \(transition.fromRiskLevel) -> \(transition.toRiskLevel)"
    }

    private static func compactLine(_ value: String) -> String {
        value
            .split { $0.isWhitespace || $0.isNewline }
            .joined(separator: " ")
    }

    private static func clampedLine(_ value: String, maxLength: Int) -> String {
        let trimmed = compactLine(value)
        guard trimmed.count > maxLength else { return trimmed }
        guard maxLength > 1 else { return String(trimmed.prefix(max(0, maxLength))) }
        return String(trimmed.prefix(maxLength - 1)) + "…"
    }

    private static func extractPrefixedLine(prefix: String, from text: String) -> String? {
        text
            .components(separatedBy: .newlines)
            .first(where: { $0.hasPrefix(prefix) })
            .map { line in
                line
                    .dropFirst(prefix.count)
                    .trimmingCharacters(in: .whitespaces)
            }
    }

    private static func nextMoveHandoffDraftPackMetadata(
        from handoff: String
    ) -> NextMoveDraftPackMetadata? {
        guard let selectedCommandLine = extractPrefixedLine(prefix: "Selected command:", from: handoff),
              let pulseRiskLine = extractPrefixedLine(prefix: "Pulse risk:", from: handoff),
              let nextActionLine = extractPrefixedLine(prefix: "Suggested next action:", from: handoff),
              let mustShipAlertLine = extractPrefixedLine(prefix: "Must-ship alert:", from: handoff) else {
            return nil
        }

        let selectedCommandPrefix = selectedCommandLine
            .split(separator: "(", maxSplits: 1, omittingEmptySubsequences: false)
            .first
            .map(String.init) ?? selectedCommandLine
        let selectedCommand = compactLine(
            selectedCommandPrefix.replacingOccurrences(of: "`", with: "")
        )
        let riskLevel = compactLine(
            pulseRiskLine
                .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                .first
                .map(String.init) ?? pulseRiskLine
        )
        let nextAction = compactLine(nextActionLine)
        let mustShipAlert = compactLine(mustShipAlertLine)
        let leadExperiment = compactLine(
            extractPrefixedLine(prefix: "Lead experiment:", from: handoff) ?? "n/a"
        )
        let scorecard = compactLine(
            extractPrefixedLine(prefix: "Scorecard:", from: handoff) ?? "Unknown"
        )

        guard !selectedCommand.isEmpty,
              !riskLevel.isEmpty,
              !nextAction.isEmpty,
              !mustShipAlert.isEmpty else {
            return nil
        }

        return (
            selectedCommand: selectedCommand,
            riskLevel: riskLevel,
            nextAction: nextAction,
            mustShipAlert: mustShipAlert,
            leadExperiment: leadExperiment,
            scorecard: scorecard
        )
    }

    private static func nextMoveHookVariants(
        metadata: NextMoveDraftPackMetadata
    ) -> (x: [String], bluesky: [String], linkedIn: [String]) {
        let x = [
            clampedLine(
                "Hook: \(metadata.mustShipAlert). Ran \(metadata.selectedCommand). Next: \(metadata.nextAction). #buildinpublic",
                maxLength: 280
            ),
            clampedLine(
                "Pulse \(metadata.riskLevel): executed \(metadata.selectedCommand). Next action: \(metadata.nextAction). #buildinpublic",
                maxLength: 280
            ),
            clampedLine(
                "Builder log: \(metadata.selectedCommand) completed. \(metadata.mustShipAlert) Next up \(metadata.nextAction). #buildinpublic",
                maxLength: 280
            )
        ]
        let bluesky = [
            clampedLine(
                "Hook: \(metadata.mustShipAlert). We ran \(metadata.selectedCommand). Next action: \(metadata.nextAction). #buildinpublic",
                maxLength: 300
            ),
            clampedLine(
                "Signal \(metadata.riskLevel): \(metadata.selectedCommand) executed. Next move: \(metadata.nextAction). #buildinpublic",
                maxLength: 300
            ),
            clampedLine(
                "Shipping note: \(metadata.selectedCommand) is done. \(metadata.mustShipAlert) Next: \(metadata.nextAction). #buildinpublic",
                maxLength: 300
            )
        ]
        let linkedIn = [
            compactLine(
                "Hook: \(metadata.mustShipAlert). We executed \(metadata.selectedCommand), and next action is \(metadata.nextAction)."
            ),
            compactLine(
                "Operator update: pulse risk is \(metadata.riskLevel); \(metadata.selectedCommand) is complete. Next step: \(metadata.nextAction)."
            ),
            compactLine(
                "Execution recap: \(metadata.selectedCommand) shipped. \(metadata.mustShipAlert) Next action now: \(metadata.nextAction)."
            )
        ]
        return (x: x, bluesky: bluesky, linkedIn: linkedIn)
    }

    private static func nextMoveRecommendedHookVariant(
        metadata: NextMoveDraftPackMetadata
    ) -> NextMoveRecommendedHookVariant {
        let profile = nextMoveHookSignalProfile(metadata: metadata)
        let indices: (Int, Int, Int)
        let reason: String

        if profile.isElevatedRisk || profile.hasRecoverySignal {
            indices = (1, 1, 1)
            reason = "Risk is elevated, so signal-forward urgency hooks are most actionable."
        } else if profile.isWatchlistRisk {
            indices = (0, 0, 1)
            reason = "Risk is watchlist-level, so X/Bluesky stay balanced while LinkedIn leads with operator context."
        } else if profile.hasMomentumSignal {
            indices = (2, 2, 0)
            reason = "Risk is low and momentum is strong, so X/Bluesky compound with builder logs while LinkedIn leads with proof-first framing."
        } else {
            indices = (2, 0, 2)
            reason = "Risk is low without breakout signals, so builder-log defaults stay strong while Bluesky keeps a lighter opener."
        }

        let tokens = ["A", "B", "C"]
        return (
            xIndex: indices.0,
            blueskyIndex: indices.1,
            linkedInIndex: indices.2,
            xToken: tokens[indices.0],
            blueskyToken: tokens[indices.1],
            linkedInToken: tokens[indices.2],
            reason: reason
        )
    }

    private static func nextMoveHookSignalProfile(
        metadata: NextMoveDraftPackMetadata
    ) -> (
        isElevatedRisk: Bool,
        isWatchlistRisk: Bool,
        hasMomentumSignal: Bool,
        hasRecoverySignal: Bool
    ) {
        let normalizedRisk = metadata.riskLevel.lowercased()
        let context = compactLine(
            "\(metadata.selectedCommand) \(metadata.nextAction) \(metadata.mustShipAlert) \(metadata.leadExperiment) \(metadata.scorecard)"
        ).lowercased()
        let momentumKeywords = [
            "momentum",
            "authority",
            "breakthrough",
            "spotlight",
            "command center",
            "breakout",
            "compounding",
            "surge"
        ]
        let recoveryKeywords = [
            "recovery",
            "must ship",
            "critical",
            "escalat",
            "contain",
            "stabil"
        ]

        return (
            isElevatedRisk: normalizedRisk == "critical" || normalizedRisk == "high",
            isWatchlistRisk: normalizedRisk == "medium",
            hasMomentumSignal: momentumKeywords.contains { context.contains($0) },
            hasRecoverySignal: recoveryKeywords.contains { context.contains($0) }
        )
    }

    private static func nextMovePublishingCadence(
        metadata: NextMoveDraftPackMetadata,
        recommendedVariant: NextMoveRecommendedHookVariant
    ) -> NextMovePublishingCadence {
        let profile = nextMoveHookSignalProfile(metadata: metadata)

        if profile.isElevatedRisk || profile.hasRecoverySignal {
            return (
                focus: "Stabilize risk quickly, then widen distribution.",
                firstWindow: "Post X \(recommendedVariant.xToken), then queue X Follow-up with the same alert framing.",
                secondWindow: "Post Bluesky \(recommendedVariant.blueskyToken) and carry forward the must-ship signal.",
                thirdWindow: "Post LinkedIn \(recommendedVariant.linkedInToken), then drop LinkedIn Comment immediately.",
                fourthWindow: "Run 10 high-signal replies using Reply Opener and close with one checkpoint update.",
                reason: "Elevated risk benefits from fast, signal-forward sequencing before deeper discussion."
            )
        }

        if profile.isWatchlistRisk {
            return (
                focus: "Protect cadence while validating resonance.",
                firstWindow: "Post X \(recommendedVariant.xToken) and log early objections from replies.",
                secondWindow: "Post Bluesky \(recommendedVariant.blueskyToken) to compare short-form hook response.",
                thirdWindow: "Post LinkedIn \(recommendedVariant.linkedInToken) with the operator-context angle.",
                fourthWindow: "Use LinkedIn Comment and Reply Opener for 8 targeted conversations.",
                reason: "Watchlist risk favors balanced experiments with tight feedback loops."
            )
        }

        if profile.hasMomentumSignal {
            return (
                focus: "Compound momentum with proof-first storytelling.",
                firstWindow: "Post LinkedIn \(recommendedVariant.linkedInToken) to anchor the proof narrative.",
                secondWindow: "Post X \(recommendedVariant.xToken) as the fast amplification layer.",
                thirdWindow: "Post Bluesky \(recommendedVariant.blueskyToken) and echo the same proof point.",
                fourthWindow: "Run 12 replies across X and Bluesky using Reply Opener.",
                reason: "When momentum is strong, depth-first publishing compounds trust before short-form fanout."
            )
        }

        return (
            focus: "Maintain steady distribution without over-rotating.",
            firstWindow: "Post X \(recommendedVariant.xToken) as the primary update.",
            secondWindow: "Post Bluesky \(recommendedVariant.blueskyToken) to keep cadence alive.",
            thirdWindow: "Post LinkedIn \(recommendedVariant.linkedInToken) for recap clarity.",
            fourthWindow: "Run 6-8 replies and place LinkedIn Comment to sustain conversation.",
            reason: "Low-risk baseline mode compounds consistency while preserving optionality."
        )
    }

    private static func nextMoveFirstCadenceHook(
        metadata: NextMoveDraftPackMetadata,
        hookVariants: (x: [String], bluesky: [String], linkedIn: [String]),
        recommendedVariant: NextMoveRecommendedHookVariant
    ) -> (channel: String, token: String, draft: String) {
        let profile = nextMoveHookSignalProfile(metadata: metadata)
        let shouldLeadWithLinkedIn = profile.hasMomentumSignal
            && !profile.isElevatedRisk
            && !profile.hasRecoverySignal
            && !profile.isWatchlistRisk

        if shouldLeadWithLinkedIn {
            return (
                channel: "LinkedIn",
                token: recommendedVariant.linkedInToken,
                draft: hookVariants.linkedIn[recommendedVariant.linkedInIndex]
            )
        }

        return (
            channel: "X",
            token: recommendedVariant.xToken,
            draft: hookVariants.x[recommendedVariant.xIndex]
        )
    }

    private static func parseLaunchTimelineEvents(from text: String) -> [(offsetMinutes: Int, action: String)] {
        text
            .components(separatedBy: .newlines)
            .compactMap { rawLine in
                let line = rawLine.trimmingCharacters(in: .whitespaces)
                guard line.hasPrefix("- T") else { return nil }
                let pieces = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
                guard pieces.count == 2 else { return nil }
                let offsetLabel = pieces[0]
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "- ", with: "")
                guard let offsetMinutes = parseLaunchOffsetMinutes(label: offsetLabel) else { return nil }
                let action = pieces[1].trimmingCharacters(in: .whitespaces)
                guard !action.isEmpty else { return nil }
                return (offsetMinutes: offsetMinutes, action: action)
            }
            .sorted { lhs, rhs in
                lhs.offsetMinutes < rhs.offsetMinutes
            }
    }

    private static func parseLaunchOffsetMinutes(label: String) -> Int? {
        guard label.hasPrefix("T"), label.hasSuffix("m") else { return nil }
        let value = label.dropFirst().dropLast()
        let rawValue = String(value)
        if rawValue.hasPrefix("+") {
            return Int(rawValue.dropFirst())
        }
        return Int(rawValue)
    }

    private static func launchOffsetLabel(minutes: Int) -> String {
        if minutes > 0 {
            return "T+\(minutes)m"
        }
        if minutes < 0 {
            return "T\(minutes)m"
        }
        return "T+0m"
    }

    private static func launchCountdownStatusPhrase(minutesUntil: Int) -> String {
        if abs(minutesUntil) <= 2 {
            return "do now"
        }
        if minutesUntil > 0 {
            return "in \(minutesUntil)m"
        }
        return "past by \(abs(minutesUntil))m"
    }

    private static func launchAnchorDate(
        from launchScript: String,
        now: Date,
        calendar: Calendar
    ) -> Date {
        guard let anchorValue = extractPrefixedLine(prefix: "Launch anchor: ", from: launchScript) else {
            return now
        }

        let cleanedValue = anchorValue
            .replacingOccurrences(of: "(local)", with: "")
            .trimmingCharacters(in: .whitespaces)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: cleanedValue) ?? now
    }

    private static func recommendationLine(
        latestEntry: FameSnapshotRollupEntry,
        scoreTrend: Int
    ) -> String {
        if latestEntry.score >= 40 || latestEntry.stage == "Authority" {
            return "Protect authority: keep daily proof loops and expand partner distribution."
        }
        if scoreTrend > 0 {
            return "Momentum is improving: double down on the current sprint lane for 7 more days."
        }
        return "Score is flat/down: run `Run Fame Sprint + Save Snapshot`, then push 1 proof post + 10 replies today."
    }

    private static func recommendedDailyScorecardActionTitle(riskLevel: String) -> String {
        switch riskLevel {
        case "High":
            return "Run Fame Recovery Sprint"
        case "Medium":
            return "Run Daily Fame Checkpoint"
        default:
            return "Run Fame Command Center"
        }
    }

    private static func recommendedDailyScorecardActionSummary(riskLevel: String) -> String {
        switch riskLevel {
        case "High":
            return "Risk is elevated, so execute a must-ship recovery block now."
        case "Medium":
            return "Risk is watchlist-level, so tighten execution with a KPI checkpoint."
        default:
            return "Risk is low; use command center to turn momentum into a 72h breakout plan."
        }
    }

    private static func actionTemplate(for title: String) -> (quick: String, focus: String, publish: String, winSignal: String) {
        switch title {
        case "Activation Fix":
            return (
                quick: "Audit onboarding friction and pick one blocker to remove.",
                focus: "Record before/after activation proof with 3 user trials.",
                publish: "Post one activation proof thread and ask for tester replies.",
                winSignal: "New users complete first run without manual help."
            )
        case "Distribution Remix":
            return (
                quick: "Pick strongest proof asset and define 2 remix angles.",
                focus: "Create channel-native remix variants for two platforms.",
                publish: "Ship remixes with tailored hooks and reply CTA.",
                winSignal: "Higher engagement on remixed posts within 24h."
            )
        case "30s Command Race":
            return (
                quick: "Script one 30-second demo with a single punchline.",
                focus: "Capture and trim two demo takes with clear CTA.",
                publish: "Post speed-run clip and pin it as social proof.",
                winSignal: "Clip generates qualified replies and demo requests."
            )
        case "Win Recap Ladder":
            return (
                quick: "Collect today’s top micro-win and one screenshot.",
                focus: "Draft three recap hook variants from the same win.",
                publish: "Post recap ladder and invite peers to share their wins.",
                winSignal: "Replies include concrete follow-up questions."
            )
        case "Reply Engine":
            return (
                quick: "Build a target list of 10 high-signal conversations.",
                focus: "Run one concentrated reply sprint with proof snippets.",
                publish: "Thread best replies into one synthesis post.",
                winSignal: "Replies convert into at least one direct conversation."
            )
        default:
            return (
                quick: "Outline one builder narrative from recent results.",
                focus: "Write a long-form thread with before/after evidence.",
                publish: "Ship builder thread and ask for one tactical critique.",
                winSignal: "Thread attracts expert feedback and reposts."
            )
        }
    }

    private static func narrativePrimaryCommandID(
        experimentTitle: String,
        pulseRisk: String
    ) -> String {
        if pulseRisk == "Critical" || pulseRisk == "High" {
            return "run-fame-recovery-sprint"
        }

        switch experimentTitle {
        case "Activation Fix":
            return "run-fame-daily-checkpoint"
        case "Distribution Remix":
            return "run-fame-command-center"
        case "30s Command Race":
            return "run-fame-sprint-snapshot"
        case "Win Recap Ladder":
            return "run-fame-daily-scorecard"
        case "Reply Engine":
            return "run-fame-operator-dashboard"
        default:
            return "run-fame-breakthrough-forecast"
        }
    }

    private static func narrativeRouteDrafts(
        experimentTitle: String,
        plan: (quick: String, focus: String, publish: String, winSignal: String),
        latestEntry: FameSnapshotRollupEntry,
        pulseRisk: String,
        trajectory: String
    ) -> (xDraft: String, linkedInDraft: String, replyOpener: String) {
        let xDraft = clampedLine(
            "\(experimentTitle): \(plan.publish) Stage \(latestEntry.stage), score \(latestEntry.score), pulse \(pulseRisk). #buildinpublic",
            maxLength: 280
        )
        let linkedInDraft = compactLine(
            "Founder narrative route: \(experimentTitle). \(plan.focus) Current trajectory: \(trajectory) Snapshot score: \(latestEntry.score) (\(latestEntry.stage)). CTA: reply with one execution idea to accelerate this lane."
        )
        let replyOpener = compactLine(
            "Route check: \(experimentTitle). Fast win signal: \(plan.winSignal) What would you test first?"
        )
        return (xDraft: xDraft, linkedInDraft: linkedInDraft, replyOpener: replyOpener)
    }

    private static func spotlightDrafts(
        route: String,
        latestEntry: FameSnapshotRollupEntry,
        pulseRisk: String,
        mustShipAlert: String,
        trajectory: String,
        leadPlan: (quick: String, focus: String, publish: String, winSignal: String)
    ) -> (xPrimary: String, xFollowUp: String, linkedIn: String, partnerDM: String, checklistComment: String) {
        let xPrimary = clampedLine(
            "\(route): \(leadPlan.publish) Snapshot \(latestEntry.score) (\(latestEntry.stage)), trend \(trajectory). #buildinpublic",
            maxLength: 280
        )
        let xFollowUp = clampedLine(
            "Today’s must-ship: \(mustShipAlert) Route: \(route). Win signal: \(leadPlan.winSignal)",
            maxLength: 280
        )
        let linkedIn = compactLine(
            "Founder spotlight route: \(route). \(leadPlan.focus) Pulse risk is \(pulseRisk), so execution stays proof-first with one measurable outcome before channel expansion."
        )
        let partnerDM = compactLine(
            "Quick founder update: we are running the \(route) lane this cycle. Current snapshot is \(latestEntry.score) (\(latestEntry.stage)); today’s publish beat is \(leadPlan.publish) Want to co-amplify if it lands?"
        )
        let checklistComment = compactLine(
            "Artifact link: [paste spotlight pack link] | Owner update: Published \(route) spotlight drafts and started reply ladder execution."
        )
        return (xPrimary: xPrimary, xFollowUp: xFollowUp, linkedIn: linkedIn, partnerDM: partnerDM, checklistComment: checklistComment)
    }

    private static func spotlightReplyLadder(
        route: String,
        leadPlan: (quick: String, focus: String, publish: String, winSignal: String),
        pulseRisk: String
    ) -> [String] {
        var replies = [
            "Thanks — we’re currently running the \(route) lane. Which part would you test first?",
            "Great call. Our next block is: \(leadPlan.quick)",
            "Signal we’re watching: \(leadPlan.winSignal)",
            "If this lands, we’ll expand with: \(leadPlan.publish)",
            "Want the exact command stack we’re using this week?"
        ]
        if pulseRisk == "High" || pulseRisk == "Critical" {
            replies[0] = "Appreciate it — pulse risk is \(pulseRisk), so we’re shipping recovery-first in the \(route) lane. Which friction should we close first?"
        }
        return replies
    }

    private static func trajectoryLine(
        latestEntry: FameSnapshotRollupEntry,
        scoreTrend: Int,
        authorityCount: Int
    ) -> String {
        if latestEntry.stage == "Authority" || latestEntry.score >= 40 || authorityCount >= 3 {
            return "Breakout lane (protect and compound authority)."
        }
        if scoreTrend >= 6 {
            return "Strong uptrend (push distribution while velocity is high)."
        }
        if scoreTrend >= 0 {
            return "Stable momentum (needs one stronger proof loop)."
        }
        if scoreTrend <= -6 {
            return "Cooling hard (run recovery sprint immediately)."
        }
        return "Soft dip (tighten execution and publish cadence)."
    }

    private static func riskLevelLine(
        latestEntry: FameSnapshotRollupEntry,
        scoreTrend: Int,
        sparkCount: Int,
        authorityCount: Int
    ) -> String {
        if latestEntry.stage == "Authority" && scoreTrend >= 0 {
            return "Low"
        }
        if scoreTrend <= -6 || (latestEntry.stage == "Spark" && authorityCount == 0 && sparkCount >= 3) {
            return "High"
        }
        return "Medium"
    }

    private static func riskLines(
        latestEntry: FameSnapshotRollupEntry,
        scoreTrend: Int,
        averageScore: Int,
        sparkCount: Int,
        authorityCount: Int
    ) -> [String] {
        var result: [String] = []

        if scoreTrend <= -4 {
            result.append("Score trend is down; ship one proof-first post before experimenting with new formats.")
        }
        if latestEntry.stage == "Spark" || sparkCount >= 3 {
            result.append("Pipeline is spark-heavy; convert one spark win into a documented case study.")
        }
        if authorityCount == 0 && averageScore < 20 {
            result.append("Authority gap is still open; prioritize one long-form builder narrative this cycle.")
        }
        if result.isEmpty {
            result.append("Current loop is healthy; protect cadence and avoid over-rotating on new channels.")
        }

        return result
    }

    private static func checkpointStatusLine(
        latestEntry: FameSnapshotRollupEntry,
        scoreDelta: Int,
        deltaVsAverage: Int
    ) -> String {
        if latestEntry.stage == "Authority" && scoreDelta >= 0 {
            return "Compounding authority. Stay consistent and amplify winners."
        }
        if scoreDelta >= 4 && deltaVsAverage >= 0 {
            return "Acceleration detected. Increase distribution while quality holds."
        }
        if scoreDelta >= 0 {
            return "Stable momentum. Push one stronger proof loop today."
        }
        if scoreDelta <= -4 {
            return "Performance dip. Enter recovery mode with proof-first output."
        }
        return "Minor pullback. Tighten execution blocks and ship without delay."
    }

    private static func pulseRiskLevel(
        latestEntry: FameSnapshotRollupEntry,
        scoreTrend: Int,
        daysSinceLastSnapshot: Int
    ) -> String {
        if daysSinceLastSnapshot >= 2 {
            return "Critical"
        }
        if daysSinceLastSnapshot == 1 || scoreTrend <= -6 {
            return "High"
        }
        if scoreTrend < 0 || latestEntry.stage == "Spark" {
            return "Medium"
        }
        return "Low"
    }

    private static func pulseRiskOrder(level: String) -> Int {
        switch level {
        case "Critical":
            return 4
        case "High":
            return 3
        case "Medium":
            return 2
        case "Low":
            return 1
        default:
            return 0
        }
    }

    private static func streakStatusLine(streakDays: Int) -> String {
        if streakDays >= 10 {
            return "Unstoppable streak (10+ days)."
        }
        if streakDays >= 5 {
            return "Hot streak is live; protect cadence."
        }
        if streakDays >= 2 {
            return "Streak is active and building."
        }
        return "New streak started. Protect today."
    }

    private static func pulseMustShipAlert(
        riskLevel: String,
        scoreTrend: Int,
        daysSinceLastSnapshot: Int
    ) -> String {
        switch riskLevel {
        case "Critical":
            return "MUST SHIP in next 2h: run `Run Fame Sprint + Save Snapshot` and publish one proof loop."
        case "High":
            if daysSinceLastSnapshot >= 1 {
                return "Must ship today to avoid streak break: one proof loop + one saved snapshot."
            }
            return "Must ship recovery loop today: publish proof first, then run reply sprint."
        case "Medium":
            if scoreTrend < 0 {
                return "Ship one proof-first post today and save a fresh snapshot."
            }
            return "Keep streak alive with one shipped proof loop before day end."
        default:
            return "Protect the streak with one quality post and one focused reply block."
        }
    }

    private static func forecastStage(for score: Int) -> String {
        if score >= 55 {
            return "Authority+"
        }
        if score >= 40 {
            return "Authority"
        }
        if score >= 20 {
            return "Momentum"
        }
        return "Spark"
    }

    private static func breakthroughTarget(for score: Int) -> (stageName: String, scoreThreshold: Int) {
        if score < 20 {
            return ("Momentum", 20)
        }
        if score < 40 {
            return ("Authority", 40)
        }
        if score < 55 {
            return ("Authority+", 55)
        }
        return ("Authority+ (stretch)", 70)
    }

    private static func breakthroughETAInDays(
        currentScore: Int,
        targetScore: Int,
        projectedDelta: Int
    ) -> Int? {
        guard currentScore < targetScore else { return 0 }
        guard projectedDelta > 0 else { return nil }

        let scoreGap = targetScore - currentScore
        let dailyGain = Double(projectedDelta) / 7.0
        guard dailyGain > 0 else { return nil }
        let days = Int(ceil(Double(scoreGap) / dailyGain))
        return max(1, days)
    }

    private static func breakthroughForecastConfidence(
        scoreTrend: Int,
        baseDelta: Int,
        latestStage: String
    ) -> String {
        if baseDelta >= 8 && (latestStage == "Momentum" || latestStage == "Authority") {
            return "High"
        }
        if scoreTrend >= 0 && baseDelta >= 2 {
            return "Medium"
        }
        return "Low"
    }

    private static func forecastScenarioSignal(delta: Int, stage: String) -> String {
        if delta <= 0 {
            return "Needs immediate recovery cadence."
        }
        if stage == "Authority+" {
            return "Breakout profile if distribution compounds."
        }
        if stage == "Authority" {
            return "Authority lock if proof loops stay daily."
        }
        if stage == "Momentum" {
            return "Momentum build; keep shipping proof."
        }
        return "Early-stage signal; tighten activation."
    }

    private static func dailyMissionPrimaryCommand(
        scorecard: FameDailyScorecardState,
        pulseRisk: String
    ) -> String {
        if pulseRisk == "High" || pulseRisk == "Critical" || scorecard.recommendsRecovery {
            return "run-fame-recovery-sprint"
        }
        if scorecard.riskLevel == "Low", scorecard.scoreDelta >= 6 {
            return "run-fame-breakthrough-forecast"
        }
        if scorecard.riskLevel == "Low" {
            return "run-fame-command-center"
        }
        return "run-fame-daily-checkpoint"
    }

    private static func snapshotDayDate(from timestamp: String, formatter: DateFormatter) -> Date? {
        guard timestamp.count >= 8 else { return nil }
        return formatter.date(from: String(timestamp.prefix(8)))
    }

    private static func currentStreakDays(dates: [Date], calendar: Calendar) -> Int {
        let ordered = dates.sorted()
        guard !ordered.isEmpty else { return 0 }
        guard ordered.count > 1 else { return 1 }

        var streak = 1
        for index in stride(from: ordered.count - 1, to: 0, by: -1) {
            let current = ordered[index]
            let previous = ordered[index - 1]
            guard let expectedPrevious = calendar.date(byAdding: .day, value: -1, to: current) else { break }
            if calendar.isDate(previous, inSameDayAs: expectedPrevious) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private static func bestExperiments(
        recentEntries: [FameSnapshotRollupEntry],
        scoreTrend: Int,
        averageScore: Int,
        authorityCount: Int,
        momentumCount: Int,
        sparkCount: Int
    ) -> [ExperimentRecommendation] {
        guard let latestEntry = recentEntries.last else {
            return []
        }

        var recommendations = [
            ExperimentRecommendation(
                title: "Activation Fix",
                score: 14
                    + (scoreTrend <= 0 ? 18 : 0)
                    + (latestEntry.stage == "Spark" ? 6 : 0)
                    + (sparkCount * 2),
                why: "Score stalls often come from weak activation moments.",
                nextMove: "Ship one clear onboarding proof loop and validate with 5 new users."
            ),
            ExperimentRecommendation(
                title: "Distribution Remix",
                score: 16
                    + (scoreTrend > 0 ? 16 : 0)
                    + ((latestEntry.stage == "Momentum" || latestEntry.stage == "Authority") ? 8 : 0)
                    + ((momentumCount + authorityCount) * 2),
                why: "When momentum is live, remixing distribution compounds reach fastest.",
                nextMove: "Remix best proof into 2 channel-native variants and publish today."
            ),
            ExperimentRecommendation(
                title: "30s Command Race",
                score: 12
                    + (recentEntries.count >= 3 ? 6 : 0)
                    + (averageScore >= 20 ? 4 : 0),
                why: "Fast demos create repeatable clip inventory for discovery feeds.",
                nextMove: "Record a 30s speed run with one strong outcome and one CTA."
            ),
            ExperimentRecommendation(
                title: "Win Recap Ladder",
                score: 13
                    + (scoreTrend <= 0 ? 10 : 0)
                    + (sparkCount > 0 ? 4 : 0),
                why: "Frequent recap posts turn small wins into social proof density.",
                nextMove: "Post 3 short recap variants and test different hooks."
            ),
            ExperimentRecommendation(
                title: "Reply Engine",
                score: 15
                    + (scoreTrend > 0 ? 10 : 0)
                    + (latestEntry.score >= 20 ? 6 : 0),
                why: "Reply volume converts attention into direct founder conversations.",
                nextMove: "Run a focused reply block and target 10 high-signal responses."
            ),
            ExperimentRecommendation(
                title: "Builder Thread",
                score: 11
                    + (latestEntry.stage == "Authority" ? 20 : 0)
                    + (authorityCount * 3),
                why: "Authority phases benefit from deeper narrative threads and context.",
                nextMove: "Publish one builder thread with before/after proof and a request."
            )
        ]

        recommendations.sort {
            if $0.score == $1.score {
                return $0.title < $1.title
            }
            return $0.score > $1.score
        }
        return Array(recommendations.prefix(3))
    }
}

private struct ExperimentRecommendation {
    let title: String
    let score: Int
    let why: String
    let nextMove: String
}
