#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

FIXTURE_DIR="scripts/fixtures/founder"
INPUTS_FILE="$FIXTURE_DIR/sample_inputs.env"

required_files=(
  "scripts/generate_founder_weekly_review.sh"
  "scripts/generate_founder_weekly_delta.sh"
  "scripts/generate_founder_scoreboard.sh"
  "scripts/generate_founder_update_post.sh"
  "scripts/generate_founder_fame_pack.sh"
  "scripts/generate_founder_press_kit.sh"
  "scripts/generate_founder_media_blast.sh"
  "scripts/generate_founder_guesting_queue.sh"
  "scripts/generate_founder_guesting_brief.sh"
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
  "scripts/generate_founder_fame_spotlight_pack.sh"
  "scripts/generate_founder_fame_breakout_plan.sh"
  "scripts/generate_founder_fame_outreach_sprint.sh"
  "scripts/generate_founder_fame_proof_loop.sh"
  "scripts/generate_founder_fame_kpi_snapshot.sh"
  "scripts/generate_founder_fame_velocity_scoreboard.sh"
  "scripts/generate_founder_fame_exceptional_loop.sh"
  "scripts/generate_founder_fame_narrative_lab.sh"
  "scripts/generate_founder_first48h_post_pack.sh"
  "scripts/verify_founder_fame_war_room.sh"
  "scripts/verify_founder_fame_war_room_run.sh"
  "scripts/post_founder_fame_war_room_comment.sh"
  "scripts/post_founder_fame_exceptional_loop_comment.sh"
  "scripts/verify_founder_fame_exceptional_loop_run.sh"
  "scripts/verify_founder_fame_proof_loop_run.sh"
  "scripts/generate_founder_weekly_pack.sh"
  "docs/FOUNDER_FAME_PACK.md"
  "docs/FOUNDER_FAME_INTERVIEW_PREP.md"
  "docs/FOUNDER_FAME_TRANSCRIPT_INGESTION.md"
  "docs/FOUNDER_PRESS_KIT.md"
  "docs/FOUNDER_MEDIA_BLAST.md"
  "docs/FOUNDER_GUESTING_QUEUE.md"
  "docs/FOUNDER_GUESTING_BRIEF.md"
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
  "docs/FOUNDER_FAME_WAR_ROOM.md"
  "docs/FOUNDER_FAME_SPOTLIGHT_PACK.md"
  "docs/FOUNDER_FAME_BREAKOUT_PLAN.md"
  "docs/FOUNDER_FAME_OUTREACH_SPRINT.md"
  "docs/FOUNDER_FAME_PROOF_LOOP.md"
  "docs/FOUNDER_FAME_KPI_SNAPSHOT.md"
  "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"
  "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"
  "docs/FOUNDER_FAME_NARRATIVE_LAB.md"
  "docs/FOUNDER_FIRST48H_POST_PACK.md"
  "docs/FOUNDER_METRICS_QUICKSTART.md"
  "docs/FOUNDER_WEEKLY_REVIEW.md"
  "docs/FOUNDER_SCOREBOARD.md"
  "docs/FOUNDER_UPDATE_POST.md"
  "$INPUTS_FILE"
  "$FIXTURE_DIR/review_markers.txt"
  "$FIXTURE_DIR/delta_markers.txt"
  "$FIXTURE_DIR/scoreboard_markers.txt"
  "$FIXTURE_DIR/post_markers.txt"
  "$FIXTURE_DIR/fame_markers.txt"
  "$FIXTURE_DIR/press_markers.txt"
  "$FIXTURE_DIR/media_blast_markers.txt"
  "$FIXTURE_DIR/guesting_markers.txt"
  "$FIXTURE_DIR/guesting_brief_markers.txt"
  "$FIXTURE_DIR/interview_prep_markers.txt"
  "$FIXTURE_DIR/transcript_ingestion_markers.txt"
  "$FIXTURE_DIR/repurpose_markers.txt"
  "$FIXTURE_DIR/momentum_brief_markers.txt"
  "$FIXTURE_DIR/opportunity_radar_markers.txt"
  "$FIXTURE_DIR/execution_sprint_markers.txt"
  "$FIXTURE_DIR/execution_scorecard_markers.txt"
  "$FIXTURE_DIR/risk_response_plan_markers.txt"
  "$FIXTURE_DIR/escalation_queue_markers.txt"
  "$FIXTURE_DIR/command_center_markers.txt"
  "$FIXTURE_DIR/war_room_markers.txt"
  "$FIXTURE_DIR/spotlight_pack_markers.txt"
  "$FIXTURE_DIR/breakout_plan_markers.txt"
  "$FIXTURE_DIR/outreach_sprint_markers.txt"
  "$FIXTURE_DIR/proof_loop_markers.txt"
  "$FIXTURE_DIR/kpi_snapshot_markers.txt"
  "$FIXTURE_DIR/velocity_scoreboard_markers.txt"
  "$FIXTURE_DIR/exceptional_loop_markers.txt"
  "$FIXTURE_DIR/exceptional_loop_comment_markers.txt"
  "$FIXTURE_DIR/narrative_lab_markers.txt"
  "$FIXTURE_DIR/first48h_post_pack_markers.txt"
)

for required_path in "${required_files[@]}"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Missing founder workflow asset: $required_path"
    exit 1
  fi
done

if ! zsh scripts/verify_founder_fame_war_room_run.sh --help >/dev/null; then
  echo "Founder war-room live verification script help command failed."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_founder_fame_war_room_run.sh"; then
  echo "Founder war-room live verification script is missing strict mode option."
  exit 1
fi

if ! zsh scripts/verify_founder_fame_exceptional_loop_run.sh --help >/dev/null; then
  echo "Founder exceptional-loop live verification script help command failed."
  exit 1
fi

if ! rg -Fq -- "--strict" "scripts/verify_founder_fame_exceptional_loop_run.sh"; then
  echo "Founder exceptional-loop live verification script is missing strict mode option."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_velocity_scoreboard.sh" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder velocity scoreboard docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq -- "--kpi-snapshot" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder velocity scoreboard docs are missing kpi-snapshot option guidance."
  exit 1
fi

if ! rg -Fq "Route Velocity Controls" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder velocity scoreboard docs are missing route velocity controls guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-velocity-scoreboard" "docs/FOUNDER_FAME_VELOCITY_SCOREBOARD.md"; then
  echo "Founder velocity scoreboard docs are missing weekly checklist marker guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_kpi_snapshot.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing KPI snapshot guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_velocity_scoreboard.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing velocity scoreboard guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_exceptional_loop.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing exceptional loop guidance."
  exit 1
fi

if ! rg -Fq "post_founder_fame_exceptional_loop_comment.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing exceptional-loop checklist comment guidance."
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
  echo "Founder fame pack docs are missing exceptional-loop live verification guidance."
  exit 1
fi

if ! rg -Fq "post_founder_fame_exceptional_loop_comment.sh" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing checklist comment command guidance."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing action-queue mission freshness context guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-exceptional-loop-comment" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing checklist comment marker guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_exceptional_loop_run.sh" "docs/FOUNDER_FAME_EXCEPTIONAL_LOOP.md"; then
  echo "Founder fame exceptional loop docs are missing live verification command guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_narrative_lab.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing narrative lab guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_war_room_run.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing war-room live verification guidance."
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

if ! rg -Fq "generate_founder_first48h_post_pack.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing first-48h post pack guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_next_move_draft_pack.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing next-move draft-pack guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_next_move_draft_pack.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing next-move draft-pack guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_war_room.sh" "docs/FOUNDER_FAME_PACK.md"; then
  echo "Founder fame pack docs are missing war-room guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_war_room.sh" "docs/CAMPAIGN_AUTOMATION.md"; then
  echo "Campaign automation docs are missing war-room guidance."
  exit 1
fi

if ! rg -Fq "generate_founder_fame_war_room.sh" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing generator command guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-war-room" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing checklist marker guidance."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_war_room.sh" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing verifier command guidance."
  exit 1
fi

if ! rg -Fq -- "--strict" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing strict verifier guidance."
  exit 1
fi

if ! rg -Fq "post_founder_fame_war_room_comment.sh" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing checklist comment upsert guidance."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing action-queue mission freshness context guidance."
  exit 1
fi

if ! rg -Fq -- "--dry-run" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing checklist comment dry-run guidance."
  exit 1
fi

if ! rg -Fq "weekly-growth-founder-fame-war-room-comment" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing checklist comment marker guidance."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "scripts/post_founder_fame_war_room_comment.sh"; then
  echo "Founder fame war-room checklist comment script is missing action-queue option."
  exit 1
fi

if ! rg -Fq -- "--action-queue" "scripts/post_founder_fame_exceptional_loop_comment.sh"; then
  echo "Founder fame exceptional-loop checklist comment script is missing action-queue option."
  exit 1
fi

if ! rg -Fq "verify_founder_fame_war_room_run.sh" "docs/FOUNDER_FAME_WAR_ROOM.md"; then
  echo "Founder fame war-room docs are missing live checklist verification guidance."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_VELOCITY_SCOREBOARD.md" "README.md"; then
  echo "README is missing founder fame velocity scoreboard docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FIRST48H_POST_PACK.md" "README.md"; then
  echo "README is missing founder first-48h post pack docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_WAR_ROOM.md" "README.md"; then
  echo "README is missing founder fame war-room docs link."
  exit 1
fi

if ! rg -Fq "FOUNDER_FAME_EXCEPTIONAL_LOOP.md" "README.md"; then
  echo "README is missing founder fame exceptional-loop docs link."
  exit 1
