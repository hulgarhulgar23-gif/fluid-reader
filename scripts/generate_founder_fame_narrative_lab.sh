#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame narrative lab from KPI/proof artifacts.

Usage:
  zsh scripts/generate_founder_fame_narrative_lab.sh [options]

Required:
  --kpi-snapshot <path>            Founder fame KPI snapshot markdown

Optional:
  --proof-loop <path>              Founder fame proof loop markdown
  --command-center <path>          Founder fame command center markdown
  --winning-hook-library <path>    Winning hook library markdown
  --credibility-ledger <path>      Credibility ledger markdown
  --week <label>                   Week label (default: inferred from KPI snapshot heading, then proof loop heading, then current ISO week)
  --product <text>                 Product name (default: Fluid Reader)
  --primary-channel <text>         Primary channel label (default: X / Threads)
  --backup-channel <text>          Backup channel label (default: LinkedIn)
  --primary-audience-region <text> Primary audience region (global/us/eu/apac; default: global)
  --backup-audience-region <text>  Backup audience region (global/us/eu/apac; default: global)
  --out <path>                     Output path (default: docs/campaigns/<week>-founder-fame-narrative-lab.md)
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_fame_narrative_lab.sh \
    --kpi-snapshot docs/campaigns/2026-W24-founder-fame-kpi-snapshot.md \
    --proof-loop docs/campaigns/2026-W24-founder-fame-proof-loop.md \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --winning-hook-library docs/campaigns/2026-W24-winning-hook-library.md \
    --credibility-ledger docs/campaigns/2026-W24-credibility-ledger.md \
    --out docs/campaigns/2026-W24-founder-fame-narrative-lab.md
EOF
}

kpi_snapshot_path=""
proof_loop_path=""
command_center_path=""
winning_hook_library_path=""
credibility_ledger_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
primary_audience_region="global"
backup_audience_region="global"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --kpi-snapshot)
      kpi_snapshot_path="${2:-}"
      shift 2
      ;;
    --proof-loop)
      proof_loop_path="${2:-}"
      shift 2
      ;;
    --command-center)
      command_center_path="${2:-}"
      shift 2
      ;;
    --winning-hook-library)
      winning_hook_library_path="${2:-}"
      shift 2
      ;;
    --credibility-ledger)
      credibility_ledger_path="${2:-}"
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
    --primary-audience-region)
      primary_audience_region="${2:-}"
      shift 2
      ;;
    --backup-audience-region)
      backup_audience_region="${2:-}"
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

for optional_path in "$proof_loop_path" "$command_center_path" "$winning_hook_library_path" "$credibility_ledger_path"; do
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

extract_first_heading_match() {
  local source_path="$1"
  local pattern="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi
  local line
  line="$(rg -m1 "$pattern" "$source_path" || true)"
  echo "$(trim_value "$line")"
}

resolve_guardrail() {
  local verification_status_value="$1"
  local normalized_status
  normalized_status="$(uppercase_value "$(trim_value "$verification_status_value")")"

  if [[ -z "$normalized_status" || "$normalized_status" == "N/A" ]]; then
    echo "Run proof-loop verification before opening a new narrative lane."
    return
  fi

  if [[ "$normalized_status" == "PASS" ]]; then
    echo "Verification is green; scale only narratives tied to measurable proof."
    return
  fi

  echo "Verification is not green; prioritize risk-closure narratives until checks recover."
}

resolve_route_lab_mode() {
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
  local route_lab_mode_value="$1"

  case "$route_lab_mode_value" in
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
  local route_lab_mode_value="$1"
  local route_scale_action_value="$2"
  local route_lane_trigger_value="$3"

  case "$route_lab_mode_value" in
    "Route Recovery")
      echo "Run route-correction narratives first; ${route_lane_trigger_value}"
      ;;
    "Route Re-Lock")
      echo "Re-lock winner, execution mode, and opportunity before next publish; ${route_lane_trigger_value}"
      ;;
    *)
      echo "$route_scale_action_value"
      ;;
  esac
}

