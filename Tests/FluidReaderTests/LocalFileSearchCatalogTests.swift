import XCTest
@testable import FluidReader

final class LocalFileSearchCatalogTests: XCTestCase {
    func testLoadIndexesVisibleFilesFromRoots() throws {
        let root = try makeTempDirectory(name: "LocalFileSearchCatalog")
        let docs = root.appendingPathComponent("Documents", isDirectory: true)
        let downloads = root.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)

        let launchPlan = docs.appendingPathComponent("Launch Plan.md")
        let nestedFolder = docs.appendingPathComponent("Specs", isDirectory: true)
        try FileManager.default.createDirectory(at: nestedFolder, withIntermediateDirectories: true)
        let spec = nestedFolder.appendingPathComponent("API Notes.txt")
        let hidden = docs.appendingPathComponent(".secret.txt")
        let nodeModules = docs.appendingPathComponent("node_modules", isDirectory: true)
        try FileManager.default.createDirectory(at: nodeModules, withIntermediateDirectories: true)
        let skippedFile = nodeModules.appendingPathComponent("skip.js")

        try "launch".write(to: launchPlan, atomically: true, encoding: .utf8)
        try "spec".write(to: spec, atomically: true, encoding: .utf8)
        try "hidden".write(to: hidden, atomically: true, encoding: .utf8)
        try "skip".write(to: skippedFile, atomically: true, encoding: .utf8)

        let items = LocalFileSearchCatalog.load(
            roots: [docs, downloads],
            homeDirectory: root,
            limit: 20,
            perRootLimit: 20,
            maxDepth: 6
        )

        XCTAssertEqual(items.map(\.name), ["API Notes.txt", "Launch Plan.md"])
        XCTAssertEqual(items.first?.displayPath, "~/Documents/Specs/API Notes.txt")
        XCTAssertEqual(items.last?.parentDisplayPath, "~/Documents")
    }

    func testLoadRespectsDepthAndLimit() throws {
        let root = try makeTempDirectory(name: "LocalFileSearchCatalogDepth")
        let docs = root.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)

        let shallow = docs.appendingPathComponent("Shallow.txt")
        let deepFolder = docs
            .appendingPathComponent("One", isDirectory: true)
            .appendingPathComponent("Two", isDirectory: true)
            .appendingPathComponent("Three", isDirectory: true)
        try FileManager.default.createDirectory(at: deepFolder, withIntermediateDirectories: true)
        let deep = deepFolder.appendingPathComponent("Deep.txt")

        try "a".write(to: shallow, atomically: true, encoding: .utf8)
        try "b".write(to: deep, atomically: true, encoding: .utf8)

        let shallowOnly = LocalFileSearchCatalog.load(
            roots: [docs],
            homeDirectory: root,
            limit: 1,
            perRootLimit: 1,
            maxDepth: 1
        )

        XCTAssertEqual(shallowOnly.map(\.name), ["Shallow.txt"])
    }

    func testNormalizedRootPathsDeduplicatesAndExpandsTilde() throws {
        let root = try makeTempDirectory(name: "LocalFileSearchCatalogNormalize")
        let documents = root.appendingPathComponent("Documents", isDirectory: true)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)

        let normalizedPaths = LocalFileSearchCatalog.normalizedRootPaths(
            [
                " ~/Documents ",
                documents.path,
                "",
                "Documents"
            ],
            homeDirectory: root
        )

        XCTAssertEqual(normalizedPaths, [documents.path])
    }

    func testDisplayRootPathUsesHomeAbbreviation() throws {
        let root = try makeTempDirectory(name: "LocalFileSearchCatalogDisplay")
        let projects = root.appendingPathComponent("Projects", isDirectory: true)

        XCTAssertEqual(
            LocalFileSearchCatalog.displayRootPath(projects.path, homeDirectory: root),
            "~/Projects"
        )
    }

    private func makeTempDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
