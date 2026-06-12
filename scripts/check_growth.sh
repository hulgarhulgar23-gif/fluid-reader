#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

required_files=(
  "scripts/generate_campaign_pack.sh"
  "scripts/generate_social_proof_kit.sh"
  "scripts/generate_social_proof_wall.sh"
  "scripts/generate_credibility_ledger.sh"
  "scripts/generate_creator_outreach_kit.sh"
  "scripts/generate_creator_target_list.sh"
  "scripts/generate_weekly_growth_issue.sh"
  "scripts/generate_growth_review_comment.sh"
  "scripts/generate_monday_publish_checkpoint.sh"
  "scripts/generate_distribution_followup_plan.sh"
  "scripts/generate_viral_experiment_board.sh"
  "scripts/generate_winning_hook_library.sh"
  "scripts/generate_first24h_reply_pack.sh"
  "scripts/generate_founder_first48h_post_pack.sh"
  "scripts/generate_founder_fame_ops_brief.sh"
  "scripts/generate_founder_fame_action_queue.sh"
  "scripts/generate_founder_fame_interview_prep.sh"
  "scripts/generate_founder_fame_transcript_ingestion.sh"
  "scripts/generate_founder_fame_repurpose_plan.sh"
  "scripts/generate_founder_fame_uplift_tracker.sh"
  "scripts/generate_founder_fame_weight_profile.sh"
  "scripts/generate_founder_fame_momentum_brief.sh"
  "scripts/generate_founder_fame_opportunity_radar.sh"
  "scripts/generate_founder_fame_execution_sprint.sh"
  "scripts/generate_founder_fame_execution_scorecard.sh"
  "scripts/generate_founder_fame_risk_response_plan.sh"
  "scripts/generate_founder_fame_escalation_queue.sh"
  "scripts/generate_founder_fame_command_center.sh"
  "scripts/generate_founder_fame_next_move_handoff.sh"
  "scripts/generate_founder_fame_next_move_draft_pack.sh"
  "scripts/generate_founder_fame_war_room.sh"
  "scripts/verify_founder_fame_war_room.sh"
  "scripts/post_founder_fame_war_room_comment.sh"
  "scripts/post_founder_fame_exceptional_loop_comment.sh"
  "scripts/generate_founder_fame_spotlight_pack.sh"
  "scripts/generate_founder_fame_breakout_plan.sh"
  "scripts/generate_founder_fame_outreach_sprint.sh"
  "scripts/generate_founder_fame_proof_loop.sh"
  "scripts/generate_founder_fame_kpi_snapshot.sh"
  "scripts/generate_founder_fame_velocity_scoreboard.sh"
  "scripts/generate_founder_fame_exceptional_loop.sh"
  "scripts/generate_founder_fame_narrative_lab.sh"
  "scripts/generate_founder_update_post.sh"
  "scripts/generate_founder_weekly_pack.sh"
  "scripts/generate_founder_fame_pack.sh"
  "scripts/generate_founder_press_kit.sh"
  "scripts/generate_founder_media_blast.sh"
  "scripts/generate_founder_guesting_queue.sh"
  "scripts/generate_founder_guesting_brief.sh"
  "scripts/check_founder_workflow.sh"
  "scripts/check_distribution_nudge_fixture.js"
  "scripts/check_founder_guesting_signal_fixture.js"
  "scripts/check_founder_narrative_route_fixture.js"
  "scripts/check_founder_narrative_route_incident_fixture.js"
  "scripts/check_founder_narrative_route_critical_comment_fixture.js"
  "scripts/check_founder_narrative_route_owner_queue_fixture.js"
  "scripts/check_founder_fame_proof_loop_alert_comment_fixture.js"
  "scripts/check_founder_fame_proof_loop_critical_comment_fixture.js"
  "scripts/check_founder_fame_proof_loop_incident_assignee_fixture.js"
  "scripts/fixtures/founder/sample_daily_mission.md"
  "scripts/check_founder_first48h_post_pack_fixture.js"
  "scripts/check_founder_first48h_controls_sync_fixture.js"
  "scripts/check_monday_draft_promoted_scripts_fixture.js"
  "scripts/check_monday_publish_promoted_defaults_fixture.js"
  "scripts/check_monday_publish_routing_precedence_fixture.js"
  "scripts/check_monday_publish_routing_live_verify_step_fixture.js"
  "scripts/check_monday_publish_routing_live_verify_step_contract_fixture.js"
  "scripts/check_monday_publish_routing_live_summary_step_fixture.js"
  "scripts/check_monday_publish_routing_live_enforcement_step_fixture.js"
  "scripts/check_monday_publish_routing_live_verifier_fixture.js"
  "scripts/check_monday_publish_routing_live_verifier_mode_contract_fixture.js"
  "scripts/check_monday_publish_routing_live_verifier_review_availability_contract_fixture.js"
  "scripts/check_launch_rescue_auto_trigger_contract_fixture.js"
  "scripts/verify_distribution_nudge_run.sh"
  "scripts/verify_monday_publish_routing_run.sh"
  "scripts/verify_founder_narrative_route_run.sh"
  "scripts/verify_founder_fame_proof_loop.sh"
  "scripts/verify_founder_fame_war_room_run.sh"
  "scripts/verify_founder_fame_proof_loop_run.sh"
  "scripts/verify_founder_fame_exceptional_loop_run.sh"
  "scripts/run_launch_day.sh"
  "docs/CAMPAIGN_AUTOMATION.md"
  "docs/CREATOR_OUTREACH_KIT.md"
  "docs/CREATOR_TARGET_LIST.md"
  "docs/GROWTH_RELEASE_CHECKLIST.md"
  "docs/LAUNCH_DAY_PLAN.md"
  "docs/LAUNCH_PLAYBOOK.md"
  "docs/WEEKLY_GROWTH_AUTOPILOT.md"
  "docs/WEEKLY_POST_PLANNER.md"
  "docs/DISTRIBUTION_PLAYBOOK.md"
  "docs/FOUNDER_FAME_OPS_BRIEF.md"
  "docs/FOUNDER_FAME_ACTION_QUEUE.md"
  "docs/FOUNDER_FAME_INTERVIEW_PREP.md"
  "docs/FOUNDER_FAME_TRANSCRIPT_INGESTION.md"
  "docs/FOUNDER_FAME_REPURPOSE_PLAN.md"
  "docs/FOUNDER_FAME_UPLIFT_TRACKER.md"
  "docs/FOUNDER_FAME_WEIGHT_PROFILE.md"
  "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"
  "docs/FOUNDER_FAME_OPPORTUNITY_RADAR.md"
  "docs/FOUNDER_FAME_EXECUTION_SPRINT.md"
  "docs/FOUNDER_FAME_EXECUTION_SCORECARD.md"
  "docs/FOUNDER_FAME_RISK_RESPONSE_PLAN.md"
  "docs/FOUNDER_FAME_ESCALATION_QUEUE.md"
  "docs/FOUNDER_FAME_COMMAND_CENTER.md"
  "docs/FOUNDER_FAME_SPOTLIGHT_PACK.md"
  "docs/FOUNDER_FAME_BREAKOUT_PLAN.md"
  "docs/FOUNDER_FAME_OUTREACH_SPRINT.md"
  "docs/FOUNDER_FAME_PROOF_LOOP.md"
  "docs/FOUNDER_FAME_KPI_SNAPSHOT.md"
  "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"
  "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"
  "docs/FOUNDER_FAME_NARRATIVE_LAB.md"
  "docs/FOUNDER_FIRST48H_POST_PACK.md"
  "docs/FOUNDER_FAME_PACK.md"
  "docs/FOUNDER_PRESS_KIT.md"
  "docs/FOUNDER_MEDIA_BLAST.md"
  "docs/FOUNDER_GUESTING_QUEUE.md"
  "docs/FOUNDER_GUESTING_BRIEF.md"
  ".github/workflows/founder-fame-pack.yml"
  ".github/workflows/launch-pack.yml"
  ".github/workflows/weekly-growth-sprint.yml"
  ".github/workflows/weekly-growth-review.yml"
  ".github/ISSUE_TEMPLATE/win_story.md"
)

for required_path in "${required_files[@]}"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Missing growth asset: $required_path"
    exit 1
  fi
done

tmp_campaign_file="${TMPDIR:-/tmp}/fluidreader-campaign-pack.${$}.${RANDOM}.md"
tmp_issue_file="${TMPDIR:-/tmp}/fluidreader-weekly-issue.${$}.${RANDOM}.md"
tmp_review_file="${TMPDIR:-/tmp}/fluidreader-growth-review.${$}.${RANDOM}.md"
tmp_social_proof_file="${TMPDIR:-/tmp}/fluidreader-social-proof.${$}.${RANDOM}.md"
tmp_creator_outreach_file="${TMPDIR:-/tmp}/fluidreader-creator-outreach.${$}.${RANDOM}.md"
tmp_creator_target_list_file="${TMPDIR:-/tmp}/fluidreader-creator-target-list.${$}.${RANDOM}.md"
tmp_monday_checkpoint_file="${TMPDIR:-/tmp}/fluidreader-monday-checkpoint.${$}.${RANDOM}.md"
tmp_distribution_plan_file="${TMPDIR:-/tmp}/fluidreader-distribution-plan.${$}.${RANDOM}.md"
tmp_viral_experiment_board_file="${TMPDIR:-/tmp}/fluidreader-viral-experiment-board.${$}.${RANDOM}.md"
tmp_winning_hook_library_file="${TMPDIR:-/tmp}/fluidreader-winning-hook-library.${$}.${RANDOM}.md"
tmp_social_proof_wall_file="${TMPDIR:-/tmp}/fluidreader-social-proof-wall.${$}.${RANDOM}.md"
tmp_credibility_ledger_file="${TMPDIR:-/tmp}/fluidreader-credibility-ledger.${$}.${RANDOM}.md"
tmp_reply_pack_file="${TMPDIR:-/tmp}/fluidreader-reply-pack.${$}.${RANDOM}.md"
tmp_founder_fame_ops_brief_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-ops-brief.${$}.${RANDOM}.md"
tmp_founder_fame_action_queue_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-action-queue.${$}.${RANDOM}.md"
tmp_founder_fame_interview_prep_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-interview-prep.${$}.${RANDOM}.md"
tmp_founder_fame_transcript_ingestion_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-transcript-ingestion.${$}.${RANDOM}.md"
tmp_founder_fame_repurpose_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-repurpose-plan.${$}.${RANDOM}.md"
tmp_founder_fame_uplift_tracker_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-uplift-tracker.${$}.${RANDOM}.md"
tmp_founder_fame_weight_profile_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-weight-profile.${$}.${RANDOM}.md"
tmp_founder_fame_momentum_brief_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-momentum-brief.${$}.${RANDOM}.md"
tmp_founder_fame_opportunity_radar_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-opportunity-radar.${$}.${RANDOM}.md"
tmp_founder_fame_execution_sprint_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-execution-sprint.${$}.${RANDOM}.md"
tmp_founder_fame_execution_scorecard_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-execution-scorecard.${$}.${RANDOM}.md"
tmp_founder_fame_risk_response_plan_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-risk-response-plan.${$}.${RANDOM}.md"
tmp_founder_fame_escalation_queue_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-escalation-queue.${$}.${RANDOM}.md"
tmp_founder_fame_command_center_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-command-center.${$}.${RANDOM}.md"
tmp_founder_fame_next_move_handoff_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-next-move-handoff.${$}.${RANDOM}.md"
tmp_founder_fame_spotlight_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-spotlight-pack.${$}.${RANDOM}.md"
tmp_founder_fame_breakout_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-breakout-plan.${$}.${RANDOM}.md"
tmp_founder_fame_outreach_sprint_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-outreach-sprint.${$}.${RANDOM}.md"
tmp_founder_fame_proof_loop_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-proof-loop.${$}.${RANDOM}.md"
tmp_founder_fame_kpi_snapshot_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-kpi-snapshot.${$}.${RANDOM}.md"
tmp_founder_fame_velocity_scoreboard_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-velocity-scoreboard.${$}.${RANDOM}.md"
tmp_founder_fame_exceptional_loop_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-exceptional-loop.${$}.${RANDOM}.md"
tmp_founder_fame_narrative_lab_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-narrative-lab.${$}.${RANDOM}.md"
tmp_founder_first48h_post_pack_file="${TMPDIR:-/tmp}/fluidreader-founder-first48h-post-pack.${$}.${RANDOM}.md"
tmp_founder_fame_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-pack.${$}.${RANDOM}.md"
tmp_founder_media_blast_file="${TMPDIR:-/tmp}/fluidreader-founder-media-blast.${$}.${RANDOM}.md"
sample_nudge_report_file=".build/growth/.tmp-distribution-nudge-live-sample.md"
sample_strict_nudge_report_file=".build/growth/.tmp-distribution-nudge-live-sample-strict.md"
sample_nudge_trace_file=".build/growth/check-growth-sample-distribution-nudge-trace-sample.md"
sample_strict_nudge_trace_file=".build/growth/check-growth-sample-strict-distribution-nudge-trace-sample.md"
sample_proof_loop_report_file=".build/growth/.tmp-founder-fame-proof-loop-verification.md"
sample_proof_loop_report_strict_file=".build/growth/.tmp-founder-fame-proof-loop-verification-strict.md"
sample_founder_live_run_report_file=".build/growth/.tmp-founder-fame-proof-loop-live-run-sample.md"
sample_founder_live_source_check_file=".build/founder/check-growth-founder-live-sample-founder-fame-proof-loop-check-sample.md"
sample_founder_live_run_check_mode_report_file=".build/growth/.tmp-founder-fame-proof-loop-live-run-check-mode-sample.md"
sample_war_room_live_report_file=".build/growth/.tmp-founder-fame-war-room-live-run-sample.md"
sample_exceptional_loop_live_report_file=".build/growth/.tmp-founder-fame-exceptional-loop-live-run-sample.md"
sample_monday_publish_routing_live_report_file=".build/growth/.tmp-monday-publish-routing-live-sample.md"
cleanup() {
  rm -f "$tmp_campaign_file" "$tmp_issue_file" "$tmp_review_file" "$tmp_social_proof_file" "$tmp_creator_outreach_file" "$tmp_creator_target_list_file" "$tmp_monday_checkpoint_file" "$tmp_distribution_plan_file" "$tmp_viral_experiment_board_file" "$tmp_winning_hook_library_file" "$tmp_social_proof_wall_file" "$tmp_credibility_ledger_file" "$tmp_reply_pack_file" "$tmp_founder_fame_ops_brief_file" "$tmp_founder_fame_action_queue_file" "$tmp_founder_fame_interview_prep_file" "$tmp_founder_fame_transcript_ingestion_file" "$tmp_founder_fame_repurpose_file" "$tmp_founder_fame_uplift_tracker_file" "$tmp_founder_fame_weight_profile_file" "$tmp_founder_fame_momentum_brief_file" "$tmp_founder_fame_opportunity_radar_file" "$tmp_founder_fame_execution_sprint_file" "$tmp_founder_fame_execution_scorecard_file" "$tmp_founder_fame_risk_response_plan_file" "$tmp_founder_fame_escalation_queue_file" "$tmp_founder_fame_command_center_file" "$tmp_founder_fame_next_move_handoff_file" "$tmp_founder_fame_spotlight_file" "$tmp_founder_fame_breakout_file" "$tmp_founder_fame_outreach_sprint_file" "$tmp_founder_fame_proof_loop_file" "$tmp_founder_fame_kpi_snapshot_file" "$tmp_founder_fame_velocity_scoreboard_file" "$tmp_founder_fame_exceptional_loop_file" "$tmp_founder_fame_narrative_lab_file" "$tmp_founder_first48h_post_pack_file" "$tmp_founder_fame_file" "$tmp_founder_media_blast_file" "$sample_nudge_report_file" "$sample_strict_nudge_report_file" "$sample_nudge_trace_file" "$sample_strict_nudge_trace_file" "$sample_proof_loop_report_file" "$sample_proof_loop_report_strict_file" "$sample_founder_live_run_report_file" "$sample_founder_live_source_check_file" "$sample_founder_live_run_check_mode_report_file" "$sample_war_room_live_report_file" "$sample_exceptional_loop_live_report_file" "$sample_monday_publish_routing_live_report_file"
}
trap cleanup EXIT

zsh scripts/generate_campaign_pack.sh \
  --week "2099-W01" \
  --command "Copy Win Card" \
  --problem "manual weekly updates" \
  --outcome "share-ready recap in under one minute" \
  --metric "saved ~15 minutes daily" \
  --workflow "Read Selected Text|Ask Anything|Copy Win Card" \
  --out "$tmp_campaign_file" >/dev/null

if [[ ! -s "$tmp_campaign_file" ]]; then
  echo "Generated campaign pack is empty."
  exit 1
fi

required_pack_sections=(
  "# Campaign Pack: 2099-W01"
  "## Monday: Before / After Post"
  "## Wednesday: Command Spotlight Post"
  "## Friday: 3-Step Workflow Post"
  "## Channel Variants"
  "## 24-Hour Reply Queue"
  "## Friday Review Notes"
)

for section in "${required_pack_sections[@]}"; do
  if ! rg -Fq -- "$section" "$tmp_campaign_file"; then
    echo "Missing campaign section: $section"
    exit 1
  fi
done

zsh scripts/generate_social_proof_kit.sh \
  --week "2099-W01" \
  --command "Copy Win Card" \
  --problem "manual weekly status updates" \
  --outcome "share-ready recap in under one minute" \
  --metric "saved ~10 minutes per day" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out "$tmp_social_proof_file" >/dev/null

if [[ ! -s "$tmp_social_proof_file" ]]; then
  echo "Generated social proof kit is empty."
  exit 1
fi

required_social_proof_snippets=(
  "# Social Proof Kit: 2099-W01"
  "## Snapshot"
  "## Launch Hook"
  "## Primary Channel Draft (X / Threads)"
  "## Backup Channel Draft (LinkedIn)"
  "## Community Comment Draft"
  "## First 24-Hour Reply Queue"
  "## CTA Split Test"
)

for snippet in "${required_social_proof_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_social_proof_file"; then
    echo "Missing social proof kit content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_creator_outreach_kit.sh \
  --week "2099-W01" \
  --command "Copy Win Card" \
  --problem "manual weekly status updates" \
  --outcome "share-ready recap in under one minute" \
  --metric "saved ~10 minutes per day" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out "$tmp_creator_outreach_file" >/dev/null

if [[ ! -s "$tmp_creator_outreach_file" ]]; then
  echo "Generated creator outreach kit is empty."
  exit 1
fi

required_creator_outreach_snippets=(
  "# Creator Outreach Kit: 2099-W01"
  "## Snapshot"
  "## Outreach Positioning"
  "## Creator DM Drafts"
  "## Podcast / Interview Pitch"
  "## Community Moderator Pitch"
  "## Partner Tracker"
  "## 7-Day Follow-Up Cadence"
  "## CTA Split Test"
)

for snippet in "${required_creator_outreach_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_creator_outreach_file"; then
    echo "Missing creator outreach kit content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_creator_target_list.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --command "Copy Win Card" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --primary-channel-roi-score "78" \
  --backup-channel-roi-score "71" \
  --channel-roi-preferred-channel "primary" \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix this week." \
  --outreach-sent "8" \
  --outreach-replies "3" \
  --outreach-collabs "1" \
  --outreach-cross-posts "1" \
  --outreach-reply-rate "37.5%" \
  --outreach-collab-rate "12.5%" \
  --outreach-cross-post-rate "12.5%" \
  --outreach-replies-delta "+1" \
  --outreach-collabs-delta "+1" \
  --creator-signal-entries "7" \
  --creator-signal-high-fit "4" \
  --creator-signal-warm-intros "2" \
  --creator-signal-collab-ready "2" \
  --creator-signal-top-segment "Workflow/tutorial creators" \
  --creator-signal-top-handle "@buildwithamy" \
  --creator-signal-enrichment-score "74" \
  --creator-signal-recommendation "Prioritize high-fit workflow creators first and personalize first-touch proof." \
  --outreach-sprint-completion-rate "75%" \
  --outreach-sprint-tasks-completed "6" \
  --outreach-sprint-tasks-total "8" \
  --outreach-sprint-creator-tasks-completed "4" \
  --outreach-sprint-guesting-tasks-completed "2" \
  --outreach-sprint-recommendation "Creator lane outperformed this week; bias next-week creator targets." \
  --out "$tmp_creator_target_list_file" >/dev/null

if [[ ! -s "$tmp_creator_target_list_file" ]]; then
  echo "Generated creator target list is empty."
  exit 1
fi

required_creator_target_list_snippets=(
  "<!-- weekly-growth-creator-target-list -->"
  "# Creator Target List: 2099-W01"
  "## Prioritization Snapshot"
  "## Creator Signal Overlay"
  "## Ranked Creator Targets"
  "## Contact Sprint Plan"
  "## DM Variants"
  "### Variant A (proof-first)"
  "### Variant B (workflow-first)"
  "### Variant C (distribution-first)"
  "## Tracking Checklist"
  "Creator signal entries reviewed:"
  "Creator signal recommendation:"
  "Outreach sprint completion rate:"
  "Outreach sprint recommendation:"
  "Updated founder outreach sprint checklist comment with creator outcomes"
)

for snippet in "${required_creator_target_list_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_creator_target_list_file"; then
    echo "Missing creator target list content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--outreach-sprint-completion-rate" "scripts/generate_creator_target_list.sh"; then
  echo "Creator target list generator is missing outreach sprint completion-rate option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-recommendation" "scripts/generate_creator_target_list.sh"; then
  echo "Creator target list generator is missing outreach sprint recommendation option."
  exit 1
fi

zsh scripts/generate_weekly_growth_issue.sh \
  --week "2099-W01" \
  --campaign "$tmp_campaign_file" \
  --primary "X / Threads" \
  --backup "LinkedIn" \
  --metric "Win Card copies and reply quality" \
  --prev-week "2098-W52" \
  --prev-baseline-week "2098-W51" \
  --prev-win-card "42" \
  --prev-win-card-delta "+7" \
  --prev-win-recap "30" \
  --prev-win-recap-delta "+5" \
  --prev-posts "5" \
  --prev-posts-delta "-1" \
  --prev-stories "8" \
  --prev-stories-delta "+2" \
  --prev-installs "16" \
  --prev-installs-delta "+4" \
  --out "$tmp_issue_file" >/dev/null

if [[ ! -s "$tmp_issue_file" ]]; then
  echo "Generated weekly growth issue is empty."
  exit 1
fi

required_issue_snippets=(
  "## Previous Week Snapshot (2098-W52)"
  "- Win Card copies: 42 (+7 vs 2098-W51)"
  "- Win Recap copies: 30 (+5 vs 2098-W51)"
  "- Public posts shipped: 5 (-1 vs 2098-W51)"
  "- User-generated stories: 8 (+2 vs 2098-W51)"
  "- Inbound installs/trials: 16 (+4 vs 2098-W51)"
  "## Campaign Draft Preview"
)

for snippet in "${required_issue_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_issue_file"; then
    echo "Missing weekly issue content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_growth_review_comment.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --win-card "42" \
  --win-card-delta "+7" \
  --win-recap "29" \
  --win-recap-delta "+4" \
  --posts "4" \
  --posts-delta "+1" \
  --stories "3" \
  --stories-delta "+1" \
  --installs "12" \
  --installs-delta "+5" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --monday-source-week "2098-W52" \
  --monday-post-status "posted" \
  --reply-pack-replies "14" \
  --reply-pack-replies-delta "+3" \
  --reply-pack-objections "3" \
  --reply-pack-objections-delta "+1" \
  --reply-pack-doc-updates "2" \
  --reply-pack-doc-updates-delta "+1" \
  --outreach-sent "8" \
  --outreach-sent-delta "+2" \
  --outreach-replies "3" \
  --outreach-replies-delta "+1" \
  --outreach-collabs "1" \
  --outreach-collabs-delta "+1" \
  --outreach-cross-posts "1" \
  --outreach-cross-posts-delta "+1" \
  --outreach-reply-rate "37.5%" \
  --outreach-reply-rate-delta "+8.0pp" \
  --outreach-collab-rate "12.5%" \
  --outreach-collab-rate-delta "+4.0pp" \
  --outreach-cross-post-rate "12.5%" \
  --outreach-cross-post-rate-delta "+4.0pp" \
  --creator-signal-entries "7" \
  --creator-signal-entries-delta "+2" \
  --creator-signal-high-fit "4" \
  --creator-signal-high-fit-delta "+1" \
  --creator-signal-warm-intros "2" \
  --creator-signal-warm-intros-delta "+1" \
  --creator-signal-collab-ready "2" \
  --creator-signal-collab-ready-delta "+1" \
  --creator-signal-top-segment "Workflow/tutorial creators" \
  --creator-signal-top-handle "@buildwithamy" \
  --creator-signal-enrichment-score "74%" \
  --creator-signal-enrichment-score-delta "+6pp" \
  --creator-signal-recommendation "Prioritize high-fit creator handles first and personalize intros with workflow-specific proof." \
  --guesting-signal-entries "5" \
  --guesting-signal-entries-delta "+2" \
  --guesting-signal-replied "4" \
  --guesting-signal-replied-delta "+2" \
  --guesting-signal-booked "2" \
  --guesting-signal-booked-delta "+1" \
  --guesting-signal-published "1" \
  --guesting-signal-published-delta "+1" \
  --guesting-signal-top-format "podcast" \
  --guesting-signal-top-target "Growth Weekly Podcast" \
  --guesting-signal-enrichment-score "82%" \
  --guesting-signal-enrichment-score-delta "+9pp" \
  --guesting-signal-recommendation "Prioritize booked/published guesting targets first and scale the top-performing format this week." \
  --narrative-route-winner "Proof-first route" \
  --narrative-route-winner-delta "unchanged" \
  --narrative-route-trend "holding Proof-first route" \
  --narrative-fame-velocity-score "78%" \
  --narrative-fame-velocity-score-delta "+6pp" \
  --narrative-launch-posture "Stabilize and scale" \
  --narrative-route-mode "Route Re-Lock" \
  --narrative-route-alignment-target "Aligned by Day 1" \
  --narrative-route-lane-status "Watch" \
  --narrative-route-guardrail "Keep every route update tied to one measurable proof artifact." \
  --narrative-next-standup-action "Log one route winner and one failed route in standup notes." \
  --narrative-route-control-recommendation "Re-lock winner, execution mode, and opportunity before next publish." \
  --narrative-route-recommendation "Keep Proof-first route as lead narrative route and scale it across both channels while preserving proof guardrails." \
  --narrative-distribution-strategy "Re-lock cadence: lead with winner reinforcement, follow with conversion proof." \
  --narrative-distribution-day0-lead "X / Threads (Global, 13:00 UTC)" \
  --narrative-distribution-day0-support "LinkedIn (US, 15:00-17:00 local)" \
  --narrative-distribution-recommendation "Run re-lock cadence with Day 0 lead X / Threads; use LinkedIn for support replies and route-confidence reinforcement." \
  --narrative-distribution-first-48h-plan "Day 0: lead with winner re-lock post on X / Threads. Day 1: reinforce confidence with replies on LinkedIn. Day 2: publish one proof-backed winner recap." \
  --outreach-sprint-comment-entries "1" \
  --outreach-sprint-comment-entries-delta "0" \
  --outreach-sprint-tasks-completed "6" \
  --outreach-sprint-tasks-completed-delta "+1" \
  --outreach-sprint-tasks-total "8" \
  --outreach-sprint-completion-rate "75%" \
  --outreach-sprint-completion-rate-delta "+12.5pp" \
  --outreach-sprint-creator-tasks-completed "4" \
  --outreach-sprint-creator-tasks-completed-delta "+1" \
  --outreach-sprint-guesting-tasks-completed "2" \
  --outreach-sprint-guesting-tasks-completed-delta "0" \
  --outreach-sprint-owner-defaults-tasks-completed "3" \
  --outreach-sprint-owner-defaults-tasks-completed-delta "+1" \
  --outreach-sprint-owner-defaults-tasks-total "4" \
  --outreach-sprint-owner-defaults-completion-rate "75%" \
  --outreach-sprint-owner-defaults-completion-rate-delta "+25pp" \
  --outreach-sprint-owner-default-creator-completed "1" \
  --outreach-sprint-owner-default-creator-completed-delta "+1" \
  --outreach-sprint-owner-default-guesting-completed "1" \
  --outreach-sprint-owner-default-guesting-completed-delta "0" \
  --outreach-sprint-owner-default-distribution-completed "0" \
  --outreach-sprint-owner-default-distribution-completed-delta "0" \
  --outreach-sprint-owner-default-ops-completed "1" \
  --outreach-sprint-owner-default-ops-completed-delta "+1" \
  --outreach-sprint-variant-promoted "yes" \
  --outreach-sprint-outcomes-logged "yes" \
  --outreach-sprint-preferred-lane "creator" \
  --outreach-sprint-recommendation "Creator lane outperformed this week; keep guesting maintenance touchpoints active." \
  --primary-channel-roi-score "78" \
  --backup-channel-roi-score "71" \
  --channel-roi-recommendation "Lead with primary channel next week (ROI 78 vs 71) and keep Variant A as default opener." \
  --distribution-days-completed "6/8" \
  --distribution-days-completed-delta "+2" \
  --distribution-completion-score "75%" \
  --distribution-completion-score-delta "+12.5pp" \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix and complete Day-0 to Day-7 follow-up cadence." \
  --primary-top-variant "A" \
  --backup-top-variant "B" \
  --primary-variant-win-trend "Variant A (2 consecutive weeks)" \
  --backup-variant-win-trend "Variant B (1 consecutive week)" \
  --variant-recommendation "Keep split test: primary Variant A, backup Variant B." \
  --outreach-recommendation "Scale creator outreach list by 50% and keep the same pitch angle next week." \
  --out "$tmp_review_file" >/dev/null

