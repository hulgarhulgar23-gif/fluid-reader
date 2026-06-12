import Foundation

struct SettingsBackup: Codable, Equatable {
    static let currentVersion = 1

    let version: Int
    let voiceIdentifier: String
    let speechRate: Double
    let speechPitch: Double
    let speechVolume: Double
    let readAfterPick: Bool
    let autoCopyNewText: Bool
    let autoPastePickedText: Bool
    let autoPasteLLMAnswers: Bool
    let saveRecentItems: Bool
    let saveClipboardHistory: Bool
    let readerAlwaysOnTop: Bool
    let fameAutoPulseAfterSnapshot: Bool
    let fameAutoPulseQuietMode: Bool
    let fameMorningBriefOnLaunch: Bool
    let fameMorningBriefQuietMode: Bool
    let fameLaunchThresholdAlertsEnabled: Bool
    let fameLaunchHealthPulseEnabled: Bool
    let fameLaunchHealthPulseCooldownSeconds: Int
    let fameLaunchHealthPressureAutoRescueEnabled: Bool
    let fameLaunchHealthPressureAutoRescueCooldownHours: Int
    let fameAutoOpsBundleCooldownMinutes: Int
    let fameLaunchRescueBurstAutoCooldownMinutes: Int
    let fameExceptionalLoopAutoRecoveryLaneMissesRequired: Int
    let fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired: Int
    let fameExceptionalLoopAutoRecoveryLaneCooldownMinutes: Int
    let fameLaunchRecoveryHotKeyAutoCoachEnabled: Bool
    let fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes: Int
    let fameLaunchRecoveryHotKeyAutoRescueEnabled: Bool
    let fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes: Int
    let fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled: Bool
    let fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes: Int
    let fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens: Int
    let fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled: Bool
    let soundEffectsEnabled: Bool
    let effectVolume: Double
    let soundStyle: String
    let feelIntensity: Double
    let hapticFeedbackEnabled: Bool
    let topPickMilestoneFeedbackEnabled: Bool
    let fameCadenceExecutionKitBadgeEnabled: Bool
    let fameCadenceExecutionKitMomentumCardEnabled: Bool
    let fameCadenceAutopilotCueCooldownSeconds: Int
    let fameCadenceAutopilotCelebrationIntensity: Int
    let fameOnboardingNudgeEnabled: Bool
    let fameOnboardingNudgeWindowDays: Int
    let ocrLanguageCode: String
    let llmEnabled: Bool
    let llmProvider: String
    let llmModel: String
    let llmEndpoint: String
    let useCloudVoiceForLLM: Bool
    let cloudVoiceModel: String
    let cloudVoiceName: String
    let cloudVoiceInstructions: String
    let customPromptTitle: String
    let customPromptText: String
    let customPromptTitle2: String
    let customPromptText2: String
    let customPromptTitle3: String
    let customPromptText3: String

