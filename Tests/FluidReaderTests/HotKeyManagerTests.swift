import Carbon.HIToolbox
import XCTest
@testable import FluidReader

final class HotKeyManagerTests: XCTestCase {
    private struct AttemptedHotKey: Equatable {
        let id: UInt32
        let keyCode: Int
        let modifiers: UInt32
    }

    func testRegisterSkipsOptionalLaunchRecoveryHotKeyWhenBusy() {
        let optionalBusyStatus = OSStatus(eventHotKeyExistsErr)
        let (manager, attemptedHotKeyIDs, _) = makeManager { id in
            id == 4 ? optionalBusyStatus : noErr
        }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            launchRecoveryAction: {}
        )

        if case .failure(let error) = result {
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2, 3, 4])
        XCTAssertEqual(
            manager.skippedOptionalHotKeyNames,
            [HotKeyManager.launchRecoveryHotKeyDisplayName]
        )
    }

    func testRegisterSkipsOptionalExceptionalLoopHotKeyWhenBusy() {
        let optionalBusyStatus = OSStatus(eventHotKeyExistsErr)
        let (manager, attemptedHotKeyIDs, _) = makeManager { id in
            id == 5 ? optionalBusyStatus : noErr
        }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            launchRecoveryAction: {},
            fameExceptionalLoopAction: {}
        )

        if case .failure(let error) = result {
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2, 3, 4, 5])
        XCTAssertEqual(
            manager.skippedOptionalHotKeyNames,
            [HotKeyManager.fameExceptionalLoopHotKeyDisplayName]
        )
    }

    func testRegisterFailsWhenRequiredHotKeyIsUnavailable() {
        let expectedStatus = OSStatus(eventHotKeyExistsErr)
        let (manager, attemptedHotKeyIDs, _) = makeManager { id in
            id == 2 ? expectedStatus : noErr
        }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            launchRecoveryAction: {}
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .hotKey("Option + Shift + S", expectedStatus))
        case .success:
            XCTFail("Expected registration failure for required hotkey")
        }
        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2])
        XCTAssertTrue(manager.skippedOptionalHotKeyNames.isEmpty)
    }

    func testRegisterWithoutLaunchRecoveryActionSkipsOptionalRegistration() {
        let (manager, attemptedHotKeyIDs, _) = makeManager { _ in noErr }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {}
        )

        if case .failure(let error) = result {
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2, 3])
        XCTAssertTrue(manager.skippedOptionalHotKeyNames.isEmpty)
    }

    func testRegisterClearsSkippedOptionalHotKeysOnSubsequentRegistration() {
        let optionalBusyStatus = OSStatus(eventHotKeyExistsErr)
        var shouldFailOptionalHotKey = true
        let (manager, attemptedHotKeyIDs, _) = makeManager { id in
            if id == 4, shouldFailOptionalHotKey {
                return optionalBusyStatus
            }
            return noErr
        }

        let firstResult = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            launchRecoveryAction: {}
        )
        if case .failure(let error) = firstResult {
            XCTFail("Expected first registration to succeed, got \(error)")
        }
        XCTAssertEqual(
            manager.skippedOptionalHotKeyNames,
            [HotKeyManager.launchRecoveryHotKeyDisplayName]
        )

        shouldFailOptionalHotKey = false
        let secondResult = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {}
        )
        if case .failure(let error) = secondResult {
            XCTFail("Expected second registration to succeed, got \(error)")
        }

        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2, 3, 4, 1, 2, 3])
        XCTAssertTrue(manager.skippedOptionalHotKeyNames.isEmpty)
    }

    func testRegisterIncludesAdditionalHotKeys() {
        let (manager, attemptedHotKeyIDs, _) = makeManager { _ in noErr }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            additionalHotKeys: [
                HotKeyManager.AdditionalHotKey(
                    id: 100,
                    keyCode: kVK_ANSI_P,
                    modifiers: UInt32(optionKey | cmdKey),
                    name: "Custom P",
                    isRequired: false,
                    action: {}
                )
            ]
        )

        if case .failure(let error) = result {
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2, 3, 100])
    }

    func testRegisterFailsWhenLauncherHotKeysDuplicateEachOther() {
        let (manager, attemptedHotKeyIDs, _) = makeManager { _ in noErr }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            screenshotHotKey: HotKeyManager.RegisteredHotKey(
                keyCode: kVK_ANSI_P,
                modifiers: UInt32(cmdKey | shiftKey),
                name: "Screenshot"
            ),
            commandHotKey: HotKeyManager.RegisteredHotKey(
                keyCode: kVK_ANSI_P,
                modifiers: UInt32(cmdKey | shiftKey),
                name: "Commands"
            )
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .duplicateHotKey("Screenshot", "Commands"))
        case .success:
            XCTFail("Expected registration failure for duplicate launcher hotkeys")
        }
        XCTAssertTrue(attemptedHotKeyIDs().isEmpty)
        XCTAssertTrue(manager.skippedOptionalHotKeyNames.isEmpty)
    }

    func testRegisterSkipsBusyAdditionalHotKeys() {
        let optionalBusyStatus = OSStatus(eventHotKeyExistsErr)
        let (manager, attemptedHotKeyIDs, _) = makeManager { id in
            id == 100 ? optionalBusyStatus : noErr
        }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            additionalHotKeys: [
                HotKeyManager.AdditionalHotKey(
                    id: 100,
                    keyCode: kVK_ANSI_P,
                    modifiers: UInt32(optionKey | cmdKey),
                    name: "Custom P",
                    isRequired: false,
                    action: {}
                )
            ]
        )

        if case .failure(let error) = result {
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(attemptedHotKeyIDs(), [1, 2, 3, 100])
        XCTAssertEqual(manager.skippedOptionalHotKeyNames, ["Custom P"])
    }

    func testRegisterFailsWhenAdditionalHotKeyDuplicatesLauncherShortcut() {
        let duplicateCommandHotKey = HotKeyManager.RegisteredHotKey(
            keyCode: kVK_ANSI_P,
            modifiers: UInt32(cmdKey | shiftKey),
            name: "Commands"
        )
        let (manager, attemptedHotKeyIDs, _) = makeManager { _ in noErr }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            commandHotKey: duplicateCommandHotKey,
            additionalHotKeys: [
                HotKeyManager.AdditionalHotKey(
                    id: 100,
                    keyCode: kVK_ANSI_P,
                    modifiers: UInt32(cmdKey | shiftKey),
                    name: "Custom Action",
                    isRequired: false,
                    action: {}
                )
            ]
        )

        switch result {
        case .failure(let error):
            XCTAssertEqual(error, .duplicateHotKey("Commands", "Custom Action"))
        case .success:
            XCTFail("Expected registration failure for duplicate additional hotkey")
        }
        XCTAssertTrue(attemptedHotKeyIDs().isEmpty)
        XCTAssertTrue(manager.skippedOptionalHotKeyNames.isEmpty)
    }

    func testRegisterUsesCustomDedicatedHotKeysWhenProvided() {
        let customCommandHotKey = HotKeyManager.RegisteredHotKey(
            keyCode: kVK_ANSI_P,
            modifiers: UInt32(cmdKey | shiftKey),
            name: "⇧⌘P"
        )
        let (manager, _, attemptedHotKeys) = makeManager { _ in noErr }

        let result = manager.register(
            readAction: {},
            screenshotAction: {},
            commandAction: {},
            commandHotKey: customCommandHotKey
        )

        if case .failure(let error) = result {
            XCTFail("Expected success, got \(error)")
        }
        XCTAssertEqual(
            attemptedHotKeys().first(where: { $0.id == 3 }),
            AttemptedHotKey(
                id: 3,
                keyCode: kVK_ANSI_P,
                modifiers: UInt32(cmdKey | shiftKey)
            )
        )
    }

    private func makeManager(
        registerStatusForHotKeyID: @escaping (_ id: UInt32) -> OSStatus
    ) -> (HotKeyManager, () -> [UInt32], () -> [AttemptedHotKey]) {
        var attemptedHotKeys: [AttemptedHotKey] = []

        let systemAPI = HotKeyManager.SystemAPI(
            installEventHandler: { _, eventHandler in
                eventHandler = OpaquePointer(bitPattern: 0xCAFE)
                return noErr
            },
            removeEventHandler: { _ in },
            registerEventHotKey: { id, keyCode, modifiers, hotKeyRef in
                attemptedHotKeys.append(
                    AttemptedHotKey(
                        id: id,
                        keyCode: Int(keyCode),
                        modifiers: modifiers
                    )
                )
                let status = registerStatusForHotKeyID(id)
                if status == noErr {
                    hotKeyRef = OpaquePointer(bitPattern: Int(id) + 0x100)
                } else {
                    hotKeyRef = nil
                }
                return status
            },
            unregisterEventHotKey: { _ in }
        )

        return (
            HotKeyManager(systemAPI: systemAPI),
            { attemptedHotKeys.map(\.id) },
            { attemptedHotKeys }
        )
    }
}
