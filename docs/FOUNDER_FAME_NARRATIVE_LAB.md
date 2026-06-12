# Founder Fame Narrative Lab

Use this when you want one ranked narrative-routing board from founder KPI, proof-loop, hook, and credibility signals.

## What It Generates

- Snapshot of current founder proof + verification status
- Fame velocity dashboard (score + posture + signal decisions)
- Narrative route control layer (`Narrative Route Lab Controls`)
- First-48h route execution plan (`Day 0` / `Day 1` / `Day 2`) tied to lead/support lanes
- Ranked narrative routes (proof-first, behind-the-scenes, objection-breaker)
- Channel-ready scripts for primary + backup channels
- Region-aware 7-day distribution calendar with publish windows
- 7-day narrative cadence table
- Reply ladder and execution checklist
- Route remix matrix for trigger-based format switching

## Inputs

- Required: `--kpi-snapshot`
- Optional overlays:
  - `--proof-loop`
  - `--command-center`
  - `--winning-hook-library`
  - `--credibility-ledger`
  - `--primary-audience-region` / `--backup-audience-region` for region-specific windows

## Command

```sh
zsh scripts/generate_founder_fame_narrative_lab.sh \
  --week "$(date +%Y-W%V)" \
  --kpi-snapshot "docs/campaigns/$(date +%Y-W%V)-founder-fame-kpi-snapshot.md" \
  --proof-loop "docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop.md" \
  --command-center "docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md" \
  --winning-hook-library "docs/campaigns/$(date +%Y-W%V)-winning-hook-library.md" \
  --credibility-ledger "docs/campaigns/$(date +%Y-W%V)-credibility-ledger.md" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --primary-audience-region "global" \
  --backup-audience-region "us" \
  --out "docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md"
```

## Output

- `docs/campaigns/<week>-founder-fame-narrative-lab.md`

Run this after proof-loop verification + KPI snapshot generation so route ranking stays evidence-backed.

Key route block:

- `Narrative Route Lab Controls` keeps winner/trend/mode/alignment/lane status/guardrail decisions visible before you publish.
- `7-Day Distribution Calendar` maps lead/support channel windows by audience region so teams can execute daily without re-planning time slots.
- Weekly growth review automation parses these control lines and syncs route mode/alignment/lane-status/guardrail/control recommendation + first-48h execution plan into Friday review + sprint effectiveness updates.
- When controls indicate `Route Recovery` or a `Critical` lane, weekly growth review automation opens `Growth Incident: Founder Narrative Route Control <week>` (`weekly-growth-founder-narrative-route-incident`) and mirrors escalation status on the checklist via `weekly-growth-founder-narrative-route-critical`.
- Critical escalation policy is configurable through weekly review inputs (`narrative_route_critical_threshold`, `narrative_route_critical_assignee`, `narrative_route_critical_assignees`, `narrative_route_critical_comment_cooldown_hours`, `narrative_route_critical_comment_min_occurrence_delta`).
- Critical-route owner execution tasks are mirrored into checklist comment `weekly-growth-founder-narrative-route-owner-queue` while escalation is active.
- Checklist issue body block `weekly-growth-founder-narrative-route-owner-queue-start` is auto-managed during escalation, and checked queue tasks are reused to auto-close owner tasks in subsequent reruns.
- Incident issue body also mirrors the owner task queue in block `weekly-growth-founder-narrative-route-owner-sync-start` while escalation is active.
