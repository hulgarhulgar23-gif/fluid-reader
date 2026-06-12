import XCTest
@testable import FluidReader

final class PromptTemplateTests: XCTestCase {
    func testBuiltInPromptsAreAvailable() {
        XCTAssertEqual(PromptTemplate.builtIn.map(\.id), [
            "summarize",
            "simple",
            "notes",
            "actions",
            "rewrite",
            "reply",
            "launch-post",
            "english",
            "mongolian",
            "code-help",
            "questions"
        ])
        XCTAssertTrue(PromptTemplate.builtIn.allSatisfy { !$0.prompt.isEmpty })
        XCTAssertTrue(PromptTemplate.builtIn.allSatisfy { !$0.keywords.isEmpty })
    }

    func testCustomPromptIsAddedWhenTextExists() throws {
        let prompts = PromptTemplate.all(
            customTitle: "  Risks  ",
            customPrompt: "  Find risks.  "
        )

        let custom = try XCTUnwrap(prompts.last)
        XCTAssertEqual(custom.id, "custom")
        XCTAssertEqual(custom.title, "Risks")
        XCTAssertEqual(custom.prompt, "Find risks.")
        XCTAssertEqual(prompts.count, PromptTemplate.builtIn.count + 1)
    }

    func testMultipleCustomPromptsAreAddedWhenTextExists() {
        let prompts = PromptTemplate.all(customPrompts: [
            CustomPromptInput(id: "custom", title: "  Risks  ", prompt: "  Find risks.  "),
            CustomPromptInput(id: "custom-2", title: "  Reply  ", prompt: "  Draft a reply.  "),
            CustomPromptInput(id: "custom-3", title: "Blank", prompt: "  ")
        ])

        XCTAssertEqual(prompts.suffix(2).map(\.id), ["custom", "custom-2"])
        XCTAssertEqual(prompts.suffix(2).map(\.title), ["Risks", "Reply"])
        XCTAssertEqual(prompts.suffix(2).map(\.prompt), ["Find risks.", "Draft a reply."])
    }

    func testBlankCustomPromptIsSkipped() {
        XCTAssertNil(PromptTemplate.custom(customTitle: "Name", customPrompt: "  "))
        XCTAssertEqual(
            PromptTemplate.all(customTitle: "Name", customPrompt: "  "),
            PromptTemplate.builtIn
        )
    }

    func testBuiltInPromptsIncludeCommonSearchAliases() {
        let aliasesByID = Dictionary(uniqueKeysWithValues: PromptTemplate.builtIn.map { ($0.id, $0.keywords) })

        XCTAssertTrue(aliasesByID["summarize"]?.contains("tldr") == true)
        XCTAssertTrue(aliasesByID["simple"]?.contains("eli5") == true)
        XCTAssertTrue(aliasesByID["notes"]?.contains("meeting") == true)
        XCTAssertTrue(aliasesByID["notes"]?.contains("minutes") == true)
        XCTAssertTrue(aliasesByID["actions"]?.contains("steps") == true)
        XCTAssertTrue(aliasesByID["code-help"]?.contains("fix") == true)
        XCTAssertTrue(aliasesByID["code-help"]?.contains("bug") == true)
        XCTAssertTrue(aliasesByID["launch-post"]?.contains("launch") == true)
    }
}
