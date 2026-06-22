import Foundation
import Vision

final class OCRService: Sendable {
    func recognizeText(in image: CGImage, languageCode: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let candidates = try [
                        CGImagePropertyOrientation.up,
                        CGImagePropertyOrientation.down
                    ].map { orientation in
                        try Self.recognizeTextOnce(
                            in: image,
                            orientation: orientation,
                            languageCode: languageCode
                        )
                    }

                    let best = candidates.max { left, right in
                        left.replacingOccurrences(of: " ", with: "").count <
                            right.replacingOccurrences(of: " ", with: "").count
                    } ?? ""

                    continuation.resume(returning: best)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func recognizeTextOnce(
        in image: CGImage,
        orientation: CGImagePropertyOrientation,
        languageCode: String
    ) throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01

        let trimmedLanguage = languageCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLanguage.isEmpty {
            // Empty code means the user picked the "Auto" preset. Vision does
            // not auto-detect by default (it falls back to English-only), so
            // ask it to detect the language instead of silently doing en-US.
            request.automaticallyDetectsLanguage = true
        } else {
            request.recognitionLanguages = [trimmedLanguage]
        }

        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        try handler.perform([request])

        let lines = request.results?
            .compactMap { observation in
                observation.topCandidates(1).first?.string
            } ?? []

        return lines.joined(separator: "\n")
    }
}
