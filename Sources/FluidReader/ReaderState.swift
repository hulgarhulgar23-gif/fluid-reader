import Foundation

@MainActor
final class ReaderState: ObservableObject {
    @Published var lastText = ""
    @Published var answerText = ""
    @Published var errorText = ""
    @Published var isWorking = false
    @Published var lastImageData: Data?
    @Published private(set) var pulseID = UUID()

    func pulse() {
        pulseID = UUID()
    }
}
