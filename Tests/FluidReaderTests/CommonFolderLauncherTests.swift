import XCTest
@testable import FluidReader

final class CommonFolderLauncherTests: XCTestCase {
    func testDefaultItemsUseStableNamesAndHomePaths() {
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)
        let items = CommonFolderCatalog.defaultItems(homeDirectory: home)

        XCTAssertEqual(items.map(\.id), [
            "downloads",
            "documents",
            "desktop",
            "home",
            "applications",
            "utilities"
        ])
        XCTAssertEqual(items.first?.title, "Downloads")
        XCTAssertEqual(items.first?.url.path, "/Users/tester/Downloads")
        XCTAssertEqual(items.first?.commandTitle, "Open Folder: Downloads")
        XCTAssertEqual(items.first?.subtitle, "Open Downloads in Finder")
    }

    func testLoadKeepsOnlyExistingFolders() throws {
        let root = try makeTempDirectory()
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        let missing = root.appendingPathComponent("Missing", isDirectory: true)
        let textFile = root.appendingPathComponent("Notes.txt")
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try "text".write(to: textFile, atomically: true, encoding: .utf8)

        let items = [
            CommonFolderItem(id: "downloads", title: "Downloads", url: downloads, keywords: []),
            CommonFolderItem(id: "missing", title: "Missing", url: missing, keywords: []),
            CommonFolderItem(id: "file", title: "File", url: textFile, keywords: [])
        ]

        XCTAssertEqual(CommonFolderCatalog.load(items: items).map(\.id), ["downloads"])
    }

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderCommonFolderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
