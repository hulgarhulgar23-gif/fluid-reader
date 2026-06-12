#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame risk response plan from execution-readiness artifacts.

Usage:
  zsh scripts/generate_founder_fame_risk_response_plan.sh [options]

Required:
  --execution-scorecard <path>     Founder fame execution scorecard markdown

Optional:
  --execution-sprint <path>        Founder fame execution sprint markdown
  --opportunity-radar <path>       Founder fame opportunity radar markdown
  --momentum-brief <path>          Founder fame momentum brief markdown
  --distribution-plan <path>       7-day distribution follow-up plan markdown
  --reply-pack <path>              First-24-hour reply pack markdown
  --week <label>                   Week label (default: inferred from execution scorecard heading, then current ISO week)
  --product <text>                 Product name (default: Fluid Reader)
  --out <path>                     Output path (default: docs/campaigns/<week>-founder-fame-risk-response-plan.md)
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_fame_risk_response_plan.sh \
    --execution-scorecard docs/campaigns/2026-W24-founder-fame-execution-scorecard.md \
    --execution-sprint docs/campaigns/2026-W24-founder-fame-execution-sprint.md \
    --opportunity-radar docs/campaigns/2026-W24-founder-fame-opportunity-radar.md \
    --momentum-brief docs/campaigns/2026-W24-founder-fame-momentum-brief.md \
    --distribution-plan docs/campaigns/2026-W24-distribution-plan.md \
    --reply-pack docs/campaigns/2026-W24-reply-pack.md \
    --out docs/campaigns/2026-W24-founder-fame-risk-response-plan.md
EOF
}

execution_scorecard_path=""
execution_sprint_path=""
opportunity_radar_path=""
momentum_brief_path=""
distribution_plan_path=""
reply_pack_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --execution-scorecard)
      execution_scorecard_path="${2:-}"
      shift 2
      ;;
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

if [[ -z "$execution_scorecard_path" ]]; then
  echo "Missing required option: --execution-scorecard" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$execution_scorecard_path" ]]; then
  echo "Execution scorecard file not found: $execution_scorecard_path" >&2
  exit 1
fi

for optional_path in "$execution_sprint_path" "$opportunity_radar_path" "$momentum_brief_path" "$distribution_plan_path" "$reply_pack_path"; do
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

risk_owner() {
  local risk_text="$1"
  local fallback_owner="$2"
  local lower_risk
  lower_risk="$(print -r -- "$risk_text" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_risk" == *"narrative route"* || "$lower_risk" == *"route alignment"* || "$lower_risk" == *"execution mode"* ]]; then
    echo "Founder narrative owner"
  elif [[ "$lower_risk" == *"reply"* ]]; then
    echo "Reply owner"
  elif [[ "$lower_risk" == *"distribution"* || "$lower_risk" == *"checklist"* || "$lower_risk" == *"window"* ]]; then
    echo "Distribution owner"
  elif [[ "$lower_risk" == *"mission"* || "$lower_risk" == *"day 0"* || "$lower_risk" == *"owner"* ]]; then
    echo "$(sanitize_inline "$fallback_owner")"
  elif [[ "$lower_risk" == *"momentum"* || "$lower_risk" == *"priority"* || "$lower_risk" == *"top bet"* ]]; then
    echo "Founder narrative owner"
  else
    echo "Founder ops owner"
  fi
}

