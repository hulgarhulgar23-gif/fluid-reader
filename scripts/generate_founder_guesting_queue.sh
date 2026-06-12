#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder guesting queue from fame pack + press kit + media blast artifacts.

Usage:
  zsh scripts/generate_founder_guesting_queue.sh [options]

Required:
  --fame-pack <path>       Founder fame pack markdown
  --press-kit <path>       Founder press kit markdown
  --media-blast <path>     Founder media blast markdown
  --out <path>             Output markdown path

Optional:
  --week <label>           Week label override (default: inferred from fame pack)
  --product <text>         Product name (default: Fluid Reader)
  --primary-channel <text> Primary channel label (default: X / Threads)
  --backup-channel <text>  Backup channel label (default: LinkedIn)
  --guesting-signal-entries <value>      Guesting signal entries captured from checklist comments
  --guesting-signal-replied <value>      Guesting signal entries with replied/booked/published stage
  --guesting-signal-booked <value>       Guesting signal entries with booked/published stage
  --guesting-signal-published <value>    Guesting signal entries with published stage
  --guesting-signal-top-format <text>    Top-performing guesting format from signals
  --guesting-signal-top-target <text>    Highest-priority guesting target from signals
  --guesting-signal-enrichment-score <value> Guesting enrichment score (0-100)
  --guesting-signal-recommendation <text> Recommendation line from guesting signal scoring
  --outreach-sprint-completion-rate <value> Outreach sprint completion rate from Monday checklist comments
  --outreach-sprint-tasks-completed <value> Completed outreach sprint checklist tasks
  --outreach-sprint-tasks-total <value> Total outreach sprint checklist tasks
  --outreach-sprint-creator-tasks-completed <value> Completed creator-focused outreach sprint tasks
  --outreach-sprint-guesting-tasks-completed <value> Completed guesting-focused outreach sprint tasks
  --outreach-sprint-recommendation <text> Recommendation derived from outreach sprint outcomes
  --cta <text>             CTA line for pitch snippets
  -h, --help               Show help

Example:
  zsh scripts/generate_founder_guesting_queue.sh \
    --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
    --press-kit .build/founder/founder-press-kit-2026-W23.md \
    --media-blast .build/founder/founder-media-blast-2026-W23.md \
    --out .build/founder/founder-guesting-queue-2026-W23.md
EOF
}

fame_pack_path=""
press_kit_path=""
media_blast_path=""
output_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
guesting_signal_entries="n/a"
guesting_signal_replied="n/a"
guesting_signal_booked="n/a"
guesting_signal_published="n/a"
guesting_signal_top_format="n/a"
guesting_signal_top_target="n/a"
guesting_signal_enrichment_score="n/a"
guesting_signal_recommendation="Capture founder guesting signal comments before Friday review."
outreach_sprint_completion_rate="n/a"
outreach_sprint_tasks_completed="n/a"
outreach_sprint_tasks_total="n/a"
outreach_sprint_creator_tasks_completed="n/a"
outreach_sprint_guesting_tasks_completed="n/a"
outreach_sprint_recommendation="Capture founder outreach sprint checklist updates in Monday checklist comments before Friday review."
cta_text="If useful, I can share the exact weekly KPI + distribution command stack we run."

