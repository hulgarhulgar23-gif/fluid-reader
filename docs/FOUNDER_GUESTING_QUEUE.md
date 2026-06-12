# Founder Guesting Queue

Use this artifact to turn founder KPI momentum into a ranked weekly interview/newsletter/community booking pipeline.

## Generate Guesting Queue

```sh
zsh scripts/generate_founder_guesting_queue.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-queue-2026-W23.md
```

The generated markdown includes:

- Guesting readiness score and outreach target for the week
- Prioritized show/newsletter/community segments
- A ranked pitch queue
- Copy-ready outreach scripts (podcast, newsletter, community)
- A 7-day booking sprint and tracking checklist

After generating a guesting queue, you can generate a sprint execution brief:

```sh
zsh scripts/generate_founder_guesting_brief.sh \
  --guesting-queue .build/founder/founder-guesting-queue-2026-W23.md \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-brief-2026-W23.md
```

## Founder Guesting Signal Comment Format

Add/update one comment in `Monday Publish Checklist <week>` using this marker format.
Weekly review parses these comments and feeds the highest-signal entries into guesting ranking.

```text
<!-- weekly-growth-founder-guesting-signal -->
- Target: Operator Podcast Network / @host_handle
- Format: podcast
- Stage: replied
- Lead channel: primary
- Priority score: 76
- Warm intro: yes
- Status: booked
```

You can also pass parsed metrics directly via CLI for manual runs:

```sh
zsh scripts/generate_founder_guesting_queue.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --guesting-signal-entries "8" \
  --guesting-signal-replied "4" \
  --guesting-signal-booked "2" \
  --guesting-signal-published "1" \
  --guesting-signal-top-format "podcast" \
  --guesting-signal-top-target "@operatorhost" \
  --guesting-signal-enrichment-score "72" \
  --out .build/founder/founder-guesting-queue-2026-W23.md
```

## One-Command Weekly Flow

The weekly founder pipeline now outputs this automatically:

```sh
zsh scripts/generate_founder_weekly_pack.sh --help
```

Expected founder outputs:

- `weekly-review-<week>.md`
- `weekly-delta-<week>.md`
- `scoreboard-<week>.md`
- `founder-update-<week>.md`
- `founder-fame-pack-<week>.md`
- `founder-press-kit-<week>.md`
- `founder-media-blast-<week>.md`
- `founder-guesting-queue-<week>.md`
- `founder-guesting-brief-<week>.md`

## CI / Artifact Flow

To generate this in GitHub Actions:

- [`Founder Fame Pack`](../.github/workflows/founder-fame-pack.yml)
- [`Weekly Growth Review`](../.github/workflows/weekly-growth-review.yml)

## Related Guides

- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_PRESS_KIT.md](FOUNDER_PRESS_KIT.md)
- [FOUNDER_MEDIA_BLAST.md](FOUNDER_MEDIA_BLAST.md)
- [FOUNDER_GUESTING_BRIEF.md](FOUNDER_GUESTING_BRIEF.md)
