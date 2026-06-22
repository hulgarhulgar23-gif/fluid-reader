import Carbon.HIToolbox
import Foundation

struct CommandHotKeyShortcut: Equatable {
    let keyCode: Int
    let modifiers: UInt32
    let displayText: String

    var comparisonKey: String {
        "\(modifiers):\(keyCode)"
    }

    static func parse(_ rawValue: String) -> CommandHotKeyShortcut? {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        var modifiers: UInt32 = 0
        var remainder = trimmedValue

        let symbolModifiers: [(Character, UInt32)] = [
            ("⌃", UInt32(controlKey)),
            ("⌥", UInt32(optionKey)),
            ("⇧", UInt32(shiftKey)),
            ("⌘", UInt32(cmdKey))
        ]
        for (symbol, flag) in symbolModifiers {
            if remainder.contains(symbol) {
                modifiers |= flag
                remainder.removeAll { $0 == symbol }
            }
        }

        let tokens = remainder
            .lowercased()
            .split { $0 == "+" || $0 == "," || $0.isWhitespace }
            .map(String.init)

        var keyToken: String?
        for token in tokens {
            switch token {
            case "cmd", "command", "⌘":
                modifiers |= UInt32(cmdKey)
            case "shift", "⇧":
                modifiers |= UInt32(shiftKey)
            case "opt", "option", "alt", "⌥":
                modifiers |= UInt32(optionKey)
            case "ctrl", "control", "ctl", "⌃":
                modifiers |= UInt32(controlKey)
            default:
                guard keyToken == nil else { return nil }
                keyToken = token
            }
        }

        let compactRemainder = remainder
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: "")
        if keyToken == nil, !compactRemainder.isEmpty {
            keyToken = compactRemainder.lowercased()
        }

        guard modifiers != 0,
              let keyToken,
              let keyCode = keyCode(for: keyToken),
              let keyDisplay = keyDisplay(for: keyToken) else {
            return nil
        }

        let displayText = displayText(modifiers: modifiers, keyDisplay: keyDisplay)
        return CommandHotKeyShortcut(
            keyCode: keyCode,
            modifiers: modifiers,
            displayText: displayText
        )
    }

    private static func displayText(modifiers: UInt32, keyDisplay: String) -> String {
        var pieces: [String] = []
        if modifiers & UInt32(controlKey) != 0 {
            pieces.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            pieces.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            pieces.append("⇧")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            pieces.append("⌘")
        }
        pieces.append(keyDisplay)
        return pieces.joined()
    }

    private static func keyDisplay(for keyToken: String) -> String? {
        switch keyToken {
        case "space", "spacebar":
            return "Space"
        case "return", "enter":
            return "Return"
        case "tab":
            return "Tab"
        case "esc", "escape":
            return "Esc"
        case "left":
            return "←"
        case "right":
            return "→"
        case "up":
            return "↑"
        case "down":
            return "↓"
        default:
            guard keyToken.count == 1 else { return nil }
            return keyToken.uppercased()
        }
    }

    private static func keyCode(for keyToken: String) -> Int? {
        switch keyToken {
        case "a": return kVK_ANSI_A
        case "b": return kVK_ANSI_B
        case "c": return kVK_ANSI_C
        case "d": return kVK_ANSI_D
        case "e": return kVK_ANSI_E
        case "f": return kVK_ANSI_F
        case "g": return kVK_ANSI_G
        case "h": return kVK_ANSI_H
        case "i": return kVK_ANSI_I
        case "j": return kVK_ANSI_J
        case "k": return kVK_ANSI_K
        case "l": return kVK_ANSI_L
        case "m": return kVK_ANSI_M
        case "n": return kVK_ANSI_N
        case "o": return kVK_ANSI_O
        case "p": return kVK_ANSI_P
        case "q": return kVK_ANSI_Q
        case "r": return kVK_ANSI_R
        case "s": return kVK_ANSI_S
        case "t": return kVK_ANSI_T
        case "u": return kVK_ANSI_U
        case "v": return kVK_ANSI_V
        case "w": return kVK_ANSI_W
        case "x": return kVK_ANSI_X
        case "y": return kVK_ANSI_Y
        case "z": return kVK_ANSI_Z
        case "0": return kVK_ANSI_0
        case "1": return kVK_ANSI_1
        case "2": return kVK_ANSI_2
        case "3": return kVK_ANSI_3
        case "4": return kVK_ANSI_4
        case "5": return kVK_ANSI_5
        case "6": return kVK_ANSI_6
        case "7": return kVK_ANSI_7
        case "8": return kVK_ANSI_8
        case "9": return kVK_ANSI_9
        case "space", "spacebar": return kVK_Space
        case "return", "enter": return kVK_Return
        case "tab": return kVK_Tab
        case "esc", "escape": return kVK_Escape
        case "left": return kVK_LeftArrow
        case "right": return kVK_RightArrow
        case "up": return kVK_UpArrow
        case "down": return kVK_DownArrow
        default: return nil
        }
    }
}

final class CommandHotKeyStore: ObservableObject {
    private struct EffectiveBinding {
        let actionID: String
        let title: String
        let shortcut: CommandHotKeyShortcut
    }

    private static let defaultKey = "commandHotKeyEntries"
    private static let maxActionIDLength = 120
    private static let maxTextLength = 40

    private let defaults: UserDefaults
    private let key: String
    @Published private(set) var shortcutTextByActionID: [String: String]

    init(
        defaults: UserDefaults = .standard,
        key: String = CommandHotKeyStore.defaultKey
    ) {
        self.defaults = defaults
        self.key = key
        shortcutTextByActionID = Self.loadEntries(from: defaults, key: key)
    }

