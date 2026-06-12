import XCTest
@testable import FluidReader

@MainActor
final class SelectionControllerTests: XCTestCase {
    func testStartCancelsWhenExternalEffectsAreSuppressed() {
        let controller = SelectionController()
        var didCancel = false
        var didComplete = false

        controller.start(
            onDrawStart: {},
            onCommit: {},
            onCancel: { didCancel = true },
            completion: { _ in didComplete = true }
        )

        XCTAssertTrue(didCancel)
        XCTAssertFalse(didComplete)
    }
}
