#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Run launch-day checks and generate launch campaign artifacts.

Usage:
  zsh scripts/run_launch_day.sh [options]

Options:
  --week <YYYY-Www>            Launch week label (default: current ISO week)
  --command <name>             Command spotlight (default: Copy Win Card)
  --problem <text>             Before-state problem statement
  --outcome <text>             After-state outcome statement
  --metric <text>              Measurable result statement
  --workflow <a|b|c>           Pipe-separated 3-step workflow
  --cta <text>                 Call-to-action line
  --audience <text>            Audience label
  --asset <text>               Primary proof asset (default: Copy Win Card)
  --primary-channel <text>     Main launch channel label
  --backup-channel <text>      Backup launch channel label
  --primary-audience-region <text> Primary audience region (global/us/eu/apac)
  --backup-audience-region <text>  Backup audience region (global/us/eu/apac)
  --channel-roi-preferred-channel <text> Preferred lead route (primary/backup/balanced)
  --channel-roi-recommendation <text> ROI routing recommendation line
  --channel-mix-recommendation <text> Channel mix recommendation line
  --creator-signal-entries <value> Creator signal entries captured from comments
  --creator-signal-high-fit <value> High-fit creator signal count (fit score >=70)
  --creator-signal-warm-intros <value> Warm-intro creator signal count
  --creator-signal-collab-ready <value> Collab-ready creator signal count
  --creator-signal-top-segment <text> Top segment from creator signal scoring
  --creator-signal-top-handle <text> Highest-priority creator handle from signal scoring
  --creator-signal-enrichment-score <value> Creator signal enrichment score (0-100)
  --creator-signal-recommendation <text> Creator signal recommendation line
  --outreach-audience <text>   Creator audience segment label
  --target-list-out <path>     Creator target list output path
  --pack-out <path>            Campaign pack output path
  --founder-update-out <path>  Founder update post output path
  --founder-fame-out <path>    Founder fame pack output path
  --founder-press-out <path>   Founder press kit output path
  --founder-media-out <path>   Founder media blast output path
  --weekly-issue-out <path>    Weekly growth issue template output path
  --proof-out <path>           Social proof kit output path
  --reply-pack-out <path>      First-24-hour reply pack output path
  --monday-checkpoint-out <path> Monday publish checkpoint output path
  --outreach-out <path>        Creator outreach kit output path
  --distribution-out <path>    7-day distribution follow-up plan output path
  --viral-out <path>           Viral experiment board output path
  --proof-wall-out <path>      Social proof wall output path
  --founder-fame-ops-out <path> Founder fame ops brief output path
  --founder-fame-daily-mission <path> Optional in-app daily mission artifact path for action-queue mission bridge
  --founder-fame-action-queue-out <path> Founder fame action queue output path
  --founder-fame-interview-prep-out <path> Founder fame interview prep output path
  --founder-transcript <path>   Founder interview transcript source path (optional; defaults to generated interview prep artifact)
  --founder-fame-transcript-ingestion-out <path> Founder fame transcript ingestion output path
  --founder-fame-repurpose-out <path> Founder fame repurpose plan output path
  --founder-fame-uplift-tracker-out <path> Founder fame uplift tracker output path
  --founder-fame-weight-profile-out <path> Founder fame adaptive signal weight profile output path
  --founder-fame-momentum-out <path> Founder fame momentum brief output path
  --founder-fame-opportunity-radar-out <path> Founder fame ranked opportunity radar output path
  --founder-fame-execution-sprint-out <path> Founder fame day-by-day execution sprint output path
  --founder-fame-execution-scorecard-out <path> Founder fame execution readiness scorecard output path
  --founder-fame-risk-response-out <path> Founder fame risk response plan output path
  --founder-fame-escalation-queue-out <path> Founder fame escalation queue output path
  --founder-fame-command-center-out <path> Founder fame command center output path
  --founder-fame-next-move-handoff-out <path> Founder fame next-move handoff output path
  --founder-fame-next-move-draft-pack-out <path> Founder fame next-move draft pack output path
  --founder-fame-war-room-out <path> Founder fame war-room output path
  --founder-fame-war-room-check-out <path> Founder fame war-room verification output path
  --founder-fame-war-room-live-check-out <path> Founder fame war-room live verification output path
  --founder-fame-war-room-comment-out <path> Founder fame war-room checklist comment output path
  --post-founder-fame-war-room-comment Upsert founder fame war-room checklist comment
  --founder-fame-war-room-comment-issue <number> Optional checklist issue number override for war-room comment upsert
  --founder-fame-war-room-comment-repo <owner/repo> Optional repository slug override for war-room comment upsert
  --founder-fame-spotlight-out <path> Founder fame spotlight pack output path
  --founder-fame-breakout-out <path> Founder fame breakout plan output path
  --founder-fame-outreach-sprint-out <path> Founder fame outreach sprint output path
  --founder-fame-proof-loop-out <path> Founder fame proof loop output path
  --founder-fame-proof-loop-check-out <path> Founder fame proof loop verification output path
  --founder-fame-kpi-snapshot-out <path> Founder fame KPI snapshot output path
  --founder-fame-velocity-scoreboard-out <path> Founder fame velocity scoreboard output path
  --founder-fame-exceptional-loop-out <path> Founder fame exceptional loop output path
  --founder-fame-exceptional-loop-comment-out <path> Founder fame exceptional-loop checklist comment output path
  --founder-fame-exceptional-loop-live-check-out <path> Founder fame exceptional-loop live verification output path
  --post-founder-fame-exceptional-loop-comment Upsert founder fame exceptional-loop checklist comment
  --founder-fame-exceptional-loop-comment-issue <number> Optional checklist issue number override for exceptional-loop comment upsert
  --founder-fame-exceptional-loop-comment-repo <owner/repo> Optional repository slug override for exceptional-loop comment upsert
  --founder-fame-narrative-lab-out <path> Founder fame narrative lab output path
  --founder-first48h-post-pack-out <path> Founder first-48h post pack output path
  --founder-first48h-primary-char-limit <n> Founder first-48h primary short-variant char limit (default: 280)
  --founder-first48h-backup-char-limit <n> Founder first-48h backup short-variant char limit (default: 500)
  --founder-first48h-primary-tone <mode> Founder first-48h primary tone profile (default: x-punchy)
  --founder-first48h-backup-tone <mode> Founder first-48h backup tone profile (default: linkedin-context)
  --hook-out <path>            Winning hook library output path
  --credibility-out <path>     Credibility ledger output path
  --brief-out <path>           Launch brief output path
  --skip-tests                 Skip swift test
  -h, --help                   Show this help

Example:
  zsh scripts/run_launch_day.sh \
    --primary-channel "X / Threads" \
    --backup-channel "LinkedIn" \
    --metric "saved ~12 minutes per day"
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

