import AppKit
import Combine
import SwiftUI

@MainActor
final class ReaderWindowController {
    private static let preferredContentSize = NSSize(width: 560, height: 580)
    private static let minContentSize = NSSize(width: 420, height: 420)
    private static let maxContentSize = NSSize(width: 760, height: 760)

    private let window: NSWindow
    private var cancellables: Set<AnyCancellable> = []
    private var hasPlacedWindow = false

    init(
        state: ReaderState,
        settings: SettingsStore,
        readText: @escaping (String) -> Void,
        copyText: @escaping (String, String) -> Void,
        copyResult: @escaping () -> Void,
        copyImage: @escaping () -> Void,
        saveText: @escaping (String, String, String) -> Void,
        saveResult: @escaping () -> Void,
        saveImage: @escaping () -> Void,
        saveSnippet: @escaping (String) -> Void,
        askLLM: @escaping (String) -> Void,
        stop: @escaping () -> Void,
        famePulseState: @escaping () -> FamePulseWidgetState,
        fameDailyScorecardState: @escaping () -> FameDailyScorecardState,
        cadenceExecutionKitMomentumSnapshot: @escaping () -> (current: Int, best: Int),
        fameAutoOpsBundleStatus: @escaping () -> AppDelegate.AutoOpsBundleEscalationStatus,
        fameAutoOpsBundleStatusTitle: @escaping () -> String,
        fameAutoOpsBundleStatusSubtitle: @escaping () -> String,
        runFameAutoOpsBundleStatusAction: @escaping () -> Void,
        fameLaunchRescueAutoStatus: @escaping () -> AppDelegate.AutoOpsBundleEscalationStatus,
        fameLaunchRescueAutoStatusTitle: @escaping () -> String,
        fameLaunchRescueAutoStatusSubtitle: @escaping () -> String,
        runFameLaunchRescueAutoStatusAction: @escaping () -> Void,
        runFameNextMoveCadenceExecutionKit: @escaping () -> Void,
        copyLatestNextMoveCadenceExecutionKit: @escaping () -> Void,
        runFameCadenceMomentumBrief: @escaping () -> Void,
        runFameCadenceAutopilotLoop: @escaping () -> Void,
        runFameDailyScorecard: @escaping () -> Void,
        runFameRecoverySprint: @escaping () -> Void,
        runFameRiskTimeline: @escaping () -> Void,
        runFameOperatorDashboard: @escaping () -> Void,
        openLatestRecoverySprint: @escaping () -> Void,
        openLatestDailyScorecard: @escaping () -> Void,
        openLatestOperatorDashboard: @escaping () -> Void
    ) {
        let view = ReaderView(
            state: state,
            settings: settings,
            readText: readText,
            copyText: copyText,
            copyResult: copyResult,
            copyImage: copyImage,
            saveText: saveText,
            saveResult: saveResult,
            saveImage: saveImage,
            saveSnippet: saveSnippet,
            askLLM: askLLM,
            stop: stop,
            famePulseState: famePulseState,
            fameDailyScorecardState: fameDailyScorecardState,
            cadenceExecutionKitMomentumSnapshot: cadenceExecutionKitMomentumSnapshot,
            fameAutoOpsBundleStatus: fameAutoOpsBundleStatus,
            fameAutoOpsBundleStatusTitle: fameAutoOpsBundleStatusTitle,
            fameAutoOpsBundleStatusSubtitle: fameAutoOpsBundleStatusSubtitle,
            runFameAutoOpsBundleStatusAction: runFameAutoOpsBundleStatusAction,
            fameLaunchRescueAutoStatus: fameLaunchRescueAutoStatus,
            fameLaunchRescueAutoStatusTitle: fameLaunchRescueAutoStatusTitle,
            fameLaunchRescueAutoStatusSubtitle: fameLaunchRescueAutoStatusSubtitle,
            runFameLaunchRescueAutoStatusAction: runFameLaunchRescueAutoStatusAction,
            runFameNextMoveCadenceExecutionKit: runFameNextMoveCadenceExecutionKit,
            copyLatestNextMoveCadenceExecutionKit: copyLatestNextMoveCadenceExecutionKit,
            runFameCadenceMomentumBrief: runFameCadenceMomentumBrief,
            runFameCadenceAutopilotLoop: runFameCadenceAutopilotLoop,
            runFameDailyScorecard: runFameDailyScorecard,
            runFameRecoverySprint: runFameRecoverySprint,
            runFameRiskTimeline: runFameRiskTimeline,
            runFameOperatorDashboard: runFameOperatorDashboard,
            openLatestRecoverySprint: openLatestRecoverySprint,
            openLatestDailyScorecard: openLatestDailyScorecard,
            openLatestOperatorDashboard: openLatestOperatorDashboard
        )

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
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
        WindowBounds.apply(
            to: window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.minContentSize,
            maxContentSize: Self.maxContentSize
        )
        window.contentViewController = NSHostingController(rootView: view)
        applyWindowLevel(settings.readerAlwaysOnTop)

        settings.$readerAlwaysOnTop
            .removeDuplicates()
            .sink { [weak self] isPinned in
                self?.applyWindowLevel(isPinned)
            }
            .store(in: &cancellables)
    }

