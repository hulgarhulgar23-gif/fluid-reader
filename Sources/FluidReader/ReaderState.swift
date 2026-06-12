import Foundation

struct ReaderHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let text: String
    let answer: String

    var preview: String {
        Self.preview(for: text.isEmpty ? answer : text, limit: 84)
    }

    var detail: String {
        if !text.isEmpty && !answer.isEmpty {
            return "Text and answer"
        }
        if !answer.isEmpty {
            return "Answer"
        }
        return "Text"
    }

    static func make(
        text: String,
        answer: String = "",
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) -> ReaderHistoryItem? {
        let cleanText = clean(text)
        let cleanAnswer = clean(answer)
        guard !cleanText.isEmpty || !cleanAnswer.isEmpty else { return nil }

        return ReaderHistoryItem(
            id: id,
            createdAt: createdAt,
            text: cleanText,
            answer: cleanAnswer
        )
    }

    static func preview(for text: String, limit: Int) -> String {
        let cleanText = clean(text)
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        guard cleanText.count > limit else { return cleanText }
        return "\(cleanText.prefix(limit))..."
    }

    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ReaderSnippetItem: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    private let customTitleValue: String?
    private let pinnedValue: Bool?

    var isPinned: Bool {
        pinnedValue == true
    }

    var customTitle: String? {
        customTitleValue
    }

    var title: String {
        customTitleValue ?? ReaderHistoryItem.preview(for: text, limit: 84)
    }

    var preview: String {
        ReaderHistoryItem.preview(for: title, limit: 84)
    }

    init(id: UUID, text: String, title: String? = nil, isPinned: Bool = false) {
        self.id = id
        self.text = text
        let cleanTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        customTitleValue = cleanTitle.isEmpty ? nil : cleanTitle
        pinnedValue = isPinned ? true : nil
    }

    static func make(
        text: String,
        title: String = "",
        id: UUID = UUID(),
        isPinned: Bool = false
    ) -> ReaderSnippetItem? {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return nil }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return ReaderSnippetItem(
            id: id,
            text: cleanText,
            title: cleanTitle.isEmpty ? nil : cleanTitle,
            isPinned: isPinned
        )
    }

    func withPinned(_ isPinned: Bool) -> ReaderSnippetItem {
        ReaderSnippetItem(id: id, text: text, title: customTitleValue, isPinned: isPinned)
    }

    func withTitle(_ title: String) -> ReaderSnippetItem {
        ReaderSnippetItem(id: id, text: text, title: title, isPinned: isPinned)
    }

    func withText(_ text: String) -> ReaderSnippetItem? {
        ReaderSnippetItem.make(text: text, title: customTitleValue ?? "", id: id, isPinned: isPinned)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case text
        case customTitleValue = "title"
        case pinnedValue = "isPinned"
    }
}

enum PetMood: String {
    case ready
    case working
    case happy
    case error
}

@MainActor
final class ReaderState: ObservableObject {
    private static let historyKey = "readerHistoryItems"
    private static let snippetsKey = "readerSnippetItems"
    private static let historyLimit = 20
    private static let snippetsLimit = 50

    private let defaults: UserDefaults

