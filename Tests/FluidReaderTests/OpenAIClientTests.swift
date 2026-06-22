import Foundation
import XCTest
@testable import FluidReader

final class OpenAIClientTests: XCTestCase {
    func testRequestURLUsesFixedResponsesEndpoint() throws {
        let url = try OpenAIClient.requestURL(
            provider: "openAIResponses",
            endpoint: "https://example.com/v1/chat/completions"
        )

        XCTAssertEqual(url.absoluteString, AppDefaults.openAIResponsesEndpoint)
    }

    func testRequestURLUsesCustomEndpointForCompatibleChat() throws {
        let url = try OpenAIClient.requestURL(
            provider: "openAICompatibleChat",
            endpoint: "https://example.com/v1/chat/completions"
        )

        XCTAssertEqual(url.absoluteString, "https://example.com/v1/chat/completions")
    }

    func testRequestURLFallsBackToDefaultChatEndpointWhenBlank() throws {
        let url = try OpenAIClient.requestURL(provider: "openAICompatibleChat", endpoint: "   ")

        XCTAssertEqual(url.absoluteString, AppDefaults.openAICompatibleChatEndpoint)
    }

    func testRequestURLRejectsRelativeOrUnsupportedEndpoints() {
        XCTAssertThrowsError(
            try OpenAIClient.requestURL(
                provider: "openAICompatibleChat",
                endpoint: "v1/chat/completions"
            )
        ) { error in
            guard case OpenAIError.badURL = error else {
                XCTFail("Expected bad URL error for relative endpoint.")
                return
            }
        }

        XCTAssertThrowsError(
            try OpenAIClient.requestURL(
                provider: "openAICompatibleChat",
                endpoint: "file:///tmp/mock-server"
            )
        ) { error in
            guard case OpenAIError.badURL = error else {
                XCTFail("Expected bad URL error for unsupported scheme.")
                return
            }
        }
    }

    func testRequestURLRejectsCredentialEndpoints() {
        XCTAssertThrowsError(
            try OpenAIClient.requestURL(
                provider: "openAICompatibleChat",
                endpoint: "https://user:pass@example.com/v1/chat/completions"
            )
        ) { error in
            guard case OpenAIError.badURL = error else {
                XCTFail("Expected bad URL error for credential endpoint.")
                return
            }
        }

        XCTAssertThrowsError(
            try OpenAIClient.requestURL(
                provider: "openAICompatibleChat",
                endpoint: "https://trusted.example.com@evil.example/v1/chat/completions"
            )
        ) { error in
            guard case OpenAIError.badURL = error else {
                XCTFail("Expected bad URL error for spoofed credential endpoint.")
                return
            }
        }
    }

    func testRequestURLAllowsLoopbackHTTPForCompatibleChat() throws {
        let localhostURL = try OpenAIClient.requestURL(
            provider: "openAICompatibleChat",
            endpoint: "http://localhost:11434/v1/chat/completions"
        )
        XCTAssertEqual(localhostURL.absoluteString, "http://localhost:11434/v1/chat/completions")

        let loopbackURL = try OpenAIClient.requestURL(
            provider: "openAICompatibleChat",
            endpoint: "http://127.0.0.1:8080/v1/chat/completions"
        )
        XCTAssertEqual(loopbackURL.absoluteString, "http://127.0.0.1:8080/v1/chat/completions")
    }

    func testRequestURLRejectsNonLoopbackHTTPForCompatibleChat() {
        XCTAssertThrowsError(
            try OpenAIClient.requestURL(
                provider: "openAICompatibleChat",
                endpoint: "http://example.com/v1/chat/completions"
            )
        ) { error in
            guard case OpenAIError.badURL = error else {
                XCTFail("Expected bad URL error for non-loopback HTTP endpoint.")
                return
            }
        }
    }

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

    func testAskBodyIncludesPreviousAnswerWhenAvailable() throws {
        let data = try OpenAIClient.makeAskBody(
            question: "Make it shorter",
            selectedText: "Original text",
            previousAnswer: "Long answer",
            imageData: nil,
            model: "custom-model"
        )
        let json = try dictionary(from: data)

        let input = try XCTUnwrap(json["input"] as? [[String: Any]])
        let message = try XCTUnwrap(input.first)
        let content = try XCTUnwrap(message["content"] as? [[String: Any]])
        let text = try XCTUnwrap(content[0]["text"] as? String)

        XCTAssertTrue(text.contains("OCR text:\nOriginal text"))
        XCTAssertTrue(text.contains("Previous answer:\nLong answer"))
    }

    func testAskBodySkipsBlankPreviousAnswer() throws {
        let data = try OpenAIClient.makeAskBody(
            question: "Explain",
            selectedText: "Text",
            previousAnswer: "  ",
            imageData: nil,
            model: "custom-model"
        )
        let json = try dictionary(from: data)

        let input = try XCTUnwrap(json["input"] as? [[String: Any]])
        let message = try XCTUnwrap(input.first)
        let content = try XCTUnwrap(message["content"] as? [[String: Any]])
        let text = try XCTUnwrap(content[0]["text"] as? String)

        XCTAssertFalse(text.contains("Previous answer:"))
    }

    func testChatBodyUsesCompatibleShape() throws {
        let data = try OpenAIClient.makeChatBody(
            question: "Explain this",
            selectedText: "Marked text",
            imageData: Data([4, 5, 6]),
            model: "chat-model"
        )
        let json = try dictionary(from: data)

        XCTAssertEqual(json["model"] as? String, "chat-model")
        XCTAssertEqual(json["max_tokens"] as? Int, 700)

        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 2)
        XCTAssertEqual(messages[0]["role"] as? String, "system")
        XCTAssertEqual(messages[1]["role"] as? String, "user")

        let content = try XCTUnwrap(messages[1]["content"] as? [[String: Any]])
        XCTAssertEqual(content.count, 2)
        XCTAssertEqual(content[0]["type"] as? String, "text")
        XCTAssertTrue((content[0]["text"] as? String)?.contains("Marked text") == true)
        XCTAssertEqual(content[1]["type"] as? String, "image_url")

        let imageURL = try XCTUnwrap(content[1]["image_url"] as? [String: Any])
        XCTAssertTrue((imageURL["url"] as? String)?.hasPrefix("data:image/png;base64,") == true)
    }

    func testChatBodyIncludesPreviousAnswer() throws {
        let data = try OpenAIClient.makeChatBody(
            question: "Follow up",
            selectedText: "Marked text",
            previousAnswer: "Earlier answer",
            imageData: nil,
            model: "chat-model"
        )
        let json = try dictionary(from: data)

        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        let content = try XCTUnwrap(messages[1]["content"] as? [[String: Any]])
        let text = try XCTUnwrap(content[0]["text"] as? String)

        XCTAssertTrue(text.contains("Previous answer:\nEarlier answer"))
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