fi

if ! rg -Fq "founder-fame-velocity-scoreboard-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame velocity scoreboard artifact naming."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_velocity_scoreboard.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame velocity scoreboard generation command."
  exit 1
fi

if ! rg -Fq "echo \"velocity_scoreboard_path=\$velocity_scoreboard_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame velocity scoreboard output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame velocity scoreboard:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame velocity scoreboard summary output."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-exceptional-loop-live-check-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop live verification artifact naming."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_exceptional_loop.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop generation command."
  exit 1
fi

if ! rg -Fq -- "--velocity-scoreboard \"\$velocity_scoreboard_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow does not wire founder fame velocity scoreboard into exceptional-loop generation."
  exit 1
fi

if ! rg -Fq "echo \"exceptional_loop_path=\$exceptional_loop_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional loop:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop summary output."
  exit 1
fi

if ! rg -Fq "founder-first48h-post-pack-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h post pack artifact naming."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_first48h_post_pack.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h post pack generation command."
  exit 1
fi

if ! rg -Fq "first48h_primary_char_limit" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h primary char-limit input wiring."
  exit 1
fi

if ! rg -Fq "first48h_backup_char_limit" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h backup char-limit input wiring."
  exit 1
fi

if ! rg -Fq "first48h_primary_tone" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h primary tone input wiring."
  exit 1
fi

if ! rg -Fq "first48h_backup_tone" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h backup tone input wiring."
  exit 1
fi

if ! rg -Fq -- "--primary-char-limit \"\$first48h_primary_char_limit\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h primary char-limit command wiring."
  exit 1
fi

if ! rg -Fq -- "--backup-char-limit \"\$first48h_backup_char_limit\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h backup char-limit command wiring."
  exit 1
fi

if ! rg -Fq -- "--primary-tone \"\$first48h_primary_tone\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h primary tone command wiring."
  exit 1
fi

if ! rg -Fq -- "--backup-tone \"\$first48h_backup_tone\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h backup tone command wiring."
  exit 1
fi

if ! rg -Fq "echo \"first48h_post_pack_path=\$first48h_post_pack_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h post pack output wiring."
  exit 1
fi

if ! rg -Fq "Founder first-48h post pack:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder first-48h post pack summary output."
  exit 1
fi

if ! rg -Fq "founder-fame-next-move-draft-pack-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame next-move draft-pack artifact naming."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_next_move_draft_pack.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame next-move draft-pack generation command."
  exit 1
fi

if ! rg -Fq "echo \"next_move_draft_pack_path=\$next_move_draft_pack_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame next-move draft-pack output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame next-move draft pack:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame next-move draft-pack summary output."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room artifact naming."
  exit 1
fi

if ! rg -Fq "scripts/generate_founder_fame_war_room.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room generation command."
  exit 1
fi

if ! rg -Fq "echo \"war_room_path=\$war_room_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame war room:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room summary output."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-check-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room verification artifact naming."
  exit 1
fi

if ! rg -Fq "founder-fame-war-room-live-check-\${week}.md" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room live verification artifact naming."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room verification command."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_war_room_run.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room live verification command."
  exit 1
fi

if ! rg -Fq -- "--comment \"\$war_room_comment_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow does not wire optional war-room checklist comment artifact into war-room live verification."
  exit 1
fi

if ! rg -Fq "war_room_verify_args+=(--strict)" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing strict war-room live verification wiring for checklist upsert mode."
  exit 1
fi

if ! rg -Fq "echo \"war_room_check_path=\$war_room_check_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room verification output wiring."
  exit 1
fi

if ! rg -Fq "echo \"war_room_live_check_path=\$war_room_live_check_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room live verification output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame war-room verification:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room verification summary output."
  exit 1
fi

if ! rg -Fq "Founder fame war-room live verification:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room live verification summary output."
  exit 1
fi

if ! rg -Fq "post_war_room_comment" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing post_war_room_comment input wiring."
  exit 1
fi

if ! rg -Fq "war_room_comment_issue" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing war_room_comment_issue input wiring."
  exit 1
fi

if ! rg -Fq "post_exceptional_loop_comment" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing post_exceptional_loop_comment input wiring."
  exit 1
fi

if ! rg -Fq "exceptional_loop_comment_issue" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing exceptional_loop_comment_issue input wiring."
  exit 1
fi

if ! rg -Fq "founder_fame_action_queue" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder_fame_action_queue optional input wiring."
  exit 1
fi

if ! rg -Fq "INPUT_POST_EXCEPTIONAL_LOOP_COMMENT" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing exceptional-loop checklist comment upsert env wiring."
  exit 1
fi

if ! rg -Fq "INPUT_FOUNDER_FAME_ACTION_QUEUE" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder_fame_action_queue env wiring."
  exit 1
fi

if ! rg -Fq "issues: write" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing issues write permission for comment upsert."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_war_room_comment.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room comment upsert command."
  exit 1
fi

if ! rg -Fq "echo \"war_room_comment_path=\$war_room_comment_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room comment output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame war-room checklist comment:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame war-room checklist comment summary output."
  exit 1
fi

if ! rg -Fq "scripts/post_founder_fame_exceptional_loop_comment.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop checklist comment render/upsert command."
  exit 1
fi

if ! rg -Fq "scripts/verify_founder_fame_exceptional_loop_run.sh" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop live verification command."
  exit 1
fi

if ! rg -Fq -- "--comment \"\$exceptional_loop_comment_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow does not wire exceptional-loop checklist comment artifact into exceptional-loop live verification."
  exit 1
fi

if ! rg -Fq "exceptional_loop_verify_args+=(--strict)" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing strict exceptional-loop live verification wiring for checklist upsert mode."
  exit 1
fi

if ! rg -Fq "echo \"exceptional_loop_comment_path=\$exceptional_loop_comment_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop checklist comment output wiring."
  exit 1
fi

if ! rg -Fq "echo \"exceptional_loop_live_check_path=\$exceptional_loop_live_check_path\" >> \"\$GITHUB_OUTPUT\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop live verification output wiring."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop checklist comment:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop checklist comment summary output."
  exit 1
fi

if ! rg -Fq -- "--action-queue \"\$founder_fame_action_queue_overlay_path\"" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow does not wire founder_fame_action_queue overlay into checklist comment scripts."
  exit 1
fi

if ! rg -Fq "Optional founder fame action queue overlay:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder_fame_action_queue overlay summary output."
  exit 1
fi

if ! rg -Fq "Founder fame daily mission freshness:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame daily mission freshness summary output."
  exit 1
fi

if ! rg -Fq "Founder fame exceptional-loop live verification:" ".github/workflows/founder-fame-pack.yml"; then
  echo "Founder workflow is missing founder fame exceptional-loop live verification summary output."
  exit 1
fi

source "$INPUTS_FILE"

TMP_DIR="${TMPDIR:-/tmp}/fluidreader-founder-check.${$}.${RANDOM}"
mkdir -p "$TMP_DIR"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

assert_markers() {
  local output_file="$1"
  local markers_file="$2"
  local label="$3"
  local marker

  while IFS= read -r marker || [[ -n "$marker" ]]; do
    [[ -z "$marker" ]] && continue
    if ! rg -Fq -- "$marker" "$output_file"; then
      echo "Missing ${label} marker: $marker"
      echo "Output file: $output_file"
      exit 1
    fi
  done < "$markers_file"
}

assert_heading() {
  local output_file="$1"
  local heading="$2"
  if ! rg -Fq -- "$heading" "$output_file"; then
    echo "Missing expected heading in $output_file: $heading"
    exit 1
  fi
}

