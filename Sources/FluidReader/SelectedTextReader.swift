import AppKit
import Carbon.HIToolbox

@MainActor
enum SelectedTextReader {
    static func readSelectedText(timeoutNanoseconds: UInt64 = 280_000_000) async -> String? {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        let oldChangeCount = pasteboard.changeCount

        postCopyShortcut()

        let step: UInt64 = 25_000_000
        var waited: UInt64 = 0
        var selectedText: String?

        while waited < timeoutNanoseconds {
            if pasteboard.changeCount != oldChangeCount,
               let text = pasteboard.string(forType: .string)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !text.isEmpty {
                selectedText = text
                break
            }

            try? await Task.sleep(nanoseconds: step)
            waited += step
        }

        snapshot.restore(to: pasteboard)
        return selectedText
    }

    private static func postCopyShortcut() {
        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_C),
                keyDown: true
              ),
              let keyUp = CGEvent(
                keyboardEventSource: source,
                virtualKey: CGKeyCode(kVK_ANSI_C),
                keyDown: false
              )
        else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
