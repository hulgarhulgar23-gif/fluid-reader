import XCTest
@testable import FluidReader

final class AppDefaultsTests: XCTestCase {
    func testModelDefaultsAreSet() {
        XCTAssertEqual(AppDefaults.llmModel, "gpt-5.4-mini")
        XCTAssertEqual(AppDefaults.cloudVoiceModel, "gpt-4o-mini-tts")
        XCTAssertEqual(AppDefaults.cloudVoiceName, "alloy")
    }

    func testBlankValueFallsBack() {
        XCTAssertEqual(AppDefaults.value("  ", fallback: "fallback"), "fallback")
        XCTAssertEqual(AppDefaults.value(" custom ", fallback: "fallback"), "custom")
    }

    func testScreenRecordingSettingsURL() throws {
        let url = try XCTUnwrap(AppDefaults.screenRecordingSettingsURL)
        XCTAssertEqual(url.scheme, "x-apple.systempreferences")
        XCTAssertTrue(url.absoluteString.contains("Privacy_ScreenCapture"))
    }
}
