import Foundation

enum ScriptCommandResolutionError: LocalizedError, Equatable {
    case missingFile
    case unsupportedInterpreter
    case emptyShebang
    case missingEnvCommand
    case missingInterpreter(String)

    var errorDescription: String? {
        switch self {
        case .missingFile:
            return "Script file is missing."
        case .unsupportedInterpreter:
            return "No supported interpreter found for this script."
        case .emptyShebang:
            return "Script shebang is empty."
        case .missingEnvCommand:
            return "Script shebang is missing a command after /usr/bin/env."
        case .missingInterpreter(let name):
            return "Interpreter \(name) was not found."
        }
    }
}

struct ScriptCommandExecution: Equatable {
    let executableURL: URL
    let arguments: [String]
    let workingDirectoryURL: URL
}

struct ScriptCommandItem: Equatable {
    let url: URL
    let title: String
    let subtitle: String
    let keywords: [String]
    let systemImage: String
    let displayPath: String

    var id: String {
        "script-command-\(Self.stableHash(url.path.lowercased()))"
    }

    var actionID: String {
        "run-\(id)"
    }

    var folderURL: URL {
        url.deletingLastPathComponent()
    }

    func executionConfiguration(
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Result<ScriptCommandExecution, ScriptCommandResolutionError> {
        ScriptCommandResolver.resolve(
            scriptURL: url,
            fileManager: fileManager,
            environment: environment
        )
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

enum ScriptCommandCatalog {
    static let defaultLimit = 120
    static let defaultMaxDepth = 4

    private static let supportedExtensions: Set<String> = [
        "sh",
        "zsh",
        "bash",
        "command",
        "py",
        "js",
        "mjs",
        "cjs",
        "rb",
        "php",
        "swift",
        "ps1"
    ]

    static func defaultDirectoryURL(fileManager: FileManager = .default) throws -> URL {
        if let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            return applicationSupportURL
                .appendingPathComponent("FluidReader", isDirectory: true)
                .appendingPathComponent("ScriptCommands", isDirectory: true)
                .standardizedFileURL
        }

        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("FluidReader", isDirectory: true)
            .appendingPathComponent("ScriptCommands", isDirectory: true)
            .standardizedFileURL
    }

    static func ensureDefaultDirectoryExists(fileManager: FileManager = .default) throws -> URL {
        let directoryURL = try defaultDirectoryURL(fileManager: fileManager)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    static func load(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        limit: Int = defaultLimit,
        maxDepth: Int = defaultMaxDepth
    ) -> [ScriptCommandItem] {
        guard limit > 0, maxDepth >= 0 else { return [] }

        let resolvedDirectoryURL: URL
        if let directoryURL {
            resolvedDirectoryURL = directoryURL.standardizedFileURL
        } else {
            guard let defaultDirectoryURL = try? defaultDirectoryURL(fileManager: fileManager) else {
                return []
            }
            resolvedDirectoryURL = defaultDirectoryURL
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: resolvedDirectoryURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              let enumerator = fileManager.enumerator(
                  at: resolvedDirectoryURL,
                  includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey, .isRegularFileKey],
                  options: [.skipsHiddenFiles, .skipsPackageDescendants],
                  errorHandler: { _, _ in true }
              ) else {
            return []
        }

        var items: [ScriptCommandItem] = []
        var seenPaths = Set<String>()

        while let nextURL = enumerator.nextObject() as? URL {
            guard items.count < limit else { break }
            if enumerator.level > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            let standardizedURL = nextURL.standardizedFileURL
            let resourceValues = try? standardizedURL.resourceValues(
                forKeys: [.isDirectoryKey, .isHiddenKey, .isRegularFileKey]
            )
            if resourceValues?.isHidden == true {
                if resourceValues?.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }
            if resourceValues?.isDirectory == true {
                continue
            }
            guard resourceValues?.isRegularFile == true else { continue }
            guard seenPaths.insert(standardizedURL.path.lowercased()).inserted else { continue }
            guard let snapshot = ScriptCommandFileSnapshot.load(from: standardizedURL) else { continue }
            guard snapshot.hasShebang || supportedExtensions.contains(standardizedURL.pathExtension.lowercased()) else {
                continue
            }
            guard let item = makeItem(
                url: standardizedURL,
                snapshot: snapshot,
                homeDirectory: homeDirectory
            ) else {
                continue
            }
            items.append(item)
        }

        return items.sorted { lhs, rhs in
            let titleOrder = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
            if titleOrder != .orderedSame {
                return titleOrder == .orderedAscending
            }
            return lhs.displayPath.localizedCaseInsensitiveCompare(rhs.displayPath) == .orderedAscending
        }
    }

    private static func makeItem(
        url: URL,
        snapshot: ScriptCommandFileSnapshot,
        homeDirectory: URL
    ) -> ScriptCommandItem? {
        let cleanTitle = metadataValue(forKey: "title", in: snapshot.metadataLines) ?? prettyTitle(
            from: url.deletingPathExtension().lastPathComponent
        )
        let cleanSubtitle = metadataValue(forKey: "subtitle", in: snapshot.metadataLines)
            ?? "Run script command"
        let cleanKeywords = metadataValues(forKey: "keywords", in: snapshot.metadataLines)
            + metadataValues(forKey: "keyword", in: snapshot.metadataLines)
        let cleanSystemImage = metadataValue(forKey: "icon", in: snapshot.metadataLines) ?? "terminal"
        let displayPath = abbreviatedPath(for: url, homeDirectory: homeDirectory)
        let baseKeywords = [
            "script",
            "automation",
            "command",
            url.lastPathComponent,
            cleanTitle,
            cleanSubtitle,
            displayPath
        ]

        let title = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        return ScriptCommandItem(
            url: url,
            title: title,
            subtitle: cleanSubtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            keywords: orderedUniqueStrings(baseKeywords + cleanKeywords),
            systemImage: cleanSystemImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "terminal"
                : cleanSystemImage.trimmingCharacters(in: .whitespacesAndNewlines),
            displayPath: displayPath
        )
    }

    private static func metadataValue(
        forKey key: String,
        in lines: [String]
    ) -> String? {
        metadataValues(forKey: key, in: lines).first
    }

    private static func metadataValues(
        forKey key: String,
        in lines: [String]
    ) -> [String] {
        let normalizedKey = key.lowercased()
        var values: [String] = []
        for line in lines {
            guard let directive = metadataDirective(from: line),
                  directive.key == normalizedKey else {
                continue
            }
            if normalizedKey == "keywords" || normalizedKey == "keyword" {
                values.append(
                    contentsOf: directive.value
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                )
            } else if !directive.value.isEmpty {
                values.append(directive.value)
            }
        }
        return orderedUniqueStrings(values)
    }

    private static func metadataDirective(
        from rawLine: String
    ) -> (key: String, value: String)? {
        var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return nil }

        let prefixes = ["#", "//", ";", "::"]
        for prefix in prefixes where line.hasPrefix(prefix) {
            line.removeFirst(prefix.count)
            break
        }
        line = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.hasPrefix("@") else { return nil }
        line.removeFirst()

        let delimiterIndex = line.firstIndex { $0 == ":" || $0.isWhitespace }
        guard let delimiterIndex else { return nil }
        let key = String(line[..<delimiterIndex])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        var valueStart = delimiterIndex
        if line[valueStart] == ":" {
            valueStart = line.index(after: valueStart)
        }
        let value = String(line[valueStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return nil }
        return (key, value)
    }

    private static func prettyTitle(from fileName: String) -> String {
        let words = fileName
            .replacingOccurrences(of: #"[_\-.]+"#, with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .map { token in
                let lowercased = token.lowercased()
                return lowercased.prefix(1).uppercased() + lowercased.dropFirst()
            }
        let title = words.joined(separator: " ")
        return title.isEmpty ? fileName : title
    }

    private static func abbreviatedPath(
        for url: URL,
        homeDirectory: URL
    ) -> String {
        let standardizedPath = url.standardizedFileURL.path
        let homePath = homeDirectory.standardizedFileURL.path
        if standardizedPath == homePath {
            return "~"
        }
        if standardizedPath.hasPrefix(homePath + "/") {
            return "~" + standardizedPath.dropFirst(homePath.count)
        }
        return standardizedPath
    }

    private static func orderedUniqueStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else { continue }
            ordered.append(trimmed)
        }
        return ordered
    }
}

struct ScriptCommandRunResult: Equatable {
    let combinedOutput: String
    let exitCode: Int32
}

enum ScriptCommandRunner {
    static func run(
        _ item: ScriptCommandItem,
        fileManager: FileManager = .default,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> ScriptCommandRunResult {
        let execution = try item.executionConfiguration(
            fileManager: fileManager,
            environment: environment
        ).get()

        let process = Process()
        process.executableURL = execution.executableURL
        process.arguments = execution.arguments
        process.currentDirectoryURL = execution.workingDirectoryURL
        process.environment = environment

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return ScriptCommandRunResult(
            combinedOutput: String(decoding: outputData, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }
}

private struct ScriptCommandFileSnapshot {
    let firstLine: String
    let metadataLines: [String]

    var hasShebang: Bool {
        firstLine.hasPrefix("#!")
    }

    static func load(from url: URL, maximumBytes: Int = 4_096) -> ScriptCommandFileSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let preview = String(decoding: data.prefix(maximumBytes), as: UTF8.self)
        let lines = preview.components(separatedBy: .newlines)
        return ScriptCommandFileSnapshot(
            firstLine: lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            metadataLines: Array(lines.prefix(24))
        )
    }
}

private enum ScriptCommandResolver {
    private struct InterpreterFallback {
        let primaryName: String
        let alternateNames: [String]
    }

    static func resolve(
        scriptURL: URL,
        fileManager: FileManager,
        environment: [String: String]
    ) -> Result<ScriptCommandExecution, ScriptCommandResolutionError> {
        let standardizedURL = scriptURL.standardizedFileURL
        guard fileManager.fileExists(atPath: standardizedURL.path) else {
            return .failure(.missingFile)
        }

        if let snapshot = ScriptCommandFileSnapshot.load(from: standardizedURL),
           snapshot.hasShebang {
            return resolveShebang(
                line: snapshot.firstLine,
                scriptURL: standardizedURL,
                fileManager: fileManager,
                environment: environment
            )
        }

        let pathExtension = standardizedURL.pathExtension.lowercased()
        if let interpreterFallback = interpreterFallback(for: pathExtension),
           let executableURL = executableURL(
               named: interpreterFallback.primaryName,
               alternateNames: interpreterFallback.alternateNames,
               fileManager: fileManager,
               environment: environment
           ) {
            return .success(
                ScriptCommandExecution(
                    executableURL: executableURL,
                    arguments: [standardizedURL.path],
                    workingDirectoryURL: standardizedURL.deletingLastPathComponent()
                )
            )
        }

        return .failure(.unsupportedInterpreter)
    }

    private static func resolveShebang(
        line: String,
        scriptURL: URL,
        fileManager: FileManager,
        environment: [String: String]
    ) -> Result<ScriptCommandExecution, ScriptCommandResolutionError> {
        let rawCommand = line.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = rawCommand
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        guard let firstToken = tokens.first else {
            return .failure(.emptyShebang)
        }

        let interpreterPath = URL(fileURLWithPath: firstToken).standardizedFileURL
        let interpreterName = interpreterPath.lastPathComponent.lowercased()
        let workingDirectoryURL = scriptURL.deletingLastPathComponent()

        if interpreterName == "env" {
            let commandStartIndex = tokens.dropFirst().first == "-S" ? 2 : 1
            guard tokens.count > commandStartIndex else {
                return .failure(.missingEnvCommand)
            }
            let commandName = tokens[commandStartIndex]
            let commandArguments = Array(tokens.dropFirst(commandStartIndex + 1))
            guard let executableURL = executableURL(
                named: commandName,
                alternateNames: [],
                fileManager: fileManager,
                environment: environment
            ) else {
                return .failure(.missingInterpreter(commandName))
            }
            return .success(
                ScriptCommandExecution(
                    executableURL: executableURL,
                    arguments: commandArguments + [scriptURL.path],
                    workingDirectoryURL: workingDirectoryURL
                )
            )
        }

        guard fileManager.isExecutableFile(atPath: interpreterPath.path) else {
            return .failure(.missingInterpreter(interpreterPath.path))
        }

        return .success(
            ScriptCommandExecution(
                executableURL: interpreterPath,
                arguments: Array(tokens.dropFirst()) + [scriptURL.path],
                workingDirectoryURL: workingDirectoryURL
            )
        )
    }

    private static func interpreterFallback(for pathExtension: String) -> InterpreterFallback? {
        switch pathExtension {
        case "sh", "zsh", "command":
            return InterpreterFallback(primaryName: "zsh", alternateNames: ["/bin/zsh", "bash", "/bin/bash", "sh", "/bin/sh"])
        case "bash":
            return InterpreterFallback(primaryName: "bash", alternateNames: ["/bin/bash", "zsh", "/bin/zsh"])
        case "py":
            return InterpreterFallback(primaryName: "python3", alternateNames: ["python", "/usr/bin/python3"])
        case "js", "mjs", "cjs":
            return InterpreterFallback(primaryName: "node", alternateNames: [])
        case "rb":
            return InterpreterFallback(primaryName: "ruby", alternateNames: ["/usr/bin/ruby"])
        case "php":
            return InterpreterFallback(primaryName: "php", alternateNames: [])
        case "swift":
            return InterpreterFallback(primaryName: "swift", alternateNames: ["/usr/bin/swift"])
        case "ps1":
            return InterpreterFallback(primaryName: "pwsh", alternateNames: ["powershell"])
        default:
            return nil
        }
    }

    private static func executableURL(
        named name: String,
        alternateNames: [String],
        fileManager: FileManager,
        environment: [String: String]
    ) -> URL? {
        for candidate in [name] + alternateNames {
            if candidate.contains("/") {
                let candidateURL = URL(fileURLWithPath: candidate).standardizedFileURL
                if fileManager.isExecutableFile(atPath: candidateURL.path) {
                    return candidateURL
                }
                continue
            }

            for directory in (environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin")
                .split(separator: ":")
                .map(String.init) {
                let candidateURL = URL(fileURLWithPath: directory, isDirectory: true)
                    .appendingPathComponent(candidate)
                    .standardizedFileURL
                if fileManager.isExecutableFile(atPath: candidateURL.path) {
                    return candidateURL
                }
            }
        }
        return nil
    }
}
