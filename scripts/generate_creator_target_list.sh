#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a prioritized creator target list from weekly outreach + ROI signals.

Usage:
  zsh scripts/generate_creator_target_list.sh [options]

Options:
  --week <YYYY-Www>                     Week label (default: current ISO week)
  --metric-focus <text>                 Primary metric focus line
  --command <text>                      Command to spotlight (default: Copy Win Card)
  --primary-channel <text>              Primary channel label (default: X / Threads)
  --backup-channel <text>               Backup channel label (default: LinkedIn)
  --primary-channel-roi-score <value>   Primary channel ROI score (number or n/a)
  --backup-channel-roi-score <value>    Backup channel ROI score (number or n/a)
  --channel-roi-preferred-channel <text> Lead route (primary/backup/balanced)
  --channel-mix-recommendation <text>   Channel mix recommendation line
  --outreach-sent <value>               Previous outreach sent count
  --outreach-replies <value>            Previous outreach replies count
  --outreach-collabs <value>            Previous outreach collaborations count
  --outreach-cross-posts <value>        Previous outreach cross-post count
  --outreach-reply-rate <value>         Previous outreach reply rate (e.g. 37.5%)
  --outreach-collab-rate <value>        Previous outreach collaboration rate
  --outreach-cross-post-rate <value>    Previous outreach cross-post rate
  --outreach-replies-delta <value>      Replies delta vs baseline
  --outreach-collabs-delta <value>      Collaborations delta vs baseline
  --creator-signal-entries <value>      Creator signal entries captured from comments
  --creator-signal-high-fit <value>     Creator signal entries with fit score >=70
  --creator-signal-warm-intros <value>  Creator signal entries with warm intros
  --creator-signal-collab-ready <value> Creator signal entries marked collab-ready
  --creator-signal-top-segment <text>   Top segment from creator signal entries
  --creator-signal-top-handle <text>    Highest-priority creator handle from signal entries
  --creator-signal-enrichment-score <value> Enrichment score derived from creator signals
  --creator-signal-recommendation <text> Recommendation line from creator signal scoring
  --outreach-sprint-completion-rate <value> Outreach sprint completion rate from Monday checklist comments
  --outreach-sprint-tasks-completed <value> Completed outreach sprint checklist tasks
  --outreach-sprint-tasks-total <value> Total outreach sprint checklist tasks
  --outreach-sprint-creator-tasks-completed <value> Completed creator-focused outreach sprint tasks
  --outreach-sprint-guesting-tasks-completed <value> Completed guesting-focused outreach sprint tasks
  --outreach-sprint-recommendation <text> Recommendation derived from outreach sprint outcomes
  --cta <text>                          CTA line for DM scripts
  --out <path>                          Output markdown path
  -h, --help                            Show help

Example:
  zsh scripts/generate_creator_target_list.sh \
    --week 2026-W23 \
    --metric-focus "Win Card copies and installs" \
    --primary-channel-roi-score 78 \
    --backup-channel-roi-score 71 \
    --channel-roi-preferred-channel primary \
    --out .build/growth/2026-W23-creator-target-list.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
