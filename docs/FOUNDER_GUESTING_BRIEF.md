# Founder Guesting Sprint Brief

Use this artifact to convert the weekly guesting queue into a tight 72-hour execution brief with booking goals, narrative spine, and follow-up operations.

## Generate Guesting Sprint Brief

```sh
zsh scripts/generate_founder_guesting_brief.sh \
  --guesting-queue .build/founder/founder-guesting-queue-2026-W23.md \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-brief-2026-W23.md
```

The generated markdown includes:

- Fame-to-guesting KPI snapshot
- A 72-hour booking plan for top targets
- Interview narrative spine with KPI proof stack
- Copy-ready host hooks (podcast/newsletter/community)
- Follow-up ops rules (SLA + objection conversion)
- A weekly tracking checklist

## One-Command Weekly Flow

The weekly founder pipeline now outputs this automatically:

```sh
zsh scripts/generate_founder_weekly_pack.sh --help
```

Expected founder outputs now include:

- `founder-guesting-brief-<week>.md`

## CI / Artifact Flow

To generate this in GitHub Actions:

- [`Founder Fame Pack`](../.github/workflows/founder-fame-pack.yml)
- [`Weekly Growth Review`](../.github/workflows/weekly-growth-review.yml)

## Related Guides

- [FOUNDER_GUESTING_QUEUE.md](FOUNDER_GUESTING_QUEUE.md)
- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_MEDIA_BLAST.md](FOUNDER_MEDIA_BLAST.md)