previous_review_path="$TMP_DIR/weekly-review-${PREVIOUS_WEEK}.md"
current_review_path="$TMP_DIR/weekly-review-${CURRENT_WEEK}.md"
delta_path="$TMP_DIR/weekly-delta-${CURRENT_WEEK}.md"
scoreboard_path="$TMP_DIR/scoreboard-${CURRENT_WEEK}.md"
post_path="$TMP_DIR/founder-update-${CURRENT_WEEK}.md"
fame_path="$TMP_DIR/founder-fame-pack-${CURRENT_WEEK}.md"
press_path="$TMP_DIR/founder-press-kit-${CURRENT_WEEK}.md"
media_blast_path="$TMP_DIR/founder-media-blast-${CURRENT_WEEK}.md"
guesting_queue_path="$TMP_DIR/founder-guesting-queue-${CURRENT_WEEK}.md"
guesting_brief_path="$TMP_DIR/founder-guesting-brief-${CURRENT_WEEK}.md"
interview_prep_path="$TMP_DIR/founder-fame-interview-prep-${CURRENT_WEEK}.md"
transcript_ingestion_path="$TMP_DIR/founder-fame-transcript-ingestion-${CURRENT_WEEK}.md"
repurpose_plan_path="$TMP_DIR/founder-fame-repurpose-plan-${CURRENT_WEEK}.md"
uplift_tracker_path="$TMP_DIR/founder-fame-uplift-tracker-${CURRENT_WEEK}.md"
weight_profile_path="$TMP_DIR/founder-fame-weight-profile-${CURRENT_WEEK}.md"
momentum_brief_path="$TMP_DIR/founder-fame-momentum-brief-${CURRENT_WEEK}.md"
opportunity_radar_path="$TMP_DIR/founder-fame-opportunity-radar-${CURRENT_WEEK}.md"
execution_sprint_path="$TMP_DIR/founder-fame-execution-sprint-${CURRENT_WEEK}.md"
execution_scorecard_path="$TMP_DIR/founder-fame-execution-scorecard-${CURRENT_WEEK}.md"
risk_response_plan_path="$TMP_DIR/founder-fame-risk-response-plan-${CURRENT_WEEK}.md"
escalation_queue_path="$TMP_DIR/founder-fame-escalation-queue-${CURRENT_WEEK}.md"
command_center_path="$TMP_DIR/founder-fame-command-center-${CURRENT_WEEK}.md"
next_move_handoff_path="$TMP_DIR/founder-fame-next-move-handoff-${CURRENT_WEEK}.md"
next_move_draft_pack_path="$TMP_DIR/founder-fame-next-move-draft-pack-${CURRENT_WEEK}.md"
spotlight_pack_path="$TMP_DIR/founder-fame-spotlight-pack-${CURRENT_WEEK}.md"
breakout_plan_path="$TMP_DIR/founder-fame-breakout-plan-${CURRENT_WEEK}.md"
outreach_sprint_path="$TMP_DIR/founder-fame-outreach-sprint-${CURRENT_WEEK}.md"
proof_loop_path="$TMP_DIR/founder-fame-proof-loop-${CURRENT_WEEK}.md"
proof_loop_check_path="$TMP_DIR/founder-fame-proof-loop-check-${CURRENT_WEEK}.md"
kpi_snapshot_path="$TMP_DIR/founder-fame-kpi-snapshot-${CURRENT_WEEK}.md"
velocity_scoreboard_path="$TMP_DIR/founder-fame-velocity-scoreboard-${CURRENT_WEEK}.md"
exceptional_loop_path="$TMP_DIR/founder-fame-exceptional-loop-${CURRENT_WEEK}.md"
exceptional_loop_comment_path="$TMP_DIR/founder-fame-exceptional-loop-comment-${CURRENT_WEEK}.md"
exceptional_loop_live_check_path="$TMP_DIR/founder-fame-exceptional-loop-live-check-${CURRENT_WEEK}.md"
narrative_lab_path="$TMP_DIR/founder-fame-narrative-lab-${CURRENT_WEEK}.md"
war_room_path="$TMP_DIR/founder-fame-war-room-${CURRENT_WEEK}.md"
war_room_check_path="$TMP_DIR/founder-fame-war-room-check-${CURRENT_WEEK}.md"
war_room_live_check_path="$TMP_DIR/founder-fame-war-room-live-check-${CURRENT_WEEK}.md"
war_room_comment_path="$TMP_DIR/founder-fame-war-room-comment-${CURRENT_WEEK}.md"
first48h_post_pack_path="$TMP_DIR/founder-first48h-post-pack-${CURRENT_WEEK}.md"
first48h_primary_char_limit="240"
first48h_backup_char_limit="420"
first48h_primary_tone="x-punchy"
first48h_backup_tone="linkedin-context"
action_queue_context_path="$TMP_DIR/founder-fame-action-queue-context-${CURRENT_WEEK}.md"
cat > "$action_queue_context_path" <<EOF
# Founder Fame Action Queue: ${CURRENT_WEEK}

## 3-Hour Mission Bridge

- Daily mission source: scripts/fixtures/founder/sample_daily_mission.md
- Mission freshness: Fresh (0d old)
- Freshness guardrail: <= 1 day old mission date
EOF

zsh scripts/generate_founder_weekly_review.sh \
  --week "$PREVIOUS_WEEK" \
  --mrr "$PREVIOUS_MRR" \
  --delivery-cost "$PREVIOUS_DELIVERY_COST" \
  --acquisition-spend "$PREVIOUS_ACQUISITION_SPEND" \
  --new-customers "$PREVIOUS_NEW_CUSTOMERS" \
  --monthly-contribution "$PREVIOUS_MONTHLY_CONTRIBUTION" \
  --lifetime-months "$PREVIOUS_LIFETIME_MONTHS" \
  --fixed-cost "$PREVIOUS_FIXED_COST" \
  --price "$PREVIOUS_PRICE" \
  --variable-cost "$PREVIOUS_VARIABLE_COST" \
  --out "$previous_review_path" >/dev/null

zsh scripts/generate_founder_weekly_review.sh \
  --week "$CURRENT_WEEK" \
  --mrr "$CURRENT_MRR" \
  --delivery-cost "$CURRENT_DELIVERY_COST" \
  --acquisition-spend "$CURRENT_ACQUISITION_SPEND" \
  --new-customers "$CURRENT_NEW_CUSTOMERS" \
  --monthly-contribution "$CURRENT_MONTHLY_CONTRIBUTION" \
  --lifetime-months "$CURRENT_LIFETIME_MONTHS" \
  --fixed-cost "$CURRENT_FIXED_COST" \
  --price "$CURRENT_PRICE" \
  --variable-cost "$CURRENT_VARIABLE_COST" \
  --out "$current_review_path" >/dev/null

if [[ ! -s "$current_review_path" ]]; then
  echo "Generated current weekly review is empty."
  exit 1
fi

assert_heading "$current_review_path" "# Founder Weekly Review - ${CURRENT_WEEK}"
assert_markers "$current_review_path" "$FIXTURE_DIR/review_markers.txt" "weekly review"

zsh scripts/generate_founder_weekly_delta.sh \
  --previous "$previous_review_path" \
  --current "$current_review_path" \
  --out "$delta_path" >/dev/null

if [[ ! -s "$delta_path" ]]; then
  echo "Generated weekly delta report is empty."
  exit 1
fi

assert_heading "$delta_path" "# Founder Weekly Delta - ${PREVIOUS_WEEK} to ${CURRENT_WEEK}"
assert_markers "$delta_path" "$FIXTURE_DIR/delta_markers.txt" "weekly delta"

zsh scripts/generate_founder_scoreboard.sh \
  --week "$CURRENT_WEEK" \
  --target-mrr "$TARGET_MRR" \
  --target-margin "$TARGET_MARGIN" \
  --target-cac "$TARGET_CAC" \
  --target-ltv-cac "$TARGET_LTV_CAC" \
  --target-new-customers "$TARGET_NEW_CUSTOMERS" \
  --actual-mrr "$CURRENT_MRR" \
  --actual-margin "55.43" \
  --actual-cac "152.94" \
  --actual-ltv-cac "9.94" \
  --actual-new-customers "$CURRENT_NEW_CUSTOMERS" \
  --out "$scoreboard_path" >/dev/null

if [[ ! -s "$scoreboard_path" ]]; then
  echo "Generated founder scoreboard is empty."
  exit 1
fi

assert_heading "$scoreboard_path" "# Founder KPI Scoreboard - ${CURRENT_WEEK}"
assert_markers "$scoreboard_path" "$FIXTURE_DIR/scoreboard_markers.txt" "scoreboard"

zsh scripts/generate_founder_update_post.sh \
  --scoreboard "$scoreboard_path" \
  --delta "$delta_path" \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$post_path" >/dev/null

if [[ ! -s "$post_path" ]]; then
  echo "Generated founder update post is empty."
  exit 1
fi

assert_heading "$post_path" "# Founder Update Post Pack - ${CURRENT_WEEK}"
assert_markers "$post_path" "$FIXTURE_DIR/post_markers.txt" "update post"

zsh scripts/generate_founder_fame_pack.sh \
  --scoreboard "$scoreboard_path" \
  --delta "$delta_path" \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$fame_path" >/dev/null

if [[ ! -s "$fame_path" ]]; then
  echo "Generated founder fame pack is empty."
  exit 1
fi

assert_heading "$fame_path" "# Founder Fame Pack - ${CURRENT_WEEK}"
assert_markers "$fame_path" "$FIXTURE_DIR/fame_markers.txt" "fame pack"

zsh scripts/generate_founder_press_kit.sh \
  --fame-pack "$fame_path" \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$press_path" >/dev/null

if [[ ! -s "$press_path" ]]; then
  echo "Generated founder press kit is empty."
  exit 1
fi

assert_heading "$press_path" "# Founder Press Kit - ${CURRENT_WEEK}"
assert_markers "$press_path" "$FIXTURE_DIR/press_markers.txt" "press kit"

zsh scripts/generate_founder_media_blast.sh \
  --fame-pack "$fame_path" \
  --press-kit "$press_path" \
  --update-post "$post_path" \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$media_blast_path" >/dev/null

if [[ ! -s "$media_blast_path" ]]; then
  echo "Generated founder media blast is empty."
  exit 1
fi

assert_heading "$media_blast_path" "# Founder Media Blast - ${CURRENT_WEEK}"
assert_markers "$media_blast_path" "$FIXTURE_DIR/media_blast_markers.txt" "media blast"

zsh scripts/generate_founder_guesting_queue.sh \
  --fame-pack "$fame_path" \
  --press-kit "$press_path" \
  --media-blast "$media_blast_path" \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --outreach-sprint-completion-rate "75%" \
  --outreach-sprint-tasks-completed "6" \
  --outreach-sprint-tasks-total "8" \
  --outreach-sprint-creator-tasks-completed "4" \
  --outreach-sprint-guesting-tasks-completed "2" \
  --outreach-sprint-recommendation "Creator lane outperformed this week; keep guesting booking sequence active." \
  --cta "$CTA_TEXT" \
  --out "$guesting_queue_path" >/dev/null

if [[ ! -s "$guesting_queue_path" ]]; then
  echo "Generated founder guesting queue is empty."
  exit 1
fi

assert_heading "$guesting_queue_path" "# Founder Guesting Queue - ${CURRENT_WEEK}"
assert_markers "$guesting_queue_path" "$FIXTURE_DIR/guesting_markers.txt" "guesting queue"

