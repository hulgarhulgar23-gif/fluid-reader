# Founder Fame Transcript Ingestion

Use this workflow to turn a founder interview transcript into quote, objection, and clip signals for repurpose execution.

## Why

- Extract repeatable proof lines from long-form interviews quickly.
- Capture objection signals while they are still fresh from the conversation.
- Feed clip/thread/recap priorities directly into the repurpose plan.
- Keep extraction quality high with speaker-aware parsing, dedupe/noise filtering, and dimension-based quality scoring.

## Generate

```sh
zsh scripts/generate_founder_fame_transcript_ingestion.sh \
  --transcript docs/campaigns/$(date +%Y-W%V)-founder-interview-transcript.md \
  --interview-prep docs/campaigns/$(date +%Y-W%V)-founder-fame-interview-prep.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md
```

Required input:

- `--transcript`

Optional overlays:

- `--interview-prep`
- `--media-blast`

Default output path:

- `docs/campaigns/<week>-founder-fame-transcript-ingestion.md`

## Output sections

- `Snapshot`
- `Transcript Quote Bank`
- `Objection Radar`
- `Clip Candidate List`
- `Quality Diagnostics`
- `Repurpose Priority Mapping`
- `Follow-up Actions`
- `Share Block`

## Typical flow

1. Generate founder interview prep.
2. Run transcript ingestion on the interview transcript (or the prep brief as fallback).
3. Generate repurpose plan with `--transcript-ingestion` so clip/thread priorities stay grounded.
4. Generate momentum brief with `generate_founder_fame_momentum_brief.sh` for 48-hour risk/readiness routing.
5. Publish one quote-led clip and one objection-led thread in the first 24 hours.
