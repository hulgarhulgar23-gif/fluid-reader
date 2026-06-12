# Founder Fame KPI Snapshot

Use this command to compress founder proof-loop + command-center signals into one KPI-first standup brief.

## Why

- Keeps weekly founder KPI targets, routing calls, and verification state in one artifact.
- Gives one copy-ready block for founder, growth, and distribution owner check-ins.
- Reduces context switching before Day 0 to Day 2 execution decisions.
- Adds `Narrative Route KPI Controls` so route winner/mode/alignment stay tied to KPI actions.

## Generate

```sh
zsh scripts/generate_founder_fame_kpi_snapshot.sh \
  --week "$(date +%Y-W%V)" \
  --proof-loop docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md
```

Required input:

- `--proof-loop`

Optional overlays:

- `--command-center`
- `--proof-loop-check`

Default output path:

- `docs/campaigns/<week>-founder-fame-kpi-snapshot.md`

## Output sections

- `Snapshot`
- `KPI Pulse`
- `Verification Pulse`
- `Narrative Route KPI Controls`
- `72-Hour KPI Actions`
- `Share Block`
- `Execution Checklist`

## Typical flow

1. Generate founder fame command center + proof loop.
2. Run strict proof-loop verification.
3. Generate KPI snapshot from proof-loop, command-center, and verification outputs.
4. Generate velocity scoreboard from this KPI snapshot (`generate_founder_fame_velocity_scoreboard.sh`) before opening new lanes.
5. Share the `Share Block` in standup and Monday checklist updates.
6. Use `Narrative Route KPI Controls` to keep route lane alignment and route guardrails locked.
7. Use `Execution Checklist` to confirm Day 0 to Day 2 KPI follow-through before opening new narratives.