resolve_priority_route() {
  local verification_status_value="$1"
  local queue_pressure_value="$2"
  local route_lab_mode_value="${3:-}"
  local narrative_route_winner_value="${4:-}"
  local normalized_status
  local normalized_queue_pressure
  normalized_status="$(uppercase_value "$(trim_value "$verification_status_value")")"
  normalized_queue_pressure="$(uppercase_value "$(trim_value "$queue_pressure_value")")"

  if [[ "$route_lab_mode_value" == "Route Recovery" ]]; then
    echo "Route recovery sprint"
    return
  fi

  if [[ "$route_lab_mode_value" == "Route Re-Lock" ]]; then
    echo "Route re-lock sequence"
    return
  fi

  if [[ -n "$narrative_route_winner_value" ]]; then
    local normalized_winner
    normalized_winner="$(uppercase_value "$(trim_value "$narrative_route_winner_value")")"
    if [[ "$normalized_winner" != "N/A" ]]; then
      echo "${narrative_route_winner_value} amplification"
      return
    fi
  fi

  if [[ "$normalized_status" == "PASS" && "$normalized_queue_pressure" != "HIGH" ]]; then
    echo "Proof-first amplification"
    return
  fi

  if [[ "$normalized_queue_pressure" == "HIGH" ]]; then
    echo "Queue-pressure release"
    return
  fi

  echo "Risk-closure sequencing"
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

resolve_fame_velocity_score() {
  local verification_status_value="$1"
  local queue_pressure_value="$2"
  local response_urgency_value="$3"
  local score=55

  local normalized_status
  local normalized_queue_pressure
  local normalized_response_urgency
  normalized_status="$(uppercase_value "$(trim_value "$verification_status_value")")"
  normalized_queue_pressure="$(uppercase_value "$(trim_value "$queue_pressure_value")")"
  normalized_response_urgency="$(uppercase_value "$(trim_value "$response_urgency_value")")"

  case "$normalized_status" in
    PASS) score=$((score + 20)) ;;
    FAIL|FAILED|ERROR|BLOCKED|NO|N/A) score=$((score - 20)) ;;
  esac

  case "$normalized_queue_pressure" in
    LOW) score=$((score + 10)) ;;
    MEDIUM) score=$((score + 2)) ;;
    HIGH) score=$((score - 12)) ;;
  esac

  case "$normalized_response_urgency" in
    LOW) score=$((score + 6)) ;;
    MEDIUM) score=$((score + 2)) ;;
    HIGH) score=$((score - 8)) ;;
  esac

  clamp_score "$score"
}

resolve_launch_posture() {
  local score="$1"
  if (( score >= 75 )); then
    echo "Scale + amplify"
    return
  fi
  if (( score >= 55 )); then
    echo "Steady cadence"
    return
  fi
  echo "Risk closure first"
}

normalize_region() {
  local value="$1"
  local normalized
  normalized="$(lowercase_value "$(trim_value "$value")")"
  case "$normalized" in
    us|eu|apac|global)
      echo "$normalized"
      ;;
    *)
      echo "global"
      ;;
  esac
}

resolve_region_label() {
  local region="$1"
  case "$region" in
    us)
      echo "US"
      ;;
    eu)
      echo "EU"
      ;;
    apac)
      echo "APAC"
      ;;
    *)
      echo "Global"
      ;;
  esac
}

resolve_publish_window() {
  local region="$1"
  local channel_lane="$2"
  case "$region" in
    us)
      if [[ "$channel_lane" == "primary" ]]; then
        echo "09:00-11:00 local"
      else
        echo "15:00-17:00 local"
      fi
      ;;
    eu)
      if [[ "$channel_lane" == "primary" ]]; then
        echo "10:00-12:00 local"
      else
        echo "16:00-18:00 local"
      fi
      ;;
    apac)
      if [[ "$channel_lane" == "primary" ]]; then
        echo "09:00-11:00 local"
      else
        echo "19:00-21:00 local"
      fi
      ;;
    *)
      if [[ "$channel_lane" == "primary" ]]; then
        echo "13:00 UTC"
      else
        echo "18:00 UTC"
      fi
      ;;
  esac
}

resolve_distribution_strategy() {
  local route_lab_mode_value="$1"
  case "$route_lab_mode_value" in
    "Route Recovery")
      echo "Recovery cadence: lead with risk-closure proof, follow with transparent unblock updates."
      ;;
    "Route Re-Lock")
      echo "Re-lock cadence: lead with winner reinforcement, follow with conversion proof."
      ;;
    *)
      echo "Compounding cadence: lead with winner amplification, follow with social-proof compounding."
      ;;
  esac
}

