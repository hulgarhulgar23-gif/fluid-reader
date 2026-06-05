import Foundation
import XCTest
@testable import FluidReader

final class OpenAIClientTests: XCTestCase {
    func testAskBodyUsesDefaultModelAndAddsImage() throws {
        let data = try OpenAIClient.makeAskBody(
            question: "What is this?",
            selectedText: "Hello",
            imageData: Data([1, 2, 3]),
            model: "  "
        )
        let json = try dictionary(from: data)

        XCTAssertEqual(json["model"] as? String, AppDefaults.llmModel)
        XCTAssertEqual(json["max_output_tokens"] as? Int, 700)

        let input = try XCTUnwrap(json["input"] as? [[String: Any]])
        let message = try XCTUnwrap(input.first)
        XCTAssertEqual(message["role"] as? String, "user")

        let content = try XCTUnwrap(message["content"] as? [[String: Any]])
        XCTAssertEqual(content.count, 2)
        XCTAssertEqual(content[0]["type"] as? String, "input_text")
        XCTAssertTrue((content[0]["text"] as? String)?.contains("Hello") == true)
        XCTAssertEqual(content[1]["type"] as? String, "input_image")
        XCTAssertTrue((content[1]["image_url"] as? String)?.hasPrefix("data:image/png;base64,") == true)
    }

    func testAskBodyUsesNoTextMessage() throws {
        let data = try OpenAIClient.makeAskBody(
            question: "Explain",
            selectedText: "  ",
            imageData: nil,
            model: "custom-model"
        )
        let json = try dictionary(from: data)

        XCTAssertEqual(json["model"] as? String, "custom-model")

        let input = try XCTUnwrap(json["input"] as? [[String: Any]])
        let message = try XCTUnwrap(input.first)
        let content = try XCTUnwrap(message["content"] as? [[String: Any]])
        XCTAssertEqual(content.count, 1)
        XCTAssertTrue((content[0]["text"] as? String)?.contains("No text was found") == true)
    }

    func testSpeechBodyUsesDefaultsAndLimitsText() throws {
        let longText = String(repeating: "a", count: 8_100)
        let data = try OpenAIClient.makeSpeechBody(
            text: " \(longText) ",
            model: "",
            voice: " ",
            instructions: " calm "
        )
        let json = try dictionary(from: data)

        XCTAssertEqual(json["model"] as? String, AppDefaults.cloudVoiceModel)
        XCTAssertEqual(json["voice"] as? String, AppDefaults.cloudVoiceName)
        XCTAssertEqual((json["input"] as? String)?.count, 8_000)
        XCTAssertEqual(json["instructions"] as? String, "calm")
        XCTAssertEqual(json["response_format"] as? String, "mp3")
    }

    func testSpeechBodyRejectsEmptyText() {
        XCTAssertThrowsError(try OpenAIClient.makeSpeechBody(
            text: " ",
            model: "",
            voice: "",
            instructions: ""
        )) { error in
            guard case OpenAIError.emptyInput = error else {
                XCTFail("Expected empty input error.")
                return
            }
        }
    }

    private func dictionary(from data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }
}
