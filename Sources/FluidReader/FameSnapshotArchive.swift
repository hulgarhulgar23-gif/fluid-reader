import Foundation

struct FameSnapshotArchive {
    struct SavedFiles: Equatable {
        let directoryURL: URL
        let sprintURL: URL
        let packURL: URL
        let ledgerURL: URL
    }

    struct AutoPulseFiles: Equatable {
        let checkpointURL: URL
        let pulseNudgeURL: URL
        let scorecardURL: URL
        let dashboardURL: URL
    }

    struct OpsBundleFiles: Equatable {
        let commandCenterURL: URL
        let checkpointURL: URL
        let riskTimelineURL: URL
        let pulseNudgeURL: URL
    }

    enum ArchiveError: Error {
        case documentsDirectoryUnavailable
    }

    static func save(
        sprintMarkdown: String,
        packMarkdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> SavedFiles {
        let directoryURL = try directoryURL(baseDirectory: baseDirectory)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let stamp = timestamp(now: now, calendar: calendar)
        let sprintURL = directoryURL.appendingPathComponent("fame-sprint-\(stamp).md")
        let packURL = directoryURL.appendingPathComponent("fame-pack-\(stamp).md")
        let ledgerURL = directoryURL.appendingPathComponent("fame-snapshot-ledger.md")

        try sprintMarkdown.write(to: sprintURL, atomically: true, encoding: .utf8)
        try packMarkdown.write(to: packURL, atomically: true, encoding: .utf8)
        try updateLedger(
            at: ledgerURL,
            stamp: stamp,
            sprintMarkdown: sprintMarkdown,
            sprintFileName: sprintURL.lastPathComponent,
            packFileName: packURL.lastPathComponent
        )

        return SavedFiles(
            directoryURL: directoryURL,
            sprintURL: sprintURL,
            packURL: packURL,
            ledgerURL: ledgerURL
        )
    }

    static func defaultDirectoryURL() throws -> URL {
        try directoryURL(baseDirectory: nil)
    }

    static func saveCommandCenter(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-command-center",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveNextMoveHandoff(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-next-move-handoff",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveNextMoveDraftPack(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-next-move-draft-pack",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveWarRoom(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-war-room",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveDailyCheckpoint(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-daily-checkpoint",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveDailyScorecard(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-daily-scorecard",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveOnboardingScorecard(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-onboarding-scorecard",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveOnboardingDailyBrief(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-onboarding-daily-brief",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func savePulseNudge(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-pulse-nudge",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveOnboardingNudge(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-onboarding-nudge",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveRecoverySprint(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-recovery-sprint",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveRecoveryChecklist(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-recovery-checklist",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveRecoveryProofPack(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-recovery-proof-pack",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveRiskTimeline(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-risk-timeline",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveOperatorDashboard(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-operator-dashboard",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveMorningBrief(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-morning-brief",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveMiddayBrief(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-midday-brief",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveEveningBrief(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-evening-brief",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveEscalationNudge(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-escalation-nudge",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveBreakthroughForecast(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-breakthrough-forecast",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveDailyMission(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-daily-mission",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveNarrativeLab(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-narrative-lab",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveSpotlightPack(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-spotlight-pack",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveLaunchDayScript(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-launch-day-script",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveLaunchCountdown(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-launch-countdown",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveLaunchRescueBurst(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-launch-rescue-burst",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveLaunchControlBrief(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-launch-control-brief",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveLaunchRescueSnapshot(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-launch-rescue-snapshot",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveCadenceMomentumBrief(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-cadence-momentum-brief",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveCadenceShareLine(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-cadence-share-line",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveCadenceSharePack(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-cadence-share-pack",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func saveExceptionalLoopRecap(
        markdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> URL {
        try saveArtifact(
            markdown: markdown,
            fileNamePrefix: "fame-exceptional-loop-recap",
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
    }

    static func latestRecoverySprintURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-recovery-sprint",
            baseDirectory: baseDirectory
        )
    }

    static func latestRecoveryChecklistURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-recovery-checklist",
            baseDirectory: baseDirectory
        )
    }

    static func latestRecoveryProofPackURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-recovery-proof-pack",
            baseDirectory: baseDirectory
        )
    }

    static func latestCommandCenterURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-command-center",
            baseDirectory: baseDirectory
        )
    }

    static func latestNextMoveHandoffURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-next-move-handoff",
            baseDirectory: baseDirectory
        )
    }

    static func latestNextMoveDraftPackURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-next-move-draft-pack",
            baseDirectory: baseDirectory
        )
    }

    static func latestDailyCheckpointURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-daily-checkpoint",
            baseDirectory: baseDirectory
        )
    }

    static func latestRiskTimelineURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-risk-timeline",
            baseDirectory: baseDirectory
        )
    }

    static func latestPulseNudgeURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-pulse-nudge",
            baseDirectory: baseDirectory
        )
    }