week="$(date '+%Y-W%V')"
command_name="Copy Win Card"
problem_statement="manual weekly status updates"
outcome_statement="share-ready recap in under one minute"
metric_statement="saved ~10 minutes per day"
workflow_steps="Read Selected Text|Ask Anything|Copy Win Card"
cta_text="Try this flow and share your first Win Card."
audience_label="builders, writers, and researchers"
asset_name="Copy Win Card"
primary_channel="X / Threads"
backup_channel="LinkedIn"
primary_audience_region="global"
backup_audience_region="global"
channel_roi_preferred_channel="balanced"
channel_roi_recommendation=""
channel_mix_recommendation=""
creator_signal_entries="n/a"
creator_signal_high_fit="n/a"
creator_signal_warm_intros="n/a"
creator_signal_collab_ready="n/a"
creator_signal_top_segment="n/a"
creator_signal_top_handle="n/a"
creator_signal_enrichment_score="n/a"
creator_signal_recommendation="Capture creator signal comments in Monday checklist before Friday review."
outreach_audience="indie builders, technical creators, and operator communities"
target_list_out=""
pack_out=""
founder_update_out=""
founder_fame_out=""
founder_press_out=""
founder_media_out=""
weekly_issue_out=""
proof_out=""
reply_pack_out=""
monday_checkpoint_out=""
outreach_out=""
distribution_out=""
viral_board_out=""
social_proof_wall_out=""
founder_fame_ops_out=""
founder_fame_daily_mission_path=""
founder_fame_action_queue_out=""
founder_fame_interview_prep_out=""
founder_transcript_path=""
founder_fame_transcript_ingestion_out=""
founder_fame_repurpose_out=""
founder_fame_uplift_tracker_out=""
founder_fame_weight_profile_out=""
founder_fame_momentum_out=""
founder_fame_opportunity_radar_out=""
founder_fame_execution_sprint_out=""
founder_fame_execution_scorecard_out=""
founder_fame_risk_response_out=""
founder_fame_escalation_queue_out=""
founder_fame_command_center_out=""
founder_fame_next_move_handoff_out=""
founder_fame_next_move_draft_pack_out=""
founder_fame_war_room_out=""
founder_fame_war_room_check_out=""
founder_fame_war_room_live_check_out=""
founder_fame_war_room_comment_out=""
founder_fame_spotlight_out=""
founder_fame_breakout_out=""
founder_fame_outreach_sprint_out=""
founder_fame_proof_loop_out=""
founder_fame_proof_loop_check_out=""
founder_fame_kpi_snapshot_out=""
founder_fame_velocity_scoreboard_out=""
founder_fame_exceptional_loop_out=""
founder_fame_exceptional_loop_comment_out=""
founder_fame_exceptional_loop_live_check_out=""
founder_fame_narrative_lab_out=""
founder_first48h_post_pack_out=""
founder_first48h_primary_char_limit="280"
founder_first48h_backup_char_limit="500"
founder_first48h_primary_tone="x-punchy"
founder_first48h_backup_tone="linkedin-context"
post_founder_fame_war_room_comment=0
founder_fame_war_room_comment_issue=""
founder_fame_war_room_comment_repo=""
post_founder_fame_exceptional_loop_comment=0
founder_fame_exceptional_loop_comment_issue=""
founder_fame_exceptional_loop_comment_repo=""
winning_hook_library_out=""
credibility_ledger_out=""
brief_out=""
skip_tests=0

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
    --outreach-audience)
      outreach_audience="${2:-}"
      shift 2
      ;;
    --pack-out)
      pack_out="${2:-}"
      shift 2
      ;;
    --founder-update-out)
      founder_update_out="${2:-}"
      shift 2
      ;;
    --founder-fame-out)
      founder_fame_out="${2:-}"
      shift 2
      ;;
    --founder-press-out)
      founder_press_out="${2:-}"
      shift 2
      ;;
    --founder-media-out)
      founder_media_out="${2:-}"
      shift 2
      ;;
    --weekly-issue-out)
      weekly_issue_out="${2:-}"
      shift 2
      ;;
    --target-list-out)
      target_list_out="${2:-}"
      shift 2
      ;;
    --proof-out)
      proof_out="${2:-}"
      shift 2
      ;;
    --reply-pack-out)
      reply_pack_out="${2:-}"
      shift 2
      ;;
    --monday-checkpoint-out)
      monday_checkpoint_out="${2:-}"
      shift 2
      ;;
    --outreach-out)
      outreach_out="${2:-}"
      shift 2
      ;;
    --distribution-out)
      distribution_out="${2:-}"
      shift 2
      ;;
    --viral-out)
      viral_board_out="${2:-}"
      shift 2
      ;;
    --proof-wall-out)
      social_proof_wall_out="${2:-}"
      shift 2
      ;;
    --founder-fame-ops-out)
      founder_fame_ops_out="${2:-}"
      shift 2
      ;;
    --founder-fame-daily-mission)
      founder_fame_daily_mission_path="${2:-}"
      shift 2
      ;;
    --founder-fame-action-queue-out)
      founder_fame_action_queue_out="${2:-}"
      shift 2
      ;;
    --founder-fame-interview-prep-out)
      founder_fame_interview_prep_out="${2:-}"
      shift 2
      ;;
    --founder-transcript)
      founder_transcript_path="${2:-}"
      shift 2
      ;;
    --founder-fame-transcript-ingestion-out)
      founder_fame_transcript_ingestion_out="${2:-}"
      shift 2
      ;;
    --founder-fame-repurpose-out)
      founder_fame_repurpose_out="${2:-}"
      shift 2
      ;;
    --founder-fame-uplift-tracker-out)
      founder_fame_uplift_tracker_out="${2:-}"
      shift 2
      ;;
    --founder-fame-weight-profile-out)
      founder_fame_weight_profile_out="${2:-}"
      shift 2
      ;;
    --founder-fame-momentum-out)
      founder_fame_momentum_out="${2:-}"
      shift 2
      ;;
    --founder-fame-opportunity-radar-out)
      founder_fame_opportunity_radar_out="${2:-}"
      shift 2
      ;;
    --founder-fame-execution-sprint-out)
      founder_fame_execution_sprint_out="${2:-}"
      shift 2
      ;;
    --founder-fame-execution-scorecard-out)
      founder_fame_execution_scorecard_out="${2:-}"
      shift 2
      ;;
    --founder-fame-risk-response-out)
      founder_fame_risk_response_out="${2:-}"
      shift 2
      ;;
    --founder-fame-escalation-queue-out)
      founder_fame_escalation_queue_out="${2:-}"
      shift 2
      ;;
    --founder-fame-command-center-out)
      founder_fame_command_center_out="${2:-}"
      shift 2
      ;;
    --founder-fame-next-move-handoff-out)
      founder_fame_next_move_handoff_out="${2:-}"
      shift 2
      ;;
    --founder-fame-next-move-draft-pack-out)
      founder_fame_next_move_draft_pack_out="${2:-}"
      shift 2
      ;;
    --founder-fame-war-room-out)
      founder_fame_war_room_out="${2:-}"
      shift 2
      ;;
    --founder-fame-war-room-check-out)
      founder_fame_war_room_check_out="${2:-}"
      shift 2
      ;;
    --founder-fame-war-room-live-check-out)
      founder_fame_war_room_live_check_out="${2:-}"
      shift 2
      ;;
    --founder-fame-war-room-comment-out)
      founder_fame_war_room_comment_out="${2:-}"
      shift 2
      ;;
    --post-founder-fame-war-room-comment)
      post_founder_fame_war_room_comment=1
      shift
      ;;
    --founder-fame-war-room-comment-issue)
      founder_fame_war_room_comment_issue="${2:-}"
      shift 2
      ;;
    --founder-fame-war-room-comment-repo)
      founder_fame_war_room_comment_repo="${2:-}"
      shift 2
      ;;
    --founder-fame-spotlight-out)
      founder_fame_spotlight_out="${2:-}"
      shift 2
      ;;
    --founder-fame-breakout-out)
      founder_fame_breakout_out="${2:-}"
      shift 2
      ;;
    --founder-fame-outreach-sprint-out)
      founder_fame_outreach_sprint_out="${2:-}"
      shift 2
      ;;
    --founder-fame-proof-loop-out)
      founder_fame_proof_loop_out="${2:-}"
      shift 2
      ;;
    --founder-fame-proof-loop-check-out)
      founder_fame_proof_loop_check_out="${2:-}"
      shift 2
      ;;
    --founder-fame-kpi-snapshot-out)
      founder_fame_kpi_snapshot_out="${2:-}"
      shift 2
      ;;
    --founder-fame-velocity-scoreboard-out)
      founder_fame_velocity_scoreboard_out="${2:-}"
      shift 2
      ;;
    --founder-fame-exceptional-loop-out)
      founder_fame_exceptional_loop_out="${2:-}"
      shift 2
      ;;
    --founder-fame-exceptional-loop-comment-out)
      founder_fame_exceptional_loop_comment_out="${2:-}"
      shift 2
      ;;
    --founder-fame-exceptional-loop-live-check-out)
      founder_fame_exceptional_loop_live_check_out="${2:-}"
      shift 2
      ;;
    --post-founder-fame-exceptional-loop-comment)
      post_founder_fame_exceptional_loop_comment=1
      shift
      ;;
    --founder-fame-exceptional-loop-comment-issue)
      founder_fame_exceptional_loop_comment_issue="${2:-}"
      shift 2
      ;;
    --founder-fame-exceptional-loop-comment-repo)
      founder_fame_exceptional_loop_comment_repo="${2:-}"
      shift 2
      ;;
    --founder-fame-narrative-lab-out)
      founder_fame_narrative_lab_out="${2:-}"
      shift 2
      ;;
    --founder-first48h-post-pack-out)
      founder_first48h_post_pack_out="${2:-}"
      shift 2
      ;;
    --founder-first48h-primary-char-limit)
      founder_first48h_primary_char_limit="${2:-}"
      shift 2
      ;;
    --founder-first48h-backup-char-limit)
      founder_first48h_backup_char_limit="${2:-}"
      shift 2
      ;;
    --founder-first48h-primary-tone)
      founder_first48h_primary_tone="${2:-}"
      shift 2
      ;;
    --founder-first48h-backup-tone)
      founder_first48h_backup_tone="${2:-}"
      shift 2
      ;;
    --hook-out)
      winning_hook_library_out="${2:-}"
      shift 2
      ;;
    --credibility-out)
      credibility_ledger_out="${2:-}"
      shift 2
      ;;
    --brief-out)
      brief_out="${2:-}"
      shift 2
      ;;
    --skip-tests)
      skip_tests=1
      shift
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

if [[ -n "$founder_transcript_path" && ! -f "$founder_transcript_path" ]]; then
  echo "Founder transcript file not found: $founder_transcript_path" >&2
  exit 1
fi

if [[ -n "$founder_fame_daily_mission_path" && ! -f "$founder_fame_daily_mission_path" ]]; then
  echo "Founder fame daily mission file not found: $founder_fame_daily_mission_path" >&2
  exit 1
fi

timestamp="$(date '+%Y%m%d-%H%M%S')"
if [[ -z "$pack_out" ]]; then
  pack_out="docs/campaigns/${week}-launch.md"
  if [[ -e "$pack_out" ]]; then
    pack_out="docs/campaigns/${week}-launch-${timestamp}.md"
  fi
fi

if [[ -z "$founder_update_out" ]]; then
  founder_update_out="docs/campaigns/${week}-founder-update.md"
  if [[ -e "$founder_update_out" ]]; then
    founder_update_out="docs/campaigns/${week}-founder-update-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_out" ]]; then
  founder_fame_out="docs/campaigns/${week}-founder-fame-pack.md"
  if [[ -e "$founder_fame_out" ]]; then
    founder_fame_out="docs/campaigns/${week}-founder-fame-pack-${timestamp}.md"
  fi
fi

if [[ -z "$founder_press_out" ]]; then
  founder_press_out="docs/campaigns/${week}-founder-press-kit.md"
  if [[ -e "$founder_press_out" ]]; then
    founder_press_out="docs/campaigns/${week}-founder-press-kit-${timestamp}.md"
  fi
fi

if [[ -z "$founder_media_out" ]]; then
  founder_media_out="docs/campaigns/${week}-founder-media-blast.md"
  if [[ -e "$founder_media_out" ]]; then
    founder_media_out="docs/campaigns/${week}-founder-media-blast-${timestamp}.md"
  fi