zsh scripts/generate_founder_guesting_brief.sh \
  --guesting-queue "$guesting_queue_path" \
  --fame-pack "$fame_path" \
  --media-blast "$media_blast_path" \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$guesting_brief_path" >/dev/null

if [[ ! -s "$guesting_brief_path" ]]; then
  echo "Generated founder guesting sprint brief is empty."
  exit 1
fi

assert_heading "$guesting_brief_path" "# Founder Guesting Sprint Brief - ${CURRENT_WEEK}"
assert_markers "$guesting_brief_path" "$FIXTURE_DIR/guesting_brief_markers.txt" "guesting sprint brief"

zsh scripts/generate_founder_fame_interview_prep.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --press-kit "$press_path" \
  --media-blast "$media_blast_path" \
  --guesting-brief "$guesting_brief_path" \
  --out "$interview_prep_path" >/dev/null

if [[ ! -s "$interview_prep_path" ]]; then
  echo "Generated founder fame interview prep is empty."
  exit 1
fi

assert_heading "$interview_prep_path" "# Founder Fame Interview Prep: ${CURRENT_WEEK}"
assert_markers "$interview_prep_path" "$FIXTURE_DIR/interview_prep_markers.txt" "interview prep"

zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --transcript "$interview_prep_path" \
  --interview-prep "$interview_prep_path" \
  --media-blast "$media_blast_path" \
  --out "$transcript_ingestion_path" >/dev/null

if [[ ! -s "$transcript_ingestion_path" ]]; then
  echo "Generated founder fame transcript ingestion is empty."
  exit 1
fi

assert_heading "$transcript_ingestion_path" "# Founder Fame Transcript Ingestion - ${CURRENT_WEEK}"
assert_markers "$transcript_ingestion_path" "$FIXTURE_DIR/transcript_ingestion_markers.txt" "transcript ingestion"

zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --interview-prep "$interview_prep_path" \
  --transcript-ingestion "$transcript_ingestion_path" \
  --media-blast "$media_blast_path" \
  --guesting-brief "$guesting_brief_path" \
  --out "$repurpose_plan_path" >/dev/null

if [[ ! -s "$repurpose_plan_path" ]]; then
  echo "Generated founder fame repurpose plan is empty."
  exit 1
fi

assert_heading "$repurpose_plan_path" "# Founder Fame Repurpose Plan - ${CURRENT_WEEK}"
assert_markers "$repurpose_plan_path" "$FIXTURE_DIR/repurpose_markers.txt" "repurpose plan"

zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --week "$CURRENT_WEEK" \
  --campaign-dir "$TMP_DIR" \
  --out "$uplift_tracker_path" >/dev/null

if [[ ! -s "$uplift_tracker_path" ]]; then
  echo "Generated founder fame uplift tracker is empty."
  exit 1
fi

assert_heading "$uplift_tracker_path" "# Founder Fame Uplift Tracker - ${CURRENT_WEEK}"

zsh scripts/generate_founder_fame_weight_profile.sh \
  --week "$CURRENT_WEEK" \
  --campaign-dir "$TMP_DIR" \
  --uplift-tracker "$uplift_tracker_path" \
  --out "$weight_profile_path" >/dev/null

if [[ ! -s "$weight_profile_path" ]]; then
  echo "Generated founder fame weight profile is empty."
  exit 1
fi

assert_heading "$weight_profile_path" "# Founder Fame Weight Profile - ${CURRENT_WEEK}"

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --fame-pack "$fame_path" \
  --repurpose-plan "$repurpose_plan_path" \
  --transcript-ingestion "$transcript_ingestion_path" \
  --press-kit "$press_path" \
  --media-blast "$media_blast_path" \
  --weight-profile "$weight_profile_path" \
  --out "$momentum_brief_path" >/dev/null

if [[ ! -s "$momentum_brief_path" ]]; then
  echo "Generated founder fame momentum brief is empty."
  exit 1
fi

assert_heading "$momentum_brief_path" "# Founder Fame Momentum Brief - ${CURRENT_WEEK}"
assert_markers "$momentum_brief_path" "$FIXTURE_DIR/momentum_brief_markers.txt" "momentum brief"

zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --momentum-brief "$momentum_brief_path" \
  --weight-profile "$weight_profile_path" \
  --uplift-tracker "$uplift_tracker_path" \
  --out "$opportunity_radar_path" >/dev/null

if [[ ! -s "$opportunity_radar_path" ]]; then
  echo "Generated founder fame opportunity radar is empty."
  exit 1
fi

assert_heading "$opportunity_radar_path" "# Founder Fame Opportunity Radar - ${CURRENT_WEEK}"
assert_markers "$opportunity_radar_path" "$FIXTURE_DIR/opportunity_radar_markers.txt" "opportunity radar"

zsh scripts/generate_founder_fame_execution_sprint.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --opportunity-radar "$opportunity_radar_path" \
  --momentum-brief "$momentum_brief_path" \
  --out "$execution_sprint_path" >/dev/null

if [[ ! -s "$execution_sprint_path" ]]; then
  echo "Generated founder fame execution sprint is empty."
  exit 1
fi

assert_heading "$execution_sprint_path" "# Founder Fame Execution Sprint - ${CURRENT_WEEK}"
assert_markers "$execution_sprint_path" "$FIXTURE_DIR/execution_sprint_markers.txt" "execution sprint"

zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --execution-sprint "$execution_sprint_path" \
  --opportunity-radar "$opportunity_radar_path" \
  --momentum-brief "$momentum_brief_path" \
  --out "$execution_scorecard_path" >/dev/null

if [[ ! -s "$execution_scorecard_path" ]]; then
  echo "Generated founder fame execution scorecard is empty."
  exit 1
fi

assert_heading "$execution_scorecard_path" "# Founder Fame Execution Scorecard - ${CURRENT_WEEK}"
assert_markers "$execution_scorecard_path" "$FIXTURE_DIR/execution_scorecard_markers.txt" "execution scorecard"

zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --execution-scorecard "$execution_scorecard_path" \
  --execution-sprint "$execution_sprint_path" \
  --opportunity-radar "$opportunity_radar_path" \
  --momentum-brief "$momentum_brief_path" \
  --out "$risk_response_plan_path" >/dev/null

if [[ ! -s "$risk_response_plan_path" ]]; then
  echo "Generated founder fame risk response plan is empty."
  exit 1
fi

assert_heading "$risk_response_plan_path" "# Founder Fame Risk Response Plan - ${CURRENT_WEEK}"
assert_markers "$risk_response_plan_path" "$FIXTURE_DIR/risk_response_plan_markers.txt" "risk response plan"

zsh scripts/generate_founder_fame_escalation_queue.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --risk-response-plan "$risk_response_plan_path" \
  --execution-scorecard "$execution_scorecard_path" \
  --execution-sprint "$execution_sprint_path" \
  --out "$escalation_queue_path" >/dev/null

if [[ ! -s "$escalation_queue_path" ]]; then
  echo "Generated founder fame escalation queue is empty."
  exit 1
fi

assert_heading "$escalation_queue_path" "# Founder Fame Escalation Queue - ${CURRENT_WEEK}"
assert_markers "$escalation_queue_path" "$FIXTURE_DIR/escalation_queue_markers.txt" "escalation queue"

zsh scripts/generate_founder_fame_command_center.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --momentum-brief "$momentum_brief_path" \
  --execution-scorecard "$execution_scorecard_path" \
  --risk-response-plan "$risk_response_plan_path" \
  --escalation-queue "$escalation_queue_path" \
  --opportunity-radar "$opportunity_radar_path" \
  --out "$command_center_path" >/dev/null

if [[ ! -s "$command_center_path" ]]; then
  echo "Generated founder fame command center is empty."
  exit 1
fi

assert_heading "$command_center_path" "# Founder Fame Command Center - ${CURRENT_WEEK}"
assert_markers "$command_center_path" "$FIXTURE_DIR/command_center_markers.txt" "command center"

zsh scripts/generate_founder_fame_next_move_handoff.sh \
  --week "$CURRENT_WEEK" \
  --command-center "$command_center_path" \
  --artifact-link "$command_center_path" \
  --draft-pack-out "$next_move_draft_pack_path" \
  --out "$next_move_handoff_path" >/dev/null

if [[ ! -s "$next_move_handoff_path" ]]; then
  echo "Generated founder fame next-move handoff is empty."
  exit 1
fi

assert_heading "$next_move_handoff_path" "# Founder Fame Next Move Handoff - ${CURRENT_WEEK}"
if ! rg -Fq "Action: Run Fame Next Move" "$next_move_handoff_path"; then
  echo "Founder fame next-move handoff is missing in-app action guidance."
  exit 1
fi
if ! rg -Fq "Artifact link: $command_center_path" "$next_move_handoff_path"; then
  echo "Founder fame next-move handoff is missing command center artifact link wiring."
  exit 1
fi
if ! rg -Fq "X draft (<=280):" "$next_move_handoff_path"; then
  echo "Founder fame next-move handoff is missing X draft wiring."
  exit 1
fi
if ! rg -Fq "Checklist comment draft:" "$next_move_handoff_path"; then
  echo "Founder fame next-move handoff is missing checklist comment draft wiring."
  exit 1
fi

if [[ ! -s "$next_move_draft_pack_path" ]]; then
  echo "Generated founder fame next-move draft pack is empty."
  exit 1
fi

assert_heading "$next_move_draft_pack_path" "# Founder Fame Next Move Draft Pack - ${CURRENT_WEEK}"
if ! rg -Fq "Source artifact: $command_center_path" "$next_move_draft_pack_path"; then
  echo "Founder fame next-move draft pack is missing command center source artifact wiring."
  exit 1