    @MainActor
    static func make(settings: SettingsStore) -> SettingsBackup {
        SettingsBackup(
            version: currentVersion,
            voiceIdentifier: settings.voiceIdentifier,
            speechRate: settings.speechRate,
            speechPitch: settings.speechPitch,
            speechVolume: settings.speechVolume,
            readAfterPick: settings.readAfterPick,
            autoCopyNewText: settings.autoCopyNewText,
            autoPastePickedText: settings.autoPastePickedText,
            autoPasteLLMAnswers: settings.autoPasteLLMAnswers,
            saveRecentItems: settings.saveRecentItems,
            saveClipboardHistory: settings.saveClipboardHistory,
            readerAlwaysOnTop: settings.readerAlwaysOnTop,
            fameAutoPulseAfterSnapshot: settings.fameAutoPulseAfterSnapshot,
            fameAutoPulseQuietMode: settings.fameAutoPulseQuietMode,
            fameMorningBriefOnLaunch: settings.fameMorningBriefOnLaunch,
            fameMorningBriefQuietMode: settings.fameMorningBriefQuietMode,
            fameLaunchThresholdAlertsEnabled: settings.fameLaunchThresholdAlertsEnabled,
            fameLaunchHealthPulseEnabled: settings.fameLaunchHealthPulseEnabled,
            fameLaunchHealthPulseCooldownSeconds: settings.fameLaunchHealthPulseCooldownSeconds,
            fameLaunchHealthPressureAutoRescueEnabled: settings.fameLaunchHealthPressureAutoRescueEnabled,
            fameLaunchHealthPressureAutoRescueCooldownHours: settings.fameLaunchHealthPressureAutoRescueCooldownHours,
            fameAutoOpsBundleCooldownMinutes: settings.fameAutoOpsBundleCooldownMinutes,
            fameLaunchRescueBurstAutoCooldownMinutes: settings.fameLaunchRescueBurstAutoCooldownMinutes,
            fameExceptionalLoopAutoRecoveryLaneMissesRequired:
                settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired:
                settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            fameExceptionalLoopAutoRecoveryLaneCooldownMinutes:
                settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes,
            fameLaunchRecoveryHotKeyAutoCoachEnabled: settings.fameLaunchRecoveryHotKeyAutoCoachEnabled,
            fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes:
                settings.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes,
            fameLaunchRecoveryHotKeyAutoRescueEnabled: settings.fameLaunchRecoveryHotKeyAutoRescueEnabled,
            fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes:
                settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes,
            fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled:
                settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
            fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes:
                settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes,
            fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens:
                settings.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens,
            fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled:
                settings
                .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled,
            soundEffectsEnabled: settings.soundEffectsEnabled,
            effectVolume: settings.effectVolume,
            soundStyle: settings.soundStyle,
            feelIntensity: settings.feelIntensity,
            hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
            topPickMilestoneFeedbackEnabled: settings.topPickMilestoneFeedbackEnabled,
            fameCadenceExecutionKitBadgeEnabled: settings.fameCadenceExecutionKitBadgeEnabled,
            fameCadenceExecutionKitMomentumCardEnabled: settings.fameCadenceExecutionKitMomentumCardEnabled,
            fameCadenceAutopilotCueCooldownSeconds: settings.fameCadenceAutopilotCueCooldownSeconds,
            fameCadenceAutopilotCelebrationIntensity: settings.fameCadenceAutopilotCelebrationIntensity,
            fameOnboardingNudgeEnabled: settings.fameOnboardingNudgeEnabled,
            fameOnboardingNudgeWindowDays: settings.fameOnboardingNudgeWindowDays,
            ocrLanguageCode: settings.ocrLanguageCode,
            llmEnabled: settings.llmEnabled,
            llmProvider: settings.llmProvider,
            llmModel: settings.llmModel,
            llmEndpoint: settings.llmEndpoint,
            useCloudVoiceForLLM: settings.useCloudVoiceForLLM,
            cloudVoiceModel: settings.cloudVoiceModel,
            cloudVoiceName: settings.cloudVoiceName,
            cloudVoiceInstructions: settings.cloudVoiceInstructions,
            customPromptTitle: settings.customPromptTitle,
            customPromptText: settings.customPromptText,
            customPromptTitle2: settings.customPromptTitle2,
            customPromptText2: settings.customPromptText2,
            customPromptTitle3: settings.customPromptTitle3,
            customPromptText3: settings.customPromptText3
        )
    }

    static func decode(_ text: String) throws -> SettingsBackup {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleanText.data(using: .utf8) else {
            throw CocoaError(.coderReadCorrupt)
        }
        return try JSONDecoder().decode(SettingsBackup.self, from: data)
    }

