#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame KPI snapshot from command-center and proof-loop artifacts.

Usage:
  zsh scripts/generate_founder_fame_kpi_snapshot.sh [options]

Required:
  --proof-loop <path>             Founder fame proof loop markdown

Optional:
  --command-center <path>         Founder fame command center markdown
  --proof-loop-check <path>       Founder fame proof loop verification markdown
  --week <label>                  Week label (default: inferred from proof loop heading, then command center heading, then current ISO week)
  --product <text>                Product name (default: Fluid Reader)
  --out <path>                    Output path (default: docs/campaigns/<week>-founder-fame-kpi-snapshot.md)
  -h, --help                      Show help

Example:
  zsh scripts/generate_founder_fame_kpi_snapshot.sh \
    --proof-loop docs/campaigns/2026-W24-founder-fame-proof-loop.md \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --proof-loop-check docs/campaigns/2026-W24-founder-fame-proof-loop-check.md \
    --out docs/campaigns/2026-W24-founder-fame-kpi-snapshot.md
EOF
}

proof_loop_path=""
command_center_path=""
proof_loop_check_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --proof-loop)
      proof_loop_path="${2:-}"
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

if [[ -z "$proof_loop_path" ]]; then
  echo "Missing required option: --proof-loop" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$proof_loop_path" ]]; then
  echo "Required source file not found: $proof_loop_path" >&2
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

uppercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:lower:]' '[:upper:]'
}

lowercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
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

resolve_lane_focus() {
  local creator_target="$1"
  local guesting_target="$2"
  local creator_int
  local guesting_int
  creator_int="$(extract_first_integer "$creator_target")"
  guesting_int="$(extract_first_integer "$guesting_target")"

  if [[ -z "$creator_int" || -z "$guesting_int" ]]; then
    echo "Capture creator + guesting lane targets before rerouting."
    return
  fi

  if (( creator_int == guesting_int )); then
    echo "Balanced lane targets; keep creator + guesting cadence paired."
    return
  fi

  if (( creator_int > guesting_int )); then
    echo "Creator lane is heavier; maintain guesting follow-through to avoid imbalance."
  else
    echo "Guesting lane is heavier; sustain creator outreach to keep conversion diversity."
  fi
}

resolve_verification_guardrail() {
  local verification_status_value="$1"
  local normalized_status
  normalized_status="$(uppercase_value "$(trim_value "$verification_status_value")")"

  if [[ -z "$normalized_status" || "$normalized_status" == "N/A" ]]; then
    echo "Run proof-loop verification and log status before external amplification."
    return
  fi

  if [[ "$normalized_status" == "PASS" ]]; then
    echo "Verification is green; proceed with one measurable proof move per day."
    return
  fi

  echo "Verification is not green; resolve failed checks before publishing additional claims."
}

resolve_route_kpi_mode() {
  local route_alignment_value="$1"
  local route_lane_status_value="$2"
  local route_signal
  route_signal="$(lowercase_value "$(trim_value "$route_alignment_value $route_lane_status_value")")"

  if print -r -- "$route_signal" | rg -q -- '(drifting|critical|signal missing|missing|fail|error|blocked)'; then
    echo "Route Recovery"
    return
  fi

  if print -r -- "$route_signal" | rg -q -- '(partial|watch|fallback|capture)'; then
    echo "Route Re-Lock"
    return
  fi

  echo "Route Compounding"
}

resolve_route_alignment_target() {
  local route_kpi_mode_value="$1"

  case "$route_kpi_mode_value" in
    "Route Recovery")
      echo "Partial or better in 24h"
      ;;
    "Route Re-Lock")
      echo "Aligned by Day 1"
      ;;
    *)
      echo "Aligned + Stable"
      ;;
  esac
}

resolve_route_health_recommendation() {
  local route_kpi_mode_value="$1"
  local route_scale_action_value="$2"

  case "$route_kpi_mode_value" in
    "Route Recovery")
      echo "Pause new variants and run route correction until lane status is no longer Critical."
      ;;
    "Route Re-Lock")
      echo "Re-lock winner, execution mode, and ranked opportunity before the next publish cycle."
      ;;
    *)
      echo "$route_scale_action_value"
      ;;
  esac
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$proof_loop_path" "# Founder Fame Proof Loop - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$command_center_path" "# Founder Fame Command Center - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-kpi-snapshot.md"
fi

mkdir -p "$(dirname "$output_path")"

