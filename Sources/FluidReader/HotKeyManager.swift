import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    enum RegistrationError: LocalizedError, Equatable {
        case eventHandler(OSStatus)
        case hotKey(OSStatus)

        var errorDescription: String? {
            switch self {
            case .eventHandler(let status):
                return "The keyboard shortcut could not start. Error \(status)."
            case .hotKey(let status):
                return "Option + Shift + R is already in use. Error \(status)."
            }
        }
    }

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var action: (() -> Void)?

    @discardableResult
    func register(action: @escaping () -> Void) -> Result<Void, RegistrationError> {
        unregister()
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                manager.action?()
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
        guard handlerStatus == noErr else {
            self.action = nil
            return .failure(.eventHandler(handlerStatus))
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x46524452), id: 1)
        let hotKeyStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_R),
            UInt32(optionKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard hotKeyStatus == noErr else {
            unregister()
            return .failure(.hotKey(hotKeyStatus))
        }

        return .success(())
    }

    deinit {
        unregister()
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }

        action = nil
    }
}
