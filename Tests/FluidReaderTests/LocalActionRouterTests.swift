import XCTest
@testable import FluidReader

final class LocalActionRouterTests: XCTestCase {
    func testBestRoutePrefersPromptTemplateForMeetingMinutesIntent() throws {
        let template = try XCTUnwrap(PromptTemplate.builtIn.first { $0.id == "notes" })
        let route = LocalActionRouter.bestRoute(
            for: "turn this meeting into quick minutes",
            candidates: [
                LocalActionRouter.Candidate(
                    id: "prompt-\(template.id)",
                    title: template.title,
                    subtitle: template.prompt,
                    keywords: template.keywords,
                    kind: .prompt(template),
                    isEnabled: true,
                    disabledReason: nil
                )
            ]
        )

        switch try XCTUnwrap(route).candidate.kind {
        case .prompt(let matchedTemplate):
            XCTAssertEqual(matchedTemplate.id, "notes")
        case .script:
            XCTFail("Expected prompt route")
        }
    }

    func testBestRoutePrefersScriptCommandForDeployIntent() {
        let item = ScriptCommandItem(
            url: URL(fileURLWithPath: "/tmp/deploy-preview.sh"),
            title: "Deploy Preview",
            subtitle: "Ship the latest preview build",
            keywords: ["deploy", "preview", "build", "release"],
            systemImage: "terminal",
            displayPath: "~/Scripts/deploy-preview.sh"
        )

        let route = LocalActionRouter.bestRoute(
            for: "deploy the latest preview build",
            candidates: [
                LocalActionRouter.Candidate(
                    id: item.actionID,
                    title: item.title,
                    subtitle: item.subtitle,
                    keywords: item.keywords,
                    kind: .script(item),
                    isEnabled: true,
                    disabledReason: nil
                )
            ]
        )

        switch try! XCTUnwrap(route).candidate.kind {
        case .prompt:
            XCTFail("Expected script route")
        case .script(let matchedItem):
            XCTAssertEqual(matchedItem.title, "Deploy Preview")
        }
    }

    func testBestRouteCanReturnDisabledMatchForClearIntent() throws {
        let template = try XCTUnwrap(PromptTemplate.builtIn.first { $0.id == "summarize" })
        let route = LocalActionRouter.bestRoute(
            for: "tldr this",
            candidates: [
                LocalActionRouter.Candidate(
                    id: "prompt-\(template.id)",
                    title: template.title,
                    subtitle: template.prompt,
                    keywords: template.keywords,
                    kind: .prompt(template),
                    isEnabled: false,
                    disabledReason: "Enable LLM in Settings."
                )
            ]
        )

        XCTAssertEqual(try XCTUnwrap(route).candidate.disabledReason, "Enable LLM in Settings.")
    }

    func testBestRouteReturnsNilWhenNoCandidateMatches() {
        let template = PromptTemplate.builtIn[0]
        let route = LocalActionRouter.bestRoute(
            for: "weather in tokyo",
            candidates: [
                LocalActionRouter.Candidate(
                    id: "prompt-\(template.id)",
                    title: template.title,
                    subtitle: template.prompt,
                    keywords: template.keywords,
                    kind: .prompt(template),
                    isEnabled: true,
                    disabledReason: nil
                )
            ]
        )

        XCTAssertNil(route)
    }
}
