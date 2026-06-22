import Foundation

enum CommandPaletteRootSearch {
    private static let appResultLimit = 14
    private static let fileResultLimit = 12
    private static let folderResultLimit = 8
    private static let snippetResultLimit = 8
    private static let quickLinkResultLimit = 8
    private static let clipboardHistoryResultLimit = 8
    private static let recentResultLimit = 8
    private static let searchablePreviewLimit = 220

    static func makeActions(
        query: String,
        apps: [AppLaunchItem],
        folders: [CommonFolderItem],
        snippets: [ReaderSnippetItem],
        quickLinks: [QuickLinkItem],
        clipboardHistory: [ClipboardHistoryItem],
        recentItems: [ReaderHistoryItem],
        openApp: @escaping (AppLaunchItem) -> Void,
        openFolder: @escaping (CommonFolderItem) -> Void,
        useSnippet: @escaping (ReaderSnippetItem) -> Void,
        openNotesWorkspace: @escaping () -> Void = {},
        setSnippetPinned: @escaping (ReaderSnippetItem, Bool) -> Void = { _, _ in },
        openQuickLink: @escaping (QuickLinkItem) -> Void,
        copyClipboardHistory: @escaping (ClipboardHistoryItem) -> Void,
        restoreRecentItem: @escaping (ReaderHistoryItem) -> Void,
        files: [LocalFileSearchItem] = [],
        openFile: @escaping (LocalFileSearchItem) -> Void = { _ in },
        revealURL: @escaping (URL) -> Void = { _ in },
        copyText: @escaping (String) -> Void = { _ in }
    ) -> [CommandPaletteAction] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return [] }

        let appActions = filtered(
            apps.map { item in
                CommandPaletteAction(
                    id: "app-launch-\(item.id)",
                    title: "Open App: \(item.name)",
                    subtitle: "Launch installed app",
                    systemImage: "app.badge",
                    group: .open,
                    sourceKind: .app,
                    keywords: [
                        "app",
                        "apps",
                        "launch",
                        "open",
                        "launcher",
                        "spotlight",
                        item.name,
                        item.url.lastPathComponent
                    ],
                    canFavorite: false,
                    secondaryActions: [
                        CommandPaletteAction.SecondaryAction(
                            id: "reveal-app-\(item.id)",
                            title: "Reveal App in Finder",
                            subtitle: item.url.path,
                            systemImage: "folder.badge.questionmark"
                        ) {
                            revealURL(item.url)
                        },
                        CommandPaletteAction.SecondaryAction(
                            id: "copy-app-path-\(item.id)",
                            title: "Copy App Path",
                            subtitle: item.url.path,
                            systemImage: "doc.on.doc"
                        ) {
                            copyText(item.url.path)
                        }
                    ]
                ) {
                    openApp(item)
                }
            },
            query: cleanQuery,
            limit: appResultLimit
        )

        let fileActions = filtered(
            files.map { item in
                CommandPaletteAction(
                    id: item.id,
                    title: "Open File: \(item.name)",
                    subtitle: item.parentDisplayPath,
                    systemImage: "doc",
                    group: .open,
                    sourceKind: .file,
                    keywords: [
                        "file",
                        "open",
                        "finder",
                        item.name,
                        item.nameStem,
                        item.displayPath
                    ],
                    canFavorite: false,
                    secondaryActions: [
                        CommandPaletteAction.SecondaryAction(
                            id: "reveal-file-\(item.id)",
                            title: "Reveal File in Finder",
                            subtitle: item.displayPath,
                            systemImage: "folder.badge.questionmark"
                        ) {
                            revealURL(item.url)
                        },
                        CommandPaletteAction.SecondaryAction(
                            id: "copy-file-path-\(item.id)",
                            title: "Copy File Path",
                            subtitle: item.displayPath,
                            systemImage: "doc.on.doc"
                        ) {
                            copyText(item.url.path)
                        }
                    ]
                ) {
                    openFile(item)
                }
            },
            query: cleanQuery,
            limit: fileResultLimit
        )

        let folderActions = filtered(
            folders.map { item in
                CommandPaletteAction(
                    id: "folder-\(item.id)",
                    title: item.commandTitle,
                    subtitle: item.subtitle,
                    systemImage: "folder",
                    group: .open,
                    sourceKind: .folder,
                    keywords: ["folder", "open", "finder"] + item.keywords,
                    canFavorite: false,
                    secondaryActions: [
                        CommandPaletteAction.SecondaryAction(
                            id: "reveal-folder-\(item.id)",
                            title: "Reveal Folder in Finder",
                            subtitle: item.url.path,
                            systemImage: "folder.badge.questionmark"
                        ) {
                            revealURL(item.url)
                        },
                        CommandPaletteAction.SecondaryAction(
                            id: "copy-folder-path-\(item.id)",
                            title: "Copy Folder Path",
                            subtitle: item.url.path,
                            systemImage: "doc.on.doc"
                        ) {
                            copyText(item.url.path)
                        }
                    ]
                ) {
                    openFolder(item)
                }
            },
            query: cleanQuery,
            limit: folderResultLimit
        )

        let snippetActions = filtered(
            snippets.map { item in
                CommandPaletteAction(
                    id: "use-snippet-\(item.id.uuidString.lowercased())",
                    title: "Use Snippet: \(item.preview)",
                    subtitle: item.isPinned ? "Pinned snippet" : "Saved snippet",
                    systemImage: item.isPinned ? "pin.fill" : "note.text",
                    group: .saved,
                    sourceKind: .snippet,
                    keywords: [
                        "snippet",
                        "note",
                        "notes",
                        "workspace",
                        "saved",
                        item.title,
                        searchablePreview(item.text)
                    ],
                    canFavorite: false,
                    secondaryActions: [
                        CommandPaletteAction.SecondaryAction(
                            id: "copy-snippet-\(item.id.uuidString.lowercased())",
                            title: "Copy Snippet Text",
                            subtitle: item.preview,
                            systemImage: "doc.on.doc"
                        ) {
                            copyText(item.text)
                        },
                        CommandPaletteAction.SecondaryAction(
                            id: "\(item.isPinned ? "unpin" : "pin")-snippet-\(item.id.uuidString.lowercased())",
                            title: item.isPinned ? "Unpin Note" : "Pin Note",
                            subtitle: item.preview,
                            systemImage: item.isPinned ? "pin.slash" : "pin"
                        ) {
                            setSnippetPinned(item, !item.isPinned)
                        },
                        CommandPaletteAction.SecondaryAction(
                            id: "open-notes-workspace-\(item.id.uuidString.lowercased())",
                            title: "Open Notes Workspace",
                            subtitle: "Browse all saved notes",
                            systemImage: "note.text"
                        ) {
                            openNotesWorkspace()
                        }
                    ]
                ) {
                    useSnippet(item)
                }
            },
            query: cleanQuery,
            limit: snippetResultLimit
        )

        let quickLinkActions = filtered(
            quickLinks.map { item in
                let subtitle = item.isPinned
                    ? "Pinned quick link · \(item.displayURL)"
                    : item.displayURL
                return CommandPaletteAction(
                    id: "quick-link-\(item.id.uuidString.lowercased())",
                    title: "Open Link: \(item.preview)",
                    subtitle: subtitle,
                    systemImage: item.isPinned ? "pin.circle.fill" : "link",
                    group: .saved,
                    sourceKind: .link,
                    keywords: [
                        "link",
                        "quick link",
                        "bookmark",
                        "saved",
                        item.title,
                        item.urlString
                    ],
                    canFavorite: false,
                    secondaryActions: [
                        CommandPaletteAction.SecondaryAction(
                            id: "copy-link-\(item.id.uuidString.lowercased())",
                            title: "Copy Link URL",
                            subtitle: item.displayURL,
                            systemImage: "doc.on.doc"
                        ) {
                            copyText(item.urlString)
                        }
                    ]
                ) {
                    openQuickLink(item)
                }
            },
            query: cleanQuery,
            limit: quickLinkResultLimit
        )

        let clipboardHistoryActions = filtered(
            clipboardHistory.map { item in
                CommandPaletteAction(
                    id: "clipboard-history-\(item.id.uuidString.lowercased())",
                    title: "Copy Clipboard: \(item.preview)",
                    subtitle: "Copy back to clipboard",
                    systemImage: "doc.on.clipboard",
                    group: .saved,
                    sourceKind: .clipboard,
                    keywords: [
                        "clipboard",
                        "history",
                        "pasteboard",
                        searchablePreview(item.text)
                    ],
                    canFavorite: false
                ) {
                    copyClipboardHistory(item)
                }
            },
            query: cleanQuery,
            limit: clipboardHistoryResultLimit
        )

        let recentActions = filtered(
            recentItems.map { item in
                CommandPaletteAction(
                    id: "recent-item-\(item.id.uuidString.lowercased())",
                    title: "Restore Recent: \(item.preview)",
                    subtitle: item.detail,
                    systemImage: "clock.arrow.circlepath",
                    group: .saved,
                    sourceKind: .recent,
                    keywords: [
                        "recent",
                        "history",
                        item.detail,
                        searchablePreview(item.text),
                        searchablePreview(item.answer)
                    ],
                    canFavorite: false,
                    secondaryActions: [
                        CommandPaletteAction.SecondaryAction(
                            id: "copy-recent-\(item.id.uuidString.lowercased())",
                            title: item.answer.isEmpty ? "Copy Recent Text" : "Copy Recent Item",
                            subtitle: item.preview,
                            systemImage: "doc.on.doc"
                        ) {
                            copyText(item.text.isEmpty ? item.answer : item.text)
                        }
                    ]
                ) {
                    restoreRecentItem(item)
                }
            },
            query: cleanQuery,
            limit: recentResultLimit
        )

        return appActions + fileActions + folderActions + quickLinkActions + snippetActions + clipboardHistoryActions + recentActions
    }

    private static func filtered(
        _ actions: [CommandPaletteAction],
        query: String,
        limit: Int
    ) -> [CommandPaletteAction] {
        Array(CommandPaletteAction.filter(actions, query: query).prefix(max(0, limit)))
    }

    private static func searchablePreview(_ text: String) -> String {
        ReaderHistoryItem.preview(for: text, limit: searchablePreviewLimit)
    }
}
