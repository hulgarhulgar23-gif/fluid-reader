import AppKit
import SwiftUI

@MainActor
final class AskPromptWindow {
    private static let preferredContentSize = NSSize(width: 520, height: 220)

    private let session = AskSession()
    private let submit: (String) -> Void
    private let window: NSPanel

    init(submit: @escaping (String) -> Void) {
        self.submit = submit

        window = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Ask Anything"
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
        WindowBounds.reset(
            window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.preferredContentSize,
            maxContentSize: Self.preferredContentSize
        )
        window.contentViewController = NSHostingController(
            rootView: AskPromptView(
                session: session,
                close: { [weak self] in self?.hide() },
                submit: { [weak self] prompt in
                    self?.hide()
                    self?.submit(prompt)
                }
            )
        )
    }

    func show() {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        session.beginOpen()
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

    private func hide() {
        window.orderOut(nil)
    }
}

typealias AskPromptWindowController = AskPromptWindow

private final class AskSession: ObservableObject {
    @Published private(set) var openCount = 0

    func beginOpen() {
        openCount += 1
    }
}

private struct AskPromptView: View {
    @ObservedObject var session: AskSession
    let close: () -> Void
    let submit: (String) -> Void

    @State private var prompt = ""
    @FocusState private var promptIsFocused: Bool

    private var cleanPrompt: String {
        FreeformPrompt.clean(prompt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Ask Anything", systemImage: "sparkles")
                .font(.title3.weight(.semibold))

            TextField("Ask about the current text, image, selection, or clipboard", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...5)
                .focused($promptIsFocused)
                .onSubmit(run)

            HStack {
                Spacer()
                Button("Cancel") {
                    close()
                }
                Button {
                    run()
                } label: {
                    Label("Ask", systemImage: "arrow.up.circle.fill")
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .disabled(cleanPrompt.isEmpty)
            }
        }
        .padding(18)
        .frame(minWidth: 480, minHeight: 180)
        .background(.regularMaterial)
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
}
