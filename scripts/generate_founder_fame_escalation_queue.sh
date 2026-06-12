#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame escalation queue from risk-response and execution-scorecard artifacts.

Usage:
  zsh scripts/generate_founder_fame_escalation_queue.sh [options]

Required:
  --risk-response-plan <path>      Founder fame risk response plan markdown
  --execution-scorecard <path>     Founder fame execution scorecard markdown

Optional:
  --execution-sprint <path>        Founder fame execution sprint markdown
  --distribution-plan <path>       7-day distribution follow-up plan markdown
  --reply-pack <path>              First-24-hour reply pack markdown
  --week <label>                   Week label (default: inferred from risk response heading, then scorecard heading, then current ISO week)
  --product <text>                 Product name (default: Fluid Reader)
  --out <path>                     Output path (default: docs/campaigns/<week>-founder-fame-escalation-queue.md)
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_fame_escalation_queue.sh \
    --risk-response-plan docs/campaigns/2026-W24-founder-fame-risk-response-plan.md \
    --execution-scorecard docs/campaigns/2026-W24-founder-fame-execution-scorecard.md \
    --execution-sprint docs/campaigns/2026-W24-founder-fame-execution-sprint.md \
    --distribution-plan docs/campaigns/2026-W24-distribution-plan.md \
    --reply-pack docs/campaigns/2026-W24-reply-pack.md \
    --out docs/campaigns/2026-W24-founder-fame-escalation-queue.md
EOF
}

risk_response_plan_path=""
execution_scorecard_path=""
execution_sprint_path=""
distribution_plan_path=""
reply_pack_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --risk-response-plan)
      risk_response_plan_path="${2:-}"
      shift 2
      ;;
    --execution-scorecard)
      execution_scorecard_path="${2:-}"
      shift 2
      ;;
    --execution-sprint)
      execution_sprint_path="${2:-}"
      shift 2
      ;;
    --distribution-plan)
      distribution_plan_path="${2:-}"
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

if [[ -z "$risk_response_plan_path" ]]; then
  echo "Missing required option: --risk-response-plan" >&2
  usage >&2
  exit 1
fi

if [[ -z "$execution_scorecard_path" ]]; then
  echo "Missing required option: --execution-scorecard" >&2
  usage >&2
  exit 1
fi

for required_path in "$risk_response_plan_path" "$execution_scorecard_path"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Required source file not found: $required_path" >&2
    exit 1
  fi
done

for optional_path in "$execution_sprint_path" "$distribution_plan_path" "$reply_pack_path"; do
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

extract_week_from_risk_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Risk Response Plan - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Risk Response Plan - "}"
}

extract_week_from_scorecard_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Execution Scorecard - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Execution Scorecard - "}"
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

extract_number() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true)"
  echo "$number"
}

extract_priority_row() {
  local source_path="$1"
  local row_index="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v heading="## Priority Risk Queue" -v target="$row_index" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Priority" || first ~ /^---/) next
      count++
      if (count == target) {
        printf "%s\t%s\t%s\t%s\t%s\n", clean($2), clean($3), clean($4), clean($5), clean($6)
        exit
      }
    }
  ' "$source_path"
}

extract_risk_flags() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    return
  fi

  awk '
    $0 == "## Risk Flags" { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^- / {
      line = $0
      sub(/^- /, "", line)
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (line != "") print line
    }
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

execution_route_for_risk() {
  local risk_text="$1"
  local lower_risk
  lower_risk="$(print -r -- "$risk_text" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_risk" == *"distribution"* || "$lower_risk" == *"checklist"* || "$lower_risk" == *"window"* ]]; then
    echo "Distribution plan Day 0-2 checklist + publish-window correction"
  elif [[ "$lower_risk" == *"reply"* || "$lower_risk" == *"objection"* || "$lower_risk" == *"comment"* ]]; then
    echo "Reply-pack cycle + objection-to-docs loop"
  elif [[ "$lower_risk" == *"day 0"* || "$lower_risk" == *"ship"* || "$lower_risk" == *"mission"* ]]; then
    echo "Execution sprint Day 0 mission board + owner checkpoint"
  elif [[ "$lower_risk" == *"momentum"* || "$lower_risk" == *"top bet"* || "$lower_risk" == *"priority"* ]]; then
    echo "Momentum brief + opportunity radar top-bet re-lock"
  else
    echo "Execution sprint owner sync + risk-response mitigation"
  fi
}

