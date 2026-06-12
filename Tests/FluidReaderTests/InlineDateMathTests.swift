import XCTest
@testable import FluidReader

final class InlineDateMathTests: XCTestCase {
    func testParseSpecialDateWords() throws {
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 7, hour: 10, minute: 30))

        XCTAssertEqual(
            DateCalc.parse("today", now: now, calendar: calendar),
            DateCalc(source: "today", result: "2026-06-07")
        )
        XCTAssertEqual(
            DateCalc.parse("tomorrow", now: now, calendar: calendar),
            DateCalc(source: "tomorrow", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("yesterday", now: now, calendar: calendar),
            DateCalc(source: "yesterday", result: "2026-06-06")
        )
        XCTAssertEqual(
            DateCalc.parse("next business day", now: now, calendar: calendar),
            DateCalc(source: "next business day", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("next business week", now: now, calendar: calendar),
            DateCalc(source: "next business week", result: "2026-06-08")
        )
    }

    func testParseRelativeDateMath() throws {
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 7, hour: 10, minute: 30))

        XCTAssertEqual(
            DateCalc.parse("in 3 days", now: now, calendar: calendar),
            DateCalc(source: "in 3 days", result: "2026-06-10")
        )
        XCTAssertEqual(
            DateCalc.parse("2 weeks from now", now: now, calendar: calendar),
            DateCalc(source: "2 weeks from now", result: "2026-06-21")
        )
        XCTAssertEqual(
            DateCalc.parse("in 3d", now: now, calendar: calendar),
            DateCalc(source: "in 3d", result: "2026-06-10")
        )
        XCTAssertEqual(
            DateCalc.parse("2w from now", now: now, calendar: calendar),
            DateCalc(source: "2w from now", result: "2026-06-21")
        )
        XCTAssertEqual(
            DateCalc.parse("in 2 business days", now: now, calendar: calendar),
            DateCalc(source: "in 2 business days", result: "2026-06-09")
        )
        XCTAssertEqual(
            DateCalc.parse("in 2bd", now: now, calendar: calendar),
            DateCalc(source: "in 2bd", result: "2026-06-09")
        )
    }

    func testParseNamedDateTargets() throws {
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 7, hour: 10, minute: 30))

        XCTAssertEqual(
            DateCalc.parse("next monday", now: now, calendar: calendar),
            DateCalc(source: "next monday", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("next friday", now: now, calendar: calendar),
            DateCalc(source: "next friday", result: "2026-06-12")
        )
        XCTAssertEqual(
            DateCalc.parse("this monday", now: now, calendar: calendar),
            DateCalc(source: "this monday", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("monday", now: now, calendar: calendar),
            DateCalc(source: "monday", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("friday", now: now, calendar: calendar),
            DateCalc(source: "friday", result: "2026-06-12")
        )
        XCTAssertEqual(
            DateCalc.parse("start of week", now: now, calendar: calendar),
            DateCalc(source: "start of week", result: "2026-06-01")
        )
        XCTAssertEqual(
            DateCalc.parse("end of week", now: now, calendar: calendar),
            DateCalc(source: "end of week", result: "2026-06-07")
        )
        XCTAssertEqual(
            DateCalc.parse("start of quarter", now: now, calendar: calendar),
            DateCalc(source: "start of quarter", result: "2026-04-01")
        )
        XCTAssertEqual(
            DateCalc.parse("end of quarter", now: now, calendar: calendar),
            DateCalc(source: "end of quarter", result: "2026-06-30")
        )
        XCTAssertEqual(
            DateCalc.parse("start of year", now: now, calendar: calendar),
            DateCalc(source: "start of year", result: "2026-01-01")
        )
        XCTAssertEqual(
            DateCalc.parse("end of year", now: now, calendar: calendar),
            DateCalc(source: "end of year", result: "2026-12-31")
        )
    }

    func testParseConversationalDateQueries() throws {
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 7, hour: 10, minute: 30))

        XCTAssertEqual(
            DateCalc.parse("when is next monday?", now: now, calendar: calendar),
            DateCalc(source: "next monday", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("what date is end of quarter?", now: now, calendar: calendar),
            DateCalc(source: "end of quarter", result: "2026-06-30")
        )
        XCTAssertEqual(
            DateCalc.parse("date in 3 days", now: now, calendar: calendar),
            DateCalc(source: "in 3 days", result: "2026-06-10")
        )
    }

    func testParseWeekdayModesDuringMidweek() throws {
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0))

        XCTAssertEqual(
            DateCalc.parse("this monday", now: now, calendar: calendar),
            DateCalc(source: "this monday", result: "2026-06-08")
        )
        XCTAssertEqual(
            DateCalc.parse("monday", now: now, calendar: calendar),
            DateCalc(source: "monday", result: "2026-06-15")
        )
        XCTAssertEqual(
            DateCalc.parse("next monday", now: now, calendar: calendar),
            DateCalc(source: "next monday", result: "2026-06-15")
        )
        XCTAssertEqual(
            DateCalc.parse("this wednesday", now: now, calendar: calendar),
            DateCalc(source: "this wednesday", result: "2026-06-10")
        )
    }

    func testParseBusinessDaysSkipsWeekend() throws {
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 12, hour: 9, minute: 0))

        XCTAssertEqual(
            DateCalc.parse("in 1 business day", now: now, calendar: calendar),
            DateCalc(source: "in 1 business day", result: "2026-06-15")
        )
        XCTAssertEqual(
            DateCalc.parse("2 business days from now", now: now, calendar: calendar),
            DateCalc(source: "2 business days from now", result: "2026-06-16")
        )
        XCTAssertEqual(
            DateCalc.parse("next business day", now: now, calendar: calendar),
            DateCalc(source: "next business day", result: "2026-06-15")
        )
        XCTAssertEqual(
            DateCalc.parse("next business week", now: now, calendar: calendar),
            DateCalc(source: "next business week", result: "2026-06-15")
        )
    }

    func testParseRejectsInvalidDateMath() {
        XCTAssertNil(DateCalc.parse("read selected text", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in -3 days", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in 2 minutes", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in 2m", calendar: calendar))
        XCTAssertNil(DateCalc.parse("2026-06-07 + 2d", calendar: calendar))
        XCTAssertNil(DateCalc.parse("next someday", calendar: calendar))
        XCTAssertNil(DateCalc.parse("start of season", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in 1 month", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in 1 year", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in 1mo", calendar: calendar))
        XCTAssertNil(DateCalc.parse("in 1y", calendar: calendar))
        XCTAssertNil(DateCalc.parse("fri", calendar: calendar))
        XCTAssertNil(DateCalc.parse("start of month", calendar: calendar))
        XCTAssertNil(DateCalc.parse("end of month", calendar: calendar))
        XCTAssertNil(DateCalc.parse("this business week", calendar: calendar))
        XCTAssertNil(DateCalc.parse("start of business week", calendar: calendar))
        XCTAssertNil(DateCalc.parse("end of business week", calendar: calendar))
    }

    func testInlineDateMathActionCopiesDate() throws {
        var copiedResult = ""
        let now = try XCTUnwrap(makeDate(year: 2026, month: 6, day: 7, hour: 10, minute: 30))
        let action = try XCTUnwrap(InlineDate.makeAction(query: "in 2 days", now: now, calendar: calendar) { result in
            copiedResult = result
        })

        XCTAssertEqual(action.id, "inline-date-math")
        XCTAssertEqual(action.title, "Date: 2026-06-09")
        XCTAssertEqual(action.subtitle, "in 2 days = 2026-06-09")
        XCTAssertEqual(action.isEnabled, true)
        XCTAssertEqual(action.canFavorite, false)

        action.run()
        XCTAssertEqual(copiedResult, "2026-06-09")
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) -> Date? {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }
}
