import Foundation

struct SupportInfoReport: Equatable {
    let appVersion: String
    let macOSVersion: String
    let ocrLanguage: String
    let llmEnabled: Bool
    let llmProvider: String
    let llmModel: String
    let apiKeySet: Bool
    let readAfterPick: Bool
    let autoCopyNewText: Bool
    let autoPastePickedText: Bool
    let autoPasteLLMAnswers: Bool
    let saveRecentItems: Bool
    let saveClipboardHistory: Bool
    let readerAlwaysOnTop: Bool
    let launchAtLoginState: LaunchAtLoginState
    let screenRecordingAllowed: Bool
    let accessibilityTrusted: Bool
    let recentItemCount: Int
    let snippetItemCount: Int
    let quickLinkItemCount: Int
    let clipboardHistoryItemCount: Int
    let activityLogItemCount: Int
    let hasReaderText: Bool
    let hasReaderImage: Bool
    let hasAnswer: Bool
    let hasError: Bool
    let bestChannelLaunchPackPressureOpportunities: Int
    let bestChannelLaunchPackPressureConversions: Int
    let bestChannelLaunchPackPressureConversionStreak: Int
    let bestChannelLaunchPackPressureBestStreak: Int
    let bestChannelLaunchPackPressureLastTone: String
    let bestChannelLaunchPackPressureModeTransitionCount: Int
    let bestChannelLaunchPackPressureModeTransitionLatest: String
    let bestChannelLaunchPackPressureModeMomentumStreak: Int
    let fameExceptionalLoopOutcomeSummary: String
    let fameExceptionalLoopOutcomeStatusTitle: String
    let fameExceptionalLoopTopWinLaneSummary: String
    let fameExceptionalLoopTopRecoveryLaneSummary: String
    let fameExceptionalLoopRecoveryNextActionSummary: String
    let fameExceptionalLoopAutoRecoveryLaneStatusSummary: String
    let fameExceptionalLoopAutoRecoveryLaneMissesRequired: Int
    let fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired: Int
    let fameExceptionalLoopAutoRecoveryLaneCooldownMinutes: Int
    let fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary: String
    let launchRescueBurstLastAutoTriggerReason: String
    let launchRescueBurstLastAutoTriggerAt: Date?
    let launchRescueBurstLastFollowupReason: String
    let launchRescueBurstLastFollowupCommandID: String
    let launchRescueBurstLastFollowupAt: Date?
    let launchRescueFollowupRouteDecisionStatusTitle: String
    let launchRescueAutoSelfHealStatusTitle: String
    let launchRescueFollowupOutcomeScoreboardStatusTitle: String
    let launchRescueFollowupOutcomeCoachStatusTitle: String
    let launchRescueFollowupOutcomeMomentumStatusTitle: String