proof_loop_heading="$(extract_heading "$proof_loop_path")"
command_center_heading="$(extract_heading "$command_center_path")"
verification_heading="$(extract_heading "$proof_loop_check_path")"

top_bet="$(extract_prefixed_value "$command_center_path" "- Top bet: ")"
core_narrative_bet="$(extract_prefixed_value "$proof_loop_path" "- Core narrative bet: ")"
fame_readiness="$(extract_prefixed_value "$command_center_path" "- Fame readiness: ")"
execution_readiness="$(extract_prefixed_value "$command_center_path" "- Execution readiness: ")"
queue_pressure="$(extract_prefixed_value "$command_center_path" "- Queue pressure: ")"
response_urgency="$(extract_prefixed_value "$command_center_path" "- Response urgency: ")"
primary_risk_call="$(extract_prefixed_value "$command_center_path" "- Primary risk call: ")"
routing_recommendation="$(extract_prefixed_value "$command_center_path" "- Routing recommendation: ")"
day_zero_ship_item="$(extract_prefixed_value "$command_center_path" "Day 0 ship item: ")"

proof_route_recommendation="$(extract_prefixed_value "$proof_loop_path" "- Route recommendation: ")"
strongest_proof_signal="$(extract_prefixed_value "$proof_loop_path" "- Strongest proof signal: ")"
weekly_touch_target_total="$(extract_prefixed_value "$proof_loop_path" "- Weekly touch target total: ")"
creator_touch_target="$(extract_prefixed_value "$proof_loop_path" "- Creator touch target: ")"
guesting_touch_target="$(extract_prefixed_value "$proof_loop_path" "- Guesting touch target: ")"
daily_touch_floor="$(extract_prefixed_value "$proof_loop_path" "- Daily touch floor (Day 0-Day 2): ")"
practical_reply_target="$(extract_prefixed_value "$proof_loop_path" "- Practical reply target: ")"
creator_collab_target="$(extract_prefixed_value "$proof_loop_path" "- Creator collab-ready target: ")"
guesting_booking_target="$(extract_prefixed_value "$proof_loop_path" "- Guesting booking-stage target: ")"
recommendation_source="$(extract_prefixed_value "$proof_loop_path" "- Recommendation source: ")"
social_proof_leads="$(extract_prefixed_value "$proof_loop_path" "- Social proof leads: ")"
narrative_route_winner="$(extract_prefixed_value "$proof_loop_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$proof_loop_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$proof_loop_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$proof_loop_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$proof_loop_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$proof_loop_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$proof_loop_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$proof_loop_path" "- Route response mode: ")"
route_proof_mode="$(extract_prefixed_value "$proof_loop_path" "- Route proof mode: ")"
route_outreach_mode="$(extract_prefixed_value "$proof_loop_path" "- Route outreach mode: ")"
route_guardrail="$(extract_prefixed_value "$proof_loop_path" "- Route guardrail: ")"
route_scale_action="$(extract_prefixed_value "$proof_loop_path" "- Route scale action: ")"
route_lane_trigger="$(extract_prefixed_value "$proof_loop_path" "- Route lane trigger: ")"
route_touch_floor_adjustment="$(extract_prefixed_value "$proof_loop_path" "- Route touch-floor adjustment: ")"

verification_mode="$(extract_prefixed_value "$proof_loop_check_path" "- Mode: ")"
verification_status="$(extract_prefixed_value "$proof_loop_check_path" "- Status: ")"
verification_failures="$(extract_prefixed_value "$proof_loop_check_path" "- Failures: ")"

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
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$(extract_prefixed_value "$command_center_path" "- Route guardrail: ")"
fi
if [[ -z "$route_scale_action" ]]; then
  route_scale_action="$(extract_prefixed_value "$command_center_path" "- Route lane action: ")"
fi
if [[ -z "$route_lane_trigger" ]]; then
  route_lane_trigger="$(extract_prefixed_value "$command_center_path" "- Route escalation condition: ")"
fi

if [[ -z "$routing_recommendation" ]]; then
  routing_recommendation="$proof_route_recommendation"
fi
if [[ -z "$top_bet" ]]; then
  top_bet="$core_narrative_bet"
fi

lane_focus="$(resolve_lane_focus "$creator_touch_target" "$guesting_touch_target")"
verification_guardrail="$(resolve_verification_guardrail "$verification_status")"
route_kpi_mode="$(resolve_route_kpi_mode "$route_alignment_signal" "$route_lane_status")"
route_alignment_target="$(resolve_route_alignment_target "$route_kpi_mode")"
route_health_recommendation="$(resolve_route_health_recommendation "$route_kpi_mode" "$route_scale_action")"

