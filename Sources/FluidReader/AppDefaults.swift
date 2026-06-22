import Foundation

enum AppDefaults {
    static let llmModel = "gpt-5.4-mini"
    static let llmProvider = "openAIResponses"
    static let openAIResponsesEndpoint = "https://api.openai.com/v1/responses"
    static let openAICompatibleChatEndpoint = "https://api.openai.com/v1/chat/completions"
    static let cloudVoiceModel = "gpt-4o-mini-tts"
    static let cloudVoiceName = "coral"
    static let cloudVoiceInstructions = "Speak in a relaxed, human-like voice. Use a gentle smile, small natural pauses, and clear words. Do not sound robotic or rushed."
    static let customPromptTitle = "Key Points"
    static let customPromptText = "Pull out the key points and any action items. Keep it short."
    static let saveRecentItems = true
    static let readerAlwaysOnTop = false
    static let showMenuBarItemKey = "showMenuBarItem"
    static let showMenuBarItem = true
    static let launcherCompactModeKey = "launcherCompactMode"
    static let launcherCompactMode = false
    static let launcherIndexedRootPathsKey = "launcherIndexedRootPaths"
    static let frontWindowGapPointsKey = "frontWindowGapPoints"
    static let frontWindowGapPoints = 0
    static let frontWindowGapPointOptions = [0, 8, 12, 16, 20, 24, 32]
    static let frontWindowCycleProfileKey = "frontWindowCycleProfile"
    static let frontWindowCycleProfile = "full"
    static let frontWindowCustomCycleCommandIDsKey = "frontWindowCustomCycleCommandIDs"
    static let autoCopyNewText = false
    static let autoPastePickedText = false
    static let autoPasteLLMAnswers = false
    static let saveClipboardHistory = false
    static let fameAutoPulseAfterSnapshot = true
    static let fameAutoPulseQuietMode = false
    static let fameMorningBriefOnLaunch = false
    static let fameMorningBriefQuietMode = true
    static let fameLaunchThresholdAlertsEnabled = true
    static let fameLaunchHealthPulseEnabled = true
    static let fameLaunchHealthPulseCooldownSeconds = 60
    static let fameLaunchHealthPulseCooldownOptions = [0, 15, 30, 60, 120, 300]
    static let fameLaunchHealthPressureAutoRescueEnabled = true
    static let fameLaunchHealthPressureAutoRescueCooldownHours = 24
    static let fameLaunchHealthPressureAutoRescueCooldownOptions = [0, 6, 12, 24, 48]
    static let fameLaunchThresholdAlertsSnoozeUntilKey = "fameLaunchThresholdAlertsSnoozeUntil"
    static let fameLaunchThresholdAlertsReminderLastSnoozeUntilKey = "fameLaunchThresholdAlertsReminderLastSnoozeUntil"
    static let fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey = "fameLaunchThresholdAlertsReminderLastUrgencyPriority"
    static let fameLaunchHealthTransitionCountDayKey = "fameLaunchHealthTransitionCountDay"
    static let fameLaunchHealthTransitionWatchToRiskCountKey = "fameLaunchHealthTransitionWatchToRiskCount"
    static let fameLaunchHealthTransitionRiskToReadyCountKey = "fameLaunchHealthTransitionRiskToReadyCount"
    static let fameLaunchHealthTransitionHistoryKey = "fameLaunchHealthTransitionHistory"
    static let fameLaunchHealthPressureAutoRescueLastRunDayKey = "fameLaunchHealthPressureAutoRescueLastRunDay"
    static let fameLaunchHealthPressureAutoRescueLastRunAtKey = "fameLaunchHealthPressureAutoRescueLastRunAt"
    static let fameLaunchRescueBurstLastRunAtKey = "fameLaunchRescueBurstLastRunAt"
    static let fameLaunchRescueBurstLastAutoTriggerReasonKey = "fameLaunchRescueBurstLastAutoTriggerReason"
    static let fameLaunchRescueBurstLastAutoTriggerAtKey = "fameLaunchRescueBurstLastAutoTriggerAt"
    static let fameLaunchRescueBurstLastFollowupReasonKey = "fameLaunchRescueBurstLastFollowupReason"
    static let fameLaunchRescueBurstLastFollowupCommandIDKey = "fameLaunchRescueBurstLastFollowupCommandID"
    static let fameLaunchRescueBurstLastFollowupAtKey = "fameLaunchRescueBurstLastFollowupAt"
    static let fameLaunchRescueBurstFollowupOutcomeTotalCountKey = "fameLaunchRescueBurstFollowupOutcomeTotalCount"
    static let fameLaunchRescueBurstFollowupOutcomeSuccessCountKey = "fameLaunchRescueBurstFollowupOutcomeSuccessCount"
    static let fameLaunchRescueBurstFollowupOutcomeLastAtKey = "fameLaunchRescueBurstFollowupOutcomeLastAt"
    static let fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey = "fameLaunchRescueBurstFollowupOutcomeLastSuccessAt"
    static let fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey = "fameLaunchRescueBurstFollowupOutcomeLastFailureAt"
    static let fameLaunchRescueBurstFollowupOutcomeHistoryKey = "fameLaunchRescueBurstFollowupOutcomeHistory"
    static let fameLaunchRescueBurstFollowupOutcomeHistoryWindowHours = 24
    static let fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey = "fameLaunchRescueBurstFollowupCoachRecoveryLaneStreak"
    static let fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey =
        "fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAt"
    static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey =
        "fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes"
    static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes = 30
    static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMinimum = 5
    static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMaximum = 60
    static let fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesStep = 5
    static let fameLaunchRescueBurstAutoCooldownMinutes = 15
    static let fameLaunchRescueBurstAutoCooldownOptions = [0, 5, 15, 30, 60]
    static let fameAutoOpsBundleLastRunAtKey = "fameAutoOpsBundleLastRunAt"
    static let fameAutoOpsBundleCooldownMinutes = 30
    static let fameAutoOpsBundleCooldownOptions = [0, 10, 30, 60]
    static let fameLaunchRecoveryHotKeyAutoCoachEnabledKey = "fameLaunchRecoveryHotKeyAutoCoachEnabled"
    static let fameLaunchRecoveryHotKeyAutoCoachEnabled = false
    static let fameLaunchRecoveryHotKeyAutoCoachCooldownMinutesKey = "fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes"
    static let fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes = 10
    static let fameLaunchRecoveryHotKeyAutoCoachCooldownOptions = [0, 5, 10, 15, 30, 60]
    static let fameLaunchRecoveryHotKeyAutoCoachLastRunAtKey = "fameLaunchRecoveryHotKeyAutoCoachLastRunAt"
    static let fameLaunchRecoveryHotKeyAutoRescueEnabledKey = "fameLaunchRecoveryHotKeyAutoRescueEnabled"
    static let fameLaunchRecoveryHotKeyAutoRescueEnabled = false
    static let fameLaunchRecoveryHotKeyAutoRescueCooldownMinutesKey =
        "fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes"
    static let fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes = 10
    static let fameLaunchRecoveryHotKeyAutoRescueCooldownOptions = [0, 5, 10, 15, 30, 60]
    static let fameLaunchRecoveryHotKeyAutoRescueLastRunAtKey = "fameLaunchRecoveryHotKeyAutoRescueLastRunAt"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeEnabledKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled = false
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutesKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes = 10
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownOptions = [0, 5, 10, 15, 30, 60]
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap = 5
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapOptions = [0, 1, 2, 3, 5, 8, 12]
    static let fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpensKey =
        "fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens"
    static let fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens = 3
    static let fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpenOptions = [1, 2, 3, 5]
    static let fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabledKey =
        "fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled"
    static let fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled = false
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDayKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDay"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCountKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCount"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeek"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCountKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCount"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCountKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCount"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistory"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeStreakKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeStreak"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreakKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreak"
    static let fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey = "fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAt"
    static let fameLaunchRecoveryHotKeyInterventionScoresKey = "fameLaunchRecoveryHotKeyInterventionScores"
    static let fameMomentumPanelActionScoresKey = "fameMomentumPanelActionScores"
    static let fameMomentumPanelOpportunityCountKey = "fameMomentumPanelOpportunityCount"
    static let fameMomentumPanelConversionCountKey = "fameMomentumPanelConversionCount"
    static let fameMomentumPanelRouteStabilizationRunCountKey =
        "fameMomentumPanelRouteStabilizationRunCount"
    static let fameMomentumPanelRouteStabilizationSuccessCountKey =
        "fameMomentumPanelRouteStabilizationSuccessCount"
    static let fameMomentumPanelRouteStabilizationResetCueDayStampKey =
        "fameMomentumPanelRouteStabilizationResetCueDayStamp"
    static let fameMomentumPanelRouteStabilizationResetCueCountTodayKey =
        "fameMomentumPanelRouteStabilizationResetCueCountToday"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore"
    static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey =
        "fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount"
    static let fameLaunchRecoveryHotKeyReadinessHistoryKey = "fameLaunchRecoveryHotKeyReadinessHistory"
    static let fameLaunchRecoveryHotKeyDirectStreakKey = "fameLaunchRecoveryHotKeyDirectStreak"
    static let fameLaunchRecoveryHotKeyBestDirectStreakKey = "fameLaunchRecoveryHotKeyBestDirectStreak"
    static let fameBestChannelLaunchPackPressureOpportunitiesKey = "fameBestChannelLaunchPackPressureOpportunities"
    static let fameBestChannelLaunchPackPressureConversionsKey = "fameBestChannelLaunchPackPressureConversions"
    static let fameBestChannelLaunchPackPressureConversionStreakKey = "fameBestChannelLaunchPackPressureConversionStreak"
    static let fameBestChannelLaunchPackPressureBestStreakKey = "fameBestChannelLaunchPackPressureBestStreak"
    static let fameBestChannelLaunchPackPressureLastToneKey = "fameBestChannelLaunchPackPressureLastTone"
    static let fameBestChannelLaunchPackPressureModeTransitionCountKey = "fameBestChannelLaunchPackPressureModeTransitionCount"
    static let fameBestChannelLaunchPackPressureModeTransitionLatestKey = "fameBestChannelLaunchPackPressureModeTransitionLatest"
    static let fameBestChannelLaunchPackPressureModeMomentumStreakKey = "fameBestChannelLaunchPackPressureModeMomentumStreak"
    static let fameRecommendationConversionOpportunitiesKey = "fameRecommendationConversionOpportunities"
    static let fameRecommendationConversionCountKey = "fameRecommendationConversionCount"
    static let fameRecommendationConversionBestOpenStreakKey = "fameRecommendationConversionBestOpenStreak"
    static let fameRecommendationConversionPairOpportunitiesKey = "fameRecommendationConversionPairOpportunities"
    static let fameRecommendationConversionPairConversionsKey = "fameRecommendationConversionPairConversions"
    static let fameRecommendationConversionPairLastConversionOpenCountKey =
        "fameRecommendationConversionPairLastConversionOpenCount"
    static let fameRecommendationMomentumRescueStreakKey = "fameRecommendationMomentumRescueStreak"
    static let fameRecommendationMomentumRescueBestStreakKey = "fameRecommendationMomentumRescueBestStreak"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabledKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled = false
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutesKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes = 10
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownOptions = [0, 5, 10, 15, 30, 60]
    static let fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpensKey =
        "fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens"
    static let fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens = 3
    static let fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpenOptions = [1, 2, 3, 5]
    static let fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabledKey =
        "fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled"
    static let fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled = false
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAtKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAt"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDayKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDay"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCountKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCount"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeek"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCountKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCount"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCountKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCount"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseStreakKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseStreak"
    static let fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreakKey =
        "fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreak"
    static let fameRecommendationMomentumRescueLeaderboardDayStampKey =
        "fameRecommendationMomentumRescueLeaderboardDayStamp"
    static let fameRecommendationMomentumRescueLeaderboardRunsTodayKey =
        "fameRecommendationMomentumRescueLeaderboardRunsToday"
    static let fameRecommendationMomentumRescueLeaderboardBestDayRunsKey =
        "fameRecommendationMomentumRescueLeaderboardBestDayRuns"
    static let fameRecommendationMomentumRescueLeaderboardWeekStampKey =
        "fameRecommendationMomentumRescueLeaderboardWeekStamp"
    static let fameRecommendationMomentumRescueLeaderboardRunsThisWeekKey =
        "fameRecommendationMomentumRescueLeaderboardRunsThisWeek"
    static let fameRecommendationMomentumRescueLeaderboardBestWeekRunsKey =
        "fameRecommendationMomentumRescueLeaderboardBestWeekRuns"
    static let fameRecommendationMomentumRescueLeaderboardPreviousWeekRunsKey =
        "fameRecommendationMomentumRescueLeaderboardPreviousWeekRuns"
    static let fameCadenceExecutionKitBadgeEnabledKey = "fameCadenceExecutionKitBadgeEnabled"
    static let fameCadenceExecutionKitBadgeEnabled = true
    static let fameCadenceExecutionKitMomentumCardEnabledKey = "fameCadenceExecutionKitMomentumCardEnabled"
    static let fameCadenceExecutionKitMomentumCardEnabled = true
    static let fameCadenceAutopilotCueCooldownSeconds = 45
    static let fameCadenceAutopilotCueCooldownOptions = [0, 15, 30, 45, 60, 120]
    static let fameCadenceAutopilotCelebrationIntensity = 1
    static let fameCadenceAutopilotCelebrationIntensityOptions = [0, 1, 2]
    static let fameOnboardingNudgeEnabledKey = "fameOnboardingNudgeEnabled"
    static let fameOnboardingNudgeEnabled = true
    static let fameOnboardingNudgeWindowDaysKey = "fameOnboardingNudgeWindowDays"
    static let fameOnboardingNudgeWindowDays = 7
    static let fameOnboardingNudgeWindowDaysOptions = [3, 5, 7, 10, 14]
    static let fameOnboardingGapRecoveryLastAtKey = "fameOnboardingGapRecoveryLastAt"
    static let fameOnboardingGapRecoveryFollowupCommandIDKey = "fameOnboardingGapRecoveryFollowupCommandID"
    static let fameOnboardingGapRecoveryRemainingArtifactsKey = "fameOnboardingGapRecoveryRemainingArtifacts"
    static let fameOnboardingGapRecoveryTopPickWindowMinutes = 20
    static let fameCadenceExecutionKitCommandStreakKey = "fameCadenceExecutionKitCommandStreak"
    static let fameCadenceExecutionKitCommandBestStreakKey = "fameCadenceExecutionKitCommandBestStreak"
    static let fameExceptionalLoopOutcomeTotalCountKey = "fameExceptionalLoopOutcomeTotalCount"
    static let fameExceptionalLoopOutcomeSuccessCountKey = "fameExceptionalLoopOutcomeSuccessCount"
    static let fameExceptionalLoopOutcomeSuccessStreakKey = "fameExceptionalLoopOutcomeSuccessStreak"
    static let fameExceptionalLoopOutcomeFailureStreakKey = "fameExceptionalLoopOutcomeFailureStreak"
    static let fameExceptionalLoopOutcomeLastFocusTokenKey = "fameExceptionalLoopOutcomeLastFocusToken"
    static let fameExceptionalLoopOutcomeLastAtKey = "fameExceptionalLoopOutcomeLastAt"
    static let fameExceptionalLoopOutcomeCommandHistoryKey = "fameExceptionalLoopOutcomeCommandHistory"
    static let fameExceptionalLoopRecoveryLaneAutoRunLastAtKey = "fameExceptionalLoopRecoveryLaneAutoRunLastAt"
    static let fameExceptionalLoopAutoRecoveryLaneMissesRequiredKey =
        "fameExceptionalLoopAutoRecoveryLaneMissesRequired"
    static let fameExceptionalLoopAutoRecoveryLaneMissesRequired = 3
    static let fameExceptionalLoopAutoRecoveryLaneMissesRequiredOptions = [2, 3, 4, 5]
    static let fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredKey =
        "fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired"
    static let fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = 2
    static let fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredOptions = [1, 2, 3, 4]
    static let fameExceptionalLoopAutoRecoveryLaneCooldownMinutesKey =
        "fameExceptionalLoopAutoRecoveryLaneCooldownMinutes"
    static let fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = 20
    static let fameExceptionalLoopAutoRecoveryLaneCooldownMinutesOptions = [0, 5, 10, 20, 30, 60]
    static let fameExceptionalLoopOutcomeCommandHistoryMaxSamples = 120
    static let fameExceptionalLoopOutcomeCommandHistoryWindowDays = 30

