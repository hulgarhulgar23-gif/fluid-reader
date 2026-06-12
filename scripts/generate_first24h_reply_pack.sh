#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a first-24-hour reply snippets pack for growth replies.

Usage:
  zsh scripts/generate_first24h_reply_pack.sh [options]

Options:
  --week <YYYY-Www>                Sprint week label (default: current ISO week)
  --metric-focus <text>            Metric focus line (default: Win Card copies and reply quality)
  --primary-channel <text>         Primary channel label (default: X / Threads)
  --backup-channel <text>          Backup channel label (default: LinkedIn)
  --strongest-metric-label <text>  Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>  Strongest metric value (default: n/a)
  --command <text>                 Suggested first command (default: derived from strongest metric)
  --out <path>                     Output markdown path (required)
  -h, --help                       Show this help

Example:
  zsh scripts/generate_first24h_reply_pack.sh \
    --week "$(date +%Y-W%V)" \
    --primary-channel "X / Threads" \
    --backup-channel "LinkedIn" \
    --strongest-metric-label "Win Card copies" \
    --strongest-metric-value "42" \
    --out .build/growth/$(date +%Y-W%V)-reply-pack.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
primary_channel="X / Threads"
backup_channel="LinkedIn"
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
command_name="Copy Win Card"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week="${2:-}"
      shift 2
      ;;
    --metric-focus)
      metric_focus="${2:-}"
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
    --strongest-metric-label)
      strongest_metric_label="${2:-}"
      shift 2
      ;;
    --strongest-metric-value)
      strongest_metric_value="${2:-}"
      shift 2
      ;;
    --command)
      command_name="${2:-}"
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

if [[ -z "$output_path" ]]; then
  echo "--out is required" >&2
  usage
  exit 1
fi

if [[ -z "$metric_focus" ]]; then
  metric_focus="Win Card copies and reply quality"
fi

if [[ -z "$command_name" ]]; then
  if [[ "${strongest_metric_label:l}" == *"recap"* ]]; then
    command_name="Copy Win Recap"
  else
    command_name="Copy Win Card"
  fi
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

channel_profile() {
  local channel_label="${1:l}"
  if [[ "$channel_label" == *"thread"* || "$channel_label" == *"x /"* || "$channel_label" == "x" ]]; then
    echo "fast"
    return
  fi
  if [[ "$channel_label" == *"linkedin"* ]]; then
    echo "professional"
    return
  fi
  if [[ "$channel_label" == *"reddit"* || "$channel_label" == *"hacker news"* || "$channel_label" == *"community"* || "$channel_label" == *"forum"* ]]; then
    echo "community"
    return
  fi
  echo "balanced"
}

build_proof_reply() {
  local profile="$1"
  case "$profile" in
    fast)
      cat <<EOF
This week: $strongest_metric_label = $strongest_metric_value.

Flow used:
Option + Shift + Space -> Read Selected Text -> $command_name
EOF
      ;;
    professional)
      cat <<EOF
Practical weekly signal:
$strongest_metric_label reached $strongest_metric_value.

We used this repeatable flow:
Read Selected Text -> Ask Anything -> $command_name.
EOF
      ;;
    community)
      cat <<EOF
No-hype result:
$strongest_metric_label moved to $strongest_metric_value this week.

Exact flow:
Read Selected Text -> Ask Anything -> $command_name
EOF
      ;;
    *)
      cat <<EOF
Strongest signal this week:
$strongest_metric_label = $strongest_metric_value.

Command path:
Read Selected Text -> Ask Anything -> $command_name
EOF
      ;;
  esac
}

build_workflow_reply() {
  local profile="$1"
  case "$profile" in
    fast)
      cat <<EOF
Fast start:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

Works best when the prompt is practical and specific.
EOF
      ;;
    professional)
      cat <<EOF
Repeatable first-use workflow:
1) Open Commands
2) Read Selected Text from real work context
3) Run $command_name for a share-ready output

