import XCTest
@testable import FluidReader

final class ResultExporterTests: XCTestCase {
    func testTextDocumentCleansTextAndBuildsFileName() throws {
        let document = try XCTUnwrap(ResultExportDocument.textDocument(
            text: "  Saved text  ",
            title: "Save Text",
            fileNamePrefix: "Saved text!"
        ))

        XCTAssertEqual(document.title, "Save Text")
        XCTAssertEqual(document.fileName, "saved-text.txt")
        XCTAssertEqual(document.allowedFileTypes, ["txt"])
        XCTAssertEqual(document.contents, "Saved text")
    }

    func testMarkdownDocumentIncludesAvailableSections() throws {
        let document = try XCTUnwrap(ResultExportDocument.markdownDocument(
            text: "Picked text",
            answer: "Short answer"
        ))

        XCTAssertEqual(document.allowedFileTypes, ["md"])
        XCTAssertTrue(document.fileName.hasSuffix(".md"))
        XCTAssertTrue(document.contents.contains("# Fluid Reader Result"))
        XCTAssertTrue(document.contents.contains("## Selected Text\n\nPicked text"))
        XCTAssertTrue(document.contents.contains("## Answer\n\nShort answer"))
    }

    func testMarkdownQuotePrefixesEachLine() throws {
        let quote = try XCTUnwrap(ResultExportDocument.markdownQuote(
            text: "  First line\n\nSecond line  "
        ))

        XCTAssertEqual(quote, "> First line\n>\n> Second line")
    }

    func testMarkdownCodeBlockWrapsText() throws {
        let block = try XCTUnwrap(ResultExportDocument.markdownCodeBlock(
            text: "  let value = 1\nprint(value)  "
        ))

        XCTAssertEqual(block, "```\nlet value = 1\nprint(value)\n```")
    }

    func testMarkdownCodeBlockUsesLongerFenceWhenNeeded() throws {
        let block = try XCTUnwrap(ResultExportDocument.markdownCodeBlock(
            text: "Before\n```swift\nlet value = 1\n```\nAfter"
        ))

        XCTAssertEqual(block, "````\nBefore\n```swift\nlet value = 1\n```\nAfter\n````")
    }

    func testMarkdownLinkUsesHostAndPathAsTitle() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/docs/start?ref=app"))
        let link = try XCTUnwrap(ResultExportDocument.markdownLink(url: url))

