#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a launch-ready social proof kit from one real workflow result.

Usage:
  zsh scripts/generate_social_proof_kit.sh [options]

Options:
  --week <YYYY-Www>            Launch week label (default: current ISO week)
  --command <name>             Command to spotlight (default: Copy Win Card)
  --problem <text>             Before-state problem statement
  --outcome <text>             After-state outcome statement
  --metric <text>              Measurable result statement
  --primary-channel <text>     Main channel label (default: X / Threads)
  --backup-channel <text>      Backup channel label (default: LinkedIn)
  --cta <text>                 Primary call-to-action line
  --out <path>                 Output markdown path
  -h, --help                   Show this help

Example:
  zsh scripts/generate_social_proof_kit.sh \
    --command "Copy Win Card" \
    --problem "manual weekly status updates" \
    --outcome "share-ready recap in under one minute" \
    --metric "saved ~10 minutes per day" \
    --out docs/campaigns/$(date +%Y-W%V)-social-proof.md
EOF
}

week=""
command_name="Copy Win Card"
problem_statement="manual weekly status updates"
outcome_statement="share-ready recap in under one minute"
metric_statement="saved ~10 minutes per day"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="Try this flow and share your first Win Card."
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
# Social Proof Kit: $week

Generated: $generated_on

## Snapshot

- Primary channel: $primary_channel
- Backup channel: $backup_channel
- Command spotlight: \`$command_name\`
- Problem: $problem_statement
- Outcome: $outcome_statement
- Metric: $metric_statement

## Launch Hook

- One-line hook: I turned "$problem_statement" into "$outcome_statement".
- Proof line: $metric_statement.
- CTA: $cta_text

## Primary Channel Draft ($primary_channel)

\`\`\`text
I turned "$problem_statement" into "$outcome_statement".

Flow:
- Option + Shift + Space
- Read Selected Text
- $command_name

Result: $metric_statement.
$cta_text
\`\`\`

## Backup Channel Draft ($backup_channel)

\`\`\`text
This week I focused on one practical workflow:
Option + Shift + Space -> Read Selected Text -> $command_name

Problem solved: $problem_statement.
Outcome: $outcome_statement.
Measured gain: $metric_statement.
\`\`\`

## Community Comment Draft

\`\`\`text
Exact workflow:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

Result: $outcome_statement ($metric_statement).
\`\`\`

## First 24-Hour Reply Queue

- FAQ 1: "How do I start?" -> share the 60-second activation flow.
- FAQ 2: "What gain should I expect?" -> answer with "$metric_statement".
- FAQ 3: "Which command first?" -> recommend "$command_name".
- FAQ 4: "Can I run local-only?" -> yes, local flow works without LLM.

## CTA Split Test

- CTA A: $cta_text
- CTA B: Reply with your workflow and I’ll suggest the first command.
EOF
)"

if [[ -n "$output_path" ]]; then
  mkdir -p "$(dirname "$output_path")"
  print -r -- "$kit_content" > "$output_path"
  echo "Wrote social proof kit: $output_path"
else
  print -r -- "$kit_content"
fi
