# Launch Day Plan

Use this timeline to run a practical launch day that maximizes discovery and reply quality.

## One-Command Start

```sh
zsh scripts/run_launch_day.sh --primary-channel "X / Threads" --backup-channel "LinkedIn"
```

Optional mission bridge input:

```sh
zsh scripts/run_launch_day.sh --primary-channel "X / Threads" --backup-channel "LinkedIn" --founder-fame-daily-mission docs/campaigns/$(date +%Y-W%V)-founder-fame-daily-mission.md
```

This runs launch checks and generates:

- `docs/campaigns/<week>-launch.md`
- `docs/campaigns/<week>-founder-update.md`
- `docs/campaigns/<week>-founder-fame-pack.md`
- `docs/campaigns/<week>-founder-press-kit.md`
- `docs/campaigns/<week>-founder-media-blast.md`
- `docs/campaigns/<week>-weekly-growth-issue.md`
- `docs/campaigns/<week>-social-proof.md`
- `docs/campaigns/<week>-reply-pack.md`
- `docs/campaigns/<week>-monday-checkpoint.md`
- `docs/campaigns/<week>-creator-outreach.md`
- `docs/campaigns/<week>-creator-target-list.md`
- `docs/campaigns/<week>-distribution-plan.md`
- `docs/campaigns/<week>-viral-experiment-board.md`
- `docs/campaigns/<week>-social-proof-wall.md`
- `docs/campaigns/<week>-founder-fame-ops-brief.md`
- `docs/campaigns/<week>-founder-fame-action-queue.md`
- `docs/campaigns/<week>-founder-fame-interview-prep.md`
- `docs/campaigns/<week>-founder-fame-transcript-ingestion.md`
- `docs/campaigns/<week>-founder-fame-repurpose-plan.md`
- `docs/campaigns/<week>-founder-fame-uplift-tracker.md`
- `docs/campaigns/<week>-founder-fame-weight-profile.md`
- `docs/campaigns/<week>-founder-fame-momentum-brief.md`
- `docs/campaigns/<week>-founder-fame-opportunity-radar.md`
- `docs/campaigns/<week>-founder-fame-execution-sprint.md`
- `docs/campaigns/<week>-founder-fame-execution-scorecard.md`
- `docs/campaigns/<week>-founder-fame-risk-response-plan.md`
- `docs/campaigns/<week>-founder-fame-escalation-queue.md`
- `docs/campaigns/<week>-founder-fame-command-center.md`
- `docs/campaigns/<week>-founder-fame-next-move-handoff.md`
- `docs/campaigns/<week>-founder-fame-next-move-draft-pack.md`
- `docs/campaigns/<week>-founder-fame-war-room.md`
- `docs/campaigns/<week>-founder-fame-war-room-check.md`
- `docs/campaigns/<week>-founder-fame-war-room-comment.md`
- `docs/campaigns/<week>-founder-fame-war-room-live-check.md`
- `docs/campaigns/<week>-founder-fame-spotlight-pack.md`
- `docs/campaigns/<week>-founder-fame-breakout-plan.md`
- `docs/campaigns/<week>-founder-fame-outreach-sprint.md`
- `docs/campaigns/<week>-founder-fame-proof-loop.md`
- `docs/campaigns/<week>-founder-fame-proof-loop-check.md`
- `docs/campaigns/<week>-founder-fame-kpi-snapshot.md`
- `docs/campaigns/<week>-founder-fame-velocity-scoreboard.md`
- `docs/campaigns/<week>-founder-fame-exceptional-loop.md`
- `docs/campaigns/<week>-founder-fame-exceptional-loop-comment.md`
- `docs/campaigns/<week>-founder-fame-exceptional-loop-live-check.md`
- `docs/campaigns/<week>-founder-fame-narrative-lab.md`
- `docs/campaigns/<week>-winning-hook-library.md`
- `docs/campaigns/<week>-credibility-ledger.md`
- `docs/campaigns/<week>-launch-brief.md`