resolve_first_48h_execution_plan() {
  local route_lab_mode_value="$1"
  local primary_channel_value="$2"
  local backup_channel_value="$3"
  local primary_window_value="$4"
  local backup_window_value="$5"
  local day_zero_ship_item_value="$6"

  case "$route_lab_mode_value" in
    "Route Recovery")
      echo "Day 0: publish recovery proof on ${primary_channel_value} (${primary_window_value}) tied to '${day_zero_ship_item_value}'. Day 1: run blocker-response follow-up on ${backup_channel_value} (${backup_window_value}). Day 2: post route-stability proof before scaling."
      ;;
    "Route Re-Lock")
      echo "Day 0: lead with winner re-lock post on ${primary_channel_value} (${primary_window_value}) tied to '${day_zero_ship_item_value}'. Day 1: reinforce confidence with replies on ${backup_channel_value} (${backup_window_value}). Day 2: publish one proof-backed winner recap."
      ;;
    *)
      echo "Day 0: launch winner amplification on ${primary_channel_value} (${primary_window_value}) using '${day_zero_ship_item_value}'. Day 1: amplify strongest replies on ${backup_channel_value} (${backup_window_value}). Day 2: publish a compounding proof recap and queue Day 3 remix."
      ;;
  esac
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$kpi_snapshot_path" "# Founder Fame KPI Snapshot - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$proof_loop_path" "# Founder Fame Proof Loop - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-narrative-lab.md"
fi

mkdir -p "$(dirname "$output_path")"

kpi_snapshot_heading="$(extract_heading "$kpi_snapshot_path")"
proof_loop_heading="$(extract_heading "$proof_loop_path")"
command_center_heading="$(extract_heading "$command_center_path")"
winning_hook_heading="$(extract_heading "$winning_hook_library_path")"
credibility_heading="$(extract_heading "$credibility_ledger_path")"

top_bet="$(extract_prefixed_value "$kpi_snapshot_path" "- Top bet: ")"
core_narrative_bet="$(extract_prefixed_value "$kpi_snapshot_path" "- Core narrative bet: ")"
strongest_proof_signal="$(extract_prefixed_value "$kpi_snapshot_path" "- Strongest proof signal: ")"
verification_status="$(extract_prefixed_value "$kpi_snapshot_path" "- Verification status: ")"
routing_recommendation="$(extract_prefixed_value "$kpi_snapshot_path" "- Routing recommendation: ")"
primary_risk_call="$(extract_prefixed_value "$kpi_snapshot_path" "- Primary risk call: ")"
day_zero_ship_item="$(extract_prefixed_value "$kpi_snapshot_path" "- Day 0 ship item: ")"
creator_touch_target="$(extract_prefixed_value "$kpi_snapshot_path" "- Creator touch target: ")"
guesting_touch_target="$(extract_prefixed_value "$kpi_snapshot_path" "- Guesting touch target: ")"
practical_reply_target="$(extract_prefixed_value "$kpi_snapshot_path" "- Practical reply target: ")"
lane_focus="$(extract_prefixed_value "$kpi_snapshot_path" "- Lane focus: ")"
social_proof_leads="$(extract_prefixed_value "$kpi_snapshot_path" "- Social proof leads: ")"
recommendation_source="$(extract_prefixed_value "$kpi_snapshot_path" "- Recommendation source: ")"
narrative_route_winner="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$kpi_snapshot_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$kpi_snapshot_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$kpi_snapshot_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Route response mode: ")"
route_kpi_mode="$(extract_prefixed_value "$kpi_snapshot_path" "- Route KPI mode: ")"
route_alignment_target="$(extract_prefixed_value "$kpi_snapshot_path" "- Route alignment target: ")"
route_guardrail="$(extract_prefixed_value "$kpi_snapshot_path" "- Route guardrail: ")"
route_scale_action="$(extract_prefixed_value "$kpi_snapshot_path" "- Route scale action: ")"
route_lane_trigger="$(extract_prefixed_value "$kpi_snapshot_path" "- Route lane trigger: ")"
route_touch_floor_adjustment="$(extract_prefixed_value "$kpi_snapshot_path" "- Route touch-floor adjustment: ")"
route_health_recommendation="$(extract_prefixed_value "$kpi_snapshot_path" "- Route health recommendation: ")"

