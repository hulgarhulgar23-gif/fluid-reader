import AppKit
import Combine
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = SettingsStore.shared
    private let readerState = ReaderState()
    private let speech = SpeechService()
    private let effects = EffectsService()
    private let activityLog = ActivityLogStore()
    private let firstRunGuide = FirstRunGuide()
    private let rewardHUD = RewardHUDController()
    private let ocr = OCRService()
    private let selectionController = SelectionController()
    private let hotKey = HotKeyManager()
    private lazy var readerWindow = ReaderWindowController(
        state: readerState,
        settings: settings,
        readText: { [weak self] text in self?.read(text) },
        copyText: { [weak self] text, message in self?.copyToClipboard(text, message: message) },
        copyResult: { [weak self] in self?.copyResult() },
        copyImage: { [weak self] in self?.copyLastImage() },
        saveText: { [weak self] text, title, prefix in self?.saveText(text, title: title, fileNamePrefix: prefix) },
        saveResult: { [weak self] in self?.saveResult() },
        saveImage: { [weak self] in self?.saveLastImage() },
        saveSnippet: { [weak self] text in self?.saveSnippet(text) },
        askLLM: { [weak self] question in self?.askLLM(question: question) },
        stop: { [weak self] in self?.stopSpeech() },
        famePulseState: { [weak self] in
            self?.famePulseWidgetState() ?? .unknown
        },
        fameDailyScorecardState: { [weak self] in
            self?.fameDailyScorecardState() ?? .unknown
        },
        cadenceExecutionKitMomentumSnapshot: { [weak self] in
            self?.cadenceExecutionKitCommandStreakSnapshot() ?? (current: 0, best: 0)
        },
        fameAutoOpsBundleStatus: { [weak self] in
            self?.autoOpsBundleEscalationStatus() ?? .disabled
        },
        fameAutoOpsBundleStatusTitle: { [weak self] in
            self?.autoOpsBundleMenuStatusTitle() ?? Self.autoOpsBundleEscalationStatusMenuTitle(.disabled)
        },
        fameAutoOpsBundleStatusSubtitle: { [weak self] in
            self?.autoOpsBundleMenuStatusToolTip() ?? Self.autoOpsBundleEscalationStatusMenuToolTip(.disabled)
        },
        runFameAutoOpsBundleStatusAction: { [weak self] in
            self?.handleReaderAutoOpsBundleStatusTap()
        },
        fameLaunchRescueAutoStatus: { [weak self] in
            self?.launchRescueBurstAutoStatus() ?? .disabled
        },
        fameLaunchRescueAutoStatusTitle: { [weak self] in
            self?.launchRescueAutoMenuStatusTitle() ?? Self.launchRescueBurstAutoStatusMenuTitle(.disabled)
        },
        fameLaunchRescueAutoStatusSubtitle: { [weak self] in
            self?.launchRescueAutoMenuStatusToolTip() ?? Self.launchRescueBurstAutoStatusMenuToolTip(.disabled)
        },
        runFameLaunchRescueAutoStatusAction: { [weak self] in
            self?.handleReaderLaunchRescueAutoStatusTap()
        },
        runFameNextMoveCadenceExecutionKit: { [weak self] in
            self?.recordCommandAction("run-fame-next-move-cadence-execution-kit")
            self?.runFameNextMove(followup: .cadenceExecutionKit)
        },
        copyLatestNextMoveCadenceExecutionKit: { [weak self] in
            self?.recordCommandAction("copy-next-move-cadence-execution-kit")
            self?.copyLatestNextMoveCadenceExecutionKit()
        },
        runFameCadenceMomentumBrief: { [weak self] in
            self?.runFameCadenceMomentumBrief()
        },
        runFameCadenceAutopilotLoop: { [weak self] in
            self?.recordCommandAction("run-fame-cadence-autopilot-loop")
            self?.runFameCadenceAutopilotLoop()
        },
        runFameDailyScorecard: { [weak self] in
            self?.runFameDailyScorecard()
        },
        runFameRecoverySprint: { [weak self] in
            self?.runFameRecoverySprint()
        },
        runFameRiskTimeline: { [weak self] in
            self?.runFameRiskTimeline()
        },
        runFameOperatorDashboard: { [weak self] in
            self?.runFameOperatorDashboard()
        },
        openLatestRecoverySprint: { [weak self] in
            self?.openLatestRecoverySprint()
        },
        openLatestDailyScorecard: { [weak self] in
            self?.openLatestDailyScorecard()
        },
        openLatestOperatorDashboard: { [weak self] in
            self?.openLatestOperatorDashboard()
        }
    )
    private lazy var settingsWindow = SettingsWindowController(
        settings: settings,
        testVoice: { [weak self] in self?.read("This is Fluid Reader.") },
        testEffect: { [weak self] in
            self?.previewFeelFlow()
        },
        resetCadenceExecutionKitStreak: { [weak self] in
            self?.resetCadenceExecutionKitCommandStreakFromSettings()
        },
        applyFameExceptionalLoopAutoRecoveryLaneTuning: { [weak self] in
            self?.runFameExceptionalLoopAutoRecoveryLaneAutoTuneFromSettings()
        },
        resetFameExceptionalLoopOutcomeTuning: { [weak self] in
            self?.resetFameExceptionalLoopOutcomeTuningFromSettings()
        },
        runFameExceptionalLoopRecoveryLaneNow: { [weak self] in
            self?.runFameExceptionalLoopRecoveryLaneNowFromSettings()
        },
        runFameExceptionalLoopHealthRecommendedAction: { [weak self] in
            self?.runFameExceptionalLoopHealthRecommendedActionFromSettings()
        },
        openLatestFameExceptionalLoopRecap: { [weak self] in
            self?.openLatestFameExceptionalLoopRecapFromSettings()
        }
    )
    private lazy var askPromptWindow = AskPromptWindow { [weak self] prompt in
        self?.askLLM(question: prompt)
    }
    private lazy var setupChecklistWindow = SetupChecklistWindow(
        report: { [weak self] in
            guard let self else { return .empty }
            return SetupChecklistReport.make(settings: self.settings)
        },
        handleAction: { [weak self] action in
            self?.handleSetupChecklistAction(action)
        }
    )
    private lazy var commandPalette = CommandPaletteWindow(
        state: readerState,
        settings: settings,
        actions: { [weak self] in
            self?.commandPaletteActions() ?? []
        },
        inlineActions: { [weak self] query in
            self?.commandPaletteInlineActions(query) ?? []
        },
        onShow: { [weak self] in
            self?.refreshFameLaunchCountdownForTopCard()
        },
        topPickMilestone: { [weak self] milestone in
            self?.handleTopPickMilestoneFeedback(milestone)
        },
        recordBestChannelLaunchPackPressureActivity: { [weak self] activity in
            self?.recordBestChannelLaunchPackPressureActivity(activity)
        },
        recordRun: { [weak self] action in
            self?.recordCommandAction(action.id)
        }
    )
    private var statusItem: NSStatusItem?
    private var statusFlashTask: Task<Void, Never>?
    private var famePulseBadgeTask: Task<Void, Never>?
    private var statusBaseSymbol = "text.viewfinder"
    private var statusBaseTint: NSColor?
    private var fameStatusBadgeLevel = "normal"
    private var famePulseLastSignal: FamePulseAlertSignal?
    private var fameLaunchUrgencyLast: FameLaunchBadgeUrgency?
    private var famePulseTransitionPrimed = false
    private var fameLaunchUrgencyTransitionPrimed = false
    private var fameOnboardingGapTransitionPrimed = false
    private var fameOnboardingGapLastMissingArtifacts: Int?
    private var fameOnboardingGapPulseLastAt: Date?
    private var fameOnboardingGapRecoveryLastAt: Date?
    private let fameOnboardingGapPulseCooldown: TimeInterval = 15 * 60
    private let fameOnboardingGapRecoveryCooldown: TimeInterval = 10 * 60
    private var launchCountdownLastRefreshAt: Date?
    private var workingFeedbackTask: Task<Void, Never>?
    private var previewFeelTask: Task<Void, Never>?
    private var fameLaunchThresholdAlertsCooldownRefreshTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    private var styleMenuItems: [String: NSMenuItem] = [:]
    private var hitMenuItems: [Double: NSMenuItem] = [:]
    private var famePulseRiskMenuItem: NSMenuItem?
    private var famePulseRiskDetailMenuItem: NSMenuItem?
    private var fameAutoOpsBundleStatusMenuItem: NSMenuItem?
    private var fameLaunchRescueAutoStatusMenuItem: NSMenuItem?
    private var fameLaunchRescueFollowupNowMenuItem: NSMenuItem?
    private var fameLaunchRescueSnapshotMenuItem: NSMenuItem?
    private var fameLaunchCountdownRunMenuItem: NSMenuItem?
    private var fameLaunchRescueBurstRunMenuItem: NSMenuItem?
    private var fameLaunchCountdownOpenMenuItem: NSMenuItem?
    private var fameLaunchRescueBurstOpenMenuItem: NSMenuItem?
    private var fameLaunchRescueSnapshotOpenMenuItem: NSMenuItem?
    private var fameLaunchControlBriefRunMenuItem: NSMenuItem?
    private var fameLaunchControlBriefOpenMenuItem: NSMenuItem?
    private var fameLaunchControlBriefCopyMenuItem: NSMenuItem?
    private var fameLaunchControlHubRunMenuItem: NSMenuItem?
    private var fameLaunchControlHubOpenMenuItem: NSMenuItem?
    private var fameOpenLatestLaunchControlHubMenuItem: NSMenuItem?
    private var fameOpenLatestLaunchRescueSnapshotMenuItem: NSMenuItem?
    private var fameNextMoveMenuItem: NSMenuItem?
    private var fameOnboardingRecoveryNextMenuItem: NSMenuItem?
    private var fameCadenceMomentumMenuItem: NSMenuItem?
    private var fameExceptionalLoopStatusMenuItem: NSMenuItem?
    private var fameExceptionalLoopAutoRecoveryLaneStatusMenuItem: NSMenuItem?
    private var fameExceptionalLoopRecoveryLaneMenuItem: NSMenuItem?
    private var fameExceptionalLoopOpenLatestRecapMenuItem: NSMenuItem?
    private var fameExceptionalLoopAutoTuneMenuItem: NSMenuItem?
    private var fameExceptionalLoopResetTuningMenuItem: NSMenuItem?
    private var fameOnboardingGapMenuItem: NSMenuItem?
    private var fameOnboardingScorecardMenuItem: NSMenuItem?
    private var fameLaunchAlertMenuItem: NSMenuItem?
    private var fameLaunchHealthMenuItem: NSMenuItem?
    private var fameLaunchRecoveryNextMenuItem: NSMenuItem?
    private var fameBestChannelLaunchPackMenuItem: NSMenuItem?
    private var fameBestChannelDraftMenuItem: NSMenuItem?
    private var fameMenu: NSMenu?
    private var fameMenuIsOpen = false
    private var fameLaunchThresholdAlertsMenuItem: NSMenuItem?
    private var fameLaunchThresholdAlertsRecommendedSnoozeMenuItem: NSMenuItem?
    private var fameLaunchThresholdAlertsSnoozeReminderMenuItem: NSMenuItem?
    private var fameLaunchThresholdAlertsQuickActionLastRunAt: Date?
    private var fameLaunchThresholdAlertsQuickActionLastActionToken: String?
    private let fameLaunchThresholdAlertsQuickActionCooldown: TimeInterval = 1.5
    private var fameExceptionalLoopHotKeyAvailable = true
    private var launchRescueAutoSelfHealAttentionIssueToken: String?
    private var launchRescueAutoSelfHealAttentionIssueStreak = 0
    private var launchRescueAutoSelfHealAttentionLastNudgeAt: Date?
    private var launchRescueAutoSelfHealAttentionLastNudgeIssueToken: String?
    private var cadenceExecutionKitAutopilotCueLastAt: Date?
    private var cadenceExecutionKitAutopilotCueLastToken: String?
    private var cadenceExecutionKitAutopilotCueCooldown: TimeInterval {
        TimeInterval(max(0, settings.fameCadenceAutopilotCueCooldownSeconds))
    }
    private var launchControlHealthPulseLastAt: Date?
    private var launchControlHealthPulseLastToken: String?
    private var launchControlHealthPulseCooldown: TimeInterval {
        TimeInterval(max(0, settings.fameLaunchHealthPulseCooldownSeconds))
    }
    private var launchHealthPressureAutoRescueCooldown: TimeInterval {
        TimeInterval(max(0, settings.fameLaunchHealthPressureAutoRescueCooldownHours) * 60 * 60)
    }
    private var isRunningLaunchControlAutoRescue = false
    private var compareRestoreSettings: (style: String, intensity: Double)?
    private let fameMorningBriefLastRunDayKey = "fameMorningBriefLastRunDay"
    private let fameLaunchThresholdAlertsSnoozeUntilKey = AppDefaults.fameLaunchThresholdAlertsSnoozeUntilKey
    private let fameLaunchThresholdAlertsReminderLastSnoozeUntilKey = AppDefaults.fameLaunchThresholdAlertsReminderLastSnoozeUntilKey
    private let fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey = AppDefaults.fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey
    private let fameLaunchHealthTransitionCountDayKey = AppDefaults.fameLaunchHealthTransitionCountDayKey
    private let fameLaunchHealthTransitionWatchToRiskCountKey = AppDefaults.fameLaunchHealthTransitionWatchToRiskCountKey
    private let fameLaunchHealthTransitionRiskToReadyCountKey = AppDefaults.fameLaunchHealthTransitionRiskToReadyCountKey
    private let fameLaunchHealthTransitionHistoryKey = AppDefaults.fameLaunchHealthTransitionHistoryKey
    private let fameLaunchHealthPressureAutoRescueLastRunDayKey = AppDefaults.fameLaunchHealthPressureAutoRescueLastRunDayKey
    private let fameLaunchHealthPressureAutoRescueLastRunAtKey = AppDefaults.fameLaunchHealthPressureAutoRescueLastRunAtKey
    private let fameLaunchRescueBurstLastRunAtKey = AppDefaults.fameLaunchRescueBurstLastRunAtKey
    private let fameLaunchRescueBurstLastAutoTriggerReasonKey = AppDefaults
        .fameLaunchRescueBurstLastAutoTriggerReasonKey
    private let fameLaunchRescueBurstLastAutoTriggerAtKey = AppDefaults
        .fameLaunchRescueBurstLastAutoTriggerAtKey
    private let fameLaunchRescueBurstLastFollowupReasonKey = AppDefaults
        .fameLaunchRescueBurstLastFollowupReasonKey
    private let fameLaunchRescueBurstLastFollowupCommandIDKey = AppDefaults
        .fameLaunchRescueBurstLastFollowupCommandIDKey
    private let fameLaunchRescueBurstLastFollowupAtKey = AppDefaults
        .fameLaunchRescueBurstLastFollowupAtKey
    private let fameLaunchRescueBurstFollowupOutcomeTotalCountKey = AppDefaults
        .fameLaunchRescueBurstFollowupOutcomeTotalCountKey
    private let fameLaunchRescueBurstFollowupOutcomeSuccessCountKey = AppDefaults
        .fameLaunchRescueBurstFollowupOutcomeSuccessCountKey
    private let fameLaunchRescueBurstFollowupOutcomeLastAtKey = AppDefaults
        .fameLaunchRescueBurstFollowupOutcomeLastAtKey
    private let fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey = AppDefaults
        .fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey
    private let fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey = AppDefaults
        .fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey
    private let fameLaunchRescueBurstFollowupOutcomeHistoryKey = AppDefaults
        .fameLaunchRescueBurstFollowupOutcomeHistoryKey
    private let fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey = AppDefaults
        .fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
    private let fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey = AppDefaults
        .fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
    private let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey = AppDefaults
        .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
    private let fameAutoOpsBundleLastRunAtKey = AppDefaults.fameAutoOpsBundleLastRunAtKey
    private let fameOnboardingGapRecoveryLastAtKey = AppDefaults.fameOnboardingGapRecoveryLastAtKey
    private let fameOnboardingGapRecoveryFollowupCommandIDKey = AppDefaults
        .fameOnboardingGapRecoveryFollowupCommandIDKey
    private let fameOnboardingGapRecoveryRemainingArtifactsKey = AppDefaults
        .fameOnboardingGapRecoveryRemainingArtifactsKey
    private let fameCadenceExecutionKitCommandStreakKey = AppDefaults.fameCadenceExecutionKitCommandStreakKey
    private let fameCadenceExecutionKitCommandBestStreakKey = AppDefaults.fameCadenceExecutionKitCommandBestStreakKey
    private let fameExceptionalLoopOutcomeTotalCountKey = AppDefaults
        .fameExceptionalLoopOutcomeTotalCountKey
    private let fameExceptionalLoopOutcomeSuccessCountKey = AppDefaults
        .fameExceptionalLoopOutcomeSuccessCountKey
    private let fameExceptionalLoopOutcomeSuccessStreakKey = AppDefaults
        .fameExceptionalLoopOutcomeSuccessStreakKey
    private let fameExceptionalLoopOutcomeFailureStreakKey = AppDefaults
        .fameExceptionalLoopOutcomeFailureStreakKey
    private let fameExceptionalLoopOutcomeLastFocusTokenKey = AppDefaults
        .fameExceptionalLoopOutcomeLastFocusTokenKey
    private let fameExceptionalLoopOutcomeLastAtKey = AppDefaults
        .fameExceptionalLoopOutcomeLastAtKey
    private let fameExceptionalLoopOutcomeCommandHistoryKey = AppDefaults
        .fameExceptionalLoopOutcomeCommandHistoryKey
    private let fameExceptionalLoopRecoveryLaneAutoRunLastAtKey = AppDefaults
        .fameExceptionalLoopRecoveryLaneAutoRunLastAtKey
    private nonisolated static let fameOnboardingSuiteArtifactCount = 3
    private nonisolated static let launchControlHubArtifactCount = 4
    private nonisolated static let launchRescueAutoFollowupArtifactFreshnessWindow: TimeInterval = 30 * 60
    private nonisolated static let launchRescueAutoSelfHealAttentionMissingGraceWindow: TimeInterval =
        8 * 60
    private nonisolated static let launchRescueAutoSelfHealAttentionNudgeCooldown: TimeInterval = 30 * 60
    private nonisolated static let fameNextMoveRunFirstPrompt = "Run Fame Next Move first."
    private nonisolated static let fameNextMoveRunAgainPrompt = "Run Fame Next Move again."
    private nonisolated static let fameNextMoveMissingHandoffError = "No saved next move handoff yet."
    private nonisolated static let fameNextMoveMissingCadenceStepError = "Latest handoff missing cadence step."
    private nonisolated static let fameNextMoveMissingFirstCadenceChannelError =
        "Latest handoff missing first cadence channel."
    private var fameLaunchRescueBurstAutoCooldown: TimeInterval {
        TimeInterval(max(0, settings.fameLaunchRescueBurstAutoCooldownMinutes) * 60)
    }
    private var fameExceptionalLoopAutoRecoveryLaneMissesRequired: Int {
        AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
    }
    private var fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired: Int {
        AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
            settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        )
    }
    private var fameExceptionalLoopAutoRecoveryLaneCooldown: TimeInterval {
        TimeInterval(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            ) * 60
        )
    }

    private enum FameMenuCommand: Int {
        case copyWinRecap
        case copyLaunchKit
        case copyFameBoard
        case copyFameSprint
        case runFameSprint
        case runFameSprintSnapshot
        case runFameMorningBrief
        case runFameMiddayBrief
        case runFameEveningBrief
        case runFameWeeklyRollup
        case runFame24hQueue
        case runFameCommandCenter
        case runFameBreakthroughForecast
        case runFameOpsBundle
        case runFameDailyCheckpoint
        case runFameDailyScorecard
        case runFameEscalationNudge
        case runFameRecoverySprint
        case runFameRecoveryChecklist
        case runFameRecoveryProofPack
        case runFameRiskTimeline
        case runFameOperatorDashboard
        case runFameNarrativeLab
        case runFameSpotlightPack
        case runFameLaunchDayScript
        case runFameLaunchCountdown
        case runFameLaunchRescueBurst
        case runFameLaunchRescueFollowupNow
        case runFameLaunchControlBrief
        case runFameLaunchControlHub
        case runFameLaunchRescueSnapshot
        case runFamePulseNudge
        case toggleFameLaunchThresholdAlerts
        case snoozeFameLaunchThresholdAlertsRecommended
        case snoozeFameLaunchThresholdAlerts10m
        case snoozeFameLaunchThresholdAlerts30m
        case snoozeFameLaunchThresholdAlerts60m
        case runFameExceptionalLoop
        case runFameExceptionalLoopRecoveryLaneNow
        case runFameNextMoveCopyDraftPack
        case runFameNextMoveCadenceExecutionKit
        case runFameOnboardingDailyBrief
        case runFameOnboardingFillGap
        case runFameOnboardingScorecard
        case runFameOnboardingNudge
        case openLatestRecoverySprint
        case openLatestCommandCenter
        case openLatestNextMoveHandoff
        case openLatestNextMoveDraftPack
        case openLatestOnboardingSuite
        case openLatestOnboardingDailyBrief
        case openLatestOnboardingNudge
        case openLatestOnboardingScorecard
        case copyLatestNextMoveDraftPack
        case copyLatestNextMoveLaunchNowSequence
        case copyLatestNextMoveCadenceExecutionKit
        case copyLatestNextMoveCadencePostQueue
        case copyLatestNextMoveReplyLadder
        case copyLatestNextMoveCadencePost
        case copyLatestNextMoveXDraft
        case copyLatestNextMoveBlueskyDraft
        case copyLatestNextMoveLinkedInDraft
        case copyLatestNextMoveBestChannelLaunchPack
        case copyLatestNextMoveBestChannelDraft
        case copyLatestNextMoveCadenceStep
        case openLatestDailyCheckpoint
        case openLatestRiskTimeline
        case openLatestPulseNudge
        case openLatestDailyScorecard
        case openLatestOperatorDashboard
        case openLatestNarrativeLab
        case openLatestSpotlightPack
        case openLatestLaunchDayScript
        case openLatestLaunchCountdown
        case openLatestLaunchRescueBurst
        case openLatestLaunchRescueSnapshot
        case openLatestLaunchControlBrief
        case openLatestLaunchControlHub
        case copyFameLaunchControlBrief
        case copyFameLaunchRescueSnapshot
        case openLatestBreakthroughForecast
        case openLatestMorningBrief
        case openLatestMiddayBrief
        case openLatestEveningBrief
        case openLatestEscalationNudge
        case openLatestRecoveryChecklist
        case openLatestRecoveryProofPack
        case openFameSnapshotFolder
        case copyFamePack
        case copyFounderCommandPresets
        case copyFameCadenceSharePack
        case saveFamePack
        case copyWinCard
        case copySetupGuide
        case runFameCadenceMomentumBrief
        case runFameCadenceAutopilotLoop
        case runFameCadenceCelebrationDemo
        case openLatestCadenceMomentumBrief
        case openLatestCadenceShareLine
        case openLatestCadenceSharePack
        case openLatestFameExceptionalLoopRecap
        case autoTuneFameExceptionalLoopRecoveryLane
        case resetFameExceptionalLoopTuning
    }

    private enum LaunchControlMenuSlot: Int {
        case launchAlert = 1001
        case launchHealth = 1017
        case launchRecoveryNext = 1018
        case launchRescueAutoStatus = 1002
        case launchThresholdAlerts = 1003
        case launchThresholdAlertsRecommendedSnooze = 1004
        case launchThresholdAlertsSnoozeReminder = 1005
        case launchThresholdAlertsSnooze10m = 1006
        case launchThresholdAlertsSnooze30m = 1007
        case launchThresholdAlertsSnooze60m = 1008
        case separator = 1009
        case runLaunchCountdown = 1010
        case runLaunchRescueBurst = 1011
        case runLaunchRescueFollowupNow = 1019
        case openLatestLaunchCountdown = 1012
        case openLatestLaunchRescueBurst = 1013
        case openLatestLaunchControlBrief = 1014
        case copyLaunchControlBrief = 1015
        case runLaunchControlBrief = 1016
        case copyLaunchRescueSnapshot = 1020
        case openLatestLaunchRescueSnapshot = 1021
        case runLaunchRescueSnapshot = 1022
        case openLatestLaunchControlHub = 1023
        case runLaunchControlHub = 1024
    }

    private enum FameOnboardingRecoveryQuickRunSource: String {
        case onboardingMenu = "onboarding-menu"
        case launchControlMenu = "launch-control-menu"
        case commandPaletteLaunchCard = "command-palette-launch-card"
        case globalHotKey = "global-hotkey"
        case other = "other"

        var shouldShowLaunchRecoveryPulse: Bool {
            switch self {
            case .launchControlMenu, .commandPaletteLaunchCard, .globalHotKey:
                return true
            case .onboardingMenu, .other:
                return false
            }
        }
    }

    private nonisolated static let launchControlMenuSlots: [LaunchControlMenuSlot] = [
        .launchAlert,
        .launchHealth,
        .launchRecoveryNext,
        .launchRescueAutoStatus,
        .launchThresholdAlerts,
        .launchThresholdAlertsRecommendedSnooze,
        .launchThresholdAlertsSnoozeReminder,
        .launchThresholdAlertsSnooze10m,
        .launchThresholdAlertsSnooze30m,
        .launchThresholdAlertsSnooze60m,
        .separator,
        .runLaunchCountdown,
        .runLaunchRescueBurst,
        .runLaunchRescueFollowupNow,
        .runLaunchControlBrief,
        .runLaunchRescueSnapshot,
        .runLaunchControlHub,
        .openLatestLaunchControlHub,
        .openLatestLaunchCountdown,
        .openLatestLaunchRescueBurst,
        .openLatestLaunchRescueSnapshot,
        .openLatestLaunchControlBrief,
        .copyLaunchControlBrief,
        .copyLaunchRescueSnapshot
    ]

    nonisolated static func launchControlMenuSlotTokens() -> [String] {
        launchControlMenuSlots.map(Self.launchControlMenuSlotToken)
    }

    nonisolated static func launchControlMenuTapTelemetryDetails() -> [String] {
        launchControlMenuSlots.compactMap(Self.launchControlMenuTapTelemetryDetail)
    }

    private nonisolated static func launchControlMenuSlotToken(_ slot: LaunchControlMenuSlot) -> String {
        switch slot {
        case .launchAlert:
            return "launch-alert"
        case .launchHealth:
            return "launch-health"
        case .launchRecoveryNext:
            return "launch-recovery-next"
        case .launchRescueAutoStatus:
            return "launch-rescue-auto-status"
        case .launchThresholdAlerts:
            return "launch-threshold-alerts"
        case .launchThresholdAlertsRecommendedSnooze:
            return "launch-threshold-alerts-smart-snooze"
        case .launchThresholdAlertsSnoozeReminder:
            return "launch-threshold-alerts-snooze-reminder"
        case .launchThresholdAlertsSnooze10m:
            return "launch-threshold-alerts-snooze-10m"
        case .launchThresholdAlertsSnooze30m:
            return "launch-threshold-alerts-snooze-30m"
        case .launchThresholdAlertsSnooze60m:
            return "launch-threshold-alerts-snooze-60m"
        case .separator:
            return "separator"
        case .runLaunchCountdown:
            return "run-launch-countdown"
        case .runLaunchRescueBurst:
            return "run-launch-rescue-burst"
        case .runLaunchRescueFollowupNow:
            return "run-launch-rescue-followup-now"
        case .runLaunchControlBrief:
            return "run-launch-control-brief"
        case .runLaunchRescueSnapshot:
            return "run-launch-rescue-snapshot"
        case .runLaunchControlHub:
            return "run-launch-control-hub"
        case .openLatestLaunchControlHub:
            return "open-latest-launch-control-hub"
        case .openLatestLaunchCountdown:
            return "open-latest-launch-countdown"
        case .openLatestLaunchRescueBurst:
            return "open-latest-launch-rescue-burst"
        case .openLatestLaunchRescueSnapshot:
            return "open-latest-launch-rescue-snapshot"
        case .openLatestLaunchControlBrief:
            return "open-latest-launch-control-brief"
        case .copyLaunchControlBrief:
            return "copy-launch-control-brief"
        case .copyLaunchRescueSnapshot:
            return "copy-launch-rescue-snapshot"
        }
    }

    private nonisolated static func launchControlMenuTapTelemetryToken(_ slot: LaunchControlMenuSlot) -> String? {
        switch slot {
        case .separator:
            return nil
        case .launchAlert:
            return "launch-alert"
        case .launchHealth:
            return "launch-health"
        case .launchRecoveryNext:
            return "launch-recovery-next"
        case .launchRescueAutoStatus:
            return "launch-rescue-auto-status"
        case .launchThresholdAlerts:
            return "threshold-alerts-toggle"
        case .launchThresholdAlertsRecommendedSnooze:
            return "threshold-alerts-smart-snooze"
        case .launchThresholdAlertsSnoozeReminder:
            return "threshold-alerts-snooze-reminder"
        case .launchThresholdAlertsSnooze10m:
            return "threshold-alerts-snooze-10m"
        case .launchThresholdAlertsSnooze30m:
            return "threshold-alerts-snooze-30m"
        case .launchThresholdAlertsSnooze60m:
            return "threshold-alerts-snooze-60m"
        case .runLaunchCountdown:
            return "run-launch-countdown"
        case .runLaunchRescueBurst:
            return "run-launch-rescue-burst"
        case .runLaunchRescueFollowupNow:
            return "run-launch-rescue-followup-now"
        case .runLaunchControlBrief:
            return "run-launch-control-brief"
        case .runLaunchRescueSnapshot:
            return "run-launch-rescue-snapshot"
        case .runLaunchControlHub:
            return "run-launch-control-hub"
        case .openLatestLaunchControlHub:
            return "open-latest-launch-control-hub"
        case .openLatestLaunchCountdown:
            return "open-latest-launch-countdown"
        case .openLatestLaunchRescueBurst:
            return "open-latest-launch-rescue-burst"
        case .openLatestLaunchRescueSnapshot:
            return "open-latest-launch-rescue-snapshot"
        case .openLatestLaunchControlBrief:
            return "open-latest-launch-control-brief"
        case .copyLaunchControlBrief:
            return "copy-launch-control-brief"
        case .copyLaunchRescueSnapshot:
            return "copy-launch-rescue-snapshot"
        }
    }

    private nonisolated static func launchControlMenuTapTelemetryDetail(_ slot: LaunchControlMenuSlot) -> String? {
        guard let token = launchControlMenuTapTelemetryToken(slot) else {
            return nil
        }
        return "launch-control-tap-\(token)"
    }

    private nonisolated static func launchControlMenuSlot(forTag tag: Int) -> LaunchControlMenuSlot? {
        LaunchControlMenuSlot(rawValue: tag)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        effects.preloadAllStyles()
        effects.warmAudioPath()
        bindSettings()
        refreshFamePulseBadge()
        startFamePulseBadgeMonitor()
        recordActivity(category: "app", detail: "app-launch-main")
        let result = hotKey.register(
            readAction: { [weak self] in
                Task { @MainActor in
                    self?.startPick()
                }
            },
            screenshotAction: { [weak self] in
                Task { @MainActor in
                    self?.startPick()
                }
            },
            commandAction: { [weak self] in
                Task { @MainActor in
                    self?.commandPalette.toggle()
                }
            },
            launchRecoveryAction: { [weak self] in
                Task { @MainActor in
                    self?.runFameLaunchRecoveryHotKey()
                }
            },
            fameExceptionalLoopAction: { [weak self] in
                Task { @MainActor in
                    self?.runFameExceptionalLoopHotKey()
                }
            }
        )

        if case .failure(let error) = result {
            showHotKeyError(error)
            return
        }
        if hotKey.skippedOptionalHotKeyNames.contains(HotKeyManager.launchRecoveryHotKeyDisplayName) {
            recordActivity(category: "support", detail: Self.launchRecoveryHotKeyBusyActivityDetail())
        }
        fameExceptionalLoopHotKeyAvailable = !hotKey.skippedOptionalHotKeyNames.contains(
            HotKeyManager.fameExceptionalLoopHotKeyDisplayName
        )
        if !fameExceptionalLoopHotKeyAvailable {
            recordActivity(category: "support", detail: Self.fameExceptionalLoopHotKeyBusyActivityDetail())
        }
        updateFameExceptionalLoopMenuStatus()

        let didShowSetupChecklist = firstRunGuide.claimSetupChecklistLaunch()
        if didShowSetupChecklist {
            setupChecklistWindow.show()
        }
        runFameMorningBriefOnLaunch(skipForSetupChecklist: didShowSetupChecklist)
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusFlashTask?.cancel()
        famePulseBadgeTask?.cancel()
        fameLaunchThresholdAlertsCooldownRefreshTask?.cancel()
    }

    private func bindSettings() {
        settings.$soundStyle
            .removeDuplicates()
            .sink { [weak self] style in
                self?.effects.preload(style: style)
                self?.updateStyleMenu()
            }
            .store(in: &cancellables)

        settings.$feelIntensity
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateHitMenu()
            }
            .store(in: &cancellables)

        settings.$fameAutoOpsBundleCooldownMinutes
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateAutoOpsBundleMenuStatus()
            }
            .store(in: &cancellables)

        settings.$fameLaunchRescueBurstAutoCooldownMinutes
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateLaunchRescueAutoMenuStatus()
            }
            .store(in: &cancellables)

        settings.$fameLaunchThresholdAlertsEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    self.setFameLaunchThresholdAlertsSnoozeUntil(nil)
                } else {
                    self.updateFameLaunchThresholdAlertsMenuTitle()
                }
            }
            .store(in: &cancellables)
    }

    private func setupMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        setStatusButton(symbol: statusBaseSymbol, tint: statusBaseTint)
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Commands", action: #selector(showCommandsFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pick and Read", action: #selector(pickFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Reader", action: #selector(showReaderFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Ask Anything", action: #selector(askAnythingFromMenu), keyEquivalent: ""))
        menu.addItem(makeFeelMenuItem())
        menu.addItem(makeFameMenuItem())
        menu.addItem(NSMenuItem(title: "Setup Checklist", action: #selector(setupChecklistFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Stop", action: #selector(stopFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(settingsFromMenu), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitFromMenu), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu
        updateStyleMenu()
        updateHitMenu()
    }

    private func startFamePulseBadgeMonitor() {
        famePulseBadgeTask?.cancel()
        famePulseBadgeTask = Task { [weak self] in
            while !Task.isCancelled {
                await MainActor.run {
                    self?.refreshFamePulseBadge()
                }
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            }
        }
    }

    private func refreshFamePulseBadge(now: Date = Date()) {
        resolveFameLaunchThresholdAlertsSnooze(now: now)
        let signal = famePulseAlertSignal()
        let launchStatus = latestLaunchCountdownStatus()
        let launchUrgency = Self.fameLaunchBadgeUrgency(launchStatus)
        updateFamePulseRiskMenu(signal: signal, now: now)
        if famePulseTransitionPrimed,
           let transition = FameSnapshotRollup.pulseRiskTransition(previous: famePulseLastSignal, next: signal) {
            handleFamePulseRiskTransition(transition, signal: signal)
        }
        if fameLaunchUrgencyTransitionPrimed,
           let transition = Self.fameLaunchUrgencyTransition(
               previous: fameLaunchUrgencyLast,
               next: launchUrgency
           ) {
            handleFameLaunchUrgencyTransition(transition, status: launchStatus)
        }
        if fameLaunchUrgencyTransitionPrimed,
           let transition = Self.launchControlHealthTransition(
               previous: fameLaunchUrgencyLast,
               next: launchUrgency
           ) {
            if incrementLaunchControlHealthTransitionCount(transition, now: now) {
                fameLaunchHealthMenuItem?.title = fameLaunchHealthMenuTitle(now: now)
            }
            handleLaunchControlHealthTransitionPulse(transition, status: launchStatus)
        }
        famePulseLastSignal = signal
        fameLaunchUrgencyLast = launchUrgency
        famePulseTransitionPrimed = true
        fameLaunchUrgencyTransitionPrimed = true
        let healthInsights = launchControlHealthInsights(now: now)
        autoRunFameLaunchRescueBurstForPressurePersistenceIfNeeded(
            launchStatus: launchStatus,
            healthInsights: healthInsights,
            now: now
        )
        let onboardingGapSignal = fameOnboardingGapStatusSignalForStatusBadge(now: now)
        let onboardingGapMissingArtifacts = onboardingGapSignal?.missingArtifacts
        if fameOnboardingGapTransitionPrimed,
           Self.shouldSurfaceFameOnboardingGapPulse(
               previousMissingArtifacts: fameOnboardingGapLastMissingArtifacts,
               nextMissingArtifacts: onboardingGapMissingArtifacts,
               lastPulseAt: fameOnboardingGapPulseLastAt,
               now: now,
               cooldown: fameOnboardingGapPulseCooldown
           ),
           let onboardingGapSignal {
            handleFameOnboardingGapPulse(
                missingArtifacts: onboardingGapSignal.missingArtifacts,
                missingArtifactNames: onboardingGapSignal.missingArtifactNames,
                recommendedCommandID: onboardingGapSignal.recommendedCommandID,
                now: now
            )
        }
        if fameOnboardingGapTransitionPrimed,
           let previousMissingArtifacts = fameOnboardingGapLastMissingArtifacts,
           Self.shouldSurfaceFameOnboardingGapRecoveryPulse(
               previousMissingArtifacts: fameOnboardingGapLastMissingArtifacts,
               nextMissingArtifacts: onboardingGapMissingArtifacts,
               lastRecoveryAt: fameOnboardingGapRecoveryLastAt,
               now: now,
               cooldown: fameOnboardingGapRecoveryCooldown
           ) {
            handleFameOnboardingGapRecovery(
                previousMissingArtifacts: previousMissingArtifacts,
                nextMissingArtifacts: max(0, onboardingGapMissingArtifacts ?? 0),
                nextMissingArtifactNames: onboardingGapSignal?.missingArtifactNames ?? [],
                recommendedCommandID: onboardingGapSignal?.recommendedCommandID,
                now: now
            )
        }
        fameOnboardingGapLastMissingArtifacts = onboardingGapMissingArtifacts
        fameOnboardingGapTransitionPrimed = true
        let nextLevel = Self.fameStatusBadgeLevel(
            pulseSignal: signal,
            launchStatus: launchStatus,
            onboardingGapMissingArtifacts: onboardingGapMissingArtifacts
        )
        let symbol = Self.fameStatusBadgeSymbol(nextLevel)
        let tint = Self.fameStatusBadgeTint(nextLevel)
        guard nextLevel.rawValue != fameStatusBadgeLevel else { return }
        fameStatusBadgeLevel = nextLevel.rawValue
        statusBaseSymbol = symbol
        statusBaseTint = tint
        if statusFlashTask == nil {
            setStatusButton(symbol: symbol, tint: tint)
        }
    }

    private func showHotKeyError(_ error: HotKeyManager.RegistrationError) {
        readerState.errorText = error.localizedDescription
        flashStatus(symbol: "keyboard.badge.ellipsis", tint: .systemRed, length: 0.36)

        let alert = NSAlert()
        alert.messageText = "Keyboard shortcut is busy."
        alert.informativeText = "\(error.localizedDescription) You can still use Pick and Read from the menu bar."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func makeFeelMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Feel", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        submenu.addItem(NSMenuItem(title: "Preview Feel", action: #selector(previewFeelFromMenu), keyEquivalent: ""))
        submenu.addItem(NSMenuItem(title: "Compare Styles", action: #selector(compareStylesFromMenu), keyEquivalent: ""))
        submenu.addItem(NSMenuItem(title: "Big Win Preview", action: #selector(bigWinPreviewFromMenu), keyEquivalent: ""))
        submenu.addItem(NSMenuItem.separator())
        submenu.addItem(makeStyleMenuItem())
        submenu.addItem(makeHitMenuItem())
        submenu.items.forEach { $0.target = self }

        item.submenu = submenu
        return item
    }

    private func makeFameMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Fame", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        fameMenu = submenu
        submenu.delegate = self

        let riskMenuItem = NSMenuItem(
            title: FameSnapshotRollup.pulseRiskMenuTitle(signal: famePulseAlertSignal()),
            action: #selector(runFamePulseRiskActionFromMenu),
            keyEquivalent: ""
        )
        riskMenuItem.target = self
        famePulseRiskMenuItem = riskMenuItem
        submenu.addItem(riskMenuItem)
        let riskDetailMenuItem = NSMenuItem(
            title: FameSnapshotRollup.pulseRiskMenuDetail(signal: famePulseAlertSignal()),
            action: nil,
            keyEquivalent: ""
        )
        riskDetailMenuItem.isEnabled = false
        famePulseRiskDetailMenuItem = riskDetailMenuItem
        submenu.addItem(riskDetailMenuItem)
        let autoOpsBundleStatusMenuItem = NSMenuItem(
            title: autoOpsBundleMenuStatusTitle(),
            action: nil,
            keyEquivalent: ""
        )
        autoOpsBundleStatusMenuItem.isEnabled = false
        autoOpsBundleStatusMenuItem.toolTip = autoOpsBundleMenuStatusToolTip()
        fameAutoOpsBundleStatusMenuItem = autoOpsBundleStatusMenuItem
        submenu.addItem(autoOpsBundleStatusMenuItem)
        let nextMoveMenuItem = NSMenuItem(
            title: fameNextMoveMenuTitle(),
            action: #selector(runFameNextMoveFromMenu),
            keyEquivalent: ""
        )
        nextMoveMenuItem.target = self
        fameNextMoveMenuItem = nextMoveMenuItem
        submenu.addItem(nextMoveMenuItem)
        let onboardingRecoverySnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot()
        let onboardingRecoveryQuickRunActionID = Self.fameOnboardingRecoveryQuickRunActionID(
            isFreshRecovery: onboardingRecoverySnapshot.isFresh,
            followupCommandID: onboardingRecoverySnapshot.followupActionID,
            remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts,
            enabledActionIDs: fameOnboardingRecoveryQuickRunEnabledActionIDs()
        )
        let onboardingRecoveryNextMenuItem = NSMenuItem(
            title: Self.fameOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                actionID: onboardingRecoveryQuickRunActionID,
                remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
            ),
            action: #selector(runFameOnboardingRecoveryNextFromMenu(_:)),
            keyEquivalent: ""
        )
        onboardingRecoveryNextMenuItem.target = self
        onboardingRecoveryNextMenuItem.isEnabled = onboardingRecoveryQuickRunActionID != nil
        onboardingRecoveryNextMenuItem.representedObject = onboardingRecoveryQuickRunActionID
        fameOnboardingRecoveryNextMenuItem = onboardingRecoveryNextMenuItem
        submenu.addItem(onboardingRecoveryNextMenuItem)
        let cadenceMomentumMenuItem = NSMenuItem(
            title: cadenceExecutionKitMenuMomentumTitle(),
            action: nil,
            keyEquivalent: ""
        )
        cadenceMomentumMenuItem.isEnabled = false
        fameCadenceMomentumMenuItem = cadenceMomentumMenuItem
        submenu.addItem(cadenceMomentumMenuItem)
        let exceptionalLoopStatusMenuItem = NSMenuItem(
            title: fameExceptionalLoopMenuStatusTitle(),
            action: nil,
            keyEquivalent: ""
        )
        exceptionalLoopStatusMenuItem.isEnabled = false
        exceptionalLoopStatusMenuItem.toolTip = fameExceptionalLoopMenuStatusToolTip()
        fameExceptionalLoopStatusMenuItem = exceptionalLoopStatusMenuItem
        submenu.addItem(exceptionalLoopStatusMenuItem)
        let exceptionalLoopAutoRecoveryLaneMenuStatus = fameExceptionalLoopAutoRecoveryLaneMenuStatus()
        let exceptionalLoopAutoRecoveryLaneStatusMenuItem = NSMenuItem(
            title: exceptionalLoopAutoRecoveryLaneMenuStatus.title,
            action: nil,
            keyEquivalent: ""
        )
        exceptionalLoopAutoRecoveryLaneStatusMenuItem.isEnabled = false
        exceptionalLoopAutoRecoveryLaneStatusMenuItem.toolTip =
            exceptionalLoopAutoRecoveryLaneMenuStatus.toolTip
        fameExceptionalLoopAutoRecoveryLaneStatusMenuItem =
            exceptionalLoopAutoRecoveryLaneStatusMenuItem
        submenu.addItem(exceptionalLoopAutoRecoveryLaneStatusMenuItem)
        let onboardingGapMenuItem = makeFameMenuItem(
            title: "Fill Onboarding Gap",
            command: .runFameOnboardingFillGap
        )
        fameOnboardingGapMenuItem = onboardingGapMenuItem
        submenu.addItem(onboardingGapMenuItem)
        let onboardingScorecardMenuItem = makeFameMenuItem(
            title: "Run First-Week Fame Scorecard",
            command: .runFameOnboardingScorecard
        )
        fameOnboardingScorecardMenuItem = onboardingScorecardMenuItem
        submenu.addItem(onboardingScorecardMenuItem)
        submenu.addItem(makeFameMenuItem(title: "Run Cadence Autopilot Loop", command: .runFameCadenceAutopilotLoop))
        submenu.addItem(makeFameMenuItem(title: "Run Cadence Momentum Brief", command: .runFameCadenceMomentumBrief))
        submenu.addItem(makeFameMenuItem(title: "Copy Cadence Share Pack", command: .copyFameCadenceSharePack))
        submenu.addItem(makeFameMenuItem(title: "Run Cadence Celebration Demo", command: .runFameCadenceCelebrationDemo))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Exceptional Loop", command: .runFameExceptionalLoop))
        let exceptionalLoopRecoveryLaneMenuStatus = fameExceptionalLoopRecoveryLaneMenuStatus()
        let exceptionalLoopRecoveryLaneMenuItem = makeFameMenuItem(
            title: exceptionalLoopRecoveryLaneMenuStatus.title,
            command: .runFameExceptionalLoopRecoveryLaneNow
        )
        exceptionalLoopRecoveryLaneMenuItem.isEnabled = exceptionalLoopRecoveryLaneMenuStatus.isEnabled
        exceptionalLoopRecoveryLaneMenuItem.toolTip = exceptionalLoopRecoveryLaneMenuStatus.toolTip
        fameExceptionalLoopRecoveryLaneMenuItem = exceptionalLoopRecoveryLaneMenuItem
        submenu.addItem(exceptionalLoopRecoveryLaneMenuItem)
        let exceptionalLoopLatestRecapStatus = fameExceptionalLoopLatestRecapStatus()
        let exceptionalLoopOpenLatestRecapMenuItem = makeFameMenuItem(
            title: exceptionalLoopLatestRecapStatus.title,
            command: .openLatestFameExceptionalLoopRecap
        )
        exceptionalLoopOpenLatestRecapMenuItem.isEnabled = exceptionalLoopLatestRecapStatus.isEnabled
        exceptionalLoopOpenLatestRecapMenuItem.toolTip = exceptionalLoopLatestRecapStatus.toolTip
        fameExceptionalLoopOpenLatestRecapMenuItem = exceptionalLoopOpenLatestRecapMenuItem
        submenu.addItem(exceptionalLoopOpenLatestRecapMenuItem)
        let exceptionalLoopAutoTuneMenuStatus = fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus()
        let exceptionalLoopAutoTuneMenuItem = makeFameMenuItem(
            title: exceptionalLoopAutoTuneMenuStatus.title,
            command: .autoTuneFameExceptionalLoopRecoveryLane
        )
        exceptionalLoopAutoTuneMenuItem.isEnabled = exceptionalLoopAutoTuneMenuStatus.isEnabled
        exceptionalLoopAutoTuneMenuItem.toolTip = exceptionalLoopAutoTuneMenuStatus.toolTip
        fameExceptionalLoopAutoTuneMenuItem = exceptionalLoopAutoTuneMenuItem
        submenu.addItem(exceptionalLoopAutoTuneMenuItem)
        let exceptionalLoopResetTuningStatus = fameExceptionalLoopOutcomeTuningResetStatus()
        let exceptionalLoopResetTuningMenuItem = makeFameMenuItem(
            title: exceptionalLoopResetTuningStatus.title,
            command: .resetFameExceptionalLoopTuning
        )
        exceptionalLoopResetTuningMenuItem.isEnabled = exceptionalLoopResetTuningStatus.isEnabled
        exceptionalLoopResetTuningMenuItem.toolTip = exceptionalLoopResetTuningStatus.toolTip
        fameExceptionalLoopResetTuningMenuItem = exceptionalLoopResetTuningMenuItem
        submenu.addItem(exceptionalLoopResetTuningMenuItem)
        submenu.addItem(makeLaunchControlMenuItem())
        submenu.addItem(makeFameMenuItem(title: "Run Next Move + Copy Draft Pack", command: .runFameNextMoveCopyDraftPack))
        submenu.addItem(makeFameMenuItem(title: "Run Next Move + Cadence Execution Kit", command: .runFameNextMoveCadenceExecutionKit))
        submenu.addItem(NSMenuItem.separator())
        submenu.addItem(makeFameMenuItem(title: "Copy Win Recap", command: .copyWinRecap))
        submenu.addItem(makeFameMenuItem(title: "Copy Launch Kit", command: .copyLaunchKit))
        submenu.addItem(makeFameMenuItem(title: "Copy Fame Board", command: .copyFameBoard))
        submenu.addItem(makeFameMenuItem(title: "Copy Fame Sprint", command: .copyFameSprint))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Sprint", command: .runFameSprint))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Sprint + Save Snapshot", command: .runFameSprintSnapshot))
        submenu.addItem(makeFameMenuItem(title: "Run Morning Fame Brief", command: .runFameMorningBrief))
        submenu.addItem(makeFameMenuItem(title: "Run Midday Fame Brief", command: .runFameMiddayBrief))
        submenu.addItem(makeFameMenuItem(title: "Run Evening Fame Brief", command: .runFameEveningBrief))
        submenu.addItem(makeFameMenuItem(title: "Run Weekly Fame Rollup", command: .runFameWeeklyRollup))
        submenu.addItem(makeFameMenuItem(title: "Run Daily Fame Mission", command: .runFame24hQueue))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Command Center", command: .runFameCommandCenter))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Breakthrough Forecast", command: .runFameBreakthroughForecast))
        submenu.addItem(NSMenuItem(title: "Run Fame War Room", action: #selector(runWarRoom), keyEquivalent: ""))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Ops Bundle", command: .runFameOpsBundle))
        submenu.addItem(makeFameMenuItem(title: "Run Daily Fame Checkpoint", command: .runFameDailyCheckpoint))
        submenu.addItem(makeFameMenuItem(title: "Run Daily Fame Scorecard", command: .runFameDailyScorecard))
        submenu.addItem(makeFameMenuItem(title: "Run First-Week Daily Brief", command: .runFameOnboardingDailyBrief))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Onboarding Nudge", command: .runFameOnboardingNudge))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Escalation Nudge", command: .runFameEscalationNudge))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Recovery Sprint", command: .runFameRecoverySprint))
        submenu.addItem(makeFameMenuItem(title: "Run 2h Recovery Checklist", command: .runFameRecoveryChecklist))
        submenu.addItem(makeFameMenuItem(title: "Run Recovery Proof Pack", command: .runFameRecoveryProofPack))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Risk Timeline", command: .runFameRiskTimeline))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Operator Dashboard", command: .runFameOperatorDashboard))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Narrative Lab", command: .runFameNarrativeLab))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Spotlight Pack", command: .runFameSpotlightPack))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Launch Day Script", command: .runFameLaunchDayScript))
        submenu.addItem(makeFameMenuItem(title: "Run Fame Pulse Nudge", command: .runFamePulseNudge))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Recovery Sprint", command: .openLatestRecoverySprint))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Command Center", command: .openLatestCommandCenter))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Next Move Handoff", command: .openLatestNextMoveHandoff))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Next Move Draft Pack", command: .openLatestNextMoveDraftPack))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Cadence Momentum Brief", command: .openLatestCadenceMomentumBrief))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Cadence Share Line", command: .openLatestCadenceShareLine))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Cadence Share Pack", command: .openLatestCadenceSharePack))
        submenu.addItem(makeFameMenuItem(title: "Copy Latest Draft Pack", command: .copyLatestNextMoveDraftPack))
        submenu.addItem(makeFameMenuItem(title: "Copy Launch Now Sequence", command: .copyLatestNextMoveLaunchNowSequence))
        submenu.addItem(makeFameMenuItem(title: "Copy Cadence Execution Kit", command: .copyLatestNextMoveCadenceExecutionKit))
        submenu.addItem(makeFameMenuItem(title: "Copy Post Cadence + Queue", command: .copyLatestNextMoveCadencePostQueue))
        submenu.addItem(makeFameMenuItem(title: "Copy Next-Move Reply Ladder", command: .copyLatestNextMoveReplyLadder))
        submenu.addItem(makeFameMenuItem(title: "Copy Post Cadence Now", command: .copyLatestNextMoveCadencePost))
        submenu.addItem(makeFameMenuItem(title: "Copy Latest X Draft", command: .copyLatestNextMoveXDraft))
        submenu.addItem(makeFameMenuItem(title: "Copy Latest Bluesky Draft", command: .copyLatestNextMoveBlueskyDraft))
        submenu.addItem(makeFameMenuItem(title: "Copy Latest LinkedIn Draft", command: .copyLatestNextMoveLinkedInDraft))
        let launchPackModeTransitionCount = max(
            0,
            UserDefaults.standard.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey
            )
        )
        let launchPackModeTransitionLatest = UserDefaults.standard.string(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey
        )
        let launchPackModeMomentumStreak = UserDefaults.standard.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let bestChannelLaunchPackMenuItem = makeFameMenuItem(
            title: Self.bestChannelLaunchPackMenuTitle(
                transitionCount: launchPackModeTransitionCount,
                latestToken: launchPackModeTransitionLatest,
                momentumStreak: launchPackModeMomentumStreak
            ),
            command: .copyLatestNextMoveBestChannelLaunchPack
        )
        bestChannelLaunchPackMenuItem.toolTip = Self.bestChannelLaunchPackMenuToolTip(
            transitionCount: launchPackModeTransitionCount,
            latestToken: launchPackModeTransitionLatest,
            momentumStreak: launchPackModeMomentumStreak
        )
        fameBestChannelLaunchPackMenuItem = bestChannelLaunchPackMenuItem
        submenu.addItem(bestChannelLaunchPackMenuItem)
        let bestChannelDraftMenuItem = makeFameMenuItem(
            title: Self.bestChannelDraftMenuTitle(
                transitionCount: launchPackModeTransitionCount,
                latestToken: launchPackModeTransitionLatest,
                momentumStreak: launchPackModeMomentumStreak
            ),
            command: .copyLatestNextMoveBestChannelDraft
        )
        bestChannelDraftMenuItem.toolTip = Self.bestChannelDraftMenuToolTip(
            transitionCount: launchPackModeTransitionCount,
            latestToken: launchPackModeTransitionLatest,
            momentumStreak: launchPackModeMomentumStreak
        )
        fameBestChannelDraftMenuItem = bestChannelDraftMenuItem
        submenu.addItem(bestChannelDraftMenuItem)
        submenu.addItem(makeFameMenuItem(title: "Copy First Cadence Step", command: .copyLatestNextMoveCadenceStep))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Daily Checkpoint", command: .openLatestDailyCheckpoint))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Risk Timeline", command: .openLatestRiskTimeline))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Pulse Nudge", command: .openLatestPulseNudge))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Daily Scorecard", command: .openLatestDailyScorecard))
        submenu.addItem(makeFameMenuItem(title: "Open First-Week Onboarding Hub", command: .openLatestOnboardingSuite))
        submenu.addItem(makeFameMenuItem(title: "Open Latest First-Week Daily Brief", command: .openLatestOnboardingDailyBrief))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Fame Onboarding Nudge", command: .openLatestOnboardingNudge))
        submenu.addItem(makeFameMenuItem(title: "Open Latest First-Week Fame Scorecard", command: .openLatestOnboardingScorecard))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Operator Dashboard", command: .openLatestOperatorDashboard))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Narrative Lab", command: .openLatestNarrativeLab))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Spotlight Pack", command: .openLatestSpotlightPack))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Launch Day Script", command: .openLatestLaunchDayScript))
        let openLaunchControlHubMenuItem = makeFameMenuItem(
            title: launchControlHubOpenMenuStatusTitle(),
            command: .openLatestLaunchControlHub
        )
        openLaunchControlHubMenuItem.toolTip = launchControlHubOpenMenuStatusToolTip()
        fameOpenLatestLaunchControlHubMenuItem = openLaunchControlHubMenuItem
        submenu.addItem(openLaunchControlHubMenuItem)
        let openLaunchRescueSnapshotMenuItem = makeFameMenuItem(
            title: launchRescueSnapshotOpenMenuStatusTitle(),
            command: .openLatestLaunchRescueSnapshot
        )
        openLaunchRescueSnapshotMenuItem.toolTip = launchRescueSnapshotOpenMenuStatusToolTip()
        fameOpenLatestLaunchRescueSnapshotMenuItem = openLaunchRescueSnapshotMenuItem
        submenu.addItem(openLaunchRescueSnapshotMenuItem)
        submenu.addItem(makeFameMenuItem(title: "Open Latest Breakthrough Forecast", command: .openLatestBreakthroughForecast))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Morning Brief", command: .openLatestMorningBrief))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Midday Brief", command: .openLatestMiddayBrief))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Evening Brief", command: .openLatestEveningBrief))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Escalation Nudge", command: .openLatestEscalationNudge))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Recovery Checklist", command: .openLatestRecoveryChecklist))
        submenu.addItem(makeFameMenuItem(title: "Open Latest Recovery Proof Pack", command: .openLatestRecoveryProofPack))
        submenu.addItem(makeFameMenuItem(title: "Open Fame Snapshot Folder", command: .openFameSnapshotFolder))
        submenu.addItem(makeFameMenuItem(title: "Copy Fame Pack", command: .copyFamePack))
        submenu.addItem(makeFameMenuItem(title: "Copy Founder Presets", command: .copyFounderCommandPresets))
        submenu.addItem(makeFameMenuItem(title: "Save Fame Pack", command: .saveFamePack))
        submenu.addItem(makeFameMenuItem(title: "Copy Win Card Image", command: .copyWinCard))
        submenu.addItem(makeFameMenuItem(title: "Copy Setup Guide", command: .copySetupGuide))
        submenu.items.forEach { $0.target = self }
        updateFameOnboardingScorecardMenuStatus()

        item.submenu = submenu
        return item
    }

    private func makeLaunchControlMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Launch Control", action: nil, keyEquivalent: "")
        let submenu = NSMenu()

        for slot in Self.launchControlMenuSlots {
            switch slot {
            case .launchAlert:
                let launchAlertMenuItem = NSMenuItem(
                    title: fameLaunchAlertMenuTitle(),
                    action: #selector(runFameLaunchAlertFromMenu(_:)),
                    keyEquivalent: ""
                )
                launchAlertMenuItem.tag = slot.rawValue
                launchAlertMenuItem.target = self
                fameLaunchAlertMenuItem = launchAlertMenuItem
                submenu.addItem(launchAlertMenuItem)
            case .launchHealth:
                let launchHealthMenuItem = NSMenuItem(
                    title: fameLaunchHealthMenuTitle(),
                    action: #selector(runFameLaunchHealthFromMenu(_:)),
                    keyEquivalent: ""
                )
                launchHealthMenuItem.tag = slot.rawValue
                launchHealthMenuItem.target = self
                fameLaunchHealthMenuItem = launchHealthMenuItem
                submenu.addItem(launchHealthMenuItem)
            case .launchRecoveryNext:
                let onboardingRecoverySnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot()
                let onboardingRecoveryQuickRunActionID = Self.fameOnboardingRecoveryQuickRunActionID(
                    isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                    followupCommandID: onboardingRecoverySnapshot.followupActionID,
                    remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts,
                    enabledActionIDs: fameOnboardingRecoveryQuickRunEnabledActionIDs()
                )
                let launchRecoveryNextMenuItem = NSMenuItem(
                    title: Self.launchControlOnboardingRecoveryQuickRunMenuTitle(
                        isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                        actionID: onboardingRecoveryQuickRunActionID,
                        remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
                    ),
                    action: #selector(runFameLaunchRecoveryNextFromMenu(_:)),
                    keyEquivalent: ""
                )
                launchRecoveryNextMenuItem.tag = slot.rawValue
                launchRecoveryNextMenuItem.target = self
                launchRecoveryNextMenuItem.isEnabled = onboardingRecoveryQuickRunActionID != nil
                launchRecoveryNextMenuItem.representedObject = onboardingRecoveryQuickRunActionID
                launchRecoveryNextMenuItem.toolTip = Self.launchControlOnboardingRecoveryQuickRunMenuToolTip(
                    isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                    actionID: onboardingRecoveryQuickRunActionID
                )
                fameLaunchRecoveryNextMenuItem = launchRecoveryNextMenuItem
                submenu.addItem(launchRecoveryNextMenuItem)
            case .launchRescueAutoStatus:
                let launchRescueAutoStatusMenuItem = NSMenuItem(
                    title: launchRescueAutoMenuStatusTitle(),
                    action: #selector(runFameLaunchRescueAutoStatusFromMenu(_:)),
                    keyEquivalent: ""
                )
                launchRescueAutoStatusMenuItem.tag = slot.rawValue
                launchRescueAutoStatusMenuItem.target = self
                launchRescueAutoStatusMenuItem.toolTip = launchRescueAutoMenuStatusToolTip()
                fameLaunchRescueAutoStatusMenuItem = launchRescueAutoStatusMenuItem
                submenu.addItem(launchRescueAutoStatusMenuItem)
            case .launchThresholdAlerts:
                let launchThresholdAlertsMenuItem = makeLaunchControlFameMenuItem(
                    title: fameLaunchThresholdAlertsMenuTitle(),
                    command: .toggleFameLaunchThresholdAlerts,
                    slot: slot
                )
                fameLaunchThresholdAlertsMenuItem = launchThresholdAlertsMenuItem
                submenu.addItem(launchThresholdAlertsMenuItem)
            case .launchThresholdAlertsRecommendedSnooze:
                let launchThresholdAlertsRecommendedSnoozeMenuItem = makeLaunchControlFameMenuItem(
                    title: fameLaunchThresholdAlertsRecommendedSnoozeMenuTitle(),
                    command: .snoozeFameLaunchThresholdAlertsRecommended,
                    slot: slot
                )
                fameLaunchThresholdAlertsRecommendedSnoozeMenuItem = launchThresholdAlertsRecommendedSnoozeMenuItem
                submenu.addItem(launchThresholdAlertsRecommendedSnoozeMenuItem)
            case .launchThresholdAlertsSnoozeReminder:
                let launchThresholdAlertsSnoozeReminderMenuItem = NSMenuItem(
                    title: fameLaunchThresholdAlertsSnoozeReminderMenuTitle(),
                    action: #selector(openFameLaunchThresholdAlertsSnoozeReminderFromMenu(_:)),
                    keyEquivalent: ""
                )
                let launchThresholdAlertsSnoozeReminderTapAction = fameLaunchThresholdAlertsSnoozeReminderMenuTapAction()
                launchThresholdAlertsSnoozeReminderMenuItem.isEnabled =
                    Self.canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(
                        launchThresholdAlertsSnoozeReminderTapAction
                    )
                    && fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
                        tapAction: launchThresholdAlertsSnoozeReminderTapAction
                    ) == nil
                launchThresholdAlertsSnoozeReminderMenuItem.tag = slot.rawValue
                fameLaunchThresholdAlertsSnoozeReminderMenuItem = launchThresholdAlertsSnoozeReminderMenuItem
                submenu.addItem(launchThresholdAlertsSnoozeReminderMenuItem)
            case .launchThresholdAlertsSnooze10m:
                submenu.addItem(
                    makeLaunchControlFameMenuItem(
                        title: "Snooze Threshold Alerts (10m)",
                        command: .snoozeFameLaunchThresholdAlerts10m,
                        slot: slot
                    )
                )
            case .launchThresholdAlertsSnooze30m:
                submenu.addItem(
                    makeLaunchControlFameMenuItem(
                        title: "Snooze Threshold Alerts (30m)",
                        command: .snoozeFameLaunchThresholdAlerts30m,
                        slot: slot
                    )
                )
            case .launchThresholdAlertsSnooze60m:
                submenu.addItem(
                    makeLaunchControlFameMenuItem(
                        title: "Snooze Threshold Alerts (60m)",
                        command: .snoozeFameLaunchThresholdAlerts60m,
                        slot: slot
                    )
                )
            case .separator:
                submenu.addItem(NSMenuItem.separator())
            case .runLaunchCountdown:
                let launchCountdownRunMenuItem = makeLaunchControlFameMenuItem(
                    title: launchCountdownRunMenuStatusTitle(),
                    command: .runFameLaunchCountdown,
                    slot: slot
                )
                launchCountdownRunMenuItem.toolTip = launchCountdownRunMenuStatusToolTip()
                fameLaunchCountdownRunMenuItem = launchCountdownRunMenuItem
                submenu.addItem(launchCountdownRunMenuItem)
            case .runLaunchRescueBurst:
                let launchRescueBurstRunMenuItem = makeLaunchControlFameMenuItem(
                    title: launchRescueBurstRunMenuStatusTitle(),
                    command: .runFameLaunchRescueBurst,
                    slot: slot
                )
                launchRescueBurstRunMenuItem.toolTip = launchRescueBurstRunMenuStatusToolTip()
                fameLaunchRescueBurstRunMenuItem = launchRescueBurstRunMenuItem
                submenu.addItem(launchRescueBurstRunMenuItem)
            case .runLaunchRescueFollowupNow:
                let launchRescueFollowupNowMenuItem = makeLaunchControlFameMenuItem(
                    title: launchRescueFollowupNowMenuStatusTitle(),
                    command: .runFameLaunchRescueFollowupNow,
                    slot: slot
                )
                launchRescueFollowupNowMenuItem.toolTip = launchRescueFollowupNowMenuStatusToolTip()
                fameLaunchRescueFollowupNowMenuItem = launchRescueFollowupNowMenuItem
                submenu.addItem(launchRescueFollowupNowMenuItem)
            case .runLaunchControlBrief:
                let launchControlBriefRunMenuItem = makeLaunchControlFameMenuItem(
                    title: launchControlBriefRunMenuStatusTitle(),
                    command: .runFameLaunchControlBrief,
                    slot: slot
                )
                launchControlBriefRunMenuItem.toolTip = launchControlBriefRunMenuStatusToolTip()
                fameLaunchControlBriefRunMenuItem = launchControlBriefRunMenuItem
                submenu.addItem(launchControlBriefRunMenuItem)
            case .runLaunchRescueSnapshot:
                submenu.addItem(
                    makeLaunchControlFameMenuItem(
                        title: "Run Launch Rescue Snapshot",
                        command: .runFameLaunchRescueSnapshot,
                        slot: slot
                    )
                )
            case .runLaunchControlHub:
                let launchControlHubRunMenuItem = makeLaunchControlFameMenuItem(
                    title: launchControlHubRunMenuStatusTitle(),
                    command: .runFameLaunchControlHub,
                    slot: slot
                )
                launchControlHubRunMenuItem.toolTip = launchControlHubRunMenuStatusToolTip()
                fameLaunchControlHubRunMenuItem = launchControlHubRunMenuItem
                submenu.addItem(launchControlHubRunMenuItem)
            case .openLatestLaunchControlHub:
                let launchControlHubOpenMenuItem = makeLaunchControlFameMenuItem(
                    title: launchControlHubOpenMenuStatusTitle(),
                    command: .openLatestLaunchControlHub,
                    slot: slot
                )
                launchControlHubOpenMenuItem.toolTip = launchControlHubOpenMenuStatusToolTip()
                fameLaunchControlHubOpenMenuItem = launchControlHubOpenMenuItem
                submenu.addItem(launchControlHubOpenMenuItem)
            case .openLatestLaunchCountdown:
                let launchCountdownOpenMenuItem = makeLaunchControlFameMenuItem(
                    title: launchCountdownOpenMenuStatusTitle(),
                    command: .openLatestLaunchCountdown,
                    slot: slot
                )
                launchCountdownOpenMenuItem.toolTip = launchCountdownOpenMenuStatusToolTip()
                fameLaunchCountdownOpenMenuItem = launchCountdownOpenMenuItem
                submenu.addItem(launchCountdownOpenMenuItem)
            case .openLatestLaunchRescueBurst:
                let launchRescueBurstOpenMenuItem = makeLaunchControlFameMenuItem(
                    title: launchRescueBurstOpenMenuStatusTitle(),
                    command: .openLatestLaunchRescueBurst,
                    slot: slot
                )
                launchRescueBurstOpenMenuItem.toolTip = launchRescueBurstOpenMenuStatusToolTip()
                fameLaunchRescueBurstOpenMenuItem = launchRescueBurstOpenMenuItem
                submenu.addItem(launchRescueBurstOpenMenuItem)
            case .openLatestLaunchRescueSnapshot:
                let launchRescueSnapshotOpenMenuItem = makeLaunchControlFameMenuItem(
                    title: launchRescueSnapshotOpenMenuStatusTitle(),
                    command: .openLatestLaunchRescueSnapshot,
                    slot: slot
                )
                launchRescueSnapshotOpenMenuItem.toolTip = launchRescueSnapshotOpenMenuStatusToolTip()
                fameLaunchRescueSnapshotOpenMenuItem = launchRescueSnapshotOpenMenuItem
                submenu.addItem(launchRescueSnapshotOpenMenuItem)
            case .openLatestLaunchControlBrief:
                let launchControlBriefOpenMenuItem = makeLaunchControlFameMenuItem(
                    title: launchControlBriefOpenMenuStatusTitle(),
                    command: .openLatestLaunchControlBrief,
                    slot: slot
                )
                launchControlBriefOpenMenuItem.toolTip = launchControlBriefOpenMenuStatusToolTip()
                fameLaunchControlBriefOpenMenuItem = launchControlBriefOpenMenuItem
                submenu.addItem(launchControlBriefOpenMenuItem)
            case .copyLaunchControlBrief:
                let launchControlBriefCopyMenuItem = makeLaunchControlFameMenuItem(
                    title: launchControlBriefCopyMenuStatusTitle(),
                    command: .copyFameLaunchControlBrief,
                    slot: slot
                )
                launchControlBriefCopyMenuItem.toolTip = launchControlBriefCopyMenuStatusToolTip()
                fameLaunchControlBriefCopyMenuItem = launchControlBriefCopyMenuItem
                submenu.addItem(launchControlBriefCopyMenuItem)
            case .copyLaunchRescueSnapshot:
                let launchRescueSnapshotMenuItem = makeLaunchControlFameMenuItem(
                    title: launchRescueSnapshotMenuTitle(),
                    command: .copyFameLaunchRescueSnapshot,
                    slot: slot
                )
                launchRescueSnapshotMenuItem.toolTip = launchRescueSnapshotCopyMenuStatusToolTip()
                fameLaunchRescueSnapshotMenuItem = launchRescueSnapshotMenuItem
                submenu.addItem(launchRescueSnapshotMenuItem)
            }
        }

        submenu.items.forEach { $0.target = self }
        item.submenu = submenu
        return item
    }

    private func makeLaunchControlFameMenuItem(
        title: String,
        command: FameMenuCommand,
        slot: LaunchControlMenuSlot
    ) -> NSMenuItem {
        let item = makeFameMenuItem(title: title, command: command)
        item.tag = slot.rawValue
        return item
    }

    private func makeFameMenuItem(title: String, command: FameMenuCommand) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(runFameMenuCommandFromMenu(_:)), keyEquivalent: "")
        item.representedObject = NSNumber(value: command.rawValue)
        return item
    }

    private func recordLaunchControlTapIfNeeded(_ sender: NSMenuItem) {
        guard let slot = Self.launchControlMenuSlot(forTag: sender.tag),
              let detail = Self.launchControlMenuTapTelemetryDetail(slot) else {
            return
        }
        recordActivity(category: "support", detail: detail)
    }

    @objc private func runFameMenuCommandFromMenu(_ sender: NSMenuItem) {
        guard let rawValue = (sender.representedObject as? NSNumber)?.intValue,
              let command = FameMenuCommand(rawValue: rawValue) else { return }
        recordLaunchControlTapIfNeeded(sender)
        switch command {
        case .copyWinRecap:
            copyWinRecap()
        case .copyLaunchKit:
            copyLaunchKit()
        case .copyFameBoard:
            copyFameBoard()
        case .copyFameSprint:
            copyFameSprint()
        case .runFameSprint:
            runFameSprint()
        case .runFameSprintSnapshot:
            runFameSprintSnapshot()
        case .runFameMorningBrief:
            runFameMorningBrief()
        case .runFameMiddayBrief:
            runFameMiddayBrief()
        case .runFameEveningBrief:
            runFameEveningBrief()
        case .runFameWeeklyRollup:
            runFameWeeklyRollup()
        case .runFame24hQueue:
            runFame24hQueue()
        case .runFameCommandCenter:
            runFameCommandCenter()
        case .runFameBreakthroughForecast:
            runFameBreakthroughForecast()
        case .runFameOpsBundle:
            runFameOpsBundle()
        case .runFameDailyCheckpoint:
            runFameDailyCheckpoint()
        case .runFameDailyScorecard:
            runFameDailyScorecard()
        case .runFameEscalationNudge:
            runFameEscalationNudge()
        case .runFameRecoverySprint:
            runFameRecoverySprint()
        case .runFameRecoveryChecklist:
            runFameRecoveryChecklist()
        case .runFameRecoveryProofPack:
            runFameRecoveryProofPack()
        case .runFameRiskTimeline:
            runFameRiskTimeline()
        case .runFameOperatorDashboard:
            runFameOperatorDashboard()
        case .runFameNarrativeLab:
            runFameNarrativeLab()
        case .runFameSpotlightPack:
            runFameSpotlightPack()
        case .runFameLaunchDayScript:
            runFameLaunchDayScript()
        case .runFameLaunchCountdown:
            runFameLaunchCountdown()
        case .runFameLaunchRescueBurst:
            runFameLaunchRescueBurst()
        case .runFameLaunchRescueFollowupNow:
            runFameLaunchRescueFollowupNow()
        case .runFameLaunchControlBrief:
            runFameLaunchControlBrief()
        case .runFameLaunchControlHub:
            runFameLaunchControlHub()
        case .runFameLaunchRescueSnapshot:
            runFameLaunchRescueSnapshot()
        case .runFamePulseNudge:
            runFamePulseNudge()
        case .toggleFameLaunchThresholdAlerts:
            toggleFameLaunchThresholdAlerts(source: "menu")
        case .snoozeFameLaunchThresholdAlertsRecommended:
            snoozeFameLaunchThresholdAlerts(
                minutes: fameLaunchThresholdAlertsRecommendedSnoozeMinutes(),
                source: "menu-recommended"
            )
        case .snoozeFameLaunchThresholdAlerts10m:
            snoozeFameLaunchThresholdAlerts(minutes: 10, source: "menu")
        case .snoozeFameLaunchThresholdAlerts30m:
            snoozeFameLaunchThresholdAlerts(minutes: 30, source: "menu")
        case .snoozeFameLaunchThresholdAlerts60m:
            snoozeFameLaunchThresholdAlerts(minutes: 60, source: "menu")
        case .runFameExceptionalLoop:
            runFameExceptionalLoop()
        case .runFameExceptionalLoopRecoveryLaneNow:
            runFameExceptionalLoopRecoveryLaneNow()
        case .openLatestFameExceptionalLoopRecap:
            openLatestFameExceptionalLoopRecap()
        case .autoTuneFameExceptionalLoopRecoveryLane:
            runFameExceptionalLoopAutoRecoveryLaneAutoTune()
        case .resetFameExceptionalLoopTuning:
            resetFameExceptionalLoopOutcomeTuningFromCommand()
        case .runFameNextMoveCopyDraftPack:
            runFameNextMove(followup: .copyDraftPack)
        case .runFameNextMoveCadenceExecutionKit:
            runFameNextMove(followup: .cadenceExecutionKit)
        case .runFameOnboardingDailyBrief:
            recordCommandAction("run-fame-onboarding-daily-brief")
            runFameOnboardingDailyBrief()
        case .runFameOnboardingFillGap:
            recordCommandAction("run-fame-onboarding-fill-gap")
            runFameOnboardingFillGap()
        case .runFameOnboardingScorecard:
            recordCommandAction("run-fame-onboarding-scorecard")
            runFameOnboardingScorecard()
        case .runFameOnboardingNudge:
            recordCommandAction("run-fame-onboarding-nudge")
            runFameOnboardingNudge()
        case .runFameCadenceMomentumBrief:
            runFameCadenceMomentumBrief()
        case .copyFameCadenceSharePack:
            copyFameCadenceSharePack()
        case .runFameCadenceAutopilotLoop:
            recordCommandAction("run-fame-cadence-autopilot-loop")
            runFameCadenceAutopilotLoop()
        case .runFameCadenceCelebrationDemo:
            runCadenceCelebrationDemo()
        case .openLatestRecoverySprint:
            openLatestRecoverySprint()
        case .openLatestCommandCenter:
            openLatestCommandCenter()
        case .openLatestNextMoveHandoff:
            openLatestNextMoveHandoff()
        case .openLatestNextMoveDraftPack:
            openLatestNextMoveDraftPack()
        case .openLatestCadenceMomentumBrief:
            openLatestCadenceMomentumBrief()
        case .openLatestCadenceShareLine:
            openLatestCadenceShareLine()
        case .openLatestCadenceSharePack:
            openLatestCadenceSharePack()
        case .openLatestOnboardingSuite:
            openLatestOnboardingSuite()
        case .openLatestOnboardingDailyBrief:
            openLatestOnboardingDailyBrief()
        case .openLatestOnboardingNudge:
            openLatestOnboardingNudge()
        case .openLatestOnboardingScorecard:
            openLatestOnboardingScorecard()
        case .copyLatestNextMoveDraftPack:
            copyLatestNextMoveDraftPack()
        case .copyLatestNextMoveLaunchNowSequence:
            copyLatestNextMoveLaunchNowSequence()
        case .copyLatestNextMoveCadenceExecutionKit:
            copyLatestNextMoveCadenceExecutionKit()
        case .copyLatestNextMoveCadencePostQueue:
            copyLatestNextMoveCadencePostQueue()
        case .copyLatestNextMoveReplyLadder:
            copyLatestNextMoveReplyLadder()
        case .copyLatestNextMoveCadencePost:
            copyLatestNextMoveCadencePost()
        case .copyLatestNextMoveXDraft:
            copyLatestNextMoveChannelDraft(.x)
        case .copyLatestNextMoveBlueskyDraft:
            copyLatestNextMoveChannelDraft(.bluesky)
        case .copyLatestNextMoveLinkedInDraft:
            copyLatestNextMoveChannelDraft(.linkedIn)
        case .copyLatestNextMoveBestChannelLaunchPack:
            copyLatestNextMoveBestChannelLaunchPack()
        case .copyLatestNextMoveBestChannelDraft:
            copyLatestNextMoveBestChannelDraft()
        case .copyLatestNextMoveCadenceStep:
            copyLatestNextMoveCadenceStep()
        case .openLatestDailyCheckpoint:
            openLatestDailyCheckpoint()
        case .openLatestRiskTimeline:
            openLatestRiskTimeline()
        case .openLatestPulseNudge:
            openLatestPulseNudge()
        case .openLatestDailyScorecard:
            openLatestDailyScorecard()
        case .openLatestOperatorDashboard:
            openLatestOperatorDashboard()
        case .openLatestNarrativeLab:
            openLatestNarrativeLab()
        case .openLatestSpotlightPack:
            openLatestSpotlightPack()
        case .openLatestLaunchDayScript:
            openLatestLaunchDayScript()
        case .openLatestLaunchCountdown:
            openLatestLaunchCountdown()
        case .openLatestLaunchRescueBurst:
            openLatestLaunchRescueBurst()
        case .openLatestLaunchRescueSnapshot:
            openLatestLaunchRescueSnapshot()
        case .openLatestLaunchControlBrief:
            openLatestLaunchControlBrief()
        case .openLatestLaunchControlHub:
            openLatestLaunchControlHub()
        case .copyFameLaunchControlBrief:
            copyFameLaunchControlBrief()
        case .copyFameLaunchRescueSnapshot:
            copyFameLaunchRescueSnapshot()
        case .openLatestBreakthroughForecast:
            openLatestBreakthroughForecast()
        case .openLatestMorningBrief:
            openLatestMorningBrief()
        case .openLatestMiddayBrief:
            openLatestMiddayBrief()
        case .openLatestEveningBrief:
            openLatestEveningBrief()
        case .openLatestEscalationNudge:
            openLatestEscalationNudge()
        case .openLatestRecoveryChecklist:
            openLatestRecoveryChecklist()
        case .openLatestRecoveryProofPack:
            openLatestRecoveryProofPack()
        case .openFameSnapshotFolder:
            openFameSnapshotFolder()
        case .copyFamePack:
            copyFamePack()
        case .copyFounderCommandPresets:
            copyFounderCommandPresets()
        case .saveFamePack:
            saveFamePack()
        case .copyWinCard:
            copyWinCard()
        case .copySetupGuide:
            copySetupGuide()
        }
    }

    private func makeStyleMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Sound Style", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let styles = EffectsService.availableStyles.map { ($0.capitalized, $0) }

        for (title, style) in styles {
            let styleItem = NSMenuItem(title: title, action: #selector(styleFromMenu(_:)), keyEquivalent: "")
            styleItem.target = self
            styleItem.representedObject = style
            submenu.addItem(styleItem)
            styleMenuItems[style] = styleItem
        }

        item.submenu = submenu
        return item
    }

    private func makeHitMenuItem() -> NSMenuItem {
        let item = NSMenuItem(title: "Hit Level", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        let levels = [
            ("Calm", 0.45),
            ("Bright", 0.84),
            ("Max", 1.00)
        ]

        for (title, level) in levels {
            let levelItem = NSMenuItem(title: title, action: #selector(hitLevelFromMenu(_:)), keyEquivalent: "")
            levelItem.target = self
            levelItem.representedObject = level
            submenu.addItem(levelItem)
            hitMenuItems[level] = levelItem
        }

        item.submenu = submenu
        return item
    }

    @objc private func pickFromMenu() {
        effects.play(.tap, settings: settings)
        startPick()
    }

    @objc private func showReaderFromMenu() {
        effects.play(.tap, settings: settings)
        readerWindow.show()
    }

    @objc private func showCommandsFromMenu() {
        effects.play(.tap, settings: settings)
        commandPalette.toggle()
    }

    @objc private func askAnythingFromMenu() {
        effects.play(.tap, settings: settings)
        askAnything()
    }

    @objc private func setupChecklistFromMenu() {
        effects.play(.tap, settings: settings)
        setupChecklistWindow.show()
        recordActivity(category: "setup", detail: "open-setup-checklist")
    }

    @objc private func settingsFromMenu() {
        effects.play(.tap, settings: settings)
        settingsWindow.show()
    }

    @objc private func previewFeelFromMenu() {
        previewFeelFlow()
    }

    @objc private func compareStylesFromMenu() {
        compareStylePreviews()
    }

    @objc private func bigWinPreviewFromMenu() {
        cancelPreviewFlow()
        settings.soundStyle = "jackpot"
        settings.feelIntensity = 1.0
        effects.preload(style: settings.soundStyle)
        updateStyleMenu()
        updateHitMenu()
        previewFeelFlow()
    }

    @objc private func styleFromMenu(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? String else { return }
        settings.soundStyle = style
        effects.preload(style: style)
        updateStyleMenu()
        effects.play(.tap, settings: settings)
    }

    @objc private func hitLevelFromMenu(_ sender: NSMenuItem) {
        guard let level = sender.representedObject as? Double else { return }
        settings.feelIntensity = level
        updateHitMenu()
        effects.play(.tap, settings: settings)
    }

    @objc private func stopFromMenu() {
        effects.play(.tap, settings: settings)
        stopSpeech()
    }

    @objc private func quitFromMenu() {
        NSApp.terminate(nil)
    }

    @objc private func runFameNextMoveFromMenu() {
        runFameNextMove()
    }

    @objc private func runFameOnboardingRecoveryNextFromMenu(_ sender: NSMenuItem) {
        let now = Date()
        let snapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        let actionID = (sender.representedObject as? String) ?? Self.fameOnboardingRecoveryQuickRunActionID(
            isFreshRecovery: snapshot.isFresh,
            followupCommandID: snapshot.followupActionID,
            remainingArtifacts: snapshot.remainingArtifacts,
            enabledActionIDs: fameOnboardingRecoveryQuickRunEnabledActionIDs(now: now)
        )

        guard let actionID else {
            readerState.petSay("No onboarding recovery quick run is active yet.", mood: .ready)
            readerState.pulse()
            recordActivity(category: "support", detail: "run-fame-onboarding-recovery-next-unavailable")
            return
        }

        runFameOnboardingRecoveryQuickRun(actionID: actionID, source: .onboardingMenu, now: now)
    }

    @objc private func runFameLaunchAlertFromMenu(_ sender: NSMenuItem) {
        recordLaunchControlTapIfNeeded(sender)
        runFameLaunchCountdown()
    }

    @objc private func runFameLaunchHealthFromMenu(_ sender: NSMenuItem) {
        recordLaunchControlTapIfNeeded(sender)
        let now = Date()
        let launchStatus = latestLaunchCountdownStatus()
        let healthInsights = launchControlHealthInsights(now: now)
        let commandID = Self.launchControlHealthActionCommandID(
            launchStatus: launchStatus,
            momentumSignal: healthInsights.momentumSignal
        )
        runFameCommand(commandID: commandID)
    }

    @objc private func runFameLaunchRecoveryNextFromMenu(_ sender: NSMenuItem) {
        recordLaunchControlTapIfNeeded(sender)
        let now = Date()
        let snapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        let actionID = (sender.representedObject as? String) ?? Self.fameOnboardingRecoveryQuickRunActionID(
            isFreshRecovery: snapshot.isFresh,
            followupCommandID: snapshot.followupActionID,
            remainingArtifacts: snapshot.remainingArtifacts,
            enabledActionIDs: fameOnboardingRecoveryQuickRunEnabledActionIDs(now: now)
        )

        guard let actionID else {
            readerState.petSay("Launch recovery quick run is not active yet.", mood: .ready)
            readerState.pulse()
            recordActivity(category: "support", detail: "run-fame-launch-recovery-next-unavailable")
            return
        }

        runFameOnboardingRecoveryQuickRun(actionID: actionID, source: .launchControlMenu, now: now)
    }

    private func runFameLaunchRecoveryHotKey(now: Date = Date()) {
        let snapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        let enabledActionIDs = fameOnboardingRecoveryQuickRunEnabledActionIDs(now: now)
        let actionID = Self.fameOnboardingRecoveryQuickRunActionID(
            isFreshRecovery: snapshot.isFresh,
            followupCommandID: snapshot.followupActionID,
            remainingArtifacts: snapshot.remainingArtifacts,
            enabledActionIDs: enabledActionIDs
        )

        guard let actionID else {
            if let fallbackActionID = Self.fameOnboardingRecoveryFallbackActionID(
                enabledActionIDs: enabledActionIDs
            ) {
                showLaunchRecoveryGlobalHotKeyFallbackPulse(actionID: fallbackActionID)
                recordActivity(
                    category: "support",
                    detail: Self.launchRecoveryGlobalHotKeyFallbackActivityDetail(
                        actionID: fallbackActionID
                    )
                )
                runFameOnboardingRecoveryQuickRun(
                    actionID: fallbackActionID,
                    source: .other,
                    now: now
                )
                return
            }

            if !commandPalette.isVisible {
                commandPalette.show()
            }
            readerState.petSay(
                "Launch recovery route is not active yet. Command Palette opened for next-step fallback.",
                mood: .ready
            )
            readerState.pulse()
            recordActivity(
                category: "support",
                detail: Self.launchRecoveryGlobalHotKeyUnavailableActivityDetail()
            )
            return
        }

        runFameOnboardingRecoveryQuickRun(actionID: actionID, source: .globalHotKey, now: now)
    }

    private func runFameExceptionalLoopHotKey(now: Date = Date()) {
        runFameExceptionalLoop(now: now)
        recordActivity(
            category: "support",
            detail: Self.fameExceptionalLoopGlobalHotKeyActivityDetail()
        )
    }

    @objc private func runFamePulseRiskActionFromMenu() {
        let commandID = Self.famePulseRiskActionCommandID(
            signal: famePulseAlertSignal(),
            transition: famePulseLatestTransition()
        )
        runFameCommand(commandID: commandID)
    }

    @objc private func runFameLaunchRescueAutoStatusFromMenu(_ sender: NSMenuItem) {
        recordLaunchControlTapIfNeeded(sender)
        runFameLaunchRescueBurstAutoStatusAction()
    }

    @objc private func openFameLaunchThresholdAlertsSnoozeReminderFromMenu(_ sender: NSMenuItem) {
        recordLaunchControlTapIfNeeded(sender)
        effects.play(.tap, settings: settings)

        guard let action = fameLaunchThresholdAlertsSnoozeReminderMenuTapAction() else {
            readerState.petSay("Launch snooze reminder is not actionable yet.", mood: .ready)
            return
        }
        runFameLaunchThresholdAlertsQuickAction(
            action: action,
            source: Self.fameLaunchThresholdAlertsQuickActionSourceFromMenu(action: action)
        )
    }

    private func runFameLaunchThresholdAlertsQuickAction(
        action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction,
        source: String,
        now: Date = Date()
    ) {
        let actionToken = Self.fameLaunchThresholdAlertsQuickActionActivityToken(action: action)
        guard Self.shouldRunFameLaunchThresholdAlertsQuickAction(
            lastRunAt: fameLaunchThresholdAlertsQuickActionLastRunAt,
            lastActionToken: fameLaunchThresholdAlertsQuickActionLastActionToken,
            nextActionToken: actionToken,
            now: now,
            cooldown: fameLaunchThresholdAlertsQuickActionCooldown
        ) else {
            let remainingSeconds = Self.fameLaunchThresholdAlertsQuickActionCooldownRemainingSeconds(
                lastRunAt: fameLaunchThresholdAlertsQuickActionLastRunAt,
                lastActionToken: fameLaunchThresholdAlertsQuickActionLastActionToken,
                nextActionToken: actionToken,
                now: now,
                cooldown: fameLaunchThresholdAlertsQuickActionCooldown
            ) ?? 1
            readerState.petSay(
                "Quick action cooling down (\(remainingSeconds)s).",
                mood: .ready
            )
            flashStatus(
                symbol: "clock.badge.exclamationmark",
                tint: .systemOrange,
                length: 0.16
            )
            recordActivity(
                category: "support",
                detail: "launch-threshold-alerts-quick-action-cooldown-\(remainingSeconds)s-\(actionToken)-\(source)"
            )
            updateFameLaunchThresholdAlertsMenuTitle(now: now)
            startFameLaunchThresholdAlertsCooldownMenuRefresh(now: now)
            return
        }
        fameLaunchThresholdAlertsQuickActionLastRunAt = now
        fameLaunchThresholdAlertsQuickActionLastActionToken = actionToken

        switch action {
        case .unmuteNow:
            toggleFameLaunchThresholdAlerts(
                source: source,
                announce: false
            )
            applyFameLaunchThresholdAlertsQuickActionFeedback(action: .unmuteNow)
        case .extend(let minutes):
            let appliedMinutes = snoozeFameLaunchThresholdAlerts(
                minutes: minutes,
                source: source,
                announce: false
            )
            applyFameLaunchThresholdAlertsQuickActionFeedback(
                action: .extend(minutes: minutes),
                resolvedMinutes: appliedMinutes
            )
        }
        updateFameLaunchThresholdAlertsMenuTitle(now: now)
        startFameLaunchThresholdAlertsCooldownMenuRefresh(now: now)
    }

    private func startPick() {
        recordActivity(category: "core", detail: "pick-and-read")
        effects.hit(.wake, settings: settings, haptic: .alignment)
        flashStatus(symbol: "sparkles", tint: .systemCyan, length: 0.22)
        selectionController.start(
            onDrawStart: { [weak self] in
                guard let self else { return }
                self.effects.hit(.drawStart, settings: self.settings, haptic: .alignment)
                self.flashStatus(symbol: "scribble.variable", tint: .systemCyan, length: 0.16)
            },
            onCommit: { [weak self] in
                guard let self else { return }
                self.effects.hit(.capture, settings: self.settings, haptic: .levelChange)
                self.flashStatus(symbol: "scope", tint: .systemBlue, length: 0.18)
            },
            onCancel: { [weak self] in
                guard let self else { return }
                self.effects.play(.error, settings: self.settings)
                self.flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.26)
            },
            completion: { [weak self] selectedImage in
                guard let self else { return }
                Task {
                    await self.handleSelection(selectedImage)
                }
            }
        )
    }

    private func handleSelection(_ selectedImage: SelectedImage) async {
        readerState.isWorking = true
        readerState.lastImageData = selectedImage.pngData
        readerState.errorText = ""
        rewardHUD.show("Reading", mood: .working, intensity: settings.feelIntensity)
        startWorkingFeedback()

        do {
            let text = try await ocr.recognizeText(
                in: selectedImage.cgImage,
                languageCode: settings.ocrLanguageCode
            )
            stopWorkingFeedback()
            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            readerState.lastText = cleanText
            readerState.isWorking = false

            if cleanText.isEmpty {
                readerState.errorText = "No readable text found."
                effects.play(.error, settings: settings)
                rewardHUD.show("No text", mood: .error, intensity: settings.feelIntensity)
                flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.30)
                recordActivity(category: "capture", detail: "ocr-empty")
                readerWindow.show()
                return
            }

            readerState.pulse()
            readerState.remember(text: cleanText)
            effects.hit(.success, settings: settings, haptic: .levelChange)
            rewardHUD.show("Ready", mood: .success, intensity: settings.feelIntensity)
            flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.42)
            recordActivity(category: "capture", detail: "ocr-success")

            if settings.readAfterPick {
                read(cleanText)
            }

            if settings.llmEnabled {
                readerWindow.show()
            }
        } catch {
            stopWorkingFeedback()
            readerState.isWorking = false
            readerState.errorText = error.localizedDescription
            effects.play(.error, settings: settings)
            rewardHUD.show("Error", mood: .error, intensity: settings.feelIntensity)
            flashStatus(symbol: "exclamationmark.triangle.fill", tint: .systemRed, length: 0.36)
            recordActivity(category: "capture", detail: "ocr-error")
            readerWindow.show()
        }
    }

    private func read(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        speech.speak(text, settings: settings)
    }

    private func copyToClipboard(
        _ text: String,
        message: String,
        announcePetMessage: Bool = true
    ) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(cleanText, forType: .string)
        if announcePetMessage {
            readerState.petSay(message, mood: .happy)
        }
        effects.hit(.success, settings: settings, haptic: .alignment)
    }

    private func copyToClipboardWithReadyPrompt(
        _ text: String,
        readyMessage: String,
        copyMessage: String,
        mood: PetMood = .happy,
        clearError: Bool = true,
        pulse: Bool = true
    ) {
        if clearError {
            readerState.errorText = ""
        }
        readerState.petSay(readyMessage, mood: mood)
        copyToClipboard(
            text,
            message: copyMessage,
            announcePetMessage: false
        )
        if pulse {
            readerState.pulse()
        }
    }

    private func copyToClipboardPreservingPrompt(
        _ text: String,
        copyMessage: String,
        clearError: Bool = false,
        pulse: Bool = false
    ) {
        if clearError {
            readerState.errorText = ""
        }
        copyToClipboard(
            text,
            message: copyMessage,
            announcePetMessage: false
        )
        if pulse {
            readerState.pulse()
        }
    }

    private func copyResult() {
        let text = readerState.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? readerState.lastText
            : readerState.answerText
        copyToClipboard(text, message: "Copied result.")
    }

    private func copyLastImage() {
        guard let data = readerState.lastImageData else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
        readerState.petSay("Copied image.", mood: .happy)
        effects.hit(.success, settings: settings, haptic: .alignment)
    }

    private func saveText(_ text: String, title: String, fileNamePrefix: String) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let panel = NSSavePanel()
        panel.title = title
        panel.nameFieldStringValue = "\(safeFileName(fileNamePrefix)).txt"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try cleanText.write(to: url, atomically: true, encoding: .utf8)
            readerState.petSay("Saved file.", mood: .happy)
            effects.hit(.success, settings: settings, haptic: .alignment)
        } catch {
            readerState.errorText = error.localizedDescription
            effects.play(.error, settings: settings)
        }
    }

    private func saveResult() {
        let text = readerState.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? readerState.lastText
            : readerState.answerText
        saveText(text, title: "Save Result", fileNamePrefix: "result")
    }

    private func saveLastImage() {
        guard let data = readerState.lastImageData else { return }
        let panel = NSSavePanel()
        panel.title = "Save Image"
        panel.nameFieldStringValue = "capture.png"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.png]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try data.write(to: url)
            readerState.petSay("Saved image.", mood: .happy)
            effects.hit(.success, settings: settings, haptic: .alignment)
        } catch {
            readerState.errorText = error.localizedDescription
            effects.play(.error, settings: settings)
        }
    }

    private func saveSnippet(_ text: String) {
        _ = readerState.saveSnippet(text: text)
    }

    private func safeFileName(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "fluid-reader"
        guard !trimmed.isEmpty else { return fallback }

        let replaced = trimmed.replacingOccurrences(
            of: #"[^a-zA-Z0-9._-]+"#,
            with: "-",
            options: .regularExpression
        )
        let collapsed = replaced.replacingOccurrences(
            of: "-+",
            with: "-",
            options: .regularExpression
        )
        let clean = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-."))
        if clean.isEmpty {
            return fallback
        }
        return String(clean.prefix(48))
    }

    private func commandPaletteActions() -> [CommandPaletteAction] {
        let hasText = !readerState.lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAnswer = !readerState.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAnyResult = hasAnswer || hasText
        let searchQuery = searchSeedText()
        let hasSearchQuery = !searchQuery.isEmpty
        let autoOpsBundleStatus = autoOpsBundleEscalationStatus()
        let launchRescueAutoStatus = launchRescueBurstAutoStatus()
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason()
        let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        let launchRescueSelfHealAttentionSnapshot = launchRescueAutoSelfHealAttentionMenuSnapshot(
            triggerReason: launchRescueAutoTriggerReason,
            lastAutoTriggerAt: launchRescueAutoTriggerAt
        )
        let launchRescueFollowupRouteDecision = Self.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: launchRescueAutoTriggerReason,
            recommendedActionID: launchRescueSelfHealAttentionSnapshot?.recommendedActionID
        )
        let launchRescueFollowupResolvedCommandID =
            launchRescueFollowupRouteDecision.resolvedCommandID
        let launchRescueFollowupRouteBadge = Self.launchRescueAutoFollowupRouteBadgeForResolvedDecision(
            defaultCommandID: launchRescueFollowupRouteDecision.defaultCommandID,
            resolvedCommandID: launchRescueFollowupResolvedCommandID
        )
        let launchRescueFollowupRouteDecisionTraceLine =
            Self.launchRescueAutoFollowupRouteDecisionTraceLine(
                defaultCommandID: launchRescueFollowupRouteDecision.defaultCommandID,
                resolvedCommandID: launchRescueFollowupResolvedCommandID
            )
        let launchRescueFollowupOutcomeScoreboard = launchRescueFollowupOutcomeScoreboard()
        let launchRescueFollowupCoachRecoveryLaneStreak = launchRescueFollowupCoachRecoveryLaneStreak()
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutes =
            launchRescueFollowupRecoveryChecklistAutoCooldownMinutes()
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining =
            launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining()
        let launchRescueFollowupOutcomeCoachSummary = Self.launchRescueFollowupOutcomeCoachSummary(
            launchRescueFollowupOutcomeScoreboard,
            triggerReason: launchRescueAutoTriggerReason,
            recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining
        )
        let launchRescueFollowupMomentumBadge = Self.launchRescueFollowupMomentumBadge(
            launchRescueFollowupOutcomeScoreboard,
            recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining
        )
        let launchRescueFollowupActionSubtitle = Self.launchRescueAutoTriggerFollowupActionSubtitle(
            launchRescueAutoTriggerReason,
            lastAutoTriggerAt: launchRescueAutoTriggerAt,
            routeCommandIDOverride: launchRescueFollowupResolvedCommandID
        )
        let launchCountdownStatus = latestLaunchCountdownStatus()
        let launchThresholdAlertsSnoozeMinutes = fameLaunchThresholdAlertsSnoozeMinutesRemaining()
        let recommendedLaunchThresholdAlertsSnoozeMinutes = Self.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
            launchStatus: launchCountdownStatus
        )
        let onboardingSuiteStatus = fameOnboardingSuiteActionStatus()
        let launchControlHubStatus = launchControlHubActionStatus()
        let latestNextMoveHandoffMarkdown = latestNextMoveHandoffMarkdownForCommandPalette()
        let launchPackModeTransitionCount = max(
            0,
            UserDefaults.standard.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey
            )
        )
        let launchPackModeTransitionLatest = UserDefaults.standard.string(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey
        )
        let launchPackModeMomentumStreak = UserDefaults.standard.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let bestChannelLaunchPackSubtitle = Self.nextMoveBestChannelLaunchPackActionSubtitle(
            handoffMarkdown: latestNextMoveHandoffMarkdown,
            pressureModeTransitionCount: launchPackModeTransitionCount,
            pressureModeTransitionLatest: launchPackModeTransitionLatest,
            pressureModeMomentumStreak: launchPackModeMomentumStreak
        )
        let bestChannelDraftSubtitle = Self.nextMoveBestChannelDraftActionSubtitle(
            handoffMarkdown: latestNextMoveHandoffMarkdown
        )
        let exceptionalLoopAutoRecoveryTuningContext =
            fameExceptionalLoopAutoRecoveryLaneTuningContext()
        let exceptionalLoopAutoRecoveryTuningRecommendationSummary =
            Self.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: exceptionalLoopAutoRecoveryTuningContext.recommendation,
                currentMissesRequired: exceptionalLoopAutoRecoveryTuningContext.missesRequired,
                currentFailureStreakRequired:
                    exceptionalLoopAutoRecoveryTuningContext.failureStreakRequired,
                currentCooldownMinutes: exceptionalLoopAutoRecoveryTuningContext.cooldownMinutes
            )
        let exceptionalLoopAutoRecoveryTuningMenuStatus =
            Self.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                recommendation: exceptionalLoopAutoRecoveryTuningContext.recommendation,
                currentMissesRequired: exceptionalLoopAutoRecoveryTuningContext.missesRequired,
                currentFailureStreakRequired:
                    exceptionalLoopAutoRecoveryTuningContext.failureStreakRequired,
                currentCooldownMinutes: exceptionalLoopAutoRecoveryTuningContext.cooldownMinutes
            )
        let exceptionalLoopLatestRecapStatus = fameExceptionalLoopLatestRecapStatus()
        let exceptionalLoopLatestRecapActionState =
            Self.fameExceptionalLoopLatestRecapCommandPaletteActionState(
                status: exceptionalLoopLatestRecapStatus
            )
        let exceptionalLoopOutcomeTuningResetStatus =
            fameExceptionalLoopOutcomeTuningResetStatus()

        var actions: [CommandPaletteAction] = [
            CommandPaletteAction(
                id: "pick-and-read",
                title: "Pick and Read",
                subtitle: "Draw an area to read from screen",
                systemImage: "lasso",
                group: .core,
                keywords: ["pick", "read", "ocr", "capture"]
            ) { [weak self] in
                self?.startPick()
            },
            CommandPaletteAction(
                id: "read-selected",
                title: "Read Selected Text",
                subtitle: "Copy selected text from front app and read",
                systemImage: "text.cursor",
                group: .core,
                keywords: ["selected", "copy", "read"]
            ) { [weak self] in
                self?.readSelectedTextFromFrontApp()
            },
            CommandPaletteAction(
                id: "show-reader",
                title: "Show Reader",
                subtitle: "Open reader window",
                systemImage: "macwindow",
                group: .window
            ) { [weak self] in
                self?.readerWindow.show()
            },
            CommandPaletteAction(
                id: "ask-anything",
                title: "Ask Anything",
                subtitle: "Ask about current, selected, clipboard, or picked text",
                systemImage: "sparkles",
                group: .ask,
                keywords: ["ask", "llm", "question", "answer"]
            ) { [weak self] in
                self?.askAnything()
            },
            CommandPaletteAction(
                id: "read-last-text",
                title: "Read Current Text",
                subtitle: "Read the text in Reader",
                systemImage: "waveform",
                group: .text,
                keywords: ["read", "text"],
                isEnabled: hasText,
                disabledReason: "No text ready"
            ) { [weak self] in
                guard let self else { return }
                self.read(self.readerState.lastText)
                self.recordActivity(category: "core", detail: "read-last-text")
            },
            CommandPaletteAction(
                id: "copy-last-text",
                title: "Copy Current Text",
                subtitle: "Copy current reader text",
                systemImage: "doc.on.doc",
                group: .text,
                keywords: ["copy", "text"],
                isEnabled: hasText,
                disabledReason: "No text ready"
            ) { [weak self] in
                guard let self else { return }
                self.copyToClipboard(self.readerState.lastText, message: "Copied text.")
                self.recordActivity(category: "text", detail: "copy-last-text")
            },
            CommandPaletteAction(
                id: "copy-answer",
                title: "Copy Answer",
                subtitle: "Copy latest AI answer",
                systemImage: "doc.plaintext",
                group: .text,
                keywords: ["copy", "answer", "llm"],
                isEnabled: hasAnswer,
                disabledReason: "No answer ready"
            ) { [weak self] in
                guard let self else { return }
                self.copyToClipboard(self.readerState.answerText, message: "Copied answer.")
                self.recordActivity(category: "text", detail: "copy-answer")
            },
            CommandPaletteAction(
                id: "copy-result",
                title: "Copy Result",
                subtitle: "Copy answer or text",
                systemImage: "doc.on.clipboard",
                group: .text,
                keywords: ["copy", "result"],
                isEnabled: hasAnyResult,
                disabledReason: "No result ready"
            ) { [weak self] in
                self?.copyResult()
                self?.recordActivity(category: "text", detail: "copy-result")
            },
            CommandPaletteAction(
                id: "save-answer",
                title: "Save Answer",
                subtitle: "Save current answer to file",
                systemImage: "square.and.arrow.down",
                group: .saved,
                keywords: ["save", "answer"],
                isEnabled: hasAnswer,
                disabledReason: "No answer ready"
            ) { [weak self] in
                guard let self else { return }
                self.saveText(self.readerState.answerText, title: "Save Answer", fileNamePrefix: "answer")
                self.recordActivity(category: "saved", detail: "save-answer")
            },
            CommandPaletteAction(
                id: "search-selected-web",
                title: "Search Selected Web",
                subtitle: "Search current text in browser",
                systemImage: "safari",
                group: .open,
                keywords: ["search", "web", "browser", "selected"],
                isEnabled: hasSearchQuery,
                disabledReason: "No text to search"
            ) { [weak self] in
                guard let self else { return }
                self.searchWeb(query: self.searchSeedText())
            },
            CommandPaletteAction(
                id: "copy-win-recap",
                title: "Copy Win Recap",
                subtitle: "Copy lightweight social recap",
                systemImage: "text.quote",
                group: .support,
                keywords: ["win", "recap", "share", "social"]
            ) { [weak self] in
                self?.copyWinRecap()
            },
            CommandPaletteAction(
                id: "copy-launch-kit",
                title: "Copy Launch Kit",
                subtitle: "Copy launch copy + KPI targets",
                systemImage: "paperplane",
                group: .support,
                keywords: ["launch", "kit", "kpi", "share"]
            ) { [weak self] in
                self?.copyLaunchKit()
            },
            CommandPaletteAction(
                id: "copy-experiment-board",
                title: "Copy Fame Board",
                subtitle: "Copy weekly fame board",
                systemImage: "chart.bar.doc.horizontal",
                group: .support,
                keywords: ["fame", "board", "experiment", "share"]
            ) { [weak self] in
                self?.copyFameBoard()
            },
            CommandPaletteAction(
                id: "copy-fame-sprint",
                title: "Copy Fame Sprint",
                subtitle: "Copy 7-day fame sprint plan",
                systemImage: "calendar.day.timeline.left",
                group: .support,
                keywords: ["fame", "sprint", "weekly", "share"]
            ) { [weak self] in
                self?.copyFameSprint()
            },
            CommandPaletteAction(
                id: "run-fame-sprint",
                title: "Run Fame Sprint",
                subtitle: "Generate today's sprint plan",
                systemImage: "bolt.circle",
                group: .support,
                keywords: ["run", "fame", "sprint"]
            ) { [weak self] in
                self?.runFameSprint()
            },
            CommandPaletteAction(
                id: "run-fame-sprint-snapshot",
                title: "Run Fame Sprint + Save Snapshot",
                subtitle: "Generate sprint + save snapshot",
                systemImage: "internaldrive",
                group: .support,
                keywords: ["run", "fame", "snapshot"]
            ) { [weak self] in
                self?.runFameSprintSnapshot()
            },
            CommandPaletteAction(
                id: "run-fame-morning-brief",
                title: "Run Morning Fame Brief",
                subtitle: "Generate morning brief",
                systemImage: "sun.max.fill",
                group: .support,
                keywords: ["run", "morning", "brief"]
            ) { [weak self] in
                self?.runFameMorningBrief()
            },
            CommandPaletteAction(
                id: "run-fame-midday-brief",
                title: "Run Midday Fame Brief",
                subtitle: "Generate midday brief",
                systemImage: "sun.max.circle.fill",
                group: .support,
                keywords: ["run", "midday", "brief"]
            ) { [weak self] in
                self?.runFameMiddayBrief()
            },
            CommandPaletteAction(
                id: "run-fame-evening-brief",
                title: "Run Evening Fame Brief",
                subtitle: "Generate evening brief",
                systemImage: "moon.stars.fill",
                group: .support,
                keywords: ["run", "evening", "brief"]
            ) { [weak self] in
                self?.runFameEveningBrief()
            },
            CommandPaletteAction(
                id: "run-fame-weekly-rollup",
                title: "Run Weekly Fame Rollup",
                subtitle: "Generate weekly rollup",
                systemImage: "chart.line.text.clipboard",
                group: .support,
                keywords: ["run", "weekly", "rollup"]
            ) { [weak self] in
                self?.runFameWeeklyRollup()
            },
            CommandPaletteAction(
                id: "run-fame-24h-queue",
                title: "Run Daily Fame Mission",
                subtitle: "Generate next 3h mission",
                systemImage: "list.bullet.clipboard",
                group: .support,
                keywords: ["run", "24h", "queue"]
            ) { [weak self] in
                self?.runFame24hQueue()
            },
            CommandPaletteAction(
                id: "run-fame-command-center",
                title: "Run Fame Command Center",
                subtitle: "Generate 72h operator brief",
                systemImage: "gauge.open.with.lines.needle.33percent",
                group: .support,
                keywords: ["run", "command", "center"]
            ) { [weak self] in
                self?.runFameCommandCenter()
            },
            CommandPaletteAction(
                id: "run-fame-breakthrough-forecast",
                title: "Run Fame Breakthrough Forecast",
                subtitle: "Generate 7-day forecast",
                systemImage: "chart.line.uptrend.xyaxis.circle",
                group: .support,
                keywords: ["run", "breakthrough", "forecast"]
            ) { [weak self] in
                self?.runFameBreakthroughForecast()
            },
            CommandPaletteAction(
                id: "run-fame-auto-bundle-status",
                title: Self.autoOpsBundleStatusActionTitle(
                    autoOpsBundleStatus,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                subtitle: Self.autoOpsBundleStatusActionSubtitle(
                    autoOpsBundleStatus,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: Self.autoOpsBundleStatusActionSystemImage(autoOpsBundleStatus),
                group: .support,
                keywords: ["auto", "ops", "bundle"],
                canFavorite: false
            ) { [weak self] in
                self?.runFameAutoBundleStatusAction()
            },
            CommandPaletteAction(
                id: "run-fame-ops-bundle",
                title: "Run Fame Ops Bundle",
                subtitle: "Generate command center + pulse set",
                systemImage: "shippingbox.circle",
                group: .support,
                keywords: ["run", "ops", "bundle"]
            ) { [weak self] in
                self?.runFameOpsBundle()
            },
            CommandPaletteAction(
                id: "run-fame-daily-checkpoint",
                title: "Run Daily Fame Checkpoint",
                subtitle: "Generate KPI checkpoint",
                systemImage: "calendar.badge.clock",
                group: .support,
                keywords: ["run", "daily", "checkpoint"]
            ) { [weak self] in
                self?.runFameDailyCheckpoint()
            },
            CommandPaletteAction(
                id: "run-fame-daily-scorecard",
                title: "Run Daily Fame Scorecard",
                subtitle: "Generate daily scorecard",
                systemImage: "chart.xyaxis.line",
                group: .support,
                keywords: ["run", "daily", "scorecard"]
            ) { [weak self] in
                self?.runFameDailyScorecard()
            },
            CommandPaletteAction(
                id: "run-fame-escalation-nudge",
                title: "Run Fame Escalation Nudge",
                subtitle: "Generate escalation nudge",
                systemImage: "exclamationmark.triangle.badge.clock",
                group: .support,
                keywords: ["run", "escalation", "nudge"]
            ) { [weak self] in
                self?.runFameEscalationNudge()
            },
            CommandPaletteAction(
                id: "run-fame-recovery-sprint",
                title: "Run Fame Recovery Sprint",
                subtitle: "Generate 6h recovery plan",
                systemImage: "flame.fill",
                group: .support,
                keywords: ["run", "recovery", "sprint"]
            ) { [weak self] in
                self?.runFameRecoverySprint()
            },
            CommandPaletteAction(
                id: "run-fame-recovery-checklist",
                title: "Run 2h Recovery Checklist",
                subtitle: "Generate 2h recovery checklist",
                systemImage: "checklist.checked",
                group: .support,
                keywords: ["run", "recovery", "checklist"]
            ) { [weak self] in
                self?.runFameRecoveryChecklist()
            },
            CommandPaletteAction(
                id: "run-fame-recovery-proof-pack",
                title: "Run Recovery Proof Pack",
                subtitle: "Generate recovery proof snippets",
                systemImage: "text.badge.checkmark",
                group: .support,
                keywords: ["run", "recovery", "proof"]
            ) { [weak self] in
                self?.runFameRecoveryProofPack()
            },
            CommandPaletteAction(
                id: "run-fame-risk-timeline",
                title: "Run Fame Risk Timeline",
                subtitle: "Generate risk timeline",
                systemImage: "waveform.path.ecg",
                group: .support,
                keywords: ["run", "risk", "timeline"]
            ) { [weak self] in
                self?.runFameRiskTimeline()
            },
            CommandPaletteAction(
                id: "run-fame-operator-dashboard",
                title: "Run Fame Operator Dashboard",
                subtitle: "Generate operator dashboard",
                systemImage: "gauge.open.with.lines.needle.33percent",
                group: .support,
                keywords: ["run", "operator", "dashboard"]
            ) { [weak self] in
                self?.runFameOperatorDashboard()
            },
            CommandPaletteAction(
                id: "run-fame-narrative-lab",
                title: "Run Fame Narrative Lab",
                subtitle: "Generate publish-ready narrative routes",
                systemImage: "text.bubble",
                group: .support,
                keywords: ["run", "fame", "narrative", "story", "route", "publish"]
            ) { [weak self] in
                self?.runFameNarrativeLab()
            },
            CommandPaletteAction(
                id: "run-fame-spotlight-pack",
                title: "Run Fame Spotlight Pack",
                subtitle: "Generate channel-ready spotlight drafts",
                systemImage: "megaphone",
                group: .support,
                keywords: ["run", "fame", "spotlight", "draft", "publish", "channel"]
            ) { [weak self] in
                self?.runFameSpotlightPack()
            },
            CommandPaletteAction(
                id: "run-fame-launch-day-script",
                title: "Run Fame Launch Day Script",
                subtitle: "Generate timed launch script + copy blocks",
                systemImage: "flag.checkered.2.crossed",
                group: .support,
                keywords: ["run", "fame", "launch", "script", "timeline", "copy"]
            ) { [weak self] in
                self?.runFameLaunchDayScript()
            },
            CommandPaletteAction(
                id: "run-fame-launch-countdown",
                title: "Run Fame Launch Countdown",
                subtitle: Self.launchCountdownActionSubtitle(
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "timer",
                group: .support,
                keywords: ["run", "fame", "launch", "countdown", "timeline", "next step"]
            ) { [weak self] in
                self?.runFameLaunchCountdown()
            },
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst",
                title: "Run Launch Rescue Burst",
                subtitle: Self.launchRescueBurstActionSubtitle(
                    modeMomentumStreak: launchPackModeMomentumStreak,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "bolt.shield",
                group: .support,
                keywords: ["run", "fame", "launch", "rescue", "burst", "countdown", "handoff", "recovery", "draft pack"]
            ) { [weak self] in
                self?.runFameLaunchRescueBurst()
            },
            CommandPaletteAction(
                id: "run-fame-launch-control-brief",
                title: "Run Launch Control Brief",
                subtitle: Self.launchControlBriefActionSubtitle(
                    "Refresh launch countdown + save + copy launch control brief",
                    followupMomentumBadge: launchRescueFollowupMomentumBadge,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "list.bullet.rectangle.portrait",
                group: .support,
                keywords: ["run", "fame", "launch", "control", "brief", "countdown", "rescue", "status", "save", "copy"]
            ) { [weak self] in
                self?.runFameLaunchControlBrief()
            },
            CommandPaletteAction(
                id: "run-fame-launch-control-hub",
                title: "Run Launch Control Hub",
                subtitle: Self.launchRescueSnapshotActionSubtitle(
                    "Generate burst + countdown + brief + snapshot",
                    followupMomentumBadge: launchRescueFollowupMomentumBadge,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "square.stack.3d.up.fill",
                group: .support,
                keywords: [
                    "run",
                    "fame",
                    "launch",
                    "control",
                    "hub",
                    "brief",
                    "snapshot",
                    "burst",
                    "countdown",
                    "orchestrate"
                ]
            ) { [weak self] in
                self?.runFameLaunchControlHub()
            },
            CommandPaletteAction(
                id: "run-fame-launch-rescue-snapshot",
                title: "Run Launch Rescue Snapshot",
                subtitle: Self.launchRescueSnapshotActionSubtitle(
                    "Generate + save + reveal launch rescue snapshot",
                    followupMomentumBadge: launchRescueFollowupMomentumBadge,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "doc.text",
                group: .support,
                keywords: [
                    "run",
                    "fame",
                    "launch",
                    "rescue",
                    "snapshot",
                    "auto",
                    "follow-up",
                    "scoreboard",
                    "coach",
                    "momentum",
                    "save"
                ]
            ) { [weak self] in
                self?.runFameLaunchRescueSnapshot()
            },
            CommandPaletteAction(
                id: "copy-fame-launch-control-brief",
                title: "Copy Launch Control Brief",
                subtitle: Self.launchControlBriefActionSubtitle(
                    "Copy live launch alert + rescue + threshold status brief",
                    followupMomentumBadge: launchRescueFollowupMomentumBadge,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "list.bullet.rectangle.portrait",
                group: .support,
                keywords: ["copy", "fame", "launch", "control", "brief", "status", "rescue", "threshold", "alerts"]
            ) { [weak self] in
                self?.copyFameLaunchControlBrief()
            },
            CommandPaletteAction(
                id: "copy-fame-launch-rescue-snapshot",
                title: "Copy Launch Rescue Snapshot",
                subtitle: Self.launchRescueSnapshotActionSubtitle(
                    "Copy auto trigger + follow-up + scoreboard snapshot",
                    followupMomentumBadge: launchRescueFollowupMomentumBadge,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "doc.on.doc",
                group: .support,
                keywords: [
                    "copy",
                    "fame",
                    "launch",
                    "rescue",
                    "snapshot",
                    "auto",
                    "follow-up",
                    "scoreboard",
                    "coach",
                    "momentum"
                ]
            ) { [weak self] in
                self?.copyFameLaunchRescueSnapshot()
            },
            CommandPaletteAction(
                id: "run-fame-launch-rescue-burst-auto-status",
                title: Self.launchRescueBurstAutoStatusActionTitle(
                    launchRescueAutoStatus,
                    modeMomentumStreak: launchPackModeMomentumStreak,
                    triggerSeverityBadge: Self.launchRescueAutoTriggerSeverityBadge(
                        launchRescueAutoTriggerReason
                    ),
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                subtitle: Self.launchRescueBurstAutoStatusActionSubtitle(
                    launchRescueAutoStatus,
                    modeMomentumStreak: launchPackModeMomentumStreak,
                    lastAutoTriggerReason: launchRescueAutoTriggerReason,
                    lastAutoTriggerAt: launchRescueAutoTriggerAt,
                    followupRouteDecisionTraceLine: launchRescueFollowupRouteDecisionTraceLine,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: Self.launchRescueBurstAutoStatusActionSystemImage(launchRescueAutoStatus),
                group: .support,
                keywords: ["launch", "rescue", "auto", "burst", "status", "cooldown"],
                canFavorite: false
            ) { [weak self] in
                self?.runFameLaunchRescueBurstAutoStatusAction()
            },
            CommandPaletteAction(
                id: "run-fame-launch-rescue-followup-now",
                title: Self.launchRescueAutoTriggerFollowupActionTitle(
                    launchRescueAutoTriggerReason,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title,
                    routeBadge: launchRescueFollowupRouteBadge
                ),
                subtitle: launchRescueFollowupActionSubtitle
                    + (
                        launchRescueSelfHealAttentionSnapshot.map {
                            " Self-Heal: \($0.signalBadge.helpText)"
                        } ?? ""
                    )
                    + " Coach: "
                    + launchRescueFollowupOutcomeCoachSummary
                    + (
                        launchRescueFollowupMomentumBadge.map { " · Momentum: \($0)" }
                            ?? ""
                    ),
                systemImage: Self.launchRescueAutoTriggerFollowupActionSystemImage(
                    launchRescueAutoTriggerReason
                ),
                group: .support,
                keywords: [
                    "launch",
                    "rescue",
                    "followup",
                    "follow-up",
                    "auto",
                    "next",
                    "route",
                    "critical"
                ],
                signalBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge,
                canFavorite: false
            ) { [weak self] in
                self?.runFameLaunchRescueFollowupNow(
                    routeCommandIDOverride: launchRescueFollowupResolvedCommandID
                )
            },
            CommandPaletteAction(
                id: "toggle-fame-launch-threshold-alerts",
                title: Self.fameLaunchThresholdAlertsToggleTitle(
                    settings.fameLaunchThresholdAlertsEnabled,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                subtitle: Self.fameLaunchThresholdAlertsToggleSubtitle(
                    settings.fameLaunchThresholdAlertsEnabled,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                systemImage: Self.fameLaunchThresholdAlertsToggleSystemImage(
                    settings.fameLaunchThresholdAlertsEnabled,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                group: .support,
                keywords: ["toggle", "fame", "launch", "threshold", "alerts", "mute", "unmute", "quiet", "hud", "flash", "snooze"],
                canFavorite: false
            ) { [weak self] in
                self?.toggleFameLaunchThresholdAlerts(source: "commands")
            },
            CommandPaletteAction(
                id: "snooze-fame-launch-threshold-alerts-recommended",
                title: Self.fameLaunchThresholdAlertsRecommendedSnoozeTitle(
                    minutes: recommendedLaunchThresholdAlertsSnoozeMinutes
                ),
                subtitle: Self.fameLaunchThresholdAlertsRecommendedSnoozeSubtitle(
                    minutes: recommendedLaunchThresholdAlertsSnoozeMinutes,
                    launchStatus: launchCountdownStatus,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                systemImage: Self.fameLaunchThresholdAlertsRecommendedSnoozeSystemImage(),
                group: .support,
                keywords: ["snooze", "fame", "launch", "threshold", "alerts", "recommended", "smart", "auto-unmute"],
                canFavorite: false
            ) { [weak self] in
                self?.snoozeFameLaunchThresholdAlerts(
                    minutes: recommendedLaunchThresholdAlertsSnoozeMinutes,
                    source: "commands-recommended"
                )
            },
            CommandPaletteAction(
                id: "snooze-fame-launch-threshold-alerts-10m",
                title: Self.fameLaunchThresholdAlertsSnoozeTitle(minutes: 10),
                subtitle: Self.fameLaunchThresholdAlertsSnoozeSubtitle(
                    minutes: 10,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                systemImage: Self.fameLaunchThresholdAlertsSnoozeSystemImage(),
                group: .support,
                keywords: ["snooze", "fame", "launch", "threshold", "alerts", "mute", "quiet", "10m", "auto-unmute"],
                canFavorite: false
            ) { [weak self] in
                self?.snoozeFameLaunchThresholdAlerts(minutes: 10, source: "commands")
            },
            CommandPaletteAction(
                id: "snooze-fame-launch-threshold-alerts-30m",
                title: Self.fameLaunchThresholdAlertsSnoozeTitle(minutes: 30),
                subtitle: Self.fameLaunchThresholdAlertsSnoozeSubtitle(
                    minutes: 30,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                systemImage: Self.fameLaunchThresholdAlertsSnoozeSystemImage(),
                group: .support,
                keywords: ["snooze", "fame", "launch", "threshold", "alerts", "mute", "quiet", "30m", "auto-unmute"],
                canFavorite: false
            ) { [weak self] in
                self?.snoozeFameLaunchThresholdAlerts(minutes: 30, source: "commands")
            },
            CommandPaletteAction(
                id: "snooze-fame-launch-threshold-alerts-60m",
                title: Self.fameLaunchThresholdAlertsSnoozeTitle(minutes: 60),
                subtitle: Self.fameLaunchThresholdAlertsSnoozeSubtitle(
                    minutes: 60,
                    snoozeMinutesRemaining: launchThresholdAlertsSnoozeMinutes
                ),
                systemImage: Self.fameLaunchThresholdAlertsSnoozeSystemImage(),
                group: .support,
                keywords: ["snooze", "fame", "launch", "threshold", "alerts", "mute", "quiet", "60m", "auto-unmute"],
                canFavorite: false
            ) { [weak self] in
                self?.snoozeFameLaunchThresholdAlerts(minutes: 60, source: "commands")
            },
            CommandPaletteAction(
                id: "run-fame-pulse-nudge",
                title: "Run Fame Pulse Nudge",
                subtitle: "Generate pulse nudge",
                systemImage: "bolt.badge.clock",
                group: .support,
                keywords: ["run", "pulse", "nudge"]
            ) { [weak self] in
                self?.runFamePulseNudge()
            },
            CommandPaletteAction(
                id: "copy-fame-pack",
                title: "Copy Fame Pack",
                subtitle: "Copy complete fame execution pack",
                systemImage: "shippingbox",
                group: .support,
                keywords: ["fame", "pack", "launch", "weekly", "share"]
            ) { [weak self] in
                self?.copyFamePack()
            },
            CommandPaletteAction(
                id: "copy-founder-command-presets",
                title: "Copy Founder Presets",
                subtitle: "Copy founder command stack",
                systemImage: "chart.line.uptrend.xyaxis",
                group: .support,
                keywords: ["founder", "commands", "stack"]
            ) { [weak self] in
                self?.copyFounderCommandPresets()
            },
            CommandPaletteAction(
                id: "save-fame-pack",
                title: "Save Fame Pack",
                subtitle: "Save complete fame execution pack",
                systemImage: "square.and.arrow.down.on.square",
                group: .saved,
                keywords: ["fame", "pack", "save", "export"]
            ) { [weak self] in
                self?.saveFamePack()
            },
            CommandPaletteAction(
                id: "open-latest-recovery-sprint",
                title: "Open Latest Recovery Sprint",
                subtitle: "Open latest recovery sprint",
                systemImage: "clock.arrow.circlepath",
                group: .open,
                keywords: ["open", "latest", "recovery"]
            ) { [weak self] in
                self?.openLatestRecoverySprint()
            },
            CommandPaletteAction(
                id: "open-latest-recovery-checklist",
                title: "Open Latest Recovery Checklist",
                subtitle: "Open latest recovery checklist",
                systemImage: "checklist.checked",
                group: .open,
                keywords: ["open", "latest", "checklist"]
            ) { [weak self] in
                self?.openLatestRecoveryChecklist()
            },
            CommandPaletteAction(
                id: "open-latest-recovery-proof-pack",
                title: "Open Latest Recovery Proof Pack",
                subtitle: "Open latest recovery proof pack",
                systemImage: "text.badge.checkmark",
                group: .open,
                keywords: ["open", "latest", "proof"]
            ) { [weak self] in
                self?.openLatestRecoveryProofPack()
            },
            CommandPaletteAction(
                id: "open-latest-command-center",
                title: "Open Latest Command Center",
                subtitle: "Open latest command center",
                systemImage: "gauge.open.with.lines.needle.33percent",
                group: .open,
                keywords: ["open", "latest", "command"]
            ) { [weak self] in
                self?.openLatestCommandCenter()
            },
            CommandPaletteAction(
                id: "open-latest-next-move-handoff",
                title: "Open Latest Next Move Handoff",
                subtitle: "Open latest next-move handoff",
                systemImage: "paperplane",
                group: .open,
                keywords: ["open", "latest", "handoff"]
            ) { [weak self] in
                self?.openLatestNextMoveHandoff()
            },
            CommandPaletteAction(
                id: "open-latest-next-move-draft-pack",
                title: "Open Latest Next Move Draft Pack",
                subtitle: "Open latest next-move draft pack",
                systemImage: "doc.text",
                group: .open,
                keywords: ["open", "latest", "next", "move", "draft", "pack"]
            ) { [weak self] in
                self?.openLatestNextMoveDraftPack()
            },
            CommandPaletteAction(
                id: "copy-next-move-drafts",
                title: "Copy Next-Move Draft Pack",
                subtitle: "X + Bluesky + LinkedIn + cadence",
                systemImage: "doc.on.doc",
                group: .support,
                keywords: ["copy", "draft", "next"]
            ) { [weak self] in
                self?.copyLatestNextMoveDraftPack()
            },
            CommandPaletteAction(
                id: "copy-next-move-launch-now-sequence",
                title: "Copy Launch Now Sequence",
                subtitle: "Cadence step + next two channel drafts",
                systemImage: "bolt.horizontal.circle",
                group: .support,
                keywords: ["copy", "launch", "now", "sequence", "next", "move", "cadence", "drafts"]
            ) { [weak self] in
                self?.copyLatestNextMoveLaunchNowSequence()
            },
            CommandPaletteAction(
                id: "copy-next-move-cadence-post",
                title: "Copy Post Cadence Now",
                subtitle: "Copy first cadence draft only",
                systemImage: "paperplane.badge.clock",
                group: .support,
                keywords: ["copy", "post", "cadence", "now", "next", "move", "draft"]
            ) { [weak self] in
                self?.copyLatestNextMoveCadencePost()
            },
            CommandPaletteAction(
                id: "copy-next-move-cadence-execution-kit",
                title: "Copy Cadence Execution Kit",
                subtitle: "Copy post + open queue + reply ladder",
                systemImage: "rocket",
                group: .support,
                keywords: ["copy", "cadence", "execution", "kit", "queue", "reply", "ladder", "launch", "next", "move"]
            ) { [weak self] in
                self?.copyLatestNextMoveCadenceExecutionKit()
            },
            CommandPaletteAction(
                id: "copy-next-move-cadence-post-queue",
                title: "Copy Post Cadence + Queue",
                subtitle: "Copy cadence draft + open 30m posting checklist",
                systemImage: "paperplane.circle",
                group: .support,
                keywords: ["copy", "post", "cadence", "queue", "checklist", "launch", "next", "move", "draft"]
            ) { [weak self] in
                self?.copyLatestNextMoveCadencePostQueue()
            },
            CommandPaletteAction(
                id: "copy-next-move-reply-ladder",
                title: "Copy Next-Move Reply Ladder",
                subtitle: "Copy 5 ready replies for the first 30m",
                systemImage: "text.bubble",
                group: .support,
                keywords: ["copy", "reply", "ladder", "queue", "cadence", "next", "move", "engagement"]
            ) { [weak self] in
                self?.copyLatestNextMoveReplyLadder()
            },
            CommandPaletteAction(
                id: "copy-next-move-x-draft",
                title: "Copy Next-Move X Draft",
                subtitle: "Copy latest X draft from handoff",
                systemImage: "x.circle",
                group: .support,
                keywords: ["copy", "next", "move", "x", "draft", "tweet", "post"]
            ) { [weak self] in
                self?.copyLatestNextMoveChannelDraft(.x)
            },
            CommandPaletteAction(
                id: "copy-next-move-bluesky-draft",
                title: "Copy Next-Move Bluesky Draft",
                subtitle: "Copy latest Bluesky draft from handoff",
                systemImage: "cloud",
                group: .support,
                keywords: ["copy", "next", "move", "bluesky", "draft", "post"]
            ) { [weak self] in
                self?.copyLatestNextMoveChannelDraft(.bluesky)
            },
            CommandPaletteAction(
                id: "copy-next-move-linkedin-draft",
                title: "Copy Next-Move LinkedIn Draft",
                subtitle: "Copy latest LinkedIn draft from handoff",
                systemImage: "briefcase",
                group: .support,
                keywords: ["copy", "next", "move", "linkedin", "draft", "post"]
            ) { [weak self] in
                self?.copyLatestNextMoveChannelDraft(.linkedIn)
            },
            CommandPaletteAction(
                id: "copy-next-move-best-channel-launch-pack",
                title: "Copy Best Channel Launch Pack",
                subtitle: bestChannelLaunchPackSubtitle,
                systemImage: "star.bubble",
                group: .support,
                keywords: ["copy", "next", "move", "best", "channel", "launch", "pack", "cadence", "queue"]
            ) { [weak self] in
                self?.copyLatestNextMoveBestChannelLaunchPack()
            },
            CommandPaletteAction(
                id: "copy-next-move-best-channel-draft",
                title: "Copy Best Channel Draft",
                subtitle: bestChannelDraftSubtitle,
                systemImage: "star.circle",
                group: .support,
                keywords: ["copy", "next", "move", "best", "channel", "cadence", "draft", "post"]
            ) { [weak self] in
                self?.copyLatestNextMoveBestChannelDraft()
            },
            CommandPaletteAction(
                id: "copy-next-move-cadence-step",
                title: "Copy First Cadence Step",
                subtitle: "Copy recommended 0-15m post block",
                systemImage: "bolt.badge.a",
                group: .support,
                keywords: ["copy", "first", "cadence", "step", "next", "move", "post"]
            ) { [weak self] in
                self?.copyLatestNextMoveCadenceStep()
            },
            CommandPaletteAction(
                id: "open-latest-cadence-momentum-brief",
                title: "Open Latest Cadence Momentum Brief",
                subtitle: "Open latest cadence momentum brief",
                systemImage: "bolt.fill",
                group: .open,
                keywords: ["open", "latest", "cadence", "momentum", "brief", "fame", "share"]
            ) { [weak self] in
                self?.openLatestCadenceMomentumBrief()
            },
            CommandPaletteAction(
                id: "open-latest-cadence-share-line",
                title: "Open Latest Cadence Share Line",
                subtitle: "Open latest cadence share line artifact",
                systemImage: "quote.bubble",
                group: .open,
                keywords: ["open", "latest", "cadence", "share", "line", "fame", "momentum"]
            ) { [weak self] in
                self?.openLatestCadenceShareLine()
            },
            CommandPaletteAction(
                id: "open-latest-cadence-share-pack",
                title: "Open Latest Cadence Share Pack",
                subtitle: "Open latest cadence share pack artifact",
                systemImage: "text.justify",
                group: .open,
                keywords: ["open", "latest", "cadence", "share", "pack", "fame", "momentum", "social"]
            ) { [weak self] in
                self?.openLatestCadenceSharePack()
            },
            CommandPaletteAction(
                id: "open-latest-fame-exceptional-loop-recap",
                title: "Open Latest Exceptional Loop Recap",
                subtitle: exceptionalLoopLatestRecapActionState.subtitle,
                systemImage: "sparkles.rectangle.stack",
                group: .open,
                keywords: ["open", "latest", "fame", "exceptional", "loop", "recap", "run", "focus"],
                isEnabled: exceptionalLoopLatestRecapActionState.isEnabled,
                disabledReason: exceptionalLoopLatestRecapActionState.disabledReason,
                canFavorite: false
            ) { [weak self] in
                self?.openLatestFameExceptionalLoopRecap()
            },
            CommandPaletteAction(
                id: "auto-tune-fame-exceptional-loop-recovery",
                title: "Auto-Tune Exceptional Loop Recovery",
                subtitle: exceptionalLoopAutoRecoveryTuningRecommendationSummary,
                systemImage: "slider.horizontal.3",
                group: .support,
                keywords: ["auto", "tune", "fame", "exceptional", "loop", "recovery", "lane", "telemetry", "cooldown"],
                isEnabled: exceptionalLoopAutoRecoveryTuningMenuStatus.isEnabled,
                disabledReason: exceptionalLoopAutoRecoveryTuningMenuStatus.isEnabled
                    ? "Adaptive tuning ready."
                    : exceptionalLoopAutoRecoveryTuningMenuStatus.title,
                canFavorite: false
            ) { [weak self] in
                self?.runFameExceptionalLoopAutoRecoveryLaneAutoTune()
            },
            CommandPaletteAction(
                id: "reset-fame-exceptional-loop-tuning",
                title: "Reset Exceptional Loop Tuning",
                subtitle: exceptionalLoopOutcomeTuningResetStatus.subtitle,
                systemImage: "arrow.counterclockwise.circle",
                group: .support,
                keywords: ["reset", "fame", "exceptional", "loop", "tuning", "outcome", "streak", "recovery"],
                isEnabled: exceptionalLoopOutcomeTuningResetStatus.isEnabled,
                disabledReason: exceptionalLoopOutcomeTuningResetStatus.isEnabled
                    ? "Reset is ready."
                    : exceptionalLoopOutcomeTuningResetStatus.title,
                canFavorite: false
            ) { [weak self] in
                self?.resetFameExceptionalLoopOutcomeTuningFromCommand()
            },
            CommandPaletteAction(
                id: "open-latest-daily-checkpoint",
                title: "Open Latest Daily Checkpoint",
                subtitle: "Open latest daily checkpoint",
                systemImage: "calendar.badge.clock",
                group: .open,
                keywords: ["open", "latest", "checkpoint"]
            ) { [weak self] in
                self?.openLatestDailyCheckpoint()
            },
            CommandPaletteAction(
                id: "open-latest-risk-timeline",
                title: "Open Latest Risk Timeline",
                subtitle: "Open latest risk timeline",
                systemImage: "waveform.path.ecg",
                group: .open,
                keywords: ["open", "latest", "timeline"]
            ) { [weak self] in
                self?.openLatestRiskTimeline()
            },
            CommandPaletteAction(
                id: "open-latest-pulse-nudge",
                title: "Open Latest Pulse Nudge",
                subtitle: "Open latest pulse nudge",
                systemImage: "bolt.badge.clock",
                group: .open,
                keywords: ["open", "latest", "pulse"]
            ) { [weak self] in
                self?.openLatestPulseNudge()
            },
            CommandPaletteAction(
                id: "open-latest-daily-scorecard",
                title: "Open Latest Daily Scorecard",
                subtitle: "Open latest daily scorecard",
                systemImage: "chart.xyaxis.line",
                group: .open,
                keywords: ["open", "latest", "scorecard"]
            ) { [weak self] in
                self?.openLatestDailyScorecard()
            },
            CommandPaletteAction(
                id: "open-latest-onboarding-suite",
                title: "Open First-Week Onboarding Hub",
                subtitle: Self.fameOnboardingSuiteActionSubtitle(
                    availableArtifacts: onboardingSuiteStatus.availableArtifacts,
                    totalArtifacts: onboardingSuiteStatus.totalArtifacts,
                    newestArtifactAgeMinutes: onboardingSuiteStatus.newestArtifactAgeMinutes
                ),
                systemImage: "square.stack.3d.up.badge.a",
                group: .open,
                keywords: ["open", "latest", "onboarding", "first-week", "daily", "brief", "scorecard", "nudge", "hub", "suite", "fame"]
            ) { [weak self] in
                self?.openLatestOnboardingSuite()
            },
            CommandPaletteAction(
                id: "open-latest-onboarding-daily-brief",
                title: "Open Latest First-Week Daily Brief",
                subtitle: "Open latest first-week daily brief",
                systemImage: "square.stack.3d.up.fill",
                group: .open,
                keywords: ["open", "latest", "onboarding", "first-week", "daily", "brief", "fame"]
            ) { [weak self] in
                self?.openLatestOnboardingDailyBrief()
            },
            CommandPaletteAction(
                id: "open-latest-onboarding-nudge",
                title: "Open Latest Fame Onboarding Nudge",
                subtitle: "Open latest first-week onboarding nudge",
                systemImage: "sparkles.rectangle.stack",
                group: .open,
                keywords: ["open", "latest", "onboarding", "first-week", "nudge", "fame"]
            ) { [weak self] in
                self?.openLatestOnboardingNudge()
            },
            CommandPaletteAction(
                id: "open-latest-onboarding-scorecard",
                title: "Open Latest First-Week Fame Scorecard",
                subtitle: "Open latest first-week onboarding scorecard",
                systemImage: "chart.bar.fill",
                group: .open,
                keywords: ["open", "latest", "onboarding", "first-week", "scorecard"]
            ) { [weak self] in
                self?.openLatestOnboardingScorecard()
            },
            CommandPaletteAction(
                id: "open-latest-operator-dashboard",
                title: "Open Latest Operator Dashboard",
                subtitle: "Open latest operator dashboard",
                systemImage: "chart.bar.doc.horizontal",
                group: .open,
                keywords: ["open", "latest", "dashboard"]
            ) { [weak self] in
                self?.openLatestOperatorDashboard()
            },
            CommandPaletteAction(
                id: "open-latest-narrative-lab",
                title: "Open Latest Narrative Lab",
                subtitle: "Open latest narrative lab",
                systemImage: "text.bubble",
                group: .open,
                keywords: ["open", "latest", "narrative", "story"]
            ) { [weak self] in
                self?.openLatestNarrativeLab()
            },
            CommandPaletteAction(
                id: "open-latest-spotlight-pack",
                title: "Open Latest Spotlight Pack",
                subtitle: "Open latest spotlight pack",
                systemImage: "megaphone",
                group: .open,
                keywords: ["open", "latest", "spotlight", "draft"]
            ) { [weak self] in
                self?.openLatestSpotlightPack()
            },
            CommandPaletteAction(
                id: "open-latest-launch-day-script",
                title: "Open Latest Launch Day Script",
                subtitle: "Open latest launch day script",
                systemImage: "flag.checkered.2.crossed",
                group: .open,
                keywords: ["open", "latest", "launch", "script", "timeline"]
            ) { [weak self] in
                self?.openLatestLaunchDayScript()
            },
            CommandPaletteAction(
                id: "open-latest-launch-control-hub",
                title: "Open Launch Control Hub",
                subtitle: Self.launchControlHubActionSubtitle(
                    availableArtifacts: launchControlHubStatus.availableArtifacts,
                    totalArtifacts: launchControlHubStatus.totalArtifacts,
                    newestArtifactAgeMinutes: launchControlHubStatus.newestArtifactAgeMinutes,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "square.stack.3d.up",
                group: .open,
                keywords: [
                    "open",
                    "latest",
                    "launch",
                    "control",
                    "hub",
                    "brief",
                    "snapshot",
                    "rescue",
                    "burst",
                    "countdown"
                ]
            ) { [weak self] in
                self?.openLatestLaunchControlHub()
            },
            CommandPaletteAction(
                id: "open-latest-launch-countdown",
                title: "Open Latest Launch Countdown",
                subtitle: Self.launchRescueSnapshotActionSubtitle(
                    "Open latest launch countdown",
                    followupMomentumBadge: nil,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "timer",
                group: .open,
                keywords: ["open", "latest", "launch", "countdown", "timeline"]
            ) { [weak self] in
                self?.openLatestLaunchCountdown()
            },
            CommandPaletteAction(
                id: "open-latest-launch-rescue-burst",
                title: "Open Latest Launch Rescue Burst",
                subtitle: Self.launchRescueSnapshotActionSubtitle(
                    "Open latest launch rescue burst",
                    followupMomentumBadge: nil,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "bolt.shield",
                group: .open,
                keywords: ["open", "latest", "launch", "rescue", "burst"]
            ) { [weak self] in
                self?.openLatestLaunchRescueBurst()
            },
            CommandPaletteAction(
                id: "open-latest-launch-rescue-snapshot",
                title: "Open Latest Launch Rescue Snapshot",
                subtitle: Self.launchRescueSnapshotActionSubtitle(
                    "Open latest launch rescue snapshot",
                    followupMomentumBadge: nil,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "doc.text",
                group: .open,
                keywords: ["open", "latest", "launch", "rescue", "snapshot", "status"]
            ) { [weak self] in
                self?.openLatestLaunchRescueSnapshot()
            },
            CommandPaletteAction(
                id: "open-latest-launch-control-brief",
                title: "Open Latest Launch Control Brief",
                subtitle: Self.launchControlBriefActionSubtitle(
                    "Open latest launch control brief",
                    followupMomentumBadge: nil,
                    routeBadge: launchRescueFollowupRouteBadge,
                    selfHealAttentionBadge: launchRescueSelfHealAttentionSnapshot?.signalBadge.title
                ),
                systemImage: "list.bullet.rectangle.portrait",
                group: .open,
                keywords: ["open", "latest", "launch", "control", "brief", "status"]
            ) { [weak self] in
                self?.openLatestLaunchControlBrief()
            },
            CommandPaletteAction(
                id: "open-latest-breakthrough-forecast",
                title: "Open Latest Breakthrough Forecast",
                subtitle: "Open latest breakthrough forecast",
                systemImage: "chart.line.uptrend.xyaxis.circle",
                group: .open,
                keywords: ["open", "latest", "forecast"]
            ) { [weak self] in
                self?.openLatestBreakthroughForecast()
            },
            CommandPaletteAction(
                id: "open-latest-morning-brief",
                title: "Open Latest Morning Brief",
                subtitle: "Open latest morning brief",
                systemImage: "sun.max",
                group: .open,
                keywords: ["open", "latest", "morning"]
            ) { [weak self] in
                self?.openLatestMorningBrief()
            },
            CommandPaletteAction(
                id: "open-latest-midday-brief",
                title: "Open Latest Midday Brief",
                subtitle: "Open latest midday brief",
                systemImage: "sun.max.circle",
                group: .open,
                keywords: ["open", "latest", "midday"]
            ) { [weak self] in
                self?.openLatestMiddayBrief()
            },
            CommandPaletteAction(
                id: "open-latest-evening-brief",
                title: "Open Latest Evening Brief",
                subtitle: "Open latest evening brief",
                systemImage: "moon.stars",
                group: .open,
                keywords: ["open", "latest", "evening"]
            ) { [weak self] in
                self?.openLatestEveningBrief()
            },
            CommandPaletteAction(
                id: "open-latest-escalation-nudge",
                title: "Open Latest Escalation Nudge",
                subtitle: "Open latest escalation nudge",
                systemImage: "exclamationmark.triangle.badge.clock",
                group: .open,
                keywords: ["open", "latest", "escalation"]
            ) { [weak self] in
                self?.openLatestEscalationNudge()
            },
            CommandPaletteAction(
                id: "open-fame-snapshot-folder",
                title: "Open Fame Snapshot Folder",
                subtitle: "Reveal saved sprint snapshots",
                systemImage: "folder",
                group: .open,
                keywords: ["fame", "snapshot", "folder", "open", "reveal"]
            ) { [weak self] in
                self?.openFameSnapshotFolder()
            },
            CommandPaletteAction(
                id: "copy-win-card",
                title: "Copy Win Card",
                subtitle: "Copy visual share card",
                systemImage: "photo",
                group: .support,
                keywords: ["win", "card", "image", "share"]
            ) { [weak self] in
                self?.copyWinCard()
            },
            CommandPaletteAction(
                id: "copy-setup-guide",
                title: "Copy Setup Guide",
                subtitle: "Copy setup/status markdown",
                systemImage: "checkmark.seal.text.page",
                group: .support,
                keywords: ["setup", "guide", "status", "onboarding"]
            ) { [weak self] in
                self?.copySetupGuide()
            },
            CommandPaletteAction(
                id: "setup-checklist",
                title: "Setup Checklist",
                subtitle: "Open setup guide",
                systemImage: "checklist",
                group: .settings,
                keywords: ["setup", "checklist", "onboarding"]
            ) { [weak self] in
                guard let self else { return }
                self.setupChecklistWindow.show()
                self.recordActivity(category: "setup", detail: "open-setup-checklist")
            },
            CommandPaletteAction(
                id: "settings",
                title: "Settings",
                subtitle: "Open app settings",
                systemImage: "gearshape",
                group: .settings
            ) { [weak self] in
                self?.settingsWindow.show()
            },
            CommandPaletteAction(
                id: "stop",
                title: "Stop Speech",
                subtitle: "Stop reading and playback",
                systemImage: "stop.fill",
                group: .core
            ) { [weak self] in
                self?.stopSpeech()
            }
        ]

        actions.insert(fameNextMoveDraftPackAction(), at: 0)
        actions.insert(fameNextMoveCadenceExecutionKitAction(), at: 0)
        actions.insert(fameCadenceAutopilotLoopAction(), at: 0)
        actions.insert(fameCadenceMomentumBriefAction(), at: 0)
        actions.insert(copyFameCadenceSharePackAction(), at: 0)
        actions.insert(copyFameCadenceShareLineAction(), at: 0)
        actions.insert(fameCadenceCelebrationDemoAction(), at: 0)
        actions.insert(fameNextMoveAction(), at: 0)
        if let onboardingAction = fameOnboardingNudgeAction() {
            actions.insert(onboardingAction, at: 0)
        }
        if let onboardingScorecardAction = fameOnboardingScorecardAction() {
            actions.insert(onboardingScorecardAction, at: 0)
        }
        if let onboardingDailyBriefAction = fameOnboardingDailyBriefAction() {
            actions.insert(onboardingDailyBriefAction, at: 0)
        }
        if let onboardingGapAction = fameOnboardingGapAction() {
            actions.insert(onboardingGapAction, at: 0)
        }

        if let pulseAlertAction = famePulseAlertAction() {
            actions.insert(pulseAlertAction, at: 0)
        }
        if let launchControlHealthAction = fameLaunchControlHealthAction() {
            actions.insert(launchControlHealthAction, at: 0)
        }
        if let launchCountdownAlertAction = fameLaunchCountdownAlertAction() {
            actions.insert(launchCountdownAlertAction, at: 0)
        }
        if let launchRecoveryNextAction = fameLaunchRecoveryNextAction() {
            actions.insert(launchRecoveryNextAction, at: 0)
        }
        if let launchThresholdAlertsRecoveryAction = fameLaunchThresholdAlertsRecoveryAction() {
            actions.insert(launchThresholdAlertsRecoveryAction, at: 0)
        }
        if let launchThresholdAlertsSnoozeReminderContext = fameLaunchThresholdAlertsSnoozeReminderContext() {
            actions.insert(
                fameLaunchThresholdAlertsSnoozeReminderExtendAction(
                    context: launchThresholdAlertsSnoozeReminderContext
                ),
                at: 0
            )
            actions.insert(
                fameLaunchThresholdAlertsSnoozeReminderAction(
                    context: launchThresholdAlertsSnoozeReminderContext
                ),
                at: 0
            )
        }
        if let fameExceptionalLoopRecoveryLaneAction = fameExceptionalLoopRecoveryLaneAction() {
            actions.insert(fameExceptionalLoopRecoveryLaneAction, at: 0)
        }
        if let fameExceptionalLoopAction = fameExceptionalLoopAction() {
            actions.insert(fameExceptionalLoopAction, at: 0)
        }
        if let launchRescueAutoSelfHealAttentionAction = fameLaunchRescueAutoSelfHealAttentionAction(
            triggerReason: launchRescueAutoTriggerReason
        ) {
            actions.insert(launchRescueAutoSelfHealAttentionAction, at: 0)
        }

        return actions
    }

    func commandPaletteActionIDsForTesting() -> [String] {
        commandPaletteActions().map(\.id)
    }

    func commandPaletteActionTitleForTesting(id: String) -> String? {
        commandPaletteActions().first { $0.id == id }?.title
    }

    func commandPaletteActionSubtitleForTesting(id: String) -> String? {
        commandPaletteActions().first { $0.id == id }?.subtitle
    }

    func commandPaletteActionSignalBadgeTitleForTesting(id: String) -> String? {
        commandPaletteActions().first { $0.id == id }?.signalBadge?.title
    }

    func commandPaletteActionSignalBadgeToneForTesting(id: String) -> String? {
        commandPaletteActions().first { $0.id == id }?.signalBadge?.tone.rawValue
    }

    func commandPaletteActionSignalBadgeHelpTextForTesting(id: String) -> String? {
        commandPaletteActions().first { $0.id == id }?.signalBadge?.helpText
    }

    func commandPaletteActionRecommendationPanelModelForTesting(
        id: String
    ) -> CommandPaletteAction.RecommendationPanelModel? {
        guard let action = commandPaletteActions().first(where: { $0.id == id }) else {
            return nil
        }
        return CommandPaletteAction.recommendationPanelModel(for: action)
    }

    func commandPaletteActionIsEnabledForTesting(id: String) -> Bool? {
        commandPaletteActions().first { $0.id == id }?.isEnabled
    }

    func commandPaletteActionDisabledReasonForTesting(id: String) -> String? {
        guard let action = commandPaletteActions().first(where: { $0.id == id }) else {
            return nil
        }
        return action.isEnabled ? nil : action.disabledReason
    }

    func launchRescueAutoMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueAutoMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueAutoMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueAutoMenuStatusToolTip(now: now, defaults: defaults)
    }

    func launchRescueFollowupNowMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueFollowupNowMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueFollowupNowMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueFollowupNowMenuStatusToolTip(now: now, defaults: defaults)
    }

    func launchControlHubRunMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchControlHubRunMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchControlHubRunMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchControlHubRunMenuStatusToolTip(now: now, defaults: defaults)
    }

    func launchControlHubOpenMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchControlHubOpenMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchControlBriefRunMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchControlBriefRunMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchControlBriefOpenMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchControlBriefOpenMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchControlBriefCopyMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchControlBriefCopyMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueSnapshotOpenMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueSnapshotOpenMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueSnapshotCopyMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueSnapshotMenuTitle(now: now, defaults: defaults)
    }

    func launchCountdownRunMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchCountdownRunMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchCountdownOpenMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchCountdownOpenMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueBurstRunMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueBurstRunMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueBurstOpenMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueBurstOpenMenuStatusTitle(now: now, defaults: defaults)
    }

    func autoOpsBundleMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        autoOpsBundleMenuStatusTitle(now: now, defaults: defaults)
    }

    func autoOpsBundleMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        autoOpsBundleMenuStatusToolTip(now: now, defaults: defaults)
    }

    func autoOpsBundleReaderPillStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        autoOpsBundleMenuStatusTitle(now: now, defaults: defaults)
    }

    func autoOpsBundleReaderPillStatusSubtitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        autoOpsBundleMenuStatusToolTip(now: now, defaults: defaults)
    }

    func launchRescueAutoReaderPillStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueAutoMenuStatusTitle(now: now, defaults: defaults)
    }

    func launchRescueAutoReaderPillStatusSubtitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        launchRescueAutoMenuStatusToolTip(now: now, defaults: defaults)
    }

    func buildFameMenuForTesting() {
        _ = makeFameMenuItem()
    }

    func refreshLaunchRescueAutoMenuStatusForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        updateLaunchRescueAutoMenuStatus(now: now, defaults: defaults)
    }

    func launchControlHubOpenMenuRenderedTitlesForTesting() -> (
        launchControlMenuTitle: String?,
        fameMenuTitle: String?
    ) {
        (
            launchControlMenuTitle: fameLaunchControlHubOpenMenuItem?.title,
            fameMenuTitle: fameOpenLatestLaunchControlHubMenuItem?.title
        )
    }

    func autoOpsBundleMenuStatusRenderedTitleForTesting() -> String? {
        fameAutoOpsBundleStatusMenuItem?.title
    }

    func autoOpsBundleMenuStatusRenderedToolTipForTesting() -> String? {
        fameAutoOpsBundleStatusMenuItem?.toolTip
    }

    func launchControlBriefMenuRenderedTitlesForTesting() -> (
        runTitle: String?,
        openTitle: String?,
        copyTitle: String?
    ) {
        (
            runTitle: fameLaunchControlBriefRunMenuItem?.title,
            openTitle: fameLaunchControlBriefOpenMenuItem?.title,
            copyTitle: fameLaunchControlBriefCopyMenuItem?.title
        )
    }

    func launchRescueSnapshotMenuRenderedTitlesForTesting() -> (
        openTitle: String?,
        copyTitle: String?,
        fameOpenTitle: String?
    ) {
        (
            openTitle: fameLaunchRescueSnapshotOpenMenuItem?.title,
            copyTitle: fameLaunchRescueSnapshotMenuItem?.title,
            fameOpenTitle: fameOpenLatestLaunchRescueSnapshotMenuItem?.title
        )
    }

    func launchCountdownAndBurstMenuRenderedTitlesForTesting() -> (
        countdownRunTitle: String?,
        countdownOpenTitle: String?,
        rescueBurstRunTitle: String?,
        rescueBurstOpenTitle: String?
    ) {
        (
            countdownRunTitle: fameLaunchCountdownRunMenuItem?.title,
            countdownOpenTitle: fameLaunchCountdownOpenMenuItem?.title,
            rescueBurstRunTitle: fameLaunchRescueBurstRunMenuItem?.title,
            rescueBurstOpenTitle: fameLaunchRescueBurstOpenMenuItem?.title
        )
    }

    func fameExceptionalLoopMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopMenuStatusToolTip(now: now, defaults: defaults)
    }

    func fameExceptionalLoopAutoRecoveryLaneMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopAutoRecoveryLaneMenuStatus(now: now, defaults: defaults).title
    }

    func fameExceptionalLoopAutoRecoveryLaneMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopAutoRecoveryLaneMenuStatus(now: now, defaults: defaults).toolTip
    }

    func fameExceptionalLoopLatestRecapStatusTitleForTesting() -> String {
        fameExceptionalLoopLatestRecapStatus().title
    }

    func fameExceptionalLoopLatestRecapStatusToolTipForTesting() -> String {
        fameExceptionalLoopLatestRecapStatus().toolTip
    }

    func fameExceptionalLoopLatestRecapStatusIsEnabledForTesting() -> Bool {
        fameExceptionalLoopLatestRecapStatus().isEnabled
    }

    func fameExceptionalLoopLatestRecapCommandPaletteActionStateForTesting(
        hasSavedRecap: Bool
    ) -> (
        subtitle: String,
        isEnabled: Bool,
        disabledReason: String
    ) {
        Self.fameExceptionalLoopLatestRecapCommandPaletteActionState(
            status: Self.fameExceptionalLoopLatestRecapStatus(hasSavedRecap: hasSavedRecap)
        )
    }

    func fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummaryForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let context = fameExceptionalLoopAutoRecoveryLaneTuningContext(now: now, defaults: defaults)
        return Self.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
            recommendation: context.recommendation,
            currentMissesRequired: context.missesRequired,
            currentFailureStreakRequired: context.failureStreakRequired,
            currentCooldownMinutes: context.cooldownMinutes
        )
    }

    func fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusTitleForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            now: now,
            defaults: defaults
        ).title
    }

    func fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusToolTipForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            now: now,
            defaults: defaults
        ).toolTip
    }

    func fameExceptionalLoopAutoRecoveryLaneTuningMenuStatusIsEnabledForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            now: now,
            defaults: defaults
        ).isEnabled
    }

    func fameExceptionalLoopOutcomeTuningResetStatusTitleForTesting(
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopOutcomeTuningResetStatus(defaults: defaults).title
    }

    func fameExceptionalLoopOutcomeTuningResetStatusToolTipForTesting(
        defaults: UserDefaults = .standard
    ) -> String {
        fameExceptionalLoopOutcomeTuningResetStatus(defaults: defaults).toolTip
    }

    func fameExceptionalLoopOutcomeTuningResetStatusIsEnabledForTesting(
        defaults: UserDefaults = .standard
    ) -> Bool {
        fameExceptionalLoopOutcomeTuningResetStatus(defaults: defaults).isEnabled
    }

    func runFameExceptionalLoopAutoRecoveryLaneAutoTuneForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        runFameExceptionalLoopAutoRecoveryLaneAutoTune(now: now, defaults: defaults)
    }

    func runFameExceptionalLoopAutoRecoveryLaneAutoTuneFromSettingsForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        runFameExceptionalLoopAutoRecoveryLaneAutoTuneFromSettings(
            now: now,
            defaults: defaults
        )
    }

    func runFameExceptionalLoopRecoveryLaneNowFromSettingsForTesting() {
        runFameExceptionalLoopRecoveryLaneNowFromSettings()
    }

    @discardableResult
    func runFameExceptionalLoopHealthRecommendedActionFromSettingsForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        shouldExecuteCommand: Bool = false
    ) -> String {
        runFameExceptionalLoopHealthRecommendedActionFromSettings(
            now: now,
            defaults: defaults,
            shouldExecuteCommand: shouldExecuteCommand
        )
    }

    func openLatestFameExceptionalLoopRecapFromSettingsForTesting() {
        openLatestFameExceptionalLoopRecapFromSettings()
    }

    func resetFameExceptionalLoopOutcomeTuningFromSettingsForTesting(
        defaults: UserDefaults = .standard
    ) {
        resetFameExceptionalLoopOutcomeTuningFromSettings(defaults: defaults)
    }

    func runFameLaunchControlBriefForTesting(now: Date = Date()) {
        runFameLaunchControlBrief(now: now)
    }

    @discardableResult
    func runFameLaunchControlHubForTesting(
        source: String = "manual",
        announce: Bool = true,
        now: Date = Date()
    ) -> Bool {
        runFameLaunchControlHub(source: source, announce: announce, now: now)
    }

    func runFameLaunchRescueSnapshotForTesting(now: Date = Date()) {
        runFameLaunchRescueSnapshot(now: now)
    }

    func runFameLaunchCountdownForTesting() {
        runFameLaunchCountdown()
    }

    @discardableResult
    func runFameLaunchRescueBurstForTesting(
        source: String = "manual",
        announce: Bool = true,
        now: Date = Date()
    ) -> Bool {
        runFameLaunchRescueBurst(
            source: source,
            announce: announce,
            now: now
        )
    }

    func runWarRoomForTesting() {
        runWarRoom()
    }

    func copyFameLaunchControlBriefForTesting(now: Date = Date()) {
        copyFameLaunchControlBrief(now: now)
    }

    func copyFameLaunchRescueSnapshotForTesting(now: Date = Date()) {
        copyFameLaunchRescueSnapshot(now: now)
    }

    func runFameOnboardingNudgeForTesting(now: Date = Date()) {
        runFameOnboardingNudge(now: now)
    }

    func runFameOnboardingDailyBriefForTesting(now: Date = Date()) {
        runFameOnboardingDailyBrief(now: now)
    }

    func runFameOnboardingScorecardForTesting(now: Date = Date()) {
        runFameOnboardingScorecard(now: now)
    }

    func runFameCadenceMomentumBriefForTesting(now: Date = Date()) {
        runFameCadenceMomentumBrief(now: now)
    }

    func copyFameCadenceShareLineForTesting(now: Date = Date()) {
        copyFameCadenceShareLine(now: now)
    }

    func copyFameCadenceSharePackForTesting(now: Date = Date()) {
        copyFameCadenceSharePack(now: now)
    }

    func copyWinRecapForTesting() {
        copyWinRecap()
    }

    func copyLaunchKitForTesting() {
        copyLaunchKit()
    }

    func copyFameBoardForTesting() {
        copyFameBoard()
    }

    func copyFameSprintForTesting() {
        copyFameSprint()
    }

    func copyFamePackForTesting() {
        copyFamePack()
    }

    func copyFounderCommandPresetsForTesting() {
        copyFounderCommandPresets()
    }

    func copySetupGuideForTesting() {
        copySetupGuide()
    }

    func runFamePulseNudgeForTesting() {
        runFamePulseNudge()
    }

    func runFameSprintForTesting() {
        runFameSprint()
    }

    func runFameMorningBriefForTesting() {
        runFameMorningBrief()
    }

    func runFameWeeklyRollupForTesting() {
        runFameWeeklyRollup()
    }

    func runFameMiddayBriefForTesting() {
        runFameMiddayBrief()
    }

    func runFameEveningBriefForTesting() {
        runFameEveningBrief()
    }

    func runFameOpsBundleForTesting() {
        runFameOpsBundle()
    }

    func runFameDailyCheckpointForTesting() {
        runFameDailyCheckpoint()
    }

    func runFameDailyScorecardForTesting() {
        runFameDailyScorecard()
    }

    func runFame24hQueueForTesting() {
        runFame24hQueue()
    }

    func runFameCommandCenterForTesting() {
        runFameCommandCenter()
    }

    func runFameBreakthroughForecastForTesting() {
        runFameBreakthroughForecast()
    }

    func runFameLaunchDayScriptForTesting() {
        runFameLaunchDayScript()
    }

    func runFameEscalationNudgeForTesting() {
        runFameEscalationNudge()
    }

    func runFameRecoverySprintForTesting() {
        runFameRecoverySprint()
    }

    func runFameRecoveryChecklistForTesting() {
        runFameRecoveryChecklist()
    }

    func runFameRecoveryProofPackForTesting() {
        runFameRecoveryProofPack()
    }

    func runFameRiskTimelineForTesting() {
        runFameRiskTimeline()
    }

    func runFameOperatorDashboardForTesting() {
        runFameOperatorDashboard()
    }

    func runFameNarrativeLabForTesting() {
        runFameNarrativeLab()
    }

    func runFameSpotlightPackForTesting() {
        runFameSpotlightPack()
    }

    func runFameNextMoveForTesting(commandID: String) {
        runFameNextMove(commandID: commandID)
    }

    func runFameNextMoveCopyDraftPackForTesting(commandID: String) {
        runFameNextMove(commandID: commandID, followup: .copyDraftPack)
    }

    func runFameNextMoveCadenceExecutionKitForTesting(commandID: String) {
        runFameNextMove(commandID: commandID, followup: .cadenceExecutionKit)
    }

    func runFameAutoBundleStatusActionForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        runNowHandler: (() -> Void)? = nil
    ) {
        runFameAutoBundleStatusAction(
            now: now,
            defaults: defaults,
            runNowHandler: runNowHandler
        )
    }

    func handleReaderAutoOpsBundleStatusTapForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        runNowHandler: (() -> Void)? = nil
    ) {
        handleReaderAutoOpsBundleStatusTap(
            now: now,
            defaults: defaults,
            runNowHandler: runNowHandler,
            emitFeedback: false
        )
    }

    func runFameLaunchRescueBurstAutoStatusActionForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        latestLaunchRescueBurstURLProvider: (() throws -> URL?)? = nil,
        runNowHandler: (() -> Void)? = nil
    ) {
        runFameLaunchRescueBurstAutoStatusAction(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: latestLaunchRescueBurstURLProvider,
            runNowHandler: runNowHandler
        )
    }

    func handleReaderLaunchRescueAutoStatusTapForTesting(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        latestLaunchRescueBurstURLProvider: (() throws -> URL?)? = nil,
        runNowHandler: (() -> Void)? = nil
    ) {
        handleReaderLaunchRescueAutoStatusTap(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: latestLaunchRescueBurstURLProvider,
            runNowHandler: runNowHandler,
            emitFeedback: false
        )
    }

    func readerFeedbackForTesting() -> (
        errorText: String,
        petMessage: String,
        petMood: PetMood
    ) {
        (
            errorText: readerState.errorText,
            petMessage: readerState.petMessage,
            petMood: readerState.petMood
        )
    }

    func bestChannelDraftCopyFeedbackForTesting() -> (
        errorText: String,
        petMessage: String,
        petMood: PetMood
    ) {
        readerFeedbackForTesting()
    }

    @discardableResult
    func copyLatestNextMoveBestChannelDraftForTesting(
        handoffMarkdown: String?
    ) -> NextMoveBestChannelDraftCopyOutcome {
        let outcome = Self.nextMoveBestChannelDraftCopyOutcome(handoffMarkdown: handoffMarkdown)
        return applyNextMoveBestChannelDraftCopyOutcome(
            outcome,
            activityDetailBase: "copy-next-move-best-channel-draft"
        )
    }

    @discardableResult
    func copyLatestNextMoveBestChannelLaunchPackForTesting(
        handoffMarkdown: String?
    ) -> NextMoveBestChannelLaunchPackCopyOutcome {
        let outcome = Self.nextMoveBestChannelLaunchPackCopyOutcome(handoffMarkdown: handoffMarkdown)
        return applyNextMoveBestChannelLaunchPackCopyOutcome(
            outcome,
            activityDetailBase: "copy-next-move-best-channel-launch-pack"
        )
    }

    func copyLatestNextMoveDraftPackForTesting() {
        copyLatestNextMoveDraftPack()
    }

    func copyLatestNextMoveCadenceStepForTesting() {
        copyLatestNextMoveCadenceStep()
    }

    func copyLatestNextMoveCadencePostForTesting() {
        copyLatestNextMoveCadencePost()
    }

    func copyLatestNextMoveCadencePostQueueForTesting() {
        copyLatestNextMoveCadencePostQueue()
    }

    func copyLatestNextMoveCadenceExecutionKitForTesting() {
        copyLatestNextMoveCadenceExecutionKit()
    }

    func copyLatestNextMoveReplyLadderForTesting() {
        copyLatestNextMoveReplyLadder()
    }

    func copyLatestNextMoveLaunchNowSequenceForTesting() {
        copyLatestNextMoveLaunchNowSequence()
    }

    func copyLatestNextMoveChannelDraftForTesting(_ channel: NextMoveDraftChannel) {
        copyLatestNextMoveChannelDraft(channel)
    }

    func copyLatestNextMoveBestChannelLaunchPackForTesting() {
        copyLatestNextMoveBestChannelLaunchPack()
    }

    func copyLatestNextMoveBestChannelDraftForTesting() {
        copyLatestNextMoveBestChannelDraft()
    }

    private func latestNextMoveHandoffMarkdownForCommandPalette() -> String? {
        guard let handoffURL = try? FameSnapshotArchive.latestNextMoveHandoffURL() else {
            return nil
        }

        return try? String(contentsOf: handoffURL, encoding: .utf8)
    }

    private func fameNextMoveAction() -> CommandPaletteAction {
        let commandID = Self.fameNextMoveCommandID(
            signal: famePulseAlertSignal(),
            transition: famePulseLatestTransition(),
            scorecard: fameDailyScorecardState()
        )

        let subtitle: String
        let systemImage: String
        switch commandID {
        case "run-fame-escalation-nudge":
            subtitle = "Escalation detected."
            systemImage = "exclamationmark.triangle.badge.clock"
        case "run-fame-recovery-sprint":
            subtitle = "Recovery sprint now."
            systemImage = "flame.fill"
        case "run-fame-sprint-snapshot":
            subtitle = "Save first snapshot."
            systemImage = "internaldrive"
        default:
            subtitle = "Run daily checkpoint."
            systemImage = "calendar.badge.clock"
        }

        return CommandPaletteAction(
            id: "run-fame-next-move",
            title: Self.fameNextMoveMenuTitle(commandID: commandID),
            subtitle: subtitle,
            systemImage: systemImage,
            group: .support,
            keywords: ["fame", "next", "move", "autopilot", "recovery", "checkpoint", "snapshot", "escalation"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameNextMove(commandID: commandID)
        }
    }

    private func fameNextMoveDraftPackAction() -> CommandPaletteAction {
        let commandID = Self.fameNextMoveCommandID(
            signal: famePulseAlertSignal(),
            transition: famePulseLatestTransition(),
            scorecard: fameDailyScorecardState()
        )
        let commandLabel = Self.fameNextMoveCommandLabel(commandID)

        return CommandPaletteAction(
            id: "run-fame-next-move-copy-drafts",
            title: "Run Next Move + Copy Draft Pack",
            subtitle: "Execute \(commandLabel), then copy ranked drafts + follow-ups + hook variants + cadence",
            systemImage: "paperplane.circle.fill",
            group: .support,
            keywords: ["run", "next", "move", "copy", "draft", "pack", "fame", "x", "bluesky", "linkedin", "checklist"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameNextMove(commandID: commandID, followup: .copyDraftPack)
        }
    }

    private func fameNextMoveCadenceExecutionKitAction() -> CommandPaletteAction {
        let commandID = Self.fameNextMoveCommandID(
            signal: famePulseAlertSignal(),
            transition: famePulseLatestTransition(),
            scorecard: fameDailyScorecardState()
        )
        let commandLabel = Self.fameNextMoveCommandLabel(commandID)

        return CommandPaletteAction(
            id: "run-fame-next-move-cadence-execution-kit",
            title: "Run Next Move + Cadence Execution Kit",
            subtitle: "Execute \(commandLabel), then copy cadence post + open queue + reply ladder",
            systemImage: "rocket.fill",
            group: .support,
            keywords: ["run", "next", "move", "cadence", "execution", "kit", "queue", "reply", "ladder", "launch"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameNextMove(commandID: commandID, followup: .cadenceExecutionKit)
        }
    }

    private func fameCadenceAutopilotLoopAction() -> CommandPaletteAction {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())

        return CommandPaletteAction(
            id: "run-fame-cadence-autopilot-loop",
            title: Self.cadenceExecutionKitAutopilotLoopTitle(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best
            ),
            subtitle: Self.cadenceExecutionKitAutopilotLoopSubtitle(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best,
                nextMoveLabel: nextMoveLabel
            ),
            systemImage: Self.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best
            ),
            group: .support,
            keywords: [
                "run", "cadence", "autopilot", "loop", "streak", "momentum", "next", "move",
                "execution", "kit", "fame", "launch"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameCadenceAutopilotLoop()
        }
    }

    private func fameCadenceMomentumBriefAction() -> CommandPaletteAction {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())

        return CommandPaletteAction(
            id: "run-fame-cadence-momentum-brief",
            title: "Run Cadence Momentum Brief",
            subtitle: Self.cadenceExecutionKitMomentumBriefActionSubtitle(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best,
                nextMoveLabel: nextMoveLabel
            ),
            systemImage: Self.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best
            ),
            group: .support,
            keywords: ["run", "cadence", "momentum", "brief", "streak", "next", "move", "fame", "launch", "scorecard"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameCadenceMomentumBrief()
        }
    }

    private func copyFameCadenceShareLineAction() -> CommandPaletteAction {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())
        let momentumTitle = Self.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best
        )

        return CommandPaletteAction(
            id: "copy-fame-cadence-share-line",
            title: "Copy Cadence Share Line",
            subtitle: Self.cadenceExecutionKitMomentumShareLineActionSubtitle(
                momentumTitle: momentumTitle,
                nextMoveLabel: nextMoveLabel
            ),
            systemImage: "quote.bubble",
            group: .support,
            keywords: [
                "copy", "cadence", "share", "line", "momentum", "brief", "fame", "launch", "standup"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.copyFameCadenceShareLine()
        }
    }

    private func copyFameCadenceSharePackAction() -> CommandPaletteAction {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())
        let momentumTitle = Self.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best
        )

        return CommandPaletteAction(
            id: "copy-fame-cadence-share-pack",
            title: "Copy Cadence Share Pack",
            subtitle: Self.cadenceExecutionKitMomentumSharePackActionSubtitle(
                momentumTitle: momentumTitle,
                nextMoveLabel: nextMoveLabel
            ),
            systemImage: "text.justify",
            group: .support,
            keywords: [
                "copy", "cadence", "share", "pack", "momentum", "brief", "fame", "launch", "social", "variants"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.copyFameCadenceSharePack()
        }
    }

    private func fameCadenceCelebrationDemoAction() -> CommandPaletteAction {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let currentIntensity = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
            settings.fameCadenceAutopilotCelebrationIntensity
        )
        let currentTitle = Self.cadenceExecutionKitAutopilotCelebrationIntensityTitle(currentIntensity)
        return CommandPaletteAction(
            id: "run-fame-cadence-celebration-demo",
            title: "Run Cadence Celebration Demo",
            subtitle: Self.cadenceExecutionKitCelebrationDemoActionSubtitle(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best,
                currentIntensityTitle: currentTitle
            ),
            systemImage: "sparkles",
            group: .support,
            keywords: [
                "run", "cadence", "celebration", "demo", "preview", "calm", "balanced", "epic",
                "haptic", "milestone", "autopilot", "fame", "streak"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runCadenceCelebrationDemo()
        }
    }

    private struct FameOnboardingScorecardContext {
        let day: Int
        let windowDays: Int
        let completedDays: Int
        let remainingDays: Int
        let currentStreak: Int
        let bestStreak: Int
        let recommendedCommandID: String
        let backupCommandID: String
    }

    private struct FameOnboardingSuiteArtifacts {
        let dailyBriefURL: URL?
        let scorecardURL: URL?
        let nudgeURL: URL?

        var orderedURLs: [URL] {
            [dailyBriefURL, scorecardURL, nudgeURL].compactMap { $0 }
        }

        var missingArtifactNames: [String] {
            var names: [String] = []
            if dailyBriefURL == nil {
                names.append("daily brief")
            }
            if scorecardURL == nil {
                names.append("scorecard")
            }
            if nudgeURL == nil {
                names.append("nudge")
            }
            return names
        }
    }

    private struct LaunchControlHubArtifacts {
        let launchControlBriefURL: URL?
        let launchRescueSnapshotURL: URL?
        let launchRescueBurstURL: URL?
        let launchCountdownURL: URL?

        var orderedURLs: [URL] {
            [launchControlBriefURL, launchRescueSnapshotURL, launchRescueBurstURL, launchCountdownURL]
                .compactMap { $0 }
        }

        var missingArtifactNames: [String] {
            var names: [String] = []
            if launchControlBriefURL == nil {
                names.append("launch control brief")
            }
            if launchRescueSnapshotURL == nil {
                names.append("launch rescue snapshot")
            }
            if launchRescueBurstURL == nil {
                names.append("launch rescue burst")
            }
            if launchCountdownURL == nil {
                names.append("launch countdown")
            }
            return names
        }
    }

    private struct FameOnboardingGapStatusSignal {
        let missingArtifacts: Int
        let missingArtifactNames: [String]
        let recommendedCommandID: String
    }

    private func fameOnboardingScorecardContext(now: Date = Date()) -> FameOnboardingScorecardContext? {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let windowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            settings.fameOnboardingNudgeWindowDays
        )
        let onboardingDay = firstRunGuide.fameOnboardingDay(now: now)
        let completedDays = firstRunGuide.fameOnboardingCompletedDays(onboardingWindowDays: windowDays)
        guard Self.isFameOnboardingScorecardActionEligible(
            fameOnboardingEnabled: settings.fameOnboardingNudgeEnabled,
            cadenceBestStreak: cadenceStreak.best,
            onboardingDay: onboardingDay,
            completedDays: completedDays,
            onboardingWindowDays: windowDays
        ) else { return nil }
        let remainingDays = firstRunGuide.fameOnboardingRemainingDays(onboardingWindowDays: windowDays)

        let plan = Self.fameOnboardingNudgePlan(
            day: onboardingDay,
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best,
            windowDays: windowDays
        )

        return FameOnboardingScorecardContext(
            day: plan.day,
            windowDays: windowDays,
            completedDays: completedDays,
            remainingDays: remainingDays,
            currentStreak: max(0, cadenceStreak.current),
            bestStreak: max(0, cadenceStreak.best),
            recommendedCommandID: plan.primaryCommandID,
            backupCommandID: plan.backupCommandID
        )
    }

    private func fameOnboardingScorecardAction(now: Date = Date()) -> CommandPaletteAction? {
        guard let context = fameOnboardingScorecardContext(now: now) else { return nil }

        return CommandPaletteAction(
            id: "run-fame-onboarding-scorecard",
            title: Self.fameOnboardingScorecardActionTitle(
                day: context.day,
                windowDays: context.windowDays
            ),
            subtitle: Self.fameOnboardingScorecardActionSubtitle(
                day: context.day,
                windowDays: context.windowDays,
                completedDays: context.completedDays,
                recommendedCommandID: context.recommendedCommandID
            ),
            systemImage: "chart.bar.fill",
            group: .support,
            keywords: [
                "fame", "onboarding", "scorecard", "first-week", "cadence", "progress",
                "streak", "momentum", "plan", "coach"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameOnboardingScorecard()
        }
    }

    private func fameOnboardingDailyBriefAction(now: Date = Date()) -> CommandPaletteAction? {
        guard let context = fameOnboardingScorecardContext(now: now) else { return nil }

        return CommandPaletteAction(
            id: "run-fame-onboarding-daily-brief",
            title: Self.fameOnboardingDailyBriefActionTitle(
                day: context.day,
                windowDays: context.windowDays
            ),
            subtitle: Self.fameOnboardingDailyBriefActionSubtitle(
                day: context.day,
                windowDays: context.windowDays,
                completedDays: context.completedDays,
                recommendedCommandID: context.recommendedCommandID
            ),
            systemImage: "square.stack.3d.up.fill",
            group: .support,
            keywords: [
                "fame", "onboarding", "first-week", "daily", "brief", "nudge", "scorecard",
                "cadence", "progress", "artifact", "coach"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameOnboardingDailyBrief()
        }
    }

    private func fameOnboardingGapAction(now: Date = Date()) -> CommandPaletteAction? {
        guard let context = fameOnboardingScorecardContext(now: now) else { return nil }
        guard let artifacts = try? latestOnboardingSuiteArtifacts() else { return nil }

        let missingArtifactNames = artifacts.missingArtifactNames
        guard !missingArtifactNames.isEmpty else { return nil }

        guard let recommendedCommandID = Self.fameOnboardingGapRecommendedCommandID(
            hasDailyBrief: artifacts.dailyBriefURL != nil,
            hasScorecard: artifacts.scorecardURL != nil,
            hasNudge: artifacts.nudgeURL != nil
        ) else { return nil }

        let newestArtifactAgeMinutes = Self.fameOnboardingSuiteNewestArtifactAgeMinutes(
            artifactURLs: artifacts.orderedURLs,
            now: now
        )

        return CommandPaletteAction(
            id: "run-fame-onboarding-fill-gap",
            title: Self.fameOnboardingGapActionTitle(recommendedCommandID: recommendedCommandID),
            subtitle: Self.fameOnboardingGapActionSubtitle(
                missingArtifactNames: missingArtifactNames,
                day: context.day,
                windowDays: context.windowDays,
                newestArtifactAgeMinutes: newestArtifactAgeMinutes,
                recommendedCommandID: recommendedCommandID
            ),
            systemImage: "sparkles.square.filled.on.square",
            group: .support,
            keywords: [
                "fame", "onboarding", "gap", "missing", "daily", "brief", "scorecard",
                "nudge", "artifact", "fix", "recovery", "first-week"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameOnboardingFillGap(recommendedCommandID: recommendedCommandID)
        }
    }

    private func fameOnboardingNudgeAction(now: Date = Date()) -> CommandPaletteAction? {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        guard firstRunGuide.shouldShowFameOnboardingNudge(
            now: now,
            cadenceBestStreak: cadenceStreak.best,
            fameOnboardingEnabled: settings.fameOnboardingNudgeEnabled,
            onboardingWindowDays: settings.fameOnboardingNudgeWindowDays
        ) else { return nil }

        let onboardingDay = firstRunGuide.fameOnboardingDay(now: now)
        let completedDays = firstRunGuide.fameOnboardingCompletedDays(
            onboardingWindowDays: settings.fameOnboardingNudgeWindowDays
        )
        let plan = Self.fameOnboardingNudgePlan(
            day: onboardingDay,
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best,
            windowDays: settings.fameOnboardingNudgeWindowDays
        )

        return CommandPaletteAction(
            id: "run-fame-onboarding-nudge",
            title: Self.fameOnboardingNudgeActionTitle(plan),
            subtitle: Self.fameOnboardingNudgeActionSubtitle(
                plan,
                windowDays: settings.fameOnboardingNudgeWindowDays,
                completedDays: completedDays
            ),
            systemImage: "sparkles.rectangle.stack",
            group: .support,
            keywords: [
                "fame", "onboarding", "first-week", "cadence", "plan", "coach", "guide",
                "streak", "next", "move", "launch", "momentum"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameOnboardingNudge()
        }
    }

    private func fameOnboardingRecoveryQuickRunEnabledActionIDs(now: Date = Date()) -> Set<String> {
        var actionIDs: Set<String> = [
            "run-fame-next-move-cadence-execution-kit",
            "run-fame-cadence-autopilot-loop"
        ]

        if fameOnboardingGapAction(now: now) != nil {
            actionIDs.insert("run-fame-onboarding-fill-gap")
        }
        if fameOnboardingScorecardAction(now: now) != nil {
            actionIDs.insert("run-fame-onboarding-scorecard")
        }
        if fameOnboardingDailyBriefAction(now: now) != nil {
            actionIDs.insert("run-fame-onboarding-daily-brief")
        }
        if fameOnboardingNudgeAction(now: now) != nil {
            actionIDs.insert("run-fame-onboarding-nudge")
        }

        return actionIDs
    }

    private func famePulseAlertAction() -> CommandPaletteAction? {
        guard let signal = famePulseAlertSignal() else { return nil }
        guard signal.riskLevel == "High" || signal.riskLevel == "Critical" else { return nil }

        let transition = famePulseLatestTransition()
        let commandID = Self.famePulseRiskActionCommandID(signal: signal, transition: transition)
        let escalatedNow = commandID == "run-fame-escalation-nudge"
        let title = signal.riskLevel == "Critical"
            ? "Fame Pulse Alert: MUST SHIP"
            : "Fame Pulse Alert: Recovery"
        let autoOpsPhrase = Self.autoOpsBundleEscalationStatusPhrase(
            autoOpsBundleEscalationStatus()
        )
        let subtitle: String
        if let transition, escalatedNow {
            subtitle = "Risk \(signal.riskLevel) · \(transition.fromRiskLevel) -> \(transition.toRiskLevel) · \(autoOpsPhrase) · run escalation nudge"
        } else {
            subtitle = "Risk \(signal.riskLevel) · \(autoOpsPhrase) · run recovery sprint now"
        }
        let systemImage = signal.riskLevel == "Critical"
            ? "exclamationmark.triangle.fill"
            : "bolt.badge.clock"

        return CommandPaletteAction(
            id: "run-fame-pulse-alert",
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            group: .support,
            keywords: ["fame", "pulse", "alert", "risk", "streak", "must-ship", "recovery", "escalation", "transition", "snapshot"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameCommand(commandID: commandID)
        }
    }

    private func fameLaunchCountdownAlertAction() -> CommandPaletteAction? {
        guard let status = latestLaunchCountdownStatus() else { return nil }

        return CommandPaletteAction(
            id: "run-fame-launch-alert",
            title: Self.fameLaunchCountdownAlertTitle(status),
            subtitle: Self.fameLaunchCountdownAlertSubtitle(status),
            systemImage: Self.fameLaunchCountdownAlertSystemImage(status),
            group: .support,
            keywords: ["fame", "launch", "countdown", "next", "action", "timeline", "ship", "overdue", "urgency"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameLaunchCountdown()
        }
    }

    private func fameLaunchControlHealthAction() -> CommandPaletteAction? {
        let launchStatus = latestLaunchCountdownStatus()
        guard launchStatus != nil else { return nil }
        let now = Date()
        let healthInsights = launchControlHealthInsights(now: now)
        let commandID = Self.launchControlHealthActionCommandID(
            launchStatus: launchStatus,
            momentumSignal: healthInsights.momentumSignal
        )
        let pulseStatusTitle = Self.launchControlHealthPulseMenuStatusTitle(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            pulseEnabled: settings.fameLaunchHealthPulseEnabled,
            cooldownSeconds: settings.fameLaunchHealthPulseCooldownSeconds,
            lastPulseAt: launchControlHealthPulseLastAt,
            lastPulseToken: launchControlHealthPulseLastToken,
            now: now
        )
        let transitionCountsStatusTitle = Self.launchControlHealthTransitionCountsMenuStatusTitle(
            watchToRiskCount: healthInsights.transitionCounts.watchToRiskCount,
            riskToReadyCount: healthInsights.transitionCounts.riskToReadyCount,
            averageDeltaTitle: healthInsights.averageDeltaTitle,
            momentumStatusTitle: healthInsights.momentumStatusTitle,
            pressurePersistenceStatusTitle: healthInsights.pressurePersistenceStatusTitle
        )
        let statusTitle = Self.launchControlStatusTitleWithFollowupMomentum(
            "\(pulseStatusTitle) · \(transitionCountsStatusTitle)",
            followupMomentumBadge: launchRescueFollowupMomentumBadgeSnapshot(now: now)
        )

        return CommandPaletteAction(
            id: "run-fame-launch-control-health",
            title: Self.launchControlHealthCardTitle(launchStatus: launchStatus),
            subtitle: Self.launchControlHealthCardSubtitle(
                launchStatus: launchStatus,
                statusTitle: statusTitle,
                commandID: commandID
            ),
            systemImage: Self.launchControlHealthCardSystemImage(launchStatus: launchStatus),
            group: .support,
            keywords: ["launch", "health", "control", "brief", "ready", "watch", "risk", "countdown", "urgency"],
            canFavorite: false
        ) { [weak self] in
            self?.runFameCommand(commandID: commandID)
        }
    }

    private func fameExceptionalLoopPlan(now: Date = Date()) -> FameExceptionalLoopPlan {
        let signal = famePulseAlertSignal()
        let transition = famePulseLatestTransition()
        let scorecard = fameDailyScorecardState()
        let launchStatus = latestLaunchCountdownStatus()
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason()
        let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        let selfHealAttentionIssueToken = Self.launchRescueAutoSelfHealAttentionIssueToken(
            triggerReason: launchRescueAutoTriggerReason,
            activityItems: activityLog.items,
            now: now,
            lastAutoTriggerAt: launchRescueAutoTriggerAt
        )
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let plan = Self.fameExceptionalLoopPlan(
            signal: signal,
            transition: transition,
            scorecard: scorecard,
            launchStatus: launchStatus,
            launchRescueSelfHealAttentionIssueToken: selfHealAttentionIssueToken,
            cadenceCurrentStreak: cadenceStreak.current,
            cadenceBestStreak: cadenceStreak.best
        )
        let outcomeScoreboard = fameExceptionalLoopOutcomeScoreboard(now: now)
        let commandOutcomeScoreboard = fameExceptionalLoopOutcomeScoreboard(
            forCommandToken: Self.fameExceptionalLoopOutcomeFocusToken(plan),
            now: now
        )
        return Self.fameExceptionalLoopPlanWithAdaptiveTuning(
            plan,
            scoreboard: outcomeScoreboard,
            commandScoreboard: commandOutcomeScoreboard
        )
    }

    private func fameExceptionalLoopAction(now: Date = Date()) -> CommandPaletteAction? {
        let plan = fameExceptionalLoopPlan(now: now)
        let outcomeScoreboard = fameExceptionalLoopOutcomeScoreboard(now: now)
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: .standard,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let healthSnapshot = Self.fameExceptionalLoopHealthSnapshot(
            scoreboard: outcomeScoreboard,
            history: windowedCommandHistory
        )

        return CommandPaletteAction(
            id: "run-fame-exceptional-loop",
            title: Self.fameExceptionalLoopActionTitle(plan),
            subtitle: Self.fameExceptionalLoopActionSubtitle(
                plan,
                healthSnapshot: healthSnapshot
            ),
            systemImage: Self.fameExceptionalLoopActionSystemImage(plan),
            group: .support,
            keywords: [
                "fame",
                "exceptional",
                "loop",
                "top-picks",
                "compound",
                "launch",
                "cadence",
                "next",
                "move",
                "momentum"
            ],
            signalBadge: Self.fameExceptionalLoopCommandPaletteSignalBadge(healthSnapshot),
            canFavorite: false
        ) { [weak self] in
            self?.runFameExceptionalLoop()
        }
    }

    private func fameExceptionalLoopRecoveryLaneAction(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> CommandPaletteAction? {
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        guard let topRecoveryLane = Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        ), let recoveryCommandID = Self.fameExceptionalLoopRecoveryLaneCommandID(
            topRecoveryLane.lastFocusToken
        ) else {
            return nil
        }
        let misses = max(0, topRecoveryLane.attempts - topRecoveryLane.successes)
        guard misses >= 2, topRecoveryLane.failureStreak >= 1 else { return nil }
        let title = Self.fameExceptionalLoopCommandTitle(recoveryCommandID)

        return CommandPaletteAction(
            id: "run-fame-exceptional-loop-recovery-lane-now",
            title: "Run Recovery Lane Now: \(title)",
            subtitle: "Top recovery lane \(misses)/\(topRecoveryLane.attempts) misses, streak x\(topRecoveryLane.failureStreak).",
            systemImage: "lifepreserver",
            group: .support,
            keywords: [
                "fame",
                "recovery",
                "lane",
                "exceptional",
                "loop",
                "streak",
                "top-picks",
                "next",
                "action"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameExceptionalLoopRecoveryLaneNow()
        }
    }

    private func fameLaunchRescueAutoSelfHealAttentionAction(
        triggerReason: String?,
        now: Date = Date()
    ) -> CommandPaletteAction? {
        let lastAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        guard let issueToken = Self.launchRescueAutoSelfHealAttentionIssueToken(
            triggerReason: triggerReason,
            activityItems: activityLog.items,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        ), let title = Self.launchRescueAutoSelfHealAttentionActionTitle(
            issueToken: issueToken,
            triggerReason: triggerReason
        ), let subtitle = Self.launchRescueAutoSelfHealAttentionActionSubtitle(
            issueToken: issueToken,
            triggerReason: triggerReason,
            activityItems: activityLog.items,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        ) else { return nil }
        let issueStreak = Self.launchRescueAutoSelfHealAttentionIssueStreakNext(
            currentIssueToken: issueToken,
            previousIssueToken: launchRescueAutoSelfHealAttentionIssueToken,
            previousIssueStreak: launchRescueAutoSelfHealAttentionIssueStreak
        )
        let recommendedActionID = Self.launchRescueAutoSelfHealAttentionRecommendedActionID(
            issueToken: issueToken,
            triggerReason: triggerReason,
            issueStreak: issueStreak,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
        let signalBadge = Self.launchRescueAutoSelfHealAttentionSignalBadge(
            issueToken: issueToken,
            triggerReason: triggerReason,
            issueStreak: issueStreak,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )

        return CommandPaletteAction(
            id: "run-fame-launch-rescue-self-heal-attention",
            title: title,
            subtitle: subtitle,
            systemImage: Self.launchRescueAutoSelfHealAttentionActionSystemImage(
                issueToken: issueToken
            ),
            group: .support,
            keywords: [
                "launch",
                "rescue",
                "self-heal",
                "attention",
                "stale",
                "mismatch",
                "missing",
                "followup",
                "follow-up",
                "priority",
                "top-picks"
            ],
            signalBadge: signalBadge,
            canFavorite: false
        ) { [weak self] in
            guard let self else { return }
            self.runFameCommand(commandID: recommendedActionID)
            self.recordActivity(
                category: "support",
                detail: Self.launchRescueAutoSelfHealAttentionActionActivityDetail(
                    issueToken: issueToken
                )
            )
        }
    }

    private func fameLaunchRecoveryNextAction(now: Date = Date()) -> CommandPaletteAction? {
        let onboardingRecoverySnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        let actionID = Self.fameOnboardingRecoveryQuickRunActionID(
            isFreshRecovery: onboardingRecoverySnapshot.isFresh,
            followupCommandID: onboardingRecoverySnapshot.followupActionID,
            remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts,
            enabledActionIDs: fameOnboardingRecoveryQuickRunEnabledActionIDs(now: now)
        )
        guard let actionID else { return nil }

        let normalizedRemainingArtifacts = max(0, onboardingRecoverySnapshot.remainingArtifacts ?? 0)
        let systemImage: String
        if normalizedRemainingArtifacts > 0 {
            systemImage = "checkmark.seal"
        } else {
            systemImage = "checkmark.seal.fill"
        }

        return CommandPaletteAction(
            id: "run-fame-launch-recovery-next",
            title: Self.launchControlOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                actionID: actionID,
                remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
            ),
            subtitle: Self.launchRecoveryQuickRunCardSubtitle(
                actionID: actionID,
                remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
            ),
            systemImage: systemImage,
            group: .support,
            keywords: [
                "launch", "recovery", "next", "onboarding", "gap", "one-click", "momentum", "followup",
                "shortcut", "keyboard", "cmd1", "command-1", "top-picks"
            ],
            canFavorite: false
        ) { [weak self] in
            self?.runFameOnboardingRecoveryQuickRun(
                actionID: actionID,
                source: .commandPaletteLaunchCard
            )
        }
    }

    private func fameLaunchThresholdAlertsRecoveryAction() -> CommandPaletteAction? {
        guard let status = latestLaunchCountdownStatus(),
              Self.shouldSurfaceFameLaunchThresholdAlertsRecoveryAction(
                  alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
                  launchStatus: status
              ) else { return nil }

        return CommandPaletteAction(
            id: "unmute-fame-launch-threshold-alerts-now",
            title: Self.fameLaunchThresholdAlertsRecoveryTitle(status),
            subtitle: Self.fameLaunchThresholdAlertsRecoverySubtitle(status),
            systemImage: "bell.slash.circle.fill",
            group: .support,
            keywords: ["launch", "threshold", "alerts", "mute", "muted", "unmute", "countdown", "urgency", "hud", "flash"],
            canFavorite: false
        ) { [weak self] in
            self?.toggleFameLaunchThresholdAlerts(source: "launch-alert-card")
        }
    }

    private struct FameLaunchThresholdAlertsSnoozeReminderContext {
        let status: FameLaunchCountdownStatus
        let snoozeMinutesRemaining: Int
        let recommendedMinutes: Int
    }

    private func fameLaunchThresholdAlertsSnoozeReminderContext() -> FameLaunchThresholdAlertsSnoozeReminderContext? {
        guard let status = latestLaunchCountdownStatus(),
              let snoozeMinutesRemaining = fameLaunchThresholdAlertsSnoozeMinutesRemaining(),
              shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
                  status: status,
                  snoozeMinutesRemaining: snoozeMinutesRemaining
              ) else { return nil }

        return FameLaunchThresholdAlertsSnoozeReminderContext(
            status: status,
            snoozeMinutesRemaining: snoozeMinutesRemaining,
            recommendedMinutes: Self.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
                launchStatus: status
            )
        )
    }

    private func fameLaunchThresholdAlertsSnoozeReminderAction(
        context: FameLaunchThresholdAlertsSnoozeReminderContext
    ) -> CommandPaletteAction {
        let action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction = .unmuteNow
        let cooldownSeconds = fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
            tapAction: action
        )
        return CommandPaletteAction(
            id: "unmute-fame-launch-threshold-alerts-snooze-ending-soon",
            title: Self.fameLaunchThresholdAlertsSnoozeReminderTitle(
                snoozeMinutesRemaining: context.snoozeMinutesRemaining
            ),
            subtitle: Self.fameLaunchThresholdAlertsSnoozeReminderSubtitle(
                status: context.status,
                snoozeMinutesRemaining: context.snoozeMinutesRemaining,
                recommendedMinutes: context.recommendedMinutes
            ),
            systemImage: Self.fameLaunchThresholdAlertsSnoozeReminderSystemImage(),
            group: .support,
            keywords: ["launch", "threshold", "alerts", "snooze", "ending", "soon", "unmute", "countdown", "urgency", "smart", "recommended"],
            isEnabled: cooldownSeconds == nil,
            disabledReason: Self.fameLaunchThresholdAlertsQuickActionDisabledReason(
                cooldownSeconds: cooldownSeconds
            ),
            canFavorite: false
        ) { [weak self] in
            self?.runFameLaunchThresholdAlertsQuickAction(
                action: action,
                source: "commands-snooze-reminder-unmute"
            )
        }
    }

    private func fameLaunchThresholdAlertsSnoozeReminderExtendAction(
        context: FameLaunchThresholdAlertsSnoozeReminderContext
    ) -> CommandPaletteAction {
        let action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction = .extend(
            minutes: context.recommendedMinutes
        )
        let cooldownSeconds = fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
            tapAction: action
        )
        return CommandPaletteAction(
            id: "extend-fame-launch-threshold-alerts-snooze-ending-soon",
            title: Self.fameLaunchThresholdAlertsSnoozeReminderExtendTitle(
                recommendedMinutes: context.recommendedMinutes
            ),
            subtitle: Self.fameLaunchThresholdAlertsSnoozeReminderExtendSubtitle(
                status: context.status,
                snoozeMinutesRemaining: context.snoozeMinutesRemaining,
                recommendedMinutes: context.recommendedMinutes
            ),
            systemImage: Self.fameLaunchThresholdAlertsSnoozeReminderExtendSystemImage(),
            group: .support,
            keywords: ["launch", "threshold", "alerts", "snooze", "ending", "soon", "extend", "smart", "recommended", "countdown"],
            isEnabled: cooldownSeconds == nil,
            disabledReason: Self.fameLaunchThresholdAlertsQuickActionDisabledReason(
                cooldownSeconds: cooldownSeconds
            ),
            canFavorite: false
        ) { [weak self] in
            self?.runFameLaunchThresholdAlertsQuickAction(
                action: action,
                source: "commands-snooze-reminder-extend"
            )
        }
    }

    private func famePulseAlertSignal() -> FamePulseAlertSignal? {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            return FameSnapshotRollup.pulseAlertSignalFromLedger(at: ledgerURL)
        } catch {
            return nil
        }
    }

    private func latestLaunchCountdownStatus() -> FameLaunchCountdownStatus? {
        do {
            guard let countdownURL = try FameSnapshotArchive.latestLaunchCountdownURL() else { return nil }
            guard let countdown = try? String(contentsOf: countdownURL, encoding: .utf8),
                  !countdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return FameSnapshotRollup.launchCountdownStatus(from: countdown)
        } catch {
            return nil
        }
    }

    private func refreshFameLaunchCountdownForTopCard(now: Date = Date()) {
        guard Self.shouldRefreshLaunchCountdown(
            lastRefreshAt: launchCountdownLastRefreshAt,
            now: now
        ) else {
            return
        }

        do {
            guard let launchScriptURL = try FameSnapshotArchive.latestLaunchDayScriptURL() else { return }
            let countdown = FameSnapshotRollup.launchCountdownFromLaunchScript(
                at: launchScriptURL,
                now: now
            )
            _ = try FameSnapshotArchive.saveLaunchCountdown(
                markdown: countdown,
                now: now
            )
            launchCountdownLastRefreshAt = now
            fameLaunchAlertMenuItem?.title = fameLaunchAlertMenuTitle(now: now)
            fameLaunchHealthMenuItem?.title = fameLaunchHealthMenuTitle(now: now)
            updateFameOnboardingScorecardMenuStatus(now: now)
            refreshFamePulseBadge()
        } catch {
            return
        }
    }

    private func fameLaunchAlertMenuTitle(now: Date = Date()) -> String {
        let onboardingRecoveryHint = fameOnboardingRecoveryMomentumHint(now: now)
        return Self.fameLaunchAlertMenuTitle(
            launchStatus: latestLaunchCountdownStatus(),
            onboardingRecoveryHint: onboardingRecoveryHint
        )
    }

    private func fameLaunchHealthMenuTitle(now: Date = Date()) -> String {
        let healthInsights = launchControlHealthInsights(now: now)
        let launchStatus = latestLaunchCountdownStatus()
        let commandID = Self.launchControlHealthActionCommandID(
            launchStatus: launchStatus,
            momentumSignal: healthInsights.momentumSignal
        )
        let pulseStatusTitle = Self.launchControlHealthPulseMenuStatusTitle(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            pulseEnabled: settings.fameLaunchHealthPulseEnabled,
            cooldownSeconds: settings.fameLaunchHealthPulseCooldownSeconds,
            lastPulseAt: launchControlHealthPulseLastAt,
            lastPulseToken: launchControlHealthPulseLastToken,
            now: now
        )
        let countsStatusTitle = Self.launchControlHealthTransitionCountsMenuStatusTitle(
            watchToRiskCount: healthInsights.transitionCounts.watchToRiskCount,
            riskToReadyCount: healthInsights.transitionCounts.riskToReadyCount,
            averageDeltaTitle: healthInsights.averageDeltaTitle,
            momentumStatusTitle: healthInsights.momentumStatusTitle,
            pressurePersistenceStatusTitle: healthInsights.pressurePersistenceStatusTitle
        )
        let onboardingRecoveryHint = fameOnboardingRecoveryMomentumHint(now: now)
        let statusTitle = Self.launchControlStatusTitleWithFollowupMomentum(
            "\(pulseStatusTitle) · \(countsStatusTitle)",
            followupMomentumBadge: launchRescueFollowupMomentumBadgeSnapshot(now: now)
        )
        return Self.fameLaunchHealthMenuTitle(
            launchStatus: launchStatus,
            statusTitle: statusTitle,
            commandID: commandID,
            onboardingRecoveryHint: onboardingRecoveryHint
        )
    }

    private func fameOnboardingRecoveryMomentumHint(now: Date = Date()) -> String? {
        let snapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        return Self.fameOnboardingRecoveryMomentumHint(
            isFreshRecovery: snapshot.isFresh,
            remainingArtifacts: snapshot.remainingArtifacts
        )
    }

    private func fameLaunchThresholdAlertsMenuTitle(now: Date = Date()) -> String {
        Self.fameLaunchThresholdAlertsToggleTitle(
            settings.fameLaunchThresholdAlertsEnabled,
            snoozeMinutesRemaining: fameLaunchThresholdAlertsSnoozeMinutesRemaining(now: now)
        )
    }

    private func fameLaunchThresholdAlertsRecommendedSnoozeMinutes() -> Int {
        Self.fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
            launchStatus: latestLaunchCountdownStatus()
        )
    }

    private func fameLaunchThresholdAlertsRecommendedSnoozeMenuTitle() -> String {
        Self.fameLaunchThresholdAlertsRecommendedSnoozeTitle(
            minutes: fameLaunchThresholdAlertsRecommendedSnoozeMinutes()
        )
    }

    private func fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let tapAction = fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            now: now,
            defaults: defaults
        )
        return Self.fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            launchStatus: latestLaunchCountdownStatus(),
            snoozeMinutesRemaining: fameLaunchThresholdAlertsSnoozeMinutesRemaining(
                now: now,
                defaults: defaults
            ),
            currentSnoozeUntil: fameLaunchThresholdAlertsSnoozeUntil(defaults: defaults),
            lastReminderSnoozeUntil: fameLaunchThresholdAlertsReminderLastSnoozeUntil(defaults: defaults),
            lastReminderUrgencyPriority: fameLaunchThresholdAlertsReminderLastUrgencyPriority(
                defaults: defaults
            ),
            cooldownSeconds: fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
                now: now,
                defaults: defaults,
                tapAction: tapAction
            )
        )
    }

    private func fameLaunchThresholdAlertsSnoozeReminderMenuState(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameLaunchThresholdAlertsSnoozeReminderMenuState {
        Self.fameLaunchThresholdAlertsSnoozeReminderMenuState(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            launchStatus: latestLaunchCountdownStatus(),
            snoozeMinutesRemaining: fameLaunchThresholdAlertsSnoozeMinutesRemaining(
                now: now,
                defaults: defaults
            ),
            currentSnoozeUntil: fameLaunchThresholdAlertsSnoozeUntil(defaults: defaults),
            lastReminderSnoozeUntil: fameLaunchThresholdAlertsReminderLastSnoozeUntil(defaults: defaults),
            lastReminderUrgencyPriority: fameLaunchThresholdAlertsReminderLastUrgencyPriority(
                defaults: defaults
            )
        )
    }

    private func fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameLaunchThresholdAlertsSnoozeReminderMenuTapAction? {
        let launchStatus = latestLaunchCountdownStatus()
        let state = Self.fameLaunchThresholdAlertsSnoozeReminderMenuState(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            launchStatus: launchStatus,
            snoozeMinutesRemaining: fameLaunchThresholdAlertsSnoozeMinutesRemaining(
                now: now,
                defaults: defaults
            ),
            currentSnoozeUntil: fameLaunchThresholdAlertsSnoozeUntil(defaults: defaults),
            lastReminderSnoozeUntil: fameLaunchThresholdAlertsReminderLastSnoozeUntil(defaults: defaults),
            lastReminderUrgencyPriority: fameLaunchThresholdAlertsReminderLastUrgencyPriority(
                defaults: defaults
            )
        )
        return Self.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            launchStatus: launchStatus,
            menuState: state
        )
    }

    private func fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        tapAction: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction? = nil
    ) -> Int? {
        let resolvedAction = tapAction ?? fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            now: now,
            defaults: defaults
        )
        guard let resolvedAction else { return nil }
        let actionToken = Self.fameLaunchThresholdAlertsQuickActionActivityToken(action: resolvedAction)
        return Self.fameLaunchThresholdAlertsQuickActionCooldownRemainingSeconds(
            lastRunAt: fameLaunchThresholdAlertsQuickActionLastRunAt,
            lastActionToken: fameLaunchThresholdAlertsQuickActionLastActionToken,
            nextActionToken: actionToken,
            now: now,
            cooldown: fameLaunchThresholdAlertsQuickActionCooldown
        )
    }

    private func startFameLaunchThresholdAlertsCooldownMenuRefresh(now: Date = Date()) {
        fameLaunchThresholdAlertsCooldownRefreshTask?.cancel()
        guard fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(now: now) != nil else {
            fameLaunchThresholdAlertsCooldownRefreshTask = nil
            return
        }

        fameLaunchThresholdAlertsCooldownRefreshTask = Task { @MainActor [weak self] in
            var previousCooldownSeconds = self?.fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
                now: now
            )
            while let self, !Task.isCancelled {
                self.updateFameLaunchThresholdAlertsMenuTitle()
                self.refreshCommandPaletteIfVisible()
                let tapAction = self.fameLaunchThresholdAlertsSnoozeReminderMenuTapAction()
                let cooldownSeconds = self.fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
                    tapAction: tapAction
                )
                let menuVisible = self.fameMenuIsOpen
                let paletteVisible = self.commandPalette.isVisible
                if Self.shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
                    previousCooldownSeconds: previousCooldownSeconds,
                    cooldownSeconds: cooldownSeconds,
                    tapAction: tapAction,
                    isMenuVisible: menuVisible || paletteVisible
                ) {
                    self.effects.hit(.tap, settings: self.settings, haptic: .alignment)
                    self.flashStatus(symbol: "clock.badge.checkmark", tint: .systemGreen, length: 0.14)
                    self.recordActivity(
                        category: "support",
                        detail: "launch-threshold-alerts-quick-action-ready-\(Self.fameLaunchThresholdAlertsQuickActionReadySurfaceToken(menuVisible: menuVisible, paletteVisible: paletteVisible))"
                    )
                }
                guard cooldownSeconds != nil else {
                    break
                }
                previousCooldownSeconds = cooldownSeconds
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            self?.fameLaunchThresholdAlertsCooldownRefreshTask = nil
        }
    }

    private func updateFameLaunchThresholdAlertsMenuTitle(now: Date = Date()) {
        let tapAction = fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(now: now)
        let cooldownSeconds = fameLaunchThresholdAlertsSnoozeReminderMenuCooldownRemainingSeconds(
            now: now,
            tapAction: tapAction
        )
        fameLaunchThresholdAlertsMenuItem?.title = fameLaunchThresholdAlertsMenuTitle(now: now)
        fameLaunchThresholdAlertsRecommendedSnoozeMenuItem?.title = fameLaunchThresholdAlertsRecommendedSnoozeMenuTitle()
        fameLaunchThresholdAlertsSnoozeReminderMenuItem?.title = fameLaunchThresholdAlertsSnoozeReminderMenuTitle(now: now)
        fameLaunchThresholdAlertsSnoozeReminderMenuItem?.isEnabled =
            Self.canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(tapAction)
            && cooldownSeconds == nil
    }

    private func refreshCommandPaletteIfVisible() {
        guard commandPalette.isVisible else { return }
        commandPalette.requestRefresh()
    }

    func menuWillOpen(_ menu: NSMenu) {
        if menu === fameMenu {
            fameMenuIsOpen = true
            updateFameExceptionalLoopMenuStatus()
            updateFameOnboardingScorecardMenuStatus()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        if menu === fameMenu {
            fameMenuIsOpen = false
        }
    }

    private func fameLaunchThresholdAlertsSnoozeUntil(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: fameLaunchThresholdAlertsSnoozeUntilKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: fameLaunchThresholdAlertsSnoozeUntilKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func setFameLaunchThresholdAlertsSnoozeUntil(_ date: Date?, defaults: UserDefaults = .standard) {
        setFameLaunchThresholdAlertsReminderLastState(
            snoozeUntil: nil,
            urgencyPriority: nil,
            defaults: defaults
        )
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: fameLaunchThresholdAlertsSnoozeUntilKey)
            updateFameLaunchThresholdAlertsMenuTitle(now: date)
        } else {
            defaults.removeObject(forKey: fameLaunchThresholdAlertsSnoozeUntilKey)
            updateFameLaunchThresholdAlertsMenuTitle()
        }
    }

    private func fameLaunchThresholdAlertsReminderLastSnoozeUntil(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: fameLaunchThresholdAlertsReminderLastSnoozeUntilKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: fameLaunchThresholdAlertsReminderLastSnoozeUntilKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func fameLaunchThresholdAlertsReminderLastUrgencyPriority(defaults: UserDefaults = .standard) -> Int? {
        guard defaults.object(forKey: fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey) != nil else {
            return nil
        }
        return defaults.integer(forKey: fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey)
    }

    private func setFameLaunchThresholdAlertsReminderLastState(
        snoozeUntil: Date?,
        urgencyPriority: Int?,
        defaults: UserDefaults = .standard
    ) {
        if let snoozeUntil {
            defaults.set(
                snoozeUntil.timeIntervalSince1970,
                forKey: fameLaunchThresholdAlertsReminderLastSnoozeUntilKey
            )
        } else {
            defaults.removeObject(forKey: fameLaunchThresholdAlertsReminderLastSnoozeUntilKey)
        }

        if let urgencyPriority {
            defaults.set(
                urgencyPriority,
                forKey: fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey
            )
        } else {
            defaults.removeObject(forKey: fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey)
        }
    }

    private func shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
        status: FameLaunchCountdownStatus,
        snoozeMinutesRemaining: Int,
        defaults: UserDefaults = .standard
    ) -> Bool {
        let currentSnoozeUntil = fameLaunchThresholdAlertsSnoozeUntil(defaults: defaults)
        let lastReminderSnoozeUntil = fameLaunchThresholdAlertsReminderLastSnoozeUntil(defaults: defaults)
        let lastReminderUrgencyPriority = fameLaunchThresholdAlertsReminderLastUrgencyPriority(defaults: defaults)

        guard Self.shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            launchStatus: status,
            snoozeMinutesRemaining: snoozeMinutesRemaining,
            currentSnoozeUntil: currentSnoozeUntil,
            lastReminderSnoozeUntil: lastReminderSnoozeUntil,
            lastReminderUrgencyPriority: lastReminderUrgencyPriority
        ) else {
            return false
        }

        guard let currentSnoozeUntil,
              let urgency = Self.fameLaunchBadgeUrgency(status) else {
            return false
        }

        setFameLaunchThresholdAlertsReminderLastState(
            snoozeUntil: currentSnoozeUntil,
            urgencyPriority: Self.fameLaunchBadgeUrgencyPriority(urgency),
            defaults: defaults
        )
        return true
    }

    private func fameLaunchThresholdAlertsSnoozeMinutesRemaining(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Int? {
        Self.fameLaunchThresholdAlertsSnoozeMinutesRemaining(
            snoozeUntil: fameLaunchThresholdAlertsSnoozeUntil(defaults: defaults),
            now: now
        )
    }

    private func resolveFameLaunchThresholdAlertsSnooze(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        guard Self.shouldAutoUnmuteFameLaunchThresholdAlerts(
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            snoozeUntil: fameLaunchThresholdAlertsSnoozeUntil(defaults: defaults),
            now: now
        ) else {
            return
        }

        settings.fameLaunchThresholdAlertsEnabled = true
        setFameLaunchThresholdAlertsSnoozeUntil(nil, defaults: defaults)
        readerState.petSay("Launch threshold alert snooze ended. Alerts back on.", mood: .ready)
        readerState.pulse()
        flashStatus(symbol: "bell.fill", tint: .systemGreen, length: 0.2)
        recordActivity(category: "support", detail: "fame-launch-threshold-alerts-snooze-ended")
    }

    private func famePulseLatestTransition() -> FamePulseRiskTransition? {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            return FameSnapshotRollup.latestPulseRiskTransitionFromLedger(at: ledgerURL)?.transition
        } catch {
            return nil
        }
    }

    private func famePulseWidgetState() -> FamePulseWidgetState {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            return FameSnapshotRollup.pulseWidgetStateFromLedger(at: ledgerURL)
        } catch {
            return .unknown
        }
    }

    private func fameDailyScorecardState() -> FameDailyScorecardState {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            return FameSnapshotRollup.dailyScorecardStateFromLedger(at: ledgerURL)
        } catch {
            return .unknown
        }
    }

    private func fameOnboardingGapStatusSignalForStatusBadge(
        now: Date = Date()
    ) -> FameOnboardingGapStatusSignal? {
        guard fameOnboardingScorecardContext(now: now) != nil else { return nil }
        guard let artifacts = try? latestOnboardingSuiteArtifacts() else { return nil }
        guard let recommendedCommandID = Self.fameOnboardingGapRecommendedCommandID(
            hasDailyBrief: artifacts.dailyBriefURL != nil,
            hasScorecard: artifacts.scorecardURL != nil,
            hasNudge: artifacts.nudgeURL != nil
        ) else { return nil }

        return FameOnboardingGapStatusSignal(
            missingArtifacts: max(0, artifacts.missingArtifactNames.count),
            missingArtifactNames: artifacts.missingArtifactNames,
            recommendedCommandID: recommendedCommandID
        )
    }

    private func handleFameOnboardingGapPulse(
        missingArtifacts: Int,
        missingArtifactNames: [String],
        recommendedCommandID: String,
        now: Date = Date()
    ) {
        fameOnboardingGapPulseLastAt = now
        let pulseMessage = Self.fameOnboardingGapPulseMessage(
            missingArtifacts: missingArtifacts,
            missingArtifactNames: missingArtifactNames,
            recommendedCommandID: recommendedCommandID
        )
        readerState.petSay(pulseMessage, mood: .ready)
        readerState.pulse()
        flashStatus(symbol: "sparkles", tint: .systemPurple, length: 0.18)
        recordActivity(
            category: "support",
            detail: Self.fameOnboardingGapPulseActivityDetail(
                missingArtifacts: missingArtifacts,
                missingArtifactNames: missingArtifactNames,
                recommendedCommandID: recommendedCommandID
            )
        )
    }

    private func handleFameOnboardingGapRecovery(
        previousMissingArtifacts: Int,
        nextMissingArtifacts: Int,
        nextMissingArtifactNames: [String],
        recommendedCommandID: String?,
        now: Date = Date()
    ) {
        fameOnboardingGapRecoveryLastAt = now
        let defaults = UserDefaults.standard
        defaults.set(now.timeIntervalSince1970, forKey: fameOnboardingGapRecoveryLastAtKey)
        defaults.set(
            max(0, nextMissingArtifacts),
            forKey: fameOnboardingGapRecoveryRemainingArtifactsKey
        )
        if let recommendedCommandID,
           !recommendedCommandID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(
                recommendedCommandID,
                forKey: fameOnboardingGapRecoveryFollowupCommandIDKey
            )
        } else {
            defaults.removeObject(forKey: fameOnboardingGapRecoveryFollowupCommandIDKey)
        }

        let recoveryMessage = Self.fameOnboardingGapRecoveryMessage(
            previousMissingArtifacts: previousMissingArtifacts,
            nextMissingArtifacts: nextMissingArtifacts,
            nextMissingArtifactNames: nextMissingArtifactNames,
            recommendedCommandID: recommendedCommandID
        )
        readerState.petSay(recoveryMessage, mood: .happy)
        readerState.pulse()
        flashStatus(symbol: "checkmark.seal.fill", tint: .systemGreen, length: 0.16)
        recordActivity(
            category: "support",
            detail: Self.fameOnboardingGapRecoveryActivityDetail(
                previousMissingArtifacts: previousMissingArtifacts,
                nextMissingArtifacts: nextMissingArtifacts,
                nextMissingArtifactNames: nextMissingArtifactNames,
                recommendedCommandID: recommendedCommandID
            )
        )
    }

    private func commandPaletteInlineActions(_ query: String) -> [CommandPaletteAction] {
        var actions: [CommandPaletteAction] = []

        if let inlineAsk = CommandPaletteInlineAsk.makeAction(query: query, run: { [weak self] prompt in
            self?.askLLM(question: prompt)
        }) {
            actions.append(inlineAsk)
        }

        if let calculatorAction = InlineCalculator.makeAction(query: query, copyResult: { [weak self] result in
            guard let self else { return }
            self.copyToClipboard(result, message: "Copied calculation.")
            self.recordActivity(category: "inline", detail: "inline-calculator")
        }) {
            actions.append(calculatorAction)
        }

        if let conversionAction = InlineUnitConverter.makeAction(query: query, copyResult: { [weak self] result in
            guard let self else { return }
            self.copyToClipboard(result, message: "Copied conversion.")
            self.recordActivity(category: "inline", detail: "inline-unit-converter")
        }) {
            actions.append(conversionAction)
        }

        if let colorAction = InlineColorConverter.makeAction(query: query, copyResult: { [weak self] result in
            guard let self else { return }
            self.copyToClipboard(result, message: "Copied color.")
            self.recordActivity(category: "inline", detail: "inline-color-converter")
        }) {
            actions.append(colorAction)
        }

        if let dateAction = InlineDate.makeAction(query: query, copyResult: { [weak self] result in
            guard let self else { return }
            self.copyToClipboard(result, message: "Copied date.")
            self.recordActivity(category: "inline", detail: "inline-date-math")
        }) {
            actions.append(dateAction)
        }

        if let webAction = WebSearch.makeAction(query: query, open: { [weak self] url in
            self?.openURL(url)
        }) {
            actions.append(webAction)
        }

        if let cleanURLAction = WebSearch.makeCleanURLAction(query: query, copy: { [weak self] cleanURL in
            guard let self else { return }
            self.copyToClipboard(cleanURL, message: "Copied clean URL.")
            self.recordActivity(category: "inline", detail: "inline-clean-url")
        }) {
            actions.append(cleanURLAction)
        }

        let fileActions = LocalFilePath.makeActions(
            query: query,
            open: { [weak self] url in
                self?.openURL(url)
            },
            reveal: { [weak self] url in
                self?.revealURL(url)
            }
        )
        actions.append(contentsOf: fileActions)

        return actions
    }

    private func askAnything() {
        if settings.llmEnabled {
            askPromptWindow.show()
            recordActivity(category: "ask", detail: "open-ask-prompt")
            return
        }

        readerState.petSay("Enable LLM in Settings to ask.", mood: .ready)
        settingsWindow.show()
        recordActivity(category: "ask", detail: "ask-disabled-open-settings")
    }

    private func readSelectedTextFromFrontApp() {
        Task { [weak self] in
            guard let self else { return }
            let selectedText = await SelectedTextReader.readSelectedText()
            await MainActor.run {
                guard let selectedText else {
                    self.readerState.errorText = "No selected text found."
                    self.effects.play(.error, settings: self.settings)
                    self.flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
                    self.recordActivity(category: "core", detail: "read-selected-empty")
                    return
                }

                self.readerState.lastText = selectedText
                self.readerState.answerText = ""
                self.readerState.errorText = ""
                self.readerState.lastImageData = nil
                self.readerState.remember(text: selectedText)
                self.readerState.petSay("Read selected text.", mood: .happy)
                self.read(selectedText)
                self.effects.hit(.success, settings: self.settings, haptic: .alignment)
                self.flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.32)
                self.recordActivity(category: "core", detail: "read-selected")
            }
        }
    }

    private func growthSnapshotCounts() -> (savedItemCount: Int, activityLogItemCount: Int) {
        (savedItemCount: max(0, readerState.snippets.count), activityLogItemCount: max(0, activityLog.items.count))
    }

    private func searchSeedText() -> String {
        let answer = readerState.answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !answer.isEmpty {
            return answer
        }

        return readerState.lastText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func setupGuideMarkdown() -> String {
        let snapshot = growthSnapshotCounts()
        return SetupGuideReport.make(
            settings: settings,
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        ).markdown()
    }

    private func copyWinRecap() {
        let snapshot = growthSnapshotCounts()
        let recap = SetupGuideReport.winRecap(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        )
        copyToClipboardWithReadyPrompt(
            recap,
            readyMessage: "Win recap ready.",
            copyMessage: "Copied win recap."
        )
        recordActivity(category: "share", detail: "copy-win-recap")
    }

    private func copyLaunchKit() {
        let snapshot = growthSnapshotCounts()
        let launchKit = SetupGuideReport.launchKit(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        )
        copyToClipboardWithReadyPrompt(
            launchKit,
            readyMessage: "Launch kit ready.",
            copyMessage: "Copied launch kit."
        )
        recordActivity(category: "share", detail: "copy-launch-kit")
    }

    private func copyFameBoard() {
        let snapshot = growthSnapshotCounts()
        let board = SetupGuideReport.experimentBoard(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        )
        copyToClipboardWithReadyPrompt(
            board,
            readyMessage: "Fame board ready.",
            copyMessage: "Copied fame board."
        )
        recordActivity(category: "share", detail: "copy-experiment-board")
    }

    private func copyFameSprint() {
        let snapshot = growthSnapshotCounts()
        let sprint = SetupGuideReport.fameSprint(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        )
        copyToClipboardWithReadyPrompt(
            sprint,
            readyMessage: "Fame sprint ready.",
            copyMessage: "Copied fame sprint."
        )
        recordActivity(category: "share", detail: "copy-fame-sprint")
    }

    private func runFameSprint() {
        let snapshot = growthSnapshotCounts()
        let plan = SetupGuideReport.fameSprintToday(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        )
        readerState.answerText = plan
        readerState.remember(text: "", answer: plan)
        copyToClipboardWithReadyPrompt(
            plan,
            readyMessage: "Fame sprint ready.",
            copyMessage: "Copied today sprint."
        )
        readerWindow.show()
        recordActivity(category: "share", detail: "run-fame-sprint")
    }

    private func runFameSprintSnapshot() {
        let snapshot = growthSnapshotCounts()
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let plan = SetupGuideReport.fameSprintToday(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        )
        let pack = SetupGuideReport.famePack(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount,
            cadenceExecutionKitCurrentStreak: cadenceStreak.current,
            cadenceExecutionKitBestStreak: cadenceStreak.best
        )

        do {
            let now = Date()
            let savedFiles = try FameSnapshotArchive.save(
                sprintMarkdown: plan,
                packMarkdown: pack,
                now: now
            )
            readerState.answerText = plan
            var readyMessage = "Sprint snapshot saved."
            if settings.fameAutoPulseAfterSnapshot,
               let autoSummary = autoPulseSummaryForSnapshot(ledgerURL: savedFiles.ledgerURL, now: now) {
                if settings.fameAutoPulseQuietMode {
                    recordActivity(category: "saved", detail: "run-fame-sprint-snapshot-auto-pulse-quiet")
                } else {
                    readerState.answerText = "\(plan)\n\n\(autoSummary)"
                    readyMessage = "Snapshot + pulse ready."
                }
            }
            readerState.remember(text: "", answer: readerState.answerText)
            copyToClipboardWithReadyPrompt(
                plan,
                readyMessage: readyMessage,
                copyMessage: "Copied today sprint."
            )
            readerWindow.show()
            revealURL(savedFiles.directoryURL)
            refreshFamePulseBadge()
            recordActivity(category: "saved", detail: "run-fame-sprint-snapshot")
        } catch {
            readerState.errorText = "Could not save sprint snapshot."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "saved", detail: "run-fame-sprint-snapshot-error")
        }
    }

    private func autoPulseSummaryForSnapshot(ledgerURL: URL, now: Date) -> String? {
        do {
            let bundle = FameSnapshotRollup.pulseBundleFromLedger(
                at: ledgerURL,
                now: now
            )
            let scorecard = FameSnapshotRollup.dailyScorecardFromLedger(
                at: ledgerURL,
                now: now
            )
            let dashboard = FameSnapshotRollup.operatorDashboardFromLedger(
                at: ledgerURL,
                now: now
            )
            let files = try FameSnapshotArchive.saveAutoPulseFiles(
                checkpointMarkdown: bundle.checkpointMarkdown,
                pulseNudgeMarkdown: bundle.pulseNudgeMarkdown,
                scorecardMarkdown: scorecard,
                dashboardMarkdown: dashboard,
                now: now
            )
            recordActivity(category: "saved", detail: "run-fame-sprint-snapshot-auto-pulse")
            return """
            ## Auto Fame Pulse
            - Daily checkpoint saved: \(files.checkpointURL.lastPathComponent)
            - Pulse nudge saved: \(files.pulseNudgeURL.lastPathComponent)
            - Daily scorecard saved: \(files.scorecardURL.lastPathComponent)
            - Operator dashboard saved: \(files.dashboardURL.lastPathComponent)
            - Next: run `Run Fame Pulse Nudge` after shipping to refresh alerts.
            """
        } catch {
            recordActivity(category: "saved", detail: "run-fame-sprint-snapshot-auto-pulse-error")
            return nil
        }
    }

    private enum FameBriefBuildError: Error {
        case noSnapshots
    }

    enum MorningBriefLaunchDecision: Equatable {
        case skipDisabled
        case skipSetupChecklist
        case skipAlreadyRanToday
        case run(quietMode: Bool)
    }

    enum AutoOpsBundleEscalationStatus: Equatable {
        case disabled
        case ready
        case coolingDown(minutesRemaining: Int)
    }

    enum ReaderStatusTone: Equatable {
        case neutral
        case success
        case warning
        case danger
    }

    enum LaunchRescueModeMomentumCueSeverity: Equatable {
        case none
        case watch
        case alert
    }

    enum LaunchRescueAutoTriggerReason: String, Equatable {
        case urgencyHigh = "urgency-high"
        case urgencyCritical = "urgency-critical"
        case momentumWatch = "momentum-watch"
        case momentumAlert = "momentum-alert"
        case pressurePersistence = "pressure-persistence"
    }

    enum LaunchRescueAutoFollowupSelfHealOutcome: String, Equatable {
        case ready
        case healed
        case failed
        case unknown
    }

    struct LaunchRescueAutoFollowupSelfHealSnapshot: Equatable {
        let reasonToken: String
        let routeCommandID: String
        let outcome: LaunchRescueAutoFollowupSelfHealOutcome
        let recordedAt: Date?
    }

    enum LaunchRescueFollowupCoachLane: String, Equatable {
        case baseline
        case winning
        case recovery
        case watch
        case stable
        case calibration
    }

    enum NextMoveCadenceStepCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case ready(step: String)
    }

    enum NextMoveCadencePostCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(post: String)
    }

    enum NextMoveCadencePostQueueCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(post: String, queue: String)
    }

    enum NextMoveCadenceExecutionKitCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(post: String, kit: String)
    }

    enum NextMoveReplyLadderCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(ladder: String)
    }

    enum NextMoveDraftChannel: Equatable {
        case x
        case bluesky
        case linkedIn
    }

    enum NextMoveChannelDraftCopyOutcome: Equatable {
        case missingHandoff
        case missingDraft
        case ready(draft: String)
    }

    enum NextMoveBestChannelDraftCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(channel: NextMoveDraftChannel, draft: String)
    }

    enum NextMoveBestChannelLaunchPackCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(channel: NextMoveDraftChannel, post: String, pack: String)
    }

    enum NextMoveLaunchNowSequenceCopyOutcome: Equatable {
        case missingHandoff
        case missingCadenceStep
        case missingDraft
        case ready(sequence: String)
    }

    enum CadenceMomentumShareLineCopyOutcome: Equatable {
        case missingBrief
        case missingShareLine
        case ready(shareLine: String)
    }

    struct CadenceMomentumSharePackChannelBlock: Equatable {
        let channelTitle: String
        let primary: String
        let followup: String
    }

    struct CadenceMomentumSharePack: Equatable {
        let shortLine: String
        let standardLine: String
        let hypeLine: String
        let channelBlocks: [CadenceMomentumSharePackChannelBlock]
        let checklistComment: String?
        let bestChannelTitle: String?
        let bestChannelReason: String?
    }

    enum FameStatusBadgeLevel: String, Equatable {
        case normal
        case launchPrep
        case launchReady
        case launchLive
        case launchHot
        case launchHigh
        case launchCritical
        case onboardingGap
        case pulseHigh
        case pulseCritical
    }

    enum FameLaunchBadgeUrgency: Equatable {
        case prep
        case ready
        case live
        case hot
        case high
        case critical
    }

    enum LaunchControlHealthBand: String, Equatable {
        case ready
        case watch
        case risk
    }

    enum LaunchControlHealthMomentumSignal: String, Equatable {
        case stable
        case riskPressure
        case recoveryMomentum
    }

    enum FameLaunchThresholdAlertsSnoozeReminderMenuState: Equatable {
        case inactiveAlertsOn
        case inactiveNoSnooze
        case waiting(minutesRemaining: Int)
        case waitingUrgencyUnknown
        case waitingUrgency(FameLaunchBadgeUrgency)
        case armed(minutesRemaining: Int)
        case suppressed
    }

    enum FameLaunchThresholdAlertsSnoozeReminderMenuTapAction: Equatable {
        case unmuteNow
        case extend(minutes: Int)
    }

    struct FameLaunchUrgencyTransition: Equatable {
        let from: FameLaunchBadgeUrgency
        let to: FameLaunchBadgeUrgency
        let isEscalation: Bool
    }

    struct LaunchControlHealthTransition: Equatable {
        let from: LaunchControlHealthBand
        let to: LaunchControlHealthBand
    }

    struct LaunchControlHealthTransitionHistoryDay: Codable, Equatable {
        let dayStamp: String
        let watchToRiskCount: Int
        let riskToReadyCount: Int
    }

    struct LaunchControlHealthTransitionAverage: Equatable {
        let watchToRiskAverage: Double
        let riskToReadyAverage: Double
    }

    struct LaunchControlHealthInsights {
        let transitionCounts: (watchToRiskCount: Int, riskToReadyCount: Int)
        let averageDeltaTitle: String
        let momentumSignal: LaunchControlHealthMomentumSignal
        let momentumStatusTitle: String
        let pressureStreakDays: Int
        let pressurePersistenceStatusTitle: String?
    }

    struct LaunchRescueFollowupOutcomeSample: Codable, Equatable {
        let recordedAt: TimeInterval
        let wasSuccess: Bool
    }

    struct LaunchRescueFollowupOutcomeScoreboard: Equatable {
        let attempts24h: Int
        let successes24h: Int
        let attemptsRolling: Int
        let successesRolling: Int
        let lastOutcomeAt: Date?
        let lastSuccessAt: Date?
        let lastFailureAt: Date?
    }

    nonisolated static func morningBriefLaunchDecision(
        isEnabled: Bool,
        quietMode: Bool,
        skipForSetupChecklist: Bool,
        lastRunStamp: String?,
        todayStamp: String
    ) -> MorningBriefLaunchDecision {
        guard isEnabled else { return .skipDisabled }
        guard !skipForSetupChecklist else { return .skipSetupChecklist }
        guard lastRunStamp != todayStamp else { return .skipAlreadyRanToday }
        return .run(quietMode: quietMode)
    }

    nonisolated static func shouldAutoTriggerFameEscalationResponse(
        _ transition: FamePulseRiskTransition
    ) -> Bool {
        guard transition.isEscalation else { return false }
        guard transition.fromRiskLevel != "Unknown" else { return false }
        return transition.toRiskLevel == "High" || transition.toRiskLevel == "Critical"
    }

    nonisolated static func shouldRunAutoOpsBundleOnEscalation(
        lastRunAt: Date?,
        now: Date,
        cooldown: TimeInterval = 30 * 60
    ) -> Bool {
        guard cooldown > 0 else { return false }
        guard let lastRunAt else { return true }
        return now.timeIntervalSince(lastRunAt) >= cooldown
    }

    nonisolated static func famePulseRiskActionCommandID(
        signal: FamePulseAlertSignal?,
        transition: FamePulseRiskTransition?
    ) -> String {
        guard let signal else { return "run-fame-pulse-nudge" }
        let isHighRisk = signal.riskLevel == "High" || signal.riskLevel == "Critical"
        guard isHighRisk else { return "run-fame-pulse-nudge" }

        let escalatedNow = transition?.isEscalation == true
            && transition?.fromRiskLevel != "Unknown"
            && (transition?.toRiskLevel == "High" || transition?.toRiskLevel == "Critical")
        return escalatedNow ? "run-fame-escalation-nudge" : "run-fame-recovery-sprint"
    }

    nonisolated static func fameNextMoveCommandID(
        signal: FamePulseAlertSignal?,
        transition: FamePulseRiskTransition?,
        scorecard: FameDailyScorecardState
    ) -> String {
        let pulseCommandID = famePulseRiskActionCommandID(signal: signal, transition: transition)
        if pulseCommandID != "run-fame-pulse-nudge" {
            return pulseCommandID
        }

        if scorecard.riskLevel == "Unknown" {
            return "run-fame-sprint-snapshot"
        }
        if scorecard.recommendsRecovery {
            return "run-fame-recovery-sprint"
        }
        if scorecard.riskLevel == "Low", scorecard.scoreDelta >= 10 {
            return "run-fame-spotlight-pack"
        }
        if scorecard.riskLevel == "Low", scorecard.scoreDelta >= 6 {
            return "run-fame-breakthrough-forecast"
        }

        switch scorecard.riskLevel {
        case "Low":
            return "run-fame-command-center"
        case "Medium":
            return "run-fame-daily-checkpoint"
        default:
            return "run-fame-daily-checkpoint"
        }
    }

    nonisolated static func fameNextMoveCommandLabel(_ commandID: String) -> String {
        switch commandID {
        case "run-fame-escalation-nudge":
            return "Escalation Nudge"
        case "run-fame-recovery-sprint":
            return "Recovery Sprint"
        case "run-fame-command-center":
            return "Command Center"
        case "run-fame-breakthrough-forecast":
            return "Breakthrough Forecast"
        case "run-fame-spotlight-pack":
            return "Spotlight Pack"
        case "run-fame-sprint-snapshot":
            return "Save Snapshot"
        case "run-fame-daily-checkpoint":
            return "Daily Checkpoint"
        default:
            return "Pulse Nudge"
        }
    }

    nonisolated static func fameNextMoveMenuTitle(
        commandID: String,
        onboardingRecoveryHint: String? = nil
    ) -> String {
        let baseTitle = "Run Fame Next Move: \(fameNextMoveCommandLabel(commandID))"
        return fameMenuTitle(baseTitle: baseTitle, appendedHint: onboardingRecoveryHint)
    }

    struct FameExceptionalLoopPlan: Equatable {
        let focusTitle: String
        let primaryCommandID: String
        let reasonLine: String
        let followupActionID: String?
        let followupReasonLine: String?
    }

    struct FameExceptionalLoopOutcomeScoreboard: Equatable {
        let attempts: Int
        let successes: Int
        let successRate: Int
        let successStreak: Int
        let failureStreak: Int
        let lastFocusToken: String?
        let lastOutcomeAt: Date?
    }

    struct FameExceptionalLoopOutcomeCommandSample: Codable, Equatable {
        let commandToken: String
        let recordedAt: TimeInterval
        let wasSuccess: Bool
    }

    struct FameExceptionalLoopOutcomeLaneHighlights: Equatable {
        let topWinLane: FameExceptionalLoopOutcomeScoreboard?
        let topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?
    }

    struct FameExceptionalLoopOutcomeLaneSummaries: Equatable {
        let topWinLane: String
        let topRecoveryLane: String
    }

    struct FameExceptionalLoopHealthSnapshot: Equatable {
        let trend: String
        let topWinLane: String
        let topRecoveryLane: String
        let recommendedNextAction: String
        let recommendedActionCommandID: String
        let recommendedActionTitle: String
        let recommendedActionConfidenceTitle: String
        let recommendedActionWhy: String
    }

    struct FameExceptionalLoopHealthRecommendation: Equatable {
        let commandID: String
        let summary: String
        let confidenceTitle: String
        let whyLine: String
    }

    struct FameExceptionalLoopRecoveryLaneMenuStatus: Equatable {
        let title: String
        let toolTip: String
        let isEnabled: Bool
    }

    struct FameExceptionalLoopAutoRecoveryLaneMenuStatus: Equatable {
        let title: String
        let toolTip: String
    }

    struct FameExceptionalLoopAutoRecoveryLaneTuningRecommendation: Equatable {
        let missesRequired: Int
        let failureStreakRequired: Int
        let cooldownMinutes: Int
        let rationale: String
    }

    struct FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus: Equatable {
        let title: String
        let toolTip: String
        let isEnabled: Bool
    }

    struct FameExceptionalLoopLatestRecapStatus: Equatable {
        let title: String
        let subtitle: String
        let toolTip: String
        let isEnabled: Bool
    }

    struct FameExceptionalLoopOutcomeTuningResetStatus: Equatable {
        let title: String
        let subtitle: String
        let toolTip: String
        let isEnabled: Bool
    }

    nonisolated static func fameExceptionalLoopOutcomeFocusToken(
        _ plan: FameExceptionalLoopPlan
    ) -> String {
        ActivityLogCommand.safeID(plan.primaryCommandID)
    }

    nonisolated static func fameExceptionalLoopOutcomeStatusTitle(
        _ scoreboard: FameExceptionalLoopOutcomeScoreboard
    ) -> String {
        guard scoreboard.attempts > 0 else {
            return "Outcome trend: warming up."
        }
        if scoreboard.failureStreak >= 2 {
            return "Outcome trend: recovery lane x\(scoreboard.failureStreak) · \(scoreboard.successRate)% hit rate."
        }
        if scoreboard.successStreak >= 2 {
            return "Outcome trend: win lane x\(scoreboard.successStreak) · \(scoreboard.successRate)% hit rate."
        }
        return "Outcome trend: mixed · \(scoreboard.successRate)% hit rate."
    }

    nonisolated static func fameExceptionalLoopHealthSnapshot(
        scoreboard: FameExceptionalLoopOutcomeScoreboard,
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopHealthSnapshot {
        let laneSummaries = fameExceptionalLoopOutcomeLaneSummaries(history: history)
        let recommendation = fameExceptionalLoopHealthRecommendation(
            scoreboard: scoreboard,
            history: history
        )
        let recommendedActionTitle = fameExceptionalLoopCommandTitle(recommendation.commandID)
        return FameExceptionalLoopHealthSnapshot(
            trend: fameExceptionalLoopOutcomeStatusTitle(scoreboard),
            topWinLane: laneSummaries.topWinLane,
            topRecoveryLane: laneSummaries.topRecoveryLane,
            recommendedNextAction: recommendation.summary,
            recommendedActionCommandID: recommendation.commandID,
            recommendedActionTitle: recommendedActionTitle,
            recommendedActionConfidenceTitle: recommendation.confidenceTitle,
            recommendedActionWhy: recommendation.whyLine
        )
    }

    nonisolated static func fameExceptionalLoopHealthRecommendation(
        scoreboard: FameExceptionalLoopOutcomeScoreboard,
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopHealthRecommendation {
        if let topRecoveryLane = fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(history: history) {
            let misses = max(0, topRecoveryLane.attempts - topRecoveryLane.successes)
            if misses > 0,
               let recoveryCommandID = fameExceptionalLoopRecoveryLaneCommandID(
                   topRecoveryLane.lastFocusToken
               ) {
                let confidenceTitle =
                    (topRecoveryLane.failureStreak >= 2 || misses >= 3) ? "High" : "Medium"
                let actionTitle = fameExceptionalLoopCommandTitle(recoveryCommandID)
                return FameExceptionalLoopHealthRecommendation(
                    commandID: recoveryCommandID,
                    summary: "\(actionTitle) (\(misses)/\(topRecoveryLane.attempts) misses, streak x\(topRecoveryLane.failureStreak))",
                    confidenceTitle: confidenceTitle,
                    whyLine: "Recovery lane pressure is active on \(actionTitle): \(misses)/\(topRecoveryLane.attempts) misses with streak x\(topRecoveryLane.failureStreak)."
                )
            }
        }

        let laneHighlights = fameExceptionalLoopOutcomeLaneHighlights(history: history)
        if let topWinLane = laneHighlights.topWinLane,
           topWinLane.successes > 0,
           let winLaneCommandID = fameExceptionalLoopRecoveryLaneCommandID(
               topWinLane.lastFocusToken
           ) {
            let confidenceTitle =
                (topWinLane.successStreak >= 3 || topWinLane.successRate >= 80) ? "High" : "Medium"
            let actionTitle = fameExceptionalLoopCommandTitle(winLaneCommandID)
            return FameExceptionalLoopHealthRecommendation(
                commandID: winLaneCommandID,
                summary: "\(actionTitle) (top win lane is compounding; press while momentum is hot).",
                confidenceTitle: confidenceTitle,
                whyLine: "Win lane momentum is strongest on \(actionTitle): \(topWinLane.successes)/\(topWinLane.attempts) hits, streak x\(topWinLane.successStreak)."
            )
        }

        if let fallbackFocusCommandID = fameExceptionalLoopRecoveryLaneCommandID(
            scoreboard.lastFocusToken
        ) {
            let actionTitle = fameExceptionalLoopCommandTitle(fallbackFocusCommandID)
            return FameExceptionalLoopHealthRecommendation(
                commandID: fallbackFocusCommandID,
                summary: "\(actionTitle) (latest focus lane while telemetry warms up).",
                confidenceTitle: "Low",
                whyLine: "No clear win/recovery lane leader yet; using the latest focus lane from outcomes telemetry."
            )
        }

        return FameExceptionalLoopHealthRecommendation(
            commandID: "run-fame-exceptional-loop",
            summary: "Run Fame Exceptional Loop to seed outcomes.",
            confidenceTitle: "Low",
            whyLine: "No lane telemetry yet. Run the full exceptional loop once to establish win/recovery lanes."
        )
    }

    nonisolated static func fameExceptionalLoopHealthRecommendedActionCommandID(
        scoreboard: FameExceptionalLoopOutcomeScoreboard,
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> String {
        fameExceptionalLoopHealthRecommendation(
            scoreboard: scoreboard,
            history: history
        ).commandID
    }

    nonisolated static func fameExceptionalLoopProjectedOutcomeScoreboard(
        current: FameExceptionalLoopOutcomeScoreboard,
        plan: FameExceptionalLoopPlan,
        wasSuccessful: Bool,
        now: Date = Date()
    ) -> FameExceptionalLoopOutcomeScoreboard {
        let attempts = max(0, current.attempts) + 1
        let successes = min(
            attempts,
            max(0, current.successes) + (wasSuccessful ? 1 : 0)
        )
        let successRate = attempts > 0
            ? Int((Double(successes) / Double(attempts) * 100).rounded())
            : 0
        let successStreak = wasSuccessful
            ? max(0, current.successStreak) + 1
            : 0
        let failureStreak = wasSuccessful
            ? 0
            : max(0, current.failureStreak) + 1
        return FameExceptionalLoopOutcomeScoreboard(
            attempts: attempts,
            successes: successes,
            successRate: max(0, min(100, successRate)),
            successStreak: successStreak,
            failureStreak: failureStreak,
            lastFocusToken: fameExceptionalLoopOutcomeFocusToken(plan),
            lastOutcomeAt: now
        )
    }

    nonisolated static func fameExceptionalLoopProjectedOutcomeCommandHistory(
        _ history: [FameExceptionalLoopOutcomeCommandSample],
        plan: FameExceptionalLoopPlan,
        wasSuccessful: Bool,
        now: Date = Date(),
        maxSamples: Int = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryMaxSamples,
        windowDays: Int = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryWindowDays
    ) -> [FameExceptionalLoopOutcomeCommandSample] {
        fameExceptionalLoopOutcomeCommandHistoryWindow(
            history + [
                FameExceptionalLoopOutcomeCommandSample(
                    commandToken: fameExceptionalLoopOutcomeFocusToken(plan),
                    recordedAt: now.timeIntervalSince1970,
                    wasSuccess: wasSuccessful
                )
            ],
            now: now,
            maxSamples: maxSamples,
            windowDays: windowDays
        )
    }

    nonisolated static func fameExceptionalLoopOutcomeLaneSummaries(
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopOutcomeLaneSummaries {
        let highlights = fameExceptionalLoopOutcomeLaneHighlights(history: history)
        return FameExceptionalLoopOutcomeLaneSummaries(
            topWinLane: fameExceptionalLoopOutcomeTopWinLaneSummary(highlights.topWinLane),
            topRecoveryLane: fameExceptionalLoopOutcomeTopRecoveryLaneSummary(
                highlights.topRecoveryLane
            )
        )
    }

    nonisolated static func fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopOutcomeScoreboard? {
        fameExceptionalLoopOutcomeLaneHighlights(history: history).topRecoveryLane
    }

    nonisolated static func fameExceptionalLoopRecoveryLaneCommandID(
        _ token: String?
    ) -> String? {
        let normalizedToken = ActivityLogCommand.safeID(token ?? "")
        switch normalizedToken {
        case "run-fame-launch-rescue-followup-now",
             "run-fame-launch-control-hub",
             "run-fame-next-move-cadence-execution-kit",
             "run-fame-cadence-autopilot-loop",
             "run-fame-next-move-copy-drafts",
             "run-fame-command-center",
             "run-fame-spotlight-pack":
            return normalizedToken
        default:
            return nil
        }
    }

    nonisolated static func fameExceptionalLoopRecoveryLaneActionSummary(
        _ scoreboard: FameExceptionalLoopOutcomeScoreboard?
    ) -> String {
        guard let scoreboard,
              scoreboard.attempts > 0,
              let commandID = fameExceptionalLoopRecoveryLaneCommandID(scoreboard.lastFocusToken)
        else {
            return "none yet"
        }
        let misses = max(0, scoreboard.attempts - scoreboard.successes)
        guard misses > 0 else { return "none yet" }
        return "\(fameExceptionalLoopCommandTitle(commandID)) (\(misses)/\(scoreboard.attempts) misses, streak x\(scoreboard.failureStreak))"
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneCommandID(
        wasSuccessful: Bool,
        topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?,
        primaryCommandID: String,
        followupCommandID: String?,
        lastAutoRunAt: Date?,
        now: Date = Date(),
        missesRequired: Int = AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
        failureStreakRequired: Int = AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes * 60
        )
    ) -> String? {
        guard !wasSuccessful,
              let topRecoveryLane,
              topRecoveryLane.attempts > 0,
              let recoveryCommandID = fameExceptionalLoopRecoveryLaneCommandID(topRecoveryLane.lastFocusToken)
        else {
            return nil
        }

        let misses = max(0, topRecoveryLane.attempts - topRecoveryLane.successes)
        let normalizedMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(missesRequired)
        let normalizedFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                failureStreakRequired
            )
        guard misses >= normalizedMissesRequired,
              topRecoveryLane.failureStreak >= normalizedFailureStreakRequired else {
            return nil
        }
        guard recoveryCommandID != primaryCommandID,
              recoveryCommandID != followupCommandID else {
            return nil
        }
        guard cooldown > 0 else { return recoveryCommandID }
        guard let lastAutoRunAt else { return recoveryCommandID }
        guard now.timeIntervalSince(lastAutoRunAt) >= cooldown else { return nil }
        return recoveryCommandID
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneRunSummary(
        commandID: String,
        misses: Int,
        attempts: Int,
        failureStreak: Int
    ) -> String {
        "Auto recovery lane fired: \(fameExceptionalLoopCommandTitle(commandID)) (\(max(0, misses))/\(max(0, attempts)) misses, streak x\(max(0, failureStreak)))."
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneTuningDetailSummary(
        missesRequired: Int,
        failureStreakRequired: Int,
        cooldownMinutes: Int
    ) -> String {
        let normalizedMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                missesRequired
            )
        let normalizedFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                failureStreakRequired
            )
        let normalizedCooldownMinutes =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                cooldownMinutes
            )
        let cooldownTitle = normalizedCooldownMinutes == 0
            ? "cooldown off"
            : "cooldown \(normalizedCooldownMinutes)m"
        return "\(normalizedMissesRequired)+ misses, streak x\(normalizedFailureStreakRequired), \(cooldownTitle)"
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
        topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?,
        minimumAttempts: Int = 3
    ) -> FameExceptionalLoopAutoRecoveryLaneTuningRecommendation? {
        guard let topRecoveryLane,
              topRecoveryLane.attempts >= max(1, minimumAttempts),
              fameExceptionalLoopRecoveryLaneCommandID(topRecoveryLane.lastFocusToken) != nil else {
            return nil
        }

        let attempts = max(1, topRecoveryLane.attempts)
        let misses = max(0, attempts - topRecoveryLane.successes)
        let missRate = Int((Double(misses) / Double(attempts) * 100).rounded())
        let failureStreak = max(0, topRecoveryLane.failureStreak)

        let recommendation: FameExceptionalLoopAutoRecoveryLaneTuningRecommendation
        if attempts >= 8, missRate <= 20, failureStreak == 0 {
            recommendation = FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 5,
                failureStreakRequired: 3,
                cooldownMinutes: 60,
                rationale: "Lane is stable (\(misses)/\(attempts) misses); reduce auto-fire frequency."
            )
        } else if attempts >= 5, missRate <= 35, failureStreak <= 1 {
            recommendation = FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 4,
                failureStreakRequired: 2,
                cooldownMinutes: 30,
                rationale: "Lane is recovering (\(misses)/\(attempts) misses); keep auto-recovery available but less eager."
            )
        } else if failureStreak >= 4 || (attempts >= 4 && missRate >= 85) {
            recommendation = FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 2,
                failureStreakRequired: 1,
                cooldownMinutes: 5,
                rationale: "Pressure is persistent (\(misses)/\(attempts) misses, streak x\(failureStreak)); fire recovery quickly."
            )
        } else if failureStreak >= 2 || (attempts >= 4 && missRate >= 65) {
            recommendation = FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 2,
                failureStreakRequired: 1,
                cooldownMinutes: 10,
                rationale: "Lane is slipping (\(misses)/\(attempts) misses, streak x\(failureStreak)); lower arming thresholds."
            )
        } else {
            recommendation = FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                missesRequired: 3,
                failureStreakRequired: 2,
                cooldownMinutes: 20,
                rationale: "Lane telemetry is mixed (\(misses)/\(attempts) misses); keep balanced defaults."
            )
        }

        return FameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
            missesRequired: AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                recommendation.missesRequired
            ),
            failureStreakRequired:
                AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                    recommendation.failureStreakRequired
                ),
            cooldownMinutes:
                AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                    recommendation.cooldownMinutes
                ),
            rationale: recommendation.rationale
        )
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
        recommendation: FameExceptionalLoopAutoRecoveryLaneTuningRecommendation?,
        currentMissesRequired: Int,
        currentFailureStreakRequired: Int,
        currentCooldownMinutes: Int
    ) -> String {
        let currentMissesRequired = AppDefaults
            .normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(currentMissesRequired)
        let currentFailureStreakRequired = AppDefaults
            .normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                currentFailureStreakRequired
            )
        let currentCooldownMinutes = AppDefaults
            .normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(currentCooldownMinutes)
        let currentSummary = fameExceptionalLoopAutoRecoveryLaneTuningDetailSummary(
            missesRequired: currentMissesRequired,
            failureStreakRequired: currentFailureStreakRequired,
            cooldownMinutes: currentCooldownMinutes
        )

        guard let recommendation else {
            return "Need at least 3 recovery-lane attempts before adaptive tuning can calibrate (current \(currentSummary))."
        }

        let recommendationSummary = fameExceptionalLoopAutoRecoveryLaneTuningDetailSummary(
            missesRequired: recommendation.missesRequired,
            failureStreakRequired: recommendation.failureStreakRequired,
            cooldownMinutes: recommendation.cooldownMinutes
        )
        let isAlreadyAligned =
            recommendation.missesRequired == currentMissesRequired
            && recommendation.failureStreakRequired == currentFailureStreakRequired
            && recommendation.cooldownMinutes == currentCooldownMinutes
        if isAlreadyAligned {
            return "Current tuning already matches telemetry (\(currentSummary)). \(recommendation.rationale)"
        }
        return "Suggested \(recommendationSummary) from telemetry (current \(currentSummary)). \(recommendation.rationale)"
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
        recommendation: FameExceptionalLoopAutoRecoveryLaneTuningRecommendation?,
        currentMissesRequired: Int,
        currentFailureStreakRequired: Int,
        currentCooldownMinutes: Int
    ) -> FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus {
        let summary = fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
            recommendation: recommendation,
            currentMissesRequired: currentMissesRequired,
            currentFailureStreakRequired: currentFailureStreakRequired,
            currentCooldownMinutes: currentCooldownMinutes
        )
        let normalizedCurrentMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                currentMissesRequired
            )
        let normalizedCurrentFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                currentFailureStreakRequired
            )
        let normalizedCurrentCooldownMinutes =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                currentCooldownMinutes
            )
        guard let recommendation else {
            return FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                title: "Auto-Tune Recovery: Waiting for Telemetry",
                toolTip: summary,
                isEnabled: false
            )
        }

        let recommendationSummary = fameExceptionalLoopAutoRecoveryLaneTuningDetailSummary(
            missesRequired: recommendation.missesRequired,
            failureStreakRequired: recommendation.failureStreakRequired,
            cooldownMinutes: recommendation.cooldownMinutes
        )
        let isAlreadyAligned = recommendation.missesRequired == normalizedCurrentMissesRequired
            && recommendation.failureStreakRequired == normalizedCurrentFailureStreakRequired
            && recommendation.cooldownMinutes == normalizedCurrentCooldownMinutes
        if isAlreadyAligned {
            return FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                title: "Auto-Tune Recovery: Tuned",
                toolTip: summary,
                isEnabled: false
            )
        }

        return FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            title: "Auto-Tune Recovery: Suggested · \(recommendationSummary)",
            toolTip: summary,
            isEnabled: true
        )
    }

    nonisolated static func fameExceptionalLoopLatestRecapStatus(
        hasSavedRecap: Bool
    ) -> FameExceptionalLoopLatestRecapStatus {
        if hasSavedRecap {
            return FameExceptionalLoopLatestRecapStatus(
                title: "Open Latest Exceptional Loop Recap",
                subtitle: "Open latest run recap for the Fame exceptional loop",
                toolTip: "Open latest run recap for the Fame exceptional loop.",
                isEnabled: true
            )
        }

        return FameExceptionalLoopLatestRecapStatus(
            title: "Open Latest Exceptional Loop Recap (Unavailable)",
            subtitle: "No saved recap yet. Run Fame Exceptional Loop first.",
            toolTip: "No saved exceptional loop recap yet. Run Fame Exceptional Loop first.",
            isEnabled: false
        )
    }

    nonisolated static func fameExceptionalLoopLatestRecapCommandPaletteActionState(
        status: FameExceptionalLoopLatestRecapStatus
    ) -> (
        subtitle: String,
        isEnabled: Bool,
        disabledReason: String
    ) {
        (
            subtitle: status.subtitle,
            isEnabled: status.isEnabled,
            disabledReason: status.isEnabled ? "Latest recap ready." : status.title
        )
    }

    nonisolated static func hasStoredFameExceptionalLoopOutcomeTelemetry(
        attempts: Int,
        successes: Int,
        successStreak: Int,
        failureStreak: Int,
        lastFocusToken: String?,
        lastOutcomeAt: Date?,
        commandHistory: [FameExceptionalLoopOutcomeCommandSample]
    ) -> Bool {
        let normalizedAttempts = max(0, attempts)
        let normalizedSuccesses = max(0, successes)
        let normalizedSuccessStreak = max(0, successStreak)
        let normalizedFailureStreak = max(0, failureStreak)
        return normalizedAttempts > 0
            || normalizedSuccesses > 0
            || normalizedSuccessStreak > 0
            || normalizedFailureStreak > 0
            || lastFocusToken != nil
            || lastOutcomeAt != nil
            || !commandHistory.isEmpty
    }

    nonisolated static func fameExceptionalLoopOutcomeTuningResetStatus(
        attempts: Int,
        successes: Int,
        successStreak: Int,
        failureStreak: Int,
        lastFocusToken: String?,
        lastOutcomeAt: Date?,
        commandHistory: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopOutcomeTuningResetStatus {
        guard hasStoredFameExceptionalLoopOutcomeTelemetry(
            attempts: attempts,
            successes: successes,
            successStreak: successStreak,
            failureStreak: failureStreak,
            lastFocusToken: lastFocusToken,
            lastOutcomeAt: lastOutcomeAt,
            commandHistory: commandHistory
        ) else {
            return FameExceptionalLoopOutcomeTuningResetStatus(
                title: "Reset Exceptional Loop Tuning: Baseline",
                subtitle: "Adaptive outcome telemetry is already at baseline.",
                toolTip: "No adaptive outcome telemetry to clear yet.",
                isEnabled: false
            )
        }

        return FameExceptionalLoopOutcomeTuningResetStatus(
            title: "Reset Exceptional Loop Tuning",
            subtitle: "Clear adaptive outcome streaks and focus memory.",
            toolTip: "Clear adaptive outcome streaks and focus memory.",
            isEnabled: true
        )
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneStatusSummary(
        topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?,
        lastAutoRunAt: Date?,
        now: Date = Date(),
        missesRequired: Int = AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
        failureStreakRequired: Int = AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes * 60
        )
    ) -> String {
        guard let topRecoveryLane,
              topRecoveryLane.attempts > 0,
              let recoveryCommandID = fameExceptionalLoopRecoveryLaneCommandID(topRecoveryLane.lastFocusToken)
        else {
            return "Auto recovery lane: Not armed (no eligible lane telemetry yet)."
        }

        let misses = max(0, topRecoveryLane.attempts - topRecoveryLane.successes)
        let normalizedMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(missesRequired)
        let normalizedFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                failureStreakRequired
            )
        let routeTitle = fameExceptionalLoopCommandTitle(recoveryCommandID)
        guard misses >= normalizedMissesRequired,
              topRecoveryLane.failureStreak >= normalizedFailureStreakRequired else {
            return "Auto recovery lane: Not armed (\(misses)/\(topRecoveryLane.attempts) misses, streak x\(topRecoveryLane.failureStreak))."
        }
        guard cooldown > 0 else {
            return "Auto recovery lane: Armed for \(routeTitle) (cooldown off)."
        }
        guard let lastAutoRunAt else {
            return "Auto recovery lane: Armed for \(routeTitle)."
        }
        let remainingSeconds = cooldown - now.timeIntervalSince(lastAutoRunAt)
        guard remainingSeconds > 0 else {
            return "Auto recovery lane: Armed for \(routeTitle)."
        }
        let remainingMinutes = max(1, Int(ceil(remainingSeconds / 60)))
        return "Auto recovery lane: Cooling down \(remainingMinutes)m before \(routeTitle)."
    }

    nonisolated static func fameExceptionalLoopAutoRecoveryLaneMenuStatus(
        topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?,
        lastAutoRunAt: Date?,
        now: Date = Date(),
        missesRequired: Int = AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
        failureStreakRequired: Int = AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes * 60
        )
    ) -> FameExceptionalLoopAutoRecoveryLaneMenuStatus {
        let summary = fameExceptionalLoopAutoRecoveryLaneStatusSummary(
            topRecoveryLane: topRecoveryLane,
            lastAutoRunAt: lastAutoRunAt,
            now: now,
            missesRequired: missesRequired,
            failureStreakRequired: failureStreakRequired,
            cooldown: cooldown
        )

        guard let topRecoveryLane,
              topRecoveryLane.attempts > 0,
              let recoveryCommandID = fameExceptionalLoopRecoveryLaneCommandID(
                  topRecoveryLane.lastFocusToken
              ) else {
            return FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Not Armed",
                toolTip: summary
            )
        }

        let misses = max(0, topRecoveryLane.attempts - topRecoveryLane.successes)
        let normalizedMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(missesRequired)
        let normalizedFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                failureStreakRequired
            )
        guard misses >= normalizedMissesRequired,
              topRecoveryLane.failureStreak >= normalizedFailureStreakRequired else {
            return FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Not Armed",
                toolTip: summary
            )
        }

        let recoveryTitle = fameExceptionalLoopCommandTitle(recoveryCommandID)
        guard cooldown > 0 else {
            return FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                title: "Auto Recovery Lane: Armed (Cooldown Off)",
                toolTip: summary
            )
        }

        if let lastAutoRunAt {
            let remainingSeconds = cooldown - now.timeIntervalSince(lastAutoRunAt)
            if remainingSeconds > 0 {
                let remainingMinutes = max(1, Int(ceil(remainingSeconds / 60)))
                return FameExceptionalLoopAutoRecoveryLaneMenuStatus(
                    title: "Auto Recovery Lane: Cooling Down (\(remainingMinutes)m) · \(recoveryTitle)",
                    toolTip: summary
                )
            }
        }

        return FameExceptionalLoopAutoRecoveryLaneMenuStatus(
            title: "Auto Recovery Lane: Armed · \(recoveryTitle)",
            toolTip: summary
        )
    }

    nonisolated static func fameExceptionalLoopRecoveryLaneMenuStatus(
        _ scoreboard: FameExceptionalLoopOutcomeScoreboard?
    ) -> FameExceptionalLoopRecoveryLaneMenuStatus {
        guard let scoreboard,
              scoreboard.attempts > 0,
              let recoveryCommandID = fameExceptionalLoopRecoveryLaneCommandID(scoreboard.lastFocusToken)
        else {
            return FameExceptionalLoopRecoveryLaneMenuStatus(
                title: "Run Recovery Lane Now (Not Armed)",
                toolTip: "No recovery lane is armed yet. Run Fame Exceptional Loop to seed telemetry.",
                isEnabled: false
            )
        }

        let misses = max(0, scoreboard.attempts - scoreboard.successes)
        let recoveryTitle = fameExceptionalLoopCommandTitle(recoveryCommandID)
        guard misses >= 2, scoreboard.failureStreak >= 1 else {
            return FameExceptionalLoopRecoveryLaneMenuStatus(
                title: "Run Recovery Lane Now (Not Armed)",
                toolTip: "Top recovery lane \(recoveryTitle) is stable (\(misses)/\(scoreboard.attempts) misses, streak x\(scoreboard.failureStreak)). Arms at 2+ misses with an active failure streak.",
                isEnabled: false
            )
        }

        return FameExceptionalLoopRecoveryLaneMenuStatus(
            title: "Run Recovery Lane Now: \(recoveryTitle)",
            toolTip: "Top recovery lane \(misses)/\(scoreboard.attempts) misses, streak x\(scoreboard.failureStreak). Click to run \(recoveryTitle) now.",
            isEnabled: true
        )
    }

    nonisolated static func fameExceptionalLoopMenuOutcomeSummaryToolTip(
        scoreboard: FameExceptionalLoopOutcomeScoreboard,
        laneSummaries: FameExceptionalLoopOutcomeLaneSummaries,
        recoveryActionSummary: String
    ) -> String {
        "\(fameExceptionalLoopOutcomeStatusTitle(scoreboard)) Top win lane: \(laneSummaries.topWinLane). Top recovery lane: \(laneSummaries.topRecoveryLane). Recovery next action: \(recoveryActionSummary)."
    }

    nonisolated static func fameExceptionalLoopOutcomeTopWinLaneSummary(
        _ scoreboard: FameExceptionalLoopOutcomeScoreboard?
    ) -> String {
        guard let scoreboard,
              scoreboard.attempts > 0,
              scoreboard.successes > 0,
              let token = scoreboard.lastFocusToken,
              !token.isEmpty else {
            return "none yet"
        }
        let title = fameExceptionalLoopCommandTitle(token)
        return "\(title) \(scoreboard.successes)/\(scoreboard.attempts) (\(scoreboard.successRate)%), streak x\(scoreboard.successStreak)"
    }

    nonisolated static func fameExceptionalLoopOutcomeTopRecoveryLaneSummary(
        _ scoreboard: FameExceptionalLoopOutcomeScoreboard?
    ) -> String {
        guard let scoreboard,
              scoreboard.attempts > 0,
              let token = scoreboard.lastFocusToken,
              !token.isEmpty else {
            return "none yet"
        }
        let misses = max(0, scoreboard.attempts - scoreboard.successes)
        guard misses > 0 else {
            return "none yet"
        }
        let title = fameExceptionalLoopCommandTitle(token)
        return "\(title) misses \(misses)/\(scoreboard.attempts), streak x\(scoreboard.failureStreak)"
    }

    private nonisolated static func fameExceptionalLoopOutcomeLaneHighlights(
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopOutcomeLaneHighlights {
        let commandTokens = Array(
            Set(
                history
                    .map { ActivityLogCommand.safeID($0.commandToken) }
                    .filter { !$0.isEmpty }
            )
        ).sorted()
        let scoreboards = commandTokens.compactMap { token in
            fameExceptionalLoopOutcomeCommandScoreboard(
                commandToken: token,
                history: history
            )
        }

        let topWinLane = scoreboards
            .filter { $0.successes > 0 }
            .sorted(by: fameExceptionalLoopOutcomePrefersWinLane(_:_:))
            .first
        let topRecoveryLane = scoreboards
            .filter { max(0, $0.attempts - $0.successes) > 0 }
            .sorted(by: fameExceptionalLoopOutcomePrefersRecoveryLane(_:_:))
            .first

        return FameExceptionalLoopOutcomeLaneHighlights(
            topWinLane: topWinLane,
            topRecoveryLane: topRecoveryLane
        )
    }

    private nonisolated static func fameExceptionalLoopOutcomePrefersWinLane(
        _ lhs: FameExceptionalLoopOutcomeScoreboard,
        _ rhs: FameExceptionalLoopOutcomeScoreboard
    ) -> Bool {
        if lhs.successStreak != rhs.successStreak {
            return lhs.successStreak > rhs.successStreak
        }
        if lhs.successRate != rhs.successRate {
            return lhs.successRate > rhs.successRate
        }
        if lhs.successes != rhs.successes {
            return lhs.successes > rhs.successes
        }
        if lhs.attempts != rhs.attempts {
            return lhs.attempts > rhs.attempts
        }
        let lhsStamp = lhs.lastOutcomeAt?.timeIntervalSince1970 ?? 0
        let rhsStamp = rhs.lastOutcomeAt?.timeIntervalSince1970 ?? 0
        if lhsStamp != rhsStamp {
            return lhsStamp > rhsStamp
        }
        let lhsToken = ActivityLogCommand.safeID(lhs.lastFocusToken ?? "")
        let rhsToken = ActivityLogCommand.safeID(rhs.lastFocusToken ?? "")
        guard lhsToken != rhsToken else { return false }
        return lhsToken < rhsToken
    }

    private nonisolated static func fameExceptionalLoopOutcomePrefersRecoveryLane(
        _ lhs: FameExceptionalLoopOutcomeScoreboard,
        _ rhs: FameExceptionalLoopOutcomeScoreboard
    ) -> Bool {
        if lhs.failureStreak != rhs.failureStreak {
            return lhs.failureStreak > rhs.failureStreak
        }
        let lhsMisses = max(0, lhs.attempts - lhs.successes)
        let rhsMisses = max(0, rhs.attempts - rhs.successes)
        if lhsMisses != rhsMisses {
            return lhsMisses > rhsMisses
        }
        if lhs.successRate != rhs.successRate {
            return lhs.successRate < rhs.successRate
        }
        if lhs.attempts != rhs.attempts {
            return lhs.attempts > rhs.attempts
        }
        let lhsStamp = lhs.lastOutcomeAt?.timeIntervalSince1970 ?? 0
        let rhsStamp = rhs.lastOutcomeAt?.timeIntervalSince1970 ?? 0
        if lhsStamp != rhsStamp {
            return lhsStamp > rhsStamp
        }
        let lhsToken = ActivityLogCommand.safeID(lhs.lastFocusToken ?? "")
        let rhsToken = ActivityLogCommand.safeID(rhs.lastFocusToken ?? "")
        guard lhsToken != rhsToken else { return false }
        return lhsToken < rhsToken
    }

    nonisolated static func fameExceptionalLoopPlanWithAdaptiveTuning(
        _ plan: FameExceptionalLoopPlan,
        scoreboard: FameExceptionalLoopOutcomeScoreboard,
        commandScoreboard: FameExceptionalLoopOutcomeScoreboard? = nil
    ) -> FameExceptionalLoopPlan {
        let focusToken = fameExceptionalLoopOutcomeFocusToken(plan)
        let adaptiveScoreboard: FameExceptionalLoopOutcomeScoreboard
        if let commandScoreboard,
           commandScoreboard.lastFocusToken == focusToken,
           commandScoreboard.attempts > 0 {
            adaptiveScoreboard = commandScoreboard
        } else {
            guard scoreboard.lastFocusToken == focusToken else {
                return plan
            }
            adaptiveScoreboard = scoreboard
        }

        switch plan.primaryCommandID {
        case "run-fame-launch-rescue-followup-now",
             "run-fame-launch-control-hub":
            return plan
        default:
            break
        }

        if adaptiveScoreboard.failureStreak >= 2 {
            switch plan.primaryCommandID {
            case "run-fame-cadence-autopilot-loop":
                return FameExceptionalLoopPlan(
                    focusTitle: "Cadence Recovery Pivot",
                    primaryCommandID: "run-fame-next-move-cadence-execution-kit",
                    reasonLine: "Cadence reinforcement stalled for x\(adaptiveScoreboard.failureStreak). Re-seed with the execution kit before compounding.",
                    followupActionID: "copy-fame-cadence-share-line",
                    followupReasonLine: "Ship one immediate share line after the reset route."
                )
            case "run-fame-next-move-copy-drafts":
                return FameExceptionalLoopPlan(
                    focusTitle: "Execution Reset",
                    primaryCommandID: "run-fame-command-center",
                    reasonLine: "Next-move compounding stalled for x\(adaptiveScoreboard.failureStreak). Rebuild the 72h execution lane before another draft burst.",
                    followupActionID: "copy-fame-cadence-share-pack",
                    followupReasonLine: "Copy a fresh share pack once the reset lane is clear."
                )
            default:
                break
            }
        }

        if adaptiveScoreboard.successStreak >= 3 {
            switch plan.primaryCommandID {
            case "run-fame-cadence-autopilot-loop":
                return FameExceptionalLoopPlan(
                    focusTitle: "Compounding Sprint",
                    primaryCommandID: "run-fame-next-move-copy-drafts",
                    reasonLine: "Cadence reinforcement is landing x\(adaptiveScoreboard.successStreak). Press the advantage with ranked draft shipping.",
                    followupActionID: "copy-fame-cadence-share-pack",
                    followupReasonLine: "Bundle the strongest variants into one launch-ready pack."
                )
            case "run-fame-next-move-copy-drafts":
                return FameExceptionalLoopPlan(
                    focusTitle: "Breakout Amplification+",
                    primaryCommandID: "run-fame-spotlight-pack",
                    reasonLine: "Compounding route is winning x\(adaptiveScoreboard.successStreak). Expand into a spotlight burst while momentum is hot.",
                    followupActionID: "copy-fame-cadence-share-pack",
                    followupReasonLine: "Copy the share pack and distribute the breakout lane immediately."
                )
            default:
                break
            }
        }

        return plan
    }

    nonisolated static func fameExceptionalLoopPlan(
        signal: FamePulseAlertSignal?,
        transition: FamePulseRiskTransition?,
        scorecard: FameDailyScorecardState,
        launchStatus: FameLaunchCountdownStatus?,
        launchRescueSelfHealAttentionIssueToken: String?,
        cadenceCurrentStreak: Int,
        cadenceBestStreak: Int
    ) -> FameExceptionalLoopPlan {
        let normalizedIssueToken = launchRescueSelfHealAttentionIssueToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if let normalizedIssueToken, normalizedIssueToken.hasPrefix("missing-") {
            return FameExceptionalLoopPlan(
                focusTitle: "Self-Heal Kickstart",
                primaryCommandID: "run-fame-launch-rescue-followup-now",
                reasonLine: "Launch rescue self-heal telemetry is missing after the latest trigger. Kick off the follow-up route now.",
                followupActionID: "copy-fame-launch-rescue-snapshot",
                followupReasonLine: "Capture a fresh launch rescue snapshot so recovery proof is logged."
            )
        }
        if let normalizedIssueToken, normalizedIssueToken.hasPrefix("stale-") {
            return FameExceptionalLoopPlan(
                focusTitle: "Self-Heal Recovery",
                primaryCommandID: "run-fame-launch-rescue-followup-now",
                reasonLine: "Launch rescue self-heal telemetry is stale. Refresh the follow-up route now.",
                followupActionID: "copy-fame-launch-rescue-snapshot",
                followupReasonLine: "Capture a fresh launch rescue snapshot for recovery proof."
            )
        }
        if let normalizedIssueToken, normalizedIssueToken.hasPrefix("mismatch-") {
            return FameExceptionalLoopPlan(
                focusTitle: "Self-Heal Alignment",
                primaryCommandID: "run-fame-launch-rescue-followup-now",
                reasonLine: "Launch rescue self-heal telemetry mismatches the current trigger context.",
                followupActionID: "copy-fame-launch-rescue-snapshot",
                followupReasonLine: "Capture a fresh launch rescue snapshot after the alignment run."
            )
        }

        if let urgency = fameLaunchBadgeUrgency(launchStatus),
           fameLaunchBadgeUrgencyPriority(urgency) >= fameLaunchBadgeUrgencyPriority(.high) {
            let urgencyLabel = fameLaunchBadgeUrgencyLabel(urgency)
            return FameExceptionalLoopPlan(
                focusTitle: "Launch \(urgencyLabel) Control",
                primaryCommandID: "run-fame-launch-control-hub",
                reasonLine: "Launch urgency is \(urgencyLabel.lowercased()); run the full control hub before momentum slips.",
                followupActionID: "copy-fame-launch-control-brief",
                followupReasonLine: "Copy the launch control brief so execution stays synchronized."
            )
        }

        let nextMoveCommandID = fameNextMoveCommandID(
            signal: signal,
            transition: transition,
            scorecard: scorecard
        )
        let nextMoveLabel = fameNextMoveCommandLabel(nextMoveCommandID)
        let normalizedCadenceCurrentStreak = max(0, cadenceCurrentStreak)
        let normalizedCadenceBestStreak = max(
            normalizedCadenceCurrentStreak,
            max(0, cadenceBestStreak)
        )

        if scorecard.riskLevel == "Low",
           scorecard.scoreDelta >= 10,
           normalizedCadenceBestStreak >= 3 {
            return FameExceptionalLoopPlan(
                focusTitle: "Breakout Amplification",
                primaryCommandID: "run-fame-spotlight-pack",
                reasonLine: "Momentum is compounding (+\(max(0, scorecard.scoreDelta))). Package the streak into social proof assets.",
                followupActionID: "copy-fame-cadence-share-pack",
                followupReasonLine: "Copy the cadence share pack to publish breakout variants quickly."
            )
        }

        if normalizedCadenceCurrentStreak == 0 {
            return FameExceptionalLoopPlan(
                focusTitle: "Cadence Ignition",
                primaryCommandID: "run-fame-next-move-cadence-execution-kit",
                reasonLine: "No active cadence streak. Run next move with execution kit to seed one now.",
                followupActionID: nil,
                followupReasonLine: nil
            )
        }

        if normalizedCadenceCurrentStreak < 3 {
            return FameExceptionalLoopPlan(
                focusTitle: "Cadence Reinforcement",
                primaryCommandID: "run-fame-cadence-autopilot-loop",
                reasonLine: "Protect your streak and climb toward x3 with a fresh autopilot run.",
                followupActionID: "copy-fame-cadence-share-line",
                followupReasonLine: "Copy one momentum share line for immediate publishing."
            )
        }

        return FameExceptionalLoopPlan(
            focusTitle: "Next Move Compounding",
            primaryCommandID: "run-fame-next-move-copy-drafts",
            reasonLine: "Run \(nextMoveLabel), then ship ranked drafts and follow-ups without delay.",
            followupActionID: nil,
            followupReasonLine: nil
        )
    }

    nonisolated static func fameExceptionalLoopCommandTitle(_ commandID: String) -> String {
        switch commandID {
        case "run-fame-command-center":
            return "Run Fame Command Center"
        case "run-fame-launch-control-hub":
            return "Run Launch Control Hub"
        case "copy-fame-launch-control-brief":
            return "Copy Launch Control Brief"
        case "copy-fame-launch-rescue-snapshot":
            return "Copy Launch Rescue Snapshot"
        case "run-fame-next-move-copy-drafts":
            return "Run Next Move + Copy Draft Pack"
        default:
            return fameOnboardingCommandTitle(commandID)
        }
    }

    nonisolated static func fameExceptionalLoopActionTitle(_ plan: FameExceptionalLoopPlan) -> String {
        "Run Fame Exceptional Loop: \(plan.focusTitle)"
    }

    nonisolated static func fameExceptionalLoopActionSubtitle(_ plan: FameExceptionalLoopPlan) -> String {
        let primaryTitle = fameExceptionalLoopCommandTitle(plan.primaryCommandID)
        var segments = ["Primary: \(primaryTitle).", plan.reasonLine]
        if let followupActionID = plan.followupActionID {
            let followupTitle = fameExceptionalLoopCommandTitle(followupActionID)
            let followupReasonLine = plan.followupReasonLine ?? "Close the loop before context drifts."
            segments.append("Follow-up: \(followupTitle). \(followupReasonLine)")
        }
        return segments.joined(separator: " ")
    }

    nonisolated static func fameExceptionalLoopActionSubtitle(
        _ plan: FameExceptionalLoopPlan,
        healthSnapshot: FameExceptionalLoopHealthSnapshot
    ) -> String {
        let baseSubtitle = fameExceptionalLoopActionSubtitle(plan)
        let confidenceTitle = healthSnapshot.recommendedActionConfidenceTitle
        return "\(baseSubtitle) Telemetry next move [\(confidenceTitle)]: \(healthSnapshot.recommendedNextAction) Why: \(healthSnapshot.recommendedActionWhy)"
    }

    nonisolated static func fameExceptionalLoopCommandPaletteSignalBadge(
        _ healthSnapshot: FameExceptionalLoopHealthSnapshot
    ) -> CommandPaletteAction.SignalBadge {
        let normalizedConfidence = healthSnapshot.recommendedActionConfidenceTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let tone: CommandPaletteAction.SignalBadge.Tone
        switch normalizedConfidence {
        case "high":
            tone = .high
        case "medium":
            tone = .medium
        default:
            tone = .low
        }
        let confidenceTitle = healthSnapshot.recommendedActionConfidenceTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return CommandPaletteAction.SignalBadge(
            title: "Loop \(confidenceTitle)",
            tone: tone,
            helpText: "\(healthSnapshot.recommendedNextAction) \(healthSnapshot.recommendedActionWhy)",
            recommendedActionID: healthSnapshot.recommendedActionCommandID,
            recommendedActionTitle: healthSnapshot.recommendedActionTitle
        )
    }

    nonisolated static func fameExceptionalLoopActionSystemImage(_ plan: FameExceptionalLoopPlan) -> String {
        switch plan.primaryCommandID {
        case "run-fame-launch-rescue-followup-now":
            return "bandage.fill"
        case "run-fame-launch-control-hub":
            return "bolt.trianglebadge.exclamationmark"
        case "run-fame-next-move-cadence-execution-kit":
            return "flame.fill"
        case "run-fame-cadence-autopilot-loop":
            return "arrow.triangle.2.circlepath.circle.fill"
        case "run-fame-spotlight-pack":
            return "sparkles.tv"
        default:
            return "sparkles"
        }
    }

    nonisolated static func fameExceptionalLoopCompletionMessage(_ plan: FameExceptionalLoopPlan) -> String {
        if let followupActionID = plan.followupActionID {
            return "Exceptional loop complete: \(plan.focusTitle). Ran \(fameExceptionalLoopCommandTitle(plan.primaryCommandID)) + \(fameExceptionalLoopCommandTitle(followupActionID))."
        }
        return "Exceptional loop complete: \(plan.focusTitle). Ran \(fameExceptionalLoopCommandTitle(plan.primaryCommandID))."
    }

    nonisolated static func fameExceptionalLoopActivityDetail(_ plan: FameExceptionalLoopPlan) -> String {
        let normalizedFocusTokenSource = plan.focusTitle
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let focusToken = ActivityLogCommand.safeID(normalizedFocusTokenSource)
        let primaryToken = ActivityLogCommand.safeID(plan.primaryCommandID)
        let followupToken = ActivityLogCommand.safeID(plan.followupActionID ?? "none")
        return "run-fame-exceptional-loop-\(focusToken)-\(primaryToken)-\(followupToken)"
    }

    nonisolated static func fameExceptionalLoopMenuStatusTitle(
        _ plan: FameExceptionalLoopPlan,
        hotKeyAvailable: Bool
    ) -> String {
        let shortcutStatus = hotKeyAvailable ? "⌥⇧E ready" : "⌥⇧E busy"
        return "Exceptional Loop Focus: \(plan.focusTitle) · \(shortcutStatus)"
    }

    nonisolated static func fameExceptionalLoopMenuStatusToolTip(
        _ plan: FameExceptionalLoopPlan,
        hotKeyAvailable: Bool
    ) -> String {
        let primaryTitle = fameExceptionalLoopCommandTitle(plan.primaryCommandID)
        let shortcutLine = hotKeyAvailable
            ? "Shortcut: global ⌥⇧E runs this loop."
            : "Shortcut: global ⌥⇧E is busy; run from menu or Command Palette."
        if let followupActionID = plan.followupActionID {
            let followupTitle = fameExceptionalLoopCommandTitle(followupActionID)
            let followupReason = plan.followupReasonLine ?? "Close the loop before context drifts."
            return "Primary: \(primaryTitle). \(plan.reasonLine) Follow-up: \(followupTitle). \(followupReason) \(shortcutLine)"
        }
        return "Primary: \(primaryTitle). \(plan.reasonLine) \(shortcutLine)"
    }

    nonisolated static func fameExceptionalLoopRecapMarkdown(
        plan: FameExceptionalLoopPlan,
        generatedAt: String,
        projectedOutcomeStatusTitle: String,
        projectedLaneSummaries: FameExceptionalLoopOutcomeLaneSummaries,
        projectedRecoveryActionSummary: String
    ) -> String {
        let primaryTitle = fameExceptionalLoopCommandTitle(plan.primaryCommandID)
        let followupSection: String
        if let followupActionID = plan.followupActionID {
            let followupTitle = fameExceptionalLoopCommandTitle(followupActionID)
            let followupReason = plan.followupReasonLine ?? "Close the loop before context drifts."
            followupSection = """

            Follow-up action:
            - `\(followupTitle)` (`\(followupActionID)`)
            - Why: \(followupReason)
            """
        } else {
            followupSection = """

            Follow-up action:
            - None required for this loop.
            """
        }

        return """
        # Fluid Reader Fame Exceptional Loop Recap

        Generated: \(generatedAt)

        Focus:
        - \(plan.focusTitle)

        Primary action:
        - `\(primaryTitle)` (`\(plan.primaryCommandID)`)
        - Why: \(plan.reasonLine)\(followupSection)

        Outcome telemetry (projected):
        - \(projectedOutcomeStatusTitle)
        - Top win lane: \(projectedLaneSummaries.topWinLane)
        - Top recovery lane: \(projectedLaneSummaries.topRecoveryLane)
        - Recovery next action: \(projectedRecoveryActionSummary)

        Completion:
        - \(fameExceptionalLoopCompletionMessage(plan))
        - Open latest recap with `open-latest-fame-exceptional-loop-recap`.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    struct FameOnboardingNudgePlan: Equatable {
        let day: Int
        let phaseTitle: String
        let focusLine: String
        let primaryCommandID: String
        let backupCommandID: String
    }

    nonisolated static func fameOnboardingNudgePlan(
        day: Int,
        currentStreak: Int,
        bestStreak: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> FameOnboardingNudgePlan {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(max(7, normalizedWindowDays), day))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        switch normalizedDay {
        case 1...2:
            if normalizedBestStreak > 0 {
                return FameOnboardingNudgePlan(
                    day: normalizedDay,
                    phaseTitle: "Kickoff",
                    focusLine: "Stabilize your first cadence streak and keep the queue warm.",
                    primaryCommandID: "run-fame-cadence-autopilot-loop",
                    backupCommandID: "run-fame-next-move-cadence-execution-kit"
                )
            }
            return FameOnboardingNudgePlan(
                day: normalizedDay,
                phaseTitle: "Kickoff",
                focusLine: "Ship your first proof loop and lock your first streak point.",
                primaryCommandID: "run-fame-next-move-cadence-execution-kit",
                backupCommandID: "run-fame-cadence-celebration-demo"
            )
        case 3...4:
            if normalizedCurrentStreak > 0 {
                return FameOnboardingNudgePlan(
                    day: normalizedDay,
                    phaseTitle: "Momentum",
                    focusLine: "Push the streak to the next milestone before the day closes.",
                    primaryCommandID: "run-fame-cadence-autopilot-loop",
                    backupCommandID: "run-fame-cadence-momentum-brief"
                )
            }
            return FameOnboardingNudgePlan(
                day: normalizedDay,
                phaseTitle: "Momentum",
                focusLine: "Restart cadence fast and recover your best-streak pace.",
                primaryCommandID: "run-fame-next-move-cadence-execution-kit",
                backupCommandID: "run-fame-cadence-autopilot-loop"
            )
        default:
            if normalizedBestStreak >= 5 {
                return FameOnboardingNudgePlan(
                    day: normalizedDay,
                    phaseTitle: "Breakout",
                    focusLine: "Package momentum into social proof and a launch-ready brief.",
                    primaryCommandID: "run-fame-cadence-momentum-brief",
                    backupCommandID: "run-fame-spotlight-pack"
                )
            }
            return FameOnboardingNudgePlan(
                day: normalizedDay,
                phaseTitle: "Breakout",
                focusLine: "Hit your first x5 cadence milestone this week.",
                primaryCommandID: "run-fame-cadence-autopilot-loop",
                backupCommandID: "run-fame-cadence-celebration-demo"
            )
        }
    }

    nonisolated static func fameOnboardingNudgeActionTitle(_ plan: FameOnboardingNudgePlan) -> String {
        "Fame Onboarding Day \(plan.day): \(plan.phaseTitle)"
    }

    nonisolated static func isFameOnboardingScorecardActionEligible(
        fameOnboardingEnabled: Bool,
        cadenceBestStreak: Int,
        onboardingDay: Int,
        completedDays: Int,
        onboardingWindowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> Bool {
        guard fameOnboardingEnabled else { return false }
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            onboardingWindowDays
        )
        let normalizedBestStreak = max(0, cadenceBestStreak)
        guard normalizedBestStreak < 10 else { return false }
        let normalizedDay = max(1, onboardingDay)
        guard normalizedDay <= normalizedWindowDays else { return false }
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        return normalizedCompletedDays < normalizedWindowDays
    }

    nonisolated static func fameOnboardingScorecardMenuTitle(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        return "Run First-Week Fame Scorecard (Day \(normalizedDay)/\(normalizedWindowDays) · \(normalizedCompletedDays)/\(normalizedWindowDays))"
    }

    nonisolated static func fameOnboardingScorecardActionTitle(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        return "Run First-Week Fame Scorecard (Day \(normalizedDay)/\(normalizedWindowDays))"
    }

    nonisolated static func fameOnboardingScorecardActionSubtitle(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int,
        recommendedCommandID: String
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        let remainingDays = max(0, normalizedWindowDays - normalizedCompletedDays)
        let commandTitle = fameOnboardingCommandTitle(recommendedCommandID)
        return "Day \(normalizedDay)/\(normalizedWindowDays) · Progress \(normalizedCompletedDays)/\(normalizedWindowDays) (\(remainingDays) left) · Next \(commandTitle)"
    }

    nonisolated static func fameOnboardingDailyBriefActionTitle(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        return "Run First-Week Daily Brief (Day \(normalizedDay)/\(normalizedWindowDays))"
    }

    nonisolated static func fameOnboardingDailyBriefActionSubtitle(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int,
        recommendedCommandID: String
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        let remainingDays = max(0, normalizedWindowDays - normalizedCompletedDays)
        let commandTitle = fameOnboardingCommandTitle(recommendedCommandID)
        return "Day \(normalizedDay)/\(normalizedWindowDays) · Progress \(normalizedCompletedDays)/\(normalizedWindowDays) (\(remainingDays) left) · Save nudge + scorecard + daily brief · Next \(commandTitle)"
    }

    nonisolated static func fameOnboardingGapActionTitle(
        recommendedCommandID: String
    ) -> String {
        switch recommendedCommandID {
        case "run-fame-onboarding-daily-brief":
            return "Fill Onboarding Gap: Daily Brief"
        case "run-fame-onboarding-scorecard":
            return "Fill Onboarding Gap: Fame Scorecard"
        case "run-fame-onboarding-nudge":
            return "Fill Onboarding Gap: Onboarding Nudge"
        default:
            return "Fill Onboarding Gap"
        }
    }

    nonisolated static func fameOnboardingGapMenuTitle(
        recommendedCommandID: String?,
        missingArtifacts: Int,
        missingArtifactNames: [String] = [],
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedMissingArtifacts = min(normalizedTotalArtifacts, max(0, missingArtifacts))

        guard let recommendedCommandID else {
            return "Fill Onboarding Gap (\(normalizedTotalArtifacts)/\(normalizedTotalArtifacts) ready)"
        }

        let commandTitle: String
        switch recommendedCommandID {
        case "run-fame-onboarding-daily-brief":
            commandTitle = "Daily Brief"
        case "run-fame-onboarding-scorecard":
            commandTitle = "Fame Scorecard"
        case "run-fame-onboarding-nudge":
            commandTitle = "Onboarding Nudge"
        default:
            commandTitle = fameOnboardingCommandTitle(recommendedCommandID)
        }

        let normalizedMissingArtifactNames = fameOnboardingNormalizedMissingArtifactNames(
            missingArtifactNames,
            totalArtifacts: normalizedTotalArtifacts
        )
        let missingNameLimit = max(0, normalizedMissingArtifacts)
        let missingNamesForTitle = Array(normalizedMissingArtifactNames.prefix(missingNameLimit))
        let missingNamesSuffix = missingNamesForTitle.isEmpty
            ? ""
            : ": \(missingNamesForTitle.joined(separator: ", "))"
        return "Fill Onboarding Gap: \(commandTitle) (\(normalizedMissingArtifacts)/\(normalizedTotalArtifacts) missing\(missingNamesSuffix))"
    }

    nonisolated static func fameOnboardingRecoveryMenuHint(
        isFreshRecovery: Bool,
        followupCommandID: String?,
        remainingArtifacts: Int?
    ) -> String? {
        guard isFreshRecovery else { return nil }

        let normalizedRemainingArtifacts = max(0, remainingArtifacts ?? 0)
        let followupTitle: String?
        if let followupCommandID {
            let normalizedID = followupCommandID.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizedID.isEmpty {
                followupTitle = nil
            } else {
                followupTitle = fameOnboardingCommandTitle(normalizedID)
            }
        } else {
            followupTitle = nil
        }

        if normalizedRemainingArtifacts > 0 {
            let noun = normalizedRemainingArtifacts == 1 ? "artifact" : "artifacts"
            let progressCopy = "Recovery \(normalizedRemainingArtifacts) \(noun) left"
            if let followupTitle {
                return "\(progressCopy) · next \(followupTitle)"
            }
            return progressCopy
        }

        if let followupTitle {
            return "Recovery gap closed · next \(followupTitle)"
        }
        return "Recovery gap closed"
    }

    nonisolated static func fameOnboardingRecoveryQuickRunActionID(
        isFreshRecovery: Bool,
        followupCommandID: String?,
        remainingArtifacts: Int?,
        enabledActionIDs: Set<String>
    ) -> String? {
        let context = CommandPaletteTopPickContext(
            hasText: false,
            hasAnswer: false,
            hasImage: false,
            hasError: false,
            llmEnabled: false,
            hasFreshOnboardingRecovery: isFreshRecovery,
            onboardingRecoveryFollowupActionID: followupCommandID,
            onboardingRecoveryRemainingArtifacts: remainingArtifacts
        )
        return CommandPaletteTopPicks.onboardingRecoveryQuickRunActionID(
            for: context,
            enabledActionIDs: enabledActionIDs
        )
    }

    nonisolated static func fameOnboardingRecoveryFallbackActionID(
        enabledActionIDs: Set<String>
    ) -> String? {
        CommandPaletteTopPicks.onboardingRecoveryFallbackActionID(
            enabledActionIDs: enabledActionIDs
        )
    }

    nonisolated static func fameOnboardingRecoveryQuickRunMenuTitle(
        isFreshRecovery: Bool,
        actionID: String?,
        remainingArtifacts: Int?
    ) -> String {
        guard isFreshRecovery else {
            return "Run Recovery Next Step (No active recovery)"
        }

        let normalizedActionID = actionID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalizedActionID.isEmpty else {
            return "Run Recovery Next Step (Unavailable)"
        }

        let commandTitle = fameOnboardingCommandTitle(normalizedActionID)
        let normalizedRemainingArtifacts = max(0, remainingArtifacts ?? 0)
        if normalizedRemainingArtifacts > 0 {
            let noun = normalizedRemainingArtifacts == 1 ? "artifact" : "artifacts"
            return "Run Recovery Next: \(commandTitle) (\(normalizedRemainingArtifacts) \(noun) left)"
        }
        return "Run Recovery Next: \(commandTitle) (Gap closed)"
    }

    nonisolated static func launchControlOnboardingRecoveryQuickRunMenuTitle(
        isFreshRecovery: Bool,
        actionID: String?,
        remainingArtifacts: Int?
    ) -> String {
        guard isFreshRecovery else {
            return "Launch Recovery Next: Awaiting onboarding recovery pulse"
        }

        let normalizedActionID = actionID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalizedActionID.isEmpty else {
            return "Launch Recovery Next: Unavailable"
        }

        let commandTitle = fameOnboardingCommandTitle(normalizedActionID)
        let normalizedRemainingArtifacts = max(0, remainingArtifacts ?? 0)
        if normalizedRemainingArtifacts > 0 {
            let noun = normalizedRemainingArtifacts == 1 ? "artifact" : "artifacts"
            return "Launch Recovery Next: \(commandTitle) (\(normalizedRemainingArtifacts) \(noun) left)"
        }
        return "Launch Recovery Next: \(commandTitle) (Gap closed)"
    }

    nonisolated static func launchRecoveryHotKeyBusyActivityDetail() -> String {
        "launch-recovery-hotkey-busy"
    }

    nonisolated static func launchRecoveryGlobalHotKeyUnavailableActivityDetail() -> String {
        "run-fame-launch-recovery-next-global-hotkey-unavailable"
    }

    nonisolated static func fameExceptionalLoopHotKeyBusyActivityDetail() -> String {
        "fame-exceptional-loop-hotkey-busy"
    }

    nonisolated static func fameExceptionalLoopGlobalHotKeyActivityDetail() -> String {
        "run-fame-exceptional-loop-global-hotkey"
    }

    nonisolated static func launchRecoveryGlobalHotKeyFallbackActivityDetail(
        actionID: String
    ) -> String {
        "run-fame-launch-recovery-next-global-hotkey-fallback-\(ActivityLogCommand.safeID(actionID))"
    }

    nonisolated static func launchRecoveryGlobalHotKeyFallbackPulseActivityDetail(
        actionID: String
    ) -> String {
        "run-fame-launch-recovery-next-global-hotkey-fallback-pulse-\(ActivityLogCommand.safeID(actionID))"
    }

    nonisolated static func launchRecoveryGlobalHotKeyFallbackPulseTitle() -> String {
        "Recovery Rerouted"
    }

    nonisolated static func launchRecoveryGlobalHotKeyFallbackPulseMessage(
        actionID: String
    ) -> String {
        let commandTitle = fameOnboardingCommandTitle(actionID)
        return "Launch recovery route was not active. Auto-rerouted to \(commandTitle)."
    }

    nonisolated static func launchRecoveryQuickRunActivityDetail(
        source: String,
        actionID: String
    ) -> String {
        "run-fame-launch-recovery-next-\(source)-\(ActivityLogCommand.safeID(actionID))"
    }

    nonisolated static func launchRecoveryQuickRunPulseActivityDetail(
        source: String,
        actionID: String
    ) -> String {
        "run-fame-launch-recovery-next-pulse-\(source)-\(ActivityLogCommand.safeID(actionID))"
    }

    private func recordBestChannelLaunchPackPressureActivity(
        _ activity: CommandPaletteBestChannelLaunchPackPressureActivity,
        defaults: UserDefaults = .standard
    ) {
        let modeShiftSummary = Self.incrementBestChannelLaunchPackPressureModeTransitionSummary(
            activity,
            defaults: defaults
        )
        if modeShiftSummary != nil {
            updateBestChannelLaunchPackMenuStatus(defaults: defaults)
        }
        recordActivity(
            category: "command",
            detail: Self.bestChannelLaunchPackPressureActivityDetail(activity)
        )
    }

    nonisolated static func bestChannelLaunchPackPressureActivityDetail(
        _ activity: CommandPaletteBestChannelLaunchPackPressureActivity
    ) -> String {
        let toneToken = bestChannelLaunchPackPressureToneToken(activity.tone)
        let opportunities = max(0, activity.opportunities)
        let conversions = min(opportunities, max(0, activity.conversions))
        let streak = min(conversions, max(0, activity.streak))
        let bestStreak = max(streak, max(0, activity.bestStreak))
        switch activity.kind {
        case .opportunity:
            return "fame-launch-pack-pressure-opportunity-\(toneToken)-\(conversions)-of-\(opportunities)-streak-\(streak)-best-\(bestStreak)"
        case .conversion:
            return "fame-launch-pack-pressure-conversion-\(toneToken)-\(conversions)-of-\(opportunities)-streak-\(streak)-best-\(bestStreak)"
        case .modeTransition:
            let previousTrendToken = activity.previousTrend
                .map(bestChannelLaunchPackPressureTrendToken) ?? "none"
            let trendToken = bestChannelLaunchPackPressureTrendToken(activity.trend)
            return "fame-launch-pack-pressure-mode-\(previousTrendToken)-to-\(trendToken)-\(toneToken)-\(conversions)-of-\(opportunities)-streak-\(streak)-best-\(bestStreak)"
        }
    }

    @discardableResult
    nonisolated static func incrementBestChannelLaunchPackPressureModeTransitionSummary(
        _ activity: CommandPaletteBestChannelLaunchPackPressureActivity,
        defaults: UserDefaults = .standard,
        countKey: String = AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey,
        latestKey: String = AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey,
        momentumStreakKey: String = AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
    ) -> (count: Int, latest: String, momentumStreak: Int)? {
        guard activity.kind == .modeTransition else { return nil }
        let previousTrendToken = activity.previousTrend.map(bestChannelLaunchPackPressureTrendToken) ?? "none"
        let trendToken = bestChannelLaunchPackPressureTrendToken(activity.trend)
        let latestToken = "\(previousTrendToken)-to-\(trendToken)"
        let count = max(0, defaults.integer(forKey: countKey)) + 1
        let direction = bestChannelLaunchPackPressureModeTransitionDirection(
            fromToken: previousTrendToken,
            toToken: trendToken
        )
        let previousMomentumStreak = defaults.integer(forKey: momentumStreakKey)
        let momentumStreak = nextBestChannelLaunchPackPressureModeMomentumStreak(
            previousStreak: previousMomentumStreak,
            direction: direction
        )
        defaults.set(count, forKey: countKey)
        defaults.set(latestToken, forKey: latestKey)
        defaults.set(momentumStreak, forKey: momentumStreakKey)
        return (count, latestToken, momentumStreak)
    }

    nonisolated private static func bestChannelLaunchPackPressureToneToken(
        _ tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) -> String {
        switch tone {
        case .alert:
            return "alert"
        case .watch:
            return "watch"
        }
    }

    nonisolated private static func bestChannelLaunchPackPressureTrendToken(
        _ trend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend
    ) -> String {
        switch trend {
        case .noOpportunities:
            return "none"
        case .noWins:
            return "no-wins"
        case .cooling:
            return "cooling"
        case .rebuilding:
            return "rebuilding"
        case .compounding:
            return "compounding"
        }
    }

    nonisolated private static func bestChannelLaunchPackPressureModeTransitionDirection(
        fromToken: String,
        toToken: String
    ) -> Int {
        guard let fromRank = bestChannelLaunchPackPressureTrendRank(fromToken),
              let toRank = bestChannelLaunchPackPressureTrendRank(toToken) else {
            return 0
        }
        if toRank > fromRank {
            return 1
        }
        if toRank < fromRank {
            return -1
        }
        return 0
    }

    nonisolated private static func bestChannelLaunchPackPressureTrendRank(_ token: String) -> Int? {
        switch token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "none":
            return 0
        case "no-wins":
            return 1
        case "cooling":
            return 2
        case "rebuilding":
            return 3
        case "compounding":
            return 4
        default:
            return nil
        }
    }

    nonisolated private static func nextBestChannelLaunchPackPressureModeMomentumStreak(
        previousStreak: Int,
        direction: Int
    ) -> Int {
        let normalizedDirection: Int
        if direction > 0 {
            normalizedDirection = 1
        } else if direction < 0 {
            normalizedDirection = -1
        } else {
            normalizedDirection = 0
        }
        guard normalizedDirection != 0 else { return 0 }
        let previousDirection: Int
        if previousStreak > 0 {
            previousDirection = 1
        } else if previousStreak < 0 {
            previousDirection = -1
        } else {
            previousDirection = 0
        }
        if previousDirection == normalizedDirection {
            return normalizedDirection * (abs(previousStreak) + 1)
        }
        return normalizedDirection
    }

    nonisolated static func launchRecoveryQuickRunShortcutHint() -> String {
        "Use global ⌥⇧L (auto-reroutes if needed), or press ⌥⌘R in Command Palette (fallback: ⌘1 from Top Picks)."
    }

    nonisolated static func launchRecoveryQuickRunCardSubtitle(
        actionID: String,
        remainingArtifacts: Int?
    ) -> String {
        let commandTitle = fameOnboardingCommandTitle(actionID)
        let normalizedRemainingArtifacts = max(0, remainingArtifacts ?? 0)
        let shortcutHint = "Shortcut: ⌥⇧L global (auto-reroute) · ⌥⌘R palette (fallback ⌘1)"
        if normalizedRemainingArtifacts > 0 {
            let noun = normalizedRemainingArtifacts == 1 ? "artifact" : "artifacts"
            return "One-click launch recovery route · \(normalizedRemainingArtifacts) \(noun) left · Next \(commandTitle) · \(shortcutHint)"
        }
        return "Onboarding gap closed · Keep momentum with \(commandTitle) · \(shortcutHint)"
    }

    nonisolated static func launchControlOnboardingRecoveryQuickRunMenuToolTip(
        isFreshRecovery: Bool,
        actionID: String?
    ) -> String {
        let shortcutHint = launchRecoveryQuickRunShortcutHint()
        guard isFreshRecovery else {
            return "Waiting for a fresh onboarding recovery pulse. \(shortcutHint)"
        }

        let normalizedActionID = actionID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalizedActionID.isEmpty else {
            return "Recovery pulse is active, but no eligible quick-run route is available yet. \(shortcutHint)"
        }

        let commandTitle = fameOnboardingCommandTitle(normalizedActionID)
        return "Runs \(commandTitle) from Launch Control. \(shortcutHint)"
    }

    nonisolated static func launchRecoveryQuickRunPulseMessage(
        actionID: String,
        remainingArtifacts: Int?
    ) -> String {
        let commandTitle = fameOnboardingCommandTitle(actionID)
        let normalizedRemainingArtifacts = max(0, remainingArtifacts ?? 0)
        if normalizedRemainingArtifacts > 0 {
            let noun = normalizedRemainingArtifacts == 1 ? "artifact" : "artifacts"
            return "Launch recovery route primed: \(commandTitle) (\(normalizedRemainingArtifacts) \(noun) left)."
        }
        return "Launch recovery route primed: \(commandTitle) (gap closed)."
    }

    nonisolated static func fameOnboardingRecoveryMomentumHint(
        isFreshRecovery: Bool,
        remainingArtifacts: Int?
    ) -> String? {
        guard isFreshRecovery else { return nil }
        let normalizedRemainingArtifacts = max(0, remainingArtifacts ?? 0)
        if normalizedRemainingArtifacts > 0 {
            let noun = normalizedRemainingArtifacts == 1 ? "artifact" : "artifacts"
            return "Onboarding recovery: \(normalizedRemainingArtifacts) \(noun) left"
        }
        return "Onboarding recovery: gap closed"
    }

    nonisolated static func fameMenuTitle(
        baseTitle: String,
        appendedHint: String?
    ) -> String {
        let trimmedHint = appendedHint?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedHint.isEmpty else { return baseTitle }
        return "\(baseTitle) · \(trimmedHint)"
    }

    nonisolated static func fameOnboardingGapPulseMessage(
        missingArtifacts: Int,
        missingArtifactNames: [String],
        recommendedCommandID: String,
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedMissingArtifacts = min(normalizedTotalArtifacts, max(1, missingArtifacts))
        let normalizedMissingArtifactNames = fameOnboardingNormalizedMissingArtifactNames(
            missingArtifactNames,
            totalArtifacts: normalizedTotalArtifacts
        )
        let missingNamesList = normalizedMissingArtifactNames.isEmpty
            ? "artifacts"
            : normalizedMissingArtifactNames.joined(separator: ", ")
        let commandTitle = fameOnboardingCommandTitle(recommendedCommandID)
        return "Onboarding gap spotted (\(normalizedMissingArtifacts)/\(normalizedTotalArtifacts) missing: \(missingNamesList)). Next: \(commandTitle)."
    }

    nonisolated static func fameOnboardingGapRecoveryMessage(
        previousMissingArtifacts: Int,
        nextMissingArtifacts: Int,
        nextMissingArtifactNames: [String],
        recommendedCommandID: String?,
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedPreviousMissingArtifacts = min(
            normalizedTotalArtifacts,
            max(0, previousMissingArtifacts)
        )
        let normalizedNextMissingArtifacts = min(
            normalizedTotalArtifacts,
            max(0, nextMissingArtifacts)
        )
        if normalizedNextMissingArtifacts == 0 {
            return "Onboarding gap closed (\(normalizedTotalArtifacts)/\(normalizedTotalArtifacts) ready). Great recovery."
        }

        let normalizedMissingArtifactNames = fameOnboardingNormalizedMissingArtifactNames(
            nextMissingArtifactNames,
            totalArtifacts: normalizedTotalArtifacts
        )
        let visibleMissingArtifactNames = Array(
            normalizedMissingArtifactNames.prefix(max(0, normalizedNextMissingArtifacts))
        )
        let missingNamesList = visibleMissingArtifactNames.isEmpty
            ? "artifacts"
            : visibleMissingArtifactNames.joined(separator: ", ")
        let nextLine: String
        if let recommendedCommandID {
            nextLine = " Next: \(fameOnboardingCommandTitle(recommendedCommandID))."
        } else {
            nextLine = ""
        }
        return "Onboarding gap improved (\(normalizedPreviousMissingArtifacts)->\(normalizedNextMissingArtifacts)/\(normalizedTotalArtifacts) missing: \(missingNamesList)).\(nextLine)"
    }

    nonisolated static func fameOnboardingGapRecoveryActivityDetail(
        previousMissingArtifacts: Int,
        nextMissingArtifacts: Int,
        nextMissingArtifactNames: [String],
        recommendedCommandID: String?,
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedPreviousMissingArtifacts = min(
            normalizedTotalArtifacts,
            max(0, previousMissingArtifacts)
        )
        let normalizedNextMissingArtifacts = min(
            normalizedTotalArtifacts,
            max(0, nextMissingArtifacts)
        )
        let normalizedMissingArtifactNames = fameOnboardingNormalizedMissingArtifactNames(
            nextMissingArtifactNames,
            totalArtifacts: normalizedTotalArtifacts
        )
        let visibleMissingArtifactNames = Array(
            normalizedMissingArtifactNames.prefix(max(0, normalizedNextMissingArtifacts))
        )
        let missingArtifactsToken = normalizedNextMissingArtifacts == 0
            ? "all-ready"
            : fameOnboardingGapMissingArtifactsToken(
                missingArtifactNames: visibleMissingArtifactNames,
                totalArtifacts: normalizedTotalArtifacts
            )
        let routeToken = recommendedCommandID.map(ActivityLogCommand.safeID) ?? "all-ready"
        return "fame-onboarding-gap-recovery-\(normalizedPreviousMissingArtifacts)-to-\(normalizedNextMissingArtifacts)-of-\(normalizedTotalArtifacts)-\(missingArtifactsToken)-\(routeToken)"
    }

    nonisolated static func fameOnboardingGapRecommendedCommandID(
        hasDailyBrief: Bool,
        hasScorecard: Bool,
        hasNudge: Bool
    ) -> String? {
        if !hasDailyBrief {
            return "run-fame-onboarding-daily-brief"
        }
        if !hasScorecard {
            return "run-fame-onboarding-scorecard"
        }
        if !hasNudge {
            return "run-fame-onboarding-nudge"
        }
        return nil
    }

    nonisolated static func shouldShowFameOnboardingGapAction(
        hasDailyBrief: Bool,
        hasScorecard: Bool,
        hasNudge: Bool
    ) -> Bool {
        fameOnboardingGapRecommendedCommandID(
            hasDailyBrief: hasDailyBrief,
            hasScorecard: hasScorecard,
            hasNudge: hasNudge
        ) != nil
    }

    nonisolated static func fameOnboardingGapActionSubtitle(
        missingArtifactNames: [String],
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        newestArtifactAgeMinutes: Int?,
        recommendedCommandID: String,
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedMissingArtifactNames = fameOnboardingNormalizedMissingArtifactNames(
            missingArtifactNames,
            totalArtifacts: normalizedTotalArtifacts
        )
        let missingCount = normalizedMissingArtifactNames.isEmpty
            ? 1
            : min(normalizedTotalArtifacts, normalizedMissingArtifactNames.count)
        let missingList = normalizedMissingArtifactNames.isEmpty
            ? "artifacts"
            : normalizedMissingArtifactNames.joined(separator: ", ")
        let recencyTitle = fameOnboardingSuiteArtifactRecencyTitle(
            newestArtifactAgeMinutes: newestArtifactAgeMinutes
        )
        let commandTitle = fameOnboardingCommandTitle(recommendedCommandID)
        return "Missing \(missingCount)/\(normalizedTotalArtifacts): \(missingList) · Day \(normalizedDay)/\(normalizedWindowDays) · \(recencyTitle) · Next \(commandTitle)"
    }

    nonisolated static func fameOnboardingNormalizedMissingArtifactNames(
        _ missingArtifactNames: [String],
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> [String] {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        var seenNames = Set<String>()
        var normalizedNames: [String] = []

        for artifactName in missingArtifactNames {
            let trimmedName = artifactName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else { continue }

            let dedupeKey = trimmedName.lowercased()
            guard seenNames.insert(dedupeKey).inserted else { continue }

            normalizedNames.append(trimmedName)
            if normalizedNames.count == normalizedTotalArtifacts {
                break
            }
        }

        return normalizedNames
    }

    nonisolated static func fameOnboardingGapMissingArtifactsToken(
        missingArtifactNames: [String],
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedNames = fameOnboardingNormalizedMissingArtifactNames(
            missingArtifactNames,
            totalArtifacts: totalArtifacts
        )
        guard !normalizedNames.isEmpty else { return "artifacts" }

        let tokens = normalizedNames.map { name in
            let tokenParts = name
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            return tokenParts.isEmpty ? "artifact" : tokenParts.joined(separator: "-")
        }

        return tokens.joined(separator: "+")
    }

    nonisolated static func fameOnboardingGapPulseActivityDetail(
        missingArtifacts: Int,
        missingArtifactNames: [String],
        recommendedCommandID: String,
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedMissingArtifacts = min(normalizedTotalArtifacts, max(1, missingArtifacts))
        let missingArtifactsToken = fameOnboardingGapMissingArtifactsToken(
            missingArtifactNames: missingArtifactNames,
            totalArtifacts: normalizedTotalArtifacts
        )
        return "fame-onboarding-gap-pulse-\(normalizedMissingArtifacts)-of-\(normalizedTotalArtifacts)-\(missingArtifactsToken)-\(ActivityLogCommand.safeID(recommendedCommandID))"
    }

    nonisolated static func fameOnboardingSuiteArtifactRecencyTitle(
        newestArtifactAgeMinutes: Int?
    ) -> String {
        guard let newestArtifactAgeMinutes else {
            return "freshness unknown"
        }
        let normalizedMinutes = max(0, newestArtifactAgeMinutes)
        if normalizedMinutes == 0 {
            return "updated just now"
        }
        if normalizedMinutes < 60 {
            return "updated \(normalizedMinutes)m ago"
        }
        let hours = normalizedMinutes / 60
        if hours < 24 {
            return "updated \(hours)h ago"
        }
        let days = hours / 24
        return "updated \(days)d ago"
    }

    nonisolated static func fameOnboardingSuiteActionSubtitle(
        availableArtifacts: Int,
        totalArtifacts: Int = fameOnboardingSuiteArtifactCount,
        newestArtifactAgeMinutes: Int?
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedAvailableArtifacts = min(normalizedTotalArtifacts, max(0, availableArtifacts))

        guard normalizedAvailableArtifacts > 0 else {
            return "No saved artifacts yet · Run first-week daily brief"
        }

        var subtitle = "\(normalizedAvailableArtifacts)/\(normalizedTotalArtifacts) artifacts ready"
        subtitle += " · \(fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: newestArtifactAgeMinutes))"
        if normalizedAvailableArtifacts < normalizedTotalArtifacts {
            subtitle += " · Fill gaps with daily brief"
        }
        return subtitle
    }

    nonisolated static func launchControlHubActionSubtitle(
        availableArtifacts: Int,
        totalArtifacts: Int = launchControlHubArtifactCount,
        newestArtifactAgeMinutes: Int?
    ) -> String {
        let normalizedTotalArtifacts = max(1, totalArtifacts)
        let normalizedAvailableArtifacts = min(normalizedTotalArtifacts, max(0, availableArtifacts))

        guard normalizedAvailableArtifacts > 0 else {
            return "No saved launch artifacts yet · Run Launch Control Brief"
        }

        var subtitle = "\(normalizedAvailableArtifacts)/\(normalizedTotalArtifacts) launch artifacts ready"
        subtitle += " · \(fameOnboardingSuiteArtifactRecencyTitle(newestArtifactAgeMinutes: newestArtifactAgeMinutes))"
        if normalizedAvailableArtifacts < normalizedTotalArtifacts {
            subtitle += " · Fill gaps with launch rescue burst"
        }
        return subtitle
    }

    nonisolated static func launchControlHubActionSubtitle(
        availableArtifacts: Int,
        totalArtifacts: Int = launchControlHubArtifactCount,
        newestArtifactAgeMinutes: Int?,
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            launchControlHubActionSubtitle(
                availableArtifacts: availableArtifacts,
                totalArtifacts: totalArtifacts,
                newestArtifactAgeMinutes: newestArtifactAgeMinutes
            ),
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueFollowupPromptContextFragment(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String? {
        let cleanRouteBadge = routeBadge?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSelfHealAttentionBadge = selfHealAttentionBadge?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fragments = [cleanRouteBadge, cleanSelfHealAttentionBadge]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
        guard !fragments.isEmpty else { return nil }
        return fragments.joined(separator: " · ")
    }

    nonisolated static func launchControlMenuTitleWithLaunchRescueContext(
        _ title: String,
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        guard let contextFragment = launchRescueFollowupPromptContextFragment(
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        ) else {
            return title
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return contextFragment }
        return "\(trimmedTitle) · \(contextFragment)"
    }

    nonisolated static func launchControlBriefRunMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Run Launch Control Brief",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlBriefOpenMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Open Latest Launch Control Brief",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlBriefCopyMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Copy Launch Control Brief",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlBriefRunMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlBriefActionSubtitle(
            "Refresh launch countdown + save + copy launch control brief",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlBriefOpenMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlBriefActionSubtitle(
            "Open latest launch control brief",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlBriefCopyMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlBriefActionSubtitle(
            "Copy live launch alert + rescue + threshold status brief",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlHubRunMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Run Launch Control Hub",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlHubOpenMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Open Launch Control Hub",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlHubRunMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            "Generate burst + countdown + brief + snapshot",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlHubOpenMenuStatusToolTip(
        availableArtifacts: Int,
        totalArtifacts: Int = launchControlHubArtifactCount,
        newestArtifactAgeMinutes: Int?,
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlHubActionSubtitle(
            availableArtifacts: availableArtifacts,
            totalArtifacts: totalArtifacts,
            newestArtifactAgeMinutes: newestArtifactAgeMinutes,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchControlPromptWithLaunchRescueContext(
        _ prompt: String,
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextualPrompt: String = {
            guard let contextFragment = launchRescueFollowupPromptContextFragment(
                routeBadge: routeBadge,
                selfHealAttentionBadge: selfHealAttentionBadge
            ) else {
                return trimmedPrompt
            }
            guard !trimmedPrompt.isEmpty else { return contextFragment }
            if trimmedPrompt.hasSuffix(".") {
                return "\(trimmedPrompt.dropLast()) · \(contextFragment)."
            }
            return "\(trimmedPrompt) · \(contextFragment)."
        }()
        guard let followupRouteDecisionTraceLine = cleanStatusLine(followupRouteDecisionTraceLine) else {
            return contextualPrompt
        }
        guard !contextualPrompt.isEmpty else {
            return followupRouteDecisionTraceLine
        }
        if contextualPrompt.hasSuffix(".") {
            return "\(contextualPrompt) \(followupRouteDecisionTraceLine)"
        }
        return "\(contextualPrompt). \(followupRouteDecisionTraceLine)"
    }

    nonisolated static func launchControlHubRunSummaryMarkdown(
        generatedAt: String,
        rescueBurstCompleted: Bool,
        readyArtifactCount: Int,
        totalArtifactCount: Int = launchControlHubArtifactCount,
        launchRescueFollowupRouteDecisionStatusTitle: String,
        launchRescueAutoSelfHealStatusTitle: String,
        launchControlBriefArtifactName: String,
        launchRescueSnapshotArtifactName: String,
        launchRescueBurstArtifactName: String,
        launchCountdownArtifactName: String,
        missingArtifactNames: [String]
    ) -> String {
        let normalizedTotalArtifactCount = max(1, totalArtifactCount)
        let normalizedReadyArtifactCount = min(
            normalizedTotalArtifactCount,
            max(0, readyArtifactCount)
        )
        let missingTitle = missingArtifactNames.isEmpty
            ? "None"
            : missingArtifactNames.joined(separator: ", ")
        let rescueBurstStatusTitle = rescueBurstCompleted
            ? "Completed."
            : "Failed (latest artifacts still loaded when available)."
        return """
        # Fluid Reader Launch Control Hub Run

        - Generated at: \(generatedAt)
        - Rescue burst run: \(rescueBurstStatusTitle)
        - Artifacts ready: \(normalizedReadyArtifactCount)/\(normalizedTotalArtifactCount)
        - \(launchRescueFollowupRouteDecisionStatusTitle)
        - \(launchRescueAutoSelfHealStatusTitle)

        ## Artifacts
        - Launch control brief: \(launchControlBriefArtifactName)
        - Launch rescue snapshot: \(launchRescueSnapshotArtifactName)
        - Launch rescue burst: \(launchRescueBurstArtifactName)
        - Launch countdown: \(launchCountdownArtifactName)

        ## Missing
        - \(missingTitle)

        ## Quick Commands
        - \(readerStatusShortcutMenuHintLine())
        - `Open Launch Control Hub`
        - `Open Latest Launch Control Brief`
        - `Open Latest Launch Rescue Snapshot`
        - `Open Latest Launch Rescue Burst`
        - `Open Latest Launch Countdown`
        """
    }

    nonisolated static func launchControlHubRunActivityDetail(
        source: String = "manual",
        readyArtifactCount: Int,
        totalArtifactCount: Int = launchControlHubArtifactCount
    ) -> String {
        let normalizedTotalArtifactCount = max(1, totalArtifactCount)
        let normalizedReadyArtifactCount = min(
            normalizedTotalArtifactCount,
            max(0, readyArtifactCount)
        )
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSource.isEmpty,
              normalizedSource.lowercased() != "manual" else {
            return "run-fame-launch-control-hub-\(normalizedReadyArtifactCount)-of-\(normalizedTotalArtifactCount)"
        }
        let sourceToken = ActivityLogCommand.safeID(normalizedSource)
        return "run-fame-launch-control-hub-\(sourceToken)-\(normalizedReadyArtifactCount)-of-\(normalizedTotalArtifactCount)"
    }

    nonisolated static func launchControlHubAutoEscalationActivityDetail(
        urgencyToken: String
    ) -> String {
        let normalizedUrgencyToken = ActivityLogCommand.safeID(urgencyToken)
        return "run-fame-launch-control-hub-auto-\(normalizedUrgencyToken)"
    }

    nonisolated static func launchControlHubAutoSkipActivityDetail(
        skipReason: String,
        urgencyToken: String,
        triggerReason: LaunchRescueAutoTriggerReason
    ) -> String {
        let normalizedSkipReason = skipReason
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() == "disabled"
            ? "disabled"
            : "cooldown"
        let normalizedUrgencyToken = ActivityLogCommand.safeID(urgencyToken)
        return "run-fame-launch-control-hub-auto-skipped-\(normalizedSkipReason)-\(normalizedUrgencyToken)-\(triggerReason.rawValue)"
    }

    nonisolated static func autoEscalationOpsBundleSummaryDisabledMarkdown() -> String {
        """
        ## Ops Bundle Auto Follow-up
        - Auto ops bundle is disabled in Settings.
        - Manual rerun: `run-fame-ops-bundle`.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    nonisolated static func autoEscalationOpsBundleSummaryCooldownMarkdown(
        remainingMinutes: Int
    ) -> String {
        let normalizedRemainingMinutes = max(0, remainingMinutes)
        return """
        ## Ops Bundle Auto Follow-up
        - Cooldown active: auto ops bundle ran recently.
        - Next auto run in about \(normalizedRemainingMinutes) min.
        - Manual rerun: `run-fame-ops-bundle`.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    nonisolated static func autoEscalationOpsBundleSummaryReadyMarkdown(
        commandCenterArtifactName: String,
        checkpointArtifactName: String,
        riskTimelineArtifactName: String,
        pulseNudgeArtifactName: String
    ) -> String {
        """
        ## Ops Bundle Auto Follow-up
        - Command center saved: \(commandCenterArtifactName)
        - Daily checkpoint saved: \(checkpointArtifactName)
        - Risk timeline saved: \(riskTimelineArtifactName)
        - Pulse nudge saved: \(pulseNudgeArtifactName)
        - Shortcuts: `open-latest-command-center`, `open-latest-daily-checkpoint`, `open-latest-risk-timeline`, `open-latest-pulse-nudge`.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    nonisolated static func fameOpsBundleSummaryMarkdown(
        bundleStamp: String,
        commandCenterArtifactName: String,
        checkpointArtifactName: String,
        riskTimelineArtifactName: String,
        pulseNudgeArtifactName: String
    ) -> String {
        let normalizedBundleStamp = bundleStamp.trimmingCharacters(in: .whitespacesAndNewlines)
        let bundleStampDisplay = normalizedBundleStamp.isEmpty ? "Unknown" : normalizedBundleStamp
        return """
        # Fluid Reader Fame Ops Bundle

        Bundle stamp: \(bundleStampDisplay)

        ## Saved Artifacts
        - Command center: \(commandCenterArtifactName)
        - Daily checkpoint: \(checkpointArtifactName)
        - Risk timeline: \(riskTimelineArtifactName)
        - Pulse nudge: \(pulseNudgeArtifactName)

        ## Instant Reopen Commands
        - \(readerStatusShortcutMenuHintLine())
        - `open-latest-command-center`
        - `open-latest-daily-checkpoint`
        - `open-latest-risk-timeline`
        - `open-latest-pulse-nudge`

        ## Next Action
        - Run `run-fame-sprint-snapshot` after shipping one proof loop.

        No API keys or private content.
        """
    }

    nonisolated static func launchRescueBurstRunSummaryMarkdown(
        launchStatusTitle: String,
        launchStatusSubtitle: String,
        launchThresholdAlertsStatusTitle: String,
        snoozeReminderActionSummary: String,
        launchScriptArtifactName: String,
        launchCountdownArtifactName: String,
        nextMoveCommandTitle: String,
        nextMoveHandoffArtifactName: String,
        nextMoveDraftPackArtifactName: String?,
        recoveryChecklistArtifactName: String,
        draftPackReady: Bool,
        clipboardActionSummary: String
    ) -> String {
        let normalizedDraftPackArtifactName = nextMoveDraftPackArtifactName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let nextMoveDraftPackDisplay: String
        if let normalizedDraftPackArtifactName, !normalizedDraftPackArtifactName.isEmpty {
            nextMoveDraftPackDisplay = normalizedDraftPackArtifactName
        } else {
            nextMoveDraftPackDisplay = "Not saved (handoff fallback)"
        }
        let draftPackReadyTitle = draftPackReady ? "Yes" : "No"
        return """
        # Fluid Reader Launch Rescue Burst

        ## Launch Status
        - \(launchStatusTitle)
        - \(launchStatusSubtitle)
        - Launch threshold alerts: \(launchThresholdAlertsStatusTitle)
        - Snooze reminder action: \(snoozeReminderActionSummary)

        ## Burst Outputs
        - Launch day script: \(launchScriptArtifactName)
        - Launch countdown: \(launchCountdownArtifactName)
        - Next move command: \(nextMoveCommandTitle)
        - Next move handoff: \(nextMoveHandoffArtifactName)
        - Next move draft pack: \(nextMoveDraftPackDisplay)
        - Recovery checklist: \(recoveryChecklistArtifactName)
        - Draft pack ready: \(draftPackReadyTitle)
        - Clipboard action: \(clipboardActionSummary)

        ## Next Operator Steps
        1. Open latest launch countdown and ship the `Next action now` step.
        2. Open latest next-move draft pack (or handoff fallback) and post the first channel block.
        3. Open latest recovery checklist and close one blocker in 15 minutes.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    nonisolated static func autoRecoveryProofPackSummaryMarkdown(
        proofPackArtifactName: String
    ) -> String {
        let normalizedProofPackArtifactName = proofPackArtifactName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let proofPackArtifactDisplay = normalizedProofPackArtifactName.isEmpty
            ? "Unknown"
            : normalizedProofPackArtifactName
        return """
        - Recovery proof pack saved: \(proofPackArtifactDisplay)
        - Shortcut: run `Open Latest Recovery Proof Pack` for post/reply snippets.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    nonisolated static func autoRecoveryChecklistSummaryMarkdown(
        checklistArtifactName: String,
        proofPackSummaryMarkdown: String? = nil
    ) -> String {
        let normalizedChecklistArtifactName = checklistArtifactName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let checklistArtifactDisplay = normalizedChecklistArtifactName.isEmpty
            ? "Unknown"
            : normalizedChecklistArtifactName

        var summary = """
        ## 2h Auto Follow-up
        - Recovery checklist saved: \(checklistArtifactDisplay)
        - Shortcut: run `Open Latest Recovery Checklist` for the execution board.
        - \(readerStatusShortcutMenuHintLine())
        """

        if let proofPackSummaryMarkdown {
            let trimmedProofPackSummary = proofPackSummaryMarkdown
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedProofPackSummary.isEmpty {
                summary += "\n\(trimmedProofPackSummary)"
            }
        }
        return summary
    }

    nonisolated static func latestRecoverySprintSummaryMarkdown(
        recoverySprintArtifactName: String
    ) -> String {
        let normalizedRecoverySprintArtifactName = recoverySprintArtifactName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let recoverySprintArtifactDisplay = normalizedRecoverySprintArtifactName.isEmpty
            ? "Unknown"
            : normalizedRecoverySprintArtifactName
        return """
        ## Latest Recovery Sprint
        - Latest file: \(recoverySprintArtifactDisplay)
        - Shortcut: run `Open Latest Recovery Sprint` to reopen it instantly.
        - \(readerStatusShortcutMenuHintLine())
        """
    }

    nonisolated static func recoverySprintRunSummaryMarkdown(
        recoveryMarkdown: String,
        checklistAutoFollowupSummaryMarkdown: String?
    ) -> String {
        let normalizedRecoveryMarkdown = recoveryMarkdown
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedChecklistSummary = checklistAutoFollowupSummaryMarkdown?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let normalizedChecklistSummary, !normalizedChecklistSummary.isEmpty else {
            return normalizedRecoveryMarkdown
        }
        guard !normalizedRecoveryMarkdown.isEmpty else {
            return normalizedChecklistSummary
        }
        return "\(normalizedRecoveryMarkdown)\n\n\(normalizedChecklistSummary)"
    }

    nonisolated static func recoveryChecklistRunSummaryMarkdown(
        checklistMarkdown: String,
        proofPackAutoFollowupSummaryMarkdown: String?
    ) -> String {
        let normalizedChecklistMarkdown = checklistMarkdown
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedProofPackSummary = proofPackAutoFollowupSummaryMarkdown?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let normalizedProofPackSummary, !normalizedProofPackSummary.isEmpty else {
            return normalizedChecklistMarkdown
        }
        guard !normalizedChecklistMarkdown.isEmpty else {
            return "## Proof Pack Auto Follow-up\n\(normalizedProofPackSummary)"
        }
        return """
        \(normalizedChecklistMarkdown)

        ## Proof Pack Auto Follow-up
        \(normalizedProofPackSummary)
        """
    }

    nonisolated static func fameOnboardingScorecardPaceLine(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        let targetCompletedByNow = min(normalizedWindowDays, normalizedDay)
        let delta = normalizedCompletedDays - targetCompletedByNow

        if delta > 0 {
            return "Ahead by \(delta) day\(delta == 1 ? "" : "s") vs day-\(normalizedDay) target."
        }
        if delta < 0 {
            let behindBy = abs(delta)
            return "Behind by \(behindBy) day\(behindBy == 1 ? "" : "s") vs day-\(normalizedDay) target."
        }
        return "On pace with day-\(normalizedDay) target."
    }

    nonisolated static func fameOnboardingScorecardMarkdown(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int,
        currentStreak: Int,
        bestStreak: Int,
        recommendedCommandID: String,
        backupCommandID: String,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        let remainingDays = max(0, normalizedWindowDays - normalizedCompletedDays)
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedCurrentStreak)
        let runsToMilestone = max(0, nextMilestone - normalizedCurrentStreak)
        let priorityTitle = fameOnboardingCommandTitle(recommendedCommandID)
        let backupTitle = fameOnboardingCommandTitle(backupCommandID)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: now)

        let paceLine = fameOnboardingScorecardPaceLine(
            day: normalizedDay,
            windowDays: normalizedWindowDays,
            completedDays: normalizedCompletedDays
        )

        return """
        # Fluid Reader First-Week Fame Scorecard

        Day \(normalizedDay) of \(normalizedWindowDays)
        Date: \(today)

        Progress:
        - Completed onboarding days: \(normalizedCompletedDays)/\(normalizedWindowDays)
        - Remaining onboarding days: \(remainingDays)
        - Pace: \(paceLine)

        Cadence:
        - Current streak: x\(normalizedCurrentStreak)
        - Best streak: x\(normalizedBestStreak)
        - Next milestone: x\(nextMilestone) (\(runsToMilestone) run\(runsToMilestone == 1 ? "" : "s") away)

        Priority command:
        - `\(priorityTitle)` (`\(recommendedCommandID)`)

        Backup command:
        - `\(backupTitle)` (`\(backupCommandID)`)

        Shortcut checks:
        - \(readerStatusShortcutMenuHintLine())

        Today win condition:
        1. Run priority command.
        2. Run backup command if blocked.
        3. Save one proof snapshot with `run-fame-sprint-snapshot`.
        """
    }

    nonisolated static func fameOnboardingDailyBriefMarkdown(
        day: Int,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int,
        currentStreak: Int,
        bestStreak: Int,
        recommendedCommandID: String,
        backupCommandID: String,
        onboardingNudgeArtifactName: String?,
        onboardingScorecardArtifactName: String?,
        dailyBriefArtifactName: String?,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let normalizedDay = max(1, min(normalizedWindowDays, day))
        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        let remainingDays = max(0, normalizedWindowDays - normalizedCompletedDays)
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let paceLine = fameOnboardingScorecardPaceLine(
            day: normalizedDay,
            windowDays: normalizedWindowDays,
            completedDays: normalizedCompletedDays
        )
        let primaryTitle = fameOnboardingCommandTitle(recommendedCommandID)
        let backupTitle = fameOnboardingCommandTitle(backupCommandID)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: now)

        return """
        # Fluid Reader First-Week Daily Brief

        Day \(normalizedDay) of \(normalizedWindowDays)
        Date: \(today)

        Progress:
        - Completed onboarding days: \(normalizedCompletedDays)/\(normalizedWindowDays)
        - Remaining onboarding days: \(remainingDays)
        - Pace: \(paceLine)

        Cadence:
        - Current streak: x\(normalizedCurrentStreak)
        - Best streak: x\(normalizedBestStreak)
        - Priority command: `\(primaryTitle)` (`\(recommendedCommandID)`)
        - Backup command: `\(backupTitle)` (`\(backupCommandID)`)

        Saved artifacts:
        - Onboarding nudge: \(onboardingNudgeArtifactName ?? "Not saved")
        - First-week scorecard: \(onboardingScorecardArtifactName ?? "Not saved")
        - Daily brief: \(dailyBriefArtifactName ?? "Not saved")

        Quick open:
        - \(readerStatusShortcutMenuHintLine())
        - `open-latest-onboarding-suite`
        - `open-latest-onboarding-daily-brief`
        - `open-latest-onboarding-nudge`
        - `open-latest-onboarding-scorecard`

        Today win condition:
        1. Run priority command.
        2. Run backup command if blocked.
        3. Ship one proof snapshot with `run-fame-sprint-snapshot`.
        """
    }

    nonisolated static func fameOnboardingNudgeActionSubtitle(
        _ plan: FameOnboardingNudgePlan,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int? = nil
    ) -> String {
        let primaryCommandTitle = fameOnboardingCommandTitle(plan.primaryCommandID)
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        guard let completedDays else {
            return "Day \(plan.day)/\(normalizedWindowDays) · \(plan.focusLine) · Start with \(primaryCommandTitle)"
        }

        let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
        let remainingDays = max(0, normalizedWindowDays - normalizedCompletedDays)
        return "Day \(plan.day)/\(normalizedWindowDays) · Progress \(normalizedCompletedDays)/\(normalizedWindowDays) (\(remainingDays) left) · \(plan.focusLine) · Start with \(primaryCommandTitle)"
    }

    nonisolated static func fameOnboardingNudgeMarkdown(
        _ plan: FameOnboardingNudgePlan,
        windowDays: Int = AppDefaults.fameOnboardingNudgeWindowDays,
        completedDays: Int? = nil,
        now: Date = Date(),
        timeZone: TimeZone = .current
    ) -> String {
        let normalizedWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(windowDays)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: now)
        let primaryTitle = fameOnboardingCommandTitle(plan.primaryCommandID)
        let backupTitle = fameOnboardingCommandTitle(plan.backupCommandID)
        let progressSection: String
        if let completedDays {
            let normalizedCompletedDays = min(normalizedWindowDays, max(0, completedDays))
            let remainingDays = max(0, normalizedWindowDays - normalizedCompletedDays)
            progressSection = """

            Progress:
            - Completed onboarding days: \(normalizedCompletedDays)/\(normalizedWindowDays)
            - Remaining onboarding days: \(remainingDays)

            """
        } else {
            progressSection = ""
        }

        return """
        # Fluid Reader Fame Onboarding Nudge

        Day \(plan.day) of \(normalizedWindowDays) · \(plan.phaseTitle)
        Date: \(today)

        Focus: \(plan.focusLine)

        \(progressSection)Primary command:
        - `\(primaryTitle)` (`\(plan.primaryCommandID)`)

        Backup command:
        - `\(backupTitle)` (`\(plan.backupCommandID)`)

        Shortcut checks:
        - \(readerStatusShortcutMenuHintLine())

        Quick run order:
        1. Run primary command.
        2. Run backup command.
        3. Save one snapshot with `run-fame-sprint-snapshot`.

        Done signal:
        - One fresh proof loop shipped.
        - Cadence streak protected into the next publish window.
        """
    }

    nonisolated static func fameOnboardingCommandTitle(_ commandID: String) -> String {
        switch commandID {
        case "run-fame-exceptional-loop":
            return "Run Fame Exceptional Loop"
        case "run-fame-exceptional-loop-recovery-lane-now":
            return "Run Recovery Lane Now"
        case "run-fame-next-move-cadence-execution-kit":
            return "Run Next Move + Cadence Execution Kit"
        case "run-fame-cadence-autopilot-loop":
            return "Run Cadence Autopilot Loop"
        case "run-fame-cadence-momentum-brief":
            return "Run Cadence Momentum Brief"
        case "copy-fame-cadence-share-line":
            return "Copy Cadence Share Line"
        case "copy-fame-cadence-share-pack":
            return "Copy Cadence Share Pack"
        case "copy-next-move-best-channel-launch-pack":
            return "Copy Best Channel Launch Pack"
        case "copy-next-move-best-channel-draft":
            return "Copy Best Channel Draft"
        case "open-latest-cadence-momentum-brief":
            return "Open Latest Cadence Momentum Brief"
        case "open-latest-cadence-share-line":
            return "Open Latest Cadence Share Line"
        case "open-latest-cadence-share-pack":
            return "Open Latest Cadence Share Pack"
        case "open-latest-fame-exceptional-loop-recap":
            return "Open Latest Exceptional Loop Recap"
        case "auto-tune-fame-exceptional-loop-recovery":
            return "Auto-Tune Exceptional Loop Recovery"
        case "reset-fame-exceptional-loop-tuning":
            return "Reset Exceptional Loop Tuning"
        case "run-fame-cadence-celebration-demo":
            return "Run Cadence Celebration Demo"
        case "run-fame-launch-rescue-followup-now":
            return "Run Launch Rescue Follow-up Now"
        case "run-fame-onboarding-daily-brief":
            return "Run First-Week Daily Brief"
        case "run-fame-onboarding-scorecard":
            return "Run First-Week Fame Scorecard"
        case "run-fame-onboarding-nudge":
            return "Run Fame Onboarding Nudge"
        case "run-fame-onboarding-fill-gap":
            return "Fill Onboarding Gap"
        case "run-fame-spotlight-pack":
            return "Run Fame Spotlight Pack"
        default:
            return commandID
        }
    }

    nonisolated static func isCadenceExecutionKitCommandAction(_ actionID: String) -> Bool {
        switch actionID {
        case "run-fame-next-move-cadence-execution-kit",
             "copy-next-move-cadence-execution-kit",
             "run-fame-cadence-autopilot-loop":
            return true
        default:
            return false
        }
    }

    nonisolated static func isCadenceExecutionKitCommandNeutralAction(_ actionID: String) -> Bool {
        switch actionID {
        case "run-fame-cadence-momentum-brief",
             "copy-fame-cadence-share-line",
             "copy-fame-cadence-share-pack",
             "copy-next-move-best-channel-launch-pack",
             "copy-next-move-best-channel-draft",
             "open-latest-cadence-momentum-brief",
             "open-latest-cadence-share-line",
             "open-latest-cadence-share-pack",
             "open-latest-fame-exceptional-loop-recap",
             "run-fame-cadence-celebration-demo",
             "run-fame-onboarding-fill-gap",
             "run-fame-onboarding-daily-brief",
             "run-fame-onboarding-scorecard",
             "run-fame-onboarding-nudge",
             "auto-tune-fame-exceptional-loop-recovery",
             "reset-fame-exceptional-loop-tuning",
             "run-fame-launch-rescue-followup-now":
            return true
        default:
            return false
        }
    }

    nonisolated static func nextCadenceExecutionKitCommandStreak(
        currentStreak: Int,
        actionID: String
    ) -> Int {
        let normalizedCurrentStreak = max(0, currentStreak)
        if isCadenceExecutionKitCommandNeutralAction(actionID) {
            return normalizedCurrentStreak
        }
        guard isCadenceExecutionKitCommandAction(actionID) else {
            return 0
        }
        return normalizedCurrentStreak + 1
    }

    struct CadenceExecutionKitCommandStreakUpdate: Equatable {
        let previousStreak: Int
        let nextStreak: Int
        let bestStreak: Int
        let milestone: Int?
        let activityDetails: [String]
    }

    nonisolated static func updateCadenceExecutionKitCommandStreak(
        actionID: String,
        defaults: UserDefaults = .standard
    ) -> CadenceExecutionKitCommandStreakUpdate {
        let previousStreak = max(0, defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey))
        let previousBestStreak = max(0, defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey))
        let nextStreak = nextCadenceExecutionKitCommandStreak(
            currentStreak: previousStreak,
            actionID: actionID
        )
        defaults.set(nextStreak, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)

        let didIncreaseStreak = nextStreak > previousStreak
        let didResetStreak = nextStreak == 0 && previousStreak > 0
        let bestStreak = max(nextStreak, max(previousStreak, previousBestStreak))
        if bestStreak != previousBestStreak {
            defaults.set(bestStreak, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        }

        var details: [String] = []
        if didIncreaseStreak {
            details.append("cadence-execution-kit-streak-\(nextStreak)")
        } else if didResetStreak {
            details.append("cadence-execution-kit-streak-reset")
        }

        let milestone = didIncreaseStreak ? cadenceExecutionKitCommandMilestone(for: nextStreak) : nil
        if let milestone {
            details.append("cadence-execution-kit-streak-milestone-\(milestone)")
        }

        return CadenceExecutionKitCommandStreakUpdate(
            previousStreak: previousStreak,
            nextStreak: nextStreak,
            bestStreak: bestStreak,
            milestone: milestone,
            activityDetails: details
        )
    }

    nonisolated static func resetCadenceExecutionKitCommandStreak(defaults: UserDefaults = .standard) {
        defaults.set(0, forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        defaults.set(0, forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
    }

    nonisolated static func resetFameExceptionalLoopOutcomeTuning(defaults: UserDefaults = .standard) {
        defaults.set(0, forKey: AppDefaults.fameExceptionalLoopOutcomeTotalCountKey)
        defaults.set(0, forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey)
        defaults.set(0, forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey)
        defaults.set(0, forKey: AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey)
        defaults.removeObject(forKey: AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey)
        defaults.removeObject(forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey)
        defaults.removeObject(forKey: AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey)
        defaults.removeObject(forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey)
    }

    nonisolated static func cadenceExecutionKitCommandMilestone(for streak: Int) -> Int? {
        if [3, 5, 10].contains(streak) {
            return streak
        }
        if streak > 10 && streak % 5 == 0 {
            return streak
        }
        return nil
    }

    nonisolated static func cadenceExecutionKitCommandMilestoneTitle(_ milestone: Int) -> String {
        "Cadence Kit Streak x\(milestone)"
    }

    nonisolated static func cadenceExecutionKitCommandMilestonePetMessage(_ milestone: Int) -> String {
        let normalizedMilestone = max(0, milestone)
        let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedMilestone)
        return "Cadence execution streak x\(normalizedMilestone). Run Cadence Autopilot Loop toward x\(nextMilestone)."
    }

    struct CadenceExecutionKitCommandDeltaFeedback: Equatable {
        let title: String
        let subtitle: String
        let statusSymbol: String
    }

    enum CadenceExecutionKitAutopilotCueTier: String, Equatable {
        case recovery
        case restart
        case momentum
        case breakout
        case fameSurge
    }

    nonisolated static func cadenceExecutionKitAutopilotCelebrationIntensityTitle(_ intensity: Int) -> String {
        let normalizedIntensity = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(intensity)
        switch normalizedIntensity {
        case 0:
            return "Calm"
        case 2:
            return "Epic"
        default:
            return "Balanced"
        }
    }

    nonisolated static func cadenceExecutionKitAutopilotCelebrationIntensityToken(_ intensity: Int) -> String {
        let normalizedIntensity = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(intensity)
        switch normalizedIntensity {
        case 0:
            return "calm"
        case 2:
            return "epic"
        default:
            return "balanced"
        }
    }

    struct CadenceExecutionKitAutopilotCue: Equatable {
        let title: String
        let subtitle: String
        let petMessage: String
        let statusSymbol: String
        let isRecovery: Bool
        let token: String
        let tier: CadenceExecutionKitAutopilotCueTier
    }

    nonisolated static func cadenceExecutionKitAutopilotCueTier(
        previousStreak: Int,
        nextStreak: Int,
        bestStreak: Int,
        milestone: Int?
    ) -> CadenceExecutionKitAutopilotCueTier {
        let normalizedPreviousStreak = max(0, previousStreak)
        let normalizedNextStreak = max(0, nextStreak)
        let normalizedBestStreak = max(normalizedNextStreak, max(0, bestStreak))

        if normalizedNextStreak == 0, normalizedPreviousStreak > 0 {
            return .recovery
        }

        guard let milestone, milestone > 0 else {
            return .restart
        }

        if milestone >= 25 || normalizedBestStreak >= 30 {
            return .fameSurge
        }
        if milestone >= 10 {
            return .breakout
        }
        if milestone >= 5 {
            return .momentum
        }
        return .restart
    }

    nonisolated static func cadenceExecutionKitAutopilotCueMilestoneTitle(
        milestone: Int,
        tier: CadenceExecutionKitAutopilotCueTier
    ) -> String {
        let normalizedMilestone = max(0, milestone)
        switch tier {
        case .fameSurge:
            return "Cadence milestone x\(normalizedMilestone) · Fame Surge"
        case .breakout:
            return "Cadence milestone x\(normalizedMilestone) · Breakout"
        default:
            return "Cadence milestone x\(normalizedMilestone)"
        }
    }

    nonisolated static func cadenceExecutionKitAutopilotCueMilestoneSubtitle(
        nextMoveLabel: String,
        nextMilestone: Int,
        remainingRuns: Int,
        tier: CadenceExecutionKitAutopilotCueTier
    ) -> String {
        let normalizedNextMilestone = max(0, nextMilestone)
        let normalizedRemainingRuns = max(1, remainingRuns)
        let runWord = normalizedRemainingRuns == 1 ? "run" : "runs"
        let base = "Run Cadence Autopilot Loop: \(nextMoveLabel) toward x\(normalizedNextMilestone) in \(normalizedRemainingRuns) \(runWord)."
        switch tier {
        case .fameSurge:
            return "Fame surge unlocked · \(base)"
        case .breakout:
            return "Breakout unlocked · \(base)"
        case .momentum:
            return "Momentum locked · \(base)"
        case .restart:
            return "Restart locked · \(base)"
        case .recovery:
            return base
        }
    }

    nonisolated static func cadenceExecutionKitAutopilotCueMilestonePetMessage(
        milestone: Int,
        tier: CadenceExecutionKitAutopilotCueTier
    ) -> String {
        let base = cadenceExecutionKitCommandMilestonePetMessage(milestone)
        switch tier {
        case .fameSurge:
            return "\(base) Fame surge unlocked. Ship the next move now."
        case .breakout:
            return "\(base) Breakout unlocked. Keep the streak hot."
        case .momentum:
            return "\(base) Momentum is building."
        case .restart:
            return "\(base) Fresh cadence run is locked."
        case .recovery:
            return base
        }
    }

    nonisolated static func cadenceExecutionKitCommandNextMilestoneTarget(after streak: Int) -> Int {
        let normalizedStreak = max(0, streak)
        if normalizedStreak < 3 {
            return 3
        }
        if normalizedStreak < 5 {
            return 5
        }
        if normalizedStreak < 10 {
            return 10
        }
        return ((normalizedStreak / 5) + 1) * 5
    }

    nonisolated static func cadenceExecutionKitCommandDeltaFeedback(
        previousStreak: Int,
        nextStreak: Int,
        bestStreak: Int,
        milestone: Int?
    ) -> CadenceExecutionKitCommandDeltaFeedback? {
        let normalizedPreviousStreak = max(0, previousStreak)
        let normalizedNextStreak = max(0, nextStreak)
        guard normalizedNextStreak > normalizedPreviousStreak else { return nil }

        let normalizedBestStreak = max(normalizedNextStreak, bestStreak)
        let title = "Cadence +1 to x\(normalizedNextStreak)"
        let statusSymbol: String
        if normalizedNextStreak >= 10 {
            statusSymbol = "trophy.fill"
        } else if normalizedNextStreak >= 5 {
            statusSymbol = "rocket.fill"
        } else {
            statusSymbol = "bolt.fill"
        }

        if let milestone {
            return CadenceExecutionKitCommandDeltaFeedback(
                title: title,
                subtitle: "Milestone x\(milestone) unlocked · Best x\(normalizedBestStreak)",
                statusSymbol: statusSymbol
            )
        }

        let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedNextStreak)
        let remainingRuns = max(1, nextMilestone - normalizedNextStreak)
        let runWord = remainingRuns == 1 ? "run" : "runs"
        return CadenceExecutionKitCommandDeltaFeedback(
            title: title,
            subtitle: "Next milestone x\(nextMilestone) in \(remainingRuns) \(runWord) · Best x\(normalizedBestStreak)",
            statusSymbol: statusSymbol
        )
    }

    nonisolated static func cadenceExecutionKitAutopilotCue(
        previousStreak: Int,
        nextStreak: Int,
        bestStreak: Int,
        milestone: Int?,
        nextMoveLabel: String
    ) -> CadenceExecutionKitAutopilotCue? {
        let normalizedPreviousStreak = max(0, previousStreak)
        let normalizedNextStreak = max(0, nextStreak)
        let normalizedBestStreak = max(normalizedNextStreak, max(0, bestStreak))
        let cleanNextMoveLabel = nextMoveLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedNextMoveLabel = cleanNextMoveLabel.isEmpty ? "Next Move" : cleanNextMoveLabel
        let tier = cadenceExecutionKitAutopilotCueTier(
            previousStreak: normalizedPreviousStreak,
            nextStreak: normalizedNextStreak,
            bestStreak: normalizedBestStreak,
            milestone: milestone
        )

        if normalizedNextStreak == 0, normalizedPreviousStreak > 0 {
            let subtitle: String
            let petMessage: String
            let title: String
            if normalizedBestStreak > 0 {
                if normalizedBestStreak >= 10 {
                    title = "Cadence reset · Comeback mode"
                    subtitle = "Best x\(normalizedBestStreak) saved · run Cadence Autopilot Loop (\(resolvedNextMoveLabel)) now to reclaim breakout pace."
                    petMessage = "Cadence streak reset. Best x\(normalizedBestStreak) saved. Comeback mode is live."
                } else {
                    title = "Cadence reset · Autopilot rebuild"
                    subtitle = "Best x\(normalizedBestStreak) saved · run Cadence Autopilot Loop (\(resolvedNextMoveLabel)) now."
                    petMessage = "Cadence streak reset. Best x\(normalizedBestStreak) saved. Run Cadence Autopilot Loop now."
                }
            } else {
                title = "Cadence reset · Autopilot rebuild"
                subtitle = "Run Cadence Autopilot Loop (\(resolvedNextMoveLabel)) now."
                petMessage = "Cadence streak reset. Run Cadence Autopilot Loop now."
            }
            return CadenceExecutionKitAutopilotCue(
                title: title,
                subtitle: subtitle,
                petMessage: petMessage,
                statusSymbol: "arrow.counterclockwise.circle.fill",
                isRecovery: true,
                token: "reset",
                tier: tier
            )
        }

        guard let milestone, milestone > 0 else { return nil }
        let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: milestone)
        let remainingRuns = max(1, nextMilestone - milestone)
        return CadenceExecutionKitAutopilotCue(
            title: cadenceExecutionKitAutopilotCueMilestoneTitle(
                milestone: milestone,
                tier: tier
            ),
            subtitle: cadenceExecutionKitAutopilotCueMilestoneSubtitle(
                nextMoveLabel: resolvedNextMoveLabel,
                nextMilestone: nextMilestone,
                remainingRuns: remainingRuns,
                tier: tier
            ),
            petMessage: cadenceExecutionKitAutopilotCueMilestonePetMessage(
                milestone: milestone,
                tier: tier
            ),
            statusSymbol: cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: normalizedNextStreak,
                bestStreak: normalizedBestStreak
            ),
            isRecovery: false,
            token: "milestone-\(milestone)",
            tier: tier
        )
    }

    nonisolated static func shouldSurfaceCadenceExecutionKitAutopilotCue(
        lastCueAt: Date?,
        lastCueToken: String?,
        nextCueToken: String,
        now: Date = Date(),
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameCadenceAutopilotCueCooldownSeconds
        )
    ) -> Bool {
        guard cooldown > 0 else { return true }
        guard lastCueToken == nextCueToken else { return true }
        guard let lastCueAt else { return true }
        return now.timeIntervalSince(lastCueAt) >= cooldown
    }

    nonisolated static func cadenceExecutionKitAutopilotCueCooldownRemainingSeconds(
        lastCueAt: Date?,
        lastCueToken: String?,
        nextCueToken: String,
        now: Date = Date(),
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameCadenceAutopilotCueCooldownSeconds
        )
    ) -> Int? {
        guard cooldown > 0,
              lastCueToken == nextCueToken,
              let lastCueAt else {
            return nil
        }
        let remaining = cooldown - now.timeIntervalSince(lastCueAt)
        guard remaining > 0 else { return nil }
        return max(1, Int(ceil(remaining)))
    }

    nonisolated static func nextMoveCadenceStepCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveCadenceStepCopyOutcome {
        guard let handoffMarkdown else { return .missingHandoff }
        guard let firstStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoffMarkdown) else {
            return .missingCadenceStep
        }
        return .ready(step: firstStep)
    }

    nonisolated static func nextMoveCadencePostCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveCadencePostCopyOutcome {
        switch nextMoveCadenceStepCopyOutcome(handoffMarkdown: handoffMarkdown) {
        case .missingHandoff:
            return .missingHandoff
        case .missingCadenceStep:
            return .missingCadenceStep
        case .ready(let firstStep):
            guard let post = nextMoveCadenceDraft(from: firstStep) else {
                return .missingDraft
            }
            return .ready(post: post)
        }
    }

    nonisolated static func nextMoveCadenceDraft(from firstCadenceStep: String) -> String? {
        guard let rawDraftLine = firstCadenceStep
            .split(whereSeparator: \.isNewline)
            .map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { $0.hasPrefix("Draft:") }) else {
            return nil
        }

        let draft = rawDraftLine
            .replacingOccurrences(of: "Draft:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !draft.isEmpty else { return nil }
        return draft
    }

    nonisolated static func nextMoveCadencePostQueue(
        post: String,
        launchNowSequence: String
    ) -> String {
        """
        Cadence Post Queue (Next 30m):

        Post Now (copied to clipboard):
        \(post)

        Follow-up Sequence:
        \(launchNowSequence)

        Posting Checklist:
        - [ ] Publish cadence post now.
        - [ ] Queue both follow-up drafts for the 15-30m window.
        - [ ] Capture first reply signal and one proof note.
        """
    }

    nonisolated static func nextMoveCadencePostQueueCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveCadencePostQueueCopyOutcome {
        switch nextMoveCadencePostCopyOutcome(handoffMarkdown: handoffMarkdown) {
        case .missingHandoff:
            return .missingHandoff
        case .missingCadenceStep:
            return .missingCadenceStep
        case .missingDraft:
            return .missingDraft
        case .ready(let post):
            switch nextMoveLaunchNowSequenceCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                return .missingHandoff
            case .missingCadenceStep:
                return .missingCadenceStep
            case .missingDraft:
                return .missingDraft
            case .ready(let sequence):
                return .ready(
                    post: post,
                    queue: nextMoveCadencePostQueue(post: post, launchNowSequence: sequence)
                )
            }
        }
    }

    nonisolated static func nextMoveReplyLadder(
        cadencePost: String,
        xDraft: String,
        blueskyDraft: String,
        linkedInDraft: String
    ) -> String {
        """
        Next-Move Reply Ladder (First 30m):

        1) Context opener
        We just shipped: "\(cadencePost)" — what metric would you watch first?

        2) Operator prompt
        Running this next loop now: "\(xDraft)" — what would you tighten in 15m?

        3) Channel calibration
        Bluesky variant: "\(blueskyDraft)" — which hook lands hardest for builders?

        4) Proof request
        LinkedIn angle: "\(linkedInDraft)" — share one proof asset you'd add.

        5) Close + CTA
        Drop one execution suggestion and we’ll test it in this cycle.
        """
    }

    nonisolated static func nextMoveReplyLadderCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveReplyLadderCopyOutcome {
        switch nextMoveCadencePostCopyOutcome(handoffMarkdown: handoffMarkdown) {
        case .missingHandoff:
            return .missingHandoff
        case .missingCadenceStep:
            return .missingCadenceStep
        case .missingDraft:
            return .missingDraft
        case .ready(let cadencePost):
            let xOutcome = nextMoveChannelDraftCopyOutcome(channel: .x, handoffMarkdown: handoffMarkdown)
            let blueskyOutcome = nextMoveChannelDraftCopyOutcome(channel: .bluesky, handoffMarkdown: handoffMarkdown)
            let linkedInOutcome = nextMoveChannelDraftCopyOutcome(channel: .linkedIn, handoffMarkdown: handoffMarkdown)

            guard case .ready(let xDraft) = xOutcome,
                  case .ready(let blueskyDraft) = blueskyOutcome,
                  case .ready(let linkedInDraft) = linkedInOutcome else {
                return .missingDraft
            }

            return .ready(
                ladder: nextMoveReplyLadder(
                    cadencePost: cadencePost,
                    xDraft: xDraft,
                    blueskyDraft: blueskyDraft,
                    linkedInDraft: linkedInDraft
                )
            )
        }
    }

    nonisolated static func nextMoveCadenceExecutionKit(
        post: String,
        queue: String,
        replyLadder: String
    ) -> String {
        """
        Cadence Execution Kit (Next 30m):

        Post Now (copied to clipboard):
        \(post)

        \(queue)

        \(replyLadder)

        Execution Checklist:
        - [ ] Publish cadence post now.
        - [ ] Queue two follow-up drafts in the 15-30m window.
        - [ ] Run all 5 ladder replies.
        - [ ] Capture one proof metric and log it.
        """
    }

    nonisolated static func nextMoveCadenceExecutionKitCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveCadenceExecutionKitCopyOutcome {
        switch nextMoveCadencePostCopyOutcome(handoffMarkdown: handoffMarkdown) {
        case .missingHandoff:
            return .missingHandoff
        case .missingCadenceStep:
            return .missingCadenceStep
        case .missingDraft:
            return .missingDraft
        case .ready(let post):
            switch nextMoveCadencePostQueueCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                return .missingHandoff
            case .missingCadenceStep:
                return .missingCadenceStep
            case .missingDraft:
                return .missingDraft
            case .ready(_, let queue):
                switch nextMoveReplyLadderCopyOutcome(handoffMarkdown: handoffMarkdown) {
                case .missingHandoff:
                    return .missingHandoff
                case .missingCadenceStep:
                    return .missingCadenceStep
                case .missingDraft:
                    return .missingDraft
                case .ready(let ladder):
                    return .ready(
                        post: post,
                        kit: nextMoveCadenceExecutionKit(
                            post: post,
                            queue: queue,
                            replyLadder: ladder
                        )
                    )
                }
            }
        }
    }

    nonisolated static func nextMoveChannelDraftCopyOutcome(
        channel: NextMoveDraftChannel,
        handoffMarkdown: String?
    ) -> NextMoveChannelDraftCopyOutcome {
        guard let handoffMarkdown else { return .missingHandoff }
        guard let drafts = FameSnapshotRollup.nextMoveHandoffDrafts(from: handoffMarkdown) else {
            return .missingDraft
        }

        let draft: String
        switch channel {
        case .x:
            draft = drafts.xDraft
        case .bluesky:
            draft = drafts.blueskyDraft
        case .linkedIn:
            draft = drafts.linkedInDraft
        }

        let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDraft.isEmpty else { return .missingDraft }
        return .ready(draft: trimmedDraft)
    }

    nonisolated static func nextMoveBestChannelDraftCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveBestChannelDraftCopyOutcome {
        guard let handoffMarkdown else { return .missingHandoff }
        guard let firstCadenceStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoffMarkdown) else {
            return .missingCadenceStep
        }
        guard let primaryChannel = nextMoveCadencePrimaryChannel(from: firstCadenceStep) else {
            return .missingCadenceStep
        }

        switch nextMoveChannelDraftCopyOutcome(channel: primaryChannel, handoffMarkdown: handoffMarkdown) {
        case .missingHandoff:
            return .missingHandoff
        case .missingDraft:
            return .missingDraft
        case .ready(let draft):
            return .ready(channel: primaryChannel, draft: draft)
        }
    }

    nonisolated static func nextMoveBestChannelLaunchPack(
        channel: NextMoveDraftChannel,
        post: String,
        cadenceStep: String,
        launchNowSequence: String
    ) -> String {
        let channelTitle = nextMoveDraftChannelTitle(channel)
        return """
        Best Channel Launch Pack (Next 30m):

        Primary channel: \(channelTitle)

        Post Now (copied to clipboard):
        \(post)

        First Cadence Step:
        \(cadenceStep)

        Cross-Channel Follow-up Sequence:
        \(launchNowSequence)

        Publish checklist:
        - [ ] Ship the primary \(channelTitle) post now.
        - [ ] Queue both follow-up drafts from the sequence.
        - [ ] Capture one proof metric in the next 30m.
        """
    }

    nonisolated static func nextMoveBestChannelLaunchPackCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveBestChannelLaunchPackCopyOutcome {
        switch nextMoveBestChannelDraftCopyOutcome(handoffMarkdown: handoffMarkdown) {
        case .missingHandoff:
            return .missingHandoff
        case .missingCadenceStep:
            return .missingCadenceStep
        case .missingDraft:
            return .missingDraft
        case .ready(let channel, let post):
            switch nextMoveCadenceStepCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                return .missingHandoff
            case .missingCadenceStep:
                return .missingCadenceStep
            case .ready(let step):
                switch nextMoveLaunchNowSequenceCopyOutcome(handoffMarkdown: handoffMarkdown) {
                case .missingHandoff:
                    return .missingHandoff
                case .missingCadenceStep:
                    return .missingCadenceStep
                case .missingDraft:
                    return .missingDraft
                case .ready(let sequence):
                    return .ready(
                        channel: channel,
                        post: post,
                        pack: nextMoveBestChannelLaunchPack(
                            channel: channel,
                            post: post,
                            cadenceStep: step,
                            launchNowSequence: sequence
                        )
                    )
                }
            }
        }
    }

    nonisolated static func nextMoveDraftChannelTitle(_ channel: NextMoveDraftChannel) -> String {
        switch channel {
        case .x:
            return "X"
        case .bluesky:
            return "Bluesky"
        case .linkedIn:
            return "LinkedIn"
        }
    }

    nonisolated static func nextMoveDraftChannelActivityDetailBase(
        _ channel: NextMoveDraftChannel
    ) -> String {
        switch channel {
        case .x:
            return "copy-next-move-x-draft"
        case .bluesky:
            return "copy-next-move-bluesky-draft"
        case .linkedIn:
            return "copy-next-move-linkedin-draft"
        }
    }

    nonisolated static func nextMoveBestChannelDraftActionSubtitle(
        handoffMarkdown: String?
    ) -> String {
        guard let primaryChannel = nextMoveCadencePrimaryChannel(handoffMarkdown: handoffMarkdown) else {
            return "Copy first cadence channel draft from handoff"
        }

        let channelTitle = nextMoveDraftChannelTitle(primaryChannel)
        return "Best channel now: \(channelTitle) · copy first cadence draft"
    }

    nonisolated static func nextMoveBestChannelLaunchPackActionSubtitle(
        handoffMarkdown: String?,
        pressureModeTransitionCount: Int = 0,
        pressureModeTransitionLatest: String? = nil,
        pressureModeMomentumStreak: Int = 0
    ) -> String {
        let baseSubtitle: String
        guard let primaryChannel = nextMoveCadencePrimaryChannel(handoffMarkdown: handoffMarkdown) else {
            baseSubtitle = "Copy best channel post + launch pack"
            return bestChannelLaunchPackSubtitleWithModeSignals(
                baseSubtitle: baseSubtitle,
                transitionCount: pressureModeTransitionCount,
                latestToken: pressureModeTransitionLatest,
                momentumStreak: pressureModeMomentumStreak
            )
        }

        let channelTitle = nextMoveDraftChannelTitle(primaryChannel)
        baseSubtitle = "Best channel now: \(channelTitle) · copy post + launch pack"
        return bestChannelLaunchPackSubtitleWithModeSignals(
            baseSubtitle: baseSubtitle,
            transitionCount: pressureModeTransitionCount,
            latestToken: pressureModeTransitionLatest,
            momentumStreak: pressureModeMomentumStreak
        )
    }

    nonisolated static func bestChannelLaunchPackMenuTitle(
        transitionCount: Int,
        latestToken: String?,
        momentumStreak: Int = 0
    ) -> String {
        let baseTitle = "Copy Best Channel Launch Pack"
        guard transitionCount > 0 else { return baseTitle }
        guard let modeShift = bestChannelLaunchPackPressureModeShift(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) else {
            return "\(baseTitle) · Mode Shift"
        }

        let suffix: String = switch modeShift.toToken {
        case "compounding":
            "Ship Momentum"
        case "rebuilding":
            "Rebuild Streak"
        case "cooling":
            "Restart Streak"
        case "no-wins", "none":
            "Start Streak"
        default:
            "Mode Shift"
        }
        if momentumStreak >= 2 {
            return "\(baseTitle) · Surge x\(momentumStreak)"
        }
        if momentumStreak <= -2 {
            return "\(baseTitle) · Break Cooldown x\(abs(momentumStreak))"
        }
        return "\(baseTitle) · \(suffix)"
    }

    nonisolated static func bestChannelDraftMenuTitle(
        transitionCount: Int,
        latestToken: String?,
        momentumStreak: Int = 0
    ) -> String {
        let baseTitle = "Copy Best Channel Draft"
        guard transitionCount > 0 else { return baseTitle }
        guard let modeShift = bestChannelLaunchPackPressureModeShift(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) else {
            return "\(baseTitle) · Mode Assist"
        }

        let suffix: String = switch modeShift.toToken {
        case "compounding":
            "Keep Queue Warm"
        case "rebuilding":
            "Support Rebuild"
        case "cooling":
            "Prep Recovery"
        case "no-wins", "none":
            "Start Recovery"
        default:
            "Mode Assist"
        }
        if momentumStreak >= 2 {
            return "\(baseTitle) · Queue Surge Support"
        }
        if momentumStreak <= -2 {
            return "\(baseTitle) · Recovery Queue"
        }
        return "\(baseTitle) · \(suffix)"
    }

    nonisolated static func bestChannelLaunchPackMenuToolTip(
        transitionCount: Int,
        latestToken: String?,
        momentumStreak: Int = 0
    ) -> String {
        let baseText = "Copy best channel post + launch pack from the latest handoff."
        guard transitionCount > 0 else { return baseText }
        let momentumLine = bestChannelLaunchPackPressureModeMomentumLine(momentumStreak)
        guard let modeShift = bestChannelLaunchPackPressureModeShift(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) else {
            var fallback = "\(baseText) Mode shifts are tracked (\(transitionCount) total); ship now to stabilize momentum."
            if let momentumLine {
                fallback += " \(momentumLine)"
            }
            return fallback
        }

        let modeLine = "Latest mode shift \(modeShift.fromTitle) -> \(modeShift.toTitle) (\(transitionCount) total)."
        let guidance: String = switch modeShift.toToken {
        case "compounding":
            "Protect momentum with an immediate ship."
        case "rebuilding":
            "One more win can restore compounding pace."
        case "cooling":
            "Run it now to prevent deeper cooldown."
        case "no-wins", "none":
            "Start a fresh win streak with one launch now."
        default:
            "Keep launch cadence tight."
        }
        var text = "\(baseText) \(modeLine) \(guidance)"
        if let momentumLine {
            text += " \(momentumLine)"
        }
        return text
    }

    nonisolated static func bestChannelDraftMenuToolTip(
        transitionCount: Int,
        latestToken: String?,
        momentumStreak: Int = 0
    ) -> String {
        let baseText = "Copy the first cadence draft for the current best channel."
        guard transitionCount > 0 else { return baseText }
        let momentumLine = bestChannelLaunchPackPressureModeMomentumLine(momentumStreak)
        guard let modeShift = bestChannelLaunchPackPressureModeShift(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) else {
            var fallback = "\(baseText) Mode shifts are tracked (\(transitionCount) total); queue draft support before the next ship window."
            if let momentumLine {
                fallback += " \(momentumLine)"
            }
            return fallback
        }

        let modeLine = "Latest mode shift \(modeShift.fromTitle) -> \(modeShift.toTitle) (\(transitionCount) total)."
        let guidance: String = switch modeShift.toToken {
        case "compounding":
            "Keep the next draft queued so momentum does not stall."
        case "rebuilding":
            "Draft now to support the rebuild push."
        case "cooling":
            "Draft now to speed up recovery when pressure spikes."
        case "no-wins", "none":
            "Prepare the first recovery draft before the next launch."
        default:
            "Keep the draft queue warm."
        }
        var text = "\(baseText) \(modeLine) \(guidance)"
        if let momentumLine {
            text += " \(momentumLine)"
        }
        return text
    }

    nonisolated static func bestChannelLaunchPackPressureModeShiftSubtitle(
        transitionCount: Int,
        latestToken: String?
    ) -> String? {
        guard transitionCount > 0 else { return nil }
        guard let modeShift = bestChannelLaunchPackPressureModeShift(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) else {
            return "Mode shift tracked"
        }
        return "Mode shift \(modeShift.fromTitle) -> \(modeShift.toTitle)"
    }

    nonisolated private static func bestChannelLaunchPackSubtitleWithModeSignals(
        baseSubtitle: String,
        transitionCount: Int,
        latestToken: String?,
        momentumStreak: Int
    ) -> String {
        var parts = [baseSubtitle]
        if let modeShiftSubtitle = bestChannelLaunchPackPressureModeShiftSubtitle(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) {
            parts.append(modeShiftSubtitle)
        }
        if let momentumLine = bestChannelLaunchPackPressureModeMomentumSubtitle(momentumStreak) {
            parts.append(momentumLine)
        }
        return parts.joined(separator: " · ")
    }

    nonisolated static func bestChannelLaunchPackPressureModeMomentumSubtitle(
        _ momentumStreak: Int
    ) -> String? {
        if momentumStreak >= 2 {
            return "Upshift streak x\(momentumStreak)"
        }
        if momentumStreak <= -2 {
            return "Cooldown streak x\(abs(momentumStreak))"
        }
        return nil
    }

    nonisolated private static func bestChannelLaunchPackPressureModeMomentumLine(
        _ momentumStreak: Int
    ) -> String? {
        if momentumStreak >= 2 {
            return "Mode momentum is rising (upshift streak x\(momentumStreak))."
        }
        if momentumStreak <= -2 {
            return "Mode momentum is cooling (cooldown streak x\(abs(momentumStreak)))."
        }
        return nil
    }

    private struct BestChannelLaunchPackPressureModeShift: Equatable {
        let fromToken: String
        let toToken: String
        let fromTitle: String
        let toTitle: String
    }

    nonisolated private static func bestChannelLaunchPackPressureModeShift(
        transitionCount: Int,
        latestToken: String?
    ) -> BestChannelLaunchPackPressureModeShift? {
        guard transitionCount > 0 else { return nil }
        let normalizedLatestToken = latestToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        let parts = normalizedLatestToken.components(separatedBy: "-to-")
        guard parts.count == 2 else { return nil }

        let fromToken = parts[0]
        let toToken = parts[1]
        return BestChannelLaunchPackPressureModeShift(
            fromToken: fromToken,
            toToken: toToken,
            fromTitle: bestChannelLaunchPackPressureTrendTitle(fromToken),
            toTitle: bestChannelLaunchPackPressureTrendTitle(toToken)
        )
    }

    nonisolated private static func bestChannelLaunchPackPressureTrendTitle(_ token: String) -> String {
        switch token {
        case "compounding":
            return "Compounding"
        case "rebuilding":
            return "Rebuilding"
        case "cooling":
            return "Cooling"
        case "no-wins":
            return "No Wins"
        case "none":
            return "None"
        default:
            return "Unknown"
        }
    }

    nonisolated static func nextMoveLaunchNowSequenceCopyOutcome(
        handoffMarkdown: String?
    ) -> NextMoveLaunchNowSequenceCopyOutcome {
        guard let handoffMarkdown else { return .missingHandoff }
        guard let firstCadenceStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoffMarkdown) else {
            return .missingCadenceStep
        }
        guard let drafts = FameSnapshotRollup.nextMoveHandoffDrafts(from: handoffMarkdown) else {
            return .missingDraft
        }

        let primaryCadenceChannel = nextMoveCadencePrimaryChannel(from: firstCadenceStep)
        let orderedChannels: [NextMoveDraftChannel] = [.x, .bluesky, .linkedIn]
        let secondaryChannels = Array(orderedChannels
            .filter { $0 != primaryCadenceChannel }
            .prefix(2))

        guard secondaryChannels.count == 2 else { return .missingDraft }

        let channelDrafts: [NextMoveDraftChannel: String] = [
            .x: drafts.xDraft,
            .bluesky: drafts.blueskyDraft,
            .linkedIn: drafts.linkedInDraft
        ]

        let firstFollowupChannel = secondaryChannels[0]
        let secondFollowupChannel = secondaryChannels[1]

        let firstFollowupDraft = (channelDrafts[firstFollowupChannel] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let secondFollowupDraft = (channelDrafts[secondFollowupChannel] ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstFollowupDraft.isEmpty, !secondFollowupDraft.isEmpty else {
            return .missingDraft
        }

        let firstFollowupChannelTitle = nextMoveDraftChannelTitle(firstFollowupChannel)
        let secondFollowupChannelTitle = nextMoveDraftChannelTitle(secondFollowupChannel)

        let sequence = """
        Launch Now Sequence (Next 30m):

        1) 0-15m:
        \(firstCadenceStep)

        2) 15-30m (\(firstFollowupChannelTitle)):
        \(firstFollowupDraft)

        3) 15-30m (\(secondFollowupChannelTitle)):
        \(secondFollowupDraft)
        """

        return .ready(sequence: sequence)
    }

    nonisolated static func nextMoveCadencePrimaryChannel(
        handoffMarkdown: String?
    ) -> NextMoveDraftChannel? {
        guard let handoffMarkdown,
              let firstCadenceStep = FameSnapshotRollup.nextMoveFirstCadenceStep(from: handoffMarkdown) else {
            return nil
        }
        return nextMoveCadencePrimaryChannel(from: firstCadenceStep)
    }

    nonisolated static func nextMoveCadencePrimaryChannel(
        from firstCadenceStep: String
    ) -> NextMoveDraftChannel? {
        guard let rawChannelLine = firstCadenceStep
            .split(whereSeparator: \.isNewline)
            .map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { $0.hasPrefix("Channel:") }) else {
            return nil
        }

        let channelPortion = rawChannelLine
            .replacingOccurrences(of: "Channel:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = channelPortion
            .components(separatedBy: "(")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalizedTitle {
        case "x":
            return .x
        case "bluesky":
            return .bluesky
        case "linkedin":
            return .linkedIn
        default:
            return nil
        }
    }

    nonisolated static func nextMoveCadencePrimaryChannelToken(
        _ channel: NextMoveDraftChannel
    ) -> String {
        switch channel {
        case .x:
            return "x"
        case .bluesky:
            return "bluesky"
        case .linkedIn:
            return "linkedin"
        }
    }

    nonisolated static func cadenceExecutionKitSharePackSource(
        usingLatestMomentumBrief: Bool,
        includesHandoffDrafts: Bool,
        preferredCadenceChannel: NextMoveDraftChannel?
    ) -> String {
        let baseSource = usingLatestMomentumBrief
            ? "Latest cadence momentum brief"
            : "Live momentum snapshot"
        guard includesHandoffDrafts else {
            return baseSource
        }

        let handoffSource = "\(baseSource) + latest next-move handoff"
        guard let preferredCadenceChannel else {
            return handoffSource
        }
        return "\(handoffSource) · Best channel \(nextMoveDraftChannelTitle(preferredCadenceChannel))"
    }

    nonisolated static func cadenceExecutionKitSharePackCopyActivityDetail(
        usingLatestMomentumBrief: Bool,
        includesHandoffDrafts: Bool,
        preferredCadenceChannel: NextMoveDraftChannel?
    ) -> String {
        var detail = usingLatestMomentumBrief
            ? "copy-fame-cadence-share-pack-latest"
            : "copy-fame-cadence-share-pack"
        guard includesHandoffDrafts else {
            return detail
        }

        detail += "-post-ready"
        if let preferredCadenceChannel {
            detail += "-best-\(nextMoveCadencePrimaryChannelToken(preferredCadenceChannel))"
        }
        return detail
    }

    nonisolated static func fameLaunchCountdownAlertTitle(_ status: FameLaunchCountdownStatus) -> String {
        "Launch Countdown: \(status.countdown)"
    }

    nonisolated static func fameLaunchCountdownMinutes(_ countdown: String) -> Int? {
        let trimmed = countdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("T"), trimmed.count >= 3 else { return nil }

        let signIndex = trimmed.index(after: trimmed.startIndex)
        let sign = trimmed[signIndex]
        guard sign == "-" || sign == "+" else { return nil }

        var minutePortion = String(trimmed[trimmed.index(after: signIndex)...])
        if minutePortion.hasSuffix("m") || minutePortion.hasSuffix("M") {
            minutePortion.removeLast()
        }
        guard let minutes = Int(minutePortion) else { return nil }
        return sign == "-" ? -minutes : minutes
    }

    nonisolated static func fameLaunchCountdownUrgency(_ status: FameLaunchCountdownStatus) -> String {
        guard let minutes = fameLaunchCountdownMinutes(status.countdown) else {
            return "Urgency Unknown"
        }

        if minutes >= 30 {
            return "Urgency Critical (overdue by \(minutes)m)"
        }
        if minutes >= 15 {
            return "Urgency High (overdue by \(minutes)m)"
        }
        if minutes > 0 {
            return "Urgency Hot (overdue by \(minutes)m)"
        }
        if minutes == 0 {
            return "Urgency Launch Window (ship now)"
        }

        let launchInMinutes = abs(minutes)
        if launchInMinutes <= 5 {
            return "Urgency Live (launch in \(launchInMinutes)m)"
        }
        if launchInMinutes <= 20 {
            return "Urgency Ready (launch in \(launchInMinutes)m)"
        }
        return "Urgency Prep (launch in \(launchInMinutes)m)"
    }

    nonisolated static func fameLaunchCountdownAlertSubtitle(_ status: FameLaunchCountdownStatus) -> String {
        "\(fameLaunchCountdownUrgency(status)) · Next: \(status.nextAction) · Risk \(status.pulseRisk) · Route \(status.launchRoute)"
    }

    nonisolated static func fameLaunchCountdownAlertSystemImage(_ status: FameLaunchCountdownStatus) -> String {
        guard let minutes = fameLaunchCountdownMinutes(status.countdown) else { return "timer" }
        if minutes >= 15 {
            return "exclamationmark.triangle.fill"
        }
        if minutes > 0 {
            return "flame.fill"
        }
        if minutes >= -5 {
            return "bolt.badge.clock"
        }
        return "timer"
    }

    nonisolated static func fameLaunchCountdownMenuTitle(_ status: FameLaunchCountdownStatus) -> String {
        "Launch Alert: \(fameLaunchCountdownUrgency(status))"
    }

    nonisolated static func fameLaunchAlertMenuTitle(
        launchStatus: FameLaunchCountdownStatus?,
        onboardingRecoveryHint: String? = nil
    ) -> String {
        let baseTitle: String
        if let launchStatus {
            baseTitle = fameLaunchCountdownMenuTitle(launchStatus)
        } else {
            baseTitle = "Launch Alert: Run Fame Launch Countdown"
        }
        return fameMenuTitle(baseTitle: baseTitle, appendedHint: onboardingRecoveryHint)
    }

    nonisolated static func launchControlBriefLaunchAlert(
        _ status: FameLaunchCountdownStatus?
    ) -> (title: String, subtitle: String) {
        guard let status else {
            return (
                "Launch Alert: Run Fame Launch Countdown",
                "Run `Run Fame Launch Day Script` first, then `Run Fame Launch Countdown`."
            )
        }
        return (
            fameLaunchCountdownAlertTitle(status),
            fameLaunchCountdownAlertSubtitle(status)
        )
    }

    nonisolated static func launchControlBriefPriorityMove(
        launchStatus: FameLaunchCountdownStatus?
    ) -> String {
        guard let urgency = fameLaunchBadgeUrgency(launchStatus) else {
            return "Run `Run Fame Launch Day Script`, then `Run Fame Launch Countdown`."
        }

        switch urgency {
        case .critical, .high:
            return "Run `Run Launch Rescue Burst` now, then ship `Next action now`."
        case .hot, .live:
            return "Ship `Next action now`, then post latest next-move draft pack."
        case .ready, .prep:
            return "Refresh launch countdown and pre-stage the next-move draft pack."
        }
    }

    nonisolated static func launchControlBriefHealthScore(
        launchStatus: FameLaunchCountdownStatus?
    ) -> String {
        switch launchControlHealthBand(launchStatus: launchStatus) {
        case .ready:
            return "Ready"
        case .watch:
            return "Watch"
        case .risk:
            return "Risk"
        }
    }

    nonisolated static func cadenceExecutionKitCommandStreakStatusTitle(
        currentStreak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak > 0 {
            return "Cadence kit streak: x\(normalizedCurrentStreak) (best x\(normalizedBestStreak))."
        }
        if normalizedBestStreak > 0 {
            return "Cadence kit streak: reset (best x\(normalizedBestStreak)). Restart `Run Fame Next Move + Cadence Execution Kit`."
        }
        return "Cadence kit streak: not started. Run `Run Fame Next Move + Cadence Execution Kit`."
    }

    nonisolated static func cadenceExecutionKitCommandMenuMomentumTitle(
        currentStreak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak > 0 {
            let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedCurrentStreak)
            let remainingRuns = max(1, nextMilestone - normalizedCurrentStreak)
            let runWord = remainingRuns == 1 ? "run" : "runs"
            return "Cadence Momentum: x\(normalizedCurrentStreak) · Best x\(normalizedBestStreak) · Next x\(nextMilestone) (\(remainingRuns) \(runWord))"
        }

        if normalizedBestStreak > 0 {
            let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: 0)
            return "Cadence Momentum: reset · Best x\(normalizedBestStreak) · Next x\(nextMilestone)"
        }
        return "Cadence Momentum: not started · Next x3"
    }

    nonisolated static func cadenceExecutionKitMomentumBriefActionSubtitle(
        currentStreak: Int,
        bestStreak: Int,
        nextMoveLabel: String
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak > 0 {
            return "Streak x\(normalizedCurrentStreak) · Next \(nextMoveLabel) · save + copy brief"
        }
        if normalizedBestStreak > 0 {
            return "Streak reset (best x\(normalizedBestStreak)) · Next \(nextMoveLabel) · rebuild now"
        }
        return "No streak yet · Next \(nextMoveLabel) · start cadence now"
    }

    nonisolated static func cadenceExecutionKitMomentumShareLineActionSubtitle(
        momentumTitle: String,
        nextMoveLabel: String
    ) -> String {
        let normalizedMomentumTitle = momentumTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNextMoveLabel = nextMoveLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let momentumFragment = normalizedMomentumTitle.isEmpty
            ? "Cadence momentum warming up"
            : normalizedMomentumTitle
        let nextMoveFragment = normalizedNextMoveLabel.isEmpty
            ? "next move"
            : normalizedNextMoveLabel
        return "\(momentumFragment) · Next \(nextMoveFragment) · copy share line"
    }

    nonisolated static func cadenceExecutionKitMomentumSharePackActionSubtitle(
        momentumTitle: String,
        nextMoveLabel: String
    ) -> String {
        let normalizedMomentumTitle = momentumTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNextMoveLabel = nextMoveLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let momentumFragment = normalizedMomentumTitle.isEmpty
            ? "Cadence momentum warming up"
            : normalizedMomentumTitle
        let nextMoveFragment = normalizedNextMoveLabel.isEmpty
            ? "next move"
            : normalizedNextMoveLabel
        return "\(momentumFragment) · Next \(nextMoveFragment) · short + standard + hype"
    }

    nonisolated static func cadenceExecutionKitAutopilotLoopTitle(
        currentStreak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        if normalizedCurrentStreak > 0 {
            return "Run Cadence Autopilot Loop (x\(normalizedCurrentStreak))"
        }
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        if normalizedBestStreak > 0 {
            return "Run Cadence Recovery Loop"
        }
        return "Start Cadence Autopilot Loop"
    }

    nonisolated static func cadenceExecutionKitAutopilotLoopSubtitle(
        currentStreak: Int,
        bestStreak: Int,
        nextMoveLabel: String
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak > 0 {
            let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedCurrentStreak)
            let remainingRuns = max(1, nextMilestone - normalizedCurrentStreak)
            let runWord = remainingRuns == 1 ? "run" : "runs"
            return "Next \(nextMoveLabel) · push to x\(nextMilestone) in \(remainingRuns) \(runWord)"
        }
        if normalizedBestStreak > 0 {
            return "Best x\(normalizedBestStreak) saved · restart with \(nextMoveLabel) + execution kit"
        }
        return "Run \(nextMoveLabel) + cadence execution kit + first post now"
    }

    nonisolated static func cadenceExecutionKitCelebrationDemoActionSubtitle(
        currentStreak: Int,
        bestStreak: Int,
        currentIntensityTitle: String
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak > 0 {
            let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedCurrentStreak)
            return "Streak x\(normalizedCurrentStreak) · current \(currentIntensityTitle) · preview Calm/Balanced/Epic before x\(nextMilestone)"
        }
        if normalizedBestStreak > 0 {
            return "Streak reset (best x\(normalizedBestStreak)) · current \(currentIntensityTitle) · preview Calm/Balanced/Epic"
        }
        return "No streak yet · current \(currentIntensityTitle) · preview Calm/Balanced/Epic"
    }

    nonisolated static func cadenceExecutionKitCommandMomentumBadgeTitle(
        currentStreak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        if normalizedCurrentStreak > 0 {
            return "x\(normalizedCurrentStreak)"
        }
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        if normalizedBestStreak > 0 {
            return "Reset"
        }
        return "Ready"
    }

    nonisolated static func cadenceExecutionKitCommandMomentumSymbolName(
        currentStreak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        if normalizedCurrentStreak >= 10 {
            return "trophy.fill"
        }
        if normalizedCurrentStreak >= 5 {
            return "rocket.fill"
        }
        if normalizedCurrentStreak > 0 {
            return "bolt.fill"
        }
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        if normalizedBestStreak > 0 {
            return "arrow.counterclockwise.circle"
        }
        return "bolt.badge.clock"
    }

    nonisolated static func cadenceExecutionKitMomentumPulseStatusTitle(
        signal: FamePulseAlertSignal?
    ) -> String {
        guard let signal else {
            return "Pulse risk: Unknown · Run `Run Daily Fame Scorecard`."
        }
        return "Pulse risk: \(signal.riskLevel) · \(signal.mustShipAlert) · Snapshot gap \(signal.daysSinceLastSnapshot)d"
    }

    nonisolated static func cadenceExecutionKitMomentumLaunchStatusTitle(
        _ launchStatus: FameLaunchCountdownStatus?
    ) -> String {
        guard let launchStatus else {
            return "Launch status: Unknown · Run `Run Fame Launch Day Script`, then `Run Fame Launch Countdown`."
        }
        return "Launch status: \(launchStatus.countdown) · \(fameLaunchCountdownUrgency(launchStatus)) · Next \(launchStatus.nextAction)"
    }

    nonisolated static func cadenceExecutionKitMomentumScorecardStatusTitle(
        _ scorecard: FameDailyScorecardState
    ) -> String {
        guard scorecard.riskLevel != "Unknown" else {
            return "Daily scorecard: Unknown · Run `Run Daily Fame Scorecard`."
        }

        let delta = scorecard.scoreDelta
        let deltaPrefix = delta >= 0 ? "+" : ""
        return "Daily scorecard: \(scorecard.riskLevel) (Δ\(deltaPrefix)\(delta)) · Next \(scorecard.nextActionTitle)"
    }

    nonisolated static func launchRecoveryHotKeyReadinessHistory(
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey,
        limit: Int = 24
    ) -> [CommandPaletteTopPicks.LaunchRecoveryHotKeyReadinessState] {
        let normalizedLimit = max(1, limit)
        let tokens = defaults.stringArray(forKey: historyKey) ?? []
        return Array(tokens.suffix(normalizedLimit)).compactMap { token in
            switch token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "direct":
                return .direct
            case "reroute":
                return .reroute
            case "standby":
                return .standby
            default:
                return nil
            }
        }
    }

    nonisolated static func launchRecoveryHotKeyWinMeterSnapshot(
        defaults: UserDefaults = .standard,
        sampleLimit: Int = 8
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter? {
        let readinessHistory = launchRecoveryHotKeyReadinessHistory(
            defaults: defaults,
            limit: max(sampleLimit, 2)
        )
        let directStreak = max(
            0,
            defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyDirectStreakKey)
        )
        let bestDirectStreak = max(
            directStreak,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyBestDirectStreakKey)
            )
        )
        return CommandPaletteTopPicks.launchRecoveryHotKeyWinMeter(
            readinessHistory: readinessHistory,
            directStreak: directStreak,
            bestDirectStreak: bestDirectStreak,
            sampleLimit: sampleLimit
        )
    }

    nonisolated static func launchRecoveryHotKeyMomentumDeltaSnapshot(
        defaults: UserDefaults = .standard,
        sampleWindow: Int = 8
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyWinDelta? {
        let normalizedWindow = max(2, sampleWindow)
        let readinessHistory = launchRecoveryHotKeyReadinessHistory(
            defaults: defaults,
            limit: normalizedWindow * 2
        )
        return CommandPaletteTopPicks.launchRecoveryHotKeyWinDelta(
            readinessHistory: readinessHistory,
            sampleWindow: normalizedWindow
        )
    }

    nonisolated static func cadenceExecutionKitMomentumPriorityMove(
        currentStreak: Int,
        bestStreak: Int,
        nextMoveLabel: String
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak >= 10 {
            return "Breakout streak x\(normalizedCurrentStreak). Run `Run Fame Next Move + Cadence Execution Kit`, then ship the first cadence step now."
        }
        if normalizedCurrentStreak >= 5 {
            return "Compounding streak x\(normalizedCurrentStreak). Keep it alive with `Run Fame Next Move + Cadence Execution Kit` before switching tracks."
        }
        if normalizedCurrentStreak > 0 {
            let nextMilestone = cadenceExecutionKitCommandNextMilestoneTarget(after: normalizedCurrentStreak)
            return "Build streak x\(normalizedCurrentStreak) toward x\(nextMilestone). Run `Run Fame Next Move + Cadence Execution Kit` now (\(nextMoveLabel))."
        }
        if normalizedBestStreak > 0 {
            return "Streak reset (best x\(normalizedBestStreak)). Rebuild with one `Run Fame Next Move + Cadence Execution Kit` run right now."
        }
        return "No cadence streak yet. Start with `Run Fame Next Move + Cadence Execution Kit`, then copy the cadence kit and publish the first post."
    }

    nonisolated static func cadenceExecutionKitMomentumShareLine(
        momentumTitle: String,
        nextMoveLabel: String,
        recoveryWinsTitle: String,
        momentumDeltaTitle: String
    ) -> String {
        let normalizedMomentumTitle = momentumTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNextMoveLabel = nextMoveLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRecoveryWinsTitle = recoveryWinsTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMomentumDeltaTitle = momentumDeltaTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        let momentumFragment = normalizedMomentumTitle.isEmpty
            ? "Cadence momentum warming up"
            : normalizedMomentumTitle
        let recoveryWinsFragment = normalizedRecoveryWinsTitle.isEmpty
            ? "Recovery wins warming up"
            : normalizedRecoveryWinsTitle
        let momentumDeltaFragment = normalizedMomentumDeltaTitle.isEmpty
            ? "Fame momentum delta warming up"
            : normalizedMomentumDeltaTitle
        let nextMoveFragment = normalizedNextMoveLabel.isEmpty ? "next move" : normalizedNextMoveLabel

        return "Fame momentum: \(momentumFragment) · \(recoveryWinsFragment) · \(momentumDeltaFragment) · Next \(nextMoveFragment)."
    }

    nonisolated static func cadenceExecutionKitMomentumShareLineFromBrief(
        _ momentumBriefMarkdown: String
    ) -> String? {
        let lines = momentumBriefMarkdown
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        if let shareSectionIndex = lines.firstIndex(where: { $0 == "## Share Line" }) {
            let tailLines = lines.suffix(from: lines.index(after: shareSectionIndex))
            for line in tailLines {
                if line.hasPrefix("## ") {
                    break
                }
                guard line.hasPrefix("- ") else {
                    continue
                }
                let candidate = String(line.dropFirst(2))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.hasPrefix("Fame momentum:"), !candidate.isEmpty {
                    return candidate
                }
            }
        }

        for line in lines {
            let normalizedLine: String
            if line.hasPrefix("- ") {
                normalizedLine = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                normalizedLine = line
            }
            if normalizedLine.hasPrefix("Fame momentum:"), !normalizedLine.isEmpty {
                return normalizedLine
            }
        }

        return nil
    }

    nonisolated static func latestCadenceMomentumShareLineCopyOutcome(
        momentumBriefMarkdown: String?
    ) -> CadenceMomentumShareLineCopyOutcome {
        guard let momentumBriefMarkdown else {
            return .missingBrief
        }
        guard let shareLine = cadenceExecutionKitMomentumShareLineFromBrief(momentumBriefMarkdown) else {
            return .missingShareLine
        }
        return .ready(shareLine: shareLine)
    }

    nonisolated static func cadenceExecutionKitMomentumSharePack(
        momentumTitle: String,
        nextMoveLabel: String,
        recoveryWinsTitle: String,
        momentumDeltaTitle: String,
        shareLine: String? = nil,
        handoffDrafts: FameNextMoveHandoffDrafts? = nil,
        preferredCadenceChannel: NextMoveDraftChannel? = nil
    ) -> CadenceMomentumSharePack {
        let normalizedMomentumTitle = momentumTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNextMoveLabel = nextMoveLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRecoveryWinsTitle = recoveryWinsTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMomentumDeltaTitle = momentumDeltaTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedShareLine = shareLine?.trimmingCharacters(in: .whitespacesAndNewlines)

        let momentumFragment = normalizedMomentumTitle.isEmpty
            ? "Cadence momentum warming up"
            : normalizedMomentumTitle
        let recoveryWinsFragment = normalizedRecoveryWinsTitle.isEmpty
            ? "Recovery wins warming up"
            : normalizedRecoveryWinsTitle
        let momentumDeltaFragment = normalizedMomentumDeltaTitle.isEmpty
            ? "Fame momentum delta warming up"
            : normalizedMomentumDeltaTitle
        let nextMoveFragment = normalizedNextMoveLabel.isEmpty
            ? "next move"
            : normalizedNextMoveLabel
        let standardLine: String
        if let normalizedShareLine, !normalizedShareLine.isEmpty {
            standardLine = normalizedShareLine
        } else {
            standardLine = cadenceExecutionKitMomentumShareLine(
                momentumTitle: momentumFragment,
                nextMoveLabel: nextMoveFragment,
                recoveryWinsTitle: recoveryWinsFragment,
                momentumDeltaTitle: momentumDeltaFragment
            )
        }

        let shortLine = "Fame snapshot: \(momentumFragment) · \(momentumDeltaFragment) · Next \(nextMoveFragment)."
        let hypeLine = "Fame breakout mode: \(momentumFragment) — \(recoveryWinsFragment) — \(momentumDeltaFragment). Shipping \(nextMoveFragment) now."
        let channelBlocks: [CadenceMomentumSharePackChannelBlock]
        let checklistComment: String?
        let bestChannelTitle: String?
        let bestChannelReason: String?
        if let handoffDrafts {
            let draftByChannel: [NextMoveDraftChannel: String] = [
                .x: handoffDrafts.xDraft,
                .bluesky: handoffDrafts.blueskyDraft,
                .linkedIn: handoffDrafts.linkedInDraft
            ]
            let followupByChannel: [NextMoveDraftChannel: String] = [
                .x: shortLine,
                .bluesky: standardLine,
                .linkedIn: hypeLine
            ]
            let defaultOrder: [NextMoveDraftChannel] = [.x, .bluesky, .linkedIn]
            let orderedChannels: [NextMoveDraftChannel]
            if let preferredCadenceChannel {
                orderedChannels = [preferredCadenceChannel] + defaultOrder.filter { $0 != preferredCadenceChannel }
            } else {
                orderedChannels = defaultOrder
            }
            channelBlocks = orderedChannels.compactMap { channel in
                guard let primary = draftByChannel[channel],
                      let followup = followupByChannel[channel] else {
                    return nil
                }
                return CadenceMomentumSharePackChannelBlock(
                    channelTitle: nextMoveDraftChannelTitle(channel),
                    primary: primary,
                    followup: followup
                )
            }
            checklistComment = handoffDrafts.checklistCommentDraft
            if let preferredCadenceChannel {
                let preferredChannelTitle = nextMoveDraftChannelTitle(preferredCadenceChannel)
                bestChannelTitle = preferredChannelTitle
                bestChannelReason = "Cadence step starts on \(preferredChannelTitle), so this channel is ranked first for the next publish window."
            } else {
                bestChannelTitle = nil
                bestChannelReason = nil
            }
        } else {
            channelBlocks = []
            checklistComment = nil
            bestChannelTitle = nil
            bestChannelReason = nil
        }

        return CadenceMomentumSharePack(
            shortLine: shortLine,
            standardLine: standardLine,
            hypeLine: hypeLine,
            channelBlocks: channelBlocks,
            checklistComment: checklistComment,
            bestChannelTitle: bestChannelTitle,
            bestChannelReason: bestChannelReason
        )
    }

    nonisolated static func cadenceExecutionKitShareLineArtifactMarkdown(
        generatedAt: String,
        shareLine: String,
        source: String
    ) -> String {
        let normalizedShareLine = shareLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let shareLineValue = normalizedShareLine.isEmpty
            ? "Fame momentum: Cadence momentum warming up · Recovery wins warming up · Fame momentum delta warming up · Next next move."
            : normalizedShareLine
        let sourceValue = normalizedSource.isEmpty ? "Live momentum snapshot" : normalizedSource
        return """
        # Fluid Reader Cadence Share Line

        - Generated at: \(generatedAt)
        - Source: \(sourceValue)

        ## Share Line
        - \(shareLineValue)

        ## Usage
        - Paste this line into launch updates, standups, and social proof check-ins.
        - Refresh with `Copy Cadence Share Line` whenever momentum changes.
        """
    }

    nonisolated static func cadenceExecutionKitSharePackArtifactMarkdown(
        generatedAt: String,
        source: String,
        pack: CadenceMomentumSharePack
    ) -> String {
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceValue = normalizedSource.isEmpty ? "Live momentum snapshot" : normalizedSource
        let normalizedBestChannelTitle = pack.bestChannelTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedBestChannelReason = pack.bestChannelReason?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let bestChannelSection: String
        if let bestChannelTitle = normalizedBestChannelTitle, !bestChannelTitle.isEmpty {
            let reasonLine: String
            if let normalizedBestChannelReason, !normalizedBestChannelReason.isEmpty {
                reasonLine = normalizedBestChannelReason
            } else {
                reasonLine = "This channel has the strongest immediate cadence signal."
            }
            let bestChannelDraftLine: String
            if let bestChannelDraft = pack.channelBlocks
                .first(where: { block in
                    block.channelTitle.caseInsensitiveCompare(bestChannelTitle) == .orderedSame
                })?
                .primary
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !bestChannelDraft.isEmpty {
                bestChannelDraftLine = "\n- Start draft: \(bestChannelDraft)"
            } else {
                bestChannelDraftLine = ""
            }
            bestChannelSection = """

            ## Best Channel Now
            - \(bestChannelTitle): \(reasonLine)\(bestChannelDraftLine)
            """
        } else {
            bestChannelSection = ""
        }
        let channelBlocksText = pack.channelBlocks.map { block in
            """
            ### \(block.channelTitle)
            - Primary: \(block.primary)
            - Follow-up: \(block.followup)
            """
        }.joined(separator: "\n\n")
        let normalizedChecklistComment = pack.checklistComment?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let checklistSection = if let normalizedChecklistComment, !normalizedChecklistComment.isEmpty {
            """
            ### Checklist Comment
            - \(normalizedChecklistComment)
            """
        } else {
            ""
        }
        let postReadySection: String
        if channelBlocksText.isEmpty && checklistSection.isEmpty {
            postReadySection = ""
        } else if checklistSection.isEmpty {
            postReadySection = """

            ## Post-Ready Blocks
            \(channelBlocksText)
            """
        } else if channelBlocksText.isEmpty {
            postReadySection = """

            ## Post-Ready Blocks
            \(checklistSection)
            """
        } else {
            postReadySection = """

            ## Post-Ready Blocks
            \(channelBlocksText)

            \(checklistSection)
            """
        }
        return """
        # Fluid Reader Cadence Share Pack

        - Generated at: \(generatedAt)
        - Source: \(sourceValue)

        ## Share Variants
        - Short: \(pack.shortLine)
        - Standard: \(pack.standardLine)
        - Hype: \(pack.hypeLine)
        \(postReadySection)
        \(bestChannelSection)

        ## Usage
        - Use Short for fast check-ins and status taps.
        - Use Standard for standups and launch updates.
        - Use Hype for social proof posts and shoutouts.
        - Post-Ready blocks pair each channel draft with a matching follow-up line.
        - Refresh with `Copy Cadence Share Pack` when momentum shifts.
        """
    }

    nonisolated static func cadenceExecutionKitMomentumBriefMarkdown(
        generatedAt: String,
        momentumTitle: String,
        streakStatusTitle: String,
        nextMoveLabel: String,
        pulseStatusTitle: String,
        launchStatusTitle: String,
        scorecardStatusTitle: String,
        priorityMove: String,
        recoveryWinsTitle: String? = nil,
        recoveryWinsSubtitle: String? = nil,
        momentumDeltaTitle: String? = nil,
        momentumDeltaSubtitle: String? = nil,
        shareLine: String? = nil
    ) -> String {
        let normalizedRecoveryWinsTitle = recoveryWinsTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRecoveryWinsSubtitle = recoveryWinsSubtitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let recoveryWinsTitleLine: String
        if let normalizedRecoveryWinsTitle, !normalizedRecoveryWinsTitle.isEmpty {
            recoveryWinsTitleLine = normalizedRecoveryWinsTitle
        } else {
            recoveryWinsTitleLine = "Recovery wins: warming up."
        }
        let recoveryWinsSubtitleLine: String
        if let normalizedRecoveryWinsSubtitle, !normalizedRecoveryWinsSubtitle.isEmpty {
            recoveryWinsSubtitleLine = normalizedRecoveryWinsSubtitle
        } else {
            recoveryWinsSubtitleLine = "Launch recovery wins appear after a few palette opens. Keep using ⌥⇧L and the top recovery action."
        }
        let normalizedMomentumDeltaTitle = momentumDeltaTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMomentumDeltaSubtitle = momentumDeltaSubtitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let momentumDeltaTitleLine: String
        if let normalizedMomentumDeltaTitle, !normalizedMomentumDeltaTitle.isEmpty {
            momentumDeltaTitleLine = normalizedMomentumDeltaTitle
        } else {
            momentumDeltaTitleLine = "Fame momentum delta: warming up."
        }
        let momentumDeltaSubtitleLine: String
        if let normalizedMomentumDeltaSubtitle, !normalizedMomentumDeltaSubtitle.isEmpty {
            momentumDeltaSubtitleLine = normalizedMomentumDeltaSubtitle
        } else {
            momentumDeltaSubtitleLine = "Need two recovery windows before delta can be computed. Keep using launch recovery to build trend evidence."
        }
        let normalizedShareLine = shareLine?.trimmingCharacters(in: .whitespacesAndNewlines)
        let shareLineText: String
        if let normalizedShareLine, !normalizedShareLine.isEmpty {
            shareLineText = normalizedShareLine
        } else {
            shareLineText = cadenceExecutionKitMomentumShareLine(
                momentumTitle: momentumTitle,
                nextMoveLabel: nextMoveLabel,
                recoveryWinsTitle: recoveryWinsTitleLine,
                momentumDeltaTitle: momentumDeltaTitleLine
            )
        }
        return """
        # Fluid Reader Cadence Momentum Brief

        - Generated at: \(generatedAt)
        - Cadence momentum: \(momentumTitle)
        - Next move recommendation: \(nextMoveLabel)

        ## Momentum Status
        - \(streakStatusTitle)
        - \(pulseStatusTitle)
        - \(launchStatusTitle)
        - \(scorecardStatusTitle)

        ## Recovery Wins
        - \(recoveryWinsTitleLine)
        - \(recoveryWinsSubtitleLine)

        ## Fame Momentum Delta
        - \(momentumDeltaTitleLine)
        - \(momentumDeltaSubtitleLine)

        ## Share Line
        - \(shareLineText)
        - Paste this into launch updates, standups, and social proof checkpoints.

        ## Priority Move
        - \(priorityMove)

        ## Quick Commands
        - \(readerStatusShortcutMenuHintLine())
        - `Run Cadence Autopilot Loop`
        - `Run Fame Next Move + Cadence Execution Kit`
        - `Copy Cadence Execution Kit`
        - `Copy Cadence Share Pack`
        - `Run Cadence Momentum Brief`
        - `Run Fame Launch Control Brief`
        - `Run Daily Fame Scorecard`
        - `Open Latest Cadence Momentum Brief`
        - `Open Latest Cadence Share Line`
        - `Open Latest Cadence Share Pack`
        """
    }

    nonisolated static func launchControlHealthPulseCooldownLabel(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        if seconds % 60 == 0 {
            return "\(minutes)m"
        }
        return String(format: "%.1fm", Double(seconds) / 60.0)
    }

    nonisolated static func launchControlHealthPulseTransitionLabel(token: String) -> String {
        let parts = token.components(separatedBy: "-to-")
        guard parts.count == 2 else {
            return token
        }
        let from = parts[0].capitalized
        let to = parts[1].capitalized
        return "\(from) -> \(to)"
    }

    nonisolated static func launchControlHealthPulseStatusTitle(
        alertsEnabled: Bool,
        pulseEnabled: Bool,
        cooldownSeconds: Int,
        lastPulseAt: Date?,
        lastPulseToken: String?,
        now: Date
    ) -> String {
        guard alertsEnabled else {
            return "Launch Health Pulse: Muted (launch threshold alerts off)"
        }
        guard pulseEnabled else {
            return "Launch Health Pulse: Off"
        }
        guard cooldownSeconds > 0 else {
            return "Launch Health Pulse: On (cooldown off; every eligible transition)."
        }

        let cooldown = TimeInterval(cooldownSeconds)
        if let lastPulseAt,
           let lastPulseToken {
            let elapsed = now.timeIntervalSince(lastPulseAt)
            if elapsed < cooldown {
                let remaining = max(1, Int(ceil(cooldown - elapsed)))
                return "Launch Health Pulse: Suppressed \(remaining)s for repeat \(launchControlHealthPulseTransitionLabel(token: lastPulseToken))."
            }
        }

        return "Launch Health Pulse: Ready (repeat cooldown \(launchControlHealthPulseCooldownLabel(seconds: cooldownSeconds)))."
    }

    nonisolated static func launchControlHealthPulseMenuStatusTitle(
        alertsEnabled: Bool,
        pulseEnabled: Bool,
        cooldownSeconds: Int,
        lastPulseAt: Date?,
        lastPulseToken: String?,
        now: Date
    ) -> String {
        guard alertsEnabled else {
            return "Pulse muted"
        }
        guard pulseEnabled else {
            return "Pulse off"
        }
        guard cooldownSeconds > 0 else {
            return "Pulse every transition"
        }

        let cooldown = TimeInterval(cooldownSeconds)
        if let lastPulseAt,
           let lastPulseToken {
            let elapsed = now.timeIntervalSince(lastPulseAt)
            if elapsed < cooldown {
                let remaining = max(1, Int(ceil(cooldown - elapsed)))
                return "Pulse suppressed \(remaining)s (\(launchControlHealthPulseTransitionLabel(token: lastPulseToken)))"
            }
        }

        return "Pulse ready (\(launchControlHealthPulseCooldownLabel(seconds: cooldownSeconds)))"
    }

    nonisolated static func launchControlHealthTransitionCountsTitle(
        watchToRiskCount: Int,
        riskToReadyCount: Int,
        averageDeltaTitle: String? = nil,
        momentumStatusTitle: String? = nil,
        pressurePersistenceStatusTitle: String? = nil
    ) -> String {
        let trendTitle = launchControlHealthTransitionTrendTitle(
            watchToRiskCount: watchToRiskCount,
            riskToReadyCount: riskToReadyCount
        )
        let watchToRiskCount = max(0, watchToRiskCount)
        let riskToReadyCount = max(0, riskToReadyCount)
        let averageDeltaSuffix = averageDeltaTitle.map { " · \($0)" } ?? ""
        let momentumSuffix = momentumStatusTitle.map { " · \($0)" } ?? ""
        let persistenceSuffix = pressurePersistenceStatusTitle.map { " · \($0)" } ?? ""
        return "Launch Health Transitions Today: Watch -> Risk \(watchToRiskCount) · Risk -> Ready \(riskToReadyCount) · Trend \(trendTitle)\(averageDeltaSuffix)\(momentumSuffix)\(persistenceSuffix)"
    }

    nonisolated static func launchControlHealthTransitionCountsMenuStatusTitle(
        watchToRiskCount: Int,
        riskToReadyCount: Int,
        averageDeltaTitle: String? = nil,
        momentumStatusTitle: String? = nil,
        pressurePersistenceStatusTitle: String? = nil
    ) -> String {
        let trendTitle = launchControlHealthTransitionTrendTitle(
            watchToRiskCount: watchToRiskCount,
            riskToReadyCount: riskToReadyCount
        )
        let watchToRiskCount = max(0, watchToRiskCount)
        let riskToReadyCount = max(0, riskToReadyCount)
        let averageDeltaSuffix = averageDeltaTitle.map { " · \($0)" } ?? ""
        let momentumSuffix = momentumStatusTitle.map { " · \($0)" } ?? ""
        let persistenceSuffix = pressurePersistenceStatusTitle.map { " · \($0)" } ?? ""
        return "Today W->R \(watchToRiskCount) · R->Ready \(riskToReadyCount) · \(trendTitle)\(averageDeltaSuffix)\(momentumSuffix)\(persistenceSuffix)"
    }

    nonisolated static func launchControlHealthTransitionTrendTitle(
        watchToRiskCount: Int,
        riskToReadyCount: Int
    ) -> String {
        let watchToRiskCount = max(0, watchToRiskCount)
        let riskToReadyCount = max(0, riskToReadyCount)
        if riskToReadyCount > watchToRiskCount {
            return "Improving ↑"
        }
        if riskToReadyCount < watchToRiskCount {
            return "Worsening ↓"
        }
        return "Steady →"
    }

    nonisolated static func launchControlHealthTransitionAverage(
        historyWindow: [LaunchControlHealthTransitionHistoryDay]
    ) -> LaunchControlHealthTransitionAverage {
        guard !historyWindow.isEmpty else {
            return LaunchControlHealthTransitionAverage(
                watchToRiskAverage: 0,
                riskToReadyAverage: 0
            )
        }

        let dayCount = Double(historyWindow.count)
        let watchToRiskTotal = historyWindow.reduce(0) { partialResult, day in
            partialResult + max(0, day.watchToRiskCount)
        }
        let riskToReadyTotal = historyWindow.reduce(0) { partialResult, day in
            partialResult + max(0, day.riskToReadyCount)
        }
        return LaunchControlHealthTransitionAverage(
            watchToRiskAverage: Double(watchToRiskTotal) / dayCount,
            riskToReadyAverage: Double(riskToReadyTotal) / dayCount
        )
    }

    nonisolated static func launchControlHealthTransitionAverageDeltaTitle(
        watchToRiskCount: Int,
        riskToReadyCount: Int,
        historyWindow: [LaunchControlHealthTransitionHistoryDay]
    ) -> String {
        let average = launchControlHealthTransitionAverage(historyWindow: historyWindow)
        let watchToRiskDelta = launchControlHealthTransitionAverageDeltaLabel(
            currentCount: watchToRiskCount,
            averageCount: average.watchToRiskAverage
        )
        let riskToReadyDelta = launchControlHealthTransitionAverageDeltaLabel(
            currentCount: riskToReadyCount,
            averageCount: average.riskToReadyAverage
        )
        return "Vs 7d avg W->R \(watchToRiskDelta) · R->Ready \(riskToReadyDelta)"
    }

    nonisolated static func launchControlHealthTransitionAverageDeltaLabel(
        currentCount: Int,
        averageCount: Double
    ) -> String {
        let delta = launchControlHealthTransitionAverageDelta(
            currentCount: currentCount,
            averageCount: averageCount
        )
        let normalizedDelta = abs(delta) < 0.05 ? 0 : delta
        let sign = normalizedDelta > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", normalizedDelta))"
    }

    nonisolated static func launchControlHealthTransitionAverageDelta(
        currentCount: Int,
        averageCount: Double
    ) -> Double {
        Double(max(0, currentCount)) - max(0, averageCount)
    }

    nonisolated static func launchControlHealthMomentumSignal(
        watchToRiskCount: Int,
        riskToReadyCount: Int,
        historyWindow: [LaunchControlHealthTransitionHistoryDay],
        minimumDelta: Double = 1.0
    ) -> LaunchControlHealthMomentumSignal {
        let average = launchControlHealthTransitionAverage(historyWindow: historyWindow)
        let watchToRiskDelta = launchControlHealthTransitionAverageDelta(
            currentCount: watchToRiskCount,
            averageCount: average.watchToRiskAverage
        )
        let riskToReadyDelta = launchControlHealthTransitionAverageDelta(
            currentCount: riskToReadyCount,
            averageCount: average.riskToReadyAverage
        )
        let normalizedMinimumDelta = max(0.1, minimumDelta)
        let isRiskPressure = watchToRiskDelta >= normalizedMinimumDelta && riskToReadyDelta <= 0.25
        let isRecoveryMomentum = riskToReadyDelta >= normalizedMinimumDelta && watchToRiskDelta <= 0.25

        switch (isRiskPressure, isRecoveryMomentum) {
        case (true, false):
            return .riskPressure
        case (false, true):
            return .recoveryMomentum
        case (true, true):
            return watchToRiskDelta > riskToReadyDelta ? .riskPressure : .recoveryMomentum
        case (false, false):
            return .stable
        }
    }

    nonisolated static func launchControlHealthMomentumStatusTitle(
        _ signal: LaunchControlHealthMomentumSignal
    ) -> String {
        switch signal {
        case .stable:
            return "Signal Baseline →"
        case .riskPressure:
            return "Signal Pressure ↑"
        case .recoveryMomentum:
            return "Signal Recovery ↑"
        }
    }

    nonisolated static func launchControlHealthPressureStreakDays(
        historyWindow: [LaunchControlHealthTransitionHistoryDay]
    ) -> Int {
        guard !historyWindow.isEmpty else { return 0 }
        var streakDays = 0
        for day in historyWindow.reversed() {
            let watchToRiskCount = max(0, day.watchToRiskCount)
            let riskToReadyCount = max(0, day.riskToReadyCount)
            guard watchToRiskCount > 0,
                  watchToRiskCount > riskToReadyCount else {
                break
            }
            streakDays += 1
        }
        return streakDays
    }

    nonisolated static func launchControlHealthPressurePersistenceStatusTitle(
        streakDays: Int,
        minimumDays: Int = 2
    ) -> String? {
        let normalizedMinimumDays = max(2, minimumDays)
        let normalizedStreakDays = max(0, streakDays)
        guard normalizedStreakDays >= normalizedMinimumDays else { return nil }
        return "Pressure streak \(normalizedStreakDays)d"
    }

    nonisolated static func shouldAutoRunLaunchRescueBurstForPressurePersistence(
        isEnabled: Bool = AppDefaults.fameLaunchHealthPressureAutoRescueEnabled,
        launchStatus: FameLaunchCountdownStatus?,
        momentumSignal: LaunchControlHealthMomentumSignal,
        pressureStreakDays: Int,
        lastAutoRunAt: Date?,
        now: Date = Date(),
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameLaunchHealthPressureAutoRescueCooldownHours * 60 * 60
        ),
        minimumStreakDays: Int = 2
    ) -> Bool {
        guard isEnabled else { return false }
        guard let launchStatus else { return false }
        guard momentumSignal == .riskPressure else { return false }
        let healthBand = launchControlHealthBand(launchStatus: launchStatus)
        guard healthBand == .watch || healthBand == .risk else { return false }
        let normalizedMinimumStreakDays = max(2, minimumStreakDays)
        guard pressureStreakDays >= normalizedMinimumStreakDays else { return false }
        guard cooldown > 0 else { return true }
        guard let lastAutoRunAt else { return true }
        return now.timeIntervalSince(lastAutoRunAt) >= cooldown
    }

    nonisolated static func launchControlHealthActionCommandID(
        launchStatus: FameLaunchCountdownStatus?,
        momentumSignal: LaunchControlHealthMomentumSignal = .stable
    ) -> String {
        let healthBand = launchControlHealthBand(launchStatus: launchStatus)
        if healthBand == .watch,
           momentumSignal == .riskPressure {
            return "run-fame-launch-rescue-burst"
        }

        switch healthBand {
        case .ready:
            return "run-fame-launch-control-brief"
        case .risk:
            return "run-fame-launch-rescue-burst"
        case .watch:
            return "run-fame-launch-countdown"
        }
    }

    nonisolated static func launchControlHealthActionTitle(commandID: String) -> String {
        switch commandID {
        case "run-fame-launch-control-brief":
            return "Run Launch Control Brief"
        case "run-fame-launch-rescue-burst":
            return "Run Launch Rescue Burst"
        default:
            return "Run Fame Launch Countdown"
        }
    }

    nonisolated static func launchControlHealthMenuTitle(
        launchStatus: FameLaunchCountdownStatus?,
        statusTitle: String? = nil,
        commandID: String? = nil
    ) -> String {
        let healthScore = launchControlBriefHealthScore(launchStatus: launchStatus)
        let activeCommandID = commandID ?? launchControlHealthActionCommandID(
            launchStatus: launchStatus
        )
        let commandTitle = launchControlHealthActionTitle(commandID: activeCommandID)
        let statusSuffix = statusTitle.map { " · \($0)" } ?? ""
        guard let launchStatus else {
            return "Launch Health: \(healthScore)\(statusSuffix) · Click: \(commandTitle)"
        }
        return "Launch Health: \(healthScore) · \(launchStatus.countdown)\(statusSuffix) · Click: \(commandTitle)"
    }

    nonisolated static func fameLaunchHealthMenuTitle(
        launchStatus: FameLaunchCountdownStatus?,
        statusTitle: String? = nil,
        commandID: String? = nil,
        onboardingRecoveryHint: String? = nil
    ) -> String {
        let baseTitle = launchControlHealthMenuTitle(
            launchStatus: launchStatus,
            statusTitle: statusTitle,
            commandID: commandID
        )
        return fameMenuTitle(baseTitle: baseTitle, appendedHint: onboardingRecoveryHint)
    }

    nonisolated static func launchControlHealthCardTitle(
        launchStatus: FameLaunchCountdownStatus?
    ) -> String {
        guard let launchStatus else {
            return "Launch Health: Watch"
        }
        let healthScore = launchControlBriefHealthScore(launchStatus: launchStatus)
        return "Launch Health: \(healthScore) · \(launchStatus.countdown)"
    }

    nonisolated static func launchControlHealthCardSubtitle(
        launchStatus: FameLaunchCountdownStatus?,
        statusTitle: String? = nil,
        commandID: String? = nil
    ) -> String {
        let activeCommandID = commandID ?? launchControlHealthActionCommandID(
            launchStatus: launchStatus
        )
        let commandTitle = launchControlHealthActionTitle(commandID: activeCommandID)
        let statusSuffix = statusTitle.map { " · \($0)" } ?? ""
        guard let launchStatus else {
            return "Run `Run Fame Launch Day Script`, then `Run Fame Launch Countdown`."
        }
        return "\(fameLaunchCountdownUrgency(launchStatus)) · Next: \(launchStatus.nextAction)\(statusSuffix) · click: \(commandTitle)"
    }

    nonisolated private static func launchControlFollowupMomentumStatusFragment(
        _ followupMomentumBadge: String?
    ) -> String? {
        guard let followupMomentumBadge else { return nil }
        let cleanFollowupMomentumBadge = followupMomentumBadge
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanFollowupMomentumBadge.isEmpty else { return nil }
        return "Rescue \(cleanFollowupMomentumBadge)"
    }

    nonisolated static func launchControlStatusTitleWithFollowupMomentum(
        _ statusTitle: String,
        followupMomentumBadge: String?
    ) -> String {
        guard let followupMomentumFragment = launchControlFollowupMomentumStatusFragment(
            followupMomentumBadge
        ) else {
            return statusTitle
        }
        return "\(statusTitle) · \(followupMomentumFragment)"
    }

    nonisolated static func launchControlBriefActionSubtitle(
        _ baseSubtitle: String,
        followupMomentumBadge: String?,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            baseSubtitle,
            followupMomentumBadge: followupMomentumBadge,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueSnapshotActionSubtitle(
        _ baseSubtitle: String,
        followupMomentumBadge: String?,
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        var statusTitle = baseSubtitle
        if let routeBadge, !routeBadge.isEmpty {
            statusTitle += " · \(routeBadge)"
        }
        if let selfHealAttentionBadge, !selfHealAttentionBadge.isEmpty {
            statusTitle += " · \(selfHealAttentionBadge)"
        }
        return launchControlStatusTitleWithFollowupMomentum(
            statusTitle,
            followupMomentumBadge: followupMomentumBadge
        )
    }

    nonisolated static func launchRescueSnapshotMenuTitle(
        followupMomentumBadge: String?,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        launchControlBriefActionSubtitle(
            "Copy Launch Rescue Snapshot",
            followupMomentumBadge: followupMomentumBadge,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueSnapshotOpenMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Open Latest Launch Rescue Snapshot",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueSnapshotOpenMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            "Open latest launch rescue snapshot",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueSnapshotCopyMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            "Copy auto trigger + follow-up route decision + self-heal + scoreboard + coach + momentum",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchCountdownActionSubtitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            "Generate real-time launch step tracker",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchCountdownRunMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Run Fame Launch Countdown",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchCountdownRunMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchCountdownActionSubtitle(
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchCountdownOpenMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Open Latest Launch Countdown",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchCountdownOpenMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            "Open latest launch countdown",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueBurstOpenMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Open Latest Launch Rescue Burst",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueBurstOpenMenuStatusToolTip(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueSnapshotActionSubtitle(
            "Open latest launch rescue burst",
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchCountdownRunMissingScriptPrompt(
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        launchControlPromptWithLaunchRescueContext(
            "Run launch day script first.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchCountdownRunReadyPrompt(
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        launchControlPromptWithLaunchRescueContext(
            "Launch countdown ready.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchRescueBurstRunReadyPrompt(
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        launchControlPromptWithLaunchRescueContext(
            "Launch rescue burst ready.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchRescueBurstAutoSavedPrompt(
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        launchControlPromptWithLaunchRescueContext(
            "Launch rescue burst auto-saved. Open latest launch rescue burst.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchRescueAutoStatusDisabledPrompt(
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        launchControlPromptWithLaunchRescueContext(
            "Launch rescue auto-burst is off. Enable it in Settings.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func autoOpsBundleStatusDisabledPrompt(
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        launchControlPromptWithLaunchRescueContext(
            "Auto bundle is off. Enable it in Settings.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchRescueAutoStatusCoolingDownMissingPrompt(
        minutesRemaining: Int,
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        let normalizedMinutesRemaining = max(0, minutesRemaining)
        return launchControlPromptWithLaunchRescueContext(
            "Auto rescue cooling down (\(normalizedMinutesRemaining)m). Run launch rescue burst first.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchRescueAutoStatusCoolingDownOpenedPrompt(
        minutesRemaining: Int,
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String? = nil
    ) -> String {
        let normalizedMinutesRemaining = max(0, minutesRemaining)
        return launchControlPromptWithLaunchRescueContext(
            "Auto rescue cooling down (\(normalizedMinutesRemaining)m). Opened latest launch rescue burst.",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge,
            followupRouteDecisionTraceLine: followupRouteDecisionTraceLine
        )
    }

    nonisolated static func launchControlHealthCardSystemImage(
        launchStatus: FameLaunchCountdownStatus?
    ) -> String {
        switch launchControlHealthBand(launchStatus: launchStatus) {
        case .ready:
            return "checkmark.shield.fill"
        case .risk:
            return "exclamationmark.triangle.fill"
        case .watch:
            return "eye.circle.fill"
        }
    }

    nonisolated static func launchControlBriefGeneratedAt(
        _ now: Date,
        calendar: Calendar = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: now)
    }

    nonisolated static func launchRescueSnapshotMarkdown(
        autoTriggerSummary: String,
        autoTriggerAtSummary: String,
        autoFollowupSummary: String,
        autoFollowupAtSummary: String,
        followupRouteDecisionStatusTitle: String,
        autoSelfHealStatusTitle: String,
        followupScoreboardStatusTitle: String,
        followupCoachStatusTitle: String,
        followupMomentumStatusTitle: String
    ) -> String {
        """
        - Auto trigger: \(autoTriggerSummary)
        - Auto trigger time: \(autoTriggerAtSummary)
        - Auto follow-up: \(autoFollowupSummary)
        - Auto follow-up time: \(autoFollowupAtSummary)
        - \(followupRouteDecisionStatusTitle)
        - \(autoSelfHealStatusTitle)
        - \(followupScoreboardStatusTitle)
        - \(followupCoachStatusTitle)
        - \(followupMomentumStatusTitle)
        """
    }

    nonisolated static func launchControlBriefMarkdown(
        generatedAt: String,
        launchAlertTitle: String,
        launchAlertSubtitle: String,
        rescueAutoStatusTitle: String,
        rescueAutoTriggerStatusTitle: String = "Launch Rescue Auto Trigger: No auto trigger recorded yet.",
        rescueAutoTriggerAtStatusTitle: String = "Launch Rescue Auto Trigger Time: No auto trigger time recorded yet.",
        rescueAutoFollowupStatusTitle: String = "Launch Rescue Auto Follow-up: Stand by.",
        rescueAutoFollowupRouteDecisionStatusTitle: String = launchRescueAutoFollowupRouteDecisionStatusTitle(
            defaultCommandID: "run-fame-launch-control-brief",
            resolvedCommandID: "run-fame-launch-control-brief"
        ),
        rescueAutoSelfHealStatusTitle: String = "Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks.",
        rescueAutoFollowupScoreboardStatusTitle: String = "Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.",
        rescueAutoFollowupCoachStatusTitle: String = "Launch Rescue Follow-up Coach: Baseline mode · run follow-up to seed outcomes.",
        rescueAutoFollowupMomentumStatusTitle: String = "Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend.",
        thresholdAlertsStatusTitle: String,
        healthPulseStatusTitle: String,
        healthTransitionCountsTitle: String,
        snoozeReminderStatusTitle: String,
        nextMoveLabel: String,
        cadenceStreakStatusTitle: String,
        healthScore: String,
        priorityMove: String
    ) -> String {
        """
        # Fluid Reader Launch Control Brief

        - Generated at: \(generatedAt)
        - Next move recommendation: \(nextMoveLabel)
        - Launch control health score: \(healthScore)

        ## Live Status
        - \(launchAlertTitle)
        - \(launchAlertSubtitle)
        - \(rescueAutoStatusTitle)
        - \(rescueAutoTriggerStatusTitle)
        - \(rescueAutoTriggerAtStatusTitle)
        - \(rescueAutoFollowupStatusTitle)
        - \(rescueAutoFollowupRouteDecisionStatusTitle)
        - \(rescueAutoSelfHealStatusTitle)
        - \(rescueAutoFollowupScoreboardStatusTitle)
        - \(rescueAutoFollowupCoachStatusTitle)
        - \(rescueAutoFollowupMomentumStatusTitle)
        - \(thresholdAlertsStatusTitle)
        - \(healthPulseStatusTitle)
        - \(healthTransitionCountsTitle)
        - \(snoozeReminderStatusTitle)
        - \(cadenceStreakStatusTitle)

        ## Priority Move
        - \(priorityMove)

        ## Quick Commands
        - \(readerStatusShortcutMenuHintLine())
        - `Run Launch Control Hub`
        - `Run Fame Launch Control Brief`
        - `Run Fame Launch Countdown`
        - `Run Launch Rescue Burst`
        - `Run Launch Rescue Follow-up Now`
        - `Run Launch Rescue Snapshot`
        - `Run Fame Next Move + Copy Draft Pack`
        - `Copy Launch Rescue Snapshot`
        - `Open Launch Control Hub`
        - `Open Latest Launch Rescue Burst`
        - `Open Latest Launch Rescue Snapshot`
        - `Open Latest Launch Control Brief`
        """
    }

    nonisolated static func fameLaunchThresholdAlertsToggleTitle(
        _ enabled: Bool,
        snoozeMinutesRemaining: Int? = nil
    ) -> String {
        guard !enabled,
              let snoozeMinutesRemaining,
              snoozeMinutesRemaining > 0 else {
            return enabled ? "Launch Threshold Alerts: On" : "Launch Threshold Alerts: Muted"
        }
        return "Launch Threshold Alerts: Snoozed \(snoozeMinutesRemaining)m"
    }

    nonisolated static func fameLaunchThresholdAlertsToggleSubtitle(
        _ enabled: Bool,
        snoozeMinutesRemaining: Int? = nil
    ) -> String {
        enabled
            ? "Mute launch threshold HUD/flash alerts (badges stay on)"
            : {
                if let snoozeMinutesRemaining,
                   snoozeMinutesRemaining > 0 {
                    return "Snoozed \(snoozeMinutesRemaining)m left · unmute now or wait for auto-unmute"
                }
                return "Unmute launch threshold HUD/flash alerts"
            }()
    }

    nonisolated static func fameLaunchThresholdAlertsToggleSystemImage(
        _ enabled: Bool,
        snoozeMinutesRemaining: Int? = nil
    ) -> String {
        if enabled {
            return "bell.fill"
        }
        if let snoozeMinutesRemaining,
           snoozeMinutesRemaining > 0 {
            return "hourglass.circle.fill"
        }
        return "bell.slash.fill"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeTitle(minutes: Int) -> String {
        "Snooze Threshold Alerts (\(minutes)m)"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeSubtitle(
        minutes: Int,
        snoozeMinutesRemaining: Int?
    ) -> String {
        if let snoozeMinutesRemaining,
           snoozeMinutesRemaining > 0 {
            return "Extend snooze by \(minutes)m · \(snoozeMinutesRemaining)m currently left"
        }
        return "Mute launch threshold HUD/flash alerts for \(minutes)m, then auto-unmute"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeSystemImage() -> String {
        "hourglass.circle.fill"
    }

    nonisolated static func fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
        launchStatus: FameLaunchCountdownStatus?
    ) -> Int {
        guard let urgency = fameLaunchBadgeUrgency(launchStatus) else { return 30 }
        switch urgency {
        case .critical, .high:
            return 10
        case .hot, .live:
            return 30
        case .ready, .prep:
            return 60
        }
    }

    nonisolated static func fameLaunchThresholdAlertsRecommendedSnoozeTitle(minutes: Int) -> String {
        "Smart Snooze (Recommended \(minutes)m)"
    }

    nonisolated static func fameLaunchThresholdAlertsRecommendedSnoozeSubtitle(
        minutes: Int,
        launchStatus: FameLaunchCountdownStatus?,
        snoozeMinutesRemaining: Int?
    ) -> String {
        let urgencySummary: String
        if let launchStatus {
            urgencySummary = fameLaunchCountdownUrgency(launchStatus)
        } else {
            urgencySummary = "Urgency Unknown"
        }

        if let snoozeMinutesRemaining,
           snoozeMinutesRemaining > 0 {
            return "\(urgencySummary) · \(snoozeMinutesRemaining)m left · extend by \(minutes)m"
        }
        return "\(urgencySummary) · quiet launch threshold alerts for \(minutes)m"
    }

    nonisolated static func fameLaunchThresholdAlertsRecommendedSnoozeSystemImage() -> String {
        "sparkles"
    }

    nonisolated static func shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
        alertsEnabled: Bool,
        launchStatus: FameLaunchCountdownStatus?,
        snoozeMinutesRemaining: Int?
    ) -> Bool {
        guard !alertsEnabled,
              let snoozeMinutesRemaining,
              snoozeMinutesRemaining > 0,
              snoozeMinutesRemaining <= 5,
              let urgency = fameLaunchBadgeUrgency(launchStatus) else {
            return false
        }

        switch urgency {
        case .ready, .live, .hot:
            return true
        case .prep, .high, .critical:
            return false
        }
    }

    nonisolated static func shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
        alertsEnabled: Bool,
        launchStatus: FameLaunchCountdownStatus?,
        snoozeMinutesRemaining: Int?,
        currentSnoozeUntil: Date?,
        lastReminderSnoozeUntil: Date?,
        lastReminderUrgencyPriority: Int?
    ) -> Bool {
        guard shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderAction(
            alertsEnabled: alertsEnabled,
            launchStatus: launchStatus,
            snoozeMinutesRemaining: snoozeMinutesRemaining
        ),
        let currentSnoozeUntil,
        let urgency = fameLaunchBadgeUrgency(launchStatus) else {
            return false
        }

        guard let lastReminderSnoozeUntil else { return true }
        let sameSnoozeWindow = abs(lastReminderSnoozeUntil.timeIntervalSince(currentSnoozeUntil)) < 1
        guard sameSnoozeWindow else { return true }

        guard let lastReminderUrgencyPriority else { return true }
        let currentUrgencyPriority = fameLaunchBadgeUrgencyPriority(urgency)
        return currentUrgencyPriority > lastReminderUrgencyPriority
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderTitle(
        snoozeMinutesRemaining: Int
    ) -> String {
        "Launch Alert: Snooze Ends in \(snoozeMinutesRemaining)m"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderSubtitle(
        status: FameLaunchCountdownStatus,
        snoozeMinutesRemaining: Int,
        recommendedMinutes: Int
    ) -> String {
        "\(fameLaunchCountdownUrgency(status)) · Threshold alerts auto-unmute in \(snoozeMinutesRemaining)m · unmute now or smart snooze \(recommendedMinutes)m · \(fameLaunchThresholdAlertsSnoozeReminderReason(status: status, snoozeMinutesRemaining: snoozeMinutesRemaining))"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderExtendTitle(
        recommendedMinutes: Int
    ) -> String {
        "Launch Alert: Extend Snooze \(recommendedMinutes)m"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderExtendSubtitle(
        status: FameLaunchCountdownStatus,
        snoozeMinutesRemaining: Int,
        recommendedMinutes: Int
    ) -> String {
        "\(fameLaunchCountdownUrgency(status)) · \(snoozeMinutesRemaining)m left · extend snooze by \(recommendedMinutes)m now"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderExtendSystemImage() -> String {
        "sparkles"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderMenuTitle(
        alertsEnabled: Bool,
        launchStatus: FameLaunchCountdownStatus?,
        snoozeMinutesRemaining: Int?,
        currentSnoozeUntil: Date?,
        lastReminderSnoozeUntil: Date?,
        lastReminderUrgencyPriority: Int?,
        cooldownSeconds: Int? = nil
    ) -> String {
        let state = fameLaunchThresholdAlertsSnoozeReminderMenuState(
            alertsEnabled: alertsEnabled,
            launchStatus: launchStatus,
            snoozeMinutesRemaining: snoozeMinutesRemaining,
            currentSnoozeUntil: currentSnoozeUntil,
            lastReminderSnoozeUntil: lastReminderSnoozeUntil,
            lastReminderUrgencyPriority: lastReminderUrgencyPriority
        )
        let tapAction = fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
            alertsEnabled: alertsEnabled,
            launchStatus: launchStatus,
            menuState: state
        )

        let baseTitle: String = switch state {
        case .inactiveAlertsOn:
            "Launch Snooze Reminder: Inactive (alerts on)"
        case .inactiveNoSnooze:
            "Launch Snooze Reminder: Inactive (no snooze)"
        case .waiting(let minutesRemaining):
            "Launch Snooze Reminder: Waiting (\(minutesRemaining)m left)"
        case .waitingUrgencyUnknown:
            "Launch Snooze Reminder: Waiting (urgency unknown)"
        case .waitingUrgency(let urgency):
            "Launch Snooze Reminder: Waiting (urgency \(fameLaunchBadgeUrgencyLabel(urgency)))"
        case .armed(let minutesRemaining):
            "Launch Snooze Reminder: Armed (\(minutesRemaining)m left)"
        case .suppressed:
            "Launch Snooze Reminder: Suppressed (shown once this snooze)"
        }

        let actionableTitle: String
        switch tapAction {
        case nil:
            actionableTitle = baseTitle
        case .unmuteNow:
            actionableTitle = "\(baseTitle) · Click: Unmute now"
        case .extend(let minutes):
            actionableTitle = "\(baseTitle) · Click: Extend \(minutes)m"
        }

        guard let cooldownSeconds,
              cooldownSeconds > 0 else {
            return actionableTitle
        }
        return "\(actionableTitle) · Cooldown \(cooldownSeconds)s"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderMenuState(
        alertsEnabled: Bool,
        launchStatus: FameLaunchCountdownStatus?,
        snoozeMinutesRemaining: Int?,
        currentSnoozeUntil: Date?,
        lastReminderSnoozeUntil: Date?,
        lastReminderUrgencyPriority: Int?
    ) -> FameLaunchThresholdAlertsSnoozeReminderMenuState {
        guard !alertsEnabled else {
            return .inactiveAlertsOn
        }

        guard let snoozeMinutesRemaining,
              snoozeMinutesRemaining > 0 else {
            return .inactiveNoSnooze
        }

        guard snoozeMinutesRemaining <= 5 else {
            return .waiting(minutesRemaining: snoozeMinutesRemaining)
        }

        guard let urgency = fameLaunchBadgeUrgency(launchStatus) else {
            return .waitingUrgencyUnknown
        }

        switch urgency {
        case .ready, .live, .hot:
            break
        case .prep, .high, .critical:
            return .waitingUrgency(urgency)
        }

        if shouldSurfaceFameLaunchThresholdAlertsSnoozeReminderActionWithDedup(
            alertsEnabled: alertsEnabled,
            launchStatus: launchStatus,
            snoozeMinutesRemaining: snoozeMinutesRemaining,
            currentSnoozeUntil: currentSnoozeUntil,
            lastReminderSnoozeUntil: lastReminderSnoozeUntil,
            lastReminderUrgencyPriority: lastReminderUrgencyPriority
        ) {
            return .armed(minutesRemaining: snoozeMinutesRemaining)
        }

        guard let currentSnoozeUntil,
              let lastReminderSnoozeUntil else {
            return .waiting(minutesRemaining: snoozeMinutesRemaining)
        }

        let sameSnoozeWindow = abs(lastReminderSnoozeUntil.timeIntervalSince(currentSnoozeUntil)) < 1
        return sameSnoozeWindow ? .suppressed : .waiting(minutesRemaining: snoozeMinutesRemaining)
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
        alertsEnabled: Bool,
        launchStatus: FameLaunchCountdownStatus?,
        menuState: FameLaunchThresholdAlertsSnoozeReminderMenuState
    ) -> FameLaunchThresholdAlertsSnoozeReminderMenuTapAction? {
        guard !alertsEnabled else { return nil }

        if let urgency = fameLaunchBadgeUrgency(launchStatus),
           urgency == .high || urgency == .critical {
            return .unmuteNow
        }

        guard let launchStatus else { return nil }
        switch menuState {
        case .armed, .suppressed:
            return .extend(minutes: fameLaunchThresholdAlertsRecommendedSnoozeMinutes(
                launchStatus: launchStatus
            ))
        case .inactiveAlertsOn, .inactiveNoSnooze, .waiting, .waitingUrgencyUnknown, .waitingUrgency:
            return nil
        }
    }

    nonisolated static func canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(
        _ state: FameLaunchThresholdAlertsSnoozeReminderMenuState
    ) -> Bool {
        switch state {
        case .armed, .suppressed:
            return true
        case .inactiveAlertsOn, .inactiveNoSnooze, .waiting, .waitingUrgencyUnknown, .waitingUrgency:
            return false
        }
    }

    nonisolated static func canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(
        _ tapAction: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction?
    ) -> Bool {
        tapAction != nil
    }

    nonisolated static func fameLaunchThresholdAlertsQuickActionMessage(
        action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction,
        resolvedMinutes: Int? = nil
    ) -> String {
        switch action {
        case .unmuteNow:
            return "Quick action: launch threshold alerts unmuted."
        case .extend(let minutes):
            let appliedMinutes = resolvedMinutes ?? minutes
            return "Quick action: launch threshold alert snooze extended \(appliedMinutes)m."
        }
    }

    nonisolated static func fameLaunchThresholdAlertsQuickActionSourceFromMenu(
        action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction
    ) -> String {
        switch action {
        case .unmuteNow:
            "menu-snooze-reminder-unmute"
        case .extend:
            "menu-snooze-reminder-extend"
        }
    }

    nonisolated static func fameLaunchThresholdAlertsQuickActionDisabledReason(
        cooldownSeconds: Int?
    ) -> String {
        guard let cooldownSeconds,
              cooldownSeconds > 0 else {
            return "Not ready"
        }
        return "Cooldown \(cooldownSeconds)s"
    }

    nonisolated static func fameLaunchThresholdAlertsQuickActionReadySurfaceToken(
        menuVisible: Bool,
        paletteVisible: Bool
    ) -> String {
        switch (menuVisible, paletteVisible) {
        case (true, true):
            return "menu-palette"
        case (true, false):
            return "menu"
        case (false, true):
            return "palette"
        case (false, false):
            return "none"
        }
    }

    nonisolated static func shouldRunFameLaunchThresholdAlertsQuickAction(
        lastRunAt: Date?,
        lastActionToken: String?,
        nextActionToken: String,
        now: Date = Date(),
        cooldown: TimeInterval
    ) -> Bool {
        guard cooldown > 0 else { return true }
        guard lastActionToken == nextActionToken else { return true }
        guard let lastRunAt else { return true }
        return now.timeIntervalSince(lastRunAt) >= cooldown
    }

    nonisolated static func fameLaunchThresholdAlertsQuickActionCooldownRemainingSeconds(
        lastRunAt: Date?,
        lastActionToken: String?,
        nextActionToken: String,
        now: Date = Date(),
        cooldown: TimeInterval
    ) -> Int? {
        guard cooldown > 0,
              lastActionToken == nextActionToken,
              let lastRunAt else {
            return nil
        }
        let remaining = cooldown - now.timeIntervalSince(lastRunAt)
        guard remaining > 0 else { return nil }
        return max(1, Int(ceil(remaining)))
    }

    nonisolated static func shouldSurfaceFameLaunchThresholdAlertsQuickActionReadyPulse(
        previousCooldownSeconds: Int?,
        cooldownSeconds: Int?,
        tapAction: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction?,
        isMenuVisible: Bool = true
    ) -> Bool {
        guard previousCooldownSeconds != nil,
              cooldownSeconds == nil,
              isMenuVisible,
              canOpenFameLaunchThresholdAlertsSnoozeReminderMenu(tapAction) else {
            return false
        }
        return true
    }

    nonisolated static func fameLaunchThresholdAlertsQuickActionActivityToken(
        action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction,
        resolvedMinutes: Int? = nil
    ) -> String {
        switch action {
        case .unmuteNow:
            return "unmute-now"
        case .extend(let minutes):
            let appliedMinutes = resolvedMinutes ?? minutes
            return "extend-\(appliedMinutes)m"
        }
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderReason(
        status: FameLaunchCountdownStatus,
        snoozeMinutesRemaining: Int
    ) -> String {
        let urgencyLabel: String
        if let urgency = fameLaunchBadgeUrgency(status) {
            urgencyLabel = fameLaunchBadgeUrgencyLabel(urgency)
        } else {
            urgencyLabel = "Unknown"
        }
        return "Why now: snooze ends in \(snoozeMinutesRemaining)m and urgency is \(urgencyLabel)"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeReminderSystemImage() -> String {
        "hourglass.circle.fill"
    }

    nonisolated static func fameLaunchThresholdAlertsSnoozeMinutesRemaining(
        snoozeUntil: Date?,
        now: Date = Date()
    ) -> Int? {
        guard let snoozeUntil else { return nil }
        let secondsRemaining = snoozeUntil.timeIntervalSince(now)
        guard secondsRemaining > 0 else { return nil }
        return max(1, Int(ceil(secondsRemaining / 60)))
    }

    nonisolated static func shouldAutoUnmuteFameLaunchThresholdAlerts(
        alertsEnabled: Bool,
        snoozeUntil: Date?,
        now: Date = Date()
    ) -> Bool {
        guard !alertsEnabled,
              let snoozeUntil else {
            return false
        }
        return snoozeUntil <= now
    }

    nonisolated static func shouldSurfaceFameLaunchThresholdAlertsRecoveryAction(
        alertsEnabled: Bool,
        launchStatus: FameLaunchCountdownStatus?
    ) -> Bool {
        guard !alertsEnabled,
              let urgency = fameLaunchBadgeUrgency(launchStatus) else {
            return false
        }

        switch urgency {
        case .high, .critical:
            return true
        case .prep, .ready, .live, .hot:
            return false
        }
    }

    nonisolated static func fameLaunchThresholdAlertsRecoveryTitle(_ status: FameLaunchCountdownStatus) -> String {
        "Launch Alert: Unmute Threshold Alerts"
    }

    nonisolated static func fameLaunchThresholdAlertsRecoverySubtitle(_ status: FameLaunchCountdownStatus) -> String {
        "\(fameLaunchCountdownUrgency(status)) · HUD/flash launch alerts muted · unmute now"
    }

    nonisolated static func fameLaunchBadgeUrgency(_ status: FameLaunchCountdownStatus?) -> FameLaunchBadgeUrgency? {
        guard let status,
              let minutes = fameLaunchCountdownMinutes(status.countdown) else {
            return nil
        }

        if minutes >= 30 {
            return .critical
        }
        if minutes >= 15 {
            return .high
        }
        if minutes > 0 {
            return .hot
        }
        if minutes >= -5 {
            return .live
        }
        if minutes >= -20 {
            return .ready
        }
        return .prep
    }

    nonisolated static func fameLaunchBadgeUrgencyPriority(_ urgency: FameLaunchBadgeUrgency) -> Int {
        switch urgency {
        case .prep:
            return 0
        case .ready:
            return 1
        case .live:
            return 2
        case .hot:
            return 3
        case .high:
            return 4
        case .critical:
            return 5
        }
    }

    nonisolated static func fameLaunchBadgeUrgencyLabel(_ urgency: FameLaunchBadgeUrgency) -> String {
        switch urgency {
        case .prep:
            return "Prep"
        case .ready:
            return "Ready"
        case .live:
            return "Live"
        case .hot:
            return "Hot"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }

    nonisolated static func fameLaunchBadgeUrgencyToken(_ urgency: FameLaunchBadgeUrgency) -> String {
        fameLaunchBadgeUrgencyLabel(urgency).lowercased()
    }

    nonisolated static func fameLaunchBadgeUrgencyToken(
        status: FameLaunchCountdownStatus?
    ) -> String {
        guard let urgency = fameLaunchBadgeUrgency(status) else {
            return "unknown"
        }
        return fameLaunchBadgeUrgencyToken(urgency)
    }

    nonisolated static func launchControlHealthBand(
        _ urgency: FameLaunchBadgeUrgency?
    ) -> LaunchControlHealthBand {
        guard let urgency else {
            return .watch
        }

        switch urgency {
        case .prep, .ready:
            return .ready
        case .live, .hot:
            return .watch
        case .high, .critical:
            return .risk
        }
    }

    nonisolated static func launchControlHealthBand(
        launchStatus: FameLaunchCountdownStatus?
    ) -> LaunchControlHealthBand {
        launchControlHealthBand(
            fameLaunchBadgeUrgency(launchStatus)
        )
    }

    nonisolated static func fameLaunchUrgencyTransition(
        previous: FameLaunchBadgeUrgency?,
        next: FameLaunchBadgeUrgency?
    ) -> FameLaunchUrgencyTransition? {
        guard let previous, let next, previous != next else { return nil }
        let isEscalation = fameLaunchBadgeUrgencyPriority(next) > fameLaunchBadgeUrgencyPriority(previous)
        return FameLaunchUrgencyTransition(
            from: previous,
            to: next,
            isEscalation: isEscalation
        )
    }

    nonisolated static func launchControlHealthTransition(
        previous: FameLaunchBadgeUrgency?,
        next: FameLaunchBadgeUrgency?
    ) -> LaunchControlHealthTransition? {
        let from = launchControlHealthBand(previous)
        let to = launchControlHealthBand(next)
        guard from != to else { return nil }
        return LaunchControlHealthTransition(from: from, to: to)
    }

    nonisolated static func shouldSurfaceLaunchControlHealthTransitionPulse(
        _ transition: LaunchControlHealthTransition,
        alertsEnabled: Bool = true
    ) -> Bool {
        guard alertsEnabled else { return false }
        return (transition.from == .watch && transition.to == .risk)
            || (transition.from == .risk && transition.to == .ready)
    }

    nonisolated static func launchControlHealthTransitionPulseToken(
        _ transition: LaunchControlHealthTransition
    ) -> String {
        "\(transition.from.rawValue)-to-\(transition.to.rawValue)"
    }

    nonisolated static func launchControlHealthTransitionCounterToken(
        _ transition: LaunchControlHealthTransition
    ) -> String? {
        switch (transition.from, transition.to) {
        case (.watch, .risk):
            return "watch-to-risk"
        case (.risk, .ready):
            return "risk-to-ready"
        default:
            return nil
        }
    }

    nonisolated static func launchControlHealthTransitionCountDayStamp(
        now: Date,
        calendar: Calendar = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now)
    }

    nonisolated static func launchControlHealthTransitionCounts(
        now: Date,
        defaults: UserDefaults = .standard,
        dayKey: String = AppDefaults.fameLaunchHealthTransitionCountDayKey,
        watchToRiskCountKey: String = AppDefaults.fameLaunchHealthTransitionWatchToRiskCountKey,
        riskToReadyCountKey: String = AppDefaults.fameLaunchHealthTransitionRiskToReadyCountKey,
        calendar: Calendar = .current
    ) -> (watchToRiskCount: Int, riskToReadyCount: Int) {
        let todayStamp = launchControlHealthTransitionCountDayStamp(
            now: now,
            calendar: calendar
        )
        guard defaults.string(forKey: dayKey) == todayStamp else {
            return (0, 0)
        }
        return (
            max(0, defaults.integer(forKey: watchToRiskCountKey)),
            max(0, defaults.integer(forKey: riskToReadyCountKey))
        )
    }

    nonisolated static func launchControlHealthTransitionHistory(
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults.fameLaunchHealthTransitionHistoryKey
    ) -> [LaunchControlHealthTransitionHistoryDay] {
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([LaunchControlHealthTransitionHistoryDay].self, from: data) else {
            return []
        }

        return history.map { day in
            LaunchControlHealthTransitionHistoryDay(
                dayStamp: day.dayStamp,
                watchToRiskCount: max(0, day.watchToRiskCount),
                riskToReadyCount: max(0, day.riskToReadyCount)
            )
        }
    }

    nonisolated static func launchControlHealthTransitionHistoryWindow(
        now: Date,
        defaults: UserDefaults = .standard,
        dayKey: String = AppDefaults.fameLaunchHealthTransitionCountDayKey,
        watchToRiskCountKey: String = AppDefaults.fameLaunchHealthTransitionWatchToRiskCountKey,
        riskToReadyCountKey: String = AppDefaults.fameLaunchHealthTransitionRiskToReadyCountKey,
        historyKey: String = AppDefaults.fameLaunchHealthTransitionHistoryKey,
        calendar: Calendar = .current,
        historyWindowDays: Int = 7
    ) -> [LaunchControlHealthTransitionHistoryDay] {
        let windowDayCount = max(1, historyWindowDays)
        let todayStamp = launchControlHealthTransitionCountDayStamp(now: now, calendar: calendar)
        let todayCounts = launchControlHealthTransitionCounts(
            now: now,
            defaults: defaults,
            dayKey: dayKey,
            watchToRiskCountKey: watchToRiskCountKey,
            riskToReadyCountKey: riskToReadyCountKey,
            calendar: calendar
        )

        var historyByDay: [String: LaunchControlHealthTransitionHistoryDay] = [:]
        launchControlHealthTransitionHistory(
            defaults: defaults,
            historyKey: historyKey
        ).forEach { day in
            historyByDay[day.dayStamp] = day
        }
        historyByDay[todayStamp] = LaunchControlHealthTransitionHistoryDay(
            dayStamp: todayStamp,
            watchToRiskCount: todayCounts.watchToRiskCount,
            riskToReadyCount: todayCounts.riskToReadyCount
        )

        let startOfToday = calendar.startOfDay(for: now)
        return stride(from: windowDayCount - 1, through: 0, by: -1).compactMap { dayOffset in
            guard let dayDate = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else {
                return nil
            }
            let dayStamp = launchControlHealthTransitionCountDayStamp(now: dayDate, calendar: calendar)
            return historyByDay[dayStamp]
                ?? LaunchControlHealthTransitionHistoryDay(
                    dayStamp: dayStamp,
                    watchToRiskCount: 0,
                    riskToReadyCount: 0
                )
        }
    }

    nonisolated static func incrementLaunchControlHealthTransitionCounts(
        _ transition: LaunchControlHealthTransition,
        now: Date,
        defaults: UserDefaults = .standard,
        dayKey: String = AppDefaults.fameLaunchHealthTransitionCountDayKey,
        watchToRiskCountKey: String = AppDefaults.fameLaunchHealthTransitionWatchToRiskCountKey,
        riskToReadyCountKey: String = AppDefaults.fameLaunchHealthTransitionRiskToReadyCountKey,
        historyKey: String = AppDefaults.fameLaunchHealthTransitionHistoryKey,
        historyWindowDays: Int = 7,
        calendar: Calendar = .current
    ) -> (watchToRiskCount: Int, riskToReadyCount: Int)? {
        guard let token = launchControlHealthTransitionCounterToken(transition) else {
            return nil
        }

        let todayStamp = launchControlHealthTransitionCountDayStamp(
            now: now,
            calendar: calendar
        )
        let storedDayStamp = defaults.string(forKey: dayKey)
        var watchToRiskCount = 0
        var riskToReadyCount = 0

        if storedDayStamp == todayStamp {
            watchToRiskCount = max(0, defaults.integer(forKey: watchToRiskCountKey))
            riskToReadyCount = max(0, defaults.integer(forKey: riskToReadyCountKey))
        }

        if token == "watch-to-risk" {
            watchToRiskCount += 1
        } else {
            riskToReadyCount += 1
        }

        defaults.set(todayStamp, forKey: dayKey)
        defaults.set(watchToRiskCount, forKey: watchToRiskCountKey)
        defaults.set(riskToReadyCount, forKey: riskToReadyCountKey)

        var history = launchControlHealthTransitionHistory(
            defaults: defaults,
            historyKey: historyKey
        )
        let todayHistory = LaunchControlHealthTransitionHistoryDay(
            dayStamp: todayStamp,
            watchToRiskCount: watchToRiskCount,
            riskToReadyCount: riskToReadyCount
        )
        if let index = history.firstIndex(where: { $0.dayStamp == todayStamp }) {
            history[index] = todayHistory
        } else {
            history.append(todayHistory)
        }
        history.sort { lhs, rhs in
            lhs.dayStamp < rhs.dayStamp
        }

        let keepDays = max(1, historyWindowDays)
        if history.count > keepDays {
            history = Array(history.suffix(keepDays))
        }

        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
        }

        return (watchToRiskCount, riskToReadyCount)
    }

    nonisolated static func shouldPulseLaunchControlHealthTransition(
        lastPulseAt: Date?,
        lastPulseToken: String?,
        transition: LaunchControlHealthTransition,
        now: Date,
        cooldown: TimeInterval = TimeInterval(AppDefaults.fameLaunchHealthPulseCooldownSeconds)
    ) -> Bool {
        guard cooldown > 0 else { return true }

        let transitionToken = launchControlHealthTransitionPulseToken(transition)
        guard lastPulseToken == transitionToken else { return true }
        guard let lastPulseAt else { return true }
        return now.timeIntervalSince(lastPulseAt) >= cooldown
    }

    nonisolated static func launchControlHealthTransitionPulseCooldownRemainingSeconds(
        lastPulseAt: Date?,
        lastPulseToken: String?,
        transition: LaunchControlHealthTransition,
        now: Date,
        cooldown: TimeInterval = TimeInterval(AppDefaults.fameLaunchHealthPulseCooldownSeconds)
    ) -> Int? {
        guard cooldown > 0 else { return nil }

        let transitionToken = launchControlHealthTransitionPulseToken(transition)
        guard lastPulseToken == transitionToken,
              let lastPulseAt else {
            return nil
        }

        let elapsed = now.timeIntervalSince(lastPulseAt)
        guard elapsed < cooldown else { return nil }
        let remaining = Int(ceil(cooldown - elapsed))
        return max(1, remaining)
    }

    nonisolated static func shouldSurfaceFameLaunchUrgencyTransition(
        _ transition: FameLaunchUrgencyTransition,
        alertsEnabled: Bool = true
    ) -> Bool {
        guard alertsEnabled else { return false }

        if transition.isEscalation {
            switch transition.to {
            case .live, .hot, .high, .critical:
                return true
            case .prep, .ready:
                return false
            }
        }

        switch transition.from {
        case .critical, .high:
            return true
        case .prep, .ready, .live, .hot:
            return false
        }
    }

    nonisolated static func shouldAutoRunFameLaunchRescueBurst(
        _ transition: FameLaunchUrgencyTransition,
        modeMomentumStreak: Int = 0,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldown: TimeInterval = TimeInterval(AppDefaults.fameLaunchRescueBurstAutoCooldownMinutes * 60),
        minimumCooldownStreak: Int = 2
    ) -> Bool {
        let urgencyEscalationTrigger: Bool
        if transition.isEscalation {
            switch transition.to {
            case .high, .critical:
                urgencyEscalationTrigger = true
            case .prep, .ready, .live, .hot:
                urgencyEscalationTrigger = false
            }
        } else {
            urgencyEscalationTrigger = false
        }

        let normalizedMinimumCooldownStreak = max(2, minimumCooldownStreak)
        let cooldownStreak = abs(min(0, modeMomentumStreak))
        let modeMomentumTrigger: Bool
        if transition.isEscalation,
           cooldownStreak >= normalizedMinimumCooldownStreak {
            switch transition.to {
            case .hot, .high, .critical:
                modeMomentumTrigger = true
            case .prep, .ready, .live:
                modeMomentumTrigger = false
            }
        } else {
            modeMomentumTrigger = false
        }

        guard urgencyEscalationTrigger || modeMomentumTrigger else { return false }
        return shouldRunAutoOpsBundleOnEscalation(
            lastRunAt: lastRunAt,
            now: now,
            cooldown: cooldown
        )
    }

    nonisolated static func launchRescueAutoTriggerReason(
        transition: FameLaunchUrgencyTransition,
        modeMomentumCueSeverity: LaunchRescueModeMomentumCueSeverity = .none
    ) -> LaunchRescueAutoTriggerReason {
        switch transition.to {
        case .critical:
            return .urgencyCritical
        case .high:
            return .urgencyHigh
        case .hot:
            switch modeMomentumCueSeverity {
            case .alert:
                return .momentumAlert
            case .watch, .none:
                return .momentumWatch
            }
        case .prep, .ready, .live:
            return .urgencyHigh
        }
    }

    nonisolated static func launchRescueAutoTriggerActivityDetail(
        reason: LaunchRescueAutoTriggerReason,
        pressureStreakDays: Int? = nil
    ) -> String {
        let baseDetail = "run-fame-launch-rescue-burst-auto-trigger-\(reason.rawValue)"
        guard reason == .pressurePersistence,
              let pressureStreakDays,
              pressureStreakDays > 0 else {
            return baseDetail
        }
        return "\(baseDetail)-\(pressureStreakDays)"
    }

    nonisolated static func launchRescueAutoTriggerReasonTokenFromActivityDetail(
        _ detail: String
    ) -> String {
        let normalizedDetail = detail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let prefix = "run-fame-launch-rescue-burst-auto-trigger-"
        guard normalizedDetail.hasPrefix(prefix) else { return "none" }
        let payload = String(normalizedDetail.dropFirst(prefix.count))
        let reasonTokens = [
            LaunchRescueAutoTriggerReason.urgencyHigh.rawValue,
            LaunchRescueAutoTriggerReason.urgencyCritical.rawValue,
            LaunchRescueAutoTriggerReason.momentumWatch.rawValue,
            LaunchRescueAutoTriggerReason.momentumAlert.rawValue,
            LaunchRescueAutoTriggerReason.pressurePersistence.rawValue
        ]

        for reasonToken in reasonTokens {
            guard payload.hasPrefix(reasonToken) else { continue }
            let suffix = String(payload.dropFirst(reasonToken.count))
            if suffix.isEmpty {
                return reasonToken
            }

            guard reasonToken == LaunchRescueAutoTriggerReason.pressurePersistence.rawValue,
                  suffix.hasPrefix("-"),
                  let streakDays = Int(suffix.dropFirst()),
                  streakDays > 0 else {
                return "none"
            }
            return reasonToken
        }

        return "none"
    }

    nonisolated static func launchRescueAutoTriggerReasonToken(_ value: String?) -> String {
        let cleanValue = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        switch cleanValue {
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue,
             LaunchRescueAutoTriggerReason.urgencyCritical.rawValue,
             LaunchRescueAutoTriggerReason.momentumWatch.rawValue,
             LaunchRescueAutoTriggerReason.momentumAlert.rawValue,
             LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return cleanValue
        default:
            return launchRescueAutoTriggerReasonTokenFromActivityDetail(cleanValue)
        }
    }

    nonisolated static func launchRescueAutoTriggerAt(_ value: Any?) -> Date? {
        let stamp: Double?
        switch value {
        case let rawStamp as Double:
            stamp = rawStamp
        case let rawStamp as NSNumber:
            stamp = rawStamp.doubleValue
        case let rawStamp as String:
            let cleanStamp = rawStamp.trimmingCharacters(in: .whitespacesAndNewlines)
            stamp = Double(cleanStamp)
        default:
            stamp = nil
        }
        guard let stamp, stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    nonisolated static func shouldSurfaceFameOnboardingGapPulse(
        previousMissingArtifacts: Int?,
        nextMissingArtifacts: Int?,
        lastPulseAt: Date?,
        now: Date = Date(),
        cooldown: TimeInterval = 15 * 60
    ) -> Bool {
        guard let nextMissingArtifacts, nextMissingArtifacts > 0 else { return false }
        guard let previousMissingArtifacts else { return false }
        guard nextMissingArtifacts > previousMissingArtifacts else { return false }

        let normalizedCooldown = max(0, cooldown)
        guard normalizedCooldown > 0 else { return true }
        guard let lastPulseAt else { return true }
        return now.timeIntervalSince(lastPulseAt) >= normalizedCooldown
    }

    nonisolated static func shouldSurfaceFameOnboardingGapRecoveryPulse(
        previousMissingArtifacts: Int?,
        nextMissingArtifacts: Int?,
        lastRecoveryAt: Date?,
        now: Date = Date(),
        cooldown: TimeInterval = 10 * 60
    ) -> Bool {
        guard let previousMissingArtifacts, previousMissingArtifacts > 0 else { return false }
        let normalizedNextMissingArtifacts = max(0, nextMissingArtifacts ?? 0)
        guard normalizedNextMissingArtifacts < previousMissingArtifacts else { return false }

        let normalizedCooldown = max(0, cooldown)
        guard normalizedCooldown > 0 else { return true }
        guard let lastRecoveryAt else { return true }
        return now.timeIntervalSince(lastRecoveryAt) >= normalizedCooldown
    }

    @discardableResult
    nonisolated static func consumeFameOnboardingGapRecoveryMomentum(
        actionID: String,
        defaults: UserDefaults = .standard,
        lastAtKey: String = AppDefaults.fameOnboardingGapRecoveryLastAtKey,
        followupCommandIDKey: String = AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey,
        remainingArtifactsKey: String = AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey
    ) -> Bool {
        let normalizedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedActionID.isEmpty else { return false }
        guard let followupCommandID = defaults.string(forKey: followupCommandIDKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !followupCommandID.isEmpty else {
            return false
        }
        guard followupCommandID == normalizedActionID else { return false }

        defaults.removeObject(forKey: lastAtKey)
        defaults.removeObject(forKey: followupCommandIDKey)
        defaults.removeObject(forKey: remainingArtifactsKey)
        return true
    }

    nonisolated static func fameStatusBadgeLevel(
        pulseSignal: FamePulseAlertSignal?,
        launchStatus: FameLaunchCountdownStatus?,
        onboardingGapMissingArtifacts: Int? = nil
    ) -> FameStatusBadgeLevel {
        let pulseLevel: FameStatusBadgeLevel?
        switch pulseSignal?.riskLevel {
        case "Critical":
            pulseLevel = .pulseCritical
        case "High":
            pulseLevel = .pulseHigh
        default:
            pulseLevel = nil
        }

        let launchLevel: FameStatusBadgeLevel?
        switch fameLaunchBadgeUrgency(launchStatus) {
        case .critical:
            launchLevel = .launchCritical
        case .high:
            launchLevel = .launchHigh
        case .hot:
            launchLevel = .launchHot
        case .live:
            launchLevel = .launchLive
        case .ready:
            launchLevel = .launchReady
        case .prep:
            launchLevel = .launchPrep
        case .none:
            launchLevel = nil
        }

        let onboardingGapLevel: FameStatusBadgeLevel?
        if let onboardingGapMissingArtifacts, onboardingGapMissingArtifacts > 0 {
            onboardingGapLevel = .onboardingGap
        } else {
            onboardingGapLevel = nil
        }

        let candidates = [pulseLevel, launchLevel, onboardingGapLevel]
            .compactMap { $0 }
            .sorted { fameStatusBadgePriority($0) > fameStatusBadgePriority($1) }

        return candidates.first ?? .normal
    }

    nonisolated static func fameStatusBadgePriority(_ level: FameStatusBadgeLevel) -> Int {
        switch level {
        case .normal:
            return 0
        case .onboardingGap:
            return 1
        case .launchPrep:
            return 2
        case .launchReady:
            return 3
        case .launchLive:
            return 4
        case .launchHot:
            return 5
        case .launchHigh:
            return 6
        case .pulseHigh:
            return 7
        case .launchCritical:
            return 8
        case .pulseCritical:
            return 9
        }
    }

    nonisolated static func fameStatusBadgeSymbol(_ level: FameStatusBadgeLevel) -> String {
        switch level {
        case .normal:
            return "text.viewfinder"
        case .onboardingGap:
            return "sparkles"
        case .launchPrep, .launchReady:
            return "timer"
        case .launchLive:
            return "bolt.badge.clock"
        case .launchHot:
            return "flame"
        case .launchHigh, .launchCritical:
            return "flame.fill"
        case .pulseHigh:
            return "exclamationmark.triangle"
        case .pulseCritical:
            return "exclamationmark.triangle.fill"
        }
    }

    nonisolated static func fameStatusBadgeTint(_ level: FameStatusBadgeLevel) -> NSColor? {
        switch level {
        case .normal:
            return nil
        case .onboardingGap:
            return .systemPurple
        case .launchPrep, .launchReady:
            return .systemBlue
        case .launchLive:
            return .systemGreen
        case .launchHot, .launchHigh:
            return .systemOrange
        case .launchCritical, .pulseCritical:
            return .systemRed
        case .pulseHigh:
            return .systemOrange
        }
    }

    nonisolated static func shouldRefreshLaunchCountdown(
        lastRefreshAt: Date?,
        now: Date,
        minimumInterval: TimeInterval = 45
    ) -> Bool {
        let normalizedInterval = max(1, minimumInterval)
        guard let lastRefreshAt else { return true }
        return now.timeIntervalSince(lastRefreshAt) >= normalizedInterval
    }

    nonisolated static func autoOpsBundleEscalationStatus(
        lastRunAt: Date?,
        now: Date,
        cooldownMinutes: Int
    ) -> AutoOpsBundleEscalationStatus {
        let normalizedCooldownMinutes = max(0, cooldownMinutes)
        guard normalizedCooldownMinutes > 0 else { return .disabled }

        let cooldown = TimeInterval(normalizedCooldownMinutes * 60)
        guard shouldRunAutoOpsBundleOnEscalation(
            lastRunAt: lastRunAt,
            now: now,
            cooldown: cooldown
        ) else {
            guard let lastRunAt else {
                return .coolingDown(minutesRemaining: normalizedCooldownMinutes)
            }

            let elapsed = max(0, now.timeIntervalSince(lastRunAt))
            let remainingSeconds = max(0, cooldown - elapsed)
            let remainingMinutes = max(1, Int(ceil(remainingSeconds / 60)))
            return .coolingDown(minutesRemaining: remainingMinutes)
        }

        return .ready
    }

    nonisolated static func autoOpsBundleEscalationStatusPhrase(
        _ status: AutoOpsBundleEscalationStatus
    ) -> String {
        switch status {
        case .disabled:
            return "auto bundle off"
        case .ready:
            return "auto bundle ready"
        case .coolingDown(let minutesRemaining):
            return "auto bundle in \(minutesRemaining)m"
        }
    }

    nonisolated static func launchRescueBurstAutoStatusPhrase(
        _ status: AutoOpsBundleEscalationStatus
    ) -> String {
        switch status {
        case .disabled:
            return "auto rescue off"
        case .ready:
            return "auto rescue ready"
        case .coolingDown(let minutesRemaining):
            return "auto rescue in \(minutesRemaining)m"
        }
    }

    nonisolated static func autoOpsBundleReaderStatusTone(
        _ status: AutoOpsBundleEscalationStatus
    ) -> ReaderStatusTone {
        switch status {
        case .disabled:
            return .neutral
        case .ready:
            return .success
        case .coolingDown:
            return .warning
        }
    }

    nonisolated static func launchRescueAutoReaderStatusTone(
        _ status: AutoOpsBundleEscalationStatus,
        title: String,
        subtitle: String
    ) -> ReaderStatusTone {
        let context = "\(title)\n\(subtitle)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if context.contains("critical")
            || context.contains("self-heal missing")
            || context.contains("self-heal mismatch")
            || context.contains("self-heal stale")
        {
            return .danger
        }

        if context.contains("high")
            || context.contains("momentum alert")
            || context.contains("alert x")
        {
            return .warning
        }

        switch status {
        case .disabled:
            return .neutral
        case .ready:
            return .success
        case .coolingDown:
            return .warning
        }
    }

    nonisolated static func readerStatusPillActionHint(
        shortcutDisplay: String? = nil
    ) -> String {
        let baseHint = "Double-tap for details and actions."
        guard let shortcutDisplay else { return baseHint }
        let cleanShortcutDisplay = shortcutDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanShortcutDisplay.isEmpty else { return baseHint }
        return "\(baseHint) Shortcut: \(cleanShortcutDisplay)."
    }

    nonisolated static func readerStatusPillHelpText(
        _ subtitle: String,
        shortcutDisplay: String? = nil
    ) -> String {
        let cleanSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let shortcutDisplay else { return cleanSubtitle }
        let cleanShortcutDisplay = shortcutDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanShortcutDisplay.isEmpty else { return cleanSubtitle }
        if cleanSubtitle.isEmpty {
            return "Shortcut: \(cleanShortcutDisplay)."
        }
        return "\(cleanSubtitle)\nShortcut: \(cleanShortcutDisplay)."
    }

    nonisolated static func readerStatusPillAccessibilityHint(
        _ subtitle: String,
        actionHint: String = "Double-tap for details and actions."
    ) -> String {
        let normalizedActionHint = actionHint.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackHint = normalizedActionHint.isEmpty
            ? "Double-tap for details and actions."
            : normalizedActionHint

        let statusLine = subtitle
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })
            ?? ""
        guard !statusLine.isEmpty else {
            return fallbackHint
        }
        if statusLine.hasSuffix(".") || statusLine.hasSuffix("!") || statusLine.hasSuffix("?") {
            return "\(statusLine) \(fallbackHint)"
        }
        return "\(statusLine). \(fallbackHint)"
    }

    nonisolated static func readerStatusShortcutLegendAccessibilityValue() -> String {
        "Option Command O runs auto bundle status. Option Command L runs launch rescue auto status."
    }

    nonisolated static func readerStatusShortcutMenuHintLine() -> String {
        "Status shortcuts: ⌥⌘O Auto Bundle · ⌥⌘L Launch Rescue Auto."
    }

    nonisolated private static func cleanStatusLine(_ line: String?) -> String? {
        guard let line else { return nil }
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLine.isEmpty else { return nil }
        return cleanLine
    }

    nonisolated private static func appendCleanStatusLine(
        _ line: String?,
        to lines: inout [String]
    ) {
        guard let cleanLine = cleanStatusLine(line) else { return }
        lines.append(cleanLine)
    }

    nonisolated static func autoOpsBundleEscalationStatusMenuTitle(
        _ status: AutoOpsBundleEscalationStatus,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        let baseTitle: String = switch status {
        case .disabled:
            "Auto Ops Bundle: Off"
        case .ready:
            "Auto Ops Bundle: Ready"
        case .coolingDown(let minutesRemaining):
            "Auto Ops Bundle: Cooldown \(minutesRemaining)m"
        }
        return launchControlMenuTitleWithLaunchRescueContext(
            baseTitle,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func autoOpsBundleEscalationStatusMenuToolTip(
        _ status: AutoOpsBundleEscalationStatus,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        let subtitle = autoOpsBundleStatusActionSubtitle(
            status,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
        return "\(subtitle)\n\(readerStatusShortcutMenuHintLine())"
    }

    nonisolated static func launchRescueBurstAutoStatusMenuTitle(
        _ status: AutoOpsBundleEscalationStatus,
        modeMomentumStreak: Int = 0,
        followupBadge: String? = nil,
        selfHealBadge: String? = nil,
        selfHealAttentionBadge: String? = nil,
        triggerSeverityBadge: String? = nil
    ) -> String {
        let baseTitle: String = switch status {
        case .disabled:
            "Launch Rescue Auto: Off"
        case .ready:
            "Launch Rescue Auto: Ready"
        case .coolingDown(let minutesRemaining):
            "Launch Rescue Auto: Cooldown \(minutesRemaining)m"
        }
        var titleBadges: [String] = []
        if let followupBadge {
            let cleanFollowupBadge = followupBadge.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanFollowupBadge.isEmpty {
                titleBadges.append(cleanFollowupBadge)
            }
        }
        if let selfHealBadge {
            let cleanSelfHealBadge = selfHealBadge.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanSelfHealBadge.isEmpty {
                titleBadges.append(cleanSelfHealBadge)
            }
        }
        if let selfHealAttentionBadge {
            let cleanSelfHealAttentionBadge = selfHealAttentionBadge
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanSelfHealAttentionBadge.isEmpty {
                titleBadges.append(cleanSelfHealAttentionBadge)
            }
        }
        if let titleBadge = launchRescueModeMomentumCueTitleBadge(modeMomentumStreak: modeMomentumStreak) {
            titleBadges.append(titleBadge)
        }
        if let triggerSeverityBadge {
            let cleanTriggerSeverityBadge = triggerSeverityBadge.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanTriggerSeverityBadge.isEmpty {
                titleBadges.append(cleanTriggerSeverityBadge)
            }
        }
        guard !titleBadges.isEmpty else {
            return baseTitle
        }
        return "\(baseTitle) · \(titleBadges.joined(separator: " · "))"
    }

    nonisolated static func launchRescueBurstAutoStatusMenuToolTip(
        _ status: AutoOpsBundleEscalationStatus,
        modeMomentumStreak: Int = 0,
        lastAutoTriggerReason: String? = nil,
        lastAutoTriggerAt: Date? = nil,
        selfHealStatusTitle: String? = nil,
        selfHealAttentionStatusTitle: String? = nil,
        followupOutcomeScoreboardStatusTitle: String? = nil,
        followupOutcomeCoachStatusTitle: String? = nil,
        followupOutcomeMomentumStatusTitle: String? = nil,
        followupRouteDecisionTraceLine: String? = nil,
        now: Date = Date()
    ) -> String {
        let statusLine: String = switch status {
        case .disabled:
            "Status: Auto rescue is off. Enable in Settings > Fame Ops."
        case .ready:
            "Status: Auto rescue is ready on launch escalation."
        case .coolingDown(let minutesRemaining):
            "Status: Auto rescue cooldown \(minutesRemaining)m remaining."
        }

        var lines = [statusLine]
        appendCleanStatusLine(
            launchRescueAutoTriggerStatusSubtitleHint(lastAutoTriggerReason),
            to: &lines
        )
        appendCleanStatusLine(
            launchRescueAutoTriggerSeveritySubtitleHint(lastAutoTriggerReason),
            to: &lines
        )
        appendCleanStatusLine(
            launchRescueAutoTriggerAtStatusSubtitleHint(
                lastAutoTriggerAt,
                now: now
            ),
            to: &lines
        )
        appendCleanStatusLine(
            launchRescueAutoTriggerFollowupStatusSubtitleHint(
                lastAutoTriggerReason,
                lastAutoTriggerAt: lastAutoTriggerAt,
                now: now
            ),
            to: &lines
        )
        appendCleanStatusLine(followupRouteDecisionTraceLine, to: &lines)
        appendCleanStatusLine(selfHealStatusTitle, to: &lines)
        appendCleanStatusLine(selfHealAttentionStatusTitle, to: &lines)
        appendCleanStatusLine(followupOutcomeScoreboardStatusTitle, to: &lines)
        appendCleanStatusLine(followupOutcomeCoachStatusTitle, to: &lines)
        appendCleanStatusLine(followupOutcomeMomentumStatusTitle, to: &lines)
        appendCleanStatusLine(
            launchRescueModeMomentumCueHint(modeMomentumStreak: modeMomentumStreak),
            to: &lines
        )
        lines.append(readerStatusShortcutMenuHintLine())
        lines.append("Command: Run Launch Rescue Burst")
        return lines.joined(separator: "\n")
    }

    nonisolated static func launchRescueAutoTriggerSummary(_ token: String?) -> String {
        let cleanToken = token?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch cleanToken {
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue:
            return "Urgency High escalation."
        case LaunchRescueAutoTriggerReason.urgencyCritical.rawValue:
            return "Urgency Critical escalation."
        case LaunchRescueAutoTriggerReason.momentumWatch.rawValue:
            return "Cooldown momentum watch streak."
        case LaunchRescueAutoTriggerReason.momentumAlert.rawValue:
            return "Cooldown momentum alert streak."
        case LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return "Launch health pressure persistence."
        default:
            return "No auto trigger recorded yet."
        }
    }

    nonisolated static func launchRescueAutoTriggerStatusTitle(_ token: String?) -> String {
        "Launch Rescue Auto Trigger: \(launchRescueAutoTriggerSummary(token))"
    }

    nonisolated static func launchRescueAutoTriggerStatusSubtitleHint(_ token: String?) -> String? {
        let cleanToken = token?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch cleanToken {
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue,
             LaunchRescueAutoTriggerReason.urgencyCritical.rawValue,
             LaunchRescueAutoTriggerReason.momentumWatch.rawValue,
             LaunchRescueAutoTriggerReason.momentumAlert.rawValue,
             LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return "Last auto trigger: \(launchRescueAutoTriggerSummary(cleanToken))"
        default:
            return nil
        }
    }

    nonisolated static func launchRescueAutoTriggerSeverityBadge(_ token: String?) -> String? {
        let normalizedToken = launchRescueAutoTriggerReasonToken(token)
        switch normalizedToken {
        case LaunchRescueAutoTriggerReason.urgencyCritical.rawValue:
            return "Critical"
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue:
            return "High"
        case LaunchRescueAutoTriggerReason.momentumAlert.rawValue:
            return "Momentum Alert"
        case LaunchRescueAutoTriggerReason.momentumWatch.rawValue:
            return "Momentum Watch"
        case LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return "Pressure"
        default:
            return nil
        }
    }

    nonisolated static func launchRescueAutoTriggerSeveritySubtitleHint(_ token: String?) -> String? {
        guard let severityBadge = launchRescueAutoTriggerSeverityBadge(token) else {
            return nil
        }
        return "Trigger severity: \(severityBadge)"
    }

    nonisolated static func launchRescueAutoTriggerAtSummary(
        _ lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String {
        guard let lastAutoTriggerAt else {
            return "No auto trigger time recorded yet."
        }

        let elapsedSeconds = max(0, now.timeIntervalSince(lastAutoTriggerAt))
        if elapsedSeconds < 60 {
            return "Just now."
        }

        let elapsedMinutes = Int(elapsedSeconds / 60)
        if elapsedMinutes < 60 {
            return "\(elapsedMinutes)m ago."
        }

        let elapsedHours = elapsedMinutes / 60
        if elapsedHours < 24 {
            return "\(elapsedHours)h ago."
        }

        let elapsedDays = elapsedHours / 24
        return "\(elapsedDays)d ago."
    }

    nonisolated static func launchRescueAutoTriggerAtStatusTitle(
        _ lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String {
        "Launch Rescue Auto Trigger Time: \(launchRescueAutoTriggerAtSummary(lastAutoTriggerAt, now: now))"
    }

    nonisolated static func launchRescueAutoTriggerAtStatusSubtitleHint(
        _ lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String? {
        guard lastAutoTriggerAt != nil else { return nil }
        return "Last auto trigger time: \(launchRescueAutoTriggerAtSummary(lastAutoTriggerAt, now: now))"
    }

    nonisolated static func launchRescueAutoFollowupCommandID(_ commandID: String?) -> String {
        let normalizedCommandID = commandID?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalizedCommandID {
        case "run-fame-launch-rescue-burst",
             "run-fame-next-move-copy-drafts",
             "run-fame-recovery-checklist",
             "run-fame-launch-control-brief":
            return normalizedCommandID
        default:
            return "none"
        }
    }

    nonisolated static func launchRescueAutoFollowupCommandTitle(_ commandID: String?) -> String {
        switch launchRescueAutoFollowupCommandID(commandID) {
        case "run-fame-launch-rescue-burst":
            return "Run Launch Rescue Burst"
        case "run-fame-next-move-copy-drafts":
            return "Run Fame Next Move + Copy Draft Pack"
        case "run-fame-recovery-checklist":
            return "Run Fame Recovery Checklist"
        case "run-fame-launch-control-brief":
            return "Run Launch Control Brief"
        default:
            return "No follow-up route"
        }
    }

    nonisolated static func launchRescueAutoFollowupRunSummary(
        commandID: String?,
        reasonToken: String?
    ) -> String {
        let normalizedCommandID = launchRescueAutoFollowupCommandID(commandID)
        guard normalizedCommandID != "none" else {
            return "No follow-up run recorded yet."
        }
        let commandTitle = launchRescueAutoFollowupCommandTitle(normalizedCommandID)
        let normalizedReasonToken = launchRescueAutoTriggerReasonToken(reasonToken)
        guard normalizedReasonToken != "none" else {
            return "\(commandTitle)."
        }
        return "\(commandTitle) · reason: \(launchRescueAutoTriggerSummary(normalizedReasonToken))"
    }

    nonisolated static func launchRescueAutoFollowupAutoPressureActivityDetail(
        wasSuccessful: Bool
    ) -> String {
        launchRescueAutoFollowupAutoActivityDetail(
            reasonToken: LaunchRescueAutoTriggerReason.pressurePersistence.rawValue,
            wasSuccessful: wasSuccessful
        )
    }

    nonisolated static func launchRescueAutoFollowupAutoActivityDetail(
        reasonToken: String?,
        wasSuccessful: Bool
    ) -> String {
        let normalizedReasonToken = launchRescueAutoTriggerReasonToken(reasonToken)
        return "run-fame-launch-rescue-followup-now-auto-\(normalizedReasonToken)-\(wasSuccessful ? "success" : "failure")"
    }

    nonisolated static func launchRescueAutoFollowupArtifactsReady(
        routeCommandID: String?,
        hasLaunchRescueBurst: Bool,
        hasNextMoveHandoff: Bool,
        hasNextMoveDraftPack: Bool,
        hasLaunchControlBrief: Bool,
        hasRecoveryChecklist: Bool
    ) -> Bool {
        switch launchRescueAutoFollowupCommandID(routeCommandID) {
        case "run-fame-launch-rescue-burst":
            return hasLaunchRescueBurst
        case "run-fame-next-move-copy-drafts":
            return hasNextMoveDraftPack || hasNextMoveHandoff
        case "run-fame-launch-control-brief":
            return hasLaunchControlBrief
        case "run-fame-recovery-checklist":
            return hasRecoveryChecklist
        default:
            return false
        }
    }

    nonisolated static func launchRescueAutoFollowupArtifactsMissing(
        routeCommandID: String?,
        hasLaunchRescueBurst: Bool,
        hasNextMoveHandoff: Bool,
        hasNextMoveDraftPack: Bool,
        hasLaunchControlBrief: Bool,
        hasRecoveryChecklist: Bool
    ) -> Bool {
        switch launchRescueAutoFollowupCommandID(routeCommandID) {
        case "run-fame-launch-rescue-burst":
            return !hasLaunchRescueBurst
        case "run-fame-next-move-copy-drafts":
            return !hasNextMoveHandoff || !hasNextMoveDraftPack
        case "run-fame-launch-control-brief":
            return !hasLaunchControlBrief
        case "run-fame-recovery-checklist":
            return !hasRecoveryChecklist
        default:
            return false
        }
    }

    nonisolated static func launchRescueAutoFollowupSelfHealActivityDetail(
        reasonToken: String?,
        routeCommandID: String?,
        outcome: String
    ) -> String {
        let normalizedReasonToken = launchRescueAutoTriggerReasonToken(reasonToken)
        let normalizedRouteCommandID = launchRescueAutoFollowupCommandID(routeCommandID)
        let normalizedOutcome = outcome
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let outcomeToken: String
        switch normalizedOutcome {
        case "ready", "healed", "failed":
            outcomeToken = normalizedOutcome
        default:
            outcomeToken = "unknown"
        }
        return "run-fame-launch-rescue-followup-now-auto-self-heal-\(normalizedReasonToken)-\(ActivityLogCommand.safeID(normalizedRouteCommandID))-\(outcomeToken)"
    }

    nonisolated static func launchRescueAutoFollowupSelfHealOutcome(
        _ value: String?
    ) -> LaunchRescueAutoFollowupSelfHealOutcome {
        let normalizedValue = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        switch normalizedValue {
        case LaunchRescueAutoFollowupSelfHealOutcome.ready.rawValue:
            return .ready
        case LaunchRescueAutoFollowupSelfHealOutcome.healed.rawValue:
            return .healed
        case LaunchRescueAutoFollowupSelfHealOutcome.failed.rawValue:
            return .failed
        default:
            return .unknown
        }
    }

    nonisolated static func launchRescueAutoFollowupSelfHealSnapshot(
        fromActivityDetail detail: String,
        recordedAt: Date? = nil
    ) -> LaunchRescueAutoFollowupSelfHealSnapshot? {
        let normalizedDetail = detail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let prefix = "run-fame-launch-rescue-followup-now-auto-self-heal-"
        guard normalizedDetail.hasPrefix(prefix) else { return nil }
        let payload = String(normalizedDetail.dropFirst(prefix.count))
        let reasonTokens = [
            LaunchRescueAutoTriggerReason.urgencyHigh.rawValue,
            LaunchRescueAutoTriggerReason.urgencyCritical.rawValue,
            LaunchRescueAutoTriggerReason.momentumWatch.rawValue,
            LaunchRescueAutoTriggerReason.momentumAlert.rawValue,
            LaunchRescueAutoTriggerReason.pressurePersistence.rawValue,
            "none"
        ]
        let outcomeTokens = [
            LaunchRescueAutoFollowupSelfHealOutcome.ready.rawValue,
            LaunchRescueAutoFollowupSelfHealOutcome.healed.rawValue,
            LaunchRescueAutoFollowupSelfHealOutcome.failed.rawValue,
            LaunchRescueAutoFollowupSelfHealOutcome.unknown.rawValue
        ]

        for reasonToken in reasonTokens {
            let reasonPrefix = "\(reasonToken)-"
            guard payload.hasPrefix(reasonPrefix) else { continue }
            let routeAndOutcome = String(payload.dropFirst(reasonPrefix.count))
            for outcomeToken in outcomeTokens {
                let outcomeSuffix = "-\(outcomeToken)"
                guard routeAndOutcome.hasSuffix(outcomeSuffix) else { continue }
                let routeToken = String(routeAndOutcome.dropLast(outcomeSuffix.count))
                let normalizedRouteCommandID = launchRescueAutoFollowupCommandID(routeToken)
                if normalizedRouteCommandID == "none", routeToken != "none" {
                    continue
                }
                return LaunchRescueAutoFollowupSelfHealSnapshot(
                    reasonToken: launchRescueAutoTriggerReasonToken(reasonToken),
                    routeCommandID: normalizedRouteCommandID,
                    outcome: launchRescueAutoFollowupSelfHealOutcome(outcomeToken),
                    recordedAt: recordedAt
                )
            }
        }

        return nil
    }

    nonisolated static func launchRescueAutoFollowupSelfHealSnapshotIsRecent(
        recordedAt: Date?,
        now: Date = Date(),
        freshnessWindow: TimeInterval = launchRescueAutoFollowupArtifactFreshnessWindow,
        futureGraceWindow: TimeInterval = 60
    ) -> Bool {
        guard let recordedAt else { return false }
        let normalizedFreshnessWindow = max(0, freshnessWindow)
        let normalizedFutureGraceWindow = max(0, futureGraceWindow)
        let age = now.timeIntervalSince(recordedAt)
        if age < -normalizedFutureGraceWindow {
            return false
        }
        if normalizedFreshnessWindow == 0 {
            return true
        }
        return age <= normalizedFreshnessWindow
    }

    nonisolated static func launchRescueAutoFollowupSelfHealBadge(
        _ snapshot: LaunchRescueAutoFollowupSelfHealSnapshot?
    ) -> String? {
        guard let snapshot else { return nil }
        switch snapshot.outcome {
        case .ready:
            return "Fresh"
        case .healed:
            return "Auto-Heal"
        case .failed:
            return "Needs Heal"
        case .unknown:
            return "Heal ?"
        }
    }

    nonisolated static func launchRescueAutoFollowupSelfHealStatusTitle(
        _ snapshot: LaunchRescueAutoFollowupSelfHealSnapshot?,
        now: Date = Date()
    ) -> String? {
        guard let snapshot else { return nil }
        let outcomeSummary: String
        switch snapshot.outcome {
        case .ready:
            outcomeSummary = "Fresh artifacts"
        case .healed:
            outcomeSummary = "Recovered missing artifacts"
        case .failed:
            outcomeSummary = "Artifacts still stale"
        case .unknown:
            outcomeSummary = "Outcome unknown"
        }
        return "Launch Rescue Auto Self-Heal: \(outcomeSummary) · Route: \(launchRescueAutoFollowupCommandTitle(snapshot.routeCommandID)) · Reason: \(launchRescueAutoTriggerSummary(snapshot.reasonToken)) · Freshness \(launchRescueAutoTriggerAtSummary(snapshot.recordedAt, now: now))"
    }

    nonisolated static func launchRescueAutoFollowupArtifactIsFresh(
        modifiedAt: Date?,
        now: Date = Date(),
        freshnessWindow: TimeInterval = launchRescueAutoFollowupArtifactFreshnessWindow
    ) -> Bool {
        guard let modifiedAt else { return false }
        let normalizedFreshnessWindow = max(0, freshnessWindow)
        if normalizedFreshnessWindow == 0 {
            return true
        }
        let age = now.timeIntervalSince(modifiedAt)
        if age < 0 {
            return true
        }
        return age <= normalizedFreshnessWindow
    }

    nonisolated static func launchRescueAutoTriggerFollowupCommandID(_ token: String?) -> String {
        let normalizedToken = launchRescueAutoTriggerReasonToken(token)
        switch normalizedToken {
        case LaunchRescueAutoTriggerReason.urgencyCritical.rawValue:
            return "run-fame-launch-rescue-burst"
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue:
            return "run-fame-next-move-copy-drafts"
        case LaunchRescueAutoTriggerReason.momentumAlert.rawValue:
            return "run-fame-launch-rescue-burst"
        case LaunchRescueAutoTriggerReason.momentumWatch.rawValue:
            return "run-fame-next-move-copy-drafts"
        case LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return "run-fame-recovery-checklist"
        default:
            return "run-fame-launch-control-brief"
        }
    }

    nonisolated static func launchRescueAutoTriggerFollowupCommandTitle(_ token: String?) -> String {
        launchRescueAutoFollowupCommandTitle(
            launchRescueAutoTriggerFollowupCommandID(token)
        )
    }

    nonisolated static func launchRescueAutoTriggerFollowupActionTitle(
        _ token: String?,
        selfHealAttentionBadge: String? = nil,
        routeBadge: String? = nil
    ) -> String {
        let baseTitle: String
        if let severityBadge = launchRescueAutoTriggerSeverityBadge(token) {
            baseTitle = "Run Launch Rescue Follow-up Now · \(severityBadge)"
        } else {
            baseTitle = "Run Launch Rescue Follow-up Now"
        }
        var titleBadges: [String] = []
        if let selfHealAttentionBadge {
            let cleanSelfHealAttentionBadge = selfHealAttentionBadge
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanSelfHealAttentionBadge.isEmpty {
                titleBadges.append(cleanSelfHealAttentionBadge)
            }
        }
        if let routeBadge {
            let cleanRouteBadge = routeBadge.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanRouteBadge.isEmpty {
                titleBadges.append(cleanRouteBadge)
            }
        }
        guard !titleBadges.isEmpty else { return baseTitle }
        return "\(baseTitle) · \(titleBadges.joined(separator: " · "))"
    }

    nonisolated static func launchRescueAutoTriggerFollowupActionSubtitle(
        _ token: String?,
        lastAutoTriggerAt: Date?,
        routeCommandIDOverride: String? = nil,
        now: Date = Date()
    ) -> String {
        let followupRouteDecision = launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: token,
            recommendedActionID: nil,
            commandIDOverride: routeCommandIDOverride
        )
        let routeTitle = launchRescueAutoFollowupCommandTitle(
            followupRouteDecision.resolvedCommandID
        )
        let summary = launchRescueAutoTriggerFollowupSummary(
            token,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        )
        if let summary {
            return "Route: \(routeTitle). \(summary)"
        }
        return "No auto trigger recorded yet. Route: \(routeTitle)."
    }

    nonisolated static func launchRescueAutoTriggerFollowupActionSystemImage(_ token: String?) -> String {
        let normalizedToken = launchRescueAutoTriggerReasonToken(token)
        switch normalizedToken {
        case LaunchRescueAutoTriggerReason.urgencyCritical.rawValue:
            return "bolt.trianglebadge.exclamationmark"
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue:
            return "bolt.badge.clock"
        case LaunchRescueAutoTriggerReason.momentumAlert.rawValue:
            return "arrow.triangle.2.circlepath.circle.fill"
        case LaunchRescueAutoTriggerReason.momentumWatch.rawValue:
            return "arrow.triangle.2.circlepath.circle"
        case LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return "checkmark.shield"
        default:
            return "bolt.badge.clock"
        }
    }

    nonisolated static func launchRescueAutoTriggerAtDiagnosticSummary(
        _ lastAutoTriggerAt: Date?
    ) -> String {
        guard let lastAutoTriggerAt else {
            return "No auto trigger time recorded yet."
        }
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: lastAutoTriggerAt)
    }

    nonisolated static func launchRescueFollowupOutcomeSuccessRatePercent(
        successes: Int,
        attempts: Int
    ) -> Int {
        let normalizedAttempts = max(0, attempts)
        guard normalizedAttempts > 0 else { return 0 }
        let normalizedSuccesses = min(
            normalizedAttempts,
            max(0, successes)
        )
        return Int(
            (
                Double(normalizedSuccesses)
                    / Double(normalizedAttempts)
                    * 100
            ).rounded()
        )
    }

    nonisolated static func launchRescueFollowupOutcomeWindowStatusTitle(
        label: String,
        successes: Int,
        attempts: Int
    ) -> String {
        let normalizedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayLabel = normalizedLabel.isEmpty ? "Window" : normalizedLabel
        let normalizedAttempts = max(0, attempts)
        guard normalizedAttempts > 0 else {
            return "\(displayLabel) no runs"
        }
        let normalizedSuccesses = min(
            normalizedAttempts,
            max(0, successes)
        )
        let successRate = launchRescueFollowupOutcomeSuccessRatePercent(
            successes: normalizedSuccesses,
            attempts: normalizedAttempts
        )
        return "\(displayLabel) \(normalizedSuccesses)/\(normalizedAttempts) success (\(successRate)%)"
    }

    nonisolated static func launchRescueFollowupOutcomeFreshnessSummary(
        _ lastOutcomeAt: Date?,
        now: Date = Date()
    ) -> String {
        guard let lastOutcomeAt else {
            return "No follow-up outcome time recorded yet."
        }
        return launchRescueAutoTriggerAtSummary(lastOutcomeAt, now: now)
    }

    nonisolated static func launchRescueFollowupOutcomeScoreboardStatusTitle(
        _ scoreboard: LaunchRescueFollowupOutcomeScoreboard,
        now: Date = Date()
    ) -> String {
        guard scoreboard.attemptsRolling > 0 else {
            return "Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet."
        }
        let status24h = launchRescueFollowupOutcomeWindowStatusTitle(
            label: "24h",
            successes: scoreboard.successes24h,
            attempts: scoreboard.attempts24h
        )
        let statusRolling = launchRescueFollowupOutcomeWindowStatusTitle(
            label: "Rolling",
            successes: scoreboard.successesRolling,
            attempts: scoreboard.attemptsRolling
        )
        let freshness = launchRescueFollowupOutcomeFreshnessSummary(
            scoreboard.lastOutcomeAt,
            now: now
        )
        return "Launch Rescue Follow-up Scoreboard: \(status24h) · \(statusRolling) · Freshness \(freshness)"
    }

    nonisolated static func launchRescueFollowupOutcomeCoachLane(
        _ scoreboard: LaunchRescueFollowupOutcomeScoreboard
    ) -> LaunchRescueFollowupCoachLane {
        guard scoreboard.attemptsRolling > 0 else {
            return .baseline
        }
        let successRate24h = launchRescueFollowupOutcomeSuccessRatePercent(
            successes: scoreboard.successes24h,
            attempts: scoreboard.attempts24h
        )
        let successRateRolling = launchRescueFollowupOutcomeSuccessRatePercent(
            successes: scoreboard.successesRolling,
            attempts: scoreboard.attemptsRolling
        )
        if scoreboard.attempts24h >= 3 && successRate24h < 50 {
            return .recovery
        }
        if scoreboard.attempts24h >= 2 && successRate24h >= 80 {
            return .winning
        }
        if scoreboard.attemptsRolling >= 3 && successRateRolling <= 40 {
            return .watch
        }
        if successRateRolling >= 70 {
            return .stable
        }
        return .calibration
    }

    nonisolated static func launchRescueFollowupOutcomeCoachSummary(
        _ scoreboard: LaunchRescueFollowupOutcomeScoreboard,
        triggerReason: String?,
        recoveryLaneStreak: Int = 0,
        recoveryChecklistCooldownMinutes: Int? = nil,
        recoveryChecklistCooldownMinutesRemaining: Int? = nil,
        now: Date = Date()
    ) -> String {
        let routeTitle = launchRescueAutoTriggerFollowupCommandTitle(triggerReason)
        let normalizedRecoveryLaneStreak = max(0, recoveryLaneStreak)
        let normalizedCooldownMinutes = max(0, recoveryChecklistCooldownMinutes ?? 0)
        let normalizedCooldownMinutesRemaining = max(
            0,
            recoveryChecklistCooldownMinutesRemaining ?? 0
        )
        let lane = launchRescueFollowupOutcomeCoachLane(scoreboard)
        guard lane != .baseline else {
            return "Baseline mode · execute \(routeTitle) once to seed outcomes."
        }
        let freshness = launchRescueFollowupOutcomeFreshnessSummary(
            scoreboard.lastOutcomeAt,
            now: now
        )
        switch lane {
        case .recovery:
            if normalizedRecoveryLaneStreak >= 2 {
                if normalizedCooldownMinutesRemaining > 0 {
                    if normalizedCooldownMinutes > 0 {
                        return "Recovery lane x\(normalizedRecoveryLaneStreak) · auto-checklist cooling down \(normalizedCooldownMinutesRemaining)m of \(normalizedCooldownMinutes)m after \(routeTitle) · Freshness \(freshness)"
                    }
                    return "Recovery lane x\(normalizedRecoveryLaneStreak) · auto-checklist cooling down \(normalizedCooldownMinutesRemaining)m after \(routeTitle) · Freshness \(freshness)"
                }
                if normalizedCooldownMinutes > 0 {
                    return "Recovery lane x\(normalizedRecoveryLaneStreak) · auto-checklist armed (\(normalizedCooldownMinutes)m window) after \(routeTitle) · Freshness \(freshness)"
                }
                return "Recovery lane x\(normalizedRecoveryLaneStreak) · auto-checklist armed after \(routeTitle) · Freshness \(freshness)"
            }
            return "Recovery lane · pair \(routeTitle) with Run Fame Recovery Checklist · Freshness \(freshness)"
        case .winning:
            return "Winning lane · keep \(routeTitle) cadence · Freshness \(freshness)"
        case .watch:
            return "Watch lane · run \(routeTitle), then tighten blockers · Freshness \(freshness)"
        case .stable:
            return "Stable lane · keep route and ship first block fast · Freshness \(freshness)"
        case .calibration:
            return "Calibration lane · run \(routeTitle) and review outcomes · Freshness \(freshness)"
        case .baseline:
            return "Baseline mode · execute \(routeTitle) once to seed outcomes."
        }
    }

    nonisolated static func launchRescueFollowupCoachRecoveryLaneStreakNext(
        currentStreak: Int,
        lane: LaunchRescueFollowupCoachLane
    ) -> Int {
        guard lane == .recovery else { return 0 }
        return max(0, currentStreak) + 1
    }

    nonisolated static func launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
        lastAutoRecoveryChecklistAt: Date?,
        now: Date = Date(),
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes * 60
        )
    ) -> Int? {
        let normalizedCooldown = max(0, cooldown)
        guard normalizedCooldown > 0 else { return nil }
        guard let lastAutoRecoveryChecklistAt else { return nil }
        let elapsed = now.timeIntervalSince(lastAutoRecoveryChecklistAt)
        let remainingSeconds = normalizedCooldown - elapsed
        guard remainingSeconds > 0 else { return nil }
        return max(1, Int(ceil(remainingSeconds / 60)))
    }

    nonisolated static func launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
        currentMinutes: Int,
        lane: LaunchRescueFollowupCoachLane,
        recoveryLaneStreak: Int,
        wasSuccessful: Bool,
        baselineMinutes: Int = AppDefaults
            .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes,
        stepMinutes: Int = AppDefaults
            .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesStep
    ) -> Int {
        let normalizedStepMinutes = max(1, stepMinutes)
        let normalizedBaselineMinutes = AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                baselineMinutes
            )
        let normalizedCurrentMinutes = AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                currentMinutes
            )
        let normalizedRecoveryLaneStreak = max(0, recoveryLaneStreak)

        if lane == .winning, wasSuccessful {
            return AppDefaults
                .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                    normalizedCurrentMinutes - normalizedStepMinutes
                )
        }

        if lane == .recovery,
           !wasSuccessful,
           normalizedRecoveryLaneStreak >= 2 {
            return AppDefaults
                .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                    normalizedCurrentMinutes + normalizedStepMinutes
                )
        }

        if normalizedCurrentMinutes > normalizedBaselineMinutes {
            return max(
                normalizedBaselineMinutes,
                AppDefaults
                    .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                        normalizedCurrentMinutes - normalizedStepMinutes
                    )
            )
        }

        if normalizedCurrentMinutes < normalizedBaselineMinutes {
            return min(
                normalizedBaselineMinutes,
                AppDefaults
                    .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                        normalizedCurrentMinutes + normalizedStepMinutes
                    )
            )
        }

        return normalizedCurrentMinutes
    }

    nonisolated static func shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
        lane: LaunchRescueFollowupCoachLane,
        recoveryLaneStreak: Int,
        routeCommandID: String,
        lastAutoRecoveryChecklistAt: Date? = nil,
        now: Date = Date(),
        cooldown: TimeInterval = TimeInterval(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes * 60
        )
    ) -> Bool {
        guard lane == .recovery,
              max(0, recoveryLaneStreak) >= 2 else {
            return false
        }
        guard launchRescueAutoFollowupCommandID(routeCommandID) != "run-fame-recovery-checklist" else {
            return false
        }
        return launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
            lastAutoRecoveryChecklistAt: lastAutoRecoveryChecklistAt,
            now: now,
            cooldown: cooldown
        ) == nil
    }

    nonisolated static func launchRescueFollowupOutcomeCoachStatusTitle(
        _ scoreboard: LaunchRescueFollowupOutcomeScoreboard,
        triggerReason: String?,
        recoveryLaneStreak: Int = 0,
        recoveryChecklistCooldownMinutes: Int? = nil,
        recoveryChecklistCooldownMinutesRemaining: Int? = nil,
        now: Date = Date()
    ) -> String {
        let summary = launchRescueFollowupOutcomeCoachSummary(
            scoreboard,
            triggerReason: triggerReason,
            recoveryLaneStreak: recoveryLaneStreak,
            recoveryChecklistCooldownMinutes: recoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining: recoveryChecklistCooldownMinutesRemaining,
            now: now
        )
        return "Launch Rescue Follow-up Coach: \(summary)"
    }

    nonisolated static func launchRescueFollowupRecoveryChecklistCooldownTrendTitle(
        currentMinutes: Int,
        baselineMinutes: Int = AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes
    ) -> String {
        let normalizedCurrentMinutes = AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                currentMinutes
            )
        let normalizedBaselineMinutes = AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                baselineMinutes
            )
        if normalizedCurrentMinutes < normalizedBaselineMinutes {
            return "Accelerating ↓"
        }
        if normalizedCurrentMinutes > normalizedBaselineMinutes {
            return "Tightening ↑"
        }
        return "Steady →"
    }

    nonisolated static func launchRescueFollowupMomentumBadge(
        _ scoreboard: LaunchRescueFollowupOutcomeScoreboard,
        recoveryLaneStreak: Int = 0,
        recoveryChecklistCooldownMinutes: Int = AppDefaults
            .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes,
        recoveryChecklistCooldownMinutesRemaining: Int? = nil
    ) -> String? {
        let lane = launchRescueFollowupOutcomeCoachLane(scoreboard)
        guard lane != .baseline else { return nil }

        let normalizedRecoveryLaneStreak = max(0, recoveryLaneStreak)
        let laneTitle: String = switch lane {
        case .baseline:
            "Baseline"
        case .winning:
            "Winning"
        case .recovery:
            normalizedRecoveryLaneStreak >= 2 ? "Recovery x\(normalizedRecoveryLaneStreak)" : "Recovery"
        case .watch:
            "Watch"
        case .stable:
            "Stable"
        case .calibration:
            "Calibration"
        }

        let normalizedCooldownMinutes = AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                recoveryChecklistCooldownMinutes
            )
        let normalizedCooldownMinutesRemaining = max(
            0,
            recoveryChecklistCooldownMinutesRemaining ?? 0
        )
        let cooldownTitle = normalizedCooldownMinutesRemaining > 0
            ? "CD \(normalizedCooldownMinutesRemaining)/\(normalizedCooldownMinutes)m"
            : "CD \(normalizedCooldownMinutes)m"
        let trendTitle = launchRescueFollowupRecoveryChecklistCooldownTrendTitle(
            currentMinutes: normalizedCooldownMinutes
        )
        return "\(laneTitle) · \(cooldownTitle) · \(trendTitle)"
    }

    nonisolated static func launchRescueFollowupMomentumStatusTitle(
        _ scoreboard: LaunchRescueFollowupOutcomeScoreboard,
        recoveryLaneStreak: Int = 0,
        recoveryChecklistCooldownMinutes: Int = AppDefaults
            .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes,
        recoveryChecklistCooldownMinutesRemaining: Int? = nil
    ) -> String? {
        guard let badge = launchRescueFollowupMomentumBadge(
            scoreboard,
            recoveryLaneStreak: recoveryLaneStreak,
            recoveryChecklistCooldownMinutes: recoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining: recoveryChecklistCooldownMinutesRemaining
        ) else {
            return nil
        }
        return "Launch Rescue Follow-up Momentum: \(badge)"
    }

    nonisolated static func launchRescueAutoTriggerFollowupMenuToolTip(
        _ token: String?,
        lastAutoTriggerAt: Date?,
        selfHealStatusTitle: String? = nil,
        selfHealAttentionStatusTitle: String? = nil,
        followupOutcomeScoreboardStatusTitle: String? = nil,
        followupOutcomeCoachStatusTitle: String? = nil,
        followupOutcomeMomentumStatusTitle: String? = nil,
        routeCommandIDOverride: String? = nil,
        now: Date = Date()
    ) -> String {
        let baseSubtitle = launchRescueAutoTriggerFollowupActionSubtitle(
            token,
            lastAutoTriggerAt: lastAutoTriggerAt,
            routeCommandIDOverride: routeCommandIDOverride,
            now: now
        )
        let followupRouteDecision = launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: token,
            recommendedActionID: nil,
            commandIDOverride: routeCommandIDOverride
        )
        var lines = [baseSubtitle]
        appendCleanStatusLine(
            launchRescueAutoFollowupRouteDecisionTraceLine(
                defaultCommandID: followupRouteDecision.defaultCommandID,
                resolvedCommandID: followupRouteDecision.resolvedCommandID
            ),
            to: &lines
        )
        appendCleanStatusLine(selfHealStatusTitle, to: &lines)
        appendCleanStatusLine(selfHealAttentionStatusTitle, to: &lines)
        appendCleanStatusLine(followupOutcomeScoreboardStatusTitle, to: &lines)
        appendCleanStatusLine(followupOutcomeCoachStatusTitle, to: &lines)
        appendCleanStatusLine(followupOutcomeMomentumStatusTitle, to: &lines)
        return lines.joined(separator: "\n")
    }

    nonisolated static func launchRescueFollowupOutcomeHistory(
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey
    ) -> [LaunchRescueFollowupOutcomeSample] {
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([LaunchRescueFollowupOutcomeSample].self, from: data) else {
            return []
        }
        return history
            .filter { sample in
                sample.recordedAt.isFinite && sample.recordedAt > 0
            }
            .sorted { lhs, rhs in
                lhs.recordedAt < rhs.recordedAt
            }
    }

    nonisolated static func launchRescueFollowupOutcomeWindow(
        _ history: [LaunchRescueFollowupOutcomeSample],
        now: Date,
        windowHours: Int = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryWindowHours
    ) -> [LaunchRescueFollowupOutcomeSample] {
        let windowSeconds = TimeInterval(max(1, windowHours) * 60 * 60)
        let nowStamp = now.timeIntervalSince1970
        let cutoffStamp = nowStamp - windowSeconds
        return history.filter { sample in
            sample.recordedAt >= cutoffStamp && sample.recordedAt <= nowStamp + 60
        }
    }

    nonisolated static func launchRescueFollowupOutcomeScoreboard(
        now: Date,
        defaults: UserDefaults = .standard,
        totalCountKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey,
        successCountKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey,
        lastOutcomeAtKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey,
        lastSuccessAtKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey,
        lastFailureAtKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey,
        historyKey: String = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey,
        historyWindowHours: Int = AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryWindowHours
    ) -> LaunchRescueFollowupOutcomeScoreboard {
        let attemptsRolling = max(0, defaults.integer(forKey: totalCountKey))
        let successesRolling = min(
            attemptsRolling,
            max(0, defaults.integer(forKey: successCountKey))
        )
        let window = launchRescueFollowupOutcomeWindow(
            launchRescueFollowupOutcomeHistory(
                defaults: defaults,
                historyKey: historyKey
            ),
            now: now,
            windowHours: historyWindowHours
        )
        let attempts24h = window.count
        let successes24h = min(
            attempts24h,
            max(
                0,
                window.reduce(0) { partialResult, sample in
                    partialResult + (sample.wasSuccess ? 1 : 0)
                }
            )
        )
        return LaunchRescueFollowupOutcomeScoreboard(
            attempts24h: attempts24h,
            successes24h: successes24h,
            attemptsRolling: attemptsRolling,
            successesRolling: successesRolling,
            lastOutcomeAt: launchRescueAutoTriggerAt(
                defaults.object(forKey: lastOutcomeAtKey)
            ),
            lastSuccessAt: launchRescueAutoTriggerAt(
                defaults.object(forKey: lastSuccessAtKey)
            ),
            lastFailureAt: launchRescueAutoTriggerAt(
                defaults.object(forKey: lastFailureAtKey)
            )
        )
    }

    nonisolated static func launchRescueAutoTriggerFollowupSummary(
        _ token: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String? {
        guard let followupStatusProfile = launchRescueAutoTriggerFollowupStatusProfile(token) else {
            return nil
        }
        guard lastAutoTriggerAt != nil else {
            return followupStatusProfile.actionLine
        }
        if launchRescueAutoTriggerFollowupIsPriorityWindowActive(
            lastAutoTriggerAt: lastAutoTriggerAt,
            activeWindowMinutes: followupStatusProfile.priorityWindowMinutes,
            now: now
        ) {
            return "Priority window active. \(followupStatusProfile.actionLine)"
        }
        return "Checkpoint. \(followupStatusProfile.actionLine)"
    }

    nonisolated static func launchRescueAutoTriggerFollowupStatusTitle(
        _ token: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String {
        guard let summary = launchRescueAutoTriggerFollowupSummary(
            token,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        ) else {
            return "Launch Rescue Auto Follow-up: Stand by."
        }
        return "Launch Rescue Auto Follow-up: \(summary)"
    }

    nonisolated static func launchRescueAutoTriggerFollowupStatusSubtitleHint(
        _ token: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String? {
        guard let summary = launchRescueAutoTriggerFollowupSummary(
            token,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        ) else {
            return nil
        }
        return "Follow-up: \(summary)"
    }

    nonisolated static func launchRescueAutoTriggerFollowupMenuBadge(
        _ token: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> String? {
        guard let followupStatusProfile = launchRescueAutoTriggerFollowupStatusProfile(token) else {
            return nil
        }
        if launchRescueAutoTriggerFollowupIsPriorityWindowActive(
            lastAutoTriggerAt: lastAutoTriggerAt,
            activeWindowMinutes: followupStatusProfile.priorityWindowMinutes,
            now: now
        ) {
            return "Now \(followupStatusProfile.menuBadge)"
        }
        return followupStatusProfile.menuBadge
    }

    nonisolated private static func launchRescueAutoTriggerFollowupStatusProfile(
        _ token: String?
    ) -> (
        actionLine: String,
        menuBadge: String,
        priorityWindowMinutes: Int
    )? {
        switch launchRescueAutoTriggerReasonToken(token) {
        case LaunchRescueAutoTriggerReason.urgencyCritical.rawValue:
            return ("Ship a recovery update now.", "Ship Update", 30)
        case LaunchRescueAutoTriggerReason.urgencyHigh.rawValue:
            return ("Run next move and ship the first block now.", "Next Move", 45)
        case LaunchRescueAutoTriggerReason.momentumAlert.rawValue:
            return ("Run launch rescue + next move before another dip.", "Rescue + Next", 60)
        case LaunchRescueAutoTriggerReason.momentumWatch.rawValue:
            return ("Stage rescue draft before next escalation.", "Stage Rescue", 90)
        case LaunchRescueAutoTriggerReason.pressurePersistence.rawValue:
            return ("Close one blocker before next health pulse.", "Close Blocker", 120)
        default:
            return nil
        }
    }

    nonisolated private static func launchRescueAutoTriggerFollowupIsPriorityWindowActive(
        lastAutoTriggerAt: Date?,
        activeWindowMinutes: Int,
        now: Date = Date()
    ) -> Bool {
        guard let lastAutoTriggerAt else { return false }
        let elapsedMinutes = max(0, Int(now.timeIntervalSince(lastAutoTriggerAt) / 60))
        return elapsedMinutes <= max(0, activeWindowMinutes)
    }

    nonisolated static func launchRescueAutoFollowupMenuRouteBadge(_ commandID: String?) -> String? {
        switch launchRescueAutoFollowupCommandID(commandID) {
        case "run-fame-launch-rescue-burst":
            return "Route Burst"
        case "run-fame-next-move-copy-drafts":
            return "Route Next Move"
        case "run-fame-recovery-checklist":
            return "Route Checklist"
        case "run-fame-launch-control-brief":
            return "Route Brief"
        default:
            return nil
        }
    }

    nonisolated static func launchRescueAutoFollowupResolvedRouteDecision(
        triggerReason: String?,
        recommendedActionID: String?,
        commandIDOverride: String? = nil
    ) -> (
        defaultCommandID: String,
        resolvedCommandID: String
    ) {
        let defaultCommandID = launchRescueAutoTriggerFollowupCommandID(triggerReason)
        let normalizedCommandIDOverride = launchRescueAutoFollowupCommandID(commandIDOverride)
        if normalizedCommandIDOverride != "none" {
            return (
                defaultCommandID: defaultCommandID,
                resolvedCommandID: normalizedCommandIDOverride
            )
        }
        let normalizedRecommendedActionID = launchRescueAutoFollowupCommandID(recommendedActionID)
        if normalizedRecommendedActionID != "none" {
            return (
                defaultCommandID: defaultCommandID,
                resolvedCommandID: normalizedRecommendedActionID
            )
        }
        return (
            defaultCommandID: defaultCommandID,
            resolvedCommandID: defaultCommandID
        )
    }

    nonisolated static func launchRescueAutoFollowupRouteBadgeForResolvedDecision(
        defaultCommandID: String,
        resolvedCommandID: String
    ) -> String? {
        guard resolvedCommandID != defaultCommandID else {
            return nil
        }
        return launchRescueAutoFollowupMenuRouteBadge(resolvedCommandID)
    }

    nonisolated static func launchRescueAutoFollowupRouteDecisionSummary(
        defaultCommandID: String,
        resolvedCommandID: String
    ) -> String {
        let defaultCommandTitle = launchRescueAutoFollowupCommandTitle(defaultCommandID)
        guard resolvedCommandID != defaultCommandID else {
            return "Default route \(defaultCommandTitle)"
        }
        let resolvedCommandTitle = launchRescueAutoFollowupCommandTitle(resolvedCommandID)
        return "Escalated to \(resolvedCommandTitle) from \(defaultCommandTitle)"
    }

    nonisolated static func launchRescueAutoFollowupRouteDecisionStatusTitle(
        defaultCommandID: String,
        resolvedCommandID: String,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        let summary = launchRescueAutoFollowupRouteDecisionSummary(
            defaultCommandID: defaultCommandID,
            resolvedCommandID: resolvedCommandID
        )
        guard let cleanSelfHealAttentionBadge = cleanStatusLine(selfHealAttentionBadge) else {
            return "Launch Rescue Auto Follow-up Route Decision: \(summary)."
        }
        return "Launch Rescue Auto Follow-up Route Decision: \(summary) · \(cleanSelfHealAttentionBadge)."
    }

    nonisolated static func launchRescueAutoFollowupRouteDecisionTraceLine(
        defaultCommandID: String,
        resolvedCommandID: String
    ) -> String? {
        guard resolvedCommandID != defaultCommandID else {
            return nil
        }
        return "Route decision: \(launchRescueAutoFollowupRouteDecisionSummary(defaultCommandID: defaultCommandID, resolvedCommandID: resolvedCommandID))."
    }

    nonisolated static func launchRescueAutoFollowupBadgeForResolvedDecision(
        triggerReason: String?,
        lastAutoTriggerAt: Date?,
        defaultCommandID: String,
        resolvedCommandID: String,
        now: Date = Date()
    ) -> String? {
        if let routeBadge = launchRescueAutoFollowupRouteBadgeForResolvedDecision(
            defaultCommandID: defaultCommandID,
            resolvedCommandID: resolvedCommandID
        ) {
            return routeBadge
        }
        return launchRescueAutoTriggerFollowupMenuBadge(
            triggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        )
    }

    nonisolated static func launchRescueAutoFollowupRouteDecisionStatusTitle(
        triggerReason: String?,
        lastAutoTriggerAt: Date?,
        activityItems: [ActivityLogItem],
        now: Date = Date()
    ) -> String {
        let defaultActionID = launchRescueAutoTriggerFollowupCommandID(triggerReason)
        guard let issueToken = launchRescueAutoSelfHealAttentionIssueToken(
            triggerReason: triggerReason,
            activityItems: activityItems,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        ) else {
            return launchRescueAutoFollowupRouteDecisionStatusTitle(
                defaultCommandID: defaultActionID,
                resolvedCommandID: defaultActionID
            )
        }
        let signalBadge = launchRescueAutoSelfHealAttentionSignalBadge(
            issueToken: issueToken,
            triggerReason: triggerReason,
            issueStreak: 1,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
        let routeDecision = launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: triggerReason,
            recommendedActionID: signalBadge.recommendedActionID
        )
        return launchRescueAutoFollowupRouteDecisionStatusTitle(
            defaultCommandID: routeDecision.defaultCommandID,
            resolvedCommandID: routeDecision.resolvedCommandID,
            selfHealAttentionBadge: signalBadge.title
        )
    }

    nonisolated static func autoOpsBundleStatusActionTitle(
        _ status: AutoOpsBundleEscalationStatus,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        let baseTitle: String = switch status {
        case .disabled:
            "Fame Auto Bundle: Enable"
        case .ready:
            "Fame Auto Bundle: Run Now"
        case .coolingDown(let minutesRemaining):
            "Fame Auto Bundle: Cooldown \(minutesRemaining)m"
        }
        return launchControlMenuTitleWithLaunchRescueContext(
            baseTitle,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func autoOpsBundleStatusActionSubtitle(
        _ status: AutoOpsBundleEscalationStatus,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        let baseSubtitle: String = switch status {
        case .disabled:
            "Auto bundle is off. Open Settings > Fame Ops."
        case .ready:
            "Auto bundle is ready on escalation. Run once now."
        case .coolingDown(let minutesRemaining):
            "Next auto run in about \(minutesRemaining) min. Run once now."
        }
        return launchRescueSnapshotActionSubtitle(
            baseSubtitle,
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func autoOpsBundleStatusActionSystemImage(
        _ status: AutoOpsBundleEscalationStatus
    ) -> String {
        switch status {
        case .disabled:
            return "gearshape"
        case .ready:
            return "shippingbox.circle"
        case .coolingDown:
            return "hourglass.circle"
        }
    }

    nonisolated static func launchRescueBurstAutoStatusActionTitle(
        _ status: AutoOpsBundleEscalationStatus,
        modeMomentumStreak: Int = 0,
        triggerSeverityBadge: String? = nil,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        let baseTitle: String = switch status {
        case .disabled:
            "Launch Rescue Auto: Enable"
        case .ready:
            "Launch Rescue Auto: Run Now"
        case .coolingDown(let minutesRemaining):
            "Launch Rescue Auto: Cooldown \(minutesRemaining)m"
        }
        var titleBadges: [String] = []
        if let titleBadge = launchRescueModeMomentumCueTitleBadge(modeMomentumStreak: modeMomentumStreak) {
            titleBadges.append(titleBadge)
        }
        if let triggerSeverityBadge {
            let cleanTriggerSeverityBadge = triggerSeverityBadge.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanTriggerSeverityBadge.isEmpty {
                titleBadges.append(cleanTriggerSeverityBadge)
            }
        }
        guard !titleBadges.isEmpty else {
            return launchControlMenuTitleWithLaunchRescueContext(
                baseTitle,
                routeBadge: routeBadge,
                selfHealAttentionBadge: selfHealAttentionBadge
            )
        }
        return launchControlMenuTitleWithLaunchRescueContext(
            "\(baseTitle) · \(titleBadges.joined(separator: " · "))",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueModeMomentumCueSeverity(
        modeMomentumStreak: Int,
        watchThreshold: Int = 2,
        alertThreshold: Int = 3
    ) -> LaunchRescueModeMomentumCueSeverity {
        let cooldownStreak = abs(min(0, modeMomentumStreak))
        let normalizedWatchThreshold = max(2, watchThreshold)
        let normalizedAlertThreshold = max(normalizedWatchThreshold + 1, alertThreshold)
        if cooldownStreak >= normalizedAlertThreshold {
            return .alert
        }
        if cooldownStreak >= normalizedWatchThreshold {
            return .watch
        }
        return .none
    }

    nonisolated static func launchRescueModeMomentumCueHint(
        modeMomentumStreak: Int
    ) -> String? {
        let cooldownStreak = abs(min(0, modeMomentumStreak))
        switch launchRescueModeMomentumCueSeverity(modeMomentumStreak: modeMomentumStreak) {
        case .none:
            return nil
        case .watch:
            return "Cooldown streak x\(cooldownStreak) · stage rescue now"
        case .alert:
            return "Cooldown streak x\(cooldownStreak) · rescue priority"
        }
    }

    nonisolated static func launchRescueModeMomentumCueTitleBadge(
        modeMomentumStreak: Int
    ) -> String? {
        let cooldownStreak = abs(min(0, modeMomentumStreak))
        switch launchRescueModeMomentumCueSeverity(modeMomentumStreak: modeMomentumStreak) {
        case .none:
            return nil
        case .watch:
            return "Watch x\(cooldownStreak)"
        case .alert:
            return "Alert x\(cooldownStreak)"
        }
    }

    nonisolated static func launchRescueBurstActionSubtitle(
        modeMomentumStreak: Int = 0,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil
    ) -> String {
        var parts = ["Generate launch countdown + next-move handoff + recovery checklist"]
        if let cueHint = launchRescueModeMomentumCueHint(modeMomentumStreak: modeMomentumStreak) {
            parts.append(cueHint)
        }
        return launchRescueSnapshotActionSubtitle(
            parts.joined(separator: " · "),
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueBurstRunMenuStatusTitle(
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchControlMenuTitleWithLaunchRescueContext(
            "Run Launch Rescue Burst",
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueBurstRunMenuStatusToolTip(
        modeMomentumStreak: Int = 0,
        routeBadge: String?,
        selfHealAttentionBadge: String?
    ) -> String {
        launchRescueBurstActionSubtitle(
            modeMomentumStreak: modeMomentumStreak,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueBurstAutoStatusActionSubtitle(
        _ status: AutoOpsBundleEscalationStatus,
        modeMomentumStreak: Int = 0,
        lastAutoTriggerReason: String? = nil,
        lastAutoTriggerAt: Date? = nil,
        followupRouteDecisionTraceLine: String? = nil,
        routeBadge: String? = nil,
        selfHealAttentionBadge: String? = nil,
        now: Date = Date()
    ) -> String {
        let baseSubtitle: String = switch status {
        case .disabled:
            "Launch rescue auto-burst is off. Open Settings > Fame Ops."
        case .ready:
            "Launch rescue auto-burst is ready on launch escalation. Run once now."
        case .coolingDown(let minutesRemaining):
            "Next auto rescue burst in about \(minutesRemaining) min. Open latest or run now."
        }
        var parts = [baseSubtitle]
        if let triggerHint = launchRescueAutoTriggerStatusSubtitleHint(lastAutoTriggerReason) {
            parts.append(triggerHint)
        }
        if let severityHint = launchRescueAutoTriggerSeveritySubtitleHint(lastAutoTriggerReason) {
            parts.append(severityHint)
        }
        if let triggerTimeHint = launchRescueAutoTriggerAtStatusSubtitleHint(
            lastAutoTriggerAt,
            now: now
        ) {
            parts.append(triggerTimeHint)
        }
        if let followupHint = launchRescueAutoTriggerFollowupStatusSubtitleHint(
            lastAutoTriggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        ) {
            parts.append(followupHint)
        }
        if let followupRouteDecisionTraceLine = cleanStatusLine(followupRouteDecisionTraceLine) {
            parts.append(followupRouteDecisionTraceLine)
        }
        if let cueHint = launchRescueModeMomentumCueHint(modeMomentumStreak: modeMomentumStreak) {
            parts.append(cueHint)
        }
        return launchRescueSnapshotActionSubtitle(
            parts.joined(separator: " · "),
            followupMomentumBadge: nil,
            routeBadge: routeBadge,
            selfHealAttentionBadge: selfHealAttentionBadge
        )
    }

    nonisolated static func launchRescueAutoTriggerReasonResetTokenForRescueRun(
        announce: Bool
    ) -> String? {
        announce ? "none" : nil
    }

    nonisolated static func launchRescueAutoTriggerAtShouldResetForRescueRun(
        announce: Bool
    ) -> Bool {
        announce
    }

    nonisolated static func launchRescueBurstAutoStatusActionSystemImage(
        _ status: AutoOpsBundleEscalationStatus
    ) -> String {
        switch status {
        case .disabled:
            return "gearshape"
        case .ready:
            return "bolt.shield"
        case .coolingDown:
            return "hourglass.circle"
        }
    }

    private func morningDayStamp(now: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now)
    }

    private func buildMorningFameBrief(now: Date = Date()) throws -> (markdown: String, url: URL) {
        let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
        let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
        let ledgerText = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        let entries = FameSnapshotRollup.parseLedger(ledgerText)
        guard !entries.isEmpty else {
            throw FameBriefBuildError.noSnapshots
        }

        let brief = FameSnapshotRollup.morningBrief(entries: entries, now: now)
        let briefURL = try FameSnapshotArchive.saveMorningBrief(markdown: brief, now: now)
        return (brief, briefURL)
    }

    private func buildMiddayFameBrief(now: Date = Date()) throws -> (markdown: String, url: URL) {
        let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
        let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
        let ledgerText = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        let entries = FameSnapshotRollup.parseLedger(ledgerText)
        guard !entries.isEmpty else {
            throw FameBriefBuildError.noSnapshots
        }

        let brief = FameSnapshotRollup.middayBrief(entries: entries, now: now)
        let briefURL = try FameSnapshotArchive.saveMiddayBrief(markdown: brief, now: now)
        return (brief, briefURL)
    }

    private func buildEveningFameBrief(now: Date = Date()) throws -> (markdown: String, url: URL) {
        let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
        let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
        let ledgerText = (try? String(contentsOf: ledgerURL, encoding: .utf8)) ?? ""
        let entries = FameSnapshotRollup.parseLedger(ledgerText)
        guard !entries.isEmpty else {
            throw FameBriefBuildError.noSnapshots
        }

        let brief = FameSnapshotRollup.eveningBrief(entries: entries, now: now)
        let briefURL = try FameSnapshotArchive.saveEveningBrief(markdown: brief, now: now)
        return (brief, briefURL)
    }

    private func runFameMorningBriefOnLaunch(skipForSetupChecklist: Bool) {
        let now = Date()
        let todayStamp = morningDayStamp(now: now)
        let decision = Self.morningBriefLaunchDecision(
            isEnabled: settings.fameMorningBriefOnLaunch,
            quietMode: settings.fameMorningBriefQuietMode,
            skipForSetupChecklist: skipForSetupChecklist,
            lastRunStamp: UserDefaults.standard.string(forKey: fameMorningBriefLastRunDayKey),
            todayStamp: todayStamp
        )

        switch decision {
        case .skipDisabled:
            return
        case .skipSetupChecklist:
            recordActivity(category: "launch", detail: "run-fame-morning-brief-launch-skipped-setup")
            return
        case .skipAlreadyRanToday:
            recordActivity(category: "launch", detail: "run-fame-morning-brief-launch-skipped-already")
            return
        case .run(let quietMode):
            do {
                let brief = try buildMorningFameBrief(now: now)
                UserDefaults.standard.set(todayStamp, forKey: fameMorningBriefLastRunDayKey)

                if quietMode {
                    recordActivity(category: "launch", detail: "run-fame-morning-brief-launch-quiet")
                    return
                }

                readerState.answerText = brief.markdown
                readerState.remember(text: "", answer: brief.markdown)
                copyToClipboardWithReadyPrompt(
                    brief.markdown,
                    readyMessage: "Morning fame brief ready.",
                    copyMessage: "Copied morning fame brief."
                )
                readerWindow.show()
                recordActivity(category: "launch", detail: "run-fame-morning-brief-launch")
            } catch FameBriefBuildError.noSnapshots {
                recordActivity(category: "launch", detail: "run-fame-morning-brief-launch-no-snapshots")
            } catch {
                recordActivity(category: "launch", detail: "run-fame-morning-brief-launch-error")
            }
        }
    }

    private func runFameMorningBrief() {
        do {
            let now = Date()
            let brief = try buildMorningFameBrief(now: now)
            UserDefaults.standard.set(morningDayStamp(now: now), forKey: fameMorningBriefLastRunDayKey)
            readerState.answerText = brief.markdown
            readerState.remember(text: "", answer: brief.markdown)
            copyToClipboardWithReadyPrompt(
                brief.markdown,
                readyMessage: "Morning fame brief ready.",
                copyMessage: "Copied morning fame brief."
            )
            readerWindow.show()
            revealURL(brief.url)
            recordActivity(category: "share", detail: "run-fame-morning-brief")
        } catch FameBriefBuildError.noSnapshots {
            readerState.errorText = "No snapshots yet. Run Fame Sprint + Save Snapshot first."
            readerState.petSay("Run snapshot first.", mood: .ready)
            readerState.pulse()
            recordActivity(category: "share", detail: "run-fame-morning-brief-empty")
        } catch {
            readerState.errorText = "Could not run morning fame brief."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-morning-brief-error")
        }
    }

    private func runFameMiddayBrief() {
        do {
            let now = Date()
            let brief = try buildMiddayFameBrief(now: now)
            readerState.answerText = brief.markdown
            readerState.remember(text: "", answer: brief.markdown)
            copyToClipboardWithReadyPrompt(
                brief.markdown,
                readyMessage: "Midday fame brief ready.",
                copyMessage: "Copied midday fame brief."
            )
            readerWindow.show()
            revealURL(brief.url)
            recordActivity(category: "share", detail: "run-fame-midday-brief")
        } catch FameBriefBuildError.noSnapshots {
            readerState.errorText = "No snapshots yet. Run Fame Sprint + Save Snapshot first."
            readerState.petSay("Run snapshot first.", mood: .ready)
            readerState.pulse()
            recordActivity(category: "share", detail: "run-fame-midday-brief-empty")
        } catch {
            readerState.errorText = "Could not run midday fame brief."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-midday-brief-error")
        }
    }

    private func runFameEveningBrief() {
        do {
            let now = Date()
            let brief = try buildEveningFameBrief(now: now)
            readerState.answerText = brief.markdown
            readerState.remember(text: "", answer: brief.markdown)
            copyToClipboardWithReadyPrompt(
                brief.markdown,
                readyMessage: "Evening fame brief ready.",
                copyMessage: "Copied evening fame brief."
            )
            readerWindow.show()
            revealURL(brief.url)
            recordActivity(category: "share", detail: "run-fame-evening-brief")
        } catch FameBriefBuildError.noSnapshots {
            readerState.errorText = "No snapshots yet. Run Fame Sprint + Save Snapshot first."
            readerState.petSay("Run snapshot first.", mood: .ready)
            readerState.pulse()
            recordActivity(category: "share", detail: "run-fame-evening-brief-empty")
        } catch {
            readerState.errorText = "Could not run evening fame brief."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-evening-brief-error")
        }
    }

    private func openFameSnapshotFolder() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            revealURL(directoryURL)
            readerState.petSay("Opened fame snapshot folder.", mood: .happy)
            readerState.errorText = ""
            recordActivity(category: "open", detail: "open-fame-snapshot-folder")
        } catch {
            readerState.errorText = "Could not open fame snapshot folder."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "open", detail: "open-fame-snapshot-folder-error")
        }
    }

    private func runFameWeeklyRollup() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let rollup = FameSnapshotRollup.markdownFromLedger(at: ledgerURL)
            readerState.answerText = rollup
            readerState.remember(text: "", answer: rollup)
            copyToClipboardWithReadyPrompt(
                rollup,
                readyMessage: "Weekly rollup ready.",
                copyMessage: "Copied weekly rollup."
            )
            readerWindow.show()
            if FileManager.default.fileExists(atPath: ledgerURL.path) {
                revealURL(ledgerURL)
            }
            recordActivity(category: "share", detail: "run-fame-weekly-rollup")
        } catch {
            readerState.errorText = "Could not run weekly fame rollup."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-weekly-rollup-error")
        }
    }

    private func runFame24hQueue() {
        do {
            let now = Date()
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let mission = FameSnapshotRollup.dailyMissionFromLedger(
                at: ledgerURL,
                now: now
            )
            let missionURL = try FameSnapshotArchive.saveDailyMission(
                markdown: mission,
                now: now
            )
            readerState.answerText = mission
            readerState.remember(text: "", answer: mission)
            copyToClipboardWithReadyPrompt(
                mission,
                readyMessage: "Daily mission ready.",
                copyMessage: "Copied daily mission."
            )
            readerWindow.show()
            revealURL(missionURL)
            recordActivity(category: "share", detail: "run-fame-24h-queue")
        } catch {
            readerState.errorText = "Could not run daily fame mission."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-24h-queue-error")
        }
    }

    private func runFameCommandCenter() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let commandCenter = FameSnapshotRollup.commandCenterFromLedger(at: ledgerURL)
            let commandCenterURL = try FameSnapshotArchive.saveCommandCenter(markdown: commandCenter)
            readerState.answerText = commandCenter
            readerState.remember(text: "", answer: commandCenter)
            copyToClipboardWithReadyPrompt(
                commandCenter,
                readyMessage: "Command center ready.",
                copyMessage: "Copied fame command center."
            )
            readerWindow.show()
            revealURL(commandCenterURL)
            recordActivity(category: "share", detail: "run-fame-command-center")
        } catch {
            readerState.errorText = "Could not run fame command center."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-command-center-error")
        }
    }

    private func runFameBreakthroughForecast() {
        do {
            let now = Date()
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let forecast = FameSnapshotRollup.breakthroughForecastFromLedger(
                at: ledgerURL,
                now: now
            )
            let forecastURL = try FameSnapshotArchive.saveBreakthroughForecast(
                markdown: forecast,
                now: now
            )
            readerState.answerText = forecast
            readerState.remember(text: "", answer: forecast)
            copyToClipboardWithReadyPrompt(
                forecast,
                readyMessage: "Breakthrough forecast ready.",
                copyMessage: "Copied fame breakthrough forecast."
            )
            readerWindow.show()
            revealURL(forecastURL)
            recordActivity(category: "share", detail: "run-fame-breakthrough-forecast")
        } catch {
            readerState.errorText = "Could not run fame breakthrough forecast."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-breakthrough-forecast-error")
        }
    }

    @objc private func runWarRoom() {
        do {
            guard let handoffURL = try FameSnapshotArchive.latestNextMoveHandoffURL() else {
                readerState.errorText = Self.fameNextMoveRunFirstPrompt
                recordActivity(category: "share", detail: "run-war-room-missing-handoff")
                return
            }
            let handoff = (try? String(contentsOf: handoffURL, encoding: .utf8)) ?? ""
            let lines = handoff.split(whereSeparator: \.isNewline)
            let pick: (String) -> String? = { prefix in
                guard let line = lines.first(where: { $0.hasPrefix(prefix) }) else { return nil }
                return line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            }
            let headingPrefix = "# Founder Fame Next Move Handoff - "
            let weekLabel = lines
                .first(where: { $0.hasPrefix(headingPrefix) })
                .map { String($0.dropFirst(headingPrefix.count)) }
                ?? "current"
            let checklistTarget = pick("Checklist target: ")
                ?? "Monday Publish Checklist \(weekLabel)"
            let selectedCommand = pick("Selected command: ")
                ?? pick("- In-app move: ")
                ?? "run-fame-next-move"
            let routeSignal = pick("Route signal: ") ?? "Monitor"
            let proofStatus = "PASS (in-app)"

            let warRoom = """
            <!-- founder-fame-war-room -->

            # Founder Fame War Room - \(weekLabel)

            ## Snapshot
            - Route alignment signal: \(routeSignal)
            - Proof-loop verification: \(proofStatus)

            ## Launch Control
            - Run now: \(selectedCommand)
            - Artifact link: \(handoffURL.lastPathComponent)
            - Checklist target: \(checklistTarget)

            ## Checklist Marker Block
            ```text
            weekly-growth-founder-fame-war-room
            week: \(weekLabel)
            selected_command: \(selectedCommand)
            artifact_link: \(handoffURL.lastPathComponent)
            checklist_target: \(checklistTarget)
            proof_status: \(proofStatus)
            route_signal: \(routeSignal)
            ```
            """
            let warRoomURL = try FameSnapshotArchive.saveWarRoom(markdown: warRoom)

            readerState.answerText = warRoom
            readerState.remember(text: "", answer: warRoom)
            copyToClipboardWithReadyPrompt(
                warRoom,
                readyMessage: "War room ready.",
                copyMessage: "Copied war room."
            )
            readerWindow.show()
            revealURL(warRoomURL)
            recordActivity(category: "share", detail: "run-war-room")
        } catch {
            readerState.errorText = "Could not run war room."
            recordActivity(category: "share", detail: "run-war-room-error")
        }
    }

    private func runFameAutoBundleStatusAction() {
        runFameAutoBundleStatusAction(
            now: Date(),
            defaults: .standard,
            runNowHandler: nil
        )
    }

    private func runFameAutoBundleStatusAction(
        now: Date,
        defaults: UserDefaults,
        runNowHandler: (() -> Void)?
    ) {
        let status = autoOpsBundleEscalationStatus(now: now, defaults: defaults)
        switch status {
        case .disabled:
            let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
            settingsWindow.show()
            readerState.petSay(
                Self.autoOpsBundleStatusDisabledPrompt(
                    routeBadge: promptContext.routeBadge,
                    selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                    followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
                ),
                mood: .ready
            )
            recordActivity(category: "support", detail: "run-fame-auto-bundle-status-settings")
        case .ready, .coolingDown:
            if let runNowHandler {
                runNowHandler()
            } else {
                runFameOpsBundle()
            }
            recordActivity(category: "support", detail: "run-fame-auto-bundle-status-run-now")
        }
    }

    private func runFameLaunchRescueBurstAutoStatusAction() {
        runFameLaunchRescueBurstAutoStatusAction(
            now: Date(),
            defaults: .standard,
            latestLaunchRescueBurstURLProvider: nil,
            runNowHandler: nil
        )
    }

    private func runFameLaunchRescueBurstAutoStatusAction(
        now: Date,
        defaults: UserDefaults,
        latestLaunchRescueBurstURLProvider: (() throws -> URL?)?,
        runNowHandler: (() -> Void)?
    ) {
        let status = launchRescueBurstAutoStatus(now: now, defaults: defaults)
        switch status {
        case .disabled:
            let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
            settingsWindow.show()
            readerState.petSay(
                Self.launchRescueAutoStatusDisabledPrompt(
                    routeBadge: promptContext.routeBadge,
                    selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                    followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
                ),
                mood: .ready
            )
            recordActivity(category: "support", detail: "run-fame-launch-rescue-auto-status-settings")
        case .ready:
            if let runNowHandler {
                runNowHandler()
            } else {
                _ = runFameLaunchRescueBurst(source: "status-action")
            }
            recordActivity(category: "support", detail: "run-fame-launch-rescue-auto-status-run-now")
        case .coolingDown(let minutesRemaining):
            openLatestLaunchRescueBurst(
                autoStatusCooldownMinutesRemaining: minutesRemaining,
                now: now,
                defaults: defaults,
                latestURLProvider: latestLaunchRescueBurstURLProvider
            )
            recordActivity(category: "support", detail: "run-fame-launch-rescue-auto-status-open-latest")
        }
    }

    private func runFameLaunchRescueFollowupNow(
        routeCommandIDOverride: String? = nil,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let triggerReason = fameLaunchRescueBurstLastAutoTriggerReason(defaults: defaults)
        let normalizedTriggerReason = Self.launchRescueAutoTriggerReasonToken(triggerReason)
        let lastAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt(defaults: defaults)
        let selfHealAttentionSnapshot = launchRescueAutoSelfHealAttentionMenuSnapshot(
            triggerReason: triggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        )
        let routeDecision = Self.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: triggerReason,
            recommendedActionID: selfHealAttentionSnapshot?.recommendedActionID,
            commandIDOverride: routeCommandIDOverride
        )
        let normalizedRouteCommandID = routeDecision.resolvedCommandID
        let wasSuccessful: Bool

        switch normalizedRouteCommandID {
        case "run-fame-launch-rescue-burst":
            wasSuccessful = runFameLaunchRescueBurst(
                source: "followup-\(ActivityLogCommand.safeID(normalizedTriggerReason))",
                now: now
            )
        case "run-fame-next-move-copy-drafts":
            runFameNextMove(followup: .copyDraftPack)
            wasSuccessful = true
        case "run-fame-recovery-checklist":
            runFameRecoveryChecklist()
            wasSuccessful = true
        default:
            runFameLaunchControlBrief(now: now)
            wasSuccessful = true
        }

        setFameLaunchRescueBurstLastFollowupReason(normalizedTriggerReason, defaults: defaults)
        setFameLaunchRescueBurstLastFollowupCommandID(normalizedRouteCommandID, defaults: defaults)
        setFameLaunchRescueBurstLastFollowupAt(now, defaults: defaults)
        let followupScoreboard = recordLaunchRescueFollowupOutcome(
            wasSuccessful: wasSuccessful,
            now: now,
            defaults: defaults
        )
        let coachLane = Self.launchRescueFollowupOutcomeCoachLane(followupScoreboard)
        let recoveryLaneStreak = updateLaunchRescueFollowupCoachState(
            lane: coachLane,
            defaults: defaults
        )
        let recoveryChecklistCooldownMinutes = launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
            defaults: defaults
        )
        let recoveryChecklistCooldown = launchRescueFollowupRecoveryChecklistAutoCooldown(
            defaults: defaults
        )
        let lastAutoRecoveryChecklistAt = launchRescueFollowupCoachLastAutoRecoveryChecklistAt(
            defaults: defaults
        )
        let recoveryChecklistEscalationArmed = Self.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
            lane: coachLane,
            recoveryLaneStreak: recoveryLaneStreak,
            routeCommandID: normalizedRouteCommandID,
            now: now,
            cooldown: 0
        )
        if Self.shouldAutoRunLaunchRescueFollowupRecoveryChecklist(
            lane: coachLane,
            recoveryLaneStreak: recoveryLaneStreak,
            routeCommandID: normalizedRouteCommandID,
            lastAutoRecoveryChecklistAt: lastAutoRecoveryChecklistAt,
            now: now,
            cooldown: recoveryChecklistCooldown
        ) {
            runFameRecoveryChecklist()
            setLaunchRescueFollowupCoachLastAutoRecoveryChecklistAt(
                now,
                defaults: defaults
            )
            recordActivity(
                category: "support",
                detail: "run-fame-launch-rescue-followup-now-auto-recovery-checklist-streak-\(recoveryLaneStreak)-\(ActivityLogCommand.safeID(normalizedRouteCommandID))"
            )
        } else if recoveryChecklistEscalationArmed,
                  let cooldownMinutesRemaining = Self.launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
                      lastAutoRecoveryChecklistAt: lastAutoRecoveryChecklistAt,
                      now: now,
                      cooldown: recoveryChecklistCooldown
                  ) {
            recordActivity(
                category: "support",
                detail: "run-fame-launch-rescue-followup-now-auto-recovery-checklist-cooldown-\(cooldownMinutesRemaining)m-streak-\(recoveryLaneStreak)-\(ActivityLogCommand.safeID(normalizedRouteCommandID))"
            )
        }
        let nextRecoveryChecklistCooldownMinutes =
            Self.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: recoveryChecklistCooldownMinutes,
                lane: coachLane,
                recoveryLaneStreak: recoveryLaneStreak,
                wasSuccessful: wasSuccessful
            )
        if nextRecoveryChecklistCooldownMinutes != recoveryChecklistCooldownMinutes {
            setLaunchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
                nextRecoveryChecklistCooldownMinutes,
                defaults: defaults
            )
            recordActivity(
                category: "support",
                detail: "run-fame-launch-rescue-followup-now-auto-recovery-checklist-cooldown-tune-\(recoveryChecklistCooldownMinutes)m-to-\(nextRecoveryChecklistCooldownMinutes)m-\(coachLane.rawValue)-streak-\(recoveryLaneStreak)-\(wasSuccessful ? "success" : "failure")"
            )
        }
        updateLaunchRescueAutoMenuStatus(now: now)
        recordActivity(
            category: "support",
            detail: "run-fame-launch-rescue-followup-now-\(ActivityLogCommand.safeID(normalizedTriggerReason))-\(ActivityLogCommand.safeID(normalizedRouteCommandID))"
        )
    }

    private func persistLaunchRescueFollowupAutoOutcome(
        triggerReason: String,
        routeCommandID: String,
        wasSuccessful: Bool,
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        cooldownTuneActivityPrefix: String
    ) {
        setFameLaunchRescueBurstLastFollowupReason(
            triggerReason,
            defaults: defaults
        )
        setFameLaunchRescueBurstLastFollowupCommandID(
            routeCommandID,
            defaults: defaults
        )
        setFameLaunchRescueBurstLastFollowupAt(now, defaults: defaults)
        if routeCommandID == "run-fame-recovery-checklist",
           wasSuccessful {
            setLaunchRescueFollowupCoachLastAutoRecoveryChecklistAt(
                now,
                defaults: defaults
            )
        }
        let followupScoreboard = recordLaunchRescueFollowupOutcome(
            wasSuccessful: wasSuccessful,
            now: now,
            defaults: defaults
        )
        let coachLane = Self.launchRescueFollowupOutcomeCoachLane(followupScoreboard)
        let recoveryLaneStreak = updateLaunchRescueFollowupCoachState(
            lane: coachLane,
            defaults: defaults
        )
        let recoveryChecklistCooldownMinutes = launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
            defaults: defaults
        )
        let nextRecoveryChecklistCooldownMinutes =
            Self.launchRescueFollowupRecoveryChecklistCooldownMinutesNext(
                currentMinutes: recoveryChecklistCooldownMinutes,
                lane: coachLane,
                recoveryLaneStreak: recoveryLaneStreak,
                wasSuccessful: wasSuccessful
            )
        if nextRecoveryChecklistCooldownMinutes != recoveryChecklistCooldownMinutes {
            setLaunchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
                nextRecoveryChecklistCooldownMinutes,
                defaults: defaults
            )
            recordActivity(
                category: "support",
                detail: "\(cooldownTuneActivityPrefix)-\(recoveryChecklistCooldownMinutes)m-to-\(nextRecoveryChecklistCooldownMinutes)m-\(coachLane.rawValue)-streak-\(recoveryLaneStreak)-\(wasSuccessful ? "success" : "failure")"
            )
        }
        updateLaunchRescueAutoMenuStatus(now: now)
    }

    private func launchRescueAutoFollowupArtifactModifiedAt(_ url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [
            .contentModificationDateKey,
            .creationDateKey
        ])
        return values?.contentModificationDate ?? values?.creationDate
    }

    private func hasFreshLaunchRescueAutoFollowupArtifact(
        latestURL: () throws -> URL?,
        now: Date = Date()
    ) -> Bool {
        do {
            guard let artifactURL = try latestURL() else { return false }
            return Self.launchRescueAutoFollowupArtifactIsFresh(
                modifiedAt: launchRescueAutoFollowupArtifactModifiedAt(artifactURL),
                now: now
            )
        } catch {
            return false
        }
    }

    private func runFameLaunchRescueFollowupNowAutoSelfHealNextMoveArtifacts(
        hasNextMoveHandoff: Bool,
        hasNextMoveDraftPack: Bool,
        now: Date = Date()
    ) {
        guard !hasNextMoveHandoff || !hasNextMoveDraftPack else { return }

        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            var handoffMarkdown: String?

            if hasNextMoveHandoff,
               let handoffURL = try FameSnapshotArchive.latestNextMoveHandoffURL(
                   baseDirectory: directoryURL
               ) {
                handoffMarkdown = (try? String(contentsOf: handoffURL, encoding: .utf8)) ?? ""
            } else {
                let commandID = fameNextMoveMenuCommandID()
                let commandLabel = Self.fameNextMoveCommandLabel(commandID)
                let handoff = FameSnapshotRollup.nextMoveHandoff(
                    commandID: commandID,
                    commandLabel: commandLabel,
                    signal: famePulseAlertSignal(),
                    transition: famePulseLatestTransition(),
                    scorecard: fameDailyScorecardState()
                )
                _ = try FameSnapshotArchive.saveNextMoveHandoff(
                    markdown: handoff,
                    now: now,
                    baseDirectory: directoryURL
                )
                handoffMarkdown = handoff
                recordActivity(
                    category: "saved",
                    detail: "save-fame-next-move-handoff-auto-self-heal-\(ActivityLogCommand.safeID(commandID))"
                )
            }

            guard !hasNextMoveDraftPack else { return }

            if handoffMarkdown == nil,
               let handoffURL = try FameSnapshotArchive.latestNextMoveHandoffURL(
                   baseDirectory: directoryURL
               ) {
                handoffMarkdown = (try? String(contentsOf: handoffURL, encoding: .utf8)) ?? ""
            }

            if let handoffMarkdown,
               let draftPack = FameSnapshotRollup.nextMoveDraftPack(from: handoffMarkdown) {
                _ = saveNextMoveDraftPackArtifact(
                    markdown: draftPack,
                    now: now,
                    baseDirectory: directoryURL,
                    activityDetailBase: "save-fame-next-move-draft-pack-auto-self-heal"
                )
            } else {
                recordActivity(
                    category: "saved",
                    detail: "save-fame-next-move-draft-pack-auto-self-heal-missing"
                )
            }
        } catch {
            recordActivity(
                category: "saved",
                detail: "save-fame-next-move-handoff-auto-self-heal-error"
            )
        }
    }

    private func runFameLaunchRescueFollowupNowAutoSelfHeal(
        triggerReason: String,
        routeCommandID: String,
        now: Date = Date()
    ) -> Bool {
        let normalizedTriggerReason = Self.launchRescueAutoTriggerReasonToken(triggerReason)
        let normalizedRouteCommandID = Self.launchRescueAutoFollowupCommandID(routeCommandID)

        var hasLaunchRescueBurst = hasFreshLaunchRescueAutoFollowupArtifact(
            latestURL: { try FameSnapshotArchive.latestLaunchRescueBurstURL() },
            now: now
        )
        var hasNextMoveHandoff = hasFreshLaunchRescueAutoFollowupArtifact(
            latestURL: { try FameSnapshotArchive.latestNextMoveHandoffURL() },
            now: now
        )
        var hasNextMoveDraftPack = hasFreshLaunchRescueAutoFollowupArtifact(
            latestURL: { try FameSnapshotArchive.latestNextMoveDraftPackURL() },
            now: now
        )
        var hasLaunchControlBrief = hasFreshLaunchRescueAutoFollowupArtifact(
            latestURL: { try FameSnapshotArchive.latestLaunchControlBriefURL() },
            now: now
        )
        var hasRecoveryChecklist = hasFreshLaunchRescueAutoFollowupArtifact(
            latestURL: { try FameSnapshotArchive.latestRecoveryChecklistURL() },
            now: now
        )

        let didDetectMissingArtifacts = Self.launchRescueAutoFollowupArtifactsMissing(
            routeCommandID: normalizedRouteCommandID,
            hasLaunchRescueBurst: hasLaunchRescueBurst,
            hasNextMoveHandoff: hasNextMoveHandoff,
            hasNextMoveDraftPack: hasNextMoveDraftPack,
            hasLaunchControlBrief: hasLaunchControlBrief,
            hasRecoveryChecklist: hasRecoveryChecklist
        )

        if didDetectMissingArtifacts {
            switch normalizedRouteCommandID {
            case "run-fame-launch-rescue-burst":
                _ = runFameLaunchRescueBurst(
                    source: "auto-followup-self-heal-\(ActivityLogCommand.safeID(normalizedTriggerReason))",
                    announce: false,
                    now: now
                )
            case "run-fame-next-move-copy-drafts":
                runFameLaunchRescueFollowupNowAutoSelfHealNextMoveArtifacts(
                    hasNextMoveHandoff: hasNextMoveHandoff,
                    hasNextMoveDraftPack: hasNextMoveDraftPack,
                    now: now
                )
            case "run-fame-launch-control-brief":
                let brief = makeFameLaunchControlBrief(now: now)
                _ = saveLaunchControlBriefArtifact(markdown: brief, now: now)
            case "run-fame-recovery-checklist":
                do {
                    let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
                    let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
                    _ = autoRecoveryChecklistSummary(ledgerURL: ledgerURL, now: now)
                } catch {
                    recordActivity(
                        category: "support",
                        detail: "run-fame-launch-rescue-followup-now-auto-self-heal-\(ActivityLogCommand.safeID(normalizedTriggerReason))-run-fame-recovery-checklist-error"
                    )
                }
            default:
                break
            }

            hasLaunchRescueBurst = hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestLaunchRescueBurstURL() },
                now: now
            )
            hasNextMoveHandoff = hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestNextMoveHandoffURL() },
                now: now
            )
            hasNextMoveDraftPack = hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestNextMoveDraftPackURL() },
                now: now
            )
            hasLaunchControlBrief = hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestLaunchControlBriefURL() },
                now: now
            )
            hasRecoveryChecklist = hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestRecoveryChecklistURL() },
                now: now
            )
        }

        let hasMissingArtifactsAfterSelfHeal = Self.launchRescueAutoFollowupArtifactsMissing(
            routeCommandID: normalizedRouteCommandID,
            hasLaunchRescueBurst: hasLaunchRescueBurst,
            hasNextMoveHandoff: hasNextMoveHandoff,
            hasNextMoveDraftPack: hasNextMoveDraftPack,
            hasLaunchControlBrief: hasLaunchControlBrief,
            hasRecoveryChecklist: hasRecoveryChecklist
        )
        let wasSuccessful = Self.launchRescueAutoFollowupArtifactsReady(
            routeCommandID: normalizedRouteCommandID,
            hasLaunchRescueBurst: hasLaunchRescueBurst,
            hasNextMoveHandoff: hasNextMoveHandoff,
            hasNextMoveDraftPack: hasNextMoveDraftPack,
            hasLaunchControlBrief: hasLaunchControlBrief,
            hasRecoveryChecklist: hasRecoveryChecklist
        )
        let outcomeToken: String
        if wasSuccessful {
            outcomeToken = didDetectMissingArtifacts && !hasMissingArtifactsAfterSelfHeal
                ? "healed"
                : "ready"
        } else {
            outcomeToken = "failed"
        }
        recordActivity(
            category: "support",
            detail: Self.launchRescueAutoFollowupSelfHealActivityDetail(
                reasonToken: normalizedTriggerReason,
                routeCommandID: normalizedRouteCommandID,
                outcome: outcomeToken
            )
        )
        return wasSuccessful
    }

    @discardableResult
    private func runFameLaunchRescueFollowupNowAuto(
        triggerReason: LaunchRescueAutoTriggerReason,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        let normalizedTriggerReason = Self.launchRescueAutoTriggerReasonToken(triggerReason.rawValue)
        let routeCommandID = Self.launchRescueAutoTriggerFollowupCommandID(
            normalizedTriggerReason
        )
        let normalizedRouteCommandID = Self.launchRescueAutoFollowupCommandID(routeCommandID)
        let wasSuccessful = runFameLaunchRescueFollowupNowAutoSelfHeal(
            triggerReason: normalizedTriggerReason,
            routeCommandID: normalizedRouteCommandID,
            now: now
        )

        persistLaunchRescueFollowupAutoOutcome(
            triggerReason: normalizedTriggerReason,
            routeCommandID: normalizedRouteCommandID,
            wasSuccessful: wasSuccessful,
            now: now,
            defaults: defaults,
            cooldownTuneActivityPrefix: "run-fame-launch-rescue-followup-now-auto-\(ActivityLogCommand.safeID(normalizedTriggerReason))-cooldown-tune"
        )
        recordActivity(
            category: "support",
            detail: Self.launchRescueAutoFollowupAutoActivityDetail(
                reasonToken: normalizedTriggerReason,
                wasSuccessful: wasSuccessful
            )
        )
        return wasSuccessful
    }

    @discardableResult
    private func runFameLaunchRescueFollowupNowAutoPressurePersistence(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        let normalizedTriggerReason = LaunchRescueAutoTriggerReason.pressurePersistence.rawValue
        let routeCommandID = Self.launchRescueAutoTriggerFollowupCommandID(
            normalizedTriggerReason
        )
        let normalizedRouteCommandID = Self.launchRescueAutoFollowupCommandID(routeCommandID)
        guard normalizedRouteCommandID == "run-fame-recovery-checklist" else {
            recordActivity(
                category: "support",
                detail: "run-fame-launch-rescue-followup-now-auto-pressure-persistence-route-\(ActivityLogCommand.safeID(normalizedRouteCommandID))"
            )
            return false
        }

        let wasSuccessful = runFameLaunchRescueFollowupNowAutoSelfHeal(
            triggerReason: normalizedTriggerReason,
            routeCommandID: normalizedRouteCommandID,
            now: now
        )

        persistLaunchRescueFollowupAutoOutcome(
            triggerReason: normalizedTriggerReason,
            routeCommandID: normalizedRouteCommandID,
            wasSuccessful: wasSuccessful,
            now: now,
            defaults: defaults,
            cooldownTuneActivityPrefix: "run-fame-launch-rescue-followup-now-auto-pressure-persistence-cooldown-tune"
        )
        recordActivity(
            category: "support",
            detail: Self.launchRescueAutoFollowupAutoPressureActivityDetail(
                wasSuccessful: wasSuccessful
            )
        )
        return wasSuccessful
    }

    private func toggleFameLaunchThresholdAlerts(source: String, announce: Bool = true) {
        let nextValue = !settings.fameLaunchThresholdAlertsEnabled
        settings.fameLaunchThresholdAlertsEnabled = nextValue
        setFameLaunchThresholdAlertsSnoozeUntil(nil)
        updateFameLaunchThresholdAlertsMenuTitle()

        let message: String
        let tint: NSColor
        if nextValue {
            message = "Launch threshold alerts on."
            tint = .systemGreen
        } else {
            message = "Launch threshold alerts muted."
            tint = .systemGray
        }

        if announce {
            readerState.petSay(message, mood: .ready)
            readerState.pulse()
            flashStatus(
                symbol: Self.fameLaunchThresholdAlertsToggleSystemImage(nextValue),
                tint: tint,
                length: 0.18
            )
        }
        recordActivity(
            category: "support",
            detail: "toggle-fame-launch-threshold-alerts-\(nextValue ? "on" : "muted")-\(source)"
        )
    }

    @discardableResult
    private func snoozeFameLaunchThresholdAlerts(
        minutes: Int,
        source: String,
        announce: Bool = true
    ) -> Int {
        let now = Date()
        let snoozeUntil = now.addingTimeInterval(TimeInterval(max(1, minutes) * 60))
        settings.fameLaunchThresholdAlertsEnabled = false
        setFameLaunchThresholdAlertsSnoozeUntil(snoozeUntil)

        let snoozeMinutes = Self.fameLaunchThresholdAlertsSnoozeMinutesRemaining(
            snoozeUntil: snoozeUntil,
            now: now
        ) ?? max(1, minutes)
        if announce {
            readerState.petSay("Launch threshold alerts snoozed \(snoozeMinutes)m.", mood: .ready)
            readerState.pulse()
            flashStatus(symbol: "hourglass.circle.fill", tint: .systemOrange, length: 0.18)
        }
        recordActivity(
            category: "support",
            detail: "snooze-fame-launch-threshold-alerts-\(snoozeMinutes)m-\(source)"
        )
        return snoozeMinutes
    }

    private func applyFameLaunchThresholdAlertsQuickActionFeedback(
        action: FameLaunchThresholdAlertsSnoozeReminderMenuTapAction,
        resolvedMinutes: Int? = nil
    ) {
        readerState.petSay(
            Self.fameLaunchThresholdAlertsQuickActionMessage(
                action: action,
                resolvedMinutes: resolvedMinutes
            ),
            mood: .ready
        )
        readerState.pulse()

        switch action {
        case .unmuteNow:
            flashStatus(symbol: "bell.badge.checkmark", tint: .systemGreen, length: 0.2)
        case .extend:
            flashStatus(symbol: "hourglass.circle.fill", tint: .systemOrange, length: 0.2)
        }

        recordActivity(
            category: "support",
            detail: "launch-threshold-alerts-quick-action-\(Self.fameLaunchThresholdAlertsQuickActionActivityToken(action: action, resolvedMinutes: resolvedMinutes))"
        )
    }

    private func handleReaderAutoOpsBundleStatusTap() {
        handleReaderAutoOpsBundleStatusTap(
            now: Date(),
            defaults: .standard,
            runNowHandler: nil,
            emitFeedback: true
        )
    }

    private func handleReaderAutoOpsBundleStatusTap(
        now: Date,
        defaults: UserDefaults,
        runNowHandler: (() -> Void)?,
        emitFeedback: Bool
    ) {
        let status = autoOpsBundleEscalationStatus(now: now, defaults: defaults)
        if emitFeedback {
            effects.hit(.tap, settings: settings, haptic: .alignment)
            switch status {
            case .disabled:
                flashStatus(symbol: "gearshape.fill", tint: .systemGray, length: 0.12)
            case .ready:
                flashStatus(symbol: "shippingbox.circle", tint: .systemGreen, length: 0.12)
            case .coolingDown:
                flashStatus(symbol: "hourglass.circle", tint: .systemOrange, length: 0.12)
            }
        }

        recordActivity(category: "support", detail: "reader-auto-bundle-status-pill-tap")
        runFameAutoBundleStatusAction(
            now: now,
            defaults: defaults,
            runNowHandler: runNowHandler
        )
    }

    private func handleReaderLaunchRescueAutoStatusTap() {
        handleReaderLaunchRescueAutoStatusTap(
            now: Date(),
            defaults: .standard,
            latestLaunchRescueBurstURLProvider: nil,
            runNowHandler: nil,
            emitFeedback: true
        )
    }

    private func handleReaderLaunchRescueAutoStatusTap(
        now: Date,
        defaults: UserDefaults,
        latestLaunchRescueBurstURLProvider: (() throws -> URL?)?,
        runNowHandler: (() -> Void)?,
        emitFeedback: Bool
    ) {
        let status = launchRescueBurstAutoStatus(now: now, defaults: defaults)
        if emitFeedback {
            effects.hit(.tap, settings: settings, haptic: .alignment)
            switch status {
            case .disabled:
                flashStatus(symbol: "gearshape.fill", tint: .systemGray, length: 0.12)
            case .ready:
                flashStatus(symbol: "bolt.circle", tint: .systemGreen, length: 0.12)
            case .coolingDown:
                flashStatus(symbol: "hourglass.circle", tint: .systemOrange, length: 0.12)
            }
        }

        recordActivity(category: "support", detail: "reader-launch-rescue-auto-status-pill-tap")
        runFameLaunchRescueBurstAutoStatusAction(
            now: now,
            defaults: defaults,
            latestLaunchRescueBurstURLProvider: latestLaunchRescueBurstURLProvider,
            runNowHandler: runNowHandler
        )
    }

    private func runFameOpsBundle() {
        do {
            let now = Date()
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")

            let commandCenter = FameSnapshotRollup.commandCenterFromLedger(at: ledgerURL)
            let checkpoint = FameSnapshotRollup.dailyCheckpointFromLedger(at: ledgerURL)
            let timeline = FameSnapshotRollup.riskTimelineFromLedger(at: ledgerURL)
            let pulseNudge = FameSnapshotRollup.pulseNudgeFromLedger(at: ledgerURL)
            let files = try FameSnapshotArchive.saveOpsBundleFiles(
                commandCenterMarkdown: commandCenter,
                checkpointMarkdown: checkpoint,
                riskTimelineMarkdown: timeline,
                pulseNudgeMarkdown: pulseNudge,
                now: now
            )
            setAutoOpsBundleLastRunAt(now)

            let stamp = FameSnapshotArchive.timestamp(now: now)
            let summary = Self.fameOpsBundleSummaryMarkdown(
                bundleStamp: stamp,
                commandCenterArtifactName: files.commandCenterURL.lastPathComponent,
                checkpointArtifactName: files.checkpointURL.lastPathComponent,
                riskTimelineArtifactName: files.riskTimelineURL.lastPathComponent,
                pulseNudgeArtifactName: files.pulseNudgeURL.lastPathComponent
            )

            readerState.answerText = summary
            readerState.remember(text: "", answer: summary)
            copyToClipboardWithReadyPrompt(
                summary,
                readyMessage: "Ops bundle ready.",
                copyMessage: "Copied fame ops bundle."
            )
            readerWindow.show()
            revealURL(files.commandCenterURL)
            refreshFamePulseBadge()
            recordActivity(category: "share", detail: "run-fame-ops-bundle")
        } catch {
            readerState.errorText = "Could not run fame ops bundle."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-ops-bundle-error")
        }
    }

    private func runFameDailyCheckpoint() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let checkpoint = FameSnapshotRollup.dailyCheckpointFromLedger(at: ledgerURL)
            let checkpointURL = try FameSnapshotArchive.saveDailyCheckpoint(markdown: checkpoint)
            readerState.answerText = checkpoint
            readerState.remember(text: "", answer: checkpoint)
            copyToClipboardWithReadyPrompt(
                checkpoint,
                readyMessage: "Daily checkpoint ready.",
                copyMessage: "Copied daily checkpoint."
            )
            readerWindow.show()
            revealURL(checkpointURL)
            recordActivity(category: "share", detail: "run-fame-daily-checkpoint")
        } catch {
            readerState.errorText = "Could not run daily fame checkpoint."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-daily-checkpoint-error")
        }
    }

    private func runFameDailyScorecard() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let scorecard = FameSnapshotRollup.dailyScorecardFromLedger(at: ledgerURL)
            let scorecardURL = try FameSnapshotArchive.saveDailyScorecard(markdown: scorecard)
            readerState.answerText = scorecard
            readerState.remember(text: "", answer: scorecard)
            copyToClipboardWithReadyPrompt(
                scorecard,
                readyMessage: "Daily scorecard ready.",
                copyMessage: "Copied daily scorecard."
            )
            readerWindow.show()
            revealURL(scorecardURL)
            recordActivity(category: "share", detail: "run-fame-daily-scorecard")
        } catch {
            readerState.errorText = "Could not run daily fame scorecard."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-daily-scorecard-error")
        }
    }

    private func runFameEscalationNudge() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let nudge = FameSnapshotRollup.escalationNudgeFromLedger(at: ledgerURL)
            let nudgeURL = try FameSnapshotArchive.saveEscalationNudge(markdown: nudge.markdown)
            readerState.answerText = nudge.markdown
            readerState.remember(text: "", answer: nudge.markdown)
            copyToClipboardWithReadyPrompt(
                nudge.markdown,
                readyMessage: "Escalation nudge ready.",
                copyMessage: "Copied escalation nudge.",
                mood: .ready
            )
            readerWindow.show()
            revealURL(nudgeURL)
            recordActivity(category: "share", detail: "run-fame-escalation-nudge")
        } catch {
            readerState.errorText = "Could not run fame escalation nudge."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-escalation-nudge-error")
        }
    }

    private func runFameRecoverySprint() {
        do {
            let now = Date()
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let recovery = FameSnapshotRollup.recoverySprintFromLedger(at: ledgerURL, now: now)
            let recoveryURL = try FameSnapshotArchive.saveRecoverySprint(markdown: recovery, now: now)
            let answer = Self.recoverySprintRunSummaryMarkdown(
                recoveryMarkdown: recovery,
                checklistAutoFollowupSummaryMarkdown: autoRecoveryChecklistSummary(
                    ledgerURL: ledgerURL,
                    now: now
                )
            )
            readerState.answerText = answer
            readerState.remember(text: "", answer: answer)
            copyToClipboardWithReadyPrompt(
                answer,
                readyMessage: "Recovery sprint ready.",
                copyMessage: "Copied fame recovery sprint."
            )
            readerWindow.show()
            revealURL(recoveryURL)
            refreshFamePulseBadge()
            recordActivity(category: "share", detail: "run-fame-recovery-sprint")
        } catch {
            readerState.errorText = "Could not run fame recovery sprint."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-recovery-sprint-error")
        }
    }

    private func autoRecoveryChecklistSummary(ledgerURL: URL, now: Date) -> String? {
        do {
            let checklist = FameSnapshotRollup.recoveryChecklistFromLedger(at: ledgerURL, now: now)
            let checklistURL = try FameSnapshotArchive.saveRecoveryChecklist(markdown: checklist, now: now)
            let summary = Self.autoRecoveryChecklistSummaryMarkdown(
                checklistArtifactName: checklistURL.lastPathComponent,
                proofPackSummaryMarkdown: autoRecoveryProofPackSummary(
                    ledgerURL: ledgerURL,
                    now: now
                )
            )
            recordActivity(category: "saved", detail: "run-fame-recovery-checklist-auto")
            return summary
        } catch {
            recordActivity(category: "saved", detail: "run-fame-recovery-checklist-auto-error")
            return nil
        }
    }

    private func autoRecoveryProofPackSummary(ledgerURL: URL, now: Date) -> String? {
        do {
            let pack = FameSnapshotRollup.recoveryProofPackFromLedger(at: ledgerURL, now: now)
            let packURL = try FameSnapshotArchive.saveRecoveryProofPack(markdown: pack, now: now)
            recordActivity(category: "saved", detail: "run-fame-recovery-proof-pack-auto")
            return Self.autoRecoveryProofPackSummaryMarkdown(
                proofPackArtifactName: packURL.lastPathComponent
            )
        } catch {
            recordActivity(category: "saved", detail: "run-fame-recovery-proof-pack-auto-error")
            return nil
        }
    }

    private func runFameRecoveryChecklist() {
        do {
            let now = Date()
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let checklist = FameSnapshotRollup.recoveryChecklistFromLedger(at: ledgerURL, now: now)
            let checklistURL = try FameSnapshotArchive.saveRecoveryChecklist(markdown: checklist, now: now)
            let answer = Self.recoveryChecklistRunSummaryMarkdown(
                checklistMarkdown: checklist,
                proofPackAutoFollowupSummaryMarkdown: autoRecoveryProofPackSummary(
                    ledgerURL: ledgerURL,
                    now: now
                )
            )
            readerState.answerText = answer
            readerState.remember(text: "", answer: answer)
            copyToClipboardWithReadyPrompt(
                answer,
                readyMessage: "Recovery checklist ready.",
                copyMessage: "Copied recovery checklist.",
                mood: .ready
            )
            readerWindow.show()
            revealURL(checklistURL)
            recordActivity(category: "share", detail: "run-fame-recovery-checklist")
        } catch {
            readerState.errorText = "Could not run recovery checklist."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-recovery-checklist-error")
        }
    }

    private func runFameRecoveryProofPack() {
        do {
            let now = Date()
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let pack = FameSnapshotRollup.recoveryProofPackFromLedger(at: ledgerURL, now: now)
            let packURL = try FameSnapshotArchive.saveRecoveryProofPack(markdown: pack, now: now)
            readerState.answerText = pack
            readerState.remember(text: "", answer: pack)
            copyToClipboardWithReadyPrompt(
                pack,
                readyMessage: "Recovery proof pack ready.",
                copyMessage: "Copied recovery proof pack."
            )
            readerWindow.show()
            revealURL(packURL)
            recordActivity(category: "share", detail: "run-fame-recovery-proof-pack")
        } catch {
            readerState.errorText = "Could not run recovery proof pack."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-recovery-proof-pack-error")
        }
    }

    private func runFameRiskTimeline() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            var timeline = FameSnapshotRollup.riskTimelineFromLedger(at: ledgerURL)
            if let latestRecoveryURL = try FameSnapshotArchive.latestRecoverySprintURL() {
                timeline += """

                \(Self.latestRecoverySprintSummaryMarkdown(
                    recoverySprintArtifactName: latestRecoveryURL.lastPathComponent
                ))
                """
            }
            let timelineURL = try FameSnapshotArchive.saveRiskTimeline(markdown: timeline)
            readerState.answerText = timeline
            readerState.remember(text: "", answer: timeline)
            copyToClipboardWithReadyPrompt(
                timeline,
                readyMessage: "Risk timeline ready.",
                copyMessage: "Copied fame risk timeline."
            )
            readerWindow.show()
            revealURL(timelineURL)
            recordActivity(category: "share", detail: "run-fame-risk-timeline")
        } catch {
            readerState.errorText = "Could not run fame risk timeline."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-risk-timeline-error")
        }
    }

    private func runFameOperatorDashboard() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            var dashboard = FameSnapshotRollup.operatorDashboardFromLedger(at: ledgerURL)
            if let latestRecoveryURL = try FameSnapshotArchive.latestRecoverySprintURL() {
                dashboard += """

                \(Self.latestRecoverySprintSummaryMarkdown(
                    recoverySprintArtifactName: latestRecoveryURL.lastPathComponent
                ))
                """
            }
            let dashboardURL = try FameSnapshotArchive.saveOperatorDashboard(markdown: dashboard)
            readerState.answerText = dashboard
            readerState.remember(text: "", answer: dashboard)
            copyToClipboardWithReadyPrompt(
                dashboard,
                readyMessage: "Operator dashboard ready.",
                copyMessage: "Copied fame operator dashboard."
            )
            readerWindow.show()
            revealURL(dashboardURL)
            recordActivity(category: "share", detail: "run-fame-operator-dashboard")
        } catch {
            readerState.errorText = "Could not run fame operator dashboard."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-operator-dashboard-error")
        }
    }

    private func runFameNarrativeLab() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let narrative = FameSnapshotRollup.narrativeLabFromLedger(at: ledgerURL)
            let narrativeURL = try FameSnapshotArchive.saveNarrativeLab(markdown: narrative)
            readerState.answerText = narrative
            readerState.remember(text: "", answer: narrative)
            copyToClipboardWithReadyPrompt(
                narrative,
                readyMessage: "Narrative lab ready.",
                copyMessage: "Copied fame narrative lab."
            )
            readerWindow.show()
            revealURL(narrativeURL)
            recordActivity(category: "share", detail: "run-fame-narrative-lab")
        } catch {
            readerState.errorText = "Could not run fame narrative lab."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-narrative-lab-error")
        }
    }

    private func runFameSpotlightPack() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let spotlight = FameSnapshotRollup.spotlightPackFromLedger(at: ledgerURL)
            let spotlightURL = try FameSnapshotArchive.saveSpotlightPack(markdown: spotlight)
            readerState.answerText = spotlight
            readerState.remember(text: "", answer: spotlight)
            copyToClipboardWithReadyPrompt(
                spotlight,
                readyMessage: "Spotlight pack ready.",
                copyMessage: "Copied fame spotlight pack."
            )
            readerWindow.show()
            revealURL(spotlightURL)
            recordActivity(category: "share", detail: "run-fame-spotlight-pack")
        } catch {
            readerState.errorText = "Could not run fame spotlight pack."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-spotlight-pack-error")
        }
    }

    private func runFameLaunchDayScript() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let launchScript = FameSnapshotRollup.launchDayScriptFromLedger(at: ledgerURL)
            let launchScriptURL = try FameSnapshotArchive.saveLaunchDayScript(markdown: launchScript)
            readerState.answerText = launchScript
            readerState.remember(text: "", answer: launchScript)
            copyToClipboardWithReadyPrompt(
                launchScript,
                readyMessage: "Launch day script ready.",
                copyMessage: "Copied fame launch day script."
            )
            readerWindow.show()
            revealURL(launchScriptURL)
            recordActivity(category: "share", detail: "run-fame-launch-day-script")
        } catch {
            readerState.errorText = "Could not run fame launch day script."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-launch-day-script-error")
        }
    }

    private func runFameLaunchCountdown() {
        let now = Date()
        let promptContext = launchControlHubFollowupPromptContext(now: now)
        do {
            guard let launchScriptURL = try FameSnapshotArchive.latestLaunchDayScriptURL() else {
                readerState.errorText = "Run Fame Launch Day Script first."
                readerState.petSay(
                    Self.launchCountdownRunMissingScriptPrompt(
                        routeBadge: promptContext.routeBadge,
                        selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                        followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
                    ),
                    mood: .ready
                )
                readerState.pulse()
                fameLaunchAlertMenuItem?.title = fameLaunchAlertMenuTitle()
                fameLaunchHealthMenuItem?.title = fameLaunchHealthMenuTitle()
                updateFameOnboardingScorecardMenuStatus()
                refreshFamePulseBadge()
                recordActivity(category: "share", detail: "run-fame-launch-countdown-missing-script")
                return
            }
            let countdown = FameSnapshotRollup.launchCountdownFromLaunchScript(at: launchScriptURL)
            let countdownURL = try FameSnapshotArchive.saveLaunchCountdown(markdown: countdown)
            readerState.answerText = countdown
            readerState.remember(text: "", answer: countdown)
            copyToClipboardWithReadyPrompt(
                countdown,
                readyMessage: Self.launchCountdownRunReadyPrompt(
                    routeBadge: promptContext.routeBadge,
                    selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                    followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
                ),
                copyMessage: "Copied fame launch countdown."
            )
            readerWindow.show()
            revealURL(countdownURL)
            fameLaunchAlertMenuItem?.title = fameLaunchAlertMenuTitle()
            fameLaunchHealthMenuItem?.title = fameLaunchHealthMenuTitle()
            updateFameOnboardingScorecardMenuStatus()
            refreshFamePulseBadge()
            recordActivity(category: "share", detail: "run-fame-launch-countdown")
        } catch {
            readerState.errorText = "Could not run fame launch countdown."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-launch-countdown-error")
        }
    }

    private func refreshLaunchCountdownForLaunchControlBrief(now: Date = Date()) {
        do {
            guard let launchScriptURL = try FameSnapshotArchive.latestLaunchDayScriptURL() else {
                recordActivity(category: "share", detail: "run-fame-launch-control-brief-refresh-skipped-missing-script")
                return
            }
            let countdown = FameSnapshotRollup.launchCountdownFromLaunchScript(
                at: launchScriptURL,
                now: now
            )
            _ = try FameSnapshotArchive.saveLaunchCountdown(
                markdown: countdown,
                now: now
            )
            launchCountdownLastRefreshAt = now
            fameLaunchAlertMenuItem?.title = fameLaunchAlertMenuTitle()
            fameLaunchHealthMenuItem?.title = fameLaunchHealthMenuTitle(now: now)
            updateFameOnboardingScorecardMenuStatus(now: now)
            refreshFamePulseBadge()
            recordActivity(category: "share", detail: "run-fame-launch-control-brief-refresh-countdown")
        } catch {
            recordActivity(category: "share", detail: "run-fame-launch-control-brief-refresh-countdown-error")
        }
    }

    private func cadenceExecutionKitCommandStreakSnapshot(
        defaults: UserDefaults = .standard
    ) -> (current: Int, best: Int) {
        let currentStreak = max(0, defaults.integer(forKey: fameCadenceExecutionKitCommandStreakKey))
        let bestStreak = max(
            currentStreak,
            max(0, defaults.integer(forKey: fameCadenceExecutionKitCommandBestStreakKey))
        )
        return (currentStreak, bestStreak)
    }

    private func makeFameLaunchControlBrief(now: Date = Date()) -> String {
        let launchStatus = latestLaunchCountdownStatus()
        let launchAlert = Self.launchControlBriefLaunchAlert(launchStatus)
        let nextMoveCommandID = fameNextMoveMenuCommandID()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(nextMoveCommandID)
        let healthInsights = launchControlHealthInsights(now: now)
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason()
        let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        let launchRescueAutoFollowupRouteDecisionStatusTitle =
            Self.launchRescueAutoFollowupRouteDecisionStatusTitle(
                triggerReason: launchRescueAutoTriggerReason,
                lastAutoTriggerAt: launchRescueAutoTriggerAt,
                activityItems: activityLog.items,
                now: now
            )
        let launchRescueAutoSelfHealStatusTitle = launchRescueAutoFollowupSelfHealArtifactStatusTitle(
            triggerReason: launchRescueAutoTriggerReason,
            now: now
        )
        let launchRescueFollowupOutcomeScoreboard = launchRescueFollowupOutcomeScoreboard(now: now)
        let launchRescueFollowupCoachRecoveryLaneStreak = launchRescueFollowupCoachRecoveryLaneStreak()
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutes =
            launchRescueFollowupRecoveryChecklistAutoCooldownMinutes()
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining =
            launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining(now: now)
        let launchRescueFollowupOutcomeCoachStatusTitle = Self.launchRescueFollowupOutcomeCoachStatusTitle(
            launchRescueFollowupOutcomeScoreboard,
            triggerReason: launchRescueAutoTriggerReason,
            recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining,
            now: now
        )
        let launchRescueFollowupMomentumStatusTitle = Self.launchRescueFollowupMomentumStatusTitle(
            launchRescueFollowupOutcomeScoreboard,
            recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining
        ) ?? "Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."
        return Self.launchControlBriefMarkdown(
            generatedAt: Self.launchControlBriefGeneratedAt(now),
            launchAlertTitle: launchAlert.title,
            launchAlertSubtitle: launchAlert.subtitle,
            rescueAutoStatusTitle: launchRescueAutoMenuStatusTitle(now: now),
            rescueAutoTriggerStatusTitle: Self.launchRescueAutoTriggerStatusTitle(
                launchRescueAutoTriggerReason
            ),
            rescueAutoTriggerAtStatusTitle: Self.launchRescueAutoTriggerAtStatusTitle(
                launchRescueAutoTriggerAt,
                now: now
            ),
            rescueAutoFollowupStatusTitle: Self.launchRescueAutoTriggerFollowupStatusTitle(
                launchRescueAutoTriggerReason,
                lastAutoTriggerAt: launchRescueAutoTriggerAt,
                now: now
            ),
            rescueAutoFollowupRouteDecisionStatusTitle:
                launchRescueAutoFollowupRouteDecisionStatusTitle,
            rescueAutoSelfHealStatusTitle: launchRescueAutoSelfHealStatusTitle,
            rescueAutoFollowupScoreboardStatusTitle: Self.launchRescueFollowupOutcomeScoreboardStatusTitle(
                launchRescueFollowupOutcomeScoreboard,
                now: now
            ),
            rescueAutoFollowupCoachStatusTitle: launchRescueFollowupOutcomeCoachStatusTitle,
            rescueAutoFollowupMomentumStatusTitle: launchRescueFollowupMomentumStatusTitle,
            thresholdAlertsStatusTitle: fameLaunchThresholdAlertsMenuTitle(now: now),
            healthPulseStatusTitle: Self.launchControlHealthPulseStatusTitle(
                alertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
                pulseEnabled: settings.fameLaunchHealthPulseEnabled,
                cooldownSeconds: settings.fameLaunchHealthPulseCooldownSeconds,
                lastPulseAt: launchControlHealthPulseLastAt,
                lastPulseToken: launchControlHealthPulseLastToken,
                now: now
            ),
            healthTransitionCountsTitle: Self.launchControlHealthTransitionCountsTitle(
                watchToRiskCount: healthInsights.transitionCounts.watchToRiskCount,
                riskToReadyCount: healthInsights.transitionCounts.riskToReadyCount,
                averageDeltaTitle: healthInsights.averageDeltaTitle,
                momentumStatusTitle: healthInsights.momentumStatusTitle,
                pressurePersistenceStatusTitle: healthInsights.pressurePersistenceStatusTitle
            ),
            snoozeReminderStatusTitle: fameLaunchThresholdAlertsSnoozeReminderMenuTitle(now: now),
            nextMoveLabel: nextMoveLabel,
            cadenceStreakStatusTitle: Self.cadenceExecutionKitCommandStreakStatusTitle(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best
            ),
            healthScore: Self.launchControlBriefHealthScore(launchStatus: launchStatus),
            priorityMove: Self.launchControlBriefPriorityMove(launchStatus: launchStatus)
        )
    }

    private func makeLaunchRescueSnapshot(now: Date = Date()) -> String {
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason()
        let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        let launchRescueAutoFollowupRouteDecisionStatusTitle =
            Self.launchRescueAutoFollowupRouteDecisionStatusTitle(
                triggerReason: launchRescueAutoTriggerReason,
                lastAutoTriggerAt: launchRescueAutoTriggerAt,
                activityItems: activityLog.items,
                now: now
            )
        let launchRescueAutoSelfHealStatusTitle = launchRescueAutoFollowupSelfHealArtifactStatusTitle(
            triggerReason: launchRescueAutoTriggerReason,
            now: now
        )
        let launchRescueFollowupReason = fameLaunchRescueBurstLastFollowupReason()
        let launchRescueFollowupCommandID = fameLaunchRescueBurstLastFollowupCommandID()
        let launchRescueFollowupAt = fameLaunchRescueBurstLastFollowupAt()
        let launchRescueFollowupOutcomeScoreboard = launchRescueFollowupOutcomeScoreboard(now: now)
        let launchRescueFollowupCoachRecoveryLaneStreak = launchRescueFollowupCoachRecoveryLaneStreak()
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutes =
            launchRescueFollowupRecoveryChecklistAutoCooldownMinutes()
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining =
            launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining(now: now)
        let launchRescueFollowupOutcomeScoreboardStatusTitle =
            Self.launchRescueFollowupOutcomeScoreboardStatusTitle(
                launchRescueFollowupOutcomeScoreboard,
                now: now
            )
        let launchRescueFollowupOutcomeCoachStatusTitle =
            Self.launchRescueFollowupOutcomeCoachStatusTitle(
                launchRescueFollowupOutcomeScoreboard,
                triggerReason: launchRescueAutoTriggerReason,
                recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
                recoveryChecklistCooldownMinutes:
                    launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
                recoveryChecklistCooldownMinutesRemaining:
                    launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining,
                now: now
            )
        let launchRescueFollowupOutcomeMomentumStatusTitle =
            Self.launchRescueFollowupMomentumStatusTitle(
                launchRescueFollowupOutcomeScoreboard,
                recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
                recoveryChecklistCooldownMinutes:
                    launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
                recoveryChecklistCooldownMinutesRemaining:
                    launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining
            ) ?? "Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."

        return Self.launchRescueSnapshotMarkdown(
            autoTriggerSummary: Self.launchRescueAutoTriggerSummary(
                launchRescueAutoTriggerReason
            ),
            autoTriggerAtSummary: Self.launchRescueAutoTriggerAtDiagnosticSummary(
                launchRescueAutoTriggerAt
            ),
            autoFollowupSummary: Self.launchRescueAutoFollowupRunSummary(
                commandID: launchRescueFollowupCommandID,
                reasonToken: launchRescueFollowupReason
            ),
            autoFollowupAtSummary: Self.launchRescueAutoTriggerAtDiagnosticSummary(
                launchRescueFollowupAt
            ),
            followupRouteDecisionStatusTitle: launchRescueAutoFollowupRouteDecisionStatusTitle,
            autoSelfHealStatusTitle: launchRescueAutoSelfHealStatusTitle,
            followupScoreboardStatusTitle: launchRescueFollowupOutcomeScoreboardStatusTitle,
            followupCoachStatusTitle: launchRescueFollowupOutcomeCoachStatusTitle,
            followupMomentumStatusTitle: launchRescueFollowupOutcomeMomentumStatusTitle
        )
    }

    private func makeCadenceExecutionKitMomentumBrief(now: Date = Date()) -> String {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveCommandID = fameNextMoveMenuCommandID()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(nextMoveCommandID)
        let momentumTitle = Self.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best
        )
        let launchRecoveryWinMeter = Self.launchRecoveryHotKeyWinMeterSnapshot()
        let launchRecoveryMomentumDelta = Self.launchRecoveryHotKeyMomentumDeltaSnapshot()
        let launchRecoveryWinsTitle = launchRecoveryWinMeter?.title ?? "Recovery wins: warming up."
        let launchRecoveryWinsSubtitle = launchRecoveryWinMeter?.subtitle
            ?? "Launch recovery wins appear after a few palette opens. Keep using ⌥⇧L and the top recovery action."
        let launchRecoveryMomentumDeltaTitle = launchRecoveryMomentumDelta?.title
            ?? "Fame momentum delta: warming up."
        let launchRecoveryMomentumDeltaSubtitle = launchRecoveryMomentumDelta?.subtitle
            ?? "Need two recovery windows before delta can be computed. Keep using launch recovery to build trend evidence."
        let shareLine = Self.cadenceExecutionKitMomentumShareLine(
            momentumTitle: momentumTitle,
            nextMoveLabel: nextMoveLabel,
            recoveryWinsTitle: launchRecoveryWinsTitle,
            momentumDeltaTitle: launchRecoveryMomentumDeltaTitle
        )

        return Self.cadenceExecutionKitMomentumBriefMarkdown(
            generatedAt: Self.launchControlBriefGeneratedAt(now),
            momentumTitle: momentumTitle,
            streakStatusTitle: Self.cadenceExecutionKitCommandStreakStatusTitle(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best
            ),
            nextMoveLabel: nextMoveLabel,
            pulseStatusTitle: Self.cadenceExecutionKitMomentumPulseStatusTitle(
                signal: famePulseAlertSignal()
            ),
            launchStatusTitle: Self.cadenceExecutionKitMomentumLaunchStatusTitle(
                latestLaunchCountdownStatus()
            ),
            scorecardStatusTitle: Self.cadenceExecutionKitMomentumScorecardStatusTitle(
                fameDailyScorecardState()
            ),
            priorityMove: Self.cadenceExecutionKitMomentumPriorityMove(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best,
                nextMoveLabel: nextMoveLabel
            ),
            recoveryWinsTitle: launchRecoveryWinsTitle,
            recoveryWinsSubtitle: launchRecoveryWinsSubtitle,
            momentumDeltaTitle: launchRecoveryMomentumDeltaTitle,
            momentumDeltaSubtitle: launchRecoveryMomentumDeltaSubtitle,
            shareLine: shareLine
        )
    }

    private func saveLaunchControlBriefArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let briefURL = try FameSnapshotArchive.saveLaunchControlBrief(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-launch-control-brief")
            return briefURL
        } catch {
            recordActivity(category: "saved", detail: "save-launch-control-brief-error")
            return nil
        }
    }

    private func saveLaunchRescueSnapshotArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let snapshotURL = try FameSnapshotArchive.saveLaunchRescueSnapshot(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-launch-rescue-snapshot")
            return snapshotURL
        } catch {
            recordActivity(category: "saved", detail: "save-launch-rescue-snapshot-error")
            return nil
        }
    }

    private func saveFameExceptionalLoopRecapArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let recapURL = try FameSnapshotArchive.saveExceptionalLoopRecap(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-fame-exceptional-loop-recap")
            return recapURL
        } catch {
            recordActivity(category: "saved", detail: "save-fame-exceptional-loop-recap-error")
            return nil
        }
    }

    private func saveCadenceShareLineArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let shareLineURL = try FameSnapshotArchive.saveCadenceShareLine(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-cadence-share-line")
            return shareLineURL
        } catch {
            recordActivity(category: "saved", detail: "save-cadence-share-line-error")
            return nil
        }
    }

    private func saveCadenceSharePackArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let sharePackURL = try FameSnapshotArchive.saveCadenceSharePack(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-cadence-share-pack")
            return sharePackURL
        } catch {
            recordActivity(category: "saved", detail: "save-cadence-share-pack-error")
            return nil
        }
    }

    private func saveFameOnboardingNudgeArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let nudgeURL = try FameSnapshotArchive.saveOnboardingNudge(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-fame-onboarding-nudge")
            return nudgeURL
        } catch {
            recordActivity(category: "saved", detail: "save-fame-onboarding-nudge-error")
            return nil
        }
    }

    private func saveFameOnboardingDailyBriefArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let briefURL = try FameSnapshotArchive.saveOnboardingDailyBrief(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-fame-onboarding-daily-brief")
            return briefURL
        } catch {
            recordActivity(category: "saved", detail: "save-fame-onboarding-daily-brief-error")
            return nil
        }
    }

    private func saveFameOnboardingScorecardArtifact(markdown: String, now: Date = Date()) -> URL? {
        do {
            let scorecardURL = try FameSnapshotArchive.saveOnboardingScorecard(
                markdown: markdown,
                now: now
            )
            recordActivity(category: "saved", detail: "save-fame-onboarding-scorecard")
            return scorecardURL
        } catch {
            recordActivity(category: "saved", detail: "save-fame-onboarding-scorecard-error")
            return nil
        }
    }

    private func runFameCadenceMomentumBrief(now: Date = Date()) {
        let brief = makeCadenceExecutionKitMomentumBrief(now: now)
        var savedURL: URL?
        do {
            savedURL = try FameSnapshotArchive.saveCadenceMomentumBrief(
                markdown: brief,
                now: now
            )
            recordActivity(category: "saved", detail: "save-cadence-momentum-brief")
        } catch {
            recordActivity(category: "saved", detail: "save-cadence-momentum-brief-error")
        }

        let didSave = savedURL != nil
        readerState.answerText = brief
        readerState.errorText = didSave
            ? ""
            : "Cadence momentum brief ready, but could not save artifact."
        readerState.remember(text: "", answer: brief)
        copyToClipboardWithReadyPrompt(
            brief,
            readyMessage: didSave ? "Cadence momentum brief ready." : "Cadence momentum brief ready (save failed).",
            copyMessage: "Copied cadence momentum brief.",
            mood: didSave ? .happy : .ready,
            clearError: didSave
        )
        readerWindow.show()
        if let savedURL {
            revealURL(savedURL)
        }
        recordActivity(category: "share", detail: "run-fame-cadence-momentum-brief")
    }

    private func copyFameCadenceShareLine(now: Date = Date()) {
        let shareLine: String
        let source: String
        let copyActivityDetail: String

        do {
            if let momentumBriefURL = try FameSnapshotArchive.latestCadenceMomentumBriefURL() {
                let momentumBrief = (try? String(contentsOf: momentumBriefURL, encoding: .utf8)) ?? ""
                switch Self.latestCadenceMomentumShareLineCopyOutcome(
                    momentumBriefMarkdown: momentumBrief
                ) {
                case .ready(let latestShareLine):
                    shareLine = latestShareLine
                    source = "Latest cadence momentum brief"
                    copyActivityDetail = "copy-fame-cadence-share-line-latest"
                    let artifactMarkdown = Self.cadenceExecutionKitShareLineArtifactMarkdown(
                        generatedAt: Self.launchControlBriefGeneratedAt(now),
                        shareLine: shareLine,
                        source: source
                    )
                    _ = saveCadenceShareLineArtifact(markdown: artifactMarkdown, now: now)
                    readerState.answerText = shareLine
                    readerState.remember(text: "", answer: shareLine)
                    copyToClipboardWithReadyPrompt(
                        shareLine,
                        readyMessage: "Cadence share line ready (latest brief).",
                        copyMessage: "Copied cadence share line."
                    )
                    recordActivity(category: "share", detail: copyActivityDetail)
                    return
                case .missingBrief, .missingShareLine:
                    break
                }
            }
        } catch {
            recordActivity(category: "share", detail: "copy-fame-cadence-share-line-latest-error")
        }

        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())
        let momentumTitle = Self.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best
        )
        let launchRecoveryWinMeter = Self.launchRecoveryHotKeyWinMeterSnapshot()
        let launchRecoveryMomentumDelta = Self.launchRecoveryHotKeyMomentumDeltaSnapshot()
        let launchRecoveryWinsTitle = launchRecoveryWinMeter?.title ?? "Recovery wins: warming up."
        let launchRecoveryMomentumDeltaTitle = launchRecoveryMomentumDelta?.title
            ?? "Fame momentum delta: warming up."
        shareLine = Self.cadenceExecutionKitMomentumShareLine(
            momentumTitle: momentumTitle,
            nextMoveLabel: nextMoveLabel,
            recoveryWinsTitle: launchRecoveryWinsTitle,
            momentumDeltaTitle: launchRecoveryMomentumDeltaTitle
        )
        source = "Live momentum snapshot"
        copyActivityDetail = "copy-fame-cadence-share-line"

        let artifactMarkdown = Self.cadenceExecutionKitShareLineArtifactMarkdown(
            generatedAt: Self.launchControlBriefGeneratedAt(now),
            shareLine: shareLine,
            source: source
        )
        _ = saveCadenceShareLineArtifact(markdown: artifactMarkdown, now: now)
        readerState.answerText = shareLine
        readerState.remember(text: "", answer: shareLine)
        copyToClipboardWithReadyPrompt(
            shareLine,
            readyMessage: "Cadence share line ready (live snapshot).",
            copyMessage: "Copied cadence share line."
        )
        recordActivity(category: "share", detail: copyActivityDetail)
    }

    private func copyFameCadenceSharePack(now: Date = Date()) {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())
        let momentumTitle = Self.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best
        )
        let launchRecoveryWinMeter = Self.launchRecoveryHotKeyWinMeterSnapshot()
        let launchRecoveryMomentumDelta = Self.launchRecoveryHotKeyMomentumDeltaSnapshot()
        let launchRecoveryWinsTitle = launchRecoveryWinMeter?.title ?? "Recovery wins: warming up."
        let launchRecoveryMomentumDeltaTitle = launchRecoveryMomentumDelta?.title
            ?? "Fame momentum delta: warming up."

        var standardShareLine = Self.cadenceExecutionKitMomentumShareLine(
            momentumTitle: momentumTitle,
            nextMoveLabel: nextMoveLabel,
            recoveryWinsTitle: launchRecoveryWinsTitle,
            momentumDeltaTitle: launchRecoveryMomentumDeltaTitle
        )
        var usingLatestMomentumBrief = false
        var handoffDrafts: FameNextMoveHandoffDrafts?
        var preferredCadenceChannel: NextMoveDraftChannel?

        do {
            if let momentumBriefURL = try FameSnapshotArchive.latestCadenceMomentumBriefURL() {
                let momentumBrief = (try? String(contentsOf: momentumBriefURL, encoding: .utf8)) ?? ""
                if case .ready(let latestShareLine) = Self.latestCadenceMomentumShareLineCopyOutcome(
                    momentumBriefMarkdown: momentumBrief
                ) {
                    standardShareLine = latestShareLine
                    usingLatestMomentumBrief = true
                }
            }
        } catch {
            recordActivity(category: "share", detail: "copy-fame-cadence-share-pack-latest-error")
        }

        do {
            if let handoffURL = try FameSnapshotArchive.latestNextMoveHandoffURL() {
                let handoff = (try? String(contentsOf: handoffURL, encoding: .utf8)) ?? ""
                handoffDrafts = FameSnapshotRollup.nextMoveHandoffDrafts(from: handoff)
                preferredCadenceChannel = Self.nextMoveCadencePrimaryChannel(
                    handoffMarkdown: handoff
                )
            }
        } catch {
            recordActivity(category: "share", detail: "copy-fame-cadence-share-pack-handoff-error")
        }
        let includesHandoffDrafts = handoffDrafts != nil
        let source = Self.cadenceExecutionKitSharePackSource(
            usingLatestMomentumBrief: usingLatestMomentumBrief,
            includesHandoffDrafts: includesHandoffDrafts,
            preferredCadenceChannel: preferredCadenceChannel
        )
        let copyActivityDetail = Self.cadenceExecutionKitSharePackCopyActivityDetail(
            usingLatestMomentumBrief: usingLatestMomentumBrief,
            includesHandoffDrafts: includesHandoffDrafts,
            preferredCadenceChannel: preferredCadenceChannel
        )

        let pack = Self.cadenceExecutionKitMomentumSharePack(
            momentumTitle: momentumTitle,
            nextMoveLabel: nextMoveLabel,
            recoveryWinsTitle: launchRecoveryWinsTitle,
            momentumDeltaTitle: launchRecoveryMomentumDeltaTitle,
            shareLine: standardShareLine,
            handoffDrafts: handoffDrafts,
            preferredCadenceChannel: preferredCadenceChannel
        )
        let artifactMarkdown = Self.cadenceExecutionKitSharePackArtifactMarkdown(
            generatedAt: Self.launchControlBriefGeneratedAt(now),
            source: source,
            pack: pack
        )
        _ = saveCadenceSharePackArtifact(markdown: artifactMarkdown, now: now)
        readerState.answerText = artifactMarkdown
        readerState.remember(text: "", answer: artifactMarkdown)
        copyToClipboardWithReadyPrompt(
            artifactMarkdown,
            readyMessage: "Cadence share pack ready.",
            copyMessage: "Copied cadence share pack."
        )
        recordActivity(category: "share", detail: copyActivityDetail)
    }

    private func runFameCadenceAutopilotLoop() {
        let commandID = fameNextMoveMenuCommandID()
        runFameNextMove(commandID: commandID, followup: .cadenceExecutionKit)

        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let streakTitle = cadenceStreak.current > 0
            ? "Cadence Autopilot x\(cadenceStreak.current)"
            : "Cadence Autopilot"
        rewardHUD.show(
            streakTitle,
            mood: .success,
            intensity: settings.feelIntensity * 0.82
        )
        flashStatus(
            symbol: Self.cadenceExecutionKitCommandMomentumSymbolName(
                currentStreak: cadenceStreak.current,
                bestStreak: cadenceStreak.best
            ),
            tint: .systemPurple,
            length: 0.18
        )
        recordActivity(
            category: "support",
            detail: "run-fame-cadence-autopilot-loop-\(ActivityLogCommand.safeID(commandID))"
        )
    }

    private func runCadenceCelebrationDemo() {
        workingFeedbackTask?.cancel()
        cancelPreviewFlow()
        effects.play(.tap, settings: settings)

        let levels = AppDefaults.fameCadenceAutopilotCelebrationIntensityOptions
        let configuredIntensity = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
            settings.fameCadenceAutopilotCelebrationIntensity
        )
        let configuredIntensityToken = Self.cadenceExecutionKitAutopilotCelebrationIntensityToken(
            configuredIntensity
        )
        recordActivity(
            category: "support",
            detail: "run-fame-cadence-celebration-demo-current-\(configuredIntensityToken)"
        )

        previewFeelTask = Task { [weak self] in
            for level in levels {
                await MainActor.run {
                    guard let self else { return }

                    let normalizedLevel = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(level)
                    let levelTitle = Self.cadenceExecutionKitAutopilotCelebrationIntensityTitle(
                        normalizedLevel
                    )
                    let levelToken = Self.cadenceExecutionKitAutopilotCelebrationIntensityToken(
                        normalizedLevel
                    )
                    let tier: CadenceExecutionKitAutopilotCueTier
                    let statusSymbol: String
                    switch normalizedLevel {
                    case 0:
                        tier = .momentum
                        statusSymbol = "bolt.fill"
                    case 2:
                        tier = .fameSurge
                        statusSymbol = "trophy.fill"
                    default:
                        tier = .breakout
                        statusSymbol = "rocket.fill"
                    }

                    let demoCue = CadenceExecutionKitAutopilotCue(
                        title: "Cadence Celebration Demo · \(levelTitle)",
                        subtitle: "Previewing \(levelTitle.lowercased()) milestone feedback.",
                        petMessage: "Cadence demo \(levelTitle.lowercased()) mode. Keep the streak hot.",
                        statusSymbol: statusSymbol,
                        isRecovery: false,
                        token: "celebration-demo-\(levelToken)",
                        tier: tier
                    )
                    let feedback = self.cadenceExecutionKitAutopilotCueFeedbackProfile(
                        for: demoCue,
                        celebrationIntensity: normalizedLevel
                    )

                    self.rewardHUD.show(
                        demoCue.title,
                        mood: feedback.hudMood,
                        intensity: min(1.18, self.settings.feelIntensity * feedback.intensityMultiplier)
                    )
                    self.readerState.petSay(demoCue.petMessage, mood: feedback.petMood)
                    self.readerState.pulse()
                    if feedback.doublePulse {
                        Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 110_000_000)
                            guard !Task.isCancelled else { return }
                            await MainActor.run {
                                self?.readerState.pulse()
                            }
                        }
                    }
                    if let hapticPattern = feedback.hapticPattern {
                        self.effects.hit(.success, settings: self.settings, haptic: hapticPattern)
                    }
                    self.flashStatus(
                        symbol: demoCue.statusSymbol,
                        tint: feedback.flashTint,
                        length: feedback.flashLength
                    )
                    self.recordActivity(
                        category: "support",
                        detail: "run-fame-cadence-celebration-demo-\(levelToken)"
                    )
                }

                try? await Task.sleep(nanoseconds: 950_000_000)
                guard !Task.isCancelled else { return }
            }

            await MainActor.run {
                guard let self else { return }
                let configuredTitle = Self.cadenceExecutionKitAutopilotCelebrationIntensityTitle(
                    self.settings.fameCadenceAutopilotCelebrationIntensity
                )
                self.readerState.petSay(
                    "Cadence celebration demo complete. Current profile: \(configuredTitle).",
                    mood: .happy
                )
                self.readerState.pulse()
                self.recordActivity(category: "support", detail: "run-fame-cadence-celebration-demo-complete")
                self.previewFeelTask = nil
            }
        }
    }

    private func runFameOnboardingFillGap(
        recommendedCommandID: String? = nil
    ) {
        let resolvedCommandID: String

        if let recommendedCommandID {
            resolvedCommandID = recommendedCommandID
        } else if let artifacts = try? latestOnboardingSuiteArtifacts(),
                  let nextCommandID = Self.fameOnboardingGapRecommendedCommandID(
                      hasDailyBrief: artifacts.dailyBriefURL != nil,
                      hasScorecard: artifacts.scorecardURL != nil,
                      hasNudge: artifacts.nudgeURL != nil
                  ) {
            resolvedCommandID = nextCommandID
        } else {
            readerState.errorText = ""
            readerState.petSay(
                "Onboarding suite already complete. Open onboarding hub to review your latest files.",
                mood: .happy
            )
            readerState.pulse()
            recordActivity(category: "support", detail: "run-fame-onboarding-fill-gap-complete")
            return
        }

        recordActivity(
            category: "support",
            detail: "run-fame-onboarding-fill-gap-\(ActivityLogCommand.safeID(resolvedCommandID))"
        )
        runFameCommand(commandID: resolvedCommandID)
    }

    private func runFameOnboardingNudge(now: Date = Date()) {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let windowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            settings.fameOnboardingNudgeWindowDays
        )
        let onboardingDay = firstRunGuide.fameOnboardingDay(now: now)
        let plan = Self.fameOnboardingNudgePlan(
            day: onboardingDay,
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best,
            windowDays: windowDays
        )
        firstRunGuide.markFameOnboardingNudgeShown(
            now: now,
            onboardingWindowDays: windowDays
        )
        let completedDays = firstRunGuide.fameOnboardingCompletedDays(onboardingWindowDays: windowDays)
        let remainingDays = firstRunGuide.fameOnboardingRemainingDays(onboardingWindowDays: windowDays)
        let markdown = Self.fameOnboardingNudgeMarkdown(
            plan,
            windowDays: windowDays,
            completedDays: completedDays,
            now: now
        )
        let savedURL = saveFameOnboardingNudgeArtifact(markdown: markdown, now: now)
        let didSave = savedURL != nil

        readerState.answerText = markdown
        readerState.errorText = didSave
            ? ""
            : "Fame onboarding nudge ready, but could not save artifact."
        readerState.remember(text: "", answer: markdown)
        rewardHUD.show(
            "Fame Onboarding Day \(plan.day) · \(completedDays)/\(windowDays)",
            mood: .success,
            intensity: min(1.1, settings.feelIntensity * 0.9)
        )
        flashStatus(symbol: "sparkles", tint: .systemPink, length: 0.22)
        copyToClipboardWithReadyPrompt(
            markdown,
            readyMessage: "Day \(plan.day) fame onboarding ready (\(completedDays)/\(windowDays) complete, \(remainingDays) left). Start with \(Self.fameOnboardingCommandTitle(plan.primaryCommandID)).",
            copyMessage: "Copied fame onboarding nudge.",
            mood: didSave ? .happy : .ready,
            clearError: didSave
        )
        readerWindow.show()
        if let savedURL {
            revealURL(savedURL)
        }
        consumeFameOnboardingGapRecoveryMomentumIfNeeded(actionID: "run-fame-onboarding-nudge")
        recordActivity(
            category: "support",
            detail: "run-fame-onboarding-nudge-day-\(plan.day)-\(completedDays)-of-\(windowDays)-\(ActivityLogCommand.safeID(plan.primaryCommandID))"
        )
    }

    private func runFameOnboardingDailyBrief(now: Date = Date()) {
        guard let context = fameOnboardingScorecardContext(now: now) else {
            readerState.errorText = "First-week daily brief is unavailable right now."
            readerState.petSay(
                "First-week daily brief is unavailable right now. Try `Run First-Week Fame Scorecard`.",
                mood: .ready
            )
            readerState.pulse()
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.2)
            recordActivity(category: "support", detail: "run-fame-onboarding-daily-brief-unavailable")
            return
        }

        let plan = Self.fameOnboardingNudgePlan(
            day: context.day,
            currentStreak: context.currentStreak,
            bestStreak: context.bestStreak,
            windowDays: context.windowDays
        )

        firstRunGuide.markFameOnboardingNudgeShown(
            now: now,
            onboardingWindowDays: context.windowDays
        )

        let completedDays = firstRunGuide.fameOnboardingCompletedDays(
            onboardingWindowDays: context.windowDays
        )
        let remainingDays = firstRunGuide.fameOnboardingRemainingDays(
            onboardingWindowDays: context.windowDays
        )

        let nudgeMarkdown = Self.fameOnboardingNudgeMarkdown(
            plan,
            windowDays: context.windowDays,
            completedDays: completedDays,
            now: now
        )
        let scorecardMarkdown = Self.fameOnboardingScorecardMarkdown(
            day: context.day,
            windowDays: context.windowDays,
            completedDays: completedDays,
            currentStreak: context.currentStreak,
            bestStreak: context.bestStreak,
            recommendedCommandID: context.recommendedCommandID,
            backupCommandID: context.backupCommandID,
            now: now
        )

        let nudgeURL = saveFameOnboardingNudgeArtifact(markdown: nudgeMarkdown, now: now)
        let scorecardURL = saveFameOnboardingScorecardArtifact(markdown: scorecardMarkdown, now: now)

        var briefMarkdown = Self.fameOnboardingDailyBriefMarkdown(
            day: context.day,
            windowDays: context.windowDays,
            completedDays: completedDays,
            currentStreak: context.currentStreak,
            bestStreak: context.bestStreak,
            recommendedCommandID: context.recommendedCommandID,
            backupCommandID: context.backupCommandID,
            onboardingNudgeArtifactName: nudgeURL?.lastPathComponent,
            onboardingScorecardArtifactName: scorecardURL?.lastPathComponent,
            dailyBriefArtifactName: nil,
            now: now
        )

        let briefURL = saveFameOnboardingDailyBriefArtifact(markdown: briefMarkdown, now: now)
        if let briefURL {
            briefMarkdown = Self.fameOnboardingDailyBriefMarkdown(
                day: context.day,
                windowDays: context.windowDays,
                completedDays: completedDays,
                currentStreak: context.currentStreak,
                bestStreak: context.bestStreak,
                recommendedCommandID: context.recommendedCommandID,
                backupCommandID: context.backupCommandID,
                onboardingNudgeArtifactName: nudgeURL?.lastPathComponent,
                onboardingScorecardArtifactName: scorecardURL?.lastPathComponent,
                dailyBriefArtifactName: briefURL.lastPathComponent,
                now: now
            )
            try? briefMarkdown.write(to: briefURL, atomically: true, encoding: .utf8)
        }

        let didSaveAnyArtifact = nudgeURL != nil || scorecardURL != nil || briefURL != nil

        readerState.answerText = briefMarkdown
        readerState.errorText = didSaveAnyArtifact
            ? ""
            : "First-week daily brief ready, but could not save artifacts."
        readerState.remember(text: "", answer: briefMarkdown)
        rewardHUD.show(
            "First-Week Daily Brief",
            mood: .success,
            intensity: min(1.1, settings.feelIntensity * 0.88)
        )
        flashStatus(symbol: "square.stack.3d.up.fill", tint: .systemIndigo, length: 0.2)
        copyToClipboardWithReadyPrompt(
            briefMarkdown,
            readyMessage: "First-week daily brief ready. \(completedDays)/\(context.windowDays) complete (\(remainingDays) left).",
            copyMessage: "Copied first-week daily brief.",
            mood: didSaveAnyArtifact ? .happy : .ready,
            clearError: didSaveAnyArtifact
        )
        readerWindow.show()
        if let briefURL {
            revealURL(briefURL)
        } else if let scorecardURL {
            revealURL(scorecardURL)
        } else if let nudgeURL {
            revealURL(nudgeURL)
        }
        consumeFameOnboardingGapRecoveryMomentumIfNeeded(actionID: "run-fame-onboarding-daily-brief")
        recordActivity(
            category: "support",
            detail: "run-fame-onboarding-daily-brief-day-\(context.day)-\(completedDays)-of-\(context.windowDays)-\(ActivityLogCommand.safeID(context.recommendedCommandID))"
        )
    }

    private func runFameOnboardingScorecard(now: Date = Date()) {
        guard let context = fameOnboardingScorecardContext(now: now) else {
            readerState.errorText = "First-week fame scorecard is unavailable right now."
            readerState.petSay(
                "First-week fame scorecard is unavailable right now. Try `Run Fame Next Move`.",
                mood: .ready
            )
            readerState.pulse()
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.2)
            recordActivity(category: "support", detail: "run-fame-onboarding-scorecard-unavailable")
            return
        }

        let markdown = Self.fameOnboardingScorecardMarkdown(
            day: context.day,
            windowDays: context.windowDays,
            completedDays: context.completedDays,
            currentStreak: context.currentStreak,
            bestStreak: context.bestStreak,
            recommendedCommandID: context.recommendedCommandID,
            backupCommandID: context.backupCommandID,
            now: now
        )
        let paceLine = Self.fameOnboardingScorecardPaceLine(
            day: context.day,
            windowDays: context.windowDays,
            completedDays: context.completedDays
        )
        let savedURL = saveFameOnboardingScorecardArtifact(markdown: markdown, now: now)
        let didSave = savedURL != nil

        readerState.answerText = markdown
        readerState.errorText = didSave
            ? ""
            : "First-week fame scorecard ready, but could not save artifact."
        readerState.remember(text: "", answer: markdown)
        rewardHUD.show(
            "First-Week Fame Scorecard",
            mood: .success,
            intensity: min(1.08, settings.feelIntensity * 0.82)
        )
        flashStatus(symbol: "chart.bar.fill", tint: .systemBlue, length: 0.18)
        copyToClipboardWithReadyPrompt(
            markdown,
            readyMessage: "First-week scorecard ready. \(context.completedDays)/\(context.windowDays) complete (\(context.remainingDays) left). \(paceLine)",
            copyMessage: "Copied first-week fame scorecard.",
            mood: didSave ? .happy : .ready,
            clearError: didSave
        )
        readerWindow.show()
        if let savedURL {
            revealURL(savedURL)
        }
        consumeFameOnboardingGapRecoveryMomentumIfNeeded(actionID: "run-fame-onboarding-scorecard")
        recordActivity(
            category: "support",
            detail: "run-fame-onboarding-scorecard-day-\(context.day)-\(context.completedDays)-of-\(context.windowDays)-\(ActivityLogCommand.safeID(context.recommendedCommandID))"
        )
    }

    private func runFameLaunchControlBrief(now: Date = Date()) {
        refreshLaunchCountdownForLaunchControlBrief(now: now)
        let brief = makeFameLaunchControlBrief(now: now)
        let briefURL = saveLaunchControlBriefArtifact(markdown: brief, now: now)
        let didSaveBrief = briefURL != nil
        let promptContext = launchControlHubFollowupPromptContext(now: now)

        readerState.answerText = brief
        readerState.errorText = didSaveBrief
            ? ""
            : "Launch control brief ready, but could not save artifact."
        readerState.remember(text: "", answer: brief)
        copyToClipboardWithReadyPrompt(
            brief,
            readyMessage: Self.launchControlPromptWithLaunchRescueContext(
                didSaveBrief ? "Launch control brief ready." : "Launch control brief ready (save failed).",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            copyMessage: "Copied launch control brief.",
            mood: didSaveBrief ? .happy : .ready,
            clearError: didSaveBrief
        )
        readerWindow.show()
        if let briefURL {
            revealURL(briefURL)
        }
        recordActivity(category: "share", detail: "run-fame-launch-control-brief")
    }

    @discardableResult
    private func runFameLaunchControlHub(
        source: String = "manual",
        announce: Bool = true,
        now: Date = Date()
    ) -> Bool {
        refreshLaunchCountdownForLaunchControlBrief(now: now)
        let normalizedSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceToken = ActivityLogCommand.safeID(normalizedSource)
        let rescueSource = normalizedSource.isEmpty || normalizedSource.lowercased() == "manual"
            ? "launch-control-hub"
            : "launch-control-hub-\(sourceToken)"
        let didRunRescueBurst = runFameLaunchRescueBurst(
            source: rescueSource,
            announce: false,
            now: now
        )

        let brief = makeFameLaunchControlBrief(now: now)
        let briefURL = saveLaunchControlBriefArtifact(markdown: brief, now: now)

        let snapshot = makeLaunchRescueSnapshot(now: now)
        let snapshotURL = saveLaunchRescueSnapshotArtifact(markdown: snapshot, now: now)

        let rescueBurstURL = (try? FameSnapshotArchive.latestLaunchRescueBurstURL()) ?? nil
        let countdownURL = (try? FameSnapshotArchive.latestLaunchCountdownURL()) ?? nil

        let artifactURLs = [briefURL, snapshotURL, rescueBurstURL, countdownURL].compactMap { $0 }
        let missingArtifactNames: [String] = [
            briefURL == nil ? "launch control brief" : nil,
            snapshotURL == nil ? "launch rescue snapshot" : nil,
            rescueBurstURL == nil ? "launch rescue burst" : nil,
            countdownURL == nil ? "launch countdown" : nil
        ].compactMap { $0 }
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason()
        let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        let launchRescueFollowupPromptSignals = launchRescueFollowupPromptContext(
            triggerReason: launchRescueAutoTriggerReason,
            lastAutoTriggerAt: launchRescueAutoTriggerAt,
            now: now
        )
        let launchRescueAutoFollowupRouteDecisionStatusTitle =
            Self.launchRescueAutoFollowupRouteDecisionStatusTitle(
                triggerReason: launchRescueAutoTriggerReason,
                lastAutoTriggerAt: launchRescueAutoTriggerAt,
                activityItems: activityLog.items,
                now: now
            )
        let launchRescueAutoSelfHealStatusTitle = launchRescueAutoFollowupSelfHealArtifactStatusTitle(
            triggerReason: launchRescueAutoTriggerReason,
            now: now
        )
        let summary = Self.launchControlHubRunSummaryMarkdown(
            generatedAt: Self.launchControlBriefGeneratedAt(now),
            rescueBurstCompleted: didRunRescueBurst,
            readyArtifactCount: artifactURLs.count,
            launchRescueFollowupRouteDecisionStatusTitle:
                launchRescueAutoFollowupRouteDecisionStatusTitle,
            launchRescueAutoSelfHealStatusTitle: launchRescueAutoSelfHealStatusTitle,
            launchControlBriefArtifactName: briefURL?.lastPathComponent ?? "Not saved",
            launchRescueSnapshotArtifactName: snapshotURL?.lastPathComponent ?? "Not saved",
            launchRescueBurstArtifactName: rescueBurstURL?.lastPathComponent ?? "Not saved",
            launchCountdownArtifactName: countdownURL?.lastPathComponent ?? "Not saved",
            missingArtifactNames: missingArtifactNames
        )

        let didSaveAnyArtifact = !artifactURLs.isEmpty
        let hasAllArtifacts = artifactURLs.count >= Self.launchControlHubArtifactCount
        let mood: PetMood = hasAllArtifacts ? .happy : .ready
        let manualPrompt: String
        if hasAllArtifacts {
            manualPrompt = Self.launchControlPromptWithLaunchRescueContext(
                "Launch control hub ready (brief + snapshot + burst + countdown).",
                routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                    .followupRouteDecisionTraceLine
            )
        } else {
            manualPrompt = Self.launchControlPromptWithLaunchRescueContext(
                "Launch control hub ready (\(artifactURLs.count)/\(Self.launchControlHubArtifactCount) artifacts).",
                routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                    .followupRouteDecisionTraceLine
            )
        }

        if announce {
            readerState.answerText = summary
            readerState.errorText = didSaveAnyArtifact
                ? ""
                : "Launch control hub ran, but could not save artifacts."
            readerState.remember(text: "", answer: summary)
            rewardHUD.show(
                "Launch Control Hub",
                mood: hasAllArtifacts ? .success : .working,
                intensity: min(1.08, settings.feelIntensity * 0.84)
            )
            flashStatus(
                symbol: hasAllArtifacts ? "square.stack.3d.up.fill" : "square.stack.3d.up",
                tint: .systemTeal,
                length: 0.2
            )
            copyToClipboardWithReadyPrompt(
                summary,
                readyMessage: manualPrompt,
                copyMessage: "Copied launch control hub run summary.",
                mood: mood,
                clearError: didSaveAnyArtifact
            )
            readerWindow.show()
            artifactURLs.forEach(revealURL)
        } else {
            let autoPrompt: String
            if didRunRescueBurst {
                if hasAllArtifacts {
                    autoPrompt = Self.launchControlPromptWithLaunchRescueContext(
                        "Launch control hub auto-saved. Open latest launch control hub.",
                        routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                        selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                        followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                            .followupRouteDecisionTraceLine
                    )
                } else {
                    autoPrompt = Self.launchControlPromptWithLaunchRescueContext(
                        "Launch control hub auto-saved (\(artifactURLs.count)/\(Self.launchControlHubArtifactCount) artifacts).",
                        routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                        selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                        followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                            .followupRouteDecisionTraceLine
                    )
                }
            } else {
                autoPrompt = Self.launchControlPromptWithLaunchRescueContext(
                    "Launch control hub auto-run failed. Run Launch Control Hub.",
                    routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                    selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                    followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                        .followupRouteDecisionTraceLine
                )
            }

            readerState.petSay(autoPrompt, mood: didRunRescueBurst ? .ready : .error)
            readerState.pulse()
            flashStatus(
                symbol: didRunRescueBurst ? "square.stack.3d.up" : "xmark.circle.fill",
                tint: didRunRescueBurst ? .systemTeal : .systemRed,
                length: 0.2
            )
        }

        recordActivity(
            category: "share",
            detail: Self.launchControlHubRunActivityDetail(
                source: normalizedSource,
                readyArtifactCount: artifactURLs.count
            )
        )
        return didRunRescueBurst
    }

    private func runFameLaunchRescueSnapshot(now: Date = Date()) {
        let snapshot = makeLaunchRescueSnapshot(now: now)
        let snapshotURL = saveLaunchRescueSnapshotArtifact(markdown: snapshot, now: now)
        let didSaveSnapshot = snapshotURL != nil
        let promptContext = launchControlHubFollowupPromptContext(now: now)

        readerState.answerText = snapshot
        readerState.errorText = didSaveSnapshot
            ? ""
            : "Launch rescue snapshot ready, but could not save artifact."
        readerState.remember(text: "", answer: snapshot)
        copyToClipboardWithReadyPrompt(
            snapshot,
            readyMessage: Self.launchControlPromptWithLaunchRescueContext(
                didSaveSnapshot
                    ? "Launch rescue snapshot ready."
                    : "Launch rescue snapshot ready (save failed).",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            copyMessage: "Copied launch rescue snapshot.",
            mood: didSaveSnapshot ? .happy : .ready,
            clearError: didSaveSnapshot
        )
        readerWindow.show()
        if let snapshotURL {
            revealURL(snapshotURL)
        }
        recordActivity(category: "share", detail: "run-fame-launch-rescue-snapshot")
    }

    private func copyFameLaunchControlBrief(now: Date = Date()) {
        let brief = makeFameLaunchControlBrief(now: now)
        let didSaveBrief = saveLaunchControlBriefArtifact(markdown: brief, now: now) != nil
        let promptContext = launchControlHubFollowupPromptContext(now: now)

        readerState.answerText = brief
        readerState.errorText = didSaveBrief
            ? ""
            : "Copied launch control brief, but could not save artifact."
        readerState.remember(text: "", answer: brief)
        copyToClipboardWithReadyPrompt(
            brief,
            readyMessage: Self.launchControlPromptWithLaunchRescueContext(
                didSaveBrief
                    ? "Launch control brief copied."
                    : "Launch control brief copied (save failed).",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            copyMessage: "Copied launch control brief.",
            mood: didSaveBrief ? .happy : .ready,
            clearError: didSaveBrief
        )
        readerWindow.show()
        recordActivity(category: "share", detail: "copy-fame-launch-control-brief")
    }

    private func copyFameLaunchRescueSnapshot(now: Date = Date()) {
        let snapshot = makeLaunchRescueSnapshot(now: now)
        let didSaveSnapshot = saveLaunchRescueSnapshotArtifact(
            markdown: snapshot,
            now: now
        ) != nil
        let promptContext = launchControlHubFollowupPromptContext(now: now)

        readerState.answerText = snapshot
        readerState.errorText = didSaveSnapshot
            ? ""
            : "Copied launch rescue snapshot, but could not save artifact."
        readerState.remember(text: "", answer: snapshot)
        copyToClipboardWithReadyPrompt(
            snapshot,
            readyMessage: Self.launchControlPromptWithLaunchRescueContext(
                didSaveSnapshot
                    ? "Launch rescue snapshot copied."
                    : "Launch rescue snapshot copied (save failed).",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            copyMessage: "Copied launch rescue snapshot.",
            mood: didSaveSnapshot ? .happy : .ready,
            clearError: didSaveSnapshot
        )
        readerWindow.show()
        recordActivity(category: "share", detail: "copy-fame-launch-rescue-snapshot")
    }

    @discardableResult
    private func runFameLaunchRescueBurst(
        source: String = "manual",
        announce: Bool = true,
        now: Date = Date()
    ) -> Bool {
        let promptContext = launchControlHubFollowupPromptContext(now: now)
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")

            let launchScriptURL: URL
            if let latestLaunchScriptURL = try FameSnapshotArchive.latestLaunchDayScriptURL(
                baseDirectory: directoryURL
            ) {
                launchScriptURL = latestLaunchScriptURL
            } else {
                let launchScript = FameSnapshotRollup.launchDayScriptFromLedger(at: ledgerURL)
                launchScriptURL = try FameSnapshotArchive.saveLaunchDayScript(
                    markdown: launchScript,
                    now: now,
                    baseDirectory: directoryURL
                )
            }

            let countdown = FameSnapshotRollup.launchCountdownFromLaunchScript(at: launchScriptURL)
            let countdownURL = try FameSnapshotArchive.saveLaunchCountdown(
                markdown: countdown,
                now: now,
                baseDirectory: directoryURL
            )
            guard let launchStatus = FameSnapshotRollup.launchCountdownStatus(from: countdown) else {
                readerState.errorText = "Could not parse launch countdown."
                effects.play(.error, settings: settings)
                flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
                let parseDetail: String
                if source == "manual" {
                    parseDetail = "run-fame-launch-rescue-burst-parse-error"
                } else {
                    parseDetail = "run-fame-launch-rescue-burst-parse-error-\(ActivityLogCommand.safeID(source))"
                }
                recordActivity(category: "share", detail: parseDetail)
                return false
            }

            let commandID = fameNextMoveMenuCommandID()
            let commandLabel = Self.fameNextMoveCommandLabel(commandID)
            let handoff = FameSnapshotRollup.nextMoveHandoff(
                commandID: commandID,
                commandLabel: commandLabel,
                signal: famePulseAlertSignal(),
                transition: famePulseLatestTransition(),
                scorecard: fameDailyScorecardState()
            )
            let handoffURL = try FameSnapshotArchive.saveNextMoveHandoff(
                markdown: handoff,
                now: now,
                baseDirectory: directoryURL
            )

            let checklist = FameSnapshotRollup.recoveryChecklistFromLedger(at: ledgerURL, now: now)
            let checklistURL = try FameSnapshotArchive.saveRecoveryChecklist(
                markdown: checklist,
                now: now,
                baseDirectory: directoryURL
            )

            let copiedDraftPack: Bool
            let savedDraftPackURL: URL?
            if let draftPack = FameSnapshotRollup.nextMoveDraftPack(from: handoff) {
                if announce {
                    copyToClipboardPreservingPrompt(
                        draftPack,
                        copyMessage: "Copied launch rescue draft pack."
                    )
                }
                copiedDraftPack = true
                savedDraftPackURL = saveNextMoveDraftPackArtifact(
                    markdown: draftPack,
                    now: now,
                    baseDirectory: directoryURL,
                    activityDetailBase: "save-fame-next-move-draft-pack-launch-rescue-burst"
                )
            } else {
                if announce {
                    copyToClipboardPreservingPrompt(
                        handoff,
                        copyMessage: "Copied launch rescue handoff."
                    )
                }
                copiedDraftPack = false
                savedDraftPackURL = nil
            }

            let reminderActionSummary: String = switch fameLaunchThresholdAlertsSnoozeReminderMenuTapAction(
                now: now
            ) {
            case .unmuteNow:
                "Unmute now"
            case .extend(let minutes):
                "Extend \(minutes)m"
            case nil:
                "None"
            }

            let rescue = Self.launchRescueBurstRunSummaryMarkdown(
                launchStatusTitle: Self.fameLaunchCountdownAlertTitle(launchStatus),
                launchStatusSubtitle: Self.fameLaunchCountdownAlertSubtitle(launchStatus),
                launchThresholdAlertsStatusTitle: fameLaunchThresholdAlertsMenuTitle(now: now),
                snoozeReminderActionSummary: reminderActionSummary,
                launchScriptArtifactName: launchScriptURL.lastPathComponent,
                launchCountdownArtifactName: countdownURL.lastPathComponent,
                nextMoveCommandTitle: commandLabel,
                nextMoveHandoffArtifactName: handoffURL.lastPathComponent,
                nextMoveDraftPackArtifactName: savedDraftPackURL?.lastPathComponent,
                recoveryChecklistArtifactName: checklistURL.lastPathComponent,
                draftPackReady: copiedDraftPack,
                clipboardActionSummary: announce
                    ? (copiedDraftPack ? "Draft pack copied" : "Handoff copied")
                    : "Skipped (auto mode preserves clipboard)"
            )
            let rescueURL = try FameSnapshotArchive.saveLaunchRescueBurst(
                markdown: rescue,
                now: now,
                baseDirectory: directoryURL
            )

            if announce {
                readerState.answerText = rescue
                readerState.errorText = ""
                readerState.petSay(
                    Self.launchRescueBurstRunReadyPrompt(
                        routeBadge: promptContext.routeBadge,
                        selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                        followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
                    ),
                    mood: .happy
                )
                readerState.remember(text: "", answer: rescue)
                readerState.pulse()
                readerWindow.show()
                revealURL(rescueURL)
            } else {
                readerState.petSay(
                    Self.launchRescueBurstAutoSavedPrompt(
                        routeBadge: promptContext.routeBadge,
                        selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                        followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
                    ),
                    mood: .ready
                )
                readerState.pulse()
                flashStatus(symbol: "bolt.shield", tint: .systemOrange, length: 0.2)
            }
            refreshFamePulseBadge()
            if let resetToken = Self.launchRescueAutoTriggerReasonResetTokenForRescueRun(
                announce: announce
            ) {
                setFameLaunchRescueBurstLastAutoTriggerReason(resetToken)
            }
            if Self.launchRescueAutoTriggerAtShouldResetForRescueRun(announce: announce) {
                setFameLaunchRescueBurstLastAutoTriggerAt(nil)
            }
            let successDetail: String
            if source == "manual" {
                successDetail = "run-fame-launch-rescue-burst"
            } else {
                successDetail = "run-fame-launch-rescue-burst-\(ActivityLogCommand.safeID(source))"
            }
            recordActivity(category: "share", detail: successDetail)
            return true
        } catch {
            readerState.errorText = "Could not run launch rescue burst."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            let errorDetail: String
            if source == "manual" {
                errorDetail = "run-fame-launch-rescue-burst-error"
            } else {
                errorDetail = "run-fame-launch-rescue-burst-error-\(ActivityLogCommand.safeID(source))"
            }
            recordActivity(category: "share", detail: errorDetail)
            return false
        }
    }

    private func openLatestFameArtifact(
        latestURL: () throws -> URL?,
        emptyError: String,
        emptyPrompt: String? = nil,
        successPrompt: String? = nil,
        failureError: String,
        activityDetailBase: String,
        playErrorFeedback: Bool = true
    ) {
        do {
            guard let artifactURL = try latestURL() else {
                readerState.errorText = emptyError
                if let emptyPrompt {
                    readerState.petSay(emptyPrompt, mood: .ready)
                    readerState.pulse()
                }
                recordActivity(category: "open", detail: "\(activityDetailBase)-empty")
                return
            }

            if let markdown = try? String(contentsOf: artifactURL, encoding: .utf8),
               !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                readerState.answerText = markdown
                readerState.remember(text: "", answer: markdown)
            }
            readerState.errorText = ""
            if let successPrompt {
                readerState.petSay(successPrompt, mood: .happy)
                readerState.pulse()
            }
            readerWindow.show()
            revealURL(artifactURL)
            recordActivity(category: "open", detail: activityDetailBase)
        } catch {
            readerState.errorText = failureError
            if playErrorFeedback {
                effects.play(.error, settings: settings)
                flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            }
            recordActivity(category: "open", detail: "\(activityDetailBase)-error")
        }
    }

    private func openLatestRecoverySprint() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestRecoverySprintURL() },
            emptyError: "No saved recovery sprint yet.",
            emptyPrompt: "Run recovery sprint first.",
            successPrompt: "Opened latest recovery sprint.",
            failureError: "Could not open latest recovery sprint.",
            activityDetailBase: "open-latest-recovery-sprint"
        )
    }

    private func openLatestRecoveryChecklist() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestRecoveryChecklistURL() },
            emptyError: "No saved recovery checklist yet.",
            emptyPrompt: "Run recovery checklist first.",
            successPrompt: "Opened latest recovery checklist.",
            failureError: "Could not open latest recovery checklist.",
            activityDetailBase: "open-latest-recovery-checklist"
        )
    }

    private func openLatestRecoveryProofPack() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestRecoveryProofPackURL() },
            emptyError: "No saved recovery proof pack yet.",
            emptyPrompt: "Run recovery proof pack first.",
            successPrompt: "Opened latest recovery proof pack.",
            failureError: "Could not open latest recovery proof pack.",
            activityDetailBase: "open-latest-recovery-proof-pack"
        )
    }

    private func openLatestCommandCenter() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestCommandCenterURL() },
            emptyError: "No saved command center yet.",
            emptyPrompt: "Run command center first.",
            successPrompt: "Opened latest command center.",
            failureError: "Could not open latest command center.",
            activityDetailBase: "open-latest-command-center"
        )
    }

    private func openLatestNextMoveHandoff() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestNextMoveHandoffURL() },
            emptyError: Self.fameNextMoveMissingHandoffError,
            failureError: "Could not open next move handoff.",
            activityDetailBase: "open-latest-next-move-handoff",
            playErrorFeedback: false
        )
    }

    private func openLatestNextMoveDraftPack() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestNextMoveDraftPackURL() },
            emptyError: "No saved next move draft pack yet.",
            emptyPrompt: "Run Next Move + Copy Draft Pack first.",
            successPrompt: "Opened latest next-move draft pack.",
            failureError: "Could not open latest next-move draft pack.",
            activityDetailBase: "open-latest-next-move-draft-pack",
            playErrorFeedback: false
        )
    }

    private func openLatestDailyCheckpoint() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestDailyCheckpointURL() },
            emptyError: "No saved daily checkpoint yet.",
            emptyPrompt: "Run daily checkpoint first.",
            successPrompt: "Opened latest daily checkpoint.",
            failureError: "Could not open latest daily checkpoint.",
            activityDetailBase: "open-latest-daily-checkpoint"
        )
    }

    private func openLatestRiskTimeline() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestRiskTimelineURL() },
            emptyError: "No saved risk timeline yet.",
            emptyPrompt: "Run risk timeline first.",
            successPrompt: "Opened latest risk timeline.",
            failureError: "Could not open latest risk timeline.",
            activityDetailBase: "open-latest-risk-timeline"
        )
    }

    private func openLatestPulseNudge() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestPulseNudgeURL() },
            emptyError: "No saved pulse nudge yet.",
            emptyPrompt: "Run pulse nudge first.",
            successPrompt: "Opened latest pulse nudge.",
            failureError: "Could not open latest pulse nudge.",
            activityDetailBase: "open-latest-pulse-nudge"
        )
    }

    private func openLatestDailyScorecard() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestDailyScorecardURL() },
            emptyError: "No saved daily scorecard yet.",
            emptyPrompt: "Run daily scorecard first.",
            successPrompt: "Opened latest daily scorecard.",
            failureError: "Could not open latest daily scorecard.",
            activityDetailBase: "open-latest-daily-scorecard"
        )
    }

    private func latestOnboardingSuiteArtifacts() throws -> FameOnboardingSuiteArtifacts {
        let dailyBriefURL = try FameSnapshotArchive.latestOnboardingDailyBriefURL()
        let scorecardURL = try FameSnapshotArchive.latestOnboardingScorecardURL()
        let nudgeURL = try FameSnapshotArchive.latestOnboardingNudgeURL()
        return FameOnboardingSuiteArtifacts(
            dailyBriefURL: dailyBriefURL,
            scorecardURL: scorecardURL,
            nudgeURL: nudgeURL
        )
    }

    private nonisolated static func fameOnboardingSuiteNewestArtifactAgeMinutes(
        artifactURLs: [URL],
        now: Date = Date()
    ) -> Int? {
        let newestArtifactDate = artifactURLs.compactMap { artifactURL -> Date? in
            guard let values = try? artifactURL.resourceValues(
                forKeys: [.contentModificationDateKey, .creationDateKey]
            ) else {
                return nil
            }
            return values.contentModificationDate ?? values.creationDate
        }.max()

        guard let newestArtifactDate else {
            return nil
        }
        return max(0, Int(now.timeIntervalSince(newestArtifactDate) / 60))
    }

    private func fameOnboardingSuiteActionStatus(
        now: Date = Date()
    ) -> (availableArtifacts: Int, totalArtifacts: Int, newestArtifactAgeMinutes: Int?) {
        let totalArtifacts = Self.fameOnboardingSuiteArtifactCount
        do {
            let artifacts = try latestOnboardingSuiteArtifacts()
            return (
                availableArtifacts: artifacts.orderedURLs.count,
                totalArtifacts: totalArtifacts,
                newestArtifactAgeMinutes: Self.fameOnboardingSuiteNewestArtifactAgeMinutes(
                    artifactURLs: artifacts.orderedURLs,
                    now: now
                )
            )
        } catch {
            return (
                availableArtifacts: 0,
                totalArtifacts: totalArtifacts,
                newestArtifactAgeMinutes: nil
            )
        }
    }

    private func latestLaunchControlHubArtifacts() throws -> LaunchControlHubArtifacts {
        let launchControlBriefURL = try FameSnapshotArchive.latestLaunchControlBriefURL()
        let launchRescueSnapshotURL = try FameSnapshotArchive.latestLaunchRescueSnapshotURL()
        let launchRescueBurstURL = try FameSnapshotArchive.latestLaunchRescueBurstURL()
        let launchCountdownURL = try FameSnapshotArchive.latestLaunchCountdownURL()
        return LaunchControlHubArtifacts(
            launchControlBriefURL: launchControlBriefURL,
            launchRescueSnapshotURL: launchRescueSnapshotURL,
            launchRescueBurstURL: launchRescueBurstURL,
            launchCountdownURL: launchCountdownURL
        )
    }

    private func launchControlHubActionStatus(
        now: Date = Date()
    ) -> (availableArtifacts: Int, totalArtifacts: Int, newestArtifactAgeMinutes: Int?) {
        let totalArtifacts = Self.launchControlHubArtifactCount
        do {
            let artifacts = try latestLaunchControlHubArtifacts()
            return (
                availableArtifacts: artifacts.orderedURLs.count,
                totalArtifacts: totalArtifacts,
                newestArtifactAgeMinutes: Self.fameOnboardingSuiteNewestArtifactAgeMinutes(
                    artifactURLs: artifacts.orderedURLs,
                    now: now
                )
            )
        } catch {
            return (
                availableArtifacts: 0,
                totalArtifacts: totalArtifacts,
                newestArtifactAgeMinutes: nil
            )
        }
    }

    private func openLatestOnboardingSuite() {
        do {
            let now = Date()
            let artifacts = try latestOnboardingSuiteArtifacts()
            let artifactURLs = artifacts.orderedURLs
            let totalArtifacts = Self.fameOnboardingSuiteArtifactCount

            guard !artifactURLs.isEmpty else {
                readerState.errorText = "No saved first-week onboarding artifacts yet."
                readerState.petSay("Run first-week daily brief first.", mood: .ready)
                readerState.pulse()
                recordActivity(category: "open", detail: "open-latest-onboarding-suite-empty")
                return
            }

            if let primaryArtifactURL = artifactURLs.first,
               let markdown = try? String(contentsOf: primaryArtifactURL, encoding: .utf8),
               !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                readerState.answerText = markdown
                readerState.remember(text: "", answer: markdown)
            }

            let openedCount = artifactURLs.count
            let newestArtifactAgeMinutes = Self.fameOnboardingSuiteNewestArtifactAgeMinutes(
                artifactURLs: artifactURLs,
                now: now
            )
            let recencyTitle = Self.fameOnboardingSuiteArtifactRecencyTitle(
                newestArtifactAgeMinutes: newestArtifactAgeMinutes
            )
            let mood: PetMood = openedCount >= totalArtifacts ? .happy : .ready
            let prompt: String
            if openedCount >= totalArtifacts {
                prompt = "Opened onboarding hub (daily brief + scorecard + nudge) · \(recencyTitle)."
            } else {
                prompt = "Opened onboarding hub (\(openedCount)/\(totalArtifacts) artifacts) · \(recencyTitle). Run first-week daily brief to refresh missing files."
            }

            readerState.errorText = ""
            readerState.petSay(prompt, mood: mood)
            readerState.pulse()
            readerWindow.show()
            artifactURLs.forEach(revealURL)
            recordActivity(
                category: "open",
                detail: "open-latest-onboarding-suite-\(openedCount)-of-\(totalArtifacts)"
            )
        } catch {
            readerState.errorText = "Could not open first-week onboarding hub."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "open", detail: "open-latest-onboarding-suite-error")
        }
    }

    private func openLatestOnboardingDailyBrief() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestOnboardingDailyBriefURL() },
            emptyError: "No saved first-week daily brief yet.",
            emptyPrompt: "Run first-week daily brief first.",
            successPrompt: "Opened latest first-week daily brief.",
            failureError: "Could not open latest first-week daily brief.",
            activityDetailBase: "open-latest-onboarding-daily-brief"
        )
    }

    private func openLatestOnboardingNudge() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestOnboardingNudgeURL() },
            emptyError: "No saved fame onboarding nudge yet.",
            emptyPrompt: "Run fame onboarding nudge first.",
            successPrompt: "Opened latest fame onboarding nudge.",
            failureError: "Could not open latest fame onboarding nudge.",
            activityDetailBase: "open-latest-onboarding-nudge"
        )
    }

    private func openLatestOnboardingScorecard() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestOnboardingScorecardURL() },
            emptyError: "No saved first-week fame scorecard yet.",
            emptyPrompt: "Run first-week fame scorecard first.",
            successPrompt: "Opened latest first-week fame scorecard.",
            failureError: "Could not open latest first-week fame scorecard.",
            activityDetailBase: "open-latest-onboarding-scorecard"
        )
    }

    private func openLatestOperatorDashboard() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestOperatorDashboardURL() },
            emptyError: "No saved operator dashboard yet.",
            emptyPrompt: "Run operator dashboard first.",
            successPrompt: "Opened latest operator dashboard.",
            failureError: "Could not open latest operator dashboard.",
            activityDetailBase: "open-latest-operator-dashboard"
        )
    }

    private func openLatestNarrativeLab() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestNarrativeLabURL() },
            emptyError: "No saved narrative lab yet.",
            emptyPrompt: "Run narrative lab first.",
            successPrompt: "Opened latest narrative lab.",
            failureError: "Could not open latest narrative lab.",
            activityDetailBase: "open-latest-narrative-lab"
        )
    }

    private func openLatestSpotlightPack() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestSpotlightPackURL() },
            emptyError: "No saved spotlight pack yet.",
            emptyPrompt: "Run spotlight pack first.",
            successPrompt: "Opened latest spotlight pack.",
            failureError: "Could not open latest spotlight pack.",
            activityDetailBase: "open-latest-spotlight-pack"
        )
    }

    private func openLatestLaunchDayScript() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestLaunchDayScriptURL() },
            emptyError: "No saved launch day script yet.",
            emptyPrompt: "Run launch day script first.",
            successPrompt: "Opened latest launch day script.",
            failureError: "Could not open latest launch day script.",
            activityDetailBase: "open-latest-launch-day-script"
        )
    }

    private func openLatestLaunchCountdown() {
        let now = Date()
        let promptContext = launchControlHubFollowupPromptContext(now: now)
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestLaunchCountdownURL() },
            emptyError: "No saved launch countdown yet.",
            emptyPrompt: Self.launchControlPromptWithLaunchRescueContext(
                "Run launch countdown first.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            successPrompt: Self.launchControlPromptWithLaunchRescueContext(
                "Opened latest launch countdown.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            failureError: "Could not open latest launch countdown.",
            activityDetailBase: "open-latest-launch-countdown"
        )
    }

    private func openLatestLaunchRescueBurst(
        autoStatusCooldownMinutesRemaining: Int? = nil,
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        latestURLProvider: (() throws -> URL?)? = nil
    ) {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        let emptyPrompt: String
        let successPrompt: String
        if let autoStatusCooldownMinutesRemaining {
            emptyPrompt = Self.launchRescueAutoStatusCoolingDownMissingPrompt(
                minutesRemaining: autoStatusCooldownMinutesRemaining,
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            )
            successPrompt = Self.launchRescueAutoStatusCoolingDownOpenedPrompt(
                minutesRemaining: autoStatusCooldownMinutesRemaining,
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            )
        } else {
            emptyPrompt = Self.launchControlPromptWithLaunchRescueContext(
                "Run launch rescue burst first.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            )
            successPrompt = Self.launchControlPromptWithLaunchRescueContext(
                "Opened latest launch rescue burst.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            )
        }
        openLatestFameArtifact(
            latestURL: {
                if let latestURLProvider {
                    return try latestURLProvider()
                }
                return try FameSnapshotArchive.latestLaunchRescueBurstURL()
            },
            emptyError: "No saved launch rescue burst yet.",
            emptyPrompt: emptyPrompt,
            successPrompt: successPrompt,
            failureError: "Could not open latest launch rescue burst.",
            activityDetailBase: "open-latest-launch-rescue-burst"
        )
    }

    private func openLatestLaunchRescueSnapshot() {
        let now = Date()
        let promptContext = launchControlHubFollowupPromptContext(now: now)
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestLaunchRescueSnapshotURL() },
            emptyError: "No saved launch rescue snapshot yet.",
            emptyPrompt: Self.launchControlPromptWithLaunchRescueContext(
                "Copy launch rescue snapshot first.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            successPrompt: Self.launchControlPromptWithLaunchRescueContext(
                "Opened latest launch rescue snapshot.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            failureError: "Could not open latest launch rescue snapshot.",
            activityDetailBase: "open-latest-launch-rescue-snapshot"
        )
    }

    private func openLatestLaunchControlBrief() {
        let now = Date()
        let promptContext = launchControlHubFollowupPromptContext(now: now)
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestLaunchControlBriefURL() },
            emptyError: "No saved launch control brief yet.",
            emptyPrompt: Self.launchControlPromptWithLaunchRescueContext(
                "Copy launch control brief first.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            successPrompt: Self.launchControlPromptWithLaunchRescueContext(
                "Opened latest launch control brief.",
                routeBadge: promptContext.routeBadge,
                selfHealAttentionBadge: promptContext.selfHealAttentionBadge,
                followupRouteDecisionTraceLine: promptContext.followupRouteDecisionTraceLine
            ),
            failureError: "Could not open latest launch control brief.",
            activityDetailBase: "open-latest-launch-control-brief"
        )
    }

    private func openLatestLaunchControlHub() {
        do {
            let now = Date()
            let artifacts = try latestLaunchControlHubArtifacts()
            let artifactURLs = artifacts.orderedURLs
            let totalArtifacts = Self.launchControlHubArtifactCount
            let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason()
            let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
            let launchRescueFollowupPromptSignals = launchRescueFollowupPromptContext(
                triggerReason: launchRescueAutoTriggerReason,
                lastAutoTriggerAt: launchRescueAutoTriggerAt,
                now: now
            )

            guard !artifactURLs.isEmpty else {
                readerState.errorText = "No saved launch artifacts yet."
                readerState.petSay(
                    Self.launchControlPromptWithLaunchRescueContext(
                        "Run Launch Control Brief first.",
                        routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                        selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                        followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                            .followupRouteDecisionTraceLine
                    ),
                    mood: .ready
                )
                readerState.pulse()
                recordActivity(category: "open", detail: "open-latest-launch-control-hub-empty")
                return
            }

            if let primaryArtifactURL = artifacts.launchControlBriefURL ?? artifacts.launchRescueSnapshotURL
                ?? artifacts.launchRescueBurstURL ?? artifacts.launchCountdownURL,
               let markdown = try? String(contentsOf: primaryArtifactURL, encoding: .utf8),
               !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                readerState.answerText = markdown
                readerState.remember(text: "", answer: markdown)
            }

            let openedCount = artifactURLs.count
            let newestArtifactAgeMinutes = Self.fameOnboardingSuiteNewestArtifactAgeMinutes(
                artifactURLs: artifactURLs,
                now: now
            )
            let recencyTitle = Self.fameOnboardingSuiteArtifactRecencyTitle(
                newestArtifactAgeMinutes: newestArtifactAgeMinutes
            )
            let mood: PetMood = openedCount >= totalArtifacts ? .happy : .ready
            let prompt: String
            if openedCount >= totalArtifacts {
                prompt = Self.launchControlPromptWithLaunchRescueContext(
                    "Opened launch control hub (brief + snapshot + burst + countdown) · \(recencyTitle).",
                    routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                    selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                    followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                        .followupRouteDecisionTraceLine
                )
            } else {
                let missingNames = artifacts.missingArtifactNames.joined(separator: ", ")
                prompt = Self.launchControlPromptWithLaunchRescueContext(
                    "Opened launch control hub (\(openedCount)/\(totalArtifacts) artifacts) · \(recencyTitle). Missing: \(missingNames).",
                    routeBadge: launchRescueFollowupPromptSignals.routeBadge,
                    selfHealAttentionBadge: launchRescueFollowupPromptSignals.selfHealAttentionBadge,
                    followupRouteDecisionTraceLine: launchRescueFollowupPromptSignals
                        .followupRouteDecisionTraceLine
                )
            }

            readerState.errorText = ""
            readerState.petSay(prompt, mood: mood)
            readerState.pulse()
            readerWindow.show()
            artifactURLs.forEach(revealURL)
            recordActivity(
                category: "open",
                detail: "open-latest-launch-control-hub-\(openedCount)-of-\(totalArtifacts)"
            )
        } catch {
            readerState.errorText = "Could not open launch control hub."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "open", detail: "open-latest-launch-control-hub-error")
        }
    }

    private func openLatestCadenceMomentumBrief() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestCadenceMomentumBriefURL() },
            emptyError: "No saved cadence momentum brief yet.",
            emptyPrompt: "Run cadence momentum brief first.",
            successPrompt: "Opened latest cadence momentum brief.",
            failureError: "Could not open latest cadence momentum brief.",
            activityDetailBase: "open-latest-cadence-momentum-brief"
        )
    }

    private func openLatestCadenceShareLine() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestCadenceShareLineURL() },
            emptyError: "No saved cadence share line yet.",
            emptyPrompt: "Copy cadence share line first.",
            successPrompt: "Opened latest cadence share line.",
            failureError: "Could not open latest cadence share line.",
            activityDetailBase: "open-latest-cadence-share-line"
        )
    }

    private func openLatestCadenceSharePack() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestCadenceSharePackURL() },
            emptyError: "No saved cadence share pack yet.",
            emptyPrompt: "Copy cadence share pack first.",
            successPrompt: "Opened latest cadence share pack.",
            failureError: "Could not open latest cadence share pack.",
            activityDetailBase: "open-latest-cadence-share-pack"
        )
    }

    private func openLatestFameExceptionalLoopRecap() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestExceptionalLoopRecapURL() },
            emptyError: "No saved exceptional loop recap yet.",
            emptyPrompt: "Run Fame Exceptional Loop first.",
            successPrompt: "Opened latest exceptional loop recap.",
            failureError: "Could not open latest exceptional loop recap.",
            activityDetailBase: "open-latest-fame-exceptional-loop-recap"
        )
    }

    private func openLatestFameExceptionalLoopRecapFromSettings() {
        recordActivity(category: "open", detail: "open-latest-fame-exceptional-loop-recap-settings")
        openLatestFameExceptionalLoopRecap()
    }

    private func openLatestBreakthroughForecast() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestBreakthroughForecastURL() },
            emptyError: "No saved breakthrough forecast yet.",
            emptyPrompt: "Run breakthrough forecast first.",
            successPrompt: "Opened latest breakthrough forecast.",
            failureError: "Could not open latest breakthrough forecast.",
            activityDetailBase: "open-latest-breakthrough-forecast"
        )
    }

    private func openLatestMorningBrief() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestMorningBriefURL() },
            emptyError: "No saved morning brief yet.",
            emptyPrompt: "Run morning brief first.",
            successPrompt: "Opened latest morning brief.",
            failureError: "Could not open latest morning brief.",
            activityDetailBase: "open-latest-morning-brief"
        )
    }

    private func openLatestMiddayBrief() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestMiddayBriefURL() },
            emptyError: "No saved midday brief yet.",
            emptyPrompt: "Run midday brief first.",
            successPrompt: "Opened latest midday brief.",
            failureError: "Could not open latest midday brief.",
            activityDetailBase: "open-latest-midday-brief"
        )
    }

    private func openLatestEveningBrief() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestEveningBriefURL() },
            emptyError: "No saved evening brief yet.",
            emptyPrompt: "Run evening brief first.",
            successPrompt: "Opened latest evening brief.",
            failureError: "Could not open latest evening brief.",
            activityDetailBase: "open-latest-evening-brief"
        )
    }

    private func openLatestEscalationNudge() {
        openLatestFameArtifact(
            latestURL: { try FameSnapshotArchive.latestEscalationNudgeURL() },
            emptyError: "No saved escalation nudge yet.",
            emptyPrompt: "Run escalation nudge first.",
            successPrompt: "Opened latest escalation nudge.",
            failureError: "Could not open latest escalation nudge.",
            activityDetailBase: "open-latest-escalation-nudge"
        )
    }

    private func runFamePulseNudge() {
        do {
            let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
            let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")
            let nudge = FameSnapshotRollup.pulseNudgeFromLedger(at: ledgerURL)
            let nudgeURL = try FameSnapshotArchive.savePulseNudge(markdown: nudge)
            readerState.answerText = nudge
            readerState.remember(text: "", answer: nudge)
            copyToClipboardWithReadyPrompt(
                nudge,
                readyMessage: "Pulse nudge ready.",
                copyMessage: "Copied fame pulse nudge."
            )
            readerWindow.show()
            revealURL(nudgeURL)
            refreshFamePulseBadge()
            recordActivity(category: "share", detail: "run-fame-pulse-nudge")
        } catch {
            readerState.errorText = "Could not run fame pulse nudge."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            recordActivity(category: "share", detail: "run-fame-pulse-nudge-error")
        }
    }

    private func runFameExceptionalLoopRecoveryLaneNow(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        guard let topRecoveryLane = Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        ), let recoveryCommandID = Self.fameExceptionalLoopRecoveryLaneCommandID(
            topRecoveryLane.lastFocusToken
        ) else {
            readerState.petSay(
                "No recovery lane is armed yet. Run Fame Exceptional Loop to seed telemetry.",
                mood: .ready
            )
            readerState.pulse()
            return
        }
        let misses = max(0, topRecoveryLane.attempts - topRecoveryLane.successes)
        guard misses >= 2, topRecoveryLane.failureStreak >= 1 else {
            readerState.petSay(
                "Recovery lane is stable right now. Keep compounding from the main exceptional loop.",
                mood: .ready
            )
            readerState.pulse()
            return
        }

        runFameCommand(commandID: recoveryCommandID)
        recordActivity(
            category: "support",
            detail: "run-fame-exceptional-loop-recovery-lane-now-\(ActivityLogCommand.safeID(recoveryCommandID))"
        )
    }

    private func runFameExceptionalLoopRecoveryLaneNowFromSettings() {
        recordActivity(category: "support", detail: "run-fame-exceptional-loop-recovery-lane-now-settings")
        runFameExceptionalLoopRecoveryLaneNow()
    }

    private func fameExceptionalLoopHealthSnapshot(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopHealthSnapshot {
        let outcomeScoreboard = Self.fameExceptionalLoopOutcomeScoreboard(
            defaults: defaults,
            totalCountKey: fameExceptionalLoopOutcomeTotalCountKey,
            successCountKey: fameExceptionalLoopOutcomeSuccessCountKey,
            successStreakKey: fameExceptionalLoopOutcomeSuccessStreakKey,
            failureStreakKey: fameExceptionalLoopOutcomeFailureStreakKey,
            lastFocusTokenKey: fameExceptionalLoopOutcomeLastFocusTokenKey,
            lastAtKey: fameExceptionalLoopOutcomeLastAtKey
        )
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        return Self.fameExceptionalLoopHealthSnapshot(
            scoreboard: outcomeScoreboard,
            history: windowedCommandHistory
        )
    }

    @discardableResult
    private func runFameExceptionalLoopHealthRecommendedActionFromSettings(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        shouldExecuteCommand: Bool = true
    ) -> String {
        let snapshot = fameExceptionalLoopHealthSnapshot(now: now, defaults: defaults)
        let commandID = snapshot.recommendedActionCommandID
        recordActivity(
            category: "support",
            detail: "run-fame-exceptional-loop-health-recommended-action-settings-\(ActivityLogCommand.safeID(commandID))"
        )
        if shouldExecuteCommand {
            runFameCommand(commandID: commandID)
        }
        return commandID
    }

    private func fameExceptionalLoopRecoveryLaneAutoRunLastAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        guard defaults.object(forKey: fameExceptionalLoopRecoveryLaneAutoRunLastAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: fameExceptionalLoopRecoveryLaneAutoRunLastAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private struct FameExceptionalLoopAutoRecoveryLaneTuningContext {
        let topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?
        let missesRequired: Int
        let failureStreakRequired: Int
        let cooldownMinutes: Int
        let recommendation: FameExceptionalLoopAutoRecoveryLaneTuningRecommendation?
    }

    private func fameExceptionalLoopAutoRecoveryLaneTuningContext(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopAutoRecoveryLaneTuningContext {
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let topRecoveryLane = Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        )
        let missesRequired = fameExceptionalLoopAutoRecoveryLaneMissesRequired
        let failureStreakRequired = fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        let cooldownMinutes = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        return FameExceptionalLoopAutoRecoveryLaneTuningContext(
            topRecoveryLane: topRecoveryLane,
            missesRequired: missesRequired,
            failureStreakRequired: failureStreakRequired,
            cooldownMinutes: cooldownMinutes,
            recommendation: Self.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                topRecoveryLane: topRecoveryLane
            )
        )
    }

    private func runFameExceptionalLoopAutoRecoveryLaneAutoTune(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        let context = fameExceptionalLoopAutoRecoveryLaneTuningContext(now: now, defaults: defaults)
        let currentSummary = Self.fameExceptionalLoopAutoRecoveryLaneTuningDetailSummary(
            missesRequired: context.missesRequired,
            failureStreakRequired: context.failureStreakRequired,
            cooldownMinutes: context.cooldownMinutes
        )
        guard let recommendation = context.recommendation else {
            readerState.petSay(
                "Need at least 3 recent recovery-lane attempts before auto-tune can calibrate.",
                mood: .ready
            )
            readerState.pulse()
            recordActivity(
                category: "support",
                detail: "auto-tune-fame-exceptional-loop-recovery-missing-telemetry-current-\(ActivityLogCommand.safeID(currentSummary))"
            )
            return
        }

        let recommendationSummary = Self.fameExceptionalLoopAutoRecoveryLaneTuningDetailSummary(
            missesRequired: recommendation.missesRequired,
            failureStreakRequired: recommendation.failureStreakRequired,
            cooldownMinutes: recommendation.cooldownMinutes
        )
        let isAlreadyAligned = recommendation.missesRequired == context.missesRequired
            && recommendation.failureStreakRequired == context.failureStreakRequired
            && recommendation.cooldownMinutes == context.cooldownMinutes
        if isAlreadyAligned {
            readerState.petSay(
                "Exceptional loop tuning already matches telemetry (\(currentSummary)).",
                mood: .happy
            )
            readerState.pulse()
            updateFameExceptionalLoopMenuStatus(now: now, defaults: defaults)
            commandPalette.requestRefresh()
            recordActivity(
                category: "support",
                detail: "auto-tune-fame-exceptional-loop-recovery-noop-\(ActivityLogCommand.safeID(currentSummary))"
            )
            return
        }

        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired = recommendation.missesRequired
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
            recommendation.failureStreakRequired
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes =
            recommendation.cooldownMinutes
        updateFameExceptionalLoopMenuStatus(now: now, defaults: defaults)
        commandPalette.requestRefresh()
        rewardHUD.show(
            "Exceptional Loop Auto-Tuned",
            mood: .success,
            intensity: settings.feelIntensity
        )
        readerState.petSay(
            "Applied \(recommendationSummary). \(recommendation.rationale)",
            mood: .happy
        )
        readerState.pulse()
        flashStatus(symbol: "slider.horizontal.3", tint: .systemTeal, length: 0.2)
        recordActivity(
            category: "support",
            detail: "auto-tune-fame-exceptional-loop-recovery-\(ActivityLogCommand.safeID(currentSummary))-to-\(ActivityLogCommand.safeID(recommendationSummary))"
        )
    }

    private func runFameExceptionalLoopAutoRecoveryLaneAutoTuneFromSettings(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        runFameExceptionalLoopAutoRecoveryLaneAutoTune(now: now, defaults: defaults)
    }

    private func maybeRunFameExceptionalLoopAutoRecoveryLane(
        plan: FameExceptionalLoopPlan,
        wasSuccessful: Bool,
        topRecoveryLane: FameExceptionalLoopOutcomeScoreboard?,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String? {
        guard let recoveryCommandID = Self.fameExceptionalLoopAutoRecoveryLaneCommandID(
            wasSuccessful: wasSuccessful,
            topRecoveryLane: topRecoveryLane,
            primaryCommandID: plan.primaryCommandID,
            followupCommandID: plan.followupActionID,
            lastAutoRunAt: fameExceptionalLoopRecoveryLaneAutoRunLastAt(defaults: defaults),
            now: now,
            missesRequired: fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            failureStreakRequired: fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            cooldown: fameExceptionalLoopAutoRecoveryLaneCooldown
        ), let topRecoveryLane else {
            return nil
        }

        runFameCommand(commandID: recoveryCommandID)
        defaults.set(now.timeIntervalSince1970, forKey: fameExceptionalLoopRecoveryLaneAutoRunLastAtKey)
        recordActivity(
            category: "support",
            detail: "run-fame-exceptional-loop-auto-recovery-lane-\(ActivityLogCommand.safeID(recoveryCommandID))"
        )
        return Self.fameExceptionalLoopAutoRecoveryLaneRunSummary(
            commandID: recoveryCommandID,
            misses: max(0, topRecoveryLane.attempts - topRecoveryLane.successes),
            attempts: topRecoveryLane.attempts,
            failureStreak: topRecoveryLane.failureStreak
        )
    }

    private func runFameExceptionalLoop(now: Date = Date()) {
        let plan = fameExceptionalLoopPlan(now: now)

        runFameCommand(commandID: plan.primaryCommandID)
        if let followupActionID = plan.followupActionID {
            runFameCommand(commandID: followupActionID)
        }

        let primarySucceeded = fameExceptionalLoopCommandSucceeded(plan.primaryCommandID, now: now)
        let followupSucceeded = plan.followupActionID.map {
            fameExceptionalLoopCommandSucceeded($0, now: now)
        } ?? true
        let commandsSucceeded = primarySucceeded && followupSucceeded
        let currentOutcomeScoreboard = fameExceptionalLoopOutcomeScoreboard(now: now)
        let currentOutcomeCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: .standard,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let projectedOutcomeCommandHistory = Self.fameExceptionalLoopProjectedOutcomeCommandHistory(
            Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
                currentOutcomeCommandHistory,
                now: now
            ),
            plan: plan,
            wasSuccessful: commandsSucceeded,
            now: now
        )
        let projectedLaneSummaries = Self.fameExceptionalLoopOutcomeLaneSummaries(
            history: projectedOutcomeCommandHistory
        )
        let projectedRecoveryActionSummary = Self.fameExceptionalLoopRecoveryLaneActionSummary(
            Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
                history: projectedOutcomeCommandHistory
            )
        )
        let projectedOutcomeScoreboard = Self.fameExceptionalLoopProjectedOutcomeScoreboard(
            current: currentOutcomeScoreboard,
            plan: plan,
            wasSuccessful: commandsSucceeded,
            now: now
        )
        let projectedOutcomeStatusTitle = Self.fameExceptionalLoopOutcomeStatusTitle(
            projectedOutcomeScoreboard
        )

        let recapMarkdown = Self.fameExceptionalLoopRecapMarkdown(
            plan: plan,
            generatedAt: Self.launchControlBriefGeneratedAt(now),
            projectedOutcomeStatusTitle: projectedOutcomeStatusTitle,
            projectedLaneSummaries: projectedLaneSummaries,
            projectedRecoveryActionSummary: projectedRecoveryActionSummary
        )
        let didSaveRecap = saveFameExceptionalLoopRecapArtifact(
            markdown: recapMarkdown,
            now: now
        ) != nil
        let wasSuccessful = didSaveRecap && commandsSucceeded
        let outcomeScoreboard = recordFameExceptionalLoopOutcome(
            plan: plan,
            wasSuccessful: wasSuccessful,
            now: now
        )
        let outcomeStatusTitle = Self.fameExceptionalLoopOutcomeStatusTitle(outcomeScoreboard)
        let outcomeCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: .standard,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let outcomeWindowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            outcomeCommandHistory,
            now: now
        )
        let outcomeLaneSummaries = Self.fameExceptionalLoopOutcomeLaneSummaries(
            history: outcomeWindowedCommandHistory
        )
        let outcomeTopRecoveryLane = Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: outcomeWindowedCommandHistory
        )
        let outcomeRecoveryActionSummary = Self.fameExceptionalLoopRecoveryLaneActionSummary(
            outcomeTopRecoveryLane
        )
        let autoRecoveryRunSummary = maybeRunFameExceptionalLoopAutoRecoveryLane(
            plan: plan,
            wasSuccessful: wasSuccessful,
            topRecoveryLane: outcomeTopRecoveryLane,
            now: now
        )
        let completionMessage = Self.fameExceptionalLoopCompletionMessage(plan)
        let autoRecoverySuffix = autoRecoveryRunSummary.map { " \($0)" } ?? ""
        readerState.petSay(
            didSaveRecap
                ? "\(completionMessage) Recap saved. Open latest recap when you need the run sheet. \(outcomeStatusTitle) Top recovery lane: \(outcomeLaneSummaries.topRecoveryLane). Recovery next action: \(outcomeRecoveryActionSummary).\(autoRecoverySuffix)"
                : "\(completionMessage) Recap save failed; rerun if you need an artifact. \(outcomeStatusTitle) Top recovery lane: \(outcomeLaneSummaries.topRecoveryLane). Recovery next action: \(outcomeRecoveryActionSummary).\(autoRecoverySuffix)",
            mood: .ready
        )
        if didSaveRecap && wasSuccessful {
            readerState.errorText = ""
        } else if !wasSuccessful {
            readerState.errorText = "Exceptional loop ran, but outcome telemetry suggests recovery is still needed."
        }
        readerState.pulse()
        updateFameExceptionalLoopMenuStatus(now: now)
        recordActivity(
            category: "support",
            detail: Self.fameExceptionalLoopActivityDetail(plan)
        )
        recordActivity(
            category: "support",
            detail: "run-fame-exceptional-loop-outcome-\(wasSuccessful ? "success" : "failure")-success-streak-\(outcomeScoreboard.successStreak)-failure-streak-\(outcomeScoreboard.failureStreak)"
        )
    }

    private enum FameNextMoveFollowup {
        case none
        case copyDraftPack
        case cadenceExecutionKit
    }

    private func runFameNextMove(commandID: String? = nil, followup: FameNextMoveFollowup = .none) {
        let resolvedCommandID = commandID ?? fameNextMoveMenuCommandID()
        let signal = famePulseAlertSignal()
        let transition = famePulseLatestTransition()
        let scorecard = fameDailyScorecardState()
        let shouldCopyHandoffToClipboard: Bool
        switch followup {
        case .none:
            shouldCopyHandoffToClipboard = true
        case .copyDraftPack, .cadenceExecutionKit:
            shouldCopyHandoffToClipboard = false
        }
        runFameCommand(commandID: resolvedCommandID)
        let handoff = saveFameNextMoveHandoff(
            commandID: resolvedCommandID,
            signal: signal,
            transition: transition,
            scorecard: scorecard,
            copyHandoffToClipboard: shouldCopyHandoffToClipboard
        )
        switch followup {
        case .none:
            break
        case .copyDraftPack:
            if let handoff {
                let didCopyDraftPack = copyNextMoveDraftPack(
                    from: handoff,
                    activityDetailBase: "copy-next-move-drafts",
                    copyMessage: "Copied next-move draft pack.",
                    missingDraftError: "New handoff missing post drafts.",
                    missingDraftPrompt: Self.fameNextMoveRunAgainPrompt
                )
                if didCopyDraftPack,
                   let draftPack = FameSnapshotRollup.nextMoveDraftPack(from: handoff) {
                    _ = saveNextMoveDraftPackArtifact(markdown: draftPack)
                }
                recordActivity(
                    category: "support",
                    detail: "run-fame-next-move-copy-drafts-\(ActivityLogCommand.safeID(resolvedCommandID))"
                )
            } else {
                reportNextMoveHandoffSaveFailure(
                    activityDetail: "run-fame-next-move-copy-drafts-error"
                )
            }
        case .cadenceExecutionKit:
            if let handoff {
                switch Self.nextMoveCadenceExecutionKitCopyOutcome(handoffMarkdown: handoff) {
                case .missingHandoff:
                    reportNextMoveHandoffSaveFailure(
                        activityDetail: "run-fame-next-move-cadence-execution-kit-error"
                    )
                case .missingCadenceStep:
                    reportNextMoveMissingCadenceStep(
                        activityDetailBase: "copy-next-move-cadence-execution-kit",
                        errorText: "New handoff missing cadence step.",
                    )
                case .missingDraft:
                    reportNextMoveMissingDraft(
                        errorText: "New handoff missing cadence execution kit drafts.",
                        activityDetailBase: "copy-next-move-cadence-execution-kit"
                    )
                case .ready(let post, let kit):
                    presentNextMoveCopyBundlePreservingPrompt(
                        post,
                        bundle: kit,
                        copyMessage: "Copied cadence execution post."
                    )
                    recordActivity(category: "share", detail: "copy-next-move-cadence-execution-kit")
                }
                recordActivity(
                    category: "support",
                    detail: "run-fame-next-move-cadence-execution-kit-\(ActivityLogCommand.safeID(resolvedCommandID))"
                )
            } else {
                reportNextMoveHandoffSaveFailure(
                    activityDetail: "run-fame-next-move-cadence-execution-kit-error"
                )
            }
        }
        recordActivity(
            category: "support",
            detail: "run-fame-next-move-\(ActivityLogCommand.safeID(resolvedCommandID))"
        )
    }

    private func reportNextMoveHandoffSaveFailure(activityDetail: String) {
        presentNextMoveError(
            "Could not save next move handoff.",
            activityCategory: "support",
            activityDetail: activityDetail
        )
    }

    private func runFameCommand(commandID: String) {
        switch commandID {
        case "run-fame-exceptional-loop":
            runFameExceptionalLoop()
        case "run-fame-exceptional-loop-recovery-lane-now":
            runFameExceptionalLoopRecoveryLaneNow()
        case "auto-tune-fame-exceptional-loop-recovery":
            runFameExceptionalLoopAutoRecoveryLaneAutoTune()
        case "reset-fame-exceptional-loop-tuning":
            resetFameExceptionalLoopOutcomeTuningFromCommand()
        case "run-fame-next-move-copy-drafts":
            runFameNextMove(followup: .copyDraftPack)
        case "run-fame-next-move-cadence-execution-kit":
            runFameNextMove(followup: .cadenceExecutionKit)
        case "run-fame-escalation-nudge":
            runFameEscalationNudge()
        case "run-fame-recovery-sprint":
            runFameRecoverySprint()
        case "run-fame-command-center":
            runFameCommandCenter()
        case "run-fame-breakthrough-forecast":
            runFameBreakthroughForecast()
        case "run-fame-daily-checkpoint":
            runFameDailyCheckpoint()
        case "run-fame-spotlight-pack":
            runFameSpotlightPack()
        case "run-fame-launch-day-script":
            runFameLaunchDayScript()
        case "run-fame-launch-countdown":
            runFameLaunchCountdown()
        case "run-fame-launch-rescue-burst":
            runFameLaunchRescueBurst()
        case "run-fame-launch-rescue-followup-now":
            runFameLaunchRescueFollowupNow()
        case "run-fame-launch-control-brief":
            runFameLaunchControlBrief()
        case "run-fame-launch-control-hub":
            runFameLaunchControlHub()
        case "run-fame-launch-rescue-snapshot":
            runFameLaunchRescueSnapshot()
        case "copy-fame-launch-control-brief":
            copyFameLaunchControlBrief()
        case "copy-fame-launch-rescue-snapshot":
            copyFameLaunchRescueSnapshot()
        case "copy-fame-cadence-share-line":
            copyFameCadenceShareLine()
        case "copy-fame-cadence-share-pack":
            copyFameCadenceSharePack()
        case "open-latest-fame-exceptional-loop-recap":
            openLatestFameExceptionalLoopRecap()
        case "open-latest-launch-control-hub":
            openLatestLaunchControlHub()
        case "run-fame-onboarding-daily-brief":
            runFameOnboardingDailyBrief()
        case "run-fame-onboarding-scorecard":
            runFameOnboardingScorecard()
        case "run-fame-onboarding-nudge":
            runFameOnboardingNudge()
        case "run-fame-onboarding-fill-gap":
            runFameOnboardingFillGap()
        case "run-fame-cadence-momentum-brief":
            runFameCadenceMomentumBrief()
        case "run-fame-cadence-autopilot-loop":
            runFameCadenceAutopilotLoop()
        case "run-fame-cadence-celebration-demo":
            runCadenceCelebrationDemo()
        case "run-fame-sprint-snapshot":
            runFameSprintSnapshot()
        default:
            runFamePulseNudge()
        }
    }

    private func runFameOnboardingRecoveryQuickRun(
        actionID: String,
        source: FameOnboardingRecoveryQuickRunSource = .other,
        now: Date = Date()
    ) {
        runLaunchRecoveryQuickRunPulseIfNeeded(actionID: actionID, source: source, now: now)

        switch actionID {
        case "run-fame-onboarding-fill-gap":
            recordCommandAction(actionID)
            runFameOnboardingFillGap()
        case "run-fame-onboarding-daily-brief":
            recordCommandAction(actionID)
            runFameOnboardingDailyBrief()
        case "run-fame-onboarding-scorecard":
            recordCommandAction(actionID)
            runFameOnboardingScorecard()
        case "run-fame-onboarding-nudge":
            recordCommandAction(actionID)
            runFameOnboardingNudge()
        case "run-fame-next-move-cadence-execution-kit":
            recordCommandAction(actionID)
            runFameNextMove(followup: .cadenceExecutionKit)
        case "run-fame-cadence-autopilot-loop":
            recordCommandAction(actionID)
            runFameCadenceAutopilotLoop()
        default:
            readerState.petSay("Onboarding recovery quick run is unavailable.", mood: .ready)
            readerState.pulse()
            recordActivity(category: "support", detail: "run-fame-onboarding-recovery-next-invalid")
            return
        }

        recordActivity(
            category: "support",
            detail: "run-fame-onboarding-recovery-next-\(ActivityLogCommand.safeID(actionID))"
        )
        if source.shouldShowLaunchRecoveryPulse {
            recordActivity(
                category: "support",
                detail: Self.launchRecoveryQuickRunActivityDetail(
                    source: source.rawValue,
                    actionID: actionID
                )
            )
        }
    }

    private func runLaunchRecoveryQuickRunPulseIfNeeded(
        actionID: String,
        source: FameOnboardingRecoveryQuickRunSource,
        now: Date = Date()
    ) {
        guard source.shouldShowLaunchRecoveryPulse else { return }
        let snapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        let remainingArtifacts = max(0, snapshot.remainingArtifacts ?? 0)
        rewardHUD.show(
            "Launch Recovery Next",
            mood: .working,
            intensity: min(1.05, settings.feelIntensity * 0.78)
        )
        readerState.petSay(
            Self.launchRecoveryQuickRunPulseMessage(
                actionID: actionID,
                remainingArtifacts: remainingArtifacts
            ),
            mood: .ready
        )
        readerState.pulse()
        flashStatus(
            symbol: remainingArtifacts > 0 ? "checkmark.seal" : "checkmark.seal.fill",
            tint: .systemTeal,
            length: remainingArtifacts > 0 ? 0.15 : 0.18
        )
        recordActivity(
            category: "support",
            detail: Self.launchRecoveryQuickRunPulseActivityDetail(
                source: source.rawValue,
                actionID: actionID
            )
        )
    }

    private func showLaunchRecoveryGlobalHotKeyFallbackPulse(actionID: String) {
        rewardHUD.show(
            Self.launchRecoveryGlobalHotKeyFallbackPulseTitle(),
            mood: .working,
            intensity: min(1.08, settings.feelIntensity * 0.76)
        )
        readerState.petSay(
            Self.launchRecoveryGlobalHotKeyFallbackPulseMessage(actionID: actionID),
            mood: .ready
        )
        readerState.pulse()
        flashStatus(
            symbol: "arrow.triangle.branch",
            tint: .systemTeal,
            length: 0.17
        )
        recordActivity(
            category: "support",
            detail: Self.launchRecoveryGlobalHotKeyFallbackPulseActivityDetail(
                actionID: actionID
            )
        )
    }

    private func saveFameNextMoveHandoff(
        commandID: String,
        signal: FamePulseAlertSignal?,
        transition: FamePulseRiskTransition?,
        scorecard: FameDailyScorecardState,
        copyHandoffToClipboard: Bool = true
    ) -> String? {
        let commandLabel = Self.fameNextMoveCommandLabel(commandID)
        let handoff = FameSnapshotRollup.nextMoveHandoff(
            commandID: commandID,
            commandLabel: commandLabel,
            signal: signal,
            transition: transition,
            scorecard: scorecard
        )

        do {
            let handoffURL = try FameSnapshotArchive.saveNextMoveHandoff(markdown: handoff)
            if copyHandoffToClipboard {
                copyToClipboardPreservingPrompt(
                    handoff,
                    copyMessage: "Copied founder fame next-move handoff.",
                    clearError: true
                )
            }
            revealURL(handoffURL)
            recordActivity(
                category: "saved",
                detail: "save-fame-next-move-handoff-\(ActivityLogCommand.safeID(commandID))"
            )
            return handoff
        } catch {
            recordActivity(category: "saved", detail: "save-fame-next-move-handoff-error")
            return nil
        }
    }

    @discardableResult
    private func copyNextMoveDraftPack(
        from handoff: String,
        activityDetailBase: String,
        copyMessage: String,
        missingDraftError: String,
        missingDraftPrompt: String? = nil,
        readyMessage: String? = nil
    ) -> Bool {
        guard let draftPack = FameSnapshotRollup.nextMoveDraftPack(from: handoff) else {
            if let missingDraftPrompt {
                reportNextMoveCopyMissing(
                    errorText: missingDraftError,
                    prompt: missingDraftPrompt,
                    activityDetail: "\(activityDetailBase)-missing"
                )
            } else {
                readerState.errorText = missingDraftError
                recordActivity(category: "share", detail: "\(activityDetailBase)-missing")
            }
            return false
        }

        if let readyMessage {
            copyToClipboardWithReadyPrompt(
                draftPack,
                readyMessage: readyMessage,
                copyMessage: copyMessage
            )
        } else {
            copyToClipboardPreservingPrompt(
                draftPack,
                copyMessage: copyMessage,
                clearError: true
            )
        }
        recordActivity(category: "share", detail: activityDetailBase)
        return true
    }

    @discardableResult
    private func saveNextMoveDraftPackArtifact(
        markdown: String,
        now: Date = Date(),
        baseDirectory: URL? = nil,
        activityDetailBase: String = "save-fame-next-move-draft-pack"
    ) -> URL? {
        do {
            let draftPackURL = try FameSnapshotArchive.saveNextMoveDraftPack(
                markdown: markdown,
                now: now,
                baseDirectory: baseDirectory
            )
            recordActivity(category: "saved", detail: activityDetailBase)
            return draftPackURL
        } catch {
            recordActivity(category: "saved", detail: "\(activityDetailBase)-error")
            return nil
        }
    }

    private func latestNextMoveHandoffMarkdown() throws -> String? {
        guard let handoffURL = try FameSnapshotArchive.latestNextMoveHandoffURL() else {
            return nil
        }
        return (try? String(contentsOf: handoffURL, encoding: .utf8)) ?? ""
    }

    private func reportNextMoveCopyMissing(
        errorText: String,
        prompt: String,
        activityDetail: String
    ) {
        readerState.errorText = errorText
        readerState.petSay(prompt, mood: .ready)
        readerState.pulse()
        recordActivity(category: "share", detail: activityDetail)
    }

    private func reportNextMoveMissingHandoff(
        activityDetailBase: String,
        detailSuffix: String = "empty"
    ) {
        reportNextMoveCopyMissing(
            errorText: Self.fameNextMoveMissingHandoffError,
            prompt: Self.fameNextMoveRunFirstPrompt,
            activityDetail: "\(activityDetailBase)-\(detailSuffix)"
        )
    }

    private func reportNextMoveMissingCadenceStep(
        activityDetailBase: String,
        errorText: String? = nil,
        detailSuffix: String = "missing-cadence"
    ) {
        reportNextMoveCopyMissing(
            errorText: errorText ?? Self.fameNextMoveMissingCadenceStepError,
            prompt: Self.fameNextMoveRunAgainPrompt,
            activityDetail: "\(activityDetailBase)-\(detailSuffix)"
        )
    }

    private func reportNextMoveMissingDraft(
        errorText: String,
        activityDetailBase: String,
        detailSuffix: String = "missing-draft"
    ) {
        reportNextMoveCopyMissing(
            errorText: errorText,
            prompt: Self.fameNextMoveRunAgainPrompt,
            activityDetail: "\(activityDetailBase)-\(detailSuffix)"
        )
    }

    private func reportNextMoveCopyFailure(
        errorText: String,
        activityDetail: String
    ) {
        presentNextMoveError(
            errorText,
            activityCategory: "share",
            activityDetail: activityDetail
        )
    }

    private func presentNextMoveError(
        _ errorText: String,
        activityCategory: String,
        activityDetail: String
    ) {
        readerState.errorText = errorText
        effects.play(.error, settings: settings)
        flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
        recordActivity(category: activityCategory, detail: activityDetail)
    }

    private func presentNextMoveCopyBundle(
        post: String,
        bundle: String,
        readyMessage: String,
        copyMessage: String
    ) {
        readerState.answerText = bundle
        readerState.errorText = ""
        readerState.remember(text: "", answer: bundle)
        copyToClipboardWithReadyPrompt(
            post,
            readyMessage: readyMessage,
            copyMessage: copyMessage,
            clearError: false,
            pulse: false
        )
        readerState.pulse()
        readerWindow.show()
    }

    private func presentNextMoveCopyBundlePreservingPrompt(
        _ post: String,
        bundle: String,
        copyMessage: String
    ) {
        copyToClipboardPreservingPrompt(post, copyMessage: copyMessage)
        readerState.answerText = bundle
        readerState.errorText = ""
        readerState.remember(text: "", answer: bundle)
        readerState.pulse()
        readerWindow.show()
    }

    private func copyLatestNextMoveDraftPack() {
        let activityDetailBase = "copy-next-move-drafts"
        do {
            if let draftPackURL = try FameSnapshotArchive.latestNextMoveDraftPackURL() {
                let draftPack = (try? String(contentsOf: draftPackURL, encoding: .utf8)) ?? ""
                if !draftPack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    copyToClipboardWithReadyPrompt(
                        draftPack,
                        readyMessage: "Next-move draft pack ready.",
                        copyMessage: "Copied next-move draft pack."
                    )
                    recordActivity(category: "share", detail: activityDetailBase)
                    return
                }
            }

            guard let handoff = try latestNextMoveHandoffMarkdown() else {
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            }
            let didCopy = copyNextMoveDraftPack(
                from: handoff,
                activityDetailBase: activityDetailBase,
                copyMessage: "Copied next-move draft pack.",
                missingDraftError: "Latest handoff missing post drafts.",
                missingDraftPrompt: Self.fameNextMoveRunAgainPrompt,
                readyMessage: "Next-move draft pack ready."
            )
            if didCopy,
               let draftPack = FameSnapshotRollup.nextMoveDraftPack(from: handoff) {
                _ = saveNextMoveDraftPackArtifact(markdown: draftPack)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy latest next-move draft.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveCadenceStep() {
        let activityDetailBase = "copy-next-move-cadence-step"
        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveCadenceStepCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingCadenceStep:
                reportNextMoveMissingCadenceStep(
                    activityDetailBase: activityDetailBase,
                    detailSuffix: "missing"
                )
                return
            case .ready(let firstStep):
                copyToClipboardWithReadyPrompt(
                    firstStep,
                    readyMessage: "First cadence step ready.",
                    copyMessage: "Copied first cadence step."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy first cadence step.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveCadencePost() {
        let activityDetailBase = "copy-next-move-cadence-post"
        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveCadencePostCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingCadenceStep:
                reportNextMoveMissingCadenceStep(activityDetailBase: activityDetailBase)
                return
            case .missingDraft:
                reportNextMoveMissingDraft(
                    errorText: "Latest cadence step missing draft.",
                    activityDetailBase: activityDetailBase
                )
                return
            case .ready(let post):
                copyToClipboardWithReadyPrompt(
                    post,
                    readyMessage: "Cadence post ready now.",
                    copyMessage: "Copied cadence post now."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy cadence post now.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveCadencePostQueue() {
        let activityDetailBase = "copy-next-move-cadence-post-queue"
        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveCadencePostQueueCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingCadenceStep:
                reportNextMoveMissingCadenceStep(activityDetailBase: activityDetailBase)
                return
            case .missingDraft:
                reportNextMoveMissingDraft(
                    errorText: "Latest handoff missing cadence queue drafts.",
                    activityDetailBase: activityDetailBase
                )
                return
            case .ready(let post, let queue):
                presentNextMoveCopyBundle(
                    post: post,
                    bundle: queue,
                    readyMessage: "Cadence post queue ready.",
                    copyMessage: "Copied cadence post + queue."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy cadence post queue.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveCadenceExecutionKit() {
        let activityDetailBase = "copy-next-move-cadence-execution-kit"
        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveCadenceExecutionKitCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingCadenceStep:
                reportNextMoveMissingCadenceStep(activityDetailBase: activityDetailBase)
                return
            case .missingDraft:
                reportNextMoveMissingDraft(
                    errorText: "Latest handoff missing cadence execution kit drafts.",
                    activityDetailBase: activityDetailBase
                )
                return
            case .ready(let post, let kit):
                presentNextMoveCopyBundle(
                    post: post,
                    bundle: kit,
                    readyMessage: "Cadence execution kit ready.",
                    copyMessage: "Copied cadence execution post."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy cadence execution kit.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveReplyLadder() {
        let activityDetailBase = "copy-next-move-reply-ladder"
        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveReplyLadderCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingCadenceStep:
                reportNextMoveMissingCadenceStep(activityDetailBase: activityDetailBase)
                return
            case .missingDraft:
                reportNextMoveMissingDraft(
                    errorText: "Latest handoff missing reply ladder drafts.",
                    activityDetailBase: activityDetailBase
                )
                return
            case .ready(let ladder):
                copyToClipboardWithReadyPrompt(
                    ladder,
                    readyMessage: "Next-move reply ladder ready.",
                    copyMessage: "Copied next-move reply ladder."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy next-move reply ladder.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveLaunchNowSequence() {
        let activityDetailBase = "copy-next-move-launch-now-sequence"
        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveLaunchNowSequenceCopyOutcome(handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingCadenceStep:
                reportNextMoveMissingCadenceStep(activityDetailBase: activityDetailBase)
                return
            case .missingDraft:
                reportNextMoveMissingDraft(
                    errorText: "Latest handoff missing launch-now sequence drafts.",
                    activityDetailBase: activityDetailBase
                )
                return
            case .ready(let sequence):
                copyToClipboardWithReadyPrompt(
                    sequence,
                    readyMessage: "Launch-now sequence ready.",
                    copyMessage: "Copied launch now sequence."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy launch now sequence.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveChannelDraft(_ channel: NextMoveDraftChannel) {
        let channelTitle = Self.nextMoveDraftChannelTitle(channel)
        let activityDetailBase = Self.nextMoveDraftChannelActivityDetailBase(channel)

        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()

            switch Self.nextMoveChannelDraftCopyOutcome(channel: channel, handoffMarkdown: handoffMarkdown) {
            case .missingHandoff:
                reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
                return
            case .missingDraft:
                reportNextMoveMissingDraft(
                    errorText: "Latest handoff missing \(channelTitle) draft.",
                    activityDetailBase: activityDetailBase,
                    detailSuffix: "missing"
                )
                return
            case .ready(let draft):
                copyToClipboardWithReadyPrompt(
                    draft,
                    readyMessage: "\(channelTitle) draft ready.",
                    copyMessage: "Copied \(channelTitle) draft."
                )
                recordActivity(category: "share", detail: activityDetailBase)
            }
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy latest \(channelTitle) draft.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    @discardableResult
    private func applyNextMoveBestChannelLaunchPackCopyOutcome(
        _ outcome: NextMoveBestChannelLaunchPackCopyOutcome,
        activityDetailBase: String
    ) -> NextMoveBestChannelLaunchPackCopyOutcome {
        switch outcome {
        case .missingHandoff:
            reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
        case .missingCadenceStep:
            reportNextMoveMissingCadenceStep(
                activityDetailBase: activityDetailBase,
                errorText: Self.fameNextMoveMissingFirstCadenceChannelError
            )
        case .missingDraft:
            reportNextMoveMissingDraft(
                errorText: "Latest handoff missing best channel launch pack drafts.",
                activityDetailBase: activityDetailBase
            )
        case .ready(let channel, let post, let pack):
            let channelTitle = Self.nextMoveDraftChannelTitle(channel)
            presentNextMoveCopyBundle(
                post: post,
                bundle: pack,
                readyMessage: "Best channel launch pack ready (\(channelTitle)).",
                copyMessage: "Copied best channel post (\(channelTitle))."
            )
            recordActivity(
                category: "share",
                detail: "\(activityDetailBase)-\(Self.nextMoveCadencePrimaryChannelToken(channel))"
            )
        }

        return outcome
    }

    @discardableResult
    private func applyNextMoveBestChannelDraftCopyOutcome(
        _ outcome: NextMoveBestChannelDraftCopyOutcome,
        activityDetailBase: String
    ) -> NextMoveBestChannelDraftCopyOutcome {
        switch outcome {
        case .missingHandoff:
            reportNextMoveMissingHandoff(activityDetailBase: activityDetailBase)
        case .missingCadenceStep:
            reportNextMoveMissingCadenceStep(
                activityDetailBase: activityDetailBase,
                errorText: Self.fameNextMoveMissingFirstCadenceChannelError
            )
        case .missingDraft:
            reportNextMoveMissingDraft(
                errorText: "Latest handoff missing best channel draft.",
                activityDetailBase: activityDetailBase
            )
        case .ready(let channel, let draft):
            let channelTitle = Self.nextMoveDraftChannelTitle(channel)
            copyToClipboardWithReadyPrompt(
                draft,
                readyMessage: "Best channel draft ready (\(channelTitle)).",
                copyMessage: "Copied best channel draft (\(channelTitle))."
            )
            recordActivity(
                category: "share",
                detail: "\(activityDetailBase)-\(Self.nextMoveCadencePrimaryChannelToken(channel))"
            )
        }

        return outcome
    }

    private func copyLatestNextMoveBestChannelLaunchPack() {
        let activityDetailBase = "copy-next-move-best-channel-launch-pack"

        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()
            let outcome = Self.nextMoveBestChannelLaunchPackCopyOutcome(handoffMarkdown: handoffMarkdown)
            _ = applyNextMoveBestChannelLaunchPackCopyOutcome(
                outcome,
                activityDetailBase: activityDetailBase
            )
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy best channel launch pack.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyLatestNextMoveBestChannelDraft() {
        let activityDetailBase = "copy-next-move-best-channel-draft"

        do {
            let handoffMarkdown = try latestNextMoveHandoffMarkdown()
            let outcome = Self.nextMoveBestChannelDraftCopyOutcome(handoffMarkdown: handoffMarkdown)
            _ = applyNextMoveBestChannelDraftCopyOutcome(
                outcome,
                activityDetailBase: activityDetailBase
            )
        } catch {
            reportNextMoveCopyFailure(
                errorText: "Could not copy best channel draft.",
                activityDetail: "\(activityDetailBase)-error"
            )
        }
    }

    private func copyFamePack() {
        let snapshot = growthSnapshotCounts()
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let pack = SetupGuideReport.famePack(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount,
            cadenceExecutionKitCurrentStreak: cadenceStreak.current,
            cadenceExecutionKitBestStreak: cadenceStreak.best
        )
        copyToClipboardWithReadyPrompt(
            pack,
            readyMessage: "Fame pack ready.",
            copyMessage: "Copied fame pack."
        )
        recordActivity(category: "share", detail: "copy-fame-pack")
    }

    private func copyFounderCommandPresets() {
        let presets = FounderCommandPreset.markdown()
        copyToClipboardWithReadyPrompt(
            presets,
            readyMessage: "Founder command presets ready.",
            copyMessage: "Copied founder presets."
        )
        recordActivity(category: "share", detail: "copy-founder-command-presets")
    }

    private func saveFamePack() {
        let snapshot = growthSnapshotCounts()
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot()
        let pack = SetupGuideReport.famePack(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount,
            cadenceExecutionKitCurrentStreak: cadenceStreak.current,
            cadenceExecutionKitBestStreak: cadenceStreak.best
        )
        saveText(pack, title: "Save Fame Pack", fileNamePrefix: "fame-pack")
        recordActivity(category: "saved", detail: "save-fame-pack")
    }

    private func copySetupGuide() {
        copyToClipboardWithReadyPrompt(
            setupGuideMarkdown(),
            readyMessage: "Setup guide ready.",
            copyMessage: "Copied setup guide."
        )
        recordActivity(category: "share", detail: "copy-setup-guide")
    }

    private func copyWinCard() {
        let snapshot = growthSnapshotCounts()
        guard let data = WinCardRenderer.pngData(
            savedItemCount: snapshot.savedItemCount,
            activityLogItemCount: snapshot.activityLogItemCount
        ) else {
            readerState.errorText = "Could not build win card image."
            effects.play(.error, settings: settings)
            flashStatus(symbol: "xmark.circle.fill", tint: .systemRed, length: 0.24)
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(data, forType: .png)
        readerState.petSay("Copied win card image.", mood: .happy)
        effects.hit(.success, settings: settings, haptic: .alignment)
        flashStatus(symbol: "photo", tint: .systemGreen, length: 0.26)
        recordActivity(category: "share", detail: "copy-win-card")
    }

    private func handleSetupChecklistAction(_ action: SetupChecklistAction) {
        switch action {
        case .screenRecordingSettings:
            openSystemSettings(url: AppDefaults.screenRecordingSettingsURL)
        case .accessibilitySettings:
            openSystemSettings(url: AppDefaults.accessibilitySettingsURL)
        case .appSettings:
            settingsWindow.show()
        case .loginItemsSettings:
            LaunchAtLoginManager.openSettings()
        }

        recordActivity(category: "setup", detail: "setup-\(action.rawValue)")
    }

    private func openSystemSettings(url: URL?) {
        guard let url else { return }
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        NSWorkspace.shared.open(url)
    }

    private func searchWeb(query: String) {
        guard let url = WebSearch.searchURL(for: query) else { return }
        openURL(url)
    }

    private func openURL(_ url: URL) {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        NSWorkspace.shared.open(url)
        recordActivity(category: "open", detail: "open-url")
    }

    private func revealURL(_ url: URL) {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        recordActivity(category: "open", detail: "reveal-path")
    }

    private func handleTopPickMilestoneFeedback(_ milestone: Int) {
        guard milestone > 0 else { return }
        recordActivity(category: "command", detail: "top-pick-milestone-\(milestone)")
        guard settings.topPickMilestoneFeedbackEnabled else { return }

        rewardHUD.show(
            "Top Picks Milestone x\(milestone)",
            mood: .success,
            intensity: settings.feelIntensity
        )
        readerState.petSay("Top Picks streak x\(milestone). Keep shipping.", mood: .happy)
        readerState.pulse()
        flashStatus(symbol: "sparkles", tint: .systemCyan, length: 0.2)
    }

    private func resetCadenceExecutionKitCommandStreakFromSettings() {
        let defaults = UserDefaults.standard
        let currentStreak = max(0, defaults.integer(forKey: fameCadenceExecutionKitCommandStreakKey))
        let bestStreak = max(0, defaults.integer(forKey: fameCadenceExecutionKitCommandBestStreakKey))

        guard currentStreak > 0 || bestStreak > 0 else {
            recordActivity(category: "command", detail: "cadence-execution-kit-streak-reset-manual-noop")
            readerState.petSay("Cadence streak is already reset.", mood: .happy)
            return
        }

        Self.resetCadenceExecutionKitCommandStreak(defaults: defaults)
        updateCadenceExecutionKitMenuMomentumStatus(defaults: defaults)
        recordActivity(category: "command", detail: "cadence-execution-kit-streak-reset-manual")
        rewardHUD.show(
            "Cadence Streak Reset",
            mood: .success,
            intensity: settings.feelIntensity
        )
        readerState.petSay("Cadence streak reset. Fresh run starts now.", mood: .happy)
        flashStatus(symbol: "arrow.counterclockwise.circle.fill", tint: .systemPurple, length: 0.2)
        commandPalette.requestRefresh()
    }

    private func resetFameExceptionalLoopOutcomeTuningFromCommand() {
        resetFameExceptionalLoopOutcomeTuning(source: "manual")
    }

    private func resetFameExceptionalLoopOutcomeTuningFromSettings(
        defaults: UserDefaults = .standard
    ) {
        resetFameExceptionalLoopOutcomeTuning(source: "settings", defaults: defaults)
    }

    private func resetFameExceptionalLoopOutcomeTuning(
        source: String,
        defaults: UserDefaults = .standard
    ) {
        let resetStatus = fameExceptionalLoopOutcomeTuningResetStatus(defaults: defaults)
        guard resetStatus.isEnabled else {
            recordActivity(
                category: "command",
                detail: "fame-exceptional-loop-outcome-tuning-reset-\(source)-noop"
            )
            readerState.petSay("Exceptional loop tuning is already reset.", mood: .happy)
            return
        }

        Self.resetFameExceptionalLoopOutcomeTuning(defaults: defaults)
        updateFameExceptionalLoopMenuStatus(defaults: defaults)
        recordActivity(category: "command", detail: "fame-exceptional-loop-outcome-tuning-reset-\(source)")
        rewardHUD.show(
            "Exceptional Loop Tuning Reset",
            mood: .success,
            intensity: settings.feelIntensity
        )
        readerState.petSay("Exceptional loop tuning reset. Next loop starts from baseline.", mood: .happy)
        readerState.pulse()
        flashStatus(symbol: "arrow.counterclockwise.circle.fill", tint: .systemTeal, length: 0.2)
        commandPalette.requestRefresh()
    }

    private struct CadenceExecutionKitAutopilotCueFeedbackProfile {
        var hudMood: RewardHUDController.Mood
        var petMood: PetMood
        var intensityMultiplier: Double
        var hapticPattern: NSHapticFeedbackManager.FeedbackPattern?
        var flashTint: NSColor
        var flashLength: TimeInterval
        var celebrationToken: String?
        var doublePulse: Bool
    }

    private func cadenceExecutionKitAutopilotCueFeedbackProfile(
        for cue: CadenceExecutionKitAutopilotCue,
        celebrationIntensity: Int
    ) -> CadenceExecutionKitAutopilotCueFeedbackProfile {
        var profile: CadenceExecutionKitAutopilotCueFeedbackProfile
        switch cue.tier {
        case .recovery:
            profile = CadenceExecutionKitAutopilotCueFeedbackProfile(
                hudMood: .working,
                petMood: .ready,
                intensityMultiplier: 0.76,
                hapticPattern: nil,
                flashTint: .systemPurple,
                flashLength: 0.18,
                celebrationToken: nil,
                doublePulse: false
            )
        case .restart:
            profile = CadenceExecutionKitAutopilotCueFeedbackProfile(
                hudMood: .success,
                petMood: .happy,
                intensityMultiplier: 0.86,
                hapticPattern: nil,
                flashTint: .systemPurple,
                flashLength: 0.20,
                celebrationToken: nil,
                doublePulse: false
            )
        case .momentum:
            profile = CadenceExecutionKitAutopilotCueFeedbackProfile(
                hudMood: .success,
                petMood: .happy,
                intensityMultiplier: 0.92,
                hapticPattern: .alignment,
                flashTint: .systemPurple,
                flashLength: 0.22,
                celebrationToken: nil,
                doublePulse: false
            )
        case .breakout:
            profile = CadenceExecutionKitAutopilotCueFeedbackProfile(
                hudMood: .success,
                petMood: .happy,
                intensityMultiplier: 1.0,
                hapticPattern: .levelChange,
                flashTint: .systemPink,
                flashLength: 0.26,
                celebrationToken: "breakout",
                doublePulse: true
            )
        case .fameSurge:
            profile = CadenceExecutionKitAutopilotCueFeedbackProfile(
                hudMood: .success,
                petMood: .happy,
                intensityMultiplier: 1.08,
                hapticPattern: .levelChange,
                flashTint: .systemOrange,
                flashLength: 0.30,
                celebrationToken: "fame-surge",
                doublePulse: true
            )
        }

        let normalizedIntensity = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
            celebrationIntensity
        )
        switch normalizedIntensity {
        case 0:
            profile.intensityMultiplier *= 0.82
            profile.doublePulse = false
            switch cue.tier {
            case .recovery, .restart:
                profile.hapticPattern = nil
            case .momentum:
                profile.hapticPattern = nil
            case .breakout, .fameSurge:
                profile.hapticPattern = .alignment
            }
        case 2:
            profile.intensityMultiplier *= 1.16
            switch cue.tier {
            case .recovery:
                profile.hapticPattern = nil
            case .restart:
                profile.hapticPattern = .alignment
            case .momentum:
                profile.hapticPattern = .levelChange
                profile.doublePulse = true
                profile.flashTint = .systemPink
                profile.flashLength = max(profile.flashLength, 0.24)
            case .breakout, .fameSurge:
                profile.doublePulse = true
                profile.flashLength += 0.06
                if let celebrationToken = profile.celebrationToken {
                    profile.celebrationToken = "\(celebrationToken)-epic"
                }
            }
        default:
            break
        }

        return profile
    }

    private func trackCadenceExecutionKitCommandStreak(actionID: String) {
        let update = Self.updateCadenceExecutionKitCommandStreak(
            actionID: actionID,
            defaults: UserDefaults.standard
        )
        updateCadenceExecutionKitMenuMomentumStatus()
        update.activityDetails.forEach { detail in
            recordActivity(category: "command", detail: detail)
        }

        if settings.topPickMilestoneFeedbackEnabled,
           Self.isCadenceExecutionKitCommandAction(actionID),
           update.milestone == nil,
           let deltaFeedback = Self.cadenceExecutionKitCommandDeltaFeedback(
               previousStreak: update.previousStreak,
               nextStreak: update.nextStreak,
               bestStreak: update.bestStreak,
               milestone: update.milestone
           ) {
            rewardHUD.show(
                deltaFeedback.title,
                mood: .success,
                intensity: settings.feelIntensity * 0.72
            )
            flashStatus(symbol: deltaFeedback.statusSymbol, tint: .systemPurple, length: 0.16)
        }

        guard settings.topPickMilestoneFeedbackEnabled else { return }
        let nextMoveLabel = Self.fameNextMoveCommandLabel(fameNextMoveMenuCommandID())
        guard let autopilotCue = Self.cadenceExecutionKitAutopilotCue(
            previousStreak: update.previousStreak,
            nextStreak: update.nextStreak,
            bestStreak: update.bestStreak,
            milestone: update.milestone,
            nextMoveLabel: nextMoveLabel
        ) else { return }

        let now = Date()
        guard Self.shouldSurfaceCadenceExecutionKitAutopilotCue(
            lastCueAt: cadenceExecutionKitAutopilotCueLastAt,
            lastCueToken: cadenceExecutionKitAutopilotCueLastToken,
            nextCueToken: autopilotCue.token,
            now: now,
            cooldown: cadenceExecutionKitAutopilotCueCooldown
        ) else {
            if let remainingSeconds = Self.cadenceExecutionKitAutopilotCueCooldownRemainingSeconds(
                lastCueAt: cadenceExecutionKitAutopilotCueLastAt,
                lastCueToken: cadenceExecutionKitAutopilotCueLastToken,
                nextCueToken: autopilotCue.token,
                now: now,
                cooldown: cadenceExecutionKitAutopilotCueCooldown
            ) {
                recordActivity(
                    category: "command",
                    detail: "cadence-execution-kit-autopilot-cue-suppressed-\(autopilotCue.token)-\(remainingSeconds)s"
                )
            }
            return
        }
        cadenceExecutionKitAutopilotCueLastAt = now
        cadenceExecutionKitAutopilotCueLastToken = autopilotCue.token
        recordActivity(category: "command", detail: "cadence-execution-kit-autopilot-cue-\(autopilotCue.token)")
        recordActivity(category: "command", detail: "cadence-execution-kit-autopilot-cue-tier-\(autopilotCue.tier.rawValue)")
        let celebrationIntensityToken = Self.cadenceExecutionKitAutopilotCelebrationIntensityToken(
            settings.fameCadenceAutopilotCelebrationIntensity
        )
        recordActivity(
            category: "command",
            detail: "cadence-execution-kit-autopilot-cue-celebration-intensity-\(celebrationIntensityToken)"
        )
        let feedback = cadenceExecutionKitAutopilotCueFeedbackProfile(
            for: autopilotCue,
            celebrationIntensity: settings.fameCadenceAutopilotCelebrationIntensity
        )
        if let celebrationToken = feedback.celebrationToken {
            recordActivity(
                category: "command",
                detail: "cadence-execution-kit-autopilot-cue-celebration-\(celebrationToken)-\(autopilotCue.token)"
            )
        }

        rewardHUD.show(
            autopilotCue.title,
            mood: feedback.hudMood,
            intensity: min(1.18, settings.feelIntensity * feedback.intensityMultiplier)
        )
        readerState.petSay(autopilotCue.petMessage, mood: feedback.petMood)
        readerState.pulse()
        if feedback.doublePulse {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 110_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.readerState.pulse()
                }
            }
        }
        if let hapticPattern = feedback.hapticPattern {
            effects.hit(.success, settings: settings, haptic: hapticPattern)
        }
        flashStatus(
            symbol: autopilotCue.statusSymbol,
            tint: feedback.flashTint,
            length: feedback.flashLength
        )
    }

    private func recordCommandAction(_ actionID: String) {
        recordActivity(category: "command", detail: ActivityLogCommand.safeID(actionID))
        trackCadenceExecutionKitCommandStreak(actionID: actionID)
    }

    @discardableResult
    private func consumeFameOnboardingGapRecoveryMomentumIfNeeded(
        actionID: String,
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard Self.consumeFameOnboardingGapRecoveryMomentum(actionID: actionID, defaults: defaults) else {
            return false
        }
        fameOnboardingGapRecoveryLastAt = nil
        recordActivity(
            category: "support",
            detail: "fame-onboarding-gap-recovery-momentum-consumed-\(ActivityLogCommand.safeID(actionID))"
        )
        return true
    }

    private func recordActivity(category: String, detail: String) {
        activityLog.record(category: category, detail: detail)
    }

    private func stopSpeech() {
        speech.stop()
        recordActivity(category: "core", detail: "stop-speech")
    }

    private func askLLM(question: String) {
        guard settings.llmEnabled else {
            readerState.errorText = "LLM is off."
            return
        }

        let apiKey = settings.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            readerState.errorText = "Add an API key in Settings."
            settingsWindow.show()
            return
        }

        let questionText = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = questionText.isEmpty ? "Explain this content in a clear, short way." : questionText
        let text = readerState.lastText
        let imageData = readerState.lastImageData

        readerState.isWorking = true
        readerState.errorText = ""

        Task {
            do {
                let answer = try await OpenAIClient(apiKey: apiKey).askAboutSelection(
                    question: prompt,
                    selectedText: text,
                    imageData: imageData,
                    model: settings.llmModel
                )

                await MainActor.run {
                    readerState.answerText = answer
                    readerState.remember(text: text, answer: answer)
                    readerState.pulse()
                    readerState.isWorking = false
                    effects.hit(.success, settings: settings, haptic: .levelChange)
                    flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.42)
                    recordActivity(category: "ask", detail: "ask-success")
                }

                if settings.useCloudVoiceForLLM {
                    let data = try await OpenAIClient(apiKey: apiKey).makeSpeech(
                        text: answer,
                        model: settings.cloudVoiceModel,
                        voice: settings.cloudVoiceName,
                        instructions: settings.cloudVoiceInstructions
                    )
                    await MainActor.run {
                        speech.playAudioData(data)
                    }
                } else {
                    await MainActor.run {
                        read(answer)
                    }
                }
            } catch {
                await MainActor.run {
                    readerState.isWorking = false
                    readerState.errorText = error.localizedDescription
                    effects.play(.error, settings: settings)
                    flashStatus(symbol: "exclamationmark.triangle.fill", tint: .systemRed, length: 0.36)
                    recordActivity(category: "ask", detail: "ask-error")
                }
            }
        }
    }

    private func startWorkingFeedback() {
        workingFeedbackTask?.cancel()
        workingFeedbackTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 90_000_000)

            for _ in 0..<6 {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, self.readerState.isWorking else { return }
                    self.effects.play(.scanTick, settings: self.settings)
                    self.flashStatus(symbol: "waveform", tint: .systemYellow, length: 0.12)
                }
                try? await Task.sleep(nanoseconds: 145_000_000)
            }
        }
    }

    private func stopWorkingFeedback() {
        workingFeedbackTask?.cancel()
        workingFeedbackTask = nil
    }

    private func previewFeelFlow() {
        workingFeedbackTask?.cancel()
        cancelPreviewFlow()
        effects.play(.tap, settings: settings)

        previewFeelTask = Task { [weak self] in
            await MainActor.run {
                guard let self else { return }
                self.effects.hit(.wake, settings: self.settings, haptic: .alignment)
                self.rewardHUD.show("Reading", mood: .working, intensity: self.settings.feelIntensity)
                self.flashStatus(symbol: "sparkles", tint: .systemCyan, length: 0.20)
            }

            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }

            for _ in 0..<4 {
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    guard let self else { return }
                    self.effects.play(.scanTick, settings: self.settings)
                    self.flashStatus(symbol: "waveform", tint: .systemYellow, length: 0.10)
                }
                try? await Task.sleep(nanoseconds: 130_000_000)
                guard !Task.isCancelled else { return }
            }

            await MainActor.run {
                guard let self else { return }
                self.effects.hit(.capture, settings: self.settings, haptic: .levelChange)
                self.flashStatus(symbol: "scope", tint: .systemBlue, length: 0.16)
            }

            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                self.effects.hit(.success, settings: self.settings, haptic: .levelChange)
                self.rewardHUD.show("Ready", mood: .success, intensity: self.settings.feelIntensity)
                self.flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.42)
            }
            await MainActor.run {
                self?.previewFeelTask = nil
            }
        }
    }

    private func compareStylePreviews() {
        workingFeedbackTask?.cancel()
        cancelPreviewFlow()

        let originalStyle = settings.soundStyle
        let originalIntensity = settings.feelIntensity
        compareRestoreSettings = (originalStyle, originalIntensity)
        let styles = [
            ("Soft", "soft"),
            ("Glass", "glass"),
            ("Jackpot", "jackpot")
        ]

        previewFeelTask = Task { [weak self] in
            for (label, style) in styles {
                await MainActor.run {
                    guard let self else { return }
                    self.settings.soundStyle = style
                    self.effects.preload(style: style)
                    self.updateStyleMenu()
                    self.effects.play(.tap, settings: self.settings)
                    self.rewardHUD.show(label, mood: .working, intensity: self.settings.feelIntensity)
                    self.flashStatus(symbol: "waveform", tint: .systemYellow, length: 0.16)
                }

                try? await Task.sleep(nanoseconds: 180_000_000)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard let self else { return }
                    self.effects.play(.scanTick, settings: self.settings)
                    self.flashStatus(symbol: "scope", tint: .systemBlue, length: 0.14)
                }

                try? await Task.sleep(nanoseconds: 180_000_000)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard let self else { return }
                    self.effects.hit(.success, settings: self.settings, haptic: .levelChange)
                    self.rewardHUD.show(label, mood: .success, intensity: self.settings.feelIntensity)
                    self.flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.34)
                }

                try? await Task.sleep(nanoseconds: 1_050_000_000)
                guard !Task.isCancelled else { return }
            }

            await MainActor.run {
                guard let self else { return }
                self.restoreCompareSettings()
                self.previewFeelTask = nil
            }
        }
    }

    private func cancelPreviewFlow() {
        previewFeelTask?.cancel()
        previewFeelTask = nil
        effects.stopActiveSounds()
        restoreCompareSettings()
    }

    private func restoreCompareSettings() {
        guard let restore = compareRestoreSettings else { return }

        settings.soundStyle = restore.style
        settings.feelIntensity = restore.intensity
        effects.preload(style: restore.style)
        updateStyleMenu()
        updateHitMenu()
        compareRestoreSettings = nil
    }

    private func updateStyleMenu() {
        for (style, item) in styleMenuItems {
            item.state = settings.soundStyle == style ? .on : .off
        }
    }

    private func updateHitMenu() {
        for (level, item) in hitMenuItems {
            item.state = abs(settings.feelIntensity - level) < 0.005 ? .on : .off
        }
    }

    private func setStatusButton(symbol: String, tint: NSColor?) {
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Fluid Reader")
        button.contentTintColor = tint
    }

    private func updateFamePulseRiskMenu(
        signal: FamePulseAlertSignal?,
        now: Date = Date()
    ) {
        famePulseRiskMenuItem?.title = FameSnapshotRollup.pulseRiskMenuTitle(signal: signal)
        famePulseRiskDetailMenuItem?.title = FameSnapshotRollup.pulseRiskMenuDetail(signal: signal)
        fameLaunchAlertMenuItem?.title = fameLaunchAlertMenuTitle()
        fameLaunchHealthMenuItem?.title = fameLaunchHealthMenuTitle(now: now)
        updateFameLaunchThresholdAlertsMenuTitle()
        updateAutoOpsBundleMenuStatus()
        updateLaunchRescueAutoMenuStatus()
        fameNextMoveMenuItem?.title = fameNextMoveMenuTitle(
            signal: signal,
            transition: famePulseLatestTransition()
        )
        updateCadenceExecutionKitMenuMomentumStatus()
        updateBestChannelLaunchPackMenuStatus()
        updateFameExceptionalLoopMenuStatus(now: now)
        updateFameOnboardingScorecardMenuStatus(now: now)
    }

    private func updateAutoOpsBundleMenuStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        fameAutoOpsBundleStatusMenuItem?.title = autoOpsBundleMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameAutoOpsBundleStatusMenuItem?.toolTip = autoOpsBundleMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
    }

    private func updateCadenceExecutionKitMenuMomentumStatus(defaults: UserDefaults = .standard) {
        fameCadenceMomentumMenuItem?.title = cadenceExecutionKitMenuMomentumTitle(defaults: defaults)
    }

    private func fameExceptionalLoopMenuStatusTitle(now: Date = Date()) -> String {
        let plan = fameExceptionalLoopPlan(now: now)
        return Self.fameExceptionalLoopMenuStatusTitle(
            plan,
            hotKeyAvailable: fameExceptionalLoopHotKeyAvailable
        )
    }

    private func fameExceptionalLoopMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let plan = fameExceptionalLoopPlan(now: now)
        let baseToolTip = Self.fameExceptionalLoopMenuStatusToolTip(
            plan,
            hotKeyAvailable: fameExceptionalLoopHotKeyAvailable
        )
        let outcomeScoreboard = fameExceptionalLoopOutcomeScoreboard(now: now, defaults: defaults)
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let laneSummaries = Self.fameExceptionalLoopOutcomeLaneSummaries(
            history: windowedCommandHistory
        )
        let healthSnapshot = Self.fameExceptionalLoopHealthSnapshot(
            scoreboard: outcomeScoreboard,
            history: windowedCommandHistory
        )
        let topRecoveryLane = Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        )
        let recoveryActionSummary = Self.fameExceptionalLoopRecoveryLaneActionSummary(
            topRecoveryLane
        )
        let autoRecoveryStatusSummary = Self.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
            topRecoveryLane: topRecoveryLane,
            lastAutoRunAt: fameExceptionalLoopRecoveryLaneAutoRunLastAt(defaults: defaults),
            now: now,
            missesRequired: fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            failureStreakRequired: fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            cooldown: fameExceptionalLoopAutoRecoveryLaneCooldown
        )
        let autoRecoveryRecommendationSummary =
            Self.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: Self.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                    topRecoveryLane: topRecoveryLane
                ),
                currentMissesRequired: fameExceptionalLoopAutoRecoveryLaneMissesRequired,
                currentFailureStreakRequired:
                    fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
                currentCooldownMinutes: AppDefaults
                    .normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
                    )
            )
        let outcomeSummaryToolTip = Self.fameExceptionalLoopMenuOutcomeSummaryToolTip(
            scoreboard: outcomeScoreboard,
            laneSummaries: laneSummaries,
            recoveryActionSummary: recoveryActionSummary
        )
        let healthRecommendationSummary =
            "Health recommendation [\(healthSnapshot.recommendedActionConfidenceTitle)]: \(healthSnapshot.recommendedNextAction) Why: \(healthSnapshot.recommendedActionWhy)"
        return "\(baseToolTip) \(outcomeSummaryToolTip) \(autoRecoveryStatusSummary) Auto recovery recommendation: \(autoRecoveryRecommendationSummary) \(healthRecommendationSummary)"
    }

    private func fameExceptionalLoopRecoveryLaneMenuStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopRecoveryLaneMenuStatus {
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        return Self.fameExceptionalLoopRecoveryLaneMenuStatus(
            Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
                history: windowedCommandHistory
            )
        )
    }

    private func fameExceptionalLoopAutoRecoveryLaneMenuStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopAutoRecoveryLaneMenuStatus {
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        return Self.fameExceptionalLoopAutoRecoveryLaneMenuStatus(
            topRecoveryLane: Self.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
                history: windowedCommandHistory
            ),
            lastAutoRunAt: fameExceptionalLoopRecoveryLaneAutoRunLastAt(defaults: defaults),
            now: now,
            missesRequired: fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            failureStreakRequired: fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            cooldown: fameExceptionalLoopAutoRecoveryLaneCooldown
        )
    }

    private func fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus {
        let context = fameExceptionalLoopAutoRecoveryLaneTuningContext(now: now, defaults: defaults)
        return Self.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            recommendation: context.recommendation,
            currentMissesRequired: context.missesRequired,
            currentFailureStreakRequired: context.failureStreakRequired,
            currentCooldownMinutes: context.cooldownMinutes
        )
    }

    private func fameExceptionalLoopLatestRecapStatus() -> FameExceptionalLoopLatestRecapStatus {
        let hasSavedRecap = (try? FameSnapshotArchive.latestExceptionalLoopRecapURL()) != nil
        return Self.fameExceptionalLoopLatestRecapStatus(hasSavedRecap: hasSavedRecap)
    }

    private func fameExceptionalLoopOutcomeTuningResetStatus(
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopOutcomeTuningResetStatus {
        let scoreboard = fameExceptionalLoopOutcomeScoreboard(defaults: defaults)
        let commandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        return Self.fameExceptionalLoopOutcomeTuningResetStatus(
            attempts: scoreboard.attempts,
            successes: scoreboard.successes,
            successStreak: scoreboard.successStreak,
            failureStreak: scoreboard.failureStreak,
            lastFocusToken: scoreboard.lastFocusToken,
            lastOutcomeAt: scoreboard.lastOutcomeAt,
            commandHistory: commandHistory
        )
    }

    private func updateFameExceptionalLoopMenuStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        fameExceptionalLoopStatusMenuItem?.title = fameExceptionalLoopMenuStatusTitle(now: now)
        fameExceptionalLoopStatusMenuItem?.toolTip = fameExceptionalLoopMenuStatusToolTip(
            now: now,
            defaults: defaults
        )

        let recoveryLaneMenuStatus = fameExceptionalLoopRecoveryLaneMenuStatus(
            now: now,
            defaults: defaults
        )
        fameExceptionalLoopRecoveryLaneMenuItem?.title = recoveryLaneMenuStatus.title
        fameExceptionalLoopRecoveryLaneMenuItem?.toolTip = recoveryLaneMenuStatus.toolTip
        fameExceptionalLoopRecoveryLaneMenuItem?.isEnabled = recoveryLaneMenuStatus.isEnabled

        let latestRecapStatus = fameExceptionalLoopLatestRecapStatus()
        fameExceptionalLoopOpenLatestRecapMenuItem?.title = latestRecapStatus.title
        fameExceptionalLoopOpenLatestRecapMenuItem?.toolTip = latestRecapStatus.toolTip
        fameExceptionalLoopOpenLatestRecapMenuItem?.isEnabled = latestRecapStatus.isEnabled

        let autoRecoveryLaneMenuStatus = fameExceptionalLoopAutoRecoveryLaneMenuStatus(
            now: now,
            defaults: defaults
        )
        fameExceptionalLoopAutoRecoveryLaneStatusMenuItem?.title = autoRecoveryLaneMenuStatus.title
        fameExceptionalLoopAutoRecoveryLaneStatusMenuItem?.toolTip = autoRecoveryLaneMenuStatus.toolTip

        let autoTuneMenuStatus = fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            now: now,
            defaults: defaults
        )
        fameExceptionalLoopAutoTuneMenuItem?.title = autoTuneMenuStatus.title
        fameExceptionalLoopAutoTuneMenuItem?.toolTip = autoTuneMenuStatus.toolTip
        fameExceptionalLoopAutoTuneMenuItem?.isEnabled = autoTuneMenuStatus.isEnabled

        let resetStatus = fameExceptionalLoopOutcomeTuningResetStatus(defaults: defaults)
        fameExceptionalLoopResetTuningMenuItem?.title = resetStatus.title
        fameExceptionalLoopResetTuningMenuItem?.toolTip = resetStatus.toolTip
        fameExceptionalLoopResetTuningMenuItem?.isEnabled = resetStatus.isEnabled
    }

    private func updateBestChannelLaunchPackMenuStatus(defaults: UserDefaults = .standard) {
        let transitionCount = max(
            0,
            defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey)
        )
        let latestToken = defaults.string(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey
        )
        let momentumStreak = defaults.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        if let launchPackMenuItem = fameBestChannelLaunchPackMenuItem {
            launchPackMenuItem.title = Self.bestChannelLaunchPackMenuTitle(
                transitionCount: transitionCount,
                latestToken: latestToken,
                momentumStreak: momentumStreak
            )
            launchPackMenuItem.toolTip = Self.bestChannelLaunchPackMenuToolTip(
                transitionCount: transitionCount,
                latestToken: latestToken,
                momentumStreak: momentumStreak
            )
        }
        if let draftMenuItem = fameBestChannelDraftMenuItem {
            draftMenuItem.title = Self.bestChannelDraftMenuTitle(
                transitionCount: transitionCount,
                latestToken: latestToken,
                momentumStreak: momentumStreak
            )
            draftMenuItem.toolTip = Self.bestChannelDraftMenuToolTip(
                transitionCount: transitionCount,
                latestToken: latestToken,
                momentumStreak: momentumStreak
            )
        }
    }

    private func updateFameOnboardingScorecardMenuStatus(now: Date = Date()) {
        let context = fameOnboardingScorecardContext(now: now)
        let onboardingRecoverySnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot(now: now)
        let onboardingRecoveryMenuHint = Self.fameOnboardingRecoveryMenuHint(
            isFreshRecovery: onboardingRecoverySnapshot.isFresh,
            followupCommandID: onboardingRecoverySnapshot.followupActionID,
            remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
        )
        let onboardingRecoveryQuickRunActionID = Self.fameOnboardingRecoveryQuickRunActionID(
            isFreshRecovery: onboardingRecoverySnapshot.isFresh,
            followupCommandID: onboardingRecoverySnapshot.followupActionID,
            remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts,
            enabledActionIDs: fameOnboardingRecoveryQuickRunEnabledActionIDs(now: now)
        )

        if let quickRunMenuItem = fameOnboardingRecoveryNextMenuItem {
            quickRunMenuItem.title = Self.fameOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                actionID: onboardingRecoveryQuickRunActionID,
                remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
            )
            quickRunMenuItem.isEnabled = onboardingRecoveryQuickRunActionID != nil
            quickRunMenuItem.representedObject = onboardingRecoveryQuickRunActionID
        }
        if let launchQuickRunMenuItem = fameLaunchRecoveryNextMenuItem {
            launchQuickRunMenuItem.title = Self.launchControlOnboardingRecoveryQuickRunMenuTitle(
                isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                actionID: onboardingRecoveryQuickRunActionID,
                remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
            )
            launchQuickRunMenuItem.isEnabled = onboardingRecoveryQuickRunActionID != nil
            launchQuickRunMenuItem.representedObject = onboardingRecoveryQuickRunActionID
            launchQuickRunMenuItem.toolTip = Self.launchControlOnboardingRecoveryQuickRunMenuToolTip(
                isFreshRecovery: onboardingRecoverySnapshot.isFresh,
                actionID: onboardingRecoveryQuickRunActionID
            )
        }

        if let gapMenuItem = fameOnboardingGapMenuItem {
            if context == nil {
                gapMenuItem.title = "Fill Onboarding Gap (Unavailable)"
                gapMenuItem.isEnabled = false
            } else if let artifacts = try? latestOnboardingSuiteArtifacts() {
                let recommendedCommandID = Self.fameOnboardingGapRecommendedCommandID(
                    hasDailyBrief: artifacts.dailyBriefURL != nil,
                    hasScorecard: artifacts.scorecardURL != nil,
                    hasNudge: artifacts.nudgeURL != nil
                )
                let baseTitle = Self.fameOnboardingGapMenuTitle(
                    recommendedCommandID: recommendedCommandID,
                    missingArtifacts: artifacts.missingArtifactNames.count,
                    missingArtifactNames: artifacts.missingArtifactNames
                )
                gapMenuItem.title = Self.fameMenuTitle(
                    baseTitle: baseTitle,
                    appendedHint: onboardingRecoveryMenuHint
                )
                gapMenuItem.isEnabled = recommendedCommandID != nil
            } else {
                gapMenuItem.title = "Fill Onboarding Gap (Unavailable)"
                gapMenuItem.isEnabled = false
            }
        }

        guard let menuItem = fameOnboardingScorecardMenuItem else { return }
        guard let context else {
            menuItem.title = "Run First-Week Fame Scorecard (Unavailable)"
            menuItem.isEnabled = false
            return
        }

        let baseTitle = Self.fameOnboardingScorecardMenuTitle(
            day: context.day,
            windowDays: context.windowDays,
            completedDays: context.completedDays
        )
        menuItem.title = Self.fameMenuTitle(
            baseTitle: baseTitle,
            appendedHint: onboardingRecoveryMenuHint
        )
        menuItem.isEnabled = true
    }

    private func cadenceExecutionKitMenuMomentumTitle(defaults: UserDefaults = .standard) -> String {
        let cadenceStreak = cadenceExecutionKitCommandStreakSnapshot(defaults: defaults)
        return Self.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: cadenceStreak.current,
            bestStreak: cadenceStreak.best
        )
    }

    private func autoOpsBundleMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.autoOpsBundleEscalationStatusMenuTitle(
            autoOpsBundleEscalationStatus(now: now, defaults: defaults),
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func autoOpsBundleMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.autoOpsBundleEscalationStatusMenuToolTip(
            autoOpsBundleEscalationStatus(now: now, defaults: defaults),
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueFollowupMomentumBadgeSnapshot(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String? {
        let followupOutcomeScoreboard = launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults
        )
        let followupCoachRecoveryLaneStreak = launchRescueFollowupCoachRecoveryLaneStreak(
            defaults: defaults
        )
        let followupCoachRecoveryChecklistCooldownMinutes =
            launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
                defaults: defaults
            )
        let followupCoachRecoveryChecklistCooldownMinutesRemaining =
            launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining(
                now: now,
                defaults: defaults
            )
        return Self.launchRescueFollowupMomentumBadge(
            followupOutcomeScoreboard,
            recoveryLaneStreak: followupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                followupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                followupCoachRecoveryChecklistCooldownMinutesRemaining
        )
    }

    private func launchRescueSnapshotMenuTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueSnapshotMenuTitle(
            followupMomentumBadge: launchRescueFollowupMomentumBadgeSnapshot(
                now: now,
                defaults: defaults
            ),
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueSnapshotOpenMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueSnapshotOpenMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueSnapshotOpenMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueSnapshotOpenMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueSnapshotCopyMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueSnapshotCopyMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchCountdownRunMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchCountdownRunMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchCountdownRunMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchCountdownRunMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchCountdownOpenMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchCountdownOpenMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchCountdownOpenMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchCountdownOpenMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueBurstOpenMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueBurstOpenMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueBurstOpenMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueBurstOpenMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueBurstRunMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueBurstRunMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchRescueBurstRunMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let modeMomentumStreak = defaults.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchRescueBurstRunMenuStatusToolTip(
            modeMomentumStreak: modeMomentumStreak,
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlHubFollowupPromptContext(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> (
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String?
    ) {
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason(defaults: defaults)
        let launchRescueAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt(defaults: defaults)
        return launchRescueFollowupPromptContext(
            triggerReason: launchRescueAutoTriggerReason,
            lastAutoTriggerAt: launchRescueAutoTriggerAt,
            now: now
        )
    }

    private func launchControlBriefRunMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlBriefRunMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlBriefRunMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlBriefRunMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlBriefOpenMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlBriefOpenMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlBriefOpenMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlBriefOpenMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlBriefCopyMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlBriefCopyMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlBriefCopyMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlBriefCopyMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlHubRunMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlHubRunMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlHubRunMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlHubRunMenuStatusToolTip(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlHubOpenMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        return Self.launchControlHubOpenMenuStatusTitle(
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    private func launchControlHubOpenMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let promptContext = launchControlHubFollowupPromptContext(now: now, defaults: defaults)
        let hubStatus = launchControlHubActionStatus(now: now)
        return Self.launchControlHubOpenMenuStatusToolTip(
            availableArtifacts: hubStatus.availableArtifacts,
            totalArtifacts: hubStatus.totalArtifacts,
            newestArtifactAgeMinutes: hubStatus.newestArtifactAgeMinutes,
            routeBadge: promptContext.routeBadge,
            selfHealAttentionBadge: promptContext.selfHealAttentionBadge
        )
    }

    nonisolated static func latestLaunchRescueAutoFollowupSelfHealSnapshot(
        from activityItems: [ActivityLogItem],
        now: Date = Date(),
        includeStale: Bool = false
    ) -> LaunchRescueAutoFollowupSelfHealSnapshot? {
        for item in activityItems {
            guard let snapshot = launchRescueAutoFollowupSelfHealSnapshot(
                fromActivityDetail: item.detail,
                recordedAt: item.createdAt
            ) else {
                continue
            }
            if !includeStale {
                guard launchRescueAutoFollowupSelfHealSnapshotIsRecent(
                    recordedAt: snapshot.recordedAt,
                    now: now
                ) else {
                    continue
                }
            }
            return snapshot
        }
        return nil
    }

    nonisolated static func launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
        _ triggerReason: String?,
        activityItems: [ActivityLogItem],
        now: Date = Date(),
        includeStale: Bool = false
    ) -> LaunchRescueAutoFollowupSelfHealSnapshot? {
        let normalizedTriggerReason = launchRescueAutoTriggerReasonToken(triggerReason)
        guard normalizedTriggerReason != "none" else { return nil }
        let latestSnapshot = latestLaunchRescueAutoFollowupSelfHealSnapshot(
            from: activityItems,
            now: now,
            includeStale: includeStale
        )
        guard latestSnapshot?.reasonToken == normalizedTriggerReason else { return nil }
        return latestSnapshot
    }

    nonisolated static func launchRescueAutoFollowupSelfHealArtifactStatusTitle(
        triggerReason: String?,
        activityItems: [ActivityLogItem],
        now: Date = Date()
    ) -> String {
        let normalizedTriggerReason = launchRescueAutoTriggerReasonToken(triggerReason)
        guard normalizedTriggerReason != "none" else {
            return "Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks."
        }

        if let matchingRecentSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            normalizedTriggerReason,
            activityItems: activityItems,
            now: now
        ), let statusTitle = launchRescueAutoFollowupSelfHealStatusTitle(
            matchingRecentSnapshot,
            now: now
        ) {
            return statusTitle
        }

        if let matchingStaleSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            normalizedTriggerReason,
            activityItems: activityItems,
            now: now,
            includeStale: true
        ) {
            return "Launch Rescue Auto Self-Heal: Last matching check is stale (\(launchRescueAutoTriggerAtSummary(matchingStaleSnapshot.recordedAt, now: now))) · Route: \(launchRescueAutoFollowupCommandTitle(matchingStaleSnapshot.routeCommandID)) · Reason: \(launchRescueAutoTriggerSummary(normalizedTriggerReason))"
        }

        if let latestSnapshot = latestLaunchRescueAutoFollowupSelfHealSnapshot(
            from: activityItems,
            now: now,
            includeStale: true
        ) {
            return "Launch Rescue Auto Self-Heal: Latest check tracked \(launchRescueAutoTriggerSummary(latestSnapshot.reasonToken)) · waiting for \(launchRescueAutoTriggerSummary(normalizedTriggerReason))"
        }

        return "Launch Rescue Auto Self-Heal: No self-heal telemetry recorded yet for \(launchRescueAutoTriggerSummary(normalizedTriggerReason))"
    }

    nonisolated static func launchRescueAutoSelfHealAttentionIssueToken(
        triggerReason: String?,
        activityItems: [ActivityLogItem],
        now: Date = Date(),
        lastAutoTriggerAt: Date? = nil,
        missingSnapshotGraceWindow: TimeInterval = launchRescueAutoSelfHealAttentionMissingGraceWindow
    ) -> String? {
        let normalizedTriggerReason = launchRescueAutoTriggerReasonToken(triggerReason)
        guard normalizedTriggerReason != "none" else { return nil }

        if launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            normalizedTriggerReason,
            activityItems: activityItems,
            now: now
        ) != nil {
            return nil
        }

        if let matchingStaleSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            normalizedTriggerReason,
            activityItems: activityItems,
            now: now,
            includeStale: true
        ) {
            return "stale-\(normalizedTriggerReason)-\(matchingStaleSnapshot.routeCommandID)"
        }

        if let latestSnapshot = latestLaunchRescueAutoFollowupSelfHealSnapshot(
            from: activityItems,
            now: now,
            includeStale: true
        ) {
            return "mismatch-\(normalizedTriggerReason)-\(latestSnapshot.reasonToken)"
        }

        guard let lastAutoTriggerAt else { return nil }
        let normalizedMissingSnapshotGraceWindow = max(0, missingSnapshotGraceWindow)
        let triggerAge = now.timeIntervalSince(lastAutoTriggerAt)
        if triggerAge < 0 {
            return nil
        }
        guard triggerAge >= normalizedMissingSnapshotGraceWindow else { return nil }
        return "missing-\(normalizedTriggerReason)"
    }

    private enum LaunchRescueAutoSelfHealAttentionIssueKind {
        case missing
        case stale
        case mismatch
        case unknown
    }

    private nonisolated static func launchRescueAutoSelfHealAttentionIssueKind(
        issueToken: String?
    ) -> LaunchRescueAutoSelfHealAttentionIssueKind {
        let normalizedIssueToken = issueToken?.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        if normalizedIssueToken?.hasPrefix("missing-") == true {
            return .missing
        }
        if normalizedIssueToken?.hasPrefix("stale-") == true {
            return .stale
        }
        if normalizedIssueToken?.hasPrefix("mismatch-") == true {
            return .mismatch
        }
        return .unknown
    }

    nonisolated static func launchRescueAutoSelfHealAttentionRecommendedActionID(
        issueToken: String?,
        triggerReason: String?,
        issueStreak: Int,
        now: Date = Date(),
        lastAutoTriggerAt: Date? = nil
    ) -> String {
        let normalizedTriggerReason = launchRescueAutoTriggerReasonToken(triggerReason)
        let defaultActionID = launchRescueAutoTriggerFollowupCommandID(normalizedTriggerReason)
        let normalizedIssueStreak = max(1, issueStreak)
        let triggerAgeSeconds = lastAutoTriggerAt.map { triggerAt in
            max(0, now.timeIntervalSince(triggerAt))
        } ?? 0
        let issueKind = launchRescueAutoSelfHealAttentionIssueKind(issueToken: issueToken)
        let isCriticalTrigger = normalizedTriggerReason
            == LaunchRescueAutoTriggerReason.urgencyCritical.rawValue

        let shouldEscalateToBurst: Bool
        switch issueKind {
        case .missing:
            shouldEscalateToBurst = normalizedIssueStreak >= 3
                || triggerAgeSeconds >= (20 * 60)
                || (isCriticalTrigger && triggerAgeSeconds >= (12 * 60))
        case .stale:
            shouldEscalateToBurst = normalizedIssueStreak >= 4
                || (isCriticalTrigger && normalizedIssueStreak >= 3)
        case .mismatch:
            shouldEscalateToBurst = normalizedIssueStreak >= 3
                || (isCriticalTrigger && normalizedIssueStreak >= 2)
        case .unknown:
            shouldEscalateToBurst = false
        }

        if shouldEscalateToBurst {
            return "run-fame-launch-rescue-burst"
        }
        return defaultActionID
    }

    nonisolated static func launchRescueAutoSelfHealAttentionSignalBadge(
        issueToken: String?,
        triggerReason: String?,
        issueStreak: Int,
        now: Date = Date(),
        lastAutoTriggerAt: Date? = nil
    ) -> CommandPaletteAction.SignalBadge {
        let normalizedIssueStreak = max(1, issueStreak)
        let issueKind = launchRescueAutoSelfHealAttentionIssueKind(issueToken: issueToken)
        let triggerAgeSeconds = lastAutoTriggerAt.map { triggerAt in
            max(0, now.timeIntervalSince(triggerAt))
        } ?? 0
        let badgeTone: CommandPaletteAction.SignalBadge.Tone
        switch issueKind {
        case .missing:
            badgeTone = (normalizedIssueStreak >= 3 || triggerAgeSeconds >= (20 * 60))
                ? .high
                : .medium
        case .stale, .mismatch:
            badgeTone = normalizedIssueStreak >= 3
                ? .high
                : .medium
        case .unknown:
            badgeTone = .low
        }
        let issueTitle: String
        switch issueKind {
        case .missing:
            issueTitle = "Self-Heal Missing"
        case .stale:
            issueTitle = "Self-Heal Stale"
        case .mismatch:
            issueTitle = "Self-Heal Mismatch"
        case .unknown:
            issueTitle = "Self-Heal Attention"
        }
        let recommendedActionID = launchRescueAutoSelfHealAttentionRecommendedActionID(
            issueToken: issueToken,
            triggerReason: triggerReason,
            issueStreak: normalizedIssueStreak,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
        let recommendedActionTitle: String = {
            let followupCommandTitle = launchRescueAutoFollowupCommandTitle(recommendedActionID)
            if followupCommandTitle != recommendedActionID {
                return followupCommandTitle
            }
            return fameExceptionalLoopCommandTitle(recommendedActionID)
        }()
        let triggerSummary = launchRescueAutoTriggerSummary(triggerReason)
        let triggerAgeSummary = launchRescueAutoTriggerAtSummary(lastAutoTriggerAt, now: now)
        return CommandPaletteAction.SignalBadge(
            title: "\(issueTitle) x\(normalizedIssueStreak)",
            tone: badgeTone,
            helpText: "\(triggerSummary) Issue streak x\(normalizedIssueStreak) · last trigger \(triggerAgeSummary) Recommended: \(recommendedActionTitle).",
            recommendedActionID: recommendedActionID,
            recommendedActionTitle: recommendedActionTitle
        )
    }

    nonisolated static func launchRescueAutoSelfHealAttentionNudgeMessage(
        triggerReason: String?,
        activityItems: [ActivityLogItem],
        now: Date = Date(),
        lastAutoTriggerAt: Date? = nil,
        missingSnapshotGraceWindow: TimeInterval = launchRescueAutoSelfHealAttentionMissingGraceWindow
    ) -> String? {
        let normalizedTriggerReason = launchRescueAutoTriggerReasonToken(triggerReason)
        guard normalizedTriggerReason != "none" else { return nil }
        let followupCommandTitle = launchRescueAutoTriggerFollowupCommandTitle(normalizedTriggerReason)

        if let matchingStaleSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            normalizedTriggerReason,
            activityItems: activityItems,
            now: now,
            includeStale: true
        ) {
            guard !launchRescueAutoFollowupSelfHealSnapshotIsRecent(
                recordedAt: matchingStaleSnapshot.recordedAt,
                now: now
            ) else {
                return nil
            }
            return "Launch Rescue Auto Self-Heal stale (\(launchRescueAutoTriggerAtSummary(matchingStaleSnapshot.recordedAt, now: now))). Execute \(followupCommandTitle) now."
        }

        if let latestSnapshot = latestLaunchRescueAutoFollowupSelfHealSnapshot(
            from: activityItems,
            now: now,
            includeStale: true
        ) {
            return "Launch Rescue Auto Self-Heal mismatch: latest \(launchRescueAutoTriggerSummary(latestSnapshot.reasonToken)) waiting for \(launchRescueAutoTriggerSummary(normalizedTriggerReason)) Execute \(followupCommandTitle) now."
        }

        guard let lastAutoTriggerAt else { return nil }
        let normalizedMissingSnapshotGraceWindow = max(0, missingSnapshotGraceWindow)
        let triggerAge = now.timeIntervalSince(lastAutoTriggerAt)
        guard triggerAge >= normalizedMissingSnapshotGraceWindow else { return nil }
        return "Launch Rescue Auto Self-Heal missing (\(launchRescueAutoTriggerAtSummary(lastAutoTriggerAt, now: now))). Execute \(followupCommandTitle) now."
    }

    nonisolated static func launchRescueAutoSelfHealAttentionActionTitle(
        issueToken: String?,
        triggerReason: String?
    ) -> String? {
        guard let issueToken else { return nil }
        let normalizedTriggerReason = launchRescueAutoTriggerReasonToken(triggerReason)
        let triggerSummary = launchRescueAutoTriggerSummary(normalizedTriggerReason)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        if issueToken.hasPrefix("missing-") {
            return "Launch Rescue Self-Heal Attention: Missing check for \(triggerSummary)"
        }
        if issueToken.hasPrefix("stale-") {
            return "Launch Rescue Self-Heal Attention: Stale check for \(triggerSummary)"
        }
        if issueToken.hasPrefix("mismatch-") {
            return "Launch Rescue Self-Heal Attention: Trigger mismatch for \(triggerSummary)"
        }
        return "Launch Rescue Self-Heal Attention"
    }

    nonisolated static func launchRescueAutoSelfHealAttentionActionSubtitle(
        issueToken: String?,
        triggerReason: String?,
        activityItems: [ActivityLogItem],
        now: Date = Date(),
        lastAutoTriggerAt: Date? = nil
    ) -> String? {
        guard let issueToken else { return nil }
        guard issueToken.hasPrefix("missing-")
                || issueToken.hasPrefix("stale-")
                || issueToken.hasPrefix("mismatch-")
        else {
            return nil
        }
        return launchRescueAutoSelfHealAttentionNudgeMessage(
            triggerReason: triggerReason,
            activityItems: activityItems,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
    }

    nonisolated static func launchRescueAutoSelfHealAttentionActionSystemImage(
        issueToken: String?
    ) -> String {
        guard let issueToken else { return "bandage.fill" }
        if issueToken.hasPrefix("missing-") {
            return "questionmark.circle"
        }
        if issueToken.hasPrefix("stale-") {
            return "clock.badge.exclamationmark"
        }
        if issueToken.hasPrefix("mismatch-") {
            return "arrow.trianglehead.2.clockwise.rotate.90"
        }
        return "bandage.fill"
    }

    nonisolated static func launchRescueAutoSelfHealAttentionActionActivityDetail(
        issueToken: String
    ) -> String {
        "run-fame-launch-rescue-self-heal-attention-action-\(ActivityLogCommand.safeID(issueToken))"
    }

    nonisolated static func launchRescueAutoSelfHealAttentionIssueStreakNext(
        currentIssueToken: String?,
        previousIssueToken: String?,
        previousIssueStreak: Int
    ) -> Int {
        guard let currentIssueToken else { return 0 }
        let normalizedPreviousIssueStreak = max(0, previousIssueStreak)
        if previousIssueToken == currentIssueToken {
            return max(1, normalizedPreviousIssueStreak + 1)
        }
        return 1
    }

    nonisolated static func shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge(
        issueToken: String?,
        issueStreak: Int,
        lastNudgeAt: Date?,
        lastNudgeIssueToken: String?,
        now: Date = Date(),
        cooldown: TimeInterval = launchRescueAutoSelfHealAttentionNudgeCooldown,
        requiredConsecutiveCount: Int = 2
    ) -> Bool {
        guard let issueToken else { return false }
        guard issueStreak >= max(1, requiredConsecutiveCount) else { return false }
        return shouldRunFameLaunchThresholdAlertsQuickAction(
            lastRunAt: lastNudgeAt,
            lastActionToken: lastNudgeIssueToken,
            nextActionToken: issueToken,
            now: now,
            cooldown: max(0, cooldown)
        )
    }

    nonisolated static func launchRescueAutoSelfHealAttentionActivityDetail(
        issueToken: String,
        issueStreak: Int
    ) -> String {
        let normalizedIssueStreak = max(1, issueStreak)
        return "run-fame-launch-rescue-self-heal-attention-\(ActivityLogCommand.safeID(issueToken))-x\(normalizedIssueStreak)"
    }

    private func latestLaunchRescueAutoFollowupSelfHealSnapshot(
        now: Date = Date(),
        includeStale: Bool = false
    ) -> LaunchRescueAutoFollowupSelfHealSnapshot? {
        Self.latestLaunchRescueAutoFollowupSelfHealSnapshot(
            from: activityLog.items,
            now: now,
            includeStale: includeStale
        )
    }

    private func launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
        _ triggerReason: String?,
        now: Date = Date(),
        includeStale: Bool = false
    ) -> LaunchRescueAutoFollowupSelfHealSnapshot? {
        Self.launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            triggerReason,
            activityItems: activityLog.items,
            now: now,
            includeStale: includeStale
        )
    }

    private func launchRescueAutoFollowupSelfHealArtifactStatusTitle(
        triggerReason: String?,
        now: Date = Date()
    ) -> String {
        Self.launchRescueAutoFollowupSelfHealArtifactStatusTitle(
            triggerReason: triggerReason,
            activityItems: activityLog.items,
            now: now
        )
    }

    private func launchRescueAutoSelfHealAttentionMenuSnapshot(
        triggerReason: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> (
        issueToken: String,
        issueStreak: Int,
        recommendedActionID: String,
        signalBadge: CommandPaletteAction.SignalBadge
    )? {
        guard let issueToken = Self.launchRescueAutoSelfHealAttentionIssueToken(
            triggerReason: triggerReason,
            activityItems: activityLog.items,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        ) else {
            return nil
        }
        let issueStreak = Self.launchRescueAutoSelfHealAttentionIssueStreakNext(
            currentIssueToken: issueToken,
            previousIssueToken: launchRescueAutoSelfHealAttentionIssueToken,
            previousIssueStreak: launchRescueAutoSelfHealAttentionIssueStreak
        )
        let recommendedActionID = Self.launchRescueAutoSelfHealAttentionRecommendedActionID(
            issueToken: issueToken,
            triggerReason: triggerReason,
            issueStreak: issueStreak,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
        let signalBadge = Self.launchRescueAutoSelfHealAttentionSignalBadge(
            issueToken: issueToken,
            triggerReason: triggerReason,
            issueStreak: issueStreak,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
        return (
            issueToken: issueToken,
            issueStreak: issueStreak,
            recommendedActionID: recommendedActionID,
            signalBadge: signalBadge
        )
    }

    private func launchRescueAutoSelfHealAttentionMenuStatusTitle(
        _ snapshot: (
            issueToken: String,
            issueStreak: Int,
            recommendedActionID: String,
            signalBadge: CommandPaletteAction.SignalBadge
        )?
    ) -> String? {
        guard let snapshot else { return nil }
        return "Launch Rescue Auto Self-Heal Attention: \(snapshot.signalBadge.title) · \(snapshot.signalBadge.helpText)"
    }

    private func launchRescueFollowupPromptContext(
        triggerReason: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> (
        routeBadge: String?,
        selfHealAttentionBadge: String?,
        followupRouteDecisionTraceLine: String?
    ) {
        let followupRouteContext = launchRescueFollowupRouteDecisionContext(
            triggerReason: triggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        )
        return (
            routeBadge: Self.launchRescueAutoFollowupMenuRouteBadge(
                followupRouteContext.routeDecision.resolvedCommandID
            ),
            selfHealAttentionBadge: followupRouteContext.selfHealAttentionSnapshot?.signalBadge.title,
            followupRouteDecisionTraceLine: Self.launchRescueAutoFollowupRouteDecisionTraceLine(
                defaultCommandID: followupRouteContext.routeDecision.defaultCommandID,
                resolvedCommandID: followupRouteContext.routeDecision.resolvedCommandID
            )
        )
    }

    private func launchRescueFollowupRouteDecisionContext(
        triggerReason: String?,
        lastAutoTriggerAt: Date?,
        now: Date = Date()
    ) -> (
        selfHealAttentionSnapshot: (
            issueToken: String,
            issueStreak: Int,
            recommendedActionID: String,
            signalBadge: CommandPaletteAction.SignalBadge
        )?,
        routeDecision: (
            defaultCommandID: String,
            resolvedCommandID: String
        )
    ) {
        let selfHealAttentionSnapshot = launchRescueAutoSelfHealAttentionMenuSnapshot(
            triggerReason: triggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        )
        let routeDecision = Self.launchRescueAutoFollowupResolvedRouteDecision(
            triggerReason: triggerReason,
            recommendedActionID: selfHealAttentionSnapshot?.recommendedActionID
        )
        return (
            selfHealAttentionSnapshot: selfHealAttentionSnapshot,
            routeDecision: routeDecision
        )
    }

    private func launchRescueFollowupRouteDecisionContext(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> (
        triggerReason: String?,
        lastAutoTriggerAt: Date?,
        selfHealAttentionSnapshot: (
            issueToken: String,
            issueStreak: Int,
            recommendedActionID: String,
            signalBadge: CommandPaletteAction.SignalBadge
        )?,
        routeDecision: (
            defaultCommandID: String,
            resolvedCommandID: String
        )
    ) {
        let triggerReason = fameLaunchRescueBurstLastAutoTriggerReason(defaults: defaults)
        let lastAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt(defaults: defaults)
        let routeContext = launchRescueFollowupRouteDecisionContext(
            triggerReason: triggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            now: now
        )
        return (
            triggerReason: triggerReason,
            lastAutoTriggerAt: lastAutoTriggerAt,
            selfHealAttentionSnapshot: routeContext.selfHealAttentionSnapshot,
            routeDecision: routeContext.routeDecision
        )
    }

    @discardableResult
    private func maybeSurfaceLaunchRescueAutoSelfHealAttentionNudge(
        triggerReason: String?,
        now: Date = Date()
    ) -> Bool {
        let lastAutoTriggerAt = fameLaunchRescueBurstLastAutoTriggerAt()
        let issueToken = Self.launchRescueAutoSelfHealAttentionIssueToken(
            triggerReason: triggerReason,
            activityItems: activityLog.items,
            now: now,
            lastAutoTriggerAt: lastAutoTriggerAt
        )
        launchRescueAutoSelfHealAttentionIssueStreak =
            Self.launchRescueAutoSelfHealAttentionIssueStreakNext(
                currentIssueToken: issueToken,
                previousIssueToken: launchRescueAutoSelfHealAttentionIssueToken,
                previousIssueStreak: launchRescueAutoSelfHealAttentionIssueStreak
            )
        launchRescueAutoSelfHealAttentionIssueToken = issueToken

        guard Self.shouldSurfaceLaunchRescueAutoSelfHealAttentionNudge(
            issueToken: issueToken,
            issueStreak: launchRescueAutoSelfHealAttentionIssueStreak,
            lastNudgeAt: launchRescueAutoSelfHealAttentionLastNudgeAt,
            lastNudgeIssueToken: launchRescueAutoSelfHealAttentionLastNudgeIssueToken,
            now: now,
            cooldown: Self.launchRescueAutoSelfHealAttentionNudgeCooldown
        ), let issueToken,
          let message = Self.launchRescueAutoSelfHealAttentionNudgeMessage(
              triggerReason: triggerReason,
              activityItems: activityLog.items,
              now: now,
              lastAutoTriggerAt: lastAutoTriggerAt
          ) else {
            return false
        }

        launchRescueAutoSelfHealAttentionLastNudgeAt = now
        launchRescueAutoSelfHealAttentionLastNudgeIssueToken = issueToken
        readerState.petSay(message, mood: .ready)
        readerState.pulse()
        flashStatus(symbol: "bandage.fill", tint: .systemOrange, length: 0.16)
        recordActivity(
            category: "support",
            detail: Self.launchRescueAutoSelfHealAttentionActivityDetail(
                issueToken: issueToken,
                issueStreak: launchRescueAutoSelfHealAttentionIssueStreak
            )
        )
        return true
    }

    private func updateLaunchRescueAutoMenuStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        updateAutoOpsBundleMenuStatus(now: now, defaults: defaults)
        let launchRescueAutoTriggerReason = fameLaunchRescueBurstLastAutoTriggerReason(defaults: defaults)
        fameLaunchRescueAutoStatusMenuItem?.title = launchRescueAutoMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueAutoStatusMenuItem?.toolTip = launchRescueAutoMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueFollowupNowMenuItem?.title = launchRescueFollowupNowMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueFollowupNowMenuItem?.toolTip = launchRescueFollowupNowMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueSnapshotMenuItem?.title = launchRescueSnapshotMenuTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueSnapshotMenuItem?.toolTip = launchRescueSnapshotCopyMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueSnapshotOpenMenuItem?.title = launchRescueSnapshotOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueSnapshotOpenMenuItem?.toolTip = launchRescueSnapshotOpenMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameOpenLatestLaunchRescueSnapshotMenuItem?.title = launchRescueSnapshotOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameOpenLatestLaunchRescueSnapshotMenuItem?.toolTip =
            launchRescueSnapshotOpenMenuStatusToolTip(
                now: now,
                defaults: defaults
            )
        fameLaunchCountdownRunMenuItem?.title = launchCountdownRunMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchCountdownRunMenuItem?.toolTip = launchCountdownRunMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchCountdownOpenMenuItem?.title = launchCountdownOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchCountdownOpenMenuItem?.toolTip = launchCountdownOpenMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueBurstRunMenuItem?.title = launchRescueBurstRunMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueBurstRunMenuItem?.toolTip = launchRescueBurstRunMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueBurstOpenMenuItem?.title = launchRescueBurstOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchRescueBurstOpenMenuItem?.toolTip = launchRescueBurstOpenMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchControlBriefRunMenuItem?.title = launchControlBriefRunMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchControlBriefRunMenuItem?.toolTip = launchControlBriefRunMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchControlBriefOpenMenuItem?.title = launchControlBriefOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchControlBriefOpenMenuItem?.toolTip = launchControlBriefOpenMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchControlBriefCopyMenuItem?.title = launchControlBriefCopyMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchControlBriefCopyMenuItem?.toolTip = launchControlBriefCopyMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchControlHubRunMenuItem?.title = launchControlHubRunMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchControlHubRunMenuItem?.toolTip = launchControlHubRunMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameLaunchControlHubOpenMenuItem?.title = launchControlHubOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameLaunchControlHubOpenMenuItem?.toolTip = launchControlHubOpenMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        fameOpenLatestLaunchControlHubMenuItem?.title = launchControlHubOpenMenuStatusTitle(
            now: now,
            defaults: defaults
        )
        fameOpenLatestLaunchControlHubMenuItem?.toolTip = launchControlHubOpenMenuStatusToolTip(
            now: now,
            defaults: defaults
        )
        _ = maybeSurfaceLaunchRescueAutoSelfHealAttentionNudge(
            triggerReason: launchRescueAutoTriggerReason,
            now: now
        )
    }

    private func launchRescueAutoMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let modeMomentumStreak = defaults.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let followupRouteContext = launchRescueFollowupRouteDecisionContext(
            now: now,
            defaults: defaults
        )
        let selfHealSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            followupRouteContext.triggerReason,
            now: now
        )
        let followupBadge = Self.launchRescueAutoFollowupBadgeForResolvedDecision(
            triggerReason: followupRouteContext.triggerReason,
            lastAutoTriggerAt: followupRouteContext.lastAutoTriggerAt,
            defaultCommandID: followupRouteContext.routeDecision.defaultCommandID,
            resolvedCommandID: followupRouteContext.routeDecision.resolvedCommandID,
            now: now
        )
        return Self.launchRescueBurstAutoStatusMenuTitle(
            launchRescueBurstAutoStatus(now: now, defaults: defaults),
            modeMomentumStreak: modeMomentumStreak,
            followupBadge: followupBadge,
            selfHealBadge: Self.launchRescueAutoFollowupSelfHealBadge(selfHealSnapshot),
            selfHealAttentionBadge: followupRouteContext.selfHealAttentionSnapshot?.signalBadge.title,
            triggerSeverityBadge: Self.launchRescueAutoTriggerSeverityBadge(
                followupRouteContext.triggerReason
            )
        )
    }

    private func launchRescueAutoMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let modeMomentumStreak = defaults.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let followupRouteContext = launchRescueFollowupRouteDecisionContext(
            now: now,
            defaults: defaults
        )
        let selfHealSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            followupRouteContext.triggerReason,
            now: now
        )
        let followupOutcomeScoreboard = launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults
        )
        let followupCoachRecoveryLaneStreak = launchRescueFollowupCoachRecoveryLaneStreak(
            defaults: defaults
        )
        let followupCoachRecoveryChecklistCooldownMinutes =
            launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
                defaults: defaults
            )
        let followupCoachRecoveryChecklistCooldownMinutesRemaining =
            launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining(
                now: now,
                defaults: defaults
            )
        let followupOutcomeCoachStatusTitle = Self.launchRescueFollowupOutcomeCoachStatusTitle(
            followupOutcomeScoreboard,
            triggerReason: followupRouteContext.triggerReason,
            recoveryLaneStreak: followupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                followupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                followupCoachRecoveryChecklistCooldownMinutesRemaining,
            now: now
        )
        let followupOutcomeMomentumStatusTitle = Self.launchRescueFollowupMomentumStatusTitle(
            followupOutcomeScoreboard,
            recoveryLaneStreak: followupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                followupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                followupCoachRecoveryChecklistCooldownMinutesRemaining
        )
        return Self.launchRescueBurstAutoStatusMenuToolTip(
            launchRescueBurstAutoStatus(now: now, defaults: defaults),
            modeMomentumStreak: modeMomentumStreak,
            lastAutoTriggerReason: followupRouteContext.triggerReason,
            lastAutoTriggerAt: followupRouteContext.lastAutoTriggerAt,
            selfHealStatusTitle: Self.launchRescueAutoFollowupSelfHealStatusTitle(
                selfHealSnapshot,
                now: now
            ),
            selfHealAttentionStatusTitle: launchRescueAutoSelfHealAttentionMenuStatusTitle(
                followupRouteContext.selfHealAttentionSnapshot
            ),
            followupOutcomeScoreboardStatusTitle: Self.launchRescueFollowupOutcomeScoreboardStatusTitle(
                followupOutcomeScoreboard,
                now: now
            ),
            followupOutcomeCoachStatusTitle: followupOutcomeCoachStatusTitle,
            followupOutcomeMomentumStatusTitle: followupOutcomeMomentumStatusTitle,
            followupRouteDecisionTraceLine: Self.launchRescueAutoFollowupRouteDecisionTraceLine(
                defaultCommandID: followupRouteContext.routeDecision.defaultCommandID,
                resolvedCommandID: followupRouteContext.routeDecision.resolvedCommandID
            ),
            now: now
        )
    }

    private func launchRescueFollowupNowMenuStatusTitle(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let followupRouteContext = launchRescueFollowupRouteDecisionContext(
            now: now,
            defaults: defaults
        )
        let routeBadge = Self.launchRescueAutoFollowupRouteBadgeForResolvedDecision(
            defaultCommandID: followupRouteContext.routeDecision.defaultCommandID,
            resolvedCommandID: followupRouteContext.routeDecision.resolvedCommandID
        )
        return Self.launchRescueAutoTriggerFollowupActionTitle(
            followupRouteContext.triggerReason,
            selfHealAttentionBadge: followupRouteContext.selfHealAttentionSnapshot?.signalBadge.title,
            routeBadge: routeBadge
        )
    }

    private func launchRescueFollowupNowMenuStatusToolTip(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> String {
        let followupRouteContext = launchRescueFollowupRouteDecisionContext(
            now: now,
            defaults: defaults
        )
        let selfHealSnapshot = launchRescueAutoFollowupSelfHealSnapshotForTriggerReason(
            followupRouteContext.triggerReason,
            now: now
        )
        let followupOutcomeScoreboard = launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults
        )
        let followupCoachRecoveryLaneStreak = launchRescueFollowupCoachRecoveryLaneStreak(
            defaults: defaults
        )
        let followupCoachRecoveryChecklistCooldownMinutes =
            launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
                defaults: defaults
            )
        let followupCoachRecoveryChecklistCooldownMinutesRemaining =
            launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining(
                now: now,
                defaults: defaults
            )
        let followupOutcomeCoachStatusTitle = Self.launchRescueFollowupOutcomeCoachStatusTitle(
            followupOutcomeScoreboard,
            triggerReason: followupRouteContext.triggerReason,
            recoveryLaneStreak: followupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                followupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                followupCoachRecoveryChecklistCooldownMinutesRemaining,
            now: now
        )
        let followupOutcomeMomentumStatusTitle = Self.launchRescueFollowupMomentumStatusTitle(
            followupOutcomeScoreboard,
            recoveryLaneStreak: followupCoachRecoveryLaneStreak,
            recoveryChecklistCooldownMinutes:
                followupCoachRecoveryChecklistCooldownMinutes,
            recoveryChecklistCooldownMinutesRemaining:
                followupCoachRecoveryChecklistCooldownMinutesRemaining
        )
        return Self.launchRescueAutoTriggerFollowupMenuToolTip(
            followupRouteContext.triggerReason,
            lastAutoTriggerAt: followupRouteContext.lastAutoTriggerAt,
            selfHealStatusTitle: Self.launchRescueAutoFollowupSelfHealStatusTitle(
                selfHealSnapshot,
                now: now
            ),
            selfHealAttentionStatusTitle: launchRescueAutoSelfHealAttentionMenuStatusTitle(
                followupRouteContext.selfHealAttentionSnapshot
            ),
            followupOutcomeScoreboardStatusTitle: Self.launchRescueFollowupOutcomeScoreboardStatusTitle(
                followupOutcomeScoreboard,
                now: now
            ),
            followupOutcomeCoachStatusTitle: followupOutcomeCoachStatusTitle,
            followupOutcomeMomentumStatusTitle: followupOutcomeMomentumStatusTitle,
            routeCommandIDOverride: followupRouteContext.routeDecision.resolvedCommandID,
            now: now
        )
    }

    private func fameNextMoveMenuCommandID(
        signal: FamePulseAlertSignal? = nil,
        transition: FamePulseRiskTransition? = nil
    ) -> String {
        let resolvedSignal = signal ?? famePulseAlertSignal()
        let resolvedTransition = transition ?? famePulseLatestTransition()
        return Self.fameNextMoveCommandID(
            signal: resolvedSignal,
            transition: resolvedTransition,
            scorecard: fameDailyScorecardState()
        )
    }

    private func fameNextMoveMenuTitle(
        signal: FamePulseAlertSignal? = nil,
        transition: FamePulseRiskTransition? = nil
    ) -> String {
        let onboardingRecoverySnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot()
        let onboardingRecoveryHint = Self.fameOnboardingRecoveryMomentumHint(
            isFreshRecovery: onboardingRecoverySnapshot.isFresh,
            remainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
        )
        return Self.fameNextMoveMenuTitle(
            commandID: fameNextMoveMenuCommandID(signal: signal, transition: transition),
            onboardingRecoveryHint: onboardingRecoveryHint
        )
    }

    private func handleFamePulseRiskTransition(
        _ transition: FamePulseRiskTransition,
        signal: FamePulseAlertSignal?
    ) {
        guard let signal else { return }

        let isCalibrating = transition.fromRiskLevel == "Unknown"
        let hudMood: RewardHUDController.Mood = transition.isEscalation ? .error : .success
        let petMood: PetMood = transition.isEscalation ? .error : .happy
        let hudTitle: String
        let petMessage: String

        if isCalibrating {
            hudTitle = transition.isEscalation
                ? "Pulse Risk \(transition.toRiskLevel)"
                : "Pulse Risk Ready"
            petMessage = "Pulse risk calibrated at \(transition.toRiskLevel). \(signal.mustShipAlert)"
        } else if transition.isEscalation {
            hudTitle = "Pulse Risk Escalated"
            petMessage = "Pulse risk moved \(transition.fromRiskLevel) -> \(transition.toRiskLevel). \(signal.mustShipAlert)"
        } else {
            hudTitle = "Pulse Risk Improved"
            petMessage = "Pulse risk moved \(transition.fromRiskLevel) -> \(transition.toRiskLevel). \(signal.mustShipAlert)"
        }

        let symbol: String
        let tint: NSColor
        if transition.isEscalation {
            switch transition.toRiskLevel {
            case "Critical":
                symbol = "exclamationmark.triangle.fill"
                tint = .systemRed
            case "High":
                symbol = "exclamationmark.triangle"
                tint = .systemOrange
            default:
                symbol = "exclamationmark.circle"
                tint = .systemYellow
            }
        } else {
            switch transition.toRiskLevel {
            case "Low":
                symbol = "checkmark.circle.fill"
                tint = .systemGreen
            default:
                symbol = "arrow.down.circle"
                tint = .systemBlue
            }
        }

        readerState.petSay(petMessage, mood: petMood)
        readerState.pulse()
        rewardHUD.show(hudTitle, mood: hudMood, intensity: settings.feelIntensity)
        flashStatus(symbol: symbol, tint: tint, length: 0.28)

        let activityDetail: String
        if isCalibrating {
            activityDetail = "pulse-risk-calibrated-\(transition.toRiskLevel.lowercased())"
        } else {
            let direction = transition.isEscalation ? "up" : "down"
            activityDetail = "pulse-risk-\(direction)-\(transition.toRiskLevel.lowercased())"
        }
        recordActivity(category: "fame", detail: activityDetail)

        if shouldAutoSurfaceFameEscalationNudge(transition) {
            autoSurfaceFameEscalationNudge(transition: transition, signal: signal)
        }
    }

    private func handleFameLaunchUrgencyTransition(
        _ transition: FameLaunchUrgencyTransition,
        status: FameLaunchCountdownStatus?
    ) {
        guard let status else { return }
        guard Self.shouldSurfaceFameLaunchUrgencyTransition(
            transition,
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled
        ) else { return }

        let hudTitle: String
        let hudMood: RewardHUDController.Mood
        let petMood: PetMood
        let symbol: String
        let tint: NSColor
        let messagePrefix: String
        let hapticType: NSHapticFeedbackManager.FeedbackPattern

        if transition.isEscalation {
            switch transition.to {
            case .live:
                hudTitle = "Launch Window Live"
                hudMood = .success
                petMood = .happy
                symbol = "bolt.badge.clock"
                tint = .systemGreen
                messagePrefix = "Launch is live."
                hapticType = .alignment
            case .hot:
                hudTitle = "Launch Alert: Hot"
                hudMood = .working
                petMood = .error
                symbol = "flame.fill"
                tint = .systemOrange
                messagePrefix = "Launch is overdue."
                hapticType = .levelChange
            case .high:
                hudTitle = "Launch Alert: High"
                hudMood = .error
                petMood = .error
                symbol = "exclamationmark.triangle"
                tint = .systemOrange
                messagePrefix = "Launch is overdue 15m+."
                hapticType = .levelChange
            case .critical:
                hudTitle = "Launch Alert: Critical"
                hudMood = .error
                petMood = .error
                symbol = "exclamationmark.triangle.fill"
                tint = .systemRed
                messagePrefix = "Launch is overdue 30m+."
                hapticType = .levelChange
            case .prep, .ready:
                return
            }
        } else {
            hudTitle = "Launch Alert Stabilized"
            hudMood = .success
            petMood = .happy
            symbol = "arrow.down.circle"
            tint = .systemBlue
            messagePrefix = "Launch urgency eased \(Self.fameLaunchBadgeUrgencyLabel(transition.from)) -> \(Self.fameLaunchBadgeUrgencyLabel(transition.to))."
            hapticType = .alignment
        }

        let petMessage = "\(messagePrefix) \(status.nextAction)"
        readerState.petSay(petMessage, mood: petMood)
        readerState.pulse()
        effects.hit(.success, settings: settings, haptic: hapticType)
        rewardHUD.show(hudTitle, mood: hudMood, intensity: settings.feelIntensity)
        flashStatus(symbol: symbol, tint: tint, length: 0.26)

        let direction = transition.isEscalation ? "up" : "down"
        let detail = "launch-urgency-\(direction)-\(Self.fameLaunchBadgeUrgencyToken(transition.to))"
        recordActivity(category: "fame", detail: detail)

        autoRunFameLaunchRescueBurstIfNeeded(transition: transition, status: status)
    }

    private func handleLaunchControlHealthTransitionPulse(
        _ transition: LaunchControlHealthTransition,
        status: FameLaunchCountdownStatus?,
        now: Date = Date()
    ) {
        guard settings.fameLaunchHealthPulseEnabled else { return }
        guard Self.shouldSurfaceLaunchControlHealthTransitionPulse(
            transition,
            alertsEnabled: settings.fameLaunchThresholdAlertsEnabled
        ) else { return }
        guard Self.shouldPulseLaunchControlHealthTransition(
            lastPulseAt: launchControlHealthPulseLastAt,
            lastPulseToken: launchControlHealthPulseLastToken,
            transition: transition,
            now: now,
            cooldown: launchControlHealthPulseCooldown
        ) else { return }

        let commandID = Self.launchControlHealthActionCommandID(launchStatus: status)
        let commandTitle = Self.launchControlHealthActionTitle(commandID: commandID)
        let hapticType: NSHapticFeedbackManager.FeedbackPattern
        let symbol: String
        let tint: NSColor
        let petMood: PetMood
        let messagePrefix: String

        switch (transition.from, transition.to) {
        case (.watch, .risk):
            hapticType = .levelChange
            symbol = "exclamationmark.triangle.fill"
            tint = .systemRed
            petMood = .error
            messagePrefix = "Launch health moved Watch -> Risk."
        case (.risk, .ready):
            hapticType = .alignment
            symbol = "checkmark.shield.fill"
            tint = .systemGreen
            petMood = .happy
            messagePrefix = "Launch health recovered Risk -> Ready."
        default:
            return
        }

        let nextActionText = status.map { " \($0.nextAction)" } ?? ""
        readerState.petSay("\(messagePrefix)\(nextActionText) Click: \(commandTitle).", mood: petMood)
        readerState.pulse()
        effects.hit(.tap, settings: settings, haptic: hapticType)
        flashStatus(symbol: symbol, tint: tint, length: 0.16)
        launchControlHealthPulseLastAt = now
        launchControlHealthPulseLastToken = Self.launchControlHealthTransitionPulseToken(transition)
        recordActivity(
            category: "fame",
            detail: "launch-health-\(Self.launchControlHealthTransitionPulseToken(transition))"
        )
    }

    private func shouldAutoSurfaceFameEscalationNudge(_ transition: FamePulseRiskTransition) -> Bool {
        Self.shouldAutoTriggerFameEscalationResponse(transition)
    }

    private func autoSurfaceFameEscalationNudge(
        transition: FamePulseRiskTransition,
        signal: FamePulseAlertSignal
    ) {
        let nudge = FameSnapshotRollup.escalationNudge(
            transition: transition,
            signal: signal
        )
        var markdown = nudge.markdown
        if let opsBundleSummary = autoEscalationOpsBundleSummary() {
            markdown += "\n\n\(opsBundleSummary)"
        }

        do {
            _ = try FameSnapshotArchive.saveEscalationNudge(markdown: markdown)
            readerState.answerText = markdown
            readerState.errorText = ""
            readerState.remember(text: "", answer: markdown)
            readerState.pulse()
            readerWindow.show()
            recordActivity(category: "fame", detail: "pulse-risk-escalation-nudge-\(transition.toRiskLevel.lowercased())")
        } catch {
            recordActivity(category: "fame", detail: "pulse-risk-escalation-nudge-error")
        }
    }

    private func autoRunFameLaunchRescueBurstIfNeeded(
        transition: FameLaunchUrgencyTransition,
        status: FameLaunchCountdownStatus,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        guard !isRunningLaunchControlAutoRescue else { return }
        guard transition.isEscalation else { return }
        switch transition.to {
        case .hot, .high, .critical:
            break
        case .prep, .ready, .live:
            return
        }
        let modeMomentumStreak = defaults.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let modeMomentumCueSeverity = Self.launchRescueModeMomentumCueSeverity(
            modeMomentumStreak: modeMomentumStreak
        )
        let triggerReason = Self.launchRescueAutoTriggerReason(
            transition: transition,
            modeMomentumCueSeverity: modeMomentumCueSeverity
        )
        if transition.to == .hot,
           modeMomentumCueSeverity == .none {
            return
        }

        let urgencyToken = Self.fameLaunchBadgeUrgencyToken(status: status)
        let cooldown = fameLaunchRescueBurstAutoCooldown
        guard Self.shouldAutoRunFameLaunchRescueBurst(
            transition,
            modeMomentumStreak: modeMomentumStreak,
            lastRunAt: fameLaunchRescueBurstLastRunAt(defaults: defaults),
            now: now,
            cooldown: cooldown
        ) else {
            recordActivity(
                category: "share",
                detail: Self.launchControlHubAutoSkipActivityDetail(
                    skipReason: cooldown > 0 ? "cooldown" : "disabled",
                    urgencyToken: urgencyToken,
                    triggerReason: triggerReason
                )
            )
            return
        }

        isRunningLaunchControlAutoRescue = true
        defer { isRunningLaunchControlAutoRescue = false }

        if runFameLaunchControlHub(
            source: "auto-\(urgencyToken)",
            announce: false,
            now: now
        ) {
            setFameLaunchRescueBurstLastRunAt(now, defaults: defaults)
            setFameLaunchRescueBurstLastAutoTriggerReason(
                triggerReason.rawValue,
                defaults: defaults
            )
            setFameLaunchRescueBurstLastAutoTriggerAt(now, defaults: defaults)
            recordActivity(
                category: "share",
                detail: Self.launchControlHubAutoEscalationActivityDetail(urgencyToken: urgencyToken)
            )
            recordActivity(
                category: "share",
                detail: Self.launchRescueAutoTriggerActivityDetail(reason: triggerReason)
            )
            _ = runFameLaunchRescueFollowupNowAuto(
                triggerReason: triggerReason,
                now: now,
                defaults: defaults
            )
        }
    }

    private func launchHealthPressureAutoRescueLastRunAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        if defaults.object(forKey: fameLaunchHealthPressureAutoRescueLastRunAtKey) != nil {
            let stamp = defaults.double(forKey: fameLaunchHealthPressureAutoRescueLastRunAtKey)
            if stamp > 0 {
                return Date(timeIntervalSince1970: stamp)
            }
        }

        guard let dayStamp = defaults.string(forKey: fameLaunchHealthPressureAutoRescueLastRunDayKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !dayStamp.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        guard let migratedDate = formatter.date(from: dayStamp) else {
            return nil
        }
        defaults.set(
            migratedDate.timeIntervalSince1970,
            forKey: fameLaunchHealthPressureAutoRescueLastRunAtKey
        )
        return migratedDate
    }

    private func setLaunchHealthPressureAutoRescueLastRunAt(
        _ date: Date,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(
            date.timeIntervalSince1970,
            forKey: fameLaunchHealthPressureAutoRescueLastRunAtKey
        )
        defaults.set(
            Self.launchControlHealthTransitionCountDayStamp(now: date),
            forKey: fameLaunchHealthPressureAutoRescueLastRunDayKey
        )
    }

    private func autoRunFameLaunchRescueBurstForPressurePersistenceIfNeeded(
        launchStatus: FameLaunchCountdownStatus?,
        healthInsights: LaunchControlHealthInsights,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        guard !isRunningLaunchControlAutoRescue else { return }
        guard Self.shouldAutoRunLaunchRescueBurstForPressurePersistence(
            isEnabled: settings.fameLaunchHealthPressureAutoRescueEnabled,
            launchStatus: launchStatus,
            momentumSignal: healthInsights.momentumSignal,
            pressureStreakDays: healthInsights.pressureStreakDays,
            lastAutoRunAt: launchHealthPressureAutoRescueLastRunAt(defaults: defaults),
            now: now,
            cooldown: launchHealthPressureAutoRescueCooldown
        ) else {
            return
        }

        let autoSource = "auto-pressure-streak-\(healthInsights.pressureStreakDays)"
        isRunningLaunchControlAutoRescue = true
        defer { isRunningLaunchControlAutoRescue = false }

        guard runFameLaunchControlHub(
            source: autoSource,
            announce: false,
            now: now
        ) else {
            return
        }

        setLaunchHealthPressureAutoRescueLastRunAt(now, defaults: defaults)
        setFameLaunchRescueBurstLastRunAt(now, defaults: defaults)
        setFameLaunchRescueBurstLastAutoTriggerReason(
            LaunchRescueAutoTriggerReason.pressurePersistence.rawValue,
            defaults: defaults
        )
        setFameLaunchRescueBurstLastAutoTriggerAt(now, defaults: defaults)
        recordActivity(
            category: "share",
            detail: "run-fame-launch-control-hub-auto-pressure-streak-\(healthInsights.pressureStreakDays)"
        )
        recordActivity(
            category: "share",
            detail: Self.launchRescueAutoTriggerActivityDetail(
                reason: .pressurePersistence,
                pressureStreakDays: healthInsights.pressureStreakDays
            )
        )
        _ = runFameLaunchRescueFollowupNowAutoPressurePersistence(
            now: now,
            defaults: defaults
        )
    }

    private func autoEscalationOpsBundleSummary(now: Date = Date()) -> String? {
        let defaults = UserDefaults.standard
        switch autoOpsBundleEscalationStatus(now: now, defaults: defaults) {
        case .disabled:
            recordActivity(category: "saved", detail: "run-fame-ops-bundle-auto-skipped-disabled")
            return Self.autoEscalationOpsBundleSummaryDisabledMarkdown()
        case .coolingDown(let remainingMinutes):
            recordActivity(category: "saved", detail: "run-fame-ops-bundle-auto-skipped-cooldown")
            return Self.autoEscalationOpsBundleSummaryCooldownMarkdown(
                remainingMinutes: remainingMinutes
            )
        case .ready:
            do {
                let directoryURL = try FameSnapshotArchive.defaultDirectoryURL()
                let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")

                let commandCenter = FameSnapshotRollup.commandCenterFromLedger(at: ledgerURL)
                let checkpoint = FameSnapshotRollup.dailyCheckpointFromLedger(at: ledgerURL)
                let riskTimeline = FameSnapshotRollup.riskTimelineFromLedger(at: ledgerURL)
                let pulseNudge = FameSnapshotRollup.pulseNudgeFromLedger(at: ledgerURL)
                let files = try FameSnapshotArchive.saveOpsBundleFiles(
                    commandCenterMarkdown: commandCenter,
                    checkpointMarkdown: checkpoint,
                    riskTimelineMarkdown: riskTimeline,
                    pulseNudgeMarkdown: pulseNudge,
                    now: now
                )
                setAutoOpsBundleLastRunAt(now, defaults: defaults)
                recordActivity(category: "saved", detail: "run-fame-ops-bundle-auto")
                return Self.autoEscalationOpsBundleSummaryReadyMarkdown(
                    commandCenterArtifactName: files.commandCenterURL.lastPathComponent,
                    checkpointArtifactName: files.checkpointURL.lastPathComponent,
                    riskTimelineArtifactName: files.riskTimelineURL.lastPathComponent,
                    pulseNudgeArtifactName: files.pulseNudgeURL.lastPathComponent
                )
            } catch {
                recordActivity(category: "saved", detail: "run-fame-ops-bundle-auto-error")
                return nil
            }
        }
    }

    private func autoOpsBundleEscalationStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> AutoOpsBundleEscalationStatus {
        Self.autoOpsBundleEscalationStatus(
            lastRunAt: autoOpsBundleLastRunAt(defaults: defaults),
            now: now,
            cooldownMinutes: settings.fameAutoOpsBundleCooldownMinutes
        )
    }

    private func launchRescueBurstAutoStatus(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> AutoOpsBundleEscalationStatus {
        Self.autoOpsBundleEscalationStatus(
            lastRunAt: fameLaunchRescueBurstLastRunAt(defaults: defaults),
            now: now,
            cooldownMinutes: settings.fameLaunchRescueBurstAutoCooldownMinutes
        )
    }

    private func launchControlHealthTransitionCounts(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> (watchToRiskCount: Int, riskToReadyCount: Int) {
        Self.launchControlHealthTransitionCounts(
            now: now,
            defaults: defaults,
            dayKey: fameLaunchHealthTransitionCountDayKey,
            watchToRiskCountKey: fameLaunchHealthTransitionWatchToRiskCountKey,
            riskToReadyCountKey: fameLaunchHealthTransitionRiskToReadyCountKey
        )
    }

    private func launchControlHealthTransitionHistoryWindow(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> [LaunchControlHealthTransitionHistoryDay] {
        Self.launchControlHealthTransitionHistoryWindow(
            now: now,
            defaults: defaults,
            dayKey: fameLaunchHealthTransitionCountDayKey,
            watchToRiskCountKey: fameLaunchHealthTransitionWatchToRiskCountKey,
            riskToReadyCountKey: fameLaunchHealthTransitionRiskToReadyCountKey,
            historyKey: fameLaunchHealthTransitionHistoryKey
        )
    }

    private func launchControlHealthInsights(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> LaunchControlHealthInsights {
        let transitionCounts = launchControlHealthTransitionCounts(
            now: now,
            defaults: defaults
        )
        let transitionHistoryWindow = launchControlHealthTransitionHistoryWindow(
            now: now,
            defaults: defaults
        )
        let averageDeltaTitle = Self.launchControlHealthTransitionAverageDeltaTitle(
            watchToRiskCount: transitionCounts.watchToRiskCount,
            riskToReadyCount: transitionCounts.riskToReadyCount,
            historyWindow: transitionHistoryWindow
        )
        let momentumSignal = Self.launchControlHealthMomentumSignal(
            watchToRiskCount: transitionCounts.watchToRiskCount,
            riskToReadyCount: transitionCounts.riskToReadyCount,
            historyWindow: transitionHistoryWindow
        )
        let pressureStreakDays = Self.launchControlHealthPressureStreakDays(
            historyWindow: transitionHistoryWindow
        )
        return LaunchControlHealthInsights(
            transitionCounts: transitionCounts,
            averageDeltaTitle: averageDeltaTitle,
            momentumSignal: momentumSignal,
            momentumStatusTitle: Self.launchControlHealthMomentumStatusTitle(momentumSignal),
            pressureStreakDays: pressureStreakDays,
            pressurePersistenceStatusTitle: Self.launchControlHealthPressurePersistenceStatusTitle(
                streakDays: pressureStreakDays
            )
        )
    }

    @discardableResult
    private func incrementLaunchControlHealthTransitionCount(
        _ transition: LaunchControlHealthTransition,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard Self.incrementLaunchControlHealthTransitionCounts(
            transition,
            now: now,
            defaults: defaults,
            dayKey: fameLaunchHealthTransitionCountDayKey,
            watchToRiskCountKey: fameLaunchHealthTransitionWatchToRiskCountKey,
            riskToReadyCountKey: fameLaunchHealthTransitionRiskToReadyCountKey,
            historyKey: fameLaunchHealthTransitionHistoryKey
        ) != nil else {
            return false
        }
        return true
    }

    private func fameLaunchRescueBurstLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: fameLaunchRescueBurstLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: fameLaunchRescueBurstLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func fameLaunchRescueBurstLastAutoTriggerAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        Self.launchRescueAutoTriggerAt(
            defaults.object(forKey: fameLaunchRescueBurstLastAutoTriggerAtKey)
        )
    }

    private func fameLaunchRescueBurstLastAutoTriggerReason(
        defaults: UserDefaults = .standard
    ) -> String {
        Self.launchRescueAutoTriggerReasonToken(
            defaults.string(forKey: fameLaunchRescueBurstLastAutoTriggerReasonKey)
        )
    }

    private func fameLaunchRescueBurstLastFollowupReason(
        defaults: UserDefaults = .standard
    ) -> String {
        Self.launchRescueAutoTriggerReasonToken(
            defaults.string(forKey: fameLaunchRescueBurstLastFollowupReasonKey)
        )
    }

    private func fameLaunchRescueBurstLastFollowupCommandID(
        defaults: UserDefaults = .standard
    ) -> String {
        Self.launchRescueAutoFollowupCommandID(
            defaults.string(forKey: fameLaunchRescueBurstLastFollowupCommandIDKey)
        )
    }

    private func fameLaunchRescueBurstLastFollowupAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        Self.launchRescueAutoTriggerAt(
            defaults.object(forKey: fameLaunchRescueBurstLastFollowupAtKey)
        )
    }

    private func setFameLaunchRescueBurstLastAutoTriggerReason(
        _ token: String,
        defaults: UserDefaults = .standard
    ) {
        let normalizedToken = Self.launchRescueAutoTriggerReasonToken(token)
        switch normalizedToken {
        case "none":
            defaults.set("none", forKey: fameLaunchRescueBurstLastAutoTriggerReasonKey)
        default:
            defaults.set(normalizedToken, forKey: fameLaunchRescueBurstLastAutoTriggerReasonKey)
        }
    }

    private func setFameLaunchRescueBurstLastAutoTriggerAt(
        _ date: Date?,
        defaults: UserDefaults = .standard
    ) {
        guard let date else {
            defaults.removeObject(forKey: fameLaunchRescueBurstLastAutoTriggerAtKey)
            return
        }
        defaults.set(
            date.timeIntervalSince1970,
            forKey: fameLaunchRescueBurstLastAutoTriggerAtKey
        )
    }

    private func setFameLaunchRescueBurstLastFollowupReason(
        _ token: String,
        defaults: UserDefaults = .standard
    ) {
        let normalizedToken = Self.launchRescueAutoTriggerReasonToken(token)
        switch normalizedToken {
        case "none":
            defaults.set("none", forKey: fameLaunchRescueBurstLastFollowupReasonKey)
        default:
            defaults.set(normalizedToken, forKey: fameLaunchRescueBurstLastFollowupReasonKey)
        }
    }

    private func setFameLaunchRescueBurstLastFollowupCommandID(
        _ commandID: String,
        defaults: UserDefaults = .standard
    ) {
        let normalizedCommandID = Self.launchRescueAutoFollowupCommandID(commandID)
        switch normalizedCommandID {
        case "none":
            defaults.set("none", forKey: fameLaunchRescueBurstLastFollowupCommandIDKey)
        default:
            defaults.set(normalizedCommandID, forKey: fameLaunchRescueBurstLastFollowupCommandIDKey)
        }
    }

    private func setFameLaunchRescueBurstLastFollowupAt(
        _ date: Date?,
        defaults: UserDefaults = .standard
    ) {
        guard let date else {
            defaults.removeObject(forKey: fameLaunchRescueBurstLastFollowupAtKey)
            return
        }
        defaults.set(
            date.timeIntervalSince1970,
            forKey: fameLaunchRescueBurstLastFollowupAtKey
        )
    }

    private func launchRescueFollowupCoachRecoveryLaneStreak(
        defaults: UserDefaults = .standard
    ) -> Int {
        max(
            0,
            defaults.integer(forKey: fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey)
        )
    }

    private func launchRescueFollowupCoachLastAutoRecoveryChecklistAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        Self.launchRescueAutoTriggerAt(
            defaults.object(forKey: fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey)
        )
    }

    private func setLaunchRescueFollowupCoachLastAutoRecoveryChecklistAt(
        _ date: Date?,
        defaults: UserDefaults = .standard
    ) {
        guard let date else {
            defaults.removeObject(forKey: fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey)
            return
        }
        defaults.set(
            date.timeIntervalSince1970,
            forKey: fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
        )
    }

    private func launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
        defaults: UserDefaults = .standard
    ) -> Int {
        let storedMinutes: Int
        if defaults.object(forKey: fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey) != nil {
            storedMinutes = defaults.integer(
                forKey: fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
            )
        } else {
            storedMinutes = AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes
        }
        return AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                storedMinutes
            )
    }

    private func setLaunchRescueFollowupRecoveryChecklistAutoCooldownMinutes(
        _ minutes: Int,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(
            AppDefaults
                .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                    minutes
                ),
            forKey: fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
        )
    }

    private func launchRescueFollowupRecoveryChecklistAutoCooldown(
        defaults: UserDefaults = .standard
    ) -> TimeInterval {
        TimeInterval(
            max(
                0,
                launchRescueFollowupRecoveryChecklistAutoCooldownMinutes(defaults: defaults)
            ) * 60
        )
    }

    private func launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Int? {
        Self.launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
            lastAutoRecoveryChecklistAt: launchRescueFollowupCoachLastAutoRecoveryChecklistAt(
                defaults: defaults
            ),
            now: now,
            cooldown: launchRescueFollowupRecoveryChecklistAutoCooldown(defaults: defaults)
        )
    }

    @discardableResult
    private func updateLaunchRescueFollowupCoachState(
        lane: LaunchRescueFollowupCoachLane,
        defaults: UserDefaults = .standard
    ) -> Int {
        let nextRecoveryLaneStreak = Self.launchRescueFollowupCoachRecoveryLaneStreakNext(
            currentStreak: launchRescueFollowupCoachRecoveryLaneStreak(defaults: defaults),
            lane: lane
        )
        defaults.set(
            nextRecoveryLaneStreak,
            forKey: fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
        )
        return nextRecoveryLaneStreak
    }

    nonisolated static func fameExceptionalLoopOutcomeCommandHistory(
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
    ) -> [FameExceptionalLoopOutcomeCommandSample] {
        guard let data = defaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode(
                  [FameExceptionalLoopOutcomeCommandSample].self,
                  from: data
              ) else {
            return []
        }

        return decoded
            .filter { sample in
                sample.recordedAt > 0
                    && !sample.commandToken
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
            }
            .sorted { $0.recordedAt < $1.recordedAt }
    }

    nonisolated static func fameExceptionalLoopOutcomeCommandHistoryWindow(
        _ history: [FameExceptionalLoopOutcomeCommandSample],
        now: Date = Date(),
        maxSamples: Int = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryMaxSamples,
        windowDays: Int = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryWindowDays
    ) -> [FameExceptionalLoopOutcomeCommandSample] {
        let normalizedMaxSamples = max(1, maxSamples)
        let windowDays = max(1, windowDays)
        let window = TimeInterval(windowDays * 24 * 60 * 60)
        let cutoff = now.addingTimeInterval(-window).timeIntervalSince1970
        let filtered = history.filter { $0.recordedAt >= cutoff }
        guard filtered.count > normalizedMaxSamples else {
            return filtered
        }
        return Array(filtered.suffix(normalizedMaxSamples))
    }

    nonisolated static func fameExceptionalLoopOutcomeCommandScoreboard(
        commandToken: String,
        history: [FameExceptionalLoopOutcomeCommandSample]
    ) -> FameExceptionalLoopOutcomeScoreboard? {
        let normalizedCommandToken = ActivityLogCommand.safeID(commandToken)
        guard !normalizedCommandToken.isEmpty else { return nil }
        let commandHistory = history.filter { $0.commandToken == normalizedCommandToken }
        guard !commandHistory.isEmpty else { return nil }

        let attempts = commandHistory.count
        let successes = commandHistory.filter(\.wasSuccess).count
        let successRate = attempts > 0
            ? Int((Double(successes) / Double(attempts) * 100).rounded())
            : 0

        var successStreak = 0
        var failureStreak = 0
        for sample in commandHistory.reversed() {
            if sample.wasSuccess {
                guard failureStreak == 0 else { break }
                successStreak += 1
            } else {
                guard successStreak == 0 else { break }
                failureStreak += 1
            }
        }

        let lastOutcomeAt = commandHistory.last.map { Date(timeIntervalSince1970: $0.recordedAt) }
        return FameExceptionalLoopOutcomeScoreboard(
            attempts: attempts,
            successes: successes,
            successRate: max(0, min(100, successRate)),
            successStreak: successStreak,
            failureStreak: failureStreak,
            lastFocusToken: normalizedCommandToken,
            lastOutcomeAt: lastOutcomeAt
        )
    }

    nonisolated static func fameExceptionalLoopOutcomeScoreboard(
        defaults: UserDefaults = .standard,
        totalCountKey: String = AppDefaults.fameExceptionalLoopOutcomeTotalCountKey,
        successCountKey: String = AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey,
        successStreakKey: String = AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey,
        failureStreakKey: String = AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey,
        lastFocusTokenKey: String = AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey,
        lastAtKey: String = AppDefaults.fameExceptionalLoopOutcomeLastAtKey
    ) -> FameExceptionalLoopOutcomeScoreboard {
        let attempts = max(0, defaults.integer(forKey: totalCountKey))
        let successes = min(
            attempts,
            max(0, defaults.integer(forKey: successCountKey))
        )
        let successRate = attempts > 0
            ? Int((Double(successes) / Double(attempts) * 100).rounded())
            : 0
        let successStreak = max(0, defaults.integer(forKey: successStreakKey))
        let failureStreak = max(0, defaults.integer(forKey: failureStreakKey))
        let lastFocusToken = defaults.string(forKey: lastFocusTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLastFocusToken = lastFocusToken?.isEmpty == true ? nil : lastFocusToken
        let lastOutcomeAt: Date?
        if defaults.object(forKey: lastAtKey) != nil {
            let stamp = defaults.double(forKey: lastAtKey)
            lastOutcomeAt = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
        } else {
            lastOutcomeAt = nil
        }
        return FameExceptionalLoopOutcomeScoreboard(
            attempts: attempts,
            successes: successes,
            successRate: max(0, min(100, successRate)),
            successStreak: successStreak,
            failureStreak: failureStreak,
            lastFocusToken: normalizedLastFocusToken,
            lastOutcomeAt: lastOutcomeAt
        )
    }

    private static func setFameExceptionalLoopOutcomeCommandHistory(
        _ history: [FameExceptionalLoopOutcomeCommandSample],
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey
    ) {
        guard !history.isEmpty else {
            defaults.removeObject(forKey: historyKey)
            return
        }
        guard let encodedHistory = try? JSONEncoder().encode(history) else { return }
        defaults.set(encodedHistory, forKey: historyKey)
    }

    private func fameExceptionalLoopOutcomeLastAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: fameExceptionalLoopOutcomeLastAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: fameExceptionalLoopOutcomeLastAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func fameExceptionalLoopOutcomeScoreboard(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopOutcomeScoreboard {
        Self.fameExceptionalLoopOutcomeScoreboard(
            defaults: defaults,
            totalCountKey: fameExceptionalLoopOutcomeTotalCountKey,
            successCountKey: fameExceptionalLoopOutcomeSuccessCountKey,
            successStreakKey: fameExceptionalLoopOutcomeSuccessStreakKey,
            failureStreakKey: fameExceptionalLoopOutcomeFailureStreakKey,
            lastFocusTokenKey: fameExceptionalLoopOutcomeLastFocusTokenKey,
            lastAtKey: fameExceptionalLoopOutcomeLastAtKey
        )
    }

    private func fameExceptionalLoopOutcomeScoreboard(
        forCommandToken commandToken: String,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopOutcomeScoreboard? {
        let history = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let windowedHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(history, now: now)
        if history != windowedHistory {
            Self.setFameExceptionalLoopOutcomeCommandHistory(
                windowedHistory,
                defaults: defaults,
                historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
            )
        }
        return Self.fameExceptionalLoopOutcomeCommandScoreboard(
            commandToken: commandToken,
            history: windowedHistory
        )
    }

    @discardableResult
    private func recordFameExceptionalLoopOutcome(
        plan: FameExceptionalLoopPlan,
        wasSuccessful: Bool,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> FameExceptionalLoopOutcomeScoreboard {
        let attempts = max(0, defaults.integer(forKey: fameExceptionalLoopOutcomeTotalCountKey)) + 1
        let successes = min(
            attempts,
            max(0, defaults.integer(forKey: fameExceptionalLoopOutcomeSuccessCountKey))
                + (wasSuccessful ? 1 : 0)
        )
        let nextSuccessStreak = wasSuccessful
            ? max(0, defaults.integer(forKey: fameExceptionalLoopOutcomeSuccessStreakKey)) + 1
            : 0
        let nextFailureStreak = wasSuccessful
            ? 0
            : max(0, defaults.integer(forKey: fameExceptionalLoopOutcomeFailureStreakKey)) + 1
        let focusToken = Self.fameExceptionalLoopOutcomeFocusToken(plan)

        defaults.set(attempts, forKey: fameExceptionalLoopOutcomeTotalCountKey)
        defaults.set(successes, forKey: fameExceptionalLoopOutcomeSuccessCountKey)
        defaults.set(nextSuccessStreak, forKey: fameExceptionalLoopOutcomeSuccessStreakKey)
        defaults.set(nextFailureStreak, forKey: fameExceptionalLoopOutcomeFailureStreakKey)
        defaults.set(focusToken, forKey: fameExceptionalLoopOutcomeLastFocusTokenKey)
        defaults.set(now.timeIntervalSince1970, forKey: fameExceptionalLoopOutcomeLastAtKey)
        let currentCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistory(
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )
        let nextCommandHistory = Self.fameExceptionalLoopOutcomeCommandHistoryWindow(
            currentCommandHistory + [
                FameExceptionalLoopOutcomeCommandSample(
                    commandToken: focusToken,
                    recordedAt: now.timeIntervalSince1970,
                    wasSuccess: wasSuccessful
                )
            ],
            now: now
        )
        Self.setFameExceptionalLoopOutcomeCommandHistory(
            nextCommandHistory,
            defaults: defaults,
            historyKey: fameExceptionalLoopOutcomeCommandHistoryKey
        )

        return fameExceptionalLoopOutcomeScoreboard(now: now, defaults: defaults)
    }

    private func fameExceptionalLoopCommandSucceeded(
        _ commandID: String,
        now: Date = Date()
    ) -> Bool {
        switch commandID {
        case "run-fame-launch-rescue-followup-now":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestLaunchRescueBurstURL() },
                now: now
            ) || hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestNextMoveHandoffURL() },
                now: now
            ) || hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestNextMoveDraftPackURL() },
                now: now
            ) || hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestLaunchControlBriefURL() },
                now: now
            ) || hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestRecoveryChecklistURL() },
                now: now
            )
        case "run-fame-launch-control-hub":
            let freshCount = [
                hasFreshLaunchRescueAutoFollowupArtifact(
                    latestURL: { try FameSnapshotArchive.latestLaunchControlBriefURL() },
                    now: now
                ),
                hasFreshLaunchRescueAutoFollowupArtifact(
                    latestURL: { try FameSnapshotArchive.latestLaunchRescueSnapshotURL() },
                    now: now
                ),
                hasFreshLaunchRescueAutoFollowupArtifact(
                    latestURL: { try FameSnapshotArchive.latestLaunchRescueBurstURL() },
                    now: now
                ),
                hasFreshLaunchRescueAutoFollowupArtifact(
                    latestURL: { try FameSnapshotArchive.latestLaunchCountdownURL() },
                    now: now
                )
            ].filter { $0 }.count
            return freshCount >= 2
        case "run-fame-command-center":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestCommandCenterURL() },
                now: now
            )
        case "run-fame-spotlight-pack":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestSpotlightPackURL() },
                now: now
            )
        case "run-fame-next-move-cadence-execution-kit",
             "run-fame-cadence-autopilot-loop":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestNextMoveHandoffURL() },
                now: now
            )
        case "run-fame-next-move-copy-drafts":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestNextMoveDraftPackURL() },
                now: now
            )
        case "copy-fame-launch-control-brief":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestLaunchControlBriefURL() },
                now: now
            )
        case "copy-fame-launch-rescue-snapshot":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestLaunchRescueSnapshotURL() },
                now: now
            )
        case "copy-fame-cadence-share-line":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestCadenceShareLineURL() },
                now: now
            )
        case "copy-fame-cadence-share-pack":
            return hasFreshLaunchRescueAutoFollowupArtifact(
                latestURL: { try FameSnapshotArchive.latestCadenceSharePackURL() },
                now: now
            )
        default:
            return true
        }
    }

    private func launchRescueFollowupOutcomeScoreboard(
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> LaunchRescueFollowupOutcomeScoreboard {
        Self.launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults,
            totalCountKey: fameLaunchRescueBurstFollowupOutcomeTotalCountKey,
            successCountKey: fameLaunchRescueBurstFollowupOutcomeSuccessCountKey,
            lastOutcomeAtKey: fameLaunchRescueBurstFollowupOutcomeLastAtKey,
            lastSuccessAtKey: fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey,
            lastFailureAtKey: fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey,
            historyKey: fameLaunchRescueBurstFollowupOutcomeHistoryKey,
            historyWindowHours: AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryWindowHours
        )
    }

    @discardableResult
    private func recordLaunchRescueFollowupOutcome(
        wasSuccessful: Bool,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> LaunchRescueFollowupOutcomeScoreboard {
        let nextAttempts = max(
            0,
            defaults.integer(forKey: fameLaunchRescueBurstFollowupOutcomeTotalCountKey)
        ) + 1
        let nextSuccesses = min(
            nextAttempts,
            max(
                0,
                defaults.integer(forKey: fameLaunchRescueBurstFollowupOutcomeSuccessCountKey)
            ) + (wasSuccessful ? 1 : 0)
        )

        defaults.set(nextAttempts, forKey: fameLaunchRescueBurstFollowupOutcomeTotalCountKey)
        defaults.set(nextSuccesses, forKey: fameLaunchRescueBurstFollowupOutcomeSuccessCountKey)
        defaults.set(
            now.timeIntervalSince1970,
            forKey: fameLaunchRescueBurstFollowupOutcomeLastAtKey
        )
        if wasSuccessful {
            defaults.set(
                now.timeIntervalSince1970,
                forKey: fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey
            )
        } else {
            defaults.set(
                now.timeIntervalSince1970,
                forKey: fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey
            )
        }

        var history = Self.launchRescueFollowupOutcomeHistory(
            defaults: defaults,
            historyKey: fameLaunchRescueBurstFollowupOutcomeHistoryKey
        )
        history.append(
            LaunchRescueFollowupOutcomeSample(
                recordedAt: now.timeIntervalSince1970,
                wasSuccess: wasSuccessful
            )
        )
        history = Self.launchRescueFollowupOutcomeWindow(
            history,
            now: now,
            windowHours: AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryWindowHours
        )
        if let encodedHistory = try? JSONEncoder().encode(history) {
            defaults.set(
                encodedHistory,
                forKey: fameLaunchRescueBurstFollowupOutcomeHistoryKey
            )
        }

        return launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults
        )
    }

    private func setFameLaunchRescueBurstLastRunAt(
        _ date: Date,
        defaults: UserDefaults = .standard
    ) {
        defaults.set(date.timeIntervalSince1970, forKey: fameLaunchRescueBurstLastRunAtKey)
        updateLaunchRescueAutoMenuStatus(now: date)
    }

    private func autoOpsBundleLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: fameAutoOpsBundleLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: fameAutoOpsBundleLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func setAutoOpsBundleLastRunAt(_ date: Date, defaults: UserDefaults = .standard) {
        defaults.set(date.timeIntervalSince1970, forKey: fameAutoOpsBundleLastRunAtKey)
        updateAutoOpsBundleMenuStatus(now: date)
    }

    private func flashStatus(symbol: String, tint: NSColor, length: TimeInterval) {
        statusFlashTask?.cancel()

        setStatusButton(symbol: symbol, tint: tint)

        statusFlashTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(length * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.statusFlashTask = nil
                self.setStatusButton(symbol: self.statusBaseSymbol, tint: self.statusBaseTint)
            }
        }
    }
}
