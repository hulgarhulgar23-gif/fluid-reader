# Founder Fame Repurpose Plan

Use this workflow to turn founder interview and media artifacts into a 7-day repurpose sprint.

## Why

- Convert one founder narrative into multiple channel-native assets.
- Keep clip/thread/recap execution tied to real KPI proof.
- Reduce post-interview drift by assigning immediate repurpose actions.

## Generate

```sh
zsh scripts/generate_founder_fame_repurpose_plan.sh \
  --interview-prep docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md \
  --transcript-ingestion docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --guesting-brief docs/campaigns/$(date +%Y-W%V)-founder-guesting-brief.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-repurpose-plan.md
```

Required inputs:

- `--interview-prep`
- `--media-blast`

Optional overlays:

- `--action-queue`
- `--guesting-brief`
- `--transcript-ingestion`

Default output path:

- `docs/campaigns/<week>-founder-fame-repurpose-plan.md`

## Output sections

- `Snapshot`
- `Repurpose Targets`
- `Asset Matrix`
- `Transcript Signals`
- `7-Day Repurpose Sprint`
- `Copy Starters`
- `Tracking Checklist`
- `Share Block`

## Typical flow

1. Generate founder interview prep.
2. Generate transcript ingestion from interview transcript (optional but recommended).
3. Generate this repurpose plan.
4. Generate a momentum brief (`generate_founder_fame_momentum_brief.sh`) to lock next 48-hour focus.
5. Publish one clip + one proof thread in the first 24 hours.
6. Capture objections and feed them into next week’s founder brief.
