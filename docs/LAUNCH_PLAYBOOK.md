# Launch Playbook

This playbook is for turning Fluid Reader usage into repeatable social proof and growth.

See [SOCIAL_PROOF_KIT.md](SOCIAL_PROOF_KIT.md) for ready-to-post templates.
See [GROWTH_RELEASE_CHECKLIST.md](GROWTH_RELEASE_CHECKLIST.md) for pre-release execution steps.
See [WEEKLY_POST_PLANNER.md](WEEKLY_POST_PLANNER.md) for campaign planning.
See [DISTRIBUTION_PLAYBOOK.md](DISTRIBUTION_PLAYBOOK.md) for multi-channel execution.
See [CAMPAIGN_AUTOMATION.md](CAMPAIGN_AUTOMATION.md) for generated weekly campaign packs.
See [CREATOR_OUTREACH_KIT.md](CREATOR_OUTREACH_KIT.md) for launch-week creator pitching templates.
See [LAUNCH_DAY_PLAN.md](LAUNCH_DAY_PLAN.md) for day-of execution.
See [WEEKLY_GROWTH_AUTOPILOT.md](WEEKLY_GROWTH_AUTOPILOT.md) for scheduled weekly automation.

## Goal

- Make first value obvious in under 60 seconds.
- Turn everyday wins into shareable proof.
- Increase weekly active users through loops already in the app.

## Core Growth Loop

1. User captures text and gets a useful result fast.
2. User runs `Copy Win Card` or `Copy Win Recap`.
3. User posts result publicly or sends it in a team chat.
4. New people see real usage proof and try the app.
5. New users repeat the same flow.

## 60-Second Activation Flow

Use this flow in demos, onboarding docs, and social posts:

1. Open Commands (`Option + Shift + Space`).
2. Run `Read Selected Text`.
3. Type `2 + 3 * 4`.
4. Type `10 km to miles`.
5. Run `Copy Win Card`.

Success criteria:

- Time-to-first-win under 60 seconds.
- User can explain one daily use case immediately.

## Weekly Campaign Rhythm

### Monday: Problem Clip

- Share a short before/after of a real task.
- End with one command name (`Read Selected Text`, `Ask Anything`, etc.).
- Use the Monday row in [WEEKLY_POST_PLANNER.md](WEEKLY_POST_PLANNER.md).

### Wednesday: Win Proof

- Post `Copy Win Card` output.
- Include one usage metric from local counts.
- Adapt the same proof for two channels using [DISTRIBUTION_PLAYBOOK.md](DISTRIBUTION_PLAYBOOK.md).

### Friday: Workflow Thread

- Post a 3-step workflow from `docs/WORKFLOWS.md`.
- Include one snippet of `Copy Win Recap`.
- Capture top replies for next week’s Monday hook.

## Content Pillars

- **Speed**: show results in seconds.
- **Reliability**: show permission/setup recovery (`Setup Checklist`, `Copy Troubleshooting Guide`).
- **Practicality**: show real writing/dev/research tasks.
- **Delight**: show Ani + Top Picks + Win Card moments.

## Viral Surfaces Already In App

- `Copy Win Card` for visual social proof.
- `Copy Win Recap` for text posts.
- `Copy Win Recap Pack` for quick A/B messaging.
- `Copy Setup Guide` for shareable onboarding.

## Experiment Backlog

- A/B post style: card-first vs recap-first.
- Compare post timing: morning vs evening local time.
- Compare CTA wording: “Try this command” vs “Watch this 10-second flow”.
- Compare demo length: 20-second clip vs 60-second walkthrough.

## Metrics To Track Weekly

- Number of Win Card copies.
- Number of Win Recap copies.
- Number of first-week retained users.
- Number of user-generated posts/screenshots shared.
- Number of inbound installs after public posts.

## Operator Checklist

- Keep `check_fast` green before every release.
- Refresh screenshots/cards weekly.
- Collect 3 new real-world use cases per week.
- Convert best use cases into pinned examples in docs and posts.
- Fill and score [WEEKLY_POST_PLANNER.md](WEEKLY_POST_PLANNER.md) every Friday.
- Generate a weekly draft pack with `zsh scripts/generate_campaign_pack.sh`.
- Use `zsh scripts/run_launch_day.sh` for launch-day checks plus campaign/social-proof/creator-outreach/distribution-plan/viral-experiment-board artifacts.
- If you have an in-app mission artifact, add `--founder-fame-daily-mission docs/campaigns/<week>-founder-fame-daily-mission.md` so founder action queue output inherits the live 3-hour route.
- Optionally run [`Launch Pack Generator`](../.github/workflows/launch-pack.yml) in GitHub Actions.
- Use [`Weekly Growth Sprint`](../.github/workflows/weekly-growth-sprint.yml) to keep one active labeled sprint issue.
- Use [`Weekly Growth Review`](../.github/workflows/weekly-growth-review.yml) to keep Friday KPI coaching on the active sprint issue.
- On manual review runs, set `primary_audience_region` / `backup_audience_region` (`global/us/eu/apac`) to localize Monday publish windows.
- Use review outputs to auto-open either `Growth Recovery Plan <week>` or `Growth Highlight Plan <week>` and keep follow-up execution explicit.
- Reuse the auto-generated Monday draft comment from `Growth Highlight Plan <week>` to publish faster after a strong week.
- Reuse the uploaded Monday draft artifact from weekly review artifacts for quick editing outside GitHub issues.
- Use the auto-managed `Monday Publish Checklist <week>` issue as the execution gate before posting.
- Use the Monday checkpoint comment for time-window, ROI-aware lead-channel order, and first-24-hour response planning.
- Reuse the first-24-hour reply pack comment to answer practical questions faster after posting.
- Reuse the creator outreach kit comment to send focused follow-ups to creators, communities, and hosts.
- Reuse the distribution follow-up plan comment to execute Day 0 to Day 7 amplification without ad-hoc scheduling.
- Reuse reply-pack Variant A/B/C per channel (proof-first, workflow-first, objection-handler) instead of ad-hoc replies.
- Update `Monday Publish Checklist <week>` with posted status, replies sent, and objections captured so Friday review can auto-sync `Reply Pack Effectiveness`.
- Update `Monday Publish Checklist <week>` with creator outreach sent/replies/collaborations/cross-posts so Friday review can auto-sync outreach effectiveness.
- Fill `Primary/Backup top variant` in `Monday Publish Checklist <week>` so Friday review can auto-recommend next-week variant routing.
- Check Friday review variant trendline (consecutive A/B/C wins) before changing weekly routing.
- Check Friday review channel ROI score + recommendation before locking Monday lead channel.
- Check Friday review channel-mix recommendation before setting primary/backup effort split for the week.
- Reuse Friday review channel scripts as Monday draft seed copy, then add one fresh proof asset before publishing.
- Start from ROI-biased `Default Publish Drafts (Auto-Promoted)` in `Monday Publish Checklist <week>` and only deviate when fresh proof clearly changes the angle.
