#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame execution scorecard from sprint and launch-operation artifacts.

Usage:
  zsh scripts/generate_founder_fame_execution_scorecard.sh [options]

Required:
  --execution-sprint <path>      Founder fame execution sprint markdown

Optional:
  --opportunity-radar <path>     Founder fame opportunity radar markdown
  --momentum-brief <path>        Founder fame momentum brief markdown
  --distribution-plan <path>     7-day distribution follow-up plan markdown
  --monday-checkpoint <path>     Monday publish checkpoint markdown
  --reply-pack <path>            First-24-hour reply pack markdown
  --week <label>                 Week label (default: inferred from execution sprint heading, then current ISO week)
  --product <text>               Product name (default: Fluid Reader)
  --out <path>                   Output path (default: docs/campaigns/<week>-founder-fame-execution-scorecard.md)
  -h, --help                     Show help

Example:
  zsh scripts/generate_founder_fame_execution_scorecard.sh \
    --execution-sprint docs/campaigns/2026-W24-founder-fame-execution-sprint.md \
    --opportunity-radar docs/campaigns/2026-W24-founder-fame-opportunity-radar.md \
    --momentum-brief docs/campaigns/2026-W24-founder-fame-momentum-brief.md \
    --distribution-plan docs/campaigns/2026-W24-distribution-plan.md \
    --monday-checkpoint docs/campaigns/2026-W24-monday-checkpoint.md \
    --reply-pack docs/campaigns/2026-W24-reply-pack.md \
    --out docs/campaigns/2026-W24-founder-fame-execution-scorecard.md
EOF
}

execution_sprint_path=""
opportunity_radar_path=""
momentum_brief_path=""
distribution_plan_path=""
monday_checkpoint_path=""
reply_pack_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --execution-sprint)
      execution_sprint_path="${2:-}"
      shift 2
      ;;
    --opportunity-radar)
      opportunity_radar_path="${2:-}"
      shift 2
      ;;
    --momentum-brief)
      momentum_brief_path="${2:-}"
      shift 2
      ;;
    --distribution-plan)
      distribution_plan_path="${2:-}"
      shift 2
      ;;
    --monday-checkpoint)
      monday_checkpoint_path="${2:-}"
      shift 2
      ;;
    --reply-pack)
      reply_pack_path="${2:-}"
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

if [[ -z "$execution_sprint_path" ]]; then
  echo "Missing required option: --execution-sprint" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$execution_sprint_path" ]]; then
  echo "Execution sprint file not found: $execution_sprint_path" >&2
  exit 1
fi

for optional_path in "$opportunity_radar_path" "$momentum_brief_path" "$distribution_plan_path" "$monday_checkpoint_path" "$reply_pack_path"; do
  if [[ -n "$optional_path" && ! -f "$optional_path" ]]; then
    echo "Optional source file not found: $optional_path" >&2
    exit 1
  fi
done

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

sanitize_inline() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//|//}"
  value="${value//\`/}"
  trim_value "$value"
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

extract_week_from_execution_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Execution Sprint - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Execution Sprint - "}"
}

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi
  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  trim_value "${line#"$prefix"}"
}

extract_section_prefixed_value() {
  local source_path="$1"
  local section_heading="$2"
  local prefix="$3"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -v heading="$section_heading" -v prefix="$prefix" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section {
      if (index($0, prefix) == 1) {
        value = substr($0, length(prefix) + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", value)
        print value
        exit
      }
    }
  ' "$source_path"
}

extract_number() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true)"
  echo "$number"
}

count_table_rows() {
  local source_path="$1"
  local section_heading="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "0"
    return
  fi

  awk -F'|' -v heading="$section_heading" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Day" || first ~ /^---/) next
      count++
    }
    END { print count + 0 }
  ' "$source_path"
}

count_numbered_lines() {
  local source_path="$1"
  local section_heading="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "0"
    return
  fi

  awk -v heading="$section_heading" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^[0-9]+\./ { count++ }
    END { print count + 0 }
  ' "$source_path"
}

count_bullet_lines() {
  local source_path="$1"
  local section_heading="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "0"
    return
  fi

  awk -v heading="$section_heading" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^- / { count++ }
    END { print count + 0 }
  ' "$source_path"
}

