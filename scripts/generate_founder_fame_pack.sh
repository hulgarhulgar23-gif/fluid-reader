#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder fame pack from scoreboard + weekly delta reports.

Usage:
  zsh scripts/generate_founder_fame_pack.sh [options]

Required:
  --scoreboard <path>      Scoreboard markdown from generate_founder_scoreboard.sh
  --delta <path>           Delta markdown from generate_founder_weekly_delta.sh
  --out <path>             Output markdown path

Optional:
  --week <label>           Week label override (default: inferred from scoreboard)
  --product <text>         Product name (default: Fluid Reader)
  --primary-channel <text> Primary channel label (default: X / Threads)
  --backup-channel <text>  Backup channel label (default: LinkedIn)
  --cta <text>             CTA line for post drafts
  -h, --help               Show help

Example:
  zsh scripts/generate_founder_fame_pack.sh \
    --scoreboard .build/founder/scoreboard-2026-W23.md \
    --delta .build/founder/weekly-delta-2026-W23.md \
    --out .build/founder/founder-fame-pack-2026-W23.md
EOF
}

scoreboard_path=""
delta_path=""
output_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="If you're building too, reply with your bottleneck and I will share our exact weekly execution flow."

while (( $# > 0 )); do
  case "$1" in
    --scoreboard)
      scoreboard_path="${2:-}"
      shift 2
      ;;
    --delta)
      delta_path="${2:-}"
      shift 2
      ;;
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --product)
      product_name="${2:-}"
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
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for pair in \
  "scoreboard_path:$scoreboard_path" \
  "delta_path:$delta_path" \
  "output_path:$output_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

if [[ ! -f "$scoreboard_path" ]]; then
  echo "Scoreboard file not found: $scoreboard_path" >&2
  exit 1
fi
if [[ ! -f "$delta_path" ]]; then
  echo "Delta file not found: $delta_path" >&2
  exit 1
fi

trim() {
  echo "$1" | sed -E 's/^ +| +$//g'
}

extract_heading_suffix() {
  local file="$1"
  local prefix="$2"
  local label
  label="$(sed -n "s/^# ${prefix} - //p" "$file" | head -n 1)"
  if [[ -z "$label" ]]; then
    echo "n/a"
  else
    echo "$label"
  fi
}

extract_snapshot_value() {
  local file="$1"
  local key="$2"
  local line
  line="$(grep -E "^- ${key}:" "$file" | head -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  trim "$(echo "$line" | sed -E "s/^- ${key}: *//")"
}

extract_metric_row() {
  local file="$1"
  local metric="$2"
  awk -F'|' -v metric="$metric" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 ~ /^\|/ {
      key = clean($2)
      if (key == metric) {
        target = clean($3)
        actual = clean($4)
        delta = clean($5)
        status = clean($6)
        direction = clean($7)
        print target "\t" actual "\t" delta "\t" status "\t" direction
        exit
      }
    }
  ' "$file"
}

