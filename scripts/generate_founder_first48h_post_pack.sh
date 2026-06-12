#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder first-48h copy pack from narrative-lab signals.

Usage:
  zsh scripts/generate_founder_first48h_post_pack.sh [options]

Options:
  --week <YYYY-Www>          Week label (default: inferred from narrative lab heading, then current ISO week)
  --product <text>           Product name (default: Fluid Reader)
  --narrative-lab <path>     Founder fame narrative lab markdown path (required)
  --primary-channel <text>   Primary channel label (default: X / Threads)
  --backup-channel <text>    Backup channel label (default: LinkedIn)
  --cta <text>               CTA line appended to Day 0/Day 1/Day 2 copy blocks
  --primary-char-limit <n>   Character limit for primary short variants (default: 280)
  --backup-char-limit <n>    Character limit for backup short variants (default: 500)
  --primary-tone <mode>      Primary tone profile (x-punchy|x-thread|neutral; default inferred from channel)
  --backup-tone <mode>       Backup tone profile (linkedin-context|linkedin-operator|neutral; default inferred from channel)
  --out <path>               Output markdown path (required)
  -h, --help                 Show help

Example:
  zsh scripts/generate_founder_first48h_post_pack.sh \
    --week "2026-W24" \
    --product "Fluid Reader" \
    --narrative-lab ".build/founder/founder-fame-narrative-lab-2026-W24.md" \
    --primary-channel "X / Threads" \
    --backup-channel "LinkedIn" \
    --cta "If you're building, reply with your KPI bottleneck and I'll share the exact command flow." \
    --primary-char-limit "280" \
    --backup-char-limit "500" \
    --primary-tone "x-punchy" \
    --backup-tone "linkedin-context" \
    --out ".build/founder/founder-first48h-post-pack-2026-W24.md"
EOF
}

week_label=""
product_name="Fluid Reader"
narrative_lab_path=""
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="If you're building, reply with your KPI bottleneck and I'll share the exact command flow."
primary_char_limit="280"
backup_char_limit="500"
primary_tone=""
backup_tone=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --product)
      product_name="${2:-}"
      shift 2
      ;;
    --narrative-lab)
      narrative_lab_path="${2:-}"
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
    --primary-char-limit)
      primary_char_limit="${2:-}"
      shift 2
      ;;
    --backup-char-limit)
      backup_char_limit="${2:-}"
      shift 2
      ;;
    --primary-tone)
      primary_tone="${2:-}"
      shift 2
      ;;
    --backup-tone)
      backup_tone="${2:-}"
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

if [[ -z "$narrative_lab_path" ]]; then
  echo "Missing required option: --narrative-lab" >&2
  usage >&2
  exit 1
fi

if [[ -z "$output_path" ]]; then
  echo "Missing required option: --out" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$narrative_lab_path" ]]; then
  echo "Narrative lab file not found: $narrative_lab_path" >&2
  exit 1
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

sanitize_inline() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//\`/}"
  trim_value "$value"
}

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  trim_value "${line#"$prefix"}"
}

split_pair_left() {
  local value="$1"
  if [[ "$value" == *"/"* ]]; then
    trim_value "${value%%/*}"
    return
  fi
  echo ""
}

split_pair_right() {
  local value="$1"
  if [[ "$value" == *"/"* ]]; then
    trim_value "${value#*/}"
    return
  fi
  echo ""
}

extract_day_column() {
  local source_path="$1"
  local day_label="$2"
  local column_index="$3"
  local line
  line="$(rg -m1 "^\\|\\s*${day_label}\\s*\\|" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  print -r -- "$line" | awk -F'|' -v col="$column_index" '{
    value=$col
    gsub(/^[ \t]+|[ \t]+$/, "", value)
    print value
  }'
}

validate_char_limit() {
  local value="$1"
  local option_name="$2"
  if [[ ! "$value" =~ '^[0-9]+$' ]]; then
    echo "Invalid ${option_name}: ${value}. Expected a positive integer." >&2
    exit 1
  fi
  if (( value <= 0 )); then
    echo "Invalid ${option_name}: ${value}. Expected a value greater than 0." >&2
    exit 1
  fi
}

