# Creator Target List

Use this artifact to prioritize creator outreach every week from ROI and outreach effectiveness signals.

## Generate Target List

```sh
zsh scripts/generate_creator_target_list.sh \
  --week 2026-W23 \
  --metric-focus "Win Card copies and installs" \
  --command "Copy Win Card" \
  --primary-channel "X / Threads" \
  --backup-channel "LinkedIn" \
  --primary-channel-roi-score "78" \
  --backup-channel-roi-score "71" \
  --channel-roi-preferred-channel "primary" \
  --channel-mix-recommendation "Maintain a primary-led 60/40 mix this week." \
  --outreach-sent "8" \
  --outreach-replies "3" \
  --outreach-collabs "1" \
  --outreach-cross-posts "1" \
  --outreach-reply-rate "37.5%" \
  --outreach-collab-rate "12.5%" \
  --outreach-cross-post-rate "12.5%" \
  --outreach-replies-delta "+1" \
  --outreach-collabs-delta "+1" \
  --creator-signal-entries "7" \
  --creator-signal-high-fit "4" \
  --creator-signal-warm-intros "2" \
  --creator-signal-collab-ready "2" \
  --creator-signal-top-segment "Workflow/tutorial creators" \
  --creator-signal-top-handle "@buildwithamy" \
  --creator-signal-enrichment-score "74" \
  --creator-signal-recommendation "Prioritize high-fit workflow creators first and personalize first-touch proof." \
  --out .build/growth/2026-W23-creator-target-list.md
```

The generated markdown includes:

- Prioritization snapshot with KPI + ROI context
- Creator signal enrichment overlay from checklist comments
- Ranked creator target queue with segment-level priority scores
- 7-day contact sprint plan
- Three DM variants (proof/workflow/distribution)
- Tracking checklist for weekly iteration

## Creator Signal Comment Format

Add/update one comment in `Monday Publish Checklist <week>` using this marker format.
Friday review parses these comments and routes enrichment into target scores.

```text
<!-- weekly-growth-creator-signal -->
- Handle: @creator_handle
- Segment: Workflow/tutorial creators
- Channel: primary
- Fit score: 78
- Warm intro: yes
- Status: replied
```

## Weekly Flow

1. Generate social proof + creator outreach artifacts.
2. Generate creator target list from latest effectiveness metrics.
3. Send top-ranked outreach in the first 24 hours.
4. Update Monday checklist with replies/collaborations/cross-posts.
5. Add creator signal comment entries for top handles you touched.
6. Re-rank next Friday using latest deltas.

## Related Guides

- [CREATOR_OUTREACH_KIT.md](CREATOR_OUTREACH_KIT.md)
- [DISTRIBUTION_PLAYBOOK.md](DISTRIBUTION_PLAYBOOK.md)
- [WEEKLY_GROWTH_AUTOPILOT.md](WEEKLY_GROWTH_AUTOPILOT.md)
