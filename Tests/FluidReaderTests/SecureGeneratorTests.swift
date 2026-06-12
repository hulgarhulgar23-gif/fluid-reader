import XCTest
@testable import FluidReader

final class SecureGeneratorTests: XCTestCase {
    func testStringFromBytesUsesAlphabet() {
        XCTAssertEqual(
            SecureGenerator.string(from: [0, 1, 2, 3, 4], alphabet: "abc", length: 5),
            "abcab"
        )
        XCTAssertEqual(SecureGenerator.string(from: [1, 2], alphabet: "abc", length: 0), "")
        XCTAssertEqual(SecureGenerator.string(from: [1, 2], alphabet: "", length: 2), "")
    }

    func testStringFromBytesRejectsBiasedBytes() {
        // With a 3-character alphabet the largest fair bound is 255, so byte
        // 255 must be discarded instead of mapping to "a" via modulo bias.
        XCTAssertEqual(SecureGenerator.string(from: [255, 0], alphabet: "abc", length: 1), "a")
        XCTAssertEqual(SecureGenerator.string(from: [255], alphabet: "abc", length: 1), "")
    }

    func testHexTokenFromBytes() {
        XCTAssertEqual(SecureGenerator.hexToken(from: [0, 15, 255]), "000fff")
    }

    func testURLTokenFromBytes() {
        XCTAssertEqual(SecureGenerator.urlToken(from: [255, 238, 221]), "_-7d")
    }

    func testGeneratedPasswordHasExpectedShape() {
        let password = SecureGenerator.strongPassword()
        let alphabet = Set(SecureGenerator.passwordAlphabet)

        XCTAssertEqual(password.count, 24)
        XCTAssertTrue(password.allSatisfy { alphabet.contains($0) })
    }

    func testGeneratedPINHasExpectedShape() {
        let pin = SecureGenerator.pin()

        XCTAssertEqual(pin.count, 6)
        XCTAssertTrue(pin.allSatisfy { $0.isNumber })
    }

    func testGeneratedTokensHaveExpectedShape() {
        let hexToken = SecureGenerator.hexToken()
        let urlToken = SecureGenerator.urlToken()

        XCTAssertEqual(hexToken.count, 32)
        XCTAssertTrue(hexToken.allSatisfy { $0.isHexDigit })
        XCTAssertFalse(urlToken.isEmpty)
        XCTAssertFalse(urlToken.contains("+"))
        XCTAssertFalse(urlToken.contains("/"))
        XCTAssertFalse(urlToken.contains("="))
    }
}