infer_default_primary_tone() {
  local channel_value="$(print -r -- "${1:-}" | tr '[:upper:]' '[:lower:]')"
  if [[ "$channel_value" == *"x"* || "$channel_value" == *"thread"* ]]; then
    echo "x-punchy"
    return
  fi
  echo "neutral"
}

infer_default_backup_tone() {
  local channel_value="$(print -r -- "${1:-}" | tr '[:upper:]' '[:lower:]')"
  if [[ "$channel_value" == *"linkedin"* ]]; then
    echo "linkedin-context"
    return
  fi
  echo "neutral"
}

validate_tone_value() {
  local tone_value="$1"
  local option_name="$2"
  shift 2
  local allowed_values=("$@")
  local allowed

  for allowed in "${allowed_values[@]}"; do
    if [[ "$tone_value" == "$allowed" ]]; then
      return
    fi
  done

  echo "Invalid ${option_name}: ${tone_value}. Allowed values: ${allowed_values[*]}." >&2
  exit 1
}

build_toned_variant_source() {
  local tone="$1"
  local day_label="$2"
  local channel_label="$3"
  local objective="$4"
  local proof_anchor="$5"
  local next_action="$6"
  local route_winner_value="$7"
  local route_mode_value="$8"
  local cta_value="$9"

  case "$tone" in
    x-punchy)
      sanitize_inline "${day_label}: ${route_winner_value}. ${objective}. Proof: ${proof_anchor}. ${cta_value}"
      ;;
    x-thread)
      sanitize_inline "${day_label} thread: winner=${route_winner_value}. Why now: ${proof_anchor}. Execution: ${objective}. Next standup: ${next_action}. ${cta_value}"
      ;;
    linkedin-context)
      sanitize_inline "${day_label} operator update (${channel_label}): Narrative route=${route_winner_value} under ${route_mode_value}. Objective: ${objective}. Evidence: ${proof_anchor}. ${cta_value}"
      ;;
    linkedin-operator)
      sanitize_inline "${day_label} execution note (${channel_label}): Decision=${route_winner_value}. Action=${objective}. Proof checkpoint=${proof_anchor}. Standup handoff=${next_action}. ${cta_value}"
      ;;
    neutral)
      sanitize_inline "${day_label}: ${route_winner_value}. Objective: ${objective}. Proof: ${proof_anchor}. ${cta_value}"
      ;;
    *)
      sanitize_inline "${day_label}: ${route_winner_value}. Objective: ${objective}. Proof: ${proof_anchor}. ${cta_value}"
      ;;
  esac
}

clip_text_to_limit() {
  local text="$1"
  local limit="$2"
  awk -v text="$text" -v limit="$limit" '
    BEGIN {
      if (limit <= 0) {
        print text;
        exit;
      }

      token_count = split(text, tokens, /[[:space:]]+/);
      output = "";
      for (i = 1; i <= token_count; i++) {
        token = tokens[i];
        if (token == "") continue;
        candidate = (output == "" ? token : output " " token);
        if (length(candidate) <= limit) {
          output = candidate;
        } else {
          break;
        }
      }

      if (output == "") {
        output = substr(text, 1, limit);
        gsub(/[[:space:]]+$/, "", output);
      }

      if (length(output) < length(text)) {
        if (limit > 3) {
          if (length(output) + 3 <= limit) {
            output = output "...";
          } else {
            output = substr(output, 1, limit - 3) "...";
          }
        } else {
          output = substr(output, 1, limit);
        }
      }

      print output;
    }
  '
}

primary_char_limit="$(trim_value "$primary_char_limit")"
backup_char_limit="$(trim_value "$backup_char_limit")"
validate_char_limit "$primary_char_limit" "--primary-char-limit"
validate_char_limit "$backup_char_limit" "--backup-char-limit"

if [[ -z "$week_label" ]]; then
  week_label="$(rg -m1 '^# Founder Fame Narrative Lab - ' "$narrative_lab_path" | sed 's/^# Founder Fame Narrative Lab - //' || true)"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

