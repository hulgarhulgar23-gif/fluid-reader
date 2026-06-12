# Campaign Automation

Use this workflow to ship weekly growth content with consistent quality and almost zero prep time.

## Why

- Convert one real app outcome into Monday/Wednesday/Friday post drafts fast.
- Keep wording and CTAs consistent across channels.
- Build a repeatable social proof loop without touching app runtime code.
- Add a repeatable creator outreach loop from the same proof asset.

## Command

```sh
zsh scripts/generate_campaign_pack.sh --out docs/campaigns/$(date +%Y-W%V).md
```

This creates a campaign markdown pack with:

- Core story block (problem, outcome, metric)
- 3 weekly post drafts
- X/LinkedIn/community variants
- 24-hour reply queue prompts

For a standalone launch-day social proof bundle:

```sh
zsh scripts/generate_social_proof_kit.sh --out docs/campaigns/$(date +%Y-W%V)-social-proof.md
```

For a standalone weekly growth issue template:

```sh
zsh scripts/generate_weekly_growth_issue.sh --out docs/campaigns/$(date +%Y-W%V)-weekly-growth-issue.md
```

For a standalone founder KPI update post pack (requires generated scoreboard + delta files):

```sh
zsh scripts/generate_founder_update_post.sh \
  --scoreboard .build/founder/scoreboard-$(date +%Y-W%V).md \
  --delta .build/founder/weekly-delta-$(date +%Y-W%V).md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-update.md
```

For standalone founder fame + press + media artifacts (requires generated founder scoreboard + delta + update files):

```sh
zsh scripts/generate_founder_fame_pack.sh \
  --scoreboard .build/founder/scoreboard-$(date +%Y-W%V).md \
  --delta .build/founder/weekly-delta-$(date +%Y-W%V).md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md

zsh scripts/generate_founder_press_kit.sh \
  --fame-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-press-kit.md

zsh scripts/generate_founder_media_blast.sh \
  --fame-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md \
  --press-kit docs/campaigns/$(date +%Y-W%V)-founder-press-kit.md \
  --update-post docs/campaigns/$(date +%Y-W%V)-founder-update.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md
```

For a standalone first-24-hour reply pack:

```sh
zsh scripts/generate_first24h_reply_pack.sh --out docs/campaigns/$(date +%Y-W%V)-reply-pack.md
```

For a standalone Monday publish checkpoint (publish windows + sequence):

```sh
zsh scripts/generate_monday_publish_checkpoint.sh --out docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md
```

For a standalone creator outreach bundle:

```sh
zsh scripts/generate_creator_outreach_kit.sh --out docs/campaigns/$(date +%Y-W%V)-creator-outreach.md
```

For a standalone creator target prioritization list:

```sh
zsh scripts/generate_creator_target_list.sh --out docs/campaigns/$(date +%Y-W%V)-creator-target-list.md
```

To include creator account enrichment in that target list, pass creator-signal inputs:

```sh
zsh scripts/generate_creator_target_list.sh \
  --creator-signal-entries "7" \
  --creator-signal-high-fit "4" \
  --creator-signal-warm-intros "2" \
  --creator-signal-collab-ready "2" \
  --creator-signal-top-segment "Workflow/tutorial creators" \
  --creator-signal-top-handle "@buildwithamy" \
  --creator-signal-enrichment-score "74" \
  --out docs/campaigns/$(date +%Y-W%V)-creator-target-list.md
```

For a standalone 7-day distribution follow-up plan:

```sh
zsh scripts/generate_distribution_followup_plan.sh --out docs/campaigns/$(date +%Y-W%V)-distribution-plan.md
```

For a standalone viral experiment board (from weekly review signals):

```sh
zsh scripts/generate_viral_experiment_board.sh --out docs/campaigns/$(date +%Y-W%V)-viral-experiment-board.md
```

For a standalone weekly social proof wall (ranked proof cards + quote bank):

```sh
zsh scripts/generate_social_proof_wall.sh --out docs/campaigns/$(date +%Y-W%V)-social-proof-wall.md
```

