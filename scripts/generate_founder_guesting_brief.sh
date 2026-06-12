#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder guesting sprint brief from guesting queue + fame + media artifacts.

Usage:
  zsh scripts/generate_founder_guesting_brief.sh [options]

Required:
  --guesting-queue <path>   Founder guesting queue markdown
  --fame-pack <path>        Founder fame pack markdown
  --media-blast <path>      Founder media blast markdown
  --out <path>              Output markdown path

Optional:
  --week <label>            Week label override (default: inferred from guesting queue)
  --product <text>          Product name (default: Fluid Reader)
  --primary-channel <text>  Primary distribution channel (default: X / Threads)
  --backup-channel <text>   Backup distribution channel (default: LinkedIn)
  --cta <text>              CTA line for outreach follow-ups
  -h, --help                Show help

Example:
  zsh scripts/generate_founder_guesting_brief.sh \
    --guesting-queue .build/founder/founder-guesting-queue-2026-W23.md \
    --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
    --media-blast .build/founder/founder-media-blast-2026-W23.md \
    --out .build/founder/founder-guesting-brief-2026-W23.md
EOF
}

guesting_queue_path=""
fame_pack_path=""
media_blast_path=""
output_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="If useful, I can share the exact command-level founder operating stack behind this week’s results."

while (( $# > 0 )); do
  case "$1" in
    --guesting-queue)
      guesting_queue_path="${2:-}"
      shift 2
      ;;
    --fame-pack)
      fame_pack_path="${2:-}"
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
  "guesting_queue_path:$guesting_queue_path" \
  "fame_pack_path:$fame_pack_path" \
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

for required_file in "$guesting_queue_path" "$fame_pack_path" "$media_blast_path"; do
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

format_number() {
  local value="$1"
  awk -v value="$value" 'BEGIN {
    rounded = int((value + 0) * 10 + 0.5) / 10
    if (rounded == int(rounded)) {
      printf "%d", int(rounded)
    } else {
      printf "%.1f", rounded
    }
  }'
}

guesting_heading="$(extract_heading_suffix "$guesting_queue_path" "Founder Guesting Queue")"
fame_heading="$(extract_heading_suffix "$fame_pack_path" "Founder Fame Pack")"
media_heading="$(extract_heading_suffix "$media_blast_path" "Founder Media Blast")"

if [[ -z "$week_label" ]]; then
  week_label="$guesting_heading"
