# Founder Fame Ops Brief

Use this command to turn growth execution artifacts into one operator brief for the next 24 hours and next 7 days.

## Why

Launch outputs often live across multiple files (`distribution-plan`, `social-proof-wall`, founder artifacts).
This brief consolidates routing, proof, and founder narrative into a single action-ready handoff.

## Generate

```sh
zsh scripts/generate_founder_fame_ops_brief.sh \
  --week "$(date +%Y-W%V)" \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --social-proof-wall docs/campaigns/$(date +%Y-W%V)-social-proof-wall.md \
  --fame-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --guesting-brief docs/campaigns/$(date +%Y-W%V)-founder-guesting-brief.md
```

Required inputs:

- `--distribution-plan`
- `--social-proof-wall`

Optional founder overlays:

- `--fame-pack`
- `--media-blast`
- `--guesting-brief`

Default output path:

- `docs/campaigns/<week>-founder-fame-ops-brief.md`

## Typical flow

1. Run launch/weekly generators first.
2. Generate this brief.
3. Use the `Next 24 Hours` section for daily execution.
4. Use the `7-Day Fame Sprint` section for weekly routing decisions.
