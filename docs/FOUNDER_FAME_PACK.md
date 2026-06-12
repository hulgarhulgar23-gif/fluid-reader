# Founder Fame Pack

Use this workflow to generate a distribution-ready founder launch brief from your weekly scoreboard and delta reports.

## Generate Fame Pack

```sh
zsh scripts/generate_founder_fame_pack.sh \
  --scoreboard .build/founder/scoreboard-2026-W23.md \
  --delta .build/founder/weekly-delta-2026-W23.md \
  --out .build/founder/founder-fame-pack-2026-W23.md
```

The generated markdown includes:

- Momentum score and tier (`Early`, `Rising`, `Breakout`)
- KPI proof stack (MRR, CAC, LTV/CAC + signals)
- Primary + backup channel post drafts
- A 7-day fame sprint plan
- Reply seeds for common community questions

After generating a fame pack, you can generate a founder press kit from it:

```sh
zsh scripts/generate_founder_press_kit.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --out .build/founder/founder-press-kit-2026-W23.md
```

Then generate a media blast execution plan:

```sh
zsh scripts/generate_founder_media_blast.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --update-post .build/founder/founder-update-2026-W23.md \
  --out .build/founder/founder-media-blast-2026-W23.md
```

Then generate a founder guesting queue from fame + press + media artifacts:

```sh
zsh scripts/generate_founder_guesting_queue.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-queue-2026-W23.md
```

Then generate a founder guesting sprint brief from the queue:

```sh
zsh scripts/generate_founder_guesting_brief.sh \
  --guesting-queue .build/founder/founder-guesting-queue-2026-W23.md \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-brief-2026-W23.md
```

If you also produce founder fame ops + action artifacts, generate interview prep:

```sh
zsh scripts/generate_founder_fame_interview_prep.sh \
  --ops-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-ops-brief.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md
```

Then ingest transcript-level quote/objection/clip signals:

```sh
zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --transcript docs/campaigns/$(date +%Y-W%V)-founder-interview-transcript.md \
  --interview-prep docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md
```

Then generate a founder repurpose plan from interview + media artifacts:

```sh
zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --interview-prep docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md \
  --transcript-ingestion docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-repurpose-plan.md
```

Then generate a founder momentum brief to lock the next 48-hour execution focus:

```sh
zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --campaign-dir docs/campaigns \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md

zsh scripts/generate_founder_fame_weight_profile.sh \
  --campaign-dir docs/campaigns \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --repurpose-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-repurpose-plan.md \
  --transcript-ingestion docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md

zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md

zsh scripts/generate_founder_fame_execution_sprint.sh \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md

zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md

zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md

zsh scripts/generate_founder_fame_escalation_queue.sh \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md

zsh scripts/generate_founder_fame_command_center.sh \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --escalation-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md

zsh scripts/generate_founder_fame_next_move_handoff.sh \
  --week "$(date +%Y-W%V)" \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --artifact-link docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md

zsh scripts/generate_founder_fame_next_move_draft_pack.sh \
  --week "$(date +%Y-W%V)" \
  --next-move-handoff docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-draft-pack.md

zsh scripts/generate_founder_fame_war_room.sh \
  --week "$(date +%Y-W%V)" \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --next-move-handoff docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md \
  --next-move-draft-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-draft-pack.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --narrative-lab docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md

zsh scripts/post_founder_fame_war_room_comment.sh \
  --war-room docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --strict \
  --dry-run

zsh scripts/verify_founder_fame_war_room_run.sh \
  --war-room docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md \
  --comment docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room-comment.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room-live-check.md

zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md

zsh scripts/generate_founder_fame_breakout_plan.sh \
  --spotlight-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md

zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --breakout-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md \
  --guesting-queue .build/founder/founder-guesting-queue-$(date +%Y-W%V).md \
  --creator-target-list docs/campaigns/$(date +%Y-W%V)-creator-target-list.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --media-blast .build/founder/founder-media-blast-$(date +%Y-W%V).md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-outreach-sprint.md

zsh scripts/generate_founder_fame_proof_loop.sh \
  --week "$(date +%Y-W%V)" \
  --breakout-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md \
  --outreach-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-outreach-sprint.md \
  --spotlight-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md

zsh scripts/generate_founder_fame_kpi_snapshot.sh \
  --week "$(date +%Y-W%V)" \
  --proof-loop docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md

zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-velocity-scoreboard.md

zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md \
  --velocity-scoreboard docs/campaigns/$(date +%Y-W%V)-founder-fame-velocity-scoreboard.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-exceptional-loop.md

zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
  --exceptional-loop docs/campaigns/$(date +%Y-W%V)-founder-fame-exceptional-loop.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --dry-run \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-exceptional-loop-comment.md

zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
  --exceptional-loop docs/campaigns/$(date +%Y-W%V)-founder-fame-exceptional-loop.md \
  --comment docs/campaigns/$(date +%Y-W%V)-founder-fame-exceptional-loop-comment.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-exceptional-loop-live-check.md

zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md \
  --velocity-scoreboard docs/campaigns/$(date +%Y-W%V)-founder-fame-velocity-scoreboard.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md

zsh scripts/generate_founder_first48h_post_pack.sh \
  --week "$(date +%Y-W%V)" \
  --narrative-lab docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "If you're building, reply with your KPI bottleneck and I'll share the exact command flow." \
  --primary-char-limit 280 \
  --backup-char-limit 500 \
  --primary-tone x-punchy \
  --backup-tone linkedin-context \
  --out docs/campaigns/$(date +%Y-W%V)-founder-first48h-post-pack.md
```