proof_loop_core_narrative="$(extract_prefixed_value "$proof_loop_path" "- Core narrative bet: ")"
proof_loop_route_recommendation="$(extract_prefixed_value "$proof_loop_path" "- Route recommendation: ")"
proof_loop_creator_collab_target="$(extract_prefixed_value "$proof_loop_path" "- Creator collab-ready target: ")"
proof_loop_guesting_booking_target="$(extract_prefixed_value "$proof_loop_path" "- Guesting booking-stage target: ")"
proof_loop_social_proof_leads="$(extract_prefixed_value "$proof_loop_path" "- Social proof leads: ")"
proof_loop_narrative_route_winner="$(extract_prefixed_value "$proof_loop_path" "- Narrative route winner: ")"
proof_loop_narrative_route_trend="$(extract_prefixed_value "$proof_loop_path" "- Narrative route trend: ")"
proof_loop_narrative_fame_velocity="$(extract_prefixed_value "$proof_loop_path" "- Narrative fame velocity: ")"
proof_loop_narrative_ranked_opportunity="$(extract_prefixed_value "$proof_loop_path" "- Narrative-ranked opportunity: ")"
proof_loop_execution_mode="$(extract_prefixed_value "$proof_loop_path" "- Execution mode: ")"
proof_loop_route_alignment_signal="$(extract_prefixed_value "$proof_loop_path" "- Route alignment signal: ")"
proof_loop_route_lane_status="$(extract_prefixed_value "$proof_loop_path" "- Route lane status: ")"
proof_loop_route_response_mode="$(extract_prefixed_value "$proof_loop_path" "- Route response mode: ")"
proof_loop_route_proof_mode="$(extract_prefixed_value "$proof_loop_path" "- Route proof mode: ")"
proof_loop_route_outreach_mode="$(extract_prefixed_value "$proof_loop_path" "- Route outreach mode: ")"
proof_loop_route_guardrail="$(extract_prefixed_value "$proof_loop_path" "- Route guardrail: ")"
proof_loop_route_scale_action="$(extract_prefixed_value "$proof_loop_path" "- Route scale action: ")"
proof_loop_route_lane_trigger="$(extract_prefixed_value "$proof_loop_path" "- Route lane trigger: ")"
proof_loop_route_touch_floor_adjustment="$(extract_prefixed_value "$proof_loop_path" "- Route touch-floor adjustment: ")"

queue_pressure="$(extract_prefixed_value "$command_center_path" "- Queue pressure: ")"
response_urgency="$(extract_prefixed_value "$command_center_path" "- Response urgency: ")"
next_standup_action="$(extract_prefixed_value "$command_center_path" "- Next standup action: ")"
command_center_top_bet="$(extract_prefixed_value "$command_center_path" "- Top bet: ")"
command_center_narrative_route_winner="$(extract_prefixed_value "$command_center_path" "- Narrative route winner: ")"
command_center_narrative_route_trend="$(extract_prefixed_value "$command_center_path" "- Narrative route trend: ")"
command_center_narrative_fame_velocity="$(extract_prefixed_value "$command_center_path" "- Narrative fame velocity: ")"
command_center_narrative_ranked_opportunity="$(extract_prefixed_value "$command_center_path" "- Narrative-ranked opportunity: ")"
command_center_execution_mode="$(extract_prefixed_value "$command_center_path" "- Execution mode: ")"
command_center_route_alignment_signal="$(extract_prefixed_value "$command_center_path" "- Route alignment signal: ")"
command_center_route_lane_status="$(extract_prefixed_value "$command_center_path" "- Route lane status: ")"
command_center_route_response_mode="$(extract_prefixed_value "$command_center_path" "- Active route mode: ")"
command_center_route_guardrail="$(extract_prefixed_value "$command_center_path" "- Route guardrail: ")"
command_center_route_scale_action="$(extract_prefixed_value "$command_center_path" "- Route lane action: ")"
command_center_route_lane_trigger="$(extract_prefixed_value "$command_center_path" "- Route escalation condition: ")"

top_hook_heading="$(extract_first_heading_match "$winning_hook_library_path" '^### Hook [A-Z]')"
credibility_signal="$(extract_prefixed_value "$credibility_ledger_path" "- Signal confidence: ")"

if [[ -z "$top_bet" ]]; then
  top_bet="$command_center_top_bet"
fi
if [[ -z "$core_narrative_bet" ]]; then
  core_narrative_bet="$proof_loop_core_narrative"
