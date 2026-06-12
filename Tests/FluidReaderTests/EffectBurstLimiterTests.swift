import XCTest
@testable import FluidReader

final class EffectBurstLimiterTests: XCTestCase {
    @MainActor
    func testGeneratedSoundDataHasValidWavHeader() {
        let data = EffectsService().soundDataForTesting(effect: .success, style: "glass")

        XCTAssertGreaterThan(data.count, 44)
        XCTAssertEqual(asciiString(data, range: 0..<4), "RIFF")
        XCTAssertEqual(asciiString(data, range: 8..<12), "WAVE")
        XCTAssertEqual(asciiString(data, range: 12..<16), "fmt ")
        XCTAssertEqual(asciiString(data, range: 36..<40), "data")
        XCTAssertEqual(littleEndianUInt32(data, at: 4) + 8, UInt32(data.count))
        XCTAssertEqual(littleEndianUInt32(data, at: 24), 44_100)
        XCTAssertEqual(littleEndianUInt32(data, at: 40) + 44, UInt32(data.count))
    }

    func testSuppressesAfterMaxEventsAndMutesBriefly() {
        var limiter = EffectBurstLimiter<String>(
            windowSeconds: 1.0,
            maxEvents: 3,
            muteSeconds: 2.0
        )
        let start = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertTrue(limiter.shouldAllow("sound", now: start))
        XCTAssertTrue(limiter.shouldAllow("sound", now: start.addingTimeInterval(0.1)))
        XCTAssertTrue(limiter.shouldAllow("sound", now: start.addingTimeInterval(0.2)))
        XCTAssertFalse(limiter.shouldAllow("sound", now: start.addingTimeInterval(0.3)))
        XCTAssertFalse(limiter.shouldAllow("sound", now: start.addingTimeInterval(1.4)))
        XCTAssertTrue(limiter.shouldAllow("sound", now: start.addingTimeInterval(2.4)))
    }

    func testMinimumGapIsPerEvent() {
        var limiter = EffectBurstLimiter<String>(
            windowSeconds: 1.0,
            maxEvents: 10,
            muteSeconds: 1.0,
            defaultMinimumGapSeconds: 0.2
        )
        let start = Date(timeIntervalSinceReferenceDate: 2_000)

        XCTAssertTrue(limiter.shouldAllow("tap", now: start))
        XCTAssertFalse(limiter.shouldAllow("tap", now: start.addingTimeInterval(0.1)))
        XCTAssertTrue(limiter.shouldAllow("success", now: start.addingTimeInterval(0.1)))
        XCTAssertTrue(limiter.shouldAllow("tap", now: start.addingTimeInterval(0.21)))
    }

    func testOldEventsDropOutOfWindow() {
        var limiter = EffectBurstLimiter<String>(
            windowSeconds: 1.0,
            maxEvents: 2,
            muteSeconds: 1.0
        )
        let start = Date(timeIntervalSinceReferenceDate: 3_000)

        XCTAssertTrue(limiter.shouldAllow("sound", now: start))
        XCTAssertTrue(limiter.shouldAllow("sound", now: start.addingTimeInterval(0.4)))
        XCTAssertFalse(limiter.shouldAllow("sound", now: start.addingTimeInterval(0.5)))
        XCTAssertTrue(limiter.shouldAllow("sound", now: start.addingTimeInterval(1.6)))
    }

    private func asciiString(_ data: Data, range: Range<Int>) -> String {
        String(decoding: data[range], as: UTF8.self)
    }

    private func littleEndianUInt32(_ data: Data, at offset: Int) -> UInt32 {
        let bytes = [UInt8](data[offset..<(offset + 4)])
        return UInt32(bytes[0]) |
            UInt32(bytes[1]) << 8 |
            UInt32(bytes[2]) << 16 |
            UInt32(bytes[3]) << 24
    }
}
