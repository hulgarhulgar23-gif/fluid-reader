import XCTest
@testable import FluidReader

final class WinCardRendererTests: XCTestCase {
    func testPngDataBuildsValidPNG() throws {
        let data = try XCTUnwrap(WinCardRenderer.pngData(savedItemCount: 3, activityLogItemCount: 2))

        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(Array(data.prefix(8)), [137, 80, 78, 71, 13, 10, 26, 10])
    }

    func testPngDataChangesWhenCountsChange() throws {
        let first = try XCTUnwrap(WinCardRenderer.pngData(savedItemCount: 1, activityLogItemCount: 1))
        let second = try XCTUnwrap(WinCardRenderer.pngData(savedItemCount: 8, activityLogItemCount: 1))

        XCTAssertNotEqual(first, second)
    }

    func testPngDataClampsNegativeCounts() throws {
        let negative = try XCTUnwrap(WinCardRenderer.pngData(savedItemCount: -4, activityLogItemCount: -2))
        let zero = try XCTUnwrap(WinCardRenderer.pngData(savedItemCount: 0, activityLogItemCount: 0))

        XCTAssertEqual(negative, zero)
    }
}
