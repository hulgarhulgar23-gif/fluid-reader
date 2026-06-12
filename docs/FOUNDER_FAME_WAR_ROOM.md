# Founder Fame War Room

Use `generate_founder_fame_war_room.sh` to collapse command-center routing, next-move action, and publishing drafts into one execution-ready brief.

## Inputs

Required:

- `--command-center`
- `--next-move-handoff`
- `--next-move-draft-pack`

Optional:

- `--proof-loop-check`
- `--narrative-lab`
- `--week`
- `--product`

Default output path:

- `docs/campaigns/<week>-founder-fame-war-room.md`

## Generator command

```sh
zsh scripts/generate_founder_fame_war_room.sh \
  --week "$(date +%Y-W%V)" \
  --command-center docs/campaigns/$(date +%Y-W%V)-founder-fame-command-center.md \
  --next-move-handoff docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-handoff.md \
  --next-move-draft-pack docs/campaigns/$(date +%Y-W%V)-founder-fame-next-move-draft-pack.md \
  --proof-loop-check docs/campaigns/$(date +%Y-W%V)-founder-fame-proof-loop-check.md \
  --narrative-lab docs/campaigns/$(date +%Y-W%V)-founder-fame-narrative-lab.md \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md
```

## What this gives you

- A single `Launch Control` block with run-now command + artifact + owner update.
- Ready-to-paste `X`, `LinkedIn`, and checklist draft blocks.
- A `90-Minute Execution Sprint` timeline for rapid operator handoff.
- A `weekly-growth-founder-fame-war-room` checklist marker block for issue comments.

## Verification

```sh
zsh scripts/verify_founder_fame_war_room.sh \
  --war-room docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md \
  --strict \
  --out docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room-check.md
```

Use strict mode before checklist posting so run-now action, draft quality, and marker payload stay launch-ready.

## Checklist comment upsert

Render and validate the checklist comment locally first:

```sh
zsh scripts/post_founder_fame_war_room_comment.sh \
  --war-room docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --strict \
  --dry-run
```

Then run a live upsert (auto-detects `Monday Publish Checklist <week>` when possible):

```sh
zsh scripts/post_founder_fame_war_room_comment.sh \
  --war-room docs/campaigns/$(date +%Y-W%V)-founder-fame-war-room.md \
  --action-queue docs/campaigns/$(date +%Y-W%V)-founder-fame-action-queue.md \
  --strict
```

Optional live overrides:

- `--repo <owner/repo>` when repo auto-detection is ambiguous.
- `--issue <number>` when checklist issue title matching returns multiple candidates.
- `--action-queue <path>` to include daily mission source/freshness context directly in the checklist comment.
- `--out <path>` to keep a checked-in copy of the rendered comment body.

The upsert marker is `weekly-growth-founder-fame-war-room-comment`, so reruns update the same issue comment instead of posting duplicates.

In GitHub Actions, set `post_war_room_comment=true` (and optionally `war_room_comment_issue=<number>`) in `founder-fame-pack.yml` workflow dispatch inputs to publish automatically after strict war-room verification.

## Live checklist verification

Verify the latest founder fame pack run (downloads war-room artifact, checks marker payload, and validates checklist comment sync if issue is resolvable):

```sh
zsh scripts/verify_founder_fame_war_room_run.sh \
  --repo <owner/repo> \
  --strict
```

You can pin a run with `--run-id <id>`, or verify local artifacts directly with `--war-room <path> --comment <path>`.

## Typical cadence

1. Run command center and next-move artifacts first.
2. Generate war room.
3. Execute the 90-minute sprint immediately.
4. Upsert the generated checklist comment into `Monday Publish Checklist <week>`.