command_name="Copy Win Card"
primary_channel="X / Threads"
backup_channel="LinkedIn"
primary_channel_roi_score="n/a"
backup_channel_roi_score="n/a"
channel_roi_preferred_channel="balanced"
channel_mix_recommendation="Keep channel mix balanced until execution score improves."
outreach_sent="n/a"
outreach_replies="n/a"
outreach_collabs="n/a"
outreach_cross_posts="n/a"
outreach_reply_rate="n/a"
outreach_collab_rate="n/a"
outreach_cross_post_rate="n/a"
outreach_replies_delta="n/a"
outreach_collabs_delta="n/a"
creator_signal_entries="n/a"
creator_signal_high_fit="n/a"
creator_signal_warm_intros="n/a"
creator_signal_collab_ready="n/a"
creator_signal_top_segment="n/a"
creator_signal_top_handle="n/a"
creator_signal_enrichment_score="n/a"
creator_signal_recommendation="Capture creator signal comments in Monday checklist before Friday review."
outreach_sprint_completion_rate="n/a"
outreach_sprint_tasks_completed="n/a"
outreach_sprint_tasks_total="n/a"
outreach_sprint_creator_tasks_completed="n/a"
outreach_sprint_guesting_tasks_completed="n/a"
outreach_sprint_recommendation="Capture founder outreach sprint checklist updates in Monday checklist comments before Friday review."
cta_text="If useful, reply with your workflow niche and I will share a tailored 3-command sequence."
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
    --channel-mix-recommendation)
      channel_mix_recommendation="${2:-}"
      shift 2
      ;;
    --outreach-sent)
      outreach_sent="${2:-}"
      shift 2
      ;;
    --outreach-replies)
      outreach_replies="${2:-}"
      shift 2
      ;;
    --outreach-collabs)
      outreach_collabs="${2:-}"
      shift 2
      ;;
    --outreach-cross-posts)
      outreach_cross_posts="${2:-}"
      shift 2
      ;;
    --outreach-reply-rate)
      outreach_reply_rate="${2:-}"
      shift 2
      ;;
    --outreach-collab-rate)
      outreach_collab_rate="${2:-}"
      shift 2
      ;;
    --outreach-cross-post-rate)
      outreach_cross_post_rate="${2:-}"
      shift 2
      ;;
    --outreach-replies-delta)
      outreach_replies_delta="${2:-}"
      shift 2
      ;;
    --outreach-collabs-delta)
      outreach_collabs_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-entries)
      creator_signal_entries="${2:-}"
      shift 2
      ;;
    --creator-signal-high-fit)
      creator_signal_high_fit="${2:-}"
      shift 2
      ;;
    --creator-signal-warm-intros)
      creator_signal_warm_intros="${2:-}"
      shift 2
      ;;
    --creator-signal-collab-ready)
      creator_signal_collab_ready="${2:-}"
      shift 2
      ;;
    --creator-signal-top-segment)
      creator_signal_top_segment="${2:-}"
      shift 2
      ;;
    --creator-signal-top-handle)
      creator_signal_top_handle="${2:-}"
      shift 2
      ;;
    --creator-signal-enrichment-score)
      creator_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --creator-signal-recommendation)
      creator_signal_recommendation="${2:-}"
      shift 2
      ;;
    --outreach-sprint-completion-rate)
      outreach_sprint_completion_rate="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-completed)
      outreach_sprint_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-total)
      outreach_sprint_tasks_total="${2:-}"
      shift 2
      ;;
    --outreach-sprint-creator-tasks-completed)
      outreach_sprint_creator_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-guesting-tasks-completed)
      outreach_sprint_guesting_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-recommendation)
      outreach_sprint_recommendation="${2:-}"
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
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$output_path" ]]; then
  echo "Missing required option: --out <path>" >&2
  usage >&2
  exit 1
fi

parse_number() {
  local value="$1"
  local parsed
  parsed="$(echo "$value" | sed -nE 's/.*([+-]?[0-9]+([.][0-9]+)?).*/\1/p' | head -n 1)"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
  else
    echo "$parsed"
  fi
}

number_or_zero() {
  local value="$1"
  if [[ "$value" == "n/a" || -z "$value" ]]; then
    echo "0"
  else
    echo "$value"
  fi
}

clamp_score() {
  local score="$1"
  if (( score < 1 )); then
    echo 1
    return
  fi
  if (( score > 100 )); then
    echo 100
    return
  fi
  echo "$score"
}

primary_roi_number="$(parse_number "$primary_channel_roi_score")"
backup_roi_number="$(parse_number "$backup_channel_roi_score")"
replies_delta_number="$(parse_number "$outreach_replies_delta")"
collabs_delta_number="$(parse_number "$outreach_collabs_delta")"
creator_signal_entries_number="$(parse_number "$creator_signal_entries")"
creator_signal_high_fit_number="$(parse_number "$creator_signal_high_fit")"
creator_signal_warm_intros_number="$(parse_number "$creator_signal_warm_intros")"
creator_signal_collab_ready_number="$(parse_number "$creator_signal_collab_ready")"
creator_signal_enrichment_score_number="$(parse_number "$creator_signal_enrichment_score")"
outreach_sprint_completion_rate_number="$(parse_number "$outreach_sprint_completion_rate")"
outreach_sprint_tasks_completed_number="$(parse_number "$outreach_sprint_tasks_completed")"
outreach_sprint_tasks_total_number="$(parse_number "$outreach_sprint_tasks_total")"
outreach_sprint_creator_tasks_completed_number="$(parse_number "$outreach_sprint_creator_tasks_completed")"
outreach_sprint_guesting_tasks_completed_number="$(parse_number "$outreach_sprint_guesting_tasks_completed")"