fi

if [[ -z "$weekly_issue_out" ]]; then
  weekly_issue_out="docs/campaigns/${week}-weekly-growth-issue.md"
  if [[ -e "$weekly_issue_out" ]]; then
    weekly_issue_out="docs/campaigns/${week}-weekly-growth-issue-${timestamp}.md"
  fi
fi

if [[ -z "$brief_out" ]]; then
  brief_out="docs/campaigns/${week}-launch-brief.md"
  if [[ -e "$brief_out" ]]; then
    brief_out="docs/campaigns/${week}-launch-brief-${timestamp}.md"
  fi
fi

if [[ -z "$proof_out" ]]; then
  proof_out="docs/campaigns/${week}-social-proof.md"
  if [[ -e "$proof_out" ]]; then
    proof_out="docs/campaigns/${week}-social-proof-${timestamp}.md"
  fi
fi

if [[ -z "$reply_pack_out" ]]; then
  reply_pack_out="docs/campaigns/${week}-reply-pack.md"
  if [[ -e "$reply_pack_out" ]]; then
    reply_pack_out="docs/campaigns/${week}-reply-pack-${timestamp}.md"
  fi
fi

if [[ -z "$monday_checkpoint_out" ]]; then
  monday_checkpoint_out="docs/campaigns/${week}-monday-checkpoint.md"
  if [[ -e "$monday_checkpoint_out" ]]; then
    monday_checkpoint_out="docs/campaigns/${week}-monday-checkpoint-${timestamp}.md"
  fi
fi

if [[ -z "$outreach_out" ]]; then
  outreach_out="docs/campaigns/${week}-creator-outreach.md"
  if [[ -e "$outreach_out" ]]; then
    outreach_out="docs/campaigns/${week}-creator-outreach-${timestamp}.md"
  fi
fi

if [[ -z "$target_list_out" ]]; then
  target_list_out="docs/campaigns/${week}-creator-target-list.md"
  if [[ -e "$target_list_out" ]]; then
    target_list_out="docs/campaigns/${week}-creator-target-list-${timestamp}.md"
  fi
fi

if [[ -z "$distribution_out" ]]; then
  distribution_out="docs/campaigns/${week}-distribution-plan.md"
  if [[ -e "$distribution_out" ]]; then
    distribution_out="docs/campaigns/${week}-distribution-plan-${timestamp}.md"
  fi
fi

if [[ -z "$viral_board_out" ]]; then
  viral_board_out="docs/campaigns/${week}-viral-experiment-board.md"
  if [[ -e "$viral_board_out" ]]; then
    viral_board_out="docs/campaigns/${week}-viral-experiment-board-${timestamp}.md"
  fi
fi

if [[ -z "$social_proof_wall_out" ]]; then
  social_proof_wall_out="docs/campaigns/${week}-social-proof-wall.md"
  if [[ -e "$social_proof_wall_out" ]]; then
    social_proof_wall_out="docs/campaigns/${week}-social-proof-wall-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_ops_out" ]]; then
  founder_fame_ops_out="docs/campaigns/${week}-founder-fame-ops-brief.md"
  if [[ -e "$founder_fame_ops_out" ]]; then
    founder_fame_ops_out="docs/campaigns/${week}-founder-fame-ops-brief-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_action_queue_out" ]]; then
  founder_fame_action_queue_out="docs/campaigns/${week}-founder-fame-action-queue.md"
  if [[ -e "$founder_fame_action_queue_out" ]]; then
    founder_fame_action_queue_out="docs/campaigns/${week}-founder-fame-action-queue-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_interview_prep_out" ]]; then
  founder_fame_interview_prep_out="docs/campaigns/${week}-founder-fame-interview-prep.md"
  if [[ -e "$founder_fame_interview_prep_out" ]]; then
    founder_fame_interview_prep_out="docs/campaigns/${week}-founder-fame-interview-prep-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_transcript_ingestion_out" ]]; then
  founder_fame_transcript_ingestion_out="docs/campaigns/${week}-founder-fame-transcript-ingestion.md"
  if [[ -e "$founder_fame_transcript_ingestion_out" ]]; then
    founder_fame_transcript_ingestion_out="docs/campaigns/${week}-founder-fame-transcript-ingestion-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_repurpose_out" ]]; then
  founder_fame_repurpose_out="docs/campaigns/${week}-founder-fame-repurpose-plan.md"
  if [[ -e "$founder_fame_repurpose_out" ]]; then
    founder_fame_repurpose_out="docs/campaigns/${week}-founder-fame-repurpose-plan-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_momentum_out" ]]; then
  founder_fame_momentum_out="docs/campaigns/${week}-founder-fame-momentum-brief.md"
  if [[ -e "$founder_fame_momentum_out" ]]; then
    founder_fame_momentum_out="docs/campaigns/${week}-founder-fame-momentum-brief-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_weight_profile_out" ]]; then
  founder_fame_weight_profile_out="docs/campaigns/${week}-founder-fame-weight-profile.md"
  if [[ -e "$founder_fame_weight_profile_out" ]]; then
    founder_fame_weight_profile_out="docs/campaigns/${week}-founder-fame-weight-profile-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_uplift_tracker_out" ]]; then
  founder_fame_uplift_tracker_out="docs/campaigns/${week}-founder-fame-uplift-tracker.md"
  if [[ -e "$founder_fame_uplift_tracker_out" ]]; then
    founder_fame_uplift_tracker_out="docs/campaigns/${week}-founder-fame-uplift-tracker-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_opportunity_radar_out" ]]; then
  founder_fame_opportunity_radar_out="docs/campaigns/${week}-founder-fame-opportunity-radar.md"
  if [[ -e "$founder_fame_opportunity_radar_out" ]]; then
    founder_fame_opportunity_radar_out="docs/campaigns/${week}-founder-fame-opportunity-radar-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_execution_sprint_out" ]]; then
  founder_fame_execution_sprint_out="docs/campaigns/${week}-founder-fame-execution-sprint.md"
  if [[ -e "$founder_fame_execution_sprint_out" ]]; then
    founder_fame_execution_sprint_out="docs/campaigns/${week}-founder-fame-execution-sprint-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_execution_scorecard_out" ]]; then
  founder_fame_execution_scorecard_out="docs/campaigns/${week}-founder-fame-execution-scorecard.md"
  if [[ -e "$founder_fame_execution_scorecard_out" ]]; then
    founder_fame_execution_scorecard_out="docs/campaigns/${week}-founder-fame-execution-scorecard-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_risk_response_out" ]]; then
  founder_fame_risk_response_out="docs/campaigns/${week}-founder-fame-risk-response-plan.md"
  if [[ -e "$founder_fame_risk_response_out" ]]; then
    founder_fame_risk_response_out="docs/campaigns/${week}-founder-fame-risk-response-plan-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_escalation_queue_out" ]]; then
  founder_fame_escalation_queue_out="docs/campaigns/${week}-founder-fame-escalation-queue.md"
  if [[ -e "$founder_fame_escalation_queue_out" ]]; then
    founder_fame_escalation_queue_out="docs/campaigns/${week}-founder-fame-escalation-queue-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_command_center_out" ]]; then
  founder_fame_command_center_out="docs/campaigns/${week}-founder-fame-command-center.md"
  if [[ -e "$founder_fame_command_center_out" ]]; then
    founder_fame_command_center_out="docs/campaigns/${week}-founder-fame-command-center-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_next_move_handoff_out" ]]; then
  founder_fame_next_move_handoff_out="docs/campaigns/${week}-founder-fame-next-move-handoff.md"
  if [[ -e "$founder_fame_next_move_handoff_out" ]]; then
    founder_fame_next_move_handoff_out="docs/campaigns/${week}-founder-fame-next-move-handoff-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_next_move_draft_pack_out" ]]; then
  founder_fame_next_move_draft_pack_out="docs/campaigns/${week}-founder-fame-next-move-draft-pack.md"
  if [[ -e "$founder_fame_next_move_draft_pack_out" ]]; then
    founder_fame_next_move_draft_pack_out="docs/campaigns/${week}-founder-fame-next-move-draft-pack-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_war_room_out" ]]; then
  founder_fame_war_room_out="docs/campaigns/${week}-founder-fame-war-room.md"
  if [[ -e "$founder_fame_war_room_out" ]]; then
    founder_fame_war_room_out="docs/campaigns/${week}-founder-fame-war-room-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_war_room_check_out" ]]; then
  founder_fame_war_room_check_out="docs/campaigns/${week}-founder-fame-war-room-check.md"
  if [[ -e "$founder_fame_war_room_check_out" ]]; then
    founder_fame_war_room_check_out="docs/campaigns/${week}-founder-fame-war-room-check-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_war_room_live_check_out" ]]; then
  founder_fame_war_room_live_check_out="docs/campaigns/${week}-founder-fame-war-room-live-check.md"
  if [[ -e "$founder_fame_war_room_live_check_out" ]]; then
    founder_fame_war_room_live_check_out="docs/campaigns/${week}-founder-fame-war-room-live-check-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_war_room_comment_out" ]]; then
  founder_fame_war_room_comment_out="docs/campaigns/${week}-founder-fame-war-room-comment.md"
  if [[ -e "$founder_fame_war_room_comment_out" ]]; then
    founder_fame_war_room_comment_out="docs/campaigns/${week}-founder-fame-war-room-comment-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_spotlight_out" ]]; then
  founder_fame_spotlight_out="docs/campaigns/${week}-founder-fame-spotlight-pack.md"
  if [[ -e "$founder_fame_spotlight_out" ]]; then
    founder_fame_spotlight_out="docs/campaigns/${week}-founder-fame-spotlight-pack-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_breakout_out" ]]; then
  founder_fame_breakout_out="docs/campaigns/${week}-founder-fame-breakout-plan.md"
  if [[ -e "$founder_fame_breakout_out" ]]; then
    founder_fame_breakout_out="docs/campaigns/${week}-founder-fame-breakout-plan-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_outreach_sprint_out" ]]; then
  founder_fame_outreach_sprint_out="docs/campaigns/${week}-founder-fame-outreach-sprint.md"
  if [[ -e "$founder_fame_outreach_sprint_out" ]]; then
    founder_fame_outreach_sprint_out="docs/campaigns/${week}-founder-fame-outreach-sprint-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_proof_loop_out" ]]; then
  founder_fame_proof_loop_out="docs/campaigns/${week}-founder-fame-proof-loop.md"
  if [[ -e "$founder_fame_proof_loop_out" ]]; then
    founder_fame_proof_loop_out="docs/campaigns/${week}-founder-fame-proof-loop-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_proof_loop_check_out" ]]; then
  founder_fame_proof_loop_check_out="docs/campaigns/${week}-founder-fame-proof-loop-check.md"
  if [[ -e "$founder_fame_proof_loop_check_out" ]]; then
    founder_fame_proof_loop_check_out="docs/campaigns/${week}-founder-fame-proof-loop-check-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_kpi_snapshot_out" ]]; then
  founder_fame_kpi_snapshot_out="docs/campaigns/${week}-founder-fame-kpi-snapshot.md"
  if [[ -e "$founder_fame_kpi_snapshot_out" ]]; then
    founder_fame_kpi_snapshot_out="docs/campaigns/${week}-founder-fame-kpi-snapshot-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_velocity_scoreboard_out" ]]; then
  founder_fame_velocity_scoreboard_out="docs/campaigns/${week}-founder-fame-velocity-scoreboard.md"
  if [[ -e "$founder_fame_velocity_scoreboard_out" ]]; then
    founder_fame_velocity_scoreboard_out="docs/campaigns/${week}-founder-fame-velocity-scoreboard-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_exceptional_loop_out" ]]; then
  founder_fame_exceptional_loop_out="docs/campaigns/${week}-founder-fame-exceptional-loop.md"
  if [[ -e "$founder_fame_exceptional_loop_out" ]]; then
    founder_fame_exceptional_loop_out="docs/campaigns/${week}-founder-fame-exceptional-loop-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_exceptional_loop_comment_out" ]]; then
  founder_fame_exceptional_loop_comment_out="docs/campaigns/${week}-founder-fame-exceptional-loop-comment.md"
  if [[ -e "$founder_fame_exceptional_loop_comment_out" ]]; then
    founder_fame_exceptional_loop_comment_out="docs/campaigns/${week}-founder-fame-exceptional-loop-comment-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_exceptional_loop_live_check_out" ]]; then
  founder_fame_exceptional_loop_live_check_out="docs/campaigns/${week}-founder-fame-exceptional-loop-live-check.md"
  if [[ -e "$founder_fame_exceptional_loop_live_check_out" ]]; then
    founder_fame_exceptional_loop_live_check_out="docs/campaigns/${week}-founder-fame-exceptional-loop-live-check-${timestamp}.md"
  fi
