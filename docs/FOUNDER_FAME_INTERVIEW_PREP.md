# Founder Fame Interview Prep

Use this workflow to generate a talk-track brief for founder interviews, podcasts, newsletter features, and live communities.

## Why

- Convert ops + action artifacts into short, repeatable speaking scripts.
- Keep interview answers anchored to one metric focus and proof stack.
- Rehearse tough-question responses before live founder appearances.

## Generate

```sh
zsh scripts/generate_founder_fame_interview_prep.sh \
  --ops-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-ops-brief.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --press-kit docs/campaigns/$(date +%Y-W%V)-founder-press-kit.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md
```

Required input routes (choose one):

- `--ops-brief` + `--action-queue`
- `--guesting-brief`

Optional overlays:

- `--press-kit`
- `--media-blast`
- `--guesting-brief`

Default output path:

- `docs/campaigns/<week>-founder-fame-interview-prep.md`

## Output sections

- `Snapshot`
- `Opening Scripts` (10-second, 30-second, 2-minute arc)
- `Proof Soundbites`
- `Tough Questions + Answers`
- `CTA Closes`
- `Live Checklist`
- `Share Block`

## Typical flow

1. Generate founder fame ops brief + action queue (or use guesting brief directly).
2. Generate this interview prep brief.
3. Generate transcript ingestion (`generate_founder_fame_transcript_ingestion.sh`) from interview transcript + this prep.
4. Generate a repurpose plan (`generate_founder_fame_repurpose_plan.sh`) with `--transcript-ingestion`.
5. Rehearse opener + tough-question set before each live slot.