while (( $# > 0 )); do
  case "$1" in
    --fame-pack)
      fame_pack_path="${2:-}"
      shift 2
      ;;
    --press-kit)
      press_kit_path="${2:-}"
      shift 2
      ;;
    --media-blast)
      media_blast_path="${2:-}"
      shift 2
      ;;
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --product)
      product_name="${2:-}"
      shift 2
      ;;
    --primary-channel)
      primary_channel="${2:-}"
      shift 2
      ;;
    --backup-channel)
      backup_channel="${2:-}"
      shift 2
      ;;
    --guesting-signal-entries)
      guesting_signal_entries="${2:-}"
      shift 2
      ;;
    --guesting-signal-replied)
      guesting_signal_replied="${2:-}"
      shift 2
      ;;
    --guesting-signal-booked)
      guesting_signal_booked="${2:-}"
      shift 2
      ;;
    --guesting-signal-published)
      guesting_signal_published="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-format)
      guesting_signal_top_format="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-target)
      guesting_signal_top_target="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score)
      guesting_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --guesting-signal-recommendation)
      guesting_signal_recommendation="${2:-}"
      shift 2
      ;;
    --outreach-sprint-completion-rate)
      outreach_sprint_completion_rate="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-completed)
      outreach_sprint_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-tasks-total)
      outreach_sprint_tasks_total="${2:-}"
      shift 2
      ;;
    --outreach-sprint-creator-tasks-completed)
      outreach_sprint_creator_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-guesting-tasks-completed)
      outreach_sprint_guesting_tasks_completed="${2:-}"
      shift 2
      ;;
    --outreach-sprint-recommendation)
      outreach_sprint_recommendation="${2:-}"
      shift 2
      ;;
    --cta)
      cta_text="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for pair in \
  "fame_pack_path:$fame_pack_path" \
  "press_kit_path:$press_kit_path" \
  "media_blast_path:$media_blast_path" \
  "output_path:$output_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

for required_file in "$fame_pack_path" "$press_kit_path" "$media_blast_path"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

trim() {
  echo "$1" | sed -E 's/^ +| +$//g'
}

extract_heading_suffix() {
  local file="$1"
  local prefix="$2"
  local heading
  heading="$(sed -n "s/^# ${prefix} - //p" "$file" | head -n 1)"
  if [[ -z "$heading" ]]; then
    echo "n/a"
  else
    echo "$heading"
  fi
}

extract_bullet_value() {
  local file="$1"
  local key="$2"
  local line
  line="$(grep -E "^- ${key}:" "$file" | head -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  local prefix="- ${key}:"
  trim "${line#${prefix}}"
}

extract_numbered_line() {
  local file="$1"
  local section_heading="$2"
  local index="$3"
  awk -v heading="$section_heading" -v target="$index" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^[0-9]+\./ {
      count++
      if (count == target) {
        sub(/^[0-9]+\.[[:space:]]*/, "", $0)
        print $0
        exit
      }
    }
  ' "$file"
}

parse_number() {
  local value="$1"
  local parsed
  parsed="$(echo "$value" | sed -nE 's/.*([+-]?[0-9]+([.][0-9]+)?).*/\1/p' | head -n 1)"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
  else
    echo "$parsed"
  fi
}

clamp_score() {
  local score="$1"
  if (( score < 0 )); then
    echo 0
    return
  fi
  if (( score > 100 )); then
    echo 100
    return
  fi
  echo "$score"
}

fame_heading="$(extract_heading_suffix "$fame_pack_path" "Founder Fame Pack")"
press_heading="$(extract_heading_suffix "$press_kit_path" "Founder Press Kit")"
media_heading="$(extract_heading_suffix "$media_blast_path" "Founder Media Blast")"

if [[ -z "$week_label" ]]; then
  week_label="$fame_heading"
