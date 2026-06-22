import XCTest
@testable import FluidReader

final class ScriptCommandCatalogTests: XCTestCase {
    func testLoadIncludesShebangScriptsAndParsesMetadata() throws {
        let root = try makeTempDirectory(name: "ScriptCommandCatalog")
        defer { try? FileManager.default.removeItem(at: root) }
        let scripts = root.appendingPathComponent("ScriptCommands", isDirectory: true)
        try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)

        let scriptURL = scripts.appendingPathComponent("launch-helper")
        try """
        #!/bin/sh
        # @title Launch Helper
        # @subtitle Run the launch checklist
        # @keywords launch, checklist, rollout
        # @icon bolt.circle
        echo ready
        """.write(to: scriptURL, atomically: true, encoding: .utf8)

        let items = ScriptCommandCatalog.load(
            directoryURL: scripts,
            fileManager: .default,
            homeDirectory: root,
            limit: 20,
            maxDepth: 2
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.title, "Launch Helper")
        XCTAssertEqual(items.first?.subtitle, "Run the launch checklist")
        XCTAssertEqual(items.first?.systemImage, "bolt.circle")
        XCTAssertEqual(items.first?.displayPath, "~/ScriptCommands/launch-helper")
        XCTAssertEqual(
            items.first?.keywords,
            [
                "script",
                "automation",
                "command",
                "launch-helper",
                "Launch Helper",
                "Run the launch checklist",
                "~/ScriptCommands/launch-helper",
                "launch",
                "checklist",
                "rollout"
            ]
        )
    }

    func testExecutionConfigurationUsesExtensionFallbackForShellScript() throws {
        let root = try makeTempDirectory(name: "ScriptCommandExecution")
        defer { try? FileManager.default.removeItem(at: root) }
        let scriptURL = root.appendingPathComponent("daily-brief.sh")
        try "echo ok".write(to: scriptURL, atomically: true, encoding: .utf8)

        let item = try XCTUnwrap(
            ScriptCommandCatalog.load(
                directoryURL: root,
                fileManager: .default,
                homeDirectory: root,
                limit: 20,
                maxDepth: 1
            ).first
        )

        let execution = try item.executionConfiguration(
            fileManager: .default,
            environment: ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
        ).get()

        XCTAssertEqual(execution.arguments, [scriptURL.path])
        XCTAssertEqual(execution.workingDirectoryURL, root)
        XCTAssertTrue(
            ["/bin/zsh", "/bin/bash", "/bin/sh"].contains(execution.executableURL.path),
            "Expected a shell interpreter, got \(execution.executableURL.path)"
        )
    }

    private func makeTempDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
