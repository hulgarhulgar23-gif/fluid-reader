import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    nonisolated static let launchRecoveryHotKeyDisplayName = "Option + Shift + L"
    nonisolated static let fameExceptionalLoopHotKeyDisplayName = "Option + Shift + E"

    struct SystemAPI {
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

        var errorDescription: String? {
            switch self {
            case .eventHandler(let status):
                return "The keyboard shortcut could not start. Error \(status)."
            case .hotKey(let name, let status):
                return "\(name) is already in use. Error \(status)."
            }
        }
    }

    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actions: [UInt32: () -> Void] = [:]
    private(set) var skippedOptionalHotKeyNames: [String] = []
    private let systemAPI: SystemAPI

    init(systemAPI: SystemAPI = .live) {
        self.systemAPI = systemAPI
    }

    @discardableResult
    func register(
        readAction: @escaping () -> Void,
        screenshotAction: @escaping () -> Void,
        commandAction: @escaping () -> Void,
        launchRecoveryAction: (() -> Void)? = nil,
        fameExceptionalLoopAction: (() -> Void)? = nil
    ) -> Result<Void, RegistrationError> {
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

        let handlerStatus = systemAPI.installEventHandler(self, &eventHandler)
        guard handlerStatus == noErr else {
            actions.removeAll()
            return .failure(.eventHandler(handlerStatus))
        }

        var hotKeys: [(id: UInt32, keyCode: Int, name: String, isRequired: Bool)] = [
            (1, kVK_ANSI_R, "Option + Shift + R", true),
            (2, kVK_ANSI_S, "Option + Shift + S", true),
            (3, kVK_Space, "Option + Shift + Space", true)
        ]
        if launchRecoveryAction != nil {
            hotKeys.append((4, kVK_ANSI_L, Self.launchRecoveryHotKeyDisplayName, false))
        }
        if fameExceptionalLoopAction != nil {
            hotKeys.append((5, kVK_ANSI_E, Self.fameExceptionalLoopHotKeyDisplayName, false))
        }

        for hotKey in hotKeys {
            var ref: EventHotKeyRef?
            let hotKeyStatus = systemAPI.registerEventHotKey(
                hotKey.id,
                hotKey.keyCode,
                UInt32(optionKey | shiftKey),
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
}
