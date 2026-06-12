#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame velocity scoreboard from KPI and command-center signals.

Usage:
  zsh scripts/generate_founder_fame_velocity_scoreboard.sh [options]

Required:
  --kpi-snapshot <path>            Founder fame KPI snapshot markdown

Optional:
  --command-center <path>          Founder fame command center markdown
  --proof-loop-check <path>        Founder fame proof-loop verification markdown
  --week <label>                   Week label (default: inferred from KPI snapshot heading, then command center heading, then current ISO week)
  --product <text>                 Product name (default: Fluid Reader)
  --out <path>                     Output path (default: docs/campaigns/<week>-founder-fame-velocity-scoreboard.md)
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_fame_velocity_scoreboard.sh \
    --kpi-snapshot docs/campaigns/2026-W24-founder-fame-kpi-snapshot.md \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --proof-loop-check docs/campaigns/2026-W24-founder-fame-proof-loop-check.md \
    --out docs/campaigns/2026-W24-founder-fame-velocity-scoreboard.md
EOF
}

kpi_snapshot_path=""
command_center_path=""
proof_loop_check_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --kpi-snapshot)
      kpi_snapshot_path="${2:-}"
      shift 2
      ;;
    --command-center)
      command_center_path="${2:-}"
      shift 2
      ;;
    --proof-loop-check)
      proof_loop_check_path="${2:-}"
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

if [[ -z "$kpi_snapshot_path" ]]; then
  echo "Missing required option: --kpi-snapshot" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$kpi_snapshot_path" ]]; then
  echo "Required source file not found: $kpi_snapshot_path" >&2
  exit 1
fi

for optional_path in "$command_center_path" "$proof_loop_check_path"; do
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

default_if_blank() {
  local value="$1"
  local fallback="$2"
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$fallback"
  fi
}

lowercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
}

uppercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:lower:]' '[:upper:]'
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

extract_first_integer() {
  local raw="$1"
  local value
  value="$(print -r -- "$raw" | rg -o --pcre2 '[0-9]+' | head -n1 || true)"
  echo "$value"
}

weighted_score() {
  local raw_score="$1"
  local weight="$2"
  if [[ -z "$raw_score" ]]; then
    echo "0"
    return
  fi
  awk -v score="$raw_score" -v weight="$weight" 'BEGIN {
    value = (score + 0) * (weight + 0) / 100
    printf "%.0f", value
  }'
}

clamp_score() {
  local value="$1"
  if (( value < 0 )); then
    echo "0"
    return
  fi
  if (( value > 100 )); then
    echo "100"
    return
  fi
  echo "$value"
}

score_bucket_queue() {
  local raw_score="$1"
  if [[ -z "$raw_score" ]]; then
    echo "0|Queue signal unavailable"
    return
  fi

  local score=$(( raw_score ))
  if (( score <= 35 )); then
    echo "10|Queue pressure is low"
    return
  fi
  if (( score <= 50 )); then
    echo "6|Queue pressure is manageable"
    return
  fi
  if (( score <= 65 )); then
    echo "2|Queue pressure needs monitoring"
    return
  fi
  if (( score <= 80 )); then
    echo "-4|Queue pressure is high"
    return
  fi
  echo "-10|Queue pressure is critical"
}

score_bucket_urgency() {
  local raw_score="$1"
  if [[ -z "$raw_score" ]]; then
    echo "0|Urgency signal unavailable"
    return
  fi

  local score=$(( raw_score ))
  if (( score <= 25 )); then
    echo "6|Urgency is controlled"
    return
  fi
  if (( score <= 40 )); then
    echo "3|Urgency is manageable"
    return
  fi
  if (( score <= 60 )); then
    echo "0|Urgency is neutral"
    return
  fi
  if (( score <= 75 )); then
    echo "-4|Urgency is elevated"
    return
  fi
  echo "-8|Urgency is severe"
}

