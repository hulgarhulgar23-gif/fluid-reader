import XCTest
@testable import FluidReader

final class LocalFilePathTests: XCTestCase {
    func testURLAcceptsExistingAbsolutePath() throws {
        let file = try makeTempFile()

        let url = try XCTUnwrap(LocalFilePath.url(from: "  \(file.path)  "))

        XCTAssertEqual(url.path, file.standardizedFileURL.path)
    }

    func testURLAcceptsQuotedFileURL() throws {
        let file = try makeTempFile(name: "Test File.txt")

        let url = try XCTUnwrap(LocalFilePath.url(from: "\"\(file.absoluteString)\""))

        XCTAssertEqual(url.path, file.standardizedFileURL.path)
    }

    func testNormalizedPathExpandsTilde() throws {
        let path = try XCTUnwrap(LocalFilePath.normalizedPath(from: "~/Desktop"))

        XCTAssertTrue(path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path))
        XCTAssertTrue(path.hasSuffix("/Desktop"))
    }

    func testURLRejectsMissingOrRelativePaths() {
        XCTAssertNil(LocalFilePath.url(from: "/tmp/FluidReaderMissing-\(UUID().uuidString)"))
        XCTAssertNil(LocalFilePath.url(from: "Sources/FluidReader/AppDelegate.swift"))
        XCTAssertNil(LocalFilePath.url(from: "one\n/two"))
    }

    func testMakeActionsOpenAndRevealPath() throws {
        let file = try makeTempFile()
        var openedURL: URL?
        var revealedURL: URL?

        let actions = LocalFilePath.makeActions(
            query: file.path,
            open: { openedURL = $0 },
            reveal: { revealedURL = $0 }
        )

        XCTAssertEqual(actions.map(\.id), ["inline-open-path", "inline-reveal-path"])
        XCTAssertEqual(actions.first?.title, "Open Path: Notes.txt")
        XCTAssertEqual(actions.first?.canFavorite, false)

        actions[0].run()
        actions[1].run()
        XCTAssertEqual(openedURL?.path, file.standardizedFileURL.path)
        XCTAssertEqual(revealedURL?.path, file.standardizedFileURL.path)
    }

    private func makeTempFile(name: String = "Notes.txt") throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderLocalFilePathTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(name)
        try "text".write(to: file, atomically: true, encoding: .utf8)
        return file
    }
}
