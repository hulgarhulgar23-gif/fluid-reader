import XCTest
@testable import FluidReader

final class OCRLanguagePresetTests: XCTestCase {
    func testPresetsIncludeAutoAndEnglish() {
        XCTAssertEqual(OCRLanguagePreset.presets.first?.id, "auto")
        XCTAssertEqual(OCRLanguagePreset.presets.first?.languageCode, "")
        XCTAssertTrue(OCRLanguagePreset.presets.contains { $0.languageCode == "en-US" })
    }

    func testTitleFallsBackToCustomCode() {
        XCTAssertEqual(OCRLanguagePreset.title(for: ""), "Auto")
        XCTAssertEqual(OCRLanguagePreset.title(for: "en-US"), "English")
        XCTAssertEqual(OCRLanguagePreset.title(for: " mn-MN "), "mn-MN")
    }

    func testNormalizedTrimsCode() {
        XCTAssertEqual(OCRLanguagePreset.normalized(" en-US "), "en-US")
    }
}
