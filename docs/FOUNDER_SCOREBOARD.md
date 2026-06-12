# Founder KPI Scoreboard

Use this workflow to turn weekly targets and actuals into a concise, status-driven founder scoreboard.

## Generate Scoreboard

```sh
zsh scripts/generate_founder_scoreboard.sh \
  --week "$(date +%Y-W%V)" \
  --target-mrr 50000 \
  --target-margin 55 \
  --target-cac 150 \
  --target-ltv-cac 3.5 \
  --target-new-customers 90 \
  --actual-mrr 48000 \
  --actual-margin 53 \
  --actual-cac 160 \
  --actual-ltv-cac 3.2 \
  --actual-new-customers 84 \
  --out .build/founder/scoreboard.md
```

This generates:

- KPI status summary (`On Track`, `At Risk`, `Off Track`)
- Target vs actual table
- Weekly action prompts

## Operating Rhythm

1. Run scoreboard after updating weekly numbers.
2. Share the markdown in your leadership channel.
3. Assign one owner and one experiment for each `Off Track` KPI.
4. Pair with the weekly delta report before deciding budget shifts.

## Related Guides

- [FOUNDER_METRICS_QUICKSTART.md](FOUNDER_METRICS_QUICKSTART.md)
- [FOUNDER_WEEKLY_REVIEW.md](FOUNDER_WEEKLY_REVIEW.md)
- [FOUNDER_UPDATE_POST.md](FOUNDER_UPDATE_POST.md)
- [FOUNDER_FAME_PACK.md](FOUNDER_FAME_PACK.md)
- [FOUNDER_PRESS_KIT.md](FOUNDER_PRESS_KIT.md)
