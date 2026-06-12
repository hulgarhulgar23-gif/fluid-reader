#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame repurpose plan from interview + media artifacts.

Usage:
  zsh scripts/generate_founder_fame_repurpose_plan.sh [options]

Required:
  --interview-prep <path>       Founder fame interview prep markdown
  --media-blast <path>          Founder media blast markdown

Optional:
  --week <label>                Week label (default: inferred from interview prep heading, then media blast heading, then current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --action-queue <path>         Founder fame action queue markdown
  --guesting-brief <path>       Founder guesting sprint brief markdown
  --transcript-ingestion <path> Founder fame transcript ingestion markdown
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-repurpose-plan.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_repurpose_plan.sh \
    --interview-prep docs/campaigns/2026-W23-founder-fame-interview-prep.md \
    --media-blast docs/campaigns/2026-W23-founder-media-blast.md \
    --action-queue docs/campaigns/2026-W23-founder-fame-action-queue.md \
    --out docs/campaigns/2026-W23-founder-fame-repurpose-plan.md
EOF
}

interview_prep_path=""
media_blast_path=""
action_queue_path=""
guesting_brief_path=""
transcript_ingestion_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --interview-prep)
      interview_prep_path="${2:-}"
      shift 2
      ;;
    --media-blast)
      media_blast_path="${2:-}"
      shift 2
      ;;
    --action-queue)
      action_queue_path="${2:-}"
      shift 2
      ;;
    --guesting-brief)
      guesting_brief_path="${2:-}"
      shift 2
      ;;
    --transcript-ingestion)
      transcript_ingestion_path="${2:-}"
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
    --out)
      output_path="${2:-}"
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
  "interview_prep_path:$interview_prep_path" \
  "media_blast_path:$media_blast_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

for required_file in "$interview_prep_path" "$media_blast_path"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

for optional_file in "$action_queue_path" "$guesting_brief_path" "$transcript_ingestion_path"; do
  if [[ -n "$optional_file" && ! -f "$optional_file" ]]; then
    echo "Optional source file not found: $optional_file" >&2
    exit 1
  fi
done

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

extract_heading() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi
  local heading
  heading="$(rg -m1 '^# ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo "n/a"
    return
  fi
  echo "${heading#\# }"
}

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi
  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  trim_value "${line#"$prefix"}"
}

extract_numbered_line() {
  local source_path="$1"
  local section_heading="$2"
  local index="$3"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

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
  ' "$source_path"
}

extract_action_line() {
  local source_path="$1"
  local index="$2"
  local value
  value="$(extract_numbered_line "$source_path" "## Top 3 Monday Actions" "$index")"
  value="${value#\[ \] }"
  trim_value "$value"
}

extract_week_from_interview_prep() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Interview Prep:' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Interview Prep:"}"
}

extract_week_from_media_blast() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Media Blast - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Media Blast - "}"
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_interview_prep "$interview_prep_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_media_blast "$media_blast_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-repurpose-plan.md"
fi

interview_heading="$(extract_heading "$interview_prep_path")"
media_heading="$(extract_heading "$media_blast_path")"
action_queue_heading="$(extract_heading "$action_queue_path")"
guesting_heading="$(extract_heading "$guesting_brief_path")"
transcript_ingestion_heading="$(extract_heading "$transcript_ingestion_path")"

metric_focus="$(extract_prefixed_value "$interview_prep_path" "- Metric focus: ")"
strongest_metric="$(extract_prefixed_value "$interview_prep_path" "- Strongest metric: ")"
lead_support_channels="$(extract_prefixed_value "$interview_prep_path" "- Lead / support channels: ")"
priority_format_target="$(extract_prefixed_value "$interview_prep_path" "- Priority format / target: ")"
reply_goal="$(extract_prefixed_value "$interview_prep_path" "- Reply goal (24h): ")"
outreach_goal="$(extract_prefixed_value "$interview_prep_path" "- Outreach goal (7d): ")"
mix_recommendation="$(extract_prefixed_value "$interview_prep_path" "- Mix recommendation: ")"

weekly_narrative="$(extract_prefixed_value "$media_blast_path" "- Weekly narrative: ")"
current_focus="$(extract_prefixed_value "$media_blast_path" "- Current focus: ")"
headline_a="$(extract_prefixed_value "$media_blast_path" "- Headline A: ")"
headline_b="$(extract_prefixed_value "$media_blast_path" "- Headline B: ")"
headline_c="$(extract_prefixed_value "$media_blast_path" "- Headline C: ")"
cta_script="$(extract_prefixed_value "$media_blast_path" "- CTA script: ")"
channel_sequence_1="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 1)"
channel_sequence_2="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 2)"
channel_sequence_3="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 3)"