score_route_health() {
  local alignment_signal="$1"
  local lane_status="$2"
  local signal_lower lane_lower score call
  signal_lower="$(lowercase_value "$(trim_value "$alignment_signal")")"
  lane_lower="$(lowercase_value "$(trim_value "$lane_status")")"
  score=0
  call="Route state unavailable"

  if print -r -- "$signal_lower" | rg -q -- '(aligned)'; then
    score=$(( score + 8 ))
    call="Route is aligned"
  elif print -r -- "$signal_lower" | rg -q -- '(partial|watch|fallback|signal capture|capture)'; then
    score=$(( score + 2 ))
    call="Route is in re-lock mode"
  elif print -r -- "$signal_lower" | rg -q -- '(drifting|critical|missing|error|fail)'; then
    score=$(( score - 8 ))
    call="Route is drifting"
  fi

  if print -r -- "$lane_lower" | rg -q -- '(stable|aligned)'; then
    score=$(( score + 6 ))
  elif print -r -- "$lane_lower" | rg -q -- '(watch|signal capture|partial|capture)'; then
    score=$(( score + 1 ))
  elif print -r -- "$lane_lower" | rg -q -- '(critical|drifting|blocked|missing)'; then
    score=$(( score - 6 ))
  fi

  echo "${score}|${call}"
}

score_verification_state() {
  local status_raw="$1"
  local failures_raw="$2"
  local status_upper failures_count
  status_upper="$(uppercase_value "$(trim_value "$status_raw")")"
  failures_count="$(extract_first_integer "$failures_raw")"
  if [[ -z "$failures_count" ]]; then
    failures_count=0
  fi

  if [[ "$status_upper" == "PASS" ]]; then
    if (( failures_count == 0 )); then
      echo "12|PASS (${failures_count} failures)"
      return
    fi
    echo "6|PASS (${failures_count} failures)"
    return
  fi

  if [[ -z "$status_upper" || "$status_upper" == "N/A" ]]; then
    echo "0|Verification status missing"
    return
  fi

  echo "-14|${status_upper} (${failures_count} failures)"
}

resolve_velocity_tier() {
  local score="$1"
  if (( score >= 80 )); then
    echo "Scale"
    return
  fi
  if (( score >= 65 )); then
    echo "Compound"
    return
  fi
  if (( score >= 50 )); then
    echo "Re-Lock"
    return
  fi
  echo "Recovery"
}

resolve_launch_posture() {
  local score="$1"
  if (( score >= 80 )); then
    echo "High-velocity launch posture"
    return
  fi
  if (( score >= 65 )); then
    echo "Measured scale posture"
    return
  fi
  if (( score >= 50 )); then
    echo "Stabilize-and-relock posture"
    return
  fi
  echo "Risk-containment posture"
}

resolve_priority_move() {
  local verification_status="$1"
  local route_alignment_signal="$2"
  local route_lane_status="$3"
  local velocity_tier="$4"
  local status_upper route_lower
  status_upper="$(uppercase_value "$(trim_value "$verification_status")")"
  route_lower="$(lowercase_value "$(trim_value "$route_alignment_signal $route_lane_status")")"

  if [[ "$status_upper" != "PASS" ]]; then
    echo "Proof-loop verifier recovery"
    return
  fi

  if print -r -- "$route_lower" | rg -q -- '(critical|drifting|missing|blocked)'; then
    echo "Narrative route recovery"
    return
  fi

  case "$velocity_tier" in
    "Scale")
      echo "Proof compounding and scale"
      ;;
    "Compound")
      echo "Daily compounding cadence"
      ;;
    "Re-Lock")
      echo "Route re-lock sprint"
      ;;
    *)
      echo "Stabilization sprint"
      ;;
  esac
}

format_signed() {
  local value="$1"
  if [[ "$value" == -* ]]; then
    echo "$value"
  else
    echo "+$value"
  fi
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$kpi_snapshot_path" "# Founder Fame KPI Snapshot - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$command_center_path" "# Founder Fame Command Center - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-velocity-scoreboard.md"
fi

mkdir -p "$(dirname "$output_path")"

kpi_snapshot_heading="$(extract_heading "$kpi_snapshot_path")"
command_center_heading="$(extract_heading "$command_center_path")"
proof_loop_check_heading="$(extract_heading "$proof_loop_check_path")"

top_bet="$(extract_prefixed_value "$kpi_snapshot_path" "- Top bet: ")"
fame_readiness="$(extract_prefixed_value "$kpi_snapshot_path" "- Fame readiness: ")"
execution_readiness="$(extract_prefixed_value "$kpi_snapshot_path" "- Execution readiness: ")"
queue_pressure="$(extract_prefixed_value "$kpi_snapshot_path" "- Queue pressure: ")"
response_urgency="$(extract_prefixed_value "$kpi_snapshot_path" "- Response urgency: ")"
verification_status="$(extract_prefixed_value "$kpi_snapshot_path" "- Verification status: ")"
verification_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Verification mode: ")"
verification_failures="$(extract_prefixed_value "$kpi_snapshot_path" "- Verification failures: ")"
narrative_route_winner="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$kpi_snapshot_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$kpi_snapshot_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Route response mode: ")"
route_kpi_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Route KPI mode: ")"
route_health_recommendation="$(extract_prefixed_value "$kpi_snapshot_path" "- Route health recommendation: ")"
route_scale_action="$(extract_prefixed_value "$kpi_snapshot_path" "- Route scale action: ")"
route_lane_trigger="$(extract_prefixed_value "$kpi_snapshot_path" "- Route lane trigger: ")"
route_guardrail="$(extract_prefixed_value "$kpi_snapshot_path" "- Route guardrail: ")"
day_zero_ship_item="$(extract_prefixed_value "$kpi_snapshot_path" "- Day 0 ship item: ")"
routing_recommendation="$(extract_prefixed_value "$kpi_snapshot_path" "- Routing recommendation: ")"

