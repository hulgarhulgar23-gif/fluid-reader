# Founder Fame Weight Profile

Use this workflow to calibrate founder momentum signal weights from recent campaign outcomes.

## Why

- Keep readiness scoring aligned with recent bottlenecks, not static assumptions.
- Increase weight on signals that consistently lag the readiness target.
- Reduce blind spots by tracking signal volatility week over week.
- Keep weighting adaptive even in early weeks via uplift bootstrap mode.

## Generate

```sh
zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --campaign-dir docs/campaigns \
  --limit 12 \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md

zsh scripts/generate_founder_fame_weight_profile.sh \
  --campaign-dir docs/campaigns \
  --limit 12 \
  --target-readiness 75 \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md
```

Optional inputs:

- `--campaign-dir`
- `--limit`
- `--target-readiness`
- `--uplift-tracker`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-weight-profile.md`

## Output sections

- `Snapshot`
- `Recommended Weights`
- `Signal Diagnostics`
- `Sample Inputs`
- `Calibration Notes`
- `Share Block`

## Typical flow

1. Generate founder momentum briefs for recent weeks.
2. Generate an uplift tracker from `docs/campaigns` momentum evidence.
3. Generate this weight profile with `--uplift-tracker`.
4. Pass `--weight-profile` into `generate_founder_fame_momentum_brief.sh`.
5. Re-run weekly after Friday review to keep routing adaptive.
