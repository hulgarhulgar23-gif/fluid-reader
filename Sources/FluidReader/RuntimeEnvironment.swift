import Foundation

enum RuntimeEnvironment {
    private static var environment: [String: String] {
        ProcessInfo.processInfo.environment
    }

    static var isRunningTests: Bool {
        let processName = ProcessInfo.processInfo.processName
        return environment["XCTestConfigurationFilePath"] != nil
            || processName.contains("xctest")
            || processName.hasSuffix("PackageTests")
    }

    static var suppressesExternalEffects: Bool {
        isRunningTests
            || environment["FLUID_READER_SUPPRESS_EXTERNAL_EFFECTS"] == "1"
    }
}
