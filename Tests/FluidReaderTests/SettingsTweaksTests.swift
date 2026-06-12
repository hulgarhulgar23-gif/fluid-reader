import XCTest
@testable import FluidReader

final class SettingsTweaksTests: XCTestCase {
    func testSpeechRateStepsByFiveHundredths() {
        XCTAssertEqual(SettingsTweaks.fasterSpeechRate(from: 0.48), 0.53)
        XCTAssertEqual(SettingsTweaks.slowerSpeechRate(from: 0.48), 0.43)
    }

    func testSpeechRateStaysInsideSettingsRange() {
        XCTAssertEqual(SettingsTweaks.fasterSpeechRate(from: 0.64), 0.65)
        XCTAssertEqual(SettingsTweaks.slowerSpeechRate(from: 0.31), 0.30)
    }

    func testSpeechRateLabelUsesTwoDecimals() {
        XCTAssertEqual(SettingsTweaks.speechRateLabel(0.5), "0.50")
    }
}