fi
if ! rg -Fq "X:" "$next_move_draft_pack_path"; then
  echo "Founder fame next-move draft pack is missing X draft block."
  exit 1
fi
if ! rg -Fq "Checklist:" "$next_move_draft_pack_path"; then
  echo "Founder fame next-move draft pack is missing checklist draft block."
  exit 1
fi

zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --command-center "$command_center_path" \
  --momentum-brief "$momentum_brief_path" \
  --execution-scorecard "$execution_scorecard_path" \
  --risk-response-plan "$risk_response_plan_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$spotlight_pack_path" >/dev/null

if [[ ! -s "$spotlight_pack_path" ]]; then
  echo "Generated founder fame spotlight pack is empty."
  exit 1
fi

assert_heading "$spotlight_pack_path" "# Founder Fame Spotlight Pack - ${CURRENT_WEEK}"
assert_markers "$spotlight_pack_path" "$FIXTURE_DIR/spotlight_pack_markers.txt" "spotlight pack"

zsh scripts/generate_founder_fame_breakout_plan.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --spotlight-pack "$spotlight_pack_path" \
  --command-center "$command_center_path" \
  --execution-sprint "$execution_sprint_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$breakout_plan_path" >/dev/null

if [[ ! -s "$breakout_plan_path" ]]; then
  echo "Generated founder fame breakout plan is empty."
  exit 1
fi

assert_heading "$breakout_plan_path" "# Founder Fame Breakout Plan - ${CURRENT_WEEK}"
assert_markers "$breakout_plan_path" "$FIXTURE_DIR/breakout_plan_markers.txt" "breakout plan"

zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --breakout-plan "$breakout_plan_path" \
  --guesting-queue "$guesting_queue_path" \
  --media-blast "$media_blast_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$outreach_sprint_path" >/dev/null

if [[ ! -s "$outreach_sprint_path" ]]; then
  echo "Generated founder fame outreach sprint is empty."
  exit 1
fi

assert_heading "$outreach_sprint_path" "# Founder Fame Outreach Sprint - ${CURRENT_WEEK}"
assert_markers "$outreach_sprint_path" "$FIXTURE_DIR/outreach_sprint_markers.txt" "outreach sprint"

zsh scripts/generate_founder_fame_proof_loop.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --breakout-plan "$breakout_plan_path" \
  --outreach-sprint "$outreach_sprint_path" \
  --spotlight-pack "$spotlight_pack_path" \
  --command-center "$command_center_path" \
  --out "$proof_loop_path" >/dev/null

if [[ ! -s "$proof_loop_path" ]]; then
  echo "Generated founder fame proof loop is empty."
  exit 1
fi

assert_heading "$proof_loop_path" "# Founder Fame Proof Loop - ${CURRENT_WEEK}"
assert_markers "$proof_loop_path" "$FIXTURE_DIR/proof_loop_markers.txt" "proof loop"

zsh scripts/verify_founder_fame_proof_loop.sh \
  --proof-loop "$proof_loop_path" \
  --strict \
  --out "$proof_loop_check_path" >/dev/null

if [[ ! -s "$proof_loop_check_path" ]]; then
  echo "Generated founder fame proof-loop verification report is empty."
  exit 1
fi
if ! rg -Fq -- "- Status: PASS" "$proof_loop_check_path"; then
  echo "Founder fame proof-loop verification report is not passing."
  exit 1
fi

zsh scripts/generate_founder_fame_kpi_snapshot.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --proof-loop "$proof_loop_path" \
  --command-center "$command_center_path" \
  --proof-loop-check "$proof_loop_check_path" \
  --out "$kpi_snapshot_path" >/dev/null

if [[ ! -s "$kpi_snapshot_path" ]]; then
  echo "Generated founder fame KPI snapshot is empty."
  exit 1
fi

assert_heading "$kpi_snapshot_path" "# Founder Fame KPI Snapshot - ${CURRENT_WEEK}"
assert_markers "$kpi_snapshot_path" "$FIXTURE_DIR/kpi_snapshot_markers.txt" "kpi snapshot"

zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --kpi-snapshot "$kpi_snapshot_path" \
  --command-center "$command_center_path" \
  --proof-loop-check "$proof_loop_check_path" \
  --out "$velocity_scoreboard_path" >/dev/null

if [[ ! -s "$velocity_scoreboard_path" ]]; then
  echo "Generated founder fame velocity scoreboard is empty."
  exit 1
fi

assert_heading "$velocity_scoreboard_path" "# Founder Fame Velocity Scoreboard - ${CURRENT_WEEK}"
assert_markers "$velocity_scoreboard_path" "$FIXTURE_DIR/velocity_scoreboard_markers.txt" "velocity scoreboard"

zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --kpi-snapshot "$kpi_snapshot_path" \
  --velocity-scoreboard "$velocity_scoreboard_path" \
  --out "$exceptional_loop_path" >/dev/null

if [[ ! -s "$exceptional_loop_path" ]]; then
  echo "Generated founder fame exceptional loop is empty."
  exit 1
fi

assert_heading "$exceptional_loop_path" "# Founder Fame Exceptional Loop - ${CURRENT_WEEK}"
assert_markers "$exceptional_loop_path" "$FIXTURE_DIR/exceptional_loop_markers.txt" "exceptional loop"

zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
  --exceptional-loop "$exceptional_loop_path" \
  --action-queue "$action_queue_context_path" \
  --dry-run \
  --out "$exceptional_loop_comment_path" >/dev/null

if [[ ! -s "$exceptional_loop_comment_path" ]]; then
  echo "Generated founder fame exceptional-loop checklist comment draft is empty."
  exit 1
fi
assert_markers "$exceptional_loop_comment_path" "$FIXTURE_DIR/exceptional_loop_comment_markers.txt" "exceptional-loop checklist comment"
if ! rg -Fq "Daily mission freshness: Fresh (0d old)" "$exceptional_loop_comment_path"; then
  echo "Founder fame exceptional-loop checklist comment draft is missing mission freshness context."
  exit 1
fi

zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
  --exceptional-loop "$exceptional_loop_path" \
  --comment "$exceptional_loop_comment_path" \
  --out "$exceptional_loop_live_check_path" >/dev/null

if [[ ! -s "$exceptional_loop_live_check_path" ]]; then
  echo "Generated founder fame exceptional-loop live verification report is empty."
  exit 1
fi
if ! rg -Fq -- "- Mode: exceptional-loop" "$exceptional_loop_live_check_path"; then
  echo "Founder fame exceptional-loop live verification report did not run in exceptional-loop mode."
  exit 1
fi
if ! rg -Fq -- "- Result: PASS" "$exceptional_loop_live_check_path"; then
  echo "Founder fame exceptional-loop live verification report is not passing."
  exit 1
fi

zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --kpi-snapshot "$kpi_snapshot_path" \
  --proof-loop "$proof_loop_path" \
  --command-center "$command_center_path" \
  --out "$narrative_lab_path" >/dev/null

if [[ ! -s "$narrative_lab_path" ]]; then
  echo "Generated founder fame narrative lab is empty."
  exit 1
fi

assert_heading "$narrative_lab_path" "# Founder Fame Narrative Lab - ${CURRENT_WEEK}"
assert_markers "$narrative_lab_path" "$FIXTURE_DIR/narrative_lab_markers.txt" "narrative lab"

zsh scripts/generate_founder_fame_war_room.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --command-center "$command_center_path" \
  --next-move-handoff "$next_move_handoff_path" \
  --next-move-draft-pack "$next_move_draft_pack_path" \
  --proof-loop-check "$proof_loop_check_path" \
  --narrative-lab "$narrative_lab_path" \
  --out "$war_room_path" >/dev/null

if [[ ! -s "$war_room_path" ]]; then
  echo "Generated founder fame war room is empty."
  exit 1
fi

assert_heading "$war_room_path" "# Founder Fame War Room - ${CURRENT_WEEK}"
assert_markers "$war_room_path" "$FIXTURE_DIR/war_room_markers.txt" "war room"
if ! rg -Fq "Checklist target: Monday Publish Checklist ${CURRENT_WEEK}" "$war_room_path"; then
  echo "Founder fame war room is missing checklist target week expansion."
  exit 1
fi
if ! rg -Fq "Run now: Run Fame Next Move" "$war_room_path"; then
  echo "Founder fame war room is missing run-now command wiring."
  exit 1
fi

zsh scripts/verify_founder_fame_war_room.sh \
  --war-room "$war_room_path" \
  --strict \
  --out "$war_room_check_path" >/dev/null

if [[ ! -s "$war_room_check_path" ]]; then
  echo "Generated founder fame war-room verification report is empty."
  exit 1
fi
if ! rg -Fq -- "- Status: PASS" "$war_room_check_path"; then
  echo "Founder fame war-room verification report is not passing."
  exit 1
fi

zsh scripts/post_founder_fame_war_room_comment.sh \
  --war-room "$war_room_path" \
  --action-queue "$action_queue_context_path" \
  --strict \
  --dry-run \
  --out "$war_room_comment_path" >/dev/null

if [[ ! -s "$war_room_comment_path" ]]; then
  echo "Generated founder fame war-room checklist comment draft is empty."
  exit 1
fi
if ! rg -Fq "<!-- weekly-growth-founder-fame-war-room-comment -->" "$war_room_comment_path"; then
  echo "Founder fame war-room checklist comment draft is missing sync marker."
  exit 1
fi
if ! rg -Fq "Run now: Run Fame Next Move" "$war_room_comment_path"; then
  echo "Founder fame war-room checklist comment draft is missing run-now action."
  exit 1