    func show() {
        WindowBounds.apply(
            to: window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.minContentSize,
            maxContentSize: Self.maxContentSize
        )
        placeIfNeeded()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func placeIfNeeded() {
        guard hasPlacedWindow else {
            window.center()
            hasPlacedWindow = true
            return
        }

        let center = CGPoint(x: window.frame.midX, y: window.frame.midY)
        let isOnVisibleScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.contains(center)
        }

        if !isOnVisibleScreen {
            window.center()
        }
    }

    private func applyWindowLevel(_ isPinned: Bool) {
        window.level = isPinned ? .floating : .normal
    }
}

private struct ReaderView: View {
    @ObservedObject var state: ReaderState
    @ObservedObject var settings: SettingsStore
    let readText: (String) -> Void
    let copyText: (String, String) -> Void
    let copyResult: () -> Void
    let copyImage: () -> Void
    let saveText: (String, String, String) -> Void
    let saveResult: () -> Void
    let saveImage: () -> Void
    let saveSnippet: (String) -> Void
    let askLLM: (String) -> Void
    let stop: () -> Void
    let famePulseState: () -> FamePulseWidgetState
    let fameDailyScorecardState: () -> FameDailyScorecardState
    let cadenceExecutionKitMomentumSnapshot: () -> (current: Int, best: Int)
    let fameAutoOpsBundleStatus: () -> AppDelegate.AutoOpsBundleEscalationStatus
    let fameAutoOpsBundleStatusTitle: () -> String
    let fameAutoOpsBundleStatusSubtitle: () -> String
    let runFameAutoOpsBundleStatusAction: () -> Void
    let fameLaunchRescueAutoStatus: () -> AppDelegate.AutoOpsBundleEscalationStatus
    let fameLaunchRescueAutoStatusTitle: () -> String
    let fameLaunchRescueAutoStatusSubtitle: () -> String
    let runFameLaunchRescueAutoStatusAction: () -> Void
    let runFameNextMoveCadenceExecutionKit: () -> Void
    let copyLatestNextMoveCadenceExecutionKit: () -> Void
    let runFameCadenceMomentumBrief: () -> Void
    let runFameCadenceAutopilotLoop: () -> Void
    let runFameDailyScorecard: () -> Void
    let runFameRecoverySprint: () -> Void
    let runFameRiskTimeline: () -> Void
    let runFameOperatorDashboard: () -> Void
    let openLatestRecoverySprint: () -> Void
    let openLatestDailyScorecard: () -> Void
    let openLatestOperatorDashboard: () -> Void

    @State private var question = ""
    @State private var glow = false
    @State private var famePulseWidget = FamePulseWidgetState.unknown
    @State private var fameDailyScorecard = FameDailyScorecardState.unknown
    @State private var cadenceExecutionKitMomentum = (current: 0, best: 0)
    @State private var statusPillRefreshNonce = 0

