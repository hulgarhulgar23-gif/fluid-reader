#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a Monday publish checkpoint markdown file from weekly growth context.

Usage:
  zsh scripts/generate_monday_publish_checkpoint.sh [options]

Options:
  --week <YYYY-Www>                Sprint week label (default: current ISO week)
  --metric-focus <text>            Metric focus line (default: Win Card copies and reply quality)
  --primary-channel <text>         Primary channel label (default: X / Threads)
  --backup-channel <text>          Backup channel label (default: LinkedIn)
  --primary-audience-region <text> Primary audience region (global/us/eu/apac, default: global)
  --backup-audience-region <text>  Backup audience region (global/us/eu/apac, default: global)
  --primary-channel-roi-score <value> ROI score for primary channel (default: n/a)
  --backup-channel-roi-score <value> ROI score for backup channel (default: n/a)
  --channel-roi-preferred-channel <primary|backup|balanced> Preferred channel lead route (default: balanced)
  --channel-roi-recommendation <text> ROI-based channel routing recommendation (optional)
  --strongest-metric-label <text>  Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>  Strongest metric value (default: n/a)
  --draft-path <path>              Monday draft markdown path (optional)
  --out <path>                     Output markdown path (required)
  -h, --help                       Show this help

Example:
  zsh scripts/generate_monday_publish_checkpoint.sh \
    --week "$(date +%Y-W%V)" \
    --primary-channel "X / Threads" \
    --backup-channel "LinkedIn" \
    --strongest-metric-label "Win Card copies" \
    --strongest-metric-value "42" \
    --draft-path .build/growth/$(date +%Y-W%V)-monday-draft.md \
    --out .build/growth/$(date +%Y-W%V)-monday-checkpoint.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
primary_channel="X / Threads"
backup_channel="LinkedIn"
primary_audience_region="global"
backup_audience_region="global"
primary_channel_roi_score="n/a"
backup_channel_roi_score="n/a"
channel_roi_preferred_channel="balanced"
channel_roi_recommendation=""
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
draft_path=""
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
    --primary-audience-region)
      primary_audience_region="${2:-}"
      shift 2
      ;;
    --backup-audience-region)
      backup_audience_region="${2:-}"
      shift 2
      ;;
    --primary-channel-roi-score)
      primary_channel_roi_score="${2:-}"
      shift 2
      ;;
    --backup-channel-roi-score)
      backup_channel_roi_score="${2:-}"
      shift 2
      ;;
    --channel-roi-preferred-channel)
      channel_roi_preferred_channel="${2:-}"
      shift 2
      ;;
    --channel-roi-recommendation)
      channel_roi_recommendation="${2:-}"
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
    --draft-path)
      draft_path="${2:-}"
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

normalize_channel_preference() {
  local raw_value="$1"
  local lowered="${raw_value:l}"
  if [[ "$lowered" == "primary" || "$lowered" == *"lead with primary"* || "$lowered" == *"primary channel"* ]]; then
    echo "primary"
    return
  fi
  if [[ "$lowered" == "backup" || "$lowered" == *"lead with backup"* || "$lowered" == *"backup channel"* ]]; then
    echo "backup"
    return
  fi
  echo "balanced"
}

normalize_audience_region() {
  local raw_value="$1"
  local lowered="${raw_value:l}"
  if [[ -z "$lowered" || "$lowered" == "global" || "$lowered" == "world" || "$lowered" == "worldwide" ]]; then
    echo "global"
    return
  fi
  if [[ "$lowered" == "us" || "$lowered" == "usa" || "$lowered" == "north-america" || "$lowered" == "na" ]]; then
    echo "us"
    return
  fi
  if [[ "$lowered" == "eu" || "$lowered" == "europe" || "$lowered" == "emea" ]]; then
    echo "eu"
    return
  fi
  if [[ "$lowered" == "apac" || "$lowered" == "asia" || "$lowered" == "asia-pacific" || "$lowered" == "asia pacific" ]]; then
    echo "apac"
    return
  fi
  echo "global"
}