risk_success_check() {
  local risk_text="$1"
  local lower_risk
  lower_risk="$(print -r -- "$risk_text" | tr '[:upper:]' '[:lower:]')"
  if [[ "$lower_risk" == *"narrative route"* || "$lower_risk" == *"route alignment"* || "$lower_risk" == *"execution mode"* ]]; then
    echo "Route winner, ranked opportunity, and execution mode are re-aligned in the refreshed scorecard."
  elif [[ "$lower_risk" == *"reply"* ]]; then
    echo "Reply cycle executed with one documented conversion insight."
  elif [[ "$lower_risk" == *"distribution"* || "$lower_risk" == *"checklist"* ]]; then
    echo "One blocked distribution checklist task is completed."
  elif [[ "$lower_risk" == *"mission"* || "$lower_risk" == *"day 0"* ]]; then
    echo "Day 0 ship item is posted and owner confirms timestamp."
  elif [[ "$lower_risk" == *"priority"* || "$lower_risk" == *"top bet"* ]]; then
    echo "Top bet is reaffirmed or explicitly replaced with rationale."
  else
    echo "Mitigation action is owner-assigned with a due timestamp."
  fi
}

risk_deadline_window() {
  local index="$1"
  case "$index" in
    1) echo "0-6h" ;;
    2) echo "6-24h" ;;
    3) echo "24-48h" ;;
    *) echo "48-72h" ;;
  esac
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_scorecard_heading "$execution_scorecard_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-risk-response-plan.md"
fi

scorecard_heading="$(extract_heading "$execution_scorecard_path")"
execution_heading="$(extract_heading "$execution_sprint_path")"
opportunity_heading="$(extract_heading "$opportunity_radar_path")"
momentum_heading="$(extract_heading "$momentum_brief_path")"
distribution_heading="$(extract_heading "$distribution_plan_path")"
reply_heading="$(extract_heading "$reply_pack_path")"

execution_readiness_line="$(extract_prefixed_value "$execution_scorecard_path" "- Score: ")"
execution_tier_line="$(extract_prefixed_value "$execution_scorecard_path" "- Tier: ")"
top_bet_line="$(extract_prefixed_value "$execution_scorecard_path" "- Top bet: ")"
owner_line="$(extract_prefixed_value "$execution_scorecard_path" "- Suggested owner: ")"
day0_ship_line="$(extract_prefixed_value "$execution_scorecard_path" "- Day 0 ship item: ")"
guardrail_line="$(extract_prefixed_value "$execution_scorecard_path" "- Guardrail: ")"
priority_line="$(extract_prefixed_value "$execution_scorecard_path" "- Top-bet priority context: ")"
momentum_line="$(extract_prefixed_value "$execution_scorecard_path" "- Momentum readiness context: ")"
narrative_route_winner_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative route winner: ")"
narrative_route_trend_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative route trend: ")"
narrative_fame_velocity_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative fame velocity score: ")"
narrative_ranked_opportunity_line="$(extract_prefixed_value "$execution_scorecard_path" "- Narrative-ranked opportunity: ")"
execution_mode_line="$(extract_prefixed_value "$execution_scorecard_path" "- Execution mode: ")"
route_alignment_signal_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route alignment signal: ")"
route_checks_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route checks passed: ")"
route_contribution_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route contribution: ")"
expected_route_opportunity_line="$(extract_prefixed_value "$execution_scorecard_path" "- Expected route opportunity: ")"
expected_execution_mode_line="$(extract_prefixed_value "$execution_scorecard_path" "- Expected execution mode: ")"
route_guardrail_line="$(extract_prefixed_value "$execution_scorecard_path" "- Route-specific guardrail: ")"

if [[ -z "$narrative_route_winner_line" ]]; then
  narrative_route_winner_line="$(extract_prefixed_value "$execution_sprint_path" "- Narrative route winner: ")"
fi
if [[ -z "$narrative_route_trend_line" ]]; then
  narrative_route_trend_line="$(extract_prefixed_value "$execution_sprint_path" "- Route trend: ")"
fi
if [[ -z "$narrative_fame_velocity_line" ]]; then
  narrative_fame_velocity_line="$(extract_prefixed_value "$execution_sprint_path" "- Fame velocity score: ")"
fi
if [[ -z "$narrative_ranked_opportunity_line" ]]; then
  narrative_ranked_opportunity_line="$(extract_prefixed_value "$execution_sprint_path" "- Ranked route opportunity: ")"