count_checklist_lines() {
  local source_path="$1"
  local section_heading="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "0"
    return
  fi

  awk -v heading="$section_heading" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^- \[ \]/ { count++ }
    END { print count + 0 }
  ' "$source_path"
}

count_reply_templates() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "0"
    return
  fi

  awk '
    /^## Core Replies/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^### Reply:/ { count++ }
    END { print count + 0 }
  ' "$source_path"
}

score_from_ratio() {
  local actual="$1"
  local target="$2"
  local max_score="$3"
  awk -v actual="$actual" -v target="$target" -v max_score="$max_score" 'BEGIN {
    a = actual + 0
    t = target + 0
    m = max_score + 0
    if (t <= 0) {
      printf "%.0f", m
      exit
    }
    ratio = a / t
    if (ratio < 0) ratio = 0
    if (ratio > 1) ratio = 1
    printf "%.0f", ratio * m
  }'
}

normalize_narrative_route() {
  local value lowered
  value="$(trim_value "$1")"
  lowered="${value:l}"
  if [[ -z "$value" || "$lowered" == "n/a" || "$lowered" == "none" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == *"proof-first"* || "$lowered" == *"proof first"* ]]; then
    echo "Proof-first route"
    return
  fi
  if [[ "$lowered" == *"behind-the-scenes"* || "$lowered" == *"behind the scenes"* || "$lowered" == *"bts"* ]]; then
    echo "Behind-the-scenes route"
    return
  fi
  if [[ "$lowered" == *"objection-breaker"* || "$lowered" == *"objection breaker"* || "$lowered" == *"objection-handler"* || "$lowered" == *"objection handler"* ]]; then
    echo "Objection-breaker route"
    return
  fi
  if [[ "$lowered" == *"hook-driven"* || "$lowered" == *"hook driven"* ]]; then
    echo "Hook-driven overlay"
    return
  fi
  echo "$value"
}

normalize_opportunity_name() {
  local value lowered
  value="$(trim_value "$1")"
  value="${value%%\(*}"
  value="$(trim_value "$value")"
  lowered="${value:l}"
  if [[ -z "$value" || "$lowered" == "n/a" || "$lowered" == "none" || "$lowered" == "unknown" ]]; then
    echo "n/a"
    return
  fi
  if [[ "$lowered" == *"distribution recovery sprint"* ]]; then
    echo "Distribution Recovery Sprint"
    return
  fi
  if [[ "$lowered" == *"objection crush sequence"* ]]; then
    echo "Objection Crush Sequence"
    return
  fi
  if [[ "$lowered" == *"kpi proof amplifier"* ]]; then
    echo "KPI Proof Amplifier"
    return
  fi
  if [[ "$lowered" == *"narrative compounding loop"* ]]; then
    echo "Narrative Compounding Loop"
    return
  fi
  echo "$value"
}

resolve_expected_route_opportunity() {
  local route="$1"
  case "$route" in
    "Proof-first route")
      echo "KPI Proof Amplifier"
      ;;
    "Behind-the-scenes route")
      echo "Narrative Compounding Loop"
      ;;
    "Objection-breaker route")
      echo "Objection Crush Sequence"
      ;;
    "Hook-driven overlay")
      echo "Narrative Compounding Loop"
      ;;
    *)
      echo "n/a"
      ;;
  esac
}

resolve_expected_execution_mode() {
  local route="$1"
  case "$route" in
    "Proof-first route")
      echo "Proof-first acceleration mode"
      ;;
    "Behind-the-scenes route")
      echo "Behind-the-scenes compounding mode"
      ;;
    "Objection-breaker route")
      echo "Objection-breaker conversion mode"
      ;;
    "Hook-driven overlay")
      echo "Hook-driven experimentation mode"
      ;;
    *)
      echo "General narrative momentum mode"
      ;;
  esac
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_execution_heading "$execution_sprint_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-execution-scorecard.md"
fi

execution_heading="$(extract_heading "$execution_sprint_path")"
opportunity_heading="$(extract_heading "$opportunity_radar_path")"
momentum_heading="$(extract_heading "$momentum_brief_path")"
distribution_heading="$(extract_heading "$distribution_plan_path")"
monday_heading="$(extract_heading "$monday_checkpoint_path")"
reply_heading="$(extract_heading "$reply_pack_path")"