recommend_window() {
  local channel="$1"
  local region="$2"
  local normalized_channel="${channel:l}"
  local normalized_region
  normalized_region="$(normalize_audience_region "$region")"

  case "$normalized_region" in
    us)
      if [[ "$normalized_channel" == *"x"* || "$normalized_channel" == *"thread"* ]]; then
        echo "16:00-18:00 UTC (US morning-midday momentum)"
      elif [[ "$normalized_channel" == *"linkedin"* ]]; then
        echo "15:00-17:00 UTC (US business-hours overlap)"
      elif [[ "$normalized_channel" == *"reddit"* || "$normalized_channel" == *"hacker news"* || "$normalized_channel" == *"hn"* ]]; then
        echo "17:00-20:00 UTC (US discussion spike)"
      elif [[ "$normalized_channel" == *"slack"* || "$normalized_channel" == *"discord"* ]]; then
        echo "17:00-19:00 UTC (US community overlap)"
      else
        echo "16:00-18:00 UTC (US practical default)"
      fi
      ;;
    eu)
      if [[ "$normalized_channel" == *"x"* || "$normalized_channel" == *"thread"* ]]; then
        echo "08:00-10:00 UTC (EU morning momentum)"
      elif [[ "$normalized_channel" == *"linkedin"* ]]; then
        echo "07:00-09:00 UTC (EU workday kickoff)"
      elif [[ "$normalized_channel" == *"reddit"* || "$normalized_channel" == *"hacker news"* || "$normalized_channel" == *"hn"* ]]; then
        echo "09:00-11:00 UTC (EU discussion window)"
      elif [[ "$normalized_channel" == *"slack"* || "$normalized_channel" == *"discord"* ]]; then
        echo "08:00-10:00 UTC (EU team overlap)"
      else
        echo "08:00-10:00 UTC (EU practical default)"
      fi
      ;;
    apac)
      if [[ "$normalized_channel" == *"x"* || "$normalized_channel" == *"thread"* ]]; then
        echo "00:00-02:00 UTC (APAC morning momentum)"
      elif [[ "$normalized_channel" == *"linkedin"* ]]; then
        echo "23:00-01:00 UTC (APAC workday kickoff)"
      elif [[ "$normalized_channel" == *"reddit"* || "$normalized_channel" == *"hacker news"* || "$normalized_channel" == *"hn"* ]]; then
        echo "01:00-03:00 UTC (APAC discussion window)"
      elif [[ "$normalized_channel" == *"slack"* || "$normalized_channel" == *"discord"* ]]; then
        echo "00:00-02:00 UTC (APAC community overlap)"
      else
        echo "00:00-02:00 UTC (APAC practical default)"
      fi
      ;;
    *)
      if [[ "$normalized_channel" == *"x"* || "$normalized_channel" == *"thread"* ]]; then
        echo "15:00-17:00 UTC (US morning / EU afternoon)"
      elif [[ "$normalized_channel" == *"linkedin"* ]]; then
        echo "13:00-15:00 UTC (workday overlap for US + EU)"
      elif [[ "$normalized_channel" == *"reddit"* || "$normalized_channel" == *"hacker news"* || "$normalized_channel" == *"hn"* ]]; then
        echo "16:00-19:00 UTC (discussion-heavy global window)"
      elif [[ "$normalized_channel" == *"slack"* || "$normalized_channel" == *"discord"* ]]; then
        echo "14:00-16:00 UTC (team overlap window)"
      else
        echo "15:00-17:00 UTC (default practical publish window)"
      fi
      ;;
  esac
}

resolve_sequence_line() {
  local preferred_channel="$1"
  local primary="$2"
  local backup="$3"
  case "$preferred_channel" in
    primary)
      echo "1) Lead on $primary, 2) amplify on $backup after first engagement cluster."
      ;;
    backup)
      echo "1) Lead on $backup, 2) amplify on $primary after first engagement cluster."
      ;;
    *)
      echo "1) Lead on $primary, 2) run parallel reinforcement on $backup in the next slot."
      ;;
  esac
}

resolve_lead_channel() {
  local preferred_channel="$1"
  local primary="$2"
  local backup="$3"
  case "$preferred_channel" in
    backup)
      echo "$backup"
      ;;
    *)
      echo "$primary"
      ;;
  esac
}

normalized_primary_audience_region="$(normalize_audience_region "$primary_audience_region")"
normalized_backup_audience_region="$(normalize_audience_region "$backup_audience_region")"
primary_window="$(recommend_window "$primary_channel" "$normalized_primary_audience_region")"
backup_window="$(recommend_window "$backup_channel" "$normalized_backup_audience_region")"
normalized_channel_roi_preference="$(normalize_channel_preference "$channel_roi_preferred_channel")"
lead_channel="$(resolve_lead_channel "$normalized_channel_roi_preference" "$primary_channel" "$backup_channel")"
launch_sequence_line="$(resolve_sequence_line "$normalized_channel_roi_preference" "$primary_channel" "$backup_channel")"
generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

if [[ -z "$channel_roi_recommendation" ]]; then
  channel_roi_recommendation="Collect Monday reply + outreach outcomes before locking a single-channel lead."
fi

draft_preview=""
if [[ -n "$draft_path" && -f "$draft_path" ]]; then
  draft_preview=$(
    cat <<EOF
## Monday Draft Snapshot

\`\`\`markdown
$(sed -n '1,140p' "$draft_path")
\`\`\`
EOF
  )
fi

mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<!-- weekly-growth-monday-checkpoint -->

# Monday Publish Checkpoint: $week

Generated: $generated_on
Metric focus: $metric_focus
Strongest metric: $strongest_metric_label ($strongest_metric_value)

## Recommended Publish Windows

- Primary channel ($primary_channel, audience $normalized_primary_audience_region): $primary_window
- Backup channel ($backup_channel, audience $normalized_backup_audience_region): $backup_window
- Fallback publish window: +3 hours after primary slot if launch is delayed.

## ROI-Aware Launch Sequence

- Primary audience region: $normalized_primary_audience_region
- Backup audience region: $normalized_backup_audience_region
- Primary channel ROI score: $primary_channel_roi_score
- Backup channel ROI score: $backup_channel_roi_score
- Channel ROI preferred lead: $normalized_channel_roi_preference
- Lead channel for this Monday window: $lead_channel
- Recommended sequence: $launch_sequence_line
- ROI routing note: $channel_roi_recommendation

## Pre-Publish Gate

- [ ] Confirm one fresh proof asset is attached (Win Card or screenshot).
- [ ] Confirm one explicit command is visible in post body.
- [ ] Confirm CTA is concrete and practical (no hype-only wording).
- [ ] Confirm links point to current docs/repo.
- [ ] Confirm first response pass is scheduled inside 24 hours.

## Response Plan (First 24 Hours)

1. Reply to practical setup questions with exact command sequence.
2. Capture one objection that blocks adoption and route it to docs/workflow.
3. Ask one follow-up question to collect a reusable user story.
4. Save the strongest reply for next Monday hook.

$draft_preview
EOF

echo "Wrote Monday publish checkpoint: $output_path"
