#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame interview prep brief from ops/action artifacts.

Usage:
  zsh scripts/generate_founder_fame_interview_prep.sh [options]

Required:
  Provide one of:
    --ops-brief <path> + --action-queue <path>
    --guesting-brief <path>

Optional:
  --week <label>                Week label (default: inferred from action queue heading, then current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --press-kit <path>            Founder press kit markdown
  --media-blast <path>          Founder media blast markdown
  --guesting-brief <path>       Founder guesting sprint brief markdown
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-interview-prep.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_interview_prep.sh \
    --ops-brief docs/campaigns/2026-W23-founder-fame-ops-brief.md \
    --action-queue docs/campaigns/2026-W23-founder-fame-action-queue.md \
    --press-kit docs/campaigns/2026-W23-founder-press-kit.md \
    --media-blast docs/campaigns/2026-W23-founder-media-blast.md \
    --out docs/campaigns/2026-W23-founder-fame-interview-prep.md
EOF
}

ops_brief_path=""
action_queue_path=""
week_label=""
product_name="Fluid Reader"
press_kit_path=""
media_blast_path=""
guesting_brief_path=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --ops-brief)
      ops_brief_path="${2:-}"
      shift 2
      ;;
    --action-queue)
      action_queue_path="${2:-}"
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
    --press-kit)
      press_kit_path="${2:-}"
      shift 2
      ;;
    --media-blast)
      media_blast_path="${2:-}"
      shift 2
      ;;
    --guesting-brief)
      guesting_brief_path="${2:-}"
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

if [[ -z "$ops_brief_path" && -z "$guesting_brief_path" ]]; then
  echo "Missing required source path: provide --guesting-brief, or --ops-brief with --action-queue." >&2
  usage >&2
  exit 1
fi

if [[ -n "$ops_brief_path" && -z "$action_queue_path" ]]; then
  echo "Missing required option with --ops-brief: --action-queue" >&2
  usage >&2
  exit 1
fi

if [[ -z "$action_queue_path" && -z "$guesting_brief_path" ]]; then
  echo "Missing source path for ranked actions: provide --action-queue or --guesting-brief." >&2
  usage >&2
  exit 1
fi