if [[ ! -s "$tmp_review_file" ]]; then
  echo "Generated growth review comment is empty."
  exit 1
fi

required_review_snippets=(
  "<!-- weekly-growth-review -->"
  "## Weekly Growth Review: 2099-W01"
  "### Scorecard"
  "### Reply Pack Effectiveness"
  "### Creator Outreach Effectiveness"
  "### Creator Account Enrichment"
  "### Founder Guesting Enrichment"
  "### Founder Narrative Route Signals"
  "### Founder Outreach Sprint Outcomes"
  "### Distribution Follow-Up Effectiveness"
  "Distribution days completed:"
  "Distribution completion score:"
  "Channel mix recommendation:"
  "### Channel ROI Routing"
  "### Default Draft Routing (ROI-Biased)"
  "### Next-Week Channel Scripts"
  "### Priority Actions (Next 7 Days)"
  "Ordered by expected lift using outreach/reply rate deltas."
  "### Next-Week Hook Candidates"
  "Sprint health:"
  "Monday post status:"
  "Primary channel top variant:"
  "Primary variant trendline:"
  "Backup variant trendline:"
  "Primary channel ROI score:"
  "Backup channel ROI score:"
  "Channel ROI recommendation:"
  "Creator collaboration rate:"
  "Creator signal entries:"
  "Creator enrichment score:"
  "Creator signal recommendation:"
  "Founder guesting signal entries:"
  "Founder guesting booked:"
  "Founder guesting enrichment score:"
  "Founder guesting recommendation:"
  "Founder narrative route winner:"
  "Founder narrative route trend:"
  "Founder narrative fame velocity score:"
  "Founder narrative route mode:"
  "Founder narrative route alignment target:"
  "Founder narrative route lane status:"
  "Founder narrative route guardrail:"
  "Founder narrative route control recommendation:"
  "Founder narrative recommendation:"
  "Founder narrative distribution strategy:"
  "Founder narrative Day 0 lead lane:"
  "Founder narrative Day 0 support lane:"
  "Founder narrative distribution recommendation:"
  "Founder narrative first 48h execution plan:"
  "Outreach sprint completion rate:"
  "Owner-default tasks completed:"
  "Owner-default completion rate:"
  "Distribution owner-default completed:"
  "Outreach sprint recommendation:"
  "Variant promoted into defaults:"
  "Primary channel ("
  "Backup channel ("
  "Next-week variant recommendation:"
  "Next-week outreach recommendation:"
  "Win Card copies"
)

for snippet in "${required_review_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_review_file"; then
    echo "Missing weekly review content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--primary-channel-roi-score" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing primary channel ROI option."
  exit 1
fi

if ! rg -Fq -- "--channel-roi-recommendation" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing channel ROI recommendation option."
  exit 1
fi

if ! rg -Fq -- "--distribution-days-completed" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing distribution days option."
  exit 1
fi

if ! rg -Fq -- "--distribution-completion-score" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing distribution completion score option."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing channel mix recommendation option."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-entries" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing creator signal entries option."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-enrichment-score" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing creator signal enrichment score option."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-entries" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder guesting signal entries option."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-enrichment-score" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder guesting enrichment score option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-winner" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route winner option."
  exit 1
fi

if ! rg -Fq -- "--narrative-fame-velocity-score" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative fame velocity option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-mode" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route mode option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-alignment-target" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route alignment-target option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-lane-status" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route lane-status option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-guardrail" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route guardrail option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-control-recommendation" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route control recommendation option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-recommendation" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative route recommendation option."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-strategy" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative distribution-strategy option."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-day0-lead" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative day0-lead option."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-day0-support" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative day0-support option."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-recommendation" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative distribution recommendation option."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-first-48h-plan" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing founder narrative first-48h execution-plan option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-comment-entries" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing outreach sprint comment entries option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-completion-rate" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing outreach sprint completion-rate option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-recommendation" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing outreach sprint recommendation option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-owner-defaults-completion-rate" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing outreach sprint owner-default completion-rate option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-owner-default-distribution-completed" "scripts/generate_growth_review_comment.sh"; then
  echo "Growth review generator is missing outreach sprint distribution-owner completion option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-completion-rate" "scripts/generate_founder_guesting_queue.sh"; then
  echo "Founder guesting queue generator is missing outreach sprint completion-rate option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-recommendation" "scripts/generate_founder_guesting_queue.sh"; then
  echo "Founder guesting queue generator is missing outreach sprint recommendation option."
  exit 1
fi

zsh scripts/generate_monday_publish_checkpoint.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --primary-audience-region "us" \
  --backup-audience-region "eu" \
  --primary-channel-roi-score "78" \
  --backup-channel-roi-score "71" \
  --channel-roi-preferred-channel "primary" \
  --channel-roi-recommendation "Lead with primary channel next week (ROI 78 vs 71) and keep Variant A as default opener." \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --draft-path "$tmp_review_file" \
  --out "$tmp_monday_checkpoint_file" >/dev/null

if [[ ! -s "$tmp_monday_checkpoint_file" ]]; then
  echo "Generated Monday publish checkpoint is empty."
  exit 1
fi

required_checkpoint_snippets=(
  "<!-- weekly-growth-monday-checkpoint -->"
  "# Monday Publish Checkpoint: 2099-W01"
  "## Recommended Publish Windows"
  "## ROI-Aware Launch Sequence"
  "Primary audience region:"
  "Backup audience region:"
  "Primary channel ROI score:"
  "Backup channel ROI score:"
  "Channel ROI preferred lead:"
  "Recommended sequence:"
  "## Pre-Publish Gate"
  "## Response Plan (First 24 Hours)"
  "## Monday Draft Snapshot"
)

for snippet in "${required_checkpoint_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_monday_checkpoint_file"; then
    echo "Missing Monday checkpoint content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--primary-audience-region" "scripts/generate_monday_publish_checkpoint.sh"; then
  echo "Monday checkpoint generator is missing primary audience-region option."
  exit 1
fi

if ! rg -Fq -- "--backup-audience-region" "scripts/generate_monday_publish_checkpoint.sh"; then
  echo "Monday checkpoint generator is missing backup audience-region option."
  exit 1
fi

zsh scripts/generate_distribution_followup_plan.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --command "Copy Win Card" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --primary-audience-region "us" \
  --backup-audience-region "eu" \
  --primary-channel-roi-score "78" \
  --backup-channel-roi-score "71" \
  --channel-roi-preferred-channel "primary" \
  --channel-roi-recommendation "Lead with primary channel next week (ROI 78 vs 71) and keep Variant A as default opener." \
  --reply-goal "12" \
  --outreach-goal "5" \
  --out "$tmp_distribution_plan_file" >/dev/null

if [[ ! -s "$tmp_distribution_plan_file" ]]; then
  echo "Generated distribution follow-up plan is empty."
  exit 1
fi

required_distribution_plan_snippets=(
  "<!-- weekly-growth-distribution-plan -->"
  "# 7-Day Distribution Follow-Up Plan: 2099-W01"
  "## Routing Snapshot"
  "Lead channel this week:"
  "Support channel this week:"
  "Channel mix recommendation:"
  "## Day-by-Day Distribution Plan"
  "| Day | Objective | Channel | Suggested window (UTC) | Deliverable | Success check |"
  "## Copy-Ready Follow-Up Scripts"
  "## Execution Checklist"
)

for snippet in "${required_distribution_plan_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_distribution_plan_file"; then
    echo "Missing distribution follow-up content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--channel-roi-preferred-channel" "scripts/generate_distribution_followup_plan.sh"; then
  echo "Distribution follow-up generator is missing ROI preferred-channel option."
  exit 1
fi

if ! rg -Fq -- "--primary-audience-region" "scripts/generate_distribution_followup_plan.sh"; then
  echo "Distribution follow-up generator is missing primary audience-region option."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation" "scripts/generate_distribution_followup_plan.sh"; then
  echo "Distribution follow-up generator is missing channel mix recommendation option."
  exit 1
fi

zsh scripts/generate_viral_experiment_board.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --win-card-delta "+7" \
  --installs-delta "+4" \
  --outreach-reply-rate "37.5%" \
  --outreach-reply-rate-delta "+5" \
  --outreach-collab-rate "12.5%" \
  --outreach-collab-rate-delta "+2.5" \
  --creator-signal-enrichment-score "74" \
  --creator-signal-enrichment-score-delta "+6" \
  --guesting-signal-enrichment-score "68" \
  --guesting-signal-enrichment-score-delta "+5" \
  --distribution-completion-score "82" \
  --distribution-completion-score-delta "+8" \
  --channel-roi-preferred-channel "primary" \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix this week." \
  --out "$tmp_viral_experiment_board_file" >/dev/null

if [[ ! -s "$tmp_viral_experiment_board_file" ]]; then
  echo "Generated viral experiment board is empty."
  exit 1
fi

required_viral_experiment_board_snippets=(
  "<!-- weekly-growth-viral-experiment-board -->"
  "# Viral Experiment Board: 2099-W01"
  "## Signal Snapshot"
  "## Ranked Experiments"
  "| Rank | Experiment | Hypothesis | Owner | Leading indicator | Priority score |"
  "## Execution Cadence"
  "## Tracking Checklist"
)

for snippet in "${required_viral_experiment_board_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_viral_experiment_board_file"; then
    echo "Missing viral experiment board content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--creator-signal-enrichment-score" "scripts/generate_viral_experiment_board.sh"; then
  echo "Viral experiment board generator is missing creator enrichment score option."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-enrichment-score" "scripts/generate_viral_experiment_board.sh"; then
  echo "Viral experiment board generator is missing founder guesting enrichment score option."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation" "scripts/generate_viral_experiment_board.sh"; then
  echo "Viral experiment board generator is missing channel mix recommendation option."
  exit 1
fi

zsh scripts/generate_winning_hook_library.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --primary-top-variant "A" \
  --backup-top-variant "B" \
  --primary-variant-win-trend "A won 2 weeks in a row" \
  --backup-variant-win-trend "B won 1 week in a row" \
  --primary-channel-roi-score "78" \
  --backup-channel-roi-score "71" \
  --channel-roi-preferred-channel "primary" \
  --channel-roi-recommendation "Lead with primary channel next week (ROI 78 vs 71)." \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix this week." \
  --variant-recommendation "Keep Variant A as default and test Variant B as challenger." \
  --outreach-recommendation "Prioritize warm intros first and close one collab this week." \
  --creator-signal-enrichment-score "74" \
  --guesting-signal-enrichment-score "68" \
  --win-card-delta "+7" \
  --installs-delta "+4" \
  --out "$tmp_winning_hook_library_file" >/dev/null

if [[ ! -s "$tmp_winning_hook_library_file" ]]; then
  echo "Generated winning hook library is empty."
  exit 1
fi

required_winning_hook_library_snippets=(
  "<!-- weekly-growth-winning-hook-library -->"
  "# Winning Hook Library: 2099-W01"
  "## Signal Snapshot"
  "## Ranked Hooks"
  "| Rank | Hook | Best channel | Script seed | Why now | Priority score |"
  "## Copy-Ready Hook Seeds"
  "### Hook A"
  "### Hook B"
  "### Hook C"
  "## Execution Checklist"
)

for snippet in "${required_winning_hook_library_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_winning_hook_library_file"; then
    echo "Missing winning hook library content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--primary-top-variant" "scripts/generate_winning_hook_library.sh"; then
  echo "Winning hook library generator is missing primary top-variant option."
  exit 1
fi

if ! rg -Fq -- "--channel-roi-recommendation" "scripts/generate_winning_hook_library.sh"; then
  echo "Winning hook library generator is missing channel ROI recommendation option."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-enrichment-score" "scripts/generate_winning_hook_library.sh"; then
  echo "Winning hook library generator is missing creator enrichment score option."
  exit 1
fi

zsh scripts/generate_social_proof_wall.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --win-card "42" \
  --win-card-delta "+7" \
  --replies-sent "14" \
  --replies-sent-delta "+3" \
  --outreach-replies "3" \
  --outreach-collabs "1" \
  --outreach-cross-posts "1" \
  --primary-top-variant "A" \
  --backup-top-variant "B" \
  --creator-signal-top-handle "@buildwithamy" \
  --creator-signal-top-segment "Workflow/tutorial creators" \
  --guesting-signal-top-target "Dev Productivity Podcast" \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix this week." \
  --variant-recommendation "Keep Variant A as default and test Variant B as challenger." \
  --outreach-recommendation "Prioritize warm intros first and close one collab this week." \
  --out "$tmp_social_proof_wall_file" >/dev/null

if [[ ! -s "$tmp_social_proof_wall_file" ]]; then
  echo "Generated social proof wall is empty."
  exit 1
fi

required_social_proof_wall_snippets=(
  "<!-- weekly-growth-social-proof-wall -->"
  "# Weekly Social Proof Wall: 2099-W01"
  "## Signal Snapshot"
  "## Ranked Proof Cards"
  "| Rank | Proof card | Best channel | Evidence seed | Usage note | Priority score |"
  "## Quote Bank"
  "## Repost Snippets"
  "### Primary Channel Snippet (X / Threads)"
  "### Backup Channel Snippet (LinkedIn)"
  "## Wall Checklist"
)

for snippet in "${required_social_proof_wall_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_social_proof_wall_file"; then
    echo "Missing social proof wall content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--creator-signal-top-handle" "scripts/generate_social_proof_wall.sh"; then
  echo "Social proof wall generator is missing creator signal top-handle option."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-top-target" "scripts/generate_social_proof_wall.sh"; then
  echo "Social proof wall generator is missing founder guesting top-target option."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation" "scripts/generate_social_proof_wall.sh"; then
  echo "Social proof wall generator is missing channel mix recommendation option."
  exit 1
fi

zsh scripts/generate_founder_fame_ops_brief.sh \
  --week "2099-W01" \
  --distribution-plan "$tmp_distribution_plan_file" \
  --social-proof-wall "$tmp_social_proof_wall_file" \
  --out "$tmp_founder_fame_ops_brief_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_ops_brief_file" ]]; then
  echo "Generated founder fame ops brief is empty."
  exit 1
fi

required_founder_fame_ops_brief_snippets=(
  "# Founder Fame Ops Brief: 2099-W01"
  "## Routing and Proof Snapshot"
  "## Founder Overlay"
  "## Next 24 Hours"
  "## 7-Day Fame Sprint"
  "## Copy Block"
)

for snippet in "${required_founder_fame_ops_brief_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_ops_brief_file"; then
    echo "Missing founder fame ops brief content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--distribution-plan" "scripts/generate_founder_fame_ops_brief.sh"; then
  echo "Founder fame ops brief generator is missing distribution-plan option."
  exit 1
fi

if ! rg -Fq -- "--social-proof-wall" "scripts/generate_founder_fame_ops_brief.sh"; then
  echo "Founder fame ops brief generator is missing social-proof-wall option."
  exit 1
fi

zsh scripts/generate_founder_fame_action_queue.sh \
  --week "2099-W01" \
  --ops-brief "$tmp_founder_fame_ops_brief_file" \
  --daily-mission "scripts/fixtures/founder/sample_daily_mission.md" \
  --out "$tmp_founder_fame_action_queue_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_action_queue_file" ]]; then
  echo "Generated founder fame action queue is empty."
  exit 1
fi

required_founder_fame_action_queue_snippets=(
  "<!-- founder-fame-action-queue -->"
  "# Founder Fame Action Queue: 2099-W01"
  "## Snapshot"
  "## Top 3 Monday Actions"
  "## Action Owners"
  "## 3-Hour Mission Bridge"
  "Daily mission source: scripts/fixtures/founder/sample_daily_mission.md"
  "Mission freshness: Future-dated by"
  "0-20m block: Run \`run-fame-breakthrough-forecast\` and lock the first publish block."
  "## Queue Notes"
  "## Copy Block"
)

for snippet in "${required_founder_fame_action_queue_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_action_queue_file"; then
    echo "Missing founder fame action queue content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--ops-brief" "scripts/generate_founder_fame_action_queue.sh"; then
  echo "Founder fame action queue generator is missing ops-brief option."
  exit 1
fi

if ! rg -Fq -- "--daily-mission" "scripts/generate_founder_fame_action_queue.sh"; then
  echo "Founder fame action queue generator is missing daily-mission option."
  exit 1
fi

if ! rg -Fq -- "--require-fresh-daily-mission" "scripts/generate_founder_fame_action_queue.sh"; then
  echo "Founder fame action queue generator is missing fresh-daily-mission guard option."
  exit 1
fi

if ! rg -Fq -- "--daily-mission-max-age-days" "scripts/generate_founder_fame_action_queue.sh"; then
  echo "Founder fame action queue generator is missing mission max-age threshold option."
  exit 1
fi

zsh scripts/generate_founder_fame_interview_prep.sh \
  --week "2099-W01" \
  --ops-brief "$tmp_founder_fame_ops_brief_file" \
  --action-queue "$tmp_founder_fame_action_queue_file" \
  --out "$tmp_founder_fame_interview_prep_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_interview_prep_file" ]]; then
  echo "Generated founder fame interview prep is empty."
  exit 1
fi

required_founder_fame_interview_prep_snippets=(
  "<!-- founder-fame-interview-prep -->"
  "# Founder Fame Interview Prep: 2099-W01"
  "## Snapshot"
  "## Opening Scripts"
  "## Proof Soundbites"
  "## Tough Questions + Answers"
  "## CTA Closes"
  "## Live Checklist"
  "## Share Block"
)

for snippet in "${required_founder_fame_interview_prep_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_interview_prep_file"; then
    echo "Missing founder fame interview prep content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--ops-brief" "scripts/generate_founder_fame_interview_prep.sh"; then
  echo "Founder fame interview prep generator is missing ops-brief option."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "scripts/generate_founder_fame_interview_prep.sh"; then
  echo "Founder fame interview prep generator is missing action-queue option."
  exit 1
fi

if ! rg -Fq -- "--guesting-brief" "scripts/generate_founder_fame_interview_prep.sh"; then
  echo "Founder fame interview prep generator is missing guesting-brief option."
  exit 1
fi

zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --week "2099-W01" \
  --transcript "$tmp_founder_fame_interview_prep_file" \
  --interview-prep "$tmp_founder_fame_interview_prep_file" \
  --out "$tmp_founder_fame_transcript_ingestion_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_transcript_ingestion_file" ]]; then
  echo "Generated founder fame transcript ingestion is empty."
  exit 1
fi

required_founder_fame_transcript_ingestion_snippets=(
  "<!-- founder-fame-transcript-ingestion -->"
  "# Founder Fame Transcript Ingestion - 2099-W01"
  "## Snapshot"
  "## Transcript Quote Bank"
  "## Objection Radar"
  "## Clip Candidate List"
  "## Quality Diagnostics"
  "## Repurpose Priority Mapping"
  "## Follow-up Actions"
  "## Share Block"
)

for snippet in "${required_founder_fame_transcript_ingestion_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_transcript_ingestion_file"; then
    echo "Missing founder fame transcript ingestion content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--transcript" "scripts/generate_founder_fame_transcript_ingestion.sh"; then
  echo "Founder fame transcript ingestion generator is missing transcript option."
  exit 1
fi

if ! rg -Fq -- "--interview-prep" "scripts/generate_founder_fame_transcript_ingestion.sh"; then
  echo "Founder fame transcript ingestion generator is missing interview-prep option."
  exit 1
fi

if ! rg -Fq -- "--media-blast" "scripts/generate_founder_fame_transcript_ingestion.sh"; then
  echo "Founder fame transcript ingestion generator is missing media-blast option."
  exit 1
fi

cat > "$tmp_founder_media_blast_file" <<'EOF'
# Founder Media Blast - 2099-W01

- Weekly narrative: Balanced scoreboard with a clear execution focus.
- Current focus: Tighten weakest KPI before expanding channel spend.
- Headline A: "Founder execution loop with measurable weekly proof."
- Headline B: "One scoreboard, one narrative, one follow-up."
- Headline C: "Local-first product with public founder proof cadence."
- CTA script: Reply with your KPI bottleneck and I will share the exact command stack.

## Channel Sequence

1. Day 1 (X / Threads): publish proof-first founder narrative.
2. Day 2 (X / Threads): post objection-handling follow-up with metric context.
3. Day 3 (LinkedIn): publish reformatted operator recap.
EOF

zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --week "2099-W01" \
  --interview-prep "$tmp_founder_fame_interview_prep_file" \
  --transcript-ingestion "$tmp_founder_fame_transcript_ingestion_file" \
  --media-blast "$tmp_founder_media_blast_file" \
  --action-queue "$tmp_founder_fame_action_queue_file" \
  --out "$tmp_founder_fame_repurpose_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_repurpose_file" ]]; then
  echo "Generated founder fame repurpose plan is empty."
  exit 1
fi

required_founder_fame_repurpose_snippets=(
  "<!-- founder-fame-repurpose-plan -->"
  "# Founder Fame Repurpose Plan - 2099-W01"
  "## Snapshot"
  "## Repurpose Targets"
  "## Asset Matrix"
  "## Transcript Signals"
  "## 7-Day Repurpose Sprint"
  "## Copy Starters"
  "## Tracking Checklist"
  "## Share Block"
)

for snippet in "${required_founder_fame_repurpose_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_repurpose_file"; then
    echo "Missing founder fame repurpose plan content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--interview-prep" "scripts/generate_founder_fame_repurpose_plan.sh"; then
  echo "Founder fame repurpose plan generator is missing interview-prep option."
  exit 1
fi

if ! rg -Fq -- "--media-blast" "scripts/generate_founder_fame_repurpose_plan.sh"; then
  echo "Founder fame repurpose plan generator is missing media-blast option."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "scripts/generate_founder_fame_repurpose_plan.sh"; then
  echo "Founder fame repurpose plan generator is missing action-queue option."
  exit 1
fi

if ! rg -Fq -- "--transcript-ingestion" "scripts/generate_founder_fame_repurpose_plan.sh"; then
  echo "Founder fame repurpose plan generator is missing transcript-ingestion option."
  exit 1
fi

zsh scripts/generate_credibility_ledger.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --win-card "42" \
  --win-recap "30" \
  --posts "5" \
  --stories "8" \
  --installs "16" \
  --replies-sent "14" \
  --objections-captured "3" \
  --docs-updates "2" \
  --creator-signal-top-handle "@buildwithamy" \
  --guesting-signal-top-target "Dev Productivity Podcast" \
  --distribution-completion-score "82" \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix this week." \
  --variant-recommendation "Keep Variant A as default and test Variant B as challenger." \
  --outreach-recommendation "Prioritize warm intros first and close one collab this week." \
  --out "$tmp_credibility_ledger_file" >/dev/null

if [[ ! -s "$tmp_credibility_ledger_file" ]]; then
  echo "Generated credibility ledger is empty."
  exit 1
fi

required_credibility_ledger_snippets=(
  "<!-- weekly-growth-credibility-ledger -->"
  "# Credibility Ledger: 2099-W01"
  "## Trust Snapshot"
  "## Verified Signals"
  "| Dimension | Evidence | Confidence score | Next proof step |"
  "## Objection Resolution Log"
  "## Credibility Quotes"
  "## Next Proof Actions"
)

for snippet in "${required_credibility_ledger_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_credibility_ledger_file"; then
    echo "Missing credibility ledger content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--objections-captured" "scripts/generate_credibility_ledger.sh"; then
  echo "Credibility ledger generator is missing objections-captured option."
  exit 1
fi

if ! rg -Fq -- "--docs-updates" "scripts/generate_credibility_ledger.sh"; then
  echo "Credibility ledger generator is missing docs-updates option."
  exit 1
fi

if ! rg -Fq -- "--distribution-completion-score" "scripts/generate_credibility_ledger.sh"; then
  echo "Credibility ledger generator is missing distribution completion score option."
  exit 1
fi

cat > "$tmp_founder_fame_file" <<'EOF'
# Founder Fame Pack - 2099-W01

- Momentum score: 82/100 (Breakout)
- Scoreboard state: 3 on track / 1 at risk / 1 off track
- Weekly summary: Weekly KPI momentum is improving with tighter founder execution.
- Current focus: Tighten weakest KPI before expanding channel spend.
EOF

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --week "2099-W01" \
  --fame-pack "$tmp_founder_fame_file" \
  --repurpose-plan "$tmp_founder_fame_repurpose_file" \
  --transcript-ingestion "$tmp_founder_fame_transcript_ingestion_file" \
  --media-blast "$tmp_founder_media_blast_file" \
  --credibility-ledger "$tmp_credibility_ledger_file" \
  --out "$tmp_founder_fame_momentum_brief_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_momentum_brief_file" ]]; then
  echo "Generated founder fame momentum brief is empty."
  exit 1
fi

zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --week "2099-W01" \
  --campaign-dir "$(dirname "$tmp_founder_fame_momentum_brief_file")" \
  --out "$tmp_founder_fame_uplift_tracker_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_uplift_tracker_file" ]]; then
  echo "Generated founder fame uplift tracker is empty."
  exit 1
fi

required_founder_fame_uplift_tracker_snippets=(
  "<!-- founder-fame-uplift-tracker -->"
  "# Founder Fame Uplift Tracker - 2099-W01"
  "## Snapshot"
  "## Uplift Multipliers"
  "## Signal Diagnostics"
  "## Calibration Notes"
  "## Share Block"
  "- momentum uplift multiplier:"
  "- distribution uplift multiplier:"
  "- kpi trendline uplift multiplier:"
  "- reply quality uplift multiplier:"
  "- transcript quality uplift multiplier:"
)

for snippet in "${required_founder_fame_uplift_tracker_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_uplift_tracker_file"; then
    echo "Missing founder fame uplift tracker content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_weight_profile.sh \
  --week "2099-W01" \
  --campaign-dir "$(dirname "$tmp_founder_fame_momentum_brief_file")" \
  --uplift-tracker "$tmp_founder_fame_uplift_tracker_file" \
  --out "$tmp_founder_fame_weight_profile_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_weight_profile_file" ]]; then
  echo "Generated founder fame weight profile is empty."
  exit 1
fi

required_founder_fame_weight_profile_snippets=(
  "<!-- founder-fame-weight-profile -->"
  "# Founder Fame Weight Profile - 2099-W01"
  "## Snapshot"
  "## Recommended Weights"
  "## Signal Diagnostics"
  "## Calibration Notes"
  "## Share Block"
  "- momentum weight:"
  "- distribution weight:"
  "- kpi trendline weight:"
  "- reply quality weight:"
  "- transcript quality weight:"
)

for snippet in "${required_founder_fame_weight_profile_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_weight_profile_file"; then
    echo "Missing founder fame weight profile content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --week "2099-W01" \
  --fame-pack "$tmp_founder_fame_file" \
  --repurpose-plan "$tmp_founder_fame_repurpose_file" \
  --transcript-ingestion "$tmp_founder_fame_transcript_ingestion_file" \
  --media-blast "$tmp_founder_media_blast_file" \
  --credibility-ledger "$tmp_credibility_ledger_file" \
  --weight-profile "$tmp_founder_fame_weight_profile_file" \
  --out "$tmp_founder_fame_momentum_brief_file" >/dev/null

required_founder_fame_momentum_brief_snippets=(
  "<!-- founder-fame-momentum-brief -->"
  "# Founder Fame Momentum Brief - 2099-W01"
  "## Snapshot"
  "## Fame Readiness Score"
  "## Signal Fusion Breakdown"
  "## Narrative Stack"
  "## Risk Radar"
  "## Next 48 Hours"
  "## Founder Share Block"
  "Weight profile mode:"
  "Uplift profile mode:"
  "Weight source:"
)

for snippet in "${required_founder_fame_momentum_brief_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_momentum_brief_file"; then
    echo "Missing founder fame momentum brief content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --week "2099-W01" \
  --momentum-brief "$tmp_founder_fame_momentum_brief_file" \
  --weight-profile "$tmp_founder_fame_weight_profile_file" \
  --uplift-tracker "$tmp_founder_fame_uplift_tracker_file" \
  --winning-hook-library "$tmp_winning_hook_library_file" \
  --credibility-ledger "$tmp_credibility_ledger_file" \
  --narrative-route-winner "Proof-first route" \
  --narrative-route-trend "holding Proof-first route" \
  --narrative-fame-velocity-score "78%" \
  --narrative-route-recommendation "Keep Proof-first route as lead narrative route and scale it across both channels while preserving proof guardrails." \
  --out "$tmp_founder_fame_opportunity_radar_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_opportunity_radar_file" ]]; then
  echo "Generated founder fame opportunity radar is empty."
  exit 1
fi

required_founder_fame_opportunity_radar_snippets=(
  "<!-- founder-fame-opportunity-radar -->"
  "# Founder Fame Opportunity Radar - 2099-W01"
  "## Snapshot"
  "## Ranked Opportunities"
  "## Action Plans"
  "## Weekly Fame Bet"
  "## Share Block"
  "Uplift mode:"
  "Founder narrative route winner: Proof-first route"
  "Narrative-ranked opportunity: KPI Proof Amplifier"
  "Narrative-ranked opportunity:"
)

for snippet in "${required_founder_fame_opportunity_radar_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_opportunity_radar_file"; then
    echo "Missing founder fame opportunity radar content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_execution_sprint.sh \
  --week "2099-W01" \
  --opportunity-radar "$tmp_founder_fame_opportunity_radar_file" \
  --momentum-brief "$tmp_founder_fame_momentum_brief_file" \
  --out "$tmp_founder_fame_execution_sprint_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_execution_sprint_file" ]]; then
  echo "Generated founder fame execution sprint is empty."
  exit 1
