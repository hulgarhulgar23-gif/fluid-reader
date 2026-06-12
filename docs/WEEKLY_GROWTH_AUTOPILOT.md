# Weekly Growth Autopilot

Use this to keep growth execution running every week with minimal manual effort.

## What runs automatically

### Monday planning autopilot

The GitHub Actions workflow
[`weekly-growth-sprint.yml`](../.github/workflows/weekly-growth-sprint.yml)
runs every Monday and can also be triggered manually.

It generates:

- A weekly campaign draft markdown file.
- A weekly growth sprint issue body.
- A repository issue titled `Weekly Growth Sprint <week>`.
- Auto-filled previous-week KPI snapshot when prior sprint data exists.
- Week-over-week KPI deltas vs a baseline week when two prior sprint issues exist.
- Automatic labels (`growth`, `weekly-sprint`, `autopilot`) on that issue.
- Automatic close-out of older open weekly sprint issues.
- Downloadable workflow artifacts.

### Friday review autopilot

The GitHub Actions workflow
[`weekly-growth-review.yml`](../.github/workflows/weekly-growth-review.yml)
runs every Friday and can also be triggered manually.

It generates:

- A weekly review artifact markdown file.
- A scored KPI review comment inside the active weekly sprint issue.
- Priority actions for the next 7 days when targets are missed.
- Next-week hook candidates based on strongest metric momentum.
- Sprint health labels on the sprint issue (`growth-watch` or `growth-highlight`).
- Monday-ready post drafts auto-generated from `Growth Highlight Plan <week>` issue body.
- Monday draft comment/artifact auto-seeded from Friday `Default Publish Drafts (Auto-Promoted)` when review scripts are available.
- Monday draft markdown artifact in `.build/growth/<week>-monday-draft.md`.
- Auto-managed issue: `Monday Publish Checklist <week>` for exceptional sprints.
- Monday timing checkpoint artifact in `.build/growth/<week>-monday-checkpoint.md`.
- Monday timing checkpoint comment auto-updated in `Monday Publish Checklist <week>`.
- Monday timing checkpoint includes ROI-aware launch sequence (lead channel + publish order).
- Monday timing checkpoint supports audience-region windows (`global/us/eu/apac`) from manual review inputs.
- First-24-hour reply pack artifact in `.build/growth/<week>-reply-pack.md`.
- Channel-specific reply variants (A/B/C) in the reply pack based on strongest metric + primary/backup channel.
- First-24-hour reply pack comment auto-updated in `Monday Publish Checklist <week>`.
- Social proof kit artifact in `.build/growth/<week>-social-proof.md`.
- Social proof kit comment auto-updated in `Monday Publish Checklist <week>`.
- Social proof wall artifact in `.build/growth/<week>-social-proof-wall.md`.
- Social proof wall comment auto-updated in `Monday Publish Checklist <week>`.
- Credibility ledger artifact in `.build/growth/<week>-credibility-ledger.md`.
- Credibility ledger comment auto-updated in `Monday Publish Checklist <week>`.
- Creator outreach kit artifact in `.build/growth/<week>-creator-outreach.md`.
- Creator outreach kit comment auto-updated in `Monday Publish Checklist <week>`.
- Creator target list artifact in `.build/growth/<week>-creator-target-list.md`.
- Creator target list comment auto-updated in `Monday Publish Checklist <week>`.
- Creator signal comment parser (`weekly-growth-creator-signal`) auto-extracts handle-level fit signals from previous Monday checklist comments.
- Creator signal enrichment metrics (entries/high-fit/warm-intro/collab-ready/top segment/top handle/score) auto-injected into Friday review, sprint sync block, and creator target ranking.
- Distribution follow-up plan artifact in `.build/growth/<week>-distribution-plan.md`.
- Distribution follow-up plan comment auto-updated in `Monday Publish Checklist <week>`.
- Viral experiment board artifact in `.build/growth/<week>-viral-experiment-board.md`.
- Viral experiment board comment auto-updated in `Monday Publish Checklist <week>`.
- Winning hook library artifact in `.build/growth/<week>-winning-hook-library.md`.
- Winning hook library comment auto-updated in `Monday Publish Checklist <week>`.
- Founder fame pack artifact in `.build/founder/founder-fame-pack-<week>.md`.
- Founder press kit artifact in `.build/founder/founder-press-kit-<week>.md`.
- Founder media blast artifact in `.build/founder/founder-media-blast-<week>.md`.
- Founder guesting queue artifact in `.build/founder/founder-guesting-queue-<week>.md`.
- Founder guesting sprint brief artifact in `.build/founder/founder-guesting-brief-<week>.md`.
- Founder fame ops brief artifact in `.build/founder/founder-fame-ops-brief-<week>.md`.
- Founder fame action queue artifact in `.build/founder/founder-fame-action-queue-<week>.md`.
- Founder fame interview prep artifact in `.build/founder/founder-fame-interview-prep-<week>.md`.
- Founder fame transcript ingestion artifact in `.build/founder/founder-fame-transcript-ingestion-<week>.md`.
- Founder fame repurpose plan artifact in `.build/founder/founder-fame-repurpose-plan-<week>.md`.
- Founder fame uplift tracker artifact in `.build/founder/founder-fame-uplift-tracker-<week>.md`.
- Founder fame weight profile artifact in `.build/founder/founder-fame-weight-profile-<week>.md`.
- Founder fame momentum brief artifact in `.build/founder/founder-fame-momentum-brief-<week>.md`.
- Founder fame command center artifact in `.build/founder/founder-fame-command-center-<week>.md`.
- Founder fame spotlight pack artifact in `.build/founder/founder-fame-spotlight-pack-<week>.md`.
- Founder fame breakout plan artifact in `.build/founder/founder-fame-breakout-plan-<week>.md`.
- Founder fame outreach sprint artifact in `.build/founder/founder-fame-outreach-sprint-<week>.md`.
- Founder fame proof loop artifact in `.build/founder/founder-fame-proof-loop-<week>.md`.
- Founder fame proof loop verification artifact in `.build/founder/founder-fame-proof-loop-check-<week>.md`.
- Founder fame KPI snapshot artifact in `.build/founder/founder-fame-kpi-snapshot-<week>.md`.
- Founder fame velocity scoreboard artifact in `.build/founder/founder-fame-velocity-scoreboard-<week>.md`.
- Founder fame exceptional loop artifact in `.build/founder/founder-fame-exceptional-loop-<week>.md`.
- Founder fame exceptional-loop checklist comment artifact in `.build/founder/founder-fame-exceptional-loop-comment-<week>.md`.
- Founder fame narrative lab artifact in `.build/founder/founder-fame-narrative-lab-<week>.md`.
- Founder first-48h post pack artifact in `.build/founder/founder-first48h-post-pack-<week>.md`.
- Founder fame/press/media/guesting/ops/action/interview/transcript-ingestion/repurpose/momentum/command-center/spotlight/breakout/outreach/proof-loop/kpi-snapshot/velocity-scoreboard/exceptional-loop/narrative-lab comments auto-updated in `Monday Publish Checklist <week>`.
- Founder first-48h post pack comment auto-updated in `Monday Publish Checklist <week>`.
- Founder first-48h route controls block (`weekly-growth-founder-first48h-controls-start`) auto-synced into `Monday Publish Checklist <week>` issue body for publish-time routing context.
- Founder guesting signal comment parser (`weekly-growth-founder-guesting-signal`) auto-extracts target-level booking signals from previous Monday checklist comments.
- Founder guesting enrichment metrics (entries/replied/booked/published/top format/top target/score) auto-injected into weekly guesting queue scoring.
- Founder narrative route parser (`weekly-growth-founder-fame-narrative-lab`) auto-extracts priority route + fame velocity + launch posture from previous Monday checklist comments.
- Founder narrative controls fallback parser (`weekly-growth-founder-first48h-controls-start/end`) auto-backfills route alignment/lane-status/guardrail/control recommendation + first-48h execution plan from checklist issue body when narrative-lab comment fields are missing.
- Founder narrative route metrics (winner/trend/fame velocity/recommendation + route mode/alignment target/lane status/guardrail/control recommendation) auto-injected into Friday review + sprint effectiveness sync block.
- Monday checklist auto-routes defaults with founder narrative winner signals and logs `Narrative route preferred variant` + routing action/reason.
- Founder fame opportunity radar now applies narrative-route weighted ranking boosts and logs `Narrative-ranked opportunity` in the snapshot/share outputs.
- Founder fame execution sprint now includes `Narrative Route Execution Mode` and route-specific Day 1-Day 3 mission/check-in/escalation defaults.
- Founder fame execution scorecard now scores `Narrative Route Alignment` and raises route-drift risk flags when winner/mode/opportunity diverge.
- Founder fame risk response plan now includes `Narrative Route Risk Controls` with route-alignment penalty and correction owner/actions.
- Founder fame escalation queue now includes `Narrative Route Escalation Lane` with lane status/deadline/trigger routing.
- Founder fame command center now includes `Narrative Route Control Tower` for route signal + lane synchronization.
- Founder fame command center now includes `In-App Fast Loop` so operators run `Run Fame Next Move` every cycle and post owner updates quickly.
- Founder fame spotlight pack now includes `Route Integrity Messaging` so public drafts mirror route state.
- Founder fame breakout plan now includes `Narrative Route Scale Plan` to keep expansion tied to route-lane stability.
- Founder fame outreach sprint now includes `Narrative Route Outreach Controls` to route-touch-floor adjustments and lane triggers.
- Founder fame proof loop now includes `Narrative Route Proof Lane` to keep proof-loop intensity tied to route-lane health.
- Founder fame KPI snapshot now includes `Narrative Route KPI Controls` to sync winner/mode/alignment with KPI actions.
- Founder fame narrative lab now includes `Narrative Route Lab Controls` to keep ranked routes anchored to route-lane guardrails.
- Founder narrative route trace artifact in `.build/growth/<week>-founder-narrative-route-trace.md` with source issue IDs, parsed route outputs, and expected sync/review markers.
- Founder narrative route live verification artifact in `.build/growth/<week>-founder-narrative-route-live-check.md`.
- Monday checklist includes a `Distribution Follow-Up Execution` section (Day 0 to Day 7 checkboxes + score fields).
- Distribution follow-up execution scoring (days completed + completion score) from previous Monday checklist.
- Automatic channel-mix recommendation (primary-led, backup-led, or balanced) from ROI + distribution execution signals.
- Monday distribution execution nudge comment auto-managed when completion score/status is below threshold.
- Day 0 to Day 2 distribution action-item comment auto-managed when nudge conditions are active.
- `Monday Publish Checklist <week>` includes an auto-managed `Distribution Escalation Queue` block for unchecked Day 0-Day 2 tasks.
- Distribution nudge/action-item comment upserts are pagination-safe and auto-clear duplicate marker comments.
- Distribution nudge trace artifact in `.build/growth/<week>-distribution-nudge-trace.md` with trigger inputs, actions, dedupe counts, and escalation outcomes.
- Previous Monday checklist effectiveness extraction (post status + reply KPIs).
- Reply-pack effectiveness block auto-synced into the active `Weekly Growth Sprint <week>` issue.
- Creator outreach effectiveness block auto-synced into the active `Weekly Growth Sprint <week>` issue.
- Automatic next-week variant recommendation from Monday effectiveness deltas.
- Automatic next-week creator outreach recommendation from Monday outreach deltas.
- Outreach rate trendlines (reply/collaboration/cross-post) included in Friday review and sprint sync.
- Friday review trendline for variant winners (consecutive A/B/C wins on primary + backup channels).
- Friday review primary/backup channel ROI scores from variant trend + reply/outreach deltas.
- Friday review channel ROI routing recommendation (primary/backup/balanced lead).
- Friday review comment section with copy-ready primary/backup channel scripts from recommended variants.
- Monday checklist auto-promotes ROI-biased default drafts from Friday review routing.
- Auto-updated follow-up issue:
  - `Growth Recovery Plan <week>` when sprint health is `Recovery`
  - `Growth Highlight Plan <week>` when sprint health is `Exceptional`

