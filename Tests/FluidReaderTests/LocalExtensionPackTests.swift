import XCTest
@testable import FluidReader

final class LocalExtensionPackTests: XCTestCase {
    func testPackRoundTripsScriptCommandMetadataAndContents() throws {
        let item = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/network-quick-look.sh"),
            title: "Network Quick Look",
            subtitle: "Local network helper",
            keywords: ["network", "diagnostics", "network"],
            systemImage: "network",
            displayPath: "/tmp/network-quick-look.sh"
        )

        let pack = LocalExtensionPack(
            scriptCommand: item,
            scriptContents: "#!/bin/sh\necho ready\n"
        )

        let decoded = try LocalExtensionPack.decode(pack.jsonData())
        XCTAssertEqual(decoded.fileName, "network-quick-look.sh")
        XCTAssertEqual(decoded.title, "Network Quick Look")
        XCTAssertEqual(decoded.keywords, ["network", "diagnostics"])
        XCTAssertTrue(decoded.suggestedExportFileName.hasSuffix(".fluid-extension.json"))
    }

    func testInstallCanReplaceExistingScriptWhenRequested() throws {
        let root = try makeTempDirectory(name: "LocalExtensionPackInstall")
        let pack = LocalExtensionPack(
            version: LocalExtensionPack.currentVersion,
            kind: "script-command",
            fileName: "disk-space.sh",
            title: "Disk Space",
            subtitle: "Disk helper",
            keywords: ["disk"],
            systemImage: "internaldrive",
            scriptContents: "#!/bin/sh\necho one\n"
        )
        let updatedPack = LocalExtensionPack(
            version: LocalExtensionPack.currentVersion,
            kind: "script-command",
            fileName: "disk-space.sh",
            title: "Disk Space",
            subtitle: "Disk helper",
            keywords: ["disk"],
            systemImage: "internaldrive",
            scriptContents: "#!/bin/sh\necho two\n"
        )

        let firstResult = try pack.install(into: root)
        let installedURL = try XCTUnwrap({
            if case .installed(let url) = firstResult { return url }
            return nil
        }())
        XCTAssertEqual(try String(contentsOf: installedURL), "#!/bin/sh\necho one\n")

        let secondResult = try updatedPack.install(into: root, mode: .replaceExisting)
        XCTAssertEqual(secondResult, .replaced(installedURL))
        XCTAssertEqual(try String(contentsOf: installedURL), "#!/bin/sh\necho two\n")
    }

    func testInstallKeepsExistingWhenRequested() throws {
        let root = try makeTempDirectory(name: "LocalExtensionPackKeepExisting")
        let pack = LocalExtensionPack(
            version: LocalExtensionPack.currentVersion,
            kind: "script-command",
            fileName: "system-uptime.sh",
            title: "System Uptime",
            subtitle: "Uptime helper",
            keywords: ["uptime"],
            systemImage: "clock.arrow.circlepath",
            scriptContents: "#!/bin/sh\necho one\n"
        )
        let updatedPack = LocalExtensionPack(
            version: LocalExtensionPack.currentVersion,
            kind: "script-command",
            fileName: "system-uptime.sh",
            title: "System Uptime",
            subtitle: "Uptime helper",
            keywords: ["uptime"],
            systemImage: "clock.arrow.circlepath",
            scriptContents: "#!/bin/sh\necho two\n"
        )

        _ = try pack.install(into: root)
        let result = try updatedPack.install(into: root, mode: .keepExisting)
        let fileURL = root.appendingPathComponent("system-uptime.sh")

        XCTAssertEqual(result, .alreadyInstalled(fileURL))
        XCTAssertEqual(try String(contentsOf: fileURL), "#!/bin/sh\necho one\n")
    }

    private func makeTempDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
