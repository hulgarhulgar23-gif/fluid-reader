import XCTest
@testable import FluidReader

final class AIWorkspaceCatalogTests: XCTestCase {
    func testSummaryTracksBuiltInCustomScriptsAndReadiness() {
        let builtInPrompt = CommandPaletteAction(
            id: "prompt-summarize",
            title: "Summary",
            systemImage: "text.badge.checkmark",
            group: .ask,
            sourceKind: .ask,
            run: {}
        )
        let customPrompt = CommandPaletteAction(
            id: "prompt-custom",
            title: "Custom",
            systemImage: "wand.and.stars",
            group: .ask,
            sourceKind: .ask,
            isEnabled: false,
            disabledReason: "Enable LLM in Settings.",
            run: {}
        )
        let readyScript = CommandPaletteAction(
            id: "run-script-ready",
            title: "Ready Script",
            systemImage: "terminal",
            group: .core,
            sourceKind: .script,
            run: {}
        )
        let brokenScript = CommandPaletteAction(
            id: "run-script-broken",
            title: "Broken Script",
            systemImage: "terminal",
            group: .core,
            sourceKind: .script,
            isEnabled: false,
            disabledReason: "Script file is missing.",
            run: {}
        )

        let catalog = AIWorkspaceCatalog(
            actions: [
                CommandPaletteAction(
                    id: "ask-anything",
                    title: "Ask Anything",
                    systemImage: "sparkles",
                    group: .ask,
                    run: {}
                ),
                CommandPaletteAction(
                    id: "run-best-local-action",
                    title: "Run Best Local Action",
                    systemImage: "bolt.horizontal.circle",
                    group: .ask,
                    sourceKind: .ask,
                    run: {}
                ),
                builtInPrompt,
                customPrompt,
                readyScript,
                brokenScript
            ],
            llmReady: false
        )

        XCTAssertEqual(
            catalog.summary,
            AIWorkspaceSummary(
                hubActionCount: 2,
                builtInPromptCount: 1,
                customPromptCount: 1,
                scriptCommandCount: 2,
                readyActionCount: 2,
                totalActionCount: 4,
                llmReady: false
            )
        )
        XCTAssertEqual(catalog.metadataTitles(for: builtInPrompt), ["Built-In", "Ready"])
        XCTAssertEqual(catalog.metadataTitles(for: customPrompt), ["Custom", "Needs LLM"])
        XCTAssertEqual(catalog.metadataTitles(for: brokenScript), ["Script", "Needs Fix"])
    }

    func testRowsFilterBuiltInCustomScriptsReadyAndSearch() {
        let builtInPrompt = CommandPaletteAction(
            id: "prompt-summarize",
            title: "Summary",
            subtitle: "Summarize the current text",
            systemImage: "text.badge.checkmark",
            group: .ask,
            sourceKind: .ask,
            run: {}
        )
        let customPrompt = CommandPaletteAction(
            id: "prompt-custom-2",
            title: "Board Update",
            subtitle: "Draft a board update",
            systemImage: "wand.and.stars",
            group: .ask,
            sourceKind: .ask,
            isEnabled: false,
            disabledReason: "Enable LLM in Settings.",
            run: {}
        )
        let script = CommandPaletteAction(
            id: "run-script-deploy",
            title: "Deploy Preview",
            subtitle: "Run deploy helper",
            systemImage: "terminal",
            group: .core,
            sourceKind: .script,
            run: {}
        )

        let catalog = AIWorkspaceCatalog(
            actions: [builtInPrompt, customPrompt, script],
            llmReady: true
        )

        XCTAssertEqual(catalog.rows(for: .builtIn, query: "").map(\.id), ["prompt-summarize"])
        XCTAssertEqual(catalog.rows(for: .custom, query: "").map(\.id), ["prompt-custom-2"])
        XCTAssertEqual(catalog.rows(for: .scripts, query: "").map(\.id), ["run-script-deploy"])
        XCTAssertEqual(
            Set(catalog.rows(for: .ready, query: "").map(\.id)),
            Set(["prompt-summarize", "run-script-deploy"])
        )
        XCTAssertEqual(
            catalog.rows(for: .all, query: "board").map(\.id),
            ["prompt-custom-2"]
        )
    }

    func testBrowseLimitHintOnlyAppliesToEmptyQueries() {
        let actions = (0..<20).map { index in
            CommandPaletteAction(
                id: "prompt-\(index)",
                title: "Prompt \(index)",
                systemImage: "sparkles",
                group: .ask,
                sourceKind: .ask,
                run: {}
            )
        }

        let catalog = AIWorkspaceCatalog(actions: actions, llmReady: true)

        XCTAssertTrue(
            catalog.shouldShowBrowseLimitHint(for: .all, query: "", emptyQueryLimit: 5)
        )
        XCTAssertEqual(
            catalog.rows(for: .all, query: "", emptyQueryLimit: 5).count,
            5
        )
        XCTAssertFalse(
            catalog.shouldShowBrowseLimitHint(for: .all, query: "prompt 12", emptyQueryLimit: 5)
        )
        XCTAssertEqual(
            catalog.rows(for: .all, query: "prompt 12", emptyQueryLimit: 5).first?.id,
            "prompt-12"
        )
    }

    func testStaticSummaryProducesStableLauncherStrings() {
        let templates = [
            PromptTemplate.builtIn[0],
            PromptTemplate.builtIn[1],
            PromptTemplate.custom(
                CustomPromptInput(
                    id: "custom",
                    title: "Board Update",
                    prompt: "Draft a board update."
                )
            )!
        ]
        let scripts = [
            ScriptCommandItem(
                url: URL(fileURLWithPath: "/tmp/deploy-preview.sh"),
                title: "Deploy Preview",
                subtitle: "Run deploy helper",
                keywords: ["deploy", "preview"],
                systemImage: "terminal",
                displayPath: "~/Scripts/deploy-preview.sh"
            )
        ]

        let summary = AIWorkspaceCatalog.summary(
            promptTemplates: templates,
            scriptCommands: scripts,
            llmEnabled: true,
            apiKey: "sk-test"
        )

        XCTAssertEqual(
            summary.askAnythingSubtitle,
            "Ask about current, selected, clipboard, or picked text · 3 AI commands ready"
        )
        XCTAssertEqual(
            summary.bestLocalActionSubtitle,
            "Route across 3 AI commands and local scripts"
        )
        XCTAssertEqual(
            summary.settingsSubtitle,
            "Manage 3 AI commands and 1 local script"
        )
    }
}
