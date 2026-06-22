import Foundation

struct LocalFileSearchItem: Equatable {
    let url: URL
    let displayPath: String

    var id: String {
        let slug = url.path
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return "indexed-file-\(String(slug.prefix(48)))-\(Self.stableHash(url.path))"
    }

    var name: String {
        let lastPathComponent = url.lastPathComponent.trimmingCharacters(in: .whitespacesAndNewlines)
        return lastPathComponent.isEmpty ? url.path : lastPathComponent
    }

    var nameStem: String {
        url.deletingPathExtension().lastPathComponent
    }

    var parentDisplayPath: String {
        let parentPath = url.deletingLastPathComponent().path
        guard parentPath != "/" else { return displayPath }
        guard let slashIndex = displayPath.lastIndex(of: "/"), slashIndex > displayPath.startIndex else {
            return displayPath
        }
        return String(displayPath[..<slashIndex])
    }

    static func make(
        url: URL,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> LocalFileSearchItem? {
        let standardizedURL = url.standardizedFileURL
        let lastPathComponent = standardizedURL.lastPathComponent.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !lastPathComponent.isEmpty else { return nil }
        return LocalFileSearchItem(
            url: standardizedURL,
            displayPath: abbreviatedPath(for: standardizedURL, homeDirectory: homeDirectory)
        )
    }

    private static func abbreviatedPath(
        for url: URL,
        homeDirectory: URL
    ) -> String {
        let standardizedPath = url.standardizedFileURL.path
        let homePath = homeDirectory.standardizedFileURL.path
        guard !homePath.isEmpty else { return standardizedPath }
        if standardizedPath == homePath {
            return "~"
        }
        if standardizedPath.hasPrefix(homePath + "/") {
            return "~" + standardizedPath.dropFirst(homePath.count)
        }
        return standardizedPath
    }

    private static func stableHash(_ text: String) -> String {
        var hash: UInt64 = 1_469_598_103_934_665_603
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}

enum LocalFileSearchCatalog {
    static let defaultLimit = 2_400
    static let defaultPerRootLimit = 800
    static let defaultMaxDepth = 6

    private static let ignoredDirectoryNames: Set<String> = [
        ".build",
        ".git",
        ".hg",
        ".swiftpm",
        ".svn",
        "build",
        "deriveddata",
        "node_modules",
        "pods"
    ]

    static func defaultRoots(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [URL] {
        [
            homeDirectory.appendingPathComponent("Desktop", isDirectory: true),
            homeDirectory.appendingPathComponent("Documents", isDirectory: true),
            homeDirectory.appendingPathComponent("Downloads", isDirectory: true)
        ]
    }

    static func defaultRootPaths(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String] {
        defaultRoots(homeDirectory: homeDirectory).map(\.path)
    }

    static func normalizedRootPaths(
        _ rawPaths: [String],
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String] {
        var seenPaths = Set<String>()
        var normalizedPaths: [String] = []

        for rawPath in rawPaths {
            let trimmedPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPath.isEmpty else { continue }

            let expandedPath: String
            if trimmedPath == "~" {
                expandedPath = homeDirectory.path
            } else if trimmedPath.hasPrefix("~/") {
                expandedPath = homeDirectory
                    .appendingPathComponent(String(trimmedPath.dropFirst(2)), isDirectory: true)
                    .path
            } else {
                expandedPath = trimmedPath
            }
            let candidateURL: URL
            if expandedPath.hasPrefix("/") {
                candidateURL = URL(fileURLWithPath: expandedPath, isDirectory: true)
            } else {
                candidateURL = homeDirectory.appendingPathComponent(expandedPath, isDirectory: true)
            }
            let standardizedPath = candidateURL.standardizedFileURL.path

            guard seenPaths.insert(standardizedPath.lowercased()).inserted else { continue }
            normalizedPaths.append(standardizedPath)
        }

        return normalizedPaths
    }

    static func rootURLs(
        fromPaths paths: [String],
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [URL] {
        normalizedRootPaths(paths, homeDirectory: homeDirectory).map {
            URL(fileURLWithPath: $0, isDirectory: true).standardizedFileURL
        }
    }

    static func displayRootPath(
        _ path: String,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> String {
        LocalFileSearchItem.make(
            url: URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL,
            homeDirectory: homeDirectory
        )?.displayPath ?? path
    }

    static func load(
        roots: [URL] = defaultRoots(),
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default,
        limit: Int = defaultLimit,
        perRootLimit: Int = defaultPerRootLimit,
        maxDepth: Int = defaultMaxDepth
    ) -> [LocalFileSearchItem] {
        guard limit > 0, perRootLimit > 0, maxDepth >= 0 else { return [] }

        var seenPaths = Set<String>()
        var items: [LocalFileSearchItem] = []

        for root in roots.map(\.standardizedFileURL) {
            guard items.count < limit else { break }

            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  let enumerator = fileManager.enumerator(
                      at: root,
                      includingPropertiesForKeys: [
                          .isDirectoryKey,
                          .isHiddenKey,
                          .isPackageKey,
                          .isRegularFileKey
                      ],
                      options: [.skipsHiddenFiles, .skipsPackageDescendants],
                      errorHandler: { _, _ in true }
                  ) else {
                continue
            }

            var itemsInRoot = 0
            while let nextURL = enumerator.nextObject() as? URL {
                guard items.count < limit, itemsInRoot < perRootLimit else { break }

                if enumerator.level > maxDepth {
                    enumerator.skipDescendants()
                    continue
                }

                let standardizedURL = nextURL.standardizedFileURL
                let resourceValues = try? standardizedURL.resourceValues(
                    forKeys: [.isDirectoryKey, .isHiddenKey, .isPackageKey, .isRegularFileKey]
                )

                if resourceValues?.isHidden == true {
                    if resourceValues?.isDirectory == true {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                if resourceValues?.isDirectory == true {
                    let lowercasedName = standardizedURL.lastPathComponent.lowercased()
                    if resourceValues?.isPackage == true || ignoredDirectoryNames.contains(lowercasedName) {
                        enumerator.skipDescendants()
                    }
                    continue
                }

                guard resourceValues?.isRegularFile == true else { continue }
                guard seenPaths.insert(standardizedURL.path.lowercased()).inserted else { continue }
                guard let item = LocalFileSearchItem.make(
                    url: standardizedURL,
                    homeDirectory: homeDirectory
                ) else {
                    continue
                }

                items.append(item)
                itemsInRoot += 1
            }
        }

        return items.sorted { lhs, rhs in
            let nameOrder = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameOrder != .orderedSame {
                return nameOrder == .orderedAscending
            }
            return lhs.displayPath.localizedCaseInsensitiveCompare(rhs.displayPath) == .orderedAscending
        }
    }
}
