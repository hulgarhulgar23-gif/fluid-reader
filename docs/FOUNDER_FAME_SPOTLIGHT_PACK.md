# Founder Fame Spotlight Pack

Use this command to convert founder command-center signals into daily public copy for reach, trust, and response velocity.

## Why

- Turns internal standup data into publish-ready channel drafts.
- Keeps public messaging aligned with execution and risk reality.
- Speeds up daily founder visibility without losing narrative quality.
- Adds `Route Integrity Messaging` so public copy stays aligned with route winner and lane status.

## Generate

```sh
zsh scripts/generate_founder_fame_spotlight_pack.sh \
  --week "$(date +%Y-W%V)" \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-spotlight-pack.md
```

Required input:

- `--command-center`

Optional overlays:

- `--momentum-brief`
- `--execution-scorecard`
- `--risk-response-plan`

Default output path:

- `docs/campaigns/<week>-founder-fame-spotlight-pack.md`

## Output sections

- `Snapshot`
- `Daily Spotlight Sequence`
- `Copy-Ready Posts`
- `Community Reply Ladder`
- `Route Integrity Messaging`
- `Live Objection Replies`
- `Media / Partner Pitches`
- `Standup-to-Public Bridge`
- `Execution Checklist`

## Typical flow

1. Generate command center from momentum + execution + risk + escalation artifacts.
2. Generate spotlight pack from command center.
3. Publish one primary and one backup draft.
4. Use objection replies during first 24-hour interactions.
5. Refresh the pack after standup if top bet or risk call changes.
