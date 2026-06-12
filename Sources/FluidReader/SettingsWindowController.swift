import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private static let preferredContentSize = NSSize(width: 560, height: 620)
    private static let minContentSize = NSSize(width: 480, height: 420)
    private static let maxContentSize = NSSize(width: 760, height: 760)

    private let window: NSWindow

    init(
        settings: SettingsStore,
        testVoice: @escaping () -> Void,
        testEffect: @escaping () -> Void,
        resetCadenceExecutionKitStreak: @escaping () -> Void,
        applyFameExceptionalLoopAutoRecoveryLaneTuning: @escaping () -> Void,
        resetFameExceptionalLoopOutcomeTuning: @escaping () -> Void,
        runFameExceptionalLoopRecoveryLaneNow: @escaping () -> Void,
        runFameExceptionalLoopHealthRecommendedAction: @escaping () -> Void,
        openLatestFameExceptionalLoopRecap: @escaping () -> Void
    ) {
        let view = SettingsView(
            settings: settings,
            testVoice: testVoice,
            testEffect: testEffect,
            resetCadenceExecutionKitStreak: resetCadenceExecutionKitStreak,
            applyFameExceptionalLoopAutoRecoveryLaneTuning:
                applyFameExceptionalLoopAutoRecoveryLaneTuning,
            resetFameExceptionalLoopOutcomeTuning:
                resetFameExceptionalLoopOutcomeTuning,
            runFameExceptionalLoopRecoveryLaneNow:
                runFameExceptionalLoopRecoveryLaneNow,
            runFameExceptionalLoopHealthRecommendedAction:
                runFameExceptionalLoopHealthRecommendedAction,
            openLatestFameExceptionalLoopRecap:
                openLatestFameExceptionalLoopRecap
        )
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        WindowBounds.apply(
            to: window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.minContentSize,
            maxContentSize: Self.maxContentSize
        )
        window.contentViewController = NSHostingController(rootView: view)
    }

    func show() {
        WindowBounds.apply(
            to: window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.minContentSize,
            maxContentSize: Self.maxContentSize
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let testVoice: () -> Void
    let testEffect: () -> Void
    let resetCadenceExecutionKitStreak: () -> Void
    let applyFameExceptionalLoopAutoRecoveryLaneTuning: () -> Void
    let resetFameExceptionalLoopOutcomeTuning: () -> Void
    let runFameExceptionalLoopRecoveryLaneNow: () -> Void
    let runFameExceptionalLoopHealthRecommendedAction: () -> Void
    let openLatestFameExceptionalLoopRecap: () -> Void
    @State private var cadenceExecutionKitStreak = 0
    @State private var cadenceExecutionKitBestStreak = 0

    var body: some View {
        Form {
            Section("App") {
                LaunchAtLoginRow()
                Toggle("Keep reader on top", isOn: $settings.readerAlwaysOnTop)
            }

            Section("Fame Ops") {
                Toggle("Auto-pulse after snapshot", isOn: $settings.fameAutoPulseAfterSnapshot)
                Toggle("Quiet auto-pulse mode", isOn: $settings.fameAutoPulseQuietMode)
                    .disabled(!settings.fameAutoPulseAfterSnapshot)
                Toggle("Morning brief at launch", isOn: $settings.fameMorningBriefOnLaunch)
                Toggle("Quiet morning brief mode", isOn: $settings.fameMorningBriefQuietMode)
                    .disabled(!settings.fameMorningBriefOnLaunch)
                Toggle("Fame onboarding nudge", isOn: $settings.fameOnboardingNudgeEnabled)

                Picker("Onboarding nudge window", selection: $settings.fameOnboardingNudgeWindowDays) {
                    ForEach(AppDefaults.fameOnboardingNudgeWindowDaysOptions, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
                .disabled(!settings.fameOnboardingNudgeEnabled)

                Toggle("Launch threshold alerts", isOn: $settings.fameLaunchThresholdAlertsEnabled)
                Toggle("Launch health transition pulse", isOn: $settings.fameLaunchHealthPulseEnabled)
                    .disabled(!settings.fameLaunchThresholdAlertsEnabled)

                Picker("Launch health pulse cooldown", selection: $settings.fameLaunchHealthPulseCooldownSeconds) {
                    Text("Off").tag(0)
                    Text("15 sec").tag(15)
                    Text("30 sec").tag(30)
                    Text("60 sec").tag(60)
                    Text("2 min").tag(120)
                    Text("5 min").tag(300)
                }
                .disabled(!settings.fameLaunchThresholdAlertsEnabled || !settings.fameLaunchHealthPulseEnabled)

                Toggle(
                    "Pressure streak auto-rescue",
                    isOn: $settings.fameLaunchHealthPressureAutoRescueEnabled
                )

                Picker(
                    "Pressure auto-rescue cooldown",
                    selection: $settings.fameLaunchHealthPressureAutoRescueCooldownHours
                ) {
                    Text("No cooldown").tag(0)
                    Text("6 hr").tag(6)
                    Text("12 hr").tag(12)
                    Text("24 hr").tag(24)
                    Text("48 hr").tag(48)
                }
                .disabled(!settings.fameLaunchHealthPressureAutoRescueEnabled)

                Picker("Escalation auto bundle", selection: $settings.fameAutoOpsBundleCooldownMinutes) {
                    Text("Off").tag(0)
                    Text("10 min").tag(10)
                    Text("30 min").tag(30)
                    Text("60 min").tag(60)
                }

                Picker("Launch rescue auto-burst", selection: $settings.fameLaunchRescueBurstAutoCooldownMinutes) {
                    Text("Off").tag(0)
                    Text("5 min").tag(5)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("60 min").tag(60)
                }

                Picker(
                    "Exceptional loop auto-recovery misses",
                    selection: $settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
                ) {
                    ForEach(AppDefaults.fameExceptionalLoopAutoRecoveryLaneMissesRequiredOptions, id: \.self) { misses in
                        Text("\(misses)+ misses").tag(misses)
                    }
                }

                Picker(
                    "Exceptional loop auto-recovery streak",
                    selection: $settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
                ) {
                    ForEach(AppDefaults.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequiredOptions, id: \.self) { streak in
                        Text("x\(streak)+ failure streak").tag(streak)
                    }
                }

                Picker(
                    "Exceptional loop auto-recovery cooldown",
                    selection: $settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
                ) {
                    ForEach(AppDefaults.fameExceptionalLoopAutoRecoveryLaneCooldownMinutesOptions, id: \.self) { minutes in
                        if minutes == 0 {
                            Text("Off").tag(minutes)
                        } else if minutes % 60 == 0 {
                            Text("\(minutes / 60) hr").tag(minutes)
                        } else {
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                }

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    let recoveryLaneStatus = fameExceptionalLoopRecoveryLaneMenuStatus(
                        now: context.date
                    )
                    let latestRecapStatus = fameExceptionalLoopLatestRecapStatus()
                    let autoTuneMenuStatus = fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
                        now: context.date
                    )
                    let resetStatus = fameExceptionalLoopOutcomeTuningResetStatus()
                    let healthSnapshot = fameExceptionalLoopHealthSnapshot(now: context.date)
                    VStack(alignment: .leading, spacing: 6) {
                        fameExceptionalLoopHealthCard(
                            snapshot: healthSnapshot,
                            runRecommendedAction: runFameExceptionalLoopHealthRecommendedAction
                        )

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Button("Run Recovery Lane Now") {
                                runFameExceptionalLoopRecoveryLaneNow()
                            }
                            .disabled(!recoveryLaneStatus.isEnabled)
                            .help(recoveryLaneStatus.toolTip)

                            Spacer(minLength: 8)

                            Text(recoveryLaneStatus.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Button("Open Latest Recap") {
                                openLatestFameExceptionalLoopRecap()
                            }
                            .disabled(!latestRecapStatus.isEnabled)
                            .help(latestRecapStatus.toolTip)

                            Spacer(minLength: 8)

                            Text(latestRecapStatus.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Button("Apply Suggested Tuning") {
                                applyFameExceptionalLoopAutoRecoveryLaneTuning()
                            }
                            .disabled(!autoTuneMenuStatus.isEnabled)
                            .help(autoTuneMenuStatus.toolTip)

                            Spacer(minLength: 8)

                            Text(autoTuneMenuStatus.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Button("Reset Tuning Baseline") {
                                resetFameExceptionalLoopOutcomeTuning()
                            }
                            .disabled(!resetStatus.isEnabled)
                            .help(resetStatus.toolTip)

                            Spacer(minLength: 8)

                            Text(resetStatus.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Toggle("Launch recovery auto-coach", isOn: $settings.fameLaunchRecoveryHotKeyAutoCoachEnabled)

                Picker(
                    "Launch recovery auto-coach cooldown",
                    selection: $settings.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
                ) {
                    ForEach(AppDefaults.fameLaunchRecoveryHotKeyAutoCoachCooldownOptions, id: \.self) { minutes in
                        if minutes == 0 {
                            Text("Off").tag(minutes)
                        } else if minutes % 60 == 0 {
                            Text("\(minutes / 60) hr").tag(minutes)
                        } else {
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                }
                .disabled(!settings.fameLaunchRecoveryHotKeyAutoCoachEnabled)

                Toggle(
                    "Launch recovery auto rescue guard",
                    isOn: $settings.fameLaunchRecoveryHotKeyAutoRescueEnabled
                )

                Picker(
                    "Auto rescue guard cooldown",
                    selection: $settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
                ) {
                    ForEach(AppDefaults.fameLaunchRecoveryHotKeyAutoRescueCooldownOptions, id: \.self) { minutes in
                        if minutes == 0 {
                            Text("Off").tag(minutes)
                        } else if minutes % 60 == 0 {
                            Text("\(minutes / 60) hr").tag(minutes)
                        } else {
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                }
                .disabled(!settings.fameLaunchRecoveryHotKeyAutoRescueEnabled)

                Toggle(
                    "Hall-of-Fame auto-defense",
                    isOn: $settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled
                )

                Picker(
                    "Hall-of-Fame auto-defense cooldown",
                    selection: $settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
                ) {
                    ForEach(
                        AppDefaults.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownOptions,
                        id: \.self
                    ) { minutes in
                        if minutes == 0 {
                            Text("Off").tag(minutes)
                        } else if minutes % 60 == 0 {
                            Text("\(minutes / 60) hr").tag(minutes)
                        } else {
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                }
                .disabled(!settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled)

                Picker(
                    "Hall-of-Fame legend risk sticky Top Picks window",
                    selection: $settings.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpens
                ) {
                    ForEach(
                        AppDefaults.fameRecommendationMomentumRescueHallOfFameLegendRiskStickyPromotionOpenOptions,
                        id: \.self
                    ) { opens in
                        if opens == 1 {
                            Text("1 open").tag(opens)
                        } else {
                            Text("\(opens) opens").tag(opens)
                        }
                    }
                }
                .disabled(!settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled)

                Toggle(
                    "Hall-of-Fame legend risk hold until recovered",
                    isOn: $settings.fameRecommendationMomentumRescueHallOfFameLegendRiskStickUntilRecoveredEnabled
                )
                .disabled(!settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled)

                Toggle("Launch recovery auto Trust Surge", isOn: $settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled)

                Picker(
                    "Auto Trust Surge cooldown",
                    selection: $settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes
                ) {
                    ForEach(AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownOptions, id: \.self) { minutes in
                        if minutes == 0 {
                            Text("Off").tag(minutes)
                        } else if minutes % 60 == 0 {
                            Text("\(minutes / 60) hr").tag(minutes)
                        } else {
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                }
                .disabled(!settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled)

                Picker(
                    "Auto Trust Surge daily cap",
                    selection: $settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap
                ) {
                    ForEach(AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCapOptions, id: \.self) { dailyCap in
                        if dailyCap == 0 {
                            Text("No cap").tag(dailyCap)
                        } else {
                            Text("\(dailyCap) / day").tag(dailyCap)
                        }
                    }
                }
                .disabled(!settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled)

                Picker(
                    "Legend risk sticky Top Picks window",
                    selection: $settings.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpens
                ) {
                    ForEach(AppDefaults.fameLaunchRecoveryHotKeyLegendRiskStickyPromotionOpenOptions, id: \.self) { opens in
                        if opens == 1 {
                            Text("1 open").tag(opens)
                        } else {
                            Text("\(opens) opens").tag(opens)
                        }
                    }
                }
                .disabled(!settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled)

                Toggle(
                    "Legend risk hold until recovered",
                    isOn: $settings.fameLaunchRecoveryHotKeyLegendRiskStickUntilRecoveredEnabled
                )
                .disabled(!settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled)

                Text("Auto-pulse saves checkpoint, nudge, scorecard, and operator dashboard after each snapshot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Morning brief runs once per day at launch when snapshots exist.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Fame onboarding nudge surfaces once per day while best cadence streak is below x10.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(fameOnboardingNudgeStatusLine())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("First-week scorecard tracks onboarding pace and saves a reusable artifact for quick reopen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(fameOnboardingScorecardStatusLine())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("First-week daily brief bundles nudge + scorecard into a single save-and-reopen handoff.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(fameOnboardingDailyBriefStatusLine())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Launch threshold alerts pulse HUD + status flash when urgency crosses Live/Hot/High/Critical bands.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Launch health transition pulse only fires on Watch -> Risk and Risk -> Ready, with configurable cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Pressure streak auto-rescue runs one launch rescue bundle when Signal Pressure persists for 2+ days, with configurable cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Escalation auto bundle saves command center + checkpoint + risk timeline + pulse nudge on High/Critical transitions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Launch rescue auto-burst saves a full launch triage bundle on High/Critical launch urgency escalations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Exceptional loop auto-recovery can auto-run the top recovery lane after repeated misses, with configurable misses/streak arming and cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Launch recovery auto-coach can auto-run the active Coach step after repeated Recovery Drift cues, with configurable cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Launch recovery auto rescue guard can auto-run one momentum rescue step when Recovery Momentum Alert appears, with configurable cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Hall-of-Fame auto-defense can auto-run the active rescue recommendation whenever a Hall-of-Fame defense/chase cue appears, with configurable cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Auto Trust Surge can auto-run the momentum action when Trust Surge is 1 open from the next milestone, with configurable cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Auto Trust Surge daily cap resets at midnight and limits how many momentum steps can auto-run in one day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Legend risk sticky window keeps the forecast-selected defense command pinned for the selected number of palette opens (including the alert open).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Legend risk hold until recovered auto-extends the sticky hold while Legend decay forecast stays active, and clears once momentum recovers.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fameAutoOpsBundleStatusLine(now: context.date))
                        Text(fameLaunchRescueBurstStatusLine(now: context.date))
                        Text(fameExceptionalLoopAutoRecoveryLaneStatusLine(now: context.date))
                        Text(fameExceptionalLoopAutoRecoveryLaneRecommendationStatusLine(now: context.date))
                        Text(fameLaunchHealthPulseStatusLine())
                        Text(fameLaunchHealthPressureAutoRescueStatusLine(now: context.date))
                        Text(fameLaunchRecoveryHotKeyAutoCoachStatusLine(now: context.date))
                        Text(fameLaunchRecoveryHotKeyAutoRescueStatusLine(now: context.date))
                        Text(fameRecommendationMomentumRescueHallOfFameAutoDefenseStatusLine(now: context.date))
                        Text(fameLaunchRecoveryHotKeyAutoTrustSurgeStatusLine(now: context.date))

                        launchRecoveryHotKeyAutoTrustSurgeLeagueHistoryPanel(now: context.date)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Section("Reading") {
                Picker("Voice", selection: $settings.voiceIdentifier) {
                    ForEach(settings.availableVoices, id: \.identifier) { voice in
                        Text("\(voice.name) (\(voice.language))")
                            .tag(voice.identifier)
                    }
                }

                HStack {
                    Text("Speed")
                    Slider(value: $settings.speechRate, in: 0.30...0.65)
                    Text(String(format: "%.2f", settings.speechRate))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }

                HStack {
                    Text("Pitch")
                    Slider(value: $settings.speechPitch, in: 0.80...1.25)
                    Text(String(format: "%.2f", settings.speechPitch))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }

                HStack {
                    Text("Volume")
                    Slider(value: $settings.speechVolume, in: 0.20...1.0)
                    Text(String(format: "%.2f", settings.speechVolume))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }

                Toggle("Read after pick", isOn: $settings.readAfterPick)

                Toggle("Auto-copy new text", isOn: $settings.autoCopyNewText)

                Toggle("Auto-paste picked text", isOn: $settings.autoPastePickedText)

                Toggle("Save recent items", isOn: $settings.saveRecentItems)

                Toggle("Save clipboard history", isOn: $settings.saveClipboardHistory)

                Picker("OCR language", selection: $settings.ocrLanguageCode) {
                    ForEach(OCRLanguagePreset.presets) { preset in
                        Text(preset.title).tag(preset.languageCode)
                    }
                }

                HStack {
                    Text("Custom OCR code")
                    TextField("en-US", text: $settings.ocrLanguageCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }

                Button("Test Voice") {
                    testVoice()
                }
            }

            Section("Feel") {
                Toggle("Sound effects", isOn: $settings.soundEffectsEnabled)

                HStack {
                    Text("Sound")
                    Slider(value: $settings.effectVolume, in: 0.0...1.0)
                    Text(String(format: "%.2f", settings.effectVolume))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }
                .disabled(!settings.soundEffectsEnabled)

                Picker("Style", selection: $settings.soundStyle) {
                    Text("Soft").tag("soft")
                    Text("Glass").tag("glass")
                    Text("Jackpot").tag("jackpot")
                }
                .pickerStyle(.segmented)
                .disabled(!settings.soundEffectsEnabled)

                HStack {
                    Text("Hit")
                    Slider(value: $settings.feelIntensity, in: 0.20...1.0)
                    Text(String(format: "%.2f", settings.feelIntensity))
                        .foregroundStyle(.secondary)
                        .frame(width: 42, alignment: .trailing)
                }

                Toggle("Haptic taps", isOn: $settings.hapticFeedbackEnabled)

                Toggle("Top Picks milestone feedback", isOn: $settings.topPickMilestoneFeedbackEnabled)

                Toggle(
                    "Cadence streak badge in Top Picks",
                    isOn: $settings.fameCadenceExecutionKitBadgeEnabled
                )

                Toggle(
                    "Cadence momentum card in Top Picks",
                    isOn: $settings.fameCadenceExecutionKitMomentumCardEnabled
                )

                Picker(
                    "Cadence autopilot cue cooldown",
                    selection: $settings.fameCadenceAutopilotCueCooldownSeconds
                ) {
                    Text("Off").tag(0)
                    Text("15 sec").tag(15)
                    Text("30 sec").tag(30)
                    Text("45 sec").tag(45)
                    Text("60 sec").tag(60)
                    Text("2 min").tag(120)
                }

                Picker(
                    "Cadence celebration intensity",
                    selection: $settings.fameCadenceAutopilotCelebrationIntensity
                ) {
                    Text("Calm").tag(0)
                    Text("Balanced").tag(1)
                    Text("Epic").tag(2)
                }

                Text("Cadence autopilot cue repeats same reset/milestone nudge after this cooldown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(cadenceAutopilotCueStatusLine())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(cadenceCelebrationStatusLine())
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Cadence kit streak: \(cadenceExecutionKitStreak). Best: \(cadenceExecutionKitBestStreak).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Reset Cadence Streak") {
                        resetCadenceExecutionKitStreak()
                        refreshCadenceExecutionKitStreak()
                    }
                    .disabled(cadenceExecutionKitStreak == 0 && cadenceExecutionKitBestStreak == 0)
                }

                Button {
                    testEffect()
                } label: {
                    Label("Test Full Feel", systemImage: "sparkles")
                }
            }

            Section("LLM") {
                Toggle("Use LLM", isOn: $settings.llmEnabled)

                if settings.llmEnabled {
                    Picker("Provider", selection: $settings.llmProvider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.title).tag(provider.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    SecureField("API key", text: $settings.openAIAPIKey)
                        .textFieldStyle(.roundedBorder)

                    TextField("Model", text: $settings.llmModel)
                        .textFieldStyle(.roundedBorder)

                    if LLMProvider.normalized(settings.llmProvider) == .openAICompatibleChat {
                        TextField("Chat endpoint", text: $settings.llmEndpoint)
                            .textFieldStyle(.roundedBorder)
                    }

                    Toggle("Cloud voice for LLM answer", isOn: $settings.useCloudVoiceForLLM)

                    Toggle("Auto-paste LLM answers", isOn: $settings.autoPasteLLMAnswers)

                    if settings.useCloudVoiceForLLM {
                        TextField("Voice model", text: $settings.cloudVoiceModel)
                            .textFieldStyle(.roundedBorder)
                        TextField("Voice", text: $settings.cloudVoiceName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Voice style", text: $settings.cloudVoiceInstructions)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    savedPromptFields(
                        "Saved prompt 1",
                        title: $settings.customPromptTitle,
                        prompt: $settings.customPromptText
                    )
                    savedPromptFields(
                        "Saved prompt 2",
                        title: $settings.customPromptTitle2,
                        prompt: $settings.customPromptText2
                    )
                    savedPromptFields(
                        "Saved prompt 3",
                        title: $settings.customPromptTitle3,
                        prompt: $settings.customPromptText3
                    )
                }
            }
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(minWidth: 520, minHeight: 640)
        .onAppear {
            refreshCadenceExecutionKitStreak()
        }
    }

    private func savedPromptFields(
        _ label: String,
        title: Binding<String>,
        prompt: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("Name", text: title)
                .textFieldStyle(.roundedBorder)

            TextField("Prompt", text: prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
        }
    }

    private func fameAutoOpsBundleStatusLine(now: Date) -> String {
        let status = AppDelegate.autoOpsBundleEscalationStatus(
            lastRunAt: autoOpsBundleLastRunAt(),
            now: now,
            cooldownMinutes: settings.fameAutoOpsBundleCooldownMinutes
        )
        switch status {
        case .disabled:
            return "Status: escalation auto bundle is off."
        case .ready:
            return "Status: escalation auto bundle is ready on next High/Critical transition."
        case .coolingDown(let minutesRemaining):
            return "Status: escalation auto bundle cooldown active — next auto run in about \(minutesRemaining) min."
        }
    }

    private func fameLaunchRescueBurstStatusLine(now: Date) -> String {
        let status = AppDelegate.autoOpsBundleEscalationStatus(
            lastRunAt: launchRescueBurstLastRunAt(),
            now: now,
            cooldownMinutes: settings.fameLaunchRescueBurstAutoCooldownMinutes
        )
        switch status {
        case .disabled:
            return "Status: launch rescue auto-burst is off."
        case .ready:
            return "Status: launch rescue auto-burst is ready on next High/Critical launch escalation."
        case .coolingDown(let minutesRemaining):
            return "Status: launch rescue auto-burst cooldown active — next auto run in about \(minutesRemaining) min."
        }
    }

    private func fameExceptionalLoopAutoRecoveryLaneStatusLine(
        now: Date,
        defaults: UserDefaults = .standard
    ) -> String {
        let commandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let windowedCommandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let topRecoveryLane = AppDelegate.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        )
        let missesRequired = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
        let failureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
            )
        let cooldownMinutes = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        let summary = AppDelegate.fameExceptionalLoopAutoRecoveryLaneStatusSummary(
            topRecoveryLane: topRecoveryLane,
            lastAutoRunAt: fameExceptionalLoopRecoveryLaneAutoRunLastAt(defaults: defaults),
            now: now,
            missesRequired: missesRequired,
            failureStreakRequired: failureStreakRequired,
            cooldown: TimeInterval(cooldownMinutes * 60)
        )
        return "Status: \(summary)"
    }

    private func fameExceptionalLoopAutoRecoveryLaneRecommendationStatusLine(
        now: Date,
        defaults: UserDefaults = .standard
    ) -> String {
        let commandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let windowedCommandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let topRecoveryLane = AppDelegate.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        )
        let missesRequired = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
        let failureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
            )
        let cooldownMinutes = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        let recommendationSummary = AppDelegate
            .fameExceptionalLoopAutoRecoveryLaneTuningRecommendationSummary(
                recommendation: AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                    topRecoveryLane: topRecoveryLane
                ),
                currentMissesRequired: missesRequired,
                currentFailureStreakRequired: failureStreakRequired,
                currentCooldownMinutes: cooldownMinutes
        )
        return "Recommendation: \(recommendationSummary)"
    }

    private func fameExceptionalLoopHealthSnapshot(
        now: Date,
        defaults: UserDefaults = .standard
    ) -> AppDelegate.FameExceptionalLoopHealthSnapshot {
        let outcomeScoreboard = AppDelegate.fameExceptionalLoopOutcomeScoreboard(defaults: defaults)
        let commandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let windowedCommandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        return AppDelegate.fameExceptionalLoopHealthSnapshot(
            scoreboard: outcomeScoreboard,
            history: windowedCommandHistory
        )
    }

    @ViewBuilder
    private func fameExceptionalLoopHealthCard(
        snapshot: AppDelegate.FameExceptionalLoopHealthSnapshot,
        runRecommendedAction: @escaping () -> Void
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Button("Run Recommended Action") {
                        runRecommendedAction()
                    }
                    .help("Runs \(snapshot.recommendedActionTitle) from the latest exceptional-loop telemetry.")

                    Spacer(minLength: 8)

                    Text(snapshot.recommendedActionTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
                Text(snapshot.trend)
                Text("Top win lane: \(snapshot.topWinLane)")
                Text("Top recovery lane: \(snapshot.topRecoveryLane)")
                Text("Recommended next action: \(snapshot.recommendedNextAction)")
                HStack(alignment: .center, spacing: 8) {
                    Text("Recommendation confidence")
                    fameExceptionalLoopConfidenceBadge(snapshot.recommendedActionConfidenceTitle)
                    ProgressView(value: fameExceptionalLoopConfidenceValue(snapshot.recommendedActionConfidenceTitle))
                        .progressViewStyle(.linear)
                        .tint(fameExceptionalLoopConfidenceColor(snapshot.recommendedActionConfidenceTitle))
                        .frame(width: 76)
                }
                Text("Why this action: \(snapshot.recommendedActionWhy)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Exceptional Loop Health")
                .font(.caption.weight(.semibold))
        }
    }

    private func fameExceptionalLoopConfidenceValue(_ title: String) -> Double {
        switch title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "high":
            return 1.0
        case "medium":
            return 0.66
        default:
            return 0.33
        }
    }

    private func fameExceptionalLoopConfidenceColor(_ title: String) -> Color {
        switch title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "high":
            return .green
        case "medium":
            return .orange
        default:
            return .yellow
        }
    }

    @ViewBuilder
    private func fameExceptionalLoopConfidenceBadge(_ title: String) -> some View {
        let color = fameExceptionalLoopConfidenceColor(title)
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(0.18))
            .clipShape(Capsule())
    }

    private func fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
        now: Date,
        defaults: UserDefaults = .standard
    ) -> AppDelegate.FameExceptionalLoopAutoRecoveryLaneTuningMenuStatus {
        let commandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let windowedCommandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let topRecoveryLane = AppDelegate.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        )
        let missesRequired = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneMissesRequired(
            settings.fameExceptionalLoopAutoRecoveryLaneMissesRequired
        )
        let failureStreakRequired =
            AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneFailureStreakRequired(
                settings.fameExceptionalLoopAutoRecoveryLaneFailureStreakRequired
            )
        let cooldownMinutes = AppDefaults.normalizedFameExceptionalLoopAutoRecoveryLaneCooldownMinutes(
            settings.fameExceptionalLoopAutoRecoveryLaneCooldownMinutes
        )
        return AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningMenuStatus(
            recommendation: AppDelegate.fameExceptionalLoopAutoRecoveryLaneTuningRecommendation(
                topRecoveryLane: topRecoveryLane
            ),
            currentMissesRequired: missesRequired,
            currentFailureStreakRequired: failureStreakRequired,
            currentCooldownMinutes: cooldownMinutes
        )
    }

    private func fameExceptionalLoopRecoveryLaneMenuStatus(
        now: Date,
        defaults: UserDefaults = .standard
    ) -> AppDelegate.FameExceptionalLoopRecoveryLaneMenuStatus {
        let commandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let windowedCommandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistoryWindow(
            commandHistory,
            now: now
        )
        let topRecoveryLane = AppDelegate.fameExceptionalLoopOutcomeTopRecoveryLaneScoreboard(
            history: windowedCommandHistory
        )
        return AppDelegate.fameExceptionalLoopRecoveryLaneMenuStatus(topRecoveryLane)
    }

    private func fameExceptionalLoopLatestRecapStatus() -> AppDelegate.FameExceptionalLoopLatestRecapStatus {
        let hasSavedRecap = (try? FameSnapshotArchive.latestExceptionalLoopRecapURL()) != nil
        return AppDelegate.fameExceptionalLoopLatestRecapStatus(hasSavedRecap: hasSavedRecap)
    }

    private func fameExceptionalLoopOutcomeTuningResetStatus(
        defaults: UserDefaults = .standard
    ) -> AppDelegate.FameExceptionalLoopOutcomeTuningResetStatus {
        let commandHistory = AppDelegate.fameExceptionalLoopOutcomeCommandHistory(defaults: defaults)
        let lastOutcomeAt: Date?
        if defaults.object(forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey) != nil {
            let stamp = defaults.double(forKey: AppDefaults.fameExceptionalLoopOutcomeLastAtKey)
            lastOutcomeAt = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
        } else {
            lastOutcomeAt = nil
        }

        return AppDelegate.fameExceptionalLoopOutcomeTuningResetStatus(
            attempts: max(0, defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeTotalCountKey)),
            successes: max(0, defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessCountKey)),
            successStreak: max(
                0,
                defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeSuccessStreakKey)
            ),
            failureStreak: max(
                0,
                defaults.integer(forKey: AppDefaults.fameExceptionalLoopOutcomeFailureStreakKey)
            ),
            lastFocusToken: defaults.string(forKey: AppDefaults.fameExceptionalLoopOutcomeLastFocusTokenKey),
            lastOutcomeAt: lastOutcomeAt,
            commandHistory: commandHistory
        )
    }

    private func fameLaunchRecoveryHotKeyAutoCoachStatusLine(now: Date) -> String {
        let status = CommandPaletteTopPicks.launchRecoveryHotKeyAutoCoachStatus(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoCoachEnabled,
            lastRunAt: launchRecoveryHotKeyAutoCoachLastRunAt(),
            now: now,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes
        )
        switch status {
        case .disabled:
            return "Status: launch recovery auto-coach is off."
        case .ready:
            if settings.fameLaunchRecoveryHotKeyAutoCoachCooldownMinutes == 0 {
                return "Status: launch recovery auto-coach runs on every repeated Recovery Drift cue (cooldown off)."
            }
            return "Status: launch recovery auto-coach is ready on the next repeated Recovery Drift cue."
        case .coolingDown(let minutesRemaining):
            return "Status: launch recovery auto-coach cooldown active — next auto run in about \(minutesRemaining) min."
        }
    }

    private func fameLaunchRecoveryHotKeyAutoRescueStatusLine(now: Date) -> String {
        let status = CommandPaletteTopPicks.launchRecoveryHotKeyAutoRescueStatus(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoRescueEnabled,
            lastRunAt: launchRecoveryHotKeyAutoRescueLastRunAt(),
            now: now,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes
        )
        switch status {
        case .disabled:
            return "Status: launch recovery auto rescue guard is off."
        case .ready:
            if settings.fameLaunchRecoveryHotKeyAutoRescueCooldownMinutes == 0 {
                return "Status: launch recovery auto rescue guard runs on every Momentum Alert (cooldown off)."
            }
            return "Status: launch recovery auto rescue guard is ready on the next Momentum Alert."
        case .coolingDown(let minutesRemaining):
            return "Status: launch recovery auto rescue guard cooldown active — next auto run in about \(minutesRemaining) min."
        }
    }

    private func fameRecommendationMomentumRescueHallOfFameAutoDefenseStatusLine(
        now: Date
    ) -> String {
        let status = CommandPaletteTopPicks.recommendationMomentumRescueHallOfFameAutoDefenseStatus(
            isEnabled: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseEnabled,
            lastRunAt: recommendationMomentumRescueHallOfFameAutoDefenseLastRunAt(),
            now: now,
            cooldownMinutes: settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes
        )
        switch status {
        case .disabled:
            return "Status: Hall-of-Fame auto-defense is off."
        case .ready:
            if settings.fameRecommendationMomentumRescueHallOfFameAutoDefenseCooldownMinutes == 0 {
                return "Status: Hall-of-Fame auto-defense runs on every Hall-of-Fame cue (cooldown off)."
            }
            return "Status: Hall-of-Fame auto-defense is ready on the next Hall-of-Fame cue."
        case .coolingDown(let minutesRemaining):
            return "Status: Hall-of-Fame auto-defense cooldown active — next auto run in about \(minutesRemaining) min."
        }
    }

    private func fameLaunchRecoveryHotKeyAutoTrustSurgeStatusLine(now: Date) -> String {
        let runsToday = launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday(now: now)
        let streak = launchRecoveryHotKeyAutoTrustSurgeStreak()
        let weeklyRuns = launchRecoveryHotKeyAutoTrustSurgeWeeklyRuns(now: now)
        let status = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
            isEnabled: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
            lastRunAt: launchRecoveryHotKeyAutoTrustSurgeLastRunAt(),
            now: now,
            cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
            dailyCap: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
            runsToday: runsToday
        )
        let leagueBadge = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueBadge(
            status: status,
            runsToday: runsToday,
            currentWeekRuns: weeklyRuns.current,
            bestWeekRuns: weeklyRuns.best,
            currentStreak: streak.current,
            bestStreak: streak.best
        )
        let leagueProgress = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueProgress(
            status: status,
            runsToday: runsToday,
            currentWeekRuns: weeklyRuns.current,
            bestWeekRuns: weeklyRuns.best,
            currentStreak: streak.current,
            bestStreak: streak.best
        )
        var metricFragments: [String] = []
        if streak.current > 0 {
            metricFragments.append("Streak x\(streak.current)d (best x\(streak.best)d)")
        }
        if weeklyRuns.current > 0 {
            metricFragments.append("Week \(weeklyRuns.current) (best \(weeklyRuns.best))")
        }
        if let leagueBadge {
            metricFragments.append(leagueBadge.title)
        }
        if let leagueProgress {
            if leagueProgress.pointsToNextTier > 0 {
                metricFragments.append("\(leagueProgress.pointsToNextTier) pts to next league")
            } else {
                metricFragments.append("Legend locked")
            }
        }
        let metricsSuffix = metricFragments.isEmpty
            ? ""
            : " " + metricFragments.joined(separator: " · ") + "."
        switch status {
        case .disabled:
            return "Status: launch recovery auto Trust Surge is off.\(metricsSuffix)"
        case .ready:
            if settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes == 0 {
                return "Status: launch recovery auto Trust Surge runs whenever momentum is 1 open from the next milestone (cooldown off).\(metricsSuffix)"
            }
            return "Status: launch recovery auto Trust Surge is ready when momentum is 1 open from the next milestone.\(metricsSuffix)"
        case .capped(let runsToday, let dailyCap):
            let runWord = runsToday == 1 ? "run" : "runs"
            return "Status: launch recovery auto Trust Surge reached today’s cap (\(runsToday)/\(dailyCap) \(runWord)); re-arms after midnight.\(metricsSuffix)"
        case .coolingDown(let minutesRemaining):
            return "Status: launch recovery auto Trust Surge cooldown active — next auto run in about \(minutesRemaining) min.\(metricsSuffix)"
        }
    }

    @ViewBuilder
    private func launchRecoveryHotKeyAutoTrustSurgeLeagueHistoryPanel(now: Date) -> some View {
        let history = launchRecoveryHotKeyAutoTrustSurgeLeagueHistory()
        if !history.isEmpty {
            let runsToday = launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday(now: now)
            let streak = launchRecoveryHotKeyAutoTrustSurgeStreak()
            let weeklyRuns = launchRecoveryHotKeyAutoTrustSurgeWeeklyRuns(now: now)
            let status = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeStatus(
                isEnabled: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeEnabled,
                lastRunAt: launchRecoveryHotKeyAutoTrustSurgeLastRunAt(),
                now: now,
                cooldownMinutes: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeCooldownMinutes,
                dailyCap: settings.fameLaunchRecoveryHotKeyAutoTrustSurgeDailyCap,
                runsToday: runsToday
            )
            let transition = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTransition(
                history: history
            )
            let trend = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTrend(
                history: history,
                sampleLimit: 4
            )
            let legendDefense = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLegendDefense(
                status: status,
                trend: trend,
                runsToday: runsToday,
                currentWeekRuns: weeklyRuns.current,
                bestWeekRuns: weeklyRuns.best,
                currentStreak: streak.current,
                bestStreak: streak.best,
                enabledActionIDs: []
            )
            let legendDecayForecast = CommandPaletteTopPicks
                .launchRecoveryHotKeyAutoTrustSurgeLegendDecayForecast(
                    status: status,
                    trend: trend,
                    runsToday: runsToday,
                    currentWeekRuns: weeklyRuns.current,
                    bestWeekRuns: weeklyRuns.best,
                    currentStreak: streak.current,
                    bestStreak: streak.best,
                    enabledActionIDs: [],
                    now: now
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Auto League history (weekly):")
                    .font(.caption.weight(.semibold))

                ForEach(Array(history.prefix(6))) { week in
                    Text(
                        "• \(launchRecoveryHotKeyAutoTrustSurgeHistoryWeekLabel(week.weekStamp, now: now)): \(CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(week.tier)) · score \(week.leagueScore) · week \(week.runsThisWeek)/\(week.bestWeekRuns) · streak x\(week.currentStreak)d"
                    )
                }

                if let transition {
                    let direction = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(
                        transition.toTier
                    ) >= CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTierRank(
                        transition.fromTier
                    ) ? "up" : "down"
                    Text(
                        "Latest tier shift (\(direction)): \(CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(transition.fromTier)) -> \(CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueTierTitle(transition.toTier))"
                    )
                }

                if let trend {
                    Text("League momentum: \(trend.title) · \(trend.subtitle)")
                }

                if let legendDefense {
                    Text("Legend defense: \(legendDefense.title) · \(legendDefense.subtitle)")
                }

                if let legendDecayForecast {
                    Text("Legend decay forecast: \(legendDecayForecast.title) · \(legendDecayForecast.subtitle)")
                }
            }
            .padding(.top, 4)
        }
    }

    private func fameLaunchHealthPulseStatusLine() -> String {
        guard settings.fameLaunchThresholdAlertsEnabled else {
            return "Status: launch health pulse is muted because launch threshold alerts are off."
        }
        guard settings.fameLaunchHealthPulseEnabled else {
            return "Status: launch health pulse is off."
        }
        let cooldown = settings.fameLaunchHealthPulseCooldownSeconds
        guard cooldown > 0 else {
            return "Status: launch health pulse runs on every Watch -> Risk and Risk -> Ready transition."
        }
        return "Status: launch health pulse repeats same transition after \(launchHealthPulseCooldownLabel(seconds: cooldown))."
    }

    private func fameOnboardingNudgeStatusLine() -> String {
        guard settings.fameOnboardingNudgeEnabled else {
            return "Status: fame onboarding nudge is off."
        }
        let windowDays = settings.fameOnboardingNudgeWindowDays
        let guide = FirstRunGuide(defaults: .standard)
        let completedDays = guide.fameOnboardingCompletedDays(onboardingWindowDays: windowDays)
        let remainingDays = guide.fameOnboardingRemainingDays(onboardingWindowDays: windowDays)
        return "Status: fame onboarding nudge can surface once per day during days 1-\(windowDays) · \(completedDays)/\(windowDays) complete, \(remainingDays) left."
    }

    private func fameOnboardingScorecardStatusLine(now: Date = Date()) -> String {
        guard settings.fameOnboardingNudgeEnabled else {
            return "Status: first-week fame scorecard is off because onboarding nudge is off."
        }

        let windowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            settings.fameOnboardingNudgeWindowDays
        )
        let guide = FirstRunGuide(defaults: .standard)
        let onboardingDay = guide.fameOnboardingDay(now: now)
        let completedDays = guide.fameOnboardingCompletedDays(onboardingWindowDays: windowDays)
        let remainingDays = guide.fameOnboardingRemainingDays(onboardingWindowDays: windowDays)
        let cadenceBestStreak = max(
            0,
            UserDefaults.standard.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        )

        guard AppDelegate.isFameOnboardingScorecardActionEligible(
            fameOnboardingEnabled: settings.fameOnboardingNudgeEnabled,
            cadenceBestStreak: cadenceBestStreak,
            onboardingDay: onboardingDay,
            completedDays: completedDays,
            onboardingWindowDays: windowDays
        ) else {
            if cadenceBestStreak >= 10 {
                return "Status: first-week fame scorecard pauses after best cadence streak reaches x10 (current best x\(cadenceBestStreak))."
            }
            if completedDays >= windowDays {
                return "Status: first-week fame scorecard is complete for this install window (\(windowDays)/\(windowDays) done)."
            }
            if onboardingDay > windowDays {
                return "Status: first-week fame scorecard window ended after day \(windowDays)."
            }
            return "Status: first-week fame scorecard is currently unavailable."
        }

        let cadenceCurrentStreak = max(
            0,
            UserDefaults.standard.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        )
        let plan = AppDelegate.fameOnboardingNudgePlan(
            day: onboardingDay,
            currentStreak: cadenceCurrentStreak,
            bestStreak: cadenceBestStreak,
            windowDays: windowDays
        )
        let paceLine = AppDelegate.fameOnboardingScorecardPaceLine(
            day: onboardingDay,
            windowDays: windowDays,
            completedDays: completedDays
        )
        let nextCommandTitle = AppDelegate.fameOnboardingCommandTitle(plan.primaryCommandID)
        return "Status: first-week fame scorecard is ready for day \(onboardingDay)/\(windowDays) · \(completedDays)/\(windowDays) complete, \(remainingDays) left · \(paceLine) · Next \(nextCommandTitle)."
    }

    private func fameOnboardingDailyBriefStatusLine(now: Date = Date()) -> String {
        guard settings.fameOnboardingNudgeEnabled else {
            return "Status: first-week daily brief is off because onboarding nudge is off."
        }

        let windowDays = AppDefaults.normalizedFameOnboardingNudgeWindowDays(
            settings.fameOnboardingNudgeWindowDays
        )
        let guide = FirstRunGuide(defaults: .standard)
        let onboardingDay = guide.fameOnboardingDay(now: now)
        let completedDays = guide.fameOnboardingCompletedDays(onboardingWindowDays: windowDays)
        let cadenceCurrentStreak = max(
            0,
            UserDefaults.standard.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandStreakKey)
        )
        let cadenceBestStreak = max(
            cadenceCurrentStreak,
            UserDefaults.standard.integer(forKey: AppDefaults.fameCadenceExecutionKitCommandBestStreakKey)
        )

        guard AppDelegate.isFameOnboardingScorecardActionEligible(
            fameOnboardingEnabled: settings.fameOnboardingNudgeEnabled,
            cadenceBestStreak: cadenceBestStreak,
            onboardingDay: onboardingDay,
            completedDays: completedDays,
            onboardingWindowDays: windowDays
        ) else {
            return "Status: first-week daily brief is unavailable until first-week scorecard conditions are met."
        }

        let remainingDays = guide.fameOnboardingRemainingDays(onboardingWindowDays: windowDays)
        let plan = AppDelegate.fameOnboardingNudgePlan(
            day: onboardingDay,
            currentStreak: cadenceCurrentStreak,
            bestStreak: cadenceBestStreak,
            windowDays: windowDays
        )
        let nextCommandTitle = AppDelegate.fameOnboardingCommandTitle(plan.primaryCommandID)
        return "Status: first-week daily brief is ready for day \(onboardingDay)/\(windowDays) · \(completedDays)/\(windowDays) complete, \(remainingDays) left · saves nudge + scorecard + daily brief · Next \(nextCommandTitle)."
    }

    private func fameLaunchHealthPressureAutoRescueStatusLine(now: Date) -> String {
        guard settings.fameLaunchHealthPressureAutoRescueEnabled else {
            return "Status: pressure streak auto-rescue is off."
        }
        let cooldownHours = settings.fameLaunchHealthPressureAutoRescueCooldownHours
        guard cooldownHours > 0 else {
            return "Status: pressure streak auto-rescue runs on every eligible Signal Pressure 2d+ state (cooldown off)."
        }

        let cooldown = TimeInterval(cooldownHours * 60 * 60)
        if let lastRunAt = launchHealthPressureAutoRescueLastRunAt() {
            let elapsed = max(0, now.timeIntervalSince(lastRunAt))
            if elapsed < cooldown {
                let remainingMinutes = max(1, Int(ceil((cooldown - elapsed) / 60)))
                return "Status: pressure streak auto-rescue cooldown active — next auto run in about \(remainingMinutes) min."
            }
        }

        return "Status: pressure streak auto-rescue is ready when Signal Pressure persists for 2d+."
    }

    private func cadenceAutopilotCueStatusLine() -> String {
        let cooldown = settings.fameCadenceAutopilotCueCooldownSeconds
        guard cooldown > 0 else {
            return "Status: cadence autopilot cue surfaces every reset/milestone event (cooldown off)."
        }
        return "Status: cadence autopilot repeats same reset/milestone cue after \(launchHealthPulseCooldownLabel(seconds: cooldown)); different cue types surface immediately."
    }

    private func cadenceCelebrationStatusLine() -> String {
        let title = AppDelegate.cadenceExecutionKitAutopilotCelebrationIntensityTitle(
            settings.fameCadenceAutopilotCelebrationIntensity
        )
        switch AppDefaults.normalizedFameCadenceAutopilotCelebrationIntensity(
            settings.fameCadenceAutopilotCelebrationIntensity
        ) {
        case 0:
            return "Status: cadence celebration profile is \(title) — softer flashes, fewer haptics, no extra pulse burst."
        case 2:
            return "Status: cadence celebration profile is \(title) — stronger haptics, brighter flashes, and extra pulse burst on big milestones."
        default:
            return "Status: cadence celebration profile is \(title) — balanced celebration feedback for resets and milestones."
        }
    }

    private func launchHealthPulseCooldownLabel(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        if seconds % 60 == 0 {
            return "\(minutes)m"
        }
        return String(format: "%.1fm", Double(seconds) / 60.0)
    }

    private func autoOpsBundleLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameAutoOpsBundleLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameAutoOpsBundleLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func launchRescueBurstLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameLaunchRescueBurstLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameLaunchRescueBurstLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func launchHealthPressureAutoRescueLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameLaunchHealthPressureAutoRescueLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameLaunchHealthPressureAutoRescueLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func fameExceptionalLoopRecoveryLaneAutoRunLastAt(
        defaults: UserDefaults = .standard
    ) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameExceptionalLoopRecoveryLaneAutoRunLastAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
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

    private func launchRecoveryHotKeyAutoTrustSurgeLastRunAt(defaults: UserDefaults = .standard) -> Date? {
        guard defaults.object(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey) != nil else {
            return nil
        }
        let stamp = defaults.double(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLastRunAtKey)
        guard stamp > 0 else { return nil }
        return Date(timeIntervalSince1970: stamp)
    }

    private func launchRecoveryHotKeyAutoTrustSurgeAutoRunsToday(
        now: Date,
        defaults: UserDefaults = .standard
    ) -> Int {
        let dayStamp = defaults.string(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunDayKey)
        let runs = defaults.integer(forKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeAutoRunCountKey)
        return CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeRunsToday(
            dayStamp: dayStamp,
            storedCount: runs,
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
        now: Date,
        defaults: UserDefaults = .standard
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

    private func launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
        defaults: UserDefaults = .standard
    ) -> [CommandPaletteTopPicks.LaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryWeek] {
        CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeLeagueHistory(
            defaults: defaults,
            historyKey: AppDefaults.fameLaunchRecoveryHotKeyAutoTrustSurgeLeagueHistoryKey,
            limit: 12
        )
    }

    private func launchRecoveryHotKeyAutoTrustSurgeHistoryWeekLabel(
        _ weekStamp: String,
        now: Date
    ) -> String {
        guard let weekStartTimestamp = Double(weekStamp),
              weekStartTimestamp > 0 else {
            return weekStamp
        }
        let weekStartDate = Date(timeIntervalSince1970: weekStartTimestamp)
        let todayStamp = CommandPaletteTopPicks.launchRecoveryHotKeyAutoTrustSurgeWeekStamp(now: now)
        if weekStamp == todayStamp {
            return "This week"
        }
        return weekStartDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private func refreshCadenceExecutionKitStreak(defaults: UserDefaults = .standard) {
        cadenceExecutionKitStreak = CommandPaletteCadenceExecutionKitStreak.currentStreak(defaults: defaults)
        cadenceExecutionKitBestStreak = CommandPaletteCadenceExecutionKitStreak.bestStreak(defaults: defaults)
    }
}

private struct LaunchAtLoginRow: View {
    @State private var state = LaunchAtLoginManager.state
    @State private var errorText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Open at login", isOn: Binding(
                get: { state.isEnabled },
                set: setOpenAtLogin
            ))
            .disabled(!state.canToggle)

            Text(state.detail)
                .font(.caption)
                .foregroundStyle(.secondary)

            if state == .requiresApproval {
                Button("Open Login Items Settings") {
                    LaunchAtLoginManager.openSettings()
                }
            }

            if !errorText.isEmpty {
                Text(errorText)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onAppear(perform: refresh)
    }

    private func setOpenAtLogin(_ isEnabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(isEnabled)
            errorText = ""
        } catch {
            errorText = error.localizedDescription
        }
        refresh()
    }

    private func refresh() {
        state = LaunchAtLoginManager.state
    }
}
