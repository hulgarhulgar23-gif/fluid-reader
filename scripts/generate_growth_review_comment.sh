#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly growth review comment markdown file.

Usage:
  zsh scripts/generate_growth_review_comment.sh [options]

Options:
  --week <YYYY-Www>              Sprint week label (default: current ISO week)
  --metric-focus <text>          Metric focus line for this sprint
  --win-card <value>             Win Card copies value
  --win-card-delta <value>       WoW delta for Win Card copies
  --win-recap <value>            Win Recap copies value
  --win-recap-delta <value>      WoW delta for Win Recap copies
  --posts <value>                Public posts shipped value
  --posts-delta <value>          WoW delta for public posts shipped
  --stories <value>              User-generated stories value
  --stories-delta <value>        WoW delta for user-generated stories
  --installs <value>             Inbound installs/trials value
  --installs-delta <value>       WoW delta for inbound installs/trials
  --primary-channel <text>       Primary distribution channel label
  --backup-channel <text>        Backup distribution channel label
  --monday-source-week <YYYY-Www> Source week for previous Monday checklist
  --monday-post-status <text>    Previous Monday publish status (posted/not posted/in progress)
  --reply-pack-replies <value>   Replies sent in first 24-hour window
  --reply-pack-replies-delta <value> WoW delta for first-24h replies
  --reply-pack-objections <value> Objections captured in first 24-hour window
  --reply-pack-objections-delta <value> WoW delta for objections captured
  --reply-pack-doc-updates <value> Docs/workflow updates from Monday replies
  --reply-pack-doc-updates-delta <value> WoW delta for docs/workflow updates
  --outreach-sent <value>        Creator outreach messages sent in Monday window
  --outreach-sent-delta <value>  WoW delta for creator outreach sent
  --outreach-replies <value>     Creator replies from outreach
  --outreach-replies-delta <value> WoW delta for creator replies
  --outreach-collabs <value>     Creator collaborations confirmed
  --outreach-collabs-delta <value> WoW delta for creator collaborations
  --outreach-cross-posts <value> Community cross-posts secured
  --outreach-cross-posts-delta <value> WoW delta for community cross-posts
  --outreach-reply-rate <value>  Creator outreach reply rate (percent)
  --outreach-reply-rate-delta <value> WoW delta for reply rate in percentage points
  --outreach-collab-rate <value> Creator collaboration rate (percent)
  --outreach-collab-rate-delta <value> WoW delta for collaboration rate in percentage points
  --outreach-cross-post-rate <value> Community cross-post rate (percent)
  --outreach-cross-post-rate-delta <value> WoW delta for cross-post rate in percentage points
  --creator-signal-entries <value> Creator signal entries parsed from checklist comments
  --creator-signal-entries-delta <value> WoW delta for creator signal entries
  --creator-signal-high-fit <value> Creator signal entries with fit score >=70
  --creator-signal-high-fit-delta <value> WoW delta for high-fit creator signal entries
  --creator-signal-warm-intros <value> Creator signal entries with warm intros
  --creator-signal-warm-intros-delta <value> WoW delta for warm-intro creator signal entries
  --creator-signal-collab-ready <value> Creator signal entries marked collab-ready
  --creator-signal-collab-ready-delta <value> WoW delta for collab-ready creator signal entries
  --creator-signal-top-segment <text> Top-performing creator segment from comment signals
  --creator-signal-top-handle <text> Highest-priority creator handle from comment signals
  --creator-signal-enrichment-score <value> Creator signal enrichment score (0-100)
  --creator-signal-enrichment-score-delta <value> WoW delta for creator signal enrichment score
  --creator-signal-recommendation <text> Recommendation line from creator signal scoring
  --guesting-signal-entries <value> Founder guesting signal entries parsed from checklist comments
  --guesting-signal-entries-delta <value> WoW delta for founder guesting signal entries
  --guesting-signal-replied <value> Founder guesting signal entries in replied/booked/published stage
  --guesting-signal-replied-delta <value> WoW delta for replied guesting signal entries
  --guesting-signal-booked <value> Founder guesting signal entries in booked/published stage
  --guesting-signal-booked-delta <value> WoW delta for booked guesting signal entries
  --guesting-signal-published <value> Founder guesting signal entries in published stage
  --guesting-signal-published-delta <value> WoW delta for published guesting signal entries
  --guesting-signal-top-format <text> Top-performing guesting format from comment signals
  --guesting-signal-top-target <text> Highest-priority guesting target from comment signals
  --guesting-signal-enrichment-score <value> Founder guesting enrichment score (0-100)
  --guesting-signal-enrichment-score-delta <value> WoW delta for founder guesting enrichment score
  --guesting-signal-recommendation <text> Recommendation line from founder guesting signal scoring
  --narrative-route-winner <text> Winner route from founder narrative lab priority route signal
  --narrative-route-winner-delta <value> WoW change label for founder narrative route winner
  --narrative-route-trend <text> Narrative route trendline versus baseline week
  --narrative-fame-velocity-score <value> Founder narrative fame velocity score (0-100)
  --narrative-fame-velocity-score-delta <value> WoW delta for founder narrative fame velocity score
  --narrative-launch-posture <text> Launch posture from founder narrative lab dashboard
  --narrative-next-standup-action <text> Next standup action from founder narrative lab dashboard
  --narrative-route-recommendation <text> Recommendation line from founder narrative route scoring
  --narrative-route-mode <text> Founder narrative route control mode from narrative lab controls
  --narrative-route-alignment-target <text> Founder narrative route alignment target from narrative lab controls
  --narrative-route-lane-status <text> Founder narrative route lane status from narrative lab snapshot
  --narrative-route-guardrail <text> Founder narrative route guardrail from narrative lab controls
  --narrative-route-control-recommendation <text> Founder narrative route control recommendation from narrative lab controls
  --narrative-distribution-strategy <text> Founder narrative distribution strategy from 7-day distribution calendar
  --narrative-distribution-day0-lead <text> Founder narrative Day 0 lead lane from distribution calendar
  --narrative-distribution-day0-support <text> Founder narrative Day 0 support lane from distribution calendar
  --narrative-distribution-recommendation <text> Founder narrative distribution recommendation from calendar signals
  --narrative-distribution-first-48h-plan <text> Founder narrative first-48h execution plan from calendar signals
  --outreach-sprint-comment-entries <value> Outreach sprint comments detected in Monday checklist
  --outreach-sprint-comment-entries-delta <value> WoW delta for outreach sprint comment entries
  --outreach-sprint-tasks-completed <value> Completed outreach sprint checklist tasks
  --outreach-sprint-tasks-completed-delta <value> WoW delta for completed outreach sprint tasks
  --outreach-sprint-tasks-total <value> Total outreach sprint checklist tasks
  --outreach-sprint-completion-rate <value> Outreach sprint checklist completion rate (percent)
  --outreach-sprint-completion-rate-delta <value> WoW delta for outreach sprint completion rate (pp)
  --outreach-sprint-creator-tasks-completed <value> Completed creator-focused outreach sprint tasks
  --outreach-sprint-creator-tasks-completed-delta <value> WoW delta for creator-focused tasks completed
  --outreach-sprint-guesting-tasks-completed <value> Completed guesting-focused outreach sprint tasks
  --outreach-sprint-guesting-tasks-completed-delta <value> WoW delta for guesting-focused tasks completed
  --outreach-sprint-owner-defaults-tasks-completed <value> Completed owner-default tasks in lane defaults block
  --outreach-sprint-owner-defaults-tasks-completed-delta <value> WoW delta for completed owner-default tasks
  --outreach-sprint-owner-defaults-tasks-total <value> Total owner-default tasks in lane defaults block
  --outreach-sprint-owner-defaults-completion-rate <value> Owner-default completion rate (percent)
  --outreach-sprint-owner-defaults-completion-rate-delta <value> WoW delta for owner-default completion rate (pp)
  --outreach-sprint-owner-default-creator-completed <value> Creator owner-default task completion (1/0 or yes/no)
  --outreach-sprint-owner-default-creator-completed-delta <value> WoW delta for creator owner-default completion
  --outreach-sprint-owner-default-guesting-completed <value> Guesting owner-default task completion (1/0 or yes/no)
  --outreach-sprint-owner-default-guesting-completed-delta <value> WoW delta for guesting owner-default completion
  --outreach-sprint-owner-default-distribution-completed <value> Distribution owner-default task completion (1/0 or yes/no)
  --outreach-sprint-owner-default-distribution-completed-delta <value> WoW delta for distribution owner-default completion
  --outreach-sprint-owner-default-ops-completed <value> Ops owner-default task completion (1/0 or yes/no)
  --outreach-sprint-owner-default-ops-completed-delta <value> WoW delta for ops owner-default completion
  --outreach-sprint-variant-promoted <text> Whether winning outreach variant was promoted (yes/no)
  --outreach-sprint-outcomes-logged <text> Whether outreach outcomes were logged (yes/no)
  --outreach-sprint-preferred-lane <text> Preferred lane from outcomes (creator/guesting/balanced)
  --outreach-sprint-recommendation <text> Recommendation from outreach sprint outcome scoring
  --primary-top-variant <A/B/C>  Top-performing variant in primary channel
  --backup-top-variant <A/B/C>   Top-performing variant in backup channel
  --variant-recommendation <text> Recommended variant plan for next week
  --outreach-recommendation <text> Recommended outreach plan for next week
  --primary-variant-win-trend <text> Consecutive-win trend for primary channel variant
  --backup-variant-win-trend <text> Consecutive-win trend for backup channel variant
  --primary-channel-roi-score <value> ROI score for primary channel routing
  --backup-channel-roi-score <value> ROI score for backup channel routing
  --channel-roi-recommendation <text> ROI-based recommendation for channel routing
  --distribution-days-completed <value> Completed distribution follow-up days (for example 5/8)
  --distribution-days-completed-delta <value> WoW delta for completed distribution days
  --distribution-completion-score <value> Distribution follow-up completion score (percent)
  --distribution-completion-score-delta <value> WoW delta for distribution completion score (pp)
  --channel-mix-recommendation <text> Recommended primary/backup mix for next week
  --target-win-card <number>     Weekly target for Win Card copies (default: 25)
  --target-win-recap <number>    Weekly target for Win Recap copies (default: 20)
  --target-posts <number>        Weekly target for public posts shipped (default: 3)
  --target-stories <number>      Weekly target for user-generated stories (default: 2)
  --target-installs <number>     Weekly target for inbound installs/trials (default: 5)
  --out <path>                   Output markdown path (required)
  -h, --help                     Show this help

Example:
  zsh scripts/generate_growth_review_comment.sh \
    --week "$(date +%Y-W%V)" \
    --metric-focus "Win Card copies and installs" \
    --win-card "42" \
    --win-card-delta "+7" \
    --win-recap "31" \
    --posts "4" \
    --stories "3" \
    --installs "12" \
    --primary-channel "X / Threads" \
    --backup-channel "LinkedIn" \
    --monday-source-week "2026-W22" \
    --monday-post-status "posted" \
    --reply-pack-replies "14" \
    --reply-pack-replies-delta "+3" \
    --reply-pack-objections "3" \
    --reply-pack-objections-delta "+1" \
    --outreach-sent "8" \
    --outreach-replies "3" \
    --outreach-collabs "1" \
    --outreach-cross-posts "1" \
    --primary-top-variant "A" \
    --backup-top-variant "B" \
    --out .build/growth/$(date +%Y-W%V)-review.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
