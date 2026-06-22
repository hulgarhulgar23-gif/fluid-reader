import Foundation

enum AgentDebugLog {
    private static let enabledKey = "FLUID_READER_AGENT_DEBUG_LOG"
    private static let pathOverrideKey = "FLUID_READER_AGENT_DEBUG_LOG_PATH"
    private static let enabledValues: Set<String> = ["1", "true", "yes", "on"]

    static func makeSessionID() -> String {
        UUID().uuidString.lowercased()
    }

    static func isEnabled(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard let rawValue = environment[enabledKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty else {
            return false
        }

        return enabledValues.contains(rawValue.lowercased())
    }

    static func logURL(
        sessionID: String,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> URL? {
        guard isEnabled(environment: environment) else {
            return nil
        }

        if let rawPath = environment[pathOverrideKey]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawPath.isEmpty {
            let expandedPath = (rawPath as NSString).expandingTildeInPath
            return URL(fileURLWithPath: expandedPath).standardizedFileURL
        }

        let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        return baseDirectory
            .appendingPathComponent("FluidReader", isDirectory: true)
            .appendingPathComponent("Debug", isDirectory: true)
            .appendingPathComponent("agent-debug-\(sessionID).log")
            .standardizedFileURL
    }
}