top_bet="$(extract_prefixed_value "$execution_sprint_path" "- Top bet this week: ")"
top_priority_raw="$(extract_prefixed_value "$execution_sprint_path" "- Top bet priority: ")"
owner_line="$(extract_prefixed_value "$execution_sprint_path" "- Suggested owner: ")"
day0_ship_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Weekly Fame Objective" "- Day 0 ship item: ")"
guardrail_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Weekly Fame Objective" "- Guardrail: ")"
weakest_signal_line="$(extract_prefixed_value "$execution_sprint_path" "- Weakest signal context: ")"
risk_call_line="$(extract_prefixed_value "$execution_sprint_path" "- Primary risk call: ")"
narrative_route_winner_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Narrative Route Execution Mode" "- Narrative route winner: ")"
narrative_route_trend_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Narrative Route Execution Mode" "- Route trend: ")"
narrative_fame_velocity_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Narrative Route Execution Mode" "- Fame velocity score: ")"
execution_mode_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Narrative Route Execution Mode" "- Execution mode: ")"
route_guardrail_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Narrative Route Execution Mode" "- Route-specific guardrail: ")"
narrative_ranked_opportunity_line="$(extract_section_prefixed_value "$execution_sprint_path" "## Narrative Route Execution Mode" "- Ranked route opportunity: ")"
radar_narrative_ranked_line="$(extract_prefixed_value "$opportunity_radar_path" "- Narrative-ranked opportunity: ")"

if [[ -z "$narrative_route_winner_line" ]]; then
  narrative_route_winner_line="$(extract_prefixed_value "$execution_sprint_path" "- Narrative route winner: ")"
fi
if [[ -z "$execution_mode_line" ]]; then
  execution_mode_line="$(extract_prefixed_value "$execution_sprint_path" "- Execution mode: ")"
fi
if [[ -z "$narrative_ranked_opportunity_line" ]]; then
  narrative_ranked_opportunity_line="$(extract_prefixed_value "$execution_sprint_path" "- Narrative-ranked opportunity: ")"
fi

primary_window_line="$(extract_prefixed_value "$monday_checkpoint_path" "- Primary channel ")"
backup_window_line="$(extract_prefixed_value "$monday_checkpoint_path" "- Backup channel ")"

momentum_readiness_line="$(extract_prefixed_value "$momentum_brief_path" "- Fame readiness score: ")"
if [[ -z "$momentum_readiness_line" ]]; then
  momentum_readiness_line="$(extract_prefixed_value "$execution_sprint_path" "- Fame readiness context: ")"
fi

mission_count="$(count_table_rows "$execution_sprint_path" "## 7-Day Mission Board")"
prompt_count="$(count_numbered_lines "$execution_sprint_path" "## Daily Check-In Prompts")"
escalation_count="$(count_bullet_lines "$execution_sprint_path" "## Escalation Triggers")"
distribution_checklist_count="$(count_checklist_lines "$distribution_plan_path" "## Execution Checklist")"
reply_template_count="$(count_reply_templates "$reply_pack_path")"

top_priority_value="$(extract_number "$top_priority_raw")"
if [[ -z "$top_priority_value" ]]; then
  top_priority_value=55
fi

momentum_readiness_value="$(extract_number "$momentum_readiness_line")"
if [[ -z "$momentum_readiness_value" ]]; then
  momentum_readiness_value=52
fi

normalized_route_winner="$(normalize_narrative_route "$narrative_route_winner_line")"
normalized_execution_mode="$(trim_value "$execution_mode_line")"
if [[ -z "$normalized_execution_mode" ]]; then
  normalized_execution_mode="n/a"
fi
normalized_ranked_opportunity="$(normalize_opportunity_name "$narrative_ranked_opportunity_line")"
if [[ "$normalized_ranked_opportunity" == "n/a" ]]; then
  normalized_ranked_opportunity="$(normalize_opportunity_name "$radar_narrative_ranked_line")"
fi
expected_route_opportunity="$(resolve_expected_route_opportunity "$normalized_route_winner")"
expected_execution_mode="$(resolve_expected_execution_mode "$normalized_route_winner")"

