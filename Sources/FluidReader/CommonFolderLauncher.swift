import Foundation

struct CommonFolderItem: Equatable {
    let id: String
    let title: String
    let url: URL
    let keywords: [String]

    var commandTitle: String {
        "Open Folder: \(title)"
    }

    var subtitle: String {
        "Open \(title) in Finder"
    }
}

enum CommonFolderCatalog {
    static func defaultItems(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [CommonFolderItem] {
        [
            CommonFolderItem(
                id: "downloads",
                title: "Downloads",
                url: homeDirectory.appendingPathComponent("Downloads", isDirectory: true),
                keywords: ["downloads", "download", "files"]
            ),
            CommonFolderItem(
                id: "documents",
                title: "Documents",
                url: homeDirectory.appendingPathComponent("Documents", isDirectory: true),
                keywords: ["documents", "docs", "files"]
            ),
            CommonFolderItem(
                id: "desktop",
                title: "Desktop",
                url: homeDirectory.appendingPathComponent("Desktop", isDirectory: true),
                keywords: ["desktop", "files"]
            ),
            CommonFolderItem(
                id: "home",
                title: "Home",
                url: homeDirectory,
                keywords: ["home", "user", "files"]
            ),
            CommonFolderItem(
                id: "applications",
                title: "Applications",
                url: URL(fileURLWithPath: "/Applications", isDirectory: true),
                keywords: ["applications", "apps"]
            ),
            CommonFolderItem(
                id: "utilities",
                title: "Utilities",
                url: URL(fileURLWithPath: "/System/Applications/Utilities", isDirectory: true),
                keywords: ["utilities", "utility", "apps"]
            )
        ]
    }

    static func load(
        items: [CommonFolderItem] = defaultItems(),
        fileManager: FileManager = .default
    ) -> [CommonFolderItem] {
        items.filter { item in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: item.url.path, isDirectory: &isDirectory)
                && isDirectory.boolValue
        }
    }
}