win_card=""
win_card_delta=""
win_recap=""
win_recap_delta=""
posts=""
posts_delta=""
stories=""
stories_delta=""
installs=""
installs_delta=""
primary_channel="X / Threads"
backup_channel="LinkedIn"
monday_source_week=""
monday_post_status="not posted"
reply_pack_replies="n/a"
reply_pack_replies_delta="n/a"
reply_pack_objections="n/a"
reply_pack_objections_delta="n/a"
reply_pack_doc_updates="n/a"
reply_pack_doc_updates_delta="n/a"
outreach_sent="n/a"
outreach_sent_delta="n/a"
outreach_replies="n/a"
outreach_replies_delta="n/a"
outreach_collabs="n/a"
outreach_collabs_delta="n/a"
outreach_cross_posts="n/a"
outreach_cross_posts_delta="n/a"
outreach_reply_rate="n/a"
outreach_reply_rate_delta="n/a"
outreach_collab_rate="n/a"
outreach_collab_rate_delta="n/a"
outreach_cross_post_rate="n/a"
outreach_cross_post_rate_delta="n/a"
creator_signal_entries="n/a"
creator_signal_entries_delta="n/a"
creator_signal_high_fit="n/a"
creator_signal_high_fit_delta="n/a"
creator_signal_warm_intros="n/a"
creator_signal_warm_intros_delta="n/a"
creator_signal_collab_ready="n/a"
creator_signal_collab_ready_delta="n/a"
creator_signal_top_segment="n/a"
creator_signal_top_handle="n/a"
creator_signal_enrichment_score="n/a"
creator_signal_enrichment_score_delta="n/a"
creator_signal_recommendation=""
guesting_signal_entries="n/a"
guesting_signal_entries_delta="n/a"
guesting_signal_replied="n/a"
guesting_signal_replied_delta="n/a"
guesting_signal_booked="n/a"
guesting_signal_booked_delta="n/a"
guesting_signal_published="n/a"
guesting_signal_published_delta="n/a"
guesting_signal_top_format="n/a"
guesting_signal_top_target="n/a"
guesting_signal_enrichment_score="n/a"
guesting_signal_enrichment_score_delta="n/a"
guesting_signal_recommendation=""
narrative_route_winner="n/a"
narrative_route_winner_delta="n/a"
narrative_route_trend="n/a"
narrative_fame_velocity_score="n/a"
narrative_fame_velocity_score_delta="n/a"
narrative_launch_posture="n/a"
narrative_next_standup_action="n/a"
narrative_route_recommendation=""
narrative_route_mode="n/a"
narrative_route_alignment_target="n/a"
narrative_route_lane_status="n/a"
narrative_route_guardrail="n/a"
narrative_route_control_recommendation=""
narrative_distribution_strategy="n/a"
narrative_distribution_day0_lead="n/a"
narrative_distribution_day0_support="n/a"
narrative_distribution_recommendation=""
narrative_distribution_first_48h_plan=""
outreach_sprint_comment_entries="n/a"
outreach_sprint_comment_entries_delta="n/a"
outreach_sprint_tasks_completed="n/a"
outreach_sprint_tasks_completed_delta="n/a"
outreach_sprint_tasks_total="n/a"
outreach_sprint_completion_rate="n/a"
outreach_sprint_completion_rate_delta="n/a"
outreach_sprint_creator_tasks_completed="n/a"
outreach_sprint_creator_tasks_completed_delta="n/a"
outreach_sprint_guesting_tasks_completed="n/a"
outreach_sprint_guesting_tasks_completed_delta="n/a"
outreach_sprint_owner_defaults_tasks_completed="n/a"
outreach_sprint_owner_defaults_tasks_completed_delta="n/a"
outreach_sprint_owner_defaults_tasks_total="n/a"
outreach_sprint_owner_defaults_completion_rate="n/a"
outreach_sprint_owner_defaults_completion_rate_delta="n/a"
outreach_sprint_owner_default_creator_completed="n/a"
outreach_sprint_owner_default_creator_completed_delta="n/a"
outreach_sprint_owner_default_guesting_completed="n/a"
outreach_sprint_owner_default_guesting_completed_delta="n/a"
outreach_sprint_owner_default_distribution_completed="n/a"
outreach_sprint_owner_default_distribution_completed_delta="n/a"
outreach_sprint_owner_default_ops_completed="n/a"
outreach_sprint_owner_default_ops_completed_delta="n/a"
outreach_sprint_variant_promoted="n/a"
outreach_sprint_outcomes_logged="n/a"
outreach_sprint_preferred_lane="balanced"
outreach_sprint_recommendation=""
primary_top_variant="n/a"
backup_top_variant="n/a"
variant_recommendation=""
outreach_recommendation=""
primary_variant_win_trend="n/a"
backup_variant_win_trend="n/a"
primary_channel_roi_score="n/a"
backup_channel_roi_score="n/a"
channel_roi_recommendation=""
distribution_days_completed="n/a"
distribution_days_completed_delta="n/a"
distribution_completion_score="n/a"
distribution_completion_score_delta="n/a"
channel_mix_recommendation=""
target_win_card="25"
target_win_recap="20"
target_posts="3"
target_stories="2"
target_installs="5"
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
    --win-card)
      win_card="${2:-}"
      shift 2
      ;;
    --win-card-delta)
      win_card_delta="${2:-}"
      shift 2
      ;;
    --win-recap)
      win_recap="${2:-}"
      shift 2
      ;;
    --win-recap-delta)
      win_recap_delta="${2:-}"
      shift 2
      ;;
    --posts)
      posts="${2:-}"
      shift 2
      ;;
    --posts-delta)
      posts_delta="${2:-}"
      shift 2
      ;;
    --stories)
      stories="${2:-}"
      shift 2
      ;;
    --stories-delta)
      stories_delta="${2:-}"
      shift 2
      ;;
    --installs)
      installs="${2:-}"
      shift 2
      ;;
    --installs-delta)
      installs_delta="${2:-}"
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
    --monday-source-week)
      monday_source_week="${2:-}"
      shift 2
      ;;
    --monday-post-status)
      monday_post_status="${2:-}"
      shift 2
      ;;
    --reply-pack-replies)
      reply_pack_replies="${2:-}"
      shift 2
      ;;
    --reply-pack-replies-delta)
      reply_pack_replies_delta="${2:-}"
      shift 2
      ;;
    --reply-pack-objections)
      reply_pack_objections="${2:-}"
      shift 2
      ;;
    --reply-pack-objections-delta)
      reply_pack_objections_delta="${2:-}"
      shift 2
      ;;
    --reply-pack-doc-updates)
      reply_pack_doc_updates="${2:-}"
      shift 2
      ;;
    --reply-pack-doc-updates-delta)
      reply_pack_doc_updates_delta="${2:-}"
      shift 2
      ;;
    --outreach-sent)
      outreach_sent="${2:-}"
      shift 2
      ;;
    --outreach-sent-delta)
      outreach_sent_delta="${2:-}"
      shift 2
      ;;
    --outreach-replies)
      outreach_replies="${2:-}"
      shift 2
      ;;
    --outreach-replies-delta)
      outreach_replies_delta="${2:-}"
      shift 2
      ;;
    --outreach-collabs)
      outreach_collabs="${2:-}"
      shift 2
      ;;
    --outreach-collabs-delta)
      outreach_collabs_delta="${2:-}"
      shift 2
      ;;
    --outreach-cross-posts)
      outreach_cross_posts="${2:-}"
      shift 2
      ;;
    --outreach-cross-posts-delta)
      outreach_cross_posts_delta="${2:-}"
      shift 2
      ;;
    --outreach-reply-rate)
      outreach_reply_rate="${2:-}"
      shift 2
      ;;
    --outreach-reply-rate-delta)
      outreach_reply_rate_delta="${2:-}"
      shift 2
      ;;
    --outreach-collab-rate)
      outreach_collab_rate="${2:-}"
      shift 2
      ;;
    --outreach-collab-rate-delta)
      outreach_collab_rate_delta="${2:-}"
      shift 2
      ;;
    --outreach-cross-post-rate)
      outreach_cross_post_rate="${2:-}"
      shift 2
      ;;
    --outreach-cross-post-rate-delta)
      outreach_cross_post_rate_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-entries)
      creator_signal_entries="${2:-}"
      shift 2
      ;;
    --creator-signal-entries-delta)
      creator_signal_entries_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-high-fit)
      creator_signal_high_fit="${2:-}"
      shift 2
      ;;
    --creator-signal-high-fit-delta)
      creator_signal_high_fit_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-warm-intros)
      creator_signal_warm_intros="${2:-}"
      shift 2
      ;;
    --creator-signal-warm-intros-delta)
      creator_signal_warm_intros_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-collab-ready)
      creator_signal_collab_ready="${2:-}"
      shift 2
      ;;
    --creator-signal-collab-ready-delta)
      creator_signal_collab_ready_delta="${2:-}"
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
    --creator-signal-enrichment-score-delta)
      creator_signal_enrichment_score_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-recommendation)
      creator_signal_recommendation="${2:-}"
      shift 2
      ;;
    --guesting-signal-entries)
      guesting_signal_entries="${2:-}"
      shift 2
      ;;
    --guesting-signal-entries-delta)
      guesting_signal_entries_delta="${2:-}"
      shift 2
      ;;
    --guesting-signal-replied)
      guesting_signal_replied="${2:-}"
      shift 2
      ;;
    --guesting-signal-replied-delta)
      guesting_signal_replied_delta="${2:-}"
      shift 2
      ;;
    --guesting-signal-booked)
      guesting_signal_booked="${2:-}"
      shift 2
      ;;
    --guesting-signal-booked-delta)
      guesting_signal_booked_delta="${2:-}"
      shift 2
      ;;
    --guesting-signal-published)
      guesting_signal_published="${2:-}"
      shift 2
      ;;
    --guesting-signal-published-delta)
      guesting_signal_published_delta="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-format)
      guesting_signal_top_format="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-target)
      guesting_signal_top_target="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score)
      guesting_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score-delta)
      guesting_signal_enrichment_score_delta="${2:-}"
      shift 2
      ;;
    --guesting-signal-recommendation)
      guesting_signal_recommendation="${2:-}"
      shift 2
      ;;
    --narrative-route-winner)
      narrative_route_winner="${2:-}"
      shift 2
      ;;
    --narrative-route-winner-delta)
      narrative_route_winner_delta="${2:-}"
      shift 2
      ;;
    --narrative-route-trend)
      narrative_route_trend="${2:-}"
      shift 2
      ;;
    --narrative-fame-velocity-score)
      narrative_fame_velocity_score="${2:-}"
      shift 2
      ;;
    --narrative-fame-velocity-score-delta)
      narrative_fame_velocity_score_delta="${2:-}"
      shift 2
      ;;
    --narrative-launch-posture)
      narrative_launch_posture="${2:-}"
      shift 2
      ;;
    --narrative-next-standup-action)
      narrative_next_standup_action="${2:-}"
      shift 2
      ;;
    --narrative-route-recommendation)
      narrative_route_recommendation="${2:-}"
      shift 2
      ;;
    --narrative-route-mode)
      narrative_route_mode="${2:-}"
      shift 2
      ;;
    --narrative-route-alignment-target)
      narrative_route_alignment_target="${2:-}"
      shift 2
      ;;
    --narrative-route-lane-status)
      narrative_route_lane_status="${2:-}"
      shift 2
      ;;
    --narrative-route-guardrail)
      narrative_route_guardrail="${2:-}"
      shift 2
      ;;
    --narrative-route-control-recommendation)
      narrative_route_control_recommendation="${2:-}"
      shift 2
      ;;
    --narrative-distribution-strategy)
      narrative_distribution_strategy="${2:-}"
      shift 2
      ;;
    --narrative-distribution-day0-lead)
      narrative_distribution_day0_lead="${2:-}"
      shift 2
      ;;
    --narrative-distribution-day0-support)
      narrative_distribution_day0_support="${2:-}"
      shift 2
      ;;
    --narrative-distribution-recommendation)
      narrative_distribution_recommendation="${2:-}"
      shift 2
      ;;
    --narrative-distribution-first-48h-plan)
      narrative_distribution_first_48h_plan="${2:-}"
      shift 2
      ;;
    --outreach-sprint-comment-entries)
      outreach_sprint_comment_entries="${2:-}"
      shift 2
      ;;
    --outreach-sprint-comment-entries-delta)
      outreach_sprint_comment_entries_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-completed)
      outreach_sprint_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-completed-delta)
      outreach_sprint_tasks_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-total)
      outreach_sprint_tasks_total="${2:-}"
      shift 2
      ;;
    --outreach-sprint-completion-rate)
      outreach_sprint_completion_rate="${2:-}"
      shift 2
      ;;
    --outreach-sprint-completion-rate-delta)
      outreach_sprint_completion_rate_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-creator-tasks-completed)
      outreach_sprint_creator_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-creator-tasks-completed-delta)
      outreach_sprint_creator_tasks_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-guesting-tasks-completed)
      outreach_sprint_guesting_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-guesting-tasks-completed-delta)
      outreach_sprint_guesting_tasks_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-defaults-tasks-completed)
      outreach_sprint_owner_defaults_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-defaults-tasks-completed-delta)
      outreach_sprint_owner_defaults_tasks_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-defaults-tasks-total)
      outreach_sprint_owner_defaults_tasks_total="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-defaults-completion-rate)
      outreach_sprint_owner_defaults_completion_rate="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-defaults-completion-rate-delta)
      outreach_sprint_owner_defaults_completion_rate_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-creator-completed)
      outreach_sprint_owner_default_creator_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-creator-completed-delta)
      outreach_sprint_owner_default_creator_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-guesting-completed)
      outreach_sprint_owner_default_guesting_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-guesting-completed-delta)
      outreach_sprint_owner_default_guesting_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-distribution-completed)
      outreach_sprint_owner_default_distribution_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-distribution-completed-delta)
      outreach_sprint_owner_default_distribution_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-ops-completed)
      outreach_sprint_owner_default_ops_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-owner-default-ops-completed-delta)
      outreach_sprint_owner_default_ops_completed_delta="${2:-}"
      shift 2
      ;;
    --outreach-sprint-variant-promoted)
      outreach_sprint_variant_promoted="${2:-}"
      shift 2
      ;;
    --outreach-sprint-outcomes-logged)
      outreach_sprint_outcomes_logged="${2:-}"
      shift 2
      ;;
    --outreach-sprint-preferred-lane)
      outreach_sprint_preferred_lane="${2:-}"
      shift 2
      ;;
    --outreach-sprint-recommendation)
      outreach_sprint_recommendation="${2:-}"
      shift 2
      ;;
    --primary-top-variant)
      primary_top_variant="${2:-}"
      shift 2
      ;;
    --backup-top-variant)
      backup_top_variant="${2:-}"
      shift 2
      ;;
    --variant-recommendation)
      variant_recommendation="${2:-}"
      shift 2
      ;;
    --outreach-recommendation)
      outreach_recommendation="${2:-}"
      shift 2
      ;;
    --primary-variant-win-trend)
      primary_variant_win_trend="${2:-}"
      shift 2
      ;;
    --backup-variant-win-trend)
      backup_variant_win_trend="${2:-}"
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
    --channel-roi-recommendation)
      channel_roi_recommendation="${2:-}"
      shift 2
      ;;
    --distribution-days-completed)
      distribution_days_completed="${2:-}"
      shift 2
      ;;
    --distribution-days-completed-delta)
      distribution_days_completed_delta="${2:-}"
      shift 2
      ;;
    --distribution-completion-score)
      distribution_completion_score="${2:-}"
      shift 2
      ;;
    --distribution-completion-score-delta)
      distribution_completion_score_delta="${2:-}"
      shift 2
      ;;
    --channel-mix-recommendation)
      channel_mix_recommendation="${2:-}"
      shift 2
      ;;
    --target-win-card)
      target_win_card="${2:-}"
      shift 2
      ;;
    --target-win-recap)
      target_win_recap="${2:-}"
      shift 2
      ;;
    --target-posts)
      target_posts="${2:-}"
      shift 2
      ;;
    --target-stories)
      target_stories="${2:-}"
      shift 2
      ;;
    --target-installs)
      target_installs="${2:-}"
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

if [[ -z "$primary_channel" ]]; then
  primary_channel="X / Threads"
fi

if [[ -z "$backup_channel" ]]; then
  backup_channel="LinkedIn"
fi

normalize_post_status() {
  local raw_status="$1"
  local lowered
  lowered="$(print -r -- "$raw_status" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lowered" == *"not posted"* || "$lowered" == *"not published"* || "$lowered" == *"blocked"* || "$lowered" == *"draft"* || "$lowered" == *"no"* ]]; then
    echo "not posted"
    return
  fi
  if [[ "$lowered" == *"in progress"* || "$lowered" == *"pending"* || "$lowered" == *"scheduled"* ]]; then
    echo "in progress"
    return
  fi
  if [[ "$lowered" == *"posted"* || "$lowered" == *"published"* || "$lowered" == *"live"* || "$lowered" == *"done"* || "$lowered" == *"yes"* ]]; then
    echo "posted"
    return
  fi
  echo "not posted"
}

normalized_monday_post_status="$(normalize_post_status "$monday_post_status")"
if [[ -z "$monday_source_week" ]]; then
  monday_source_week="n/a"
fi

normalize_variant_label() {
  local raw_variant="$1"
  local lowered
  lowered="$(print -r -- "$raw_variant" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$lowered" || "$lowered" == "n/a" || "$lowered" == "none" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == *"variant a"* || "$lowered" == *"proof-first"* || "$lowered" == *"proof first"* || "$lowered" == "a" ]]; then
    echo "A"
    return
  fi
  if [[ "$lowered" == *"variant b"* || "$lowered" == *"workflow-first"* || "$lowered" == *"workflow first"* || "$lowered" == "b" ]]; then
    echo "B"
    return
  fi
  if [[ "$lowered" == *"variant c"* || "$lowered" == *"objection-handler"* || "$lowered" == *"objection handler"* || "$lowered" == "c" ]]; then
    echo "C"
    return
  fi
  echo "n/a"
}

normalize_narrative_route() {
  local raw_route="$1"
  local lowered
  lowered="$(print -r -- "$raw_route" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$lowered" || "$lowered" == "n/a" || "$lowered" == "none" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == *"proof-first"* || "$lowered" == *"proof first"* ]]; then
    echo "Proof-first route"
    return
  fi
  if [[ "$lowered" == *"behind-the-scenes"* || "$lowered" == *"behind the scenes"* || "$lowered" == *"bts"* ]]; then
    echo "Behind-the-scenes route"
    return
  fi
  if [[ "$lowered" == *"objection-breaker"* || "$lowered" == *"objection breaker"* || "$lowered" == *"objection-handler"* || "$lowered" == *"objection handler"* ]]; then
    echo "Objection-breaker route"
    return
  fi
  if [[ "$lowered" == *"hook-driven"* || "$lowered" == *"hook driven"* ]]; then
    echo "Hook-driven overlay"
    return
  fi
  echo "$raw_route"
}

normalize_binary_completion() {
  local raw_value="$1"
  local lowered
  lowered="$(print -r -- "$raw_value" | tr '[:upper:]' '[:lower:]')"
  lowered="${lowered## }"
  lowered="${lowered%% }"
  if [[ -z "$lowered" || "$lowered" == "n/a" || "$lowered" == "na" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == "1" || "$lowered" == "yes" || "$lowered" == "y" || "$lowered" == "true" || "$lowered" == "done" || "$lowered" == "completed" ]]; then
    echo "yes"
    return
  fi
  if [[ "$lowered" == "0" || "$lowered" == "no" || "$lowered" == "n" || "$lowered" == "false" || "$lowered" == "not done" || "$lowered" == "incomplete" ]]; then
    echo "no"
    return
  fi
  echo "n/a"
}