fi

if [[ -z "$founder_fame_narrative_lab_out" ]]; then
  founder_fame_narrative_lab_out="docs/campaigns/${week}-founder-fame-narrative-lab.md"
  if [[ -e "$founder_fame_narrative_lab_out" ]]; then
    founder_fame_narrative_lab_out="docs/campaigns/${week}-founder-fame-narrative-lab-${timestamp}.md"
  fi
fi
if [[ -z "$founder_first48h_post_pack_out" ]]; then
  founder_first48h_post_pack_out="docs/campaigns/${week}-founder-first48h-post-pack.md"
  if [[ -e "$founder_first48h_post_pack_out" ]]; then
    founder_first48h_post_pack_out="docs/campaigns/${week}-founder-first48h-post-pack-${timestamp}.md"
  fi
fi

if [[ -z "$winning_hook_library_out" ]]; then
  winning_hook_library_out="docs/campaigns/${week}-winning-hook-library.md"
  if [[ -e "$winning_hook_library_out" ]]; then
    winning_hook_library_out="docs/campaigns/${week}-winning-hook-library-${timestamp}.md"
  fi
fi

if [[ -z "$credibility_ledger_out" ]]; then
  credibility_ledger_out="docs/campaigns/${week}-credibility-ledger.md"
  if [[ -e "$credibility_ledger_out" ]]; then
    credibility_ledger_out="docs/campaigns/${week}-credibility-ledger-${timestamp}.md"
  fi
fi

run_step() {
  local label="$1"
  shift
  echo "==> $label"
  "$@"
}

if (( skip_tests == 0 )); then
  run_step "swift test" swift test
else
  echo "==> Skipping swift test (--skip-tests)"
fi

run_step "zsh scripts/check_docs.sh" zsh scripts/check_docs.sh
run_step "zsh scripts/check_growth.sh" zsh scripts/check_growth.sh
run_step "zsh scripts/check_fast.sh" zsh scripts/check_fast.sh

run_step "Generate launch campaign pack" zsh scripts/generate_campaign_pack.sh \
  --week "$week" \
  --command "$command_name" \
  --problem "$problem_statement" \
  --outcome "$outcome_statement" \
  --metric "$metric_statement" \
  --workflow "$workflow_steps" \
  --cta "$cta_text" \
  --audience "$audience_label" \
  --asset "$asset_name" \
  --out "$pack_out"

run_step "Generate weekly growth issue template" zsh scripts/generate_weekly_growth_issue.sh \
  --week "$week" \
  --campaign "$pack_out" \
  --primary "$primary_channel" \
  --backup "$backup_channel" \
  --metric "$metric_statement" \
  --out "$weekly_issue_out"

founder_fixture_path="scripts/fixtures/founder/sample_inputs.env"
founder_product_name="Fluid Reader"
founder_cta_text="If you're building, reply with your KPI bottleneck and I'll share the exact command flow."
founder_target_mrr="50000"
founder_target_margin="55"
founder_target_cac="150"
founder_target_ltv_cac="3.5"
founder_target_new_customers="95"
founder_previous_mrr="42000"
founder_previous_delivery_cost="19000"
founder_previous_acquisition_spend="12000"
founder_previous_new_customers="80"
founder_previous_monthly_contribution="75"
founder_previous_lifetime_months="18"
founder_previous_fixed_cost="10000"
founder_previous_price="50"
founder_previous_variable_cost="30"
founder_current_mrr="46000"
founder_current_delivery_cost="20500"
founder_current_acquisition_spend="13000"
founder_current_new_customers="85"
founder_current_monthly_contribution="80"
founder_current_lifetime_months="18"
founder_current_fixed_cost="10500"
founder_current_price="52"
founder_current_variable_cost="31"

if [[ -f "$founder_fixture_path" ]]; then
  source "$founder_fixture_path"
  founder_product_name="${PRODUCT_NAME:-$founder_product_name}"
  founder_cta_text="${CTA_TEXT:-$founder_cta_text}"
  founder_target_mrr="${TARGET_MRR:-$founder_target_mrr}"
  founder_target_margin="${TARGET_MARGIN:-$founder_target_margin}"
  founder_target_cac="${TARGET_CAC:-$founder_target_cac}"
  founder_target_ltv_cac="${TARGET_LTV_CAC:-$founder_target_ltv_cac}"
  founder_target_new_customers="${TARGET_NEW_CUSTOMERS:-$founder_target_new_customers}"
  founder_previous_mrr="${PREVIOUS_MRR:-$founder_previous_mrr}"
  founder_previous_delivery_cost="${PREVIOUS_DELIVERY_COST:-$founder_previous_delivery_cost}"
  founder_previous_acquisition_spend="${PREVIOUS_ACQUISITION_SPEND:-$founder_previous_acquisition_spend}"
  founder_previous_new_customers="${PREVIOUS_NEW_CUSTOMERS:-$founder_previous_new_customers}"
  founder_previous_monthly_contribution="${PREVIOUS_MONTHLY_CONTRIBUTION:-$founder_previous_monthly_contribution}"
  founder_previous_lifetime_months="${PREVIOUS_LIFETIME_MONTHS:-$founder_previous_lifetime_months}"
  founder_previous_fixed_cost="${PREVIOUS_FIXED_COST:-$founder_previous_fixed_cost}"
  founder_previous_price="${PREVIOUS_PRICE:-$founder_previous_price}"
  founder_previous_variable_cost="${PREVIOUS_VARIABLE_COST:-$founder_previous_variable_cost}"
  founder_current_mrr="${CURRENT_MRR:-$founder_current_mrr}"
  founder_current_delivery_cost="${CURRENT_DELIVERY_COST:-$founder_current_delivery_cost}"
  founder_current_acquisition_spend="${CURRENT_ACQUISITION_SPEND:-$founder_current_acquisition_spend}"
  founder_current_new_customers="${CURRENT_NEW_CUSTOMERS:-$founder_current_new_customers}"
  founder_current_monthly_contribution="${CURRENT_MONTHLY_CONTRIBUTION:-$founder_current_monthly_contribution}"
  founder_current_lifetime_months="${CURRENT_LIFETIME_MONTHS:-$founder_current_lifetime_months}"
  founder_current_fixed_cost="${CURRENT_FIXED_COST:-$founder_current_fixed_cost}"
  founder_current_price="${CURRENT_PRICE:-$founder_current_price}"
  founder_current_variable_cost="${CURRENT_VARIABLE_COST:-$founder_current_variable_cost}"
