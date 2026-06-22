import AppKit
import SwiftUI

struct ExtensionsWorkspaceItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case aiCommand(PromptTemplate)
        case scriptCommand(ScriptCommandItem)
        case starterExtension(StarterExtensionTemplate)
    }

    let kind: Kind

    var id: String {
        switch kind {
        case .aiCommand(let template):
            return "ai-\(template.id)"
        case .scriptCommand(let item):
            return "script-\(item.id)"
        case .starterExtension(let template):
            return "starter-\(template.id)"
        }
    }

    var title: String {
        switch kind {
        case .aiCommand(let template):
            return template.title
        case .scriptCommand(let item):
            return item.title
        case .starterExtension(let template):
            return template.title
        }
    }

    var subtitle: String {
        switch kind {
        case .aiCommand:
            return "AI command"
        case .scriptCommand(let item):
            return item.subtitle.isEmpty ? item.displayPath : item.subtitle
        case .starterExtension(let template):
            return template.subtitle
        }
    }

    var systemImage: String {
        switch kind {
        case .aiCommand(let template):
            return template.systemImage
        case .scriptCommand(let item):
            return item.systemImage
        case .starterExtension(let template):
            return template.systemImage
        }
    }

    var keywords: [String] {
        switch kind {
        case .aiCommand(let template):
            return template.keywords + ["ai", "command", "extension", "prompt", template.title]
        case .scriptCommand(let item):
            return item.keywords + ["script", "extension", "automation", "command", item.title]
        case .starterExtension(let template):
            return template.keywords + ["starter", "library", "install", "extension", template.title]
        }
    }

    var sectionTitle: String {
        switch kind {
        case .aiCommand:
            return "AI Commands"
        case .scriptCommand:
            return "Script Commands"
        case .starterExtension:
            return "Starter Extensions"
        }
    }
}

enum ExtensionsWorkspaceFilter: String, CaseIterable, Identifiable {
    case all
    case ai
    case scripts
    case starter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .ai:
            return "AI"
        case .scripts:
            return "Scripts"
        case .starter:
            return "Starter"
        }
    }
}

struct ExtensionsWorkspaceSummary: Equatable {
    let aiCommandCount: Int
    let scriptCommandCount: Int
    let starterExtensionCount: Int
    let installedStarterCount: Int
    let totalCount: Int
    let llmReady: Bool

    var actionSubtitle: String {
        guard totalCount > 0 else {
            return "Open the local extension hub for AI commands, starter installs, and scripts"
        }
        let scriptNoun = scriptCommandCount == 1 ? "script" : "scripts"
        let starterNoun = starterExtensionCount == 1 ? "starter" : "starters"
        return "\(aiCommandCount) AI · \(scriptCommandCount) \(scriptNoun) · \(starterExtensionCount) \(starterNoun) in one local hub"
    }

    var llmStatusTitle: String {
        llmReady ? "Ready" : "Needs LLM"
    }
}