Focus metric: $metric_focus
EOF
      ;;
    community)
      cat <<EOF
Setup-friendly workflow:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

If blocked, run Setup Checklist first.
EOF
      ;;
    *)
      cat <<EOF
Starter workflow:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

Then reuse the same flow in reply threads.
EOF
      ;;
  esac
}

build_objection_reply() {
  local profile="$1"
  case "$profile" in
    fast)
      cat <<EOF
Totally fair question.

Default path stays local on Mac, and LLM is optional.
If you want, I can share the exact setup path for your use case.
EOF
      ;;
    professional)
      cat <<EOF
Good question.

The baseline workflow runs locally (capture + OCR on device), with LLM optional.
If helpful, I can share the exact onboarding steps we use internally.
EOF
      ;;
    community)
      cat <<EOF
Reasonable concern.

Core mode is local-first on macOS; cloud LLM is optional.
If something breaks, share the blocked step and I can map it to docs quickly.
EOF
      ;;
    *)
      cat <<EOF
Great question.

Default mode is local on Mac and LLM is optional.
Share the exact blocker and I can send the shortest fix path.
EOF
      ;;
  esac
}

primary_channel_profile="$(channel_profile "$primary_channel")"
backup_channel_profile="$(channel_profile "$backup_channel")"

cat > "$output_path" <<EOF
<!-- weekly-growth-reply-pack -->

# First 24-Hour Reply Pack: $week

Generated: $generated_on
Metric focus: $metric_focus
Strongest metric: $strongest_metric_label ($strongest_metric_value)

## Core Replies

### Reply: "How do I start?"

\`\`\`text
Fastest way to start:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

You should get a share-ready output in under a minute.
\`\`\`

### Reply: "What is the real benefit?"

\`\`\`text
For us, the strongest signal this week was:
$strongest_metric_label: $strongest_metric_value

That came from practical daily flows, not a one-off demo.
\`\`\`

### Reply: "Is this private?"

\`\`\`text
Default mode is local on Mac (OCR + capture on device).
LLM remains optional and can stay off if you need local-only use.
\`\`\`

### Reply: "What command should I use first?"

\`\`\`text
Start with $command_name, then keep one repeatable flow:
Read Selected Text -> Ask Anything -> $command_name.
\`\`\`

### Reply: "I am blocked on setup"

\`\`\`text
Run Setup Checklist and grant missing permissions first.
If it still fails, share which step is blocked and I can send the exact fix path.
\`\`\`

## Channel-Ready Variants

### $primary_channel (Primary channel)

#### Variant A (proof-first)

\`\`\`text
$(build_proof_reply "$primary_channel_profile")
\`\`\`

#### Variant B (workflow-first)

\`\`\`text
$(build_workflow_reply "$primary_channel_profile")
\`\`\`

#### Variant C (objection-handler)

\`\`\`text
$(build_objection_reply "$primary_channel_profile")
\`\`\`

### $backup_channel (Backup channel)

#### Variant A (proof-first)

\`\`\`text
$(build_proof_reply "$backup_channel_profile")
\`\`\`

#### Variant B (workflow-first)

\`\`\`text
$(build_workflow_reply "$backup_channel_profile")
\`\`\`

#### Variant C (objection-handler)

\`\`\`text
$(build_objection_reply "$backup_channel_profile")
\`\`\`

### Community long-form fallback

\`\`\`text
No hype version:
- Problem we targeted: $metric_focus
- Command we used first: $command_name
- Signal that moved: $strongest_metric_label ($strongest_metric_value)

Happy to share exact steps for your use case.
\`\`\`

## First 24-Hour Execution Checklist

- [ ] Reply to practical setup questions within 24 hours.
- [ ] Reuse strongest metric line in at least 3 replies.
- [ ] Capture one objection and route it to docs/workflow.
- [ ] Capture one positive result as next-week hook seed.
EOF

echo "Wrote first-24h reply pack: $output_path"