escalation_owner_for_route() {
  local route="$1"
  local owner="$2"
  local lower_route
  lower_route="$(print -r -- "$route" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_route" == *"distribution"* ]]; then
    echo "Founder growth lead + distribution lead"
  elif [[ "$lower_route" == *"reply"* || "$lower_route" == *"objection"* ]]; then
    echo "Founder growth lead + community lead"
  elif [[ "$lower_route" == *"mission"* || "$lower_route" == *"day 0"* ]]; then
    echo "Founder growth lead + launch lead"
  else
    echo "Founder growth lead + $(sanitize_inline "$owner")"
  fi
}

escalation_trigger_for_priority() {
  local priority="$1"
  case "$priority" in
    P1) echo "No visible progress update inside 2 hours." ;;
    P2) echo "No visible progress update inside 8 hours." ;;
    *) echo "No visible progress update inside 24 hours." ;;
  esac
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_risk_heading "$risk_response_plan_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_scorecard_heading "$execution_scorecard_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-escalation-queue.md"
fi

risk_response_heading="$(extract_heading "$risk_response_plan_path")"
execution_scorecard_heading="$(extract_heading "$execution_scorecard_path")"
execution_sprint_heading="$(extract_heading "$execution_sprint_path")"
distribution_heading="$(extract_heading "$distribution_plan_path")"
reply_heading="$(extract_heading "$reply_pack_path")"

top_bet_line="$(extract_prefixed_value "$risk_response_plan_path" "- Top bet: ")"
suggested_owner_line="$(extract_prefixed_value "$risk_response_plan_path" "- Suggested owner: ")"
day0_ship_line="$(extract_prefixed_value "$risk_response_plan_path" "- Day 0 ship item: ")"
guardrail_line="$(extract_prefixed_value "$risk_response_plan_path" "- Guardrail: ")"
response_urgency_line="$(extract_prefixed_value "$risk_response_plan_path" "- Response urgency score: ")"
response_mode_line="$(extract_prefixed_value "$risk_response_plan_path" "- Response mode: ")"
risk_count_line="$(extract_prefixed_value "$risk_response_plan_path" "- Risk flags detected: ")"
narrative_route_winner_line="$(extract_prefixed_value "$risk_response_plan_path" "- Narrative route winner: ")"
narrative_route_trend_line="$(extract_prefixed_value "$risk_response_plan_path" "- Narrative route trend: ")"
narrative_fame_velocity_line="$(extract_prefixed_value "$risk_response_plan_path" "- Narrative fame velocity score: ")"
narrative_ranked_opportunity_line="$(extract_prefixed_value "$risk_response_plan_path" "- Narrative-ranked opportunity: ")"
execution_mode_line="$(extract_prefixed_value "$risk_response_plan_path" "- Execution mode: ")"
route_alignment_signal_line="$(extract_prefixed_value "$risk_response_plan_path" "- Route alignment signal context: ")"
route_checks_line="$(extract_prefixed_value "$risk_response_plan_path" "- Route checks context: ")"
route_contribution_line="$(extract_prefixed_value "$risk_response_plan_path" "- Route contribution context: ")"
route_penalty_line="$(extract_prefixed_value "$risk_response_plan_path" "- Route alignment penalty applied: ")"
route_guardrail_line="$(extract_prefixed_value "$risk_response_plan_path" "- Route-specific guardrail: ")"
route_response_mode_line="$(extract_prefixed_value "$risk_response_plan_path" "- Route response mode: ")"
expected_route_opportunity_line="$(extract_prefixed_value "$risk_response_plan_path" "- Expected route opportunity: ")"
expected_execution_mode_line="$(extract_prefixed_value "$risk_response_plan_path" "- Expected execution mode: ")"