route_winner="$(extract_prefixed_value "$narrative_lab_path" "- Narrative route winner: ")"
route_mode="$(extract_prefixed_value "$narrative_lab_path" "- Route lab mode: ")"
distribution_strategy="$(extract_prefixed_value "$narrative_lab_path" "- Distribution strategy: ")"
first_48h_execution_plan="$(extract_prefixed_value "$narrative_lab_path" "- First 48h execution plan: ")"
next_standup_action="$(extract_prefixed_value "$narrative_lab_path" "- Next standup action: ")"
route_alignment_target="$(extract_prefixed_value "$narrative_lab_path" "- Route alignment target: ")"
route_guardrail="$(extract_prefixed_value "$narrative_lab_path" "- Route guardrail: ")"
route_lane_trigger="$(extract_prefixed_value "$narrative_lab_path" "- Route lane trigger: ")"
route_recommendation_now="$(extract_prefixed_value "$narrative_lab_path" "- Route recommendation now: ")"
audience_regions="$(extract_prefixed_value "$narrative_lab_path" "- Audience regions: ")"
publish_windows="$(extract_prefixed_value "$narrative_lab_path" "- Publish windows: ")"

day0_lead_lane="$(extract_day_column "$narrative_lab_path" "Day 0" 3)"
day0_support_lane="$(extract_day_column "$narrative_lab_path" "Day 0" 4)"
day0_objective="$(extract_day_column "$narrative_lab_path" "Day 0" 5)"
day0_proof_anchor="$(extract_day_column "$narrative_lab_path" "Day 0" 6)"
day1_lead_lane="$(extract_day_column "$narrative_lab_path" "Day 1" 3)"
day1_support_lane="$(extract_day_column "$narrative_lab_path" "Day 1" 4)"
day1_objective="$(extract_day_column "$narrative_lab_path" "Day 1" 5)"
day1_proof_anchor="$(extract_day_column "$narrative_lab_path" "Day 1" 6)"
day2_lead_lane="$(extract_day_column "$narrative_lab_path" "Day 2" 3)"
day2_support_lane="$(extract_day_column "$narrative_lab_path" "Day 2" 4)"
day2_objective="$(extract_day_column "$narrative_lab_path" "Day 2" 5)"
day2_proof_anchor="$(extract_day_column "$narrative_lab_path" "Day 2" 6)"

product_name="$(sanitize_inline "${product_name:-Fluid Reader}")"
primary_channel="$(sanitize_inline "${primary_channel:-X / Threads}")"
backup_channel="$(sanitize_inline "${backup_channel:-LinkedIn}")"
cta_text="$(sanitize_inline "${cta_text:-If you're building, reply with your KPI bottleneck and I'll share the exact command flow.}")"
primary_tone="$(sanitize_inline "${primary_tone:-}")"
backup_tone="$(sanitize_inline "${backup_tone:-}")"
route_winner="$(sanitize_inline "${route_winner:-Proof-first route}")"
route_mode="$(sanitize_inline "${route_mode:-Route Compounding}")"
distribution_strategy="$(sanitize_inline "${distribution_strategy:-Compounding cadence: lead with winner amplification, follow with social-proof compounding.}")"
first_48h_execution_plan="$(sanitize_inline "${first_48h_execution_plan:-Capture Day 0/Day 1/Day 2 route actions before distribution starts.}")"
next_standup_action="$(sanitize_inline "${next_standup_action:-Log one route winner and one blocked route in standup notes.}")"
route_alignment_target="$(sanitize_inline "${route_alignment_target:-Aligned + Stable}")"
route_guardrail="$(sanitize_inline "${route_guardrail:-Keep each post tied to one measurable proof line and CTA.}")"
route_lane_trigger="$(sanitize_inline "${route_lane_trigger:-Escalate if route lane status degrades in the next standup.}")"
route_recommendation_now="$(sanitize_inline "${route_recommendation_now:-Keep route winner and proof anchor locked for the next 48 hours.}")"
audience_regions="$(sanitize_inline "${audience_regions:-Global / Global}")"
publish_windows="$(sanitize_inline "${publish_windows:-13:00 UTC / 18:00 UTC}")"
day0_lead_lane="$(sanitize_inline "${day0_lead_lane:-$primary_channel}")"
day0_support_lane="$(sanitize_inline "${day0_support_lane:-$backup_channel}")"
day0_objective="$(sanitize_inline "${day0_objective:-Launch one route-winner proof post and pin the narrative route.}")"
day0_proof_anchor="$(sanitize_inline "${day0_proof_anchor:-Ship one proof-first narrative in the first posting window.}")"
day1_lead_lane="$(sanitize_inline "${day1_lead_lane:-$backup_channel}")"
day1_support_lane="$(sanitize_inline "${day1_support_lane:-$primary_channel}")"
day1_objective="$(sanitize_inline "${day1_objective:-Close practical replies and publish one objection-breaker follow-up.}")"
day1_proof_anchor="$(sanitize_inline "${day1_proof_anchor:-Practical reply target from the narrative lab.}")"
day2_lead_lane="$(sanitize_inline "${day2_lead_lane:-$primary_channel}")"
day2_support_lane="$(sanitize_inline "${day2_support_lane:-$backup_channel}")"
day2_objective="$(sanitize_inline "${day2_objective:-Push creator + guesting momentum updates from active route lanes.}")"
day2_proof_anchor="$(sanitize_inline "${day2_proof_anchor:-Creator/guesting target from the narrative lab.}")"

