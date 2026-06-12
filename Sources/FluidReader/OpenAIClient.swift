import Foundation

enum LLMProvider: String, CaseIterable, Identifiable {
    case openAIResponses
    case openAICompatibleChat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAIResponses:
            return "OpenAI"
        case .openAICompatibleChat:
            return "Compatible"
        }
    }

    static func normalized(_ value: String) -> LLMProvider {
        LLMProvider(rawValue: value) ?? .openAIResponses
    }
}

struct OpenAIClient {
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    func askAboutSelection(
        question: String,
        selectedText: String,
        previousAnswer: String = "",
        imageData: Data?,
        model: String,
        provider: String = AppDefaults.llmProvider,
        endpoint: String = AppDefaults.openAIResponsesEndpoint
    ) async throws -> String {
        let responseData: Data
        let output: String?

        switch LLMProvider.normalized(provider) {
        case .openAIResponses:
            guard let url = URL(string: AppDefaults.openAIResponsesEndpoint) else {
                throw OpenAIError.badURL
            }
            let data = try Self.makeAskBody(
                question: question,
                selectedText: selectedText,
                previousAnswer: previousAnswer,
                imageData: imageData,
                model: model
            )
            responseData = try await sendJSON(data, to: url)
            let decoded = try JSONDecoder().decode(ResponsesEnvelope.self, from: responseData)
            output = decoded.outputText
                ?? decoded.output?
                    .flatMap { $0.content ?? [] }
                    .compactMap { $0.text }
                    .joined(separator: "\n")
        case .openAICompatibleChat:
            let endpointValue = AppDefaults.value(endpoint, fallback: AppDefaults.openAICompatibleChatEndpoint)
            guard let url = URL(string: endpointValue) else {
                throw OpenAIError.badURL
            }
            let data = try Self.makeChatBody(
                question: question,
                selectedText: selectedText,
                previousAnswer: previousAnswer,
                imageData: imageData,
                model: model
            )
            responseData = try await sendJSON(data, to: url)
            let decoded = try JSONDecoder().decode(ChatEnvelope.self, from: responseData)
            output = decoded.choices
                .compactMap { $0.message.content }
                .joined(separator: "\n")
        }

        let cleanOutput = output?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !cleanOutput.isEmpty else {
            throw OpenAIError.emptyResponse
        }
        return cleanOutput
    }

    static func makeAskBody(
        question: String,
        selectedText: String,
        previousAnswer: String = "",
        imageData: Data?,
        model: String
    ) throws -> Data {
        var content: [[String: Any]] = [
            [
                "type": "input_text",
                "text": promptText(
                    question: question,
                    selectedText: selectedText,
                    previousAnswer: previousAnswer
                )
            ]
        ]

        if let imageData, !imageData.isEmpty {
            content.append([
                "type": "input_image",
                "detail": "auto",
                "image_url": "data:image/png;base64,\(imageData.base64EncodedString())"
            ])
        }

        let body: [String: Any] = [
            "model": AppDefaults.value(model, fallback: AppDefaults.llmModel),
            "instructions": "You help read and explain selected screen content. Keep the answer short, clear, and good for listening.",
            "input": [
                [
                    "role": "user",
                    "content": content
                ]
            ],
            "max_output_tokens": 700
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    static func makeChatBody(
        question: String,
        selectedText: String,
        previousAnswer: String = "",
        imageData: Data?,
        model: String
    ) throws -> Data {
        var content: [[String: Any]] = [
            [
                "type": "text",
                "text": promptText(
                    question: question,
                    selectedText: selectedText,
                    previousAnswer: previousAnswer
                )
            ]
        ]

        if let imageData, !imageData.isEmpty {
            content.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/png;base64,\(imageData.base64EncodedString())"
                ]
            ])
        }

        let body: [String: Any] = [
            "model": AppDefaults.value(model, fallback: AppDefaults.llmModel),
            "messages": [
                [
                    "role": "system",
                    "content": "You help read and explain selected screen content. Keep the answer short, clear, and good for listening."
                ],
                [
                    "role": "user",
                    "content": content
                ]
            ],
            "max_tokens": 700
        ]

        return try JSONSerialization.data(withJSONObject: body)
    }

    private static func promptText(
        question: String,
        selectedText: String,
        previousAnswer: String
    ) -> String {
        let cleanQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSelectedText = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPreviousAnswer = contextText(previousAnswer)

        var sections = [
            cleanQuestion,
            """
            OCR text:
            \(cleanSelectedText.isEmpty ? "(No text was found by OCR.)" : cleanSelectedText)
            """
        ]

        if !cleanPreviousAnswer.isEmpty {
            sections.append(
                """
                Previous answer:
                \(cleanPreviousAnswer)
                """
            )
        }

        return sections.joined(separator: "\n\n")
    }

    private static func contextText(_ value: String, limit: Int = 4_000) -> String {
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanValue.count > limit else { return cleanValue }
        return String(cleanValue.prefix(limit))
    }

    func makeSpeech(
        text: String,
        model: String,
        voice: String,
        instructions: String
    ) async throws -> Data {
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            throw OpenAIError.badURL
        }

        let data = try Self.makeSpeechBody(
            text: text,
            model: model,
            voice: voice,
            instructions: instructions
        )
        return try await sendJSON(data, to: url)
    }

    static func makeSpeechBody(
        text: String,
        model: String,
        voice: String,
        instructions: String
    ) throws -> Data {
        let cleanText = String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(8000))
        guard !cleanText.isEmpty else { throw OpenAIError.emptyInput }

        var body: [String: Any] = [
            "model": AppDefaults.value(model, fallback: AppDefaults.cloudVoiceModel),
            "voice": AppDefaults.value(voice, fallback: AppDefaults.cloudVoiceName),
            "input": cleanText,
            "response_format": "mp3"
        ]

        let cleanInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanInstructions.isEmpty {
            body["instructions"] = cleanInstructions
        }

        return try JSONSerialization.data(withJSONObject: body)
    }

    private func sendJSON(_ data: Data, to url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = data

        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.badResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: responseData, encoding: .utf8) ?? "OpenAI error"
            throw OpenAIError.api(message)
        }

        return responseData
    }
}

private struct ResponsesEnvelope: Decodable {
    let outputText: String?
    let output: [OutputItem]?

    enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

private struct OutputItem: Decodable {
    let content: [OutputContent]?
}

private struct OutputContent: Decodable {
    let type: String?
    let text: String?
}

private struct ChatEnvelope: Decodable {
    let choices: [ChatChoice]
}

private struct ChatChoice: Decodable {
    let message: ChatMessage
}

private struct ChatMessage: Decodable {
    let content: String?
}

enum OpenAIError: LocalizedError {
    case badURL
    case badResponse
    case emptyInput
    case emptyResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The API address is not valid."
        case .badResponse:
            return "The API response was not valid."
        case .emptyInput:
            return "There is no text to read."
        case .emptyResponse:
            return "The LLM did not return text."
        case .api(let message):
            return message
        }
    }
}
