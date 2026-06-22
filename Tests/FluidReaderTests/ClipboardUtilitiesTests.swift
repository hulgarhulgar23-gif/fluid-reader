import XCTest
@testable import FluidReader

final class ClipboardUtilitiesTests: XCTestCase {
    func testUUIDStringIsLowercase() {
        let uuid = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

        XCTAssertEqual(
            ClipboardUtility.uuidString(uuid),
            "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        )
    }

    func testTimestampsUseStableFormats() {
        let date = Date(timeIntervalSince1970: 0)

        XCTAssertEqual(ClipboardUtility.isoTimestamp(date), "1970-01-01T00:00:00Z")
        XCTAssertEqual(
            ClipboardUtility.localISOTimestamp(date, timeZone: TimeZone(secondsFromGMT: 8 * 60 * 60)!),
            "1970-01-01T08:00:00+08:00"
        )
        XCTAssertEqual(
            ClipboardUtility.dateStamp(date, timeZone: TimeZone(secondsFromGMT: 0)!),
            "1970-01-01"
        )
        XCTAssertEqual(
            ClipboardUtility.dateTimeStamp(date, timeZone: TimeZone(secondsFromGMT: 0)!),
            "1970-01-01-0000"
        )
        XCTAssertEqual(ClipboardUtility.utcDateTimeStamp(date), "1970-01-01-0000")
        XCTAssertEqual(ClipboardUtility.unixTimestamp(date), "0")
    }

    func testTimeZoneSummaryIncludesOffset() {
        XCTAssertEqual(
            ClipboardUtility.timeZoneSummary(TimeZone(identifier: "Asia/Ulaanbaatar")!),
            "Asia/Ulaanbaatar UTC+08:00"
        )
        XCTAssertEqual(
            ClipboardUtility.timeZoneSummary(TimeZone(secondsFromGMT: -5 * 60 * 60)!),
            "GMT-0500 UTC-05:00"
        )
        XCTAssertEqual(
            ClipboardUtility.timeZoneOffset(TimeZone(secondsFromGMT: 9 * 60 * 60 + 30 * 60)!),
            "UTC+09:30"
        )
    }

    func testRelativeDateStampsUseCalendarDays() {
        let date = Date(timeIntervalSince1970: 0)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(
            ClipboardUtility.relativeDateStamp(days: -1, from: date, timeZone: timeZone),
            "1969-12-31"
        )
        XCTAssertEqual(
            ClipboardUtility.relativeDateStamp(days: 1, from: date, timeZone: timeZone),
            "1970-01-02"
        )
    }

    func testWeekDateStampsUseMondayAndSunday() {
        let date = Date(timeIntervalSince1970: 6 * 24 * 60 * 60)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(
            ClipboardUtility.weekStartDateStamp(date, timeZone: timeZone),
            "1970-01-05"
        )
        XCTAssertEqual(
            ClipboardUtility.weekEndDateStamp(date, timeZone: timeZone),
            "1970-01-11"
        )
    }

    func testMonthDateStampsUseFirstAndLastDay() {
        let date = Date(timeIntervalSince1970: 6 * 24 * 60 * 60)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(
            ClipboardUtility.monthStartDateStamp(date, timeZone: timeZone),
            "1970-01-01"
        )
        XCTAssertEqual(
            ClipboardUtility.monthEndDateStamp(date, timeZone: timeZone),
            "1970-01-31"
        )
    }

    func testQuarterDateStampsUseFirstAndLastDay() {
        let date = Date(timeIntervalSince1970: 6 * 24 * 60 * 60)
        let timeZone = TimeZone(secondsFromGMT: 0)!

        XCTAssertEqual(
            ClipboardUtility.quarterStartDateStamp(date, timeZone: timeZone),
            "1970-01-01"
        )
        XCTAssertEqual(
            ClipboardUtility.quarterEndDateStamp(date, timeZone: timeZone),
            "1970-03-31"
        )
    }

    func testURLEncodeAndDecode() throws {
        XCTAssertEqual(
            ClipboardUtility.urlEncode(" hello world/@? "),
            "hello%20world%2F%40%3F"
        )
        XCTAssertEqual(
            ClipboardUtility.urlDecode("hello%20world+now"),
            "hello world now"
        )
        XCTAssertNil(ClipboardUtility.urlEncode("  "))
        XCTAssertNil(ClipboardUtility.urlDecode("  "))
    }

    func testCleanURLRemovesTrackingParameters() {
        XCTAssertEqual(
            ClipboardUtility.cleanURL("https://example.com/path?utm_source=news&keep=1&fbclid=abc#part"),
            "https://example.com/path?keep=1#part"
        )
        XCTAssertEqual(
            ClipboardUtility.cleanURL("example.com/docs?utm_campaign=sale"),
            "https://example.com/docs"
        )
        XCTAssertEqual(
            ClipboardUtility.cleanURL("https://example.com/path?keep=1"),
            "https://example.com/path?keep=1"
        )
        XCTAssertNil(ClipboardUtility.cleanURL("not a url"))
        XCTAssertNil(ClipboardUtility.cleanURL("mailto:hello@example.com"))
    }

    func testCleanURLPreservesEncodedPlusInRemainingParameters() {
        // Stripping tracking params must not decode "%2B" to "+": for a
        // form-encoded server "a+b" means "a b", so the URL's meaning changes.
        XCTAssertEqual(
            ClipboardUtility.cleanURL("https://example.com/search?q=a%2Bb&utm_source=news"),
            "https://example.com/search?q=a%2Bb"
        )
    }

    func testCleanURLRejectsEmbeddedCredentials() {
        // "apple.com@evil.com" visually looks trusted while actually opening
        // evil.com. Cleaning should reject this pattern entirely.
        XCTAssertNil(ClipboardUtility.cleanURL("https://apple.com@evil.com/login?utm_source=news"))
        XCTAssertNil(ClipboardUtility.cleanURL("https://user:pass@example.com/path"))
    }

    func testExtractURLsFromText() {
        let text = """
        Read https://example.com/a?utm_source=news&keep=1.
        Then open <docs.example.com/start> and https://example.com/a?keep=1 again.
        Markdown: [status](https://status.example.org/now). Email: hello@example.net.
        """

        XCTAssertEqual(
            ClipboardUtility.extractURLs(text),
            "https://example.com/a?keep=1\nhttps://docs.example.com/start\nhttps://status.example.org/now"
        )
        XCTAssertNil(ClipboardUtility.extractURLs("no links here"))
        XCTAssertNil(ClipboardUtility.extractURLs("   "))
    }

    func testExtractDomainsFromText() {
        let text = """
        See https://Example.com/a?keep=1 and <docs.example.com/start>.
        Again: https://example.com/other. Email: hello@example.net.
        """

        XCTAssertEqual(
            ClipboardUtility.extractDomains(text),
            "example.com\ndocs.example.com"
        )
        XCTAssertNil(ClipboardUtility.extractDomains("hello@example.com only"))
        XCTAssertNil(ClipboardUtility.extractDomains("   "))
    }

    func testExtractEmailsFromText() {
        let text = """
        Support: <Hello@Example.com>, bugs+ios@example.org.
        Mailto: mailto:hello@example.com. Site: example.com and https://example.com.
        """

        XCTAssertEqual(
            ClipboardUtility.extractEmails(text),
            "hello@example.com\nbugs+ios@example.org"
        )
        XCTAssertNil(ClipboardUtility.extractEmails("docs.example.com has no email"))
        XCTAssertNil(ClipboardUtility.extractEmails("   "))
    }

    func testBase64EncodeAndDecode() {
        XCTAssertEqual(ClipboardUtility.base64Encode("hello"), "aGVsbG8=")
        XCTAssertEqual(ClipboardUtility.base64Decode(" aGVs\nbG8= "), "hello")
        XCTAssertNil(ClipboardUtility.base64Encode("  "))
        XCTAssertNil(ClipboardUtility.base64Decode("not base64"))
    }

    func testPrettyJSON() throws {
        let output = try XCTUnwrap(ClipboardUtility.prettyJSON("{\"b\":2,\"a\":1}"))

        XCTAssertTrue(output.contains("\"a\" : 1"))
        XCTAssertTrue(output.contains("\"b\" : 2"))
        XCTAssertEqual(
            ClipboardUtility.minifyJSON("{\n  \"b\" : 2,\n  \"a\" : 1\n}"),
            "{\"a\":1,\"b\":2}"
        )
        XCTAssertNil(ClipboardUtility.prettyJSON("not json"))
        XCTAssertNil(ClipboardUtility.minifyJSON("not json"))
    }

    func testSlugify() {
        XCTAssertEqual(ClipboardUtility.slugify(" Hello, Cafe World! "), "hello-cafe-world")
        XCTAssertEqual(ClipboardUtility.slugify("A/B_test 2026"), "a-b-test-2026")
        XCTAssertEqual(ClipboardUtility.snakeCasedText(" Hello, Cafe World! "), "hello_cafe_world")
        XCTAssertEqual(ClipboardUtility.constantCasedText(" Hello, Cafe World! "), "HELLO_CAFE_WORLD")
        XCTAssertEqual(ClipboardUtility.camelCasedText(" Hello, Cafe World! "), "helloCafeWorld")
        XCTAssertEqual(ClipboardUtility.pascalCasedText(" Hello, Cafe World! "), "HelloCafeWorld")
        XCTAssertNil(ClipboardUtility.slugify(" --- "))
        XCTAssertNil(ClipboardUtility.snakeCasedText(" --- "))
        XCTAssertNil(ClipboardUtility.constantCasedText(" --- "))
        XCTAssertNil(ClipboardUtility.camelCasedText(" --- "))
        XCTAssertNil(ClipboardUtility.pascalCasedText(" --- "))
    }

    func testCaseTransforms() {
        XCTAssertEqual(ClipboardUtility.uppercasedText("  Hello World  "), "HELLO WORLD")
        XCTAssertEqual(ClipboardUtility.lowercasedText("  Hello World  "), "hello world")
        XCTAssertEqual(ClipboardUtility.titleCasedText("  hello world  "), "Hello World")
        XCTAssertEqual(ClipboardUtility.singleSpacedText("  hello   world\nagain\t now  "), "hello world again now")
        XCTAssertNil(ClipboardUtility.uppercasedText("  "))
        XCTAssertNil(ClipboardUtility.lowercasedText("  "))
        XCTAssertNil(ClipboardUtility.titleCasedText("  "))
        XCTAssertNil(ClipboardUtility.singleSpacedText("  \n\t  "))
    }

    func testStripANSI() {
        let coloredText = "\u{001B}[31merror\u{001B}[0m\n\u{001B}[1;32mok\u{001B}[0m"

        XCTAssertEqual(ClipboardUtility.stripANSI(coloredText), "error\nok")
        XCTAssertEqual(ClipboardUtility.stripANSI(" plain log "), "plain log")
        XCTAssertEqual(ClipboardUtility.stripANSI("log \u{001B}x done"), "log \u{001B}x done")
        XCTAssertNil(ClipboardUtility.stripANSI("\u{001B}[0m"))
        XCTAssertNil(ClipboardUtility.stripANSI("  "))
    }

    func testLineTransforms() {
        let text = "\n  banana  \napple\nbanana\n  carrot  \n"

        XCTAssertEqual(ClipboardUtility.trimmedLines(text), "banana\napple\nbanana\ncarrot")
        XCTAssertEqual(ClipboardUtility.trimmedLines("one\n\n two \n \nthree"), "one\ntwo\nthree")
        XCTAssertEqual(ClipboardUtility.joinedLines(text), "banana apple banana carrot")
        XCTAssertEqual(ClipboardUtility.reversedLines(text), "carrot\nbanana\napple\nbanana")
        XCTAssertEqual(ClipboardUtility.sortedLines(text), "apple\nbanana\nbanana\ncarrot")
        XCTAssertEqual(ClipboardUtility.uniqueLines(text), "banana\napple\ncarrot")
        XCTAssertEqual(
            ClipboardUtility.markdownChecklist(text),
            "- [ ] banana\n- [ ] apple\n- [ ] banana\n- [ ] carrot"
        )
        XCTAssertEqual(
            ClipboardUtility.markdownBullets(text),
            "- banana\n- apple\n- banana\n- carrot"
        )
        XCTAssertEqual(
            ClipboardUtility.markdownNumberedList(text),
            "1. banana\n2. apple\n3. banana\n4. carrot"
        )
        XCTAssertNil(ClipboardUtility.trimmedLines(" \n \n "))
        XCTAssertNil(ClipboardUtility.joinedLines(" \n \n "))
        XCTAssertNil(ClipboardUtility.reversedLines(" \n \n "))
        XCTAssertNil(ClipboardUtility.sortedLines(" \n \n "))
        XCTAssertNil(ClipboardUtility.uniqueLines(" \n \n "))
        XCTAssertNil(ClipboardUtility.markdownChecklist(" \n \n "))
        XCTAssertNil(ClipboardUtility.markdownBullets(" \n \n "))
        XCTAssertNil(ClipboardUtility.markdownNumberedList(" \n \n "))
    }

    func testMarkdownTable() {
        XCTAssertEqual(
            ClipboardUtility.markdownTable("Name,Count\nTea,2\nCoffee,3"),
            """
            | Name | Count |
            | --- | --- |
            | Tea | 2 |
            | Coffee | 3 |
            """
        )
        XCTAssertEqual(
            ClipboardUtility.markdownTable("Name\tCount\nTea\t2"),
            """
            | Name | Count |
            | --- | --- |
            | Tea | 2 |
            """
        )
        XCTAssertEqual(
            ClipboardUtility.markdownTable("Name,Note\nTea,A|B"),
            """
            | Name | Note |
            | --- | --- |
            | Tea | A\\|B |
            """
        )
        XCTAssertNil(ClipboardUtility.markdownTable("just text"))
        XCTAssertNil(ClipboardUtility.markdownTable("Name,Count\nTea"))
    }

    func testCleanCSV() {
        XCTAssertEqual(
            ClipboardUtility.cleanCSV(" Name , Count \n Tea , 2 \n Coffee , 3 "),
            "Name,Count\nTea,2\nCoffee,3"
        )
        XCTAssertEqual(
            ClipboardUtility.cleanCSV("Name\tNote\nTea\tA,B\nCoffee\tSays \"hi\""),
            "Name,Note\nTea,\"A,B\"\nCoffee,\"Says \"\"hi\"\"\""
        )
        XCTAssertEqual(ClipboardUtility.cleanCSV("Name,Count"), "Name,Count")
        XCTAssertNil(ClipboardUtility.cleanCSV("just text"))
        XCTAssertNil(ClipboardUtility.cleanCSV("Name,Count\nTea"))
    }

    func testTextStats() {
        XCTAssertEqual(
            ClipboardUtility.textStats("  one two\nthree  "),
            "2 lines, 3 words, 13 characters"
        )
        XCTAssertEqual(ClipboardUtility.textStats("word"), "1 line, 1 word, 4 characters")
        XCTAssertNil(ClipboardUtility.textStats("  "))
    }
}
