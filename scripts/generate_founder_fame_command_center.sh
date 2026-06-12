#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame command center from momentum, execution, and risk artifacts.

Usage:
  zsh scripts/generate_founder_fame_command_center.sh [options]

Required:
  --momentum-brief <path>         Founder fame momentum brief markdown
  --execution-scorecard <path>    Founder fame execution scorecard markdown
  --risk-response-plan <path>     Founder fame risk response plan markdown
  --escalation-queue <path>       Founder fame escalation queue markdown

Optional:
  --opportunity-radar <path>      Founder fame opportunity radar markdown
  --week <label>                  Week label (default: inferred from momentum heading, then execution heading, then current ISO week)
  --product <text>                Product name (default: Fluid Reader)
  --out <path>                    Output path (default: docs/campaigns/<week>-founder-fame-command-center.md)
  -h, --help                      Show help

Example:
  zsh scripts/generate_founder_fame_command_center.sh \
    --momentum-brief docs/campaigns/2026-W24-founder-fame-momentum-brief.md \
    --execution-scorecard docs/campaigns/2026-W24-founder-fame-execution-scorecard.md \
    --risk-response-plan docs/campaigns/2026-W24-founder-fame-risk-response-plan.md \
    --escalation-queue docs/campaigns/2026-W24-founder-fame-escalation-queue.md \
    --opportunity-radar docs/campaigns/2026-W24-founder-fame-opportunity-radar.md \
    --out docs/campaigns/2026-W24-founder-fame-command-center.md
EOF
}

momentum_brief_path=""
execution_scorecard_path=""
risk_response_plan_path=""
escalation_queue_path=""
opportunity_radar_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --momentum-brief)
      momentum_brief_path="${2:-}"
      shift 2
      ;;
    --execution-scorecard)
      execution_scorecard_path="${2:-}"
      shift 2
      ;;
    --risk-response-plan)
      risk_response_plan_path="${2:-}"
      shift 2
      ;;
    --escalation-queue)
      escalation_queue_path="${2:-}"
      shift 2
      ;;
    --opportunity-radar)
      opportunity_radar_path="${2:-}"
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

for required_pair in \
  "momentum-brief:$momentum_brief_path" \
  "execution-scorecard:$execution_scorecard_path" \
  "risk-response-plan:$risk_response_plan_path" \
  "escalation-queue:$escalation_queue_path"; do
  required_name="${required_pair%%:*}"
  required_value="${required_pair#*:}"
  if [[ -z "$required_value" ]]; then
    echo "Missing required option: --${required_name}" >&2
    usage >&2
    exit 1
  fi
  if [[ ! -f "$required_value" ]]; then
    echo "Required source file not found: $required_value" >&2
    exit 1
  fi
done

if [[ -n "$opportunity_radar_path" && ! -f "$opportunity_radar_path" ]]; then
  echo "Optional source file not found: $opportunity_radar_path" >&2
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

extract_week_from_heading_prefix() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  local heading
  heading="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"$prefix"}"
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

extract_table_column_value() {
  local source_path="$1"
  local section_heading="$2"
  local row_index="$3"
  local column_index="$4"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v heading="$section_heading" -v target="$row_index" -v column="$column_index" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Priority" || first == "Rank" || first == "Trigger" || first ~ /^---/) next
      count++
      if (count == target) {
        idx = column + 1
        value = clean($(idx))
        print value
        exit
      }
    }
  ' "$source_path"
}

