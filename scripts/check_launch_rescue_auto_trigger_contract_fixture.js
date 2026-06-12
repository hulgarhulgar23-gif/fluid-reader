#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const appDefaultsPath = path.resolve(__dirname, '../Sources/FluidReader/AppDefaults.swift');
const appDelegatePath = path.resolve(__dirname, '../Sources/FluidReader/AppDelegate.swift');
const fameSnapshotArchivePath = path.resolve(__dirname, '../Sources/FluidReader/FameSnapshotArchive.swift');
const supportInfoPath = path.resolve(__dirname, '../Sources/FluidReader/SupportInfoReport.swift');
const issueSupportBundlePath = path.resolve(__dirname, '../Sources/FluidReader/IssueSupportBundle.swift');
const bugReportDraftPath = path.resolve(__dirname, '../Sources/FluidReader/BugReportDraft.swift');
const launchTestsPath = path.resolve(__dirname, '../Tests/FluidReaderTests/AppDelegateLaunchTests.swift');
const archiveTestsPath = path.resolve(__dirname, '../Tests/FluidReaderTests/FameSnapshotArchiveTests.swift');
const supportTestsPath = path.resolve(__dirname, '../Tests/FluidReaderTests/SupportInfoReportTests.swift');
const issueSupportTestsPath = path.resolve(__dirname, '../Tests/FluidReaderTests/IssueSupportBundleTests.swift');
const bugReportTestsPath = path.resolve(__dirname, '../Tests/FluidReaderTests/BugReportDraftTests.swift');

