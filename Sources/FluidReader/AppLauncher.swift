import Foundation

struct AppLaunchItem: Equatable {
    let name: String
    let url: URL

    var id: String {
        name
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    static func make(url: URL) -> AppLaunchItem? {
        guard url.pathExtension.lowercased() == "app" else { return nil }
        let name = url.deletingPathExtension().lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        return AppLaunchItem(name: name, url: url)
    }
}

struct AppLaunchCatalog {
    static let defaultLimit = 120

    static func appFolders(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [URL] {
        [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
            homeDirectory.appendingPathComponent("Applications", isDirectory: true)
        ]
    }

    static func load(
        folders: [URL] = appFolders(),
        fileManager: FileManager = .default,
        limit: Int = defaultLimit
    ) -> [AppLaunchItem] {
        var seenNames = Set<String>()
        var items: [AppLaunchItem] = []

        for folder in folders {
            let urls = (try? fileManager.contentsOfDirectory(
                at: folder,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )) ?? []

            for url in urls {
                guard let item = AppLaunchItem.make(url: url) else { continue }
                let key = item.name.lowercased()
                guard seenNames.insert(key).inserted else { continue }
                items.append(item)
            }
        }

        return Array(items.sorted { left, right in
            left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }.prefix(limit))
    }
}
