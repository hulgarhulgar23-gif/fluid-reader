# Founder Fame Exceptional Loop

Use this when you need a single operator-ready brief that turns recent Fame Snapshot performance into a concrete 72-hour execution loop.

## Generate

```bash
zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --ledger "$HOME/Documents/FluidReader/FameSnapshots/fame-snapshot-ledger.md" \
  --window 12 \
  --out docs/campaigns/$(date '+%Y-W%V')-founder-fame-exceptional-loop.md
```

When running in CI (without a local ledger file), derive the loop from generated founder artifacts:

```bash
zsh scripts/generate_founder_fame_exceptional_loop.sh \
  --kpi-snapshot docs/campaigns/<week>-founder-fame-kpi-snapshot.md \
  --velocity-scoreboard docs/campaigns/<week>-founder-fame-velocity-scoreboard.md \
  --out docs/campaigns/<week>-founder-fame-exceptional-loop.md
```

## What It Produces

- **Signal Snapshot**: current score, velocity, volatility, and streak state.
- **Route Mode**: `Recovery`, `Stabilize`, or `Accelerate`.
- **72-Hour Loop**: day-by-day execution focus with KPI guardrails.
- **Fame Multipliers**: highest-impact actions for the current route.
- **Narrative Hooks**: X, LinkedIn, and checklist update seeds.
- **Operator Marker Block**: machine-readable metadata for workflow checks.

## Checklist Comment Draft / Upsert

```bash
zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
  --exceptional-loop docs/campaigns/<week>-founder-fame-exceptional-loop.md \
  --action-queue docs/campaigns/<week>-founder-fame-action-queue.md \
  --dry-run \
  --out docs/campaigns/<week>-founder-fame-exceptional-loop-comment.md
```

For live upsert:

```bash
zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
  --exceptional-loop docs/campaigns/<week>-founder-fame-exceptional-loop.md \
  --action-queue docs/campaigns/<week>-founder-fame-action-queue.md \
  --repo <owner/repo> \
  --issue <number>
```

The upsert marker is `weekly-growth-founder-fame-exceptional-loop-comment`, so reruns update the same issue comment instead of posting duplicates.

## Live Verification

```bash
zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
  --exceptional-loop docs/campaigns/<week>-founder-fame-exceptional-loop.md \
  --comment docs/campaigns/<week>-founder-fame-exceptional-loop-comment.md \
  --repo <owner/repo> \
  --issue <number> \
  --strict \
  --out docs/campaigns/<week>-founder-fame-exceptional-loop-live-check.md
```

This verifier checks marker uniqueness plus route/readiness/score/velocity field parity between the artifact and the checklist comment body.

## Recommended Operating Cadence

1. Run after each meaningful snapshot cluster (or at least daily).
2. Use the `Route Mode` to choose execution posture for the next 24h.
3. Post one measurable proof update per day and mirror status in checklist comments.
4. Re-run after each proof cycle and track velocity drift in the marker block.
