import XCTest
@testable import FluidReader

final class InlineUnitConverterTests: XCTestCase {
    func testParseCommonConversions() throws {
        XCTAssertEqual(
            UnitConversion.parse("10 km to miles"),
            UnitConversion(source: "10 km", result: "6.21371 mi")
        )
        XCTAssertEqual(
            UnitConversion.parse("convert 10 km to miles"),
            UnitConversion(source: "10 km", result: "6.21371 mi")
        )
        XCTAssertEqual(
            UnitConversion.parse("10km to miles"),
            UnitConversion(source: "10 km", result: "6.21371 mi")
        )
        XCTAssertEqual(
            UnitConversion.parse("what is 8 fl oz in ml?"),
            UnitConversion(source: "8 fl oz", result: "236.588 mL")
        )
        XCTAssertEqual(
            UnitConversion.parse("32 f to c"),
            UnitConversion(source: "32 F", result: "0 C")
        )
        XCTAssertEqual(
            UnitConversion.parse("1 gb to mb"),
            UnitConversion(source: "1 GB", result: "1000 MB")
        )
        XCTAssertEqual(
            UnitConversion.parse("90 min to hours"),
            UnitConversion(source: "90 min", result: "1.5 h")
        )
        XCTAssertEqual(
            UnitConversion.parse("2 cups to ml"),
            UnitConversion(source: "2 cup", result: "473.176 mL")
        )
        XCTAssertEqual(
            UnitConversion.parse("1 gal to liters"),
            UnitConversion(source: "1 gal", result: "3.78541 L")
        )
        XCTAssertEqual(
            UnitConversion.parse("8 fl oz to ml"),
            UnitConversion(source: "8 fl oz", result: "236.588 mL")
        )
        XCTAssertEqual(
            UnitConversion.parse("1 cup to fl oz"),
            UnitConversion(source: "1 cup", result: "8 fl oz")
        )
        XCTAssertEqual(
            UnitConversion.parse("14:30 UTC+8 to UTC"),
            UnitConversion(source: "14:30 UTC+08:00", result: "06:30 UTC+00:00")
        )
        XCTAssertEqual(
            UnitConversion.parse("23:00 UTC to UTC+2"),
            UnitConversion(source: "23:00 UTC+00:00", result: "01:00 UTC+02:00")
        )
        XCTAssertEqual(
            UnitConversion.parse("09:15 UTC+5:30 to UTC-4"),
            UnitConversion(source: "09:15 UTC+05:30", result: "23:45 UTC-04:00")
        )
        XCTAssertEqual(
            UnitConversion.parse("9 pm PST to EST"),
            UnitConversion(source: "21:00 PST UTC-08:00", result: "00:00 EST UTC-05:00")
        )
        XCTAssertEqual(
            UnitConversion.parse("timezone 9 pm PST to EST"),
            UnitConversion(source: "21:00 PST UTC-08:00", result: "00:00 EST UTC-05:00")
        )
        XCTAssertEqual(
            UnitConversion.parse("12am JST to UTC"),
            UnitConversion(source: "00:00 JST UTC+09:00", result: "15:00 UTC+00:00")
        )
    }

    func testParseTimeZonesUsesLocalByDefaultWhenSourceZoneMissing() throws {
        let localTimeZone = try XCTUnwrap(TimeZone(secondsFromGMT: ((5 * 60) + 45) * 60))
        XCTAssertEqual(
            UnitConversion.parse("9:15 to utc", localTimeZone: localTimeZone),
            UnitConversion(source: "09:15 local UTC+05:45", result: "03:30 UTC+00:00")
        )
    }

    func testParseRejectsInvalidConversions() {
        XCTAssertNil(UnitConversion.parse("read selected text"))
        XCTAssertNil(UnitConversion.parse("10 km"))
        XCTAssertNil(UnitConversion.parse("10 km to kg"))
        XCTAssertNil(UnitConversion.parse("10 cups to kg"))
        XCTAssertNil(UnitConversion.parse("km to miles"))
        XCTAssertNil(UnitConversion.parse("10 apples to oranges"))
        XCTAssertNil(UnitConversion.parse("25:00 UTC to local"))
        XCTAssertNil(UnitConversion.parse("09:00 UTC to nowhere"))
        XCTAssertNil(UnitConversion.parse("13pm UTC to local"))
        XCTAssertNil(UnitConversion.parse("09:00 UTC+14:30 to UTC"))
        XCTAssertNil(UnitConversion.parse("09:00 UTC+5:90 to UTC"))
    }

    func testInlineUnitConverterActionCopiesResult() throws {
        var copiedResult = ""
        let action = try XCTUnwrap(InlineUnitConverter.makeAction(query: "  2 kg to lb  ") { result in
            copiedResult = result
        })

        XCTAssertEqual(action.id, "inline-unit-converter")
        XCTAssertEqual(action.title, "Convert: 4.40925 lb")
        XCTAssertEqual(action.subtitle, "2 kg = 4.40925 lb")
        XCTAssertEqual(action.isEnabled, true)
        XCTAssertEqual(action.canFavorite, false)

        action.run()
        XCTAssertEqual(copiedResult, "4.40925 lb")
    }

    func testInlineUnitConverterActionMatchesTypedQuery() throws {
        let action = try XCTUnwrap(InlineUnitConverter.makeAction(query: "10 km to miles") { _ in })

        XCTAssertEqual(
            CommandPaletteAction.filter([action], query: "10 km to miles").map(\.id),
            ["inline-unit-converter"]
        )
    }
}