if [[ -z "$top_bet" ]]; then
  top_bet="$(extract_prefixed_value "$command_center_path" "- Top bet: ")"
fi
if [[ -z "$fame_readiness" ]]; then
  fame_readiness="$(extract_prefixed_value "$command_center_path" "- Fame readiness: ")"
fi
if [[ -z "$execution_readiness" ]]; then
  execution_readiness="$(extract_prefixed_value "$command_center_path" "- Execution readiness: ")"
fi
if [[ -z "$queue_pressure" ]]; then
  queue_pressure="$(extract_prefixed_value "$command_center_path" "- Queue pressure: ")"
fi
if [[ -z "$response_urgency" ]]; then
  response_urgency="$(extract_prefixed_value "$command_center_path" "- Response urgency: ")"
fi
if [[ -z "$narrative_route_winner" ]]; then
  narrative_route_winner="$(extract_prefixed_value "$command_center_path" "- Narrative route winner: ")"
fi
if [[ -z "$narrative_route_trend" ]]; then
  narrative_route_trend="$(extract_prefixed_value "$command_center_path" "- Narrative route trend: ")"
fi
if [[ -z "$narrative_fame_velocity" ]]; then
  narrative_fame_velocity="$(extract_prefixed_value "$command_center_path" "- Narrative fame velocity: ")"
fi
if [[ -z "$narrative_ranked_opportunity" ]]; then
  narrative_ranked_opportunity="$(extract_prefixed_value "$command_center_path" "- Narrative-ranked opportunity: ")"
fi
if [[ -z "$execution_mode" ]]; then
  execution_mode="$(extract_prefixed_value "$command_center_path" "- Execution mode: ")"
fi
if [[ -z "$route_alignment_signal" ]]; then
  route_alignment_signal="$(extract_prefixed_value "$command_center_path" "- Route alignment signal: ")"
fi
if [[ -z "$route_lane_status" ]]; then
  route_lane_status="$(extract_prefixed_value "$command_center_path" "- Route lane status: ")"
fi
if [[ -z "$route_response_mode" ]]; then
  route_response_mode="$(extract_prefixed_value "$command_center_path" "- Active route mode: ")"
fi
if [[ -z "$route_scale_action" ]]; then
  route_scale_action="$(extract_prefixed_value "$command_center_path" "- Route lane action: ")"
fi
if [[ -z "$route_lane_trigger" ]]; then
  route_lane_trigger="$(extract_prefixed_value "$command_center_path" "- Route escalation condition: ")"
fi
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$(extract_prefixed_value "$command_center_path" "- Route guardrail: ")"
fi
if [[ -z "$day_zero_ship_item" ]]; then
  day_zero_ship_item="$(extract_prefixed_value "$command_center_path" "- Day 0 ship item: ")"
fi
if [[ -z "$routing_recommendation" ]]; then
  routing_recommendation="$(extract_prefixed_value "$command_center_path" "- Routing recommendation: ")"
fi

if [[ -z "$verification_status" ]]; then
  verification_status="$(extract_prefixed_value "$proof_loop_check_path" "- Status: ")"
fi
if [[ -z "$verification_mode" ]]; then
  verification_mode="$(extract_prefixed_value "$proof_loop_check_path" "- Mode: ")"
fi
if [[ -z "$verification_failures" ]]; then
  verification_failures="$(extract_prefixed_value "$proof_loop_check_path" "- Failures: ")"
fi