fi

required_founder_fame_execution_sprint_snippets=(
  "<!-- founder-fame-execution-sprint -->"
  "# Founder Fame Execution Sprint - 2099-W01"
  "## Snapshot"
  "## Weekly Fame Objective"
  "## Narrative Route Execution Mode"
  "## 7-Day Mission Board"
  "## Daily Check-In Prompts"
  "## Escalation Triggers"
  "## Share Block"
  "Narrative route winner: Proof-first route"
  "Execution mode: Proof-first acceleration mode"
  "Narrative-ranked opportunity: KPI Proof Amplifier"
)

for snippet in "${required_founder_fame_execution_sprint_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_execution_sprint_file"; then
    echo "Missing founder fame execution sprint content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --week "2099-W01" \
  --execution-sprint "$tmp_founder_fame_execution_sprint_file" \
  --opportunity-radar "$tmp_founder_fame_opportunity_radar_file" \
  --momentum-brief "$tmp_founder_fame_momentum_brief_file" \
  --out "$tmp_founder_fame_execution_scorecard_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_execution_scorecard_file" ]]; then
  echo "Generated founder fame execution scorecard is empty."
  exit 1
fi

required_founder_fame_execution_scorecard_snippets=(
  "<!-- founder-fame-execution-scorecard -->"
  "# Founder Fame Execution Scorecard - 2099-W01"
  "## Snapshot"
  "## Narrative Route Alignment"
  "## Execution Readiness Score"
  "## Signal Breakdown"
  "## Launch Gates"
  "## Daily Rhythm Checks"
  "## Risk Flags"
  "## Next 24 Hours"
  "## Share Block"
  "Route alignment signal: Aligned"
  "Narrative route alignment | Aligned (3/3 checks) | 2/2"
)

for snippet in "${required_founder_fame_execution_scorecard_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_execution_scorecard_file"; then
    echo "Missing founder fame execution scorecard content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --week "2099-W01" \
  --execution-scorecard "$tmp_founder_fame_execution_scorecard_file" \
  --execution-sprint "$tmp_founder_fame_execution_sprint_file" \
  --opportunity-radar "$tmp_founder_fame_opportunity_radar_file" \
  --momentum-brief "$tmp_founder_fame_momentum_brief_file" \
  --distribution-plan "$tmp_distribution_plan_file" \
  --out "$tmp_founder_fame_risk_response_plan_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_risk_response_plan_file" ]]; then
  echo "Generated founder fame risk response plan is empty."
  exit 1
fi

required_founder_fame_risk_response_plan_snippets=(
  "<!-- founder-fame-risk-response-plan -->"
  "# Founder Fame Risk Response Plan - 2099-W01"
  "## Snapshot"
  "## Risk Response Signal"
  "## Narrative Route Risk Controls"
  "## Priority Risk Queue"
  "## 72-Hour Stabilization Plan"
  "## Mitigation Checkpoints"
  "## Escalation Conditions"
  "## Share Block"
  "Route alignment signal context: Aligned"
)

for snippet in "${required_founder_fame_risk_response_plan_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_risk_response_plan_file"; then
    echo "Missing founder fame risk response plan content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_escalation_queue.sh \
  --week "2099-W01" \
  --risk-response-plan "$tmp_founder_fame_risk_response_plan_file" \
  --execution-scorecard "$tmp_founder_fame_execution_scorecard_file" \
  --execution-sprint "$tmp_founder_fame_execution_sprint_file" \
  --distribution-plan "$tmp_distribution_plan_file" \
  --out "$tmp_founder_fame_escalation_queue_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_escalation_queue_file" ]]; then
  echo "Generated founder fame escalation queue is empty."
  exit 1
fi

required_founder_fame_escalation_queue_snippets=(
  "<!-- founder-fame-escalation-queue -->"
  "# Founder Fame Escalation Queue - 2099-W01"
  "## Snapshot"
  "## Escalation Queue Signal"
  "## Narrative Route Escalation Lane"
  "## Immediate Escalation Queue"
  "## Owner Routing Notes"
  "## First 24 Hours"
  "## Escalation Conditions"
  "## Share Block"
  "Route alignment signal context: Aligned"
)

for snippet in "${required_founder_fame_escalation_queue_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_escalation_queue_file"; then
    echo "Missing founder fame escalation queue content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_command_center.sh \
  --week "2099-W01" \
  --momentum-brief "$tmp_founder_fame_momentum_brief_file" \
  --execution-scorecard "$tmp_founder_fame_execution_scorecard_file" \
  --risk-response-plan "$tmp_founder_fame_risk_response_plan_file" \
  --escalation-queue "$tmp_founder_fame_escalation_queue_file" \
  --opportunity-radar "$tmp_founder_fame_opportunity_radar_file" \
  --out "$tmp_founder_fame_command_center_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_command_center_file" ]]; then
  echo "Generated founder fame command center is empty."
  exit 1
fi

required_founder_fame_command_center_snippets=(
  "<!-- founder-fame-command-center -->"
  "# Founder Fame Command Center - 2099-W01"
  "## Snapshot"
  "## Narrative Route Control Tower"
  "## Next 24 Hours"
  "## Trigger Matrix"
  "## Standup Share Block"
  "## In-App Fast Loop"
  "## Update Cadence"
  "Route alignment: Aligned"
)

for snippet in "${required_founder_fame_command_center_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_command_center_file"; then
    echo "Missing founder fame command center content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_next_move_handoff.sh \
  --week "2099-W01" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --artifact-link "$tmp_founder_fame_command_center_file" \
  --out "$tmp_founder_fame_next_move_handoff_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_next_move_handoff_file" ]]; then
  echo "Generated founder fame next-move handoff is empty."
  exit 1
fi

required_founder_fame_next_move_handoff_snippets=(
  "<!-- founder-fame-next-move-handoff -->"
  "# Founder Fame Next Move Handoff - 2099-W01"
  "## Action"
  "In-app move: Run Fame Next Move"
  "Checklist target: Monday Publish Checklist <week>"
  "Source artifact: $tmp_founder_fame_command_center_file"
  "## Checklist Comment Draft"
  "Founder fame next move handoff (2099-W01)"
  "Action: Run Fame Next Move"
  "Artifact link: $tmp_founder_fame_command_center_file"
  "Owner: <name> - shared update pending."
  "## Operator Notes"
  "Run this move immediately after command-center standup."
  "Post artifact link plus owner update in the checklist comment."
)

for snippet in "${required_founder_fame_next_move_handoff_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_next_move_handoff_file"; then
    echo "Missing founder fame next-move handoff content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --momentum-brief "$tmp_founder_fame_momentum_brief_file" \
  --execution-scorecard "$tmp_founder_fame_execution_scorecard_file" \
  --risk-response-plan "$tmp_founder_fame_risk_response_plan_file" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "Reply with your KPI bottleneck and I will share the exact command stack." \
  --out "$tmp_founder_fame_spotlight_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_spotlight_file" ]]; then
  echo "Generated founder fame spotlight pack is empty."
  exit 1
fi

required_founder_fame_spotlight_snippets=(
  "<!-- founder-fame-spotlight-pack -->"
  "# Founder Fame Spotlight Pack - 2099-W01"
  "## Snapshot"
  "## Daily Spotlight Sequence"
  "## Copy-Ready Posts"
  "## Route Integrity Messaging"
  "## Live Objection Replies"
  "## Media / Partner Pitches"
  "## Standup-to-Public Bridge"
  "## Execution Checklist"
  "Route alignment signal: Aligned"
)

for snippet in "${required_founder_fame_spotlight_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_spotlight_file"; then
    echo "Missing founder fame spotlight pack content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_breakout_plan.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --spotlight-pack "$tmp_founder_fame_spotlight_file" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --execution-sprint "$tmp_founder_fame_execution_sprint_file" \
  --distribution-plan "$tmp_distribution_plan_file" \
  --winning-hook-library "$tmp_winning_hook_library_file" \
  --credibility-ledger "$tmp_credibility_ledger_file" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "Reply with your KPI bottleneck and I will share the exact command stack." \
  --out "$tmp_founder_fame_breakout_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_breakout_file" ]]; then
  echo "Generated founder fame breakout plan is empty."
  exit 1
fi

required_founder_fame_breakout_snippets=(
  "<!-- founder-fame-breakout-plan -->"
  "# Founder Fame Breakout Plan - 2099-W01"
  "## Snapshot"
  "## Breakout Thesis"
  "## Narrative Route Scale Plan"
  "## 7-Day Fame Cadence"
  "## Channel Script Blocks"
  "## Partnership Bursts"
  "## Fame Flywheel Metrics"
  "## Daily Standup Prompts"
  "## Execution Checklist"
  "Route integrity | Proof-first route / Aligned"
)

for snippet in "${required_founder_fame_breakout_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_breakout_file"; then
    echo "Missing founder fame breakout plan content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --breakout-plan "$tmp_founder_fame_breakout_file" \
  --creator-target-list "$tmp_creator_target_list_file" \
  --distribution-plan "$tmp_distribution_plan_file" \
  --media-blast "$tmp_founder_media_blast_file" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "Reply with your KPI bottleneck and I will share the exact command stack." \
  --out "$tmp_founder_fame_outreach_sprint_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_outreach_sprint_file" ]]; then
  echo "Generated founder fame outreach sprint is empty."
  exit 1
fi

required_founder_fame_outreach_sprint_snippets=(
  "<!-- founder-fame-outreach-sprint -->"
  "# Founder Fame Outreach Sprint - 2099-W01"
  "## Snapshot"
  "## Outreach Thesis"
  "## Narrative Route Outreach Controls"
  "## 7-Day Outreach Sprint Grid"
  "## Creator Conversation Blocks"
  "## Guesting Booking Blocks"
  "## Follow-Up Cadence"
  "## Daily Standup Prompts"
  "## Execution Checklist"
  "Route outreach mode: Route-Locked Outreach"
)

for snippet in "${required_founder_fame_outreach_sprint_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_outreach_sprint_file"; then
    echo "Missing founder fame outreach sprint content: $snippet"
    exit 1
  fi
done

zsh scripts/generate_founder_fame_proof_loop.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --breakout-plan "$tmp_founder_fame_breakout_file" \
  --outreach-sprint "$tmp_founder_fame_outreach_sprint_file" \
  --spotlight-pack "$tmp_founder_fame_spotlight_file" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --credibility-ledger "$tmp_credibility_ledger_file" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "Reply with your KPI bottleneck and I will share the exact command stack." \
  --out "$tmp_founder_fame_proof_loop_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_proof_loop_file" ]]; then
  echo "Generated founder fame proof loop is empty."
  exit 1
fi

required_founder_fame_proof_loop_snippets=(
  "<!-- founder-fame-proof-loop -->"
  "# Founder Fame Proof Loop - 2099-W01"
  "## Snapshot"
  "## Proof Loop Scorecard"
  "## Narrative Route Proof Lane"
  "## 72-Hour Loop Plan"
  "## Channel Proof Scripts"
  "## Conversion Signals to Log"
  "## Daily Standup Prompts"
  "## Execution Checklist"
  "Route integrity | Proof-first route / Aligned"
)

for snippet in "${required_founder_fame_proof_loop_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_proof_loop_file"; then
    echo "Missing founder fame proof loop content: $snippet"
    exit 1
  fi
done

if ! zsh scripts/verify_founder_fame_proof_loop.sh --help >/dev/null; then
  echo "Founder fame proof loop verifier help command failed."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_proof_loop.sh \
  --proof-loop "$tmp_founder_fame_proof_loop_file" \
  --out "$sample_proof_loop_report_file" >/dev/null; then
  echo "Founder fame proof loop verifier failed on generated artifact."
  exit 1
fi

if ! rg -Fq -- "- Status: PASS" "$sample_proof_loop_report_file"; then
  echo "Founder fame proof loop verifier report is missing PASS status."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_proof_loop.sh \
  --proof-loop "$tmp_founder_fame_proof_loop_file" \
  --strict \
  --out "$sample_proof_loop_report_strict_file" >/dev/null; then
  echo "Founder fame proof loop verifier strict mode failed on generated artifact."
  exit 1
fi

if ! rg -Fq -- "- Mode: strict" "$sample_proof_loop_report_strict_file"; then
  echo "Founder fame proof loop strict report is missing strict mode marker."
  exit 1
fi

if ! rg -Fq -- "- Status: PASS" "$sample_proof_loop_report_strict_file"; then
  echo "Founder fame proof loop strict report is missing PASS status."
  exit 1
fi

zsh scripts/generate_founder_fame_kpi_snapshot.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --proof-loop "$tmp_founder_fame_proof_loop_file" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --proof-loop-check "$sample_proof_loop_report_strict_file" \
  --out "$tmp_founder_fame_kpi_snapshot_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_kpi_snapshot_file" ]]; then
  echo "Generated founder fame KPI snapshot is empty."
  exit 1
fi

required_founder_fame_kpi_snapshot_snippets=(
  "<!-- founder-fame-kpi-snapshot -->"
  "# Founder Fame KPI Snapshot - 2099-W01"
  "## Snapshot"
  "## KPI Pulse"
  "## Verification Pulse"
  "## Narrative Route KPI Controls"
  "## 72-Hour KPI Actions"
  "## Share Block"
  "## Execution Checklist"
  "Route integrity |"
)

for snippet in "${required_founder_fame_kpi_snapshot_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_kpi_snapshot_file"; then
    echo "Missing founder fame KPI snapshot content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--proof-loop-check" "scripts/generate_founder_fame_kpi_snapshot.sh"; then
  echo "Founder fame KPI snapshot generator is missing proof-loop-check option."
  exit 1
fi

zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --kpi-snapshot "$tmp_founder_fame_kpi_snapshot_file" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --proof-loop-check "$sample_proof_loop_report_strict_file" \
  --out "$tmp_founder_fame_velocity_scoreboard_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_velocity_scoreboard_file" ]]; then
  echo "Generated founder fame velocity scoreboard is empty."
  exit 1
fi

required_founder_fame_velocity_scoreboard_snippets=(
  "<!-- founder-fame-velocity-scoreboard -->"
  "# Founder Fame Velocity Scoreboard - 2099-W01"
  "## Snapshot"
  "## Velocity Scoreboard"
  "## Route Velocity Controls"
  "## 72-Hour Velocity Plays"
  "## Checklist Comment Draft"
  "## Share Block"
  "## Execution Checklist"
  "Velocity score:"
  "Priority move:"
)

for snippet in "${required_founder_fame_velocity_scoreboard_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_velocity_scoreboard_file"; then
    echo "Missing founder fame velocity scoreboard content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--kpi-snapshot" "scripts/generate_founder_fame_velocity_scoreboard.sh"; then
  echo "Founder fame velocity scoreboard generator is missing kpi-snapshot option."
  exit 1
fi

zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --kpi-snapshot "$tmp_founder_fame_kpi_snapshot_file" \
  --velocity-scoreboard "$tmp_founder_fame_velocity_scoreboard_file" \
  --out "$tmp_founder_fame_exceptional_loop_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_exceptional_loop_file" ]]; then
  echo "Generated founder fame exceptional loop is empty."
  exit 1
fi

required_founder_fame_exceptional_loop_snippets=(
  "<!-- founder-fame-exceptional-loop -->"
  "# Founder Fame Exceptional Loop - 2099-W01"
  "## Signal Snapshot"
  "## 72-Hour Exceptional Loop"
  "## Fame Multipliers"
  "## Public Narrative Hooks"
  "## Operator Marker Block"
  "weekly-growth-founder-fame-exceptional-loop"
)

for snippet in "${required_founder_fame_exceptional_loop_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_exceptional_loop_file"; then
    echo "Missing founder fame exceptional loop content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--kpi-snapshot" "scripts/generate_founder_fame_exceptional_loop.sh"; then
  echo "Founder fame exceptional loop generator is missing kpi-snapshot option."
  exit 1
fi

if ! rg -Fq -- "--velocity-scoreboard" "scripts/generate_founder_fame_exceptional_loop.sh"; then
  echo "Founder fame exceptional loop generator is missing velocity-scoreboard option."
  exit 1
fi

zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --kpi-snapshot "$tmp_founder_fame_kpi_snapshot_file" \
  --proof-loop "$tmp_founder_fame_proof_loop_file" \
  --command-center "$tmp_founder_fame_command_center_file" \
  --winning-hook-library "$tmp_winning_hook_library_file" \
  --credibility-ledger "$tmp_credibility_ledger_file" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out "$tmp_founder_fame_narrative_lab_file" >/dev/null

if [[ ! -s "$tmp_founder_fame_narrative_lab_file" ]]; then
  echo "Generated founder fame narrative lab is empty."
  exit 1
fi

required_founder_fame_narrative_lab_snippets=(
  "<!-- founder-fame-narrative-lab -->"
  "# Founder Fame Narrative Lab - 2099-W01"
  "## Snapshot"
  "## Narrative Route Lab Controls"
  "## Ranked Narrative Routes"
  "## Channel Scripts"
  "## 7-Day Distribution Calendar"
  "## 7-Day Narrative Cadence"
  "## Reply Ladder"
  "## Experiment Checklist"
)

for snippet in "${required_founder_fame_narrative_lab_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_fame_narrative_lab_file"; then
    echo "Missing founder fame narrative lab content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--kpi-snapshot" "scripts/generate_founder_fame_narrative_lab.sh"; then
  echo "Founder fame narrative lab generator is missing kpi-snapshot option."
  exit 1
fi

if ! rg -Fq -- "--winning-hook-library" "scripts/generate_founder_fame_narrative_lab.sh"; then
  echo "Founder fame narrative lab generator is missing winning-hook-library option."
  exit 1
fi

if ! rg -Fq -- "--primary-audience-region" "scripts/generate_founder_fame_narrative_lab.sh"; then
  echo "Founder fame narrative lab generator is missing primary-audience-region option."
  exit 1
fi

zsh scripts/generate_founder_first48h_post_pack.sh \
  --week "2099-W01" \
  --product "Fluid Reader" \
  --narrative-lab "$tmp_founder_fame_narrative_lab_file" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "Want a private demo pass and the exact setup flow?" \
  --primary-char-limit 240 \
  --backup-char-limit 420 \
  --out "$tmp_founder_first48h_post_pack_file" >/dev/null

if [[ ! -s "$tmp_founder_first48h_post_pack_file" ]]; then
  echo "Generated founder first-48h post pack is empty."
  exit 1
fi

required_founder_first48h_post_pack_snippets=(
  "<!-- weekly-growth-founder-first48h-post-pack -->"
  "# Founder First 48h Post Pack: 2099-W01"
  "## Signal Snapshot"
  "## Day 0 Launch Copy (Lead)"
  "## Day 1 Reinforcement Copy (Support)"
  "## Day 2 Compounding Copy (Scale)"
  "## Channel-Ready Short Variants"
  "### Day 0 Short Variants"
  "### Day 1 Short Variants"
  "### Day 2 Short Variants"
  "Primary short variant target: <=240 chars"
  "Backup short variant target: <=420 chars"
  "Primary tone profile: x-punchy"
  "Backup tone profile: linkedin-context"
  "## Route Control Handshake (First 48h)"
  "## 48h Micro-Experiment Board"
  "## Rapid Reply Prompts"
  "## Comment Trigger Seeds (Post-Reply Boost)"
  "## Objection Response Ladder"
  "### 1) “Will this route work in my context?”"
  "### 2) “I do not have time to run this every week.”"
  "### 3) “Show me proof before I copy this.”"
  "## Escalation & Adaptation Triggers"
  "## First 48h Execution Checklist"
  "CTA line: Want a private demo pass and the exact setup flow?"
)

for snippet in "${required_founder_first48h_post_pack_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_founder_first48h_post_pack_file"; then
    echo "Missing founder first-48h post pack content: $snippet"
    exit 1
  fi
done

if ! rg -Fq -- "--narrative-lab" "scripts/generate_founder_first48h_post_pack.sh"; then
  echo "Founder first-48h post pack generator is missing narrative-lab option."
  exit 1
fi

if ! rg -Fq -- "--cta" "scripts/generate_founder_first48h_post_pack.sh"; then
  echo "Founder first-48h post pack generator is missing cta option."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit" "scripts/generate_founder_first48h_post_pack.sh"; then
  echo "Founder first-48h post pack generator is missing primary-char-limit option."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit" "scripts/generate_founder_first48h_post_pack.sh"; then
  echo "Founder first-48h post pack generator is missing backup-char-limit option."
  exit 1
fi

if ! rg -Fq -- "--primary-tone" "scripts/generate_founder_first48h_post_pack.sh"; then
  echo "Founder first-48h post pack generator is missing primary-tone option."
  exit 1
fi

if ! rg -Fq -- "--backup-tone" "scripts/generate_founder_first48h_post_pack.sh"; then
  echo "Founder first-48h post pack generator is missing backup-tone option."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_proof_loop_run.sh --help >/dev/null; then
  echo "Founder fame proof loop live verifier help command failed."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_founder_fame_proof_loop_run.sh"; then
  echo "Founder fame proof loop live verifier is missing strict mode option."
  exit 1
fi

if ! rg -Fq -- "--check <path>" "scripts/verify_founder_fame_proof_loop_run.sh"; then
  echo "Founder fame proof loop live verifier is missing check-file mode option."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_proof_loop_run.sh \
  --sample \
  --run-id check-growth-founder-live-sample \
  --out "$sample_founder_live_run_report_file" >/dev/null; then
  echo "Founder fame proof loop live verifier sample mode failed."
  exit 1
fi

if ! rg -Fq -- "- Result: PASS" "$sample_founder_live_run_report_file"; then
  echo "Founder fame proof loop live verifier sample report is missing PASS verdict."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_proof_loop_run.sh \
  --check "$sample_founder_live_source_check_file" \
  --repo "n/a" \
  --run-id check-growth-founder-live-check-mode \
  --out "$sample_founder_live_run_check_mode_report_file" >/dev/null; then
  echo "Founder fame proof loop live verifier check-file mode failed."
  exit 1
fi

if ! rg -Fq -- "- Mode: check" "$sample_founder_live_run_check_mode_report_file"; then
  echo "Founder fame proof loop live verifier check-file report is missing check mode marker."
  exit 1
fi

if ! rg -Fq -- "- Result: PASS" "$sample_founder_live_run_check_mode_report_file"; then
  echo "Founder fame proof loop live verifier check-file report is missing PASS verdict."
  exit 1
fi

if ! rg -Fq -- "--fame-pack" "scripts/generate_founder_fame_momentum_brief.sh"; then
  echo "Founder fame momentum brief generator is missing fame-pack option."
  exit 1
fi

if ! rg -Fq -- "--repurpose-plan" "scripts/generate_founder_fame_momentum_brief.sh"; then
  echo "Founder fame momentum brief generator is missing repurpose-plan option."
  exit 1
fi

if ! rg -Fq -- "--credibility-ledger" "scripts/generate_founder_fame_momentum_brief.sh"; then
  echo "Founder fame momentum brief generator is missing credibility-ledger option."
  exit 1
fi

if ! rg -Fq -- "--weight-profile" "scripts/generate_founder_fame_momentum_brief.sh"; then
  echo "Founder fame momentum brief generator is missing weight-profile option."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief" "scripts/generate_founder_fame_opportunity_radar.sh"; then
  echo "Founder fame opportunity radar generator is missing momentum-brief option."
  exit 1
fi

if ! rg -Fq -- "--winning-hook-library" "scripts/generate_founder_fame_opportunity_radar.sh"; then
  echo "Founder fame opportunity radar generator is missing winning-hook-library option."
  exit 1
fi

if ! rg -Fq -- "--credibility-ledger" "scripts/generate_founder_fame_opportunity_radar.sh"; then
  echo "Founder fame opportunity radar generator is missing credibility-ledger option."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-winner" "scripts/generate_founder_fame_opportunity_radar.sh"; then
  echo "Founder fame opportunity radar generator is missing narrative-route-winner option."
  exit 1
fi

if ! rg -Fq -- "--narrative-fame-velocity-score" "scripts/generate_founder_fame_opportunity_radar.sh"; then
  echo "Founder fame opportunity radar generator is missing narrative-fame-velocity-score option."
  exit 1
fi

if ! rg -Fq -- "--opportunity-radar" "scripts/generate_founder_fame_execution_sprint.sh"; then
  echo "Founder fame execution sprint generator is missing opportunity-radar option."
  exit 1
fi

if ! rg -Fq -- "--distribution-plan" "scripts/generate_founder_fame_execution_sprint.sh"; then
  echo "Founder fame execution sprint generator is missing distribution-plan option."
  exit 1
fi

if ! rg -Fq -- "--reply-pack" "scripts/generate_founder_fame_execution_sprint.sh"; then
  echo "Founder fame execution sprint generator is missing reply-pack option."
  exit 1
fi

if ! rg -Fq -- "--execution-sprint" "scripts/generate_founder_fame_execution_scorecard.sh"; then
  echo "Founder fame execution scorecard generator is missing execution-sprint option."
  exit 1
fi

if ! rg -Fq -- "--monday-checkpoint" "scripts/generate_founder_fame_execution_scorecard.sh"; then
  echo "Founder fame execution scorecard generator is missing monday-checkpoint option."
  exit 1
fi

if ! rg -Fq -- "--reply-pack" "scripts/generate_founder_fame_execution_scorecard.sh"; then
  echo "Founder fame execution scorecard generator is missing reply-pack option."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard" "scripts/generate_founder_fame_risk_response_plan.sh"; then
  echo "Founder fame risk response plan generator is missing execution-scorecard option."
  exit 1
fi

if ! rg -Fq -- "--distribution-plan" "scripts/generate_founder_fame_risk_response_plan.sh"; then
  echo "Founder fame risk response plan generator is missing distribution-plan option."
  exit 1
fi

if ! rg -Fq -- "--reply-pack" "scripts/generate_founder_fame_risk_response_plan.sh"; then
  echo "Founder fame risk response plan generator is missing reply-pack option."
  exit 1
fi

if ! rg -Fq -- "--risk-response-plan" "scripts/generate_founder_fame_escalation_queue.sh"; then
  echo "Founder fame escalation queue generator is missing risk-response-plan option."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard" "scripts/generate_founder_fame_escalation_queue.sh"; then
  echo "Founder fame escalation queue generator is missing execution-scorecard option."
  exit 1
fi

if ! rg -Fq -- "--distribution-plan" "scripts/generate_founder_fame_escalation_queue.sh"; then
  echo "Founder fame escalation queue generator is missing distribution-plan option."
  exit 1
fi

if ! rg -Fq -- "--reply-pack" "scripts/generate_founder_fame_escalation_queue.sh"; then
  echo "Founder fame escalation queue generator is missing reply-pack option."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief" "scripts/generate_founder_fame_command_center.sh"; then
  echo "Founder fame command center generator is missing momentum-brief option."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard" "scripts/generate_founder_fame_command_center.sh"; then
  echo "Founder fame command center generator is missing execution-scorecard option."
  exit 1
fi

if ! rg -Fq -- "--risk-response-plan" "scripts/generate_founder_fame_command_center.sh"; then
  echo "Founder fame command center generator is missing risk-response-plan option."
  exit 1
fi

if ! rg -Fq -- "--escalation-queue" "scripts/generate_founder_fame_command_center.sh"; then
  echo "Founder fame command center generator is missing escalation-queue option."
  exit 1
fi

if ! rg -Fq -- "--opportunity-radar" "scripts/generate_founder_fame_command_center.sh"; then
  echo "Founder fame command center generator is missing opportunity-radar option."
  exit 1
fi

if ! rg -Fq -- "--command-center" "scripts/generate_founder_fame_spotlight_pack.sh"; then
  echo "Founder fame spotlight pack generator is missing command-center option."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief" "scripts/generate_founder_fame_spotlight_pack.sh"; then
  echo "Founder fame spotlight pack generator is missing momentum-brief option."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard" "scripts/generate_founder_fame_spotlight_pack.sh"; then
  echo "Founder fame spotlight pack generator is missing execution-scorecard option."
  exit 1
fi

if ! rg -Fq -- "--risk-response-plan" "scripts/generate_founder_fame_spotlight_pack.sh"; then
  echo "Founder fame spotlight pack generator is missing risk-response-plan option."
  exit 1
fi

if ! rg -Fq -- "--primary-channel" "scripts/generate_founder_fame_spotlight_pack.sh"; then
  echo "Founder fame spotlight pack generator is missing primary-channel option."
  exit 1
fi

if ! rg -Fq -- "--backup-channel" "scripts/generate_founder_fame_spotlight_pack.sh"; then
  echo "Founder fame spotlight pack generator is missing backup-channel option."
  exit 1
fi

if ! rg -Fq -- "--spotlight-pack" "scripts/generate_founder_fame_breakout_plan.sh"; then
  echo "Founder fame breakout plan generator is missing spotlight-pack option."
  exit 1
fi

if ! rg -Fq -- "--command-center" "scripts/generate_founder_fame_breakout_plan.sh"; then
  echo "Founder fame breakout plan generator is missing command-center option."
  exit 1
fi

if ! rg -Fq -- "--execution-sprint" "scripts/generate_founder_fame_breakout_plan.sh"; then
  echo "Founder fame breakout plan generator is missing execution-sprint option."
  exit 1
fi

if ! rg -Fq -- "--distribution-plan" "scripts/generate_founder_fame_breakout_plan.sh"; then
  echo "Founder fame breakout plan generator is missing distribution-plan option."
  exit 1
fi

if ! rg -Fq -- "--winning-hook-library" "scripts/generate_founder_fame_breakout_plan.sh"; then
  echo "Founder fame breakout plan generator is missing winning-hook-library option."
  exit 1
fi