fi

founder_current_margin="$(awk -v mrr="$founder_current_mrr" -v cost="$founder_current_delivery_cost" 'BEGIN {
  if ((mrr + 0) == 0) {
    print "n/a"
  } else {
    printf "%.6f", (((mrr + 0) - (cost + 0)) / (mrr + 0)) * 100
  }
}')"

founder_current_cac="$(awk -v spend="$founder_current_acquisition_spend" -v customers="$founder_current_new_customers" 'BEGIN {
  if ((customers + 0) == 0) {
    print "n/a"
  } else {
    printf "%.6f", (spend + 0) / (customers + 0)
  }
}')"

founder_current_ltv_cac="$(awk -v contrib="$founder_current_monthly_contribution" -v lifetime="$founder_current_lifetime_months" -v cac="$founder_current_cac" 'BEGIN {
  if (cac == "n/a" || (cac + 0) == 0) {
    print "n/a"
  } else {
    ltv = (contrib + 0) * (lifetime + 0)
    printf "%.6f", ltv / (cac + 0)
  }
}')"

founder_output_dir=".build/founder/launch-${week}"
mkdir -p "$founder_output_dir"
founder_previous_review_path="$founder_output_dir/founder-weekly-review-baseline-${week}.md"
founder_current_review_path="$founder_output_dir/founder-weekly-review-${week}.md"
founder_delta_path="$founder_output_dir/founder-weekly-delta-${week}.md"
founder_scoreboard_path="$founder_output_dir/founder-scoreboard-${week}.md"

run_step "Generate founder baseline weekly review" zsh scripts/generate_founder_weekly_review.sh \
  --week "baseline-${week}" \
  --mrr "$founder_previous_mrr" \
  --delivery-cost "$founder_previous_delivery_cost" \
  --acquisition-spend "$founder_previous_acquisition_spend" \
  --new-customers "$founder_previous_new_customers" \
  --monthly-contribution "$founder_previous_monthly_contribution" \
  --lifetime-months "$founder_previous_lifetime_months" \
  --fixed-cost "$founder_previous_fixed_cost" \
  --price "$founder_previous_price" \
  --variable-cost "$founder_previous_variable_cost" \
  --out "$founder_previous_review_path"

run_step "Generate founder current weekly review" zsh scripts/generate_founder_weekly_review.sh \
  --week "$week" \
  --mrr "$founder_current_mrr" \
  --delivery-cost "$founder_current_delivery_cost" \
  --acquisition-spend "$founder_current_acquisition_spend" \
  --new-customers "$founder_current_new_customers" \
  --monthly-contribution "$founder_current_monthly_contribution" \
  --lifetime-months "$founder_current_lifetime_months" \
  --fixed-cost "$founder_current_fixed_cost" \
  --price "$founder_current_price" \
  --variable-cost "$founder_current_variable_cost" \
  --out "$founder_current_review_path"

run_step "Generate founder weekly delta" zsh scripts/generate_founder_weekly_delta.sh \
  --previous "$founder_previous_review_path" \
  --current "$founder_current_review_path" \
  --label-prev "baseline" \
  --label-current "$week" \
  --out "$founder_delta_path"

run_step "Generate founder scoreboard" zsh scripts/generate_founder_scoreboard.sh \
  --week "$week" \
  --target-mrr "$founder_target_mrr" \
  --target-margin "$founder_target_margin" \
  --target-cac "$founder_target_cac" \
  --target-ltv-cac "$founder_target_ltv_cac" \
  --target-new-customers "$founder_target_new_customers" \
  --actual-mrr "$founder_current_mrr" \
  --actual-margin "$founder_current_margin" \
  --actual-cac "$founder_current_cac" \
  --actual-ltv-cac "$founder_current_ltv_cac" \
  --actual-new-customers "$founder_current_new_customers" \
  --out "$founder_scoreboard_path"

run_step "Generate founder update post pack" zsh scripts/generate_founder_update_post.sh \
  --scoreboard "$founder_scoreboard_path" \
  --delta "$founder_delta_path" \
  --week "$week" \
  --product "$founder_product_name" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_update_out"

run_step "Generate founder fame pack" zsh scripts/generate_founder_fame_pack.sh \
  --scoreboard "$founder_scoreboard_path" \
  --delta "$founder_delta_path" \
  --week "$week" \
  --product "$founder_product_name" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_fame_out"

run_step "Generate founder press kit" zsh scripts/generate_founder_press_kit.sh \
  --fame-pack "$founder_fame_out" \
  --week "$week" \
  --product "$founder_product_name" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_press_out"

run_step "Generate founder media blast" zsh scripts/generate_founder_media_blast.sh \
  --fame-pack "$founder_fame_out" \
  --press-kit "$founder_press_out" \
  --update-post "$founder_update_out" \
  --week "$week" \
  --product "$founder_product_name" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_media_out"

run_step "Generate social proof kit" zsh scripts/generate_social_proof_kit.sh \
  --week "$week" \
  --command "$command_name" \
  --problem "$problem_statement" \
  --outcome "$outcome_statement" \
  --metric "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$cta_text" \
  --out "$proof_out"

run_step "Generate first-24-hour reply pack" zsh scripts/generate_first24h_reply_pack.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --command "$command_name" \
  --out "$reply_pack_out"

run_step "Generate Monday publish checkpoint" zsh scripts/generate_monday_publish_checkpoint.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --primary-audience-region "$primary_audience_region" \
  --backup-audience-region "$backup_audience_region" \
  --primary-channel-roi-score "n/a" \
  --backup-channel-roi-score "n/a" \
  --channel-roi-preferred-channel "$channel_roi_preferred_channel" \
  --channel-roi-recommendation "${channel_roi_recommendation:-Collect first 24-hour reply and outreach outcomes before forcing a single-channel route.}" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --out "$monday_checkpoint_out"

run_step "Generate creator outreach kit" zsh scripts/generate_creator_outreach_kit.sh \
  --week "$week" \
  --command "$command_name" \
  --problem "$problem_statement" \
  --outcome "$outcome_statement" \
  --metric "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --audience "$outreach_audience" \
  --asset "$asset_name" \
  --cta "$cta_text" \
  --out "$outreach_out"

run_step "Generate creator target list" zsh scripts/generate_creator_target_list.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --command "$command_name" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --primary-channel-roi-score "n/a" \
  --backup-channel-roi-score "n/a" \
  --channel-roi-preferred-channel "$channel_roi_preferred_channel" \
  --channel-mix-recommendation "${channel_mix_recommendation:-Keep channel mix balanced until distribution execution score is logged.}" \
  --outreach-sent "0" \
  --outreach-replies "0" \
  --outreach-collabs "0" \
  --outreach-cross-posts "0" \
  --outreach-reply-rate "n/a" \
  --outreach-collab-rate "n/a" \
  --outreach-cross-post-rate "n/a" \
  --outreach-replies-delta "n/a" \
  --outreach-collabs-delta "n/a" \
  --creator-signal-entries "$creator_signal_entries" \
  --creator-signal-high-fit "$creator_signal_high_fit" \
  --creator-signal-warm-intros "$creator_signal_warm_intros" \
  --creator-signal-collab-ready "$creator_signal_collab_ready" \
  --creator-signal-top-segment "$creator_signal_top_segment" \
  --creator-signal-top-handle "$creator_signal_top_handle" \
  --creator-signal-enrichment-score "$creator_signal_enrichment_score" \
  --creator-signal-recommendation "$creator_signal_recommendation" \
  --cta "$cta_text" \
  --out "$target_list_out"

run_step "Generate 7-day distribution follow-up plan" zsh scripts/generate_distribution_followup_plan.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --command "$command_name" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --primary-audience-region "$primary_audience_region" \
  --backup-audience-region "$backup_audience_region" \
  --primary-channel-roi-score "n/a" \
  --backup-channel-roi-score "n/a" \
  --channel-roi-preferred-channel "$channel_roi_preferred_channel" \
  --channel-roi-recommendation "${channel_roi_recommendation:-Collect first 24-hour reply and outreach outcomes before forcing a single-channel route.}" \
  --channel-mix-recommendation "${channel_mix_recommendation:-Keep channel mix balanced until distribution execution score is logged.}" \
  --reply-goal "12" \
  --outreach-goal "5" \
  --out "$distribution_out"

run_step "Generate viral experiment board" zsh scripts/generate_viral_experiment_board.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --creator-signal-enrichment-score "$creator_signal_enrichment_score" \
  --channel-roi-preferred-channel "$channel_roi_preferred_channel" \
  --channel-mix-recommendation "${channel_mix_recommendation:-Keep channel mix balanced until distribution execution score is logged.}" \
  --out "$viral_board_out"

run_step "Generate social proof wall" zsh scripts/generate_social_proof_wall.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --win-card "0" \
  --win-card-delta "n/a" \
  --replies-sent "0" \
  --replies-sent-delta "n/a" \
  --outreach-replies "0" \
  --outreach-collabs "0" \
  --outreach-cross-posts "0" \
  --primary-top-variant "A" \
  --backup-top-variant "B" \
  --creator-signal-top-handle "$creator_signal_top_handle" \
  --creator-signal-top-segment "$creator_signal_top_segment" \
  --channel-mix-recommendation "${channel_mix_recommendation:-Keep channel mix balanced until distribution execution score is logged.}" \
  --variant-recommendation "Use first launch replies to decide next-week proof wall highlights." \
  --outreach-recommendation "${creator_signal_recommendation:-Capture creator signal comments in Monday checklist before Friday review.}" \
  --out "$social_proof_wall_out"