default_if_blank() {
  local value="$1"
  local fallback="$2"
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$fallback"
  fi
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$momentum_brief_path" "# Founder Fame Momentum Brief - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$execution_scorecard_path" "# Founder Fame Execution Scorecard - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$risk_response_plan_path" "# Founder Fame Risk Response Plan - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-command-center.md"
fi

mkdir -p "$(dirname "$output_path")"

momentum_heading="$(extract_heading "$momentum_brief_path")"
execution_heading="$(extract_heading "$execution_scorecard_path")"
risk_heading="$(extract_heading "$risk_response_plan_path")"
queue_heading="$(extract_heading "$escalation_queue_path")"
opportunity_heading="$(extract_heading "$opportunity_radar_path")"

fame_readiness="$(extract_prefixed_value "$momentum_brief_path" "- Fame readiness score: ")"
weakest_signal="$(extract_prefixed_value "$momentum_brief_path" "- Weakest signal now: ")"
routing_recommendation="$(extract_prefixed_value "$momentum_brief_path" "- Routing recommendation: ")"
execution_readiness_score="$(extract_prefixed_value "$execution_scorecard_path" "- Score: ")"
execution_tier="$(extract_prefixed_value "$execution_scorecard_path" "- Tier: ")"
top_bet_priority_context="$(extract_prefixed_value "$execution_scorecard_path" "- Top-bet priority context: ")"
momentum_readiness_context="$(extract_prefixed_value "$execution_scorecard_path" "- Momentum readiness context: ")"
top_bet="$(extract_prefixed_value "$execution_scorecard_path" "- Top bet: ")"
suggested_owner="$(extract_prefixed_value "$execution_scorecard_path" "- Suggested owner: ")"
day_zero_ship_item="$(extract_prefixed_value "$execution_scorecard_path" "- Day 0 ship item: ")"
guardrail="$(extract_prefixed_value "$execution_scorecard_path" "- Guardrail: ")"
response_urgency_score="$(extract_prefixed_value "$risk_response_plan_path" "- Response urgency score: ")"
response_mode="$(extract_prefixed_value "$risk_response_plan_path" "- Response mode: ")"
primary_risk_call="$(extract_prefixed_value "$risk_response_plan_path" "- Primary risk call: ")"
queue_pressure_score="$(extract_prefixed_value "$escalation_queue_path" "- Queue pressure score: ")"
queue_mode="$(extract_prefixed_value "$escalation_queue_path" "- Queue mode: ")"
p1_trigger="$(extract_prefixed_value "$escalation_queue_path" "- P1 escalation trigger: ")"
p2_trigger="$(extract_prefixed_value "$escalation_queue_path" "- P2 escalation trigger: ")"
narrative_route_winner="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative fame velocity score: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$execution_scorecard_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$execution_scorecard_path" "- Route alignment signal: ")"
route_checks="$(extract_prefixed_value "$execution_scorecard_path" "- Route checks passed: ")"
route_contribution="$(extract_prefixed_value "$execution_scorecard_path" "- Route contribution: ")"
expected_route_opportunity="$(extract_prefixed_value "$execution_scorecard_path" "- Expected route opportunity: ")"
expected_execution_mode="$(extract_prefixed_value "$execution_scorecard_path" "- Expected execution mode: ")"
route_guardrail="$(extract_prefixed_value "$execution_scorecard_path" "- Route-specific guardrail: ")"
route_risk_tier="$(extract_prefixed_value "$risk_response_plan_path" "- Route risk tier: ")"
route_response_mode="$(extract_prefixed_value "$risk_response_plan_path" "- Route response mode: ")"
route_escalation_condition="$(extract_prefixed_value "$risk_response_plan_path" "- Route escalation condition: ")"
route_lane_status="$(extract_prefixed_value "$escalation_queue_path" "- Route lane status: ")"
route_lane_owner="$(extract_prefixed_value "$escalation_queue_path" "- Route lane owner: ")"
route_lane_deadline="$(extract_prefixed_value "$escalation_queue_path" "- Route lane deadline: ")"
route_lane_action="$(extract_prefixed_value "$escalation_queue_path" "- Route lane action: ")"
route_lane_trigger="$(extract_prefixed_value "$escalation_queue_path" "- Route lane trigger: ")"

if [[ -z "$routing_recommendation" ]]; then
  routing_recommendation="$(extract_prefixed_value "$opportunity_radar_path" "- Routing recommendation: ")"
fi
if [[ -z "$top_bet" ]]; then
  top_bet="$(extract_prefixed_value "$opportunity_radar_path" "- Bet: ")"
fi
if [[ -z "$guardrail" ]]; then
  guardrail="$(extract_prefixed_value "$risk_response_plan_path" "- Guardrail: ")"
fi
if [[ -z "$primary_risk_call" ]]; then
  primary_risk_call="$(extract_prefixed_value "$momentum_brief_path" "- Primary risk call: ")"
fi
if [[ -z "$narrative_ranked_opportunity" ]]; then
  narrative_ranked_opportunity="$(extract_prefixed_value "$opportunity_radar_path" "- Narrative-ranked opportunity: ")"
fi
if [[ -z "$narrative_route_winner" ]]; then
  narrative_route_winner="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative route winner: ")"
fi
if [[ -z "$narrative_route_trend" ]]; then
  narrative_route_trend="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative route trend: ")"
fi
if [[ -z "$narrative_fame_velocity" ]]; then
  narrative_fame_velocity="$(extract_prefixed_value "$opportunity_radar_path" "- Founder narrative fame velocity score: ")"
fi

p1_priority="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 1)"
p1_risk="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 2)"
p1_owner="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 3)"
p1_route="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 4)"
p1_deadline="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 5)"
p1_escalate_to="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 6)"
p1_success_check="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 1 7)"
p2_priority="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 1)"
p2_risk="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 2)"
p2_owner="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 3)"
p2_route="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 4)"
p2_deadline="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 5)"
p2_escalate_to="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 6)"
p2_success_check="$(extract_table_column_value "$escalation_queue_path" "## Immediate Escalation Queue" 2 7)"