You can also trigger
[`Launch Pack Generator`](../.github/workflows/launch-pack.yml) manually in GitHub Actions.

## Goal

- Ship one clear value message.
- Show one real proof asset.
- Convert replies into follow-up usage stories.

## T-24 Hours: Prep

1. Run:
   - `zsh scripts/run_launch_day.sh --primary-channel "X / Threads" --backup-channel "LinkedIn"`
2. Confirm generated campaign, founder-update, founder-fame-pack, founder-press-kit, founder-media-blast, weekly-growth-issue, social-proof, reply-pack, monday-checkpoint, creator-outreach, creator-target-list, distribution-plan, viral-experiment-board, social-proof-wall, founder-fame-ops-brief, founder-fame-action-queue, founder-fame-interview-prep, founder-fame-transcript-ingestion, founder-fame-repurpose-plan, founder-fame-uplift-tracker, founder-fame-weight-profile, founder-fame-momentum-brief, founder-fame-opportunity-radar, founder-fame-execution-sprint, founder-fame-execution-scorecard, founder-fame-risk-response-plan, founder-fame-escalation-queue, founder-fame-command-center, founder-fame-next-move-handoff, founder-fame-next-move-draft-pack, founder-fame-war-room, founder-fame-war-room-check, founder-fame-war-room-comment, founder-fame-war-room-live-check, founder-fame-spotlight-pack, founder-fame-breakout-plan, founder-fame-outreach-sprint, founder-fame-proof-loop, founder-fame-proof-loop-check, founder-fame-kpi-snapshot, founder-fame-velocity-scoreboard, founder-fame-exceptional-loop, founder-fame-exceptional-loop-comment, founder-fame-exceptional-loop-live-check, founder-fame-narrative-lab, winning-hook-library, credibility-ledger, and brief files look correct.
3. Finalize one screenshot or one `Copy Win Card` asset.
4. Pick one primary channel and one backup channel.
5. If available, apply Friday `channel-mix recommendation` to set effort split before posting.
6. If available, pass Friday creator signal inputs (`--creator-signal-*`) so launch-day target ranking uses latest enriched handles.
7. If you have a real founder interview transcript, pass `--founder-transcript docs/campaigns/<week>-founder-interview-transcript.md` so transcript ingestion and momentum scoring use real speaker/timecode signals instead of interview-prep fallback.
8. If you have an in-app daily mission artifact, pass `--founder-fame-daily-mission docs/campaigns/<week>-founder-fame-daily-mission.md`; launch-day now enforces freshness and fails fast when the mission date is stale/unparseable.
9. For live checklist upsert, pass `--post-founder-fame-war-room-comment` (and optionally `--founder-fame-war-room-comment-issue <number>` or `--founder-fame-war-room-comment-repo <owner/repo>`).
10. For exceptional-loop checklist upsert, pass `--post-founder-fame-exceptional-loop-comment` (and optionally `--founder-fame-exceptional-loop-comment-issue <number>` or `--founder-fame-exceptional-loop-comment-repo <owner/repo>`).
11. Confirm `docs/campaigns/<week>-founder-fame-war-room-live-check.md` reports `- Result: PASS`; this runs in strict mode when war-room comment upsert is enabled.
12. Confirm `docs/campaigns/<week>-founder-fame-exceptional-loop-live-check.md` reports `- Result: PASS`; this runs in strict mode when exceptional-loop comment upsert is enabled.

## T-3 Hours: Final QA

1. Re-run `zsh scripts/check_fast.sh`.
2. Confirm 60-second activation flow is still accurate.
3. Verify links in posts point to current docs.
4. Prepare first 3 replies using `docs/DISTRIBUTION_PLAYBOOK.md`.

## T0: Launch Post

Post order (recommended):

1. Primary channel launch post (proof-first).
2. Secondary channel short variant.
3. One practical community comment with exact command flow.

Launch post should include:

- One problem statement.
- One command spotlight.
- One measurable outcome.
- One explicit CTA.

## T+2 Hours: Engage