route_alignment_raw=0
if [[ "$normalized_route_winner" != "n/a" ]]; then
  route_alignment_raw=$((route_alignment_raw + 1))
  if [[ "$normalized_execution_mode" == "$expected_execution_mode" ]]; then
    route_alignment_raw=$((route_alignment_raw + 1))
  fi
  if [[ "$normalized_ranked_opportunity" == "$expected_route_opportunity" ]]; then
    route_alignment_raw=$((route_alignment_raw + 1))
  fi
elif [[ "$normalized_execution_mode" == "General narrative momentum mode" ]]; then
  route_alignment_raw=1
fi

route_alignment_signal="Missing"
if [[ "$normalized_route_winner" == "n/a" ]]; then
  if (( route_alignment_raw >= 1 )); then
    route_alignment_signal="Fallback active"
  fi
elif (( route_alignment_raw >= 3 )); then
  route_alignment_signal="Aligned"
elif (( route_alignment_raw == 2 )); then
  route_alignment_signal="Partial"
else
  route_alignment_signal="Drifting"
fi

route_alignment_score="$(awk -v route="$normalized_route_winner" -v raw="$route_alignment_raw" 'BEGIN {
  r = raw + 0
  if (route == "n/a") {
    if (r >= 1) print 1
    else print 0
  } else {
    if (r >= 3) print 2
    else if (r >= 2) print 1
    else print 0
  }
}')"

owner_score=0
if [[ -n "$owner_line" && "$owner_line" != "n/a" ]]; then
  owner_score=10
fi

day0_score=0
if [[ -n "$day0_ship_line" && "$day0_ship_line" != "n/a" ]]; then
  day0_score=10
fi

mission_score="$(score_from_ratio "$mission_count" 7 20)"
prompt_score="$(score_from_ratio "$prompt_count" 5 10)"
escalation_score="$(score_from_ratio "$escalation_count" 4 15)"
distribution_score="$(score_from_ratio "$distribution_checklist_count" 6 10)"
reply_score="$(score_from_ratio "$reply_template_count" 5 10)"

window_score=0
if [[ -n "$primary_window_line" ]]; then
  window_score=$(( window_score + 5 ))
fi
if [[ -n "$backup_window_line" ]]; then
  window_score=$(( window_score + 5 ))
fi

priority_score="$(awk -v priority="$top_priority_value" 'BEGIN {
  p = priority + 0
  if (p >= 75) print 10
  else if (p >= 65) print 8
  else if (p >= 55) print 6
  else if (p >= 45) print 4
  else print 2
}')"

momentum_score="$(awk -v readiness="$momentum_readiness_value" 'BEGIN {
  r = readiness + 0
  if (r >= 75) print 3
  else if (r >= 60) print 2
  else if (r >= 45) print 1
  else print 0
}')"

execution_readiness_score="$(awk \
  -v owner="$owner_score" \
  -v day0="$day0_score" \
  -v mission="$mission_score" \
  -v prompt="$prompt_score" \
  -v escalation="$escalation_score" \
  -v distribution="$distribution_score" \
  -v reply="$reply_score" \
  -v window="$window_score" \
  -v priority="$priority_score" \
  -v momentum="$momentum_score" \
  -v route="$route_alignment_score" \
  'BEGIN {
    total = owner + day0 + mission + prompt + escalation + distribution + reply + window + priority + momentum + route
    if (total < 0) total = 0
    if (total > 100) total = 100
    printf "%.0f", total
  }')"

readiness_tier="At Risk"
if (( execution_readiness_score >= 85 )); then
  readiness_tier="Execution-Locked"
elif (( execution_readiness_score >= 70 )); then
  readiness_tier="Ready-to-Ship"
elif (( execution_readiness_score >= 55 )); then
  readiness_tier="Needs Alignment"
fi

risk_flags=()
if (( mission_count < 7 )); then
  risk_flags+=("Mission board is incomplete (${mission_count}/7 days mapped).")
fi
if (( reply_template_count < 5 )); then
  risk_flags+=("Reply template coverage is thin (${reply_template_count}/5 core prompts).")
fi
if (( distribution_checklist_count < 6 )); then
  risk_flags+=("Distribution execution checklist has low coverage (${distribution_checklist_count}/6).")