enum ExtensionsWorkspaceCatalog {
    static func items(
        promptTemplates: [PromptTemplate],
        scriptCommands: [ScriptCommandItem],
        starterExtensions: [StarterExtensionTemplate] = []
    ) -> [ExtensionsWorkspaceItem] {
        let aiItems = promptTemplates.map { ExtensionsWorkspaceItem(kind: .aiCommand($0)) }
        let scriptItems = scriptCommands.map { ExtensionsWorkspaceItem(kind: .scriptCommand($0)) }
        let starterItems = starterExtensions.map { ExtensionsWorkspaceItem(kind: .starterExtension($0)) }
        return aiItems
            + scriptItems.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            + starterItems.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    static func filteredItems(
        _ items: [ExtensionsWorkspaceItem],
        query: String,
        filter: ExtensionsWorkspaceFilter = .all
    ) -> [ExtensionsWorkspaceItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredItems = items.filter { item in
            filter.matches(item)
        }
        guard !cleanQuery.isEmpty else { return filteredItems }
        return filteredItems.filter { item in
            let haystack = ([item.title, item.subtitle, item.sectionTitle] + item.keywords)
                .joined(separator: "\n")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            return haystack.contains(
                cleanQuery.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            )
        }
    }

    static func count(
        _ items: [ExtensionsWorkspaceItem],
        filter: ExtensionsWorkspaceFilter
    ) -> Int {
        filteredItems(items, query: "", filter: filter).count
    }

    static func summary(
        promptTemplates: [PromptTemplate],
        scriptCommands: [ScriptCommandItem],
        starterExtensions: [StarterExtensionTemplate],
        llmEnabled: Bool,
        apiKey: String
    ) -> ExtensionsWorkspaceSummary {
        let aiCommandCount = promptTemplates.count
        let scriptCommandCount = scriptCommands.count
        let starterExtensionCount = starterExtensions.count
        let installedStarterCount = starterExtensions.filter {
            installedScript(for: $0, in: scriptCommands) != nil
        }.count
        let llmReady = llmEnabled && !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return ExtensionsWorkspaceSummary(
            aiCommandCount: aiCommandCount,
            scriptCommandCount: scriptCommandCount,
            starterExtensionCount: starterExtensionCount,
            installedStarterCount: installedStarterCount,
            totalCount: aiCommandCount + scriptCommandCount + starterExtensionCount,
            llmReady: llmReady
        )
    }

    static func installedScript(
        for template: StarterExtensionTemplate,
        in scriptCommands: [ScriptCommandItem]
    ) -> ScriptCommandItem? {
        StarterExtensionCatalog.installedScript(for: template, in: scriptCommands)
    }
}

private extension ExtensionsWorkspaceFilter {
    func matches(_ item: ExtensionsWorkspaceItem) -> Bool {
        switch self {
        case .all:
            return true
        case .ai:
            if case .aiCommand = item.kind { return true }
            return false
        case .scripts:
            if case .scriptCommand = item.kind { return true }
            return false
        case .starter:
            if case .starterExtension = item.kind { return true }
            return false
        }
    }
}

@MainActor
final class ExtensionsWorkspaceWindowController {
    private static let preferredContentSize = NSSize(width: 700, height: 620)
    private static let minContentSize = NSSize(width: 560, height: 440)
    private static let maxContentSize = NSSize(width: 860, height: 760)

    private let window: NSWindow