## Manual trigger

From GitHub Actions, run **Weekly Growth Sprint** and optionally override:

- `week`
- `primary_channel`
- `backup_channel`
- `metric_focus`
- messaging fields (`command`, `problem`, `outcome`, etc.)

From GitHub Actions, run **Weekly Growth Review** and optionally override:

- `week` (to review a specific sprint)
- `founder_transcript_path` (optional repo-relative founder interview transcript; falls back to interview prep when omitted)
- `founder_fame_daily_mission_path` (optional repo-relative founder daily mission artifact; when provided, action-queue generation enforces freshness and fails fast on stale/unparseable mission dates)
- `target_win_card`
- `target_win_recap`
- `target_posts`
- `target_stories`
- `target_installs`
- `primary_audience_region` (`global`, `us`, `eu`, `apac`)
- `backup_audience_region` (`global`, `us`, `eu`, `apac`)
- `distribution_completion_threshold` (minimum distribution completion score before nudge/escalation)
- `distribution_verifier_critical_threshold` (failure-count threshold before critical verifier escalation, default `3`)
- `distribution_verifier_critical_assignee` (optional GitHub username to auto-assign when verifier incident reaches critical)
- `distribution_verifier_critical_assignees` (optional comma-separated fallback assignee list; evaluated in order)
- `distribution_verifier_critical_comment_cooldown_hours` (hours to suppress repeat critical checklist-comment updates when failure count is unchanged, default `24`)
- `distribution_verifier_critical_comment_min_failure_delta` (minimum failure-count increase required to update critical checklist comment during cooldown, default `1`)
- `founder_verifier_critical_threshold` (failure-count threshold before founder proof-loop verifier incident is marked critical, default `3`)
- `founder_verifier_critical_assignee` (optional GitHub username to auto-assign when founder proof-loop verifier incident reaches critical)
- `founder_verifier_critical_assignees` (optional comma-separated fallback assignee list; evaluated in order for founder proof-loop incidents)
- `founder_verifier_comment_cooldown_hours` (hours to suppress repeat founder verifier checklist-comment updates when failure count is unchanged, default `24`)
- `founder_verifier_comment_min_failure_delta` (minimum failure-count increase required to update founder verifier checklist comments during cooldown, default `1`)
- `narrative_route_critical_threshold` (critical-route occurrence threshold before founder narrative route incident is marked critical, default `2`)
- `narrative_route_critical_assignee` (optional GitHub username to auto-assign when narrative-route incident reaches critical threshold)
- `narrative_route_critical_assignees` (optional comma-separated fallback assignee list; evaluated in order for narrative-route incidents)
- `narrative_route_critical_comment_cooldown_hours` (hours to suppress repeat narrative-route critical checklist-comment updates when occurrence count is unchanged, default `24`)
- `narrative_route_critical_comment_min_occurrence_delta` (minimum critical-occurrence increase required to update narrative-route critical checklist comments during cooldown, default `1`)

