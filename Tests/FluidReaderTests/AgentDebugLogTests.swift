import XCTest
@testable import FluidReader

final class AgentDebugLogTests: XCTestCase {
    func testIsEnabledDefaultsToFalse() {
        XCTAssertFalse(AgentDebugLog.isEnabled(environment: [:]))
        XCTAssertFalse(AgentDebugLog.isEnabled(environment: ["FLUID_READER_AGENT_DEBUG_LOG": ""]))
        XCTAssertFalse(AgentDebugLog.isEnabled(environment: ["FLUID_READER_AGENT_DEBUG_LOG": "0"]))
        XCTAssertFalse(AgentDebugLog.isEnabled(environment: ["FLUID_READER_AGENT_DEBUG_LOG": "off"]))
    }

    func testIsEnabledAcceptsTruthyValues() {
        let truthyValues = ["1", "true", "TRUE", " yes ", "On"]
        truthyValues.forEach { value in
            XCTAssertTrue(
                AgentDebugLog.isEnabled(environment: ["FLUID_READER_AGENT_DEBUG_LOG": value]),
                "Expected value to enable logging: \(value)"
            )
        }
    }

    func testLogURLReturnsNilWhenDebugLoggingDisabled() {
        XCTAssertNil(AgentDebugLog.logURL(sessionID: "session", environment: [:]))
    }

    func testLogURLUsesPathOverrideWhenProvided() throws {
        let customPath = "~/tmp/fluid-reader-debug.log"
        let url = try XCTUnwrap(
            AgentDebugLog.logURL(
                sessionID: "session",
                environment: [
                    "FLUID_READER_AGENT_DEBUG_LOG": "1",
                    "FLUID_READER_AGENT_DEBUG_LOG_PATH": customPath
                ]
            )
        )

        XCTAssertEqual(url.path, (customPath as NSString).expandingTildeInPath)
    }

    func testLogURLBuildsSessionFileInsideFluidReaderDebugFolder() throws {
        let sessionID = "session-123"
        let url = try XCTUnwrap(
            AgentDebugLog.logURL(
                sessionID: sessionID,
                environment: ["FLUID_READER_AGENT_DEBUG_LOG": "true"]
            )
        )

        XCTAssertEqual(url.lastPathComponent, "agent-debug-\(sessionID).log")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Debug")
        XCTAssertEqual(
            url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent,
            "FluidReader"
        )
    }
}
