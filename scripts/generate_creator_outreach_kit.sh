#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a creator outreach kit for launch-week distribution.

Usage:
  zsh scripts/generate_creator_outreach_kit.sh [options]

Options:
  --week <YYYY-Www>            Launch week label (default: current ISO week)
  --command <name>             Command to spotlight (default: Copy Win Card)
  --problem <text>             Before-state problem statement
  --outcome <text>             After-state outcome statement
  --metric <text>              Measurable result statement
  --primary-channel <text>     Main channel label (default: X / Threads)
  --backup-channel <text>      Backup channel label (default: LinkedIn)
  --audience <text>            Target creator segment
  --asset <text>               Proof asset name (default: Copy Win Card)
  --cta <text>                 Call-to-action line
  --out <path>                 Output markdown path
  -h, --help                   Show this help

Example:
  zsh scripts/generate_creator_outreach_kit.sh \
    --command "Copy Win Card" \
    --problem "manual weekly status updates" \
    --outcome "share-ready recap in under one minute" \
    --metric "saved ~10 minutes per day" \
    --out docs/campaigns/$(date +%Y-W%V)-creator-outreach.md
EOF
}

week=""
command_name="Copy Win Card"
problem_statement="manual weekly status updates"
outcome_statement="share-ready recap in under one minute"
metric_statement="saved ~10 minutes per day"
primary_channel="X / Threads"
backup_channel="LinkedIn"
audience_label="indie builders, technical creators, and operator communities"
asset_name="Copy Win Card"
cta_text="Want a private demo pass and the exact setup flow?"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week="${2:-}"
      shift 2
      ;;
    --command)
      command_name="${2:-}"
      shift 2
      ;;
    --problem)
      problem_statement="${2:-}"
      shift 2
      ;;
    --outcome)
      outcome_statement="${2:-}"
      shift 2
      ;;
    --metric)
      metric_statement="${2:-}"
      shift 2
      ;;
    --primary-channel)
      primary_channel="${2:-}"
      shift 2
      ;;
    --backup-channel)
      backup_channel="${2:-}"
      shift 2
      ;;
    --audience)
      audience_label="${2:-}"
      shift 2
      ;;
    --asset)
      asset_name="${2:-}"
      shift 2
      ;;
    --cta)
      cta_text="${2:-}"
      shift 2
      ;;
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$week" ]]; then
  week="$(date '+%Y-W%V')"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

kit_content="$(cat <<EOF
# Creator Outreach Kit: $week

Generated: $generated_on

## Snapshot

- Primary launch channel: $primary_channel
- Backup launch channel: $backup_channel
- Creator audience: $audience_label
- Command spotlight: \`$command_name\`
- Proof asset: \`$asset_name\`
- Problem solved: $problem_statement
- Outcome delivered: $outcome_statement
- Proof metric: $metric_statement

## Outreach Positioning

- Core angle: turn "$problem_statement" into "$outcome_statement" in one practical flow.
- Why now: teams want practical AI workflows they can adopt in minutes, not tutorials that never get used.
- Credibility line: "$metric_statement" using \`$command_name\` as the repeatable final step.

## Creator DM Drafts

### DM 1 — Build-in-public creator

\`\`\`text
Hey! I’ve been using Fluid Reader to turn "$problem_statement" into "$outcome_statement".

The repeatable flow is:
- Option + Shift + Space
- Read Selected Text
- $command_name

Measured result: $metric_statement.
If useful, I can send a 60-second walkthrough and sample asset ($asset_name).
\`\`\`

### DM 2 — Newsletter writer

\`\`\`text
I have a short workflow your readers can copy:
Problem: $problem_statement
Outcome: $outcome_statement
Metric: $metric_statement

Happy to share a concise guest section + one screenshot if you want.
\`\`\`

### DM 3 — Workflow/video creator

\`\`\`text
Would love to collaborate on a practical mini-demo.
Hook: "$problem_statement" -> "$outcome_statement".
Exact command path: Read Selected Text -> Ask Anything -> $command_name.

$cta_text
\`\`\`

## Podcast / Interview Pitch

\`\`\`text
Episode angle:
"How tiny local-first workflows beat big generic AI demos."

Case study:
- Starting pain: $problem_statement
- Working flow: Option + Shift + Space -> Read Selected Text -> $command_name
- Practical result: $outcome_statement
- Measured gain: $metric_statement
\`\`\`

## Community Moderator Pitch

\`\`\`text
Could I share a practical no-hype workflow post?

It covers one repeatable use case:
- Problem: $problem_statement
- Flow: Read Selected Text -> Ask Anything -> $command_name
- Result: $outcome_statement ($metric_statement)

I’ll keep it implementation-first and include caveats.
\`\`\`

## Partner Tracker

| Target | Type | Angle | Ask | Status | Follow-up |
| --- | --- | --- | --- | --- | --- |
| Creator #1 | Build-in-public | Before/after | DM + 60s walkthrough | Not sent | Day 2 |
| Creator #2 | Newsletter | Practical workflow write-up | Guest section | Not sent | Day 3 |
| Creator #3 | Video/shorts | Screen flow demo | Co-post clip | Not sent | Day 2 |
| Community #1 | Forum/moderator | No-hype command path | Approved post slot | Pending | Day 4 |
| Podcast #1 | Interview host | Local-first AI ops | 20-min interview | Not sent | Day 5 |

## 7-Day Follow-Up Cadence

- Day 0: Send 5 focused outreach messages.
- Day 1: Publish proof-first post on $primary_channel.
- Day 2: Follow up with top 3 creator prospects.
- Day 3: Publish context-first variant on $backup_channel.
- Day 4: Share one community adaptation with exact command flow.
- Day 5: Convert best response into a docs snippet and repost.
- Day 7: Review acceptance rate and refresh top 3 pitches.

## CTA Split Test

- CTA A: $cta_text
- CTA B: Reply with your workflow niche and I will tailor a 3-command script.
EOF
)"

if [[ -n "$output_path" ]]; then
  mkdir -p "$(dirname "$output_path")"
  print -r -- "$kit_content" > "$output_path"
  echo "Wrote creator outreach kit: $output_path"
else
  print -r -- "$kit_content"
fi
