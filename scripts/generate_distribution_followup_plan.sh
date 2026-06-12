#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a 7-day distribution follow-up plan from weekly growth context.

Usage:
  zsh scripts/generate_distribution_followup_plan.sh [options]

Options:
  --week <YYYY-Www>                Sprint week label (default: current ISO week)
  --metric-focus <text>            Metric focus line (default: Win Card copies and reply quality)
  --strongest-metric-label <text>  Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>  Strongest metric value (default: n/a)
  --command <text>                 Suggested command anchor (default: Copy Win Card)
  --primary-channel <text>         Primary channel label (default: X / Threads)
  --backup-channel <text>          Backup channel label (default: LinkedIn)
  --primary-audience-region <text> Primary audience region (global/us/eu/apac, default: global)
  --backup-audience-region <text>  Backup audience region (global/us/eu/apac, default: global)
  --primary-channel-roi-score <value> ROI score for primary channel (default: n/a)
  --backup-channel-roi-score <value> ROI score for backup channel (default: n/a)
  --channel-roi-preferred-channel <primary|backup|balanced> Preferred lead route (default: balanced)
  --channel-roi-recommendation <text> ROI-based routing recommendation (optional)
  --channel-mix-recommendation <text> Channel mix recommendation (optional)
  --reply-goal <number>            First-24h practical reply goal (default: 12)
  --outreach-goal <number>         Seven-day creator/community follow-up goal (default: 5)
  --out <path>                     Output markdown path (required)
  -h, --help                       Show this help

Example:
  zsh scripts/generate_distribution_followup_plan.sh \
    --week "$(date +%Y-W%V)" \
    --primary-channel "X / Threads" \
    --backup-channel "LinkedIn" \
    --primary-audience-region "us" \
    --backup-audience-region "eu" \
    --channel-roi-preferred-channel "primary" \
    --out .build/growth/$(date +%Y-W%V)-distribution-plan.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
command_name="Copy Win Card"
primary_channel="X / Threads"
backup_channel="LinkedIn"
primary_audience_region="global"
backup_audience_region="global"
primary_channel_roi_score="n/a"
backup_channel_roi_score="n/a"
channel_roi_preferred_channel="balanced"
channel_roi_recommendation=""
channel_mix_recommendation=""
reply_goal="12"
outreach_goal="5"
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
    --channel-mix-recommendation)
      channel_mix_recommendation="${2:-}"
      shift 2
      ;;
    --reply-goal)
      reply_goal="${2:-}"
      shift 2
      ;;
    --outreach-goal)
      outreach_goal="${2:-}"
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

if [[ -z "$command_name" ]]; then
  if [[ "${strongest_metric_label:l}" == *"recap"* ]]; then
    command_name="Copy Win Recap"
  else
    command_name="Copy Win Card"
  fi
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

normalized_primary_region="$(normalize_audience_region "$primary_audience_region")"
normalized_backup_region="$(normalize_audience_region "$backup_audience_region")"
normalized_channel_preference="$(normalize_channel_preference "$channel_roi_preferred_channel")"

lead_channel="$primary_channel"
lead_region="$normalized_primary_region"
support_channel="$backup_channel"
support_region="$normalized_backup_region"
if [[ "$normalized_channel_preference" == "backup" ]]; then
  lead_channel="$backup_channel"
  lead_region="$normalized_backup_region"
  support_channel="$primary_channel"
  support_region="$normalized_primary_region"
fi

lead_window="$(recommend_window "$lead_channel" "$lead_region")"
support_window="$(recommend_window "$support_channel" "$support_region")"

if [[ -z "$channel_roi_recommendation" ]]; then
  channel_roi_recommendation="Collect Monday reply + outreach outcomes before locking a single-channel lead."
fi

if [[ -z "$channel_mix_recommendation" ]]; then
  case "$normalized_channel_preference" in
    primary)
      channel_mix_recommendation="Use a primary-led 60/40 mix until Monday reply quality stabilizes."
      ;;
    backup)
      channel_mix_recommendation="Use a backup-led 60/40 mix until Monday reply quality stabilizes."
      ;;
    *)
      channel_mix_recommendation="Keep a balanced 50/50 mix and choose lead from early Monday replies."
      ;;
  esac
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<!-- weekly-growth-distribution-plan -->

# 7-Day Distribution Follow-Up Plan: $week

Generated: $generated_on
Metric focus: $metric_focus
Strongest metric: $strongest_metric_label ($strongest_metric_value)

## Routing Snapshot

- Lead channel this week: $lead_channel (audience $lead_region, window $lead_window)
- Support channel this week: $support_channel (audience $support_region, window $support_window)
- Primary channel ROI score: $primary_channel_roi_score
- Backup channel ROI score: $backup_channel_roi_score
- Channel ROI preferred lead: $normalized_channel_preference
- ROI routing note: $channel_roi_recommendation
- Channel mix recommendation: $channel_mix_recommendation
- First-24-hour practical reply goal: $reply_goal
- Seven-day outreach follow-up goal: $outreach_goal

## Day-by-Day Distribution Plan

| Day | Objective | Channel | Suggested window (UTC) | Deliverable | Success check |
| --- | --- | --- | --- | --- | --- |
| Day 0 | Launch proof-first post + initial replies | $lead_channel | $lead_window | Publish one proof asset + command-led caption | Post shipped + first 3 practical replies sent |
| Day 1 | Reinforce with workflow-first follow-up | $support_channel | $support_window | Publish short variant + cross-link to Day 0 proof | Combined replies reach half of reply goal |
| Day 2 | Creator/community follow-up wave 1 | Creator DMs + communities | $support_window | Send top-priority outreach batch and one community comment | At least 2 meaningful conversations opened |
| Day 3 | Objection-handler repost | $lead_channel | $lead_window | Share objection-response variant with one caveat | Objection count logged + response quality maintained |
| Day 4 | Creator/community follow-up wave 2 | Creator DMs + communities | $lead_window | Send second follow-up batch using strongest proof asset | Outreach replies move toward goal |
| Day 5 | Docs and workflow conversion | Repo/docs + support channel | 12:00-15:00 UTC | Convert top question into one docs/workflow update | One reusable docs update shipped |
| Day 6 | Proof recap + collaboration nudge | $support_channel | $support_window | Share week recap and direct collaboration CTA | One collaboration ask sent with proof context |
| Day 7 | Friday review handoff | Weekly review issue | 12:00-14:00 UTC | Log reply/outreach outcomes and best hooks | Monday draft + routing notes ready for next cycle |

## Copy-Ready Follow-Up Scripts

### Reply Script (practical question)

\`\`\`text
Great question — exact path:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

This week’s strongest signal: $strongest_metric_label ($strongest_metric_value).
If you share your workflow, I can suggest a tighter 3-command route.
\`\`\`

### Outreach Follow-Up Script

\`\`\`text
Quick follow-up with a concrete result:
- Focus: $metric_focus
- Strongest proof: $strongest_metric_label ($strongest_metric_value)
- Repeatable command anchor: $command_name

If useful, I can send the exact 60-second workflow and the asset we used publicly.
\`\`\`

## Execution Checklist

- [ ] Lead-channel post shipped in planned window.
- [ ] Support-channel follow-up shipped within 24 hours.
- [ ] At least $reply_goal practical replies handled with command-level guidance.
- [ ] At least $outreach_goal creator/community follow-ups sent this week.
- [ ] Top objection converted into one docs/workflow improvement.
- [ ] Friday review updated with reply/outreach outcomes for next-week routing.
EOF

echo "Wrote distribution follow-up plan: $output_path"