    static func latestOnboardingNudgeURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-onboarding-nudge",
            baseDirectory: baseDirectory
        )
    }

    static func latestDailyScorecardURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-daily-scorecard",
            baseDirectory: baseDirectory
        )
    }

    static func latestOnboardingScorecardURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-onboarding-scorecard",
            baseDirectory: baseDirectory
        )
    }

    static func latestOnboardingDailyBriefURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-onboarding-daily-brief",
            baseDirectory: baseDirectory
        )
    }

    static func latestOperatorDashboardURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-operator-dashboard",
            baseDirectory: baseDirectory
        )
    }

    static func latestMorningBriefURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-morning-brief",
            baseDirectory: baseDirectory
        )
    }

    static func latestMiddayBriefURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-midday-brief",
            baseDirectory: baseDirectory
        )
    }

    static func latestEveningBriefURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-evening-brief",
            baseDirectory: baseDirectory
        )
    }

    static func latestEscalationNudgeURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-escalation-nudge",
            baseDirectory: baseDirectory
        )
    }

    static func latestBreakthroughForecastURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-breakthrough-forecast",
            baseDirectory: baseDirectory
        )
    }

    static func latestDailyMissionURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-daily-mission",
            baseDirectory: baseDirectory
        )
    }

    static func latestNarrativeLabURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-narrative-lab",
            baseDirectory: baseDirectory
        )
    }

    static func latestSpotlightPackURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-spotlight-pack",
            baseDirectory: baseDirectory
        )
    }

    static func latestLaunchDayScriptURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-launch-day-script",
            baseDirectory: baseDirectory
        )
    }

    static func latestLaunchCountdownURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-launch-countdown",
            baseDirectory: baseDirectory
        )
    }

    static func latestLaunchRescueBurstURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-launch-rescue-burst",
            baseDirectory: baseDirectory
        )
    }

    static func latestLaunchControlBriefURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-launch-control-brief",
            baseDirectory: baseDirectory
        )
    }

    static func latestLaunchRescueSnapshotURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-launch-rescue-snapshot",
            baseDirectory: baseDirectory
        )
    }

    static func latestCadenceMomentumBriefURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-cadence-momentum-brief",
            baseDirectory: baseDirectory
        )
    }

    static func latestCadenceShareLineURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-cadence-share-line",
            baseDirectory: baseDirectory
        )
    }

    static func latestCadenceSharePackURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-cadence-share-pack",
            baseDirectory: baseDirectory
        )
    }

    static func latestExceptionalLoopRecapURL(baseDirectory: URL? = nil) throws -> URL? {
        try latestArtifactURL(
            fileNamePrefix: "fame-exceptional-loop-recap",
            baseDirectory: baseDirectory
        )
    }

    static func saveAutoPulseFiles(
        checkpointMarkdown: String,
        pulseNudgeMarkdown: String,
        scorecardMarkdown: String,
        dashboardMarkdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> AutoPulseFiles {
        let checkpointURL = try saveDailyCheckpoint(
            markdown: checkpointMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        let pulseNudgeURL = try savePulseNudge(
            markdown: pulseNudgeMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        let scorecardURL = try saveDailyScorecard(
            markdown: scorecardMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        let dashboardURL = try saveOperatorDashboard(
            markdown: dashboardMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        return AutoPulseFiles(
            checkpointURL: checkpointURL,
            pulseNudgeURL: pulseNudgeURL,
            scorecardURL: scorecardURL,
            dashboardURL: dashboardURL
        )
    }

    static func saveOpsBundleFiles(
        commandCenterMarkdown: String,
        checkpointMarkdown: String,
        riskTimelineMarkdown: String,
        pulseNudgeMarkdown: String,
        now: Date = Date(),
        calendar: Calendar = .current,
        baseDirectory: URL? = nil
    ) throws -> OpsBundleFiles {
        let commandCenterURL = try saveCommandCenter(
            markdown: commandCenterMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        let checkpointURL = try saveDailyCheckpoint(
            markdown: checkpointMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        let riskTimelineURL = try saveRiskTimeline(
            markdown: riskTimelineMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        let pulseNudgeURL = try savePulseNudge(
            markdown: pulseNudgeMarkdown,
            now: now,
            calendar: calendar,
            baseDirectory: baseDirectory
        )
        return OpsBundleFiles(
            commandCenterURL: commandCenterURL,
            checkpointURL: checkpointURL,
            riskTimelineURL: riskTimelineURL,
            pulseNudgeURL: pulseNudgeURL
        )
    }

    static func timestamp(now: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: now)
    }

    private static func directoryURL(baseDirectory: URL?) throws -> URL {
        if let baseDirectory {
            return baseDirectory
        }

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ArchiveError.documentsDirectoryUnavailable
        }

        return documentsURL
            .appendingPathComponent("FluidReader")
            .appendingPathComponent("FameSnapshots")
    }

    private static func updateLedger(
        at ledgerURL: URL,
        stamp: String,
        sprintMarkdown: String,
        sprintFileName: String,
        packFileName: String
    ) throws {
        let stage = extractField(prefix: "Stage:", from: sprintMarkdown) ?? "-"
        let score = extractField(prefix: "Score target:", from: sprintMarkdown) ?? "-"
        let dayLabel = extractDayLabel(from: sprintMarkdown) ?? "-"
        let row = "| \(stamp) | \(sanitize(stage)) | \(sanitize(score)) | \(sanitize(dayLabel)) | \(sprintFileName) | \(packFileName) |"

        let header = """
        # Fluid Reader Fame Snapshot Ledger

        No API keys or private content.

        | Timestamp | Stage | Score | Day | Sprint File | Pack File |
        | --- | --- | --- | --- | --- | --- |
        """

        if FileManager.default.fileExists(atPath: ledgerURL.path) {
            // Propagate read failures instead of coalescing to "", which would
            // silently rewrite the ledger and destroy all snapshot history.
            let existing = try String(contentsOf: ledgerURL, encoding: .utf8)
            let trimmed = existing.trimmingCharacters(in: .whitespacesAndNewlines)
            let next = trimmed.isEmpty ? "\(header)\n\(row)\n" : "\(trimmed)\n\(row)\n"
            try next.write(to: ledgerURL, atomically: true, encoding: .utf8)
            return
        }

        try "\(header)\n\(row)\n".write(to: ledgerURL, atomically: true, encoding: .utf8)
    }

    private static func extractField(prefix: String, from text: String) -> String? {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { $0.hasPrefix(prefix) })?
            .dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractDayLabel(from text: String) -> String? {
        guard let dateLine = extractField(prefix: "Date:", from: text),
              let openParen = dateLine.lastIndex(of: "("),
              let closeParen = dateLine.lastIndex(of: ")"),
              openParen < closeParen else {
            return nil
        }
        let day = dateLine[dateLine.index(after: openParen)..<closeParen]
        return String(day)
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "|", with: "/")
    }

    private static func saveArtifact(
        markdown: String,
        fileNamePrefix: String,
        now: Date,
        calendar: Calendar,
        baseDirectory: URL?
    ) throws -> URL {
        let directoryURL = try directoryURL(baseDirectory: baseDirectory)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let stamp = timestamp(now: now, calendar: calendar)
        let artifactURL = directoryURL.appendingPathComponent("\(fileNamePrefix)-\(stamp).md")
        try markdown.write(to: artifactURL, atomically: true, encoding: .utf8)
        return artifactURL
    }

    private static func latestArtifactURL(
        fileNamePrefix: String,
        baseDirectory: URL?
    ) throws -> URL? {
        let directoryURL = try directoryURL(baseDirectory: baseDirectory)
        guard FileManager.default.fileExists(atPath: directoryURL.path) else { return nil }

        let files = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        let prefix = "\(fileNamePrefix)-"
        let candidates = files
            .filter { $0.pathExtension == "md" && $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return candidates.last
    }
}