    var assignedActionIDs: [String] {
        shortcutTextByActionID.keys.sorted()
    }

    func shortcutText(for actionID: String) -> String {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else { return "" }
        return shortcutTextByActionID[sanitizedActionID] ?? ""
    }

    func parsedShortcut(for actionID: String) -> CommandHotKeyShortcut? {
        CommandHotKeyShortcut.parse(shortcutText(for: actionID))
    }

    func bindings() -> [(actionID: String, shortcut: CommandHotKeyShortcut)] {
        assignedActionIDs.compactMap { actionID in
            guard let shortcut = parsedShortcut(for: actionID) else { return nil }
            return (actionID: actionID, shortcut: shortcut)
        }
    }

    func hasConflict(for actionID: String) -> Bool {
        conflictingActionTitle(for: actionID) != nil
    }

    func conflictingActionTitle(for actionID: String) -> String? {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID),
              let currentShortcut = effectiveShortcut(for: sanitizedActionID) else {
            return nil
        }

        return effectiveBindings().first {
            $0.actionID != sanitizedActionID
                && $0.shortcut.comparisonKey == currentShortcut.comparisonKey
        }?.title
    }

    func validationMessage(for actionID: String) -> String? {
        let text = shortcutText(for: actionID).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let shortcut = parsedShortcut(for: actionID) {
            if let conflictTitle = conflictingActionTitle(for: actionID) {
                return "Conflicts with \(conflictTitle): \(shortcut.displayText)."
            }
            return "Global hotkey ready: \(shortcut.displayText)"
        }
        return "Use a modifier plus key, like ⌥⌘P or cmd+shift+p."
    }

    @discardableResult
    func setShortcutText(actionID: String, shortcutText: String) -> Bool {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else {
            return false
        }

        let normalizedText = Self.normalizedText(shortcutText)
        var nextEntries = shortcutTextByActionID

        if normalizedText.isEmpty {
            nextEntries.removeValue(forKey: sanitizedActionID)
        } else {
            let resolvedText = CommandHotKeyShortcut.parse(normalizedText)?.displayText ?? normalizedText
            nextEntries[sanitizedActionID] = resolvedText

            if let resolvedShortcut = CommandHotKeyShortcut.parse(resolvedText) {
                for actionID in nextEntries.keys where actionID != sanitizedActionID {
                    guard let otherShortcut = CommandHotKeyShortcut.parse(nextEntries[actionID] ?? ""),
                          otherShortcut.comparisonKey == resolvedShortcut.comparisonKey else {
                        continue
                    }
                    nextEntries.removeValue(forKey: actionID)
                }
            }
        }

        guard nextEntries != shortcutTextByActionID else { return false }
        shortcutTextByActionID = nextEntries
        save()
        return true
    }

    @discardableResult
    func clearShortcut(actionID: String) -> Bool {
        setShortcutText(actionID: actionID, shortcutText: "")
    }

    func backupEntries() -> [String: String] {
        shortcutTextByActionID
    }

    @discardableResult
    func restoreEntries(_ entries: [String: String]) -> Bool {
        let sanitizedEntries = Self.sanitizedEntries(entries)
        guard sanitizedEntries != shortcutTextByActionID else { return false }
        shortcutTextByActionID = sanitizedEntries
        save()
        return true
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(shortcutTextByActionID) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadEntries(from defaults: UserDefaults, key: String) -> [String: String] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }

        var sanitized: [String: String] = [:]
        for (actionID, rawText) in decoded {
            guard let sanitizedActionID = sanitizedActionID(actionID) else { continue }
            let normalized = normalizedText(rawText)
            guard !normalized.isEmpty else { continue }
            sanitized[sanitizedActionID] = CommandHotKeyShortcut.parse(normalized)?.displayText ?? normalized
        }
        return sanitized
    }

    private static func sanitizedEntries(_ entries: [String: String]) -> [String: String] {
        var sanitized: [String: String] = [:]
        for (actionID, rawText) in entries {
            guard let sanitizedActionID = sanitizedActionID(actionID) else { continue }
            let normalized = normalizedText(rawText)
            guard !normalized.isEmpty else { continue }
            sanitized[sanitizedActionID] = CommandHotKeyShortcut.parse(normalized)?.displayText ?? normalized
        }
        return sanitized
    }

    private static func normalizedText(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let collapsed = trimmed
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return String(collapsed.prefix(maxTextLength))
    }

    private static func sanitizedActionID(_ actionID: String) -> String? {
        let trimmedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedActionID.isEmpty,
              trimmedActionID.count <= maxActionIDLength else {
            return nil
        }
        return trimmedActionID
    }

    private func effectiveShortcut(for actionID: String) -> CommandHotKeyShortcut? {
        if let definition = LauncherHotKeyCatalog.definition(for: actionID) {
            return definition.resolvedShortcut(using: self)
        }
        return parsedShortcut(for: actionID)
    }

    private func effectiveBindings() -> [EffectiveBinding] {
        let launcherDefinitions = LauncherHotKeyCatalog.all
        let launcherActionIDs = Set(launcherDefinitions.map(\.id))

        var bindings = launcherDefinitions.map {
            EffectiveBinding(
                actionID: $0.id,
                title: $0.title,
                shortcut: $0.resolvedShortcut(using: self)
            )
        }

        bindings.append(contentsOf: assignedActionIDs.compactMap { actionID in
            guard !launcherActionIDs.contains(actionID),
                  let shortcut = parsedShortcut(for: actionID) else {
                return nil
            }

            return EffectiveBinding(
                actionID: actionID,
                title: LauncherHotKeyCatalog.title(for: actionID) ?? actionID,
                shortcut: shortcut
            )
        })

        return bindings
    }
}
