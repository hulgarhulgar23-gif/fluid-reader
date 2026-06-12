import XCTest
@testable import FluidReader

final class AppDefaultsTests: XCTestCase {
    func testModelDefaultsAreSet() {
        XCTAssertEqual(AppDefaults.llmModel, "gpt-5.4-mini")
        XCTAssertEqual(AppDefaults.llmProvider, "openAIResponses")
        XCTAssertEqual(AppDefaults.openAIResponsesEndpoint, "https://api.openai.com/v1/responses")
        XCTAssertEqual(AppDefaults.openAICompatibleChatEndpoint, "https://api.openai.com/v1/chat/completions")
        XCTAssertEqual(AppDefaults.cloudVoiceModel, "gpt-4o-mini-tts")
        XCTAssertEqual(AppDefaults.cloudVoiceName, "coral")
        XCTAssertEqual(AppDefaults.customPromptTitle, "Key Points")
        XCTAssertFalse(AppDefaults.customPromptText.isEmpty)
        XCTAssertTrue(AppDefaults.saveRecentItems)
        XCTAssertFalse(AppDefaults.readerAlwaysOnTop)
        XCTAssertFalse(AppDefaults.autoCopyNewText)
        XCTAssertFalse(AppDefaults.autoPastePickedText)
        XCTAssertFalse(AppDefaults.autoPasteLLMAnswers)
        XCTAssertFalse(AppDefaults.saveClipboardHistory)
        XCTAssertTrue(AppDefaults.fameAutoPulseAfterSnapshot)
        XCTAssertFalse(AppDefaults.fameAutoPulseQuietMode)
        XCTAssertFalse(AppDefaults.fameMorningBriefOnLaunch)
        XCTAssertTrue(AppDefaults.fameMorningBriefQuietMode)
        XCTAssertTrue(AppDefaults.fameLaunchThresholdAlertsEnabled)
        XCTAssertTrue(AppDefaults.fameLaunchHealthPulseEnabled)
        XCTAssertEqual(AppDefaults.fameLaunchHealthPulseCooldownSeconds, 60)
        XCTAssertTrue(AppDefaults.fameLaunchHealthPressureAutoRescueEnabled)
        XCTAssertEqual(AppDefaults.fameLaunchHealthPressureAutoRescueCooldownHours, 24)
        XCTAssertEqual(
            AppDefaults.fameLaunchThresholdAlertsSnoozeUntilKey,
            "fameLaunchThresholdAlertsSnoozeUntil"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchThresholdAlertsReminderLastSnoozeUntilKey,
            "fameLaunchThresholdAlertsReminderLastSnoozeUntil"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchThresholdAlertsReminderLastUrgencyPriorityKey,
            "fameLaunchThresholdAlertsReminderLastUrgencyPriority"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchHealthTransitionCountDayKey,
            "fameLaunchHealthTransitionCountDay"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchHealthTransitionWatchToRiskCountKey,
            "fameLaunchHealthTransitionWatchToRiskCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchHealthTransitionRiskToReadyCountKey,
            "fameLaunchHealthTransitionRiskToReadyCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchHealthTransitionHistoryKey,
            "fameLaunchHealthTransitionHistory"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchHealthPressureAutoRescueLastRunDayKey,
            "fameLaunchHealthPressureAutoRescueLastRunDay"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchHealthPressureAutoRescueLastRunAtKey,
            "fameLaunchHealthPressureAutoRescueLastRunAt"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRescueBurstLastRunAtKey, "fameLaunchRescueBurstLastRunAt")
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstLastAutoTriggerReasonKey,
            "fameLaunchRescueBurstLastAutoTriggerReason"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstLastAutoTriggerAtKey,
            "fameLaunchRescueBurstLastAutoTriggerAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstLastFollowupReasonKey,
            "fameLaunchRescueBurstLastFollowupReason"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstLastFollowupCommandIDKey,
            "fameLaunchRescueBurstLastFollowupCommandID"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstLastFollowupAtKey,
            "fameLaunchRescueBurstLastFollowupAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupOutcomeTotalCountKey,
            "fameLaunchRescueBurstFollowupOutcomeTotalCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupOutcomeSuccessCountKey,
            "fameLaunchRescueBurstFollowupOutcomeSuccessCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastAtKey,
            "fameLaunchRescueBurstFollowupOutcomeLastAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastSuccessAtKey,
            "fameLaunchRescueBurstFollowupOutcomeLastSuccessAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupOutcomeLastFailureAtKey,
            "fameLaunchRescueBurstFollowupOutcomeLastFailureAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryKey,
            "fameLaunchRescueBurstFollowupOutcomeHistory"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRescueBurstFollowupOutcomeHistoryWindowHours, 24)
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachRecoveryLaneStreakKey,
            "fameLaunchRescueBurstFollowupCoachRecoveryLaneStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAtKey,
            "fameLaunchRescueBurstFollowupCoachLastAutoRecoveryChecklistAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesKey,
            "fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes,
            30
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMinimum,
            5
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMaximum,
            60
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesStep,
            5
        )
        XCTAssertEqual(AppDefaults.fameLaunchRescueBurstAutoCooldownMinutes, 15)
        XCTAssertEqual(AppDefaults.fameAutoOpsBundleLastRunAtKey, "fameAutoOpsBundleLastRunAt")
        XCTAssertEqual(AppDefaults.fameAutoOpsBundleCooldownMinutes, 30)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabledKey,
            "fameLaunchRecoveryHotKeyAutoCoachEnabled"
        )
        XCTAssertFalse(AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutesKey,
            "fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes, 10)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachLastRunAtKey,
            "fameLaunchRecoveryHotKeyAutoCoachLastRunAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabledKey,
            "fameLaunchRecoveryHotKeyAutoRescueEnabled"
        )
        XCTAssertFalse(AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutesKey,
            "fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes, 10)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueLastRunAtKey,
            "fameLaunchRecoveryHotKeyAutoRescueLastRunAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabledKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled"
        )
        XCTAssertFalse(AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutesKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes, 10)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap, 5)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpensKey,
            "fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens"
        )
        XCTAssertEqual(AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens, 3)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabledKey,
            "fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled"
        )
        XCTAssertFalse(AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled)
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDayKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDay"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCountKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeek"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCountKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCountKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistory"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeStreakKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreakKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey,
            "fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAt"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyInterventionScoresKey,
            "fameLaunchRecoveryHotKeyInterventionScores"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelActionScoresKey,
            "fameMomentumPanelActionScores"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelOpportunityCountKey,
            "fameMomentumPanelOpportunityCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelConversionCountKey,
            "fameMomentumPanelConversionCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey,
            "fameMomentumPanelRouteStabilizationRunCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey,
            "fameMomentumPanelRouteStabilizationSuccessCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationResetCueDayStampKey,
            "fameMomentumPanelRouteStabilizationResetCueDayStamp"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationResetCueCountTodayKey,
            "fameMomentumPanelRouteStabilizationResetCueCountToday"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore"
        )
        XCTAssertEqual(
            AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey,
            "fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey,
            "fameLaunchRecoveryHotKeyReadinessHistory"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyDirectStreakKey,
            "fameLaunchRecoveryHotKeyDirectStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameLaunchRecoveryHotKeyBestDirectStreakKey,
            "fameLaunchRecoveryHotKeyBestDirectStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureOpportunitiesKey,
            "fameBestChannelLaunchPackPressureOpportunities"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureConversionsKey,
            "fameBestChannelLaunchPackPressureConversions"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureConversionStreakKey,
            "fameBestChannelLaunchPackPressureConversionStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureBestStreakKey,
            "fameBestChannelLaunchPackPressureBestStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureLastToneKey,
            "fameBestChannelLaunchPackPressureLastTone"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey,
            "fameBestChannelLaunchPackPressureModeTransitionCount"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey,
            "fameBestChannelLaunchPackPressureModeTransitionLatest"
        )
        XCTAssertEqual(
            AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey,
            "fameBestChannelLaunchPackPressureModeMomentumStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationConversionOpportunitiesKey,
            "fameRecommendationConversionOpportunities"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationConversionCountKey,
            "fameRecommendationConversionCount"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationConversionBestOpenStreakKey,
            "fameRecommendationConversionBestOpenStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationConversionPairOpportunitiesKey,
            "fameRecommendationConversionPairOpportunities"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationConversionPairConversionsKey,
            "fameRecommendationConversionPairConversions"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationConversionPairLastConversionOpenCountKey,
            "fameRecommendationConversionPairLastConversionOpenCount"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueStreakKey,
            "fameRecommendationMomentumRescueStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueBestStreakKey,
            "fameRecommendationMomentumRescueBestStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabledKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled"
        )
        XCTAssertFalse(AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled)
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutesKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes"
        )
        XCTAssertEqual(AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes, 10)
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpensKey,
            "fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens,
            3
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabledKey,
            "fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled"
        )
        XCTAssertFalse(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAtKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAt"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDayKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDay"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCountKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCount"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeek"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCountKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCount"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCountKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCount"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseStreakKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreakKey,
            "fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeTotalCountKey,
            "fameExceptionalLoopOutcomeTotalCount"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey,
            "fameExceptionalLoopOutcomeSuccessCount"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey,
            "fameExceptionalLoopOutcomeSuccessStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey,
            "fameExceptionalLoopOutcomeFailureStreak"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey,
            "fameExceptionalLoopOutcomeLastFocusToken"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeLastAtKey,
            "fameExceptionalLoopOutcomeLastAt"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopOutcomeCommandHistoryKey,
            "fameExceptionalLoopOutcomeCommandHistory"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey,
            "fameExceptionalLoopRecoveryLaneAutoRunLastAt"
        )
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequiredKey,
            "fameExceptionalLoopAutoRecoveryLaneMissesRequired"
        )
        XCTAssertEqual(AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired, 3)
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredKey,
            "fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired"
        )
        XCTAssertEqual(AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired, 2)
        XCTAssertEqual(
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutesKey,
            "fameExceptionalLoopAutoRecoveryLaneCooldownMinutes"
        )
        XCTAssertEqual(AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes, 20)
        XCTAssertEqual(AppDefaults.fameExceptionalLoopOutcomeCommandHistoryMaxSamples, 120)
        XCTAssertEqual(AppDefaults.fameExceptionalLoopOutcomeCommandHistoryWindowDays, 30)
        XCTAssertEqual(
            AppDefaults.fameCadenceExecutionKitBadgeEnabledKey,
            "fameCadenceExecutionKitBadgeEnabled"
        )
        XCTAssertTrue(AppDefaults.fameCadenceExecutionKitBadgeEnabled)
        XCTAssertEqual(
            AppDefaults.fameCadenceExecutionKitMomentumCardEnabledKey,
            "fameCadenceExecutionKitMomentumCardEnabled"
        )
        XCTAssertTrue(AppDefaults.fameCadenceExecutionKitMomentumCardEnabled)
        XCTAssertEqual(AppDefaults.fameCadenceAutopilotCueCooldownSeconds, 45)
        XCTAssertEqual(AppDefaults.fameCadenceAutopilotCelebrationIntensity, 1)
        XCTAssertEqual(AppDefaults.fameOnboardingNudgeEnabledKey, "fameOnboardingNudgeEnabled")
        XCTAssertTrue(AppDefaults.fameOnboardingNudgeEnabled)
        XCTAssertEqual(AppDefaults.fameOnboardingNudgeWindowDaysKey, "fameOnboardingNudgeWindowDays")
        XCTAssertEqual(AppDefaults.fameOnboardingNudgeWindowDays, 7)
        XCTAssertEqual(
            AppDefaults.cloudVoiceInstructions,
            "Speak in a relaxed, human-like voice. Use a gentle smile, small natural pauses, and clear words. Do not sound robotic or rushed."
        )
    }

    func testBlankValueFallsBack() {
        XCTAssertEqual(AppDefaults.value("  ", fallback: "fallback"), "fallback")
        XCTAssertEqual(AppDefaults.value(" custom ", fallback: "fallback"), "custom")
    }

    func testOpsBundleCooldownNormalization() {
        XCTAssertEqual(AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(10), 10)
        XCTAssertEqual(AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(30), 30)
        XCTAssertEqual(AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(60), 60)
        XCTAssertEqual(
            AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(7),
            AppDefaults.fameAutoOpsBundleCooldownMinutes
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(5), 5)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(15), 15)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(60), 60)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(7),
            AppDefaults.fameLaunchRescueBurstAutoCooldownMinutes
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                    1
                ),
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMinimum
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                    30
                ),
            30
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutes(
                    90
                ),
            AppDefaults.fameLaunchRescueBurstFollowupCoachAutoRecoveryChecklistCooldownMinutesMaximum
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(5), 5)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(10), 10)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(60), 60)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(7),
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(5), 5)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(10), 10)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(60), 60)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(7),
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(5), 5)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(10), 10)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(60), 60)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(7),
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(1), 1)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(5), 5)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(12), 12)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(4),
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(1), 1)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(3), 3)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(5), 5)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(4),
            AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(15), 15)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(60), 60)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(300), 300)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(7),
            AppDefaults.fameLaunchHealthPulseCooldownSeconds
        )
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(6), 6)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(24), 24)
        XCTAssertEqual(AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(48), 48)
        XCTAssertEqual(
            AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(9),
            AppDefaults.fameLaunchHealthPressureAutoRescueCooldownHours
        )
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(15), 15)
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(45), 45)
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(120), 120)
        XCTAssertEqual(
            AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(22),
            AppDefaults.fameCadenceAutopilotCueCooldownSeconds
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                    0
                ),
            0
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                    5
                ),
            5
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                    10
                ),
            10
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                    60
                ),
            60
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                    7
                ),
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                    1
                ),
            1
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                    3
                ),
            3
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                    5
                ),
            5
        )
        XCTAssertEqual(
            AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                    4
                ),
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
        )
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(0), 0)
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(1), 1)
        XCTAssertEqual(AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(2), 2)
        XCTAssertEqual(
            AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(9),
            AppDefaults.fameCadenceAutopilotCelebrationIntensity
        )
        XCTAssertEqual(AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(2), 2)
        XCTAssertEqual(AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(3), 3)
        XCTAssertEqual(AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(5), 5)
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(7),
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(1),
            1
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(2),
            2
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(4),
            4
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(9),
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(0),
            0
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(20),
            20
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(60),
            60
        )
        XCTAssertEqual(
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(17),
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        XCTAssertEqual(AppDefaults.normalizedFameOnboardingNudgeWindowDays(3), 3)
        XCTAssertEqual(AppDefaults.normalizedFameOnboardingNudgeWindowDays(7), 7)
        XCTAssertEqual(AppDefaults.normalizedFameOnboardingNudgeWindowDays(14), 14)
        XCTAssertEqual(
            AppDefaults.normalizedFameOnboardingNudgeWindowDays(8),
            AppDefaults.fameOnboardingNudgeWindowDays
        )
    }

    func testScreenRecordingSettingsURL() throws {
        let url = try XCTUnwrap(AppDefaults.screenRecordingSettingsURL)
        XCTAssertEqual(url.scheme, "x-apple.systempreferences")
        XCTAssertTrue(url.absoluteString.contains("Privacy_ScreenCapture"))
    }

    func testAccessibilitySettingsURL() throws {
        let url = try XCTUnwrap(AppDefaults.accessibilitySettingsURL)
        XCTAssertEqual(url.scheme, "x-apple.systempreferences")
        XCTAssertTrue(url.absoluteString.contains("Privacy_Accessibility"))
    }
}