format_delta_display() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  format_signed_number "$parsed"
}

format_rate_display() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  awk -v parsed="$parsed" 'BEGIN {
    value = parsed + 0
    rounded = int((value * 10) + (value >= 0 ? 0.5 : -0.5)) / 10
    if (rounded == int(rounded)) {
      printf "%d%%", int(rounded)
    } else {
      printf "%.1f%%", rounded
    }
  }'
}

format_rate_delta_display() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  awk -v parsed="$parsed" 'BEGIN {
    value = parsed + 0
    rounded = int((value * 10) + (value >= 0 ? 0.5 : -0.5)) / 10
    if (rounded > 0) {
      if (rounded == int(rounded)) {
        printf "+%dpp", int(rounded)
      } else {
        printf "+%.1fpp", rounded
      }
      exit
    }
    if (rounded == int(rounded)) {
      printf "%dpp", int(rounded)
    } else {
      printf "%.1fpp", rounded
    }
  }'
}

build_variant_recommendation() {
  local primary_variant="$1"
  local backup_variant="$2"
  local replies_delta_value="$3"
  local replies_delta_numeric
  replies_delta_numeric="$(extract_number "$replies_delta_value")"

  if [[ "$primary_variant" != "n/a" && "$backup_variant" != "n/a" && "$primary_variant" == "$backup_variant" ]]; then
    echo "Scale Variant $primary_variant across both channels next week."
    return
  fi
  if [[ "$primary_variant" != "n/a" && "$backup_variant" != "n/a" ]]; then
    echo "Keep split test: primary Variant $primary_variant, backup Variant $backup_variant."
    return
  fi
  if [[ "$primary_variant" != "n/a" ]]; then
    echo "Keep Variant $primary_variant on primary channel and test Variant B on backup."
    return
  fi
  if [[ "$backup_variant" != "n/a" ]]; then
    echo "Keep Variant $backup_variant on backup channel and test Variant B on primary."
    return
  fi

  if [[ -n "$replies_delta_numeric" ]]; then
    if [[ "$(is_ge "$replies_delta_numeric" "0.000001")" == "1" ]]; then
      echo "Keep current variant mix and log winners by Monday night."
      return
    fi
    if [[ "$(is_ge "$replies_delta_numeric" "0")" != "1" ]]; then
      echo "Switch both channels to Variant B (workflow-first) to recover replies."
      return
    fi
  fi

  echo "Start with Variant A on primary and Variant B on backup, then log winners in checklist."
}

build_outreach_recommendation() {
  local outreach_sent_value="$1"
  local outreach_replies_value="$2"
  local outreach_collabs_value="$3"
  local outreach_cross_posts_value="$4"
  local outreach_replies_delta_value="$5"
  local outreach_collabs_delta_value="$6"
  local outreach_reply_rate_value="$7"
  local outreach_collab_rate_value="$8"
  local outreach_reply_rate_delta_value="$9"
  local outreach_collab_rate_delta_value="${10}"

  local sent_numeric
  local replies_numeric
  local collabs_numeric
  local cross_posts_numeric
  local replies_delta_numeric
  local collabs_delta_numeric
  local reply_rate_numeric
  local collab_rate_numeric
  local reply_rate_delta_numeric
  local collab_rate_delta_numeric

  sent_numeric="$(extract_number "$outreach_sent_value")"
  replies_numeric="$(extract_number "$outreach_replies_value")"
  collabs_numeric="$(extract_number "$outreach_collabs_value")"
  cross_posts_numeric="$(extract_number "$outreach_cross_posts_value")"
  replies_delta_numeric="$(extract_number "$outreach_replies_delta_value")"
  collabs_delta_numeric="$(extract_number "$outreach_collabs_delta_value")"
  reply_rate_numeric="$(extract_number "$outreach_reply_rate_value")"
  collab_rate_numeric="$(extract_number "$outreach_collab_rate_value")"
  reply_rate_delta_numeric="$(extract_number "$outreach_reply_rate_delta_value")"
  collab_rate_delta_numeric="$(extract_number "$outreach_collab_rate_delta_value")"

  if [[ -z "$reply_rate_numeric" && -n "$sent_numeric" && -n "$replies_numeric" && "$(is_ge "$sent_numeric" "0.000001")" == "1" ]]; then
    reply_rate_numeric="$(awk -v replies="$replies_numeric" -v sent="$sent_numeric" 'BEGIN { printf "%.6f", ((replies + 0) / (sent + 0)) * 100 }')"
  fi
  if [[ -z "$collab_rate_numeric" && -n "$sent_numeric" && -n "$collabs_numeric" && "$(is_ge "$sent_numeric" "0.000001")" == "1" ]]; then
    collab_rate_numeric="$(awk -v collabs="$collabs_numeric" -v sent="$sent_numeric" 'BEGIN { printf "%.6f", ((collabs + 0) / (sent + 0)) * 100 }')"
  fi

  if [[ -n "$collab_rate_numeric" && "$(is_ge "$collab_rate_numeric" "20")" == "1" ]]; then
    echo "Scale creator outreach list by 50% and keep the current pitch angle."
    return
  fi

  if [[ -n "$collab_rate_numeric" && "$(is_ge "$collab_rate_numeric" "10")" == "1" ]]; then
    echo "Keep creator pitch angle and tighten Day-2 + Day-4 follow-ups."
    return
  fi

  if [[ -n "$collab_rate_delta_numeric" && "$(is_ge "$collab_rate_delta_numeric" "0.000001")" == "1" ]]; then
    echo "Double down on creator categories with rising collaboration rate."
    return
  fi

  if [[ -n "$reply_rate_delta_numeric" && "$(is_ge "$reply_rate_delta_numeric" "0")" != "1" ]]; then
    echo "Refresh outreach hook with stronger before/after proof to recover reply rate."
    return
  fi

  if [[ -n "$sent_numeric" && -n "$collabs_numeric" && "$(is_ge "$sent_numeric" "0.000001")" == "1" ]]; then
    local acceptance_rate
    acceptance_rate="$(awk -v collabs="$collabs_numeric" -v sent="$sent_numeric" 'BEGIN { if (sent + 0 <= 0) { print "0"; exit } printf "%.6f", (collabs + 0) / (sent + 0) }')"
    if [[ "$(is_ge "$acceptance_rate" "0.20")" == "1" ]]; then
      echo "Scale creator outreach list by 50% and keep the current pitch angle."
      return
    fi
    if [[ "$(is_ge "$acceptance_rate" "0.10")" == "1" ]]; then
      echo "Keep creator pitch angle and tighten Day-2 + Day-4 follow-ups."
      return
    fi
  fi

  if [[ -n "$collabs_delta_numeric" && "$(is_ge "$collabs_delta_numeric" "0.000001")" == "1" ]]; then
    echo "Double down on creator categories that produced collaborations this week."
    return
  fi

  if [[ -n "$replies_delta_numeric" && "$(is_ge "$replies_delta_numeric" "0")" != "1" ]]; then
    echo "Refresh outreach hook with stronger before/after proof and follow up within 48 hours."
    return
  fi

  if [[ -n "$cross_posts_numeric" && "$(is_ge "$cross_posts_numeric" "1")" != "1" ]]; then
    echo "Secure at least one community cross-post before Friday to widen discovery."
    return
  fi

  if [[ -n "$sent_numeric" && "$(is_ge "$sent_numeric" "5")" != "1" ]]; then
    echo "Raise outreach volume to at least 5 targeted creator messages next week."
    return
  fi

  if [[ -n "$replies_numeric" && "$(is_ge "$replies_numeric" "1")" == "1" && ( -z "$collabs_numeric" || "$(is_ge "$collabs_numeric" "1")" != "1" ) ]]; then
    echo "Convert active creator replies into one concrete collaboration ask this week."
    return
  fi

  echo "Send 5 targeted creator messages and log outcomes in Monday checklist."
}

normalize_channel_preference() {
  local raw_value="$1"
  local lowered
  lowered="$(print -r -- "$raw_value" | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$lowered" ]]; then
    echo "balanced"
    return
  fi
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

build_channel_roi_recommendation() {
  local primary_roi_score="$1"
  local backup_roi_score="$2"
  local preferred_channel="$3"
  local primary_variant="$4"
  local backup_variant="$5"
  local primary_display
  local backup_display

  if [[ -z "$primary_roi_score" || -z "$backup_roi_score" ]]; then
    echo "Collect Monday reply and outreach effectiveness data before routing by channel ROI."
    return
  fi

  primary_display="$(format_number "$primary_roi_score")"
  backup_display="$(format_number "$backup_roi_score")"

  case "$preferred_channel" in
    primary)
      if [[ "$primary_variant" != "n/a" ]]; then
        echo "Lead with primary channel next week (ROI $primary_display vs $backup_display) and keep Variant $primary_variant as default opener."
      else
        echo "Lead with primary channel next week (ROI $primary_display vs $backup_display) and keep backup channel for supporting distribution."
      fi
      ;;
    backup)
      if [[ "$backup_variant" != "n/a" ]]; then
        echo "Lead with backup channel next week (ROI $backup_display vs $primary_display) and keep Variant $backup_variant as default opener."
      else
        echo "Lead with backup channel next week (ROI $backup_display vs $primary_display) and keep primary channel as supporting distribution."
      fi
      ;;
    *)
      if [[ "$primary_variant" != "n/a" && "$backup_variant" != "n/a" && "$primary_variant" == "$backup_variant" ]]; then
        echo "ROI is close ($primary_display vs $backup_display); run Variant $primary_variant on both channels and pick winner from Monday reply quality."
      else
        echo "ROI is close ($primary_display vs $backup_display); keep split-channel test and decide lead channel after Monday replies."
      fi
      ;;
  esac
}

build_channel_mix_recommendation() {
  local preferred_channel="$1"
  local distribution_score_value="$2"
  local distribution_score_delta_value="$3"
  local monday_post_status_value="$4"
  local replies_delta_value="$5"
  local outreach_reply_rate_delta_value="$6"

  local distribution_score_number
  local distribution_score_delta_number
  local replies_delta_number
  local outreach_reply_rate_delta_number
  local mix_label

  distribution_score_number="$(extract_number "$distribution_score_value")"
  distribution_score_delta_number="$(extract_number "$distribution_score_delta_value")"
  replies_delta_number="$(extract_number "$replies_delta_value")"
  outreach_reply_rate_delta_number="$(extract_number "$outreach_reply_rate_delta_value")"

  case "$preferred_channel" in
    primary)
      mix_label="primary-led 60/40"
      ;;
    backup)
      mix_label="backup-led 60/40"
      ;;
    *)
      mix_label="balanced 50/50"
      ;;
  esac

  if [[ -z "$distribution_score_number" ]]; then
    echo "Keep channel mix balanced until distribution execution score is logged."
    return
  fi

  if [[ "$(is_ge "$distribution_score_number" "75")" == "1" ]]; then
    echo "Distribution execution is strong (${distribution_score_value}); keep $mix_label mix and scale Day-2 + Day-4 follow-ups."
    return
  fi

  if [[ "$(is_ge "$distribution_score_number" "50")" != "1" ]]; then
    if [[ "$preferred_channel" == "primary" || "$preferred_channel" == "backup" ]]; then
      echo "Distribution execution is low (${distribution_score_value}); narrow to ${preferred_channel}-led 80/20 until Day-0 to Day-2 tasks are complete."
    else
      echo "Distribution execution is low (${distribution_score_value}); narrow to a single 80/20 lead channel until Day-0 to Day-2 tasks are complete."
    fi
    return
  fi

  if [[ "$monday_post_status_value" != "posted" ]]; then
    echo "Monday post status is ${monday_post_status_value}; keep an 80/20 lead mix until publish status is fully closed."
    return
  fi

  if [[ -n "$distribution_score_delta_number" && "$(is_ge "$distribution_score_delta_number" "0")" != "1" ]]; then
    echo "Distribution completion is slipping (${distribution_score_delta_value}); simplify to a 70/30 lead mix and recover checklist coverage."
    return
  fi

  if [[ -n "$replies_delta_number" && "$(is_ge "$replies_delta_number" "0")" != "1" ]]; then
    echo "Reply momentum is down; bias to ROI-preferred channel at 70/30 and run objection-handler repost on Day 3."
    return
  fi

  if [[ -n "$outreach_reply_rate_delta_number" && "$(is_ge "$outreach_reply_rate_delta_number" "0")" != "1" ]]; then
    echo "Outreach reply rate is down; bias to ROI-preferred channel at 70/30 and tighten follow-up cadence."
    return
  fi

  echo "Maintain $mix_label mix and complete the full Day-0 to Day-7 distribution cadence."
}

build_narrative_route_recommendation() {
  local route_winner="$1"
  local route_trend="$2"
  local fame_velocity_score_value="$3"
  local launch_posture_value="$4"
  local next_standup_action_value="$5"
  local normalized_route
  local normalized_trend
  local normalized_posture
  local fame_velocity_score_number

  normalized_route="$(normalize_narrative_route "$route_winner")"
  normalized_trend="${route_trend:l}"
  normalized_posture="${launch_posture_value:l}"
  fame_velocity_score_number="$(extract_number "$fame_velocity_score_value")"

  if [[ "$normalized_route" == "n/a" ]]; then
    echo "Capture founder fame narrative lab comment before Friday review to track route winners."
    return
  fi

  if [[ -n "$fame_velocity_score_number" && "$(is_ge "$fame_velocity_score_number" "75")" == "1" ]]; then
    if [[ -n "$next_standup_action_value" && "${next_standup_action_value:l}" != "n/a" ]]; then
      echo "Keep $normalized_route as lead narrative route and scale it across both channels while preserving proof guardrails. Next standup action: $next_standup_action_value"
      return
    fi
    echo "Keep $normalized_route as lead narrative route and scale it across both channels while preserving proof guardrails."
    return
  fi

  if [[ "$normalized_trend" == shifted\ from* ]]; then
    echo "Validate $normalized_route as the new route winner with two proof-backed posts before locking next-week defaults."
    return
  fi

  if [[ "$normalized_posture" == *"recovery"* || "$normalized_posture" == *"stabilize"* || "$normalized_posture" == *"watch"* ]]; then
    echo "Keep $normalized_route as lead route, run one Route Remix Matrix fallback this week, and log one winner + one failed route in standup notes."
    return
  fi

  if [[ -n "$next_standup_action_value" && "${next_standup_action_value:l}" != "n/a" ]]; then
    echo "Keep $normalized_route as the priority route and execute next standup action: $next_standup_action_value"
    return
  fi

  echo "Keep $normalized_route as the priority route and log one winner + one failed route in standup notes."
}

