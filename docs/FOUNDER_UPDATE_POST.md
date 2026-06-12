# Founder Update Post Generator

Use this workflow to create a share-ready weekly founder update from your scoreboard and delta reports.

## Generate Post Pack

```sh
zsh scripts/generate_founder_update_post.sh \
  --scoreboard .build/founder/scoreboard.md \
  --delta .build/founder/weekly-delta-2026-W23.md \
  --out .build/founder/founder-update-2026-W23.md
```

The generated markdown includes:

- KPI snapshot
- Primary channel post draft
- Backup channel post draft
- Comment reply seeds

## Recommended Sequence

1. Generate weekly review (`generate_founder_weekly_review.sh`).
2. Generate week-over-week delta (`generate_founder_weekly_delta.sh`).
3. Generate scoreboard (`generate_founder_scoreboard.sh`).
4. Generate founder update post pack (this script).
5. Generate founder fame pack (`generate_founder_fame_pack.sh`) for weekly distribution execution.
6. Generate founder press kit (`generate_founder_press_kit.sh`) for media/outreach execution.

Or run the one-command pipeline:

```sh
zsh scripts/generate_founder_weekly_pack.sh --help
```

## Related Guides

- [FOUNDER_WEEKLY_REVIEW.md](FOUNDER_WEEKLY_REVIEW.md)
- [FOUNDER_SCOREBOARD.md](FOUNDER_SCOREBOARD.md)
- [FOUNDER_METRICS_QUICKSTART.md](FOUNDER_METRICS_QUICKSTART.md)
- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_PRESS_KIT.md](FOUNDER_PRESS_KIT.md)
