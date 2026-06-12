import Foundation

enum SetupChecklistItemState: String, Equatable {
    case ready
    case actionNeeded
    case optional

    var title: String {
        switch self {
        case .ready:
            return "Ready"
        case .actionNeeded:
            return "Needs step"
        case .optional:
            return "Can skip"
        }
    }

    var systemImage: String {
        switch self {
        case .ready:
            return "checkmark.circle.fill"
        case .actionNeeded:
            return "exclamationmark.circle.fill"
        case .optional:
            return "circle"
        }
    }
}

enum SetupChecklistAction: String, Equatable {
    case screenRecordingSettings
    case accessibilitySettings
    case appSettings
    case loginItemsSettings
}

struct SetupChecklistItem: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let state: SetupChecklistItemState
    let actionTitle: String?
    let action: SetupChecklistAction?
}

struct SetupChecklistReport: Equatable {
    let items: [SetupChecklistItem]

    var actionNeededCount: Int {
        items.filter { $0.state == .actionNeeded }.count
    }

    var focusedItems: [SetupChecklistItem] {
        let targetState: SetupChecklistItemState = actionNeededCount == 0 ? .ready : .actionNeeded
        return items.filter { $0.state == targetState }
    }

    var summary: String {
        switch actionNeededCount {
        case 0:
            return "Ready for local reading."
        case 1:
            return "1 setup step needs attention."
        default:
            return "\(actionNeededCount) setup steps need attention."
        }
    }

    static let empty = SetupChecklistReport(items: [])

    @MainActor
    static func make(settings: SettingsStore) -> SetupChecklistReport {
        make(
            screenRecordingAllowed: PermissionStatus.screenRecordingAllowed(),
            accessibilityTrusted: PermissionStatus.accessibilityTrusted(),
            llmEnabled: settings.llmEnabled,
            apiKeySet: !settings.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            autoPastePickedText: settings.autoPastePickedText,
            autoPasteLLMAnswers: settings.autoPasteLLMAnswers,
            saveRecentItems: settings.saveRecentItems,
            saveClipboardHistory: settings.saveClipboardHistory,
            launchAtLoginState: LaunchAtLoginManager.state
        )
    }

    static func make(
        screenRecordingAllowed: Bool,
        accessibilityTrusted: Bool,
        llmEnabled: Bool,
        apiKeySet: Bool,
        autoPastePickedText: Bool = false,
        autoPasteLLMAnswers: Bool = false,
        saveRecentItems: Bool,
        saveClipboardHistory: Bool = AppDefaults.saveClipboardHistory,
        launchAtLoginState: LaunchAtLoginState
    ) -> SetupChecklistReport {
        SetupChecklistReport(items: [
            screenRecordingItem(isAllowed: screenRecordingAllowed),
            accessibilityItem(isTrusted: accessibilityTrusted),
            llmItem(isEnabled: llmEnabled, apiKeySet: apiKeySet),
            autoPastePickedTextItem(isEnabled: autoPastePickedText, accessibilityTrusted: accessibilityTrusted),
            autoPasteLLMAnswersItem(isEnabled: autoPasteLLMAnswers, accessibilityTrusted: accessibilityTrusted),
            launchAtLoginItem(state: launchAtLoginState),
            recentItemsItem(isEnabled: saveRecentItems),
            clipboardHistoryItem(isEnabled: saveClipboardHistory)
        ])
    }

    private static func screenRecordingItem(isAllowed: Bool) -> SetupChecklistItem {
        SetupChecklistItem(
            id: "screen-recording",
            title: "Screen Recording",
            detail: isAllowed
                ? "Screen pick can read text on the screen."
                : "Turn on Fluid Reader in Screen Recording. Quit and reopen if macOS still blocks it.",
            state: isAllowed ? .ready : .actionNeeded,
            actionTitle: isAllowed ? nil : "Open Screen Recording Settings",
            action: isAllowed ? nil : .screenRecordingSettings
        )
    }

    private static func accessibilityItem(isTrusted: Bool) -> SetupChecklistItem {
        SetupChecklistItem(
            id: "accessibility",
            title: "Accessibility",
            detail: isTrusted
                ? "Selected-text, paste, and window commands can work."
                : "Turn on Fluid Reader in Accessibility. Quit and reopen if commands still fail.",
            state: isTrusted ? .ready : .actionNeeded,
            actionTitle: isTrusted ? nil : "Open Accessibility Settings",
            action: isTrusted ? nil : .accessibilitySettings
        )
    }