    func jsonString() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return text
    }

    @MainActor
    func apply(to settings: SettingsStore) {
        settings.voiceIdentifier = clean(voiceIdentifier, fallback: settings.voiceIdentifier)
        settings.speechRate = clamp(speechRate, to: 0.30...0.65)
        settings.speechPitch = clamp(speechPitch, to: 0.80...1.25)
        settings.speechVolume = clamp(speechVolume, to: 0.20...1.0)
        settings.readAfterPick = readAfterPick
        settings.autoCopyNewText = autoCopyNewText
        settings.autoPastePickedText = autoPastePickedText
        settings.autoPasteLLMAnswers = autoPasteLLMAnswers
        settings.saveRecentItems = saveRecentItems
        settings.saveClipboardHistory = saveClipboardHistory
        settings.readerAlwaysOnTop = readerAlwaysOnTop
        settings.fameAutoPulseAfterSnapshot = fameAutoPulseAfterSnapshot
        settings.fameAutoPulseQuietMode = fameAutoPulseQuietMode
        settings.fameMorningBriefOnLaunch = fameMorningBriefOnLaunch
        settings.fameMorningBriefQuietMode = fameMorningBriefQuietMode
        settings.fameLaunchThresholdAlertsEnabled = fameLaunchThresholdAlertsEnabled
        settings.fameLaunchHealthPulseEnabled = fameLaunchHealthPulseEnabled
        settings.fameLaunchHealthPulseCooldownSeconds =
            AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(
                fameLaunchHealthPulseCooldownSeconds
            )
        settings.fameLaunchHealthPressureAutoRescueEnabled = fameLaunchHealthPressureAutoRescueEnabled
        settings.fameLaunchHealthPressureAutoRescueCooldownHours =
            AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(
                fameLaunchHealthPressureAutoRescueCooldownHours
            )
        settings.fameAutoOpsBundleCooldownMinutes = AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(
            fameAutoOpsBundleCooldownMinutes
        )
        settings.fameLaunchRescueBurstAutoCooldownMinutes =
            AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(
                fameLaunchRescueBurstAutoCooldownMinutes
            )
        settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                fameExceptionalLoopAutoRecoveryLaneMissesRequired
            )
        settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
            )
        settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            )
        settings.fameLaunchRecoveryHotKeyAutoCoachEnabled = fameLaunchRecoveryHotKeyAutoCoachEnabled
        settings.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(
                fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
            )
        settings.fameLaunchRecoveryHotKeyAutoRescueEnabled = fameLaunchRecoveryHotKeyAutoRescueEnabled
        settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(
                fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
            )
        settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled =
            fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
        settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes =
            AppDefaults.normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
            )
        settings.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens =
            AppDefaults.normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
            )
        settings.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled =
            fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        settings.soundEffectsEnabled = soundEffectsEnabled
        settings.effectVolume = clamp(effectVolume, to: 0.0...1.0)
        settings.soundStyle = clean(soundStyle, fallback: "glass")
        settings.feelIntensity = clamp(feelIntensity, to: 0.20...1.0)
        settings.hapticFeedbackEnabled = hapticFeedbackEnabled
        settings.topPickMilestoneFeedbackEnabled = topPickMilestoneFeedbackEnabled
        settings.fameCadenceExecutionKitBadgeEnabled = fameCadenceExecutionKitBadgeEnabled
        settings.fameCadenceExecutionKitMomentumCardEnabled = fameCadenceExecutionKitMomentumCardEnabled
        settings.fameCadenceAutopilotCueCooldownSeconds =
            AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(
                fameCadenceAutopilotCueCooldownSeconds
            )
        settings.fameCadenceAutopilotCelebrationIntensity =
            AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
                fameCadenceAutopilotCelebrationIntensity
            )
        settings.fameOnboardingNudgeEnabled = fameOnboardingNudgeEnabled
        settings.fameOnboardingNudgeWindowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            fameOnboardingNudgeWindowDays
        )
        settings.ocrLanguageCode = OCRLanguagePreset.normalized(ocrLanguageCode)
        settings.llmEnabled = llmEnabled
        settings.llmProvider = LLMProvider.normalized(llmProvider).rawValue
        settings.llmModel = clean(llmModel, fallback: AppDefaults.llmModel)
        settings.llmEndpoint = clean(llmEndpoint, fallback: AppDefaults.openAICompatibleChatEndpoint)
        settings.useCloudVoiceForLLM = useCloudVoiceForLLM
        settings.cloudVoiceModel = clean(cloudVoiceModel, fallback: AppDefaults.cloudVoiceModel)
        settings.cloudVoiceName = clean(cloudVoiceName, fallback: AppDefaults.cloudVoiceName)
        settings.cloudVoiceInstructions = clean(
            cloudVoiceInstructions,
            fallback: AppDefaults.cloudVoiceInstructions
        )
        settings.customPromptTitle = customPromptTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.customPromptText = customPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.customPromptTitle2 = customPromptTitle2.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.customPromptText2 = customPromptText2.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.customPromptTitle3 = customPromptTitle3.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.customPromptText3 = customPromptText3.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clean(_ value: String, fallback: String) -> String {
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanValue.isEmpty ? fallback : cleanValue
    }

    private func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

