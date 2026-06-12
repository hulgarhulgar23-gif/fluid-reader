import ServiceManagement
import XCTest
@testable import FluidReader

final class LaunchAtLoginManagerTests: XCTestCase {
    func testStatesMapFromSystemStatus() {
        XCTAssertEqual(LaunchAtLoginState.from(.enabled), .enabled)
        XCTAssertEqual(LaunchAtLoginState.from(.notRegistered), .disabled)
        XCTAssertEqual(LaunchAtLoginState.from(.requiresApproval), .requiresApproval)
        XCTAssertEqual(LaunchAtLoginState.from(.notFound), .unavailable)
    }

    func testOnlyOnAndOffCanToggle() {
        XCTAssertTrue(LaunchAtLoginState.enabled.canToggle)
        XCTAssertTrue(LaunchAtLoginState.disabled.canToggle)
        XCTAssertFalse(LaunchAtLoginState.requiresApproval.canToggle)
        XCTAssertFalse(LaunchAtLoginState.unavailable.canToggle)
    }

    func testUserTextIsClear() {
        XCTAssertEqual(LaunchAtLoginState.enabled.title, "On")
        XCTAssertEqual(LaunchAtLoginState.disabled.title, "Off")
        XCTAssertEqual(LaunchAtLoginState.requiresApproval.disabledReason, "Needs approval")
        XCTAssertEqual(LaunchAtLoginState.unavailable.disabledReason, "Unavailable")
        XCTAssertTrue(LaunchAtLoginState.requiresApproval.detail.contains("Login Items"))
    }
}
