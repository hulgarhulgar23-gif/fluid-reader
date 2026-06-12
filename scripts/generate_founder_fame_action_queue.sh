#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a ranked founder fame Monday action queue from an ops brief.

Usage:
  zsh scripts/generate_founder_fame_action_queue.sh [options]

Required:
  --ops-brief <path>          Founder fame ops brief markdown path

Optional:
  --daily-mission <path>      In-app daily mission markdown for 3-hour bridge sync
  --require-fresh-daily-mission
                              Fail generation unless the daily mission date is fresh
  --daily-mission-max-age-days <days>
                              Freshness threshold in days when mission is provided (default: 1)
  --week <label>              Week label (default: inferred from ops brief heading, then current ISO week)
  --out <path>                Output path (default: docs/campaigns/<week>-founder-fame-action-queue.md)
  -h, --help                  Show help

Example:
  zsh scripts/generate_founder_fame_action_queue.sh \
    --ops-brief docs/campaigns/2026-W23-founder-fame-ops-brief.md \
    --daily-mission scripts/fixtures/founder/sample_daily_mission.md \
    --out docs/campaigns/2026-W23-founder-fame-action-queue.md
EOF
}

ops_brief_path=""
daily_mission_path=""
require_fresh_daily_mission=0
daily_mission_max_age_days="1"
week_label=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --ops-brief)
      ops_brief_path="${2:-}"
      shift 2
      ;;
    --daily-mission)
      daily_mission_path="${2:-}"
      shift 2
      ;;
    --require-fresh-daily-mission)
      require_fresh_daily_mission=1
      shift
      ;;
    --daily-mission-max-age-days)
      daily_mission_max_age_days="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
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
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ops_brief_path" ]]; then
  echo "Missing required option: --ops-brief" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$ops_brief_path" ]]; then
  echo "Ops brief file not found: $ops_brief_path" >&2
  exit 1
fi

if [[ -n "$daily_mission_path" && ! -f "$daily_mission_path" ]]; then
  echo "Daily mission file not found: $daily_mission_path" >&2
  exit 1
fi

if [[ ! "$daily_mission_max_age_days" =~ ^[0-9]+$ ]]; then
  echo "Invalid daily mission max-age days value: $daily_mission_max_age_days" >&2
  exit 1
fi

if (( require_fresh_daily_mission )) && [[ -z "$daily_mission_path" ]]; then
  echo "Missing required option: --daily-mission (required when --require-fresh-daily-mission is set)" >&2
  usage >&2
  exit 1
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  trim_value "${line#"$prefix"}"
}

extract_week_from_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Ops Brief:' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Ops Brief:"}"
}