    @Published var lastText = ""
    @Published var answerText = ""
    @Published var errorText = ""
    @Published var isWorking = false
    @Published var lastImageData: Data?
    @Published var petMessage = "Hi, I am Ani."
    @Published var petMood = PetMood.ready
    @Published private(set) var recentItems: [ReaderHistoryItem] = []
    @Published private(set) var snippets: [ReaderSnippetItem] = []
    @Published private(set) var pulseID = UUID()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        recentItems = Self.loadHistory(from: defaults)
        snippets = Self.loadSnippets(from: defaults)
    }

    func pulse() {
        pulseID = UUID()
    }

    func petSay(_ message: String, mood: PetMood) {
        petMessage = message
        petMood = mood
    }

    func remember(text: String, answer: String = "") {
        guard let item = ReaderHistoryItem.make(text: text, answer: answer) else { return }

        let deduped = recentItems.filter {
            $0.text != item.text || $0.answer != item.answer
        }
        recentItems = Array(([item] + deduped).prefix(Self.historyLimit))
        saveHistory()
    }

    func restore(_ item: ReaderHistoryItem) {
        lastText = item.text
        answerText = item.answer
        lastImageData = nil
        errorText = ""
        isWorking = false
        petSay("Restored recent item.", mood: .happy)
        pulse()
    }

    func clearCurrent(announce: Bool = true) {
        lastText = ""
        answerText = ""
        lastImageData = nil
        errorText = ""
        isWorking = false

        if announce {
            petSay("Reader cleared.", mood: .ready)
            pulse()
        }
    }

    func clearHistory(announce: Bool = true) {
        recentItems = []
        defaults.removeObject(forKey: Self.historyKey)

        if announce {
            petSay("History cleared.", mood: .ready)
            pulse()
        }
    }

    @discardableResult
    func saveSnippet(text: String) -> ReaderSnippetItem? {
        guard let item = ReaderSnippetItem.make(text: text) else { return nil }

        let existingItem = snippets.first { $0.text == item.text }
        let savedItem = ReaderSnippetItem(
            id: item.id,
            text: item.text,
            title: existingItem?.customTitle,
            isPinned: existingItem?.isPinned ?? false
        )
        let deduped = snippets.filter { $0.text != item.text }
        snippets = Self.orderedSnippets([savedItem] + deduped)
        saveSnippets()
        petSay("Saved snippet.", mood: .happy)
        pulse()
        return savedItem
    }

    func clearSnippets(announce: Bool = true) {
        snippets = []
        defaults.removeObject(forKey: Self.snippetsKey)

        if announce {
            petSay("Snippets cleared.", mood: .ready)
            pulse()
        }
    }

    @discardableResult
    func deleteSnippet(_ item: ReaderSnippetItem, announce: Bool = true) -> Bool {
        let originalCount = snippets.count
        snippets.removeAll { $0.id == item.id }
        guard snippets.count != originalCount else { return false }

        if snippets.isEmpty {
            defaults.removeObject(forKey: Self.snippetsKey)
        } else {
            saveSnippets()
        }

        if announce {
            petSay("Deleted snippet.", mood: .ready)
            pulse()
        }

        return true
    }

    func useSnippet(_ item: ReaderSnippetItem) {
        lastText = item.text
        answerText = ""
        lastImageData = nil
        errorText = ""
        isWorking = false
        petSay("Loaded snippet.", mood: .happy)
        pulse()
    }

    @discardableResult
    func setSnippetPinned(_ item: ReaderSnippetItem, isPinned: Bool, announce: Bool = true) -> Bool {
        guard let index = snippets.firstIndex(where: { $0.id == item.id }),
              snippets[index].isPinned != isPinned else {
            return false
        }

        snippets[index] = snippets[index].withPinned(isPinned)
        snippets = Self.orderedSnippets(snippets)
        saveSnippets()

        if announce {
            petSay(isPinned ? "Pinned snippet." : "Unpinned snippet.", mood: .happy)
            pulse()
        }

        return true
    }

    @discardableResult
    func renameSnippet(_ item: ReaderSnippetItem, title: String, announce: Bool = true) -> Bool {
        guard let index = snippets.firstIndex(where: { $0.id == item.id }) else {
            return false
        }

        let updatedItem = snippets[index].withTitle(title)
        guard snippets[index] != updatedItem else {
            return false
        }

        snippets[index] = updatedItem
        saveSnippets()

        if announce {
            petSay("Renamed snippet.", mood: .happy)
            pulse()
        }

        return true
    }

    @discardableResult
    func editSnippetText(_ item: ReaderSnippetItem, text: String, announce: Bool = true) -> Bool {
        guard let index = snippets.firstIndex(where: { $0.id == item.id }),
              let updatedItem = snippets[index].withText(text) else {
            return false
        }

        guard snippets[index] != updatedItem else {
            return false
        }

        var updatedSnippets = snippets
        updatedSnippets[index] = updatedItem
        updatedSnippets.removeAll { $0.id != updatedItem.id && $0.text == updatedItem.text }
        snippets = Self.orderedSnippets(updatedSnippets)
        saveSnippets()

        if announce {
            petSay("Updated snippet.", mood: .happy)
            pulse()
        }

        return true
    }

    func clearLocalReaderData() {
        clearCurrent(announce: false)
        recentItems = []
        snippets = []
        defaults.removeObject(forKey: Self.historyKey)
        defaults.removeObject(forKey: Self.snippetsKey)
        petSay("Local reader data cleared.", mood: .ready)
        pulse()
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(recentItems) else { return }
        defaults.set(data, forKey: Self.historyKey)
    }

    private func saveSnippets() {
        guard let data = try? JSONEncoder().encode(snippets) else { return }
        defaults.set(data, forKey: Self.snippetsKey)
    }

    private static func loadHistory(from defaults: UserDefaults) -> [ReaderHistoryItem] {
        guard let data = defaults.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([ReaderHistoryItem].self, from: data) else {
            return []
        }

        return Array(items.prefix(historyLimit))
    }

    private static func loadSnippets(from defaults: UserDefaults) -> [ReaderSnippetItem] {
        guard let data = defaults.data(forKey: snippetsKey),
              let items = try? JSONDecoder().decode([ReaderSnippetItem].self, from: data) else {
            return []
        }

        return orderedSnippets(items)
    }

    private static func orderedSnippets(_ items: [ReaderSnippetItem]) -> [ReaderSnippetItem] {
        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned }
        return Array((pinned + unpinned).prefix(snippetsLimit))
    }
}