primary_publish_window="$(sanitize_inline "$(split_pair_left "$publish_windows")")"
backup_publish_window="$(sanitize_inline "$(split_pair_right "$publish_windows")")"
if [[ -z "$primary_publish_window" ]]; then
  primary_publish_window="13:00 UTC"
fi
if [[ -z "$backup_publish_window" ]]; then
  backup_publish_window="18:00 UTC"
fi

if [[ -z "$primary_tone" ]]; then
  primary_tone="$(infer_default_primary_tone "$primary_channel")"
fi
if [[ -z "$backup_tone" ]]; then
  backup_tone="$(infer_default_backup_tone "$backup_channel")"
fi

validate_tone_value "$primary_tone" "--primary-tone" "x-punchy" "x-thread" "neutral"
validate_tone_value "$backup_tone" "--backup-tone" "linkedin-context" "linkedin-operator" "neutral"

day0_primary_short_source="$(build_toned_variant_source "$primary_tone" "Day 0" "$primary_channel" "$day0_objective" "$day0_proof_anchor" "$next_standup_action" "$route_winner" "$route_mode" "$cta_text")"
day0_backup_short_source="$(build_toned_variant_source "$backup_tone" "Day 0" "$backup_channel" "$day0_objective" "$day0_proof_anchor" "$next_standup_action" "$route_winner" "$route_mode" "$cta_text")"
day1_primary_short_source="$(build_toned_variant_source "$primary_tone" "Day 1" "$primary_channel" "$day1_objective" "$day1_proof_anchor" "$next_standup_action" "$route_winner" "$route_mode" "$cta_text")"
day1_backup_short_source="$(build_toned_variant_source "$backup_tone" "Day 1" "$backup_channel" "$day1_objective" "$day1_proof_anchor" "$next_standup_action" "$route_winner" "$route_mode" "$cta_text")"
day2_primary_short_source="$(build_toned_variant_source "$primary_tone" "Day 2" "$primary_channel" "$day2_objective" "$day2_proof_anchor" "$next_standup_action" "$route_winner" "$route_mode" "$cta_text")"
day2_backup_short_source="$(build_toned_variant_source "$backup_tone" "Day 2" "$backup_channel" "$day2_objective" "$day2_proof_anchor" "$next_standup_action" "$route_winner" "$route_mode" "$cta_text")"

day0_primary_short="$(clip_text_to_limit "$day0_primary_short_source" "$primary_char_limit")"
day0_backup_short="$(clip_text_to_limit "$day0_backup_short_source" "$backup_char_limit")"
day1_primary_short="$(clip_text_to_limit "$day1_primary_short_source" "$primary_char_limit")"
day1_backup_short="$(clip_text_to_limit "$day1_backup_short_source" "$backup_char_limit")"
day2_primary_short="$(clip_text_to_limit "$day2_primary_short_source" "$primary_char_limit")"
day2_backup_short="$(clip_text_to_limit "$day2_backup_short_source" "$backup_char_limit")"

