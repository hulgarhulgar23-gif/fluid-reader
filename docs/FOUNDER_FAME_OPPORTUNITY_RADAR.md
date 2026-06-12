# Founder Fame Opportunity Radar

Use this workflow to rank the next highest-leverage founder growth bets from momentum, uplift, and proof artifacts.

## Why

- Convert multiple founder artifacts into one ranked action queue.
- Balance impact, confidence, and execution effort for faster prioritization.
- Keep weekly execution focused on the highest expected fame lift.

## Generate

```sh
zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --narrative-route-winner "Proof-first route" \
  --narrative-route-trend "holding Proof-first route" \
  --narrative-fame-velocity-score "72%" \
  --narrative-route-recommendation "Keep Proof-first route as lead route." \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md
```

Required inputs:

- `--momentum-brief`

Optional overlays:

- `--weight-profile`
- `--uplift-tracker`
- `--winning-hook-library`
- `--credibility-ledger`
- `--narrative-route-winner`
- `--narrative-route-trend`
- `--narrative-fame-velocity-score`
- `--narrative-route-recommendation`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-opportunity-radar.md`

## Output sections

- `Snapshot`
- `Ranked Opportunities`
- `Action Plans`
- `Weekly Fame Bet`
- `Share Block`

When narrative route inputs are provided, the radar boosts the aligned opportunity and logs `Narrative-ranked opportunity` plus boost rationale in `Snapshot`.

## Typical flow

1. Generate momentum, uplift tracker, and weight profile artifacts.
2. Refresh winning hook library and credibility ledger.
3. Generate this opportunity radar.
4. Generate the execution sprint board from this radar.
5. Execute the top-ranked bet in the next 24 hours.
6. Re-run after major reply/distribution updates.