run_step "Generate founder fame ops brief" zsh scripts/generate_founder_fame_ops_brief.sh \
  --week "$week" \
  --distribution-plan "$distribution_out" \
  --social-proof-wall "$social_proof_wall_out" \
  --fame-pack "$founder_fame_out" \
  --media-blast "$founder_media_out" \
  --out "$founder_fame_ops_out"

founder_fame_action_queue_args=(
  --week "$week"
  --ops-brief "$founder_fame_ops_out"
  --out "$founder_fame_action_queue_out"
)
if [[ -n "$founder_fame_daily_mission_path" ]]; then
  founder_fame_action_queue_args+=(--daily-mission "$founder_fame_daily_mission_path")
  founder_fame_action_queue_args+=(--require-fresh-daily-mission)
fi
run_step "Generate founder fame action queue" zsh scripts/generate_founder_fame_action_queue.sh "${founder_fame_action_queue_args[@]}"

run_step "Generate founder fame interview prep" zsh scripts/generate_founder_fame_interview_prep.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --ops-brief "$founder_fame_ops_out" \
  --action-queue "$founder_fame_action_queue_out" \
  --press-kit "$founder_press_out" \
  --media-blast "$founder_media_out" \
  --out "$founder_fame_interview_prep_out"

founder_transcript_source_path="$founder_fame_interview_prep_out"
if [[ -n "$founder_transcript_path" ]]; then
  founder_transcript_source_path="$founder_transcript_path"
fi

founder_fame_daily_mission_source="$founder_fame_daily_mission_path"
if [[ -z "$founder_fame_daily_mission_source" ]]; then
  founder_fame_daily_mission_source="(optional input not provided; action queue uses ops-brief only)"
fi
founder_fame_daily_mission_freshness_line="$(rg -m1 '^- Mission freshness: ' "$founder_fame_action_queue_out" || true)"
founder_fame_daily_mission_freshness="${founder_fame_daily_mission_freshness_line#"- Mission freshness: "}"
if [[ -z "$founder_fame_daily_mission_freshness" ]]; then
  founder_fame_daily_mission_freshness="n/a (missing mission freshness line in action queue artifact)"
fi

run_step "Generate founder fame transcript ingestion" zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --transcript "$founder_transcript_source_path" \
  --interview-prep "$founder_fame_interview_prep_out" \
  --media-blast "$founder_media_out" \
  --out "$founder_fame_transcript_ingestion_out"

run_step "Generate founder fame repurpose plan" zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --interview-prep "$founder_fame_interview_prep_out" \
  --transcript-ingestion "$founder_fame_transcript_ingestion_out" \
  --media-blast "$founder_media_out" \
  --action-queue "$founder_fame_action_queue_out" \
  --out "$founder_fame_repurpose_out"

run_step "Generate winning hook library" zsh scripts/generate_winning_hook_library.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --channel-roi-preferred-channel "$channel_roi_preferred_channel" \
  --channel-roi-recommendation "${channel_roi_recommendation:-Collect first 24-hour reply and outreach outcomes before forcing a single-channel route.}" \
  --channel-mix-recommendation "${channel_mix_recommendation:-Keep channel mix balanced until distribution execution score is logged.}" \
  --variant-recommendation "Use first launch replies to decide next-week winning hook default." \
  --outreach-recommendation "${creator_signal_recommendation:-Capture creator signal comments in Monday checklist before Friday review.}" \
  --creator-signal-enrichment-score "$creator_signal_enrichment_score" \
  --out "$winning_hook_library_out"

run_step "Generate credibility ledger" zsh scripts/generate_credibility_ledger.sh \
  --week "$week" \
  --metric-focus "$metric_statement" \
  --strongest-metric-label "Launch outcome metric" \
  --strongest-metric-value "$metric_statement" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --replies-sent "0" \
  --objections-captured "0" \
  --docs-updates "0" \
  --creator-signal-top-handle "$creator_signal_top_handle" \
  --distribution-completion-score "0" \
  --channel-mix-recommendation "${channel_mix_recommendation:-Keep channel mix balanced until distribution execution score is logged.}" \
  --variant-recommendation "Use first launch replies to decide next-week proof/workflow/objection default." \
  --outreach-recommendation "${creator_signal_recommendation:-Capture creator signal comments in Monday checklist before Friday review.}" \
  --out "$credibility_ledger_out"

run_step "Generate founder fame uplift tracker" zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --campaign-dir "docs/campaigns" \
  --out "$founder_fame_uplift_tracker_out"

run_step "Generate founder fame weight profile" zsh scripts/generate_founder_fame_weight_profile.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --campaign-dir "docs/campaigns" \
  --uplift-tracker "$founder_fame_uplift_tracker_out" \
  --out "$founder_fame_weight_profile_out"

run_step "Generate founder fame momentum brief" zsh scripts/generate_founder_fame_momentum_brief.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --fame-pack "$founder_fame_out" \
  --repurpose-plan "$founder_fame_repurpose_out" \
  --transcript-ingestion "$founder_fame_transcript_ingestion_out" \
  --press-kit "$founder_press_out" \
  --media-blast "$founder_media_out" \
  --credibility-ledger "$credibility_ledger_out" \
  --weight-profile "$founder_fame_weight_profile_out" \
  --out "$founder_fame_momentum_out"

run_step "Generate founder fame opportunity radar" zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --momentum-brief "$founder_fame_momentum_out" \
  --weight-profile "$founder_fame_weight_profile_out" \
  --uplift-tracker "$founder_fame_uplift_tracker_out" \
  --winning-hook-library "$winning_hook_library_out" \
  --credibility-ledger "$credibility_ledger_out" \
  --out "$founder_fame_opportunity_radar_out"

run_step "Generate founder fame execution sprint" zsh scripts/generate_founder_fame_execution_sprint.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --opportunity-radar "$founder_fame_opportunity_radar_out" \
  --momentum-brief "$founder_fame_momentum_out" \
  --distribution-plan "$distribution_out" \
  --monday-checkpoint "$monday_checkpoint_out" \
  --reply-pack "$reply_pack_out" \
  --out "$founder_fame_execution_sprint_out"

run_step "Generate founder fame execution scorecard" zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --execution-sprint "$founder_fame_execution_sprint_out" \
  --opportunity-radar "$founder_fame_opportunity_radar_out" \
  --momentum-brief "$founder_fame_momentum_out" \
  --distribution-plan "$distribution_out" \
  --monday-checkpoint "$monday_checkpoint_out" \
  --reply-pack "$reply_pack_out" \
  --out "$founder_fame_execution_scorecard_out"

run_step "Generate founder fame risk response plan" zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --execution-scorecard "$founder_fame_execution_scorecard_out" \
  --execution-sprint "$founder_fame_execution_sprint_out" \
  --opportunity-radar "$founder_fame_opportunity_radar_out" \
  --momentum-brief "$founder_fame_momentum_out" \
  --distribution-plan "$distribution_out" \
  --reply-pack "$reply_pack_out" \
  --out "$founder_fame_risk_response_out"

run_step "Generate founder fame escalation queue" zsh scripts/generate_founder_fame_escalation_queue.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --risk-response-plan "$founder_fame_risk_response_out" \
  --execution-scorecard "$founder_fame_execution_scorecard_out" \
  --execution-sprint "$founder_fame_execution_sprint_out" \
  --distribution-plan "$distribution_out" \
  --reply-pack "$reply_pack_out" \
  --out "$founder_fame_escalation_queue_out"

run_step "Generate founder fame command center" zsh scripts/generate_founder_fame_command_center.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --momentum-brief "$founder_fame_momentum_out" \
  --execution-scorecard "$founder_fame_execution_scorecard_out" \
  --risk-response-plan "$founder_fame_risk_response_out" \
  --escalation-queue "$founder_fame_escalation_queue_out" \
  --opportunity-radar "$founder_fame_opportunity_radar_out" \
  --out "$founder_fame_command_center_out"

run_step "Generate founder fame next-move handoff" zsh scripts/generate_founder_fame_next_move_handoff.sh \
  --week "$week" \
  --command-center "$founder_fame_command_center_out" \
  --artifact-link "$founder_fame_command_center_out" \
  --out "$founder_fame_next_move_handoff_out"

run_step "Generate founder fame next-move draft pack" zsh scripts/generate_founder_fame_next_move_draft_pack.sh \
  --week "$week" \
  --next-move-handoff "$founder_fame_next_move_handoff_out" \
  --out "$founder_fame_next_move_draft_pack_out"

run_step "Generate founder fame spotlight pack" zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --command-center "$founder_fame_command_center_out" \
  --momentum-brief "$founder_fame_momentum_out" \
  --execution-scorecard "$founder_fame_execution_scorecard_out" \
  --risk-response-plan "$founder_fame_risk_response_out" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_fame_spotlight_out"

run_step "Generate founder fame breakout plan" zsh scripts/generate_founder_fame_breakout_plan.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --spotlight-pack "$founder_fame_spotlight_out" \
  --command-center "$founder_fame_command_center_out" \
  --execution-sprint "$founder_fame_execution_sprint_out" \
  --distribution-plan "$distribution_out" \
  --winning-hook-library "$winning_hook_library_out" \
  --credibility-ledger "$credibility_ledger_out" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_fame_breakout_out"