    static let screenRecordingSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    )
    static let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    static func value(_ value: String, fallback: String) -> String {
        let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }

    static func normalizedFrontWindowGapPoints(_ points: Int) -> Int {
        frontWindowGapPointOptions.contains(points) ? points : frontWindowGapPoints
    }

    static func normalizedFameAutoOpsBundleCooldownMinutes(_ minutes: Int) -> Int {
        fameAutoOpsBundleCooldownOptions.contains(minutes) ? minutes : fameAutoOpsBundleCooldownMinutes
    }

    static func normalizedFameLaunchRescueBurstAutoCooldownMinutes(_ minutes: Int) -> Int {
        fameLaunchRescueBurstAutoCooldownOptions.contains(minutes)
            ? minutes
            : fameLaunchRescueBurstAutoCooldownMinutes
    }

    static func normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
        _ minutes: Int
    ) -> Int {
        min(
            fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMaximum,
            max(
                fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMinimum,
                minutes
            )
        )
    }

    static func normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(_ minutes: Int) -> Int {
        fameLaunchRecoveryHotKeyAutoCoachCooldownOptions.contains(minutes)
            ? minutes
            : fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
    }

    static func normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(_ minutes: Int) -> Int {
        fameLaunchRecoveryHotKeyAutoRescueCooldownOptions.contains(minutes)
            ? minutes
            : fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
    }

    static func normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(_ minutes: Int) -> Int {
        fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownOptions.contains(minutes)
            ? minutes
            : fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes
    }

    static func normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(_ dailyCap: Int) -> Int {
        fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapOptions.contains(dailyCap)
            ? dailyCap
            : fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap
    }

    static func normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(_ opens: Int) -> Int {
        fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpenOptions.contains(opens)
            ? opens
            : fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens
    }

    static func normalizedFameLaunchHealthPulseCooldownSeconds(_ seconds: Int) -> Int {
        fameLaunchHealthPulseCooldownOptions.contains(seconds)
            ? seconds
            : fameLaunchHealthPulseCooldownSeconds
    }

    static func normalizedFameLaunchHealthPressureAutoRescueCooldownHours(_ hours: Int) -> Int {
        fameLaunchHealthPressureAutoRescueCooldownOptions.contains(hours)
            ? hours
            : fameLaunchHealthPressureAutoRescueCooldownHours
    }

    static func normalizedFameCadenceAutopilotCueCooldownSeconds(_ seconds: Int) -> Int {
        fameCadenceAutopilotCueCooldownOptions.contains(seconds)
            ? seconds
            : fameCadenceAutopilotCueCooldownSeconds
    }

    static func normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
        _ minutes: Int
    ) -> Int {
        fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownOptions.contains(minutes)
            ? minutes
            : fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
    }

    static func normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
        _ opens: Int
    ) -> Int {
        fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpenOptions.contains(opens)
            ? opens
            : fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
    }

    static func normalizedFameCadenceAutopilotCelebrationIntensity(_ intensity: Int) -> Int {
        fameCadenceAutopilotCelebrationIntensityOptions.contains(intensity)
            ? intensity
            : fameCadenceAutopilotCelebrationIntensity
    }

    static func normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(_ misses: Int) -> Int {
        fameExceptionalLoopAutoRecoveryLaneMissesRequiredOptions.contains(misses)
            ? misses
            : fameExceptionalLoopAutoRecoveryLaneMissesRequired
    }

    static func normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
        _ failureStreak: Int
    ) -> Int {
        fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredOptions.contains(failureStreak)
            ? failureStreak
            : fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
    }

    static func normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(_ minutes: Int) -> Int {
        fameExceptionalLoopAutoRecoveryLaneCooldownMinutesOptions.contains(minutes)
            ? minutes
            : fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
    }

    static func normalizedFameOnboardingNudgeWindowDays(_ days: Int) -> Int {
        fameOnboardingNudgeWindowDaysOptions.contains(days)
            ? days
            : fameOnboardingNudgeWindowDays
    }
}
