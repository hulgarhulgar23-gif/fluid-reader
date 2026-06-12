# Founder Fame Proof Loop

Use this command to convert breakout + outreach signals into one 72-hour proof loop playbook.

## Why

- Keeps public proof moves and outreach cadence tightly coupled.
- Turns lane targets into daily operator actions that can be logged quickly.
- Creates one repeatable loop for narrative, proof, replies, and conversions.
- Reduces improvisation during high-visibility founder weeks.
- Adds `Narrative Route Proof Lane` to keep proof scripts aligned with route signal and mode.

## Generate

```sh
zsh scripts/generate_founder_fame_proof_loop.sh \
  --week "$(date +%Y-W%V)" \
  --breakout-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-breakout-plan.md \
  --outreach-sprint docs/campaigns/$(date +%Y-W%V)-founder-fame-outreach-sprint.md \
  --spotlight-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --credibility-ledger docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md
```

Required input:

- `--breakout-plan`

Optional overlays:

- `--outreach-sprint`
- `--spotlight-pack`
- `--command-center`
- `--credibility-ledger`

Default output path:

- `docs/campaigns/<week>-founder-fame-proof-loop.md`

## Output sections

- `Snapshot`
- `Proof Loop Scorecard`
- `Narrative Route Proof Lane`
- `72-Hour Loop Plan`
- `Channel Proof Scripts`
- `Conversion Signals to Log`
- `Daily Standup Prompts`
- `Execution Checklist`

## Verify quality

Run a strict quality gate before sharing or automating this artifact:

```sh
zsh scripts/verify_founder_fame_proof_loop.sh \
  --proof-loop docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md \
  --strict
```

This fails when critical proof-loop fields are placeholders or conversion targets are too weak to execute confidently.

## Typical flow

1. Generate breakout and outreach sprint artifacts.
2. Generate proof loop from breakout + outreach (+ optional overlays).
3. Ship Day 0 primary proof post and the first outreach wave.
4. Ship Day 1 backup reinforcement and follow-up wave.
5. Use `Narrative Route Proof Lane` to keep route signal and proof intensity synchronized.
6. Close Day 2 objection-proof loop and update Monday checklist owner defaults.