fi
if ! rg -Fq "weekly-growth-founder-fame-war-room" "$war_room_comment_path"; then
  echo "Founder fame war-room checklist comment draft is missing marker payload block."
  exit 1
fi
if ! rg -Fq "Daily mission freshness: Fresh (0d old)" "$war_room_comment_path"; then
  echo "Founder fame war-room checklist comment draft is missing mission freshness context."
  exit 1
fi

zsh scripts/verify_founder_fame_war_room_run.sh \
  --war-room "$war_room_path" \
  --comment "$war_room_comment_path" \
  --out "$war_room_live_check_path" >/dev/null

if [[ ! -s "$war_room_live_check_path" ]]; then
  echo "Generated founder fame war-room live verification report is empty."
  exit 1
fi
if ! rg -Fq -- "- Mode: war-room" "$war_room_live_check_path"; then
  echo "Founder fame war-room live verification report did not run in war-room mode."
  exit 1
fi
if ! rg -Fq -- "- Result: PASS" "$war_room_live_check_path"; then
  echo "Founder fame war-room live verification report is not passing."
  exit 1
fi

zsh scripts/generate_founder_first48h_post_pack.sh \
  --week "$CURRENT_WEEK" \
  --product "$PRODUCT_NAME" \
  --narrative-lab "$narrative_lab_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --primary-char-limit "$first48h_primary_char_limit" \
  --backup-char-limit "$first48h_backup_char_limit" \
  --primary-tone "$first48h_primary_tone" \
  --backup-tone "$first48h_backup_tone" \
  --out "$first48h_post_pack_path" >/dev/null

if [[ ! -s "$first48h_post_pack_path" ]]; then
  echo "Generated founder first-48h post pack is empty."
  exit 1
fi

assert_heading "$first48h_post_pack_path" "# Founder First 48h Post Pack: ${CURRENT_WEEK}"
assert_markers "$first48h_post_pack_path" "$FIXTURE_DIR/first48h_post_pack_markers.txt" "first-48h post pack"
if ! rg -Fq "Primary short variant target: <=${first48h_primary_char_limit} chars" "$first48h_post_pack_path"; then
  echo "Founder first-48h post pack is missing primary char-limit rendering."
  exit 1
fi
if ! rg -Fq "Backup short variant target: <=${first48h_backup_char_limit} chars" "$first48h_post_pack_path"; then
  echo "Founder first-48h post pack is missing backup char-limit rendering."
  exit 1
fi
if ! rg -Fq "Primary tone profile: ${first48h_primary_tone}" "$first48h_post_pack_path"; then
  echo "Founder first-48h post pack is missing primary tone rendering."
  exit 1
fi
if ! rg -Fq "Backup tone profile: ${first48h_backup_tone}" "$first48h_post_pack_path"; then
  echo "Founder first-48h post pack is missing backup tone rendering."
  exit 1
fi

pack_dir="$TMP_DIR/pack"
zsh scripts/generate_founder_weekly_pack.sh \
  --week "$PACK_WEEK" \
  --previous-review "$current_review_path" \
  --mrr "$PACK_MRR" \
  --delivery-cost "$PACK_DELIVERY_COST" \
  --acquisition-spend "$PACK_ACQUISITION_SPEND" \
  --new-customers "$PACK_NEW_CUSTOMERS" \
  --monthly-contribution "$PACK_MONTHLY_CONTRIBUTION" \
  --lifetime-months "$PACK_LIFETIME_MONTHS" \
  --fixed-cost "$PACK_FIXED_COST" \
  --price "$PACK_PRICE" \
  --variable-cost "$PACK_VARIABLE_COST" \
  --target-mrr "$TARGET_MRR" \
  --target-margin "$TARGET_MARGIN" \
  --target-cac "$TARGET_CAC" \
  --target-ltv-cac "$TARGET_LTV_CAC" \
  --target-new-customers "$TARGET_NEW_CUSTOMERS" \
  --product "$PRODUCT_NAME" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out-dir "$pack_dir" >/dev/null

pack_review_path="$pack_dir/weekly-review-${PACK_WEEK}.md"
pack_delta_path="$pack_dir/weekly-delta-${PACK_WEEK}.md"
pack_scoreboard_path="$pack_dir/scoreboard-${PACK_WEEK}.md"
pack_post_path="$pack_dir/founder-update-${PACK_WEEK}.md"
pack_fame_path="$pack_dir/founder-fame-pack-${PACK_WEEK}.md"
pack_press_path="$pack_dir/founder-press-kit-${PACK_WEEK}.md"
pack_media_blast_path="$pack_dir/founder-media-blast-${PACK_WEEK}.md"
pack_guesting_queue_path="$pack_dir/founder-guesting-queue-${PACK_WEEK}.md"
pack_guesting_brief_path="$pack_dir/founder-guesting-brief-${PACK_WEEK}.md"
pack_interview_prep_path="$pack_dir/founder-fame-interview-prep-${PACK_WEEK}.md"
pack_transcript_ingestion_path="$pack_dir/founder-fame-transcript-ingestion-${PACK_WEEK}.md"
pack_repurpose_plan_path="$pack_dir/founder-fame-repurpose-plan-${PACK_WEEK}.md"
pack_uplift_tracker_path="$pack_dir/founder-fame-uplift-tracker-${PACK_WEEK}.md"
pack_weight_profile_path="$pack_dir/founder-fame-weight-profile-${PACK_WEEK}.md"
pack_momentum_brief_path="$pack_dir/founder-fame-momentum-brief-${PACK_WEEK}.md"
pack_opportunity_radar_path="$pack_dir/founder-fame-opportunity-radar-${PACK_WEEK}.md"
pack_execution_sprint_path="$pack_dir/founder-fame-execution-sprint-${PACK_WEEK}.md"
pack_execution_scorecard_path="$pack_dir/founder-fame-execution-scorecard-${PACK_WEEK}.md"
pack_risk_response_plan_path="$pack_dir/founder-fame-risk-response-plan-${PACK_WEEK}.md"
pack_escalation_queue_path="$pack_dir/founder-fame-escalation-queue-${PACK_WEEK}.md"
pack_command_center_path="$pack_dir/founder-fame-command-center-${PACK_WEEK}.md"
pack_next_move_handoff_path="$pack_dir/founder-fame-next-move-handoff-${PACK_WEEK}.md"
pack_next_move_draft_pack_path="$pack_dir/founder-fame-next-move-draft-pack-${PACK_WEEK}.md"
pack_spotlight_pack_path="$pack_dir/founder-fame-spotlight-pack-${PACK_WEEK}.md"
pack_breakout_plan_path="$pack_dir/founder-fame-breakout-plan-${PACK_WEEK}.md"
pack_outreach_sprint_path="$pack_dir/founder-fame-outreach-sprint-${PACK_WEEK}.md"
pack_proof_loop_path="$pack_dir/founder-fame-proof-loop-${PACK_WEEK}.md"
pack_proof_loop_check_path="$pack_dir/founder-fame-proof-loop-check-${PACK_WEEK}.md"
pack_kpi_snapshot_path="$pack_dir/founder-fame-kpi-snapshot-${PACK_WEEK}.md"
pack_velocity_scoreboard_path="$pack_dir/founder-fame-velocity-scoreboard-${PACK_WEEK}.md"
pack_exceptional_loop_path="$pack_dir/founder-fame-exceptional-loop-${PACK_WEEK}.md"
pack_exceptional_loop_comment_path="$pack_dir/founder-fame-exceptional-loop-comment-${PACK_WEEK}.md"
pack_exceptional_loop_live_check_path="$pack_dir/founder-fame-exceptional-loop-live-check-${PACK_WEEK}.md"
pack_narrative_lab_path="$pack_dir/founder-fame-narrative-lab-${PACK_WEEK}.md"
pack_war_room_path="$pack_dir/founder-fame-war-room-${PACK_WEEK}.md"
pack_war_room_check_path="$pack_dir/founder-fame-war-room-check-${PACK_WEEK}.md"
pack_war_room_live_check_path="$pack_dir/founder-fame-war-room-live-check-${PACK_WEEK}.md"
pack_first48h_post_pack_path="$pack_dir/founder-first48h-post-pack-${PACK_WEEK}.md"
pack_action_queue_context_path="$pack_dir/founder-fame-action-queue-context-${PACK_WEEK}.md"
cat > "$pack_action_queue_context_path" <<EOF
# Founder Fame Action Queue: ${PACK_WEEK}

## 3-Hour Mission Bridge

- Daily mission source: scripts/fixtures/founder/sample_daily_mission.md
- Mission freshness: Fresh (0d old)
- Freshness guardrail: <= 1 day old mission date
EOF

zsh scripts/generate_founder_fame_interview_prep.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --press-kit "$pack_press_path" \
  --media-blast "$pack_media_blast_path" \
  --guesting-brief "$pack_guesting_brief_path" \
  --out "$pack_interview_prep_path" >/dev/null

zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --transcript "$pack_interview_prep_path" \
  --interview-prep "$pack_interview_prep_path" \
  --media-blast "$pack_media_blast_path" \
  --out "$pack_transcript_ingestion_path" >/dev/null

zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --interview-prep "$pack_interview_prep_path" \
  --transcript-ingestion "$pack_transcript_ingestion_path" \
  --media-blast "$pack_media_blast_path" \
  --guesting-brief "$pack_guesting_brief_path" \
  --out "$pack_repurpose_plan_path" >/dev/null

zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --week "$PACK_WEEK" \
  --campaign-dir "$pack_dir" \
  --out "$pack_uplift_tracker_path" >/dev/null