priority_ask="$(extract_prefixed_value "$guesting_brief_path" "- Priority ask: ")"
guesting_priority_target="$(extract_prefixed_value "$guesting_brief_path" "- Priority target: ")"
transcript_quote_1="$(extract_numbered_line "$transcript_ingestion_path" "## Transcript Quote Bank" 1)"
transcript_quote_2="$(extract_numbered_line "$transcript_ingestion_path" "## Transcript Quote Bank" 2)"
transcript_objection_1="$(extract_numbered_line "$transcript_ingestion_path" "## Objection Radar" 1)"
transcript_clip_1="$(extract_numbered_line "$transcript_ingestion_path" "## Clip Candidate List" 1)"

action_1="$(extract_action_line "$action_queue_path" 1)"
action_2="$(extract_action_line "$action_queue_path" 2)"
action_3="$(extract_action_line "$action_queue_path" 3)"

if [[ "$metric_focus" == "n/a" ]]; then
  metric_focus="one KPI-backed founder proof narrative"
fi
if [[ "$strongest_metric" == "n/a" ]]; then
  strongest_metric="weekly strongest KPI signal"
fi
if [[ "$lead_support_channels" == "n/a" ]]; then
  lead_support_channels="primary channel / backup channel"
fi
if [[ "$priority_format_target" == "n/a" ]]; then
  priority_format_target="podcast / top-priority founder guesting target"
fi
if [[ "$reply_goal" == "n/a" ]]; then
  reply_goal="12 practical replies"
fi
if [[ "$outreach_goal" == "n/a" ]]; then
  outreach_goal="5 founder follow-ups"
fi
if [[ "$mix_recommendation" == "n/a" ]]; then
  mix_recommendation="Keep routing aligned to ROI and reply quality."
fi
if [[ "$weekly_narrative" == "n/a" ]]; then
  weekly_narrative="Balanced founder execution narrative with explicit proof."
fi
if [[ "$current_focus" == "n/a" ]]; then
  current_focus="Tighten weakest KPI before expanding channel spend."
fi
if [[ "$headline_a" == "n/a" ]]; then
  headline_a="Founder execution loop with measurable weekly proof."
fi
if [[ "$headline_b" == "n/a" ]]; then
  headline_b="One scoreboard, one narrative, one operator follow-up."
fi
if [[ "$headline_c" == "n/a" ]]; then
  headline_c="Local-first product and public founder proof cadence."
fi
if [[ "$cta_script" == "n/a" ]]; then
  cta_script="Reply with your KPI bottleneck and I’ll share the exact command stack."
fi
if [[ -z "$channel_sequence_1" ]]; then
  channel_sequence_1="Day 1: publish proof-first founder narrative."
fi
if [[ -z "$channel_sequence_2" ]]; then
  channel_sequence_2="Day 2: post objection-handling follow-up with KPI context."
fi
if [[ -z "$channel_sequence_3" ]]; then
  channel_sequence_3="Day 3: publish reformatted operator recap on backup channel."
fi
if [[ "$priority_ask" == "n/a" ]]; then
  priority_ask="Book one founder interview + one newsletter feature this week."
fi
if [[ "$guesting_priority_target" == "n/a" ]]; then
  guesting_priority_target="top-priority founder guesting target"
fi
if [[ -z "$action_1" ]]; then
  action_1="Publish proof-first message in lead channel."
fi
if [[ -z "$action_2" ]]; then
  action_2="Ship support-channel follow-up with one concrete CTA."
fi
if [[ -z "$action_3" ]]; then
  action_3="Handle practical replies and log repeated objections."
fi
if [[ -z "$transcript_quote_1" ]]; then
  transcript_quote_1="We tightened one bottleneck first, then scaled what proved repeatable."
fi
if [[ -z "$transcript_quote_2" ]]; then
  transcript_quote_2="Weekly scoreboards keep us honest on which channels deserve more effort."
fi
if [[ -z "$transcript_objection_1" ]]; then
  transcript_objection_1="How do you prove this is more than anecdotal founder momentum?"
fi
if [[ -z "$transcript_clip_1" ]]; then
  transcript_clip_1="00:10-00:40 | We tightened one bottleneck first, then scaled what proved repeatable."
fi

lead_channel="${lead_support_channels%%/*}"
support_channel="${lead_support_channels#*/}"
lead_channel="$(trim_value "$lead_channel")"
support_channel="$(trim_value "$support_channel")"
if [[ -z "$lead_channel" || "$lead_channel" == "$lead_support_channels" ]]; then
  lead_channel="primary channel"