build_narrative_route_control_recommendation() {
  local route_mode_value="$1"
  local route_lane_status_value="$2"
  local route_alignment_target_value="$3"
  local route_guardrail_value="$4"
  local route_winner_value="$5"
  local next_standup_action_value="$6"
  local normalized_mode="${route_mode_value:l}"
  local normalized_lane_status="${route_lane_status_value:l}"
  local normalized_winner
  normalized_winner="$(normalize_narrative_route "$route_winner_value")"

  if [[ -z "$normalized_mode" || "$normalized_mode" == "n/a" ]]; then
    if [[ -z "$normalized_lane_status" || "$normalized_lane_status" == "n/a" ]]; then
      echo "Capture route mode and lane status in founder narrative lab controls before Friday review."
      return
    fi
  fi

  if [[ "$normalized_mode" == *"recovery"* || "$normalized_lane_status" == *"critical"* || "$normalized_lane_status" == *"drifting"* ]]; then
    echo "Run route recovery execution this week, keep lane status above Critical, and enforce guardrail: ${route_guardrail_value}."
    return
  fi

  if [[ "$normalized_mode" == *"re-lock"* || "$normalized_lane_status" == *"watch"* || "$normalized_lane_status" == *"partial"* ]]; then
    echo "Run route re-lock actions, restore alignment target ${route_alignment_target_value}, and validate one proof-backed winner before scaling."
    return
  fi

  if [[ "$normalized_winner" == "n/a" ]]; then
    echo "Capture and normalize the route winner before scaling narrative distribution."
    return
  fi

  if [[ -n "$next_standup_action_value" && "${next_standup_action_value:l}" != "n/a" ]]; then
    echo "Keep ${normalized_winner} at alignment target ${route_alignment_target_value} and execute: ${next_standup_action_value}"
    return
  fi

  echo "Keep ${normalized_winner} at alignment target ${route_alignment_target_value} while preserving guardrail: ${route_guardrail_value}."
}

build_narrative_distribution_recommendation() {
  local distribution_strategy_value="$1"
  local distribution_day0_lead_value="$2"
  local distribution_day0_support_value="$3"
  local route_mode_value="$4"
  local route_lane_status_value="$5"

  local normalized_strategy
  local normalized_strategy_lower
  local normalized_day0_lead
  local normalized_day0_support
  local normalized_mode
  local normalized_lane_status

  normalized_strategy="$(trim_value "$distribution_strategy_value")"
  normalized_strategy_lower="${normalized_strategy:l}"
  normalized_day0_lead="$(trim_value "$distribution_day0_lead_value")"
  normalized_day0_support="$(trim_value "$distribution_day0_support_value")"
  normalized_mode="${route_mode_value:l}"
  normalized_lane_status="${route_lane_status_value:l}"

  if [[ -z "$normalized_strategy" || "$normalized_strategy_lower" == "n/a" ]]; then
    if [[ -z "$normalized_day0_lead" || "${normalized_day0_lead:l}" == "n/a" ]]; then
      echo "Capture 7-day distribution calendar fields in founder narrative lab before Friday review."
      return
    fi
  fi

  if [[ "$normalized_mode" == *"recovery"* || "$normalized_lane_status" == *"critical"* || "$normalized_lane_status" == *"drifting"* ]]; then
    echo "Run recovery distribution cadence with Day 0 lead ${normalized_day0_lead:-n/a} and support ${normalized_day0_support:-n/a}; keep risk-closure proof first."
    return
  fi

  if [[ "$normalized_mode" == *"re-lock"* || "$normalized_lane_status" == *"watch"* || "$normalized_lane_status" == *"partial"* ]]; then
    echo "Run re-lock distribution cadence with Day 0 lead ${normalized_day0_lead:-n/a}; use ${normalized_day0_support:-n/a} for support replies and route-confidence reinforcement."
    return
  fi

  if [[ "$normalized_strategy_lower" == *"recovery cadence"* ]]; then
    echo "Keep recovery cadence active: lead ${normalized_day0_lead:-n/a}, support ${normalized_day0_support:-n/a}, and close practical-reply blockers before scaling."
    return
  fi

  if [[ "$normalized_strategy_lower" == *"re-lock cadence"* ]]; then
    echo "Keep re-lock cadence active: lead ${normalized_day0_lead:-n/a}, support ${normalized_day0_support:-n/a}, and validate one route-winner proof post before broad distribution."
    return
  fi

  if [[ "$normalized_strategy_lower" == *"compounding cadence"* ]]; then
    echo "Keep compounding cadence active with Day 0 lead ${normalized_day0_lead:-n/a} and support ${normalized_day0_support:-n/a}; scale winner amplification through Day 6."
    return
  fi

  echo "Execute distribution strategy '${normalized_strategy:-n/a}' with Day 0 lead ${normalized_day0_lead:-n/a} and support ${normalized_day0_support:-n/a}."
}

build_narrative_distribution_first_48h_plan() {
  local distribution_strategy_value="$1"
  local distribution_day0_lead_value="$2"
  local distribution_day0_support_value="$3"
  local route_mode_value="$4"
  local route_lane_status_value="$5"

  local normalized_strategy
  local normalized_strategy_lower
  local normalized_day0_lead
  local normalized_day0_support
  local normalized_mode
  local normalized_lane_status
  local lead_lane
  local support_lane

  normalized_strategy="$(trim_value "$distribution_strategy_value")"
  normalized_strategy_lower="${normalized_strategy:l}"
  normalized_day0_lead="$(trim_value "$distribution_day0_lead_value")"
  normalized_day0_support="$(trim_value "$distribution_day0_support_value")"
  normalized_mode="${route_mode_value:l}"
  normalized_lane_status="${route_lane_status_value:l}"
  lead_lane="${normalized_day0_lead:-n/a}"
  support_lane="${normalized_day0_support:-n/a}"

  if [[ ( -z "$normalized_strategy" || "$normalized_strategy_lower" == "n/a" ) && ( -z "$normalized_day0_lead" || "${normalized_day0_lead:l}" == "n/a" ) && ( -z "$normalized_day0_support" || "${normalized_day0_support:l}" == "n/a" ) ]]; then
    echo "Capture Day 0 lead/support lanes first, then script Day 1 proof recap and Day 2 objection-breaker follow-up."
    return
  fi

  if [[ "$normalized_mode" == *"recovery"* || "$normalized_lane_status" == *"critical"* || "$normalized_lane_status" == *"drifting"* ]]; then
    echo "Day 0: publish recovery proof on ${lead_lane}. Day 1: run blocker-response follow-up on ${support_lane}. Day 2: post route-stability proof before scaling."
    return
  fi

  if [[ "$normalized_mode" == *"re-lock"* || "$normalized_lane_status" == *"watch"* || "$normalized_lane_status" == *"partial"* ]]; then
    echo "Day 0: lead with winner re-lock post on ${lead_lane}. Day 1: reinforce confidence with replies on ${support_lane}. Day 2: publish one proof-backed winner recap."
    return
  fi

  if [[ "$normalized_strategy_lower" == *"compounding cadence"* ]]; then
    echo "Day 0: publish winner-led opener on ${lead_lane}. Day 1: amplify best replies on ${support_lane}. Day 2: ship compounding proof recap and queue Day 3 remix."
    return
  fi

  if [[ "$normalized_strategy_lower" == *"recovery cadence"* ]]; then
    echo "Day 0: run recovery opener on ${lead_lane}. Day 1: close objections on ${support_lane}. Day 2: verify route health and only then scale distribution."
    return
  fi

  if [[ "$normalized_strategy_lower" == *"re-lock cadence"* ]]; then
    echo "Day 0: run re-lock opener on ${lead_lane}. Day 1: reinforce with support-lane follow-ups on ${support_lane}. Day 2: confirm winner confidence with one proof post."
    return
  fi

  echo "Day 0: launch on ${lead_lane}. Day 1: support with targeted replies on ${support_lane}. Day 2: publish proof recap tied to strategy '${normalized_strategy:-n/a}'."
}

build_variant_script() {
  local variant="$1"
  local channel_label="$2"
  local command_name="$3"
  local strongest_metric_line="$4"
  local focus_line="$5"

  case "$variant" in
    A)
      cat <<EOF
Proof-first script for $channel_label:
$strongest_metric_line

Flow:
Option + Shift + Space -> Read Selected Text -> $command_name

CTA: Try this exact flow and share your first result.
EOF
      ;;
    B)
      cat <<EOF
Workflow-first script for $channel_label:
1) Option + Shift + Space
2) Read Selected Text
3) $command_name

Focus: $focus_line
CTA: Reply if you want the exact prompt I used.
EOF
      ;;
    C)
      cat <<EOF
Objection-handler script for $channel_label:
Core mode runs local on macOS (capture + OCR on device).
LLM stays optional when local-only workflow is required.

Command path:
Read Selected Text -> Ask Anything -> $command_name
EOF
      ;;
    *)
      cat <<EOF
Balanced script for $channel_label:
$strongest_metric_line

Starter flow:
Read Selected Text -> Ask Anything -> $command_name
EOF
      ;;
  esac
}

extract_number() {
  local raw_value="$1"
  print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true
}

is_ge() {
  local left="$1"
  local right="$2"
  awk -v left="$left" -v right="$right" 'BEGIN { if ((left + 0) >= (right + 0)) print "1"; else print "0" }'
}

is_le() {
  local left="$1"
  local right="$2"
  awk -v left="$left" -v right="$right" 'BEGIN { if ((left + 0) <= (right + 0)) print "1"; else print "0" }'
}

format_number() {
  local raw_number="$1"
  awk -v raw_number="$raw_number" 'BEGIN {
    value = raw_number + 0
    if (value == int(value)) {
      printf "%d", int(value)
    } else {
      printf "%.2f", value
    }
  }'
}

format_signed_number() {
  local raw_number="$1"
  awk -v raw_number="$raw_number" 'BEGIN {
    value = raw_number + 0
    if (value == int(value)) {
      if (value > 0) {
        printf "+%d", int(value)
      } else {
        printf "%d", int(value)
      }
    } else {
      if (value > 0) {
        printf "+%.2f", value
      } else {
        printf "%.2f", value
      }
    }
  }'
}

format_non_negative_gap() {
  local current_value="$1"
  local target_value="$2"
  awk -v current_value="$current_value" -v target_value="$target_value" 'BEGIN {
    gap = (target_value + 0) - (current_value + 0)
    if (gap < 0) gap = 0
    if (gap == int(gap)) {
      printf "%d", int(gap)
    } else {
      printf "%.2f", gap
    }
  }'
}

score_priority_action_line() {
  local action_line="$1"
  local lowered_action
  local score=40
  lowered_action="${action_line:l}"

  if [[ "$lowered_action" == *"creator outreach"* || "$lowered_action" == *"collaboration"* || "$lowered_action" == *"cross-post"* ]]; then
    (( score += 20 ))
  fi
  if [[ "$lowered_action" == *"reply"* ]]; then
    (( score += 10 ))
  fi
  if [[ "$lowered_action" == *"monday publish checklist"* || "$lowered_action" == *"posted status"* ]]; then
    (( score += 16 ))
  fi
  if [[ "$lowered_action" == *"docs/workflow"* || "$lowered_action" == *"docs update"* ]]; then
    (( score += 8 ))
  fi
  if [[ "$lowered_action" == *"win card"* || "$lowered_action" == *"install"* ]]; then
    (( score += 6 ))
  fi
  if [[ "$lowered_action" == *"owner-default"* || "$lowered_action" == *"owner default"* || "$lowered_action" == *"owner accountability"* ]]; then
    (( score += 18 ))
  fi
  if [[ "$lowered_action" == *"distribution owner"* || "$lowered_action" == *"touch-floor"* || "$lowered_action" == *"practical reply target"* ]]; then
    (( score += 14 ))
  fi

  if [[ "$lowered_action" == *"creator outreach"* || "$lowered_action" == *"collaboration"* || "$lowered_action" == *"cross-post"* ]]; then
    if [[ -n "$outreach_collab_rate_number" && "$(is_ge "$outreach_collab_rate_number" "10")" != "1" ]]; then
      (( score += 25 ))
    fi
    if [[ -n "$outreach_collab_rate_delta_number" && "$(is_ge "$outreach_collab_rate_delta_number" "0")" != "1" ]]; then
      (( score += 18 ))
    fi
    if [[ -n "$outreach_reply_rate_number" && "$(is_ge "$outreach_reply_rate_number" "20")" != "1" ]]; then
      (( score += 12 ))
    fi
    if [[ -n "$outreach_reply_rate_delta_number" && "$(is_ge "$outreach_reply_rate_delta_number" "0")" != "1" ]]; then
      (( score += 12 ))
    fi
  fi

  if [[ "$lowered_action" == *"reply"* ]]; then
    if [[ -n "$reply_pack_replies_delta_number" && "$(is_ge "$reply_pack_replies_delta_number" "0")" != "1" ]]; then
      (( score += 15 ))
    fi
  fi

  if [[ "$normalized_monday_post_status" != "posted" && "$lowered_action" == *"monday publish checklist"* ]]; then
    (( score += 20 ))
  fi

  echo "$score"
}

rank_priority_actions_by_lift() {
  local -a ranked_lines
  local action_line
  local action_score
  local action_index=0

  ranked_lines=()
  for action_line in "${priority_actions[@]}"; do
    action_score="$(score_priority_action_line "$action_line")"
    ranked_lines+=("$(printf '%04d|%04d|%s' "$action_score" "$action_index" "$action_line")")
    (( action_index += 1 ))
  done

  local sorted_lines
  local deduped_lines
  sorted_lines="$(printf '%s\n' "${ranked_lines[@]}" | sort -t'|' -k1,1nr -k2,2n)"
  deduped_lines="$(print -r -- "$sorted_lines" | awk -F'|' '!seen[$3]++')"

  priority_actions=()
  while IFS= read -r ranked_line; do
    [[ -z "$ranked_line" ]] && continue
    local payload="${ranked_line#*|}"
    payload="${payload#*|}"
    priority_actions+=("$payload")
  done <<< "$deduped_lines"
}

metric_lines=()
priority_actions=()
on_track_count=0
best_metric_label=""
best_metric_value=""
best_metric_value_display="n/a"
best_delta_label=""
best_delta_value=""
best_delta_display="n/a"

evaluate_metric() {
  local label="$1"
  local raw_value="$2"
  local raw_delta="$3"
  local target_value="$4"
  local missing_action="$5"
  local gap_action="$6"
  local parsed_value
  local parsed_delta
  local delta_display="n/a"

  parsed_value="$(extract_number "$raw_value")"
  parsed_delta="$(extract_number "$raw_delta")"
  if [[ -n "$parsed_delta" ]]; then
    delta_display="$(format_signed_number "$parsed_delta")"
    if [[ "$(is_ge "$parsed_delta" "0.000001")" == "1" ]]; then
      if [[ -z "$best_delta_value" || "$(is_ge "$parsed_delta" "$best_delta_value")" == "1" ]]; then
        best_delta_label="$label"
        best_delta_value="$parsed_delta"
        best_delta_display="$delta_display"
      fi
    fi
  fi

  if [[ -z "$parsed_value" ]]; then
    metric_lines+=("- ⚪ $label: n/a / target $target_value (WoW: $delta_display)")
    priority_actions+=("$missing_action")
    return
  fi

  local formatted_value
  local formatted_target
  formatted_value="$(format_number "$parsed_value")"
  formatted_target="$(format_number "$target_value")"

  if [[ -z "$best_metric_value" || "$(is_ge "$parsed_value" "$best_metric_value")" == "1" ]]; then
    best_metric_label="$label"
    best_metric_value="$parsed_value"
    best_metric_value_display="$formatted_value"
  fi

  if [[ "$(is_ge "$parsed_value" "$target_value")" == "1" ]]; then
    local over_target
    over_target="$(format_non_negative_gap "$target_value" "$parsed_value")"
    metric_lines+=("- ✅ $label: $formatted_value / target $formatted_target (+$over_target above target; WoW: $delta_display)")
    (( on_track_count += 1 ))
  else
    local gap
    gap="$(format_non_negative_gap "$parsed_value" "$target_value")"
    metric_lines+=("- ⚠️ $label: $formatted_value / target $formatted_target (need +$gap; WoW: $delta_display)")
    priority_actions+=("$gap_action (need +$gap).")
  fi
}