if ! rg -Fq -- "--credibility-ledger" "scripts/generate_founder_fame_breakout_plan.sh"; then
  echo "Founder fame breakout plan generator is missing credibility-ledger option."
  exit 1
fi

if ! rg -Fq -- "--breakout-plan" "scripts/generate_founder_fame_outreach_sprint.sh"; then
  echo "Founder fame outreach sprint generator is missing breakout-plan option."
  exit 1
fi

if ! rg -Fq -- "--guesting-queue" "scripts/generate_founder_fame_outreach_sprint.sh"; then
  echo "Founder fame outreach sprint generator is missing guesting-queue option."
  exit 1
fi

if ! rg -Fq -- "--creator-target-list" "scripts/generate_founder_fame_outreach_sprint.sh"; then
  echo "Founder fame outreach sprint generator is missing creator-target-list option."
  exit 1
fi

if ! rg -Fq -- "--distribution-plan" "scripts/generate_founder_fame_outreach_sprint.sh"; then
  echo "Founder fame outreach sprint generator is missing distribution-plan option."
  exit 1
fi

if ! rg -Fq -- "--media-blast" "scripts/generate_founder_fame_outreach_sprint.sh"; then
  echo "Founder fame outreach sprint generator is missing media-blast option."
  exit 1
fi

if ! rg -Fq -- "--breakout-plan" "scripts/generate_founder_fame_proof_loop.sh"; then
  echo "Founder fame proof loop generator is missing breakout-plan option."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint" "scripts/generate_founder_fame_proof_loop.sh"; then
  echo "Founder fame proof loop generator is missing outreach-sprint option."
  exit 1
fi

if ! rg -Fq -- "--command-center" "scripts/generate_founder_fame_proof_loop.sh"; then
  echo "Founder fame proof loop generator is missing command-center option."
  exit 1
fi

if ! rg -Fq -- "--campaign-dir" "scripts/generate_founder_fame_weight_profile.sh"; then
  echo "Founder fame weight profile generator is missing campaign-dir option."
  exit 1
fi

if ! rg -Fq -- "--uplift-tracker" "scripts/generate_founder_fame_weight_profile.sh"; then
  echo "Founder fame weight profile generator is missing uplift-tracker option."
  exit 1
fi

if ! rg -Fq -- "--campaign-dir" "scripts/generate_founder_fame_uplift_tracker.sh"; then
  echo "Founder fame uplift tracker generator is missing campaign-dir option."
  exit 1
fi

zsh scripts/generate_first24h_reply_pack.sh \
  --week "2099-W01" \
  --metric-focus "Win Card copies and installs" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --strongest-metric-label "Win Card copies" \
  --strongest-metric-value "42" \
  --command "Copy Win Card" \
  --out "$tmp_reply_pack_file" >/dev/null

if [[ ! -s "$tmp_reply_pack_file" ]]; then
  echo "Generated first-24h reply pack is empty."
  exit 1
fi

required_reply_pack_snippets=(
  "<!-- weekly-growth-reply-pack -->"
  "# First 24-Hour Reply Pack: 2099-W01"
  "## Core Replies"
  "## Channel-Ready Variants"
  "### X / Threads (Primary channel)"
  "#### Variant A (proof-first)"
  "#### Variant B (workflow-first)"
  "#### Variant C (objection-handler)"
  "## First 24-Hour Execution Checklist"
)

for snippet in "${required_reply_pack_snippets[@]}"; do
  if ! rg -Fq -- "$snippet" "$tmp_reply_pack_file"; then
    echo "Missing first-24h reply pack content: $snippet"
    exit 1
  fi
done

if ! rg -Fq "## Permission to feature" ".github/ISSUE_TEMPLATE/win_story.md"; then
  echo "Win story template is missing permission section."
  exit 1
fi

if ! rg -Fq "labels: community, social-proof" ".github/ISSUE_TEMPLATE/win_story.md"; then
  echo "Win story template is missing social-proof labeling."
  exit 1
fi

if ! zsh scripts/run_launch_day.sh --help >/dev/null; then
  echo "Launch day runner help command failed."
  exit 1
fi

if ! rg -Fq "scripts/run_launch_day.sh" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan is missing run_launch_day command."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan is missing founder fame proof loop artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-kpi-snapshot" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan is missing founder fame KPI snapshot artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-velocity-scoreboard" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan is missing founder fame velocity scoreboard artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan is missing founder fame exceptional loop artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-narrative-lab" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan is missing founder fame narrative lab artifact guidance."
  exit 1
fi

if ! rg -Fq "workflow_dispatch" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing workflow_dispatch trigger."
  exit 1
fi

if ! rg -Fq "scripts/run_launch_day.sh" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not call run_launch_day.sh."
  exit 1
fi

if ! rg -Fq "proof_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing social proof output wiring."
  exit 1
fi

if ! rg -Fq -- "--proof-out \"\$proof_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire social proof output path into launch runner."
  exit 1
fi

if ! rg -Fq "weekly_issue_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing weekly growth issue output wiring."
  exit 1
fi

if ! rg -Fq -- "--weekly-issue-out \"\$weekly_issue_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire weekly growth issue output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_update_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder update output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-update-out \"\$founder_update_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder update output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-out \"\$founder_fame_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_press_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder press output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-press-out \"\$founder_press_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder press output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_media_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder media output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-media-out \"\$founder_media_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder media output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_ops_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame ops brief output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-ops-out \"\$founder_fame_ops_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame ops brief output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_action_queue_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame action queue output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_daily_mission_freshness=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame daily mission freshness output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-action-queue-out \"\$founder_fame_action_queue_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame action queue output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_interview_prep_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame interview prep output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-interview-prep-out \"\$founder_fame_interview_prep_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame interview prep output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_transcript_ingestion_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame transcript ingestion output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-transcript-ingestion-out \"\$founder_fame_transcript_ingestion_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame transcript ingestion output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_repurpose_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame repurpose plan output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-repurpose-out \"\$founder_fame_repurpose_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame repurpose output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_uplift_tracker_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame uplift tracker output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-uplift-tracker-out \"\$founder_fame_uplift_tracker_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame uplift tracker output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_weight_profile_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame weight profile output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-weight-profile-out \"\$founder_fame_weight_profile_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame weight profile output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_momentum_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame momentum brief output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-momentum-out \"\$founder_fame_momentum_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame momentum brief output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_opportunity_radar_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame opportunity radar output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-opportunity-radar-out \"\$founder_fame_opportunity_radar_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame opportunity radar output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_execution_sprint_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame execution sprint output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-execution-sprint-out \"\$founder_fame_execution_sprint_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame execution sprint output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_execution_scorecard_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame execution scorecard output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-execution-scorecard-out \"\$founder_fame_execution_scorecard_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame execution scorecard output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_risk_response_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame risk response plan output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-risk-response-out \"\$founder_fame_risk_response_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame risk response plan output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_escalation_queue_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame escalation queue output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-escalation-queue-out \"\$founder_fame_escalation_queue_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame escalation queue output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_command_center_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame command center output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-command-center-out \"\$founder_fame_command_center_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame command center output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_spotlight_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame spotlight pack output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-spotlight-out \"\$founder_fame_spotlight_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame spotlight pack output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_breakout_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame breakout plan output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-breakout-out \"\$founder_fame_breakout_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame breakout plan output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_outreach_sprint_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame outreach sprint output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-outreach-sprint-out \"\$founder_fame_outreach_sprint_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame outreach sprint output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_proof_loop_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame proof loop output wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-proof-loop-out \"\$founder_fame_proof_loop_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame proof loop output path into launch runner."
  exit 1
fi

if ! rg -Fq "founder_fame_kpi_snapshot_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame KPI snapshot output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_velocity_scoreboard_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame velocity scoreboard output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional loop output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_live_check_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room live verification output wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_war_room_live_check_path=\$founder_fame_war_room_live_check_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not expose founder fame war-room live verification output path."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_exceptional_loop_path=\$founder_fame_exceptional_loop_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not expose founder fame exceptional loop output path."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_comment_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist comment output wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_exceptional_loop_comment_path=\$founder_fame_exceptional_loop_comment_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not expose founder fame exceptional-loop checklist comment output path."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_live_check_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop live verification output wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_exceptional_loop_live_check_path=\$founder_fame_exceptional_loop_live_check_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not expose founder fame exceptional-loop live verification output path."
  exit 1
fi

if ! rg -Fq "founder_fame_narrative_lab_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame narrative lab output wiring."
  exit 1
fi

if ! rg -Fq "founder_first48h_post_pack_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h post pack output wiring."
  exit 1
fi

if ! rg -Fq "founder_first48h_primary_char_limit:" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h primary char-limit input."
  exit 1
fi

if ! rg -Fq "founder_first48h_backup_char_limit:" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h backup char-limit input."
  exit 1
fi

if ! rg -Fq "founder_first48h_primary_tone:" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h primary tone input."
  exit 1
fi

if ! rg -Fq "founder_first48h_backup_tone:" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h backup tone input."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FIRST48H_PRIMARY_CHAR_LIMIT" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h primary char-limit env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FIRST48H_BACKUP_CHAR_LIMIT" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h backup char-limit env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FIRST48H_PRIMARY_TONE" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h primary tone env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FIRST48H_BACKUP_TONE" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h backup tone env wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-kpi-snapshot-out \"\$founder_fame_kpi_snapshot_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame KPI snapshot output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-velocity-scoreboard-out \"\$founder_fame_velocity_scoreboard_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame velocity scoreboard output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-out \"\$founder_fame_exceptional_loop_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional loop output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-comment-out \"\$founder_fame_exceptional_loop_comment_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional-loop checklist comment output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-live-check-out \"\$founder_fame_war_room_live_check_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame war-room live verification output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-live-check-out \"\$founder_fame_exceptional_loop_live_check_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional-loop live verification output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-narrative-lab-out \"\$founder_fame_narrative_lab_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame narrative lab output path into launch runner."
  exit 1
fi

if ! rg -Fq "Founder fame velocity scoreboard" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame velocity scoreboard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional loop" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop checklist comment" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist comment summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room live verification" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room live verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop live verification" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop live verification summary output."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-post-pack-out \"\$founder_first48h_post_pack_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder first-48h post pack output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-primary-char-limit \"\$INPUT_FOUNDER_FIRST48H_PRIMARY_CHAR_LIMIT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder first-48h primary char-limit into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-backup-char-limit \"\$INPUT_FOUNDER_FIRST48H_BACKUP_CHAR_LIMIT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder first-48h backup char-limit into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-primary-tone \"\$INPUT_FOUNDER_FIRST48H_PRIMARY_TONE\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder first-48h primary tone into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-backup-tone \"\$INPUT_FOUNDER_FIRST48H_BACKUP_TONE\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder first-48h backup tone into launch runner."
  exit 1
fi

if ! rg -Fq "Founder fame momentum brief" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame momentum brief summary output."
  exit 1
fi

if ! rg -Fq "Founder fame opportunity radar" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame opportunity radar summary output."
  exit 1
fi

if ! rg -Fq "Founder fame execution sprint" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame execution sprint summary output."
  exit 1
fi

if ! rg -Fq "Founder fame execution scorecard" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame execution scorecard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame risk response plan" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame risk response plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame escalation queue" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame escalation queue summary output."
  exit 1
fi

if ! rg -Fq "Founder fame command center" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame command center summary output."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame in-app next-move summary guidance."
  exit 1
fi

if ! rg -Fq "artifact link + owner update" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame command-center handoff summary guidance."
  exit 1
fi

if ! rg -Fq "Founder fame spotlight pack" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame spotlight pack summary output."
  exit 1
fi

if ! rg -Fq "Founder fame breakout plan" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame breakout plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame outreach sprint" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame outreach sprint summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame proof loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verification" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame proof loop verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame KPI snapshot" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame KPI snapshot summary output."
  exit 1
fi

if ! rg -Fq "Founder fame narrative lab" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame narrative lab summary output."
  exit 1
fi

if ! rg -Fq "Founder first-48h post pack" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder first-48h post pack summary output."
  exit 1
fi

if ! rg -Fq "Founder fame weight profile" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame weight profile summary output."
  exit 1
fi

if ! rg -Fq "Founder fame uplift tracker" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame uplift tracker summary output."
  exit 1
fi

if ! rg -Fq "outreach_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing creator outreach output wiring."
  exit 1
fi

if ! rg -Fq -- "--outreach-out \"\$outreach_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire creator outreach output path into launch runner."
  exit 1
fi

if ! rg -Fq "target_list_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing creator target list output wiring."
  exit 1
fi

if ! rg -Fq -- "--target-list-out \"\$target_list_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire creator target list output path into launch runner."
  exit 1
fi

if ! rg -Fq "scripts/generate_social_proof_kit.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing social proof kit generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_ops_brief.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame ops brief generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_action_queue.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame action queue generation step."
  exit 1
fi

if ! rg -Fq -- "--daily-mission \"\$founder_fame_daily_mission_path\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame daily mission source into founder action queue generation."
  exit 1
fi

if ! rg -Fq -- "--require-fresh-daily-mission" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing daily mission freshness enforcement for founder action queue generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_interview_prep.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame interview prep generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_transcript_ingestion.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame transcript ingestion generation step."
  exit 1
fi

if ! rg -Fq -- "--transcript \"\$founder_transcript_source_path\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder transcript source path into transcript ingestion generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_repurpose_plan.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame repurpose generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_uplift_tracker.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame uplift tracker generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_weight_profile.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame weight profile generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_momentum_brief.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame momentum brief generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_opportunity_radar.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame opportunity radar generation step."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-opportunity-radar-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame opportunity radar CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-execution-sprint-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame execution sprint CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-execution-scorecard-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame execution scorecard CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-risk-response-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame risk response plan CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-escalation-queue-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame escalation queue CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-command-center-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame command center CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-next-move-handoff-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame next-move handoff CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-next-move-draft-pack-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame next-move draft-pack CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-check-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room verification CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-live-check-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room live verification CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-comment-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room comment CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--post-founder-fame-war-room-comment" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room checklist comment upsert flag wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-comment-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop comment CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-live-check-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop live verification CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--post-founder-fame-exceptional-loop-comment" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop checklist comment upsert flag wiring."
  exit 1
fi

if ! rg -Fq -- "--transcript-ingestion \"\$founder_fame_transcript_ingestion_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire transcript ingestion artifact into repurpose generation."
  exit 1
fi

if ! rg -Fq -- "--weight-profile \"\$founder_fame_weight_profile_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame weight profile into momentum generation."
  exit 1
fi

if ! rg -Fq -- "--uplift-tracker \"\$founder_fame_uplift_tracker_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame uplift tracker into weight profile generation."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief \"\$founder_fame_momentum_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire momentum brief into founder fame opportunity radar generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_sprint.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame execution sprint generation step."
  exit 1
fi

if ! rg -Fq -- "--opportunity-radar \"\$founder_fame_opportunity_radar_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire opportunity radar into founder fame execution sprint generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_scorecard.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame execution scorecard generation step."
  exit 1
fi

if ! rg -Fq -- "--execution-sprint \"\$founder_fame_execution_sprint_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire execution sprint into founder fame execution scorecard generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_risk_response_plan.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame risk response plan generation step."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard \"\$founder_fame_execution_scorecard_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire execution scorecard into founder fame risk response plan generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_escalation_queue.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame escalation queue generation step."
  exit 1
fi

if ! rg -Fq -- "--risk-response-plan \"\$founder_fame_risk_response_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire risk response plan into founder fame escalation queue generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_command_center.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame command center generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_handoff.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame next-move handoff generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_draft_pack.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame next-move draft-pack generation step."
  exit 1
fi

if ! rg -Fq -- "--artifact-link \"\$founder_fame_command_center_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire command center artifact link into founder fame next-move handoff generation."
  exit 1
fi

if ! rg -Fq -- "--next-move-handoff \"\$founder_fame_next_move_handoff_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame next-move handoff into founder next-move draft-pack generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_war_room.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room generation step."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room verification step."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_war_room_comment.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room checklist comment render/upsert step."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_exceptional_loop_comment.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop checklist comment render/upsert step."
  exit 1
fi

if ! rg -Fq -- "--action-queue \"\$founder_fame_action_queue_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame action queue artifact into checklist comment render/upsert scripts."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room_run.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room live verification step."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_exceptional_loop_run.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop live verification step."
  exit 1
fi

if ! rg -Fq "Verify founder fame war-room live state" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room live verification run step."
  exit 1
fi

if ! rg -Fq "Verify founder fame exceptional-loop live state" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop live verification run step."
  exit 1
fi

if ! rg -Fq -- "--comment \"\$founder_fame_war_room_comment_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame war-room checklist comment artifact into war-room live verification."
  exit 1
fi

if ! rg -Fq -- "--comment \"\$founder_fame_exceptional_loop_comment_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame exceptional-loop checklist comment artifact into exceptional-loop live verification."
  exit 1
fi

if ! rg -Fq "war_room_live_verify_args+=(--strict)" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing strict founder fame war-room live verification wiring for checklist upsert mode."
  exit 1
fi

if ! rg -Fq "exceptional_loop_live_verify_args+=(--strict)" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing strict founder fame exceptional-loop live verification wiring for checklist upsert mode."
  exit 1
fi

if ! rg -Fq -- "--next-move-draft-pack \"\$founder_fame_next_move_draft_pack_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame next-move draft-pack into founder war-room generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_spotlight_pack.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame spotlight pack generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_breakout_plan.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame breakout plan generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_outreach_sprint.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame outreach sprint generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_proof_loop.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame proof loop generation step."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_proof_loop.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame proof loop verification step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_kpi_snapshot.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame KPI snapshot generation step."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-kpi-snapshot-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame KPI snapshot CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--proof-loop-check \"\$founder_fame_proof_loop_check_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire proof loop verification output into founder KPI snapshot generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_velocity_scoreboard.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame velocity scoreboard generation step."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-velocity-scoreboard-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame velocity scoreboard CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot \"\$founder_fame_kpi_snapshot_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder KPI snapshot artifact into founder fame velocity scoreboard generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_exceptional_loop.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional loop generation step."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional loop CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--velocity-scoreboard \"\$founder_fame_velocity_scoreboard_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder velocity scoreboard artifact into founder fame exceptional loop generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_narrative_lab.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame narrative lab generation step."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-narrative-lab-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame narrative lab CLI option wiring."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot \"\$founder_fame_kpi_snapshot_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder KPI snapshot artifact into founder narrative lab generation."
  exit 1
fi

if ! rg -Fq "Founder fame velocity scoreboard:" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame velocity scoreboard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional loop:" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop checklist comment:" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop checklist comment summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop live verification:" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop live verification summary output."
  exit 1
fi

if ! rg -Fq -- "--primary-audience-region \"\$primary_audience_region\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire primary audience region into founder narrative lab generation."
  exit 1
fi

if ! rg -Fq -- "--backup-audience-region \"\$backup_audience_region\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire backup audience region into founder narrative lab generation."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief \"\$founder_fame_momentum_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire momentum brief into founder fame command center generation."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard \"\$founder_fame_execution_scorecard_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire execution scorecard into founder fame command center generation."
  exit 1
fi

if ! rg -Fq -- "--escalation-queue \"\$founder_fame_escalation_queue_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire escalation queue into founder fame command center generation."
  exit 1
fi

if ! rg -Fq -- "--command-center \"\$founder_fame_command_center_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame command center into founder spotlight generation."
  exit 1
fi

if ! rg -Fq -- "--spotlight-pack \"\$founder_fame_spotlight_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame spotlight pack into founder breakout plan generation."
  exit 1
fi

if ! rg -Fq -- "--breakout-plan \"\$founder_fame_breakout_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame breakout plan into founder outreach sprint generation."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint \"\$founder_fame_outreach_sprint_out\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder fame outreach sprint into founder proof loop generation."
  exit 1
fi

if ! rg -Fq "Founder fame command center" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame command center summary output."
  exit 1
fi

if ! rg -Fq "Founder fame next-move handoff" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame next-move handoff summary output."
  exit 1
fi

if ! rg -Fq "Founder fame next-move draft pack" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame next-move draft-pack summary output."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame in-app next-move guidance."
  exit 1
fi

if ! rg -Fq "Founder fame war room" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room verification" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room live verification" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room live verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room checklist comment" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room checklist comment summary output."
  exit 1
fi

if ! rg -Fq "artifact link + owner update" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame command-center handoff guidance."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission source" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame daily mission source summary output."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission freshness" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame daily mission freshness summary output."
  exit 1
fi

if ! rg -Fq "Founder fame spotlight pack" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame spotlight pack summary output."
  exit 1
fi

if ! rg -Fq "Founder fame breakout plan" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame breakout plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame outreach sprint" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame outreach sprint summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame proof loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verification" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame proof loop verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame KPI snapshot" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame KPI snapshot summary output."
  exit 1
fi

if ! rg -Fq "Founder fame narrative lab" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame narrative lab summary output."
  exit 1
fi

if ! rg -Fq "scripts/generate_weekly_growth_issue.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing weekly growth issue generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_update_post.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder update generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_pack.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_press_kit.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder press generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_media_blast.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder media generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_first24h_reply_pack.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing first-24-hour reply pack generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_first48h_post_pack.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder first-48h post pack generation step."
  exit 1
fi

if ! rg -Fq -- "--cta \"\$founder_cta_text\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder CTA into founder first-48h post pack generation."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit \"\$founder_first48h_primary_char_limit\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder first-48h primary char-limit into generation."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit \"\$founder_first48h_backup_char_limit\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder first-48h backup char-limit into generation."
  exit 1
fi

if ! rg -Fq -- "--primary-tone \"\$founder_first48h_primary_tone\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder first-48h primary tone into generation."
  exit 1
fi

if ! rg -Fq -- "--backup-tone \"\$founder_first48h_backup_tone\"" "scripts/run_launch_day.sh"; then
  echo "Launch day runner does not wire founder first-48h backup tone into generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_monday_publish_checkpoint.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing Monday publish checkpoint generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_creator_outreach_kit.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing creator outreach kit generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_creator_target_list.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing creator target list generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_social_proof_wall.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing social proof wall generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_winning_hook_library.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing winning hook library generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_credibility_ledger.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing credibility ledger generation step."
  exit 1
fi

if ! rg -Fq "schedule:" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing schedule trigger."
  exit 1
fi

if ! rg -Fq "scripts/generate_weekly_growth_issue.sh" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow does not call issue generator script."
  exit 1
fi

if ! rg -Fq "Extract previous weekly metrics" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing previous-metrics extraction."
  exit 1
fi

if ! rg -Fq "previous_week" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing previous week snapshot wiring."
  exit 1
fi

if ! rg -Fq "previous_baseline_week" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing baseline week wiring."
  exit 1
fi

if ! rg -Fq "previous_win_card_delta" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing weekly delta outputs."
  exit 1
fi

if ! rg -Fq "schedule:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing schedule trigger."
  exit 1
fi

if ! rg -Fq "workflow_dispatch" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing workflow_dispatch trigger."
  exit 1
fi

if ! rg -Fq "primary_audience_region" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing primary audience-region dispatch input."
  exit 1
fi

if ! rg -Fq "backup_audience_region" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing backup audience-region dispatch input."
  exit 1
fi

if ! rg -Fq "distribution_completion_threshold" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution completion threshold input."
  exit 1
fi

if ! rg -Fq "founder_transcript_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder transcript source dispatch input."
  exit 1
fi

if ! rg -Fq "founder_fame_daily_mission_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission source dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_primary_char_limit" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h primary char-limit dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_backup_char_limit" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h backup char-limit dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_primary_tone" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h primary tone dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_backup_tone" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h backup tone dispatch input."
  exit 1
fi

if ! rg -Fq "DISTRIBUTION_COMPLETION_THRESHOLD: \${{ inputs.distribution_completion_threshold }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing threshold wiring into distribution nudge logic."
  exit 1
fi

if ! rg -Fq "scripts/generate_growth_review_comment.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call review generator script."
  exit 1
fi

if ! rg -Fq "Classify sprint health" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing sprint health classification."
  exit 1
fi

if ! rg -Fq "Upsert weekly review comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing review comment upsert step."
  exit 1
fi

if ! rg -Fq "Escalate sprint health" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing sprint escalation step."
  exit 1
fi

if ! rg -Fq "Generate Monday draft from highlight plan" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday draft generation step."
  exit 1
fi

if ! rg -Fq "Extract previous Monday checklist effectiveness" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing previous Monday effectiveness extraction."
  exit 1
fi

if ! rg -Fq "Sync reply pack effectiveness into sprint issue" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing sprint issue reply effectiveness sync."
  exit 1
fi

if ! rg -Fq "Founder guesting signal entries:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal effectiveness fields in sprint sync."
  exit 1
fi

if ! rg -Fq "Founder guesting replied:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting replied field in sprint sync."
  exit 1
fi

if ! rg -Fq "Founder guesting booked:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting booked field in sprint sync."
  exit 1
fi

if ! rg -Fq "Founder guesting published:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting published field in sprint sync."
  exit 1
fi

if ! rg -Fq "Founder guesting recommendation:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting recommendation field in sprint sync."
  exit 1
fi

if ! rg -Fq "GUESTING_SIGNAL_ENTRIES" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal env wiring in sprint sync."
  exit 1
fi

if ! rg -Fq "GUESTING_SIGNAL_REPLIED" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting replied env wiring in sprint sync."
  exit 1
fi

if ! rg -Fq "GUESTING_SIGNAL_BOOKED" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting booked env wiring in sprint sync."
  exit 1
fi

if ! rg -Fq "GUESTING_SIGNAL_PUBLISHED" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting published env wiring in sprint sync."
  exit 1
fi

if ! rg -Fq "GUESTING_SIGNAL_ENRICHMENT_SCORE" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting enrichment env wiring in sprint sync."
  exit 1
fi

if ! rg -Fq "GUESTING_SIGNAL_RECOMMENDATION" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting recommendation env wiring in sprint sync."
  exit 1
fi

if ! rg -Fq "buildVariantRecommendation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing variant recommendation logic."
  exit 1
fi

if ! rg -Fq -- "--primary-channel \"\$PRIMARY_CHANNEL\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel wiring to review generator."
  exit 1
fi

if ! rg -Fq "REVIEW_PATH: \${{ env.review_path }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing review artifact wiring into Monday checklist."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-review -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing review comment marker."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-reply-effectiveness -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing sprint issue reply effectiveness marker."
  exit 1
fi

if ! rg -Fq "growth-watch" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing growth-watch label handling."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-recovery-plan -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing recovery plan marker."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-highlight-plan -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing highlight plan marker."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-monday-draft -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday draft marker."
  exit 1
fi

if ! rg -Fq "monday_draft_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday draft artifact output."
  exit 1
fi

if ! rg -Fq "steps.monday_draft.outputs.monday_draft_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday draft artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Upsert Monday publish checklist issue" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish checklist upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-monday-publish-checklist -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish checklist marker."
  exit 1
fi

if ! rg -Fq "## First 24-Hour Reply Effectiveness" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday reply effectiveness section."
  exit 1
fi

if ! rg -Fq "## Default Publish Drafts (Auto-Promoted)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing auto-promoted default drafts section."
  exit 1
fi

if ! rg -Fq "Source review artifact:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing review artifact traceability in Monday checklist."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-default-drafts-start -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing default-draft insertion start marker."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-default-drafts-end -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing default-draft insertion end marker."
  exit 1
fi

if ! rg -Fq "extractPromotedScriptsFromReview" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing robust review script parser wiring."
  exit 1
fi

if ! rg -Fq "extractPromotedDefaults" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing promoted defaults marker parser."
  exit 1
fi

if ! rg -Fq "Primary channel top variant" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday variant effectiveness fields."
  exit 1
fi

if ! rg -Fq "Creator outreach sent" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach effectiveness fields."
  exit 1
fi

if ! rg -Fq "Creator outreach recommendation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach recommendation field."
  exit 1
fi

if ! rg -Fq "outreach_recommendation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach recommendation wiring."
  exit 1
fi

if ! rg -Fq "outreach_reply_rate" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach rate output wiring."
  exit 1
fi

if ! rg -Fq -- "--outreach-reply-rate \"\$OUTREACH_REPLY_RATE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach reply-rate wiring into review generator."
  exit 1
fi

if ! rg -Fq "primary_channel_roi_score" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel ROI score output wiring."
  exit 1
fi

if ! rg -Fq -- "--primary-channel-roi-score \"\$PRIMARY_CHANNEL_ROI_SCORE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing primary channel ROI wiring into review generator."
  exit 1
fi

if ! rg -Fq "CHANNEL_ROI_PREFERRED_CHANNEL" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel ROI preferred-channel wiring."
  exit 1
fi

if ! rg -Fq "Channel ROI recommendation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel ROI recommendation fields."
  exit 1
fi

if ! rg -Fq "distribution_days_completed" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution completion output wiring."
  exit 1
fi

if ! rg -Fq "distribution_completion_score" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution score output wiring."
  exit 1
fi

if ! rg -Fq "channel_mix_recommendation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel mix recommendation wiring."
  exit 1
fi