extension SettingsBackup {
    private enum CodingKeys: String, CodingKey {
        case version
        case voiceIdentifier
        case speechRate
        case speechPitch
        case speechVolume
        case readAfterPick
        case autoCopyNewText
        case autoPastePickedText
        case autoPasteLLMAnswers
        case saveRecentItems
        case saveClipboardHistory
        case readerAlwaysOnTop
        case fameAutoPulseAfterSnapshot
        case fameAutoPulseQuietMode
        case fameMorningBriefOnLaunch
        case fameMorningBriefQuietMode
        case fameLaunchThresholdAlertsEnabled
        case fameLaunchHealthPulseEnabled
        case fameLaunchHealthPulseCooldownSeconds
        case fameLaunchHealthPressureAutoRescueEnabled
        case fameLaunchHealthPressureAutoRescueCooldownHours
        case fameAutoOpsBundleCooldownMinutes
        case fameLaunchRescueBurstAutoCooldownMinutes
        case fameExceptionalLoopAutoRecoveryLaneMissesRequired
        case fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        case fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        case fameLaunchRecoveryHotKeyAutoCoachEnabled
        case fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
        case fameLaunchRecoveryHotKeyAutoRescueEnabled
        case fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
        case fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
        case fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
        case fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
        case fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        case soundEffectsEnabled
        case effectVolume
        case soundStyle
        case feelIntensity
        case hapticFeedbackEnabled
        case topPickMilestoneFeedbackEnabled
        case fameCadenceExecutionKitBadgeEnabled
        case fameCadenceExecutionKitMomentumCardEnabled
        case fameCadenceAutopilotCueCooldownSeconds
        case fameCadenceAutopilotCelebrationIntensity
        case fameOnboardingNudgeEnabled
        case fameOnboardingNudgeWindowDays
        case ocrLanguageCode
        case llmEnabled
        case llmProvider
        case llmModel
        case llmEndpoint
        case useCloudVoiceForLLM
        case cloudVoiceModel
        case cloudVoiceName
        case cloudVoiceInstructions
        case customPromptTitle
        case customPromptText
        case customPromptTitle2
        case customPromptText2
        case customPromptTitle3
        case customPromptText3
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(Int.self, forKey: .version)
        voiceIdentifier = try container.decode(String.self, forKey: .voiceIdentifier)
        speechRate = try container.decode(Double.self, forKey: .speechRate)
        speechPitch = try container.decode(Double.self, forKey: .speechPitch)
        speechVolume = try container.decode(Double.self, forKey: .speechVolume)
        readAfterPick = try container.decode(Bool.self, forKey: .readAfterPick)
        autoCopyNewText = try container.decodeIfPresent(Bool.self, forKey: .autoCopyNewText)
            ?? AppDefaults.autoCopyNewText
        autoPastePickedText = try container.decodeIfPresent(Bool.self, forKey: .autoPastePickedText)
            ?? AppDefaults.autoPastePickedText
        autoPasteLLMAnswers = try container.decodeIfPresent(Bool.self, forKey: .autoPasteLLMAnswers)
            ?? AppDefaults.autoPasteLLMAnswers
        saveRecentItems = try container.decode(Bool.self, forKey: .saveRecentItems)
        saveClipboardHistory = try container.decodeIfPresent(Bool.self, forKey: .saveClipboardHistory)
            ?? AppDefaults.saveClipboardHistory
        readerAlwaysOnTop = try container.decode(Bool.self, forKey: .readerAlwaysOnTop)
        fameAutoPulseAfterSnapshot = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameAutoPulseAfterSnapshot
        ) ?? AppDefaults.fameAutoPulseAfterSnapshot
        fameAutoPulseQuietMode = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameAutoPulseQuietMode
        ) ?? AppDefaults.fameAutoPulseQuietMode
        fameMorningBriefOnLaunch = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameMorningBriefOnLaunch
        ) ?? AppDefaults.fameMorningBriefOnLaunch
        fameMorningBriefQuietMode = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameMorningBriefQuietMode
        ) ?? AppDefaults.fameMorningBriefQuietMode
        fameLaunchThresholdAlertsEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameLaunchThresholdAlertsEnabled
        ) ?? AppDefaults.fameLaunchThresholdAlertsEnabled
        fameLaunchHealthPulseEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameLaunchHealthPulseEnabled
        ) ?? AppDefaults.fameLaunchHealthPulseEnabled
        fameLaunchHealthPulseCooldownSeconds =
            AppDefaults.normalizedFameLaunchHealthPulseCooldownSeconds(
                try container.decodeIfPresent(Int.self, forKey: .fameLaunchHealthPulseCooldownSeconds)
                    ?? AppDefaults.fameLaunchHealthPulseCooldownSeconds
            )
        fameLaunchHealthPressureAutoRescueEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameLaunchHealthPressureAutoRescueEnabled
        ) ?? AppDefaults.fameLaunchHealthPressureAutoRescueEnabled
        fameLaunchHealthPressureAutoRescueCooldownHours =
            AppDefaults.normalizedFameLaunchHealthPressureAutoRescueCooldownHours(
                try container.decodeIfPresent(Int.self, forKey: .fameLaunchHealthPressureAutoRescueCooldownHours)
                    ?? AppDefaults.fameLaunchHealthPressureAutoRescueCooldownHours
            )
        fameAutoOpsBundleCooldownMinutes = AppDefaults.normalizedFameAutoOpsBundleCooldownMinutes(
            try container.decodeIfPresent(Int.self, forKey: .fameAutoOpsBundleCooldownMinutes)
                ?? AppDefaults.fameAutoOpsBundleCooldownMinutes
        )
        fameLaunchRescueBurstAutoCooldownMinutes =
            AppDefaults.normalizedFameLaunchRescueBurstAutoCooldownMinutes(
                try container.decodeIfPresent(Int.self, forKey: .fameLaunchRescueBurstAutoCooldownMinutes)
                    ?? AppDefaults.fameLaunchRescueBurstAutoCooldownMinutes
            )
        fameExceptionalLoopAutoRecoveryLaneMissesRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameExceptionalLoopAutoRecoveryLaneMissesRequired
                ) ?? AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired
            )
        fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
                ) ?? AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
            )
        fameExceptionalLoopAutoRecoveryLaneCooldownMinutes =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
                ) ?? AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
            )
        fameLaunchRecoveryHotKeyAutoCoachEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameLaunchRecoveryHotKeyAutoCoachEnabled
        ) ?? AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled
        fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoCoachCooldownMinutes(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
                ) ?? AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
            )
        fameLaunchRecoveryHotKeyAutoRescueEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameLaunchRecoveryHotKeyAutoRescueEnabled
        ) ?? AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled
        fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes =
            AppDefaults.normalizedFameLaunchRecoveryHotKeyAutoRescueCooldownMinutes(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
                ) ?? AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
            )
        fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
        ) ?? AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
        fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes =
            AppDefaults.normalizedFameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
                ) ?? AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
            )
        fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens =
            AppDefaults.normalizedFameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens(
                try container.decodeIfPresent(
                    Int.self,
                    forKey: .fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
                ) ?? AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
            )
        fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled =
            try container.decodeIfPresent(
                Bool.self,
                forKey: .fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
            ) ?? AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        soundEffectsEnabled = try container.decode(Bool.self, forKey: .soundEffectsEnabled)
        effectVolume = try container.decode(Double.self, forKey: .effectVolume)
        soundStyle = try container.decode(String.self, forKey: .soundStyle)
        feelIntensity = try container.decode(Double.self, forKey: .feelIntensity)
        hapticFeedbackEnabled = try container.decode(Bool.self, forKey: .hapticFeedbackEnabled)
        topPickMilestoneFeedbackEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .topPickMilestoneFeedbackEnabled
        ) ?? true
        fameCadenceExecutionKitBadgeEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameCadenceExecutionKitBadgeEnabled
        ) ?? AppDefaults.fameCadenceExecutionKitBadgeEnabled
        fameCadenceExecutionKitMomentumCardEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameCadenceExecutionKitMomentumCardEnabled
        ) ?? AppDefaults.fameCadenceExecutionKitMomentumCardEnabled
        fameCadenceAutopilotCueCooldownSeconds =
            AppDefaults.normalizedFameCadenceAutopilotCueCooldownSeconds(
                try container.decodeIfPresent(Int.self, forKey: .fameCadenceAutopilotCueCooldownSeconds)
                    ?? AppDefaults.fameCadenceAutopilotCueCooldownSeconds
            )
        fameCadenceAutopilotCelebrationIntensity =
            AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
                try container.decodeIfPresent(Int.self, forKey: .fameCadenceAutopilotCelebrationIntensity)
                    ?? AppDefaults.fameCadenceAutopilotCelebrationIntensity
            )
        fameOnboardingNudgeEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .fameOnboardingNudgeEnabled
        ) ?? AppDefaults.fameOnboardingNudgeEnabled
        fameOnboardingNudgeWindowDays =
            AppDefaults.normalizedFameOnboardingNudgeWindowDays(
                try container.decodeIfPresent(Int.self, forKey: .fameOnboardingNudgeWindowDays)
                    ?? AppDefaults.fameOnboardingNudgeWindowDays
            )
        ocrLanguageCode = try container.decode(String.self, forKey: .ocrLanguageCode)
        llmEnabled = try container.decode(Bool.self, forKey: .llmEnabled)
        llmProvider = try container.decode(String.self, forKey: .llmProvider)
        llmModel = try container.decode(String.self, forKey: .llmModel)
        llmEndpoint = try container.decode(String.self, forKey: .llmEndpoint)
        useCloudVoiceForLLM = try container.decode(Bool.self, forKey: .useCloudVoiceForLLM)
        cloudVoiceModel = try container.decode(String.self, forKey: .cloudVoiceModel)
        cloudVoiceName = try container.decode(String.self, forKey: .cloudVoiceName)
        cloudVoiceInstructions = try container.decode(String.self, forKey: .cloudVoiceInstructions)
        customPromptTitle = try container.decode(String.self, forKey: .customPromptTitle)
        customPromptText = try container.decode(String.self, forKey: .customPromptText)
        customPromptTitle2 = try container.decode(String.self, forKey: .customPromptTitle2)
        customPromptText2 = try container.decode(String.self, forKey: .customPromptText2)
        customPromptTitle3 = try container.decode(String.self, forKey: .customPromptTitle3)
        customPromptText3 = try container.decode(String.self, forKey: .customPromptText3)
    }
}