evaluate_metric \
  "Win Card copies" \
  "$win_card" \
  "$win_card_delta" \
  "$target_win_card" \
  "Add current Win Card count into the sprint issue before the review run." \
  "Show Win Card output in Monday and Friday posts to increase reuse"

evaluate_metric \
  "Win Recap copies" \
  "$win_recap" \
  "$win_recap_delta" \
  "$target_win_recap" \
  "Fill the Win Recap count so the review can score post-ready output." \
  "Reply with Copy Win Recap variants on practical questions"

evaluate_metric \
  "Public posts shipped" \
  "$posts" \
  "$posts_delta" \
  "$target_posts" \
  "Log shipped public posts in the sprint issue." \
  "Ship one extra post by repurposing the strongest proof asset"

evaluate_metric \
  "User-generated stories" \
  "$stories" \
  "$stories_delta" \
  "$target_stories" \
  "Log user story count in the sprint issue." \
  "Ask for one concrete user story in each reply thread"

evaluate_metric \
  "Inbound installs/trials" \
  "$installs" \
  "$installs_delta" \
  "$target_installs" \
  "Add inbound install/trial count to keep acquisition visible." \
  "Tighten CTA and include one direct install path in each post"

health_status="Recovery"
if (( on_track_count >= 5 )); then
  health_status="Exceptional"
elif (( on_track_count >= 3 )); then
  health_status="Solid"
fi

reply_pack_replies_number="$(extract_number "$reply_pack_replies")"
reply_pack_objections_number="$(extract_number "$reply_pack_objections")"
reply_pack_doc_updates_number="$(extract_number "$reply_pack_doc_updates")"
reply_pack_replies_delta_display="$(format_delta_display "$reply_pack_replies_delta")"
reply_pack_objections_delta_display="$(format_delta_display "$reply_pack_objections_delta")"
reply_pack_doc_updates_delta_display="$(format_delta_display "$reply_pack_doc_updates_delta")"
outreach_sent_number="$(extract_number "$outreach_sent")"
outreach_replies_number="$(extract_number "$outreach_replies")"
outreach_collabs_number="$(extract_number "$outreach_collabs")"
outreach_cross_posts_number="$(extract_number "$outreach_cross_posts")"
outreach_sent_delta_display="$(format_delta_display "$outreach_sent_delta")"
outreach_replies_delta_display="$(format_delta_display "$outreach_replies_delta")"
outreach_collabs_delta_display="$(format_delta_display "$outreach_collabs_delta")"
outreach_cross_posts_delta_display="$(format_delta_display "$outreach_cross_posts_delta")"
outreach_reply_rate_number="$(extract_number "$outreach_reply_rate")"
outreach_reply_rate_delta_number="$(extract_number "$outreach_reply_rate_delta")"
outreach_collab_rate_number="$(extract_number "$outreach_collab_rate")"
outreach_collab_rate_delta_number="$(extract_number "$outreach_collab_rate_delta")"
outreach_cross_post_rate_number="$(extract_number "$outreach_cross_post_rate")"
outreach_cross_post_rate_delta_number="$(extract_number "$outreach_cross_post_rate_delta")"
creator_signal_entries_number="$(extract_number "$creator_signal_entries")"
creator_signal_high_fit_number="$(extract_number "$creator_signal_high_fit")"
creator_signal_warm_intros_number="$(extract_number "$creator_signal_warm_intros")"
creator_signal_collab_ready_number="$(extract_number "$creator_signal_collab_ready")"
creator_signal_enrichment_score_number="$(extract_number "$creator_signal_enrichment_score")"
guesting_signal_entries_number="$(extract_number "$guesting_signal_entries")"
guesting_signal_replied_number="$(extract_number "$guesting_signal_replied")"
guesting_signal_booked_number="$(extract_number "$guesting_signal_booked")"
guesting_signal_published_number="$(extract_number "$guesting_signal_published")"
guesting_signal_enrichment_score_number="$(extract_number "$guesting_signal_enrichment_score")"
narrative_fame_velocity_score_number="$(extract_number "$narrative_fame_velocity_score")"
outreach_sprint_comment_entries_number="$(extract_number "$outreach_sprint_comment_entries")"
outreach_sprint_tasks_completed_number="$(extract_number "$outreach_sprint_tasks_completed")"
outreach_sprint_tasks_total_number="$(extract_number "$outreach_sprint_tasks_total")"
outreach_sprint_completion_rate_number="$(extract_number "$outreach_sprint_completion_rate")"
outreach_sprint_creator_tasks_completed_number="$(extract_number "$outreach_sprint_creator_tasks_completed")"
outreach_sprint_guesting_tasks_completed_number="$(extract_number "$outreach_sprint_guesting_tasks_completed")"
outreach_sprint_owner_defaults_tasks_completed_number="$(extract_number "$outreach_sprint_owner_defaults_tasks_completed")"
outreach_sprint_owner_defaults_tasks_total_number="$(extract_number "$outreach_sprint_owner_defaults_tasks_total")"
outreach_sprint_owner_defaults_completion_rate_number="$(extract_number "$outreach_sprint_owner_defaults_completion_rate")"
outreach_sprint_owner_default_creator_completed_number="$(extract_number "$outreach_sprint_owner_default_creator_completed")"
outreach_sprint_owner_default_guesting_completed_number="$(extract_number "$outreach_sprint_owner_default_guesting_completed")"
outreach_sprint_owner_default_distribution_completed_number="$(extract_number "$outreach_sprint_owner_default_distribution_completed")"
outreach_sprint_owner_default_ops_completed_number="$(extract_number "$outreach_sprint_owner_default_ops_completed")"
outreach_reply_rate_display="$(format_rate_display "$outreach_reply_rate")"
outreach_reply_rate_delta_display="$(format_rate_delta_display "$outreach_reply_rate_delta")"
outreach_collab_rate_display="$(format_rate_display "$outreach_collab_rate")"
outreach_collab_rate_delta_display="$(format_rate_delta_display "$outreach_collab_rate_delta")"
outreach_cross_post_rate_display="$(format_rate_display "$outreach_cross_post_rate")"
outreach_cross_post_rate_delta_display="$(format_rate_delta_display "$outreach_cross_post_rate_delta")"
creator_signal_entries_display="$creator_signal_entries"
creator_signal_entries_delta_display="$(format_delta_display "$creator_signal_entries_delta")"
creator_signal_high_fit_display="$creator_signal_high_fit"
creator_signal_high_fit_delta_display="$(format_delta_display "$creator_signal_high_fit_delta")"
creator_signal_warm_intros_display="$creator_signal_warm_intros"
creator_signal_warm_intros_delta_display="$(format_delta_display "$creator_signal_warm_intros_delta")"
creator_signal_collab_ready_display="$creator_signal_collab_ready"
creator_signal_collab_ready_delta_display="$(format_delta_display "$creator_signal_collab_ready_delta")"
creator_signal_enrichment_score_display="$creator_signal_enrichment_score"
creator_signal_enrichment_score_delta_display="$(format_rate_delta_display "$creator_signal_enrichment_score_delta")"
guesting_signal_entries_display="$guesting_signal_entries"
guesting_signal_entries_delta_display="$(format_delta_display "$guesting_signal_entries_delta")"
guesting_signal_replied_display="$guesting_signal_replied"
guesting_signal_replied_delta_display="$(format_delta_display "$guesting_signal_replied_delta")"
guesting_signal_booked_display="$guesting_signal_booked"
guesting_signal_booked_delta_display="$(format_delta_display "$guesting_signal_booked_delta")"
guesting_signal_published_display="$guesting_signal_published"
guesting_signal_published_delta_display="$(format_delta_display "$guesting_signal_published_delta")"
guesting_signal_enrichment_score_display="$guesting_signal_enrichment_score"
guesting_signal_enrichment_score_delta_display="$(format_rate_delta_display "$guesting_signal_enrichment_score_delta")"
narrative_route_winner_display="$(normalize_narrative_route "$narrative_route_winner")"
narrative_route_winner_delta_display="$narrative_route_winner_delta"
narrative_route_trend_display="$narrative_route_trend"
narrative_fame_velocity_score_display="$narrative_fame_velocity_score"
narrative_fame_velocity_score_delta_display="$(format_rate_delta_display "$narrative_fame_velocity_score_delta")"
narrative_route_mode_display="$narrative_route_mode"
narrative_route_alignment_target_display="$narrative_route_alignment_target"
narrative_route_lane_status_display="$narrative_route_lane_status"
narrative_route_guardrail_display="$narrative_route_guardrail"
narrative_route_control_recommendation_display="$narrative_route_control_recommendation"
narrative_distribution_strategy_display="$narrative_distribution_strategy"
narrative_distribution_day0_lead_display="$narrative_distribution_day0_lead"
narrative_distribution_day0_support_display="$narrative_distribution_day0_support"
narrative_distribution_recommendation_display="$narrative_distribution_recommendation"
narrative_distribution_first_48h_plan_display="$narrative_distribution_first_48h_plan"
outreach_sprint_comment_entries_display="$outreach_sprint_comment_entries"
outreach_sprint_comment_entries_delta_display="$(format_delta_display "$outreach_sprint_comment_entries_delta")"
outreach_sprint_tasks_completed_display="$outreach_sprint_tasks_completed"
outreach_sprint_tasks_completed_delta_display="$(format_delta_display "$outreach_sprint_tasks_completed_delta")"
outreach_sprint_tasks_total_display="$outreach_sprint_tasks_total"
outreach_sprint_completion_rate_display="$(format_rate_display "$outreach_sprint_completion_rate")"
outreach_sprint_completion_rate_delta_display="$(format_rate_delta_display "$outreach_sprint_completion_rate_delta")"
outreach_sprint_creator_tasks_completed_display="$outreach_sprint_creator_tasks_completed"
outreach_sprint_creator_tasks_completed_delta_display="$(format_delta_display "$outreach_sprint_creator_tasks_completed_delta")"
outreach_sprint_guesting_tasks_completed_display="$outreach_sprint_guesting_tasks_completed"
outreach_sprint_guesting_tasks_completed_delta_display="$(format_delta_display "$outreach_sprint_guesting_tasks_completed_delta")"
outreach_sprint_owner_defaults_tasks_completed_display="$outreach_sprint_owner_defaults_tasks_completed"
outreach_sprint_owner_defaults_tasks_completed_delta_display="$(format_delta_display "$outreach_sprint_owner_defaults_tasks_completed_delta")"
outreach_sprint_owner_defaults_tasks_total_display="$outreach_sprint_owner_defaults_tasks_total"
outreach_sprint_owner_defaults_completion_rate_display="$(format_rate_display "$outreach_sprint_owner_defaults_completion_rate")"
outreach_sprint_owner_defaults_completion_rate_delta_display="$(format_rate_delta_display "$outreach_sprint_owner_defaults_completion_rate_delta")"
outreach_sprint_owner_default_creator_completed_display="$(normalize_binary_completion "$outreach_sprint_owner_default_creator_completed")"
outreach_sprint_owner_default_creator_completed_delta_display="$(format_delta_display "$outreach_sprint_owner_default_creator_completed_delta")"
outreach_sprint_owner_default_guesting_completed_display="$(normalize_binary_completion "$outreach_sprint_owner_default_guesting_completed")"
outreach_sprint_owner_default_guesting_completed_delta_display="$(format_delta_display "$outreach_sprint_owner_default_guesting_completed_delta")"
outreach_sprint_owner_default_distribution_completed_display="$(normalize_binary_completion "$outreach_sprint_owner_default_distribution_completed")"
outreach_sprint_owner_default_distribution_completed_delta_display="$(format_delta_display "$outreach_sprint_owner_default_distribution_completed_delta")"
outreach_sprint_owner_default_ops_completed_display="$(normalize_binary_completion "$outreach_sprint_owner_default_ops_completed")"
outreach_sprint_owner_default_ops_completed_delta_display="$(format_delta_display "$outreach_sprint_owner_default_ops_completed_delta")"
outreach_sprint_variant_promoted_display="$outreach_sprint_variant_promoted"
outreach_sprint_outcomes_logged_display="$outreach_sprint_outcomes_logged"
outreach_sprint_preferred_lane_display="$outreach_sprint_preferred_lane"
normalized_primary_top_variant="$(normalize_variant_label "$primary_top_variant")"
normalized_backup_top_variant="$(normalize_variant_label "$backup_top_variant")"

reply_pack_replies_display="$reply_pack_replies"
reply_pack_objections_display="$reply_pack_objections"
reply_pack_doc_updates_display="$reply_pack_doc_updates"

if [[ -z "$reply_pack_replies_display" ]]; then
  reply_pack_replies_display="n/a"
fi
if [[ -z "$reply_pack_objections_display" ]]; then
  reply_pack_objections_display="n/a"
fi
if [[ -z "$reply_pack_doc_updates_display" ]]; then
  reply_pack_doc_updates_display="n/a"
fi

if [[ -n "$reply_pack_replies_number" ]]; then
  reply_pack_replies_display="$(format_number "$reply_pack_replies_number")"
fi
if [[ -n "$reply_pack_objections_number" ]]; then
  reply_pack_objections_display="$(format_number "$reply_pack_objections_number")"
fi
if [[ -n "$reply_pack_doc_updates_number" ]]; then
  reply_pack_doc_updates_display="$(format_number "$reply_pack_doc_updates_number")"
fi

outreach_sent_display="$outreach_sent"
outreach_replies_display="$outreach_replies"
outreach_collabs_display="$outreach_collabs"
outreach_cross_posts_display="$outreach_cross_posts"

if [[ -z "$outreach_sent_display" ]]; then
  outreach_sent_display="n/a"
fi
if [[ -z "$outreach_replies_display" ]]; then
  outreach_replies_display="n/a"
fi
if [[ -z "$outreach_collabs_display" ]]; then
  outreach_collabs_display="n/a"
fi
if [[ -z "$outreach_cross_posts_display" ]]; then
  outreach_cross_posts_display="n/a"
fi

if [[ -n "$outreach_sent_number" ]]; then
  outreach_sent_display="$(format_number "$outreach_sent_number")"
fi
if [[ -n "$outreach_replies_number" ]]; then
  outreach_replies_display="$(format_number "$outreach_replies_number")"
fi
if [[ -n "$outreach_collabs_number" ]]; then
  outreach_collabs_display="$(format_number "$outreach_collabs_number")"
fi
if [[ -n "$outreach_cross_posts_number" ]]; then
  outreach_cross_posts_display="$(format_number "$outreach_cross_posts_number")"
fi

if [[ -z "$creator_signal_entries_display" ]]; then
  creator_signal_entries_display="n/a"
fi
if [[ -z "$creator_signal_high_fit_display" ]]; then
  creator_signal_high_fit_display="n/a"
fi
if [[ -z "$creator_signal_warm_intros_display" ]]; then
  creator_signal_warm_intros_display="n/a"
fi
if [[ -z "$creator_signal_collab_ready_display" ]]; then
  creator_signal_collab_ready_display="n/a"
fi
if [[ -z "$creator_signal_enrichment_score_display" ]]; then
  creator_signal_enrichment_score_display="n/a"