    private var hasSelectedText: Bool {
        !state.lastText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasAnswer: Bool {
        !state.answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasContent: Bool {
        hasSelectedText || hasAnswer || selectedImage != nil
    }

    private var hasResult: Bool {
        hasSelectedText || hasAnswer
    }

    private var hasError: Bool {
        !state.errorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.86)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                header
                fameAutoOpsBundleStatusPill
                fameLaunchRescueAutoStatusPill
                readerStatusShortcutLegend
                cadenceExecutionKitMomentumPanel
                famePulsePanel
                fameDailyScorecardPanel

                editor(
                    title: "Selected text",
                    text: $state.lastText,
                    minHeight: 170
                )
                .shadow(color: glow ? Color.cyan.opacity(0.35) : .clear, radius: glow ? 18 : 0)

                if let image = selectedImage {
                    imagePanel(image)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button {
                            readText(state.lastText)
                        } label: {
                            Label("Read", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!hasSelectedText)

                        Button {
                            copyText(state.lastText, "Copied text.")
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .disabled(!hasSelectedText)

                        Button {
                            copyQuote(state.lastText, message: "Copied quote.")
                        } label: {
                            Label("Quote", systemImage: "text.quote")
                        }
                        .disabled(!hasSelectedText)

                        Button {
                            saveSnippet(state.lastText)
                        } label: {
                            Label("Snippet", systemImage: "bookmark")
                        }
                        .disabled(!hasSelectedText)

                        Button {
                            saveText(state.lastText, "Save Text", state.lastText)
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .disabled(!hasSelectedText)

                        Button {
                            stop()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                    }
                }

                if settings.llmEnabled {
                    llmPanel
                } else {
                    offlinePanel
                }

                if !state.recentItems.isEmpty {
                    recentPanel
                }

                if !state.snippets.isEmpty {
                    snippetsPanel
                }

                if hasError {
                    HStack(alignment: .top, spacing: 8) {
                        Label(state.errorText, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        Button {
                            copyText(state.errorText, "Copied error.")
                        } label: {
                            Label("Copy Error", systemImage: "doc.on.doc")
                        }
                        .controlSize(.small)
                    }
                }
            }
            .padding(18)
        }
        .frame(minWidth: 460, minHeight: 440)
        .animation(.easeInOut(duration: 0.18), value: state.isWorking)
        .animation(.easeInOut(duration: 0.18), value: settings.llmEnabled)
        .onAppear {
            refreshCadenceExecutionKitMomentum()
            refreshFamePulseWidget()
            refreshFameDailyScorecard()
        }
        .onChange(of: state.pulseID) { _, _ in
            refreshCadenceExecutionKitMomentum()
            refreshFamePulseWidget()
            refreshFameDailyScorecard()
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

            Button {
                settings.readerAlwaysOnTop.toggle()
            } label: {
                Image(systemName: settings.readerAlwaysOnTop ? "pin.fill" : "pin")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help(settings.readerAlwaysOnTop ? "Unpin Reader" : "Pin Reader")
            .accessibilityLabel(settings.readerAlwaysOnTop ? "Unpin Reader" : "Pin Reader")

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

    private var fameAutoOpsBundleStatusPill: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let status = fameAutoOpsBundleStatus()
            let title = fameAutoOpsBundleStatusTitle()
            let subtitle = fameAutoOpsBundleStatusSubtitle()
            let tone = AppDelegate.autoOpsBundleReaderStatusTone(status)
            let tint = readerStatusToneTint(tone)
            let accessibilityHint = AppDelegate.readerStatusPillAccessibilityHint(
                subtitle,
                actionHint: AppDelegate.readerStatusPillActionHint(
                    shortcutDisplay: "Option-Command-O"
                )
            )
            let helpText = AppDelegate.readerStatusPillHelpText(
                subtitle,
                shortcutDisplay: "⌥⌘O"
            )

            Button {
                runFameAutoOpsBundleStatusAction()
                refreshStatusPillsAfterTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: AppDelegate.autoOpsBundleStatusActionSystemImage(status))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(AppDelegate.autoOpsBundleEscalationStatusPhrase(status))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.14))
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .help(helpText)
            .accessibilityLabel(title)
            .accessibilityValue(AppDelegate.autoOpsBundleEscalationStatusPhrase(status))
            .accessibilityHint(accessibilityHint)
            .keyboardShortcut("o", modifiers: [.command, .option])
        }
        .id(statusPillRefreshNonce)
    }

    private var fameLaunchRescueAutoStatusPill: some View {
        TimelineView(.periodic(from: .now, by: 30)) { _ in
            let status = fameLaunchRescueAutoStatus()
            let title = fameLaunchRescueAutoStatusTitle()
            let subtitle = fameLaunchRescueAutoStatusSubtitle()
            let tone = AppDelegate.launchRescueAutoReaderStatusTone(
                status,
                title: title,
                subtitle: subtitle
            )
            let tint = readerStatusToneTint(tone)
            let accessibilityHint = AppDelegate.readerStatusPillAccessibilityHint(
                subtitle,
                actionHint: AppDelegate.readerStatusPillActionHint(
                    shortcutDisplay: "Option-Command-L"
                )
            )
            let helpText = AppDelegate.readerStatusPillHelpText(
                subtitle,
                shortcutDisplay: "⌥⌘L"
            )

            Button {
                runFameLaunchRescueAutoStatusAction()
                refreshStatusPillsAfterTap()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: AppDelegate.launchRescueBurstAutoStatusActionSystemImage(status))
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(AppDelegate.launchRescueBurstAutoStatusPhrase(status))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.14))
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .help(helpText)
            .accessibilityLabel(title)
            .accessibilityValue(AppDelegate.launchRescueBurstAutoStatusPhrase(status))
            .accessibilityHint(accessibilityHint)
            .keyboardShortcut("l", modifiers: [.command, .option])
        }
        .id(statusPillRefreshNonce)
    }