day0_primary_short_count="${#day0_primary_short}"
day0_backup_short_count="${#day0_backup_short}"
day1_primary_short_count="${#day1_primary_short}"
day1_backup_short_count="${#day1_backup_short}"
day2_primary_short_count="${#day2_primary_short}"
day2_backup_short_count="${#day2_backup_short}"

day0_comment_seed="$(sanitize_inline "If you want the exact Day 0 command stack we used for ${route_winner}, reply \"route\" and I’ll paste it.")"
day1_comment_seed="$(sanitize_inline "If this objection is your blocker too, reply \"objection\" and I’ll share the exact Day 1 response ladder.")"
day2_comment_seed="$(sanitize_inline "If you want our Day 2 compounding checklist, reply \"scale\" and I’ll share the creator + guesting execution sheet.")"

objection_fast_reply="$(sanitize_inline "Quick answer: ${route_winner} works because we anchor every claim to one measurable proof line (${day0_proof_anchor}).")"
objection_operator_reply="$(sanitize_inline "Operator answer: We run Day 0 = ${day0_objective}; Day 1 = ${day1_objective}; Day 2 = ${day2_objective}. That sequence protects focus and compounds proof.")"
objection_cta_reply="$(sanitize_inline "If you share your KPI bottleneck, I’ll map the same Day 0/1/2 route to your context.")"

friction_fast_reply="$(sanitize_inline "Quick answer: this is built for low-time teams — one lead lane, one support lane, and one standup action (${next_standup_action}).")"
friction_operator_reply="$(sanitize_inline "Operator answer: the minimum loop is one post + one reply wave + one compounding update. You can run it in under 48 hours.")"
friction_cta_reply="$(sanitize_inline "Reply with your available time window and I’ll suggest a compressed route.")"

proof_fast_reply="$(sanitize_inline "Quick answer: proof anchor this week is ${day0_proof_anchor}. Day 1 validates with ${day1_proof_anchor}. Day 2 compounds with ${day2_proof_anchor}.")"
proof_operator_reply="$(sanitize_inline "Operator answer: we only keep routes that produce measurable proof and remove lanes that do not convert.")"
proof_cta_reply="$(sanitize_inline "Reply \"proof\" and I’ll share the evidence-first post + follow-up sequence.")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- weekly-growth-founder-first48h-post-pack -->

# Founder First 48h Post Pack: ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source narrative lab: ${narrative_lab_path}

## Signal Snapshot

- Narrative route winner: ${route_winner}
- Route lab mode: ${route_mode}
- Distribution strategy: ${distribution_strategy}
- First 48h execution plan: ${first_48h_execution_plan}
- CTA line: ${cta_text}
- Primary tone profile: ${primary_tone}
- Backup tone profile: ${backup_tone}

## Route Control Handshake (First 48h)

- Route alignment target: ${route_alignment_target}
- Route guardrail: ${route_guardrail}
- Route lane trigger: ${route_lane_trigger}
- Route recommendation now: ${route_recommendation_now}
- Audience regions: ${audience_regions}
- Publish windows: ${publish_windows}

## 48h Micro-Experiment Board

| Day | Experiment | Success signal | Fallback action |
| --- | --- | --- | --- |
| Day 0 | Run primary vs backup short variant tone test (${primary_tone} vs ${backup_tone}) | Replies mention concrete KPI blockers within first response wave | If weak response quality, enforce: ${route_guardrail} |
| Day 1 | Run objection ladder fast reply vs operator reply in parallel | One objection thread moves to next-step commitment | If no conversion signal, apply: ${route_recommendation_now} |
| Day 2 | Run CTA specificity test (route / objection / scale) across reply seeds | More actionable inbound prompts before next standup | If replies stall, trigger: ${route_lane_trigger} |

## Day 0 Launch Copy (Lead)

- Lead lane: ${day0_lead_lane}
- Support lane: ${day0_support_lane}
- Objective: ${day0_objective}
- Proof anchor: ${day0_proof_anchor}

