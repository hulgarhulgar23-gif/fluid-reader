import Foundation

struct ClipboardHistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let text: String

    var preview: String {
        ReaderHistoryItem.preview(for: text, limit: 84)
    }

    static func make(
        text: String,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) -> ClipboardHistoryItem? {
        let cleanText = clean(text)
        guard !cleanText.isEmpty else { return nil }

        return ClipboardHistoryItem(
            id: id,
            createdAt: createdAt,
            text: cleanText
        )
    }

    static func clean(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > ClipboardHistoryStore.maxTextLength else { return trimmed }
        return String(trimmed.prefix(ClipboardHistoryStore.maxTextLength))
    }
}

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    nonisolated static let defaultStorageKey = "clipboardHistoryItems"
    nonisolated static let itemLimit = 50
    nonisolated static let maxTextLength = 8_000

    private let defaults: UserDefaults
    private let storageKey: String
    @Published private(set) var items: [ClipboardHistoryItem]

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ClipboardHistoryStore.defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        items = Self.loadItems(from: defaults, storageKey: storageKey)
    }

    @discardableResult
    func remember(
        text: String,
        createdAt: Date = Date(),
        id: UUID = UUID()
    ) -> ClipboardHistoryItem? {
        guard let item = ClipboardHistoryItem.make(text: text, createdAt: createdAt, id: id) else {
            return nil
        }

        let deduped = items.filter { $0.text != item.text }
        items = Array(([item] + deduped).prefix(Self.itemLimit))
        save()
        return item
    }

    @discardableResult
    func delete(_ item: ClipboardHistoryItem) -> Bool {
        let originalCount = items.count
        items.removeAll { $0.id == item.id }
        guard items.count != originalCount else { return false }

        if items.isEmpty {
            defaults.removeObject(forKey: storageKey)
        } else {
            save()
        }

        return true
    }

    func clear() {
        items = []
        defaults.removeObject(forKey: storageKey)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func loadItems(from defaults: UserDefaults, storageKey: String) -> [ClipboardHistoryItem] {
        guard let data = defaults.data(forKey: storageKey),
              let decodedItems = try? JSONDecoder().decode([ClipboardHistoryItem].self, from: data) else {
            return []
        }

        var sanitizedItems: [ClipboardHistoryItem] = []
        var seenTexts = Set<String>()

        for item in decodedItems {
            guard let sanitizedItem = ClipboardHistoryItem.make(
                text: item.text,
                createdAt: item.createdAt,
                id: item.id
            ) else {
                continue
            }

            guard seenTexts.insert(sanitizedItem.text).inserted else {
                continue
            }

            sanitizedItems.append(sanitizedItem)
            if sanitizedItems.count >= itemLimit {
                break
            }
        }

        return sanitizedItems
    }
}