1. Reply to every practical question.
2. Offer exact command sequence when asked.
3. Collect top objections and repeated confusion points.
4. Use `docs/campaigns/<week>-reply-pack.md` for first-wave replies.
5. Use `docs/campaigns/<week>-monday-checkpoint.md` to confirm sequencing windows if timing shifts.
6. Execute Day 0 to Day 1 actions in `docs/campaigns/<week>-distribution-plan.md`.

## T+24 Hours: Capture Learnings

1. Add top replies/questions to the weekly planner review.
2. Open a `Win story` issue for best user outcomes.
3. Seed weekly execution tracking from `docs/campaigns/<week>-weekly-growth-issue.md`.
4. Publish founder KPI update using `docs/campaigns/<week>-founder-update.md`.
5. Publish founder fame + press + media sequence from generated founder artifacts.
6. Assign owners and complete top 3 founder actions from `docs/campaigns/<week>-founder-fame-action-queue.md`.
7. Rehearse 10-second + 30-second opener from `docs/campaigns/<week>-founder-fame-interview-prep.md`.
8. Finalize quote + clip priorities from `docs/campaigns/<week>-founder-fame-transcript-ingestion.md`.
9. Publish one founder clip/thread from `docs/campaigns/<week>-founder-fame-repurpose-plan.md`.
10. Refresh uplift multipliers from `docs/campaigns/<week>-founder-fame-uplift-tracker.md` before lock-in.
11. Post one founder momentum summary from `docs/campaigns/<week>-founder-fame-momentum-brief.md`.
12. Execute the top-ranked bet from `docs/campaigns/<week>-founder-fame-opportunity-radar.md`.
13. Run Day 0 to Day 6 owner checkpoints from `docs/campaigns/<week>-founder-fame-execution-sprint.md`.
14. Resolve the highest risk flag from `docs/campaigns/<week>-founder-fame-execution-scorecard.md`.
15. Execute P1 and P2 mitigations from `docs/campaigns/<week>-founder-fame-risk-response-plan.md`.
16. Execute the top two owner-routed actions from `docs/campaigns/<week>-founder-fame-escalation-queue.md`, run the standup from `docs/campaigns/<week>-founder-fame-command-center.md`, and log one owner update + artifact link from `docs/campaigns/<week>-founder-fame-next-move-handoff.md` using the generated checklist comment in `docs/campaigns/<week>-founder-fame-war-room-comment.md`.
17. Publish one proof-first spotlight post from `docs/campaigns/<week>-founder-fame-spotlight-pack.md`.
18. Execute Day 0 to Day 1 script blocks from `docs/campaigns/<week>-founder-fame-breakout-plan.md`.
19. Run creator + guesting outreach waves from `docs/campaigns/<week>-founder-fame-outreach-sprint.md`.
20. Run a Day 0 to Day 2 standup from `docs/campaigns/<week>-founder-fame-proof-loop.md` and log one conversion signal.
21. Share `docs/campaigns/<week>-founder-fame-kpi-snapshot.md` with founder + growth owners before next standup.
22. Share `docs/campaigns/<week>-founder-fame-velocity-scoreboard.md` and execute the listed priority move.
23. Run `docs/campaigns/<week>-founder-fame-exceptional-loop.md` as the next 72-hour owner loop.
24. Lock this week’s route winner from `docs/campaigns/<week>-founder-fame-narrative-lab.md` before secondary channel posting.
25. Send creator follow-ups using the generated outreach tracker.
26. Convert one repeated question into docs update.
27. Queue repost slots from `docs/campaigns/<week>-social-proof-wall.md`.
28. Lock next-week Hook A/B/C defaults using `docs/campaigns/<week>-winning-hook-library.md`.
29. Publish one credibility follow-up using `docs/campaigns/<week>-credibility-ledger.md`.

## Metrics Snapshot

Track within first 24 hours:

- Post impressions/views
- Replies/comments
- Saves/bookmarks
- Click-through to repository/docs
- New user win stories collected