\`\`\`text
Founder route winner this week: ${route_winner}.

Day 0 objective: ${day0_objective}
Proof anchor: ${day0_proof_anchor}

We're running ${route_mode} and keeping this practical.
${cta_text}
\`\`\`

## Day 1 Reinforcement Copy (Support)

- Lead lane: ${day1_lead_lane}
- Support lane: ${day1_support_lane}
- Objective: ${day1_objective}
- Proof anchor: ${day1_proof_anchor}

\`\`\`text
Day 1 follow-up from the ${route_winner} lane.

Focus: ${day1_objective}
Evidence: ${day1_proof_anchor}

${cta_text}
\`\`\`

## Day 2 Compounding Copy (Scale)

- Lead lane: ${day2_lead_lane}
- Support lane: ${day2_support_lane}
- Objective: ${day2_objective}
- Proof anchor: ${day2_proof_anchor}

\`\`\`text
Day 2 compounding update:
${route_winner} stays in front while we scale outcomes.

Objective: ${day2_objective}
Proof anchor: ${day2_proof_anchor}

Next standup action: ${next_standup_action}
${cta_text}
\`\`\`

## Channel-Ready Short Variants

- Primary short variant target: <=${primary_char_limit} chars
- Backup short variant target: <=${backup_char_limit} chars
- Primary tone profile: ${primary_tone}
- Backup tone profile: ${backup_tone}

### Day 0 Short Variants

- Primary length: ${day0_primary_short_count}/${primary_char_limit}

\`\`\`text
${day0_primary_short}
\`\`\`

- Backup length: ${day0_backup_short_count}/${backup_char_limit}

\`\`\`text
${day0_backup_short}
\`\`\`

### Day 1 Short Variants

- Primary length: ${day1_primary_short_count}/${primary_char_limit}

\`\`\`text
${day1_primary_short}
\`\`\`

- Backup length: ${day1_backup_short_count}/${backup_char_limit}

\`\`\`text
${day1_backup_short}
\`\`\`

### Day 2 Short Variants

- Primary length: ${day2_primary_short_count}/${primary_char_limit}

\`\`\`text
${day2_primary_short}
\`\`\`

- Backup length: ${day2_backup_short_count}/${backup_char_limit}

\`\`\`text
${day2_backup_short}
\`\`\`

## Rapid Reply Prompts

1. Which step in this route is slowest for you right now?
2. Want the proof-first version or objection-breaker version first?
3. Share one KPI blocker and I’ll map Day 0/1/2 actions.

## Comment Trigger Seeds (Post-Reply Boost)

- Day 0 first comment seed: ${day0_comment_seed}
- Day 1 first comment seed: ${day1_comment_seed}
- Day 2 first comment seed: ${day2_comment_seed}

## Objection Response Ladder

### 1) “Will this route work in my context?”

- Fast reply: ${objection_fast_reply}
- Operator reply: ${objection_operator_reply}
- Conversion CTA: ${objection_cta_reply}

### 2) “I do not have time to run this every week.”

- Fast reply: ${friction_fast_reply}
- Operator reply: ${friction_operator_reply}
- Conversion CTA: ${friction_cta_reply}

### 3) “Show me proof before I copy this.”

- Fast reply: ${proof_fast_reply}
- Operator reply: ${proof_operator_reply}
- Conversion CTA: ${proof_cta_reply}

## Escalation & Adaptation Triggers

1. Route lane trigger: ${route_lane_trigger}
2. Route recommendation now: ${route_recommendation_now}
3. If Day 1 conversion stalls, reinforce with proof anchor: ${day1_proof_anchor}
4. If Day 2 amplification underperforms, switch lead/support windows: ${primary_publish_window} <-> ${backup_publish_window}

## First 48h Execution Checklist

- [ ] Ship Day 0 lead-lane post with proof anchor.
- [ ] Run Day 1 support-lane reply wave.
- [ ] Publish Day 2 compounding update with standup action.
- [ ] Log one route win and one blocked step before next standup.
EOF

echo "Generated founder first-48h post pack: $output_path"
