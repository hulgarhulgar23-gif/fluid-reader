<!-- founder-fame-weight-profile -->

# Founder Fame Weight Profile - 2026-W24

Generated: 2026-06-08 23:16:29 +08
Product: Fluid Reader
Campaign directory: docs/campaigns

## Snapshot

- Samples analyzed: 1
- Target readiness score: 75
- Mode: default (insufficient historical samples)
- Calibration confidence: 12/100
- Uplift tracker: Founder Fame Uplift Tracker - 2026-W24
- Uplift mode: bootstrap-pressure
- Uplift source: docs/campaigns/2026-W24-founder-fame-uplift-tracker.md
- Top pressure signal: distribution (35.1)
- Applied uplift multipliers: momentum 1.006, distribution 1.220, KPI trendline 1.083, reply 1.132, transcript 1.000
- Applied weight vector: momentum 0.277, distribution 0.246, KPI trendline 0.199, reply 0.187, transcript 0.092
- Readiness mean/min/max: 54.0 / 54.0 / 54.0

## Recommended Weights

- momentum weight: 0.277
- distribution weight: 0.246
- kpi trendline weight: 0.199
- reply quality weight: 0.187
- transcript quality weight: 0.092

## Signal Diagnostics

| Signal | Mean | Min | Max | Pressure | Recommended Weight |
| --- | ---: | ---: | ---: | ---: | ---: |
| Momentum core | 71.0 | 71.0 | 71.0 | 2.6 | 0.277 |
| Distribution health | 21.0 | 21.0 | 21.0 | 35.1 | 0.246 |
| KPI trendline | 57.0 | 57.0 | 57.0 | 11.7 | 0.199 |
| Reply quality | 48.0 | 48.0 | 48.0 | 17.6 | 0.187 |
| Transcript quality | 93.0 | 93.0 | 93.0 | 0.0 | 0.092 |

## Sample Inputs

- docs/campaigns/2026-W24-founder-fame-momentum-brief.md

## Calibration Notes

- If fewer than 3 valid momentum briefs are available, this profile preserves default base weights.
- Pressure combines readiness gap pressure (65%) and volatility pressure (35%).
- Uplift multipliers bias pressure-based weighting toward signals with observed next-week lift.
- Re-run weekly after Friday review to keep weighting aligned to observed bottlenecks.

## Share Block

```text
Founder fame weight profile (2026-W24)
Mode: default (insufficient historical samples)
Samples: 1
Uplift mode: bootstrap-pressure
Top pressure signal: distribution (35.1)
Weights: momentum 0.277, distribution 0.246, KPI trendline 0.199, reply 0.187, transcript 0.092
```