fi
if (( escalation_count < 3 )); then
  risk_flags+=("Escalation trigger coverage is limited (${escalation_count} trigger rules).")
fi
if (( top_priority_value < 60 )); then
  risk_flags+=("Top bet priority is below preferred threshold (${top_priority_value}/100).")
fi
if [[ -n "$weakest_signal_line" && "$weakest_signal_line" != "n/a" ]]; then
  risk_flags+=("Weakest signal remains: $(sanitize_inline "$weakest_signal_line")")
fi
if [[ -n "$risk_call_line" && "$risk_call_line" != "n/a" ]]; then
  risk_flags+=("Primary risk call: $(sanitize_inline "$risk_call_line")")
fi
if [[ "$normalized_route_winner" == "n/a" ]]; then
  risk_flags+=("Narrative route winner is missing; execution mode is running without route-specific ranking context.")
else
  if [[ "$normalized_execution_mode" != "$expected_execution_mode" ]]; then
    risk_flags+=("Execution mode does not match route winner (${normalized_route_winner} -> expected ${expected_execution_mode}, found ${normalized_execution_mode}).")
  fi
  if [[ "$normalized_ranked_opportunity" != "$expected_route_opportunity" ]]; then
    risk_flags+=("Narrative-ranked opportunity drifts from route target (${normalized_route_winner} -> expected ${expected_route_opportunity}, found ${normalized_ranked_opportunity}).")
  fi
fi
if [[ -z "$route_guardrail_line" || "$route_guardrail_line" == "n/a" ]]; then
  risk_flags+=("Route-specific guardrail is missing from execution sprint output.")
