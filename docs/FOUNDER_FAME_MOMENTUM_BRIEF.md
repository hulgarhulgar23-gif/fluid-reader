# Founder Fame Momentum Brief

Use this workflow to synthesize founder artifacts into one momentum decision brief for the next 48 hours.

## Why

- Collapse scattered founder outputs into one operator-ready decision layer.
- Score fame readiness from momentum, distribution health, KPI trendline, reply quality, and transcript quality.
- Keep clip/thread/press actions aligned to one narrative stack.

## Generate

```sh
zsh scripts/generate_founder_fame_uplift_tracker.sh \
  --campaign-dir docs/campaigns \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md

zsh scripts/generate_founder_fame_weight_profile.sh \
  --campaign-dir docs/campaigns \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md

zsh scripts/generate_founder_fame_momentum_brief.sh \
  --fame-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-pack.md \
  --repurpose-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-repurpose-plan.md \
  --transcript-ingestion docs/campaigns/$(date +%Y-W%V)-founder-fame-transcript-ingestion.md \
  --press-kit docs/campaigns/$(date +%Y-W%V)-founder-press-kit.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md

zsh scripts/generate_founder_fame_opportunity_radar.sh \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --weight-profile docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md \
  --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md

zsh scripts/generate_founder_fame_execution_sprint.sh \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --monday-checkpoint docs/campaigns/$(date +%Y-W%V)-monday-checkpoint.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md

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

zsh scripts/generate_founder_fame_escalation_queue.sh \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --reply-pack docs/campaigns/$(date +%Y-W%V)-reply-pack.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md

zsh scripts/generate_founder_fame_command_center.sh \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --escalation-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md

zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md

zsh scripts/generate_founder_fame_breakout_plan.sh \
  --spotlight-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md

zsh scripts/generate_founder_fame_outreach_sprint.sh \
  --breakout-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md \
  --creator-target-list docs/campaigns/$(date +%Y-W%V)-creator-target-list.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --media-blast docs/campaigns/$(date +%Y-W%V)-founder-media-blast.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-outreach-sprint.md
```

Required inputs:

- `--fame-pack`
- `--repurpose-plan`

Optional overlays:

- `--transcript-ingestion`
- `--press-kit`
- `--media-blast`
- `--credibility-ledger`
- `--weight-profile`

Default output path:

- `docs/campaigns/<week>-founder-fame-momentum-brief.md`

## Output sections

- `Snapshot`
- `Fame Readiness Score`
- `Signal Fusion Breakdown`
- `Narrative Stack`
- `Risk Radar`
- `Next 48 Hours`
- `Founder Share Block`

## Typical flow

1. Generate founder fame pack, transcript ingestion, and repurpose plan.
2. Generate/refresh a founder fame uplift tracker from recent momentum briefs.
3. Generate/refresh a founder fame weight profile with uplift-aware biasing.
4. Generate this momentum brief to choose the next 48-hour execution focus.
5. Generate the opportunity radar and execute the top-ranked bet.
6. Generate the execution sprint board and run daily owner check-ins.
7. Generate the execution scorecard and resolve the highest execution risk before scaling spend.
8. Generate the risk response plan and run the first two mitigation tasks inside 24 hours.
9. Generate the escalation queue and route P1/P2 owners with explicit trigger windows.
10. Generate the command center and run standups from one shared control sheet.
11. Generate the spotlight pack and publish one proof-first draft on primary + backup channels.
12. Generate the breakout plan and run Day 0 to Day 1 script blocks + partner bursts.
13. Generate the outreach sprint and run creator + guesting waves with owner checks.
14. Ship one quote-led clip and one objection-led thread from the brief.
15. Re-run after major reply waves to refresh risk and readiness.
