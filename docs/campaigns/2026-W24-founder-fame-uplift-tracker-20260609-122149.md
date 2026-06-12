<!-- founder-fame-uplift-tracker -->

# Founder Fame Uplift Tracker - 2026-W24

Generated: 2026-06-09 12:22:32 +08
Product: Fluid Reader
Campaign directory: docs/campaigns

## Snapshot

- Samples analyzed: 1
- Transitions analyzed: 0
- Mode: bootstrap-pressure
- Calibration confidence: 9/100
- Latest readiness score: 54.0
- Average readiness delta (next-week): n/a
- Positive delta rate: n/a%
- Top leading signal: distribution health (lift 51.00)
- Readiness mean/min/max: 54.0 / 54.0 / 54.0
- Distribution completion mean/min/max: 0.0 / 0.0 / 0.0

## Uplift Multipliers

- momentum uplift multiplier: 1.006
- distribution uplift multiplier: 1.220
- kpi trendline uplift multiplier: 1.083
- reply quality uplift multiplier: 1.132
- transcript quality uplift multiplier: 1.000
- Applied multiplier vector: momentum 1.006, distribution 1.220, KPI trendline 1.083, reply 1.132, transcript 1.000

## Signal Diagnostics

| Signal | Mean Score | Avg Next-Week Delta | Strong-Bucket Delta | Weak-Bucket Delta | Lift (Strong-Weak) | Uplift Multiplier |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Momentum core | 71.0 | n/a | n/a | n/a | n/a | 1.006 |
| Distribution health | 21.0 | n/a | n/a | n/a | n/a | 1.220 |
| KPI trendline | 57.0 | n/a | n/a | n/a | n/a | 1.083 |
| Reply quality | 48.0 | n/a | n/a | n/a | n/a | 1.132 |
| Transcript quality | 93.0 | n/a | n/a | n/a | n/a | 1.000 |

## Sample Inputs

- 2026-W24 | readiness 54 | source docs/campaigns/2026-W24-founder-fame-momentum-brief.md

## Calibration Notes

- With zero transitions, multipliers use snapshot-pressure bootstrap from current signal means.
- With one or more transitions, multipliers shift toward observed strong-vs-weak next-week lift.
- Strong/weak buckets use a 70-point split on each signal.
- Re-run weekly after new momentum briefs to improve predictive confidence.

## Share Block

```text
Founder fame uplift tracker (2026-W24)
Mode: bootstrap-pressure
Samples: 1
Transitions: 0
Top leading signal: distribution health (lift 51.00)
Multipliers: momentum 1.006, distribution 1.220, KPI trendline 1.083, reply 1.132, transcript 1.000
```