        XCTAssertEqual(link, "[example.com/docs/start](https://example.com/docs/start?ref=app)")
    }

    func testMarkdownLinkUsesHostForRootURL() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/"))
        let link = try XCTUnwrap(ResultExportDocument.markdownLink(url: url))

        XCTAssertEqual(link, "[example.com](https://example.com/)")
    }

    func testMarkdownLinkRejectsURLWithoutHost() throws {
        let url = try XCTUnwrap(URL(string: "file:///Users/tester/notes.txt"))

        XCTAssertNil(ResultExportDocument.markdownLink(url: url))
    }

    func testRecentItemsDocumentIncludesTextAndAnswers() throws {
        let items = [
            try XCTUnwrap(ReaderHistoryItem.make(text: "First picked text", answer: "First answer")),
            try XCTUnwrap(ReaderHistoryItem.make(text: "Second picked text"))
        ]

        let document = try XCTUnwrap(ResultExportDocument.recentItemsDocument(items))

        XCTAssertEqual(document.title, "Save Recent Items")
        XCTAssertEqual(document.fileName, "fluid-reader-recent-items.md")
        XCTAssertEqual(document.allowedFileTypes, ["md"])
        XCTAssertTrue(document.contents.contains("# Fluid Reader Recent Items"))
        XCTAssertTrue(document.contents.contains("## 1. First picked text"))
        XCTAssertTrue(document.contents.contains("### Text\n\nFirst picked text"))
        XCTAssertTrue(document.contents.contains("### Answer\n\nFirst answer"))
        XCTAssertTrue(document.contents.contains("## 2. Second picked text"))
    }

    func testSnippetsDocumentIncludesSavedText() throws {
        let items = [
            try XCTUnwrap(ReaderSnippetItem.make(text: "First saved snippet")),
            try XCTUnwrap(ReaderSnippetItem.make(text: "Second saved snippet"))
        ]

        let document = try XCTUnwrap(ResultExportDocument.snippetsDocument(items))

        XCTAssertEqual(document.title, "Save Snippets")
        XCTAssertEqual(document.fileName, "fluid-reader-snippets.md")
        XCTAssertEqual(document.allowedFileTypes, ["md"])
        XCTAssertTrue(document.contents.contains("# Fluid Reader Snippets"))
        XCTAssertTrue(document.contents.contains("## 1. First saved snippet"))
        XCTAssertTrue(document.contents.contains("First saved snippet"))
        XCTAssertTrue(document.contents.contains("## 2. Second saved snippet"))
    }

    func testQuickLinksDocumentIncludesSavedMarkdownLinks() throws {
        let items = [
            try XCTUnwrap(QuickLinkItem.make(urlString: "https://example.com/first", title: "First Link")),
            try XCTUnwrap(QuickLinkItem.make(urlString: "https://example.com/second", title: "Second Link"))
        ]

        let document = try XCTUnwrap(ResultExportDocument.quickLinksDocument(items))

        XCTAssertEqual(document.title, "Save Quick Links")
        XCTAssertEqual(document.fileName, "fluid-reader-quick-links.md")
        XCTAssertEqual(document.allowedFileTypes, ["md"])
        XCTAssertTrue(document.contents.contains("# Fluid Reader Quick Links"))
        XCTAssertTrue(document.contents.contains("## 1. First Link"))
        XCTAssertTrue(document.contents.contains("[First Link](https://example.com/first)"))
        XCTAssertTrue(document.contents.contains("## 2. Second Link"))
    }

    func testClipboardHistoryDocumentIncludesSavedText() throws {
        let items = [
            try XCTUnwrap(ClipboardHistoryItem.make(text: "First copied text")),
            try XCTUnwrap(ClipboardHistoryItem.make(text: "Second copied text"))
        ]

        let document = try XCTUnwrap(ResultExportDocument.clipboardHistoryDocument(items))

        XCTAssertEqual(document.title, "Save Clipboard History")
        XCTAssertEqual(document.fileName, "fluid-reader-clipboard-history.md")
        XCTAssertEqual(document.allowedFileTypes, ["md"])
        XCTAssertTrue(document.contents.contains("# Fluid Reader Clipboard History"))
        XCTAssertTrue(document.contents.contains("## 1. First copied text"))
        XCTAssertTrue(document.contents.contains("First copied text"))
        XCTAssertTrue(document.contents.contains("## 2. Second copied text"))
    }

    func testBlankDocumentsAreRejected() {
        XCTAssertNil(ResultExportDocument.textDocument(text: "  ", title: "Save", fileNamePrefix: "test"))
        XCTAssertNil(ResultExportDocument.markdownDocument(text: "  ", answer: "  "))
        XCTAssertNil(ResultExportDocument.markdownQuote(text: "  "))
        XCTAssertNil(ResultExportDocument.markdownCodeBlock(text: "  "))
        XCTAssertNil(ResultExportDocument.recentItemsDocument([]))
        XCTAssertNil(ResultExportDocument.snippetsDocument([]))
        XCTAssertNil(ResultExportDocument.quickLinksDocument([]))
        XCTAssertNil(ResultExportDocument.clipboardHistoryDocument([]))
    }

    func testImageDocumentBuildsPNGFile() throws {
        let data = Data([0x89, 0x50, 0x4E, 0x47])
        let document = try XCTUnwrap(ImageExportDocument.pngDocument(
            data: data,
            fileNamePrefix: "Marked Screenshot!"
        ))

        XCTAssertEqual(document.title, "Save Image")
        XCTAssertEqual(document.fileName, "marked-screenshot.png")
        XCTAssertEqual(document.allowedFileTypes, ["png"])
        XCTAssertEqual(document.data, data)
    }

    func testBlankImageDocumentsAreRejected() {
        XCTAssertNil(ImageExportDocument.pngDocument(data: nil))
        XCTAssertNil(ImageExportDocument.pngDocument(data: Data()))
    }

    func testFileNameFallsBackAndLimitsWords() {
        XCTAssertEqual(ResultExportDocument.fileName(from: " /! ", fallback: "fallback"), "fallback")
        XCTAssertEqual(
            ResultExportDocument.fileName(
                from: "One two three four five six seven eight nine ten",
                fallback: "fallback"
            ),
            "one-two-three-four-five-six-seven-eight"
        )
    }
}