product_name="$(sanitize_inline "$product_name")"
top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "n/a")")"
fame_readiness="$(sanitize_inline "$(default_if_blank "$fame_readiness" "n/a")")"
execution_readiness="$(sanitize_inline "$(default_if_blank "$execution_readiness" "n/a")")"
queue_pressure="$(sanitize_inline "$(default_if_blank "$queue_pressure" "n/a")")"
response_urgency="$(sanitize_inline "$(default_if_blank "$response_urgency" "n/a")")"
verification_status="$(sanitize_inline "$(default_if_blank "$verification_status" "n/a")")"
verification_mode="$(sanitize_inline "$(default_if_blank "$verification_mode" "n/a")")"
verification_failures="$(sanitize_inline "$(default_if_blank "$verification_failures" "0")")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "n/a")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "n/a")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "n/a")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "n/a")")"
route_kpi_mode="$(sanitize_inline "$(default_if_blank "$route_kpi_mode" "n/a")")"
route_health_recommendation="$(sanitize_inline "$(default_if_blank "$route_health_recommendation" "Capture route winner and lane status before scaling.")")"
route_scale_action="$(sanitize_inline "$(default_if_blank "$route_scale_action" "Keep one route and close one blocker before opening a new lane.")")"
route_lane_trigger="$(sanitize_inline "$(default_if_blank "$route_lane_trigger" "Escalate if route lane health degrades on next rerun.")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "Run proof-loop verification before accelerating new narratives.")")"
day_zero_ship_item="$(sanitize_inline "$(default_if_blank "$day_zero_ship_item" "Ship one proof-first founder update tied to top KPI signal.")")"
routing_recommendation="$(sanitize_inline "$(default_if_blank "$routing_recommendation" "Keep one measurable proof narrative until route stability improves.")")"

narrative_velocity_score="$(extract_first_integer "$narrative_fame_velocity")"
execution_readiness_score="$(extract_first_integer "$execution_readiness")"
fame_readiness_score="$(extract_first_integer "$fame_readiness")"
queue_pressure_score="$(extract_first_integer "$queue_pressure")"
response_urgency_score="$(extract_first_integer "$response_urgency")"

velocity_base_component=12
velocity_base_source="fallback baseline"
if [[ -n "$narrative_velocity_score" ]]; then
  velocity_base_component="$(weighted_score "$narrative_velocity_score" 40)"
  velocity_base_source="${narrative_velocity_score}/100"
elif [[ -n "$execution_readiness_score" ]]; then
  velocity_base_component="$(weighted_score "$execution_readiness_score" 25)"
  velocity_base_source="execution readiness fallback"
fi

execution_component=10
if [[ -n "$execution_readiness_score" ]]; then
  execution_component="$(weighted_score "$execution_readiness_score" 20)"
fi

fame_component=8
if [[ -n "$fame_readiness_score" ]]; then
  fame_component="$(weighted_score "$fame_readiness_score" 15)"
fi

queue_component_meta="$(score_bucket_queue "$queue_pressure_score")"
queue_component="${queue_component_meta%%|*}"
queue_component_reason="${queue_component_meta#*|}"

urgency_component_meta="$(score_bucket_urgency "$response_urgency_score")"
urgency_component="${urgency_component_meta%%|*}"
urgency_component_reason="${urgency_component_meta#*|}"

route_component_meta="$(score_route_health "$route_alignment_signal" "$route_lane_status")"
route_component="${route_component_meta%%|*}"
route_component_reason="${route_component_meta#*|}"

verification_component_meta="$(score_verification_state "$verification_status" "$verification_failures")"
verification_component="${verification_component_meta%%|*}"
verification_component_reason="${verification_component_meta#*|}"

raw_velocity_score=$(( velocity_base_component + execution_component + fame_component + queue_component + urgency_component + route_component + verification_component ))
velocity_score="$(clamp_score "$raw_velocity_score")"
velocity_tier="$(resolve_velocity_tier "$velocity_score")"
launch_posture="$(resolve_launch_posture "$velocity_score")"
priority_move="$(resolve_priority_move "$verification_status" "$route_alignment_signal" "$route_lane_status" "$velocity_tier")"

velocity_call="Keep one route and compound with daily touch-floor discipline."
case "$velocity_tier" in
  "Scale")
    velocity_call="Scale the winner route with one proof post and one conversion push today."
    ;;
  "Compound")
    velocity_call="Compound current route; add one measurable proof increment per cycle."
    ;;
  "Re-Lock")
    velocity_call="Re-lock route alignment before opening any additional narrative variants."
    ;;
  *)
    velocity_call="Run recovery mode: close verifier/route blockers before scale."
    ;;
esac

verification_status_upper="$(uppercase_value "$verification_status")"
if [[ "$verification_status_upper" != "PASS" ]]; then
  velocity_call="Resolve proof-loop verification failures before accelerating distribution."
