# Founder First 48h Post Pack

Use this to turn founder narrative-lab signals into copy-ready Day 0/Day 1/Day 2 posts.

## What It Generates

- A signal snapshot (winner/mode/strategy/first-48h plan/CTA line)
- Day 0 launch copy block
- Day 1 reinforcement copy block
- Day 2 compounding copy block
- Channel-ready short variants for Day 0/Day 1/Day 2 with primary/backup character budgets
- Tone-aware short variants (`x-punchy`/`x-thread` primary, `linkedin-context`/`linkedin-operator` backup, or `neutral`)
- Route-control handshake values pulled from narrative-lab controls (alignment target, guardrail, lane trigger, recommendation)
- 48-hour micro-experiment board for tone/objection/CTA tests with fallback actions
- Rapid reply prompts
- Comment trigger seeds for Day 0/Day 1/Day 2 post-reply boosts
- Objection response ladder (fast reply, operator reply, conversion CTA)
- Escalation and adaptation triggers for low-response windows
- First-48h execution checklist

## Inputs

- Required: `--narrative-lab`
- Optional: `--week`, `--product`, `--primary-channel`, `--backup-channel`, `--cta`, `--primary-char-limit`, `--backup-char-limit`, `--primary-tone`, `--backup-tone`

## Command

```sh
zsh scripts/generate_founder_first48h_post_pack.sh \
  --week "$(date +%Y-W%V)" \
  --product "Fluid Reader" \
  --narrative-lab ".build/founder/founder-fame-narrative-lab-$(date +%Y-W%V).md" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --cta "If you're building, reply with your KPI bottleneck and I'll share the exact command flow." \
  --primary-char-limit 280 \
  --backup-char-limit 500 \
  --primary-tone x-punchy \
  --backup-tone linkedin-context \
  --out ".build/founder/founder-first48h-post-pack-$(date +%Y-W%V).md"
```

## Output

- `.build/founder/founder-first48h-post-pack-<week>.md`

Weekly review automation can upsert this pack to the Monday checklist using marker:

- `weekly-growth-founder-first48h-post-pack`
- `weekly-growth-founder-first48h-controls-start` / `weekly-growth-founder-first48h-controls-end` (auto-synced controls block parsed by Monday effectiveness extraction as fallback routing context)