fi

if [[ -n "$creator_signal_entries_number" ]]; then
  creator_signal_entries_display="$(format_number "$creator_signal_entries_number")"
fi
if [[ -n "$creator_signal_high_fit_number" ]]; then
  creator_signal_high_fit_display="$(format_number "$creator_signal_high_fit_number")"
fi
if [[ -n "$creator_signal_warm_intros_number" ]]; then
  creator_signal_warm_intros_display="$(format_number "$creator_signal_warm_intros_number")"
fi
if [[ -n "$creator_signal_collab_ready_number" ]]; then
  creator_signal_collab_ready_display="$(format_number "$creator_signal_collab_ready_number")"
fi
if [[ -n "$creator_signal_enrichment_score_number" ]]; then
  creator_signal_enrichment_score_display="$(format_rate_display "$creator_signal_enrichment_score_number")"
fi

if [[ -z "$guesting_signal_entries_display" ]]; then
  guesting_signal_entries_display="n/a"
fi
if [[ -z "$guesting_signal_replied_display" ]]; then
  guesting_signal_replied_display="n/a"
fi
if [[ -z "$guesting_signal_booked_display" ]]; then
  guesting_signal_booked_display="n/a"
fi
if [[ -z "$guesting_signal_published_display" ]]; then
  guesting_signal_published_display="n/a"
fi
if [[ -z "$guesting_signal_enrichment_score_display" ]]; then
  guesting_signal_enrichment_score_display="n/a"
fi
if [[ -z "$guesting_signal_top_format" ]]; then
  guesting_signal_top_format="n/a"
fi
if [[ -z "$guesting_signal_top_target" ]]; then
  guesting_signal_top_target="n/a"
fi

if [[ -n "$guesting_signal_entries_number" ]]; then
  guesting_signal_entries_display="$(format_number "$guesting_signal_entries_number")"
fi
if [[ -n "$guesting_signal_replied_number" ]]; then
  guesting_signal_replied_display="$(format_number "$guesting_signal_replied_number")"
fi
if [[ -n "$guesting_signal_booked_number" ]]; then
  guesting_signal_booked_display="$(format_number "$guesting_signal_booked_number")"
fi
if [[ -n "$guesting_signal_published_number" ]]; then
  guesting_signal_published_display="$(format_number "$guesting_signal_published_number")"
fi
if [[ -n "$guesting_signal_enrichment_score_number" ]]; then
  guesting_signal_enrichment_score_display="$(format_rate_display "$guesting_signal_enrichment_score_number")"
fi

if [[ -z "$narrative_route_winner_display" ]]; then
  narrative_route_winner_display="n/a"
fi
if [[ -z "$narrative_route_winner_delta_display" ]]; then
  narrative_route_winner_delta_display="n/a"
fi
if [[ -z "$narrative_route_trend_display" ]]; then
  narrative_route_trend_display="n/a"
fi
if [[ -z "$narrative_fame_velocity_score_display" ]]; then
  narrative_fame_velocity_score_display="n/a"
fi
if [[ -z "$narrative_launch_posture" ]]; then
  narrative_launch_posture="n/a"
fi
if [[ -z "$narrative_next_standup_action" ]]; then
  narrative_next_standup_action="n/a"
fi
if [[ -z "$narrative_route_mode_display" ]]; then
  narrative_route_mode_display="n/a"
fi
if [[ -z "$narrative_route_alignment_target_display" ]]; then
  narrative_route_alignment_target_display="n/a"
fi
if [[ -z "$narrative_route_lane_status_display" ]]; then
  narrative_route_lane_status_display="n/a"
fi
if [[ -z "$narrative_route_guardrail_display" ]]; then
  narrative_route_guardrail_display="n/a"
fi
if [[ -z "$narrative_distribution_strategy_display" ]]; then
  narrative_distribution_strategy_display="n/a"
fi
if [[ -z "$narrative_distribution_day0_lead_display" ]]; then
  narrative_distribution_day0_lead_display="n/a"
fi
if [[ -z "$narrative_distribution_day0_support_display" ]]; then
  narrative_distribution_day0_support_display="n/a"
fi
if [[ -n "$narrative_fame_velocity_score_number" ]]; then
  narrative_fame_velocity_score_display="$(format_rate_display "$narrative_fame_velocity_score_number")"
fi

if [[ -z "$outreach_sprint_comment_entries_display" ]]; then
  outreach_sprint_comment_entries_display="n/a"
fi
if [[ -z "$outreach_sprint_tasks_completed_display" ]]; then
  outreach_sprint_tasks_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_tasks_total_display" ]]; then
  outreach_sprint_tasks_total_display="n/a"
fi
if [[ -z "$outreach_sprint_completion_rate_display" ]]; then
  outreach_sprint_completion_rate_display="n/a"
fi
if [[ -z "$outreach_sprint_creator_tasks_completed_display" ]]; then
  outreach_sprint_creator_tasks_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_guesting_tasks_completed_display" ]]; then
  outreach_sprint_guesting_tasks_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_defaults_tasks_completed_display" ]]; then
  outreach_sprint_owner_defaults_tasks_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_defaults_tasks_total_display" ]]; then
  outreach_sprint_owner_defaults_tasks_total_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_defaults_completion_rate_display" ]]; then
  outreach_sprint_owner_defaults_completion_rate_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_default_creator_completed_display" ]]; then
  outreach_sprint_owner_default_creator_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_default_guesting_completed_display" ]]; then
  outreach_sprint_owner_default_guesting_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_default_distribution_completed_display" ]]; then
  outreach_sprint_owner_default_distribution_completed_display="n/a"
fi
if [[ -z "$outreach_sprint_owner_default_ops_completed_display" ]]; then
  outreach_sprint_owner_default_ops_completed_display="n/a"
fi
if [[ -n "$outreach_sprint_comment_entries_number" ]]; then
  outreach_sprint_comment_entries_display="$(format_number "$outreach_sprint_comment_entries_number")"
fi
if [[ -n "$outreach_sprint_tasks_completed_number" ]]; then
  outreach_sprint_tasks_completed_display="$(format_number "$outreach_sprint_tasks_completed_number")"
fi
if [[ -n "$outreach_sprint_tasks_total_number" ]]; then
  outreach_sprint_tasks_total_display="$(format_number "$outreach_sprint_tasks_total_number")"
fi
if [[ -n "$outreach_sprint_completion_rate_number" ]]; then
  outreach_sprint_completion_rate_display="$(format_rate_display "$outreach_sprint_completion_rate_number")"
fi
if [[ -n "$outreach_sprint_creator_tasks_completed_number" ]]; then
  outreach_sprint_creator_tasks_completed_display="$(format_number "$outreach_sprint_creator_tasks_completed_number")"
fi
if [[ -n "$outreach_sprint_guesting_tasks_completed_number" ]]; then
  outreach_sprint_guesting_tasks_completed_display="$(format_number "$outreach_sprint_guesting_tasks_completed_number")"
fi
if [[ -n "$outreach_sprint_owner_defaults_tasks_completed_number" ]]; then
  outreach_sprint_owner_defaults_tasks_completed_display="$(format_number "$outreach_sprint_owner_defaults_tasks_completed_number")"
fi
if [[ -n "$outreach_sprint_owner_defaults_tasks_total_number" ]]; then
  outreach_sprint_owner_defaults_tasks_total_display="$(format_number "$outreach_sprint_owner_defaults_tasks_total_number")"
fi
if [[ -n "$outreach_sprint_owner_defaults_completion_rate_number" ]]; then
  outreach_sprint_owner_defaults_completion_rate_display="$(format_rate_display "$outreach_sprint_owner_defaults_completion_rate_number")"
fi

normalized_outreach_sprint_lane="${outreach_sprint_preferred_lane_display:l}"
if [[ "$normalized_outreach_sprint_lane" != "creator" && "$normalized_outreach_sprint_lane" != "guesting" && "$normalized_outreach_sprint_lane" != "balanced" ]]; then
  normalized_outreach_sprint_lane="balanced"
fi
outreach_sprint_preferred_lane_display="$normalized_outreach_sprint_lane"

normalized_outreach_sprint_variant_promoted="${outreach_sprint_variant_promoted_display:l}"
if [[ -z "$normalized_outreach_sprint_variant_promoted" ]]; then
  normalized_outreach_sprint_variant_promoted="n/a"
fi
if [[ "$normalized_outreach_sprint_variant_promoted" == "true" || "$normalized_outreach_sprint_variant_promoted" == "1" ]]; then
  normalized_outreach_sprint_variant_promoted="yes"
fi
if [[ "$normalized_outreach_sprint_variant_promoted" == "false" || "$normalized_outreach_sprint_variant_promoted" == "0" ]]; then
  normalized_outreach_sprint_variant_promoted="no"
fi
if [[ "$normalized_outreach_sprint_variant_promoted" != "yes" && "$normalized_outreach_sprint_variant_promoted" != "no" && "$normalized_outreach_sprint_variant_promoted" != "n/a" ]]; then
  normalized_outreach_sprint_variant_promoted="n/a"
fi
outreach_sprint_variant_promoted_display="$normalized_outreach_sprint_variant_promoted"

normalized_outreach_sprint_outcomes_logged="${outreach_sprint_outcomes_logged_display:l}"
if [[ -z "$normalized_outreach_sprint_outcomes_logged" ]]; then
  normalized_outreach_sprint_outcomes_logged="n/a"
fi
if [[ "$normalized_outreach_sprint_outcomes_logged" == "true" || "$normalized_outreach_sprint_outcomes_logged" == "1" ]]; then
  normalized_outreach_sprint_outcomes_logged="yes"
fi
if [[ "$normalized_outreach_sprint_outcomes_logged" == "false" || "$normalized_outreach_sprint_outcomes_logged" == "0" ]]; then
  normalized_outreach_sprint_outcomes_logged="no"
fi
if [[ "$normalized_outreach_sprint_outcomes_logged" != "yes" && "$normalized_outreach_sprint_outcomes_logged" != "no" && "$normalized_outreach_sprint_outcomes_logged" != "n/a" ]]; then
  normalized_outreach_sprint_outcomes_logged="n/a"
fi
outreach_sprint_outcomes_logged_display="$normalized_outreach_sprint_outcomes_logged"

if [[ -z "$outreach_sprint_recommendation" ]]; then
  outreach_sprint_recommendation="Capture founder outreach sprint checklist updates in Monday checklist comments before Friday review."
fi

if [[ -n "$outreach_sprint_owner_defaults_completion_rate_number" ]]; then
  if [[ "$(is_ge "$outreach_sprint_owner_defaults_completion_rate_number" "50")" != "1" ]]; then
    outreach_sprint_recommendation="Lane owner defaults are mostly unchecked; assign creator/guesting/distribution/ops owners before Friday review so next-week routing stays accountable."
  elif [[ "$(is_ge "$outreach_sprint_owner_defaults_completion_rate_number" "100")" != "1" ]]; then
    outreach_sprint_recommendation="Close remaining lane owner-default checklist tasks before Friday review so outreach ownership is explicit across all lanes."
  fi
fi

if [[ "$outreach_sprint_owner_default_distribution_completed_display" == "no" ]]; then
  outreach_sprint_recommendation="Distribution owner default is unchecked; enforce daily touch floor and practical reply target by Day 2 before scaling outreach lanes."
elif [[ "$outreach_sprint_owner_default_ops_completed_display" == "no" ]]; then
  outreach_sprint_recommendation="Ops owner default is unchecked; update lane owner handles and progress in the owner-default block before Friday review."
elif [[ "$outreach_sprint_owner_default_creator_completed_display" == "no" || "$outreach_sprint_owner_default_guesting_completed_display" == "no" ]]; then
  outreach_sprint_recommendation="Creator/guesting owner defaults are incomplete; assign owners and close lane-default tasks before Friday review."
fi

if [[ -z "$outreach_reply_rate_number" && -n "$outreach_sent_number" && -n "$outreach_replies_number" && "$(is_ge "$outreach_sent_number" "0.000001")" == "1" ]]; then
  outreach_reply_rate_number="$(awk -v replies="$outreach_replies_number" -v sent="$outreach_sent_number" 'BEGIN { printf "%.4f", ((replies + 0) / (sent + 0)) * 100 }')"
  outreach_reply_rate_display="$(format_rate_display "$outreach_reply_rate_number")"
fi

if [[ -z "$outreach_collab_rate_number" && -n "$outreach_sent_number" && -n "$outreach_collabs_number" && "$(is_ge "$outreach_sent_number" "0.000001")" == "1" ]]; then
  outreach_collab_rate_number="$(awk -v collabs="$outreach_collabs_number" -v sent="$outreach_sent_number" 'BEGIN { printf "%.4f", ((collabs + 0) / (sent + 0)) * 100 }')"
  outreach_collab_rate_display="$(format_rate_display "$outreach_collab_rate_number")"
fi

if [[ -z "$outreach_cross_post_rate_number" && -n "$outreach_sent_number" && -n "$outreach_cross_posts_number" && "$(is_ge "$outreach_sent_number" "0.000001")" == "1" ]]; then
  outreach_cross_post_rate_number="$(awk -v cross_posts="$outreach_cross_posts_number" -v sent="$outreach_sent_number" 'BEGIN { printf "%.4f", ((cross_posts + 0) / (sent + 0)) * 100 }')"
  outreach_cross_post_rate_display="$(format_rate_display "$outreach_cross_post_rate_number")"
fi

primary_channel_roi_score_number="$(extract_number "$primary_channel_roi_score")"
backup_channel_roi_score_number="$(extract_number "$backup_channel_roi_score")"
primary_channel_roi_score_display="n/a"
backup_channel_roi_score_display="n/a"
distribution_days_completed_number="$(extract_number "$distribution_days_completed")"
distribution_days_completed_display="$distribution_days_completed"
distribution_days_completed_delta_display="$(format_delta_display "$distribution_days_completed_delta")"
distribution_completion_score_number="$(extract_number "$distribution_completion_score")"
distribution_completion_score_display="$distribution_completion_score"
distribution_completion_score_delta_display="$(format_rate_delta_display "$distribution_completion_score_delta")"

if [[ -n "$primary_channel_roi_score_number" ]]; then
  primary_channel_roi_score_display="$(format_number "$primary_channel_roi_score_number")"
elif [[ -n "$primary_channel_roi_score" ]]; then
  primary_channel_roi_score_display="$primary_channel_roi_score"
fi

if [[ -n "$backup_channel_roi_score_number" ]]; then
  backup_channel_roi_score_display="$(format_number "$backup_channel_roi_score_number")"
elif [[ -n "$backup_channel_roi_score" ]]; then
  backup_channel_roi_score_display="$backup_channel_roi_score"
fi

if [[ -z "$distribution_days_completed_display" ]]; then
  distribution_days_completed_display="n/a"
fi
if [[ "${distribution_days_completed_display:l}" == "n/a/n/a" ]]; then
  distribution_days_completed_display="n/a"
fi
if [[ "$distribution_days_completed_display" == "n/a" && -n "$distribution_days_completed_number" ]]; then
  distribution_days_completed_display="$(format_number "$distribution_days_completed_number")"
fi

if [[ -n "$distribution_completion_score_number" ]]; then
  distribution_completion_score_display="$(format_rate_display "$distribution_completion_score_number")"
elif [[ -z "$distribution_completion_score_display" ]]; then
  distribution_completion_score_display="n/a"
fi