    private static func llmItem(isEnabled: Bool, apiKeySet: Bool) -> SetupChecklistItem {
        if isEnabled && apiKeySet {
            return SetupChecklistItem(
                id: "llm",
                title: "LLM",
                detail: "Ask actions are ready.",
                state: .ready,
                actionTitle: nil,
                action: nil
            )
        }

        if isEnabled {
            return SetupChecklistItem(
                id: "llm",
                title: "LLM",
                detail: "Add an API key so ask actions can run.",
                state: .actionNeeded,
                actionTitle: "Open Settings",
                action: .appSettings
            )
        }

        return SetupChecklistItem(
            id: "llm",
            title: "LLM",
            detail: "Local mode works without LLM.",
            state: .optional,
            actionTitle: "Open Settings",
            action: .appSettings
        )
    }

    private static func autoPastePickedTextItem(
        isEnabled: Bool,
        accessibilityTrusted: Bool
    ) -> SetupChecklistItem {
        guard isEnabled else {
            return SetupChecklistItem(
                id: "auto-paste-picked-text",
                title: "Auto-Paste Picked Text",
                detail: "Off. You can turn it on later.",
                state: .optional,
                actionTitle: "Open Settings",
                action: .appSettings
            )
        }

        return SetupChecklistItem(
            id: "auto-paste-picked-text",
            title: "Auto-Paste Picked Text",
            detail: accessibilityTrusted
                ? "Picked screen text can paste into the last app."
                : "Turn on Fluid Reader in Accessibility. Quit and reopen if paste still fails.",
            state: accessibilityTrusted ? .ready : .actionNeeded,
            actionTitle: accessibilityTrusted ? nil : "Open Accessibility Settings",
            action: accessibilityTrusted ? nil : .accessibilitySettings
        )
    }

    private static func autoPasteLLMAnswersItem(
        isEnabled: Bool,
        accessibilityTrusted: Bool
    ) -> SetupChecklistItem {
        guard isEnabled else {
            return SetupChecklistItem(
                id: "auto-paste-llm-answers",
                title: "Auto-Paste LLM Answers",
                detail: "Off. You can turn it on later.",
                state: .optional,
                actionTitle: "Open Settings",
                action: .appSettings
            )
        }

        return SetupChecklistItem(
            id: "auto-paste-llm-answers",
            title: "Auto-Paste LLM Answers",
            detail: accessibilityTrusted
                ? "LLM answers can paste into the last app."
                : "Turn on Fluid Reader in Accessibility. Quit and reopen if paste still fails.",
            state: accessibilityTrusted ? .ready : .actionNeeded,
            actionTitle: accessibilityTrusted ? nil : "Open Accessibility Settings",
            action: accessibilityTrusted ? nil : .accessibilitySettings
        )
    }

    private static func launchAtLoginItem(state: LaunchAtLoginState) -> SetupChecklistItem {
        let itemState: SetupChecklistItemState
        let actionTitle: String?
        let action: SetupChecklistAction?

        switch state {
        case .enabled:
            itemState = .ready
            actionTitle = nil
            action = nil
        case .requiresApproval:
            itemState = .actionNeeded
            actionTitle = "Open Login Items Settings"
            action = .loginItemsSettings
        case .disabled, .unavailable:
            itemState = .optional
            actionTitle = state == .disabled ? "Open Settings" : nil
            action = state == .disabled ? .appSettings : nil
        }

        return SetupChecklistItem(
            id: "launch-at-login",
            title: "Launch at Login",
            detail: state.detail,
            state: itemState,
            actionTitle: actionTitle,
            action: action
        )
    }

    private static func recentItemsItem(isEnabled: Bool) -> SetupChecklistItem {
        SetupChecklistItem(
            id: "recent-items",
            title: "Recent Items",
            detail: isEnabled
                ? "Recent text and answers are saved on this Mac."
                : "Off. You can turn it on later.",
            state: isEnabled ? .ready : .optional,
            actionTitle: isEnabled ? nil : "Open Settings",
            action: isEnabled ? nil : .appSettings
        )
    }

    private static func clipboardHistoryItem(isEnabled: Bool) -> SetupChecklistItem {
        SetupChecklistItem(
            id: "clipboard-history",
            title: "Clipboard History",
            detail: isEnabled
                ? "Future text clipboard changes are saved on this Mac."
                : "Off. You can turn it on later.",
            state: isEnabled ? .ready : .optional,
            actionTitle: isEnabled ? nil : "Open Settings",
            action: isEnabled ? nil : .appSettings
        )
    }
}
