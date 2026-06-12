# Founder Fame Outreach Sprint

Use this command to convert breakout publishing signals into an owner-ready creator + guesting outreach sprint.

## Why

- Turns breakout narratives into daily outbound actions with clear success signals.
- Aligns creator DMs, guesting pitches, and distribution follow-ups in one sheet.
- Computes a lane-aware touch mix so creator and guesting effort stays intentional.
- Helps the team run practical reach compounding without improvising copy each day.
- Adds `Narrative Route Outreach Controls` so outreach touch plans stay aligned to route winner and lane status.

## Generate

```sh
zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --week "$(date +%Y-W%V)" \
  --breakout-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md \
  --guesting-queue .build/founder/founder-guesting-queue-$(date +%Y-W%V).md \
  --creator-target-list docs/campaigns/$(date +%Y-W%V)-creator-target-list.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --media-blast .build/founder/founder-media-blast-$(date +%Y-W%V).md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-outreach-sprint.md
```

Required input:

- `--breakout-plan`

Optional overlays:

- `--guesting-queue`
- `--creator-target-list`
- `--distribution-plan`
- `--media-blast`

Default output path:

- `docs/campaigns/<week>-founder-fame-outreach-sprint.md`

## Output sections

- `Snapshot`
- `Outreach Thesis`
- `Narrative Route Outreach Controls`
- `Lane Allocation Scorecard`
- `7-Day Outreach Sprint Grid`
- `Creator Conversation Blocks`
- `Guesting Booking Blocks`
- `Follow-Up Cadence`
- `Daily Standup Prompts`
- `Execution Checklist`

## Typical flow

1. Generate breakout plan from spotlight, execution, and distribution signals.
2. Layer guesting queue and creator target list context into outreach sprint.
3. Execute Day 0 and Day 1 creator + guesting actions.
4. Log booked/collab-ready signals in Monday checklist comments.
5. Use `Narrative Route Outreach Controls` to enforce route lane guardrails before scaling touch volume.
6. Refresh weekly defaults from the winning script variant.