zsh scripts/generate_founder_fame_weight_profile.sh \
  --week "$PACK_WEEK" \
  --campaign-dir "$pack_dir" \
  --uplift-tracker "$pack_uplift_tracker_path" \
  --out "$pack_weight_profile_path" >/dev/null

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --fame-pack "$pack_fame_path" \
  --repurpose-plan "$pack_repurpose_plan_path" \
  --transcript-ingestion "$pack_transcript_ingestion_path" \
  --press-kit "$pack_press_path" \
  --media-blast "$pack_media_blast_path" \
  --weight-profile "$pack_weight_profile_path" \
  --out "$pack_momentum_brief_path" >/dev/null

zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --momentum-brief "$pack_momentum_brief_path" \
  --weight-profile "$pack_weight_profile_path" \
  --uplift-tracker "$pack_uplift_tracker_path" \
  --out "$pack_opportunity_radar_path" >/dev/null

zsh scripts/generate_founder_fame_execution_sprint.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --opportunity-radar "$pack_opportunity_radar_path" \
  --momentum-brief "$pack_momentum_brief_path" \
  --out "$pack_execution_sprint_path" >/dev/null

zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --execution-sprint "$pack_execution_sprint_path" \
  --opportunity-radar "$pack_opportunity_radar_path" \
  --momentum-brief "$pack_momentum_brief_path" \
  --out "$pack_execution_scorecard_path" >/dev/null

zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --execution-scorecard "$pack_execution_scorecard_path" \
  --execution-sprint "$pack_execution_sprint_path" \
  --opportunity-radar "$pack_opportunity_radar_path" \
  --momentum-brief "$pack_momentum_brief_path" \
  --out "$pack_risk_response_plan_path" >/dev/null

zsh scripts/generate_founder_fame_escalation_queue.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --risk-response-plan "$pack_risk_response_plan_path" \
  --execution-scorecard "$pack_execution_scorecard_path" \
  --execution-sprint "$pack_execution_sprint_path" \
  --out "$pack_escalation_queue_path" >/dev/null

zsh scripts/generate_founder_fame_command_center.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --momentum-brief "$pack_momentum_brief_path" \
  --execution-scorecard "$pack_execution_scorecard_path" \
  --risk-response-plan "$pack_risk_response_plan_path" \
  --escalation-queue "$pack_escalation_queue_path" \
  --opportunity-radar "$pack_opportunity_radar_path" \
  --out "$pack_command_center_path" >/dev/null

zsh scripts/generate_founder_fame_next_move_handoff.sh \
  --week "$PACK_WEEK" \
  --command-center "$pack_command_center_path" \
  --artifact-link "$pack_command_center_path" \
  --draft-pack-out "$pack_next_move_draft_pack_path" \
  --out "$pack_next_move_handoff_path" >/dev/null

zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --command-center "$pack_command_center_path" \
  --momentum-brief "$pack_momentum_brief_path" \
  --execution-scorecard "$pack_execution_scorecard_path" \
  --risk-response-plan "$pack_risk_response_plan_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$pack_spotlight_pack_path" >/dev/null

zsh scripts/generate_founder_fame_breakout_plan.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --spotlight-pack "$pack_spotlight_pack_path" \
  --command-center "$pack_command_center_path" \
  --execution-sprint "$pack_execution_sprint_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$pack_breakout_plan_path" >/dev/null

zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --breakout-plan "$pack_breakout_plan_path" \
  --guesting-queue "$pack_guesting_queue_path" \
  --media-blast "$pack_media_blast_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --out "$pack_outreach_sprint_path" >/dev/null

zsh scripts/generate_founder_fame_proof_loop.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --breakout-plan "$pack_breakout_plan_path" \
  --outreach-sprint "$pack_outreach_sprint_path" \
  --spotlight-pack "$pack_spotlight_pack_path" \
  --command-center "$pack_command_center_path" \
  --out "$pack_proof_loop_path" >/dev/null

zsh scripts/verify_founder_fame_proof_loop.sh \
  --proof-loop "$pack_proof_loop_path" \
  --strict \
  --out "$pack_proof_loop_check_path" >/dev/null

zsh scripts/generate_founder_fame_kpi_snapshot.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --proof-loop "$pack_proof_loop_path" \
  --command-center "$pack_command_center_path" \
  --proof-loop-check "$pack_proof_loop_check_path" \
  --out "$pack_kpi_snapshot_path" >/dev/null

zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --kpi-snapshot "$pack_kpi_snapshot_path" \
  --command-center "$pack_command_center_path" \
  --proof-loop-check "$pack_proof_loop_check_path" \
  --out "$pack_velocity_scoreboard_path" >/dev/null

zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --kpi-snapshot "$pack_kpi_snapshot_path" \
  --velocity-scoreboard "$pack_velocity_scoreboard_path" \
  --out "$pack_exceptional_loop_path" >/dev/null

zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
  --exceptional-loop "$pack_exceptional_loop_path" \
  --action-queue "$pack_action_queue_context_path" \
  --dry-run \
  --out "$pack_exceptional_loop_comment_path" >/dev/null

zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
  --exceptional-loop "$pack_exceptional_loop_path" \
  --comment "$pack_exceptional_loop_comment_path" \
  --out "$pack_exceptional_loop_live_check_path" >/dev/null

zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --kpi-snapshot "$pack_kpi_snapshot_path" \
  --proof-loop "$pack_proof_loop_path" \
  --command-center "$pack_command_center_path" \
  --out "$pack_narrative_lab_path" >/dev/null

zsh scripts/generate_founder_fame_war_room.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --command-center "$pack_command_center_path" \
  --next-move-handoff "$pack_next_move_handoff_path" \
  --next-move-draft-pack "$pack_next_move_draft_pack_path" \
  --proof-loop-check "$pack_proof_loop_check_path" \
  --narrative-lab "$pack_narrative_lab_path" \
  --out "$pack_war_room_path" >/dev/null

zsh scripts/verify_founder_fame_war_room.sh \
  --war-room "$pack_war_room_path" \
  --strict \
  --out "$pack_war_room_check_path" >/dev/null

zsh scripts/verify_founder_fame_war_room_run.sh \
  --war-room "$pack_war_room_path" \
  --out "$pack_war_room_live_check_path" >/dev/null

zsh scripts/generate_founder_first48h_post_pack.sh \
  --week "$PACK_WEEK" \
  --product "$PRODUCT_NAME" \
  --narrative-lab "$pack_narrative_lab_path" \
  --primary-channel "$PRIMARY_CHANNEL" \
  --backup-channel "$BACKUP_CHANNEL" \
  --cta "$CTA_TEXT" \
  --primary-char-limit "$first48h_primary_char_limit" \
  --backup-char-limit "$first48h_backup_char_limit" \
  --primary-tone "$first48h_primary_tone" \
  --backup-tone "$first48h_backup_tone" \
  --out "$pack_first48h_post_pack_path" >/dev/null

for generated_file in \
  "$pack_review_path" \
  "$pack_delta_path" \
  "$pack_scoreboard_path" \
  "$pack_post_path" \
  "$pack_fame_path" \
  "$pack_press_path" \
  "$pack_media_blast_path" \
  "$pack_guesting_queue_path" \
  "$pack_guesting_brief_path" \
  "$pack_interview_prep_path" \
  "$pack_transcript_ingestion_path" \
  "$pack_repurpose_plan_path" \
  "$pack_uplift_tracker_path" \
  "$pack_weight_profile_path" \
  "$pack_momentum_brief_path" \
  "$pack_opportunity_radar_path" \
  "$pack_execution_sprint_path" \
  "$pack_execution_scorecard_path" \
  "$pack_risk_response_plan_path" \
  "$pack_escalation_queue_path" \
  "$pack_command_center_path" \
  "$pack_next_move_handoff_path" \
  "$pack_next_move_draft_pack_path" \
  "$pack_spotlight_pack_path" \
  "$pack_breakout_plan_path" \
  "$pack_outreach_sprint_path" \
  "$pack_proof_loop_path" \
  "$pack_proof_loop_check_path" \
  "$pack_kpi_snapshot_path" \
  "$pack_velocity_scoreboard_path" \
  "$pack_exceptional_loop_path" \
  "$pack_exceptional_loop_comment_path" \
  "$pack_exceptional_loop_live_check_path" \
  "$pack_narrative_lab_path" \
  "$pack_war_room_path" \
  "$pack_war_room_check_path" \
  "$pack_war_room_live_check_path" \
  "$pack_first48h_post_pack_path"; do
  if [[ ! -s "$generated_file" ]]; then
    echo "Founder pack output missing or empty: $generated_file"
    exit 1
  fi
done

