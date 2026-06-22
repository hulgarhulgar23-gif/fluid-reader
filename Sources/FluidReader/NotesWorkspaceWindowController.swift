import AppKit
import SwiftUI

@MainActor
final class NotesWorkspaceWindowController {
    private static let preferredContentSize = NSSize(width: 760, height: 620)
    private static let minContentSize = NSSize(width: 560, height: 420)
    private static let maxContentSize = NSSize(width: 980, height: 840)

    private let window: NSWindow

    init(
        state: ReaderState,
        copyNote: @escaping (ReaderSnippetItem) -> Void,
        openNote: @escaping (ReaderSnippetItem) -> Void,
        createNote: @escaping (_ title: String, _ text: String) -> Void,
        updateNote: @escaping (_ item: ReaderSnippetItem, _ title: String, _ text: String) -> Void,
        togglePinned: @escaping (ReaderSnippetItem) -> Void,
        deleteNote: @escaping (ReaderSnippetItem) -> Void,
        clearNotes: @escaping () -> Void
    ) {
        let view = NotesWorkspaceView(
            state: state,
            copyNote: copyNote,
            openNote: openNote,
            createNote: createNote,
            updateNote: updateNote,
            togglePinned: togglePinned,
            deleteNote: deleteNote,
            clearNotes: clearNotes
        )
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notes Workspace"
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

private struct NotesWorkspaceView: View {
    @ObservedObject var state: ReaderState
    let copyNote: (ReaderSnippetItem) -> Void
    let openNote: (ReaderSnippetItem) -> Void
    let createNote: (_ title: String, _ text: String) -> Void
    let updateNote: (_ item: ReaderSnippetItem, _ title: String, _ text: String) -> Void
    let togglePinned: (ReaderSnippetItem) -> Void
    let deleteNote: (ReaderSnippetItem) -> Void
    let clearNotes: () -> Void

    @State private var searchQuery = ""
    @State private var selectedFilter = NotesWorkspaceFilter.all
    @State private var editorContext: NoteEditorContext?

    private var workspaceSummary: NotesWorkspaceSummary {
        NotesWorkspaceCatalog.summary(state.snippets)
    }

    private var filteredNotes: [ReaderSnippetItem] {
        NotesWorkspaceCatalog.filteredNotes(
            state.snippets,
            query: searchQuery,
            filter: selectedFilter
        )
    }

    private var selectedFilterNoteCount: Int {
        NotesWorkspaceCatalog.count(state.snippets, filter: selectedFilter)
    }

    private var noteListStatusTitle: String {
        let cleanQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanQuery.isEmpty {
            let noun = selectedFilterNoteCount == 1 ? "note" : "notes"
            return "\(selectedFilterNoteCount) \(noun)"
        }
        let shownCount = filteredNotes.count
        let noun = shownCount == 1 ? "match" : "matches"
        return "\(shownCount) \(noun)"
    }

    private var emptyStateText: String {
        let cleanQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanQuery.isEmpty else {
            return "Try a shorter search, or search by note title, contents, pinned state, or quick captures."
        }
        if workspaceSummary.totalCount == 0 {
            return "Create a note here, or keep using snippet-save actions from the launcher and reader. Everything lands in the same workspace."
        }
        switch selectedFilter {
        case .all:
            return "No notes are available right now."
        case .pinned:
            return "No pinned notes yet. Pin favorites to keep them at the top of this workspace and the launcher."
        case .titled:
            return "No named notes yet. Edit a quick capture to give it a reusable title."
        case .quickCapture:
            return "No quick captures right now. Save text quickly from the launcher or reader to land it here."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Notes Workspace", systemImage: "note.text")
                        .font(.title3.weight(.semibold))
                    Text("Local-first notes powered by your saved snippets. They stay searchable from the launcher and editable in one place.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button("New Note") {
                        editorContext = .new
                    }
                    .keyboardShortcut("n", modifiers: [.command])

                    Button("Clear All") {
                        clearNotes()
                    }
                    .disabled(state.snippets.isEmpty)
                }
            }

            notesSummaryGrid

            HStack(spacing: 10) {
                TextField("Search notes", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Text(noteListStatusTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            }

            notesFilterBar

            Text("Saved snippets, quick captures, and named notes all live in the same local workspace, and launcher search still reaches them from one bar.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if filteredNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No notes yet." : "No notes matched.")
                        .font(.headline)
                    Text(emptyStateText)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredNotes) { item in
                            noteRow(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(18)
        .sheet(item: $editorContext) { context in
            NoteEditorSheet(
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
    }

    private func noteRow(_ item: ReaderSnippetItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                if !metadataTitles(for: item).isEmpty {
                    HStack(spacing: 6) {
                        ForEach(metadataTitles(for: item), id: \.self) { title in
                            Text(title)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(nsColor: .textBackgroundColor).opacity(0.52))
                                .clipShape(Capsule())
                        }
                    }
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
                    editorContext = .edit(item)
                }
                .controlSize(.small)

                Button(item.isPinned ? "Unpin" : "Pin") {
                    togglePinned(item)
                }
                .controlSize(.small)

                Spacer()

                Button("Delete", role: .destructive) {
                    deleteNote(item)
                }
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var notesSummaryGrid: some View {
        let summary = workspaceSummary
        return VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(minimum: 120), spacing: 8),
                    GridItem(.flexible(minimum: 120), spacing: 8)
                ],
                alignment: .leading,
                spacing: 8
            ) {
                summaryCard(title: "Notes", value: summary.totalCount, detail: "Saved locally")
                summaryCard(title: "Pinned", value: summary.pinnedCount, detail: "Top of launcher")
                summaryCard(title: "Named", value: summary.titledCount, detail: "Custom titles")
                summaryCard(title: "Quick Captures", value: summary.quickCaptureCount, detail: "Fast saves")
            }

            Text("Pinned notes stay on top, named notes make search cleaner, and quick captures let you save first and organize later without leaving the launcher flow.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func summaryCard(
        title: String,
        value: Int,
        detail: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
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

    private var notesFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NotesWorkspaceFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.title)
                            Text("\(NotesWorkspaceCatalog.count(state.snippets, filter: filter))")
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

    private func metadataTitles(for item: ReaderSnippetItem) -> [String] {
        var titles: [String] = []
        if item.isPinned {
            titles.append("Pinned")
        }
        if item.customTitle != nil {
            titles.append("Named")
        } else {
            titles.append("Quick Capture")
        }
        return titles
    }
}

private struct NoteEditorContext: Identifiable {
    let id: UUID
    let item: ReaderSnippetItem?
    let title: String
    let text: String

    static let new = NoteEditorContext(id: UUID(), item: nil, title: "", text: "")

    static func edit(_ item: ReaderSnippetItem) -> NoteEditorContext {
        NoteEditorContext(
            id: item.id,
            item: item,
            title: item.customTitle ?? "",
            text: item.text
        )
    }
}

private struct NoteEditorSheet: View {
    let title: String
    let initialTitle: String
    let initialText: String
    let onSave: (_ title: String, _ text: String) -> Void

    @Environment(\.dismiss) private var dismiss
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
                Text("Launcher search matches the title and body.")
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