execution_readiness_line="$(extract_prefixed_value "$execution_scorecard_path" "- Score: ")"
execution_tier_line="$(extract_prefixed_value "$execution_scorecard_path" "- Tier: ")"
priority_context_line="$(extract_prefixed_value "$execution_scorecard_path" "- Top-bet priority context: ")"
momentum_context_line="$(extract_prefixed_value "$execution_scorecard_path" "- Momentum readiness context: ")"

if [[ -z "$top_bet_line" ]]; then
  top_bet_line="$(extract_prefixed_value "$execution_scorecard_path" "- Top bet: ")"
fi
if [[ -z "$suggested_owner_line" ]]; then
  suggested_owner_line="$(extract_prefixed_value "$execution_scorecard_path" "- Suggested owner: ")"
fi
if [[ -z "$day0_ship_line" ]]; then
  day0_ship_line="$(extract_prefixed_value "$execution_scorecard_path" "- Day 0 ship item: ")"
fi
if [[ -z "$guardrail_line" ]]; then
  guardrail_line="$(extract_prefixed_value "$execution_scorecard_path" "- Guardrail: ")"
fi
if [[ -z "$narrative_route_winner_line" ]]; then
  narrative_route_winner_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative route winner: ")"
fi
if [[ -z "$narrative_route_trend_line" ]]; then
  narrative_route_trend_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative route trend: ")"
fi
if [[ -z "$narrative_fame_velocity_line" ]]; then
  narrative_fame_velocity_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative fame velocity score: ")"
fi
if [[ -z "$narrative_ranked_opportunity_line" ]]; then
  narrative_ranked_opportunity_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative-ranked opportunity: ")"
fi
if [[ -z "$execution_mode_line" ]]; then
  execution_mode_line="$(extract_prefixed_value "$execution_scorecard_path" "- Execution mode: ")"
fi
if [[ -z "$route_alignment_signal_line" ]]; then
  route_alignment_signal_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route alignment signal: ")"
fi
if [[ -z "$route_checks_line" ]]; then
  route_checks_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route checks passed: ")"
fi
if [[ -z "$route_contribution_line" ]]; then
  route_contribution_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route contribution: ")"
fi
if [[ -z "$route_guardrail_line" ]]; then
  route_guardrail_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route-specific guardrail: ")"
fi
if [[ -z "$expected_route_opportunity_line" ]]; then
  expected_route_opportunity_line="$(extract_prefixed_value "$execution_scorecard_path" "- Expected route opportunity: ")"
fi
if [[ -z "$expected_execution_mode_line" ]]; then
  expected_execution_mode_line="$(extract_prefixed_value "$execution_scorecard_path" "- Expected execution mode: ")"
fi

if [[ -z "$top_bet_line" ]]; then
  top_bet_line="Narrative Compounding Loop"
fi
if [[ -z "$suggested_owner_line" ]]; then
  suggested_owner_line="Founder growth lead"
fi
if [[ -z "$day0_ship_line" ]]; then
  day0_ship_line="Ship one founder proof artifact in the next publish window."
fi
if [[ -z "$guardrail_line" ]]; then
  guardrail_line="Keep one proof-first narrative across primary and backup channels."
fi

execution_readiness_value="$(extract_number "$execution_readiness_line")"
if [[ -z "$execution_readiness_value" ]]; then
  execution_readiness_value=52
fi

response_urgency_value="$(extract_number "$response_urgency_line")"
if [[ -z "$response_urgency_value" ]]; then
  response_urgency_value="$(awk -v readiness="$execution_readiness_value" 'BEGIN {
    urgency = 100 - (readiness + 0)
    if (urgency < 0) urgency = 0
    if (urgency > 100) urgency = 100
    printf "%.0f", urgency
  }')"