if ! rg -Fq "## Distribution Follow-Up Execution" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday distribution execution section."
  exit 1
fi

if ! rg -Fq -- "--distribution-days-completed \"\$DISTRIBUTION_DAYS_COMPLETED\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution-days wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--distribution-completion-score \"\$DISTRIBUTION_COMPLETION_SCORE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution-score wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation \"\$CHANNEL_MIX_RECOMMENDATION\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel mix recommendation wiring into review generator."
  exit 1
fi

if ! rg -Fq "default_primary_variant" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing promoted draft variant outputs."
  exit 1
fi

if ! rg -Fq "monday-publish" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing monday-publish label handling."
  exit 1
fi

if ! rg -Fq "Close Monday publish checklist when not exceptional" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish checklist close-out step."
  exit 1
fi

if ! rg -Fq "Generate Monday publish checkpoint artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_monday_publish_checkpoint.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call Monday checkpoint generator script."
  exit 1
fi

if ! rg -Fq -- "--channel-roi-preferred-channel \"\${CHANNEL_ROI_PREFERRED_CHANNEL:-balanced}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing ROI preferred-channel wiring into Monday checkpoint generator."
  exit 1
fi

if ! rg -Fq -- "--channel-roi-recommendation \"\${CHANNEL_ROI_RECOMMENDATION:-Collect Monday reply + outreach outcomes before locking a single-channel lead.}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing ROI recommendation wiring into Monday checkpoint generator."
  exit 1
fi

if ! rg -Fq -- "--primary-audience-region \"\$primary_audience_region_value\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing primary audience-region wiring into Monday checkpoint generator."
  exit 1
fi

if ! rg -Fq -- "--backup-audience-region \"\$backup_audience_region_value\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing backup audience-region wiring into Monday checkpoint generator."
  exit 1
fi

if ! rg -Fq "Upsert Monday publish checkpoint comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-monday-checkpoint -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint marker wiring."
  exit 1
fi

if ! rg -Fq "env.checkpoint_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Monday checkpoint ROI lead route" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint ROI summary output."
  exit 1
fi

if ! rg -Fq "Monday checkpoint audience regions" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint audience-region summary output."
  exit 1
fi

if ! rg -Fq "Monday checkpoint channel mix recommendation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday checkpoint channel-mix summary output."
  exit 1
fi

if ! rg -Fq "Generate first-24h reply pack artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing first-24h reply pack artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_first24h_reply_pack.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call first-24h reply pack generator script."
  exit 1
fi

if ! rg -Fq "Upsert first-24h reply pack comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing first-24h reply pack comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-reply-pack -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing first-24h reply pack marker wiring."
  exit 1
fi

if ! rg -Fq "env.reply_pack_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing first-24h reply pack artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate founder first-48h post pack" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h post pack artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_first48h_post_pack.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder first-48h post pack generator script."
  exit 1
fi

if ! rg -Fq "Upsert founder first-48h post pack comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h post pack comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-first48h-post-pack -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h post pack marker wiring."
  exit 1
fi

if ! rg -Fq "Sync founder first-48h controls into Monday checklist" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h controls sync step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-first48h-controls-start -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h controls checklist block start marker."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-first48h-controls-end -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h controls checklist block end marker."
  exit 1
fi

if ! rg -Fq "Founder First 48h Route Controls (Auto-Synced)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h route controls checklist sync body."
  exit 1
fi

if ! rg -Fq "Route Control Handshake (First 48h)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h route control handshake extraction."
  exit 1
fi

if ! rg -Fq "Escalation & Adaptation Triggers" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h escalation trigger extraction."
  exit 1
fi

if ! rg -Fq "Add founder first-48h controls sync summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h controls sync summary step."
  exit 1
fi

if ! rg -Fq "steps.founder_first48h_controls_sync.outputs.first48h_execution_plan" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h execution-plan sync output wiring."
  exit 1
fi

if ! rg -Fq "founder_first48h_post_pack_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h post pack artifact wiring."
  exit 1
fi

if ! rg -Fq "founder_cta_text=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder CTA export for founder first-48h post pack generation."
  exit 1
fi

if ! rg -Fq "FOUNDER_CTA_TEXT" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h CTA env wiring."
  exit 1
fi

if ! rg -Fq -- "--cta \"\${FOUNDER_CTA_TEXT" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder CTA into founder first-48h post pack generator."
  exit 1
fi

if ! rg -Fq -- "echo \"founder_first48h_primary_char_limit=\${{ inputs.first48h_primary_char_limit || '280' }}\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h primary char-limit env export."
  exit 1
fi

if ! rg -Fq -- "echo \"founder_first48h_backup_char_limit=\${{ inputs.first48h_backup_char_limit || '500' }}\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h backup char-limit env export."
  exit 1
fi

if ! rg -Fq -- "echo \"founder_first48h_primary_tone=\${{ inputs.first48h_primary_tone || 'x-punchy' }}\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h primary tone env export."
  exit 1
fi

if ! rg -Fq -- "echo \"founder_first48h_backup_tone=\${{ inputs.first48h_backup_tone || 'linkedin-context' }}\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h backup tone env export."
  exit 1
fi

if ! rg -Fq -- "FOUNDER_FIRST48H_PRIMARY_CHAR_LIMIT: \${{ env.founder_first48h_primary_char_limit }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h primary char-limit step env wiring."
  exit 1
fi

if ! rg -Fq -- "FOUNDER_FIRST48H_BACKUP_CHAR_LIMIT: \${{ env.founder_first48h_backup_char_limit }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h backup char-limit step env wiring."
  exit 1
fi

if ! rg -Fq -- "FOUNDER_FIRST48H_PRIMARY_TONE: \${{ env.founder_first48h_primary_tone }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h primary tone step env wiring."
  exit 1
fi

if ! rg -Fq -- "FOUNDER_FIRST48H_BACKUP_TONE: \${{ env.founder_first48h_backup_tone }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h backup tone step env wiring."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit \"\${FOUNDER_FIRST48H_PRIMARY_CHAR_LIMIT:-280}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder first-48h primary char limit into post-pack generator."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit \"\${FOUNDER_FIRST48H_BACKUP_CHAR_LIMIT:-500}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder first-48h backup char limit into post-pack generator."
  exit 1
fi

if ! rg -Fq -- "--primary-tone \"\${FOUNDER_FIRST48H_PRIMARY_TONE:-x-punchy}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder first-48h primary tone into post-pack generator."
  exit 1
fi

if ! rg -Fq -- "--backup-tone \"\${FOUNDER_FIRST48H_BACKUP_TONE:-linkedin-context}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder first-48h backup tone into post-pack generator."
  exit 1
fi

if ! rg -Fq "Generate social proof kit artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof kit artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_social_proof_kit.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call social proof kit generator script."
  exit 1
fi

if ! rg -Fq "Upsert social proof kit comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof kit comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-social-proof-kit -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof kit marker wiring."
  exit 1
fi

if ! rg -Fq "env.social_proof_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate creator outreach kit artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach kit artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_creator_outreach_kit.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call creator outreach kit generator script."
  exit 1
fi

if ! rg -Fq "Upsert creator outreach kit comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach kit comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-creator-outreach-kit -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach kit marker wiring."
  exit 1
fi

if ! rg -Fq "env.creator_outreach_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator outreach artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate creator target list artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator target list artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_creator_target_list.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call creator target list generator script."
  exit 1
fi

if ! rg -Fq "Upsert creator target list comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator target list comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-creator-target-list -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator target list marker wiring."
  exit 1
fi

if ! rg -Fq "weekly-growth-creator-signal" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator signal marker guidance."
  exit 1
fi

if ! rg -Fq "creator_signal_entries" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator signal output wiring."
  exit 1
fi

if ! rg -Fq "guesting_signal_entries" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal output wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_winner" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route output wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_mode" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route mode output wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_preferred_variant" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative preferred-variant routing output."
  exit 1
fi

if ! rg -Fq "Founder narrative routing action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative routing action logging."
  exit 1
fi

if ! rg -Fq "Lead with Variant" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative-driven variant promotion guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-guesting-signal" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal marker guidance."
  exit 1
fi

if ! rg -Fq "Extract founder outreach sprint outcomes" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder outreach sprint outcome extraction step."
  exit 1
fi

if ! rg -Fq "outreach_sprint_outcomes.outputs.outreach_sprint_completion_rate" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder outreach sprint completion-rate output wiring."
  exit 1
fi

if ! rg -Fq "Founder Outreach Sprint Outcome Intake" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder outreach sprint outcome intake guidance in Monday checklist."
  exit 1
fi

if ! rg -Fq "Founder outreach sprint outcomes:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder outreach sprint outcome summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative route:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative controls:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative controls summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative distribution calendar:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution-calendar summary output."
  exit 1
fi

if ! rg -Fq "first 48h plan" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative first-48h plan summary output."
  exit 1
fi

if ! rg -Fq "first48hExecutionPlanMatch" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative first-48h execution-plan parser match."
  exit 1
fi

if ! rg -Fq "routeLaneTriggerMatch" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route lane-trigger parser match."
  exit 1
fi

if ! rg -Fq "parseFounderNarrativeControlsFromChecklistBody" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder first-48h controls fallback parser."
  exit 1
fi

if ! rg -Fq "mergeFounderNarrativeSummary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative + first-48h controls merge wiring."
  exit 1
fi

if ! rg -Fq "previousFounderNarrativeSummary.first48hExecutionPlan" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative first-48h execution-plan source preference wiring."
  exit 1
fi

if ! rg -Fq "extractFounderNarrativeSummary(previousChecklist.issueNumber, previousChecklist.issueBody)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing previous-checklist issue-body wiring for founder narrative fallback extraction."
  exit 1
fi

if ! rg -Fq "extractFounderNarrativeSummary(baselineChecklist.issueNumber, baselineChecklist.issueBody)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing baseline-checklist issue-body wiring for founder narrative fallback extraction."
  exit 1
fi

if ! rg -Fq "Founder narrative route control recommendation:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route control recommendation sync output."
  exit 1
fi

if ! rg -Fq "Founder outreach sprint owner defaults:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder outreach sprint owner-default summary output."
  exit 1
fi

if ! rg -Fq -- "OUTREACH_SPRINT_RECOMMENDATION: \${{ steps.outreach_sprint_outcomes.outputs.outreach_sprint_recommendation }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint recommendation env wiring."
  exit 1
fi

if ! rg -Fq "outreach_sprint_owner_defaults_completion_rate" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint owner-default completion-rate output wiring."
  exit 1
fi

