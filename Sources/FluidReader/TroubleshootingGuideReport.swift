import Foundation

struct TroubleshootingGuideReport: Equatable {
    let screenRecordingAllowed: Bool
    let accessibilityTrusted: Bool
    let llmEnabled: Bool
    let apiKeySet: Bool
    let activityLogItemCount: Int

    @MainActor
    static func make(settings: SettingsStore, activityLogItemCount: Int) -> TroubleshootingGuideReport {
        TroubleshootingGuideReport(
            screenRecordingAllowed: PermissionStatus.screenRecordingAllowed(),
            accessibilityTrusted: PermissionStatus.accessibilityTrusted(),
            llmEnabled: settings.llmEnabled,
            apiKeySet: !settings.openAIAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            activityLogItemCount: activityLogItemCount
        )
    }

    func markdown() -> String {
        """
        # Fluid Reader Troubleshooting Guide

        ## Current Status
        - Screen Recording: \(yesNo(screenRecordingAllowed))
        - Accessibility: \(yesNo(accessibilityTrusted))
        - LLM: \(llmEnabled ? "On" : "Off")
        - API key set: \(yesNo(apiKeySet))
        - Activity log item count: \(activityLogItemCount)

        ## Fixes
        - Text, paste, window: allow Accessibility; try Read Clipboard Text, Paste Last Text, or Window Maximize.
        - Screen pick: allow Screen Recording; draw tight; try another OCR language.
        - LLM: turn it on, add a key, check model/provider/endpoint.
        - Stuck app: run Stop Speech, Show Reader, Clear Reader, or Clear Local Reader Data.
        - Good issue: paste Copy Issue Bundle into GitHub.

        ## Privacy
        No API keys or private content.
        """
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }
}