fi
if [[ -z "$narrative_ranked_opportunity_line" ]]; then
  narrative_ranked_opportunity_line="$(extract_prefixed_value "$opportunity_radar_path" "- Narrative-ranked opportunity: ")"
fi
if [[ -z "$execution_mode_line" ]]; then
  execution_mode_line="$(extract_prefixed_value "$execution_sprint_path" "- Execution mode: ")"
fi
if [[ -z "$route_guardrail_line" ]]; then
  route_guardrail_line="$(extract_prefixed_value "$execution_sprint_path" "- Route-specific guardrail: ")"
fi

execution_readiness_value="$(extract_number "$execution_readiness_line")"
if [[ -z "$execution_readiness_value" ]]; then
  execution_readiness_value=52
fi

if [[ -z "$execution_tier_line" ]]; then
  execution_tier_line="Needs Alignment"
fi

if [[ -z "$top_bet_line" ]]; then
  top_bet_line="Narrative Compounding Loop"
fi
if [[ -z "$owner_line" ]]; then
  owner_line="Founder growth lead"
fi
if [[ -z "$day0_ship_line" ]]; then
  day0_ship_line="Ship one founder narrative asset in the next publish window."
fi
if [[ -z "$guardrail_line" ]]; then
  guardrail_line="Preserve one clear top-bet narrative across all channels."
fi
if [[ -z "$priority_line" ]]; then
  priority_line="n/a"
fi
if [[ -z "$momentum_line" ]]; then
  momentum_line="n/a"
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
route_alignment_penalty=0
route_risk_tier="Low"
route_response_mode="Route Locked"
route_control_owner="Founder narrative owner"
route_primary_action="Keep current route winner and execution mode locked in daily check-ins."
route_escalation_condition="Escalate if route alignment signal drops below Partial in the next scorecard refresh."

case "${route_alignment_signal_normalized:l}" in
  aligned*)
    route_alignment_penalty=0
    route_risk_tier="Low"
    route_response_mode="Route Locked"
    route_primary_action="Keep the route winner stable and reinforce it with proof-backed execution."
    route_escalation_condition="Escalate if route checks fall below 2/3 on the next scorecard refresh."
    ;;
  partial*)
    route_alignment_penalty=6
    route_risk_tier="Medium"
    route_response_mode="Route Re-Lock"
    route_primary_action="Re-lock ranked opportunity and execution mode to the winner before the next public post."
    route_escalation_condition="Escalate if route alignment stays Partial after one correction cycle."
    ;;
  drifting*)
    route_alignment_penalty=12
    route_risk_tier="High"
    route_response_mode="Route Correction Surge"
    route_primary_action="Pause non-critical experiments and align winner, mode, and ranked opportunity immediately."
    route_escalation_condition="Escalate immediately if route alignment remains Drifting after 6 hours."
    ;;
  "fallback active"*)
    route_alignment_penalty=4
    route_risk_tier="Medium"
    route_response_mode="Route Signal Capture"
    route_primary_action="Capture fresh narrative-route signals and replace fallback mode in the next run."
    route_escalation_condition="Escalate if fallback mode remains active after one full scorecard cycle."
    ;;
  missing*|n/a|"")
    route_alignment_penalty=8
    route_risk_tier="High"
    route_response_mode="Route Signal Capture"
    route_primary_action="Capture route winner, trend, and execution mode before the next launch window."
    route_escalation_condition="Escalate if route signal stays missing after 24 hours."
    ;;
  *)
    route_alignment_penalty=5
    route_risk_tier="Medium"
    route_response_mode="Route Review"
    route_primary_action="Review route winner and execution-mode mapping in the next owner sync."
    route_escalation_condition="Escalate if unknown route state persists after one rerun."
    ;;
esac

risk_flags=()
while IFS= read -r risk_flag || [[ -n "$risk_flag" ]]; do
  [[ -z "$risk_flag" ]] && continue
  risk_flags+=("$(sanitize_inline "$risk_flag")")