fi

if [[ -z "$execution_tier_line" ]]; then
  execution_tier_line="Needs Alignment"
fi
if [[ -z "$response_mode_line" ]]; then
  response_mode_line="Monitor"
fi
if [[ -z "$priority_context_line" ]]; then
  priority_context_line="n/a"
fi
if [[ -z "$momentum_context_line" ]]; then
  momentum_context_line="n/a"
fi
if [[ -z "$narrative_route_winner_line" ]]; then
  narrative_route_winner_line="n/a"
fi
if [[ -z "$narrative_route_trend_line" ]]; then
  narrative_route_trend_line="n/a"
fi
if [[ -z "$narrative_fame_velocity_line" ]]; then
  narrative_fame_velocity_line="n/a"
fi
if [[ -z "$narrative_ranked_opportunity_line" ]]; then
  narrative_ranked_opportunity_line="$top_bet_line"
fi
if [[ -z "$execution_mode_line" ]]; then
  execution_mode_line="General narrative momentum mode"
fi
if [[ -z "$route_alignment_signal_line" ]]; then
  route_alignment_signal_line="Missing"
fi
if [[ -z "$route_checks_line" ]]; then
  route_checks_line="n/a"
fi
if [[ -z "$route_contribution_line" ]]; then
  route_contribution_line="0/2"
fi
if [[ -z "$route_penalty_line" ]]; then
  route_penalty_line="0"
fi
if [[ -z "$route_response_mode_line" ]]; then
  route_response_mode_line="Route Review"
fi
if [[ -z "$expected_route_opportunity_line" ]]; then
  expected_route_opportunity_line="$narrative_ranked_opportunity_line"
fi
if [[ -z "$expected_execution_mode_line" ]]; then
  expected_execution_mode_line="$execution_mode_line"
fi
if [[ -z "$route_guardrail_line" ]]; then
  route_guardrail_line="$guardrail_line"
fi

narrative_ranked_opportunity_line="${narrative_ranked_opportunity_line%%\(*}"
narrative_ranked_opportunity_line="$(trim_value "$narrative_ranked_opportunity_line")"
expected_route_opportunity_line="${expected_route_opportunity_line%%\(*}"
expected_route_opportunity_line="$(trim_value "$expected_route_opportunity_line")"

route_alignment_signal_normalized="$(sanitize_inline "$route_alignment_signal_line")"
route_checks_normalized="$(sanitize_inline "$route_checks_line")"
route_contribution_normalized="$(sanitize_inline "$route_contribution_line")"
route_penalty_value="$(extract_number "$route_penalty_line")"
if [[ -z "$route_penalty_value" ]]; then
  route_penalty_value=0
fi

route_queue_boost=0
route_lane_status="Stable"
route_lane_owner="Founder narrative owner"
route_lane_deadline="24h"
route_lane_action="Keep route winner and execution mode stable while maintaining proof quality."
route_lane_trigger="Escalate if route signal drops below Partial on the next scorecard refresh."

