# Founder Fame Velocity Scoreboard

Use this command to convert founder KPI + command-center + verifier signals into one composite velocity score for the next 72 hours.

## Why

- Keeps velocity posture, route health, and verification state in one operator sheet.
- Makes one clear priority move visible before each publish cycle.
- Produces a checklist-ready comment block for `Monday Publish Checklist <week>`.

## Generate

```sh
zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-velocity-scoreboard.md
```

Required input:

- `--kpi-snapshot`

Optional overlays:

- `--command-center`
- `--proof-loop-check`

Default output path:

- `docs/campaigns/<week>-founder-fame-velocity-scoreboard.md`

## Output sections

- `Snapshot`
- `Velocity Scoreboard`
- `Route Velocity Controls`
- `72-Hour Velocity Plays`
- `Checklist Comment Draft`
- `Share Block`
- `Execution Checklist`

## Typical flow

1. Generate founder fame proof loop + strict verification.
2. Generate founder fame KPI snapshot.
3. Generate founder fame velocity scoreboard.
4. Post `Checklist Comment Draft` into `Monday Publish Checklist <week>` (workflow marker: `weekly-growth-founder-fame-velocity-scoreboard`).
5. Use `Velocity score`, `Tier`, and `Priority move` to decide the next in-app founder action.
