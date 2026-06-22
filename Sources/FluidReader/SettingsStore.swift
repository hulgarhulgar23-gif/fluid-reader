import AVFoundation
import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private var isLoading = true

    @Published var voiceIdentifier: String {
        didSet { save("voiceIdentifier", voiceIdentifier) }
    }

    @Published var speechRate: Double {
        didSet { save("speechRate", speechRate) }
    }

    @Published var speechPitch: Double {
        didSet { save("speechPitch", speechPitch) }
    }

    @Published var speechVolume: Double {
        didSet { save("speechVolume", speechVolume) }
    }

    @Published var readAfterPick: Bool {
        didSet { save("readAfterPick", readAfterPick) }
    }

    @Published var autoCopyNewText: Bool {
        didSet { save("autoCopyNewText", autoCopyNewText) }
    }

    @Published var autoPastePickedText: Bool {
        didSet { save("autoPastePickedText", autoPastePickedText) }
    }

    @Published var autoPasteLLMAnswers: Bool {
        didSet { save("autoPasteLLMAnswers", autoPasteLLMAnswers) }
    }

    @Published var saveRecentItems: Bool {
        didSet { save("saveRecentItems", saveRecentItems) }
    }

    @Published var saveClipboardHistory: Bool {
        didSet { save("saveClipboardHistory", saveClipboardHistory) }
    }

    @Published var readerAlwaysOnTop: Bool {
        didSet { save("readerAlwaysOnTop", readerAlwaysOnTop) }
    }

    @Published var showMenuBarItem: Bool {
        didSet { save(AppDefaults.showMenuBarItemKey, showMenuBarItem) }
    }

    @Published var launcherCompactMode: Bool {
        didSet { save(AppDefaults.launcherCompactModeKey, launcherCompactMode) }
    }

    @Published var launcherIndexedRootPaths: [String] {
        didSet {
            let normalized = LocalFileSearchCatalog.normalizedRootPaths(launcherIndexedRootPaths)
            if normalized != launcherIndexedRootPaths {
                launcherIndexedRootPaths = normalized
                return
            }
            save(AppDefaults.launcherIndexedRootPathsKey, normalized)
        }
    }

    @Published var frontWindowGapPoints: Int {
        didSet {
            let normalized = AppDefaults.normalizedFrontWindowGapPoints(frontWindowGapPoints)
            if normalized != frontWindowGapPoints {
                frontWindowGapPoints = normalized
                return
            }
            save(AppDefaults.frontWindowGapPointsKey, normalized)
        }
    }

    @Published var frontWindowCycleProfile: String {
        didSet {
            let normalized = FrontWindowManager.normalizedCycleProfileRawValue(frontWindowCycleProfile)
            if normalized != frontWindowCycleProfile {
                frontWindowCycleProfile = normalized
                return
            }
            guard !isLoading else { return }
            if normalized == AppDefaults.frontWindowCycleProfile {
                defaults.removeObject(forKey: AppDefaults.frontWindowCycleProfileKey)
                return
            }
            save(AppDefaults.frontWindowCycleProfileKey, normalized)
        }
    }

    @Published var frontWindowCustomCycleCommandIDs: [String] {
        didSet {
            let normalized = FrontWindowManager.normalizedCustomCycleCommandRawValues(
                frontWindowCustomCycleCommandIDs
            )
            if normalized != frontWindowCustomCycleCommandIDs {
                frontWindowCustomCycleCommandIDs = normalized
                return
            }
            save(AppDefaults.frontWindowCustomCycleCommandIDsKey, normalized)
        }
    }

    @Published var fameAutoPulseAfterSnapshot: Bool {
        didSet { save("fameAutoPulseAfterSnapshot", fameAutoPulseAfterSnapshot) }
    }

    @Published var fameAutoPulseQuietMode: Bool {
        didSet { save("fameAutoPulseQuietMode", fameAutoPulseQuietMode) }
    }

    @Published var fameMorningBriefOnLaunch: Bool {
        didSet { save("fameMorningBriefOnLaunch", fameMorningBriefOnLaunch) }
    }

    @Published var fameMorningBriefQuietMode: Bool {
        didSet { save("fameMorningBriefQuietMode", fameMorningBriefQuietMode) }
    }

    @Published var fameLaunchThresholdAlertsEnabled: Bool {
        didSet { save("fameLaunchThresholdAlertsEnabled", fameLaunchThresholdAlertsEnabled) }
    }

    @Published var fameLaunchHealthPulseEnabled: Bool {
        didSet { save("fameLaunchHealthPulseEnabled", fameLaunchHealthPulseEnabled) }
    }

    @Published var fameLaunchHealthPulseCooldownSeconds: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(
                fameLaunchHealthPulseCooldownSeconds
            )
            if normalized != fameLaunchHealthPulseCooldownSeconds {
                fameLaunchHealthPulseCooldownSeconds = normalized
                return
            }
            save("fameLaunchHealthPulseCooldownSeconds", normalized)
        }
    }

    @Published var fameLaunchHealthPressureAutoRescueEnabled: Bool {
        didSet {
            save(
                "fameLaunchHealthPressureAutoRescueEnabled",
                fameLaunchHealthPressureAutoRescueEnabled
            )
        }
    }

    @Published var fameLaunchHealthPressureAutoRescueCooldownHours: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(
                fameLaunchHealthPressureAutoRescueCooldownHours
            )
            if normalized != fameLaunchHealthPressureAutoRescueCooldownHours {
                fameLaunchHealthPressureAutoRescueCooldownHours = normalized
                return
            }
            save("fameLaunchHealthPressureAutoRescueCooldownHours", normalized)
        }
    }

    @Published var fameAutoOpsBundleCooldownMinutes: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(fameAutoOpsBundleCooldownMinutes)
            if normalized != fameAutoOpsBundleCooldownMinutes {
                fameAutoOpsBundleCooldownMinutes = normalized
                return
            }
            save("fameAutoOpsBundleCooldownMinutes", normalized)
        }
    }

    @Published var fameLaunchRescueBurstAutoCooldownMinutes: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(
                fameLaunchRescueBurstAutoCooldownMinutes
            )
            if normalized != fameLaunchRescueBurstAutoCooldownMinutes {
                fameLaunchRescueBurstAutoCooldownMinutes = normalized
                return
            }
            save("fameLaunchRescueBurstAutoCooldownMinutes", normalized)
        }
    }

    @Published var fameExceptionalLoopAutoRecoveryLaneMissesRequired: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                fameExceptionalLoopAutoRecoveryLaneMissesRequired
            )
            if normalized != fameExceptionalLoopAutoRecoveryLaneMissesRequired {
                fameExceptionalLoopAutoRecoveryLaneMissesRequired = normalized
                return
            }
            save(AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequiredKey, normalized)
        }
    }

    @Published var fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired: Int {
        didSet {
            let normalized = AppDefaults
                .normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                    fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
                )
            if normalized != fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired {
                fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired = normalized
                return
            }
            save(
                AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredKey,
                normalized
            )
        }
    }

    @Published var fameExceptionalLoopAutoRecoveryLaneCooldownMinutes: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            )
            if normalized != fameExceptionalLoopAutoRecoveryLaneCooldownMinutes {
                fameExceptionalLoopAutoRecoveryLaneCooldownMinutes = normalized
                return
            }
            save(AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutesKey, normalized)
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoCoachEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabledKey,
                fameLaunchRecoveryHotKeyAutoCoachEnabled
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(
                fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
            )
            if normalized != fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes {
                fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes = normalized
                return
            }
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutesKey,
                normalized
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoRescueEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabledKey,
                fameLaunchRecoveryHotKeyAutoRescueEnabled
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(
                fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
            )
            if normalized != fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes {
                fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes = normalized
                return
            }
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutesKey,
                normalized
            )
        }
    }

    @Published var fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabledKey,
                fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
            )
        }
    }

    @Published var fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes: Int {
        didSet {
            let normalized =
                AppDefaults.normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                    fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
                )
            if normalized != fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes {
                fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes = normalized
                return
            }
            save(
                AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutesKey,
                normalized
            )
        }
    }

    @Published var fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens: Int {
        didSet {
            let normalized =
                AppDefaults
                .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                    fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
                )
            if normalized != fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens {
                fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens = normalized
                return
            }
            save(
                AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpensKey,
                normalized
            )
        }
    }

    @Published var fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled: Bool {
        didSet {
            save(
                AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabledKey,
                fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabledKey,
                fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(
                fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes
            )
            if normalized != fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes {
                fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes = normalized
                return
            }
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutesKey,
                normalized
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(
                fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap
            )
            if normalized != fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap {
                fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap = normalized
                return
            }
            save(
                AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapKey,
                normalized
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(
                fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens
            )
            if normalized != fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens {
                fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens = normalized
                return
            }
            save(
                AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpensKey,
                normalized
            )
        }
    }

    @Published var fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabledKey,
                fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled
            )
        }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet { save("soundEffectsEnabled", soundEffectsEnabled) }
    }

    @Published var effectVolume: Double {
        didSet { save("effectVolume", effectVolume) }
    }

    @Published var soundStyle: String {
        didSet { save("soundStyle", soundStyle) }
    }

    @Published var feelIntensity: Double {
        didSet { save("feelIntensity", feelIntensity) }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { save("hapticFeedbackEnabled", hapticFeedbackEnabled) }
    }

    @Published var topPickMilestoneFeedbackEnabled: Bool {
        didSet { save("topPickMilestoneFeedbackEnabled", topPickMilestoneFeedbackEnabled) }
    }

    @Published var fameCadenceExecutionKitBadgeEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameCadenceExecutionKitBadgeEnabledKey,
                fameCadenceExecutionKitBadgeEnabled
            )
        }
    }

    @Published var fameCadenceExecutionKitMomentumCardEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameCadenceExecutionKitMomentumCardEnabledKey,
                fameCadenceExecutionKitMomentumCardEnabled
            )
        }
    }

    @Published var fameCadenceAutopilotCueCooldownSeconds: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(
                fameCadenceAutopilotCueCooldownSeconds
            )
            if normalized != fameCadenceAutopilotCueCooldownSeconds {
                fameCadenceAutopilotCueCooldownSeconds = normalized
                return
            }
            save("fameCadenceAutopilotCueCooldownSeconds", normalized)
        }
    }

    @Published var fameCadenceAutopilotCelebrationIntensity: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
                fameCadenceAutopilotCelebrationIntensity
            )
            if normalized != fameCadenceAutopilotCelebrationIntensity {
                fameCadenceAutopilotCelebrationIntensity = normalized
                return
            }
            save("fameCadenceAutopilotCelebrationIntensity", normalized)
        }
    }

    @Published var fameOnboardingNudgeEnabled: Bool {
        didSet {
            save(
                AppDefaults.fameOnboardingNudgeEnabledKey,
                fameOnboardingNudgeEnabled
            )
        }
    }

    @Published var fameOnboardingNudgeWindowDays: Int {
        didSet {
            let normalized = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
                fameOnboardingNudgeWindowDays
            )
            if normalized != fameOnboardingNudgeWindowDays {
                fameOnboardingNudgeWindowDays = normalized
                return
            }
            save(AppDefaults.fameOnboardingNudgeWindowDaysKey, normalized)
        }
    }

    @Published var ocrLanguageCode: String {
        didSet { save("ocrLanguageCode", ocrLanguageCode) }
    }

    @Published var llmEnabled: Bool {
        didSet { save("llmEnabled", llmEnabled) }
    }

    @Published var llmModel: String {
        didSet { save("llmModel", llmModel) }
    }

    @Published var llmProvider: String {
        didSet { save("llmProvider", llmProvider) }
    }

    @Published var llmEndpoint: String {
        didSet { save("llmEndpoint", llmEndpoint) }
    }

    @Published var openAIAPIKey: String {
        didSet {
            guard !isLoading else { return }
            KeychainStore.set(openAIAPIKey, service: "FluidReader", account: "openai-api-key")
        }
    }

    @Published var useCloudVoiceForLLM: Bool {
        didSet { save("useCloudVoiceForLLM", useCloudVoiceForLLM) }
    }

    @Published var cloudVoiceModel: String {
        didSet { save("cloudVoiceModel", cloudVoiceModel) }
    }

    @Published var cloudVoiceName: String {
        didSet { save("cloudVoiceName", cloudVoiceName) }
    }

    @Published var cloudVoiceInstructions: String {
        didSet { save("cloudVoiceInstructions", cloudVoiceInstructions) }
    }

    @Published var customPromptTitle: String {
        didSet { save("customPromptTitle", customPromptTitle) }
    }

    @Published var customPromptText: String {
        didSet { save("customPromptText", customPromptText) }
    }

    @Published var customPromptTitle2: String {
        didSet { save("customPromptTitle2", customPromptTitle2) }
    }

    @Published var customPromptText2: String {
        didSet { save("customPromptText2", customPromptText2) }
    }

    @Published var customPromptTitle3: String {
        didSet { save("customPromptTitle3", customPromptTitle3) }
    }

    @Published var customPromptText3: String {
        didSet { save("customPromptText3", customPromptText3) }
    }

    var customPromptInputs: [CustomPromptInput] {
        [
            CustomPromptInput(id: "custom", title: customPromptTitle, prompt: customPromptText),
            CustomPromptInput(id: "custom-2", title: customPromptTitle2, prompt: customPromptText2),
            CustomPromptInput(id: "custom-3", title: customPromptTitle3, prompt: customPromptText3)
        ]
    }

    var frontWindowCycleProfileValue: FrontWindowCycleProfile {
        get { FrontWindowCycleProfile(rawValue: frontWindowCycleProfile) ?? .full }
        set { frontWindowCycleProfile = newValue.rawValue }
    }

    var frontWindowCustomCycleCommands: [FrontWindowLayoutCommand] {
        get { FrontWindowManager.customCycleCommands(fromRawValues: frontWindowCustomCycleCommandIDs) }
        set {
            frontWindowCustomCycleCommandIDs = FrontWindowLayoutCommand.cycleCommandRawValues(newValue)
        }
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices()
            .sorted { left, right in
                if left.language == right.language {
                    return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
                }
                return left.language.localizedCaseInsensitiveCompare(right.language) == .orderedAscending
            }
    }

    private init() {
        defaults.register(defaults: [
            "speechRate": 0.48,
            "speechPitch": 1.0,
            "speechVolume": 0.92,
            "readAfterPick": true,
            "autoCopyNewText": AppDefaults.autoCopyNewText,
            "autoPastePickedText": AppDefaults.autoPastePickedText,
            "autoPasteLLMAnswers": AppDefaults.autoPasteLLMAnswers,
            "saveRecentItems": AppDefaults.saveRecentItems,
            "saveClipboardHistory": AppDefaults.saveClipboardHistory,
            "readerAlwaysOnTop": AppDefaults.readerAlwaysOnTop,
            AppDefaults.showMenuBarItemKey: AppDefaults.showMenuBarItem,
            AppDefaults.launcherCompactModeKey: AppDefaults.launcherCompactMode,
            AppDefaults.launcherIndexedRootPathsKey: LocalFileSearchCatalog.defaultRootPaths(),
            AppDefaults.frontWindowGapPointsKey: AppDefaults.frontWindowGapPoints,
            AppDefaults.frontWindowCycleProfileKey: AppDefaults.frontWindowCycleProfile,
            AppDefaults.frontWindowCustomCycleCommandIDsKey:
                FrontWindowManager.normalizedCustomCycleCommandRawValues([]),
            "fameAutoPulseAfterSnapshot": AppDefaults.fameAutoPulseAfterSnapshot,
            "fameAutoPulseQuietMode": AppDefaults.fameAutoPulseQuietMode,
            "fameMorningBriefOnLaunch": AppDefaults.fameMorningBriefOnLaunch,
            "fameMorningBriefQuietMode": AppDefaults.fameMorningBriefQuietMode,
            "fameLaunchThresholdAlertsEnabled": AppDefaults.fameLaunchThresholdAlertsEnabled,
            "fameLaunchHealthPulseEnabled": AppDefaults.fameLaunchHealthPulseEnabled,
            "fameLaunchHealthPulseCooldownSeconds": AppDefaults.fameLaunchHealthPulseCooldownSeconds,
            "fameLaunchHealthPressureAutoRescueEnabled": AppDefaults.fameLaunchHealthPressureAutoRescueEnabled,
            "fameLaunchHealthPressureAutoRescueCooldownHours": AppDefaults.fameLaunchHealthPressureAutoRescueCooldownHours,
            "fameAutoOpsBundleCooldownMinutes": AppDefaults.fameAutoOpsBundleCooldownMinutes,
            "fameLaunchRescueBurstAutoCooldownMinutes": AppDefaults.fameLaunchRescueBurstAutoCooldownMinutes,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequiredKey:
                AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredKey:
                AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutesKey:
                AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes,
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabledKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled,
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutesKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes,
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabledKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled,
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutesKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabledKey:
                AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutesKey:
                AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpensKey:
                AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabledKey:
                AppDefaults
                .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled,
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabledKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutesKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
            AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
            AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpensKey: AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens,
            AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabledKey: AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled,
            "soundEffectsEnabled": true,
            "effectVolume": 0.72,
            "soundStyle": "glass",
            "feelIntensity": 0.84,
            "hapticFeedbackEnabled": true,
            "topPickMilestoneFeedbackEnabled": true,
            AppDefaults.fameCadenceExecutionKitBadgeEnabledKey: AppDefaults.fameCadenceExecutionKitBadgeEnabled,
            AppDefaults.fameCadenceExecutionKitMomentumCardEnabledKey: AppDefaults.fameCadenceExecutionKitMomentumCardEnabled,
            "fameCadenceAutopilotCueCooldownSeconds": AppDefaults.fameCadenceAutopilotCueCooldownSeconds,
            "fameCadenceAutopilotCelebrationIntensity": AppDefaults.fameCadenceAutopilotCelebrationIntensity,
            AppDefaults.fameOnboardingNudgeEnabledKey: AppDefaults.fameOnboardingNudgeEnabled,
            AppDefaults.fameOnboardingNudgeWindowDaysKey: AppDefaults.fameOnboardingNudgeWindowDays,
            "ocrLanguageCode": "en-US",
            "llmEnabled": false,
            "llmModel": AppDefaults.llmModel,
            "llmProvider": AppDefaults.llmProvider,
            "llmEndpoint": AppDefaults.openAICompatibleChatEndpoint,
            "useCloudVoiceForLLM": false,
            "cloudVoiceModel": AppDefaults.cloudVoiceModel,
            "cloudVoiceName": AppDefaults.cloudVoiceName,
            "cloudVoiceInstructions": AppDefaults.cloudVoiceInstructions,
            "customPromptTitle": AppDefaults.customPromptTitle,
            "customPromptText": AppDefaults.customPromptText,
            "customPromptTitle2": "",
            "customPromptText2": "",
            "customPromptTitle3": "",
            "customPromptText3": ""
        ])

        let calmLaunchMigrationKey = "didMigrateMorningBriefCalmLaunchDefault"
        if !defaults.bool(forKey: calmLaunchMigrationKey) {
            defaults.set(AppDefaults.fameMorningBriefOnLaunch, forKey: "fameMorningBriefOnLaunch")
            defaults.set(AppDefaults.fameMorningBriefQuietMode, forKey: "fameMorningBriefQuietMode")
            defaults.set(true, forKey: calmLaunchMigrationKey)
        }

        voiceIdentifier = defaults.string(forKey: "voiceIdentifier") ?? Self.defaultVoiceIdentifier()
        speechRate = defaults.double(forKey: "speechRate")
        speechPitch = defaults.double(forKey: "speechPitch")
        speechVolume = defaults.double(forKey: "speechVolume")
        readAfterPick = defaults.bool(forKey: "readAfterPick")
        autoCopyNewText = defaults.bool(forKey: "autoCopyNewText")
        autoPastePickedText = defaults.bool(forKey: "autoPastePickedText")
        autoPasteLLMAnswers = defaults.bool(forKey: "autoPasteLLMAnswers")
        saveRecentItems = defaults.bool(forKey: "saveRecentItems")
        saveClipboardHistory = defaults.bool(forKey: "saveClipboardHistory")
        readerAlwaysOnTop = defaults.bool(forKey: "readerAlwaysOnTop")
        showMenuBarItem = defaults.object(forKey: AppDefaults.showMenuBarItemKey) as? Bool
            ?? AppDefaults.showMenuBarItem
        launcherCompactMode = defaults.object(forKey: AppDefaults.launcherCompactModeKey) as? Bool
            ?? AppDefaults.launcherCompactMode
        launcherIndexedRootPaths = LocalFileSearchCatalog.normalizedRootPaths(
            defaults.stringArray(forKey: AppDefaults.launcherIndexedRootPathsKey)
                ?? LocalFileSearchCatalog.defaultRootPaths()
        )
        frontWindowGapPoints = AppDefaults.normalizedFrontWindowGapPoints(
            defaults.object(forKey: AppDefaults.frontWindowGapPointsKey) as? Int
                ?? AppDefaults.frontWindowGapPoints
        )
        frontWindowCycleProfile = FrontWindowManager.normalizedCycleProfileRawValue(
            defaults.string(forKey: AppDefaults.frontWindowCycleProfileKey)
                ?? AppDefaults.frontWindowCycleProfile
        )
        frontWindowCustomCycleCommandIDs = FrontWindowManager.normalizedCustomCycleCommandRawValues(
            defaults.stringArray(forKey: AppDefaults.frontWindowCustomCycleCommandIDsKey) ?? []
        )
        fameAutoPulseAfterSnapshot = defaults.bool(forKey: "fameAutoPulseAfterSnapshot")
        fameAutoPulseQuietMode = defaults.bool(forKey: "fameAutoPulseQuietMode")
        fameMorningBriefOnLaunch = defaults.bool(forKey: "fameMorningBriefOnLaunch")
        fameMorningBriefQuietMode = defaults.bool(forKey: "fameMorningBriefQuietMode")
        fameLaunchThresholdAlertsEnabled = defaults.bool(forKey: "fameLaunchThresholdAlertsEnabled")
        fameLaunchHealthPulseEnabled = defaults.bool(forKey: "fameLaunchHealthPulseEnabled")
        fameLaunchHealthPulseCooldownSeconds = AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(
            defaults.integer(forKey: "fameLaunchHealthPulseCooldownSeconds")
        )
        fameLaunchHealthPressureAutoRescueEnabled = defaults.bool(
            forKey: "fameLaunchHealthPressureAutoRescueEnabled"
        )
        fameLaunchHealthPressureAutoRescueCooldownHours =
            AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(
                defaults.integer(forKey: "fameLaunchHealthPressureAutoRescueCooldownHours")
            )
        fameAutoOpsBundleCooldownMinutes = AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(
            defaults.integer(forKey: "fameAutoOpsBundleCooldownMinutes")
        )
        fameLaunchRescueBurstAutoCooldownMinutes = AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(
            defaults.integer(forKey: "fameLaunchRescueBurstAutoCooldownMinutes")
        )
        fameExceptionalLoopAutoRecoveryLaneMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                defaults.integer(
                    forKey: AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequiredKey
                )
            )
        fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                defaults.integer(
                    forKey: AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredKey
                )
            )
        fameExceptionalLoopAutoRecoveryLaneCooldownMinutes =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                defaults.integer(
                    forKey: AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutesKey
                )
            )
        fameLaunchRecoveryHotKeyAutoCoachEnabled = defaults.object(
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabledKey
        ) as? Bool ?? AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled
        fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(
                defaults.integer(
                    forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutesKey
                )
            )
        fameLaunchRecoveryHotKeyAutoRescueEnabled = defaults.object(
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabledKey
        ) as? Bool ?? AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled
        fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(
                defaults.integer(
                    forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutesKey
                )
            )
        fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled = defaults.object(
            forKey: AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabledKey
        ) as? Bool ?? AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
        fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes =
            AppDefaults.normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                defaults.integer(
                    forKey: AppDefaults
                        .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutesKey
                )
            )
        fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens =
            AppDefaults
            .normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                defaults.integer(
                    forKey: AppDefaults
                        .fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpensKey
                )
            )
        fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled =
            defaults.object(
                forKey: AppDefaults
                    .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabledKey
            ) as? Bool
            ?? AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled = defaults.object(
            forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabledKey
        ) as? Bool ?? AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled
        fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes(
                defaults.integer(
                    forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutesKey
                )
            )
        fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap(
                defaults.integer(
                    forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapKey
                )
            )
        fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens(
                defaults.integer(
                    forKey: AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpensKey
                )
            )
        fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled = defaults.object(
            forKey: AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabledKey
        ) as? Bool ?? AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled
        soundEffectsEnabled = defaults.bool(forKey: "soundEffectsEnabled")
        effectVolume = defaults.double(forKey: "effectVolume")
        soundStyle = defaults.string(forKey: "soundStyle") ?? "glass"
        feelIntensity = defaults.double(forKey: "feelIntensity")
        hapticFeedbackEnabled = defaults.bool(forKey: "hapticFeedbackEnabled")
        topPickMilestoneFeedbackEnabled = defaults.bool(forKey: "topPickMilestoneFeedbackEnabled")
        fameCadenceExecutionKitBadgeEnabled = defaults.object(
            forKey: AppDefaults.fameCadenceExecutionKitBadgeEnabledKey
        ) as? Bool ?? AppDefaults.fameCadenceExecutionKitBadgeEnabled
        fameCadenceExecutionKitMomentumCardEnabled = defaults.object(
            forKey: AppDefaults.fameCadenceExecutionKitMomentumCardEnabledKey
        ) as? Bool ?? AppDefaults.fameCadenceExecutionKitMomentumCardEnabled
        fameCadenceAutopilotCueCooldownSeconds = AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(
            defaults.integer(forKey: "fameCadenceAutopilotCueCooldownSeconds")
        )
        fameCadenceAutopilotCelebrationIntensity =
            AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
                defaults.integer(forKey: "fameCadenceAutopilotCelebrationIntensity")
            )
        fameOnboardingNudgeEnabled = defaults.object(
            forKey: AppDefaults.fameOnboardingNudgeEnabledKey
        ) as? Bool ?? AppDefaults.fameOnboardingNudgeEnabled
        fameOnboardingNudgeWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            defaults.integer(forKey: AppDefaults.fameOnboardingNudgeWindowDaysKey)
        )
        ocrLanguageCode = defaults.string(forKey: "ocrLanguageCode") ?? "en-US"
        llmEnabled = defaults.bool(forKey: "llmEnabled")
        llmModel = defaults.string(forKey: "llmModel") ?? AppDefaults.llmModel
        llmProvider = defaults.string(forKey: "llmProvider") ?? AppDefaults.llmProvider
        llmEndpoint = defaults.string(forKey: "llmEndpoint") ?? AppDefaults.openAICompatibleChatEndpoint
        openAIAPIKey = KeychainStore.get(service: "FluidReader", account: "openai-api-key") ?? ""
        useCloudVoiceForLLM = defaults.bool(forKey: "useCloudVoiceForLLM")
        cloudVoiceModel = defaults.string(forKey: "cloudVoiceModel") ?? AppDefaults.cloudVoiceModel
        cloudVoiceName = defaults.string(forKey: "cloudVoiceName") ?? AppDefaults.cloudVoiceName
        cloudVoiceInstructions = defaults.string(forKey: "cloudVoiceInstructions")
            ?? AppDefaults.cloudVoiceInstructions
        customPromptTitle = defaults.string(forKey: "customPromptTitle") ?? AppDefaults.customPromptTitle
        customPromptText = defaults.string(forKey: "customPromptText") ?? AppDefaults.customPromptText
        customPromptTitle2 = defaults.string(forKey: "customPromptTitle2") ?? ""
        customPromptText2 = defaults.string(forKey: "customPromptText2") ?? ""
        customPromptTitle3 = defaults.string(forKey: "customPromptTitle3") ?? ""
        customPromptText3 = defaults.string(forKey: "customPromptText3") ?? ""
        isLoading = false
    }

    private func save<T>(_ key: String, _ value: T) {
        guard !isLoading else { return }
        defaults.set(value, forKey: key)
    }

    private static func defaultVoiceIdentifier() -> String {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferredNames = ["Ava", "Nicky", "Samantha", "Zoe", "Allison", "Karen", "Moira", "Daniel"]

        let englishVoices = voices.filter { $0.language.hasPrefix("en") }
        let scoredVoice = englishVoices.max { left, right in
            scoreVoice(left, preferredNames: preferredNames) < scoreVoice(right, preferredNames: preferredNames)
        }

        if let scoredVoice {
            return scoredVoice.identifier
        }

        if let englishVoice = englishVoices.first {
            return englishVoice.identifier
        }

        return voices.first?.identifier ?? ""
    }

    private static func scoreVoice(
        _ voice: AVSpeechSynthesisVoice,
        preferredNames: [String]
    ) -> Int {
        let loweredName = voice.name.lowercased()
        let preferredRank = preferredNames.firstIndex {
            loweredName.contains($0.lowercased())
        }
        let preferredScore = preferredRank.map { 80 - $0 } ?? 0
        let languageScore = voice.language == "en-US" ? 16 : 8
        let qualityScore = voice.quality.rawValue * 100

        return qualityScore + preferredScore + languageScore
    }
}
