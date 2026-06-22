import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    nonisolated static let launchRecoveryHotKeyDisplayName = "Option + Shift + L"
    nonisolated static let fameExceptionalLoopHotKeyDisplayName = "Option + Shift + E"
    private typealias ResolvedHotKey = (
        id: UInt32,
        keyCode: Int,
        modifiers: UInt32,
        name: String,
        isRequired: Bool
    )

    struct RegisteredHotKey {
        let keyCode: Int
        let modifiers: UInt32
        let name: String
    }

    struct AdditionalHotKey {
        let id: UInt32
        let keyCode: Int
        let modifiers: UInt32
        let name: String
        let isRequired: Bool
        let action: () -> Void
    }

    struct SystemAPI: @unchecked Sendable {
        let installEventHandler: (_ manager: HotKeyManager, _ eventHandler: inout EventHandlerRef?) -> OSStatus
        let removeEventHandler: (_ eventHandler: EventHandlerRef) -> Void
        let registerEventHotKey: (
            _ id: UInt32,
            _ keyCode: Int,
            _ modifiers: UInt32,
            _ hotKeyRef: inout EventHotKeyRef?
        ) -> OSStatus
        let unregisterEventHotKey: (_ hotKeyRef: EventHotKeyRef) -> Void

        static let live = Self(
            installEventHandler: { manager, eventHandler in
                var eventType = EventTypeSpec(
                    eventClass: OSType(kEventClassKeyboard),
                    eventKind: UInt32(kEventHotKeyPressed)
                )

                return InstallEventHandler(
                    GetApplicationEventTarget(),
                    { _, event, userData in
                        guard let userData else { return noErr }
                        let manager = Unmanaged<HotKeyManager>
                            .fromOpaque(userData)
                            .takeUnretainedValue()

                        var hotKeyID = EventHotKeyID()
                        let status = GetEventParameter(
                            event,
                            EventParamName(kEventParamDirectObject),
                            EventParamType(typeEventHotKeyID),
                            nil,
                            MemoryLayout<EventHotKeyID>.size,
                            nil,
                            &hotKeyID
                        )
                        guard status == noErr else { return status }

                        manager.actions[hotKeyID.id]?()
                        return noErr
                    },
                    1,
                    &eventType,
                    UnsafeMutableRawPointer(Unmanaged.passUnretained(manager).toOpaque()),
                    &eventHandler
                )
            },
            removeEventHandler: { eventHandler in
                RemoveEventHandler(eventHandler)
            },
            registerEventHotKey: { id, keyCode, modifiers, hotKeyRef in
                var hotKeyID = EventHotKeyID(signature: OSType(0x46524452), id: id)
                return RegisterEventHotKey(
                    UInt32(keyCode),
                    modifiers,
                    hotKeyID,
                    GetApplicationEventTarget(),
                    0,
                    &hotKeyRef
                )
            },
            unregisterEventHotKey: { hotKeyRef in
                UnregisterEventHotKey(hotKeyRef)
            }
        )
    }

    enum RegistrationError: LocalizedError, Equatable {
        case eventHandler(OSStatus)
        case hotKey(String, OSStatus)
        case duplicateHotKey(String, String)

        var errorDescription: String? {
            switch self {
            case .eventHandler(let status):
                return "The keyboard shortcut could not start. Error \(status)."
            case .hotKey(let name, let status):
                return "\(name) is already in use. Error \(status)."
            case .duplicateHotKey(let existingName, let conflictingName):
                return "\(conflictingName) conflicts with \(existingName). Use a different keyboard shortcut."
            }
        }
    }

    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actions: [UInt32: () -> Void] = [:]
    private(set) var skippedOptionalHotKeyNames: [String] = []
    private let systemAPI: SystemAPI

    private static let defaultReadHotKey = RegisteredHotKey(
        keyCode: kVK_ANSI_R,
        modifiers: UInt32(optionKey | shiftKey),
        name: "Option + Shift + R"
    )
    private static let defaultScreenshotHotKey = RegisteredHotKey(
        keyCode: kVK_ANSI_S,
        modifiers: UInt32(optionKey | shiftKey),
        name: "Option + Shift + S"
    )
    private static let defaultCommandHotKey = RegisteredHotKey(
        keyCode: kVK_Space,
        modifiers: UInt32(optionKey | shiftKey),
        name: "Option + Shift + Space"
    )
    private static let defaultLaunchRecoveryHotKey = RegisteredHotKey(
        keyCode: kVK_ANSI_L,
        modifiers: UInt32(optionKey | shiftKey),
        name: HotKeyManager.launchRecoveryHotKeyDisplayName
    )
    private static let defaultFameExceptionalLoopHotKey = RegisteredHotKey(
        keyCode: kVK_ANSI_E,
        modifiers: UInt32(optionKey | shiftKey),
        name: HotKeyManager.fameExceptionalLoopHotKeyDisplayName
    )

    init(systemAPI: SystemAPI = .live) {
        self.systemAPI = systemAPI
    }

    @discardableResult
    func register(
        readAction: @escaping () -> Void,
        screenshotAction: @escaping () -> Void,
        commandAction: @escaping () -> Void,
        readHotKey: RegisteredHotKey? = nil,
        screenshotHotKey: RegisteredHotKey? = nil,
        commandHotKey: RegisteredHotKey? = nil,
        launchRecoveryAction: (() -> Void)? = nil,
        launchRecoveryHotKey: RegisteredHotKey? = nil,
        fameExceptionalLoopAction: (() -> Void)? = nil,
        fameExceptionalLoopHotKey: RegisteredHotKey? = nil,
        additionalHotKeys: [AdditionalHotKey] = []
    ) -> Result<Void, RegistrationError> {
        let resolvedReadHotKey = readHotKey ?? Self.defaultReadHotKey
        let resolvedScreenshotHotKey = screenshotHotKey ?? Self.defaultScreenshotHotKey
        let resolvedCommandHotKey = commandHotKey ?? Self.defaultCommandHotKey

        var hotKeys: [ResolvedHotKey] = [
            (1, resolvedReadHotKey.keyCode, resolvedReadHotKey.modifiers, resolvedReadHotKey.name, true),
            (2, resolvedScreenshotHotKey.keyCode, resolvedScreenshotHotKey.modifiers, resolvedScreenshotHotKey.name, true),
            (3, resolvedCommandHotKey.keyCode, resolvedCommandHotKey.modifiers, resolvedCommandHotKey.name, true)
        ]
        if launchRecoveryAction != nil {
            let resolvedLaunchRecoveryHotKey = launchRecoveryHotKey ?? Self.defaultLaunchRecoveryHotKey
            hotKeys.append((
                4,
                resolvedLaunchRecoveryHotKey.keyCode,
                resolvedLaunchRecoveryHotKey.modifiers,
                resolvedLaunchRecoveryHotKey.name,
                false
            ))
        }
        if fameExceptionalLoopAction != nil {
            let resolvedExceptionalLoopHotKey = fameExceptionalLoopHotKey ?? Self.defaultFameExceptionalLoopHotKey
            hotKeys.append((
                5,
                resolvedExceptionalLoopHotKey.keyCode,
                resolvedExceptionalLoopHotKey.modifiers,
                resolvedExceptionalLoopHotKey.name,
                false
            ))
        }
        hotKeys.append(contentsOf: additionalHotKeys.map {
            ($0.id, $0.keyCode, $0.modifiers, $0.name, $0.isRequired)
        })

        if let duplicateError = Self.duplicateRegistrationError(in: hotKeys) {
            return .failure(duplicateError)
        }

        unregister()
        skippedOptionalHotKeyNames = []
        actions = [
            1: readAction,
            2: screenshotAction,
            3: commandAction
        ]
        if let launchRecoveryAction {
            actions[4] = launchRecoveryAction
        }
        if let fameExceptionalLoopAction {
            actions[5] = fameExceptionalLoopAction
        }
        for registration in additionalHotKeys {
            actions[registration.id] = registration.action
        }

        let handlerStatus = systemAPI.installEventHandler(self, &eventHandler)
        guard handlerStatus == noErr else {
            actions.removeAll()
            return .failure(.eventHandler(handlerStatus))
        }

        for hotKey in hotKeys {
            var ref: EventHotKeyRef?
            let hotKeyStatus = systemAPI.registerEventHotKey(
                hotKey.id,
                hotKey.keyCode,
                hotKey.modifiers,
                &ref
            )
            guard hotKeyStatus == noErr, let ref else {
                if hotKey.isRequired {
                    unregister()
                    return .failure(.hotKey(hotKey.name, hotKeyStatus))
                }
                actions.removeValue(forKey: hotKey.id)
                skippedOptionalHotKeyNames.append(hotKey.name)
                continue
            }
            hotKeyRefs[hotKey.id] = ref
        }

        return .success(())
    }

    deinit {
        unregister()
    }

    private func unregister() {
        for hotKeyRef in hotKeyRefs.values {
            systemAPI.unregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()

        if let eventHandler {
            systemAPI.removeEventHandler(eventHandler)
            self.eventHandler = nil
        }

        actions.removeAll()
    }

    private static func duplicateRegistrationError(
        in hotKeys: [ResolvedHotKey]
    ) -> RegistrationError? {
        var seenHotKeyNames: [String: String] = [:]

        for hotKey in hotKeys {
            let pairKey = "\(hotKey.modifiers):\(hotKey.keyCode)"
            if let existingName = seenHotKeyNames[pairKey] {
                return .duplicateHotKey(existingName, hotKey.name)
            }
            seenHotKeyNames[pairKey] = hotKey.name
        }

        return nil
    }
}