fi
if [[ -z "$routing_recommendation" ]]; then
  routing_recommendation="$proof_loop_route_recommendation"
fi
if [[ -z "$social_proof_leads" ]]; then
  social_proof_leads="$proof_loop_social_proof_leads"
fi

if [[ -z "$narrative_route_winner" ]]; then
  narrative_route_winner="$proof_loop_narrative_route_winner"
fi
if [[ -z "$narrative_route_winner" ]]; then
  narrative_route_winner="$command_center_narrative_route_winner"
fi
if [[ -z "$narrative_route_trend" ]]; then
  narrative_route_trend="$proof_loop_narrative_route_trend"
fi
if [[ -z "$narrative_route_trend" ]]; then
  narrative_route_trend="$command_center_narrative_route_trend"
fi
if [[ -z "$narrative_fame_velocity" ]]; then
  narrative_fame_velocity="$proof_loop_narrative_fame_velocity"
fi
if [[ -z "$narrative_fame_velocity" ]]; then
  narrative_fame_velocity="$command_center_narrative_fame_velocity"
fi
if [[ -z "$narrative_ranked_opportunity" ]]; then
  narrative_ranked_opportunity="$proof_loop_narrative_ranked_opportunity"
fi
if [[ -z "$narrative_ranked_opportunity" ]]; then
  narrative_ranked_opportunity="$command_center_narrative_ranked_opportunity"
fi
if [[ -z "$execution_mode" ]]; then
  execution_mode="$proof_loop_execution_mode"
fi
if [[ -z "$execution_mode" ]]; then
  execution_mode="$command_center_execution_mode"
fi
if [[ -z "$route_alignment_signal" ]]; then
  route_alignment_signal="$proof_loop_route_alignment_signal"
fi
if [[ -z "$route_alignment_signal" ]]; then
  route_alignment_signal="$command_center_route_alignment_signal"
fi
if [[ -z "$route_lane_status" ]]; then
  route_lane_status="$proof_loop_route_lane_status"
fi
if [[ -z "$route_lane_status" ]]; then
  route_lane_status="$command_center_route_lane_status"
fi
if [[ -z "$route_response_mode" ]]; then
  route_response_mode="$proof_loop_route_response_mode"
fi
if [[ -z "$route_response_mode" ]]; then
  route_response_mode="$command_center_route_response_mode"
fi

route_proof_mode="$proof_loop_route_proof_mode"
route_outreach_mode="$proof_loop_route_outreach_mode"
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$proof_loop_route_guardrail"
fi
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$command_center_route_guardrail"
fi
if [[ -z "$route_scale_action" ]]; then
  route_scale_action="$proof_loop_route_scale_action"
fi
if [[ -z "$route_scale_action" ]]; then
  route_scale_action="$command_center_route_scale_action"
fi
if [[ -z "$route_lane_trigger" ]]; then
  route_lane_trigger="$proof_loop_route_lane_trigger"
fi
if [[ -z "$route_lane_trigger" ]]; then
  route_lane_trigger="$command_center_route_lane_trigger"
fi
if [[ -z "$route_touch_floor_adjustment" ]]; then
  route_touch_floor_adjustment="$proof_loop_route_touch_floor_adjustment"
fi

if [[ -z "$route_kpi_mode" ]]; then
  route_kpi_mode="$(resolve_route_lab_mode "$route_alignment_signal" "$route_lane_status")"
fi
if [[ -z "$route_alignment_target" ]]; then
  route_alignment_target="$(resolve_route_alignment_target "$route_kpi_mode")"
fi
if [[ -z "$route_health_recommendation" ]]; then
  route_health_recommendation="$(resolve_route_health_recommendation "$route_kpi_mode" "$route_scale_action" "$route_lane_trigger")"
fi

priority_route="$(resolve_priority_route "$verification_status" "$queue_pressure" "$route_kpi_mode" "$narrative_route_winner")"
verification_guardrail="$(resolve_guardrail "$verification_status")"
fame_velocity_score="$(resolve_fame_velocity_score "$verification_status" "$queue_pressure" "$response_urgency")"
launch_posture="$(resolve_launch_posture "$fame_velocity_score")"
distribution_strategy="$(resolve_distribution_strategy "$route_kpi_mode")"
primary_audience_region="$(normalize_region "$primary_audience_region")"
backup_audience_region="$(normalize_region "$backup_audience_region")"
primary_audience_region_label="$(resolve_region_label "$primary_audience_region")"
backup_audience_region_label="$(resolve_region_label "$backup_audience_region")"
primary_publish_window="$(resolve_publish_window "$primary_audience_region" "primary")"
backup_publish_window="$(resolve_publish_window "$backup_audience_region" "backup")"
first_48h_execution_plan="$(resolve_first_48h_execution_plan "$route_kpi_mode" "$primary_channel" "$backup_channel" "$primary_publish_window" "$backup_publish_window" "$day_zero_ship_item")"