## One-Command Flow

Run the full weekly pipeline (review, delta, scoreboard, update post, fame pack):

```sh
zsh scripts/generate_founder_weekly_pack.sh --help
```

## CI / Artifact Flow

To generate founder artifacts from a GitHub Actions form (without local setup), run:

- [`Founder Fame Pack`](../.github/workflows/founder-fame-pack.yml)

This workflow also has a weekly schedule trigger and uses fixture defaults when no manual inputs are provided.
You can optionally pass repo-relative markdown overlays for:

- `creator_target_list` (used by founder outreach sprint lane routing)
- `distribution_plan` (used by founder breakout + outreach lane routing)
- `founder_fame_action_queue` (used to mirror daily mission source/freshness into war-room + exceptional-loop checklist comments)
- `post_war_room_comment` + `war_room_comment_issue` (enables checklist upsert and strict war-room live verification in the same run)
- `post_exceptional_loop_comment` + `exceptional_loop_comment_issue` (enables checklist upsert and strict live verification in the same run)

## Related Guides

- [FOUNDER_WEEKLY_REVIEW.md](FOUNDER_WEEKLY_REVIEW.md)
- [FOUNDER_SCOREBOARD.md](FOUNDER_SCOREBOARD.md)
- [FOUNDER_UPDATE_POST.md](FOUNDER_UPDATE_POST.md)
- [FOUNDER_PRESS_KIT.md](FOUNDER_PRESS_KIT.md)
- [FOUNDER_MEDIA_BLAST.md](FOUNDER_MEDIA_BLAST.md)
- [FOUNDER_GUESTING_QUEUE.md](FOUNDER_GUESTING_QUEUE.md)
- [FOUNDER_FAME_EXCEPTIONAL_LOOP.md](FOUNDER_FAME_EXCEPTIONAL_LOOP.md)
- [FOUNDER_GUESTING_BRIEF.md](FOUNDER_GUESTING_BRIEF.md)
- [FOUNDER_FAME_INTERVIEW_PREP.md](FOUNDER_FAME_INTERVIEW_PREP.md)
- [FOUNDER_FAME_TRANSCRIPT_INGESTION.md](FOUNDER_FAME_TRANSCRIPT_INGESTION.md)
- [FOUNDER_FAME_REPURPOSE_PLAN.md](FOUNDER_FAME_REPURPOSE_PLAN.md)
- [FOUNDER_FAME_UPLIFT_TRACKER.md](FOUNDER_FAME_UPLIFT_TRACKER.md)
- [FOUNDER_FAME_WEIGHT_PROFILE.md](FOUNDER_FAME_WEIGHT_PROFILE.md)
- [FOUNDER_FAME_MOMENTUM_BRIEF.md](FOUNDER_FAME_MOMENTUM_BRIEF.md)
- [FOUNDER_FAME_OPPORTUNITY_RADAR.md](FOUNDER_FAME_OPPORTUNITY_RADAR.md)
- [FOUNDER_FAME_EXECUTION_SPRINT.md](FOUNDER_FAME_EXECUTION_SPRINT.md)
- [FOUNDER_FAME_EXECUTION_SCORECARD.md](FOUNDER_FAME_EXECUTION_SCORECARD.md)
- [FOUNDER_FAME_RISK_RESPONSE_PLAN.md](FOUNDER_FAME_RISK_RESPONSE_PLAN.md)
- [FOUNDER_FAME_ESCALATION_QUEUE.md](FOUNDER_FAME_ESCALATION_QUEUE.md)
- [FOUNDER_FAME_COMMAND_CENTER.md](FOUNDER_FAME_COMMAND_CENTER.md)
- [FOUNDER_FAME_WAR_ROOM.md](FOUNDER_FAME_WAR_ROOM.md)
- [FOUNDER_FAME_SPOTLIGHT_PACK.md](FOUNDER_FAME_SPOTLIGHT_PACK.md)
- [FOUNDER_FAME_BREAKOUT_PLAN.md](FOUNDER_FAME_BREAKOUT_PLAN.md)
- [FOUNDER_FAME_OUTREACH_SPRINT.md](FOUNDER_FAME_OUTREACH_SPRINT.md)
- [FOUNDER_FAME_PROOF_LOOP.md](FOUNDER_FAME_PROOF_LOOP.md)
- [FOUNDER_FAME_KPI_SNAPSHOT.md](FOUNDER_FAME_KPI_SNAPSHOT.md)
- [FOUNDER_FAME_VELOCITY_SCOREBOARD.md](FOUNDER_FAME_VELOCITY_SCOREBOARD.md)
- [FOUNDER_FAME_NARRATIVE_LAB.md](FOUNDER_FAME_NARRATIVE_LAB.md)
- [FOUNDER_FIRST48H_POST_PACK.md](FOUNDER_FIRST48H_POST_PACK.md)
