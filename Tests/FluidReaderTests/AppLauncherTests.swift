import XCTest
@testable import FluidReader

final class AppLauncherTests: XCTestCase {
    func testAppLaunchItemBuildsNameAndStableID() throws {
        let item = try XCTUnwrap(AppLaunchItem.make(url: URL(fileURLWithPath: "/Applications/My App.app")))

        XCTAssertEqual(item.name, "My App")
        XCTAssertEqual(item.id, "myapp")
        XCTAssertNil(AppLaunchItem.make(url: URL(fileURLWithPath: "/Applications/Notes.txt")))
    }

    func testCatalogLoadsSortedDedupedApps() throws {
        let root = try makeTempDirectory()
        let firstFolder = root.appendingPathComponent("First", isDirectory: true)
        let secondFolder = root.appendingPathComponent("Second", isDirectory: true)
        try FileManager.default.createDirectory(at: firstFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: firstFolder.appendingPathComponent("Beta.app", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: firstFolder.appendingPathComponent("Alpha.app", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: secondFolder.appendingPathComponent("Alpha.app", isDirectory: true),
            withIntermediateDirectories: true
        )
        try "ignore".write(
            to: firstFolder.appendingPathComponent("Readme.txt"),
            atomically: true,
            encoding: .utf8
        )

        let items = AppLaunchCatalog.load(folders: [firstFolder, secondFolder], limit: 10)

        XCTAssertEqual(items.map(\.name), ["Alpha", "Beta"])
    }

    func testCatalogAppliesLimit() throws {
        let root = try makeTempDirectory()
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("One.app", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("Two.app", isDirectory: true),
            withIntermediateDirectories: true
        )

        let items = AppLaunchCatalog.load(folders: [root], limit: 1)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.name, "One")
    }

    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("FluidReaderAppLauncherTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