fi
if (( ${#risk_flags[@]} == 0 )); then
  risk_flags+=("No acute execution risks detected from current artifact coverage.")
fi

if [[ -z "$top_bet" ]]; then
  top_bet="Narrative Compounding Loop"
fi
if [[ -z "$owner_line" ]]; then
  owner_line="Founder growth lead"
fi
if [[ -z "$day0_ship_line" ]]; then
  day0_ship_line="Ship one top-bet founder narrative asset in the next launch window."
fi
if [[ -z "$guardrail_line" ]]; then
  guardrail_line="Keep daily execution tightly focused on one top-bet narrative loop."
fi
if [[ -z "$narrative_route_trend_line" ]]; then
  narrative_route_trend_line="n/a"
fi
if [[ -z "$narrative_fame_velocity_line" ]]; then
  narrative_fame_velocity_line="n/a"
fi
if [[ -z "$route_guardrail_line" || "$route_guardrail_line" == "n/a" ]]; then
  route_guardrail_line="$guardrail_line"
fi
if [[ "$normalized_execution_mode" == "n/a" ]]; then
  normalized_execution_mode="$expected_execution_mode"
fi
if [[ "$normalized_ranked_opportunity" == "n/a" ]]; then
  normalized_ranked_opportunity="$top_bet"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<!-- founder-fame-execution-scorecard -->

# Founder Fame Execution Scorecard - $week_label

Generated: $generated_on
Product: $product_name
Source execution sprint: $execution_sprint_path
Source opportunity radar: ${opportunity_radar_path:-n/a}
Source momentum brief: ${momentum_brief_path:-n/a}
Source distribution plan: ${distribution_plan_path:-n/a}
Source Monday checkpoint: ${monday_checkpoint_path:-n/a}
Source reply pack: ${reply_pack_path:-n/a}

## Snapshot

- Execution sprint: $execution_heading
- Opportunity radar: $opportunity_heading
- Momentum brief: $momentum_heading
- Distribution plan: $distribution_heading
- Monday checkpoint: $monday_heading
- Reply pack: $reply_heading
- Top bet: $(sanitize_inline "$top_bet")
- Suggested owner: $(sanitize_inline "$owner_line")
- Day 0 ship item: $(sanitize_inline "$day0_ship_line")
- Guardrail: $(sanitize_inline "$guardrail_line")
- Narrative route winner: $(sanitize_inline "$normalized_route_winner")
- Narrative route trend: $(sanitize_inline "$narrative_route_trend_line")
- Narrative fame velocity score: $(sanitize_inline "$narrative_fame_velocity_line")
- Narrative-ranked opportunity: $(sanitize_inline "$normalized_ranked_opportunity")
- Execution mode: $(sanitize_inline "$normalized_execution_mode")

## Narrative Route Alignment

- Route alignment signal: ${route_alignment_signal}
- Route checks passed: ${route_alignment_raw}/3
- Route contribution: ${route_alignment_score}/2
- Expected route opportunity: $(sanitize_inline "$expected_route_opportunity")
- Expected execution mode: $(sanitize_inline "$expected_execution_mode")
- Route-specific guardrail: $(sanitize_inline "$route_guardrail_line")

## Execution Readiness Score

- Score: ${execution_readiness_score}/100
- Tier: $readiness_tier
- Top-bet priority context: ${top_priority_value}/100
- Momentum readiness context: ${momentum_readiness_value}/100
- Route alignment contribution: ${route_alignment_score}/2

## Signal Breakdown

| Signal | Coverage | Contribution |
| --- | --- | ---: |
| Ownership lock | Owner assigned | ${owner_score}/10 |
| Day 0 launch lock | Top-bet ship item present | ${day0_score}/10 |
| Mission board coverage | ${mission_count}/7 days | ${mission_score}/20 |
| Daily check-in prompts | ${prompt_count}/5 prompts | ${prompt_score}/10 |
| Escalation trigger coverage | ${escalation_count}/4 triggers | ${escalation_score}/15 |
| Distribution checklist coverage | ${distribution_checklist_count}/6 checks | ${distribution_score}/10 |
| Reply template coverage | ${reply_template_count}/5 prompts | ${reply_score}/10 |
| Publish window wiring | Primary/backup windows mapped | ${window_score}/10 |
| Top-bet priority quality | Priority context (${top_priority_value}/100) | ${priority_score}/10 |
| Momentum readiness quality | Readiness context (${momentum_readiness_value}/100) | ${momentum_score}/3 |
| Narrative route alignment | ${route_alignment_signal} (${route_alignment_raw}/3 checks) | ${route_alignment_score}/2 |

## Launch Gates

- [ ] Confirm Day 0 ship item is posted in the primary publish window.
- [ ] Confirm top-bet owner runs first check-in within 6 hours.
- [ ] Confirm first practical replies are handled using reply-pack scripts.
- [ ] Confirm one distribution checklist step is completed before Day 1 handoff.
- [ ] Confirm one risk flag has an explicit owner and mitigation.

## Daily Rhythm Checks

1. Is the top-bet narrative still the highest leverage use of today’s attention?
2. Which reply pattern is converting best, and what should be promoted tomorrow?
3. Which distribution task is at risk of slipping and needs immediate owner support?
4. Which escalation trigger is currently closest to activation?
5. What can we cut now to preserve execution speed for the next 24 hours?

## Risk Flags

EOF

for risk_flag in "${risk_flags[@]}"; do
  echo "- $(sanitize_inline "$risk_flag")" >> "$output_path"
done

cat >> "$output_path" <<EOF

## Next 24 Hours

1. Ship: $(sanitize_inline "$day0_ship_line")
2. Owner sync: $(sanitize_inline "$owner_line") confirms mission progress before Day 1.
3. Replies: Run at least one reply-pack response cycle on live comments.
4. Distribution: Close one open checklist item from the distribution plan.
5. Risk mitigation: Resolve the highest-risk item from the flags above.

## Share Block

\`\`\`text
Founder fame execution scorecard ($week_label)
Execution readiness: ${execution_readiness_score}/100 ($readiness_tier)
Top bet: $(sanitize_inline "$top_bet") (${top_priority_value}/100)
Owner: $(sanitize_inline "$owner_line")
Day 0 ship item: $(sanitize_inline "$day0_ship_line")
Mission coverage: ${mission_count}/7 days
Reply coverage: ${reply_template_count}/5 prompts
Distribution checklist coverage: ${distribution_checklist_count}/6 checks
Narrative route: $(sanitize_inline "$normalized_route_winner")
Execution mode: $(sanitize_inline "$normalized_execution_mode")
Route alignment: ${route_alignment_signal} (${route_alignment_raw}/3 checks)
Guardrail: $(sanitize_inline "$guardrail_line")
Route guardrail: $(sanitize_inline "$route_guardrail_line")
\`\`\`
EOF

echo "Generated founder fame execution scorecard: $output_path"