    private var readerStatusShortcutLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                shortcutLegendChip(
                    shortcutTitle: "⌥⌘O",
                    actionTitle: "Auto Bundle"
                )
                shortcutLegendChip(
                    shortcutTitle: "⌥⌘L",
                    actionTitle: "Rescue Auto"
                )
            }
            .padding(.horizontal, 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reader status shortcuts")
        .accessibilityValue(AppDelegate.readerStatusShortcutLegendAccessibilityValue())
    }

    private func shortcutLegendChip(
        shortcutTitle: String,
        actionTitle: String
    ) -> some View {
        HStack(spacing: 6) {
            Text(shortcutTitle)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            Text(actionTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func readerStatusToneTint(
        _ tone: AppDelegate.ReaderStatusTone
    ) -> Color {
        switch tone {
        case .neutral:
            return .secondary
        case .success:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        }
    }

    private var famePulsePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: famePulseWidget.symbolName)
                    .foregroundStyle(famePulseTint)
                Text(famePulseWidget.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(famePulseWidget.riskLevel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(famePulseTint.opacity(0.14))
                    .clipShape(Capsule(style: .continuous))
            }

            Text(famePulseWidget.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        runFameRecoverySprint()
                    } label: {
                        Label("Recovery Sprint", systemImage: "flame.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        runFameRiskTimeline()
                    } label: {
                        Label("Risk Timeline", systemImage: "waveform.path.ecg")
                    }
                    .controlSize(.small)

                    Button {
                        openLatestRecoverySprint()
                    } label: {
                        Label("Open Latest", systemImage: "clock.arrow.circlepath")
                    }
                    .controlSize(.small)

                    Button {
                        runFameOperatorDashboard()
                    } label: {
                        Label("Operator Dash", systemImage: "gauge.open.with.lines.needle.33percent")
                    }
                    .controlSize(.small)

                    Button {
                        openLatestOperatorDashboard()
                    } label: {
                        Label("Open Ops", systemImage: "chart.bar.doc.horizontal")
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(famePulseTint.opacity(0.35), lineWidth: 1)
        )
    }

    private var famePulseTint: Color {
        switch famePulseWidget.riskLevel {
        case "Critical":
            return .red
        case "High":
            return .orange
        case "Medium":
            return .yellow
        case "Low":
            return .green
        default:
            return .blue
        }
    }

    private func refreshFamePulseWidget() {
        famePulseWidget = famePulseState()
    }

    private var cadenceExecutionKitMomentumPanel: some View {
        let currentStreak = max(0, cadenceExecutionKitMomentum.current)
        let bestStreak = max(currentStreak, max(0, cadenceExecutionKitMomentum.best))
        let menuTitle = AppDelegate.cadenceExecutionKitCommandMenuMomentumTitle(
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )
        let statusTitle = AppDelegate.cadenceExecutionKitCommandStreakStatusTitle(
            currentStreak: currentStreak,
            bestStreak: bestStreak
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(
                    systemName: AppDelegate.cadenceExecutionKitCommandMomentumSymbolName(
                        currentStreak: currentStreak,
                        bestStreak: bestStreak
                    )
                )
                .foregroundStyle(cadenceExecutionKitMomentumTint)
                Text("Cadence Momentum")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(
                    AppDelegate.cadenceExecutionKitCommandMomentumBadgeTitle(
                        currentStreak: currentStreak,
                        bestStreak: bestStreak
                    )
                )
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(cadenceExecutionKitMomentumTint.opacity(0.14))
                .clipShape(Capsule(style: .continuous))
            }

            Text(menuTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(statusTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        runFameCadenceAutopilotLoop()
                    } label: {
                        Label("Autopilot", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button {
                        runFameNextMoveCadenceExecutionKit()
                    } label: {
                        Label("Run Kit", systemImage: "bolt.fill")
                    }
                    .controlSize(.small)

                    Button {
                        copyLatestNextMoveCadenceExecutionKit()
                    } label: {
                        Label("Copy Kit", systemImage: "doc.on.doc")
                    }
                    .controlSize(.small)

                    Button {
                        runFameCadenceMomentumBrief()
                    } label: {
                        Label("Momentum Brief", systemImage: "list.bullet.rectangle.portrait")
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(cadenceExecutionKitMomentumTint.opacity(0.35), lineWidth: 1)
        )
    }

    private var cadenceExecutionKitMomentumTint: Color {
        let currentStreak = max(0, cadenceExecutionKitMomentum.current)
        if currentStreak >= 10 {
            return .purple
        }
        if currentStreak >= 5 {
            return .orange
        }
        if currentStreak > 0 {
            return .green
        }
        if max(0, cadenceExecutionKitMomentum.best) > 0 {
            return .yellow
        }
        return .secondary
    }

    private func refreshCadenceExecutionKitMomentum() {
        cadenceExecutionKitMomentum = cadenceExecutionKitMomentumSnapshot()
    }

    private func refreshStatusPillsAfterTap() {
        statusPillRefreshNonce &+= 1
        refreshCadenceExecutionKitMomentum()
        refreshFamePulseWidget()
        refreshFameDailyScorecard()
    }

    private var fameDailyScorecardPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: fameDailyScorecardSymbolName)
                    .foregroundStyle(fameDailyScorecardTint)
                Text(fameDailyScorecard.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(fameDailyScorecard.riskLevel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(fameDailyScorecardTint.opacity(0.14))
                    .clipShape(Capsule(style: .continuous))
            }

            Text(fameDailyScorecard.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(fameDailyScorecard.recommendation)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Next: \(fameDailyScorecard.nextActionTitle) — \(fameDailyScorecard.nextActionSummary)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        runFameDailyScorecard()
                    } label: {
                        Label("Run Scorecard", systemImage: "calendar.badge.clock")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    if fameDailyScorecard.recommendsRecovery {
                        Button {
                            runFameRecoverySprint()
                        } label: {
                            Label("Recovery Sprint", systemImage: "flame.fill")
                        }
                        .controlSize(.small)
                    }

                    Button {
                        openLatestDailyScorecard()
                    } label: {
                        Label("Open Latest", systemImage: "clock.arrow.circlepath")
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(fameDailyScorecardTint.opacity(0.35), lineWidth: 1)
        )
    }

    private var fameDailyScorecardTint: Color {
        switch fameDailyScorecard.riskLevel {
        case "High":
            return .orange
        case "Medium":
            return .yellow
        case "Low":
            return .green
        default:
            return .blue
        }
    }

    private var fameDailyScorecardSymbolName: String {
        switch fameDailyScorecard.riskLevel {
        case "High":
            return "exclamationmark.triangle.fill"
        case "Medium":
            return "exclamationmark.circle"
        case "Low":
            return "checkmark.circle.fill"
        default:
            return "questionmark.circle"
        }
    }

    private func refreshFameDailyScorecard() {
        fameDailyScorecard = fameDailyScorecardState()
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

            quickPromptRow

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button {
                        readText(state.answerText)
                    } label: {
                        Label("Read Answer", systemImage: "speaker.wave.2.fill")
                    }
                    .disabled(!hasAnswer)

                    Button {
                        copyText(state.answerText, "Copied answer.")
                    } label: {
                        Label("Copy Answer", systemImage: "doc.on.clipboard")
                    }
                    .disabled(!hasAnswer)

                    Button {
                        copyQuote(state.answerText, message: "Copied answer quote.")
                    } label: {
                        Label("Quote Answer", systemImage: "text.quote")
                    }
                    .disabled(!hasAnswer)

                    Button {
                        saveSnippet(state.answerText)
                    } label: {
                        Label("Snippet Answer", systemImage: "bookmark")
                    }
                    .disabled(!hasAnswer)

                    Button {
                        saveText(state.answerText, "Save Answer", state.answerText)
                    } label: {
                        Label("Save Answer", systemImage: "square.and.arrow.down")
                    }
                    .disabled(!hasAnswer)

                    Button {
                        copyResult()
                    } label: {
                        Label("Copy Result", systemImage: "doc.on.doc.fill")
                    }
                    .disabled(!hasResult)

                    Button {
                        saveResult()
                    } label: {
                        Label("Save Result", systemImage: "doc.richtext")
                    }
                    .disabled(!hasResult)
                }
            }

            editor(title: "Answer", text: $state.answerText, minHeight: 130)
        }
    }

    private var quickPromptRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PromptTemplate.all(customPrompts: settings.customPromptInputs)) { template in
                    promptButton(template.title, systemImage: template.systemImage) {
                        askLLM(template.prompt)
                    }
                }
            }
        }
        .disabled(!hasContent)
    }

    private func promptButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
        }
        .controlSize(.small)
    }

    private func copyQuote(_ text: String, message: String) {
        guard let quote = ResultExportDocument.markdownQuote(text: text) else {
            return
        }

        copyText(quote, message)
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

    private var recentPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Label("Recent", systemImage: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") {
                    state.clearHistory()
                }
                .controlSize(.small)
            }

            VStack(spacing: 4) {
                ForEach(Array(state.recentItems.prefix(4))) { item in
                    Button {
                        state.restore(item)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.answer.isEmpty ? "text.quote" : "sparkles")
                                .foregroundStyle(.secondary)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.preview)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.42))
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var snippetsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Label("Snippets", systemImage: "bookmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") {
                    state.clearSnippets()
                }
                .controlSize(.small)
            }

            VStack(spacing: 4) {
                ForEach(Array(state.snippets.prefix(4))) { item in
                    HStack(spacing: 6) {
                        Button {
                            copyText(item.text, "Copied snippet.")
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 18)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.preview)
                                        .font(.caption)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    Text(item.isPinned ? "Pinned" : "Saved")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            state.useSnippet(item)
                        } label: {
                            Image(systemName: "arrow.down.doc")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .help("Use Snippet in Reader")

                        Button {
                            state.deleteSnippet(item)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                        .help("Delete Snippet")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.42))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
            }
        }
    }

    private var selectedImage: NSImage? {
        guard let data = state.lastImageData else { return nil }
        return NSImage(data: data)
    }

    private func imagePanel(_ image: NSImage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 120)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18))
                )

            HStack(spacing: 8) {
                Button {
                    copyImage()
                } label: {
                    Label("Copy Image", systemImage: "photo.on.rectangle")
                }

                Button {
                    saveImage()
                } label: {
                    Label("Save Image", systemImage: "square.and.arrow.down")
                }

                Spacer()
            }
            .controlSize(.small)
        }
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