For a standalone founder fame ops brief (single routing/proof/founder execution handoff):

```sh
zsh scripts/generate_founder_fame_ops_brief.sh \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --social-proof-wall docs/campaigns/$(date +%Y-W%V)-social-proof-wall.md \
  --fame-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --guesting-brief docs/campaigns/$(date +%Y-W%V)-founder-guesting-brief.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-ops-brief.md
```

For a standalone founder fame Monday action queue (top 3 owner-assigned actions from the ops brief):

```sh
zsh scripts/generate_founder_fame_action_queue.sh \
  --ops-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-ops-brief.md \
  --daily-mission docs/campaigns/$(date +%Y-W%V)-founder-fame-daily-mission.md \
  --require-fresh-daily-mission \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md
```

For a standalone founder fame interview prep brief (opener scripts + tough-question answers):

```sh
zsh scripts/generate_founder_fame_interview_prep.sh \
  --ops-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-ops-brief.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --press-kit docs/campaigns/$(date +%Y-W%V)-founder-press-kit.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md
```

For transcript-driven founder signal extraction (quotes/objections/clips):

```sh
zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --transcript docs/campaigns/$(date +%Y-W%V)-founder-interview-transcript.md \
  --interview-prep docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md
```

For a standalone founder fame repurpose plan (clip/thread/recap follow-through):

```sh
zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --interview-prep docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md \
  --transcript-ingestion docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --guesting-brief docs/campaigns/$(date +%Y-W%V)-founder-guesting-brief.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-repurpose-plan.md
```

For a standalone founder fame momentum brief (48-hour readiness + risk + narrative stack):

```sh
zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --campaign-dir docs/campaigns \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md

zsh scripts/generate_founder_fame_weight_profile.sh \
  --campaign-dir docs/campaigns \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --fame-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md \
  --repurpose-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-repurpose-plan.md \
  --transcript-ingestion docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md \
  --press-kit docs/campaigns/$(date +%Y-W%V)-founder-press-kit.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md
```

For a standalone founder fame opportunity radar (ranked impact/confidence/effort bets):

```sh
zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md
```

For a standalone founder fame execution sprint (day-by-day owner board from top bet + launch operations):

```sh
zsh scripts/generate_founder_fame_execution_sprint.sh \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md
```

For a standalone founder fame execution scorecard (readiness/risk scoring from sprint + launch signals):

```sh
zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md
```

For a standalone founder fame risk response plan (72-hour mitigation routing from scorecard risk flags):

```sh
zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md
```

For a standalone founder fame escalation queue (owner-routed P1/P2 actions from the risk response plan):

```sh
zsh scripts/generate_founder_fame_escalation_queue.sh \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md
```

For a standalone founder fame command center (single daily control sheet for momentum + execution + risk + escalation):

```sh
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
  --strict \
  --dry-run
```

Then run `Fame -> Run Fame Next Move` in the app and post the resulting artifact link + owner update in `Monday Publish Checklist <week>` (use the generated next-move handoff, draft-pack, and war-room blocks as ready-to-paste execution copy).

For a standalone founder fame spotlight pack (daily publish-ready scripts from command-center execution signals):

```sh
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
  --creator-target-list docs/campaigns/$(date +%Y-W%V)-creator-target-list.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
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
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md

zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-velocity-scoreboard.md

zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md \
  --proof-loop docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md
```

For a standalone credibility ledger (trust signals + objection-resolution proof):

```sh
zsh scripts/generate_credibility_ledger.sh --out docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md
```

For a standalone winning hook library (ranked hook angles + ready seeds):

```sh
zsh scripts/generate_winning_hook_library.sh --out docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md
```

## Custom Example

```sh
zsh scripts/generate_campaign_pack.sh \
  --command "Copy Win Card" \
  --problem "manual end-of-day recap writing" \
  --outcome "share-ready recap card in under 1 minute" \
  --metric "saved ~12 minutes per day" \
  --workflow "Read Selected Text|Ask Anything|Copy Win Card" \
  --cta "Try this flow and share your first card." \
  --out docs/campaigns/$(date +%Y-W%V)-win-card.md
```

