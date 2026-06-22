import XCTest
@testable import FluidReader

final class StarterExtensionLibraryTests: XCTestCase {
    func testInstallerWritesStarterScriptAndDetectsExistingInstall() throws {
        let root = try makeTempDirectory(name: "StarterExtensionInstall")
        let template = StarterExtensionTemplate(
            id: "uptime",
            title: "System Uptime",
            subtitle: "Install uptime helper",
            fileName: "system-uptime.sh",
            systemImage: "clock.arrow.circlepath",
            keywords: ["starter", "uptime"],
            scriptContents: "#!/bin/sh\necho uptime\n"
        )

        let firstInstall = try StarterExtensionInstaller.install(template, directoryURL: root)
        let installedURL = try XCTUnwrap(
            {
                if case .installed(let url) = firstInstall { return url }
                return nil
            }()
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: installedURL.path))
        XCTAssertEqual(try String(contentsOf: installedURL), template.scriptContents)

        let secondInstall = try StarterExtensionInstaller.install(template, directoryURL: root)
        XCTAssertEqual(secondInstall, .alreadyInstalled(installedURL))
    }

    func testInstalledScriptMatchesByFileName() {
        let template = StarterExtensionTemplate(
            id: "downloads",
            title: "Recent Downloads",
            subtitle: "Install recent downloads helper",
            fileName: "recent-downloads.sh",
            systemImage: "arrow.down.circle",
            keywords: ["starter", "downloads"],
            scriptContents: "#!/bin/sh\necho downloads\n"
        )
        let item = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/recent-downloads.sh"),
            title: "Recent Downloads",
            subtitle: "Latest downloads",
            keywords: ["downloads"],
            systemImage: "arrow.down.circle",
            displayPath: "/tmp/recent-downloads.sh"
        )

        XCTAssertEqual(
            StarterExtensionCatalog.installedScript(for: template, in: [item]),
            item
        )
    }

    private func makeTempDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