done < <(extract_risk_flags "$execution_scorecard_path")

has_route_risk_flag=0
for risk_flag in "${risk_flags[@]}"; do
  if [[ "${risk_flag:l}" == *"narrative route"* || "${risk_flag:l}" == *"route alignment"* || "${risk_flag:l}" == *"execution mode"* ]]; then
    has_route_risk_flag=1
    break
  fi
done

if [[ "$route_alignment_signal_normalized" != "Aligned" && "$has_route_risk_flag" -eq 0 ]]; then
  risk_flags+=("Narrative route alignment is ${route_alignment_signal_normalized} (${route_checks_normalized}); re-lock winner, ranked opportunity, and execution mode.")
fi

if (( ${#risk_flags[@]} == 0 )); then
  risk_flags+=("No acute risk flags were listed in the scorecard. Keep response mode in monitoring state.")
fi

risk_count="${#risk_flags[@]}"
distribution_checklist_count="$(count_checklist_lines "$distribution_plan_path" "## Execution Checklist")"
reply_template_count="$(count_reply_templates "$reply_pack_path")"

response_urgency_score="$(awk -v readiness="$execution_readiness_value" -v risk_count="$risk_count" -v route_penalty="$route_alignment_penalty" 'BEGIN {
  r = readiness + 0
  c = risk_count + 0
  p = route_penalty + 0
  urgency = (100 - r) + (c * 6) + p
  if (urgency < 0) urgency = 0
  if (urgency > 100) urgency = 100
  printf "%.0f", urgency
}')"

response_mode="Monitor"
if (( response_urgency_score >= 70 )); then
  response_mode="Emergency Stabilization"
elif (( response_urgency_score >= 50 )); then
  response_mode="Rapid Hardening"
elif (( response_urgency_score >= 30 )); then
  response_mode="Focused Recovery"
fi

primary_risk="${risk_flags[1]}"
primary_owner="$(risk_owner "$primary_risk" "$owner_line")"
primary_success_check="$(risk_success_check "$primary_risk")"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"
cat > "$output_path" <<EOF
<!-- founder-fame-risk-response-plan -->

# Founder Fame Risk Response Plan - $week_label

Generated: $generated_on
Product: $product_name
Source execution scorecard: $execution_scorecard_path
Source execution sprint: ${execution_sprint_path:-n/a}
Source opportunity radar: ${opportunity_radar_path:-n/a}
Source momentum brief: ${momentum_brief_path:-n/a}
Source distribution plan: ${distribution_plan_path:-n/a}
Source reply pack: ${reply_pack_path:-n/a}

## Snapshot

- Execution scorecard: $scorecard_heading
- Execution sprint: $execution_heading
- Opportunity radar: $opportunity_heading
- Momentum brief: $momentum_heading
- Distribution plan: $distribution_heading
- Reply pack: $reply_heading
- Top bet: $(sanitize_inline "$top_bet_line")
- Suggested owner: $(sanitize_inline "$owner_line")
- Day 0 ship item: $(sanitize_inline "$day0_ship_line")
- Guardrail: $(sanitize_inline "$guardrail_line")
- Narrative route winner: $(sanitize_inline "$narrative_route_winner_line")
- Narrative route trend: $(sanitize_inline "$narrative_route_trend_line")
- Narrative fame velocity score: $(sanitize_inline "$narrative_fame_velocity_line")
- Narrative-ranked opportunity: $(sanitize_inline "$narrative_ranked_opportunity_line")
- Execution mode: $(sanitize_inline "$execution_mode_line")

## Risk Response Signal

- Execution readiness score context: ${execution_readiness_value}/100
- Execution readiness tier context: $(sanitize_inline "$execution_tier_line")
- Response urgency score: ${response_urgency_score}/100
- Response mode: $response_mode
- Risk flags detected: ${risk_count}
- Top-bet priority context: $(sanitize_inline "$priority_line")
- Momentum readiness context: $(sanitize_inline "$momentum_line")
- Distribution checklist coverage context: ${distribution_checklist_count} tasks
- Reply template coverage context: ${reply_template_count} templates
- Route alignment signal context: ${route_alignment_signal_normalized}
- Route checks context: ${route_checks_normalized}
- Route contribution context: ${route_contribution_normalized}
- Route alignment penalty applied: ${route_alignment_penalty}
- Route risk tier: ${route_risk_tier}

## Narrative Route Risk Controls

- Route response mode: ${route_response_mode}
- Route control owner: $(sanitize_inline "$route_control_owner")
- Expected route opportunity: $(sanitize_inline "$expected_route_opportunity_line")
- Expected execution mode: $(sanitize_inline "$expected_execution_mode_line")
- Route-specific guardrail: $(sanitize_inline "$route_guardrail_line")
- Immediate route action: $(sanitize_inline "$route_primary_action")
- Route escalation condition: $(sanitize_inline "$route_escalation_condition")

## Priority Risk Queue

| Priority | Risk | Owner | Deadline | Success Check |
| --- | --- | --- | --- | --- |
EOF

risk_index=1
for risk_flag in "${risk_flags[@]}"; do
  local_owner="$(risk_owner "$risk_flag" "$owner_line")"
  local_deadline="$(risk_deadline_window "$risk_index")"
  local_success_check="$(risk_success_check "$risk_flag")"
  echo "| P${risk_index} | $(sanitize_inline "$risk_flag") | $(sanitize_inline "$local_owner") | ${local_deadline} | $(sanitize_inline "$local_success_check") |" >> "$output_path"
  (( risk_index++ ))
  if (( risk_index > 4 )); then
    break
  fi
done

cat >> "$output_path" <<EOF

## 72-Hour Stabilization Plan

1. **0-6h triage:** $(sanitize_inline "$primary_owner") confirms current blocker context for \`$(sanitize_inline "$top_bet_line")\` and assigns one mitigation owner per active risk.
2. **6-24h execution:** Ship $(sanitize_inline "$day0_ship_line"), then close at least one blocked distribution or reply gap with evidence.
3. **24-48h validation:** Recheck conversion quality and response velocity; keep only mitigation steps that improve practical outcomes.
4. **48-72h lock-in:** Re-run the execution scorecard and promote the best-performing response pattern into next-week default operating rhythm.

## Mitigation Checkpoints

- [ ] Highest-priority risk has one accountable owner and due time.
- [ ] Day 0 ship item has a publish timestamp and link.
- [ ] One reply improvement loop is executed with a documented lesson.
- [ ] One distribution checklist blocker is removed.
- [ ] Execution scorecard is scheduled for re-run inside 72 hours.

## Escalation Conditions

- Escalate immediately if response urgency score remains \`>=70\` after the next scorecard refresh.
- Escalate if reply quality still lacks practical specificity after one full response cycle.
- Escalate if no owner confirms progress on P1 risk within 6 hours.
- Escalate if day-by-day mission execution slips for two consecutive checkpoints.

## Share Block

\`\`\`text
Founder fame risk response plan ($week_label)
Execution readiness context: ${execution_readiness_value}/100 (${execution_tier_line})
Response urgency: ${response_urgency_score}/100 (${response_mode})
Route signal: ${route_alignment_signal_normalized} (${route_checks_normalized}, penalty +${route_alignment_penalty})
Route mode: ${route_response_mode}
Top bet: $(sanitize_inline "$top_bet_line")
P1 risk: $(sanitize_inline "$primary_risk")
P1 owner: $(sanitize_inline "$primary_owner")
P1 success check: $(sanitize_inline "$primary_success_check")
Guardrail: $(sanitize_inline "$guardrail_line")
Route guardrail: $(sanitize_inline "$route_guardrail_line")
\`\`\`
EOF

echo "Generated founder fame risk response plan: $output_path"