    init(
        settings: SettingsStore,
        promptTemplates: @escaping () -> [PromptTemplate],
        scriptCommands: @escaping () -> [ScriptCommandItem],
        starterExtensions: @escaping () -> [StarterExtensionTemplate],
        runPromptTemplate: @escaping (PromptTemplate) -> Void,
        runScriptCommand: @escaping (ScriptCommandItem) -> Void,
        installStarterExtension: @escaping (StarterExtensionTemplate) -> Void,
        revealStarterExtension: @escaping (StarterExtensionTemplate) -> Void,
        importExtensionPack: @escaping () -> Void,
        exportScriptCommand: @escaping (ScriptCommandItem) -> Void,
        openScriptCommandsFolder: @escaping () -> Void,
        refreshScriptCommands: @escaping () -> Void,
        revealScript: @escaping (URL) -> Void,
        openSettings: @escaping () -> Void
    ) {
        let view = ExtensionsWorkspaceView(
            settings: settings,
            promptTemplates: promptTemplates,
            scriptCommands: scriptCommands,
            starterExtensions: starterExtensions,
            runPromptTemplate: runPromptTemplate,
            runScriptCommand: runScriptCommand,
            installStarterExtension: installStarterExtension,
            revealStarterExtension: revealStarterExtension,
            importExtensionPack: importExtensionPack,
            exportScriptCommand: exportScriptCommand,
            openScriptCommandsFolder: openScriptCommandsFolder,
            refreshScriptCommands: refreshScriptCommands,
            revealScript: revealScript,
            openSettings: openSettings
        )

        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.preferredContentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Extensions Workspace"
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

private struct ExtensionsWorkspaceView: View {
    @ObservedObject var settings: SettingsStore
    let promptTemplates: () -> [PromptTemplate]
    let scriptCommands: () -> [ScriptCommandItem]
    let starterExtensions: () -> [StarterExtensionTemplate]
    let runPromptTemplate: (PromptTemplate) -> Void
    let runScriptCommand: (ScriptCommandItem) -> Void
    let installStarterExtension: (StarterExtensionTemplate) -> Void
    let revealStarterExtension: (StarterExtensionTemplate) -> Void
    let importExtensionPack: () -> Void
    let exportScriptCommand: (ScriptCommandItem) -> Void
    let openScriptCommandsFolder: () -> Void
    let refreshScriptCommands: () -> Void
    let revealScript: (URL) -> Void
    let openSettings: () -> Void

    @State private var searchQuery = ""
    @State private var selectedFilter = ExtensionsWorkspaceFilter.all
    @State private var refreshCounter = 0

    private var promptTemplateItems: [PromptTemplate] {
        _ = refreshCounter
        return promptTemplates()
    }

    private var scriptCommandItems: [ScriptCommandItem] {
        _ = refreshCounter
        return scriptCommands()
    }

    private var starterExtensionItems: [StarterExtensionTemplate] {
        _ = refreshCounter
        return starterExtensions()
    }

    private var allItems: [ExtensionsWorkspaceItem] {
        ExtensionsWorkspaceCatalog.items(
            promptTemplates: promptTemplateItems,
            scriptCommands: scriptCommandItems,
            starterExtensions: starterExtensionItems
        )
    }

    private var workspaceSummary: ExtensionsWorkspaceSummary {
        ExtensionsWorkspaceCatalog.summary(
            promptTemplates: promptTemplateItems,
            scriptCommands: scriptCommandItems,
            starterExtensions: starterExtensionItems,
            llmEnabled: settings.llmEnabled,
            apiKey: settings.openAIAPIKey
        )
    }

    private var filteredItems: [ExtensionsWorkspaceItem] {
        ExtensionsWorkspaceCatalog.filteredItems(
            allItems,
            query: searchQuery,
            filter: selectedFilter
        )
    }

    private var filteredAIItems: [ExtensionsWorkspaceItem] {
        filteredItems.filter {
            if case .aiCommand = $0.kind { return true }
            return false
        }
    }

    private var filteredScriptItems: [ExtensionsWorkspaceItem] {
        filteredItems.filter {
            if case .scriptCommand = $0.kind { return true }
            return false
        }
    }

    private var filteredStarterItems: [ExtensionsWorkspaceItem] {
        filteredItems.filter {
            if case .starterExtension = $0.kind { return true }
            return false
        }
    }

    private var selectedFilterItemCount: Int {
        ExtensionsWorkspaceCatalog.count(allItems, filter: selectedFilter)
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
            return "Try a shorter search, or search by command title, extension kind, or automation keywords."
        }
        if workspaceSummary.totalCount == 0 {
            return "Turn on LLM for AI Commands, install a starter extension, or drop scripts into the Script Commands folder to grow this workspace."
        }
        switch selectedFilter {
        case .all:
            return "No extensions are available right now."
        case .ai:
            return workspaceSummary.llmReady
                ? "No AI commands are available right now."
                : "AI commands are listed here. Turn on LLM and add an API key in Settings to run them."
        case .scripts:
            return "No script commands are installed yet. Open the Script Commands folder or install a starter extension."
        case .starter:
            return "No starter extensions are available right now."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Extensions Workspace", systemImage: "puzzlepiece.extension")
                        .font(.title3.weight(.semibold))
                    Text("Local command packs for AI Commands and Script Commands, plus a starter library you can install into the same extension surface without cluttering idle Commands.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    Button("Open Script Folder") {
                        openScriptCommandsFolder()
                    }
                    Button("Import Pack") {
                        importExtensionPack()
                    }
                    Button("Refresh Scripts") {
                        refreshScriptCommands()
                        refreshCounter += 1
                    }
                    Button("Settings") {
                        openSettings()
                    }
                }
            }

            extensionsSummaryGrid

            HStack(spacing: 10) {
                TextField("Search extensions", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)

                Text(itemListStatusTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            }

            extensionsFilterBar

            Text("AI commands, local scripts, starter installs, and extension packs all stay in one local-first workspace, and the same items still appear in the launcher.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if filteredItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No extensions yet." : "No extensions matched.")
                        .font(.headline)
                    Text(emptyStateText)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !filteredAIItems.isEmpty {
                            section("AI Commands", items: filteredAIItems)
                        }
                        if !filteredScriptItems.isEmpty {
                            section("Script Commands", items: filteredScriptItems)
                        }
                        if !filteredStarterItems.isEmpty {
                            section("Starter Extensions", items: filteredStarterItems)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                }
            }
        }
        .padding(18)
        .frame(minWidth: 620, minHeight: 520)
    }