To verify live nudge behavior after a Friday run, use:

- `zsh scripts/verify_distribution_nudge_run.sh --repo <owner/repo> --strict`
- `zsh scripts/verify_founder_narrative_route_run.sh --repo <owner/repo> --strict`
- `zsh scripts/verify_monday_publish_routing_run.sh --repo <owner/repo> --issue <monday_issue_number> --review .build/growth/<week>-review.md --strict`
- `zsh scripts/verify_founder_fame_proof_loop_run.sh --repo <owner/repo> --strict`
- `zsh scripts/verify_founder_fame_exceptional_loop_run.sh --repo <owner/repo> --strict`
- `zsh scripts/verify_founder_fame_proof_loop.sh --proof-loop .build/founder/founder-fame-proof-loop-<week>.md --strict`
- Optional: pass `--run-id <github_run_id>` to pin a specific run.
- The workflow also runs this verification automatically against its local trace and uploads `<week>-distribution-nudge-live-check.md`.
- The workflow also runs founder run-level verification automatically and uploads `founder-fame-proof-loop-live-check-<week>.md`.
- The workflow also runs founder exceptional-loop live verification automatically and uploads `founder-fame-exceptional-loop-live-check-<week>.md`.
- On strict verification failures, the workflow also upserts `weekly-growth-distribution-nudge-verifier-failure` on the Monday checklist issue before failing the run.
- The workflow also runs strict founder proof-loop verification and uploads `founder-fame-proof-loop-check-<week>.md`.
- On strict founder proof-loop verification failures, the workflow also upserts `weekly-growth-founder-fame-proof-loop-verifier-failure` on the Monday checklist issue before failing the run.
- The workflow also auto-manages `Growth Incident: Founder Fame Proof Loop Verifier <week>` issue state (create/reopen/update on failure, close on recovery) and tracks failure count.
- If founder verifier alert comment updates are noisy, set `founder_verifier_comment_cooldown_hours` and `founder_verifier_comment_min_failure_delta` to suppress repeat updates until failure delta clears your threshold.
- When founder failure count reaches `founder_verifier_critical_threshold`, it adds `growth-critical` on the founder incident and upserts `weekly-growth-founder-fame-proof-loop-verifier-critical` on the Monday checklist issue.
- If `founder_verifier_critical_assignee` or `founder_verifier_critical_assignees` is set, the workflow auto-assigns the first valid owner on founder critical escalation and removes configured owners after recovery/pressure drop.
- The workflow also auto-manages `Growth Incident: Distribution Nudge Verifier <week>` issue state (create/reopen/update on failure, close on recovery) and tracks failure count.
- When failure count reaches `distribution_verifier_critical_threshold`, it adds `growth-critical` on the incident and upserts `weekly-growth-distribution-nudge-verifier-critical` on the Monday checklist issue.
- If `distribution_verifier_critical_assignee` or `distribution_verifier_critical_assignees` is set, the workflow auto-assigns the first valid owner when critical escalation activates and removes configured owners when incident pressure drops.
- If failure count is unchanged and the critical checklist comment was updated recently, comment updates are suppressed until `distribution_verifier_critical_comment_cooldown_hours` elapses.
- During cooldown, critical checklist-comment updates resume only when failure delta meets `distribution_verifier_critical_comment_min_failure_delta`.
- The workflow auto-manages `Growth Incident: Founder Narrative Route Control <week>` when route mode enters recovery or lane status enters critical, and tracks critical occurrences for the week.
- When critical occurrences reach `narrative_route_critical_threshold`, it applies `growth-critical` and upserts `weekly-growth-founder-narrative-route-critical` on the Monday checklist issue.
- If `narrative_route_critical_assignee` or `narrative_route_critical_assignees` is set, the workflow auto-assigns the first valid owner on narrative-route critical escalation and removes configured owners when route pressure drops.
- If narrative-route critical occurrence count is unchanged and the critical checklist comment was updated recently, comment updates are suppressed until `narrative_route_critical_comment_cooldown_hours` elapses.
- During cooldown, narrative-route critical checklist-comment updates resume only when occurrence delta meets `narrative_route_critical_comment_min_occurrence_delta`.
- During narrative-route critical escalation, the workflow also upserts `weekly-growth-founder-narrative-route-owner-queue` on the Monday checklist issue with immediate owner tasks and clears it after recovery.
- During narrative-route critical escalation, the workflow auto-manages checklist issue body block `weekly-growth-founder-narrative-route-owner-queue-start` so owner task checkbox state can auto-close queue items and persist across reruns.
- During narrative-route critical escalation, the workflow mirrors owner tasks into incident issue body block `weekly-growth-founder-narrative-route-owner-sync-start` for single-pane incident tracking and clears it after recovery.

