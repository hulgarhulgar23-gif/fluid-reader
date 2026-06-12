import XCTest
@testable import FluidReader

final class SettingsBackupTests: XCTestCase {
    func testRoundTripKeepsSettings() throws {
        let backup = makeBackup()
        let json = try backup.jsonString()

        XCTAssertEqual(try SettingsBackup.decode(json), backup)
    }

    func testOldBackupDefaultsNewAutomationOff() throws {
        let json = try makeBackup().jsonString()
        let data = try XCTUnwrap(json.data(using: .utf8))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "autoCopyNewText")
        object.removeValue(forKey: "autoPastePickedText")
        object.removeValue(forKey: "autoPasteLLMAnswers")
        object.removeValue(forKey: "saveClipboardHistory")
        object.removeValue(forKey: "fameAutoPulseAfterSnapshot")
        object.removeValue(forKey: "fameAutoPulseQuietMode")
        object.removeValue(forKey: "fameMorningBriefOnLaunch")
        object.removeValue(forKey: "fameMorningBriefQuietMode")
        object.removeValue(forKey: "fameLaunchThresholdAlertsEnabled")
        object.removeValue(forKey: "fameLaunchHealthPulseEnabled")
        object.removeValue(forKey: "fameLaunchHealthPulseCooldownSeconds")
        object.removeValue(forKey: "fameLaunchHealthPressureAutoRescueEnabled")
        object.removeValue(forKey: "fameLaunchHealthPressureAutoRescueCooldownHours")
        object.removeValue(forKey: "fameAutoOpsBundleCooldownMinutes")
        object.removeValue(forKey: "fameLaunchRescueBurstAutoCooldownMinutes")
        object.removeValue(forKey: "fameExceptionalLoopAutoRecoveryLaneMissesRequired")
        object.removeValue(forKey: "fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired")
        object.removeValue(forKey: "fameExceptionalLoopAutoRecoveryLaneCooldownMinutes")
        object.removeValue(forKey: "fameLaunchRecoveryHotKeyAutoCoachEnabled")
        object.removeValue(forKey: "fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes")
        object.removeValue(forKey: "fameLaunchRecoveryHotKeyAutoRescueEnabled")
        object.removeValue(forKey: "fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes")
        object.removeValue(forKey: "fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled")
        object.removeValue(forKey: "fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes")
        object.removeValue(forKey: "fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens")
        object.removeValue(forKey: "fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled")
        object.removeValue(forKey: "topPickMilestoneFeedbackEnabled")
        object.removeValue(forKey: "fameCadenceExecutionKitBadgeEnabled")
        object.removeValue(forKey: "fameCadenceExecutionKitMomentumCardEnabled")
        object.removeValue(forKey: "fameCadenceAutopilotCueCooldownSeconds")
        object.removeValue(forKey: "fameCadenceAutopilotCelebrationIntensity")
        object.removeValue(forKey: "fameOnboardingNudgeEnabled")
        object.removeValue(forKey: "fameOnboardingNudgeWindowDays")
        let oldData = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let oldJSON = try XCTUnwrap(String(data: oldData, encoding: .utf8))

