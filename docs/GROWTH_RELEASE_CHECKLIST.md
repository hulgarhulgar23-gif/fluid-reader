# Growth Release Checklist

Use this checklist before every public release.

## 1) Product Readiness

- [ ] `swift test` passes.
- [ ] `zsh scripts/check_fast.sh` passes.
- [ ] `zsh scripts/check_docs.sh` passes.
- [ ] `zsh scripts/check_growth.sh` passes.
- [ ] `Top Picks` default flow still shows a share action.
- [ ] `Copy Win Card` and `Copy Win Recap` both work.

## 2) Demo Readiness

- [ ] `zsh scripts/run_launch_day.sh --skip-tests` generates launch artifacts.
- [ ] Launch run includes `-founder-update.md` artifact for founder KPI storytelling.
- [ ] Launch run includes `-founder-fame-pack.md` artifact for founder narrative amplification.
- [ ] Launch run includes `-founder-press-kit.md` artifact for press-ready founder storytelling.
- [ ] Launch run includes `-founder-media-blast.md` artifact for 7-day founder channel execution.
- [ ] Launch run includes `-weekly-growth-issue.md` artifact for owner-assigned weekly execution tracking.
- [ ] Launch run includes `-social-proof.md` artifact for post + reply copy.
- [ ] Launch run includes `-reply-pack.md` artifact for first-24-hour response speed.
- [ ] Launch run includes `-monday-checkpoint.md` artifact for publish-window + sequence lock.
- [ ] Launch run includes `-creator-outreach.md` artifact for creator/community pitching.
- [ ] Launch run includes `-distribution-plan.md` artifact for 7-day follow-up execution.
- [ ] Launch run includes `-viral-experiment-board.md` artifact for owner-assigned growth testing.
- [ ] Launch run includes `-social-proof-wall.md` artifact for repost-ready proof cards.
- [ ] Launch run includes `-founder-fame-action-queue.md` artifact for owner-assigned founder execution.
- [ ] Launch run includes `-founder-fame-interview-prep.md` artifact for founder opener + Q&A rehearsal.
- [ ] Launch run includes `-founder-fame-transcript-ingestion.md` artifact for quote/objection/clip extraction.
- [ ] Launch run includes `-founder-fame-repurpose-plan.md` artifact for clip/thread/recap follow-through.
- [ ] Launch run includes `-founder-fame-uplift-tracker.md` artifact for outcome-uplift calibration before weight refresh.
- [ ] Launch run includes `-founder-fame-weight-profile.md` artifact for adaptive signal weighting.
- [ ] Launch run includes `-founder-fame-momentum-brief.md` artifact for 48-hour founder readiness and risk routing.
- [ ] Launch run includes `-founder-fame-opportunity-radar.md` artifact for ranked high-leverage fame bets.
- [ ] Launch run includes `-founder-fame-execution-sprint.md` artifact for day-by-day owner execution.
- [ ] Launch run includes `-founder-fame-execution-scorecard.md` artifact for readiness scoring and highest-risk routing.
- [ ] Launch run includes `-founder-fame-risk-response-plan.md` artifact for 72-hour mitigation routing from scorecard risk flags.
- [ ] Launch run includes `-founder-fame-escalation-queue.md` artifact for owner-routed P1/P2 escalation execution.
- [ ] Launch run includes `-founder-fame-next-move-draft-pack.md` artifact for copy-ready founder channel + checklist posting blocks.
- [ ] Launch run includes `-founder-fame-war-room.md` artifact for single-sheet founder execution routing.
- [ ] Launch run includes `-founder-fame-war-room-check.md` artifact with strict war-room quality verification.
- [ ] Launch run includes `-founder-fame-war-room-comment.md` artifact for checklist comment upsert/dry-run review.
- [ ] Launch run includes `-founder-fame-war-room-live-check.md` artifact for checklist live verification parity.
- [ ] Launch run includes `-founder-fame-spotlight-pack.md` artifact for proof-first daily founder publishing.
- [ ] Launch run includes `-founder-fame-breakout-plan.md` artifact for 7-day founder script + partner burst execution.
- [ ] Launch run includes `-founder-fame-outreach-sprint.md` artifact for creator + guesting outreach conversion execution.
- [ ] Launch run includes `-founder-fame-proof-loop.md` artifact for Day 0 to Day 2 founder proof + conversion logging.
- [ ] Launch run includes `-founder-fame-proof-loop-check.md` artifact with strict proof-loop quality verification.
- [ ] Launch run includes `-founder-fame-exceptional-loop.md` artifact for 72-hour founder execution routing.
- [ ] Launch run includes `-founder-fame-exceptional-loop-comment.md` artifact for checklist comment upsert/dry-run review.
- [ ] Launch run includes `-founder-fame-exceptional-loop-live-check.md` artifact for checklist live verification parity.
- [ ] Launch run includes `-winning-hook-library.md` artifact for next-week Hook A/B/C lock-in.
- [ ] Launch run includes `-credibility-ledger.md` artifact for trust-proof follow-ups.
- [ ] Manual `Launch Pack Generator` workflow run succeeds.
- [ ] 60-second activation flow is still accurate.
- [ ] One fresh screenshot for Commands.
- [ ] One fresh Win Card sample image.
- [ ] One short demo clip (15 to 45 seconds).