    @ViewBuilder
    private func section(_ title: String, items: [ExtensionsWorkspaceItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(items) { item in
                itemRow(item)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: ExtensionsWorkspaceItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.systemImage)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.callout.weight(.semibold))
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
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                if let helperText = aiDisabledMessage(for: item) ?? starterInstallStatusText(for: item) {
                    Text(helperText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            switch item.kind {
            case .aiCommand(let template):
                Button("Run") {
                    runPromptTemplate(template)
                }
                .disabled(!workspaceSummary.llmReady)
            case .scriptCommand(let script):
                Button("Reveal") {
                    revealScript(script.url)
                }
                Button("Export") {
                    exportScriptCommand(script)
                }
                Button("Run") {
                    runScriptCommand(script)
                }
            case .starterExtension(let template):
                if ExtensionsWorkspaceCatalog.installedScript(for: template, in: scriptCommandItems) != nil {
                    Button("Reveal") {
                        revealStarterExtension(template)
                    }
                } else {
                    Button("Install") {
                        installStarterExtension(template)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.48))
        )
    }

    private var extensionsSummaryGrid: some View {
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
                summaryCard(
                    title: "AI Commands",
                    value: summary.aiCommandCount,
                    detail: summary.llmStatusTitle
                )
                summaryCard(
                    title: "Script Commands",
                    value: summary.scriptCommandCount,
                    detail: "Local automation"
                )
                summaryCard(
                    title: "Starter Library",
                    value: summary.starterExtensionCount,
                    detail: "Installable helpers"
                )
                summaryCard(
                    title: "Installed Starters",
                    value: summary.installedStarterCount,
                    detail: "Already in scripts"
                )
            }

            Text(
                summary.llmReady
                    ? "AI and script commands share the same local extension surface, and launcher search still reaches them from one bar."
                    : "AI commands are cataloged here even when LLM is off. Turn on LLM and add an API key in Settings to run them."
            )
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

    private var extensionsFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExtensionsWorkspaceFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.title)
                            Text("\(ExtensionsWorkspaceCatalog.count(allItems, filter: filter))")
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

    private func metadataTitles(for item: ExtensionsWorkspaceItem) -> [String] {
        switch item.kind {
        case .aiCommand:
            return workspaceSummary.llmReady ? ["AI", "Ready"] : ["AI", "LLM Off"]
        case .scriptCommand:
            return ["Script", "Installed"]
        case .starterExtension(let template):
            if ExtensionsWorkspaceCatalog.installedScript(for: template, in: scriptCommandItems) != nil {
                return ["Starter", "Installed"]
            }
            return ["Starter"]
        }
    }

    private func aiDisabledMessage(for item: ExtensionsWorkspaceItem) -> String? {
        guard case .aiCommand = item.kind,
              !workspaceSummary.llmReady else {
            return nil
        }
        return "Turn on LLM and add an API key in Settings to run AI commands."
    }

    private func starterInstallStatusText(for item: ExtensionsWorkspaceItem) -> String? {
        guard case .starterExtension(let template) = item.kind,
              ExtensionsWorkspaceCatalog.installedScript(for: template, in: scriptCommandItems) != nil else {
            return nil
        }
        return "Already installed in your local Script Commands folder."
    }
}