fame_readiness="$(default_if_blank "$fame_readiness" "n/a")"
weakest_signal="$(default_if_blank "$weakest_signal" "n/a")"
routing_recommendation="$(default_if_blank "$routing_recommendation" "Keep one proof narrative until execution coverage improves.")"
execution_readiness_score="$(default_if_blank "$execution_readiness_score" "n/a")"
execution_tier="$(default_if_blank "$execution_tier" "n/a")"
top_bet_priority_context="$(default_if_blank "$top_bet_priority_context" "n/a")"
momentum_readiness_context="$(default_if_blank "$momentum_readiness_context" "n/a")"
top_bet="$(default_if_blank "$top_bet" "n/a")"
suggested_owner="$(default_if_blank "$suggested_owner" "n/a")"
day_zero_ship_item="$(default_if_blank "$day_zero_ship_item" "n/a")"
guardrail="$(default_if_blank "$guardrail" "n/a")"
response_urgency_score="$(default_if_blank "$response_urgency_score" "n/a")"
response_mode="$(default_if_blank "$response_mode" "n/a")"
primary_risk_call="$(default_if_blank "$primary_risk_call" "n/a")"
queue_pressure_score="$(default_if_blank "$queue_pressure_score" "n/a")"
queue_mode="$(default_if_blank "$queue_mode" "n/a")"
p1_trigger="$(default_if_blank "$p1_trigger" "No P1 owner update in trigger window.")"
p2_trigger="$(default_if_blank "$p2_trigger" "No P2 owner update in trigger window.")"
narrative_route_winner="$(default_if_blank "$narrative_route_winner" "n/a")"
narrative_route_trend="$(default_if_blank "$narrative_route_trend" "n/a")"
narrative_fame_velocity="$(default_if_blank "$narrative_fame_velocity" "n/a")"
narrative_ranked_opportunity="$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")"
execution_mode="$(default_if_blank "$execution_mode" "General narrative momentum mode")"
route_alignment_signal="$(default_if_blank "$route_alignment_signal" "Missing")"
route_checks="$(default_if_blank "$route_checks" "n/a")"
route_contribution="$(default_if_blank "$route_contribution" "0/2")"
expected_route_opportunity="$(default_if_blank "$expected_route_opportunity" "$narrative_ranked_opportunity")"
expected_execution_mode="$(default_if_blank "$expected_execution_mode" "$execution_mode")"
route_guardrail="$(default_if_blank "$route_guardrail" "$guardrail")"
route_risk_tier="$(default_if_blank "$route_risk_tier" "n/a")"
route_response_mode="$(default_if_blank "$route_response_mode" "Route Review")"
route_escalation_condition="$(default_if_blank "$route_escalation_condition" "Escalate if route alignment degrades on the next scorecard refresh.")"
route_lane_status="$(default_if_blank "$route_lane_status" "n/a")"
route_lane_owner="$(default_if_blank "$route_lane_owner" "Founder narrative owner")"
route_lane_deadline="$(default_if_blank "$route_lane_deadline" "n/a")"
route_lane_action="$(default_if_blank "$route_lane_action" "Reconfirm route owner/actions in the next standup.")"
route_lane_trigger="$(default_if_blank "$route_lane_trigger" "Escalate when route-lane evidence is missing inside the next update window.")"
p1_priority="$(default_if_blank "$p1_priority" "P1")"
p1_risk="$(default_if_blank "$p1_risk" "n/a")"
p1_owner="$(default_if_blank "$p1_owner" "n/a")"
p1_route="$(default_if_blank "$p1_route" "n/a")"
p1_deadline="$(default_if_blank "$p1_deadline" "n/a")"
p1_escalate_to="$(default_if_blank "$p1_escalate_to" "n/a")"
p1_success_check="$(default_if_blank "$p1_success_check" "n/a")"
p2_priority="$(default_if_blank "$p2_priority" "P2")"
p2_risk="$(default_if_blank "$p2_risk" "n/a")"
p2_owner="$(default_if_blank "$p2_owner" "n/a")"
p2_route="$(default_if_blank "$p2_route" "n/a")"
p2_deadline="$(default_if_blank "$p2_deadline" "n/a")"
p2_escalate_to="$(default_if_blank "$p2_escalate_to" "n/a")"
p2_success_check="$(default_if_blank "$p2_success_check" "n/a")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-command-center -->