fi
if [[ -z "$support_channel" || "$support_channel" == "$lead_support_channels" ]]; then
  support_channel="backup channel"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-repurpose-plan -->

# Founder Fame Repurpose Plan - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source interview prep: ${interview_prep_path}
Source media blast: ${media_blast_path}
Source action queue: ${action_queue_path:-n/a}
Source guesting brief: ${guesting_brief_path:-n/a}
Source transcript ingestion: ${transcript_ingestion_path:-n/a}

## Snapshot

- Interview prep: ${interview_heading}
- Media blast: ${media_heading}
- Action queue: ${action_queue_heading}
- Guesting brief: ${guesting_heading}
- Transcript ingestion: ${transcript_ingestion_heading}
- Metric focus: ${metric_focus}
- Strongest metric: ${strongest_metric}
- Lead / support channels: ${lead_channel} / ${support_channel}
- Priority format / target: ${priority_format_target}
- Weekly narrative: ${weekly_narrative}
- Current focus: ${current_focus}
- Reply goal (24h): ${reply_goal}
- Outreach goal (7d): ${outreach_goal}

## Repurpose Targets

1. **Founder clip (30 to 60s):** Use headline angle "${headline_a}", anchor with "${transcript_quote_1}", and end with "${cta_script}".
2. **Proof thread:** Lead with "${headline_b}", answer "${transcript_objection_1}", and turn action queue into a 3-post sequence.
3. **Operator recap post:** Reformat "${headline_c}" for ${support_channel} and include one concrete KPI proof.
4. **Newsletter excerpt:** Convert interview highlights into a short “what changed this week” note.

## Asset Matrix

| Asset | Source anchor | Hook | CTA | Execution window (UTC) |
| --- | --- | --- | --- | --- |
| Clip A | Interview prep opener + media headline A | ${headline_a} | ${cta_script} | Day 1 09:00-11:00 |
| Thread A | Action queue top actions | ${headline_b} | Ask for one practical reply | Day 1 12:00-14:00 |
| Recap post | Channel sequence + weekly narrative | ${headline_c} | Invite one follow-up question | Day 2 09:00-11:00 |
| Newsletter snippet | Priority ask + strongest metric | ${strongest_metric} | ${priority_ask} | Day 2 12:00-15:00 |

## Transcript Signals

- Quote anchor A: ${transcript_quote_1}
- Quote anchor B: ${transcript_quote_2}
- Objection to handle first: ${transcript_objection_1}
- First clip candidate: ${transcript_clip_1}

## 7-Day Repurpose Sprint

1. Day 0: Lock anchor narrative + strongest metric proof.
2. Day 1: Publish clip + proof thread using action sequence (${action_1} -> ${action_2} -> ${action_3}).
3. Day 2: Publish recap post + newsletter pitch variant.
4. Day 3: Recut top-performing segment and ship second clip.
5. Day 4: Turn best objection into FAQ/docs clarity.
6. Day 5: Run collaboration follow-up with ${guesting_priority_target}.
7. Day 7: Publish weekly repurpose recap and set next-week default formats.

## Copy Starters

### Thread opener

\`\`\`text
This week in ${product_name}: ${weekly_narrative}
Strongest proof: ${strongest_metric}
Execution focus: ${current_focus}
Next 3 actions:
1) ${action_1}
2) ${action_2}
3) ${action_3}
\`\`\`

### Clip caption

\`\`\`text
Founder repurpose sprint (${week_label})
Lead channel: ${lead_channel}
Support channel: ${support_channel}
Mix call: ${mix_recommendation}
Ask: ${priority_ask}
\`\`\`

### Newsletter lead

\`\`\`text
This week’s founder operating note:
- Focus: ${metric_focus}
- Proof: ${strongest_metric}
- Narrative: ${weekly_narrative}
- What we’ll repurpose next: clip + thread + recap sequence.
\`\`\`

## Tracking Checklist

- [ ] Published one founder clip with concrete KPI proof.
- [ ] Published one proof thread with 3 actionable points.
- [ ] Published one recap post on support channel.
- [ ] Logged top objections from repurpose content replies.
- [ ] Converted one objection into docs/product clarity.
- [ ] Sent one follow-up to ${guesting_priority_target}.

## Share Block

\`\`\`text
Founder repurpose plan (${week_label})
Focus: ${metric_focus}
Proof: ${strongest_metric}
Lead/support: ${lead_channel}/${support_channel}
Top actions:
1) ${action_1}
2) ${action_2}
3) ${action_3}
\`\`\`
EOF

echo "Wrote founder fame repurpose plan: $output_path"
