import XCTest
@testable import FluidReader

final class InlineCalculatorTests: XCTestCase {
    func testEvaluateBasicMath() throws {
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("2 + 3 * 4")).result, "14")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("=(2 + 3) * 4")).result, "20")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("6 ÷ 4")).result, "1.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("2^3")).result, "8")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("10 % 4")).result, "2")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("1,000 + 2")).result, "1002")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("sqrt(81)")).result, "9")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("√81")).result, "9")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("pi * 2")).result, "6.28318530718")
    }

    func testEvaluateConversationalMathQueries() throws {
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("what is 2 + 3 * 4?")).result, "14")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("calculate sqrt(81)")).result, "9")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("calc 1,000 + 2")).result, "1002")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("what is 20% of 85?")).result, "17")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("roi 1200 1000")).result, "20%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("calc margin 100 75")).result, "25%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("markup 125 100")).result, "25%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("calculate cagr 100 121 2")).result, "10%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("breakeven 10000 50 30")).result, "500")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("ltv 75 18")).result, "1350")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("cac 12000 80")).result, "150")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("runway 240000 12000")).result, "20")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("payback 900 75")).result, "12")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("ltvcac 1350 150")).result, "9")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("burnmultiple 120000 240000")).result, "0.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("gross margin 100 75")).result, "25%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("break even 10000 50 30")).result, "500")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("runway months 240000 12000")).result, "20")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("cac payback 900 75")).result, "12")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("payback period 900 75")).result, "12")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("ltv/cac 1350 150")).result, "9")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("burn multiple 120000 240000")).result, "0.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("net burn multiple 120000 240000")).result, "0.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("customer acquisition cost 12000 80")).result, "150")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("lifetime value 75 18")).result, "1350")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("nrr 1000 200 100 50")).result, "105%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("net revenue retention 1000 200 100 50")).result, "105%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("quickratio 120 30 50 10")).result, "2.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("quick ratio 120 30 50 10")).result, "2.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("magicnumber 250000 400000")).result, "2.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("magic number 250000 400000")).result, "2.5")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("rule40 35 10")).result, "45%")
        XCTAssertEqual(try XCTUnwrap(CalculatorExpression.evaluate("rule of 40 35 10")).result, "45%")
    }

    func testEvaluateRejectsNonMathAndInvalidMath() {
        XCTAssertNil(CalculatorExpression.evaluate("read selected text"))
        XCTAssertNil(CalculatorExpression.evaluate("gpt-4"))
        XCTAssertNil(CalculatorExpression.evaluate("what is gpt-4?"))
        XCTAssertNil(CalculatorExpression.evaluate("1 / 0"))
        XCTAssertNil(CalculatorExpression.evaluate("2 +"))
        XCTAssertNil(CalculatorExpression.evaluate("sqrt(-1)"))
        XCTAssertNil(CalculatorExpression.evaluate("="))
        XCTAssertNil(CalculatorExpression.evaluate("20% of apples"))
        XCTAssertNil(CalculatorExpression.evaluate("80 after 20% off"))
        XCTAssertNil(CalculatorExpression.evaluate("split 120 among 3"))
        XCTAssertNil(CalculatorExpression.evaluate("roi 100 0"))
        XCTAssertNil(CalculatorExpression.evaluate("cagr 100 121 0"))
        XCTAssertNil(CalculatorExpression.evaluate("cagr -100 121 2"))
        XCTAssertNil(CalculatorExpression.evaluate("breakeven 10000 20 20"))
        XCTAssertNil(CalculatorExpression.evaluate("runway 240000 0"))
        XCTAssertNil(CalculatorExpression.evaluate("runway maybe 240000 12000"))
        XCTAssertNil(CalculatorExpression.evaluate("payback 900 0"))
        XCTAssertNil(CalculatorExpression.evaluate("burn multiple 120000 now"))
        XCTAssertNil(CalculatorExpression.evaluate("ltvcac 1350 0"))
        XCTAssertNil(CalculatorExpression.evaluate("burnmultiple 120000 0"))
        XCTAssertNil(CalculatorExpression.evaluate("ltv 75 -1"))
        XCTAssertNil(CalculatorExpression.evaluate("cac 12000 0"))
        XCTAssertNil(CalculatorExpression.evaluate("nrr 0 200 100 50"))
        XCTAssertNil(CalculatorExpression.evaluate("quick ratio 120 30 0 0"))
        XCTAssertNil(CalculatorExpression.evaluate("magic number 250000 0"))
        XCTAssertNil(CalculatorExpression.evaluate("rule of 40 growth 10"))
        XCTAssertNil(CalculatorExpression.evaluate("targetprice 80 25"))
    }

    func testInlineCalculatorActionCopiesResult() throws {
        var copiedResult = ""
        let action = try XCTUnwrap(InlineCalculator.makeAction(query: "  2 + 2  ") { result in
            copiedResult = result
        })

        XCTAssertEqual(action.id, "inline-calculator")
        XCTAssertEqual(action.title, "Calculate: 4")
        XCTAssertEqual(action.subtitle, "2 + 2 = 4")
        XCTAssertEqual(action.isEnabled, true)
        XCTAssertEqual(action.canFavorite, false)

        action.run()
        XCTAssertEqual(copiedResult, "4")
    }
}