primary_roi_base="$(number_or_zero "$primary_roi_number")"
backup_roi_base="$(number_or_zero "$backup_roi_number")"
replies_delta_base="$(number_or_zero "$replies_delta_number")"
collabs_delta_base="$(number_or_zero "$collabs_delta_number")"
creator_signal_entries_base="$(number_or_zero "$creator_signal_entries_number")"
creator_signal_high_fit_base="$(number_or_zero "$creator_signal_high_fit_number")"
creator_signal_warm_intros_base="$(number_or_zero "$creator_signal_warm_intros_number")"
creator_signal_collab_ready_base="$(number_or_zero "$creator_signal_collab_ready_number")"
creator_signal_enrichment_score_base="$(number_or_zero "$creator_signal_enrichment_score_number")"
outreach_sprint_completion_rate_base="$(number_or_zero "$outreach_sprint_completion_rate_number")"
outreach_sprint_tasks_completed_base="$(number_or_zero "$outreach_sprint_tasks_completed_number")"
outreach_sprint_tasks_total_base="$(number_or_zero "$outreach_sprint_tasks_total_number")"
outreach_sprint_creator_tasks_completed_base="$(number_or_zero "$outreach_sprint_creator_tasks_completed_number")"
outreach_sprint_guesting_tasks_completed_base="$(number_or_zero "$outreach_sprint_guesting_tasks_completed_number")"

signal_segment_normalized="$(echo "$creator_signal_top_segment" | tr '[:upper:]' '[:lower:]')"
segment_primary_bias=0
segment_backup_bias=0
if [[ "$signal_segment_normalized" == *"workflow"* || "$signal_segment_normalized" == *"build-in-public"* || "$signal_segment_normalized" == *"podcast"* || "$signal_segment_normalized" == *"video"* ]]; then
  segment_primary_bias=3
elif [[ "$signal_segment_normalized" == *"newsletter"* || "$signal_segment_normalized" == *"analyst"* || "$signal_segment_normalized" == *"community"* ]]; then
  segment_backup_bias=3
fi

signal_bonus_raw="$(awk -v score="$creator_signal_enrichment_score_base" -v high="$creator_signal_high_fit_base" -v warm="$creator_signal_warm_intros_base" -v collab="$creator_signal_collab_ready_base" -v entries="$creator_signal_entries_base" 'BEGIN {
  value = (score * 0.20) + (high * 2) + (warm * 3) + (collab * 4) + entries;
  printf "%.0f", value;
}')"
signal_bonus="$signal_bonus_raw"
if (( signal_bonus < 0 )); then
  signal_bonus=0
fi
if (( signal_bonus > 20 )); then
  signal_bonus=20
fi

outreach_sprint_completion_bonus_raw="$(awk -v completion="$outreach_sprint_completion_rate_base" -v completed="$outreach_sprint_tasks_completed_base" 'BEGIN {
  value = (completion * 0.18) + (completed * 1.5);
  printf "%.0f", value;
}')"
outreach_sprint_completion_bonus="$outreach_sprint_completion_bonus_raw"
if (( outreach_sprint_completion_bonus < 0 )); then
  outreach_sprint_completion_bonus=0
fi
if (( outreach_sprint_completion_bonus > 18 )); then
  outreach_sprint_completion_bonus=18
fi

creator_outcome_bonus_raw="$(awk -v creator="$outreach_sprint_creator_tasks_completed_base" -v guesting="$outreach_sprint_guesting_tasks_completed_base" 'BEGIN {
  value = (creator * 3) - (guesting * 1.5);
  printf "%.0f", value;
}')"
creator_outcome_bonus="$creator_outcome_bonus_raw"
if (( creator_outcome_bonus < -8 )); then
  creator_outcome_bonus=-8
fi
if (( creator_outcome_bonus > 16 )); then
  creator_outcome_bonus=16
fi

creator_lane_bias=0
guesting_lane_bias=0
if (( outreach_sprint_creator_tasks_completed_base > outreach_sprint_guesting_tasks_completed_base )); then
  creator_lane_bias=4
elif (( outreach_sprint_guesting_tasks_completed_base > outreach_sprint_creator_tasks_completed_base )); then
  guesting_lane_bias=4
fi