if ! rg -Fq -- "OUTREACH_SPRINT_OWNER_DEFAULT_DISTRIBUTION_COMPLETED: \${{ steps.outreach_sprint_outcomes.outputs.outreach_sprint_owner_default_distribution_completed }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint distribution-owner completion env wiring."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-owner-defaults-completion-rate \"\$OUTREACH_SPRINT_OWNER_DEFAULTS_COMPLETION_RATE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing owner-default completion-rate wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-owner-default-distribution-completed \"\$OUTREACH_SPRINT_OWNER_DEFAULT_DISTRIBUTION_COMPLETED\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing owner-default distribution completion wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-entries \"\$CREATOR_SIGNAL_ENTRIES\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator signal entries wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-enrichment-score \"\$CREATOR_SIGNAL_ENRICHMENT_SCORE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator enrichment score wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "GUESTING_SIGNAL_ENTRIES: \${{ steps.monday_effectiveness.outputs.guesting_signal_entries }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal entries env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_ROUTE_WINNER: \${{ steps.monday_effectiveness.outputs.narrative_route_winner }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route winner env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_ROUTE_MODE: \${{ steps.monday_effectiveness.outputs.narrative_route_mode }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route mode env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_ROUTE_ALIGNMENT_TARGET: \${{ steps.monday_effectiveness.outputs.narrative_route_alignment_target }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route alignment-target env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_ROUTE_CONTROL_RECOMMENDATION: \${{ steps.monday_effectiveness.outputs.narrative_route_control_recommendation }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route control recommendation env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_DISTRIBUTION_STRATEGY: \${{ steps.monday_effectiveness.outputs.narrative_distribution_strategy }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution strategy env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_DISTRIBUTION_DAY0_LEAD: \${{ steps.monday_effectiveness.outputs.narrative_distribution_day0_lead }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution Day 0 lead env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_DISTRIBUTION_DAY0_SUPPORT: \${{ steps.monday_effectiveness.outputs.narrative_distribution_day0_support }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution Day 0 support env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_DISTRIBUTION_RECOMMENDATION: \${{ steps.monday_effectiveness.outputs.narrative_distribution_recommendation }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution recommendation env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "NARRATIVE_DISTRIBUTION_FIRST_48H_PLAN: \${{ steps.monday_effectiveness.outputs.narrative_distribution_first_48h_plan }}" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative first-48h execution-plan env wiring into review generator step."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-entries \"\$GUESTING_SIGNAL_ENTRIES\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal entries wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-winner \"\$NARRATIVE_ROUTE_WINNER\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route winner wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-mode \"\$NARRATIVE_ROUTE_MODE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route mode wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-alignment-target \"\$NARRATIVE_ROUTE_ALIGNMENT_TARGET\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route alignment-target wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-lane-status \"\$NARRATIVE_ROUTE_LANE_STATUS\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route lane-status wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-guardrail \"\$NARRATIVE_ROUTE_GUARDRAIL\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route guardrail wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-control-recommendation \"\$NARRATIVE_ROUTE_CONTROL_RECOMMENDATION\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route control recommendation wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-recommendation \"\$NARRATIVE_ROUTE_RECOMMENDATION\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route recommendation wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-strategy \"\$NARRATIVE_DISTRIBUTION_STRATEGY\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution strategy wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-day0-lead \"\$NARRATIVE_DISTRIBUTION_DAY0_LEAD\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution Day 0 lead wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-day0-support \"\$NARRATIVE_DISTRIBUTION_DAY0_SUPPORT\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution Day 0 support wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-recommendation \"\$NARRATIVE_DISTRIBUTION_RECOMMENDATION\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative distribution recommendation wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-distribution-first-48h-plan \"\$NARRATIVE_DISTRIBUTION_FIRST_48H_PLAN\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative first-48h execution-plan wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-booked \"\$GUESTING_SIGNAL_BOOKED\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting booked wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-enrichment-score \"\$GUESTING_SIGNAL_ENRICHMENT_SCORE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting enrichment score wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-recommendation \"\$GUESTING_SIGNAL_RECOMMENDATION\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting recommendation wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-comment-entries \"\$OUTREACH_SPRINT_COMMENT_ENTRIES\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint comment entries wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-completion-rate \"\$OUTREACH_SPRINT_COMPLETION_RATE\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint completion-rate wiring into review generator."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-entries \"\${CREATOR_SIGNAL_ENTRIES:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator signal entries wiring into creator target list generator."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-enrichment-score \"\${CREATOR_SIGNAL_ENRICHMENT_SCORE:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator enrichment score wiring into creator target list generator."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-completion-rate \"\${OUTREACH_SPRINT_COMPLETION_RATE:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint completion-rate wiring into creator target list generator."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-entries \"\${GUESTING_SIGNAL_ENTRIES:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting signal entries wiring into guesting queue generator."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-enrichment-score \"\${GUESTING_SIGNAL_ENRICHMENT_SCORE:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting enrichment score wiring into guesting queue generator."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-completion-rate \"\${OUTREACH_SPRINT_COMPLETION_RATE:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing outreach sprint completion-rate wiring into guesting queue generator."
  exit 1
fi

if ! rg -Fq "env.creator_target_list_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator target list artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate founder fame pack artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame artifact step."
  exit 1
fi

if ! rg -Fq "source scripts/fixtures/founder/sample_inputs.env" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fixture defaults sourcing."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_weekly_pack.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder weekly pack generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_press_kit.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder press kit generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_media_blast.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder media blast generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_guesting_queue.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder guesting queue generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_guesting_brief.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder guesting sprint brief generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_ops_brief.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame ops brief generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_action_queue.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame action queue generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_interview_prep.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame interview prep generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_transcript_ingestion.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame transcript ingestion generator script."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_TRANSCRIPT_PATH" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder transcript source env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_DAILY_MISSION_PATH" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission source env wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_daily_mission_freshness=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission freshness env wiring."
  exit 1
fi

if ! rg -Fq -- "--transcript \"\$founder_transcript_source_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder transcript source path into transcript ingestion generation."
  exit 1
fi

if ! rg -Fq -- "--daily-mission \"\$founder_fame_daily_mission_source_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder daily mission source path into founder action queue generation."
  exit 1
fi

if ! rg -Fq -- "--require-fresh-daily-mission" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission freshness enforcement."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission freshness:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission freshness summary output."
  exit 1
fi

if ! rg -Fq "founder_fame_transcript_ingestion_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame transcript ingestion path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_repurpose_plan.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame repurpose generator script."
  exit 1
fi

if ! rg -Fq -- "--transcript-ingestion \"\$founder_fame_transcript_ingestion_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire transcript ingestion artifact into founder repurpose generator."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_uplift_tracker.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame uplift tracker generator script."
  exit 1
fi

if ! rg -Fq "founder_fame_uplift_tracker_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame uplift tracker path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_weight_profile.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame weight profile generator script."
  exit 1
fi

if ! rg -Fq "founder_fame_weight_profile_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame weight profile path wiring."
  exit 1
fi

if ! rg -Fq -- "--uplift-tracker \"\$founder_fame_uplift_tracker_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire uplift tracker into founder weight profile generator."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_momentum_brief.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame momentum brief generator script."
  exit 1
fi

if ! rg -Fq -- "--weight-profile \"\$founder_fame_weight_profile_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire weight profile into founder momentum generator."
  exit 1
fi

if ! rg -Fq "founder_fame_momentum_brief_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame momentum brief path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_opportunity_radar.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame opportunity radar generator script."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief \"\$founder_fame_momentum_brief_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire momentum brief into founder fame opportunity radar generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-route-winner \"\${NARRATIVE_ROUTE_WINNER:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire narrative route winner into founder fame opportunity radar generator."
  exit 1
fi

if ! rg -Fq -- "--narrative-fame-velocity-score \"\${NARRATIVE_FAME_VELOCITY_SCORE:-n/a}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire narrative fame velocity into founder fame opportunity radar generator."
  exit 1
fi

if ! rg -Fq "founder_fame_opportunity_radar_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame opportunity radar path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_sprint.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame execution sprint generator script."
  exit 1
fi

if ! rg -Fq -- "--opportunity-radar \"\$founder_fame_opportunity_radar_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire opportunity radar into founder fame execution sprint generator."
  exit 1
fi

if ! rg -Fq "founder_fame_execution_sprint_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution sprint path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_scorecard.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame execution scorecard generator script."
  exit 1
fi

if ! rg -Fq -- "--execution-sprint \"\$founder_fame_execution_sprint_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire execution sprint into founder fame execution scorecard generator."
  exit 1
fi

if ! rg -Fq "founder_fame_execution_scorecard_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution scorecard path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_risk_response_plan.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame risk response plan generator script."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard \"\$founder_fame_execution_scorecard_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire execution scorecard into founder fame risk response plan generator."
  exit 1
fi

if ! rg -Fq "founder_fame_risk_response_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame risk response plan path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_escalation_queue.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame escalation queue generator script."
  exit 1
fi

if ! rg -Fq -- "--risk-response-plan \"\$founder_fame_risk_response_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire risk response plan into founder fame escalation queue generator."
  exit 1
fi

if ! rg -Fq "founder_fame_escalation_queue_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame escalation queue path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_command_center.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame command center generator script."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief \"\$founder_fame_momentum_brief_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire momentum brief into founder fame command center generator."
  exit 1
fi

if ! rg -Fq -- "--escalation-queue \"\$founder_fame_escalation_queue_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire escalation queue into founder fame command center generator."
  exit 1
fi

if ! rg -Fq "founder_fame_command_center_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame command center path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_handoff.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame next-move handoff generator script."
  exit 1
fi

if ! rg -Fq -- "--command-center \"\$founder_fame_command_center_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame command center into founder next-move handoff generator."
  exit 1
fi

if ! rg -Fq "founder_fame_next_move_handoff_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move handoff path wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_next_move_handoff_path=\$founder_fame_next_move_handoff_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move handoff environment export wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_draft_pack.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame next-move draft-pack generator script."
  exit 1
fi

if ! rg -Fq -- "--next-move-handoff \"\$founder_fame_next_move_handoff_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame next-move handoff artifact into founder next-move draft-pack generator."
  exit 1
fi

if ! rg -Fq "founder_fame_next_move_draft_pack_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move draft-pack path wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_next_move_draft_pack_path=\$founder_fame_next_move_draft_pack_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move draft-pack environment export wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_spotlight_pack.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame spotlight pack generator script."
  exit 1
fi

if ! rg -Fq -- "--command-center \"\$founder_fame_command_center_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame command center into founder spotlight generator."
  exit 1
fi

if ! rg -Fq "founder_fame_spotlight_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame spotlight pack path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_breakout_plan.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame breakout plan generator script."
  exit 1
fi

if ! rg -Fq -- "--spotlight-pack \"\$founder_fame_spotlight_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame spotlight artifact into founder breakout generator."
  exit 1
fi

if ! rg -Fq "founder_fame_breakout_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame breakout plan path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_outreach_sprint.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame outreach sprint generator script."
  exit 1
fi

if ! rg -Fq -- "--breakout-plan \"\$founder_fame_breakout_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame breakout artifact into founder outreach sprint generator."
  exit 1
fi

if ! rg -Fq "founder_fame_outreach_sprint_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame outreach sprint path wiring."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_proof_loop.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame proof loop generator script."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint \"\$founder_fame_outreach_sprint_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame outreach sprint artifact into founder proof loop generator."
  exit 1
fi

if ! rg -Fq "founder_fame_proof_loop_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop path wiring."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_proof_loop.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame proof loop verifier script."
  exit 1
fi

if ! rg -Fq -- "--proof-loop \"\$founder_fame_proof_loop_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame proof loop artifact into founder proof loop verifier."
  exit 1
fi

if ! rg -Fq "founder_fame_proof_loop_check_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verification path wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_kpi_snapshot_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame KPI snapshot path wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_velocity_scoreboard_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard path wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_narrative_lab_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab path wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame proof loop verification summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verification summary step."
  exit 1
fi

if ! rg -Fq "Generate founder fame KPI snapshot" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame KPI snapshot generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_kpi_snapshot.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame KPI snapshot generator script."
  exit 1
fi

if ! rg -Fq "Upsert founder fame KPI snapshot comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame KPI snapshot comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-kpi-snapshot -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame KPI snapshot marker wiring."
  exit 1
fi

if ! rg -Fq "Generate founder fame velocity scoreboard" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_velocity_scoreboard.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame velocity scoreboard generator script."
  exit 1
fi

if ! rg -Fq "Upsert founder fame velocity scoreboard comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-velocity-scoreboard -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard marker wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional loop path wiring."
  exit 1
fi

if ! rg -Fq "Generate founder fame exceptional loop" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional loop generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_exceptional_loop.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame exceptional loop generator script."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot \"\$founder_fame_kpi_snapshot_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame KPI snapshot artifact into founder exceptional loop generator."
  exit 1
fi

if ! rg -Fq -- "--velocity-scoreboard \"\$founder_fame_velocity_scoreboard_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame velocity scoreboard artifact into founder exceptional loop generator."
  exit 1
fi

if ! rg -Fq "Upsert founder fame exceptional-loop checklist comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment upsert step."
  exit 1
fi

if ! rg -Fq "id: founder_fame_exceptional_loop_comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment step id wiring."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_exceptional_loop_comment.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame exceptional-loop checklist comment upsert script."
  exit 1
fi

if ! rg -Fq -- "--action-queue \"\$founder_fame_action_queue_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame action queue artifact into checklist comment upsert scripts."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_comment_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment artifact wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame exceptional-loop checklist comment summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment summary step."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop checklist comment upsert outcome" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment upsert summary output."
  exit 1
fi

if ! rg -Fq "Generate founder fame narrative lab" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_narrative_lab.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame narrative lab generator script."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot \"\$founder_fame_kpi_snapshot_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame KPI snapshot artifact into founder narrative lab generator."
  exit 1
fi

if ! rg -Fq -- "--proof-loop \"\${founder_fame_proof_loop_path:-}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame proof loop artifact into founder narrative lab generator."
  exit 1
fi

if ! rg -Fq -- "--winning-hook-library \"\${winning_hook_library_path:-}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire winning hook library artifact into founder narrative lab generator."
  exit 1
fi

if ! rg -Fq -- "--credibility-ledger \"\${credibility_ledger_path:-}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire credibility ledger artifact into founder narrative lab generator."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_velocity_scoreboard_path=\$output_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not export founder fame velocity scoreboard path from generation step."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_exceptional_loop_path=\$output_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not export founder fame exceptional loop path from generation step."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_exceptional_loop_live_check_path=\$report_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not export founder fame exceptional-loop live verification artifact path."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_narrative_lab_path=\$output_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not export founder fame narrative lab path from generation step."
  exit 1
fi

if ! rg -Fq "Add founder fame velocity scoreboard summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard summary step."
  exit 1
fi

if ! rg -Fq "Add founder fame exceptional loop summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional loop summary step."
  exit 1
fi

if ! rg -Fq "Add founder fame narrative lab summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab summary step."
  exit 1
fi

if ! rg -Fq "Upsert founder fame narrative lab comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-narrative-lab -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab marker wiring."
  exit 1
fi

if ! rg -Fq "Generate founder fame war room" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_war_room.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame war-room generator script."
  exit 1
fi

if ! rg -Fq -- "--next-move-handoff \"\$founder_fame_next_move_handoff_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame next-move handoff artifact into founder war-room generator."
  exit 1
fi

if ! rg -Fq -- "--next-move-draft-pack \"\$founder_fame_next_move_draft_pack_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder fame next-move draft-pack artifact into founder war-room generator."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room path wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_war_room_path=\$output_path\" >> \"\$GITHUB_ENV\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not export founder fame war-room path from generation step."
  exit 1
fi

if ! rg -Fq "Add founder fame war room summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room summary step."
  exit 1
fi

if ! rg -Fq "Verify founder fame war room state" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room verification step."
  exit 1
fi

if ! rg -Fq "id: founder_fame_war_room_verify" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room verification step id wiring."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame war-room verifier script."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room verification artifact wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame war-room verification summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room verification summary step."
  exit 1
fi

if ! rg -Fq "Upsert founder fame war-room checklist comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment upsert step."
  exit 1
fi

if ! rg -Fq "id: founder_fame_war_room_comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment step id wiring."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_war_room_comment.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call founder fame war-room checklist comment upsert script."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_comment_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment artifact wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame war-room checklist comment summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment summary step."
  exit 1
fi

if ! rg -Fq "Founder fame war-room checklist comment upsert outcome" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment upsert summary output."
  exit 1
fi

if ! rg -Fq "Reconcile founder narrative route incident issue" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident issue reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-incident -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident marker wiring."
  exit 1
fi

if ! rg -Fq "Add founder narrative route incident summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident summary step."
  exit 1
fi

if ! rg -Fq "Founder narrative route incident critical trigger" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident critical-trigger summary output."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_threshold" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-threshold input wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_assignee" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-assignee input wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_assignees" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-assignees fallback input wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_comment_cooldown_hours" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-comment cooldown input wiring."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_comment_min_occurrence_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-comment min-occurrence-delta input wiring."
  exit 1
fi

if ! rg -Fq "Reconcile founder narrative route critical escalation comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route critical-comment reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-critical -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route critical-comment marker wiring."
  exit 1
fi

if ! rg -Fq "Add founder narrative route critical comment summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route critical-comment summary step."
  exit 1
fi

if ! rg -Fq "Founder narrative route critical comment policy reason" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route critical-comment policy summary output."
  exit 1
fi

if ! rg -Fq "Reconcile founder narrative route owner queue comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route owner-queue reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-owner-queue -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route owner-queue marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-owner-queue-start -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route owner-queue checklist block start marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-owner-queue-end -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route owner-queue checklist block end marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-owner-sync-start -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident owner-sync start marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-narrative-route-owner-sync-end -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident owner-sync end marker wiring."
  exit 1
fi

if ! rg -Fq "Add founder narrative route owner queue summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route owner-queue summary step."
  exit 1
fi

if ! rg -Fq "Founder narrative route incident critical assignee action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route incident critical assignee summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative route critical comment occurrence delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-comment occurrence-delta summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative route owner queue comment action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue comment summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative route owner queue checklist block action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue checklist-block summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative route incident owner sync action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route incident owner-sync summary output."
  exit 1
fi

if ! rg -Fq "Reconcile founder fame proof loop verification alert comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verifier alert reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-proof-loop-verifier-failure -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verifier failure marker wiring."
  exit 1
fi

if ! rg -Fq "Enforce founder fame proof loop verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verification enforcement step."
  exit 1
fi

if ! rg -Fq "Reconcile founder fame proof loop verifier incident issue" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verifier incident issue reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-proof-loop-verifier-incident -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verifier incident marker wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame proof loop verifier incident summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verifier incident summary step."
  exit 1
fi

if ! rg -Fq "founder_verifier_critical_threshold" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier critical-threshold input wiring."
  exit 1
fi

if ! rg -Fq "founder_verifier_critical_assignee" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier critical-assignee input wiring."
  exit 1
fi

if ! rg -Fq "founder_verifier_critical_assignees" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier critical-assignees fallback input wiring."
  exit 1
fi

if ! rg -Fq "founder_verifier_comment_cooldown_hours" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier comment cooldown input wiring."
  exit 1
fi

if ! rg -Fq "founder_verifier_comment_min_failure_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier comment min-failure-delta input wiring."
  exit 1
fi

if ! rg -Fq "id: founder_fame_proof_loop_verifier_alert_comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop verifier alert step id wiring."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verifier alert comment action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier alert summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verifier alert comment policy reason" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier alert policy-reason summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verifier incident critical escalation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier incident critical summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verifier incident critical assignee action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder verifier incident critical assignee summary output."
  exit 1
fi

if ! rg -Fq "Reconcile founder fame proof loop critical escalation comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop critical-comment reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-proof-loop-verifier-critical -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop critical-comment marker wiring."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop critical comment action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop critical comment summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop critical comment policy reason" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop critical comment policy summary output."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_proof_loop_run.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop live verifier script call."
  exit 1
fi

if ! rg -Fq "Verify founder fame proof loop live state" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop live verification step."
  exit 1
fi

if ! rg -Fq "id: founder_fame_proof_loop_live_verify" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop live verification step id wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_proof_loop_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop live verification artifact wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame proof loop live verification summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop live verification summary step."
  exit 1
fi

if ! rg -Fq "Enforce founder fame proof loop live verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder proof loop live verification enforcement step."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_exceptional_loop_run.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop live verifier script call."
  exit 1
fi

if ! rg -Fq "Verify founder fame exceptional-loop live state" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop live verification step."
  exit 1
fi

if ! rg -Fq "id: founder_fame_exceptional_loop_live_verify" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop live verification step id wiring."
  exit 1
fi

if ! rg -Fq "verify_args+=(--comment \"\$founder_fame_exceptional_loop_comment_path\")" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder exceptional-loop checklist comment artifact into founder exceptional-loop live verifier."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop live verification artifact wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame exceptional-loop live verification summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop live verification summary step."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room_run.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room live verifier script call."
  exit 1
fi

if ! rg -Fq "Verify founder fame war-room live state" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room live verification step."
  exit 1
fi

if ! rg -Fq "id: founder_fame_war_room_live_verify" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room live verification step id wiring."
  exit 1
fi

if ! rg -Fq -- "--repo \"\$REPO_SLUG\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing repo wiring into founder war-room live verifier."
  exit 1
fi

if ! rg -Fq -- "--issue \"\$CHECKLIST_ISSUE_NUMBER\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing checklist issue wiring into founder war-room live verifier."
  exit 1
fi

if ! rg -Fq "verify_args+=(--comment \"\$founder_fame_war_room_comment_path\")" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not wire founder war-room checklist comment artifact into founder war-room live verifier."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room live verification artifact wiring."
  exit 1
fi

if ! rg -Fq "Add founder fame war-room live verification summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room live verification summary step."
  exit 1
fi

if ! rg -Fq "Enforce founder fame war-room verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room verification enforcement step."
  exit 1
fi

if ! rg -Fq "Enforce founder fame war-room checklist comment upsert" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room checklist comment enforcement step."
  exit 1
fi

if ! rg -Fq "Enforce founder fame exceptional-loop checklist comment upsert" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop checklist comment enforcement step."
  exit 1
fi

if ! rg -Fq "Enforce founder fame exceptional-loop live verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder exceptional-loop live verification enforcement step."
  exit 1
fi

if ! rg -Fq "Enforce founder fame war-room live verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder war-room live verification enforcement step."
  exit 1
fi

if ! rg -Fq "Upsert founder fame pack comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame pack comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-pack -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame pack marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder press kit comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder press kit comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-press-kit -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder press kit marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder media blast comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder media blast comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-media-blast -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder media blast marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder guesting queue comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting queue comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-guesting-queue -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting queue marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder guesting sprint brief comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting sprint brief comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-guesting-brief -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting sprint brief marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame ops brief comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame ops brief comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-ops-brief -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame ops brief marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame action queue comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame action queue comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-action-queue -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame action queue marker wiring."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_DAILY_MISSION_SOURCE" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission source context wiring in action queue comment upsert."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_DAILY_MISSION_FRESHNESS" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder daily mission freshness context wiring in action queue comment upsert."
  exit 1
fi

if ! rg -Fq "## Mission Bridge Status" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder action queue mission-bridge status block in checklist comments."
  exit 1
fi

if ! rg -Fq "Upsert founder fame interview prep comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame interview prep comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-interview-prep -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame interview prep marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame transcript ingestion comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame transcript ingestion comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-transcript-ingestion -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame transcript ingestion marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame repurpose plan comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame repurpose comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-repurpose-plan -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame repurpose marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame momentum brief comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame momentum brief comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-momentum-brief -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame momentum brief marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame opportunity radar comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame opportunity radar comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-opportunity-radar -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame opportunity radar marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame execution sprint comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution sprint comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-execution-sprint -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution sprint marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame execution scorecard comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution scorecard comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-execution-scorecard -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution scorecard marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame risk response plan comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame risk response plan comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-risk-response-plan -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame risk response plan marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame escalation queue comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame escalation queue comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-escalation-queue -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame escalation queue marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame command center comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame command center comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-command-center -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame command center marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame spotlight pack comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame spotlight pack comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-spotlight-pack -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame spotlight pack marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame breakout plan comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame breakout plan comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-breakout-plan -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame breakout plan marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame outreach sprint comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame outreach sprint comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-outreach-sprint -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame outreach sprint marker wiring."
  exit 1
fi

if ! rg -Fq "Upsert founder fame proof loop comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-proof-loop -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop marker wiring."
  exit 1
fi

if ! rg -Fq "Lane Owner Defaults (Auto-Prefilled)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing lane owner defaults autofill block for founder outreach sprint comments."
  exit 1
fi

if ! rg -Fq "extractSection(sprintMarkdown, 'Lane Allocation Scorecard')" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing lane allocation scorecard extraction for founder outreach sprint comments."
  exit 1
fi

if ! rg -Fq "Creator owner default: assign owner + ship creator touch target and collab-ready target." ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing creator owner default task prefill for founder outreach sprint comments."
  exit 1
fi

if ! rg -Fq "Founder fame pack artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame pack summary output."
  exit 1
fi

if ! rg -Fq "Founder press kit artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder press kit summary output."
  exit 1
fi

if ! rg -Fq "Founder media blast artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder media blast summary output."
  exit 1
fi

if ! rg -Fq "Founder guesting queue artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting queue summary output."
  exit 1
fi

if ! rg -Fq "Founder guesting sprint brief artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting sprint brief summary output."
  exit 1
fi

if ! rg -Fq "Founder fame ops brief artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame ops brief summary output."
  exit 1
fi

if ! rg -Fq "Founder fame action queue artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame action queue summary output."
  exit 1
fi

if ! rg -Fq "Founder fame interview prep artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame interview prep summary output."
  exit 1
fi

if ! rg -Fq "Founder fame uplift tracker artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame uplift tracker summary output."
  exit 1
fi

if ! rg -Fq "Founder fame weight profile artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame weight profile summary output."
  exit 1
fi

if ! rg -Fq "Founder fame transcript ingestion artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame transcript ingestion summary output."
  exit 1
fi

if ! rg -Fq "Founder fame repurpose plan artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame repurpose summary output."
  exit 1
fi

if ! rg -Fq "Founder fame momentum brief artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame momentum brief summary output."
  exit 1
fi

if ! rg -Fq "Founder fame opportunity radar artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame opportunity radar summary output."
  exit 1
fi

if ! rg -Fq "Founder fame execution sprint artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution sprint summary output."
  exit 1
fi

if ! rg -Fq "Founder fame execution scorecard artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution scorecard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame risk response plan artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame risk response plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame escalation queue artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame escalation queue summary output."
  exit 1
fi

if ! rg -Fq "Founder fame command center artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame command center summary output."
  exit 1
fi

if ! rg -Fq "Founder fame next-move handoff artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move handoff summary output."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame in-app next-move summary guidance."
  exit 1
fi

if ! rg -Fq "artifact link + owner update" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame command-center handoff summary guidance."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-founder-fame-next-move-handoff -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move handoff checklist comment marker."
  exit 1
fi

if ! rg -Fq "Founder fame next-move draft pack artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move draft-pack summary output."
  exit 1
fi

if ! rg -Fq "Founder fame spotlight pack artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame spotlight pack summary output."
  exit 1
fi

if ! rg -Fq "Founder fame breakout plan artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame breakout plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame outreach sprint artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame outreach sprint summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verification artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame KPI snapshot artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame KPI snapshot summary output."
  exit 1
fi

if ! rg -Fq "Founder fame velocity scoreboard artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop checklist comment artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop live verification artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop live verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame narrative lab artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war room artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room verification artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room checklist comment artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room live verification artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room live verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verifier incident action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verifier incident summary output."
  exit 1
fi

if ! rg -Fq "Founder narrative route incident action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route incident summary output."
  exit 1
fi

if ! rg -Fq "critical_occurrences" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route incident critical-occurrences output wiring."
  exit 1
fi

if ! rg -Fq "critical_assignee_attempts" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route incident critical-assignee attempts output wiring."
  exit 1
fi

if ! rg -Fq "Founder narrative route critical comment action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route critical-comment summary output."
  exit 1
fi

if ! rg -Fq "critical_comment_min_occurrence_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-comment min-occurrence-delta output wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_occurrence_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route critical-comment occurrence-delta output wiring."
  exit 1
fi

if ! rg -Fq "owner_queue_comment_action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue comment-action output wiring."
  exit 1
fi

if ! rg -Fq "owner_queue_checklist_block_action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue checklist-block action output wiring."
  exit 1
fi

if ! rg -Fq "owner_queue_completed_tasks" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue completed-tasks output wiring."
  exit 1
fi

if ! rg -Fq "owner_queue_open_tasks" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue open-tasks output wiring."
  exit 1
fi

if ! rg -Fq "owner_queue_duplicate_comments_cleared" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route owner-queue dedupe output wiring."
  exit 1
fi

if ! rg -Fq "incident_owner_sync_action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route incident owner-sync action output wiring."
  exit 1
fi

if ! rg -Fq "incident_owner_sync_status" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing narrative route incident owner-sync status output wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_press_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder press artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_media_blast_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder media blast artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_guesting_queue_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting queue artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_guesting_brief_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder guesting sprint brief artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_ops_brief_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame ops brief artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_action_queue_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame action queue artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_interview_prep_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame interview prep artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_transcript_ingestion_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame transcript ingestion artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_repurpose_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame repurpose artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_uplift_tracker_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame uplift tracker artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_weight_profile_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame weight profile artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_momentum_brief_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame momentum brief artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_opportunity_radar_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame opportunity radar artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_execution_sprint_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution sprint artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_execution_scorecard_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame execution scorecard artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_risk_response_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame risk response plan artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_escalation_queue_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame escalation queue artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_command_center_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame command center artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_next_move_handoff_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move handoff artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_next_move_draft_pack_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame next-move draft-pack artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_spotlight_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame spotlight pack artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_breakout_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame breakout plan artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_outreach_sprint_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame outreach sprint artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_proof_loop_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_proof_loop_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop verification artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_velocity_scoreboard_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame velocity scoreboard artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_exceptional_loop_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional loop artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_exceptional_loop_comment_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop checklist comment artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_exceptional_loop_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame exceptional-loop live verification artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_narrative_lab_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame narrative lab artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_war_room_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_war_room_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room verification artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_war_room_comment_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room checklist comment artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_proof_loop_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame proof loop live verification artifact upload wiring."
  exit 1
fi

if ! rg -Fq "env.founder_fame_war_room_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder fame war-room live verification artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate distribution follow-up plan artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution follow-up artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_distribution_followup_plan.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call distribution follow-up generator script."
  exit 1
fi

if ! rg -Fq "Upsert distribution follow-up plan comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution follow-up comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-plan -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution follow-up marker wiring."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation \"\${CHANNEL_MIX_RECOMMENDATION:-Keep channel mix balanced until distribution execution score is logged.}\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing channel mix recommendation wiring into distribution follow-up generator."
  exit 1
fi

if ! rg -Fq "env.distribution_plan_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution follow-up artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Distribution follow-up artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution follow-up summary output."
  exit 1
fi

if ! rg -Fq "Generate viral experiment board artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_viral_experiment_board.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call viral experiment board generator script."
  exit 1
fi

if ! rg -Fq "Upsert viral experiment board comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-viral-experiment-board -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board marker wiring."
  exit 1
fi

if ! rg -Fq "Add viral experiment board summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board summary step."
  exit 1
fi

if ! rg -Fq "Viral experiment board artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board summary output."
  exit 1
fi

if ! rg -Fq "viral_experiment_board_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board path env wiring."
  exit 1
fi

if ! rg -q "^[[:space:]]+\\$\\{\\{ env\\.viral_experiment_board_path \\}\\}$" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing viral experiment board artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate winning hook library artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_winning_hook_library.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call winning hook library generator script."
  exit 1
fi

if ! rg -Fq "Upsert winning hook library comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-winning-hook-library -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library marker wiring."
  exit 1
fi

if ! rg -Fq "Add winning hook library summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library summary step."
  exit 1
fi

if ! rg -Fq "Winning hook library artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library summary output."
  exit 1
fi

if ! rg -Fq "winning_hook_library_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library path env wiring."
  exit 1
fi

if ! rg -q "^[[:space:]]+\\$\\{\\{ env\\.winning_hook_library_path \\}\\}$" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing winning hook library artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate social proof wall artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_social_proof_wall.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call social proof wall generator script."
  exit 1
fi

if ! rg -Fq "Upsert social proof wall comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-social-proof-wall -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall marker wiring."
  exit 1
fi

if ! rg -Fq "Add social proof wall summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall summary step."
  exit 1
fi

if ! rg -Fq "Social proof wall artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall summary output."
  exit 1
fi

if ! rg -Fq "social_proof_wall_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall path env wiring."
  exit 1
fi

if ! rg -q "^[[:space:]]+\\$\\{\\{ env\\.social_proof_wall_path \\}\\}$" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing social proof wall artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Generate credibility ledger artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger artifact step."
  exit 1
fi

if ! rg -Fq "scripts/generate_credibility_ledger.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow does not call credibility ledger generator script."
  exit 1
fi

if ! rg -Fq "Upsert credibility ledger comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger comment upsert step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-credibility-ledger -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger marker wiring."
  exit 1
fi

if ! rg -Fq "Add credibility ledger summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger summary step."
  exit 1
fi

if ! rg -Fq "Credibility ledger artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger summary output."
  exit 1
fi

if ! rg -Fq "credibility_ledger_path=" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger path env wiring."
  exit 1
fi

if ! rg -q "^[[:space:]]+\\$\\{\\{ env\\.credibility_ledger_path \\}\\}$" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing credibility ledger artifact upload wiring."
  exit 1
fi

if ! rg -Fq "Upsert distribution execution nudge" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution execution nudge step."
  exit 1
fi

if ! rg -Fq "github.paginate(github.rest.issues.listComments" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing paginated distribution comment scanning."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-nudge -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-action-items -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution action-items marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-escalation-start -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution escalation start marker wiring."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-escalation-end -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution escalation end marker wiring."
  exit 1
fi

if ! rg -Fq "## Distribution Action Items (Day 0-Day 2)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Day 0-Day 2 action-items comment content."
  exit 1
fi

if ! rg -Fq "## Distribution Escalation Queue (Auto-Managed)" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution escalation queue body content."
  exit 1
fi

if ! rg -Fq "stripEscalationBlock" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing stale escalation block cleanup logic."
  exit 1
fi

if ! rg -Fq "Escalated Day 0-Day 2 tasks" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing escalated Day 0-Day 2 task metrics in nudge output."
  exit 1
fi

if ! rg -Fq "steps.distribution_nudge.outputs.nudge_status" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge summary wiring."
  exit 1
fi

if ! rg -Fq "steps.distribution_nudge.outputs.escalation_status" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution escalation summary wiring."
  exit 1
fi

if ! rg -Fq "steps.distribution_nudge.outputs.escalated_tasks_count" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing escalated task count summary wiring."
  exit 1
fi

if ! rg -Fq "steps.distribution_nudge.outputs.escalated_tasks" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing escalated task labels summary wiring."
  exit 1
fi

if ! rg -Fq "Generate distribution nudge trace artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge trace artifact step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-nudge-trace -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge trace marker."
  exit 1
fi

if ! rg -Fq "distribution_nudge_trace_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge trace path wiring."
  exit 1
fi

if ! rg -Fq "Checklist issue number:" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing checklist issue number in distribution nudge trace."
  exit 1
fi

if ! rg -Fq "Distribution nudge trace artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge trace summary output."
  exit 1
fi

if ! rg -Fq "Distribution nudge verifier command" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge verifier command summary output."
  exit 1
fi

if ! rg -Fq "Verify distribution nudge state" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge self-verification step."
  exit 1
fi

if ! rg -Fq -- "--trace \"\$distribution_nudge_trace_path\"" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing trace-path verifier wiring."
  exit 1
fi

if ! rg -Fq "distribution_nudge_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge live-check artifact wiring."
  exit 1
fi

if ! rg -Fq "distribution_verifier_critical_threshold" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution verifier critical-threshold input wiring."
  exit 1
fi

if ! rg -Fq "distribution_verifier_critical_assignee" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution verifier critical-assignee input wiring."
  exit 1
fi

if ! rg -Fq "distribution_verifier_critical_assignees" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution verifier critical-assignees fallback input wiring."
  exit 1
fi

if ! rg -Fq "distribution_verifier_critical_comment_cooldown_hours" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution verifier critical-comment cooldown input wiring."
  exit 1
fi

if ! rg -Fq "distribution_verifier_critical_comment_min_failure_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution verifier critical-comment min-failure-delta input wiring."
  exit 1
fi

if ! rg -Fq "continue-on-error: true" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing continue-on-error wiring for distribution nudge verification step."
  exit 1
fi

if ! rg -Fq "Reconcile distribution nudge verification alert comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge verification alert reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-nudge-verifier-failure -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge verifier failure marker wiring."
  exit 1
fi

if ! rg -Fq "Reconcile distribution nudge verifier incident issue" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge verifier incident issue reconciliation step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-nudge-verifier-incident -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge verifier incident marker wiring."
  exit 1
fi

if ! rg -Fq "Distribution nudge incident issue action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge incident summary output."
  exit 1
fi

if ! rg -Fq "Distribution nudge incident critical escalation" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge incident critical summary output."
  exit 1
fi

if ! rg -Fq "Distribution nudge incident critical assignee action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge incident critical assignee summary output."
  exit 1
fi

if ! rg -Fq "Distribution nudge incident critical assignee attempts" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge incident critical assignee attempts summary output."
  exit 1
fi

if ! rg -Fq "distribution_nudge_incident" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge incident step wiring."
  exit 1
fi

if ! rg -Fq "critical_assignee_action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical assignee action output wiring."
  exit 1
fi

if ! rg -Fq "critical_assignee_selected" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical assignee selected output wiring."
  exit 1
fi

if ! rg -Fq "critical_assignee_attempts" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical assignee attempts output wiring."
  exit 1
fi

if ! rg -Fq "id: distribution_nudge_critical_comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge critical-comment step id wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment action output wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_cooldown_hours" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment cooldown-hours output wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_cooldown_active" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment cooldown-active output wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_min_failure_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment min-failure-delta output wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_failure_delta" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment failure-delta output wiring."
  exit 1
fi

if ! rg -Fq "critical_comment_policy_reason" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment policy-reason output wiring."
  exit 1
fi

if ! rg -Fq "Distribution nudge critical comment action" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment summary output."
  exit 1
fi

if ! rg -Fq "Distribution nudge critical comment policy reason" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical comment policy-reason summary output."
  exit 1
fi

if ! rg -Fq "Reconcile distribution nudge critical escalation comment" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical escalation checklist-comment reconciliation step."
  exit 1
fi

if ! rg -Fq "Write founder narrative route trace artifact" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route trace artifact step."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_narrative_route_run.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route live verifier wiring."
  exit 1
fi

if ! rg -Fq "founder_narrative_route_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route live-check artifact wiring."
  exit 1
fi

if ! rg -Fq "Enforce founder narrative route verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing founder narrative route verification enforcement step."
  exit 1
fi

if ! rg -Fq "scripts/verify_monday_publish_routing_run.sh" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish routing live verifier wiring."
  exit 1
fi

if ! rg -Fq "Verify Monday publish routing live state" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish routing live verification step."
  exit 1
fi

if ! rg -Fq "id: monday_publish_routing_live_verify" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish routing live verification step id wiring."
  exit 1
fi

if ! rg -Fq "monday_publish_routing_live_check_path" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish routing live-check artifact wiring."
  exit 1
fi

if ! rg -Fq "Add Monday publish routing verification summary" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish routing live verification summary step."
  exit 1
fi

if ! rg -Fq "Enforce Monday publish routing live verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing Monday publish routing live verification enforcement step."
  exit 1
fi

if ! rg -Fq "<!-- weekly-growth-distribution-nudge-verifier-critical -->" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing critical escalation marker wiring."
  exit 1
fi

if ! rg -Fq "growth-critical" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing growth-critical label wiring."
  exit 1
fi

if ! rg -Fq "Enforce distribution nudge verification" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing distribution nudge verification enforcement step."
  exit 1
fi

if ! rg -Fq "always() && env.review_path != ''" ".github/workflows/weekly-growth-review.yml"; then
  echo "Weekly growth review workflow is missing always-upload artifact guard for verifier failures."
  exit 1
fi

if ! node scripts/check_distribution_nudge_fixture.js >/dev/null; then
  echo "Weekly growth review workflow distribution nudge fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_guesting_signal_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder guesting signal fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_first48h_post_pack_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder first-48h post pack fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_first48h_controls_sync_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder first-48h controls sync fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_draft_promoted_scripts_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday draft promoted-scripts fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_promoted_defaults_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish promoted-defaults fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_precedence_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing-precedence fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_verify_step_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live-verify step fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_verify_step_contract_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live-verify step contract fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_summary_step_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live summary-step fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_enforcement_step_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live enforcement-step fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_verifier_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live verifier fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_verifier_mode_contract_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live verifier mode-contract fixture simulation failed."
  exit 1
fi

if ! node scripts/check_monday_publish_routing_live_verifier_review_availability_contract_fixture.js >/dev/null; then
  echo "Weekly growth review workflow Monday publish routing live verifier review-availability contract fixture simulation failed."
  exit 1
fi

if ! node scripts/check_launch_rescue_auto_trigger_contract_fixture.js >/dev/null; then
  echo "Launch rescue auto-trigger activity-detail contract fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_narrative_route_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder narrative route fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_narrative_route_incident_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder narrative route incident fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_narrative_route_critical_comment_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder narrative route critical-comment fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_narrative_route_owner_queue_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder narrative route owner-queue fixture simulation failed."
  exit 1
fi

if ! node scripts/check_distribution_nudge_critical_comment_fixture.js >/dev/null; then
  echo "Weekly growth review workflow critical distribution nudge comment fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_fame_proof_loop_alert_comment_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder proof loop verifier alert comment fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_fame_proof_loop_critical_comment_fixture.js >/dev/null; then
  echo "Weekly growth review workflow critical founder proof loop comment fixture simulation failed."
  exit 1
fi

if ! node scripts/check_founder_fame_proof_loop_incident_assignee_fixture.js >/dev/null; then
  echo "Weekly growth review workflow founder proof loop incident assignee fixture simulation failed."
  exit 1
fi

if ! zsh scripts/verify_distribution_nudge_run.sh --help >/dev/null; then
  echo "Distribution nudge live verification script help command failed."
  exit 1
fi

if ! zsh scripts/verify_monday_publish_routing_run.sh --help >/dev/null; then
  echo "Monday publish routing live verification script help command failed."
  exit 1
fi

if ! zsh scripts/verify_founder_narrative_route_run.sh --help >/dev/null; then
  echo "Founder narrative route live verification script help command failed."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_war_room_run.sh --help >/dev/null; then
  echo "Founder war-room live verification script help command failed."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_exceptional_loop_run.sh --help >/dev/null; then
  echo "Founder exceptional-loop live verification script help command failed."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_distribution_nudge_run.sh"; then
  echo "Distribution nudge live verification script is missing strict mode option."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_monday_publish_routing_run.sh"; then
  echo "Monday publish routing live verification script is missing strict mode option."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_founder_narrative_route_run.sh"; then
  echo "Founder narrative route live verification script is missing strict mode option."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_founder_fame_war_room_run.sh"; then
  echo "Founder war-room live verification script is missing strict mode option."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_founder_fame_exceptional_loop_run.sh"; then
  echo "Founder exceptional-loop live verification script is missing strict mode option."
  exit 1
fi

if ! rg -Fq -- "--trace <path>" "scripts/verify_distribution_nudge_run.sh"; then
  echo "Distribution nudge live verification script is missing trace mode option."
  exit 1
fi

if ! rg -Fq -- "--checklist <path>" "scripts/verify_monday_publish_routing_run.sh"; then
  echo "Monday publish routing live verification script is missing checklist artifact option."
  exit 1
fi

if ! rg -Fq -- "--review <path>" "scripts/verify_monday_publish_routing_run.sh"; then
  echo "Monday publish routing live verification script is missing review artifact option."
  exit 1
fi

if ! rg -Fq -- "--review <path>" "scripts/verify_founder_narrative_route_run.sh"; then
  echo "Founder narrative route live verification script is missing review artifact option."
  exit 1
fi

if ! rg -Fq -- "--war-room <path>" "scripts/verify_founder_fame_war_room_run.sh"; then
  echo "Founder war-room live verification script is missing war-room artifact option."
  exit 1
fi

if ! rg -Fq -- "--exceptional-loop <path>" "scripts/verify_founder_fame_exceptional_loop_run.sh"; then
  echo "Founder exceptional-loop live verification script is missing exceptional-loop artifact option."
  exit 1
fi

if ! rg -Fq "Distribution first 48h execution plan" "scripts/verify_founder_narrative_route_run.sh"; then
  echo "Founder narrative route live verification script is missing distribution first-48h execution-plan checks."
  exit 1
fi

if ! rg -Fq "Checklist first-48h execution plan field" "scripts/verify_founder_narrative_route_run.sh"; then
  echo "Founder narrative route live verification script is missing checklist first-48h execution-plan field checks."
  exit 1
fi

if ! zsh scripts/verify_founder_narrative_route_run.sh --sample >/dev/null; then
  echo "Founder narrative route live verification sample run failed."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_war_room_run.sh --sample --out "$sample_war_room_live_report_file" >/dev/null; then
  echo "Founder war-room live verification script sample mode failed."
  exit 1
fi

if ! rg -Fq -- "- Mode: sample" "$sample_war_room_live_report_file"; then
  echo "Founder war-room live verification sample report is missing sample mode metadata."
  exit 1
fi

if ! rg -Fq -- "- Result: PASS" "$sample_war_room_live_report_file"; then
  echo "Founder war-room live verification sample report is missing PASS result marker."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_exceptional_loop_run.sh --sample --out "$sample_exceptional_loop_live_report_file" >/dev/null; then
  echo "Founder exceptional-loop live verification script sample mode failed."
  exit 1
fi

if ! rg -Fq -- "- Mode: sample" "$sample_exceptional_loop_live_report_file"; then
  echo "Founder exceptional-loop live verification sample report is missing sample mode metadata."
  exit 1
fi

if ! rg -Fq -- "- Result: PASS" "$sample_exceptional_loop_live_report_file"; then
  echo "Founder exceptional-loop live verification sample report is missing PASS result marker."
  exit 1
fi

if ! zsh scripts/verify_monday_publish_routing_run.sh --sample --out "$sample_monday_publish_routing_live_report_file" >/dev/null; then
  echo "Monday publish routing live verification script sample mode failed."
  exit 1
fi

if ! rg -Fq -- "- Mode: sample" "$sample_monday_publish_routing_live_report_file"; then
  echo "Monday publish routing live verification sample report is missing sample mode metadata."
  exit 1
fi

if ! rg -Fq -- "- Result: PASS" "$sample_monday_publish_routing_live_report_file"; then
  echo "Monday publish routing live verification sample report is missing PASS result marker."
  exit 1
fi

if ! zsh scripts/verify_distribution_nudge_run.sh --sample --run-id check-growth-sample --out "$sample_nudge_report_file" >/dev/null; then
  echo "Distribution nudge live verification script sample mode failed."
  exit 1
fi

if ! zsh scripts/verify_distribution_nudge_run.sh --trace "$sample_nudge_trace_file" --out "$sample_nudge_report_file" >/dev/null; then
  echo "Distribution nudge live verification script trace mode failed."
  exit 1
fi

if ! zsh scripts/verify_distribution_nudge_run.sh --sample --run-id check-growth-sample-strict --out "$sample_strict_nudge_report_file" --strict >/dev/null; then
  echo "Distribution nudge live verification script strict sample mode failed."
  exit 1
fi

if ! rg -Fq "scripts/generate_distribution_followup_plan.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing distribution follow-up plan generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_viral_experiment_board.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing viral experiment board generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_social_proof_wall.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing social proof wall generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_weekly_growth_issue.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing weekly growth issue generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_update_post.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder update generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_first24h_reply_pack.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing first-24-hour reply pack generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_monday_publish_checkpoint.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing Monday publish checkpoint generation step."
  exit 1
fi

if ! rg -Fq "scripts/generate_winning_hook_library.sh" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing winning hook library generation step."
  exit 1
fi

if ! rg -Fq -- "--reply-pack-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing first-24-hour reply pack output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-post-pack-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder first-48h post pack output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-primary-char-limit" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder first-48h primary char-limit option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-backup-char-limit" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder first-48h backup char-limit option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-primary-tone" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder first-48h primary tone option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-first48h-backup-tone" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder first-48h backup tone option wiring."
  exit 1
fi

if ! rg -Fq -- "--monday-checkpoint-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing Monday publish checkpoint output option wiring."
  exit 1
fi

if ! rg -Fq -- "--weekly-issue-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing weekly growth issue output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-update-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder update output option wiring."
  exit 1
fi

if ! rg -Fq -- "--distribution-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing distribution output option wiring."
  exit 1
fi

if ! rg -Fq -- "--viral-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing viral experiment board output option wiring."
  exit 1
fi

if ! rg -Fq -- "--proof-wall-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing social proof wall output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-ops-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame ops brief output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-action-queue-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame action queue output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-interview-prep-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame interview prep output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-transcript-ingestion-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame transcript ingestion output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-transcript" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder transcript source option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-daily-mission" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame daily mission source option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-repurpose-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame repurpose output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-uplift-tracker-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame uplift tracker output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-weight-profile-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame weight profile output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-momentum-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame momentum brief output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-spotlight-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame spotlight pack output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-breakout-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame breakout plan output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-outreach-sprint-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame outreach sprint output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-proof-loop-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame proof loop output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-proof-loop-check-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame proof loop verification output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-kpi-snapshot-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame KPI snapshot output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-live-check-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame war-room live verification output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional loop output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-comment-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop checklist comment output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-live-check-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame exceptional-loop live verification output option wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-narrative-lab-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing founder fame narrative lab output option wiring."
  exit 1
fi

if ! rg -Fq -- "--hook-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing winning hook library output option wiring."
  exit 1
fi

if ! rg -Fq -- "--credibility-out" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing credibility ledger output option wiring."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing channel-mix recommendation option wiring."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-entries" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing creator signal entries option wiring."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-enrichment-score" "scripts/run_launch_day.sh"; then
  echo "Launch day runner is missing creator enrichment score option wiring."
  exit 1
fi

if ! rg -Fq "primary_audience_region" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing primary audience-region input."
  exit 1
fi

if ! rg -Fq "backup_audience_region" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing backup audience-region input."
  exit 1
fi

if ! rg -Fq "channel_roi_preferred_channel" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing channel ROI preferred-route input."
  exit 1
fi

if ! rg -Fq "channel_roi_recommendation" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing channel ROI recommendation input."
  exit 1
fi

if ! rg -Fq "channel_mix_recommendation" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing channel-mix recommendation input."
  exit 1
fi

if ! rg -Fq "creator_signal_entries" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing creator signal entries input."
  exit 1
fi

if ! rg -Fq "creator_signal_enrichment_score" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing creator enrichment score input."
  exit 1
fi

if ! rg -Fq "founder_transcript" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder transcript source input."
  exit 1
fi

if ! rg -Fq "founder_fame_daily_mission" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame daily mission source input."
  exit 1
fi

if ! rg -Fq "post_founder_fame_war_room_comment" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room checklist comment upsert input."
  exit 1
fi

if ! rg -Fq "post_founder_fame_exceptional_loop_comment" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist comment upsert input."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_comment_issue" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room checklist issue override input."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_comment_repo" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room checklist repo override input."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_comment_issue" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist issue override input."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_comment_repo" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist repo override input."
  exit 1
fi

if ! rg -Fq "INPUT_POST_FOUNDER_FAME_WAR_ROOM_COMMENT" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room checklist upsert env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_POST_FOUNDER_FAME_EXCEPTIONAL_LOOP_COMMENT" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist upsert env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_EXCEPTIONAL_LOOP_COMMENT_ISSUE" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist issue env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_EXCEPTIONAL_LOOP_COMMENT_REPO" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist repo env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_WAR_ROOM_COMMENT_REPO" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room checklist repo env wiring."
  exit 1
fi

if ! rg -Fq "issues: write" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing issues write permission for founder fame war-room checklist upsert."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_TRANSCRIPT" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder transcript source env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_DAILY_MISSION" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame daily mission source env wiring."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-out \"\$founder_fame_war_room_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame war-room output path into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-comment-out \"\$founder_fame_war_room_comment_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame war-room checklist comment output path into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-war-room-live-check-out \"\$founder_fame_war_room_live_check_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame war-room live verification output path into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--post-founder-fame-war-room-comment" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame war-room checklist upsert flag into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-comment-out \"\$founder_fame_exceptional_loop_comment_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional-loop checklist comment output path into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-live-check-out \"\$founder_fame_exceptional_loop_live_check_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional-loop live verification output path into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--post-founder-fame-exceptional-loop-comment" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional-loop checklist upsert flag into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--founder-transcript \"\$INPUT_FOUNDER_TRANSCRIPT\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder transcript source input into launch runner args."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-daily-mission \"\$INPUT_FOUNDER_FAME_DAILY_MISSION\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame daily mission source input into launch runner args."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission source:" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame daily mission source summary output."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission freshness:" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame daily mission freshness summary output."
  exit 1
fi

if ! rg -Fq "distribution_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing distribution follow-up output wiring."
  exit 1
fi

if ! rg -Fq "weekly_issue_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing weekly growth issue output wiring."
  exit 1
fi

if ! rg -Fq "founder_update_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder update output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_comment_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room checklist comment output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_war_room_live_check_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame war-room live verification output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_comment_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop checklist comment output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_exceptional_loop_live_check_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame exceptional-loop live verification output wiring."
  exit 1
fi

if ! rg -Fq "reply_pack_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing first-24-hour reply pack output wiring."
  exit 1
fi

if ! rg -Fq "monday_checkpoint_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing Monday publish checkpoint output wiring."
  exit 1
fi

if ! rg -Fq "viral_board_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing viral experiment board output wiring."
  exit 1
fi

if ! rg -Fq "social_proof_wall_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing social proof wall output wiring."
  exit 1
fi

if ! rg -Fq "winning_hook_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing winning hook library output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_proof_loop_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame proof loop output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_proof_loop_check_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame proof loop verification output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_kpi_snapshot_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing founder fame KPI snapshot output wiring."
  exit 1
fi

if ! rg -Fq "credibility_ledger_path=" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow is missing credibility ledger output wiring."
  exit 1
fi

if ! rg -Fq -- "--distribution-out \"\$distribution_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire distribution follow-up output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--weekly-issue-out \"\$weekly_issue_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire weekly growth issue output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-update-out \"\$founder_update_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder update output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--reply-pack-out \"\$reply_pack_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire first-24-hour reply pack output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--monday-checkpoint-out \"\$monday_checkpoint_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire Monday publish checkpoint output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--viral-out \"\$viral_board_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire viral experiment board output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--proof-wall-out \"\$social_proof_wall_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire social proof wall output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--hook-out \"\$winning_hook_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire winning hook library output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-proof-loop-out \"\$founder_fame_proof_loop_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame proof loop output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-proof-loop-check-out \"\$founder_fame_proof_loop_check_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame proof loop verification output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-kpi-snapshot-out \"\$founder_fame_kpi_snapshot_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame KPI snapshot output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--founder-fame-exceptional-loop-out \"\$founder_fame_exceptional_loop_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire founder fame exceptional loop output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--credibility-out \"\$credibility_ledger_path\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire credibility ledger output path into launch runner."
  exit 1
fi

if ! rg -Fq -- "--channel-roi-preferred-channel \"\$INPUT_CHANNEL_ROI_PREFERRED_CHANNEL\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire channel ROI preferred-route into launch runner."
  exit 1
fi

if ! rg -Fq -- "--channel-roi-recommendation \"\$INPUT_CHANNEL_ROI_RECOMMENDATION\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire channel ROI recommendation into launch runner."
  exit 1
fi

if ! rg -Fq -- "--channel-mix-recommendation \"\$INPUT_CHANNEL_MIX_RECOMMENDATION\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire channel-mix recommendation into launch runner."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-entries \"\$INPUT_CREATOR_SIGNAL_ENTRIES\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire creator signal entries into launch runner."
  exit 1
fi

if ! rg -Fq -- "--creator-signal-enrichment-score \"\$INPUT_CREATOR_SIGNAL_ENRICHMENT_SCORE\"" ".github/workflows/launch-pack.yml"; then
  echo "Launch pack workflow does not wire creator enrichment score into launch runner."
  exit 1
fi

if ! rg -Fq "weekly-sprint" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing sprint labels."
  exit 1
fi

if ! rg -Fq "state: 'closed'" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing stale issue close logic."
  exit 1
fi

if ! rg -Fq "Closing stale weekly sprint issue" ".github/workflows/weekly-growth-sprint.yml"; then
  echo "Weekly growth sprint workflow is missing stale issue comment."
  exit 1
fi

if ! rg -Fq "weekly-growth-review.yml" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing growth review workflow link."
  exit 1
fi

if ! rg -Fq "distribution follow-up" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing distribution follow-up guidance."
  exit 1
fi

if ! rg -Fq "channel-mix recommendation" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing channel-mix recommendation guidance."
  exit 1
fi

if ! rg -Fq "distribution nudge" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing distribution nudge guidance."
  exit 1
fi

if ! rg -Fq "founder-media-blast" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder media blast guidance."
  exit 1
fi

if ! rg -Fq "founder-guesting-queue" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder guesting queue guidance."
  exit 1
fi

if ! rg -Fq "founder-guesting-brief" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder guesting sprint brief guidance."
  exit 1
fi

if ! rg -Fq "founder fame ops brief" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame ops brief guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-ops-brief" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame ops brief artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-interview-prep" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame interview prep artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-transcript-ingestion" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame transcript ingestion artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-repurpose-plan" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame repurpose artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-uplift-tracker" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame uplift tracker artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-weight-profile" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame weight profile artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-momentum-brief" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame momentum brief artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-command-center" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame command center artifact guidance."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame in-app next-move guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-spotlight-pack" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame spotlight pack artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-breakout-plan" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame breakout plan artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-outreach-sprint" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame outreach sprint artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-kpi-snapshot" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame KPI snapshot artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-narrative-lab" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame narrative lab artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop-check" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop verification artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop-live-check" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop live verification artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-live-check" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame exceptional-loop live verification artifact guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_proof_loop.sh --proof-loop .build/founder/founder-fame-proof-loop-<week>.md --strict" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_proof_loop_run.sh --repo <owner/repo> --strict" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop live verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_exceptional_loop_run.sh --repo <owner/repo> --strict" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame exceptional-loop live verification command guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-proof-loop-verifier-failure" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop verifier failure marker guidance."
  exit 1
fi

if ! rg -Fq "Growth Incident: Founder Fame Proof Loop Verifier <week>" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof loop verifier incident guidance."
  exit 1
fi

if ! rg -Fq "founder_verifier_critical_threshold" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder verifier critical-threshold guidance."
  exit 1
fi

if ! rg -Fq "founder_verifier_comment_cooldown_hours" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder verifier comment cooldown guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-proof-loop-verifier-critical" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder proof loop critical-comment marker guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-narrative-lab" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame narrative lab marker guidance."
  exit 1
fi

if ! rg -Fq "Founder Narrative Route Signals" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route review-section checklist guidance."
  exit 1
fi

if ! rg -Fq "first 48h execution plan" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative first-48h execution-plan guidance."
  exit 1
fi

if ! rg -Fq "route mode" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route control guidance."
  exit 1
fi

if ! rg -Fq "effectiveness block includes founder narrative route winner + trend updates" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route effectiveness-block checklist guidance."
  exit 1
fi

if ! rg -Fq "founder-narrative-route-trace" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route trace artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-narrative-route-live-check" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route live verification artifact guidance."
  exit 1
fi

if ! rg -Fq "monday-publish-routing-live-check" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing Monday publish routing live verification artifact guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_narrative_route_run.sh --repo <owner/repo> --strict" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route live verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_monday_publish_routing_run.sh --repo <owner/repo> --issue <monday_issue_number> --review .build/growth/<week>-review.md --strict" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing Monday publish routing live verification command guidance."
  exit 1
fi

if ! rg -Fq "Growth Incident: Founder Narrative Route Control <week>" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route incident guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-incident" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route incident marker guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-critical" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder narrative route critical-comment marker guidance."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_threshold" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative route critical-threshold guidance."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_assignee" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative route critical-assignee guidance."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_comment_cooldown_hours" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative route critical-comment cooldown guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-queue" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative route owner-queue marker guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-queue-start" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative route owner-queue checklist-block marker guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-sync-start" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative route incident owner-sync marker guidance."
  exit 1
fi

if ! rg -Fq "Narrative route preferred variant" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative-route default variant routing guidance."
  exit 1
fi

if ! rg -Fq "Narrative-ranked opportunity" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing narrative-ranked opportunity guidance."
  exit 1
fi

if ! rg -Fq "founder fame repurpose plan comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame repurpose comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame transcript ingestion comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame transcript ingestion comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame momentum brief comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame momentum brief comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame command center comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame command center comment checklist guidance."
  exit 1
fi

if ! rg -Fq "In-App Fast Loop" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame command center in-app fast-loop checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame spotlight pack comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame spotlight pack comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame breakout plan comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame breakout plan comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame outreach sprint comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame outreach sprint comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame KPI snapshot comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame KPI snapshot comment checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame narrative lab comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame narrative lab comment checklist guidance."
  exit 1
fi

if ! rg -Fq "Lane Owner Defaults (Auto-Prefilled)" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame outreach sprint owner-defaults checklist guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Outreach Controls" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame outreach route-controls guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Proof Lane" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame proof-loop route-lane guidance."
  exit 1
fi

if ! rg -Fq "Friday review includes founder outreach sprint owner-default completion" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing Friday owner-default completion visibility guidance."
  exit 1
fi

if ! rg -Fq "founder fame weight profile artifact is uploaded" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame weight profile checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame uplift tracker artifact is uploaded" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame uplift tracker checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame outreach sprint artifact is uploaded" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame outreach sprint checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame KPI snapshot artifact is uploaded" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame KPI snapshot checklist guidance."
  exit 1
fi

if ! rg -Fq "founder fame narrative lab artifact is uploaded" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame narrative lab checklist guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_command_center.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame command center local command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_next_move_handoff.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame next-move handoff local command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_spotlight_pack.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame spotlight pack local command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_breakout_plan.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame breakout plan local command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame outreach sprint local command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_kpi_snapshot.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame KPI snapshot local command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_narrative_lab.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame narrative lab local command guidance."
  exit 1
fi

if ! rg -Fq "founder fame next-move handoff comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder fame next-move handoff checklist guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_first48h_post_pack.sh" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack local command guidance."
  exit 1
fi

if ! rg -Fq -- "--cta" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack CTA command guidance."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack primary-char-limit command guidance."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack backup-char-limit command guidance."
  exit 1
fi

if ! rg -Fq -- "--primary-tone" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack primary-tone command guidance."
  exit 1
fi

if ! rg -Fq -- "--backup-tone" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack backup-tone command guidance."
  exit 1
fi

if ! rg -Fq "founder-first48h-post-pack" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack artifact guidance."
  exit 1
fi

if ! rg -Fq "founder first-48h post pack comment exists" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder first-48h post pack checklist guidance."
  exit 1
fi

if ! rg -Fq "viral experiment board" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing viral experiment board guidance."
  exit 1
fi

if ! rg -Fq "viral-experiment-board" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing viral experiment board artifact guidance."
  exit 1
fi

if ! rg -Fq "social proof wall" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing social proof wall guidance."
  exit 1
fi

if ! rg -Fq "social-proof-wall" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing social proof wall artifact guidance."
  exit 1
fi

if ! rg -Fq "credibility ledger" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing credibility ledger guidance."
  exit 1
fi

if ! rg -Fq "credibility-ledger" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing credibility ledger artifact guidance."
  exit 1
fi

if ! rg -Fq "winning hook library" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing winning hook library guidance."
  exit 1
fi

if ! rg -Fq "winning-hook-library" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing winning hook library artifact guidance."
  exit 1
fi

if ! rg -Fq "generate_distribution_followup_plan.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing distribution follow-up generator command."
  exit 1
fi

if ! rg -Fq "generate_viral_experiment_board.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing viral experiment board generator command."
  exit 1
fi

if ! rg -Fq "generate_social_proof_wall.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing social proof wall generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_ops_brief.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame ops brief generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_interview_prep.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame interview prep generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_transcript_ingestion.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame transcript ingestion generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_repurpose_plan.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame repurpose generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_uplift_tracker.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame uplift tracker generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_weight_profile.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame weight profile generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_uplift_tracker.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing uplift tracker generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_uplift_tracker.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing uplift tracker generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_uplift_tracker.sh" "docs/FOUNDER_FAME_WEIGHT_PROFILE.md"; then
  echo "Founder fame weight profile docs are missing uplift tracker generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_uplift_tracker.sh" "docs/FOUNDER_FAME_UPLIFT_TRACKER.md"; then
  echo "Founder fame uplift tracker docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_uplift_tracker.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame uplift tracker generator command."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_UPLIFT_TRACKER.md" "README.md"; then
  echo "README is missing founder fame uplift tracker docs link."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_momentum_brief.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame momentum brief generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_opportunity_radar.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame opportunity radar generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_sprint.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame execution sprint generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_scorecard.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame execution scorecard generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_risk_response_plan.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame risk response plan generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_escalation_queue.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame escalation queue generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_command_center.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame command center generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_next_move_handoff.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame next-move handoff generator command."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame in-app next-move guidance."
  exit 1
fi

if ! rg -Fq "artifact link + owner update" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame command-center handoff guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_spotlight_pack.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame spotlight pack generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_breakout_plan.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame breakout plan generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame outreach sprint generator command."
  exit 1
fi

if ! rg -Fq "generate_credibility_ledger.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing credibility ledger generator command."
  exit 1
fi

if ! rg -Fq "generate_winning_hook_library.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing winning hook library generator command."
  exit 1
fi

if ! rg -Fq "generate_first24h_reply_pack.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing first-24-hour reply pack generator command."
  exit 1
fi

if ! rg -Fq "generate_monday_publish_checkpoint.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing Monday publish checkpoint generator command."
  exit 1
fi

if ! rg -Fq "generate_weekly_growth_issue.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing weekly growth issue generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_update_post.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder update generator command."
  exit 1
fi

if ! rg -Fq "generate_creator_target_list.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing creator target list generator command."
  exit 1
fi

if ! rg -Fq "viral experiment board" "docs/DISTRIBUTION_PLAYBOOK.md"; then
  echo "Distribution playbook docs are missing viral experiment board guidance."
  exit 1
fi

if ! rg -Fq "distribution-plan" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing distribution follow-up artifact guidance."
  exit 1
fi

if ! rg -Fq "reply-pack" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing first-24-hour reply pack artifact guidance."
  exit 1
fi

if ! rg -Fq "monday-checkpoint" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing Monday publish checkpoint artifact guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-issue" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing weekly growth issue artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-update" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder update artifact guidance."
  exit 1
fi

if ! rg -Fq "viral-experiment-board" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing viral experiment board artifact guidance."
  exit 1
fi

if ! rg -Fq "social-proof-wall" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing social proof wall artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-ops-brief" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame ops brief artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-interview-prep" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame interview prep artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-transcript-ingestion" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame transcript ingestion artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-repurpose-plan" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame repurpose artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-uplift-tracker" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame uplift tracker artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-weight-profile" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame weight profile artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-momentum-brief" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame momentum brief artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-opportunity-radar" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame opportunity radar artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-execution-sprint" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame execution sprint artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-execution-scorecard" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame execution scorecard artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-risk-response-plan" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame risk response plan artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-escalation-queue" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame escalation queue artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-spotlight-pack" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame spotlight pack artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-breakout-plan" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame breakout plan artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-outreach-sprint" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame outreach sprint artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-narrative-lab" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame narrative lab artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame exceptional loop artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-comment" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame exceptional-loop checklist comment artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-live-check" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame war-room live verification artifact guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-live-check" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame exceptional-loop live verification artifact guidance."
  exit 1
fi

if ! rg -Fq "strict mode when war-room comment upsert is enabled" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame war-room strict live verification guidance."
  exit 1
fi

if ! rg -Fq "strict mode when exceptional-loop comment upsert is enabled" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing founder fame exceptional-loop strict live verification guidance."
  exit 1
fi

if ! rg -Fq "winning-hook-library" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing winning hook library artifact guidance."
  exit 1
fi

if ! rg -Fq "credibility-ledger" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing credibility ledger artifact guidance."
  exit 1
fi

if ! rg -Fq "channel-mix recommendation" "docs/LAUNCH_PLAYBOOK.md"; then
  echo "Launch playbook docs are missing channel-mix recommendation guidance."
  exit 1
fi

if ! rg -Fq "viral-experiment-board" "docs/LAUNCH_PLAYBOOK.md"; then
  echo "Launch playbook docs are missing viral experiment board guidance."
  exit 1
fi

if ! rg -Fq "creator-target-list" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing creator target list artifact guidance."
  exit 1
fi

if ! rg -Fq "creator-signal" "docs/LAUNCH_DAY_PLAN.md"; then
  echo "Launch day plan docs are missing creator signal launch guidance."
  exit 1
fi

if ! rg -Fq "viral-experiment-board.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing viral experiment board launch guidance."
  exit 1
fi

if ! rg -Fq "reply-pack.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing first-24-hour reply pack launch guidance."
  exit 1
fi

if ! rg -Fq "monday-checkpoint.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing Monday publish checkpoint launch guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-issue.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing weekly growth issue launch guidance."
  exit 1
fi

if ! rg -Fq "founder-update.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder update launch guidance."
  exit 1
fi

if ! rg -Fq "social-proof-wall.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing social proof wall launch guidance."
  exit 1
fi

if ! rg -Fq "winning-hook-library.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing winning hook library launch guidance."
  exit 1
fi

if ! rg -Fq "credibility-ledger.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing credibility ledger launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-interview-prep.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame interview prep launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-transcript-ingestion.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame transcript ingestion launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-repurpose-plan.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame repurpose launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-uplift-tracker.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame uplift tracker launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-weight-profile.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame weight profile launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-momentum-brief.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame momentum brief launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-opportunity-radar.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame opportunity radar launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-execution-sprint.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame execution sprint launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-execution-scorecard.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame execution scorecard launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-risk-response-plan.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame risk response plan launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-escalation-queue.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame escalation queue launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-next-move-draft-pack.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame next-move draft-pack launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame war-room launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-check.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame war-room verification launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-comment.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame war-room checklist comment launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-live-check.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame war-room live verification launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-spotlight-pack.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame spotlight pack launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-breakout-plan.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame breakout plan launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-outreach-sprint.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame outreach sprint launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop-check" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame proof loop verification launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame exceptional loop launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-comment.md" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame exceptional-loop checklist comment launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop-live-check" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame proof loop live verification launch guidance."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-live-check" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame exceptional-loop live verification launch guidance."
  exit 1
fi

if ! rg -Fq "monday-publish-routing-live-check" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing Monday publish routing live verification launch guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_proof_loop.sh --proof-loop .build/founder/founder-fame-proof-loop-<week>.md --strict" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing strict founder proof loop verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_monday_publish_routing_run.sh --repo <owner/repo> --issue <monday_issue_number> --review .build/growth/<week>-review.md --strict" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing Monday publish routing live verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_proof_loop_run.sh --repo <owner/repo> --strict" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder proof loop live verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_exceptional_loop_run.sh --repo <owner/repo> --strict" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder exceptional-loop live verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_war_room_run.sh --repo <owner/repo> --strict" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder war-room live verification command guidance."
  exit 1
fi

if ! rg -Fq "Growth Incident: Founder Fame Proof Loop Verifier <week>" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder fame proof loop verifier incident guidance."
  exit 1
fi

if ! rg -Fq "founder_verifier_critical_threshold" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder verifier critical-threshold guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-proof-loop-verifier-critical" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder proof loop critical-comment guidance."
  exit 1
fi

if ! rg -Fq "Growth Incident: Founder Narrative Route Control <week>" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder narrative route incident guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-critical" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing founder narrative route critical-comment guidance."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_threshold" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing narrative route critical-threshold guidance."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_assignee" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing narrative route critical-assignee guidance."
  exit 1
fi

if ! rg -Fq "narrative_route_critical_comment_cooldown_hours" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing narrative route critical-comment cooldown guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-queue" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing narrative route owner-queue guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-queue-start" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing narrative route owner-queue checklist-block guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-sync-start" "docs/GROWTH_RELEASE_CHECKLIST.md"; then
  echo "Growth release checklist docs are missing narrative route incident owner-sync guidance."
  exit 1
fi

if ! rg -Fq "CREATOR_TARGET_LIST.md" "docs/CREATOR_OUTREACH_KIT.md"; then
  echo "Creator outreach docs are missing creator target list cross-link."
  exit 1
fi

if ! rg -Fq "creator-target-list" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing creator target list guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-creator-signal" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing creator signal marker guidance."
  exit 1
fi

if ! rg -Fq "Creator Account Enrichment" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing creator account enrichment guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-guesting-signal" "docs/WEEKLY_GROWTH_AUTOPILOT.md"; then
  echo "Weekly growth autopilot docs are missing founder guesting signal marker guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-creator-signal" "docs/CREATOR_TARGET_LIST.md"; then
  echo "Creator target list docs are missing creator signal comment format guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-guesting-signal" "docs/FOUNDER_GUESTING_QUEUE.md"; then
  echo "Founder guesting queue docs are missing guesting signal comment format guidance."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-entries" "docs/FOUNDER_GUESTING_QUEUE.md"; then
  echo "Founder guesting queue docs are missing guesting signal CLI wiring guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_guesting_brief.sh" "docs/FOUNDER_GUESTING_QUEUE.md"; then
  echo "Founder guesting queue docs are missing guesting sprint brief command guidance."
  exit 1
fi

if ! rg -Fq "founder-guesting-brief" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing founder guesting sprint brief guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_interview_prep.sh" "docs/FOUNDER_FAME_INTERVIEW_PREP.md"; then
  echo "Founder fame interview prep docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_transcript_ingestion.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing transcript ingestion generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_transcript_ingestion.sh" "docs/FOUNDER_FAME_TRANSCRIPT_INGESTION.md"; then
  echo "Founder fame transcript ingestion docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_repurpose_plan.sh" "docs/FOUNDER_FAME_REPURPOSE_PLAN.md"; then
  echo "Founder fame repurpose docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_momentum_brief.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing momentum brief generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_opportunity_radar.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing opportunity radar generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_sprint.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing execution sprint generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_scorecard.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing execution scorecard generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_risk_response_plan.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing risk response plan generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_escalation_queue.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing escalation queue generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_command_center.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing command center generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_next_move_handoff.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing next-move handoff generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_spotlight_pack.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing spotlight pack generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_breakout_plan.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing breakout plan generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing outreach sprint generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_exceptional_loop.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing exceptional loop generator command guidance."
  exit 1
fi

if ! rg -Fq "post_founder_fame_exceptional_loop_comment.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing exceptional-loop checklist comment command guidance."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing action-queue mission freshness context guidance."
  exit 1
fi

if ! rg -Fq "founder_fame_action_queue" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing founder_fame_action_queue workflow input guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_exceptional_loop_run.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing exceptional-loop live verification command guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_war_room_run.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing war-room live verification command guidance."
  exit 1
fi

if ! rg -Fq "post_founder_fame_exceptional_loop_comment.sh" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing exceptional-loop checklist comment command guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-exceptional-loop-comment" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing exceptional-loop checklist comment marker guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_exceptional_loop_run.sh" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing exceptional-loop live verification command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_momentum_brief.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_opportunity_radar.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing opportunity radar generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_sprint.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing execution sprint generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_scorecard.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing execution scorecard generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_risk_response_plan.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing risk response plan generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_escalation_queue.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing escalation queue generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_command_center.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing command center generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_spotlight_pack.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing spotlight pack generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_breakout_plan.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing breakout plan generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing outreach sprint generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_weight_profile.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing weight profile generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_weight_profile.sh" "docs/FOUNDER_FAME_MOMENTUM_BRIEF.md"; then
  echo "Founder fame momentum brief docs are missing weight profile generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_weight_profile.sh" "docs/FOUNDER_FAME_WEIGHT_PROFILE.md"; then
  echo "Founder fame weight profile docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_weight_profile.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame weight profile generator command."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_opportunity_radar.sh" "docs/FOUNDER_FAME_OPPORTUNITY_RADAR.md"; then
  echo "Founder fame opportunity radar docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_sprint.sh" "docs/FOUNDER_FAME_EXECUTION_SPRINT.md"; then
  echo "Founder fame execution sprint docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Execution Mode" "docs/FOUNDER_FAME_EXECUTION_SPRINT.md"; then
  echo "Founder fame execution sprint docs are missing narrative route execution mode guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_execution_scorecard.sh" "docs/FOUNDER_FAME_EXECUTION_SCORECARD.md"; then
  echo "Founder fame execution scorecard docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Alignment" "docs/FOUNDER_FAME_EXECUTION_SCORECARD.md"; then
  echo "Founder fame execution scorecard docs are missing narrative route alignment guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_risk_response_plan.sh" "docs/FOUNDER_FAME_EXECUTION_SCORECARD.md"; then
  echo "Founder fame execution scorecard docs are missing risk response plan generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_risk_response_plan.sh" "docs/FOUNDER_FAME_RISK_RESPONSE_PLAN.md"; then
  echo "Founder fame risk response plan docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Risk Controls" "docs/FOUNDER_FAME_RISK_RESPONSE_PLAN.md"; then
  echo "Founder fame risk response plan docs are missing narrative route risk controls guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_escalation_queue.sh" "docs/FOUNDER_FAME_RISK_RESPONSE_PLAN.md"; then
  echo "Founder fame risk response plan docs are missing escalation queue generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_escalation_queue.sh" "docs/FOUNDER_FAME_ESCALATION_QUEUE.md"; then
  echo "Founder fame escalation queue docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Escalation Lane" "docs/FOUNDER_FAME_ESCALATION_QUEUE.md"; then
  echo "Founder fame escalation queue docs are missing narrative route escalation lane guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_command_center.sh" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_next_move_handoff.sh" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing next-move handoff generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Control Tower" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing narrative route control tower guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_spotlight_pack.sh" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing spotlight pack generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_breakout_plan.sh" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing breakout plan generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing outreach sprint generator command guidance."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" "docs/FOUNDER_FAME_COMMAND_CENTER.md"; then
  echo "Founder fame command center docs are missing in-app next-move guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_spotlight_pack.sh" "docs/FOUNDER_FAME_SPOTLIGHT_PACK.md"; then
  echo "Founder fame spotlight pack docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Route Integrity Messaging" "docs/FOUNDER_FAME_SPOTLIGHT_PACK.md"; then
  echo "Founder fame spotlight pack docs are missing route integrity messaging guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_breakout_plan.sh" "docs/FOUNDER_FAME_BREAKOUT_PLAN.md"; then
  echo "Founder fame breakout plan docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Scale Plan" "docs/FOUNDER_FAME_BREAKOUT_PLAN.md"; then
  echo "Founder fame breakout plan docs are missing narrative route scale plan guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/FOUNDER_FAME_BREAKOUT_PLAN.md"; then
  echo "Founder fame breakout plan docs are missing outreach sprint generator command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_outreach_sprint.sh" "docs/FOUNDER_FAME_OUTREACH_SPRINT.md"; then
  echo "Founder fame outreach sprint docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Outreach Controls" "docs/FOUNDER_FAME_OUTREACH_SPRINT.md"; then
  echo "Founder fame outreach sprint docs are missing narrative route outreach controls guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_proof_loop.sh" "docs/FOUNDER_FAME_PROOF_LOOP.md"; then
  echo "Founder fame proof loop docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Proof Lane" "docs/FOUNDER_FAME_PROOF_LOOP.md"; then
  echo "Founder fame proof loop docs are missing narrative route proof lane guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_kpi_snapshot.sh" "docs/FOUNDER_FAME_KPI_SNAPSHOT.md"; then
  echo "Founder fame KPI snapshot docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq -- "--proof-loop-check" "docs/FOUNDER_FAME_KPI_SNAPSHOT.md"; then
  echo "Founder fame KPI snapshot docs are missing proof-loop-check option guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route KPI Controls" "docs/FOUNDER_FAME_KPI_SNAPSHOT.md"; then
  echo "Founder fame KPI snapshot docs are missing narrative route KPI controls guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_velocity_scoreboard.sh" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder fame velocity scoreboard docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder fame velocity scoreboard docs are missing kpi-snapshot option guidance."
  exit 1
fi

if ! rg -Fq "Route Velocity Controls" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder fame velocity scoreboard docs are missing route velocity controls guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-velocity-scoreboard" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder fame velocity scoreboard docs are missing weekly checklist marker guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_velocity_scoreboard.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing founder fame velocity scoreboard guidance."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_EXCEPTIONAL_LOOP.md" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing founder fame exceptional loop guide link."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_narrative_lab.sh" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing kpi-snapshot option guidance."
  exit 1
fi

if ! rg -Fq "Narrative Route Lab Controls" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing narrative route lab controls guidance."
  exit 1
fi

if ! rg -Fq "route mode/alignment/lane-status/guardrail/control recommendation" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing route-control sync guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-queue" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing narrative route owner-queue guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-queue-start" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing narrative route owner-queue checklist-block guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-narrative-route-owner-sync-start" "docs/FOUNDER_FAME_NARRATIVE_LAB.md"; then
  echo "Founder fame narrative lab docs are missing narrative route incident owner-sync guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_first48h_post_pack.sh" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq -- "--narrative-lab" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing narrative-lab option guidance."
  exit 1
fi

if ! rg -Fq -- "--cta" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing cta option guidance."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing primary-char-limit option guidance."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing backup-char-limit option guidance."
  exit 1
fi

if ! rg -Fq -- "--primary-tone" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing primary-tone option guidance."
  exit 1
fi

if ! rg -Fq -- "--backup-tone" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing backup-tone option guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-first48h-post-pack" "docs/FOUNDER_FIRST48H_POST_PACK.md"; then
  echo "Founder first-48h post pack docs are missing checklist marker guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_narrative_lab.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing founder fame narrative lab generator command."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_WEIGHT_PROFILE.md" "README.md"; then
  echo "README is missing founder fame weight profile docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_MOMENTUM_BRIEF.md" "README.md"; then
  echo "README is missing founder fame momentum brief docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FIRST48H_POST_PACK.md" "README.md"; then
  echo "README is missing founder first-48h post pack docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_OPPORTUNITY_RADAR.md" "README.md"; then
  echo "README is missing founder fame opportunity radar docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_EXECUTION_SPRINT.md" "README.md"; then
  echo "README is missing founder fame execution sprint docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_EXECUTION_SCORECARD.md" "README.md"; then
  echo "README is missing founder fame execution scorecard docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_RISK_RESPONSE_PLAN.md" "README.md"; then
  echo "README is missing founder fame risk response plan docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_ESCALATION_QUEUE.md" "README.md"; then
  echo "README is missing founder fame escalation queue docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_COMMAND_CENTER.md" "README.md"; then
  echo "README is missing founder fame command center docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_SPOTLIGHT_PACK.md" "README.md"; then
  echo "README is missing founder fame spotlight pack docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_BREAKOUT_PLAN.md" "README.md"; then
  echo "README is missing founder fame breakout plan docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_OUTREACH_SPRINT.md" "README.md"; then
  echo "README is missing founder fame outreach sprint docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_PROOF_LOOP.md" "README.md"; then
  echo "README is missing founder fame proof loop docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_KPI_SNAPSHOT.md" "README.md"; then
  echo "README is missing founder fame KPI snapshot docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_VELOCITY_SCOREBOARD.md" "README.md"; then
  echo "README is missing founder fame velocity scoreboard docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_NARRATIVE_LAB.md" "README.md"; then
  echo "README is missing founder fame narrative lab docs link."
  exit 1
fi

if ! rg -Fq "workflow_dispatch" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing workflow_dispatch trigger."
  exit 1
fi

if ! rg -Fq "schedule:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing schedule trigger."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_weekly_review.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not call weekly review generator script."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_weekly_pack.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not call weekly pack generator script."
  exit 1
fi

if ! rg -Fq "founder-fame-pack-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder artifact naming."
  exit 1
fi

if ! rg -Fq "founder-press-kit-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder press-kit artifact naming."
  exit 1
fi

if ! rg -Fq "founder-media-blast-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder media blast artifact naming."
  exit 1
fi

if ! rg -Fq "founder-guesting-queue-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder guesting queue artifact naming."
  exit 1
fi

if ! rg -Fq "founder-guesting-brief-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder guesting sprint brief artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-interview-prep-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame interview prep artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-transcript-ingestion-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame transcript ingestion artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-repurpose-plan-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame repurpose artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-uplift-tracker-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame uplift tracker artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-weight-profile-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame weight profile artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-momentum-brief-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame momentum brief artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-opportunity-radar-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame opportunity radar artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-execution-sprint-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution sprint artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-execution-scorecard-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution scorecard artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-risk-response-plan-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame risk response plan artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-escalation-queue-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame escalation queue artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-command-center-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame command center artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-next-move-handoff-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame next-move handoff artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-spotlight-pack-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame spotlight pack artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-breakout-plan-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame breakout plan artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-outreach-sprint-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame outreach sprint artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-proof-loop-check-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop verification artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-kpi-snapshot-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame KPI snapshot artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-velocity-scoreboard-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame velocity scoreboard artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional loop artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-live-check-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop live verification artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-live-check-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame war-room live verification artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-narrative-lab-" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame narrative lab artifact naming."
  exit 1
fi

if ! rg -Fq "Founder fame weight profile" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame weight profile summary output."
  exit 1
fi

if ! rg -Fq "Founder fame uplift tracker" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame uplift tracker summary output."
  exit 1
fi

if ! rg -Fq "Founder fame opportunity radar" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame opportunity radar summary output."
  exit 1
fi

if ! rg -Fq "Founder fame velocity scoreboard" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame velocity scoreboard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional loop" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop checklist comment" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop checklist comment summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop live verification" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop live verification summary output."
  exit 1
fi

if ! rg -Fq "Optional founder fame action queue overlay:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder_fame_action_queue overlay summary output."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission freshness:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame daily mission freshness summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room live verification" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame war-room live verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame execution sprint" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution sprint summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop summary output."
  exit 1
fi

if ! rg -Fq "Founder fame proof loop verification" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame KPI snapshot" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame KPI snapshot summary output."
  exit 1
fi

if ! rg -Fq "Founder fame narrative lab" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame narrative lab summary output."
  exit 1
fi

if ! rg -Fq "Founder fame execution scorecard" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution scorecard summary output."
  exit 1
fi

if ! rg -Fq "Founder fame risk response plan" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame risk response plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame escalation queue" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame escalation queue summary output."
  exit 1
fi

if ! rg -Fq "Founder fame command center" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame command center summary output."
  exit 1
fi

if ! rg -Fq "Founder fame next-move handoff" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame next-move handoff summary output."
  exit 1
fi

if ! rg -Fq "Run Fame Next Move" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame in-app next-move summary guidance."
  exit 1
fi

if ! rg -Fq "artifact link + owner update" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame command-center handoff summary guidance."
  exit 1
fi

if ! rg -Fq "Founder fame spotlight pack" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame spotlight pack summary output."
  exit 1
fi

if ! rg -Fq "Founder fame breakout plan" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame breakout plan summary output."
  exit 1
fi

if ! rg -Fq "Founder fame outreach sprint" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame outreach sprint summary output."
  exit 1
fi

if ! rg -Fq "press_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing press path output wiring."
  exit 1
fi

if ! rg -Fq "media_blast_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing media blast path output wiring."
  exit 1
fi

if ! rg -Fq "guesting_queue_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing guesting queue path output wiring."
  exit 1
fi

if ! rg -Fq "guesting_brief_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing guesting sprint brief path output wiring."
  exit 1
fi

if ! rg -Fq "interview_prep_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame interview prep path output wiring."
  exit 1
fi

if ! rg -Fq "transcript_ingestion_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame transcript ingestion path output wiring."
  exit 1
fi

if ! rg -Fq "repurpose_plan_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame repurpose path output wiring."
  exit 1
fi

if ! rg -Fq "uplift_tracker_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame uplift tracker path output wiring."
  exit 1
fi

if ! rg -Fq "weight_profile_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame weight profile path output wiring."
  exit 1
fi

if ! rg -Fq "momentum_brief_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame momentum brief path output wiring."
  exit 1
fi

if ! rg -Fq "opportunity_radar_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame opportunity radar path output wiring."
  exit 1
fi

if ! rg -Fq "execution_sprint_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution sprint path output wiring."
  exit 1
fi

if ! rg -Fq "execution_scorecard_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution scorecard path output wiring."
  exit 1
fi

if ! rg -Fq "risk_response_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame risk response plan path output wiring."
  exit 1
fi

if ! rg -Fq "escalation_queue_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame escalation queue path output wiring."
  exit 1
fi

if ! rg -Fq "command_center_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame command center path output wiring."
  exit 1
fi

if ! rg -Fq "next_move_handoff_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame next-move handoff path output wiring."
  exit 1
fi

if ! rg -Fq "spotlight_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame spotlight pack path output wiring."
  exit 1
fi

if ! rg -Fq "breakout_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame breakout plan path output wiring."
  exit 1
fi

if ! rg -Fq "outreach_sprint_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame outreach sprint path output wiring."
  exit 1
fi

if ! rg -Fq "proof_loop_check_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop verification path output wiring."
  exit 1
fi

if ! rg -Fq "kpi_snapshot_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame KPI snapshot path output wiring."
  exit 1
fi

if ! rg -Fq "exceptional_loop_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional loop path output wiring."
  exit 1
fi

if ! rg -Fq "exceptional_loop_comment_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop checklist comment path output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_action_queue_overlay_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder_fame_action_queue overlay output wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_daily_mission_freshness=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame daily mission freshness output wiring."
  exit 1
fi

if ! rg -Fq "exceptional_loop_live_check_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop live verification path output wiring."
  exit 1
fi

if ! rg -Fq "war_room_live_check_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame war-room live verification path output wiring."
  exit 1
fi

if ! rg -Fq "narrative_lab_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame narrative lab path output wiring."
  exit 1
fi

if ! rg -Fq "first48h_post_pack_path=" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h post pack path output wiring."
  exit 1
fi

if ! rg -Fq "source scripts/fixtures/founder/sample_inputs.env" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing fixture defaults sourcing for scheduled runs."
  exit 1
fi

if ! rg -Fq "github.event.inputs" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing event input wiring."
  exit 1
fi

if ! rg -Fq "post_exceptional_loop_comment" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing post_exceptional_loop_comment input wiring."
  exit 1
fi

if ! rg -Fq "exceptional_loop_comment_issue" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing exceptional_loop_comment_issue input wiring."
  exit 1
fi

if ! rg -Fq "INPUT_POST_EXCEPTIONAL_LOOP_COMMENT" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing exceptional-loop checklist comment upsert env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_ACTION_QUEUE" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder_fame_action_queue env wiring."
  exit 1
fi

if ! rg -Fq "guesting_signal_entries" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing guesting signal entries input."
  exit 1
fi

if ! rg -Fq "founder_transcript" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder transcript source input."
  exit 1
fi

if ! rg -Fq "founder_fame_action_queue" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder_fame_action_queue optional input."
  exit 1
fi

if ! rg -Fq "first48h_primary_char_limit" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h primary char-limit dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_backup_char_limit" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h backup char-limit dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_primary_tone" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h primary tone dispatch input."
  exit 1
fi

if ! rg -Fq "first48h_backup_tone" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h backup tone dispatch input."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_TRANSCRIPT" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder transcript source env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FIRST48H_PRIMARY_CHAR_LIMIT" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h primary char-limit env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FIRST48H_BACKUP_CHAR_LIMIT" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h backup char-limit env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FIRST48H_PRIMARY_TONE" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h primary tone env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FIRST48H_BACKUP_TONE" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h backup tone env wiring."
  exit 1
fi

if ! rg -Fq -- "first48h_primary_char_limit=\"\$(resolve_value \"\$INPUT_FIRST48H_PRIMARY_CHAR_LIMIT\" \"280\")\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h primary char-limit default resolution."
  exit 1
fi

if ! rg -Fq -- "first48h_backup_char_limit=\"\$(resolve_value \"\$INPUT_FIRST48H_BACKUP_CHAR_LIMIT\" \"500\")\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h backup char-limit default resolution."
  exit 1
fi

if ! rg -Fq -- "first48h_primary_tone=\"\$(resolve_value \"\$INPUT_FIRST48H_PRIMARY_TONE\" \"x-punchy\")\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h primary tone default resolution."
  exit 1
fi

if ! rg -Fq -- "first48h_backup_tone=\"\$(resolve_value \"\$INPUT_FIRST48H_BACKUP_TONE\" \"linkedin-context\")\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h backup tone default resolution."
  exit 1
fi

if ! rg -Fq -- "--guesting-signal-entries" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing guesting signal entries wiring into weekly pack runner."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_interview_prep.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame interview prep generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_transcript_ingestion.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame transcript ingestion generator call."
  exit 1
fi

if ! rg -Fq -- "--transcript \"\$transcript_source_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder transcript source path into transcript ingestion generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_repurpose_plan.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame repurpose generator call."
  exit 1
fi

if ! rg -Fq -- "--transcript-ingestion \"\$transcript_ingestion_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire transcript ingestion artifact into founder repurpose generator."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_weight_profile.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame weight profile generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_uplift_tracker.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame uplift tracker generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_momentum_brief.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame momentum brief generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_opportunity_radar.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame opportunity radar generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_sprint.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution sprint generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_scorecard.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame execution scorecard generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_risk_response_plan.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame risk response plan generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_escalation_queue.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame escalation queue generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_command_center.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame command center generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_handoff.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame next-move handoff generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_spotlight_pack.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame spotlight pack generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_breakout_plan.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame breakout plan generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_outreach_sprint.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame outreach sprint generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_proof_loop.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop generator call."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_proof_loop.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame proof loop verifier call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_kpi_snapshot.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame KPI snapshot generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_exceptional_loop.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional loop generator call."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_exceptional_loop_comment.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop checklist comment render/upsert command."
  exit 1
fi

if ! rg -Fq -- "--action-queue \"\$founder_fame_action_queue_overlay_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder_fame_action_queue overlay into checklist comment scripts."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_exceptional_loop_run.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop live verification command."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room_run.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame war-room live verification command."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_narrative_lab.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame narrative lab generator call."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_first48h_post_pack.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder first-48h post pack generator call."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot \"\$kpi_snapshot_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder KPI snapshot into founder narrative lab generator."
  exit 1
fi

if ! rg -Fq -- "--velocity-scoreboard \"\$velocity_scoreboard_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder velocity scoreboard artifact into founder exceptional loop generator."
  exit 1
fi

if ! rg -Fq -- "--comment \"\$exceptional_loop_comment_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire exceptional-loop checklist comment artifact into founder exceptional-loop live verification."
  exit 1
fi

if ! rg -Fq "exceptional_loop_verify_args+=(--strict)" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing strict founder exceptional-loop live verification wiring."
  exit 1
fi

if ! rg -Fq "war_room_verify_args+=(--strict)" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing strict founder war-room live verification wiring."
  exit 1
fi

if ! rg -Fq -- "--narrative-lab \"\$narrative_lab_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder narrative lab artifact into founder first-48h post pack generator."
  exit 1
fi

if ! rg -Fq -- "--cta \"\$cta_text\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder CTA into founder first-48h post pack generator."
  exit 1
fi

if ! rg -Fq -- "--out \"\$first48h_post_pack_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder first-48h post pack output path into first-48h generator."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit \"\$first48h_primary_char_limit\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder first-48h primary char limit into first-48h generator."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit \"\$first48h_backup_char_limit\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder first-48h backup char limit into first-48h generator."
  exit 1
fi

if ! rg -Fq -- "--primary-tone \"\$first48h_primary_tone\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder first-48h primary tone into first-48h generator."
  exit 1
fi

if ! rg -Fq -- "--backup-tone \"\$first48h_backup_tone\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder first-48h backup tone into first-48h generator."
  exit 1
fi

if ! rg -Fq "creator_target_list:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing creator target list workflow-dispatch input."
  exit 1
fi

if ! rg -Fq "distribution_plan:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing distribution plan workflow-dispatch input."
  exit 1
fi

if ! rg -Fq "INPUT_CREATOR_TARGET_LIST: \${{ github.event.inputs.creator_target_list || '' }}" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing creator target list env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_DISTRIBUTION_PLAN: \${{ github.event.inputs.distribution_plan || '' }}" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing distribution plan env wiring."
  exit 1
fi

if ! rg -Fq -- "--uplift-tracker \"\$uplift_tracker_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire uplift tracker into founder weight profile generator."
  exit 1
fi

if ! rg -Fq -- "--weight-profile \"\$weight_profile_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire weight profile into founder momentum generator."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief \"\$momentum_brief_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire momentum brief into founder opportunity radar generator."
  exit 1
fi

if ! rg -Fq -- "--opportunity-radar \"\$opportunity_radar_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire opportunity radar into founder execution sprint generator."
  exit 1
fi

if ! rg -Fq -- "--execution-sprint \"\$execution_sprint_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire execution sprint into founder execution scorecard generator."
  exit 1
fi

if ! rg -Fq -- "--execution-scorecard \"\$execution_scorecard_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire execution scorecard into founder risk response plan generator."
  exit 1
fi

if ! rg -Fq -- "--risk-response-plan \"\$risk_response_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire risk response plan into founder escalation queue generator."
  exit 1
fi

if ! rg -Fq -- "--momentum-brief \"\$momentum_brief_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire momentum brief into founder command center generator."
  exit 1
fi

if ! rg -Fq -- "--escalation-queue \"\$escalation_queue_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire escalation queue into founder command center generator."
  exit 1
fi

if ! rg -Fq -- "--out \"\$command_center_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire command center output path into founder command center generator."
  exit 1
fi

if ! rg -Fq -- "--command-center \"\$command_center_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire command center output into founder next-move handoff generator."
  exit 1
fi

if ! rg -Fq -- "--out \"\$next_move_handoff_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire next-move handoff output path into founder next-move handoff generator."
  exit 1
fi

if ! rg -Fq -- "--artifact-link \"\$command_center_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire command center artifact link into founder next-move handoff generator."
  exit 1
fi

if ! rg -Fq "echo \"next_move_handoff_path=\$next_move_handoff_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame next-move handoff output wiring."
  exit 1
fi

if ! rg -Fq "echo \"exceptional_loop_path=\$exceptional_loop_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional loop output wiring."
  exit 1
fi

if ! rg -Fq "echo \"exceptional_loop_comment_path=\$exceptional_loop_comment_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame exceptional-loop checklist comment output wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_action_queue_overlay_path=\$founder_fame_action_queue_overlay_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder_fame_action_queue overlay output wiring."
  exit 1
fi

if ! rg -Fq "echo \"founder_fame_daily_mission_freshness=\$founder_fame_daily_mission_freshness\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow is missing founder fame daily mission freshness output wiring."
  exit 1
fi

if ! rg -Fq -- "--command-center \"\$command_center_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire founder command center output into founder spotlight generator."
  exit 1
fi

if ! rg -Fq -- "--out \"\$spotlight_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire spotlight output path into founder spotlight generator."
  exit 1
fi

if ! rg -Fq -- "--spotlight-pack \"\$spotlight_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire spotlight output into founder breakout generator."
  exit 1
fi

if ! rg -Fq -- "--out \"\$breakout_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire breakout output path into founder breakout generator."
  exit 1
fi

if ! rg -Fq -- "--breakout-plan \"\$breakout_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire breakout output into founder outreach sprint generator."
  exit 1
fi

if ! rg -Fq -- "--creator-target-list \"\$creator_target_list_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire creator target list overlay into founder outreach sprint generator."
  exit 1
fi

if ! rg -Fq -- "--distribution-plan \"\$distribution_plan_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire distribution plan overlay into founder breakout/outreach generators."
  exit 1
fi

if ! rg -Fq -- "--out \"\$outreach_sprint_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire outreach sprint output path into founder outreach sprint generator."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint \"\$outreach_sprint_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire outreach sprint artifact into founder proof loop generator."
  exit 1
fi

if ! rg -Fq -- "--out \"\$proof_loop_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder fame workflow does not wire proof loop output path into founder proof loop generator."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_press_kit.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing press kit generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_media_blast.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing media blast generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_guesting_queue.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing guesting queue generator coverage."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-completion-rate" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing outreach sprint completion-rate coverage for guesting queue generation."
  exit 1
fi

if ! rg -Fq -- "--outreach-sprint-recommendation" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing outreach sprint recommendation coverage for guesting queue generation."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_guesting_brief.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing guesting sprint brief generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_interview_prep.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame interview prep generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_transcript_ingestion.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame transcript ingestion generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_repurpose_plan.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame repurpose generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_weight_profile.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame weight profile generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_uplift_tracker.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame uplift tracker generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_momentum_brief.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame momentum brief generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_opportunity_radar.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame opportunity radar generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_sprint.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame execution sprint generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_execution_scorecard.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame execution scorecard generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_risk_response_plan.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame risk response plan generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_escalation_queue.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame escalation queue generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_command_center.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame command center generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_handoff.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame next-move handoff generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_spotlight_pack.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame spotlight pack generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_breakout_plan.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame breakout plan generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_outreach_sprint.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame outreach sprint generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_proof_loop.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame proof loop generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_exceptional_loop.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame exceptional-loop generator coverage."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_exceptional_loop_comment.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame exceptional-loop checklist comment coverage."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_exceptional_loop_run.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame exceptional-loop live verification coverage."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room_run.sh" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame war-room live verification coverage."
  exit 1
fi

if ! rg -Fq "docs/FOUNDER_FAME_SPOTLIGHT_PACK.md" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame spotlight pack docs coverage."
  exit 1
fi

if ! rg -Fq "docs/FOUNDER_FAME_BREAKOUT_PLAN.md" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame breakout plan docs coverage."
  exit 1
fi

if ! rg -Fq "docs/FOUNDER_FAME_OUTREACH_SPRINT.md" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame outreach sprint docs coverage."
  exit 1
fi

if ! rg -Fq "docs/FOUNDER_FAME_PROOF_LOOP.md" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame proof loop docs coverage."
  exit 1
fi

if ! rg -Fq "command_center_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame command center fixture marker coverage."
  exit 1
fi

if ! rg -Fq "spotlight_pack_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame spotlight pack fixture marker coverage."
  exit 1
fi

if ! rg -Fq "breakout_plan_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame breakout plan fixture marker coverage."
  exit 1
fi

if ! rg -Fq "outreach_sprint_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame outreach sprint fixture marker coverage."
  exit 1
fi

if ! rg -Fq "proof_loop_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame proof loop fixture marker coverage."
  exit 1
fi

if ! rg -Fq "exceptional_loop_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame exceptional-loop fixture marker coverage."
  exit 1
fi

if ! rg -Fq "exceptional_loop_comment_markers.txt" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing founder fame exceptional-loop checklist comment fixture marker coverage."
  exit 1
fi

if ! rg -Fq "exceptional_loop_live_check_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run exceptional-loop live verification output coverage."
  exit 1
fi

if ! rg -Fq "war_room_live_check_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run war-room live verification output coverage."
  exit 1
fi

if ! rg -Fq "spotlight_pack_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run spotlight pack output coverage."
  exit 1
fi

if ! rg -Fq "breakout_plan_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run breakout plan output coverage."
  exit 1
fi

if ! rg -Fq "outreach_sprint_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run outreach sprint output coverage."
  exit 1
fi

if ! rg -Fq "proof_loop_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run proof loop output coverage."
  exit 1
fi

if ! rg -Fq "exceptional_loop_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing single-run exceptional-loop output coverage."
  exit 1
fi

if ! rg -Fq "pack_spotlight_pack_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack spotlight output coverage."
  exit 1
fi

if ! rg -Fq "pack_breakout_plan_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack breakout output coverage."
  exit 1
fi

if ! rg -Fq "pack_outreach_sprint_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack outreach sprint output coverage."
  exit 1
fi

if ! rg -Fq "pack_proof_loop_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack proof loop output coverage."
  exit 1
fi

if ! rg -Fq "pack_exceptional_loop_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack exceptional-loop output coverage."
  exit 1
fi

if ! rg -Fq "pack_exceptional_loop_live_check_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack exceptional-loop live verification output coverage."
  exit 1
fi

if ! rg -Fq "pack_war_room_live_check_path=" "scripts/check_founder_workflow.sh"; then
  echo "Founder workflow checks are missing weekly-pack war-room live verification output coverage."
  exit 1
fi

if ! zsh scripts/check_founder_workflow.sh; then
  echo "Founder workflow fixture checks failed."
  exit 1
fi

echo "Growth checks passed."