fi
if [[ -z "$week_label" || "$week_label" == "n/a" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

momentum_signal="$(extract_bullet_value "$fame_pack_path" "Momentum score")"
scoreboard_state="$(extract_bullet_value "$fame_pack_path" "Scoreboard state")"
current_focus="$(extract_bullet_value "$fame_pack_path" "Current focus")"
weekly_summary="$(extract_bullet_value "$fame_pack_path" "Weekly summary")"
mrr_line="$(extract_bullet_value "$fame_pack_path" "MRR")"
cac_line="$(extract_bullet_value "$fame_pack_path" "CAC")"
ltv_cac_line="$(extract_bullet_value "$fame_pack_path" "LTV/CAC")"
blast_narrative="$(extract_bullet_value "$media_blast_path" "Weekly narrative")"

headline_1="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 1)"
headline_2="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 2)"
headline_3="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 3)"

if [[ -z "$current_focus" || "$current_focus" == "n/a" ]]; then
  current_focus="Turn one KPI bottleneck into one public proof narrative each week."
fi
if [[ -z "$weekly_summary" || "$weekly_summary" == "n/a" ]]; then
  weekly_summary="Weekly summary unavailable; re-run founder fame pack generation."
fi
if [[ -z "$blast_narrative" || "$blast_narrative" == "n/a" ]]; then
  blast_narrative="$weekly_summary"
fi
if [[ -z "$mrr_line" || "$mrr_line" == "n/a" ]]; then
  mrr_line="n/a"
fi
if [[ -z "$cac_line" || "$cac_line" == "n/a" ]]; then
  cac_line="n/a"
fi
if [[ -z "$ltv_cac_line" || "$ltv_cac_line" == "n/a" ]]; then
  ltv_cac_line="n/a"
fi
if [[ -z "$headline_1" ]]; then
  headline_1="Founder KPI loop translates weekly execution into public proof."
fi
if [[ -z "$headline_2" ]]; then
  headline_2="Small-team operating cadence compounds reach without bloating process."
fi
if [[ -z "$headline_3" ]]; then
  headline_3="One weekly narrative, one KPI bottleneck, one measurable experiment."
fi

momentum_number="$(parse_number "$momentum_signal")"
if [[ "$momentum_number" == "n/a" ]]; then
  momentum_number=55
fi

guesting_signal_entries_number="$(parse_number "$guesting_signal_entries")"
guesting_signal_replied_number="$(parse_number "$guesting_signal_replied")"
guesting_signal_booked_number="$(parse_number "$guesting_signal_booked")"
guesting_signal_published_number="$(parse_number "$guesting_signal_published")"
guesting_signal_enrichment_score_number="$(parse_number "$guesting_signal_enrichment_score")"
outreach_sprint_completion_rate_number="$(parse_number "$outreach_sprint_completion_rate")"
outreach_sprint_tasks_completed_number="$(parse_number "$outreach_sprint_tasks_completed")"
outreach_sprint_tasks_total_number="$(parse_number "$outreach_sprint_tasks_total")"
outreach_sprint_creator_tasks_completed_number="$(parse_number "$outreach_sprint_creator_tasks_completed")"
outreach_sprint_guesting_tasks_completed_number="$(parse_number "$outreach_sprint_guesting_tasks_completed")"

if [[ "$guesting_signal_entries_number" == "n/a" ]]; then
  guesting_signal_entries_number=0
fi
if [[ "$guesting_signal_replied_number" == "n/a" ]]; then
  guesting_signal_replied_number=0
fi
if [[ "$guesting_signal_booked_number" == "n/a" ]]; then
  guesting_signal_booked_number=0
fi
if [[ "$guesting_signal_published_number" == "n/a" ]]; then
  guesting_signal_published_number=0
fi
if [[ "$guesting_signal_enrichment_score_number" == "n/a" ]]; then
  guesting_signal_enrichment_score_number=0
fi
if [[ "$outreach_sprint_completion_rate_number" == "n/a" ]]; then
  outreach_sprint_completion_rate_number=0
fi
if [[ "$outreach_sprint_tasks_completed_number" == "n/a" ]]; then
  outreach_sprint_tasks_completed_number=0
fi
if [[ "$outreach_sprint_tasks_total_number" == "n/a" ]]; then
  outreach_sprint_tasks_total_number=0
fi
if [[ "$outreach_sprint_creator_tasks_completed_number" == "n/a" ]]; then
  outreach_sprint_creator_tasks_completed_number=0
fi
if [[ "$outreach_sprint_guesting_tasks_completed_number" == "n/a" ]]; then
  outreach_sprint_guesting_tasks_completed_number=0
fi

off_track_number_raw="$(echo "$scoreboard_state" | sed -nE 's/.*\/[[:space:]]*([0-9]+)[[:space:]]*off track.*/\1/p' | head -n 1)"
if [[ -z "$off_track_number_raw" ]]; then
  off_track_number_raw=0
fi

readiness_score_raw="$(awk -v momentum="$momentum_number" -v off_track="$off_track_number_raw" 'BEGIN {
  value = momentum - (off_track * 7) + 10;
  printf "%.0f", value;
}')"
readiness_score_raw="$(awk -v base="$readiness_score_raw" -v enrich="$guesting_signal_enrichment_score_number" -v booked="$guesting_signal_booked_number" -v published="$guesting_signal_published_number" -v sprint_completion="$outreach_sprint_completion_rate_number" -v sprint_guesting="$outreach_sprint_guesting_tasks_completed_number" 'BEGIN {
  value = base + (enrich * 0.20) + (booked * 4) + (published * 6) + (sprint_completion * 0.12) + (sprint_guesting * 2);
  printf "%.0f", value;
}')"
guesting_readiness_score="$(clamp_score "$readiness_score_raw")"