product_name="$(sanitize_inline "$product_name")"
top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "n/a")")"
core_narrative_bet="$(sanitize_inline "$(default_if_blank "$core_narrative_bet" "n/a")")"
fame_readiness="$(sanitize_inline "$(default_if_blank "$fame_readiness" "n/a")")"
execution_readiness="$(sanitize_inline "$(default_if_blank "$execution_readiness" "n/a")")"
queue_pressure="$(sanitize_inline "$(default_if_blank "$queue_pressure" "n/a")")"
response_urgency="$(sanitize_inline "$(default_if_blank "$response_urgency" "n/a")")"
primary_risk_call="$(sanitize_inline "$(default_if_blank "$primary_risk_call" "n/a")")"
routing_recommendation="$(sanitize_inline "$(default_if_blank "$routing_recommendation" "Keep one KPI narrative until execution confidence is stable.")")"
day_zero_ship_item="$(sanitize_inline "$(default_if_blank "$day_zero_ship_item" "Ship one proof-first founder update tied to the top KPI signal.")")"
strongest_proof_signal="$(sanitize_inline "$(default_if_blank "$strongest_proof_signal" "n/a")")"
weekly_touch_target_total="$(sanitize_inline "$(default_if_blank "$weekly_touch_target_total" "n/a")")"
creator_touch_target="$(sanitize_inline "$(default_if_blank "$creator_touch_target" "n/a")")"
guesting_touch_target="$(sanitize_inline "$(default_if_blank "$guesting_touch_target" "n/a")")"
daily_touch_floor="$(sanitize_inline "$(default_if_blank "$daily_touch_floor" "n/a")")"
practical_reply_target="$(sanitize_inline "$(default_if_blank "$practical_reply_target" "n/a")")"
creator_collab_target="$(sanitize_inline "$(default_if_blank "$creator_collab_target" "n/a")")"
guesting_booking_target="$(sanitize_inline "$(default_if_blank "$guesting_booking_target" "n/a")")"
recommendation_source="$(sanitize_inline "$(default_if_blank "$recommendation_source" "Capture proof-loop outcomes before Friday review.")")"
social_proof_leads="$(sanitize_inline "$(default_if_blank "$social_proof_leads" "n/a")")"
verification_mode="$(sanitize_inline "$(default_if_blank "$verification_mode" "n/a")")"
verification_status="$(sanitize_inline "$(default_if_blank "$verification_status" "n/a")")"
verification_failures="$(sanitize_inline "$(default_if_blank "$verification_failures" "n/a")")"
lane_focus="$(sanitize_inline "$lane_focus")"
verification_guardrail="$(sanitize_inline "$verification_guardrail")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "n/a")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "n/a")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "Missing")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "Route Review")")"
route_proof_mode="$(sanitize_inline "$(default_if_blank "$route_proof_mode" "Route-Locked Proof Compounding")")"
route_outreach_mode="$(sanitize_inline "$(default_if_blank "$route_outreach_mode" "Route-Locked Outreach")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "$verification_guardrail")")"
route_scale_action="$(sanitize_inline "$(default_if_blank "$route_scale_action" "Keep route winner and ranked opportunity locked while KPI targets compound.")")"
route_lane_trigger="$(sanitize_inline "$(default_if_blank "$route_lane_trigger" "Escalate if route lane status degrades in the next standup.")")"
route_touch_floor_adjustment="$(sanitize_inline "$(default_if_blank "$route_touch_floor_adjustment" "0")")"
route_kpi_mode="$(sanitize_inline "$route_kpi_mode")"
route_alignment_target="$(sanitize_inline "$route_alignment_target")"
route_health_recommendation="$(sanitize_inline "$route_health_recommendation")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-kpi-snapshot -->

# Founder Fame KPI Snapshot - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source proof loop: ${proof_loop_path}
Source command center: ${command_center_path:-n/a}
Source proof-loop verification: ${proof_loop_check_path:-n/a}

## Snapshot

- Proof loop: ${proof_loop_heading}
- Command center: ${command_center_heading}
- Verification report: ${verification_heading}
- Top bet: ${top_bet}
- Core narrative bet: ${core_narrative_bet}
- Strongest proof signal: ${strongest_proof_signal}
- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Queue pressure: ${queue_pressure}
- Response urgency: ${response_urgency}
- Verification status: ${verification_status}
- Verification mode: ${verification_mode}
- Verification failures: ${verification_failures}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment signal: ${route_alignment_signal}
- Route lane status: ${route_lane_status}
- Route response mode: ${route_response_mode}