channel_roi_preferred_channel="$(normalize_channel_preference "$channel_roi_recommendation")"
if [[ -n "$primary_channel_roi_score_number" && -n "$backup_channel_roi_score_number" ]]; then
  channel_roi_gap="$(awk -v primary_score="$primary_channel_roi_score_number" -v backup_score="$backup_channel_roi_score_number" 'BEGIN { printf "%.4f", (primary_score + 0) - (backup_score + 0) }')"
  if [[ "$(is_ge "$channel_roi_gap" "8")" == "1" ]]; then
    channel_roi_preferred_channel="primary"
  elif [[ "$(is_le "$channel_roi_gap" "-8")" == "1" ]]; then
    channel_roi_preferred_channel="backup"
  else
    channel_roi_preferred_channel="balanced"
  fi
fi

if [[ -z "$channel_roi_recommendation" ]]; then
  channel_roi_recommendation="$(build_channel_roi_recommendation "$primary_channel_roi_score_number" "$backup_channel_roi_score_number" "$channel_roi_preferred_channel" "$normalized_primary_top_variant" "$normalized_backup_top_variant")"
fi

if [[ -z "$channel_mix_recommendation" ]]; then
  channel_mix_recommendation="$(build_channel_mix_recommendation "$channel_roi_preferred_channel" "$distribution_completion_score" "$distribution_completion_score_delta" "$normalized_monday_post_status" "$reply_pack_replies_delta" "$outreach_reply_rate_delta")"
fi

if [[ -z "$creator_signal_recommendation" ]]; then
  if [[ -n "$creator_signal_enrichment_score_number" && "$(is_ge "$creator_signal_enrichment_score_number" "60")" == "1" ]]; then
    creator_signal_recommendation="Prioritize high-fit creator handles first and personalize intros with workflow-specific proof."
  elif [[ -n "$creator_signal_entries_number" && "$(is_ge "$creator_signal_entries_number" "1")" == "1" ]]; then
    creator_signal_recommendation="Increase fit scoring depth and add warm-intro pathways for top creator targets."
  else
    creator_signal_recommendation="Capture at least 5 creator signal comments in Monday checklist to unlock enrichment routing."
  fi
fi

if [[ -z "$guesting_signal_recommendation" ]]; then
  if [[ -n "$guesting_signal_enrichment_score_number" && "$(is_ge "$guesting_signal_enrichment_score_number" "75")" == "1" ]]; then
    guesting_signal_recommendation="Prioritize booked/published guesting targets first and scale the top-performing format this week."
  elif [[ -n "$guesting_signal_booked_number" && "$(is_ge "$guesting_signal_booked_number" "2")" == "1" ]]; then
    guesting_signal_recommendation="Double down on booked guesting slots and turn replies into confirmed calendar holds."
  elif [[ -n "$guesting_signal_entries_number" && "$(is_ge "$guesting_signal_entries_number" "3")" == "1" ]]; then
    guesting_signal_recommendation="Increase booked conversion by tightening follow-up cadence on replied targets."
  else
    guesting_signal_recommendation="Capture at least 5 founder guesting signal comments to prioritize interview and newsletter targets."
  fi
fi

if [[ -z "$narrative_route_recommendation" ]]; then
  narrative_route_recommendation="$(build_narrative_route_recommendation "$narrative_route_winner_display" "$narrative_route_trend_display" "$narrative_fame_velocity_score_display" "$narrative_launch_posture" "$narrative_next_standup_action")"
fi

if [[ -z "$narrative_route_control_recommendation_display" ]]; then
  narrative_route_control_recommendation_display="$(build_narrative_route_control_recommendation "$narrative_route_mode_display" "$narrative_route_lane_status_display" "$narrative_route_alignment_target_display" "$narrative_route_guardrail_display" "$narrative_route_winner_display" "$narrative_next_standup_action")"
fi
if [[ -z "$narrative_route_control_recommendation_display" ]]; then
  narrative_route_control_recommendation_display="n/a"
fi

if [[ -z "$narrative_distribution_recommendation_display" ]]; then
  narrative_distribution_recommendation_display="$(build_narrative_distribution_recommendation "$narrative_distribution_strategy_display" "$narrative_distribution_day0_lead_display" "$narrative_distribution_day0_support_display" "$narrative_route_mode_display" "$narrative_route_lane_status_display")"
fi
if [[ -z "$narrative_distribution_recommendation_display" ]]; then
  narrative_distribution_recommendation_display="Capture 7-day distribution calendar fields in founder narrative lab before Friday review."
fi

if [[ -z "$narrative_distribution_first_48h_plan_display" ]]; then
  narrative_distribution_first_48h_plan_display="$(build_narrative_distribution_first_48h_plan "$narrative_distribution_strategy_display" "$narrative_distribution_day0_lead_display" "$narrative_distribution_day0_support_display" "$narrative_route_mode_display" "$narrative_route_lane_status_display")"
fi
if [[ -z "$narrative_distribution_first_48h_plan_display" ]]; then
  narrative_distribution_first_48h_plan_display="Capture Day 0 lead/support lanes first, then script Day 1 proof recap and Day 2 objection-breaker follow-up."
fi

if [[ -n "$outreach_sprint_completion_rate_number" ]]; then
  if [[ "$(is_ge "$outreach_sprint_completion_rate_number" "85")" == "1" ]]; then
    if [[ "$outreach_sprint_preferred_lane_display" == "creator" ]]; then
      creator_signal_recommendation="Outreach sprint execution is strong on creator lane; prioritize top-segment creator handles first and keep warm-intro follow-ups daily."
    elif [[ "$outreach_sprint_preferred_lane_display" == "guesting" ]]; then
      guesting_signal_recommendation="Outreach sprint execution is strong on guesting lane; prioritize booked/published targets first and preserve creator maintenance touches."
    fi
  elif [[ "$(is_ge "$outreach_sprint_completion_rate_number" "50")" != "1" ]]; then
    creator_signal_recommendation="Outreach sprint completion is below 50%; focus on closing creator checklist actions before opening new creator targets."
    guesting_signal_recommendation="Outreach sprint completion is below 50%; close guesting checklist actions before expanding booking targets."
  fi
fi

reply_pack_replies_delta_number="$(extract_number "$reply_pack_replies_delta")"
primary_variant_for_next_week="$normalized_primary_top_variant"
backup_variant_for_next_week="$normalized_backup_top_variant"

if [[ "$primary_variant_for_next_week" == "n/a" ]]; then
  if [[ -n "$reply_pack_replies_delta_number" && "$(is_ge "$reply_pack_replies_delta_number" "0")" != "1" ]]; then
    primary_variant_for_next_week="B"
  else
    primary_variant_for_next_week="A"
  fi
fi

if [[ "$backup_variant_for_next_week" == "n/a" ]]; then
  if [[ -n "$reply_pack_replies_delta_number" && "$(is_ge "$reply_pack_replies_delta_number" "0")" != "1" ]]; then
    backup_variant_for_next_week="B"
  elif [[ "$primary_variant_for_next_week" == "A" ]]; then
    backup_variant_for_next_week="B"
  else
    backup_variant_for_next_week="A"
  fi
fi

if [[ -z "$variant_recommendation" ]]; then
  variant_recommendation="$(build_variant_recommendation "$normalized_primary_top_variant" "$normalized_backup_top_variant" "$reply_pack_replies_delta")"
fi

if [[ -z "$outreach_recommendation" ]]; then
  outreach_recommendation="$(build_outreach_recommendation "$outreach_sent" "$outreach_replies" "$outreach_collabs" "$outreach_cross_posts" "$outreach_replies_delta" "$outreach_collabs_delta" "$outreach_reply_rate" "$outreach_collab_rate" "$outreach_reply_rate_delta" "$outreach_collab_rate_delta")"
fi

if [[ -n "$outreach_sprint_completion_rate_number" ]]; then
  if [[ "$(is_ge "$outreach_sprint_completion_rate_number" "50")" != "1" ]]; then
    outreach_recommendation="Close unchecked founder outreach sprint checklist items before expanding new creator and guesting targets."
  elif [[ "$outreach_sprint_owner_default_distribution_completed_display" == "no" ]]; then
    outreach_recommendation="Distribution owner default is unchecked; enforce daily touch floor and practical reply target by Day 2 before expanding outreach lanes."
  elif [[ "$outreach_sprint_owner_default_ops_completed_display" == "no" ]]; then
    outreach_recommendation="Ops owner default is unchecked; update owner handles and progress in the lane defaults block before Friday review."
  elif [[ "$outreach_sprint_owner_default_creator_completed_display" == "no" || "$outreach_sprint_owner_default_guesting_completed_display" == "no" ]]; then
    outreach_recommendation="Creator/guesting owner defaults are incomplete; assign owners and close owner-default checklist tasks before scaling new outreach lanes."
  elif [[ -n "$outreach_sprint_owner_defaults_completion_rate_number" && "$(is_ge "$outreach_sprint_owner_defaults_completion_rate_number" "100")" != "1" ]]; then
    outreach_recommendation="Close remaining lane owner-default checklist tasks before Friday review so next-week routing has clear ownership."
  elif [[ "$outreach_sprint_variant_promoted_display" != "yes" ]]; then
    variant_recommendation="Promote one winning outreach script variant from this week into Monday defaults before launch."
  elif [[ "$outreach_sprint_preferred_lane_display" == "creator" && "$(is_ge "$outreach_sprint_completion_rate_number" "75")" == "1" ]]; then
    outreach_recommendation="Creator lane outperformed this week; run creator-first outreach sequencing and keep one guesting booking wave."
  elif [[ "$outreach_sprint_preferred_lane_display" == "guesting" && "$(is_ge "$outreach_sprint_completion_rate_number" "75")" == "1" ]]; then
    outreach_recommendation="Guesting lane outperformed this week; run booking-first outreach sequencing and keep creator follow-up cadence active."
  fi
fi

if [[ -z "$primary_variant_win_trend" ]]; then
  primary_variant_win_trend="n/a"
fi

if [[ -z "$backup_variant_win_trend" ]]; then
  backup_variant_win_trend="n/a"
fi

if [[ "$channel_roi_preferred_channel" == "primary" ]]; then
  priority_actions+=("Lead Monday publish with the primary channel first, then reuse the backup channel for reinforcement replies.")
elif [[ "$channel_roi_preferred_channel" == "backup" ]]; then
  priority_actions+=("Lead Monday publish with the backup channel first, then repost to primary after early engagement.")
fi

if [[ "$normalized_monday_post_status" != "posted" ]]; then
  priority_actions+=("Close Monday publish checklist with explicit \"posted\" status by end of Monday.")
fi

if [[ -n "$reply_pack_replies_number" && "$(is_ge "$reply_pack_replies_number" "3")" != "1" ]]; then
  priority_actions+=("Raise first-24h replies to at least 3 by using the reply pack in live threads.")
fi

if [[ -n "$reply_pack_objections_number" && "$(is_ge "$reply_pack_objections_number" "1")" == "1" ]]; then
  if [[ -z "$reply_pack_doc_updates_number" || "$(is_ge "$reply_pack_doc_updates_number" "$reply_pack_objections_number")" != "1" ]]; then
    priority_actions+=("Convert each captured objection into a docs/workflow update before Friday review.")
  fi
fi

if [[ "$normalized_primary_top_variant" == "n/a" || "$normalized_backup_top_variant" == "n/a" ]]; then
  priority_actions+=("Log primary/backup top variant labels (A/B/C) in Monday checklist to sharpen next-week replies.")
fi

if [[ -n "$outreach_sent_number" && "$(is_ge "$outreach_sent_number" "5")" != "1" ]]; then
  priority_actions+=("Send at least 5 targeted creator outreach messages in the Monday window.")
fi

if [[ -n "$outreach_replies_number" && "$(is_ge "$outreach_replies_number" "1")" != "1" ]]; then
  priority_actions+=("Tune creator outreach hook to secure at least one creator reply this week.")
fi

if [[ -n "$outreach_collabs_number" && "$(is_ge "$outreach_collabs_number" "1")" != "1" ]]; then
  priority_actions+=("Convert creator replies into one concrete collaboration ask before Friday.")
fi

if [[ -n "$outreach_cross_posts_number" && "$(is_ge "$outreach_cross_posts_number" "1")" != "1" ]]; then
  priority_actions+=("Secure one community cross-post to widen top-of-funnel visibility.")
fi

if [[ -n "$outreach_sprint_tasks_completed_number" && -n "$outreach_sprint_tasks_total_number" ]]; then
  if [[ "$(is_ge "$outreach_sprint_tasks_total_number" "1")" == "1" && "$(is_ge "$outreach_sprint_tasks_completed_number" "$outreach_sprint_tasks_total_number")" != "1" ]]; then
    priority_actions+=("Close unchecked founder outreach sprint checklist tasks to keep Friday ranking defaults grounded in execution.")
  fi
fi

if [[ "$outreach_sprint_variant_promoted_display" == "no" ]]; then
  priority_actions+=("Promote one winning outreach script variant into next-week defaults before Monday publish.")
fi

if [[ "$outreach_sprint_outcomes_logged_display" == "no" ]]; then
  priority_actions+=("Log founder outreach sprint outcomes in Monday checklist comments before Friday review run.")
fi

if [[ -n "$outreach_sprint_owner_defaults_tasks_completed_number" && -n "$outreach_sprint_owner_defaults_tasks_total_number" ]]; then
  if [[ "$(is_ge "$outreach_sprint_owner_defaults_tasks_total_number" "1")" == "1" && "$(is_ge "$outreach_sprint_owner_defaults_tasks_completed_number" "$outreach_sprint_owner_defaults_tasks_total_number")" != "1" ]]; then
    priority_actions+=("Close remaining lane owner-default checklist tasks so creator/guesting/distribution/ops ownership is explicit before Friday review.")
  fi
fi

if [[ "$outreach_sprint_owner_default_creator_completed_display" == "no" ]]; then
  priority_actions+=("Assign a creator lane owner and close creator owner-default tasks before Friday review.")
fi

if [[ "$outreach_sprint_owner_default_guesting_completed_display" == "no" ]]; then
  priority_actions+=("Assign a guesting lane owner and close guesting owner-default tasks before Friday review.")
fi

if [[ "$outreach_sprint_owner_default_distribution_completed_display" == "no" ]]; then
  priority_actions+=("Assign distribution owner accountability and enforce daily touch-floor + practical reply targets by Day 2.")
fi

if [[ "$outreach_sprint_owner_default_ops_completed_display" == "no" ]]; then
  priority_actions+=("Assign ops owner accountability and update lane owner handles/progress before Friday review.")
fi

if [[ "$outreach_sprint_preferred_lane_display" == "creator" && -n "$outreach_sprint_completion_rate_number" && "$(is_ge "$outreach_sprint_completion_rate_number" "75")" == "1" ]]; then
  priority_actions+=("Bias next-week routing to creator-first lane while preserving one guesting booking sequence.")
fi

if [[ "$outreach_sprint_preferred_lane_display" == "guesting" && -n "$outreach_sprint_completion_rate_number" && "$(is_ge "$outreach_sprint_completion_rate_number" "75")" == "1" ]]; then
  priority_actions+=("Bias next-week routing to guesting-first lane while keeping creator follow-up cadence active.")
fi

if [[ -n "$guesting_signal_entries_number" && "$(is_ge "$guesting_signal_entries_number" "3")" != "1" ]]; then
  priority_actions+=("Capture at least 3 founder guesting signal entries in Monday checklist comments.")
fi