product_name="$(sanitize_inline "$product_name")"
primary_channel="$(sanitize_inline "$primary_channel")"
backup_channel="$(sanitize_inline "$backup_channel")"
primary_audience_region_label="$(sanitize_inline "$primary_audience_region_label")"
backup_audience_region_label="$(sanitize_inline "$backup_audience_region_label")"
primary_publish_window="$(sanitize_inline "$primary_publish_window")"
backup_publish_window="$(sanitize_inline "$backup_publish_window")"
top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "n/a")")"
core_narrative_bet="$(sanitize_inline "$(default_if_blank "$core_narrative_bet" "n/a")")"
strongest_proof_signal="$(sanitize_inline "$(default_if_blank "$strongest_proof_signal" "n/a")")"
verification_status="$(sanitize_inline "$(default_if_blank "$verification_status" "n/a")")"
routing_recommendation="$(sanitize_inline "$(default_if_blank "$routing_recommendation" "Keep one proof-backed route until conversion signal improves.")")"
primary_risk_call="$(sanitize_inline "$(default_if_blank "$primary_risk_call" "n/a")")"
day_zero_ship_item="$(sanitize_inline "$(default_if_blank "$day_zero_ship_item" "Ship one proof-first narrative in the first posting window.")")"
creator_touch_target="$(sanitize_inline "$(default_if_blank "$creator_touch_target" "n/a")")"
guesting_touch_target="$(sanitize_inline "$(default_if_blank "$guesting_touch_target" "n/a")")"
practical_reply_target="$(sanitize_inline "$(default_if_blank "$practical_reply_target" "n/a")")"
lane_focus="$(sanitize_inline "$(default_if_blank "$lane_focus" "Keep creator and guesting lanes balanced.")")"
social_proof_leads="$(sanitize_inline "$(default_if_blank "$social_proof_leads" "n/a")")"
recommendation_source="$(sanitize_inline "$(default_if_blank "$recommendation_source" "Review KPI snapshot and proof-loop outcomes together.")")"
proof_loop_creator_collab_target="$(sanitize_inline "$(default_if_blank "$proof_loop_creator_collab_target" "n/a")")"
proof_loop_guesting_booking_target="$(sanitize_inline "$(default_if_blank "$proof_loop_guesting_booking_target" "n/a")")"
queue_pressure="$(sanitize_inline "$(default_if_blank "$queue_pressure" "n/a")")"
response_urgency="$(sanitize_inline "$(default_if_blank "$response_urgency" "n/a")")"
next_standup_action="$(sanitize_inline "$(default_if_blank "$next_standup_action" "Log one route winner and one blocked route in the next standup.")")"
top_hook_heading="$(sanitize_inline "$(default_if_blank "$top_hook_heading" "Hook A")")"
credibility_signal="$(sanitize_inline "$(default_if_blank "$credibility_signal" "n/a")")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "Proof-first route")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "n/a")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "Missing")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "Route Review")")"
route_proof_mode="$(sanitize_inline "$(default_if_blank "$route_proof_mode" "Route-Locked Proof Compounding")")"
route_outreach_mode="$(sanitize_inline "$(default_if_blank "$route_outreach_mode" "Route-Locked Outreach")")"
route_kpi_mode="$(sanitize_inline "$(default_if_blank "$route_kpi_mode" "Route Compounding")")"
route_alignment_target="$(sanitize_inline "$(default_if_blank "$route_alignment_target" "Aligned + Stable")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "$verification_guardrail")")"
route_scale_action="$(sanitize_inline "$(default_if_blank "$route_scale_action" "Keep route winner and ranked opportunity locked while narrative performance compounds.")")"
route_lane_trigger="$(sanitize_inline "$(default_if_blank "$route_lane_trigger" "Escalate if route lane status degrades in the next standup.")")"
route_touch_floor_adjustment="$(sanitize_inline "$(default_if_blank "$route_touch_floor_adjustment" "0")")"
route_health_recommendation="$(sanitize_inline "$(default_if_blank "$route_health_recommendation" "$route_scale_action")")"
priority_route="$(sanitize_inline "$priority_route")"
verification_guardrail="$(sanitize_inline "$verification_guardrail")"
launch_posture="$(sanitize_inline "$launch_posture")"
distribution_strategy="$(sanitize_inline "$distribution_strategy")"
first_48h_execution_plan="$(sanitize_inline "$(default_if_blank "$first_48h_execution_plan" "Capture Day 0/Day 1/Day 2 route actions before distribution starts.")")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-narrative-lab -->

