# Founder Media Blast

Use this artifact to turn founder KPI outputs into a 7-day distribution execution plan.

## Generate Media Blast

```sh
zsh scripts/generate_founder_media_blast.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --update-post .build/founder/founder-update-2026-W23.md \
  --out .build/founder/founder-media-blast-2026-W23.md
```

The generated markdown includes:

- Blast objective and weekly focus
- 7-day channel sequence
- Headline + KPI content queue
- Creator/community DM wave
- Reply operations and escalation playbook
- Daily KPI capture checklist

After media blast generation, you can build a ranked guesting pipeline:

```sh
zsh scripts/generate_founder_guesting_queue.sh \
  --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
  --press-kit .build/founder/founder-press-kit-2026-W23.md \
  --media-blast .build/founder/founder-media-blast-2026-W23.md \
  --out .build/founder/founder-guesting-queue-2026-W23.md
```

## One-Command Weekly Flow

The weekly pack now outputs media blast automatically:

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

## CI / Artifact Flow

To generate this through GitHub Actions:

- [`Founder Fame Pack`](../.github/workflows/founder-fame-pack.yml)
- [`Weekly Growth Review`](../.github/workflows/weekly-growth-review.yml)

## Related Guides

- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_PRESS_KIT.md](FOUNDER_PRESS_KIT.md)
- [FOUNDER_UPDATE_POST.md](FOUNDER_UPDATE_POST.md)
- [FOUNDER_GUESTING_QUEUE.md](FOUNDER_GUESTING_QUEUE.md)
