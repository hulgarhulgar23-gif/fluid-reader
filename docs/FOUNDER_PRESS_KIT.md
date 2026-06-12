# Founder Press Kit

Use this workflow to generate founder storytelling assets (press + outreach + talking points) from the weekly fame pack.

## Generate Press Kit

```sh
zsh scripts/generate_founder_press_kit.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --out .build/founder/founder-press-kit-2026-W23.md
```

The generated markdown includes:

- Narrative snapshot from current momentum and KPI proof
- Headline angle options
- Press release lead
- Podcast + newsletter pitch drafts
- Channel-specific DM outreach snippets
- Interview talking points
- A 48-hour media sprint checklist

## One-Command Flow

The weekly orchestrator also emits this artifact automatically:

```sh
zsh scripts/generate_founder_weekly_pack.sh --help
```

To turn press narratives into concrete booking targets, generate:

```sh
zsh scripts/generate_founder_guesting_queue.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-queue-2026-W23.md
```

## Related Guides

- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_UPDATE_POST.md](FOUNDER_UPDATE_POST.md)
- [FOUNDER_WEEKLY_REVIEW.md](FOUNDER_WEEKLY_REVIEW.md)
- [FOUNDER_GUESTING_QUEUE.md](FOUNDER_GUESTING_QUEUE.md)
