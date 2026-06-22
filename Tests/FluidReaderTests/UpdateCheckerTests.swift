import XCTest
@testable import FluidReader

final class UpdateCheckerTests: XCTestCase {
    func testNumericComponentsParsesPlainAndPrefixedVersions() {
        XCTAssertEqual(UpdateChecker.numericComponents(of: "0.1.0"), [0, 1, 0])
        XCTAssertEqual(UpdateChecker.numericComponents(of: "v1.2.3"), [1, 2, 3])
        XCTAssertEqual(UpdateChecker.numericComponents(of: " V2.0 "), [2, 0])
        XCTAssertEqual(UpdateChecker.numericComponents(of: "1.2.0-beta.1"), [1, 2, 0])
    }

    func testNumericComponentsRejectsNonNumericVersions() {
        XCTAssertEqual(UpdateChecker.numericComponents(of: ""), [])
        XCTAssertEqual(UpdateChecker.numericComponents(of: "latest"), [])
        XCTAssertEqual(UpdateChecker.numericComponents(of: "1.x"), [])
        XCTAssertEqual(UpdateChecker.numericComponents(of: "1.2x"), [])
        // Everything after the first dash is treated as a pre-release suffix.
        XCTAssertEqual(UpdateChecker.numericComponents(of: "1.-2"), [1])
    }

    func testIsVersionNewerThanComparesComponents() {
        XCTAssertTrue(UpdateChecker.isVersion("0.2.0", newerThan: "0.1.0"))
        XCTAssertTrue(UpdateChecker.isVersion("v1.0.0", newerThan: "0.9.9"))
        XCTAssertTrue(UpdateChecker.isVersion("0.1.1", newerThan: "0.1"))
        XCTAssertFalse(UpdateChecker.isVersion("0.1.0", newerThan: "0.1.0"))
        XCTAssertFalse(UpdateChecker.isVersion("0.1.0", newerThan: "0.2.0"))
        XCTAssertFalse(UpdateChecker.isVersion("0.1", newerThan: "0.1.0"))
    }

    func testIsVersionNewerThanRejectsUnparseableVersions() {
        XCTAssertFalse(UpdateChecker.isVersion("latest", newerThan: "0.1.0"))
        XCTAssertFalse(UpdateChecker.isVersion("0.2.0", newerThan: "unknown"))
    }

    func testCurrentVersionFallsBackWhenMissing() {
        XCTAssertEqual(UpdateChecker.currentVersion(bundle: Bundle(for: Self.self)), "0.0.0")
    }

    func testParseLatestReleaseReadsTagAndPage() throws {
        let json = """
        {"tag_name": "v0.2.0", "html_url": "https://github.com/hulgarhulgar23-gif/fluid-reader/releases/tag/v0.2.0"}
        """
        let release = try UpdateChecker.parseLatestRelease(from: Data(json.utf8))

        XCTAssertEqual(release.version, "v0.2.0")
        XCTAssertEqual(
            release.pageURL.absoluteString,
            "https://github.com/hulgarhulgar23-gif/fluid-reader/releases/tag/v0.2.0"
        )
    }

    func testParseLatestReleaseRejectsBadPayloads() {
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(from: Data("not json".utf8)))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(#"{"tag_name": "", "html_url": "https://example.com"}"#.utf8)
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(#"{"tag_name": "latest", "html_url": "https://example.com"}"#.utf8)
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(#"{"tag_name": "v0.2.0", "html_url": "http://insecure.example.com"}"#.utf8)
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(
                #"{"tag_name": "v0.2.0", "html_url": "https://example.com/hulgarhulgar23-gif/fluid-reader/releases/tag/v0.2.0"}"#
                    .utf8
            )
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(
                #"{"tag_name": "v0.2.0", "html_url": "https://github.com/hulgarhulgar23-gif/fluid-reader/releases-malicious"}"#
                    .utf8
            )
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(
                #"{"tag_name": "v0.2.0", "html_url": "https://user:pass@github.com/hulgarhulgar23-gif/fluid-reader/releases/tag/v0.2.0"}"#
                    .utf8
            )
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(
                #"{"tag_name": "v0.2.0", "html_url": "https://github.com/hulgarhulgar23-gif/fluid-reader/releases/../issues"}"#
                    .utf8
            )
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(
                #"{"tag_name": "v0.2.0", "html_url": "https://github.com/hulgarhulgar23-gif/fluid-reader/releases/%2E%2E/issues"}"#
                    .utf8
            )
        ))
        XCTAssertThrowsError(try UpdateChecker.parseLatestRelease(
            from: Data(
                #"{"tag_name": "v0.2.0", "html_url": "https://github.com/hulgarhulgar23-gif/fluid-reader/releases/%2e%2e%5cissues"}"#
                    .utf8
            )
        ))
    }

    func testReleaseURLsPointAtSubmissionRepository() {
        XCTAssertEqual(
            UpdateChecker.latestReleaseAPIURL.absoluteString,
            "https://api.github.com/repos/hulgarhulgar23-gif/fluid-reader/releases/latest"
        )
        XCTAssertEqual(
            UpdateChecker.releasesPageURL.absoluteString,
            "https://github.com/hulgarhulgar23-gif/fluid-reader/releases"
        )
    }
}
