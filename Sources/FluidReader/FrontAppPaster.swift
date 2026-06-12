import AppKit
import Carbon.HIToolbox

enum FrontAppPasteResult: Equatable {
    case pasted
    case emptyText
    case noTargetApplication
    case accessibilityNotAllowed
    case eventFailed

    var isSuccess: Bool {
        self == .pasted
    }
}

enum FrontAppPaster {
    static let activationDelayNanoseconds: UInt64 = 120_000_000
    static let restoreDelayNanoseconds: UInt64 = 600_000_000

    static func clean(_ text: String?) -> String? {
        guard let text else { return nil }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanText.isEmpty ? nil : cleanText
    }

    @MainActor
    static func paste(
        _ rawText: String,
        to application: NSRunningApplication?,
        pasteboard: NSPasteboard = .general,
        accessibilityTrusted: () -> Bool = PermissionStatus.accessibilityTrusted,
        postPasteShortcut: (@MainActor () -> Bool)? = nil,
        activationDelayNanoseconds: UInt64 = FrontAppPaster.activationDelayNanoseconds,
        restoreDelayNanoseconds: UInt64 = FrontAppPaster.restoreDelayNanoseconds
    ) async -> FrontAppPasteResult {
        guard let text = clean(rawText) else { return .emptyText }
        guard accessibilityTrusted() else { return .accessibilityNotAllowed }
        guard let application, !application.isTerminated else { return .noTargetApplication }

        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            snapshot.restore(to: pasteboard)
            return .eventFailed
        }
        let pasteChangeCount = pasteboard.changeCount

        guard application.activate() else {
            snapshot.restore(to: pasteboard, ifChangeCountEquals: pasteChangeCount)
            return .eventFailed
        }

        try? await Task.sleep(nanoseconds: activationDelayNanoseconds)

        let postPasteShortcut = postPasteShortcut ?? FrontAppPaster.postPasteShortcut
        guard postPasteShortcut() else {
            snapshot.restore(to: pasteboard, ifChangeCountEquals: pasteChangeCount)
            return .eventFailed
        }

        try? await Task.sleep(nanoseconds: restoreDelayNanoseconds)
        // Skip the restore if anything else wrote to the pasteboard while we
        // waited, so the user's newer clipboard content is not clobbered.
        snapshot.restore(to: pasteboard, ifChangeCountEquals: pasteChangeCount)
        return .pasted
    }

    @MainActor
    private static func postPasteShortcut() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: true
              ),
              let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_V),
                keyDown: false
              )
        else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}