# Founder Fame Narrative Lab - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source KPI snapshot: ${kpi_snapshot_path}
Source proof loop: ${proof_loop_path:-n/a}
Source command center: ${command_center_path:-n/a}
Source winning hook library: ${winning_hook_library_path:-n/a}
Source credibility ledger: ${credibility_ledger_path:-n/a}

## Snapshot

- KPI snapshot: ${kpi_snapshot_heading}
- Proof loop: ${proof_loop_heading}
- Command center: ${command_center_heading}
- Winning hook library: ${winning_hook_heading}
- Credibility ledger: ${credibility_heading}
- Top bet: ${top_bet}
- Core narrative bet: ${core_narrative_bet}
- Strongest proof signal: ${strongest_proof_signal}
- Verification status: ${verification_status}
- Routing recommendation: ${routing_recommendation}
- Primary risk call: ${primary_risk_call}
- Queue pressure: ${queue_pressure}
- Response urgency: ${response_urgency}
- Lane focus: ${lane_focus}
- Audience regions: ${primary_audience_region_label} / ${backup_audience_region_label}
- Publish windows: ${primary_publish_window} / ${backup_publish_window}
- Priority route: ${priority_route}
- Guardrail: ${verification_guardrail}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Route alignment signal: ${route_alignment_signal}
- Route lane status: ${route_lane_status}
- Route response mode: ${route_response_mode}

## Fame Velocity Dashboard

- Fame velocity score: ${fame_velocity_score}/100
- Launch posture: ${launch_posture}
- Next standup action: ${next_standup_action}

| Signal | Current state | Decision |
| --- | --- | --- |
| Verification status | ${verification_status} | Keep narrative bets proof-backed before scaling. |
| Queue pressure | ${queue_pressure} | If pressure is high, shift one lane toward unblock updates. |
| Response urgency | ${response_urgency} | Match posting cadence to response load and close loops same day. |
| Route health | ${route_alignment_signal} / ${route_lane_status} | Keep route lane at ${route_alignment_target} with ${route_kpi_mode}. |
| Priority route | ${priority_route} | Keep this as primary until route health falls below ${route_alignment_target}. |
| Recommendation source | ${recommendation_source} | Re-run this lab after each weekly KPI snapshot refresh. |

## Narrative Route Lab Controls

- Route lab mode: ${route_kpi_mode}
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
- Route recommendation now: ${route_health_recommendation}
- First 48h execution plan: ${first_48h_execution_plan}

## Ranked Narrative Routes

| Rank | Narrative route | Why now | Risk guardrail | CTA seed |
| --- | --- | --- | --- | --- |
| 1 | ${narrative_route_winner} | Uses strongest proof signal (${strongest_proof_signal}) with verification status ${verification_status}. | ${route_guardrail} | Share your KPI bottleneck and I will map this route to your week. |
| 2 | Behind-the-scenes route | Converts queue pressure (${queue_pressure}) + response urgency (${response_urgency}) into transparent execution updates. | Keep each post tied to one measurable action from day-zero ship item. | Reply with the blocker that is slowing your founder loop. |
| 3 | Objection-breaker route | Uses credibility + proof leads (${social_proof_leads}) to handle practical replies early. | ${route_health_recommendation} | Ask me for the exact objection response script. |

## Channel Scripts

### Primary Channel (${primary_channel})

1. ${top_bet}
2. Proof signal: ${strongest_proof_signal}
3. Route: ${routing_recommendation} (${route_kpi_mode})
4. Day 0 ship item: ${day_zero_ship_item}
5. CTA: Reply with your KPI bottleneck for the exact weekly route.

### Backup Channel (${backup_channel})

