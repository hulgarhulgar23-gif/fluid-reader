import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let window: NSWindow

    init(
        settings: SettingsStore,
        testVoice: @escaping () -> Void,
        testEffect: @escaping () -> Void
    ) {
        let view = SettingsView(
            settings: settings,
            testVoice: testVoice,
            testEffect: testEffect
        )
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentViewController = NSHostingController(rootView: view)
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    let testVoice: () -> Void
    let testEffect: () -> Void

    var body: some View {
        Form {
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

                HStack {
                    Text("OCR language")
                    TextField("en-US", text: $settings.ocrLanguageCode)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
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

                Button {
                    testEffect()
                } label: {
                    Label("Test Full Feel", systemImage: "sparkles")
                }
            }

            Section("LLM") {
                Toggle("Use LLM", isOn: $settings.llmEnabled)

                if settings.llmEnabled {
                    SecureField("OpenAI API key", text: $settings.openAIAPIKey)
                        .textFieldStyle(.roundedBorder)

                    TextField("Model", text: $settings.llmModel)
                        .textFieldStyle(.roundedBorder)

                    Toggle("Cloud voice for LLM answer", isOn: $settings.useCloudVoiceForLLM)

                    if settings.useCloudVoiceForLLM {
                        TextField("Voice model", text: $settings.cloudVoiceModel)
                            .textFieldStyle(.roundedBorder)
                        TextField("Voice", text: $settings.cloudVoiceName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Voice style", text: $settings.cloudVoiceInstructions)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(18)
        .frame(minWidth: 500, minHeight: 560)
    }
}
