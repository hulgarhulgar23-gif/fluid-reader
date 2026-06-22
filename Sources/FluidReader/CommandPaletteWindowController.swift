import AppKit
import SwiftUI

struct CommandUsageRecord: Codable, Equatable {
    var useCount: Int
    var lastUsedAt: Date
}

final class CommandUsageStore: ObservableObject {
    private static let defaultKey = "commandUsageRecords"
    private static let defaultFavoritesKey = "favoriteCommandIDs"
    private static let maxActionIDLength = 120

    private let defaults: UserDefaults
    private let key: String
    private let favoritesKey: String
    @Published private(set) var records: [String: CommandUsageRecord]
    @Published private(set) var favoriteActionIDs: Set<String>

    init(
        defaults: UserDefaults = .standard,
        key: String = CommandUsageStore.defaultKey,
        favoritesKey: String = CommandUsageStore.defaultFavoritesKey
    ) {
        self.defaults = defaults
        self.key = key
        self.favoritesKey = favoritesKey
        records = Self.loadRecords(from: defaults, key: key)
        favoriteActionIDs = Self.loadFavoriteActionIDs(from: defaults, key: favoritesKey)
    }

    func recordRun(actionID: String, at date: Date = Date()) {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else {
            return
        }

        let oldRecord = records[sanitizedActionID]
        let useCount: Int
        if let existingUseCount = oldRecord?.useCount {
            useCount = existingUseCount < Int.max ? existingUseCount + 1 : Int.max
        } else {
            useCount = 1
        }

        records[sanitizedActionID] = CommandUsageRecord(
            useCount: useCount,
            lastUsedAt: date
        )
        save()
    }

    func clearRecords() {
        records = [:]
        defaults.removeObject(forKey: key)
    }

    func isFavorite(actionID: String) -> Bool {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else {
            return false
        }
        return favoriteActionIDs.contains(sanitizedActionID)
    }

    func toggleFavorite(actionID: String) {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else {
            return
        }

        if favoriteActionIDs.contains(sanitizedActionID) {
            favoriteActionIDs.remove(sanitizedActionID)
        } else {
            favoriteActionIDs.insert(sanitizedActionID)
        }
        saveFavorites()
    }

    func clearFavorites() {
        favoriteActionIDs = []
        defaults.removeObject(forKey: favoritesKey)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }

    private func saveFavorites() {
        defaults.set(favoriteActionIDs.sorted(), forKey: favoritesKey)
    }

    private static func loadRecords(from defaults: UserDefaults, key: String) -> [String: CommandUsageRecord] {
        guard let data = defaults.data(forKey: key),
              let decodedRecords = try? JSONDecoder().decode([String: CommandUsageRecord].self, from: data) else {
            return [:]
        }

        var sanitizedRecords: [String: CommandUsageRecord] = [:]
        for (actionID, record) in decodedRecords {
            guard let normalizedActionID = sanitizedActionID(actionID),
                  record.useCount > 0 else {
                continue
            }

            if let existing = sanitizedRecords[normalizedActionID] {
                sanitizedRecords[normalizedActionID] = CommandUsageRecord(
                    useCount: max(existing.useCount, record.useCount),
                    lastUsedAt: max(existing.lastUsedAt, record.lastUsedAt)
                )
                continue
            }

            sanitizedRecords[normalizedActionID] = record
        }
        return sanitizedRecords
    }

    private static func loadFavoriteActionIDs(from defaults: UserDefaults, key: String) -> Set<String> {
        Set(
            (defaults.stringArray(forKey: key) ?? [])
                .compactMap(sanitizedActionID(_:))
        )
    }

    private static func sanitizedActionID(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }

        if trimmed.count <= maxActionIDLength {
            return trimmed
        }
        return String(trimmed.prefix(maxActionIDLength))
    }
}

final class PaletteSession: ObservableObject {
    private static let launchRecoveryHotKeyInterventionScoreDefaultDecayOpenInterval = 4
    private static let launchRecoveryHotKeyInterventionScoreCriticalDecayOpenInterval = 2
    private static let launchRecoveryHotKeyInterventionScoreRange = -12...12
    private static let launchRecoveryHotKeyInterventionTrustHistoryLimit = 12
    private static let launchRecoveryHotKeyReadinessPersistenceLimit = 24
    private static let fameMomentumPanelActionScoreRange = -12...12
    private static let fameMomentumPanelActionScoreDecayOpenInterval = 5
    private static let fameMomentumPanelActionScorePositiveDelta = 2
    private static let fameMomentumPanelActionScoreMissDelta = -1
    private static let fameMomentumPanelActionScoreSkippedAlternativeDelta = -1
    private static let fameMomentumPanelRouteFlipHistoryLimit = 3
    private static let fameMomentumPanelRouteStabilizationPulseVolatileStreakThreshold = 2
    private static let fameMomentumPanelRouteStabilizationPulseCooldownOpenInterval = 3
    private static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryLimit = 12
    private static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreRange =
        -36...36
    private static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountLimit =
        160
    private static let
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreIdleDecayOpenInterval = 3
    private static let
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleIdleDecayOpenInterval = 6
    private static let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationBiasRange =
        -3...3
    private static let recommendationPairMaxActionIDLength = 120

    struct LaunchRecoveryHotKeyLegendRiskStickyPromotion: Equatable {
        let actionID: String
        let opensRemaining: Int
        let isHoldUntilRecovered: Bool
    }

    struct RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion: Equatable {
        let actionID: String
        let opensRemaining: Int
        let isHoldUntilRecovered: Bool
    }

    struct RecommendationConversionPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescuePulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let streak: Int
        let bestStreak: Int
        let tierTitle: String
        let didTierUpgrade: Bool
        let didSetNewBest: Bool
    }

    struct RecommendationMomentumRescueWeeklyRecordPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let runsThisWeek: Int
        let previousBestWeekRuns: Int
        let delta: Int
    }

    struct FameMomentumPanelLearningPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct FameMomentumPanelRouteFlipPulse: Equatable {
        enum Trigger: Equatable {
            case freshSignal
            case momentumSurge
            case tightDecision
            case rerank
        }

        let trigger: Trigger
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let previousActionPrompt: String
        let nextActionPrompt: String
        let confidenceDeltaPoints: Int?
        let previousSignalAgeOpens: Int?
        let nextSignalAgeOpens: Int?
        let previousActionScore: Int?
        let nextActionScore: Int?
        let routeScoreDelta: Int?
    }

    struct FameMomentumPanelRouteStabilizationPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let volatileStreak: Int
        let flipCount: Int
        let openSpan: Int
    }

    struct FameMomentumPanelRouteStabilizationScoreboard: Equatable {
        let runs: Int
        let successes: Int
        let pendingRuns: Int
        let successRatePercent: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct FameMomentumPanelRouteStabilizationRecoverySuggestion: Equatable {
        let resetCountToday: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let buttonTitle: String
        let helpText: String
    }

    struct FameMomentumPanelRouteFlipHistoryEntry: Equatable {
        let openCount: Int
        let occurredAt: Date
        let trigger: FameMomentumPanelRouteFlipPulse.Trigger
        let previousActionPrompt: String
        let nextActionPrompt: String
        let routeScoreDelta: Int?
        let confidenceDeltaPoints: Int?
    }

    struct FameMomentumPanelRouteFlipRhythm: Equatable {
        enum Tone: Equatable {
            case stabilizing
            case watch
            case volatile
        }

        let tone: Tone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let flipCount: Int
        let openSpan: Int
        let averageAbsRouteScoreDelta: Int?
        let averageAbsConfidenceDeltaPoints: Int?
    }

    struct RecommendationPairPerformance: Equatable {
        let opportunities: Int
        let conversions: Int
    }

    private let defaults: UserDefaults
    private let launchRecoveryHotKeyInterventionScoresStorageKey: String?
    private let fameMomentumPanelActionScoresStorageKey: String?
    @Published private(set) var openCount = 0
    @Published private(set) var topPickRunStreak = 0
    @Published private(set) var bestTopPickRunStreak = 0
    @Published private(set) var launchRecoveryHotKeyDirectStreak = 0
    @Published private(set) var launchRecoveryHotKeyBestDirectStreak = 0
    @Published private(set) var lastTopPickMilestone = 0
    @Published private(set) var topPickMilestoneEvent = 0
    @Published private(set) var cadenceExecutionKitMomentumPulseEvent = 0
    @Published private(set) var cadenceExecutionKitMomentumPulse: CommandPaletteCadenceExecutionKitStreak
        .MomentumPulse?
    @Published private(set) var launchRecoveryHotKeyRestorePulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyRestorePulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyRestorePulse?
    @Published private(set) var launchRecoveryHotKeyDecayPulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyDecayPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyDecayPulse?
    @Published private(set) var launchRecoveryHotKeyConfidencePulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyConfidencePulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyConfidencePulse?
    @Published private(set) var launchRecoveryHotKeyMomentumPulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyMomentumPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyMomentumPulse?
    @Published private(set) var launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse?
    @Published private(set) var launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse?
    @Published private(set) var launchRecoveryHotKeyLegendRiskStickyReleasePulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyLegendRiskStickyReleasePulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyLegendRiskStickyReleasePulse?
    @Published private(set) var launchRecoveryHotKeyInterventionTrustPulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyInterventionTrustPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustPulse?
    @Published private(set) var launchRecoveryHotKeyInterventionTrustMomentumPulseEvent = 0
    @Published private(set) var launchRecoveryHotKeyInterventionTrustMomentumPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustMomentumPulse?
    @Published private(set) var launchRecoveryHotKeyInterventionScores: [String: Int] = [:]
    @Published private(set) var fameMomentumPanelActionScores: [String: Int] = [:]
    @Published private(set) var fameMomentumPanelOpportunityCount = 0
    @Published private(set) var fameMomentumPanelConversionCount = 0
    @Published private(set) var fameMomentumPanelLearningPulseEvent = 0
    @Published private(set) var fameMomentumPanelLearningPulse: FameMomentumPanelLearningPulse?
    @Published private(set) var fameMomentumPanelRouteFlipPulseEvent = 0
    @Published private(set) var fameMomentumPanelRouteFlipPulse: FameMomentumPanelRouteFlipPulse?
    @Published private(set) var fameMomentumPanelRouteStabilizationPulseEvent = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationPulse: FameMomentumPanelRouteStabilizationPulse?
    @Published private(set) var fameMomentumPanelRouteStabilizationRunCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationSuccessCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationPendingRunCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationResetCueCountToday = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount = 0
    @Published private(set) var fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount = 0
    @Published private(set) var
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory: [Int] = []
    @Published private(set) var
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore = 0
    @Published private(set) var
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount = 0
    @Published private(set) var fameMomentumPanelRouteFlipHistory: [FameMomentumPanelRouteFlipHistoryEntry]
        = []
    @Published private(set) var launchRecoveryHotKeyInterventionTrustHistory: [Int] = []
    @Published private(set) var launchRecoveryHotKeyReadinessHistory: [CommandPaletteTopPicks
        .LaunchRecoveryHotKeyReadinessState] = []
    @Published private(set) var bestChannelLaunchPackPressureOpportunities = 0
    @Published private(set) var bestChannelLaunchPackPressureConversions = 0
    @Published private(set) var bestChannelLaunchPackPressureConversionStreak = 0
    @Published private(set) var bestChannelLaunchPackPressureBestStreak = 0
    @Published private(set) var bestChannelLaunchPackPressureLastTone: CommandPaletteTopPicks
        .BestChannelLaunchPackPressureTone?
    @Published private(set) var recommendationConversionOpportunities = 0
    @Published private(set) var recommendationConversionCount = 0
    @Published private(set) var recommendationConversionOpenStreak = 0
    @Published private(set) var recommendationConversionBestOpenStreak = 0
    @Published private(set) var recommendationMomentumRescueStreak = 0
    @Published private(set) var recommendationMomentumRescueBestStreak = 0
    @Published private(set) var recommendationMomentumRescueRunsToday = 0
    @Published private(set) var recommendationMomentumRescueBestDayRuns = 0
    @Published private(set) var recommendationMomentumRescueRunsThisWeek = 0
    @Published private(set) var recommendationMomentumRescueBestWeekRuns = 0
    @Published private(set) var recommendationMomentumRescuePreviousWeekRuns = 0
    @Published private(set) var recommendationConversionPairOpportunities: [String: Int] = [:]
    @Published private(set) var recommendationConversionPairConversions: [String: Int] = [:]
    private var recommendationConversionPairLastConversionOpenCount: [String: Int] = [:]
    @Published private(set) var recommendationConversionPulseEvent = 0
    @Published private(set) var recommendationConversionPulse: RecommendationConversionPulse?
    @Published private(set) var recommendationMomentumRescuePulseEvent = 0
    @Published private(set) var recommendationMomentumRescuePulse: RecommendationMomentumRescuePulse?
    @Published private(set) var recommendationMomentumRescueWeeklyRecordPulseEvent = 0
    @Published private(set) var recommendationMomentumRescueWeeklyRecordPulse:
        RecommendationMomentumRescueWeeklyRecordPulse?
    @Published private(set) var recommendationMomentumRescueImpactPulseEvent = 0
    @Published private(set) var recommendationMomentumRescueImpactPulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueImpactPulse?
    @Published private(set) var recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseEvent = 0
    @Published private(set) var
        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse?
    @Published private(set) var recommendationMomentumRescueHallOfFameLegendRiskPulseEvent = 0
    @Published private(set) var recommendationMomentumRescueHallOfFameLegendRiskPulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameLegendRiskPulse?
    @Published private(set) var recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEvent = 0
    @Published private(set) var recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse:
        CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse?
    private var cadenceExecutionKitMomentumPulseAt: Date?
    private var launchRecoveryHotKeyRestorePulseAt: Date?
    private var launchRecoveryHotKeyDecayPulseAt: Date?
    private var launchRecoveryHotKeyConfidencePulseAt: Date?
    private var launchRecoveryHotKeyMomentumPulseAt: Date?
    private var launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseAt: Date?
    private var launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseAt: Date?
    private var launchRecoveryHotKeyLegendRiskStickyReleasePulseAt: Date?
    private var launchRecoveryHotKeyInterventionTrustPulseAt: Date?
    private var launchRecoveryHotKeyInterventionTrustMomentumPulseAt: Date?
    private var recommendationConversionPulseAt: Date?
    private var recommendationMomentumRescuePulseAt: Date?
    private var recommendationMomentumRescueWeeklyRecordPulseAt: Date?
    private var recommendationMomentumRescueImpactPulseAt: Date?
    private var recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseAt: Date?
    private var recommendationMomentumRescueHallOfFameLegendRiskPulseAt: Date?
    private var recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseAt: Date?
    private var fameMomentumPanelLearningPulseAt: Date?
    private var fameMomentumPanelRouteFlipPulseAt: Date?
    private var fameMomentumPanelRouteStabilizationPulseAt: Date?
    private var lastLaunchRecoveryHotKeyReadinessOpenCount = -1
    private var lastLaunchRecoveryHotKeyCoachCueOpenCount = -1
    private var lastLaunchRecoveryHotKeyConfidenceScoreOpenCount = -1
    private var lastLaunchRecoveryHotKeyMomentumPulseOpenCount = -1
    private var lastLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastOpenCount = -1
    private var lastRecommendationMomentumRescueHallOfFameLegendRiskForecastOpenCount = -1
    private var launchRecoveryHotKeyCoachCueStreak = 0
    private var launchRecoveryHotKeyPendingInterventionActionID: String?
    private var launchRecoveryHotKeyPendingInterventionOpenCount = -1
    private var launchRecoveryHotKeyPendingInterventionBaselineTier: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyConfidenceScore.Tier?
    private var launchRecoveryHotKeyPendingInterventionBaselinePoints: Int?
    private var launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount: [String: Int] = [:]
    private var fameMomentumPanelActionScoreLastUpdatedOpenCount: [String: Int] = [:]
    private var lastLaunchRecoveryHotKeyInterventionTrustSnapshotOpenCount = -1
    private var lastLaunchRecoveryHotKeyInterventionTrustPulseOpenCount = -1
    private var lastLaunchRecoveryHotKeyInterventionTrustMomentumPulseOpenCount = -1
    private var launchRecoveryHotKeyLastConfidenceTier: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyConfidenceScore.Tier?
    private var launchRecoveryHotKeyLastConfidencePoints: Int?
    private var launchRecoveryHotKeyLastMomentum: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyMomentum?
    private var launchRecoveryHotKeyLastLegendDecayForecast: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast?
    private var recommendationMomentumRescueHallOfFameLastLegendRiskForecast: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameLegendRiskForecast?
    private var launchRecoveryHotKeyLegendRiskStickyPromotedActionID: String?
    private var launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount = 0
    private var launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered = false
    private var recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID: String?
    private var recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount = 0
    private var recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered = false
    private var bestChannelLaunchPackPressureOpportunityOpenCount = -1
    private var bestChannelLaunchPackPressureConversionOpenCount = -1
    private var recommendationOpportunityOpenCount = -1
    private var recommendationPairOpportunityOpenCount: [String: Int] = [:]
    private var didRecordRecommendationConversionInCurrentOpen = false
    private var fameMomentumPanelOpportunityOpenCount = -1
    private var fameMomentumPanelOpportunityActionIDs: Set<String> = []
    private var didRecordFameMomentumPanelConversionInCurrentOpen = false
    private var lastFameMomentumPanelPrimaryActionID: String?
    private var lastFameMomentumPanelPrimaryActionPrompt: String?
    private var lastFameMomentumPanelPrimaryActionScore: Int?
    private var lastFameMomentumPanelPrimaryActionGapPoints: Int?
    private var lastFameMomentumPanelPrimaryActionSignalAgeOpens: Int?
    private var fameMomentumPanelRouteVolatileStreak = 0
    private var fameMomentumPanelRouteVolatilityEvaluatedOpenCount = -1
    private var fameMomentumPanelRouteStabilizationPulseOpenCount = -1
    private var fameMomentumPanelRouteFlipTotalCount = 0
    private var fameMomentumPanelRouteStabilizationResetCueDayStamp: String?
    private var fameMomentumPanelRouteStabilizationResetCueRecordedOpenCount = -1
    private var fameMomentumPanelRouteStabilizationRecoverySuggestionRecordedOpenCount = -1
    private var fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceRecordedOpenCount =
        -1
    private var fameMomentumPanelPrimaryActionRecordedOpenCount = -1
    private var fameMomentumPanelPrimaryActionRecordedActionIDInOpen: String?
    private var fameMomentumPanelRouteStabilizationPendingRuns: [FameMomentumPanelRouteStabilizationPendingRun]
        = []
    private var didRecordRecommendationMomentumRescueInCurrentOpen = false
    private var recommendationMomentumRescueLeaderboardDayStamp: String?
    private var recommendationMomentumRescueLeaderboardWeekStamp: String?

    private struct FameMomentumPanelRouteStabilizationPendingRun: Equatable {
        let runOpenCount: Int
        let evaluateAfterOpenCount: Int
        let baselineFlipTotalCount: Int
        let baselineVolatileStreak: Int
    }

    init(
        defaults: UserDefaults = .standard,
        launchRecoveryHotKeyInterventionScoresStorageKey: String? = nil,
        fameMomentumPanelActionScoresStorageKey: String? = nil
    ) {
        self.defaults = defaults
        let normalizedStorageKey = launchRecoveryHotKeyInterventionScoresStorageKey?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedStorageKey, !normalizedStorageKey.isEmpty {
            self.launchRecoveryHotKeyInterventionScoresStorageKey = normalizedStorageKey
            let persistedScores = Self.loadLaunchRecoveryHotKeyInterventionScores(
                from: defaults,
                key: normalizedStorageKey
            )
            launchRecoveryHotKeyInterventionScores = persistedScores
            launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount = Dictionary(
                uniqueKeysWithValues: persistedScores.keys.map { ($0, 0) }
            )
        } else {
            self.launchRecoveryHotKeyInterventionScoresStorageKey = nil
        }

        let normalizedFameMomentumStorageKey = fameMomentumPanelActionScoresStorageKey?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedFameMomentumStorageKey, !normalizedFameMomentumStorageKey.isEmpty {
            self.fameMomentumPanelActionScoresStorageKey = normalizedFameMomentumStorageKey
            let persistedScores = Self.loadFameMomentumPanelActionScores(
                from: defaults,
                key: normalizedFameMomentumStorageKey
            )
            fameMomentumPanelActionScores = persistedScores
            fameMomentumPanelActionScoreLastUpdatedOpenCount = Dictionary(
                uniqueKeysWithValues: persistedScores.keys.map { ($0, 0) }
            )
        } else {
            self.fameMomentumPanelActionScoresStorageKey = nil
        }

        persistLaunchRecoveryHotKeyInterventionScoresIfNeeded()
        persistFameMomentumPanelActionScoresIfNeeded()

        fameMomentumPanelOpportunityCount = max(
            0,
            defaults.integer(forKey: AppDefaults.fameMomentumPanelOpportunityCountKey)
        )
        fameMomentumPanelConversionCount = min(
            fameMomentumPanelOpportunityCount,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameMomentumPanelConversionCountKey)
            )
        )
        fameMomentumPanelRouteStabilizationRunCount = max(
            0,
            defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey)
        )
        fameMomentumPanelRouteStabilizationSuccessCount = min(
            fameMomentumPanelRouteStabilizationRunCount,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey)
            )
        )
        fameMomentumPanelRouteStabilizationResetCueDayStamp = defaults.string(
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueDayStampKey
        )
        fameMomentumPanelRouteStabilizationResetCueCountToday = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeRunsToday(
                dayStamp: fameMomentumPanelRouteStabilizationResetCueDayStamp,
                storedCount: max(
                    0,
                    defaults.integer(
                        forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueCountTodayKey
                    )
                )
            )
        fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
            )
        )
        let persistedRecoverySuggestionLegacyRunCount = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
            )
        )
        var persistedRecoverySuggestionRecoveryRunCount = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
            )
        )
        var persistedRecoverySuggestionUnblockRunCount = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
            )
        )
        let persistedRecoverySuggestionSplitRunCount = max(
            0,
            persistedRecoverySuggestionRecoveryRunCount + persistedRecoverySuggestionUnblockRunCount
        )
        let resolvedRecoverySuggestionRunCount = min(
            fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
            max(
                persistedRecoverySuggestionLegacyRunCount,
                persistedRecoverySuggestionSplitRunCount
            )
        )
        if persistedRecoverySuggestionSplitRunCount <= 0,
           resolvedRecoverySuggestionRunCount > 0 {
            persistedRecoverySuggestionRecoveryRunCount = resolvedRecoverySuggestionRunCount
            persistedRecoverySuggestionUnblockRunCount = 0
        } else {
            persistedRecoverySuggestionRecoveryRunCount = min(
                resolvedRecoverySuggestionRunCount,
                persistedRecoverySuggestionRecoveryRunCount
            )
            persistedRecoverySuggestionUnblockRunCount = min(
                max(0, resolvedRecoverySuggestionRunCount - persistedRecoverySuggestionRecoveryRunCount),
                persistedRecoverySuggestionUnblockRunCount
            )
        }
        fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount =
            resolvedRecoverySuggestionRunCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount =
            persistedRecoverySuggestionRecoveryRunCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount =
            persistedRecoverySuggestionUnblockRunCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
            )
        )
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory = Self
            .loadFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory(
                from: defaults,
                key: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey,
                limit: Self
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryLimit
            )
        let normalizedRecoverySuggestionPressureCalibration = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: defaults.integer(
                    forKey: AppDefaults
                        .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
                ),
                sampleCount: defaults.integer(
                    forKey: AppDefaults
                        .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
                )
            )
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore =
            normalizedRecoverySuggestionPressureCalibration.score
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount =
            normalizedRecoverySuggestionPressureCalibration.sampleCount
        persistFameMomentumPanelTelemetrySnapshot()

        launchRecoveryHotKeyReadinessHistory = Self.loadLaunchRecoveryHotKeyReadinessHistory(
            from: defaults,
            key: AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey,
            limit: Self.launchRecoveryHotKeyReadinessPersistenceLimit
        )
        launchRecoveryHotKeyDirectStreak = max(
            0,
            defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyDirectStreakKey)
        )
        launchRecoveryHotKeyBestDirectStreak = max(
            launchRecoveryHotKeyDirectStreak,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyBestDirectStreakKey)
            )
        )
        bestChannelLaunchPackPressureOpportunities = max(
            0,
            defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureOpportunitiesKey)
        )
        bestChannelLaunchPackPressureConversions = min(
            bestChannelLaunchPackPressureOpportunities,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureConversionsKey)
            )
        )
        bestChannelLaunchPackPressureConversionStreak = min(
            bestChannelLaunchPackPressureConversions,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureConversionStreakKey)
            )
        )
        bestChannelLaunchPackPressureBestStreak = max(
            bestChannelLaunchPackPressureConversionStreak,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameBestChannelLaunchPackPressureBestStreakKey)
            )
        )
        bestChannelLaunchPackPressureLastTone = Self.bestChannelLaunchPackPressureTone(
            token: defaults.string(forKey: AppDefaults.fameBestChannelLaunchPackPressureLastToneKey)
        )
        recommendationConversionOpportunities = max(
            0,
            defaults.integer(forKey: AppDefaults.fameRecommendationConversionOpportunitiesKey)
        )
        recommendationConversionCount = min(
            recommendationConversionOpportunities,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameRecommendationConversionCountKey)
            )
        )
        recommendationConversionBestOpenStreak = min(
            recommendationConversionCount,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameRecommendationConversionBestOpenStreakKey)
            )
        )
        recommendationMomentumRescueStreak = max(
            0,
            defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueStreakKey)
        )
        recommendationMomentumRescueBestStreak = max(
            recommendationMomentumRescueStreak,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueBestStreakKey)
            )
        )
        recommendationMomentumRescueLeaderboardDayStamp = defaults.string(
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardDayStampKey
        )
        recommendationMomentumRescueRunsToday = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: recommendationMomentumRescueLeaderboardDayStamp,
            storedCount: defaults.integer(
                forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsTodayKey
            )
        )
        recommendationMomentumRescueBestDayRuns = max(
            recommendationMomentumRescueRunsToday,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestDayRunsKey)
            )
        )
        let storedRecommendationMomentumRescueLeaderboardWeekStamp = defaults.string(
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardWeekStampKey
        )
        let storedRecommendationMomentumRescueRunsThisWeek = max(
            0,
            defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsThisWeekKey)
        )
        let storedRecommendationMomentumRescueBestWeekRuns = max(
            0,
            defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestWeekRunsKey)
        )
        let storedRecommendationMomentumRescuePreviousWeekRuns = max(
            0,
            defaults.integer(forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardPreviousWeekRunsKey)
        )
        recommendationMomentumRescueLeaderboardWeekStamp = storedRecommendationMomentumRescueLeaderboardWeekStamp
        recommendationMomentumRescueRunsThisWeek = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
                weekStamp: storedRecommendationMomentumRescueLeaderboardWeekStamp,
                storedCount: storedRecommendationMomentumRescueRunsThisWeek
            )
        recommendationMomentumRescueBestWeekRuns = max(
            storedRecommendationMomentumRescueBestWeekRuns,
            max(
                recommendationMomentumRescueRunsThisWeek,
                storedRecommendationMomentumRescueRunsThisWeek
            )
        )
        let currentWeekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp()
        if let storedRecommendationMomentumRescueLeaderboardWeekStamp,
           storedRecommendationMomentumRescueLeaderboardWeekStamp != currentWeekStamp,
           storedRecommendationMomentumRescueRunsThisWeek > 0 {
            recommendationMomentumRescuePreviousWeekRuns = storedRecommendationMomentumRescueRunsThisWeek
        } else {
            recommendationMomentumRescuePreviousWeekRuns = storedRecommendationMomentumRescuePreviousWeekRuns
        }
        recommendationConversionPairOpportunities = Self.loadRecommendationPairMetrics(
            from: defaults,
            key: AppDefaults.fameRecommendationConversionPairOpportunitiesKey
        )
        recommendationConversionPairConversions = Self.loadRecommendationPairMetrics(
            from: defaults,
            key: AppDefaults.fameRecommendationConversionPairConversionsKey
        )
        recommendationConversionPairLastConversionOpenCount = Self.loadRecommendationPairMetrics(
            from: defaults,
            key: AppDefaults.fameRecommendationConversionPairLastConversionOpenCountKey
        )
        persistLaunchRecoveryHotKeyReadinessSnapshot(
            limit: Self.launchRecoveryHotKeyReadinessPersistenceLimit
        )
        persistBestChannelLaunchPackPressureSnapshot()
        persistRecommendationConversionSnapshot()
        persistRecommendationPairSnapshot()
    }

    func beginOpen() {
        resetBestChannelLaunchPackPressureConversionStreakIfNeededForPreviousOpen()
        resetRecommendationConversionOpenStreakIfNeededForPreviousOpen()
        resetRecommendationMomentumRescueStreakIfNeededForPreviousOpen()
        resetRecommendationMomentumRescueDailyCountIfNeeded()
        resetRecommendationMomentumRescueWeeklyCountIfNeeded()
        resetFameMomentumPanelRouteStabilizationResetCueCountIfNeeded()
        finalizeFameMomentumPanelOpportunityForPreviousOpen()
        decayFameMomentumPanelActionScoresIfNeeded()
        decayFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationIfNeeded()
        openCount += 1
        didRecordRecommendationConversionInCurrentOpen = false
        didRecordFameMomentumPanelConversionInCurrentOpen = false
        didRecordRecommendationMomentumRescueInCurrentOpen = false
        decayLaunchRecoveryHotKeyInterventionScoresIfNeeded()
        recordLaunchRecoveryHotKeyInterventionTrustSnapshot()
        resolveFameMomentumPanelRouteStabilizationOutcomesIfNeeded()
    }

    func recordRun(wasTopPick: Bool) {
        if wasTopPick {
            topPickRunStreak += 1
            bestTopPickRunStreak = max(bestTopPickRunStreak, topPickRunStreak)

            if let milestone = Self.milestone(for: topPickRunStreak) {
                lastTopPickMilestone = milestone
                topPickMilestoneEvent += 1
            }
        } else {
            topPickRunStreak = 0
        }
    }

    @discardableResult
    func recordFameMomentumPanelOpportunity(actionID: String?) -> Bool {
        recordFameMomentumPanelOpportunity(actionIDs: [actionID])
    }

    @discardableResult
    func recordFameMomentumPanelOpportunity(actionIDs: [String?]) -> Bool {
        guard openCount > 0 else { return false }
        let normalizedActionIDs = Set(actionIDs.compactMap(Self.normalizedFameMomentumPanelActionID))

        if fameMomentumPanelOpportunityOpenCount == openCount {
            if fameMomentumPanelOpportunityActionIDs != normalizedActionIDs {
                fameMomentumPanelOpportunityActionIDs = normalizedActionIDs
            }
            return false
        }

        fameMomentumPanelOpportunityOpenCount = openCount
        fameMomentumPanelOpportunityActionIDs = normalizedActionIDs
        didRecordFameMomentumPanelConversionInCurrentOpen = false
        fameMomentumPanelOpportunityCount += 1
        persistFameMomentumPanelTelemetrySnapshot()
        return true
    }

    func recordFameMomentumPanelPrimarySuggestion(
        actionID: String?,
        actionPrompt: String?,
        actionScore: Int? = nil,
        reasonChips: [CommandPaletteTopPicks.FameMomentumPanelReasonChip] = [],
        selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence? = nil,
        actionRecency: CommandPaletteTopPicks.FameMomentumPanelActionRecency? = nil,
        at date: Date = Date()
    ) {
        guard openCount > 0 else { return }
        let normalizedActionID = Self.normalizedFameMomentumPanelActionID(actionID)
        let normalizedActionPrompt = Self.normalizedFameMomentumPanelRoutePrompt(actionPrompt)
        let normalizedActionScore = actionScore
        let currentGapPoints = selectionConfidence?.gapPoints
        let currentSignalAgeOpens = Self.fameMomentumPanelActionRecencyOpensAgo(actionRecency)

        if fameMomentumPanelPrimaryActionRecordedOpenCount == openCount,
           fameMomentumPanelPrimaryActionRecordedActionIDInOpen == normalizedActionID {
            return
        }
        fameMomentumPanelPrimaryActionRecordedOpenCount = openCount
        fameMomentumPanelPrimaryActionRecordedActionIDInOpen = normalizedActionID

        if let previousActionID = lastFameMomentumPanelPrimaryActionID,
           let normalizedActionID,
           previousActionID != normalizedActionID {
            let previousPrompt = Self.resolvedFameMomentumPanelRoutePrompt(
                lastFameMomentumPanelPrimaryActionPrompt,
                fallback: "Previous Route"
            )
            let nextPrompt = Self.resolvedFameMomentumPanelRoutePrompt(
                normalizedActionPrompt,
                fallback: "New Route"
            )
            let routeFlipPulse = Self.fameMomentumPanelRouteFlipPulse(
                previousPrompt: previousPrompt,
                nextPrompt: nextPrompt,
                previousActionScore: lastFameMomentumPanelPrimaryActionScore,
                nextActionScore: normalizedActionScore,
                previousGapPoints: lastFameMomentumPanelPrimaryActionGapPoints,
                nextGapPoints: currentGapPoints,
                previousSignalAgeOpens: lastFameMomentumPanelPrimaryActionSignalAgeOpens,
                nextSignalAgeOpens: currentSignalAgeOpens,
                reasonChips: reasonChips,
                selectionConfidence: selectionConfidence
            )
            fameMomentumPanelRouteFlipPulse = routeFlipPulse
            fameMomentumPanelRouteFlipPulseAt = date
            fameMomentumPanelRouteFlipPulseEvent += 1
            appendFameMomentumPanelRouteFlipHistory(
                routeFlipPulse,
                at: date,
                openCount: openCount
            )
        }

        guard let normalizedActionID else { return }
        lastFameMomentumPanelPrimaryActionID = normalizedActionID
        lastFameMomentumPanelPrimaryActionPrompt = normalizedActionPrompt
        lastFameMomentumPanelPrimaryActionScore = normalizedActionScore
        lastFameMomentumPanelPrimaryActionGapPoints = currentGapPoints
        lastFameMomentumPanelPrimaryActionSignalAgeOpens = currentSignalAgeOpens
        evaluateFameMomentumPanelRouteVolatilityForCurrentOpen(at: date)
        resolveFameMomentumPanelRouteStabilizationOutcomesIfNeeded()
    }

    private func appendFameMomentumPanelRouteFlipHistory(
        _ pulse: FameMomentumPanelRouteFlipPulse,
        at date: Date,
        openCount: Int
    ) {
        let entry = FameMomentumPanelRouteFlipHistoryEntry(
            openCount: max(0, openCount),
            occurredAt: date,
            trigger: pulse.trigger,
            previousActionPrompt: pulse.previousActionPrompt,
            nextActionPrompt: pulse.nextActionPrompt,
            routeScoreDelta: pulse.routeScoreDelta,
            confidenceDeltaPoints: pulse.confidenceDeltaPoints
        )
        fameMomentumPanelRouteFlipTotalCount += 1
        fameMomentumPanelRouteFlipHistory.insert(entry, at: 0)
        if fameMomentumPanelRouteFlipHistory.count > Self.fameMomentumPanelRouteFlipHistoryLimit {
            fameMomentumPanelRouteFlipHistory.removeLast(
                fameMomentumPanelRouteFlipHistory.count - Self.fameMomentumPanelRouteFlipHistoryLimit
            )
        }
    }

    private func evaluateFameMomentumPanelRouteVolatilityForCurrentOpen(at date: Date) {
        guard openCount > 0 else { return }
        guard fameMomentumPanelRouteVolatilityEvaluatedOpenCount != openCount else { return }
        fameMomentumPanelRouteVolatilityEvaluatedOpenCount = openCount

        guard let rhythm = fameMomentumPanelRouteFlipRhythm() else {
            fameMomentumPanelRouteVolatileStreak = 0
            return
        }

        if rhythm.tone == .volatile {
            fameMomentumPanelRouteVolatileStreak += 1
        } else {
            fameMomentumPanelRouteVolatileStreak = 0
            return
        }

        let streakThreshold = max(1, Self.fameMomentumPanelRouteStabilizationPulseVolatileStreakThreshold)
        guard fameMomentumPanelRouteVolatileStreak >= streakThreshold else { return }

        let cooldownOpenInterval = max(1, Self.fameMomentumPanelRouteStabilizationPulseCooldownOpenInterval)
        let opensSinceLastPulse = max(
            0,
            openCount - max(0, fameMomentumPanelRouteStabilizationPulseOpenCount)
        )
        if fameMomentumPanelRouteStabilizationPulseOpenCount >= 0,
           opensSinceLastPulse < cooldownOpenInterval {
            return
        }

        fameMomentumPanelRouteStabilizationPulse = Self.fameMomentumPanelRouteStabilizationPulse(
            rhythm: rhythm,
            volatileStreak: fameMomentumPanelRouteVolatileStreak
        )
        fameMomentumPanelRouteStabilizationPulseAt = date
        fameMomentumPanelRouteStabilizationPulseOpenCount = openCount
        fameMomentumPanelRouteStabilizationPulseEvent += 1
    }

    func recordFameMomentumPanelRouteStabilizationRun() {
        guard openCount > 0 else { return }
        fameMomentumPanelRouteStabilizationRunCount += 1
        let pendingRun = FameMomentumPanelRouteStabilizationPendingRun(
            runOpenCount: openCount,
            evaluateAfterOpenCount: openCount + 1,
            baselineFlipTotalCount: fameMomentumPanelRouteFlipTotalCount,
            baselineVolatileStreak: max(0, fameMomentumPanelRouteVolatileStreak)
        )
        fameMomentumPanelRouteStabilizationPendingRuns.append(pendingRun)
        fameMomentumPanelRouteStabilizationPendingRunCount = fameMomentumPanelRouteStabilizationPendingRuns.count
        persistFameMomentumPanelTelemetrySnapshot()
    }

    private func recordFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceSnapshotIfNeeded(
        sampleLimit: Int = PaletteSession
            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryLimit
    ) {
        guard openCount > 0 else { return }
        let pressureCalibration = fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration
        guard let pressureBadge = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                shownCount: fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                blockedCount: fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount,
                recoveryRunCount: fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount,
                unblockRunCount: fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount,
                pressureConfidenceHistory:
                    fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
                pressureCalibration: pressureCalibration
            ) else {
            return
        }

        let normalizedSampleLimit = max(1, sampleLimit)
        if fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceRecordedOpenCount == openCount {
            if fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.isEmpty {
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory = [
                    pressureBadge.confidencePercent
                ]
            } else {
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory[
                    fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.count - 1
                ] = pressureBadge.confidencePercent
            }
        } else {
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.append(
                pressureBadge.confidencePercent
            )
            if fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory.count
                > normalizedSampleLimit {
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
                    .removeFirst(
                        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
                            .count - normalizedSampleLimit
                    )
            }
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceRecordedOpenCount = openCount
        }

        updateFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
            pressureBadge: pressureBadge
        )
    }

    private func decayFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationIfNeeded() {
        let normalizedCalibration = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
                sampleCount: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
            )
        guard normalizedCalibration.sampleCount > 0 else {
            guard fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore != 0
                    || fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
                        != 0 else {
                return
            }
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore = 0
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount = 0
            persistFameMomentumPanelTelemetrySnapshot()
            return
        }

        let lastPressureConfidenceRecordedOpenCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceRecordedOpenCount
        )
        let idleOpenCount = max(0, openCount - lastPressureConfidenceRecordedOpenCount)
        guard idleOpenCount > 0 else { return }

        let scoreDecayInterval = max(
            1,
            Self
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreIdleDecayOpenInterval
        )
        let sampleDecayInterval = max(
            scoreDecayInterval,
            Self
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleIdleDecayOpenInterval
        )
        let shouldDecayScore = idleOpenCount % scoreDecayInterval == 0
        let shouldDecaySample = idleOpenCount % sampleDecayInterval == 0
        guard shouldDecayScore || shouldDecaySample else { return }

        var decayedScore = normalizedCalibration.score
        if shouldDecayScore {
            if decayedScore > 0 {
                decayedScore -= 1
            } else if decayedScore < 0 {
                decayedScore += 1
            }
        }

        var decayedSampleCount = normalizedCalibration.sampleCount
        if shouldDecaySample {
            decayedSampleCount = max(0, decayedSampleCount - 1)
        }
        if decayedSampleCount <= 0 {
            decayedScore = 0
        }

        let normalizedDecayedCalibration = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: decayedScore,
                sampleCount: decayedSampleCount
            )
        guard normalizedDecayedCalibration.score
                != fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore
                || normalizedDecayedCalibration.sampleCount
                != fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
        else {
            return
        }
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore =
            normalizedDecayedCalibration.score
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount =
            normalizedDecayedCalibration.sampleCount
        persistFameMomentumPanelTelemetrySnapshot()
    }

    private func updateFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
        pressureBadge: CommandPaletteTopPicks
            .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge
    ) {
        let normalizedShownCount = max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount)
        guard normalizedShownCount > 0 else { return }

        let normalizedBlockedCount = max(
            0,
            min(
                normalizedShownCount,
                fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount
            )
        )
        let normalizedRecoveryRunCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount
        )
        let normalizedUnblockRunCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount
        )
        let normalizedRunCount = max(0, normalizedRecoveryRunCount + normalizedUnblockRunCount)
        let blockedRate = Double(normalizedBlockedCount) / Double(max(1, normalizedShownCount))
        let unblockCoverage = Double(normalizedUnblockRunCount) / Double(max(1, normalizedRunCount))

        let calibrationSignal: Int
        switch pressureBadge.tone {
        case .alert:
            calibrationSignal = 2
        case .watch:
            if blockedRate >= 0.35,
               normalizedRunCount > 0,
               unblockCoverage <= 0.30 {
                calibrationSignal = 1
            } else if blockedRate <= 0.20,
                      unblockCoverage >= 0.45 {
                calibrationSignal = -1
            } else {
                calibrationSignal = 0
            }
        case .steady:
            calibrationSignal = unblockCoverage >= 0.35 ? -1 : 0
        }

        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount += 1
        if calibrationSignal != 0 {
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore += calibrationSignal
        } else if fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount % 9 == 0 {
            if fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore > 0 {
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore -= 1
            } else if fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore < 0 {
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore += 1
            }
        }

        let normalizedCalibration = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
                sampleCount: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
            )
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore =
            normalizedCalibration.score
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount =
            normalizedCalibration.sampleCount
    }

    @discardableResult
    func recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
        action: CommandPaletteAction?
    ) -> Bool {
        guard openCount > 0 else { return false }
        guard fameMomentumPanelRouteStabilizationRecoverySuggestionRecordedOpenCount != openCount else {
            return false
        }
        fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount += 1
        if action?.isEnabled != true {
            fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount += 1
        }
        fameMomentumPanelRouteStabilizationRecoverySuggestionRecordedOpenCount = openCount
        recordFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceSnapshotIfNeeded()
        persistFameMomentumPanelTelemetrySnapshot()
        return true
    }

    @discardableResult
    func recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun(
        usedUnblockAction: Bool = false
    ) -> Bool {
        guard openCount > 0 else { return false }
        fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount += 1
        if usedUnblockAction {
            fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount += 1
        } else {
            fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount += 1
        }
        recordFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceSnapshotIfNeeded()
        persistFameMomentumPanelTelemetrySnapshot()
        return true
    }

    private func resolveFameMomentumPanelRouteStabilizationOutcomesIfNeeded() {
        guard !fameMomentumPanelRouteStabilizationPendingRuns.isEmpty else { return }
        let currentOpenCount = max(0, openCount)
        let currentFlipTotalCount = fameMomentumPanelRouteFlipTotalCount
        let currentRhythmTone = fameMomentumPanelRouteFlipRhythm()?.tone
        let didObserveCurrentOpenPrimarySuggestion =
            fameMomentumPanelPrimaryActionRecordedOpenCount == currentOpenCount

        var remainingRuns: [FameMomentumPanelRouteStabilizationPendingRun] = []
        remainingRuns.reserveCapacity(fameMomentumPanelRouteStabilizationPendingRuns.count)
        var successDelta = 0

        for pendingRun in fameMomentumPanelRouteStabilizationPendingRuns {
            let evaluationOpen = max(0, pendingRun.evaluateAfterOpenCount)
            let shouldEvaluate = currentOpenCount > evaluationOpen
                || (currentOpenCount == evaluationOpen && didObserveCurrentOpenPrimarySuggestion)
            guard shouldEvaluate else {
                remainingRuns.append(pendingRun)
                continue
            }

            let didCalmTone = currentRhythmTone != .volatile
            let didAvoidNewFlips = currentFlipTotalCount <= pendingRun.baselineFlipTotalCount
            let didReduceVolatileStreak = fameMomentumPanelRouteVolatileStreak
                < pendingRun.baselineVolatileStreak
            if didCalmTone || didAvoidNewFlips || didReduceVolatileStreak {
                successDelta += 1
            }
        }

        fameMomentumPanelRouteStabilizationPendingRuns = remainingRuns
        fameMomentumPanelRouteStabilizationPendingRunCount = remainingRuns.count
        if successDelta > 0 {
            fameMomentumPanelRouteStabilizationSuccessCount += successDelta
            persistFameMomentumPanelTelemetrySnapshot()
        }
    }

    @discardableResult
    func recordFameMomentumPanelRouteStabilizationResetCueIfNeeded(
        now: Date = Date()
    ) -> Bool {
        guard openCount > 0 else { return false }
        resetFameMomentumPanelRouteStabilizationResetCueCountIfNeeded(now: now)
        guard fameMomentumPanelRouteStabilizationResetCueRecordedOpenCount != openCount else {
            return false
        }
        let recorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: fameMomentumPanelRouteStabilizationResetCueDayStamp,
            storedCount: fameMomentumPanelRouteStabilizationResetCueCountToday,
            now: now
        )
        fameMomentumPanelRouteStabilizationResetCueDayStamp = recorded.dayStamp
        fameMomentumPanelRouteStabilizationResetCueCountToday = recorded.runsToday
        fameMomentumPanelRouteStabilizationResetCueRecordedOpenCount = openCount
        persistFameMomentumPanelTelemetrySnapshot(now: now)
        return true
    }

    @discardableResult
    func recordFameMomentumPanelConversion(
        actionID: String,
        at date: Date = Date()
    ) -> Bool {
        guard openCount > 0 else { return false }
        guard fameMomentumPanelOpportunityOpenCount == openCount else { return false }
        guard !didRecordFameMomentumPanelConversionInCurrentOpen else { return false }
        guard let normalizedActionID = Self.normalizedFameMomentumPanelActionID(actionID),
              fameMomentumPanelOpportunityActionIDs.contains(normalizedActionID) else {
            return false
        }

        didRecordFameMomentumPanelConversionInCurrentOpen = true
        fameMomentumPanelConversionCount += 1
        updateFameMomentumPanelActionScore(
            actionID: normalizedActionID,
            delta: Self.fameMomentumPanelActionScorePositiveDelta
        )
        let skippedAlternativeActionIDs = fameMomentumPanelOpportunityActionIDs
            .subtracting([normalizedActionID])
        for skippedActionID in skippedAlternativeActionIDs {
            updateFameMomentumPanelActionScore(
                actionID: skippedActionID,
                delta: Self.fameMomentumPanelActionScoreSkippedAlternativeDelta
            )
        }
        if !skippedAlternativeActionIDs.isEmpty {
            fameMomentumPanelLearningPulse = Self.fameMomentumPanelLearningPulse(
                cooledAlternativesCount: skippedAlternativeActionIDs.count
            )
            fameMomentumPanelLearningPulseAt = date
            fameMomentumPanelLearningPulseEvent += 1
        }
        persistFameMomentumPanelTelemetrySnapshot(now: date)
        return true
    }

    @discardableResult
    func recordRecommendationOpportunity() -> Bool {
        guard openCount > 0 else { return false }
        guard recommendationOpportunityOpenCount != openCount else { return false }
        recommendationOpportunityOpenCount = openCount
        recommendationConversionOpportunities = Self.incrementSaturating(
            recommendationConversionOpportunities
        )
        persistRecommendationConversionSnapshot()
        return true
    }

    @discardableResult
    func recordRecommendationOpportunity(
        sourceActionID: String,
        recommendedActionID: String
    ) -> Bool {
        guard openCount > 0 else { return false }
        guard let token = Self.recommendationPairToken(
            sourceActionID: sourceActionID,
            recommendedActionID: recommendedActionID
        ) else {
            return false
        }
        guard recommendationPairOpportunityOpenCount[token] != openCount else {
            return false
        }
        recommendationPairOpportunityOpenCount[token] = openCount
        recommendationConversionPairOpportunities[token] = Self.incrementSaturating(
            recommendationConversionPairOpportunities[token] ?? 0
        )
        persistRecommendationPairSnapshot()
        return true
    }

    func recommendationPairPerformance(
        sourceActionID: String,
        recommendedActionID: String
    ) -> RecommendationPairPerformance? {
        guard let token = Self.recommendationPairToken(
            sourceActionID: sourceActionID,
            recommendedActionID: recommendedActionID
        ) else {
            return nil
        }
        let opportunities = max(
            0,
            recommendationConversionPairOpportunities[token] ?? 0
        )
        guard opportunities > 0 else { return nil }
        let conversions = min(
            opportunities,
            max(0, recommendationConversionPairConversions[token] ?? 0)
        )
        return RecommendationPairPerformance(
            opportunities: opportunities,
            conversions: conversions
        )
    }

    func recommendationPairLastConversionOpenCount(
        sourceActionID: String,
        recommendedActionID: String
    ) -> Int? {
        guard let token = Self.recommendationPairToken(
            sourceActionID: sourceActionID,
            recommendedActionID: recommendedActionID
        ) else {
            return nil
        }
        let openCount = max(0, recommendationConversionPairLastConversionOpenCount[token] ?? 0)
        guard openCount > 0 else { return nil }
        return openCount
    }

    func recommendationPairOpensSinceLastConversion(
        sourceActionID: String,
        recommendedActionID: String
    ) -> Int? {
        guard let lastConversionOpenCount = recommendationPairLastConversionOpenCount(
            sourceActionID: sourceActionID,
            recommendedActionID: recommendedActionID
        ) else {
            return nil
        }
        let normalizedOpenCount = max(0, openCount)
        guard normalizedOpenCount > 0 else { return nil }
        return max(0, normalizedOpenCount - lastConversionOpenCount)
    }

    @discardableResult
    func recordRecommendationConversion(
        sourceActionID: String,
        recommendedActionID: String,
        at date: Date = Date()
    ) -> Bool {
        guard openCount > 0 else { return false }
        guard let token = Self.recommendationPairToken(
            sourceActionID: sourceActionID,
            recommendedActionID: recommendedActionID
        ),
        let normalizedPair = Self.recommendationPairToken(from: token) else {
            return false
        }
        let normalizedSourceActionID = normalizedPair.sourceActionID
        let normalizedRecommendedActionID = normalizedPair.recommendedActionID
        guard !didRecordRecommendationConversionInCurrentOpen else {
            return false
        }
        _ = recordRecommendationOpportunity()
        _ = recordRecommendationOpportunity(
            sourceActionID: normalizedSourceActionID,
            recommendedActionID: normalizedRecommendedActionID
        )
        var rescuedPairSnapshot: (
            opportunities: Int,
            conversions: Int,
            opensSinceLastConversion: Int
        )?
        let pairOpportunities = max(
            0,
            recommendationConversionPairOpportunities[token] ?? 0
        )
        let pairConversionsBefore = min(
            pairOpportunities,
            max(0, recommendationConversionPairConversions[token] ?? 0)
        )
        let pairLastConversionOpenCount = max(
            0,
            recommendationConversionPairLastConversionOpenCount[token] ?? 0
        )
        let opensSinceLastConversion = pairLastConversionOpenCount > 0
            ? max(0, openCount - pairLastConversionOpenCount)
            : nil
        let pairWasColdAndHighConfidence = CommandPaletteTopPicks.recommendationPairIsHighConfidence(
            opportunities: pairOpportunities,
            conversionCount: pairConversionsBefore
        ) && (opensSinceLastConversion ?? 0) >= 7

        recommendationConversionPairConversions[token] = Self.incrementSaturating(
            recommendationConversionPairConversions[token] ?? 0
        )
        recommendationConversionPairLastConversionOpenCount[token] = max(1, openCount)
        if pairWasColdAndHighConfidence,
           let opensSinceLastConversion {
            let normalizedConversions = min(
                pairOpportunities,
                max(0, recommendationConversionPairConversions[token] ?? 0)
            )
            rescuedPairSnapshot = (
                opportunities: pairOpportunities,
                conversions: normalizedConversions,
                opensSinceLastConversion: opensSinceLastConversion
            )
        }
        persistRecommendationPairSnapshot()
        recommendationConversionCount = Self.incrementSaturating(recommendationConversionCount)
        let previousBestOpenStreak = recommendationConversionBestOpenStreak
        didRecordRecommendationConversionInCurrentOpen = true
        recommendationConversionOpenStreak = Self.incrementSaturating(recommendationConversionOpenStreak)
        recommendationConversionBestOpenStreak = max(
            recommendationConversionBestOpenStreak,
            recommendationConversionOpenStreak
        )
        if recommendationConversionBestOpenStreak > previousBestOpenStreak {
            let pulse = Self.recommendationConversionPulse(
                openStreak: recommendationConversionBestOpenStreak,
                conversionCount: recommendationConversionCount
            )
            recommendationConversionPulse = pulse
            recommendationConversionPulseAt = date
            recommendationConversionPulseEvent += 1
        }
        if let rescuedPairSnapshot {
            didRecordRecommendationMomentumRescueInCurrentOpen = true
            recordRecommendationMomentumRescueLeaderboardRun(now: date)
            let previousRescueStreak = recommendationMomentumRescueStreak
            let previousBestRescueStreak = recommendationMomentumRescueBestStreak
            recommendationMomentumRescueStreak = Self.incrementSaturating(
                recommendationMomentumRescueStreak
            )
            recommendationMomentumRescueBestStreak = max(
                recommendationMomentumRescueBestStreak,
                recommendationMomentumRescueStreak
            )
            let didSetNewBest = recommendationMomentumRescueBestStreak > previousBestRescueStreak
            let pulse = Self.recommendationMomentumRescuePulse(
                opportunities: rescuedPairSnapshot.opportunities,
                conversionCount: rescuedPairSnapshot.conversions,
                opensSinceLastConversion: rescuedPairSnapshot.opensSinceLastConversion,
                streak: recommendationMomentumRescueStreak,
                bestStreak: recommendationMomentumRescueBestStreak,
                previousStreak: previousRescueStreak,
                didSetNewBest: didSetNewBest
            )
            recommendationMomentumRescuePulse = pulse
            recommendationMomentumRescuePulseAt = date
            recommendationMomentumRescuePulseEvent += 1
        }
        persistRecommendationConversionSnapshot()
        return true
    }

    func recordCadenceExecutionKitMomentumPulse(
        _ pulse: CommandPaletteCadenceExecutionKitStreak.MomentumPulse,
        at date: Date = Date()
    ) {
        cadenceExecutionKitMomentumPulse = pulse
        cadenceExecutionKitMomentumPulseAt = date
        cadenceExecutionKitMomentumPulseEvent += 1
    }

    func recordRecommendationMomentumRescueImpactPulse(
        _ pulse: CommandPaletteTopPicks.RecommendationMomentumRescueImpactPulse,
        at date: Date = Date()
    ) {
        recommendationMomentumRescueImpactPulse = pulse
        recommendationMomentumRescueImpactPulseAt = date
        recommendationMomentumRescueImpactPulseEvent += 1
    }

    func recordRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
        _ pulse: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse,
        at date: Date = Date()
    ) {
        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse = pulse
        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseAt = date
        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseEvent += 1
    }

    @discardableResult
    func recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
        _ forecast: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast?,
        stickyPromotionOpenWindow: Int = AppDefaults
            .fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens,
        stickyPromotionHoldUntilRecovered: Bool = AppDefaults
            .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled,
        at date: Date = Date()
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskPulse? {
        guard openCount > 0 else {
            recommendationMomentumRescueHallOfFameLastLegendRiskForecast = forecast
            return nil
        }
        guard openCount != lastRecommendationMomentumRescueHallOfFameLegendRiskForecastOpenCount else {
            return nil
        }

        let normalizedStickyPromotionOpenWindow =
            AppDefaults
            .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                stickyPromotionOpenWindow
            )

        lastRecommendationMomentumRescueHallOfFameLegendRiskForecastOpenCount = openCount
        let pulse = CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameLegendRiskPulse(
            previousForecast: recommendationMomentumRescueHallOfFameLastLegendRiskForecast,
            nextForecast: forecast
        )
        recommendationMomentumRescueHallOfFameLastLegendRiskForecast = forecast

        if stickyPromotionHoldUntilRecovered,
           forecast == nil {
            if let promotedActionID =
                recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID {
                recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
                        actionID: promotedActionID
                    )
                recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseAt = date
                recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEvent += 1
            }
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID = nil
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount = 0
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered = false
        }

        if let pulse {
            recommendationMomentumRescueHallOfFameLegendRiskPulse = pulse
            recommendationMomentumRescueHallOfFameLegendRiskPulseAt = date
            recommendationMomentumRescueHallOfFameLegendRiskPulseEvent += 1
            if pulse.tone == .alert,
               let promotedActionID = forecast?.actionID {
                recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID = promotedActionID
                recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount =
                    openCount + normalizedStickyPromotionOpenWindow - 1
                recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered =
                    stickyPromotionHoldUntilRecovered
            }
        }

        if stickyPromotionHoldUntilRecovered,
           recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID != nil,
           forecast != nil {
            if let promotedActionID = forecast?.actionID {
                recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID = promotedActionID
            }
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount = max(
                recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount,
                openCount + normalizedStickyPromotionOpenWindow - 1
            )
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered = true
        } else if !stickyPromotionHoldUntilRecovered {
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered = false
        }

        return pulse
    }

    func recordLaunchRecoveryHotKeyReadiness(
        _ readiness: CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness,
        sampleLimit: Int = 12,
        at date: Date = Date()
    ) {
        guard openCount > 0 else { return }
        guard openCount != lastLaunchRecoveryHotKeyReadinessOpenCount else { return }

        lastLaunchRecoveryHotKeyReadinessOpenCount = openCount
        let nextState = CommandPaletteTopPicks.launchRecoveryHotKeyReadinessState(for: readiness)
        if let previousState = launchRecoveryHotKeyReadinessHistory.last,
           previousState != .direct,
           nextState == .direct {
            launchRecoveryHotKeyRestorePulse = CommandPaletteTopPicks.launchRecoveryHotKeyRestorePulse(
                previousState: previousState
            )
            launchRecoveryHotKeyRestorePulseAt = date
            launchRecoveryHotKeyRestorePulseEvent += 1
        }

        if nextState == .direct {
            launchRecoveryHotKeyDirectStreak += 1
            launchRecoveryHotKeyBestDirectStreak = max(
                launchRecoveryHotKeyBestDirectStreak,
                launchRecoveryHotKeyDirectStreak
            )
        } else {
            launchRecoveryHotKeyDirectStreak = 0
        }
        launchRecoveryHotKeyReadinessHistory.append(nextState)

        let normalizedLimit = max(1, sampleLimit)
        if launchRecoveryHotKeyReadinessHistory.count > normalizedLimit {
            launchRecoveryHotKeyReadinessHistory.removeFirst(
                launchRecoveryHotKeyReadinessHistory.count - normalizedLimit
            )
        }
        persistLaunchRecoveryHotKeyReadinessSnapshot(limit: normalizedLimit)
    }

    func launchRecoveryHotKeyReadinessTrend(
        limit: Int = 6
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend? {
        CommandPaletteTopPicks.launchRecoveryHotKeyTrend(
            for: launchRecoveryHotKeyReadinessHistory,
            limit: limit
        )
    }

    @discardableResult
    func recordBestChannelLaunchPackPressureOpportunity(
        tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) -> Bool {
        guard openCount > 0 else { return false }
        guard bestChannelLaunchPackPressureOpportunityOpenCount != openCount else { return false }

        bestChannelLaunchPackPressureOpportunityOpenCount = openCount
        bestChannelLaunchPackPressureLastTone = tone
        bestChannelLaunchPackPressureOpportunities += 1
        persistBestChannelLaunchPackPressureSnapshot()
        return true
    }

    @discardableResult
    func recordBestChannelLaunchPackPressureConversion(
        tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) -> Bool {
        guard openCount > 0 else { return false }
        guard bestChannelLaunchPackPressureOpportunityOpenCount == openCount else { return false }
        guard bestChannelLaunchPackPressureConversionOpenCount != openCount else { return false }

        bestChannelLaunchPackPressureConversionOpenCount = openCount
        bestChannelLaunchPackPressureLastTone = tone
        bestChannelLaunchPackPressureConversions += 1
        bestChannelLaunchPackPressureConversionStreak += 1
        bestChannelLaunchPackPressureBestStreak = max(
            bestChannelLaunchPackPressureBestStreak,
            bestChannelLaunchPackPressureConversionStreak
        )
        persistBestChannelLaunchPackPressureSnapshot()
        return true
    }

    private func resetBestChannelLaunchPackPressureConversionStreakIfNeededForPreviousOpen() {
        guard openCount > 0 else { return }
        guard bestChannelLaunchPackPressureOpportunityOpenCount == openCount else { return }
        guard bestChannelLaunchPackPressureConversionOpenCount != openCount else { return }
        bestChannelLaunchPackPressureConversionStreak = 0
        persistBestChannelLaunchPackPressureSnapshot()
    }

    private func resetRecommendationConversionOpenStreakIfNeededForPreviousOpen() {
        guard openCount > 0 else { return }
        guard !didRecordRecommendationConversionInCurrentOpen else { return }
        recommendationConversionOpenStreak = 0
    }

    private func resetRecommendationMomentumRescueStreakIfNeededForPreviousOpen() {
        guard openCount > 0 else { return }
        guard !didRecordRecommendationMomentumRescueInCurrentOpen else { return }
        guard recommendationMomentumRescueStreak > 0 else { return }
        recommendationMomentumRescueStreak = 0
        persistRecommendationConversionSnapshot()
    }

    private func resetRecommendationMomentumRescueDailyCountIfNeeded(
        now: Date = Date()
    ) {
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(now: now)
        let runsToday = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: recommendationMomentumRescueLeaderboardDayStamp,
            storedCount: recommendationMomentumRescueRunsToday,
            now: now
        )
        guard recommendationMomentumRescueLeaderboardDayStamp != todayStamp ||
            recommendationMomentumRescueRunsToday != runsToday else {
            return
        }
        recommendationMomentumRescueLeaderboardDayStamp = todayStamp
        recommendationMomentumRescueRunsToday = runsToday
        persistRecommendationConversionSnapshot()
    }

    private func resetRecommendationMomentumRescueWeeklyCountIfNeeded(
        now: Date = Date()
    ) {
        let weekStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(now: now)
        let runsThisWeek = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
            weekStamp: recommendationMomentumRescueLeaderboardWeekStamp,
            storedCount: recommendationMomentumRescueRunsThisWeek,
            now: now
        )
        guard recommendationMomentumRescueLeaderboardWeekStamp != weekStamp ||
            recommendationMomentumRescueRunsThisWeek != runsThisWeek else {
            return
        }

        if recommendationMomentumRescueLeaderboardWeekStamp != nil,
           recommendationMomentumRescueLeaderboardWeekStamp != weekStamp,
           recommendationMomentumRescueRunsThisWeek > 0 {
            recommendationMomentumRescuePreviousWeekRuns = recommendationMomentumRescueRunsThisWeek
        }

        recommendationMomentumRescueLeaderboardWeekStamp = weekStamp
        recommendationMomentumRescueRunsThisWeek = runsThisWeek
        recommendationMomentumRescueBestWeekRuns = max(
            recommendationMomentumRescueBestWeekRuns,
            recommendationMomentumRescueRunsThisWeek
        )
        persistRecommendationConversionSnapshot()
    }

    private func resetFameMomentumPanelRouteStabilizationResetCueCountIfNeeded(
        now: Date = Date()
    ) {
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(now: now)
        let countToday = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: fameMomentumPanelRouteStabilizationResetCueDayStamp,
            storedCount: fameMomentumPanelRouteStabilizationResetCueCountToday,
            now: now
        )
        guard fameMomentumPanelRouteStabilizationResetCueDayStamp != todayStamp ||
            fameMomentumPanelRouteStabilizationResetCueCountToday != countToday else {
            return
        }
        fameMomentumPanelRouteStabilizationResetCueDayStamp = todayStamp
        fameMomentumPanelRouteStabilizationResetCueCountToday = countToday
        fameMomentumPanelRouteStabilizationResetCueRecordedOpenCount = -1
        persistFameMomentumPanelTelemetrySnapshot(now: now)
    }

    private func recordRecommendationMomentumRescueLeaderboardRun(
        now: Date = Date()
    ) {
        resetRecommendationMomentumRescueDailyCountIfNeeded(now: now)
        resetRecommendationMomentumRescueWeeklyCountIfNeeded(now: now)
        let previousBestWeekRuns = max(0, recommendationMomentumRescueBestWeekRuns)
        let previousWeekRuns = max(0, recommendationMomentumRescuePreviousWeekRuns)
        let recorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: recommendationMomentumRescueLeaderboardDayStamp,
            storedCount: recommendationMomentumRescueRunsToday,
            now: now
        )
        let weekly = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
            weekStamp: recommendationMomentumRescueLeaderboardWeekStamp,
            storedCount: recommendationMomentumRescueRunsThisWeek,
            bestWeekCount: recommendationMomentumRescueBestWeekRuns,
            now: now
        )
        recommendationMomentumRescueLeaderboardDayStamp = recorded.dayStamp
        recommendationMomentumRescueRunsToday = recorded.runsToday
        recommendationMomentumRescueBestDayRuns = max(
            recommendationMomentumRescueBestDayRuns,
            recommendationMomentumRescueRunsToday
        )
        recommendationMomentumRescueLeaderboardWeekStamp = weekly.weekStamp
        recommendationMomentumRescueRunsThisWeek = weekly.runsThisWeek
        recommendationMomentumRescueBestWeekRuns = weekly.bestWeekCount
        if previousBestWeekRuns > 0,
           recommendationMomentumRescueBestWeekRuns > previousBestWeekRuns,
           recommendationMomentumRescueRunsThisWeek == recommendationMomentumRescueBestWeekRuns {
            let pulse = Self.recommendationMomentumRescueWeeklyRecordPulse(
                runsThisWeek: recommendationMomentumRescueRunsThisWeek,
                previousBestWeekRuns: previousBestWeekRuns,
                previousWeekRuns: previousWeekRuns
            )
            recommendationMomentumRescueWeeklyRecordPulse = pulse
            recommendationMomentumRescueWeeklyRecordPulseAt = now
            recommendationMomentumRescueWeeklyRecordPulseEvent += 1
        }
        persistRecommendationConversionSnapshot()
    }

    private static func recommendationConversionPulse(
        openStreak: Int,
        conversionCount: Int
    ) -> RecommendationConversionPulse {
        let normalizedOpenStreak = max(1, openStreak)
        let normalizedConversionCount = max(1, conversionCount)
        let conversionWord = normalizedConversionCount == 1 ? "conversion" : "conversions"
        let title = "Recommendation Streak x\(normalizedOpenStreak)"
        let subtitle = "\(normalizedConversionCount) guided \(conversionWord)"
        let systemImage: String
        switch normalizedOpenStreak {
        case 5...:
            systemImage = "flame.fill"
        case 3...:
            systemImage = "sparkles"
        default:
            systemImage = "arrow.forward.circle.fill"
        }
        let helpText = "Recommendation CTA converted across x\(normalizedOpenStreak) consecutive opens (\(subtitle))."
        return RecommendationConversionPulse(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    private static func fameMomentumPanelLearningPulse(
        cooledAlternativesCount: Int
    ) -> FameMomentumPanelLearningPulse {
        let normalizedCooledAlternatives = max(1, cooledAlternativesCount)
        let alternateWord = normalizedCooledAlternatives == 1 ? "alternate" : "alternates"
        let subtitle = "Boosted winner, cooled \(normalizedCooledAlternatives) \(alternateWord)"
        let helpText = "Top Picks learning refreshed: converted action gains +\(fameMomentumPanelActionScorePositiveDelta), while \(normalizedCooledAlternatives) skipped \(alternateWord) each cool by \(abs(fameMomentumPanelActionScoreSkippedAlternativeDelta))."
        return FameMomentumPanelLearningPulse(
            title: "Learning Updated",
            subtitle: subtitle,
            systemImage: "brain.head.profile",
            helpText: helpText
        )
    }

    private static func fameMomentumPanelRouteFlipPulse(
        previousPrompt: String,
        nextPrompt: String,
        previousActionScore: Int?,
        nextActionScore: Int?,
        previousGapPoints: Int?,
        nextGapPoints: Int?,
        previousSignalAgeOpens: Int?,
        nextSignalAgeOpens: Int?,
        reasonChips: [CommandPaletteTopPicks.FameMomentumPanelReasonChip],
        selectionConfidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence?
    ) -> FameMomentumPanelRouteFlipPulse {
        let reasonTitles = reasonChips.map(\.title)
        let routeScoreDelta: Int? = {
            guard let previousActionScore, let nextActionScore else { return nil }
            return nextActionScore - previousActionScore
        }()
        let confidenceDeltaPoints: Int? = {
            guard let previousGapPoints, let nextGapPoints else { return nil }
            return nextGapPoints - previousGapPoints
        }()
        let hasStaleSignalReason = reasonTitles.contains("Signal Stale")
            || reasonTitles.contains("Signal Aging")
        let didFreshenSignal = {
            guard let previousSignalAgeOpens, let nextSignalAgeOpens else { return false }
            return nextSignalAgeOpens + 1 < previousSignalAgeOpens
        }()
        let hasMomentumReason = reasonTitles.contains(where: { title in
            title.hasPrefix("Observed +")
                || title.hasPrefix("Rescue Conf +")
                || title.hasPrefix("Δwins +")
        })
        let didConfidenceJump = (confidenceDeltaPoints ?? 0) >= 12
        let trigger: FameMomentumPanelRouteFlipPulse.Trigger
        if hasStaleSignalReason || didFreshenSignal {
            trigger = .freshSignal
        } else if hasMomentumReason || didConfidenceJump {
            trigger = .momentumSurge
        } else if selectionConfidence?.tier == .split {
            trigger = .tightDecision
        } else {
            trigger = .rerank
        }

        let title: String
        let systemImage: String
        let helpReason: String
        switch trigger {
        case .freshSignal:
            title = "Route Flip · Fresh Signal"
            systemImage = "arrow.triangle.2.circlepath.circle.fill"
            helpReason = "Stale or aging evidence got discounted while fresher signals were promoted."
        case .momentumSurge:
            title = "Route Flip · Momentum Surge"
            systemImage = "bolt.trianglebadge.exclamationmark.fill"
            helpReason = "Positive observed momentum re-ranked the Top Picks route."
        case .tightDecision:
            title = "Route Flip · Tight Decision"
            systemImage = "arrow.left.arrow.right.circle.fill"
            helpReason = "The primary and backup routes stayed close, so ranking flipped on a narrow margin."
        case .rerank:
            title = "Route Flip · Re-ranked"
            systemImage = "line.3.horizontal.decrease.circle.fill"
            helpReason = "Adaptive ranking changed route priority."
        }

        var subtitle = "\(previousPrompt) → \(nextPrompt)"
        if let routeScoreDelta {
            let signedRouteDelta = routeScoreDelta > 0 ? "+\(routeScoreDelta)" : "\(routeScoreDelta)"
            subtitle += " · Δscore \(signedRouteDelta)"
        }
        if let confidenceDeltaPoints {
            let signedDelta = confidenceDeltaPoints > 0 ? "+\(confidenceDeltaPoints)" : "\(confidenceDeltaPoints)"
            subtitle += " · Δgap \(signedDelta)"
        }

        var detailParts: [String] = []
        if let routeScoreDelta {
            let signedRouteDelta = routeScoreDelta > 0 ? "+\(routeScoreDelta)" : "\(routeScoreDelta)"
            detailParts.append("Route score moved by \(signedRouteDelta) points.")
        }
        if let confidenceDeltaPoints {
            let signedDelta = confidenceDeltaPoints > 0 ? "+\(confidenceDeltaPoints)" : "\(confidenceDeltaPoints)"
            detailParts.append("Confidence gap shifted by \(signedDelta) points.")
        }
        if let previousSignalAgeOpens, let nextSignalAgeOpens {
            detailParts.append("Signal age moved from \(previousSignalAgeOpens) to \(nextSignalAgeOpens) open(s).")
        } else if let nextSignalAgeOpens {
            detailParts.append("New route signal age is \(nextSignalAgeOpens) open(s).")
        }
        let detailSuffix = detailParts.isEmpty ? "" : " " + detailParts.joined(separator: " ")
        let helpText = "Fame Momentum Panel switched primary route from \(previousPrompt) to \(nextPrompt). \(helpReason)\(detailSuffix)"
        return FameMomentumPanelRouteFlipPulse(
            trigger: trigger,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText,
            previousActionPrompt: previousPrompt,
            nextActionPrompt: nextPrompt,
            confidenceDeltaPoints: confidenceDeltaPoints,
            previousSignalAgeOpens: previousSignalAgeOpens,
            nextSignalAgeOpens: nextSignalAgeOpens,
            previousActionScore: previousActionScore,
            nextActionScore: nextActionScore,
            routeScoreDelta: routeScoreDelta
        )
    }

    private static func fameMomentumPanelRouteStabilizationPulse(
        rhythm: FameMomentumPanelRouteFlipRhythm,
        volatileStreak: Int
    ) -> FameMomentumPanelRouteStabilizationPulse {
        let normalizedVolatileStreak = max(1, volatileStreak)
        let title = "Route Stabilizer x\(normalizedVolatileStreak)"
        let subtitle = "\(rhythm.flipCount) flips/\(rhythm.openSpan) opens · run Best Bet, keep backup live."
        var helpText = "Fame route rhythm stayed volatile for \(normalizedVolatileStreak) consecutive open(s). Keep split routing visible and prioritize fresh-signal routes until cadence settles."
        if let averageRouteDelta = rhythm.averageAbsRouteScoreDelta {
            helpText += " Average route-score swing: \(averageRouteDelta)."
        }
        if let averageGapDelta = rhythm.averageAbsConfidenceDeltaPoints {
            helpText += " Average confidence-gap swing: \(averageGapDelta)."
        }
        return FameMomentumPanelRouteStabilizationPulse(
            title: title,
            subtitle: subtitle,
            systemImage: "shield.lefthalf.filled.trianglebadge.exclamationmark",
            helpText: helpText,
            volatileStreak: normalizedVolatileStreak,
            flipCount: rhythm.flipCount,
            openSpan: rhythm.openSpan
        )
    }

    private static func fameMomentumPanelActionRecencyOpensAgo(
        _ recency: CommandPaletteTopPicks.FameMomentumPanelActionRecency?
    ) -> Int? {
        guard let recency else { return nil }
        switch recency {
        case .recentlyValidated(let opensAgo):
            return max(0, opensAgo)
        case .aging(let opensAgo):
            return max(0, opensAgo)
        case .stale(let opensAgo):
            return max(0, opensAgo)
        }
    }

    private static func normalizedFameMomentumPanelRoutePrompt(_ prompt: String?) -> String? {
        guard let prompt else { return nil }
        let normalizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPrompt.isEmpty else { return nil }
        return normalizedPrompt
    }

    private static func resolvedFameMomentumPanelRoutePrompt(_ prompt: String?, fallback: String) -> String {
        let normalizedPrompt = normalizedFameMomentumPanelRoutePrompt(prompt)
        return normalizedPrompt ?? fallback
    }

    private static func recommendationMomentumRescuePulse(
        opportunities: Int,
        conversionCount: Int,
        opensSinceLastConversion: Int,
        streak: Int,
        bestStreak: Int,
        previousStreak: Int,
        didSetNewBest: Bool
    ) -> RecommendationMomentumRescuePulse {
        let normalizedOpportunities = max(1, opportunities)
        let normalizedConversionCount = min(
            normalizedOpportunities,
            max(1, conversionCount)
        )
        let normalizedOpensSinceLastConversion = max(1, opensSinceLastConversion)
        let normalizedStreak = max(1, streak)
        let normalizedBestStreak = max(normalizedStreak, max(0, bestStreak))
        let normalizedPreviousStreak = max(0, previousStreak)
        let rescueTier = recommendationMomentumRescueTier(for: normalizedStreak)
        let previousTierTitle = normalizedPreviousStreak > 0
            ? recommendationMomentumRescueTier(for: normalizedPreviousStreak).title
            : nil
        let didTierUpgrade = previousTierTitle.map { $0 != rescueTier.title } ?? false
        let title = "Momentum Rescue x\(normalizedStreak)"
        let subtitle = "Recovered after \(normalizedOpensSinceLastConversion) opens cold"
        let helpText: String
        if let nextTierTitle = rescueTier.nextTierTitle,
           let nextTierThreshold = rescueTier.nextTierThreshold {
            helpText = "Cold high-trust recommendation recovered (\(normalizedConversionCount)/\(normalizedOpportunities)). Rescue lane \(rescueTier.title) now at x\(normalizedStreak); next \(nextTierTitle) at x\(nextTierThreshold)."
        } else {
            helpText = "Cold high-trust recommendation recovered (\(normalizedConversionCount)/\(normalizedOpportunities)). Rescue lane \(rescueTier.title) is locked at x\(normalizedStreak)."
        }
        return RecommendationMomentumRescuePulse(
            title: title,
            subtitle: subtitle,
            systemImage: rescueTier.systemImage,
            helpText: helpText,
            streak: normalizedStreak,
            bestStreak: normalizedBestStreak,
            tierTitle: rescueTier.title,
            didTierUpgrade: didTierUpgrade,
            didSetNewBest: didSetNewBest
        )
    }

    private static func recommendationMomentumRescueWeeklyRecordPulse(
        runsThisWeek: Int,
        previousBestWeekRuns: Int,
        previousWeekRuns: Int
    ) -> RecommendationMomentumRescueWeeklyRecordPulse {
        let normalizedRunsThisWeek = max(1, runsThisWeek)
        let normalizedPreviousBestWeekRuns = max(1, previousBestWeekRuns)
        let normalizedPreviousWeekRuns = max(0, previousWeekRuns)
        let delta = max(1, normalizedRunsThisWeek - normalizedPreviousBestWeekRuns)
        let title = "Weekly Record x\(normalizedRunsThisWeek)"
        let subtitle: String
        let helpText: String
        if normalizedPreviousWeekRuns > 0 {
            subtitle = "Week \(normalizedRunsThisWeek) beats best x\(normalizedPreviousBestWeekRuns) (+\(delta)) · last week x\(normalizedPreviousWeekRuns)."
            helpText = "Hall of Fame update: week \(normalizedRunsThisWeek) beats prior best x\(normalizedPreviousBestWeekRuns) by +\(delta). Last week closed at x\(normalizedPreviousWeekRuns)."
        } else {
            subtitle = "Week \(normalizedRunsThisWeek) beats best x\(normalizedPreviousBestWeekRuns) (+\(delta))."
            helpText = "Hall of Fame update: week \(normalizedRunsThisWeek) beats prior best x\(normalizedPreviousBestWeekRuns) by +\(delta)."
        }
        return RecommendationMomentumRescueWeeklyRecordPulse(
            title: title,
            subtitle: subtitle,
            systemImage: "trophy.fill",
            helpText: helpText,
            runsThisWeek: normalizedRunsThisWeek,
            previousBestWeekRuns: normalizedPreviousBestWeekRuns,
            delta: delta
        )
    }

    private static func recommendationMomentumRescueTier(
        for streak: Int
    ) -> (
        title: String,
        systemImage: String,
        nextTierTitle: String?,
        nextTierThreshold: Int?
    ) {
        let normalizedStreak = max(1, streak)
        switch normalizedStreak {
        case ...2:
            return (
                title: "Spark",
                systemImage: "bolt.badge.clock",
                nextTierTitle: "Breakout",
                nextTierThreshold: 3
            )
        case ...4:
            return (
                title: "Breakout",
                systemImage: "sparkles",
                nextTierTitle: "Fame",
                nextTierThreshold: 5
            )
        case ...7:
            return (
                title: "Fame",
                systemImage: "flame.fill",
                nextTierTitle: "Legend",
                nextTierThreshold: 8
            )
        default:
            return (
                title: "Legend",
                systemImage: "crown.fill",
                nextTierTitle: nil,
                nextTierThreshold: nil
            )
        }
    }

    private func persistBestChannelLaunchPackPressureSnapshot() {
        let normalizedOpportunities = max(0, bestChannelLaunchPackPressureOpportunities)
        let normalizedConversions = min(
            normalizedOpportunities,
            max(0, bestChannelLaunchPackPressureConversions)
        )
        let normalizedStreak = min(
            normalizedConversions,
            max(0, bestChannelLaunchPackPressureConversionStreak)
        )
        let normalizedBestStreak = max(
            normalizedStreak,
            max(0, bestChannelLaunchPackPressureBestStreak)
        )

        bestChannelLaunchPackPressureOpportunities = normalizedOpportunities
        bestChannelLaunchPackPressureConversions = normalizedConversions
        bestChannelLaunchPackPressureConversionStreak = normalizedStreak
        bestChannelLaunchPackPressureBestStreak = normalizedBestStreak

        defaults.set(
            normalizedOpportunities,
            forKey: AppDefaults.fameBestChannelLaunchPackPressureOpportunitiesKey
        )
        defaults.set(
            normalizedConversions,
            forKey: AppDefaults.fameBestChannelLaunchPackPressureConversionsKey
        )
        defaults.set(
            normalizedStreak,
            forKey: AppDefaults.fameBestChannelLaunchPackPressureConversionStreakKey
        )
        defaults.set(
            normalizedBestStreak,
            forKey: AppDefaults.fameBestChannelLaunchPackPressureBestStreakKey
        )
        if let tone = bestChannelLaunchPackPressureLastTone {
            defaults.set(
                Self.bestChannelLaunchPackPressureToneToken(tone),
                forKey: AppDefaults.fameBestChannelLaunchPackPressureLastToneKey
            )
        } else {
            defaults.removeObject(forKey: AppDefaults.fameBestChannelLaunchPackPressureLastToneKey)
        }
    }

    private func persistRecommendationConversionSnapshot() {
        let normalizedOpportunities = max(0, recommendationConversionOpportunities)
        let normalizedConversions = min(
            normalizedOpportunities,
            max(0, recommendationConversionCount)
        )
        let normalizedBestOpenStreak = min(
            normalizedConversions,
            max(0, recommendationConversionBestOpenStreak)
        )
        let normalizedMomentumRescueStreak = max(0, recommendationMomentumRescueStreak)
        let normalizedMomentumRescueBestStreak = max(
            normalizedMomentumRescueStreak,
            max(0, recommendationMomentumRescueBestStreak)
        )
        let normalizedMomentumRescueRunsToday = max(0, recommendationMomentumRescueRunsToday)
        let normalizedMomentumRescueBestDayRuns = max(
            normalizedMomentumRescueRunsToday,
            max(0, recommendationMomentumRescueBestDayRuns)
        )
        let normalizedMomentumRescueRunsThisWeek = max(0, recommendationMomentumRescueRunsThisWeek)
        let normalizedMomentumRescueBestWeekRuns = max(
            normalizedMomentumRescueRunsThisWeek,
            max(0, recommendationMomentumRescueBestWeekRuns)
        )
        let normalizedMomentumRescuePreviousWeekRuns = max(0, recommendationMomentumRescuePreviousWeekRuns)
        let normalizedMomentumRescueLeaderboardDayStamp = recommendationMomentumRescueLeaderboardDayStamp?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMomentumRescueLeaderboardWeekStamp = recommendationMomentumRescueLeaderboardWeekStamp?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedMomentumRescueLeaderboardDayStamp: String
        if let normalizedMomentumRescueLeaderboardDayStamp,
           !normalizedMomentumRescueLeaderboardDayStamp.isEmpty {
            resolvedMomentumRescueLeaderboardDayStamp = normalizedMomentumRescueLeaderboardDayStamp
        } else {
            resolvedMomentumRescueLeaderboardDayStamp = CommandPaletteTopPicks
                .launchRecoveryHotKeyAutoTrustSurgeDayStamp()
        }
        let resolvedMomentumRescueLeaderboardWeekStamp: String
        if let normalizedMomentumRescueLeaderboardWeekStamp,
           !normalizedMomentumRescueLeaderboardWeekStamp.isEmpty {
            resolvedMomentumRescueLeaderboardWeekStamp = normalizedMomentumRescueLeaderboardWeekStamp
        } else {
            resolvedMomentumRescueLeaderboardWeekStamp = CommandPaletteTopPicks
                .launchRecoveryHotKeyAutoTrustSurgeWeekStamp()
        }

        recommendationConversionOpportunities = normalizedOpportunities
        recommendationConversionCount = normalizedConversions
        recommendationConversionBestOpenStreak = normalizedBestOpenStreak
        recommendationMomentumRescueStreak = normalizedMomentumRescueStreak
        recommendationMomentumRescueBestStreak = normalizedMomentumRescueBestStreak
        recommendationMomentumRescueRunsToday = normalizedMomentumRescueRunsToday
        recommendationMomentumRescueBestDayRuns = normalizedMomentumRescueBestDayRuns
        recommendationMomentumRescueRunsThisWeek = normalizedMomentumRescueRunsThisWeek
        recommendationMomentumRescueBestWeekRuns = normalizedMomentumRescueBestWeekRuns
        recommendationMomentumRescuePreviousWeekRuns = normalizedMomentumRescuePreviousWeekRuns
        recommendationMomentumRescueLeaderboardDayStamp = resolvedMomentumRescueLeaderboardDayStamp
        recommendationMomentumRescueLeaderboardWeekStamp = resolvedMomentumRescueLeaderboardWeekStamp

        defaults.set(
            normalizedOpportunities,
            forKey: AppDefaults.fameRecommendationConversionOpportunitiesKey
        )
        defaults.set(
            normalizedConversions,
            forKey: AppDefaults.fameRecommendationConversionCountKey
        )
        defaults.set(
            normalizedBestOpenStreak,
            forKey: AppDefaults.fameRecommendationConversionBestOpenStreakKey
        )
        defaults.set(
            normalizedMomentumRescueStreak,
            forKey: AppDefaults.fameRecommendationMomentumRescueStreakKey
        )
        defaults.set(
            normalizedMomentumRescueBestStreak,
            forKey: AppDefaults.fameRecommendationMomentumRescueBestStreakKey
        )
        defaults.set(
            resolvedMomentumRescueLeaderboardDayStamp,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardDayStampKey
        )
        defaults.set(
            normalizedMomentumRescueRunsToday,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsTodayKey
        )
        defaults.set(
            normalizedMomentumRescueBestDayRuns,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestDayRunsKey
        )
        defaults.set(
            resolvedMomentumRescueLeaderboardWeekStamp,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardWeekStampKey
        )
        defaults.set(
            normalizedMomentumRescueRunsThisWeek,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardRunsThisWeekKey
        )
        defaults.set(
            normalizedMomentumRescueBestWeekRuns,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardBestWeekRunsKey
        )
        defaults.set(
            normalizedMomentumRescuePreviousWeekRuns,
            forKey: AppDefaults.fameRecommendationMomentumRescueLeaderboardPreviousWeekRunsKey
        )
    }

    private func persistRecommendationPairSnapshot() {
        let normalizedOpportunities = Self.normalizedRecommendationPairMetrics(
            recommendationConversionPairOpportunities
        )
        let normalizedConversions = Self.normalizedRecommendationPairMetrics(
            recommendationConversionPairConversions
        )
        let normalizedLastConversionOpenCount = Self.normalizedRecommendationPairMetrics(
            recommendationConversionPairLastConversionOpenCount
        )
        let constrainedConversions = normalizedConversions.reduce(into: [String: Int]()) { result, entry in
            let opportunities = normalizedOpportunities[entry.key] ?? 0
            guard opportunities > 0 else { return }
            let conversions = min(opportunities, max(0, entry.value))
            guard conversions > 0 else { return }
            result[entry.key] = conversions
        }
        let constrainedLastConversionOpenCount = normalizedLastConversionOpenCount.reduce(into: [String: Int]()) { result,
            entry in
            let conversions = constrainedConversions[entry.key] ?? 0
            guard conversions > 0 else { return }
            result[entry.key] = max(1, entry.value)
        }

        recommendationConversionPairOpportunities = normalizedOpportunities
        recommendationConversionPairConversions = constrainedConversions
        recommendationConversionPairLastConversionOpenCount = constrainedLastConversionOpenCount

        if normalizedOpportunities.isEmpty {
            defaults.removeObject(forKey: AppDefaults.fameRecommendationConversionPairOpportunitiesKey)
        } else if let data = try? JSONEncoder().encode(normalizedOpportunities) {
            defaults.set(data, forKey: AppDefaults.fameRecommendationConversionPairOpportunitiesKey)
        }
        if constrainedConversions.isEmpty {
            defaults.removeObject(forKey: AppDefaults.fameRecommendationConversionPairConversionsKey)
        } else if let data = try? JSONEncoder().encode(constrainedConversions) {
            defaults.set(data, forKey: AppDefaults.fameRecommendationConversionPairConversionsKey)
        }
        if constrainedLastConversionOpenCount.isEmpty {
            defaults.removeObject(forKey: AppDefaults.fameRecommendationConversionPairLastConversionOpenCountKey)
        } else if let data = try? JSONEncoder().encode(constrainedLastConversionOpenCount) {
            defaults.set(
                data,
                forKey: AppDefaults.fameRecommendationConversionPairLastConversionOpenCountKey
            )
        }
    }

    private static func loadRecommendationPairMetrics(
        from defaults: UserDefaults,
        key: String
    ) -> [String: Int] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return normalizedRecommendationPairMetrics(decoded)
    }

    private static func normalizedRecommendationPairMetrics(
        _ metrics: [String: Int]
    ) -> [String: Int] {
        var normalized: [String: Int] = [:]
        normalized.reserveCapacity(metrics.count)
        for (token, value) in metrics {
            guard let pair = recommendationPairToken(from: token),
                  let normalizedToken = recommendationPairToken(
                      sourceActionID: pair.sourceActionID,
                      recommendedActionID: pair.recommendedActionID
                  ) else {
                continue
            }
            let cleanValue = max(0, value)
            guard cleanValue > 0 else { continue }
            normalized[normalizedToken] = max(cleanValue, normalized[normalizedToken] ?? 0)
        }
        return normalized
    }

    private static func recommendationPairToken(
        sourceActionID: String,
        recommendedActionID: String
    ) -> String? {
        guard let normalizedSourceActionID = normalizedRecommendationPairActionID(sourceActionID),
              let normalizedRecommendedActionID = normalizedRecommendationPairActionID(recommendedActionID) else {
            return nil
        }
        guard !normalizedSourceActionID.isEmpty,
              !normalizedRecommendedActionID.isEmpty,
              normalizedSourceActionID != normalizedRecommendedActionID else {
            return nil
        }
        return "\(normalizedSourceActionID)->\(normalizedRecommendedActionID)"
    }

    private static func recommendationPairToken(
        from token: String
    ) -> (sourceActionID: String, recommendedActionID: String)? {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separatorRange = cleanToken.range(of: "->") else { return nil }
        let sourceActionID = String(cleanToken[..<separatorRange.lowerBound])
        let recommendedActionID = String(cleanToken[separatorRange.upperBound...])
        guard let normalizedToken = recommendationPairToken(
            sourceActionID: sourceActionID,
            recommendedActionID: recommendedActionID
        ),
        let normalizedSeparatorRange = normalizedToken.range(of: "->") else {
            return nil
        }
        return (
            sourceActionID: String(normalizedToken[..<normalizedSeparatorRange.lowerBound]),
            recommendedActionID: String(normalizedToken[normalizedSeparatorRange.upperBound...])
        )
    }

    private static func normalizedRecommendationPairActionID(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count <= recommendationPairMaxActionIDLength else { return nil }
        guard trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        guard !trimmed.contains("->") else { return nil }
        return trimmed
    }

    private static func incrementSaturating(_ value: Int) -> Int {
        guard value < Int.max else {
            return Int.max
        }
        return value + 1
    }

    private static func bestChannelLaunchPackPressureToneToken(
        _ tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) -> String {
        switch tone {
        case .watch:
            return "watch"
        case .alert:
            return "alert"
        }
    }

    private static func bestChannelLaunchPackPressureTone(
        token: String?
    ) -> CommandPaletteTopPicks.BestChannelLaunchPackPressureTone? {
        switch token?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "watch":
            return .watch
        case "alert":
            return .alert
        default:
            return nil
        }
    }

    private func persistLaunchRecoveryHotKeyReadinessSnapshot(
        limit: Int = PaletteSession.launchRecoveryHotKeyReadinessPersistenceLimit
    ) {
        let normalizedLimit = max(1, limit)
        let history = Array(launchRecoveryHotKeyReadinessHistory.suffix(normalizedLimit))
        let tokens = history.map(Self.launchRecoveryHotKeyReadinessToken)
        if tokens.isEmpty {
            defaults.removeObject(forKey: AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey)
        } else {
            defaults.set(tokens, forKey: AppDefaults.fameLaunchRecoveryHotKeyReadinessHistoryKey)
        }
        defaults.set(
            max(0, launchRecoveryHotKeyDirectStreak),
            forKey: AppDefaults.fameLaunchRecoveryHotKeyDirectStreakKey
        )
        defaults.set(
            max(launchRecoveryHotKeyDirectStreak, launchRecoveryHotKeyBestDirectStreak),
            forKey: AppDefaults.fameLaunchRecoveryHotKeyBestDirectStreakKey
        )
    }

    private static func loadLaunchRecoveryHotKeyReadinessHistory(
        from defaults: UserDefaults,
        key: String,
        limit: Int
    ) -> [CommandPaletteTopPicks.LaunchRecoveryHotKeyReadinessState] {
        let normalizedLimit = max(1, limit)
        let tokens = defaults.stringArray(forKey: key) ?? []
        let trimmedTokens = Array(tokens.suffix(normalizedLimit))
        return trimmedTokens.compactMap { token in
            Self.launchRecoveryHotKeyReadinessState(token: token)
        }
    }

    private static func launchRecoveryHotKeyReadinessToken(
        _ state: CommandPaletteTopPicks.LaunchRecoveryHotKeyReadinessState
    ) -> String {
        switch state {
        case .direct:
            return "direct"
        case .reroute:
            return "reroute"
        case .standby:
            return "standby"
        }
    }

    private static func launchRecoveryHotKeyReadinessState(
        token: String
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyReadinessState? {
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

    @discardableResult
    func recordLaunchRecoveryHotKeyCoachCue(
        _ cue: CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue?,
        at date: Date = Date(),
        repeatThreshold: Int = 3
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyDecayPulse? {
        guard openCount > 0 else { return nil }
        guard openCount != lastLaunchRecoveryHotKeyCoachCueOpenCount else { return nil }

        lastLaunchRecoveryHotKeyCoachCueOpenCount = openCount
        if cue == nil {
            launchRecoveryHotKeyCoachCueStreak = 0
            return nil
        }

        launchRecoveryHotKeyCoachCueStreak += 1
        let normalizedThreshold = max(2, repeatThreshold)
        guard launchRecoveryHotKeyCoachCueStreak == normalizedThreshold,
              let cue else {
            return nil
        }

        let pulse = CommandPaletteTopPicks.launchRecoveryHotKeyDecayPulse(
            coachCue: cue,
            streakCount: launchRecoveryHotKeyCoachCueStreak
        )
        launchRecoveryHotKeyDecayPulse = pulse
        launchRecoveryHotKeyDecayPulseAt = date
        launchRecoveryHotKeyDecayPulseEvent += 1
        return pulse
    }

    @discardableResult
    func recordLaunchRecoveryHotKeyConfidenceScore(
        _ score: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore,
        at date: Date = Date()
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse? {
        guard openCount > 0 else { return nil }
        guard openCount != lastLaunchRecoveryHotKeyConfidenceScoreOpenCount else { return nil }

        lastLaunchRecoveryHotKeyConfidenceScoreOpenCount = openCount
        let previousTier = launchRecoveryHotKeyLastConfidenceTier
        let previousPoints = launchRecoveryHotKeyLastConfidencePoints
        let pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse?
        if let previousTier {
            pulse = CommandPaletteTopPicks.launchRecoveryHotKeyConfidencePulse(
                previousTier: previousTier,
                nextTier: score.tier,
                points: score.points
            )
            updateLaunchRecoveryHotKeyInterventionScores(
                previousTier: previousTier,
                nextTier: score.tier,
                previousPoints: previousPoints,
                nextPoints: score.points
            )
        } else {
            pulse = nil
        }

        launchRecoveryHotKeyLastConfidenceTier = score.tier
        launchRecoveryHotKeyLastConfidencePoints = score.points

        if let pulse {
            launchRecoveryHotKeyConfidencePulse = pulse
            launchRecoveryHotKeyConfidencePulseAt = date
            launchRecoveryHotKeyConfidencePulseEvent += 1
        }
        return pulse
    }

    func recordLaunchRecoveryHotKeyInterventionRun(actionID: String) {
        guard openCount > 0 else { return }
        guard CommandPaletteTopPicks.isLaunchRecoveryHotKeyInterventionActionID(actionID) else { return }
        launchRecoveryHotKeyPendingInterventionActionID = actionID
        launchRecoveryHotKeyPendingInterventionOpenCount = openCount
        launchRecoveryHotKeyPendingInterventionBaselineTier = launchRecoveryHotKeyLastConfidenceTier
        launchRecoveryHotKeyPendingInterventionBaselinePoints = launchRecoveryHotKeyLastConfidencePoints
    }

    @discardableResult
    func recordLaunchRecoveryHotKeyMomentum(
        _ momentum: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum?,
        at date: Date = Date()
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse? {
        guard openCount > 0 else {
            launchRecoveryHotKeyLastMomentum = momentum
            return nil
        }
        guard openCount != lastLaunchRecoveryHotKeyMomentumPulseOpenCount else {
            return nil
        }

        lastLaunchRecoveryHotKeyMomentumPulseOpenCount = openCount
        let pulse = CommandPaletteTopPicks.launchRecoveryHotKeyMomentumPulse(
            previousMomentum: launchRecoveryHotKeyLastMomentum,
            nextMomentum: momentum
        )
        launchRecoveryHotKeyLastMomentum = momentum

        if let pulse {
            launchRecoveryHotKeyMomentumPulse = pulse
            launchRecoveryHotKeyMomentumPulseAt = date
            launchRecoveryHotKeyMomentumPulseEvent += 1
        }
        return pulse
    }

    func recordLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse,
        at date: Date = Date()
    ) {
        launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse = pulse
        launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseAt = date
        launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseEvent += 1
    }

    func launchRecoveryHotKeyLegendRiskStickyPromotionActionID(
        enabledActionIDs: Set<String>
    ) -> String? {
        launchRecoveryHotKeyLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )?.actionID
    }

    func launchRecoveryHotKeyLegendRiskStickyPromotion(
        enabledActionIDs: Set<String>
    ) -> LaunchRecoveryHotKeyLegendRiskStickyPromotion? {
        guard openCount > 0 else { return nil }
        guard let actionID = launchRecoveryHotKeyLegendRiskStickyPromotedActionID else { return nil }
        guard openCount <= launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount else {
            launchRecoveryHotKeyLegendRiskStickyPromotedActionID = nil
            launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount = 0
            launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered = false
            return nil
        }
        guard enabledActionIDs.contains(actionID) else { return nil }
        let opensRemaining = max(
            1,
            launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount - openCount + 1
        )
        return LaunchRecoveryHotKeyLegendRiskStickyPromotion(
            actionID: actionID,
            opensRemaining: opensRemaining,
            isHoldUntilRecovered: launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered
        )
    }

    func recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionActionID(
        enabledActionIDs: Set<String>
    ) -> String? {
        recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )?.actionID
    }

    func recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
        enabledActionIDs: Set<String>
    ) -> RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion? {
        guard openCount > 0 else { return nil }
        guard let actionID = recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID else {
            return nil
        }
        guard openCount <= recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount else {
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotedActionID = nil
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount = 0
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered = false
            return nil
        }
        guard enabledActionIDs.contains(actionID) else { return nil }
        let opensRemaining = max(
            1,
            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionUntilOpenCount - openCount + 1
        )
        return RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            actionID: actionID,
            opensRemaining: opensRemaining,
            isHoldUntilRecovered: recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionHoldUntilRecovered
        )
    }

    @discardableResult
    func recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
        _ forecast: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast?,
        stickyPromotionOpenWindow: Int = AppDefaults
            .fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens,
        stickyPromotionHoldUntilRecovered: Bool = AppDefaults
            .fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled,
        at date: Date = Date()
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse? {
        guard openCount > 0 else {
            launchRecoveryHotKeyLastLegendDecayForecast = forecast
            return nil
        }
        guard openCount != lastLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastOpenCount else {
            return nil
        }

        let normalizedStickyPromotionOpenWindow =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(
                stickyPromotionOpenWindow
            )

        lastLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastOpenCount = openCount
        let previousForecast = launchRecoveryHotKeyLastLegendDecayForecast
        let pulse = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
            previousForecast: previousForecast,
            nextForecast: forecast
        )
        launchRecoveryHotKeyLastLegendDecayForecast = forecast

        if stickyPromotionHoldUntilRecovered,
           forecast == nil {
            if let promotedActionID = launchRecoveryHotKeyLegendRiskStickyPromotedActionID {
                launchRecoveryHotKeyLegendRiskStickyReleasePulse = CommandPaletteTopPicks
                    .launchRecoveryHotKeyLegendRiskStickyReleasePulse(
                        actionID: promotedActionID
                    )
                launchRecoveryHotKeyLegendRiskStickyReleasePulseAt = date
                launchRecoveryHotKeyLegendRiskStickyReleasePulseEvent += 1
            }
            launchRecoveryHotKeyLegendRiskStickyPromotedActionID = nil
            launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount = 0
            launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered = false
        }

        if let pulse {
            launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse = pulse
            launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseAt = date
            launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent += 1
            if pulse.tone == .alert,
               let promotedActionID = forecast?.actionID {
                launchRecoveryHotKeyLegendRiskStickyPromotedActionID = promotedActionID
                launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount = openCount
                    + normalizedStickyPromotionOpenWindow - 1
                launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered = stickyPromotionHoldUntilRecovered
            }
        }

        if stickyPromotionHoldUntilRecovered,
           launchRecoveryHotKeyLegendRiskStickyPromotedActionID != nil,
           forecast != nil {
            if let promotedActionID = forecast?.actionID {
                launchRecoveryHotKeyLegendRiskStickyPromotedActionID = promotedActionID
            }
            launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount = max(
                launchRecoveryHotKeyLegendRiskStickyPromotionUntilOpenCount,
                openCount + normalizedStickyPromotionOpenWindow - 1
            )
            launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered = true
        } else if !stickyPromotionHoldUntilRecovered {
            launchRecoveryHotKeyLegendRiskStickyPromotionHoldUntilRecovered = false
        }

        return pulse
    }

    var launchRecoveryHotKeyInterventionRecency: [String: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionRecency] {
        guard !launchRecoveryHotKeyInterventionScores.isEmpty else { return [:] }

        let staleThreshold = Self.launchRecoveryHotKeyInterventionScoreStaleOpenThreshold(
            for: launchRecoveryHotKeyLastConfidenceTier
        )
        var recency: [String: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionRecency] = [:]
        recency.reserveCapacity(launchRecoveryHotKeyInterventionScores.count)

        for actionID in launchRecoveryHotKeyInterventionScores.keys {
            let lastUpdatedOpenCount = launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount[actionID]
                ?? openCount
            let elapsedOpens = max(0, openCount - lastUpdatedOpenCount)
            if elapsedOpens >= staleThreshold {
                recency[actionID] = .stale(opensAgo: elapsedOpens)
            } else {
                recency[actionID] = .recentlyValidated(opensAgo: elapsedOpens)
            }
        }
        return recency
    }

    var launchRecoveryHotKeyInterventionTrustTrend: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustTrend? {
        CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustTrend(
            for: launchRecoveryHotKeyInterventionTrustHistory
        )
    }

    var fameMomentumPanelAdaptiveActionScores: [String: Int] {
        var mergedScores = launchRecoveryHotKeyInterventionScores
        for (actionID, score) in fameMomentumPanelActionScores {
            guard score != 0 else { continue }
            mergedScores[actionID, default: 0] += score
        }
        return mergedScores
    }

    var fameMomentumPanelActionRecency: [String: CommandPaletteTopPicks.FameMomentumPanelActionRecency] {
        guard !fameMomentumPanelActionScores.isEmpty else { return [:] }

        let agingThreshold = Self.fameMomentumPanelActionScoreAgingOpenThreshold()
        let staleThreshold = Self.fameMomentumPanelActionScoreStaleOpenThreshold()
        var recency: [String: CommandPaletteTopPicks.FameMomentumPanelActionRecency] = [:]
        recency.reserveCapacity(fameMomentumPanelActionScores.count)

        for actionID in fameMomentumPanelActionScores.keys {
            let lastUpdatedOpenCount = fameMomentumPanelActionScoreLastUpdatedOpenCount[actionID] ?? openCount
            let elapsedOpens = max(0, openCount - lastUpdatedOpenCount)
            if elapsedOpens >= staleThreshold {
                recency[actionID] = .stale(opensAgo: elapsedOpens)
            } else if elapsedOpens >= agingThreshold {
                recency[actionID] = .aging(opensAgo: elapsedOpens)
            } else {
                recency[actionID] = .recentlyValidated(opensAgo: elapsedOpens)
            }
        }
        return recency
    }

    func recentLaunchRecoveryHotKeyDecayPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyDecayPulse? {
        guard let launchRecoveryHotKeyDecayPulse,
              let launchRecoveryHotKeyDecayPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyDecayPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyDecayPulse
    }

    func recentLaunchRecoveryHotKeyRestorePulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyRestorePulse? {
        guard let launchRecoveryHotKeyRestorePulse,
              let launchRecoveryHotKeyRestorePulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyRestorePulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyRestorePulse
    }

    func recentLaunchRecoveryHotKeyConfidencePulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse? {
        guard let launchRecoveryHotKeyConfidencePulse,
              let launchRecoveryHotKeyConfidencePulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyConfidencePulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyConfidencePulse
    }

    func recentLaunchRecoveryHotKeyMomentumPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse? {
        guard let launchRecoveryHotKeyMomentumPulse,
              let launchRecoveryHotKeyMomentumPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyMomentumPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyMomentumPulse
    }

    func recentLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse? {
        guard let launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse,
              let launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse
    }

    func recentLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse? {
        guard let launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse,
              let launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse
    }

    func recentLaunchRecoveryHotKeyLegendRiskStickyReleasePulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyLegendRiskStickyReleasePulse? {
        guard let launchRecoveryHotKeyLegendRiskStickyReleasePulse,
              let launchRecoveryHotKeyLegendRiskStickyReleasePulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyLegendRiskStickyReleasePulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyLegendRiskStickyReleasePulse
    }

    func recentLaunchRecoveryHotKeyInterventionTrustPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse? {
        guard let launchRecoveryHotKeyInterventionTrustPulse,
              let launchRecoveryHotKeyInterventionTrustPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyInterventionTrustPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyInterventionTrustPulse
    }

    func recentLaunchRecoveryHotKeyInterventionTrustMomentumPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentumPulse? {
        guard let launchRecoveryHotKeyInterventionTrustMomentumPulse,
              let launchRecoveryHotKeyInterventionTrustMomentumPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(launchRecoveryHotKeyInterventionTrustMomentumPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return launchRecoveryHotKeyInterventionTrustMomentumPulse
    }

    func recentRecommendationMomentumRescuePulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> RecommendationMomentumRescuePulse? {
        guard let recommendationMomentumRescuePulse,
              let recommendationMomentumRescuePulseAt else {
            return nil
        }
        guard now.timeIntervalSince(recommendationMomentumRescuePulseAt) <= max(0, maxAge) else {
            return nil
        }
        return recommendationMomentumRescuePulse
    }

    func recentRecommendationMomentumRescueWeeklyRecordPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> RecommendationMomentumRescueWeeklyRecordPulse? {
        guard let recommendationMomentumRescueWeeklyRecordPulse,
              let recommendationMomentumRescueWeeklyRecordPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(recommendationMomentumRescueWeeklyRecordPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return recommendationMomentumRescueWeeklyRecordPulse
    }

    func recentRecommendationMomentumRescueImpactPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueImpactPulse? {
        guard let recommendationMomentumRescueImpactPulse,
              let recommendationMomentumRescueImpactPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(recommendationMomentumRescueImpactPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return recommendationMomentumRescueImpactPulse
    }

    func recentRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse? {
        guard let recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse,
              let recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse
    }

    func recentRecommendationMomentumRescueHallOfFameLegendRiskPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskPulse? {
        guard let recommendationMomentumRescueHallOfFameLegendRiskPulse,
              let recommendationMomentumRescueHallOfFameLegendRiskPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(recommendationMomentumRescueHallOfFameLegendRiskPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return recommendationMomentumRescueHallOfFameLegendRiskPulse
    }

    func recentRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse? {
        guard let recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse,
              let recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseAt else {
            return nil
        }
        guard now.timeIntervalSince(
            recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseAt
        ) <= max(0, maxAge) else {
            return nil
        }
        return recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse
    }

    func recentRecommendationConversionPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> RecommendationConversionPulse? {
        guard let recommendationConversionPulse,
              let recommendationConversionPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(recommendationConversionPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return recommendationConversionPulse
    }

    func recentFameMomentumPanelLearningPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> FameMomentumPanelLearningPulse? {
        guard let fameMomentumPanelLearningPulse,
              let fameMomentumPanelLearningPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(fameMomentumPanelLearningPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return fameMomentumPanelLearningPulse
    }

    func recentFameMomentumPanelRouteFlipPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> FameMomentumPanelRouteFlipPulse? {
        guard let fameMomentumPanelRouteFlipPulse,
              let fameMomentumPanelRouteFlipPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(fameMomentumPanelRouteFlipPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return fameMomentumPanelRouteFlipPulse
    }

    func recentFameMomentumPanelRouteStabilizationPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> FameMomentumPanelRouteStabilizationPulse? {
        guard let fameMomentumPanelRouteStabilizationPulse,
              let fameMomentumPanelRouteStabilizationPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(fameMomentumPanelRouteStabilizationPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return fameMomentumPanelRouteStabilizationPulse
    }

    func fameMomentumPanelRouteStabilizationScoreboard() -> FameMomentumPanelRouteStabilizationScoreboard? {
        let runs = max(0, fameMomentumPanelRouteStabilizationRunCount)
        let successes = max(0, min(runs, fameMomentumPanelRouteStabilizationSuccessCount))
        let pendingRuns = max(0, fameMomentumPanelRouteStabilizationPendingRunCount)
        let recoverySuggestionShownCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount
        )
        let recoverySuggestionRunCount = max(
            0,
            min(
                recoverySuggestionShownCount,
                fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount
            )
        )
        let recoverySuggestionRecoveryRunCount = max(
            0,
            min(
                recoverySuggestionRunCount,
                fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount
            )
        )
        let recoverySuggestionUnblockRunCount = max(
            0,
            min(
                max(0, recoverySuggestionRunCount - recoverySuggestionRecoveryRunCount),
                fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount
            )
        )
        let recoverySuggestionBlockedCount = max(
            0,
            min(
                recoverySuggestionShownCount,
                fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount
            )
        )
        guard runs > 0 || pendingRuns > 0 else { return nil }

        let successRatePercent: Int
        if runs > 0 {
            successRatePercent = Int(
                round((Double(successes) / Double(max(1, runs))) * 100)
            )
        } else {
            successRatePercent = 0
        }

        let title = "Stabilizer \(successRatePercent)%"
        let baseSubtitle: String
        if pendingRuns > 0 {
            baseSubtitle = "\(successes)/\(runs) stabilized · \(pendingRuns) pending"
        } else {
            baseSubtitle = "\(successes)/\(runs) stabilized"
        }
        let subtitle: String
        if recoverySuggestionShownCount > 0 {
            var recoveryTelemetryParts = ["\(recoverySuggestionRunCount)/\(recoverySuggestionShownCount) recovery"]
            if recoverySuggestionRecoveryRunCount > 0 {
                recoveryTelemetryParts.append(
                    "\(recoverySuggestionRecoveryRunCount) recovery runs"
                )
            }
            if recoverySuggestionUnblockRunCount > 0 {
                recoveryTelemetryParts.append(
                    "\(recoverySuggestionUnblockRunCount) unblock runs"
                )
            }
            if recoverySuggestionBlockedCount > 0 {
                recoveryTelemetryParts.append("\(recoverySuggestionBlockedCount) blocked")
            }
            subtitle = ([baseSubtitle] + recoveryTelemetryParts).joined(separator: " · ")
        } else {
            subtitle = baseSubtitle
        }
        let systemImage: String
        if pendingRuns > 0 {
            systemImage = "clock.arrow.circlepath"
        } else if successRatePercent >= 70 {
            systemImage = "checkmark.seal.fill"
        } else if successRatePercent >= 40 {
            systemImage = "shield.lefthalf.filled"
        } else {
            systemImage = "exclamationmark.triangle.fill"
        }
        let recoveryTelemetryHelpText: String
        if recoverySuggestionShownCount > 0 {
            let recoveryClickRatePercent = Int(
                round(
                    (Double(recoverySuggestionRunCount) / Double(max(1, recoverySuggestionShownCount)))
                        * 100
                )
            )
            let recoveryRunMixHelpText: String
            if recoverySuggestionRunCount > 0 {
                if recoverySuggestionUnblockRunCount > 0 {
                    recoveryRunMixHelpText =
                        " Run mix: \(recoverySuggestionRecoveryRunCount) recovery-route run(s), \(recoverySuggestionUnblockRunCount) unblock-route run(s)."
                } else {
                    recoveryRunMixHelpText =
                        " Run mix: \(recoverySuggestionRecoveryRunCount) recovery-route run(s)."
                }
            } else {
                recoveryRunMixHelpText = ""
            }
            if recoverySuggestionBlockedCount > 0 {
                recoveryTelemetryHelpText = " Recovery CTA shown \(recoverySuggestionShownCount) times; launched \(recoverySuggestionRunCount) runs (\(recoveryClickRatePercent)%); blocked \(recoverySuggestionBlockedCount) times due to unavailable actions.\(recoveryRunMixHelpText)"
            } else {
                recoveryTelemetryHelpText = " Recovery CTA shown \(recoverySuggestionShownCount) times; launched \(recoverySuggestionRunCount) runs (\(recoveryClickRatePercent)%).\(recoveryRunMixHelpText)"
            }
        } else {
            recoveryTelemetryHelpText = ""
        }
        let helpText = "Stabilizer outcomes track runs launched from the volatile-route cue. Success means route volatility calmed, no additional flip occurred in the evaluation window, or volatile streak improved.\(recoveryTelemetryHelpText)"
        return FameMomentumPanelRouteStabilizationScoreboard(
            runs: runs,
            successes: successes,
            pendingRuns: pendingRuns,
            successRatePercent: successRatePercent,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    func fameMomentumPanelRouteStabilizationRecoverySuggestion(
        triggerThreshold: Int = 2
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestion? {
        let normalizedThreshold = max(1, triggerThreshold)
        let resetCountToday = max(0, fameMomentumPanelRouteStabilizationResetCueCountToday)
        let recoverySuggestionShownCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount
        )
        let recoverySuggestionRunCount = min(
            recoverySuggestionShownCount,
            max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount)
        )
        let recoverySuggestionRecoveryRunCount = min(
            recoverySuggestionRunCount,
            max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount)
        )
        let recoverySuggestionUnblockRunCount = min(
            max(0, recoverySuggestionRunCount - recoverySuggestionRecoveryRunCount),
            max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount)
        )
        let recoverySuggestionBlockedCount = min(
            recoverySuggestionShownCount,
            max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount)
        )
        let pressureCalibration = fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration
        let hasBlockedPressure = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
                shownCount: recoverySuggestionShownCount,
                blockedCount: recoverySuggestionBlockedCount,
                recoveryRunCount: recoverySuggestionRecoveryRunCount,
                unblockRunCount: recoverySuggestionUnblockRunCount,
                pressureCalibration: pressureCalibration
            )
        let adaptiveThreshold = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThreshold(
                defaultThreshold: normalizedThreshold,
                shownCount: recoverySuggestionShownCount,
                blockedCount: recoverySuggestionBlockedCount,
                recoveryRunCount: recoverySuggestionRecoveryRunCount,
                unblockRunCount: recoverySuggestionUnblockRunCount,
                pressureCalibration: pressureCalibration
            )
        guard resetCountToday >= adaptiveThreshold else { return nil }

        let title: String
        let subtitle: String
        let systemImage: String
        let buttonTitle: String
        let helpText: String
        if hasBlockedPressure {
            let blockedRatePercent = Int(
                round(
                    (Double(recoverySuggestionBlockedCount)
                        / Double(max(1, recoverySuggestionShownCount))) * 100
                )
            )
            if resetCountToday >= 4 {
                title = "Unblock Route Critical"
                systemImage = "xmark.shield.fill"
            } else {
                title = "Unblock Route Recommended"
                systemImage = "exclamationmark.shield.fill"
            }
            subtitle = "Reset mode fired x\(resetCountToday) today · blockers hit \(recoverySuggestionBlockedCount)/\(recoverySuggestionShownCount) recovery cues."
            buttonTitle = "Run Unblock Plan"
            helpText = "Recovery suggestions are under blocker pressure (\(blockedRatePercent)% blocked across \(recoverySuggestionShownCount) cues). Run an unblock plan to reopen a clean stabilization lane before reranking. Run mix: \(recoverySuggestionRecoveryRunCount) recovery-route run(s), \(recoverySuggestionUnblockRunCount) unblock-route run(s)."
        } else if resetCountToday >= 4 {
            title = "Recovery Loop Recommended"
            subtitle = "Reset mode fired x\(resetCountToday) today · run a full recovery loop before reranking again."
            systemImage = "bolt.shield.fill"
            buttonTitle = "Run Full Recovery"
            helpText = "Route stabilizer reset mode has activated \(resetCountToday) times today. Run a focused recovery loop to rebuild a cleaner confidence signal before opening another volatile rerank."
        } else {
            title = "Recovery Loop Suggested"
            subtitle = "Reset mode fired x\(resetCountToday) today · run a focused recovery loop now."
            systemImage = "arrow.clockwise.circle.fill"
            buttonTitle = "Run Recovery Loop"
            helpText = "Route stabilizer reset mode has activated \(resetCountToday) times today. Run a focused recovery loop to rebuild a cleaner confidence signal before opening another volatile rerank."
        }
        return FameMomentumPanelRouteStabilizationRecoverySuggestion(
            resetCountToday: resetCountToday,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            buttonTitle: buttonTitle,
            helpText: helpText
        )
    }

    var fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration:
        CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration? {
        let normalizedCalibration = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
                sampleCount: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
            )
        guard normalizedCalibration.sampleCount > 0 else { return nil }
        return CommandPaletteTopPicks
            .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                biasPoints: Self
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationBiasPoints(
                        score: normalizedCalibration.score,
                        sampleCount: normalizedCalibration.sampleCount
                    ),
                sampleCount: normalizedCalibration.sampleCount
            )
    }

    func fameMomentumPanelRouteFlipRhythm() -> FameMomentumPanelRouteFlipRhythm? {
        let history = fameMomentumPanelRouteFlipHistory
        guard history.count >= 2 else { return nil }

        let currentOpen = max(0, openCount)
        let newestOpen = max(0, history.first?.openCount ?? currentOpen)
        let oldestOpen = max(0, history.last?.openCount ?? newestOpen)
        let openSpan = max(
            1,
            max(newestOpen, currentOpen) - oldestOpen + 1
        )
        let flipCount = history.count
        let averageAbsRouteScoreDelta = Self.averageAbsoluteValue(
            history.compactMap(\.routeScoreDelta)
        )
        let averageAbsConfidenceDeltaPoints = Self.averageAbsoluteValue(
            history.compactMap(\.confidenceDeltaPoints)
        )

        let tone: FameMomentumPanelRouteFlipRhythm.Tone
        if flipCount >= 3, openSpan <= 4 {
            tone = .volatile
        } else if openSpan <= 3
            || ((averageAbsRouteScoreDelta ?? 99) <= 16
                && (averageAbsConfidenceDeltaPoints ?? 99) <= 10) {
            tone = .watch
        } else {
            tone = .stabilizing
        }

        let title: String
        let subtitle: String
        let systemImage: String
        let helpReason: String
        switch tone {
        case .volatile:
            title = "Route Rhythm · Volatile"
            subtitle = "\(flipCount) flips in \(openSpan) opens · ranking still reshuffling."
            systemImage = "waveform.path.ecg.rectangle.fill"
            helpReason = "Primary route is changing quickly, so expect additional re-ranks."
        case .watch:
            title = "Route Rhythm · Watch"
            subtitle = "\(flipCount) flips in \(openSpan) opens · routes remain close."
            systemImage = "eye.trianglebadge.exclamationmark"
            helpReason = "Route order is still sensitive and can flip on small evidence shifts."
        case .stabilizing:
            title = "Route Rhythm · Stabilizing"
            subtitle = "\(flipCount) flips spread across \(openSpan) opens · cadence is settling."
            systemImage = "checkmark.seal.fill"
            helpReason = "Flip tempo slowed down, suggesting a steadier primary route."
        }

        var metricParts: [String] = []
        if let averageAbsRouteScoreDelta {
            metricParts.append("Average route-score swing is \(averageAbsRouteScoreDelta) points")
        }
        if let averageAbsConfidenceDeltaPoints {
            metricParts.append("average confidence-gap swing is \(averageAbsConfidenceDeltaPoints) points")
        }
        let metricSuffix = metricParts.isEmpty ? "" : " " + metricParts.joined(separator: "; ") + "."
        let helpText = "\(helpReason)\(metricSuffix)"

        return FameMomentumPanelRouteFlipRhythm(
            tone: tone,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText,
            flipCount: flipCount,
            openSpan: openSpan,
            averageAbsRouteScoreDelta: averageAbsRouteScoreDelta,
            averageAbsConfidenceDeltaPoints: averageAbsConfidenceDeltaPoints
        )
    }

    func recentCadenceExecutionKitMomentumPulse(
        now: Date = Date(),
        maxAge: TimeInterval = 12
    ) -> CommandPaletteCadenceExecutionKitStreak.MomentumPulse? {
        guard let cadenceExecutionKitMomentumPulse,
              let cadenceExecutionKitMomentumPulseAt else {
            return nil
        }
        guard now.timeIntervalSince(cadenceExecutionKitMomentumPulseAt) <= max(0, maxAge) else {
            return nil
        }
        return cadenceExecutionKitMomentumPulse
    }

    private static func milestone(for streak: Int) -> Int? {
        if [3, 5, 10].contains(streak) {
            return streak
        }
        if streak > 10 && streak % 5 == 0 {
            return streak
        }
        return nil
    }

    private static func averageAbsoluteValue(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0) { partialResult, value in
            partialResult + abs(value)
        }
        let divisor = max(1, values.count)
        return Int(round(Double(total) / Double(divisor)))
    }

    private func updateLaunchRecoveryHotKeyInterventionScores(
        previousTier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier,
        nextTier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier,
        previousPoints: Int?,
        nextPoints: Int
    ) {
        guard let actionID = launchRecoveryHotKeyPendingInterventionActionID,
              openCount > launchRecoveryHotKeyPendingInterventionOpenCount else {
            return
        }
        let baselineTier = launchRecoveryHotKeyPendingInterventionBaselineTier ?? previousTier
        let baselinePoints = launchRecoveryHotKeyPendingInterventionBaselinePoints ?? previousPoints
        launchRecoveryHotKeyPendingInterventionActionID = nil
        launchRecoveryHotKeyPendingInterventionOpenCount = -1
        launchRecoveryHotKeyPendingInterventionBaselineTier = nil
        launchRecoveryHotKeyPendingInterventionBaselinePoints = nil

        let tierDelta = CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceTierRank(nextTier)
            - CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceTierRank(baselineTier)
        var impact = tierDelta * 3
        if impact == 0,
           let baselinePoints {
            let pointsDelta = nextPoints - baselinePoints
            if pointsDelta >= 6 {
                impact = 1
            } else if pointsDelta <= -6 {
                impact = -1
            }
        }
        let current = launchRecoveryHotKeyInterventionScores[actionID, default: 0]
        if impact == 0 {
            let dampedScore = Self.launchRecoveryHotKeyInterventionScoreByDampening(current)
            if dampedScore == 0 {
                launchRecoveryHotKeyInterventionScores.removeValue(forKey: actionID)
                launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount.removeValue(forKey: actionID)
                persistLaunchRecoveryHotKeyInterventionScoresIfNeeded()
            } else if dampedScore != current {
                launchRecoveryHotKeyInterventionScores[actionID] = dampedScore
                launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount[actionID] = openCount
                persistLaunchRecoveryHotKeyInterventionScoresIfNeeded()
            }
            return
        }

        let nextScore = Self.clampedLaunchRecoveryHotKeyInterventionScore(current + impact)
        if nextScore == 0 {
            launchRecoveryHotKeyInterventionScores.removeValue(forKey: actionID)
            launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount.removeValue(forKey: actionID)
            persistLaunchRecoveryHotKeyInterventionScoresIfNeeded()
            return
        }

        launchRecoveryHotKeyInterventionScores[actionID] = nextScore
        launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount[actionID] = openCount
        persistLaunchRecoveryHotKeyInterventionScoresIfNeeded()
    }

    private func finalizeFameMomentumPanelOpportunityForPreviousOpen() {
        guard openCount > 0 else { return }
        guard fameMomentumPanelOpportunityOpenCount == openCount else { return }
        guard !didRecordFameMomentumPanelConversionInCurrentOpen else { return }
        guard !fameMomentumPanelOpportunityActionIDs.isEmpty else { return }

        for actionID in fameMomentumPanelOpportunityActionIDs {
            updateFameMomentumPanelActionScore(
                actionID: actionID,
                delta: Self.fameMomentumPanelActionScoreMissDelta
            )
        }
    }

    private func updateFameMomentumPanelActionScore(actionID: String, delta: Int) {
        guard delta != 0 else { return }
        guard let normalizedActionID = Self.normalizedFameMomentumPanelActionID(actionID) else { return }

        let currentScore = fameMomentumPanelActionScores[normalizedActionID, default: 0]
        let nextScore = Self.clampedFameMomentumPanelActionScore(currentScore + delta)
        if nextScore == 0 {
            fameMomentumPanelActionScores.removeValue(forKey: normalizedActionID)
            fameMomentumPanelActionScoreLastUpdatedOpenCount.removeValue(forKey: normalizedActionID)
        } else {
            fameMomentumPanelActionScores[normalizedActionID] = nextScore
            fameMomentumPanelActionScoreLastUpdatedOpenCount[normalizedActionID] = openCount
        }
        persistFameMomentumPanelActionScoresIfNeeded()
    }

    private func decayFameMomentumPanelActionScoresIfNeeded() {
        guard !fameMomentumPanelActionScores.isEmpty else { return }

        let decayInterval = max(1, Self.fameMomentumPanelActionScoreDecayOpenInterval)
        var updatedScores = fameMomentumPanelActionScores
        var updatedOpenCounts = fameMomentumPanelActionScoreLastUpdatedOpenCount

        for (actionID, score) in fameMomentumPanelActionScores {
            guard score != 0 else {
                updatedScores.removeValue(forKey: actionID)
                updatedOpenCounts.removeValue(forKey: actionID)
                continue
            }

            let lastUpdatedOpenCount = updatedOpenCounts[actionID] ?? openCount
            let elapsedOpens = openCount - lastUpdatedOpenCount
            guard elapsedOpens >= decayInterval else { continue }

            let decaySteps = elapsedOpens / decayInterval
            let decayedScore: Int
            if score > 0 {
                decayedScore = max(0, score - decaySteps)
            } else {
                decayedScore = min(0, score + decaySteps)
            }

            if decayedScore == 0 {
                updatedScores.removeValue(forKey: actionID)
                updatedOpenCounts.removeValue(forKey: actionID)
            } else {
                updatedScores[actionID] = decayedScore
                updatedOpenCounts[actionID] = lastUpdatedOpenCount + decaySteps * decayInterval
            }
        }

        guard updatedScores != fameMomentumPanelActionScores
                || updatedOpenCounts != fameMomentumPanelActionScoreLastUpdatedOpenCount else {
            return
        }
        fameMomentumPanelActionScores = updatedScores
        fameMomentumPanelActionScoreLastUpdatedOpenCount = updatedOpenCounts
        persistFameMomentumPanelActionScoresIfNeeded()
    }

    private func decayLaunchRecoveryHotKeyInterventionScoresIfNeeded() {
        guard !launchRecoveryHotKeyInterventionScores.isEmpty else { return }

        let decayInterval = Self.launchRecoveryHotKeyInterventionScoreDecayOpenInterval(
            for: launchRecoveryHotKeyLastConfidenceTier
        )
        var updatedScores = launchRecoveryHotKeyInterventionScores
        var updatedOpenCounts = launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount

        for (actionID, score) in launchRecoveryHotKeyInterventionScores {
            if actionID == launchRecoveryHotKeyPendingInterventionActionID {
                continue
            }
            guard score != 0 else {
                updatedScores.removeValue(forKey: actionID)
                updatedOpenCounts.removeValue(forKey: actionID)
                continue
            }

            let lastUpdatedOpenCount = updatedOpenCounts[actionID] ?? openCount
            let elapsedOpens = openCount - lastUpdatedOpenCount
            guard elapsedOpens >= decayInterval else { continue }

            let decaySteps = elapsedOpens / decayInterval
            let decayedScore: Int
            if score > 0 {
                decayedScore = max(0, score - decaySteps)
            } else {
                decayedScore = min(0, score + decaySteps)
            }

            if decayedScore == 0 {
                updatedScores.removeValue(forKey: actionID)
                updatedOpenCounts.removeValue(forKey: actionID)
            } else {
                updatedScores[actionID] = decayedScore
                updatedOpenCounts[actionID] = lastUpdatedOpenCount + decaySteps * decayInterval
            }
        }

        guard updatedScores != launchRecoveryHotKeyInterventionScores
                || updatedOpenCounts != launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount else {
            return
        }
        launchRecoveryHotKeyInterventionScores = updatedScores
        launchRecoveryHotKeyInterventionScoreLastUpdatedOpenCount = updatedOpenCounts
        persistLaunchRecoveryHotKeyInterventionScoresIfNeeded()
    }

    private func persistLaunchRecoveryHotKeyInterventionScoresIfNeeded() {
        defer { recordLaunchRecoveryHotKeyInterventionTrustSnapshot() }
        guard let key = launchRecoveryHotKeyInterventionScoresStorageKey else { return }
        let normalizedScores = Self.normalizedLaunchRecoveryHotKeyInterventionScores(
            launchRecoveryHotKeyInterventionScores
        )
        guard !normalizedScores.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(normalizedScores) else { return }
        defaults.set(data, forKey: key)
    }

    private func persistFameMomentumPanelActionScoresIfNeeded() {
        guard let key = fameMomentumPanelActionScoresStorageKey else { return }
        let normalizedScores = Self.normalizedFameMomentumPanelActionScores(
            fameMomentumPanelActionScores
        )
        fameMomentumPanelActionScores = normalizedScores
        fameMomentumPanelActionScoreLastUpdatedOpenCount = fameMomentumPanelActionScoreLastUpdatedOpenCount
            .filter { normalizedScores[$0.key] != nil }
        guard !normalizedScores.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(normalizedScores) else { return }
        defaults.set(data, forKey: key)
    }

    private func persistFameMomentumPanelTelemetrySnapshot(
        now: Date = Date()
    ) {
        let normalizedOpportunities = max(0, fameMomentumPanelOpportunityCount)
        let normalizedConversions = min(
            normalizedOpportunities,
            max(0, fameMomentumPanelConversionCount)
        )
        let normalizedStabilizationRuns = max(0, fameMomentumPanelRouteStabilizationRunCount)
        let normalizedStabilizationSuccesses = min(
            normalizedStabilizationRuns,
            max(0, fameMomentumPanelRouteStabilizationSuccessCount)
        )
        let normalizedStabilizationResetCueCountToday = max(
            0,
            fameMomentumPanelRouteStabilizationResetCueCountToday
        )
        let normalizedRecoverySuggestionShownCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount
        )
        let normalizedRecoverySuggestionRunCount = min(
            normalizedRecoverySuggestionShownCount,
            max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount)
        )
        let rawRecoverySuggestionRecoveryRunCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount
        )
        let rawRecoverySuggestionUnblockRunCount = max(
            0,
            fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount
        )
        let rawRecoverySuggestionSplitRunCount = max(
            0,
            rawRecoverySuggestionRecoveryRunCount + rawRecoverySuggestionUnblockRunCount
        )
        let normalizedRecoverySuggestionRecoveryRunCount: Int
        let normalizedRecoverySuggestionUnblockRunCount: Int
        if rawRecoverySuggestionSplitRunCount <= 0,
           normalizedRecoverySuggestionRunCount > 0 {
            normalizedRecoverySuggestionRecoveryRunCount = normalizedRecoverySuggestionRunCount
            normalizedRecoverySuggestionUnblockRunCount = 0
        } else {
            normalizedRecoverySuggestionRecoveryRunCount = min(
                normalizedRecoverySuggestionRunCount,
                rawRecoverySuggestionRecoveryRunCount
            )
            normalizedRecoverySuggestionUnblockRunCount = min(
                max(
                    0,
                    normalizedRecoverySuggestionRunCount
                        - normalizedRecoverySuggestionRecoveryRunCount
                ),
                rawRecoverySuggestionUnblockRunCount
            )
        }
        let normalizedRecoverySuggestionBlockedCount = min(
            normalizedRecoverySuggestionShownCount,
            max(0, fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount)
        )
        let normalizedRecoverySuggestionPressureConfidenceHistoryRaw = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory(
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
                limit: Self
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryLimit
            )
        let normalizedRecoverySuggestionPressureConfidenceHistory =
            normalizedRecoverySuggestionShownCount > 0
            ? normalizedRecoverySuggestionPressureConfidenceHistoryRaw
            : []
        let normalizedRecoverySuggestionPressureCalibration = Self
            .normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore,
                sampleCount:
                    fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount
            )
        let normalizedStabilizationResetCueDayStamp = fameMomentumPanelRouteStabilizationResetCueDayStamp?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedStabilizationResetCueDayStamp: String
        if let normalizedStabilizationResetCueDayStamp,
           !normalizedStabilizationResetCueDayStamp.isEmpty {
            resolvedStabilizationResetCueDayStamp = normalizedStabilizationResetCueDayStamp
        } else {
            resolvedStabilizationResetCueDayStamp = CommandPaletteTopPicks
                .launchRecoveryHotKeyAutoTrustSurgeDayStamp(now: now)
        }
        let resolvedStabilizationResetCueCountToday = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeRunsToday(
                dayStamp: resolvedStabilizationResetCueDayStamp,
                storedCount: normalizedStabilizationResetCueCountToday,
                now: now
            )

        fameMomentumPanelOpportunityCount = normalizedOpportunities
        fameMomentumPanelConversionCount = normalizedConversions
        fameMomentumPanelRouteStabilizationRunCount = normalizedStabilizationRuns
        fameMomentumPanelRouteStabilizationSuccessCount = normalizedStabilizationSuccesses
        fameMomentumPanelRouteStabilizationResetCueDayStamp = resolvedStabilizationResetCueDayStamp
        fameMomentumPanelRouteStabilizationResetCueCountToday = resolvedStabilizationResetCueCountToday
        fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount =
            normalizedRecoverySuggestionShownCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount =
            normalizedRecoverySuggestionRunCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount =
            normalizedRecoverySuggestionRecoveryRunCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount =
            normalizedRecoverySuggestionUnblockRunCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount =
            normalizedRecoverySuggestionBlockedCount
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory =
            normalizedRecoverySuggestionPressureConfidenceHistory
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore =
            normalizedRecoverySuggestionPressureCalibration.score
        fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount =
            normalizedRecoverySuggestionPressureCalibration.sampleCount

        defaults.set(
            normalizedOpportunities,
            forKey: AppDefaults.fameMomentumPanelOpportunityCountKey
        )
        defaults.set(
            normalizedConversions,
            forKey: AppDefaults.fameMomentumPanelConversionCountKey
        )
        defaults.set(
            normalizedStabilizationRuns,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRunCountKey
        )
        defaults.set(
            normalizedStabilizationSuccesses,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationSuccessCountKey
        )
        defaults.set(
            resolvedStabilizationResetCueDayStamp,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueDayStampKey
        )
        defaults.set(
            resolvedStabilizationResetCueCountToday,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationResetCueCountTodayKey
        )
        defaults.set(
            normalizedRecoverySuggestionShownCount,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCountKey
        )
        defaults.set(
            normalizedRecoverySuggestionRunCount,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCountKey
        )
        defaults.set(
            normalizedRecoverySuggestionRecoveryRunCount,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCountKey
        )
        defaults.set(
            normalizedRecoverySuggestionUnblockRunCount,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCountKey
        )
        defaults.set(
            normalizedRecoverySuggestionBlockedCount,
            forKey: AppDefaults.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCountKey
        )
        if normalizedRecoverySuggestionPressureConfidenceHistory.isEmpty {
            defaults.removeObject(
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
            )
        } else {
            defaults.set(
                normalizedRecoverySuggestionPressureConfidenceHistory,
                forKey: AppDefaults
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistoryKey
            )
        }
        defaults.set(
            normalizedRecoverySuggestionPressureCalibration.score,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreKey
        )
        defaults.set(
            normalizedRecoverySuggestionPressureCalibration.sampleCount,
            forKey: AppDefaults
                .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountKey
        )
    }

    private static func loadLaunchRecoveryHotKeyInterventionScores(
        from defaults: UserDefaults,
        key: String
    ) -> [String: Int] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return normalizedLaunchRecoveryHotKeyInterventionScores(decoded)
    }

    private static func loadFameMomentumPanelActionScores(
        from defaults: UserDefaults,
        key: String
    ) -> [String: Int] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return normalizedFameMomentumPanelActionScores(decoded)
    }

    private static func loadFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory(
        from defaults: UserDefaults,
        key: String,
        limit: Int
    ) -> [Int] {
        let rawHistory = defaults.array(forKey: key) ?? []
        let historyValues = rawHistory.compactMap { value -> Int? in
            if let intValue = value as? Int {
                return intValue
            }
            if let number = value as? NSNumber {
                return number.intValue
            }
            if let stringValue = value as? String {
                return Int(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return nil
        }
        return normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory(
            historyValues,
            limit: limit
        )
    }

    private static func normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory(
        _ history: [Int],
        limit: Int
    ) -> [Int] {
        let normalizedLimit = max(1, limit)
        let normalizedHistory = history.map { value in
            max(1, min(99, value))
        }
        return Array(normalizedHistory.suffix(normalizedLimit))
    }

    private static func normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
        score: Int,
        sampleCount: Int
    ) -> (score: Int, sampleCount: Int) {
        let normalizedSampleCount = max(
            0,
            min(
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCountLimit,
                sampleCount
            )
        )
        let normalizedScore: Int
        if normalizedSampleCount <= 0 {
            normalizedScore = 0
        } else {
            normalizedScore = min(
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreRange.upperBound,
                max(
                    fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScoreRange
                        .lowerBound,
                    score
                )
            )
        }
        return (
            score: normalizedScore,
            sampleCount: normalizedSampleCount
        )
    }

    private static func fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationBiasPoints(
        score: Int,
        sampleCount: Int
    ) -> Int {
        let normalizedCalibration =
            normalizedFameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration(
                score: score,
                sampleCount: sampleCount
            )
        guard normalizedCalibration.sampleCount > 0 else { return 0 }

        let denominator = max(4, min(18, normalizedCalibration.sampleCount))
        let rawBiasPoints = Int(
            round(
                Double(normalizedCalibration.score)
                    / Double(denominator)
            )
        )
        return min(
            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationBiasRange.upperBound,
            max(
                fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationBiasRange
                    .lowerBound,
                rawBiasPoints
            )
        )
    }

    private static func normalizedLaunchRecoveryHotKeyInterventionScores(
        _ scores: [String: Int]
    ) -> [String: Int] {
        var normalized: [String: Int] = [:]
        normalized.reserveCapacity(scores.count)
        for (actionID, score) in scores {
            guard CommandPaletteTopPicks.isLaunchRecoveryHotKeyInterventionActionID(actionID) else {
                continue
            }
            let clampedScore = clampedLaunchRecoveryHotKeyInterventionScore(score)
            guard clampedScore != 0 else { continue }
            normalized[actionID] = clampedScore
        }
        return normalized
    }

    private static func clampedLaunchRecoveryHotKeyInterventionScore(_ score: Int) -> Int {
        min(
            launchRecoveryHotKeyInterventionScoreRange.upperBound,
            max(launchRecoveryHotKeyInterventionScoreRange.lowerBound, score)
        )
    }

    private static func normalizedFameMomentumPanelActionID(_ actionID: String?) -> String? {
        guard let actionID else { return nil }
        let normalizedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedActionID.isEmpty else { return nil }
        return normalizedActionID
    }

    private static func normalizedFameMomentumPanelActionScores(
        _ scores: [String: Int]
    ) -> [String: Int] {
        var normalized: [String: Int] = [:]
        normalized.reserveCapacity(scores.count)
        for (actionID, score) in scores {
            guard let normalizedActionID = normalizedFameMomentumPanelActionID(actionID) else {
                continue
            }
            let clampedScore = clampedFameMomentumPanelActionScore(score)
            guard clampedScore != 0 else { continue }
            normalized[normalizedActionID] = clampedScore
        }
        return normalized
    }

    private static func clampedFameMomentumPanelActionScore(_ score: Int) -> Int {
        min(
            fameMomentumPanelActionScoreRange.upperBound,
            max(fameMomentumPanelActionScoreRange.lowerBound, score)
        )
    }

    private func recordLaunchRecoveryHotKeyInterventionTrustSnapshot(at date: Date = Date()) {
        guard openCount > 0 else { return }
        let trustPoints = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPoints(
            interventionScores: launchRecoveryHotKeyInterventionScores,
            interventionRecency: launchRecoveryHotKeyInterventionRecency
        )
        let referencePoints: Int?

        if lastLaunchRecoveryHotKeyInterventionTrustSnapshotOpenCount == openCount {
            referencePoints = launchRecoveryHotKeyInterventionTrustHistory.count >= 2
                ? launchRecoveryHotKeyInterventionTrustHistory[
                    launchRecoveryHotKeyInterventionTrustHistory.count - 2
                ]
                : nil
            guard !launchRecoveryHotKeyInterventionTrustHistory.isEmpty else {
                launchRecoveryHotKeyInterventionTrustHistory = [trustPoints]
                return
            }
            launchRecoveryHotKeyInterventionTrustHistory[launchRecoveryHotKeyInterventionTrustHistory.count - 1] = trustPoints
        } else {
            referencePoints = launchRecoveryHotKeyInterventionTrustHistory.last
            lastLaunchRecoveryHotKeyInterventionTrustSnapshotOpenCount = openCount
            launchRecoveryHotKeyInterventionTrustHistory.append(trustPoints)
            if launchRecoveryHotKeyInterventionTrustHistory.count > Self.launchRecoveryHotKeyInterventionTrustHistoryLimit {
                launchRecoveryHotKeyInterventionTrustHistory.removeFirst(
                    launchRecoveryHotKeyInterventionTrustHistory.count - Self.launchRecoveryHotKeyInterventionTrustHistoryLimit
                )
            }
        }

        emitLaunchRecoveryHotKeyInterventionTrustPulseIfNeeded(
            previousPoints: referencePoints,
            nextPoints: trustPoints,
            at: date
        )
        emitLaunchRecoveryHotKeyInterventionTrustMomentumPulseIfNeeded(at: date)
    }

    private func emitLaunchRecoveryHotKeyInterventionTrustPulseIfNeeded(
        previousPoints: Int?,
        nextPoints: Int,
        at date: Date = Date()
    ) {
        guard let previousPoints else { return }
        guard lastLaunchRecoveryHotKeyInterventionTrustPulseOpenCount != openCount else { return }
        guard let pulse = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustPulse(
            previousPoints: previousPoints,
            nextPoints: nextPoints
        ) else {
            return
        }
        lastLaunchRecoveryHotKeyInterventionTrustPulseOpenCount = openCount
        launchRecoveryHotKeyInterventionTrustPulse = pulse
        launchRecoveryHotKeyInterventionTrustPulseAt = date
        launchRecoveryHotKeyInterventionTrustPulseEvent += 1
    }

    private func emitLaunchRecoveryHotKeyInterventionTrustMomentumPulseIfNeeded(
        at date: Date = Date()
    ) {
        guard lastLaunchRecoveryHotKeyInterventionTrustMomentumPulseOpenCount != openCount else {
            return
        }
        guard let pulse = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPulse(
            for: launchRecoveryHotKeyInterventionTrustHistory
        ) else {
            return
        }
        lastLaunchRecoveryHotKeyInterventionTrustMomentumPulseOpenCount = openCount
        launchRecoveryHotKeyInterventionTrustMomentumPulse = pulse
        launchRecoveryHotKeyInterventionTrustMomentumPulseAt = date
        launchRecoveryHotKeyInterventionTrustMomentumPulseEvent += 1
    }

    private static func launchRecoveryHotKeyInterventionScoreByDampening(_ score: Int) -> Int {
        if score > 0 {
            return score - 1
        }
        if score < 0 {
            return score + 1
        }
        return 0
    }

    private static func launchRecoveryHotKeyInterventionScoreDecayOpenInterval(
        for tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier?
    ) -> Int {
        if tier == .critical {
            return launchRecoveryHotKeyInterventionScoreCriticalDecayOpenInterval
        }
        return launchRecoveryHotKeyInterventionScoreDefaultDecayOpenInterval
    }

    private static func launchRecoveryHotKeyInterventionScoreStaleOpenThreshold(
        for tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier?
    ) -> Int {
        max(1, launchRecoveryHotKeyInterventionScoreDecayOpenInterval(for: tier) - 1)
    }

    private static func fameMomentumPanelActionScoreAgingOpenThreshold() -> Int {
        max(1, fameMomentumPanelActionScoreDecayOpenInterval / 2)
    }

    private static func fameMomentumPanelActionScoreStaleOpenThreshold() -> Int {
        max(2, fameMomentumPanelActionScoreDecayOpenInterval)
    }
}

typealias CommandPaletteSession = PaletteSession

enum CommandPaletteCadenceExecutionKitStreak {
    private static let cadenceExecutionKitActionIDs: Set<String> = [
        "run-fame-next-move-cadence-execution-kit",
        "copy-next-move-cadence-execution-kit",
        "run-fame-cadence-autopilot-loop"
    ]
    private static let runActionID = "run-fame-next-move-cadence-execution-kit"
    private static let copyActionID = "copy-next-move-cadence-execution-kit"

    static func currentStreak(defaults: UserDefaults = .standard) -> Int {
        max(0, defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey))
    }

    static func bestStreak(defaults: UserDefaults = .standard) -> Int {
        let current = currentStreak(defaults: defaults)
        let best = max(0, defaults.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey))
        return max(current, best)
    }

    static func shouldShowBadge(
        currentStreak: Int,
        topPickActionIDs: [String],
        badgeEnabled: Bool = AppDefaults.fameCadenceExecutionKitBadgeEnabled
    ) -> Bool {
        guard badgeEnabled else { return false }
        guard currentStreak > 0 else { return false }
        return topPickActionIDs.contains { cadenceExecutionKitActionIDs.contains($0) }
    }

    static func shouldShowMomentumCard(
        currentStreak: Int,
        bestStreak: Int,
        momentumCardEnabled: Bool = AppDefaults.fameCadenceExecutionKitMomentumCardEnabled
    ) -> Bool {
        guard momentumCardEnabled else { return false }
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, bestStreak)
        return normalizedCurrentStreak > 0 || normalizedBestStreak > 0
    }

    static func isCadenceExecutionKitAction(_ actionID: String) -> Bool {
        cadenceExecutionKitActionIDs.contains(actionID)
    }

    static func runActionIDCandidate() -> String {
        runActionID
    }

    static func copyActionIDCandidate() -> String {
        copyActionID
    }

    static func nextMilestoneTarget(after streak: Int) -> Int {
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

    static func momentumTitle(streak: Int, bestStreak: Int) -> String {
        let normalizedStreak = max(0, streak)
        let normalizedBestStreak = max(normalizedStreak, bestStreak)
        if normalizedStreak > 0 {
            return "Cadence momentum x\(normalizedStreak)"
        }
        if normalizedBestStreak > 0 {
            return "Cadence momentum reset"
        }
        return "Cadence momentum"
    }

    static func momentumSubtitle(streak: Int, bestStreak: Int) -> String {
        let normalizedStreak = max(0, streak)
        let normalizedBestStreak = max(normalizedStreak, bestStreak)
        let nextMilestone = nextMilestoneTarget(after: normalizedStreak)
        let remainingRuns = max(1, nextMilestone - normalizedStreak)
        let runWord = remainingRuns == 1 ? "run" : "runs"

        if normalizedStreak > 0 {
            return "Next milestone x\(nextMilestone) in \(remainingRuns) \(runWord) · Best x\(normalizedBestStreak)"
        }
        if normalizedBestStreak > 0 {
            return "Best x\(normalizedBestStreak). Restart and hit x\(nextMilestone)."
        }
        return "Start now. First milestone x\(nextMilestone)."
    }

    static func momentumSystemImage(streak: Int) -> String {
        let normalizedStreak = max(0, streak)
        if normalizedStreak >= 10 {
            return "trophy.fill"
        }
        if normalizedStreak >= 5 {
            return "rocket.fill"
        }
        if normalizedStreak > 0 {
            return "bolt.fill"
        }
        return "arrow.clockwise"
    }

    static func momentumHelpText(streak: Int, bestStreak: Int) -> String {
        "\(momentumTitle(streak: streak, bestStreak: bestStreak)). \(momentumSubtitle(streak: streak, bestStreak: bestStreak))"
    }

    struct MomentumPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    static func momentumPulse(
        previousStreak: Int,
        nextStreak: Int,
        bestStreak: Int
    ) -> MomentumPulse? {
        let normalizedPreviousStreak = max(0, previousStreak)
        let normalizedNextStreak = max(0, nextStreak)
        let normalizedBestStreak = max(normalizedNextStreak, bestStreak)
        guard normalizedNextStreak != normalizedPreviousStreak else { return nil }

        if normalizedNextStreak > normalizedPreviousStreak {
            let title = "Cadence +1 to x\(normalizedNextStreak)"
            if let milestone = cadenceExecutionKitMilestone(for: normalizedNextStreak) {
                let subtitle = "Milestone x\(milestone) unlocked · Best x\(normalizedBestStreak)"
                return MomentumPulse(
                    title: title,
                    subtitle: subtitle,
                    systemImage: momentumSystemImage(streak: normalizedNextStreak),
                    helpText: "\(title). \(subtitle)"
                )
            }

            let nextMilestone = nextMilestoneTarget(after: normalizedNextStreak)
            let remainingRuns = max(1, nextMilestone - normalizedNextStreak)
            let runWord = remainingRuns == 1 ? "run" : "runs"
            let subtitle = "Next milestone x\(nextMilestone) in \(remainingRuns) \(runWord) · Best x\(normalizedBestStreak)"
            return MomentumPulse(
                title: title,
                subtitle: subtitle,
                systemImage: momentumSystemImage(streak: normalizedNextStreak),
                helpText: "\(title). \(subtitle)"
            )
        }

        let title = "Cadence streak reset"
        let subtitle: String
        if normalizedBestStreak > 0 {
            subtitle = "Best x\(normalizedBestStreak) saved. Run again to rebuild."
        } else {
            subtitle = "Run again to restart cadence."
        }
        return MomentumPulse(
            title: title,
            subtitle: subtitle,
            systemImage: "arrow.counterclockwise.circle.fill",
            helpText: "\(title). \(subtitle)"
        )
    }

    static func badgeLabel(streak: Int) -> String {
        "Cadence x\(max(0, streak))"
    }

    static func badgeSystemImage(streak: Int) -> String {
        streak >= 5 ? "rocket.fill" : "bolt.fill"
    }

    static func badgeHelpText(streak: Int, bestStreak: Int) -> String {
        let normalizedStreak = max(0, streak)
        let normalizedBestStreak = max(normalizedStreak, bestStreak)
        return "Cadence execution kit streak: \(normalizedStreak). Best: \(normalizedBestStreak)."
    }

    private static func cadenceExecutionKitMilestone(for streak: Int) -> Int? {
        let normalizedStreak = max(0, streak)
        if [3, 5, 10].contains(normalizedStreak) {
            return normalizedStreak
        }
        if normalizedStreak > 10 && normalizedStreak % 5 == 0 {
            return normalizedStreak
        }
        return nil
    }
}

final class CommandPaletteRefreshClock: ObservableObject {
    @Published private(set) var tick = 0

    func bump() {
        tick &+= 1
    }
}

enum CommandPaletteGroup: String, CaseIterable, Identifiable {
    case core
    case ask
    case text
    case saved
    case open
    case window
    case settings
    case support

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .core:
            return "Core"
        case .ask:
            return "Ask"
        case .text:
            return "Text"
        case .saved:
            return "Saved"
        case .open:
            return "Open"
        case .window:
            return "Window"
        case .settings:
            return "Settings"
        case .support:
            return "Support"
        }
    }

    var systemImage: String {
        switch self {
        case .core:
            return "wand.and.stars"
        case .ask:
            return "sparkles"
        case .text:
            return "textformat"
        case .saved:
            return "tray.full"
        case .open:
            return "arrow.up.right.square"
        case .window:
            return "rectangle.3.offgrid"
        case .settings:
            return "gearshape"
        case .support:
            return "lifepreserver"
        }
    }

    var shortcutDigit: Int {
        switch self {
        case .core:
            return 1
        case .ask:
            return 2
        case .text:
            return 3
        case .saved:
            return 4
        case .open:
            return 5
        case .window:
            return 6
        case .settings:
            return 7
        case .support:
            return 8
        }
    }

    static func group(forShortcutDigit digit: Int) -> CommandPaletteGroup? {
        allCases.first { $0.shortcutDigit == digit }
    }

    static func parseScopedQuery(_ rawQuery: String) -> CommandPaletteScopedQuery {
        let trimmedQuery = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return CommandPaletteScopedQuery(group: nil, sourceKinds: nil, searchQuery: rawQuery, hasScope: false)
        }

        guard let separatorIndex = trimmedQuery.firstIndex(where: { $0 == ":" || $0 == "/" }) else {
            return CommandPaletteScopedQuery(group: nil, sourceKinds: nil, searchQuery: rawQuery, hasScope: false)
        }

        let token = trimmedQuery[..<separatorIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let group = scopeTokenToGroup[token]
        let sourceKinds = scopeTokenToSourceKinds[token]
        guard group != nil || sourceKinds != nil else {
            return CommandPaletteScopedQuery(group: nil, sourceKinds: nil, searchQuery: rawQuery, hasScope: false)
        }

        let remainderStart = trimmedQuery.index(after: separatorIndex)
        let remainder = String(trimmedQuery[remainderStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return CommandPaletteScopedQuery(
            group: group,
            sourceKinds: sourceKinds,
            searchQuery: remainder,
            hasScope: true
        )
    }

    static func classify(
        actionID: String,
        title: String,
        subtitle: String,
        keywords: [String]
    ) -> CommandPaletteGroup {
        let id = actionID.lowercased()
        let searchable = ([actionID, title, subtitle] + keywords)
            .joined(separator: " ")
            .lowercased()

        if id.hasPrefix("window-") {
            return .window
        }

        if containsAny(id, markers: [
            "settings",
            "setup-checklist",
            "toggle-",
            "open-login-items-settings",
            "screen-recording",
            "accessibility",
            "launch-at-login",
            "ocr-language-",
            "reader-pin",
            "preview-feel",
            "voice-"
        ]) || containsAny(searchable, markers: [
            "settings",
            "permission",
            "setup",
            "preferences",
            "launch at login"
        ]) {
            return .settings
        }

        if containsAny(id, markers: [
            "support",
            "bug-report",
            "issue-bundle",
            "troubleshooting",
            "activity-log",
            "error-message",
            "clear-local-reader-data",
            "reset-command-learning",
            "win-recap",
            "win-card"
        ]) || containsAny(searchable, markers: [
            "support",
            "bug report",
            "troubleshoot",
            "activity log",
            "error"
        ]) {
            return .support
        }

        if containsAny(id, markers: [
            "snippet",
            "quick-link",
            "recent-",
            "clipboard-history"
        ]) || containsAny(searchable, markers: [
            "snippet",
            "quick link",
            "recent item",
            "clipboard history"
        ]) {
            return .saved
        }

        if containsAny(id, markers: [
            "ask-anything",
            "run-best-local-action",
            "inline-ask",
            "inline-route",
            "prompt-"
        ]) || containsAny(searchable, markers: [
            "ask",
            "question",
            "llm",
            "rewrite",
            "reply draft",
            "summary",
            "translate"
        ]) {
            return .ask
        }

        if containsAny(id, markers: [
            "read-",
            "pick-and-read",
            "mark-screenshot",
            "show-reader",
            "stop",
            "toggle-ani"
        ]) || containsAny(searchable, markers: [
            "read selected",
            "pick text",
            "mark screenshot",
            "show reader",
            "stop speech"
        ]) {
            return .core
        }

        if containsAny(id, markers: [
            "open-",
            "reveal-",
            "search-",
            "inline-open-",
            "inline-reveal-",
            "inline-web-search",
            "inline-open-url",
            "app-launch-",
            "refresh-app-launcher",
            "folder-"
        ]) || containsAny(searchable, markers: [
            "open",
            "reveal",
            "launch app",
            "search web",
            "browser",
            "finder"
        ]) {
            return .open
        }

        if containsAny(id, markers: [
            "copy-",
            "paste-",
            "save-",
            "inline-calculator",
            "inline-unit-converter",
            "inline-color-converter",
            "inline-date-math",
            "inline-clean-url",
            "inline-markdown-link",
            "base64",
            "slug",
            "snake-case",
            "camel-case",
            "pascal-case",
            "constant-case",
            "title-case",
            "lowercase",
            "uppercase",
            "clean-csv",
            "clean-url",
            "markdown-",
            "json",
            "extract-",
            "url-encode",
            "url-decode",
            "trim-",
            "join-",
            "sort-",
            "reverse-",
            "unique-",
            "single-space",
            "strip-ansi",
            "text-stats",
            "date-stamp",
            "unix-time",
            "iso-date",
            "utc-",
            "token",
            "password",
            "pin-code",
            "uuid",
            "time-zone"
        ]) || containsAny(searchable, markers: [
            "clipboard",
            "format",
            "convert",
            "copy",
            "paste",
            "save",
            "json",
            "markdown"
        ]) {
            return .text
        }

        return .core
    }

    private static func containsAny(_ value: String, markers: [String]) -> Bool {
        markers.contains { marker in
            value.contains(marker)
        }
    }

    private static let scopeTokenToGroup: [String: CommandPaletteGroup] = [
        "core": .core,
        "main": .core,
        "ask": .ask,
        "q": .ask,
        "ai": .ask,
        "llm": .ask,
        "prompt": .ask,
        "question": .ask,
        "questions": .ask,
        "text": .text,
        "copy": .text,
        "paste": .text,
        "calc": .text,
        "math": .text,
        "unit": .text,
        "date": .text,
        "time": .text,
        "color": .text,
        "clipboard": .text,
        "format": .text,
        "saved": .saved,
        "save": .saved,
        "snippet": .saved,
        "snippets": .saved,
        "snip": .saved,
        "recent": .saved,
        "history": .saved,
        "clip": .saved,
        "clips": .saved,
        "link": .saved,
        "links": .saved,
        "bookmark": .saved,
        "bookmarks": .saved,
        "fav": .saved,
        "favorite": .saved,
        "favorites": .saved,
        "note": .saved,
        "notes": .saved,
        "stash": .saved,
        "open": .open,
        "file": .open,
        "folder": .open,
        "doc": .open,
        "docs": .open,
        "app": .open,
        "apps": .open,
        "launch": .open,
        "web": .open,
        "site": .open,
        "website": .open,
        "browser": .open,
        "browse": .open,
        "finder": .open,
        "url": .open,
        "path": .open,
        "window": .window,
        "win": .window,
        "tile": .window,
        "snap": .window,
        "layout": .window,
        "display": .window,
        "monitor": .window,
        "settings": .settings,
        "setup": .settings,
        "checklist": .settings,
        "onboard": .settings,
        "onboarding": .settings,
        "prefs": .settings,
        "preferences": .settings,
        "perm": .settings,
        "permission": .settings,
        "permissions": .settings,
        "grant": .settings,
        "privacy": .settings,
        "support": .support,
        "help": .support,
        "issue": .support,
        "bug": .support,
        "share": .support,
        "social": .support,
        "post": .support,
        "fame": .support,
        "viral": .support,
        "error": .support,
        "fix": .support,
        "repair": .support,
        "broken": .support,
        "blocked": .support,
        "stuck": .support,
        "diag": .support,
        "diagnostic": .support,
        "diagnose": .support,
        "trouble": .support,
        "troubleshoot": .support
    ]

    private static let scopeTokenToSourceKinds: [String: Set<CommandPaletteAction.SourceKind>] = [
        "snippet": [.snippet],
        "snippets": [.snippet],
        "snip": [.snippet],
        "note": [.snippet],
        "notes": [.snippet],
        "clipboard": [.clipboard],
        "clip": [.clipboard],
        "clips": [.clipboard],
        "recent": [.recent],
        "history": [.recent, .clipboard],
        "link": [.link],
        "links": [.link],
        "bookmark": [.link],
        "bookmarks": [.link],
        "app": [.app],
        "apps": [.app],
        "file": [.file, .path],
        "files": [.file, .path],
        "folder": [.folder, .path],
        "doc": [.file, .folder, .path],
        "docs": [.file, .folder, .path],
        "site": [.web, .link],
        "sites": [.web, .link],
        "web": [.web, .link],
        "website": [.web, .link],
        "browser": [.web, .link],
        "url": [.web, .link],
        "path": [.path, .file, .folder],
        "script": [.script],
        "scripts": [.script]
    ]
}

struct CommandPaletteScopedQuery {
    let group: CommandPaletteGroup?
    let sourceKinds: Set<CommandPaletteAction.SourceKind>?
    let searchQuery: String
    let hasScope: Bool
}

struct CommandPaletteLauncherHomeSection: Equatable {
    let title: String
    let actionIDs: [String]
}

struct CommandPaletteBrowseSummary: Equatable {
    struct Source: Identifiable, Equatable {
        let id: String
        let title: String
        let count: Int
        let systemImage: String
        let helpText: String

        var countTitle: String {
            CommandPaletteBrowseSummary.compactCountLabel(count)
        }
    }

    struct Scope: Identifiable, Equatable {
        let id: String
        let title: String
        let insertedText: String
        let systemImage: String
        let helpText: String
    }

    let detail: String
    let sources: [Source]
    let scopes: [Scope]

    static let empty = CommandPaletteBrowseSummary(detail: "", sources: [], scopes: [])

    nonisolated static func compactCountLabel(_ count: Int) -> String {
        let normalizedCount = max(0, count)
        switch normalizedCount {
        case 0..<1_000:
            return "\(normalizedCount)"
        case 1_000..<10_000:
            let thousands = Double(normalizedCount) / 1_000
            let rounded = (thousands * 10).rounded() / 10
            if rounded.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(rounded))k"
            }
            return String(format: "%.1fk", rounded)
        case 10_000..<1_000_000:
            return "\(Int((Double(normalizedCount) / 1_000).rounded()))k"
        default:
            let millions = Double(normalizedCount) / 1_000_000
            let rounded = (millions * 10).rounded() / 10
            if rounded.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(rounded))m"
            }
            return String(format: "%.1fm", rounded)
        }
    }
}

struct CommandPaletteTopPickContext {
    let hasText: Bool
    let hasAnswer: Bool
    let hasImage: Bool
    let hasError: Bool
    let llmEnabled: Bool
    let hasFreshOnboardingRecovery: Bool
    let onboardingRecoveryFollowupActionID: String?
    let onboardingRecoveryRemainingArtifacts: Int?

    init(
        hasText: Bool,
        hasAnswer: Bool,
        hasImage: Bool,
        hasError: Bool,
        llmEnabled: Bool,
        hasFreshOnboardingRecovery: Bool = false,
        onboardingRecoveryFollowupActionID: String? = nil,
        onboardingRecoveryRemainingArtifacts: Int? = nil
    ) {
        self.hasText = hasText
        self.hasAnswer = hasAnswer
        self.hasImage = hasImage
        self.hasError = hasError
        self.llmEnabled = llmEnabled
        self.hasFreshOnboardingRecovery = hasFreshOnboardingRecovery
        self.onboardingRecoveryFollowupActionID = onboardingRecoveryFollowupActionID
        self.onboardingRecoveryRemainingArtifacts = onboardingRecoveryRemainingArtifacts
    }
}

enum CommandPaletteTopPicks {
    struct OnboardingRecoverySnapshot: Equatable {
        let isFresh: Bool
        let followupActionID: String?
        let remainingArtifacts: Int?
    }

    struct RecommendationPairPromotionCandidate: Equatable {
        let sourceActionID: String
        let recommendedActionID: String
        let opportunities: Int
        let conversions: Int
        let opensSinceLastConversion: Int?

        init(
            sourceActionID: String,
            recommendedActionID: String,
            opportunities: Int,
            conversions: Int,
            opensSinceLastConversion: Int? = nil
        ) {
            self.sourceActionID = sourceActionID
            self.recommendedActionID = recommendedActionID
            self.opportunities = opportunities
            self.conversions = conversions
            self.opensSinceLastConversion = opensSinceLastConversion
        }
    }

    struct RecommendationPairRescuePlan: Equatable {
        let recommendedActionID: String
        let opportunities: Int
        let conversions: Int
        let opensSinceLastConversion: Int
        let conversionRatePercent: Int
    }

    struct RecommendationMomentumRescueImpactPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueFollowthroughCue: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueCelebrationCue: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationPairRescueConfidenceChipTone: Equatable {
        case proven
        case strong
        case watch
    }

    struct RecommendationPairRescueConfidenceChip: Equatable {
        let tone: RecommendationPairRescueConfidenceChipTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueLaneBadgeTone: Equatable {
        case active
        case cooling
    }

    struct RecommendationMomentumRescueLaneBadge: Equatable {
        let tone: RecommendationMomentumRescueLaneBadgeTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueLeaderboardBadgeTone: Equatable {
        case active
        case idle
    }

    struct RecommendationMomentumRescueLeaderboardBadge: Equatable {
        let tone: RecommendationMomentumRescueLeaderboardBadgeTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueLeaderboardCard: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueHallOfFameTrend: Equatable {
        case rising
        case steady
        case falling
    }

    struct RecommendationMomentumRescueHallOfFameBadge: Equatable {
        let trend: RecommendationMomentumRescueHallOfFameTrend
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameCard: Equatable {
        let trend: RecommendationMomentumRescueHallOfFameTrend
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueHallOfFameDefenseCueTone: Equatable {
        case chase
        case defense
    }

    struct RecommendationMomentumRescueHallOfFameDefenseCue: Equatable {
        let tone: RecommendationMomentumRescueHallOfFameDefenseCueTone
        let trend: RecommendationMomentumRescueHallOfFameTrend
        let title: String
        let subtitle: String
        let buttonTitle: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyReadiness: Equatable {
        case direct(actionID: String)
        case reroute(actionID: String)
        case unavailable
    }

    enum LaunchRecoveryHotKeyReadinessState: Equatable {
        case direct
        case reroute
        case standby
    }

    struct LaunchRecoveryHotKeyTrend: Equatable {
        let directCount: Int
        let rerouteCount: Int
        let standbyCount: Int

        var sampleCount: Int {
            directCount + rerouteCount + standbyCount
        }
    }

    enum LaunchRecoveryHotKeyWinMeterTone: Equatable {
        case rebuild
        case steady
        case surge
    }

    struct LaunchRecoveryHotKeyWinMeter: Equatable {
        let tone: LaunchRecoveryHotKeyWinMeterTone
        let wins: Int
        let sampleCount: Int
        let multiplier: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyWinDeltaTone: Equatable {
        case climbing
        case steady
        case slipping
    }

    struct LaunchRecoveryHotKeyWinDelta: Equatable {
        let tone: LaunchRecoveryHotKeyWinDeltaTone
        let currentWins: Int
        let previousWins: Int
        let sampleCount: Int
        let deltaWins: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum FameMomentumPanelTone: Equatable {
        case alert
        case watch
        case steady
        case prime
    }

    struct FameMomentumPanelReasonChip: Equatable, Identifiable {
        let title: String
        let systemImage: String
        let helpText: String

        var id: String { "\(title)|\(systemImage)" }
    }

    enum FameMomentumPanelActionRecency: Equatable {
        case recentlyValidated(opensAgo: Int)
        case aging(opensAgo: Int)
        case stale(opensAgo: Int)
    }

    enum FameMomentumPanelRouteFlipRhythmTone: Equatable {
        case stabilizing
        case watch
        case volatile
    }

    enum FameMomentumPanelSelectionConfidenceTier: Equatable {
        case locked
        case leaning
        case split
    }

    struct FameMomentumPanelSelectionConfidence: Equatable {
        let tier: FameMomentumPanelSelectionConfidenceTier
        let confidencePercent: Int
        let gapPoints: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct FameMomentumPanelRouteStabilizationCue: Equatable {
        enum Focus: Equatable {
            case primaryLock
            case primaryReset
            case dualTrack
        }

        let focus: Focus
        let title: String
        let subtitle: String
        let systemImage: String
        let buttonTitle: String
        let secondaryButtonTitle: String?
        let helpText: String
    }

    enum FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeTone: Equatable {
        case strong
        case watch
        case blocked
    }

    struct FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge: Equatable {
        let tone: FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    enum FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeTone: Equatable {
        case steady
        case watch
        case alert
    }

    struct FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge: Equatable {
        let tone: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeTone
        let confidencePercent: Int
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration: Equatable {
        let biasPoints: Int
        let sampleCount: Int
    }

    enum FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrendDirection: Equatable {
        case rising
        case cooling
        case steady
    }

    struct FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend: Equatable {
        let direction: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrendDirection
        let deltaPoints: Int
        let sampleCount: Int
        let subtitle: String
        let helpText: String
    }

    enum FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueTone: Equatable {
        case watch
        case blocked
    }

    struct FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue: Equatable {
        let tone: FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueTone
        let title: String
        let subtitle: String
        let systemImage: String
        let buttonTitle: String
        let helpText: String
    }

    enum FameMomentumPanelActionEmphasis: Equatable {
        case primaryDominant
        case splitDecision
    }

    struct FameMomentumPanel: Equatable {
        let tone: FameMomentumPanelTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String?
        let actionPrompt: String?
        let secondaryActionID: String?
        let secondaryActionPrompt: String?
        let actionScore: Int?
        let secondaryActionScore: Int?
        let actionRecency: FameMomentumPanelActionRecency?
        let secondaryActionRecency: FameMomentumPanelActionRecency?
        let selectionConfidence: FameMomentumPanelSelectionConfidence?
        let reasonChips: [FameMomentumPanelReasonChip]
        let routeFlipRhythmTone: FameMomentumPanelRouteFlipRhythmTone?
        let interventionTrustTrend: LaunchRecoveryHotKeyInterventionTrustTrend?
    }

    typealias FameMomentumPanelCandidate = (
        id: String,
        prompt: String,
        score: Int,
        offset: Int,
        observedImpact: Int,
        rescueConfidenceBonus: Int,
        recency: FameMomentumPanelActionRecency?,
        recencyBonus: Int,
        rhythmBonus: Int
    )

    struct LaunchRecoveryHotKeyMomentum: Equatable {
        enum Direction: Equatable {
            case rising
            case steady
            case falling
        }

        let direction: Direction
        let deltaPoints: Int
        let previousScore: Int
        let recentScore: Int
        let windowSize: Int
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyConfidenceScore: Equatable {
        enum Tier: Equatable {
            case critical
            case watch
            case steady
            case prime
        }

        let points: Int
        let tier: Tier
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyCoachCue: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let actionID: String
    }

    struct LaunchRecoveryHotKeyDecayPulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyRestorePulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyConfidencePulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyMomentumPulse: Equatable {
        enum Tone: Equatable {
            case rising
            case falling
        }

        let tone: Tone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyMomentumRescue: Equatable {
        enum Severity: Equatable {
            case watch
            case alert
        }

        let severity: Severity
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String?
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse: Equatable {
        let fromTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let toTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse: Equatable {
        let fromTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
        let toTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueHallOfFameLegendRiskPulseTone: Equatable {
        case watch
        case alert
    }

    struct RecommendationMomentumRescueHallOfFameLegendRiskPulse: Equatable {
        let tone: RecommendationMomentumRescueHallOfFameLegendRiskPulseTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTone: Equatable {
        case ready
        case alert
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse: Equatable {
        let tone: LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyLegendRiskStickyReleasePulse: Equatable {
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyInterventionTrustPulse: Equatable {
        enum Tone: Equatable {
            case rising
            case falling
        }

        let tone: Tone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyIntervention: Equatable {
        let actionID: String
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let impactScore: Int
        let recency: LaunchRecoveryHotKeyInterventionRecency?

        init(
            actionID: String,
            title: String,
            subtitle: String,
            systemImage: String,
            helpText: String,
            impactScore: Int,
            recency: LaunchRecoveryHotKeyInterventionRecency? = nil
        ) {
            self.actionID = actionID
            self.title = title
            self.subtitle = subtitle
            self.systemImage = systemImage
            self.helpText = helpText
            self.impactScore = impactScore
            self.recency = recency
        }
    }

    enum LaunchRecoveryHotKeyInterventionRecency: Equatable {
        case recentlyValidated(opensAgo: Int)
        case stale(opensAgo: Int)
    }

    enum LaunchRecoveryHotKeyInterventionImpactTone: Equatable {
        case positive
        case negative
    }

    enum LaunchRecoveryHotKeyInterventionRecencyTone: Equatable {
        case recent
        case stale
    }

    struct LaunchRecoveryHotKeyInterventionTrustTrend: Equatable {
        enum Direction: Equatable {
            case rising
            case steady
            case falling
        }

        let samples: [Int]
        let currentPoints: Int
        let deltaPoints: Int
        let direction: Direction
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyInterventionTrustMomentum: Equatable {
        let streak: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyInterventionTrustMomentumPlan: Equatable {
        let streak: Int
        let nextMilestone: Int
        let remainingOpens: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String?
    }

    struct LaunchRecoveryHotKeyInterventionTrustMomentumPulse: Equatable {
        let streak: Int
        let milestone: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyInterventionTrustGuard: Equatable {
        enum Severity: Equatable {
            case watch
            case critical
        }

        let severity: Severity
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyAutoCoachStatus: Equatable {
        case disabled
        case ready
        case coolingDown(minutesRemaining: Int)
    }

    enum LaunchRecoveryHotKeyAutoRescueStatus: Equatable {
        case disabled
        case ready
        case coolingDown(minutesRemaining: Int)
    }

    enum RecommendationMomentumRescueHallOfFameAutoDefenseStatus: Equatable {
        case disabled
        case ready
        case coolingDown(minutesRemaining: Int)
    }

    enum RecommendationMomentumRescueHallOfFameAutoDefenseBadgeTone: Equatable {
        case disabled
        case ready
        case coolingDown
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseBadge: Equatable {
        let tone: RecommendationMomentumRescueHallOfFameAutoDefenseBadgeTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge: Equatable {
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge: Equatable {
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge: Equatable {
        let title: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier: String, Codable, Equatable {
        case starter
        case rising
        case elite
        case legend
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge: Equatable {
        let tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress: Equatable {
        let tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
        let pointsToNextTier: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend: Equatable {
        enum Direction: Equatable {
            case rising
            case steady
            case falling
        }

        let direction: Direction
        let sampleCount: Int
        let scoreDelta: Int
        let fromTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
        let toTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum RecommendationMomentumRescueHallOfFameLegendRiskForecastTone: Equatable {
        case watch
        case alert
    }

    struct RecommendationMomentumRescueHallOfFameLegendRiskForecast: Equatable {
        let tone: RecommendationMomentumRescueHallOfFameLegendRiskForecastTone
        let riskLabel: String
        let nextDefenseMinutes: Int
        let nextDefenseLabel: String
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String?
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek: Codable, Equatable,
        Identifiable
    {
        let weekStamp: String
        let runsToday: Int
        let runsThisWeek: Int
        let bestWeekRuns: Int
        let currentStreak: Int
        let bestStreak: Int
        let leagueScore: Int
        let tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier

        var id: String { weekStamp }
    }

    enum RecommendationMomentumRescueHallOfFameAutoDefenseScorecardTone: Equatable {
        case disabled
        case ready
        case coolingDown
    }

    struct RecommendationMomentumRescueHallOfFameAutoDefenseScorecard: Equatable {
        let tone: RecommendationMomentumRescueHallOfFameAutoDefenseScorecardTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyAutoRescueBadgeTone: Equatable {
        case disabled
        case ready
        case coolingDown
    }

    struct LaunchRecoveryHotKeyAutoRescueBadge: Equatable {
        let tone: LaunchRecoveryHotKeyAutoRescueBadgeTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyAutoRescueRecencyBadge: Equatable {
        let title: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeStatus: Equatable {
        case disabled
        case ready
        case capped(runsToday: Int, dailyCap: Int)
        case coolingDown(minutesRemaining: Int)
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeBadgeTone: Equatable {
        case disabled
        case ready
        case capped
        case coolingDown
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeBadge: Equatable {
        let tone: LaunchRecoveryHotKeyAutoTrustSurgeBadgeTone
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge: Equatable {
        let title: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier: String, Codable, Equatable {
        case starter
        case rising
        case elite
        case legend
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge: Equatable {
        let tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress: Equatable {
        let tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let pointsToNextTier: Int
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend: Equatable {
        enum Direction: Equatable {
            case rising
            case steady
            case falling
        }

        let direction: Direction
        let sampleCount: Int
        let scoreDelta: Int
        let fromTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let toTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeLegendDefenseTone: Equatable {
        case watch
        case alert
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense: Equatable {
        let tone: LaunchRecoveryHotKeyAutoTrustSurgeLegendDefenseTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String?
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastTone: Equatable {
        case watch
        case alert
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast: Equatable {
        let tone: LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastTone
        let riskLabel: String
        let nextDefenseMinutes: Int
        let nextDefenseLabel: String
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String?
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek: Codable, Equatable, Identifiable {
        let weekStamp: String
        let runsToday: Int
        let runsThisWeek: Int
        let bestWeekRuns: Int
        let currentStreak: Int
        let bestStreak: Int
        let leagueScore: Int
        let tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier

        var id: String { weekStamp }
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition: Equatable {
        let fromTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let toTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
        let weekStamp: String
    }

    enum LaunchRecoveryHotKeyAutoTrustSurgeInsightTone: Equatable {
        case standby
        case primed
        case climbing
        case podium
        case coolingDown
        case capped
    }

    struct LaunchRecoveryHotKeyAutoTrustSurgeInsight: Equatable {
        let tone: LaunchRecoveryHotKeyAutoTrustSurgeInsightTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
    }

    enum BestChannelLaunchPackPressureTone: Equatable {
        case watch
        case alert
    }

    enum BestChannelLaunchPackPressureTrend: Equatable {
        case noOpportunities
        case noWins
        case cooling
        case rebuilding
        case compounding
    }

    struct BestChannelLaunchPackPressureModeTransition: Equatable {
        let previousTrend: BestChannelLaunchPackPressureTrend
        let trend: BestChannelLaunchPackPressureTrend
    }

    private struct BestChannelLaunchPackPressureModeShiftSnapshot: Equatable {
        let fromToken: String
        let toToken: String
        let fromTitle: String
        let toTitle: String
    }

    private enum BestChannelLaunchPackPressureModeTrajectoryBias: Equatable {
        case none
        case momentumUpshift
        case recoveryUpshift
        case coolingDownshift
    }

    struct BestChannelLaunchPackPressureCard: Equatable {
        let tone: BestChannelLaunchPackPressureTone
        let title: String
        let subtitle: String
        let systemImage: String
        let helpText: String
        let actionID: String
    }

    private static let pulsePressurePromotedActionIDs = [
        "run-fame-cadence-autopilot-loop",
        "copy-next-move-launch-now-sequence",
        "copy-next-move-cadence-execution-kit",
        "copy-next-move-cadence-post-queue",
        "copy-next-move-reply-ladder",
        "copy-next-move-cadence-post",
        "copy-next-move-cadence-step",
        "copy-next-move-best-channel-launch-pack",
        "copy-next-move-best-channel-draft",
        "copy-fame-cadence-share-pack",
        "copy-next-move-x-draft",
        "copy-next-move-bluesky-draft",
        "copy-next-move-linkedin-draft",
        "copy-next-move-drafts"
    ]

    private static let launchHealthRiskWatchPromotedActionIDs = [
        "copy-next-move-best-channel-launch-pack",
        "copy-next-move-best-channel-draft"
    ]

    private static let onboardingRecoveryPromotedFallbackActionIDs = [
        "run-fame-onboarding-fill-gap",
        "run-fame-onboarding-scorecard",
        "run-fame-onboarding-daily-brief",
        "run-fame-onboarding-nudge",
        "run-fame-next-move-cadence-execution-kit",
        "run-fame-cadence-autopilot-loop"
    ]

    private static let launchRecoveryCoachActionIDs = [
        "run-fame-onboarding-fill-gap",
        "run-fame-onboarding-scorecard",
        "run-fame-onboarding-daily-brief",
        "run-fame-onboarding-nudge"
    ]

    private static let launchRecoveryInterventionCriticalOrder = [
        "run-fame-onboarding-fill-gap",
        "run-fame-onboarding-scorecard",
        "run-fame-onboarding-daily-brief",
        "run-fame-onboarding-nudge",
        "run-fame-cadence-autopilot-loop"
    ]

    private static let launchRecoveryInterventionWatchOrder = [
        "run-fame-onboarding-scorecard",
        "run-fame-onboarding-daily-brief",
        "run-fame-onboarding-fill-gap",
        "run-fame-onboarding-nudge",
        "run-fame-cadence-autopilot-loop"
    ]

    private static let launchRecoveryInterventionActionIDs: Set<String> = Set(
        launchRecoveryInterventionCriticalOrder +
            launchRecoveryInterventionWatchOrder +
            [CommandPaletteAction.launchRecoveryNextActionID]
    )

    private static let fameMomentumPanelRouteStabilizationRecoveryUnblockActionPriority = [
        "run-fame-launch-control-health",
        "run-fame-launch-control-brief",
        "run-fame-risk-timeline",
        "run-fame-next-move-cadence-execution-kit"
    ]

    private static let fameMomentumPanelRouteStabilizationRecoveryUnblockActionIDs: Set<String> = Set(
        fameMomentumPanelRouteStabilizationRecoveryUnblockActionPriority
    )

    private static let fameMomentumPanelRouteStabilizationRecoveryActionPriority = [
        CommandPaletteAction.launchRecoveryNextActionID,
        "run-fame-recovery-sprint",
        "run-fame-recovery-checklist",
        "run-fame-recovery-proof-pack",
        "run-fame-onboarding-fill-gap",
        "run-fame-cadence-autopilot-loop"
    ] + fameMomentumPanelRouteStabilizationRecoveryUnblockActionPriority

    private static let idleStateActionIDs = [
        "pick-and-read",
        "read-selected",
        "ask-anything",
        "run-best-local-action",
        "run-fame-onboarding-fill-gap",
        "run-fame-onboarding-daily-brief",
        "run-fame-onboarding-scorecard",
        "run-fame-onboarding-nudge",
        "open-latest-onboarding-suite",
        "open-latest-onboarding-daily-brief",
        "open-latest-onboarding-scorecard",
        "open-latest-onboarding-nudge",
        "unmute-fame-launch-threshold-alerts-now",
        "unmute-fame-launch-threshold-alerts-snooze-ending-soon",
        "extend-fame-launch-threshold-alerts-snooze-ending-soon",
        "snooze-fame-launch-threshold-alerts-recommended",
        "run-fame-launch-control-health",
        "run-fame-launch-recovery-next",
        "run-fame-launch-alert",
        "run-fame-launch-rescue-burst",
        "run-fame-launch-control-brief",
        "copy-fame-launch-control-brief",
        "run-fame-launch-rescue-burst-auto-status",
        "run-fame-next-move",
        "run-fame-cadence-autopilot-loop",
        "run-fame-next-move-cadence-execution-kit",
        "run-fame-next-move-copy-drafts",
        "run-fame-pulse-alert",
        "run-fame-cadence-momentum-brief",
        "copy-fame-cadence-share-line",
        "copy-fame-cadence-share-pack",
        "run-fame-cadence-celebration-demo",
        "run-fame-recovery-sprint",
        "run-fame-recovery-checklist",
        "run-fame-recovery-proof-pack",
        "run-fame-risk-timeline",
        "open-latest-recovery-sprint",
        "open-latest-recovery-checklist",
        "open-latest-recovery-proof-pack",
        "open-latest-command-center",
        "open-latest-next-move-handoff",
        "open-latest-cadence-momentum-brief",
        "open-latest-cadence-share-line",
        "open-latest-cadence-share-pack",
        "copy-next-move-launch-now-sequence",
        "copy-next-move-cadence-execution-kit",
        "copy-next-move-cadence-post-queue",
        "copy-next-move-reply-ladder",
        "copy-next-move-cadence-post",
        "copy-next-move-drafts",
        "copy-next-move-best-channel-launch-pack",
        "copy-next-move-best-channel-draft",
        "open-latest-daily-checkpoint",
        "open-latest-risk-timeline",
        "open-latest-pulse-nudge",
        "open-latest-daily-scorecard",
        "run-fame-sprint",
        "run-fame-sprint-snapshot",
        "run-fame-morning-brief",
        "run-fame-midday-brief",
        "run-fame-evening-brief",
        "run-fame-weekly-rollup",
        "run-fame-24h-queue",
        "run-fame-command-center",
        "run-fame-auto-bundle-status",
        "run-fame-ops-bundle",
        "run-fame-daily-checkpoint",
        "run-fame-daily-scorecard",
        "run-fame-escalation-nudge",
        "run-fame-operator-dashboard",
        "run-fame-narrative-lab",
        "run-fame-spotlight-pack",
        "run-fame-launch-day-script",
        "run-fame-launch-countdown",
        "run-fame-pulse-nudge",
        "open-fame-snapshot-folder",
        "open-latest-operator-dashboard",
        "open-latest-narrative-lab",
        "open-latest-spotlight-pack",
        "open-latest-launch-day-script",
        "open-latest-launch-countdown",
        "open-latest-launch-rescue-burst",
        "open-latest-launch-control-brief",
        "open-latest-morning-brief",
        "open-latest-midday-brief",
        "open-latest-evening-brief",
        "open-latest-escalation-nudge",
        "copy-fame-pack",
        "copy-founder-command-presets",
        "copy-win-card",
        "copy-fame-sprint",
        "save-fame-pack",
        "copy-experiment-board",
        "setup-checklist"
    ]

    private static let fallbackActionIDs = idleStateActionIDs

    static func onboardingRecoverySnapshot(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        freshnessWindowMinutes: Int = AppDefaults.fameOnboardingGapRecoveryTopPickWindowMinutes
    ) -> OnboardingRecoverySnapshot {
        guard defaults.object(forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey) != nil else {
            return OnboardingRecoverySnapshot(
                isFresh: false,
                followupActionID: nil,
                remainingArtifacts: nil
            )
        }

        let timestamp = defaults.double(forKey: AppDefaults.fameOnboardingGapRecoveryLastAtKey)
        guard timestamp > 0 else {
            return OnboardingRecoverySnapshot(
                isFresh: false,
                followupActionID: nil,
                remainingArtifacts: nil
            )
        }

        let freshnessWindow = TimeInterval(max(1, freshnessWindowMinutes) * 60)
        let elapsed = max(0, now.timeIntervalSince(Date(timeIntervalSince1970: timestamp)))
        guard elapsed <= freshnessWindow else {
            return OnboardingRecoverySnapshot(
                isFresh: false,
                followupActionID: nil,
                remainingArtifacts: nil
            )
        }

        let followupActionID = defaults.string(
            forKey: AppDefaults.fameOnboardingGapRecoveryFollowupCommandIDKey
        )?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedFollowupActionID = followupActionID?.isEmpty == true ? nil : followupActionID

        let remainingArtifacts: Int?
        if defaults.object(forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey) != nil {
            remainingArtifacts = max(
                0,
                defaults.integer(forKey: AppDefaults.fameOnboardingGapRecoveryRemainingArtifactsKey)
            )
        } else {
            remainingArtifacts = nil
        }

        return OnboardingRecoverySnapshot(
            isFresh: true,
            followupActionID: normalizedFollowupActionID,
            remainingArtifacts: remainingArtifacts
        )
    }

    static func pickActions(
        from actions: [CommandPaletteAction],
        context: CommandPaletteTopPickContext,
        usageRecords: [String: CommandUsageRecord] = [:],
        favoriteActionIDs: Set<String> = [],
        priorityPromotedActionIDs: [String] = [],
        promotedActionIDs: [String] = [],
        limit: Int = 4
    ) -> [CommandPaletteAction] {
        guard limit > 0 else { return [] }

        let enabledActions = actions.filter(\.isEnabled)
        guard !enabledActions.isEmpty else { return [] }

        let actionOrder = Dictionary(uniqueKeysWithValues: actions.enumerated().map { ($0.element.id, $0.offset) })
        var selectedActions: [CommandPaletteAction] = []
        var usedActionIDs: Set<String> = []

        let enabledByID = Dictionary(uniqueKeysWithValues: enabledActions.map { ($0.id, $0) })
        let orderedCandidateIDs = preferredActionIDs(
            for: context,
            enabledActionIDs: Set(enabledByID.keys),
            enabledActionsByID: enabledByID
        ) + fallbackActionIDs

        func appendPromotedActionIDs(_ actionIDs: [String]) -> Bool {
            for actionID in actionIDs {
                guard let action = enabledByID[actionID], !usedActionIDs.contains(action.id) else {
                    continue
                }
                selectedActions.append(action)
                usedActionIDs.insert(action.id)
                if selectedActions.count >= limit {
                    return true
                }
            }
            return false
        }

        if appendPromotedActionIDs(priorityPromotedActionIDs) {
            return selectedActions
        }

        if isIdleState(context) {
            let idleFavorites = enabledActions
                .filter { favoriteActionIDs.contains($0.id) && $0.canFavorite }
                .sorted {
                    compareByUsage(
                        lhs: $0,
                        rhs: $1,
                        usageRecords: usageRecords,
                        actionOrder: actionOrder
                    )
                }

            for action in idleFavorites where !usedActionIDs.contains(action.id) {
                selectedActions.append(action)
                usedActionIDs.insert(action.id)
                if selectedActions.count >= limit {
                    return selectedActions
                }
            }
        }

        if appendPromotedActionIDs(promotedActionIDs) {
            return selectedActions
        }

        for actionID in orderedCandidateIDs {
            guard let action = enabledByID[actionID], !usedActionIDs.contains(action.id) else { continue }
            selectedActions.append(action)
            usedActionIDs.insert(action.id)
            if selectedActions.count >= limit {
                return selectedActions
            }
        }

        let remainingActions = enabledActions.sorted {
            compareByUsage(lhs: $0, rhs: $1, usageRecords: usageRecords, actionOrder: actionOrder)
        }

        for action in remainingActions where !usedActionIDs.contains(action.id) {
            selectedActions.append(action)
            usedActionIDs.insert(action.id)
            if selectedActions.count >= limit {
                break
            }
        }

        return selectedActions
    }

    static func recommendationPairPromotedActionID(
        sourceActionID: String,
        recommendedActionID: String,
        opportunities: Int,
        conversions: Int,
        enabledActionIDs: Set<String>,
        minimumHighConfidenceOpportunities: Int = 5
    ) -> String? {
        let normalizedSourceActionID = sourceActionID
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRecommendedActionID = recommendedActionID
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSourceActionID.isEmpty,
              !normalizedRecommendedActionID.isEmpty,
              normalizedSourceActionID != normalizedRecommendedActionID,
              enabledActionIDs.contains(normalizedRecommendedActionID) else {
            return nil
        }

        guard recommendationPairIsHighConfidence(
            opportunities: opportunities,
            conversionCount: conversions,
            minimumHighConfidenceOpportunities: minimumHighConfidenceOpportunities
        ) else {
            return nil
        }
        return normalizedRecommendedActionID
    }

    static func recommendationPairPromotedActionID(
        candidates: [RecommendationPairPromotionCandidate],
        enabledActionIDs: Set<String>,
        minimumHighConfidenceOpportunities: Int = 5,
        activeRescueStreak: Int = 0
    ) -> String? {
        let normalizedMinimumOpportunities = max(3, minimumHighConfidenceOpportunities)
        var bestCandidate: (
            recommendedActionID: String,
            effectiveOpportunities: Int,
            opportunities: Int,
            conversionRate: Double,
            conversions: Int,
            opensSinceLastConversion: Int?
        )?

        for candidate in candidates {
            guard let promotedActionID = recommendationPairPromotedActionID(
                sourceActionID: candidate.sourceActionID,
                recommendedActionID: candidate.recommendedActionID,
                opportunities: candidate.opportunities,
                conversions: candidate.conversions,
                enabledActionIDs: enabledActionIDs,
                minimumHighConfidenceOpportunities: normalizedMinimumOpportunities
            ) else {
                continue
            }
            let normalizedOpportunities = max(0, candidate.opportunities)
            let normalizedConversions = min(
                normalizedOpportunities,
                max(0, candidate.conversions)
            )
            let conversionRate = normalizedOpportunities > 0
                ? Double(normalizedConversions) / Double(normalizedOpportunities)
                : 0
            let normalizedOpensSinceLastConversion = candidate.opensSinceLastConversion.map { max(0, $0) }
            let recencyScore = recommendationPairRecencyScore(
                opensSinceLastConversion: normalizedOpensSinceLastConversion
            )
            let rescueMomentumBias = recommendationPairRescueMomentumBias(
                activeRescueStreak: activeRescueStreak,
                opportunities: normalizedOpportunities,
                conversions: normalizedConversions,
                opensSinceLastConversion: normalizedOpensSinceLastConversion,
                minimumHighConfidenceOpportunities: normalizedMinimumOpportunities
            )
            let effectiveOpportunities = normalizedOpportunities + recencyScore + rescueMomentumBias

            guard let best = bestCandidate else {
                bestCandidate = (
                    recommendedActionID: promotedActionID,
                    effectiveOpportunities: effectiveOpportunities,
                    opportunities: normalizedOpportunities,
                    conversionRate: conversionRate,
                    conversions: normalizedConversions,
                    opensSinceLastConversion: normalizedOpensSinceLastConversion
                )
                continue
            }

            let shouldReplaceBest =
                effectiveOpportunities > best.effectiveOpportunities ||
                (effectiveOpportunities == best.effectiveOpportunities &&
                    normalizedOpportunities > best.opportunities) ||
                (effectiveOpportunities == best.effectiveOpportunities &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate > best.conversionRate) ||
                (effectiveOpportunities == best.effectiveOpportunities &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate == best.conversionRate &&
                    normalizedConversions > best.conversions) ||
                (effectiveOpportunities == best.effectiveOpportunities &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate == best.conversionRate &&
                    normalizedConversions == best.conversions &&
                    (normalizedOpensSinceLastConversion ?? Int.max) <
                    (best.opensSinceLastConversion ?? Int.max)) ||
                (effectiveOpportunities == best.effectiveOpportunities &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate == best.conversionRate &&
                    normalizedConversions == best.conversions &&
                    (normalizedOpensSinceLastConversion ?? Int.max) ==
                    (best.opensSinceLastConversion ?? Int.max) &&
                    promotedActionID < best.recommendedActionID)
            if shouldReplaceBest {
                bestCandidate = (
                    recommendedActionID: promotedActionID,
                    effectiveOpportunities: effectiveOpportunities,
                    opportunities: normalizedOpportunities,
                    conversionRate: conversionRate,
                    conversions: normalizedConversions,
                    opensSinceLastConversion: normalizedOpensSinceLastConversion
                )
            }
        }

        return bestCandidate?.recommendedActionID
    }

    static func recommendationPairIsHighConfidence(
        opportunities: Int,
        conversionCount: Int,
        minimumHighConfidenceOpportunities: Int = 5
    ) -> Bool {
        let normalizedOpportunities = max(0, opportunities)
        let requiredOpportunities = max(3, minimumHighConfidenceOpportunities)
        guard normalizedOpportunities >= requiredOpportunities else {
            return false
        }
        let normalizedConversionCount = min(
            normalizedOpportunities,
            max(0, conversionCount)
        )
        guard normalizedConversionCount > 0 else {
            return false
        }
        let conversionRate = Double(normalizedConversionCount) / Double(normalizedOpportunities)
        return conversionRate >= 0.7
    }

    private static func recommendationPairRecencyBonus(
        opensSinceLastConversion: Int?
    ) -> Int {
        guard let normalizedOpensSinceLastConversion = opensSinceLastConversion else {
            return 0
        }
        switch normalizedOpensSinceLastConversion {
        case ...1:
            return 3
        case ...3:
            return 2
        case ...6:
            return 1
        default:
            return 0
        }
    }

    private static func recommendationPairStalenessPenalty(
        opensSinceLastConversion: Int?
    ) -> Int {
        guard let normalizedOpensSinceLastConversion = opensSinceLastConversion else {
            return 0
        }
        switch normalizedOpensSinceLastConversion {
        case 0...9:
            return 0
        case 10...14:
            return 1
        case 15...24:
            return 2
        default:
            return 3
        }
    }

    private static func recommendationPairRecencyScore(
        opensSinceLastConversion: Int?
    ) -> Int {
        recommendationPairRecencyBonus(opensSinceLastConversion: opensSinceLastConversion) -
            recommendationPairStalenessPenalty(opensSinceLastConversion: opensSinceLastConversion)
    }

    private static func recommendationPairRescueMomentumBias(
        activeRescueStreak: Int,
        opportunities: Int,
        conversions: Int,
        opensSinceLastConversion: Int?,
        minimumHighConfidenceOpportunities: Int
    ) -> Int {
        let normalizedRescueStreak = max(0, activeRescueStreak)
        guard normalizedRescueStreak > 0 else { return 0 }
        guard let normalizedOpensSinceLastConversion = opensSinceLastConversion else { return 0 }
        guard normalizedOpensSinceLastConversion >= 7 else { return 0 }
        guard recommendationPairIsHighConfidence(
            opportunities: opportunities,
            conversionCount: conversions,
            minimumHighConfidenceOpportunities: minimumHighConfidenceOpportunities
        ) else {
            return 0
        }
        switch normalizedRescueStreak {
        case ...2:
            return 2
        case ...4:
            return 4
        case ...7:
            return 6
        default:
            return 8
        }
    }

    static func recommendationPairRescueActionID(
        candidates: [RecommendationPairPromotionCandidate],
        enabledActionIDs: Set<String>,
        minimumHighConfidenceOpportunities: Int = 5,
        minimumColdOpensSinceLastConversion: Int = 7
    ) -> String? {
        recommendationPairRescuePlan(
            candidates: candidates,
            enabledActionIDs: enabledActionIDs,
            minimumHighConfidenceOpportunities: minimumHighConfidenceOpportunities,
            minimumColdOpensSinceLastConversion: minimumColdOpensSinceLastConversion
        )?
        .recommendedActionID
    }

    static func recommendationPairRescuePlan(
        candidates: [RecommendationPairPromotionCandidate],
        enabledActionIDs: Set<String>,
        minimumHighConfidenceOpportunities: Int = 5,
        minimumColdOpensSinceLastConversion: Int = 7
    ) -> RecommendationPairRescuePlan? {
        let normalizedMinimumOpportunities = max(3, minimumHighConfidenceOpportunities)
        let normalizedMinimumColdOpensSinceLastConversion = max(
            1,
            minimumColdOpensSinceLastConversion
        )
        var bestCandidate: (
            recommendedActionID: String,
            opensSinceLastConversion: Int,
            opportunities: Int,
            conversionRate: Double,
            conversions: Int
        )?

        for candidate in candidates {
            guard let promotedActionID = recommendationPairPromotedActionID(
                sourceActionID: candidate.sourceActionID,
                recommendedActionID: candidate.recommendedActionID,
                opportunities: candidate.opportunities,
                conversions: candidate.conversions,
                enabledActionIDs: enabledActionIDs,
                minimumHighConfidenceOpportunities: normalizedMinimumOpportunities
            ) else {
                continue
            }
            guard let opensSinceLastConversion = candidate.opensSinceLastConversion else { continue }
            let normalizedOpensSinceLastConversion = max(0, opensSinceLastConversion)
            guard normalizedOpensSinceLastConversion >=
                normalizedMinimumColdOpensSinceLastConversion else {
                continue
            }

            let normalizedOpportunities = max(0, candidate.opportunities)
            let normalizedConversions = min(
                normalizedOpportunities,
                max(0, candidate.conversions)
            )
            let conversionRate = normalizedOpportunities > 0
                ? Double(normalizedConversions) / Double(normalizedOpportunities)
                : 0

            guard let best = bestCandidate else {
                bestCandidate = (
                    recommendedActionID: promotedActionID,
                    opensSinceLastConversion: normalizedOpensSinceLastConversion,
                    opportunities: normalizedOpportunities,
                    conversionRate: conversionRate,
                    conversions: normalizedConversions
                )
                continue
            }

            let shouldReplaceBest =
                normalizedOpensSinceLastConversion > best.opensSinceLastConversion ||
                (normalizedOpensSinceLastConversion == best.opensSinceLastConversion &&
                    normalizedOpportunities > best.opportunities) ||
                (normalizedOpensSinceLastConversion == best.opensSinceLastConversion &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate > best.conversionRate) ||
                (normalizedOpensSinceLastConversion == best.opensSinceLastConversion &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate == best.conversionRate &&
                    normalizedConversions > best.conversions) ||
                (normalizedOpensSinceLastConversion == best.opensSinceLastConversion &&
                    normalizedOpportunities == best.opportunities &&
                    conversionRate == best.conversionRate &&
                    normalizedConversions == best.conversions &&
                    promotedActionID < best.recommendedActionID)
            if shouldReplaceBest {
                bestCandidate = (
                    recommendedActionID: promotedActionID,
                    opensSinceLastConversion: normalizedOpensSinceLastConversion,
                    opportunities: normalizedOpportunities,
                    conversionRate: conversionRate,
                    conversions: normalizedConversions
                )
            }
        }

        guard let bestCandidate else { return nil }
        let conversionRatePercent = bestCandidate.opportunities > 0
            ? Int(
                (Double(bestCandidate.conversions) / Double(bestCandidate.opportunities) * 100).rounded()
            )
            : 0
        return RecommendationPairRescuePlan(
            recommendedActionID: bestCandidate.recommendedActionID,
            opportunities: bestCandidate.opportunities,
            conversions: bestCandidate.conversions,
            opensSinceLastConversion: bestCandidate.opensSinceLastConversion,
            conversionRatePercent: conversionRatePercent
        )
    }

    static func recommendationMomentumRescueLaneBadge(
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueLaneBadge? {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(
            normalizedCurrentStreak,
            max(0, bestStreak)
        )
        guard normalizedCurrentStreak > 0 || normalizedBestStreak > 0 else {
            return nil
        }

        if normalizedCurrentStreak > 0 {
            let currentTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
            let tierProgressLine: String
            if let nextTierTitle = currentTier.nextTierTitle,
               let nextTierThreshold = currentTier.nextTierThreshold {
                tierProgressLine = "Current x\(normalizedCurrentStreak) (\(currentTier.title)), best x\(normalizedBestStreak); next \(nextTierTitle) at x\(nextTierThreshold)."
            } else {
                tierProgressLine = "Current x\(normalizedCurrentStreak) (\(currentTier.title)), best x\(normalizedBestStreak); legend pace locked."
            }
            return RecommendationMomentumRescueLaneBadge(
                tone: .active,
                title: "Rescue Lane Active",
                systemImage: currentTier.systemImage,
                helpText: "Top Picks is biasing cold high-confidence recommendation pairs because rescue lane is active. \(tierProgressLine)"
            )
        }

        let bestTier = recommendationMomentumRescueTier(for: normalizedBestStreak)
        return RecommendationMomentumRescueLaneBadge(
            tone: .cooling,
            title: "Rescue Lane Cooling",
            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
            helpText: "Rescue lane promotions are paused until the next cold high-confidence recovery. Last best x\(normalizedBestStreak) (\(bestTier.title))."
        )
    }

    static func recommendationMomentumRescueLaneDetailLine(
        currentStreak: Int,
        bestStreak: Int
    ) -> String? {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(
            normalizedCurrentStreak,
            max(0, bestStreak)
        )
        guard normalizedCurrentStreak > 0 || normalizedBestStreak > 0 else {
            return nil
        }

        if normalizedCurrentStreak > 0 {
            let currentTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
            if let nextTierTitle = currentTier.nextTierTitle,
               let nextTierThreshold = currentTier.nextTierThreshold {
                return "Rescue lane \(currentTier.title) active · run x\(normalizedCurrentStreak) · best x\(normalizedBestStreak) · next \(nextTierTitle) at x\(nextTierThreshold). Top Picks is biasing cold high-confidence recoveries."
            }
            return "Rescue lane \(currentTier.title) active · run x\(normalizedCurrentStreak) · best x\(normalizedBestStreak) · legend pace locked. Top Picks is biasing cold high-confidence recoveries."
        }

        let bestTier = recommendationMomentumRescueTier(for: normalizedBestStreak)
        return "Rescue lane cooling · best x\(normalizedBestStreak) (\(bestTier.title)). Promotions resume after the next cold high-confidence recovery."
    }

    static func recommendationMomentumRescueLeaderboardBadge(
        runsToday: Int,
        bestDayRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueLeaderboardBadge? {
        let normalizedRunsToday = max(0, runsToday)
        let normalizedBestDayRuns = max(normalizedRunsToday, max(0, bestDayRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        guard normalizedBestDayRuns > 0 || normalizedBestStreak > 0 else { return nil }

        if normalizedRunsToday > 0 {
            let systemImage = normalizedRunsToday >= normalizedBestDayRuns
                ? "trophy.fill"
                : "chart.line.uptrend.xyaxis"
            return RecommendationMomentumRescueLeaderboardBadge(
                tone: .active,
                title: "Rescue Board \(normalizedRunsToday) Today",
                systemImage: systemImage,
                helpText: "Rescue leaderboard is live with \(normalizedRunsToday) today, best day \(normalizedBestDayRuns), lane run x\(normalizedCurrentStreak), and best lane x\(normalizedBestStreak)."
            )
        }

        return RecommendationMomentumRescueLeaderboardBadge(
            tone: .idle,
            title: "Rescue Board Best \(normalizedBestDayRuns)",
            systemImage: "medal.fill",
            helpText: "Rescue leaderboard best day is \(normalizedBestDayRuns). No rescue conversions landed yet today."
        )
    }

    static func recommendationMomentumRescueLeaderboardCard(
        runsToday: Int,
        bestDayRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueLeaderboardCard? {
        let normalizedRunsToday = max(0, runsToday)
        let normalizedBestDayRuns = max(normalizedRunsToday, max(0, bestDayRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        guard normalizedBestDayRuns > 0 || normalizedBestStreak > 0 else { return nil }

        let laneLine: String
        if normalizedCurrentStreak > 0 {
            let currentTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
            laneLine = "Lane \(currentTier.title) active at x\(normalizedCurrentStreak) · best x\(normalizedBestStreak)."
        } else if normalizedBestStreak > 0 {
            let bestTier = recommendationMomentumRescueTier(for: normalizedBestStreak)
            laneLine = "Lane cooling with best x\(normalizedBestStreak) (\(bestTier.title))."
        } else {
            laneLine = "Lane is waiting for the first rescue chain."
        }

        if normalizedRunsToday == 0 {
            let helpText = "Best rescue day: \(normalizedBestDayRuns). \(laneLine) Land one rescue conversion to re-open today’s board."
            return RecommendationMomentumRescueLeaderboardCard(
                title: "Rescue Leaderboard · Best Day \(normalizedBestDayRuns)",
                subtitle: "No rescue conversions landed today yet. Land one to restart the board.",
                systemImage: "medal.fill",
                helpText: helpText
            )
        }

        if normalizedRunsToday >= normalizedBestDayRuns {
            let helpText = "Today matched the all-time rescue day at \(normalizedBestDayRuns). \(laneLine)"
            return RecommendationMomentumRescueLeaderboardCard(
                title: "Rescue Leaderboard · Tied Best Day",
                subtitle: "Today is at \(normalizedRunsToday), matching the all-time best rescue day.",
                systemImage: "trophy.fill",
                helpText: helpText
            )
        }

        let runsToTie = max(1, normalizedBestDayRuns - normalizedRunsToday)
        let runWord = runsToTie == 1 ? "rescue" : "rescues"
        let helpText = "Today is \(normalizedRunsToday) with \(runsToTie) more \(runWord) needed to tie best day \(normalizedBestDayRuns). \(laneLine)"
        return RecommendationMomentumRescueLeaderboardCard(
            title: "Rescue Leaderboard · \(normalizedRunsToday) Today",
            subtitle: "\(runsToTie) more \(runWord) to tie best day \(normalizedBestDayRuns).",
            systemImage: runsToTie == 1 ? "bolt.fill" : "chart.bar.fill",
            helpText: helpText
        )
    }

    static func recommendationMomentumRescueHallOfFameBadge(
        runsThisWeek: Int,
        bestWeekRuns: Int,
        previousWeekRuns: Int
    ) -> RecommendationMomentumRescueHallOfFameBadge? {
        let normalizedRunsThisWeek = max(0, runsThisWeek)
        let normalizedBestWeekRuns = max(normalizedRunsThisWeek, max(0, bestWeekRuns))
        let normalizedPreviousWeekRuns = max(0, previousWeekRuns)
        guard normalizedBestWeekRuns > 0 || normalizedPreviousWeekRuns > 0 else { return nil }

        let trend = recommendationMomentumRescueHallOfFameTrend(
            runsThisWeek: normalizedRunsThisWeek,
            previousWeekRuns: normalizedPreviousWeekRuns
        )
        let systemImage = recommendationMomentumRescueHallOfFameSystemImage(trend: trend)
        if normalizedRunsThisWeek == 0 {
            return RecommendationMomentumRescueHallOfFameBadge(
                trend: trend,
                title: "Hall of Fame Best \(normalizedBestWeekRuns)",
                systemImage: systemImage,
                helpText: recommendationMomentumRescueHallOfFameTrendLine(
                    trend: trend,
                    runsThisWeek: normalizedRunsThisWeek,
                    previousWeekRuns: normalizedPreviousWeekRuns,
                    bestWeekRuns: normalizedBestWeekRuns
                )
            )
        }
        return RecommendationMomentumRescueHallOfFameBadge(
            trend: trend,
            title: "Hall of Fame \(normalizedRunsThisWeek) Wk",
            systemImage: systemImage,
            helpText: recommendationMomentumRescueHallOfFameTrendLine(
                trend: trend,
                runsThisWeek: normalizedRunsThisWeek,
                previousWeekRuns: normalizedPreviousWeekRuns,
                bestWeekRuns: normalizedBestWeekRuns
            )
        )
    }

    static func recommendationMomentumRescueHallOfFameCard(
        runsThisWeek: Int,
        bestWeekRuns: Int,
        previousWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameCard? {
        let normalizedRunsThisWeek = max(0, runsThisWeek)
        let normalizedBestWeekRuns = max(normalizedRunsThisWeek, max(0, bestWeekRuns))
        let normalizedPreviousWeekRuns = max(0, previousWeekRuns)
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        guard normalizedBestWeekRuns > 0 || normalizedBestStreak > 0 else { return nil }

        let trend = recommendationMomentumRescueHallOfFameTrend(
            runsThisWeek: normalizedRunsThisWeek,
            previousWeekRuns: normalizedPreviousWeekRuns
        )
        let systemImage = recommendationMomentumRescueHallOfFameSystemImage(trend: trend)
        let recordTarget = max(1, normalizedBestWeekRuns + 1)
        let runsToRecord = max(1, recordTarget - normalizedRunsThisWeek)
        let rescueWord = runsToRecord == 1 ? "rescue" : "rescues"
        let laneLine: String
        if normalizedCurrentStreak > 0 {
            let currentTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
            laneLine = "Lane \(currentTier.title) active at x\(normalizedCurrentStreak) · best x\(normalizedBestStreak)."
        } else if normalizedBestStreak > 0 {
            let bestTier = recommendationMomentumRescueTier(for: normalizedBestStreak)
            laneLine = "Lane cooling with best x\(normalizedBestStreak) (\(bestTier.title))."
        } else {
            laneLine = "Lane is waiting for the next rescue chain."
        }

        let trendLine = recommendationMomentumRescueHallOfFameTrendLine(
            trend: trend,
            runsThisWeek: normalizedRunsThisWeek,
            previousWeekRuns: normalizedPreviousWeekRuns,
            bestWeekRuns: normalizedBestWeekRuns
        )

        if normalizedRunsThisWeek == 0 {
            return RecommendationMomentumRescueHallOfFameCard(
                trend: trend,
                title: "Rescue Hall of Fame · Best Week \(normalizedBestWeekRuns)",
                subtitle: "No rescue conversions landed this week yet. \(recordTarget) rescues sets a new weekly record.",
                systemImage: systemImage,
                helpText: "\(trendLine) \(laneLine)"
            )
        }

        if runsToRecord == 1 {
            return RecommendationMomentumRescueHallOfFameCard(
                trend: trend,
                title: "Rescue Hall of Fame · Record Pace",
                subtitle: "One more rescue sets a new weekly record at \(recordTarget).",
                systemImage: systemImage,
                helpText: "\(trendLine) \(laneLine)"
            )
        }

        return RecommendationMomentumRescueHallOfFameCard(
            trend: trend,
            title: "Rescue Hall of Fame · \(normalizedRunsThisWeek) This Week",
            subtitle: "\(runsToRecord) more \(rescueWord) to set weekly record \(recordTarget).",
            systemImage: systemImage,
            helpText: "\(trendLine) \(laneLine)"
        )
    }

    static func recommendationMomentumRescueHallOfFameDefenseCue(
        runsThisWeek: Int,
        bestWeekRuns: Int,
        previousWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameDefenseCue? {
        let normalizedRunsThisWeek = max(0, runsThisWeek)
        let normalizedBestWeekRuns = max(normalizedRunsThisWeek, max(0, bestWeekRuns))
        let normalizedPreviousWeekRuns = max(0, previousWeekRuns)
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        guard normalizedBestWeekRuns > 0 else { return nil }

        let trend = recommendationMomentumRescueHallOfFameTrend(
            runsThisWeek: normalizedRunsThisWeek,
            previousWeekRuns: normalizedPreviousWeekRuns
        )
        let trendLine = recommendationMomentumRescueHallOfFameTrendLine(
            trend: trend,
            runsThisWeek: normalizedRunsThisWeek,
            previousWeekRuns: normalizedPreviousWeekRuns,
            bestWeekRuns: normalizedBestWeekRuns
        )
        let laneLine: String
        if normalizedCurrentStreak > 0 {
            let currentTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
            laneLine = "Lane \(currentTier.title) active at x\(normalizedCurrentStreak) · best x\(normalizedBestStreak)."
        } else if normalizedBestStreak > 0 {
            let bestTier = recommendationMomentumRescueTier(for: normalizedBestStreak)
            laneLine = "Lane cooling with best x\(normalizedBestStreak) (\(bestTier.title))."
        } else {
            laneLine = "Lane is waiting for the next rescue chain."
        }

        let recordTarget = max(1, normalizedBestWeekRuns + 1)
        let runsToRecord = max(0, recordTarget - normalizedRunsThisWeek)
        if normalizedRunsThisWeek >= normalizedBestWeekRuns {
            let delta = max(0, normalizedRunsThisWeek - normalizedBestWeekRuns)
            if delta > 0 {
                return RecommendationMomentumRescueHallOfFameDefenseCue(
                    tone: .defense,
                    trend: trend,
                    title: "Hall of Fame Defense · Record +\(delta)",
                    subtitle: "Weekly record extended to \(normalizedRunsThisWeek). Keep pressure to protect the lead.",
                    buttonTitle: "Defend Record",
                    systemImage: "shield.checkered",
                    helpText: "\(trendLine) \(laneLine)"
                )
            }
            return RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: .defense,
                trend: trend,
                title: "Hall of Fame Defense · Tied Best",
                subtitle: "One more rescue sets a new weekly record at \(recordTarget).",
                buttonTitle: "Take Record",
                systemImage: "shield.lefthalf.filled",
                helpText: "\(trendLine) \(laneLine)"
            )
        }

        if runsToRecord <= 2 {
            let rescueWord = runsToRecord == 1 ? "rescue" : "rescues"
            let urgencyLine = trend == .falling
                ? "before pace cools further"
                : "to lock a new record"
            return RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: trend == .falling ? .defense : .chase,
                trend: trend,
                title: "Hall of Fame Chase · \(runsToRecord) Away",
                subtitle: "\(runsToRecord) more \(rescueWord) \(urgencyLine) at \(recordTarget).",
                buttonTitle: runsToRecord == 1 ? "Take Record" : "Push Record",
                systemImage: runsToRecord == 1 ? "bolt.fill" : "flag.checkered.2.crossed",
                helpText: "\(trendLine) \(laneLine)"
            )
        }

        if trend == .falling,
           normalizedPreviousWeekRuns >= max(3, normalizedRunsThisWeek + 2) {
            let rescueWord = runsToRecord == 1 ? "rescue" : "rescues"
            return RecommendationMomentumRescueHallOfFameDefenseCue(
                tone: .defense,
                trend: trend,
                title: "Hall of Fame Defense · Cooling",
                subtitle: "Week pace slipped. \(runsToRecord) more \(rescueWord) to set record \(recordTarget).",
                buttonTitle: "Stabilize Pace",
                systemImage: "thermometer.low",
                helpText: "\(trendLine) \(laneLine)"
            )
        }

        return nil
    }

    static func recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
        cue: RecommendationMomentumRescueHallOfFameDefenseCue?,
        rescuePlan: RecommendationPairRescuePlan?,
        enabledActionIDs: Set<String>
    ) -> [String] {
        guard let cue,
              let rescuePlan,
              enabledActionIDs.contains(rescuePlan.recommendedActionID) else {
            return []
        }

        var promotedActionIDs = [rescuePlan.recommendedActionID]
        let cadenceActionID = "run-fame-cadence-autopilot-loop"
        if cue.tone == .defense,
           enabledActionIDs.contains(cadenceActionID),
           cadenceActionID != rescuePlan.recommendedActionID {
            promotedActionIDs.append(cadenceActionID)
        }

        var uniqueActionIDs: [String] = []
        var seenActionIDs = Set<String>()
        for actionID in promotedActionIDs where seenActionIDs.insert(actionID).inserted {
            uniqueActionIDs.append(actionID)
        }
        return uniqueActionIDs
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseStatus(
        isEnabled: Bool = AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults
            .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseStatus {
        guard isEnabled else { return .disabled }

        let normalizedCooldownMinutes = max(0, cooldownMinutes)
        guard normalizedCooldownMinutes > 0,
              let lastRunAt else {
            return .ready
        }

        let cooldown = TimeInterval(normalizedCooldownMinutes * 60)
        let elapsed = now.timeIntervalSince(lastRunAt)
        guard elapsed < cooldown else { return .ready }

        let remainingSeconds = max(0, cooldown - elapsed)
        let minutesRemaining = max(1, Int(ceil(remainingSeconds / 60)))
        return .coolingDown(minutesRemaining: minutesRemaining)
    }

    static func shouldAutoRunRecommendationMomentumRescueHallOfFameAutoDefense(
        isEnabled: Bool = AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults
            .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes,
        cue: RecommendationMomentumRescueHallOfFameDefenseCue?,
        hasRunnableAction: Bool
    ) -> Bool {
        guard cue != nil,
              hasRunnableAction else {
            return false
        }
        return recommendationMomentumRescueHallOfFameAutoDefenseStatus(
            isEnabled: isEnabled,
            lastRunAt: lastRunAt,
            now: now,
            cooldownMinutes: cooldownMinutes
        ) == .ready
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseBadge(
        status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseBadge {
        switch status {
        case .disabled:
            return RecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                tone: .disabled,
                title: "Auto Defense Off",
                systemImage: "power",
                helpText: "Hall-of-Fame auto-defense is off. Enable it to auto-run the active rescue lane when Hall-of-Fame defense/chase cues appear."
            )
        case .ready:
            return RecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                tone: .ready,
                title: "Auto Defense Ready",
                systemImage: "shield.lefthalf.filled",
                helpText: "Hall-of-Fame auto-defense is armed and will auto-run the active rescue lane when Hall-of-Fame defense/chase cues appear."
            )
        case .coolingDown(let minutesRemaining):
            return RecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                tone: .coolingDown,
                title: "Auto Defense Cooldown \(minutesRemaining)m",
                systemImage: "clock.badge.checkmark",
                helpText: "Hall-of-Fame auto-defense is cooling down for about \(minutesRemaining) more minutes."
            )
        }
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
        lastRunAt: Date?,
        now: Date = Date(),
        maxAgeMinutes: Int? = nil
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge? {
        guard let lastRunAt else { return nil }

        let elapsed = max(0, now.timeIntervalSince(lastRunAt))
        if let maxAgeMinutes {
            let maxAge = TimeInterval(max(0, maxAgeMinutes) * 60)
            guard elapsed <= maxAge else { return nil }
        }

        if elapsed < 60 {
            return RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                title: "Auto defended <1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Hall-of-Fame auto-defense ran less than a minute ago."
            )
        }

        let minutesAgo = max(1, Int(floor(elapsed / 60)))
        let minuteWord = minutesAgo == 1 ? "minute" : "minutes"
        return RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
            title: "Auto defended \(minutesAgo)m ago",
            systemImage: "clock.arrow.circlepath",
            helpText: "Hall-of-Fame auto-defense ran about \(minutesAgo) \(minuteWord) ago."
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseRunsToday(
        dayStamp: String?,
        storedCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: dayStamp,
            storedCount: storedCount,
            now: now,
            calendar: calendar
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseRecordedRun(
        dayStamp: String?,
        storedCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (dayStamp: String, runsToday: Int) {
        launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: dayStamp,
            storedCount: storedCount,
            now: now,
            calendar: calendar
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseRunsThisWeek(
        weekStamp: String?,
        storedCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
            weekStamp: weekStamp,
            storedCount: storedCount,
            now: now,
            calendar: calendar
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseRecordedWeeklyRun(
        weekStamp: String?,
        storedCount: Int,
        bestWeekCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (weekStamp: String, runsThisWeek: Int, bestWeekCount: Int) {
        launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
            weekStamp: weekStamp,
            storedCount: storedCount,
            bestWeekCount: bestWeekCount,
            now: now,
            calendar: calendar
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseUpdatedStreak(
        previousDayStamp: String?,
        currentStreak: Int,
        bestStreak: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (streak: Int, bestStreak: Int) {
        launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
            previousDayStamp: previousDayStamp,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            now: now,
            calendar: calendar
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge? {
        let normalizedCurrentStreak = max(0, currentStreak)
        guard normalizedCurrentStreak > 0 else { return nil }
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let symbol = normalizedCurrentStreak >= 7 ? "flame.fill" : "shield.fill"

        return RecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
            title: "Defense Streak x\(normalizedCurrentStreak)d",
            systemImage: symbol,
            helpText: "Hall-of-Fame auto-defense streak: x\(normalizedCurrentStreak) day(s) with at least one auto run. Best x\(normalizedBestStreak)."
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
        currentWeekRuns: Int,
        bestWeekRuns: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge? {
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        guard normalizedCurrentWeekRuns > 0 else { return nil }
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, max(0, bestWeekRuns))
        let symbol = normalizedCurrentWeekRuns >= normalizedBestWeekRuns ? "sparkles" : "calendar"

        return RecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
            title: "Defense Week \(normalizedCurrentWeekRuns)",
            systemImage: symbol,
            helpText: "Hall-of-Fame auto-defense this week: \(normalizedCurrentWeekRuns) runs. Best week: \(normalizedBestWeekRuns) runs."
        )
    }

    private static func recommendationMomentumRescueHallOfFameAutoDefenseStatusSummary(
        _ status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus
    ) -> String {
        switch status {
        case .disabled:
            return "Hall-of-Fame auto-defense is currently disabled."
        case .ready:
            return "Hall-of-Fame auto-defense is armed and ready."
        case .coolingDown(let minutesRemaining):
            return "Hall-of-Fame auto-defense is cooling down (\(minutesRemaining)m remaining)."
        }
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
        currentWeekRuns: Int,
        currentStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier {
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        let normalizedCurrentStreak = max(0, currentStreak)
        if normalizedCurrentWeekRuns >= 8 || normalizedCurrentStreak >= 7 {
            return .legend
        }
        if normalizedCurrentWeekRuns >= 5 || normalizedCurrentStreak >= 4 {
            return .elite
        }
        if normalizedCurrentWeekRuns >= 2 || normalizedCurrentStreak >= 2 {
            return .rising
        }
        return .starter
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(
        _ tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> String {
        switch tier {
        case .starter:
            return "Starter"
        case .rising:
            return "Rising"
        case .elite:
            return "Elite"
        case .legend:
            return "Legend"
        }
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(
        _ tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> Int {
        switch tier {
        case .starter:
            return 0
        case .rising:
            return 1
        case .elite:
            return 2
        case .legend:
            return 3
        }
    }

    private static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueScore(
        runsToday: Int,
        currentWeekRuns: Int,
        currentStreak: Int
    ) -> Int {
        let normalizedRunsToday = max(0, runsToday)
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        let normalizedCurrentStreak = max(0, currentStreak)
        return (min(12, normalizedCurrentWeekRuns) * 2)
            + min(12, normalizedCurrentStreak)
            + min(3, normalizedRunsToday)
    }

    private static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierSystemImage(
        _ tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> String {
        switch tier {
        case .starter:
            return "shield"
        case .rising:
            return "chart.line.uptrend.xyaxis"
        case .elite:
            return "sparkles"
        case .legend:
            return "crown.fill"
        }
    }

    private static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueNextTier(
        currentTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> (
        tier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier,
        weekThreshold: Int,
        streakThreshold: Int
    )? {
        switch currentTier {
        case .starter:
            return (.rising, 2, 2)
        case .rising:
            return (.elite, 5, 4)
        case .elite:
            return (.legend, 8, 7)
        case .legend:
            return nil
        }
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
        status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge? {
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, max(0, bestWeekRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let hasHistory = normalizedCurrentWeekRuns > 0 ||
            normalizedBestWeekRuns > 0 ||
            normalizedCurrentStreak > 0 ||
            normalizedBestStreak > 0

        if case .disabled = status, !hasHistory {
            return nil
        }

        let tier = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
            currentWeekRuns: normalizedCurrentWeekRuns,
            currentStreak: normalizedCurrentStreak
        )
        let tierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(tier)
        let progressLine =
            "League uses week \(normalizedCurrentWeekRuns)/\(normalizedBestWeekRuns) and streak x\(normalizedCurrentStreak)d (best x\(normalizedBestStreak)d)."
        let nextTierLine: String
        if let nextTier = recommendationMomentumRescueHallOfFameAutoDefenseLeagueNextTier(currentTier: tier) {
            let nextTierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(
                nextTier.tier
            )
            let weekDelta = max(1, nextTier.weekThreshold - normalizedCurrentWeekRuns)
            let streakDelta = max(1, nextTier.streakThreshold - normalizedCurrentStreak)
            nextTierLine =
                "Need \(weekDelta) more weekly auto-defenses or \(streakDelta) more streak day(s) to reach \(nextTierTitle)."
        } else {
            nextTierLine = "Legend pace is active — protect the crown."
        }

        return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
            tier: tier,
            title: "Defense League \(tierTitle)",
            systemImage: recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierSystemImage(tier),
            helpText: "\(recommendationMomentumRescueHallOfFameAutoDefenseStatusSummary(status)) \(progressLine) \(nextTierLine)"
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
        status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress? {
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, max(0, bestWeekRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let hasHistory = normalizedCurrentWeekRuns > 0 ||
            normalizedBestWeekRuns > 0 ||
            normalizedCurrentStreak > 0 ||
            normalizedBestStreak > 0

        if case .disabled = status, !hasHistory {
            return nil
        }

        let tier = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
            currentWeekRuns: normalizedCurrentWeekRuns,
            currentStreak: normalizedCurrentStreak
        )
        let tierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(tier)
        let subtitle =
            "League \(tierTitle) • Week \(normalizedCurrentWeekRuns)/\(normalizedBestWeekRuns) • Streak x\(normalizedCurrentStreak)d"

        guard let nextTier = recommendationMomentumRescueHallOfFameAutoDefenseLeagueNextTier(currentTier: tier) else {
            return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                tier: tier,
                pointsToNextTier: 0,
                title: "Defense League Legend Locked",
                subtitle: subtitle,
                systemImage: "crown.fill",
                helpText: "\(recommendationMomentumRescueHallOfFameAutoDefenseStatusSummary(status)) Legend tier is active. Keep weekly auto-defense volume and streak pressure compounding."
            )
        }

        let nextTierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(
            nextTier.tier
        )
        let weekDelta = max(1, nextTier.weekThreshold - normalizedCurrentWeekRuns)
        let streakDelta = max(1, nextTier.streakThreshold - normalizedCurrentStreak)
        let pointsToNextTier = min(weekDelta, streakDelta)
        let stepWord = pointsToNextTier == 1 ? "step" : "steps"
        let weekWord = weekDelta == 1 ? "weekly auto-defense" : "weekly auto-defenses"
        let streakWord = streakDelta == 1 ? "streak day" : "streak days"

        return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
            tier: tier,
            pointsToNextTier: pointsToNextTier,
            title: "\(pointsToNextTier) \(stepWord) to \(nextTierTitle)",
            subtitle: subtitle,
            systemImage: "flag.checkered.2.crossed",
            helpText: "\(recommendationMomentumRescueHallOfFameAutoDefenseStatusSummary(status)) Need \(weekDelta) more \(weekWord) or \(streakDelta) more \(streakWord) to reach \(nextTierTitle)."
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults
            .fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
        limit: Int = 12
    ) -> [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek] {
        guard limit > 0 else { return [] }
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode(
                  [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek].self,
                  from: data
              ) else {
            return []
        }

        return Array(
            normalizedRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(history)
                .prefix(limit)
        )
    }

    private static func normalizedRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
        _ history: [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek]
    ) -> [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek] {
        var historyByWeek:
            [String: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek] = [:]
        historyByWeek.reserveCapacity(history.count)
        for item in history {
            guard
                let normalizedItem =
                    normalizedRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
                        item
                    )
            else {
                continue
            }
            historyByWeek[normalizedItem.weekStamp] = normalizedItem
        }

        return historyByWeek.values.sorted { lhs, rhs in
            (Int(lhs.weekStamp) ?? 0) > (Int(rhs.weekStamp) ?? 0)
        }
    }

    private static func normalizedRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
        _ week: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek? {
        guard let normalizedWeekStamp = normalizedLeagueHistoryWeekStamp(week.weekStamp) else {
            return nil
        }

        let normalizedRunsToday = max(0, week.runsToday)
        let normalizedRunsThisWeek = max(0, week.runsThisWeek)
        let normalizedBestWeekRuns = max(normalizedRunsThisWeek, max(0, week.bestWeekRuns))
        let normalizedCurrentStreak = max(0, week.currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, week.bestStreak))
        let normalizedTier = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
            currentWeekRuns: normalizedRunsThisWeek,
            currentStreak: normalizedCurrentStreak
        )
        let normalizedLeagueScore = recommendationMomentumRescueHallOfFameAutoDefenseLeagueScore(
            runsToday: normalizedRunsToday,
            currentWeekRuns: normalizedRunsThisWeek,
            currentStreak: normalizedCurrentStreak
        )

        return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
            weekStamp: normalizedWeekStamp,
            runsToday: normalizedRunsToday,
            runsThisWeek: normalizedRunsThisWeek,
            bestWeekRuns: normalizedBestWeekRuns,
            currentStreak: normalizedCurrentStreak,
            bestStreak: normalizedBestStreak,
            leagueScore: normalizedLeagueScore,
            tier: normalizedTier
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseRecordedLeagueHistory(
        history: [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek],
        weekStamp: String,
        runsToday: Int,
        runsThisWeek: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int,
        limit: Int = 12
    ) -> [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek] {
        guard limit > 0 else { return [] }
        let normalizedRunsToday = max(0, runsToday)
        let normalizedCurrentWeekRuns = max(0, runsThisWeek)
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, max(0, bestWeekRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let tier = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
            currentWeekRuns: normalizedCurrentWeekRuns,
            currentStreak: normalizedCurrentStreak
        )
        let week = RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek(
            weekStamp: weekStamp,
            runsToday: normalizedRunsToday,
            runsThisWeek: normalizedCurrentWeekRuns,
            bestWeekRuns: normalizedBestWeekRuns,
            currentStreak: normalizedCurrentStreak,
            bestStreak: normalizedBestStreak,
            leagueScore: recommendationMomentumRescueHallOfFameAutoDefenseLeagueScore(
                runsToday: normalizedRunsToday,
                currentWeekRuns: normalizedCurrentWeekRuns,
                currentStreak: normalizedCurrentStreak
            ),
            tier: tier
        )
        var historyByWeek: [String: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek] =
            [:]
        for item in history {
            historyByWeek[item.weekStamp] = item
        }
        historyByWeek[weekStamp] = week

        return Array(
            historyByWeek.values
                .sorted { lhs, rhs in
                    (Int(lhs.weekStamp) ?? 0) > (Int(rhs.weekStamp) ?? 0)
                }
                .prefix(limit)
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
        history: [RecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryWeek],
        sampleLimit: Int = 3
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend? {
        let normalizedSampleLimit = max(2, sampleLimit)
        let sortedHistory = history.sorted { lhs, rhs in
            (Int(lhs.weekStamp) ?? 0) < (Int(rhs.weekStamp) ?? 0)
        }
        let samples = Array(sortedHistory.suffix(normalizedSampleLimit))
        guard samples.count >= 2,
              let first = samples.first,
              let last = samples.last else {
            return nil
        }

        let scoreDelta = last.leagueScore - first.leagueScore
        let scoreDeltaLabel = scoreDelta > 0 ? "+\(scoreDelta)" : "\(scoreDelta)"
        let fromTier = first.tier
        let toTier = last.tier
        let tierDelta = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(toTier)
            - recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(fromTier)
        let fromTierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(fromTier)
        let toTierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(toTier)
        let sampleCount = samples.count
        let sampleWord = sampleCount == 1 ? "week" : "weeks"

        if tierDelta > 0 || scoreDelta >= 3 {
            let subtitle: String
            if tierDelta > 0 {
                subtitle = "\(sampleCount)w climb · \(fromTierTitle) -> \(toTierTitle)"
            } else {
                subtitle = "\(sampleCount)w climb · \(toTierTitle)"
            }
            return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                direction: .rising,
                sampleCount: sampleCount,
                scoreDelta: scoreDelta,
                fromTier: fromTier,
                toTier: toTier,
                title: "Defense League Heat \(scoreDeltaLabel)",
                subtitle: subtitle,
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Hall-of-Fame defense league momentum is rising over the last \(sampleCount) \(sampleWord): score \(first.leagueScore) -> \(last.leagueScore) (Δ\(scoreDeltaLabel)), tier \(fromTierTitle) -> \(toTierTitle)."
            )
        }

        if tierDelta < 0 || scoreDelta <= -3 {
            let subtitle: String
            if tierDelta < 0 {
                subtitle = "\(sampleCount)w slide · \(fromTierTitle) -> \(toTierTitle)"
            } else {
                subtitle = "\(sampleCount)w slide · \(toTierTitle)"
            }
            return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                direction: .falling,
                sampleCount: sampleCount,
                scoreDelta: scoreDelta,
                fromTier: fromTier,
                toTier: toTier,
                title: "Defense League Drift \(scoreDeltaLabel)",
                subtitle: subtitle,
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Hall-of-Fame defense league momentum is cooling over the last \(sampleCount) \(sampleWord): score \(first.leagueScore) -> \(last.leagueScore) (Δ\(scoreDeltaLabel)), tier \(fromTierTitle) -> \(toTierTitle)."
            )
        }

        return RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
            direction: .steady,
            sampleCount: sampleCount,
            scoreDelta: scoreDelta,
            fromTier: fromTier,
            toTier: toTier,
            title: "Defense League Holding",
            subtitle: "\(sampleCount)w steady · \(toTierTitle) at \(last.leagueScore)",
            systemImage: "equal.circle.fill",
            helpText: "Hall-of-Fame defense league momentum is steady over the last \(sampleCount) \(sampleWord): score \(first.leagueScore) -> \(last.leagueScore) (Δ\(scoreDeltaLabel)) while holding \(toTierTitle)."
        )
    }

    static func recommendationMomentumRescueHallOfFameLegendRiskForecast(
        status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus,
        trend: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend?,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int,
        enabledActionIDs: Set<String>,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> RecommendationMomentumRescueHallOfFameLegendRiskForecast? {
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, max(0, bestWeekRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        guard recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
            currentWeekRuns: normalizedCurrentWeekRuns,
            currentStreak: normalizedCurrentStreak
        ) == .legend,
            let trend,
            trend.direction != .rising else {
            return nil
        }

        let actionID = recommendationMomentumRescueHallOfFameLegendRiskActionID(
            enabledActionIDs: enabledActionIDs
        )
        let actionPrompt = actionID == nil
            ? "Run a rescue defense step"
            : "Run the suggested rescue step"
        let nextDefenseWindow = recommendationMomentumRescueHallOfFameLegendRiskNextDefenseWindow(
            status: status,
            now: now,
            calendar: calendar
        )
        let tierDelta = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(trend.toTier)
            - recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(trend.fromTier)
        let isHighRisk = trend.direction == .falling && (trend.scoreDelta <= -8 || tierDelta < 0)
        let riskLabel = isHighRisk ? "High" : "Watch"
        let tone: RecommendationMomentumRescueHallOfFameLegendRiskForecastTone = isHighRisk
            ? .alert
            : .watch
        let signedDelta = trend.scoreDelta > 0 ? "+\(trend.scoreDelta)" : "\(trend.scoreDelta)"

        let title: String
        let subtitle: String
        let systemImage: String
        switch trend.direction {
        case .falling:
            title = "Hall-of-Fame Legend Risk"
            subtitle = "Risk \(riskLabel) · \(trend.title) (Δ\(signedDelta)) · Next defense \(nextDefenseWindow.label)"
            systemImage = isHighRisk
                ? "exclamationmark.shield.fill"
                : "shield.lefthalf.filled"
        case .steady:
            title = "Hall-of-Fame Legend Stability"
            subtitle = "Risk Watch · \(trend.subtitle) · Next defense \(nextDefenseWindow.label)"
            systemImage = "clock.arrow.circlepath"
        case .rising:
            return nil
        }

        let timingInstruction: String
        if nextDefenseWindow.minutesUntil <= 0 {
            timingInstruction = "\(actionPrompt) now to protect Hall-of-Fame legend pace."
        } else {
            timingInstruction = "\(actionPrompt) around \(nextDefenseWindow.clockLabel) to protect Hall-of-Fame legend pace."
        }
        let helpText = "\(recommendationMomentumRescueHallOfFameAutoDefenseStatusSummary(status)) \(trend.helpText) Defense timing \(nextDefenseWindow.label). \(timingInstruction) Current week \(normalizedCurrentWeekRuns)/\(normalizedBestWeekRuns), streak x\(normalizedCurrentStreak)d (best x\(normalizedBestStreak)d)."

        return RecommendationMomentumRescueHallOfFameLegendRiskForecast(
            tone: tone,
            riskLabel: riskLabel,
            nextDefenseMinutes: nextDefenseWindow.minutesUntil,
            nextDefenseLabel: nextDefenseWindow.label,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText,
            actionID: actionID
        )
    }

    private static func recommendationMomentumRescueHallOfFameLegendRiskActionID(
        enabledActionIDs: Set<String>
    ) -> String? {
        let preferredActionIDs = [
            "run-fame-next-move-copy-drafts",
            "run-fame-next-move-cadence-execution-kit",
            "run-fame-cadence-autopilot-loop",
            "run-fame-next-move"
        ]
        for actionID in preferredActionIDs where enabledActionIDs.contains(actionID) {
            return actionID
        }
        return nil
    }

    private static func recommendationMomentumRescueHallOfFameLegendRiskNextDefenseWindow(
        status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus,
        now: Date,
        calendar: Calendar
    ) -> (minutesUntil: Int, label: String, clockLabel: String) {
        switch status {
        case .disabled, .ready:
            return (0, "now", launchRecoveryHotKeyAutoTrustSurgeClockLabel(now, calendar: calendar))
        case .coolingDown(let minutesRemaining):
            let minutesUntil = max(1, minutesRemaining)
            let targetDate = now.addingTimeInterval(TimeInterval(minutesUntil * 60))
            let targetLabel = launchRecoveryHotKeyAutoTrustSurgeClockLabel(targetDate, calendar: calendar)
            return (minutesUntil, "in \(minutesUntil)m (~\(targetLabel))", targetLabel)
        }
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseScorecard(
        status: RecommendationMomentumRescueHallOfFameAutoDefenseStatus,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseScorecard {
        let normalizedRunsToday = max(0, runsToday)
        let normalizedCurrentWeekRuns = max(0, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, max(0, bestWeekRuns))
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let recordTarget = max(1, normalizedBestWeekRuns + 1)
        let runsToRecord = max(0, recordTarget - normalizedCurrentWeekRuns)
        let progressLine =
            "Today \(normalizedRunsToday) · week \(normalizedCurrentWeekRuns)/best \(normalizedBestWeekRuns) · streak x\(normalizedCurrentStreak)d (best x\(normalizedBestStreak)d)."

        switch status {
        case .disabled:
            return RecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                tone: .disabled,
                title: "Hall-of-Fame Auto Defense Disabled",
                subtitle: "Enable auto-defense to protect weekly rescue pace. \(progressLine)",
                systemImage: "power",
                helpText: "Hall-of-Fame auto-defense is currently disabled. \(progressLine)"
            )
        case .ready:
            let subtitle: String
            if normalizedCurrentWeekRuns == 0 {
                subtitle = "Armed for the first Hall-of-Fame save this week. \(progressLine)"
            } else if runsToRecord == 0 {
                subtitle = "Armed to extend the weekly auto-defense record. \(progressLine)"
            } else if runsToRecord == 1 {
                subtitle = "One more auto-defense ties best week \(normalizedBestWeekRuns). \(progressLine)"
            } else {
                subtitle = "\(runsToRecord) more auto-defenses to set best week \(recordTarget). \(progressLine)"
            }
            return RecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                tone: .ready,
                title: "Hall-of-Fame Auto Defense Armed",
                subtitle: subtitle,
                systemImage: "shield.checkered",
                helpText: "Hall-of-Fame auto-defense is ready for the next defense/chase cue. \(progressLine)"
            )
        case .coolingDown(let minutesRemaining):
            return RecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                tone: .coolingDown,
                title: "Hall-of-Fame Auto Defense Cooldown",
                subtitle: "Cooling down for about \(minutesRemaining)m. \(progressLine)",
                systemImage: "clock.badge.checkmark",
                helpText: "Hall-of-Fame auto-defense is cooling down for about \(minutesRemaining) minutes. \(progressLine)"
            )
        }
    }

    private static func recommendationMomentumRescueHallOfFameTrend(
        runsThisWeek: Int,
        previousWeekRuns: Int
    ) -> RecommendationMomentumRescueHallOfFameTrend {
        let normalizedRunsThisWeek = max(0, runsThisWeek)
        let normalizedPreviousWeekRuns = max(0, previousWeekRuns)
        if normalizedRunsThisWeek > normalizedPreviousWeekRuns {
            return .rising
        }
        if normalizedRunsThisWeek < normalizedPreviousWeekRuns {
            return .falling
        }
        return .steady
    }

    private static func recommendationMomentumRescueHallOfFameSystemImage(
        trend: RecommendationMomentumRescueHallOfFameTrend
    ) -> String {
        switch trend {
        case .rising:
            return "arrow.up.right.circle.fill"
        case .steady:
            return "minus.circle.fill"
        case .falling:
            return "arrow.down.right.circle.fill"
        }
    }

    private static func recommendationMomentumRescueHallOfFameTrendLine(
        trend: RecommendationMomentumRescueHallOfFameTrend,
        runsThisWeek: Int,
        previousWeekRuns: Int,
        bestWeekRuns: Int
    ) -> String {
        switch trend {
        case .rising:
            return "Week trend rising (\(runsThisWeek) vs \(previousWeekRuns) last week). Best week \(bestWeekRuns)."
        case .steady:
            return "Week trend steady (\(runsThisWeek) vs \(previousWeekRuns) last week). Best week \(bestWeekRuns)."
        case .falling:
            return "Week trend cooling (\(runsThisWeek) vs \(previousWeekRuns) last week). Best week \(bestWeekRuns)."
        }
    }

    static func recommendationMomentumRescueImpactPulse(
        actionTitle: String,
        currentStreak: Int,
        bestStreak: Int,
        rescuePlan: RecommendationPairRescuePlan
    ) -> RecommendationMomentumRescueImpactPulse {
        let normalizedActionTitle = actionTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedActionTitle = normalizedActionTitle.isEmpty
            ? "recommended rescue action"
            : normalizedActionTitle
        let normalizedCurrentStreak = max(1, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let rescueTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
        let openWord = rescuePlan.opensSinceLastConversion == 1 ? "open" : "opens"
        let title = "Rescue Attempt · \(rescueTier.title)"
        let subtitle = "Running \(resolvedActionTitle) · last win \(rescuePlan.opensSinceLastConversion) \(openWord) ago"
        let helpText = "Rescue Now launched \(resolvedActionTitle) to recover a cold high-confidence recommendation pair (\(rescuePlan.conversions)/\(rescuePlan.opportunities), \(rescuePlan.conversionRatePercent)% conversion, last win \(rescuePlan.opensSinceLastConversion) \(openWord) ago). Rescue lane x\(normalizedCurrentStreak) · best x\(normalizedBestStreak)."
        return RecommendationMomentumRescueImpactPulse(
            title: title,
            subtitle: subtitle,
            systemImage: rescueTier.systemImage,
            helpText: helpText
        )
    }

    static func recommendationMomentumRescueFollowthroughCue(
        actionTitle: String,
        currentStreak: Int,
        bestStreak: Int,
        rescuePlan: RecommendationPairRescuePlan
    ) -> RecommendationMomentumRescueFollowthroughCue {
        let normalizedActionTitle = actionTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedActionTitle = normalizedActionTitle.isEmpty
            ? "recommended rescue action"
            : normalizedActionTitle
        let normalizedCurrentStreak = max(1, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))
        let projectedStreak = normalizedCurrentStreak + 1
        let projectedBestStreak = max(normalizedBestStreak, projectedStreak)
        let projectedTier = recommendationMomentumRescueTier(for: projectedStreak)
        let normalizedOpportunities = max(1, rescuePlan.opportunities)
        let normalizedConversions = min(
            normalizedOpportunities,
            max(0, rescuePlan.conversions)
        )
        let normalizedConversionRatePercent = Int(
            (Double(normalizedConversions) / Double(normalizedOpportunities) * 100).rounded()
        )
        let normalizedOpensSinceLastConversion = max(0, rescuePlan.opensSinceLastConversion)
        let openWord = normalizedOpensSinceLastConversion == 1 ? "open" : "opens"
        let title: String
        let subtitle: String
        let systemImage: String
        if projectedStreak > normalizedBestStreak {
            title = "Rescue Upside · New Best"
            subtitle = "If \(resolvedActionTitle) converts, lane reaches x\(projectedStreak) (\(projectedTier.title)) and sets a new best x\(projectedBestStreak)."
            systemImage = "trophy.fill"
        } else if projectedTier.nextTierTitle == nil {
            title = "Rescue Upside · Legend Pace"
            subtitle = "If \(resolvedActionTitle) converts, lane reaches x\(projectedStreak) with legend pace locked."
            systemImage = "crown.fill"
        } else {
            title = "Rescue Upside · \(projectedTier.title)"
            subtitle = "If \(resolvedActionTitle) converts, lane climbs to x\(projectedStreak) (\(projectedTier.title))."
            systemImage = "arrow.up.forward.circle.fill"
        }
        let helpText = "Rescue attempt is live for \(resolvedActionTitle) (\(normalizedConversions)/\(normalizedOpportunities), \(normalizedConversionRatePercent)% conversion, last win \(normalizedOpensSinceLastConversion) \(openWord) ago). A conversion this open would move rescue lane to x\(projectedStreak) and best x\(projectedBestStreak)."
        return RecommendationMomentumRescueFollowthroughCue(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    static func recommendationMomentumRescueCelebrationCue(
        pulse: CommandPaletteSession.RecommendationMomentumRescuePulse
    ) -> RecommendationMomentumRescueCelebrationCue {
        let normalizedStreak = max(1, pulse.streak)
        let normalizedBestStreak = max(normalizedStreak, max(0, pulse.bestStreak))
        let currentTier = recommendationMomentumRescueTier(for: normalizedStreak)
        let title: String
        let subtitle: String
        let systemImage: String
        if pulse.didSetNewBest {
            title = "Rescue Landed · New Best x\(normalizedBestStreak)"
            subtitle = "Lane reached \(currentTier.title) with a new rescue best. Keep stacking this momentum."
            systemImage = "trophy.fill"
        } else if pulse.didTierUpgrade {
            title = "Rescue Landed · \(currentTier.title) Tier Up"
            subtitle = "Lane promoted to \(currentTier.title) at x\(normalizedStreak)."
            systemImage = "arrow.up.forward.circle.fill"
        } else {
            title = "Rescue Landed · \(currentTier.title)"
            subtitle = "Lane stabilized at x\(normalizedStreak) (\(currentTier.title))."
            systemImage = currentTier.systemImage
        }

        let helpText: String
        if let nextTierTitle = currentTier.nextTierTitle,
           let nextTierThreshold = currentTier.nextTierThreshold {
            helpText = "\(pulse.helpText) Next target: \(nextTierTitle) at x\(nextTierThreshold)."
        } else {
            helpText = "\(pulse.helpText) Legend pace is locked."
        }

        return RecommendationMomentumRescueCelebrationCue(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    static func recommendationPairRescueConfidenceChip(
        plan: RecommendationPairRescuePlan
    ) -> RecommendationPairRescueConfidenceChip {
        let normalizedOpportunities = max(1, plan.opportunities)
        let normalizedConversions = min(
            normalizedOpportunities,
            max(0, plan.conversions)
        )
        let normalizedConversionRatePercent = Int(
            (Double(normalizedConversions) / Double(normalizedOpportunities) * 100).rounded()
        )
        let normalizedOpensSinceLastConversion = max(0, plan.opensSinceLastConversion)
        let confidenceTitle = CommandPaletteAction.recommendationConversionConfidenceTitle(
            opportunities: normalizedOpportunities,
            conversionCount: normalizedConversions
        )
        let tone: RecommendationPairRescueConfidenceChipTone
        let systemImage: String
        if normalizedConversionRatePercent >= 85, normalizedOpportunities >= 10 {
            tone = .proven
            systemImage = "sparkles"
        } else if normalizedConversionRatePercent >= 70 {
            tone = .strong
            systemImage = "chart.line.uptrend.xyaxis"
        } else {
            tone = .watch
            systemImage = "clock.badge.exclamationmark"
        }
        let openWord = normalizedOpensSinceLastConversion == 1 ? "open" : "opens"
        return RecommendationPairRescueConfidenceChip(
            tone: tone,
            title: "Win Chance \(normalizedConversionRatePercent)%",
            systemImage: systemImage,
            helpText: "Rescue proof \(confidenceTitle) · \(normalizedConversions)/\(normalizedOpportunities) converted (\(normalizedConversionRatePercent)%). Last win \(normalizedOpensSinceLastConversion) \(openWord) ago."
        )
    }

    private static func recommendationMomentumRescueTier(
        for streak: Int
    ) -> (
        title: String,
        systemImage: String,
        nextTierTitle: String?,
        nextTierThreshold: Int?
    ) {
        let normalizedStreak = max(1, streak)
        switch normalizedStreak {
        case ...2:
            return (
                title: "Spark",
                systemImage: "bolt.badge.clock",
                nextTierTitle: "Breakout",
                nextTierThreshold: 3
            )
        case ...4:
            return (
                title: "Breakout",
                systemImage: "sparkles",
                nextTierTitle: "Fame",
                nextTierThreshold: 5
            )
        case ...7:
            return (
                title: "Fame",
                systemImage: "flame.fill",
                nextTierTitle: "Legend",
                nextTierThreshold: 8
            )
        default:
            return (
                title: "Legend",
                systemImage: "crown.fill",
                nextTierTitle: nil,
                nextTierThreshold: nil
            )
        }
    }

    static func summaryText(for context: CommandPaletteTopPickContext) -> String {
        if context.hasError {
            return "Looks like there is an error right now"
        }
        if context.hasAnswer {
            return "Your answer is ready"
        }
        if context.hasImage {
            return "You have an image ready"
        }
        if context.hasText {
            return context.llmEnabled
                ? "You have text ready for reading or ask flows"
                : "You have text ready"
        }

        if context.hasFreshOnboardingRecovery {
            if let remainingArtifacts = context.onboardingRecoveryRemainingArtifacts,
               remainingArtifacts > 0 {
                let noun = remainingArtifacts == 1 ? "artifact" : "artifacts"
                let progressTitle = "Onboarding recovery live (\(remainingArtifacts) \(noun) left)"
                if let followupTitle = onboardingRecoveryFollowupTitle(
                    actionID: context.onboardingRecoveryFollowupActionID
                ) {
                    return "\(progressTitle) · Next \(followupTitle)"
                }
                return progressTitle
            }
            if let followupTitle = onboardingRecoveryFollowupTitle(
                actionID: context.onboardingRecoveryFollowupActionID
            ) {
                return "Onboarding gap just closed — lock in momentum with \(followupTitle)"
            }
            return "Onboarding gap just closed — lock in momentum"
        }

        return "Start with capture, read, ask, or share"
    }

    static func statusShortcutBadgeTitle(
        hasAutoOpsShortcut: Bool,
        hasLaunchRescueShortcut: Bool
    ) -> String? {
        switch (hasAutoOpsShortcut, hasLaunchRescueShortcut) {
        case (true, true):
            return "Status ⌥⌘O · ⌥⌘L"
        case (true, false):
            return "Status ⌥⌘O"
        case (false, true):
            return "Status ⌥⌘L"
        case (false, false):
            return nil
        }
    }

    static func statusShortcutBadgeHelpText(
        hasAutoOpsShortcut: Bool,
        hasLaunchRescueShortcut: Bool
    ) -> String? {
        switch (hasAutoOpsShortcut, hasLaunchRescueShortcut) {
        case (true, true):
            return "Reader status shortcuts: ⌥⌘O runs Auto Bundle status. ⌥⌘L runs Launch Rescue Auto status."
        case (true, false):
            return "Reader status shortcut: ⌥⌘O runs Auto Bundle status."
        case (false, true):
            return "Reader status shortcut: ⌥⌘L runs Launch Rescue Auto status."
        case (false, false):
            return nil
        }
    }

    static func onboardingRecoveryBadgeTitle(for context: CommandPaletteTopPickContext) -> String? {
        guard context.hasFreshOnboardingRecovery else { return nil }
        if let remainingArtifacts = context.onboardingRecoveryRemainingArtifacts,
           remainingArtifacts > 0 {
            let noun = remainingArtifacts == 1 ? "artifact" : "artifacts"
            return "Recovery · \(remainingArtifacts) \(noun) left"
        }
        return "Recovery · Gap closed"
    }

    static func onboardingRecoveryBadgeSystemImage(for context: CommandPaletteTopPickContext) -> String? {
        guard context.hasFreshOnboardingRecovery else { return nil }
        if let remainingArtifacts = context.onboardingRecoveryRemainingArtifacts,
           remainingArtifacts > 0 {
            return "checkmark.seal"
        }
        return "checkmark.seal.fill"
    }

    static func onboardingRecoveryHelpText(
        for context: CommandPaletteTopPickContext,
        followupTitle: String?
    ) -> String {
        let resolvedFollowupTitle: String?
        if let followupTitle {
            let trimmedTitle = followupTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedTitle.isEmpty {
                resolvedFollowupTitle = onboardingRecoveryFollowupTitle(
                    actionID: context.onboardingRecoveryFollowupActionID
                )
            } else {
                resolvedFollowupTitle = trimmedTitle
            }
        } else {
            resolvedFollowupTitle = onboardingRecoveryFollowupTitle(
                actionID: context.onboardingRecoveryFollowupActionID
            )
        }
        if let remainingArtifacts = context.onboardingRecoveryRemainingArtifacts,
           remainingArtifacts > 0 {
            if let resolvedFollowupTitle {
                return "Onboarding recovery is active. \(remainingArtifacts) artifacts left. Next focus: \(resolvedFollowupTitle)."
            }
            return "Onboarding recovery is active. \(remainingArtifacts) artifacts left. Pick the top recovery command to close the gap."
        }
        if let resolvedFollowupTitle {
            return "Onboarding gap closed. Keep momentum with \(resolvedFollowupTitle)."
        }
        return "Onboarding gap closed. Keep momentum with your next move."
    }

    static func onboardingRecoveryQuickRunActionID(
        for context: CommandPaletteTopPickContext,
        enabledActionIDs: Set<String>
    ) -> String? {
        guard context.hasFreshOnboardingRecovery else { return nil }
        if let followupActionID = context.onboardingRecoveryFollowupActionID,
           enabledActionIDs.contains(followupActionID) {
            return followupActionID
        }
        return onboardingRecoveryFallbackActionID(enabledActionIDs: enabledActionIDs)
    }

    static func onboardingRecoveryFallbackActionID(enabledActionIDs: Set<String>) -> String? {
        for actionID in onboardingRecoveryPromotedFallbackActionIDs where enabledActionIDs.contains(actionID) {
            return actionID
        }
        return nil
    }

    static func launchRecoveryHotKeyReadiness(
        for context: CommandPaletteTopPickContext,
        enabledActionIDs: Set<String>
    ) -> LaunchRecoveryHotKeyReadiness {
        if let actionID = onboardingRecoveryQuickRunActionID(
            for: context,
            enabledActionIDs: enabledActionIDs
        ) {
            return .direct(actionID: actionID)
        }
        if let actionID = onboardingRecoveryFallbackActionID(enabledActionIDs: enabledActionIDs) {
            return .reroute(actionID: actionID)
        }
        return .unavailable
    }

    static func launchRecoveryHotKeyReadinessState(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> LaunchRecoveryHotKeyReadinessState {
        switch readiness {
        case .direct:
            return .direct
        case .reroute:
            return .reroute
        case .unavailable:
            return .standby
        }
    }

    static func launchRecoveryHotKeyTrend(
        for readinessHistory: [LaunchRecoveryHotKeyReadinessState],
        limit: Int = 6
    ) -> LaunchRecoveryHotKeyTrend? {
        let normalizedLimit = max(1, limit)
        let samples = Array(readinessHistory.suffix(normalizedLimit))
        guard !samples.isEmpty else { return nil }

        var directCount = 0
        var rerouteCount = 0
        var standbyCount = 0
        for sample in samples {
            switch sample {
            case .direct:
                directCount += 1
            case .reroute:
                rerouteCount += 1
            case .standby:
                standbyCount += 1
            }
        }
        return LaunchRecoveryHotKeyTrend(
            directCount: directCount,
            rerouteCount: rerouteCount,
            standbyCount: standbyCount
        )
    }

    static func launchRecoveryHotKeyTrendDominantState(
        for trend: LaunchRecoveryHotKeyTrend
    ) -> LaunchRecoveryHotKeyReadinessState {
        if trend.directCount >= trend.rerouteCount,
           trend.directCount >= trend.standbyCount {
            return .direct
        }
        if trend.rerouteCount >= trend.standbyCount {
            return .reroute
        }
        return .standby
    }

    static func launchRecoveryHotKeyTrendBadgeTitle(for trend: LaunchRecoveryHotKeyTrend) -> String {
        "Trend D\(trend.directCount)·R\(trend.rerouteCount)·S\(trend.standbyCount)"
    }

    static func launchRecoveryHotKeyTrendBadgeSystemImage(for trend: LaunchRecoveryHotKeyTrend) -> String {
        switch launchRecoveryHotKeyTrendDominantState(for: trend) {
        case .direct:
            return "chart.line.uptrend.xyaxis"
        case .reroute:
            return "arrow.triangle.branch"
        case .standby:
            return "clock.badge.exclamationmark"
        }
    }

    static func launchRecoveryHotKeyTrendBadgeHelpText(for trend: LaunchRecoveryHotKeyTrend) -> String {
        let noun = trend.sampleCount == 1 ? "open" : "opens"
        let baseline = "Launch recovery confidence over last \(trend.sampleCount) palette \(noun): Direct \(trend.directCount), Reroute \(trend.rerouteCount), Standby \(trend.standbyCount)."
        switch launchRecoveryHotKeyTrendDominantState(for: trend) {
        case .direct:
            return "\(baseline) Direct route is leading."
        case .reroute:
            return "\(baseline) Reroute is carrying recovery while fresh pulses rebuild."
        case .standby:
            return "\(baseline) Recovery mostly stays on standby; queue onboarding recovery steps to restore one-click flow."
        }
    }

    static func launchRecoveryHotKeyWinMeter(
        readinessHistory: [LaunchRecoveryHotKeyReadinessState],
        directStreak: Int,
        bestDirectStreak: Int,
        sampleLimit: Int = 8
    ) -> LaunchRecoveryHotKeyWinMeter? {
        let normalizedLimit = max(2, sampleLimit)
        let samples = Array(readinessHistory.suffix(normalizedLimit))
        guard !samples.isEmpty else { return nil }

        let wins = samples.filter { $0 == .direct }.count
        let sampleCount = samples.count
        let normalizedDirectStreak = max(0, directStreak)
        let normalizedBestDirectStreak = max(normalizedDirectStreak, bestDirectStreak)
        let multiplier: Int
        if normalizedDirectStreak >= 9 {
            multiplier = 4
        } else if normalizedDirectStreak >= 5 {
            multiplier = 3
        } else if normalizedDirectStreak >= 2 {
            multiplier = 2
        } else {
            multiplier = 1
        }

        let winRatePercent = (wins * 100) / max(1, sampleCount)
        let tone: LaunchRecoveryHotKeyWinMeterTone
        let systemImage: String
        let subtitle: String
        if winRatePercent >= 75 {
            tone = .surge
            systemImage = "trophy.fill"
            subtitle = "Direct route is winning \(wins)/\(sampleCount) opens. Keep streak pressure high."
        } else if winRatePercent >= 45 {
            tone = .steady
            systemImage = "chart.line.uptrend.xyaxis"
            subtitle = "Recovery is stabilizing at \(wins)/\(sampleCount) direct wins. Stack the next win."
        } else {
            tone = .rebuild
            systemImage = "arrow.triangle.2.circlepath"
            subtitle = "Recovery is rebuilding (\(wins)/\(sampleCount) direct wins). Run the next recovery step now."
        }

        return LaunchRecoveryHotKeyWinMeter(
            tone: tone,
            wins: wins,
            sampleCount: sampleCount,
            multiplier: multiplier,
            title: "Recovery Wins \(wins)/\(sampleCount) · x\(multiplier)",
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: "Launch recovery win meter tracks direct-route wins over the last \(sampleCount) opens: \(wins) direct wins, current streak x\(normalizedDirectStreak), best x\(normalizedBestDirectStreak), multiplier x\(multiplier)."
        )
    }

    static func launchRecoveryHotKeyWinDelta(
        readinessHistory: [LaunchRecoveryHotKeyReadinessState],
        sampleWindow: Int = 8
    ) -> LaunchRecoveryHotKeyWinDelta? {
        let normalizedWindow = max(2, sampleWindow)
        guard readinessHistory.count >= normalizedWindow * 2 else { return nil }

        let currentSamples = Array(readinessHistory.suffix(normalizedWindow))
        let previousSamples = Array(readinessHistory.dropLast(normalizedWindow).suffix(normalizedWindow))
        let currentWins = currentSamples.filter { $0 == .direct }.count
        let previousWins = previousSamples.filter { $0 == .direct }.count
        let deltaWins = currentWins - previousWins
        let signedDelta = deltaWins > 0 ? "+\(deltaWins)" : "\(deltaWins)"
        let title = "Fame Momentum Delta \(signedDelta) wins"

        let tone: LaunchRecoveryHotKeyWinDeltaTone
        let subtitle: String
        let systemImage: String
        if deltaWins > 0 {
            tone = .climbing
            subtitle = "Direct wins climbed to \(currentWins)/\(normalizedWindow) from \(previousWins)/\(normalizedWindow). Keep compounding."
            systemImage = "arrow.up.right.circle.fill"
        } else if deltaWins < 0 {
            tone = .slipping
            subtitle = "Direct wins slipped to \(currentWins)/\(normalizedWindow) from \(previousWins)/\(normalizedWindow). Re-anchor recovery now."
            systemImage = "arrow.down.right.circle.fill"
        } else {
            tone = .steady
            subtitle = "Direct wins are flat at \(currentWins)/\(normalizedWindow) vs \(previousWins)/\(normalizedWindow). Push one extra direct win."
            systemImage = "equal.circle.fill"
        }

        return LaunchRecoveryHotKeyWinDelta(
            tone: tone,
            currentWins: currentWins,
            previousWins: previousWins,
            sampleCount: normalizedWindow,
            deltaWins: deltaWins,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: "Fame momentum delta compares direct wins across two \(normalizedWindow)-open windows: current \(currentWins), previous \(previousWins), Δ\(signedDelta)."
        )
    }

    static func fameMomentumPanel(
        confidenceScore: LaunchRecoveryHotKeyConfidenceScore,
        winDelta: LaunchRecoveryHotKeyWinDelta?,
        interventionTrustTrend: LaunchRecoveryHotKeyInterventionTrustTrend? = nil,
        routeFlipRhythmTone: FameMomentumPanelRouteFlipRhythmTone? = nil,
        rescuePlan: RecommendationPairRescuePlan?,
        hallOfFameCue: RecommendationMomentumRescueHallOfFameDefenseCue?,
        trustGuardActionID: String?,
        trustMomentumPlanActionID: String?,
        actionScores: [String: Int] = [:],
        actionRecency: [String: FameMomentumPanelActionRecency] = [:],
        enabledActionIDs: Set<String>
    ) -> FameMomentumPanel? {
        let needsAttention = launchRecoveryHotKeyConfidenceScoreNeedsAttention(confidenceScore)
        let hasMomentumSignals = winDelta != nil || rescuePlan != nil || hallOfFameCue != nil
        guard needsAttention || hasMomentumSignals else { return nil }

        let tone = fameMomentumPanelTone(
            confidenceScore: confidenceScore,
            winDelta: winDelta,
            rescuePlan: rescuePlan,
            hallOfFameCue: hallOfFameCue
        )
        let tierTitle = launchRecoveryHotKeyConfidenceTierTitle(for: confidenceScore.tier)
        let title = "Fame Momentum Panel · Trust \(confidenceScore.points)/100 \(tierTitle)"

        let winDeltaLine: String
        if let winDelta {
            let signedDelta = winDelta.deltaWins > 0 ? "+\(winDelta.deltaWins)" : "\(winDelta.deltaWins)"
            winDeltaLine = "Δwins \(signedDelta)"
        } else {
            winDeltaLine = "Δwins pending"
        }

        let rescueLine: String
        if let rescuePlan {
            rescueLine =
                "Rescue \(rescuePlan.conversionRatePercent)% · cold \(rescuePlan.opensSinceLastConversion)"
        } else if let hallOfFameCue {
            rescueLine = hallOfFameCue.title
        } else {
            rescueLine = "Rescue lane warming up"
        }

        let subtitle =
            "Trust \(confidenceScore.points)/100 · \(winDeltaLine) · \(rescueLine)"

        let rescueActionID = rescuePlan?.recommendedActionID
        let rescueConfidenceBonus = fameMomentumPanelRescueConfidenceBonus(rescuePlan)
        var actionCandidates: [(id: String?, prompt: String, basePriority: Int)] = []
        if needsAttention {
            actionCandidates.append((
                trustGuardActionID,
                trustGuardActionID == CommandPaletteAction.launchRecoveryNextActionID
                    ? "Run Recovery Next"
                    : "Run Trust Fix",
                300
            ))
            actionCandidates.append((
                trustMomentumPlanActionID,
                trustMomentumPlanActionID == CommandPaletteAction.launchRecoveryNextActionID
                    ? "Run Recovery Next"
                    : "Run Trust Step",
                200
            ))
            actionCandidates.append((rescueActionID, "Run Rescue Now", 100))
        } else {
            actionCandidates.append((rescueActionID, "Run Rescue Now", 300))
            actionCandidates.append((
                trustMomentumPlanActionID,
                trustMomentumPlanActionID == CommandPaletteAction.launchRecoveryNextActionID
                    ? "Run Recovery Next"
                    : "Run Trust Step",
                200
            ))
            actionCandidates.append((
                trustGuardActionID,
                trustGuardActionID == CommandPaletteAction.launchRecoveryNextActionID
                    ? "Run Recovery Next"
                    : "Run Trust Fix",
                100
            ))
        }

        let rankedCandidates = actionCandidates
            .enumerated()
            .compactMap { offset, candidate -> FameMomentumPanelCandidate? in
                guard let actionID = candidate.id,
                      enabledActionIDs.contains(actionID) else {
                    return nil
                }
                let observedImpact = actionScores[actionID, default: 0]
                let recency = actionRecency[actionID]
                let recencyAdaptiveBonus = fameMomentumPanelActionRecencyAdaptiveBonus(recency)
                let rhythmAdaptiveBonus = fameMomentumPanelRouteFlipRhythmAdaptiveBonus(
                    tone: routeFlipRhythmTone,
                    recency: recency,
                    observedImpact: observedImpact
                )
                let rescueConfidenceAdaptiveBonus = actionID == rescueActionID
                    ? rescueConfidenceBonus
                    : 0
                let adaptiveBonus = observedImpact * 18
                    + rescueConfidenceAdaptiveBonus
                    + recencyAdaptiveBonus
                    + rhythmAdaptiveBonus
                return (
                    id: actionID,
                    prompt: candidate.prompt,
                    score: candidate.basePriority + adaptiveBonus,
                    offset: offset,
                    observedImpact: observedImpact,
                    rescueConfidenceBonus: rescueConfidenceAdaptiveBonus,
                    recency: recency,
                    recencyBonus: recencyAdaptiveBonus,
                    rhythmBonus: rhythmAdaptiveBonus
                )
            }
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.offset < rhs.offset
            }

        let selectedCandidate = rankedCandidates.first
        let secondaryCandidate = fameMomentumPanelSecondaryCandidate(
            selectedCandidate: selectedCandidate,
            rankedCandidates: rankedCandidates,
            needsAttention: needsAttention
        )
        let secondaryScoreGap: Int?
        if let selectedCandidate, let secondaryCandidate {
            secondaryScoreGap = max(0, selectedCandidate.score - secondaryCandidate.score)
        } else {
            secondaryScoreGap = nil
        }
        let selectionConfidence = fameMomentumPanelSelectionConfidence(
            selectedCandidate: selectedCandidate,
            rankedCandidates: rankedCandidates,
            secondaryCandidate: secondaryCandidate,
            needsAttention: needsAttention
        )
        let resolvedActionID = selectedCandidate?.id
        let resolvedActionPrompt = selectedCandidate?.prompt
        let resolvedSecondaryActionID = secondaryCandidate?.id
        let resolvedSecondaryActionPrompt = secondaryCandidate?.prompt

        let systemImage: String
        switch tone {
        case .alert:
            systemImage = "exclamationmark.shield.fill"
        case .watch:
            systemImage = "shield.lefthalf.filled"
        case .steady:
            systemImage = winDelta?.systemImage ?? "chart.line.uptrend.xyaxis"
        case .prime:
            systemImage = "sparkles"
        }

        var helpParts = [confidenceScore.helpText]
        if let winDelta {
            helpParts.append(winDelta.helpText)
        }
        if let hallOfFameCue {
            helpParts.append(hallOfFameCue.helpText)
        }
        if let rescuePlan {
            helpParts.append(
                "Recommendation rescue confidence is \(rescuePlan.conversionRatePercent)% (\(rescuePlan.conversions)/\(rescuePlan.opportunities)); \(rescuePlan.opensSinceLastConversion) open(s) since the last conversion."
            )
        }
        if let routeFlipRhythmTone {
            helpParts.append(
                fameMomentumPanelRouteFlipRhythmHelpText(
                    tone: routeFlipRhythmTone,
                    selectedCandidate: selectedCandidate
                )
            )
        }
        if let selectedCandidate,
           let recency = selectedCandidate.recency {
            helpParts.append(fameMomentumPanelActionRecencyHelpText(recency))
        }

        let helpText = helpParts.joined(separator: " ")
        let reasonChips = fameMomentumPanelReasonChips(
            needsAttention: needsAttention,
            winDelta: winDelta,
            selectedCandidate: selectedCandidate,
            secondaryCandidate: secondaryCandidate,
            secondaryScoreGap: secondaryScoreGap,
            routeFlipRhythmTone: routeFlipRhythmTone,
            rescueActionID: rescueActionID
        )
        return FameMomentumPanel(
            tone: tone,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText,
            actionID: resolvedActionID,
            actionPrompt: resolvedActionPrompt,
            secondaryActionID: resolvedSecondaryActionID,
            secondaryActionPrompt: resolvedSecondaryActionPrompt,
            actionScore: selectedCandidate?.score,
            secondaryActionScore: secondaryCandidate?.score,
            actionRecency: selectedCandidate?.recency,
            secondaryActionRecency: secondaryCandidate?.recency,
            selectionConfidence: selectionConfidence,
            reasonChips: reasonChips,
            routeFlipRhythmTone: routeFlipRhythmTone,
            interventionTrustTrend: interventionTrustTrend
        )
    }

    private static func fameMomentumPanelReasonChips(
        needsAttention: Bool,
        winDelta: LaunchRecoveryHotKeyWinDelta?,
        selectedCandidate: FameMomentumPanelCandidate?,
        secondaryCandidate: FameMomentumPanelCandidate?,
        secondaryScoreGap: Int?,
        routeFlipRhythmTone: FameMomentumPanelRouteFlipRhythmTone?,
        rescueActionID: String?
    ) -> [FameMomentumPanelReasonChip] {
        var chips: [FameMomentumPanelReasonChip] = []

        if needsAttention {
            chips.append(
                FameMomentumPanelReasonChip(
                    title: "Trust Priority",
                    systemImage: "exclamationmark.shield",
                    helpText: "Trust is below target, so trust recovery actions are weighted ahead."
                )
            )
        }

        if let selectedCandidate,
           selectedCandidate.observedImpact != 0 {
            let signedImpact = selectedCandidate.observedImpact > 0
                ? "+\(selectedCandidate.observedImpact)"
                : "\(selectedCandidate.observedImpact)"
            chips.append(
                FameMomentumPanelReasonChip(
                    title: "Observed \(signedImpact)",
                    systemImage: selectedCandidate.observedImpact > 0
                        ? "arrow.up.right.circle.fill"
                        : "arrow.down.right.circle.fill",
                    helpText: "Recent panel outcomes changed this action's rank by observed impact \(signedImpact)."
                )
            )
        }

        if let selectedCandidate,
           selectedCandidate.id == rescueActionID,
           selectedCandidate.rescueConfidenceBonus != 0 {
            let signedBonus = selectedCandidate.rescueConfidenceBonus > 0
                ? "+\(selectedCandidate.rescueConfidenceBonus)"
                : "\(selectedCandidate.rescueConfidenceBonus)"
            chips.append(
                FameMomentumPanelReasonChip(
                    title: "Rescue Conf \(signedBonus)",
                    systemImage: selectedCandidate.rescueConfidenceBonus > 0
                        ? "checkmark.seal.fill"
                        : "clock.badge.exclamationmark",
                    helpText: "Cold-lane rescue confidence adjusted this ranking by \(signedBonus)."
                )
            )
        }

        if let selectedCandidate,
           selectedCandidate.rhythmBonus != 0,
           chips.count < 3 {
            let signedBonus = selectedCandidate.rhythmBonus > 0
                ? "+\(selectedCandidate.rhythmBonus)"
                : "\(selectedCandidate.rhythmBonus)"
            let titlePrefix: String
            let systemImage: String
            let helpText: String
            switch routeFlipRhythmTone {
            case .volatile:
                titlePrefix = "Rhythm Vol"
                systemImage = "waveform.path.ecg.rectangle.fill"
                helpText = "Route flips are volatile, so ranking amplifies fresh wins and discounts stale signals (\(signedBonus))."
            case .watch:
                titlePrefix = "Rhythm Watch"
                systemImage = "eye.trianglebadge.exclamationmark"
                helpText = "Route flips remain sensitive, so ranking applies light rhythm weighting (\(signedBonus))."
            case .stabilizing:
                titlePrefix = "Rhythm Settle"
                systemImage = "checkmark.seal.fill"
                helpText = "Route rhythm is stabilizing, so ranking keeps only mild rhythm weighting (\(signedBonus))."
            case nil:
                titlePrefix = "Rhythm"
                systemImage = "line.3.horizontal.decrease.circle"
                helpText = "Route rhythm weighting adjusted this route by \(signedBonus)."
            }
            chips.append(
                FameMomentumPanelReasonChip(
                    title: "\(titlePrefix) \(signedBonus)",
                    systemImage: systemImage,
                    helpText: helpText
                )
            )
        }

        if let selectedCandidate,
           let recency = selectedCandidate.recency,
           chips.count < 3 {
            chips.append(
                FameMomentumPanelReasonChip(
                    title: fameMomentumPanelActionRecencyChipTitle(recency),
                    systemImage: fameMomentumPanelActionRecencyChipSystemImage(recency),
                    helpText: fameMomentumPanelActionRecencyHelpText(recency)
                )
            )
        }

        if let winDelta, chips.count < 3 {
            let signedDelta = winDelta.deltaWins > 0 ? "+\(winDelta.deltaWins)" : "\(winDelta.deltaWins)"
            chips.append(
                FameMomentumPanelReasonChip(
                    title: "Δwins \(signedDelta)",
                    systemImage: winDelta.systemImage,
                    helpText: winDelta.helpText
                )
            )
        }

        if let secondaryCandidate,
           let secondaryScoreGap,
           chips.count < 3 {
            let compactPrompt = secondaryCandidate.prompt
                .replacingOccurrences(of: "Run ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackLabel = compactPrompt.isEmpty ? "Backup Ready" : "Backup \(compactPrompt)"
            chips.append(
                FameMomentumPanelReasonChip(
                    title: fallbackLabel,
                    systemImage: "arrow.triangle.branch",
                    helpText: "A fallback action stayed close in rank (gap \(secondaryScoreGap)). Use it if the primary step is blocked."
                )
            )
        }

        if chips.isEmpty {
            chips.append(
                FameMomentumPanelReasonChip(
                    title: "Base Priority",
                    systemImage: "line.3.horizontal.decrease.circle",
                    helpText: "No strong adaptive signal yet, so base Top Picks priority decides."
                )
            )
        }

        return Array(chips.prefix(3))
    }

    private static func fameMomentumPanelRouteFlipRhythmAdaptiveBonus(
        tone: FameMomentumPanelRouteFlipRhythmTone?,
        recency: FameMomentumPanelActionRecency?,
        observedImpact: Int
    ) -> Int {
        guard let tone else { return 0 }
        switch tone {
        case .stabilizing:
            return 0
        case .watch:
            let recencyBonus: Int
            switch recency {
            case .recentlyValidated:
                recencyBonus = 8
            case .aging:
                recencyBonus = -4
            case .stale:
                recencyBonus = -8
            case nil:
                recencyBonus = 0
            }
            return recencyBonus
        case .volatile:
            let recencyBonus: Int
            switch recency {
            case .recentlyValidated:
                recencyBonus = 24
            case .aging:
                recencyBonus = -10
            case .stale:
                recencyBonus = -20
            case nil:
                recencyBonus = 0
            }
            let impactBonus: Int
            if observedImpact > 0 {
                impactBonus = 6
            } else if observedImpact < 0 {
                impactBonus = -6
            } else {
                impactBonus = 0
            }
            return recencyBonus + impactBonus
        }
    }

    private static func fameMomentumPanelRouteFlipRhythmHelpText(
        tone: FameMomentumPanelRouteFlipRhythmTone,
        selectedCandidate: FameMomentumPanelCandidate?
    ) -> String {
        let bonus = selectedCandidate?.rhythmBonus ?? 0
        let signedBonus = bonus > 0 ? "+\(bonus)" : "\(bonus)"
        switch tone {
        case .stabilizing:
            return "Route rhythm is stabilizing, so ranking keeps baseline weighting (current rhythm adjustment \(signedBonus))."
        case .watch:
            return "Route rhythm is on watch, so ranking adds gentle anti-flip weighting (current adjustment \(signedBonus))."
        case .volatile:
            return "Route rhythm is volatile, so ranking prioritizes fresh, high-signal routes to reduce noisy flips (current adjustment \(signedBonus))."
        }
    }

    private static func fameMomentumPanelActionRecencyAdaptiveBonus(
        _ recency: FameMomentumPanelActionRecency?
    ) -> Int {
        guard let recency else { return 0 }
        switch recency {
        case .recentlyValidated(let opensAgo):
            if opensAgo <= 0 {
                return 10
            }
            if opensAgo == 1 {
                return 6
            }
            return 3
        case .aging(let opensAgo):
            if opensAgo <= 3 {
                return -2
            }
            return -6
        case .stale(let opensAgo):
            if opensAgo >= 8 {
                return -16
            }
            return -12
        }
    }

    private static func fameMomentumPanelActionRecencyChipTitle(
        _ recency: FameMomentumPanelActionRecency
    ) -> String {
        switch recency {
        case .recentlyValidated:
            return "Signal Fresh"
        case .aging:
            return "Signal Aging"
        case .stale:
            return "Signal Stale"
        }
    }

    private static func fameMomentumPanelActionRecencyChipSystemImage(
        _ recency: FameMomentumPanelActionRecency
    ) -> String {
        switch recency {
        case .recentlyValidated:
            return "clock.badge.checkmark"
        case .aging:
            return "clock.arrow.circlepath"
        case .stale:
            return "clock.badge.exclamationmark"
        }
    }

    private static func fameMomentumPanelActionRecencyHelpText(
        _ recency: FameMomentumPanelActionRecency
    ) -> String {
        switch recency {
        case .recentlyValidated(let opensAgo):
            if opensAgo <= 0 {
                return "This action's learning signal was refreshed in the current open, so it receives a freshness bonus."
            }
            if opensAgo == 1 {
                return "This action's learning signal was refreshed 1 open ago, so it keeps a small freshness bonus."
            }
            return "This action's learning signal was refreshed \(opensAgo) opens ago, so it keeps a mild freshness bonus."
        case .aging(let opensAgo):
            return "This action's learning signal is \(opensAgo) opens old, so ranking trims some confidence until it is revalidated."
        case .stale(let opensAgo):
            return "This action's learning signal is stale (\(opensAgo) opens old), so ranking applies a stronger penalty until new conversions refresh it."
        }
    }

    private static func fameMomentumPanelSecondaryCandidate(
        selectedCandidate: FameMomentumPanelCandidate?,
        rankedCandidates: [FameMomentumPanelCandidate],
        needsAttention: Bool
    ) -> FameMomentumPanelCandidate? {
        guard let selectedCandidate,
              rankedCandidates.count >= 2 else {
            return nil
        }
        let runnerUp = rankedCandidates[1]
        let gap = max(0, selectedCandidate.score - runnerUp.score)
        let maxGap = needsAttention ? 76 : 52
        let shouldSurfaceRunnerUp = gap <= maxGap
            || (selectedCandidate.observedImpact < 0 && gap <= maxGap + 18)
            || (runnerUp.observedImpact > 0 && gap <= maxGap + 12)
            || (selectedCandidate.recencyBonus < 0 && gap <= maxGap + 14)
            || (runnerUp.recencyBonus > 0 && gap <= maxGap + 8)
        guard shouldSurfaceRunnerUp else { return nil }
        return runnerUp
    }

    private static func fameMomentumPanelSelectionConfidence(
        selectedCandidate: FameMomentumPanelCandidate?,
        rankedCandidates: [FameMomentumPanelCandidate],
        secondaryCandidate: FameMomentumPanelCandidate?,
        needsAttention: Bool
    ) -> FameMomentumPanelSelectionConfidence? {
        guard let selectedCandidate else { return nil }
        guard let runnerUp = rankedCandidates.dropFirst().first else {
            return FameMomentumPanelSelectionConfidence(
                tier: .locked,
                confidencePercent: 100,
                gapPoints: 120,
                title: "Selection Locked",
                subtitle: "Only one eligible route",
                systemImage: "lock.shield.fill",
                helpText: "Only one eligible Fame momentum action is currently enabled, so ranking confidence is treated as locked."
            )
        }

        let gapPoints = max(0, selectedCandidate.score - runnerUp.score)
        let confidencePercent = max(
            0,
            min(
                100,
                Int(round(Double(min(120, gapPoints)) / 1.2))
            )
        )
        let tier: FameMomentumPanelSelectionConfidenceTier
        let title: String
        let systemImage: String
        if gapPoints >= 80 {
            tier = .locked
            title = "Selection Locked"
            systemImage = "lock.shield.fill"
        } else if gapPoints >= 36 {
            tier = .leaning
            title = "Selection Leaning"
            systemImage = "slider.horizontal.2.square"
        } else {
            tier = .split
            title = "Selection Split"
            systemImage = "arrow.triangle.branch"
        }

        let backupStatus = secondaryCandidate == nil ? "backup hidden" : "backup live"
        let subtitle: String
        if needsAttention && tier == .split {
            subtitle = "Gap \(gapPoints) · trust-sensitive split"
        } else {
            subtitle = "Gap \(gapPoints) · \(backupStatus)"
        }

        let helpText = "Selection confidence estimates ranking certainty from the score gap between primary and runner-up actions. Current gap is \(gapPoints) points (\(confidencePercent)% confidence). Base priority, observed impact, and rescue confidence all contribute."

        return FameMomentumPanelSelectionConfidence(
            tier: tier,
            confidencePercent: confidencePercent,
            gapPoints: gapPoints,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    static func fameMomentumPanelActionEmphasis(
        selectionConfidence: FameMomentumPanelSelectionConfidence?,
        hasSecondaryAction: Bool,
        routeFlipRhythmTone: FameMomentumPanelRouteFlipRhythmTone? = nil
    ) -> FameMomentumPanelActionEmphasis {
        guard hasSecondaryAction else { return .primaryDominant }
        guard let selectionConfidence else { return .primaryDominant }
        if selectionConfidence.tier == .split,
           selectionConfidence.gapPoints <= 18 {
            return .splitDecision
        }
        if routeFlipRhythmTone == .volatile,
           selectionConfidence.tier == .split,
           selectionConfidence.gapPoints <= 28 {
            return .splitDecision
        }
        return .primaryDominant
    }

    static func fameMomentumPanelResolvedActionPrompts(
        primaryPrompt: String?,
        secondaryPrompt: String?,
        selectionConfidence: FameMomentumPanelSelectionConfidence?,
        actionEmphasis: FameMomentumPanelActionEmphasis,
        hasSecondaryAction: Bool
    ) -> (primary: String, secondary: String?) {
        let normalizedPrimaryPrompt = normalizedFameMomentumPanelActionPrompt(
            primaryPrompt,
            fallback: "Run Next"
        )
        guard hasSecondaryAction else {
            return (normalizedPrimaryPrompt, nil)
        }

        let normalizedSecondaryPrompt = normalizedFameMomentumPanelActionPrompt(
            secondaryPrompt,
            fallback: "Run Backup"
        )
        guard actionEmphasis == .splitDecision else {
            return (normalizedPrimaryPrompt, normalizedSecondaryPrompt)
        }

        let primarySplitPrompt: String
        let secondarySplitPrompt: String
        if let selectionConfidence,
           selectionConfidence.confidencePercent <= 10 {
            primarySplitPrompt = "Best Bet"
            secondarySplitPrompt = "Alternate Bet"
        } else {
            primarySplitPrompt = "Best Bet"
            secondarySplitPrompt = "Strong Alternate"
        }
        return (primarySplitPrompt, secondarySplitPrompt)
    }

    static func fameMomentumPanelActionLabelExplanation(
        selectionConfidence: FameMomentumPanelSelectionConfidence?,
        actionEmphasis: FameMomentumPanelActionEmphasis,
        hasSecondaryAction: Bool,
        routeFlipRhythmTone: FameMomentumPanelRouteFlipRhythmTone? = nil
    ) -> String? {
        guard hasSecondaryAction else {
            return "Only one eligible action is available right now, so adaptive split labels stay off."
        }

        guard let selectionConfidence else {
            return "Label adaptation is waiting for enough ranking confidence data."
        }

        if actionEmphasis == .splitDecision {
            if routeFlipRhythmTone == .volatile,
               selectionConfidence.gapPoints > 18 {
                return "Route rhythm is volatile and decision confidence remains split (\(selectionConfidence.confidencePercent)% · gap \(selectionConfidence.gapPoints)), so labels stay in split mode to keep the backup route explicit."
            }
            if selectionConfidence.confidencePercent <= 10 {
                return "Decision confidence is ultra-tight at \(selectionConfidence.confidencePercent)% (gap \(selectionConfidence.gapPoints)), so labels switch to Best Bet and Alternate Bet."
            }
            return "Decision confidence is split at \(selectionConfidence.confidencePercent)% (gap \(selectionConfidence.gapPoints)), so labels switch to Best Bet and Strong Alternate."
        }

        return "Primary route leads by \(selectionConfidence.gapPoints) points (\(selectionConfidence.confidencePercent)% confidence), so original run/backup labels stay in place."
    }

    static func fameMomentumPanelRouteStabilizationCue(
        rhythmTone: FameMomentumPanelRouteFlipRhythmTone?,
        stabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse?,
        selectionConfidence: FameMomentumPanelSelectionConfidence?,
        hasSecondaryAction: Bool,
        stabilizationScoreboard: CommandPaletteSession.FameMomentumPanelRouteStabilizationScoreboard? =
            nil
    ) -> FameMomentumPanelRouteStabilizationCue? {
        guard rhythmTone == .volatile,
              let stabilizationPulse else {
            return nil
        }

        let shouldDualTrack = hasSecondaryAction
            && selectionConfidence?.tier == .split
        let settledPerformance = fameMomentumPanelRouteStabilizationCompletedPerformance(
            stabilizationScoreboard
        )
        let settledRuns = settledPerformance?.completedRuns ?? 0
        let settledSuccessRatePercent = settledPerformance?.successRatePercent ?? 0

        if settledRuns >= 3,
           settledSuccessRatePercent <= 40 {
            return FameMomentumPanelRouteStabilizationCue(
                focus: .primaryReset,
                title: "Route Stabilizer Reset",
                subtitle: "Hit rate \(settledSuccessRatePercent)% over \(settledRuns) settled runs · lock one route.",
                systemImage: "exclamationmark.shield.fill",
                buttonTitle: "Re-anchor Route",
                secondaryButtonTitle: nil,
                helpText: "Recent stabilizer outcomes landed at \(settledSuccessRatePercent)% across \(settledRuns) settled runs. Run the strongest primary route to re-anchor confidence before reopening the alternate lane."
            )
        }

        if shouldDualTrack,
           settledRuns >= 3,
           settledSuccessRatePercent >= 70 {
            return FameMomentumPanelRouteStabilizationCue(
                focus: .dualTrack,
                title: "Route Stabilizer Compounding",
                subtitle: "Hit rate \(settledSuccessRatePercent)% over \(settledRuns) settled runs · keep primary + alternate warm.",
                systemImage: "chart.line.uptrend.xyaxis",
                buttonTitle: "Keep Stabilizing",
                secondaryButtonTitle: "Run Alternate",
                helpText: "Stabilizer outcomes are landing at \(settledSuccessRatePercent)% across \(settledRuns) settled runs. Run the primary route while keeping the alternate hot for fast pivots if signals shift."
            )
        }

        if shouldDualTrack {
            return FameMomentumPanelRouteStabilizationCue(
                focus: .dualTrack,
                title: "Route Stabilizer Active",
                subtitle: "Volatile streak x\(stabilizationPulse.volatileStreak) · keep best bet + backup warm.",
                systemImage: "arrow.triangle.branch",
                buttonTitle: "Stabilize Now",
                secondaryButtonTitle: "Run Alternate",
                helpText: "Route rhythm remains volatile across \(stabilizationPulse.flipCount) flips in \(stabilizationPulse.openSpan) opens. Run the primary route now, with the alternate still ready as a fast fallback."
            )
        }

        return FameMomentumPanelRouteStabilizationCue(
            focus: .primaryLock,
            title: "Route Stabilizer Lock",
            subtitle: "Volatile streak x\(stabilizationPulse.volatileStreak) · anchor one clear route.",
            systemImage: "shield.lefthalf.filled.trianglebadge.exclamationmark",
            buttonTitle: "Stabilize Now",
            secondaryButtonTitle: nil,
            helpText: "Route rhythm remains volatile across \(stabilizationPulse.flipCount) flips in \(stabilizationPulse.openSpan) opens. Run the strongest primary route to re-anchor ranking confidence before another rerank."
        )
    }

    private static func fameMomentumPanelRouteStabilizationCompletedPerformance(
        _ scoreboard: CommandPaletteSession.FameMomentumPanelRouteStabilizationScoreboard?
    ) -> (completedRuns: Int, successRatePercent: Int)? {
        guard let scoreboard else { return nil }
        let completedRuns = max(0, scoreboard.runs - scoreboard.pendingRuns)
        guard completedRuns > 0 else { return nil }
        let normalizedSuccesses = max(0, min(completedRuns, scoreboard.successes))
        let successRatePercent = Int(
            round((Double(normalizedSuccesses) / Double(completedRuns)) * 100)
        )
        return (
            completedRuns: completedRuns,
            successRatePercent: successRatePercent
        )
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
        shownCount: Int,
        runCount: Int,
        blockedCount: Int
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge? {
        let normalizedShownCount = max(0, shownCount)
        guard normalizedShownCount > 0 else { return nil }

        let normalizedRunCount = max(
            0,
            min(normalizedShownCount, runCount)
        )
        let normalizedBlockedCount = max(
            0,
            min(normalizedShownCount, blockedCount)
        )
        let runRatePercent = Int(
            round((Double(normalizedRunCount) / Double(normalizedShownCount)) * 100)
        )
        let blockedRatePercent = Int(
            round((Double(normalizedBlockedCount) / Double(normalizedShownCount)) * 100)
        )

        let tone: FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeTone
        if normalizedBlockedCount > 0,
           (runRatePercent <= 34 || blockedRatePercent >= 35) {
            tone = .blocked
        } else if runRatePercent >= 65,
                  normalizedBlockedCount == 0 {
            tone = .strong
        } else {
            tone = .watch
        }

        let title: String
        let systemImage: String
        switch tone {
        case .strong:
            title = "Recovery CTA \(runRatePercent)%"
            systemImage = "checkmark.shield.fill"
        case .watch:
            if normalizedBlockedCount > 0 {
                title = "Recovery CTA \(runRatePercent)% · \(normalizedBlockedCount) blocked"
            } else {
                title = "Recovery CTA \(runRatePercent)%"
            }
            systemImage = "exclamationmark.shield.fill"
        case .blocked:
            title = "Recovery CTA Blocked x\(normalizedBlockedCount)"
            systemImage = "xmark.shield.fill"
        }

        var helpText = "Recovery suggestion CTA shown x\(normalizedShownCount); launched x\(normalizedRunCount) (\(runRatePercent)%)."
        if normalizedBlockedCount > 0 {
            helpText += " Blocked x\(normalizedBlockedCount) (\(blockedRatePercent)%) when suggested actions were unavailable."
        }
        return FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
            tone: tone,
            title: title,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
        shownCount: Int,
        blockedCount: Int,
        recoveryRunCount: Int,
        unblockRunCount: Int,
        pressureConfidenceHistory: [Int] = [],
        pressureCalibration: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?
            = nil
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge? {
        guard let blockedPressureEvaluation =
            fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureEvaluation(
                shownCount: shownCount,
                blockedCount: blockedCount,
                recoveryRunCount: recoveryRunCount,
                unblockRunCount: unblockRunCount,
                pressureCalibration: pressureCalibration
            ) else {
            return nil
        }

        let blockedCountProgress = Double(blockedPressureEvaluation.normalizedBlockedCount)
            / Double(max(1, blockedPressureEvaluation.effectiveMinBlockedCount))
        let blockedRateProgress = blockedPressureEvaluation.blockedRate
            / max(0.0001, blockedPressureEvaluation.effectiveBlockedRateThreshold)
        let sampleStrength = min(1, Double(blockedPressureEvaluation.normalizedShownCount) / 12)
        let rawConfidence: Double
        if blockedPressureEvaluation.hasBlockedPressure {
            let pressureSignalStrength = min(
                1,
                max(
                    0,
                    (min(1, blockedCountProgress) + min(1, blockedRateProgress)) / 2
                )
            )
            rawConfidence = max(
                55,
                pressureSignalStrength * (0.55 + sampleStrength * 0.45) * 100
            )
        } else {
            let countHeadroom = max(0, 1 - blockedCountProgress)
            let rateHeadroom = max(0, 1 - blockedRateProgress)
            let stabilitySignalStrength = min(1, (countHeadroom + rateHeadroom) / 2)
            rawConfidence = (0.4 + (0.6 * stabilitySignalStrength))
                * (0.55 + sampleStrength * 0.45)
                * 100
        }
        let confidencePercent = max(1, min(99, Int(round(rawConfidence))))
        let tone: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeTone
        if blockedPressureEvaluation.hasBlockedPressure {
            tone = confidencePercent >= 70 ? .alert : .watch
        } else {
            tone = confidencePercent >= 70 ? .steady : .watch
        }

        var title: String
        let systemImage: String
        switch tone {
        case .steady:
            title = "Pressure Stable \(confidencePercent)%"
            systemImage = "checkmark.shield.fill"
        case .watch:
            title = blockedPressureEvaluation.hasBlockedPressure
                ? "Pressure Watch \(confidencePercent)%"
                : "Pressure Mixed \(confidencePercent)%"
            systemImage = "exclamationmark.shield.fill"
        case .alert:
            title = "Pressure High \(confidencePercent)%"
            systemImage = "xmark.shield.fill"
        }
        if let calibrationCue = fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationTitleCue(
            biasPoints: blockedPressureEvaluation.calibrationBiasPoints,
            sampleCount: blockedPressureEvaluation.calibrationSampleCount
        ) {
            title += " · \(calibrationCue)"
        }

        let blockedRatePercent = Int(round(blockedPressureEvaluation.blockedRate * 100))
        let effectiveBlockedRatePercent = Int(
            round(blockedPressureEvaluation.effectiveBlockedRateThreshold * 100)
        )
        let unblockCoveragePercent = Int(
            round(
                (Double(blockedPressureEvaluation.normalizedUnblockRunCount)
                    / Double(max(1, blockedPressureEvaluation.normalizedRunCount))) * 100
            )
        )
        let sensitivityLabel: String
        switch blockedPressureEvaluation.pressureSensitivity {
        case .aggressive:
            sensitivityLabel = "Aggressive"
        case .balanced:
            sensitivityLabel = "Balanced"
        case .conservative:
            sensitivityLabel = "Conservative"
        }
        let coverageSignalPhrase = blockedPressureEvaluation.unblockCoverageIsLow
            ? "Coverage is skewed toward recovery runs."
            : "Coverage is balanced between recovery and unblock runs."
        let calibrationPhrase: String
        if blockedPressureEvaluation.calibrationSampleCount > 0 {
            let calibrationBiasLabel: String
            switch blockedPressureEvaluation.calibrationBiasPoints {
            case let bias where bias > 0:
                calibrationBiasLabel = "Aggressive +\(bias)"
            case let bias where bias < 0:
                calibrationBiasLabel = "Conservative \(bias)"
            default:
                calibrationBiasLabel = "Balanced 0"
            }
            calibrationPhrase = " Calibration profile is \(calibrationBiasLabel) from \(blockedPressureEvaluation.calibrationSampleCount) samples."
        } else {
            calibrationPhrase = ""
        }
        let normalizedPressureConfidenceHistory = pressureConfidenceHistory.map { value in
            max(1, min(99, value))
        }
        var pressureTrendHistory = normalizedPressureConfidenceHistory
        if pressureTrendHistory.last != confidencePercent {
            pressureTrendHistory.append(confidencePercent)
        }
        let pressureTrend = fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
            history: pressureTrendHistory
        )
        let pressureTrendPhrase = pressureTrend.map { " \($0.helpText)" } ?? ""
        let helpText = "Pressure model is \(sensitivityLabel) at \(confidencePercent)% confidence. Blocked x\(blockedPressureEvaluation.normalizedBlockedCount)/\(blockedPressureEvaluation.normalizedShownCount) cues (\(blockedRatePercent)%). Unblock coverage is \(blockedPressureEvaluation.normalizedUnblockRunCount)/\(max(1, blockedPressureEvaluation.normalizedRunCount)) runs (\(unblockCoveragePercent)%). Pressure gates require ≥\(blockedPressureEvaluation.effectiveMinBlockedCount) blocked cues and ≥\(effectiveBlockedRatePercent)% blocked rate. \(coverageSignalPhrase)\(calibrationPhrase)\(pressureTrendPhrase)"

        return FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
            tone: tone,
            confidencePercent: confidencePercent,
            title: title,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    private static func fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationTitleCue(
        biasPoints: Int,
        sampleCount: Int
    ) -> String? {
        let normalizedSampleCount = max(0, sampleCount)
        guard normalizedSampleCount > 0 else { return nil }

        let normalizedBiasPoints = max(-3, min(3, biasPoints))
        let biasLabel = normalizedBiasPoints > 0
            ? "+\(normalizedBiasPoints)"
            : "\(normalizedBiasPoints)"
        return "Cal \(biasLabel)/\(normalizedSampleCount)"
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
        history: [Int],
        baselineWindow: Int = 3,
        deltaThreshold: Int = 5
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend? {
        let normalizedHistory = history.map { value in
            max(1, min(99, value))
        }
        guard normalizedHistory.count >= 2 else { return nil }

        let latestConfidence = normalizedHistory.last ?? 0
        let baselineSampleCount = max(
            1,
            min(max(1, baselineWindow), normalizedHistory.count - 1)
        )
        let baselineSample = Array(
            normalizedHistory.dropLast().suffix(baselineSampleCount)
        )
        let baselineAverage = Int(
            round(
                Double(baselineSample.reduce(0, +))
                    / Double(max(1, baselineSample.count))
            )
        )
        let deltaPoints = latestConfidence - baselineAverage
        let normalizedDeltaThreshold = max(1, deltaThreshold)

        let direction: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrendDirection
        if deltaPoints >= normalizedDeltaThreshold {
            direction = .rising
        } else if deltaPoints <= -normalizedDeltaThreshold {
            direction = .cooling
        } else {
            direction = .steady
        }

        let deltaLabel: String
        if deltaPoints > 0 {
            deltaLabel = "+\(deltaPoints)"
        } else {
            deltaLabel = "\(deltaPoints)"
        }
        let subtitle: String
        let helpText: String
        switch direction {
        case .rising:
            subtitle = "Pressure trend rising (\(deltaLabel)pts)"
            helpText =
                "Pressure trend is rising (\(deltaLabel)pts vs recent baseline) across \(baselineSampleCount + 1) checks."
        case .cooling:
            subtitle = "Pressure trend cooling (\(deltaLabel)pts)"
            helpText =
                "Pressure trend is cooling (\(deltaLabel)pts vs recent baseline) across \(baselineSampleCount + 1) checks."
        case .steady:
            subtitle = "Pressure trend steady (\(deltaLabel)pts)"
            helpText =
                "Pressure trend is steady (\(deltaLabel)pts vs recent baseline) across \(baselineSampleCount + 1) checks."
        }

        return FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
            direction: direction,
            deltaPoints: deltaPoints,
            sampleCount: baselineSampleCount + 1,
            subtitle: subtitle,
            helpText: helpText
        )
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpText(
        baseHelpText: String,
        diagnosticsCue: FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue?,
        actionTitle: String? = nil
    ) -> String {
        guard diagnosticsCue != nil else { return baseHelpText }

        let normalizedActionTitle = actionTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedActionTitle,
           !normalizedActionTitle.isEmpty {
            return "\(baseHelpText) Click to focus recovery diagnostics and highlight \(normalizedActionTitle)."
        }

        return "\(baseHelpText) Click to focus recovery diagnostics."
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
        shownCount: Int,
        runCount: Int,
        blockedCount: Int,
        pressureConfidenceBadge: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge? = nil,
        pressureConfidenceTrend: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend? = nil,
        actionID: String? = nil,
        actionTitle: String? = nil,
        hasRunnableAction: Bool = true
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue? {
        guard let healthBadge = fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
            shownCount: shownCount,
            runCount: runCount,
            blockedCount: blockedCount
        ) else {
            return nil
        }

        let normalizedShownCount = max(0, shownCount)
        let normalizedRunCount = max(
            0,
            min(normalizedShownCount, runCount)
        )
        let normalizedBlockedCount = max(
            0,
            min(normalizedShownCount, blockedCount)
        )
        let runRatePercent = Int(
            round((Double(normalizedRunCount) / Double(max(1, normalizedShownCount))) * 100)
        )
        let blockedRatePercent = Int(
            round((Double(normalizedBlockedCount) / Double(max(1, normalizedShownCount))) * 100)
        )
        let pressureTone = pressureConfidenceBadge?.tone
        let hasPressureAlert = pressureTone == .alert
        let pressureSubtitleParts: [String] = {
            var parts: [String] = []
            if let pressureConfidenceBadge,
               pressureTone != .steady {
                parts.append(pressureConfidenceBadge.title)
            }
            if let pressureConfidenceTrend {
                parts.append(pressureConfidenceTrend.subtitle)
            }
            return parts
        }()
        let pressureSubtitleSuffix: String = {
            guard !pressureSubtitleParts.isEmpty else { return "" }
            return " · \(pressureSubtitleParts.joined(separator: " · "))"
        }()
        let pressureHelpParts: [String] = {
            var parts: [String] = []
            if let pressureConfidenceBadge {
                switch pressureConfidenceBadge.tone {
                case .steady:
                    break
                case .watch:
                    switch pressureConfidenceTrend?.direction {
                    case .cooling:
                        parts.append(
                            "\(pressureConfidenceBadge.title) remains mixed, but blocker pressure is cooling."
                        )
                    case .steady:
                        parts.append(
                            "\(pressureConfidenceBadge.title) is holding mixed pressure, so keep unblock coverage active."
                        )
                    case .rising, .none:
                        parts.append(
                            "\(pressureConfidenceBadge.title) suggests blocker pressure is rising, so keep unblock coverage active."
                        )
                    }
                case .alert:
                    parts.append(
                        "\(pressureConfidenceBadge.title) signals critical blocker pressure, so prioritize unblock coverage now."
                    )
                }
            }
            if let pressureConfidenceTrend {
                parts.append(pressureConfidenceTrend.helpText)
            }
            return parts
        }()
        let pressureHelpSuffix: String = {
            guard !pressureHelpParts.isEmpty else { return "" }
            return " \(pressureHelpParts.joined(separator: " "))"
        }()
        let hasRisingPressureWatchEscalation = pressureTone == .watch
            && pressureConfidenceTrend?.direction == .rising
            && normalizedBlockedCount > 0
            && runRatePercent <= 50
        let shouldEscalateToPressureAlert = healthBadge.tone == .watch
            && (hasPressureAlert || hasRisingPressureWatchEscalation)
        let pressureAlertTitle: String
        if hasPressureAlert {
            pressureAlertTitle = "Recovery Route Pressure Alert"
        } else if hasRisingPressureWatchEscalation {
            pressureAlertTitle = "Recovery Route Pressure Spike"
        } else {
            pressureAlertTitle = "Recovery Route Blockers"
        }

        let normalizedActionTitle = actionTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRunnableRecoveryAction = hasRunnableAction && normalizedActionTitle != nil
        let usesUnblockAction = fameMomentumPanelRouteStabilizationRecoverySuggestionUsesUnblockAction(
            actionID: actionID,
            actionTitle: normalizedActionTitle
        )
        let actionPhrase: String
        if let normalizedActionTitle, !normalizedActionTitle.isEmpty {
            actionPhrase = normalizedActionTitle.hasPrefix("Run ")
                ? normalizedActionTitle
                : "Run \(normalizedActionTitle)"
        } else {
            actionPhrase = "Run the strongest recovery route"
        }

        switch healthBadge.tone {
        case .strong:
            return nil
        case .watch:
            if shouldEscalateToPressureAlert {
                let subtitle = "Blocked x\(normalizedBlockedCount)/\(normalizedShownCount) recovery cues · run rate \(runRatePercent)%\(pressureSubtitleSuffix)."
                return FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                    tone: .blocked,
                    title: pressureAlertTitle,
                    subtitle: subtitle,
                    systemImage: "xmark.shield.fill",
                    buttonTitle: hasRunnableRecoveryAction
                        ? (usesUnblockAction ? "Run Unblock Plan" : "Run Recovery Now")
                        : "Resolve Blockers",
                    helpText: hasRunnableRecoveryAction
                        ? "Recovery suggestions are blocking too often (\(blockedRatePercent)% blocked, \(runRatePercent)% run rate). \(actionPhrase) to reopen a clean stabilization lane.\(pressureHelpSuffix)"
                        : "Recovery suggestions are blocking too often (\(blockedRatePercent)% blocked, \(runRatePercent)% run rate). No runnable recovery command is currently available, so resolve blockers to reopen a clean stabilization lane.\(pressureHelpSuffix)"
                )
            }

            let subtitle: String
            if normalizedBlockedCount > 0 {
                subtitle = "Run rate \(runRatePercent)% across \(normalizedShownCount) cues · \(normalizedBlockedCount) blocked\(pressureSubtitleSuffix)."
            } else {
                subtitle = "Run rate \(runRatePercent)% across \(normalizedShownCount) recovery cues\(pressureSubtitleSuffix)."
            }
            return FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .watch,
                title: "Recovery Route Watch",
                subtitle: subtitle,
                systemImage: "exclamationmark.shield.fill",
                buttonTitle: hasRunnableRecoveryAction
                    ? (usesUnblockAction
                        ? "Run Unblock Plan"
                        : (runRatePercent >= 50 ? "Keep Recovery Warm" : "Run Recovery Now"))
                    : "Review Blockers",
                helpText: hasRunnableRecoveryAction
                    ? "Recovery suggestion engagement is mixed at \(runRatePercent)% across \(normalizedShownCount) cues. \(actionPhrase) to keep route stabilization momentum compounding.\(pressureHelpSuffix)"
                    : "Recovery suggestion engagement is mixed at \(runRatePercent)% across \(normalizedShownCount) cues. No runnable recovery command is currently available, so review blockers to keep route stabilization momentum compounding.\(pressureHelpSuffix)"
            )
        case .blocked:
            let subtitle = "Blocked x\(normalizedBlockedCount)/\(normalizedShownCount) recovery cues · run rate \(runRatePercent)%\(pressureSubtitleSuffix)."
            return FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                tone: .blocked,
                title: "Recovery Route Blockers",
                subtitle: subtitle,
                systemImage: "xmark.shield.fill",
                buttonTitle: hasRunnableRecoveryAction
                    ? (usesUnblockAction ? "Run Unblock Plan" : "Run Recovery Now")
                    : "Resolve Blockers",
                helpText: hasRunnableRecoveryAction
                    ? "Recovery suggestions are blocking too often (\(blockedRatePercent)% blocked, \(runRatePercent)% run rate). \(actionPhrase) to reopen a clean stabilization lane.\(pressureHelpSuffix)"
                    : "Recovery suggestions are blocking too often (\(blockedRatePercent)% blocked, \(runRatePercent)% run rate). No runnable recovery command is currently available, so resolve blockers to reopen a clean stabilization lane.\(pressureHelpSuffix)"
            )
        }
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsActionHelpText(
        tone: FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueTone,
        actionTitle: String,
        isEnabled: Bool,
        disabledReason: String
    ) -> String {
        let normalizedActionTitle = actionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let runActionPhrase: String = {
            guard !normalizedActionTitle.isEmpty else { return "Run the recovery command" }
            return normalizedActionTitle.hasPrefix("Run ")
                ? normalizedActionTitle
                : "Run \(normalizedActionTitle)"
        }()

        guard isEnabled else {
            let normalizedDisabledReason = disabledReason.trimmingCharacters(in: .whitespacesAndNewlines)
            let reasonPhrase = normalizedDisabledReason.isEmpty
                ? "this command is currently unavailable"
                : normalizedDisabledReason
            switch tone {
            case .watch:
                return "Recovery command is unavailable: \(reasonPhrase). Resolve blockers, then rerun recovery."
            case .blocked:
                return "Recovery command is unavailable: \(reasonPhrase). Clear blockers to reopen a clean stabilization lane."
            }
        }

        switch tone {
        case .watch:
            return "\(runActionPhrase) to improve recovery cue throughput."
        case .blocked:
            return "\(runActionPhrase) to reopen a clean stabilization lane."
        }
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionUsesUnblockAction(
        actionID: String? = nil,
        actionTitle: String?
    ) -> Bool {
        if let actionID {
            let normalizedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalizedActionID.isEmpty {
                if fameMomentumPanelRouteStabilizationRecoveryUnblockActionIDs.contains(normalizedActionID) {
                    return true
                }
                if fameMomentumPanelRouteStabilizationRecoveryActionPriority.contains(normalizedActionID) {
                    return false
                }
            }
        }

        guard let actionTitle else { return false }
        let normalizedActionTitle = actionTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedActionTitle.isEmpty else { return false }
        return !normalizedActionTitle.localizedCaseInsensitiveContains("recovery")
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionButtonTitle(
        defaultTitle: String,
        actionID: String? = nil,
        actionTitle: String?
    ) -> String {
        if fameMomentumPanelRouteStabilizationRecoverySuggestionUsesUnblockAction(
            actionID: actionID,
            actionTitle: actionTitle
        ) {
            return "Run Unblock Plan"
        }

        let normalizedDefaultTitle = defaultTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedDefaultTitle.isEmpty else { return "Run Recovery Loop" }
        return normalizedDefaultTitle
    }

    private static func normalizedFameMomentumPanelActionPrompt(
        _ prompt: String?,
        fallback: String
    ) -> String {
        guard let prompt else { return fallback }
        let normalizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedPrompt.isEmpty else { return fallback }
        return normalizedPrompt
    }

    private static func fameMomentumPanelRescueConfidenceBonus(
        _ rescuePlan: RecommendationPairRescuePlan?
    ) -> Int {
        guard let rescuePlan else { return 0 }
        let confidenceTierBonus = max(0, (rescuePlan.conversionRatePercent - 50) / 5)
        let recencyPenalty = min(8, max(0, rescuePlan.opensSinceLastConversion / 2))
        return confidenceTierBonus - recencyPenalty
    }

    private static func fameMomentumPanelTone(
        confidenceScore: LaunchRecoveryHotKeyConfidenceScore,
        winDelta: LaunchRecoveryHotKeyWinDelta?,
        rescuePlan: RecommendationPairRescuePlan?,
        hallOfFameCue: RecommendationMomentumRescueHallOfFameDefenseCue?
    ) -> FameMomentumPanelTone {
        switch confidenceScore.tier {
        case .critical:
            return .alert
        case .watch:
            return .watch
        case .steady:
            if winDelta?.tone == .slipping || hallOfFameCue?.tone == .defense {
                return .watch
            }
            return .steady
        case .prime:
            if winDelta?.tone == .slipping || hallOfFameCue?.tone == .defense {
                return .watch
            }
            if rescuePlan != nil || winDelta != nil || hallOfFameCue != nil {
                return .steady
            }
            return .prime
        }
    }

    static func launchRecoveryHotKeyMomentum(
        for readinessHistory: [LaunchRecoveryHotKeyReadinessState],
        window: Int = 4
    ) -> LaunchRecoveryHotKeyMomentum? {
        let normalizedWindow = max(2, window)
        guard readinessHistory.count >= normalizedWindow * 2 else { return nil }

        let recentSamples = Array(readinessHistory.suffix(normalizedWindow))
        let previousSamples = Array(readinessHistory.dropLast(normalizedWindow).suffix(normalizedWindow))
        let recentScore = launchRecoveryHotKeyMomentumScore(for: recentSamples)
        let previousScore = launchRecoveryHotKeyMomentumScore(for: previousSamples)
        let deltaPoints = recentScore - previousScore
        let direction: LaunchRecoveryHotKeyMomentum.Direction
        let title: String
        let systemImage: String
        if deltaPoints >= 10 {
            direction = .rising
            title = "Momentum +\(deltaPoints)"
            systemImage = "arrow.up.right.circle.fill"
        } else if deltaPoints <= -10 {
            direction = .falling
            title = "Momentum \(deltaPoints)"
            systemImage = "arrow.down.right.circle.fill"
        } else {
            direction = .steady
            title = "Momentum Stable"
            systemImage = "equal.circle.fill"
        }
        let signedDelta = deltaPoints > 0 ? "+\(deltaPoints)" : "\(deltaPoints)"

        return LaunchRecoveryHotKeyMomentum(
            direction: direction,
            deltaPoints: deltaPoints,
            previousScore: previousScore,
            recentScore: recentScore,
            windowSize: normalizedWindow,
            title: title,
            systemImage: systemImage,
            helpText: "Launch recovery momentum compares last \(normalizedWindow) opens (\(recentScore)/100) vs prior \(normalizedWindow) opens (\(previousScore)/100), Δ\(signedDelta)."
        )
    }

    static func launchRecoveryHotKeyConfidenceScore(
        readiness: LaunchRecoveryHotKeyReadiness,
        trend: LaunchRecoveryHotKeyTrend?,
        directStreak: Int,
        bestDirectStreak: Int
    ) -> LaunchRecoveryHotKeyConfidenceScore {
        let normalizedDirectStreak = max(0, directStreak)
        let normalizedBestDirectStreak = max(normalizedDirectStreak, bestDirectStreak)
        let points = max(
            0,
            min(
                100,
                launchRecoveryHotKeyReadinessPoints(for: readiness) +
                    launchRecoveryHotKeyTrendDirectSharePoints(for: trend) +
                    min(normalizedDirectStreak * 2, 8) +
                    min(normalizedBestDirectStreak, 8)
            )
        )
        let tier = launchRecoveryHotKeyConfidenceScoreTier(for: points)
        let tierTitle = launchRecoveryHotKeyConfidenceTierTitle(for: tier)
        let trendSnapshot: String
        if let trend {
            trendSnapshot = "Trend D\(trend.directCount)·R\(trend.rerouteCount)·S\(trend.standbyCount)"
        } else {
            trendSnapshot = "Trend warming up"
        }
        let title = "Confidence \(points) · \(tierTitle)"
        let subtitle = launchRecoveryHotKeyConfidenceScoreSubtitle(
            tier: tier,
            trend: trend,
            directStreak: normalizedDirectStreak,
            bestDirectStreak: normalizedBestDirectStreak
        )
        let helpText = "Launch recovery confidence score \(points)/100 (\(tierTitle)). \(trendSnapshot). Direct streak x\(normalizedDirectStreak), best x\(normalizedBestDirectStreak)."

        return LaunchRecoveryHotKeyConfidenceScore(
            points: points,
            tier: tier,
            title: title,
            subtitle: subtitle,
            systemImage: launchRecoveryHotKeyConfidenceTierSystemImage(for: tier),
            helpText: helpText
        )
    }

    private static func launchRecoveryHotKeyMomentumScore(
        for samples: [LaunchRecoveryHotKeyReadinessState]
    ) -> Int {
        guard !samples.isEmpty else { return 0 }
        let totalScore = samples.reduce(0) { partialResult, sample in
            partialResult + launchRecoveryHotKeyMomentumStateScore(sample)
        }
        return Int(round(Double(totalScore) / Double(samples.count)))
    }

    private static func launchRecoveryHotKeyMomentumStateScore(
        _ state: LaunchRecoveryHotKeyReadinessState
    ) -> Int {
        switch state {
        case .direct:
            return 100
        case .reroute:
            return 55
        case .standby:
            return 15
        }
    }

    static func launchRecoveryHotKeyConfidenceScoreNeedsAttention(
        _ score: LaunchRecoveryHotKeyConfidenceScore
    ) -> Bool {
        switch score.tier {
        case .critical, .watch:
            return true
        case .steady, .prime:
            return false
        }
    }

    static func launchRecoveryHotKeyConfidencePulse(
        previousTier: LaunchRecoveryHotKeyConfidenceScore.Tier,
        nextTier: LaunchRecoveryHotKeyConfidenceScore.Tier,
        points: Int
    ) -> LaunchRecoveryHotKeyConfidencePulse? {
        guard previousTier != nextTier else { return nil }

        let normalizedPoints = max(0, min(100, points))
        let previousTierTitle = launchRecoveryHotKeyConfidenceTierTitle(for: previousTier)
        let nextTierTitle = launchRecoveryHotKeyConfidenceTierTitle(for: nextTier)
        let improved = launchRecoveryHotKeyConfidenceTierRank(nextTier)
            > launchRecoveryHotKeyConfidenceTierRank(previousTier)

        if improved {
            if nextTier == .prime {
                return LaunchRecoveryHotKeyConfidencePulse(
                    title: "Confidence Prime",
                    subtitle: "Recovery confidence reached Prime (\(normalizedPoints)). Keep direct streak alive.",
                    systemImage: "checkmark.seal.fill",
                    helpText: "Launch recovery confidence climbed from \(previousTierTitle) to \(nextTierTitle) at \(normalizedPoints)/100. Keep stacking direct opens to preserve prime routing."
                )
            }

            return LaunchRecoveryHotKeyConfidencePulse(
                title: "Confidence Rising",
                subtitle: "Recovery confidence moved to \(nextTierTitle) (\(normalizedPoints)).",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Launch recovery confidence improved from \(previousTierTitle) to \(nextTierTitle) at \(normalizedPoints)/100."
            )
        }

        if nextTier == .critical {
            return LaunchRecoveryHotKeyConfidencePulse(
                title: "Confidence Drop",
                subtitle: "Recovery confidence fell to Critical (\(normalizedPoints)). Run coach now.",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Launch recovery confidence dropped from \(previousTierTitle) to \(nextTierTitle) at \(normalizedPoints)/100. Run a coach step to restore direct routing."
            )
        }

        return LaunchRecoveryHotKeyConfidencePulse(
            title: "Confidence Drop",
            subtitle: "Recovery confidence slipped to \(nextTierTitle) (\(normalizedPoints)).",
            systemImage: "arrow.down.right.circle.fill",
            helpText: "Launch recovery confidence dropped from \(previousTierTitle) to \(nextTierTitle) at \(normalizedPoints)/100."
        )
    }

    static func launchRecoveryHotKeyMomentumPulse(
        previousMomentum: LaunchRecoveryHotKeyMomentum?,
        nextMomentum: LaunchRecoveryHotKeyMomentum?
    ) -> LaunchRecoveryHotKeyMomentumPulse? {
        guard let nextMomentum else { return nil }
        let signedDelta = nextMomentum.deltaPoints > 0
            ? "+\(nextMomentum.deltaPoints)"
            : "\(nextMomentum.deltaPoints)"

        switch nextMomentum.direction {
        case .steady:
            return nil
        case .rising:
            let wasRising = previousMomentum?.direction == .rising
            let isBreakout = wasRising &&
                (previousMomentum?.deltaPoints ?? 0) < 25 &&
                nextMomentum.deltaPoints >= 25
            guard !wasRising || isBreakout else { return nil }
            if isBreakout {
                return LaunchRecoveryHotKeyMomentumPulse(
                    tone: .rising,
                    title: "Recovery Momentum Breakout",
                    subtitle: "Launch recovery hit breakout pace at \(nextMomentum.recentScore)/100 (Δ\(signedDelta)).",
                    systemImage: "chart.line.uptrend.xyaxis.circle.fill",
                    helpText: "Launch recovery momentum expanded to breakout pace across \(nextMomentum.windowSize)-open windows (\(nextMomentum.previousScore) → \(nextMomentum.recentScore), Δ\(signedDelta)). Keep direct runs compounding."
                )
            }
            return LaunchRecoveryHotKeyMomentumPulse(
                tone: .rising,
                title: "Recovery Momentum Surge",
                subtitle: "Launch recovery pace accelerated to \(nextMomentum.recentScore)/100 (Δ\(signedDelta)).",
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Launch recovery momentum turned upward across \(nextMomentum.windowSize)-open windows (\(nextMomentum.previousScore) → \(nextMomentum.recentScore), Δ\(signedDelta))."
            )
        case .falling:
            let wasFalling = previousMomentum?.direction == .falling
            let isAlert = wasFalling &&
                (previousMomentum?.deltaPoints ?? 0) > -25 &&
                nextMomentum.deltaPoints <= -25
            guard !wasFalling || isAlert else { return nil }
            if isAlert {
                return LaunchRecoveryHotKeyMomentumPulse(
                    tone: .falling,
                    title: "Recovery Momentum Alert",
                    subtitle: "Launch recovery dropped to \(nextMomentum.recentScore)/100 (Δ\(signedDelta)). Run coach now.",
                    systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
                    helpText: "Launch recovery momentum has sharply deteriorated across \(nextMomentum.windowSize)-open windows (\(nextMomentum.previousScore) → \(nextMomentum.recentScore), Δ\(signedDelta)). Run a coach step now."
                )
            }
            return LaunchRecoveryHotKeyMomentumPulse(
                tone: .falling,
                title: "Recovery Momentum Slip",
                subtitle: "Launch recovery pace slipped to \(nextMomentum.recentScore)/100 (Δ\(signedDelta)).",
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Launch recovery momentum turned downward across \(nextMomentum.windowSize)-open windows (\(nextMomentum.previousScore) → \(nextMomentum.recentScore), Δ\(signedDelta))."
            )
        }
    }

    static func launchRecoveryHotKeyMomentumRescue(
        pulse: LaunchRecoveryHotKeyMomentumPulse?,
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        readiness: LaunchRecoveryHotKeyReadiness,
        enabledActionIDs: Set<String>
    ) -> LaunchRecoveryHotKeyMomentumRescue? {
        guard let pulse,
              pulse.tone == .falling else {
            return nil
        }

        let actionID = launchRecoveryHotKeyMomentumRescueActionID(
            coachCue: coachCue,
            readiness: readiness,
            enabledActionIDs: enabledActionIDs
        )
        let isAlert = pulse.title.contains("Alert")
        let severity: LaunchRecoveryHotKeyMomentumRescue.Severity = isAlert ? .alert : .watch
        let title = isAlert ? "Momentum Rescue Alert" : "Momentum Rescue Ready"
        let subtitle: String
        let helpText: String
        let systemImage: String
        if let actionID {
            let actionTitle = launchRecoveryHotKeyActionTitle(actionID: actionID)
            subtitle = "\(pulse.subtitle) \(actionTitle) now."
            helpText = "\(pulse.helpText) Run \(actionTitle) now to recover launch-routing momentum."
            systemImage = isAlert ? "cross.case.fill" : "cross.case"
        } else {
            subtitle = "\(pulse.subtitle) Queue a rescue step now."
            helpText = "\(pulse.helpText) Run a coach or recovery action now to recover launch-routing momentum."
            systemImage = isAlert ? "cross.case.fill" : "cross.case"
        }

        return LaunchRecoveryHotKeyMomentumRescue(
            severity: severity,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText,
            actionID: actionID
        )
    }

    static func launchRecoveryHotKeyInterventions(
        score: LaunchRecoveryHotKeyConfidenceScore,
        readiness: LaunchRecoveryHotKeyReadiness,
        trend: LaunchRecoveryHotKeyTrend?,
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        enabledActionIDs: Set<String>,
        interventionScores: [String: Int] = [:],
        interventionRecency: [String: LaunchRecoveryHotKeyInterventionRecency] = [:],
        limit: Int = 3
    ) -> [LaunchRecoveryHotKeyIntervention] {
        guard launchRecoveryHotKeyConfidenceScoreNeedsAttention(score) else { return [] }

        var rankedActionIDs: [String] = []
        func append(_ actionID: String?) {
            guard let actionID,
                  enabledActionIDs.contains(actionID),
                  !rankedActionIDs.contains(actionID) else {
                return
            }
            rankedActionIDs.append(actionID)
        }

        append(coachCue?.actionID)

        switch readiness {
        case .direct(let actionID), .reroute(let actionID):
            append(actionID)
        case .unavailable:
            break
        }

        append(CommandPaletteAction.launchRecoveryNextActionID)
        if let trend,
           trend.standbyCount > trend.rerouteCount {
            append("run-fame-onboarding-fill-gap")
        }

        let tierOrder: [String]
        switch score.tier {
        case .critical:
            tierOrder = launchRecoveryInterventionCriticalOrder
        case .watch:
            tierOrder = launchRecoveryInterventionWatchOrder
        case .steady, .prime:
            tierOrder = launchRecoveryInterventionWatchOrder
        }
        for actionID in tierOrder {
            append(actionID)
        }

        let baseOrder = Dictionary(uniqueKeysWithValues: rankedActionIDs.enumerated().map { ($0.element, $0.offset) })
        let sortByObservedImpact: ([String]) -> [String] = { actionIDs in
            actionIDs.sorted { lhs, rhs in
                let lhsScore = interventionScores[lhs, default: 0]
                let rhsScore = interventionScores[rhs, default: 0]
                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }
                return baseOrder[lhs, default: Int.max] < baseOrder[rhs, default: Int.max]
            }
        }

        if let coachActionID = coachCue?.actionID,
           score.tier == .critical,
           rankedActionIDs.first == coachActionID {
            let adaptiveTail = sortByObservedImpact(Array(rankedActionIDs.dropFirst()))
            rankedActionIDs = [coachActionID] + adaptiveTail
        } else {
            rankedActionIDs = sortByObservedImpact(rankedActionIDs)
        }

        let normalizedLimit = max(1, limit)
        return rankedActionIDs
            .prefix(normalizedLimit)
            .map { actionID in
                launchRecoveryHotKeyIntervention(
                    actionID: actionID,
                    coachCue: coachCue,
                    observedImpact: interventionScores[actionID, default: 0],
                    recency: interventionRecency[actionID]
                )
            }
    }

    static func isLaunchRecoveryHotKeyInterventionActionID(_ actionID: String) -> Bool {
        launchRecoveryInterventionActionIDs.contains(actionID)
    }

    static func launchRecoveryHotKeyCoachCue(
        readiness: LaunchRecoveryHotKeyReadiness,
        trend: LaunchRecoveryHotKeyTrend?,
        context: CommandPaletteTopPickContext,
        enabledActionIDs: Set<String>
    ) -> LaunchRecoveryHotKeyCoachCue? {
        guard let trend, trend.sampleCount >= 3 else { return nil }
        guard !isLaunchRecoveryHotKeyDirect(readiness) else { return nil }

        let dominantState = launchRecoveryHotKeyTrendDominantState(for: trend)
        guard dominantState != .direct else { return nil }
        guard let actionID = launchRecoveryHotKeyCoachActionID(
            context: context,
            enabledActionIDs: enabledActionIDs
        ) else {
            return nil
        }

        let actionTitle = launchRecoveryHotKeyActionTitle(actionID: actionID)
        switch dominantState {
        case .direct:
            return nil
        case .reroute:
            return LaunchRecoveryHotKeyCoachCue(
                title: "Coach: Restore ⌥⇧L Direct",
                subtitle: "Reroute leads \(trend.rerouteCount)/\(trend.sampleCount) opens. Run \(actionTitle) to restore direct launch recovery.",
                systemImage: "arrow.triangle.2.circlepath",
                actionID: actionID
            )
        case .standby:
            return LaunchRecoveryHotKeyCoachCue(
                title: "Coach: Wake Recovery Route",
                subtitle: "Standby leads \(trend.standbyCount)/\(trend.sampleCount) opens. Run \(actionTitle) to re-arm launch recovery.",
                systemImage: "bolt.badge.clock",
                actionID: actionID
            )
        }
    }

    static func launchRecoveryHotKeyDecayPulse(
        coachCue: LaunchRecoveryHotKeyCoachCue,
        streakCount: Int
    ) -> LaunchRecoveryHotKeyDecayPulse {
        let normalizedStreak = max(2, streakCount)
        return LaunchRecoveryHotKeyDecayPulse(
            title: "Recovery Drift x\(normalizedStreak)",
            subtitle: "Coach has repeated \(normalizedStreak) opens. Run \(launchRecoveryHotKeyActionTitle(actionID: coachCue.actionID)) now.",
            systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
            helpText: "Launch recovery confidence has drifted for \(normalizedStreak) consecutive palette opens. Run \(launchRecoveryHotKeyActionTitle(actionID: coachCue.actionID)) to restore direct hotkey routing."
        )
    }

    static func launchRecoveryHotKeyRestorePulse(
        previousState: LaunchRecoveryHotKeyReadinessState
    ) -> LaunchRecoveryHotKeyRestorePulse {
        switch previousState {
        case .reroute:
            return LaunchRecoveryHotKeyRestorePulse(
                title: "Direct Restored",
                subtitle: "Reroute cleared. ⌥⇧L is running direct again.",
                systemImage: "checkmark.arrow.trianglehead.counterclockwise",
                helpText: "Launch recovery reroute fallback has cleared. Global ⌥⇧L now runs the primary recovery route directly."
            )
        case .standby:
            return LaunchRecoveryHotKeyRestorePulse(
                title: "Direct Restored",
                subtitle: "Standby cleared. ⌥⇧L route is live again.",
                systemImage: "checkmark.arrow.trianglehead.counterclockwise",
                helpText: "Launch recovery standby has cleared. Global ⌥⇧L now runs the primary recovery route directly."
            )
        case .direct:
            return LaunchRecoveryHotKeyRestorePulse(
                title: "Direct Restored",
                subtitle: "⌥⇧L route remains direct.",
                systemImage: "checkmark.arrow.trianglehead.counterclockwise",
                helpText: "Global ⌥⇧L is already routed directly to the primary recovery route."
            )
        }
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
        fromTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier,
        toTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier,
        runsThisWeek: Int,
        currentStreak: Int
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse? {
        guard launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(toTier)
            > launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(fromTier) else {
            return nil
        }

        let normalizedRunsThisWeek = max(1, runsThisWeek)
        let normalizedCurrentStreak = max(0, currentStreak)
        let toTierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(toTier)
        let fromTierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(fromTier)
        let systemImage = toTier == .legend ? "crown.fill" : "sparkles"

        return LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
            fromTier: fromTier,
            toTier: toTier,
            title: "Auto League \(toTierTitle) Unlocked",
            subtitle: "Promoted from \(fromTierTitle) • Week \(normalizedRunsThisWeek) • Streak x\(normalizedCurrentStreak)d",
            systemImage: systemImage,
            helpText: "Auto Trust Surge promoted from \(fromTierTitle) to \(toTierTitle). Weekly auto-run volume is \(normalizedRunsThisWeek) with a streak of x\(normalizedCurrentStreak)d."
        )
    }

    static func recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
        fromTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier,
        toTier: RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier,
        currentWeekRuns: Int,
        currentStreak: Int
    ) -> RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse? {
        guard recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(toTier)
            > recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierRank(fromTier) else {
            return nil
        }

        let normalizedCurrentWeekRuns = max(1, currentWeekRuns)
        let normalizedCurrentStreak = max(1, currentStreak)
        let toTierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(toTier)
        let fromTierTitle = recommendationMomentumRescueHallOfFameAutoDefenseLeagueTierTitle(fromTier)
        let systemImage = toTier == .legend ? "crown.fill" : "sparkles"

        return RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
            fromTier: fromTier,
            toTier: toTier,
            title: "Defense League \(toTierTitle) Unlocked",
            subtitle: "Promoted from \(fromTierTitle) • Week \(normalizedCurrentWeekRuns) • Streak x\(normalizedCurrentStreak)d",
            systemImage: systemImage,
            helpText: "Hall-of-Fame auto-defense league promoted from \(fromTierTitle) to \(toTierTitle). Weekly auto-defense volume is \(normalizedCurrentWeekRuns) with a streak of x\(normalizedCurrentStreak)d."
        )
    }

    static func recommendationMomentumRescueHallOfFameLegendRiskPulse(
        previousForecast: RecommendationMomentumRescueHallOfFameLegendRiskForecast?,
        nextForecast: RecommendationMomentumRescueHallOfFameLegendRiskForecast?
    ) -> RecommendationMomentumRescueHallOfFameLegendRiskPulse? {
        guard let nextForecast else { return nil }

        if nextForecast.tone == .alert,
           previousForecast?.tone != .alert {
            return RecommendationMomentumRescueHallOfFameLegendRiskPulse(
                tone: .alert,
                title: "Hall-of-Fame Legend Alert",
                subtitle: nextForecast.subtitle,
                systemImage: "exclamationmark.shield.fill",
                helpText: "Hall-of-Fame legend risk escalated to \(nextForecast.riskLabel). \(nextForecast.helpText)"
            )
        }

        if let previousForecast,
           previousForecast.nextDefenseMinutes > 0,
           nextForecast.nextDefenseMinutes == 0 {
            return RecommendationMomentumRescueHallOfFameLegendRiskPulse(
                tone: .watch,
                title: "Legend Defense Window Open",
                subtitle: "Next defense is now · Risk \(nextForecast.riskLabel)",
                systemImage: "shield.checkered",
                helpText: "Hall-of-Fame legend defense timing just shifted to now. \(nextForecast.helpText)"
            )
        }

        return nil
    }

    static func recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
        actionID: String
    ) -> RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse {
        let actionTitle = recommendationMomentumRescueActionTitle(actionID: actionID)
        return RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse(
            title: "Hall-of-Fame Hold Released",
            subtitle: "\(actionTitle) unpinned after Hall-of-Fame recovery.",
            systemImage: "pin.slash.fill",
            helpText: "Hall-of-Fame legend risk recovered, so \(actionTitle) was unpinned from sticky Top Picks promotion."
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
        previousForecast: LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast?,
        nextForecast: LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast?
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse? {
        guard let nextForecast else { return nil }

        if nextForecast.tone == .alert,
           previousForecast?.tone != .alert {
            return LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                tone: .alert,
                title: "Legend Risk Alert",
                subtitle: nextForecast.subtitle,
                systemImage: "hourglass.badge.exclamationmark",
                helpText: "Legend decay risk escalated to \(nextForecast.riskLabel). \(nextForecast.helpText)"
            )
        }

        if let previousForecast,
           previousForecast.nextDefenseMinutes > 0,
           nextForecast.nextDefenseMinutes == 0 {
            return LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse(
                tone: .ready,
                title: "Legend Defense Window Open",
                subtitle: "Next defense is now · Risk \(nextForecast.riskLabel)",
                systemImage: "shield.checkerboard",
                helpText: "Legend defense timing just shifted to now. \(nextForecast.helpText)"
            )
        }

        return nil
    }

    static func launchRecoveryHotKeyLegendRiskStickyReleasePulse(
        actionID: String
    ) -> LaunchRecoveryHotKeyLegendRiskStickyReleasePulse {
        let actionTitle = launchRecoveryHotKeyActionTitle(actionID: actionID)
        return LaunchRecoveryHotKeyLegendRiskStickyReleasePulse(
            title: "Legend Hold Released",
            subtitle: "\(actionTitle) unpinned after recovery.",
            systemImage: "pin.slash.fill",
            helpText: "Legend decay forecast recovered, so \(actionTitle) was unpinned from sticky Top Picks promotion."
        )
    }

    static func launchRecoveryHotKeyInterventionTrustPulse(
        previousPoints: Int,
        nextPoints: Int
    ) -> LaunchRecoveryHotKeyInterventionTrustPulse? {
        let normalizedPreviousPoints = max(0, min(100, previousPoints))
        let normalizedNextPoints = max(0, min(100, nextPoints))
        let delta = normalizedNextPoints - normalizedPreviousPoints
        let signedDelta = delta > 0 ? "+\(delta)" : "\(delta)"

        if delta <= -12 {
            if normalizedNextPoints <= 35 || delta <= -20 {
                return LaunchRecoveryHotKeyInterventionTrustPulse(
                    tone: .falling,
                    title: "Intervention Trust Alert",
                    subtitle: "Trust fell to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Re-run coach now.",
                    systemImage: "exclamationmark.triangle.fill",
                    helpText: "Intervention trust dropped sharply from \(normalizedPreviousPoints)/100 to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Re-run the lead coach intervention and verify ordering before the next launch recovery cycle."
                )
            }

            return LaunchRecoveryHotKeyInterventionTrustPulse(
                tone: .falling,
                title: "Intervention Trust Dip",
                subtitle: "Trust slipped to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Validate ordering.",
                systemImage: "chart.line.downtrend.xyaxis",
                helpText: "Intervention trust dropped from \(normalizedPreviousPoints)/100 to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Validate top intervention ordering to keep launch recovery guidance reliable."
            )
        }

        if delta >= 12 {
            if normalizedNextPoints >= 72 || delta >= 20 {
                return LaunchRecoveryHotKeyInterventionTrustPulse(
                    tone: .rising,
                    title: "Intervention Trust Recovered",
                    subtitle: "Trust climbed to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Keep this ordering.",
                    systemImage: "arrow.up.right.circle.fill",
                    helpText: "Intervention trust rebounded from \(normalizedPreviousPoints)/100 to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Keep the current lead intervention ordering while confidence is rising."
                )
            }

            return LaunchRecoveryHotKeyInterventionTrustPulse(
                tone: .rising,
                title: "Intervention Trust Rising",
                subtitle: "Trust improved to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Keep validating.",
                systemImage: "chart.line.uptrend.xyaxis",
                helpText: "Intervention trust improved from \(normalizedPreviousPoints)/100 to \(normalizedNextPoints)/100 (Δ\(signedDelta)). Continue validating intervention ordering to preserve recovery momentum."
            )
        }

        return nil
    }

    static func launchRecoveryHotKeyAutoCoachStatus(
        isEnabled: Bool = AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
    ) -> LaunchRecoveryHotKeyAutoCoachStatus {
        guard isEnabled else { return .disabled }

        let normalizedCooldownMinutes = max(0, cooldownMinutes)
        guard normalizedCooldownMinutes > 0,
              let lastRunAt else {
            return .ready
        }

        let cooldown = TimeInterval(normalizedCooldownMinutes * 60)
        let elapsed = now.timeIntervalSince(lastRunAt)
        guard elapsed < cooldown else { return .ready }

        let remainingSeconds = max(0, cooldown - elapsed)
        let minutesRemaining = max(1, Int(ceil(remainingSeconds / 60)))
        return .coolingDown(minutesRemaining: minutesRemaining)
    }

    static func shouldAutoRunLaunchRecoveryHotKeyCoach(
        isEnabled: Bool = AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
    ) -> Bool {
        launchRecoveryHotKeyAutoCoachStatus(
            isEnabled: isEnabled,
            lastRunAt: lastRunAt,
            now: now,
            cooldownMinutes: cooldownMinutes
        ) == .ready
    }

    static func launchRecoveryHotKeyAutoRescueStatus(
        isEnabled: Bool = AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
    ) -> LaunchRecoveryHotKeyAutoRescueStatus {
        guard isEnabled else { return .disabled }

        let normalizedCooldownMinutes = max(0, cooldownMinutes)
        guard normalizedCooldownMinutes > 0,
              let lastRunAt else {
            return .ready
        }

        let cooldown = TimeInterval(normalizedCooldownMinutes * 60)
        let elapsed = now.timeIntervalSince(lastRunAt)
        guard elapsed < cooldown else { return .ready }

        let remainingSeconds = max(0, cooldown - elapsed)
        let minutesRemaining = max(1, Int(ceil(remainingSeconds / 60)))
        return .coolingDown(minutesRemaining: minutesRemaining)
    }

    static func shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
        isEnabled: Bool = AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes,
        rescue: LaunchRecoveryHotKeyMomentumRescue?,
        hasRunnableAction: Bool
    ) -> Bool {
        guard hasRunnableAction,
              let rescue,
              rescue.severity == .alert else {
            return false
        }
        return launchRecoveryHotKeyAutoRescueStatus(
            isEnabled: isEnabled,
            lastRunAt: lastRunAt,
            now: now,
            cooldownMinutes: cooldownMinutes
        ) == .ready
    }

    static func launchRecoveryHotKeyAutoRescueBadge(
        status: LaunchRecoveryHotKeyAutoRescueStatus
    ) -> LaunchRecoveryHotKeyAutoRescueBadge {
        switch status {
        case .disabled:
            return LaunchRecoveryHotKeyAutoRescueBadge(
                tone: .disabled,
                title: "Auto Rescue Off",
                systemImage: "power",
                helpText: "Launch recovery auto rescue guard is off. Enable it to auto-run one rescue step when Momentum Alert appears."
            )
        case .ready:
            return LaunchRecoveryHotKeyAutoRescueBadge(
                tone: .ready,
                title: "Auto Rescue Ready",
                systemImage: "bolt.badge.automatic",
                helpText: "Launch recovery auto rescue guard is armed and will auto-run one rescue step when Momentum Alert appears."
            )
        case .coolingDown(let minutesRemaining):
            return LaunchRecoveryHotKeyAutoRescueBadge(
                tone: .coolingDown,
                title: "Auto Rescue Cooldown \(minutesRemaining)m",
                systemImage: "clock.badge.checkmark",
                helpText: "Launch recovery auto rescue guard is cooling down for about \(minutesRemaining) more minutes."
            )
        }
    }

    static func launchRecoveryHotKeyAutoRescueRecencyBadge(
        lastRunAt: Date?,
        now: Date = Date(),
        maxAgeMinutes: Int? = nil
    ) -> LaunchRecoveryHotKeyAutoRescueRecencyBadge? {
        guard let lastRunAt else { return nil }

        let elapsed = max(0, now.timeIntervalSince(lastRunAt))
        if let maxAgeMinutes {
            let maxAge = TimeInterval(max(0, maxAgeMinutes) * 60)
            guard elapsed <= maxAge else { return nil }
        }

        if elapsed < 60 {
            return LaunchRecoveryHotKeyAutoRescueRecencyBadge(
                title: "Auto rescued <1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Launch recovery auto rescue ran less than a minute ago."
            )
        }

        let minutesAgo = max(1, Int(floor(elapsed / 60)))
        let minuteWord = minutesAgo == 1 ? "minute" : "minutes"
        return LaunchRecoveryHotKeyAutoRescueRecencyBadge(
            title: "Auto rescued \(minutesAgo)m ago",
            systemImage: "clock.arrow.circlepath",
            helpText: "Launch recovery auto rescue ran about \(minutesAgo) \(minuteWord) ago."
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeDayStamp(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        String(Int(calendar.startOfDay(for: now).timeIntervalSince1970))
    }

    static func launchRecoveryHotKeyAutoTrustSurgeRunsToday(
        dayStamp: String?,
        storedCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard let dayStamp,
              dayStamp == launchRecoveryHotKeyAutoTrustSurgeDayStamp(
                  now: now,
                  calendar: calendar
              ) else {
            return 0
        }
        return max(0, storedCount)
    }

    static func launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
        dayStamp: String?,
        storedCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (dayStamp: String, runsToday: Int) {
        let todayStamp = launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now,
            calendar: calendar
        )
        let currentRunsToday = launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: dayStamp,
            storedCount: storedCount,
            now: now,
            calendar: calendar
        )
        let updatedRunsToday: Int
        if currentRunsToday < Int.max {
            updatedRunsToday = currentRunsToday + 1
        } else {
            updatedRunsToday = Int.max
        }
        return (todayStamp, max(1, updatedRunsToday))
    }

    static func launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            ?? calendar.startOfDay(for: now)
        return String(Int(start.timeIntervalSince1970))
    }

    static func launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
        weekStamp: String?,
        storedCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int {
        guard let weekStamp,
              weekStamp == launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
                  now: now,
                  calendar: calendar
              ) else {
            return 0
        }
        return max(0, storedCount)
    }

    static func launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
        weekStamp: String?,
        storedCount: Int,
        bestWeekCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (weekStamp: String, runsThisWeek: Int, bestWeekCount: Int) {
        let currentWeekStamp = launchRecoveryHotKeyAutoTrustSurgeWeekStamp(
            now: now,
            calendar: calendar
        )
        let runsThisWeek = launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
            weekStamp: weekStamp,
            storedCount: storedCount,
            now: now,
            calendar: calendar
        )
        let updatedRunsThisWeek: Int
        if runsThisWeek < Int.max {
            updatedRunsThisWeek = runsThisWeek + 1
        } else {
            updatedRunsThisWeek = Int.max
        }
        let updatedBestWeekCount = max(max(0, bestWeekCount), updatedRunsThisWeek)
        return (
            weekStamp: currentWeekStamp,
            runsThisWeek: updatedRunsThisWeek,
            bestWeekCount: updatedBestWeekCount
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
        previousDayStamp: String?,
        currentStreak: Int,
        bestStreak: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> (streak: Int, bestStreak: Int) {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(0, bestStreak)
        let todayStamp = launchRecoveryHotKeyAutoTrustSurgeDayStamp(
            now: now,
            calendar: calendar
        )

        guard let previousDayStamp else {
            return (1, max(normalizedBestStreak, 1))
        }

        if previousDayStamp == todayStamp {
            let streak = max(1, normalizedCurrentStreak)
            return (streak, max(normalizedBestStreak, streak))
        }

        guard let yesterdayStart = calendar.date(
            byAdding: .day,
            value: -1,
            to: calendar.startOfDay(for: now)
        ) else {
            return (1, max(normalizedBestStreak, 1))
        }
        let yesterdayStamp = String(Int(yesterdayStart.timeIntervalSince1970))
        if previousDayStamp == yesterdayStamp {
            let streak = max(1, normalizedCurrentStreak) + 1
            return (streak, max(normalizedBestStreak, streak))
        }

        return (1, max(normalizedBestStreak, 1))
    }

    static func launchRecoveryHotKeyAutoTrustSurgeStatus(
        isEnabled: Bool = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
        dailyCap: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
        runsToday: Int = 0
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeStatus {
        guard isEnabled else { return .disabled }

        let normalizedDailyCap = max(0, dailyCap)
        let normalizedRunsToday = max(0, runsToday)
        if normalizedDailyCap > 0,
           normalizedRunsToday >= normalizedDailyCap {
            return .capped(
                runsToday: normalizedRunsToday,
                dailyCap: normalizedDailyCap
            )
        }

        let normalizedCooldownMinutes = max(0, cooldownMinutes)
        guard normalizedCooldownMinutes > 0,
              let lastRunAt else {
            return .ready
        }

        let cooldown = TimeInterval(normalizedCooldownMinutes * 60)
        let elapsed = now.timeIntervalSince(lastRunAt)
        guard elapsed < cooldown else { return .ready }

        let remainingSeconds = max(0, cooldown - elapsed)
        let minutesRemaining = max(1, Int(ceil(remainingSeconds / 60)))
        return .coolingDown(minutesRemaining: minutesRemaining)
    }

    static func shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
        isEnabled: Bool = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
        lastRunAt: Date?,
        now: Date = Date(),
        cooldownMinutes: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
        dailyCap: Int = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
        runsToday: Int = 0,
        remainingOpens: Int,
        confidenceNeedsAttention: Bool
    ) -> Bool {
        guard !confidenceNeedsAttention else { return false }
        guard remainingOpens <= 1 else { return false }
        return launchRecoveryHotKeyAutoTrustSurgeStatus(
            isEnabled: isEnabled,
            lastRunAt: lastRunAt,
            now: now,
            cooldownMinutes: cooldownMinutes,
            dailyCap: dailyCap,
            runsToday: runsToday
        ) == .ready
    }

    static func launchRecoveryHotKeyAutoTrustSurgeBadge(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        remainingOpens: Int
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeBadge {
        let normalizedRemainingOpens = max(1, remainingOpens)
        let openWord = normalizedRemainingOpens == 1 ? "open" : "opens"

        switch status {
        case .disabled:
            return LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .disabled,
                title: "Auto Surge Off",
                systemImage: "power",
                helpText: "Auto Trust Surge is currently off. Enable it to auto-run the momentum step when Trust Surge is 1 open from the next milestone."
            )
        case .ready:
            if normalizedRemainingOpens <= 1 {
                return LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                    tone: .ready,
                    title: "Auto Surge Ready",
                    systemImage: "bolt.badge.automatic",
                    helpText: "Auto Trust Surge is armed and will auto-run when the next 1-open milestone setup appears."
                )
            }
            return LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .ready,
                title: "Auto Surge Armed",
                systemImage: "bolt.badge.automatic",
                helpText: "Auto Trust Surge is armed. The next auto-run unlocks when Trust Surge is \(normalizedRemainingOpens) \(openWord) from its next milestone."
            )
        case .capped(let runsToday, let dailyCap):
            let runWord = runsToday == 1 ? "run" : "runs"
            return LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .capped,
                title: "Auto Surge Cap \(runsToday)/\(dailyCap)",
                systemImage: "hand.raised.slash",
                helpText: "Auto Trust Surge hit today’s cap at \(runsToday)/\(dailyCap) \(runWord). It automatically re-arms after midnight."
            )
        case .coolingDown(let minutesRemaining):
            return LaunchRecoveryHotKeyAutoTrustSurgeBadge(
                tone: .coolingDown,
                title: "Auto Surge Cooldown \(minutesRemaining)m",
                systemImage: "clock.badge.checkmark",
                helpText: "Auto Trust Surge is cooling down for about \(minutesRemaining) more minutes."
            )
        }
    }

    static func launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
        lastRunAt: Date?,
        now: Date = Date(),
        maxAgeMinutes: Int? = nil
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge? {
        guard let lastRunAt else { return nil }

        let elapsed = max(0, now.timeIntervalSince(lastRunAt))
        if let maxAgeMinutes {
            let maxAge = TimeInterval(max(0, maxAgeMinutes) * 60)
            guard elapsed <= maxAge else { return nil }
        }

        if elapsed < 60 {
            return LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                title: "Auto surged <1m ago",
                systemImage: "clock.arrow.circlepath",
                helpText: "Auto Trust Surge ran less than a minute ago."
            )
        }

        let minutesAgo = max(1, Int(floor(elapsed / 60)))
        let minuteWord = minutesAgo == 1 ? "minute" : "minutes"
        return LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
            title: "Auto surged \(minutesAgo)m ago",
            systemImage: "clock.arrow.circlepath",
            helpText: "Auto Trust Surge ran about \(minutesAgo) \(minuteWord) ago."
        )
    }

    private struct LaunchRecoveryHotKeyAutoTrustSurgeLeagueMetrics {
        let runsToday: Int
        let currentWeekRuns: Int
        let bestWeekRuns: Int
        let currentStreak: Int
        let bestStreak: Int
        let score: Int
        let hasHistory: Bool
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueMetrics {
        let normalizedRunsToday = max(0, runsToday)
        let normalizedWeekRuns = max(0, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedWeekRuns, max(0, bestWeekRuns))
        let normalizedStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedStreak, max(0, bestStreak))
        let hasHistory = normalizedRunsToday > 0 ||
            normalizedWeekRuns > 0 ||
            normalizedBestWeekRuns > 0 ||
            normalizedStreak > 0 ||
            normalizedBestStreak > 0

        var leagueScore = normalizedRunsToday + normalizedWeekRuns + (normalizedStreak * 2)
        if normalizedWeekRuns > 0, normalizedWeekRuns >= normalizedBestWeekRuns {
            leagueScore += 2
        }
        if normalizedStreak > 0, normalizedStreak >= normalizedBestStreak {
            leagueScore += 2
        }

        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: normalizedRunsToday,
            currentWeekRuns: normalizedWeekRuns,
            bestWeekRuns: normalizedBestWeekRuns,
            currentStreak: normalizedStreak,
            bestStreak: normalizedBestStreak,
            score: max(0, leagueScore),
            hasHistory: hasHistory
        )
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLeagueTier(
        metrics: LaunchRecoveryHotKeyAutoTrustSurgeLeagueMetrics
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier {
        if metrics.currentWeekRuns >= 10 || metrics.currentStreak >= 7 || metrics.score >= 20 {
            return .legend
        }
        if metrics.currentWeekRuns >= 6 || metrics.currentStreak >= 4 || metrics.score >= 12 {
            return .elite
        }
        if metrics.currentWeekRuns >= 3 || metrics.currentStreak >= 2 || metrics.score >= 6 {
            return .rising
        }
        return .starter
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(
        _ tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> String {
        switch tier {
        case .starter:
            return "Starter"
        case .rising:
            return "Rising"
        case .elite:
            return "Elite"
        case .legend:
            return "Legend"
        }
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(
        _ tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> Int {
        switch tier {
        case .starter:
            return 0
        case .rising:
            return 1
        case .elite:
            return 2
        case .legend:
            return 3
        }
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLeagueTierSystemImage(
        _ tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> String {
        switch tier {
        case .starter:
            return "figure.run"
        case .rising:
            return "chart.line.uptrend.xyaxis"
        case .elite:
            return "bolt.fill"
        case .legend:
            return "crown.fill"
        }
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLeagueNextTier(
        currentTier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> (tier: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier, threshold: Int)? {
        switch currentTier {
        case .starter:
            return (.rising, 6)
        case .rising:
            return (.elite, 12)
        case .elite:
            return (.legend, 20)
        case .legend:
            return nil
        }
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeStatusSummary(
        _ status: LaunchRecoveryHotKeyAutoTrustSurgeStatus
    ) -> String {
        switch status {
        case .disabled:
            return "Auto Trust Surge is currently disabled."
        case .ready:
            return "Auto Trust Surge is armed and ready."
        case .coolingDown(let minutesRemaining):
            return "Auto Trust Surge is cooling down (\(minutesRemaining)m remaining)."
        case .capped(let cappedRunsToday, let dailyCap):
            let normalizedCappedRunsToday = max(0, cappedRunsToday)
            let normalizedDailyCap = max(1, dailyCap)
            return "Auto Trust Surge reached today’s cap at \(normalizedCappedRunsToday)/\(normalizedDailyCap) runs."
        }
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge? {
        let metrics = launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: runsToday,
            currentWeekRuns: currentWeekRuns,
            bestWeekRuns: bestWeekRuns,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
        if case .disabled = status, !metrics.hasHistory {
            return nil
        }

        let tier = launchRecoveryHotKeyAutoTrustSurgeLeagueTier(metrics: metrics)
        let tierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(tier)
        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
            tier: tier,
            title: "Auto League \(tierTitle)",
            systemImage: launchRecoveryHotKeyAutoTrustSurgeLeagueTierSystemImage(tier),
            helpText: "\(launchRecoveryHotKeyAutoTrustSurgeStatusSummary(status)) League tier uses today \(metrics.runsToday), week \(metrics.currentWeekRuns)/\(metrics.bestWeekRuns), and streak x\(metrics.currentStreak)d (best x\(metrics.bestStreak))."
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress? {
        let metrics = launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: runsToday,
            currentWeekRuns: currentWeekRuns,
            bestWeekRuns: bestWeekRuns,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
        if case .disabled = status, !metrics.hasHistory {
            return nil
        }

        let tier = launchRecoveryHotKeyAutoTrustSurgeLeagueTier(metrics: metrics)
        let tierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(tier)
        let subtitle = "League \(tierTitle) • Score \(metrics.score) • Week \(metrics.currentWeekRuns)/\(metrics.bestWeekRuns) • Streak x\(metrics.currentStreak)d"
        guard let nextTier = launchRecoveryHotKeyAutoTrustSurgeLeagueNextTier(currentTier: tier) else {
            return LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                tier: tier,
                pointsToNextTier: 0,
                title: "Auto League Legend Locked",
                subtitle: subtitle,
                systemImage: "crown.fill",
                helpText: "\(launchRecoveryHotKeyAutoTrustSurgeStatusSummary(status)) Legend tier is active. Score \(metrics.score) reflects sustained weekly runs and streak pressure."
            )
        }

        let nextTierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(nextTier.tier)
        let pointsToNextTier = max(1, nextTier.threshold - metrics.score)
        let pointWord = pointsToNextTier == 1 ? "point" : "points"
        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
            tier: tier,
            pointsToNextTier: pointsToNextTier,
            title: "\(pointsToNextTier) \(pointWord) to \(nextTierTitle)",
            subtitle: subtitle,
            systemImage: "flag.checkered.2.crossed",
            helpText: "\(launchRecoveryHotKeyAutoTrustSurgeStatusSummary(status)) Auto League score is \(metrics.score). Need \(pointsToNextTier) more \(pointWord) to reach \(nextTierTitle). Score grows from daily auto runs, weekly volume, and streak compounding."
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
        defaults: UserDefaults = .standard,
        historyKey: String = AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
        limit: Int = 12
    ) -> [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek] {
        guard limit > 0 else { return [] }
        guard let data = defaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode(
                  [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek].self,
                  from: data
              ) else {
            return []
        }

        return Array(
            normalizedLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistory(history)
                .prefix(limit)
        )
    }

    private static func normalizedLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
        _ history: [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek]
    ) -> [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek] {
        var historyByWeek: [String: LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek] = [:]
        historyByWeek.reserveCapacity(history.count)
        for item in history {
            guard let normalizedItem = normalizedLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(item) else {
                continue
            }
            historyByWeek[normalizedItem.weekStamp] = normalizedItem
        }

        return historyByWeek.values.sorted { lhs, rhs in
            (Int(lhs.weekStamp) ?? 0) > (Int(rhs.weekStamp) ?? 0)
        }
    }

    private static func normalizedLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
        _ week: LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek? {
        guard let normalizedWeekStamp = normalizedLeagueHistoryWeekStamp(week.weekStamp) else {
            return nil
        }

        let metrics = launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: week.runsToday,
            currentWeekRuns: week.runsThisWeek,
            bestWeekRuns: week.bestWeekRuns,
            currentStreak: week.currentStreak,
            bestStreak: week.bestStreak
        )
        let normalizedTier = launchRecoveryHotKeyAutoTrustSurgeLeagueTier(metrics: metrics)

        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
            weekStamp: normalizedWeekStamp,
            runsToday: metrics.runsToday,
            runsThisWeek: metrics.currentWeekRuns,
            bestWeekRuns: metrics.bestWeekRuns,
            currentStreak: metrics.currentStreak,
            bestStreak: metrics.bestStreak,
            leagueScore: metrics.score,
            tier: normalizedTier
        )
    }

    private static func normalizedLeagueHistoryWeekStamp(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let stamp = Int(trimmed), stamp > 0 else {
            return nil
        }
        return String(stamp)
    }

    static func launchRecoveryHotKeyAutoTrustSurgeRecordedLeagueHistory(
        history: [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek],
        weekStamp: String,
        runsToday: Int,
        runsThisWeek: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int,
        limit: Int = 12
    ) -> [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek] {
        guard limit > 0 else { return [] }
        let metrics = launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: runsToday,
            currentWeekRuns: runsThisWeek,
            bestWeekRuns: bestWeekRuns,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
        let week = LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek(
            weekStamp: weekStamp,
            runsToday: metrics.runsToday,
            runsThisWeek: metrics.currentWeekRuns,
            bestWeekRuns: metrics.bestWeekRuns,
            currentStreak: metrics.currentStreak,
            bestStreak: metrics.bestStreak,
            leagueScore: metrics.score,
            tier: launchRecoveryHotKeyAutoTrustSurgeLeagueTier(metrics: metrics)
        )
        var historyByWeek: [String: LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek] = [:]
        for item in history {
            historyByWeek[item.weekStamp] = item
        }
        historyByWeek[weekStamp] = week

        return Array(
            historyByWeek.values
                .sorted { lhs, rhs in
                    (Int(lhs.weekStamp) ?? 0) > (Int(rhs.weekStamp) ?? 0)
                }
                .prefix(limit)
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
        history: [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek]
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition? {
        let sortedHistory = history.sorted { lhs, rhs in
            (Int(lhs.weekStamp) ?? 0) < (Int(rhs.weekStamp) ?? 0)
        }
        guard sortedHistory.count >= 2 else { return nil }
        guard let latest = sortedHistory.last else { return nil }
        let previous = sortedHistory[sortedHistory.count - 2]
        guard latest.tier != previous.tier else { return nil }

        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
            fromTier: previous.tier,
            toTier: latest.tier,
            weekStamp: latest.weekStamp
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
        history: [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek],
        sampleLimit: Int = 3
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend? {
        let normalizedSampleLimit = max(2, sampleLimit)
        let sortedHistory = history.sorted { lhs, rhs in
            (Int(lhs.weekStamp) ?? 0) < (Int(rhs.weekStamp) ?? 0)
        }
        let samples = Array(sortedHistory.suffix(normalizedSampleLimit))
        guard samples.count >= 2,
              let first = samples.first,
              let last = samples.last else {
            return nil
        }

        let scoreDelta = last.leagueScore - first.leagueScore
        let scoreDeltaLabel = scoreDelta > 0 ? "+\(scoreDelta)" : "\(scoreDelta)"
        let fromTier = first.tier
        let toTier = last.tier
        let tierDelta = launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(toTier)
            - launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(fromTier)
        let fromTierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(fromTier)
        let toTierTitle = launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(toTier)
        let sampleCount = samples.count
        let sampleWord = sampleCount == 1 ? "week" : "weeks"

        if tierDelta > 0 || scoreDelta >= 3 {
            let subtitle: String
            if tierDelta > 0 {
                subtitle = "\(sampleCount)w climb · \(fromTierTitle) -> \(toTierTitle)"
            } else {
                subtitle = "\(sampleCount)w climb · \(toTierTitle)"
            }
            return LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                direction: .rising,
                sampleCount: sampleCount,
                scoreDelta: scoreDelta,
                fromTier: fromTier,
                toTier: toTier,
                title: "League Heat \(scoreDeltaLabel)",
                subtitle: subtitle,
                systemImage: "arrow.up.right.circle.fill",
                helpText: "Auto League momentum is rising over the last \(sampleCount) \(sampleWord): score \(first.leagueScore) -> \(last.leagueScore) (Δ\(scoreDeltaLabel)), tier \(fromTierTitle) -> \(toTierTitle)."
            )
        }

        if tierDelta < 0 || scoreDelta <= -3 {
            let subtitle: String
            if tierDelta < 0 {
                subtitle = "\(sampleCount)w slide · \(fromTierTitle) -> \(toTierTitle)"
            } else {
                subtitle = "\(sampleCount)w slide · \(toTierTitle)"
            }
            return LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                direction: .falling,
                sampleCount: sampleCount,
                scoreDelta: scoreDelta,
                fromTier: fromTier,
                toTier: toTier,
                title: "League Drift \(scoreDeltaLabel)",
                subtitle: subtitle,
                systemImage: "arrow.down.right.circle.fill",
                helpText: "Auto League momentum is cooling over the last \(sampleCount) \(sampleWord): score \(first.leagueScore) -> \(last.leagueScore) (Δ\(scoreDeltaLabel)), tier \(fromTierTitle) -> \(toTierTitle)."
            )
        }

        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
            direction: .steady,
            sampleCount: sampleCount,
            scoreDelta: scoreDelta,
            fromTier: fromTier,
            toTier: toTier,
            title: "League Holding",
            subtitle: "\(sampleCount)w steady · \(toTierTitle) at \(last.leagueScore)",
            systemImage: "equal.circle.fill",
            helpText: "Auto League momentum is steady over the last \(sampleCount) \(sampleWord): score \(first.leagueScore) -> \(last.leagueScore) (Δ\(scoreDeltaLabel)) while holding \(toTierTitle)."
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        trend: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend?,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int,
        enabledActionIDs: Set<String>
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense? {
        let metrics = launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: runsToday,
            currentWeekRuns: currentWeekRuns,
            bestWeekRuns: bestWeekRuns,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
        guard launchRecoveryHotKeyAutoTrustSurgeLeagueTier(metrics: metrics) == .legend,
              let trend else {
            return nil
        }

        let actionID = launchRecoveryHotKeyAutoTrustSurgeLegendDefenseActionID(
            enabledActionIDs: enabledActionIDs
        )
        let actionPrompt: String
        if let actionID {
            let actionTitle = launchRecoveryHotKeyActionTitle(actionID: actionID)
            actionPrompt = actionTitle.hasPrefix("Run ")
                ? "\(actionTitle) now"
                : "Run \(actionTitle) now"
        } else {
            actionPrompt = "Run a momentum defense step now"
        }

        let normalizedRunsToday = max(0, metrics.runsToday)
        let normalizedWeekRuns = max(0, metrics.currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedWeekRuns, metrics.bestWeekRuns)
        let normalizedCurrentStreak = max(0, metrics.currentStreak)
        let signedDelta = trend.scoreDelta > 0 ? "+\(trend.scoreDelta)" : "\(trend.scoreDelta)"

        switch trend.direction {
        case .falling:
            return LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                tone: .alert,
                title: "Legend Defense Alert",
                subtitle: "Legend under pressure · \(trend.title) (Δ\(signedDelta))",
                systemImage: "shield.slash.fill",
                helpText: "\(launchRecoveryHotKeyAutoTrustSurgeStatusSummary(status)) Legend defense flagged over \(trend.sampleCount) weeks (\(trend.subtitle)). \(actionPrompt) to protect Legend with week \(normalizedWeekRuns)/\(normalizedBestWeekRuns) and streak x\(normalizedCurrentStreak)d.",
                actionID: actionID
            )
        case .steady:
            if normalizedRunsToday > 0, trend.scoreDelta > 0 {
                return nil
            }
            let runWord = normalizedRunsToday == 1 ? "run" : "runs"
            return LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                tone: .watch,
                title: "Legend Defense Check",
                subtitle: "Legend holding · Today \(normalizedRunsToday) \(runWord) · Week \(normalizedWeekRuns)/\(normalizedBestWeekRuns)",
                systemImage: "shield.lefthalf.filled",
                helpText: "\(launchRecoveryHotKeyAutoTrustSurgeStatusSummary(status)) Legend is holding but needs a defense touchpoint. \(actionPrompt) to keep the tier stable while trend reads \(trend.title).",
                actionID: actionID
            )
        case .rising:
            return nil
        }
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLegendDefenseActionID(
        enabledActionIDs: Set<String>
    ) -> String? {
        let preferredActionIDs = [
            "run-fame-cadence-autopilot-loop",
            "run-fame-next-move-cadence-execution-kit",
            CommandPaletteAction.launchRecoveryNextActionID,
            "run-fame-onboarding-daily-brief"
        ]
        for actionID in preferredActionIDs where enabledActionIDs.contains(actionID) {
            return actionID
        }
        return nil
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        trend: LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend?,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int,
        enabledActionIDs: Set<String>,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast? {
        let metrics = launchRecoveryHotKeyAutoTrustSurgeLeagueMetrics(
            runsToday: runsToday,
            currentWeekRuns: currentWeekRuns,
            bestWeekRuns: bestWeekRuns,
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
        guard launchRecoveryHotKeyAutoTrustSurgeLeagueTier(metrics: metrics) == .legend,
              let trend,
              trend.direction != .rising else {
            return nil
        }

        let actionID = launchRecoveryHotKeyAutoTrustSurgeLegendDefenseActionID(
            enabledActionIDs: enabledActionIDs
        )
        let actionPrompt: String
        if let actionID {
            let actionTitle = launchRecoveryHotKeyActionTitle(actionID: actionID)
            actionPrompt = actionTitle.hasPrefix("Run ")
                ? actionTitle
                : "Run \(actionTitle)"
        } else {
            actionPrompt = "Run a defense step"
        }

        let nextDefenseWindow = launchRecoveryHotKeyAutoTrustSurgeLegendDecayNextDefenseWindow(
            status: status,
            now: now,
            calendar: calendar
        )
        let tierDelta = launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(trend.toTier)
            - launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(trend.fromTier)
        let isHighRisk = trend.direction == .falling && (trend.scoreDelta <= -8 || tierDelta < 0)
        let riskLabel = isHighRisk ? "High" : "Watch"
        let tone: LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastTone = isHighRisk ? .alert : .watch

        let title: String
        let subtitle: String
        let systemImage: String
        switch trend.direction {
        case .falling:
            let estimatedSlipDays = launchRecoveryHotKeyAutoTrustSurgeLegendDecayEstimatedSlipDays(
                currentScore: metrics.score,
                trendScoreDelta: trend.scoreDelta,
                sampleCount: trend.sampleCount
            )
            title = "Legend Decay Forecast"
            subtitle = "Risk \(riskLabel) · est. tier slip ~\(estimatedSlipDays)d · Next defense \(nextDefenseWindow.label)"
            systemImage = isHighRisk
                ? "hourglass.badge.exclamationmark"
                : "hourglass"
        case .steady:
            title = "Legend Stability Forecast"
            subtitle = "Risk Watch · \(trend.subtitle) · Next defense \(nextDefenseWindow.label)"
            systemImage = "clock.arrow.circlepath"
        case .rising:
            return nil
        }

        let normalizedWeekRuns = max(0, metrics.currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedWeekRuns, metrics.bestWeekRuns)
        let normalizedCurrentStreak = max(0, metrics.currentStreak)
        let timingInstruction: String
        if nextDefenseWindow.minutesUntil <= 0 {
            timingInstruction = "\(actionPrompt) now to reinforce Legend."
        } else {
            timingInstruction = "\(actionPrompt) at about \(nextDefenseWindow.clockLabel) to reinforce Legend."
        }
        let helpText = "\(launchRecoveryHotKeyAutoTrustSurgeStatusSummary(status)) \(trend.helpText) Defense timing \(nextDefenseWindow.label). \(timingInstruction) Current week \(normalizedWeekRuns)/\(normalizedBestWeekRuns), streak x\(normalizedCurrentStreak)d."

        return LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            tone: tone,
            riskLabel: riskLabel,
            nextDefenseMinutes: nextDefenseWindow.minutesUntil,
            nextDefenseLabel: nextDefenseWindow.label,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText,
            actionID: actionID
        )
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLegendDecayEstimatedSlipDays(
        currentScore: Int,
        trendScoreDelta: Int,
        sampleCount: Int
    ) -> Int {
        guard trendScoreDelta < 0 else { return 30 }
        let normalizedCurrentScore = max(0, currentScore)
        let pointsUntilLegendDrop = max(1, normalizedCurrentScore - 19)
        let intervals = max(1, sampleCount - 1)
        let weeklyDrop = Double(max(1, abs(trendScoreDelta))) / Double(intervals)
        let estimatedWeeks = Double(pointsUntilLegendDrop) / weeklyDrop
        return max(1, Int(ceil(estimatedWeeks * 7)))
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeLegendDecayNextDefenseWindow(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        now: Date,
        calendar: Calendar
    ) -> (minutesUntil: Int, label: String, clockLabel: String) {
        switch status {
        case .disabled, .ready:
            return (0, "now", launchRecoveryHotKeyAutoTrustSurgeClockLabel(now, calendar: calendar))
        case .coolingDown(let minutesRemaining):
            let minutesUntil = max(1, minutesRemaining)
            let targetDate = now.addingTimeInterval(TimeInterval(minutesUntil * 60))
            let targetLabel = launchRecoveryHotKeyAutoTrustSurgeClockLabel(targetDate, calendar: calendar)
            return (minutesUntil, "in \(minutesUntil)m (~\(targetLabel))", targetLabel)
        case .capped:
            let startOfTomorrow: Date
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
                startOfTomorrow = nextDay
            } else {
                startOfTomorrow = now.addingTimeInterval(24 * 60 * 60)
            }
            let minutesUntil = max(1, Int(ceil(startOfTomorrow.timeIntervalSince(now) / 60)))
            let targetLabel = launchRecoveryHotKeyAutoTrustSurgeClockLabel(startOfTomorrow, calendar: calendar)
            return (minutesUntil, "after reset in \(minutesUntil)m (~\(targetLabel))", targetLabel)
        }
    }

    private static func launchRecoveryHotKeyAutoTrustSurgeClockLabel(
        _ date: Date,
        calendar: Calendar
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionTransition(
        previousHistory: [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek],
        updatedHistory: [LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek],
        weekStamp: String
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition? {
        guard let updatedWeek = updatedHistory.first(where: { $0.weekStamp == weekStamp }) else {
            return nil
        }

        let previousWeek = previousHistory.first(where: { $0.weekStamp == weekStamp }) ??
            previousHistory.max { lhs, rhs in
                (Int(lhs.weekStamp) ?? 0) < (Int(rhs.weekStamp) ?? 0)
            }
        guard let previousWeek else { return nil }
        guard launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(updatedWeek.tier)
            > launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(previousWeek.tier) else {
            return nil
        }

        return LaunchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
            fromTier: previousWeek.tier,
            toTier: updatedWeek.tier,
            weekStamp: weekStamp
        )
    }

    static func launchRecoveryHotKeyAutoTrustSurgeInsight(
        status: LaunchRecoveryHotKeyAutoTrustSurgeStatus,
        runsToday: Int,
        currentWeekRuns: Int,
        bestWeekRuns: Int,
        currentStreak: Int,
        bestStreak: Int
    ) -> LaunchRecoveryHotKeyAutoTrustSurgeInsight? {
        let normalizedRunsToday = max(0, runsToday)
        let normalizedWeekRuns = max(0, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedWeekRuns, max(0, bestWeekRuns))
        let normalizedStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedStreak, max(0, bestStreak))
        let hasHistory = normalizedRunsToday > 0 ||
            normalizedWeekRuns > 0 ||
            normalizedBestWeekRuns > 0 ||
            normalizedStreak > 0 ||
            normalizedBestStreak > 0

        if case .disabled = status, !hasHistory {
            return nil
        }

        let subtitle = "Today \(normalizedRunsToday) • Week \(normalizedWeekRuns)/\(normalizedBestWeekRuns) • Streak x\(normalizedStreak)d"
        let scoreline = "Today: \(normalizedRunsToday) auto runs. Week: \(normalizedWeekRuns) runs (best \(normalizedBestWeekRuns)). Streak: x\(normalizedStreak) days (best x\(normalizedBestStreak))."

        switch status {
        case .disabled:
            return LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .standby,
                title: "Auto Surge Engine Paused",
                subtitle: subtitle,
                systemImage: "pause.circle",
                helpText: "Auto Trust Surge is disabled. \(scoreline) Re-enable Auto Trust Surge to keep the streak engine compounding."
            )
        case .capped(let cappedRunsToday, let dailyCap):
            let normalizedCappedRunsToday = max(0, cappedRunsToday)
            let normalizedDailyCap = max(1, dailyCap)
            return LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .capped,
                title: "Auto Surge Engine Capped",
                subtitle: subtitle,
                systemImage: "flag.checkered",
                helpText: "Auto Trust Surge reached today’s cap at \(normalizedCappedRunsToday)/\(normalizedDailyCap) runs. \(scoreline)"
            )
        case .coolingDown(let minutesRemaining):
            return LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .coolingDown,
                title: "Auto Surge Engine Cooling",
                subtitle: subtitle,
                systemImage: "hourglass.bottomhalf.filled",
                helpText: "Auto Trust Surge is cooling down and re-arms in about \(minutesRemaining) minutes. \(scoreline)"
            )
        case .ready:
            let isPodiumPace = normalizedWeekRuns >= max(5, normalizedBestWeekRuns) ||
                normalizedStreak >= max(4, normalizedBestStreak) ||
                (normalizedRunsToday >= 3 && normalizedStreak >= 2)
            if isPodiumPace {
                return LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                    tone: .podium,
                    title: "Auto Surge Engine Podium Pace",
                    subtitle: subtitle,
                    systemImage: "trophy.fill",
                    helpText: "Auto Trust Surge is running at a leaderboard pace. \(scoreline)"
                )
            }

            let isClimbing = normalizedRunsToday >= 2 || normalizedWeekRuns >= 3 || normalizedStreak >= 2
            if isClimbing {
                return LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                    tone: .climbing,
                    title: "Auto Surge Engine Climbing",
                    subtitle: subtitle,
                    systemImage: "chart.line.uptrend.xyaxis",
                    helpText: "Auto Trust Surge is compounding with strong momentum. \(scoreline)"
                )
            }

            return LaunchRecoveryHotKeyAutoTrustSurgeInsight(
                tone: .primed,
                title: "Auto Surge Engine Primed",
                subtitle: subtitle,
                systemImage: "bolt.badge.automatic",
                helpText: "Auto Trust Surge is armed and waiting for the next 1-open milestone setup. \(scoreline)"
            )
        }
    }

    static func launchRecoveryHotKeyBadgeTitle(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> String {
        switch readiness {
        case .direct:
            return "⌥⇧L Direct"
        case .reroute:
            return "⌥⇧L Reroute"
        case .unavailable:
            return "⌥⇧L Standby"
        }
    }

    static func launchRecoveryHotKeyBadgeSystemImage(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> String {
        switch readiness {
        case .direct:
            return "checkmark.seal.fill"
        case .reroute:
            return "arrow.triangle.branch"
        case .unavailable:
            return "clock"
        }
    }

    static func launchRecoveryHotKeyBadgeHelpText(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> String {
        switch readiness {
        case .direct(let actionID):
            return "Global launch recovery hotkey is primed to run \(launchRecoveryHotKeyActionTitle(actionID: actionID)) directly."
        case .reroute(let actionID):
            return "Global launch recovery hotkey will auto-reroute to \(launchRecoveryHotKeyActionTitle(actionID: actionID)) until a fresh recovery pulse appears."
        case .unavailable:
            return "Global launch recovery hotkey is on standby until a recovery action becomes eligible."
        }
    }

    static func launchRecoveryHotKeyLegendRiskStickyPromotionBadgeTitle(
        opensRemaining: Int,
        holdUntilRecovered: Bool
    ) -> String {
        let normalizedOpensRemaining = max(1, opensRemaining)
        if holdUntilRecovered {
            return "Legend Hold Auto \(normalizedOpensRemaining)"
        }
        return "Legend Hold \(normalizedOpensRemaining)"
    }

    static func launchRecoveryHotKeyLegendRiskStickyPromotionBadgeHelpText(
        actionTitle: String,
        opensRemaining: Int,
        holdUntilRecovered: Bool
    ) -> String {
        let normalizedOpensRemaining = max(1, opensRemaining)
        let openWord = normalizedOpensRemaining == 1 ? "open" : "opens"
        let holdWindowText = "Legend Risk Alert pinned \(actionTitle) to the front of Top Picks for \(normalizedOpensRemaining) more \(openWord), including this open."
        guard holdUntilRecovered else { return holdWindowText }
        return "\(holdWindowText) Auto hold is active and keeps extending while the legend decay forecast remains active."
    }

    static func recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeTitle(
        opensRemaining: Int,
        holdUntilRecovered: Bool
    ) -> String {
        let normalizedOpensRemaining = max(1, opensRemaining)
        if holdUntilRecovered {
            return "Hall-of-Fame Hold Auto \(normalizedOpensRemaining)"
        }
        return "Hall-of-Fame Hold \(normalizedOpensRemaining)"
    }

    static func recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeHelpText(
        actionTitle: String,
        opensRemaining: Int,
        holdUntilRecovered: Bool
    ) -> String {
        let normalizedOpensRemaining = max(1, opensRemaining)
        let openWord = normalizedOpensRemaining == 1 ? "open" : "opens"
        let holdWindowText = "Hall-of-Fame Legend Risk pinned \(actionTitle) to the front of Top Picks for \(normalizedOpensRemaining) more \(openWord), including this open."
        guard holdUntilRecovered else { return holdWindowText }
        return "\(holdWindowText) Auto hold is active and keeps extending while Hall-of-Fame legend risk remains active."
    }

    static func launchRecoveryHotKeyPromptTitle(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> String? {
        guard case .direct = readiness else { return nil }
        return "Press ⌥⇧L now"
    }

    static func launchRecoveryHotKeyPromptSystemImage(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> String? {
        guard case .direct = readiness else { return nil }
        return "keyboard"
    }

    static func launchRecoveryHotKeyPromptHelpText(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> String? {
        guard case .direct(let actionID) = readiness else { return nil }
        return "Launch recovery route is direct. Press Option + Shift + L now to run \(launchRecoveryHotKeyActionTitle(actionID: actionID))."
    }

    static func appearingActionIDs(previous: [String], current: [String]) -> Set<String> {
        Set(current).subtracting(Set(previous))
    }

    static func onboardingRecoveryFollowupTitle(actionID: String?) -> String? {
        guard let actionID = actionID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !actionID.isEmpty else {
            return nil
        }
        switch actionID {
        case "run-fame-onboarding-fill-gap":
            return "Fill Onboarding Gap"
        case "run-fame-onboarding-daily-brief":
            return "Run First-Week Daily Brief"
        case "run-fame-onboarding-scorecard":
            return "Run First-Week Fame Scorecard"
        case "run-fame-onboarding-nudge":
            return "Run Fame Onboarding Nudge"
        case "run-fame-next-move-cadence-execution-kit":
            return "Run Next-Move Cadence Execution Kit"
        case "run-fame-cadence-autopilot-loop":
            return "Run Fame Cadence Autopilot Loop"
        case CommandPaletteAction.launchRecoveryNextActionID:
            return "Launch Recovery Next"
        default:
            return nil
        }
    }

    private static func launchRecoveryHotKeyActionTitle(actionID: String) -> String {
        onboardingRecoveryFollowupTitle(actionID: actionID) ?? "the best recovery action"
    }

    private static func recommendationMomentumRescueActionTitle(actionID: String) -> String {
        if let followupTitle = onboardingRecoveryFollowupTitle(actionID: actionID) {
            return followupTitle
        }
        switch actionID {
        case "run-fame-next-move-copy-drafts":
            return "Copy Next-Move Drafts"
        case "run-fame-next-move":
            return "Run Fame Next Move"
        default:
            return "the suggested rescue action"
        }
    }

    private static func launchRecoveryHotKeyIntervention(
        actionID: String,
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        observedImpact: Int,
        recency: LaunchRecoveryHotKeyInterventionRecency?
    ) -> LaunchRecoveryHotKeyIntervention {
        let impactSuffix = launchRecoveryHotKeyInterventionImpactSuffix(observedImpact)
        let recencySuffix = launchRecoveryHotKeyInterventionRecencySuffix(recency)
        if let coachCue,
           coachCue.actionID == actionID {
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Coach Step",
                subtitle: coachCue.subtitle,
                systemImage: coachCue.systemImage,
                helpText: "Priority intervention. \(coachCue.subtitle)\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        }

        switch actionID {
        case CommandPaletteAction.launchRecoveryNextActionID:
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Recovery Next",
                subtitle: "Run the dedicated one-click recovery route now and re-check confidence.",
                systemImage: "command",
                helpText: "Run Launch Recovery Next now to validate direct route readiness.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        case "run-fame-onboarding-fill-gap":
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Fill Gap",
                subtitle: "Close onboarding recovery gaps and rebuild direct confidence quickly.",
                systemImage: "sparkles",
                helpText: "Run Fill Onboarding Gap to restore a direct launch recovery route.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        case "run-fame-onboarding-scorecard":
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Scorecard",
                subtitle: "Run the first-week scorecard to stabilize signal quality.",
                systemImage: "chart.bar.fill",
                helpText: "Run the first-week scorecard to tighten recovery signal quality.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        case "run-fame-onboarding-daily-brief":
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Daily Brief",
                subtitle: "Queue today’s next recovery move from the onboarding brief.",
                systemImage: "calendar.badge.clock",
                helpText: "Run the onboarding daily brief to queue the best next recovery step.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        case "run-fame-onboarding-nudge":
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Nudge",
                subtitle: "Ship the next onboarding nudge to keep confidence compounding.",
                systemImage: "bolt.badge.a",
                helpText: "Run onboarding nudge to keep recovery momentum moving.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        case "run-fame-cadence-autopilot-loop":
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Cadence Loop",
                subtitle: "Spin cadence autopilot so recovery outputs keep shipping.",
                systemImage: "arrow.triangle.2.circlepath",
                helpText: "Run cadence autopilot loop to keep recovery execution active.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        default:
            let actionTitle = launchRecoveryHotKeyActionTitle(actionID: actionID)
            return LaunchRecoveryHotKeyIntervention(
                actionID: actionID,
                title: "Run Step",
                subtitle: "Run \(actionTitle) to strengthen launch recovery confidence.",
                systemImage: "bolt.fill",
                helpText: "Run \(actionTitle) as an intervention to improve launch recovery confidence.\(impactSuffix)\(recencySuffix)",
                impactScore: observedImpact,
                recency: recency
            )
        }
    }

    private static func launchRecoveryHotKeyInterventionImpactSuffix(_ score: Int) -> String {
        guard score != 0 else { return "" }
        let sign = score > 0 ? "+" : ""
        return " Observed impact \(sign)\(score)."
    }

    private static func launchRecoveryHotKeyInterventionRecencySuffix(
        _ recency: LaunchRecoveryHotKeyInterventionRecency?
    ) -> String {
        guard let recency else { return "" }
        switch recency {
        case .recentlyValidated(let opensAgo):
            if opensAgo <= 0 {
                return " Recently validated this open."
            }
            if opensAgo == 1 {
                return " Recently validated 1 open ago."
            }
            return " Recently validated \(opensAgo) opens ago."
        case .stale(let opensAgo):
            if opensAgo == 1 {
                return " Intervention signal is stale after 1 open."
            }
            return " Intervention signal is stale after \(max(2, opensAgo)) opens."
        }
    }

    static func launchRecoveryHotKeyInterventionButtonTitle(
        _ intervention: LaunchRecoveryHotKeyIntervention
    ) -> String {
        var title = intervention.title
        if let impactBadge = launchRecoveryHotKeyInterventionImpactBadgeTitle(intervention.impactScore) {
            title += " \(impactBadge)"
        }
        if let recencyBadge = launchRecoveryHotKeyInterventionRecencyBadgeTitle(intervention.recency) {
            title += " (\(recencyBadge))"
        }
        return title
    }

    static func launchRecoveryHotKeyInterventionImpactBadgeTitle(_ score: Int) -> String? {
        guard score != 0 else { return nil }
        let sign = score > 0 ? "+" : ""
        return "\(sign)\(score)"
    }

    static func launchRecoveryHotKeyInterventionImpactTone(
        _ score: Int
    ) -> LaunchRecoveryHotKeyInterventionImpactTone? {
        if score > 0 {
            return .positive
        }
        if score < 0 {
            return .negative
        }
        return nil
    }

    static func launchRecoveryHotKeyInterventionRecencyBadgeTitle(
        _ recency: LaunchRecoveryHotKeyInterventionRecency?
    ) -> String? {
        guard let recency else { return nil }
        switch recency {
        case .recentlyValidated:
            return "Recent"
        case .stale:
            return "Stale"
        }
    }

    static func launchRecoveryHotKeyInterventionRecencyTone(
        _ recency: LaunchRecoveryHotKeyInterventionRecency?
    ) -> LaunchRecoveryHotKeyInterventionRecencyTone? {
        guard let recency else { return nil }
        switch recency {
        case .recentlyValidated:
            return .recent
        case .stale:
            return .stale
        }
    }

    static func launchRecoveryHotKeyInterventionTrustPoints(
        interventionScores: [String: Int],
        interventionRecency: [String: LaunchRecoveryHotKeyInterventionRecency]
    ) -> Int {
        let normalizedScores = interventionScores
            .filter { isLaunchRecoveryHotKeyInterventionActionID($0.key) }
            .mapValues { max(-12, min(12, $0)) }
            .filter { $0.value != 0 }

        guard !normalizedScores.isEmpty else { return 24 }

        var weightedStrength: Double = 0
        var recentCount = 0

        for (actionID, score) in normalizedScores {
            let normalizedMagnitude = min(6, abs(score))
            let recency = interventionRecency[actionID] ?? .stale(opensAgo: 6)
            let freshnessWeight: Double
            switch recency {
            case .recentlyValidated(let opensAgo):
                if opensAgo <= 0 {
                    freshnessWeight = 1
                } else if opensAgo == 1 {
                    freshnessWeight = 0.9
                } else {
                    freshnessWeight = 0.82
                }
                recentCount += 1
            case .stale:
                freshnessWeight = 0.55
            }

            weightedStrength += Double(normalizedMagnitude) * freshnessWeight
        }

        let signalCount = normalizedScores.count
        let averageStrength = weightedStrength / Double(max(1, signalCount))
        let recentRatio = Double(recentCount) / Double(max(1, signalCount))
        let coverageBonus = Double(min(signalCount, 3)) * 6
        let rawPoints = 18 + (averageStrength * 9) + (recentRatio * 26) + coverageBonus
        return max(0, min(100, Int(round(rawPoints))))
    }

    static func launchRecoveryHotKeyInterventionTrustTrend(
        for history: [Int],
        limit: Int = 8
    ) -> LaunchRecoveryHotKeyInterventionTrustTrend? {
        let normalizedLimit = max(2, limit)
        let samples = Array(history.suffix(normalizedLimit)).map { max(0, min(100, $0)) }
        guard samples.count >= 2,
              let currentPoints = samples.last else {
            return nil
        }

        let baselineWindow = max(1, samples.count / 2)
        let baselinePoints = Int(round(
            Double(samples.prefix(baselineWindow).reduce(0, +)) / Double(baselineWindow)
        ))
        let deltaPoints = currentPoints - baselinePoints
        let direction: LaunchRecoveryHotKeyInterventionTrustTrend.Direction
        let title: String
        let systemImage: String
        if deltaPoints >= 6 {
            direction = .rising
            title = "Intervention Trust Rising"
            systemImage = "chart.line.uptrend.xyaxis"
        } else if deltaPoints <= -6 {
            direction = .falling
            title = "Intervention Trust Sliding"
            systemImage = "chart.line.downtrend.xyaxis"
        } else {
            direction = .steady
            title = "Intervention Trust Stable"
            systemImage = "minus.forwardslash.plus"
        }

        let signedDelta = deltaPoints > 0 ? "+\(deltaPoints)" : "\(deltaPoints)"
        let subtitle = "Trust \(currentPoints)/100 · Δ\(signedDelta)"
        let noun = samples.count == 1 ? "open" : "opens"
        let helpText = "Intervention trust estimates how reliable recovery ordering is based on observed impact strength and recency over the last \(samples.count) \(noun). Current \(currentPoints)/100 (Δ\(signedDelta))."

        return LaunchRecoveryHotKeyInterventionTrustTrend(
            samples: samples,
            currentPoints: currentPoints,
            deltaPoints: deltaPoints,
            direction: direction,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    static func shouldCelebrateFameMomentumPanelTrustTrendTransition(
        previousDirection: LaunchRecoveryHotKeyInterventionTrustTrend.Direction?,
        nextDirection: LaunchRecoveryHotKeyInterventionTrustTrend.Direction
    ) -> Bool {
        guard let previousDirection else { return false }
        return previousDirection == .falling && nextDirection == .rising
    }

    static func launchRecoveryHotKeyInterventionTrustGuard(
        for trend: LaunchRecoveryHotKeyInterventionTrustTrend
    ) -> LaunchRecoveryHotKeyInterventionTrustGuard? {
        guard trend.direction == .falling else { return nil }

        let signedDelta = trend.deltaPoints > 0 ? "+\(trend.deltaPoints)" : "\(trend.deltaPoints)"
        if trend.currentPoints <= 38 || trend.deltaPoints <= -18 {
            return LaunchRecoveryHotKeyInterventionTrustGuard(
                severity: .critical,
                title: "Trust Guard Critical",
                subtitle: "Trust dropped to \(trend.currentPoints)/100 (Δ\(signedDelta)). Run a trust fix now.",
                systemImage: "exclamationmark.triangle.fill",
                helpText: "Intervention trust is sliding critically at \(trend.currentPoints)/100 (Δ\(signedDelta)). Run a coach or recovery-next action to revalidate intervention ordering before the next launch cycle."
            )
        }

        guard trend.deltaPoints <= -8 else { return nil }
        return LaunchRecoveryHotKeyInterventionTrustGuard(
            severity: .watch,
            title: "Trust Guard Watch",
            subtitle: "Trust is sliding to \(trend.currentPoints)/100 (Δ\(signedDelta)). Validate ordering.",
            systemImage: "shield.lefthalf.filled",
            helpText: "Intervention trust is trending down at \(trend.currentPoints)/100 (Δ\(signedDelta)). Run a trust-fix step to refresh intervention ordering confidence."
        )
    }

    static func launchRecoveryHotKeyInterventionTrustGuardActionID(
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        enabledActionIDs: Set<String>
    ) -> String? {
        if let coachActionID = coachCue?.actionID,
           enabledActionIDs.contains(coachActionID) {
            return coachActionID
        }

        if enabledActionIDs.contains(CommandPaletteAction.launchRecoveryNextActionID) {
            return CommandPaletteAction.launchRecoveryNextActionID
        }

        for actionID in launchRecoveryInterventionWatchOrder where enabledActionIDs.contains(actionID) {
            return actionID
        }
        return nil
    }

    static func launchRecoveryHotKeyInterventionTrustMomentum(
        for history: [Int],
        reboundDeltaThreshold: Int = 12,
        minimumStreak: Int = 2
    ) -> LaunchRecoveryHotKeyInterventionTrustMomentum? {
        let normalizedThreshold = max(1, reboundDeltaThreshold)
        let samples = history.map { max(0, min(100, $0)) }
        guard samples.count >= 2 else { return nil }

        var streak = 0
        for index in stride(from: samples.count - 1, to: 0, by: -1) {
            let delta = samples[index] - samples[index - 1]
            guard delta >= normalizedThreshold else { break }
            streak += 1
        }

        let normalizedMinimumStreak = max(2, minimumStreak)
        guard streak >= normalizedMinimumStreak,
              let currentPoints = samples.last else {
            return nil
        }

        let baselineIndex = max(0, samples.count - streak - 1)
        let baselinePoints = samples[baselineIndex]
        let recoveredPoints = max(0, currentPoints - baselinePoints)
        let systemImage: String
        if streak >= 5 {
            systemImage = "trophy.fill"
        } else if streak >= 3 {
            systemImage = "flame.fill"
        } else {
            systemImage = "arrow.up.right.circle.fill"
        }

        let title = "Trust Momentum x\(streak)"
        let subtitle = "Rebound +\(recoveredPoints) · Trust \(currentPoints)/100"
        let helpText = "Intervention trust has rebounded for \(streak) consecutive opens (+\(recoveredPoints) points) and now sits at \(currentPoints)/100. Keep the current recovery ordering active while momentum holds."

        return LaunchRecoveryHotKeyInterventionTrustMomentum(
            streak: streak,
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            helpText: helpText
        )
    }

    static func launchRecoveryHotKeyInterventionTrustMomentumPulse(
        for history: [Int],
        reboundDeltaThreshold: Int = 12
    ) -> LaunchRecoveryHotKeyInterventionTrustMomentumPulse? {
        guard let momentum = launchRecoveryHotKeyInterventionTrustMomentum(
            for: history,
            reboundDeltaThreshold: reboundDeltaThreshold,
            minimumStreak: 3
        ),
              let milestone = launchRecoveryHotKeyInterventionTrustMomentumMilestone(
                for: momentum.streak
              ) else {
            return nil
        }

        let title = "Trust Momentum Milestone x\(milestone)"
        let subtitle = "Milestone x\(milestone) unlocked · \(momentum.subtitle)"
        return LaunchRecoveryHotKeyInterventionTrustMomentumPulse(
            streak: momentum.streak,
            milestone: milestone,
            title: title,
            subtitle: subtitle,
            systemImage: momentum.systemImage,
            helpText: "\(title). \(momentum.helpText)"
        )
    }

    static func launchRecoveryHotKeyInterventionTrustMomentumPlan(
        momentum: LaunchRecoveryHotKeyInterventionTrustMomentum?,
        interventions: [LaunchRecoveryHotKeyIntervention],
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        enabledActionIDs: Set<String>,
        minimumStreak: Int = 3
    ) -> LaunchRecoveryHotKeyInterventionTrustMomentumPlan? {
        guard let momentum else { return nil }
        let normalizedMinimumStreak = max(2, minimumStreak)
        guard momentum.streak >= normalizedMinimumStreak else { return nil }

        let nextMilestone = launchRecoveryHotKeyInterventionTrustMomentumNextMilestone(
            after: momentum.streak
        )
        let remainingOpens = max(1, nextMilestone - momentum.streak)
        let openWord = remainingOpens == 1 ? "open" : "opens"
        let actionID = launchRecoveryHotKeyInterventionTrustMomentumActionID(
            interventions: interventions,
            coachCue: coachCue,
            enabledActionIDs: enabledActionIDs
        )
        let actionTitle = actionID.map { actionID in
            if actionID == CommandPaletteAction.launchRecoveryNextActionID {
                return "Launch Recovery Next"
            }
            return launchRecoveryHotKeyActionTitle(actionID: actionID)
        }
        let actionPhrase = actionTitle.map { title in
            title.hasPrefix("Run ") ? title : "Run \(title)"
        }

        let title = "Trust Surge x\(momentum.streak)"
        let subtitle: String
        let helpText: String
        if let actionPhrase {
            subtitle = "Next milestone x\(nextMilestone) in \(remainingOpens) \(openWord) · \(actionPhrase)."
            helpText = "Intervention trust momentum is holding at x\(momentum.streak). \(actionPhrase) within \(remainingOpens) \(openWord) to reach milestone x\(nextMilestone) and keep recovery ordering confidence compounding."
        } else {
            subtitle = "Next milestone x\(nextMilestone) in \(remainingOpens) \(openWord) · Keep ordering active."
            helpText = "Intervention trust momentum is holding at x\(momentum.streak). Keep the current recovery ordering active over the next \(remainingOpens) \(openWord) to reach milestone x\(nextMilestone)."
        }

        return LaunchRecoveryHotKeyInterventionTrustMomentumPlan(
            streak: momentum.streak,
            nextMilestone: nextMilestone,
            remainingOpens: remainingOpens,
            title: title,
            subtitle: subtitle,
            systemImage: momentum.systemImage,
            helpText: helpText,
            actionID: actionID
        )
    }

    private static func launchRecoveryHotKeyInterventionTrustMomentumActionID(
        interventions: [LaunchRecoveryHotKeyIntervention],
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        enabledActionIDs: Set<String>
    ) -> String? {
        if let interventionActionID = interventions.first(where: { enabledActionIDs.contains($0.actionID) })?.actionID {
            return interventionActionID
        }

        if let coachActionID = coachCue?.actionID,
           enabledActionIDs.contains(coachActionID) {
            return coachActionID
        }

        if enabledActionIDs.contains(CommandPaletteAction.launchRecoveryNextActionID) {
            return CommandPaletteAction.launchRecoveryNextActionID
        }
        return nil
    }

    private static func launchRecoveryHotKeyInterventionTrustMomentumMilestone(
        for streak: Int
    ) -> Int? {
        let normalizedStreak = max(0, streak)
        if [3, 5, 10].contains(normalizedStreak) {
            return normalizedStreak
        }
        if normalizedStreak > 10 && normalizedStreak % 5 == 0 {
            return normalizedStreak
        }
        return nil
    }

    private static func launchRecoveryHotKeyInterventionTrustMomentumNextMilestone(
        after streak: Int
    ) -> Int {
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

    private static func launchRecoveryHotKeyCoachActionID(
        context: CommandPaletteTopPickContext,
        enabledActionIDs: Set<String>
    ) -> String? {
        if let quickRunActionID = onboardingRecoveryQuickRunActionID(
            for: context,
            enabledActionIDs: enabledActionIDs
        ),
           launchRecoveryCoachActionIDs.contains(quickRunActionID) {
            return quickRunActionID
        }

        for actionID in launchRecoveryCoachActionIDs where enabledActionIDs.contains(actionID) {
            return actionID
        }
        return nil
    }

    private static func launchRecoveryHotKeyMomentumRescueActionID(
        coachCue: LaunchRecoveryHotKeyCoachCue?,
        readiness: LaunchRecoveryHotKeyReadiness,
        enabledActionIDs: Set<String>
    ) -> String? {
        if let coachActionID = coachCue?.actionID,
           enabledActionIDs.contains(coachActionID) {
            return coachActionID
        }

        switch readiness {
        case .direct(let actionID), .reroute(let actionID):
            if enabledActionIDs.contains(actionID) {
                return actionID
            }
        case .unavailable:
            break
        }

        if enabledActionIDs.contains(CommandPaletteAction.launchRecoveryNextActionID) {
            return CommandPaletteAction.launchRecoveryNextActionID
        }

        for actionID in launchRecoveryInterventionWatchOrder where enabledActionIDs.contains(actionID) {
            return actionID
        }
        return nil
    }

    static func fameMomentumPanelRouteStabilizationRecoveryActionID(
        primaryActionID: String?,
        secondaryActionID: String?,
        enabledActionIDs: Set<String>,
        availableActionIDs: Set<String> = [],
        recoverySuggestionShownCount: Int = 0,
        recoverySuggestionBlockedCount: Int = 0,
        recoverySuggestionRecoveryRunCount: Int = 0,
        recoverySuggestionUnblockRunCount: Int = 0,
        pressureCalibration: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?
            = nil
    ) -> String? {
        let normalizedEnabledActionIDs: Set<String> = Set(
            enabledActionIDs.compactMap { actionID in
                let normalizedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalizedActionID.isEmpty else { return nil }
                return normalizedActionID
            }
        )
        let normalizedAvailableActionIDs: Set<String> = Set(
            availableActionIDs.compactMap { actionID in
                let normalizedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalizedActionID.isEmpty else { return nil }
                return normalizedActionID
            }
        )

        let normalizedPrimaryActionID = primaryActionID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSecondaryActionID = secondaryActionID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let directCandidates: [String] = [normalizedPrimaryActionID, normalizedSecondaryActionID]
            .compactMap { actionID in
                guard let actionID, !actionID.isEmpty else { return nil }
                return actionID
            }

        let shouldPrioritizeUnblockRoute = fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
            shownCount: recoverySuggestionShownCount,
            blockedCount: recoverySuggestionBlockedCount,
            recoveryRunCount: recoverySuggestionRecoveryRunCount,
            unblockRunCount: recoverySuggestionUnblockRunCount,
            pressureCalibration: pressureCalibration
        )
        let prioritizedActionOrder: [String] = {
            guard shouldPrioritizeUnblockRoute else {
                return fameMomentumPanelRouteStabilizationRecoveryActionPriority
            }

            var seenActionIDs = Set<String>()
            return (fameMomentumPanelRouteStabilizationRecoveryUnblockActionPriority
                + fameMomentumPanelRouteStabilizationRecoveryActionPriority)
                .filter { actionID in
                    seenActionIDs.insert(actionID).inserted
                }
        }()

        if let prioritizedFallbackMatch = prioritizedActionOrder
            .first(where: { actionID in normalizedEnabledActionIDs.contains(actionID) }) {
            return prioritizedFallbackMatch
        }

        if let directEnabledMatch = directCandidates.first(where: { actionID in
            normalizedEnabledActionIDs.contains(actionID)
        }) {
            return directEnabledMatch
        }

        if let prioritizedAvailableMatch = prioritizedActionOrder
            .first(where: { actionID in normalizedAvailableActionIDs.contains(actionID) }) {
            return prioritizedAvailableMatch
        }

        if let directAvailableMatch = directCandidates.first(where: { actionID in
            normalizedAvailableActionIDs.contains(actionID)
        }) {
            return directAvailableMatch
        }

        return nil
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionAdaptiveTriggerThreshold(
        defaultThreshold: Int,
        shownCount: Int,
        blockedCount: Int,
        recoveryRunCount: Int,
        unblockRunCount: Int,
        pressureCalibration: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?
            = nil
    ) -> Int {
        let normalizedDefaultThreshold = max(1, defaultThreshold)
        guard fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
            shownCount: shownCount,
            blockedCount: blockedCount,
            recoveryRunCount: recoveryRunCount,
            unblockRunCount: unblockRunCount,
            pressureCalibration: pressureCalibration
        ) else {
            return normalizedDefaultThreshold
        }

        return max(1, normalizedDefaultThreshold - 1)
    }

    static func fameMomentumPanelRouteStabilizationRecoverySuggestionHasBlockedPressure(
        shownCount: Int,
        blockedCount: Int,
        recoveryRunCount: Int,
        unblockRunCount: Int,
        pressureCalibration: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?
            = nil
    ) -> Bool {
        guard let evaluation = fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureEvaluation(
            shownCount: shownCount,
            blockedCount: blockedCount,
            recoveryRunCount: recoveryRunCount,
            unblockRunCount: unblockRunCount,
            pressureCalibration: pressureCalibration
        ) else {
            return false
        }
        return evaluation.hasBlockedPressure
    }

    private struct FameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureEvaluation {
        let normalizedShownCount: Int
        let normalizedBlockedCount: Int
        let normalizedRecoveryRunCount: Int
        let normalizedUnblockRunCount: Int
        let normalizedRunCount: Int
        let blockedRate: Double
        let hasNoUnblockCoverage: Bool
        let unblockCoverageIsLow: Bool
        let effectiveMinBlockedCount: Int
        let effectiveBlockedRateThreshold: Double
        let pressureSensitivity: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureSensitivity
        let calibrationBiasPoints: Int
        let calibrationSampleCount: Int
        let hasBlockedPressure: Bool
    }

    private static func fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureEvaluation(
        shownCount: Int,
        blockedCount: Int,
        recoveryRunCount: Int,
        unblockRunCount: Int,
        pressureCalibration: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?
            = nil
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureEvaluation? {
        let normalizedShownCount = max(0, shownCount)
        guard normalizedShownCount > 0 else { return nil }

        let normalizedBlockedCount = max(
            0,
            min(normalizedShownCount, blockedCount)
        )
        let normalizedRecoveryRunCount = max(0, recoveryRunCount)
        let normalizedUnblockRunCount = max(0, unblockRunCount)
        let normalizedRunCount = max(
            0,
            normalizedRecoveryRunCount + normalizedUnblockRunCount
        )
        let blockedRate = Double(normalizedBlockedCount) / Double(max(1, normalizedShownCount))

        let hasNoUnblockCoverage = normalizedUnblockRunCount == 0
        let hasStrongRecoveryBias = normalizedRecoveryRunCount >= 2
            && normalizedUnblockRunCount * 2 < normalizedRecoveryRunCount
        let unblockCoverageIsLow = hasNoUnblockCoverage || hasStrongRecoveryBias

        let thresholds = fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureThresholds(
            shownCount: normalizedShownCount
        )
        let blockedCountThresholdReduction = hasNoUnblockCoverage && normalizedRecoveryRunCount >= 4
            ? 1
            : 0
        let pressureSensitivity = fameMomentumPanelRouteStabilizationRecoverySuggestionPressureSensitivity(
            shownCount: normalizedShownCount,
            blockedRate: blockedRate,
            recoveryRunCount: normalizedRecoveryRunCount,
            unblockRunCount: normalizedUnblockRunCount,
            hasNoUnblockCoverage: hasNoUnblockCoverage
        )
        let sensitivityBlockedCountAdjustment: Int
        let sensitivityBlockedRateAdjustment: Double
        switch pressureSensitivity {
        case .aggressive:
            sensitivityBlockedCountAdjustment = -1
            sensitivityBlockedRateAdjustment = -0.06
        case .balanced:
            sensitivityBlockedCountAdjustment = 0
            sensitivityBlockedRateAdjustment = 0
        case .conservative:
            sensitivityBlockedCountAdjustment = 1
            sensitivityBlockedRateAdjustment = 0.04
        }
        let normalizedPressureCalibration =
            fameMomentumPanelRouteStabilizationRecoverySuggestionNormalizedPressureCalibration(
                pressureCalibration
            )
        let calibrationWeight = min(1, Double(normalizedPressureCalibration.sampleCount) / 10)
        let calibrationBlockedCountAdjustment = Int(
            round(
                Double(
                    normalizedPressureCalibration.biasPoints >= 2
                        ? -1
                        : (normalizedPressureCalibration.biasPoints <= -2 ? 1 : 0)
                ) * calibrationWeight
            )
        )
        let calibrationBlockedRateAdjustment = (
            Double(-normalizedPressureCalibration.biasPoints) * 0.02 * calibrationWeight
        )

        let effectiveMinBlockedCount = max(
            1,
            thresholds.minBlockedCount
                - blockedCountThresholdReduction
                + sensitivityBlockedCountAdjustment
                + calibrationBlockedCountAdjustment
        )
        let blockedRateThresholdReduction = hasNoUnblockCoverage && normalizedRecoveryRunCount >= 3
            ? 0.05
            : 0.0
        let effectiveBlockedRateThreshold = max(
            0.22,
            min(
                0.7,
                thresholds.blockedRateThreshold
                    - blockedRateThresholdReduction
                    + sensitivityBlockedRateAdjustment
                    + calibrationBlockedRateAdjustment
            )
        )
        let hasBlockedPressure = unblockCoverageIsLow
            && normalizedBlockedCount >= effectiveMinBlockedCount
            && blockedRate >= effectiveBlockedRateThreshold

        return FameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureEvaluation(
            normalizedShownCount: normalizedShownCount,
            normalizedBlockedCount: normalizedBlockedCount,
            normalizedRecoveryRunCount: normalizedRecoveryRunCount,
            normalizedUnblockRunCount: normalizedUnblockRunCount,
            normalizedRunCount: normalizedRunCount,
            blockedRate: blockedRate,
            hasNoUnblockCoverage: hasNoUnblockCoverage,
            unblockCoverageIsLow: unblockCoverageIsLow,
            effectiveMinBlockedCount: effectiveMinBlockedCount,
            effectiveBlockedRateThreshold: effectiveBlockedRateThreshold,
            pressureSensitivity: pressureSensitivity,
            calibrationBiasPoints: normalizedPressureCalibration.biasPoints,
            calibrationSampleCount: normalizedPressureCalibration.sampleCount,
            hasBlockedPressure: hasBlockedPressure
        )
    }

    private static func fameMomentumPanelRouteStabilizationRecoverySuggestionNormalizedPressureCalibration(
        _ pressureCalibration: FameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration?
    ) -> (biasPoints: Int, sampleCount: Int) {
        guard let pressureCalibration else {
            return (biasPoints: 0, sampleCount: 0)
        }
        return (
            biasPoints: max(-3, min(3, pressureCalibration.biasPoints)),
            sampleCount: max(0, pressureCalibration.sampleCount)
        )
    }

    private static func fameMomentumPanelRouteStabilizationRecoverySuggestionPressureSensitivity(
        shownCount: Int,
        blockedRate: Double,
        recoveryRunCount: Int,
        unblockRunCount: Int,
        hasNoUnblockCoverage: Bool
    ) -> FameMomentumPanelRouteStabilizationRecoverySuggestionPressureSensitivity {
        let normalizedShownCount = max(1, shownCount)
        let normalizedBlockedRate = max(0, min(1, blockedRate))
        let normalizedRecoveryRunCount = max(0, recoveryRunCount)
        let normalizedUnblockRunCount = max(0, unblockRunCount)
        let recoveryBias = max(0, normalizedRecoveryRunCount - normalizedUnblockRunCount)

        if normalizedShownCount >= 18, normalizedBlockedRate <= 0.20 {
            return .conservative
        }

        if hasNoUnblockCoverage, normalizedRecoveryRunCount >= 4 {
            return .aggressive
        }

        if recoveryBias >= 4, normalizedShownCount <= 8 {
            return .aggressive
        }

        return .balanced
    }

    private static func fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedPressureThresholds(
        shownCount: Int
    ) -> (minBlockedCount: Int, blockedRateThreshold: Double) {
        let normalizedShownCount = max(1, shownCount)
        switch normalizedShownCount {
        case 1...3:
            return (1, 0.5)
        case 4...7:
            return (2, 0.4)
        case 8...12:
            return (3, 0.34)
        default:
            return (
                max(3, Int(round(Double(normalizedShownCount) * 0.24))),
                0.30
            )
        }
    }

    private enum FameMomentumPanelRouteStabilizationRecoverySuggestionPressureSensitivity {
        case aggressive
        case balanced
        case conservative
    }

    private static func launchRecoveryHotKeyReadinessPoints(
        for readiness: LaunchRecoveryHotKeyReadiness
    ) -> Int {
        switch readiness {
        case .direct:
            return 58
        case .reroute:
            return 30
        case .unavailable:
            return 8
        }
    }

    private static func launchRecoveryHotKeyTrendDirectSharePoints(
        for trend: LaunchRecoveryHotKeyTrend?
    ) -> Int {
        guard let trend,
              trend.sampleCount > 0 else {
            return 0
        }
        return Int(round((Double(trend.directCount) / Double(trend.sampleCount)) * 26))
    }

    private static func launchRecoveryHotKeyConfidenceScoreTier(
        for points: Int
    ) -> LaunchRecoveryHotKeyConfidenceScore.Tier {
        let normalizedPoints = max(0, min(100, points))
        if normalizedPoints >= 80 {
            return .prime
        }
        if normalizedPoints >= 58 {
            return .steady
        }
        if normalizedPoints >= 35 {
            return .watch
        }
        return .critical
    }

    private static func launchRecoveryHotKeyConfidenceTierTitle(
        for tier: LaunchRecoveryHotKeyConfidenceScore.Tier
    ) -> String {
        switch tier {
        case .critical:
            return "Critical"
        case .watch:
            return "Watch"
        case .steady:
            return "Steady"
        case .prime:
            return "Prime"
        }
    }

    private static func launchRecoveryHotKeyConfidenceTierSystemImage(
        for tier: LaunchRecoveryHotKeyConfidenceScore.Tier
    ) -> String {
        switch tier {
        case .critical:
            return "xmark.octagon.fill"
        case .watch:
            return "exclamationmark.triangle.fill"
        case .steady:
            return "chart.line.uptrend.xyaxis"
        case .prime:
            return "checkmark.seal.fill"
        }
    }

    private static func launchRecoveryHotKeyConfidenceScoreSubtitle(
        tier: LaunchRecoveryHotKeyConfidenceScore.Tier,
        trend: LaunchRecoveryHotKeyTrend?,
        directStreak: Int,
        bestDirectStreak: Int
    ) -> String {
        switch tier {
        case .critical:
            return "Direct confidence is low. Run a coach step now to re-arm ⌥⇧L direct routing."
        case .watch:
            if let trend,
               trend.standbyCount > trend.rerouteCount {
                return "Standby pressure is rising. Run a coach step to wake direct recovery."
            }
            return "Reroute pressure is rising. Run a coach step to restore direct confidence."
        case .steady:
            return "Direct routing is stable. Keep stacking direct opens (streak x\(directStreak), best x\(bestDirectStreak))."
        case .prime:
            return "Direct routing is locked in (streak x\(directStreak), best x\(bestDirectStreak))."
        }
    }

    fileprivate static func launchRecoveryHotKeyConfidenceTierRank(
        _ tier: LaunchRecoveryHotKeyConfidenceScore.Tier
    ) -> Int {
        switch tier {
        case .critical:
            return 0
        case .watch:
            return 1
        case .steady:
            return 2
        case .prime:
            return 3
        }
    }

    private static func isLaunchRecoveryHotKeyDirect(_ readiness: LaunchRecoveryHotKeyReadiness) -> Bool {
        if case .direct = readiness {
            return true
        }
        return false
    }

    private static func preferredActionIDs(
        for context: CommandPaletteTopPickContext,
        enabledActionIDs: Set<String>,
        enabledActionsByID: [String: CommandPaletteAction]
    ) -> [String] {
        if context.hasError {
            return [
                "copy-troubleshooting-guide",
                "copy-issue-bundle",
                "copy-error-message",
                "copy-support-info",
                "setup-checklist"
            ]
        }

        if context.hasAnswer {
            return [
                "paste-answer",
                "copy-answer",
                "save-answer",
                "copy-answer-quote",
                "ask-anything"
            ]
        }

        if context.hasImage {
            return [
                "ask-anything",
                "copy-last-image",
                "save-last-image",
                "mark-screenshot",
                "pick-and-read"
            ]
        }

        if context.hasText {
            var picks = [
                "read-last-text",
                "copy-last-text",
                "save-text-snippet",
                "copy-text-quote",
                "search-selected-web"
            ]
            if context.llmEnabled {
                picks.insert(contentsOf: ["prompt-summarize", "prompt-actions", "prompt-launch-post", "ask-anything"], at: 0)
            } else {
                picks.insert("ask-anything", at: 0)
            }
            return picks
        }

        return idleStateActionIDsForCurrentState(
            enabledActionIDs: enabledActionIDs,
            enabledActionsByID: enabledActionsByID,
            context: context
        )
    }

    private static func isIdleState(_ context: CommandPaletteTopPickContext) -> Bool {
        !context.hasText && !context.hasAnswer && !context.hasImage && !context.hasError
    }

    private static func idleStateActionIDsForCurrentState(
        enabledActionIDs: Set<String>,
        enabledActionsByID: [String: CommandPaletteAction],
        context: CommandPaletteTopPickContext
    ) -> [String] {
        var ids = idleStateActionIDs

        if context.hasFreshOnboardingRecovery {
            var promotedIDs: [String] = []
            if let followupActionID = context.onboardingRecoveryFollowupActionID,
               enabledActionIDs.contains(followupActionID) {
                promotedIDs.append(followupActionID)
            }
            for actionID in onboardingRecoveryPromotedFallbackActionIDs
                where enabledActionIDs.contains(actionID) && !promotedIDs.contains(actionID) {
                promotedIDs.append(actionID)
            }
            ids = promoteActionIDs(promotedIDs, in: ids, insertionIndex: 0)
        }

        if shouldPromoteBestChannelDraftForLaunchHealth(enabledActionsByID: enabledActionsByID) {
            let promotedIDs = launchHealthRiskWatchPromotedActionIDs.filter { enabledActionIDs.contains($0) }
            if !promotedIDs.isEmpty {
                ids = promoteActionIDs(
                    promotedIDs,
                    in: ids,
                    insertionIndex: launchHealthRiskWatchPromotionInsertionIndex(in: ids)
                )
            }
        }

        guard enabledActionIDs.contains("run-fame-pulse-alert") else {
            return ids
        }

        let insertionIndex = (ids.firstIndex(of: "run-fame-pulse-alert").map { $0 + 1 }) ?? ids.count
        let promotedIDs = pulsePressurePromotedActionIDs.filter { enabledActionIDs.contains($0) }
        ids = promoteActionIDs(promotedIDs, in: ids, insertionIndex: insertionIndex)
        return ids
    }

    private static func promoteActionIDs(
        _ promotedIDs: [String],
        in ids: [String],
        insertionIndex: Int
    ) -> [String] {
        var result = ids
        var seenPromotedIDs = Set<String>()
        let uniquePromotedIDs = promotedIDs.filter { seenPromotedIDs.insert($0).inserted }

        for id in uniquePromotedIDs {
            if let existingIndex = result.firstIndex(of: id) {
                result.remove(at: existingIndex)
            }
        }

        let normalizedInsertionIndex = max(0, min(result.count, insertionIndex))
        result.insert(contentsOf: uniquePromotedIDs, at: normalizedInsertionIndex)
        return result
    }

    private static func shouldPromoteBestChannelDraftForLaunchHealth(
        enabledActionsByID: [String: CommandPaletteAction]
    ) -> Bool {
        guard let launchHealthAction = enabledActionsByID["run-fame-launch-control-health"] else {
            return false
        }

        let normalizedTitle = launchHealthAction.title.lowercased()
        return normalizedTitle.contains("launch health: risk")
            || normalizedTitle.contains("launch health: watch")
    }

    static func bestChannelLaunchPackPressureCard(
        launchPackAction: CommandPaletteAction?,
        pulseAlertAction: CommandPaletteAction?,
        launchHealthAction: CommandPaletteAction?,
        launchAlertAction: CommandPaletteAction?,
        momentumPulse: LaunchRecoveryHotKeyMomentumPulse?,
        opportunities: Int = 0,
        conversions: Int = 0,
        streak: Int = 0,
        bestStreak: Int = 0,
        modeTransitionCount: Int = 0,
        modeTransitionLatestToken: String? = nil,
        modeMomentumStreak: Int = 0
    ) -> BestChannelLaunchPackPressureCard? {
        guard let launchPackAction, launchPackAction.isEnabled else { return nil }

        let actionSignalTones = [pulseAlertAction, launchHealthAction, launchAlertAction]
            .compactMap(launchPressureTone(for:))
        let tone: BestChannelLaunchPackPressureTone?

        if actionSignalTones.contains(.alert) || momentumPulse?.tone == .falling {
            tone = .alert
        } else if actionSignalTones.contains(.watch) {
            tone = .watch
        } else {
            tone = nil
        }

        guard let tone else { return nil }
        let trend = bestChannelLaunchPackPressureTrend(
            opportunities: opportunities,
            conversions: conversions,
            streak: streak,
            bestStreak: bestStreak
        )
        let helpText = bestChannelLaunchPackPressureCardHelpText(
            tone: tone,
            trend: trend,
            actionTitle: launchPackAction.title,
            opportunities: opportunities,
            conversions: conversions,
            streak: streak,
            bestStreak: bestStreak,
            modeTransitionCount: modeTransitionCount,
            modeTransitionLatestToken: modeTransitionLatestToken,
            modeMomentumStreak: modeMomentumStreak
        )

        switch tone {
        case .alert:
            return BestChannelLaunchPackPressureCard(
                tone: .alert,
                title: "Launch Pressure: Ship Best Channel",
                subtitle: "One tap copies your best-channel post + launch pack.",
                systemImage: "bolt.trianglebadge.exclamationmark",
                helpText: helpText,
                actionID: launchPackAction.id
            )
        case .watch:
            return BestChannelLaunchPackPressureCard(
                tone: .watch,
                title: "Launch Pressure Watch: Stage Best Channel",
                subtitle: "Queue your best-channel launch pack now so it is ready to ship.",
                systemImage: "eye.trianglebadge.exclamationmark",
                helpText: helpText,
                actionID: launchPackAction.id
            )
        }
    }

    static func bestChannelLaunchPackPressureCardHelpText(
        tone: BestChannelLaunchPackPressureTone,
        trend: BestChannelLaunchPackPressureTrend,
        actionTitle: String,
        opportunities: Int,
        conversions: Int,
        streak: Int,
        bestStreak: Int,
        modeTransitionCount: Int = 0,
        modeTransitionLatestToken: String? = nil,
        modeMomentumStreak: Int = 0
    ) -> String {
        let baseGuidance: String = switch (tone, trend) {
        case (.alert, .compounding):
            "High launch pressure and compounding momentum. Run \(actionTitle) now to lock this window."
        case (.alert, .rebuilding):
            "High launch pressure with rebuilding momentum. Run \(actionTitle) now to lock recovery."
        case (.alert, .cooling), (.alert, .noWins), (.alert, .noOpportunities):
            "High launch pressure detected. Run \(actionTitle) now to stop streak erosion."
        case (.watch, .compounding):
            "Launch pressure is elevated while momentum compounds. Run \(actionTitle) now to keep launch copy warm."
        case (.watch, .rebuilding):
            "Launch pressure is elevated and rebuilding. Run \(actionTitle) now to keep recovery on track."
        case (.watch, .cooling), (.watch, .noWins), (.watch, .noOpportunities):
            "Launch pressure is elevated. Run \(actionTitle) now so recovery copy is staged."
        }
        let modeShiftGuidance = bestChannelLaunchPackPressureModeShiftGuidance(
            transitionCount: modeTransitionCount,
            latestToken: modeTransitionLatestToken,
            modeMomentumStreak: modeMomentumStreak
        )
        let performanceLine = bestChannelLaunchPackPressurePerformanceLine(
            opportunities: opportunities,
            conversions: conversions,
            streak: streak,
            bestStreak: bestStreak
        )

        return [baseGuidance, modeShiftGuidance, performanceLine]
            .compactMap { line in
                let trimmed = line?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }
            .joined(separator: " ")
    }

    static func bestChannelLaunchPackPressureTrend(
        opportunities: Int,
        conversions: Int,
        streak: Int,
        bestStreak: Int
    ) -> BestChannelLaunchPackPressureTrend {
        let normalizedOpportunities = max(0, opportunities)
        let normalizedConversions = min(
            normalizedOpportunities,
            max(0, conversions)
        )
        let normalizedStreak = min(
            normalizedConversions,
            max(0, streak)
        )
        let normalizedBestStreak = max(
            normalizedStreak,
            max(0, bestStreak)
        )

        if normalizedOpportunities == 0 {
            return .noOpportunities
        }
        if normalizedConversions == 0 {
            return .noWins
        }
        if normalizedStreak == 0 {
            return .cooling
        }
        if normalizedStreak >= normalizedBestStreak {
            return .compounding
        }
        return .rebuilding
    }

    static func bestChannelLaunchPackPressureModeTransition(
        previousTrend: BestChannelLaunchPackPressureTrend?,
        trend: BestChannelLaunchPackPressureTrend
    ) -> BestChannelLaunchPackPressureModeTransition? {
        guard let previousTrend, previousTrend != trend else { return nil }
        return BestChannelLaunchPackPressureModeTransition(
            previousTrend: previousTrend,
            trend: trend
        )
    }

    static func bestChannelLaunchPackPressurePriorityPromotedActionIDs(
        card: BestChannelLaunchPackPressureCard?,
        opportunities: Int,
        conversions: Int,
        streak: Int,
        bestStreak: Int,
        enabledActionIDs: Set<String>,
        modeTransitionCount: Int = 0,
        modeTransitionLatestToken: String? = nil,
        modeMomentumStreak: Int = 0
    ) -> [String] {
        guard let card else { return [] }
        guard enabledActionIDs.contains(card.actionID) else { return [] }

        let trend = bestChannelLaunchPackPressureTrend(
            opportunities: opportunities,
            conversions: conversions,
            streak: streak,
            bestStreak: bestStreak
        )
        let draftActionID = "copy-next-move-best-channel-draft"
        let cadenceActionID = "run-fame-cadence-autopilot-loop"

        var promotedActionIDs = [card.actionID]
        switch trend {
        case .compounding:
            if card.tone == .watch {
                promotedActionIDs = []
            }
        case .rebuilding:
            if card.tone == .watch, enabledActionIDs.contains(draftActionID) {
                promotedActionIDs.append(draftActionID)
            }
        case .noOpportunities, .noWins, .cooling:
            if enabledActionIDs.contains(draftActionID) {
                promotedActionIDs.append(draftActionID)
            } else if enabledActionIDs.contains(cadenceActionID) {
                promotedActionIDs.append(cadenceActionID)
            }
        }
        let trajectoryBias = bestChannelLaunchPackPressureModeTrajectoryBias(
            transitionCount: modeTransitionCount,
            latestToken: modeTransitionLatestToken,
            modeMomentumStreak: modeMomentumStreak
        )
        switch trajectoryBias {
        case .momentumUpshift:
            if promotedActionIDs.isEmpty {
                promotedActionIDs.append(card.actionID)
            }
            if enabledActionIDs.contains(cadenceActionID) {
                promotedActionIDs.append(cadenceActionID)
            }
        case .recoveryUpshift:
            if promotedActionIDs.isEmpty {
                promotedActionIDs.append(card.actionID)
            }
            if enabledActionIDs.contains(draftActionID) {
                promotedActionIDs.append(draftActionID)
            }
            if enabledActionIDs.contains(cadenceActionID) {
                promotedActionIDs.append(cadenceActionID)
            }
        case .coolingDownshift:
            promotedActionIDs = [card.actionID]
            if enabledActionIDs.contains(cadenceActionID) {
                promotedActionIDs.append(cadenceActionID)
            }
            if enabledActionIDs.contains(draftActionID) {
                promotedActionIDs.append(draftActionID)
            }
        case .none:
            break
        }

        var uniqueActionIDs: [String] = []
        var seenActionIDs = Set<String>()
        for actionID in promotedActionIDs where seenActionIDs.insert(actionID).inserted {
            uniqueActionIDs.append(actionID)
        }
        return uniqueActionIDs
    }

    static func bestChannelLaunchPackPressureBadgeTitle(
        opportunities: Int,
        conversions: Int,
        streak: Int
    ) -> String? {
        let normalizedOpportunities = max(0, opportunities)
        let normalizedConversions = max(0, min(normalizedOpportunities, conversions))
        let normalizedStreak = max(0, streak)
        guard normalizedOpportunities > 0 else { return nil }

        let winRate = Int(
            (Double(normalizedConversions) / Double(normalizedOpportunities) * 100).rounded()
        )
        if normalizedStreak > 0 {
            return "Launch Pack \(winRate)% · x\(normalizedStreak)"
        }
        return "Launch Pack \(winRate)%"
    }

    static func bestChannelLaunchPackPressureBadgeSystemImage(
        tone: BestChannelLaunchPackPressureTone?
    ) -> String {
        switch tone {
        case .alert:
            return "bolt.trianglebadge.exclamationmark"
        case .watch:
            return "eye.trianglebadge.exclamationmark"
        case nil:
            return "star.bubble"
        }
    }

    static func bestChannelLaunchPackPressureModeBadgeTitle(
        trend: BestChannelLaunchPackPressureTrend
    ) -> String? {
        switch trend {
        case .compounding:
            return "Pressure Mode: Compounding"
        case .rebuilding:
            return "Pressure Mode: Rebuilding"
        case .cooling:
            return "Pressure Mode: Cooling"
        case .noOpportunities, .noWins:
            return nil
        }
    }

    static func bestChannelLaunchPackPressureModeBadgeSystemImage(
        trend: BestChannelLaunchPackPressureTrend
    ) -> String {
        switch trend {
        case .compounding:
            return "arrow.up.right.circle.fill"
        case .rebuilding:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .cooling:
            return "snowflake.circle.fill"
        case .noOpportunities, .noWins:
            return "circle.dashed"
        }
    }

    static func bestChannelLaunchPackPressureModeBadgeHelpText(
        trend: BestChannelLaunchPackPressureTrend,
        opportunities: Int,
        conversions: Int,
        streak: Int,
        bestStreak: Int
    ) -> String {
        let performanceLine = bestChannelLaunchPackPressurePerformanceLine(
            opportunities: opportunities,
            conversions: conversions,
            streak: streak,
            bestStreak: bestStreak
        )
        let guidance: String = switch trend {
        case .compounding:
            "Conversions are matching your best streak. Keep shipping the best channel while momentum is compounding."
        case .rebuilding:
            "Wins are recovering but still below your best streak. Pair draft prep with launch-pack execution to close the gap."
        case .cooling:
            "Latest pressure cycle cooled off after a miss. Relaunch the best channel now to restart streak momentum."
        case .noOpportunities:
            "No pressure opportunities logged yet. First launch-pack run sets the baseline."
        case .noWins:
            "Pressure opportunities logged but no conversions yet. Push one launch-pack win to start streak momentum."
        }
        return "\(guidance) \(performanceLine)"
    }

    static func bestChannelLaunchPackGuidanceButtonTitle(
        trend: BestChannelLaunchPackPressureTrend,
        tone: BestChannelLaunchPackPressureTone
    ) -> String {
        switch trend {
        case .compounding:
            return tone == .alert ? "Ship Momentum" : "Keep Momentum"
        case .rebuilding:
            return "Rebuild Streak"
        case .cooling:
            return "Restart Streak"
        case .noOpportunities, .noWins:
            return "Start Streak"
        }
    }

    static func bestChannelLaunchPackPressurePerformanceLine(
        opportunities: Int,
        conversions: Int,
        streak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedOpportunities = max(0, opportunities)
        let normalizedConversions = max(0, min(normalizedOpportunities, conversions))
        let normalizedStreak = max(0, streak)
        let normalizedBestStreak = max(normalizedStreak, max(0, bestStreak))

        if normalizedOpportunities == 0 {
            return "No pressure runs yet · first clutch run starts streak."
        }

        let winRate = Int(
            (Double(normalizedConversions) / Double(normalizedOpportunities) * 100).rounded()
        )
        if normalizedConversions == 0 {
            return "\(winRate)% win rate · first clutch run starts streak."
        }

        return "\(winRate)% win rate · streak x\(normalizedStreak) · best x\(normalizedBestStreak)"
    }

    private static func bestChannelLaunchPackPressureModeShiftGuidance(
        transitionCount: Int,
        latestToken: String?,
        modeMomentumStreak: Int = 0
    ) -> String? {
        guard transitionCount > 0 else { return nil }
        let momentumLine = bestChannelLaunchPackPressureModeMomentumLine(modeMomentumStreak)
        guard let modeShift = bestChannelLaunchPackPressureModeShiftSnapshot(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) else {
            var fallback = "Mode shifts tracked (\(transitionCount) total); stack two focused launch-pack wins to steady cadence."
            if let momentumLine {
                fallback += " \(momentumLine)"
            }
            return fallback
        }

        let modeLine = "Latest mode shift \(modeShift.fromTitle) -> \(modeShift.toTitle)."
        let guidance: String = switch (modeShift.fromToken, modeShift.toToken) {
        case ("cooling", "rebuilding"), ("no-wins", "rebuilding"), ("none", "rebuilding"):
            "One more win can restore compounding pace."
        case ("rebuilding", "compounding"), ("cooling", "compounding"), ("no-wins", "compounding"):
            "Protect this upswing with immediate shipping."
        case ("compounding", "cooling"), ("rebuilding", "cooling"):
            "Respond quickly to prevent deeper slide."
        case (_, "compounding"):
            "Keep momentum compounding with back-to-back launches."
        case (_, "rebuilding"):
            "Keep pressure on until the rebuild stabilizes."
        case (_, "cooling"):
            "Treat this window like recovery sprint mode."
        case (_, "no-wins"), (_, "none"):
            "Prioritize one clean win to restart streak momentum."
        default:
            "Keep launch cadence tight while mode shifts settle."
        }
        var summary = "\(modeLine) \(guidance)"
        if let momentumLine {
            summary += " \(momentumLine)"
        }
        return summary
    }

    private static func bestChannelLaunchPackPressureModeShiftSnapshot(
        transitionCount: Int,
        latestToken: String?
    ) -> BestChannelLaunchPackPressureModeShiftSnapshot? {
        guard transitionCount > 0 else { return nil }
        let normalizedLatestToken = latestToken?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
        let parts = normalizedLatestToken.components(separatedBy: "-to-")
        guard parts.count == 2 else { return nil }
        let fromToken = parts[0]
        let toToken = parts[1]
        return BestChannelLaunchPackPressureModeShiftSnapshot(
            fromToken: fromToken,
            toToken: toToken,
            fromTitle: bestChannelLaunchPackPressureTrendTitle(fromToken),
            toTitle: bestChannelLaunchPackPressureTrendTitle(toToken)
        )
    }

    private static func bestChannelLaunchPackPressureModeTrajectoryBias(
        transitionCount: Int,
        latestToken: String?,
        modeMomentumStreak: Int = 0
    ) -> BestChannelLaunchPackPressureModeTrajectoryBias {
        let tokenBias: BestChannelLaunchPackPressureModeTrajectoryBias
        if let modeShift = bestChannelLaunchPackPressureModeShiftSnapshot(
            transitionCount: transitionCount,
            latestToken: latestToken
        ) {
            switch (modeShift.fromToken, modeShift.toToken) {
            case ("rebuilding", "compounding"), ("cooling", "compounding"), ("no-wins", "compounding"):
                tokenBias = .momentumUpshift
            case ("cooling", "rebuilding"), ("no-wins", "rebuilding"), ("none", "rebuilding"):
                tokenBias = .recoveryUpshift
            case ("compounding", "cooling"), ("rebuilding", "cooling"):
                tokenBias = .coolingDownshift
            default:
                tokenBias = .none
            }
        } else {
            tokenBias = .none
        }

        if tokenBias != .none {
            return tokenBias
        }
        if modeMomentumStreak >= 2 {
            return .momentumUpshift
        }
        if modeMomentumStreak <= -2 {
            return .coolingDownshift
        }
        return .none
    }

    private static func bestChannelLaunchPackPressureModeMomentumLine(
        _ modeMomentumStreak: Int
    ) -> String? {
        if modeMomentumStreak >= 2 {
            return "Mode momentum is rising (upshift streak x\(modeMomentumStreak))."
        }
        if modeMomentumStreak <= -2 {
            return "Mode momentum is cooling (cooldown streak x\(abs(modeMomentumStreak)))."
        }
        return nil
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

    private static func launchPressureTone(
        for action: CommandPaletteAction?
    ) -> BestChannelLaunchPackPressureTone? {
        guard let action, action.isEnabled else { return nil }

        let normalizedText = "\(action.title) \(action.subtitle)".lowercased()
        let alertKeywords = [
            "must ship",
            "critical",
            "urgency high",
            "risk",
            "overdue",
            "launch alert"
        ]

        if alertKeywords.contains(where: { normalizedText.contains($0) }) {
            return .alert
        }

        if normalizedText.contains("watch") {
            return .watch
        }

        return nil
    }

    private static func launchHealthRiskWatchPromotionInsertionIndex(in ids: [String]) -> Int {
        if let healthIndex = ids.firstIndex(of: "run-fame-launch-control-health") {
            return healthIndex + 1
        }
        if let launchAlertIndex = ids.firstIndex(of: "run-fame-launch-alert") {
            return launchAlertIndex + 1
        }
        return 0
    }

    private static func compareByUsage(
        lhs: CommandPaletteAction,
        rhs: CommandPaletteAction,
        usageRecords: [String: CommandUsageRecord],
        actionOrder: [String: Int]
    ) -> Bool {
        let lhsCount = usageRecords[lhs.id]?.useCount ?? 0
        let rhsCount = usageRecords[rhs.id]?.useCount ?? 0
        if lhsCount != rhsCount {
            return lhsCount > rhsCount
        }

        let lhsUsedAt = usageRecords[lhs.id]?.lastUsedAt ?? .distantPast
        let rhsUsedAt = usageRecords[rhs.id]?.lastUsedAt ?? .distantPast
        if lhsUsedAt != rhsUsedAt {
            return lhsUsedAt > rhsUsedAt
        }

        return (actionOrder[lhs.id] ?? Int.max) < (actionOrder[rhs.id] ?? Int.max)
    }
}

struct CommandPaletteAction: Identifiable {
    nonisolated static let launchRecoveryNextActionID = "run-fame-launch-recovery-next"
    nonisolated static let autoOpsBundleStatusActionID = "run-fame-auto-bundle-status"
    nonisolated static let launchRescueAutoStatusActionID = "run-fame-launch-rescue-burst-auto-status"

    struct SecondaryAction: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let systemImage: String
        let isEnabled: Bool
        let disabledReason: String
        let closesPaletteAfterRun: Bool
        let closesPanelAfterRun: Bool
        let run: () -> Void

        init(
            id: String,
            title: String,
            subtitle: String = "",
            systemImage: String,
            isEnabled: Bool = true,
            disabledReason: String = "Not ready",
            closesPaletteAfterRun: Bool = true,
            closesPanelAfterRun: Bool = true,
            run: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.subtitle = subtitle.isEmpty ? title : subtitle
            self.systemImage = systemImage
            self.isEnabled = isEnabled
            self.disabledReason = disabledReason
            self.closesPaletteAfterRun = closesPaletteAfterRun
            self.closesPanelAfterRun = closesPanelAfterRun
            self.run = run
        }
    }

    enum SourceKind: Equatable, Hashable {
        case command
        case ask
        case app
        case file
        case folder
        case script
        case link
        case clipboard
        case path
        case web
        case math
        case unit
        case color
        case date
        case snippet
        case recent

        var badgeTitle: String? {
            switch self {
            case .command:
                return nil
            case .ask:
                return "Ask"
            case .app:
                return "App"
            case .file:
                return "File"
            case .folder:
                return "Folder"
            case .script:
                return "Script"
            case .link:
                return "Link"
            case .clipboard:
                return "Clipboard"
            case .path:
                return "Path"
            case .web:
                return "Web"
            case .math:
                return "Math"
            case .unit:
                return "Unit"
            case .color:
                return "Color"
            case .date:
                return "Date"
            case .snippet:
                return "Snippet"
            case .recent:
                return "Recent"
            }
        }

        var helpText: String? {
            switch self {
            case .command:
                return nil
            case .ask:
                return "Inline question for the current reader context."
            case .app:
                return "Installed app matched from root search."
            case .file:
                return "Indexed local file matched from root search."
            case .folder:
                return "Common folder matched from root search."
            case .script:
                return "User script command loaded from the Script Commands folder."
            case .link:
                return "Saved quick link matched from root search."
            case .clipboard:
                return "Clipboard history item matched from root search."
            case .path:
                return "Existing local path matched from root search."
            case .web:
                return "Web or URL result matched from root search."
            case .math:
                return "Inline calculator result."
            case .unit:
                return "Inline conversion result."
            case .color:
                return "Inline color conversion result."
            case .date:
                return "Inline date or timezone result."
            case .snippet:
                return "Saved note or snippet matched from root search."
            case .recent:
                return "Recent reader item matched from root search."
            }
        }
    }

    struct SignalBadge: Equatable {
        enum Tone: String, Equatable {
            case low
            case medium
            case high
        }

        let title: String
        let tone: Tone
        let helpText: String
        let recommendedActionID: String?
        let recommendedActionTitle: String?

        init(
            title: String,
            tone: Tone,
            helpText: String,
            recommendedActionID: String? = nil,
            recommendedActionTitle: String? = nil
        ) {
            self.title = title
            self.tone = tone
            self.helpText = helpText
            self.recommendedActionID = recommendedActionID
            self.recommendedActionTitle = recommendedActionTitle
        }
    }

    struct RecommendationMomentumBadge: Equatable {
        enum Tone: String, Equatable {
            case hot
            case warm
            case cooling
            case cold
        }

        let title: String
        let tone: Tone
        let helpText: String
    }

    struct RecommendationMomentumRescueCue: Equatable {
        let title: String
        let systemImage: String
        let helpText: String
    }

    struct RecommendationPanelModel: Equatable {
        let title: String
        let actionID: String
        let actionTitle: String
        let badgeTitle: String
        let tone: SignalBadge.Tone
        let detail: String
        let recommendedActionID: String?
        let recommendedActionTitle: String?
    }

    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let group: CommandPaletteGroup?
    let sourceKind: SourceKind
    let keywords: [String]
    let signalBadge: SignalBadge?
    let isEnabled: Bool
    let disabledReason: String
    let canFavorite: Bool
    let aliasBadgeTitle: String?
    let aliasHelpText: String?
    let hotKeyBadgeTitle: String?
    let hotKeyHelpText: String?
    let secondaryActions: [SecondaryAction]
    let run: () -> Void

    init(
        id: String,
        title: String,
        subtitle: String = "",
        systemImage: String,
        group: CommandPaletteGroup? = nil,
        sourceKind: SourceKind = .command,
        keywords: [String] = [],
        signalBadge: SignalBadge? = nil,
        isEnabled: Bool = true,
        disabledReason: String = "Not ready",
        canFavorite: Bool = true,
        aliasBadgeTitle: String? = nil,
        aliasHelpText: String? = nil,
        hotKeyBadgeTitle: String? = nil,
        hotKeyHelpText: String? = nil,
        secondaryActions: [SecondaryAction] = [],
        run: @escaping () -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle.isEmpty ? title : subtitle
        self.systemImage = systemImage
        self.group = group
        self.sourceKind = sourceKind
        self.keywords = keywords
        self.signalBadge = signalBadge
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
        self.canFavorite = canFavorite
        self.aliasBadgeTitle = aliasBadgeTitle
        self.aliasHelpText = aliasHelpText
        self.hotKeyBadgeTitle = hotKeyBadgeTitle
        self.hotKeyHelpText = hotKeyHelpText
        self.secondaryActions = secondaryActions
        self.run = run
    }

    nonisolated static func dedicatedShortcutBadgeTitle(for actionID: String) -> String? {
        switch actionID {
        case launchRecoveryNextActionID:
            return "⌥⌘R"
        case autoOpsBundleStatusActionID:
            return "⌥⌘O"
        case launchRescueAutoStatusActionID:
            return "⌥⌘L"
        default:
            return nil
        }
    }

    nonisolated static func recommendationPanelModel(
        for action: CommandPaletteAction?
    ) -> RecommendationPanelModel? {
        guard let action,
              let signalBadge = action.signalBadge else {
            return nil
        }
        let detail = signalBadge.helpText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return nil }
        let normalizedRecommendedActionID = signalBadge.recommendedActionID?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRecommendedActionTitle = signalBadge.recommendedActionTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return RecommendationPanelModel(
            title: "Why this recommendation",
            actionID: action.id,
            actionTitle: action.title,
            badgeTitle: signalBadge.title,
            tone: signalBadge.tone,
            detail: detail,
            recommendedActionID: normalizedRecommendedActionID?.isEmpty == false
                ? normalizedRecommendedActionID
                : nil,
            recommendedActionTitle: normalizedRecommendedActionTitle?.isEmpty == false
                ? normalizedRecommendedActionTitle
                : nil
        )
    }

    nonisolated static func recommendationConversionSignalLine(
        opportunities: Int,
        conversionCount: Int,
        openStreak: Int,
        bestOpenStreak: Int
    ) -> String? {
        let normalizedOpportunities = max(0, opportunities)
        guard normalizedOpportunities > 0 else { return nil }
        let normalizedConversionCount = min(
            normalizedOpportunities,
            max(0, conversionCount)
        )
        let conversionRate = Int(
            (Double(normalizedConversionCount) / Double(normalizedOpportunities) * 100).rounded()
        )
        let confidenceTitle = recommendationConversionConfidenceTitle(
            opportunities: normalizedOpportunities,
            conversionCount: normalizedConversionCount
        )
        let normalizedOpenStreak = max(0, openStreak)
        let normalizedBestOpenStreak = max(normalizedOpenStreak, bestOpenStreak)
        return "Recommendation proof \(confidenceTitle) · \(normalizedConversionCount)/\(normalizedOpportunities) (\(conversionRate)%) · streak x\(normalizedOpenStreak) · best x\(normalizedBestOpenStreak)"
    }

    nonisolated static func recommendationPairSignalLine(
        opportunities: Int,
        conversionCount: Int
    ) -> String? {
        let normalizedOpportunities = max(0, opportunities)
        guard normalizedOpportunities > 0 else { return nil }
        let normalizedConversionCount = min(
            normalizedOpportunities,
            max(0, conversionCount)
        )
        let conversionRate = Int(
            (Double(normalizedConversionCount) / Double(normalizedOpportunities) * 100).rounded()
        )
        let confidenceTitle = recommendationConversionConfidenceTitle(
            opportunities: normalizedOpportunities,
            conversionCount: normalizedConversionCount
        )
        return "This recommendation \(confidenceTitle) proof · \(normalizedConversionCount)/\(normalizedOpportunities) (\(conversionRate)%)"
    }

    nonisolated static func recommendationPairMomentumLine(
        opensSinceLastConversion: Int?
    ) -> String? {
        guard let snapshot = recommendationPairMomentumSnapshot(
            opensSinceLastConversion: opensSinceLastConversion
        ) else {
            return nil
        }
        return "Recommendation momentum \(snapshot.title) · \(snapshot.detail)"
    }

    nonisolated static func recommendationPairMomentumBadge(
        opensSinceLastConversion: Int?
    ) -> RecommendationMomentumBadge? {
        guard let snapshot = recommendationPairMomentumSnapshot(
            opensSinceLastConversion: opensSinceLastConversion
        ) else {
            return nil
        }
        let momentumGuidance: String
        switch snapshot.tone {
        case .hot:
            momentumGuidance = "Recent recommendation wins are compounding."
        case .warm:
            momentumGuidance = "Recommendation momentum is still active."
        case .cooling:
            momentumGuidance = "Recommendation momentum is cooling; refresh with a quick win."
        case .cold:
            momentumGuidance = "Recommendation momentum is stale; force a fresh conversion."
        }
        return RecommendationMomentumBadge(
            title: "Momentum \(snapshot.title)",
            tone: snapshot.tone,
            helpText: "\(momentumGuidance) Latest signal: \(snapshot.detail)."
        )
    }

    nonisolated static func recommendationPairMomentumRescueCue(
        opensSinceLastConversion: Int?,
        opportunities: Int,
        conversionCount: Int,
        minimumHighConfidenceOpportunities: Int = 5
    ) -> RecommendationMomentumRescueCue? {
        guard CommandPaletteTopPicks.recommendationPairIsHighConfidence(
            opportunities: opportunities,
            conversionCount: conversionCount,
            minimumHighConfidenceOpportunities: minimumHighConfidenceOpportunities
        ),
            let snapshot = recommendationPairMomentumSnapshot(
                opensSinceLastConversion: opensSinceLastConversion
            ),
            snapshot.tone == .cold else {
            return nil
        }
        let normalizedOpportunities = max(0, opportunities)
        let normalizedConversionCount = min(
            normalizedOpportunities,
            max(0, conversionCount)
        )
        return RecommendationMomentumRescueCue(
            title: "Momentum Rescue Ready",
            systemImage: "bolt.badge.clock",
            helpText: "High-trust recommendation is cold (\(normalizedConversionCount)/\(normalizedOpportunities)). Latest signal: \(snapshot.detail). Run the recommended action now to restart momentum."
        )
    }

    nonisolated static func recommendationMomentumRescueSignalLine(
        currentStreak: Int,
        bestStreak: Int
    ) -> String? {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(
            normalizedCurrentStreak,
            max(0, bestStreak)
        )
        guard normalizedCurrentStreak > 0 || normalizedBestStreak > 0 else { return nil }

        if normalizedCurrentStreak == 0 {
            let bestTier = recommendationMomentumRescueTier(for: normalizedBestStreak)
            return "Rescue lane cooling · best x\(normalizedBestStreak) (\(bestTier.title)). Land one rescue to restart momentum."
        }

        let currentTier = recommendationMomentumRescueTier(for: normalizedCurrentStreak)
        if let nextTierTitle = currentTier.nextTierTitle,
           let nextTierThreshold = currentTier.nextTierThreshold {
            return "Rescue lane \(currentTier.title) · run x\(normalizedCurrentStreak) · best x\(normalizedBestStreak) · next \(nextTierTitle) at x\(nextTierThreshold)"
        }
        return "Rescue lane \(currentTier.title) · run x\(normalizedCurrentStreak) · best x\(normalizedBestStreak) · legend pace locked"
    }

    nonisolated static func shouldCelebrateRecommendationMomentumTransition(
        previousTone: RecommendationMomentumBadge.Tone?,
        nextTone: RecommendationMomentumBadge.Tone
    ) -> Bool {
        guard let previousTone else { return false }
        return recommendationMomentumToneRank(nextTone) > recommendationMomentumToneRank(previousTone)
    }

    nonisolated static func recommendationConversionConfidenceTitle(
        opportunities: Int,
        conversionCount: Int
    ) -> String {
        let normalizedOpportunities = max(0, opportunities)
        guard normalizedOpportunities > 0 else { return "Calibrating" }
        let normalizedConversionCount = min(
            normalizedOpportunities,
            max(0, conversionCount)
        )
        guard normalizedOpportunities >= 3 else { return "Calibrating" }
        let conversionRate = Double(normalizedConversionCount) / Double(normalizedOpportunities)
        switch conversionRate {
        case 0.7...:
            return "High"
        case 0.4...:
            return "Medium"
        default:
            return "Low"
        }
    }

    private static func recommendationPairMomentumSnapshot(
        opensSinceLastConversion: Int?
    ) -> (
        title: String,
        tone: RecommendationMomentumBadge.Tone,
        detail: String
    )? {
        guard let opensSinceLastConversion else { return nil }
        let normalizedOpensSinceLastConversion = max(0, opensSinceLastConversion)
        if normalizedOpensSinceLastConversion == 0 {
            return (
                title: "Hot",
                tone: .hot,
                detail: "converted this open"
            )
        }

        let openNoun = normalizedOpensSinceLastConversion == 1 ? "open" : "opens"
        let detail = "last win \(normalizedOpensSinceLastConversion) \(openNoun) ago"
        switch normalizedOpensSinceLastConversion {
        case 1:
            return (title: "Hot", tone: .hot, detail: detail)
        case 2...3:
            return (title: "Warm", tone: .warm, detail: detail)
        case 4...6:
            return (title: "Cooling", tone: .cooling, detail: detail)
        default:
            return (title: "Cold", tone: .cold, detail: detail)
        }
    }

    private static func recommendationMomentumToneRank(
        _ tone: RecommendationMomentumBadge.Tone
    ) -> Int {
        switch tone {
        case .cold:
            return 0
        case .cooling:
            return 1
        case .warm:
            return 2
        case .hot:
            return 3
        }
    }

    private static func recommendationMomentumRescueTier(
        for streak: Int
    ) -> (
        title: String,
        systemImage: String,
        nextTierTitle: String?,
        nextTierThreshold: Int?
    ) {
        let normalizedStreak = max(1, streak)
        switch normalizedStreak {
        case ...2:
            return (
                title: "Spark",
                systemImage: "bolt.badge.clock",
                nextTierTitle: "Breakout",
                nextTierThreshold: 3
            )
        case ...4:
            return (
                title: "Breakout",
                systemImage: "sparkles",
                nextTierTitle: "Fame",
                nextTierThreshold: 5
            )
        case ...7:
            return (
                title: "Fame",
                systemImage: "flame.fill",
                nextTierTitle: "Legend",
                nextTierThreshold: 8
            )
        default:
            return (
                title: "Legend",
                systemImage: "crown.fill",
                nextTierTitle: nil,
                nextTierThreshold: nil
            )
        }
    }

    func matches(_ query: String) -> Bool {
        let terms = Self.searchTerms(from: query)
        return matchScore(terms: terms) != nil
    }

    var resolvedGroup: CommandPaletteGroup {
        group ?? CommandPaletteGroup.classify(
            actionID: id,
            title: title,
            subtitle: subtitle,
            keywords: keywords
        )
    }

    func matchScore(terms: [String]) -> Int? {
        guard !terms.isEmpty else { return 0 }

        var fields = [(title, 30), (subtitle, 12), (id, 6)] + keywords.map { ($0, 0) }
        fields.append((resolvedGroup.title, 3))
        if !isEnabled {
            fields.append((disabledReason, 4))
        }
        var totalScore = 0

        for term in terms {
            let bestScore = fields.compactMap { field, weight -> Int? in
                guard let score = Self.score(term: term, in: field) else { return nil }
                return score + weight
            }.max()
            guard let bestScore else { return nil }
            totalScore += bestScore
        }

        return totalScore
    }

    static func filter(
        _ actions: [CommandPaletteAction],
        query: String,
        usageRecords: [String: CommandUsageRecord] = [:],
        favoriteActionIDs: Set<String> = [],
        requiredGroup: CommandPaletteGroup? = nil,
        requiredSourceKinds: Set<SourceKind>? = nil,
        priorityActionIDs: Set<String> = [],
        preferredSourceKinds: Set<SourceKind> = []
    ) -> [CommandPaletteAction] {
        let terms = searchTerms(from: query)
        let matchedActions = actions.enumerated().compactMap { index, action -> RankedCommandAction? in
            guard let matchScore = action.matchScore(terms: terms) else { return nil }
            return RankedCommandAction(
                index: index,
                action: action,
                matchScore: matchScore,
                priorityBoost: searchPriorityBoost(
                    for: action,
                    priorityActionIDs: priorityActionIDs,
                    preferredSourceKinds: preferredSourceKinds,
                    termCount: terms.count
                )
            )
        }

        return matchedActions
            .sorted { lhs, rhs in
                if lhs.action.isEnabled != rhs.action.isEnabled {
                    return lhs.action.isEnabled
                }

                let lhsIsFavorite = favoriteActionIDs.contains(lhs.action.id) && lhs.action.canFavorite
                let rhsIsFavorite = favoriteActionIDs.contains(rhs.action.id) && rhs.action.canFavorite
                if terms.isEmpty && lhsIsFavorite != rhsIsFavorite {
                    return lhsIsFavorite
                }

                let lhsEffectiveMatchScore = lhs.matchScore + lhs.priorityBoost
                let rhsEffectiveMatchScore = rhs.matchScore + rhs.priorityBoost
                if !terms.isEmpty && lhsEffectiveMatchScore != rhsEffectiveMatchScore {
                    return lhsEffectiveMatchScore > rhsEffectiveMatchScore
                }

                if !terms.isEmpty && lhs.priorityBoost != rhs.priorityBoost {
                    return lhs.priorityBoost > rhs.priorityBoost
                }

                if !terms.isEmpty && lhs.matchScore != rhs.matchScore {
                    return lhs.matchScore > rhs.matchScore
                }

                if !terms.isEmpty && lhsIsFavorite != rhsIsFavorite {
                    return lhsIsFavorite
                }

                let lhsRecord = usageRecords[lhs.action.id]
                let rhsRecord = usageRecords[rhs.action.id]
                let lhsCount = lhsRecord?.useCount ?? 0
                let rhsCount = rhsRecord?.useCount ?? 0
                if lhsCount != rhsCount {
                    return lhsCount > rhsCount
                }

                let lhsUsedAt = lhsRecord?.lastUsedAt ?? .distantPast
                let rhsUsedAt = rhsRecord?.lastUsedAt ?? .distantPast
                if lhsUsedAt != rhsUsedAt {
                    return lhsUsedAt > rhsUsedAt
                }

                return lhs.index < rhs.index
            }
            .map(\.action)
            .filter { action in
                guard let requiredGroup else { return true }
                return action.resolvedGroup == requiredGroup
            }
            .filter { action in
                guard let requiredSourceKinds, !requiredSourceKinds.isEmpty else { return true }
                return requiredSourceKinds.contains(action.sourceKind)
            }
    }

    private static func searchPriorityBoost(
        for action: CommandPaletteAction,
        priorityActionIDs: Set<String>,
        preferredSourceKinds: Set<SourceKind>,
        termCount: Int
    ) -> Int {
        guard termCount == 1 else { return 0 }

        var boost = 0
        if priorityActionIDs.contains(action.id) {
            boost += 32
        }
        if preferredSourceKinds.contains(action.sourceKind) {
            boost += 22
        }
        return boost
    }

    private static func searchTerms(from query: String) -> [String] {
        query
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }

    private static func score(term: String, in field: String) -> Int? {
        let cleanField = field.lowercased()
        let words = cleanField
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        let compactField = words.joined()
        let acronym = String(words.compactMap(\.first))

        if cleanField == term {
            return 140
        }
        if cleanField.hasPrefix(term) {
            return 120
        }
        if words.contains(term) {
            return 112
        }
        if words.contains(where: { $0.hasPrefix(term) }) {
            return 100
        }
        if compactField == term {
            return 92
        }
        if compactField.hasPrefix(term) {
            return 86
        }
        if compactField.contains(term) {
            return 82
        }
        if cleanField.contains(term) {
            return 78
        }
        if term.count >= 2 && acronym.hasPrefix(term) {
            return 72
        }
        if term.count >= 2 && acronym.contains(term) {
            return 64
        }
        if term.count >= 2 && isSubsequence(term, in: acronym) {
            return 58
        }
        if words.contains(where: { isNearTerm(term, $0) }) {
            return 48
        }

        return nil
    }

    private static func isNearTerm(_ term: String, _ word: String) -> Bool {
        let termCount = term.count
        let wordCount = word.count
        guard termCount >= 5 else { return false }

        if wordCount >= termCount,
           wordCount - termCount <= 2,
           isSubsequence(term, in: word) {
            return true
        }
        guard abs(wordCount - termCount) <= 1 else { return false }

        var edits = 0
        var termIndex = term.startIndex
        var wordIndex = word.startIndex
        while termIndex < term.endIndex && wordIndex < word.endIndex {
            if term[termIndex] == word[wordIndex] {
                term.formIndex(after: &termIndex)
                word.formIndex(after: &wordIndex)
                continue
            }

            edits += 1
            guard edits <= 1 else { return false }
            if termCount > wordCount {
                term.formIndex(after: &termIndex)
            } else if wordCount > termCount {
                word.formIndex(after: &wordIndex)
            } else {
                term.formIndex(after: &termIndex)
                word.formIndex(after: &wordIndex)
            }
        }

        return true
    }

    private static func isSubsequence(_ needle: String, in haystack: String) -> Bool {
        guard !needle.isEmpty else { return true }

        var remaining = needle[...]
        for character in haystack where remaining.first == character {
            remaining.removeFirst()
            if remaining.isEmpty {
                return true
            }
        }

        return false
    }
}

private struct RankedCommandAction {
    let index: Int
    let action: CommandPaletteAction
    let matchScore: Int
    let priorityBoost: Int
}

enum CommandPaletteInlineRoute {
    static let minimumPromptLength = 3
    static let titleLimit = 72
    private static let prefixes = ["route:", "route ", "do:", "do "]

    static func makeAction(
        query: String,
        run: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        guard let prompt = prefixedPrompt(from: query), prompt.count >= minimumPromptLength else {
            return nil
        }

        return CommandPaletteAction(
            id: "inline-route",
            title: "Route: \(FreeformPrompt.preview(prompt, limit: titleLimit))",
            subtitle: "Run the best local AI command or script for this request",
            systemImage: "bolt.horizontal.circle",
            sourceKind: .ask,
            keywords: ["route", "local", "action", "script", "prompt", prompt],
            canFavorite: false
        ) {
            run(prompt)
        }
    }

    private static func prefixedPrompt(from query: String) -> String? {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in prefixes where cleanQuery.lowercased().hasPrefix(prefix) {
            let prompt = String(cleanQuery.dropFirst(prefix.count))
            let cleanPrompt = FreeformPrompt.clean(prompt)
            return cleanPrompt.isEmpty ? nil : cleanPrompt
        }
        return nil
    }
}

enum CommandPaletteInlineAsk {
    static let minimumPromptLength = 3
    static let titleLimit = 72

    static func makeAction(
        query: String,
        run: @escaping (String) -> Void
    ) -> CommandPaletteAction? {
        let prompt = FreeformPrompt.clean(query)
        guard prompt.count >= minimumPromptLength else { return nil }

        return CommandPaletteAction(
            id: "inline-ask",
            title: "Ask: \(FreeformPrompt.preview(prompt, limit: titleLimit))",
            subtitle: "Ask about current, selected, clipboard, or picked text",
            systemImage: "sparkles",
            sourceKind: .ask,
            keywords: ["ask", "ai", "llm", "question", prompt],
            canFavorite: false
        ) {
            run(prompt)
        }
    }
}

@MainActor
final class CommandPaletteWindow {
    struct LayoutMetrics: Equatable {
        let preferredContentSize: NSSize
        let bodyMinSize: NSSize
        let stackSpacing: CGFloat
        let searchFieldSpacing: CGFloat
        let searchHorizontalPadding: CGFloat
        let searchVerticalPadding: CGFloat
        let contentPadding: CGFloat
        let emptyStateVerticalPadding: CGFloat
        let groupChipSpacing: CGFloat
        let groupChipHorizontalPadding: CGFloat
        let groupChipVerticalPadding: CGFloat
        let groupBarHorizontalPadding: CGFloat
        let groupBadgeHorizontalPadding: CGFloat
        let groupBadgeVerticalPadding: CGFloat
        let rowHorizontalPadding: CGFloat
        let rowVerticalPadding: CGFloat
        let commandLabelSpacing: CGFloat
        let footerSpacing: CGFloat
        let actionPanelSpacing: CGFloat
        let actionPanelRowSpacing: CGFloat
        let actionPanelPadding: CGFloat
        let actionPanelWidth: CGFloat
        let actionPanelOverlayPadding: CGFloat
        let secondaryRowHorizontalPadding: CGFloat
        let secondaryRowVerticalPadding: CGFloat
        let shortcutBadgeHorizontalPadding: CGFloat
        let shortcutBadgeVerticalPadding: CGFloat
    }

    nonisolated static func layoutMetrics(isCompact: Bool) -> LayoutMetrics {
        if isCompact {
            return LayoutMetrics(
                preferredContentSize: NSSize(width: 596, height: 404),
                bodyMinSize: NSSize(width: 520, height: 332),
                stackSpacing: 10,
                searchFieldSpacing: 8,
                searchHorizontalPadding: 12,
                searchVerticalPadding: 10,
                contentPadding: 10,
                emptyStateVerticalPadding: 36,
                groupChipSpacing: 6,
                groupChipHorizontalPadding: 8,
                groupChipVerticalPadding: 5,
                groupBarHorizontalPadding: 0,
                groupBadgeHorizontalPadding: 4,
                groupBadgeVerticalPadding: 2,
                rowHorizontalPadding: 10,
                rowVerticalPadding: 8,
                commandLabelSpacing: 10,
                footerSpacing: 10,
                actionPanelSpacing: 8,
                actionPanelRowSpacing: 5,
                actionPanelPadding: 10,
                actionPanelWidth: 272,
                actionPanelOverlayPadding: 10,
                secondaryRowHorizontalPadding: 8,
                secondaryRowVerticalPadding: 6,
                shortcutBadgeHorizontalPadding: 5,
                shortcutBadgeVerticalPadding: 2
            )
        }

        return LayoutMetrics(
            preferredContentSize: NSSize(width: 640, height: 460),
            bodyMinSize: NSSize(width: 560, height: 380),
            stackSpacing: 12,
            searchFieldSpacing: 10,
            searchHorizontalPadding: 16,
            searchVerticalPadding: 14,
            contentPadding: 14,
            emptyStateVerticalPadding: 48,
            groupChipSpacing: 8,
            groupChipHorizontalPadding: 10,
            groupChipVerticalPadding: 6,
            groupBarHorizontalPadding: 2,
            groupBadgeHorizontalPadding: 5,
            groupBadgeVerticalPadding: 2,
            rowHorizontalPadding: 12,
            rowVerticalPadding: 10,
            commandLabelSpacing: 12,
            footerSpacing: 12,
            actionPanelSpacing: 10,
            actionPanelRowSpacing: 6,
            actionPanelPadding: 12,
            actionPanelWidth: 304,
            actionPanelOverlayPadding: 14,
            secondaryRowHorizontalPadding: 10,
            secondaryRowVerticalPadding: 8,
            shortcutBadgeHorizontalPadding: 6,
            shortcutBadgeVerticalPadding: 3
        )
    }

    private let state: ReaderState
    private let settings: SettingsStore
    private let usageStore = CommandUsageStore()
    private let session = CommandPaletteSession(
        launchRecoveryHotKeyInterventionScoresStorageKey: AppDefaults.fameLaunchRecoveryHotKeyInterventionScoresKey,
        fameMomentumPanelActionScoresStorageKey: AppDefaults.fameMomentumPanelActionScoresKey
    )
    private let refreshClock = CommandPaletteRefreshClock()
    private let actions: () -> [CommandPaletteAction]
    private let browseActions: () -> [CommandPaletteAction]
    private let browseSummary: () -> CommandPaletteBrowseSummary
    private let inlineActions: (String) -> [CommandPaletteAction]
    private let onShow: () -> Void
    private let prepareRun: (String) -> Void
    private var window: NSPanel?
    private var testIsVisible = false
    private nonisolated static let rootSearchInlinePrefixes = ["route:", "route ", "do:", "do "]

    private var currentLayoutMetrics: LayoutMetrics {
        Self.layoutMetrics(isCompact: settings.launcherCompactMode)
    }

    init(
        state: ReaderState,
        settings: SettingsStore,
        actions: @escaping () -> [CommandPaletteAction],
        browseActions: @escaping () -> [CommandPaletteAction] = { [] },
        browseSummary: @escaping () -> CommandPaletteBrowseSummary = { .empty },
        inlineActions: @escaping (String) -> [CommandPaletteAction] = { _ in [] },
        onShow: @escaping () -> Void = {},
        prepareRun: @escaping (String) -> Void = { _ in },
        topPickMilestone: @escaping (Int) -> Void = { _ in },
        recordBestChannelLaunchPackPressureActivity: @escaping (
            CommandPaletteBestChannelLaunchPackPressureActivity
        ) -> Void = { _ in },
        recordRun: @escaping (CommandPaletteAction) -> Void = { _ in }
    ) {
        self.state = state
        self.settings = settings
        self.actions = actions
        self.browseActions = browseActions
        self.browseSummary = browseSummary
        self.inlineActions = inlineActions
        self.onShow = onShow
        self.prepareRun = prepareRun

        guard !RuntimeEnvironment.suppressesExternalEffects else { return }

        let layoutMetrics = currentLayoutMetrics
        let window = NSPanel(
            contentRect: NSRect(origin: .zero, size: layoutMetrics.preferredContentSize),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.window = window
        window.title = "Commands"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.isFloatingPanel = true
        window.hidesOnDeactivate = true
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.animationBehavior = .utilityWindow
        applyWindowLayout(to: window)
        window.contentViewController = NSHostingController(
            rootView: CommandPaletteView(
                state: state,
                settings: settings,
                usageStore: usageStore,
                session: session,
                refreshClock: refreshClock,
                actions: actions,
                browseActions: browseActions,
                browseSummary: browseSummary,
                inlineActions: inlineActions,
                prepareRun: prepareRun,
                topPickMilestone: topPickMilestone,
                recordBestChannelLaunchPackPressureActivity:
                    recordBestChannelLaunchPackPressureActivity,
                recordRun: recordRun,
                close: { [weak self] in self?.hide() }
            )
        )
    }

    func show() {
        onShow()
        session.beginOpen()
        guard !RuntimeEnvironment.suppressesExternalEffects else {
            testIsVisible = true
            return
        }
        guard let window else { return }
        applyWindowLayout(to: window)
        placeNearTopOfScreen()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    var isVisible: Bool {
        if RuntimeEnvironment.suppressesExternalEffects {
            return testIsVisible
        }
        return window?.isVisible ?? false
    }

    func requestRefresh() {
        refreshClock.bump()
    }

    func refreshLayout() {
        refreshClock.bump()
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        guard let window else { return }
        applyWindowLayout(to: window)
        if window.isVisible {
            placeNearTopOfScreen()
        }
    }

    func clearCommandLearning() {
        usageStore.clearRecords()
    }

    var currentWindowContentSize: NSSize? {
        if RuntimeEnvironment.suppressesExternalEffects {
            return currentLayoutMetrics.preferredContentSize
        }
        return window?.contentView?.bounds.size
    }

    var hasCommandFavorites: Bool {
        !usageStore.favoriteActionIDs.isEmpty
    }

    func clearCommandFavorites() {
        usageStore.clearFavorites()
    }

    func recordExternalRun(actionID: String) {
        usageStore.recordRun(actionID: actionID)
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: actionID)
    }

    nonisolated static func baseActionIDsForSearchState(
        allActions: [CommandPaletteAction],
        browseActions: [CommandPaletteAction],
        searchQuery: String,
        hasScopedQuery: Bool,
        activeGroup: CommandPaletteGroup?
    ) -> [String] {
        let cleanQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty && !hasScopedQuery && activeGroup == nil {
            return browseActions.map(\.id)
        }
        return allActions.map(\.id)
    }

    nonisolated static func launcherHomeSections(
        availableActionIDs: [String]
    ) -> [CommandPaletteLauncherHomeSection] {
        let availableActionIDSet = Set(availableActionIDs)
        let sectionDefinitions = [
            CommandPaletteLauncherHomeSection(
                title: "Start",
                actionIDs: [
                    "pick-and-read",
                    "screenshot-line",
                    "ask-anything",
                    "run-best-local-action"
                ]
            ),
            CommandPaletteLauncherHomeSection(
                title: "Spaces",
                actionIDs: [
                    "open-notes-workspace",
                    "open-extensions-workspace",
                    "window-settings",
                    "setup-checklist"
                ]
            )
        ]

        return sectionDefinitions
            .map { section in
                CommandPaletteLauncherHomeSection(
                    title: section.title,
                    actionIDs: section.actionIDs.filter { availableActionIDSet.contains($0) }
                )
            }
            .filter { !$0.actionIDs.isEmpty }
    }

    nonisolated static func launcherHomeUtilityActionIDs(
        availableActionIDs: [String]
    ) -> [String] {
        let availableActionIDSet = Set(availableActionIDs)
        let preferredActionIDs = [
            "show-reader",
            "refresh-app-launcher",
            "toggle-menu-bar-item",
            "settings"
        ]
        return preferredActionIDs.filter { availableActionIDSet.contains($0) }
    }

    nonisolated static let platformFirstSearchSourceKinds: Set<CommandPaletteAction.SourceKind> = [
        .app,
        .file,
        .folder,
        .snippet,
        .link,
        .clipboard,
        .recent,
        .script,
        .path,
        .web
    ]

    nonisolated static func normalizedSelectionID(
        actionIDs: [String],
        currentID: String?
    ) -> String? {
        guard !actionIDs.isEmpty else { return nil }
        if let currentID, actionIDs.contains(currentID) {
            return currentID
        }
        return actionIDs.first
    }

    nonisolated static func shiftedSelectionID(
        actionIDs: [String],
        currentID: String?,
        offset: Int
    ) -> String? {
        guard !actionIDs.isEmpty else { return nil }
        let currentIndex = currentID.flatMap { actionIDs.firstIndex(of: $0) } ?? 0
        let count = actionIDs.count
        let nextIndex = ((currentIndex + offset) % count + count) % count
        return actionIDs[nextIndex]
    }

    nonisolated static func queryByApplyingScope(
        _ insertedText: String,
        currentQuery: String
    ) -> String {
        let normalizedInsertedText = insertedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedInsertedText.isEmpty else { return currentQuery }

        let scopedQuery = CommandPaletteGroup.parseScopedQuery(currentQuery)
        let existingRemainder: String
        if scopedQuery.hasScope {
            existingRemainder = scopedQuery.searchQuery
        } else if let inlinePrompt = inlinePrompt(from: currentQuery) {
            existingRemainder = inlinePrompt
        } else {
            existingRemainder = currentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let cleanRemainder = existingRemainder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanRemainder.isEmpty else {
            return "\(normalizedInsertedText) "
        }
        return "\(normalizedInsertedText) \(cleanRemainder)"
    }

    private nonisolated static func inlinePrompt(from query: String) -> String? {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in rootSearchInlinePrefixes where cleanQuery.lowercased().hasPrefix(prefix) {
            let prompt = String(cleanQuery.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !prompt.isEmpty else { return nil }
            return prompt
        }
        return nil
    }

    private func hide() {
        guard !RuntimeEnvironment.suppressesExternalEffects else {
            testIsVisible = false
            return
        }
        window?.orderOut(nil)
    }

    private func applyWindowLayout(to window: NSPanel) {
        let layoutMetrics = currentLayoutMetrics
        WindowBounds.reset(
            window,
            preferredContentSize: layoutMetrics.preferredContentSize,
            minContentSize: layoutMetrics.preferredContentSize,
            maxContentSize: layoutMetrics.preferredContentSize
        )
    }

    private func placeNearTopOfScreen() {
        guard let window else { return }
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? .zero
        guard screenFrame != .zero else {
            window.center()
            return
        }

        let size = window.frame.size
        let x = screenFrame.midX - (size.width / 2)
        let y = screenFrame.maxY - size.height - 86
        window.setFrameOrigin(NSPoint(x: x, y: max(screenFrame.minY + 20, y)))
    }
}

typealias CommandPaletteWindowController = CommandPaletteWindow

enum CommandPaletteBestChannelLaunchPackPressureActivityKind: Equatable {
    case opportunity
    case conversion
    case modeTransition
}

struct CommandPaletteBestChannelLaunchPackPressureActivity: Equatable {
    let kind: CommandPaletteBestChannelLaunchPackPressureActivityKind
    let tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    let opportunities: Int
    let conversions: Int
    let streak: Int
    let bestStreak: Int
    let previousTrend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend?
    let trend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend

    init(
        kind: CommandPaletteBestChannelLaunchPackPressureActivityKind,
        tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone,
        opportunities: Int,
        conversions: Int,
        streak: Int,
        bestStreak: Int,
        previousTrend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend? = nil,
        trend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend = .noOpportunities
    ) {
        self.kind = kind
        self.tone = tone
        self.opportunities = opportunities
        self.conversions = conversions
        self.streak = streak
        self.bestStreak = bestStreak
        self.previousTrend = previousTrend
        self.trend = trend
    }
}

private struct CommandPaletteView: View {
    @ObservedObject var state: ReaderState
    @ObservedObject var settings: SettingsStore
    @ObservedObject var usageStore: CommandUsageStore
    @ObservedObject var session: CommandPaletteSession
    @ObservedObject var refreshClock: CommandPaletteRefreshClock
    let actions: () -> [CommandPaletteAction]
    let browseActions: () -> [CommandPaletteAction]
    let browseSummary: () -> CommandPaletteBrowseSummary
    let inlineActions: (String) -> [CommandPaletteAction]
    let prepareRun: (String) -> Void
    let topPickMilestone: (Int) -> Void
    let recordBestChannelLaunchPackPressureActivity:
        (CommandPaletteBestChannelLaunchPackPressureActivity) -> Void
    let recordRun: (CommandPaletteAction) -> Void
    let close: () -> Void

    @State private var query = ""
    @State private var selectedGroup: CommandPaletteGroup?
    @State private var selectedActionID: String?
    @State private var isActionPanelPresented = false
    @State private var selectedSecondaryActionID: String?
    // While the user is moving the selection with the keyboard, rows can scroll
    // under a stationary cursor and wrongly fire `.onHover`, stealing the
    // selection. We suppress hover-selection until the pointer actually moves.
    @State private var isKeyboardNavigating = false
    @State private var lastHoverLocation: CGPoint?
    @State private var previousTopPickIDs: [String] = []
    @State private var highlightedTopPickIDs: Set<String> = []
    @State private var topPickHighlightTask: Task<Void, Never>?
    @State private var visibleTopPickMilestone: Int?
    @State private var topPickMilestoneTask: Task<Void, Never>?
    @State private var visibleCadenceExecutionKitMomentumPulse: CommandPaletteCadenceExecutionKitStreak
        .MomentumPulse?
    @State private var cadenceExecutionKitMomentumPulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyRestorePulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyRestorePulse?
    @State private var launchRecoveryHotKeyRestorePulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyDecayPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyDecayPulse?
    @State private var launchRecoveryHotKeyDecayPulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyConfidencePulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyConfidencePulse?
    @State private var launchRecoveryHotKeyConfidencePulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyMomentumPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyMomentumPulse?
    @State private var launchRecoveryHotKeyMomentumPulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse?
    @State private var launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse?
    @State private var launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyLegendRiskStickyReleasePulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyLegendRiskStickyReleasePulse?
    @State private var launchRecoveryHotKeyLegendRiskStickyReleasePulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyInterventionTrustPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustPulse?
    @State private var launchRecoveryHotKeyInterventionTrustPulseTask: Task<Void, Never>?
    @State private var visibleLaunchRecoveryHotKeyInterventionTrustMomentumPulse: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustMomentumPulse?
    @State private var launchRecoveryHotKeyInterventionTrustMomentumPulseTask: Task<Void, Never>?
    @State private var
        visibleRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse?
    @State private var
        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseTask: Task<Void, Never>?
    @State private var
        visibleRecommendationMomentumRescueHallOfFameLegendRiskPulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameLegendRiskPulse?
    @State private var recommendationMomentumRescueHallOfFameLegendRiskPulseTask: Task<Void, Never>?
    @State private var
        visibleRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse?
    @State private var recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseTask: Task<Void, Never>?
    @State private var visibleRecommendationMomentumRescuePulse: CommandPaletteSession
        .RecommendationMomentumRescuePulse?
    @State private var recommendationMomentumRescuePulseTask: Task<Void, Never>?
    @State private var recommendationMomentumRescuePulseAnimationTask: Task<Void, Never>?
    @State private var isRecommendationMomentumRescuePulseCelebrationAnimated = false
    @State private var visibleRecommendationMomentumRescueWeeklyRecordPulse: CommandPaletteSession
        .RecommendationMomentumRescueWeeklyRecordPulse?
    @State private var recommendationMomentumRescueWeeklyRecordPulseTask: Task<Void, Never>?
    @State private var visibleRecommendationMomentumRescueImpactPulse: CommandPaletteTopPicks
        .RecommendationMomentumRescueImpactPulse?
    @State private var recommendationMomentumRescueImpactPulseTask: Task<Void, Never>?
    @State private var recommendationMomentumRescueImpactPulseAnimationTask: Task<Void, Never>?
    @State private var isRecommendationMomentumRescueImpactPulseAnimated = false
    @State private var visibleRecommendationConversionPulse: CommandPaletteSession
        .RecommendationConversionPulse?
    @State private var recommendationConversionPulseTask: Task<Void, Never>?
    @State private var visibleFameMomentumPanelLearningPulse: CommandPaletteSession
        .FameMomentumPanelLearningPulse?
    @State private var fameMomentumPanelLearningPulseTask: Task<Void, Never>?
    @State private var visibleFameMomentumPanelRouteFlipPulse: CommandPaletteSession
        .FameMomentumPanelRouteFlipPulse?
    @State private var fameMomentumPanelRouteFlipPulseTask: Task<Void, Never>?
    @State private var visibleFameMomentumPanelRouteStabilizationPulse: CommandPaletteSession
        .FameMomentumPanelRouteStabilizationPulse?
    @State private var fameMomentumPanelRouteStabilizationPulseTask: Task<Void, Never>?
    @State private var fameMomentumPanelRouteFlipInsightToken = ""
    @State private var isFameMomentumPanelRouteFlipInsightExpanded = false
    @State private var isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused = false
    @State private var fameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocusTask: Task<Void, Never>?
    @State private var previousRecommendationMomentumPairToken = ""
    @State private var previousRecommendationMomentumTone: CommandPaletteAction
        .RecommendationMomentumBadge.Tone?
    @State private var activeRecommendationMomentumPulseToken = ""
    @State private var isRecommendationMomentumPulseActive = false
    @State private var recommendationMomentumPulseTask: Task<Void, Never>?
    @State private var previousFameMomentumPanelTrustTrendToken = ""
    @State private var previousFameMomentumPanelTrustTrendDirection: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustTrend.Direction?
    @State private var activeFameMomentumPanelTrustFlipToken = ""
    @State private var isFameMomentumPanelTrustFlipCelebrationActive = false
    @State private var fameMomentumPanelTrustFlipCelebrationTask: Task<Void, Never>?
    @State private var lastBestChannelLaunchPackPressureTrend: CommandPaletteTopPicks
        .BestChannelLaunchPackPressureTrend?
    @FocusState private var searchIsFocused: Bool

    private var scopedQuery: CommandPaletteScopedQuery {
        CommandPaletteGroup.parseScopedQuery(query)
    }

    private var effectiveSearchQuery: String {
        scopedQuery.searchQuery
    }

    private var activeGroup: CommandPaletteGroup? {
        scopedQuery.hasScope ? scopedQuery.group : selectedGroup
    }

    private var layoutMetrics: CommandPaletteWindow.LayoutMetrics {
        CommandPaletteWindow.layoutMetrics(isCompact: settings.launcherCompactMode)
    }

    private var matchedActions: [CommandPaletteAction] {
        _ = refreshClock.tick
        let allActions = actions()
        let idleBrowseActions = browseActions()
        let baseActionIDs = Set(
            CommandPaletteWindow.baseActionIDsForSearchState(
                allActions: allActions,
                browseActions: idleBrowseActions,
                searchQuery: effectiveSearchQuery,
                hasScopedQuery: scopedQuery.hasScope,
                activeGroup: activeGroup
            )
        )
        let baseActions = allActions.filter { baseActionIDs.contains($0.id) }
        let availableActions = baseActions + inlineActions(effectiveSearchQuery)
        let usePlatformFirstSearchRanking = !effectiveSearchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty && !scopedQuery.hasScope && activeGroup == nil
        let priorityActionIDs = usePlatformFirstSearchRanking
            ? Set(idleBrowseActions.map(\.id))
            : []
        let preferredSourceKinds = usePlatformFirstSearchRanking
            ? CommandPaletteWindow.platformFirstSearchSourceKinds
            : []

        return CommandPaletteAction.filter(
            availableActions,
            query: effectiveSearchQuery,
            usageRecords: usageStore.records,
            favoriteActionIDs: usageStore.favoriteActionIDs,
            requiredSourceKinds: scopedQuery.sourceKinds,
            priorityActionIDs: priorityActionIDs,
            preferredSourceKinds: preferredSourceKinds
        )
    }

    private var filteredActions: [CommandPaletteAction] {
        guard let activeGroup else {
            return matchedActions
        }
        return matchedActions.filter { $0.resolvedGroup == activeGroup }
    }

    private var groupCounts: [CommandPaletteGroup: Int] {
        matchedActions.reduce(into: [:]) { partialResult, action in
            partialResult[action.resolvedGroup, default: 0] += 1
        }
    }

    private var availableGroups: [CommandPaletteGroup] {
        // Only surface group filter chips that actually contain visible actions,
        // so the bar never shows empty categories.
        let counts = groupCounts
        return CommandPaletteGroup.allCases.filter { (counts[$0] ?? 0) > 0 }
    }

    private var shouldShowTopPicks: Bool {
        let cleanQuery = effectiveSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanQuery.isEmpty && !scopedQuery.hasScope && activeGroup == nil
    }

    private var currentBrowseSummary: CommandPaletteBrowseSummary {
        browseSummary()
    }

    private var idleBrowseActions: [CommandPaletteAction] {
        browseActions()
    }

    private var launcherHomeSections: [CommandPaletteLauncherHomeSection] {
        CommandPaletteWindow.launcherHomeSections(
            availableActionIDs: idleBrowseActions.map(\.id)
        )
    }

    private var launcherHomeActionsByID: [String: CommandPaletteAction] {
        Dictionary(uniqueKeysWithValues: idleBrowseActions.map { ($0.id, $0) })
    }

    private var launcherHomeUtilityActions: [CommandPaletteAction] {
        let actionsByID = launcherHomeActionsByID
        let actionIDs = CommandPaletteWindow.launcherHomeUtilityActionIDs(
            availableActionIDs: idleBrowseActions.map(\.id)
        )
        return actionIDs.compactMap { actionsByID[$0] }
    }

    // The "Fame Ops" growth widgets (momentum/trust/confidence/scorecard cards,
    // header chips, and the recommendation rationale card) are hidden so the
    // Command Palette stays focused on real reader actions. Flip to `true` to
    // bring the growth tooling back.
    private var showFameTopPicksExtras: Bool { false }

    private var topPickContext: CommandPaletteTopPickContext {
        let onboardingRecoverySnapshot = CommandPaletteTopPicks.onboardingRecoverySnapshot()
        return CommandPaletteTopPickContext(
            hasText: !state.lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasAnswer: !state.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasImage: state.lastImageData != nil,
            hasError: !state.errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            llmEnabled: settings.llmEnabled,
            hasFreshOnboardingRecovery: onboardingRecoverySnapshot.isFresh,
            onboardingRecoveryFollowupActionID: onboardingRecoverySnapshot.followupActionID,
            onboardingRecoveryRemainingArtifacts: onboardingRecoverySnapshot.remainingArtifacts
        )
    }

    private var bestChannelLaunchPackAction: CommandPaletteAction? {
        matchedActions.first { action in
            action.id == "copy-next-move-best-channel-launch-pack" && action.isEnabled
        }
    }

    private var pulseAlertActionForPressure: CommandPaletteAction? {
        matchedActions.first { $0.id == "run-fame-pulse-alert" && $0.isEnabled }
    }

    private var launchHealthActionForPressure: CommandPaletteAction? {
        matchedActions.first { $0.id == "run-fame-launch-control-health" && $0.isEnabled }
    }

    private var launchAlertActionForPressure: CommandPaletteAction? {
        matchedActions.first { $0.id == "run-fame-launch-alert" && $0.isEnabled }
    }

    private var bestChannelLaunchPackPressureCard: CommandPaletteTopPicks.BestChannelLaunchPackPressureCard? {
        let modeShiftSummary = bestChannelLaunchPackPressureModeTransitionSummary
        return CommandPaletteTopPicks.bestChannelLaunchPackPressureCard(
            launchPackAction: bestChannelLaunchPackAction,
            pulseAlertAction: pulseAlertActionForPressure,
            launchHealthAction: launchHealthActionForPressure,
            launchAlertAction: launchAlertActionForPressure,
            momentumPulse: visibleLaunchRecoveryHotKeyMomentumPulse,
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak,
            modeTransitionCount: modeShiftSummary.count,
            modeTransitionLatestToken: modeShiftSummary.latestToken,
            modeMomentumStreak: modeShiftSummary.momentumStreak
        )
    }

    private var topPickPriorityPromotedActionIDs: [String] {
        let modeShiftSummary = bestChannelLaunchPackPressureModeTransitionSummary
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        let hallOfFamePriorityPromotedActionIDs = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFamePriorityPromotedActionIDs(
                cue: topPicksRecommendationMomentumRescueHallOfFameDefenseCueModel,
                rescuePlan: topPicksRecommendationMomentumRescuePlan,
                enabledActionIDs: enabledActionIDs
            )
        let bestChannelPriorityPromotedActionIDs = CommandPaletteTopPicks
            .bestChannelLaunchPackPressurePriorityPromotedActionIDs(
            card: bestChannelLaunchPackPressureCard,
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak,
            enabledActionIDs: enabledActionIDs,
            modeTransitionCount: modeShiftSummary.count,
            modeTransitionLatestToken: modeShiftSummary.latestToken,
            modeMomentumStreak: modeShiftSummary.momentumStreak
        )
        var priorityPromotedActionIDs: [String] = []
        var seenActionIDs = Set<String>()
        for actionID in hallOfFamePriorityPromotedActionIDs + bestChannelPriorityPromotedActionIDs
            where seenActionIDs.insert(actionID).inserted {
            priorityPromotedActionIDs.append(actionID)
        }
        return priorityPromotedActionIDs
    }

    private var bestChannelLaunchPackPressureModeTransitionSummary: (
        count: Int,
        latestToken: String?,
        momentumStreak: Int
    ) {
        let count = max(
            0,
            UserDefaults.standard.integer(
                forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionCountKey
            )
        )
        let latestToken = UserDefaults.standard.string(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeTransitionLatestKey
        )
        let momentumStreak = UserDefaults.standard.integer(
            forKey: AppDefaults.fameBestChannelLaunchPackPressureModeMomentumStreakKey
        )
        return (count, latestToken, momentumStreak)
    }

    private var bestChannelLaunchPackPressureBadgeTitle: String? {
        CommandPaletteTopPicks.bestChannelLaunchPackPressureBadgeTitle(
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak
        )
    }

    private var bestChannelLaunchPackPressurePerformanceLine: String {
        CommandPaletteTopPicks.bestChannelLaunchPackPressurePerformanceLine(
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak
        )
    }

    private var bestChannelLaunchPackPressureTrend: CommandPaletteTopPicks
        .BestChannelLaunchPackPressureTrend {
        CommandPaletteTopPicks.bestChannelLaunchPackPressureTrend(
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak
        )
    }

    private var bestChannelLaunchPackPressureModeBadgeTitle: String? {
        CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeTitle(
            trend: bestChannelLaunchPackPressureTrend
        )
    }

    private var bestChannelLaunchPackPressureModeBadgeHelpText: String {
        CommandPaletteTopPicks.bestChannelLaunchPackPressureModeBadgeHelpText(
            trend: bestChannelLaunchPackPressureTrend,
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak
        )
    }

    private var topPickPromotedActionIDs: [String] {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        guard !enabledActionIDs.isEmpty else { return [] }

        var promotedActionIDs: [String] = []
        if let stickyPromotion = session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        ),
            !promotedActionIDs.contains(stickyPromotion.actionID) {
            promotedActionIDs.append(stickyPromotion.actionID)
        }

        if let stickyPromotion = session.launchRecoveryHotKeyLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        ),
            !promotedActionIDs.contains(stickyPromotion.actionID) {
            promotedActionIDs.append(stickyPromotion.actionID)
        }

        let autoTrustSurgeLastRunAt = launchRecoveryHotKeyAutoTrustSurgeLastRunAt()
        let autoTrustSurgeRunsToday = launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday()
        let autoTrustSurgeStreak = launchRecoveryHotKeyAutoTrustSurgeStreak()
        let autoTrustSurgeWeeklyRuns = launchRecoveryHotKeyAutoTrustSurgeWeeklyRuns()
        let autoTrustSurgeStatus = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
            lastRunAt: autoTrustSurgeLastRunAt,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
            dailyCap: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
            runsToday: autoTrustSurgeRunsToday
        )
        let autoTrustSurgeLeagueHistory = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
                defaults: .standard,
                historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
                limit: 6
            )
        let autoTrustSurgeLeagueTrend = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: autoTrustSurgeLeagueHistory,
                sampleLimit: 4
            )
        if let legendDecayForecast = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                status: autoTrustSurgeStatus,
                trend: autoTrustSurgeLeagueTrend,
                runsToday: autoTrustSurgeRunsToday,
                currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                currentStreak: autoTrustSurgeStreak.current,
                bestStreak: autoTrustSurgeStreak.best,
                enabledActionIDs: enabledActionIDs
            ),
            legendDecayForecast.tone == .alert,
            let liveAlertActionID = legendDecayForecast.actionID,
            enabledActionIDs.contains(liveAlertActionID) {
            if !promotedActionIDs.contains(liveAlertActionID) {
                promotedActionIDs.append(liveAlertActionID)
            }
        }

        if let recommendationPairPromotedActionID = topPickRecommendationPairPromotedActionID(
            enabledActionIDs: enabledActionIDs
        ),
            !promotedActionIDs.contains(recommendationPairPromotedActionID) {
            promotedActionIDs.append(recommendationPairPromotedActionID)
        }
        return promotedActionIDs
    }

    private func topPickRecommendationPairPromotedActionID(
        enabledActionIDs: Set<String>
    ) -> String? {
        let candidates = topPickRecommendationPairPromotionCandidates(
            enabledActionIDs: enabledActionIDs
        )
        return CommandPaletteTopPicks.recommendationPairPromotedActionID(
            candidates: candidates,
            enabledActionIDs: enabledActionIDs,
            activeRescueStreak: session.recommendationMomentumRescueStreak
        )
    }

    private func topPickRecommendationPairRescuePlan(
        enabledActionIDs: Set<String>
    ) -> CommandPaletteTopPicks.RecommendationPairRescuePlan? {
        let candidates = topPickRecommendationPairPromotionCandidates(
            enabledActionIDs: enabledActionIDs
        )
        return CommandPaletteTopPicks.recommendationPairRescuePlan(
            candidates: candidates,
            enabledActionIDs: enabledActionIDs
        )
    }

    private func topPickRecommendationPairPromotionCandidates(
        enabledActionIDs: Set<String>
    ) -> [CommandPaletteTopPicks.RecommendationPairPromotionCandidate] {
        guard !enabledActionIDs.isEmpty else { return [] }
        return matchedActions.compactMap { action -> CommandPaletteTopPicks
            .RecommendationPairPromotionCandidate? in
            guard action.isEnabled,
                  let model = CommandPaletteAction.recommendationPanelModel(for: action),
                  let recommendedActionID = model.recommendedActionID,
                  enabledActionIDs.contains(recommendedActionID),
                  let performance = session.recommendationPairPerformance(
                      sourceActionID: model.actionID,
                      recommendedActionID: recommendedActionID
                  ) else {
                return nil
            }
            return CommandPaletteTopPicks.RecommendationPairPromotionCandidate(
                sourceActionID: model.actionID,
                recommendedActionID: recommendedActionID,
                opportunities: performance.opportunities,
                conversions: performance.conversions,
                opensSinceLastConversion: session.recommendationPairOpensSinceLastConversion(
                    sourceActionID: model.actionID,
                    recommendedActionID: recommendedActionID
                )
            )
        }
    }

    private var launchRecoveryHotKeyLegendRiskStickyPromotion: CommandPaletteSession
        .LaunchRecoveryHotKeyLegendRiskStickyPromotion? {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        guard !enabledActionIDs.isEmpty else { return nil }
        return session.launchRecoveryHotKeyLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
    }

    private var recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion: CommandPaletteSession
        .RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion? {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        guard !enabledActionIDs.isEmpty else { return nil }
        return session.recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion(
            enabledActionIDs: enabledActionIDs
        )
    }

    private var topPickActions: [CommandPaletteAction] {
        guard shouldShowTopPicks else { return [] }
        return CommandPaletteTopPicks.pickActions(
            from: matchedActions,
            context: topPickContext,
            usageRecords: usageStore.records,
            favoriteActionIDs: usageStore.favoriteActionIDs,
            priorityPromotedActionIDs: topPickPriorityPromotedActionIDs,
            promotedActionIDs: topPickPromotedActionIDs,
            limit: 4
        )
    }

    private var topPickSummary: String {
        CommandPaletteTopPicks.summaryText(for: topPickContext)
    }

    private var bestChannelLaunchPackPressureCardToken: String {
        guard let card = bestChannelLaunchPackPressureCard else { return "" }
        let toneToken: String = switch card.tone {
        case .watch:
            "watch"
        case .alert:
            "alert"
        }
        return "\(session.openCount)|\(card.actionID)|\(toneToken)"
    }

    private var bestChannelLaunchPackPressureTrendToken: String {
        guard bestChannelLaunchPackPressureCard != nil else { return "" }
        let trendToken: String = switch bestChannelLaunchPackPressureTrend {
        case .noOpportunities:
            "none"
        case .noWins:
            "no-wins"
        case .cooling:
            "cooling"
        case .rebuilding:
            "rebuilding"
        case .compounding:
            "compounding"
        }
        return "\(session.openCount)|\(trendToken)"
    }

    private var topPicksFameMomentumPanelModel: CommandPaletteTopPicks.FameMomentumPanel? {
        let confidenceInterventions = launchRecoveryHotKeyInterventions
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        let routeFlipRhythmTone: CommandPaletteTopPicks.FameMomentumPanelRouteFlipRhythmTone? = {
            guard let tone = session.fameMomentumPanelRouteFlipRhythm()?.tone else { return nil }
            switch tone {
            case .stabilizing:
                return .stabilizing
            case .watch:
                return .watch
            case .volatile:
                return .volatile
            }
        }()
        let trustMomentumPlan = CommandPaletteTopPicks
            .launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: launchRecoveryHotKeyInterventionTrustMomentum,
                interventions: confidenceInterventions,
                coachCue: launchRecoveryHotKeyCoachCue,
                enabledActionIDs: enabledActionIDs
            )
        let trustMomentumPlanActionID = trustMomentumPlan?.actionID.flatMap { actionID in
            matchedActions.contains(where: { $0.id == actionID && $0.isEnabled }) ? actionID : nil
        }

        return CommandPaletteTopPicks.fameMomentumPanel(
            confidenceScore: launchRecoveryHotKeyConfidenceScore,
            winDelta: CommandPaletteTopPicks.launchRecoveryHotKeyWinDelta(
                readinessHistory: session.launchRecoveryHotKeyReadinessHistory
            ),
            interventionTrustTrend: launchRecoveryHotKeyInterventionTrustTrend,
            routeFlipRhythmTone: routeFlipRhythmTone,
            rescuePlan: topPicksRecommendationMomentumRescuePlan,
            hallOfFameCue: topPicksRecommendationMomentumRescueHallOfFameDefenseCueModel,
            trustGuardActionID: launchRecoveryHotKeyInterventionTrustGuardAction?.id,
            trustMomentumPlanActionID: trustMomentumPlanActionID,
            actionScores: session.fameMomentumPanelAdaptiveActionScores,
            actionRecency: session.fameMomentumPanelActionRecency,
            enabledActionIDs: enabledActionIDs
        )
    }

    private var fameMomentumPanelTrustTrendDirection: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustTrend.Direction? {
        topPicksFameMomentumPanelModel?.interventionTrustTrend?.direction
    }

    private var fameMomentumPanelTrustTrendToken: String {
        fameMomentumPanelTrustTrendTransitionToken(
            actionID: topPicksFameMomentumPanelModel?.actionID,
            trustTrend: topPicksFameMomentumPanelModel?.interventionTrustTrend
        )
    }

    private var onboardingRecoveryBadgeTitle: String? {
        CommandPaletteTopPicks.onboardingRecoveryBadgeTitle(for: topPickContext)
    }

    private var onboardingRecoveryBadgeSystemImage: String? {
        CommandPaletteTopPicks.onboardingRecoveryBadgeSystemImage(for: topPickContext)
    }

    private var onboardingRecoveryBadgeHelpText: String {
        let followupTitle = topPickContext.onboardingRecoveryFollowupActionID.flatMap { actionID in
            matchedActions.first(where: { $0.id == actionID })?.title
        }
        return CommandPaletteTopPicks.onboardingRecoveryHelpText(
            for: topPickContext,
            followupTitle: followupTitle
        )
    }

    private var onboardingRecoveryQuickRunAction: CommandPaletteAction? {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        guard let actionID = CommandPaletteTopPicks.onboardingRecoveryQuickRunActionID(
            for: topPickContext,
            enabledActionIDs: enabledActionIDs
        ) else {
            return nil
        }
        return matchedActions.first { $0.id == actionID && $0.isEnabled }
    }

    private var launchRecoveryHotKeyReadiness: CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        return CommandPaletteTopPicks.launchRecoveryHotKeyReadiness(
            for: topPickContext,
            enabledActionIDs: enabledActionIDs
        )
    }

    private var launchRecoveryHotKeyTrend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend? {
        session.launchRecoveryHotKeyReadinessTrend(limit: 6)
    }

    private var launchRecoveryHotKeyWinMeter: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter? {
        CommandPaletteTopPicks.launchRecoveryHotKeyWinMeter(
            readinessHistory: session.launchRecoveryHotKeyReadinessHistory,
            directStreak: session.launchRecoveryHotKeyDirectStreak,
            bestDirectStreak: session.launchRecoveryHotKeyBestDirectStreak,
            sampleLimit: 8
        )
    }

    private var launchRecoveryHotKeyMomentum: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum? {
        CommandPaletteTopPicks.launchRecoveryHotKeyMomentum(
            for: session.launchRecoveryHotKeyReadinessHistory,
            window: 4
        )
    }

    private var launchRecoveryHotKeyConfidenceScore: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyConfidenceScore {
        CommandPaletteTopPicks.launchRecoveryHotKeyConfidenceScore(
            readiness: launchRecoveryHotKeyReadiness,
            trend: launchRecoveryHotKeyTrend,
            directStreak: session.launchRecoveryHotKeyDirectStreak,
            bestDirectStreak: session.launchRecoveryHotKeyBestDirectStreak
        )
    }

    private var launchRecoveryHotKeyCoachCue: CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue? {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        return CommandPaletteTopPicks.launchRecoveryHotKeyCoachCue(
            readiness: launchRecoveryHotKeyReadiness,
            trend: launchRecoveryHotKeyTrend,
            context: topPickContext,
            enabledActionIDs: enabledActionIDs
        )
    }

    private var launchRecoveryHotKeyCoachAction: CommandPaletteAction? {
        guard let actionID = launchRecoveryHotKeyCoachCue?.actionID else { return nil }
        return matchedActions.first { $0.id == actionID && $0.isEnabled }
    }

    private var launchRecoveryHotKeyInterventions: [CommandPaletteTopPicks
        .LaunchRecoveryHotKeyIntervention] {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        return CommandPaletteTopPicks.launchRecoveryHotKeyInterventions(
            score: launchRecoveryHotKeyConfidenceScore,
            readiness: launchRecoveryHotKeyReadiness,
            trend: launchRecoveryHotKeyTrend,
            coachCue: launchRecoveryHotKeyCoachCue,
            enabledActionIDs: enabledActionIDs,
            interventionScores: session.launchRecoveryHotKeyInterventionScores,
            interventionRecency: session.launchRecoveryHotKeyInterventionRecency,
            limit: 3
        )
    }

    private var launchRecoveryHotKeyInterventionTrustTrend: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustTrend? {
        session.launchRecoveryHotKeyInterventionTrustTrend
    }

    private var launchRecoveryHotKeyInterventionTrustMomentum: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustMomentum? {
        CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentum(
            for: session.launchRecoveryHotKeyInterventionTrustHistory
        )
    }

    private var launchRecoveryHotKeyInterventionTrustGuard: CommandPaletteTopPicks
        .LaunchRecoveryHotKeyInterventionTrustGuard? {
        guard let trustTrend = launchRecoveryHotKeyInterventionTrustTrend else { return nil }
        return CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuard(for: trustTrend)
    }

    private var launchRecoveryHotKeyInterventionTrustGuardAction: CommandPaletteAction? {
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        guard let actionID = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustGuardActionID(
            coachCue: launchRecoveryHotKeyCoachCue,
            enabledActionIDs: enabledActionIDs
        ) else {
            return nil
        }
        return matchedActions.first { $0.id == actionID && $0.isEnabled }
    }

    private func recordBestChannelLaunchPackPressureOpportunityIfNeeded() {
        guard let pressureCard = bestChannelLaunchPackPressureCard else { return }
        let previousTrend = bestChannelLaunchPackPressureTrend
        if session.recordBestChannelLaunchPackPressureOpportunity(tone: pressureCard.tone) {
            recordBestChannelLaunchPackPressureActivity(
                kind: .opportunity,
                tone: pressureCard.tone
            )
            recordBestChannelLaunchPackPressureTrendTransitionIfNeeded(
                previousTrend: previousTrend,
                tone: pressureCard.tone
            )
        }
    }

    private func recordBestChannelLaunchPackPressureTrendTransitionIfNeeded(
        previousTrend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend,
        tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) {
        let nextTrend = bestChannelLaunchPackPressureTrend
        defer {
            lastBestChannelLaunchPackPressureTrend = nextTrend
        }
        guard let transition = CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
            previousTrend: previousTrend,
            trend: nextTrend
        ) else {
            return
        }
        recordBestChannelLaunchPackPressureActivity(
            kind: .modeTransition,
            tone: tone,
            previousTrend: transition.previousTrend,
            trend: transition.trend
        )
    }

    private func recordBestChannelLaunchPackPressureTrendTransitionIfNeededForCurrentState() {
        guard let pressureCard = bestChannelLaunchPackPressureCard else { return }
        let currentTrend = bestChannelLaunchPackPressureTrend
        defer {
            lastBestChannelLaunchPackPressureTrend = currentTrend
        }

        guard let transition = CommandPaletteTopPicks.bestChannelLaunchPackPressureModeTransition(
            previousTrend: lastBestChannelLaunchPackPressureTrend,
            trend: currentTrend
        ) else {
            return
        }

        recordBestChannelLaunchPackPressureActivity(
            kind: .modeTransition,
            tone: pressureCard.tone,
            previousTrend: transition.previousTrend,
            trend: transition.trend
        )
    }

    private func recordBestChannelLaunchPackPressureActivity(
        kind: CommandPaletteBestChannelLaunchPackPressureActivityKind,
        tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone,
        previousTrend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend? = nil,
        trend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend? = nil
    ) {
        let resolvedTrend = trend ?? bestChannelLaunchPackPressureTrend
        let activity = CommandPaletteBestChannelLaunchPackPressureActivity(
            kind: kind,
            tone: tone,
            opportunities: session.bestChannelLaunchPackPressureOpportunities,
            conversions: session.bestChannelLaunchPackPressureConversions,
            streak: session.bestChannelLaunchPackPressureConversionStreak,
            bestStreak: session.bestChannelLaunchPackPressureBestStreak,
            previousTrend: previousTrend,
            trend: resolvedTrend
        )
        recordBestChannelLaunchPackPressureActivity(activity)
    }

    private var launchRecoveryDedicatedShortcutAction: CommandPaletteAction? {
        actions().first { action in
            action.id == CommandPaletteAction.launchRecoveryNextActionID && action.isEnabled
        }
    }

    private var autoOpsBundleStatusDedicatedShortcutAction: CommandPaletteAction? {
        actions().first { action in
            action.id == CommandPaletteAction.autoOpsBundleStatusActionID && action.isEnabled
        }
    }

    private var launchRescueAutoStatusDedicatedShortcutAction: CommandPaletteAction? {
        actions().first { action in
            action.id == CommandPaletteAction.launchRescueAutoStatusActionID && action.isEnabled
        }
    }

    private var cadenceExecutionKitStreak: Int {
        CommandPaletteCadenceExecutionKitStreak.currentStreak()
    }

    private var cadenceExecutionKitBestStreak: Int {
        CommandPaletteCadenceExecutionKitStreak.bestStreak()
    }

    private var shouldShowCadenceExecutionKitStreakBadge: Bool {
        CommandPaletteCadenceExecutionKitStreak.shouldShowBadge(
            currentStreak: cadenceExecutionKitStreak,
            topPickActionIDs: topPickActions.map(\.id),
            badgeEnabled: settings.fameCadenceExecutionKitBadgeEnabled
        )
    }

    private var topPicksRecommendationMomentumRescueLaneBadgeModel: CommandPaletteTopPicks
        .RecommendationMomentumRescueLaneBadge? {
        CommandPaletteTopPicks.recommendationMomentumRescueLaneBadge(
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak
        )
    }

    private var topPicksRecommendationMomentumRescueLeaderboardBadgeModel: CommandPaletteTopPicks
        .RecommendationMomentumRescueLeaderboardBadge? {
        CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardBadge(
            runsToday: session.recommendationMomentumRescueRunsToday,
            bestDayRuns: session.recommendationMomentumRescueBestDayRuns,
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak
        )
    }

    private var topPicksRecommendationMomentumRescueLeaderboardCardModel: CommandPaletteTopPicks
        .RecommendationMomentumRescueLeaderboardCard? {
        CommandPaletteTopPicks.recommendationMomentumRescueLeaderboardCard(
            runsToday: session.recommendationMomentumRescueRunsToday,
            bestDayRuns: session.recommendationMomentumRescueBestDayRuns,
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak
        )
    }

    private var topPicksRecommendationMomentumRescueHallOfFameBadgeModel: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameBadge? {
        CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameBadge(
            runsThisWeek: session.recommendationMomentumRescueRunsThisWeek,
            bestWeekRuns: session.recommendationMomentumRescueBestWeekRuns,
            previousWeekRuns: session.recommendationMomentumRescuePreviousWeekRuns
        )
    }

    private var topPicksRecommendationMomentumRescueHallOfFameCardModel: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameCard? {
        CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameCard(
            runsThisWeek: session.recommendationMomentumRescueRunsThisWeek,
            bestWeekRuns: session.recommendationMomentumRescueBestWeekRuns,
            previousWeekRuns: session.recommendationMomentumRescuePreviousWeekRuns,
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak
        )
    }

    private var topPicksRecommendationMomentumRescueHallOfFameDefenseCueModel: CommandPaletteTopPicks
        .RecommendationMomentumRescueHallOfFameDefenseCue? {
        CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameDefenseCue(
            runsThisWeek: session.recommendationMomentumRescueRunsThisWeek,
            bestWeekRuns: session.recommendationMomentumRescueBestWeekRuns,
            previousWeekRuns: session.recommendationMomentumRescuePreviousWeekRuns,
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak
        )
    }

    private var topPicksRecommendationMomentumRescuePlan: CommandPaletteTopPicks
        .RecommendationPairRescuePlan? {
        guard session.recommendationMomentumRescueStreak > 0 else { return nil }
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        return topPickRecommendationPairRescuePlan(enabledActionIDs: enabledActionIDs)
    }

    private var topPicksRecommendationMomentumRescueAction: CommandPaletteAction? {
        guard let rescueActionID = topPicksRecommendationMomentumRescuePlan?.recommendedActionID else {
            return nil
        }
        return matchedActions.first { $0.id == rescueActionID && $0.isEnabled }
    }

    private var shouldShowCadenceExecutionKitMomentumCard: Bool {
        CommandPaletteCadenceExecutionKitStreak.shouldShowMomentumCard(
            currentStreak: cadenceExecutionKitStreak,
            bestStreak: cadenceExecutionKitBestStreak,
            momentumCardEnabled: settings.fameCadenceExecutionKitMomentumCardEnabled
        )
    }

    private var cadenceExecutionKitRunAction: CommandPaletteAction? {
        matchedActions.first { $0.id == CommandPaletteCadenceExecutionKitStreak.runActionIDCandidate() }
    }

    private var cadenceExecutionKitCopyAction: CommandPaletteAction? {
        matchedActions.first { $0.id == CommandPaletteCadenceExecutionKitStreak.copyActionIDCandidate() }
    }

    private var activeActionID: String? {
        if let selectedActionID,
           filteredActions.contains(where: { $0.id == selectedActionID }) {
            return selectedActionID
        }
        return filteredActions.first?.id
    }

    private var activeAction: CommandPaletteAction? {
        guard let activeActionID else { return nil }
        return filteredActions.first { $0.id == activeActionID }
    }

    private var activeActionPanelActions: [CommandPaletteAction.SecondaryAction] {
        guard let action = activeAction else { return [] }

        var panelActions: [CommandPaletteAction.SecondaryAction] = []
        if !action.secondaryActions.isEmpty || action.canFavorite {
            panelActions.append(
                CommandPaletteAction.SecondaryAction(
                    id: "run-primary-\(action.id)",
                    title: action.title,
                    subtitle: action.subtitle,
                    systemImage: action.systemImage,
                    isEnabled: action.isEnabled,
                    disabledReason: action.disabledReason,
                    closesPaletteAfterRun: false
                ) {
                    run(action)
                }
            )
        }

        panelActions.append(contentsOf: action.secondaryActions)

        if action.canFavorite {
            let isFavorite = usageStore.isFavorite(actionID: action.id)
            panelActions.append(
                CommandPaletteAction.SecondaryAction(
                    id: "favorite-\(action.id)",
                    title: isFavorite ? "Unfavorite Command" : "Favorite Command",
                    subtitle: isFavorite
                        ? "Remove from launcher favorites"
                        : "Pin higher in launcher results",
                    systemImage: isFavorite ? "star.slash" : "star",
                    closesPaletteAfterRun: false,
                    closesPanelAfterRun: false
                ) {
                    usageStore.toggleFavorite(actionID: action.id)
                }
            )
        }

        return panelActions
    }

    private var activeSecondaryActionID: String? {
        CommandPaletteWindow.normalizedSelectionID(
            actionIDs: activeActionPanelActions.map(\.id),
            currentID: selectedSecondaryActionID
        )
    }

    private var activeSecondaryAction: CommandPaletteAction.SecondaryAction? {
        guard let activeSecondaryActionID else { return nil }
        return activeActionPanelActions.first { $0.id == activeSecondaryActionID }
    }

    private var actionPanelContextToken: String {
        let actionToken = activeAction?.id ?? "none"
        let panelActionToken = activeActionPanelActions
            .map { "\($0.id):\($0.title):\($0.isEnabled)" }
            .joined(separator: "|")
        return "\(actionToken)|\(panelActionToken)"
    }

    private var selectedActionRecommendationPanelModel: CommandPaletteAction.RecommendationPanelModel? {
        CommandPaletteAction.recommendationPanelModel(for: activeAction)
    }

    private var selectedActionRecommendationCTAAction: CommandPaletteAction? {
        guard let selectedActionRecommendationPanelModel,
              let recommendedActionID = selectedActionRecommendationPanelModel.recommendedActionID else {
            return nil
        }
        return actions().first { action in
            action.id == recommendedActionID && action.isEnabled
        }
    }

    private var selectedActionRecommendationOpportunityToken: String {
        guard let model = selectedActionRecommendationPanelModel,
              let ctaAction = selectedActionRecommendationCTAAction else {
            return ""
        }
        return "\(model.actionID)->\(ctaAction.id)"
    }

    private var fameMomentumPanelRouteStabilizationRecoveryDiagnosticsTelemetryToken: String {
        let confidenceHistoryToken = session
            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
            .map(String.init)
            .joined(separator: ",")
        return
            "\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount)|\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount)|\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount)|\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount)|\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount)|\(confidenceHistoryToken)|\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationScore)|\(session.fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibrationSampleCount)"
    }

    private var selectedActionRecommendationPairSignalLine: String? {
        guard let model = selectedActionRecommendationPanelModel,
              let ctaAction = selectedActionRecommendationCTAAction,
              let performance = session.recommendationPairPerformance(
                  sourceActionID: model.actionID,
                  recommendedActionID: ctaAction.id
              ) else {
            return nil
        }
        return CommandPaletteAction.recommendationPairSignalLine(
            opportunities: performance.opportunities,
            conversionCount: performance.conversions
        )
    }

    private var selectedActionRecommendationPairMomentumBadge: CommandPaletteAction
        .RecommendationMomentumBadge? {
        guard let model = selectedActionRecommendationPanelModel,
              let ctaAction = selectedActionRecommendationCTAAction else {
            return nil
        }
        return CommandPaletteAction.recommendationPairMomentumBadge(
            opensSinceLastConversion: session.recommendationPairOpensSinceLastConversion(
                sourceActionID: model.actionID,
                recommendedActionID: ctaAction.id
            )
        )
    }

    private var selectedActionRecommendationPairMomentumRescueCue: CommandPaletteAction
        .RecommendationMomentumRescueCue? {
        guard let model = selectedActionRecommendationPanelModel,
              let ctaAction = selectedActionRecommendationCTAAction,
              let performance = session.recommendationPairPerformance(
                  sourceActionID: model.actionID,
                  recommendedActionID: ctaAction.id
              ) else {
            return nil
        }
        return CommandPaletteAction.recommendationPairMomentumRescueCue(
            opensSinceLastConversion: session.recommendationPairOpensSinceLastConversion(
                sourceActionID: model.actionID,
                recommendedActionID: ctaAction.id
            ),
            opportunities: performance.opportunities,
            conversionCount: performance.conversions
        )
    }

    private var selectedActionRecommendationConversionSignalLine: String? {
        CommandPaletteAction.recommendationConversionSignalLine(
            opportunities: session.recommendationConversionOpportunities,
            conversionCount: session.recommendationConversionCount,
            openStreak: session.recommendationConversionOpenStreak,
            bestOpenStreak: session.recommendationConversionBestOpenStreak
        )
    }

    private var selectedActionRecommendationMomentumRescueSignalLine: String? {
        CommandPaletteAction.recommendationMomentumRescueSignalLine(
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak
        )
    }

    var body: some View {
        paletteBodyEventBindings
            .onMoveCommand(perform: moveSelection)
            .onExitCommand(perform: handleExitCommand)
    }

    private var paletteBodyContent: some View {
        VStack(spacing: layoutMetrics.stackSpacing) {
            HStack(spacing: layoutMetrics.searchFieldSpacing) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                TextField("Search commands, apps, files, notes…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($searchIsFocused)
                    .onSubmit(runActiveAction)
            }
            .padding(.horizontal, layoutMetrics.searchHorizontalPadding)
            .padding(.vertical, layoutMetrics.searchVerticalPadding)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            launcherSummaryCard

            groupFilterBar

            topPicksBar

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
                            commandRow(action, shortcutNumber: index < 9 ? index + 1 : nil)
                                .id(action.id)
                        }

                        if filteredActions.isEmpty {
                            Text("No results found. Try app:, file:, note:, link:, script:, q:, or shorter text.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, layoutMetrics.emptyStateVerticalPadding)
                        }
                    }
                }
                .onChange(of: activeActionID) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case .active(let location):
                        // A changed location means the user actually moved the
                        // pointer, so hand control back to mouse hover.
                        if let last = lastHoverLocation, location != last {
                            isKeyboardNavigating = false
                        }
                        lastHoverLocation = location
                    case .ended:
                        lastHoverLocation = nil
                    }
                }
            }

            if showFameTopPicksExtras, let selectedActionRecommendationPanelModel {
                selectedActionRecommendationPanel(
                    selectedActionRecommendationPanelModel,
                    ctaAction: selectedActionRecommendationCTAAction
                )
            }

            footer
            launchRecoveryDedicatedShortcutRegistrar
            autoOpsBundleStatusDedicatedShortcutRegistrar
            launchRescueAutoStatusDedicatedShortcutRegistrar
            selectedActionRecommendationShortcutRegistrar
            actionPanelToggleShortcutRegistrar
        }
    }

    @ViewBuilder
    private var launcherSummaryCard: some View {
        let summary = currentBrowseSummary
        let homeSections = launcherHomeSections
        let utilityActions = launcherHomeUtilityActions
        if shouldShowTopPicks
            && (
                !summary.sources.isEmpty
                    || !summary.scopes.isEmpty
                    || !homeSections.isEmpty
                    || !utilityActions.isEmpty
            ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Label("Launcher Home", systemImage: "square.grid.2x2")
                        .font(.caption.weight(.semibold))
                    Text("Quiet local launcher for reading, notes, scripts, files, AI, and windows.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !summary.detail.isEmpty {
                    Text(summary.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if !homeSections.isEmpty {
                    ForEach(Array(homeSections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            launcherSummarySectionLabel(section.title)
                            LazyVGrid(
                                columns: [
                                    GridItem(
                                        .adaptive(
                                            minimum: settings.launcherCompactMode ? 116 : 128
                                        ),
                                        spacing: 8,
                                        alignment: .leading
                                    )
                                ],
                                alignment: .leading,
                                spacing: 8
                            ) {
                                ForEach(section.actionIDs, id: \.self) { actionID in
                                    if let action = launcherHomeActionsByID[actionID] {
                                        launcherHomeActionTile(action)
                                    }
                                }
                            }
                        }
                    }
                }

                if !utilityActions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        launcherSummarySectionLabel("Platform")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(utilityActions) { action in
                                    launcherHomeUtilityActionChip(action)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }

                if !summary.sources.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        launcherSummarySectionLabel("Search")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(summary.sources) { source in
                                    launcherSummarySourceChip(source)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }

                if !summary.scopes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        launcherSummarySectionLabel("Try")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(summary.scopes) { scope in
                                    launcherSummaryScopeChip(scope)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            )
        }
    }

    private func launcherSummarySectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
    }

    private func launcherHomeActionTile(_ action: CommandPaletteAction) -> some View {
        Button {
            run(action)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: action.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(action.isEnabled ? Color.accentColor : .secondary)
                    .frame(width: 14)

                Text(launcherHomeActionTitle(for: action))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(action.isEnabled ? .primary : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let badgeTitle = launcherHomeActionShortcutBadgeTitle(for: action) {
                    shortcutBadge(badgeTitle)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                action.isEnabled
                    ? Color.accentColor.opacity(0.08)
                    : Color.secondary.opacity(0.08)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        action.isEnabled
                            ? Color.accentColor.opacity(0.16)
                            : Color.secondary.opacity(0.12),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
        .help(launcherHomeActionHelpText(for: action))
    }

    private func launcherHomeUtilityActionChip(_ action: CommandPaletteAction) -> some View {
        Button {
            run(action)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: action.systemImage)
                    .font(.caption.weight(.semibold))
                Text(launcherHomeActionTitle(for: action))
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                if let badgeTitle = launcherHomeActionShortcutBadgeTitle(for: action) {
                    shortcutBadge(badgeTitle)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                action.isEnabled
                    ? Color.secondary.opacity(0.1)
                    : Color.secondary.opacity(0.06)
            )
            .foregroundStyle(action.isEnabled ? .primary : .secondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
        .help(launcherHomeActionHelpText(for: action))
    }

    private func launcherHomeActionTitle(for action: CommandPaletteAction) -> String {
        switch action.id {
        case "pick-and-read":
            return "Pick & Read"
        case "screenshot-line":
            return "Screenshot"
        case "ask-anything":
            return "Ask"
        case "run-best-local-action":
            return "Route Request"
        case "open-notes-workspace":
            return "Notes"
        case "open-extensions-workspace":
            return "Extensions"
        case "window-settings":
            return "Windows"
        case "setup-checklist":
            return "Setup"
        case "refresh-app-launcher":
            return "Refresh Search"
        case "toggle-menu-bar-item":
            return action.title.replacingOccurrences(of: " Menu Bar Item", with: "")
        case "show-reader":
            return "Reader"
        default:
            return action.title
        }
    }

    private func launcherHomeActionShortcutBadgeTitle(
        for action: CommandPaletteAction
    ) -> String? {
        action.hotKeyBadgeTitle ?? CommandPaletteAction.dedicatedShortcutBadgeTitle(for: action.id)
    }

    private func launcherHomeActionHelpText(for action: CommandPaletteAction) -> String {
        guard action.isEnabled else {
            return "\(action.subtitle). \(action.disabledReason)"
        }
        if let badgeTitle = launcherHomeActionShortcutBadgeTitle(for: action) {
            return "\(action.subtitle). Shortcut: \(badgeTitle)."
        }
        return action.subtitle
    }

    private func launcherSummarySourceChip(_ source: CommandPaletteBrowseSummary.Source) -> some View {
        HStack(spacing: 6) {
            Image(systemName: source.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(source.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(source.countTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.primary.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
        .help(source.helpText)
    }

    private func launcherSummaryScopeChip(_ scope: CommandPaletteBrowseSummary.Scope) -> some View {
        Button {
            query = CommandPaletteWindow.queryByApplyingScope(
                scope.insertedText,
                currentQuery: query
            )
            selectedGroup = nil
            isActionPanelPresented = false
            selectedSecondaryActionID = nil
            searchIsFocused = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: scope.systemImage)
                    .font(.caption.weight(.semibold))
                Text(scope.title)
                    .font(.caption2.weight(.semibold))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.accentColor.opacity(0.14))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .help(scope.helpText)
    }

    private var paletteBodyStyled: some View {
        paletteBodyContent
            .padding(layoutMetrics.contentPadding)
            .frame(
                minWidth: layoutMetrics.bodyMinSize.width,
                minHeight: layoutMetrics.bodyMinSize.height
            )
            // Solid panel instead of a translucent material so the windows
            // behind the palette don't bleed through as blurred text.
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(alignment: .bottomTrailing) {
                if isActionPanelPresented, !activeActionPanelActions.isEmpty {
                    actionPanelOverlay
                        .padding(layoutMetrics.actionPanelOverlayPadding)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
    }

    private var paletteBodyLifecycleBindings: some View {
        paletteBodyStyled
            .onAppear {
                resetForOpen()
                previousTopPickIDs = topPickActions.map(\.id)
                recordBestChannelLaunchPackPressureOpportunityIfNeeded()
                recordBestChannelLaunchPackPressureTrendTransitionIfNeededForCurrentState()
                showCadenceExecutionKitMomentumPulseIfRecent()
                showLaunchRecoveryHotKeyRestorePulseIfRecent()
                showLaunchRecoveryHotKeyDecayPulseIfRecent()
                showLaunchRecoveryHotKeyConfidencePulseIfRecent()
                showLaunchRecoveryHotKeyMomentumPulseIfRecent()
                showLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseIfRecent()
                showLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseIfRecent()
                showLaunchRecoveryHotKeyLegendRiskStickyReleasePulseIfRecent()
                showLaunchRecoveryHotKeyInterventionTrustPulseIfRecent()
                showLaunchRecoveryHotKeyInterventionTrustMomentumPulseIfRecent()
                showRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseIfRecent()
                showRecommendationMomentumRescueHallOfFameLegendRiskPulseIfRecent()
                showRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseIfRecent()
                showRecommendationMomentumRescueImpactPulseIfRecent()
                showRecommendationMomentumRescuePulseIfRecent()
                showRecommendationMomentumRescueWeeklyRecordPulseIfRecent()
                showRecommendationConversionPulseIfRecent()
                showFameMomentumPanelLearningPulseIfRecent()
                showFameMomentumPanelRouteFlipPulseIfRecent()
                showFameMomentumPanelRouteStabilizationPulseIfRecent()
            }
            .onDisappear {
                topPickHighlightTask?.cancel()
                topPickMilestoneTask?.cancel()
                cadenceExecutionKitMomentumPulseTask?.cancel()
                launchRecoveryHotKeyRestorePulseTask?.cancel()
                launchRecoveryHotKeyDecayPulseTask?.cancel()
                launchRecoveryHotKeyConfidencePulseTask?.cancel()
                launchRecoveryHotKeyMomentumPulseTask?.cancel()
                launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseTask?.cancel()
                launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTask?.cancel()
                launchRecoveryHotKeyLegendRiskStickyReleasePulseTask?.cancel()
                launchRecoveryHotKeyInterventionTrustPulseTask?.cancel()
                launchRecoveryHotKeyInterventionTrustMomentumPulseTask?.cancel()
                recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseTask?.cancel()
                recommendationMomentumRescueHallOfFameLegendRiskPulseTask?.cancel()
                recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseTask?.cancel()
                recommendationMomentumRescueImpactPulseTask?.cancel()
                recommendationMomentumRescueImpactPulseAnimationTask?.cancel()
                recommendationMomentumRescuePulseTask?.cancel()
                recommendationMomentumRescuePulseAnimationTask?.cancel()
                recommendationMomentumRescueWeeklyRecordPulseTask?.cancel()
                recommendationConversionPulseTask?.cancel()
                fameMomentumPanelLearningPulseTask?.cancel()
                fameMomentumPanelRouteFlipPulseTask?.cancel()
                fameMomentumPanelRouteStabilizationPulseTask?.cancel()
                fameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocusTask?.cancel()
                visibleFameMomentumPanelRouteFlipPulse = nil
                visibleFameMomentumPanelRouteStabilizationPulse = nil
                fameMomentumPanelRouteFlipInsightToken = ""
                isFameMomentumPanelRouteFlipInsightExpanded = false
                isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused = false
                recommendationMomentumPulseTask?.cancel()
                clearFameMomentumPanelTrustFlipCelebration()
                isRecommendationMomentumRescueImpactPulseAnimated = false
                isRecommendationMomentumRescuePulseCelebrationAnimated = false
            }
    }

    private var paletteBodyEventBindings: some View {
        let baseEventBindings = paletteBodyLifecycleBindings
            .onChange(of: session.openCount) { _, _ in
                resetForOpen()
            }
            .onChange(of: query) { _, _ in
                clearFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocus()
                selectedActionID = filteredActions.first?.id
                dismissActionPanel()
            }
            .onChange(
                of: fameMomentumPanelRouteStabilizationRecoveryDiagnosticsTelemetryToken
            ) { _, _ in
                guard isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused else {
                    return
                }
                guard CommandPaletteTopPicks
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                        shownCount: session.fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                        runCount: session.fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount,
                        blockedCount: session.fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount,
                        pressureConfidenceBadge: CommandPaletteTopPicks
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                                shownCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                                blockedCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount,
                                recoveryRunCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount,
                                unblockRunCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount,
                                pressureConfidenceHistory: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
                                pressureCalibration: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration
                            ),
                        pressureConfidenceTrend: CommandPaletteTopPicks
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
                                history: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
                            )
                    ) == nil else {
                    return
                }
                clearFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocus()
            }
            .onChange(of: matchedActions.map(\.id).joined(separator: "|")) { _, _ in
                if !filteredActions.contains(where: { $0.id == selectedActionID }) {
                    selectedActionID = filteredActions.first?.id
                }
                normalizeActionPanelSelection()
            }
            .onChange(of: actionPanelContextToken) { _, _ in
                normalizeActionPanelSelection()
            }
            .onChange(of: selectedActionRecommendationOpportunityToken) { _, _ in
                recordRecommendationOpportunityIfNeeded()
                syncRecommendationMomentumBaseline()
            }
            .onChange(of: selectedActionRecommendationPairMomentumBadge?.tone) { _, nextTone in
                handleRecommendationMomentumToneChange(nextTone)
            }
            .onChange(of: topPickActions.map(\.id).joined(separator: "|")) { _, _ in
                refreshTopPickHighlights()
            }
            .onChange(of: bestChannelLaunchPackPressureCardToken) { _, _ in
                recordBestChannelLaunchPackPressureOpportunityIfNeeded()
            }
            .onChange(of: bestChannelLaunchPackPressureTrendToken) { _, _ in
                recordBestChannelLaunchPackPressureTrendTransitionIfNeededForCurrentState()
            }
            .onChange(of: fameMomentumPanelTrustTrendToken) { _, _ in
                syncFameMomentumPanelTrustTrendBaseline()
            }
            .onChange(of: fameMomentumPanelTrustTrendDirection) { _, nextDirection in
                handleFameMomentumPanelTrustTrendDirectionChange(nextDirection)
            }
            .onChange(of: session.topPickMilestoneEvent) { _, _ in
                let milestone = session.lastTopPickMilestone
                showTopPickMilestone(milestone)
                if milestone > 0 {
                    topPickMilestone(milestone)
                }
            }

        let pulseEventBindings = baseEventBindings
            .onChange(of: session.cadenceExecutionKitMomentumPulseEvent) { _, _ in
                showCadenceExecutionKitMomentumPulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyRestorePulseEvent) { _, _ in
                showLaunchRecoveryHotKeyRestorePulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyDecayPulseEvent) { _, _ in
                showLaunchRecoveryHotKeyDecayPulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyConfidencePulseEvent) { _, _ in
                showLaunchRecoveryHotKeyConfidencePulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyMomentumPulseEvent) { _, _ in
                showLaunchRecoveryHotKeyMomentumPulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseEvent) { _, _ in
                showLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseEvent) { _, _ in
                showLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyLegendRiskStickyReleasePulseEvent) { _, _ in
                showLaunchRecoveryHotKeyLegendRiskStickyReleasePulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyInterventionTrustPulseEvent) { _, _ in
                showLaunchRecoveryHotKeyInterventionTrustPulseIfRecent()
            }
            .onChange(of: session.launchRecoveryHotKeyInterventionTrustMomentumPulseEvent) { _, _ in
                showLaunchRecoveryHotKeyInterventionTrustMomentumPulseIfRecent()
            }
            .onChange(
                of: session.recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseEvent
            ) { _, _ in
                showRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseIfRecent()
            }
            .onChange(of: session.recommendationMomentumRescueHallOfFameLegendRiskPulseEvent) { _, _ in
                showRecommendationMomentumRescueHallOfFameLegendRiskPulseIfRecent()
            }
            .onChange(of: session.recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseEvent) { _, _ in
                showRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseIfRecent()
            }

        return pulseEventBindings
            .onChange(of: session.recommendationMomentumRescueImpactPulseEvent) { _, _ in
                showRecommendationMomentumRescueImpactPulseIfRecent()
            }
            .onChange(of: session.recommendationMomentumRescuePulseEvent) { _, _ in
                showRecommendationMomentumRescuePulseIfRecent()
            }
            .onChange(of: session.recommendationMomentumRescueWeeklyRecordPulseEvent) { _, _ in
                showRecommendationMomentumRescueWeeklyRecordPulseIfRecent()
            }
            .onChange(of: session.recommendationConversionPulseEvent) { _, _ in
                showRecommendationConversionPulseIfRecent()
            }
            .onChange(of: session.fameMomentumPanelLearningPulseEvent) { _, _ in
                showFameMomentumPanelLearningPulseIfRecent()
            }
            .onChange(of: session.fameMomentumPanelRouteFlipPulseEvent) { _, _ in
                showFameMomentumPanelRouteFlipPulseIfRecent()
            }
            .onChange(of: session.fameMomentumPanelRouteStabilizationPulseEvent) { _, _ in
                showFameMomentumPanelRouteStabilizationPulseIfRecent()
            }
    }

    private func recordRecommendationOpportunityIfNeeded() {
        guard let model = selectedActionRecommendationPanelModel,
              let ctaAction = selectedActionRecommendationCTAAction else {
            return
        }
        _ = session.recordRecommendationOpportunity()
        _ = session.recordRecommendationOpportunity(
            sourceActionID: model.actionID,
            recommendedActionID: ctaAction.id
        )
    }

    private func syncRecommendationMomentumBaseline() {
        previousRecommendationMomentumPairToken = selectedActionRecommendationOpportunityToken
        previousRecommendationMomentumTone = selectedActionRecommendationPairMomentumBadge?.tone
    }

    private func handleRecommendationMomentumToneChange(
        _ nextTone: CommandPaletteAction.RecommendationMomentumBadge.Tone?
    ) {
        let pairToken = selectedActionRecommendationOpportunityToken
        guard !pairToken.isEmpty else {
            previousRecommendationMomentumPairToken = ""
            previousRecommendationMomentumTone = nil
            clearRecommendationMomentumPulse()
            return
        }

        guard pairToken == previousRecommendationMomentumPairToken else {
            previousRecommendationMomentumPairToken = pairToken
            previousRecommendationMomentumTone = nextTone
            clearRecommendationMomentumPulse()
            return
        }

        guard let nextTone else {
            previousRecommendationMomentumTone = nil
            clearRecommendationMomentumPulse()
            return
        }

        let shouldCelebrate = CommandPaletteAction.shouldCelebrateRecommendationMomentumTransition(
            previousTone: previousRecommendationMomentumTone,
            nextTone: nextTone
        )
        previousRecommendationMomentumTone = nextTone
        guard shouldCelebrate else { return }
        showRecommendationMomentumPulse(for: pairToken)
    }

    private func showRecommendationMomentumPulse(for pairToken: String) {
        recommendationMomentumPulseTask?.cancel()
        recommendationMomentumPulseTask = Task {
            await MainActor.run {
                activeRecommendationMomentumPulseToken = pairToken
                isRecommendationMomentumPulseActive = false
                withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                    isRecommendationMomentumPulseActive = true
                }
            }

            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) {
                    isRecommendationMomentumPulseActive = false
                }
            }
        }
    }

    private func clearRecommendationMomentumPulse() {
        recommendationMomentumPulseTask?.cancel()
        recommendationMomentumPulseTask = nil
        activeRecommendationMomentumPulseToken = ""
        isRecommendationMomentumPulseActive = false
    }

    private func fameMomentumPanelTrustTrendTransitionToken(
        actionID: String?,
        trustTrend: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend?
    ) -> String {
        guard trustTrend != nil else { return "" }
        let normalizedActionID = actionID?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedActionID, !normalizedActionID.isEmpty {
            return normalizedActionID
        }
        return "none"
    }

    private func syncFameMomentumPanelTrustTrendBaseline() {
        previousFameMomentumPanelTrustTrendToken = fameMomentumPanelTrustTrendToken
        previousFameMomentumPanelTrustTrendDirection = fameMomentumPanelTrustTrendDirection
        if fameMomentumPanelTrustTrendToken.isEmpty {
            clearFameMomentumPanelTrustFlipCelebration()
        }
    }

    private func handleFameMomentumPanelTrustTrendDirectionChange(
        _ nextDirection: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend.Direction?
    ) {
        let trustTrendToken = fameMomentumPanelTrustTrendToken
        guard !trustTrendToken.isEmpty else {
            previousFameMomentumPanelTrustTrendToken = ""
            previousFameMomentumPanelTrustTrendDirection = nil
            clearFameMomentumPanelTrustFlipCelebration()
            return
        }

        guard trustTrendToken == previousFameMomentumPanelTrustTrendToken else {
            previousFameMomentumPanelTrustTrendToken = trustTrendToken
            previousFameMomentumPanelTrustTrendDirection = nextDirection
            clearFameMomentumPanelTrustFlipCelebration()
            return
        }

        guard let nextDirection else {
            previousFameMomentumPanelTrustTrendDirection = nil
            clearFameMomentumPanelTrustFlipCelebration()
            return
        }

        let shouldCelebrate = CommandPaletteTopPicks
            .shouldCelebrateFameMomentumPanelTrustTrendTransition(
                previousDirection: previousFameMomentumPanelTrustTrendDirection,
                nextDirection: nextDirection
            )
        previousFameMomentumPanelTrustTrendDirection = nextDirection
        guard shouldCelebrate else { return }
        showFameMomentumPanelTrustFlipCelebration(for: trustTrendToken)
    }

    private func showFameMomentumPanelTrustFlipCelebration(for trustTrendToken: String) {
        fameMomentumPanelTrustFlipCelebrationTask?.cancel()
        fameMomentumPanelTrustFlipCelebrationTask = Task {
            await MainActor.run {
                activeFameMomentumPanelTrustFlipToken = trustTrendToken
                isFameMomentumPanelTrustFlipCelebrationActive = false
                withAnimation(.spring(response: 0.24, dampingFraction: 0.64)) {
                    isFameMomentumPanelTrustFlipCelebrationActive = true
                }
            }

            try? await Task.sleep(nanoseconds: 720_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) {
                    isFameMomentumPanelTrustFlipCelebrationActive = false
                }
            }
        }
    }

    private func clearFameMomentumPanelTrustFlipCelebration() {
        fameMomentumPanelTrustFlipCelebrationTask?.cancel()
        fameMomentumPanelTrustFlipCelebrationTask = nil
        activeFameMomentumPanelTrustFlipToken = ""
        isFameMomentumPanelTrustFlipCelebrationActive = false
    }

    private func runRecommendationMomentumRescueAction(
        _ action: CommandPaletteAction,
        plan: CommandPaletteTopPicks.RecommendationPairRescuePlan
    ) {
        let pulse = CommandPaletteTopPicks.recommendationMomentumRescueImpactPulse(
            actionTitle: action.title,
            currentStreak: session.recommendationMomentumRescueStreak,
            bestStreak: session.recommendationMomentumRescueBestStreak,
            rescuePlan: plan
        )
        session.recordRecommendationMomentumRescueImpactPulse(pulse)
        run(action)
    }

    @discardableResult
    private func runRecommendationMomentumRescueHallOfFameAutoDefenseIfNeeded(
        cue: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue?,
        action: CommandPaletteAction?,
        plan: CommandPaletteTopPicks.RecommendationPairRescuePlan?,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard cue != nil,
              let action,
              let plan,
              action.isEnabled else {
            return false
        }
        guard CommandPaletteTopPicks.shouldAutoRunRecommendationMomentumRescueHallOfFameAutoDefense(
            isEnabled: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
            lastRunAt: recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt(defaults: defaults),
            now: now,
            cooldownMinutes: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes,
            cue: cue,
            hasRunnableAction: true
        ) else {
            return false
        }

        defaults.set(
            now.timeIntervalSince1970,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAtKey
        )
        recordRecommendationMomentumRescueHallOfFameAutoDefenseAutoRun(
            defaults: defaults,
            now: now
        )
        runRecommendationMomentumRescueAction(action, plan: plan)
        return true
    }

    private func resetForOpen() {
        clearFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocus()
        query = ""
        selectedGroup = nil
        selectedActionID = filteredActions.first?.id
        isActionPanelPresented = false
        selectedSecondaryActionID = nil
        highlightedTopPickIDs = []
        visibleTopPickMilestone = nil
        previousTopPickIDs = topPickActions.map(\.id)
        let readiness = launchRecoveryHotKeyReadiness
        let confidenceScore = launchRecoveryHotKeyConfidenceScore
        let confidenceNeedsAttention = CommandPaletteTopPicks
            .launchRecoveryHotKeyConfidenceScoreNeedsAttention(confidenceScore)
        let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
        session.recordLaunchRecoveryHotKeyReadiness(readiness)
        let momentumPulse = session.recordLaunchRecoveryHotKeyMomentum(launchRecoveryHotKeyMomentum)
        session.recordLaunchRecoveryHotKeyConfidenceScore(confidenceScore)
        let coachCue = launchRecoveryHotKeyCoachCue
        let momentumRescue = CommandPaletteTopPicks.launchRecoveryHotKeyMomentumRescue(
            pulse: momentumPulse,
            coachCue: coachCue,
            readiness: readiness,
            enabledActionIDs: enabledActionIDs
        )
        let momentumRescueAction: CommandPaletteAction? = momentumRescue.flatMap { rescue in
            guard let actionID = rescue.actionID else { return nil }
            return matchedActions.first { $0.id == actionID && $0.isEnabled }
        }
        let recommendationMomentumRescueHallOfFameDefenseCue =
            CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameDefenseCue(
                runsThisWeek: session.recommendationMomentumRescueRunsThisWeek,
                bestWeekRuns: session.recommendationMomentumRescueBestWeekRuns,
                previousWeekRuns: session.recommendationMomentumRescuePreviousWeekRuns,
                currentStreak: session.recommendationMomentumRescueStreak,
                bestStreak: session.recommendationMomentumRescueBestStreak
            )
        let recommendationMomentumRescuePlan = topPickRecommendationPairRescuePlan(
            enabledActionIDs: enabledActionIDs
        )
        let recommendationMomentumRescueAction: CommandPaletteAction? = recommendationMomentumRescuePlan
            .flatMap { plan in
                matchedActions.first { action in
                    action.id == plan.recommendedActionID && action.isEnabled
                }
            }
        let didRunRecommendationMomentumRescueHallOfFameAutoDefense =
            runRecommendationMomentumRescueHallOfFameAutoDefenseIfNeeded(
                cue: recommendationMomentumRescueHallOfFameDefenseCue,
                action: recommendationMomentumRescueAction,
                plan: recommendationMomentumRescuePlan
            )
        let decayPulse = session.recordLaunchRecoveryHotKeyCoachCue(coachCue)
        let didRunAutoCoach = !didRunRecommendationMomentumRescueHallOfFameAutoDefense
            && runLaunchRecoveryHotKeyAutoCoachIfNeeded(
                coachCue: coachCue,
                decayPulse: decayPulse
            )
        let didRunAutoRescue = !didRunRecommendationMomentumRescueHallOfFameAutoDefense
            && !didRunAutoCoach
            && runLaunchRecoveryHotKeyAutoRescueIfNeeded(
                rescue: momentumRescue,
                action: momentumRescueAction
            )
        if !didRunRecommendationMomentumRescueHallOfFameAutoDefense
            && !didRunAutoCoach
            && !didRunAutoRescue {
            let trustMomentumPlan = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionTrustMomentumPlan(
                momentum: launchRecoveryHotKeyInterventionTrustMomentum,
                interventions: launchRecoveryHotKeyInterventions,
                coachCue: coachCue,
                enabledActionIDs: enabledActionIDs
            )
            let trustMomentumPlanAction: CommandPaletteAction? = trustMomentumPlan.flatMap { plan -> CommandPaletteAction? in
                guard let actionID = plan.actionID else { return nil }
                return matchedActions.first { $0.id == actionID && $0.isEnabled }
            }
            runLaunchRecoveryHotKeyAutoTrustSurgeIfNeeded(
                trustMomentumPlan: trustMomentumPlan,
                action: trustMomentumPlanAction,
                confidenceNeedsAttention: confidenceNeedsAttention
            )
        }
        let autoTrustSurgeLastRunAt = launchRecoveryHotKeyAutoTrustSurgeLastRunAt()
        let autoTrustSurgeRunsToday = launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday()
        let autoTrustSurgeStreak = launchRecoveryHotKeyAutoTrustSurgeStreak()
        let autoTrustSurgeWeeklyRuns = launchRecoveryHotKeyAutoTrustSurgeWeeklyRuns()
        let autoTrustSurgeStatus = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
            lastRunAt: autoTrustSurgeLastRunAt,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
            dailyCap: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
            runsToday: autoTrustSurgeRunsToday
        )
        let autoTrustSurgeLeagueHistory = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
                defaults: .standard,
                historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
                limit: 6
            )
        let autoTrustSurgeLeagueTrend = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: autoTrustSurgeLeagueHistory,
                sampleLimit: 4
            )
        let autoTrustSurgeLegendDecayForecast = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                status: autoTrustSurgeStatus,
                trend: autoTrustSurgeLeagueTrend,
                runsToday: autoTrustSurgeRunsToday,
                currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                currentStreak: autoTrustSurgeStreak.current,
                bestStreak: autoTrustSurgeStreak.best,
                enabledActionIDs: enabledActionIDs
            )
        session.recordLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
            autoTrustSurgeLegendDecayForecast,
            stickyPromotionOpenWindow: settings.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens,
            stickyPromotionHoldUntilRecovered: settings
                .fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled
        )
        let recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt =
            recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt()
        let recommendationMomentumRescueHallOfFameAutoDefenseStatus = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseStatus(
                isEnabled: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
                lastRunAt: recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt,
                cooldownMinutes: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
            )
        let recommendationMomentumRescueHallOfFameAutoDefenseRunsTodayCount =
            recommendationMomentumRescueHallOfFameAutoDefenseRunsToday()
        let recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics =
            recommendationMomentumRescueHallOfFameAutoDefenseStreak()
        let recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics =
            recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRuns()
        let recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
                defaults: .standard,
                historyKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
                limit: 6
            )
        let recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                history: recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory,
                sampleLimit: 4
            )
        let recommendationMomentumRescueHallOfFameLegendRiskForecast = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameLegendRiskForecast(
                status: recommendationMomentumRescueHallOfFameAutoDefenseStatus,
                trend: recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend,
                runsToday: recommendationMomentumRescueHallOfFameAutoDefenseRunsTodayCount,
                currentWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.current,
                bestWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.best,
                currentStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.current,
                bestStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.best,
                enabledActionIDs: enabledActionIDs
            )
        session.recordRecommendationMomentumRescueHallOfFameLegendRiskForecast(
            recommendationMomentumRescueHallOfFameLegendRiskForecast,
            stickyPromotionOpenWindow: settings
                .fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens,
            stickyPromotionHoldUntilRecovered: settings
                .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        )
        recordRecommendationOpportunityIfNeeded()
        clearRecommendationMomentumPulse()
        syncRecommendationMomentumBaseline()
        searchIsFocused = true
    }

    @discardableResult
    private func runLaunchRecoveryHotKeyAutoCoachIfNeeded(
        coachCue: CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue?,
        decayPulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyDecayPulse?,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard decayPulse != nil else { return false }
        guard let coachCue,
              let action = launchRecoveryHotKeyCoachAction,
              action.id == coachCue.actionID,
              action.isEnabled else {
            return false
        }
        guard CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyCoach(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoCoachEnabled,
            lastRunAt: launchRecoveryHotKeyAutoCoachLastRunAt(defaults: defaults),
            now: now,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
        ) else {
            return false
        }

        defaults.set(now.timeIntervalSince1970, forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachLastRunAtKey)
        run(action)
        return true
    }

    @discardableResult
    private func runLaunchRecoveryHotKeyAutoRescueIfNeeded(
        rescue: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue?,
        action: CommandPaletteAction?,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> Bool {
        guard let action,
              action.isEnabled else {
            return false
        }
        guard CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyAutoRescue(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoRescueEnabled,
            lastRunAt: launchRecoveryHotKeyAutoRescueLastRunAt(defaults: defaults),
            now: now,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes,
            rescue: rescue,
            hasRunnableAction: true
        ) else {
            return false
        }

        defaults.set(now.timeIntervalSince1970, forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueLastRunAtKey)
        run(action)
        return true
    }

    private func runLaunchRecoveryHotKeyAutoTrustSurgeIfNeeded(
        trustMomentumPlan: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentumPlan?,
        action: CommandPaletteAction?,
        confidenceNeedsAttention: Bool,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) {
        guard let trustMomentumPlan,
              let action,
              action.isEnabled else {
            return
        }
        let autoRunsToday = launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday(
            defaults: defaults,
            now: now
        )
        guard CommandPaletteTopPicks.shouldAutoRunLaunchRecoveryHotKeyTrustSurge(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
            lastRunAt: launchRecoveryHotKeyAutoTrustSurgeLastRunAt(defaults: defaults),
            now: now,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
            dailyCap: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
            runsToday: autoRunsToday,
            remainingOpens: trustMomentumPlan.remainingOpens,
            confidenceNeedsAttention: confidenceNeedsAttention
        ) else {
            return
        }

        defaults.set(now.timeIntervalSince1970, forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey)
        recordLaunchRecoveryHotKeyAutoTrustSurgeAutoRun(defaults: defaults, now: now)
        run(action)
    }

    private func refreshTopPickHighlights() {
        let currentIDs = topPickActions.map(\.id)
        let appeared = CommandPaletteTopPicks.appearingActionIDs(previous: previousTopPickIDs, current: currentIDs)
        previousTopPickIDs = currentIDs

        topPickHighlightTask?.cancel()
        guard !appeared.isEmpty else {
            highlightedTopPickIDs = []
            return
        }

        highlightedTopPickIDs = appeared
        topPickHighlightTask = Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.24)) {
                    highlightedTopPickIDs = []
                }
            }
        }
    }

    private func showTopPickMilestone(_ milestone: Int) {
        guard milestone > 0 else { return }

        topPickMilestoneTask?.cancel()
        visibleTopPickMilestone = milestone

        topPickMilestoneTask = Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.22)) {
                    visibleTopPickMilestone = nil
                }
            }
        }
    }

    private func showCadenceExecutionKitMomentumPulseIfRecent() {
        guard let pulse = session.recentCadenceExecutionKitMomentumPulse() else {
            visibleCadenceExecutionKitMomentumPulse = nil
            return
        }

        cadenceExecutionKitMomentumPulseTask?.cancel()
        visibleCadenceExecutionKitMomentumPulse = pulse
        cadenceExecutionKitMomentumPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleCadenceExecutionKitMomentumPulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyRestorePulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyRestorePulse() else {
            visibleLaunchRecoveryHotKeyRestorePulse = nil
            return
        }

        launchRecoveryHotKeyRestorePulseTask?.cancel()
        visibleLaunchRecoveryHotKeyRestorePulse = pulse
        launchRecoveryHotKeyRestorePulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyRestorePulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyDecayPulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyDecayPulse() else {
            visibleLaunchRecoveryHotKeyDecayPulse = nil
            return
        }

        launchRecoveryHotKeyDecayPulseTask?.cancel()
        visibleLaunchRecoveryHotKeyDecayPulse = pulse
        launchRecoveryHotKeyDecayPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyDecayPulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyConfidencePulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyConfidencePulse() else {
            visibleLaunchRecoveryHotKeyConfidencePulse = nil
            return
        }

        launchRecoveryHotKeyConfidencePulseTask?.cancel()
        visibleLaunchRecoveryHotKeyConfidencePulse = pulse
        launchRecoveryHotKeyConfidencePulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyConfidencePulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyMomentumPulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyMomentumPulse() else {
            visibleLaunchRecoveryHotKeyMomentumPulse = nil
            return
        }

        launchRecoveryHotKeyMomentumPulseTask?.cancel()
        visibleLaunchRecoveryHotKeyMomentumPulse = pulse
        launchRecoveryHotKeyMomentumPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyMomentumPulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse() else {
            visibleLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse = nil
            return
        }

        launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseTask?.cancel()
        visibleLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse = pulse
        launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse() else {
            visibleLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse = nil
            return
        }

        launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTask?.cancel()
        visibleLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse = pulse
        launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyLegendRiskStickyReleasePulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyLegendRiskStickyReleasePulse() else {
            visibleLaunchRecoveryHotKeyLegendRiskStickyReleasePulse = nil
            return
        }

        launchRecoveryHotKeyLegendRiskStickyReleasePulseTask?.cancel()
        visibleLaunchRecoveryHotKeyLegendRiskStickyReleasePulse = pulse
        launchRecoveryHotKeyLegendRiskStickyReleasePulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyLegendRiskStickyReleasePulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyInterventionTrustPulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyInterventionTrustPulse() else {
            visibleLaunchRecoveryHotKeyInterventionTrustPulse = nil
            return
        }

        launchRecoveryHotKeyInterventionTrustPulseTask?.cancel()
        visibleLaunchRecoveryHotKeyInterventionTrustPulse = pulse
        launchRecoveryHotKeyInterventionTrustPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyInterventionTrustPulse = nil
                }
            }
        }
    }

    private func showLaunchRecoveryHotKeyInterventionTrustMomentumPulseIfRecent() {
        guard let pulse = session.recentLaunchRecoveryHotKeyInterventionTrustMomentumPulse() else {
            visibleLaunchRecoveryHotKeyInterventionTrustMomentumPulse = nil
            return
        }

        launchRecoveryHotKeyInterventionTrustMomentumPulseTask?.cancel()
        visibleLaunchRecoveryHotKeyInterventionTrustMomentumPulse = pulse
        launchRecoveryHotKeyInterventionTrustMomentumPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleLaunchRecoveryHotKeyInterventionTrustMomentumPulse = nil
                }
            }
        }
    }

    private func showRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseIfRecent() {
        guard let pulse = session
            .recentRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse() else {
            visibleRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse = nil
            return
        }

        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseTask?.cancel()
        visibleRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse = pulse
        recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse = nil
                }
            }
        }
    }

    private func showRecommendationMomentumRescueHallOfFameLegendRiskPulseIfRecent() {
        guard let pulse = session.recentRecommendationMomentumRescueHallOfFameLegendRiskPulse() else {
            visibleRecommendationMomentumRescueHallOfFameLegendRiskPulse = nil
            return
        }

        recommendationMomentumRescueHallOfFameLegendRiskPulseTask?.cancel()
        visibleRecommendationMomentumRescueHallOfFameLegendRiskPulse = pulse
        recommendationMomentumRescueHallOfFameLegendRiskPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationMomentumRescueHallOfFameLegendRiskPulse = nil
                }
            }
        }
    }

    private func showRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseIfRecent() {
        guard let pulse = session
            .recentRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse() else {
            visibleRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse = nil
            return
        }

        recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseTask?.cancel()
        visibleRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse = pulse
        recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse = nil
                }
            }
        }
    }

    private func showRecommendationMomentumRescueImpactPulseIfRecent() {
        guard let pulse = session.recentRecommendationMomentumRescueImpactPulse() else {
            visibleRecommendationMomentumRescueImpactPulse = nil
            recommendationMomentumRescueImpactPulseAnimationTask?.cancel()
            isRecommendationMomentumRescueImpactPulseAnimated = false
            return
        }

        recommendationMomentumRescueImpactPulseTask?.cancel()
        visibleRecommendationMomentumRescueImpactPulse = pulse
        animateRecommendationMomentumRescueImpactPulse()
        recommendationMomentumRescueImpactPulseTask = Task {
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationMomentumRescueImpactPulse = nil
                    isRecommendationMomentumRescueImpactPulseAnimated = false
                }
            }
        }
    }

    private func animateRecommendationMomentumRescueImpactPulse() {
        recommendationMomentumRescueImpactPulseAnimationTask?.cancel()
        recommendationMomentumRescueImpactPulseAnimationTask = Task {
            await MainActor.run {
                isRecommendationMomentumRescueImpactPulseAnimated = false
                withAnimation(.spring(response: 0.24, dampingFraction: 0.64)) {
                    isRecommendationMomentumRescueImpactPulseAnimated = true
                }
            }

            try? await Task.sleep(nanoseconds: 850_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.26)) {
                    isRecommendationMomentumRescueImpactPulseAnimated = false
                }
            }
        }
    }

    private func showRecommendationMomentumRescuePulseIfRecent() {
        guard let pulse = session.recentRecommendationMomentumRescuePulse() else {
            visibleRecommendationMomentumRescuePulse = nil
            recommendationMomentumRescuePulseAnimationTask?.cancel()
            isRecommendationMomentumRescuePulseCelebrationAnimated = false
            return
        }

        recommendationMomentumRescuePulseTask?.cancel()
        visibleRecommendationMomentumRescuePulse = pulse
        animateRecommendationMomentumRescuePulseCelebration()
        recommendationMomentumRescuePulseTask = Task {
            try? await Task.sleep(nanoseconds: 2_100_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationMomentumRescuePulse = nil
                    isRecommendationMomentumRescuePulseCelebrationAnimated = false
                }
            }
        }
    }

    private func showRecommendationMomentumRescueWeeklyRecordPulseIfRecent() {
        guard let pulse = session.recentRecommendationMomentumRescueWeeklyRecordPulse() else {
            visibleRecommendationMomentumRescueWeeklyRecordPulse = nil
            return
        }

        recommendationMomentumRescueWeeklyRecordPulseTask?.cancel()
        visibleRecommendationMomentumRescueWeeklyRecordPulse = pulse
        recommendationMomentumRescueWeeklyRecordPulseTask = Task {
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationMomentumRescueWeeklyRecordPulse = nil
                }
            }
        }
    }

    private func animateRecommendationMomentumRescuePulseCelebration() {
        recommendationMomentumRescuePulseAnimationTask?.cancel()
        recommendationMomentumRescuePulseAnimationTask = Task {
            await MainActor.run {
                isRecommendationMomentumRescuePulseCelebrationAnimated = false
                withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                    isRecommendationMomentumRescuePulseCelebrationAnimated = true
                }
            }

            try? await Task.sleep(nanoseconds: 920_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.26)) {
                    isRecommendationMomentumRescuePulseCelebrationAnimated = false
                }
            }
        }
    }

    private func showRecommendationConversionPulseIfRecent() {
        guard let pulse = session.recentRecommendationConversionPulse() else {
            visibleRecommendationConversionPulse = nil
            return
        }

        recommendationConversionPulseTask?.cancel()
        visibleRecommendationConversionPulse = pulse
        recommendationConversionPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleRecommendationConversionPulse = nil
                }
            }
        }
    }

    private func showFameMomentumPanelLearningPulseIfRecent() {
        guard let pulse = session.recentFameMomentumPanelLearningPulse() else {
            visibleFameMomentumPanelLearningPulse = nil
            return
        }

        fameMomentumPanelLearningPulseTask?.cancel()
        visibleFameMomentumPanelLearningPulse = pulse
        fameMomentumPanelLearningPulseTask = Task {
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleFameMomentumPanelLearningPulse = nil
                }
            }
        }
    }

    private func showFameMomentumPanelRouteFlipPulseIfRecent() {
        guard let pulse = session.recentFameMomentumPanelRouteFlipPulse() else {
            visibleFameMomentumPanelRouteFlipPulse = nil
            fameMomentumPanelRouteFlipInsightToken = ""
            isFameMomentumPanelRouteFlipInsightExpanded = false
            return
        }

        fameMomentumPanelRouteFlipPulseTask?.cancel()
        visibleFameMomentumPanelRouteFlipPulse = pulse
        let nextInsightToken = "\(pulse.previousActionPrompt)|\(pulse.nextActionPrompt)|\(pulse.subtitle)"
        if fameMomentumPanelRouteFlipInsightToken != nextInsightToken {
            fameMomentumPanelRouteFlipInsightToken = nextInsightToken
            isFameMomentumPanelRouteFlipInsightExpanded = false
        }
        fameMomentumPanelRouteFlipPulseTask = Task {
            try? await Task.sleep(nanoseconds: 8_600_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleFameMomentumPanelRouteFlipPulse = nil
                    fameMomentumPanelRouteFlipInsightToken = ""
                    isFameMomentumPanelRouteFlipInsightExpanded = false
                }
            }
        }
    }

    private func showFameMomentumPanelRouteStabilizationPulseIfRecent() {
        guard let pulse = session.recentFameMomentumPanelRouteStabilizationPulse() else {
            visibleFameMomentumPanelRouteStabilizationPulse = nil
            return
        }

        fameMomentumPanelRouteStabilizationPulseTask?.cancel()
        visibleFameMomentumPanelRouteStabilizationPulse = pulse
        fameMomentumPanelRouteStabilizationPulseTask = Task {
            try? await Task.sleep(nanoseconds: 4_600_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    visibleFameMomentumPanelRouteStabilizationPulse = nil
                }
            }
        }
    }

    private func launchRecoveryHotKeyAutoCoachLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func launchRecoveryHotKeyAutoRescueLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        guard defaults.object(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAtKey
        ) != nil else {
            return nil
        }
        let stamp = defaults.double(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLastRunAtKey
        )
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func recommendationMomentumRescueHallOfFameAutoDefenseRunsToday(
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Int {
        let dayStamp = defaults.string(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDayKey
        )
        let storedCount = defaults.integer(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCountKey
        )
        return CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseRunsToday(
            dayStamp: dayStamp,
            storedCount: storedCount,
            now: now
        )
    }

    private func recommendationMomentumRescueHallOfFameAutoDefenseStreak(
        defaults: UserDefaults = .standard
    ) -> (current: Int, best: Int) {
        let current = max(
            0,
            defaults.integer(
                forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseStreakKey
            )
        )
        let best = max(
            current,
            max(
                0,
                defaults.integer(
                    forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreakKey
                )
            )
        )
        return (current, best)
    }

    private func recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRuns(
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> (current: Int, best: Int) {
        let current = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRunsThisWeek(
                weekStamp: defaults.string(
                    forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekKey
                ),
                storedCount: defaults.integer(
                    forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCountKey
                ),
                now: now
            )
        let best = max(
            current,
            max(
                0,
                defaults.integer(
                    forKey: AppDefaults
                        .fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCountKey
                )
            )
        )
        return (current, best)
    }

    private func recordRecommendationMomentumRescueHallOfFameAutoDefenseAutoRun(
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) {
        let previousDayStamp = defaults.string(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDayKey
        )
        let storedWeekStamp = defaults.string(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekKey
        )
        let storedWeekCount = defaults.integer(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCountKey
        )
        let storedCurrentStreak = defaults.integer(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseStreakKey
        )
        let previousWeekRuns = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRunsThisWeek(
                weekStamp: storedWeekStamp,
                storedCount: storedWeekCount,
                now: now
            )
        let normalizedStoredCurrentStreak = max(0, storedCurrentStreak)
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeDayStamp(now: now)
        let previousStreak: Int
        if previousDayStamp == todayStamp {
            previousStreak = max(1, normalizedStoredCurrentStreak)
        } else {
            let calendar = Calendar.current
            if let yesterdayStart = calendar.date(
                byAdding: .day,
                value: -1,
                to: calendar.startOfDay(for: now)
            ) {
                let yesterdayStamp = String(Int(yesterdayStart.timeIntervalSince1970))
                if previousDayStamp == yesterdayStamp {
                    previousStreak = max(1, normalizedStoredCurrentStreak)
                } else {
                    previousStreak = 0
                }
            } else {
                previousStreak = 0
            }
        }
        let previousTier = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
                currentWeekRuns: previousWeekRuns,
                currentStreak: previousStreak
            )
        let recorded = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRecordedRun(
                dayStamp: previousDayStamp,
                storedCount: defaults.integer(
                    forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCountKey
                ),
                now: now
            )
        let streak = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseUpdatedStreak(
                previousDayStamp: previousDayStamp,
                currentStreak: storedCurrentStreak,
                bestStreak: defaults.integer(
                    forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreakKey
                ),
                now: now
            )
        let weekly = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRecordedWeeklyRun(
                weekStamp: storedWeekStamp,
                storedCount: storedWeekCount,
                bestWeekCount: defaults.integer(
                    forKey: AppDefaults
                        .fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCountKey
                ),
                now: now
            )
        let updatedTier = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueTier(
                currentWeekRuns: weekly.runsThisWeek,
                currentStreak: streak.streak
            )
        if let promotionPulse = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse(
                fromTier: previousTier,
                toTier: updatedTier,
                currentWeekRuns: weekly.runsThisWeek,
                currentStreak: streak.streak
            ) {
            session.recordRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse(
                promotionPulse,
                at: now
            )
        }
        let history = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
                defaults: defaults,
                historyKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
                limit: 12
            )
        let updatedHistory = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameAutoDefenseRecordedLeagueHistory(
                history: history,
                weekStamp: weekly.weekStamp,
                runsToday: recorded.runsToday,
                runsThisWeek: weekly.runsThisWeek,
                bestWeekRuns: weekly.bestWeekCount,
                currentStreak: streak.streak,
                bestStreak: streak.bestStreak,
                limit: 12
            )
        defaults.set(
            recorded.dayStamp,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunDayKey
        )
        defaults.set(
            recorded.runsToday,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunCountKey
        )
        defaults.set(
            streak.streak,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseStreakKey
        )
        defaults.set(
            streak.bestStreak,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseBestStreakKey
        )
        defaults.set(
            weekly.weekStamp,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekKey
        )
        defaults.set(
            weekly.runsThisWeek,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunWeekCountKey
        )
        defaults.set(
            weekly.bestWeekCount,
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseAutoRunBestWeekCountKey
        )
        if let historyData = try? JSONEncoder().encode(updatedHistory) {
            defaults.set(
                historyData,
                forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey
            )
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday(
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> Int {
        let dayStamp = defaults.string(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDayKey)
        let storedCount = defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCountKey)
        return CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: dayStamp,
            storedCount: storedCount,
            now: now
        )
    }

    private func launchRecoveryHotKeyAutoTrustSurgeStreak(
        defaults: UserDefaults = .standard
    ) -> (current: Int, best: Int) {
        let current = max(0, defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeStreakKey))
        let best = max(
            current,
            max(0, defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreakKey))
        )
        return (current, best)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeWeeklyRuns(
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) -> (current: Int, best: Int) {
        let current = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsThisWeek(
            weekStamp: defaults.string(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekKey),
            storedCount: defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCountKey),
            now: now
        )
        let best = max(
            current,
            max(
                0,
                defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCountKey)
            )
        )
        return (current, best)
    }

    private func recordLaunchRecoveryHotKeyAutoTrustSurgeAutoRun(
        defaults: UserDefaults = .standard,
        now: Date = Date()
    ) {
        let previousDayStamp = defaults.string(
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDayKey
        )
        let recorded = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedRun(
            dayStamp: previousDayStamp,
            storedCount: defaults.integer(
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCountKey
            ),
            now: now
        )
        let streak = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeUpdatedStreak(
            previousDayStamp: previousDayStamp,
            currentStreak: defaults.integer(
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeStreakKey
            ),
            bestStreak: defaults.integer(
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreakKey
            ),
            now: now
        )
        let weekly = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedWeeklyRun(
            weekStamp: defaults.string(
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekKey
            ),
            storedCount: defaults.integer(
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCountKey
            ),
            bestWeekCount: defaults.integer(
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCountKey
            ),
            now: now
        )
        defaults.set(
            recorded.dayStamp,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDayKey
        )
        defaults.set(
            recorded.runsToday,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCountKey
        )
        defaults.set(
            streak.streak,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeStreakKey
        )
        defaults.set(
            streak.bestStreak,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeBestStreakKey
        )
        defaults.set(
            weekly.weekStamp,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekKey
        )
        defaults.set(
            weekly.runsThisWeek,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunWeekCountKey
        )
        defaults.set(
            weekly.bestWeekCount,
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunBestWeekCountKey
        )
        let history = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
            defaults: defaults,
            historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
            limit: 12
        )
        let updatedHistory = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecordedLeagueHistory(
            history: history,
            weekStamp: weekly.weekStamp,
            runsToday: recorded.runsToday,
            runsThisWeek: weekly.runsThisWeek,
            bestWeekRuns: weekly.bestWeekCount,
            currentStreak: streak.streak,
            bestStreak: streak.bestStreak,
            limit: 12
        )
        if let promotionTransition = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionTransition(
                previousHistory: history,
                updatedHistory: updatedHistory,
                weekStamp: weekly.weekStamp
            ),
           let promotionPulse = CommandPaletteTopPicks
            .launchRecoveryHotKeyAutoTrustSurgeLeaguePulse(
                fromTier: promotionTransition.fromTier,
                toTier: promotionTransition.toTier,
                runsThisWeek: weekly.runsThisWeek,
                currentStreak: streak.streak
            ) {
            session.recordLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse(
                promotionPulse,
                at: now
            )
        }
        if let historyData = try? JSONEncoder().encode(updatedHistory) {
            defaults.set(
                historyData,
                forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey
            )
        }
    }

    @ViewBuilder
    private var groupFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: layoutMetrics.groupChipSpacing) {
                groupChip(
                    title: "All",
                    systemImage: "square.grid.2x2",
                    isSelected: activeGroup == nil,
                    count: matchedActions.count,
                    shortcutDigit: 0
                ) {
                    applyGroupSelection(nil)
                }

                ForEach(availableGroups) { group in
                    groupChip(
                        title: group.title,
                        systemImage: group.systemImage,
                        isSelected: activeGroup == group,
                        count: groupCounts[group, default: 0],
                        shortcutDigit: group.shortcutDigit
                    ) {
                        applyGroupSelection(group)
                    }
                }
            }
            .padding(.horizontal, layoutMetrics.groupBarHorizontalPadding)
        }
    }

    private func applyGroupSelection(_ group: CommandPaletteGroup?) {
        if scopedQuery.hasScope {
            query = scopedQuery.searchQuery
        }
        selectedGroup = group
        selectedActionID = filteredActions.first?.id
    }

    private func groupChip(
        title: String,
        systemImage: String,
        isSelected: Bool,
        count: Int,
        shortcutDigit: Int,
        action: @escaping () -> Void
    ) -> some View {
        let isEmpty = count == 0
        let key = KeyEquivalent(Character(String(shortcutDigit)))

        return Button(action: action) {
            HStack(spacing: layoutMetrics.groupChipSpacing) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption.weight(.semibold))
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, layoutMetrics.groupBadgeHorizontalPadding)
                    .padding(.vertical, layoutMetrics.groupBadgeVerticalPadding)
                    .background(Color.secondary.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                Text("⌃\(shortcutDigit)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, layoutMetrics.groupBadgeHorizontalPadding)
                    .padding(.vertical, layoutMetrics.groupBadgeVerticalPadding)
                    .background(Color.secondary.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .padding(.horizontal, layoutMetrics.groupChipHorizontalPadding)
            .padding(.vertical, layoutMetrics.groupChipVerticalPadding)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
            .opacity(isSelected || !isEmpty ? 1 : 0.72)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(key, modifiers: [.control])
        .help("\(title) (⌃\(shortcutDigit))")
    }

    @ViewBuilder
    private var topPicksBar: some View {
        // The whole "Top Picks" / Fame Ops bar is growth tooling, not a reader
        // action. Hiding it keeps the palette short enough to never overflow the
        // fixed window (which was clipping the search field at the top) and
        // removes the wall of text above the command list.
        if showFameTopPicksExtras && shouldShowTopPicks && !topPickActions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                let confidenceScore = launchRecoveryHotKeyConfidenceScore
                let winMeter = launchRecoveryHotKeyWinMeter
                let confidenceInterventions = launchRecoveryHotKeyInterventions
                let confidenceNeedsAttention = CommandPaletteTopPicks
                    .launchRecoveryHotKeyConfidenceScoreNeedsAttention(confidenceScore)
                let enabledActionIDs = Set(matchedActions.filter(\.isEnabled).map(\.id))
                let trustMomentumPlan = CommandPaletteTopPicks
                    .launchRecoveryHotKeyInterventionTrustMomentumPlan(
                        momentum: launchRecoveryHotKeyInterventionTrustMomentum,
                        interventions: confidenceInterventions,
                        coachCue: launchRecoveryHotKeyCoachCue,
                        enabledActionIDs: enabledActionIDs
                    )
                let trustMomentumPlanAction: CommandPaletteAction? = trustMomentumPlan.flatMap { plan -> CommandPaletteAction? in
                    guard let actionID = plan.actionID else { return nil }
                    return matchedActions.first { $0.id == actionID && $0.isEnabled }
                }
                let momentumRescue = CommandPaletteTopPicks.launchRecoveryHotKeyMomentumRescue(
                    pulse: visibleLaunchRecoveryHotKeyMomentumPulse,
                    coachCue: launchRecoveryHotKeyCoachCue,
                    readiness: launchRecoveryHotKeyReadiness,
                    enabledActionIDs: enabledActionIDs
                )
                let momentumRescueAction: CommandPaletteAction? = momentumRescue.flatMap { rescue in
                    guard let actionID = rescue.actionID else { return nil }
                    return matchedActions.first { $0.id == actionID && $0.isEnabled }
                }
                let autoRescueLastRunAt = launchRecoveryHotKeyAutoRescueLastRunAt()
                let autoRescueStatus = CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueStatus(
                    isEnabled: settings.fameLaunchRecoveryHotKeyAutoRescueEnabled,
                    lastRunAt: autoRescueLastRunAt,
                    cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
                )
                let autoRescueBadge = momentumRescue.map { _ in
                    CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueBadge(
                        status: autoRescueStatus
                    )
                }
                let autoRescueRecencyBadge = autoRescueBadge.flatMap { _ in
                    CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueRecencyBadge(
                        lastRunAt: autoRescueLastRunAt,
                        maxAgeMinutes: max(
                            20,
                            settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes * 6
                        )
                    )
                }
                let autoTrustSurgeLastRunAt = launchRecoveryHotKeyAutoTrustSurgeLastRunAt()
                let autoTrustSurgeRunsToday = launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday()
                let autoTrustSurgeStreak = launchRecoveryHotKeyAutoTrustSurgeStreak()
                let autoTrustSurgeWeeklyRuns = launchRecoveryHotKeyAutoTrustSurgeWeeklyRuns()
                let autoTrustSurgeStatus = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                    isEnabled: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
                    lastRunAt: autoTrustSurgeLastRunAt,
                    cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
                    dailyCap: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
                    runsToday: autoTrustSurgeRunsToday
                )
                let autoTrustSurgeBadge = trustMomentumPlan.map { plan in
                    CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeBadge(
                        status: autoTrustSurgeStatus,
                        remainingOpens: plan.remainingOpens
                    )
                }
                let autoTrustSurgeRecencyBadge = autoTrustSurgeBadge.flatMap { _ in
                    CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
                        lastRunAt: autoTrustSurgeLastRunAt,
                        maxAgeMinutes: max(
                            20,
                            settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes * 6
                        )
                    )
                }
                let autoTrustSurgeLeagueBadge = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
                    status: autoTrustSurgeStatus,
                    runsToday: autoTrustSurgeRunsToday,
                    currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                    bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                    currentStreak: autoTrustSurgeStreak.current,
                    bestStreak: autoTrustSurgeStreak.best
                )
                let autoTrustSurgeLeagueProgress = CommandPaletteTopPicks
                    .launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
                        status: autoTrustSurgeStatus,
                        runsToday: autoTrustSurgeRunsToday,
                        currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                        bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                        currentStreak: autoTrustSurgeStreak.current,
                        bestStreak: autoTrustSurgeStreak.best
                    )
                let autoTrustSurgeLeagueHistory = CommandPaletteTopPicks
                    .launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
                        defaults: .standard,
                        historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
                        limit: 6
                    )
                let autoTrustSurgeLeagueTrend = CommandPaletteTopPicks
                    .launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                        history: autoTrustSurgeLeagueHistory,
                        sampleLimit: 4
                    )
                let autoTrustSurgeLegendDefense = CommandPaletteTopPicks
                    .launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                        status: autoTrustSurgeStatus,
                        trend: autoTrustSurgeLeagueTrend,
                        runsToday: autoTrustSurgeRunsToday,
                        currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                        bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                        currentStreak: autoTrustSurgeStreak.current,
                        bestStreak: autoTrustSurgeStreak.best,
                        enabledActionIDs: enabledActionIDs
                    )
                let autoTrustSurgeLegendDefenseAction: CommandPaletteAction? = autoTrustSurgeLegendDefense.flatMap { defense in
                    guard let actionID = defense.actionID else { return nil }
                    return matchedActions.first { $0.id == actionID && $0.isEnabled }
                }
                let autoTrustSurgeLegendDecayForecast = CommandPaletteTopPicks
                    .launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                        status: autoTrustSurgeStatus,
                        trend: autoTrustSurgeLeagueTrend,
                        runsToday: autoTrustSurgeRunsToday,
                        currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                        bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                        currentStreak: autoTrustSurgeStreak.current,
                        bestStreak: autoTrustSurgeStreak.best,
                        enabledActionIDs: enabledActionIDs
                    )
                let autoTrustSurgeLegendDecayForecastAction: CommandPaletteAction? = autoTrustSurgeLegendDecayForecast.flatMap { forecast in
                    guard let actionID = forecast.actionID else { return nil }
                    return matchedActions.first { $0.id == actionID && $0.isEnabled }
                }
                let autoTrustSurgeInsight = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeInsight(
                    status: autoTrustSurgeStatus,
                    runsToday: autoTrustSurgeRunsToday,
                    currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                    bestWeekRuns: autoTrustSurgeWeeklyRuns.best,
                    currentStreak: autoTrustSurgeStreak.current,
                    bestStreak: autoTrustSurgeStreak.best
                )
                let recommendationMomentumRescueLaneBadge = topPicksRecommendationMomentumRescueLaneBadgeModel
                let recommendationMomentumRescueLaneDetailLine = CommandPaletteTopPicks
                    .recommendationMomentumRescueLaneDetailLine(
                        currentStreak: session.recommendationMomentumRescueStreak,
                        bestStreak: session.recommendationMomentumRescueBestStreak
                    )
                let recommendationMomentumRescueLeaderboardBadge =
                    topPicksRecommendationMomentumRescueLeaderboardBadgeModel
                let recommendationMomentumRescueLeaderboardCard =
                    topPicksRecommendationMomentumRescueLeaderboardCardModel
                let recommendationMomentumRescueHallOfFameBadge =
                    topPicksRecommendationMomentumRescueHallOfFameBadgeModel
                let recommendationMomentumRescueHallOfFameCard =
                    topPicksRecommendationMomentumRescueHallOfFameCardModel
                let recommendationMomentumRescueHallOfFameDefenseCue =
                    topPicksRecommendationMomentumRescueHallOfFameDefenseCueModel
                let recommendationMomentumRescuePlan = topPicksRecommendationMomentumRescuePlan
                let recommendationMomentumRescueAction = topPicksRecommendationMomentumRescueAction
                let recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt =
                    recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt()
                let recommendationMomentumRescueHallOfFameAutoDefenseStatus =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseStatus(
                        isEnabled: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
                        lastRunAt: recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt,
                        cooldownMinutes: settings
                            .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
                    )
                let recommendationMomentumRescueHallOfFameAutoDefenseBadge =
                    recommendationMomentumRescueHallOfFameDefenseCue.map { _ in
                        CommandPaletteTopPicks
                            .recommendationMomentumRescueHallOfFameAutoDefenseBadge(
                                status: recommendationMomentumRescueHallOfFameAutoDefenseStatus
                            )
                    }
                let recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge =
                    recommendationMomentumRescueHallOfFameAutoDefenseBadge.flatMap { _ in
                        CommandPaletteTopPicks
                            .recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                                lastRunAt: recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt,
                                maxAgeMinutes: max(
                                    20,
                                    settings
                                        .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes * 6
                                )
                            )
                    }
                let recommendationMomentumRescueHallOfFameAutoDefenseRunsTodayCount =
                    recommendationMomentumRescueHallOfFameAutoDefenseRunsToday()
                let recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics =
                    recommendationMomentumRescueHallOfFameAutoDefenseStreak()
                let recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics =
                    recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRuns()
                let recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory(
                        defaults: .standard,
                        historyKey: AppDefaults
                            .fameRecommendationMomentumRescueHallOfFameAutoDefenseLeagueHistoryKey,
                        limit: 6
                    )
                let recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend(
                        history: recommendationMomentumRescueHallOfFameAutoDefenseLeagueHistory,
                        sampleLimit: 4
                    )
                let recommendationMomentumRescueHallOfFameLegendRiskForecast =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameLegendRiskForecast(
                        status: recommendationMomentumRescueHallOfFameAutoDefenseStatus,
                        trend: recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend,
                        runsToday: recommendationMomentumRescueHallOfFameAutoDefenseRunsTodayCount,
                        currentWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.current,
                        bestWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.best,
                        currentStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.current,
                        bestStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.best,
                        enabledActionIDs: enabledActionIDs
                    )
                let recommendationMomentumRescueHallOfFameLegendRiskForecastAction: CommandPaletteAction? =
                    recommendationMomentumRescueHallOfFameLegendRiskForecast.flatMap { forecast in
                        guard let actionID = forecast.actionID else { return nil }
                        return matchedActions.first { $0.id == actionID && $0.isEnabled }
                    }
                let recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
                        currentStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.current,
                        bestStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.best
                    )
                let recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
                        currentWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.current,
                        bestWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.best
                    )
                let recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
                        status: recommendationMomentumRescueHallOfFameAutoDefenseStatus,
                        currentWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.current,
                        bestWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.best,
                        currentStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.current,
                        bestStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.best
                    )
                let recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress =
                    CommandPaletteTopPicks
                    .recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress(
                        status: recommendationMomentumRescueHallOfFameAutoDefenseStatus,
                        currentWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.current,
                        bestWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.best,
                        currentStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.current,
                        bestStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.best
                    )
                let recommendationMomentumRescueHallOfFameAutoDefenseScorecard =
                    recommendationMomentumRescueHallOfFameDefenseCue.map { _ in
                        CommandPaletteTopPicks
                            .recommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                                status: recommendationMomentumRescueHallOfFameAutoDefenseStatus,
                                runsToday: recommendationMomentumRescueHallOfFameAutoDefenseRunsTodayCount,
                                currentWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.current,
                                bestWeekRuns: recommendationMomentumRescueHallOfFameAutoDefenseWeeklyRunMetrics.best,
                                currentStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.current,
                                bestStreak: recommendationMomentumRescueHallOfFameAutoDefenseStreakMetrics.best
                            )
                    }
                let recommendationMomentumRescueConfidenceChip = recommendationMomentumRescuePlan
                    .map { plan in
                        CommandPaletteTopPicks.recommendationPairRescueConfidenceChip(plan: plan)
                    }
                let recommendationMomentumRescueFollowthroughCue = recommendationMomentumRescuePlan
                    .map { plan in
                        CommandPaletteTopPicks.recommendationMomentumRescueFollowthroughCue(
                            actionTitle: recommendationMomentumRescueAction?.title ?? "",
                            currentStreak: session.recommendationMomentumRescueStreak,
                            bestStreak: session.recommendationMomentumRescueBestStreak,
                            rescuePlan: plan
                        )
                    }
                let recommendationMomentumRescueCelebrationCue = visibleRecommendationMomentumRescuePulse
                    .map { pulse in
                        CommandPaletteTopPicks.recommendationMomentumRescueCelebrationCue(
                            pulse: pulse
                        )
                    }
                let topPicksStatusShortcutBadgeTitle = CommandPaletteTopPicks.statusShortcutBadgeTitle(
                    hasAutoOpsShortcut: autoOpsBundleStatusDedicatedShortcutAction != nil,
                    hasLaunchRescueShortcut: launchRescueAutoStatusDedicatedShortcutAction != nil
                )
                let topPicksStatusShortcutBadgeHelpText = CommandPaletteTopPicks.statusShortcutBadgeHelpText(
                    hasAutoOpsShortcut: autoOpsBundleStatusDedicatedShortcutAction != nil,
                    hasLaunchRescueShortcut: launchRescueAutoStatusDedicatedShortcutAction != nil
                ) ?? ""
                let fameMomentumPanelRouteStabilizationRecoveryPressureCalibration = session
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureCalibration
                let fameMomentumPanel = topPicksFameMomentumPanelModel
                let fameMomentumPanelAction: CommandPaletteAction? = fameMomentumPanel.flatMap { panel in
                    guard let actionID = panel.actionID else { return nil }
                    return matchedActions.first { $0.id == actionID && $0.isEnabled }
                }
                let fameMomentumPanelSecondaryAction: CommandPaletteAction? = fameMomentumPanel
                    .flatMap { panel in
                        guard let actionID = panel.secondaryActionID else { return nil }
                        return matchedActions.first { $0.id == actionID && $0.isEnabled }
                    }
                let fameMomentumPanelRouteStabilizationRecoveryAction: CommandPaletteAction? = fameMomentumPanel
                    .flatMap { panel in
                        guard let actionID = CommandPaletteTopPicks
                            .fameMomentumPanelRouteStabilizationRecoveryActionID(
                                primaryActionID: panel.actionID,
                                secondaryActionID: panel.secondaryActionID,
                                enabledActionIDs: enabledActionIDs,
                                availableActionIDs: Set(matchedActions.map(\.id)),
                                recoverySuggestionShownCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                                recoverySuggestionBlockedCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount,
                                recoverySuggestionRecoveryRunCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount,
                                recoverySuggestionUnblockRunCount: session
                                    .fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount,
                                pressureCalibration: fameMomentumPanelRouteStabilizationRecoveryPressureCalibration
                            ) else {
                            return nil
                        }
                        return matchedActions.first { $0.id == actionID }
                    }
                let fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge =
                    CommandPaletteTopPicks
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                        shownCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                        runCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount,
                        blockedCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount
                    )
                let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge =
                    CommandPaletteTopPicks
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                        shownCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                        blockedCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount,
                        recoveryRunCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionRecoveryRunCount,
                        unblockRunCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionUnblockRunCount,
                        pressureConfidenceHistory: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory,
                        pressureCalibration: fameMomentumPanelRouteStabilizationRecoveryPressureCalibration
                    )
                let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend =
                    CommandPaletteTopPicks
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend(
                        history: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceHistory
                    )
                let fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue =
                    CommandPaletteTopPicks
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue(
                        shownCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionShownCount,
                        runCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionRunCount,
                        blockedCount: session
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionBlockedCount,
                        pressureConfidenceBadge: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge,
                        pressureConfidenceTrend: fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceTrend,
                        actionID: fameMomentumPanelRouteStabilizationRecoveryAction?.id,
                        actionTitle: fameMomentumPanelRouteStabilizationRecoveryAction?.title,
                        hasRunnableAction: fameMomentumPanelRouteStabilizationRecoveryAction?.isEnabled == true
                    )
                let fameMomentumPanelRouteStabilizationRecoverySourceActionID = fameMomentumPanel?.actionID
                    ?? fameMomentumPanel?.secondaryActionID

                HStack(spacing: 8) {
                    Label("Top Picks", systemImage: "sparkles.rectangle.stack")
                        .font(.caption.weight(.semibold))
                    Text(topPickSummary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if showFameTopPicksExtras {
                    if let topPicksStatusShortcutBadgeTitle {
                        Label(topPicksStatusShortcutBadgeTitle, systemImage: "keyboard")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                            .help(topPicksStatusShortcutBadgeHelpText)
                    }

                    launchRecoveryHotKeyConfidenceBadge(launchRecoveryHotKeyReadiness)
                    launchRecoveryHotKeyDirectPromptBadge(launchRecoveryHotKeyReadiness)
                    launchRecoveryHotKeyTrendBadge(launchRecoveryHotKeyTrend)
                    launchRecoveryHotKeyWinMeterBadge(winMeter)
                    launchRecoveryHotKeyMomentumBadge(launchRecoveryHotKeyMomentum)
                    launchRecoveryHotKeyConfidenceScoreBadge(confidenceScore)

                    if let fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge {
                        topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
                            fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge,
                            diagnosticsCue: fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue,
                            action: fameMomentumPanelRouteStabilizationRecoveryAction
                        )
                    }

                    if let fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge {
                        topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
                            fameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge,
                            diagnosticsCue: fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue,
                            action: fameMomentumPanelRouteStabilizationRecoveryAction
                        )
                    }

                    if let bestChannelLaunchPackPressureBadgeTitle {
                        Label(
                            bestChannelLaunchPackPressureBadgeTitle,
                            systemImage: CommandPaletteTopPicks.bestChannelLaunchPackPressureBadgeSystemImage(
                                tone: session.bestChannelLaunchPackPressureLastTone
                            )
                        )
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            bestChannelLaunchPackPressureBadgeBackgroundColor(
                                session.bestChannelLaunchPackPressureLastTone
                            )
                        )
                        .clipShape(Capsule())
                        .help(bestChannelLaunchPackPressurePerformanceLine)
                    }

                    if bestChannelLaunchPackPressureCard != nil,
                       let bestChannelLaunchPackPressureModeBadgeTitle {
                        Label(
                            bestChannelLaunchPackPressureModeBadgeTitle,
                            systemImage: CommandPaletteTopPicks
                                .bestChannelLaunchPackPressureModeBadgeSystemImage(
                                    trend: bestChannelLaunchPackPressureTrend
                                )
                        )
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            bestChannelLaunchPackPressureModeBadgeBackgroundColor(
                                bestChannelLaunchPackPressureTrend
                            )
                        )
                        .clipShape(Capsule())
                        .help(bestChannelLaunchPackPressureModeBadgeHelpText)
                    }

                    if let onboardingRecoveryBadgeTitle,
                       let onboardingRecoveryBadgeSystemImage {
                        Label(onboardingRecoveryBadgeTitle, systemImage: onboardingRecoveryBadgeSystemImage)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.16))
                            .clipShape(Capsule())
                            .help(onboardingRecoveryBadgeHelpText)

                        if let recoveryQuickRunAction = onboardingRecoveryQuickRunAction {
                            Button("Run Next") {
                                run(recoveryQuickRunAction)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                            .help(
                                "Run \(recoveryQuickRunAction.title). \(onboardingRecoveryBadgeHelpText)"
                            )
                        }
                    }

                    if session.topPickRunStreak >= 2 {
                        topPickStreakBadge
                    }

                    if let recommendationMomentumRescueLaneBadge {
                        topPicksRecommendationMomentumRescueLaneBadge(
                            recommendationMomentumRescueLaneBadge
                        )
                    }

                    if let recommendationMomentumRescueLeaderboardBadge {
                        topPicksRecommendationMomentumRescueLeaderboardBadge(
                            recommendationMomentumRescueLeaderboardBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameBadge {
                        topPicksRecommendationMomentumRescueHallOfFameBadge(
                            recommendationMomentumRescueHallOfFameBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameAutoDefenseBadge {
                        topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                            recommendationMomentumRescueHallOfFameAutoDefenseBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge {
                        topPicksRecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                            recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge {
                        topPicksRecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
                            recommendationMomentumRescueHallOfFameAutoDefenseStreakBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge {
                        topPicksRecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
                            recommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge {
                        topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
                            recommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge
                        )
                    }

                    if let recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend {
                        topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendBadge(
                            recommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend
                        )
                    }

                    if shouldShowCadenceExecutionKitStreakBadge {
                        cadenceExecutionKitStreakBadge(
                            cadenceExecutionKitStreak,
                            bestStreak: cadenceExecutionKitBestStreak
                        )
                    }

                    topPicksPulseBadges

                    if let recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion {
                        recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadge(
                            recommendationMomentumRescueHallOfFameLegendRiskStickyPromotion
                        )
                    }

                    if let launchRecoveryHotKeyLegendRiskStickyPromotion {
                        launchRecoveryHotKeyLegendRiskStickyPromotionBadge(
                            launchRecoveryHotKeyLegendRiskStickyPromotion
                        )
                    }

                    if let launchRecoveryHotKeyInterventionTrustMomentum {
                        launchRecoveryHotKeyInterventionTrustMomentumBadge(
                            launchRecoveryHotKeyInterventionTrustMomentum
                        )
                    }

                    if let autoTrustSurgeBadge {
                        launchRecoveryHotKeyAutoTrustSurgeBadge(autoTrustSurgeBadge)
                    }

                    if let autoTrustSurgeRecencyBadge {
                        launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(autoTrustSurgeRecencyBadge)
                    }

                    if let autoTrustSurgeLeagueBadge {
                        launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(autoTrustSurgeLeagueBadge)
                    }

                    if let autoTrustSurgeLeagueTrend {
                        launchRecoveryHotKeyAutoTrustSurgeLeagueTrendBadge(autoTrustSurgeLeagueTrend)
                    }

                    if autoTrustSurgeStreak.current > 0 {
                        launchRecoveryHotKeyAutoTrustSurgeStreakBadge(
                            currentStreak: autoTrustSurgeStreak.current,
                            bestStreak: autoTrustSurgeStreak.best
                        )
                    }

                    if autoTrustSurgeWeeklyRuns.current > 0 {
                        launchRecoveryHotKeyAutoTrustSurgeWeeklyBadge(
                            currentWeekRuns: autoTrustSurgeWeeklyRuns.current,
                            bestWeekRuns: autoTrustSurgeWeeklyRuns.best
                        )
                    }
                    } // end showFameTopPicksExtras (Top Picks header chips)
                }

                if showFameTopPicksExtras {
                if let fameMomentumPanel {
                    topPicksFameMomentumPanelCard(
                        fameMomentumPanel,
                        action: fameMomentumPanelAction,
                        secondaryAction: fameMomentumPanelSecondaryAction,
                        recoverySuggestionAction: fameMomentumPanelRouteStabilizationRecoveryAction
                    )
                }

                if let fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue {
                    topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCard(
                        fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue,
                        action: fameMomentumPanelRouteStabilizationRecoveryAction,
                        sourceActionID: fameMomentumPanelRouteStabilizationRecoverySourceActionID,
                        isFocused: isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused
                    )
                }

                if let recommendationMomentumRescueLaneDetailLine,
                   let recommendationMomentumRescueLaneBadge {
                    HStack(alignment: .center, spacing: 8) {
                        Text(recommendationMomentumRescueLaneDetailLine)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(
                                recommendationMomentumRescueLaneBadge.tone == .active
                                    ? Color.orange
                                    : Color.secondary
                            )
                            .lineLimit(2)

                        if let recommendationMomentumRescueAction,
                           let recommendationMomentumRescuePlan,
                           let recommendationMomentumRescueConfidenceChip {
                            topPicksRecommendationMomentumRescueConfidenceChip(
                                recommendationMomentumRescueConfidenceChip
                            )

                            Button("Rescue Now") {
                                runRecommendationMomentumRescueAction(
                                    recommendationMomentumRescueAction,
                                    plan: recommendationMomentumRescuePlan
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                            .help(
                                "Run \(recommendationMomentumRescueAction.title) to recover the coldest high-confidence recommendation lane now."
                            )
                        }
                    }
                }

                if let recommendationMomentumRescueLeaderboardCard {
                    topPicksRecommendationMomentumRescueLeaderboardCard(
                        recommendationMomentumRescueLeaderboardCard
                    )
                }

                if let recommendationMomentumRescueHallOfFameCard {
                    topPicksRecommendationMomentumRescueHallOfFameCard(
                        recommendationMomentumRescueHallOfFameCard
                    )
                }

                if let recommendationMomentumRescueHallOfFameDefenseCue {
                    topPicksRecommendationMomentumRescueHallOfFameDefenseCueCard(
                        recommendationMomentumRescueHallOfFameDefenseCue,
                        action: recommendationMomentumRescueAction,
                        plan: recommendationMomentumRescuePlan,
                        autoDefenseBadge: recommendationMomentumRescueHallOfFameAutoDefenseBadge,
                        autoDefenseRecencyBadge:
                            recommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge
                    )
                }

                if let recommendationMomentumRescueHallOfFameAutoDefenseScorecard {
                    topPicksRecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
                        recommendationMomentumRescueHallOfFameAutoDefenseScorecard
                    )
                }

                if let recommendationMomentumRescueHallOfFameLegendRiskForecast {
                    topPicksRecommendationMomentumRescueHallOfFameLegendRiskForecastCard(
                        recommendationMomentumRescueHallOfFameLegendRiskForecast,
                        action: recommendationMomentumRescueHallOfFameLegendRiskForecastAction,
                        plan: recommendationMomentumRescuePlan
                    )
                }

                if let recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress {
                    topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgressCard(
                        recommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress
                    )
                }

                if let visibleRecommendationMomentumRescueWeeklyRecordPulse {
                    topPicksRecommendationMomentumRescueWeeklyRecordCard(
                        visibleRecommendationMomentumRescueWeeklyRecordPulse
                    )
                }

                if let visibleRecommendationMomentumRescueImpactPulse,
                   let recommendationMomentumRescueFollowthroughCue {
                    topPicksRecommendationMomentumRescueFollowthroughCard(
                        recommendationMomentumRescueFollowthroughCue,
                        pulse: visibleRecommendationMomentumRescueImpactPulse
                    )
                }

                if let visibleRecommendationMomentumRescuePulse,
                   let recommendationMomentumRescueCelebrationCue {
                    topPicksRecommendationMomentumRescueCelebrationCard(
                        recommendationMomentumRescueCelebrationCue,
                        pulse: visibleRecommendationMomentumRescuePulse
                    )
                }

                if confidenceNeedsAttention {
                    launchRecoveryHotKeyConfidenceScoreCard(
                        confidenceScore,
                        interventions: confidenceInterventions,
                        interventionTrustTrend: launchRecoveryHotKeyInterventionTrustTrend
                    )
                } else if let coachCue = launchRecoveryHotKeyCoachCue {
                    launchRecoveryHotKeyCoachCard(
                        coachCue,
                        action: launchRecoveryHotKeyCoachAction
                    )
                }

                if let winMeter {
                    launchRecoveryHotKeyWinMeterCard(winMeter)
                }

                if let momentumRescue {
                    launchRecoveryHotKeyMomentumRescueCard(
                        momentumRescue,
                        action: momentumRescueAction,
                        autoRescueBadge: autoRescueBadge,
                        autoRescueRecencyBadge: autoRescueRecencyBadge
                    )
                }

                if let bestChannelLaunchPackPressureCard,
                   let bestChannelLaunchPackAction {
                    bestChannelLaunchPackGuidanceCard(
                        bestChannelLaunchPackPressureCard,
                        action: bestChannelLaunchPackAction,
                        trend: bestChannelLaunchPackPressureTrend,
                        performanceLine: bestChannelLaunchPackPressurePerformanceLine
                    )
                }

                if !confidenceNeedsAttention,
                   let trustGuard = launchRecoveryHotKeyInterventionTrustGuard {
                    launchRecoveryHotKeyInterventionTrustGuardCard(
                        trustGuard,
                        action: launchRecoveryHotKeyInterventionTrustGuardAction
                    )
                }

                if !confidenceNeedsAttention,
                   let trustMomentumPlan {
                    launchRecoveryHotKeyInterventionTrustMomentumCard(
                        trustMomentumPlan,
                        action: trustMomentumPlanAction,
                        autoTrustSurgeBadge: autoTrustSurgeBadge,
                        autoTrustSurgeRecencyBadge: autoTrustSurgeRecencyBadge
                    )
                }

                if !confidenceNeedsAttention,
                   let autoTrustSurgeInsight {
                    launchRecoveryHotKeyAutoTrustSurgeInsightCard(autoTrustSurgeInsight)
                }

                if !confidenceNeedsAttention,
                   let autoTrustSurgeLeagueProgress {
                    launchRecoveryHotKeyAutoTrustSurgeLeagueProgressCard(autoTrustSurgeLeagueProgress)
                }

                if !confidenceNeedsAttention,
                   let autoTrustSurgeLegendDefense {
                    launchRecoveryHotKeyAutoTrustSurgeLegendDefenseCard(
                        autoTrustSurgeLegendDefense,
                        action: autoTrustSurgeLegendDefenseAction
                    )
                }

                if !confidenceNeedsAttention,
                   let autoTrustSurgeLegendDecayForecast {
                    launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastCard(
                        autoTrustSurgeLegendDecayForecast,
                        action: autoTrustSurgeLegendDecayForecastAction
                    )
                }

                if shouldShowCadenceExecutionKitMomentumCard {
                    cadenceExecutionKitMomentumCard
                }
                } // end showFameTopPicksExtras (Top Picks cards)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topPickActions) { action in
                            topPickButton(action)
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var topPicksPulseBadges: some View {
        if let visibleTopPickMilestone {
            topPickMilestoneBadge(visibleTopPickMilestone)
        }

        if let visibleCadenceExecutionKitMomentumPulse {
            cadenceExecutionKitMomentumPulseBadge(visibleCadenceExecutionKitMomentumPulse)
        }

        if let visibleLaunchRecoveryHotKeyRestorePulse {
            launchRecoveryHotKeyRestorePulseBadge(visibleLaunchRecoveryHotKeyRestorePulse)
        }

        if let visibleLaunchRecoveryHotKeyDecayPulse {
            launchRecoveryHotKeyDecayPulseBadge(visibleLaunchRecoveryHotKeyDecayPulse)
        }

        if let visibleLaunchRecoveryHotKeyConfidencePulse {
            launchRecoveryHotKeyConfidencePulseBadge(visibleLaunchRecoveryHotKeyConfidencePulse)
        }

        if let visibleLaunchRecoveryHotKeyMomentumPulse {
            launchRecoveryHotKeyMomentumPulseBadge(visibleLaunchRecoveryHotKeyMomentumPulse)
        }

        if let visibleLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse {
            launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseBadge(
                visibleLaunchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulse
            )
        }

        if let visibleLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse {
            launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseBadge(
                visibleLaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse
            )
        }

        if let visibleLaunchRecoveryHotKeyLegendRiskStickyReleasePulse {
            launchRecoveryHotKeyLegendRiskStickyReleasePulseBadge(
                visibleLaunchRecoveryHotKeyLegendRiskStickyReleasePulse
            )
        }

        if let visibleLaunchRecoveryHotKeyInterventionTrustPulse {
            launchRecoveryHotKeyInterventionTrustPulseBadge(
                visibleLaunchRecoveryHotKeyInterventionTrustPulse
            )
        }

        if let visibleLaunchRecoveryHotKeyInterventionTrustMomentumPulse {
            launchRecoveryHotKeyInterventionTrustMomentumPulseBadge(
                visibleLaunchRecoveryHotKeyInterventionTrustMomentumPulse
            )
        }

        if let visibleRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse {
            recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseBadge(
                visibleRecommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulse
            )
        }

        if let visibleRecommendationMomentumRescueHallOfFameLegendRiskPulse {
            recommendationMomentumRescueHallOfFameLegendRiskPulseBadge(
                visibleRecommendationMomentumRescueHallOfFameLegendRiskPulse
            )
        }

        if let visibleRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse {
            recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseBadge(
                visibleRecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse
            )
        }

        if let visibleRecommendationMomentumRescueImpactPulse {
            recommendationMomentumRescueImpactPulseBadge(
                visibleRecommendationMomentumRescueImpactPulse
            )
        }

        if let visibleRecommendationMomentumRescuePulse {
            recommendationMomentumRescuePulseBadge(visibleRecommendationMomentumRescuePulse)
        }

        if let visibleRecommendationMomentumRescueWeeklyRecordPulse {
            recommendationMomentumRescueWeeklyRecordPulseBadge(
                visibleRecommendationMomentumRescueWeeklyRecordPulse
            )
        }

        if let visibleRecommendationConversionPulse {
            recommendationConversionPulseBadge(visibleRecommendationConversionPulse)
        }

        if let visibleFameMomentumPanelLearningPulse {
            fameMomentumPanelLearningPulseBadge(visibleFameMomentumPanelLearningPulse)
        }

        if let visibleFameMomentumPanelRouteFlipPulse {
            fameMomentumPanelRouteFlipPulseBadge(visibleFameMomentumPanelRouteFlipPulse)
        }

        if let visibleFameMomentumPanelRouteStabilizationPulse {
            fameMomentumPanelRouteStabilizationPulseBadge(
                visibleFameMomentumPanelRouteStabilizationPulse
            )
        }
    }

    private func topPickButton(_ action: CommandPaletteAction) -> some View {
        let isHighlighted = highlightedTopPickIDs.contains(action.id)

        return Button {
            run(action)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: action.systemImage)
                    .font(.caption.weight(.semibold))
                    .frame(width: 16)
                Text(action.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isHighlighted
                    ? Color.accentColor.opacity(0.25)
                    : Color.accentColor.opacity(0.14)
            )
            .overlay {
                if isHighlighted {
                    Capsule()
                        .stroke(Color.accentColor.opacity(0.38), lineWidth: 1)
                }
            }
            .scaleEffect(isHighlighted ? 1.02 : 1)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.76), value: isHighlighted)
    }

    private func focusFameMomentumPanelRouteStabilizationRecoveryDiagnostics(
        actionID: String?
    ) {
        fameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocusTask?.cancel()
        if let actionID,
           filteredActions.contains(where: { $0.id == actionID }) {
            selectedActionID = actionID
        }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
            isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused = true
        }
        fameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocusTask = Task {
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused = false
                }
            }
        }
    }

    private func clearFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocus() {
        fameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocusTask?.cancel()
        fameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocusTask = nil
        isFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocused = false
    }

    private var topPickStreakBadge: some View {
        let streakCount = session.topPickRunStreak
        let streakSymbol = streakCount >= 5 ? "flame.fill" : "bolt.fill"

        return Label("x\(streakCount)", systemImage: streakSymbol)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.16))
            .clipShape(Capsule())
            .help("Top Picks streak: \(streakCount). Best: \(session.bestTopPickRunStreak).")
    }

    private func topPicksFameMomentumPanelCard(
        _ panel: CommandPaletteTopPicks.FameMomentumPanel,
        action: CommandPaletteAction?,
        secondaryAction: CommandPaletteAction?,
        recoverySuggestionAction: CommandPaletteAction?
    ) -> some View {
        let telemetryToken = "\(session.openCount)|\(panel.actionID ?? "none")|\(panel.secondaryActionID ?? "none")"
        let sourceActionID = panel.actionID ?? panel.secondaryActionID
        let trustTrendToken = fameMomentumPanelTrustTrendTransitionToken(
            actionID: panel.actionID,
            trustTrend: panel.interventionTrustTrend
        )
        let isTrustFlipCelebrationActive = isFameMomentumPanelTrustFlipCelebrationActive
            && activeFameMomentumPanelTrustFlipToken == trustTrendToken
        let routeFlipPulse: CommandPaletteSession.FameMomentumPanelRouteFlipPulse? = {
            guard let pulse = visibleFameMomentumPanelRouteFlipPulse else { return nil }
            let currentPrompt = normalizedFameMomentumPanelPrompt(panel.actionPrompt)
            let nextPrompt = pulse.nextActionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !currentPrompt.isEmpty,
                  currentPrompt == nextPrompt else {
                return nil
            }
            return pulse
        }()
        let routeStabilizationPulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse? = {
            guard panel.routeFlipRhythmTone == .volatile else { return nil }
            return visibleFameMomentumPanelRouteStabilizationPulse
        }()
        let hasDistinctSecondaryAction = secondaryAction.map { secondary in
            guard let action else { return true }
            return secondary.id != action.id
        } ?? false
        let routeStabilizationScoreboard = session.fameMomentumPanelRouteStabilizationScoreboard()
        let routeStabilizationCue = CommandPaletteTopPicks.fameMomentumPanelRouteStabilizationCue(
            rhythmTone: panel.routeFlipRhythmTone,
            stabilizationPulse: routeStabilizationPulse,
            selectionConfidence: panel.selectionConfidence,
            hasSecondaryAction: hasDistinctSecondaryAction,
            stabilizationScoreboard: routeStabilizationScoreboard
        )
        let isRouteStabilizationResetCueActive = routeStabilizationCue?.focus == .primaryReset
        let routeStabilizationRecoverySuggestion: CommandPaletteSession
            .FameMomentumPanelRouteStabilizationRecoverySuggestion? = {
                guard isRouteStabilizationResetCueActive else { return nil }
                return session.fameMomentumPanelRouteStabilizationRecoverySuggestion()
            }()
        let shouldShowSecondaryActionButton = hasDistinctSecondaryAction
            && (routeStabilizationCue == nil || routeStabilizationCue?.secondaryButtonTitle != nil)

        return HStack(spacing: 9) {
            Image(systemName: panel.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(topPicksFameMomentumPanelForegroundColor(panel.tone))

            VStack(alignment: .leading, spacing: 2) {
                Text(panel.title)
                    .font(.caption.weight(.semibold))
                Text(panel.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let selectionConfidence = panel.selectionConfidence {
                    topPicksFameMomentumPanelSelectionConfidenceRow(
                        selectionConfidence
                    )
                }

                if !panel.reasonChips.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(panel.reasonChips) { chip in
                            Label(chip.title, systemImage: chip.systemImage)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(Capsule())
                                .help(chip.helpText)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                if let trustTrend = panel.interventionTrustTrend {
                    HStack(spacing: 6) {
                        Label(trustTrend.title, systemImage: trustTrend.systemImage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(
                                launchRecoveryHotKeyInterventionTrustTrendForegroundColor(
                                    trustTrend.direction
                                )
                            )
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Text(trustTrend.subtitle)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)

                        launchRecoveryHotKeyInterventionTrustSparkline(
                            trustTrend.samples,
                            direction: trustTrend.direction
                        )
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(
                        Color.primary.opacity(
                            isTrustFlipCelebrationActive ? 0.12 : 0.06
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(
                                Color.mint.opacity(0.82),
                                lineWidth: 1.2
                            )
                            .scaleEffect(isTrustFlipCelebrationActive ? 1.06 : 1)
                            .opacity(isTrustFlipCelebrationActive ? 0.88 : 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .scaleEffect(isTrustFlipCelebrationActive ? 1.02 : 1)
                    .help(trustTrend.helpText)
                }

                if let routeFlipPulse {
                    topPicksFameMomentumPanelRouteFlipInsightDisclosure(routeFlipPulse)
                }

                if let routeStabilizationCue {
                    topPicksFameMomentumPanelRouteStabilizationCueRow(routeStabilizationCue)
                }

                if let routeStabilizationRecoverySuggestion {
                    topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionRow(
                        routeStabilizationRecoverySuggestion,
                        action: recoverySuggestionAction,
                        sourceActionID: sourceActionID
                    )
                }

                if let routeStabilizationScoreboard {
                    topPicksFameMomentumPanelRouteStabilizationScoreboardRow(
                        routeStabilizationScoreboard
                    )
                }
            }

            Spacer(minLength: 6)

            if let action {
                let actionEmphasis = CommandPaletteTopPicks.fameMomentumPanelActionEmphasis(
                    selectionConfidence: panel.selectionConfidence,
                    hasSecondaryAction: hasDistinctSecondaryAction,
                    routeFlipRhythmTone: panel.routeFlipRhythmTone
                )
                let actionPrompts = CommandPaletteTopPicks.fameMomentumPanelResolvedActionPrompts(
                    primaryPrompt: panel.actionPrompt,
                    secondaryPrompt: panel.secondaryActionPrompt,
                    selectionConfidence: panel.selectionConfidence,
                    actionEmphasis: actionEmphasis,
                    hasSecondaryAction: hasDistinctSecondaryAction
                )
                let labelExplanation = CommandPaletteTopPicks.fameMomentumPanelActionLabelExplanation(
                    selectionConfidence: panel.selectionConfidence,
                    actionEmphasis: actionEmphasis,
                    hasSecondaryAction: hasDistinctSecondaryAction,
                    routeFlipRhythmTone: panel.routeFlipRhythmTone
                )
                let primaryButtonTitle = routeStabilizationCue?.buttonTitle ?? actionPrompts.primary
                let secondaryButtonTitle = routeStabilizationCue?.secondaryButtonTitle
                    ?? actionPrompts.secondary
                    ?? "Run Backup"
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 6) {
                        if actionEmphasis == .splitDecision {
                            Button(primaryButtonTitle) {
                                run(
                                    action,
                                    fameMomentumPanelSourceActionID: sourceActionID,
                                    fameMomentumPanelRouteStabilizationActive: routeStabilizationCue != nil
                                )
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .disabled(!action.isEnabled)
                            .help("Top-ranked route by a slim margin: \(action.title).")
                        } else {
                            Button(primaryButtonTitle) {
                                run(
                                    action,
                                    fameMomentumPanelSourceActionID: sourceActionID,
                                    fameMomentumPanelRouteStabilizationActive: routeStabilizationCue != nil
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.mini)
                            .disabled(!action.isEnabled)
                            .help("Run \(action.title) to keep Fame momentum compounding.")
                        }

                        if let secondaryAction,
                           shouldShowSecondaryActionButton {
                            if actionEmphasis == .splitDecision {
                                Button(secondaryButtonTitle) {
                                    run(
                                        secondaryAction,
                                        fameMomentumPanelSourceActionID: sourceActionID,
                                        fameMomentumPanelRouteStabilizationActive: routeStabilizationCue != nil
                                    )
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.mini)
                                .disabled(!secondaryAction.isEnabled)
                                .help("Split confidence: alternate route is co-primary (\(secondaryAction.title)).")
                            } else {
                                Button(secondaryButtonTitle) {
                                    run(
                                        secondaryAction,
                                        fameMomentumPanelSourceActionID: sourceActionID,
                                        fameMomentumPanelRouteStabilizationActive: routeStabilizationCue != nil
                                    )
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                                .disabled(!secondaryAction.isEnabled)
                                .help("Backup route: \(secondaryAction.title). Run it when the primary step is blocked.")
                            }
                        }
                    }

                    if let labelExplanation {
                        Label("Why labels", systemImage: "questionmark.circle")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .help(labelExplanation)
                    }
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(topPicksFameMomentumPanelBackgroundColor(panel.tone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(panel.helpText)
        .onAppear {
            _ = session.recordFameMomentumPanelOpportunity(
                actionIDs: [panel.actionID, panel.secondaryActionID]
            )
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: panel.actionID,
                actionPrompt: panel.actionPrompt,
                actionScore: panel.actionScore,
                reasonChips: panel.reasonChips,
                selectionConfidence: panel.selectionConfidence,
                actionRecency: panel.actionRecency
            )
            if isRouteStabilizationResetCueActive {
                _ = session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded()
            }
        }
        .onChange(of: telemetryToken) { _, _ in
            _ = session.recordFameMomentumPanelOpportunity(
                actionIDs: [panel.actionID, panel.secondaryActionID]
            )
            session.recordFameMomentumPanelPrimarySuggestion(
                actionID: panel.actionID,
                actionPrompt: panel.actionPrompt,
                actionScore: panel.actionScore,
                reasonChips: panel.reasonChips,
                selectionConfidence: panel.selectionConfidence,
                actionRecency: panel.actionRecency
            )
            if isRouteStabilizationResetCueActive {
                _ = session.recordFameMomentumPanelRouteStabilizationResetCueIfNeeded()
            }
            if routeStabilizationRecoverySuggestion != nil {
                _ = session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionExposure(
                    action: recoverySuggestionAction
                )
            }
        }
    }

    private func normalizedFameMomentumPanelPrompt(_ prompt: String?) -> String {
        guard let prompt else { return "" }
        return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func topPicksFameMomentumPanelRouteFlipInsightDisclosure(
        _ pulse: CommandPaletteSession.FameMomentumPanelRouteFlipPulse
    ) -> some View {
        let recentFlips = Array(session.fameMomentumPanelRouteFlipHistory.prefix(3))
        let routeFlipRhythm = session.fameMomentumPanelRouteFlipRhythm()

        return DisclosureGroup(
            isExpanded: $isFameMomentumPanelRouteFlipInsightExpanded
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pulse.previousActionPrompt) → \(pulse.nextActionPrompt)")
                    .font(.caption2.weight(.semibold))

                if let confidenceDeltaPoints = pulse.confidenceDeltaPoints {
                    let signedDelta = confidenceDeltaPoints > 0
                        ? "+\(confidenceDeltaPoints)"
                        : "\(confidenceDeltaPoints)"
                    Text("Confidence gap Δ\(signedDelta) points.")
                }

                if let previousSignalAgeOpens = pulse.previousSignalAgeOpens,
                   let nextSignalAgeOpens = pulse.nextSignalAgeOpens {
                    Text(
                        "Signal age \(previousSignalAgeOpens) → \(nextSignalAgeOpens) open(s)."
                    )
                } else if let nextSignalAgeOpens = pulse.nextSignalAgeOpens {
                    Text("Signal age now \(nextSignalAgeOpens) open(s).")
                }

                if let previousActionScore = pulse.previousActionScore,
                   let nextActionScore = pulse.nextActionScore {
                    HStack(spacing: 8) {
                        topPicksFameMomentumPanelRouteScoreSparkline(
                            previousScore: previousActionScore,
                            nextScore: nextActionScore
                        )

                        let scoreDelta = nextActionScore - previousActionScore
                        let signedDelta = scoreDelta > 0 ? "+\(scoreDelta)" : "\(scoreDelta)"
                        Text("Score \(previousActionScore) → \(nextActionScore) (\(signedDelta))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if !recentFlips.isEmpty {
                    Divider()
                        .padding(.vertical, 1)

                    Text("Last \(recentFlips.count) flips")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(Array(recentFlips.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 6) {
                            Text(topPicksFameMomentumPanelRouteFlipTriggerTag(entry.trigger))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.mint)

                            Text("Open \(entry.openCount)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)

                            Text("\(entry.previousActionPrompt)→\(entry.nextActionPrompt)")
                                .lineLimit(1)

                            Spacer(minLength: 4)

                            Text(
                                topPicksFameMomentumPanelRouteFlipMetricToken(
                                    prefix: "Δscore",
                                    value: entry.routeScoreDelta
                                )
                            )
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)

                            Text(
                                topPicksFameMomentumPanelRouteFlipMetricToken(
                                    prefix: "Δgap",
                                    value: entry.confidenceDeltaPoints
                                )
                            )
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                if let routeFlipRhythm {
                    topPicksFameMomentumPanelRouteFlipRhythmRow(routeFlipRhythm)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        } label: {
            Label("Why it flipped", systemImage: "arrow.triangle.2.circlepath")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.mint)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(Color.mint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(pulse.helpText)
    }

    private func topPicksFameMomentumPanelRouteStabilizationCueRow(
        _ cue: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationCue
    ) -> some View {
        HStack(spacing: 6) {
            Label(cue.title, systemImage: cue.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(cue.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(cue.helpText)
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionRow(
        _ suggestion: CommandPaletteSession.FameMomentumPanelRouteStabilizationRecoverySuggestion,
        action: CommandPaletteAction?,
        sourceActionID: String?
    ) -> some View {
        HStack(spacing: 6) {
            Label(suggestion.title, systemImage: suggestion.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.mint)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(suggestion.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let action {
                let recoverySuggestionButtonTitle = CommandPaletteTopPicks
                    .fameMomentumPanelRouteStabilizationRecoverySuggestionButtonTitle(
                        defaultTitle: suggestion.buttonTitle,
                        actionID: action.id,
                        actionTitle: action.title
                    )
                Button(recoverySuggestionButtonTitle) {
                    _ = session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun(
                        usedUnblockAction: CommandPaletteTopPicks
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionUsesUnblockAction(
                                actionID: action.id,
                                actionTitle: action.title
                            )
                    )
                    run(
                        action,
                        fameMomentumPanelSourceActionID: sourceActionID,
                        fameMomentumPanelRouteStabilizationActive: true
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help(
                    action.isEnabled
                        ? "Run \(action.title) to execute the recovery loop now."
                        : "Recovery command is unavailable: \(action.disabledReason)."
                )
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.mint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(suggestion.helpText)
    }

    private func topPicksFameMomentumPanelRouteStabilizationScoreboardRow(
        _ scoreboard: CommandPaletteSession.FameMomentumPanelRouteStabilizationScoreboard
    ) -> some View {
        HStack(spacing: 6) {
            Label(scoreboard.title, systemImage: scoreboard.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(scoreboard.subtitle)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(scoreboard.helpText)
    }

    private func topPicksFameMomentumPanelRouteScoreSparkline(
        previousScore: Int,
        nextScore: Int
    ) -> some View {
        let lineColor: Color = nextScore >= previousScore ? .mint : .orange

        return GeometryReader { geometry in
            let chartWidth = max(24, geometry.size.width)
            let chartHeight = max(10, geometry.size.height)
            let startX = CGFloat(4)
            let endX = chartWidth - 4
            let maxScore = max(previousScore, nextScore) + 6
            let minScore = min(previousScore, nextScore) - 6
            let scoreRange = max(1, maxScore - minScore)
            let yForScore: (Int) -> CGFloat = { score in
                let normalized = CGFloat(score - minScore) / CGFloat(scoreRange)
                return (chartHeight - 2) - (normalized * (chartHeight - 4))
            }
            let startY = yForScore(previousScore)
            let endY = yForScore(nextScore)

            ZStack {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 2)
                    .position(x: chartWidth / 2, y: chartHeight / 2)

                Path { path in
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(lineColor.opacity(0.92), lineWidth: 2)

                Circle()
                    .fill(Color.secondary.opacity(0.92))
                    .frame(width: 4, height: 4)
                    .position(x: startX, y: startY)

                Circle()
                    .fill(lineColor.opacity(0.96))
                    .frame(width: 5, height: 5)
                    .position(x: endX, y: endY)
            }
        }
        .frame(width: 68, height: 16)
        .help("Before/after route score trend for the latest flip.")
    }

    private func topPicksFameMomentumPanelRouteFlipRhythmRow(
        _ rhythm: CommandPaletteSession.FameMomentumPanelRouteFlipRhythm
    ) -> some View {
        let rowColor = topPicksFameMomentumPanelRouteFlipRhythmColor(rhythm.tone)

        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Label(rhythm.title, systemImage: rhythm.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(rowColor)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text("\(rhythm.flipCount)/\(rhythm.openSpan)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Text(rhythm.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(
                    topPicksFameMomentumPanelRouteFlipAverageMetricToken(
                        prefix: "avgΔscore",
                        value: rhythm.averageAbsRouteScoreDelta
                    )
                )
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

                Text(
                    topPicksFameMomentumPanelRouteFlipAverageMetricToken(
                        prefix: "avgΔgap",
                        value: rhythm.averageAbsConfidenceDeltaPoints
                    )
                )
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(rowColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(rhythm.helpText)
    }

    private func topPicksFameMomentumPanelRouteFlipMetricToken(
        prefix: String,
        value: Int?
    ) -> String {
        guard let value else { return "\(prefix) —" }
        let signedValue = value > 0 ? "+\(value)" : "\(value)"
        return "\(prefix) \(signedValue)"
    }

    private func topPicksFameMomentumPanelRouteFlipAverageMetricToken(
        prefix: String,
        value: Int?
    ) -> String {
        guard let value else { return "\(prefix) —" }
        return "\(prefix) \(value)"
    }

    private func topPicksFameMomentumPanelRouteFlipTriggerTag(
        _ trigger: CommandPaletteSession.FameMomentumPanelRouteFlipPulse.Trigger
    ) -> String {
        switch trigger {
        case .freshSignal:
            return "Fresh"
        case .momentumSurge:
            return "Surge"
        case .tightDecision:
            return "Tight"
        case .rerank:
            return "Rerank"
        }
    }

    private func topPicksFameMomentumPanelRouteFlipRhythmColor(
        _ tone: CommandPaletteSession.FameMomentumPanelRouteFlipRhythm.Tone
    ) -> Color {
        switch tone {
        case .stabilizing:
            return .green
        case .watch:
            return .orange
        case .volatile:
            return .red
        }
    }

    private func topPicksFameMomentumPanelSelectionConfidenceRow(
        _ confidence: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidence
    ) -> some View {
        let rowColor = topPicksFameMomentumPanelSelectionConfidenceColor(
            confidence.tier
        )
        let fillWidth = max(3, CGFloat(confidence.confidencePercent) * 0.68)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Label(confidence.title, systemImage: confidence.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(rowColor)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text("\(confidence.confidencePercent)%")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Capsule()
                    .fill(Color.primary.opacity(0.14))
                    .frame(width: 68, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(rowColor.opacity(0.88))
                            .frame(width: fillWidth, height: 4)
                    }

                Text(confidence.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(rowColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(confidence.helpText)
    }

    private func topPicksFameMomentumPanelSelectionConfidenceColor(
        _ tier: CommandPaletteTopPicks.FameMomentumPanelSelectionConfidenceTier
    ) -> Color {
        switch tier {
        case .locked:
            return .green
        case .leaning:
            return .blue
        case .split:
            return .orange
        }
    }

    private func topPicksFameMomentumPanelForegroundColor(
        _ tone: CommandPaletteTopPicks.FameMomentumPanelTone
    ) -> Color {
        switch tone {
        case .alert:
            return Color.red
        case .watch:
            return Color.orange
        case .steady:
            return Color.blue
        case .prime:
            return Color.mint
        }
    }

    private func topPicksFameMomentumPanelBackgroundColor(
        _ tone: CommandPaletteTopPicks.FameMomentumPanelTone
    ) -> Color {
        switch tone {
        case .alert:
            return Color.red.opacity(0.12)
        case .watch:
            return Color.orange.opacity(0.12)
        case .steady:
            return Color.blue.opacity(0.12)
        case .prime:
            return Color.mint.opacity(0.12)
        }
    }

    private func topPicksRecommendationMomentumRescueLaneBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueLaneBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueLaneBadgeBackgroundColor(
                    badge.tone
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueLaneBadgeForegroundColor(
                    badge.tone
                )
            )
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueLaneBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueLaneBadgeTone
    ) -> Color {
        switch tone {
        case .active:
            return Color.orange
        case .cooling:
            return Color.secondary
        }
    }

    private func topPicksRecommendationMomentumRescueLaneBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueLaneBadgeTone
    ) -> Color {
        switch tone {
        case .active:
            return Color.orange.opacity(0.2)
        case .cooling:
            return Color.secondary.opacity(0.16)
        }
    }

    @ViewBuilder
    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge(
        _ badge: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadge,
        diagnosticsCue: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue?,
        action: CommandPaletteAction?
    ) -> some View {
        let badgeLabel = Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeBackgroundColor(
                    badge.tone
                )
            )
            .foregroundStyle(
                topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeForegroundColor(
                    badge.tone
                )
            )
            .clipShape(Capsule())
        let badgeHelpText = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpText(
                baseHelpText: badge.helpText,
                diagnosticsCue: diagnosticsCue,
                actionTitle: action?.title
            )

        if diagnosticsCue != nil {
            Button {
                focusFameMomentumPanelRouteStabilizationRecoveryDiagnostics(
                    actionID: action?.id
                )
            } label: {
                badgeLabel
            }
            .buttonStyle(.plain)
            .help(badgeHelpText)
        } else {
            badgeLabel
                .help(badgeHelpText)
        }
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeTone
    ) -> Color {
        switch tone {
        case .strong:
            return Color.mint
        case .watch:
            return Color.orange
        case .blocked:
            return Color.red
        }
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeTone
    ) -> Color {
        switch tone {
        case .strong:
            return Color.mint.opacity(0.2)
        case .watch:
            return Color.orange.opacity(0.2)
        case .blocked:
            return Color.red.opacity(0.2)
        }
    }

    @ViewBuilder
    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge(
        _ badge: CommandPaletteTopPicks
            .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadge,
        diagnosticsCue: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue?,
        action: CommandPaletteAction?
    ) -> some View {
        let badgeLabel = Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeBackgroundColor(
                    badge.tone
                )
            )
            .foregroundStyle(
                topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeForegroundColor(
                    badge.tone
                )
            )
            .clipShape(Capsule())
        let badgeHelpText = CommandPaletteTopPicks
            .fameMomentumPanelRouteStabilizationRecoverySuggestionHealthBadgeActionHelpText(
                baseHelpText: badge.helpText,
                diagnosticsCue: diagnosticsCue,
                actionTitle: action?.title
            )

        if diagnosticsCue != nil {
            Button {
                focusFameMomentumPanelRouteStabilizationRecoveryDiagnostics(
                    actionID: action?.id
                )
            } label: {
                badgeLabel
            }
            .buttonStyle(.plain)
            .help(badgeHelpText)
        } else {
            badgeLabel
                .help(badgeHelpText)
        }
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks
            .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeTone
    ) -> Color {
        switch tone {
        case .steady:
            return Color.blue
        case .watch:
            return Color.orange
        case .alert:
            return Color.red
        }
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks
            .FameMomentumPanelRouteStabilizationRecoverySuggestionPressureConfidenceBadgeTone
    ) -> Color {
        switch tone {
        case .steady:
            return Color.blue.opacity(0.18)
        case .watch:
            return Color.orange.opacity(0.18)
        case .alert:
            return Color.red.opacity(0.18)
        }
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCard(
        _ cue: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCue,
        action: CommandPaletteAction?,
        sourceActionID: String?,
        isFocused: Bool = false
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: cue.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCardForegroundColor(
                        cue.tone
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(cue.title)
                    .font(.caption.weight(.semibold))
                Text(cue.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let action {
                Button(cue.buttonTitle) {
                    clearFameMomentumPanelRouteStabilizationRecoveryDiagnosticsFocus()
                    _ = session.recordFameMomentumPanelRouteStabilizationRecoverySuggestionRun(
                        usedUnblockAction: CommandPaletteTopPicks
                            .fameMomentumPanelRouteStabilizationRecoverySuggestionUsesUnblockAction(
                                actionID: action.id,
                                actionTitle: action.title
                            )
                    )
                    run(
                        action,
                        fameMomentumPanelSourceActionID: sourceActionID,
                        fameMomentumPanelRouteStabilizationActive: true
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help(
                    CommandPaletteTopPicks
                        .fameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsActionHelpText(
                            tone: cue.tone,
                            actionTitle: action.title,
                            isEnabled: action.isEnabled,
                            disabledReason: action.disabledReason
                        )
                )
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCardBackgroundColor(
                cue.tone
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCardForegroundColor(
                        cue.tone
                    ).opacity(0.82),
                    lineWidth: 1.3
                )
                .opacity(isFocused ? 1 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .scaleEffect(isFocused ? 1.01 : 1)
        .animation(.easeOut(duration: 0.2), value: isFocused)
        .help(cue.helpText)
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCardForegroundColor(
        _ tone: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueTone
    ) -> Color {
        switch tone {
        case .watch:
            return .orange
        case .blocked:
            return .red
        }
    }

    private func topPicksFameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCardBackgroundColor(
        _ tone: CommandPaletteTopPicks.FameMomentumPanelRouteStabilizationRecoverySuggestionDiagnosticsCueTone
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.1)
        case .blocked:
            return Color.red.opacity(0.12)
        }
    }

    private func topPicksRecommendationMomentumRescueLeaderboardBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueLeaderboardBadgeBackgroundColor(
                    badge.tone
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueLeaderboardBadgeForegroundColor(
                    badge.tone
                )
            )
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueLeaderboardBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardBadgeTone
    ) -> Color {
        switch tone {
        case .active:
            return Color.purple
        case .idle:
            return Color.secondary
        }
    }

    private func topPicksRecommendationMomentumRescueLeaderboardBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardBadgeTone
    ) -> Color {
        switch tone {
        case .active:
            return Color.purple.opacity(0.2)
        case .idle:
            return Color.secondary.opacity(0.14)
        }
    }

    private func topPicksRecommendationMomentumRescueLeaderboardCard(
        _ card: CommandPaletteTopPicks.RecommendationMomentumRescueLeaderboardCard
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: card.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.purple)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.purple)
                    .lineLimit(1)

                Text(card.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.14))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.purple.opacity(0.24), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.scale(scale: 0.98).combined(with: .opacity))
        .help(card.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueHallOfFameBadgeBackgroundColor(
                    badge.trend
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueHallOfFameBadgeForegroundColor(
                    badge.trend
                )
            )
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameBadgeForegroundColor(
        _ trend: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameTrend
    ) -> Color {
        switch trend {
        case .rising:
            return Color.indigo
        case .steady:
            return Color.secondary
        case .falling:
            return Color.orange
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameBadgeBackgroundColor(
        _ trend: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameTrend
    ) -> Color {
        switch trend {
        case .rising:
            return Color.indigo.opacity(0.2)
        case .steady:
            return Color.secondary.opacity(0.14)
        case .falling:
            return Color.orange.opacity(0.2)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadgeBackgroundColor(
                    badge.tone
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadgeForegroundColor(
                    badge.tone
                )
            )
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.14))
            .foregroundStyle(Color.blue)
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseStreakBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.pink.opacity(0.18))
            .foregroundStyle(Color.pink)
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseWeeklyBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.indigo.opacity(0.18))
            .foregroundStyle(Color.indigo)
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge(
        _ badge: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeBackgroundColor(
                    badge.tier
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeForegroundColor(
                    badge.tier
                )
            )
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendBadge(
        _ trend: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend
    ) -> some View {
        Label(trend.title, systemImage: trend.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendBadgeBackgroundColor(
                    trend.direction
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendBadgeForegroundColor(
                    trend.direction
                )
            )
            .clipShape(Capsule())
            .help("\(trend.subtitle). \(trend.helpText)")
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeForegroundColor(
        _ tier: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> Color {
        switch tier {
        case .starter:
            return .teal
        case .rising:
            return .blue
        case .elite:
            return .purple
        case .legend:
            return .yellow
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeBackgroundColor(
        _ tier: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> Color {
        switch tier {
        case .starter:
            return Color.teal.opacity(0.18)
        case .rising:
            return Color.blue.opacity(0.18)
        case .elite:
            return Color.purple.opacity(0.2)
        case .legend:
            return Color.yellow.opacity(0.24)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendBadgeForegroundColor(
        _ direction: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend
            .Direction
    ) -> Color {
        switch direction {
        case .rising:
            return .mint
        case .steady:
            return .indigo
        case .falling:
            return .orange
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrendBadgeBackgroundColor(
        _ direction: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTrend
            .Direction
    ) -> Color {
        switch direction {
        case .rising:
            return Color.mint.opacity(0.2)
        case .steady:
            return Color.indigo.opacity(0.16)
        case .falling:
            return Color.orange.opacity(0.2)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgressCard(
        _ progress: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgress
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: progress.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeForegroundColor(
                        progress.tier
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(progress.title)
                    .font(.caption.weight(.semibold))
                Text(progress.subtitle)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgressBackgroundColor(
                progress.tier
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(progress.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueProgressBackgroundColor(
        _ tier: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeagueTier
    ) -> Color {
        switch tier {
        case .starter:
            return Color.teal.opacity(0.12)
        case .rising:
            return Color.blue.opacity(0.12)
        case .elite:
            return Color.purple.opacity(0.14)
        case .legend:
            return Color.yellow.opacity(0.16)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseScorecard(
        _ scorecard: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseScorecard
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: scorecard.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    topPicksRecommendationMomentumRescueHallOfFameAutoDefenseScorecardForegroundColor(
                        scorecard.tone
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(scorecard.title)
                    .font(.caption.weight(.semibold))
                Text(scorecard.subtitle)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 6)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            topPicksRecommendationMomentumRescueHallOfFameAutoDefenseScorecardBackgroundColor(
                scorecard.tone
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(scorecard.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseScorecardForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseScorecardTone
    ) -> Color {
        switch tone {
        case .disabled:
            return .secondary
        case .ready:
            return .blue
        case .coolingDown:
            return .orange
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseScorecardBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseScorecardTone
    ) -> Color {
        switch tone {
        case .disabled:
            return Color.secondary.opacity(0.1)
        case .ready:
            return Color.blue.opacity(0.12)
        case .coolingDown:
            return Color.orange.opacity(0.14)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameLegendRiskForecastCard(
        _ forecast: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecast,
        action: CommandPaletteAction?,
        plan: CommandPaletteTopPicks.RecommendationPairRescuePlan?
    ) -> some View {
        let buttonTitle: String
        if let action,
           let plan,
           action.id == plan.recommendedActionID {
            buttonTitle = "Run Rescue Now"
        } else {
            buttonTitle = "Run Forecast"
        }

        return HStack(spacing: 9) {
            Image(systemName: forecast.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    topPicksRecommendationMomentumRescueHallOfFameLegendRiskForecastForegroundColor(
                        forecast.tone
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(forecast.title)
                    .font(.caption.weight(.semibold))
                Text(forecast.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let action {
                Button(buttonTitle) {
                    if let plan,
                       action.id == plan.recommendedActionID {
                        runRecommendationMomentumRescueAction(action, plan: plan)
                    } else {
                        run(action)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to reinforce Hall-of-Fame legend defense timing.")
            }

            if !settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled {
                Button("Enable Auto") {
                    settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled = true
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Enable Hall-of-Fame auto-defense to keep legend defense timing protected automatically.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            topPicksRecommendationMomentumRescueHallOfFameLegendRiskForecastBackgroundColor(
                forecast.tone
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(forecast.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameLegendRiskForecastForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecastTone
    ) -> Color {
        switch tone {
        case .watch:
            return .orange
        case .alert:
            return .red
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameLegendRiskForecastBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskForecastTone
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.1)
        case .alert:
            return Color.red.opacity(0.12)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseBadgeTone
    ) -> Color {
        switch tone {
        case .disabled:
            return .secondary
        case .ready:
            return .blue
        case .coolingDown:
            return .orange
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseBadgeTone
    ) -> Color {
        switch tone {
        case .disabled:
            return Color.secondary.opacity(0.14)
        case .ready:
            return Color.blue.opacity(0.2)
        case .coolingDown:
            return Color.orange.opacity(0.2)
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameCard(
        _ card: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameCard
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: card.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    topPicksRecommendationMomentumRescueHallOfFameBadgeForegroundColor(
                        card.trend
                    )
                )
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(card.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        topPicksRecommendationMomentumRescueHallOfFameBadgeForegroundColor(
                            card.trend
                        )
                    )
                    .lineLimit(1)

                Text(card.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            topPicksRecommendationMomentumRescueHallOfFameBadgeBackgroundColor(card.trend)
                .opacity(0.8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    topPicksRecommendationMomentumRescueHallOfFameBadgeForegroundColor(card.trend)
                        .opacity(0.24),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.scale(scale: 0.98).combined(with: .opacity))
        .help(card.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameDefenseCueCard(
        _ cue: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCue,
        action: CommandPaletteAction?,
        plan: CommandPaletteTopPicks.RecommendationPairRescuePlan?,
        autoDefenseBadge: CommandPaletteTopPicks
            .RecommendationMomentumRescueHallOfFameAutoDefenseBadge?,
        autoDefenseRecencyBadge: CommandPaletteTopPicks
            .RecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge?
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: cue.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    topPicksRecommendationMomentumRescueHallOfFameDefenseCueForegroundColor(
                        cue.tone
                    )
                )
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(cue.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        topPicksRecommendationMomentumRescueHallOfFameDefenseCueForegroundColor(
                            cue.tone
                        )
                    )
                    .lineLimit(1)

                Text(cue.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if autoDefenseBadge != nil || autoDefenseRecencyBadge != nil {
                    HStack(spacing: 6) {
                        if let autoDefenseBadge {
                            topPicksRecommendationMomentumRescueHallOfFameAutoDefenseBadge(
                                autoDefenseBadge
                            )
                        }

                        if let autoDefenseRecencyBadge {
                            topPicksRecommendationMomentumRescueHallOfFameAutoDefenseRecencyBadge(
                                autoDefenseRecencyBadge
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            if let action,
               let plan {
                Button(cue.buttonTitle) {
                    runRecommendationMomentumRescueAction(
                        action,
                        plan: plan
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .help("Run \(action.title) to convert this week’s Hall of Fame cue.")
            }

            if !settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled {
                Button("Enable Auto") {
                    settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled = true
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Enable Hall-of-Fame auto-defense so defense/chase cues can auto-run this rescue lane.")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            topPicksRecommendationMomentumRescueHallOfFameDefenseCueBackgroundColor(cue.tone)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    topPicksRecommendationMomentumRescueHallOfFameDefenseCueForegroundColor(cue.tone)
                        .opacity(0.24),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.scale(scale: 0.98).combined(with: .opacity))
        .help(cue.helpText)
    }

    private func topPicksRecommendationMomentumRescueHallOfFameDefenseCueForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCueTone
    ) -> Color {
        switch tone {
        case .chase:
            return Color.blue
        case .defense:
            return Color.orange
        }
    }

    private func topPicksRecommendationMomentumRescueHallOfFameDefenseCueBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameDefenseCueTone
    ) -> Color {
        switch tone {
        case .chase:
            return Color.blue.opacity(0.16)
        case .defense:
            return Color.orange.opacity(0.16)
        }
    }

    private func topPicksRecommendationMomentumRescueWeeklyRecordCard(
        _ pulse: CommandPaletteSession.RecommendationMomentumRescueWeeklyRecordPulse
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: pulse.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.yellow)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(pulse.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.yellow)
                    .lineLimit(1)

                Text(pulse.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.17))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.yellow.opacity(0.28), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .transition(.scale(scale: 0.98).combined(with: .opacity))
        .help(pulse.helpText)
    }

    private func topPicksRecommendationMomentumRescueConfidenceChip(
        _ chip: CommandPaletteTopPicks.RecommendationPairRescueConfidenceChip
    ) -> some View {
        Label(chip.title, systemImage: chip.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueConfidenceChipBackgroundColor(
                    chip.tone
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueConfidenceChipForegroundColor(
                    chip.tone
                )
            )
            .clipShape(Capsule())
            .help(chip.helpText)
    }

    private func topPicksRecommendationMomentumRescueConfidenceChipForegroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationPairRescueConfidenceChipTone
    ) -> Color {
        switch tone {
        case .proven:
            return Color.mint
        case .strong:
            return Color.blue
        case .watch:
            return Color.orange
        }
    }

    private func topPicksRecommendationMomentumRescueConfidenceChipBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationPairRescueConfidenceChipTone
    ) -> Color {
        switch tone {
        case .proven:
            return Color.mint.opacity(0.2)
        case .strong:
            return Color.blue.opacity(0.2)
        case .watch:
            return Color.orange.opacity(0.2)
        }
    }

    private func topPicksRecommendationMomentumRescueFollowthroughCard(
        _ cue: CommandPaletteTopPicks.RecommendationMomentumRescueFollowthroughCue,
        pulse: CommandPaletteTopPicks.RecommendationMomentumRescueImpactPulse
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: cue.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.indigo)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(cue.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.indigo)
                    .lineLimit(1)

                Text(cue.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Color.indigo.opacity(
                isRecommendationMomentumRescueImpactPulseAnimated ? 0.24 : 0.14
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    Color.indigo.opacity(
                        isRecommendationMomentumRescueImpactPulseAnimated ? 0.42 : 0.24
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .scaleEffect(isRecommendationMomentumRescueImpactPulseAnimated ? 1.01 : 0.995)
        .animation(
            .spring(response: 0.24, dampingFraction: 0.68),
            value: isRecommendationMomentumRescueImpactPulseAnimated
        )
        .transition(.scale(scale: 0.98).combined(with: .opacity))
        .help("\(pulse.subtitle). \(cue.helpText)")
    }

    private func topPicksRecommendationMomentumRescueCelebrationCard(
        _ cue: CommandPaletteTopPicks.RecommendationMomentumRescueCelebrationCue,
        pulse: CommandPaletteSession.RecommendationMomentumRescuePulse
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: cue.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.orange)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(cue.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.orange)
                    .lineLimit(1)

                Text(cue.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Color.orange.opacity(
                isRecommendationMomentumRescuePulseCelebrationAnimated ? 0.28 : 0.16
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    Color.orange.opacity(
                        isRecommendationMomentumRescuePulseCelebrationAnimated ? 0.45 : 0.24
                    ),
                    lineWidth: 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .scaleEffect(isRecommendationMomentumRescuePulseCelebrationAnimated ? 1.012 : 0.996)
        .animation(
            .spring(response: 0.24, dampingFraction: 0.66),
            value: isRecommendationMomentumRescuePulseCelebrationAnimated
        )
        .transition(.scale(scale: 0.98).combined(with: .opacity))
        .help("\(pulse.subtitle). \(cue.helpText)")
    }

    private func launchRecoveryHotKeyLegendRiskStickyPromotionBadge(
        _ stickyPromotion: CommandPaletteSession.LaunchRecoveryHotKeyLegendRiskStickyPromotion
    ) -> some View {
        let opensRemaining = max(1, stickyPromotion.opensRemaining)
        let actionTitle = matchedActions.first { $0.id == stickyPromotion.actionID }?.title
            ?? stickyPromotion.actionID
        let title = CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyPromotionBadgeTitle(
            opensRemaining: opensRemaining,
            holdUntilRecovered: stickyPromotion.isHoldUntilRecovered
        )
        let helpText = CommandPaletteTopPicks.launchRecoveryHotKeyLegendRiskStickyPromotionBadgeHelpText(
            actionTitle: actionTitle,
            opensRemaining: opensRemaining,
            holdUntilRecovered: stickyPromotion.isHoldUntilRecovered
        )

        return Label(title, systemImage: "pin.circle.fill")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.2))
            .foregroundStyle(Color.red)
            .clipShape(Capsule())
            .help(helpText)
    }

    private func recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadge(
        _ stickyPromotion: CommandPaletteSession.RecommendationMomentumRescueHallOfFameLegendRiskStickyPromotion
    ) -> some View {
        let opensRemaining = max(1, stickyPromotion.opensRemaining)
        let actionTitle = matchedActions.first { $0.id == stickyPromotion.actionID }?.title
            ?? stickyPromotion.actionID
        let title = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeTitle(
                opensRemaining: opensRemaining,
                holdUntilRecovered: stickyPromotion.isHoldUntilRecovered
            )
        let helpText = CommandPaletteTopPicks
            .recommendationMomentumRescueHallOfFameLegendRiskStickyPromotionBadgeHelpText(
                actionTitle: actionTitle,
                opensRemaining: opensRemaining,
                holdUntilRecovered: stickyPromotion.isHoldUntilRecovered
            )

        return Label(title, systemImage: "pin.circle.fill")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.2))
            .foregroundStyle(Color.orange)
            .clipShape(Capsule())
            .help(helpText)
    }

    private func launchRecoveryHotKeyConfidenceBadge(
        _ readiness: CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness
    ) -> some View {
        let backgroundColor: Color
        switch readiness {
        case .direct:
            backgroundColor = Color.green.opacity(0.16)
        case .reroute:
            backgroundColor = Color.teal.opacity(0.18)
        case .unavailable:
            backgroundColor = Color.secondary.opacity(0.16)
        }

        return Label(
            CommandPaletteTopPicks.launchRecoveryHotKeyBadgeTitle(for: readiness),
            systemImage: CommandPaletteTopPicks.launchRecoveryHotKeyBadgeSystemImage(for: readiness)
        )
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .clipShape(Capsule())
        .help(CommandPaletteTopPicks.launchRecoveryHotKeyBadgeHelpText(for: readiness))
    }

    @ViewBuilder
    private func launchRecoveryHotKeyDirectPromptBadge(
        _ readiness: CommandPaletteTopPicks.LaunchRecoveryHotKeyReadiness
    ) -> some View {
        if let title = CommandPaletteTopPicks.launchRecoveryHotKeyPromptTitle(for: readiness),
           let systemImage = CommandPaletteTopPicks.launchRecoveryHotKeyPromptSystemImage(for: readiness),
           let helpText = CommandPaletteTopPicks.launchRecoveryHotKeyPromptHelpText(for: readiness) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.orange.opacity(0.2))
                .clipShape(Capsule())
                .help(helpText)
        }
    }

    @ViewBuilder
    private func launchRecoveryHotKeyTrendBadge(
        _ trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyTrend?
    ) -> some View {
        if let trend,
           trend.sampleCount >= 2 {
            let dominantState = CommandPaletteTopPicks.launchRecoveryHotKeyTrendDominantState(
                for: trend
            )
            let backgroundColor = launchRecoveryHotKeyTrendBadgeBackgroundColor(
                dominantState
            )

            Label(
                CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeTitle(for: trend),
                systemImage: CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeSystemImage(
                    for: trend
                )
            )
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .clipShape(Capsule())
            .help(CommandPaletteTopPicks.launchRecoveryHotKeyTrendBadgeHelpText(for: trend))
        }
    }

    private func launchRecoveryHotKeyTrendBadgeBackgroundColor(
        _ state: CommandPaletteTopPicks.LaunchRecoveryHotKeyReadinessState
    ) -> Color {
        switch state {
        case .direct:
            return Color.mint.opacity(0.2)
        case .reroute:
            return Color.teal.opacity(0.2)
        case .standby:
            return Color.secondary.opacity(0.16)
        }
    }

    @ViewBuilder
    private func launchRecoveryHotKeyWinMeterBadge(
        _ meter: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter?
    ) -> some View {
        if let meter {
            Label(meter.title, systemImage: meter.systemImage)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(launchRecoveryHotKeyWinMeterBadgeBackgroundColor(meter.tone))
                .clipShape(Capsule())
                .help(meter.helpText)
        }
    }

    private func launchRecoveryHotKeyWinMeterBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeterTone
    ) -> Color {
        switch tone {
        case .rebuild:
            return Color.orange.opacity(0.22)
        case .steady:
            return Color.blue.opacity(0.2)
        case .surge:
            return Color.mint.opacity(0.24)
        }
    }

    @ViewBuilder
    private func launchRecoveryHotKeyMomentumBadge(
        _ momentum: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum?
    ) -> some View {
        if let momentum {
            Label(momentum.title, systemImage: momentum.systemImage)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(launchRecoveryHotKeyMomentumBadgeBackgroundColor(momentum.direction))
                .clipShape(Capsule())
                .help(momentum.helpText)
        }
    }

    private func launchRecoveryHotKeyMomentumBadgeBackgroundColor(
        _ direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentum.Direction
    ) -> Color {
        switch direction {
        case .rising:
            return Color.green.opacity(0.2)
        case .steady:
            return Color.blue.opacity(0.18)
        case .falling:
            return Color.red.opacity(0.22)
        }
    }

    private func launchRecoveryHotKeyConfidenceScoreBadge(
        _ score: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore
    ) -> some View {
        Label(score.title, systemImage: score.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyConfidenceScoreBadgeBackgroundColor(score.tier))
            .clipShape(Capsule())
            .help(score.helpText)
    }

    private func launchRecoveryHotKeyConfidenceScoreBadgeBackgroundColor(
        _ tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier
    ) -> Color {
        switch tier {
        case .critical:
            return Color.red.opacity(0.22)
        case .watch:
            return Color.orange.opacity(0.24)
        case .steady:
            return Color.blue.opacity(0.18)
        case .prime:
            return Color.mint.opacity(0.22)
        }
    }

    private func launchRecoveryHotKeyInterventionAction(
        _ intervention: CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention
    ) -> CommandPaletteAction? {
        matchedActions.first { $0.id == intervention.actionID && $0.isEnabled }
    }

    private func launchRecoveryHotKeyConfidenceScoreCard(
        _ score: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore,
        interventions: [CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention],
        interventionTrustTrend: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend?
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 9) {
                Image(systemName: score.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(
                        score.tier == .critical ? Color.red : Color.orange
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(score.title)
                        .font(.caption.weight(.semibold))
                    Text(score.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 6)
            }

            if let interventionTrustTrend {
                launchRecoveryHotKeyInterventionTrustTrendRow(interventionTrustTrend)
            }

            if !interventions.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(interventions.enumerated()), id: \.element.actionID) { index, intervention in
                        if let action = launchRecoveryHotKeyInterventionAction(intervention) {
                            if index == 0 {
                                Button {
                                    run(action)
                                } label: {
                                    launchRecoveryHotKeyInterventionButtonLabel(intervention)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.mini)
                                .disabled(!action.isEnabled)
                                .help(intervention.helpText)
                                .accessibilityLabel(
                                    CommandPaletteTopPicks.launchRecoveryHotKeyInterventionButtonTitle(
                                        intervention
                                    )
                                )
                            } else {
                                Button {
                                    run(action)
                                } label: {
                                    launchRecoveryHotKeyInterventionButtonLabel(intervention)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                                .disabled(!action.isEnabled)
                                .help(intervention.helpText)
                                .accessibilityLabel(
                                    CommandPaletteTopPicks.launchRecoveryHotKeyInterventionButtonTitle(
                                        intervention
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(launchRecoveryHotKeyConfidenceScoreCardBackgroundColor(score.tier))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(score.helpText)
    }

    private func launchRecoveryHotKeyWinMeterCard(
        _ meter: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeter
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: meter.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(launchRecoveryHotKeyWinMeterCardForegroundColor(meter.tone))

            VStack(alignment: .leading, spacing: 2) {
                Text(meter.title)
                    .font(.caption.weight(.semibold))
                Text(meter.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            Text("x\(meter.multiplier)")
                .font(.caption2.monospacedDigit().weight(.semibold))
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(launchRecoveryHotKeyWinMeterMultiplierBackgroundColor(meter.tone))
                .foregroundStyle(launchRecoveryHotKeyWinMeterCardForegroundColor(meter.tone))
                .clipShape(Capsule())
                .help("Recovery streak multiplier is x\(meter.multiplier).")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(launchRecoveryHotKeyWinMeterCardBackgroundColor(meter.tone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(meter.helpText)
    }

    private func launchRecoveryHotKeyInterventionTrustTrendRow(
        _ trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend
    ) -> some View {
        HStack(spacing: 8) {
            Label(trend.title, systemImage: trend.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(
                    launchRecoveryHotKeyInterventionTrustTrendForegroundColor(trend.direction)
                )

            Spacer(minLength: 6)

            Text(trend.subtitle)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

            launchRecoveryHotKeyInterventionTrustSparkline(
                trend.samples,
                direction: trend.direction
            )
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(
            launchRecoveryHotKeyInterventionTrustTrendBackgroundColor(trend.direction)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .help(trend.helpText)
    }

    private func launchRecoveryHotKeyInterventionTrustSparkline(
        _ samples: [Int],
        direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend.Direction
    ) -> some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width)
            let height = max(1, geometry.size.height)
            let normalizedSamples = samples.map { max(0, min(100, $0)) }
            let denominator = max(1, normalizedSamples.count - 1)
            let path = Path { path in
                for (index, value) in normalizedSamples.enumerated() {
                    let x = (Double(index) / Double(denominator)) * width
                    let y = (1 - (Double(value) / 100)) * height
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }

            path.stroke(
                launchRecoveryHotKeyInterventionTrustTrendForegroundColor(direction),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 58, height: 14)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func launchRecoveryHotKeyInterventionButtonLabel(
        _ intervention: CommandPaletteTopPicks.LaunchRecoveryHotKeyIntervention
    ) -> some View {
        HStack(spacing: 4) {
            Text(intervention.title)
            if let impactBadgeTitle = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactBadgeTitle(
                intervention.impactScore
            ),
            let impactTone = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionImpactTone(
                intervention.impactScore
            ) {
                Text(impactBadgeTitle)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .foregroundStyle(
                        launchRecoveryHotKeyInterventionImpactBadgeForegroundColor(impactTone)
                    )
                    .background(
                        launchRecoveryHotKeyInterventionImpactBadgeBackgroundColor(impactTone)
                    )
                    .clipShape(Capsule())
            }
            if let recencyBadgeTitle = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyBadgeTitle(
                intervention.recency
            ),
            let recencyTone = CommandPaletteTopPicks.launchRecoveryHotKeyInterventionRecencyTone(
                intervention.recency
            ) {
                Text(recencyBadgeTitle)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .foregroundStyle(
                        launchRecoveryHotKeyInterventionRecencyBadgeForegroundColor(recencyTone)
                    )
                    .background(
                        launchRecoveryHotKeyInterventionRecencyBadgeBackgroundColor(recencyTone)
                    )
                    .clipShape(Capsule())
            }
        }
    }

    private func launchRecoveryHotKeyConfidenceScoreCardBackgroundColor(
        _ tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidenceScore.Tier
    ) -> Color {
        switch tier {
        case .critical:
            return Color.red.opacity(0.12)
        case .watch:
            return Color.orange.opacity(0.12)
        case .steady:
            return Color.blue.opacity(0.1)
        case .prime:
            return Color.mint.opacity(0.1)
        }
    }

    private func launchRecoveryHotKeyWinMeterCardForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeterTone
    ) -> Color {
        switch tone {
        case .rebuild:
            return Color.orange
        case .steady:
            return Color.blue
        case .surge:
            return Color.mint
        }
    }

    private func launchRecoveryHotKeyWinMeterCardBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeterTone
    ) -> Color {
        switch tone {
        case .rebuild:
            return Color.orange.opacity(0.12)
        case .steady:
            return Color.blue.opacity(0.12)
        case .surge:
            return Color.mint.opacity(0.12)
        }
    }

    private func launchRecoveryHotKeyWinMeterMultiplierBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyWinMeterTone
    ) -> Color {
        switch tone {
        case .rebuild:
            return Color.orange.opacity(0.2)
        case .steady:
            return Color.blue.opacity(0.2)
        case .surge:
            return Color.mint.opacity(0.2)
        }
    }

    private func launchRecoveryHotKeyInterventionTrustTrendForegroundColor(
        _ direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend.Direction
    ) -> Color {
        switch direction {
        case .rising:
            return Color.mint
        case .steady:
            return Color.blue
        case .falling:
            return Color.orange
        }
    }

    private func launchRecoveryHotKeyInterventionTrustTrendBackgroundColor(
        _ direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustTrend.Direction
    ) -> Color {
        switch direction {
        case .rising:
            return Color.mint.opacity(0.12)
        case .steady:
            return Color.blue.opacity(0.1)
        case .falling:
            return Color.orange.opacity(0.14)
        }
    }

    private func launchRecoveryHotKeyInterventionImpactBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionImpactTone
    ) -> Color {
        switch tone {
        case .positive:
            return Color.mint
        case .negative:
            return Color.red
        }
    }

    private func launchRecoveryHotKeyInterventionImpactBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionImpactTone
    ) -> Color {
        switch tone {
        case .positive:
            return Color.mint.opacity(0.2)
        case .negative:
            return Color.red.opacity(0.2)
        }
    }

    private func launchRecoveryHotKeyInterventionRecencyBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionRecencyTone
    ) -> Color {
        switch tone {
        case .recent:
            return Color.blue
        case .stale:
            return Color.orange
        }
    }

    private func launchRecoveryHotKeyInterventionRecencyBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionRecencyTone
    ) -> Color {
        switch tone {
        case .recent:
            return Color.blue.opacity(0.16)
        case .stale:
            return Color.orange.opacity(0.2)
        }
    }

    private func launchRecoveryHotKeyInterventionTrustGuardCard(
        _ trustGuard: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustGuard,
        action: CommandPaletteAction?
    ) -> some View {
        let foregroundColor: Color = trustGuard.severity == .critical ? .red : .orange
        let backgroundColor: Color = trustGuard.severity == .critical
            ? Color.red.opacity(0.12)
            : Color.orange.opacity(0.12)
        let buttonTitle = action?.id == CommandPaletteAction.launchRecoveryNextActionID
            ? "Run Recovery Next"
            : "Run Trust Fix"

        return HStack(spacing: 9) {
            Image(systemName: trustGuard.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foregroundColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(trustGuard.title)
                    .font(.caption.weight(.semibold))
                Text(trustGuard.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let action {
                Button(buttonTitle) {
                    run(action)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to stabilize intervention trust.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(trustGuard.helpText)
    }

    private func launchRecoveryHotKeyInterventionTrustMomentumCard(
        _ plan: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentumPlan,
        action: CommandPaletteAction?,
        autoTrustSurgeBadge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge?,
        autoTrustSurgeRecencyBadge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge?
    ) -> some View {
        let buttonTitle = action?.id == CommandPaletteAction.launchRecoveryNextActionID
            ? "Run Recovery Next"
            : "Run Trust Step"

        return HStack(spacing: 9) {
            Image(systemName: plan.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.mint)

            VStack(alignment: .leading, spacing: 2) {
                Text(plan.title)
                    .font(.caption.weight(.semibold))
                Text(plan.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if autoTrustSurgeBadge != nil || autoTrustSurgeRecencyBadge != nil {
                    HStack(spacing: 6) {
                        if let autoTrustSurgeBadge {
                            Label(autoTrustSurgeBadge.title, systemImage: autoTrustSurgeBadge.systemImage)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(
                                    launchRecoveryHotKeyAutoTrustSurgeBadgeBackgroundColor(
                                        autoTrustSurgeBadge.tone
                                    )
                                )
                                .foregroundStyle(
                                    launchRecoveryHotKeyAutoTrustSurgeBadgeForegroundColor(
                                        autoTrustSurgeBadge.tone
                                    )
                                )
                                .clipShape(Capsule())
                                .help(autoTrustSurgeBadge.helpText)
                        }

                        if let autoTrustSurgeRecencyBadge {
                            launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(autoTrustSurgeRecencyBadge)
                        }
                    }
                }
            }

            Spacer(minLength: 6)

            if let action {
                Button(buttonTitle) {
                    run(action)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to keep trust momentum compounding.")
            }

            if !settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled {
                Button("Enable Auto") {
                    settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled = true
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Enable Auto Trust Surge so 1-open milestone setups can auto-run this momentum step.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.mint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(plan.helpText)
    }

    private func launchRecoveryHotKeyCoachCard(
        _ cue: CommandPaletteTopPicks.LaunchRecoveryHotKeyCoachCue,
        action: CommandPaletteAction?
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: cue.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(cue.title)
                    .font(.caption.weight(.semibold))
                Text(cue.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let action {
                Button("Run Coach Step") {
                    run(action)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to improve launch recovery confidence.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func launchRecoveryHotKeyMomentumRescueCard(
        _ rescue: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue,
        action: CommandPaletteAction?,
        autoRescueBadge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadge?,
        autoRescueRecencyBadge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueRecencyBadge?
    ) -> some View {
        let buttonTitle = action?.id == CommandPaletteAction.launchRecoveryNextActionID
            ? "Run Recovery Next"
            : "Run Rescue"

        return HStack(spacing: 9) {
            Image(systemName: rescue.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    rescue.severity == .alert ? Color.red : Color.orange
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(rescue.title)
                    .font(.caption.weight(.semibold))
                Text(rescue.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if autoRescueBadge != nil || autoRescueRecencyBadge != nil {
                    HStack(spacing: 6) {
                        if let autoRescueBadge {
                            launchRecoveryHotKeyAutoRescueBadge(autoRescueBadge)
                        }

                        if let autoRescueRecencyBadge {
                            launchRecoveryHotKeyAutoRescueRecencyBadge(autoRescueRecencyBadge)
                        }
                    }
                }
            }

            Spacer(minLength: 6)

            if let action {
                Button(buttonTitle) {
                    run(action)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to reverse momentum slip.")
            }

            if !settings.fameLaunchRecoveryHotKeyAutoRescueEnabled {
                Button("Enable Auto") {
                    settings.fameLaunchRecoveryHotKeyAutoRescueEnabled = true
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Enable auto rescue guard so Momentum Alert pulses can auto-run one rescue step.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(launchRecoveryHotKeyMomentumRescueCardBackgroundColor(rescue.severity))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(rescue.helpText)
    }

    private func launchRecoveryHotKeyMomentumRescueCardBackgroundColor(
        _ severity: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumRescue.Severity
    ) -> Color {
        switch severity {
        case .watch:
            return Color.orange.opacity(0.12)
        case .alert:
            return Color.red.opacity(0.12)
        }
    }

    private func bestChannelLaunchPackGuidanceCard(
        _ card: CommandPaletteTopPicks.BestChannelLaunchPackPressureCard,
        action: CommandPaletteAction,
        trend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend,
        performanceLine: String
    ) -> some View {
        let buttonTitle = CommandPaletteTopPicks.bestChannelLaunchPackGuidanceButtonTitle(
            trend: trend,
            tone: card.tone
        )
        return HStack(spacing: 9) {
            Image(systemName: card.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(bestChannelLaunchPackGuidanceCardAccentColor(card.tone))

            VStack(alignment: .leading, spacing: 2) {
                Text(card.title)
                    .font(.caption.weight(.semibold))
                Text(card.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(performanceLine)
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.92))
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Button(buttonTitle) {
                run(action)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
            .disabled(!action.isEnabled)
            .help("Run \(action.title) for one-tap launch-ready copy.")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(bestChannelLaunchPackGuidanceCardBackgroundColor(card.tone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(card.helpText)
    }

    private func bestChannelLaunchPackGuidanceCardBackgroundColor(
        _ tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.12)
        case .alert:
            return Color.red.opacity(0.12)
        }
    }

    private func bestChannelLaunchPackGuidanceCardAccentColor(
        _ tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone
    ) -> Color {
        switch tone {
        case .watch:
            return .orange
        case .alert:
            return .red
        }
    }

    private func bestChannelLaunchPackPressureBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.BestChannelLaunchPackPressureTone?
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.18)
        case .alert:
            return Color.red.opacity(0.18)
        case nil:
            return Color.purple.opacity(0.18)
        }
    }

    private func bestChannelLaunchPackPressureModeBadgeBackgroundColor(
        _ trend: CommandPaletteTopPicks.BestChannelLaunchPackPressureTrend
    ) -> Color {
        switch trend {
        case .compounding:
            return Color.green.opacity(0.16)
        case .rebuilding:
            return Color.orange.opacity(0.16)
        case .cooling:
            return Color.red.opacity(0.16)
        case .noOpportunities, .noWins:
            return Color.purple.opacity(0.16)
        }
    }

    private var cadenceExecutionKitMomentumCard: some View {
        HStack(spacing: 9) {
            Image(
                systemName: CommandPaletteCadenceExecutionKitStreak.momentumSystemImage(streak: cadenceExecutionKitStreak)
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text(
                    CommandPaletteCadenceExecutionKitStreak.momentumTitle(
                        streak: cadenceExecutionKitStreak,
                        bestStreak: cadenceExecutionKitBestStreak
                    )
                )
                .font(.caption.weight(.semibold))
                Text(
                    CommandPaletteCadenceExecutionKitStreak.momentumSubtitle(
                        streak: cadenceExecutionKitStreak,
                        bestStreak: cadenceExecutionKitBestStreak
                    )
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let runAction = cadenceExecutionKitRunAction {
                Button("Run Now") {
                    run(runAction)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!runAction.isEnabled)
            }

            if let copyAction = cadenceExecutionKitCopyAction {
                Button("Copy Kit") {
                    run(copyAction)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(!copyAction.isEnabled)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(
            CommandPaletteCadenceExecutionKitStreak.momentumHelpText(
                streak: cadenceExecutionKitStreak,
                bestStreak: cadenceExecutionKitBestStreak
            )
        )
    }

    private func cadenceExecutionKitStreakBadge(_ streak: Int, bestStreak: Int) -> some View {
        Label(
            CommandPaletteCadenceExecutionKitStreak.badgeLabel(streak: streak),
            systemImage: CommandPaletteCadenceExecutionKitStreak.badgeSystemImage(streak: streak)
        )
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.purple.opacity(0.2))
        .clipShape(Capsule())
        .help(
            CommandPaletteCadenceExecutionKitStreak.badgeHelpText(
                streak: streak,
                bestStreak: bestStreak
            )
        )
    }

    private func topPickMilestoneBadge(_ milestone: Int) -> some View {
        Label("Milestone x\(milestone)", systemImage: "sparkles")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.yellow.opacity(0.24))
            .clipShape(Capsule())
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: milestone)
    }

    private func cadenceExecutionKitMomentumPulseBadge(
        _ pulse: CommandPaletteCadenceExecutionKitStreak.MomentumPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.purple.opacity(0.24))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyDecayPulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyDecayPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.28))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyRestorePulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyRestorePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.mint.opacity(0.24))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyConfidencePulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyConfidencePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.24))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyMomentumPulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyMomentumPulseBadgeBackgroundColor(pulse.tone))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeaguePromotionPulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeaguePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeBackgroundColor(pulse.toTier))
            .foregroundStyle(launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeForegroundColor(pulse.toTier))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseBadgeBackgroundColor(
                    pulse.tone
                )
            )
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyLegendRiskStickyReleasePulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyLegendRiskStickyReleasePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.24))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyMomentumPulseBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyMomentumPulse.Tone
    ) -> Color {
        switch tone {
        case .rising:
            return Color.green.opacity(0.24)
        case .falling:
            return Color.red.opacity(0.24)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayPulseTone
    ) -> Color {
        switch tone {
        case .ready:
            return Color.indigo.opacity(0.24)
        case .alert:
            return Color.red.opacity(0.24)
        }
    }

    private func launchRecoveryHotKeyInterventionTrustPulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                launchRecoveryHotKeyInterventionTrustPulseBadgeBackgroundColor(
                    pulse.tone
                )
            )
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyInterventionTrustMomentumPulseBadge(
        _ pulse: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentumPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.yellow.opacity(0.28))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationMomentumRescueHallOfFameAutoDefenseLeaguePromotionPulseBadge(
        _ pulse: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameAutoDefenseLeaguePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeBackgroundColor(
                    pulse.toTier
                )
            )
            .foregroundStyle(
                topPicksRecommendationMomentumRescueHallOfFameAutoDefenseLeagueBadgeForegroundColor(
                    pulse.toTier
                )
            )
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationMomentumRescueHallOfFameLegendRiskPulseBadge(
        _ pulse: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                recommendationMomentumRescueHallOfFameLegendRiskPulseBadgeBackgroundColor(
                    pulse.tone
                )
            )
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationMomentumRescueHallOfFameLegendRiskPulseBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskPulseTone
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.24)
        case .alert:
            return Color.red.opacity(0.24)
        }
    }

    private func recommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulseBadge(
        _ pulse: CommandPaletteTopPicks.RecommendationMomentumRescueHallOfFameLegendRiskStickyReleasePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.24))
            .clipShape(Capsule())
            .help(pulse.helpText)
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationConversionPulseBadge(
        _ pulse: CommandPaletteSession.RecommendationConversionPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.pink.opacity(0.24))
            .foregroundStyle(Color.pink)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func fameMomentumPanelLearningPulseBadge(
        _ pulse: CommandPaletteSession.FameMomentumPanelLearningPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.22))
            .foregroundStyle(Color.blue)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func fameMomentumPanelRouteFlipPulseBadge(
        _ pulse: CommandPaletteSession.FameMomentumPanelRouteFlipPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.mint.opacity(0.24))
            .foregroundStyle(Color.mint)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func fameMomentumPanelRouteStabilizationPulseBadge(
        _ pulse: CommandPaletteSession.FameMomentumPanelRouteStabilizationPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.28))
            .foregroundStyle(Color.orange)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationMomentumRescueImpactPulseBadge(
        _ pulse: CommandPaletteTopPicks.RecommendationMomentumRescueImpactPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.indigo.opacity(0.24))
            .foregroundStyle(Color.indigo)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationMomentumRescuePulseBadge(
        _ pulse: CommandPaletteSession.RecommendationMomentumRescuePulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.26))
            .foregroundStyle(Color.orange)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func recommendationMomentumRescueWeeklyRecordPulseBadge(
        _ pulse: CommandPaletteSession.RecommendationMomentumRescueWeeklyRecordPulse
    ) -> some View {
        Label(pulse.title, systemImage: pulse.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.yellow.opacity(0.28))
            .foregroundStyle(Color.yellow)
            .clipShape(Capsule())
            .help("\(pulse.subtitle). \(pulse.helpText)")
            .transition(.scale.combined(with: .opacity))
    }

    private func launchRecoveryHotKeyInterventionTrustPulseBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustPulse.Tone
    ) -> Color {
        switch tone {
        case .rising:
            return Color.mint.opacity(0.24)
        case .falling:
            return Color.red.opacity(0.24)
        }
    }

    private func launchRecoveryHotKeyInterventionTrustMomentumBadge(
        _ momentum: CommandPaletteTopPicks.LaunchRecoveryHotKeyInterventionTrustMomentum
    ) -> some View {
        Label(momentum.title, systemImage: momentum.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.mint.opacity(0.24))
            .clipShape(Capsule())
            .help("\(momentum.subtitle). \(momentum.helpText)")
    }

    private func launchRecoveryHotKeyAutoRescueBadge(
        _ badge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyAutoRescueBadgeBackgroundColor(badge.tone))
            .foregroundStyle(launchRecoveryHotKeyAutoRescueBadgeForegroundColor(badge.tone))
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func launchRecoveryHotKeyAutoRescueRecencyBadge(
        _ badge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueRecencyBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.14))
            .foregroundStyle(Color.blue)
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeBadge(
        _ badge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyAutoTrustSurgeBadgeBackgroundColor(badge.tone))
            .foregroundStyle(launchRecoveryHotKeyAutoTrustSurgeBadgeForegroundColor(badge.tone))
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeRecencyBadge(
        _ badge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeRecencyBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.14))
            .foregroundStyle(Color.blue)
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
        _ badge: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueBadge
    ) -> some View {
        Label(badge.title, systemImage: badge.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeBackgroundColor(badge.tier))
            .foregroundStyle(launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeForegroundColor(badge.tier))
            .clipShape(Capsule())
            .help(badge.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueTrendBadge(
        _ trend: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend
    ) -> some View {
        Label(trend.title, systemImage: trend.systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(launchRecoveryHotKeyAutoTrustSurgeLeagueTrendBadgeBackgroundColor(trend.direction))
            .foregroundStyle(launchRecoveryHotKeyAutoTrustSurgeLeagueTrendBadgeForegroundColor(trend.direction))
            .clipShape(Capsule())
            .help("\(trend.subtitle). \(trend.helpText)")
    }

    private func launchRecoveryHotKeyAutoTrustSurgeStreakBadge(
        currentStreak: Int,
        bestStreak: Int
    ) -> some View {
        let normalizedCurrentStreak = max(1, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, bestStreak)
        let symbol = normalizedCurrentStreak >= 7 ? "flame.fill" : "bolt.fill"

        return Label("Auto Streak x\(normalizedCurrentStreak)d", systemImage: symbol)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.pink.opacity(0.18))
            .foregroundStyle(Color.pink)
            .clipShape(Capsule())
            .help(
                "Auto Trust Surge streak: x\(normalizedCurrentStreak) days with at least one auto run. Best: x\(normalizedBestStreak)."
            )
    }

    private func launchRecoveryHotKeyAutoTrustSurgeWeeklyBadge(
        currentWeekRuns: Int,
        bestWeekRuns: Int
    ) -> some View {
        let normalizedCurrentWeekRuns = max(1, currentWeekRuns)
        let normalizedBestWeekRuns = max(normalizedCurrentWeekRuns, bestWeekRuns)
        let symbol = normalizedCurrentWeekRuns >= normalizedBestWeekRuns ? "sparkles" : "chart.bar.fill"

        return Label("Auto Week \(normalizedCurrentWeekRuns)", systemImage: symbol)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.indigo.opacity(0.18))
            .foregroundStyle(Color.indigo)
            .clipShape(Capsule())
            .help(
                "Auto Trust Surge this week: \(normalizedCurrentWeekRuns) runs. Best week: \(normalizedBestWeekRuns) runs."
            )
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeForegroundColor(
        _ tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> Color {
        switch tier {
        case .starter:
            return .teal
        case .rising:
            return .blue
        case .elite:
            return .purple
        case .legend:
            return .yellow
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeBackgroundColor(
        _ tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> Color {
        switch tier {
        case .starter:
            return Color.teal.opacity(0.18)
        case .rising:
            return Color.blue.opacity(0.18)
        case .elite:
            return Color.purple.opacity(0.2)
        case .legend:
            return Color.yellow.opacity(0.24)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueTrendBadgeForegroundColor(
        _ direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend.Direction
    ) -> Color {
        switch direction {
        case .rising:
            return .mint
        case .steady:
            return .indigo
        case .falling:
            return .orange
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueTrendBadgeBackgroundColor(
        _ direction: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTrend.Direction
    ) -> Color {
        switch direction {
        case .rising:
            return Color.mint.opacity(0.2)
        case .steady:
            return Color.indigo.opacity(0.16)
        case .falling:
            return Color.orange.opacity(0.2)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDefenseCard(
        _ defense: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDefense,
        action: CommandPaletteAction?
    ) -> some View {
        let buttonTitle = action?.id == CommandPaletteAction.launchRecoveryNextActionID
            ? "Run Recovery Next"
            : "Run Defense"

        return HStack(spacing: 9) {
            Image(systemName: defense.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(launchRecoveryHotKeyAutoTrustSurgeLegendDefenseForegroundColor(defense.tone))

            VStack(alignment: .leading, spacing: 2) {
                Text(defense.title)
                    .font(.caption.weight(.semibold))
                Text(defense.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let action {
                Button(buttonTitle) {
                    run(action)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to keep Auto League Legend protected.")
            }

            if !settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled {
                Button("Enable Auto") {
                    settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled = true
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Enable Auto Trust Surge to protect Legend automatically during momentum slides.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(launchRecoveryHotKeyAutoTrustSurgeLegendDefenseBackgroundColor(defense.tone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(defense.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDefenseForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDefenseTone
    ) -> Color {
        switch tone {
        case .watch:
            return .orange
        case .alert:
            return .red
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDefenseBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDefenseTone
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.12)
        case .alert:
            return Color.red.opacity(0.14)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastCard(
        _ forecast: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast,
        action: CommandPaletteAction?
    ) -> some View {
        let buttonTitle = action?.id == CommandPaletteAction.launchRecoveryNextActionID
            ? "Run Recovery Next"
            : "Run Forecast"

        return HStack(spacing: 9) {
            Image(systemName: forecast.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastForegroundColor(
                        forecast.tone
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(forecast.title)
                    .font(.caption.weight(.semibold))
                Text(forecast.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)

            if let action {
                Button(buttonTitle) {
                    run(action)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .disabled(!action.isEnabled)
                .help("Run \(action.title) to reinforce Legend before drift compounds.")
            }

            if !settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled {
                Button("Enable Auto") {
                    settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled = true
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .help("Enable Auto Trust Surge so Legend defense timing runs automatically.")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastBackgroundColor(forecast.tone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(forecast.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastTone
    ) -> Color {
        switch tone {
        case .watch:
            return .orange
        case .alert:
            return .red
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLegendDecayForecastTone
    ) -> Color {
        switch tone {
        case .watch:
            return Color.orange.opacity(0.1)
        case .alert:
            return Color.red.opacity(0.12)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueProgressCard(
        _ progress: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueProgress
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: progress.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    launchRecoveryHotKeyAutoTrustSurgeLeagueBadgeForegroundColor(progress.tier)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(progress.title)
                    .font(.caption.weight(.semibold))
                Text(progress.subtitle)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(
            launchRecoveryHotKeyAutoTrustSurgeLeagueProgressBackgroundColor(progress.tier)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(progress.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueProgressBackgroundColor(
        _ tier: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueTier
    ) -> Color {
        switch tier {
        case .starter:
            return Color.teal.opacity(0.12)
        case .rising:
            return Color.blue.opacity(0.12)
        case .elite:
            return Color.purple.opacity(0.14)
        case .legend:
            return Color.yellow.opacity(0.16)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeInsightCard(
        _ insight: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsight
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: insight.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    launchRecoveryHotKeyAutoTrustSurgeInsightForegroundColor(insight.tone)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption.weight(.semibold))
                Text(insight.subtitle)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 6)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(launchRecoveryHotKeyAutoTrustSurgeInsightBackgroundColor(insight.tone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help(insight.helpText)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeInsightForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsightTone
    ) -> Color {
        switch tone {
        case .standby:
            return .secondary
        case .primed:
            return .mint
        case .climbing:
            return .blue
        case .podium:
            return .purple
        case .coolingDown:
            return .orange
        case .capped:
            return .purple
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeInsightBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeInsightTone
    ) -> Color {
        switch tone {
        case .standby:
            return Color.secondary.opacity(0.1)
        case .primed:
            return Color.mint.opacity(0.1)
        case .climbing:
            return Color.blue.opacity(0.12)
        case .podium:
            return Color.purple.opacity(0.14)
        case .coolingDown:
            return Color.orange.opacity(0.12)
        case .capped:
            return Color.purple.opacity(0.16)
        }
    }

    private func launchRecoveryHotKeyAutoRescueBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadgeTone
    ) -> Color {
        switch tone {
        case .disabled:
            return .secondary
        case .ready:
            return .red
        case .coolingDown:
            return .orange
        }
    }

    private func launchRecoveryHotKeyAutoRescueBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoRescueBadgeTone
    ) -> Color {
        switch tone {
        case .disabled:
            return Color.secondary.opacity(0.14)
        case .ready:
            return Color.red.opacity(0.2)
        case .coolingDown:
            return Color.orange.opacity(0.2)
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeBadgeForegroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadgeTone
    ) -> Color {
        switch tone {
        case .disabled:
            return .secondary
        case .ready:
            return .mint
        case .capped:
            return .purple
        case .coolingDown:
            return .orange
        }
    }

    private func launchRecoveryHotKeyAutoTrustSurgeBadgeBackgroundColor(
        _ tone: CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeBadgeTone
    ) -> Color {
        switch tone {
        case .disabled:
            return Color.secondary.opacity(0.14)
        case .ready:
            return Color.mint.opacity(0.2)
        case .capped:
            return Color.purple.opacity(0.2)
        case .coolingDown:
            return Color.orange.opacity(0.2)
        }
    }

    @ViewBuilder
    private func commandRow(_ action: CommandPaletteAction, shortcutNumber: Int?) -> some View {
        let isSelected = action.id == activeActionID

        HStack(spacing: 8) {
            commandButton(action, shortcutNumber: shortcutNumber)

            if action.canFavorite {
                favoriteButton(action)
            } else {
                Color.clear
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, layoutMetrics.rowHorizontalPadding)
        .padding(.vertical, layoutMetrics.rowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovering in
            // Ignore hover events caused by rows scrolling under a stationary
            // cursor during keyboard navigation; only a real pointer move
            // (detected by `.onContinuousHover` on the list) re-enables this.
            if isHovering && !isKeyboardNavigating {
                selectedActionID = action.id
            }
        }
    }

    @ViewBuilder
    private func commandButton(_ action: CommandPaletteAction, shortcutNumber: Int?) -> some View {
        if let shortcutNumber {
            let key = KeyEquivalent(Character(String(shortcutNumber)))
            plainCommandButton(action, shortcutNumber: shortcutNumber)
                .keyboardShortcut(key, modifiers: [.command])
        } else {
            plainCommandButton(action, shortcutNumber: shortcutNumber)
        }
    }

    private func plainCommandButton(_ action: CommandPaletteAction, shortcutNumber: Int?) -> some View {
        Button {
            run(action)
        } label: {
            commandLabel(action, shortcutNumber: shortcutNumber)
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
    }

    private func commandLabel(_ action: CommandPaletteAction, shortcutNumber: Int?) -> some View {
        HStack(spacing: layoutMetrics.commandLabelSpacing) {
            Image(systemName: action.systemImage)
                .font(.title3)
                .foregroundStyle(action.isEnabled ? .primary : .secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(action.isEnabled ? .primary : .secondary)
                Text(action.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let signalBadge = action.signalBadge {
                commandSignalBadge(signalBadge)
                    .help(signalBadge.helpText)
            }

            if let sourceBadgeTitle = action.sourceKind.badgeTitle {
                commandSourceBadge(sourceBadgeTitle)
                    .help(action.sourceKind.helpText ?? sourceBadgeTitle)
            }

            if let aliasBadgeTitle = action.aliasBadgeTitle {
                commandAliasBadge(aliasBadgeTitle)
                    .help(action.aliasHelpText ?? aliasBadgeTitle)
            }

            if let hotKeyBadgeTitle = action.hotKeyBadgeTitle {
                shortcutBadge(hotKeyBadgeTitle)
                    .help(action.hotKeyHelpText ?? hotKeyBadgeTitle)
            }

            if !action.isEnabled {
                Text(action.disabledReason)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                if let shortcutNumber {
                    shortcutBadge("⌘\(shortcutNumber)")
                }
                if let dedicatedShortcutBadgeTitle = CommandPaletteAction.dedicatedShortcutBadgeTitle(
                    for: action.id
                ) {
                    shortcutBadge(dedicatedShortcutBadgeTitle)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func commandSourceBadge(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.12))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    private func commandAliasBadge(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.14))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    private func commandSignalBadge(_ badge: CommandPaletteAction.SignalBadge) -> some View {
        Text(badge.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(commandSignalBadgeForegroundColor(badge.tone))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(commandSignalBadgeBackgroundColor(badge.tone))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    private func commandSignalBadgeForegroundColor(_ tone: CommandPaletteAction.SignalBadge.Tone) -> Color {
        switch tone {
        case .high:
            return .green
        case .medium:
            return .orange
        case .low:
            return .yellow
        }
    }

    private func commandSignalBadgeBackgroundColor(_ tone: CommandPaletteAction.SignalBadge.Tone) -> Color {
        switch tone {
        case .high:
            return Color.green.opacity(0.18)
        case .medium:
            return Color.orange.opacity(0.18)
        case .low:
            return Color.yellow.opacity(0.2)
        }
    }

    private func recommendationMomentumBadge(
        _ badge: CommandPaletteAction.RecommendationMomentumBadge
    ) -> some View {
        let isPulsing = isRecommendationMomentumPulseActive &&
            activeRecommendationMomentumPulseToken == selectedActionRecommendationOpportunityToken
        return Text(badge.title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(recommendationMomentumBadgeForegroundColor(badge.tone))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(recommendationMomentumBadgeBackgroundColor(badge.tone))
            .clipShape(Capsule())
            .lineLimit(1)
            .overlay {
                Capsule()
                    .stroke(
                        recommendationMomentumBadgeForegroundColor(badge.tone).opacity(0.72),
                        lineWidth: 1.2
                    )
                    .scaleEffect(isPulsing ? 1.12 : 1)
                    .opacity(isPulsing ? 0.84 : 0)
            }
            .scaleEffect(isPulsing ? 1.07 : 1)
            .help(badge.helpText)
    }

    private func recommendationMomentumBadgeForegroundColor(
        _ tone: CommandPaletteAction.RecommendationMomentumBadge.Tone
    ) -> Color {
        switch tone {
        case .hot:
            return .green
        case .warm:
            return .mint
        case .cooling:
            return .orange
        case .cold:
            return .secondary
        }
    }

    private func recommendationMomentumBadgeBackgroundColor(
        _ tone: CommandPaletteAction.RecommendationMomentumBadge.Tone
    ) -> Color {
        switch tone {
        case .hot:
            return Color.green.opacity(0.2)
        case .warm:
            return Color.mint.opacity(0.2)
        case .cooling:
            return Color.orange.opacity(0.2)
        case .cold:
            return Color.secondary.opacity(0.14)
        }
    }

    private func selectedActionRecommendationPanel(
        _ model: CommandPaletteAction.RecommendationPanelModel,
        ctaAction: CommandPaletteAction?
    ) -> some View {
        let accentColor = commandSignalBadgeForegroundColor(model.tone)
        let backgroundColor = commandSignalBadgeBackgroundColor(model.tone).opacity(0.42)
        let momentumRescueCue = selectedActionRecommendationPairMomentumRescueCue
        let badge = CommandPaletteAction.SignalBadge(
            title: model.badgeTitle,
            tone: model.tone,
            helpText: model.detail,
            recommendedActionID: model.recommendedActionID,
            recommendedActionTitle: model.recommendedActionTitle
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                Text(model.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
                Spacer(minLength: 8)
                HStack(spacing: 6) {
                    commandSignalBadge(badge)
                    if let selectedActionRecommendationPairMomentumBadge {
                        recommendationMomentumBadge(selectedActionRecommendationPairMomentumBadge)
                    }
                }
            }

            Text(model.actionTitle)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(model.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let selectedActionRecommendationPairSignalLine {
                Text(selectedActionRecommendationPairSignalLine)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
            }

            if let selectedActionRecommendationConversionSignalLine {
                Text(selectedActionRecommendationConversionSignalLine)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
            }

            if let selectedActionRecommendationMomentumRescueSignalLine {
                Text(selectedActionRecommendationMomentumRescueSignalLine)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.orange)
                    .lineLimit(1)
            }

            if let momentumRescueCue {
                Label(momentumRescueCue.title, systemImage: momentumRescueCue.systemImage)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                    .help(momentumRescueCue.helpText)
            }

            if let ctaAction {
                let runTitle = model.recommendedActionTitle ?? ctaAction.title
                let ctaTitle = momentumRescueCue == nil
                    ? "Run \(runTitle)"
                    : "Rescue momentum: Run \(runTitle)"
                let ctaSystemImage = momentumRescueCue?.systemImage ?? "arrow.forward.circle.fill"
                Button {
                    run(
                        ctaAction,
                        recommendationSourceActionID: model.actionID
                    )
                } label: {
                    Label(
                        ctaTitle,
                        systemImage: ctaSystemImage
                    )
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(momentumRescueCue == nil ? accentColor : .orange)
                .help(momentumRescueCue?.helpText ?? "Run recommended action now")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1)
        }
        .help(model.detail)
    }

    private func shortcutBadge(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, layoutMetrics.shortcutBadgeHorizontalPadding)
            .padding(.vertical, layoutMetrics.shortcutBadgeVerticalPadding)
            .background(Color.secondary.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    private func favoriteButton(_ action: CommandPaletteAction) -> some View {
        let isFavorite = usageStore.isFavorite(actionID: action.id)

        return Button {
            usageStore.toggleFavorite(actionID: action.id)
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.callout.weight(.semibold))
                .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .help(isFavorite ? "Remove Favorite" : "Add Favorite")
    }

    private var footer: some View {
        HStack(spacing: layoutMetrics.footerSpacing) {
            if settings.llmEnabled {
                Label("LLM on", systemImage: "sparkles")
            } else {
                Label("Local mode", systemImage: "lock.shield")
            }

            if !state.lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Label("Text ready", systemImage: "text.quote")
            }

            if state.lastImageData != nil {
                Label("Image ready", systemImage: "photo")
            }

            if !usageStore.favoriteActionIDs.isEmpty {
                Label("Favorites", systemImage: "star.fill")
            }

            Spacer()

            shortcutBadge("Return")
            Text("Run")
                .font(.caption)
                .foregroundStyle(.secondary)
            shortcutBadge("⌘1-9")
            Text("Quick run")
                .font(.caption)
                .foregroundStyle(.secondary)
            if showFameTopPicksExtras, launchRecoveryDedicatedShortcutAction != nil {
                shortcutBadge("⌥⌘R")
                Text("Launch recovery")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if showFameTopPicksExtras, autoOpsBundleStatusDedicatedShortcutAction != nil {
                shortcutBadge("⌥⌘O")
                Text("Auto bundle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if showFameTopPicksExtras, launchRescueAutoStatusDedicatedShortcutAction != nil {
                shortcutBadge("⌥⌘L")
                Text("Rescue auto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if showFameTopPicksExtras, selectedActionRecommendationCTAAction != nil {
                shortcutBadge("⌘↩")
                Text("Recommend")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !activeActionPanelActions.isEmpty {
                shortcutBadge("⌘K")
                Text("Actions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            shortcutBadge("⌃0-8")
            Text("Groups")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private var actionPanelOverlay: some View {
        VStack(alignment: .leading, spacing: layoutMetrics.actionPanelSpacing) {
            HStack(spacing: 8) {
                Label("Actions", systemImage: "square.grid.2x2")
                    .font(.caption.weight(.semibold))
                Spacer()
                shortcutBadge("⌘K")
                    .help("Toggle action panel")
            }

            if let activeAction {
                Text(activeAction.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(spacing: layoutMetrics.actionPanelRowSpacing) {
                ForEach(activeActionPanelActions) { action in
                    secondaryActionButton(action)
                }
            }

            HStack(spacing: 8) {
                shortcutBadge("Return")
                Text("Run")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                shortcutBadge("Esc")
                Text("Close")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(layoutMetrics.actionPanelPadding)
        .frame(width: layoutMetrics.actionPanelWidth, alignment: .leading)
        .background(Color(nsColor: .underPageBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.18))
        )
        .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 8)
    }

    private func secondaryActionButton(_ action: CommandPaletteAction.SecondaryAction) -> some View {
        Button {
            runSecondaryAction(action)
        } label: {
            secondaryActionLabel(action)
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
    }

    private func secondaryActionLabel(_ action: CommandPaletteAction.SecondaryAction) -> some View {
        let isSelected = activeSecondaryActionID == action.id
        return HStack(spacing: layoutMetrics.commandLabelSpacing) {
            Image(systemName: action.systemImage)
                .font(.body)
                .foregroundStyle(action.isEnabled ? .primary : .secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(action.isEnabled ? .primary : .secondary)
                Text(action.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !action.isEnabled {
                Text(action.disabledReason)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, layoutMetrics.secondaryRowHorizontalPadding)
        .padding(.vertical, layoutMetrics.secondaryRowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .onHover { isHovering in
            if isHovering && !isKeyboardNavigating {
                selectedSecondaryActionID = action.id
            }
        }
    }

    @ViewBuilder
    private var actionPanelToggleShortcutRegistrar: some View {
        if !activeActionPanelActions.isEmpty {
            Button {
                toggleActionPanel()
            } label: {
                Text(" ")
            }
            .keyboardShortcut("k", modifiers: [.command])
            .frame(width: 0, height: 0)
            .opacity(0.001)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var launchRecoveryDedicatedShortcutRegistrar: some View {
        if let action = launchRecoveryDedicatedShortcutAction {
            Button {
                run(action)
            } label: {
                Text(" ")
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .frame(width: 0, height: 0)
            .opacity(0.001)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var autoOpsBundleStatusDedicatedShortcutRegistrar: some View {
        if let action = autoOpsBundleStatusDedicatedShortcutAction {
            Button {
                run(action)
            } label: {
                Text(" ")
            }
            .keyboardShortcut("o", modifiers: [.command, .option])
            .frame(width: 0, height: 0)
            .opacity(0.001)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var launchRescueAutoStatusDedicatedShortcutRegistrar: some View {
        if let action = launchRescueAutoStatusDedicatedShortcutAction {
            Button {
                run(action)
            } label: {
                Text(" ")
            }
            .keyboardShortcut("l", modifiers: [.command, .option])
            .frame(width: 0, height: 0)
            .opacity(0.001)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var selectedActionRecommendationShortcutRegistrar: some View {
        if let ctaAction = selectedActionRecommendationCTAAction,
           let selectedActionRecommendationPanelModel {
            Button {
                run(
                    ctaAction,
                    recommendationSourceActionID: selectedActionRecommendationPanelModel.actionID
                )
            } label: {
                Text(" ")
            }
            .keyboardShortcut(KeyEquivalent.return, modifiers: [.command])
            .frame(width: 0, height: 0)
            .opacity(0.001)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        switch direction {
        case .down:
            isKeyboardNavigating = true
            if isActionPanelPresented {
                shiftSecondarySelection(by: 1)
            } else {
                shiftSelection(by: 1)
            }
        case .up:
            isKeyboardNavigating = true
            if isActionPanelPresented {
                shiftSecondarySelection(by: -1)
            } else {
                shiftSelection(by: -1)
            }
        default:
            break
        }
    }

    private func shiftSelection(by offset: Int) {
        selectedActionID = CommandPaletteWindow.shiftedSelectionID(
            actionIDs: filteredActions.map(\.id),
            currentID: activeActionID,
            offset: offset
        )
    }

    private func runActiveAction() {
        if isActionPanelPresented, let activeSecondaryAction {
            runSecondaryAction(activeSecondaryAction)
            return
        }
        guard let activeActionID,
              let action = filteredActions.first(where: { $0.id == activeActionID }) else {
            return
        }
        run(action)
    }

    private func shiftSecondarySelection(by offset: Int) {
        selectedSecondaryActionID = CommandPaletteWindow.shiftedSelectionID(
            actionIDs: activeActionPanelActions.map(\.id),
            currentID: activeSecondaryActionID,
            offset: offset
        )
    }

    private func handleExitCommand() {
        if isActionPanelPresented {
            dismissActionPanel()
            return
        }
        close()
    }

    private func toggleActionPanel() {
        guard !activeActionPanelActions.isEmpty else { return }
        if isActionPanelPresented {
            dismissActionPanel()
            return
        }
        isKeyboardNavigating = true
        withAnimation(.easeOut(duration: 0.12)) {
            isActionPanelPresented = true
        }
        selectedSecondaryActionID = activeActionPanelActions.first?.id
    }

    private func dismissActionPanel() {
        withAnimation(.easeOut(duration: 0.12)) {
            isActionPanelPresented = false
        }
        selectedSecondaryActionID = nil
    }

    private func normalizeActionPanelSelection() {
        guard isActionPanelPresented else {
            selectedSecondaryActionID = nil
            return
        }
        guard !activeActionPanelActions.isEmpty else {
            dismissActionPanel()
            return
        }
        selectedSecondaryActionID = CommandPaletteWindow.normalizedSelectionID(
            actionIDs: activeActionPanelActions.map(\.id),
            currentID: selectedSecondaryActionID
        )
    }

    private func runSecondaryAction(_ action: CommandPaletteAction.SecondaryAction) {
        guard action.isEnabled else { return }
        prepareRun(action.id)
        if action.closesPanelAfterRun {
            dismissActionPanel()
        }
        if action.closesPaletteAfterRun {
            close()
        }
        action.run()
    }

    private func run(
        _ action: CommandPaletteAction,
        recommendationSourceActionID: String? = nil,
        fameMomentumPanelSourceActionID: String? = nil,
        fameMomentumPanelRouteStabilizationActive: Bool = false
    ) {
        guard action.isEnabled else { return }
        let previousCadenceExecutionKitStreak = cadenceExecutionKitStreak
        let previousBestChannelLaunchPackPressureTrend = bestChannelLaunchPackPressureTrend
        let wasCadenceExecutionKitAction = CommandPaletteCadenceExecutionKitStreak.isCadenceExecutionKitAction(
            action.id
        )
        let currentTopPickIDs = Set(topPickActions.map(\.id))
        let wasTopPick = currentTopPickIDs.contains(action.id)
        if let pressureCard = bestChannelLaunchPackPressureCard,
           action.id == pressureCard.actionID,
           session.recordBestChannelLaunchPackPressureConversion(tone: pressureCard.tone) {
            recordBestChannelLaunchPackPressureActivity(
                kind: .conversion,
                tone: pressureCard.tone
            )
            recordBestChannelLaunchPackPressureTrendTransitionIfNeeded(
                previousTrend: previousBestChannelLaunchPackPressureTrend,
                tone: pressureCard.tone
            )
        }
        session.recordRun(wasTopPick: wasTopPick)
        if let recommendationSourceActionID {
            session.recordRecommendationConversion(
                sourceActionID: recommendationSourceActionID,
                recommendedActionID: action.id
            )
        }
        if fameMomentumPanelSourceActionID != nil {
            session.recordFameMomentumPanelConversion(actionID: action.id)
        }
        if fameMomentumPanelRouteStabilizationActive {
            session.recordFameMomentumPanelRouteStabilizationRun()
        }
        session.recordLaunchRecoveryHotKeyInterventionRun(actionID: action.id)
        usageStore.recordRun(actionID: action.id)
        recordRun(action)
        prepareRun(action.id)

        if wasCadenceExecutionKitAction,
           let pulse = CommandPaletteCadenceExecutionKitStreak.momentumPulse(
               previousStreak: previousCadenceExecutionKitStreak,
               nextStreak: cadenceExecutionKitStreak,
               bestStreak: cadenceExecutionKitBestStreak
           ) {
            session.recordCadenceExecutionKitMomentumPulse(pulse)
        }

        close()
        action.run()
    }
}
