import Foundation

enum NotesWorkspaceFilter: String, CaseIterable, Identifiable {
    case all
    case pinned
    case titled
    case quickCapture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .pinned:
            return "Pinned"
        case .titled:
            return "Named"
        case .quickCapture:
            return "Quick Capture"
        }
    }
}

struct NotesWorkspaceSummary: Equatable {
    let totalCount: Int
    let pinnedCount: Int
    let titledCount: Int
    let quickCaptureCount: Int

    var actionSubtitle: String {
        guard totalCount > 0 else {
            return "Create and search local notes in one workspace"
        }
        let noteNoun = totalCount == 1 ? "note" : "notes"
        let pinnedSuffix = pinnedCount > 0 ? " · \(pinnedCount) pinned" : ""
        return "Browse \(totalCount) saved \(noteNoun)\(pinnedSuffix) in one local workspace"
    }
}

enum NotesWorkspaceCatalog {
    static func summary(_ notes: [ReaderSnippetItem]) -> NotesWorkspaceSummary {
        let pinnedCount = notes.filter(\.isPinned).count
        let titledCount = notes.filter { $0.customTitle != nil }.count
        let totalCount = notes.count
        return NotesWorkspaceSummary(
            totalCount: totalCount,
            pinnedCount: pinnedCount,
            titledCount: titledCount,
            quickCaptureCount: max(0, totalCount - titledCount)
        )
    }

    static func count(
        _ notes: [ReaderSnippetItem],
        filter: NotesWorkspaceFilter
    ) -> Int {
        filteredNotes(notes, query: "", filter: filter).count
    }

    static func filteredNotes(
        _ notes: [ReaderSnippetItem],
        query: String,
        filter: NotesWorkspaceFilter = .all
    ) -> [ReaderSnippetItem] {
        let scopedNotes = notes.filter { filter.matches($0) }
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return scopedNotes }

        let terms = cleanQuery
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        return scopedNotes.filter { item in
            let haystack = [
                item.title,
                item.text,
                item.isPinned ? "pinned note" : "saved note",
                item.customTitle != nil ? "named note" : "quick capture",
                "note",
                "notes",
                "workspace"
            ]
            .joined(separator: "\n")
            .lowercased()

            return terms.allSatisfy { haystack.contains($0) }
        }
    }
}

private extension NotesWorkspaceFilter {
    func matches(_ item: ReaderSnippetItem) -> Bool {
        switch self {
        case .all:
            return true
        case .pinned:
            return item.isPinned
        case .titled:
            return item.customTitle != nil
        case .quickCapture:
            return item.customTitle == nil
        }
    }
}
