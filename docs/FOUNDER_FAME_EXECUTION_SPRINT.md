# Founder Fame Execution Sprint

Use this workflow to convert the founder opportunity radar into a concrete 7-day execution board with owners, daily missions, and escalation rules.

## Why

- Turn ranked opportunities into a day-by-day shipping plan.
- Keep founder distribution, replies, and proof updates synchronized.
- Reduce execution drift by adding explicit daily checkpoints and escalation triggers.
- Auto-switch Day 1-Day 3 mission mode based on the weekly narrative route winner.

## Generate

```sh
zsh scripts/generate_founder_fame_execution_sprint.sh \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md
```

Required inputs:

- `--opportunity-radar`

Optional overlays:

- `--momentum-brief`
- `--distribution-plan`
- `--monday-checkpoint`
- `--reply-pack`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-execution-sprint.md`

## Output sections

- `Snapshot`
- `Weekly Fame Objective`
- `Narrative Route Execution Mode`
- `7-Day Mission Board`
- `Daily Check-In Prompts`
- `Escalation Triggers`
- `Share Block`

## Typical flow

1. Generate founder fame momentum brief and opportunity radar.
2. Refresh distribution plan, Monday checkpoint, and reply pack.
3. Generate this execution sprint board.
4. Run Day 0 through Day 6 mission checks daily.
5. Re-run when the top bet, route winner, routing recommendation, or risk call changes.
