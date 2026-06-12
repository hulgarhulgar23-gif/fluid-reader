# Distribution Playbook

Use this playbook to distribute one Fluid Reader proof asset across multiple channels without changing product code.

Generate an auto-routed 7-day execution draft with:

```sh
zsh scripts/generate_distribution_followup_plan.sh --out docs/campaigns/$(date +%Y-W%V)-distribution-plan.md
```

Pair it with a weekly viral experiment board to prioritize what to test next:

```sh
zsh scripts/generate_viral_experiment_board.sh --out docs/campaigns/$(date +%Y-W%V)-viral-experiment-board.md
```

Use Friday review `Channel mix recommendation` to choose a default split (for example `60/40`, `70/30`, or `50/50`) before posting.

Primary assets:

- `Copy Win Card` image
- `Copy Win Recap` text
- `Copy Win Recap Pack` variants

## Core Principle

One proof, many wrappers:

1. Capture one real result from your daily work.
2. Share the same result in channel-native formats.
3. Link back to one practical command/workflow.

## Channel Packaging

### X / Threads

- Lead with one outcome line.
- Attach one `Copy Win Card` image.
- Keep body to 3 to 5 short lines.
- End with one direct CTA.

Example:

```text
I turned a repetitive 5-minute cleanup into 45 seconds.

Used:
- Option + Shift + Space
- Read Selected Text
- Copy Win Card
```

### LinkedIn

- Use context → problem → workflow → result.
- Mention one command by name.
- Include one screenshot or Win Card.
- Ask one discussion question to invite comments.

### Reddit / Hacker News comments

- Skip hype language.
- Share exact steps and one caveat.
- Include measured gain from real use.
- Offer to share command details if asked.

### Team Slack / Discord

- Post one short recap + one image.
- Add a “try this in 60 seconds” mini checklist.
- Ask for one volunteer use case to feature next week.

## 24-Hour Reply Loop

Within 24 hours of posting:

1. Reply to every practical question with exact commands.
2. Turn common questions into one new FAQ/docs update.
3. Save best user response for next week’s Monday post.

## Reuse Templates

### Reply: “How do I start?”

```text
Start with this 60-second path:
1) Option + Shift + Space
2) Read Selected Text
3) Copy Win Card
```

### Reply: “What’s the real benefit?”

```text
For me, the gain is [X minutes saved] on [task] each day.
The key is using [command] immediately after selecting text.
```

### Reply: “Is this private?”

```text
Default mode is local on Mac (OCR + capture on device).
I only enable LLM when I want it.
```

## Weekly Distribution Targets

- 3 public posts (Mon/Wed/Fri)
- 1 community comment thread
- 3 reply-based micro demos
- 1 docs/workflow update from real feedback

Use [WEEKLY_POST_PLANNER.md](WEEKLY_POST_PLANNER.md) to plan and score each week.