## KPI Pulse

| KPI | Current signal | Weekly target | Notes |
| --- | --- | --- | --- |
| Route integrity | ${route_alignment_signal} / ${route_lane_status} | ${route_alignment_target} | Mode: ${route_kpi_mode}; winner ${narrative_route_winner}. |
| Weekly touch target total | ${weekly_touch_target_total} | ${weekly_touch_target_total} | Keep proof + outreach throughput stable. |
| Creator touch target | ${creator_touch_target} | ${creator_touch_target} | Creator lane conversion coverage. |
| Guesting touch target | ${guesting_touch_target} | ${guesting_touch_target} | Guesting lane booking coverage. |
| Daily touch floor (Day 0-Day 2) | ${daily_touch_floor} | ${daily_touch_floor} | Enforce minimum daily execution depth. |
| Practical reply target | ${practical_reply_target} | ${practical_reply_target} | Convert public interest to practical conversations. |
| Creator collab-ready target | ${creator_collab_target} | ${creator_collab_target} | Advance creator conversations to collab-ready. |
| Guesting booking-stage target | ${guesting_booking_target} | ${guesting_booking_target} | Secure booking-stage guesting outcomes. |

## Verification Pulse

- Verification status: ${verification_status}
- Verification mode: ${verification_mode}
- Verification failures: ${verification_failures}
- Primary risk call: ${primary_risk_call}
- Day 0 ship item: ${day_zero_ship_item}
- Routing recommendation: ${routing_recommendation}
- Recommendation source: ${recommendation_source}
- Lane focus: ${lane_focus}
- Social proof leads: ${social_proof_leads}
- Guardrail: ${verification_guardrail}

## Narrative Route KPI Controls

- Route KPI mode: ${route_kpi_mode}
- Route winner and trend: ${narrative_route_winner} (${narrative_route_trend})
- Route fame velocity: ${narrative_fame_velocity}
- Route priority opportunity: ${narrative_ranked_opportunity}
- Route execution/response mode: ${execution_mode} / ${route_response_mode}
- Route proof/outreach mode: ${route_proof_mode} / ${route_outreach_mode}
- Route alignment target: ${route_alignment_target}
- Route guardrail: ${route_guardrail}
- Route scale action: ${route_scale_action}
- Route lane trigger: ${route_lane_trigger}
- Route touch-floor adjustment: ${route_touch_floor_adjustment}
- Route health recommendation: ${route_health_recommendation}

## 72-Hour KPI Actions

1. Day 0: Ship one proof-first founder update anchored to ${strongest_proof_signal}.
2. Day 1: Lock route mode (${route_kpi_mode}) and lane focus (${lane_focus}) before publishing the next follow-up wave.
3. Day 2: Convert strongest conversations toward creator collab-ready and guesting booking-stage targets while executing ${route_scale_action}.
4. End of cycle: Re-score queue pressure + response urgency before opening new narratives.

## Share Block

\`\`\`text
Founder KPI snapshot (${week_label})
- Top bet: ${top_bet}
- Core narrative: ${core_narrative_bet}
- Verification: ${verification_status} (${verification_mode}, failures: ${verification_failures})
- Touch targets: creator ${creator_touch_target} / guesting ${guesting_touch_target} / daily floor ${daily_touch_floor}
- Practical reply target: ${practical_reply_target}
- Routing: ${routing_recommendation}
- Route health: ${route_alignment_signal} / ${route_lane_status} (${route_kpi_mode})
- Route action: ${route_health_recommendation}
- Risk call: ${primary_risk_call}
- Day 0 ship item: ${day_zero_ship_item}
\`\`\`

## Execution Checklist

- [ ] Confirm proof-loop verification status is PASS before external amplification.
- [ ] Ship one Day 0 proof move linked to the strongest proof signal.
- [ ] Hit daily touch floor for Day 0 through Day 2.
- [ ] Track practical replies and route two to high-intent follow-ups.
- [ ] Close at least one creator collab-ready and one guesting booking-stage step.
- [ ] Keep route lane at ${route_alignment_target} and execute: ${route_health_recommendation}
- [ ] Update the next command-center standup with this KPI snapshot.
EOF

echo "Generated founder fame KPI snapshot: $output_path"
