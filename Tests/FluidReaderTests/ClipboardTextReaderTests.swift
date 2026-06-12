import XCTest
@testable import FluidReader

final class ClipboardTextReaderTests: XCTestCase {
    func testCleanTrimsText() {
        XCTAssertEqual(ClipboardTextReader.clean("  Hello clipboard\n"), "Hello clipboard")
    }

    func testCleanRejectsBlankText() {
        XCTAssertNil(ClipboardTextReader.clean(nil))
        XCTAssertNil(ClipboardTextReader.clean("  \n\t  "))
    }
}
