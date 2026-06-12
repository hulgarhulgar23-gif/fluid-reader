# Founder Fame Uplift Tracker

Use this workflow to quantify which founder momentum signals most improve next-week readiness.

## Why

- Move from static assumptions to evidence-backed signal prioritization.
- Estimate uplift multipliers from observed strong-vs-weak signal buckets.
- Bootstrap early weeks with snapshot-pressure multipliers when transition history is sparse.
- Feed uplift bias directly into weekly weight-profile generation.

## Generate

```sh
zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --campaign-dir docs/campaigns \
  --limit 16 \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md
```

Optional inputs:

- `--campaign-dir`
- `--limit`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-uplift-tracker.md`

## Output sections

- `Snapshot`
- `Uplift Multipliers`
- `Signal Diagnostics`
- `Sample Inputs`
- `Calibration Notes`
- `Share Block`

## Typical flow

1. Generate or refresh recent founder momentum briefs.
2. Generate this uplift tracker from `docs/campaigns`.
3. Pass `--uplift-tracker` into `generate_founder_fame_weight_profile.sh`.
4. Pass the updated weight profile into `generate_founder_fame_momentum_brief.sh`.
5. Re-run weekly after Friday review to keep scoring aligned with observed outcomes.