case "${route_alignment_signal_normalized:l}" in
  aligned*)
    route_queue_boost=0
    route_lane_status="Stable"
    route_lane_owner="Founder narrative owner"
    route_lane_deadline="24h"
    route_lane_action="Maintain route lock and keep narrative-ranked opportunity as the primary execution lane."
    route_lane_trigger="Escalate if route checks fall below 2/3."
    ;;
  partial*)
    route_queue_boost=6
    route_lane_status="Watch"
    route_lane_owner="Founder narrative owner + growth lead"
    route_lane_deadline="8h"
    route_lane_action="Re-lock winner, ranked opportunity, and execution mode before the next public touchpoint."
    route_lane_trigger="Escalate if Partial status persists after one route-correction cycle."
    ;;
  drifting*)
    route_queue_boost=12
    route_lane_status="Critical"
    route_lane_owner="Founder growth lead + narrative lead"
    route_lane_deadline="4h"
    route_lane_action="Pause non-critical experimentation and force immediate route winner + mode realignment."
    route_lane_trigger="Escalate immediately if Drifting status remains after 4 hours."
    ;;
  "fallback active"*)
    route_queue_boost=4
    route_lane_status="Signal Capture"
    route_lane_owner="Founder narrative owner"
    route_lane_deadline="12h"
    route_lane_action="Capture new route signals from live replies and replace fallback defaults."
    route_lane_trigger="Escalate if fallback mode remains active on the next rerun."
    ;;
  missing*|n/a|"")
    route_queue_boost=9
    route_lane_status="Signal Missing"
    route_lane_owner="Founder growth lead + narrative owner"
    route_lane_deadline="6h"
    route_lane_action="Capture route winner/trend/fame velocity before the next launch window."
    route_lane_trigger="Escalate if route signal is still missing after 6 hours."
    ;;
  *)
    route_queue_boost=5
    route_lane_status="Review"
    route_lane_owner="Founder narrative owner"
    route_lane_deadline="12h"
    route_lane_action="Run route-alignment review and confirm mode mapping in owner sync."
    route_lane_trigger="Escalate if unknown route state persists after one update cycle."
    ;;
esac

if (( route_queue_boost < route_penalty_value )); then
  route_queue_boost="$route_penalty_value"
fi

risk_flags=()
while IFS= read -r risk_flag || [[ -n "$risk_flag" ]]; do
  [[ -z "$risk_flag" ]] && continue
  risk_flags+=("$(sanitize_inline "$risk_flag")")
done < <(extract_risk_flags "$execution_scorecard_path")

risk_count="$(extract_number "$risk_count_line")"
if [[ -z "$risk_count" ]]; then
  risk_count="${#risk_flags[@]}"
fi
if [[ -z "$risk_count" || "$risk_count" == "0" ]]; then
  risk_count=1
fi

p1_row="$(extract_priority_row "$risk_response_plan_path" 1)"
p2_row="$(extract_priority_row "$risk_response_plan_path" 2)"

p1_priority=""
p1_risk=""
p1_owner=""
p1_deadline=""
p1_success_check=""

p2_priority=""
p2_risk=""
p2_owner=""
p2_deadline=""
p2_success_check=""

if [[ -n "$p1_row" ]]; then
  IFS=$'\t' read -r p1_priority p1_risk p1_owner p1_deadline p1_success_check <<< "$p1_row"
fi

if [[ -n "$p2_row" ]]; then
  IFS=$'\t' read -r p2_priority p2_risk p2_owner p2_deadline p2_success_check <<< "$p2_row"
fi

if [[ -z "$p1_priority" ]]; then
  p1_priority="P1"
fi
if [[ -z "$p1_risk" ]]; then
  p1_risk="${risk_flags[1]:-Highest-priority risk was not explicitly listed; assign one owner and mitigation immediately.}"
fi
if [[ -z "$p1_owner" ]]; then
  p1_owner="$suggested_owner_line"
fi
if [[ -z "$p1_deadline" ]]; then
  p1_deadline="0-6h"
fi
if [[ -z "$p1_success_check" ]]; then
  p1_success_check="Owner logs one completed mitigation action with timestamp."
fi

if [[ -z "$p2_priority" ]]; then
  p2_priority="P2"
fi
if [[ -z "$p2_risk" ]]; then
  p2_risk="${risk_flags[2]:-Second-priority risk was not explicitly listed; monitor the next-most-fragile signal.}"
fi
if [[ -z "$p2_owner" ]]; then
  p2_owner="$suggested_owner_line"
fi
if [[ -z "$p2_deadline" ]]; then
  p2_deadline="6-24h"
fi
if [[ -z "$p2_success_check" ]]; then
  p2_success_check="Owner ships one preventative action and shares evidence."