lead_route="$(echo "$channel_roi_preferred_channel" | tr '[:upper:]' '[:lower:]')"
primary_lead_bonus=0
backup_lead_bonus=0
if [[ "$lead_route" == "primary" ]]; then
  primary_lead_bonus=8
elif [[ "$lead_route" == "backup" ]]; then
  backup_lead_bonus=8
else
  primary_lead_bonus=4
  backup_lead_bonus=4
fi

primary_score_raw="$(awk -v roi="$primary_roi_base" -v rb="$replies_delta_base" -v cb="$collabs_delta_base" -v bonus="$primary_lead_bonus" -v signal="$signal_bonus" -v segment="$segment_primary_bias" -v sprint_bonus="$outreach_sprint_completion_bonus" -v creator_bonus="$creator_outcome_bonus" -v lane_bias="$creator_lane_bias" 'BEGIN {
  value = roi + (rb * 2) + (cb * 3) + bonus + signal + segment + sprint_bonus + creator_bonus + lane_bias;
  printf "%.0f", value;
}')"
backup_score_raw="$(awk -v roi="$backup_roi_base" -v rb="$replies_delta_base" -v cb="$collabs_delta_base" -v bonus="$backup_lead_bonus" -v signal="$signal_bonus" -v segment="$segment_backup_bias" -v sprint_bonus="$outreach_sprint_completion_bonus" -v creator_bonus="$creator_outcome_bonus" -v lane_bias="$guesting_lane_bias" 'BEGIN {
  value = roi + (rb * 2) + (cb * 3) + bonus + signal + segment + sprint_bonus - creator_bonus + lane_bias;
  printf "%.0f", value;
}')"

primary_score="$(clamp_score "$primary_score_raw")"
backup_score="$(clamp_score "$backup_score_raw")"

overall_momentum_score_raw="$(awk -v p="$primary_score" -v b="$backup_score" -v enrich="$creator_signal_enrichment_score_base" 'BEGIN {
  value = ((p + b) / 2.0) + (enrich * 0.15);
  printf "%.0f", value;
}')"
overall_momentum_score="$(clamp_score "$overall_momentum_score_raw")"

rank1_segment="Build-in-public operator creators"
if [[ -n "$creator_signal_top_segment" && "$creator_signal_top_segment" != "n/a" ]]; then
  rank1_segment="$creator_signal_top_segment"
fi

rank1_hook="Show one KPI delta + exact 3-command path"
if [[ -n "$creator_signal_top_handle" && "$creator_signal_top_handle" != "n/a" ]]; then
  rank1_hook="Reference ${creator_signal_top_handle} signal and share exact 3-command path"
fi

day0_focus_line="Send top-5 targets from rank 1-2."
if [[ -n "$creator_signal_top_handle" && "$creator_signal_top_handle" != "n/a" ]]; then
  day0_focus_line="Send top-5 targets from rank 1-2 and prioritize profiles similar to ${creator_signal_top_handle}."
fi

if (( outreach_sprint_creator_tasks_completed_base > outreach_sprint_guesting_tasks_completed_base )) && (( outreach_sprint_completion_rate_base >= 75 )); then
  day0_focus_line="Send creator-first wave from rank 1-3 and stage guesting follow-ups for Day 2."
fi

if [[ -n "$outreach_sprint_recommendation" && "$outreach_sprint_recommendation" != "n/a" ]]; then
  rank1_hook="${rank1_hook}; ${outreach_sprint_recommendation}"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- weekly-growth-creator-target-list -->
# Creator Target List: ${week}

Generated: ${generated_on}

## Prioritization Snapshot

