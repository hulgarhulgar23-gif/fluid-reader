import AppKit
import SwiftUI

@MainActor
final class SetupChecklistWindow {
    private static let preferredContentSize = NSSize(width: 560, height: 460)

    private let session = SetupSession()
    private let report: () -> SetupChecklistReport
    private let handleAction: (SetupChecklistAction) -> Void
    private var window: NSPanel!

    init(
        report: @escaping () -> SetupChecklistReport,
        handleAction: @escaping (SetupChecklistAction) -> Void
    ) {
        self.report = report
        self.handleAction = handleAction

        window = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Setup Checklist"
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
            rootView: SetupChecklistView(
                session: session,
                report: report,
                handleAction: handleAction,
                close: { [weak self] in self?.hide() }
            )
        )
    }

    func show() {
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

typealias SetupChecklistWindowController = SetupChecklistWindow

private final class SetupSession: ObservableObject {
    @Published private(set) var openCount = 0

    func beginOpen() {
        openCount += 1
    }
}

private struct SetupChecklistView: View {
    @ObservedObject var session: SetupSession
    let report: () -> SetupChecklistReport
    let handleAction: (SetupChecklistAction) -> Void
    let close: () -> Void

    @State private var currentReport: SetupChecklistReport

    init(
        session: SetupSession,
        report: @escaping () -> SetupChecklistReport,
        handleAction: @escaping (SetupChecklistAction) -> Void,
        close: @escaping () -> Void
    ) {
        self.session = session
        self.report = report
        self.handleAction = handleAction
        self.close = close
        _currentReport = State(initialValue: report())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Label("Setup Checklist", systemImage: "checklist.checked")
                    .font(.title3.weight(.semibold))

                Spacer()

                Button {
                    refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }

            Text(currentReport.summary)
                .font(.callout)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(currentReport.focusedItems) { item in
                    row(item)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    close()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(18)
        .frame(minWidth: 520, minHeight: 420)
        .background(.regularMaterial)
        .onAppear(perform: refresh)
        .onChange(of: session.openCount) { _, _ in
            refresh()
        }
        .onExitCommand(perform: close)
    }

    private func row(_ item: SetupChecklistItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.state.systemImage)
                .font(.title3)
                .foregroundStyle(color(for: item.state))
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.callout.weight(.semibold))
                    Text(item.state.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(color(for: item.state))
                }

                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if let action = item.action, let actionTitle = item.actionTitle {
                Button(actionTitle) {
                    handleAction(action)
                    refresh()
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func refresh() {
        currentReport = report()
    }

    private func color(for state: SetupChecklistItemState) -> Color {
        switch state {
        case .ready:
            return .green
        case .actionNeeded:
            return .orange
        case .optional:
            return .secondary
        }
    }
}
