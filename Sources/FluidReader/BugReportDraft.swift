import Foundation

struct BugReportDraft: Equatable {
    let supportInfo: SupportInfoReport

    func markdown() -> String {
        """
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

        ## Extra notes

        Add anything else that helps.

        No API keys or private content.
        """
    }
}
