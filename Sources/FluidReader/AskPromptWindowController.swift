import AppKit
import SwiftUI

@MainActor
final class AskPromptWindow {
    private static let preferredContentSize = NSSize(width: 540, height: 300)
    private let windowObserver = AskPromptWindowObserver()

    struct Configuration {
        struct PromptSuggestion: Identifiable, Equatable {
            let id: String
            let title: String
            let prompt: String
        }

        let title: String
        let systemImage: String
        let promptPlaceholder: String
        let helperText: String
        let submitTitle: String
        let submitSystemImage: String
        let suggestions: [PromptSuggestion]

        static let askAnything = Configuration(
            title: "Ask Anything",
            systemImage: "sparkles",
            promptPlaceholder: "Ask about the current text, image, selection, or clipboard",
            helperText: "Uses current reader text first, then selected text, then clipboard text, then asks you to pick from screen if needed.",
            submitTitle: "Ask",
            submitSystemImage: "arrow.up.circle.fill",
            suggestions: [
                PromptSuggestion(
                    id: "summary",
                    title: "Summary",
                    prompt: "Summarize this in a short, clear way."
                ),
                PromptSuggestion(
                    id: "actions",
                    title: "Action Items",
                    prompt: "Find action items. Keep each one short and clear."
                ),
                PromptSuggestion(
                    id: "questions",
                    title: "Questions",
                    prompt: "List the main questions I should ask about this."
                ),
                PromptSuggestion(
                    id: "translate",
                    title: "English",
                    prompt: "Translate this to clear English."
                )
            ]
        )
    }

    private let session = AskSession()
    private let configuration: Configuration
    private let submit: (String) -> Void
    private let cancel: () -> Void
    private let window: NSPanel
    private var appDidResignActiveObserver: NSObjectProtocol?
    private var isSubmitting = false
    private var hasHandledDismissal = false

    init(
        configuration: Configuration = .askAnything,
        submit: @escaping (String) -> Void,
        cancel: @escaping () -> Void = {}
    ) {
        self.configuration = configuration
        self.submit = submit
        self.cancel = cancel

        window = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = configuration.title
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
        windowObserver.handleWillClose = { [weak self] in
            self?.handleExternalDismissal()
        }
        windowObserver.handleDidResignKey = { [weak self] in
            self?.handleKeyLoss()
        }
        window.delegate = windowObserver
        appDidResignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleAppDidResignActive()
            }
        }
        WindowBounds.reset(
            window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.preferredContentSize,
            maxContentSize: Self.preferredContentSize
        )
        window.contentViewController = NSHostingController(
            rootView: AskPromptView(
                session: session,
                configuration: configuration,
                close: { [weak self] in self?.cancelAndHide() },
                submit: { [weak self] prompt in
                    self?.submitAndHide(prompt)
                }
            )
        )
    }

    deinit {
        if let appDidResignActiveObserver {
            NotificationCenter.default.removeObserver(appDidResignActiveObserver)
        }
    }

    func show() {
        isSubmitting = false
        hasHandledDismissal = false
        session.beginOpen()
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        WindowBounds.reset(
            window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.preferredContentSize,
            maxContentSize: Self.preferredContentSize
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func cancelForTesting() {
        cancelAndHide()
    }

    private func hide() {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        window.orderOut(nil)
    }

    private func cancelAndHide() {
        handleDismissalIfNeeded()
        hide()
    }

    private func submitAndHide(_ prompt: String) {
        isSubmitting = true
        hasHandledDismissal = true
        hide()
        submit(prompt)
        isSubmitting = false
    }

    private func handleExternalDismissal() {
        guard !isSubmitting else { return }
        handleDismissalIfNeeded()
    }

    private func handleKeyLoss() {
        guard !isSubmitting else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.window.isVisible else { return }
            self.handleDismissalIfNeeded()
        }
    }

    private func handleAppDidResignActive() {
        guard !isSubmitting, window.isVisible else { return }
        handleDismissalIfNeeded()
    }

    private func handleDismissalIfNeeded() {
        guard !hasHandledDismissal else { return }
        hasHandledDismissal = true
        cancel()
    }
}

typealias AskPromptWindowController = AskPromptWindow

private final class AskPromptWindowObserver: NSObject, NSWindowDelegate {
    var handleWillClose: (() -> Void)?
    var handleDidResignKey: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        handleWillClose?()
    }

    func windowDidResignKey(_ notification: Notification) {
        handleDidResignKey?()
    }
}

private final class AskSession: ObservableObject {
    @Published private(set) var openCount = 0

    func beginOpen() {
        openCount += 1
    }
}

private struct AskPromptView: View {
    @ObservedObject var session: AskSession
    let configuration: AskPromptWindow.Configuration
    let close: () -> Void
    let submit: (String) -> Void

    @State private var prompt = ""
    @FocusState private var promptIsFocused: Bool

    private var cleanPrompt: String {
        FreeformPrompt.clean(prompt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(configuration.title, systemImage: configuration.systemImage)
                .font(.title3.weight(.semibold))

            TextField(configuration.promptPlaceholder, text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
                .focused($promptIsFocused)
                .onSubmit(run)

            Text(configuration.helperText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !configuration.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick start")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(configuration.suggestions) { suggestion in
                                Button(suggestion.title) {
                                    applySuggestion(suggestion)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(nsColor: .textBackgroundColor).opacity(0.42))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    close()
                }
                Button {
                    run()
                } label: {
                    Label(configuration.submitTitle, systemImage: configuration.submitSystemImage)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(cleanPrompt.isEmpty)
            }
        }
        .padding(18)
        .frame(minWidth: 480, minHeight: 180)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear(perform: reset)
        .onChange(of: session.openCount) { _, _ in
            reset()
        }
        .onExitCommand(perform: close)
    }

    private func reset() {
        prompt = ""
        promptIsFocused = true
    }

    private func run() {
        let prompt = cleanPrompt
        guard !prompt.isEmpty else { return }
        submit(prompt)
    }

    private func applySuggestion(_ suggestion: AskPromptWindow.Configuration.PromptSuggestion) {
        prompt = suggestion.prompt
        promptIsFocused = true
    }
}
