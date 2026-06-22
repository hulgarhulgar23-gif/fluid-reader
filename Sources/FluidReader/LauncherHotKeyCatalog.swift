import Carbon.HIToolbox
import Foundation

struct LauncherHotKeyDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let defaultShortcut: CommandHotKeyShortcut

    var defaultShortcutDisplayText: String {
        defaultShortcut.displayText
    }

    func resolvedShortcut(using store: CommandHotKeyStore) -> CommandHotKeyShortcut {
        store.parsedShortcut(for: id) ?? defaultShortcut
    }

    func validationMessage(using store: CommandHotKeyStore) -> String {
        let rawText = store.shortcutText(for: id).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawText.isEmpty else {
            return "Default hotkey: \(defaultShortcut.displayText)"
        }
        if let shortcut = store.parsedShortcut(for: id) {
            if let conflictTitle = store.conflictingActionTitle(for: id) {
                return "Conflicts with \(conflictTitle): \(shortcut.displayText)."
            }
            return "Global hotkey ready: \(shortcut.displayText)"
        }
        return "Use a modifier plus key, like ⌥⌘P or cmd+shift+p. Default stays \(defaultShortcut.displayText)."
    }
}

enum LauncherHotKeyCatalog {
    static let commands = LauncherHotKeyDefinition(
        id: "launcher-shortcut-commands",
        title: "Commands",
        subtitle: "Show the unified launcher from anywhere",
        defaultShortcut: CommandHotKeyShortcut(
            keyCode: kVK_Space,
            modifiers: UInt32(optionKey | shiftKey),
            displayText: "⌥⇧Space"
        )
    )

    static let pickAndRead = LauncherHotKeyDefinition(
        id: "pick-and-read",
        title: "Pick and Read",
        subtitle: "Start the OCR lasso immediately",
        defaultShortcut: CommandHotKeyShortcut(
            keyCode: kVK_ANSI_R,
            modifiers: UInt32(optionKey | shiftKey),
            displayText: "⌥⇧R"
        )
    )

    static let screenshot = LauncherHotKeyDefinition(
        id: "screenshot-line",
        title: "Screenshot",
        subtitle: "Capture the highlighted screenshot line immediately",
        defaultShortcut: CommandHotKeyShortcut(
            keyCode: kVK_ANSI_S,
            modifiers: UInt32(optionKey | shiftKey),
            displayText: "⌥⇧S"
        )
    )

    static let all = [commands, pickAndRead, screenshot]

    static func definition(for actionID: String) -> LauncherHotKeyDefinition? {
        all.first { $0.id == actionID }
    }

    static func title(for actionID: String) -> String? {
        definition(for: actionID)?.title
    }
}
