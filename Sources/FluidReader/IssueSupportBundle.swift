import Foundation

struct IssueSupportBundle: Equatable {
    static let activityLogItemLimit = 20

    let supportInfo: SupportInfoReport
    let activityLogItems: [ActivityLogItem]

    func markdown() -> String {
        let limitedActivityLogItems = Array(activityLogItems.prefix(Self.activityLogItemLimit))
        let omittedActivityLogItemCount = max(0, activityLogItems.count - limitedActivityLogItems.count)
        let activitySection = ActivityLogReport.markdown(items: limitedActivityLogItems)
            ?? "No activity log events yet."
        let activityLimitNote = omittedActivityLogItemCount > 0
            ? "\n\n_\(omittedActivityLogItemCount) older safe events not included._"
            : ""

        return """
        # Fluid Reader Issue

        ## What happened?

        Tell us what went wrong.

        ## What did you expect?

        Tell us what should have happened.

        ## Steps

        1.
        2.
        3.

        ## Problem type

        Type: text, screen/OCR, paste, window, LLM, app, other.

        ## Launch Rescue Snapshot

        \(supportInfo.launchRescueSnapshotMarkdown())

        ## Support info

        \(supportInfo.markdown())

        ## Activity log

        \(activitySection)\(activityLimitNote)

        ## Extra notes

        Add anything else that helps.

        No API keys or private content.
        """
    }
}