function assertCondition(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function runFixtureSuite() {
  const appDefaults = fs.readFileSync(appDefaultsPath, 'utf8');
  const appDelegate = fs.readFileSync(appDelegatePath, 'utf8');
  const fameSnapshotArchive = fs.readFileSync(fameSnapshotArchivePath, 'utf8');
  const supportInfo = fs.readFileSync(supportInfoPath, 'utf8');
  const issueSupportBundle = fs.readFileSync(issueSupportBundlePath, 'utf8');
  const bugReportDraft = fs.readFileSync(bugReportDraftPath, 'utf8');
  const launchTests = fs.readFileSync(launchTestsPath, 'utf8');
  const archiveTests = fs.readFileSync(archiveTestsPath, 'utf8');
  const supportTests = fs.readFileSync(supportTestsPath, 'utf8');
  const issueSupportTests = fs.readFileSync(issueSupportTestsPath, 'utf8');
  const bugReportTests = fs.readFileSync(bugReportTestsPath, 'utf8');

  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerActivityDetail('),
    'Expected launch rescue auto trigger activity-detail formatter helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerReasonTokenFromActivityDetail('),
    'Expected launch rescue auto trigger activity-detail parser helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerReasonToken(_ value: String?) -> String {'),
    'Expected launch rescue auto trigger shared reason-token normalization helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerAt(_ value: Any?) -> Date? {'),
    'Expected launch rescue auto trigger timestamp normalization helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerAtStatusTitle('),
    'Expected launch rescue auto trigger timestamp status-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupSummary('),
    'Expected launch rescue auto trigger follow-up summary helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupStatusTitle('),
    'Expected launch rescue auto trigger follow-up status-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupStatusSubtitleHint('),
    'Expected launch rescue auto trigger follow-up subtitle helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupMenuBadge('),
    'Expected launch rescue auto trigger follow-up menu-badge helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupOutcomeScoreboardStatusTitle('),
    'Expected launch rescue follow-up scoreboard status-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupOutcomeCoachSummary('),
    'Expected launch rescue follow-up coach summary helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupOutcomeCoachStatusTitle('),
    'Expected launch rescue follow-up coach status-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupCoachRecoveryLaneStreakNext('),
    'Expected launch rescue follow-up coach recovery-lane streak helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func shouldAutoRunLaunchRescueFollowupRecoveryChecklist('),
    'Expected launch rescue follow-up auto-checklist escalation helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining('),
    'Expected launch rescue follow-up auto-checklist cooldown helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupRecoveryChecklistCooldownMinutesNext('),
    'Expected launch rescue follow-up auto-checklist adaptive cooldown helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueFollowupOutcomeScoreboard('),
    'Expected launch rescue follow-up scoreboard snapshot helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerSeverityBadge(_ token: String?) -> String? {'),
    'Expected launch rescue auto-trigger severity-badge helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerSeveritySubtitleHint(_ token: String?) -> String? {'),
    'Expected launch rescue auto-trigger severity subtitle helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupCommandID(_ commandID: String?) -> String {'),
    'Expected launch rescue auto follow-up command-id normalization helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupRunSummary('),
    'Expected launch rescue auto follow-up run-summary helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupAutoActivityDetail('),
    'Expected launch rescue auto follow-up auto activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupAutoPressureActivityDetail('),
    'Expected launch rescue auto follow-up pressure auto-run activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupArtifactsReady('),
    'Expected launch rescue auto follow-up route artifact-ready helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupArtifactsMissing('),
    'Expected launch rescue auto follow-up route artifact-missing helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealActivityDetail('),
    'Expected launch rescue auto follow-up self-heal activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealOutcome('),
    'Expected launch rescue auto follow-up self-heal outcome normalization helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealSnapshot('),
    'Expected launch rescue auto follow-up self-heal snapshot parser helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealSnapshotIsRecent('),
    'Expected launch rescue auto follow-up self-heal recency helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealBadge('),
    'Expected launch rescue auto follow-up self-heal badge helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealStatusTitle('),
    'Expected launch rescue auto follow-up self-heal status-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupSelfHealArtifactStatusTitle('),
    'Expected launch rescue auto follow-up shared artifact status helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionIssueToken('),
    'Expected launch rescue auto self-heal attention issue-token helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionNudgeMessage('),
    'Expected launch rescue auto self-heal attention nudge-message helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionIssueStreakNext('),
    'Expected launch rescue auto self-heal attention issue-streak helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge('),
    'Expected launch rescue auto self-heal attention nudge-gating helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionActivityDetail('),
    'Expected launch rescue auto self-heal attention activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionActionTitle('),
    'Expected launch rescue auto self-heal attention action-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionActionSubtitle('),
    'Expected launch rescue auto self-heal attention action-subtitle helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionActionSystemImage('),
    'Expected launch rescue auto self-heal attention action-system-image helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoSelfHealAttentionActionActivityDetail('),
    'Expected launch rescue auto self-heal attention action activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('struct FameExceptionalLoopPlan: Equatable {'),
    'Expected fame exceptional loop plan helper contract.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func fameExceptionalLoopPlan('),
    'Expected fame exceptional loop plan builder helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func fameExceptionalLoopActionTitle(_ plan: FameExceptionalLoopPlan) -> String {'),
    'Expected fame exceptional loop action-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func fameExceptionalLoopActionSubtitle(_ plan: FameExceptionalLoopPlan) -> String {'),
    'Expected fame exceptional loop action-subtitle helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func fameExceptionalLoopActionSystemImage(_ plan: FameExceptionalLoopPlan) -> String {'),
    'Expected fame exceptional loop action-system-image helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func fameExceptionalLoopActivityDetail(_ plan: FameExceptionalLoopPlan) -> String {'),
    'Expected fame exceptional loop activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('private func fameExceptionalLoopAction(now: Date = Date()) -> CommandPaletteAction? {'),
    'Expected command-palette builder for fame exceptional loop.'
  );
  assertCondition(
    appDelegate.includes('private func runFameExceptionalLoop(now: Date = Date()) {'),
    'Expected runner for fame exceptional loop.'
  );
  assertCondition(
    appDelegate.includes('private func fameLaunchRescueAutoSelfHealAttentionAction('),
    'Expected launch rescue auto self-heal attention command-palette action builder.'
  );
  assertCondition(
    appDelegate.includes('private func launchRescueAutoFollowupSelfHealArtifactStatusTitle('),
    'Expected launch rescue auto follow-up self-heal artifact status helper for artifact outputs.'
  );
  assertCondition(
    appDelegate.includes('private func launchRescueAutoFollowupSelfHealSnapshotForTriggerReason('),
    'Expected launch rescue auto follow-up self-heal trigger-matching snapshot helper.'
  );
  assertCondition(
    appDelegate.includes('autoSelfHealStatusTitle: String,'),
    'Expected launch rescue snapshot markdown helper to accept self-heal status lines.'
  );
  assertCondition(
    appDelegate.includes('rescueAutoSelfHealStatusTitle: String = "Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks.",'),
    'Expected launch control brief markdown helper to accept self-heal status lines.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoFollowupArtifactIsFresh('),
    'Expected launch rescue auto follow-up artifact freshness helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupCommandID(_ token: String?) -> String {'),
    'Expected launch rescue auto follow-up route helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupActionTitle(_ token: String?) -> String {'),
    'Expected launch rescue auto follow-up action-title helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerFollowupActionSubtitle('),
    'Expected launch rescue auto follow-up action-subtitle helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueBurstAutoStatusMenuToolTip('),
    'Expected launch rescue auto status menu tooltip helper.'
  );
  assertCondition(
    appDelegate.includes('selfHealBadge: String? = nil'),
    'Expected launch rescue auto status menu title helper to accept self-heal badge context.'
  );
  assertCondition(
    appDelegate.includes('selfHealStatusTitle: String? = nil'),
    'Expected launch rescue auto tooltip helpers to accept self-heal status context.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueAutoTriggerAtDiagnosticSummary('),
    'Expected launch rescue auto trigger timestamp diagnostic-summary helper.'
  );
  assertCondition(
    appDelegate.includes('let baseDetail = "run-fame-launch-rescue-burst-auto-trigger-\\(reason.rawValue)"'),
    'Expected canonical launch rescue auto-trigger activity-detail base string.'
  );
  assertCondition(
    appDelegate.includes('return "\\(baseDetail)-\\(pressureStreakDays)"'),
    'Expected pressure-persistence suffix wiring in activity-detail formatter.'
  );
  assertCondition(
    appDelegate.includes('let prefix = "run-fame-launch-rescue-burst-auto-trigger-"'),
    'Expected parser prefix wiring for launch rescue auto-trigger details.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchControlHubAutoEscalationActivityDetail('),
    'Expected launch control hub auto-escalation activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchControlHubAutoSkipActivityDetail('),
    'Expected launch control hub auto-skip activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('if runFameLaunchControlHub(\n            source: "auto-\\(urgencyToken)",\n            announce: false,'),
    'Expected urgency/momentum auto-trigger path to orchestrate through launch control hub in non-intrusive mode.'
  );
  assertCondition(
    appDelegate.includes('detail: Self.launchControlHubAutoEscalationActivityDetail(urgencyToken: urgencyToken)'),
    'Expected urgency/momentum auto-trigger path to emit launch control hub auto-run telemetry helper.'
  );
  assertCondition(
    appDelegate.includes('detail: Self.launchControlHubAutoSkipActivityDetail('),
    'Expected urgency/momentum auto-trigger cooldown path to emit launch control hub auto-skip telemetry helper.'
  );
  assertCondition(
    appDelegate.includes('detail: Self.launchRescueAutoTriggerActivityDetail(reason: triggerReason)'),
    'Expected urgency/momentum auto-trigger emit path to use formatter helper.'
  );
  assertCondition(
    appDelegate.includes('_ = runFameLaunchRescueFollowupNowAuto(\n                triggerReason: triggerReason,\n                now: now,\n                defaults: defaults\n            )'),
    'Expected urgency/momentum auto-trigger path to run launch rescue follow-up auto helper.'
  );
  assertCondition(
    appDelegate.includes('detail: Self.launchRescueAutoTriggerActivityDetail(\n                reason: .pressurePersistence,'),
    'Expected pressure-persistence auto-trigger emit path to use formatter helper.'
  );
  assertCondition(
    appDelegate.includes('_ = runFameLaunchRescueFollowupNowAutoPressurePersistence(\n            now: now,\n            defaults: defaults\n        )'),
    'Expected pressure-persistence auto-trigger path to run launch rescue follow-up auto helper.'
  );
  assertCondition(
    appDelegate.includes('guard runFameLaunchControlHub(\n            source: autoSource,\n            announce: false,'),
    'Expected pressure-persistence auto-run path to trigger launch control hub in non-intrusive mode.'
  );
  assertCondition(
    appDelegate.includes('detail: "run-fame-launch-control-hub-auto-pressure-streak-\\(healthInsights.pressureStreakDays)"'),
    'Expected pressure-persistence auto-run telemetry detail to reflect launch control hub orchestration.'
  );
  assertCondition(
    appDelegate.includes('setFameLaunchRescueBurstLastAutoTriggerAt(now, defaults: defaults)'),
    'Expected auto-trigger flows to persist last auto trigger timestamp.'
  );
  assertCondition(
    appDelegate.includes('setFameLaunchRescueBurstLastAutoTriggerAt(nil)'),
    'Expected announced manual rescue runs to clear stale auto trigger timestamp.'
  );
  assertCondition(
    appDelegate.includes('rescueAutoFollowupStatusTitle: Self.launchRescueAutoTriggerFollowupStatusTitle('),
    'Expected launch control brief to surface launch rescue auto-trigger follow-up guidance.'
  );
  assertCondition(
    appDelegate.includes('rescueAutoFollowupScoreboardStatusTitle: Self.launchRescueFollowupOutcomeScoreboardStatusTitle('),
    'Expected launch control brief to surface launch rescue follow-up scoreboard guidance.'
  );
  assertCondition(
    appDelegate.includes('rescueAutoSelfHealStatusTitle: launchRescueAutoSelfHealStatusTitle,'),
    'Expected launch control brief builder to wire launch rescue self-heal artifact status guidance.'
  );
  assertCondition(
    appDelegate.includes('autoSelfHealStatusTitle: launchRescueAutoSelfHealStatusTitle,'),
    'Expected launch rescue snapshot builder to wire launch rescue self-heal artifact status guidance.'
  );
  assertCondition(
    appDelegate.includes('rescueAutoFollowupCoachStatusTitle: launchRescueFollowupOutcomeCoachStatusTitle'),
    'Expected launch control brief to surface launch rescue follow-up coach guidance.'
  );
  assertCondition(
    appDelegate.includes('followupBadge: Self.launchRescueAutoTriggerFollowupMenuBadge('),
    'Expected launch rescue auto menu status title to surface follow-up badge guidance.'
  );
  assertCondition(
    appDelegate.includes('selfHealBadge: Self.launchRescueAutoFollowupSelfHealBadge('),
    'Expected launch rescue auto menu status title to surface self-heal badge guidance.'
  );
  assertCondition(
    appDelegate.includes('selfHealStatusTitle: Self.launchRescueAutoFollowupSelfHealStatusTitle('),
    'Expected launch rescue auto menu tooltips to surface self-heal status guidance.'
  );
  assertCondition(
    appDelegate.includes('func launchRescueAutoMenuStatusTitleForTesting('),
    'Expected launch rescue auto menu status title testing accessor.'
  );
  assertCondition(
    appDelegate.includes('func launchRescueAutoMenuStatusToolTipForTesting('),
    'Expected launch rescue auto menu status tooltip testing accessor.'
  );
  assertCondition(
    appDelegate.includes('func launchRescueFollowupNowMenuStatusTitleForTesting('),
    'Expected launch rescue follow-up now menu status title testing accessor.'
  );
  assertCondition(
    appDelegate.includes('func launchRescueFollowupNowMenuStatusToolTipForTesting('),
    'Expected launch rescue follow-up now menu status tooltip testing accessor.'
  );
  assertCondition(
    appDelegate.includes('private var fameLaunchRescueFollowupNowMenuItem: NSMenuItem?'),
    'Expected launch rescue follow-up now launch-control menu item reference.'
  );
  assertCondition(
    appDelegate.includes('private var fameLaunchRescueSnapshotMenuItem: NSMenuItem?'),
    'Expected launch rescue snapshot launch-control menu item reference.'
  );
  assertCondition(
    appDelegate.includes('case runLaunchRescueFollowupNow = 1019'),
    'Expected launch control slot entry for launch rescue follow-up now.'
  );
  assertCondition(
    appDelegate.includes('case copyLaunchRescueSnapshot = 1020'),
    'Expected launch control slot entry for launch rescue snapshot copy.'
  );
  assertCondition(
    appDelegate.includes('case openLatestLaunchRescueSnapshot = 1021'),
    'Expected launch control slot entry for latest launch rescue snapshot open action.'
  );
  assertCondition(
    appDelegate.includes('case runLaunchRescueSnapshot = 1022'),
    'Expected launch control slot entry for launch rescue snapshot run action.'
  );
  assertCondition(
    appDelegate.includes('case openLatestLaunchControlHub = 1023'),
    'Expected launch control slot entry for launch control hub open action.'
  );
  assertCondition(
    appDelegate.includes('case runLaunchControlHub = 1024'),
    'Expected launch control slot entry for launch control hub run action.'
  );
  assertCondition(
    appDelegate.includes('case .runLaunchRescueFollowupNow:\n            return "run-launch-rescue-followup-now"'),
    'Expected launch control token mapping for launch rescue follow-up now.'
  );
  assertCondition(
    appDelegate.includes('case .copyLaunchRescueSnapshot:\n            return "copy-launch-rescue-snapshot"'),
    'Expected launch control token mapping for launch rescue snapshot copy.'
  );
  assertCondition(
    appDelegate.includes('case .openLatestLaunchRescueSnapshot:\n            return "open-latest-launch-rescue-snapshot"'),
    'Expected launch control token mapping for latest launch rescue snapshot open action.'
  );
  assertCondition(
    appDelegate.includes('case .runLaunchRescueSnapshot:\n            return "run-launch-rescue-snapshot"'),
    'Expected launch control token mapping for launch rescue snapshot run action.'
  );
  assertCondition(
    appDelegate.includes('case .runLaunchControlHub:\n            return "run-launch-control-hub"'),
    'Expected launch control token mapping for launch control hub run action.'
  );
  assertCondition(
    appDelegate.includes('case .openLatestLaunchControlHub:\n            return "open-latest-launch-control-hub"'),
    'Expected launch control token mapping for launch control hub open action.'
  );
  assertCondition(
    appDelegate.includes('command: .runFameLaunchRescueFollowupNow'),
    'Expected launch control menu command wiring for launch rescue follow-up now.'
  );
  assertCondition(
    appDelegate.includes('command: .copyFameLaunchRescueSnapshot'),
    'Expected launch control menu command wiring for launch rescue snapshot copy.'
  );
  assertCondition(
    appDelegate.includes('command: .openLatestLaunchRescueSnapshot'),
    'Expected launch control menu command wiring for latest launch rescue snapshot open action.'
  );
  assertCondition(
    appDelegate.includes('command: .runFameLaunchRescueSnapshot'),
    'Expected launch control menu command wiring for launch rescue snapshot run action.'
  );
  assertCondition(
    appDelegate.includes('command: .runFameLaunchControlHub'),
    'Expected launch control menu command wiring for launch control hub run action.'
  );
  assertCondition(
    appDelegate.includes('command: .openLatestLaunchControlHub'),
    'Expected launch control menu command wiring for launch control hub open action.'
  );
  assertCondition(
    appDelegate.includes('private func launchRescueFollowupNowMenuStatusTitle('),
    'Expected launch rescue follow-up now menu title helper.'
  );
  assertCondition(
    appDelegate.includes('private func launchRescueSnapshotMenuTitle('),
    'Expected launch rescue snapshot menu title helper.'
  );
  assertCondition(
    appDelegate.includes('private func launchRescueFollowupNowMenuStatusToolTip('),
    'Expected launch rescue follow-up now menu tooltip helper.'
  );
  assertCondition(
    appDelegate.includes('private func maybeSurfaceLaunchRescueAutoSelfHealAttentionNudge('),
    'Expected launch rescue auto menu refresh path to include self-heal attention nudge helper.'
  );
  assertCondition(
    appDelegate.includes('private func latestLaunchRescueAutoFollowupSelfHealSnapshot('),
    'Expected launch rescue auto helper to read latest self-heal snapshot from activity log.'
  );
  assertCondition(
    appDelegate.includes('activityItems: activityLog.items'),
    'Expected launch rescue auto helpers to route through shared self-heal activity-item status logic.'
  );
  assertCondition(
    appDelegate.includes('followupOutcomeCoachStatusTitle: followupOutcomeCoachStatusTitle'),
    'Expected launch rescue follow-up menu tooltips to include coach guidance.'
  );
  assertCondition(
    appDelegate.includes('id: "run-fame-launch-rescue-followup-now"'),
    'Expected dedicated launch rescue follow-up command palette action.'
  );
  assertCondition(
    appDelegate.includes('id: "run-fame-exceptional-loop"'),
    'Expected dedicated fame exceptional loop command palette action.'
  );
  assertCondition(
    appDelegate.includes('id: "run-fame-launch-rescue-self-heal-attention"'),
    'Expected dedicated launch rescue self-heal attention command palette action.'
  );
  assertCondition(
    appDelegate.includes('id: "copy-fame-launch-rescue-snapshot"'),
    'Expected dedicated launch rescue snapshot copy command palette action.'
  );
  assertCondition(
    appDelegate.includes('id: "run-fame-launch-rescue-snapshot"'),
    'Expected dedicated launch rescue snapshot run command palette action.'
  );
  assertCondition(
    appDelegate.includes('id: "run-fame-launch-control-hub"'),
    'Expected dedicated launch control hub run command palette action.'
  );
  assertCondition(
    appDelegate.includes('id: "open-latest-launch-control-hub"'),
    'Expected dedicated launch control hub open command palette action.'
  );
  assertCondition(
    appDelegate.includes('private func makeLaunchRescueSnapshot('),
    'Expected launch rescue snapshot builder helper for operator copy flow.'
  );
  assertCondition(
    appDelegate.includes('private func copyFameLaunchRescueSnapshot('),
    'Expected launch rescue snapshot copy command handler.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchRescueSnapshot('),
    'Expected launch rescue snapshot run command handler.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchControlHub('),
    'Expected launch control hub run command handler.'
  );
  assertCondition(
    appDelegate.includes('@discardableResult\n    private func runFameLaunchControlHub(\n        source: String = "manual",\n        announce: Bool = true,'),
    'Expected launch control hub runner to support non-intrusive auto mode parameters.'
  );
  assertCondition(
    appDelegate.includes('private func saveLaunchRescueSnapshotArtifact('),
    'Expected launch rescue snapshot save-artifact helper.'
  );
  assertCondition(
    appDelegate.includes('private func openLatestLaunchRescueSnapshot('),
    'Expected latest launch rescue snapshot open helper.'
  );
  assertCondition(
    appDelegate.includes('private func openLatestLaunchControlHub('),
    'Expected launch control hub open helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchControlHubActionSubtitle('),
    'Expected launch control hub command subtitle helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchControlHubRunActivityDetail('),
    'Expected launch control hub run activity-detail helper.'
  );
  assertCondition(
    appDelegate.includes('id: "open-latest-launch-rescue-snapshot"'),
    'Expected command palette action for opening latest launch rescue snapshot.'
  );
  assertCondition(
    appDelegate.includes('case .copyFameLaunchRescueSnapshot:\n            copyFameLaunchRescueSnapshot()'),
    'Expected fame menu command switch wiring for launch rescue snapshot copy.'
  );
  assertCondition(
    appDelegate.includes('case .runFameLaunchRescueSnapshot:\n            runFameLaunchRescueSnapshot()'),
    'Expected fame menu command switch wiring for launch rescue snapshot run action.'
  );
  assertCondition(
    appDelegate.includes('case .runFameLaunchControlHub:\n            runFameLaunchControlHub()'),
    'Expected fame menu command switch wiring for launch control hub run action.'
  );
  assertCondition(
    appDelegate.includes('case .runFameExceptionalLoop:\n            runFameExceptionalLoop()'),
    'Expected fame menu command switch wiring for exceptional loop action.'
  );
  assertCondition(
    appDelegate.includes('case "run-fame-launch-control-hub":\n            runFameLaunchControlHub()'),
    'Expected command-id router wiring for launch control hub run action.'
  );
  assertCondition(
    appDelegate.includes('case "run-fame-exceptional-loop":\n            runFameExceptionalLoop()'),
    'Expected command-id router wiring for exceptional loop action.'
  );
  assertCondition(
    appDelegate.includes('makeFameMenuItem(title: "Run Fame Exceptional Loop", command: .runFameExceptionalLoop)'),
    'Expected Fame menu entry for exceptional loop action.'
  );
  assertCondition(
    appDelegate.includes('case runFameExceptionalLoop'),
    'Expected Fame menu command enum entry for exceptional loop action.'
  );
  assertCondition(
    appDelegate.includes('case "run-fame-exceptional-loop":\n            return "Run Fame Exceptional Loop"'),
    'Expected onboarding command-title mapping for exceptional loop action.'
  );
  assertCondition(
    appDelegate.includes('case .openLatestLaunchRescueSnapshot:\n            openLatestLaunchRescueSnapshot()'),
    'Expected fame menu command switch wiring for latest launch rescue snapshot open action.'
  );
  assertCondition(
    appDelegate.includes('case .openLatestLaunchControlHub:\n            openLatestLaunchControlHub()'),
    'Expected fame menu command switch wiring for launch control hub open action.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueSnapshotMarkdown('),
    'Expected launch rescue snapshot markdown formatter helper.'
  );
  assertCondition(
    appDelegate.includes('nonisolated static func launchRescueSnapshotMenuTitle('),
    'Expected launch rescue snapshot menu title formatter helper.'
  );
  assertCondition(
    appDelegate.includes('- `Run Launch Rescue Snapshot`'),
    'Expected launch control brief quick commands to include launch rescue snapshot run action.'
  );
  assertCondition(
    appDelegate.includes('- `Run Launch Control Hub`'),
    'Expected launch control brief quick commands to include launch control hub run action.'
  );
  assertCondition(
    appDelegate.includes('- `Copy Launch Rescue Snapshot`'),
    'Expected launch control brief quick commands to include launch rescue snapshot copy action.'
  );
  assertCondition(
    appDelegate.includes('- `Open Latest Launch Rescue Snapshot`'),
    'Expected launch control brief quick commands to include launch rescue snapshot open action.'
  );
  assertCondition(
    appDelegate.includes('- `Open Launch Control Hub`'),
    'Expected launch control brief quick commands to include launch control hub open action.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchRescueFollowupNow('),
    'Expected launch rescue follow-up command handler.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchRescueFollowupNowAuto('),
    'Expected launch rescue follow-up auto helper.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchRescueFollowupNowAutoPressurePersistence('),
    'Expected launch rescue follow-up pressure auto-run helper.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchRescueFollowupNowAutoSelfHeal('),
    'Expected launch rescue follow-up auto self-heal helper.'
  );
  assertCondition(
    appDelegate.includes('private func runFameLaunchRescueFollowupNowAutoSelfHealNextMoveArtifacts('),
    'Expected launch rescue follow-up auto self-heal helper for next-move artifacts.'
  );
  assertCondition(
    appDelegate.includes('private func hasFreshLaunchRescueAutoFollowupArtifact('),
    'Expected launch rescue follow-up auto helper to check fresh artifacts before scoring.'
  );
  assertCondition(
    appDelegate.includes('let wasSuccessful = runFameLaunchRescueFollowupNowAutoSelfHeal('),
    'Expected launch rescue follow-up auto paths to self-heal artifacts before scoring success.'
  );
  assertCondition(
    appDelegate.includes('detail: Self.launchRescueAutoFollowupSelfHealActivityDetail('),
    'Expected launch rescue follow-up auto self-heal activity telemetry helper wiring.'
  );
  assertCondition(
    appDelegate.includes('setFameLaunchRescueBurstLastFollowupReason(normalizedTriggerReason, defaults: defaults)'),
    'Expected launch rescue follow-up command to persist follow-up reason telemetry.'
  );
  assertCondition(
    appDelegate.includes('setFameLaunchRescueBurstLastFollowupCommandID(normalizedRouteCommandID, defaults: defaults)'),
    'Expected launch rescue follow-up command to persist follow-up route telemetry.'
  );
  assertCondition(
    appDelegate.includes('setFameLaunchRescueBurstLastFollowupAt(now, defaults: defaults)'),
    'Expected launch rescue follow-up command to persist follow-up timestamp telemetry.'
  );
  assertCondition(
    appDelegate.includes('let followupScoreboard = recordLaunchRescueFollowupOutcome('),
    'Expected launch rescue follow-up command to persist outcome scoreboard telemetry.'
  );
  assertCondition(
    appDelegate.includes('run-fame-launch-rescue-followup-now-auto-recovery-checklist-streak-'),
    'Expected launch rescue follow-up command to auto-run recovery checklist on repeated recovery-lane outcomes.'
  );
  assertCondition(
    appDelegate.includes('run-fame-launch-rescue-followup-now-auto-recovery-checklist-cooldown-'),
    'Expected launch rescue follow-up command to emit cooldown telemetry when escalation is rate-limited.'
  );
  assertCondition(
    appDelegate.includes('run-fame-launch-rescue-followup-now-auto-recovery-checklist-cooldown-tune-'),
    'Expected launch rescue follow-up command to emit adaptive cooldown tuning telemetry.'
  );
  assertCondition(
    appDelegate.includes('auto-checklist cooling down'),
    'Expected launch rescue follow-up coach messaging to surface auto-checklist cooldown state.'
  );
  assertCondition(
    !appDelegate.includes('detail: "run-fame-launch-rescue-burst-auto-trigger-'),
    'Found raw launch rescue auto-trigger detail emit; expected helper-based contract wiring.'
  );

  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstLastFollowupReasonKey = "fameLaunchRescueBurstLastFollowupReason"'),
    'Expected launch rescue follow-up reason defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstLastFollowupCommandIDKey = "fameLaunchRescueBurstLastFollowupCommandID"'),
    'Expected launch rescue follow-up command defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstLastFollowupAtKey = "fameLaunchRescueBurstLastFollowupAt"'),
    'Expected launch rescue follow-up timestamp defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupOutcomeTotalCountKey = "fameLaunchRescueBurstFollowupOutcomeTotalCount"'),
    'Expected launch rescue follow-up outcome total-count defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupOutcomeSuccessCountKey = "fameLaunchRescueBurstFollowupOutcomeSuccessCount"'),
    'Expected launch rescue follow-up outcome success-count defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupOutcomeLastAtKey = "fameLaunchRescueBurstFollowupOutcomeLastAt"'),
    'Expected launch rescue follow-up outcome last-at defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupOutcomeHistoryKey = "fameLaunchRescueBurstFollowupOutcomeHistory"'),
    'Expected launch rescue follow-up outcome history defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey = "fameLaunchRescueBurstFollowupCoachRecoveryLaneStreak"'),
    'Expected launch rescue follow-up coach recovery-lane streak defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey ='),
    'Expected launch rescue follow-up coach auto-checklist timestamp defaults key.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes = 30'),
    'Expected launch rescue follow-up coach auto-checklist cooldown default.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey ='),
    'Expected launch rescue follow-up coach auto-checklist cooldown-key default.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMinimum = 5'),
    'Expected launch rescue follow-up coach auto-checklist cooldown minimum.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMaximum = 60'),
    'Expected launch rescue follow-up coach auto-checklist cooldown maximum.'
  );
  assertCondition(
    appDefaults.includes('static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesStep = 5'),
    'Expected launch rescue follow-up coach auto-checklist cooldown adaptive step.'
  );
  assertCondition(
    fameSnapshotArchive.includes('static func saveLaunchRescueSnapshot('),
    'Expected launch rescue snapshot save artifact helper in archive.'
  );
  assertCondition(
    fameSnapshotArchive.includes('fileNamePrefix: "fame-launch-rescue-snapshot"'),
    'Expected launch rescue snapshot artifact file-name prefix wiring.'
  );
  assertCondition(
    fameSnapshotArchive.includes('static func latestLaunchRescueSnapshotURL(baseDirectory: URL? = nil) throws -> URL?'),
    'Expected latest launch rescue snapshot archive lookup helper.'
  );
  assertCondition(
    archiveTests.includes('testSaveLaunchRescueSnapshotCreatesFileWithStableName'),
    'Expected launch rescue snapshot archive save test coverage.'
  );
  assertCondition(
    archiveTests.includes('testLatestLaunchRescueSnapshotURLReturnsNewestFile'),
    'Expected launch rescue snapshot archive latest-url coverage.'
  );
  assertCondition(
    archiveTests.includes('testLatestLaunchRescueSnapshotURLReturnsNilWhenMissing'),
    'Expected launch rescue snapshot archive missing-state coverage.'
  );

  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerActivityDetailContractFormatsReasonAndPressureSuffix'),
    'Expected formatter contract test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchControlHubAutoEscalationAndSkipActivityDetailsNormalizeInputs'),
    'Expected launch control hub auto-run telemetry helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupAutoPressureActivityDetailFormatsSuccessAndFailure'),
    'Expected launch rescue auto follow-up pressure auto-run activity-detail helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupAutoActivityDetailNormalizesReasonAndOutcome'),
    'Expected launch rescue auto follow-up auto activity-detail helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupArtifactsReadyMapsRouteFallbackRules'),
    'Expected launch rescue auto follow-up artifact-ready helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupArtifactsMissingTracksRouteRepairGaps'),
    'Expected launch rescue auto follow-up artifact-missing helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupSelfHealActivityDetailNormalizesReasonRouteAndOutcome'),
    'Expected launch rescue auto follow-up self-heal activity-detail helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupSelfHealSnapshotParsesContractAndNormalizesFields'),
    'Expected launch rescue auto follow-up self-heal snapshot parser coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupSelfHealSnapshotRecencyAndStatusFormatting'),
    'Expected launch rescue auto follow-up self-heal recency and status formatting coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoSelfHealAttentionIssueTokenAndMessageCoverHealthyStaleAndMismatchStates'),
    'Expected launch rescue auto self-heal attention issue/message helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoSelfHealAttentionNudgeGatingTracksConsecutiveIssuesAndCooldown'),
    'Expected launch rescue auto self-heal attention nudge gating coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoSelfHealAttentionActivityDetailNormalizesIssueAndStreak'),
    'Expected launch rescue auto self-heal attention activity-detail helper coverage.'
  );
  assertCondition(
    launchTests.includes('testCommandPaletteLaunchRescueSelfHealAttentionActionAppearsForStaleIssue'),
    'Expected command palette coverage for stale launch rescue self-heal attention action.'
  );
  assertCondition(
    launchTests.includes('testCommandPaletteLaunchRescueSelfHealAttentionActionAppearsForMismatchIssue'),
    'Expected command palette coverage for mismatch launch rescue self-heal attention action.'
  );
  assertCondition(
    launchTests.includes('testCommandPaletteLaunchRescueSelfHealAttentionActionHidesWhenHealthyOrNoTrigger'),
    'Expected command palette coverage for healthy/none launch rescue self-heal attention suppression.'
  );
  assertCondition(
    launchTests.includes('testFameExceptionalLoopPlanPrioritizesSelfHealAttentionBeforeOtherSignals'),
    'Expected fame exceptional loop priority coverage for self-heal attention states.'
  );
  assertCondition(
    launchTests.includes('testFameExceptionalLoopPlanPrioritizesLaunchControlWhenUrgencyIsHigh'),
    'Expected fame exceptional loop priority coverage for high launch urgency states.'
  );
  assertCondition(
    launchTests.includes('testFameExceptionalLoopPlanUsesCadenceIgnitionWhenStreakIsZero'),
    'Expected fame exceptional loop priority coverage for cadence ignition fallback.'
  );
  assertCondition(
    launchTests.includes('testFameExceptionalLoopActionHelpersFormatTitleSubtitleAndActivityDetails'),
    'Expected fame exceptional loop helper formatting coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupArtifactIsFreshRequiresTimestampAndWindow'),
    'Expected launch rescue auto follow-up artifact freshness helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoMenuStatusCanIncludeSelfHealBadgeAndTooltipFromActivityLog'),
    'Expected launch rescue auto menu integration coverage for self-heal badge and tooltip context.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoMenusSuppressSelfHealWhenLatestSnapshotIsMismatchedOrStale'),
    'Expected launch rescue auto/follow-up menu integration coverage for stale or mismatched self-heal suppression.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerReasonTokenFromActivityDetailParsesKnownContract'),
    'Expected parser contract test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerReasonTokenNormalizesKnownAndActivityDetailValues'),
    'Expected shared reason-token normalization test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerAtParsesKnownTimestampValues'),
    'Expected timestamp normalization test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerAtStatusTitleFormatsKnownAndFallbackStates'),
    'Expected timestamp status-title test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerFollowupStatusTitleFormatsPriorityCheckpointAndStandby'),
    'Expected follow-up status-title test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerFollowupStatusSubtitleHintFormatsKnownAndSkipsUnknown'),
    'Expected follow-up subtitle-hint test coverage for launch rescue auto-trigger details.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoStatusMenuTitleCanAppendFollowupBadgeAndMomentumBadge'),
    'Expected launch rescue auto status-menu follow-up badge coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerFollowupMenuBadgeFormatsKnownAndFallbackStates'),
    'Expected launch rescue auto follow-up menu-badge helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoStatusTitlesCanAppendTriggerSeverityBadge'),
    'Expected launch rescue auto status title severity badge coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerSeverityBadgeAndSubtitleHintFormatsKnownAndSkipsUnknown'),
    'Expected launch rescue auto trigger severity helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoTriggerFollowupCommandRouteHelpersMapKnownReasonsAndFallback'),
    'Expected launch rescue follow-up routing helper coverage.'
  );
  assertCondition(
    launchTests.includes('run-fame-launch-rescue-followup-now'),
    'Expected command palette coverage for launch rescue follow-up command id.'
  );
  assertCondition(
    launchTests.includes('run-fame-exceptional-loop'),
    'Expected command palette coverage for fame exceptional loop command id.'
  );
  assertCondition(
    launchTests.includes('AppDelegate.fameOnboardingCommandTitle("run-fame-exceptional-loop")'),
    'Expected onboarding command-title coverage for exceptional loop action.'
  );
  assertCondition(
    launchTests.includes('run-fame-launch-rescue-self-heal-attention'),
    'Expected command palette coverage for launch rescue self-heal attention command id.'
  );
  assertCondition(
    launchTests.includes('copy-fame-launch-rescue-snapshot'),
    'Expected command palette coverage for launch rescue snapshot copy command id.'
  );
  assertCondition(
    launchTests.includes('run-fame-launch-rescue-snapshot'),
    'Expected command palette coverage for launch rescue snapshot run command id.'
  );
  assertCondition(
    launchTests.includes('run-fame-launch-control-hub'),
    'Expected command palette coverage for launch control hub run command id.'
  );
  assertCondition(
    launchTests.includes('open-latest-launch-rescue-snapshot'),
    'Expected command palette coverage for launch rescue snapshot open command id.'
  );
  assertCondition(
    launchTests.includes('open-latest-launch-control-hub'),
    'Expected command palette coverage for launch control hub open command id.'
  );
  assertCondition(
    launchTests.includes('testLaunchControlHubActionSubtitleFormatsEmptyPartialAndFullStates'),
    'Expected launch control hub subtitle helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchControlHubRunActivityDetailFormatsManualAndAutoSources'),
    'Expected launch control hub run activity-detail helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoMenuStatusTitleCanIncludeFollowupBadgeFromDefaults'),
    'Expected launch rescue auto menu status integration coverage for follow-up badge defaults wiring.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueSnapshotMenuTitleCanAppendFollowupMomentumCue'),
    'Expected launch rescue snapshot menu title momentum-hint coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchControlBriefAndLaunchRescueSnapshotShareCanonicalStatusLines'),
    'Expected cross-artifact canonical status-line consistency coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoStatusMenuToolTipFormatsCoreStates'),
    'Expected launch rescue auto status menu tooltip core-state coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoStatusMenuToolTipIncludesTriggerTimeFollowupAndMomentumHints'),
    'Expected launch rescue auto status menu tooltip context-line coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoMenuStatusToolTipCanIncludeFollowupAndMomentumFromDefaults'),
    'Expected launch rescue auto menu status tooltip integration coverage from defaults wiring.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupNowMenuStatusCanReflectDefaultsRouteAndPriorityWindow'),
    'Expected launch rescue follow-up now menu status coverage for priority route copy.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupNowMenuStatusFallsBackWhenNoAutoTriggerRecorded'),
    'Expected launch rescue follow-up now menu status fallback coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupOutcomeScoreboardStatusTitleFormats24hRollingAndFreshness'),
    'Expected launch rescue follow-up scoreboard status-title coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupOutcomeScoreboardReadsRollingAnd24hCountsFromDefaults'),
    'Expected launch rescue follow-up scoreboard defaults snapshot coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupOutcomeCoachStatusTitleFormatsBaselineWinningAndRecoveryLanes'),
    'Expected launch rescue follow-up coach status-title coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupCoachRecoveryLaneStreakNextResetsOrIncrementsAsExpected'),
    'Expected launch rescue follow-up coach recovery-lane streak helper coverage.'
  );
  assertCondition(
    launchTests.includes('testShouldAutoRunLaunchRescueFollowupRecoveryChecklistRequiresRecoveryLaneAndArmedStreak'),
    'Expected launch rescue follow-up auto-checklist escalation helper coverage.'
  );
  assertCondition(
    launchTests.includes('testShouldAutoRunLaunchRescueFollowupRecoveryChecklistRespectsCooldownWindow'),
    'Expected launch rescue follow-up auto-checklist cooldown gate coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupRecoveryChecklistCooldownMinutesRemainingTracksWindow'),
    'Expected launch rescue follow-up auto-checklist cooldown summary helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupRecoveryChecklistCooldownMinutesNextAdaptsAndRecenters'),
    'Expected launch rescue follow-up adaptive cooldown helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupNowMenuStatusToolTipCanShowRecoveryLaneEscalationArmed'),
    'Expected launch rescue follow-up menu tooltip coverage for recovery-lane escalation guidance.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueFollowupNowMenuStatusToolTipCanShowRecoveryLaneEscalationCooldown'),
    'Expected launch rescue follow-up menu tooltip coverage for recovery-lane cooldown guidance.'
  );
  assertCondition(
    launchTests.includes('"run-launch-rescue-followup-now"'),
    'Expected launch control slot/token coverage for launch rescue follow-up menu row.'
  );
  assertCondition(
    launchTests.includes('"copy-launch-rescue-snapshot"'),
    'Expected launch control slot/token coverage for launch rescue snapshot menu row.'
  );
  assertCondition(
    launchTests.includes('"open-latest-launch-rescue-snapshot"'),
    'Expected launch control slot/token coverage for launch rescue snapshot open menu row.'
  );
  assertCondition(
    launchTests.includes('"run-launch-rescue-snapshot"'),
    'Expected launch control slot/token coverage for launch rescue snapshot run menu row.'
  );
  assertCondition(
    launchTests.includes('"run-launch-control-hub"'),
    'Expected launch control slot/token coverage for launch control hub run menu row.'
  );
  assertCondition(
    launchTests.includes('"open-latest-launch-control-hub"'),
    'Expected launch control slot/token coverage for launch control hub menu row.'
  );
  assertCondition(
    launchTests.includes('"launch-control-tap-run-launch-rescue-followup-now"'),
    'Expected launch control tap telemetry coverage for launch rescue follow-up menu row.'
  );
  assertCondition(
    launchTests.includes('"launch-control-tap-copy-launch-rescue-snapshot"'),
    'Expected launch control tap telemetry coverage for launch rescue snapshot menu row.'
  );
  assertCondition(
    launchTests.includes('"launch-control-tap-open-latest-launch-rescue-snapshot"'),
    'Expected launch control tap telemetry coverage for launch rescue snapshot open menu row.'
  );
  assertCondition(
    launchTests.includes('"launch-control-tap-run-launch-rescue-snapshot"'),
    'Expected launch control tap telemetry coverage for launch rescue snapshot run menu row.'
  );
  assertCondition(
    launchTests.includes('"launch-control-tap-run-launch-control-hub"'),
    'Expected launch control tap telemetry coverage for launch control hub run menu row.'
  );
  assertCondition(
    launchTests.includes('"launch-control-tap-open-latest-launch-control-hub"'),
    'Expected launch control tap telemetry coverage for launch control hub menu row.'
  );
  assertCondition(
    supportInfo.includes('AppDelegate.launchRescueAutoTriggerReasonToken(token)'),
    'Expected support info auto-trigger normalization to use shared parser/token helper.'
  );
  assertCondition(
    supportInfo.includes('AppDelegate.launchRescueAutoTriggerAt('),
    'Expected support info auto-trigger timestamp normalization to use shared helper.'
  );
  assertCondition(
    supportInfo.includes('AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary('),
    'Expected support info auto-trigger timestamp summary to use shared helper.'
  );
  assertCondition(
    supportInfo.includes('AppDelegate.launchRescueAutoFollowupCommandID('),
    'Expected support info launch rescue follow-up command normalization to use shared helper.'
  );
  assertCondition(
    supportInfo.includes('Launch Rescue Auto Follow-up:'),
    'Expected support info to include launch rescue follow-up summary line.'
  );
  assertCondition(
    supportInfo.includes('Launch Rescue Auto Follow-up Time:'),
    'Expected support info to include launch rescue follow-up timestamp line.'
  );
  assertCondition(
    supportInfo.includes('Launch Rescue Auto Self-Heal:'),
    'Expected support info to include launch rescue auto self-heal status line.'
  );
  assertCondition(
    supportInfo.includes('Launch Rescue Follow-up Scoreboard:'),
    'Expected support info to include launch rescue follow-up scoreboard line.'
  );
  assertCondition(
    supportInfo.includes('Launch Rescue Follow-up Coach:'),
    'Expected support info to include launch rescue follow-up coach line.'
  );
  assertCondition(
    supportInfo.includes('Launch Rescue Follow-up Momentum:'),
    'Expected support info to include launch rescue follow-up momentum line.'
  );
  assertCondition(
    supportInfo.includes('func launchRescueSnapshotMarkdown() -> String'),
    'Expected support info launch rescue snapshot formatter helper.'
  );
  assertCondition(
    supportInfo.includes('AppDelegate.launchRescueAutoFollowupRunSummary('),
    'Expected support info launch rescue auto follow-up summary to use shared formatter helper.'
  );
  assertCondition(
    supportInfo.includes('AppDelegate.launchRescueSnapshotMarkdown('),
    'Expected support info snapshot to use shared launch rescue snapshot formatter helper.'
  );
  assertCondition(
    supportInfo.includes('ActivityLogStore(defaults: defaults).items'),
    'Expected support info to decode activity-log telemetry before resolving launch rescue self-heal status.'
  );
  assertCondition(
    supportInfo.includes('launchRescueAutoFollowupSelfHealArtifactStatusTitle('),
    'Expected support info to use shared launch rescue self-heal artifact status helper.'
  );
  assertCondition(
    supportInfo.includes('autoTriggerSummary: launchRescueBurstAutoTriggerSummary'),
    'Expected support info snapshot helper call to pass auto-trigger summary.'
  );
  assertCondition(
    supportInfo.includes('autoFollowupSummary: launchRescueBurstAutoFollowupSummary'),
    'Expected support info snapshot helper call to pass auto follow-up summary.'
  );
  assertCondition(
    supportInfo.includes('followupMomentumStatusTitle: launchRescueFollowupOutcomeMomentumStatusTitle'),
    'Expected support info snapshot helper call to pass momentum status title.'
  );
  assertCondition(
    supportTests.includes('testMakeParsesLaunchRescueAutoTriggerReasonFromActivityDetailContract'),
    'Expected support info activity-detail fallback contract test coverage.'
  );
  assertCondition(
    supportTests.includes('testMakeReadsLaunchRescueAutoTriggerAtFromDefaults'),
    'Expected support info auto-trigger timestamp read coverage.'
  );
  assertCondition(
    supportTests.includes('testMakeReadsLaunchRescueAutoFollowupTelemetryFromDefaults'),
    'Expected support info launch rescue follow-up telemetry read coverage.'
  );
  assertCondition(
    supportTests.includes('testMakeDerivesLaunchRescueAutoSelfHealStatusFromRecentMatchingActivityLog'),
    'Expected support info coverage for launch rescue auto self-heal status from matching recent telemetry.'
  );
  assertCondition(
    supportTests.includes('testMakeDerivesLaunchRescueAutoSelfHealStatusAsStaleForMatchingOldActivityLog'),
    'Expected support info coverage for launch rescue auto self-heal stale telemetry handling.'
  );
  assertCondition(
    supportTests.includes('testMakeDerivesLaunchRescueAutoSelfHealStatusAsReasonWaitWhenLatestActivityMismatches'),
    'Expected support info coverage for launch rescue auto self-heal reason-mismatch telemetry handling.'
  );
  assertCondition(
    supportTests.includes('testMakeReadsLaunchRescueFollowupOutcomeScoreboardFromDefaults'),
    'Expected support info launch rescue follow-up scoreboard read coverage.'
  );
  assertCondition(
    supportTests.includes('testMakeReadsLaunchRescueFollowupCoachCooldownStateFromDefaults'),
    'Expected support info launch rescue follow-up coach cooldown coverage.'
  );
  assertCondition(
    supportTests.includes('testLaunchRescueSnapshotMarkdownIncludesBaselineStatusLines'),
    'Expected support info snapshot formatter baseline coverage.'
  );
  assertCondition(
    supportTests.includes('testLaunchRescueSnapshotMarkdownIncludesContextualTelemetry'),
    'Expected support info snapshot formatter contextual telemetry coverage.'
  );
  assertCondition(
    supportTests.includes('testLaunchRescueSnapshotMarkdownUsesCanonicalAppDelegateFormatter'),
    'Expected support info snapshot formatter canonical AppDelegate helper coverage.'
  );
  assertCondition(
    issueSupportBundle.includes('## Launch Rescue Snapshot'),
    'Expected issue support bundle markdown to include launch rescue snapshot section.'
  );
  assertCondition(
    issueSupportBundle.includes('\\(supportInfo.launchRescueSnapshotMarkdown())'),
    'Expected issue support bundle markdown to embed launch rescue snapshot formatter output.'
  );
  assertCondition(
    bugReportDraft.includes('## Launch Rescue Snapshot'),
    'Expected bug report draft markdown to include launch rescue snapshot section.'
  );
  assertCondition(
    bugReportDraft.includes('\\(supportInfo.launchRescueSnapshotMarkdown())'),
    'Expected bug report draft markdown to embed launch rescue snapshot formatter output.'
  );
  assertCondition(
    issueSupportTests.includes('Launch Rescue Auto Trigger Time:'),
    'Expected issue support bundle coverage for launch rescue auto-trigger timestamp line.'
  );
  assertCondition(
    issueSupportTests.includes('Launch Rescue Auto Follow-up:'),
    'Expected issue support bundle coverage for launch rescue follow-up summary line.'
  );
  assertCondition(
    issueSupportTests.includes('Launch Rescue Follow-up Scoreboard:'),
    'Expected issue support bundle coverage for launch rescue follow-up scoreboard line.'
  );
  assertCondition(
    issueSupportTests.includes('Launch Rescue Follow-up Coach:'),
    'Expected issue support bundle coverage for launch rescue follow-up coach line.'
  );
  assertCondition(
    issueSupportTests.includes('## Launch Rescue Snapshot'),
    'Expected issue support bundle coverage for launch rescue snapshot section.'
  );
  assertCondition(
    issueSupportTests.includes('Auto trigger: Urgency High escalation.'),
    'Expected issue support bundle coverage for launch rescue snapshot trigger summary.'
  );
  assertCondition(
    issueSupportTests.includes('Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend.'),
    'Expected issue support bundle coverage for launch rescue snapshot momentum baseline line.'
  );
  assertCondition(
    bugReportTests.includes('## Launch Rescue Snapshot'),
    'Expected bug report draft coverage for launch rescue snapshot section.'
  );
  assertCondition(
    bugReportTests.includes('Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend.'),
    'Expected bug report draft coverage for launch rescue snapshot momentum line.'
  );
  assertCondition(
    launchTests.includes('Launch Rescue Auto Follow-up:'),
    'Expected launch control brief/subtitle coverage for launch rescue auto-trigger follow-up guidance.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueAutoFollowupRunSummaryFormatsKnownAndFallbackStates'),
    'Expected launch rescue auto follow-up run-summary helper coverage.'
  );
  assertCondition(
    launchTests.includes('testLaunchRescueSnapshotMarkdownFormatsCanonicalLines'),
    'Expected launch rescue snapshot markdown formatter helper coverage.'
  );
}

try {
  runFixtureSuite();
  process.stdout.write('Launch rescue auto-trigger contract fixture checks passed.\n');
} catch (error) {
  process.stderr.write(`Launch rescue auto-trigger contract fixture checks failed: ${error.message}\n`);
  process.exit(1);
}
