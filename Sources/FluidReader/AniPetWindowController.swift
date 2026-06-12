import AppKit
import SwiftUI

@MainActor
final class AniPetWindowController {
    private static let preferredContentSize = NSSize(width: 286, height: 142)

    private let panel: NSPanel

    init(
        state: ReaderState,
        openReader: @escaping () -> Void
    ) {
        let view = AniPetView(state: state, openReader: openReader)
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = NSHostingController(rootView: view)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .none
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        WindowBounds.reset(
            panel,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.preferredContentSize,
            maxContentSize: Self.preferredContentSize
        )
    }

    func show() {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        WindowBounds.reset(
            panel,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.preferredContentSize,
            maxContentSize: Self.preferredContentSize
        )
        placeIfNeeded()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func placeIfNeeded() {
        guard let screen = NSScreen.main else { return }
        let frame = panel.frame
        let visible = screen.visibleFrame

        if visible.contains(CGPoint(x: frame.midX, y: frame.midY)) {
            return
        }

        let origin = CGPoint(
            x: visible.maxX - frame.width - 22,
            y: visible.minY + 28
        )
        panel.setFrameOrigin(origin)
    }
}

private struct AniPetView: View {
    @ObservedObject var state: ReaderState
    let openReader: () -> Void

    var body: some View {
        Button(action: openReader) {
            HStack(spacing: 10) {
                bubble
                face
            }
            .padding(10)
            .frame(width: 286, height: 142)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ani pet")
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Circle()
                    .fill(moodColor)
                    .frame(width: 7, height: 7)
                Text("Ani")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(state.petMessage)
                .font(.callout.weight(.medium))
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            if state.petMood == .working {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var face: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.42, green: 0.90, blue: 1.0),
                            Color(red: 1.0, green: 0.60, blue: 0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.70), lineWidth: 2))

            HStack(spacing: 13) {
                eye
                eye
            }
            .offset(y: -5)

            Capsule()
                .fill(Color.black.opacity(0.72))
                .frame(width: 18, height: state.petMood == .happy ? 8 : 5)
                .offset(y: 15)

            HStack(spacing: 28) {
                Circle()
                    .fill(Color.white.opacity(0.34))
                    .frame(width: 9, height: 6)
                Circle()
                    .fill(Color.white.opacity(0.34))
                    .frame(width: 9, height: 6)
            }
            .offset(y: 6)

            if state.petMood == .happy {
                Image(systemName: "sparkle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
                    .offset(x: 27, y: -30)
            }
        }
        .frame(width: 78, height: 78)
        .shadow(color: moodColor.opacity(0.30), radius: 10, x: 0, y: 4)
    }

    private var eye: some View {
        Circle()
            .fill(Color.black.opacity(0.78))
            .frame(width: 8, height: 12)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.88))
                    .frame(width: 3, height: 3)
                    .offset(x: -1, y: -3)
            )
    }

    private var moodColor: Color {
        switch state.petMood {
        case .ready:
            return .cyan
        case .working:
            return .yellow
        case .happy:
            return .green
        case .error:
            return .red
        }
    }
}
