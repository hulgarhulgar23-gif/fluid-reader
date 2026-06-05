import AppKit
import SwiftUI

@MainActor
final class ReaderWindowController {
    private let window: NSWindow

    init(
        state: ReaderState,
        settings: SettingsStore,
        readText: @escaping (String) -> Void,
        askLLM: @escaping (String) -> Void,
        stop: @escaping () -> Void
    ) {
        let view = ReaderView(
            state: state,
            settings: settings,
            readText: readText,
            askLLM: askLLM,
            stop: stop
        )

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 580),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Fluid Reader"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.contentViewController = NSHostingController(rootView: view)
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct ReaderView: View {
    @ObservedObject var state: ReaderState
    @ObservedObject var settings: SettingsStore
    let readText: (String) -> Void
    let askLLM: (String) -> Void
    let stop: () -> Void

    @State private var question = ""
    @State private var glow = false

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.86)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                header

                editor(
                    title: "Selected text",
                    text: $state.lastText,
                    minHeight: 170
                )
                .shadow(color: glow ? Color.cyan.opacity(0.35) : .clear, radius: glow ? 18 : 0)

                HStack(spacing: 10) {
                    Button {
                        readText(state.lastText)
                    } label: {
                        Label("Read", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }

                    Spacer()
                }

                if settings.llmEnabled {
                    llmPanel
                } else {
                    offlinePanel
                }

                if !state.errorText.isEmpty {
                    Label(state.errorText, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(18)
        }
        .frame(minWidth: 460, minHeight: 440)
        .animation(.easeInOut(duration: 0.18), value: state.isWorking)
        .animation(.easeInOut(duration: 0.18), value: settings.llmEnabled)
        .onChange(of: state.pulseID) { _, _ in
            withAnimation(.spring(response: 0.24, dampingFraction: 0.62)) {
                glow = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                withAnimation(.easeOut(duration: 0.28)) {
                    glow = false
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.viewfinder")
                .font(.title2)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("Fluid Reader")
                    .font(.title2.weight(.semibold))
                Text(state.isWorking ? "Reading screen content" : "Ready")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if state.isWorking {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "sparkle")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.top, 6)
    }

    private var llmPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            HStack(spacing: 10) {
                TextField("Ask about this", text: $question)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        askLLM(question)
                    }

                Button {
                    askLLM(question)
                } label: {
                    Label("Ask", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack {
                Button {
                    readText(state.answerText)
                } label: {
                    Label("Read Answer", systemImage: "speaker.wave.2.fill")
                }
                .disabled(state.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }

            editor(title: "Answer", text: $state.answerText, minHeight: 130)
        }
    }

    private var offlinePanel: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.green)
            Text("Local mode")
                .font(.callout.weight(.medium))
            Text("LLM is off.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private func editor(title: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextEditor(text: text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: minHeight)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.20))
                )
        }
    }
}