fi

p1_route="$(execution_route_for_risk "$p1_risk")"
p2_route="$(execution_route_for_risk "$p2_risk")"
p1_escalate_to="$(escalation_owner_for_route "$p1_route" "$p1_owner")"
p2_escalate_to="$(escalation_owner_for_route "$p2_route" "$p2_owner")"
p1_trigger="$(escalation_trigger_for_priority "$p1_priority")"
p2_trigger="$(escalation_trigger_for_priority "$p2_priority")"

distribution_checklist_count="$(count_checklist_lines "$distribution_plan_path" "## Execution Checklist")"
reply_template_count="$(count_reply_templates "$reply_pack_path")"

queue_pressure_score="$(awk -v urgency="$response_urgency_value" -v readiness="$execution_readiness_value" -v risk_count="$risk_count" -v route_boost="$route_queue_boost" 'BEGIN {
  u = urgency + 0
  r = readiness + 0
  c = risk_count + 0
  b = route_boost + 0
  score = (u * 0.60) + ((100 - r) * 0.20) + (c * 7) + b
  if (score < 0) score = 0
  if (score > 100) score = 100
  printf "%.0f", score
}')"

queue_mode="Monitor-and-Route"
if (( queue_pressure_score >= 70 )); then
  queue_mode="Escalation-Live"
elif (( queue_pressure_score >= 45 )); then
  queue_mode="Owner-Lock"
fi
if [[ "$route_lane_status" == "Critical" && "$queue_mode" != "Escalation-Live" ]]; then
  queue_mode="Escalation-Live"
elif [[ "$route_lane_status" == "Watch" && "$queue_mode" == "Monitor-and-Route" ]]; then
  queue_mode="Owner-Lock"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<!-- founder-fame-escalation-queue -->

# Founder Fame Escalation Queue - $week_label

Generated: $generated_on
Product: $product_name
Source risk response plan: $risk_response_plan_path
Source execution scorecard: $execution_scorecard_path
Source execution sprint: ${execution_sprint_path:-n/a}
Source distribution plan: ${distribution_plan_path:-n/a}
Source reply pack: ${reply_pack_path:-n/a}

## Snapshot

- Risk response plan: $risk_response_heading
- Execution scorecard: $execution_scorecard_heading
- Execution sprint: $execution_sprint_heading
- Distribution plan: $distribution_heading
- Reply pack: $reply_heading
- Top bet: $(sanitize_inline "$top_bet_line")
- Suggested owner: $(sanitize_inline "$suggested_owner_line")
- Day 0 ship item: $(sanitize_inline "$day0_ship_line")
- Guardrail: $(sanitize_inline "$guardrail_line")
- Narrative route winner: $(sanitize_inline "$narrative_route_winner_line")
- Narrative route trend: $(sanitize_inline "$narrative_route_trend_line")
- Narrative fame velocity score: $(sanitize_inline "$narrative_fame_velocity_line")
- Narrative-ranked opportunity: $(sanitize_inline "$narrative_ranked_opportunity_line")
- Execution mode: $(sanitize_inline "$execution_mode_line")

## Escalation Queue Signal

- Execution readiness context: ${execution_readiness_value}/100 ($(sanitize_inline "$execution_tier_line"))
- Response urgency context: ${response_urgency_value}/100 ($(sanitize_inline "$response_mode_line"))
- Queue pressure score: ${queue_pressure_score}/100
- Queue mode: $queue_mode
- Risk flags routed into queue: ${risk_count}
- Top-bet priority context: $(sanitize_inline "$priority_context_line")
- Momentum readiness context: $(sanitize_inline "$momentum_context_line")
- Distribution checklist coverage context: ${distribution_checklist_count} tasks
- Reply template coverage context: ${reply_template_count} templates
- Route alignment signal context: ${route_alignment_signal_normalized}
- Route checks context: ${route_checks_normalized}
- Route contribution context: ${route_contribution_normalized}
- Route response mode: $(sanitize_inline "$route_response_mode_line")
- Route queue boost applied: ${route_queue_boost}

