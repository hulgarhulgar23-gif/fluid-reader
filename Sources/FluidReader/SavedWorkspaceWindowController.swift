import AppKit
import SwiftUI

@MainActor
final class SavedWorkspaceWindowController {
    private static let preferredContentSize = NSSize(width: 820, height: 680)
    private static let minContentSize = NSSize(width: 620, height: 460)
    private static let maxContentSize = NSSize(width: 1080, height: 900)

    private let window: NSWindow

    init(
        settings: SettingsStore,
        state: ReaderState,
        quickLinkStore: QuickLinkStore,
        clipboardHistoryStore: ClipboardHistoryStore,
        copyNote: @escaping (ReaderSnippetItem) -> Void,
        openNote: @escaping (ReaderSnippetItem) -> Void,
        createNote: @escaping (_ title: String, _ text: String) -> Void,
        updateNote: @escaping (_ item: ReaderSnippetItem, _ title: String, _ text: String) -> Void,
        toggleNotePinned: @escaping (ReaderSnippetItem) -> Void,
        deleteNote: @escaping (ReaderSnippetItem) -> Void,
        clearNotes: @escaping () -> Void,
        openQuickLink: @escaping (QuickLinkItem) -> Void,
        copyQuickLink: @escaping (QuickLinkItem) -> Void,
        updateQuickLink: @escaping (_ item: QuickLinkItem, _ title: String, _ urlString: String) -> Void,
        toggleQuickLinkPinned: @escaping (QuickLinkItem) -> Void,
        deleteQuickLink: @escaping (QuickLinkItem) -> Void,
        clearQuickLinks: @escaping () -> Void,
        copyClipboardHistoryItem: @escaping (ClipboardHistoryItem) -> Void,
        deleteClipboardHistoryItem: @escaping (ClipboardHistoryItem) -> Void,
        clearClipboardHistory: @escaping () -> Void,
        restoreRecentItem: @escaping (ReaderHistoryItem) -> Void,
        copyRecentItem: @escaping (ReaderHistoryItem) -> Void,
        deleteRecentItem: @escaping (ReaderHistoryItem) -> Void,
        clearRecentItems: @escaping () -> Void,
        importClipboardLinks: @escaping () -> Void
    ) {
        let view = SavedWorkspaceView(
            settings: settings,
            state: state,
            quickLinkStore: quickLinkStore,
            clipboardHistoryStore: clipboardHistoryStore,
            copyNote: copyNote,
            openNote: openNote,
            createNote: createNote,
            updateNote: updateNote,
            toggleNotePinned: toggleNotePinned,
            deleteNote: deleteNote,
            clearNotes: clearNotes,
            openQuickLink: openQuickLink,
            copyQuickLink: copyQuickLink,
            updateQuickLink: updateQuickLink,
            toggleQuickLinkPinned: toggleQuickLinkPinned,
            deleteQuickLink: deleteQuickLink,
            clearQuickLinks: clearQuickLinks,
            copyClipboardHistoryItem: copyClipboardHistoryItem,
            deleteClipboardHistoryItem: deleteClipboardHistoryItem,
            clearClipboardHistory: clearClipboardHistory,
            restoreRecentItem: restoreRecentItem,
            copyRecentItem: copyRecentItem,
            deleteRecentItem: deleteRecentItem,
            clearRecentItems: clearRecentItems,
            importClipboardLinks: importClipboardLinks
        )

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Saved Workspace"
        WindowBounds.apply(
            to: window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.minContentSize,
            maxContentSize: Self.maxContentSize
        )
        window.contentViewController = NSHostingController(rootView: view)
    }

