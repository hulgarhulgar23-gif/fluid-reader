# Founder Fame Action Queue

Use this workflow to turn a founder fame ops brief into a ranked Top-3 Monday execution queue.

## Why

- Compress a long founder ops brief into immediate Monday actions.
- Keep ranking explicit so nothing critical slips.
- Make owner assignment and completion windows clear.

## Generate

```sh
zsh scripts/generate_founder_fame_action_queue.sh \
  --ops-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-ops-brief.md \
  --daily-mission ~/Documents/FluidReader/FameSnapshots/fame-daily-mission-$(date +%Y%m%d)-*.md \
  --require-fresh-daily-mission \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md
```

Required input:

- `--ops-brief`

Optional overlays:

- `--daily-mission`
- `--require-fresh-daily-mission` (fails fast if mission date is stale/unparseable)
- `--daily-mission-max-age-days <days>` (default: `1`)

Default output path:

- `docs/campaigns/<week>-founder-fame-action-queue.md`

## Output sections

- `Snapshot`
- `Top 3 Monday Actions`
- `Action Owners`
- `3-Hour Mission Bridge`
- `Queue Notes`
- `Copy Block`

The mission bridge now includes `Mission age (days)`, `Mission freshness`, and a freshness guardrail line so owners can quickly validate whether in-app mission context is still current.

## Typical Monday flow

1. Generate ops brief (`generate_founder_fame_ops_brief.sh`).
2. Run in-app `Run Daily Fame Mission` and grab the latest `fame-daily-mission-*.md` artifact.
3. Generate this action queue with `--daily-mission --require-fresh-daily-mission` so Monday priorities match the live 3-hour route and stale mission files cannot silently route work.
4. Generate interview prep (`generate_founder_fame_interview_prep.sh`) from ops + queue.
5. Assign owners and run ranked actions in order.
6. Post progress updates from the `Copy Block`.