weekly_touch_goal=8
if (( guesting_readiness_score >= 80 )); then
  weekly_touch_goal=18
elif (( guesting_readiness_score >= 60 )); then
  weekly_touch_goal=12
fi

if (( guesting_signal_entries_number >= 8 )); then
  weekly_touch_goal=$(( weekly_touch_goal + 4 ))
elif (( guesting_signal_entries_number >= 4 )); then
  weekly_touch_goal=$(( weekly_touch_goal + 2 ))
fi

if (( outreach_sprint_guesting_tasks_completed_number >= 3 )); then
  weekly_touch_goal=$(( weekly_touch_goal + 3 ))
elif (( outreach_sprint_guesting_tasks_completed_number >= 1 )); then
  weekly_touch_goal=$(( weekly_touch_goal + 1 ))
fi

if (( outreach_sprint_completion_rate_number >= 80 )); then
  weekly_touch_goal=$(( weekly_touch_goal + 2 ))
fi

if (( weekly_touch_goal > 24 )); then
  weekly_touch_goal=24
fi

launch_route="balanced"
if (( guesting_readiness_score >= 70 )); then
  launch_route="primary-led"
elif (( guesting_readiness_score <= 45 )); then
  launch_route="backup-led"
fi

if (( outreach_sprint_guesting_tasks_completed_number > outreach_sprint_creator_tasks_completed_number )) && (( outreach_sprint_completion_rate_number >= 70 )); then
  launch_route="primary-led"
elif (( outreach_sprint_creator_tasks_completed_number > outreach_sprint_guesting_tasks_completed_number )) && (( outreach_sprint_completion_rate_number >= 70 )); then
  launch_route="backup-led"
fi

tier_one_channel="$primary_channel"
tier_two_channel="$backup_channel"
if [[ "$launch_route" == "backup-led" ]]; then
  tier_one_channel="$backup_channel"
  tier_two_channel="$primary_channel"
fi

if [[ "$guesting_signal_top_format" == "n/a" || -z "$guesting_signal_top_format" ]]; then
  guesting_signal_top_format="podcast"
fi

if [[ "$guesting_signal_top_target" == "n/a" || -z "$guesting_signal_top_target" ]]; then
  guesting_signal_top_target="top-priority founder guesting target"
fi

if [[ "$guesting_signal_recommendation" == "n/a" || -z "$guesting_signal_recommendation" ]]; then
  guesting_signal_recommendation="Capture at least 5 founder guesting signal comments before next Friday review."
fi
if [[ "$outreach_sprint_recommendation" == "n/a" || -z "$outreach_sprint_recommendation" ]]; then
  outreach_sprint_recommendation="Capture founder outreach sprint checklist updates in Monday checklist comments before Friday review."
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Guesting Queue - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source fame pack: ${fame_heading}
Source press kit: ${press_heading}
Source media blast: ${media_heading}

## Guesting Objective

- Guesting readiness score: ${guesting_readiness_score}/100
- Momentum signal: ${momentum_signal}
- Scoreboard state: ${scoreboard_state}
- Narrative anchor: ${blast_narrative}
- Weekly outreach touch goal: ${weekly_touch_goal}
- Channel route: ${launch_route}
- Guesting signal entries: ${guesting_signal_entries}
- Guesting replied/booked/published: ${guesting_signal_replied}/${guesting_signal_booked}/${guesting_signal_published}
- Guesting signal top format: ${guesting_signal_top_format}
- Guesting signal top target: ${guesting_signal_top_target}
- Guesting signal enrichment score: ${guesting_signal_enrichment_score}
- Guesting signal recommendation: ${guesting_signal_recommendation}
- Outreach sprint completion rate: ${outreach_sprint_completion_rate}
- Outreach sprint checklist: ${outreach_sprint_tasks_completed}/${outreach_sprint_tasks_total}
- Outreach sprint creator/guesting completed: ${outreach_sprint_creator_tasks_completed}/${outreach_sprint_guesting_tasks_completed}
- Outreach sprint recommendation: ${outreach_sprint_recommendation}