## Narrative Route Escalation Lane

- Route lane status: ${route_lane_status}
- Route lane owner: $(sanitize_inline "$route_lane_owner")
- Route lane deadline: ${route_lane_deadline}
- Route lane action: $(sanitize_inline "$route_lane_action")
- Expected route opportunity: $(sanitize_inline "$expected_route_opportunity_line")
- Expected execution mode: $(sanitize_inline "$expected_execution_mode_line")
- Route-specific guardrail: $(sanitize_inline "$route_guardrail_line")
- Route lane trigger: $(sanitize_inline "$route_lane_trigger")

## Immediate Escalation Queue

| Priority | Risk | Routed owner | Execution route | Deadline window | Escalate to | Success check |
| --- | --- | --- | --- | --- | --- | --- |
| $(sanitize_inline "$p1_priority") | $(sanitize_inline "$p1_risk") | $(sanitize_inline "$p1_owner") | $(sanitize_inline "$p1_route") | $(sanitize_inline "$p1_deadline") | $(sanitize_inline "$p1_escalate_to") | $(sanitize_inline "$p1_success_check") |
| $(sanitize_inline "$p2_priority") | $(sanitize_inline "$p2_risk") | $(sanitize_inline "$p2_owner") | $(sanitize_inline "$p2_route") | $(sanitize_inline "$p2_deadline") | $(sanitize_inline "$p2_escalate_to") | $(sanitize_inline "$p2_success_check") |

## Owner Routing Notes

- $(sanitize_inline "$p1_priority") escalation trigger: $(sanitize_inline "$p1_trigger")
- $(sanitize_inline "$p2_priority") escalation trigger: $(sanitize_inline "$p2_trigger")
- Narrative route lane trigger: $(sanitize_inline "$route_lane_trigger")
- Keep one owner update thread in the Monday checklist issue with timestamps + artifact links.
- Re-route to the risk-response plan if either queue item reappears in the next scorecard run.

## First 24 Hours

1. **0-2h:** $(sanitize_inline "$p1_owner") confirms current blocker and starts $(sanitize_inline "$p1_route").
2. **2-8h:** $(sanitize_inline "$p2_owner") executes $(sanitize_inline "$p2_route") and posts one evidence update.
3. **8-16h:** Verify Day 0 ship item completion for \`$(sanitize_inline "$top_bet_line")\` and close one queue row.
4. **16-24h:** Re-score execution readiness, then keep, downgrade, or escalate each queue row with rationale.

## Escalation Conditions

- Escalate immediately when queue pressure score stays \`>=70\` after one owner update cycle.
- Escalate when $(sanitize_inline "$p1_priority") has no evidence update inside its trigger window.
- Escalate when Day 0 ship item slips beyond \`$p1_deadline\`.
- Escalate when reply/distribution coverage remains unchanged after one full execution pass.
- Escalate when route lane status is \`Critical\` and no route-lock evidence is posted by \`$route_lane_deadline\`.

## Share Block

\`\`\`text
Founder fame escalation queue ($week_label)
Queue mode: ${queue_mode}
Pressure: ${queue_pressure_score}/100
Readiness context: ${execution_readiness_value}/100 (${execution_tier_line})
Urgency context: ${response_urgency_value}/100 (${response_mode_line})
Route signal: ${route_alignment_signal_normalized} (${route_checks_normalized})
Route lane: ${route_lane_status} (${route_lane_deadline})
Route mode: ${route_response_mode_line}
P1: ${p1_risk}
P1 owner: ${p1_owner}
P1 route: ${p1_route}
P2: ${p2_risk}
P2 owner: ${p2_owner}
Guardrail: ${guardrail_line}
Route guardrail: ${route_guardrail_line}
\`\`\`
EOF

echo "Generated founder fame escalation queue: $output_path"