fi

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-velocity-scoreboard -->

# Founder Fame Velocity Scoreboard - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source KPI snapshot: ${kpi_snapshot_path}
Source command center: ${command_center_path:-n/a}
Source proof-loop verification: ${proof_loop_check_path:-n/a}

## Snapshot

- KPI snapshot: ${kpi_snapshot_heading}
- Command center: ${command_center_heading}
- Proof-loop verification: ${proof_loop_check_heading}
- Velocity score: ${velocity_score}/100
- Tier: ${velocity_tier}
- Launch posture: ${launch_posture}
- Priority move: ${priority_move}
- Velocity call: ${velocity_call}
- Verification state: ${verification_status} (${verification_mode}, failures: ${verification_failures})
- Top bet: ${top_bet}
- Narrative route winner/trend: ${narrative_route_winner} (${narrative_route_trend})
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment + lane: ${route_alignment_signal} / ${route_lane_status}
- Route response mode: ${route_response_mode}
- Route KPI mode: ${route_kpi_mode}

## Velocity Scoreboard

| Signal | Current value | Weight | Contribution |
| --- | --- | --- | --- |
| Narrative fame velocity | ${narrative_fame_velocity} | 40% | $(format_signed "$velocity_base_component") (${velocity_base_source}) |
| Execution readiness | ${execution_readiness} | 20% | $(format_signed "$execution_component") |
| Fame readiness | ${fame_readiness} | 15% | $(format_signed "$fame_component") |
| Queue pressure | ${queue_pressure} | context | $(format_signed "$queue_component") (${queue_component_reason}) |
| Response urgency | ${response_urgency} | context | $(format_signed "$urgency_component") (${urgency_component_reason}) |
| Route health | ${route_alignment_signal} / ${route_lane_status} | context | $(format_signed "$route_component") (${route_component_reason}) |
| Verification state | ${verification_status} (${verification_failures}) | gate | $(format_signed "$verification_component") (${verification_component_reason}) |
| **Total** | **${velocity_score}/100** | **composite** | **$(format_signed "$raw_velocity_score") pre-clamp** |

## Route Velocity Controls

- Route health recommendation: ${route_health_recommendation}
- Route scale action: ${route_scale_action}
- Route lane trigger: ${route_lane_trigger}
- Route guardrail: ${route_guardrail}
- Routing recommendation: ${routing_recommendation}
- Day 0 ship item: ${day_zero_ship_item}

## 72-Hour Velocity Plays

1. Day 0: Execute priority move (${priority_move}) and publish one proof-backed update tied to ${top_bet}.
2. Day 1: Keep route lane healthy (${route_alignment_signal}/${route_lane_status}) while advancing ${narrative_ranked_opportunity}.
3. Day 2: Re-score queue pressure + urgency before expanding channel volume.
4. End of cycle: Recompute velocity score and update checklist owners with the next route call.

## Checklist Comment Draft

Founder fame velocity scoreboard (${week_label})
Velocity score: ${velocity_score}/100 (${velocity_tier}, ${launch_posture})
Priority move: ${priority_move}
Verification: ${verification_status} (${verification_mode}, failures: ${verification_failures})
Route state: ${route_alignment_signal} / ${route_lane_status} (${route_response_mode})
Route call: ${route_health_recommendation}
Day 0 ship item: ${day_zero_ship_item}
Routing recommendation: ${routing_recommendation}

## Share Block

\`\`\`text
Founder fame velocity scoreboard (${week_label})
Velocity score: ${velocity_score}/100 (${velocity_tier})
Launch posture: ${launch_posture}
Priority move: ${priority_move}
Verification: ${verification_status} (${verification_mode}, failures: ${verification_failures})
Route: ${route_alignment_signal} / ${route_lane_status} (${route_response_mode})
Top bet: ${top_bet}
Opportunity: ${narrative_ranked_opportunity}
Routing recommendation: ${routing_recommendation}
Day 0 ship item: ${day_zero_ship_item}
\`\`\`

## Execution Checklist

- [ ] Confirm proof-loop verification remains PASS before scale moves.
- [ ] Execute the priority move and log owner update in Monday checklist.
- [ ] Keep route lane trigger visible during Day 0 to Day 2 standups.
- [ ] Close one queue-pressure blocker before opening a new narrative lane.
- [ ] Re-score this velocity scoreboard after the next command-center refresh.
EOF

echo "Generated founder fame velocity scoreboard: $output_path"
