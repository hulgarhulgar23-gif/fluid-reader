import AppKit
import CoreGraphics

struct SelectedImage {
    let cgImage: CGImage
    let pngData: Data?
}

@MainActor
final class SelectionController {
    private var windows: [NSWindow] = []
    private var completion: ((SelectedImage) -> Void)?
    private var onCancelEffect: (() -> Void)?

    func start(
        onDrawStart: @escaping () -> Void,
        onCommit: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        completion: @escaping (SelectedImage) -> Void
    ) {
        guard windows.isEmpty else { return }
        self.completion = completion
        onCancelEffect = onCancel

        guard screenCaptureAllowed() else {
            CGRequestScreenCaptureAccess()
            showScreenAccessAlert()
            self.completion = nil
            onCancelEffect = nil
            return
        }

        let captures = NSScreen.screens.compactMap { screen -> (NSScreen, CGImage)? in
            guard let displayID = screen.displayID,
                  let image = CGDisplayCreateImage(displayID)
            else {
                return nil
            }
            return (screen, image)
        }

        guard !captures.isEmpty else {
            showScreenAccessAlert()
            self.completion = nil
            onCancelEffect = nil
            return
        }

        for (screen, image) in captures {
            let view = SelectionOverlayView(
                screenImage: image,
                onDrawStart: onDrawStart,
                onCommit: onCommit,
                onFinish: { [weak self] result in
                    self?.finish(result)
                },
                onCancel: { [weak self] in
                    self?.cancel()
                }
            )

            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )
            window.contentView = view
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
            window.makeKeyAndOrderFront(nil)
            window.alphaValue = 0
            window.makeFirstResponder(view)
            windows.append(window)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.10
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().alphaValue = 1
            }
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func finish(_ result: SelectionOverlayResult) {
        let selected = SelectedImage(cgImage: result.image, pngData: result.pngData)
        let selectedCompletion = completion
        self.completion = nil
        onCancelEffect = nil

        closeWindows(animated: true) {
            selectedCompletion?(selected)
        }
    }

    private func cancel() {
        onCancelEffect?()
        completion = nil
        onCancelEffect = nil
        closeWindows(animated: true)
    }

    private func closeWindows(animated: Bool, completion: (() -> Void)? = nil) {
        let closingWindows = windows
        windows.removeAll()

        guard animated, !closingWindows.isEmpty else {
            closingWindows.forEach { $0.close() }
            completion?()
            return
        }

        closingWindows.forEach { $0.ignoresMouseEvents = true }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.08
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            closingWindows.forEach { $0.animator().alphaValue = 0 }
        } completionHandler: {
            closingWindows.forEach { $0.close() }
            completion?()
        }
    }

    private func screenCaptureAllowed() -> Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        }
        return true
    }

    private func showScreenAccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Allow Screen Recording."
        alert.informativeText = "Fluid Reader needs this to read the area you pick. After you allow it, choose Pick and Read again."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Not Now")

        if alert.runModal() == .alertFirstButtonReturn,
           let url = AppDefaults.screenRecordingSettingsURL {
            NSWorkspace.shared.open(url)
        }
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber).map { CGDirectDisplayID($0.uint32Value) }
    }
}