    init(
        appVersion: String,
        macOSVersion: String,
        ocrLanguage: String,
        llmEnabled: Bool,
        llmProvider: String,
        llmModel: String,
        apiKeySet: Bool,
        readAfterPick: Bool,
        autoCopyNewText: Bool,
        autoPastePickedText: Bool,
        autoPasteLLMAnswers: Bool,
        saveRecentItems: Bool,
        saveClipboardHistory: Bool,
        readerAlwaysOnTop: Bool,
        launchAtLoginState: LaunchAtLoginState,
        screenRecordingAllowed: Bool,
        accessibilityTrusted: Bool,
        recentItemCount: Int,
        snippetItemCount: Int,
        quickLinkItemCount: Int,
        clipboardHistoryItemCount: Int,
        activityLogItemCount: Int,
        hasReaderText: Bool,
        hasReaderImage: Bool,
        hasAnswer: Bool,
        hasError: Bool,
        bestChannelLaunchPackPressureOpportunities: Int = 0,
        bestChannelLaunchPackPressureConversions: Int = 0,
        bestChannelLaunchPackPressureConversionStreak: Int = 0,
        bestChannelLaunchPackPressureBestStreak: Int = 0,
        bestChannelLaunchPackPressureLastTone: String = "None",
        bestChannelLaunchPackPressureModeTransitionCount: Int = 0,
        bestChannelLaunchPackPressureModeTransitionLatest: String = "none-to-none",
        bestChannelLaunchPackPressureModeMomentumStreak: Int = 0,
        fameExceptionalLoopOutcomeSummary: String = "wins 0/0 (0%), win streak x0, recovery streak x0, last focus None, last run No auto trigger time recorded yet.",
        fameExceptionalLoopOutcomeStatusTitle: String = "Outcome trend: warming up.",
        fameExceptionalLoopTopWinLaneSummary: String = "none yet",
        fameExceptionalLoopTopRecoveryLaneSummary: String = "none yet",
        fameExceptionalLoopRecoveryNextActionSummary: String = "none yet",
        fameExceptionalLoopAutoRecoveryLaneStatusSummary: String = "Auto recovery lane: Not armed (no eligible lane telemetry yet).",
        fameExceptionalLoopAutoRecoveryLaneMissesRequired: Int =
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
        fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired: Int =
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
        fameExceptionalLoopAutoRecoveryLaneCooldownMinutes: Int =
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes,
        fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary: String =
            AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: nil,
                currentMissesRequired: AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
                currentFailureStreakRequired:
                    AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
                currentCooldownMinutes: AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            ),
        launchRescueBurstLastAutoTriggerReason: String = "none",
        launchRescueBurstLastAutoTriggerAt: Date? = nil,
        launchRescueBurstLastFollowupReason: String = "none",
        launchRescueBurstLastFollowupCommandID: String = "none",
        launchRescueBurstLastFollowupAt: Date? = nil,
        launchRescueFollowupRouteDecisionStatusTitle: String = "Launch Rescue Auto Follow-up Route Decision: Default route Run Launch Control Brief.",
        launchRescueAutoSelfHealStatusTitle: String = "Launch Rescue Auto Self-Heal: Waiting for auto trigger telemetry before artifact checks.",
        launchRescueFollowupOutcomeScoreboardStatusTitle: String = "Launch Rescue Follow-up Scoreboard: No follow-up outcomes recorded yet.",
        launchRescueFollowupOutcomeCoachStatusTitle: String = "Launch Rescue Follow-up Coach: Baseline mode · run follow-up to seed outcomes.",
        launchRescueFollowupOutcomeMomentumStatusTitle: String = "Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."
    ) {
        self.appVersion = appVersion
        self.macOSVersion = macOSVersion
        self.ocrLanguage = ocrLanguage
        self.llmEnabled = llmEnabled
        self.llmProvider = llmProvider
        self.llmModel = llmModel
        self.apiKeySet = apiKeySet
        self.readAfterPick = readAfterPick
        self.autoCopyNewText = autoCopyNewText
        self.autoPastePickedText = autoPastePickedText
        self.autoPasteLLMAnswers = autoPasteLLMAnswers
        self.saveRecentItems = saveRecentItems
        self.saveClipboardHistory = saveClipboardHistory
        self.readerAlwaysOnTop = readerAlwaysOnTop
        self.launchAtLoginState = launchAtLoginState
        self.screenRecordingAllowed = screenRecordingAllowed
        self.accessibilityTrusted = accessibilityTrusted
        self.recentItemCount = recentItemCount
        self.snippetItemCount = snippetItemCount
        self.quickLinkItemCount = quickLinkItemCount
        self.clipboardHistoryItemCount = clipboardHistoryItemCount
        self.activityLogItemCount = activityLogItemCount
        self.hasReaderText = hasReaderText
        self.hasReaderImage = hasReaderImage
        self.hasAnswer = hasAnswer
        self.hasError = hasError
        self.bestChannelLaunchPackPressureOpportunities = bestChannelLaunchPackPressureOpportunities
        self.bestChannelLaunchPackPressureConversions = bestChannelLaunchPackPressureConversions
        self.bestChannelLaunchPackPressureConversionStreak = bestChannelLaunchPackPressureConversionStreak
        self.bestChannelLaunchPackPressureBestStreak = bestChannelLaunchPackPressureBestStreak
        self.bestChannelLaunchPackPressureLastTone = bestChannelLaunchPackPressureLastTone
        self.bestChannelLaunchPackPressureModeTransitionCount = bestChannelLaunchPackPressureModeTransitionCount
        self.bestChannelLaunchPackPressureModeTransitionLatest = bestChannelLaunchPackPressureModeTransitionLatest
        self.bestChannelLaunchPackPressureModeMomentumStreak = bestChannelLaunchPackPressureModeMomentumStreak
        self.fameExceptionalLoopOutcomeSummary = fameExceptionalLoopOutcomeSummary
        self.fameExceptionalLoopOutcomeStatusTitle = fameExceptionalLoopOutcomeStatusTitle
        self.fameExceptionalLoopTopWinLaneSummary = fameExceptionalLoopTopWinLaneSummary
        self.fameExceptionalLoopTopRecoveryLaneSummary = fameExceptionalLoopTopRecoveryLaneSummary
        self.fameExceptionalLoopRecoveryNextActionSummary = fameExceptionalLoopRecoveryNextActionSummary
        self.fameExceptionalLoopAutoRecoveryLaneStatusSummary = fameExceptionalLoopAutoRecoveryLaneStatusSummary
        self.fameExceptionalLoopAutoRecoveryLaneMissesRequired =
            fameExceptionalLoopAutoRecoveryLaneMissesRequired
        self.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
            fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        self.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes =
            fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        self.fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary =
            fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary
        self.launchRescueBurstLastAutoTriggerReason = launchRescueBurstLastAutoTriggerReason
        self.launchRescueBurstLastAutoTriggerAt = launchRescueBurstLastAutoTriggerAt
        self.launchRescueBurstLastFollowupReason = launchRescueBurstLastFollowupReason
        self.launchRescueBurstLastFollowupCommandID = launchRescueBurstLastFollowupCommandID
        self.launchRescueBurstLastFollowupAt = launchRescueBurstLastFollowupAt
        self.launchRescueFollowupRouteDecisionStatusTitle = launchRescueFollowupRouteDecisionStatusTitle
        self.launchRescueAutoSelfHealStatusTitle = launchRescueAutoSelfHealStatusTitle
        self.launchRescueFollowupOutcomeScoreboardStatusTitle = launchRescueFollowupOutcomeScoreboardStatusTitle
        self.launchRescueFollowupOutcomeCoachStatusTitle = launchRescueFollowupOutcomeCoachStatusTitle
        self.launchRescueFollowupOutcomeMomentumStatusTitle = launchRescueFollowupOutcomeMomentumStatusTitle
    }

    @MainActor
    static func make(
        settings: SettingsStore,
        state: ReaderState,
        quickLinkItemCount: Int = 0,
        clipboardHistoryItemCount: Int = 0,
        activityLogItemCount: Int = 0,
        defaults: UserDefaults = .standard
    ) -> SupportInfoReport {
        let pressureOpportunities = max(
            0,
            defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureOpportunitiesKey)
        )
        let pressureConversions = min(
            pressureOpportunities,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureConversionsKey)
            )
        )
        let pressureStreak = min(
            pressureConversions,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureConversionStreakKey)
            )
        )
        let pressureBestStreak = max(
            pressureStreak,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureBestStreakKey)
            )
        )
        let pressureTone = bestChannelLaunchPackPressureToneTitle(
            defaults.string(forKey: AppDefaults.fameBestChannelLaunchPackPressureLastToneKey)
        )
        let pressureModeTransitionCount = max(
            0,
            defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey)
        )
        let pressureModeTransitionLatest = bestChannelLaunchPackPressureModeTransitionLatestToken(
            defaults.string(forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey)
        )
        let pressureModeMomentumStreak = defaults.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        let launchRescueBurstAutoTriggerReason = launchRescueBurstAutoTriggerReasonToken(
            defaults.string(forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey)
        )
        let launchRescueBurstAutoTriggerAt = AppDelegate.launchRescueAutoTriggerAt(
            defaults.object(forKey: AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey)
        )
        let launchRescueBurstLastFollowupReason = launchRescueBurstAutoTriggerReasonToken(
            defaults.string(forKey: AppDefaults.fameLaunchRescueBurstLastFollowupReasonKey)
        )
        let launchRescueBurstLastFollowupCommandID = AppDelegate.launchRescueAutoFollowupCommandID(
            defaults.string(forKey: AppDefaults.fameLaunchRescueBurstLastFollowupCommandIDKey)
        )
        let launchRescueBurstLastFollowupAt = AppDelegate.launchRescueAutoTriggerAt(
            defaults.object(forKey: AppDefaults.fameLaunchRescueBurstLastFollowupAtKey)
        )
        let now = Date()
        let activityItems = ActivityLogStore(defaults: defaults).items
        let launchRescueFollowupOutcomeScoreboard = AppDelegate.launchRescueFollowupOutcomeScoreboard(
            now: now,
            defaults: defaults
        )
        let launchRescueFollowupCoachRecoveryLaneStreak = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey
            )
        )
        let launchRescueFollowupCoachLastAutoRecoveryChecklistAt = AppDelegate
            .launchRescueAutoTriggerAt(
                defaults.object(
                    forKey: AppDefaults.fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey
                )
            )
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutes = AppDefaults
            .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                defaults.object(
                    forKey: AppDefaults
                        .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
                ) != nil
                    ? defaults.integer(
                        forKey: AppDefaults
                            .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey
                    )
                    : AppDefaults
                        .fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes
            )
        let launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining = AppDelegate
            .launchRescueFollowupRecoveryChecklistCooldownMinutesRemaining(
                lastAutoRecoveryChecklistAt: launchRescueFollowupCoachLastAutoRecoveryChecklistAt,
                now: now,
                cooldown: TimeInterval(launchRescueFollowupCoachRecoveryChecklistCooldownMinutes * 60)
            )
        let fameExceptionalLoopOutcomeAttempts = max(
            0,
            defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeTotalCountKey)
        )
        let fameExceptionalLoopOutcomeSuccesses = min(
            fameExceptionalLoopOutcomeAttempts,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey)
            )
        )
        let fameExceptionalLoopOutcomeSuccessRate = fameExceptionalLoopOutcomeAttempts > 0
            ? Int(
                (
                    Double(fameExceptionalLoopOutcomeSuccesses)
                        / Double(fameExceptionalLoopOutcomeAttempts)
                        * 100
                ).rounded()
            )
            : 0
        let fameExceptionalLoopOutcomeLastFocusToken = defaults
            .string(forKey: AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fameExceptionalLoopOutcomeScoreboard = AppDelegate.FameExceptionalLoopOutcomeScoreboard(
            attempts: fameExceptionalLoopOutcomeAttempts,
            successes: fameExceptionalLoopOutcomeSuccesses,
            successRate: max(0, min(100, fameExceptionalLoopOutcomeSuccessRate)),
            successStreak: max(
                0,
                defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey)
            ),
            failureStreak: max(
                0,
                defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey)
            ),
            lastFocusToken: fameExceptionalLoopOutcomeLastFocusToken?.isEmpty == true
                ? nil
                : fameExceptionalLoopOutcomeLastFocusToken,
            lastOutcomeAt: AppDelegate.launchRescueAutoTriggerAt(
                defaults.object(forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey)
            )
        )
        let fameExceptionalLoopOutcomeCommandHistory = AppDelegate
            .fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let fameExceptionalLoopOutcomeWindowedCommandHistory = AppDelegate
            .fameExceptionalLoopOutcomeCommandHistoryWindow(
                fameExceptionalLoopOutcomeCommandHistory,
                now: now
            )
        let fameExceptionalLoopOutcomeLaneSummaries = AppDelegate
            .fameExceptionalLoopOutcomeLaneSummaries(
                history: fameExceptionalLoopOutcomeWindowedCommandHistory
            )
        let fameExceptionalLoopTopRecoveryLaneScoreboard = AppDelegate
            .fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
                history: fameExceptionalLoopOutcomeWindowedCommandHistory
            )
        let fameExceptionalLoopAutoRecoveryLaneMissesRequired = AppDefaults
            .normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
            )
        let fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = AppDefaults
            .normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
            )
        let fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = AppDefaults
            .normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            )
        let fameExceptionalLoopRecoveryLaneAutoRunLastAt = AppDelegate.launchRescueAutoTriggerAt(
            defaults.object(forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey)
        )
        let fameExceptionalLoopAutoRecoveryLaneStatusSummary = AppDelegate
            .fameExceptionalLoopAutoRecoveryLaneStatusSummary(
                topRecoveryLane: fameExceptionalLoopTopRecoveryLaneScoreboard,
                lastAutoRunAt: fameExceptionalLoopRecoveryLaneAutoRunLastAt,
                now: now,
                missesRequired: fameExceptionalLoopAutoRecoveryLaneMissesRequired,
                failureStreakRequired: fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
                cooldown: TimeInterval(fameExceptionalLoopAutoRecoveryLaneCooldownMinutes * 60)
            )
        let fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary = AppDelegate
            .fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: AppDelegate
                    .fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                        topRecoveryLane: fameExceptionalLoopTopRecoveryLaneScoreboard
                    ),
                currentMissesRequired: fameExceptionalLoopAutoRecoveryLaneMissesRequired,
                currentFailureStreakRequired: fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
                currentCooldownMinutes: fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            )

        return SupportInfoReport(
            appVersion: appVersion(),
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            ocrLanguage: value(settings.ocrLanguageCode, fallback: "Auto"),
            llmEnabled: settings.llmEnabled,
            llmProvider: LLMProvider.normalized(settings.llmProvider).title,
            llmModel: value(settings.llmModel, fallback: "Default"),
            apiKeySet: !settings.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            readAfterPick: settings.readAfterPick,
            autoCopyNewText: settings.autoCopyNewText,
            autoPastePickedText: settings.autoPastePickedText,
            autoPasteLLMAnswers: settings.autoPasteLLMAnswers,
            saveRecentItems: settings.saveRecentItems,
            saveClipboardHistory: settings.saveClipboardHistory,
            readerAlwaysOnTop: settings.readerAlwaysOnTop,
            launchAtLoginState: LaunchAtLoginManager.state,
            screenRecordingAllowed: PermissionStatus.screenRecordingAllowed(),
            accessibilityTrusted: PermissionStatus.accessibilityTrusted(),
            recentItemCount: state.recentItems.count,
            snippetItemCount: state.snippets.count,
            quickLinkItemCount: quickLinkItemCount,
            clipboardHistoryItemCount: clipboardHistoryItemCount,
            activityLogItemCount: activityLogItemCount,
            hasReaderText: !state.lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasReaderImage: state.lastImageData != nil,
            hasAnswer: !state.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasError: !state.errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            bestChannelLaunchPackPressureOpportunities: pressureOpportunities,
            bestChannelLaunchPackPressureConversions: pressureConversions,
            bestChannelLaunchPackPressureConversionStreak: pressureStreak,
            bestChannelLaunchPackPressureBestStreak: pressureBestStreak,
            bestChannelLaunchPackPressureLastTone: pressureTone,
            bestChannelLaunchPackPressureModeTransitionCount: pressureModeTransitionCount,
            bestChannelLaunchPackPressureModeTransitionLatest: pressureModeTransitionLatest,
            bestChannelLaunchPackPressureModeMomentumStreak: pressureModeMomentumStreak,
            fameExceptionalLoopOutcomeSummary: Self.fameExceptionalLoopOutcomeSummary(
                fameExceptionalLoopOutcomeScoreboard
            ),
            fameExceptionalLoopOutcomeStatusTitle: AppDelegate.fameExceptionalLoopOutcomeStatusTitle(
                fameExceptionalLoopOutcomeScoreboard
            ),
            fameExceptionalLoopTopWinLaneSummary: fameExceptionalLoopOutcomeLaneSummaries.topWinLane,
            fameExceptionalLoopTopRecoveryLaneSummary:
                fameExceptionalLoopOutcomeLaneSummaries.topRecoveryLane,
            fameExceptionalLoopRecoveryNextActionSummary: AppDelegate
                .fameExceptionalLoopRecoveryLaneActionSummary(
                    fameExceptionalLoopTopRecoveryLaneScoreboard
                ),
            fameExceptionalLoopAutoRecoveryLaneStatusSummary:
                fameExceptionalLoopAutoRecoveryLaneStatusSummary,
            fameExceptionalLoopAutoRecoveryLaneMissesRequired:
                fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired:
                fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            fameExceptionalLoopAutoRecoveryLaneCooldownMinutes:
                fameExceptionalLoopAutoRecoveryLaneCooldownMinutes,
            fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary:
                fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary,
            launchRescueBurstLastAutoTriggerReason: launchRescueBurstAutoTriggerReason,
            launchRescueBurstLastAutoTriggerAt: launchRescueBurstAutoTriggerAt,
            launchRescueBurstLastFollowupReason: launchRescueBurstLastFollowupReason,
            launchRescueBurstLastFollowupCommandID: launchRescueBurstLastFollowupCommandID,
            launchRescueBurstLastFollowupAt: launchRescueBurstLastFollowupAt,
            launchRescueFollowupRouteDecisionStatusTitle: AppDelegate
                .launchRescueAutoFollowupRouteDecisionStatusTitle(
                    triggerReason: launchRescueBurstAutoTriggerReason,
                    lastAutoTriggerAt: launchRescueBurstAutoTriggerAt,
                    activityItems: activityItems,
                    now: now
                ),
            launchRescueAutoSelfHealStatusTitle: AppDelegate
                .launchRescueAutoFollowupSelfHealArtifactStatusTitle(
                    triggerReason: launchRescueBurstAutoTriggerReason,
                    activityItems: activityItems,
                    now: now
                ),
            launchRescueFollowupOutcomeScoreboardStatusTitle: AppDelegate
                .launchRescueFollowupOutcomeScoreboardStatusTitle(
                    launchRescueFollowupOutcomeScoreboard,
                    now: now
                ),
            launchRescueFollowupOutcomeCoachStatusTitle: AppDelegate
                .launchRescueFollowupOutcomeCoachStatusTitle(
                    launchRescueFollowupOutcomeScoreboard,
                    triggerReason: launchRescueBurstAutoTriggerReason,
                    recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
                    recoveryChecklistCooldownMinutes:
                        launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
                    recoveryChecklistCooldownMinutesRemaining:
                        launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining,
                    now: now
                ),
            launchRescueFollowupOutcomeMomentumStatusTitle: AppDelegate
                .launchRescueFollowupMomentumStatusTitle(
                    launchRescueFollowupOutcomeScoreboard,
                    recoveryLaneStreak: launchRescueFollowupCoachRecoveryLaneStreak,
                    recoveryChecklistCooldownMinutes:
                        launchRescueFollowupCoachRecoveryChecklistCooldownMinutes,
                    recoveryChecklistCooldownMinutesRemaining:
                        launchRescueFollowupCoachRecoveryChecklistCooldownMinutesRemaining
                ) ?? "Launch Rescue Follow-up Momentum: Baseline mode · run follow-up to seed momentum trend."
        )
    }

    func launchRescueSnapshotMarkdown() -> String {
        AppDelegate.launchRescueSnapshotMarkdown(
            autoTriggerSummary: launchRescueBurstAutoTriggerSummary,
            autoTriggerAtSummary: launchRescueBurstAutoTriggerAtSummary,
            autoFollowupSummary: launchRescueBurstAutoFollowupSummary,
            autoFollowupAtSummary: launchRescueBurstAutoFollowupAtSummary,
            followupRouteDecisionStatusTitle: launchRescueFollowupRouteDecisionStatusTitle,
            autoSelfHealStatusTitle: launchRescueAutoSelfHealStatusTitle,
            followupScoreboardStatusTitle: launchRescueFollowupOutcomeScoreboardStatusTitle,
            followupCoachStatusTitle: launchRescueFollowupOutcomeCoachStatusTitle,
            followupMomentumStatusTitle: launchRescueFollowupOutcomeMomentumStatusTitle
        )
    }

    func markdown() -> String {
        """
        # Fluid Reader Support Info

        No API keys or private content.

        - Version: \(appVersion)
        - macOS: \(macOSVersion)
        - Screen Recording: \(yesNo(screenRecordingAllowed))
        - Accessibility: \(yesNo(accessibilityTrusted))
        - Reader: text \(yesNo(hasReaderText)), image \(yesNo(hasReaderImage)), answer \(yesNo(hasAnswer)), error \(yesNo(hasError))
        - Counts: recent \(recentItemCount), snippets \(snippetItemCount), links \(quickLinkItemCount), clipboard \(clipboardHistoryItemCount), log \(activityLogItemCount)
        - OCR: \(ocrLanguage)
        - LLM: \(yesNo(llmEnabled)), \(llmProvider), \(llmModel), key \(yesNo(apiKeySet))
        - Flow: read \(yesNo(readAfterPick)), copy \(yesNo(autoCopyNewText)), paste pick \(yesNo(autoPastePickedText)), paste answer \(yesNo(autoPasteLLMAnswers))
        - Saved: recent \(yesNo(saveRecentItems)), clipboard \(yesNo(saveClipboardHistory)), pinned \(yesNo(readerAlwaysOnTop))
        - Launch Pack Pressure: wins \(bestChannelLaunchPackPressureConversions)/\(bestChannelLaunchPackPressureOpportunities) (\(bestChannelLaunchPackPressureWinRate)%), streak x\(bestChannelLaunchPackPressureConversionStreak), best x\(bestChannelLaunchPackPressureBestStreak), tone \(bestChannelLaunchPackPressureLastTone)
        - Launch Pack Trend: \(bestChannelLaunchPackPressureTrendSummary)
        - Launch Pack Mode Shifts: \(bestChannelLaunchPackPressureModeShiftSummary)
        - Launch Pack Mode Momentum: \(bestChannelLaunchPackPressureModeMomentumSummary)
        - Exceptional Loop Outcomes: \(fameExceptionalLoopOutcomeSummary)
        - Exceptional Loop Trend: \(fameExceptionalLoopOutcomeStatusTitle)
        - Exceptional Loop Top Win Lane: \(fameExceptionalLoopTopWinLaneSummary)
        - Exceptional Loop Top Recovery Lane: \(fameExceptionalLoopTopRecoveryLaneSummary)
        - Exceptional Loop Recovery Next Action: \(fameExceptionalLoopRecoveryNextActionSummary)
        - Exceptional Loop Auto Recovery Lane: \(fameExceptionalLoopAutoRecoveryLaneStatusSummary)
        - Exceptional Loop Auto Recovery Tuning: arms at \(fameExceptionalLoopAutoRecoveryLaneMissesRequired)+ misses and streak x\(fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired), cooldown \(fameExceptionalLoopAutoRecoveryLaneCooldownMinutes)m
        - Exceptional Loop Auto Recovery Recommendation: \(fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary)
        - Launch Rescue Auto Trigger: \(launchRescueBurstAutoTriggerSummary)
        - Launch Rescue Auto Trigger Time: \(launchRescueBurstAutoTriggerAtSummary)
        - Launch Rescue Auto Follow-up: \(launchRescueBurstAutoFollowupSummary)
        - Launch Rescue Auto Follow-up Time: \(launchRescueBurstAutoFollowupAtSummary)
        - \(launchRescueFollowupRouteDecisionStatusTitle)
        - \(launchRescueAutoSelfHealStatusTitle)
        - \(launchRescueFollowupOutcomeScoreboardStatusTitle)
        - \(launchRescueFollowupOutcomeCoachStatusTitle)
        - \(launchRescueFollowupOutcomeMomentumStatusTitle)
        - Login: \(launchAtLoginState.title)
        """
    }

    private var bestChannelLaunchPackPressureWinRate: Int {
        guard bestChannelLaunchPackPressureOpportunities > 0 else { return 0 }
        return Int(
            (
                Double(bestChannelLaunchPackPressureConversions)
                    / Double(bestChannelLaunchPackPressureOpportunities)
                    * 100
            ).rounded()
        )
    }

    private var bestChannelLaunchPackPressureTrendSummary: String {
        guard bestChannelLaunchPackPressureOpportunities > 0 else {
            return "No opportunities yet; first pressure card starts baseline."
        }

        guard bestChannelLaunchPackPressureConversions > 0 else {
            return "No wins yet; first conversion starts streak."
        }

        if bestChannelLaunchPackPressureConversionStreak == 0 {
            let bestStreak = max(1, bestChannelLaunchPackPressureBestStreak)
            return "Cooling after last miss; recover toward best x\(bestStreak)."
        }

        if bestChannelLaunchPackPressureConversionStreak >= bestChannelLaunchPackPressureBestStreak {
            let nextTarget = bestChannelLaunchPackPressureConversionStreak + 1
            return "Building with active x\(bestChannelLaunchPackPressureConversionStreak); next target x\(nextTarget)."
        }

        let gapToBest = max(
            1,
            bestChannelLaunchPackPressureBestStreak - bestChannelLaunchPackPressureConversionStreak
        )
        return "Rebuilding at x\(bestChannelLaunchPackPressureConversionStreak); \(gapToBest) from best x\(bestChannelLaunchPackPressureBestStreak)."
    }

    private var bestChannelLaunchPackPressureModeShiftSummary: String {
        guard bestChannelLaunchPackPressureModeTransitionCount > 0 else {
            return "No mode transitions yet."
        }
        let latestTitle = Self.bestChannelLaunchPackPressureModeTransitionTitle(
            bestChannelLaunchPackPressureModeTransitionLatest
        )
        return "\(bestChannelLaunchPackPressureModeTransitionCount) total; latest \(latestTitle)."
    }

    private var bestChannelLaunchPackPressureModeMomentumSummary: String {
        if bestChannelLaunchPackPressureModeMomentumStreak >= 2 {
            return "Upshift streak x\(bestChannelLaunchPackPressureModeMomentumStreak)."
        }
        if bestChannelLaunchPackPressureModeMomentumStreak <= -2 {
            return "Cooldown streak x\(abs(bestChannelLaunchPackPressureModeMomentumStreak))."
        }
        if bestChannelLaunchPackPressureModeMomentumStreak == 1 {
            return "Recent transition moved upward."
        }
        if bestChannelLaunchPackPressureModeMomentumStreak == -1 {
            return "Recent transition moved downward."
        }
        return "Neutral."
    }

    private var launchRescueBurstAutoTriggerSummary: String {
        launchRescueBurstAutoTriggerSummary(launchRescueBurstLastAutoTriggerReason)
    }

    private var launchRescueBurstAutoTriggerAtSummary: String {
        AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(launchRescueBurstLastAutoTriggerAt)
    }

    private var launchRescueBurstAutoFollowupSummary: String {
        AppDelegate.launchRescueAutoFollowupRunSummary(
            commandID: launchRescueBurstLastFollowupCommandID,
            reasonToken: launchRescueBurstLastFollowupReason
        )
    }

    private var launchRescueBurstAutoFollowupAtSummary: String {
        AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(launchRescueBurstLastFollowupAt)
    }

    private static func appVersion(bundle: Bundle = .main) -> String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        return value(version ?? "", fallback: "Development")
    }

    private static func value(_ rawValue: String, fallback: String) -> String {
        let cleanValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanValue.isEmpty ? fallback : cleanValue
    }

    private static func bestChannelLaunchPackPressureToneTitle(_ token: String?) -> String {
        switch token?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "alert":
            return "Alert"
        case "watch":
            return "Watch"
        default:
            return "None"
        }
    }

    private static func bestChannelLaunchPackPressureModeTransitionLatestToken(
        _ token: String?
    ) -> String {
        let cleanToken = token?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard cleanToken.contains("-to-") else { return "none-to-none" }
        return cleanToken
    }

    private static func fameExceptionalLoopOutcomeSummary(
        _ scoreboard: AppDelegate.FameExceptionalLoopOutcomeScoreboard
    ) -> String {
        let lastFocusTitle = fameExceptionalLoopFocusTitle(scoreboard.lastFocusToken)
        let lastOutcomeAtSummary = AppDelegate.launchRescueAutoTriggerAtDiagnosticSummary(
            scoreboard.lastOutcomeAt
        )
        return "wins \(scoreboard.successes)/\(scoreboard.attempts) (\(scoreboard.successRate)%), win streak x\(scoreboard.successStreak), recovery streak x\(scoreboard.failureStreak), last focus \(lastFocusTitle), last run \(lastOutcomeAtSummary)"
    }

    private static func fameExceptionalLoopFocusTitle(_ token: String?) -> String {
        let normalizedToken = token?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard let normalizedToken, !normalizedToken.isEmpty else {
            return "None"
        }
        return AppDelegate.fameOnboardingCommandTitle(normalizedToken)
    }

    private static func launchRescueBurstAutoTriggerReasonToken(_ token: String?) -> String {
        AppDelegate.launchRescueAutoTriggerReasonToken(token)
    }

    private func launchRescueBurstAutoTriggerSummary(_ token: String) -> String {
        switch token {
        case "urgency-high":
            return "Urgency High escalation."
        case "urgency-critical":
            return "Urgency Critical escalation."
        case "momentum-watch":
            return "Cooldown momentum watch streak."
        case "momentum-alert":
            return "Cooldown momentum alert streak."
        case "pressure-persistence":
            return "Launch health pressure persistence."
        case "none":
            return "No auto trigger recorded yet."
        default:
            return "Unknown."
        }
    }

    private static func bestChannelLaunchPackPressureModeTransitionTitle(
        _ token: String
    ) -> String {
        let parts = token
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: "-to-")
        guard parts.count == 2 else { return "None -> None" }
        return "\(bestChannelLaunchPackPressureTrendTitle(parts[0])) -> \(bestChannelLaunchPackPressureTrendTitle(parts[1]))"
    }

    private static func bestChannelLaunchPackPressureTrendTitle(_ token: String) -> String {
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

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }
}
