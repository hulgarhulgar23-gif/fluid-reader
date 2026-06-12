import Foundation

struct ActivityLogItem: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    let category: String
    let detail: String
}

final class ActivityLogStore {
    static let defaultStorageKey = "activityLogItems"
    static let maxItemCount = 80

    private let defaults: UserDefaults
    private let storageKey: String
    private(set) var items: [ActivityLogItem]

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = ActivityLogStore.defaultStorageKey
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        items = Self.loadItems(from: defaults, storageKey: storageKey)
    }

    func record(category: String, detail: String, at date: Date = Date()) {
        let item = ActivityLogItem(
            id: UUID(),
            createdAt: date,
            category: ActivityLogText.safeOneLine(category, fallback: "event"),
            detail: ActivityLogText.safeOneLine(detail, fallback: "ok")
        )

        items.insert(item, at: 0)
        if items.count > Self.maxItemCount {
            items = Array(items.prefix(Self.maxItemCount))
        }
        save()
    }

    func clear() {
        items = []
        defaults.removeObject(forKey: storageKey)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func loadItems(from defaults: UserDefaults, storageKey: String) -> [ActivityLogItem] {
        guard let data = defaults.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([ActivityLogItem].self, from: data) else {
            return []
        }
        return Array(items.prefix(maxItemCount))
    }
}

enum ActivityLogCommand {
    static func safeID(_ id: String) -> String {
        if id.hasPrefix("recent-") {
            return "recent-item"
        }
        if id.hasPrefix("snippet-")
            || id.hasPrefix("use-snippet-")
            || id.hasPrefix("paste-snippet-")
            || id.hasPrefix("delete-snippet-")
            || id.hasPrefix("pin-snippet-")
            || id.hasPrefix("edit-snippet-") {
            return "snippet-item"
        }
        if id.hasPrefix("quick-link-")
            || id.hasPrefix("copy-quick-link-")
            || id.hasPrefix("delete-quick-link-")
            || id.hasPrefix("pin-quick-link-")
            || id.hasPrefix("edit-quick-link-") {
            return "quick-link-item"
        }
        if id.hasPrefix("clipboard-history-")
            || id.hasPrefix("use-clipboard-history-")
            || id.hasPrefix("paste-clipboard-history-")
            || id.hasPrefix("delete-clipboard-history-") {
            return "clipboard-history-item"
        }
        if id.hasPrefix("app-launch-") {
            return "app-launch"
        }

        return ActivityLogText.safeOneLine(id, fallback: "command")
    }
}

enum ActivityLogReport {
    static func markdown(items: [ActivityLogItem]) -> String? {
        guard !items.isEmpty else { return nil }

        let lines = items.map { item in
            "- \(timestamp(item.createdAt)) | \(item.category) | \(item.detail)"
        }

        return """
        # Fluid Reader Activity Log

        No API keys or private content.

        \(lines.joined(separator: "\n"))
        """
    }

    private static func timestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

private enum ActivityLogText {
    static let maxLength = 120

    static func safeOneLine(_ value: String, fallback: String) -> String {
        let oneLine = value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !oneLine.isEmpty else { return fallback }
        if oneLine.count <= maxLength {
            return oneLine
        }
        return "\(oneLine.prefix(maxLength))..."
    }
}