## Local equivalent

If you prefer local execution:

1. `zsh scripts/run_launch_day.sh --skip-tests`
2. `zsh scripts/generate_weekly_growth_issue.sh --out /tmp/weekly-growth-issue.md`
3. `zsh scripts/generate_social_proof_kit.sh --out /tmp/social-proof-kit.md`
4. `zsh scripts/generate_creator_outreach_kit.sh --out /tmp/creator-outreach-kit.md`
5. `zsh scripts/generate_distribution_followup_plan.sh --out /tmp/distribution-followup-plan.md`
6. `zsh scripts/generate_viral_experiment_board.sh --out /tmp/viral-experiment-board.md`
7. `zsh scripts/generate_winning_hook_library.sh --out /tmp/winning-hook-library.md`
8. `zsh scripts/generate_social_proof_wall.sh --out /tmp/social-proof-wall.md`
9. `zsh scripts/generate_credibility_ledger.sh --out /tmp/credibility-ledger.md`
10. `zsh scripts/generate_founder_fame_ops_brief.sh --distribution-plan /tmp/distribution-followup-plan.md --social-proof-wall /tmp/social-proof-wall.md --out /tmp/founder-fame-ops-brief.md`
11. `zsh scripts/generate_founder_fame_action_queue.sh --ops-brief /tmp/founder-fame-ops-brief.md --daily-mission /tmp/founder-fame-daily-mission.md --require-fresh-daily-mission --out /tmp/founder-fame-action-queue.md`
12. `zsh scripts/generate_founder_fame_interview_prep.sh --ops-brief /tmp/founder-fame-ops-brief.md --action-queue /tmp/founder-fame-action-queue.md --out /tmp/founder-fame-interview-prep.md`
13. `zsh scripts/generate_founder_fame_transcript_ingestion.sh --transcript /tmp/founder-fame-interview-prep.md --interview-prep /tmp/founder-fame-interview-prep.md --media-blast /tmp/founder-media-blast.md --out /tmp/founder-fame-transcript-ingestion.md`
14. `zsh scripts/generate_founder_fame_repurpose_plan.sh --interview-prep /tmp/founder-fame-interview-prep.md --transcript-ingestion /tmp/founder-fame-transcript-ingestion.md --media-blast /tmp/founder-media-blast.md --action-queue /tmp/founder-fame-action-queue.md --out /tmp/founder-fame-repurpose-plan.md`
15. `zsh scripts/generate_founder_fame_uplift_tracker.sh --campaign-dir docs/campaigns --out /tmp/founder-fame-uplift-tracker.md`
16. `zsh scripts/generate_founder_fame_weight_profile.sh --campaign-dir docs/campaigns --uplift-tracker /tmp/founder-fame-uplift-tracker.md --out /tmp/founder-fame-weight-profile.md`
17. `zsh scripts/generate_founder_fame_momentum_brief.sh --fame-pack /tmp/founder-fame-pack.md --repurpose-plan /tmp/founder-fame-repurpose-plan.md --transcript-ingestion /tmp/founder-fame-transcript-ingestion.md --press-kit /tmp/founder-press-kit.md --media-blast /tmp/founder-media-blast.md --credibility-ledger /tmp/credibility-ledger.md --weight-profile /tmp/founder-fame-weight-profile.md --out /tmp/founder-fame-momentum-brief.md`
18. `zsh scripts/generate_founder_fame_opportunity_radar.sh --momentum-brief /tmp/founder-fame-momentum-brief.md --weight-profile /tmp/founder-fame-weight-profile.md --uplift-tracker /tmp/founder-fame-uplift-tracker.md --winning-hook-library /tmp/winning-hook-library.md --credibility-ledger /tmp/credibility-ledger.md --out /tmp/founder-fame-opportunity-radar.md`
19. `zsh scripts/generate_founder_fame_execution_sprint.sh --opportunity-radar /tmp/founder-fame-opportunity-radar.md --momentum-brief /tmp/founder-fame-momentum-brief.md --distribution-plan /tmp/distribution-followup-plan.md --monday-checkpoint /tmp/monday-checkpoint.md --reply-pack /tmp/reply-pack.md --out /tmp/founder-fame-execution-sprint.md`
20. `zsh scripts/generate_founder_fame_execution_scorecard.sh --execution-sprint /tmp/founder-fame-execution-sprint.md --opportunity-radar /tmp/founder-fame-opportunity-radar.md --momentum-brief /tmp/founder-fame-momentum-brief.md --distribution-plan /tmp/distribution-followup-plan.md --monday-checkpoint /tmp/monday-checkpoint.md --reply-pack /tmp/reply-pack.md --out /tmp/founder-fame-execution-scorecard.md`
21. `zsh scripts/generate_founder_fame_risk_response_plan.sh --execution-scorecard /tmp/founder-fame-execution-scorecard.md --execution-sprint /tmp/founder-fame-execution-sprint.md --opportunity-radar /tmp/founder-fame-opportunity-radar.md --momentum-brief /tmp/founder-fame-momentum-brief.md --distribution-plan /tmp/distribution-followup-plan.md --reply-pack /tmp/reply-pack.md --out /tmp/founder-fame-risk-response-plan.md`
22. `zsh scripts/generate_founder_fame_escalation_queue.sh --risk-response-plan /tmp/founder-fame-risk-response-plan.md --execution-scorecard /tmp/founder-fame-execution-scorecard.md --execution-sprint /tmp/founder-fame-execution-sprint.md --distribution-plan /tmp/distribution-followup-plan.md --reply-pack /tmp/reply-pack.md --out /tmp/founder-fame-escalation-queue.md`
23. `zsh scripts/generate_founder_fame_command_center.sh --momentum-brief /tmp/founder-fame-momentum-brief.md --execution-scorecard /tmp/founder-fame-execution-scorecard.md --risk-response-plan /tmp/founder-fame-risk-response-plan.md --escalation-queue /tmp/founder-fame-escalation-queue.md --opportunity-radar /tmp/founder-fame-opportunity-radar.md --out /tmp/founder-fame-command-center.md`
24. `zsh scripts/generate_founder_fame_next_move_handoff.sh --week 2026-W24 --command-center /tmp/founder-fame-command-center.md --artifact-link /tmp/founder-fame-command-center.md --out /tmp/founder-fame-next-move-handoff.md`
25. `zsh scripts/generate_founder_fame_next_move_draft_pack.sh --week 2026-W24 --next-move-handoff /tmp/founder-fame-next-move-handoff.md --out /tmp/founder-fame-next-move-draft-pack.md`
26. `zsh scripts/generate_founder_fame_war_room.sh --week 2026-W24 --command-center /tmp/founder-fame-command-center.md --next-move-handoff /tmp/founder-fame-next-move-handoff.md --next-move-draft-pack /tmp/founder-fame-next-move-draft-pack.md --proof-loop-check /tmp/founder-fame-proof-loop-check.md --narrative-lab /tmp/founder-fame-narrative-lab.md --out /tmp/founder-fame-war-room.md`
27. `zsh scripts/verify_founder_fame_war_room.sh --war-room /tmp/founder-fame-war-room.md --strict --out /tmp/founder-fame-war-room-check.md`
28. `zsh scripts/post_founder_fame_war_room_comment.sh --war-room /tmp/founder-fame-war-room.md --strict --dry-run --out /tmp/founder-fame-war-room-comment.md`
29. In the app menu, run `Fame -> Run Fame Next Move`, then post the resulting artifact link + owner update from `/tmp/founder-fame-next-move-handoff.md` in `Monday Publish Checklist <week>`.
30. `zsh scripts/generate_founder_fame_spotlight_pack.sh --command-center /tmp/founder-fame-command-center.md --momentum-brief /tmp/founder-fame-momentum-brief.md --execution-scorecard /tmp/founder-fame-execution-scorecard.md --risk-response-plan /tmp/founder-fame-risk-response-plan.md --primary-channel "X / Threads" --backup-channel "LinkedIn" --out /tmp/founder-fame-spotlight-pack.md`
31. `zsh scripts/generate_founder_fame_breakout_plan.sh --spotlight-pack /tmp/founder-fame-spotlight-pack.md --command-center /tmp/founder-fame-command-center.md --execution-sprint /tmp/founder-fame-execution-sprint.md --distribution-plan /tmp/distribution-followup-plan.md --winning-hook-library /tmp/winning-hook-library.md --credibility-ledger /tmp/credibility-ledger.md --out /tmp/founder-fame-breakout-plan.md`
32. `zsh scripts/generate_founder_fame_outreach_sprint.sh --breakout-plan /tmp/founder-fame-breakout-plan.md --guesting-queue /tmp/founder-guesting-queue.md --creator-target-list /tmp/creator-target-list.md --distribution-plan /tmp/distribution-followup-plan.md --media-blast /tmp/founder-media-blast.md --out /tmp/founder-fame-outreach-sprint.md`
33. `zsh scripts/generate_founder_fame_proof_loop.sh --breakout-plan /tmp/founder-fame-breakout-plan.md --outreach-sprint /tmp/founder-fame-outreach-sprint.md --spotlight-pack /tmp/founder-fame-spotlight-pack.md --command-center /tmp/founder-fame-command-center.md --credibility-ledger /tmp/credibility-ledger.md --out /tmp/founder-fame-proof-loop.md`
34. `zsh scripts/verify_founder_fame_proof_loop.sh --proof-loop /tmp/founder-fame-proof-loop.md --strict --out /tmp/founder-fame-proof-loop-check.md`
35. `zsh scripts/generate_founder_fame_kpi_snapshot.sh --proof-loop /tmp/founder-fame-proof-loop.md --command-center /tmp/founder-fame-command-center.md --proof-loop-check /tmp/founder-fame-proof-loop-check.md --out /tmp/founder-fame-kpi-snapshot.md`
36. `zsh scripts/generate_founder_fame_velocity_scoreboard.sh --week 2026-W24 --product "Fluid Reader" --kpi-snapshot /tmp/founder-fame-kpi-snapshot.md --command-center /tmp/founder-fame-command-center.md --proof-loop-check /tmp/founder-fame-proof-loop-check.md --out /tmp/founder-fame-velocity-scoreboard.md`
37. `zsh scripts/generate_founder_fame_exceptional_loop.sh --week 2026-W24 --product "Fluid Reader" --kpi-snapshot /tmp/founder-fame-kpi-snapshot.md --velocity-scoreboard /tmp/founder-fame-velocity-scoreboard.md --out /tmp/founder-fame-exceptional-loop.md`
38. `zsh scripts/post_founder_fame_exceptional_loop_comment.sh --exceptional-loop /tmp/founder-fame-exceptional-loop.md --dry-run --out /tmp/founder-fame-exceptional-loop-comment.md`
39. `zsh scripts/verify_founder_fame_exceptional_loop_run.sh --exceptional-loop /tmp/founder-fame-exceptional-loop.md --comment /tmp/founder-fame-exceptional-loop-comment.md --strict --out /tmp/founder-fame-exceptional-loop-live-check.md`
40. `zsh scripts/generate_founder_fame_narrative_lab.sh --week 2026-W24 --product "Fluid Reader" --kpi-snapshot /tmp/founder-fame-kpi-snapshot.md --proof-loop /tmp/founder-fame-proof-loop.md --command-center /tmp/founder-fame-command-center.md --winning-hook-library /tmp/winning-hook-library.md --credibility-ledger /tmp/credibility-ledger.md --primary-channel "X / Threads" --backup-channel "LinkedIn" --out /tmp/founder-fame-narrative-lab.md`
41. `zsh scripts/generate_founder_first48h_post_pack.sh --week 2026-W24 --product "Fluid Reader" --narrative-lab /tmp/founder-fame-narrative-lab.md --primary-channel "X / Threads" --backup-channel "LinkedIn" --cta "If you're building, reply with your KPI bottleneck and I'll share the exact command flow." --primary-char-limit 280 --backup-char-limit 500 --primary-tone x-punchy --backup-tone linkedin-context --out /tmp/founder-first48h-post-pack.md`

