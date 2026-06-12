import AppKit
import SwiftUI

@MainActor
final class RewardHUDController {
    private static let minContentSize = NSSize(width: 160, height: 54)
    private static let maxContentSize = NSSize(width: 340, height: 96)

    enum Mood {
        case success
        case working
        case error
    }

    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    func show(_ title: String, mood: Mood, intensity: Double = 0.84) {
        hideTask?.cancel()

        let view = RewardHUDView(title: title, mood: mood, intensity: intensity)
        let hosting = NSHostingController(rootView: view)
        let size = WindowBounds.clampedSize(
            hosting.view.fittingSize,
            minimum: Self.minContentSize,
            maximum: Self.maxContentSize
        )
        hosting.view.frame = CGRect(origin: .zero, size: size)
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = CGPoint(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 72
        )

        if panel == nil {
            let panel = NSPanel(
                contentRect: CGRect(origin: origin, size: size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.animationBehavior = .none
            panel.isReleasedWhenClosed = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            panel.ignoresMouseEvents = true
            panel.contentMinSize = Self.minContentSize
            panel.contentMaxSize = Self.maxContentSize
            self.panel = panel
        }

        guard let panel else { return }
        panel.contentViewController = hosting
        panel.setFrame(CGRect(origin: origin, size: size), display: true)
        WindowBounds.clampOrigin(toVisibleScreen: panel)
        panel.alphaValue = 1
        panel.orderFrontRegardless()

        let holdSeconds: TimeInterval = switch mood {
        case .success:
            1.35
        case .working:
            1.00
        case .error:
            1.10
        }

        hideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(holdSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.hide()
            }
        }
    }

    func hide() {
        guard let panel else { return }
        panel.alphaValue = 0
        panel.orderOut(nil)
    }
}

private struct RewardHUDView: View {
    let title: String
    let mood: RewardHUDController.Mood
    let intensity: Double

    @State private var pop = false

    private var tint: Color {
        switch mood {
        case .success:
            return .cyan
        case .working:
            return .yellow
        case .error:
            return .red
        }
    }

    private var iconName: String {
        switch mood {
        case .success:
            return "sparkles"
        case .working:
            return "waveform"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        ZStack {
            hudContent

            if mood == .success {
                successBurst
            }
        }
        .padding(20)
        .onAppear {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.52)) {
                pop = true
            }
        }
    }

    private var hudContent: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 32, height: 32)
                    .scaleEffect(pop ? 1.18 : 0.86)
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .scaleEffect(pop ? 1.0 : 0.82)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            if mood == .working || mood == .success {
                slotReels
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial)
        .clipShape(Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.22 + intensity * 0.12), radius: pop ? 14 + intensity * 8 : 6, y: 5)
    }

    private var slotReels: some View {
        let finalSymbols = ["scope", "waveform", "sparkles"]
        let rollingSymbols = ["sparkles", "scope", "waveform", "text.viewfinder", "speaker.wave.2.fill"]

        return TimelineView(.animation(minimumInterval: 1.0 / 18.0)) { timeline in
            let tick = Int(timeline.date.timeIntervalSinceReferenceDate * 18)

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    let symbol = mood == .working
                        ? rollingSymbols[(tick + index * 2) % rollingSymbols.count]
                        : finalSymbols[index]

                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(tint.opacity(0.14 + intensity * 0.12))
                            .frame(width: 25, height: 25)

                        Image(systemName: symbol)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(tint)
                            .offset(y: reelOffset(index: index, tick: tick))
                            .opacity(pop ? 1 : 0.12)
                    }
                    .scaleEffect(reelScale(index: index, tick: tick))
                    .rotation3DEffect(
                        .degrees(mood == .success && !pop ? 58 : 0),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .animation(
                        .spring(response: 0.24 + Double(index) * 0.03, dampingFraction: 0.52)
                            .delay(Double(index) * 0.045),
                        value: pop
                    )
                }
            }
            .padding(.leading, 2)
        }
    }

    private func reelOffset(index: Int, tick: Int) -> CGFloat {
        if mood == .success {
            return pop ? 0 : -18
        }

        let phase = Double((tick + index * 3) % 6) / 6.0
        return CGFloat(sin(phase * .pi * 2.0) * 3.0)
    }

    private func reelScale(index: Int, tick: Int) -> CGFloat {
        if mood == .success {
            return pop ? 1.0 : 0.74
        }

        let phase = Double((tick + index * 2) % 8) / 8.0
        return 0.92 + CGFloat((sin(phase * .pi * 2.0) + 1.0) * 0.04)
    }

    private var successBurst: some View {
        let offsets: [CGSize] = [
            CGSize(width: -66, height: -18),
            CGSize(width: -50, height: 20),
            CGSize(width: -18, height: -34),
            CGSize(width: 8, height: 34),
            CGSize(width: 36, height: -28),
            CGSize(width: 62, height: -6),
            CGSize(width: 48, height: 24),
            CGSize(width: -4, height: -42)
        ]

        return ZStack {
            ForEach(offsets.indices, id: \.self) { index in
                Circle()
                    .fill(tint.opacity(pop ? 0.0 : 0.92))
                    .frame(width: 4 + intensity * 4, height: 4 + intensity * 4)
                    .scaleEffect(pop ? 0.15 : 1.0)
                    .offset(
                        x: pop ? offsets[index].width : 0,
                        y: pop ? offsets[index].height : 0
                    )
                    .animation(
                        .easeOut(duration: 0.42 + Double(index % 3) * 0.04)
                            .delay(Double(index) * 0.025),
                        value: pop
                    )
            }
        }
        .allowsHitTesting(false)
    }
}
