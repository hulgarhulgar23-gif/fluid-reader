# Campaign Packs

This folder holds generated weekly campaign packs.

Generate one with:

```sh
zsh scripts/generate_campaign_pack.sh --out docs/campaigns/$(date +%Y-W%V).md
```

Each pack includes Monday/Wednesday/Friday post drafts, channel variants, and reply prompts.

For launch-day automation, run:

```sh
zsh scripts/run_launch_day.sh --primary-channel "X / Threads" --backup-channel "LinkedIn"
```

Or run
[`Launch Pack Generator`](../../.github/workflows/launch-pack.yml)
from GitHub Actions.

For weekly automation and issue generation, run
[`Weekly Growth Sprint`](../../.github/workflows/weekly-growth-sprint.yml).