1. Core narrative: ${core_narrative_bet}
2. Lane focus: ${lane_focus}
3. Creator/guesting target: ${creator_touch_target} / ${guesting_touch_target} (adjustment ${route_touch_floor_adjustment})
4. Practical reply target: ${practical_reply_target} (${route_alignment_target})
5. CTA: Comment with your current proof gap and I will share a one-week action ladder.

## 7-Day Distribution Calendar

- Distribution strategy: ${distribution_strategy}
- First 48h execution plan: ${first_48h_execution_plan}

| Day | Lead channel | Support channel | Objective | Proof anchor |
| --- | --- | --- | --- | --- |
| Day 0 | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | Launch one route-winner proof post and pin the narrative route. | ${day_zero_ship_item} |
| Day 1 | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | Close practical replies and publish one objection-breaker follow-up. | Practical reply target: ${practical_reply_target} |
| Day 2 | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | Push creator + guesting momentum updates from active route lanes. | Creator/guesting target: ${creator_touch_target} / ${guesting_touch_target} |
| Day 3 | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | Publish credibility reinforcement and route-health progress. | Credibility confidence: ${credibility_signal} |
| Day 4 | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | Run hook remix test while preserving the route winner proof source. | Hook test: ${top_hook_heading} |
| Day 5 | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | Share queue-pressure and response-urgency improvements from the week. | Queue/urgency: ${queue_pressure} / ${response_urgency} |
| Day 6 | ${primary_channel} (${primary_audience_region_label}, ${primary_publish_window}) | ${backup_channel} (${backup_audience_region_label}, ${backup_publish_window}) | Lock next-loop winner and publish the coming-week route call. | Next standup action: ${next_standup_action} |

## 7-Day Narrative Cadence

| Day | Focus | Route | Deliverable |
| --- | --- | --- | --- |
| Day 0 | Launch proof | Proof-first | Publish one post tied to ${day_zero_ship_item}. |
| Day 1 | Reply conversion | Objection-breaker | Close practical replies toward target (${practical_reply_target}). |
| Day 2 | Lane momentum | Behind-the-scenes | Share creator + guesting progress (${creator_touch_target} / ${guesting_touch_target}). |
| Day 3 | Credibility push | Proof-first | Publish one credibility-backed follow-up (signal confidence: ${credibility_signal}). |
| Day 4 | Hook iteration | Hook-driven | Test top hook seed (${top_hook_heading}) against route winner (${narrative_route_winner}). |
| Day 5 | Outcome recap | Behind-the-scenes | Post what changed in queue pressure + response urgency. |
| Day 6 | Next-loop setup | Objection-breaker | Set next standup action: ${next_standup_action}; keep route lane at ${route_alignment_target}. |

## Reply Ladder

1. Discovery reply: confirm KPI context + urgency in one sentence.
2. Proof reply: map one concrete proof action to the user’s blocker.
3. Conversion reply: route into creator collab-ready / guesting booking-stage targets.
4. Follow-up reply: log one measurable outcome and schedule next step.

- Creator collab-ready target: ${proof_loop_creator_collab_target}
- Guesting booking-stage target: ${proof_loop_guesting_booking_target}
- Recommendation source: ${recommendation_source}

## Route Remix Matrix

| Trigger | Route to run | Post format | Success check |
| --- | --- | --- | --- |
| Verification green + low queue pressure | ${narrative_route_winner} | One proof screenshot + one KPI sentence | Replies reference concrete KPI blockers. |
| Verification green + high queue pressure | Behind-the-scenes route | Execution log update + unblock CTA | Queue pressure trend eases in next standup. |
| Verification not green or route lane degrades | Objection-breaker route | Risk-closure post + explicit next action | At least one blocked reply moves to next step and route lane improves. |
| New hook winner appears (${top_hook_heading}) | Hook-driven overlay | Hook remix with same proof source | Hook winner beats prior route in reply quality. |

## Experiment Checklist

- [ ] Publish one proof-first post with explicit KPI evidence.
- [ ] Test one alternate route from Ranked Narrative Routes.
- [ ] Compare primary vs backup script response quality.
- [ ] Route at least two replies into next-step conversations.
- [ ] Log one route winner and one failed route in standup notes.
- [ ] Keep route lane at ${route_alignment_target} and execute: ${route_health_recommendation}
- [ ] Carry the winning route into next week’s command center.
EOF

echo "Generated founder fame narrative lab: $output_path"
