#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly growth campaign pack from one real app win.

Usage:
  zsh scripts/generate_campaign_pack.sh [options]

Options:
  --week <YYYY-Www>         Campaign week label (default: current ISO week)
  --command <name>          Command to spotlight (default: Read Selected Text)
  --problem <text>          Before state / problem statement
  --outcome <text>          After state / outcome statement
  --metric <text>           Measurable result to repeat
  --workflow <a|b|c>        Pipe-separated 3-step workflow commands
  --cta <text>              Call to action
  --audience <text>         Audience label
  --asset <text>            Primary proof asset (default: Copy Win Card)
  --builder <text>          Author name for the pack header
  --out <path>              Write output markdown to this path
  -h, --help                Show this help

Example:
  zsh scripts/generate_campaign_pack.sh \
    --command "Copy Win Card" \
    --problem "manual end-of-day recap" \
    --outcome "share-ready recap in under a minute" \
    --metric "saved ~12 minutes per day" \
    --workflow "Read Selected Text|Ask Anything|Copy Win Card" \
    --out docs/campaigns/$(date +%Y-W%V).md
EOF
}

week=""
command_name="Read Selected Text"
problem_statement="manual copy/paste + cleanup loops"
outcome_statement="a useful result in under one minute"
metric_statement="saved ~5 minutes on a repeat task"
workflow_steps="Read Selected Text|Ask Anything|Copy Win Card"
cta_text="Try this exact flow and share your first Win Card."
audience_label="builders, writers, and researchers"
asset_name="Copy Win Card"
builder_name="${USER:-Operator}"
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
    --workflow)
      workflow_steps="${2:-}"
      shift 2
      ;;
    --cta)
      cta_text="${2:-}"
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
    --builder)
      builder_name="${2:-}"
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

generated_on="$(date '+%Y-%m-%d')"

IFS='|' read -r step1 step2 step3 _ <<<"$workflow_steps"
step1="${step1:-Read Selected Text}"
step2="${step2:-Ask Anything}"
step3="${step3:-Copy Win Card}"
x_flow_asset="$asset_name"
if [[ "$command_name" == "$asset_name" ]]; then
  x_flow_asset="Share ${asset_name} output"
fi

pack_content="$(cat <<EOF
# Campaign Pack: $week

Generated: $generated_on
Owner: $builder_name
Audience: $audience_label

## Core Story

- Problem: $problem_statement
- Outcome: $outcome_statement
- Metric: $metric_statement
- Command spotlight: \`$command_name\`
- Proof asset: \`$asset_name\`

## Monday: Before / After Post

\`\`\`text
Before: $problem_statement
After: Option + Shift + Space + $command_name

Result: $outcome_statement ($metric_statement).
$cta_text
\`\`\`

## Wednesday: Command Spotlight Post

\`\`\`text
Command spotlight: $command_name

I use this for $problem_statement.
This week it produced $outcome_statement.
Measured result: $metric_statement.
\`\`\`

## Friday: 3-Step Workflow Post

\`\`\`text
Tiny workflow I now use:
1) $step1
2) $step2
3) $step3

Outcome: $outcome_statement.
\`\`\`

## Channel Variants

### X / Threads (short)

\`\`\`text
I turned "$problem_statement" into "$outcome_statement".

Flow:
- Option + Shift + Space
- $command_name
- $x_flow_asset
\`\`\`

### LinkedIn (context + outcome)

\`\`\`text
This week I focused on $problem_statement.

Using Fluid Reader with "$command_name", I now get $outcome_statement.
Measured outcome: $metric_statement.

$cta_text
\`\`\`

### Community Comment (practical)

\`\`\`text
Exact flow I used:
1) $step1
2) $step2
3) $step3

Measured gain: $metric_statement.
\`\`\`

## 24-Hour Reply Queue

- FAQ reply 1: "How do I start?" -> share the 60-second activation flow.
- FAQ reply 2: "What is the real gain?" -> answer with "$metric_statement".
- FAQ reply 3: "Which command first?" -> recommend "$command_name".

## Friday Review Notes

- What post drove the most saves/replies?
- Which command story was easiest to explain?
- What should be reused next week?
EOF
)"

if [[ -n "$output_path" ]]; then
  mkdir -p "$(dirname "$output_path")"
  print -r -- "$pack_content" > "$output_path"
  echo "Wrote campaign pack: $output_path"
else
  print -r -- "$pack_content"
fi