run_step "Generate founder fame outreach sprint" zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --breakout-plan "$founder_fame_breakout_out" \
  --creator-target-list "$target_list_out" \
  --distribution-plan "$distribution_out" \
  --media-blast "$founder_media_out" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_fame_outreach_sprint_out"

run_step "Generate founder fame proof loop" zsh scripts/generate_founder_fame_proof_loop.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --breakout-plan "$founder_fame_breakout_out" \
  --outreach-sprint "$founder_fame_outreach_sprint_out" \
  --spotlight-pack "$founder_fame_spotlight_out" \
  --command-center "$founder_fame_command_center_out" \
  --credibility-ledger "$credibility_ledger_out" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --out "$founder_fame_proof_loop_out"

run_step "Verify founder fame proof loop" zsh scripts/verify_founder_fame_proof_loop.sh \
  --proof-loop "$founder_fame_proof_loop_out" \
  --strict \
  --out "$founder_fame_proof_loop_check_out"

run_step "Generate founder fame KPI snapshot" zsh scripts/generate_founder_fame_kpi_snapshot.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --proof-loop "$founder_fame_proof_loop_out" \
  --command-center "$founder_fame_command_center_out" \
  --proof-loop-check "$founder_fame_proof_loop_check_out" \
  --out "$founder_fame_kpi_snapshot_out"

run_step "Generate founder fame velocity scoreboard" zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --kpi-snapshot "$founder_fame_kpi_snapshot_out" \
  --command-center "$founder_fame_command_center_out" \
  --proof-loop-check "$founder_fame_proof_loop_check_out" \
  --out "$founder_fame_velocity_scoreboard_out"

run_step "Generate founder fame exceptional loop" zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --kpi-snapshot "$founder_fame_kpi_snapshot_out" \
  --velocity-scoreboard "$founder_fame_velocity_scoreboard_out" \
  --out "$founder_fame_exceptional_loop_out"

exceptional_loop_comment_args=(
  --exceptional-loop "$founder_fame_exceptional_loop_out"
  --action-queue "$founder_fame_action_queue_out"
  --out "$founder_fame_exceptional_loop_comment_out"
)

if [[ -n "$founder_fame_exceptional_loop_comment_issue" ]]; then
  exceptional_loop_comment_args+=(--issue "$founder_fame_exceptional_loop_comment_issue")
fi

if [[ -n "$founder_fame_exceptional_loop_comment_repo" ]]; then
  exceptional_loop_comment_args+=(--repo "$founder_fame_exceptional_loop_comment_repo")
fi

exceptional_loop_comment_mode=""
if (( post_founder_fame_exceptional_loop_comment == 1 )); then
  run_step "Upsert founder fame exceptional-loop checklist comment" zsh scripts/post_founder_fame_exceptional_loop_comment.sh "${exceptional_loop_comment_args[@]}"
  if [[ -n "$founder_fame_exceptional_loop_comment_issue" ]]; then
    exceptional_loop_comment_mode="upserted to issue ${founder_fame_exceptional_loop_comment_issue}"
  else
    exceptional_loop_comment_mode="upserted (issue auto-detected)"
  fi
else
  exceptional_loop_comment_args+=(--dry-run)
  run_step "Render founder fame exceptional-loop checklist comment draft" zsh scripts/post_founder_fame_exceptional_loop_comment.sh "${exceptional_loop_comment_args[@]}"
  exceptional_loop_comment_mode="draft-only (set --post-founder-fame-exceptional-loop-comment for live upsert)"
fi

exceptional_loop_live_verify_args=(
  --exceptional-loop "$founder_fame_exceptional_loop_out"
  --comment "$founder_fame_exceptional_loop_comment_out"
  --out "$founder_fame_exceptional_loop_live_check_out"
)
if [[ -n "$founder_fame_exceptional_loop_comment_issue" ]]; then
  exceptional_loop_live_verify_args+=(--issue "$founder_fame_exceptional_loop_comment_issue")
fi
if [[ -n "$founder_fame_exceptional_loop_comment_repo" ]]; then
  exceptional_loop_live_verify_args+=(--repo "$founder_fame_exceptional_loop_comment_repo")
fi
exceptional_loop_live_check_mode=""
if (( post_founder_fame_exceptional_loop_comment == 1 )); then
  exceptional_loop_live_verify_args+=(--strict)
  exceptional_loop_live_check_mode="strict"
else
  exceptional_loop_live_check_mode="non-strict draft validation"
fi
run_step "Verify founder fame exceptional-loop live state" zsh scripts/verify_founder_fame_exceptional_loop_run.sh "${exceptional_loop_live_verify_args[@]}"

run_step "Generate founder fame narrative lab" zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --kpi-snapshot "$founder_fame_kpi_snapshot_out" \
  --proof-loop "$founder_fame_proof_loop_out" \
  --command-center "$founder_fame_command_center_out" \
  --winning-hook-library "$winning_hook_library_out" \
  --credibility-ledger "$credibility_ledger_out" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --primary-audience-region "$primary_audience_region" \
  --backup-audience-region "$backup_audience_region" \
  --out "$founder_fame_narrative_lab_out"

run_step "Generate founder fame war room" zsh scripts/generate_founder_fame_war_room.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --command-center "$founder_fame_command_center_out" \
  --next-move-handoff "$founder_fame_next_move_handoff_out" \
  --next-move-draft-pack "$founder_fame_next_move_draft_pack_out" \
  --proof-loop-check "$founder_fame_proof_loop_check_out" \
  --narrative-lab "$founder_fame_narrative_lab_out" \
  --out "$founder_fame_war_room_out"

run_step "Verify founder fame war room" zsh scripts/verify_founder_fame_war_room.sh \
  --war-room "$founder_fame_war_room_out" \
  --strict \
  --out "$founder_fame_war_room_check_out"

war_room_comment_args=(
  --war-room "$founder_fame_war_room_out"
  --action-queue "$founder_fame_action_queue_out"
  --strict
  --out "$founder_fame_war_room_comment_out"
)

if [[ -n "$founder_fame_war_room_comment_issue" ]]; then
  war_room_comment_args+=(--issue "$founder_fame_war_room_comment_issue")
fi

if [[ -n "$founder_fame_war_room_comment_repo" ]]; then
  war_room_comment_args+=(--repo "$founder_fame_war_room_comment_repo")
fi

war_room_comment_mode=""
if (( post_founder_fame_war_room_comment == 1 )); then
  run_step "Upsert founder fame war-room checklist comment" zsh scripts/post_founder_fame_war_room_comment.sh "${war_room_comment_args[@]}"
  if [[ -n "$founder_fame_war_room_comment_issue" ]]; then
    war_room_comment_mode="upserted to issue ${founder_fame_war_room_comment_issue}"
  else
    war_room_comment_mode="upserted (issue auto-detected)"
  fi
else
  war_room_comment_args+=(--dry-run)
  run_step "Render founder fame war-room checklist comment draft" zsh scripts/post_founder_fame_war_room_comment.sh "${war_room_comment_args[@]}"
  war_room_comment_mode="draft-only (set --post-founder-fame-war-room-comment for live upsert)"
fi

war_room_live_verify_args=(
  --war-room "$founder_fame_war_room_out"
  --comment "$founder_fame_war_room_comment_out"
  --out "$founder_fame_war_room_live_check_out"
)
if [[ -n "$founder_fame_war_room_comment_issue" ]]; then
  war_room_live_verify_args+=(--issue "$founder_fame_war_room_comment_issue")
fi
if [[ -n "$founder_fame_war_room_comment_repo" ]]; then
  war_room_live_verify_args+=(--repo "$founder_fame_war_room_comment_repo")
fi
war_room_live_check_mode=""
if (( post_founder_fame_war_room_comment == 1 )); then
  war_room_live_verify_args+=(--strict)
  war_room_live_check_mode="strict"
else
  war_room_live_check_mode="non-strict draft validation"
fi
run_step "Verify founder fame war-room live state" zsh scripts/verify_founder_fame_war_room_run.sh "${war_room_live_verify_args[@]}"

run_step "Generate founder first-48h post pack" zsh scripts/generate_founder_first48h_post_pack.sh \
  --week "$week" \
  --product "$founder_product_name" \
  --narrative-lab "$founder_fame_narrative_lab_out" \
  --primary-channel "$primary_channel" \
  --backup-channel "$backup_channel" \
  --cta "$founder_cta_text" \
  --primary-char-limit "$founder_first48h_primary_char_limit" \
  --backup-char-limit "$founder_first48h_backup_char_limit" \
  --primary-tone "$founder_first48h_primary_tone" \
  --backup-tone "$founder_first48h_backup_tone" \
  --out "$founder_first48h_post_pack_out"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$brief_out")"
cat > "$brief_out" <<EOF
# Launch Brief: $week

Generated: $generated_on

## Channel Plan

- Primary: $primary_channel
- Backup: $backup_channel

## Story

