import XCTest
@testable import FluidReader

final class AppDelegateLaunchTests: XCTestCase {
    func testMorningBriefLaunchDecisionSkipsWhenDisabled() {
        let decision = AppDelegate.morningBriefLaunchDecision(
            isEnabled: false,
            quietMode: false,
            skipForSetupChecklist: false,
            lastRunStamp: nil,
            todayStamp: "2026-06-09"
        )

        XCTAssertEqual(decision, .skipDisabled)
    }

    func testMorningBriefLaunchDecisionSkipsForSetupChecklistBeforeAlreadyRan() {
        let decision = AppDelegate.morningBriefLaunchDecision(
            isEnabled: true,
            quietMode: false,
            skipForSetupChecklist: true,
            lastRunStamp: "2026-06-09",
            todayStamp: "2026-06-09"
        )

        XCTAssertEqual(decision, .skipSetupChecklist)
    }

    func testMorningBriefLaunchDecisionSkipsWhenAlreadyRanToday() {
        let decision = AppDelegate.morningBriefLaunchDecision(
            isEnabled: true,
            quietMode: false,
            skipForSetupChecklist: false,
            lastRunStamp: "2026-06-09",
            todayStamp: "2026-06-09"
        )

        XCTAssertEqual(decision, .skipAlreadyRanToday)
    }

    func testMorningBriefLaunchDecisionRunsInQuietMode() {
        let decision = AppDelegate.morningBriefLaunchDecision(
            isEnabled: true,
            quietMode: true,
            skipForSetupChecklist: false,
            lastRunStamp: "2026-06-08",
            todayStamp: "2026-06-09"
        )

        XCTAssertEqual(decision, .run(quietMode: true))
    }

    func testMorningBriefLaunchDecisionRunsInInteractiveMode() {
        let decision = AppDelegate.morningBriefLaunchDecision(
            isEnabled: true,
            quietMode: false,
            skipForSetupChecklist: false,
            lastRunStamp: nil,
            todayStamp: "2026-06-09"
        )

        XCTAssertEqual(decision, .run(quietMode: false))
    }

    func testEscalationResponseTriggerRunsForHighEscalation() {
        let transition = FamePulseRiskTransition(
            fromRiskLevel: "Medium",
            toRiskLevel: "High",
            isEscalation: true
        )

        XCTAssertTrue(AppDelegate.shouldAutoTriggerFameEscalationResponse(transition))
    }

    func testEscalationResponseTriggerRunsForCriticalEscalation() {
        let transition = FamePulseRiskTransition(
            fromRiskLevel: "High",
            toRiskLevel: "Critical",
            isEscalation: true
        )

        XCTAssertTrue(AppDelegate.shouldAutoTriggerFameEscalationResponse(transition))
    }

    func testEscalationResponseTriggerSkipsCalibrationTransitions() {
        let transition = FamePulseRiskTransition(
            fromRiskLevel: "Unknown",
            toRiskLevel: "High",
            isEscalation: true
        )

        XCTAssertFalse(AppDelegate.shouldAutoTriggerFameEscalationResponse(transition))
    }

    func testEscalationResponseTriggerSkipsNonEscalationTransitions() {
        let transition = FamePulseRiskTransition(
            fromRiskLevel: "High",
            toRiskLevel: "Medium",
            isEscalation: false
        )

        XCTAssertFalse(AppDelegate.shouldAutoTriggerFameEscalationResponse(transition))
    }

    func testFamePulseRiskActionCommandIDDefaultsToPulseNudgeWithoutSignal() {
        XCTAssertEqual(
            AppDelegate.famePulseRiskActionCommandID(signal: nil, transition: nil),
            "run-fame-pulse-nudge"
        )
    }

    func testFamePulseRiskActionCommandIDUsesPulseNudgeForLowRisk() {
        let signal = FamePulseAlertSignal(
            riskLevel: "Low",
            mustShipAlert: "Steady",
            streakDays: 4,
            daysSinceLastSnapshot: 0,
            leadExperiment: "Builder Thread"
        )

        XCTAssertEqual(
            AppDelegate.famePulseRiskActionCommandID(
                signal: signal,
                transition: FamePulseRiskTransition(
                    fromRiskLevel: "Medium",
                    toRiskLevel: "Low",
                    isEscalation: false
                )
            ),
            "run-fame-pulse-nudge"
        )
    }

    func testFamePulseRiskActionCommandIDUsesEscalationNudgeForHighEscalation() {
        let signal = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "MUST SHIP in next 2h",
            streakDays: 2,
            daysSinceLastSnapshot: 2,
            leadExperiment: "Creator Sprint"
        )

        XCTAssertEqual(
            AppDelegate.famePulseRiskActionCommandID(
                signal: signal,
                transition: FamePulseRiskTransition(
                    fromRiskLevel: "Medium",
                    toRiskLevel: "High",
                    isEscalation: true
                )
            ),
            "run-fame-escalation-nudge"
        )
    }

    func testFamePulseRiskActionCommandIDUsesRecoverySprintForStableHighRisk() {
        let signal = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "MUST SHIP in next 2h",
            streakDays: 1,
            daysSinceLastSnapshot: 3,
            leadExperiment: "Distribution Loop"
        )

        XCTAssertEqual(
            AppDelegate.famePulseRiskActionCommandID(
                signal: signal,
                transition: FamePulseRiskTransition(
                    fromRiskLevel: "High",
                    toRiskLevel: "High",
                    isEscalation: false
                )
            ),
            "run-fame-recovery-sprint"
        )
    }

    func testFameNextMoveCommandIDUsesSnapshotWhenScorecardIsUnknown() {
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: nil,
                transition: nil,
                scorecard: .unknown
            ),
            "run-fame-sprint-snapshot"
        )
    }

    func testFameNextMoveCommandIDUsesCommandCenterWhenRiskIsStable() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 3,
            title: "Daily Scorecard: Low",
            detail: "Compounding authority.",
            recommendation: "Run Fame Command Center",
            nextActionTitle: "Run Fame Command Center",
            nextActionSummary: "Risk is low; run a breakout plan.",
            recommendsRecovery: false
        )

        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: nil,
                transition: nil,
                scorecard: scorecard
            ),
            "run-fame-command-center"
        )
    }

    func testFameNextMoveCommandIDUsesDailyCheckpointWhenRiskIsWatchlist() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Medium",
            scoreDelta: 1,
            title: "Daily Scorecard: Medium",
            detail: "Watchlist-level risk.",
            recommendation: "Run Daily Fame Checkpoint",
            nextActionTitle: "Run Daily Fame Checkpoint",
            nextActionSummary: "Tighten execution with KPI checks.",
            recommendsRecovery: false
        )

        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: nil,
                transition: nil,
                scorecard: scorecard
            ),
            "run-fame-daily-checkpoint"
        )
    }

    func testFameNextMoveCommandIDUsesRecoveryWhenScorecardRecommendsRecovery() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Medium",
            scoreDelta: -3,
            title: "Daily Scorecard: Medium",
            detail: "Recover quickly.",
            recommendation: "Run Fame Recovery Sprint",
            nextActionTitle: "Run Fame Recovery Sprint",
            nextActionSummary: "Risk is rising.",
            recommendsRecovery: true
        )

        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: nil,
                transition: nil,
                scorecard: scorecard
            ),
            "run-fame-recovery-sprint"
        )
    }

    func testFameNextMoveCommandIDPrefersEscalationSignalOverScorecardFallback() {
        let signal = FamePulseAlertSignal(
            riskLevel: "Critical",
            mustShipAlert: "MUST SHIP in next 2h",
            streakDays: 1,
            daysSinceLastSnapshot: 3,
            leadExperiment: "Creator Sprint"
        )
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 8,
            title: "Daily Scorecard: Low",
            detail: "Compounding authority.",
            recommendation: "Run Fame Command Center",
            nextActionTitle: "Run Fame Command Center",
            nextActionSummary: "Risk is low; run a breakout plan.",
            recommendsRecovery: false
        )

        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: signal,
                transition: FamePulseRiskTransition(
                    fromRiskLevel: "High",
                    toRiskLevel: "Critical",
                    isEscalation: true
                ),
                scorecard: scorecard
            ),
            "run-fame-escalation-nudge"
        )
    }

    func testFameNextMoveCommandIDUsesBreakthroughForecastWhenMomentumIsStrong() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 6,
            title: "Daily Scorecard: 46 (+6 vs prev)",
            detail: "Trend +12 · Authority · Sparkline ▁▄█",
            recommendation: "Compounding authority. Stay consistent and amplify winners.",
            nextActionTitle: "Run Fame Command Center",
            nextActionSummary: "Risk is low; use command center to turn momentum into a 72h breakout plan.",
            recommendsRecovery: false
        )

        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: nil,
                transition: nil,
                scorecard: scorecard
            ),
            "run-fame-breakthrough-forecast"
        )
    }

    func testFameNextMoveCommandIDUsesSpotlightPackWhenMomentumIsExceptional() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 10,
            title: "Daily Scorecard: 50 (+10 vs prev)",
            detail: "Trend +18 · Authority · Sparkline ▂▆█",
            recommendation: "Momentum is exceptional. Package a spotlight campaign now.",
            nextActionTitle: "Run Fame Spotlight Pack",
            nextActionSummary: "Risk is low and momentum is exceptional; ship coordinated spotlight copy.",
            recommendsRecovery: false
        )

        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandID(
                signal: nil,
                transition: nil,
                scorecard: scorecard
            ),
            "run-fame-spotlight-pack"
        )
    }

    func testFameExceptionalLoopPlanPrioritizesSelfHealAttentionBeforeOtherSignals() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 11,
            title: "Daily Scorecard: 50 (+11 vs prev)",
            detail: "Trend +20",
            recommendation: "Run Fame Spotlight Pack",
            nextActionTitle: "Run Fame Spotlight Pack",
            nextActionSummary: "Momentum is exceptional.",
            recommendsRecovery: false
        )
        let plan = AppDelegate.fameExceptionalLoopPlan(
            signal: FamePulseAlertSignal(
                riskLevel: "Critical",
                mustShipAlert: "MUST SHIP in next 2h",
                streakDays: 2,
                daysSinceLastSnapshot: 1,
                leadExperiment: "Creator Sprint"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "High",
                toRiskLevel: "Critical",
                isEscalation: true
            ),
            scorecard: scorecard,
            launchStatus: FameLaunchCountdownStatus(
                countdown: "T+35m",
                nextAction: "Ship launch update now",
                launchRoute: "Rescue",
                pulseRisk: "Critical"
            ),
            launchRescueSelfHealAttentionIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
            cadenceCurrentStreak: 5,
            cadenceBestStreak: 9
        )

        XCTAssertEqual(plan.focusTitle, "Self-Heal Recovery")
        XCTAssertEqual(plan.primaryCommandID, "run-fame-launch-rescue-followup-now")
        XCTAssertEqual(plan.followupActionID, "copy-fame-launch-rescue-snapshot")
    }

    func testFameExceptionalLoopPlanPrioritizesMissingSelfHealAttentionBeforeOtherSignals() {
        let scorecard = FameDailyScorecardState(
            riskLevel: "Low",
            scoreDelta: 11,
            title: "Daily Scorecard: 50 (+11 vs prev)",
            detail: "Trend +20",
            recommendation: "Run Fame Spotlight Pack",
            nextActionTitle: "Run Fame Spotlight Pack",
            nextActionSummary: "Momentum is exceptional.",
            recommendsRecovery: false
        )
        let plan = AppDelegate.fameExceptionalLoopPlan(
            signal: FamePulseAlertSignal(
                riskLevel: "Critical",
                mustShipAlert: "MUST SHIP in next 2h",
                streakDays: 2,
                daysSinceLastSnapshot: 1,
                leadExperiment: "Creator Sprint"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "High",
                toRiskLevel: "Critical",
                isEscalation: true
            ),
            scorecard: scorecard,
            launchStatus: FameLaunchCountdownStatus(
                countdown: "T+35m",
                nextAction: "Ship launch update now",
                launchRoute: "Rescue",
                pulseRisk: "Critical"
            ),
            launchRescueSelfHealAttentionIssueToken: "missing-urgency-critical",
            cadenceCurrentStreak: 5,
            cadenceBestStreak: 9
        )

        XCTAssertEqual(plan.focusTitle, "Self-Heal Kickstart")
        XCTAssertEqual(plan.primaryCommandID, "run-fame-launch-rescue-followup-now")
        XCTAssertEqual(plan.followupActionID, "copy-fame-launch-rescue-snapshot")
    }

    func testFameExceptionalLoopPlanPrioritizesLaunchControlWhenUrgencyIsHigh() {
        let plan = AppDelegate.fameExceptionalLoopPlan(
            signal: nil,
            transition: nil,
            scorecard: FameDailyScorecardState(
                riskLevel: "Low",
                scoreDelta: 2,
                title: "Daily Scorecard: Low",
                detail: "Stable momentum.",
                recommendation: "Run Fame Command Center",
                nextActionTitle: "Run Fame Command Center",
                nextActionSummary: "Keep momentum.",
                recommendsRecovery: false
            ),
            launchStatus: FameLaunchCountdownStatus(
                countdown: "T+18m",
                nextAction: "Ship launch update now",
                launchRoute: "Recovery",
                pulseRisk: "High"
            ),
            launchRescueSelfHealAttentionIssueToken: nil,
            cadenceCurrentStreak: 4,
            cadenceBestStreak: 7
        )

        XCTAssertEqual(plan.focusTitle, "Launch High Control")
        XCTAssertEqual(plan.primaryCommandID, "run-fame-launch-control-hub")
        XCTAssertEqual(plan.followupActionID, "copy-fame-launch-control-brief")
    }

    func testFameExceptionalLoopPlanUsesCadenceIgnitionWhenStreakIsZero() {
        let plan = AppDelegate.fameExceptionalLoopPlan(
            signal: nil,
            transition: nil,
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 0,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution.",
                recommendsRecovery: false
            ),
            launchStatus: FameLaunchCountdownStatus(
                countdown: "T-12m",
                nextAction: "Prep launch assets",
                launchRoute: "Prep",
                pulseRisk: "Medium"
            ),
            launchRescueSelfHealAttentionIssueToken: nil,
            cadenceCurrentStreak: 0,
            cadenceBestStreak: 2
        )

        XCTAssertEqual(plan.focusTitle, "Cadence Ignition")
        XCTAssertEqual(plan.primaryCommandID, "run-fame-next-move-cadence-execution-kit")
        XCTAssertNil(plan.followupActionID)
    }

    func testFameExceptionalLoopActionHelpersFormatTitleSubtitleAndActivityDetails() {
        let plan = AppDelegate.FameExceptionalLoopPlan(
            focusTitle: "Launch High Control",
            primaryCommandID: "run-fame-launch-control-hub",
            reasonLine: "Launch urgency is high; run the full control hub before momentum slips.",
            followupActionID: "copy-fame-launch-control-brief",
            followupReasonLine: "Copy the launch control brief so execution stays synchronized."
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopActionTitle(plan),
            "Run Fame Exceptional Loop: Launch High Control"
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopActionSystemImage(plan),
            "bolt.trianglebadge.exclamationmark"
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopActionSubtitle(plan),
            "Primary: Run Launch Control Hub. Launch urgency is high; run the full control hub before momentum slips. Follow-up: Copy Launch Control Brief. Copy the launch control brief so execution stays synchronized."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopCompletionMessage(plan),
            "Exceptional loop complete: Launch High Control. Ran Run Launch Control Hub + Copy Launch Control Brief."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopActivityDetail(plan),
            "run-fame-exceptional-loop-launch-high-control-run-fame-launch-control-hub-copy-fame-launch-control-brief"
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopMenuStatusTitle(plan, hotKeyAvailable: true),
            "Exceptional Loop Focus: Launch High Control · ⌥⇧E ready"
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopMenuStatusTitle(plan, hotKeyAvailable: false),
            "Exceptional Loop Focus: Launch High Control · ⌥⇧E busy"
        )
        XCTAssertTrue(
            AppDelegate.fameExceptionalLoopMenuStatusToolTip(plan, hotKeyAvailable: true)
                .contains("Shortcut: global ⌥⇧E runs this loop.")
        )
        let recapMarkdown = AppDelegate.fameExceptionalLoopRecapMarkdown(
            plan: plan,
            generatedAt: "2026-06-11 10:30",
            projectedOutcomeStatusTitle: "Outcome trend: win lane x3 · 75% hit rate.",
            projectedLaneSummaries: AppDelegate.FameExceptionalLoopOutcomeLaneSummaries(
                topWinLane: "Run Cadence Autopilot Loop 3/4 (75%), streak x3",
                topRecoveryLane: "Run Next Move + Copy Draft Pack misses 1/4, streak x1"
            ),
            projectedRecoveryActionSummary: "Run Next Move + Copy Draft Pack (1/4 misses, streak x1)"
        )
        XCTAssertTrue(recapMarkdown.contains("open-latest-fame-exceptional-loop-recap"))
        XCTAssertTrue(recapMarkdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(recapMarkdown.contains("Outcome telemetry (projected):"))
        XCTAssertTrue(recapMarkdown.contains("Recovery next action: Run Next Move + Copy Draft Pack (1/4 misses, streak x1)"))
    }

    func testFameExceptionalLoopProjectedOutcomeScoreboardAndHistoryMirrorNextRun() {
        let plan = AppDelegate.FameExceptionalLoopPlan(
            focusTitle: "Cadence Reinforcement",
            primaryCommandID: "run-fame-cadence-autopilot-loop",
            reasonLine: "Protect your streak and climb toward x3 with a fresh autopilot run.",
            followupActionID: "copy-fame-cadence-share-line",
            followupReasonLine: "Copy one momentum share line for immediate publishing."
        )
        let currentScoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 3,
            successRate: 60,
            successStreak: 2,
            failureStreak: 0,
            lastFocusToken: "run-fame-cadence-autopilot-loop",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )
        let now = Date(timeIntervalSince1970: 1_715_300_000)

        let projectedSuccessScoreboard = AppDelegate
            .fameExceptionalLoopProjectedOutcomeScoreboard(
                current: currentScoreboard,
                plan: plan,
                wasSuccessful: true,
                now: now
            )
        XCTAssertEqual(projectedSuccessScoreboard.attempts, 6)
        XCTAssertEqual(projectedSuccessScoreboard.successes, 4)
        XCTAssertEqual(projectedSuccessScoreboard.successRate, 67)
        XCTAssertEqual(projectedSuccessScoreboard.successStreak, 3)
        XCTAssertEqual(projectedSuccessScoreboard.failureStreak, 0)
        XCTAssertEqual(
            projectedSuccessScoreboard.lastFocusToken,
            AppDelegate.fameExceptionalLoopOutcomeFocusToken(plan)
        )
        XCTAssertEqual(projectedSuccessScoreboard.lastOutcomeAt, now)

        let projectedFailureScoreboard = AppDelegate
            .fameExceptionalLoopProjectedOutcomeScoreboard(
                current: currentScoreboard,
                plan: plan,
                wasSuccessful: false,
                now: now
            )
        XCTAssertEqual(projectedFailureScoreboard.attempts, 6)
        XCTAssertEqual(projectedFailureScoreboard.successes, 3)
        XCTAssertEqual(projectedFailureScoreboard.successRate, 50)
        XCTAssertEqual(projectedFailureScoreboard.successStreak, 0)
        XCTAssertEqual(projectedFailureScoreboard.failureStreak, 1)

        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: 1_715_299_900,
                wasSuccess: false
            )
        ]
        let projectedHistory = AppDelegate.fameExceptionalLoopProjectedOutcomeCommandHistory(
            history,
            plan: plan,
            wasSuccessful: true,
            now: now
        )
        XCTAssertEqual(projectedHistory.count, 2)
        XCTAssertEqual(
            projectedHistory.last?.commandToken,
            AppDelegate.fameExceptionalLoopOutcomeFocusToken(plan)
        )
        XCTAssertEqual(projectedHistory.last?.recordedAt, now.timeIntervalSince1970)
        XCTAssertEqual(projectedHistory.last?.wasSuccess, true)
    }

    func testFameExceptionalLoopPlanAdaptiveTuningPivotsAfterRepeatedFailures() {
        let basePlan = AppDelegate.FameExceptionalLoopPlan(
            focusTitle: "Cadence Reinforcement",
            primaryCommandID: "run-fame-cadence-autopilot-loop",
            reasonLine: "Protect your streak and climb toward x3 with a fresh autopilot run.",
            followupActionID: "copy-fame-cadence-share-line",
            followupReasonLine: "Copy one momentum share line for immediate publishing."
        )
        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 1,
            successRate: 20,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: AppDelegate.fameExceptionalLoopOutcomeFocusToken(basePlan),
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )

        let tunedPlan = AppDelegate.fameExceptionalLoopPlanWithAdaptiveTuning(
            basePlan,
            scoreboard: scoreboard
        )

        XCTAssertEqual(tunedPlan.focusTitle, "Cadence Recovery Pivot")
        XCTAssertEqual(tunedPlan.primaryCommandID, "run-fame-next-move-cadence-execution-kit")
        XCTAssertEqual(tunedPlan.followupActionID, "copy-fame-cadence-share-line")
    }

    func testFameExceptionalLoopPlanAdaptiveTuningEscalatesAfterWinStreak() {
        let basePlan = AppDelegate.FameExceptionalLoopPlan(
            focusTitle: "Next Move Compounding",
            primaryCommandID: "run-fame-next-move-copy-drafts",
            reasonLine: "Run command center, then ship ranked drafts and follow-ups without delay.",
            followupActionID: nil,
            followupReasonLine: nil
        )
        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 8,
            successes: 6,
            successRate: 75,
            successStreak: 3,
            failureStreak: 0,
            lastFocusToken: AppDelegate.fameExceptionalLoopOutcomeFocusToken(basePlan),
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )

        let tunedPlan = AppDelegate.fameExceptionalLoopPlanWithAdaptiveTuning(
            basePlan,
            scoreboard: scoreboard
        )

        XCTAssertEqual(tunedPlan.focusTitle, "Breakout Amplification+")
        XCTAssertEqual(tunedPlan.primaryCommandID, "run-fame-spotlight-pack")
        XCTAssertEqual(tunedPlan.followupActionID, "copy-fame-cadence-share-pack")
    }

    func testFameExceptionalLoopPlanAdaptiveTuningUsesPerCommandScoreboardWhenGlobalFocusDiffers() {
        let basePlan = AppDelegate.FameExceptionalLoopPlan(
            focusTitle: "Cadence Reinforcement",
            primaryCommandID: "run-fame-cadence-autopilot-loop",
            reasonLine: "Protect your streak and climb toward x3 with a fresh autopilot run.",
            followupActionID: "copy-fame-cadence-share-line",
            followupReasonLine: "Copy one momentum share line for immediate publishing."
        )
        let globalScoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 8,
            successes: 5,
            successRate: 63,
            successStreak: 0,
            failureStreak: 0,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )
        let commandScoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 4,
            successes: 1,
            successRate: 25,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: AppDelegate.fameExceptionalLoopOutcomeFocusToken(basePlan),
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_230_000)
        )

        let tunedPlan = AppDelegate.fameExceptionalLoopPlanWithAdaptiveTuning(
            basePlan,
            scoreboard: globalScoreboard,
            commandScoreboard: commandScoreboard
        )

        XCTAssertEqual(tunedPlan.focusTitle, "Cadence Recovery Pivot")
        XCTAssertEqual(tunedPlan.primaryCommandID, "run-fame-next-move-cadence-execution-kit")
        XCTAssertEqual(tunedPlan.followupActionID, "copy-fame-cadence-share-line")
    }

    func testFameExceptionalLoopOutcomeCommandScoreboardUsesLatestPerCommandStreak() {
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_100_000,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: 1_715_100_100,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_100_200,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_100_300,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_100_400,
                wasSuccess: false
            )
        ]

        let scoreboard = AppDelegate.fameExceptionalLoopOutcomeCommandScoreboard(
            commandToken: "run-fame-cadence-autopilot-loop",
            history: history
        )

        XCTAssertEqual(scoreboard?.attempts, 4)
        XCTAssertEqual(scoreboard?.successes, 2)
        XCTAssertEqual(scoreboard?.successRate, 50)
        XCTAssertEqual(scoreboard?.successStreak, 0)
        XCTAssertEqual(scoreboard?.failureStreak, 2)
        XCTAssertEqual(scoreboard?.lastFocusToken, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(
            scoreboard?.lastOutcomeAt,
            Date(timeIntervalSince1970: 1_715_100_400)
        )
    }

    func testFameExceptionalLoopOutcomeLaneSummariesHighlightTopWinAndRecoveryLanes() {
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_200_000,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: 1_715_200_100,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_200_200,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: 1_715_200_300,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_200_400,
                wasSuccess: true
            )
        ]

        let laneSummaries = AppDelegate.fameExceptionalLoopOutcomeLaneSummaries(history: history)

        XCTAssertEqual(
            laneSummaries.topWinLane,
            "\(AppDelegate.fameExceptionalLoopCommandTitle("run-fame-cadence-autopilot-loop")) 3/3 (100%), streak x3"
        )
        XCTAssertEqual(
            laneSummaries.topRecoveryLane,
            "\(AppDelegate.fameExceptionalLoopCommandTitle("run-fame-next-move-copy-drafts")) misses 2/2, streak x2"
        )
    }

    func testFameExceptionalLoopMenuOutcomeSummaryToolTipIncludesLaneSummaries() {
        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 3,
            successRate: 60,
            successStreak: 2,
            failureStreak: 0,
            lastFocusToken: "run-fame-cadence-autopilot-loop",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )
        let laneSummaries = AppDelegate.FameExceptionalLoopOutcomeLaneSummaries(
            topWinLane: "Run Cadence Autopilot Loop 3/4 (75%), streak x2",
            topRecoveryLane: "Run Next Move + Copy Draft Pack misses 2/4, streak x2"
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopMenuOutcomeSummaryToolTip(
                scoreboard: scoreboard,
                laneSummaries: laneSummaries,
                recoveryActionSummary: "Run Next Move + Copy Draft Pack (2/4 misses, streak x2)"
            ),
            "Outcome trend: win lane x2 · 60% hit rate. Top win lane: Run Cadence Autopilot Loop 3/4 (75%), streak x2. Top recovery lane: Run Next Move + Copy Draft Pack misses 2/4, streak x2. Recovery next action: Run Next Move + Copy Draft Pack (2/4 misses, streak x2)."
        )
    }

    func testFameExceptionalLoopRecoveryLaneActionSummaryFormatsRecommendationAndFallback() {
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopRecoveryLaneActionSummary(nil),
            "none yet"
        )

        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 4,
            successes: 2,
            successRate: 50,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopRecoveryLaneActionSummary(scoreboard),
            "Run Next Move + Copy Draft Pack (2/4 misses, streak x2)"
        )
    }

    func testFameExceptionalLoopHealthSnapshotFormatsTrendLanesAndRecommendedAction() {
        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 6,
            successes: 4,
            successRate: 67,
            successStreak: 2,
            failureStreak: 0,
            lastFocusToken: "run-fame-cadence-autopilot-loop",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_200_000,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: 1_715_200_100,
                wasSuccess: true
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: 1_715_200_200,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: 1_715_200_300,
                wasSuccess: false
            )
        ]

        let snapshot = AppDelegate.fameExceptionalLoopHealthSnapshot(
            scoreboard: scoreboard,
            history: history
        )

        XCTAssertEqual(snapshot.trend, "Outcome trend: win lane x2 · 67% hit rate.")
        XCTAssertEqual(
            snapshot.topWinLane,
            "Run Cadence Autopilot Loop 2/2 (100%), streak x2"
        )
        XCTAssertEqual(
            snapshot.topRecoveryLane,
            "Run Next Move + Copy Draft Pack misses 2/2, streak x2"
        )
        XCTAssertEqual(
            snapshot.recommendedNextAction,
            "Run Next Move + Copy Draft Pack (2/2 misses, streak x2)"
        )
        XCTAssertEqual(
            snapshot.recommendedActionCommandID,
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertEqual(
            snapshot.recommendedActionTitle,
            "Run Next Move + Copy Draft Pack"
        )
        XCTAssertEqual(snapshot.recommendedActionConfidenceTitle, "High")
        XCTAssertEqual(
            snapshot.recommendedActionWhy,
            "Recovery lane pressure is active on Run Next Move + Copy Draft Pack: 2/2 misses with streak x2."
        )
    }

    func testFameExceptionalLoopHealthSnapshotFallsBackToSeedActionWithoutRecoveryLane() {
        let snapshot = AppDelegate.fameExceptionalLoopHealthSnapshot(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 0,
                successes: 0,
                successRate: 0,
                successStreak: 0,
                failureStreak: 0,
                lastFocusToken: nil,
                lastOutcomeAt: nil
            ),
            history: []
        )

        XCTAssertEqual(snapshot.trend, "Outcome trend: warming up.")
        XCTAssertEqual(snapshot.topWinLane, "none yet")
        XCTAssertEqual(snapshot.topRecoveryLane, "none yet")
        XCTAssertEqual(
            snapshot.recommendedNextAction,
            "Run Fame Exceptional Loop to seed outcomes."
        )
        XCTAssertEqual(
            snapshot.recommendedActionCommandID,
            "run-fame-exceptional-loop"
        )
        XCTAssertEqual(
            snapshot.recommendedActionTitle,
            "Run Fame Exceptional Loop"
        )
        XCTAssertEqual(snapshot.recommendedActionConfidenceTitle, "Low")
        XCTAssertEqual(
            snapshot.recommendedActionWhy,
            "No lane telemetry yet. Run the full exceptional loop once to establish win/recovery lanes."
        )
    }

    func testFameExceptionalLoopHealthSnapshotCanRecommendTopWinLaneWhenRecoveryIsStable() {
        let snapshot = AppDelegate.fameExceptionalLoopHealthSnapshot(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 4,
                successes: 4,
                successRate: 100,
                successStreak: 4,
                failureStreak: 0,
                lastFocusToken: "run-fame-cadence-autopilot-loop",
                lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
            ),
            history: [
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_000,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_100,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_200,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_300,
                    wasSuccess: true
                )
            ]
        )

        XCTAssertEqual(
            snapshot.recommendedActionCommandID,
            "run-fame-cadence-autopilot-loop"
        )
        XCTAssertEqual(
            snapshot.recommendedActionTitle,
            "Run Cadence Autopilot Loop"
        )
        XCTAssertEqual(
            snapshot.recommendedNextAction,
            "Run Cadence Autopilot Loop (top win lane is compounding; press while momentum is hot)."
        )
        XCTAssertEqual(snapshot.recommendedActionConfidenceTitle, "High")
        XCTAssertEqual(
            snapshot.recommendedActionWhy,
            "Win lane momentum is strongest on Run Cadence Autopilot Loop: 4/4 hits, streak x4."
        )
    }

    func testFameExceptionalLoopHealthSnapshotCanFallbackToLatestFocusLaneWhenNoLaneLeads() {
        let snapshot = AppDelegate.fameExceptionalLoopHealthSnapshot(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 1,
                successes: 1,
                successRate: 100,
                successStreak: 1,
                failureStreak: 0,
                lastFocusToken: "run-fame-command-center",
                lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
            ),
            history: []
        )

        XCTAssertEqual(snapshot.recommendedActionCommandID, "run-fame-command-center")
        XCTAssertEqual(snapshot.recommendedActionTitle, "Run Fame Command Center")
        XCTAssertEqual(
            snapshot.recommendedNextAction,
            "Run Fame Command Center (latest focus lane while telemetry warms up)."
        )
        XCTAssertEqual(snapshot.recommendedActionConfidenceTitle, "Low")
        XCTAssertEqual(
            snapshot.recommendedActionWhy,
            "No clear win/recovery lane leader yet; using the latest focus lane from outcomes telemetry."
        )
    }

    func testFameExceptionalLoopCommandPaletteSignalBadgeMapsConfidenceAndHelpText() {
        func snapshot(
            confidenceTitle: String,
            why: String = "Recovery lane pressure is active."
        ) -> AppDelegate.FameExceptionalLoopHealthSnapshot {
            AppDelegate.FameExceptionalLoopHealthSnapshot(
                trend: "Outcome trend: mixed · 50% hit rate.",
                topWinLane: "Run Cadence Autopilot Loop 1/2 (50%), streak x1",
                topRecoveryLane: "Run Next Move + Copy Draft Pack misses 1/2, streak x1",
                recommendedNextAction: "Run Next Move + Copy Draft Pack (1/2 misses, streak x1)",
                recommendedActionCommandID: "run-fame-next-move-copy-drafts",
                recommendedActionTitle: "Run Next Move + Copy Draft Pack",
                recommendedActionConfidenceTitle: confidenceTitle,
                recommendedActionWhy: why
            )
        }

        let highBadge = AppDelegate.fameExceptionalLoopCommandPaletteSignalBadge(
            snapshot(confidenceTitle: "High")
        )
        XCTAssertEqual(highBadge.title, "Loop High")
        XCTAssertEqual(highBadge.tone, .high)
        XCTAssertTrue(highBadge.helpText.contains("Run Next Move + Copy Draft Pack"))
        XCTAssertEqual(highBadge.recommendedActionID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(highBadge.recommendedActionTitle, "Run Next Move + Copy Draft Pack")

        let mediumBadge = AppDelegate.fameExceptionalLoopCommandPaletteSignalBadge(
            snapshot(confidenceTitle: "Medium")
        )
        XCTAssertEqual(mediumBadge.title, "Loop Medium")
        XCTAssertEqual(mediumBadge.tone, .medium)

        let lowBadge = AppDelegate.fameExceptionalLoopCommandPaletteSignalBadge(
            snapshot(confidenceTitle: "Low")
        )
        XCTAssertEqual(lowBadge.title, "Loop Low")
        XCTAssertEqual(lowBadge.tone, .low)

        let fallbackBadge = AppDelegate.fameExceptionalLoopCommandPaletteSignalBadge(
            snapshot(confidenceTitle: "Unknown")
        )
        XCTAssertEqual(fallbackBadge.title, "Loop Unknown")
        XCTAssertEqual(fallbackBadge.tone, .low)
    }

    func testCommandPaletteRecommendationPanelModelUsesSignalBadgeHelpText() throws {
        let action = CommandPaletteAction(
            id: "run-fame-exceptional-loop",
            title: "Run Fame Exceptional Loop",
            subtitle: "Exceptional loop telemetry guidance",
            systemImage: "sparkles",
            signalBadge: CommandPaletteAction.SignalBadge(
                title: "Loop High",
                tone: .high,
                helpText: "Run Next Move + Copy Draft Pack because recovery lane pressure is elevated.",
                recommendedActionID: "run-fame-next-move-copy-drafts",
                recommendedActionTitle: "Run Next Move + Copy Draft Pack"
            ),
            canFavorite: false
        ) {}

        let panelModel = try XCTUnwrap(
            CommandPaletteAction.recommendationPanelModel(for: action)
        )

        XCTAssertEqual(panelModel.title, "Why this recommendation")
        XCTAssertEqual(panelModel.actionID, "run-fame-exceptional-loop")
        XCTAssertEqual(panelModel.actionTitle, "Run Fame Exceptional Loop")
        XCTAssertEqual(panelModel.badgeTitle, "Loop High")
        XCTAssertEqual(panelModel.tone, .high)
        XCTAssertEqual(
            panelModel.detail,
            "Run Next Move + Copy Draft Pack because recovery lane pressure is elevated."
        )
        XCTAssertEqual(panelModel.recommendedActionID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(panelModel.recommendedActionTitle, "Run Next Move + Copy Draft Pack")
    }

    func testCommandPaletteRecommendationPanelModelSkipsWithoutUsableSignalHelpText() {
        let noBadgeAction = CommandPaletteAction(
            id: "run-fame-exceptional-loop",
            title: "Run Fame Exceptional Loop",
            subtitle: "Exceptional loop telemetry guidance",
            systemImage: "sparkles",
            canFavorite: false
        ) {}

        XCTAssertNil(CommandPaletteAction.recommendationPanelModel(for: noBadgeAction))

        let emptyHelpTextAction = CommandPaletteAction(
            id: "run-fame-exceptional-loop",
            title: "Run Fame Exceptional Loop",
            subtitle: "Exceptional loop telemetry guidance",
            systemImage: "sparkles",
            signalBadge: CommandPaletteAction.SignalBadge(
                title: "Loop High",
                tone: .high,
                helpText: "   "
            ),
            canFavorite: false
        ) {}

        XCTAssertNil(CommandPaletteAction.recommendationPanelModel(for: emptyHelpTextAction))
    }

    func testFameExceptionalLoopHealthRecommendationUsesMediumRecoveryConfidenceBelowEscalationThreshold() {
        let recommendation = AppDelegate.fameExceptionalLoopHealthRecommendation(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 4,
                successes: 3,
                successRate: 75,
                successStreak: 0,
                failureStreak: 1,
                lastFocusToken: "run-fame-next-move-copy-drafts",
                lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_400)
            ),
            history: [
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_100,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_200,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_300,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_400,
                    wasSuccess: false
                )
            ]
        )

        XCTAssertEqual(recommendation.commandID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(
            recommendation.summary,
            "Run Next Move + Copy Draft Pack (1/4 misses, streak x1)"
        )
        XCTAssertEqual(recommendation.confidenceTitle, "Medium")
        XCTAssertEqual(
            recommendation.whyLine,
            "Recovery lane pressure is active on Run Next Move + Copy Draft Pack: 1/4 misses with streak x1."
        )
    }

    func testFameExceptionalLoopHealthRecommendationUsesHighRecoveryConfidenceAtMissEscalationThreshold() {
        let recommendation = AppDelegate.fameExceptionalLoopHealthRecommendation(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 4,
                successes: 1,
                successRate: 25,
                successStreak: 0,
                failureStreak: 1,
                lastFocusToken: "run-fame-next-move-copy-drafts",
                lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_400)
            ),
            history: [
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_100,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_200,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_300,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: 1_715_200_400,
                    wasSuccess: false
                )
            ]
        )

        XCTAssertEqual(recommendation.commandID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(
            recommendation.summary,
            "Run Next Move + Copy Draft Pack (3/4 misses, streak x1)"
        )
        XCTAssertEqual(recommendation.confidenceTitle, "High")
        XCTAssertEqual(
            recommendation.whyLine,
            "Recovery lane pressure is active on Run Next Move + Copy Draft Pack: 3/4 misses with streak x1."
        )
    }

    func testFameExceptionalLoopHealthRecommendationUsesMediumWinLaneConfidenceBelowCompoundingThreshold() {
        let recommendation = AppDelegate.fameExceptionalLoopHealthRecommendation(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 3,
                successes: 2,
                successRate: 67,
                successStreak: 2,
                failureStreak: 0,
                lastFocusToken: "run-fame-cadence-autopilot-loop",
                lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_700)
            ),
            history: [
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_100,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_200,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_300,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_400,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_500,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_600,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_700,
                    wasSuccess: true
                )
            ]
        )

        XCTAssertEqual(recommendation.commandID, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(
            recommendation.summary,
            "Run Cadence Autopilot Loop (top win lane is compounding; press while momentum is hot)."
        )
        XCTAssertEqual(recommendation.confidenceTitle, "Medium")
        XCTAssertEqual(
            recommendation.whyLine,
            "Win lane momentum is strongest on Run Cadence Autopilot Loop: 2/3 hits, streak x2."
        )
    }

    func testFameExceptionalLoopHealthRecommendationUsesHighWinLaneConfidenceAtSuccessRateThreshold() {
        let recommendation = AppDelegate.fameExceptionalLoopHealthRecommendation(
            scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                attempts: 5,
                successes: 4,
                successRate: 80,
                successStreak: 2,
                failureStreak: 0,
                lastFocusToken: "run-fame-cadence-autopilot-loop",
                lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_800)
            ),
            history: [
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_100,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_200,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "custom-unknown-lane",
                    recordedAt: 1_715_200_300,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_400,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_500,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_600,
                    wasSuccess: false
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_700,
                    wasSuccess: true
                ),
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: 1_715_200_800,
                    wasSuccess: true
                )
            ]
        )

        XCTAssertEqual(recommendation.commandID, "run-fame-cadence-autopilot-loop")
        XCTAssertEqual(
            recommendation.summary,
            "Run Cadence Autopilot Loop (top win lane is compounding; press while momentum is hot)."
        )
        XCTAssertEqual(recommendation.confidenceTitle, "High")
        XCTAssertEqual(
            recommendation.whyLine,
            "Win lane momentum is strongest on Run Cadence Autopilot Loop: 4/5 hits, streak x2."
        )
    }

    func testFameExceptionalLoopOutcomeScoreboardReadsDefaultsAndNormalizesValues() throws {
        let suiteName = "AppDelegateLaunchOutcomeScoreboardTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(5, forKey: "total")
        defaults.set(9, forKey: "successes")
        defaults.set(-2, forKey: "successStreak")
        defaults.set(3, forKey: "failureStreak")
        defaults.set(" run-fame-next-move-copy-drafts ", forKey: "focus")
        defaults.set(1_715_200_000.0, forKey: "lastAt")

        let scoreboard = AppDelegate.fameExceptionalLoopOutcomeScoreboard(
            defaults: defaults,
            totalCountKey: "total",
            successCountKey: "successes",
            successStreakKey: "successStreak",
            failureStreakKey: "failureStreak",
            lastFocusTokenKey: "focus",
            lastAtKey: "lastAt"
        )

        XCTAssertEqual(scoreboard.attempts, 5)
        XCTAssertEqual(scoreboard.successes, 5)
        XCTAssertEqual(scoreboard.successRate, 100)
        XCTAssertEqual(scoreboard.successStreak, 0)
        XCTAssertEqual(scoreboard.failureStreak, 3)
        XCTAssertEqual(scoreboard.lastFocusToken, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(
            scoreboard.lastOutcomeAt,
            Date(timeIntervalSince1970: 1_715_200_000.0)
        )
    }

    func testFameExceptionalLoopRecoveryLaneMenuStatusArmsWhenRecoveryLaneIsHot() {
        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 4,
            successes: 2,
            successRate: 50,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopRecoveryLaneMenuStatus(scoreboard),
            AppDelegate.FameExceptionalLoopRecoveryLaneMenuStatus(
                title: "Run Recovery Lane Now: Run Next Move + Copy Draft Pack",
                toolTip: "Top recovery lane 2/4 misses, streak x2. Click to run Run Next Move + Copy Draft Pack now.",
                isEnabled: true
            )
        )
    }

    func testFameExceptionalLoopRecoveryLaneMenuStatusStaysNotArmedWhenTelemetryIsStable() {
        let scoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 2,
            successes: 1,
            successRate: 50,
            successStreak: 0,
            failureStreak: 0,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopRecoveryLaneMenuStatus(scoreboard),
            AppDelegate.FameExceptionalLoopRecoveryLaneMenuStatus(
                title: "Run Recovery Lane Now (Not Armed)",
                toolTip: "Top recovery lane Run Next Move + Copy Draft Pack is stable (1/2 misses, streak x0). Arms at 2+ misses with an active failure streak.",
                isEnabled: false
            )
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneCommandIDRequiresPressureAndRespectsCooldown() {
        let now = Date(timeIntervalSince1970: 140_000)
        let recoveryLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 1,
            successRate: 20,
            successStreak: 0,
            failureStreak: 3,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: false,
                topRecoveryLane: recoveryLane,
                primaryCommandID: "run-fame-launch-control-hub",
                followupCommandID: "copy-fame-launch-control-brief",
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: false,
                topRecoveryLane: recoveryLane,
                primaryCommandID: "run-fame-launch-control-hub",
                followupCommandID: "copy-fame-launch-control-brief",
                lastAutoRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldown: 20 * 60
            )
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneCommandIDSkipsSuccessLowPressureAndDuplicateRoute() {
        let now = Date(timeIntervalSince1970: 140_000)
        let lowPressureLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 2,
            successes: 1,
            successRate: 50,
            successStreak: 0,
            failureStreak: 1,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )
        let duplicateRouteLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 1,
            successRate: 20,
            successStreak: 0,
            failureStreak: 3,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )

        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: true,
                topRecoveryLane: duplicateRouteLane,
                primaryCommandID: "run-fame-launch-control-hub",
                followupCommandID: nil,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            )
        )
        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: false,
                topRecoveryLane: lowPressureLane,
                primaryCommandID: "run-fame-launch-control-hub",
                followupCommandID: nil,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            )
        )
        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: false,
                topRecoveryLane: duplicateRouteLane,
                primaryCommandID: "run-fame-next-move-copy-drafts",
                followupCommandID: nil,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            )
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneCommandIDHonorsCustomArmingThresholds() {
        let now = Date(timeIntervalSince1970: 140_000)
        let recoveryLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 2,
            successes: 0,
            successRate: 0,
            successStreak: 0,
            failureStreak: 1,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )

        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: false,
                topRecoveryLane: recoveryLane,
                primaryCommandID: "run-fame-launch-control-hub",
                followupCommandID: nil,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneCommandID(
                wasSuccessful: false,
                topRecoveryLane: recoveryLane,
                primaryCommandID: "run-fame-launch-control-hub",
                followupCommandID: nil,
                lastAutoRunAt: nil,
                now: now,
                missesRequired: 2,
                failureStreakRequired: 1,
                cooldown: 20 * 60
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneRunSummaryFormatsTelemetry() {
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneRunSummary(
                commandID: "run-fame-next-move-copy-drafts",
                misses: 3,
                attempts: 5,
                failureStreak: 3
            ),
            "Auto recovery lane fired: Run Next Move + Copy Draft Pack (3/5 misses, streak x3)."
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneTuningRecommendationRequiresEnoughTelemetry() {
        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                topRecoveryLane: nil
            )
        )

        let lowSampleLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 2,
            successes: 0,
            successRate: 0,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 200_000)
        )
        XCTAssertNil(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                topRecoveryLane: lowSampleLane
            )
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneTuningRecommendationCanTightenAndRelaxThresholds() {
        let pressureLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 6,
            successes: 0,
            successRate: 0,
            successStreak: 0,
            failureStreak: 4,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 200_000)
        )
        let stableLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 9,
            successes: 8,
            successRate: 89,
            successStreak: 2,
            failureStreak: 0,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: Date(timeIntervalSince1970: 210_000)
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                topRecoveryLane: pressureLane
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 2,
                failureStreakRequired: 1,
                cooldownMinutes: 5,
                rationale: "Pressure is persistent (6/6 misses, streak x4); fire recovery quickly."
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                topRecoveryLane: stableLane
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 5,
                failureStreakRequired: 3,
                cooldownMinutes: 60,
                rationale: "Lane is stable (1/9 misses); reduce auto-fire frequency."
            )
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummaryFormatsCurrentVsSuggested() {
        let recommendation = AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
            missesRequired: 2,
            failureStreakRequired: 1,
            cooldownMinutes: 10,
            rationale: "Lane is slipping (4/5 misses, streak x2); lower arming thresholds."
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: nil,
                currentMissesRequired: 3,
                currentFailureStreakRequired: 2,
                currentCooldownMinutes: 20
            ),
            "Need at least 3 recovery-lane attempts before adaptive tuning can calibrate (current 3+ misses, streak x2, cooldown 20m)."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: recommendation,
                currentMissesRequired: 3,
                currentFailureStreakRequired: 2,
                currentCooldownMinutes: 20
            ),
            "Suggested 2+ misses, streak x1, cooldown 10m from telemetry (current 3+ misses, streak x2, cooldown 20m). Lane is slipping (4/5 misses, streak x2); lower arming thresholds."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: recommendation,
                currentMissesRequired: 2,
                currentFailureStreakRequired: 1,
                currentCooldownMinutes: 10
            ),
            "Current tuning already matches telemetry (2+ misses, streak x1, cooldown 10m). Lane is slipping (4/5 misses, streak x2); lower arming thresholds."
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneTuningMenuStatusFormatsCalibratingSuggestedAndTunedStates() {
        let recommendation = AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
            missesRequired: 2,
            failureStreakRequired: 1,
            cooldownMinutes: 10,
            rationale: "Lane is slipping (4/5 misses, streak x2); lower arming thresholds."
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                recommendation: nil,
                currentMissesRequired: 3,
                currentFailureStreakRequired: 2,
                currentCooldownMinutes: 20
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                title: "Auto-Tune Recovery: Waiting for Telemetry",
                toolTip: "Need at least 3 recovery-lane attempts before adaptive tuning can calibrate (current 3+ misses, streak x2, cooldown 20m).",
                isEnabled: false
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                recommendation: recommendation,
                currentMissesRequired: 3,
                currentFailureStreakRequired: 2,
                currentCooldownMinutes: 20
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                title: "Auto-Tune Recovery: Suggested · 2+ misses, streak x1, cooldown 10m",
                toolTip: "Suggested 2+ misses, streak x1, cooldown 10m from telemetry (current 3+ misses, streak x2, cooldown 20m). Lane is slipping (4/5 misses, streak x2); lower arming thresholds.",
                isEnabled: true
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                recommendation: recommendation,
                currentMissesRequired: 2,
                currentFailureStreakRequired: 1,
                currentCooldownMinutes: 10
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                title: "Auto-Tune Recovery: Tuned",
                toolTip: "Current tuning already matches telemetry (2+ misses, streak x1, cooldown 10m). Lane is slipping (4/5 misses, streak x2); lower arming thresholds.",
                isEnabled: false
            )
        )
    }

    func testFameExceptionalLoopOutcomeTuningResetStatusFormatsBaselineAndReadyStates() {
        let now = Date(timeIntervalSince1970: 200_000)
        let commandHistory = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.timeIntervalSince1970,
                wasSuccess: false
            )
        ]

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopOutcomeTuningResetStatus(
                attempts: 0,
                successes: 0,
                successStreak: 0,
                failureStreak: 0,
                lastFocusToken: nil,
                lastOutcomeAt: nil,
                commandHistory: []
            ),
            AppDelegate.FameExceptionalLoopOutcomeTuningResetStatus(
                title: "Reset Exceptional Loop Tuning: Baseline",
                subtitle: "Adaptive outcome telemetry is already at baseline.",
                toolTip: "No adaptive outcome telemetry to clear yet.",
                isEnabled: false
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopOutcomeTuningResetStatus(
                attempts: 0,
                successes: 0,
                successStreak: 0,
                failureStreak: 0,
                lastFocusToken: nil,
                lastOutcomeAt: nil,
                commandHistory: commandHistory
            ),
            AppDelegate.FameExceptionalLoopOutcomeTuningResetStatus(
                title: "Reset Exceptional Loop Tuning",
                subtitle: "Clear adaptive outcome streaks and focus memory.",
                toolTip: "Clear adaptive outcome streaks and focus memory.",
                isEnabled: true
            )
        )
    }

    func testFameExceptionalLoopLatestRecapStatusFormatsUnavailableAndReadyStates() {
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopLatestRecapStatus(hasSavedRecap: false),
            AppDelegate.FameExceptionalLoopLatestRecapStatus(
                title: "Open Latest Exceptional Loop Recap (Unavailable)",
                subtitle: "No saved recap yet. Run Fame Exceptional Loop first.",
                toolTip: "No saved exceptional loop recap yet. Run Fame Exceptional Loop first.",
                isEnabled: false
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopLatestRecapStatus(hasSavedRecap: true),
            AppDelegate.FameExceptionalLoopLatestRecapStatus(
                title: "Open Latest Exceptional Loop Recap",
                subtitle: "Open latest run recap for the Fame exceptional loop",
                toolTip: "Open latest run recap for the Fame exceptional loop.",
                isEnabled: true
            )
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneStatusSummaryFormatsReadinessStates() {
        let now = Date(timeIntervalSince1970: 200_000)
        let lowPressureLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 2,
            successes: 1,
            successRate: 50,
            successStreak: 0,
            failureStreak: 1,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )
        let armedLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 2,
            successRate: 40,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: nil,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            "Auto recovery lane: Not armed (no eligible lane telemetry yet)."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: lowPressureLane,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            "Auto recovery lane: Not armed (1/2 misses, streak x1)."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: armedLane,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            "Auto recovery lane: Armed for Run Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: armedLane,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 0
            ),
            "Auto recovery lane: Armed for Run Next Move + Copy Draft Pack (cooldown off)."
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneStatusSummaryFormatsCooldownWindow() {
        let now = Date(timeIntervalSince1970: 200_000)
        let armedLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 2,
            successRate: 40,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: armedLane,
                lastAutoRunAt: now.addingTimeInterval(-121),
                now: now,
                cooldown: 5 * 60
            ),
            "Auto recovery lane: Cooling down 3m before Run Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: armedLane,
                lastAutoRunAt: now.addingTimeInterval(-360),
                now: now,
                cooldown: 5 * 60
            ),
            "Auto recovery lane: Armed for Run Next Move + Copy Draft Pack."
        )
    }

    func testFameExceptionalLoopAutoRecoveryLaneMenuStatusFormatsReadinessStates() {
        let now = Date(timeIntervalSince1970: 200_000)
        let lowPressureLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 2,
            successes: 1,
            successRate: 50,
            successStreak: 0,
            failureStreak: 1,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )
        let armedLane = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: 5,
            successes: 2,
            successRate: 40,
            successStreak: 0,
            failureStreak: 2,
            lastFocusToken: "run-fame-next-move-copy-drafts",
            lastOutcomeAt: now
        )

        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatus(
                topRecoveryLane: nil,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Not Armed",
                toolTip: "Auto recovery lane: Not armed (no eligible lane telemetry yet)."
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatus(
                topRecoveryLane: lowPressureLane,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Not Armed",
                toolTip: "Auto recovery lane: Not armed (1/2 misses, streak x1)."
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatus(
                topRecoveryLane: armedLane,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 20 * 60
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Armed · Run Next Move + Copy Draft Pack",
                toolTip: "Auto recovery lane: Armed for Run Next Move + Copy Draft Pack."
            )
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatus(
                topRecoveryLane: armedLane,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 0
            ),
            AppDelegate.FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Armed (Cooldown Off)",
                toolTip: "Auto recovery lane: Armed for Run Next Move + Copy Draft Pack (cooldown off)."
            )
        )
    }

    @MainActor
    func testFameExceptionalLoopAutoRecoveryLaneMenuStatusForTestingUsesConfiguredThresholdsAndCooldown() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let autoRunAtKey = AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousAutoRunAt = defaults.object(forKey: autoRunAtKey)
        let previousMissesRequired = settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let previousFailureStreakRequired = settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let previousCooldownMinutes = settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes

        defer {
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = previousMissesRequired
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
                previousFailureStreakRequired
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = previousCooldownMinutes
            restoreDefaultsObject(previousHistory, forKey: historyKey)
            restoreDefaultsObject(previousAutoRunAt, forKey: autoRunAtKey)
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 1
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 5

        let now = Date(timeIntervalSince1970: 200_000)
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-180).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-120).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)
        defaults.set(now.addingTimeInterval(-60).timeIntervalSince1970, forKey: autoRunAtKey)

        let appDelegate = AppDelegate()
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto Recovery Lane: Cooling Down (4m) · Run Next Move + Copy Draft Pack"
        )
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusToolTipForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto recovery lane: Cooling down 4m before Run Next Move + Copy Draft Pack."
        )

        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 0
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto Recovery Lane: Armed (Cooldown Off)"
        )
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusToolTipForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto recovery lane: Armed for Run Next Move + Copy Draft Pack (cooldown off)."
        )
    }

    @MainActor
    func testFameExceptionalLoopAutoRecoveryLaneTuningMenuStatusForTestingTracksSuggestedVsTuned() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousMissesRequired = settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let previousFailureStreakRequired = settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let previousCooldownMinutes = settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes

        defer {
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = previousMissesRequired
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
                previousFailureStreakRequired
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = previousCooldownMinutes
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 3
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 20

        let now = Date(timeIntervalSince1970: 200_000)
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-180).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-120).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-60).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let appDelegate = AppDelegate()
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto-Tune Recovery: Suggested · 2+ misses, streak x1, cooldown 10m"
        )
        XCTAssertTrue(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusIsEnabledForTesting(
                now: now,
                defaults: defaults
            )
        )
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusToolTipForTesting(
                now: now,
                defaults: defaults
            ),
            "Suggested 2+ misses, streak x1, cooldown 10m from telemetry (current 3+ misses, streak x2, cooldown 20m). Lane is slipping (3/3 misses, streak x3); lower arming thresholds."
        )

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 1
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 10

        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto-Tune Recovery: Tuned"
        )
        XCTAssertFalse(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusIsEnabledForTesting(
                now: now,
                defaults: defaults
            )
        )
    }

    @MainActor
    func testFameExceptionalLoopMenuStatusToolTipAndAutoRecoveryRowReflectCooldownLiveState() {
        let defaults = UserDefaults.standard
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let autoRunAtKey = AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousAutoRunAt = defaults.object(forKey: autoRunAtKey)

        defer {
            restoreDefaultsObject(previousHistory, forKey: historyKey)
            restoreDefaultsObject(previousAutoRunAt, forKey: autoRunAtKey)
        }

        let now = Date(timeIntervalSince1970: 200_000)
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-320).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-260).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-200).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)
        defaults.set(now.addingTimeInterval(-121).timeIntervalSince1970, forKey: autoRunAtKey)

        let appDelegate = AppDelegate()
        let statusToolTip = appDelegate.fameExceptionalLoopMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(
            statusToolTip.contains(
                "Auto recovery lane: Cooling down 18m before Run Next Move + Copy Draft Pack."
            )
        )
        XCTAssertTrue(statusToolTip.contains("Auto recovery recommendation:"))
        XCTAssertTrue(
            statusToolTip.contains(
                "Health recommendation [High]: Run Next Move + Copy Draft Pack (3/3 misses, streak x3)"
            )
        )
        XCTAssertTrue(
            statusToolTip.contains(
                "Why: Recovery lane pressure is active on Run Next Move + Copy Draft Pack: 3/3 misses with streak x3."
            )
        )
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto Recovery Lane: Cooling Down (18m) · Run Next Move + Copy Draft Pack"
        )
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusToolTipForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto recovery lane: Cooling down 18m before Run Next Move + Copy Draft Pack."
        )

        defaults.removeObject(forKey: autoRunAtKey)
        XCTAssertEqual(
            appDelegate.fameExceptionalLoopAutoRecoveryLaneMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto Recovery Lane: Armed · Run Next Move + Copy Draft Pack"
        )
    }

    func testFameExceptionalLoopOutcomeStatusTitleFormatsTrendStates() {
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopOutcomeStatusTitle(
                AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                    attempts: 0,
                    successes: 0,
                    successRate: 0,
                    successStreak: 0,
                    failureStreak: 0,
                    lastFocusToken: nil,
                    lastOutcomeAt: nil
                )
            ),
            "Outcome trend: warming up."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopOutcomeStatusTitle(
                AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                    attempts: 7,
                    successes: 4,
                    successRate: 57,
                    successStreak: 2,
                    failureStreak: 0,
                    lastFocusToken: "run-fame-cadence-autopilot-loop",
                    lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
                )
            ),
            "Outcome trend: win lane x2 · 57% hit rate."
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopOutcomeStatusTitle(
                AppDelegate.FameExceptionalLoopOutcomeScoreboard(
                    attempts: 9,
                    successes: 3,
                    successRate: 33,
                    successStreak: 0,
                    failureStreak: 3,
                    lastFocusToken: "run-fame-next-move-copy-drafts",
                    lastOutcomeAt: Date(timeIntervalSince1970: 1_715_200_000)
                )
            ),
            "Outcome trend: recovery lane x3 · 33% hit rate."
        )
    }

    func testFameNextMoveCommandLabelFormatsKnownAndFallbackCommands() {
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-escalation-nudge"),
            "Escalation Nudge"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-recovery-sprint"),
            "Recovery Sprint"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-command-center"),
            "Command Center"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-breakthrough-forecast"),
            "Breakthrough Forecast"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-spotlight-pack"),
            "Spotlight Pack"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-sprint-snapshot"),
            "Save Snapshot"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-daily-checkpoint"),
            "Daily Checkpoint"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveCommandLabel("run-fame-pulse-nudge"),
            "Pulse Nudge"
        )
    }

    func testFameNextMoveMenuTitleIncludesCommandLabel() {
        XCTAssertEqual(
            AppDelegate.fameNextMoveMenuTitle(commandID: "run-fame-recovery-sprint"),
            "Run Fame Next Move: Recovery Sprint"
        )
        XCTAssertEqual(
            AppDelegate.fameNextMoveMenuTitle(
                commandID: "run-fame-recovery-sprint",
                onboardingRecoveryHint: "Onboarding recovery: 1 artifact left"
            ),
            "Run Fame Next Move: Recovery Sprint · Onboarding recovery: 1 artifact left"
        )
    }

    func testFameOnboardingCommandTitleMapsCadenceShareLineCopyAction() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("run-fame-exceptional-loop"),
            "Run Fame Exceptional Loop"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("run-fame-exceptional-loop-recovery-lane-now"),
            "Run Recovery Lane Now"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("copy-fame-cadence-share-line"),
            "Copy Cadence Share Line"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("copy-fame-cadence-share-pack"),
            "Copy Cadence Share Pack"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("copy-next-move-best-channel-launch-pack"),
            "Copy Best Channel Launch Pack"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("copy-next-move-best-channel-draft"),
            "Copy Best Channel Draft"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("open-latest-cadence-momentum-brief"),
            "Open Latest Cadence Momentum Brief"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("open-latest-cadence-share-line"),
            "Open Latest Cadence Share Line"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("open-latest-cadence-share-pack"),
            "Open Latest Cadence Share Pack"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("open-latest-fame-exceptional-loop-recap"),
            "Open Latest Exceptional Loop Recap"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("auto-tune-fame-exceptional-loop-recovery"),
            "Auto-Tune Exceptional Loop Recovery"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingCommandTitle("reset-fame-exceptional-loop-tuning"),
            "Reset Exceptional Loop Tuning"
        )
    }

    func testNextMoveBestChannelDraftActionSubtitleFallsBackWithoutHandoff() {
        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelDraftActionSubtitle(handoffMarkdown: nil),
            "Copy first cadence channel draft from handoff"
        )
    }

    func testNextMoveBestChannelDraftActionSubtitleIncludesResolvedBestChannel() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship the X proof loop now.
        Bluesky draft (<=300): Blue proof loop shipped today.
        LinkedIn draft: LinkedIn proof loop and results.
        Checklist comment draft: Checklist comment for handoff.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelDraftActionSubtitle(handoffMarkdown: handoff),
            "Best channel now: X · copy first cadence draft"
        )
    }

    func testNextMoveBestChannelLaunchPackActionSubtitleFallsBackWithoutHandoff() {
        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackActionSubtitle(handoffMarkdown: nil),
            "Copy best channel post + launch pack"
        )
    }

    func testNextMoveBestChannelLaunchPackActionSubtitleIncludesResolvedBestChannel() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship the X proof loop now.
        Bluesky draft (<=300): Blue proof loop shipped today.
        LinkedIn draft: LinkedIn proof loop and results.
        Checklist comment draft: Checklist comment for handoff.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackActionSubtitle(handoffMarkdown: handoff),
            "Best channel now: X · copy post + launch pack"
        )
    }

    func testNextMoveBestChannelLaunchPackActionSubtitleCanAppendPressureModeShift() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship the X proof loop now.
        Bluesky draft (<=300): Blue proof loop shipped today.
        LinkedIn draft: LinkedIn proof loop and results.
        Checklist comment draft: Checklist comment for handoff.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackActionSubtitle(
                handoffMarkdown: handoff,
                pressureModeTransitionCount: 4,
                pressureModeTransitionLatest: "cooling-to-rebuilding"
            ),
            "Best channel now: X · copy post + launch pack · Mode shift Cooling -> Rebuilding"
        )
        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackActionSubtitle(
                handoffMarkdown: nil,
                pressureModeTransitionCount: 3,
                pressureModeTransitionLatest: "rebuilding-to-compounding"
            ),
            "Copy best channel post + launch pack · Mode shift Rebuilding -> Compounding"
        )
        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackActionSubtitle(
                handoffMarkdown: handoff,
                pressureModeTransitionCount: 5,
                pressureModeTransitionLatest: "rebuilding-to-compounding",
                pressureModeMomentumStreak: 3
            ),
            "Best channel now: X · copy post + launch pack · Mode shift Rebuilding -> Compounding · Upshift streak x3"
        )
    }

    func testBestChannelLaunchPackPressureModeShiftSubtitleHandlesMalformedAndEmptyState() {
        XCTAssertNil(
            AppDelegate.bestChannelLaunchPackPressureModeShiftSubtitle(
                transitionCount: 0,
                latestToken: "cooling-to-rebuilding"
            )
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackPressureModeShiftSubtitle(
                transitionCount: 2,
                latestToken: "invalid"
            ),
            "Mode shift tracked"
        )
    }

    func testBestChannelLaunchPackMenuTitlesAndTooltipsAdaptToLatestModeShift() {
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuTitle(
                transitionCount: 4,
                latestToken: "cooling-to-rebuilding"
            ),
            "Copy Best Channel Launch Pack · Rebuild Streak"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelDraftMenuTitle(
                transitionCount: 4,
                latestToken: "cooling-to-rebuilding"
            ),
            "Copy Best Channel Draft · Support Rebuild"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuToolTip(
                transitionCount: 4,
                latestToken: "cooling-to-rebuilding"
            ),
            "Copy best channel post + launch pack from the latest handoff. Latest mode shift Cooling -> Rebuilding (4 total). One more win can restore compounding pace."
        )
        XCTAssertEqual(
            AppDelegate.bestChannelDraftMenuToolTip(
                transitionCount: 4,
                latestToken: "cooling-to-rebuilding"
            ),
            "Copy the first cadence draft for the current best channel. Latest mode shift Cooling -> Rebuilding (4 total). Draft now to support the rebuild push."
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuTitle(
                transitionCount: 5,
                latestToken: "rebuilding-to-compounding",
                momentumStreak: 3
            ),
            "Copy Best Channel Launch Pack · Surge x3"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelDraftMenuTitle(
                transitionCount: 5,
                latestToken: "rebuilding-to-compounding",
                momentumStreak: 3
            ),
            "Copy Best Channel Draft · Queue Surge Support"
        )
    }

    func testBestChannelLaunchPackMenuTitlesAndTooltipsFallbackWhenModeShiftTokenIsMissing() {
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuTitle(
                transitionCount: 0,
                latestToken: nil
            ),
            "Copy Best Channel Launch Pack"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelDraftMenuTitle(
                transitionCount: 0,
                latestToken: nil
            ),
            "Copy Best Channel Draft"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuTitle(
                transitionCount: 2,
                latestToken: "invalid"
            ),
            "Copy Best Channel Launch Pack · Mode Shift"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelDraftMenuTitle(
                transitionCount: 2,
                latestToken: "invalid"
            ),
            "Copy Best Channel Draft · Mode Assist"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuToolTip(
                transitionCount: 2,
                latestToken: "invalid"
            ),
            "Copy best channel post + launch pack from the latest handoff. Mode shifts are tracked (2 total); ship now to stabilize momentum."
        )
        XCTAssertEqual(
            AppDelegate.bestChannelDraftMenuToolTip(
                transitionCount: 2,
                latestToken: "invalid"
            ),
            "Copy the first cadence draft for the current best channel. Mode shifts are tracked (2 total); queue draft support before the next ship window."
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackMenuToolTip(
                transitionCount: 5,
                latestToken: "invalid",
                momentumStreak: -2
            ),
            "Copy best channel post + launch pack from the latest handoff. Mode shifts are tracked (5 total); ship now to stabilize momentum. Mode momentum is cooling (cooldown streak x2)."
        )
    }

    func testFameOnboardingRecoveryMomentumHintFormatsActiveAndClosedStates() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMomentumHint(
                isFreshRecovery: true,
                remainingArtifacts: 1
            ),
            "Onboarding recovery: 1 artifact left"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMomentumHint(
                isFreshRecovery: true,
                remainingArtifacts: 2
            ),
            "Onboarding recovery: 2 artifacts left"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMomentumHint(
                isFreshRecovery: true,
                remainingArtifacts: 0
            ),
            "Onboarding recovery: gap closed"
        )
        XCTAssertNil(
            AppDelegate.fameOnboardingRecoveryMomentumHint(
                isFreshRecovery: false,
                remainingArtifacts: 1
            )
        )
    }

    func testCadenceExecutionKitCommandActionClassificationMatchesKnownIDs() {
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandAction("run-fame-next-move-cadence-execution-kit"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandAction("copy-next-move-cadence-execution-kit"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandAction("run-fame-cadence-autopilot-loop"))
        XCTAssertFalse(AppDelegate.isCadenceExecutionKitCommandAction("run-fame-next-move-copy-drafts"))
    }

    func testCadenceExecutionKitCommandNeutralActionClassificationMatchesKnownIDs() {
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-cadence-momentum-brief"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("copy-fame-cadence-share-line"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("copy-fame-cadence-share-pack"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("copy-next-move-best-channel-launch-pack"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("copy-next-move-best-channel-draft"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("open-latest-cadence-momentum-brief"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("open-latest-cadence-share-line"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("open-latest-cadence-share-pack"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("open-latest-fame-exceptional-loop-recap"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-cadence-celebration-demo"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-onboarding-fill-gap"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-onboarding-daily-brief"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-onboarding-scorecard"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-onboarding-nudge"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("auto-tune-fame-exceptional-loop-recovery"))
        XCTAssertTrue(AppDelegate.isCadenceExecutionKitCommandNeutralAction("reset-fame-exceptional-loop-tuning"))
        XCTAssertFalse(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-cadence-autopilot-loop"))
        XCTAssertFalse(AppDelegate.isCadenceExecutionKitCommandNeutralAction("run-fame-next-move-cadence-execution-kit"))
    }

    func testNextCadenceExecutionKitCommandStreakIncrementsAndResets() {
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 2,
                actionID: "run-fame-next-move-cadence-execution-kit"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "copy-next-move-cadence-execution-kit"
            ),
            4
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-next-move-copy-drafts"
            ),
            0
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-cadence-momentum-brief"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "copy-fame-cadence-share-line"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "copy-fame-cadence-share-pack"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "copy-next-move-best-channel-launch-pack"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "copy-next-move-best-channel-draft"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "open-latest-cadence-momentum-brief"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "open-latest-cadence-share-line"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "open-latest-cadence-share-pack"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-cadence-celebration-demo"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-onboarding-fill-gap"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-onboarding-daily-brief"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-onboarding-scorecard"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-onboarding-nudge"
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: 3,
                actionID: "run-fame-cadence-autopilot-loop"
            ),
            4
        )
        XCTAssertEqual(
            AppDelegate.nextCadenceExecutionKitCommandStreak(
                currentStreak: -4,
                actionID: "copy-next-move-cadence-execution-kit"
            ),
            1
        )
    }

    func testResetCadenceExecutionKitCommandStreakClearsCurrentAndBestDefaults() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(9, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)

        AppDelegate.resetCadenceExecutionKitCommandStreak(defaults: defaults)

        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 0)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 0)
    }

    func testResetFameExceptionalLoopOutcomeTuningClearsStoredTelemetry() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(6, forKey: AppDefaults.fameExceptionalLoopOutcomeTotalCountKey)
        defaults.set(4, forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey)
        defaults.set(2, forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey)
        defaults.set(1, forKey: AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey)
        defaults.set("run-fame-cadence-autopilot-loop", forKey: AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey)
        defaults.set(Date().timeIntervalSince1970, forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey)
        defaults.set(
            Date().addingTimeInterval(-120).timeIntervalSince1970,
            forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey
        )
        defaults.set(
            try? JSONEncoder().encode([
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-cadence-autopilot-loop",
                    recordedAt: Date().timeIntervalSince1970,
                    wasSuccess: true
                )
            ]),
            forKey: AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        )

        AppDelegate.resetFameExceptionalLoopOutcomeTuning(defaults: defaults)

        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeTotalCountKey), 0)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey), 0)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey), 0)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey), 0)
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey))
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey))
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey))
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey))
    }

    func testCadenceExecutionKitCommandStreakUpdateWritesDefaultsAndActivityDetails() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(2, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(2, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)

        let milestoneUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-next-move-cadence-execution-kit",
            defaults: defaults
        )
        XCTAssertEqual(milestoneUpdate.previousStreak, 2)
        XCTAssertEqual(milestoneUpdate.nextStreak, 3)
        XCTAssertEqual(milestoneUpdate.bestStreak, 3)
        XCTAssertEqual(milestoneUpdate.milestone, 3)
        XCTAssertEqual(
            milestoneUpdate.activityDetails,
            ["cadence-execution-kit-streak-3", "cadence-execution-kit-streak-milestone-3"]
        )
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 3)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 3)

        let neutralUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-cadence-momentum-brief",
            defaults: defaults
        )
        XCTAssertEqual(neutralUpdate.previousStreak, 3)
        XCTAssertEqual(neutralUpdate.nextStreak, 3)
        XCTAssertEqual(neutralUpdate.bestStreak, 3)
        XCTAssertNil(neutralUpdate.milestone)
        XCTAssertEqual(neutralUpdate.activityDetails, [])
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 3)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 3)

        let onboardingScorecardNeutralUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-onboarding-scorecard",
            defaults: defaults
        )
        XCTAssertEqual(onboardingScorecardNeutralUpdate.previousStreak, 3)
        XCTAssertEqual(onboardingScorecardNeutralUpdate.nextStreak, 3)
        XCTAssertEqual(onboardingScorecardNeutralUpdate.bestStreak, 3)
        XCTAssertNil(onboardingScorecardNeutralUpdate.milestone)
        XCTAssertEqual(onboardingScorecardNeutralUpdate.activityDetails, [])
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 3)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 3)

        let onboardingGapNeutralUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-onboarding-fill-gap",
            defaults: defaults
        )
        XCTAssertEqual(onboardingGapNeutralUpdate.previousStreak, 3)
        XCTAssertEqual(onboardingGapNeutralUpdate.nextStreak, 3)
        XCTAssertEqual(onboardingGapNeutralUpdate.bestStreak, 3)
        XCTAssertNil(onboardingGapNeutralUpdate.milestone)
        XCTAssertEqual(onboardingGapNeutralUpdate.activityDetails, [])
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 3)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 3)

        let onboardingDailyBriefNeutralUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-onboarding-daily-brief",
            defaults: defaults
        )
        XCTAssertEqual(onboardingDailyBriefNeutralUpdate.previousStreak, 3)
        XCTAssertEqual(onboardingDailyBriefNeutralUpdate.nextStreak, 3)
        XCTAssertEqual(onboardingDailyBriefNeutralUpdate.bestStreak, 3)
        XCTAssertNil(onboardingDailyBriefNeutralUpdate.milestone)
        XCTAssertEqual(onboardingDailyBriefNeutralUpdate.activityDetails, [])
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 3)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 3)

        let autopilotUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-cadence-autopilot-loop",
            defaults: defaults
        )
        XCTAssertEqual(autopilotUpdate.previousStreak, 3)
        XCTAssertEqual(autopilotUpdate.nextStreak, 4)
        XCTAssertEqual(autopilotUpdate.bestStreak, 4)
        XCTAssertNil(autopilotUpdate.milestone)
        XCTAssertEqual(autopilotUpdate.activityDetails, ["cadence-execution-kit-streak-4"])
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 4)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 4)

        let resetUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-next-move-copy-drafts",
            defaults: defaults
        )
        XCTAssertEqual(resetUpdate.previousStreak, 4)
        XCTAssertEqual(resetUpdate.nextStreak, 0)
        XCTAssertEqual(resetUpdate.bestStreak, 4)
        XCTAssertNil(resetUpdate.milestone)
        XCTAssertEqual(resetUpdate.activityDetails, ["cadence-execution-kit-streak-reset"])
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey), 0)
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey), 4)

        let noopUpdate = AppDelegate.updateCadenceExecutionKitCommandStreak(
            actionID: "run-fame-next-move-copy-drafts",
            defaults: defaults
        )
        XCTAssertEqual(noopUpdate.previousStreak, 0)
        XCTAssertEqual(noopUpdate.nextStreak, 0)
        XCTAssertEqual(noopUpdate.bestStreak, 4)
        XCTAssertNil(noopUpdate.milestone)
        XCTAssertEqual(noopUpdate.activityDetails, [])
    }

    func testCadenceExecutionKitCommandNextMilestoneTargetUsesExpectedThresholds() {
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandNextMilestoneTarget(after: 0), 3)
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandNextMilestoneTarget(after: 3), 5)
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandNextMilestoneTarget(after: 5), 10)
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandNextMilestoneTarget(after: 10), 15)
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandNextMilestoneTarget(after: 15), 20)
    }

    func testCadenceExecutionKitCommandDeltaFeedbackFormatsRunAndMilestoneCopy() throws {
        XCTAssertNil(
            AppDelegate.cadenceExecutionKitCommandDeltaFeedback(
                previousStreak: 3,
                nextStreak: 3,
                bestStreak: 7,
                milestone: nil
            )
        )
        XCTAssertNil(
            AppDelegate.cadenceExecutionKitCommandDeltaFeedback(
                previousStreak: 4,
                nextStreak: 0,
                bestStreak: 7,
                milestone: nil
            )
        )

        let runFeedback = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitCommandDeltaFeedback(
                previousStreak: 3,
                nextStreak: 4,
                bestStreak: 7,
                milestone: nil
            )
        )
        XCTAssertEqual(runFeedback.title, "Cadence +1 to x4")
        XCTAssertEqual(runFeedback.subtitle, "Next milestone x5 in 1 run · Best x7")
        XCTAssertEqual(runFeedback.statusSymbol, "bolt.fill")

        let milestoneFeedback = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitCommandDeltaFeedback(
                previousStreak: 4,
                nextStreak: 5,
                bestStreak: 7,
                milestone: 5
            )
        )
        XCTAssertEqual(milestoneFeedback.title, "Cadence +1 to x5")
        XCTAssertEqual(milestoneFeedback.subtitle, "Milestone x5 unlocked · Best x7")
        XCTAssertEqual(milestoneFeedback.statusSymbol, "rocket.fill")

        let trophyFeedback = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitCommandDeltaFeedback(
                previousStreak: 9,
                nextStreak: 10,
                bestStreak: 10,
                milestone: 10
            )
        )
        XCTAssertEqual(trophyFeedback.statusSymbol, "trophy.fill")
    }

    func testCadenceExecutionKitCommandStreakStatusTitleReflectsState() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandStreakStatusTitle(
                currentStreak: 4,
                bestStreak: 7
            ),
            "Cadence kit streak: x4 (best x7)."
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandStreakStatusTitle(
                currentStreak: 0,
                bestStreak: 5
            ),
            "Cadence kit streak: reset (best x5). Restart `Run Fame Next Move + Cadence Execution Kit`."
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandStreakStatusTitle(
                currentStreak: 0,
                bestStreak: 0
            ),
            "Cadence kit streak: not started. Run `Run Fame Next Move + Cadence Execution Kit`."
        )
    }

    func testCadenceExecutionKitCommandMenuMomentumTitleReflectsProgressAndReset() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMenuMomentumTitle(
                currentStreak: 4,
                bestStreak: 7
            ),
            "Cadence Momentum: x4 · Best x7 · Next x5 (1 run)"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMenuMomentumTitle(
                currentStreak: 0,
                bestStreak: 7
            ),
            "Cadence Momentum: reset · Best x7 · Next x3"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMenuMomentumTitle(
                currentStreak: 0,
                bestStreak: 0
            ),
            "Cadence Momentum: not started · Next x3"
        )
    }

    func testCadenceExecutionKitMomentumBriefActionSubtitleReflectsState() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumBriefActionSubtitle(
                currentStreak: 4,
                bestStreak: 7,
                nextMoveLabel: "Recovery Sprint"
            ),
            "Streak x4 · Next Recovery Sprint · save + copy brief"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumBriefActionSubtitle(
                currentStreak: 0,
                bestStreak: 7,
                nextMoveLabel: "Daily Checkpoint"
            ),
            "Streak reset (best x7) · Next Daily Checkpoint · rebuild now"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumBriefActionSubtitle(
                currentStreak: 0,
                bestStreak: 0,
                nextMoveLabel: "Save Snapshot"
            ),
            "No streak yet · Next Save Snapshot · start cadence now"
        )
    }

    func testCadenceExecutionKitMomentumShareLineActionSubtitleFormatsMomentumAndFallbacks() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumShareLineActionSubtitle(
                momentumTitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run)",
                nextMoveLabel: "Recovery Sprint"
            ),
            "Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Next Recovery Sprint · copy share line"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumShareLineActionSubtitle(
                momentumTitle: " ",
                nextMoveLabel: " "
            ),
            "Cadence momentum warming up · Next next move · copy share line"
        )
    }

    func testCadenceExecutionKitMomentumSharePackActionSubtitleFormatsMomentumAndFallbacks() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumSharePackActionSubtitle(
                momentumTitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run)",
                nextMoveLabel: "Recovery Sprint"
            ),
            "Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Next Recovery Sprint · short + standard + hype"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumSharePackActionSubtitle(
                momentumTitle: " ",
                nextMoveLabel: " "
            ),
            "Cadence momentum warming up · Next next move · short + standard + hype"
        )
    }

    func testCadenceExecutionKitMomentumShareLineFormatsSignalsAndFallbacks() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumShareLine(
                momentumTitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run)",
                nextMoveLabel: "Recovery Sprint",
                recoveryWinsTitle: "Recovery Wins 6/8 · x3",
                momentumDeltaTitle: "Fame Momentum Delta +2 wins"
            ),
            "Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint."
        )

        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumShareLine(
                momentumTitle: " ",
                nextMoveLabel: " ",
                recoveryWinsTitle: " ",
                momentumDeltaTitle: " "
            ),
            "Fame momentum: Cadence momentum warming up · Recovery wins warming up · Fame momentum delta warming up · Next next move."
        )
    }

    func testCadenceExecutionKitMomentumShareLineFromBriefParsesShareSectionAndFallbackLine() {
        let canonicalMarkdown = AppDelegate.cadenceExecutionKitMomentumBriefMarkdown(
            generatedAt: "2026-06-10 09:14",
            momentumTitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run)",
            streakStatusTitle: "Cadence kit streak: x4 (best x8).",
            nextMoveLabel: "Recovery Sprint",
            pulseStatusTitle: "Pulse risk: High · MUST SHIP in next 2h · Snapshot gap 1d",
            launchStatusTitle: "Launch status: T+18m · Urgency High (overdue by 18m) · Next T+18m: Ship launch update",
            scorecardStatusTitle: "Daily scorecard: Medium (Δ-2) · Next Run Daily Fame Checkpoint",
            priorityMove: "Build streak x4 toward x5. Run `Run Fame Next Move + Cadence Execution Kit` now (Recovery Sprint).",
            recoveryWinsTitle: "Recovery Wins 6/8 · x3",
            recoveryWinsSubtitle: "Direct route is winning 6/8 opens. Keep streak pressure high.",
            momentumDeltaTitle: "Fame Momentum Delta +2 wins",
            momentumDeltaSubtitle: "Direct wins climbed to 6/8 from 4/8. Keep compounding.",
            shareLine: "Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint."
        )

        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumShareLineFromBrief(canonicalMarkdown),
            "Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint."
        )

        let fallbackMarkdown = """
        # Other Brief

        Notes:
        - Keep pushing.
        - Fame momentum: Cadence Momentum: reset · Recovery wins warming up · Fame momentum delta warming up · Next Daily Checkpoint.
        """
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumShareLineFromBrief(fallbackMarkdown),
            "Fame momentum: Cadence Momentum: reset · Recovery wins warming up · Fame momentum delta warming up · Next Daily Checkpoint."
        )
        XCTAssertNil(
            AppDelegate.cadenceExecutionKitMomentumShareLineFromBrief(
                "# Empty\n\n- No share content here."
            )
        )
    }

    func testLatestCadenceMomentumShareLineCopyOutcomeHandlesMissingAndReadyStates() {
        XCTAssertEqual(
            AppDelegate.latestCadenceMomentumShareLineCopyOutcome(momentumBriefMarkdown: nil),
            .missingBrief
        )
        XCTAssertEqual(
            AppDelegate.latestCadenceMomentumShareLineCopyOutcome(
                momentumBriefMarkdown: "# Brief\n\n## Share Line\n- Paste this into updates."
            ),
            .missingShareLine
        )
        XCTAssertEqual(
            AppDelegate.latestCadenceMomentumShareLineCopyOutcome(
                momentumBriefMarkdown: """
                # Brief

                ## Share Line
                - Fame momentum: Cadence Momentum: x3 · Recovery Wins 5/8 · x2 · Fame Momentum Delta +1 wins · Next Recovery Sprint.
                """
            ),
            .ready(
                shareLine: "Fame momentum: Cadence Momentum: x3 · Recovery Wins 5/8 · x2 · Fame Momentum Delta +1 wins · Next Recovery Sprint."
            )
        )
    }

    func testCadenceExecutionKitShareLineArtifactMarkdownIncludesMetadataAndUsage() {
        let markdown = AppDelegate.cadenceExecutionKitShareLineArtifactMarkdown(
            generatedAt: "2026-06-10 09:14",
            shareLine: "Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint.",
            source: "Latest cadence momentum brief"
        )
        XCTAssertTrue(markdown.contains("# Fluid Reader Cadence Share Line"))
        XCTAssertTrue(markdown.contains("- Generated at: 2026-06-10 09:14"))
        XCTAssertTrue(markdown.contains("- Source: Latest cadence momentum brief"))
        XCTAssertTrue(markdown.contains("## Share Line"))
        XCTAssertTrue(markdown.contains("- Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint."))
        XCTAssertTrue(markdown.contains("## Usage"))
        XCTAssertTrue(markdown.contains("- Refresh with `Copy Cadence Share Line` whenever momentum changes."))
    }

    func testCadenceExecutionKitMomentumSharePackBuildsVariantsAndRespectsProvidedStandardLine() {
        let handoffDrafts = FameNextMoveHandoffDrafts(
            xDraft: "Ship the X proof loop now.",
            blueskyDraft: "Blue proof loop shipped today.",
            linkedInDraft: "LinkedIn proof loop and results.",
            checklistCommentDraft: "Checklist comment for handoff."
        )
        let pack = AppDelegate.cadenceExecutionKitMomentumSharePack(
            momentumTitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run)",
            nextMoveLabel: "Recovery Sprint",
            recoveryWinsTitle: "Recovery Wins 6/8 · x3",
            momentumDeltaTitle: "Fame Momentum Delta +2 wins",
            shareLine: "Fame momentum: canonical share line.",
            handoffDrafts: handoffDrafts
        )
        XCTAssertEqual(
            pack.shortLine,
            "Fame snapshot: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Fame Momentum Delta +2 wins · Next Recovery Sprint."
        )
        XCTAssertEqual(pack.standardLine, "Fame momentum: canonical share line.")
        XCTAssertEqual(
            pack.hypeLine,
            "Fame breakout mode: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) — Recovery Wins 6/8 · x3 — Fame Momentum Delta +2 wins. Shipping Recovery Sprint now."
        )
        XCTAssertEqual(
            pack.channelBlocks,
            [
                AppDelegate.CadenceMomentumSharePackChannelBlock(
                    channelTitle: "X",
                    primary: "Ship the X proof loop now.",
                    followup: "Fame snapshot: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Fame Momentum Delta +2 wins · Next Recovery Sprint."
                ),
                AppDelegate.CadenceMomentumSharePackChannelBlock(
                    channelTitle: "Bluesky",
                    primary: "Blue proof loop shipped today.",
                    followup: "Fame momentum: canonical share line."
                ),
                AppDelegate.CadenceMomentumSharePackChannelBlock(
                    channelTitle: "LinkedIn",
                    primary: "LinkedIn proof loop and results.",
                    followup: "Fame breakout mode: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) — Recovery Wins 6/8 · x3 — Fame Momentum Delta +2 wins. Shipping Recovery Sprint now."
                )
            ]
        )
        XCTAssertEqual(pack.checklistComment, "Checklist comment for handoff.")
        XCTAssertNil(pack.bestChannelTitle)
        XCTAssertNil(pack.bestChannelReason)
    }

    func testCadenceExecutionKitMomentumSharePackRanksPreferredChannelAndIncludesBestChannelNowMetadata() {
        let handoffDrafts = FameNextMoveHandoffDrafts(
            xDraft: "Ship the X proof loop now.",
            blueskyDraft: "Blue proof loop shipped today.",
            linkedInDraft: "LinkedIn proof loop and results.",
            checklistCommentDraft: "Checklist comment for handoff."
        )
        let pack = AppDelegate.cadenceExecutionKitMomentumSharePack(
            momentumTitle: "Cadence Momentum: x4",
            nextMoveLabel: "Recovery Sprint",
            recoveryWinsTitle: "Recovery Wins 6/8 · x3",
            momentumDeltaTitle: "Fame Momentum Delta +2 wins",
            shareLine: "Fame momentum: canonical share line.",
            handoffDrafts: handoffDrafts,
            preferredCadenceChannel: .linkedIn
        )

        XCTAssertEqual(pack.channelBlocks.first?.channelTitle, "LinkedIn")
        XCTAssertEqual(pack.bestChannelTitle, "LinkedIn")
        XCTAssertEqual(
            pack.bestChannelReason,
            "Cadence step starts on LinkedIn, so this channel is ranked first for the next publish window."
        )
    }

    func testCadenceExecutionKitSharePackSourceIncludesHandoffAndBestChannelContext() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitSharePackSource(
                usingLatestMomentumBrief: false,
                includesHandoffDrafts: false,
                preferredCadenceChannel: .linkedIn
            ),
            "Live momentum snapshot"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitSharePackSource(
                usingLatestMomentumBrief: true,
                includesHandoffDrafts: true,
                preferredCadenceChannel: nil
            ),
            "Latest cadence momentum brief + latest next-move handoff"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitSharePackSource(
                usingLatestMomentumBrief: true,
                includesHandoffDrafts: true,
                preferredCadenceChannel: .bluesky
            ),
            "Latest cadence momentum brief + latest next-move handoff · Best channel Bluesky"
        )
    }

    func testCadenceExecutionKitSharePackCopyActivityDetailTracksLatestAndBestChannel() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitSharePackCopyActivityDetail(
                usingLatestMomentumBrief: false,
                includesHandoffDrafts: false,
                preferredCadenceChannel: .x
            ),
            "copy-fame-cadence-share-pack"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitSharePackCopyActivityDetail(
                usingLatestMomentumBrief: true,
                includesHandoffDrafts: true,
                preferredCadenceChannel: nil
            ),
            "copy-fame-cadence-share-pack-latest-post-ready"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitSharePackCopyActivityDetail(
                usingLatestMomentumBrief: true,
                includesHandoffDrafts: true,
                preferredCadenceChannel: .linkedIn
            ),
            "copy-fame-cadence-share-pack-latest-post-ready-best-linkedin"
        )
    }

    func testCadenceExecutionKitSharePackArtifactMarkdownIncludesVariantsAndUsage() {
        let pack = AppDelegate.CadenceMomentumSharePack(
            shortLine: "Fame snapshot short line.",
            standardLine: "Fame momentum standard line.",
            hypeLine: "Fame breakout hype line.",
            channelBlocks: [
                AppDelegate.CadenceMomentumSharePackChannelBlock(
                    channelTitle: "X",
                    primary: "X primary block.",
                    followup: "X follow-up block."
                )
            ],
            checklistComment: "Checklist comment block.",
            bestChannelTitle: nil,
            bestChannelReason: nil
        )
        let markdown = AppDelegate.cadenceExecutionKitSharePackArtifactMarkdown(
            generatedAt: "2026-06-10 09:14",
            source: "Latest cadence momentum brief",
            pack: pack
        )
        XCTAssertTrue(markdown.contains("# Fluid Reader Cadence Share Pack"))
        XCTAssertTrue(markdown.contains("- Generated at: 2026-06-10 09:14"))
        XCTAssertTrue(markdown.contains("- Source: Latest cadence momentum brief"))
        XCTAssertTrue(markdown.contains("## Share Variants"))
        XCTAssertTrue(markdown.contains("- Short: Fame snapshot short line."))
        XCTAssertTrue(markdown.contains("- Standard: Fame momentum standard line."))
        XCTAssertTrue(markdown.contains("- Hype: Fame breakout hype line."))
        XCTAssertTrue(markdown.contains("## Post-Ready Blocks"))
        XCTAssertTrue(markdown.contains("### X"))
        XCTAssertTrue(markdown.contains("- Primary: X primary block."))
        XCTAssertTrue(markdown.contains("- Follow-up: X follow-up block."))
        XCTAssertTrue(markdown.contains("### Checklist Comment"))
        XCTAssertTrue(markdown.contains("- Checklist comment block."))
        XCTAssertTrue(markdown.contains("## Usage"))
        XCTAssertTrue(markdown.contains("- Post-Ready blocks pair each channel draft with a matching follow-up line."))
        XCTAssertTrue(markdown.contains("- Refresh with `Copy Cadence Share Pack` when momentum shifts."))
    }

    func testCadenceExecutionKitSharePackArtifactMarkdownIncludesBestChannelNowSectionWhenProvided() {
        let pack = AppDelegate.CadenceMomentumSharePack(
            shortLine: "Fame snapshot short line.",
            standardLine: "Fame momentum standard line.",
            hypeLine: "Fame breakout hype line.",
            channelBlocks: [
                AppDelegate.CadenceMomentumSharePackChannelBlock(
                    channelTitle: "Bluesky",
                    primary: "Publish Bluesky thread now.",
                    followup: "Follow-up thread in 15m."
                )
            ],
            checklistComment: nil,
            bestChannelTitle: "Bluesky",
            bestChannelReason: "Cadence step starts on Bluesky, so this channel is ranked first for the next publish window."
        )
        let markdown = AppDelegate.cadenceExecutionKitSharePackArtifactMarkdown(
            generatedAt: "2026-06-10 09:14",
            source: "Latest cadence momentum brief",
            pack: pack
        )

        XCTAssertTrue(markdown.contains("## Best Channel Now"))
        XCTAssertTrue(markdown.contains("- Bluesky: Cadence step starts on Bluesky, so this channel is ranked first for the next publish window."))
        XCTAssertTrue(markdown.contains("- Start draft: Publish Bluesky thread now."))
    }

    func testCadenceExecutionKitAutopilotLoopTitleAndSubtitleReflectState() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotLoopTitle(
                currentStreak: 4,
                bestStreak: 7
            ),
            "Run Cadence Autopilot Loop (x4)"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotLoopTitle(
                currentStreak: 0,
                bestStreak: 7
            ),
            "Run Cadence Recovery Loop"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotLoopTitle(
                currentStreak: 0,
                bestStreak: 0
            ),
            "Start Cadence Autopilot Loop"
        )

        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotLoopSubtitle(
                currentStreak: 4,
                bestStreak: 7,
                nextMoveLabel: "Recovery Sprint"
            ),
            "Next Recovery Sprint · push to x5 in 1 run"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotLoopSubtitle(
                currentStreak: 0,
                bestStreak: 7,
                nextMoveLabel: "Recovery Sprint"
            ),
            "Best x7 saved · restart with Recovery Sprint + execution kit"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotLoopSubtitle(
                currentStreak: 0,
                bestStreak: 0,
                nextMoveLabel: "Save Snapshot"
            ),
            "Run Save Snapshot + cadence execution kit + first post now"
        )
    }

    func testCadenceExecutionKitCelebrationDemoActionSubtitleReflectsState() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCelebrationDemoActionSubtitle(
                currentStreak: 4,
                bestStreak: 7,
                currentIntensityTitle: "Balanced"
            ),
            "Streak x4 · current Balanced · preview Calm/Balanced/Epic before x5"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCelebrationDemoActionSubtitle(
                currentStreak: 0,
                bestStreak: 7,
                currentIntensityTitle: "Epic"
            ),
            "Streak reset (best x7) · current Epic · preview Calm/Balanced/Epic"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCelebrationDemoActionSubtitle(
                currentStreak: 0,
                bestStreak: 0,
                currentIntensityTitle: "Calm"
            ),
            "No streak yet · current Calm · preview Calm/Balanced/Epic"
        )
    }

    func testFameOnboardingNudgePlanPhasesAdaptByDayAndStreak() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgePlan(
                day: 1,
                currentStreak: 0,
                bestStreak: 0
            ),
            AppDelegate.FameOnboardingNudgePlan(
                day: 1,
                phaseTitle: "Kickoff",
                focusLine: "Ship your first proof loop and lock your first streak point.",
                primaryCommandID: "run-fame-next-move-cadence-execution-kit",
                backupCommandID: "run-fame-cadence-celebration-demo"
            )
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgePlan(
                day: 4,
                currentStreak: 2,
                bestStreak: 3
            ),
            AppDelegate.FameOnboardingNudgePlan(
                day: 4,
                phaseTitle: "Momentum",
                focusLine: "Push the streak to the next milestone before the day closes.",
                primaryCommandID: "run-fame-cadence-autopilot-loop",
                backupCommandID: "run-fame-cadence-momentum-brief"
            )
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgePlan(
                day: 9,
                currentStreak: 0,
                bestStreak: 8
            ),
            AppDelegate.FameOnboardingNudgePlan(
                day: 7,
                phaseTitle: "Breakout",
                focusLine: "Package momentum into social proof and a launch-ready brief.",
                primaryCommandID: "run-fame-cadence-momentum-brief",
                backupCommandID: "run-fame-spotlight-pack"
            )
        )
    }

    func testFameOnboardingNudgeTitleSubtitleAndMarkdownIncludePlanCommands() {
        let plan = AppDelegate.FameOnboardingNudgePlan(
            day: 5,
            phaseTitle: "Breakout",
            focusLine: "Package momentum into social proof and a launch-ready brief.",
            primaryCommandID: "run-fame-cadence-momentum-brief",
            backupCommandID: "run-fame-spotlight-pack"
        )

        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgeActionTitle(plan),
            "Fame Onboarding Day 5: Breakout"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgeActionSubtitle(plan),
            "Day 5/7 · Package momentum into social proof and a launch-ready brief. · Start with Run Cadence Momentum Brief"
        )

        let markdown = AppDelegate.fameOnboardingNudgeMarkdown(
            plan,
            now: Date(timeIntervalSince1970: 1_717_977_600),
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )
        XCTAssertTrue(markdown.contains("# Fluid Reader Fame Onboarding Nudge"))
        XCTAssertTrue(markdown.contains("Day 5 of 7 · Breakout"))
        XCTAssertTrue(markdown.contains("Date: 2024-06-10"))
        XCTAssertTrue(markdown.contains("`Run Cadence Momentum Brief` (`run-fame-cadence-momentum-brief`)"))
        XCTAssertTrue(markdown.contains("`Run Fame Spotlight Pack` (`run-fame-spotlight-pack`)"))
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("run-fame-sprint-snapshot"))
    }

    func testFameOnboardingNudgeSubtitleAndMarkdownUseConfiguredWindowDays() {
        let plan = AppDelegate.fameOnboardingNudgePlan(
            day: 10,
            currentStreak: 2,
            bestStreak: 4,
            windowDays: 10
        )

        XCTAssertEqual(plan.day, 10)
        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgeActionSubtitle(plan, windowDays: 10),
            "Day 10/10 · Hit your first x5 cadence milestone this week. · Start with Run Cadence Autopilot Loop"
        )

        let markdown = AppDelegate.fameOnboardingNudgeMarkdown(
            plan,
            windowDays: 10,
            now: Date(timeIntervalSince1970: 1_717_977_600),
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )
        XCTAssertTrue(markdown.contains("Day 10 of 10 · Breakout"))
    }

    func testFameOnboardingNudgeSubtitleCanIncludeProgress() {
        let plan = AppDelegate.FameOnboardingNudgePlan(
            day: 3,
            phaseTitle: "Momentum",
            focusLine: "Push the streak to the next milestone before the day closes.",
            primaryCommandID: "run-fame-cadence-autopilot-loop",
            backupCommandID: "run-fame-cadence-momentum-brief"
        )

        XCTAssertEqual(
            AppDelegate.fameOnboardingNudgeActionSubtitle(
                plan,
                windowDays: 7,
                completedDays: 2
            ),
            "Day 3/7 · Progress 2/7 (5 left) · Push the streak to the next milestone before the day closes. · Start with Run Cadence Autopilot Loop"
        )
    }

    func testFameOnboardingNudgeMarkdownCanIncludeProgressSection() {
        let plan = AppDelegate.FameOnboardingNudgePlan(
            day: 4,
            phaseTitle: "Momentum",
            focusLine: "Push the streak to the next milestone before the day closes.",
            primaryCommandID: "run-fame-cadence-autopilot-loop",
            backupCommandID: "run-fame-cadence-momentum-brief"
        )

        let markdown = AppDelegate.fameOnboardingNudgeMarkdown(
            plan,
            windowDays: 7,
            completedDays: 3,
            now: Date(timeIntervalSince1970: 1_717_977_600),
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        XCTAssertTrue(markdown.contains("Progress:"))
        XCTAssertTrue(markdown.contains("Completed onboarding days: 3/7"))
        XCTAssertTrue(markdown.contains("Remaining onboarding days: 4"))
    }

    func testFameOnboardingScorecardTitleSubtitleAndPaceCanReflectProgress() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingScorecardActionTitle(day: 3, windowDays: 7),
            "Run First-Week Fame Scorecard (Day 3/7)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingScorecardActionSubtitle(
                day: 3,
                windowDays: 7,
                completedDays: 2,
                recommendedCommandID: "run-fame-cadence-autopilot-loop"
            ),
            "Day 3/7 · Progress 2/7 (5 left) · Next Run Cadence Autopilot Loop"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingScorecardPaceLine(
                day: 3,
                windowDays: 7,
                completedDays: 2
            ),
            "Behind by 1 day vs day-3 target."
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingScorecardPaceLine(
                day: 3,
                windowDays: 7,
                completedDays: 4
            ),
            "Ahead by 1 day vs day-3 target."
        )
    }

    func testFameOnboardingScorecardActionEligibilityGatesFollowOnboardingAndCadenceState() {
        XCTAssertTrue(
            AppDelegate.isFameOnboardingScorecardActionEligible(
                fameOnboardingEnabled: true,
                cadenceBestStreak: 4,
                onboardingDay: 3,
                completedDays: 2,
                onboardingWindowDays: 7
            )
        )
        XCTAssertFalse(
            AppDelegate.isFameOnboardingScorecardActionEligible(
                fameOnboardingEnabled: false,
                cadenceBestStreak: 4,
                onboardingDay: 3,
                completedDays: 2,
                onboardingWindowDays: 7
            )
        )
        XCTAssertFalse(
            AppDelegate.isFameOnboardingScorecardActionEligible(
                fameOnboardingEnabled: true,
                cadenceBestStreak: 10,
                onboardingDay: 3,
                completedDays: 2,
                onboardingWindowDays: 7
            )
        )
        XCTAssertFalse(
            AppDelegate.isFameOnboardingScorecardActionEligible(
                fameOnboardingEnabled: true,
                cadenceBestStreak: 4,
                onboardingDay: 8,
                completedDays: 2,
                onboardingWindowDays: 7
            )
        )
        XCTAssertFalse(
            AppDelegate.isFameOnboardingScorecardActionEligible(
                fameOnboardingEnabled: true,
                cadenceBestStreak: 4,
                onboardingDay: 3,
                completedDays: 7,
                onboardingWindowDays: 7
            )
        )
    }

    func testFameOnboardingSuiteArtifactRecencyTitleFormatsKnownBands() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: nil),
            "freshness unknown"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: 0),
            "updated just now"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: 18),
            "updated 18m ago"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: 90),
            "updated 1h ago"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: 2_940),
            "updated 2d ago"
        )
    }

    func testFameOnboardingSuiteActionSubtitleFormatsEmptyPartialAndFullStates() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteActionSubtitle(
                availableArtifacts: 0,
                totalArtifacts: 3,
                newestArtifactAgeMinutes: nil
            ),
            "No saved artifacts yet · Run first-week daily brief"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteActionSubtitle(
                availableArtifacts: 2,
                totalArtifacts: 3,
                newestArtifactAgeMinutes: 78
            ),
            "2/3 artifacts ready · updated 1h ago · Fill gaps with daily brief"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingSuiteActionSubtitle(
                availableArtifacts: 3,
                totalArtifacts: 3,
                newestArtifactAgeMinutes: 9
            ),
            "3/3 artifacts ready · updated 9m ago"
        )
    }

    func testLaunchControlHubActionSubtitleFormatsEmptyPartialAndFullStates() {
        XCTAssertEqual(
            AppDelegate.launchControlHubActionSubtitle(
                availableArtifacts: 0,
                totalArtifacts: 4,
                newestArtifactAgeMinutes: nil
            ),
            "No saved launch artifacts yet · Run Launch Control Brief"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubActionSubtitle(
                availableArtifacts: 2,
                totalArtifacts: 4,
                newestArtifactAgeMinutes: 95
            ),
            "2/4 launch artifacts ready · updated 1h ago · Fill gaps with launch rescue burst"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubActionSubtitle(
                availableArtifacts: 4,
                totalArtifacts: 4,
                newestArtifactAgeMinutes: 6
            ),
            "4/4 launch artifacts ready · updated 6m ago"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubActionSubtitle(
                availableArtifacts: 0,
                totalArtifacts: 4,
                newestArtifactAgeMinutes: nil,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "No saved launch artifacts yet · Run Launch Control Brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubActionSubtitle(
                availableArtifacts: 2,
                totalArtifacts: 4,
                newestArtifactAgeMinutes: 95,
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "2/4 launch artifacts ready · updated 1h ago · Fill gaps with launch rescue burst"
        )
    }

    func testLaunchControlHubMenuStatusHelpersAppendRouteAndSelfHealContext() {
        XCTAssertEqual(
            AppDelegate.launchControlHubRunMenuStatusTitle(
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Run Launch Control Hub"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubRunMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Run Launch Control Hub · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubOpenMenuStatusTitle(
                routeBadge: "Route Brief",
                selfHealAttentionBadge: nil
            ),
            "Open Launch Control Hub · Route Brief"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubRunMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Generate burst + countdown + brief + snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubOpenMenuStatusToolTip(
                availableArtifacts: 0,
                totalArtifacts: 4,
                newestArtifactAgeMinutes: nil,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "No saved launch artifacts yet · Run Launch Control Brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefRunMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Run Launch Control Brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefOpenMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open Latest Launch Control Brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefCopyMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Copy Launch Control Brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefRunMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Refresh launch countdown + save + copy launch control brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueSnapshotOpenMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open Latest Launch Rescue Snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueSnapshotOpenMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open latest launch rescue snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueSnapshotCopyMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Copy auto trigger + follow-up route decision + self-heal + scoreboard + coach + momentum · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownRunMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Run Fame Launch Countdown · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownRunMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Generate real-time launch step tracker · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownOpenMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open Latest Launch Countdown · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownOpenMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open latest launch countdown · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstOpenMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open Latest Launch Rescue Burst · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstRunMenuStatusTitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Run Launch Rescue Burst · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstRunMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Generate launch countdown + next-move handoff + recovery checklist · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstOpenMenuStatusToolTip(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Open latest launch rescue burst · Route Burst · Self-Heal Missing x1"
        )
    }

    func testLaunchRunPromptHelpersAppendRouteAndSelfHealContext() {
        XCTAssertEqual(
            AppDelegate.launchCountdownRunMissingScriptPrompt(
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Run launch day script first."
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownRunMissingScriptPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Run launch day script first · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownRunReadyPrompt(
                routeBadge: "Route Brief",
                selfHealAttentionBadge: nil
            ),
            "Launch countdown ready · Route Brief."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstRunReadyPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Launch rescue burst ready · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoSavedPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Launch rescue burst auto-saved. Open latest launch rescue burst · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoStatusDisabledPrompt(
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Launch rescue auto-burst is off. Enable it in Settings."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoStatusDisabledPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Launch rescue auto-burst is off. Enable it in Settings · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoStatusDisabledPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1",
                followupRouteDecisionTraceLine: "  Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack.  "
            ),
            "Launch rescue auto-burst is off. Enable it in Settings · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusDisabledPrompt(
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Auto bundle is off. Enable it in Settings."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusDisabledPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Auto bundle is off. Enable it in Settings · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusDisabledPrompt(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1",
                followupRouteDecisionTraceLine: "  Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack.  "
            ),
            "Auto bundle is off. Enable it in Settings · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoStatusCoolingDownMissingPrompt(
                minutesRemaining: 9,
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Auto rescue cooling down (9m). Run launch rescue burst first."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoStatusCoolingDownOpenedPrompt(
                minutesRemaining: 9,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Auto rescue cooling down (9m). Opened latest launch rescue burst · Route Burst · Self-Heal Missing x1."
        )
    }

    func testLaunchRescueFollowupPromptContextFragmentFormatsRouteAndSelfHealSignals() {
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupPromptContextFragment(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x2"
            ),
            "Route Burst · Self-Heal Missing x2"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupPromptContextFragment(
                routeBadge: "Route Brief",
                selfHealAttentionBadge: nil
            ),
            "Route Brief"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupPromptContextFragment(
                routeBadge: nil,
                selfHealAttentionBadge: "Self-Heal Stale x1"
            ),
            "Self-Heal Stale x1"
        )
        XCTAssertNil(
            AppDelegate.launchRescueFollowupPromptContextFragment(
                routeBadge: "   ",
                selfHealAttentionBadge: "\n"
            )
        )
    }

    func testLaunchControlPromptWithLaunchRescueContextAppendsSignalsAndPreservesPunctuation() {
        XCTAssertEqual(
            AppDelegate.launchControlPromptWithLaunchRescueContext(
                "Launch control hub ready.",
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1",
                followupRouteDecisionTraceLine: "  Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack.  "
            ),
            "Launch control hub ready · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(
            AppDelegate.launchControlPromptWithLaunchRescueContext(
                "Run Launch Control Brief first",
                routeBadge: "Route Brief",
                selfHealAttentionBadge: nil
            ),
            "Run Launch Control Brief first · Route Brief."
        )
        XCTAssertEqual(
            AppDelegate.launchControlPromptWithLaunchRescueContext(
                "Opened launch control hub.",
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Opened launch control hub."
        )
        XCTAssertEqual(
            AppDelegate.launchControlPromptWithLaunchRescueContext(
                "   ",
                routeBadge: "Route Brief",
                selfHealAttentionBadge: nil
            ),
            "Route Brief"
        )
        XCTAssertEqual(
            AppDelegate.launchControlPromptWithLaunchRescueContext(
                "  ",
                routeBadge: nil,
                selfHealAttentionBadge: nil,
                followupRouteDecisionTraceLine: "  Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack.  "
            ),
            "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
    }

    func testLaunchControlHubRunActivityDetailFormatsManualAndAutoSources() {
        XCTAssertEqual(
            AppDelegate.launchControlHubRunActivityDetail(
                source: "manual",
                readyArtifactCount: 4,
                totalArtifactCount: 4
            ),
            "run-fame-launch-control-hub-4-of-4"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubRunActivityDetail(
                source: "  auto-pressure-streak-3  ",
                readyArtifactCount: 2,
                totalArtifactCount: 4
            ),
            "run-fame-launch-control-hub-auto-pressure-streak-3-2-of-4"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubRunActivityDetail(
                source: "   ",
                readyArtifactCount: 9,
                totalArtifactCount: 4
            ),
            "run-fame-launch-control-hub-4-of-4"
        )
    }

    func testLaunchControlHubRunSummaryMarkdownIncludesRouteDecisionAndSelfHealStatus() {
        let markdown = AppDelegate.launchControlHubRunSummaryMarkdown(
            generatedAt: "2026-06-12 05:55",
            rescueBurstCompleted: false,
            readyArtifactCount: 9,
            totalArtifactCount: 4,
            launchRescueFollowupRouteDecisionStatusTitle:
                "Launch Rescue Auto Follow-up Route Decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack · Self-Heal Missing x1.",
            launchRescueAutoSelfHealStatusTitle:
                "Launch Rescue Auto Self-Heal: Last matching check is stale (22m ago) · Route: Run Fame Next Move + Copy Draft Pack · Reason: Urgency High escalation.",
            launchControlBriefArtifactName: "fame-launch-control-brief-2026-06-12-0555.md",
            launchRescueSnapshotArtifactName: "fame-launch-rescue-snapshot-2026-06-12-0555.md",
            launchRescueBurstArtifactName: "Not saved",
            launchCountdownArtifactName: "fame-launch-countdown-2026-06-12-0555.md",
            missingArtifactNames: ["launch rescue burst"]
        )

        XCTAssertTrue(markdown.contains("- Artifacts ready: 4/4"))
        XCTAssertTrue(
            markdown.contains(
                "- Launch Rescue Auto Follow-up Route Decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack · Self-Heal Missing x1."
            )
        )
        XCTAssertTrue(
            markdown.contains(
                "- Launch Rescue Auto Self-Heal: Last matching check is stale (22m ago) · Route: Run Fame Next Move + Copy Draft Pack · Reason: Urgency High escalation."
            )
        )
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("- launch rescue burst"))
    }

    func testLaunchControlHubRunSummaryMarkdownShowsNoneWhenMissingArtifactsIsEmpty() {
        let markdown = AppDelegate.launchControlHubRunSummaryMarkdown(
            generatedAt: "2026-06-12 06:10",
            rescueBurstCompleted: true,
            readyArtifactCount: 4,
            totalArtifactCount: 4,
            launchRescueFollowupRouteDecisionStatusTitle:
                "Launch Rescue Auto Follow-up Route Decision: Default route Run Launch Control Brief.",
            launchRescueAutoSelfHealStatusTitle:
                "Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks.",
            launchControlBriefArtifactName: "brief.md",
            launchRescueSnapshotArtifactName: "snapshot.md",
            launchRescueBurstArtifactName: "burst.md",
            launchCountdownArtifactName: "countdown.md",
            missingArtifactNames: []
        )

        XCTAssertTrue(markdown.contains("## Missing\n- None"))
        XCTAssertTrue(markdown.contains("- Rescue burst run: Completed."))
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testAutoEscalationOpsBundleSummaryMarkdownIncludesStatusShortcutHintAcrossStates() {
        let disabledMarkdown = AppDelegate.autoEscalationOpsBundleSummaryDisabledMarkdown()
        XCTAssertTrue(disabledMarkdown.contains("## Ops Bundle Auto Follow-up"))
        XCTAssertTrue(disabledMarkdown.contains("Auto ops bundle is disabled in Settings."))
        XCTAssertTrue(disabledMarkdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))

        let cooldownMarkdown = AppDelegate.autoEscalationOpsBundleSummaryCooldownMarkdown(
            remainingMinutes: 9
        )
        XCTAssertTrue(cooldownMarkdown.contains("Cooldown active: auto ops bundle ran recently."))
        XCTAssertTrue(cooldownMarkdown.contains("Next auto run in about 9 min."))
        XCTAssertTrue(cooldownMarkdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))

        let readyMarkdown = AppDelegate.autoEscalationOpsBundleSummaryReadyMarkdown(
            commandCenterArtifactName: "fame-command-center-2026-06-12-0900.md",
            checkpointArtifactName: "fame-daily-checkpoint-2026-06-12-0900.md",
            riskTimelineArtifactName: "fame-risk-timeline-2026-06-12-0900.md",
            pulseNudgeArtifactName: "fame-pulse-nudge-2026-06-12-0900.md"
        )
        XCTAssertTrue(readyMarkdown.contains("Command center saved: fame-command-center-2026-06-12-0900.md"))
        XCTAssertTrue(readyMarkdown.contains("Daily checkpoint saved: fame-daily-checkpoint-2026-06-12-0900.md"))
        XCTAssertTrue(readyMarkdown.contains("Risk timeline saved: fame-risk-timeline-2026-06-12-0900.md"))
        XCTAssertTrue(readyMarkdown.contains("Pulse nudge saved: fame-pulse-nudge-2026-06-12-0900.md"))
        XCTAssertTrue(
            readyMarkdown.contains(
                "Shortcuts: `open-latest-command-center`, `open-latest-daily-checkpoint`, `open-latest-risk-timeline`, `open-latest-pulse-nudge`."
            )
        )
        XCTAssertTrue(readyMarkdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testFameOpsBundleSummaryMarkdownIncludesStatusShortcutHintAndReopenCommands() {
        let markdown = AppDelegate.fameOpsBundleSummaryMarkdown(
            bundleStamp: "2026-06-12-0900",
            commandCenterArtifactName: "fame-command-center-2026-06-12-0900.md",
            checkpointArtifactName: "fame-daily-checkpoint-2026-06-12-0900.md",
            riskTimelineArtifactName: "fame-risk-timeline-2026-06-12-0900.md",
            pulseNudgeArtifactName: "fame-pulse-nudge-2026-06-12-0900.md"
        )

        XCTAssertTrue(markdown.contains("# Fluid Reader Fame Ops Bundle"))
        XCTAssertTrue(markdown.contains("Bundle stamp: 2026-06-12-0900"))
        XCTAssertTrue(markdown.contains("Command center: fame-command-center-2026-06-12-0900.md"))
        XCTAssertTrue(markdown.contains("Daily checkpoint: fame-daily-checkpoint-2026-06-12-0900.md"))
        XCTAssertTrue(markdown.contains("Risk timeline: fame-risk-timeline-2026-06-12-0900.md"))
        XCTAssertTrue(markdown.contains("Pulse nudge: fame-pulse-nudge-2026-06-12-0900.md"))
        XCTAssertTrue(markdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("`open-latest-command-center`"))
        XCTAssertTrue(markdown.contains("`open-latest-pulse-nudge`"))
    }

    func testLaunchRescueBurstRunSummaryMarkdownIncludesStatusShortcutHintAndDraftFallback() {
        let markdown = AppDelegate.launchRescueBurstRunSummaryMarkdown(
            launchStatusTitle: "Urgency High (overdue by 18m)",
            launchStatusSubtitle: "Next: T+18m: Push replies",
            launchThresholdAlertsStatusTitle: "Threshold Alerts: Snoozed 20m",
            snoozeReminderActionSummary: "Extend 20m",
            launchScriptArtifactName: "fame-launch-day-script-2026-06-12-0900.md",
            launchCountdownArtifactName: "fame-launch-countdown-2026-06-12-0900.md",
            nextMoveCommandTitle: "Run Fame Next Move + Copy Draft Pack",
            nextMoveHandoffArtifactName: "fame-next-move-handoff-2026-06-12-0900.md",
            nextMoveDraftPackArtifactName: nil,
            recoveryChecklistArtifactName: "fame-recovery-checklist-2026-06-12-0900.md",
            draftPackReady: false,
            clipboardActionSummary: "Skipped (auto mode preserves clipboard)"
        )

        XCTAssertTrue(markdown.contains("# Fluid Reader Launch Rescue Burst"))
        XCTAssertTrue(markdown.contains("- Launch threshold alerts: Threshold Alerts: Snoozed 20m"))
        XCTAssertTrue(markdown.contains("- Snooze reminder action: Extend 20m"))
        XCTAssertTrue(markdown.contains("- Next move draft pack: Not saved (handoff fallback)"))
        XCTAssertTrue(markdown.contains("- Draft pack ready: No"))
        XCTAssertTrue(markdown.contains("Open latest launch countdown and ship the `Next action now` step."))
        XCTAssertTrue(markdown.contains("Open latest recovery checklist and close one blocker in 15 minutes."))
        XCTAssertTrue(markdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testAutoRecoveryProofPackSummaryMarkdownIncludesStatusShortcutHintAndFallback() {
        let markdown = AppDelegate.autoRecoveryProofPackSummaryMarkdown(
            proofPackArtifactName: "  "
        )

        XCTAssertTrue(markdown.contains("Recovery proof pack saved: Unknown"))
        XCTAssertTrue(markdown.contains("Open Latest Recovery Proof Pack"))
        XCTAssertTrue(markdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testAutoRecoveryChecklistSummaryMarkdownIncludesProofPackAndStatusShortcutHint() {
        let proofPackSummary = AppDelegate.autoRecoveryProofPackSummaryMarkdown(
            proofPackArtifactName: "fame-recovery-proof-pack-2026-06-12-1000.md"
        )
        let markdown = AppDelegate.autoRecoveryChecklistSummaryMarkdown(
            checklistArtifactName: "fame-recovery-checklist-2026-06-12-1000.md",
            proofPackSummaryMarkdown: proofPackSummary
        )

        XCTAssertTrue(markdown.contains("## 2h Auto Follow-up"))
        XCTAssertTrue(markdown.contains("Recovery checklist saved: fame-recovery-checklist-2026-06-12-1000.md"))
        XCTAssertTrue(markdown.contains("Recovery proof pack saved: fame-recovery-proof-pack-2026-06-12-1000.md"))
        XCTAssertTrue(markdown.contains("Open Latest Recovery Checklist"))
        XCTAssertTrue(markdown.contains("Open Latest Recovery Proof Pack"))
        XCTAssertTrue(markdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testLatestRecoverySprintSummaryMarkdownIncludesStatusShortcutHintAndFallback() {
        let markdown = AppDelegate.latestRecoverySprintSummaryMarkdown(
            recoverySprintArtifactName: ""
        )

        XCTAssertTrue(markdown.contains("## Latest Recovery Sprint"))
        XCTAssertTrue(markdown.contains("Latest file: Unknown"))
        XCTAssertTrue(markdown.contains("Open Latest Recovery Sprint"))
        XCTAssertTrue(markdown.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testRecoverySprintRunSummaryMarkdownAppendsChecklistSummaryWhenPresent() {
        let checklistSummary = AppDelegate.autoRecoveryChecklistSummaryMarkdown(
            checklistArtifactName: "fame-recovery-checklist-2026-06-12-1100.md",
            proofPackSummaryMarkdown: AppDelegate.autoRecoveryProofPackSummaryMarkdown(
                proofPackArtifactName: "fame-recovery-proof-pack-2026-06-12-1100.md"
            )
        )
        let markdown = AppDelegate.recoverySprintRunSummaryMarkdown(
            recoveryMarkdown: "# Recovery Sprint\n\nShip one unblock now.",
            checklistAutoFollowupSummaryMarkdown: checklistSummary
        )

        XCTAssertTrue(markdown.contains("# Recovery Sprint"))
        XCTAssertTrue(markdown.contains("## 2h Auto Follow-up"))
        XCTAssertTrue(markdown.contains("Recovery checklist saved: fame-recovery-checklist-2026-06-12-1100.md"))
        XCTAssertTrue(markdown.contains("Recovery proof pack saved: fame-recovery-proof-pack-2026-06-12-1100.md"))
    }

    func testRecoveryChecklistRunSummaryMarkdownAppendsProofPackSectionWhenPresent() {
        let proofPackSummary = AppDelegate.autoRecoveryProofPackSummaryMarkdown(
            proofPackArtifactName: "fame-recovery-proof-pack-2026-06-12-1200.md"
        )
        let markdown = AppDelegate.recoveryChecklistRunSummaryMarkdown(
            checklistMarkdown: "# Recovery Checklist\n\nClose one blocker.",
            proofPackAutoFollowupSummaryMarkdown: proofPackSummary
        )

        XCTAssertTrue(markdown.contains("# Recovery Checklist"))
        XCTAssertTrue(markdown.contains("## Proof Pack Auto Follow-up"))
        XCTAssertTrue(markdown.contains("Recovery proof pack saved: fame-recovery-proof-pack-2026-06-12-1200.md"))
        XCTAssertTrue(markdown.contains("Open Latest Recovery Proof Pack"))
    }

    func testRecoveryChecklistRunSummaryMarkdownFallsBackToProofSectionWhenChecklistIsEmpty() {
        let proofPackSummary = AppDelegate.autoRecoveryProofPackSummaryMarkdown(
            proofPackArtifactName: "fame-recovery-proof-pack-2026-06-12-1300.md"
        )
        let markdown = AppDelegate.recoveryChecklistRunSummaryMarkdown(
            checklistMarkdown: "  ",
            proofPackAutoFollowupSummaryMarkdown: proofPackSummary
        )

        XCTAssertTrue(markdown.hasPrefix("## Proof Pack Auto Follow-up"))
        XCTAssertTrue(markdown.contains("Recovery proof pack saved: fame-recovery-proof-pack-2026-06-12-1300.md"))
    }

    func testFameOnboardingGapActionTitleAndSubtitleUseMissingArtifactsAndRecency() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapActionTitle(
                recommendedCommandID: "run-fame-onboarding-daily-brief"
            ),
            "Fill Onboarding Gap: Daily Brief"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapActionTitle(
                recommendedCommandID: "run-fame-onboarding-scorecard"
            ),
            "Fill Onboarding Gap: Fame Scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapActionTitle(
                recommendedCommandID: "run-fame-onboarding-nudge"
            ),
            "Fill Onboarding Gap: Onboarding Nudge"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapActionSubtitle(
                missingArtifactNames: ["daily brief", "scorecard"],
                day: 3,
                windowDays: 7,
                newestArtifactAgeMinutes: 87,
                recommendedCommandID: "run-fame-onboarding-daily-brief"
            ),
            "Missing 2/3: daily brief, scorecard · Day 3/7 · updated 1h ago · Next Run First-Week Daily Brief"
        )
    }

    func testFameOnboardingGapMenuTitleReflectsMissingProgressAndRecommendation() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapMenuTitle(
                recommendedCommandID: "run-fame-onboarding-daily-brief",
                missingArtifacts: 2
            ),
            "Fill Onboarding Gap: Daily Brief (2/3 missing)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapMenuTitle(
                recommendedCommandID: "run-fame-onboarding-scorecard",
                missingArtifacts: 1
            ),
            "Fill Onboarding Gap: Fame Scorecard (1/3 missing)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapMenuTitle(
                recommendedCommandID: "run-fame-onboarding-nudge",
                missingArtifacts: 1
            ),
            "Fill Onboarding Gap: Onboarding Nudge (1/3 missing)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapMenuTitle(
                recommendedCommandID: nil,
                missingArtifacts: 0
            ),
            "Fill Onboarding Gap (3/3 ready)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapMenuTitle(
                recommendedCommandID: "run-fame-onboarding-daily-brief",
                missingArtifacts: 7,
                missingArtifactNames: [" daily brief ", "scorecard", "", "Daily Brief", "nudge", "bonus"]
            ),
            "Fill Onboarding Gap: Daily Brief (3/3 missing: daily brief, scorecard, nudge)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapMenuTitle(
                recommendedCommandID: "run-fame-onboarding-scorecard",
                missingArtifacts: 1,
                missingArtifactNames: ["scorecard", "daily brief"]
            ),
            "Fill Onboarding Gap: Fame Scorecard (1/3 missing: scorecard)"
        )
    }

    func testFameOnboardingRecoveryMenuHintFormatsOpenAndClosedMomentumStates() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMenuHint(
                isFreshRecovery: true,
                followupCommandID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1
            ),
            "Recovery 1 artifact left · next Run First-Week Fame Scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMenuHint(
                isFreshRecovery: true,
                followupCommandID: nil,
                remainingArtifacts: 2
            ),
            "Recovery 2 artifacts left"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMenuHint(
                isFreshRecovery: true,
                followupCommandID: "run-fame-onboarding-nudge",
                remainingArtifacts: 0
            ),
            "Recovery gap closed · next Run Fame Onboarding Nudge"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryMenuHint(
                isFreshRecovery: false,
                followupCommandID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1
            ),
            nil
        )
    }

    func testFameOnboardingRecoveryQuickRunActionIDPrefersFollowupAndFallback() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryQuickRunActionID(
                isFreshRecovery: true,
                followupCommandID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 2,
                enabledActionIDs: [
                    "run-fame-onboarding-fill-gap",
                    "run-fame-onboarding-scorecard",
                    "run-fame-onboarding-daily-brief"
                ]
            ),
            "run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryQuickRunActionID(
                isFreshRecovery: true,
                followupCommandID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 2,
                enabledActionIDs: [
                    "run-fame-onboarding-daily-brief",
                    "run-fame-onboarding-nudge"
                ]
            ),
            "run-fame-onboarding-daily-brief"
        )
        XCTAssertNil(
            AppDelegate.fameOnboardingRecoveryQuickRunActionID(
                isFreshRecovery: false,
                followupCommandID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1,
                enabledActionIDs: ["run-fame-onboarding-scorecard"]
            )
        )
    }

    func testFameOnboardingRecoveryQuickRunMenuTitleReflectsState() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: true,
                actionID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 2
            ),
            "Run Recovery Next: Run First-Week Fame Scorecard (2 artifacts left)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: true,
                actionID: "run-fame-onboarding-nudge",
                remainingArtifacts: 0
            ),
            "Run Recovery Next: Run Fame Onboarding Nudge (Gap closed)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: true,
                actionID: nil,
                remainingArtifacts: 1
            ),
            "Run Recovery Next Step (Unavailable)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: false,
                actionID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1
            ),
            "Run Recovery Next Step (No active recovery)"
        )
    }

    func testFameMenuTitleAppendsRecoveryHintOnlyWhenPresent() {
        XCTAssertEqual(
            AppDelegate.fameMenuTitle(
                baseTitle: "Fill Onboarding Gap: Daily Brief (1/3 missing)",
                appendedHint: "Recovery 1 artifact left · next Run First-Week Fame Scorecard"
            ),
            "Fill Onboarding Gap: Daily Brief (1/3 missing) · Recovery 1 artifact left · next Run First-Week Fame Scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameMenuTitle(
                baseTitle: "Run First-Week Fame Scorecard (Day 3/7 · 2/7)",
                appendedHint: "   "
            ),
            "Run First-Week Fame Scorecard (Day 3/7 · 2/7)"
        )
    }

    func testFameOnboardingGapPulseMessageIncludesMissingArtifactsAndNextCommand() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapPulseMessage(
                missingArtifacts: 2,
                missingArtifactNames: ["daily brief", "scorecard"],
                recommendedCommandID: "run-fame-onboarding-daily-brief"
            ),
            "Onboarding gap spotted (2/3 missing: daily brief, scorecard). Next: Run First-Week Daily Brief."
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapPulseMessage(
                missingArtifacts: 1,
                missingArtifactNames: [],
                recommendedCommandID: "run-fame-onboarding-nudge"
            ),
            "Onboarding gap spotted (1/3 missing: artifacts). Next: Run Fame Onboarding Nudge."
        )
    }

    func testFameOnboardingGapPulseMessageNormalizesMissingArtifactsAndClampsCount() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapPulseMessage(
                missingArtifacts: 7,
                missingArtifactNames: [" daily brief ", "scorecard", "", "Daily Brief", "nudge", "bonus"],
                recommendedCommandID: "run-fame-onboarding-daily-brief"
            ),
            "Onboarding gap spotted (3/3 missing: daily brief, scorecard, nudge). Next: Run First-Week Daily Brief."
        )
    }

    func testFameOnboardingGapPulseActivityDetailIncludesMissingArtifactToken() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapPulseActivityDetail(
                missingArtifacts: 7,
                missingArtifactNames: [" daily brief ", "scorecard", "", "Daily Brief", "nudge", "bonus"],
                recommendedCommandID: "run-fame-onboarding-daily-brief"
            ),
            "fame-onboarding-gap-pulse-3-of-3-daily-brief+scorecard+nudge-run-fame-onboarding-daily-brief"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapPulseActivityDetail(
                missingArtifacts: 1,
                missingArtifactNames: [" ", "\n"],
                recommendedCommandID: "run-fame-onboarding-nudge"
            ),
            "fame-onboarding-gap-pulse-1-of-3-artifacts-run-fame-onboarding-nudge"
        )
    }

    func testFameOnboardingGapRecoveryMessageCoversPartialAndCompleteRecovery() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecoveryMessage(
                previousMissingArtifacts: 3,
                nextMissingArtifacts: 1,
                nextMissingArtifactNames: ["scorecard", "nudge"],
                recommendedCommandID: "run-fame-onboarding-scorecard"
            ),
            "Onboarding gap improved (3->1/3 missing: scorecard). Next: Run First-Week Fame Scorecard."
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecoveryMessage(
                previousMissingArtifacts: 2,
                nextMissingArtifacts: 0,
                nextMissingArtifactNames: [],
                recommendedCommandID: nil
            ),
            "Onboarding gap closed (3/3 ready). Great recovery."
        )
    }

    func testFameOnboardingGapRecoveryActivityDetailIncludesProgressAndRoute() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecoveryActivityDetail(
                previousMissingArtifacts: 3,
                nextMissingArtifacts: 1,
                nextMissingArtifactNames: ["scorecard", "nudge"],
                recommendedCommandID: "run-fame-onboarding-scorecard"
            ),
            "fame-onboarding-gap-recovery-3-to-1-of-3-scorecard-run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecoveryActivityDetail(
                previousMissingArtifacts: 2,
                nextMissingArtifacts: 0,
                nextMissingArtifactNames: [],
                recommendedCommandID: nil
            ),
            "fame-onboarding-gap-recovery-2-to-0-of-3-all-ready-all-ready"
        )
    }

    func testFameOnboardingGapRecommendedCommandIDPrioritizesMissingArtifacts() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecommendedCommandID(
                hasDailyBrief: false,
                hasScorecard: false,
                hasNudge: false
            ),
            "run-fame-onboarding-daily-brief"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecommendedCommandID(
                hasDailyBrief: true,
                hasScorecard: false,
                hasNudge: false
            ),
            "run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingGapRecommendedCommandID(
                hasDailyBrief: true,
                hasScorecard: true,
                hasNudge: false
            ),
            "run-fame-onboarding-nudge"
        )
        XCTAssertNil(
            AppDelegate.fameOnboardingGapRecommendedCommandID(
                hasDailyBrief: true,
                hasScorecard: true,
                hasNudge: true
            )
        )
    }

    func testShouldShowFameOnboardingGapActionHidesAtThreeOfThreeArtifacts() {
        XCTAssertTrue(
            AppDelegate.shouldShowFameOnboardingGapAction(
                hasDailyBrief: false,
                hasScorecard: true,
                hasNudge: true
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldShowFameOnboardingGapAction(
                hasDailyBrief: true,
                hasScorecard: false,
                hasNudge: true
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldShowFameOnboardingGapAction(
                hasDailyBrief: true,
                hasScorecard: true,
                hasNudge: false
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldShowFameOnboardingGapAction(
                hasDailyBrief: true,
                hasScorecard: true,
                hasNudge: true
            )
        )
    }

    @MainActor
    func testCommandPaletteOnboardingRunActionsAppearWhenOnboardingIsEligible() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared

        let previousOnboardingEnabled = settings.fameOnboardingNudgeEnabled
        let previousOnboardingWindowDays = settings.fameOnboardingNudgeWindowDays
        let previousCadenceCurrent = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        let previousCadenceBest = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        let previousInstallDay = defaults.object(forKey: "firstRunInstallDay")
        let previousCompletedDays = defaults.object(forKey: "fameOnboardingCompletedDays")
        let previousNudgeLastShownDay = defaults.object(forKey: "fameOnboardingNudgeLastShownDay")

        defer {
            settings.fameOnboardingNudgeEnabled = previousOnboardingEnabled
            settings.fameOnboardingNudgeWindowDays = previousOnboardingWindowDays
            restoreDefaultsObject(previousCadenceCurrent, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
            restoreDefaultsObject(previousCadenceBest, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
            restoreDefaultsObject(previousInstallDay, forKey: "firstRunInstallDay")
            restoreDefaultsObject(previousCompletedDays, forKey: "fameOnboardingCompletedDays")
            restoreDefaultsObject(previousNudgeLastShownDay, forKey: "fameOnboardingNudgeLastShownDay")
        }

        settings.fameOnboardingNudgeEnabled = true
        settings.fameOnboardingNudgeWindowDays = 7
        defaults.set(3, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        defaults.set(Self.dayStamp(daysFromNow: -2), forKey: "firstRunInstallDay")
        defaults.set(2, forKey: "fameOnboardingCompletedDays")
        defaults.removeObject(forKey: "fameOnboardingNudgeLastShownDay")

        let actionIDs = AppDelegate().commandPaletteActionIDsForTesting()

        XCTAssertTrue(actionIDs.contains("run-fame-onboarding-daily-brief"))
        XCTAssertTrue(actionIDs.contains("run-fame-onboarding-scorecard"))
        XCTAssertTrue(actionIDs.contains("run-fame-onboarding-nudge"))
        XCTAssertTrue(actionIDs.contains("open-latest-onboarding-suite"))
    }

    @MainActor
    func testCommandPaletteIncludesCopyCadenceShareLineAction() {
        let actionIDs = AppDelegate().commandPaletteActionIDsForTesting()
        XCTAssertTrue(actionIDs.contains("run-fame-exceptional-loop"))
        XCTAssertTrue(actionIDs.contains("copy-fame-cadence-share-line"))
        XCTAssertTrue(actionIDs.contains("copy-fame-cadence-share-pack"))
        XCTAssertTrue(actionIDs.contains("run-fame-launch-control-hub"))
        XCTAssertTrue(actionIDs.contains("run-fame-launch-rescue-snapshot"))
        XCTAssertTrue(actionIDs.contains("copy-fame-launch-rescue-snapshot"))
        XCTAssertTrue(actionIDs.contains("open-latest-launch-control-hub"))
        XCTAssertTrue(actionIDs.contains("open-latest-launch-rescue-snapshot"))
        XCTAssertTrue(actionIDs.contains("copy-next-move-best-channel-launch-pack"))
        XCTAssertTrue(actionIDs.contains("copy-next-move-best-channel-draft"))
        XCTAssertTrue(actionIDs.contains("open-latest-cadence-momentum-brief"))
        XCTAssertTrue(actionIDs.contains("open-latest-cadence-share-line"))
        XCTAssertTrue(actionIDs.contains("open-latest-cadence-share-pack"))
        XCTAssertTrue(actionIDs.contains("open-latest-fame-exceptional-loop-recap"))
        XCTAssertTrue(actionIDs.contains("auto-tune-fame-exceptional-loop-recovery"))
        XCTAssertTrue(actionIDs.contains("reset-fame-exceptional-loop-tuning"))
        XCTAssertTrue(actionIDs.contains("run-fame-launch-rescue-followup-now"))
    }

    @MainActor
    func testCommandPaletteExceptionalLoopActionSubtitleIncludesHealthRecommendationContext() throws {
        let defaults = UserDefaults.standard
        let totalKey = AppDefaults.fameExceptionalLoopOutcomeTotalCountKey
        let successKey = AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey
        let successStreakKey = AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey
        let failureStreakKey = AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey
        let lastFocusKey = AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey
        let lastAtKey = AppDefaults.fameExceptionalLoopOutcomeLastAtKey
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey

        let previousTotal = defaults.object(forKey: totalKey)
        let previousSuccess = defaults.object(forKey: successKey)
        let previousSuccessStreak = defaults.object(forKey: successStreakKey)
        let previousFailureStreak = defaults.object(forKey: failureStreakKey)
        let previousLastFocus = defaults.object(forKey: lastFocusKey)
        let previousLastAt = defaults.object(forKey: lastAtKey)
        let previousHistory = defaults.object(forKey: historyKey)

        defer {
            restoreDefaultsObject(previousTotal, forKey: totalKey)
            restoreDefaultsObject(previousSuccess, forKey: successKey)
            restoreDefaultsObject(previousSuccessStreak, forKey: successStreakKey)
            restoreDefaultsObject(previousFailureStreak, forKey: failureStreakKey)
            restoreDefaultsObject(previousLastFocus, forKey: lastFocusKey)
            restoreDefaultsObject(previousLastAt, forKey: lastAtKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(4 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(2 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: now.addingTimeInterval(-(1 * 60)).timeIntervalSince1970,
                wasSuccess: true
            )
        ]

        defaults.set(3, forKey: totalKey)
        defaults.set(1, forKey: successKey)
        defaults.set(0, forKey: successStreakKey)
        defaults.set(2, forKey: failureStreakKey)
        defaults.set("run-fame-next-move-copy-drafts", forKey: lastFocusKey)
        defaults.set(now.timeIntervalSince1970, forKey: lastAtKey)
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let delegate = AppDelegate()
        let actionID = "run-fame-exceptional-loop"
        let subtitle = try XCTUnwrap(
            delegate.commandPaletteActionSubtitleForTesting(id: actionID)
        )
        XCTAssertTrue(
            subtitle.contains(
                "Telemetry next move ["
            )
        )
        XCTAssertTrue(subtitle.contains("Run Next Move + Copy Draft Pack"))
        XCTAssertTrue(
            subtitle.contains(
                "Why: Recovery lane pressure is active on Run Next Move + Copy Draft Pack:"
            )
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSignalBadgeTitleForTesting(id: actionID),
            "Loop High"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSignalBadgeToneForTesting(id: actionID),
            "high"
        )
        let signalHelpText = try XCTUnwrap(
            delegate.commandPaletteActionSignalBadgeHelpTextForTesting(id: actionID)
        )
        XCTAssertTrue(signalHelpText.contains("Run Next Move + Copy Draft Pack"))

        let panelModel = try XCTUnwrap(
            delegate.commandPaletteActionRecommendationPanelModelForTesting(id: actionID)
        )
        let actionTitle = try XCTUnwrap(delegate.commandPaletteActionTitleForTesting(id: actionID))
        let badgeTitle = try XCTUnwrap(
            delegate.commandPaletteActionSignalBadgeTitleForTesting(id: actionID)
        )
        XCTAssertEqual(panelModel.title, "Why this recommendation")
        XCTAssertEqual(panelModel.actionID, actionID)
        XCTAssertEqual(panelModel.actionTitle, actionTitle)
        XCTAssertEqual(panelModel.badgeTitle, badgeTitle)
        XCTAssertEqual(panelModel.tone, .high)
        XCTAssertEqual(panelModel.detail, signalHelpText)
        XCTAssertEqual(panelModel.recommendedActionID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(panelModel.recommendedActionTitle, "Run Next Move + Copy Draft Pack")
    }

    @MainActor
    func testCommandPaletteExceptionalLoopRecoveryLaneActionAppearsForRecoveryStreak() {
        let defaults = UserDefaults.standard
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        defer {
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(4 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(1 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let delegate = AppDelegate()
        let actionID = "run-fame-exceptional-loop-recovery-lane-now"
        let actionIDs = delegate.commandPaletteActionIDsForTesting()
        XCTAssertTrue(actionIDs.contains(actionID))
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: actionID),
            "Run Recovery Lane Now: Run Next Move + Copy Draft Pack"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: actionID),
            "Top recovery lane 2/2 misses, streak x2."
        )
    }

    @MainActor
    func testCommandPaletteExceptionalLoopRecoveryLaneActionHidesWithoutMeaningfulRecoveryStreak() {
        let defaults = UserDefaults.standard
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        defer {
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(2 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(1 * 60)).timeIntervalSince1970,
                wasSuccess: true
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let actionIDs = AppDelegate().commandPaletteActionIDsForTesting()
        XCTAssertFalse(actionIDs.contains("run-fame-exceptional-loop-recovery-lane-now"))
    }

    @MainActor
    func testCommandPaletteExceptionalLoopLatestRecapActionStateCanToggleEnabledAndReason() {
        let unavailableState = AppDelegate()
            .fameExceptionalLoopLatestRecapCommandPaletteActionStateForTesting(
                hasSavedRecap: false
            )
        XCTAssertEqual(
            unavailableState.subtitle,
            "No saved recap yet. Run Fame Exceptional Loop first."
        )
        XCTAssertEqual(unavailableState.isEnabled, false)
        XCTAssertEqual(
            unavailableState.disabledReason,
            "Open Latest Exceptional Loop Recap (Unavailable)"
        )

        let readyState = AppDelegate()
            .fameExceptionalLoopLatestRecapCommandPaletteActionStateForTesting(
                hasSavedRecap: true
            )
        XCTAssertEqual(
            readyState.subtitle,
            "Open latest run recap for the Fame exceptional loop"
        )
        XCTAssertEqual(readyState.isEnabled, true)
        XCTAssertEqual(readyState.disabledReason, "Latest recap ready.")
    }

    @MainActor
    func testCommandPaletteExceptionalLoopAutoTuneActionCanShowSuggestedTuning() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousMissesRequired = settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let previousFailureStreakRequired = settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let previousCooldownMinutes = settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes

        defer {
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = previousMissesRequired
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
                previousFailureStreakRequired
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = previousCooldownMinutes
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 3
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 20

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(6 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(5 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(4 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(3 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let delegate = AppDelegate()
        let actionID = "auto-tune-fame-exceptional-loop-recovery"
        XCTAssertTrue(delegate.commandPaletteActionIDsForTesting().contains(actionID))
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: actionID),
            "Suggested 2+ misses, streak x1, cooldown 5m from telemetry (current 3+ misses, streak x2, cooldown 20m). Pressure is persistent (4/4 misses, streak x4); fire recovery quickly."
        )
        XCTAssertEqual(delegate.commandPaletteActionIsEnabledForTesting(id: actionID), true)
        XCTAssertNil(delegate.commandPaletteActionDisabledReasonForTesting(id: actionID))
    }

    @MainActor
    func testCommandPaletteExceptionalLoopAutoTuneActionCanDisableWhenCalibratingOrAlreadyTuned() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousMissesRequired = settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let previousFailureStreakRequired = settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let previousCooldownMinutes = settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes

        defer {
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = previousMissesRequired
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
                previousFailureStreakRequired
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = previousCooldownMinutes
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 3
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 20
        defaults.removeObject(forKey: historyKey)

        let delegate = AppDelegate()
        let actionID = "auto-tune-fame-exceptional-loop-recovery"
        XCTAssertEqual(delegate.commandPaletteActionIsEnabledForTesting(id: actionID), false)
        XCTAssertEqual(
            delegate.commandPaletteActionDisabledReasonForTesting(id: actionID),
            "Auto-Tune Recovery: Waiting for Telemetry"
        )

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(3 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(2 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(1 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)
        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 1
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 10

        XCTAssertEqual(delegate.commandPaletteActionIsEnabledForTesting(id: actionID), false)
        XCTAssertEqual(
            delegate.commandPaletteActionDisabledReasonForTesting(id: actionID),
            "Auto-Tune Recovery: Tuned"
        )
    }

    @MainActor
    func testCommandPaletteExceptionalLoopResetActionCanDisableWhenAlreadyBaseline() {
        let defaults = UserDefaults.standard
        let totalKey = AppDefaults.fameExceptionalLoopOutcomeTotalCountKey
        let successKey = AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey
        let successStreakKey = AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey
        let failureStreakKey = AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey
        let lastFocusKey = AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey
        let lastAtKey = AppDefaults.fameExceptionalLoopOutcomeLastAtKey
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousTotal = defaults.object(forKey: totalKey)
        let previousSuccess = defaults.object(forKey: successKey)
        let previousSuccessStreak = defaults.object(forKey: successStreakKey)
        let previousFailureStreak = defaults.object(forKey: failureStreakKey)
        let previousLastFocus = defaults.object(forKey: lastFocusKey)
        let previousLastAt = defaults.object(forKey: lastAtKey)
        let previousHistory = defaults.object(forKey: historyKey)

        defer {
            restoreDefaultsObject(previousTotal, forKey: totalKey)
            restoreDefaultsObject(previousSuccess, forKey: successKey)
            restoreDefaultsObject(previousSuccessStreak, forKey: successStreakKey)
            restoreDefaultsObject(previousFailureStreak, forKey: failureStreakKey)
            restoreDefaultsObject(previousLastFocus, forKey: lastFocusKey)
            restoreDefaultsObject(previousLastAt, forKey: lastAtKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        defaults.removeObject(forKey: totalKey)
        defaults.removeObject(forKey: successKey)
        defaults.removeObject(forKey: successStreakKey)
        defaults.removeObject(forKey: failureStreakKey)
        defaults.removeObject(forKey: lastFocusKey)
        defaults.removeObject(forKey: lastAtKey)
        defaults.removeObject(forKey: historyKey)

        let delegate = AppDelegate()
        let actionID = "reset-fame-exceptional-loop-tuning"
        XCTAssertEqual(delegate.commandPaletteActionIsEnabledForTesting(id: actionID), false)
        XCTAssertEqual(
            delegate.commandPaletteActionDisabledReasonForTesting(id: actionID),
            "Reset Exceptional Loop Tuning: Baseline"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: actionID),
            "Adaptive outcome telemetry is already at baseline."
        )

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-90).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        XCTAssertEqual(delegate.commandPaletteActionIsEnabledForTesting(id: actionID), true)
        XCTAssertNil(delegate.commandPaletteActionDisabledReasonForTesting(id: actionID))
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: actionID),
            "Clear adaptive outcome streaks and focus memory."
        )
    }

    @MainActor
    func testExceptionalLoopAutoTuneActionCanApplyRecommendedThresholds() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousMissesRequired = settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let previousFailureStreakRequired = settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let previousCooldownMinutes = settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes

        defer {
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = previousMissesRequired
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
                previousFailureStreakRequired
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = previousCooldownMinutes
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 3
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 20

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(8 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(7 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(6 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(5 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let delegate = AppDelegate()
        delegate.runFameExceptionalLoopAutoRecoveryLaneAutoTuneForTesting(
            now: now,
            defaults: defaults
        )

        XCTAssertEqual(settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired, 2)
        XCTAssertEqual(settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired, 1)
        XCTAssertEqual(settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes, 5)
    }

    @MainActor
    func testExceptionalLoopAutoTuneSettingsActionCanApplyRecommendedThresholds() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousHistory = defaults.object(forKey: historyKey)
        let previousMissesRequired = settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let previousFailureStreakRequired = settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let previousCooldownMinutes = settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes

        defer {
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = previousMissesRequired
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
                previousFailureStreakRequired
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = previousCooldownMinutes
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = 3
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 2
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 20

        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(8 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(7 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(6 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(5 * 60)).timeIntervalSince1970,
                wasSuccess: false
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let delegate = AppDelegate()
        delegate.runFameExceptionalLoopAutoRecoveryLaneAutoTuneFromSettingsForTesting(
            now: now,
            defaults: defaults
        )

        XCTAssertEqual(settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired, 2)
        XCTAssertEqual(settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired, 1)
        XCTAssertEqual(settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes, 5)
    }

    @MainActor
    func testExceptionalLoopRecoveryLaneSettingsActionRecordsSettingsActivity() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousHistory = defaults.object(forKey: historyKey)

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: historyKey)

        let delegate = AppDelegate()
        delegate.runFameExceptionalLoopRecoveryLaneNowFromSettingsForTesting()

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(
            loggedDetails.contains("run-fame-exceptional-loop-recovery-lane-now-settings")
        )
    }

    @MainActor
    func testExceptionalLoopHealthRecommendedSettingsActionCanSelectRecoveryLaneAndTrackSource() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousHistory = defaults.object(forKey: historyKey)

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        defaults.removeObject(forKey: activityLogKey)
        let now = Date()
        let history = [
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(4 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-next-move-copy-drafts",
                recordedAt: now.addingTimeInterval(-(2 * 60)).timeIntervalSince1970,
                wasSuccess: false
            ),
            AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                commandToken: "run-fame-cadence-autopilot-loop",
                recordedAt: now.addingTimeInterval(-(1 * 60)).timeIntervalSince1970,
                wasSuccess: true
            )
        ]
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let delegate = AppDelegate()
        let commandID = delegate.runFameExceptionalLoopHealthRecommendedActionFromSettingsForTesting(
            now: now,
            defaults: defaults
        )

        XCTAssertEqual(commandID, "run-fame-next-move-copy-drafts")
        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(
            loggedDetails.contains(
                "run-fame-exceptional-loop-health-recommended-action-settings-run-fame-next-move-copy-drafts"
            )
        )
    }

    @MainActor
    func testExceptionalLoopLatestRecapSettingsActionRecordsSettingsActivity() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
        }

        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.openLatestFameExceptionalLoopRecapFromSettingsForTesting()

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("open-latest-fame-exceptional-loop-recap-settings"))
        XCTAssertTrue(
            loggedDetails.contains("open-latest-fame-exceptional-loop-recap")
                || loggedDetails.contains("open-latest-fame-exceptional-loop-recap-empty")
                || loggedDetails.contains("open-latest-fame-exceptional-loop-recap-error")
        )
    }

    @MainActor
    func testExceptionalLoopResetSettingsActionCanClearStoredTelemetry() {
        let defaults = UserDefaults.standard
        let totalKey = AppDefaults.fameExceptionalLoopOutcomeTotalCountKey
        let successKey = AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey
        let successStreakKey = AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey
        let failureStreakKey = AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey
        let lastFocusKey = AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey
        let lastAtKey = AppDefaults.fameExceptionalLoopOutcomeLastAtKey
        let historyKey = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
        let autoRunAtKey = AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey
        let previousTotal = defaults.object(forKey: totalKey)
        let previousSuccess = defaults.object(forKey: successKey)
        let previousSuccessStreak = defaults.object(forKey: successStreakKey)
        let previousFailureStreak = defaults.object(forKey: failureStreakKey)
        let previousLastFocus = defaults.object(forKey: lastFocusKey)
        let previousLastAt = defaults.object(forKey: lastAtKey)
        let previousHistory = defaults.object(forKey: historyKey)
        let previousAutoRunAt = defaults.object(forKey: autoRunAtKey)

        defer {
            restoreDefaultsObject(previousTotal, forKey: totalKey)
            restoreDefaultsObject(previousSuccess, forKey: successKey)
            restoreDefaultsObject(previousSuccessStreak, forKey: successStreakKey)
            restoreDefaultsObject(previousFailureStreak, forKey: failureStreakKey)
            restoreDefaultsObject(previousLastFocus, forKey: lastFocusKey)
            restoreDefaultsObject(previousLastAt, forKey: lastAtKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
            restoreDefaultsObject(previousAutoRunAt, forKey: autoRunAtKey)
        }

        defaults.set(6, forKey: totalKey)
        defaults.set(3, forKey: successKey)
        defaults.set(2, forKey: successStreakKey)
        defaults.set(1, forKey: failureStreakKey)
        defaults.set("run-fame-next-move-copy-drafts", forKey: lastFocusKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastAtKey)
        defaults.set(Date().addingTimeInterval(-120).timeIntervalSince1970, forKey: autoRunAtKey)
        defaults.set(
            try? JSONEncoder().encode([
                AppDelegate.FameExceptionalLoopOutcomeCommandSample(
                    commandToken: "run-fame-next-move-copy-drafts",
                    recordedAt: Date().timeIntervalSince1970,
                    wasSuccess: false
                )
            ]),
            forKey: historyKey
        )

        let delegate = AppDelegate()
        delegate.resetFameExceptionalLoopOutcomeTuningFromSettingsForTesting(defaults: defaults)

        XCTAssertEqual(defaults.integer(forKey: totalKey), 0)
        XCTAssertEqual(defaults.integer(forKey: successKey), 0)
        XCTAssertEqual(defaults.integer(forKey: successStreakKey), 0)
        XCTAssertEqual(defaults.integer(forKey: failureStreakKey), 0)
        XCTAssertNil(defaults.object(forKey: lastFocusKey))
        XCTAssertNil(defaults.object(forKey: lastAtKey))
        XCTAssertNil(defaults.object(forKey: historyKey))
        XCTAssertNil(defaults.object(forKey: autoRunAtKey))
    }

    @MainActor
    func testCommandPaletteLaunchRescueSubtitlesCanIncludeCooldownMomentumCue() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let triggerReasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousTriggerReason = defaults.object(forKey: triggerReasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousTriggerReason, forKey: triggerReasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        defaults.set(-2, forKey: modeMomentumKey)
        defaults.set("urgency-high", forKey: triggerReasonKey)
        defaults.removeObject(forKey: triggerAtKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()

        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: "run-fame-launch-rescue-burst-auto-status"),
            "Launch Rescue Auto: Run Now · Watch x2 · High"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-countdown"),
            "Generate real-time launch step tracker"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-burst"),
            "Generate launch countdown + next-move handoff + recovery checklist · Cooldown streak x2 · stage rescue now"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-burst-auto-status"),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Last auto trigger: Urgency High escalation. · Trigger severity: High · Follow-up: Run next move and ship the first block now. · Cooldown streak x2 · stage rescue now"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: "run-fame-launch-rescue-followup-now"),
            "Run Launch Rescue Follow-up Now · High"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-followup-now"),
            "Route: Run Fame Next Move + Copy Draft Pack. Run next move and ship the first block now. Coach: Baseline mode · execute Run Fame Next Move + Copy Draft Pack once to seed outcomes."
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-control-brief"),
            "Refresh launch countdown + save + copy launch control brief"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-control-hub"),
            "Generate burst + countdown + brief + snapshot"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-snapshot"),
            "Generate + save + reveal launch rescue snapshot"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "copy-fame-launch-control-brief"),
            "Copy live launch alert + rescue + threshold status brief"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "copy-fame-launch-rescue-snapshot"),
            "Copy auto trigger + follow-up + scoreboard snapshot"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "open-latest-launch-rescue-snapshot"),
            "Open latest launch rescue snapshot"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "open-latest-launch-countdown"),
            "Open latest launch countdown"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "open-latest-launch-rescue-burst"),
            "Open latest launch rescue burst"
        )
    }

    @MainActor
    func testCommandPaletteLaunchControlBriefSubtitlesCanIncludeFollowupMomentumCue() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let followupCoachRecoveryChecklistCooldownMinutesKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
        let followupCoachRecoveryChecklistLastAutoAtKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousFollowupCoachRecoveryChecklistCooldownMinutes = defaults.object(
            forKey: followupCoachRecoveryChecklistCooldownMinutesKey
        )
        let previousFollowupCoachRecoveryChecklistLastAutoAt = defaults.object(
            forKey: followupCoachRecoveryChecklistLastAutoAtKey
        )

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryChecklistCooldownMinutes,
                forKey: followupCoachRecoveryChecklistCooldownMinutesKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryChecklistLastAutoAt,
                forKey: followupCoachRecoveryChecklistLastAutoAtKey
            )
        }

        let now = Date()
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(6, forKey: followupOutcomeTotalCountKey)
        defaults.set(2, forKey: followupOutcomeSuccessCountKey)
        defaults.set(now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970, forKey: followupOutcomeLastAtKey)
        defaults.set(2, forKey: followupCoachRecoveryLaneStreakKey)
        defaults.set(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes,
            forKey: followupCoachRecoveryChecklistCooldownMinutesKey
        )
        defaults.removeObject(forKey: followupCoachRecoveryChecklistLastAutoAtKey)
        defaults.set(
            try? JSONEncoder().encode([
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
            ]),
            forKey: followupOutcomeHistoryKey
        )

        let delegate = AppDelegate()

        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-control-brief"),
            "Refresh launch countdown + save + copy launch control brief · Rescue Recovery x2 · CD 30m · Steady →"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-control-hub"),
            "Generate burst + countdown + brief + snapshot · Rescue Recovery x2 · CD 30m · Steady →"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-snapshot"),
            "Generate + save + reveal launch rescue snapshot · Rescue Recovery x2 · CD 30m · Steady →"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "copy-fame-launch-control-brief"),
            "Copy live launch alert + rescue + threshold status brief · Rescue Recovery x2 · CD 30m · Steady →"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "copy-fame-launch-rescue-snapshot"),
            "Copy auto trigger + follow-up + scoreboard snapshot · Rescue Recovery x2 · CD 30m · Steady →"
        )
    }

    @MainActor
    func testCommandPaletteLaunchRescueFollowupActionCanEscalateRouteForSelfHealAttention() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(Date().addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(0, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 30

        let delegate = AppDelegate()
        let actionID = "run-fame-launch-rescue-followup-now"
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: actionID),
            "Run Launch Rescue Follow-up Now · High · Self-Heal Missing x1 · Route Burst"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSignalBadgeTitleForTesting(id: actionID),
            "Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSignalBadgeToneForTesting(id: actionID),
            "high"
        )
        let signalHelpText = delegate.commandPaletteActionSignalBadgeHelpTextForTesting(id: actionID) ?? ""
        XCTAssertTrue(signalHelpText.contains("Issue streak x1") == true)
        XCTAssertTrue(signalHelpText.contains("Recommended: Run Launch Rescue Burst.") == true)
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: "run-fame-launch-rescue-burst-auto-status"),
            "Launch Rescue Auto: Run Now · High · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-burst-auto-status"),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Last auto trigger: Urgency High escalation. · Trigger severity: High · Last auto trigger time: 22m ago. · Follow-up: Priority window active. Run next move and ship the first block now. · Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack. · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: "run-fame-auto-bundle-status"),
            "Fame Auto Bundle: Run Now · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-auto-bundle-status"),
            "Auto bundle is ready on escalation. Run once now. · Route Burst · Self-Heal Missing x1"
        )

        let subtitle = delegate.commandPaletteActionSubtitleForTesting(id: actionID) ?? ""
        XCTAssertTrue(
            subtitle.contains(
                "Route: Run Launch Rescue Burst. Priority window active. Run next move and ship the first block now."
            ) == true
        )
        XCTAssertTrue(subtitle.contains("Self-Heal: Urgency High escalation.") == true)
        XCTAssertTrue(
            subtitle.contains(
                "Coach: Baseline mode · execute Run Fame Next Move + Copy Draft Pack once to seed outcomes."
            ) == true
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-control-hub"),
            "Generate burst + countdown + brief + snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-control-brief"),
            "Refresh launch countdown + save + copy launch control brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-countdown"),
            "Generate real-time launch step tracker · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-burst"),
            "Generate launch countdown + next-move handoff + recovery checklist · Route Burst · Self-Heal Missing x1"
        )
        let launchControlHubOpenSubtitle = delegate.commandPaletteActionSubtitleForTesting(
            id: "open-latest-launch-control-hub"
        ) ?? ""
        XCTAssertTrue(launchControlHubOpenSubtitle.contains("Route Burst"))
        XCTAssertTrue(launchControlHubOpenSubtitle.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            launchControlHubOpenSubtitle.contains("No saved launch artifacts yet")
                || launchControlHubOpenSubtitle.contains("launch artifacts ready")
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "open-latest-launch-control-brief"),
            "Open latest launch control brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "open-latest-launch-countdown"),
            "Open latest launch countdown · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "open-latest-launch-rescue-burst"),
            "Open latest launch rescue burst · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "run-fame-launch-rescue-snapshot"),
            "Generate + save + reveal launch rescue snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "copy-fame-launch-control-brief"),
            "Copy live launch alert + rescue + threshold status brief · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: "copy-fame-launch-rescue-snapshot"),
            "Copy auto trigger + follow-up + scoreboard snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.launchControlHubRunMenuStatusTitleForTesting(),
            "Run Launch Control Hub · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.launchControlHubRunMenuStatusToolTipForTesting(),
            "Generate burst + countdown + brief + snapshot · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.launchControlHubOpenMenuStatusTitleForTesting(),
            "Open Launch Control Hub · Route Burst · Self-Heal Missing x1"
        )
    }

    @MainActor
    func testLaunchControlHubMenuItemsRefreshAfterRouteContextChanges() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
        }

        defaults.removeObject(forKey: reasonKey)
        defaults.removeObject(forKey: triggerAtKey)

        let delegate = AppDelegate()
        delegate.buildFameMenuForTesting()

        let baselineNow = Date(timeIntervalSince1970: 1_800_000_000)
        delegate.refreshLaunchRescueAutoMenuStatusForTesting(now: baselineNow, defaults: defaults)
        let baselineTitles = delegate.launchControlHubOpenMenuRenderedTitlesForTesting()
        let baselineBriefTitles = delegate.launchControlBriefMenuRenderedTitlesForTesting()
        let baselineSnapshotTitles = delegate.launchRescueSnapshotMenuRenderedTitlesForTesting()
        let baselineCountdownAndBurstTitles = delegate.launchCountdownAndBurstMenuRenderedTitlesForTesting()
        let baselineAutoOpsTitle = delegate.autoOpsBundleMenuStatusRenderedTitleForTesting()
        let baselineAutoOpsToolTip = delegate.autoOpsBundleMenuStatusRenderedToolTipForTesting()
        let baselineExpected = delegate.launchControlHubOpenMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineAutoOpsExpected = delegate.autoOpsBundleMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineAutoOpsToolTipExpected = delegate.autoOpsBundleMenuStatusToolTipForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineBriefRunExpected = delegate.launchControlBriefRunMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineBriefOpenExpected = delegate.launchControlBriefOpenMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineBriefCopyExpected = delegate.launchControlBriefCopyMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineSnapshotOpenExpected = delegate.launchRescueSnapshotOpenMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineSnapshotCopyExpected = delegate.launchRescueSnapshotCopyMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineCountdownRunExpected = delegate.launchCountdownRunMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineCountdownOpenExpected = delegate.launchCountdownOpenMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineRescueBurstRunExpected = delegate.launchRescueBurstRunMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        let baselineRescueBurstOpenExpected = delegate.launchRescueBurstOpenMenuStatusTitleForTesting(
            now: baselineNow,
            defaults: defaults
        )
        XCTAssertEqual(baselineTitles.launchControlMenuTitle, baselineExpected)
        XCTAssertEqual(baselineTitles.fameMenuTitle, baselineExpected)
        XCTAssertEqual(baselineAutoOpsTitle, baselineAutoOpsExpected)
        XCTAssertEqual(baselineAutoOpsToolTip, baselineAutoOpsToolTipExpected)
        XCTAssertEqual(baselineBriefTitles.runTitle, baselineBriefRunExpected)
        XCTAssertEqual(baselineBriefTitles.openTitle, baselineBriefOpenExpected)
        XCTAssertEqual(baselineBriefTitles.copyTitle, baselineBriefCopyExpected)
        XCTAssertEqual(baselineSnapshotTitles.openTitle, baselineSnapshotOpenExpected)
        XCTAssertEqual(baselineSnapshotTitles.copyTitle, baselineSnapshotCopyExpected)
        XCTAssertEqual(baselineSnapshotTitles.fameOpenTitle, baselineSnapshotOpenExpected)
        XCTAssertEqual(
            baselineCountdownAndBurstTitles.countdownRunTitle,
            baselineCountdownRunExpected
        )
        XCTAssertEqual(
            baselineCountdownAndBurstTitles.countdownOpenTitle,
            baselineCountdownOpenExpected
        )
        XCTAssertEqual(
            baselineCountdownAndBurstTitles.rescueBurstRunTitle,
            baselineRescueBurstRunExpected
        )
        XCTAssertEqual(
            baselineCountdownAndBurstTitles.rescueBurstOpenTitle,
            baselineRescueBurstOpenExpected
        )

        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(baselineNow.timeIntervalSince1970, forKey: triggerAtKey)

        let escalatedNow = baselineNow.addingTimeInterval(60)
        delegate.refreshLaunchRescueAutoMenuStatusForTesting(now: escalatedNow, defaults: defaults)
        let escalatedTitles = delegate.launchControlHubOpenMenuRenderedTitlesForTesting()
        let escalatedBriefTitles = delegate.launchControlBriefMenuRenderedTitlesForTesting()
        let escalatedSnapshotTitles = delegate.launchRescueSnapshotMenuRenderedTitlesForTesting()
        let escalatedCountdownAndBurstTitles = delegate.launchCountdownAndBurstMenuRenderedTitlesForTesting()
        let escalatedAutoOpsTitle = delegate.autoOpsBundleMenuStatusRenderedTitleForTesting()
        let escalatedAutoOpsToolTip = delegate.autoOpsBundleMenuStatusRenderedToolTipForTesting()
        let escalatedExpected = delegate.launchControlHubOpenMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedAutoOpsExpected = delegate.autoOpsBundleMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedAutoOpsToolTipExpected = delegate.autoOpsBundleMenuStatusToolTipForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedBriefRunExpected = delegate.launchControlBriefRunMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedBriefOpenExpected = delegate.launchControlBriefOpenMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedBriefCopyExpected = delegate.launchControlBriefCopyMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedSnapshotOpenExpected = delegate.launchRescueSnapshotOpenMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedSnapshotCopyExpected = delegate.launchRescueSnapshotCopyMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedCountdownRunExpected = delegate.launchCountdownRunMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedCountdownOpenExpected = delegate.launchCountdownOpenMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedRescueBurstRunExpected = delegate.launchRescueBurstRunMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        let escalatedRescueBurstOpenExpected = delegate.launchRescueBurstOpenMenuStatusTitleForTesting(
            now: escalatedNow,
            defaults: defaults
        )
        XCTAssertEqual(escalatedTitles.launchControlMenuTitle, escalatedExpected)
        XCTAssertEqual(escalatedTitles.fameMenuTitle, escalatedExpected)
        XCTAssertEqual(escalatedAutoOpsTitle, escalatedAutoOpsExpected)
        XCTAssertEqual(escalatedAutoOpsToolTip, escalatedAutoOpsToolTipExpected)
        XCTAssertEqual(escalatedBriefTitles.runTitle, escalatedBriefRunExpected)
        XCTAssertEqual(escalatedBriefTitles.openTitle, escalatedBriefOpenExpected)
        XCTAssertEqual(escalatedBriefTitles.copyTitle, escalatedBriefCopyExpected)
        XCTAssertEqual(escalatedSnapshotTitles.openTitle, escalatedSnapshotOpenExpected)
        XCTAssertEqual(escalatedSnapshotTitles.copyTitle, escalatedSnapshotCopyExpected)
        XCTAssertEqual(escalatedSnapshotTitles.fameOpenTitle, escalatedSnapshotOpenExpected)
        XCTAssertEqual(
            escalatedCountdownAndBurstTitles.countdownRunTitle,
            escalatedCountdownRunExpected
        )
        XCTAssertEqual(
            escalatedCountdownAndBurstTitles.countdownOpenTitle,
            escalatedCountdownOpenExpected
        )
        XCTAssertEqual(
            escalatedCountdownAndBurstTitles.rescueBurstRunTitle,
            escalatedRescueBurstRunExpected
        )
        XCTAssertEqual(
            escalatedCountdownAndBurstTitles.rescueBurstOpenTitle,
            escalatedRescueBurstOpenExpected
        )
        XCTAssertNotEqual(escalatedTitles.launchControlMenuTitle, baselineTitles.launchControlMenuTitle)
        XCTAssertNotEqual(escalatedTitles.fameMenuTitle, baselineTitles.fameMenuTitle)
        XCTAssertNotEqual(escalatedAutoOpsTitle, baselineAutoOpsTitle)
        XCTAssertNotEqual(escalatedAutoOpsToolTip, baselineAutoOpsToolTip)
        XCTAssertNotEqual(escalatedBriefTitles.runTitle, baselineBriefTitles.runTitle)
        XCTAssertNotEqual(escalatedBriefTitles.openTitle, baselineBriefTitles.openTitle)
        XCTAssertNotEqual(escalatedBriefTitles.copyTitle, baselineBriefTitles.copyTitle)
        XCTAssertNotEqual(escalatedSnapshotTitles.openTitle, baselineSnapshotTitles.openTitle)
        XCTAssertNotEqual(escalatedSnapshotTitles.copyTitle, baselineSnapshotTitles.copyTitle)
        XCTAssertNotEqual(escalatedSnapshotTitles.fameOpenTitle, baselineSnapshotTitles.fameOpenTitle)
        XCTAssertNotEqual(
            escalatedCountdownAndBurstTitles.countdownRunTitle,
            baselineCountdownAndBurstTitles.countdownRunTitle
        )
        XCTAssertNotEqual(
            escalatedCountdownAndBurstTitles.countdownOpenTitle,
            baselineCountdownAndBurstTitles.countdownOpenTitle
        )
        XCTAssertNotEqual(
            escalatedCountdownAndBurstTitles.rescueBurstRunTitle,
            baselineCountdownAndBurstTitles.rescueBurstRunTitle
        )
        XCTAssertNotEqual(
            escalatedCountdownAndBurstTitles.rescueBurstOpenTitle,
            baselineCountdownAndBurstTitles.rescueBurstOpenTitle
        )
    }

    @MainActor
    func testCommandPaletteOnboardingRunActionsHideWhenOnboardingIsDisabled() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared

        let previousOnboardingEnabled = settings.fameOnboardingNudgeEnabled
        let previousOnboardingWindowDays = settings.fameOnboardingNudgeWindowDays
        let previousCadenceCurrent = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        let previousCadenceBest = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        let previousInstallDay = defaults.object(forKey: "firstRunInstallDay")
        let previousCompletedDays = defaults.object(forKey: "fameOnboardingCompletedDays")
        let previousNudgeLastShownDay = defaults.object(forKey: "fameOnboardingNudgeLastShownDay")

        defer {
            settings.fameOnboardingNudgeEnabled = previousOnboardingEnabled
            settings.fameOnboardingNudgeWindowDays = previousOnboardingWindowDays
            restoreDefaultsObject(previousCadenceCurrent, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
            restoreDefaultsObject(previousCadenceBest, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
            restoreDefaultsObject(previousInstallDay, forKey: "firstRunInstallDay")
            restoreDefaultsObject(previousCompletedDays, forKey: "fameOnboardingCompletedDays")
            restoreDefaultsObject(previousNudgeLastShownDay, forKey: "fameOnboardingNudgeLastShownDay")
        }

        settings.fameOnboardingNudgeEnabled = false
        settings.fameOnboardingNudgeWindowDays = 7
        defaults.set(3, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        defaults.set(Self.dayStamp(daysFromNow: -2), forKey: "firstRunInstallDay")
        defaults.set(2, forKey: "fameOnboardingCompletedDays")
        defaults.removeObject(forKey: "fameOnboardingNudgeLastShownDay")

        let actionIDs = AppDelegate().commandPaletteActionIDsForTesting()

        XCTAssertFalse(actionIDs.contains("run-fame-onboarding-daily-brief"))
        XCTAssertFalse(actionIDs.contains("run-fame-onboarding-scorecard"))
        XCTAssertFalse(actionIDs.contains("run-fame-onboarding-nudge"))
        XCTAssertTrue(actionIDs.contains("open-latest-onboarding-suite"))
        XCTAssertTrue(actionIDs.contains("open-latest-onboarding-daily-brief"))
        XCTAssertTrue(actionIDs.contains("open-latest-onboarding-scorecard"))
        XCTAssertTrue(actionIDs.contains("open-latest-onboarding-nudge"))
    }

    @MainActor
    func testCommandPaletteLaunchRecoveryNextActionAppearsWithFreshRecoveryMomentum() {
        let defaults = UserDefaults.standard
        let lastRecoveryAtKey = AppDefaults.fameOnboardingGapRecoveryLastAtKey
        let followupCommandIDKey = AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey
        let remainingArtifactsKey = AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey
        let previousLastRecoveryAt = defaults.object(forKey: lastRecoveryAtKey)
        let previousFollowupCommandID = defaults.object(forKey: followupCommandIDKey)
        let previousRemainingArtifacts = defaults.object(forKey: remainingArtifactsKey)

        defer {
            restoreDefaultsObject(previousLastRecoveryAt, forKey: lastRecoveryAtKey)
            restoreDefaultsObject(previousFollowupCommandID, forKey: followupCommandIDKey)
            restoreDefaultsObject(previousRemainingArtifacts, forKey: remainingArtifactsKey)
        }

        defaults.set(Date().timeIntervalSince1970, forKey: lastRecoveryAtKey)
        defaults.set("run-fame-onboarding-scorecard", forKey: followupCommandIDKey)
        defaults.set(1, forKey: remainingArtifactsKey)

        let actionIDs = AppDelegate().commandPaletteActionIDsForTesting()
        XCTAssertTrue(actionIDs.contains("run-fame-launch-recovery-next"))
    }

    @MainActor
    func testCommandPaletteLaunchRecoveryNextActionHidesWithoutFreshRecoveryMomentum() {
        let defaults = UserDefaults.standard
        let lastRecoveryAtKey = AppDefaults.fameOnboardingGapRecoveryLastAtKey
        let followupCommandIDKey = AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey
        let remainingArtifactsKey = AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey
        let previousLastRecoveryAt = defaults.object(forKey: lastRecoveryAtKey)
        let previousFollowupCommandID = defaults.object(forKey: followupCommandIDKey)
        let previousRemainingArtifacts = defaults.object(forKey: remainingArtifactsKey)

        defer {
            restoreDefaultsObject(previousLastRecoveryAt, forKey: lastRecoveryAtKey)
            restoreDefaultsObject(previousFollowupCommandID, forKey: followupCommandIDKey)
            restoreDefaultsObject(previousRemainingArtifacts, forKey: remainingArtifactsKey)
        }

        defaults.removeObject(forKey: lastRecoveryAtKey)
        defaults.removeObject(forKey: followupCommandIDKey)
        defaults.removeObject(forKey: remainingArtifactsKey)

        let actionIDs = AppDelegate().commandPaletteActionIDsForTesting()
        XCTAssertFalse(actionIDs.contains("run-fame-launch-recovery-next"))
    }

    @MainActor
    func testCommandPaletteLaunchRescueSelfHealAttentionActionAppearsForStaleIssue() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
        }

        let staleDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "healed"
        )
        let encodedActivityLog = try? JSONEncoder().encode([
            ActivityLogItem(
                id: UUID(),
                createdAt: Date().addingTimeInterval(-(40 * 60)),
                category: "support",
                detail: staleDetail
            )
        ])

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(encodedActivityLog, forKey: activityLogKey)

        let delegate = AppDelegate()
        let actionID = "run-fame-launch-rescue-self-heal-attention"
        let actionIDs = delegate.commandPaletteActionIDsForTesting()
        XCTAssertEqual(actionIDs.first, actionID)
        XCTAssertTrue(actionIDs.contains(actionID))
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: actionID),
            "Launch Rescue Self-Heal Attention: Stale check for Urgency Critical escalation"
        )
        let subtitle = delegate.commandPaletteActionSubtitleForTesting(id: actionID) ?? ""
        XCTAssertTrue(subtitle.contains("Launch Rescue Auto Self-Heal stale ("))
        XCTAssertTrue(subtitle.contains("Execute Run Launch Rescue Burst now."))
    }

    @MainActor
    func testCommandPaletteLaunchRescueSelfHealAttentionActionAppearsForMismatchIssue() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
        }

        let mismatchDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-high",
            routeCommandID: "run-fame-next-move-copy-drafts",
            outcome: "ready"
        )
        let encodedActivityLog = try? JSONEncoder().encode([
            ActivityLogItem(
                id: UUID(),
                createdAt: Date().addingTimeInterval(-120),
                category: "support",
                detail: mismatchDetail
            )
        ])

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(encodedActivityLog, forKey: activityLogKey)

        let delegate = AppDelegate()
        let actionID = "run-fame-launch-rescue-self-heal-attention"
        XCTAssertTrue(delegate.commandPaletteActionIDsForTesting().contains(actionID))
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: actionID),
            "Launch Rescue Self-Heal Attention: Trigger mismatch for Urgency Critical escalation"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSubtitleForTesting(id: actionID),
            "Launch Rescue Auto Self-Heal mismatch: latest Urgency High escalation. waiting for Urgency Critical escalation. Execute Run Launch Rescue Burst now."
        )
    }

    @MainActor
    func testCommandPaletteLaunchRescueSelfHealAttentionActionAppearsForMissingIssueAfterGraceWindow() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
        }

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(
            Date().addingTimeInterval(-(12 * 60)).timeIntervalSince1970,
            forKey: triggerAtKey
        )
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        let actionID = "run-fame-launch-rescue-self-heal-attention"
        XCTAssertTrue(delegate.commandPaletteActionIDsForTesting().contains(actionID))
        XCTAssertEqual(
            delegate.commandPaletteActionTitleForTesting(id: actionID),
            "Launch Rescue Self-Heal Attention: Missing check for Urgency Critical escalation"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSignalBadgeTitleForTesting(id: actionID),
            "Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.commandPaletteActionSignalBadgeToneForTesting(id: actionID),
            "medium"
        )
        let signalHelpText = delegate.commandPaletteActionSignalBadgeHelpTextForTesting(id: actionID) ?? ""
        XCTAssertTrue(signalHelpText.contains("Urgency Critical escalation.") == true)
        XCTAssertTrue(signalHelpText.contains("Recommended: Run Launch Rescue Burst.") == true)
        let subtitle = delegate.commandPaletteActionSubtitleForTesting(id: actionID) ?? ""
        XCTAssertTrue(subtitle.contains("Launch Rescue Auto Self-Heal missing ("))
        XCTAssertTrue(subtitle.contains("Execute Run Launch Rescue Burst now."))
    }

    @MainActor
    func testCommandPaletteLaunchRescueSelfHealAttentionActionHidesWhenHealthyOrNoTrigger() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
        }

        let actionID = "run-fame-launch-rescue-self-heal-attention"
        let matchingHealthyDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "healed"
        )
        let healthyActivityLog = try? JSONEncoder().encode([
            ActivityLogItem(
                id: UUID(),
                createdAt: Date().addingTimeInterval(-90),
                category: "support",
                detail: matchingHealthyDetail
            )
        ])

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(healthyActivityLog, forKey: activityLogKey)
        XCTAssertFalse(AppDelegate().commandPaletteActionIDsForTesting().contains(actionID))

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(
            Date().addingTimeInterval(-120).timeIntervalSince1970,
            forKey: triggerAtKey
        )
        defaults.removeObject(forKey: activityLogKey)
        XCTAssertFalse(AppDelegate().commandPaletteActionIDsForTesting().contains(actionID))

        defaults.set("none", forKey: reasonKey)
        XCTAssertFalse(AppDelegate().commandPaletteActionIDsForTesting().contains(actionID))
    }

    func testFameOnboardingScorecardMenuTitleIncludesDayAndProgress() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingScorecardMenuTitle(
                day: 3,
                windowDays: 7,
                completedDays: 2
            ),
            "Run First-Week Fame Scorecard (Day 3/7 · 2/7)"
        )
    }

    func testFameOnboardingDailyBriefTitleSubtitleAndMarkdownIncludesArtifacts() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingDailyBriefActionTitle(day: 3, windowDays: 7),
            "Run First-Week Daily Brief (Day 3/7)"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingDailyBriefActionSubtitle(
                day: 3,
                windowDays: 7,
                completedDays: 2,
                recommendedCommandID: "run-fame-cadence-autopilot-loop"
            ),
            "Day 3/7 · Progress 2/7 (5 left) · Save nudge + scorecard + daily brief · Next Run Cadence Autopilot Loop"
        )

        let markdown = AppDelegate.fameOnboardingDailyBriefMarkdown(
            day: 4,
            windowDays: 7,
            completedDays: 3,
            currentStreak: 2,
            bestStreak: 5,
            recommendedCommandID: "run-fame-cadence-autopilot-loop",
            backupCommandID: "run-fame-cadence-momentum-brief",
            onboardingNudgeArtifactName: "fame-onboarding-nudge-20260610-1030.md",
            onboardingScorecardArtifactName: "fame-onboarding-scorecard-20260610-1030.md",
            dailyBriefArtifactName: "fame-onboarding-daily-brief-20260610-1030.md",
            now: Date(timeIntervalSince1970: 1_717_977_600),
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        XCTAssertTrue(markdown.contains("# Fluid Reader First-Week Daily Brief"))
        XCTAssertTrue(markdown.contains("Day 4 of 7"))
        XCTAssertTrue(markdown.contains("Date: 2024-06-10"))
        XCTAssertTrue(markdown.contains("Completed onboarding days: 3/7"))
        XCTAssertTrue(markdown.contains("Remaining onboarding days: 4"))
        XCTAssertTrue(markdown.contains("Current streak: x2"))
        XCTAssertTrue(markdown.contains("Best streak: x5"))
        XCTAssertTrue(markdown.contains("Onboarding nudge: fame-onboarding-nudge-20260610-1030.md"))
        XCTAssertTrue(markdown.contains("First-week scorecard: fame-onboarding-scorecard-20260610-1030.md"))
        XCTAssertTrue(markdown.contains("Daily brief: fame-onboarding-daily-brief-20260610-1030.md"))
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("`open-latest-onboarding-suite`"))
    }

    func testFameOnboardingScorecardMarkdownIncludesProgressCadenceAndCommands() {
        let markdown = AppDelegate.fameOnboardingScorecardMarkdown(
            day: 4,
            windowDays: 7,
            completedDays: 3,
            currentStreak: 2,
            bestStreak: 5,
            recommendedCommandID: "run-fame-cadence-autopilot-loop",
            backupCommandID: "run-fame-cadence-momentum-brief",
            now: Date(timeIntervalSince1970: 1_717_977_600),
            timeZone: TimeZone(secondsFromGMT: 0) ?? .current
        )

        XCTAssertTrue(markdown.contains("# Fluid Reader First-Week Fame Scorecard"))
        XCTAssertTrue(markdown.contains("Day 4 of 7"))
        XCTAssertTrue(markdown.contains("Date: 2024-06-10"))
        XCTAssertTrue(markdown.contains("Completed onboarding days: 3/7"))
        XCTAssertTrue(markdown.contains("Remaining onboarding days: 4"))
        XCTAssertTrue(markdown.contains("Current streak: x2"))
        XCTAssertTrue(markdown.contains("Best streak: x5"))
        XCTAssertTrue(markdown.contains("Next milestone: x3 (1 run away)"))
        XCTAssertTrue(markdown.contains("`Run Cadence Autopilot Loop` (`run-fame-cadence-autopilot-loop`)"))
        XCTAssertTrue(markdown.contains("`Run Cadence Momentum Brief` (`run-fame-cadence-momentum-brief`)"))
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
    }

    func testCadenceExecutionKitCommandMomentumBadgeTitleReflectsCurrentAndReset() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumBadgeTitle(
                currentStreak: 4,
                bestStreak: 7
            ),
            "x4"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumBadgeTitle(
                currentStreak: 0,
                bestStreak: 7
            ),
            "Reset"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumBadgeTitle(
                currentStreak: 0,
                bestStreak: 0
            ),
            "Ready"
        )
    }

    func testCadenceExecutionKitCommandMomentumSymbolNameUsesTieredSignals() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: 11,
                bestStreak: 11
            ),
            "trophy.fill"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: 6,
                bestStreak: 8
            ),
            "rocket.fill"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: 2,
                bestStreak: 4
            ),
            "bolt.fill"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: 0,
                bestStreak: 4
            ),
            "arrow.counterclockwise.circle"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: 0,
                bestStreak: 0
            ),
            "bolt.badge.clock"
        )
    }

    func testCadenceExecutionKitCommandMilestoneUsesTopPickThresholds() {
        XCTAssertNil(AppDelegate.cadenceExecutionKitCommandMilestone(for: 2))
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandMilestone(for: 3), 3)
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandMilestone(for: 5), 5)
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandMilestone(for: 10), 10)
        XCTAssertNil(AppDelegate.cadenceExecutionKitCommandMilestone(for: 11))
        XCTAssertEqual(AppDelegate.cadenceExecutionKitCommandMilestone(for: 15), 15)
    }

    func testCadenceExecutionKitCommandMilestoneCopyMatchesUIFeedbackText() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMilestoneTitle(5),
            "Cadence Kit Streak x5"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitCommandMilestonePetMessage(5),
            "Cadence execution streak x5. Run Cadence Autopilot Loop toward x10."
        )
    }

    func testCadenceExecutionKitAutopilotCueFormatsResetAndMilestonePrompts() throws {
        XCTAssertNil(
            AppDelegate.cadenceExecutionKitAutopilotCue(
                previousStreak: 3,
                nextStreak: 3,
                bestStreak: 7,
                milestone: nil,
                nextMoveLabel: "Recovery Sprint"
            )
        )

        let resetCue = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitAutopilotCue(
                previousStreak: 4,
                nextStreak: 0,
                bestStreak: 7,
                milestone: nil,
                nextMoveLabel: "Recovery Sprint"
            )
        )
        XCTAssertEqual(resetCue.title, "Cadence reset · Autopilot rebuild")
        XCTAssertEqual(
            resetCue.subtitle,
            "Best x7 saved · run Cadence Autopilot Loop (Recovery Sprint) now."
        )
        XCTAssertEqual(
            resetCue.petMessage,
            "Cadence streak reset. Best x7 saved. Run Cadence Autopilot Loop now."
        )
        XCTAssertEqual(resetCue.statusSymbol, "arrow.counterclockwise.circle.fill")
        XCTAssertTrue(resetCue.isRecovery)
        XCTAssertEqual(resetCue.token, "reset")
        XCTAssertEqual(resetCue.tier, .recovery)

        let milestoneCue = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitAutopilotCue(
                previousStreak: 4,
                nextStreak: 5,
                bestStreak: 7,
                milestone: 5,
                nextMoveLabel: "Recovery Sprint"
            )
        )
        XCTAssertEqual(milestoneCue.title, "Cadence milestone x5")
        XCTAssertEqual(
            milestoneCue.subtitle,
            "Momentum locked · Run Cadence Autopilot Loop: Recovery Sprint toward x10 in 5 runs."
        )
        XCTAssertEqual(
            milestoneCue.petMessage,
            "Cadence execution streak x5. Run Cadence Autopilot Loop toward x10. Momentum is building."
        )
        XCTAssertEqual(milestoneCue.statusSymbol, "rocket.fill")
        XCTAssertFalse(milestoneCue.isRecovery)
        XCTAssertEqual(milestoneCue.token, "milestone-5")
        XCTAssertEqual(milestoneCue.tier, .momentum)

        let trophyCue = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitAutopilotCue(
                previousStreak: 9,
                nextStreak: 10,
                bestStreak: 10,
                milestone: 10,
                nextMoveLabel: "Spotlight Pack"
            )
        )
        XCTAssertEqual(trophyCue.title, "Cadence milestone x10 · Breakout")
        XCTAssertEqual(
            trophyCue.subtitle,
            "Breakout unlocked · Run Cadence Autopilot Loop: Spotlight Pack toward x15 in 5 runs."
        )
        XCTAssertEqual(
            trophyCue.petMessage,
            "Cadence execution streak x10. Run Cadence Autopilot Loop toward x15. Breakout unlocked. Keep the streak hot."
        )
        XCTAssertEqual(trophyCue.statusSymbol, "trophy.fill")
        XCTAssertEqual(trophyCue.token, "milestone-10")
        XCTAssertEqual(trophyCue.tier, .breakout)
    }

    func testCadenceExecutionKitAutopilotCueTierRanksRecoveryRestartMomentumBreakoutAndFameSurge() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueTier(
                previousStreak: 7,
                nextStreak: 0,
                bestStreak: 12,
                milestone: nil
            ),
            .recovery
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueTier(
                previousStreak: 2,
                nextStreak: 3,
                bestStreak: 3,
                milestone: 3
            ),
            .restart
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueTier(
                previousStreak: 4,
                nextStreak: 5,
                bestStreak: 8,
                milestone: 5
            ),
            .momentum
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueTier(
                previousStreak: 9,
                nextStreak: 10,
                bestStreak: 10,
                milestone: 10
            ),
            .breakout
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueTier(
                previousStreak: 24,
                nextStreak: 25,
                bestStreak: 25,
                milestone: 25
            ),
            .fameSurge
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueTier(
                previousStreak: 19,
                nextStreak: 20,
                bestStreak: 30,
                milestone: 20
            ),
            .fameSurge
        )
    }

    func testCadenceExecutionKitAutopilotCelebrationIntensityTitleAndTokenNormalizeLevels() {
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityTitle(0),
            "Calm"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityTitle(1),
            "Balanced"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityTitle(2),
            "Epic"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityTitle(9),
            "Balanced"
        )

        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityToken(0),
            "calm"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityToken(1),
            "balanced"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityToken(2),
            "epic"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityToken(99),
            "balanced"
        )
    }

    func testCadenceExecutionKitAutopilotCueFameSurgeCopyEscalatesAtMilestone25() throws {
        let fameCue = try XCTUnwrap(
            AppDelegate.cadenceExecutionKitAutopilotCue(
                previousStreak: 24,
                nextStreak: 25,
                bestStreak: 25,
                milestone: 25,
                nextMoveLabel: "Operator Dashboard"
            )
        )

        XCTAssertEqual(fameCue.title, "Cadence milestone x25 · Fame Surge")
        XCTAssertEqual(
            fameCue.subtitle,
            "Fame surge unlocked · Run Cadence Autopilot Loop: Operator Dashboard toward x30 in 5 runs."
        )
        XCTAssertEqual(
            fameCue.petMessage,
            "Cadence execution streak x25. Run Cadence Autopilot Loop toward x30. Fame surge unlocked. Ship the next move now."
        )
        XCTAssertEqual(fameCue.tier, .fameSurge)
        XCTAssertEqual(fameCue.token, "milestone-25")
    }

    func testCadenceExecutionKitAutopilotCueCooldownHelpersDedupByToken() {
        let now = Date(timeIntervalSince1970: 2_000)

        XCTAssertTrue(
            AppDelegate.shouldSurfaceCadenceExecutionKitAutopilotCue(
                lastCueAt: nil,
                lastCueToken: nil,
                nextCueToken: "reset",
                now: now,
                cooldown: 45
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceCadenceExecutionKitAutopilotCue(
                lastCueAt: now.addingTimeInterval(-10),
                lastCueToken: "milestone-3",
                nextCueToken: "milestone-5",
                now: now,
                cooldown: 45
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceCadenceExecutionKitAutopilotCue(
                lastCueAt: now.addingTimeInterval(-20),
                lastCueToken: "reset",
                nextCueToken: "reset",
                now: now,
                cooldown: 45
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceCadenceExecutionKitAutopilotCue(
                lastCueAt: now.addingTimeInterval(-45),
                lastCueToken: "reset",
                nextCueToken: "reset",
                now: now,
                cooldown: 45
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceCadenceExecutionKitAutopilotCue(
                lastCueAt: now.addingTimeInterval(-2),
                lastCueToken: "reset",
                nextCueToken: "reset",
                now: now,
                cooldown: 0
            )
        )

        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitAutopilotCueCooldownRemainingSeconds(
                lastCueAt: now.addingTimeInterval(-20.2),
                lastCueToken: "reset",
                nextCueToken: "reset",
                now: now,
                cooldown: 45
            ),
            25
        )
        XCTAssertNil(
            AppDelegate.cadenceExecutionKitAutopilotCueCooldownRemainingSeconds(
                lastCueAt: now.addingTimeInterval(-20),
                lastCueToken: "milestone-3",
                nextCueToken: "reset",
                now: now,
                cooldown: 45
            )
        )
        XCTAssertNil(
            AppDelegate.cadenceExecutionKitAutopilotCueCooldownRemainingSeconds(
                lastCueAt: now.addingTimeInterval(-60),
                lastCueToken: "reset",
                nextCueToken: "reset",
                now: now,
                cooldown: 45
            )
        )
    }

    func testNextMoveCadenceStepCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveCadenceStepCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveCadenceStepCopyOutcomeReturnsMissingStepForMalformedHandoff() {
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            AppDelegate.nextMoveCadenceStepCopyOutcome(handoffMarkdown: malformedHandoff),
            .missingCadenceStep
        )
    }

    func testNextMoveCadenceStepCopyOutcomeReturnsReadyStepForValidHandoff() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-escalation-nudge",
            commandLabel: "Escalation Nudge",
            signal: FamePulseAlertSignal(
                riskLevel: "High",
                mustShipAlert: "MUST SHIP in next 2h",
                streakDays: 2,
                daysSinceLastSnapshot: 1,
                leadExperiment: "Distribution Remix"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Medium",
                toRiskLevel: "High",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "High",
                scoreDelta: -4,
                title: "Daily Scorecard: High",
                detail: "Risk is escalating.",
                recommendation: "Run Fame Recovery Sprint",
                nextActionTitle: "Run Fame Recovery Sprint",
                nextActionSummary: "Stabilize in the next hour.",
                recommendsRecovery: true
            )
        )

        let outcome = AppDelegate.nextMoveCadenceStepCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let firstStep) = outcome else {
            XCTFail("Expected ready cadence step, got \(outcome)")
            return
        }

        XCTAssertTrue(firstStep.contains("First Cadence Step (0-15m):"))
        XCTAssertTrue(firstStep.contains("Channel:"))
        XCTAssertTrue(firstStep.contains("Draft:"))
        XCTAssertTrue(firstStep.contains("Cadence focus:"))
        XCTAssertTrue(firstStep.contains("Next (15-30m):"))
    }

    func testNextMoveCadencePostCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveCadencePostCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveCadencePostCopyOutcomeReturnsMissingCadenceForMalformedHandoff() {
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            AppDelegate.nextMoveCadencePostCopyOutcome(handoffMarkdown: malformedHandoff),
            .missingCadenceStep
        )
    }

    func testNextMoveCadencePostCopyOutcomeReturnsReadyPostForValidHandoff() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let outcome = AppDelegate.nextMoveCadencePostCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let post) = outcome else {
            XCTFail("Expected ready cadence post, got \(outcome)")
            return
        }

        XCTAssertFalse(post.isEmpty)
        XCTAssertFalse(post.contains("First Cadence Step (0-15m):"))
        XCTAssertFalse(post.contains("Channel:"))
        XCTAssertFalse(post.contains("Cadence focus:"))
    }

    func testNextMoveCadencePostCopyOutcomeCopiesExactDraftOnly() {
        let expectedPost = "Ship now: proof loop live; reply with your top metric."
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): \(expectedPost)
        LinkedIn draft: Founder ops update placeholder.
        Checklist comment draft: Artifact link placeholder.
        """

        let outcome = AppDelegate.nextMoveCadencePostCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let post) = outcome else {
            XCTFail("Expected ready cadence post, got \(outcome)")
            return
        }

        XCTAssertEqual(post, expectedPost)
        XCTAssertFalse(post.contains("\n"))
    }

    func testNextMoveCadencePostCopyOutcomeReturnsMissingDraftWhenDraftLineIsEmpty() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280):
        LinkedIn draft: Founder ops update placeholder.
        Checklist comment draft: Artifact link placeholder.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveCadencePostCopyOutcome(handoffMarkdown: handoff),
            .missingDraft
        )
    }

    func testNextMoveCadencePostQueueCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveCadencePostQueueCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveCadencePostQueueCopyOutcomeReturnsReadyQueueForValidHandoff() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let outcome = AppDelegate.nextMoveCadencePostQueueCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let post, let queue) = outcome else {
            XCTFail("Expected ready cadence post queue, got \(outcome)")
            return
        }

        XCTAssertFalse(post.isEmpty)
        XCTAssertTrue(queue.contains("Cadence Post Queue (Next 30m):"))
        XCTAssertTrue(queue.contains("Post Now (copied to clipboard):"))
        XCTAssertTrue(queue.contains(post))
        XCTAssertTrue(queue.contains("Launch Now Sequence (Next 30m):"))
        XCTAssertTrue(queue.contains("Posting Checklist:"))
    }

    func testNextMoveCadencePostQueueCopyOutcomeReturnsMissingDraftWhenFollowupDraftIsEmpty() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship now: proof loop live.
        Bluesky draft (<=300): Follow-up cue is ready.
        LinkedIn draft:
        Checklist comment draft: Artifact link placeholder.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveCadencePostQueueCopyOutcome(handoffMarkdown: handoff),
            .missingDraft
        )
    }

    func testNextMoveReplyLadderCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveReplyLadderCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveReplyLadderCopyOutcomeReturnsReadyLadderForValidHandoff() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let outcome = AppDelegate.nextMoveReplyLadderCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let ladder) = outcome else {
            XCTFail("Expected ready reply ladder, got \(outcome)")
            return
        }

        XCTAssertTrue(ladder.contains("Next-Move Reply Ladder (First 30m):"))
        XCTAssertTrue(ladder.contains("1) Context opener"))
        XCTAssertTrue(ladder.contains("2) Operator prompt"))
        XCTAssertTrue(ladder.contains("3) Channel calibration"))
        XCTAssertTrue(ladder.contains("4) Proof request"))
        XCTAssertTrue(ladder.contains("5) Close + CTA"))
    }

    func testNextMoveReplyLadderCopyOutcomeReturnsMissingDraftWhenChannelDraftIsEmpty() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship now: proof loop live.
        Bluesky draft (<=300):
        LinkedIn draft: Founder ops update placeholder.
        Checklist comment draft: Artifact link placeholder.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveReplyLadderCopyOutcome(handoffMarkdown: handoff),
            .missingDraft
        )
    }

    func testNextMoveCadenceExecutionKitCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveCadenceExecutionKitCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveCadenceExecutionKitCopyOutcomeReturnsReadyKitForValidHandoff() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let outcome = AppDelegate.nextMoveCadenceExecutionKitCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let post, let kit) = outcome else {
            XCTFail("Expected ready cadence execution kit, got \(outcome)")
            return
        }

        XCTAssertFalse(post.isEmpty)
        XCTAssertTrue(kit.contains("Cadence Execution Kit (Next 30m):"))
        XCTAssertTrue(kit.contains("Post Now (copied to clipboard):"))
        XCTAssertTrue(kit.contains("Cadence Post Queue (Next 30m):"))
        XCTAssertTrue(kit.contains("Next-Move Reply Ladder (First 30m):"))
        XCTAssertTrue(kit.contains("Execution Checklist:"))
    }

    func testNextMoveCadenceExecutionKitCopyOutcomeReturnsMissingDraftWhenChannelDraftIsEmpty() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship now: proof loop live.
        Bluesky draft (<=300):
        LinkedIn draft: Founder ops update placeholder.
        Checklist comment draft: Artifact link placeholder.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveCadenceExecutionKitCopyOutcome(handoffMarkdown: handoff),
            .missingDraft
        )
    }

    func testNextMoveChannelDraftCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveChannelDraftCopyOutcome(channel: .x, handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveChannelDraftCopyOutcomeReturnsMissingDraftForMalformedHandoff() {
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            AppDelegate.nextMoveChannelDraftCopyOutcome(channel: .bluesky, handoffMarkdown: malformedHandoff),
            .missingDraft
        )
    }

    func testNextMoveChannelDraftCopyOutcomeReturnsReadyDraftPerChannel() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let xOutcome = AppDelegate.nextMoveChannelDraftCopyOutcome(channel: .x, handoffMarkdown: handoff)
        guard case .ready(let xDraft) = xOutcome else {
            XCTFail("Expected ready X draft, got \(xOutcome)")
            return
        }
        XCTAssertFalse(xDraft.isEmpty)
        XCTAssertTrue(xDraft.contains("Command Center"))

        let blueskyOutcome = AppDelegate.nextMoveChannelDraftCopyOutcome(channel: .bluesky, handoffMarkdown: handoff)
        guard case .ready(let blueskyDraft) = blueskyOutcome else {
            XCTFail("Expected ready Bluesky draft, got \(blueskyOutcome)")
            return
        }
        XCTAssertFalse(blueskyDraft.isEmpty)
        XCTAssertTrue(blueskyDraft.contains("Pulse Medium"))

        let linkedInOutcome = AppDelegate.nextMoveChannelDraftCopyOutcome(channel: .linkedIn, handoffMarkdown: handoff)
        guard case .ready(let linkedInDraft) = linkedInOutcome else {
            XCTFail("Expected ready LinkedIn draft, got \(linkedInOutcome)")
            return
        }
        XCTAssertFalse(linkedInDraft.isEmpty)
        XCTAssertTrue(linkedInDraft.contains("Founder ops update"))
    }

    func testNextMoveBestChannelDraftCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelDraftCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveBestChannelDraftCopyOutcomeReturnsMissingCadenceForMalformedHandoff() {
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelDraftCopyOutcome(handoffMarkdown: malformedHandoff),
            .missingCadenceStep
        )
    }

    func testNextMoveBestChannelDraftCopyOutcomeReturnsReadyDraftForFirstCadenceChannel() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship the X proof loop now.
        Bluesky draft (<=300): Blue proof loop shipped today.
        LinkedIn draft: LinkedIn proof loop and results.
        Checklist comment draft: Checklist comment for handoff.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelDraftCopyOutcome(handoffMarkdown: handoff),
            .ready(channel: .x, draft: "Ship the X proof loop now.")
        )
    }

    func testNextMoveBestChannelLaunchPackCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveBestChannelLaunchPackCopyOutcomeReturnsMissingCadenceForMalformedHandoff() {
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            AppDelegate.nextMoveBestChannelLaunchPackCopyOutcome(handoffMarkdown: malformedHandoff),
            .missingCadenceStep
        )
    }

    func testNextMoveBestChannelLaunchPackCopyOutcomeReturnsReadyPackForFirstCadenceChannel() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let outcome = AppDelegate.nextMoveBestChannelLaunchPackCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let channel, let post, let pack) = outcome else {
            XCTFail("Expected ready best channel launch pack, got \(outcome)")
            return
        }

        XCTAssertEqual(channel, .x)
        XCTAssertFalse(post.isEmpty)
        XCTAssertTrue(pack.contains("Best Channel Launch Pack (Next 30m):"))
        XCTAssertTrue(pack.contains("Primary channel: X"))
        XCTAssertTrue(pack.contains("Post Now (copied to clipboard):"))
        XCTAssertTrue(pack.contains("First Cadence Step:"))
        XCTAssertTrue(pack.contains("Cross-Channel Follow-up Sequence:"))
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelDraftForTestingShowsRecoveryPromptWhenHandoffMissing() {
        let appDelegate = AppDelegate()

        XCTAssertEqual(
            appDelegate.copyLatestNextMoveBestChannelDraftForTesting(handoffMarkdown: nil),
            .missingHandoff
        )
        let feedback = appDelegate.bestChannelDraftCopyFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "No saved next move handoff yet.")
        XCTAssertEqual(feedback.petMessage, "Run Fame Next Move first.")
        XCTAssertEqual(feedback.petMood, .ready)
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelDraftForTestingShowsCadencePromptWhenStepMissing() {
        let appDelegate = AppDelegate()
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            appDelegate.copyLatestNextMoveBestChannelDraftForTesting(handoffMarkdown: malformedHandoff),
            .missingCadenceStep
        )
        let feedback = appDelegate.bestChannelDraftCopyFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "Latest handoff missing first cadence channel.")
        XCTAssertEqual(feedback.petMessage, "Run Fame Next Move again.")
        XCTAssertEqual(feedback.petMood, .ready)
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelDraftForTestingCopiesReadyDraftAndClearsError() {
        let appDelegate = AppDelegate()
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship the X proof loop now.
        Bluesky draft (<=300): Blue proof loop shipped today.
        LinkedIn draft: LinkedIn proof loop and results.
        Checklist comment draft: Checklist comment for handoff.
        """

        XCTAssertEqual(
            appDelegate.copyLatestNextMoveBestChannelDraftForTesting(handoffMarkdown: handoff),
            .ready(channel: .x, draft: "Ship the X proof loop now.")
        )
        let feedback = appDelegate.bestChannelDraftCopyFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(feedback.petMessage, "Best channel draft ready (X).")
        XCTAssertFalse(feedback.petMessage.contains("Copied best channel draft (X)."))
        XCTAssertEqual(feedback.petMood, .happy)
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelLaunchPackForTestingShowsRecoveryPromptWhenHandoffMissing() {
        let appDelegate = AppDelegate()

        XCTAssertEqual(
            appDelegate.copyLatestNextMoveBestChannelLaunchPackForTesting(handoffMarkdown: nil),
            .missingHandoff
        )
        let feedback = appDelegate.bestChannelDraftCopyFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "No saved next move handoff yet.")
        XCTAssertEqual(feedback.petMessage, "Run Fame Next Move first.")
        XCTAssertEqual(feedback.petMood, .ready)
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelLaunchPackForTestingCopiesReadyPackAndClearsError() {
        let appDelegate = AppDelegate()
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-command-center",
            commandLabel: "Command Center",
            signal: FamePulseAlertSignal(
                riskLevel: "Medium",
                mustShipAlert: "Ship one loop in next 2h",
                streakDays: 3,
                daysSinceLastSnapshot: 0,
                leadExperiment: "Builder Thread"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Low",
                toRiskLevel: "Medium",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "Medium",
                scoreDelta: 2,
                title: "Daily Scorecard: Medium",
                detail: "Watchlist-level risk.",
                recommendation: "Run Daily Fame Checkpoint",
                nextActionTitle: "Run Daily Fame Checkpoint",
                nextActionSummary: "Tighten execution and monitor risk.",
                recommendsRecovery: false
            )
        )

        let outcome = appDelegate.copyLatestNextMoveBestChannelLaunchPackForTesting(handoffMarkdown: handoff)
        guard case .ready(let channel, let post, let pack) = outcome else {
            XCTFail("Expected ready best channel launch pack, got \(outcome)")
            return
        }
        XCTAssertEqual(channel, .x)
        XCTAssertFalse(post.isEmpty)
        XCTAssertTrue(pack.contains("Best Channel Launch Pack (Next 30m):"))

        let feedback = appDelegate.bestChannelDraftCopyFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(feedback.petMessage, "Best channel launch pack ready (X).")
        XCTAssertFalse(feedback.petMessage.contains("Copied best channel post (X)."))
        XCTAssertEqual(feedback.petMood, .happy)
    }

    func testNextMoveLaunchNowSequenceCopyOutcomeReturnsMissingHandoffWhenNoHandoffExists() {
        XCTAssertEqual(
            AppDelegate.nextMoveLaunchNowSequenceCopyOutcome(handoffMarkdown: nil),
            .missingHandoff
        )
    }

    func testNextMoveLaunchNowSequenceCopyOutcomeReturnsMissingCadenceForMalformedHandoff() {
        let malformedHandoff = """
        # Founder Fame Next Move Handoff

        Date: 2026-06-10
        Selected command: Recovery Sprint (`run-fame-recovery-sprint`)
        """

        XCTAssertEqual(
            AppDelegate.nextMoveLaunchNowSequenceCopyOutcome(handoffMarkdown: malformedHandoff),
            .missingCadenceStep
        )
    }

    func testNextMoveCadencePrimaryChannelFromHandoffReturnsFallbackXWhenDraftsExist() {
        let handoff = """
        # Founder Fame Next Move Handoff

        X draft (<=280): Ship the X proof loop now.
        Bluesky draft (<=300): Blue proof loop shipped today.
        LinkedIn draft: LinkedIn proof loop and results.
        Checklist comment draft: Checklist comment for handoff.
        """

        XCTAssertEqual(
            AppDelegate.nextMoveCadencePrimaryChannel(handoffMarkdown: handoff),
            .x
        )
    }

    func testNextMoveCadencePrimaryChannelTokenMapsKnownChannels() {
        XCTAssertEqual(AppDelegate.nextMoveCadencePrimaryChannelToken(.x), "x")
        XCTAssertEqual(AppDelegate.nextMoveCadencePrimaryChannelToken(.bluesky), "bluesky")
        XCTAssertEqual(AppDelegate.nextMoveCadencePrimaryChannelToken(.linkedIn), "linkedin")
    }

    func testNextMoveLaunchNowSequenceCopyOutcomeReturnsReadySequenceForValidHandoff() {
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: "run-fame-escalation-nudge",
            commandLabel: "Escalation Nudge",
            signal: FamePulseAlertSignal(
                riskLevel: "High",
                mustShipAlert: "MUST SHIP in next 2h",
                streakDays: 2,
                daysSinceLastSnapshot: 1,
                leadExperiment: "Distribution Remix"
            ),
            transition: FamePulseRiskTransition(
                fromRiskLevel: "Medium",
                toRiskLevel: "High",
                isEscalation: true
            ),
            scorecard: FameDailyScorecardState(
                riskLevel: "High",
                scoreDelta: -4,
                title: "Daily Scorecard: High",
                detail: "Risk is escalating.",
                recommendation: "Run Fame Recovery Sprint",
                nextActionTitle: "Run Fame Recovery Sprint",
                nextActionSummary: "Stabilize in the next hour.",
                recommendsRecovery: true
            )
        )

        let outcome = AppDelegate.nextMoveLaunchNowSequenceCopyOutcome(handoffMarkdown: handoff)
        guard case .ready(let sequence) = outcome else {
            XCTFail("Expected ready launch now sequence, got \(outcome)")
            return
        }

        XCTAssertTrue(sequence.contains("Launch Now Sequence (Next 30m):"))
        XCTAssertTrue(sequence.contains("1) 0-15m:"))
        XCTAssertTrue(sequence.contains("First Cadence Step (0-15m):"))
        XCTAssertTrue(sequence.contains("2) 15-30m ("))
        XCTAssertTrue(sequence.contains("3) 15-30m ("))
    }

    func testFameLaunchCountdownAlertTitleFormatsCountdown() {
        let status = FameLaunchCountdownStatus(
            countdown: "T-20m",
            nextAction: "T-20m: Publish X primary draft",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchCountdownAlertTitle(status),
            "Launch Countdown: T-20m"
        )
    }

    func testFameLaunchCountdownAlertSubtitleIncludesNextActionRiskAndRoute() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+10m",
            nextAction: "T+10m: Reply ladder seed",
            launchRoute: "Reply Engine",
            pulseRisk: "Medium"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchCountdownAlertSubtitle(status),
            "Urgency Hot (overdue by 10m) · Next: T+10m: Reply ladder seed · Risk Medium · Route Reply Engine"
        )
    }

    func testFameLaunchCountdownMinutesParsesSignedLabels() {
        XCTAssertEqual(AppDelegate.fameLaunchCountdownMinutes("T-20m"), -20)
        XCTAssertEqual(AppDelegate.fameLaunchCountdownMinutes("T+10m"), 10)
        XCTAssertEqual(AppDelegate.fameLaunchCountdownMinutes("T+0m"), 0)
        XCTAssertNil(AppDelegate.fameLaunchCountdownMinutes("20m"))
    }

    func testFameLaunchCountdownUrgencyCanClassifyPrepAndOverdueStates() {
        let prepStatus = FameLaunchCountdownStatus(
            countdown: "T-35m",
            nextAction: "T-35m: Warm up",
            launchRoute: "Builder Thread",
            pulseRisk: "Low"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchCountdownUrgency(prepStatus),
            "Urgency Prep (launch in 35m)"
        )

        let overdueStatus = FameLaunchCountdownStatus(
            countdown: "T+32m",
            nextAction: "T+32m: Respond now",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchCountdownUrgency(overdueStatus),
            "Urgency Critical (overdue by 32m)"
        )
    }

    func testFameLaunchCountdownMenuTitleIncludesUrgencyStatus() {
        let status = FameLaunchCountdownStatus(
            countdown: "T-8m",
            nextAction: "T-8m: Prep final post",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchCountdownMenuTitle(status),
            "Launch Alert: Urgency Ready (launch in 8m)"
        )
    }

    func testFameLaunchAlertMenuTitleCanAppendRecoveryMomentumHint() {
        let status = FameLaunchCountdownStatus(
            countdown: "T-8m",
            nextAction: "T-8m: Prep final post",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchAlertMenuTitle(
                launchStatus: status,
                onboardingRecoveryHint: "Onboarding recovery: 1 artifact left"
            ),
            "Launch Alert: Urgency Ready (launch in 8m) · Onboarding recovery: 1 artifact left"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchAlertMenuTitle(
                launchStatus: nil,
                onboardingRecoveryHint: "Onboarding recovery: gap closed"
            ),
            "Launch Alert: Run Fame Launch Countdown · Onboarding recovery: gap closed"
        )
    }

    func testLaunchControlHealthCardHelpersCoverRiskReadyAndFallback() {
        let riskStatus = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Push replies",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardTitle(launchStatus: riskStatus),
            "Launch Health: Risk · T+18m"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSubtitle(launchStatus: riskStatus),
            "Urgency High (overdue by 18m) · Next: T+18m: Push replies · click: Run Launch Rescue Burst"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSystemImage(launchStatus: riskStatus),
            "exclamationmark.triangle.fill"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthActionCommandID(launchStatus: riskStatus),
            "run-fame-launch-rescue-burst"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMenuTitle(launchStatus: riskStatus),
            "Launch Health: Risk · T+18m · Click: Run Launch Rescue Burst"
        )

        let readyStatus = FameLaunchCountdownStatus(
            countdown: "T-12m",
            nextAction: "T-12m: Queue thread",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardTitle(launchStatus: readyStatus),
            "Launch Health: Ready · T-12m"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSystemImage(launchStatus: readyStatus),
            "checkmark.shield.fill"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthActionCommandID(launchStatus: readyStatus),
            "run-fame-launch-control-brief"
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthCardTitle(launchStatus: nil),
            "Launch Health: Watch"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthActionCommandID(launchStatus: nil),
            "run-fame-launch-countdown"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthActionTitle(commandID: "run-fame-launch-rescue-burst"),
            "Run Launch Rescue Burst"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSubtitle(launchStatus: nil),
            "Run `Run Fame Launch Day Script`, then `Run Fame Launch Countdown`."
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMenuTitle(launchStatus: nil),
            "Launch Health: Watch · Click: Run Fame Launch Countdown"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSystemImage(launchStatus: nil),
            "eye.circle.fill"
        )
    }

    func testLaunchControlHealthCardSubtitleCanIncludePulseAndTransitionStatus() {
        let riskStatus = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Push replies",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSubtitle(
                launchStatus: riskStatus,
                statusTitle: "Pulse suppressed 40s (Watch -> Risk) · Today W->R 2 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +0.8 · R->Ready -0.3"
            ),
            "Urgency High (overdue by 18m) · Next: T+18m: Push replies · Pulse suppressed 40s (Watch -> Risk) · Today W->R 2 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +0.8 · R->Ready -0.3 · click: Run Launch Rescue Burst"
        )
    }

    func testLaunchControlStatusTitleWithFollowupMomentumCanAppendRescueFragment() {
        XCTAssertEqual(
            AppDelegate.launchControlStatusTitleWithFollowupMomentum(
                "Pulse ready (1m) · Today W->R 2 · R->Ready 1 · Worsening ↓",
                followupMomentumBadge: nil
            ),
            "Pulse ready (1m) · Today W->R 2 · R->Ready 1 · Worsening ↓"
        )
        XCTAssertEqual(
            AppDelegate.launchControlStatusTitleWithFollowupMomentum(
                "Pulse ready (1m) · Today W->R 2 · R->Ready 1 · Worsening ↓",
                followupMomentumBadge: "Recovery x2 · CD 30m · Steady →"
            ),
            "Pulse ready (1m) · Today W->R 2 · R->Ready 1 · Worsening ↓ · Rescue Recovery x2 · CD 30m · Steady →"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefActionSubtitle(
                "Refresh launch countdown + save + copy launch control brief",
                followupMomentumBadge: "Recovery x2 · CD 30m · Steady →"
            ),
            "Refresh launch countdown + save + copy launch control brief · Rescue Recovery x2 · CD 30m · Steady →"
        )
    }

    func testLaunchRescueSnapshotMenuTitleCanAppendFollowupMomentumCue() {
        XCTAssertEqual(
            AppDelegate.launchRescueSnapshotMenuTitle(followupMomentumBadge: nil),
            "Copy Launch Rescue Snapshot"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueSnapshotMenuTitle(
                followupMomentumBadge: "Recovery x2 · CD 30m · Steady →"
            ),
            "Copy Launch Rescue Snapshot · Rescue Recovery x2 · CD 30m · Steady →"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueSnapshotMenuTitle(
                followupMomentumBadge: "Recovery x2 · CD 30m · Steady →",
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Copy Launch Rescue Snapshot · Route Burst · Self-Heal Missing x1 · Rescue Recovery x2 · CD 30m · Steady →"
        )
    }

    func testLaunchRescueAutoFollowupRunSummaryFormatsKnownAndFallbackStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRunSummary(
                commandID: nil,
                reasonToken: nil
            ),
            "No follow-up run recorded yet."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRunSummary(
                commandID: "run-fame-recovery-checklist",
                reasonToken: nil
            ),
            "Run Fame Recovery Checklist."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRunSummary(
                commandID: "run-fame-next-move-copy-drafts",
                reasonToken: "urgency-high"
            ),
            "Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation."
        )
    }

    func testLaunchRescueAutoFollowupAutoPressureActivityDetailFormatsSuccessAndFailure() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupAutoPressureActivityDetail(wasSuccessful: true),
            "run-fame-launch-rescue-followup-now-auto-pressure-persistence-success"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupAutoPressureActivityDetail(wasSuccessful: false),
            "run-fame-launch-rescue-followup-now-auto-pressure-persistence-failure"
        )
    }

    func testLaunchRescueAutoFollowupAutoActivityDetailNormalizesReasonAndOutcome() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupAutoActivityDetail(
                reasonToken: " urgency-high ",
                wasSuccessful: true
            ),
            "run-fame-launch-rescue-followup-now-auto-urgency-high-success"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupAutoActivityDetail(
                reasonToken: "unexpected-token",
                wasSuccessful: false
            ),
            "run-fame-launch-rescue-followup-now-auto-none-failure"
        )
    }

    func testLaunchRescueAutoFollowupArtifactsReadyMapsRouteFallbackRules() {
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "run-fame-launch-rescue-burst",
                hasLaunchRescueBurst: true,
                hasNextMoveHandoff: false,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "run-fame-launch-rescue-burst",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: true,
                hasLaunchControlBrief: true,
                hasRecoveryChecklist: true
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "run-fame-next-move-copy-drafts",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "run-fame-next-move-copy-drafts",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: false,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "run-fame-launch-control-brief",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: false,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: true,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "run-fame-recovery-checklist",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: false,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: true
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactsReady(
                routeCommandID: "unknown-route",
                hasLaunchRescueBurst: true,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: true,
                hasLaunchControlBrief: true,
                hasRecoveryChecklist: true
            )
        )
    }

    func testLaunchRescueAutoFollowupArtifactsMissingTracksRouteRepairGaps() {
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsMissing(
                routeCommandID: "run-fame-launch-rescue-burst",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: true,
                hasLaunchControlBrief: true,
                hasRecoveryChecklist: true
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsMissing(
                routeCommandID: "run-fame-next-move-copy-drafts",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactsMissing(
                routeCommandID: "run-fame-next-move-copy-drafts",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: true,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsMissing(
                routeCommandID: "run-fame-launch-control-brief",
                hasLaunchRescueBurst: true,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: true,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: true
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactsMissing(
                routeCommandID: "run-fame-recovery-checklist",
                hasLaunchRescueBurst: true,
                hasNextMoveHandoff: true,
                hasNextMoveDraftPack: true,
                hasLaunchControlBrief: true,
                hasRecoveryChecklist: false
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactsMissing(
                routeCommandID: "none",
                hasLaunchRescueBurst: false,
                hasNextMoveHandoff: false,
                hasNextMoveDraftPack: false,
                hasLaunchControlBrief: false,
                hasRecoveryChecklist: false
            )
        )
    }

    func testLaunchRescueAutoFollowupSelfHealActivityDetailNormalizesReasonRouteAndOutcome() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
                reasonToken: " urgency-high ",
                routeCommandID: "run-fame-next-move-copy-drafts",
                outcome: " healed "
            ),
            "run-fame-launch-rescue-followup-now-auto-self-heal-urgency-high-run-fame-next-move-copy-drafts-healed"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
                reasonToken: "unexpected",
                routeCommandID: "unexpected-route",
                outcome: "???"
            ),
            "run-fame-launch-rescue-followup-now-auto-self-heal-none-none-unknown"
        )
    }

    func testLaunchRescueAutoFollowupSelfHealSnapshotParsesContractAndNormalizesFields() {
        let recordedAt = Date(timeIntervalSince1970: 500_000)
        let snapshot = AppDelegate.launchRescueAutoFollowupSelfHealSnapshot(
            fromActivityDetail: " run-fame-launch-rescue-followup-now-auto-self-heal-urgency-high-run-fame-next-move-copy-drafts-healed ",
            recordedAt: recordedAt
        )
        XCTAssertEqual(snapshot?.reasonToken, "urgency-high")
        XCTAssertEqual(snapshot?.routeCommandID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(snapshot?.outcome, .healed)
        XCTAssertEqual(snapshot?.recordedAt, recordedAt)
        XCTAssertNil(
            AppDelegate.launchRescueAutoFollowupSelfHealSnapshot(
                fromActivityDetail: "run-fame-launch-rescue-followup-now-auto-self-heal-urgency-high-unknown-route-healed"
            )
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoFollowupSelfHealSnapshot(
                fromActivityDetail: "run-fame-launch-rescue-followup-now-auto-self-heal-urgency-high-run-fame-next-move-copy-drafts-bad-outcome"
            )
        )
    }

    func testLaunchRescueAutoFollowupSelfHealSnapshotRecencyAndStatusFormatting() {
        let now = Date(timeIntervalSince1970: 500_000)
        let snapshot = AppDelegate.LaunchRescueAutoFollowupSelfHealSnapshot(
            reasonToken: "urgency-high",
            routeCommandID: "run-fame-next-move-copy-drafts",
            outcome: .healed,
            recordedAt: now.addingTimeInterval(-120)
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupSelfHealBadge(snapshot),
            "Auto-Heal"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupSelfHealStatusTitle(snapshot, now: now),
            "Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Fame Next Move + Copy Draft Pack · Reason: Urgency High escalation. · Freshness 2m ago."
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupSelfHealSnapshotIsRecent(
                recordedAt: now.addingTimeInterval(-60),
                now: now,
                freshnessWindow: 900
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupSelfHealSnapshotIsRecent(
                recordedAt: now.addingTimeInterval(-(16 * 60)),
                now: now,
                freshnessWindow: 900
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupSelfHealSnapshotIsRecent(
                recordedAt: now.addingTimeInterval(120),
                now: now,
                freshnessWindow: 900,
                futureGraceWindow: 60
            )
        )
    }

    func testLaunchRescueAutoSelfHealAttentionIssueTokenAndMessageCoverHealthyStaleMismatchAndMissingStates() {
        let now = Date(timeIntervalSince1970: 500_000)
        let healthyDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "healed"
        )
        let healthyItems = [
            ActivityLogItem(
                id: UUID(),
                createdAt: now.addingTimeInterval(-90),
                category: "support",
                detail: healthyDetail
            )
        ]

        XCTAssertNil(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueToken(
                triggerReason: "urgency-critical",
                activityItems: healthyItems,
                now: now
            )
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoSelfHealAttentionNudgeMessage(
                triggerReason: "urgency-critical",
                activityItems: healthyItems,
                now: now
            )
        )

        let staleItems = [
            ActivityLogItem(
                id: UUID(),
                createdAt: now.addingTimeInterval(-(40 * 60)),
                category: "support",
                detail: healthyDetail
            )
        ]
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueToken(
                triggerReason: "urgency-critical",
                activityItems: staleItems,
                now: now
            ),
            "stale-urgency-critical-run-fame-launch-rescue-burst"
        )
        let staleMessage = AppDelegate.launchRescueAutoSelfHealAttentionNudgeMessage(
            triggerReason: "urgency-critical",
            activityItems: staleItems,
            now: now
        )
        XCTAssertEqual(
            staleMessage,
            "Launch Rescue Auto Self-Heal stale (40m ago.). Execute Run Launch Rescue Burst now."
        )

        let mismatchDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-high",
            routeCommandID: "run-fame-next-move-copy-drafts",
            outcome: "ready"
        )
        let mismatchItems = [
            ActivityLogItem(
                id: UUID(),
                createdAt: now.addingTimeInterval(-60),
                category: "support",
                detail: mismatchDetail
            )
        ]
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueToken(
                triggerReason: "urgency-critical",
                activityItems: mismatchItems,
                now: now
            ),
            "mismatch-urgency-critical-urgency-high"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionNudgeMessage(
                triggerReason: "urgency-critical",
                activityItems: mismatchItems,
                now: now
            ),
            "Launch Rescue Auto Self-Heal mismatch: latest Urgency High escalation. waiting for Urgency Critical escalation. Execute Run Launch Rescue Burst now."
        )

        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueToken(
                triggerReason: "urgency-critical",
                activityItems: [],
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-(9 * 60))
            ),
            "missing-urgency-critical"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionNudgeMessage(
                triggerReason: "urgency-critical",
                activityItems: [],
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-(9 * 60))
            ),
            "Launch Rescue Auto Self-Heal missing (9m ago.). Execute Run Launch Rescue Burst now."
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueToken(
                triggerReason: "urgency-critical",
                activityItems: [],
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-120)
            )
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoSelfHealAttentionNudgeMessage(
                triggerReason: "urgency-critical",
                activityItems: [],
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-120)
            )
        )
    }

    func testLaunchRescueAutoSelfHealAttentionRecommendedActionIDEscalatesByIssueSeverity() {
        let now = Date(timeIntervalSince1970: 500_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionRecommendedActionID(
                issueToken: "missing-urgency-high",
                triggerReason: "urgency-high",
                issueStreak: 1,
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-(9 * 60))
            ),
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionRecommendedActionID(
                issueToken: "missing-urgency-high",
                triggerReason: "urgency-high",
                issueStreak: 3,
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-(9 * 60))
            ),
            "run-fame-launch-rescue-burst"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionRecommendedActionID(
                issueToken: "mismatch-urgency-critical-urgency-high",
                triggerReason: "urgency-critical",
                issueStreak: 2,
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-(6 * 60))
            ),
            "run-fame-launch-rescue-burst"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionRecommendedActionID(
                issueToken: "stale-urgency-high-run-fame-next-move-copy-drafts",
                triggerReason: "urgency-high",
                issueStreak: 1,
                now: now,
                lastAutoTriggerAt: now.addingTimeInterval(-(40 * 60))
            ),
            "run-fame-next-move-copy-drafts"
        )
    }

    func testLaunchRescueAutoSelfHealAttentionSignalBadgeHighlightsEscalationRoute() {
        let now = Date(timeIntervalSince1970: 500_000)
        let highBadge = AppDelegate.launchRescueAutoSelfHealAttentionSignalBadge(
            issueToken: "missing-urgency-critical",
            triggerReason: "urgency-critical",
            issueStreak: 3,
            now: now,
            lastAutoTriggerAt: now.addingTimeInterval(-(22 * 60))
        )
        XCTAssertEqual(highBadge.title, "Self-Heal Missing x3")
        XCTAssertEqual(highBadge.tone, .high)
        XCTAssertEqual(highBadge.recommendedActionID, "run-fame-launch-rescue-burst")
        XCTAssertEqual(highBadge.recommendedActionTitle, "Run Launch Rescue Burst")
        XCTAssertTrue(highBadge.helpText.contains("Issue streak x3") == true)
        XCTAssertTrue(highBadge.helpText.contains("last trigger 22m ago.") == true)

        let mediumBadge = AppDelegate.launchRescueAutoSelfHealAttentionSignalBadge(
            issueToken: "stale-urgency-high-run-fame-next-move-copy-drafts",
            triggerReason: "urgency-high",
            issueStreak: 1,
            now: now,
            lastAutoTriggerAt: now.addingTimeInterval(-(14 * 60))
        )
        XCTAssertEqual(mediumBadge.title, "Self-Heal Stale x1")
        XCTAssertEqual(mediumBadge.tone, .medium)
        XCTAssertEqual(mediumBadge.recommendedActionID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(mediumBadge.recommendedActionTitle, "Run Fame Next Move + Copy Draft Pack")
        XCTAssertTrue(mediumBadge.helpText.contains("Urgency High escalation.") == true)
    }

    func testLaunchRescueAutoSelfHealAttentionNudgeGatingTracksConsecutiveIssuesAndCooldown() {
        let now = Date(timeIntervalSince1970: 500_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueStreakNext(
                currentIssueToken: nil,
                previousIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueStreak: 3
            ),
            0
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueStreakNext(
                currentIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueToken: nil,
                previousIssueStreak: 0
            ),
            1
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueStreakNext(
                currentIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueStreak: 1
            ),
            2
        )

        // Repeat observations inside the debounce window hold the streak so
        // rapid menu/status refreshes do not inflate escalation thresholds.
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueStreakNext(
                currentIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueStreak: 1,
                now: now,
                previousStreakUpdatedAt: now.addingTimeInterval(-10)
            ),
            1
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionIssueStreakNext(
                currentIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                previousIssueStreak: 1,
                now: now,
                previousStreakUpdatedAt: now.addingTimeInterval(
                    -AppDelegate.launchRescueAutoSelfHealAttentionStreakObservationInterval
                )
            ),
            2
        )

        XCTAssertFalse(
            AppDelegate.shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge(
                issueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                issueStreak: 1,
                lastNudgeAt: nil,
                lastNudgeIssueToken: nil,
                now: now,
                cooldown: 30 * 60,
                requiredConsecutiveCount: 2
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge(
                issueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                issueStreak: 2,
                lastNudgeAt: nil,
                lastNudgeIssueToken: nil,
                now: now,
                cooldown: 30 * 60,
                requiredConsecutiveCount: 2
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge(
                issueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                issueStreak: 3,
                lastNudgeAt: now.addingTimeInterval(-30),
                lastNudgeIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                now: now,
                cooldown: 60,
                requiredConsecutiveCount: 2
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge(
                issueToken: "mismatch-urgency-critical-urgency-high",
                issueStreak: 2,
                lastNudgeAt: now.addingTimeInterval(-30),
                lastNudgeIssueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                now: now,
                cooldown: 60,
                requiredConsecutiveCount: 2
            )
        )
    }

    func testLaunchRescueAutoSelfHealAttentionActivityDetailNormalizesIssueAndStreak() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionActivityDetail(
                issueToken: "stale-urgency-critical-run-fame-launch-rescue-burst",
                issueStreak: 3
            ),
            "run-fame-launch-rescue-self-heal-attention-stale-urgency-critical-run-fame-launch-rescue-burst-x3"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoSelfHealAttentionActivityDetail(
                issueToken: "mismatch-urgency-critical-urgency-high",
                issueStreak: 0
            ),
            "run-fame-launch-rescue-self-heal-attention-mismatch-urgency-critical-urgency-high-x1"
        )
    }

    func testLaunchRescueAutoFollowupArtifactIsFreshRequiresTimestampAndWindow() {
        let now = Date(timeIntervalSince1970: 500_000)

        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactIsFresh(
                modifiedAt: nil,
                now: now,
                freshnessWindow: 900
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactIsFresh(
                modifiedAt: now.addingTimeInterval(-600),
                now: now,
                freshnessWindow: 900
            )
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoFollowupArtifactIsFresh(
                modifiedAt: now.addingTimeInterval(-901),
                now: now,
                freshnessWindow: 900
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactIsFresh(
                modifiedAt: now.addingTimeInterval(30),
                now: now,
                freshnessWindow: 900
            )
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoFollowupArtifactIsFresh(
                modifiedAt: now.addingTimeInterval(-86_400),
                now: now,
                freshnessWindow: 0
            )
        )
    }

    func testLaunchRescueSnapshotMarkdownFormatsCanonicalLines() {
        let markdown = AppDelegate.launchRescueSnapshotMarkdown(
            autoTriggerSummary: "Urgency High escalation.",
            autoTriggerAtSummary: "2023-11-14T22:13:20Z",
            autoFollowupSummary: "Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation.",
            autoFollowupAtSummary: "2023-11-14T22:13:20Z",
            followupRouteDecisionStatusTitle: "Launch Rescue Auto Follow-up Route Decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack · Self-Heal Missing x1.",
            autoSelfHealStatusTitle: "Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Fame Next Move + Copy Draft Pack · Reason: Urgency High escalation. · Freshness 12m ago.",
            followupScoreboardStatusTitle: "Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago.",
            followupCoachStatusTitle: "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago.",
            followupMomentumStatusTitle: "Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →"
        )

        XCTAssertEqual(
            markdown,
            """
            - Auto trigger: Urgency High escalation.
            - Auto trigger time: 2023-11-14T22:13:20Z
            - Auto follow-up: Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation.
            - Auto follow-up time: 2023-11-14T22:13:20Z
            - Launch Rescue Auto Follow-up Route Decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack · Self-Heal Missing x1.
            - Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Fame Next Move + Copy Draft Pack · Reason: Urgency High escalation. · Freshness 12m ago.
            - Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago.
            - Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago.
            - Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →
            """
        )
    }

    func testLaunchControlBriefAndLaunchRescueSnapshotShareCanonicalStatusLines() {
        let autoTriggerSummary = "Urgency High escalation."
        let autoSelfHealStatusTitle =
            "Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Fame Next Move + Copy Draft Pack · Reason: Urgency High escalation. · Freshness 12m ago."
        let followupScoreboardStatusTitle =
            "Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago."
        let followupCoachStatusTitle =
            "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."
        let followupMomentumStatusTitle =
            "Launch Rescue Follow-up Momentum: Recovery x2 · CD 9/30m · Steady →"
        let followupRouteDecisionStatusTitle =
            "Launch Rescue Auto Follow-up Route Decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack · Self-Heal Missing x1."

        let brief = AppDelegate.launchControlBriefMarkdown(
            generatedAt: "2026-06-10 08:30",
            launchAlertTitle: "Launch Countdown: T+18m",
            launchAlertSubtitle: "Urgency High (overdue by 18m) · Next: Ship update",
            rescueAutoStatusTitle: "Launch Rescue Auto: Cooldown 12m",
            rescueAutoTriggerStatusTitle: "Launch Rescue Auto Trigger: \(autoTriggerSummary)",
            rescueAutoTriggerAtStatusTitle: "Launch Rescue Auto Trigger Time: 12m ago.",
            rescueAutoFollowupStatusTitle: "Launch Rescue Auto Follow-up: Priority window active. Run next move and ship the first block now.",
            rescueAutoFollowupRouteDecisionStatusTitle: followupRouteDecisionStatusTitle,
            rescueAutoSelfHealStatusTitle: autoSelfHealStatusTitle,
            rescueAutoFollowupScoreboardStatusTitle: followupScoreboardStatusTitle,
            rescueAutoFollowupCoachStatusTitle: followupCoachStatusTitle,
            rescueAutoFollowupMomentumStatusTitle: followupMomentumStatusTitle,
            thresholdAlertsStatusTitle: "Launch Threshold Alerts: Snoozed 12m",
            healthPulseStatusTitle: "Launch Health Pulse: Suppressed 32s for repeat Watch -> Risk.",
            healthTransitionCountsTitle: "Launch Health Transitions Today: Watch -> Risk 2 · Risk -> Ready 1 · Trend Worsening ↓ · Vs 7d avg W->R +0.9 · R->Ready -0.4",
            snoozeReminderStatusTitle: "Launch Snooze Reminder: Armed · Click: Unmute now",
            nextMoveLabel: "Recovery Sprint",
            cadenceStreakStatusTitle: "Cadence kit streak: x3 (best x8).",
            healthScore: "Risk",
            priorityMove: "Run `Run Launch Rescue Burst` now, then ship `Next action now`."
        )
        let snapshot = AppDelegate.launchRescueSnapshotMarkdown(
            autoTriggerSummary: autoTriggerSummary,
            autoTriggerAtSummary: "2023-11-14T22:13:20Z",
            autoFollowupSummary: "Run Fame Next Move + Copy Draft Pack · reason: Urgency High escalation.",
            autoFollowupAtSummary: "2023-11-14T22:13:20Z",
            followupRouteDecisionStatusTitle: followupRouteDecisionStatusTitle,
            autoSelfHealStatusTitle: autoSelfHealStatusTitle,
            followupScoreboardStatusTitle: followupScoreboardStatusTitle,
            followupCoachStatusTitle: followupCoachStatusTitle,
            followupMomentumStatusTitle: followupMomentumStatusTitle
        )

        func lineValue(_ markdown: String, prefix: String) -> String? {
            markdown
                .split(separator: "\n")
                .map(String.init)
                .first(where: { $0.hasPrefix(prefix) })
                .map { String($0.dropFirst(prefix.count)) }
        }

        XCTAssertEqual(
            lineValue(brief, prefix: "- Launch Rescue Auto Trigger: "),
            lineValue(snapshot, prefix: "- Auto trigger: ")
        )
        XCTAssertEqual(
            lineValue(brief, prefix: "- Launch Rescue Follow-up Scoreboard: "),
            lineValue(snapshot, prefix: "- Launch Rescue Follow-up Scoreboard: ")
        )
        XCTAssertEqual(
            lineValue(brief, prefix: "- Launch Rescue Auto Follow-up Route Decision: "),
            lineValue(snapshot, prefix: "- Launch Rescue Auto Follow-up Route Decision: ")
        )
        XCTAssertEqual(
            lineValue(brief, prefix: "- Launch Rescue Auto Self-Heal: "),
            lineValue(snapshot, prefix: "- Launch Rescue Auto Self-Heal: ")
        )
        XCTAssertEqual(
            lineValue(brief, prefix: "- Launch Rescue Follow-up Coach: "),
            lineValue(snapshot, prefix: "- Launch Rescue Follow-up Coach: ")
        )
        XCTAssertEqual(
            lineValue(brief, prefix: "- Launch Rescue Follow-up Momentum: "),
            lineValue(snapshot, prefix: "- Launch Rescue Follow-up Momentum: ")
        )
    }

    func testLaunchControlHealthActionCommandIDCanEscalateWatchBandWhenPressureSignalIsHigh() {
        let watchStatus = FameLaunchCountdownStatus(
            countdown: "T+8m",
            nextAction: "T+8m: Push replies",
            launchRoute: "Recovery",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthActionCommandID(
                launchStatus: watchStatus,
                momentumSignal: .stable
            ),
            "run-fame-launch-countdown"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthActionCommandID(
                launchStatus: watchStatus,
                momentumSignal: .riskPressure
            ),
            "run-fame-launch-rescue-burst"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthActionCommandID(
                launchStatus: watchStatus,
                momentumSignal: .recoveryMomentum
            ),
            "run-fame-launch-countdown"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMenuTitle(
                launchStatus: watchStatus,
                statusTitle: "Pulse ready (1m) · Today W->R 5 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -0.4 · Signal Pressure ↑",
                commandID: "run-fame-launch-rescue-burst"
            ),
            "Launch Health: Watch · T+8m · Pulse ready (1m) · Today W->R 5 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -0.4 · Signal Pressure ↑ · Click: Run Launch Rescue Burst"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthCardSubtitle(
                launchStatus: watchStatus,
                statusTitle: "Pulse ready (1m) · Today W->R 5 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -0.4 · Signal Pressure ↑",
                commandID: "run-fame-launch-rescue-burst"
            ),
            "Urgency Hot (overdue by 8m) · Next: T+8m: Push replies · Pulse ready (1m) · Today W->R 5 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -0.4 · Signal Pressure ↑ · click: Run Launch Rescue Burst"
        )
    }

    func testFameLaunchCountdownAlertSystemImageEscalatesWhenOverdue() {
        let overdueStatus = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Push replies",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchCountdownAlertSystemImage(overdueStatus),
            "exclamationmark.triangle.fill"
        )
    }

    func testFameLaunchBadgeUrgencyMapsPrepLiveAndCriticalBands() {
        let prep = FameLaunchCountdownStatus(
            countdown: "T-35m",
            nextAction: "T-35m: Prep",
            launchRoute: "Builder Thread",
            pulseRisk: "Low"
        )
        let live = FameLaunchCountdownStatus(
            countdown: "T-4m",
            nextAction: "T-4m: Queue launch post",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )
        let critical = FameLaunchCountdownStatus(
            countdown: "T+33m",
            nextAction: "T+33m: Catch up replies",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )

        XCTAssertEqual(AppDelegate.fameLaunchBadgeUrgency(prep), .prep)
        XCTAssertEqual(AppDelegate.fameLaunchBadgeUrgency(live), .live)
        XCTAssertEqual(AppDelegate.fameLaunchBadgeUrgency(critical), .critical)
    }

    func testFameLaunchUrgencyTransitionDetectsEscalationAndRecovery() {
        let escalation = AppDelegate.fameLaunchUrgencyTransition(
            previous: .ready,
            next: .high
        )
        XCTAssertEqual(
            escalation,
            AppDelegate.FameLaunchUrgencyTransition(
                from: .ready,
                to: .high,
                isEscalation: true
            )
        )

        let recovery = AppDelegate.fameLaunchUrgencyTransition(
            previous: .critical,
            next: .live
        )
        XCTAssertEqual(
            recovery,
            AppDelegate.FameLaunchUrgencyTransition(
                from: .critical,
                to: .live,
                isEscalation: false
            )
        )

        XCTAssertNil(
            AppDelegate.fameLaunchUrgencyTransition(
                previous: .hot,
                next: .hot
            )
        )
    }

    func testFameLaunchUrgencyTransitionSurfacingTargetsKeyThresholds() {
        let prepToReady = AppDelegate.FameLaunchUrgencyTransition(
            from: .prep,
            to: .ready,
            isEscalation: true
        )
        XCTAssertFalse(AppDelegate.shouldSurfaceFameLaunchUrgencyTransition(prepToReady))

        let readyToLive = AppDelegate.FameLaunchUrgencyTransition(
            from: .ready,
            to: .live,
            isEscalation: true
        )
        XCTAssertTrue(AppDelegate.shouldSurfaceFameLaunchUrgencyTransition(readyToLive))

        let hotToHigh = AppDelegate.FameLaunchUrgencyTransition(
            from: .hot,
            to: .high,
            isEscalation: true
        )
        XCTAssertTrue(AppDelegate.shouldSurfaceFameLaunchUrgencyTransition(hotToHigh))

        let highToReady = AppDelegate.FameLaunchUrgencyTransition(
            from: .high,
            to: .ready,
            isEscalation: false
        )
        XCTAssertTrue(AppDelegate.shouldSurfaceFameLaunchUrgencyTransition(highToReady))

        let liveToReady = AppDelegate.FameLaunchUrgencyTransition(
            from: .live,
            to: .ready,
            isEscalation: false
        )
        XCTAssertFalse(AppDelegate.shouldSurfaceFameLaunchUrgencyTransition(liveToReady))
    }

    func testFameLaunchUrgencyTransitionSurfacingCanBeDisabled() {
        let transition = AppDelegate.FameLaunchUrgencyTransition(
            from: .ready,
            to: .critical,
            isEscalation: true
        )

        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchUrgencyTransition(
                transition,
                alertsEnabled: false
            )
        )
    }

    func testLaunchControlHealthBandMapsUrgencyAndUnknownStates() {
        XCTAssertEqual(AppDelegate.launchControlHealthBand(.prep), .ready)
        XCTAssertEqual(AppDelegate.launchControlHealthBand(.ready), .ready)
        XCTAssertEqual(AppDelegate.launchControlHealthBand(.live), .watch)
        XCTAssertEqual(AppDelegate.launchControlHealthBand(.hot), .watch)
        XCTAssertEqual(AppDelegate.launchControlHealthBand(.high), .risk)
        XCTAssertEqual(AppDelegate.launchControlHealthBand(.critical), .risk)
        XCTAssertEqual(AppDelegate.launchControlHealthBand(nil), .watch)
    }

    func testLaunchControlHealthTransitionDetectsBandCrossingsOnly() {
        let watchToRisk = AppDelegate.launchControlHealthTransition(
            previous: .hot,
            next: .high
        )
        XCTAssertEqual(
            watchToRisk,
            AppDelegate.LaunchControlHealthTransition(
                from: .watch,
                to: .risk
            )
        )

        let riskToReady = AppDelegate.launchControlHealthTransition(
            previous: .critical,
            next: .ready
        )
        XCTAssertEqual(
            riskToReady,
            AppDelegate.LaunchControlHealthTransition(
                from: .risk,
                to: .ready
            )
        )

        XCTAssertNil(
            AppDelegate.launchControlHealthTransition(
                previous: .high,
                next: .critical
            )
        )
    }

    func testLaunchControlHealthTransitionPulseSurfacingTargetsRiskAndReadyRecovery() {
        let watchToRisk = AppDelegate.LaunchControlHealthTransition(
            from: .watch,
            to: .risk
        )
        XCTAssertTrue(AppDelegate.shouldSurfaceLaunchControlHealthTransitionPulse(watchToRisk))

        let riskToReady = AppDelegate.LaunchControlHealthTransition(
            from: .risk,
            to: .ready
        )
        XCTAssertTrue(AppDelegate.shouldSurfaceLaunchControlHealthTransitionPulse(riskToReady))

        let readyToWatch = AppDelegate.LaunchControlHealthTransition(
            from: .ready,
            to: .watch
        )
        XCTAssertFalse(AppDelegate.shouldSurfaceLaunchControlHealthTransitionPulse(readyToWatch))

        let riskToWatch = AppDelegate.LaunchControlHealthTransition(
            from: .risk,
            to: .watch
        )
        XCTAssertFalse(AppDelegate.shouldSurfaceLaunchControlHealthTransitionPulse(riskToWatch))
    }

    func testLaunchControlHealthTransitionPulseSurfacingCanBeDisabled() {
        let transition = AppDelegate.LaunchControlHealthTransition(
            from: .watch,
            to: .risk
        )

        XCTAssertFalse(
            AppDelegate.shouldSurfaceLaunchControlHealthTransitionPulse(
                transition,
                alertsEnabled: false
            )
        )
    }

    func testLaunchControlHealthTransitionPulseTokenUsesFromToBands() {
        let transition = AppDelegate.LaunchControlHealthTransition(
            from: .watch,
            to: .risk
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionPulseToken(transition),
            "watch-to-risk"
        )
    }

    func testShouldPulseLaunchControlHealthTransitionDedupesRepeatedTokenWithinCooldown() {
        let transition = AppDelegate.LaunchControlHealthTransition(
            from: .watch,
            to: .risk
        )
        let now = Date(timeIntervalSince1970: 20_000)

        XCTAssertTrue(
            AppDelegate.shouldPulseLaunchControlHealthTransition(
                lastPulseAt: nil,
                lastPulseToken: nil,
                transition: transition,
                now: now,
                cooldown: 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldPulseLaunchControlHealthTransition(
                lastPulseAt: now.addingTimeInterval(-15),
                lastPulseToken: "watch-to-risk",
                transition: transition,
                now: now,
                cooldown: 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldPulseLaunchControlHealthTransition(
                lastPulseAt: now.addingTimeInterval(-15),
                lastPulseToken: "risk-to-ready",
                transition: transition,
                now: now,
                cooldown: 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldPulseLaunchControlHealthTransition(
                lastPulseAt: now.addingTimeInterval(-61),
                lastPulseToken: "watch-to-risk",
                transition: transition,
                now: now,
                cooldown: 60
            )
        )
    }

    func testShouldPulseLaunchControlHealthTransitionTreatsZeroCooldownAsAlwaysReady() {
        let transition = AppDelegate.LaunchControlHealthTransition(
            from: .watch,
            to: .risk
        )
        let now = Date(timeIntervalSince1970: 20_000)

        XCTAssertTrue(
            AppDelegate.shouldPulseLaunchControlHealthTransition(
                lastPulseAt: now.addingTimeInterval(-1),
                lastPulseToken: "watch-to-risk",
                transition: transition,
                now: now,
                cooldown: 0
            )
        )
        XCTAssertNil(
            AppDelegate.launchControlHealthTransitionPulseCooldownRemainingSeconds(
                lastPulseAt: now.addingTimeInterval(-1),
                lastPulseToken: "watch-to-risk",
                transition: transition,
                now: now,
                cooldown: 0
            )
        )
    }

    func testLaunchControlHealthTransitionPulseCooldownRemainingSecondsTracksWindow() {
        let transition = AppDelegate.LaunchControlHealthTransition(
            from: .watch,
            to: .risk
        )
        let now = Date(timeIntervalSince1970: 30_000)

        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionPulseCooldownRemainingSeconds(
                lastPulseAt: now.addingTimeInterval(-55),
                lastPulseToken: "watch-to-risk",
                transition: transition,
                now: now,
                cooldown: 60
            ),
            5
        )
        XCTAssertNil(
            AppDelegate.launchControlHealthTransitionPulseCooldownRemainingSeconds(
                lastPulseAt: now.addingTimeInterval(-60),
                lastPulseToken: "watch-to-risk",
                transition: transition,
                now: now,
                cooldown: 60
            )
        )
        XCTAssertNil(
            AppDelegate.launchControlHealthTransitionPulseCooldownRemainingSeconds(
                lastPulseAt: now.addingTimeInterval(-55),
                lastPulseToken: "risk-to-ready",
                transition: transition,
                now: now,
                cooldown: 60
            )
        )
    }

    func testFameLaunchRescueBurstAutoTriggerRequiresHighOrCriticalEscalationAndCooldown() {
        let now = Date(timeIntervalSince1970: 90_000)

        XCTAssertFalse(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .high,
                    to: .live,
                    isEscalation: false
                ),
                lastRunAt: nil,
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .ready,
                    to: .hot,
                    isEscalation: true
                ),
                lastRunAt: nil,
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .hot,
                    to: .high,
                    isEscalation: true
                ),
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .hot,
                    to: .high,
                    isEscalation: true
                ),
                lastRunAt: now.addingTimeInterval(-(16 * 60)),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .high,
                    to: .critical,
                    isEscalation: true
                ),
                lastRunAt: nil,
                now: now,
                cooldown: 15 * 60
            )
        )
    }

    func testFameLaunchRescueBurstAutoTriggerCanUseCooldownMomentumAtHotEscalation() {
        let now = Date(timeIntervalSince1970: 90_000)
        let hotEscalation = AppDelegate.FameLaunchUrgencyTransition(
            from: .ready,
            to: .hot,
            isEscalation: true
        )

        XCTAssertFalse(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                hotEscalation,
                modeMomentumStreak: -1,
                lastRunAt: nil,
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                hotEscalation,
                modeMomentumStreak: -2,
                lastRunAt: now.addingTimeInterval(-120),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                hotEscalation,
                modeMomentumStreak: -2,
                lastRunAt: now.addingTimeInterval(-(16 * 60)),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                hotEscalation,
                modeMomentumStreak: -3,
                lastRunAt: nil,
                now: now,
                cooldown: 15 * 60
            )
        )
    }

    func testLaunchRescueAutoTriggerReasonMapsUrgencyAndMomentumPaths() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReason(
                transition: AppDelegate.FameLaunchUrgencyTransition(
                    from: .ready,
                    to: .hot,
                    isEscalation: true
                ),
                modeMomentumCueSeverity: .watch
            ),
            .momentumWatch
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReason(
                transition: AppDelegate.FameLaunchUrgencyTransition(
                    from: .ready,
                    to: .hot,
                    isEscalation: true
                ),
                modeMomentumCueSeverity: .alert
            ),
            .momentumAlert
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReason(
                transition: AppDelegate.FameLaunchUrgencyTransition(
                    from: .hot,
                    to: .high,
                    isEscalation: true
                ),
                modeMomentumCueSeverity: .alert
            ),
            .urgencyHigh
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReason(
                transition: AppDelegate.FameLaunchUrgencyTransition(
                    from: .high,
                    to: .critical,
                    isEscalation: true
                ),
                modeMomentumCueSeverity: .watch
            ),
            .urgencyCritical
        )
    }

    func testLaunchRescueAutoTriggerActivityDetailContractFormatsReasonAndPressureSuffix() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerActivityDetail(reason: .urgencyHigh),
            "run-fame-launch-rescue-burst-auto-trigger-urgency-high"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerActivityDetail(reason: .momentumAlert),
            "run-fame-launch-rescue-burst-auto-trigger-momentum-alert"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerActivityDetail(
                reason: .pressurePersistence,
                pressureStreakDays: 4
            ),
            "run-fame-launch-rescue-burst-auto-trigger-pressure-persistence-4"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerActivityDetail(
                reason: .pressurePersistence,
                pressureStreakDays: 0
            ),
            "run-fame-launch-rescue-burst-auto-trigger-pressure-persistence"
        )
    }

    func testLaunchControlHubAutoEscalationAndSkipActivityDetailsNormalizeInputs() {
        XCTAssertEqual(
            AppDelegate.launchControlHubAutoEscalationActivityDetail(urgencyToken: "critical"),
            "run-fame-launch-control-hub-auto-critical"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubAutoEscalationActivityDetail(urgencyToken: "   "),
            "run-fame-launch-control-hub-auto-command"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubAutoSkipActivityDetail(
                skipReason: "disabled",
                urgencyToken: "high",
                triggerReason: .urgencyHigh
            ),
            "run-fame-launch-control-hub-auto-skipped-disabled-high-urgency-high"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHubAutoSkipActivityDetail(
                skipReason: "something-else",
                urgencyToken: "   ",
                triggerReason: .momentumWatch
            ),
            "run-fame-launch-control-hub-auto-skipped-cooldown-command-momentum-watch"
        )
    }

    func testLaunchRescueAutoTriggerReasonTokenFromActivityDetailParsesKnownContract() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonTokenFromActivityDetail(
                "run-fame-launch-rescue-burst-auto-trigger-urgency-critical"
            ),
            "urgency-critical"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonTokenFromActivityDetail(
                "run-fame-launch-rescue-burst-auto-trigger-pressure-persistence-6"
            ),
            "pressure-persistence"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonTokenFromActivityDetail(
                "run-fame-launch-rescue-burst-auto-trigger-pressure-persistence-not-a-number"
            ),
            "none"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonTokenFromActivityDetail(
                "run-fame-launch-rescue-burst-auto-trigger-momentum-watch-extra"
            ),
            "none"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonTokenFromActivityDetail(
                "run-fame-launch-rescue-burst-auto-skipped-cooldown-critical-urgency-critical"
            ),
            "none"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonTokenFromActivityDetail(
                "  RUN-FAME-LAUNCH-RESCUE-BURST-AUTO-TRIGGER-MOMENTUM-WATCH  "
            ),
            "momentum-watch"
        )
    }

    func testLaunchRescueAutoTriggerReasonTokenNormalizesKnownAndActivityDetailValues() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonToken("  MOMENTUM-ALERT "),
            "momentum-alert"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonToken(
                "run-fame-launch-rescue-burst-auto-trigger-urgency-high"
            ),
            "urgency-high"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonToken(
                " RUN-FAME-LAUNCH-RESCUE-BURST-AUTO-TRIGGER-PRESSURE-PERSISTENCE-5 "
            ),
            "pressure-persistence"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonToken("unexpected-token"),
            "none"
        )
    }

    func testLaunchRescueAutoTriggerAtParsesKnownTimestampValues() {
        let parsedFromDouble = AppDelegate.launchRescueAutoTriggerAt(1_700_000_000)?.timeIntervalSince1970
        let parsedFromString = AppDelegate.launchRescueAutoTriggerAt(" 1700000000 ")?.timeIntervalSince1970
        XCTAssertNotNil(parsedFromDouble)
        XCTAssertNotNil(parsedFromString)
        XCTAssertEqual(
            parsedFromDouble ?? 0,
            1_700_000_000,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            parsedFromString ?? 0,
            1_700_000_000,
            accuracy: 0.0001
        )
        XCTAssertNil(AppDelegate.launchRescueAutoTriggerAt("not-a-timestamp"))
        XCTAssertNil(AppDelegate.launchRescueAutoTriggerAt(0))
    }

    func testFameLaunchRescueBurstAutoTriggerRunsWhenCooldownExactlyElapsed() {
        let now = Date(timeIntervalSince1970: 90_000)

        XCTAssertTrue(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .hot,
                    to: .high,
                    isEscalation: true
                ),
                lastRunAt: now.addingTimeInterval(-(15 * 60)),
                now: now,
                cooldown: 15 * 60
            )
        )
    }

    func testFameLaunchRescueBurstAutoTriggerCanBeDisabled() {
        let now = Date(timeIntervalSince1970: 90_000)

        XCTAssertFalse(
            AppDelegate.shouldAutoRunFameLaunchRescueBurst(
                AppDelegate.FameLaunchUrgencyTransition(
                    from: .hot,
                    to: .high,
                    isEscalation: true
                ),
                lastRunAt: now.addingTimeInterval(-(60 * 60)),
                now: now,
                cooldown: 0
            )
        )
    }

    func testLaunchControlHealthPressurePersistenceAutoTriggerRequiresPressureSignalStreakAndCooldown() {
        let watchStatus = FameLaunchCountdownStatus(
            countdown: "T+8m",
            nextAction: "T+8m: Push replies",
            launchRoute: "Recovery",
            pulseRisk: "High"
        )
        let readyStatus = FameLaunchCountdownStatus(
            countdown: "T-8m",
            nextAction: "T-8m: Queue thread",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )
        let now = Date(timeIntervalSince1970: 100_000)

        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: false,
                launchStatus: nil,
                momentumSignal: .riskPressure,
                pressureStreakDays: 3,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 24 * 60 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: true,
                launchStatus: watchStatus,
                momentumSignal: .stable,
                pressureStreakDays: 3,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 24 * 60 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: true,
                launchStatus: readyStatus,
                momentumSignal: .riskPressure,
                pressureStreakDays: 3,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 24 * 60 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: true,
                launchStatus: watchStatus,
                momentumSignal: .riskPressure,
                pressureStreakDays: 1,
                lastAutoRunAt: nil,
                now: now,
                cooldown: 24 * 60 * 60
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: true,
                launchStatus: watchStatus,
                momentumSignal: .riskPressure,
                pressureStreakDays: 3,
                lastAutoRunAt: now.addingTimeInterval(-(2 * 60 * 60)),
                now: now,
                cooldown: 24 * 60 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: true,
                launchStatus: watchStatus,
                momentumSignal: .riskPressure,
                pressureStreakDays: 3,
                lastAutoRunAt: now.addingTimeInterval(-(26 * 60 * 60)),
                now: now,
                cooldown: 24 * 60 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunLaunchRescueBurstForPressurePersistence(
                isEnabled: true,
                launchStatus: watchStatus,
                momentumSignal: .riskPressure,
                pressureStreakDays: 3,
                lastAutoRunAt: now.addingTimeInterval(-10),
                now: now,
                cooldown: 0
            )
        )
    }

    func testFameLaunchThresholdAlertsToggleCopyAndIconCanReflectState() {
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleTitle(true),
            "Launch Threshold Alerts: On"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleTitle(false),
            "Launch Threshold Alerts: Muted"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleSubtitle(true),
            "Mute launch threshold HUD/flash alerts (badges stay on)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleSubtitle(false),
            "Unmute launch threshold HUD/flash alerts"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleSystemImage(true),
            "bell.fill"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleSystemImage(false),
            "bell.slash.fill"
        )
    }

    func testFameLaunchThresholdAlertsToggleCopyCanReflectSnoozedState() {
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleTitle(
                false,
                snoozeMinutesRemaining: 22
            ),
            "Launch Threshold Alerts: Snoozed 22m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleSubtitle(
                false,
                snoozeMinutesRemaining: 22
            ),
            "Snoozed 22m left · unmute now or wait for auto-unmute"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsToggleSystemImage(
                false,
                snoozeMinutesRemaining: 22
            ),
            "hourglass.circle.fill"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeTitle(minutes: 10),
            "Snooze Threshold Alerts (10m)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeTitle(minutes: 30),
            "Snooze Threshold Alerts (30m)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeTitle(minutes: 60),
            "Snooze Threshold Alerts (60m)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeSubtitle(
                minutes: 10,
                snoozeMinutesRemaining: nil
            ),
            "Mute launch threshold HUD/flash alerts for 10m, then auto-unmute"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeSubtitle(
                minutes: 30,
                snoozeMinutesRemaining: nil
            ),
            "Mute launch threshold HUD/flash alerts for 30m, then auto-unmute"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeSubtitle(
                minutes: 60,
                snoozeMinutesRemaining: nil
            ),
            "Mute launch threshold HUD/flash alerts for 60m, then auto-unmute"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeSubtitle(
                minutes: 30,
                snoozeMinutesRemaining: 12
            ),
            "Extend snooze by 30m · 12m currently left"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeSystemImage(),
            "hourglass.circle.fill"
        )
    }

    func testFameLaunchThresholdAlertsRecommendedSnoozeMinutesMapsUrgencyBands() {
        let highStatus = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Catch up queue",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )
        let hotStatus = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "Medium"
        )
        let prepStatus = FameLaunchCountdownStatus(
            countdown: "T-24m",
            nextAction: "T-24m: Preflight",
            launchRoute: "Builder Thread",
            pulseRisk: "Low"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
                launchStatus: highStatus
            ),
            10
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
                launchStatus: hotStatus
            ),
            30
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
                launchStatus: prepStatus
            ),
            60
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
                launchStatus: nil
            ),
            30
        )
    }

    func testFameLaunchThresholdAlertsRecommendedSnoozeCopyIncludesUrgencyAndExtension() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Catch up queue",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeTitle(minutes: 10),
            "Smart Snooze (Recommended 10m)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeSubtitle(
                minutes: 10,
                launchStatus: status,
                snoozeMinutesRemaining: nil
            ),
            "Urgency High (overdue by 18m) · quiet launch threshold alerts for 10m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeSubtitle(
                minutes: 10,
                launchStatus: status,
                snoozeMinutesRemaining: 7
            ),
            "Urgency High (overdue by 18m) · 7m left · extend by 10m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeSubtitle(
                minutes: 30,
                launchStatus: nil,
                snoozeMinutesRemaining: nil
            ),
            "Urgency Unknown · quiet launch threshold alerts for 30m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecommendedSnoozeSystemImage(),
            "sparkles"
        )
    }

    func testFameLaunchThresholdAlertsSnoozeReminderSurfacingRequiresMutedNearExpiryAndLaunchWindow() {
        let hotStatus = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "High"
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
                alertsEnabled: true,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 8
            )
        )

        let prepStatus = FameLaunchCountdownStatus(
            countdown: "T-35m",
            nextAction: "T-35m: Warm up queue",
            launchRoute: "Builder Thread",
            pulseRisk: "Low"
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
                alertsEnabled: false,
                launchStatus: prepStatus,
                snoozeMinutesRemaining: 3
            )
        )
    }

    func testFameLaunchThresholdAlertsSnoozeReminderCopyIncludesRecommendedExtension() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderTitle(
                snoozeMinutesRemaining: 3
            ),
            "Launch Alert: Snooze Ends in 3m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderSubtitle(
                status: status,
                snoozeMinutesRemaining: 3,
                recommendedMinutes: 30
            ),
            "Urgency Hot (overdue by 4m) · Threshold alerts auto-unmute in 3m · unmute now or smart snooze 30m · Why now: snooze ends in 3m and urgency is Hot"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderReason(
                status: status,
                snoozeMinutesRemaining: 3
            ),
            "Why now: snooze ends in 3m and urgency is Hot"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderSystemImage(),
            "hourglass.circle.fill"
        )
    }

    func testFameLaunchThresholdAlertsSnoozeReminderExtendCopyIncludesUrgency() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderExtendTitle(
                recommendedMinutes: 30
            ),
            "Launch Alert: Extend Snooze 30m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderExtendSubtitle(
                status: status,
                snoozeMinutesRemaining: 3,
                recommendedMinutes: 30
            ),
            "Urgency Hot (overdue by 4m) · 3m left · extend snooze by 30m now"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderExtendSystemImage(),
            "sparkles"
        )
    }

    func testFameLaunchThresholdAlertsSnoozeReminderMenuTitleCanShowArmedSuppressedAndInactiveStates() {
        let hotStatus = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "High"
        )
        let prepStatus = FameLaunchCountdownStatus(
            countdown: "T-35m",
            nextAction: "T-35m: Warm up queue",
            launchRoute: "Builder Thread",
            pulseRisk: "Low"
        )
        let snoozeUntil = Date(timeIntervalSince1970: 40_000)

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: true,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: nil,
                lastReminderUrgencyPriority: nil
            ),
            "Launch Snooze Reminder: Inactive (alerts on)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: nil,
                currentSnoozeUntil: nil,
                lastReminderSnoozeUntil: nil,
                lastReminderUrgencyPriority: nil
            ),
            "Launch Snooze Reminder: Inactive (no snooze)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 9,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: nil,
                lastReminderUrgencyPriority: nil
            ),
            "Launch Snooze Reminder: Waiting (9m left)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: prepStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: nil,
                lastReminderUrgencyPriority: nil
            ),
            "Launch Snooze Reminder: Waiting (urgency Prep)"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: snoozeUntil,
                lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.live)
            ),
            "Launch Snooze Reminder: Armed (3m left) · Click: Extend 30m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: snoozeUntil,
                lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.live),
                cooldownSeconds: 2
            ),
            "Launch Snooze Reminder: Armed (3m left) · Click: Extend 30m · Cooldown 2s"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: snoozeUntil,
                lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.hot)
            ),
            "Launch Snooze Reminder: Suppressed (shown once this snooze) · Click: Extend 30m"
        )

        let armedState = AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuState(
            alertsEnabled: false,
            launchStatus: hotStatus,
            snoozeMinutesRemaining: 3,
            currentSnoozeUntil: snoozeUntil,
            lastReminderSnoozeUntil: snoozeUntil,
            lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.live)
        )
        XCTAssertEqual(
            armedState,
            .armed(minutesRemaining: 3)
        )
        let armedTapAction = AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            alertsEnabled: false,
            launchStatus: hotStatus,
            menuState: armedState
        )
        XCTAssertEqual(armedTapAction, .extend(minutes: 30))
        XCTAssertTrue(
            AppDelegate.canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(armedTapAction)
        )

        let suppressedState = AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuState(
            alertsEnabled: false,
            launchStatus: hotStatus,
            snoozeMinutesRemaining: 3,
            currentSnoozeUntil: snoozeUntil,
            lastReminderSnoozeUntil: snoozeUntil,
            lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.hot)
        )
        XCTAssertEqual(
            suppressedState,
            .suppressed
        )
        let suppressedTapAction = AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            alertsEnabled: false,
            launchStatus: hotStatus,
            menuState: suppressedState
        )
        XCTAssertEqual(suppressedTapAction, .extend(minutes: 30))
        XCTAssertTrue(
            AppDelegate.canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(suppressedTapAction)
        )
        let highStatus = FameLaunchCountdownStatus(
            countdown: "T+20m",
            nextAction: "T+20m: Recover launch timeline",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: highStatus,
                snoozeMinutesRemaining: 9,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: nil,
                lastReminderUrgencyPriority: nil
            ),
            "Launch Snooze Reminder: Waiting (9m left) · Click: Unmute now"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
                alertsEnabled: false,
                launchStatus: highStatus,
                snoozeMinutesRemaining: 9,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: nil,
                lastReminderUrgencyPriority: nil,
                cooldownSeconds: 2
            ),
            "Launch Snooze Reminder: Waiting (9m left) · Click: Unmute now · Cooldown 2s"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
                alertsEnabled: false,
                launchStatus: highStatus,
                menuState: .waiting(minutesRemaining: 9)
            ),
            .unmuteNow
        )
        let waitingTapAction = AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            alertsEnabled: false,
            launchStatus: hotStatus,
            menuState: .waiting(minutesRemaining: 9)
        )
        XCTAssertNil(waitingTapAction)
        XCTAssertFalse(
            AppDelegate.canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(
                waitingTapAction
            )
        )
        XCTAssertFalse(
            AppDelegate.canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(
                AppDelegate.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
                    alertsEnabled: false,
                    launchStatus: hotStatus,
                    menuState: .inactiveNoSnooze
                )
            )
        )
    }

    func testFameLaunchThresholdAlertsQuickActionFeedbackCopyAndActivityToken() {
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionMessage(
                action: .unmuteNow
            ),
            "Quick action: launch threshold alerts unmuted."
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionActivityToken(
                action: .unmuteNow
            ),
            "unmute-now"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionMessage(
                action: .extend(minutes: 30)
            ),
            "Quick action: launch threshold alert snooze extended 30m."
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionMessage(
                action: .extend(minutes: 30),
                resolvedMinutes: 28
            ),
            "Quick action: launch threshold alert snooze extended 28m."
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionActivityToken(
                action: .extend(minutes: 30),
                resolvedMinutes: 28
            ),
            "extend-28m"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionSourceFromMenu(
                action: .unmuteNow
            ),
            "menu-snooze-reminder-unmute"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionSourceFromMenu(
                action: .extend(minutes: 30)
            ),
            "menu-snooze-reminder-extend"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionDisabledReason(
                cooldownSeconds: nil
            ),
            "Not ready"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionDisabledReason(
                cooldownSeconds: 2
            ),
            "Cooldown 2s"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionReadySurfaceToken(
                menuVisible: true,
                paletteVisible: false
            ),
            "menu"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionReadySurfaceToken(
                menuVisible: false,
                paletteVisible: true
            ),
            "palette"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionReadySurfaceToken(
                menuVisible: true,
                paletteVisible: true
            ),
            "menu-palette"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionReadySurfaceToken(
                menuVisible: false,
                paletteVisible: false
            ),
            "none"
        )
    }

    func testFameLaunchThresholdAlertsQuickActionCooldownCanBlockRepeatedSameActionOnly() {
        let now = Date(timeIntervalSince1970: 50_000)
        let lastRunAt = now.addingTimeInterval(-0.3)

        XCTAssertFalse(
            AppDelegate.shouldRunFameLaunchThresholdAlertsQuickAction(
                lastRunAt: lastRunAt,
                lastActionToken: "extend-30m",
                nextActionToken: "extend-30m",
                now: now,
                cooldown: 1.5
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldRunFameLaunchThresholdAlertsQuickAction(
                lastRunAt: lastRunAt,
                lastActionToken: "extend-30m",
                nextActionToken: "unmute-now",
                now: now,
                cooldown: 1.5
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldRunFameLaunchThresholdAlertsQuickAction(
                lastRunAt: now.addingTimeInterval(-2.0),
                lastActionToken: "extend-30m",
                nextActionToken: "extend-30m",
                now: now,
                cooldown: 1.5
            )
        )
        XCTAssertNil(
            AppDelegate.fameLaunchThresholdAlertsQuickActionCooldownRemainingSeconds(
                lastRunAt: lastRunAt,
                lastActionToken: "extend-30m",
                nextActionToken: "unmute-now",
                now: now,
                cooldown: 1.5
            )
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsQuickActionCooldownRemainingSeconds(
                lastRunAt: lastRunAt,
                lastActionToken: "extend-30m",
                nextActionToken: "extend-30m",
                now: now,
                cooldown: 1.5
            ),
            2
        )
    }

    func testFameLaunchThresholdAlertsQuickActionReadyPulseSurfacingRequiresCooldownEndAndActionability() {
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
                previousCooldownSeconds: 1,
                cooldownSeconds: nil,
                tapAction: .extend(minutes: 30)
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
                previousCooldownSeconds: 1,
                cooldownSeconds: nil,
                tapAction: nil
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
                previousCooldownSeconds: nil,
                cooldownSeconds: nil,
                tapAction: .extend(minutes: 30)
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
                previousCooldownSeconds: 2,
                cooldownSeconds: 1,
                tapAction: .extend(minutes: 30)
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
                previousCooldownSeconds: 1,
                cooldownSeconds: nil,
                tapAction: .extend(minutes: 30),
                isMenuVisible: false
            )
        )
    }

    func testFameLaunchThresholdAlertsSnoozeReminderDedupCanSuppressRepeatAndAllowWorsening() {
        let now = Date(timeIntervalSince1970: 20_000)
        let sameSnoozeUntil = now.addingTimeInterval(3 * 60)

        let liveStatus = FameLaunchCountdownStatus(
            countdown: "T-3m",
            nextAction: "T-3m: Final post",
            launchRoute: "Distribution Remix",
            pulseRisk: "Medium"
        )
        let hotStatus = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "High"
        )

        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
                alertsEnabled: false,
                launchStatus: liveStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: sameSnoozeUntil,
                lastReminderSnoozeUntil: sameSnoozeUntil,
                lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.live)
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: sameSnoozeUntil,
                lastReminderSnoozeUntil: sameSnoozeUntil,
                lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.live)
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
                alertsEnabled: false,
                launchStatus: liveStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: sameSnoozeUntil,
                lastReminderSnoozeUntil: now.addingTimeInterval(8 * 60),
                lastReminderUrgencyPriority: AppDelegate.fameLaunchBadgeUrgencyPriority(.live)
            )
        )
    }

    func testFameLaunchThresholdAlertsSnoozeReminderDedupCanUsePersistedStateAcrossDefaultsReload() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snoozeUntil = Date(timeIntervalSince1970: 30_000)
        defaults.set(
            snoozeUntil.timeIntervalSince1970,
            forKey: AppDefaults.fameLaunchThresholdAlertsReminderLastSnoozeUntilKey
        )
        defaults.set(
            AppDelegate.fameLaunchBadgeUrgencyPriority(.live),
            forKey: AppDefaults.fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey
        )

        let reloadedDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let persistedSnoozeUntil = Date(
            timeIntervalSince1970: reloadedDefaults.double(
                forKey: AppDefaults.fameLaunchThresholdAlertsReminderLastSnoozeUntilKey
            )
        )
        let persistedUrgencyPriority = reloadedDefaults.integer(
            forKey: AppDefaults.fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey
        )

        let liveStatus = FameLaunchCountdownStatus(
            countdown: "T-2m",
            nextAction: "T-2m: Final publish",
            launchRoute: "Distribution Remix",
            pulseRisk: "Medium"
        )
        let hotStatus = FameLaunchCountdownStatus(
            countdown: "T+4m",
            nextAction: "T+4m: Publish follow-up",
            launchRoute: "Distribution Remix",
            pulseRisk: "High"
        )

        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
                alertsEnabled: false,
                launchStatus: liveStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: persistedSnoozeUntil,
                lastReminderUrgencyPriority: persistedUrgencyPriority
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
                alertsEnabled: false,
                launchStatus: hotStatus,
                snoozeMinutesRemaining: 3,
                currentSnoozeUntil: snoozeUntil,
                lastReminderSnoozeUntil: persistedSnoozeUntil,
                lastReminderUrgencyPriority: persistedUrgencyPriority
            )
        )
    }

    func testFameLaunchThresholdAlertsSnoozeMinutesRemainingRoundsUpAndExpires() {
        let now = Date(timeIntervalSince1970: 10_000)
        let nearlyNineMinutes = now.addingTimeInterval(8 * 60 + 10)

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsSnoozeMinutesRemaining(
                snoozeUntil: nearlyNineMinutes,
                now: now
            ),
            9
        )
        XCTAssertNil(
            AppDelegate.fameLaunchThresholdAlertsSnoozeMinutesRemaining(
                snoozeUntil: now.addingTimeInterval(-1),
                now: now
            )
        )
        XCTAssertNil(
            AppDelegate.fameLaunchThresholdAlertsSnoozeMinutesRemaining(
                snoozeUntil: nil,
                now: now
            )
        )
    }

    func testShouldAutoUnmuteFameLaunchThresholdAlertsRequiresMutedAndElapsedSnooze() {
        let now = Date(timeIntervalSince1970: 5_000)
        let elapsedSnooze = now.addingTimeInterval(-30)
        let activeSnooze = now.addingTimeInterval(60)

        XCTAssertTrue(
            AppDelegate.shouldAutoUnmuteFameLaunchThresholdAlerts(
                alertsEnabled: false,
                snoozeUntil: elapsedSnooze,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoUnmuteFameLaunchThresholdAlerts(
                alertsEnabled: false,
                snoozeUntil: activeSnooze,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoUnmuteFameLaunchThresholdAlerts(
                alertsEnabled: true,
                snoozeUntil: elapsedSnooze,
                now: now
            )
        )
    }

    func testFameLaunchThresholdAlertsRecoveryActionSurfacingRequiresMutedAndEscalatedUrgency() {
        let criticalStatus = FameLaunchCountdownStatus(
            countdown: "T+33m",
            nextAction: "T+33m: Recover launch timeline",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsRecoveryAction(
                alertsEnabled: false,
                launchStatus: criticalStatus
            )
        )

        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsRecoveryAction(
                alertsEnabled: true,
                launchStatus: criticalStatus
            )
        )

        let readyStatus = FameLaunchCountdownStatus(
            countdown: "T-8m",
            nextAction: "T-8m: Final preflight check",
            launchRoute: "Distribution Remix",
            pulseRisk: "Medium"
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameLaunchThresholdAlertsRecoveryAction(
                alertsEnabled: false,
                launchStatus: readyStatus
            )
        )
    }

    func testFameLaunchThresholdAlertsRecoveryCopyCanIncludeUrgencyContext() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Respond to backlog",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecoveryTitle(status),
            "Launch Alert: Unmute Threshold Alerts"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchThresholdAlertsRecoverySubtitle(status),
            "Urgency High (overdue by 18m) · HUD/flash launch alerts muted · unmute now"
        )
    }

    func testFameStatusBadgeLevelUsesLaunchUrgencyWhenPulseIsStable() {
        let launchStatus = FameLaunchCountdownStatus(
            countdown: "T-3m",
            nextAction: "T-3m: Schedule launch publish",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )

        XCTAssertEqual(
            AppDelegate.fameStatusBadgeLevel(
                pulseSignal: nil,
                launchStatus: launchStatus
            ),
            .launchLive
        )
    }

    func testFameStatusBadgeLevelUsesOnboardingGapWhenLaunchAndPulseAreQuiet() {
        XCTAssertEqual(
            AppDelegate.fameStatusBadgeLevel(
                pulseSignal: nil,
                launchStatus: nil,
                onboardingGapMissingArtifacts: 2
            ),
            .onboardingGap
        )
    }

    func testFameStatusBadgeLevelIgnoresOnboardingGapWhenArtifactsAreComplete() {
        XCTAssertEqual(
            AppDelegate.fameStatusBadgeLevel(
                pulseSignal: nil,
                launchStatus: nil,
                onboardingGapMissingArtifacts: 0
            ),
            .normal
        )
    }

    func testFameStatusBadgeLevelPrefersLaunchSignalOverOnboardingGap() {
        let launchStatus = FameLaunchCountdownStatus(
            countdown: "T-3m",
            nextAction: "T-3m: Schedule launch publish",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )

        XCTAssertEqual(
            AppDelegate.fameStatusBadgeLevel(
                pulseSignal: nil,
                launchStatus: launchStatus,
                onboardingGapMissingArtifacts: 3
            ),
            .launchLive
        )
    }

    func testFameStatusBadgeLevelPrefersLaunchCriticalOverPulseHigh() {
        let pulseSignal = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "MUST SHIP",
            streakDays: 1,
            daysSinceLastSnapshot: 2,
            leadExperiment: "Reply Engine"
        )
        let launchStatus = FameLaunchCountdownStatus(
            countdown: "T+36m",
            nextAction: "T+36m: Ship late launch recovery",
            launchRoute: "Reply Engine",
            pulseRisk: "High"
        )

        XCTAssertEqual(
            AppDelegate.fameStatusBadgeLevel(
                pulseSignal: pulseSignal,
                launchStatus: launchStatus
            ),
            .launchCritical
        )
    }

    func testFameStatusBadgeLevelPrefersPulseCriticalOverLaunchCritical() {
        let pulseSignal = FamePulseAlertSignal(
            riskLevel: "Critical",
            mustShipAlert: "MUST SHIP now",
            streakDays: 0,
            daysSinceLastSnapshot: 3,
            leadExperiment: "Activation Fix"
        )
        let launchStatus = FameLaunchCountdownStatus(
            countdown: "T+40m",
            nextAction: "T+40m: Escalate launch response",
            launchRoute: "Activation Fix",
            pulseRisk: "Critical"
        )

        XCTAssertEqual(
            AppDelegate.fameStatusBadgeLevel(
                pulseSignal: pulseSignal,
                launchStatus: launchStatus
            ),
            .pulseCritical
        )
    }

    func testFameStatusBadgeSymbolMapsLaunchAndPulseLevels() {
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.normal), "text.viewfinder")
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.onboardingGap), "sparkles")
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.launchReady), "timer")
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.launchHot), "flame")
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.launchCritical), "flame.fill")
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.pulseHigh), "exclamationmark.triangle")
        XCTAssertEqual(AppDelegate.fameStatusBadgeSymbol(.pulseCritical), "exclamationmark.triangle.fill")
    }

    func testFameStatusBadgeTintMapsOnboardingGapToPurple() {
        XCTAssertEqual(AppDelegate.fameStatusBadgeTint(.onboardingGap), .systemPurple)
    }

    func testShouldSurfaceFameOnboardingGapPulseRequiresWorseningGapAndCooldown() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)

        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: 1,
                nextMissingArtifacts: 2,
                lastPulseAt: nil,
                now: now,
                cooldown: 900
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: 1,
                nextMissingArtifacts: 2,
                lastPulseAt: Date(timeIntervalSince1970: 1_790_000_300),
                now: now,
                cooldown: 900
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: 1,
                nextMissingArtifacts: 2,
                lastPulseAt: Date(timeIntervalSince1970: 1_789_998_900),
                now: now,
                cooldown: 900
            )
        )
    }

    func testShouldSurfaceFameOnboardingGapPulseSkipsFirstObservationAndNonEscalations() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)

        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: nil,
                nextMissingArtifacts: 2,
                lastPulseAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: 2,
                nextMissingArtifacts: 2,
                lastPulseAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: 2,
                nextMissingArtifacts: 1,
                lastPulseAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapPulse(
                previousMissingArtifacts: 1,
                nextMissingArtifacts: nil,
                lastPulseAt: nil,
                now: now
            )
        )
    }

    func testShouldSurfaceFameOnboardingGapRecoveryPulseRequiresImprovementAndCooldown() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)

        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: 3,
                nextMissingArtifacts: 2,
                lastRecoveryAt: nil,
                now: now,
                cooldown: 600
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: 3,
                nextMissingArtifacts: 2,
                lastRecoveryAt: Date(timeIntervalSince1970: 1_789_999_700),
                now: now,
                cooldown: 600
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: 2,
                nextMissingArtifacts: nil,
                lastRecoveryAt: Date(timeIntervalSince1970: 1_789_998_900),
                now: now,
                cooldown: 600
            )
        )
    }

    func testShouldSurfaceFameOnboardingGapRecoveryPulseSkipsFirstObservationAndNonRecoveries() {
        let now = Date(timeIntervalSince1970: 1_790_000_000)

        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: nil,
                nextMissingArtifacts: 1,
                lastRecoveryAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: 0,
                nextMissingArtifacts: 0,
                lastRecoveryAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: 1,
                nextMissingArtifacts: 1,
                lastRecoveryAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldSurfaceFameOnboardingGapRecoveryPulse(
                previousMissingArtifacts: 1,
                nextMissingArtifacts: 2,
                lastRecoveryAt: nil,
                now: now
            )
        )
    }

    func testConsumeFameOnboardingGapRecoveryMomentumClearsSnapshotForMatchingAction() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let lastAt = 1_790_000_000.0
        defaults.set(lastAt, forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey)
        defaults.set(
            "run-fame-onboarding-scorecard",
            forKey: AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey
        )
        defaults.set(2, forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey)

        XCTAssertTrue(
            AppDelegate.consumeFameOnboardingGapRecoveryMomentum(
                actionID: "run-fame-onboarding-scorecard",
                defaults: defaults
            )
        )
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey))
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey))
        XCTAssertNil(defaults.object(forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey))
    }

    func testConsumeFameOnboardingGapRecoveryMomentumSkipsNonMatchingAction() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let lastAt = 1_790_000_000.0
        defaults.set(lastAt, forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey)
        defaults.set(
            "run-fame-onboarding-scorecard",
            forKey: AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey
        )
        defaults.set(2, forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey)

        XCTAssertFalse(
            AppDelegate.consumeFameOnboardingGapRecoveryMomentum(
                actionID: "run-fame-onboarding-nudge",
                defaults: defaults
            )
        )
        XCTAssertEqual(defaults.double(forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey), lastAt)
        XCTAssertEqual(
            defaults.string(forKey: AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey),
            "run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(defaults.integer(forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey), 2)
    }

    func testLaunchCountdownRefreshRunsWhenNeverRefreshed() {
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        XCTAssertTrue(
            AppDelegate.shouldRefreshLaunchCountdown(
                lastRefreshAt: nil,
                now: now
            )
        )
    }

    func testLaunchCountdownRefreshSkipsInsideMinimumInterval() {
        let lastRefresh = Date(timeIntervalSince1970: 1_780_000_000)
        let now = Date(timeIntervalSince1970: 1_780_000_000 + 20)
        XCTAssertFalse(
            AppDelegate.shouldRefreshLaunchCountdown(
                lastRefreshAt: lastRefresh,
                now: now,
                minimumInterval: 45
            )
        )
    }

    func testLaunchCountdownRefreshRunsAfterMinimumInterval() {
        let lastRefresh = Date(timeIntervalSince1970: 1_780_000_000)
        let now = Date(timeIntervalSince1970: 1_780_000_000 + 65)
        XCTAssertTrue(
            AppDelegate.shouldRefreshLaunchCountdown(
                lastRefreshAt: lastRefresh,
                now: now,
                minimumInterval: 45
            )
        )
    }

    func testAutoOpsBundleCooldownRunsWhenNeverExecuted() {
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        XCTAssertTrue(
            AppDelegate.shouldRunAutoOpsBundleOnEscalation(
                lastRunAt: nil,
                now: now
            )
        )
    }

    func testAutoOpsBundleCooldownSkipsWhenInsideWindow() {
        let lastRun = Date(timeIntervalSince1970: 1_780_000_000)
        let now = Date(timeIntervalSince1970: 1_780_000_000 + 5 * 60)
        XCTAssertFalse(
            AppDelegate.shouldRunAutoOpsBundleOnEscalation(
                lastRunAt: lastRun,
                now: now,
                cooldown: 30 * 60
            )
        )
    }

    func testAutoOpsBundleCooldownRunsWhenWindowElapsed() {
        let lastRun = Date(timeIntervalSince1970: 1_780_000_000)
        let now = Date(timeIntervalSince1970: 1_780_000_000 + 35 * 60)
        XCTAssertTrue(
            AppDelegate.shouldRunAutoOpsBundleOnEscalation(
                lastRunAt: lastRun,
                now: now,
                cooldown: 30 * 60
            )
        )
    }

    func testAutoOpsBundleCooldownCanDisableAutoRun() {
        let lastRun = Date(timeIntervalSince1970: 1_780_000_000)
        let now = Date(timeIntervalSince1970: 1_780_000_000 + 60 * 60)
        XCTAssertFalse(
            AppDelegate.shouldRunAutoOpsBundleOnEscalation(
                lastRunAt: lastRun,
                now: now,
                cooldown: 0
            )
        )
    }

    func testAutoOpsBundleEscalationStatusDisabledWhenCooldownIsOff() {
        let status = AppDelegate.autoOpsBundleEscalationStatus(
            lastRunAt: Date(timeIntervalSince1970: 1_780_000_000),
            now: Date(timeIntervalSince1970: 1_780_000_000 + 60),
            cooldownMinutes: 0
        )

        XCTAssertEqual(status, .disabled)
    }

    func testAutoOpsBundleEscalationStatusReadyWhenCooldownElapsed() {
        let status = AppDelegate.autoOpsBundleEscalationStatus(
            lastRunAt: Date(timeIntervalSince1970: 1_780_000_000),
            now: Date(timeIntervalSince1970: 1_780_000_000 + 31 * 60),
            cooldownMinutes: 30
        )

        XCTAssertEqual(status, .ready)
    }

    func testAutoOpsBundleEscalationStatusReturnsRemainingMinutes() {
        let status = AppDelegate.autoOpsBundleEscalationStatus(
            lastRunAt: Date(timeIntervalSince1970: 1_780_000_000),
            now: Date(timeIntervalSince1970: 1_780_000_000 + 11 * 60 + 1),
            cooldownMinutes: 30
        )

        XCTAssertEqual(status, .coolingDown(minutesRemaining: 19))
    }

    func testAutoOpsBundleEscalationStatusPhraseFormatsCooldown() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusPhrase(.coolingDown(minutesRemaining: 12)),
            "auto bundle in 12m"
        )
    }

    func testAutoOpsBundleEscalationStatusPhraseFormatsDisabledAndReady() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusPhrase(.disabled),
            "auto bundle off"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusPhrase(.ready),
            "auto bundle ready"
        )
    }

    func testLaunchRescueAutoStatusPhraseFormatsStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusPhrase(.disabled),
            "auto rescue off"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusPhrase(.ready),
            "auto rescue ready"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusPhrase(.coolingDown(minutesRemaining: 8)),
            "auto rescue in 8m"
        )
    }

    func testAutoOpsBundleReaderStatusToneMapsStates() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleReaderStatusTone(.disabled),
            .neutral
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleReaderStatusTone(.ready),
            .success
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleReaderStatusTone(.coolingDown(minutesRemaining: 6)),
            .warning
        )
    }

    func testLaunchRescueAutoReaderStatusToneEscalatesForSeverityAndSelfHealContext() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoReaderStatusTone(
                .ready,
                title: "Launch Rescue Auto: Ready · Critical",
                subtitle: "Status: Auto rescue is ready on launch escalation."
            ),
            .danger
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoReaderStatusTone(
                .ready,
                title: "Launch Rescue Auto: Ready · High",
                subtitle: "Status: Auto rescue is ready on launch escalation."
            ),
            .warning
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoReaderStatusTone(
                .ready,
                title: "Launch Rescue Auto: Ready",
                subtitle: "Launch Rescue Auto Self-Heal Attention: Self-Heal Missing x1"
            ),
            .danger
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoReaderStatusTone(
                .ready,
                title: "Launch Rescue Auto: Ready",
                subtitle: "Status: Auto rescue is ready on launch escalation."
            ),
            .success
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoReaderStatusTone(
                .coolingDown(minutesRemaining: 9),
                title: "Launch Rescue Auto: Cooldown 9m",
                subtitle: "Status: Auto rescue cooldown 9m remaining."
            ),
            .warning
        )
    }

    func testReaderStatusPillAccessibilityHintUsesFirstStatusLineAndActionHint() {
        let subtitle = """
        Status: Auto rescue is ready on launch escalation.
        Last auto trigger: Urgency High escalation.
        Trigger severity: High
        """
        XCTAssertEqual(
            AppDelegate.readerStatusPillAccessibilityHint(subtitle),
            "Status: Auto rescue is ready on launch escalation. Double-tap for details and actions."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillAccessibilityHint(
                "Auto bundle ready on escalation",
                actionHint: "  Open Fame Ops now.  "
            ),
            "Auto bundle ready on escalation. Open Fame Ops now."
        )
    }

    func testReaderStatusPillAccessibilityHintFallsBackToDefaultActionHint() {
        XCTAssertEqual(
            AppDelegate.readerStatusPillAccessibilityHint("   "),
            "Double-tap for details and actions."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillAccessibilityHint(
                "Status: Auto rescue is off.",
                actionHint: "   "
            ),
            "Status: Auto rescue is off. Double-tap for details and actions."
        )
    }

    func testReaderStatusPillActionHintFormatsShortcutAndFallback() {
        XCTAssertEqual(
            AppDelegate.readerStatusPillActionHint(),
            "Double-tap for details and actions."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillActionHint(shortcutDisplay: "  Option-Command-R  "),
            "Double-tap for details and actions. Shortcut: Option-Command-R."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillActionHint(shortcutDisplay: "   "),
            "Double-tap for details and actions."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillActionHint(shortcutDisplay: "Option-Command-L"),
            "Double-tap for details and actions. Shortcut: Option-Command-L."
        )
    }

    func testReaderStatusPillHelpTextIncludesShortcutWhenProvided() {
        XCTAssertEqual(
            AppDelegate.readerStatusPillHelpText(
                "Status: Auto rescue is ready on launch escalation.",
                shortcutDisplay: "⌥⌘R"
            ),
            "Status: Auto rescue is ready on launch escalation.\nShortcut: ⌥⌘R."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillHelpText(
                "   ",
                shortcutDisplay: "⌥⌘O"
            ),
            "Shortcut: ⌥⌘O."
        )
        XCTAssertEqual(
            AppDelegate.readerStatusPillHelpText(
                "Status: Auto rescue is off.",
                shortcutDisplay: "   "
            ),
            "Status: Auto rescue is off."
        )
    }

    func testReaderStatusShortcutLegendAccessibilityValueMentionsDedicatedActions() {
        XCTAssertEqual(
            AppDelegate.readerStatusShortcutLegendAccessibilityValue(),
            "Option Command O runs auto bundle status. Option Command L runs launch rescue auto status."
        )
    }

    func testReaderStatusShortcutMenuHintLineMentionsDedicatedActions() {
        XCTAssertEqual(
            AppDelegate.readerStatusShortcutMenuHintLine(),
            "Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
        )
    }

    func testAutoOpsBundleEscalationStatusMenuTitleFormatsStates() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuTitle(.disabled),
            "Auto Ops Bundle: Off"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuTitle(.ready),
            "Auto Ops Bundle: Ready"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuTitle(.coolingDown(minutesRemaining: 7)),
            "Auto Ops Bundle: Cooldown 7m"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuTitle(
                .ready,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Auto Ops Bundle: Ready · Route Burst · Self-Heal Missing x1"
        )
    }

    func testAutoOpsBundleEscalationStatusMenuToolTipFormatsStates() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuToolTip(.disabled),
            "Auto bundle is off. Open Settings > Fame Ops.\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuToolTip(.ready),
            "Auto bundle is ready on escalation. Run once now.\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuToolTip(.coolingDown(minutesRemaining: 9)),
            "Next auto run in about 9 min. Run once now.\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleEscalationStatusMenuToolTip(
                .ready,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Auto bundle is ready on escalation. Run once now. · Route Burst · Self-Heal Missing x1\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
        )
    }

    @MainActor
    func testReaderAutoOpsBundleStatusPillContentCanIncludeRouteAndSelfHealContext() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)

        let delegate = AppDelegate()
        XCTAssertEqual(
            delegate.autoOpsBundleReaderPillStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto Ops Bundle: Ready · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            delegate.autoOpsBundleReaderPillStatusSubtitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Auto bundle is ready on escalation. Run once now. · Route Burst · Self-Heal Missing x1\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
        )
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusPillContentCanIncludeRouteAndSelfHealContext() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(-2, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 30

        let delegate = AppDelegate()
        XCTAssertEqual(
            delegate.launchRescueAutoReaderPillStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Launch Rescue Auto: Ready · Route Burst · Self-Heal Missing x1 · Watch x2 · High"
        )
        let subtitle = delegate.launchRescueAutoReaderPillStatusSubtitleForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(subtitle.contains("Status: Auto rescue is ready on launch escalation."))
        XCTAssertTrue(subtitle.contains("Last auto trigger: Urgency High escalation."))
        XCTAssertTrue(subtitle.contains("Trigger severity: High"))
        XCTAssertTrue(subtitle.contains("Launch Rescue Auto Self-Heal Attention: Self-Heal Missing x1"))
        XCTAssertTrue(subtitle.contains("Recommended: Run Launch Rescue Burst."))
        XCTAssertTrue(
            subtitle.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertTrue(subtitle.contains("Cooldown streak x2 · stage rescue now"))
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusPillSubtitleHidesRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(0, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 30

        let subtitle = AppDelegate().launchRescueAutoReaderPillStatusSubtitleForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(subtitle.contains("Status: Auto rescue is ready on launch escalation."))
        XCTAssertTrue(subtitle.contains("Last auto trigger: Urgency Critical escalation."))
        XCTAssertFalse(subtitle.contains("Route decision:"))
    }

    func testLaunchRescueAutoStatusMenuTitleFormatsStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(.disabled),
            "Launch Rescue Auto: Off"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(.ready),
            "Launch Rescue Auto: Ready"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(.coolingDown(minutesRemaining: 7)),
            "Launch Rescue Auto: Cooldown 7m"
        )
    }

    func testLaunchRescueAutoStatusMenuToolTipFormatsCoreStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuToolTip(.disabled),
            "Status: Auto rescue is off. Enable in Settings > Fame Ops.\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto.\nCommand: Run Launch Rescue Burst"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuToolTip(
                .ready,
                lastAutoTriggerReason: "urgency-high"
            ),
            "Status: Auto rescue is ready on launch escalation.\nLast auto trigger: Urgency High escalation.\nTrigger severity: High\nFollow-up: Run next move and ship the first block now.\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto.\nCommand: Run Launch Rescue Burst"
        )
    }

    func testLaunchRescueAutoStatusMenuToolTipIncludesTriggerTimeFollowupAndMomentumHints() {
        let now = Date(timeIntervalSince1970: 1_000)
        let tooltip = AppDelegate.launchRescueBurstAutoStatusMenuToolTip(
            .ready,
            modeMomentumStreak: -3,
            lastAutoTriggerReason: "urgency-critical",
            lastAutoTriggerAt: now.addingTimeInterval(-(12 * 60)),
            now: now
        )
        XCTAssertTrue(tooltip.contains("Status: Auto rescue is ready on launch escalation."))
        XCTAssertTrue(tooltip.contains("Last auto trigger: Urgency Critical escalation."))
        XCTAssertTrue(tooltip.contains("Trigger severity: Critical"))
        XCTAssertTrue(tooltip.contains("Last auto trigger time: 12m ago."))
        XCTAssertTrue(tooltip.contains("Follow-up: Priority window active. Ship a recovery update now."))
        XCTAssertTrue(tooltip.contains("Cooldown streak x3 · rescue priority"))
        XCTAssertTrue(tooltip.contains("Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(tooltip.contains("Command: Run Launch Rescue Burst"))
    }

    func testLaunchRescueAutoStatusMenuToolTipTrimsBlankOptionalStatusLines() {
        let tooltip = AppDelegate.launchRescueBurstAutoStatusMenuToolTip(
            .ready,
            lastAutoTriggerReason: "urgency-high",
            selfHealStatusTitle: "   ",
            selfHealAttentionStatusTitle: "\n",
            followupOutcomeScoreboardStatusTitle: "  Scoreboard line  ",
            followupOutcomeCoachStatusTitle: " ",
            followupOutcomeMomentumStatusTitle: "\t"
        )

        XCTAssertEqual(
            tooltip,
            """
            Status: Auto rescue is ready on launch escalation.
            Last auto trigger: Urgency High escalation.
            Trigger severity: High
            Follow-up: Run next move and ship the first block now.
            Scoreboard line
            Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto.
            Command: Run Launch Rescue Burst
            """
        )
    }

    func testAutoOpsBundleStatusActionTitleAndSubtitleFormatStates() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionTitle(.disabled),
            "Fame Auto Bundle: Enable"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSubtitle(.disabled),
            "Auto bundle is off. Open Settings > Fame Ops."
        )

        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionTitle(.ready),
            "Fame Auto Bundle: Run Now"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSubtitle(.ready),
            "Auto bundle is ready on escalation. Run once now."
        )

        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionTitle(.coolingDown(minutesRemaining: 9)),
            "Fame Auto Bundle: Cooldown 9m"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSubtitle(.coolingDown(minutesRemaining: 9)),
            "Next auto run in about 9 min. Run once now."
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionTitle(
                .ready,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Fame Auto Bundle: Run Now · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSubtitle(
                .ready,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Auto bundle is ready on escalation. Run once now. · Route Burst · Self-Heal Missing x1"
        )
    }

    func testAutoOpsBundleStatusActionSystemImageFormatsStates() {
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSystemImage(.disabled),
            "gearshape"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSystemImage(.ready),
            "shippingbox.circle"
        )
        XCTAssertEqual(
            AppDelegate.autoOpsBundleStatusActionSystemImage(.coolingDown(minutesRemaining: 4)),
            "hourglass.circle"
        )
    }

    @MainActor
    func testAutoOpsBundleStatusActionForTestingDisabledCanIncludeRouteAndSelfHealPrompt() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 0

        let delegate = AppDelegate()
        delegate.runFameAutoBundleStatusActionForTesting(now: now, defaults: defaults)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto bundle is off. Enable it in Settings · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("run-fame-auto-bundle-status-settings"))
    }

    @MainActor
    func testAutoOpsBundleStatusActionForTestingDisabledOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 0

        let delegate = AppDelegate()
        delegate.runFameAutoBundleStatusActionForTesting(now: now, defaults: defaults)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto bundle is off. Enable it in Settings · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("run-fame-auto-bundle-status-settings"))
    }

    @MainActor
    func testAutoOpsBundleStatusActionForTestingRunNowUsesReadyAndCoolingStates() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 30

        let delegate = AppDelegate()
        var runNowCount = 0

        delegate.runFameAutoBundleStatusActionForTesting(
            now: now,
            defaults: defaults,
            runNowHandler: { runNowCount += 1 }
        )
        defaults.set(now.timeIntervalSince1970, forKey: autoOpsLastRunAtKey)
        delegate.runFameAutoBundleStatusActionForTesting(
            now: now,
            defaults: defaults,
            runNowHandler: { runNowCount += 1 }
        )

        XCTAssertEqual(runNowCount, 2)
        let runNowDetails = ActivityLogStore(defaults: defaults).items
            .map(\.detail)
            .filter { $0 == "run-fame-auto-bundle-status-run-now" }
        XCTAssertEqual(runNowDetails.count, 2)
    }

    @MainActor
    func testReaderAutoOpsBundleStatusTapForTestingDisabledCanIncludeRouteAndSelfHealPrompt() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 0

        let delegate = AppDelegate()
        delegate.handleReaderAutoOpsBundleStatusTapForTesting(now: now, defaults: defaults)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto bundle is off. Enable it in Settings · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-auto-bundle-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("run-fame-auto-bundle-status-settings"))
    }

    @MainActor
    func testReaderAutoOpsBundleStatusTapForTestingDisabledOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 0

        let delegate = AppDelegate()
        delegate.handleReaderAutoOpsBundleStatusTapForTesting(now: now, defaults: defaults)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto bundle is off. Enable it in Settings · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-auto-bundle-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("run-fame-auto-bundle-status-settings"))
    }

    @MainActor
    func testReaderAutoOpsBundleStatusTapForTestingRunNowUsesReadyAndCoolingStates() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let autoOpsLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoOpsLastRunAt = defaults.object(forKey: autoOpsLastRunAtKey)
        let previousAutoOpsCooldownMinutes = settings.fameAutoOpsBundleCooldownMinutes

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            restoreDefaultsObject(previousAutoOpsLastRunAt, forKey: autoOpsLastRunAtKey)
            settings.fameAutoOpsBundleCooldownMinutes = previousAutoOpsCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.removeObject(forKey: activityLogKey)
        defaults.removeObject(forKey: autoOpsLastRunAtKey)
        settings.fameAutoOpsBundleCooldownMinutes = 30

        let delegate = AppDelegate()
        var runNowCount = 0

        delegate.handleReaderAutoOpsBundleStatusTapForTesting(
            now: now,
            defaults: defaults,
            runNowHandler: { runNowCount += 1 }
        )
        defaults.set(now.timeIntervalSince1970, forKey: autoOpsLastRunAtKey)
        delegate.handleReaderAutoOpsBundleStatusTapForTesting(
            now: now,
            defaults: defaults,
            runNowHandler: { runNowCount += 1 }
        )

        XCTAssertEqual(runNowCount, 2)
        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        let runNowDetails = loggedDetails.filter { $0 == "run-fame-auto-bundle-status-run-now" }
        let pillTapDetails = loggedDetails.filter { $0 == "reader-auto-bundle-status-pill-tap" }
        XCTAssertEqual(runNowDetails.count, 2)
        XCTAssertEqual(pillTapDetails.count, 2)
        XCTAssertFalse(loggedDetails.contains("run-fame-auto-bundle-status-settings"))
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusTapForTestingDisabledCanIncludeRouteAndSelfHealPrompt() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 0

        let delegate = AppDelegate()
        delegate.handleReaderLaunchRescueAutoStatusTapForTesting(
            now: now,
            defaults: defaults
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Launch rescue auto-burst is off. Enable it in Settings · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-launch-rescue-auto-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-settings"))
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusTapForTestingDisabledOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 0

        let delegate = AppDelegate()
        delegate.handleReaderLaunchRescueAutoStatusTapForTesting(
            now: now,
            defaults: defaults
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Launch rescue auto-burst is off. Enable it in Settings · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-launch-rescue-auto-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-settings"))
    }

    @MainActor
    func testRunFameLaunchControlBriefForTestingIncludesRouteDecisionTraceWhenEscalated() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.runFameLaunchControlBriefForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            feedback.petMessage.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertFalse(feedback.petMessage.contains("Copied launch control brief."))
    }

    @MainActor
    func testRunFameLaunchControlBriefForTestingOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.runFameLaunchControlBriefForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch control brief."))
    }

    @MainActor
    func testRunFameLaunchControlHubForTestingIncludesRouteDecisionTraceWhenEscalated() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        _ = delegate.runFameLaunchControlHubForTesting(
            source: "manual",
            announce: true,
            now: now
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch control hub ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            feedback.petMessage.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertFalse(feedback.petMessage.contains("Copied launch control hub run summary."))
    }

    @MainActor
    func testRunFameLaunchControlHubForTestingOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        _ = delegate.runFameLaunchControlHubForTesting(
            source: "manual",
            announce: true,
            now: now
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch control hub ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch control hub run summary."))
    }

    @MainActor
    func testRunFameLaunchRescueSnapshotForTestingIncludesRouteDecisionTraceWhenEscalated() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.runFameLaunchRescueSnapshotForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch rescue snapshot ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            feedback.petMessage.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertFalse(feedback.petMessage.contains("Copied launch rescue snapshot."))
    }

    @MainActor
    func testRunFameLaunchRescueSnapshotForTestingOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.runFameLaunchRescueSnapshotForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch rescue snapshot ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch rescue snapshot."))
    }

    @MainActor
    func testCopyFameLaunchControlBriefForTestingIncludesRouteDecisionTraceWhenEscalated() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.copyFameLaunchControlBriefForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief copied"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            feedback.petMessage.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertFalse(feedback.petMessage.contains("Copied launch control brief."))
    }

    @MainActor
    func testCopyFameLaunchControlBriefForTestingOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.copyFameLaunchControlBriefForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief copied"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch control brief."))
    }

    @MainActor
    func testRunFameOnboardingNudgeForTestingPreservesProgressPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let previousOnboardingEnabled = settings.fameOnboardingNudgeEnabled
        let previousOnboardingWindowDays = settings.fameOnboardingNudgeWindowDays
        let previousCadenceCurrent = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        let previousCadenceBest = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        let previousInstallDay = defaults.object(forKey: "firstRunInstallDay")
        let previousCompletedDays = defaults.object(forKey: "fameOnboardingCompletedDays")
        let previousNudgeLastShownDay = defaults.object(forKey: "fameOnboardingNudgeLastShownDay")
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            settings.fameOnboardingNudgeEnabled = previousOnboardingEnabled
            settings.fameOnboardingNudgeWindowDays = previousOnboardingWindowDays
            restoreDefaultsObject(previousCadenceCurrent, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
            restoreDefaultsObject(previousCadenceBest, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
            restoreDefaultsObject(previousInstallDay, forKey: "firstRunInstallDay")
            restoreDefaultsObject(previousCompletedDays, forKey: "fameOnboardingCompletedDays")
            restoreDefaultsObject(previousNudgeLastShownDay, forKey: "fameOnboardingNudgeLastShownDay")
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        settings.fameOnboardingNudgeEnabled = true
        settings.fameOnboardingNudgeWindowDays = 7
        defaults.set(3, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        defaults.set(Self.dayStamp(daysFromNow: -2), forKey: "firstRunInstallDay")
        defaults.set(2, forKey: "fameOnboardingCompletedDays")
        defaults.removeObject(forKey: "fameOnboardingNudgeLastShownDay")

        let now = Date()
        let delegate = AppDelegate()
        delegate.runFameOnboardingNudgeForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("fame onboarding ready"))
        XCTAssertTrue(feedback.petMessage.contains("complete"))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame onboarding nudge."))
    }

    @MainActor
    func testRunFameOnboardingDailyBriefForTestingPreservesProgressPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let previousOnboardingEnabled = settings.fameOnboardingNudgeEnabled
        let previousOnboardingWindowDays = settings.fameOnboardingNudgeWindowDays
        let previousCadenceCurrent = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        let previousCadenceBest = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        let previousInstallDay = defaults.object(forKey: "firstRunInstallDay")
        let previousCompletedDays = defaults.object(forKey: "fameOnboardingCompletedDays")
        let previousNudgeLastShownDay = defaults.object(forKey: "fameOnboardingNudgeLastShownDay")
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            settings.fameOnboardingNudgeEnabled = previousOnboardingEnabled
            settings.fameOnboardingNudgeWindowDays = previousOnboardingWindowDays
            restoreDefaultsObject(previousCadenceCurrent, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
            restoreDefaultsObject(previousCadenceBest, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
            restoreDefaultsObject(previousInstallDay, forKey: "firstRunInstallDay")
            restoreDefaultsObject(previousCompletedDays, forKey: "fameOnboardingCompletedDays")
            restoreDefaultsObject(previousNudgeLastShownDay, forKey: "fameOnboardingNudgeLastShownDay")
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        settings.fameOnboardingNudgeEnabled = true
        settings.fameOnboardingNudgeWindowDays = 7
        defaults.set(3, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        defaults.set(Self.dayStamp(daysFromNow: -2), forKey: "firstRunInstallDay")
        defaults.set(2, forKey: "fameOnboardingCompletedDays")
        defaults.removeObject(forKey: "fameOnboardingNudgeLastShownDay")

        let now = Date()
        let delegate = AppDelegate()
        delegate.runFameOnboardingDailyBriefForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("First-week daily brief ready."))
        XCTAssertTrue(feedback.petMessage.contains("complete"))
        XCTAssertFalse(feedback.petMessage.contains("Copied first-week daily brief."))
    }

    @MainActor
    func testRunFameOnboardingScorecardForTestingPreservesProgressPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let previousOnboardingEnabled = settings.fameOnboardingNudgeEnabled
        let previousOnboardingWindowDays = settings.fameOnboardingNudgeWindowDays
        let previousCadenceCurrent = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        let previousCadenceBest = defaults.object(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        let previousInstallDay = defaults.object(forKey: "firstRunInstallDay")
        let previousCompletedDays = defaults.object(forKey: "fameOnboardingCompletedDays")
        let previousNudgeLastShownDay = defaults.object(forKey: "fameOnboardingNudgeLastShownDay")
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            settings.fameOnboardingNudgeEnabled = previousOnboardingEnabled
            settings.fameOnboardingNudgeWindowDays = previousOnboardingWindowDays
            restoreDefaultsObject(previousCadenceCurrent, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
            restoreDefaultsObject(previousCadenceBest, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
            restoreDefaultsObject(previousInstallDay, forKey: "firstRunInstallDay")
            restoreDefaultsObject(previousCompletedDays, forKey: "fameOnboardingCompletedDays")
            restoreDefaultsObject(previousNudgeLastShownDay, forKey: "fameOnboardingNudgeLastShownDay")
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        settings.fameOnboardingNudgeEnabled = true
        settings.fameOnboardingNudgeWindowDays = 7
        defaults.set(3, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(4, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        defaults.set(Self.dayStamp(daysFromNow: -2), forKey: "firstRunInstallDay")
        defaults.set(2, forKey: "fameOnboardingCompletedDays")
        defaults.removeObject(forKey: "fameOnboardingNudgeLastShownDay")

        let now = Date()
        let delegate = AppDelegate()
        delegate.runFameOnboardingScorecardForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("First-week scorecard ready."))
        XCTAssertTrue(feedback.petMessage.contains("complete"))
        XCTAssertFalse(feedback.petMessage.contains("Copied first-week fame scorecard."))
    }

    @MainActor
    func testRunFameCadenceMomentumBriefForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameCadenceMomentumBriefForTesting(now: Date())

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Cadence momentum brief ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence momentum brief."))
    }

    @MainActor
    func testCopyFameCadenceShareLineForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.saveCadenceMomentumBrief(
                markdown: """
                # Fluid Reader Cadence Momentum Brief

                - Fame momentum: Build streak x3 · Next Move + Copy Draft Pack · copy share line
                """,
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.copyFameCadenceShareLineForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Cadence share line ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence share line."))
    }

    @MainActor
    func testCopyFameCadenceSharePackForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.copyFameCadenceSharePackForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Cadence share pack ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence share pack."))
    }

    @MainActor
    func testCopyWinRecapForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copyWinRecapForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Win recap ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied win recap."))
    }

    @MainActor
    func testCopyLaunchKitForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copyLaunchKitForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch kit ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch kit."))
    }

    @MainActor
    func testCopyFameBoardForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copyFameBoardForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Fame board ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame board."))
    }

    @MainActor
    func testCopyFameSprintForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copyFameSprintForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Fame sprint ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame sprint."))
    }

    @MainActor
    func testCopyFamePackForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copyFamePackForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Fame pack ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame pack."))
    }

    @MainActor
    func testCopyFounderCommandPresetsForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copyFounderCommandPresetsForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Founder command presets ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied founder presets."))
    }

    @MainActor
    func testCopySetupGuideForTestingPreservesReadyPromptAfterCopy() {
        let delegate = AppDelegate()
        delegate.copySetupGuideForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Setup guide ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied setup guide."))
    }

    @MainActor
    func testUtilityCopyForTestingCanClearPreviousErrorState() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.copyLatestNextMoveDraftPackForTesting()
        let initialFeedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(initialFeedback.errorText, "No saved next move handoff yet.")

        delegate.copyWinRecapForTesting()
        let afterFeedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(afterFeedback.errorText, "")
        XCTAssertTrue(afterFeedback.petMessage.contains("Win recap ready."))
    }

    @MainActor
    func testRunFamePulseNudgeForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFamePulseNudgeForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(feedback.petMessage, "Pulse nudge ready.")
        XCTAssertFalse(feedback.petMessage.contains("Copied fame pulse nudge."))
    }

    @MainActor
    func testRunFameSprintForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
        }

        let delegate = AppDelegate()
        delegate.runFameSprintForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(feedback.petMessage, "Fame sprint ready.")
        XCTAssertFalse(feedback.petMessage.contains("Copied today sprint."))
    }

    @MainActor
    func testRunFameMorningBriefForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let lastRunDayKey = "fameMorningBriefLastRunDay"
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousLastRunDay = defaults.object(forKey: lastRunDayKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousLastRunDay, forKey: lastRunDayKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameMorningBriefForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Morning fame brief ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied morning fame brief."))
    }

    @MainActor
    func testRunFameWeeklyRollupForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameWeeklyRollupForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Weekly rollup ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied weekly rollup."))
    }

    @MainActor
    func testRunFameMiddayBriefForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameMiddayBriefForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Midday fame brief ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied midday fame brief."))
    }

    @MainActor
    func testRunFameEveningBriefForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameEveningBriefForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Evening fame brief ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied evening fame brief."))
    }

    @MainActor
    func testRunFameOpsBundleForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameOpsBundleForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Ops bundle ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame ops bundle."))
    }

    @MainActor
    func testRunFameDailyCheckpointForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameDailyCheckpointForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Daily checkpoint ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied daily checkpoint."))
    }

    @MainActor
    func testRunFameDailyScorecardForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameDailyScorecardForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Daily scorecard ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied daily scorecard."))
    }

    @MainActor
    func testRunFame24hQueueForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFame24hQueueForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Daily mission ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied daily mission."))
    }

    @MainActor
    func testRunFameCommandCenterForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameCommandCenterForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Command center ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame command center."))
    }

    @MainActor
    func testRunFameBreakthroughForecastForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameBreakthroughForecastForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Breakthrough forecast ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame breakthrough forecast."))
    }

    @MainActor
    func testRunFameLaunchDayScriptForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        delegate.runFameLaunchDayScriptForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch day script ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame launch day script."))
    }

    @MainActor
    func testRunFameLaunchRescueBurstForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        XCTAssertNoThrow(
            try FameSnapshotArchive.save(
                sprintMarkdown: """
                # Fluid Reader Fame Sprint Today
                Date: 2026-06-12 (Day 3)
                Stage: Momentum
                Score target: 32
                """,
                packMarkdown: "# Pack",
                now: Date()
            )
        )

        let delegate = AppDelegate()
        let didRun = delegate.runFameLaunchRescueBurstForTesting()

        XCTAssertTrue(didRun)
        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch rescue burst ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch rescue draft pack."))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch rescue handoff."))
    }

    @MainActor
    func testRunWarRoomForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.runWarRoomForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("War room ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied war room."))
    }

    @MainActor
    func testRunFameEscalationNudgeForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameEscalationNudgeForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Escalation nudge ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied escalation nudge."))
    }

    @MainActor
    func testRunFameRecoverySprintForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameRecoverySprintForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Recovery sprint ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame recovery sprint."))
    }

    @MainActor
    func testRunFameRecoveryChecklistForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameRecoveryChecklistForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Recovery checklist ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied recovery checklist."))
    }

    @MainActor
    func testRunFameRecoveryProofPackForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameRecoveryProofPackForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Recovery proof pack ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied recovery proof pack."))
    }

    @MainActor
    func testRunFameRiskTimelineForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameRiskTimelineForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Risk timeline ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame risk timeline."))
    }

    @MainActor
    func testRunFameOperatorDashboardForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameOperatorDashboardForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Operator dashboard ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame operator dashboard."))
    }

    @MainActor
    func testRunFameNarrativeLabForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNarrativeLabForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Narrative lab ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame narrative lab."))
    }

    @MainActor
    func testRunFameSpotlightPackForTestingPreservesReadyPromptAfterCopy() {
        let defaults = UserDefaults.standard
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameSpotlightPackForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Spotlight pack ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame spotlight pack."))
    }

    @MainActor
    func testRunFameNextMoveForTestingPreservesCommandPromptAfterHandoffCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied founder fame next-move handoff."))
    }

    @MainActor
    func testRunFameNextMoveCopyDraftPackForTestingPreservesCommandPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveCopyDraftPackForTesting(commandID: "run-fame-launch-control-brief")

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied next-move draft pack."))
    }

    @MainActor
    func testRunFameNextMoveCadenceExecutionKitForTestingPreservesCommandPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveCadenceExecutionKitForTesting(commandID: "run-fame-launch-control-brief")

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch control brief ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence execution post."))
    }

    @MainActor
    func testCopyLatestNextMoveDraftPackForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveDraftPackForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Next-move draft pack ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied next-move draft pack."))
    }

    @MainActor
    func testCopyLatestNextMoveCadenceStepForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveCadenceStepForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("First cadence step ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied first cadence step."))
    }

    @MainActor
    func testCopyLatestNextMoveCadencePostForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveCadencePostForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Cadence post ready now."))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence post now."))
    }

    @MainActor
    func testCopyLatestNextMoveCadencePostQueueForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveCadencePostQueueForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Cadence post queue ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence post + queue."))
    }

    @MainActor
    func testCopyLatestNextMoveCadenceExecutionKitForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveCadenceExecutionKitForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Cadence execution kit ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied cadence execution post."))
    }

    @MainActor
    func testCopyLatestNextMoveReplyLadderForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveReplyLadderForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Next-move reply ladder ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied next-move reply ladder."))
    }

    @MainActor
    func testCopyLatestNextMoveLaunchNowSequenceForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveLaunchNowSequenceForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch-now sequence ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch now sequence."))
    }

    @MainActor
    func testCopyLatestNextMoveChannelDraftForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveChannelDraftForTesting(.x)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("X draft ready."))
        XCTAssertFalse(feedback.petMessage.contains("Copied X draft."))
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelLaunchPackForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveBestChannelLaunchPackForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Best channel launch pack ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied best channel post ("))
    }

    @MainActor
    func testCopyLatestNextMoveBestChannelDraftForTestingPreservesReadyPromptAfterCopy() {
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let delegate = AppDelegate()
        delegate.runFameNextMoveForTesting(commandID: "run-fame-launch-control-brief")
        delegate.copyLatestNextMoveBestChannelDraftForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Best channel draft ready"))
        XCTAssertFalse(feedback.petMessage.contains("Copied best channel draft ("))
    }

    @MainActor
    func testRunFameLaunchCountdownForTestingIncludesRouteDecisionTraceWhenEscalated() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date()
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        XCTAssertNoThrow(
            try FameSnapshotArchive.saveLaunchDayScript(
                markdown: "# Launch Day Script\n\n- Ship now.\n",
                now: now
            )
        )

        let delegate = AppDelegate()
        delegate.runFameLaunchCountdownForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch countdown ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            feedback.petMessage.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertFalse(feedback.petMessage.contains("Copied fame launch countdown."))
    }

    @MainActor
    func testRunFameLaunchCountdownForTestingOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date()
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        XCTAssertNoThrow(
            try FameSnapshotArchive.saveLaunchDayScript(
                markdown: "# Launch Day Script\n\n- Ship now.\n",
                now: now
            )
        )

        let delegate = AppDelegate()
        delegate.runFameLaunchCountdownForTesting()

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertTrue(feedback.petMessage.contains("Launch countdown ready"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertFalse(feedback.petMessage.contains("Copied fame launch countdown."))
    }

    @MainActor
    func testCopyFameLaunchRescueSnapshotForTestingIncludesRouteDecisionTraceWhenEscalated() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.copyFameLaunchRescueSnapshotForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch rescue snapshot copied"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertTrue(
            feedback.petMessage.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertFalse(feedback.petMessage.contains("Copied launch rescue snapshot."))
    }

    @MainActor
    func testCopyFameLaunchRescueSnapshotForTestingOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let archiveBaseline = captureFameSnapshotArchiveBaseline()

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            if let archiveBaseline {
                removeNewFameSnapshotArchiveArtifacts(
                    directoryURL: archiveBaseline.directoryURL,
                    baselineFileNames: archiveBaseline.fileNames
                )
            }
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.removeObject(forKey: activityLogKey)

        let delegate = AppDelegate()
        delegate.copyFameLaunchRescueSnapshotForTesting(now: now)

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertTrue(feedback.petMessage.contains("Launch rescue snapshot copied"))
        XCTAssertTrue(feedback.petMessage.contains("Route Burst"))
        XCTAssertTrue(feedback.petMessage.contains("Self-Heal Missing x1"))
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertFalse(feedback.petMessage.contains("Copied launch rescue snapshot."))
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusTapForTestingReadyCanRunInjectedHandler() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 30

        let delegate = AppDelegate()
        var runNowCount = 0
        delegate.handleReaderLaunchRescueAutoStatusTapForTesting(
            now: now,
            defaults: defaults,
            runNowHandler: { runNowCount += 1 }
        )

        XCTAssertEqual(runNowCount, 1)
        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-launch-rescue-auto-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-run-now"))
        XCTAssertFalse(loggedDetails.contains("run-fame-launch-rescue-auto-status-settings"))
        XCTAssertFalse(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusTapForTestingCoolingDownCanUseOpenLatestFallbackPromptWhenBurstMissing() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(now.addingTimeInterval(-10).timeIntervalSince1970, forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()
        delegate.handleReaderLaunchRescueAutoStatusTapForTesting(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: { nil }
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "No saved launch rescue burst yet.")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto rescue cooling down (15m). Run launch rescue burst first · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-launch-rescue-auto-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("open-latest-launch-rescue-burst-empty"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
    }

    @MainActor
    func testReaderLaunchRescueAutoStatusTapForTestingCoolingDownOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(now.addingTimeInterval(-10).timeIntervalSince1970, forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()
        delegate.handleReaderLaunchRescueAutoStatusTapForTesting(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: { nil }
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "No saved launch rescue burst yet.")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto rescue cooling down (15m). Run launch rescue burst first · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("reader-launch-rescue-auto-status-pill-tap"))
        XCTAssertTrue(loggedDetails.contains("open-latest-launch-rescue-burst-empty"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
    }

    func testLaunchRescueAutoStatusActionTitleAndSubtitleFormatStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(.disabled),
            "Launch Rescue Auto: Enable"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(.disabled),
            "Launch rescue auto-burst is off. Open Settings > Fame Ops."
        )

        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(.ready),
            "Launch Rescue Auto: Run Now"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(.ready),
            "Launch rescue auto-burst is ready on launch escalation. Run once now."
        )

        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(.coolingDown(minutesRemaining: 9)),
            "Launch Rescue Auto: Cooldown 9m"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(.coolingDown(minutesRemaining: 9)),
            "Next auto rescue burst in about 9 min. Open latest or run now."
        )
    }

    func testLaunchRescueAutoStatusTitlesCanAppendCooldownMomentumBadge() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(
                .ready,
                modeMomentumStreak: -2
            ),
            "Launch Rescue Auto: Ready · Watch x2"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(
                .coolingDown(minutesRemaining: 9),
                modeMomentumStreak: -3
            ),
            "Launch Rescue Auto: Cooldown 9m · Alert x3"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(
                .ready,
                modeMomentumStreak: -2
            ),
            "Launch Rescue Auto: Run Now · Watch x2"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(
                .coolingDown(minutesRemaining: 9),
                modeMomentumStreak: -3
            ),
            "Launch Rescue Auto: Cooldown 9m · Alert x3"
        )
    }

    func testLaunchRescueAutoStatusMenuTitleCanAppendFollowupBadgeAndMomentumBadge() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(
                .ready,
                modeMomentumStreak: -2,
                followupBadge: "Now Next Move"
            ),
            "Launch Rescue Auto: Ready · Now Next Move · Watch x2"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(
                .coolingDown(minutesRemaining: 9),
                modeMomentumStreak: 0,
                followupBadge: "Close Blocker"
            ),
            "Launch Rescue Auto: Cooldown 9m · Close Blocker"
        )
    }

    func testLaunchRescueAutoStatusTitlesCanAppendTriggerSeverityBadge() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusMenuTitle(
                .ready,
                modeMomentumStreak: -2,
                followupBadge: "Now Next Move",
                triggerSeverityBadge: "Critical"
            ),
            "Launch Rescue Auto: Ready · Now Next Move · Watch x2 · Critical"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(
                .ready,
                modeMomentumStreak: -2,
                triggerSeverityBadge: "High"
            ),
            "Launch Rescue Auto: Run Now · Watch x2 · High"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionTitle(
                .ready,
                modeMomentumStreak: 0,
                triggerSeverityBadge: "High",
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Launch Rescue Auto: Run Now · High · Route Burst · Self-Heal Missing x1"
        )
    }

    func testLaunchRescueAutoTriggerFollowupMenuBadgeFormatsKnownAndFallbackStates() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                "urgency-critical",
                lastAutoTriggerAt: nil,
                now: now
            ),
            "Ship Update"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                "urgency-critical",
                lastAutoTriggerAt: now.addingTimeInterval(-(5 * 60)),
                now: now
            ),
            "Now Ship Update"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                "urgency-high",
                lastAutoTriggerAt: now.addingTimeInterval(-(2 * 60 * 60)),
                now: now
            ),
            "Next Move"
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                "none",
                lastAutoTriggerAt: now,
                now: now
            )
        )
    }

    @MainActor
    func testLaunchRescueAutoStatusActionCoolingDownCanUseOpenLatestFallbackPromptWhenBurstMissing() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(now.addingTimeInterval(-10).timeIntervalSince1970, forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()
        delegate.runFameLaunchRescueBurstAutoStatusActionForTesting(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: { nil }
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "No saved launch rescue burst yet.")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto rescue cooling down (15m). Run launch rescue burst first · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("open-latest-launch-rescue-burst-empty"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
    }

    @MainActor
    func testLaunchRescueAutoStatusActionCoolingDownOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(now.addingTimeInterval(-10).timeIntervalSince1970, forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()
        delegate.runFameLaunchRescueBurstAutoStatusActionForTesting(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: { nil }
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "No saved launch rescue burst yet.")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto rescue cooling down (15m). Run launch rescue burst first · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertEqual(feedback.petMood, .ready)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("open-latest-launch-rescue-burst-empty"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
    }

    @MainActor
    func testLaunchRescueAutoStatusActionCoolingDownCanOpenInjectedLatestBurst() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes
        let latestURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("launch-rescue-auto-status-\(UUID().uuidString).md")

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
            try? FileManager.default.removeItem(at: latestURL)
        }

        XCTAssertNoThrow(
            try "# Launch Rescue Burst\n\nKeep shipping.\n".write(
                to: latestURL,
                atomically: true,
                encoding: .utf8
            )
        )

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(now.addingTimeInterval(-10).timeIntervalSince1970, forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()
        delegate.runFameLaunchRescueBurstAutoStatusActionForTesting(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: { latestURL }
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto rescue cooling down (15m). Opened latest launch rescue burst · Route Burst · Self-Heal Missing x1. Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )
        XCTAssertEqual(feedback.petMood, .happy)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("open-latest-launch-rescue-burst"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
        XCTAssertFalse(loggedDetails.contains("open-latest-launch-rescue-burst-empty"))
    }

    @MainActor
    func testLaunchRescueAutoStatusActionCoolingDownOpenedPromptOmitsRouteDecisionTraceForDefaultRoute() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes
        let latestURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("launch-rescue-auto-status-\(UUID().uuidString).md")

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
            try? FileManager.default.removeItem(at: latestURL)
        }

        XCTAssertNoThrow(
            try "# Launch Rescue Burst\n\nKeep shipping.\n".write(
                to: latestURL,
                atomically: true,
                encoding: .utf8
            )
        )

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(now.addingTimeInterval(-10).timeIntervalSince1970, forKey: rescueLastRunAtKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let delegate = AppDelegate()
        delegate.runFameLaunchRescueBurstAutoStatusActionForTesting(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: { latestURL }
        )

        let feedback = delegate.readerFeedbackForTesting()
        XCTAssertEqual(feedback.errorText, "")
        XCTAssertEqual(
            feedback.petMessage,
            "Auto rescue cooling down (15m). Opened latest launch rescue burst · Route Burst · Self-Heal Missing x1."
        )
        XCTAssertFalse(feedback.petMessage.contains("Route decision:"))
        XCTAssertEqual(feedback.petMood, .happy)

        let loggedDetails = ActivityLogStore(defaults: defaults).items.map(\.detail)
        XCTAssertTrue(loggedDetails.contains("open-latest-launch-rescue-burst"))
        XCTAssertTrue(loggedDetails.contains("run-fame-launch-rescue-auto-status-open-latest"))
        XCTAssertFalse(loggedDetails.contains("open-latest-launch-rescue-burst-empty"))
    }

    @MainActor
    func testLaunchRescueAutoMenuStatusTitleCanIncludeFollowupBadgeFromDefaults() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(1_000.0, forKey: triggerAtKey)
        defaults.set(-2, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        XCTAssertEqual(
            AppDelegate().launchRescueAutoMenuStatusTitleForTesting(
                now: Date(timeIntervalSince1970: 1_000),
                defaults: defaults
            ),
            "Launch Rescue Auto: Ready · Now Ship Update · Watch x2 · Critical"
        )
    }

    @MainActor
    func testLaunchRescueAutoMenuStatusCanIncludeSelfHealBadgeAndTooltipFromActivityLog() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 1_000)
        let selfHealDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "healed"
        )
        let encodedActivityLog = try? JSONEncoder().encode([
            ActivityLogItem(
                id: UUID(),
                createdAt: now.addingTimeInterval(-90),
                category: "support",
                detail: selfHealDetail
            )
        ])

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(-2, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)
        defaults.set(encodedActivityLog, forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let appDelegate = AppDelegate()
        XCTAssertEqual(
            appDelegate.launchRescueAutoMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Launch Rescue Auto: Ready · Now Ship Update · Auto-Heal · Watch x2 · Critical"
        )
        let tooltip = appDelegate.launchRescueAutoMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(
            tooltip.contains(
                "Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Launch Rescue Burst · Reason: Urgency Critical escalation. · Freshness 1m ago."
            )
        )
    }

    @MainActor
    func testLaunchRescueAutoMenusShowSelfHealAttentionWhenLatestSnapshotIsMismatchedOrStale() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 1_000)
        let mismatchedRecentDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-high",
            routeCommandID: "run-fame-next-move-copy-drafts",
            outcome: "healed"
        )
        let matchingStaleDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-critical",
            routeCommandID: "run-fame-launch-rescue-burst",
            outcome: "failed"
        )
        let encodedActivityLog = try? JSONEncoder().encode([
            ActivityLogItem(
                id: UUID(),
                createdAt: now.addingTimeInterval(-120),
                category: "support",
                detail: mismatchedRecentDetail
            ),
            ActivityLogItem(
                id: UUID(),
                createdAt: now.addingTimeInterval(-(20 * 60)),
                category: "support",
                detail: matchingStaleDetail
            )
        ])

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(now.timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(-2, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)
        defaults.set(encodedActivityLog, forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let appDelegate = AppDelegate()
        XCTAssertEqual(
            appDelegate.launchRescueAutoMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Launch Rescue Auto: Ready · Now Ship Update · Self-Heal Mismatch x1 · Watch x2 · Critical"
        )
        let autoToolTip = appDelegate.launchRescueAutoMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(
            autoToolTip.contains(
                "Launch Rescue Auto Self-Heal Attention: Self-Heal Mismatch x1"
            )
        )
        XCTAssertTrue(
            autoToolTip.contains("Recommended: Run Launch Rescue Burst.")
        )
        XCTAssertFalse(autoToolTip.contains("Route decision:"))
        XCTAssertEqual(
            appDelegate.launchRescueFollowupNowMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Run Launch Rescue Follow-up Now · Critical · Self-Heal Mismatch x1"
        )
        let followupToolTip = appDelegate.launchRescueFollowupNowMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(
            followupToolTip.contains(
                "Launch Rescue Auto Self-Heal Attention: Self-Heal Mismatch x1"
            )
        )
        XCTAssertTrue(
            followupToolTip.contains("Recommended: Run Launch Rescue Burst.")
        )
    }

    @MainActor
    func testLaunchRescueFollowupMenusEscalateRouteForMissingSelfHealAttention() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let activityLogKey = ActivityLogStore.defaultStorageKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )
        let previousActivityLog = defaults.object(forKey: activityLogKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
            restoreDefaultsObject(previousActivityLog, forKey: activityLogKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        let now = Date(timeIntervalSince1970: 2_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.addingTimeInterval(-(22 * 60)).timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(0, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)
        defaults.removeObject(forKey: activityLogKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        let appDelegate = AppDelegate()
        XCTAssertEqual(
            appDelegate.launchRescueAutoMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Launch Rescue Auto: Ready · Route Burst · Self-Heal Missing x1 · High"
        )
        let autoToolTip = appDelegate.launchRescueAutoMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(
            autoToolTip.contains(
                "Launch Rescue Auto Self-Heal Attention: Self-Heal Missing x1"
            )
        )
        XCTAssertTrue(
            autoToolTip.contains("Recommended: Run Launch Rescue Burst.")
        )
        XCTAssertTrue(
            autoToolTip.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertEqual(
            appDelegate.launchRescueFollowupNowMenuStatusTitleForTesting(
                now: now,
                defaults: defaults
            ),
            "Run Launch Rescue Follow-up Now · High · Self-Heal Missing x1 · Route Burst"
        )
        let followupToolTip = appDelegate.launchRescueFollowupNowMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )
        XCTAssertTrue(
            followupToolTip.contains(
                "Route: Run Launch Rescue Burst. Priority window active. Run next move and ship the first block now."
            )
        )
        XCTAssertTrue(
            followupToolTip.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
        XCTAssertTrue(
            followupToolTip.contains(
                "Launch Rescue Auto Self-Heal Attention: Self-Heal Missing x1"
            )
        )
    }

    @MainActor
    func testLaunchRescueAutoMenuStatusToolTipCanIncludeFollowupAndMomentumFromDefaults() {
        let defaults = UserDefaults.standard
        let settings = SettingsStore.shared
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let modeMomentumKey = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        let rescueLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousModeMomentum = defaults.object(forKey: modeMomentumKey)
        let previousRescueLastRunAt = defaults.object(forKey: rescueLastRunAtKey)
        let previousAutoCooldownMinutes = settings.fameLaunchRescueBurstAutoCooldownMinutes

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousModeMomentum, forKey: modeMomentumKey)
            restoreDefaultsObject(previousRescueLastRunAt, forKey: rescueLastRunAtKey)
            settings.fameLaunchRescueBurstAutoCooldownMinutes = previousAutoCooldownMinutes
        }

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(1_000.0, forKey: triggerAtKey)
        defaults.set(-2, forKey: modeMomentumKey)
        defaults.removeObject(forKey: rescueLastRunAtKey)
        settings.fameLaunchRescueBurstAutoCooldownMinutes = 15

        XCTAssertEqual(
            AppDelegate().launchRescueAutoMenuStatusToolTipForTesting(
                now: Date(timeIntervalSince1970: 1_000),
                defaults: defaults
            ),
            "Status: Auto rescue is ready on launch escalation.\nLast auto trigger: Urgency Critical escalation.\nTrigger severity: Critical\nLast auto trigger time: Just now.\nFollow-up: Priority window active. Ship a recovery update now.\nLaunch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.\nLaunch Rescue Follow-up Coach: Baseline mode · execute Run Launch Rescue Burst once to seed outcomes.\nCooldown streak x2 · stage rescue now\nStatus shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto.\nCommand: Run Launch Rescue Burst"
        )
    }

    @MainActor
    func testLaunchRescueFollowupNowMenuStatusCanReflectDefaultsRouteAndPriorityWindow() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
        }

        defaults.set("urgency-critical", forKey: reasonKey)
        defaults.set(1_000.0, forKey: triggerAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)

        XCTAssertEqual(
            AppDelegate().launchRescueFollowupNowMenuStatusTitleForTesting(
                now: Date(timeIntervalSince1970: 1_000),
                defaults: defaults
            ),
            "Run Launch Rescue Follow-up Now · Critical"
        )
        let followupToolTip = AppDelegate().launchRescueFollowupNowMenuStatusToolTipForTesting(
            now: Date(timeIntervalSince1970: 1_000),
            defaults: defaults
        )
        XCTAssertEqual(
            followupToolTip,
            "Route: Run Launch Rescue Burst. Priority window active. Ship a recovery update now.\nLaunch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.\nLaunch Rescue Follow-up Coach: Baseline mode · execute Run Launch Rescue Burst once to seed outcomes."
        )
        XCTAssertFalse(followupToolTip.contains("Route decision:"))
    }

    @MainActor
    func testLaunchRescueFollowupNowMenuStatusFallsBackWhenNoAutoTriggerRecorded() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let followupOutcomeTotalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let followupOutcomeSuccessCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let followupOutcomeLastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let followupOutcomeHistoryKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let followupCoachRecoveryLaneStreakKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousFollowupOutcomeTotalCount = defaults.object(forKey: followupOutcomeTotalCountKey)
        let previousFollowupOutcomeSuccessCount = defaults.object(forKey: followupOutcomeSuccessCountKey)
        let previousFollowupOutcomeLastAt = defaults.object(forKey: followupOutcomeLastAtKey)
        let previousFollowupOutcomeHistory = defaults.object(forKey: followupOutcomeHistoryKey)
        let previousFollowupCoachRecoveryLaneStreak = defaults.object(
            forKey: followupCoachRecoveryLaneStreakKey
        )

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(
                previousFollowupOutcomeTotalCount,
                forKey: followupOutcomeTotalCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeSuccessCount,
                forKey: followupOutcomeSuccessCountKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeLastAt,
                forKey: followupOutcomeLastAtKey
            )
            restoreDefaultsObject(
                previousFollowupOutcomeHistory,
                forKey: followupOutcomeHistoryKey
            )
            restoreDefaultsObject(
                previousFollowupCoachRecoveryLaneStreak,
                forKey: followupCoachRecoveryLaneStreakKey
            )
        }

        defaults.set("none", forKey: reasonKey)
        defaults.removeObject(forKey: triggerAtKey)
        defaults.set(0, forKey: followupOutcomeTotalCountKey)
        defaults.set(0, forKey: followupOutcomeSuccessCountKey)
        defaults.removeObject(forKey: followupOutcomeLastAtKey)
        defaults.removeObject(forKey: followupOutcomeHistoryKey)
        defaults.set(0, forKey: followupCoachRecoveryLaneStreakKey)

        XCTAssertEqual(
            AppDelegate().launchRescueFollowupNowMenuStatusTitleForTesting(
                defaults: defaults
            ),
            "Run Launch Rescue Follow-up Now"
        )
        XCTAssertEqual(
            AppDelegate().launchRescueFollowupNowMenuStatusToolTipForTesting(
                defaults: defaults
            ),
            "No auto trigger recorded yet. Route: Run Launch Control Brief.\nLaunch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.\nLaunch Rescue Follow-up Coach: Baseline mode · execute Run Launch Control Brief once to seed outcomes."
        )
    }

    @MainActor
    func testLaunchRescueFollowupNowMenuStatusToolTipCanShowRecoveryLaneEscalationArmed() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let totalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let successCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let lastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let historyKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let recoveryLaneStreakKey = AppDefaults.fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let recoveryChecklistCooldownAtKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousTotalCount = defaults.object(forKey: totalCountKey)
        let previousSuccessCount = defaults.object(forKey: successCountKey)
        let previousLastAt = defaults.object(forKey: lastAtKey)
        let previousHistory = defaults.object(forKey: historyKey)
        let previousRecoveryLaneStreak = defaults.object(forKey: recoveryLaneStreakKey)
        let previousRecoveryChecklistCooldownAt = defaults.object(forKey: recoveryChecklistCooldownAtKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousTotalCount, forKey: totalCountKey)
            restoreDefaultsObject(previousSuccessCount, forKey: successCountKey)
            restoreDefaultsObject(previousLastAt, forKey: lastAtKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
            restoreDefaultsObject(previousRecoveryLaneStreak, forKey: recoveryLaneStreakKey)
            restoreDefaultsObject(previousRecoveryChecklistCooldownAt, forKey: recoveryChecklistCooldownAtKey)
        }

        let now = Date(timeIntervalSince1970: 10_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(6, forKey: totalCountKey)
        defaults.set(2, forKey: successCountKey)
        defaults.set(now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970, forKey: lastAtKey)
        defaults.set(2, forKey: recoveryLaneStreakKey)
        defaults.removeObject(forKey: recoveryChecklistCooldownAtKey)
        defaults.set(
            try? JSONEncoder().encode([
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
            ]),
            forKey: historyKey
        )

        let toolTip = AppDelegate().launchRescueFollowupNowMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )

        XCTAssertTrue(toolTip.contains("Launch Rescue Follow-up Scoreboard: 24h 1/3 success (33%) · Rolling 2/6 success (33%) · Freshness 12m ago."))
        XCTAssertTrue(toolTip.contains("Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist armed (30m window) after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."))
        XCTAssertTrue(
            toolTip.contains(
                "Launch Rescue Follow-up Momentum: Recovery x2 · CD 30m · Steady →"
            )
        )
    }

    @MainActor
    func testLaunchRescueFollowupNowMenuStatusToolTipCanShowRecoveryLaneEscalationCooldown() {
        let defaults = UserDefaults.standard
        let reasonKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey
        let triggerAtKey = AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey
        let totalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let successCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let lastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let historyKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let recoveryLaneStreakKey = AppDefaults.fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        let recoveryChecklistCooldownAtKey = AppDefaults
            .fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
        let previousReason = defaults.object(forKey: reasonKey)
        let previousTriggerAt = defaults.object(forKey: triggerAtKey)
        let previousTotalCount = defaults.object(forKey: totalCountKey)
        let previousSuccessCount = defaults.object(forKey: successCountKey)
        let previousLastAt = defaults.object(forKey: lastAtKey)
        let previousHistory = defaults.object(forKey: historyKey)
        let previousRecoveryLaneStreak = defaults.object(forKey: recoveryLaneStreakKey)
        let previousRecoveryChecklistCooldownAt = defaults.object(forKey: recoveryChecklistCooldownAtKey)

        defer {
            restoreDefaultsObject(previousReason, forKey: reasonKey)
            restoreDefaultsObject(previousTriggerAt, forKey: triggerAtKey)
            restoreDefaultsObject(previousTotalCount, forKey: totalCountKey)
            restoreDefaultsObject(previousSuccessCount, forKey: successCountKey)
            restoreDefaultsObject(previousLastAt, forKey: lastAtKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
            restoreDefaultsObject(previousRecoveryLaneStreak, forKey: recoveryLaneStreakKey)
            restoreDefaultsObject(previousRecoveryChecklistCooldownAt, forKey: recoveryChecklistCooldownAtKey)
        }

        let now = Date(timeIntervalSince1970: 10_000)
        defaults.set("urgency-high", forKey: reasonKey)
        defaults.set(now.timeIntervalSince1970, forKey: triggerAtKey)
        defaults.set(6, forKey: totalCountKey)
        defaults.set(2, forKey: successCountKey)
        defaults.set(now.addingTimeInterval(-(12 * 60)).timeIntervalSince1970, forKey: lastAtKey)
        defaults.set(2, forKey: recoveryLaneStreakKey)
        defaults.set(now.addingTimeInterval(-(5 * 60)).timeIntervalSince1970, forKey: recoveryChecklistCooldownAtKey)
        defaults.set(
            try? JSONEncoder().encode([
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
            ]),
            forKey: historyKey
        )

        let toolTip = AppDelegate().launchRescueFollowupNowMenuStatusToolTipForTesting(
            now: now,
            defaults: defaults
        )

        XCTAssertTrue(
            toolTip.contains(
                "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 25m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."
            )
        )
        XCTAssertTrue(
            toolTip.contains(
                "Launch Rescue Follow-up Momentum: Recovery x2 · CD 25/30m · Steady →"
            )
        )
    }

    func testLaunchRescueFollowupOutcomeScoreboardStatusTitleFormats24hRollingAndFreshness() {
        let now = Date(timeIntervalSince1970: 1_000)
        let scoreboard = AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
            attempts24h: 2,
            successes24h: 1,
            attemptsRolling: 5,
            successesRolling: 3,
            lastOutcomeAt: now.addingTimeInterval(-(12 * 60)),
            lastSuccessAt: now.addingTimeInterval(-(12 * 60)),
            lastFailureAt: now.addingTimeInterval(-(2 * 60 * 60))
        )

        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeScoreboardStatusTitle(
                scoreboard,
                now: now
            ),
            "Launch Rescue Follow-up Scoreboard: 24h 1/2 success (50%) · Rolling 3/5 success (60%) · Freshness 12m ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeScoreboardStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 0,
                    successes24h: 0,
                    attemptsRolling: 0,
                    successesRolling: 0,
                    lastOutcomeAt: nil,
                    lastSuccessAt: nil,
                    lastFailureAt: nil
                ),
                now: now
            ),
            "Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet."
        )
    }

    func testLaunchRescueFollowupOutcomeCoachStatusTitleFormatsBaselineWinningAndRecoveryLanes() {
        let now = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeCoachStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 0,
                    successes24h: 0,
                    attemptsRolling: 0,
                    successesRolling: 0,
                    lastOutcomeAt: nil,
                    lastSuccessAt: nil,
                    lastFailureAt: nil
                ),
                triggerReason: "urgency-high",
                now: now
            ),
            "Launch Rescue Follow-up Coach: Baseline mode · execute Run Fame Next Move + Copy Draft Pack once to seed outcomes."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeCoachStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 2,
                    successes24h: 2,
                    attemptsRolling: 5,
                    successesRolling: 4,
                    lastOutcomeAt: now.addingTimeInterval(-(12 * 60)),
                    lastSuccessAt: now.addingTimeInterval(-(12 * 60)),
                    lastFailureAt: now.addingTimeInterval(-(4 * 60 * 60))
                ),
                triggerReason: "urgency-critical",
                now: now
            ),
            "Launch Rescue Follow-up Coach: Winning lane · keep Run Launch Rescue Burst cadence · Freshness 12m ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeCoachStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 3,
                    successes24h: 1,
                    attemptsRolling: 6,
                    successesRolling: 2,
                    lastOutcomeAt: now.addingTimeInterval(-(12 * 60)),
                    lastSuccessAt: now.addingTimeInterval(-(4 * 60 * 60)),
                    lastFailureAt: now.addingTimeInterval(-(12 * 60))
                ),
                triggerReason: "urgency-high",
                now: now
            ),
            "Launch Rescue Follow-up Coach: Recovery lane · pair Run Fame Next Move + Copy Draft Pack with Run Fame Recovery Checklist · Freshness 12m ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeCoachStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 3,
                    successes24h: 1,
                    attemptsRolling: 6,
                    successesRolling: 2,
                    lastOutcomeAt: now.addingTimeInterval(-(12 * 60)),
                    lastSuccessAt: now.addingTimeInterval(-(4 * 60 * 60)),
                    lastFailureAt: now.addingTimeInterval(-(12 * 60))
                ),
                triggerReason: "urgency-high",
                recoveryLaneStreak: 2,
                now: now
            ),
            "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist armed after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeCoachStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 3,
                    successes24h: 1,
                    attemptsRolling: 6,
                    successesRolling: 2,
                    lastOutcomeAt: now.addingTimeInterval(-(12 * 60)),
                    lastSuccessAt: now.addingTimeInterval(-(4 * 60 * 60)),
                    lastFailureAt: now.addingTimeInterval(-(12 * 60))
                ),
                triggerReason: "urgency-high",
                recoveryLaneStreak: 2,
                recoveryChecklistCooldownMinutesRemaining: 9,
                now: now
            ),
            "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupOutcomeCoachStatusTitle(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 3,
                    successes24h: 1,
                    attemptsRolling: 6,
                    successesRolling: 2,
                    lastOutcomeAt: now.addingTimeInterval(-(12 * 60)),
                    lastSuccessAt: now.addingTimeInterval(-(4 * 60 * 60)),
                    lastFailureAt: now.addingTimeInterval(-(12 * 60))
                ),
                triggerReason: "urgency-high",
                recoveryLaneStreak: 2,
                recoveryChecklistCooldownMinutes: 30,
                recoveryChecklistCooldownMinutesRemaining: 9,
                now: now
            ),
            "Launch Rescue Follow-up Coach: Recovery lane x2 · auto-checklist cooling down 9m of 30m after Run Fame Next Move + Copy Draft Pack · Freshness 12m ago."
        )
    }

    func testLaunchRescueFollowupCoachRecoveryLaneStreakNextResetsOrIncrementsAsExpected() {
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupCoachRecoveryLaneStreakNext(
                currentStreak: 0,
                lane: .recovery
            ),
            1
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupCoachRecoveryLaneStreakNext(
                currentStreak: 2,
                lane: .recovery
            ),
            3
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupCoachRecoveryLaneStreakNext(
                currentStreak: 3,
                lane: .winning
            ),
            0
        )
    }

    func testShouldAutoRunLaunchRescueFollowupRecoveryChecklistRequiresRecoveryLaneAndArmedStreak() {
        XCTAssertTrue(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .recovery,
                recoveryLaneStreak: 2,
                routeCommandID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .recovery,
                recoveryLaneStreak: 1,
                routeCommandID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .recovery,
                recoveryLaneStreak: 3,
                routeCommandID: "run-fame-recovery-checklist"
            )
        )
        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .stable,
                recoveryLaneStreak: 5,
                routeCommandID: "run-fame-next-move-copy-drafts"
            )
        )
    }

    func testShouldAutoRunLaunchRescueFollowupRecoveryChecklistRespectsCooldownWindow() {
        let now = Date(timeIntervalSince1970: 10_000)
        let routeCommandID = "run-fame-next-move-copy-drafts"

        XCTAssertFalse(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .recovery,
                recoveryLaneStreak: 2,
                routeCommandID: routeCommandID,
                lastAutoRecoveryChecklistAt: now.addingTimeInterval(-(5 * 60)),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .recovery,
                recoveryLaneStreak: 2,
                routeCommandID: routeCommandID,
                lastAutoRecoveryChecklistAt: now.addingTimeInterval(-(16 * 60)),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertTrue(
            AppDelegate.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
                lane: .recovery,
                recoveryLaneStreak: 2,
                routeCommandID: routeCommandID,
                lastAutoRecoveryChecklistAt: now,
                now: now,
                cooldown: 0
            )
        )
    }

    func testLaunchRescueFollowupRecoveryChecklistCooldownMinutesRemainingTracksWindow() {
        let now = Date(timeIntervalSince1970: 10_000)

        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
                lastAutoRecoveryChecklistAt: now.addingTimeInterval(-(14 * 60)),
                now: now,
                cooldown: 15 * 60
            ),
            1
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
                lastAutoRecoveryChecklistAt: now.addingTimeInterval(-(5 * 60)),
                now: now,
                cooldown: 15 * 60
            ),
            10
        )
        XCTAssertNil(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
                lastAutoRecoveryChecklistAt: now.addingTimeInterval(-(20 * 60)),
                now: now,
                cooldown: 15 * 60
            )
        )
        XCTAssertNil(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
                lastAutoRecoveryChecklistAt: nil,
                now: now,
                cooldown: 15 * 60
            )
        )
    }

    func testLaunchRescueFollowupRecoveryChecklistCooldownTrendTitleFormatsAdaptiveDirection() {
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownTrendTitle(
                currentMinutes: 20
            ),
            "Accelerating ↓"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownTrendTitle(
                currentMinutes: 30
            ),
            "Steady →"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownTrendTitle(
                currentMinutes: 45
            ),
            "Tightening ↑"
        )
    }

    func testLaunchRescueFollowupMomentumBadgeFormatsLaneCooldownAndTrend() {
        let scoreboard = AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
            attempts24h: 3,
            successes24h: 1,
            attemptsRolling: 6,
            successesRolling: 2,
            lastOutcomeAt: Date(timeIntervalSince1970: 1_000),
            lastSuccessAt: Date(timeIntervalSince1970: 900),
            lastFailureAt: Date(timeIntervalSince1970: 1_000)
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupMomentumBadge(
                scoreboard,
                recoveryLaneStreak: 2,
                recoveryChecklistCooldownMinutes: 25
            ),
            "Recovery x2 · CD 25m · Accelerating ↓"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupMomentumBadge(
                scoreboard,
                recoveryLaneStreak: 2,
                recoveryChecklistCooldownMinutes: 35,
                recoveryChecklistCooldownMinutesRemaining: 12
            ),
            "Recovery x2 · CD 12/35m · Tightening ↑"
        )
        XCTAssertNil(
            AppDelegate.launchRescueFollowupMomentumBadge(
                AppDelegate.LaunchRescueFollowupOutcomeScoreboard(
                    attempts24h: 0,
                    successes24h: 0,
                    attemptsRolling: 0,
                    successesRolling: 0,
                    lastOutcomeAt: nil,
                    lastSuccessAt: nil,
                    lastFailureAt: nil
                ),
                recoveryLaneStreak: 0,
                recoveryChecklistCooldownMinutes: 30
            )
        )
    }

    func testLaunchRescueFollowupRecoveryChecklistCooldownMinutesNextAdaptsAndRecenters() {
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: 30,
                lane: .winning,
                recoveryLaneStreak: 0,
                wasSuccessful: true
            ),
            25
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: 30,
                lane: .recovery,
                recoveryLaneStreak: 3,
                wasSuccessful: false
            ),
            35
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: 20,
                lane: .stable,
                recoveryLaneStreak: 0,
                wasSuccessful: true
            ),
            25
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: 40,
                lane: .watch,
                recoveryLaneStreak: 1,
                wasSuccessful: true
            ),
            35
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: 5,
                lane: .winning,
                recoveryLaneStreak: 0,
                wasSuccessful: true
            ),
            5
        )
        XCTAssertEqual(
            AppDelegate.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: 60,
                lane: .recovery,
                recoveryLaneStreak: 4,
                wasSuccessful: false
            ),
            60
        )
    }

    @MainActor
    func testLaunchRescueFollowupOutcomeScoreboardReadsRollingAnd24hCountsFromDefaults() {
        let defaults = UserDefaults.standard
        let totalCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey
        let successCountKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
        let lastAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey
        let lastSuccessAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey
        let lastFailureAtKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey
        let historyKey = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
        let previousTotalCount = defaults.object(forKey: totalCountKey)
        let previousSuccessCount = defaults.object(forKey: successCountKey)
        let previousLastAt = defaults.object(forKey: lastAtKey)
        let previousLastSuccessAt = defaults.object(forKey: lastSuccessAtKey)
        let previousLastFailureAt = defaults.object(forKey: lastFailureAtKey)
        let previousHistory = defaults.object(forKey: historyKey)

        defer {
            restoreDefaultsObject(previousTotalCount, forKey: totalCountKey)
            restoreDefaultsObject(previousSuccessCount, forKey: successCountKey)
            restoreDefaultsObject(previousLastAt, forKey: lastAtKey)
            restoreDefaultsObject(previousLastSuccessAt, forKey: lastSuccessAtKey)
            restoreDefaultsObject(previousLastFailureAt, forKey: lastFailureAtKey)
            restoreDefaultsObject(previousHistory, forKey: historyKey)
        }

        let now = Date(timeIntervalSince1970: 10_000)
        let lastOutcomeAt = now.addingTimeInterval(-(15 * 60))
        let lastFailureAt = now.addingTimeInterval(-(90 * 60))
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
                recordedAt: now.addingTimeInterval(-(30 * 60 * 60)).timeIntervalSince1970,
                wasSuccess: true
            )
        ]

        defaults.set(5, forKey: totalCountKey)
        defaults.set(4, forKey: successCountKey)
        defaults.set(lastOutcomeAt.timeIntervalSince1970, forKey: lastAtKey)
        defaults.set(lastOutcomeAt.timeIntervalSince1970, forKey: lastSuccessAtKey)
        defaults.set(lastFailureAt.timeIntervalSince1970, forKey: lastFailureAtKey)
        defaults.set(try? JSONEncoder().encode(history), forKey: historyKey)

        let scoreboard = AppDelegate.launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults
        )

        XCTAssertEqual(scoreboard.attempts24h, 2)
        XCTAssertEqual(scoreboard.successes24h, 1)
        XCTAssertEqual(scoreboard.attemptsRolling, 5)
        XCTAssertEqual(scoreboard.successesRolling, 4)
        XCTAssertEqual(scoreboard.lastOutcomeAt, lastOutcomeAt)
        XCTAssertEqual(scoreboard.lastSuccessAt, lastOutcomeAt)
        XCTAssertEqual(scoreboard.lastFailureAt, lastFailureAt)
    }

    func testLaunchRescueAutoTriggerStatusTitleFormatsKnownAndFallbackStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerStatusTitle("urgency-high"),
            "Launch Rescue Auto Trigger: Urgency High escalation."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerStatusTitle("momentum-alert"),
            "Launch Rescue Auto Trigger: Cooldown momentum alert streak."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerStatusTitle("pressure-persistence"),
            "Launch Rescue Auto Trigger: Launch health pressure persistence."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerStatusTitle(" unexpected-token "),
            "Launch Rescue Auto Trigger: No auto trigger recorded yet."
        )
    }

    func testLaunchRescueAutoTriggerStatusSubtitleHintFormatsKnownAndSkipsUnknown() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerStatusSubtitleHint("momentum-watch"),
            "Last auto trigger: Cooldown momentum watch streak."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerStatusSubtitleHint(" pressure-persistence "),
            "Last auto trigger: Launch health pressure persistence."
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerStatusSubtitleHint("none")
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerStatusSubtitleHint("unexpected-token")
        )
    }

    func testLaunchRescueAutoTriggerAtStatusTitleFormatsKnownAndFallbackStates() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtStatusTitle(nil, now: now),
            "Launch Rescue Auto Trigger Time: No auto trigger time recorded yet."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtStatusTitle(
                now.addingTimeInterval(-30),
                now: now
            ),
            "Launch Rescue Auto Trigger Time: Just now."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtStatusTitle(
                now.addingTimeInterval(-(12 * 60)),
                now: now
            ),
            "Launch Rescue Auto Trigger Time: 12m ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtStatusTitle(
                now.addingTimeInterval(-(3 * 60 * 60)),
                now: now
            ),
            "Launch Rescue Auto Trigger Time: 3h ago."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtStatusTitle(
                now.addingTimeInterval(-(2 * 24 * 60 * 60)),
                now: now
            ),
            "Launch Rescue Auto Trigger Time: 2d ago."
        )
    }

    func testLaunchRescueAutoTriggerAtStatusSubtitleHintFormatsKnownAndSkipsMissing() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtStatusSubtitleHint(
                now.addingTimeInterval(-(12 * 60)),
                now: now
            ),
            "Last auto trigger time: 12m ago."
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerAtStatusSubtitleHint(nil, now: now)
        )
    }

    func testLaunchRescueAutoTriggerAtDiagnosticSummaryFormatsIso8601AndFallback() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(
                Date(timeIntervalSince1970: 1_700_000_000)
            ),
            "2023-11-14T22:13:20Z"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(nil),
            "No auto trigger time recorded yet."
        )
    }

    func testLaunchRescueAutoTriggerFollowupStatusTitleFormatsPriorityCheckpointAndStandby() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupStatusTitle(
                "none",
                lastAutoTriggerAt: nil,
                now: now
            ),
            "Launch Rescue Auto Follow-up: Stand by."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupStatusTitle(
                "urgency-critical",
                lastAutoTriggerAt: nil,
                now: now
            ),
            "Launch Rescue Auto Follow-up: Ship a recovery update now."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupStatusTitle(
                "urgency-critical",
                lastAutoTriggerAt: now.addingTimeInterval(-(10 * 60)),
                now: now
            ),
            "Launch Rescue Auto Follow-up: Priority window active. Ship a recovery update now."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupStatusTitle(
                "urgency-high",
                lastAutoTriggerAt: now.addingTimeInterval(-(2 * 60 * 60)),
                now: now
            ),
            "Launch Rescue Auto Follow-up: Checkpoint. Run next move and ship the first block now."
        )
    }

    func testLaunchRescueAutoTriggerFollowupStatusSubtitleHintFormatsKnownAndSkipsUnknown() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupStatusSubtitleHint(
                "momentum-alert",
                lastAutoTriggerAt: now.addingTimeInterval(-(20 * 60)),
                now: now
            ),
            "Follow-up: Priority window active. Run launch rescue + next move before another dip."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupStatusSubtitleHint(
                "pressure-persistence",
                lastAutoTriggerAt: nil,
                now: now
            ),
            "Follow-up: Close one blocker before next health pulse."
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerFollowupStatusSubtitleHint(
                "none",
                lastAutoTriggerAt: now,
                now: now
            )
        )
    }

    func testLaunchRescueAutoTriggerFollowupSummaryAndMenuBadgeStayAlignedAcrossReasons() {
        let now = Date(timeIntervalSince1970: 10_000)
        let cases: [(token: String, actionLine: String, menuBadge: String, windowMinutes: Int)] = [
            ("urgency-critical", "Ship a recovery update now.", "Ship Update", 30),
            ("urgency-high", "Run next move and ship the first block now.", "Next Move", 45),
            ("momentum-alert", "Run launch rescue + next move before another dip.", "Rescue + Next", 60),
            ("momentum-watch", "Stage rescue draft before next escalation.", "Stage Rescue", 90),
            ("pressure-persistence", "Close one blocker before next health pulse.", "Close Blocker", 120)
        ]

        for testCase in cases {
            let insideWindow = now.addingTimeInterval(
                TimeInterval(-max(1, testCase.windowMinutes - 1) * 60)
            )
            let outsideWindow = now.addingTimeInterval(
                TimeInterval(-(testCase.windowMinutes + 1) * 60)
            )

            XCTAssertEqual(
                AppDelegate.launchRescueAutoTriggerFollowupSummary(
                    testCase.token,
                    lastAutoTriggerAt: nil,
                    now: now
                ),
                testCase.actionLine
            )
            XCTAssertEqual(
                AppDelegate.launchRescueAutoTriggerFollowupSummary(
                    testCase.token,
                    lastAutoTriggerAt: insideWindow,
                    now: now
                ),
                "Priority window active. \(testCase.actionLine)"
            )
            XCTAssertEqual(
                AppDelegate.launchRescueAutoTriggerFollowupSummary(
                    testCase.token,
                    lastAutoTriggerAt: outsideWindow,
                    now: now
                ),
                "Checkpoint. \(testCase.actionLine)"
            )

            XCTAssertEqual(
                AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                    testCase.token,
                    lastAutoTriggerAt: nil,
                    now: now
                ),
                testCase.menuBadge
            )
            XCTAssertEqual(
                AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                    testCase.token,
                    lastAutoTriggerAt: insideWindow,
                    now: now
                ),
                "Now \(testCase.menuBadge)"
            )
            XCTAssertEqual(
                AppDelegate.launchRescueAutoTriggerFollowupMenuBadge(
                    testCase.token,
                    lastAutoTriggerAt: outsideWindow,
                    now: now
                ),
                testCase.menuBadge
            )
        }
    }

    func testLaunchRescueAutoTriggerSeverityBadgeAndSubtitleHintFormatsKnownAndSkipsUnknown() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerSeverityBadge("urgency-critical"),
            "Critical"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerSeverityBadge(" urgency-high "),
            "High"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerSeverityBadge("momentum-watch"),
            "Momentum Watch"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerSeveritySubtitleHint("momentum-alert"),
            "Trigger severity: Momentum Alert"
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerSeveritySubtitleHint("none")
        )
    }

    func testLaunchRescueAutoFollowupResolvedRouteDecisionNormalizesRecommendationAndOverride() {
        let now = Date(timeIntervalSince1970: 1_000)
        let defaultDecision = AppDelegate.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: "urgency-high",
            recommendedActionID: nil
        )
        XCTAssertEqual(defaultDecision.defaultCommandID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(defaultDecision.resolvedCommandID, "run-fame-next-move-copy-drafts")
        XCTAssertNil(
            AppDelegate.launchRescueAutoFollowupRouteBadgeForResolvedDecision(
                defaultCommandID: defaultDecision.defaultCommandID,
                resolvedCommandID: defaultDecision.resolvedCommandID
            )
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupBadgeForResolvedDecision(
                triggerReason: "urgency-high",
                lastAutoTriggerAt: now.addingTimeInterval(-(2 * 60 * 60)),
                defaultCommandID: defaultDecision.defaultCommandID,
                resolvedCommandID: defaultDecision.resolvedCommandID,
                now: now
            ),
            "Next Move"
        )

        let recommendedDecision = AppDelegate.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: "urgency-high",
            recommendedActionID: "run-fame-launch-rescue-burst"
        )
        XCTAssertEqual(recommendedDecision.defaultCommandID, "run-fame-next-move-copy-drafts")
        XCTAssertEqual(recommendedDecision.resolvedCommandID, "run-fame-launch-rescue-burst")
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRouteBadgeForResolvedDecision(
                defaultCommandID: recommendedDecision.defaultCommandID,
                resolvedCommandID: recommendedDecision.resolvedCommandID
            ),
            "Route Burst"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupBadgeForResolvedDecision(
                triggerReason: "urgency-high",
                lastAutoTriggerAt: now.addingTimeInterval(-(2 * 60 * 60)),
                defaultCommandID: recommendedDecision.defaultCommandID,
                resolvedCommandID: recommendedDecision.resolvedCommandID,
                now: now
            ),
            "Route Burst"
        )

        let invalidRecommendationDecision = AppDelegate.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: "urgency-high",
            recommendedActionID: "unexpected-route"
        )
        XCTAssertEqual(
            invalidRecommendationDecision.resolvedCommandID,
            "run-fame-next-move-copy-drafts"
        )

        let overrideDecision = AppDelegate.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: "urgency-high",
            recommendedActionID: "run-fame-launch-rescue-burst",
            commandIDOverride: "run-fame-recovery-checklist"
        )
        XCTAssertEqual(overrideDecision.resolvedCommandID, "run-fame-recovery-checklist")
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRouteBadgeForResolvedDecision(
                defaultCommandID: overrideDecision.defaultCommandID,
                resolvedCommandID: overrideDecision.resolvedCommandID
            ),
            "Route Checklist"
        )

        let invalidOverrideDecision = AppDelegate.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: "urgency-high",
            recommendedActionID: "run-fame-launch-rescue-burst",
            commandIDOverride: "invalid-override"
        )
        XCTAssertEqual(invalidOverrideDecision.resolvedCommandID, "run-fame-launch-rescue-burst")
    }

    func testLaunchRescueAutoFollowupRouteDecisionTraceLineShowsOnlyEscalatedRoutes() {
        XCTAssertNil(
            AppDelegate.launchRescueAutoFollowupRouteDecisionTraceLine(
                defaultCommandID: "run-fame-next-move-copy-drafts",
                resolvedCommandID: "run-fame-next-move-copy-drafts"
            )
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRouteDecisionTraceLine(
                defaultCommandID: "run-fame-next-move-copy-drafts",
                resolvedCommandID: "run-fame-launch-rescue-burst"
            ),
            "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
        )

        let tooltip = AppDelegate.launchRescueAutoTriggerFollowupMenuToolTip(
            "urgency-high",
            lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (5 * 60)),
            routeCommandIDOverride: "run-fame-launch-rescue-burst",
            now: Date(timeIntervalSince1970: 1_000)
        )
        XCTAssertTrue(
            tooltip.contains(
                "Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack."
            )
        )
    }

    func testLaunchRescueAutoTriggerFollowupCommandRouteHelpersMapKnownReasonsAndFallback() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupCommandID("urgency-critical"),
            "run-fame-launch-rescue-burst"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupCommandID("urgency-high"),
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupCommandID("pressure-persistence"),
            "run-fame-recovery-checklist"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupCommandID("none"),
            "run-fame-launch-control-brief"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupCommandTitle("urgency-high"),
            "Run Fame Next Move + Copy Draft Pack"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupActionTitle("urgency-critical"),
            "Run Launch Rescue Follow-up Now · Critical"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupActionTitle(
                "urgency-critical",
                selfHealAttentionBadge: "Self-Heal Missing x1",
                routeBadge: "Route Burst"
            ),
            "Run Launch Rescue Follow-up Now · Critical · Self-Heal Missing x1 · Route Burst"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupActionSubtitle(
                "urgency-critical",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (5 * 60)),
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Route: Run Launch Rescue Burst. Priority window active. Ship a recovery update now."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupActionSubtitle(
                "urgency-high",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (5 * 60)),
                routeCommandIDOverride: "run-fame-launch-rescue-burst",
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Route: Run Launch Rescue Burst. Priority window active. Run next move and ship the first block now."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupActionSubtitle(
                "none",
                lastAutoTriggerAt: nil,
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "No auto trigger recorded yet. Route: Run Launch Control Brief."
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerFollowupMenuToolTip(
                "urgency-high",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (5 * 60)),
                selfHealStatusTitle: "  ",
                selfHealAttentionStatusTitle: "\n",
                followupOutcomeScoreboardStatusTitle: "  Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.  ",
                followupOutcomeCoachStatusTitle: " ",
                followupOutcomeMomentumStatusTitle: "\t",
                now: Date(timeIntervalSince1970: 1_000)
            ),
            """
            Route: Run Fame Next Move + Copy Draft Pack. Priority window active. Run next move and ship the first block now.
            Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.
            """
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRouteDecisionStatusTitle(
                triggerReason: "urgency-high",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (22 * 60)),
                activityItems: [],
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Launch Rescue Auto Follow-up Route Decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack · Self-Heal Missing x1."
        )
        let matchingDetail = AppDelegate.launchRescueAutoFollowupSelfHealActivityDetail(
            reasonToken: "urgency-high",
            routeCommandID: "run-fame-next-move-copy-drafts",
            outcome: "healed"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupRouteDecisionStatusTitle(
                triggerReason: "urgency-high",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (2 * 60)),
                activityItems: [
                    ActivityLogItem(
                        id: UUID(),
                        createdAt: Date(timeIntervalSince1970: 1_000 - 60),
                        category: "support",
                        detail: matchingDetail
                    )
                ],
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Launch Rescue Auto Follow-up Route Decision: Default route Run Fame Next Move + Copy Draft Pack."
        )
    }

    func testLaunchRescueAutoFollowupCommandIDNormalizesKnownAndUnknownValues() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupCommandID(" RUN-FAME-NEXT-MOVE-COPY-DRAFTS "),
            "run-fame-next-move-copy-drafts"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupCommandID("unexpected-command"),
            "none"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueAutoFollowupCommandTitle("run-fame-recovery-checklist"),
            "Run Fame Recovery Checklist"
        )
    }

    func testLaunchRescueAutoTriggerReasonResetTokenForRescueRunClearsOnlyAnnouncedRuns() {
        XCTAssertEqual(
            AppDelegate.launchRescueAutoTriggerReasonResetTokenForRescueRun(announce: true),
            "none"
        )
        XCTAssertNil(
            AppDelegate.launchRescueAutoTriggerReasonResetTokenForRescueRun(announce: false)
        )
        XCTAssertTrue(
            AppDelegate.launchRescueAutoTriggerAtShouldResetForRescueRun(announce: true)
        )
        XCTAssertFalse(
            AppDelegate.launchRescueAutoTriggerAtShouldResetForRescueRun(announce: false)
        )
    }

    func testLaunchRescueModeMomentumCueSeverityMapsCooldownStreakBands() {
        XCTAssertEqual(
            AppDelegate.launchRescueModeMomentumCueSeverity(modeMomentumStreak: 1),
            .none
        )
        XCTAssertEqual(
            AppDelegate.launchRescueModeMomentumCueSeverity(modeMomentumStreak: -2),
            .watch
        )
        XCTAssertEqual(
            AppDelegate.launchRescueModeMomentumCueSeverity(modeMomentumStreak: -3),
            .alert
        )
        XCTAssertEqual(
            AppDelegate.launchRescueModeMomentumCueTitleBadge(modeMomentumStreak: -2),
            "Watch x2"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueModeMomentumCueTitleBadge(modeMomentumStreak: -3),
            "Alert x3"
        )
    }

    func testLaunchRescueBurstSubtitlesCanAppendCooldownMomentumCue() {
        XCTAssertEqual(
            AppDelegate.launchCountdownActionSubtitle(
                routeBadge: nil,
                selfHealAttentionBadge: nil
            ),
            "Generate real-time launch step tracker"
        )
        XCTAssertEqual(
            AppDelegate.launchCountdownActionSubtitle(
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Generate real-time launch step tracker · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstActionSubtitle(modeMomentumStreak: 0),
            "Generate launch countdown + next-move handoff + recovery checklist"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstActionSubtitle(modeMomentumStreak: -2),
            "Generate launch countdown + next-move handoff + recovery checklist · Cooldown streak x2 · stage rescue now"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstActionSubtitle(
                modeMomentumStreak: -2,
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1"
            ),
            "Generate launch countdown + next-move handoff + recovery checklist · Cooldown streak x2 · stage rescue now · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .ready,
                modeMomentumStreak: -3
            ),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Cooldown streak x3 · rescue priority"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .ready,
                modeMomentumStreak: -3,
                lastAutoTriggerReason: "urgency-critical"
            ),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Last auto trigger: Urgency Critical escalation. · Trigger severity: Critical · Follow-up: Ship a recovery update now. · Cooldown streak x3 · rescue priority"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .ready,
                modeMomentumStreak: -3,
                lastAutoTriggerReason: "urgency-critical",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (12 * 60)),
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Last auto trigger: Urgency Critical escalation. · Trigger severity: Critical · Last auto trigger time: 12m ago. · Follow-up: Priority window active. Ship a recovery update now. · Cooldown streak x3 · rescue priority"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .ready,
                modeMomentumStreak: -3,
                lastAutoTriggerReason: "urgency-critical",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (12 * 60)),
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1",
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Last auto trigger: Urgency Critical escalation. · Trigger severity: Critical · Last auto trigger time: 12m ago. · Follow-up: Priority window active. Ship a recovery update now. · Cooldown streak x3 · rescue priority · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .ready,
                modeMomentumStreak: 0,
                lastAutoTriggerReason: "urgency-high",
                lastAutoTriggerAt: Date(timeIntervalSince1970: 1_000 - (12 * 60)),
                followupRouteDecisionTraceLine: "  Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack.  ",
                routeBadge: "Route Burst",
                selfHealAttentionBadge: "Self-Heal Missing x1",
                now: Date(timeIntervalSince1970: 1_000)
            ),
            "Launch rescue auto-burst is ready on launch escalation. Run once now. · Last auto trigger: Urgency High escalation. · Trigger severity: High · Last auto trigger time: 12m ago. · Follow-up: Priority window active. Run next move and ship the first block now. · Route decision: Escalated to Run Launch Rescue Burst from Run Fame Next Move + Copy Draft Pack. · Route Burst · Self-Heal Missing x1"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .coolingDown(minutesRemaining: 9),
                modeMomentumStreak: -2
            ),
            "Next auto rescue burst in about 9 min. Open latest or run now. · Cooldown streak x2 · stage rescue now"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSubtitle(
                .disabled,
                modeMomentumStreak: 0,
                lastAutoTriggerReason: "none"
            ),
            "Launch rescue auto-burst is off. Open Settings > Fame Ops."
        )
    }

    func testLaunchRescueAutoStatusActionSystemImageFormatsStates() {
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSystemImage(.disabled),
            "gearshape"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSystemImage(.ready),
            "bolt.shield"
        )
        XCTAssertEqual(
            AppDelegate.launchRescueBurstAutoStatusActionSystemImage(.coolingDown(minutesRemaining: 4)),
            "hourglass.circle"
        )
    }

    func testLaunchControlMenuSlotTokensExposeStableOrder() {
        XCTAssertEqual(
            AppDelegate.launchControlMenuSlotTokens(),
            [
                "launch-alert",
                "launch-health",
                "launch-recovery-next",
                "launch-rescue-auto-status",
                "launch-threshold-alerts",
                "launch-threshold-alerts-smart-snooze",
                "launch-threshold-alerts-snooze-reminder",
                "launch-threshold-alerts-snooze-10m",
                "launch-threshold-alerts-snooze-30m",
                "launch-threshold-alerts-snooze-60m",
                "separator",
                "run-launch-countdown",
                "run-launch-rescue-burst",
                "run-launch-rescue-followup-now",
                "run-launch-control-brief",
                "run-launch-rescue-snapshot",
                "run-launch-control-hub",
                "open-latest-launch-control-hub",
                "open-latest-launch-countdown",
                "open-latest-launch-rescue-burst",
                "open-latest-launch-rescue-snapshot",
                "open-latest-launch-control-brief",
                "copy-launch-control-brief",
                "copy-launch-rescue-snapshot"
            ]
        )
    }

    func testLaunchControlTapTelemetryDetailsCoverActionableRows() {
        XCTAssertEqual(
            AppDelegate.launchControlMenuTapTelemetryDetails(),
            [
                "launch-control-tap-launch-alert",
                "launch-control-tap-launch-health",
                "launch-control-tap-launch-recovery-next",
                "launch-control-tap-launch-rescue-auto-status",
                "launch-control-tap-threshold-alerts-toggle",
                "launch-control-tap-threshold-alerts-smart-snooze",
                "launch-control-tap-threshold-alerts-snooze-reminder",
                "launch-control-tap-threshold-alerts-snooze-10m",
                "launch-control-tap-threshold-alerts-snooze-30m",
                "launch-control-tap-threshold-alerts-snooze-60m",
                "launch-control-tap-run-launch-countdown",
                "launch-control-tap-run-launch-rescue-burst",
                "launch-control-tap-run-launch-rescue-followup-now",
                "launch-control-tap-run-launch-control-brief",
                "launch-control-tap-run-launch-rescue-snapshot",
                "launch-control-tap-run-launch-control-hub",
                "launch-control-tap-open-latest-launch-control-hub",
                "launch-control-tap-open-latest-launch-countdown",
                "launch-control-tap-open-latest-launch-rescue-burst",
                "launch-control-tap-open-latest-launch-rescue-snapshot",
                "launch-control-tap-open-latest-launch-control-brief",
                "launch-control-tap-copy-launch-control-brief",
                "launch-control-tap-copy-launch-rescue-snapshot"
            ]
        )
    }

    func testLaunchControlOnboardingRecoveryQuickRunMenuTitleReflectsState() {
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: true,
                actionID: "run-fame-onboarding-daily-brief",
                remainingArtifacts: 1
            ),
            "Launch Recovery Next: Run First-Week Daily Brief (1 artifact left)"
        )
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: true,
                actionID: "run-fame-onboarding-nudge",
                remainingArtifacts: 0
            ),
            "Launch Recovery Next: Run Fame Onboarding Nudge (Gap closed)"
        )
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: true,
                actionID: nil,
                remainingArtifacts: 2
            ),
            "Launch Recovery Next: Unavailable"
        )
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: false,
                actionID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1
            ),
            "Launch Recovery Next: Awaiting onboarding recovery pulse"
        )
    }

    func testLaunchRecoveryQuickRunCardSubtitleIncludesShortcutHint() {
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunCardSubtitle(
                actionID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 2
            ),
            "One-click launch recovery route · 2 artifacts left · Next Run First-Week Fame Scorecard · Shortcut: ⌥⇧L global (auto-reroute) · ⌥⌘R palette (fallback ⌘1)"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunCardSubtitle(
                actionID: "run-fame-onboarding-nudge",
                remainingArtifacts: 0
            ),
            "Onboarding gap closed · Keep momentum with Run Fame Onboarding Nudge · Shortcut: ⌥⇧L global (auto-reroute) · ⌥⌘R palette (fallback ⌘1)"
        )
    }

    func testLaunchRecoveryQuickRunShortcutHintIncludesGlobalPaletteAndFallbackRoutes() {
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunShortcutHint(),
            "Use global ⌥⇧L (auto-reroutes if needed), or press ⌥⌘R in Command Palette (fallback: ⌘1 from Top Picks)."
        )
    }

    func testLaunchControlOnboardingRecoveryQuickRunMenuToolTipReflectsState() {
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuToolTip(
                isFreshRecovery: false,
                actionID: "run-fame-onboarding-scorecard"
            ),
            "Waiting for a fresh onboarding recovery pulse. Use global ⌥⇧L (auto-reroutes if needed), or press ⌥⌘R in Command Palette (fallback: ⌘1 from Top Picks)."
        )
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuToolTip(
                isFreshRecovery: true,
                actionID: nil
            ),
            "Recovery pulse is active, but no eligible quick-run route is available yet. Use global ⌥⇧L (auto-reroutes if needed), or press ⌥⌘R in Command Palette (fallback: ⌘1 from Top Picks)."
        )
        XCTAssertEqual(
            AppDelegate.launchControlOnboardingRecoveryQuickRunMenuToolTip(
                isFreshRecovery: true,
                actionID: "run-fame-onboarding-daily-brief"
            ),
            "Runs Run First-Week Daily Brief from Launch Control. Use global ⌥⇧L (auto-reroutes if needed), or press ⌥⌘R in Command Palette (fallback: ⌘1 from Top Picks)."
        )
    }

    func testLaunchRecoveryQuickRunPulseMessageReflectsRemainingArtifacts() {
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunPulseMessage(
                actionID: "run-fame-onboarding-scorecard",
                remainingArtifacts: 1
            ),
            "Launch recovery route primed: Run First-Week Fame Scorecard (1 artifact left)."
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunPulseMessage(
                actionID: "run-fame-onboarding-nudge",
                remainingArtifacts: 0
            ),
            "Launch recovery route primed: Run Fame Onboarding Nudge (gap closed)."
        )
    }

    func testLaunchRecoveryGlobalHotKeyDisplayNameIsStable() {
        XCTAssertEqual(
            HotKeyManager.launchRecoveryHotKeyDisplayName,
            "Option + Shift + L"
        )
    }

    func testFameExceptionalLoopGlobalHotKeyMetadataIsStable() {
        XCTAssertEqual(
            HotKeyManager.fameExceptionalLoopHotKeyDisplayName,
            "Option + Shift + E"
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopHotKeyBusyActivityDetail(),
            "fame-exceptional-loop-hotkey-busy"
        )
        XCTAssertEqual(
            AppDelegate.fameExceptionalLoopGlobalHotKeyActivityDetail(),
            "run-fame-exceptional-loop-global-hotkey"
        )
    }

    func testLaunchRecoveryGlobalHotKeyFallbackActionIDUsesPriorityOrder() {
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryFallbackActionID(
                enabledActionIDs: [
                    "run-fame-onboarding-scorecard",
                    "run-fame-onboarding-daily-brief"
                ]
            ),
            "run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryFallbackActionID(
                enabledActionIDs: [
                    "run-fame-onboarding-fill-gap",
                    "run-fame-onboarding-scorecard"
                ]
            ),
            "run-fame-onboarding-fill-gap"
        )
        XCTAssertEqual(
            AppDelegate.fameOnboardingRecoveryFallbackActionID(
                enabledActionIDs: ["run-fame-cadence-autopilot-loop"]
            ),
            "run-fame-cadence-autopilot-loop"
        )
        XCTAssertNil(
            AppDelegate.fameOnboardingRecoveryFallbackActionID(enabledActionIDs: [])
        )
    }

    func testLaunchRecoveryGlobalHotKeyFallbackPulseCopyHighlightsAutoReroute() {
        XCTAssertEqual(
            AppDelegate.launchRecoveryGlobalHotKeyFallbackPulseTitle(),
            "Recovery Rerouted"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryGlobalHotKeyFallbackPulseMessage(
                actionID: "run-fame-onboarding-scorecard"
            ),
            "Launch recovery route was not active. Auto-rerouted to Run First-Week Fame Scorecard."
        )
    }

    func testLaunchRecoveryTelemetryDetailHelpersCoverGlobalHotKeyPath() {
        XCTAssertEqual(
            AppDelegate.launchRecoveryHotKeyBusyActivityDetail(),
            "launch-recovery-hotkey-busy"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryGlobalHotKeyUnavailableActivityDetail(),
            "run-fame-launch-recovery-next-global-hotkey-unavailable"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryGlobalHotKeyFallbackActivityDetail(
                actionID: "run-fame-onboarding-scorecard"
            ),
            "run-fame-launch-recovery-next-global-hotkey-fallback-run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryGlobalHotKeyFallbackPulseActivityDetail(
                actionID: "run-fame-onboarding-scorecard"
            ),
            "run-fame-launch-recovery-next-global-hotkey-fallback-pulse-run-fame-onboarding-scorecard"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunActivityDetail(
                source: "global-hotkey",
                actionID: "run-fame-onboarding-daily-brief"
            ),
            "run-fame-launch-recovery-next-global-hotkey-run-fame-onboarding-daily-brief"
        )
        XCTAssertEqual(
            AppDelegate.launchRecoveryQuickRunPulseActivityDetail(
                source: "global-hotkey",
                actionID: "run-fame-onboarding-daily-brief"
            ),
            "run-fame-launch-recovery-next-pulse-global-hotkey-run-fame-onboarding-daily-brief"
        )
    }

    func testBestChannelLaunchPackPressureActivityDetailTracksKindToneAndNormalization() {
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackPressureActivityDetail(
                CommandPaletteBestChannelLaunchPackPressureActivity(
                    kind: .opportunity,
                    tone: .alert,
                    opportunities: 7,
                    conversions: 3,
                    streak: 2,
                    bestStreak: 4
                )
            ),
            "fame-launch-pack-pressure-opportunity-alert-3-of-7-streak-2-best-4"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackPressureActivityDetail(
                CommandPaletteBestChannelLaunchPackPressureActivity(
                    kind: .conversion,
                    tone: .watch,
                    opportunities: 3,
                    conversions: 8,
                    streak: 9,
                    bestStreak: -1
                )
            ),
            "fame-launch-pack-pressure-conversion-watch-3-of-3-streak-3-best-3"
        )
        XCTAssertEqual(
            AppDelegate.bestChannelLaunchPackPressureActivityDetail(
                CommandPaletteBestChannelLaunchPackPressureActivity(
                    kind: .modeTransition,
                    tone: .alert,
                    opportunities: 9,
                    conversions: 4,
                    streak: 3,
                    bestStreak: 5,
                    previousTrend: .rebuilding,
                    trend: .compounding
                )
            ),
            "fame-launch-pack-pressure-mode-rebuilding-to-compounding-alert-4-of-9-streak-3-best-5"
        )
    }

    func testBestChannelLaunchPackPressureModeTransitionSummaryTracksCountAndLatest() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        XCTAssertNil(
            AppDelegate.incrementBestChannelLaunchPackPressureModeTransitionSummary(
                CommandPaletteBestChannelLaunchPackPressureActivity(
                    kind: .opportunity,
                    tone: .watch,
                    opportunities: 3,
                    conversions: 0,
                    streak: 0,
                    bestStreak: 0
                ),
                defaults: defaults
            )
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey
            ),
            0
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
            ),
            0
        )

        XCTAssertEqual(
            AppDelegate.incrementBestChannelLaunchPackPressureModeTransitionSummary(
                CommandPaletteBestChannelLaunchPackPressureActivity(
                    kind: .modeTransition,
                    tone: .watch,
                    opportunities: 3,
                    conversions: 1,
                    streak: 1,
                    bestStreak: 1,
                    previousTrend: .noWins,
                    trend: .compounding
                ),
                defaults: defaults
            )?.count,
            1
        )
        XCTAssertEqual(
            defaults.string(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey
            ),
            "no-wins-to-compounding"
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
            ),
            1
        )

        let secondSummary = AppDelegate.incrementBestChannelLaunchPackPressureModeTransitionSummary(
            CommandPaletteBestChannelLaunchPackPressureActivity(
                kind: .modeTransition,
                tone: .alert,
                opportunities: 5,
                conversions: 2,
                streak: 0,
                bestStreak: 2,
                previousTrend: .rebuilding,
                trend: .cooling
            ),
            defaults: defaults
        )
        XCTAssertEqual(secondSummary?.count, 2)
        XCTAssertEqual(secondSummary?.latest, "rebuilding-to-cooling")
        XCTAssertEqual(secondSummary?.momentumStreak, -1)
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey
            ),
            2
        )
        XCTAssertEqual(
            defaults.string(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey
            ),
            "rebuilding-to-cooling"
        )
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
            ),
            -1
        )

        let thirdSummary = AppDelegate.incrementBestChannelLaunchPackPressureModeTransitionSummary(
            CommandPaletteBestChannelLaunchPackPressureActivity(
                kind: .modeTransition,
                tone: .alert,
                opportunities: 8,
                conversions: 3,
                streak: 0,
                bestStreak: 3,
                previousTrend: .compounding,
                trend: .rebuilding
            ),
            defaults: defaults
        )
        XCTAssertEqual(thirdSummary?.count, 3)
        XCTAssertEqual(thirdSummary?.latest, "compounding-to-rebuilding")
        XCTAssertEqual(thirdSummary?.momentumStreak, -2)
        XCTAssertEqual(
            defaults.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
            ),
            -2
        )
    }

    func testLaunchControlBriefLaunchAlertUsesFallbackWhenCountdownMissing() {
        let launchAlert = AppDelegate.launchControlBriefLaunchAlert(nil)

        XCTAssertEqual(launchAlert.title, "Launch Alert: Run Fame Launch Countdown")
        XCTAssertEqual(
            launchAlert.subtitle,
            "Run `Run Fame Launch Day Script` first, then `Run Fame Launch Countdown`."
        )
    }

    func testLaunchControlBriefPriorityMoveTracksUrgencyBands() {
        XCTAssertEqual(
            AppDelegate.launchControlBriefPriorityMove(launchStatus: nil),
            "Run `Run Fame Launch Day Script`, then `Run Fame Launch Countdown`."
        )

        let criticalStatus = FameLaunchCountdownStatus(
            countdown: "T+31m",
            nextAction: "Ship incident update",
            launchRoute: "Recovery",
            pulseRisk: "Critical"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefPriorityMove(launchStatus: criticalStatus),
            "Run `Run Launch Rescue Burst` now, then ship `Next action now`."
        )

        let liveStatus = FameLaunchCountdownStatus(
            countdown: "T-2m",
            nextAction: "Publish launch thread",
            launchRoute: "Hot",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefPriorityMove(launchStatus: liveStatus),
            "Ship `Next action now`, then post latest next-move draft pack."
        )
    }

    func testLaunchControlBriefHealthScoreTracksReadyWatchRiskBands() {
        XCTAssertEqual(
            AppDelegate.launchControlBriefHealthScore(launchStatus: nil),
            "Watch"
        )

        let readyStatus = FameLaunchCountdownStatus(
            countdown: "T-8m",
            nextAction: "T-8m: Stage launch copy",
            launchRoute: "Distribution Remix",
            pulseRisk: "Low"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefHealthScore(launchStatus: readyStatus),
            "Ready"
        )

        let watchStatus = FameLaunchCountdownStatus(
            countdown: "T+3m",
            nextAction: "T+3m: Push top comment",
            launchRoute: "Reply Engine",
            pulseRisk: "Medium"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefHealthScore(launchStatus: watchStatus),
            "Watch"
        )

        let riskStatus = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Run rescue queue",
            launchRoute: "Recovery",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.launchControlBriefHealthScore(launchStatus: riskStatus),
            "Risk"
        )
    }

    func testLaunchControlHealthPulseStatusTitleCoversMutedOffReadyAndSuppressedStates() {
        let now = Date(timeIntervalSince1970: 40_000)

        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseStatusTitle(
                alertsEnabled: false,
                pulseEnabled: true,
                cooldownSeconds: 60,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Launch Health Pulse: Muted (launch threshold alerts off)"
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseStatusTitle(
                alertsEnabled: true,
                pulseEnabled: false,
                cooldownSeconds: 60,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Launch Health Pulse: Off"
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseStatusTitle(
                alertsEnabled: true,
                pulseEnabled: true,
                cooldownSeconds: 60,
                lastPulseAt: nil,
                lastPulseToken: nil,
                now: now
            ),
            "Launch Health Pulse: Ready (repeat cooldown 1m)."
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseStatusTitle(
                alertsEnabled: true,
                pulseEnabled: true,
                cooldownSeconds: 60,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Launch Health Pulse: Suppressed 40s for repeat Watch -> Risk."
        )

        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseStatusTitle(
                alertsEnabled: true,
                pulseEnabled: true,
                cooldownSeconds: 0,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Launch Health Pulse: On (cooldown off; every eligible transition)."
        )
    }

    func testLaunchControlHealthPulseMenuStatusTitleCoversMutedOffReadyAndSuppressedStates() {
        let now = Date(timeIntervalSince1970: 41_000)

        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseMenuStatusTitle(
                alertsEnabled: false,
                pulseEnabled: true,
                cooldownSeconds: 60,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Pulse muted"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseMenuStatusTitle(
                alertsEnabled: true,
                pulseEnabled: false,
                cooldownSeconds: 60,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Pulse off"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseMenuStatusTitle(
                alertsEnabled: true,
                pulseEnabled: true,
                cooldownSeconds: 60,
                lastPulseAt: nil,
                lastPulseToken: nil,
                now: now
            ),
            "Pulse ready (1m)"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseMenuStatusTitle(
                alertsEnabled: true,
                pulseEnabled: true,
                cooldownSeconds: 60,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Pulse suppressed 40s (Watch -> Risk)"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPulseMenuStatusTitle(
                alertsEnabled: true,
                pulseEnabled: true,
                cooldownSeconds: 0,
                lastPulseAt: now.addingTimeInterval(-20),
                lastPulseToken: "watch-to-risk",
                now: now
            ),
            "Pulse every transition"
        )
    }

    func testLaunchControlHealthTransitionCountsPersistAndResetByDay() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let dayOne = Date(timeIntervalSince1970: 86_400 * 3 + 1_000)
        let dayTwo = dayOne.addingTimeInterval(86_400)

        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCounts(
                now: dayOne,
                defaults: defaults
            ).watchToRiskCount,
            0
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCounts(
                now: dayOne,
                defaults: defaults
            ).riskToReadyCount,
            0
        )

        _ = AppDelegate.incrementLaunchControlHealthTransitionCounts(
            AppDelegate.LaunchControlHealthTransition(from: .watch, to: .risk),
            now: dayOne,
            defaults: defaults
        )
        _ = AppDelegate.incrementLaunchControlHealthTransitionCounts(
            AppDelegate.LaunchControlHealthTransition(from: .risk, to: .ready),
            now: dayOne,
            defaults: defaults
        )
        _ = AppDelegate.incrementLaunchControlHealthTransitionCounts(
            AppDelegate.LaunchControlHealthTransition(from: .watch, to: .risk),
            now: dayOne,
            defaults: defaults
        )

        let dayOneCounts = AppDelegate.launchControlHealthTransitionCounts(
            now: dayOne,
            defaults: defaults
        )
        XCTAssertEqual(dayOneCounts.watchToRiskCount, 2)
        XCTAssertEqual(dayOneCounts.riskToReadyCount, 1)

        let dayTwoCountsBeforeIncrement = AppDelegate.launchControlHealthTransitionCounts(
            now: dayTwo,
            defaults: defaults
        )
        XCTAssertEqual(dayTwoCountsBeforeIncrement.watchToRiskCount, 0)
        XCTAssertEqual(dayTwoCountsBeforeIncrement.riskToReadyCount, 0)

        let dayTwoIncremented = AppDelegate.incrementLaunchControlHealthTransitionCounts(
            AppDelegate.LaunchControlHealthTransition(from: .risk, to: .ready),
            now: dayTwo,
            defaults: defaults
        )
        XCTAssertEqual(dayTwoIncremented?.watchToRiskCount, 0)
        XCTAssertEqual(dayTwoIncremented?.riskToReadyCount, 1)

        let dayOneStamp = AppDelegate.launchControlHealthTransitionCountDayStamp(now: dayOne)
        let dayTwoStamp = AppDelegate.launchControlHealthTransitionCountDayStamp(now: dayTwo)
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionHistory(defaults: defaults),
            [
                AppDelegate.LaunchControlHealthTransitionHistoryDay(
                    dayStamp: dayOneStamp,
                    watchToRiskCount: 2,
                    riskToReadyCount: 1
                ),
                AppDelegate.LaunchControlHealthTransitionHistoryDay(
                    dayStamp: dayTwoStamp,
                    watchToRiskCount: 0,
                    riskToReadyCount: 1
                )
            ]
        )
    }

    func testLaunchControlHealthTransitionHistoryKeepsLatestSevenDays() throws {
        let suiteName = "FluidReaderTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let baseDay = Date(timeIntervalSince1970: 86_400 * 120)
        let transition = AppDelegate.LaunchControlHealthTransition(from: .watch, to: .risk)

        for dayOffset in 0..<8 {
            let now = baseDay.addingTimeInterval(TimeInterval(dayOffset * 86_400 + 120))
            _ = AppDelegate.incrementLaunchControlHealthTransitionCounts(
                transition,
                now: now,
                defaults: defaults,
                calendar: calendar
            )
        }

        let history = AppDelegate.launchControlHealthTransitionHistory(defaults: defaults)
        XCTAssertEqual(history.count, 7)
        XCTAssertEqual(history.map(\.watchToRiskCount), Array(repeating: 1, count: 7))
        XCTAssertEqual(history.map(\.riskToReadyCount), Array(repeating: 0, count: 7))

        let expectedStart = AppDelegate.launchControlHealthTransitionCountDayStamp(
            now: baseDay.addingTimeInterval(86_400),
            calendar: calendar
        )
        let expectedEnd = AppDelegate.launchControlHealthTransitionCountDayStamp(
            now: baseDay.addingTimeInterval(86_400 * 7),
            calendar: calendar
        )
        XCTAssertEqual(history.first?.dayStamp, expectedStart)
        XCTAssertEqual(history.last?.dayStamp, expectedEnd)
    }

    func testLaunchControlHealthTransitionCountTitlesFormatForBriefAndMenu() {
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 2
            ),
            "Launch Health Transitions Today: Watch -> Risk 3 · Risk -> Ready 2 · Trend Worsening ↓"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsMenuStatusTitle(
                watchToRiskCount: -1,
                riskToReadyCount: 2
            ),
            "Today W->R 0 · R->Ready 2 · Improving ↑"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionTrendTitle(
                watchToRiskCount: 2,
                riskToReadyCount: 2
            ),
            "Steady →"
        )

        let historyWindow = [
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-04",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-05",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-06",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-07",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-08",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-09",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-10",
                watchToRiskCount: 1,
                riskToReadyCount: 2
            )
        ]
        let averageDeltaTitle = AppDelegate.launchControlHealthTransitionAverageDeltaTitle(
            watchToRiskCount: 3,
            riskToReadyCount: 1,
            historyWindow: historyWindow
        )
        XCTAssertEqual(averageDeltaTitle, "Vs 7d avg W->R +2.0 · R->Ready -1.0")
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsMenuStatusTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                averageDeltaTitle: averageDeltaTitle
            ),
            "Today W->R 3 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -1.0"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                averageDeltaTitle: averageDeltaTitle
            ),
            "Launch Health Transitions Today: Watch -> Risk 3 · Risk -> Ready 1 · Trend Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -1.0"
        )

        let momentumStatusTitle = AppDelegate.launchControlHealthMomentumStatusTitle(
            .riskPressure
        )
        XCTAssertEqual(momentumStatusTitle, "Signal Pressure ↑")
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsMenuStatusTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                averageDeltaTitle: averageDeltaTitle,
                momentumStatusTitle: momentumStatusTitle
            ),
            "Today W->R 3 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -1.0 · Signal Pressure ↑"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                averageDeltaTitle: averageDeltaTitle,
                momentumStatusTitle: momentumStatusTitle
            ),
            "Launch Health Transitions Today: Watch -> Risk 3 · Risk -> Ready 1 · Trend Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -1.0 · Signal Pressure ↑"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsMenuStatusTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                averageDeltaTitle: averageDeltaTitle,
                momentumStatusTitle: momentumStatusTitle,
                pressurePersistenceStatusTitle: "Pressure streak 2d"
            ),
            "Today W->R 3 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -1.0 · Signal Pressure ↑ · Pressure streak 2d"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthTransitionCountsTitle(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                averageDeltaTitle: averageDeltaTitle,
                momentumStatusTitle: momentumStatusTitle,
                pressurePersistenceStatusTitle: "Pressure streak 2d"
            ),
            "Launch Health Transitions Today: Watch -> Risk 3 · Risk -> Ready 1 · Trend Worsening ↓ · Vs 7d avg W->R +2.0 · R->Ready -1.0 · Signal Pressure ↑ · Pressure streak 2d"
        )
    }

    func testLaunchControlHealthMomentumSignalDetectsPressureRecoveryAndBaseline() {
        let historyWindow = [
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-04",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-05",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-06",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-07",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-08",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-09",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-10",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            )
        ]

        XCTAssertEqual(
            AppDelegate.launchControlHealthMomentumSignal(
                watchToRiskCount: 3,
                riskToReadyCount: 1,
                historyWindow: historyWindow
            ),
            .riskPressure
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMomentumSignal(
                watchToRiskCount: 1,
                riskToReadyCount: 3,
                historyWindow: historyWindow
            ),
            .recoveryMomentum
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMomentumSignal(
                watchToRiskCount: 1,
                riskToReadyCount: 1,
                historyWindow: historyWindow
            ),
            .stable
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMomentumStatusTitle(.stable),
            "Signal Baseline →"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMomentumStatusTitle(.recoveryMomentum),
            "Signal Recovery ↑"
        )
    }

    func testLaunchControlHealthPressureStreakAndStatusTitleUseContiguousTailDays() {
        let historyWindow = [
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-04",
                watchToRiskCount: 0,
                riskToReadyCount: 0
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-05",
                watchToRiskCount: 1,
                riskToReadyCount: 0
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-06",
                watchToRiskCount: 2,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-07",
                watchToRiskCount: 3,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-08",
                watchToRiskCount: 1,
                riskToReadyCount: 1
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-09",
                watchToRiskCount: 2,
                riskToReadyCount: 0
            ),
            AppDelegate.LaunchControlHealthTransitionHistoryDay(
                dayStamp: "2026-06-10",
                watchToRiskCount: 2,
                riskToReadyCount: 1
            )
        ]

        XCTAssertEqual(
            AppDelegate.launchControlHealthPressureStreakDays(historyWindow: historyWindow),
            2
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPressurePersistenceStatusTitle(streakDays: 0),
            nil
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPressurePersistenceStatusTitle(streakDays: 1),
            nil
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthPressurePersistenceStatusTitle(streakDays: 2),
            "Pressure streak 2d"
        )
    }

    func testLaunchControlHealthMenuTitleCanIncludeStatusSummary() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+8m",
            nextAction: "T+8m: Push replies",
            launchRoute: "Recovery",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.launchControlHealthMenuTitle(
                launchStatus: status,
                statusTitle: "Pulse suppressed 42s (Watch -> Risk) · Today W->R 4 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +1.5 · R->Ready -0.2"
            ),
            "Launch Health: Watch · T+8m · Pulse suppressed 42s (Watch -> Risk) · Today W->R 4 · R->Ready 1 · Worsening ↓ · Vs 7d avg W->R +1.5 · R->Ready -0.2 · Click: Run Fame Launch Countdown"
        )
    }

    func testFameLaunchHealthMenuTitleCanAppendRecoveryMomentumHint() {
        let status = FameLaunchCountdownStatus(
            countdown: "T+8m",
            nextAction: "T+8m: Push replies",
            launchRoute: "Recovery",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.fameLaunchHealthMenuTitle(
                launchStatus: status,
                statusTitle: "Pulse suppressed 42s (Watch -> Risk)",
                commandID: "run-fame-launch-countdown",
                onboardingRecoveryHint: "Onboarding recovery: 2 artifacts left"
            ),
            "Launch Health: Watch · T+8m · Pulse suppressed 42s (Watch -> Risk) · Click: Run Fame Launch Countdown · Onboarding recovery: 2 artifacts left"
        )
    }

    func testLaunchControlBriefMarkdownIncludesCoreSections() {
        let markdown = AppDelegate.launchControlBriefMarkdown(
            generatedAt: "2026-06-10 08:30",
            launchAlertTitle: "Launch Countdown: T+18m",
            launchAlertSubtitle: "Urgency High (overdue by 18m) · Next: Ship update",
            rescueAutoStatusTitle: "Launch Rescue Auto: Cooldown 12m",
            rescueAutoTriggerStatusTitle: "Launch Rescue Auto Trigger: Urgency High escalation.",
            rescueAutoTriggerAtStatusTitle: "Launch Rescue Auto Trigger Time: 12m ago.",
            rescueAutoFollowupStatusTitle: "Launch Rescue Auto Follow-up: Priority window active. Run next move and ship the first block now.",
            rescueAutoSelfHealStatusTitle: "Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Launch Rescue Burst · Reason: Urgency High escalation. · Freshness 8m ago.",
            rescueAutoFollowupScoreboardStatusTitle: "Launch Rescue Follow-up Scoreboard: 24h 2/3 success (67%) · Rolling 5/7 success (71%) · Freshness 12m ago.",
            rescueAutoFollowupCoachStatusTitle: "Launch Rescue Follow-up Coach: Winning lane · keep Run Fame Next Move + Copy Draft Pack cadence · Freshness 12m ago.",
            rescueAutoFollowupMomentumStatusTitle: "Launch Rescue Follow-up Momentum: Recovery x2 · CD 25/30m · Steady →",
            thresholdAlertsStatusTitle: "Launch Threshold Alerts: Snoozed 12m",
            healthPulseStatusTitle: "Launch Health Pulse: Suppressed 32s for repeat Watch -> Risk.",
            healthTransitionCountsTitle: "Launch Health Transitions Today: Watch -> Risk 2 · Risk -> Ready 1 · Trend Worsening ↓ · Vs 7d avg W->R +0.9 · R->Ready -0.4",
            snoozeReminderStatusTitle: "Launch Snooze Reminder: Armed · Click: Unmute now",
            nextMoveLabel: "Recovery Sprint",
            cadenceStreakStatusTitle: "Cadence kit streak: x3 (best x8).",
            healthScore: "Risk",
            priorityMove: "Run `Run Launch Rescue Burst` now, then ship `Next action now`."
        )

        XCTAssertTrue(markdown.contains("# Fluid Reader Launch Control Brief"))
        XCTAssertTrue(markdown.contains("- Next move recommendation: Recovery Sprint"))
        XCTAssertTrue(markdown.contains("- Launch control health score: Risk"))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto: Cooldown 12m"))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Trigger: Urgency High escalation."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Trigger Time: 12m ago."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Follow-up: Priority window active. Run next move and ship the first block now."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Auto Self-Heal: Recovered missing artifacts · Route: Run Launch Rescue Burst · Reason: Urgency High escalation. · Freshness 8m ago."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Scoreboard: 24h 2/3 success (67%) · Rolling 5/7 success (71%) · Freshness 12m ago."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Coach: Winning lane · keep Run Fame Next Move + Copy Draft Pack cadence · Freshness 12m ago."))
        XCTAssertTrue(markdown.contains("- Launch Rescue Follow-up Momentum: Recovery x2 · CD 25/30m · Steady →"))
        XCTAssertTrue(markdown.contains("- Launch Health Pulse: Suppressed 32s for repeat Watch -> Risk."))
        XCTAssertTrue(markdown.contains("- Launch Health Transitions Today: Watch -> Risk 2 · Risk -> Ready 1 · Trend Worsening ↓ · Vs 7d avg W->R +0.9 · R->Ready -0.4"))
        XCTAssertTrue(markdown.contains("- Cadence kit streak: x3 (best x8)."))
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("- `Run Launch Rescue Burst`"))
        XCTAssertTrue(markdown.contains("- `Run Launch Rescue Follow-up Now`"))
        XCTAssertTrue(markdown.contains("- `Run Launch Rescue Snapshot`"))
        XCTAssertTrue(markdown.contains("- `Run Launch Control Hub`"))
        XCTAssertTrue(markdown.contains("- `Copy Launch Rescue Snapshot`"))
        XCTAssertTrue(markdown.contains("- `Open Launch Control Hub`"))
        XCTAssertTrue(markdown.contains("- `Open Latest Launch Rescue Snapshot`"))
        XCTAssertTrue(markdown.contains("- `Run Fame Launch Control Brief`"))
        XCTAssertTrue(markdown.contains("- `Open Latest Launch Control Brief`"))
    }

    func testCadenceExecutionKitMomentumBriefStatusHelpersFormatKnownAndFallbackStates() {
        let signal = FamePulseAlertSignal(
            riskLevel: "High",
            mustShipAlert: "MUST SHIP in next 2h",
            streakDays: 2,
            daysSinceLastSnapshot: 1,
            leadExperiment: "Reply Engine"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumPulseStatusTitle(signal: signal),
            "Pulse risk: High · MUST SHIP in next 2h · Snapshot gap 1d"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumPulseStatusTitle(signal: nil),
            "Pulse risk: Unknown · Run `Run Daily Fame Scorecard`."
        )

        let launchStatus = FameLaunchCountdownStatus(
            countdown: "T+18m",
            nextAction: "T+18m: Ship launch update",
            launchRoute: "Recovery",
            pulseRisk: "High"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumLaunchStatusTitle(launchStatus),
            "Launch status: T+18m · Urgency High (overdue by 18m) · Next T+18m: Ship launch update"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumLaunchStatusTitle(nil),
            "Launch status: Unknown · Run `Run Fame Launch Day Script`, then `Run Fame Launch Countdown`."
        )

        let scorecard = FameDailyScorecardState(
            riskLevel: "Medium",
            scoreDelta: -2,
            title: "Daily Scorecard: Medium",
            detail: "Risk is elevated.",
            recommendation: "Run Daily Fame Checkpoint",
            nextActionTitle: "Run Daily Fame Checkpoint",
            nextActionSummary: "Stabilize with KPI check.",
            recommendsRecovery: false
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumScorecardStatusTitle(scorecard),
            "Daily scorecard: Medium (Δ-2) · Next Run Daily Fame Checkpoint"
        )
        XCTAssertEqual(
            AppDelegate.cadenceExecutionKitMomentumScorecardStatusTitle(.unknown),
            "Daily scorecard: Unknown · Run `Run Daily Fame Scorecard`."
        )
    }

    func testCadenceExecutionKitMomentumBriefMarkdownIncludesCoreSections() {
        let markdown = AppDelegate.cadenceExecutionKitMomentumBriefMarkdown(
            generatedAt: "2026-06-10 09:14",
            momentumTitle: "Cadence Momentum: x4 · Best x8 · Next x5 (1 run)",
            streakStatusTitle: "Cadence kit streak: x4 (best x8).",
            nextMoveLabel: "Recovery Sprint",
            pulseStatusTitle: "Pulse risk: High · MUST SHIP in next 2h · Snapshot gap 1d",
            launchStatusTitle: "Launch status: T+18m · Urgency High (overdue by 18m) · Next T+18m: Ship launch update",
            scorecardStatusTitle: "Daily scorecard: Medium (Δ-2) · Next Run Daily Fame Checkpoint",
            priorityMove: "Build streak x4 toward x5. Run `Run Fame Next Move + Cadence Execution Kit` now (Recovery Sprint).",
            recoveryWinsTitle: "Recovery Wins 6/8 · x3",
            recoveryWinsSubtitle: "Direct route is winning 6/8 opens. Keep streak pressure high.",
            momentumDeltaTitle: "Fame Momentum Delta +2 wins",
            momentumDeltaSubtitle: "Direct wins climbed to 6/8 from 4/8. Keep compounding.",
            shareLine: "Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint."
        )

        XCTAssertTrue(markdown.contains("# Fluid Reader Cadence Momentum Brief"))
        XCTAssertTrue(markdown.contains("- Cadence momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run)"))
        XCTAssertTrue(markdown.contains("- Next move recommendation: Recovery Sprint"))
        XCTAssertTrue(markdown.contains("- Cadence kit streak: x4 (best x8)."))
        XCTAssertTrue(markdown.contains("- Pulse risk: High · MUST SHIP in next 2h · Snapshot gap 1d"))
        XCTAssertTrue(markdown.contains("- Daily scorecard: Medium (Δ-2) · Next Run Daily Fame Checkpoint"))
        XCTAssertTrue(markdown.contains("## Recovery Wins"))
        XCTAssertTrue(markdown.contains("- Recovery Wins 6/8 · x3"))
        XCTAssertTrue(markdown.contains("- Direct route is winning 6/8 opens. Keep streak pressure high."))
        XCTAssertTrue(markdown.contains("## Fame Momentum Delta"))
        XCTAssertTrue(markdown.contains("- Fame Momentum Delta +2 wins"))
        XCTAssertTrue(markdown.contains("- Direct wins climbed to 6/8 from 4/8. Keep compounding."))
        XCTAssertTrue(markdown.contains("## Share Line"))
        XCTAssertTrue(markdown.contains("- Fame momentum: Cadence Momentum: x4 · Best x8 · Next x5 (1 run) · Recovery Wins 6/8 · x3 · Fame Momentum Delta +2 wins · Next Recovery Sprint."))
        XCTAssertTrue(markdown.contains("- Paste this into launch updates, standups, and social proof checkpoints."))
        XCTAssertTrue(markdown.contains("- Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."))
        XCTAssertTrue(markdown.contains("- `Run Cadence Autopilot Loop`"))
        XCTAssertTrue(markdown.contains("- `Copy Cadence Share Pack`"))
        XCTAssertTrue(markdown.contains("- `Run Cadence Momentum Brief`"))
        XCTAssertTrue(markdown.contains("- `Open Latest Cadence Momentum Brief`"))
        XCTAssertTrue(markdown.contains("- `Open Latest Cadence Share Line`"))
        XCTAssertTrue(markdown.contains("- `Open Latest Cadence Share Pack`"))
    }

    func testLaunchRecoveryHotKeyWinMeterSnapshotReadsDefaultsHistory() throws {
        let suiteName = "AppDelegateLaunchWinMeterTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(
            ["standby", "direct", "direct", "reroute", "direct", "direct", "direct", "standby"],
            forKey: AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey
        )
        defaults.set(5, forKey: AppDefaults.fameLaunchRecoveryHotKeyDirectStreakKey)
        defaults.set(7, forKey: AppDefaults.fameLaunchRecoveryHotKeyBestDirectStreakKey)

        XCTAssertEqual(
            AppDelegate.launchRecoveryHotKeyWinMeterSnapshot(
                defaults: defaults,
                sampleLimit: 8
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter(
                tone: .steady,
                wins: 5,
                sampleCount: 8,
                multiplier: 3,
                title: "Recovery Wins 5/8 · x3",
                subtitle: "Recovery is stabilizing at 5/8 direct wins. Stack the next win.",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Launch recovery win meter tracks direct-route wins over the last 8 opens: 5 direct wins, current streak x5, best x7, multiplier x3."
            )
        )
    }

    func testLaunchRecoveryHotKeyMomentumDeltaSnapshotReadsDefaultsHistory() throws {
        let suiteName = "AppDelegateLaunchMomentumDeltaTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(
            [
                "standby", "reroute", "direct", "standby",
                "direct", "direct", "reroute", "direct"
            ],
            forKey: AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey
        )

        XCTAssertEqual(
            AppDelegate.launchRecoveryHotKeyMomentumDeltaSnapshot(
                defaults: defaults,
                sampleWindow: 4
            ),
            CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta(
                tone: .climbing,
                currentWins: 3,
                previousWins: 1,
                sampleCount: 4,
                deltaWins: 2,
                title: "Fame Momentum Delta +2 wins",
                subtitle: "Direct wins climbed to 3/4 from 1/4. Keep compounding.",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Fame momentum delta compares direct wins across two 4-open windows: current 3, previous 1, Δ+2."
            )
        )
    }

    private func restoreDefaultsObject(_ object: Any?, forKey key: String) {
        let defaults = UserDefaults.standard
        if let object {
            defaults.set(object, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    private func captureFameSnapshotArchiveBaseline() -> (directoryURL: URL, fileNames: Set<String>)? {
        guard let directoryURL = try? FameSnapshotArchive.defaultDirectoryURL() else {
            return nil
        }
        let fileNames = Set(
            (try? FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            ).map(\.lastPathComponent)) ?? []
        )
        return (directoryURL: directoryURL, fileNames: fileNames)
    }

    private func removeNewFameSnapshotArchiveArtifacts(
        directoryURL: URL,
        baselineFileNames: Set<String>
    ) {
        guard let currentURLs = try? FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        for url in currentURLs where !baselineFileNames.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func dayStamp(daysFromNow offset: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
