# Founder Fame Risk Response Plan

Use this workflow to convert execution scorecard risk flags into a concrete 72-hour mitigation plan.

## Why

- Turn readiness gaps into owner-assigned recovery actions immediately.
- Reduce launch slippage by timeboxing high-risk mitigation work.
- Keep top-bet narrative execution stable while fixing weak signals.
- Force route winner, ranked opportunity, and execution mode back into alignment when drift appears.

## Generate

```sh
zsh scripts/generate_founder_fame_risk_response_plan.sh \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md

zsh scripts/generate_founder_fame_escalation_queue.sh \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md
```

Required inputs:

- `--execution-scorecard`

Optional overlays:

- `--execution-sprint`
- `--opportunity-radar`
- `--momentum-brief`
- `--distribution-plan`
- `--reply-pack`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-risk-response-plan.md`

## Output sections

- `Snapshot`
- `Risk Response Signal`
- `Narrative Route Risk Controls`
- `Priority Risk Queue`
- `72-Hour Stabilization Plan`
- `Mitigation Checkpoints`
- `Escalation Conditions`
- `Share Block`

## Typical flow

1. Generate execution scorecard from sprint + launch operation artifacts.
2. Generate this risk response plan to assign mitigation owners and deadlines.
3. Execute P1 and P2 mitigation tasks inside the first 24 hours.
4. Generate the escalation queue to route P1/P2 owners with escalation triggers.
5. Re-run scorecard and this plan after meaningful execution updates.
6. Promote successful mitigation patterns into next-week default launch rhythm.