# Founder Fame Command Center - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source momentum brief: ${momentum_brief_path}
Source execution scorecard: ${execution_scorecard_path}
Source risk response plan: ${risk_response_plan_path}
Source escalation queue: ${escalation_queue_path}
Source opportunity radar: ${opportunity_radar_path:-n/a}

## Snapshot

- Momentum brief: ${momentum_heading}
- Execution scorecard: ${execution_heading}
- Risk response plan: ${risk_heading}
- Escalation queue: ${queue_heading}
- Opportunity radar: ${opportunity_heading}
- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness_score} (${execution_tier})
- Queue pressure: ${queue_pressure_score} (${queue_mode})
- Response urgency: ${response_urgency_score} (${response_mode})
- Top-bet priority context: ${top_bet_priority_context}
- Momentum readiness context: ${momentum_readiness_context}
- Top bet: ${top_bet}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment signal: ${route_alignment_signal}
- Weakest signal: ${weakest_signal}
- Primary risk call: ${primary_risk_call}
- Routing recommendation: ${routing_recommendation}

## Narrative Route Control Tower

- Route alignment: ${route_alignment_signal} (${route_checks}, contribution ${route_contribution})
- Active route mode: ${route_response_mode}
- Route lane status: ${route_lane_status}
- Route lane owner/deadline: ${route_lane_owner} (${route_lane_deadline})
- Route lane action: ${route_lane_action}
- Route winner vs expected opportunity: ${narrative_route_winner} -> ${narrative_ranked_opportunity} (expected: ${expected_route_opportunity})
- Execution mode vs expected mode: ${execution_mode} (expected: ${expected_execution_mode})
- Route risk tier: ${route_risk_tier}
- Route guardrail: ${route_guardrail}
- Route escalation condition: ${route_escalation_condition}

## Next 24 Hours

1. **Resolve ${p1_priority}:** ${p1_risk}
   - Owner: ${p1_owner}
   - Route: ${p1_route}
   - Deadline: ${p1_deadline}
   - Success check: ${p1_success_check}
2. **Advance top bet:** ${top_bet}
   - Suggested owner: ${suggested_owner}
   - Day 0 ship item: ${day_zero_ship_item}
3. **Lock route lane:** ${route_lane_action}
   - Owner: ${route_lane_owner}
   - Deadline: ${route_lane_deadline}
4. **Protect execution quality:** ${guardrail}
5. **Prep next queue row:** ${p2_priority} -> ${p2_risk}
   - Owner: ${p2_owner}
   - Route: ${p2_route}
   - Deadline: ${p2_deadline}
   - Success check: ${p2_success_check}

## Trigger Matrix

| Trigger | Decision | Action |
| --- | --- | --- |
| ${p1_trigger} | Escalate ${p1_priority} immediately | Notify ${p1_escalate_to} with owner update + artifact link. |
| ${p2_trigger} | Promote ${p2_priority} into active lane | Move ${p2_owner} update to top of the checklist queue. |
| ${route_lane_trigger} | Trigger route-lane escalation | Notify ${route_lane_owner} and switch to route correction mode. |
| Queue pressure remains ${queue_pressure_score} after one cycle | Tighten scope for 24h | Pause new experiments and close one blocker first. |
| Momentum readiness drifts from ${momentum_readiness_context} | Re-route channel effort | Focus one proof narrative before adding new distribution lanes. |

## Standup Share Block

\`\`\`text
Founder fame command center (${week_label})
Top bet: ${top_bet}
Execution readiness: ${execution_readiness_score} (${execution_tier})
Fame readiness: ${fame_readiness}
Queue pressure: ${queue_pressure_score} (${queue_mode})
Route signal: ${route_alignment_signal} (${route_checks})
Route lane: ${route_lane_status} (${route_lane_deadline})
Route mode: ${route_response_mode}
P1 owner/route: ${p1_owner} -> ${p1_route}
P1 success check: ${p1_success_check}
Primary risk: ${primary_risk_call}
Routing call: ${routing_recommendation}
Day 0 ship item: ${day_zero_ship_item}
Route guardrail: ${route_guardrail}
\`\`\`

## In-App Fast Loop

- Run "Fame -> Run Fame Next Move" once per update cycle to execute the highest-priority in-app action.
- Re-run immediately whenever pulse risk changes to High or Critical.
- Post the resulting artifact link and owner update into the same standup thread.

## Update Cadence

- [ ] T+2h: P1 owner posts first evidence update.
- [ ] T+6h: Top-bet owner confirms ship status and blocker state.
- [ ] T+12h: Re-score queue pressure and close or escalate one row.
- [ ] T+24h: Publish one proof recap and reset next-day priorities.
EOF

echo "Generated founder fame command center: $output_path"