assert_heading "$pack_review_path" "# Founder Weekly Review - ${PACK_WEEK}"
assert_heading "$pack_delta_path" "# Founder Weekly Delta - ${CURRENT_WEEK} to ${PACK_WEEK}"
assert_heading "$pack_scoreboard_path" "# Founder KPI Scoreboard - ${PACK_WEEK}"
assert_heading "$pack_post_path" "# Founder Update Post Pack - ${PACK_WEEK}"
assert_heading "$pack_fame_path" "# Founder Fame Pack - ${PACK_WEEK}"
assert_heading "$pack_press_path" "# Founder Press Kit - ${PACK_WEEK}"
assert_heading "$pack_media_blast_path" "# Founder Media Blast - ${PACK_WEEK}"
assert_heading "$pack_guesting_queue_path" "# Founder Guesting Queue - ${PACK_WEEK}"
assert_heading "$pack_guesting_brief_path" "# Founder Guesting Sprint Brief - ${PACK_WEEK}"
assert_heading "$pack_interview_prep_path" "# Founder Fame Interview Prep: ${PACK_WEEK}"
assert_heading "$pack_transcript_ingestion_path" "# Founder Fame Transcript Ingestion - ${PACK_WEEK}"
assert_heading "$pack_repurpose_plan_path" "# Founder Fame Repurpose Plan - ${PACK_WEEK}"
assert_heading "$pack_uplift_tracker_path" "# Founder Fame Uplift Tracker - ${PACK_WEEK}"
assert_heading "$pack_weight_profile_path" "# Founder Fame Weight Profile - ${PACK_WEEK}"
assert_heading "$pack_momentum_brief_path" "# Founder Fame Momentum Brief - ${PACK_WEEK}"
assert_heading "$pack_opportunity_radar_path" "# Founder Fame Opportunity Radar - ${PACK_WEEK}"
assert_heading "$pack_execution_sprint_path" "# Founder Fame Execution Sprint - ${PACK_WEEK}"
assert_heading "$pack_execution_scorecard_path" "# Founder Fame Execution Scorecard - ${PACK_WEEK}"
assert_heading "$pack_risk_response_plan_path" "# Founder Fame Risk Response Plan - ${PACK_WEEK}"
assert_heading "$pack_escalation_queue_path" "# Founder Fame Escalation Queue - ${PACK_WEEK}"
assert_heading "$pack_command_center_path" "# Founder Fame Command Center - ${PACK_WEEK}"
assert_heading "$pack_next_move_handoff_path" "# Founder Fame Next Move Handoff - ${PACK_WEEK}"
assert_heading "$pack_next_move_draft_pack_path" "# Founder Fame Next Move Draft Pack - ${PACK_WEEK}"
assert_heading "$pack_spotlight_pack_path" "# Founder Fame Spotlight Pack - ${PACK_WEEK}"
assert_heading "$pack_breakout_plan_path" "# Founder Fame Breakout Plan - ${PACK_WEEK}"
assert_heading "$pack_outreach_sprint_path" "# Founder Fame Outreach Sprint - ${PACK_WEEK}"
assert_heading "$pack_proof_loop_path" "# Founder Fame Proof Loop - ${PACK_WEEK}"
assert_heading "$pack_kpi_snapshot_path" "# Founder Fame KPI Snapshot - ${PACK_WEEK}"
assert_heading "$pack_velocity_scoreboard_path" "# Founder Fame Velocity Scoreboard - ${PACK_WEEK}"
assert_heading "$pack_exceptional_loop_path" "# Founder Fame Exceptional Loop - ${PACK_WEEK}"
assert_heading "$pack_narrative_lab_path" "# Founder Fame Narrative Lab - ${PACK_WEEK}"
assert_heading "$pack_war_room_path" "# Founder Fame War Room - ${PACK_WEEK}"
assert_heading "$pack_first48h_post_pack_path" "# Founder First 48h Post Pack: ${PACK_WEEK}"
assert_markers "$pack_review_path" "$FIXTURE_DIR/review_markers.txt" "pack review"
assert_markers "$pack_delta_path" "$FIXTURE_DIR/delta_markers.txt" "pack delta"
assert_markers "$pack_scoreboard_path" "$FIXTURE_DIR/scoreboard_markers.txt" "pack scoreboard"
assert_markers "$pack_post_path" "$FIXTURE_DIR/post_markers.txt" "pack update post"
assert_markers "$pack_fame_path" "$FIXTURE_DIR/fame_markers.txt" "pack fame pack"
assert_markers "$pack_press_path" "$FIXTURE_DIR/press_markers.txt" "pack press kit"
assert_markers "$pack_media_blast_path" "$FIXTURE_DIR/media_blast_markers.txt" "pack media blast"
assert_markers "$pack_guesting_queue_path" "$FIXTURE_DIR/guesting_markers.txt" "pack guesting queue"
assert_markers "$pack_guesting_brief_path" "$FIXTURE_DIR/guesting_brief_markers.txt" "pack guesting sprint brief"
assert_markers "$pack_interview_prep_path" "$FIXTURE_DIR/interview_prep_markers.txt" "pack interview prep"
assert_markers "$pack_transcript_ingestion_path" "$FIXTURE_DIR/transcript_ingestion_markers.txt" "pack transcript ingestion"
assert_markers "$pack_repurpose_plan_path" "$FIXTURE_DIR/repurpose_markers.txt" "pack repurpose plan"
assert_markers "$pack_momentum_brief_path" "$FIXTURE_DIR/momentum_brief_markers.txt" "pack momentum brief"
assert_markers "$pack_opportunity_radar_path" "$FIXTURE_DIR/opportunity_radar_markers.txt" "pack opportunity radar"
assert_markers "$pack_execution_sprint_path" "$FIXTURE_DIR/execution_sprint_markers.txt" "pack execution sprint"
assert_markers "$pack_execution_scorecard_path" "$FIXTURE_DIR/execution_scorecard_markers.txt" "pack execution scorecard"
assert_markers "$pack_risk_response_plan_path" "$FIXTURE_DIR/risk_response_plan_markers.txt" "pack risk response plan"
assert_markers "$pack_escalation_queue_path" "$FIXTURE_DIR/escalation_queue_markers.txt" "pack escalation queue"
assert_markers "$pack_command_center_path" "$FIXTURE_DIR/command_center_markers.txt" "pack command center"
if ! rg -Fq "X draft (<=280):" "$pack_next_move_handoff_path"; then
  echo "Pack founder fame next-move handoff is missing X draft wiring."
  exit 1
fi
if ! rg -Fq "Checklist:" "$pack_next_move_draft_pack_path"; then
  echo "Pack founder fame next-move draft pack is missing checklist block."
  exit 1
fi
if ! rg -Fq -- "- Status: PASS" "$pack_proof_loop_check_path"; then
  echo "Pack founder fame proof-loop verification report is not passing."
  exit 1
fi
assert_markers "$pack_spotlight_pack_path" "$FIXTURE_DIR/spotlight_pack_markers.txt" "pack spotlight pack"
assert_markers "$pack_breakout_plan_path" "$FIXTURE_DIR/breakout_plan_markers.txt" "pack breakout plan"
assert_markers "$pack_outreach_sprint_path" "$FIXTURE_DIR/outreach_sprint_markers.txt" "pack outreach sprint"
assert_markers "$pack_proof_loop_path" "$FIXTURE_DIR/proof_loop_markers.txt" "pack proof loop"
assert_markers "$pack_kpi_snapshot_path" "$FIXTURE_DIR/kpi_snapshot_markers.txt" "pack kpi snapshot"
assert_markers "$pack_velocity_scoreboard_path" "$FIXTURE_DIR/velocity_scoreboard_markers.txt" "pack velocity scoreboard"
assert_markers "$pack_exceptional_loop_path" "$FIXTURE_DIR/exceptional_loop_markers.txt" "pack exceptional loop"
assert_markers "$pack_exceptional_loop_comment_path" "$FIXTURE_DIR/exceptional_loop_comment_markers.txt" "pack exceptional-loop checklist comment"
if ! rg -Fq "Daily mission freshness: Fresh (0d old)" "$pack_exceptional_loop_comment_path"; then
  echo "Pack founder fame exceptional-loop checklist comment draft is missing mission freshness context."
  exit 1
fi
if ! rg -Fq -- "- Mode: exceptional-loop" "$pack_exceptional_loop_live_check_path"; then
  echo "Pack founder fame exceptional-loop live verification report did not run in exceptional-loop mode."
  exit 1
fi
if ! rg -Fq -- "- Result: PASS" "$pack_exceptional_loop_live_check_path"; then
  echo "Pack founder fame exceptional-loop live verification report is not passing."
  exit 1
fi
assert_markers "$pack_narrative_lab_path" "$FIXTURE_DIR/narrative_lab_markers.txt" "pack narrative lab"
assert_markers "$pack_war_room_path" "$FIXTURE_DIR/war_room_markers.txt" "pack war room"
if ! rg -Fq -- "- Status: PASS" "$pack_war_room_check_path"; then
  echo "Pack founder fame war-room verification report is not passing."
  exit 1
fi
if ! rg -Fq -- "- Mode: war-room" "$pack_war_room_live_check_path"; then
  echo "Pack founder fame war-room live verification report did not run in war-room mode."
  exit 1
fi
if ! rg -Fq -- "- Result: PASS" "$pack_war_room_live_check_path"; then
  echo "Pack founder fame war-room live verification report is not passing."
  exit 1
fi
assert_markers "$pack_first48h_post_pack_path" "$FIXTURE_DIR/first48h_post_pack_markers.txt" "pack first-48h post pack"
if ! rg -Fq "Primary short variant target: <=${first48h_primary_char_limit} chars" "$pack_first48h_post_pack_path"; then
  echo "Pack first-48h post pack is missing primary char-limit rendering."
  exit 1
fi
if ! rg -Fq "Backup short variant target: <=${first48h_backup_char_limit} chars" "$pack_first48h_post_pack_path"; then
  echo "Pack first-48h post pack is missing backup char-limit rendering."
  exit 1
fi
if ! rg -Fq "Primary tone profile: ${first48h_primary_tone}" "$pack_first48h_post_pack_path"; then
  echo "Pack first-48h post pack is missing primary tone rendering."
  exit 1
fi
if ! rg -Fq "Backup tone profile: ${first48h_backup_tone}" "$pack_first48h_post_pack_path"; then
  echo "Pack first-48h post pack is missing backup tone rendering."
  exit 1
fi

echo "Founder workflow checks passed."