extract_signal_line() {
  local file="$1"
  local index="$2"
  awk -v idx="$index" '
    /^## Signals/ { in_signals=1; next }
    in_signals && /^## / { in_signals=0 }
    in_signals && /^- / {
      count++
      if (count == idx) {
        sub(/^- /, "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

scoreboard_heading="$(extract_heading_suffix "$scoreboard_path" "Founder KPI Scoreboard")"
delta_heading="$(extract_heading_suffix "$delta_path" "Founder Weekly Delta")"

if [[ -z "$week_label" ]]; then
  week_label="$scoreboard_heading"
fi
if [[ "$week_label" == "n/a" || -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

on_track="$(extract_snapshot_value "$scoreboard_path" "On Track")"
at_risk="$(extract_snapshot_value "$scoreboard_path" "At Risk")"
off_track="$(extract_snapshot_value "$scoreboard_path" "Off Track")"
summary="$(extract_snapshot_value "$scoreboard_path" "Summary")"

mrr_row="$(extract_metric_row "$scoreboard_path" "MRR")"
cac_row="$(extract_metric_row "$scoreboard_path" "CAC")"
ltv_cac_row="$(extract_metric_row "$scoreboard_path" "LTV/CAC")"

if [[ -z "$mrr_row" ]]; then mrr_row=$'n/a\tn/a\tn/a\tn/a\tn/a'; fi
if [[ -z "$cac_row" ]]; then cac_row=$'n/a\tn/a\tn/a\tn/a\tn/a'; fi
if [[ -z "$ltv_cac_row" ]]; then ltv_cac_row=$'n/a\tn/a\tn/a\tn/a\tn/a'; fi

IFS=$'\t' read -r mrr_target mrr_actual mrr_delta mrr_status _ <<< "$mrr_row"
IFS=$'\t' read -r cac_target cac_actual cac_delta cac_status _ <<< "$cac_row"
IFS=$'\t' read -r ltv_cac_target ltv_cac_actual ltv_cac_delta ltv_cac_status _ <<< "$ltv_cac_row"

signal_1="$(extract_signal_line "$delta_path" 1)"
signal_2="$(extract_signal_line "$delta_path" 2)"
if [[ -z "$signal_1" ]]; then signal_1="Signal unavailable. Re-run weekly delta report."; fi
if [[ -z "$signal_2" ]]; then signal_2="Use scoreboard status to pick one focused experiment."; fi

on_track_num="${on_track:-0}"
at_risk_num="${at_risk:-0}"
off_track_num="${off_track:-0}"

if ! [[ "$on_track_num" =~ ^[0-9]+$ ]]; then on_track_num=0; fi
if ! [[ "$at_risk_num" =~ ^[0-9]+$ ]]; then at_risk_num=0; fi
if ! [[ "$off_track_num" =~ ^[0-9]+$ ]]; then off_track_num=0; fi

momentum_score=$(( (on_track_num * 20) + (at_risk_num * 8) - (off_track_num * 5) + 20 ))
if (( momentum_score < 0 )); then momentum_score=0; fi
if (( momentum_score > 100 )); then momentum_score=100; fi

momentum_tier="Early"
if (( momentum_score >= 80 )); then
  momentum_tier="Breakout"
elif (( momentum_score >= 55 )); then
  momentum_tier="Rising"
fi

focus_line="Tighten weakest KPI before expanding channel spend."
if (( off_track_num >= 2 )); then
  focus_line="Repair off-track KPIs first, then re-test growth spend."
elif [[ "$mrr_status" == "On Track" && "$ltv_cac_status" == "On Track" ]]; then
  focus_line="Unit economics are healthy. Scale distribution in a controlled way."
elif [[ "$cac_status" == "Off Track" ]]; then
  focus_line="CAC is off track. Improve acquisition efficiency before scaling."
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Fame Pack - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source scoreboard: ${scoreboard_heading}
Source delta: ${delta_heading}

## Momentum Engine

- Momentum score: ${momentum_score}/100 (${momentum_tier})
- Scoreboard state: ${on_track} on track / ${at_risk} at risk / ${off_track} off track
- Weekly summary: ${summary}
- Current focus: ${focus_line}

## Proof Stack

- MRR: ${mrr_actual} (target ${mrr_target}, delta ${mrr_delta}, status ${mrr_status})
- CAC: ${cac_actual} (target ${cac_target}, delta ${cac_delta}, status ${cac_status})
- LTV/CAC: ${ltv_cac_actual} (target ${ltv_cac_target}, delta ${ltv_cac_delta}, status ${ltv_cac_status})
- Signals:
  - ${signal_1}
  - ${signal_2}

## Post Drafts

### Primary (${primary_channel})

\`\`\`text
Founder update (${week_label}) for ${product_name}:

- Momentum: ${momentum_score}/100 (${momentum_tier})
- MRR: ${mrr_actual} (${mrr_delta} vs target)
- CAC: ${cac_actual} (${cac_delta} vs target)
- LTV/CAC: ${ltv_cac_actual} (${ltv_cac_delta} vs target)

Focus: ${focus_line}
${cta_text}
\`\`\`

### Backup (${backup_channel})

\`\`\`text
Weekly founder execution snapshot (${week_label}):

Scoreboard: ${on_track} on track / ${at_risk} at risk / ${off_track} off track
Headline metrics: MRR ${mrr_actual}, CAC ${cac_actual}, LTV/CAC ${ltv_cac_actual}
Current focus: ${focus_line}

${cta_text}
\`\`\`

## 7-Day Fame Sprint

1. Monday: Publish primary draft + pin top proof point.
2. Tuesday: Reply to objections and save high-signal comments.
3. Wednesday: Share one workflow breakdown with commands used.
4. Thursday: Publish one case-study style before/after.
5. Friday: Post KPI delta + next-week experiment.
6. Saturday: Recut best-performing draft for backup channel.
7. Sunday: Queue Monday draft with strongest signal first.

## Reply Seeds

- "What moved this week?" -> ${signal_1}
- "What are you fixing next?" -> ${signal_2}
- "How are you measuring this?" -> Weekly review + delta + scoreboard + fame pack workflow.
EOF

echo "Wrote founder fame pack: $output_path"
