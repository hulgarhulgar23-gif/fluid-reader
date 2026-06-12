# Founder Fame Breakout Plan

Use this command to turn spotlight + execution signals into one weekly breakout publishing plan.

## Why

- Keeps founder narrative, hook routing, and distribution cadence in one sheet.
- Aligns daily posting with execution readiness and risk guardrails.
- Adds an explicit outreach lane strategy for creator vs guesting focus.
- Bridges internal standup context to external visibility and trust loops.
- Adds a `Narrative Route Scale Plan` so breakout execution stays route-locked during expansion.

## Generate

```sh
zsh scripts/generate_founder_fame_breakout_plan.sh \
  --week "$(date +%Y-W%V)" \
  --spotlight-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --execution-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-sprint.md \
  --distribution-plan docs/campaigns/$(date +%Y-W%V)-distribution-plan.md \
  --winning-hook-library docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md
```

Required input:

- `--spotlight-pack`

Optional overlays:

- `--command-center`
- `--execution-sprint`
- `--distribution-plan`
- `--winning-hook-library`
- `--credibility-ledger`

Default output path:

- `docs/campaigns/<week>-founder-fame-breakout-plan.md`

## Output sections

- `Snapshot`
- `Breakout Thesis`
- `Narrative Route Scale Plan`
- `7-Day Fame Cadence`
- `Channel Script Blocks`
- `Partnership Bursts`
- `Fame Flywheel Metrics`
- `Daily Standup Prompts`
- `Execution Checklist`

## Typical flow

1. Generate command center + spotlight pack from momentum/execution/risk artifacts.
2. Generate breakout plan from spotlight and optional overlays.
3. Publish Day 0 + Day 1 scripts on primary and backup channels.
4. Use the partnership burst section to run creator and guesting pushes.
5. Generate `generate_founder_fame_outreach_sprint.sh` to convert breakout guidance into daily outreach actions.
6. Refresh after major reply waves and update Monday checklist comments.