## 3) Messaging Pack

- [ ] Generate a base draft with `zsh scripts/generate_campaign_pack.sh`.
- [ ] Generate social proof bundle with `zsh scripts/generate_social_proof_kit.sh`.
- [ ] Generate creator outreach bundle with `zsh scripts/generate_creator_outreach_kit.sh`.
- [ ] One “before/after” post draft.
- [ ] One “command spotlight” post draft.
- [ ] One 3-step workflow post draft.
- [ ] Weekly rows filled in `docs/WEEKLY_POST_PLANNER.md`.
- [ ] CTA for each post is explicit.
- [ ] Links point to current docs.

## 4) Distribution Plan

- [ ] Choose post dates for Monday/Wednesday/Friday.
- [ ] Pick one primary channel and one backup channel.
- [ ] Prepare one community post/comment (no hype, practical flow).
- [ ] Prepare one direct share for friends/teammates.
- [ ] Prepare reply templates from `docs/DISTRIBUTION_PLAYBOOK.md`.

## 5) Measurement Plan

- [ ] Define this release’s primary growth metric.
- [ ] Track Win Card copies and Win Recap copies.
- [ ] Track user-generated post count.
- [ ] Track inbound install trend after posting.
- [ ] Write one short weekly review note.

## 6) Post-Release Loop