if [[ -n "$guesting_signal_replied_number" && "$(is_ge "$guesting_signal_replied_number" "2")" != "1" ]]; then
  priority_actions+=("Raise founder guesting replied targets to at least 2 with tighter follow-up cadence.")
fi

if [[ -n "$guesting_signal_booked_number" && "$(is_ge "$guesting_signal_booked_number" "1")" != "1" ]]; then
  priority_actions+=("Convert founder guesting replies into one booked slot before Friday.")
fi

if [[ "$narrative_route_winner_display" == "n/a" ]]; then
  priority_actions+=("Capture founder narrative lab comment with priority route + fame velocity score before Friday review.")
fi

if [[ "${narrative_route_mode_display:l}" == *"recovery"* || "${narrative_route_lane_status_display:l}" == *"critical"* || "${narrative_route_lane_status_display:l}" == *"drifting"* ]]; then
  priority_actions+=("Execute route recovery mode immediately and resolve route lane issues before scaling new narrative variants.")
fi

if [[ "${narrative_route_mode_display:l}" == *"re-lock"* || "${narrative_route_lane_status_display:l}" == *"watch"* || "${narrative_route_lane_status_display:l}" == *"partial"* ]]; then
  priority_actions+=("Run route re-lock sequence and restore alignment target ${narrative_route_alignment_target_display} before next publish cycle.")
fi

if [[ "${narrative_route_trend_display:l}" == shifted\ from* ]]; then
  priority_actions+=("Validate shifted founder narrative route winner with two proof-backed posts before locking next-week defaults.")
fi

if [[ -n "$narrative_fame_velocity_score_number" && "$(is_ge "$narrative_fame_velocity_score_number" "70")" != "1" ]]; then
  priority_actions+=("Raise founder fame velocity score above 70% by running one Route Remix Matrix fallback this week.")
fi

if [[ -n "$distribution_days_completed_number" && "$(is_ge "$distribution_days_completed_number" "5")" != "1" ]]; then
  priority_actions+=("Complete at least 5 distribution follow-up days before Friday review to improve channel momentum.")
fi

if [[ -n "$distribution_completion_score_number" && "$(is_ge "$distribution_completion_score_number" "75")" != "1" ]]; then
  priority_actions+=("Raise distribution completion score above 75% by closing Day-0 to Day-4 follow-up tasks.")
fi

fallback_actions=(
  "Keep Monday/Wednesday/Friday cadence and preserve fast reply speed."
  "Reuse the top-performing hook in next Monday's before/after post."
  "Open one Win story issue from the best user response."
)

for fallback_action in "${fallback_actions[@]}"; do
  if (( ${#priority_actions[@]} >= 3 )); then
    break
  fi
  priority_actions+=("$fallback_action")
done

rank_priority_actions_by_lift

if [[ -z "$best_metric_label" ]]; then
  best_metric_label="Win Card copies"
fi

command_for_scripts="Copy Win Card"
if [[ "${best_metric_label:l}" == *"recap"* ]]; then
  command_for_scripts="Copy Win Recap"
fi

strongest_metric_line="$best_metric_label reached $best_metric_value_display this sprint."
primary_channel_script="$(build_variant_script "$primary_variant_for_next_week" "$primary_channel" "$command_for_scripts" "$strongest_metric_line" "$metric_focus")"
backup_channel_script="$(build_variant_script "$backup_variant_for_next_week" "$backup_channel" "$command_for_scripts" "$strongest_metric_line" "$metric_focus")"
default_primary_channel_label="$primary_channel"
default_primary_variant_for_next_week="$primary_variant_for_next_week"
default_primary_channel_script="$primary_channel_script"
default_backup_channel_label="$backup_channel"
default_backup_variant_for_next_week="$backup_variant_for_next_week"
default_backup_channel_script="$backup_channel_script"

if [[ "$channel_roi_preferred_channel" == "backup" ]]; then
  default_primary_channel_label="$backup_channel"
  default_primary_variant_for_next_week="$backup_variant_for_next_week"
  default_primary_channel_script="$backup_channel_script"
  default_backup_channel_label="$primary_channel"
  default_backup_variant_for_next_week="$primary_variant_for_next_week"
  default_backup_channel_script="$primary_channel_script"
fi

hook_line_one="Lead next week with \"$best_metric_label\" proof (${best_metric_value_display} this sprint)."
hook_line_two="Center messaging on \"$metric_focus\" and keep command steps explicit."
hook_line_three="Run one CTA experiment: \"Try this exact flow\" vs \"Share your first Win Card\"."

if [[ -n "$best_delta_label" ]]; then
  hook_line_two="Highlight momentum: $best_delta_label improved $best_delta_display WoW."
fi

if [[ "$channel_roi_preferred_channel" == "backup" ]]; then
  hook_line_three="Open Monday on backup channel first (higher ROI), then cross-post to primary after first replies."
elif [[ "$channel_roi_preferred_channel" == "primary" ]]; then
  hook_line_three="Open Monday on primary channel first (higher ROI), then use backup channel for reinforcement."
fi

if [[ -n "$outreach_sprint_completion_rate_number" && "$(is_ge "$outreach_sprint_completion_rate_number" "75")" == "1" ]]; then
  if [[ "$outreach_sprint_preferred_lane_display" == "creator" ]]; then
    hook_line_three="Open Monday with creator-first outreach proof, then fold guesting booking wins into Day-3 reinforcement."
  elif [[ "$outreach_sprint_preferred_lane_display" == "guesting" ]]; then
    hook_line_three="Open Monday with booking-first guesting proof, then run creator follow-up wave by Day 2."
  fi
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

{
  echo "<!-- weekly-growth-review -->"
  echo
  echo "## Weekly Growth Review: $week"
  echo
  echo "Generated: $generated_on"
  echo "Metric focus: $metric_focus"
  echo
  echo "### Scorecard"
  echo
  echo "- Sprint health: **$health_status** ($on_track_count/5 targets on track)"
  for metric_line in "${metric_lines[@]}"; do
    echo "$metric_line"
  done
  echo
  echo "### Reply Pack Effectiveness"
  echo
  echo "- Source week: $monday_source_week"
  echo "- Monday post status: $normalized_monday_post_status"
  echo "- Replies sent (first 24h): $reply_pack_replies_display (Δ $reply_pack_replies_delta_display)"
  echo "- Objections captured (first 24h): $reply_pack_objections_display (Δ $reply_pack_objections_delta_display)"
  echo "- Docs/workflow updates from replies: $reply_pack_doc_updates_display (Δ $reply_pack_doc_updates_delta_display)"
  echo "- Primary channel top variant: $normalized_primary_top_variant"
  echo "- Backup channel top variant: $normalized_backup_top_variant"
  echo "- Primary variant trendline: $primary_variant_win_trend"
  echo "- Backup variant trendline: $backup_variant_win_trend"
  echo "- Next-week variant recommendation: $variant_recommendation"
  echo
  echo "### Creator Outreach Effectiveness"
  echo
  echo "- Creator outreach sent: $outreach_sent_display (Δ $outreach_sent_delta_display)"
  echo "- Creator outreach replies: $outreach_replies_display (Δ $outreach_replies_delta_display)"
  echo "- Creator collaborations: $outreach_collabs_display (Δ $outreach_collabs_delta_display)"
  echo "- Community cross-posts: $outreach_cross_posts_display (Δ $outreach_cross_posts_delta_display)"
  echo "- Creator reply rate: $outreach_reply_rate_display (Δ $outreach_reply_rate_delta_display)"
  echo "- Creator collaboration rate: $outreach_collab_rate_display (Δ $outreach_collab_rate_delta_display)"
  echo "- Community cross-post rate: $outreach_cross_post_rate_display (Δ $outreach_cross_post_rate_delta_display)"
  echo "- Next-week outreach recommendation: $outreach_recommendation"
  echo
  echo "### Creator Account Enrichment"
  echo
  echo "- Creator signal entries: $creator_signal_entries_display (Δ $creator_signal_entries_delta_display)"
  echo "- High-fit creator signals: $creator_signal_high_fit_display (Δ $creator_signal_high_fit_delta_display)"
  echo "- Warm-intro creator signals: $creator_signal_warm_intros_display (Δ $creator_signal_warm_intros_delta_display)"
  echo "- Collab-ready creator signals: $creator_signal_collab_ready_display (Δ $creator_signal_collab_ready_delta_display)"
  echo "- Top creator signal segment: $creator_signal_top_segment"
  echo "- Priority creator handle: $creator_signal_top_handle"
  echo "- Creator enrichment score: $creator_signal_enrichment_score_display (Δ $creator_signal_enrichment_score_delta_display)"
  echo "- Creator signal recommendation: $creator_signal_recommendation"
  echo
  echo "### Founder Guesting Enrichment"
  echo
  echo "- Founder guesting signal entries: $guesting_signal_entries_display (Δ $guesting_signal_entries_delta_display)"
  echo "- Founder guesting replied: $guesting_signal_replied_display (Δ $guesting_signal_replied_delta_display)"
  echo "- Founder guesting booked: $guesting_signal_booked_display (Δ $guesting_signal_booked_delta_display)"
  echo "- Founder guesting published: $guesting_signal_published_display (Δ $guesting_signal_published_delta_display)"
  echo "- Founder guesting top format: $guesting_signal_top_format"
  echo "- Founder guesting top target: $guesting_signal_top_target"
  echo "- Founder guesting enrichment score: $guesting_signal_enrichment_score_display (Δ $guesting_signal_enrichment_score_delta_display)"
  echo "- Founder guesting recommendation: $guesting_signal_recommendation"
  echo
  echo "### Founder Narrative Route Signals"
  echo
  echo "- Founder narrative route winner: $narrative_route_winner_display (Δ $narrative_route_winner_delta_display)"
  echo "- Founder narrative route trend: $narrative_route_trend_display"
  echo "- Founder narrative fame velocity score: $narrative_fame_velocity_score_display (Δ $narrative_fame_velocity_score_delta_display)"
  echo "- Founder narrative launch posture: $narrative_launch_posture"
  echo "- Founder narrative route mode: $narrative_route_mode_display"
  echo "- Founder narrative route alignment target: $narrative_route_alignment_target_display"
  echo "- Founder narrative route lane status: $narrative_route_lane_status_display"
  echo "- Founder narrative route guardrail: $narrative_route_guardrail_display"
  echo "- Founder narrative next standup action: $narrative_next_standup_action"
  echo "- Founder narrative route control recommendation: $narrative_route_control_recommendation_display"
  echo "- Founder narrative recommendation: $narrative_route_recommendation"
  echo "- Founder narrative distribution strategy: $narrative_distribution_strategy_display"
  echo "- Founder narrative Day 0 lead lane: $narrative_distribution_day0_lead_display"
  echo "- Founder narrative Day 0 support lane: $narrative_distribution_day0_support_display"
  echo "- Founder narrative distribution recommendation: $narrative_distribution_recommendation_display"
  echo "- Founder narrative first 48h execution plan: $narrative_distribution_first_48h_plan_display"
  echo
  echo "### Founder Outreach Sprint Outcomes"
  echo
  echo "- Outreach sprint comments: $outreach_sprint_comment_entries_display (Δ $outreach_sprint_comment_entries_delta_display)"
  echo "- Outreach sprint checklist completion: $outreach_sprint_tasks_completed_display/$outreach_sprint_tasks_total_display (Δ $outreach_sprint_tasks_completed_delta_display)"
  echo "- Outreach sprint completion rate: $outreach_sprint_completion_rate_display (Δ $outreach_sprint_completion_rate_delta_display)"
  echo "- Creator-focused tasks completed: $outreach_sprint_creator_tasks_completed_display (Δ $outreach_sprint_creator_tasks_completed_delta_display)"
  echo "- Guesting-focused tasks completed: $outreach_sprint_guesting_tasks_completed_display (Δ $outreach_sprint_guesting_tasks_completed_delta_display)"
  echo "- Owner-default tasks completed: $outreach_sprint_owner_defaults_tasks_completed_display/$outreach_sprint_owner_defaults_tasks_total_display (Δ $outreach_sprint_owner_defaults_tasks_completed_delta_display)"
  echo "- Owner-default completion rate: $outreach_sprint_owner_defaults_completion_rate_display (Δ $outreach_sprint_owner_defaults_completion_rate_delta_display)"
  echo "- Creator owner-default completed: $outreach_sprint_owner_default_creator_completed_display (Δ $outreach_sprint_owner_default_creator_completed_delta_display)"
  echo "- Guesting owner-default completed: $outreach_sprint_owner_default_guesting_completed_display (Δ $outreach_sprint_owner_default_guesting_completed_delta_display)"
  echo "- Distribution owner-default completed: $outreach_sprint_owner_default_distribution_completed_display (Δ $outreach_sprint_owner_default_distribution_completed_delta_display)"
  echo "- Ops owner-default completed: $outreach_sprint_owner_default_ops_completed_display (Δ $outreach_sprint_owner_default_ops_completed_delta_display)"
  echo "- Variant promoted into defaults: $outreach_sprint_variant_promoted_display"
  echo "- Outcomes logged in checklist: $outreach_sprint_outcomes_logged_display"
  echo "- Preferred execution lane: $outreach_sprint_preferred_lane_display"
  echo "- Outreach sprint recommendation: $outreach_sprint_recommendation"
  echo
  echo "### Distribution Follow-Up Effectiveness"
  echo
  echo "- Distribution days completed: $distribution_days_completed_display (Δ $distribution_days_completed_delta_display)"
  echo "- Distribution completion score: $distribution_completion_score_display (Δ $distribution_completion_score_delta_display)"
  echo "- Channel mix recommendation: $channel_mix_recommendation"
  echo
  echo "### Channel ROI Routing"
  echo
  echo "- Primary channel ROI score: $primary_channel_roi_score_display"
  echo "- Backup channel ROI score: $backup_channel_roi_score_display"
  echo "- Channel ROI preferred channel: $channel_roi_preferred_channel"
  echo "- Channel ROI recommendation: $channel_roi_recommendation"
  echo
  echo "### Default Draft Routing (ROI-Biased)"
  echo
  echo "- Default primary draft: \`$default_primary_channel_label\` (Variant $default_primary_variant_for_next_week)"
  echo
  echo "\`\`\`text"
  echo "$default_primary_channel_script"
  echo "\`\`\`"
  echo
  echo "- Default backup draft: \`$default_backup_channel_label\` (Variant $default_backup_variant_for_next_week)"
  echo
  echo "\`\`\`text"
  echo "$default_backup_channel_script"
  echo "\`\`\`"
  echo
  echo "### Next-Week Channel Scripts"
  echo
  echo "- Primary channel (\`$primary_channel\`): Variant $primary_variant_for_next_week"
  echo
  echo "\`\`\`text"
  echo "$primary_channel_script"
  echo "\`\`\`"
  echo
  echo "- Backup channel (\`$backup_channel\`): Variant $backup_variant_for_next_week"
  echo
  echo "\`\`\`text"
  echo "$backup_channel_script"
  echo "\`\`\`"
  echo
  echo "### Priority Actions (Next 7 Days)"
  echo
  echo "_Ordered by expected lift using outreach/reply rate deltas._"
  echo
  local_index=1
  for action_line in "${priority_actions[@]}"; do
    echo "$local_index. $action_line"
    (( local_index += 1 ))
  done
  echo
  echo "### Next-Week Hook Candidates"
  echo
  echo "- $hook_line_one"
  echo "- $hook_line_two"
  echo "- $hook_line_three"
} > "$output_path"

echo "Wrote growth review comment: $output_path"