    func show() {
        guard !RuntimeEnvironment.suppressesExternalEffects else { return }
        WindowBounds.apply(
            to: window,
            preferredContentSize: Self.preferredContentSize,
            minContentSize: Self.minContentSize,
            maxContentSize: Self.maxContentSize
        )
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct SavedWorkspaceView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: ReaderState
    @ObservedObject var quickLinkStore: QuickLinkStore
    @ObservedObject var clipboardHistoryStore: ClipboardHistoryStore

    let copyNote: (ReaderSnippetItem) -> Void
    let openNote: (ReaderSnippetItem) -> Void
    let createNote: (_ title: String, _ text: String) -> Void
    let updateNote: (_ item: ReaderSnippetItem, _ title: String, _ text: String) -> Void
    let toggleNotePinned: (ReaderSnippetItem) -> Void
    let deleteNote: (ReaderSnippetItem) -> Void
    let clearNotes: () -> Void
    let openQuickLink: (QuickLinkItem) -> Void
    let copyQuickLink: (QuickLinkItem) -> Void
    let updateQuickLink: (_ item: QuickLinkItem, _ title: String, _ urlString: String) -> Void
    let toggleQuickLinkPinned: (QuickLinkItem) -> Void
    let deleteQuickLink: (QuickLinkItem) -> Void
    let clearQuickLinks: () -> Void
    let copyClipboardHistoryItem: (ClipboardHistoryItem) -> Void
    let deleteClipboardHistoryItem: (ClipboardHistoryItem) -> Void
    let clearClipboardHistory: () -> Void
    let restoreRecentItem: (ReaderHistoryItem) -> Void
    let copyRecentItem: (ReaderHistoryItem) -> Void
    let deleteRecentItem: (ReaderHistoryItem) -> Void
    let clearRecentItems: () -> Void
    let importClipboardLinks: () -> Void

    @State private var searchQuery = ""
    @State private var selectedFilter = SavedWorkspaceFilter.all
    @State private var noteEditorContext: SavedNoteEditorContext?
    @State private var linkEditorContext: SavedLinkEditorContext?

    private var visibleClipboardHistoryItems: [ClipboardHistoryItem] {
        settings.saveClipboardHistory ? clipboardHistoryStore.items : []
    }

    private var visibleRecentItems: [ReaderHistoryItem] {
        settings.saveRecentItems ? state.recentItems : []
    }

    private var workspaceSummary: SavedWorkspaceSummary {
        SavedWorkspaceCatalog.summary(
            notes: state.snippets,
            quickLinks: quickLinkStore.items,
            clipboardHistory: visibleClipboardHistoryItems,
            recentItems: visibleRecentItems,
            clipboardEnabled: settings.saveClipboardHistory,
            recentEnabled: settings.saveRecentItems
        )
    }

    private var allItems: [SavedWorkspaceItem] {
        SavedWorkspaceCatalog.items(
            notes: state.snippets,
            quickLinks: quickLinkStore.items,
            clipboardHistory: visibleClipboardHistoryItems,
            recentItems: visibleRecentItems
        )
    }

    private var filteredItems: [SavedWorkspaceItem] {
        SavedWorkspaceCatalog.filteredItems(
            allItems,
            query: searchQuery,
            filter: selectedFilter
        )
    }

    private var filteredNoteItems: [ReaderSnippetItem] {
        filteredItems.compactMap { item in
            guard case .note(let note) = item else { return nil }
            return note
        }
    }

    private var filteredLinkItems: [QuickLinkItem] {
        filteredItems.compactMap { item in
            guard case .link(let link) = item else { return nil }
            return link
        }
    }

    private var filteredClipboardItems: [ClipboardHistoryItem] {
        filteredItems.compactMap { item in
            guard case .clipboard(let clipboardItem) = item else { return nil }
            return clipboardItem
        }
    }

    private var filteredRecentItems: [ReaderHistoryItem] {
        filteredItems.compactMap { item in
            guard case .recent(let recentItem) = item else { return nil }
            return recentItem
        }
    }

    private var selectedFilterItemCount: Int {
        SavedWorkspaceCatalog.count(allItems, filter: selectedFilter)
    }

    private var itemListStatusTitle: String {
        let cleanQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty {
            let noun = selectedFilterItemCount == 1 ? "item" : "items"
            return "\(selectedFilterItemCount) \(noun)"
        }
        let shownCount = filteredItems.count
        let noun = shownCount == 1 ? "match" : "matches"
        return "\(shownCount) \(noun)"
    }

    private var emptyStateText: String {
        let cleanQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.isEmpty else {
            return "Try a shorter search, or search by note title, link title, URL, clipboard text, or recent reader text."
        }

        if workspaceSummary.totalCount == 0 {
            return "Saved notes, quick links, clipboard history, and recent reader items all gather here. Create a note, save a link, or turn on the optional history lanes to grow this workspace."
        }

        switch selectedFilter {
        case .all:
            return "No saved items are available right now."
        case .notes:
            return "No notes yet. Save text from the launcher or reader and it will land here."
        case .links:
            return "No quick links yet. Save a URL from Commands or import links from the clipboard."
        case .clipboard:
            return settings.saveClipboardHistory
                ? "No clipboard history items yet. Copy something new to start filling this lane."
                : "Clipboard history is off. Turn it on here or in Settings to search clipboard items."
        case .recent:
            return settings.saveRecentItems
                ? "No recent reader items yet. Read or ask something and it will appear here."
                : "Recent items are off. Turn them on here or in Settings to keep a local recent lane."
        case .pinned:
            return "No pinned notes or links yet. Pin important items to keep them at the top."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Saved Workspace", systemImage: "tray.full")
                        .font(.title3.weight(.semibold))
                    Text("Local-first notes, quick links, clipboard history, and recent reader items stay searchable from the launcher and manageable in one place.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button("New Note") {
                        noteEditorContext = .new
                    }
                    .keyboardShortcut("n", modifiers: [.command])

                    Button("Import Links") {
                        importClipboardLinks()
                    }

                    if !settings.saveClipboardHistory {
                        Button("Turn On Clipboard") {
                            settings.saveClipboardHistory = true
                        }
                    }

                    if !settings.saveRecentItems {
                        Button("Turn On Recent") {
                            settings.saveRecentItems = true
                        }
                    }
                }
            }

            summaryGrid

            HStack(spacing: 10) {
                TextField("Search saved items", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Text(itemListStatusTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            }

            filterBar

            Text("Notes, links, clipboard history, and recent reader items still show up in root search, but this workspace gives them one calmer management surface.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if filteredItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No saved items yet." : "No saved items matched.")
                        .font(.headline)
                    Text(emptyStateText)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !filteredNoteItems.isEmpty {
                            noteSection
                        }
                        if !filteredLinkItems.isEmpty {
                            linkSection
                        }
                        if !filteredClipboardItems.isEmpty {
                            clipboardSection
                        }
                        if !filteredRecentItems.isEmpty {
                            recentSection
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .sheet(item: $noteEditorContext) { context in
            SavedNoteEditorSheet(
                title: context.item == nil ? "New Note" : "Edit Note",
                initialTitle: context.title,
                initialText: context.text
            ) { title, text in
                if let item = context.item {
                    updateNote(item, title, text)
                } else {
                    createNote(title, text)
                }
            }
        }
        .sheet(item: $linkEditorContext) { context in
            SavedLinkEditorSheet(
                title: "Edit Link",
                initialTitle: context.title,
                initialURL: context.urlString
            ) { title, urlString in
                updateQuickLink(context.item, title, urlString)
            }
        }
    }

    private var summaryGrid: some View {
        let summary = workspaceSummary
        return LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 120), spacing: 8),
                GridItem(.flexible(minimum: 120), spacing: 8)
            ],
            alignment: .leading,
            spacing: 8
        ) {
            summaryCard(
                title: "Notes",
                value: summary.noteCount,
                detail: summary.pinnedNoteCount == 0 ? "Local note lane" : "\(summary.pinnedNoteCount) pinned"
            )
            summaryCard(
                title: "Links",
                value: summary.linkCount,
                detail: summary.pinnedLinkCount == 0 ? "Saved URLs" : "\(summary.pinnedLinkCount) pinned"
            )
            summaryCard(
                title: "Clipboard",
                value: summary.clipboardEnabled ? "\(summary.clipboardCount)" : "Off",
                detail: summary.clipboardEnabled ? "History lane" : "Optional lane"
            )
            summaryCard(
                title: "Recent",
                value: summary.recentEnabled ? "\(summary.recentCount)" : "Off",
                detail: summary.recentEnabled ? "Reader history" : "Optional lane"
            )
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SavedWorkspaceFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.title)
                            Text("\(SavedWorkspaceCatalog.count(allItems, filter: filter))")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(selectedFilter == filter ? Color.accentColor : Color.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            selectedFilter == filter
                                ? Color.accentColor.opacity(0.14)
                                : Color(nsColor: .textBackgroundColor).opacity(0.34)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(
                                    selectedFilter == filter
                                        ? Color.accentColor.opacity(0.28)
                                        : Color.secondary.opacity(0.16),
                                    lineWidth: 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Notes",
                count: filteredNoteItems.count
            ) {
                if !state.snippets.isEmpty {
                    Button("Clear") {
                        clearNotes()
                    }
                    .controlSize(.small)
                }
            }

            ForEach(filteredNoteItems) { item in
                noteRow(item)
            }
        }
    }

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Quick Links",
                count: filteredLinkItems.count
            ) {
                if !quickLinkStore.items.isEmpty {
                    Button("Clear") {
                        clearQuickLinks()
                    }
                    .controlSize(.small)
                }
            }

            ForEach(filteredLinkItems) { item in
                linkRow(item)
            }
        }
    }

    private var clipboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Clipboard History",
                count: filteredClipboardItems.count
            ) {
                if !settings.saveClipboardHistory {
                    Button("Turn On") {
                        settings.saveClipboardHistory = true
                    }
                    .controlSize(.small)
                } else if !clipboardHistoryStore.items.isEmpty {
                    Button("Clear") {
                        clearClipboardHistory()
                    }
                    .controlSize(.small)
                }
            }

            ForEach(filteredClipboardItems) { item in
                clipboardRow(item)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Recent Reader Items",
                count: filteredRecentItems.count
            ) {
                if !settings.saveRecentItems {
                    Button("Turn On") {
                        settings.saveRecentItems = true
                    }
                    .controlSize(.small)
                } else if !state.recentItems.isEmpty {
                    Button("Clear") {
                        clearRecentItems()
                    }
                    .controlSize(.small)
                }
            }

            ForEach(filteredRecentItems) { item in
                recentRow(item)
            }
        }
    }

    @ViewBuilder
    private func sectionHeader<Actions: View>(
        title: String,
        count: Int,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
            Text("\(count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            actions()
        }
    }

    private func noteRow(_ item: ReaderSnippetItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                ForEach(noteMetadataTitles(for: item), id: \.self) { title in
                    metadataChip(title)
                }

                Spacer()
            }

            Text(item.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("Open") {
                    openNote(item)
                }
                .controlSize(.small)

                Button("Copy") {
                    copyNote(item)
                }
                .controlSize(.small)

                Button("Edit") {
                    noteEditorContext = .edit(item)
                }
                .controlSize(.small)

                Button(item.isPinned ? "Unpin" : "Pin") {
                    toggleNotePinned(item)
                }
                .controlSize(.small)

                Spacer()

                Button("Delete", role: .destructive) {
                    deleteNote(item)
                }
                .controlSize(.small)
            }
        }
    }

    private func linkRow(_ item: QuickLinkItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                ForEach(linkMetadataTitles(for: item), id: \.self) { title in
                    metadataChip(title)
                }

                Spacer()
            }

            Text(item.urlString)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("Open") {
                    openQuickLink(item)
                }
                .controlSize(.small)

                Button("Copy") {
                    copyQuickLink(item)
                }
                .controlSize(.small)

                Button("Edit") {
                    linkEditorContext = SavedLinkEditorContext(item: item)
                }
                .controlSize(.small)

                Button(item.isPinned ? "Unpin" : "Pin") {
                    toggleQuickLinkPinned(item)
                }
                .controlSize(.small)

                Spacer()

                Button("Delete", role: .destructive) {
                    deleteQuickLink(item)
                }
                .controlSize(.small)
            }
        }
    }

    private func clipboardRow(_ item: ClipboardHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.preview)
                    .font(.headline)
                    .lineLimit(1)
                metadataChip("Clipboard")
                Spacer()
            }

            Text(item.text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("Copy") {
                    copyClipboardHistoryItem(item)
                }
                .controlSize(.small)

                Spacer()

                Button("Delete", role: .destructive) {
                    deleteClipboardHistoryItem(item)
                }
                .controlSize(.small)
            }
        }
    }

    private func recentRow(_ item: ReaderHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.preview)
                    .font(.headline)
                    .lineLimit(1)

                ForEach(recentMetadataTitles(for: item), id: \.self) { title in
                    metadataChip(title)
                }

                Spacer()
            }

            Text(recentPreviewText(for: item))
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("Restore") {
                    restoreRecentItem(item)
                }
                .controlSize(.small)

                Button("Copy") {
                    copyRecentItem(item)
                }
                .controlSize(.small)

                Spacer()

                Button("Delete", role: .destructive) {
                    deleteRecentItem(item)
                }
                .controlSize(.small)
            }
        }
    }

    private func summaryCard(
        title: String,
        value: String,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
            Text(title)
                .font(.caption.weight(.medium))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func summaryCard(
        title: String,
        value: Int,
        detail: String
    ) -> some View {
        summaryCard(title: title, value: "\(value)", detail: detail)
    }

    private func metadataChip(_ title: String) -> some View {
        Text(title)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.52))
            .clipShape(Capsule())
    }

    private func noteMetadataTitles(for item: ReaderSnippetItem) -> [String] {
        var titles: [String] = []
        if item.isPinned {
            titles.append("Pinned")
        }
        titles.append(item.customTitle != nil ? "Named" : "Quick Capture")
        return titles
    }

    private func linkMetadataTitles(for item: QuickLinkItem) -> [String] {
        item.isPinned ? ["Pinned", "Link"] : ["Link"]
    }

    private func recentMetadataTitles(for item: ReaderHistoryItem) -> [String] {
        item.detail == "Text and answer" ? ["Text", "Answer"] : [item.detail]
    }

    private func recentPreviewText(for item: ReaderHistoryItem) -> String {
        if !item.text.isEmpty && !item.answer.isEmpty {
            return "Text: \(item.text)\n\nAnswer: \(item.answer)"
        }
        return item.text.isEmpty ? item.answer : item.text
    }
}