        let backup = try SettingsBackup.decode(oldJSON)
        XCTAssertFalse(backup.autoCopyNewText)
        XCTAssertFalse(backup.autoPastePickedText)
        XCTAssertFalse(backup.autoPasteLLMAnswers)
        XCTAssertFalse(backup.saveClipboardHistory)
        XCTAssertTrue(backup.fameAutoPulseAfterSnapshot)
        XCTAssertFalse(backup.fameAutoPulseQuietMode)
        XCTAssertFalse(backup.fameMorningBriefOnLaunch)
        XCTAssertTrue(backup.fameMorningBriefQuietMode)
        XCTAssertTrue(backup.fameLaunchThresholdAlertsEnabled)
        XCTAssertTrue(backup.fameLaunchHealthPulseEnabled)
        XCTAssertEqual(
            backup.fameLaunchHealthPulseCooldownSeconds,
            AppDefaults.fameLaunchHealthPulseCooldownSeconds
        )
        XCTAssertEqual(
            backup.fameLaunchHealthPressureAutoRescueEnabled,
            AppDefaults.fameLaunchHealthPressureAutoRescueEnabled
        )
        XCTAssertEqual(
            backup.fameLaunchHealthPressureAutoRescueCooldownHours,
            AppDefaults.fameLaunchHealthPressureAutoRescueCooldownHours
        )
        XCTAssertEqual(backup.fameAutoOpsBundleCooldownMinutes, AppDefaults.fameAutoOpsBundleCooldownMinutes)
        XCTAssertEqual(
            backup.fameLaunchRescueBurstAutoCooldownMinutes,
            AppDefaults.fameLaunchRescueBurstAutoCooldownMinutes
        )
        XCTAssertEqual(
            backup.fameExceptionalLoopAutoRecoveryLaneMissesRequired,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
        XCTAssertEqual(
            backup.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
        )
        XCTAssertEqual(
            backup.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes,
            AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        XCTAssertEqual(
            backup.fameLaunchRecoveryHotKeyAutoCoachEnabled,
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachEnabled
        )
        XCTAssertEqual(
            backup.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes,
            AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
        )
        XCTAssertEqual(
            backup.fameLaunchRecoveryHotKeyAutoRescueEnabled,
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueEnabled
        )
        XCTAssertEqual(
            backup.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes,
            AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
        )
        XCTAssertEqual(
            backup.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
        )
        XCTAssertEqual(
            backup.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
        )
        XCTAssertEqual(
            backup.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
        )
        XCTAssertEqual(
            backup.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled,
            AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
        )
        XCTAssertTrue(backup.topPickMilestoneFeedbackEnabled)
        XCTAssertTrue(backup.fameCadenceExecutionKitBadgeEnabled)
        XCTAssertTrue(backup.fameCadenceExecutionKitMomentumCardEnabled)
        XCTAssertEqual(
            backup.fameCadenceAutopilotCueCooldownSeconds,
            AppDefaults.fameCadenceAutopilotCueCooldownSeconds
        )
        XCTAssertEqual(
            backup.fameCadenceAutopilotCelebrationIntensity,
            AppDefaults.fameCadenceAutopilotCelebrationIntensity
        )
        XCTAssertEqual(
            backup.fameOnboardingNudgeEnabled,
            AppDefaults.fameOnboardingNudgeEnabled
        )
        XCTAssertEqual(
            backup.fameOnboardingNudgeWindowDays,
            AppDefaults.fameOnboardingNudgeWindowDays
        )
    }

    func testBackupJSONDoesNotIncludeAPIKey() throws {
        let json = try makeBackup().jsonString()

        XCTAssertFalse(json.contains("apiKey"))
        XCTAssertFalse(json.contains("openAIAPIKey"))
        XCTAssertFalse(json.contains("sk-test"))
    }

    func testInvalidBackupThrows() {
        XCTAssertThrowsError(try SettingsBackup.decode("not json"))
    }

    func testBackupFromNewerVersionThrows() throws {
        let json = try makeBackup().jsonString()
        let futureJSON = json.replacingOccurrences(
            of: "\"version\" : \(SettingsBackup.currentVersion)",
            with: "\"version\" : \(SettingsBackup.currentVersion + 1)"
        )
        XCTAssertNotEqual(json, futureJSON)

        XCTAssertThrowsError(try SettingsBackup.decode(futureJSON))
    }

    private func makeBackup() -> SettingsBackup {
        SettingsBackup(
            version: SettingsBackup.currentVersion,
            voiceIdentifier: "com.apple.voice",
            speechRate: 0.5,
            speechPitch: 1.0,
            speechVolume: 0.9,
            readAfterPick: true,
            autoCopyNewText: true,
            autoPastePickedText: true,
            autoPasteLLMAnswers: true,
            saveRecentItems: true,
            saveClipboardHistory: true,
            readerAlwaysOnTop: false,
            fameAutoPulseAfterSnapshot: true,
            fameAutoPulseQuietMode: false,
            fameMorningBriefOnLaunch: true,
            fameMorningBriefQuietMode: false,
            fameLaunchThresholdAlertsEnabled: true,
            fameLaunchHealthPulseEnabled: true,
            fameLaunchHealthPulseCooldownSeconds: 30,
            fameLaunchHealthPressureAutoRescueEnabled: true,
            fameLaunchHealthPressureAutoRescueCooldownHours: 24,
            fameAutoOpsBundleCooldownMinutes: 10,
            fameLaunchRescueBurstAutoCooldownMinutes: 5,
            fameExceptionalLoopAutoRecoveryLaneMissesRequired: 4,
            fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired: 3,
            fameExceptionalLoopAutoRecoveryLaneCooldownMinutes: 30,
            fameLaunchRecoveryHotKeyAutoCoachEnabled: true,
            fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes: 15,
            fameLaunchRecoveryHotKeyAutoRescueEnabled: true,
            fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes: 15,
            fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled: true,
            fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes: 15,
            fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens: 5,
            fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled: true,
            soundEffectsEnabled: true,
            effectVolume: 0.6,
            soundStyle: "glass",
            feelIntensity: 0.8,
            hapticFeedbackEnabled: true,
            topPickMilestoneFeedbackEnabled: true,
            fameCadenceExecutionKitBadgeEnabled: true,
            fameCadenceExecutionKitMomentumCardEnabled: true,
            fameCadenceAutopilotCueCooldownSeconds: 60,
            fameCadenceAutopilotCelebrationIntensity: 2,
            fameOnboardingNudgeEnabled: true,
            fameOnboardingNudgeWindowDays: 10,
            ocrLanguageCode: "en-US",
            llmEnabled: true,
            llmProvider: "openAICompatibleChat",
            llmModel: "gpt-test",
            llmEndpoint: "https://api.example.test/v1/chat/completions",
            useCloudVoiceForLLM: false,
            cloudVoiceModel: "gpt-voice",
            cloudVoiceName: "coral",
            cloudVoiceInstructions: "Speak clearly.",
            customPromptTitle: "Key Points",
            customPromptText: "Find key points.",
            customPromptTitle2: "Risks",
            customPromptText2: "Find risks.",
            customPromptTitle3: "Next",
            customPromptText3: "Find next steps."
        )
    }
}
