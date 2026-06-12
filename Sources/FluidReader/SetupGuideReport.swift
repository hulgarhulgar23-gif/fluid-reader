import Foundation

struct SetupGuideReport: Equatable {
    let screenRecordingAllowed: Bool
    let accessibilityTrusted: Bool
    let llmEnabled: Bool
    let autoCopyNewText: Bool
    let autoPastePickedText: Bool
    let autoPasteLLMAnswers: Bool
    let saveRecentItems: Bool
    let saveClipboardHistory: Bool
    let launchAtLoginState: LaunchAtLoginState
    let savedItemCount: Int
    let activityLogItemCount: Int

    @MainActor
    static func make(
        settings: SettingsStore,
        savedItemCount: Int,
        activityLogItemCount: Int
    ) -> SetupGuideReport {
        SetupGuideReport(
            screenRecordingAllowed: PermissionStatus.screenRecordingAllowed(),
            accessibilityTrusted: PermissionStatus.accessibilityTrusted(),
            llmEnabled: settings.llmEnabled,
            autoCopyNewText: settings.autoCopyNewText,
            autoPastePickedText: settings.autoPastePickedText,
            autoPasteLLMAnswers: settings.autoPasteLLMAnswers,
            saveRecentItems: settings.saveRecentItems,
            saveClipboardHistory: settings.saveClipboardHistory,
            launchAtLoginState: LaunchAtLoginManager.state,
            savedItemCount: max(0, savedItemCount),
            activityLogItemCount: max(0, activityLogItemCount)
        )
    }

    func markdown() -> String {
        """
        # Fluid Reader Setup Guide

        ## Shortcuts
        - ⌥⇧Space: Commands
        - ⌥⇧R: Read/pick
        - ⌥⇧S: Screenshot
        - ⌥⌘O: Auto Bundle status
        - ⌥⌘L: Launch Rescue Auto status
        - \(AppDelegate.readerStatusShortcutMenuHintLine())

        ## First Use
        1. Open Commands.
        2. Run Read Selected Text.
        3. Draw area if needed.

        ## Status
        - Screen Recording: \(yesNo(screenRecordingAllowed))
        - Accessibility: \(yesNo(accessibilityTrusted))
        - LLM: \(llmEnabled ? "on" : "off")
        - Auto-copy: \(autoCopyNewText ? "on" : "off")
        - Auto-paste pick: \(autoPastePickedText ? "on" : "off")
        - Auto-paste answer: \(autoPasteLLMAnswers ? "on" : "off")
        - Recent items: \(saveRecentItems ? "on" : "off")
        - Clipboard history: \(saveClipboardHistory ? "on" : "off")
        - Launch at login: \(launchAtLoginState.title) - \(launchAtLoginState.detail)
        - No API keys or private content.

        ## Useful Commands
        Try: Read Selected Text, Ask Anything, Search Web.

        ## Share
        Paste this:
        \(Self.winRecap(
            savedItemCount: savedItemCount,
            activityLogItemCount: activityLogItemCount
        ))

        Need growth copy? Launch Kit.
        """
    }

