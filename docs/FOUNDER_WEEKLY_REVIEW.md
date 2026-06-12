# Founder Weekly Review Workflow

Use the weekly review generator to convert your latest numbers into a one-page KPI readout.

## Generate The Review

```sh
zsh scripts/generate_founder_weekly_review.sh \
  --week "$(date +%Y-W%V)" \
  --mrr 42000 \
  --delivery-cost 19000 \
  --acquisition-spend 12000 \
  --new-customers 80 \
  --monthly-contribution 75 \
  --lifetime-months 18 \
  --fixed-cost 10000 \
  --price 50 \
  --variable-cost 30 \
  --out .build/founder/weekly-review.md
```

The script writes:

- Input snapshot
- Margin, ROI, CAC, LTV, LTV/CAC, and break-even units
- A concise founder readout with priority hints

## Paste Into Team Rituals

1. Share the generated markdown in your weekly leadership thread.
2. Use the formula command examples in the file to validate numbers in Commands.
3. Track week-over-week trend of margin and LTV/CAC before scaling spend.

## Generate Week-Over-Week Delta

```sh
zsh scripts/generate_founder_weekly_delta.sh \
  --previous .build/founder/weekly-review-2026-W22.md \
  --current .build/founder/weekly-review-2026-W23.md \
  --out .build/founder/weekly-delta-2026-W23.md
```

This delta report summarizes KPI movement and flags whether unit economics is improving.

## Weekly Operating Cadence (Monday / Friday)

### Monday Ritual (Ship The Weekly Story)

Run one command to generate the full founder pack:

```sh
zsh scripts/generate_founder_weekly_pack.sh \
  --week "$(date +%Y-W%V)" \
  --previous-review .build/founder/weekly-review-2026-W22.md \
  --mrr 42000 \
  --delivery-cost 19000 \
  --acquisition-spend 12000 \
  --new-customers 80 \
  --monthly-contribution 75 \
  --lifetime-months 18 \
  --fixed-cost 10000 \
  --price 50 \
  --variable-cost 30 \
  --target-mrr 50000 \
  --target-margin 55 \
  --target-cac 150 \
  --target-ltv-cac 3.5 \
  --target-new-customers 90 \
  --out-dir .build/founder
```

This one command writes review, delta, scoreboard, update post, fame pack, and press kit drafts in sequence.

### Friday Ritual (Close The Loop)

1. Re-run weekly review and scoreboard with final week data.
2. Compare Monday plan vs Friday reality with the delta report.
3. Pick one KPI recovery or scale experiment for next week.
4. Save the latest review file as next Monday's `--previous-review` input.

## Related Guides

- [FOUNDER_METRICS_QUICKSTART.md](FOUNDER_METRICS_QUICKSTART.md)
- [FOUNDER_SCOREBOARD.md](FOUNDER_SCOREBOARD.md)
- [FOUNDER_UPDATE_POST.md](FOUNDER_UPDATE_POST.md)
- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_PRESS_KIT.md](FOUNDER_PRESS_KIT.md)
- [WORKFLOWS.md](WORKFLOWS.md)
