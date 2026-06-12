import Foundation

enum FounderCommandPreset {
    static func markdown(
        primaryChannel: String = "X / Threads",
        backupChannel: String = "LinkedIn"
    ) -> String {
        """
        Fame command presets

        KPI formulas (Commands)
        - roi 1200 1000
        - margin 100 75
        - breakeven 10000 50 30
        - runway 240000 12000
        - payback 900 75
        - ltvcac 1350 150
        - run-fame-sprint
        - run-fame-sprint-snapshot
        - run-fame-next-move
        - run-fame-next-move-cadence-execution-kit
        - run-fame-next-move-copy-drafts
        - run-fame-morning-brief
        - run-fame-midday-brief
        - run-fame-evening-brief
        - run-fame-weekly-rollup
        - run-fame-24h-queue
        - run-fame-command-center
        - run-fame-breakthrough-forecast
        - run-fame-ops-bundle
        - run-fame-daily-checkpoint
        - run-fame-daily-scorecard
        - run-fame-escalation-nudge
        - run-fame-operator-dashboard
        - run-fame-narrative-lab
        - run-fame-spotlight-pack
        - run-fame-launch-day-script
        - run-fame-launch-countdown
        - run-fame-pulse-nudge
        - run-fame-recovery-checklist
        - run-fame-recovery-proof-pack
        - open-latest-command-center
        - open-latest-daily-checkpoint
        - open-latest-risk-timeline
        - open-latest-pulse-nudge
        - open-latest-daily-scorecard
        - open-latest-operator-dashboard
        - open-latest-narrative-lab
        - open-latest-spotlight-pack
        - open-latest-launch-day-script
        - open-latest-launch-countdown
        - open-latest-breakthrough-forecast
        - open-latest-morning-brief
        - open-latest-midday-brief
        - open-latest-evening-brief
        - open-latest-next-move-handoff
        - open-latest-next-move-draft-pack
        - copy-next-move-drafts
        - copy-next-move-launch-now-sequence
        - copy-next-move-cadence-execution-kit
        - copy-next-move-cadence-post-queue
        - copy-next-move-reply-ladder
        - copy-next-move-cadence-post
        - copy-next-move-x-draft
        - copy-next-move-bluesky-draft
        - copy-next-move-linkedin-draft
        - copy-next-move-cadence-step
        - open-latest-escalation-nudge
        - open-latest-recovery-checklist
        - open-latest-recovery-proof-pack
        - open-fame-snapshot-folder
        - copy-founder-command-presets
        - copy-launch-kit
        - copy-fame-sprint
        - copy-fame-pack
        - copy-experiment-board

        Fame scripts (Terminal)
        - zsh scripts/run_launch_day.sh --primary-channel "\(primaryChannel)" --backup-channel "\(backupChannel)"
        - zsh scripts/check_growth.sh
        - zsh scripts/check_fast.sh
        """
    }
}
