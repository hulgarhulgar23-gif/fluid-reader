import Carbon.HIToolbox
import XCTest
@testable import FluidReader

final class HotKeyManagerTests: XCTestCase {
    func testRegisterSkipsOptionalLaunchRecoveryHotKeyWhenBusy() {
        let optionalBusyStatus = OSStatus(eventHotKeyExistsErr)
        let (manager, attemptedHotKeyIDs) = makeManager { id in
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
        let (manager, attemptedHotKeyIDs) = makeManager { id in
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
        let (manager, attemptedHotKeyIDs) = makeManager { id in
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
        let (manager, attemptedHotKeyIDs) = makeManager { _ in noErr }

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
        let (manager, attemptedHotKeyIDs) = makeManager { id in
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

    private func makeManager(
        registerStatusForHotKeyID: @escaping (_ id: UInt32) -> OSStatus
    ) -> (HotKeyManager, () -> [UInt32]) {
        var attemptedHotKeyIDs: [UInt32] = []

        let systemAPI = HotKeyManager.SystemAPI(
            installEventHandler: { _, eventHandler in
                eventHandler = OpaquePointer(bitPattern: 0xCAFE)
                return noErr
            },
            removeEventHandler: { _ in },
            registerEventHotKey: { id, _, _, hotKeyRef in
                attemptedHotKeyIDs.append(id)
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

        return (HotKeyManager(systemAPI: systemAPI), { attemptedHotKeyIDs })
    }
}