- Metric focus: ${metric_focus}
- Command spotlight: \`${command_name}\`
- Primary channel ROI score: ${primary_channel_roi_score}
- Backup channel ROI score: ${backup_channel_roi_score}
- Lead route: ${channel_roi_preferred_channel}
- Channel mix recommendation: ${channel_mix_recommendation}
- Outreach baseline: sent ${outreach_sent}, replies ${outreach_replies}, collabs ${outreach_collabs}, cross-posts ${outreach_cross_posts}
- Outreach rates: reply ${outreach_reply_rate}, collab ${outreach_collab_rate}, cross-post ${outreach_cross_post_rate}
- Outreach deltas: replies ${outreach_replies_delta}, collabs ${outreach_collabs_delta}
- Creator signal entries reviewed: ${creator_signal_entries}
- High-fit creator signals: ${creator_signal_high_fit}
- Warm intro signals: ${creator_signal_warm_intros}
- Collab-ready signals: ${creator_signal_collab_ready}
- Top signal segment: ${creator_signal_top_segment}
- Top signal handle: ${creator_signal_top_handle}
- Creator enrichment score: ${creator_signal_enrichment_score}
- Creator signal recommendation: ${creator_signal_recommendation}
- Outreach sprint completion rate: ${outreach_sprint_completion_rate}
- Outreach sprint checklist: ${outreach_sprint_tasks_completed}/${outreach_sprint_tasks_total}
- Outreach sprint creator/guesting completed: ${outreach_sprint_creator_tasks_completed}/${outreach_sprint_guesting_tasks_completed}
- Outreach sprint recommendation: ${outreach_sprint_recommendation}
- Creator signal scoring bonus: +${signal_bonus}
- Outreach sprint execution bonus: +${outreach_sprint_completion_bonus}
- Momentum score: ${overall_momentum_score}/100

## Creator Signal Overlay

- Lead segment for this week: ${creator_signal_top_segment}
- Priority handle to personalize first touch: ${creator_signal_top_handle}
- Enrichment recommendation: ${creator_signal_recommendation}
- Outreach sprint lane feedback: ${outreach_sprint_recommendation}

## Ranked Creator Targets

| Rank | Segment | Lead channel | Priority score | Hook | Ask | Next action |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | ${rank1_segment} | ${primary_channel} | ${primary_score} | ${rank1_hook} | 60-second workflow quote repost | Send 3 personalized DMs in 24h |
| 2 | Workflow/tutorial creators | ${primary_channel} | $(( primary_score > 6 ? primary_score - 6 : primary_score )) | Before/after flow with reproducible steps | Co-post short walkthrough | Offer script + asset pack |
| 3 | Newsletter + analyst creators | ${backup_channel} | ${backup_score} | Weekly metrics narrative + operational insight | Include in weekly roundup | Send concise 5-bullet pitch |
| 4 | Community moderators | ${backup_channel} | $(( backup_score > 5 ? backup_score - 5 : backup_score )) | Practical no-hype command flow for members | Approved post slot / AMA thread | Propose one-value community post |
| 5 | Podcast/video hosts | ${primary_channel} | $(( overall_momentum_score > 4 ? overall_momentum_score - 4 : overall_momentum_score )) | Founder operating cadence with measurable outcomes | 20-minute founder story segment | Send interview pitch + talking points |

## Contact Sprint Plan

1. Day 0: ${day0_focus_line}
2. Day 1: Follow up with non-responders from rank 1.
3. Day 2: Send rank 3 newsletter pitches with one metric proof.
4. Day 3: Push community moderator asks from rank 4.
5. Day 4: Send podcast/video angle from rank 5.
6. Day 5: Resurface best-performing hook with updated metric.
7. Day 7: Refresh ranking using latest reply + collab outcomes.

## DM Variants

### Variant A (proof-first)

\`\`\`text
Quick founder note for ${week}:
- Metric focus: ${metric_focus}
- Working command path: Read Selected Text -> Ask Anything -> ${command_name}
- Weekly momentum score: ${overall_momentum_score}/100

Would you be open to a short repost/collab if I share the exact setup and screenshot?
${cta_text}
\`\`\`

### Variant B (workflow-first)

\`\`\`text
I have a practical workflow your audience can copy in minutes:
1) Read Selected Text
2) Ask Anything
3) ${command_name}

It maps directly to this week’s focus: ${metric_focus}.
Happy to send a concise script + proof asset for your format.
\`\`\`

### Variant C (distribution-first)

\`\`\`text
We are running a weekly distribution loop with lead route "${channel_roi_preferred_channel}".
Current channel context:
- ${primary_channel}: ROI ${primary_channel_roi_score}
- ${backup_channel}: ROI ${backup_channel_roi_score}

If useful, we can run a cross-post test and share the postmortem publicly.
${cta_text}
\`\`\`

## Tracking Checklist

- [ ] Sent at least 5 ranked outreach messages
- [ ] Logged replies by target segment
- [ ] Logged collaborations and cross-posts
- [ ] Promoted best-performing DM variant into next week default
- [ ] Updated channel score inputs from latest outcomes
- [ ] Updated founder outreach sprint checklist comment with creator outcomes
EOF

echo "Wrote creator target list: $output_path"
