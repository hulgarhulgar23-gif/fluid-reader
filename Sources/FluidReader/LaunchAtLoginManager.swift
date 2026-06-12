import Foundation
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable

    var isEnabled: Bool {
        self == .enabled
    }

    var canToggle: Bool {
        switch self {
        case .enabled, .disabled:
            return true
        case .requiresApproval, .unavailable:
            return false
        }
    }

    var title: String {
        switch self {
        case .enabled:
            return "On"
        case .disabled:
            return "Off"
        case .requiresApproval:
            return "Needs approval"
        case .unavailable:
            return "Unavailable"
        }
    }

    var detail: String {
        switch self {
        case .enabled:
            return "Opens at sign-in."
        case .disabled:
            return "Does not open at sign-in."
        case .requiresApproval:
            return "Approve in Login Items."
        case .unavailable:
            return "Requires app bundle."
        }
    }

    var disabledReason: String {
        switch self {
        case .enabled, .disabled:
            return "Not ready"
        case .requiresApproval:
            return "Needs approval"
        case .unavailable:
            return "Unavailable"
        }
    }

    static func from(_ status: SMAppService.Status) -> LaunchAtLoginState {
        switch status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }
}

enum LaunchAtLoginManager {
    static var state: LaunchAtLoginState {
        LaunchAtLoginState.from(SMAppService.mainApp.status)
    }

    static func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    static func openSettings() {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        SMAppService.openSystemSettingsLoginItems()
    }
}