extract_section_prefixed_value() {
  local source_path="$1"
  local section_heading="$2"
  local prefix="$3"

  awk -v heading="$section_heading" -v prefix="$prefix" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section {
      if (index($0, prefix) == 1) {
        value = substr($0, length(prefix) + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", value)
        print value
        found = 1
        exit
      }
    }
    END {
      if (!found) {
        print "n/a"
      }
    }
  ' "$source_path"
}

date_to_epoch() {
  local date_value="$1"
  if date -j -f "%Y-%m-%d" "$date_value" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d" "$date_value" "+%s"
    return
  fi
  if date -d "$date_value" "+%s" >/dev/null 2>&1; then
    date -d "$date_value" "+%s"
    return
  fi
  echo ""
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading "$ops_brief_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-action-queue.md"
fi

metric_focus="$(extract_prefixed_value "$ops_brief_path" "- Metric focus: ")"
strongest_metric="$(extract_prefixed_value "$ops_brief_path" "- Strongest metric: ")"
lead_channel="$(extract_prefixed_value "$ops_brief_path" "- Lead channel: ")"
support_channel="$(extract_prefixed_value "$ops_brief_path" "- Support channel: ")"
reply_goal="$(extract_prefixed_value "$ops_brief_path" "- Reply goal (24h): ")"
outreach_goal="$(extract_prefixed_value "$ops_brief_path" "- Outreach goal (7d): ")"
scoreboard_state="$(extract_prefixed_value "$ops_brief_path" "- Scoreboard state: ")"
weekly_summary="$(extract_prefixed_value "$ops_brief_path" "- Weekly summary: ")"
mix_recommendation="$(extract_prefixed_value "$ops_brief_path" "- Mix recommendation: ")"

if [[ -n "$daily_mission_path" ]]; then
  mission_source="$daily_mission_path"
  mission_date="$(extract_prefixed_value "$daily_mission_path" "Date: ")"
  mission_pulse_risk="$(extract_prefixed_value "$daily_mission_path" "Pulse risk: ")"
  mission_lead_experiment="$(extract_prefixed_value "$daily_mission_path" "Lead experiment: ")"
  mission_must_ship_alert="$(extract_prefixed_value "$daily_mission_path" "Must-ship alert: ")"
  mission_block_0_20="$(extract_section_prefixed_value "$daily_mission_path" "## 3-Hour Mission" "- 0-20m: ")"
  mission_block_20_90="$(extract_section_prefixed_value "$daily_mission_path" "## 3-Hour Mission" "- 20-90m: ")"
  mission_block_90_180="$(extract_section_prefixed_value "$daily_mission_path" "## 3-Hour Mission" "- 90-180m: ")"
  mission_freshness_guardrail="<= ${daily_mission_max_age_days} day old mission date"
  mission_age_days="n/a"
  mission_freshness="Unknown (Date: must be YYYY-MM-DD)"

  mission_date_epoch="$(date_to_epoch "$mission_date")"
  if [[ -n "$mission_date_epoch" ]]; then
    current_epoch="$(date '+%s')"
    mission_age_days="$(( (current_epoch - mission_date_epoch) / 86400 ))"
    if (( mission_age_days < -1 )); then
      mission_freshness="Future-dated by $(( -mission_age_days ))d (check timezone or source file)"
    elif (( mission_age_days <= daily_mission_max_age_days )); then
      mission_freshness="Fresh (${mission_age_days}d old)"
    else
      mission_freshness="Stale (${mission_age_days}d old; max ${daily_mission_max_age_days}d)"
    fi
  fi

  if (( require_fresh_daily_mission )) && [[ "$mission_freshness" != Fresh* ]]; then
    echo "Daily mission freshness requirement failed: $mission_freshness" >&2
    echo "Run in-app Daily Fame Mission again and pass a fresh artifact via --daily-mission." >&2
    exit 1
  fi
else
  mission_source="n/a (optional --daily-mission)"
  mission_date="n/a (run in-app Daily Fame Mission first)"
  mission_age_days="n/a"
  mission_freshness="n/a (daily mission not provided)"
  mission_freshness_guardrail="optional; pass --daily-mission to sync the 3-hour bridge"
  mission_pulse_risk="n/a"
  mission_lead_experiment="n/a"
  mission_must_ship_alert="n/a"
  mission_block_0_20="n/a"
  mission_block_20_90="n/a"
  mission_block_90_180="n/a"
fi

next_24h_actions=()
while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="$(trim_value "$line")"
  [[ -z "$trimmed" ]] && continue
  cleaned="${trimmed#<->}"
  cleaned="${cleaned#<->}"
  if [[ "$cleaned" =~ ^[0-9]+\.\  ]]; then
    cleaned="${cleaned#*. }"
    next_24h_actions+=("$cleaned")
  fi
done < <(
  awk '
    /^## Next 24 Hours/ { in_section=1; next }
    /^## / && in_section { in_section=0 }
    in_section { print }
  ' "$ops_brief_path"
)

if (( ${#next_24h_actions[@]} < 1 )); then
  next_24h_actions+=("Publish proof-first message in the lead channel.")
fi
if (( ${#next_24h_actions[@]} < 2 )); then
  next_24h_actions+=("Ship one support-channel follow-up with concrete CTA.")
fi
if (( ${#next_24h_actions[@]} < 3 )); then
  next_24h_actions+=("Handle practical replies and log top objections.")
fi

top_action_1="${next_24h_actions[1]}"
top_action_2="${next_24h_actions[2]}"
top_action_3="${next_24h_actions[3]}"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-action-queue -->

# Founder Fame Action Queue: $week_label

Generated: $generated_on
Source ops brief: $ops_brief_path

## Snapshot

- Metric focus: $metric_focus
- Strongest metric: $strongest_metric
- Lead / support channels: $lead_channel / $support_channel
- Reply goal (24h): $reply_goal
- Outreach goal (7d): $outreach_goal
- Scoreboard state: $scoreboard_state
- Weekly summary: $weekly_summary

## Top 3 Monday Actions

1. [ ] $top_action_1
2. [ ] $top_action_2
3. [ ] $top_action_3

## Action Owners

| Rank | Action | Suggested owner | Completion window (UTC) |
| --- | --- | --- | --- |
| 1 | $top_action_1 | Founder / launch lead | 09:00-11:00 |
| 2 | $top_action_2 | Distribution owner | 11:00-13:00 |
| 3 | $top_action_3 | Community + support owner | 13:00-16:00 |

## 3-Hour Mission Bridge

- Daily mission source: $mission_source
- Mission date: $mission_date
- Mission age (days): $mission_age_days
- Mission freshness: $mission_freshness
- Freshness guardrail: $mission_freshness_guardrail
- Pulse risk: $mission_pulse_risk
- Lead experiment: $mission_lead_experiment
- 0-20m block: $mission_block_0_20
- 20-90m block: $mission_block_20_90
- 90-180m block: $mission_block_90_180
- Must-ship alert: $mission_must_ship_alert

## Queue Notes

- Mix recommendation: $mix_recommendation
- Use the lead channel first, then support-channel follow-up within the same day.
- If mission freshness is stale, rerun in-app Daily Fame Mission before owner handoff.
- Carry unresolved objections into the next docs/workflow update block.

## Copy Block

\`\`\`text
Founder Monday action queue ($week_label):
1) $top_action_1
2) $top_action_2
3) $top_action_3

Metric anchor: $strongest_metric
Mix call: $mix_recommendation
Mission bridge (0-20m): $mission_block_0_20
Mission freshness: $mission_freshness
\`\`\`
EOF

echo "Wrote founder fame action queue: $output_path"
