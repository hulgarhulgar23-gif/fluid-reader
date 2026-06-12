import XCTest
@testable import FluidReader

final class WebSearchTests: XCTestCase {
    func testSearchURLUsesDuckDuckGoAndEncodesQuery() throws {
        let url = try XCTUnwrap(WebSearch.searchURL(for: "  swift appkit  "))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "duckduckgo.com")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "q", value: "swift appkit")])
    }

    func testWebURLNormalizesPlainDomains() throws {
        let url = try XCTUnwrap(WebSearch.webURL(from: "example.com/docs"))

        XCTAssertEqual(url.absoluteString, "https://example.com/docs")
    }

    func testWebURLRejectsSearchText() {
        XCTAssertNil(WebSearch.webURL(from: "swift appkit"))
    }

    func testWebURLRejectsDottedNumbers() {
        XCTAssertNil(WebSearch.webURL(from: "3.14"))
        XCTAssertNil(WebSearch.webURL(from: "1.2.3"))
        XCTAssertNil(WebSearch.webURL(from: "127.0.0.1"))
    }

    func testMakeActionOpensSearchURL() throws {
        var openedURL: URL?
        let action = try XCTUnwrap(WebSearch.makeAction(query: "swift appkit") { url in
            openedURL = url
        })

        XCTAssertEqual(action.id, "inline-web-search")
        XCTAssertEqual(action.title, "Search Web: swift appkit")
        XCTAssertEqual(action.canFavorite, false)

        action.run()
        XCTAssertEqual(openedURL?.host, "duckduckgo.com")
    }

    func testMakeActionOpensTypedURL() throws {
        var openedURL: URL?
        let action = try XCTUnwrap(WebSearch.makeAction(query: "example.com/docs") { url in
            openedURL = url
        })

        XCTAssertEqual(action.id, "inline-open-url")
        XCTAssertEqual(action.title, "Open URL: example.com/docs")

        action.run()
        XCTAssertEqual(openedURL?.absoluteString, "https://example.com/docs")
    }

    func testMakeCleanURLActionCopiesCleanURL() throws {
        var copiedURL = ""
        let action = try XCTUnwrap(WebSearch.makeCleanURLAction(query: "example.com/docs?utm_source=news&keep=1") { url in
            copiedURL = url
        })

        XCTAssertEqual(action.id, "inline-clean-url")
        XCTAssertEqual(action.title, "Clean URL: https://example.com/docs?keep=1")
        XCTAssertEqual(action.subtitle, "Copy without tracking")
        XCTAssertEqual(action.canFavorite, false)

        action.run()
        XCTAssertEqual(copiedURL, "https://example.com/docs?keep=1")
    }

    func testMakeCleanURLActionSkipsAlreadyCleanURL() {
        XCTAssertNil(WebSearch.makeCleanURLAction(query: "example.com/docs?keep=1", copy: { _ in }))
        XCTAssertNil(WebSearch.makeCleanURLAction(query: "swift appkit", copy: { _ in }))
    }

    func testMarkdownLinkBuildsMarkdownLinkFromTypedURL() {
        XCTAssertEqual(
            WebSearch.markdownLink(from: "example.com/docs"),
            "[example.com/docs](https://example.com/docs)"
        )
    }

    func testMarkdownLinkSkipsNonURLText() {
        XCTAssertNil(WebSearch.markdownLink(from: "swift appkit"))
    }

    func testMakeActionSkipsShortText() {
        XCTAssertNil(WebSearch.makeAction(query: " a ", open: { _ in }))
    }

    func testInlineWebSearchDoesNotBeatStrongCommandMatch() throws {
        let readAction = CommandPaletteAction(
            id: "read",
            title: "Read Selected Text",
            subtitle: "Use selected text",
            systemImage: "text.cursor",
            run: {}
        )
        let searchAction = try XCTUnwrap(WebSearch.makeAction(query: "read", open: { _ in }))

        XCTAssertEqual(CommandPaletteAction.filter([readAction, searchAction], query: "read").map(\.id), [
            "read",
            "inline-web-search"
        ])
    }
}
