# Founder Fame Command Center

Use this command to consolidate founder fame momentum, execution, risk, and escalation artifacts into one operator control sheet.

## Why

- Keeps top-bet execution, risk response, and escalation triggers in one place.
- Gives one standup-ready share block for founder + growth leads.
- Prevents context switching across multiple founder fame files during launch week.
- Adds a `Narrative Route Control Tower` so route winner, lane status, and escalation triggers stay synchronized.

## Output sections

- `Snapshot`
- `Narrative Route Control Tower`
- `Next 24 Hours`
- `Trigger Matrix`
- `Standup Share Block`
- `In-App Fast Loop`
- `Update Cadence`
- `Next-Move Handoff` (generated via separate helper script)

## Generate

```sh
zsh scripts/generate_founder_fame_command_center.sh \
  --week "$(date +%Y-W%V)" \
  --momentum-brief docs/campaigns/$(date +%Y-W%V)-founder-fame-momentum-brief.md \
  --execution-scorecard docs/campaigns/$(date +%Y-W%V)-founder-fame-execution-scorecard.md \
  --risk-response-plan docs/campaigns/$(date +%Y-W%V)-founder-fame-risk-response-plan.md \
  --escalation-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-escalation-queue.md \
  --opportunity-radar docs/campaigns/$(date +%Y-W%V)-founder-fame-opportunity-radar.md
```

Required inputs:

- `--momentum-brief`
- `--execution-scorecard`
- `--risk-response-plan`
- `--escalation-queue`

Optional input:

- `--opportunity-radar`

Default output path:

- `docs/campaigns/<week>-founder-fame-command-center.md`

## Typical flow

1. Generate momentum brief, execution scorecard, risk response plan, and escalation queue first.
2. Generate command center.
3. Use the `Next 24 Hours` section for daily owner routing.
4. Use the `Narrative Route Control Tower` to detect mode drift before publishing.
5. Use the `Trigger Matrix` to decide when escalation should fire.
6. Generate next-move handoff:
   - `zsh scripts/generate_founder_fame_next_move_handoff.sh --week "$(date +%Y-W%V)" --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md --artifact-link docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md --out docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md`
7. Generate next-move draft pack:
   - `zsh scripts/generate_founder_fame_next_move_draft_pack.sh --week "$(date +%Y-W%V)" --next-move-handoff docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md --out docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-draft-pack.md`
8. Generate war-room one-sheet:
   - `zsh scripts/generate_founder_fame_war_room.sh --week "$(date +%Y-W%V)" --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md --next-move-handoff docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md --next-move-draft-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-draft-pack.md --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md --narrative-lab docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md --out docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md`
9. Render checklist comment draft (or live upsert) from war-room output:
   - `zsh scripts/post_founder_fame_war_room_comment.sh --war-room docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md --strict --dry-run`
10. Use `In-App Fast Loop` to run `Fame -> Run Fame Next Move` every cycle, then post the owner update.
11. Post the `Standup Share Block` plus next-move handoff block into your Monday checklist issue or daily thread.
12. Paste `X`, `Bluesky`, `LinkedIn`, and `Checklist` blocks from the next-move draft pack into your publishing queue, run the 60-minute publishing cadence plan, and start with the risk + momentum-aware recommended hook variant per channel before testing the other A/B/C options.
13. Before publishing, run `Copy Launch Now Sequence` to copy the recommended cadence step plus the next two channel drafts in one operator block.
14. For fastest single-post execution, run `Copy Post Cadence Now` to copy only the first cadence draft text (no metadata wrapper).
15. If you need the full first beat context, run `Copy First Cadence Step` to grab the exact recommended 0-15m channel draft block.
16. Use `Copy Latest X Draft`, `Copy Latest Bluesky Draft`, or `Copy Latest LinkedIn Draft` when you only need one channel post without opening the full pack.
17. If execution stalls, run `Open Latest Next Move Draft Pack` to resume from the latest saved artifact without regenerating the loop.
18. Post the `weekly-growth-founder-fame-war-room` marker block from the war room in your checklist thread.
19. Generate `generate_founder_fame_spotlight_pack.sh` to publish copy-ready channel drafts from the same signals.
20. Generate `generate_founder_fame_breakout_plan.sh` to run Day 0 to Day 1 script blocks and partnership bursts from the spotlight + command-center stack.
21. Generate `generate_founder_fame_outreach_sprint.sh` to convert breakout scripts into creator + guesting outreach waves.
