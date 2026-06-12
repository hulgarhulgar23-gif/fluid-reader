import XCTest
@testable import FluidReader

final class InlineColorConverterTests: XCTestCase {
    func testParseColorFormats() throws {
        let orange = try XCTUnwrap(ColorConversion.parse("#ff8800"))
        XCTAssertEqual(orange.hex, "#FF8800")
        XCTAssertEqual(orange.rgb, "rgb(255, 136, 0)")
        XCTAssertEqual(orange.hsl, "hsl(32, 100%, 50%)")

        XCTAssertEqual(ColorConversion.parse("#369")?.hex, "#336699")
        XCTAssertEqual(ColorConversion.parse("hex 336699")?.rgb, "rgb(51, 102, 153)")
        XCTAssertEqual(ColorConversion.parse("color #336699")?.hsl, "hsl(210, 50%, 40%)")
        XCTAssertEqual(ColorConversion.parse("rgb(255, 136, 0)")?.hex, "#FF8800")
        XCTAssertEqual(ColorConversion.parse("rgb 51 102 153")?.hex, "#336699")
        XCTAssertEqual(ColorConversion.parse("hsl(210, 50%, 40%)")?.hex, "#336699")
        XCTAssertEqual(ColorConversion.parse("hsl 0 0 50")?.rgb, "rgb(128, 128, 128)")
    }

    func testParseRejectsInvalidColorInput() {
        XCTAssertNil(ColorConversion.parse("read selected text"))
        XCTAssertNil(ColorConversion.parse("336699"))
        XCTAssertNil(ColorConversion.parse("#12"))
        XCTAssertNil(ColorConversion.parse("#xyzxyz"))
        XCTAssertNil(ColorConversion.parse("rgb(255, 0)"))
        XCTAssertNil(ColorConversion.parse("rgb(256, 0, 0)"))
        XCTAssertNil(ColorConversion.parse("hsl(210, 50%)"))
        XCTAssertNil(ColorConversion.parse("hsl(210, 101%, 40%)"))
    }

    func testInlineColorConverterActionCopiesSummary() throws {
        var copiedResult = ""
        let action = try XCTUnwrap(InlineColorConverter.makeAction(query: "#336699") { result in
            copiedResult = result
        })

        XCTAssertEqual(action.id, "inline-color-converter")
        XCTAssertEqual(action.title, "Color: #336699")
        XCTAssertEqual(action.subtitle, "rgb(51, 102, 153) | hsl(210, 50%, 40%)")
        XCTAssertEqual(action.isEnabled, true)
        XCTAssertEqual(action.canFavorite, false)

        action.run()
        XCTAssertEqual(copiedResult, "#336699\nrgb(51, 102, 153)\nhsl(210, 50%, 40%)")
    }

    func testInlineColorConverterActionMatchesTypedQuery() throws {
        let action = try XCTUnwrap(InlineColorConverter.makeAction(query: "hsl(210, 50%, 40%)") { _ in })

        XCTAssertEqual(
            CommandPaletteAction.filter([action], query: "hsl 210 50 40").map(\.id),
            ["inline-color-converter"]
        )
    }
}