## Suggested Weekly Routine

1. Generate one pack on Monday morning.
2. Edit only the metric and examples after each post.
3. Save top replies in Friday review notes.
4. Feed best hooks into next week’s pack.
5. Log creator outreach outcomes in `Monday Publish Checklist <week>` for Friday sync.
6. Use Friday channel ROI recommendation to pick Monday default draft order.
7. Generate/refresh a distribution follow-up plan before publishing.
8. Use Friday channel-mix recommendation to set primary/backup effort split for the week.
9. On manual Friday review runs, set audience regions to localize Monday publish windows.
10. Add `weekly-growth-creator-signal` comments on `Monday Publish Checklist <week>` so Friday review can auto-score creator enrichment.
11. Publish the weekly viral experiment board to lock top 3 growth tests before Monday posting.
12. Publish the weekly winning hook library to lock Hook A/B/C copy before Monday posting.
13. Publish the weekly social proof wall so proof cards and quote bank are ready for reposts.
14. Publish the weekly credibility ledger so trust proof and objection handling stay explicit.
15. Publish a Monday checkpoint so publish windows + sequence stay aligned with channel ROI signals.
16. After refreshing founder fame command center, run `Run Fame Next Move` once and log the artifact link + owner update.
17. Share founder fame velocity scoreboard and execute its priority move before opening new narrative lanes.

## Launch-Day Shortcut

For full launch execution (checks + campaign + founder update pack + founder fame/press/media packs + weekly growth issue template + social proof + first-24-hour reply pack + Monday publish checkpoint + creator outreach + creator target list + distribution follow-up + viral experiment board + social proof wall + founder fame action queue + founder interview prep + founder transcript ingestion + founder repurpose plan + founder uplift tracker + founder adaptive weight profile + founder momentum brief + founder opportunity radar + founder execution sprint + founder execution scorecard + founder risk response plan + founder escalation queue + founder command center + founder next-move handoff + founder next-move draft pack + founder war room + founder war-room verification + founder war-room checklist comment draft + founder spotlight pack + founder breakout plan + founder outreach sprint + founder proof loop + founder proof loop verification + founder KPI snapshot + founder fame velocity scoreboard + founder fame exceptional loop + founder fame exceptional-loop checklist comment draft + founder narrative lab + winning hook library + credibility ledger + brief):

```sh
zsh scripts/run_launch_day.sh \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --founder-transcript docs/campaigns/$(date +%Y-W%V)-founder-interview-transcript.md
```

Add `--post-founder-fame-war-room-comment` to perform live war-room checklist comment upsert.
Add `--post-founder-fame-exceptional-loop-comment` to perform live exceptional-loop checklist comment upsert.
By default, launch-day runs still render both checklist comment draft artifacts for manual review.

For remote/manual runs, use
[`Launch Pack Generator`](../.github/workflows/launch-pack.yml) in GitHub Actions.

Use this with:

- [WEEKLY_POST_PLANNER.md](WEEKLY_POST_PLANNER.md)
- [DISTRIBUTION_PLAYBOOK.md](DISTRIBUTION_PLAYBOOK.md)
- [GROWTH_RELEASE_CHECKLIST.md](GROWTH_RELEASE_CHECKLIST.md)
- [LAUNCH_DAY_PLAN.md](LAUNCH_DAY_PLAN.md)
- [WEEKLY_GROWTH_AUTOPILOT.md](WEEKLY_GROWTH_AUTOPILOT.md)
- [CREATOR_OUTREACH_KIT.md](CREATOR_OUTREACH_KIT.md)
- [CREATOR_TARGET_LIST.md](CREATOR_TARGET_LIST.md)
- [FOUNDER_FAME_OUTREACH_SPRINT.md](FOUNDER_FAME_OUTREACH_SPRINT.md)
- [FOUNDER_FAME_PROOF_LOOP.md](FOUNDER_FAME_PROOF_LOOP.md)
