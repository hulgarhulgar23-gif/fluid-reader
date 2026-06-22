import Foundation

enum LocalExtensionPackError: LocalizedError, Equatable {
    case unsupportedVersion(Int)
    case unsupportedKind(String)
    case emptyScriptContents
    case missingScriptFile

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "Extension pack version \(version) is not supported."
        case .unsupportedKind(let kind):
            return "Extension pack kind \(kind) is not supported."
        case .emptyScriptContents:
            return "Extension pack script contents are empty."
        case .missingScriptFile:
            return "Script file is missing."
        }
    }
}

enum LocalExtensionPackInstallMode: Equatable {
    case keepExisting
    case replaceExisting
}

enum LocalExtensionPackInstallResult: Equatable {
    case installed(URL)
    case alreadyInstalled(URL)
    case replaced(URL)
}

struct LocalExtensionPack: Codable, Equatable {
    static let currentVersion = 1
    static let fileSuffix = ".fluid-extension.json"

    let version: Int
    let kind: String
    let fileName: String
    let title: String
    let subtitle: String
    let keywords: [String]
    let systemImage: String
    let scriptContents: String

    init(
        version: Int,
        kind: String,
        fileName: String,
        title: String,
        subtitle: String,
        keywords: [String],
        systemImage: String,
        scriptContents: String
    ) {
        self.version = version
        self.kind = kind
        self.fileName = fileName
        self.title = title
        self.subtitle = subtitle
        self.keywords = keywords
        self.systemImage = systemImage
        self.scriptContents = scriptContents
    }

    init(template: StarterExtensionTemplate) {
        self.init(
            version: Self.currentVersion,
            kind: "script-command",
            fileName: template.fileName,
            title: template.title,
            subtitle: template.subtitle,
            keywords: template.keywords,
            systemImage: template.systemImage,
            scriptContents: template.scriptContents
        )
    }

    init(scriptCommand item: ScriptCommandItem, scriptContents: String) {
        self.init(
            version: Self.currentVersion,
            kind: "script-command",
            fileName: item.url.lastPathComponent,
            title: item.title,
            subtitle: item.subtitle,
            keywords: item.keywords,
            systemImage: item.systemImage,
            scriptContents: scriptContents
        )
    }

    var suggestedExportFileName: String {
        let baseName = (normalizedFileName as NSString).deletingPathExtension
        return "\(baseName)\(Self.fileSuffix)"
    }

    var normalizedFileName: String {
        let lastPathComponent = (fileName as NSString).lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lastPathComponent.isEmpty else { return "script-command.sh" }
        return lastPathComponent
    }

    static func decode(_ data: Data) throws -> LocalExtensionPack {
        let pack = try JSONDecoder().decode(LocalExtensionPack.self, from: data)
        return try pack.validated()
    }

    static func load(from url: URL) throws -> LocalExtensionPack {
        let data = try Data(contentsOf: url)
        return try decode(data)
    }

    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(try validated())
    }

    func install(
        into directoryURL: URL,
        fileManager: FileManager = .default,
        mode: LocalExtensionPackInstallMode = .replaceExisting
    ) throws -> LocalExtensionPackInstallResult {
        let validatedPack = try validated()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let destinationURL = directoryURL
            .appendingPathComponent(validatedPack.normalizedFileName, isDirectory: false)
            .standardizedFileURL

        let newData = Data(validatedPack.scriptContents.utf8)
        if fileManager.fileExists(atPath: destinationURL.path) {
            let existingData = try? Data(contentsOf: destinationURL)
            if existingData == newData {
                return .alreadyInstalled(destinationURL)
            }
            switch mode {
            case .keepExisting:
                return .alreadyInstalled(destinationURL)
            case .replaceExisting:
                try newData.write(to: destinationURL, options: .atomic)
                try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationURL.path)
                return .replaced(destinationURL)
            }
        }

        try newData.write(to: destinationURL, options: .atomic)
        try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destinationURL.path)
        return .installed(destinationURL)
    }

    private func validated() throws -> LocalExtensionPack {
        guard version == Self.currentVersion else {
            throw LocalExtensionPackError.unsupportedVersion(version)
        }
        guard kind == "script-command" else {
            throw LocalExtensionPackError.unsupportedKind(kind)
        }
        let cleanScriptContents = scriptContents.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanScriptContents.isEmpty else {
            throw LocalExtensionPackError.emptyScriptContents
        }
        return LocalExtensionPack(
            version: version,
            kind: kind,
            fileName: normalizedFileName,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Script Command" : title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            keywords: orderedUniqueKeywords(keywords),
            systemImage: systemImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "terminal" : systemImage.trimmingCharacters(in: .whitespacesAndNewlines),
            scriptContents: scriptContents
        )
    }

    private func orderedUniqueKeywords(_ rawKeywords: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for keyword in rawKeywords {
            let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let normalized = trimmed.lowercased()
            guard seen.insert(normalized).inserted else { continue }
            ordered.append(trimmed)
        }
        return ordered
    }
}