If you have a real founder interview transcript, add `--founder-transcript docs/campaigns/<week>-founder-interview-transcript.md` to step 1 so transcript ingestion and momentum scoring use real speaker/timecode signals.

## Operator checklist

- Review the auto-created weekly issue.
- Confirm labels are present and issue metadata looks correct.
- Confirm previous-week KPI snapshot is present when historical data exists.
- Confirm delta notes include baseline week when at least two prior issues exist.
- Confirm Friday review comment is updated with scorecard + priority actions.
- Confirm sprint health label (`growth-watch` or `growth-highlight`) matches KPI outcome.
- Confirm recovery/highlight plan issue is open when expected for that week.
- Confirm Monday draft comment is present in highlight plan issue when sprint is exceptional.
- Confirm Monday draft artifact uploads with weekly review workflow artifacts.
- Confirm `Monday Publish Checklist <week>` issue is open on exceptional weeks and closed otherwise.
- Confirm Monday timing checkpoint comment exists in `Monday Publish Checklist <week>`.
- Confirm Monday timing checkpoint includes ROI lead channel + sequence guidance.
- Confirm Monday timing checkpoint publish windows align with selected audience regions.
- Confirm first-24-hour reply pack comment exists in `Monday Publish Checklist <week>`.
- Confirm social proof kit comment exists in `Monday Publish Checklist <week>`.
- Confirm social proof wall comment exists in `Monday Publish Checklist <week>`.
- Confirm credibility ledger comment exists in `Monday Publish Checklist <week>`.
- Confirm creator outreach kit comment exists in `Monday Publish Checklist <week>`.
- Confirm creator target list comment exists in `Monday Publish Checklist <week>`.
- Confirm creator signal comments use marker `weekly-growth-creator-signal` and include handle/segment/channel/fit/warm intro/status fields.
- Confirm Friday review includes `Creator Account Enrichment` with creator signal metrics and recommendation.
- Confirm distribution follow-up plan comment exists in `Monday Publish Checklist <week>`.
- Confirm viral experiment board comment exists in `Monday Publish Checklist <week>`.
- Confirm winning hook library comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame pack, press kit, and media blast comments exist in `Monday Publish Checklist <week>`.
- Confirm founder guesting queue comment exists in `Monday Publish Checklist <week>`.
- Confirm founder guesting sprint brief comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame ops brief comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame action queue comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame interview prep comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame transcript ingestion comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame repurpose plan comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame uplift tracker artifact is uploaded with weekly review outputs.
- Confirm founder fame weight profile artifact is uploaded with weekly review outputs.
- Confirm founder fame outreach sprint artifact is uploaded with weekly review outputs.
- Confirm founder fame momentum brief comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame command center comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame next-move handoff comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame war-room comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame spotlight pack comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame breakout plan comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame outreach sprint comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame proof loop comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame KPI snapshot comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame velocity scoreboard comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame exceptional-loop checklist comment exists in `Monday Publish Checklist <week>`.
- Confirm founder fame narrative lab comment exists in `Monday Publish Checklist <week>`.
- Confirm founder first-48h post pack comment exists in `Monday Publish Checklist <week>`.
- Confirm founder first-48h route controls block exists in `Monday Publish Checklist <week>` issue body.
- Confirm founder fame proof loop verification artifact is uploaded with weekly review outputs.
- Confirm founder fame KPI snapshot artifact is uploaded with weekly review outputs.
- Confirm founder fame velocity scoreboard artifact is uploaded with weekly review outputs.
- Confirm founder fame narrative lab artifact is uploaded with weekly review outputs.
- Confirm founder narrative route trace artifact is uploaded with weekly review outputs.
- Confirm founder narrative route live verification artifact is uploaded with weekly review outputs.
- Confirm Monday publish routing live verification artifact (`-monday-publish-routing-live-check.md`) is uploaded with weekly review outputs.
- Confirm founder fame proof loop live verification artifact is uploaded with weekly review outputs.
- Confirm founder fame proof loop strict verification passes for the reviewed artifact.
- Confirm `verify_founder_fame_proof_loop_run.sh` reports PASS for the reviewed run + checklist issue.
- Confirm `verify_founder_narrative_route_run.sh` reports PASS for the reviewed run + checklist/sprint issues.
- Confirm `verify_monday_publish_routing_run.sh` reports PASS for the reviewed run + checklist/review artifacts.
- Confirm strict founder proof-loop verifier failures upsert and later clear `weekly-growth-founder-fame-proof-loop-verifier-failure` on the Monday checklist issue.
- Confirm strict founder proof-loop verifier failures create/reopen/update `Growth Incident: Founder Fame Proof Loop Verifier <week>` and recovery closes it.
- Confirm founder fame velocity scoreboard upserts use marker `weekly-growth-founder-fame-velocity-scoreboard` for idempotent checklist updates.
- Confirm founder fame narrative lab upserts use marker `weekly-growth-founder-fame-narrative-lab` for idempotent checklist updates.
- Confirm Route Recovery / Critical lane status creates or reopens `Growth Incident: Founder Narrative Route Control <week>` and recovery closes it.
- Confirm founder narrative route incident issues are tracked by marker `weekly-growth-founder-narrative-route-incident` and critical checklist comments use marker `weekly-growth-founder-narrative-route-critical`.
- Confirm narrative-route incident applies `growth-critical` once occurrences reach `narrative_route_critical_threshold`.
- Confirm optional `narrative_route_critical_assignee` / `narrative_route_critical_assignees` routes to the first valid owner on narrative-route critical escalation and unassigns configured owners after recovery/pressure drop.
- Confirm narrative-route critical-comment cooldown policy honors `narrative_route_critical_comment_cooldown_hours` and `narrative_route_critical_comment_min_occurrence_delta`.
- Confirm narrative-route owner queue comment (`weekly-growth-founder-narrative-route-owner-queue`) appears with owner tasks during critical escalation and clears after recovery.
- Confirm checklist issue auto-manages narrative-route owner queue block `weekly-growth-founder-narrative-route-owner-queue-start` and checked tasks are mirrored into queue comment + incident owner-sync block.
- Confirm incident issue body mirrors owner tasks in `weekly-growth-founder-narrative-route-owner-sync-start` while escalation is active and clears after recovery.
- Confirm Friday review includes `Founder Narrative Route Signals` with winner/trend/fame velocity/recommendation lines plus distribution strategy/Day 0 lead lane/Day 0 support lane/distribution recommendation/first 48h execution plan lines.
- Confirm Friday review includes founder narrative route control lines (`route mode`, `route alignment target`, `route lane status`, `route guardrail`, `route control recommendation`).
- Confirm `Weekly Growth Sprint <week>` effectiveness block includes founder narrative route winner + trend updates.
- Confirm `Monday Publish Checklist <week>` logs `Narrative route preferred variant` and `Founder narrative routing action` in effectiveness/default draft sections.
- Confirm founder fame opportunity radar snapshot includes `Narrative-ranked opportunity` with route-based boost context.
- Confirm founder fame execution sprint snapshot includes `Execution mode` and `Narrative Route Execution Mode` section.
- Confirm founder fame execution scorecard includes `Narrative Route Alignment` signal and route-drift risk flags when alignment degrades.
- Confirm founder fame risk response plan includes `Narrative Route Risk Controls` and route-alignment penalty context.
- Confirm founder fame escalation queue includes `Narrative Route Escalation Lane` and route lane deadline/trigger fields.
- Confirm founder fame command center includes `Narrative Route Control Tower` with route lane status + trigger wiring.
- Confirm founder fame command center includes `In-App Fast Loop` and `Run Fame Next Move` cadence guidance.
- Confirm founder fame spotlight pack includes `Route Integrity Messaging` aligned with current route signal/mode.
- Confirm founder fame breakout plan includes `Narrative Route Scale Plan` and route integrity metric row.
- Confirm founder fame outreach sprint includes `Narrative Route Outreach Controls` with route outreach mode + lane trigger fields.
- Confirm founder fame proof loop includes `Narrative Route Proof Lane` and route integrity row in `Proof Loop Scorecard`.
- Confirm founder fame KPI snapshot includes `Narrative Route KPI Controls` with route health recommendation + lane trigger fields.
- Confirm founder fame narrative lab includes `Narrative Route Lab Controls` with route mode/alignment/guardrail decisions.
- Confirm founder fame outreach sprint comment includes `Lane Owner Defaults (Auto-Prefilled)` with creator/guesting/distribution owner tasks.
- Confirm Friday review includes founder outreach sprint owner-default completion (overall + creator/guesting/distribution/ops owner tasks).
- Confirm founder guesting signal comments use marker `weekly-growth-founder-guesting-signal` and include target/format/stage/channel/priority/warm intro/status fields.
- Confirm distribution follow-up plan route aligns with current ROI recommendation.
- Confirm Friday review includes distribution completion metrics (days + score delta).
- Confirm Friday review includes an explicit channel-mix recommendation.
- Confirm a distribution nudge comment appears when completion score/status is below threshold and clears when recovered.
- Confirm a distribution action-items comment appears for unchecked Day 0-Day 2 tasks and clears when those tasks are complete.
- Confirm `Monday Publish Checklist <week>` includes (and clears) an auto-managed `Distribution Escalation Queue` block when Day 0-Day 2 tasks are unchecked.
- Confirm distribution nudge trace artifact is uploaded with weekly review outputs and includes action/dedupe fields.
- Confirm `verify_distribution_nudge_run.sh` reports PASS for the reviewed run + checklist issue.
- Confirm `Weekly Growth Sprint <week>` issue includes a `Reply Pack Effectiveness` block with Monday status/reply KPIs.
- Confirm `Weekly Growth Sprint <week>` issue includes creator outreach effectiveness metrics (sent/replies/collabs/cross-posts).
- Confirm Friday review includes a variant recommendation line based on Monday reply effectiveness deltas.
- Confirm Friday review includes an outreach recommendation line based on Monday creator outreach deltas.
- Confirm Friday review includes creator outreach rate deltas (reply/collab/cross-post) for trendline decisions.
- Confirm Friday review includes primary/backup variant trendline (consecutive wins).
- Confirm Friday review includes primary/backup channel ROI scores.
- Confirm Friday review includes a channel ROI routing recommendation line.
- Confirm Friday review includes copy-ready channel scripts for primary + backup channels.
- Confirm `Monday Publish Checklist <week>` includes ROI-biased `Default Publish Drafts (Auto-Promoted)` sourced from Friday review artifact.
- Confirm Monday draft artifact/comment includes `Default Publish Drafts (Auto-Promoted)` markers for parser-safe fallback.
- Confirm campaign draft fits current product messaging.
- Ship Monday/Wednesday/Friday posts.
- Update issue with actual outcomes by Friday.