private struct SavedNoteEditorContext: Identifiable {
    let id: String
    let item: ReaderSnippetItem?
    let title: String
    let text: String

    static var new: SavedNoteEditorContext {
        SavedNoteEditorContext(id: "new", item: nil, title: "", text: "")
    }

    static func edit(_ item: ReaderSnippetItem) -> SavedNoteEditorContext {
        SavedNoteEditorContext(
            id: item.id.uuidString.lowercased(),
            item: item,
            title: item.customTitle ?? "",
            text: item.text
        )
    }
}

private struct SavedLinkEditorContext: Identifiable {
    let id: String
    let item: QuickLinkItem
    let title: String
    let urlString: String

    init(item: QuickLinkItem) {
        id = item.id.uuidString.lowercased()
        self.item = item
        title = item.title
        urlString = item.urlString
    }
}

private struct SavedNoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialTitle: String
    let initialText: String
    let onSave: (_ title: String, _ text: String) -> Void

    @State private var noteTitle: String
    @State private var noteText: String

    init(
        title: String,
        initialTitle: String,
        initialText: String,
        onSave: @escaping (_ title: String, _ text: String) -> Void
    ) {
        self.title = title
        self.initialTitle = initialTitle
        self.initialText = initialText
        self.onSave = onSave
        _noteTitle = State(initialValue: initialTitle)
        _noteText = State(initialValue: initialText)
    }

    private var canSave: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))

            TextField("Title (optional)", text: $noteTitle)
                .textFieldStyle(.roundedBorder)

            TextEditor(text: $noteText)
                .font(.body)
                .frame(minHeight: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                )

            HStack {
                Text("Launcher search still matches the title and body.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    onSave(noteTitle, noteText)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(18)
        .frame(width: 560)
    }
}

private struct SavedLinkEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialTitle: String
    let initialURL: String
    let onSave: (_ title: String, _ urlString: String) -> Void

    @State private var linkTitle: String
    @State private var linkURL: String

    init(
        title: String,
        initialTitle: String,
        initialURL: String,
        onSave: @escaping (_ title: String, _ urlString: String) -> Void
    ) {
        self.title = title
        self.initialTitle = initialTitle
        self.initialURL = initialURL
        self.onSave = onSave
        _linkTitle = State(initialValue: initialTitle)
        _linkURL = State(initialValue: initialURL)
    }

    private var canSave: Bool {
        !linkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))

            TextField("Title", text: $linkTitle)
                .textFieldStyle(.roundedBorder)

            TextField("URL", text: $linkURL)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text("Quick links stay searchable by title and URL in the launcher.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    onSave(linkTitle, linkURL)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .padding(18)
        .frame(width: 520)
    }
}
