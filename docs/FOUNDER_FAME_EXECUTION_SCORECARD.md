# Founder Fame Execution Scorecard

Use this workflow to score how execution-ready the weekly founder fame plan is before (and during) distribution.

## Why

- Add one numeric execution-readiness signal to the founder stack.
- Catch weak owner/day coverage before launch momentum is lost.
- Keep daily missions, reply coverage, and escalation triggers aligned.
- Flag when route winner, ranked opportunity, and execution mode drift out of alignment.

## Generate

```sh
zsh scripts/generate_founder_fame_execution_scorecard.sh \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md

zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md
```

Required inputs:

- `--execution-sprint`

Optional overlays:

- `--opportunity-radar`
- `--momentum-brief`
- `--distribution-plan`
- `--monday-checkpoint`
- `--reply-pack`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-execution-scorecard.md`

## Output sections

- `Snapshot`
- `Narrative Route Alignment`
- `Execution Readiness Score`
- `Signal Breakdown`
- `Launch Gates`
- `Daily Rhythm Checks`
- `Risk Flags`
- `Next 24 Hours`
- `Share Block`

## Typical flow

1. Generate execution sprint from momentum + radar + launch ops artifacts.
2. Generate this scorecard to check coverage quality before posting.
3. Resolve highest-risk flag before Day 0 publish.
4. Generate the risk response plan and execute P1/P2 mitigation owners in the first 24 hours.
5. Re-run after Day 2 and Day 5 check-ins.
6. Feed scorecard outcomes into Friday review notes.
