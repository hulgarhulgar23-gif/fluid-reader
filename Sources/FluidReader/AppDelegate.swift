import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = SettingsStore.shared
    private let readerState = ReaderState()
    private let speech = SpeechService()
    private let effects = EffectsService()
    private let rewardHUD = RewardHUDController()
    private let ocr = OCRService()
    private let selectionController = SelectionController()
    private let hotKey = HotKeyManager()
    private lazy var readerWindow = ReaderWindowController(
        state: readerState,
        settings: settings,
        readText: { [weak self] text in self?.read(text) },
        askLLM: { [weak self] question in self?.askLLM(question: question) },
        stop: { [weak self] in self?.stopSpeech() }
    )
    private lazy var settingsWindow = SettingsWindowController(
        settings: settings,
        testVoice: { [weak self] in self?.read("This is Fluid Reader.") },
        testEffect: { [weak self] in
            self?.previewFeelFlow()
        }
    )
    private var statusItem: NSStatusItem?
    private var statusFlashTask: Task<Void, Never>?
    private var workingFeedbackTask: Task<Void, Never>?
    private var previewFeelTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []
    private var styleMenuItems: [String: NSMenuItem] = [:]
    private var hitMenuItems: [Double: NSMenuItem] = [:]
    private var compareRestoreSettings: (style: String, intensity: Double)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        effects.preloadAllStyles()
        effects.warmAudioPath()
        bindSettings()
        let result = hotKey.register { [weak self] in
            Task { @MainActor in
                self?.startPick()
            }
        }

        if case .failure(let error) = result {
            showHotKeyError(error)
        }
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
    }

    private func setupMenu() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        item.button?.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "Fluid Reader")
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Pick and Read", action: #selector(pickFromMenu), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Reader", action: #selector(showReaderFromMenu), keyEquivalent: ""))
        menu.addItem(makeFeelMenuItem())
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

    private func startPick() {
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
                readerWindow.show()
                return
            }

            readerState.pulse()
            effects.hit(.success, settings: settings, haptic: .levelChange)
            rewardHUD.show("Ready", mood: .success, intensity: settings.feelIntensity)
            flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.42)

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
            readerWindow.show()
        }
    }

    private func read(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        speech.speak(text, settings: settings)
    }

    private func stopSpeech() {
        speech.stop()
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
                    readerState.pulse()
                    readerState.isWorking = false
                    effects.hit(.success, settings: settings, haptic: .levelChange)
                    flashStatus(symbol: "sparkles", tint: .systemGreen, length: 0.42)
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

    private func flashStatus(symbol: String, tint: NSColor, length: TimeInterval) {
        guard let button = statusItem?.button else { return }
        statusFlashTask?.cancel()

        let normalImage = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "Fluid Reader")
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Fluid Reader")
        button.contentTintColor = tint

        statusFlashTask = Task { [weak button] in
            try? await Task.sleep(nanoseconds: UInt64(length * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                button?.image = normalImage
                button?.contentTintColor = nil
            }
        }
    }
}