for required_file in "$ops_brief_path" "$action_queue_path" "$guesting_brief_path"; do
  if [[ -n "$required_file" && ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

for optional_file in "$press_kit_path" "$media_blast_path" "$guesting_brief_path"; do
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

source_label() {
  local source_path="$1"
  if [[ -z "$source_path" ]]; then
    echo "n/a"
    return
  fi
  echo "$source_path"
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

extract_week_from_action_queue() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Action Queue:' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Action Queue:"}"
}

extract_week_from_guesting_brief() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Guesting Sprint Brief - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Guesting Sprint Brief - "}"
}

if [[ -z "$week_label" ]]; then
  if [[ -n "$action_queue_path" ]]; then
    week_label="$(extract_week_from_action_queue "$action_queue_path")"
  fi
fi
if [[ -z "$week_label" && -n "$guesting_brief_path" ]]; then
  week_label="$(extract_week_from_guesting_brief "$guesting_brief_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-interview-prep.md"
fi

ops_heading="$(extract_heading "$ops_brief_path")"
action_queue_heading="$(extract_heading "$action_queue_path")"
press_heading="$(extract_heading "$press_kit_path")"
media_heading="$(extract_heading "$media_blast_path")"
guesting_heading="$(extract_heading "$guesting_brief_path")"

metric_focus="$(extract_prefixed_value "$ops_brief_path" "- Metric focus: ")"
strongest_metric="$(extract_prefixed_value "$ops_brief_path" "- Strongest metric: ")"
lead_channel="$(extract_prefixed_value "$ops_brief_path" "- Lead channel: ")"
support_channel="$(extract_prefixed_value "$ops_brief_path" "- Support channel: ")"
scoreboard_state="$(extract_prefixed_value "$ops_brief_path" "- Scoreboard state: ")"
weekly_summary="$(extract_prefixed_value "$ops_brief_path" "- Weekly summary: ")"
weekly_narrative="$(extract_prefixed_value "$ops_brief_path" "- Weekly narrative: ")"
reply_goal="$(extract_prefixed_value "$ops_brief_path" "- Reply goal (24h): ")"
outreach_goal="$(extract_prefixed_value "$ops_brief_path" "- Outreach goal (7d): ")"
priority_target="$(extract_prefixed_value "$ops_brief_path" "- Priority guesting target: ")"
if [[ "$priority_target" == "n/a" ]]; then
  priority_target="$(extract_prefixed_value "$ops_brief_path" "- Top guesting target: ")"
fi

priority_format="$(extract_prefixed_value "$guesting_brief_path" "- Priority format: ")"
if [[ "$priority_target" == "n/a" ]]; then
  priority_target="$(extract_prefixed_value "$guesting_brief_path" "- Priority target: ")"
fi
guesting_recommendation="$(extract_prefixed_value "$guesting_brief_path" "- Guesting recommendation: ")"
mix_recommendation="$(extract_prefixed_value "$action_queue_path" "- Mix recommendation: ")"
if [[ "$mix_recommendation" == "n/a" ]]; then
  mix_recommendation="$(extract_prefixed_value "$ops_brief_path" "- Mix recommendation: ")"
fi

headline_1="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 1)"
headline_2="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 2)"
talking_point_1="$(extract_numbered_line "$press_kit_path" "## Interview Talking Points" 1)"
talking_point_2="$(extract_numbered_line "$press_kit_path" "## Interview Talking Points" 2)"
channel_sequence_1="$(extract_numbered_line "$media_blast_path" "## Channel Sequence" 1)"

action_1="$(extract_action_line "$action_queue_path" 1)"
action_2="$(extract_action_line "$action_queue_path" 2)"
action_3="$(extract_action_line "$action_queue_path" 3)"

if [[ "$metric_focus" == "n/a" ]]; then
  metric_focus="one concrete KPI bottleneck with public proof"
fi
if [[ "$strongest_metric" == "n/a" ]]; then
  strongest_metric="latest weekly KPI proof signal"
fi
if [[ "$lead_channel" == "n/a" ]]; then
  lead_channel="primary launch channel"
fi
if [[ "$support_channel" == "n/a" ]]; then
  support_channel="backup launch channel"
fi
if [[ "$scoreboard_state" == "n/a" ]]; then
  scoreboard_state="review latest founder scoreboard state"
fi
if [[ "$weekly_summary" == "n/a" ]]; then
  weekly_summary="Weekly summary unavailable. Re-run founder fame artifacts before external interviews."
fi
if [[ "$weekly_narrative" == "n/a" ]]; then
  weekly_narrative="$weekly_summary"
fi
if [[ "$reply_goal" == "n/a" ]]; then
  reply_goal="12 practical replies"
fi
if [[ "$outreach_goal" == "n/a" ]]; then
  outreach_goal="5 founder outreach follow-ups"
fi
if [[ "$priority_format" == "n/a" ]]; then
  priority_format="podcast"
fi
if [[ "$priority_target" == "n/a" ]]; then
  priority_target="top-priority founder guesting target"
fi
if [[ "$guesting_recommendation" == "n/a" ]]; then
  guesting_recommendation="Translate high-signal guesting replies into confirmed calendar holds the same day."
fi
if [[ "$mix_recommendation" == "n/a" ]]; then
  mix_recommendation="Keep lead/support routing aligned with ROI and reply quality signals."
fi
if [[ -z "$headline_1" ]]; then
  headline_1="Founder execution loop: one scoreboard, one narrative, one proof-first follow-up."
fi
if [[ -z "$headline_2" ]]; then
  headline_2="Operator storytelling works best when every claim has a KPI anchor."
fi
if [[ -z "$talking_point_1" ]]; then
  talking_point_1="Why weekly scoreboard discipline beats ad-hoc launch posting."
fi
if [[ -z "$talking_point_2" ]]; then
  talking_point_2="How to keep momentum narrative tied to one concrete experiment."
fi
if [[ -z "$channel_sequence_1" ]]; then
  channel_sequence_1="Day 1: publish the proof-first founder narrative in the lead channel."
fi
if [[ -z "$action_1" ]]; then
  action_1="Publish proof-first message in lead channel with strongest metric."
fi
if [[ -z "$action_2" ]]; then
  action_2="Ship support-channel follow-up with one concrete CTA."
fi
if [[ -z "$action_3" ]]; then
  action_3="Handle practical replies and log repeated objections."
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-interview-prep -->

# Founder Fame Interview Prep: ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source ops brief: $(source_label "$ops_brief_path")
Source action queue: $(source_label "$action_queue_path")
Source press kit: $(source_label "$press_kit_path")
Source media blast: $(source_label "$media_blast_path")
Source guesting brief: $(source_label "$guesting_brief_path")

## Snapshot

- Ops brief: ${ops_heading}
- Action queue: ${action_queue_heading}
- Press kit: ${press_heading}
- Media blast: ${media_heading}
- Guesting brief: ${guesting_heading}
- Metric focus: ${metric_focus}
- Strongest metric: ${strongest_metric}
- Scoreboard state: ${scoreboard_state}
- Lead / support channels: ${lead_channel} / ${support_channel}
- Priority format / target: ${priority_format} / ${priority_target}
- Reply goal (24h): ${reply_goal}
- Outreach goal (7d): ${outreach_goal}
- Mix recommendation: ${mix_recommendation}

## Opening Scripts

### 10-Second Opener

\`\`\`text
I’m the founder of ${product_name}. This week we’re focused on ${metric_focus}, and our strongest proof is ${strongest_metric}.
\`\`\`

### 30-Second Opener

\`\`\`text
Quick context: ${weekly_summary}
We route proof through ${lead_channel} first, then reinforce in ${support_channel}.
This week’s strongest signal: ${strongest_metric}.
Current execution priority: ${action_1}
\`\`\`

### 2-Minute Story Arc

1. Context: ${weekly_narrative}
2. Proof: ${strongest_metric}
3. Execution: ${action_1} -> ${action_2} -> ${action_3}
4. Ask: convert interest into a concrete next step with ${priority_target}.

## Proof Soundbites

- "${headline_1}"
- "${headline_2}"
- "${talking_point_1}"
- "${talking_point_2}"
- "Current execution sequence: ${channel_sequence_1}"

## Tough Questions + Answers

1. Q: Why is this not just founder hype?
   A: We anchor every claim to one metric focus (${metric_focus}) and one strongest signal (${strongest_metric}).
2. Q: What is still weak right now?
   A: ${scoreboard_state}. The live action queue starts with ${action_1}.
3. Q: What changed this week operationally?
   A: We ran ${lead_channel} then ${support_channel}, and documented the next three actions explicitly.
4. Q: How do you avoid scattered channel execution?
   A: We follow one mix call each week: ${mix_recommendation}
5. Q: What do you want from this audience right now?
   A: Hit ${reply_goal} and ${outreach_goal} while prioritizing ${priority_target}.
6. Q: What happens after this interview/post?
   A: We capture objections, convert one into product/docs clarity, and roll learnings into next week’s ops brief.

## CTA Closes

- Close A (operator podcast): "If this is useful, I’ll share the exact weekly command stack and metrics worksheet we run."
- Close B (newsletter feature): "I can send a 5-bullet operating recap with the same proof stack and next-week experiment."
- Close C (community/live): "Happy to run a practical teardown and post what changed one week later."

## Live Checklist

- [ ] Rehearse 10-second opener three times before recording.
- [ ] Rehearse 30-second opener with one metric + one action.
- [ ] Keep top-3 examples ready:
  - [ ] ${action_1}
  - [ ] ${action_2}
  - [ ] ${action_3}
- [ ] Bring one concrete ask for ${priority_target}.
- [ ] Apply guesting recommendation: ${guesting_recommendation}

## Share Block

\`\`\`text
Founder interview prep (${week_label})
Focus: ${metric_focus}
Proof: ${strongest_metric}
Lead/support: ${lead_channel}/${support_channel}
Priority target: ${priority_target}
Top actions:
1) ${action_1}
2) ${action_2}
3) ${action_3}
\`\`\`
EOF

echo "Wrote founder fame interview prep: $output_path"