fi
if [[ -z "$week_label" || "$week_label" == "n/a" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

readiness_score_line="$(extract_bullet_value "$guesting_queue_path" "Guesting readiness score")"
touch_goal_line="$(extract_bullet_value "$guesting_queue_path" "Weekly outreach touch goal")"
channel_route_line="$(extract_bullet_value "$guesting_queue_path" "Channel route")"
top_format_line="$(extract_bullet_value "$guesting_queue_path" "Guesting signal top format")"
top_target_line="$(extract_bullet_value "$guesting_queue_path" "Guesting signal top target")"
signal_recommendation_line="$(extract_bullet_value "$guesting_queue_path" "Guesting signal recommendation")"
narrative_anchor_line="$(extract_bullet_value "$guesting_queue_path" "Narrative anchor")"

momentum_line="$(extract_bullet_value "$fame_pack_path" "Momentum score")"
scoreboard_state_line="$(extract_bullet_value "$fame_pack_path" "Scoreboard state")"
weekly_summary_line="$(extract_bullet_value "$fame_pack_path" "Weekly summary")"
focus_line="$(extract_bullet_value "$fame_pack_path" "Current focus")"
mrr_line="$(extract_bullet_value "$fame_pack_path" "MRR")"
cac_line="$(extract_bullet_value "$fame_pack_path" "CAC")"
ltv_cac_line="$(extract_bullet_value "$fame_pack_path" "LTV/CAC")"

blast_narrative_line="$(extract_bullet_value "$media_blast_path" "Weekly narrative")"
priority_ask_line="$(extract_bullet_value "$media_blast_path" "Priority ask")"

pitch_queue_1="$(extract_numbered_line "$guesting_queue_path" "## Ranked Pitch Queue" 1)"
pitch_queue_2="$(extract_numbered_line "$guesting_queue_path" "## Ranked Pitch Queue" 2)"
pitch_queue_3="$(extract_numbered_line "$guesting_queue_path" "## Ranked Pitch Queue" 3)"

channel_sequence_1="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 1)"
channel_sequence_2="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 2)"
channel_sequence_3="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 3)"

readiness_score_number="$(parse_number "$readiness_score_line")"
touch_goal_number="$(parse_number "$touch_goal_line")"

if [[ -z "$weekly_summary_line" || "$weekly_summary_line" == "n/a" ]]; then
  weekly_summary_line="Weekly KPI summary unavailable; re-run founder fame pack."
fi
if [[ -z "$focus_line" || "$focus_line" == "n/a" ]]; then
  focus_line="Turn one KPI bottleneck into one public proof narrative each week."
fi
if [[ -z "$blast_narrative_line" || "$blast_narrative_line" == "n/a" ]]; then
  blast_narrative_line="$weekly_summary_line"
fi
if [[ -z "$narrative_anchor_line" || "$narrative_anchor_line" == "n/a" ]]; then
  narrative_anchor_line="$blast_narrative_line"
fi
if [[ -z "$top_format_line" || "$top_format_line" == "n/a" ]]; then
  top_format_line="podcast"
fi
if [[ -z "$top_target_line" || "$top_target_line" == "n/a" ]]; then
  top_target_line="top-priority founder guesting target"
fi
if [[ -z "$signal_recommendation_line" || "$signal_recommendation_line" == "n/a" ]]; then
  signal_recommendation_line="Capture at least 5 founder guesting signal entries before next Friday review."
fi
if [[ -z "$priority_ask_line" || "$priority_ask_line" == "n/a" ]]; then
  priority_ask_line="Book one founder interview + one newsletter feature this week."
fi
if [[ -z "$pitch_queue_1" ]]; then
  pitch_queue_1="Tier-1 operator podcast hosts with recurring founder operating-system episodes."
fi
if [[ -z "$pitch_queue_2" ]]; then
  pitch_queue_2="Newsletter editors who feature measurable startup experiments."
fi
if [[ -z "$pitch_queue_3" ]]; then
  pitch_queue_3="Community leaders running weekly async founder AMA threads."
fi
if [[ -z "$channel_sequence_1" ]]; then
  channel_sequence_1="Day 1 (${primary_channel}): publish KPI narrative + first proof point."
fi
if [[ -z "$channel_sequence_2" ]]; then
  channel_sequence_2="Day 2 (${primary_channel}): post objection-handling follow-up thread."
fi
if [[ -z "$channel_sequence_3" ]]; then
  channel_sequence_3="Day 3 (${backup_channel}): publish reformatted operator recap."
fi

if [[ "$readiness_score_number" == "n/a" ]]; then
  readiness_score_number=55
fi
if [[ "$touch_goal_number" == "n/a" ]]; then
  touch_goal_number=10
fi

booking_goal=1
if (( readiness_score_number >= 80 )); then
  booking_goal=3
elif (( readiness_score_number >= 60 )); then
  booking_goal=2
fi
if (( touch_goal_number >= 16 )); then
  booking_goal=$(( booking_goal + 1 ))
fi
if (( booking_goal > 4 )); then
  booking_goal=4
fi

lead_channel="$primary_channel"
support_channel="$backup_channel"
if [[ "${channel_route_line:l}" == *"backup-led"* ]]; then
  lead_channel="$backup_channel"
  support_channel="$primary_channel"
fi

reply_sla_hours=6
if (( readiness_score_number >= 70 )); then
  reply_sla_hours=4
fi

prep_window_minutes=35
if (( readiness_score_number >= 75 )); then
  prep_window_minutes=50
elif (( readiness_score_number >= 60 )); then
  prep_window_minutes=45
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Guesting Sprint Brief - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source guesting queue: ${guesting_heading}
Source fame pack: ${fame_heading}
Source media blast: ${media_heading}

## Fame-to-Guesting Snapshot

- Guesting readiness score: $(format_number "$readiness_score_number")/100
- Weekly touch goal: ${touch_goal_number}
- Booking goal this sprint: ${booking_goal}
- Lead channel: ${lead_channel}
- Support channel: ${support_channel}
- Priority format: ${top_format_line}
- Priority target: ${top_target_line}
- Momentum signal: ${momentum_line}
- Scoreboard state: ${scoreboard_state_line}
- Guesting recommendation: ${signal_recommendation_line}

## 72-Hour Booking Plan

1. Open with top target: ${pitch_queue_1}
2. Send secondary target outreach: ${pitch_queue_2}
3. Lock backup lane outreach: ${pitch_queue_3}
4. Apply channel sequence block 1: ${channel_sequence_1}
5. Apply channel sequence block 2: ${channel_sequence_2}
6. Apply channel sequence block 3: ${channel_sequence_3}

## Interview Narrative Spine

- Narrative anchor: ${narrative_anchor_line}
- Weekly summary: ${weekly_summary_line}
- Current focus: ${focus_line}
- KPI proof stack: MRR ${mrr_line}, CAC ${cac_line}, LTV/CAC ${ltv_cac_line}
- Blast narrative alignment: ${blast_narrative_line}
- Priority ask: ${priority_ask_line}

## Host Hook Pack

### Hook A (operator podcast)

\`\`\`text
I can share a concise founder operating breakdown for ${product_name}:
1) KPI scoreboard and weekly delta loop
2) Distribution + guesting execution cadence
3) What changed in one week and why

Would a ${prep_window_minutes}-minute founder segment fit your next recording window?
${cta_text}
\`\`\`

### Hook B (newsletter feature)

\`\`\`text
Working angle: ${top_format_line} + metrics-backed founder execution.

I can send a short write-up with:
- Weekly KPI movement (${mrr_line}, ${cac_line}, ${ltv_cac_line})
- Execution stack and distribution sequence
- Lessons from this week’s guesting sprint

If useful, I can send a 5-bullet draft by tomorrow.
\`\`\`

### Hook C (community / live format)

\`\`\`text
Running a founder guesting sprint this week and looking for one practical community slot.

Narrative: ${narrative_anchor_line}
Current priority: ${priority_ask_line}

Happy to tailor the format to your group and share a post-session recap.
${cta_text}
\`\`\`

## Follow-Up Ops

- Reply SLA: ${reply_sla_hours} hours for high-signal hosts/editors.
- Daily follow-up block: two windows per day on ${lead_channel} + ${support_channel}.
- Objection conversion rule: turn repeated objections into one explicit proof asset within 24 hours.
- Booking confirmation rule: convert warm replies into calendar holds in the same day.

## Tracking Checklist

- [ ] Sent at least ${touch_goal_number} guesting touches this week
- [ ] Booked at least ${booking_goal} interview/newsletter/community slots
- [ ] Logged status for each top-3 target in the queue
- [ ] Converted objections into one updated hook/script
- [ ] Published one end-of-week guesting lessons recap
EOF

echo "Wrote founder guesting sprint brief: $output_path"
