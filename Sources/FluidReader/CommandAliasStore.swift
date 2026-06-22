import Foundation

final class CommandAliasStore: ObservableObject {
    private static let defaultKey = "commandAliasEntries"
    private static let maxActionIDLength = 120
    private static let maxAliasesPerAction = 5
    private static let maxAliasLength = 40

    private let defaults: UserDefaults
    private let key: String
    @Published private(set) var aliasesByActionID: [String: [String]]

    init(
        defaults: UserDefaults = .standard,
        key: String = CommandAliasStore.defaultKey
    ) {
        self.defaults = defaults
        self.key = key
        aliasesByActionID = Self.loadAliases(from: defaults, key: key)
    }

    var aliasedActionIDs: [String] {
        aliasesByActionID.keys.sorted()
    }

    func aliases(for actionID: String) -> [String] {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else { return [] }
        return aliasesByActionID[sanitizedActionID] ?? []
    }

    func aliasText(for actionID: String) -> String {
        aliases(for: actionID).joined(separator: ", ")
    }

    @discardableResult
    func setAliases(actionID: String, aliasText: String) -> Bool {
        guard let sanitizedActionID = Self.sanitizedActionID(actionID) else {
            return false
        }

        let nextAliases = Self.normalizedAliases(from: aliasText)
        var nextMap = aliasesByActionID

        let normalizedAliasKeys = Set(nextAliases.map(Self.aliasComparisonKey(_:)))
        if !normalizedAliasKeys.isEmpty {
            for actionID in nextMap.keys where actionID != sanitizedActionID {
                let filteredAliases = (nextMap[actionID] ?? []).filter {
                    !normalizedAliasKeys.contains(Self.aliasComparisonKey($0))
                }
                if filteredAliases.isEmpty {
                    nextMap.removeValue(forKey: actionID)
                } else {
                    nextMap[actionID] = filteredAliases
                }
            }
        }

        if nextAliases.isEmpty {
            nextMap.removeValue(forKey: sanitizedActionID)
        } else {
            nextMap[sanitizedActionID] = nextAliases
        }

        guard nextMap != aliasesByActionID else { return false }
        aliasesByActionID = nextMap
        save()
        return true
    }

    @discardableResult
    func clearAliases(actionID: String) -> Bool {
        setAliases(actionID: actionID, aliasText: "")
    }

    func backupEntries() -> [String: [String]] {
        aliasesByActionID
    }

    @discardableResult
    func restoreEntries(_ entries: [String: [String]]) -> Bool {
        let sanitizedEntries = Self.sanitizedEntries(entries)
        guard sanitizedEntries != aliasesByActionID else { return false }
        aliasesByActionID = sanitizedEntries
        save()
        return true
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(aliasesByActionID) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadAliases(from defaults: UserDefaults, key: String) -> [String: [String]] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }

        var sanitized: [String: [String]] = [:]
        for (actionID, aliases) in decoded {
            guard let sanitizedActionID = sanitizedActionID(actionID) else { continue }
            let normalizedAliases = normalizedAliases(from: aliases.joined(separator: ", "))
            guard !normalizedAliases.isEmpty else { continue }
            sanitized[sanitizedActionID] = normalizedAliases
        }
        return sanitized
    }

    private static func sanitizedEntries(_ entries: [String: [String]]) -> [String: [String]] {
        var sanitized: [String: [String]] = [:]
        for (actionID, aliases) in entries {
            guard let sanitizedActionID = sanitizedActionID(actionID) else { continue }
            let normalizedAliases = normalizedAliases(from: aliases.joined(separator: ", "))
            guard !normalizedAliases.isEmpty else { continue }
            sanitized[sanitizedActionID] = normalizedAliases
        }
        return sanitized
    }

    private static func normalizedAliases(from rawValue: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",\n")
        let rawAliases = rawValue.components(separatedBy: separators)

        var seen = Set<String>()
        var normalizedAliases: [String] = []

        for rawAlias in rawAliases {
            let collapsedAlias = rawAlias
                .split(whereSeparator: \.isWhitespace)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !collapsedAlias.isEmpty else { continue }

            let limitedAlias = String(collapsedAlias.prefix(maxAliasLength))
            let comparisonKey = aliasComparisonKey(limitedAlias)
            guard seen.insert(comparisonKey).inserted else { continue }

            normalizedAliases.append(limitedAlias)
            if normalizedAliases.count >= maxAliasesPerAction {
                break
            }
        }

        return normalizedAliases
    }

    private static func aliasComparisonKey(_ alias: String) -> String {
        alias
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private static func sanitizedActionID(_ actionID: String) -> String? {
        let trimmedActionID = actionID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedActionID.isEmpty,
              trimmedActionID.count <= maxActionIDLength else {
            return nil
        }
        return trimmedActionID
    }
}
