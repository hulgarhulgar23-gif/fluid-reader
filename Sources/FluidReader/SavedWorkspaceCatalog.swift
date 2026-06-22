import Foundation

enum SavedWorkspaceFilter: String, CaseIterable, Identifiable {
    case all
    case notes
    case links
    case clipboard
    case recent
    case pinned

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .notes:
            return "Notes"
        case .links:
            return "Links"
        case .clipboard:
            return "Clipboard"
        case .recent:
            return "Recent"
        case .pinned:
            return "Pinned"
        }
    }
}

enum SavedWorkspaceItem: Identifiable, Equatable {
    case note(ReaderSnippetItem)
    case link(QuickLinkItem)
    case clipboard(ClipboardHistoryItem)
    case recent(ReaderHistoryItem)

    var id: String {
        switch self {
        case .note(let item):
            return "note-\(item.id.uuidString.lowercased())"
        case .link(let item):
            return "link-\(item.id.uuidString.lowercased())"
        case .clipboard(let item):
            return "clipboard-\(item.id.uuidString.lowercased())"
        case .recent(let item):
            return "recent-\(item.id.uuidString.lowercased())"
        }
    }

    var title: String {
        switch self {
        case .note(let item):
            return item.title
        case .link(let item):
            return item.title
        case .clipboard(let item):
            return item.preview
        case .recent(let item):
            return item.preview
        }
    }

    var subtitle: String {
        switch self {
        case .note(let item):
            return item.isPinned ? "Pinned note" : (item.customTitle != nil ? "Named note" : "Quick capture")
        case .link(let item):
            return item.displayURL
        case .clipboard:
            return "Clipboard history item"
        case .recent(let item):
            return item.detail
        }
    }

    var isPinned: Bool {
        switch self {
        case .note(let item):
            return item.isPinned
        case .link(let item):
            return item.isPinned
        case .clipboard, .recent:
            return false
        }
    }

    var sectionTitle: String {
        switch self {
        case .note:
            return "Notes"
        case .link:
            return "Quick Links"
        case .clipboard:
            return "Clipboard History"
        case .recent:
            return "Recent Reader Items"
        }
    }

    var keywords: [String] {
        switch self {
        case .note(let item):
            return [
                "note",
                "notes",
                "snippet",
                "workspace",
                item.title,
                item.text,
                item.isPinned ? "pinned" : "saved",
                item.customTitle != nil ? "named" : "quick capture"
            ]
        case .link(let item):
            return [
                "link",
                "links",
                "quick link",
                "saved",
                item.title,
                item.urlString,
                item.displayURL,
                item.isPinned ? "pinned" : "saved"
            ]
        case .clipboard(let item):
            return [
                "clipboard",
                "history",
                "saved",
                item.text
            ]
        case .recent(let item):
            return [
                "recent",
                "history",
                "reader",
                item.detail,
                item.text,
                item.answer
            ]
        }
    }
}

struct SavedWorkspaceSummary: Equatable {
    let noteCount: Int
    let pinnedNoteCount: Int
    let linkCount: Int
    let pinnedLinkCount: Int
    let clipboardCount: Int
    let recentCount: Int
    let totalCount: Int
    let clipboardEnabled: Bool
    let recentEnabled: Bool

    var actionSubtitle: String {
        guard totalCount > 0 else {
            return "Create and search notes, links, clipboard history, and recent items in one local workspace"
        }

        var parts: [String] = []
        if noteCount > 0 {
            parts.append("\(noteCount) \(noteCount == 1 ? "note" : "notes")")
        }
        if linkCount > 0 {
            parts.append("\(linkCount) \(linkCount == 1 ? "link" : "links")")
        }
        if clipboardEnabled, clipboardCount > 0 {
            parts.append("\(clipboardCount) clipboard")
        }
        if recentEnabled, recentCount > 0 {
            parts.append("\(recentCount) recent")
        }

        if parts.isEmpty {
            return "Browse saved items in one local workspace"
        }

        return "Browse \(parts.joined(separator: " · ")) in one local workspace"
    }
}

enum SavedWorkspaceCatalog {
    static func summary(
        notes: [ReaderSnippetItem],
        quickLinks: [QuickLinkItem],
        clipboardHistory: [ClipboardHistoryItem],
        recentItems: [ReaderHistoryItem],
        clipboardEnabled: Bool,
        recentEnabled: Bool
    ) -> SavedWorkspaceSummary {
        let noteCount = notes.count
        let linkCount = quickLinks.count
        let visibleClipboardCount = clipboardEnabled ? clipboardHistory.count : 0
        let visibleRecentCount = recentEnabled ? recentItems.count : 0

        return SavedWorkspaceSummary(
            noteCount: noteCount,
            pinnedNoteCount: notes.filter(\.isPinned).count,
            linkCount: linkCount,
            pinnedLinkCount: quickLinks.filter(\.isPinned).count,
            clipboardCount: visibleClipboardCount,
            recentCount: visibleRecentCount,
            totalCount: noteCount + linkCount + visibleClipboardCount + visibleRecentCount,
            clipboardEnabled: clipboardEnabled,
            recentEnabled: recentEnabled
        )
    }

    static func items(
        notes: [ReaderSnippetItem],
        quickLinks: [QuickLinkItem],
        clipboardHistory: [ClipboardHistoryItem],
        recentItems: [ReaderHistoryItem]
    ) -> [SavedWorkspaceItem] {
        notes.map(SavedWorkspaceItem.note)
            + quickLinks.map(SavedWorkspaceItem.link)
            + clipboardHistory.map(SavedWorkspaceItem.clipboard)
            + recentItems.map(SavedWorkspaceItem.recent)
    }

    static func filteredItems(
        _ items: [SavedWorkspaceItem],
        query: String,
        filter: SavedWorkspaceFilter = .all
    ) -> [SavedWorkspaceItem] {
        let scopedItems = items.filter { filter.matches($0) }
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return scopedItems }

        let foldedQuery = cleanQuery
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let terms = foldedQuery.split(whereSeparator: \.isWhitespace).map(String.init)

        return scopedItems.filter { item in
            let haystack = ([item.title, item.subtitle, item.sectionTitle] + item.keywords)
                .joined(separator: "\n")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    static func count(
        _ items: [SavedWorkspaceItem],
        filter: SavedWorkspaceFilter
    ) -> Int {
        filteredItems(items, query: "", filter: filter).count
    }
}

private extension SavedWorkspaceFilter {
    func matches(_ item: SavedWorkspaceItem) -> Bool {
        switch self {
        case .all:
            return true
        case .notes:
            if case .note = item { return true }
            return false
        case .links:
            if case .link = item { return true }
            return false
        case .clipboard:
            if case .clipboard = item { return true }
            return false
        case .recent:
            if case .recent = item { return true }
            return false
        case .pinned:
            return item.isPinned
        }
    }
}