## Guesting Signal Overlay

- Lead guesting format this week: ${guesting_signal_top_format}
- Priority guesting target: ${guesting_signal_top_target}
- Recommendation: ${guesting_signal_recommendation}
- Outreach sprint feedback: ${outreach_sprint_recommendation}

## Prioritized Show Segments

| Rank | Segment | Why now | Primary ask | Lead channel |
| --- | --- | --- | --- | --- |
| 1 | Operator podcasts (${guesting_signal_top_format}) | Fastest route to founder credibility + long-form proof | 20-minute founder operating story segment | ${tier_one_channel} |
| 2 | Builder newsletters | High-trust distribution for practical workflows | Include KPI narrative + one actionable breakdown | ${tier_one_channel} |
| 3 | GTM / growth communities | Converts replies into collaboration loops | Moderator-approved deep-dive thread | ${tier_two_channel} |
| 4 | Product/design shows | Cross-functional relevance of execution loop | Case-study interview with proof stack | ${tier_two_channel} |
| 5 | Creator cross-post partners | Compounds reach in one week sprint | Co-post one distilled script + screenshot | ${tier_one_channel} |

## Ranked Pitch Queue

1. Tier-1 operator podcast hosts with recurring founder operating-system episodes (start with ${guesting_signal_top_target}).
2. Newsletter editors who feature measurable startup experiments.
3. Community leaders running weekly async AMA threads.
4. Creator-led interview formats open to execution teardown clips.
5. Regional product meetups that accept virtual founder lightning talks.
6. Tactical productivity channels that highlight command-level workflows.
7. Investor-facing newsletters open to KPI transparency narratives.
8. Engineering leadership communities discussing product operating cadence.
9. Technical podcast hosts looking for repeatable growth playbooks.
10. Cross-post partners aligned with ${headline_1}

## Outreach Scripts

### Script A (podcast / interview)

\`\`\`text
Founder story pitch for ${week_label}:
- Narrative: ${weekly_summary}
- KPI proof: MRR ${mrr_line}, CAC ${cac_line}, LTV/CAC ${ltv_cac_line}
- Focus: ${current_focus}

Would you be open to a 20-minute segment on the weekly execution loop behind this?
${cta_text}
\`\`\`

### Script B (newsletter / written feature)

\`\`\`text
Working angle: ${headline_2}

I can share a concise founder teardown for ${product_name}:
1) Weekly KPI review
2) Delta + scoreboard
3) Fame + media distribution loop

If useful, I can send a 5-bullet draft with proof points and exact commands.
\`\`\`

### Script C (community / cross-post)

\`\`\`text
Running a weekly founder distribution sprint and looking for one practical cross-post slot.

This week’s narrative: ${headline_3}
Current focus: ${current_focus}

Happy to tailor the post to your format and share a postmortem after launch.
${cta_text}
\`\`\`

## 7-Day Booking Sprint

1. Day 0: Send top 5 pitches (2 podcasts, 2 newsletters, 1 community lead).
2. Day 1: Follow up on non-responders with one proof artifact.
3. Day 2: Send wave-2 pitches to ranks 6-10.
4. Day 3: Book first interview slot and prep talking points.
5. Day 4: Convert strongest response into co-post commitment.
6. Day 5: Publish one guest-ready founder breakdown draft.
7. Day 7: Log outcomes and refresh queue for next week.

## Tracking Checklist

- [ ] Sent at least ${weekly_touch_goal} guesting touches this week
- [ ] Logged response status for each ranked pitch target
- [ ] Booked at least 1 interview/newsletter/community slot
- [ ] Captured objections and folded them into next pitch draft
- [ ] Promoted best-performing outreach script into next-week default
- [ ] Updated founder outreach sprint checklist comment with guesting outcomes
EOF

echo "Wrote founder guesting queue: $output_path"