- [ ] Collect top 3 user replies/questions.
- [ ] Convert one reply into a docs/workflow update.
- [ ] Reuse one top reply as next Monday hook.
- [ ] Add one new practical example for next release.
- [ ] Keep what worked, drop what did not.
- [ ] Confirm `Weekly Growth Sprint` workflow issue exists for next week.
- [ ] Confirm `Weekly Growth Review` workflow updates the active sprint issue.
- [ ] Confirm sprint health label (`growth-watch` or `growth-highlight`) is applied correctly.
- [ ] Confirm recovery/highlight plan issue is auto-managed for the sprint week.
- [ ] Confirm Monday-ready draft comment is generated from highlight plan on exceptional weeks.
- [ ] Confirm Monday draft markdown artifact is uploaded by weekly review workflow.
- [ ] Confirm `Monday Publish Checklist <week>` issue is auto-managed for exceptional vs non-exceptional weeks.
- [ ] Confirm Monday timing checkpoint comment/artifact is generated for the checklist issue.
- [ ] Confirm Monday timing checkpoint includes ROI-aware lead channel + publish sequence.
- [ ] Confirm Monday timing checkpoint publish windows match chosen audience regions (`global/us/eu/apac`).
- [ ] Confirm first-24-hour reply pack comment/artifact is generated for the checklist issue.
- [ ] Confirm social proof kit comment/artifact is generated for the checklist issue.
- [ ] Confirm social proof wall comment/artifact is generated for the checklist issue.
- [ ] Confirm winning hook library comment/artifact is generated for the checklist issue.
- [ ] Confirm credibility ledger comment/artifact is generated for the checklist issue.
- [ ] Confirm creator outreach kit comment/artifact is generated for the checklist issue.
- [ ] Confirm distribution follow-up plan comment/artifact is generated for the checklist issue.
- [ ] Confirm distribution execution nudge comment auto-appears below threshold and auto-clears when recovered.
- [ ] Confirm distribution action-items comment auto-appears for unchecked Day 0 to Day 2 tasks and clears when complete.
- [ ] Confirm `Monday Publish Checklist <week>` auto-manages `Distribution Escalation Queue` block for unchecked Day 0 to Day 2 tasks.
- [ ] Confirm distribution nudge trace artifact (`-distribution-nudge-trace.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm distribution nudge live verification artifact (`-distribution-nudge-live-check.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm Monday publish routing live verification artifact (`-monday-publish-routing-live-check.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm strict verifier failures upsert and later clear `weekly-growth-distribution-nudge-verifier-failure` on the Monday checklist issue.
- [ ] Confirm strict verifier failures create/reopen/update `Growth Incident: Distribution Nudge Verifier <week>` and recovery closes it.
- [ ] Confirm founder fame proof loop verification artifact (`-founder-fame-proof-loop-check-<week>.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm founder fame proof loop live verification artifact (`-founder-fame-proof-loop-live-check-<week>.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm founder fame exceptional-loop live verification artifact (`-founder-fame-exceptional-loop-live-check-<week>.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm founder fame velocity scoreboard artifact (`-founder-fame-velocity-scoreboard-<week>.md`) is generated and uploaded with weekly review artifacts.
- [ ] Confirm founder fame velocity scoreboard comment (`weekly-growth-founder-fame-velocity-scoreboard`) appears on the Monday checklist issue.
- [ ] Confirm strict founder proof-loop verifier failures upsert and later clear `weekly-growth-founder-fame-proof-loop-verifier-failure` on the Monday checklist issue.
- [ ] Confirm strict founder proof-loop verifier failures create/reopen/update `Growth Incident: Founder Fame Proof Loop Verifier <week>` and recovery closes it.
- [ ] Confirm Route Recovery / Critical lane state creates/reopens `Growth Incident: Founder Narrative Route Control <week>` and recovery closes it.
- [ ] Confirm founder narrative route critical escalation comment (`weekly-growth-founder-narrative-route-critical`) appears on checklist issue when route mode/lane is critical and clears after recovery.
- [ ] Confirm narrative-route incident applies `growth-critical` once occurrences reach `narrative_route_critical_threshold`.
- [ ] Confirm optional `narrative_route_critical_assignee` / `narrative_route_critical_assignees` routes to first valid owner on narrative-route critical escalation and unassigns configured owners after recovery/pressure drop.
- [ ] Confirm narrative-route critical-comment cooldown policy honors `narrative_route_critical_comment_cooldown_hours` and `narrative_route_critical_comment_min_occurrence_delta`.
- [ ] Confirm narrative-route owner queue comment (`weekly-growth-founder-narrative-route-owner-queue`) appears with owner tasks during critical escalation and clears after recovery.
- [ ] Confirm checklist issue body auto-manages narrative-route owner queue block (`weekly-growth-founder-narrative-route-owner-queue-start`) and owner task checkbox state auto-syncs into queue comment + incident mirror.
- [ ] Confirm incident issue body mirrors narrative-route owner tasks in `weekly-growth-founder-narrative-route-owner-sync-start` while escalation is active and clears after recovery.
- [ ] Confirm founder verifier alert-comment cooldown policy honors `founder_verifier_comment_cooldown_hours` and `founder_verifier_comment_min_failure_delta`.
- [ ] Confirm founder verifier incident applies `growth-critical` once failures reach `founder_verifier_critical_threshold`.
- [ ] Confirm founder critical escalation comment (`weekly-growth-founder-fame-proof-loop-verifier-critical`) appears on checklist issue at threshold and clears after recovery.
- [ ] Confirm optional `founder_verifier_critical_assignee` / `founder_verifier_critical_assignees` routes to first valid owner on founder critical escalation and unassigns configured owners after recovery/pressure drop.
- [ ] Confirm incident tracks failure occurrences and applies `growth-critical` once failures reach `distribution_verifier_critical_threshold`.
- [ ] Confirm critical escalation comment (`weekly-growth-distribution-nudge-verifier-critical`) appears on checklist issue at threshold and clears after recovery.
- [ ] Confirm optional `distribution_verifier_critical_assignee` / `distribution_verifier_critical_assignees` routes to first valid owner on critical escalation and unassigns configured owners after recovery/pressure drop.
- [ ] Confirm critical escalation comment honors `distribution_verifier_critical_comment_cooldown_hours` by skipping repeat updates when failure count is unchanged.
- [ ] Confirm cooldown-period updates resume only when failure delta meets `distribution_verifier_critical_comment_min_failure_delta`.
- [ ] Confirm `zsh scripts/verify_distribution_nudge_run.sh --repo <owner/repo> --strict` passes for the latest review run (or pin with `--run-id <id>`).
- [ ] Confirm `zsh scripts/verify_monday_publish_routing_run.sh --repo <owner/repo> --issue <monday_issue_number> --review .build/growth/<week>-review.md --strict` passes for the latest review/checklist pair.
- [ ] Confirm `zsh scripts/verify_founder_fame_proof_loop_run.sh --repo <owner/repo> --strict` passes for the latest review run (or pin with `--run-id <id>`).
- [ ] Confirm `zsh scripts/verify_founder_fame_exceptional_loop_run.sh --repo <owner/repo> --strict` passes for the latest review run (or pin with `--run-id <id>`).
- [ ] Confirm `zsh scripts/verify_founder_fame_war_room_run.sh --repo <owner/repo> --strict` passes for the latest founder fame pack run (or pin with `--run-id <id>`).
- [ ] Confirm reply pack includes channel-specific variants (proof/workflow/objection) for primary and backup channels.
- [ ] Confirm `zsh scripts/verify_founder_fame_proof_loop.sh --proof-loop .build/founder/founder-fame-proof-loop-<week>.md --strict` passes for the latest review artifact.
- [ ] Confirm Friday review syncs previous Monday `Reply Pack Effectiveness` (posted status, replies, objections) into the active sprint issue.
- [ ] Confirm Friday review syncs previous Monday creator outreach effectiveness (sent, replies, collaborations, cross-posts) into the active sprint issue.
- [ ] Confirm Friday review outputs a next-week variant recommendation from Monday effectiveness deltas.
- [ ] Confirm Friday review outputs a next-week creator outreach recommendation from Monday outreach deltas.
- [ ] Confirm Friday review outputs creator outreach rate deltas (reply/collaboration/cross-post) for prioritization.
- [ ] Confirm Friday review outputs primary/backup variant trendline (consecutive wins).
- [ ] Confirm Friday review outputs primary/backup channel ROI scores from Monday effectiveness signals.
- [ ] Confirm Friday review outputs a channel ROI routing recommendation (primary/backup/balanced lead).
- [ ] Confirm Friday review outputs distribution completion metrics (days completed + score delta).
- [ ] Confirm Friday review outputs a channel-mix recommendation from ROI + distribution execution signals.
- [ ] Confirm Friday review outputs copy-ready primary/backup channel scripts from the selected variants.
- [ ] Confirm `zsh scripts/verify_founder_fame_proof_loop.sh --proof-loop docs/campaigns/<week>-founder-fame-proof-loop.md --strict` passes.
- [ ] Confirm `Monday Publish Checklist <week>` auto-promotes ROI-biased defaults into `Default Publish Drafts (Auto-Promoted)`.
- [ ] Confirm Monday draft comment/artifact is seeded from `Default Publish Drafts (Auto-Promoted)` with parser markers preserved.
- [ ] Confirm stale weekly sprint issues are closed automatically.
- [ ] Confirm previous-week KPI snapshot is auto-filled in new sprint issue.
- [ ] Confirm WoW KPI deltas include baseline week when available.

## Suggested Targets (starting point)

- 3 public posts per week.
- 1 fresh workflow example per week.
- 1 measurable outcome included in every post.