- Problem: $problem_statement
- Outcome: $outcome_statement
- Metric: $metric_statement
- Command spotlight: \`$command_name\`
- Proof asset: \`$asset_name\`

## Produced Artifacts

- Campaign pack: \`$pack_out\`
- Founder update post pack: \`$founder_update_out\`
- Founder fame pack: \`$founder_fame_out\`
- Founder press kit: \`$founder_press_out\`
- Founder media blast: \`$founder_media_out\`
- Weekly growth issue template: \`$weekly_issue_out\`
- Social proof kit: \`$proof_out\`
- First-24-hour reply pack: \`$reply_pack_out\`
- Monday publish checkpoint: \`$monday_checkpoint_out\`
- Creator outreach kit: \`$outreach_out\`
- Creator target list: \`$target_list_out\`
- Distribution follow-up plan: \`$distribution_out\`
- Viral experiment board: \`$viral_board_out\`
- Social proof wall: \`$social_proof_wall_out\`
- Founder fame ops brief: \`$founder_fame_ops_out\`
- Founder fame daily mission source: \`$founder_fame_daily_mission_source\`
- Founder fame daily mission freshness: \`$founder_fame_daily_mission_freshness\`
- Founder fame action queue: \`$founder_fame_action_queue_out\`
- Founder fame interview prep: \`$founder_fame_interview_prep_out\`
- Founder transcript source: \`$founder_transcript_source_path\`
- Founder fame transcript ingestion: \`$founder_fame_transcript_ingestion_out\`
- Founder fame repurpose plan: \`$founder_fame_repurpose_out\`
- Founder fame uplift tracker: \`$founder_fame_uplift_tracker_out\`
- Founder fame weight profile: \`$founder_fame_weight_profile_out\`
- Founder fame momentum brief: \`$founder_fame_momentum_out\`
- Founder fame opportunity radar: \`$founder_fame_opportunity_radar_out\`
- Founder fame execution sprint: \`$founder_fame_execution_sprint_out\`
- Founder fame execution scorecard: \`$founder_fame_execution_scorecard_out\`
- Founder fame risk response plan: \`$founder_fame_risk_response_out\`
- Founder fame escalation queue: \`$founder_fame_escalation_queue_out\`
- Founder fame command center: \`$founder_fame_command_center_out\`
- Founder fame next-move handoff: \`$founder_fame_next_move_handoff_out\`
- Founder fame next-move draft pack: \`$founder_fame_next_move_draft_pack_out\`
- In-app fast loop: run \`Fame -> Run Fame Next Move\`, then log artifact link + owner update in \`Monday Publish Checklist <week>\`.
- Founder fame war room: \`$founder_fame_war_room_out\`
- Founder fame war-room verification: \`$founder_fame_war_room_check_out\`
- Founder fame war-room checklist comment: \`$founder_fame_war_room_comment_out\` ($war_room_comment_mode)
- Founder fame war-room live verification: \`$founder_fame_war_room_live_check_out\` ($war_room_live_check_mode)
- Founder fame spotlight pack: \`$founder_fame_spotlight_out\`
- Founder fame breakout plan: \`$founder_fame_breakout_out\`
- Founder fame outreach sprint: \`$founder_fame_outreach_sprint_out\`
- Founder fame proof loop: \`$founder_fame_proof_loop_out\`
- Founder fame proof loop verification: \`$founder_fame_proof_loop_check_out\`
- Founder fame KPI snapshot: \`$founder_fame_kpi_snapshot_out\`
- Founder fame velocity scoreboard: \`$founder_fame_velocity_scoreboard_out\`
- Founder fame exceptional loop: \`$founder_fame_exceptional_loop_out\`
- Founder fame exceptional-loop checklist comment: \`$founder_fame_exceptional_loop_comment_out\` ($exceptional_loop_comment_mode)
- Founder fame exceptional-loop live verification: \`$founder_fame_exceptional_loop_live_check_out\` ($exceptional_loop_live_check_mode)
- Founder fame narrative lab: \`$founder_fame_narrative_lab_out\`
- Founder first-48h post pack: \`$founder_first48h_post_pack_out\`
- Winning hook library: \`$winning_hook_library_out\`
- Credibility ledger: \`$credibility_ledger_out\`
- Launch brief: \`$brief_out\`

## Validation Run

- $( (( skip_tests == 0 )) && echo "swift test" || echo "swift test (skipped)" )
- zsh scripts/check_docs.sh
- zsh scripts/check_growth.sh
- zsh scripts/check_fast.sh

## Immediate Next Steps

1. Post primary launch message to $primary_channel.
2. Publish founder update post on founder-facing channel.
3. Run founder fame + press + media sequence for amplification.
4. Use Monday publish checkpoint windows + sequence before posting.
5. Post short variant to $backup_channel.
6. Open weekly growth issue template and assign owners.
7. Use the first-24-hour reply pack for practical question responses.
8. Send 5 creator outreach messages using the outreach kit.
9. Execute Day 0-2 follow-ups from the distribution plan.
10. Assign owners for top-2 viral experiments.
11. Queue repost windows using social proof wall proof cards.
12. Assign owners and complete top 3 founder fame actions from the action queue.
13. Rehearse 10-second + 30-second founder opener from interview prep.
14. Finalize quote + clip selection from transcript ingestion.
15. Publish one founder clip/thread from the repurpose plan.
16. Lock next-week Hook A/B/C defaults from the winning hook library.
17. Convert top replies into one docs update.
18. Publish one credibility follow-up using ledger highlights.
19. Post a short founder momentum summary using the momentum brief.
20. Execute top-priority founder opportunity from the opportunity radar.
21. Run daily owner check-ins from the founder fame execution sprint board.
22. Resolve highest risk flag from the founder fame execution scorecard.
23. Run first two mitigations from the founder fame risk response plan.
24. Execute the top two owner-routed actions from the founder fame escalation queue.
25. Run the founder fame command center standup, then execute "Fame -> Run Fame Next Move" and share one owner update + artifact link.
26. Publish one proof-first spotlight post from the founder fame spotlight pack.
27. Run the founder fame breakout cadence and ship Day 0 + Day 1 scripts.
28. Execute the founder fame outreach sprint to trigger creator + guesting booking waves.
29. Run the founder fame proof loop standup and close one conversion log.
30. Share the founder fame KPI snapshot with owners before the next standup.
31. Share the founder fame velocity scoreboard and execute its priority move.
32. Run the founder fame exceptional loop and execute the next 72-hour move owner.
33. Run the founder fame narrative lab and lock this week’s narrative route winner.
EOF

echo "Launch day run complete."
echo "Campaign pack: $pack_out"
echo "Founder update post pack: $founder_update_out"
echo "Founder fame pack: $founder_fame_out"
echo "Founder press kit: $founder_press_out"
echo "Founder media blast: $founder_media_out"
echo "Weekly growth issue template: $weekly_issue_out"
echo "Social proof kit: $proof_out"
echo "First-24-hour reply pack: $reply_pack_out"
echo "Monday publish checkpoint: $monday_checkpoint_out"
echo "Creator outreach kit: $outreach_out"
echo "Creator target list: $target_list_out"
echo "Distribution follow-up plan: $distribution_out"
echo "Viral experiment board: $viral_board_out"
echo "Social proof wall: $social_proof_wall_out"
echo "Founder fame ops brief: $founder_fame_ops_out"
echo "Founder fame daily mission source: $founder_fame_daily_mission_source"
echo "Founder fame daily mission freshness: $founder_fame_daily_mission_freshness"
echo "Founder fame action queue: $founder_fame_action_queue_out"
echo "Founder fame interview prep: $founder_fame_interview_prep_out"
echo "Founder transcript source: $founder_transcript_source_path"
echo "Founder fame transcript ingestion: $founder_fame_transcript_ingestion_out"
echo "Founder fame repurpose plan: $founder_fame_repurpose_out"
echo "Founder fame uplift tracker: $founder_fame_uplift_tracker_out"
echo "Founder fame weight profile: $founder_fame_weight_profile_out"
echo "Founder fame momentum brief: $founder_fame_momentum_out"
echo "Founder fame opportunity radar: $founder_fame_opportunity_radar_out"
echo "Founder fame execution sprint: $founder_fame_execution_sprint_out"
echo "Founder fame execution scorecard: $founder_fame_execution_scorecard_out"
echo "Founder fame risk response plan: $founder_fame_risk_response_out"
echo "Founder fame escalation queue: $founder_fame_escalation_queue_out"
echo "Founder fame command center: $founder_fame_command_center_out"
echo "Founder fame next-move handoff: $founder_fame_next_move_handoff_out"
echo "Founder fame next-move draft pack: $founder_fame_next_move_draft_pack_out"
echo "In-app fast loop: Run Fame Next Move, then log artifact link + owner update in Monday Publish Checklist <week>."
echo "Founder fame war room: $founder_fame_war_room_out"
echo "Founder fame war-room verification: $founder_fame_war_room_check_out"
echo "Founder fame war-room checklist comment: $founder_fame_war_room_comment_out ($war_room_comment_mode)"
echo "Founder fame war-room live verification: $founder_fame_war_room_live_check_out ($war_room_live_check_mode)"
echo "Founder fame spotlight pack: $founder_fame_spotlight_out"
echo "Founder fame breakout plan: $founder_fame_breakout_out"
echo "Founder fame outreach sprint: $founder_fame_outreach_sprint_out"
echo "Founder fame proof loop: $founder_fame_proof_loop_out"
echo "Founder fame proof loop verification: $founder_fame_proof_loop_check_out"
echo "Founder fame KPI snapshot: $founder_fame_kpi_snapshot_out"
echo "Founder fame velocity scoreboard: $founder_fame_velocity_scoreboard_out"
echo "Founder fame exceptional loop: $founder_fame_exceptional_loop_out"
echo "Founder fame exceptional-loop checklist comment: $founder_fame_exceptional_loop_comment_out ($exceptional_loop_comment_mode)"
echo "Founder fame exceptional-loop live verification: $founder_fame_exceptional_loop_live_check_out ($exceptional_loop_live_check_mode)"
echo "Founder fame narrative lab: $founder_fame_narrative_lab_out"
echo "Founder first-48h post pack: $founder_first48h_post_pack_out"
echo "Winning hook library: $winning_hook_library_out"
echo "Credibility ledger: $credibility_ledger_out"
echo "Launch brief: $brief_out"
