# Founder Fame Escalation Queue

Use this workflow to convert founder risk-response priorities into owner-routed escalation actions for the next 24 hours.

## Why

- Route P1 and P2 risks into explicit execution owners immediately.
- Keep mitigation work tied to sprint, distribution, and reply execution lanes.
- Add clear escalation triggers before launch momentum slips.
- Add a dedicated narrative-route escalation lane when route alignment degrades.

## Generate

```sh
zsh scripts/generate_founder_fame_escalation_queue.sh \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md
```

Required inputs:

- `--risk-response-plan`
- `--execution-scorecard`

Optional overlays:

- `--execution-sprint`
- `--distribution-plan`
- `--reply-pack`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-escalation-queue.md`

## Output sections

- `Snapshot`
- `Escalation Queue Signal`
- `Narrative Route Escalation Lane`
- `Immediate Escalation Queue`
- `Owner Routing Notes`
- `First 24 Hours`
- `Escalation Conditions`
- `Share Block`

## Typical flow

1. Generate the execution scorecard and risk response plan first.
2. Generate this escalation queue to route P1/P2 owners with trigger windows.
3. Execute top queue actions and post evidence updates in the Monday checklist issue.
4. Re-run scorecard + risk response + queue after meaningful execution changes.
5. Promote resolved patterns into next-week default owner routing.
