import Foundation

struct QuickLinkItem: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let urlString: String
    private let pinnedValue: Bool?

    var isPinned: Bool {
        pinnedValue == true
    }

    var preview: String {
        ReaderHistoryItem.preview(for: title, limit: 84)
    }

    var displayURL: String {
        ReaderHistoryItem.preview(for: urlString, limit: 96)
    }

    var url: URL? {
        URL(string: urlString)
    }

    init(id: UUID, title: String, urlString: String, isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.urlString = urlString
        pinnedValue = isPinned ? true : nil
    }

    static func make(
        urlString: String,
        title: String = "",
        id: UUID = UUID(),
        isPinned: Bool = false
    ) -> QuickLinkItem? {
        guard let normalizedURL = normalizedURLString(urlString) else { return nil }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return QuickLinkItem(
            id: id,
            title: cleanTitle.isEmpty ? defaultTitle(for: normalizedURL) : cleanTitle,
            urlString: normalizedURL,
            isPinned: isPinned
        )
    }

    func withPinned(_ isPinned: Bool) -> QuickLinkItem {
        QuickLinkItem(id: id, title: title, urlString: urlString, isPinned: isPinned)
    }

    func withTitle(_ title: String) -> QuickLinkItem {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedTitle = cleanTitle.isEmpty ? Self.defaultTitle(for: urlString) : cleanTitle
        return QuickLinkItem(id: id, title: resolvedTitle, urlString: urlString, isPinned: isPinned)
    }

    func withURL(_ urlString: String) -> QuickLinkItem? {
        QuickLinkItem.make(
            urlString: urlString,
            title: title,
            id: id,
            isPinned: isPinned
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case urlString
        case pinnedValue = "isPinned"
    }

    private static func normalizedURLString(_ rawValue: String) -> String? {
        var candidate = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !candidate.isEmpty else { return nil }
        guard candidate.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }

        let lowercased = candidate.lowercased()
        if !lowercased.contains("://"), !lowercased.hasPrefix("mailto:"), candidate.contains(".") {
            candidate = "https://\(candidate)"
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "mailto"].contains(scheme) else {
            return nil
        }

        if scheme == "http" || scheme == "https" {
            guard url.user == nil,
                  url.password == nil,
                  let host = url.host,
                  !host.isEmpty else { return nil }
        }

        if scheme == "mailto" {
            let address = String(url.absoluteString.dropFirst("mailto:".count))
            guard !address.isEmpty else { return nil }
        }

        return url.absoluteString
    }

    private static func defaultTitle(for urlString: String) -> String {
        guard let url = URL(string: urlString) else { return "Quick Link" }

        if url.scheme?.lowercased() == "mailto" {
            let address = String(url.absoluteString.dropFirst("mailto:".count))
            return "Email \(address)"
        }

        let host = url.host?.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        let firstPathPart = url.pathComponents.dropFirst().first?
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        switch (host, firstPathPart) {
        case let (.some(host), .some(part)) where !part.isEmpty:
            return "\(host) \(part)"
        case let (.some(host), _):
            return host
        default:
            return "Quick Link"
        }
    }
}

@MainActor
final class QuickLinkStore: ObservableObject {
    nonisolated static let defaultStorageKey = "quickLinkItems"
    nonisolated static let itemLimit = 50

    private let defaults: UserDefaults
    private let storageKey: String
    @Published private(set) var items: [QuickLinkItem]

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = QuickLinkStore.defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        items = Self.loadItems(from: defaults, storageKey: storageKey)
    }

    @discardableResult
    func saveLink(urlString: String, title: String = "") -> QuickLinkItem? {
        guard let item = QuickLinkItem.make(urlString: urlString, title: title) else { return nil }

        let savedItem = item.withPinned(items.first { $0.urlString == item.urlString }?.isPinned ?? false)
        let deduped = items.filter { $0.urlString != item.urlString }
        items = Self.orderedItems([savedItem] + deduped)
        save()
        return savedItem
    }

    @discardableResult
    func setPinned(_ item: QuickLinkItem, isPinned: Bool) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              items[index].isPinned != isPinned else {
            return false
        }

        items[index] = items[index].withPinned(isPinned)
        items = Self.orderedItems(items)
        save()
        return true
    }

    @discardableResult
    func delete(_ item: QuickLinkItem) -> Bool {
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

    @discardableResult
    func updateTitle(_ item: QuickLinkItem, title: String) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return false
        }

        let updatedItem = items[index].withTitle(title)
        guard items[index] != updatedItem else {
            return false
        }

        items[index] = updatedItem
        save()
        return true
    }

    @discardableResult
    func updateURL(_ item: QuickLinkItem, urlString: String) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              let proposedItem = items[index].withURL(urlString) else {
            return false
        }

        var updatedItem = proposedItem
        let mergedPinned = items[index].isPinned || items.contains {
            $0.id != proposedItem.id && $0.urlString == proposedItem.urlString && $0.isPinned
        }
        if mergedPinned != proposedItem.isPinned {
            updatedItem = proposedItem.withPinned(mergedPinned)
        }

        guard items[index] != updatedItem else {
            return false
        }

        var nextItems = items
        nextItems[index] = updatedItem
        nextItems.removeAll { $0.id != updatedItem.id && $0.urlString == updatedItem.urlString }
        items = Self.orderedItems(nextItems)
        save()
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

    private static func loadItems(from defaults: UserDefaults, storageKey: String) -> [QuickLinkItem] {
        guard let data = defaults.data(forKey: storageKey),
              let decodedItems = try? JSONDecoder().decode([QuickLinkItem].self, from: data) else {
            return []
        }

        var sanitizedItems: [QuickLinkItem] = []
        var indexByURLString: [String: Int] = [:]

        for item in decodedItems {
            guard let sanitizedItem = QuickLinkItem.make(
                urlString: item.urlString,
                title: item.title,
                id: item.id,
                isPinned: item.isPinned
            ) else {
                continue
            }

            if let existingIndex = indexByURLString[sanitizedItem.urlString] {
                if sanitizedItem.isPinned, !sanitizedItems[existingIndex].isPinned {
                    sanitizedItems[existingIndex] = sanitizedItems[existingIndex].withPinned(true)
                }
                continue
            }

            indexByURLString[sanitizedItem.urlString] = sanitizedItems.count
            sanitizedItems.append(sanitizedItem)
        }

        return orderedItems(sanitizedItems)
    }

    private static func orderedItems(_ items: [QuickLinkItem]) -> [QuickLinkItem] {
        let pinned = items.filter(\.isPinned)
        let unpinned = items.filter { !$0.isPinned }
        return Array((pinned + unpinned).prefix(itemLimit))
    }
}
