import XCTest
@testable import FluidReader

final class ExtensionsWorkspaceCatalogTests: XCTestCase {
    func testItemsKeepAICommandsFirstAndSortScriptCommandsByTitle() {
        let zetaScript = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/zeta.sh"),
            title: "Zeta Script",
            subtitle: "Run zeta",
            keywords: ["zeta"],
            systemImage: "terminal",
            displayPath: "/tmp/zeta.sh"
        )
        let alphaScript = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/alpha.sh"),
            title: "Alpha Script",
            subtitle: "Run alpha",
            keywords: ["alpha"],
            systemImage: "terminal",
            displayPath: "/tmp/alpha.sh"
        )

        let items = ExtensionsWorkspaceCatalog.items(
            promptTemplates: [PromptTemplate.builtIn[0], PromptTemplate.builtIn[1]],
            scriptCommands: [zetaScript, alphaScript]
        )

        XCTAssertEqual(items.map(\.title), ["Summary", "Simple", "Alpha Script", "Zeta Script"])
        XCTAssertEqual(items.first?.sectionTitle, "AI Commands")
        XCTAssertEqual(items.last?.sectionTitle, "Script Commands")
    }

    func testFilteredItemsMatchesAIAndScriptKeywords() {
        let notesTemplate = PromptTemplate.builtIn.first { $0.id == "notes" }
        XCTAssertNotNil(notesTemplate)

        let script = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/deploy.sh"),
            title: "Deploy Helper",
            subtitle: "Run deployment automation",
            keywords: ["deploy", "automation", "release"],
            systemImage: "terminal",
            displayPath: "/tmp/deploy.sh"
        )

        let items = ExtensionsWorkspaceCatalog.items(
            promptTemplates: [notesTemplate!],
            scriptCommands: [script]
        )

        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "meeting").map(\.title),
            ["Notes"]
        )
        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "automation").map(\.title),
            ["Deploy Helper"]
        )
        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "script commands").map(\.title),
            ["Deploy Helper"]
        )
    }

    func testItemsCanIncludeStarterExtensionsAfterInstalledCommands() {
        let script = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/deploy.sh"),
            title: "Deploy Helper",
            subtitle: "Run deployment automation",
            keywords: ["deploy", "automation", "release"],
            systemImage: "terminal",
            displayPath: "/tmp/deploy.sh"
        )

        let starter = StarterExtensionTemplate(
            id: "starter-disk",
            title: "Disk Space",
            subtitle: "Install disk space helper",
            fileName: "disk-space.sh",
            systemImage: "internaldrive",
            keywords: ["starter", "disk"],
            scriptContents: "#!/bin/sh\necho hi\n"
        )

        let items = ExtensionsWorkspaceCatalog.items(
            promptTemplates: [PromptTemplate.builtIn[0]],
            scriptCommands: [script],
            starterExtensions: [starter]
        )

        XCTAssertEqual(items.map(\.title), ["Summary", "Deploy Helper", "Disk Space"])
        XCTAssertEqual(items.last?.sectionTitle, "Starter Extensions")
    }

    func testFilteredItemsMatchesStarterExtensionKeywords() {
        let starter = StarterExtensionTemplate(
            id: "starter-network",
            title: "Network Quick Look",
            subtitle: "Install network helper",
            fileName: "network-quick-look.sh",
            systemImage: "network",
            keywords: ["starter", "install", "network"],
            scriptContents: "#!/bin/sh\necho hi\n"
        )

        let items = ExtensionsWorkspaceCatalog.items(
            promptTemplates: [],
            scriptCommands: [],
            starterExtensions: [starter]
        )

        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "install network").map(\.title),
            ["Network Quick Look"]
        )
    }

    func testSummaryTracksCountsInstalledStartersAndLLMReadiness() {
        let script = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/network-quick-look.sh"),
            title: "Network Quick Look",
            subtitle: "Run network helper",
            keywords: ["network"],
            systemImage: "network",
            displayPath: "/tmp/network-quick-look.sh"
        )
        let starter = StarterExtensionTemplate(
            id: "starter-network",
            title: "Network Quick Look",
            subtitle: "Install network helper",
            fileName: "network-quick-look.sh",
            systemImage: "network",
            keywords: ["starter", "network"],
            scriptContents: "#!/bin/sh\necho hi\n"
        )

        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.summary(
                promptTemplates: [PromptTemplate.builtIn[0], PromptTemplate.builtIn[1]],
                scriptCommands: [script],
                starterExtensions: [starter],
                llmEnabled: true,
                apiKey: "test-key"
            ),
            ExtensionsWorkspaceSummary(
                aiCommandCount: 2,
                scriptCommandCount: 1,
                starterExtensionCount: 1,
                installedStarterCount: 1,
                totalCount: 4,
                llmReady: true
            )
        )
        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.summary(
                promptTemplates: [PromptTemplate.builtIn[0], PromptTemplate.builtIn[1]],
                scriptCommands: [script],
                starterExtensions: [starter],
                llmEnabled: true,
                apiKey: "test-key"
            ).actionSubtitle,
            "2 AI · 1 script · 1 starter in one local hub"
        )
    }

    func testFilteredItemsSupportsWorkspaceFilters() {
        let script = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/deploy.sh"),
            title: "Deploy Helper",
            subtitle: "Run deployment automation",
            keywords: ["deploy", "automation"],
            systemImage: "terminal",
            displayPath: "/tmp/deploy.sh"
        )
        let starter = StarterExtensionTemplate(
            id: "starter-network",
            title: "Network Quick Look",
            subtitle: "Install network helper",
            fileName: "network-quick-look.sh",
            systemImage: "network",
            keywords: ["starter", "network"],
            scriptContents: "#!/bin/sh\necho hi\n"
        )

        let items = ExtensionsWorkspaceCatalog.items(
            promptTemplates: [PromptTemplate.builtIn[0]],
            scriptCommands: [script],
            starterExtensions: [starter]
        )

        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "", filter: .ai).map(\.title),
            ["Summary"]
        )
        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "", filter: .scripts).map(\.title),
            ["Deploy Helper"]
        )
        XCTAssertEqual(
            ExtensionsWorkspaceCatalog.filteredItems(items, query: "", filter: .starter).map(\.title),
            ["Network Quick Look"]
        )
    }
}