    static func winRecap(savedItemCount: Int, activityLogItemCount: Int) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let style = (safeSavedItemCount + safeActivityLogItemCount) % 3
        return winRecap(
            savedItemCount: safeSavedItemCount,
            activityLogItemCount: safeActivityLogItemCount,
            style: style
        )
    }

    @inline(never)
    static func winRecapPack(savedItemCount: Int, activityLogItemCount: Int) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let sections = (0..<3).map { index in
            "## Variant \(index + 1)\n\n\(winRecap(savedItemCount: safeSavedItemCount, activityLogItemCount: safeActivityLogItemCount, style: index))"
        }

        return (["# Fluid Reader Win Recap Pack"] + sections).joined(separator: "\n\n")
    }

    @inline(never)
    static func launchKit(savedItemCount: Int, activityLogItemCount: Int) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let proof = "Saved: \(safeSavedItemCount), events: \(safeActivityLogItemCount)."
        let momentum = max(1, safeSavedItemCount + safeActivityLogItemCount)
        let demoTarget = max(3, (momentum + 2) / 3)
        let replyTarget = max(10, momentum * 2)
        let dmTarget = max(5, momentum)

        return """
        # Fluid Reader Launch Kit

        ## Positioning
        Local-first macOS OCR + ask.
        Shortcut: ⌥⇧Space.
        \(proof)

        ## Hooks
        - One shortcut: read, ask, save.
        - Share proof daily.

        ## X Post
        Fluid Reader: local-first read/OCR/ask.
        \(proof)
        Reply "launch".
        #macOS #productivity #opensource

        ## LinkedIn Post
        Built for macOS OCR + ask. \(proof)

        ## PH / IH Blurb
        Local-first text app. Optional LLM.
        Momentum: \(momentum).

        ## 7-Day Sprint
        D1-7: X, LinkedIn, Reddit, IH.

        ## KPI Targets
        - Clips: \(demoTarget)
        - Replies: \(replyTarget)
        - DMs: \(dmTarget)

        ## 30s Demo
        Commands -> Screenshot -> Ask.

        ## CTA
        Reply "demo"/"tester".
        """
    }

    @inline(never)
    static func experimentBoard(savedItemCount: Int, activityLogItemCount: Int) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let momentum = max(1, safeSavedItemCount + safeActivityLogItemCount)
        let clipTarget = max(3, (momentum + 2) / 3)
        let replyTarget = max(8, momentum + 4)
        let demoTarget = max(5, momentum)
        let fameScore = max(1, (safeSavedItemCount * 2) + safeActivityLogItemCount + clipTarget)
        let fameStage = fameScore >= 40 ? "Authority" : (fameScore >= 20 ? "Momentum" : "Spark")

        let topTitle: String
        let topWhy: String
        let topShip: String
        let topSuccess: String
        if safeActivityLogItemCount < safeSavedItemCount {
            topTitle = "Activation Fix"
            topWhy = "Saved > events."
            topShip = "Run before/after onboarding."
            topSuccess = "Raise weekly events to \(safeSavedItemCount)."
        } else {
            topTitle = "Distribution Remix"
            topWhy = "Events lead."
            topShip = "Remix demo for X/LinkedIn."
            topSuccess = "Ship \(clipTarget) remixes + \(replyTarget) replies."
        }

        return """
        # Fluid Reader Fame Board

        ## Snapshot
        Saved \(safeSavedItemCount), events \(safeActivityLogItemCount), momentum \(momentum), fame \(fameScore) (\(fameStage)).

        ## Top 5 Experiments
        1) \(topTitle)
        - Why: \(topWhy)
        - Ship: \(topShip)
        - Success: \(topSuccess)

        2) 30s Command Race
        - Goal: \(clipTarget) clips.

        3) Win Recap Ladder
        - Goal: \(demoTarget) proof.

        4) Reply Engine
        - Goal: \(replyTarget) replies + \(clipTarget) demos.

        5) Builder Thread - Goal: \(clipTarget) requests.

        Ship daily; share via Copy Fame Board.
        """
    }

    @inline(never)
    static func fameSprint(savedItemCount: Int, activityLogItemCount: Int) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let momentum = max(1, safeSavedItemCount + safeActivityLogItemCount)
        let clipTarget = max(3, (momentum + 2) / 3)
        let replyTarget = max(8, momentum + 4)
        let demoTarget = max(5, momentum)
        let fameScore = max(1, (safeSavedItemCount * 2) + safeActivityLogItemCount + clipTarget)
        let fameStage = fameScore >= 40 ? "Authority" : (fameScore >= 20 ? "Momentum" : "Spark")
        let dailyReplyTarget = max(3, replyTarget / 3)
        let board = experimentBoard(
            savedItemCount: safeSavedItemCount,
            activityLogItemCount: safeActivityLogItemCount
        )

        return """
        # Fluid Reader Fame Sprint

        ## Sprint Goal
        Push to \(fameScore) fame points (\(fameStage)).
        Ship \(clipTarget) clips, \(replyTarget) replies, \(demoTarget) proof moments this week.

        ## 7-Day Cadence
        - Day 1: Run Pick and Read, post one demo clip, and share Copy Win Recap.
        - Day 2: Publish one hook remix and reply to \(dailyReplyTarget) builders.
        - Day 3: Ship one "before/after" proof thread and DM 3 potential testers.
        - Day 4: Post one 30s command race and push 1 community comment.
        - Day 5: Share one user quote, one win card image, and ask for 3 intros.
        - Day 6: Run Copy Launch Kit, publish one long-form recap, and collect feedback.
        - Day 7: Share Copy Fame Board, pick top experiment, and reset next sprint.

        ## Board Snapshot
        \(board)
        """
    }

    @inline(never)
    static func fameSprintToday(
        savedItemCount: Int,
        activityLogItemCount: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let momentum = max(1, safeSavedItemCount + safeActivityLogItemCount)
        let clipTarget = max(3, (momentum + 2) / 3)
        let replyTarget = max(8, momentum + 4)
        let demoTarget = max(5, momentum)
        let fameScore = max(1, (safeSavedItemCount * 2) + safeActivityLogItemCount + clipTarget)
        let fameStage = fameScore >= 40 ? "Authority" : (fameScore >= 20 ? "Momentum" : "Spark")

        let weekday = calendar.component(.weekday, from: now)
        let dayIndex = ((weekday + 5) % 7) + 1
        let cadence = fameSprintCadenceLines(dailyReplyTarget: max(3, replyTarget / 3))
        let todayMission = cadence[dayIndex - 1]
        let nextMission = cadence[dayIndex % cadence.count]

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        let dateText = formatter.string(from: now)

        return """
        # Fluid Reader Fame Sprint Today

        Date: \(dateText) (Day \(dayIndex))
        Stage: \(fameStage)
        Score target: \(fameScore)

        ## Today Mission
        \(todayMission)

        ## Next Mission
        \(nextMission)

        ## Checklist
        - [ ] Copy Fame Pack
        - [ ] Copy Founder Presets
        - [ ] Ship toward \(clipTarget) clips and \(replyTarget) replies this week
        - [ ] Capture \(demoTarget) proof moments
        - [ ] Save Fame Pack at wrap
        """
    }

    @inline(never)
    static func famePack(
        savedItemCount: Int,
        activityLogItemCount: Int,
        cadenceExecutionKitCurrentStreak: Int = 0,
        cadenceExecutionKitBestStreak: Int = 0,
        primaryChannel: String = "X / Threads",
        backupChannel: String = "LinkedIn"
    ) -> String {
        let safeSavedItemCount = max(0, savedItemCount)
        let safeActivityLogItemCount = max(0, activityLogItemCount)
        let momentum = max(1, safeSavedItemCount + safeActivityLogItemCount)
        let cadenceSummary = cadenceExecutionKitStreakSummary(
            currentStreak: cadenceExecutionKitCurrentStreak,
            bestStreak: cadenceExecutionKitBestStreak
        )
        let recapPack = winRecapPack(
            savedItemCount: safeSavedItemCount,
            activityLogItemCount: safeActivityLogItemCount
        )
        let launchKitPack = launchKit(
            savedItemCount: safeSavedItemCount,
            activityLogItemCount: safeActivityLogItemCount
        )
        let sprintPack = fameSprint(
            savedItemCount: safeSavedItemCount,
            activityLogItemCount: safeActivityLogItemCount
        )
        let commandPresets = FounderCommandPreset.markdown(
            primaryChannel: primaryChannel,
            backupChannel: backupChannel
        )

        return """
        # Fluid Reader Fame Pack

        ## Snapshot
        Saved \(safeSavedItemCount), events \(safeActivityLogItemCount), momentum \(momentum).
        Cadence kit streak: \(cadenceSummary).

        ## Win Recap Pack
        \(recapPack)

        ## Launch Kit
        \(launchKitPack)

        ## Fame Sprint
        \(sprintPack)

        ## Founder Command Presets
        \(commandPresets)
        """
    }

    private static func cadenceExecutionKitStreakSummary(
        currentStreak: Int,
        bestStreak: Int
    ) -> String {
        let normalizedCurrentStreak = max(0, currentStreak)
        let normalizedBestStreak = max(normalizedCurrentStreak, max(0, bestStreak))

        if normalizedCurrentStreak > 0 {
            return "x\(normalizedCurrentStreak) (best x\(normalizedBestStreak))"
        }
        if normalizedBestStreak > 0 {
            return "reset (best x\(normalizedBestStreak))"
        }
        return "not started"
    }

    private static func winRecap(savedItemCount: Int, activityLogItemCount: Int, style: Int) -> String {
        switch style {
        case 0:
            return """
            Fluid Reader win
            Saved items: \(savedItemCount)
            Safe events: \(activityLogItemCount)
            #macOS #productivity #opensource
            """
        case 1:
            return """
            Fluid Reader on macOS.
            Saved \(savedItemCount), events \(activityLogItemCount).
            #opensource #macOS
            """
        default:
            return """
            Local-first Fluid Reader flow.
            Saved \(savedItemCount) items, \(activityLogItemCount) safe events.
            #productivity #opensource
            """
        }
    }

    private static func fameSprintCadenceLines(dailyReplyTarget: Int) -> [String] {
        [
            "Day 1: Run Pick and Read, post one demo clip, and share Copy Win Recap.",
            "Day 2: Publish one hook remix and reply to \(dailyReplyTarget) builders.",
            "Day 3: Ship one before/after proof thread and DM 3 potential testers.",
            "Day 4: Post one 30s command race and push 1 community comment.",
            "Day 5: Share one user quote, one win card image, and ask for 3 intros.",
            "Day 6: Run Copy Launch Kit, publish one long-form recap, and collect feedback.",
            "Day 7: Share Copy Fame Board, pick top experiment, and reset next sprint."
        ]
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }
}
