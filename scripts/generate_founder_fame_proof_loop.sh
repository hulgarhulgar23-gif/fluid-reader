#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame proof loop from breakout and outreach artifacts.

Usage:
  zsh scripts/generate_founder_fame_proof_loop.sh [options]

Required:
  --breakout-plan <path>            Founder fame breakout plan markdown

Optional:
  --outreach-sprint <path>          Founder fame outreach sprint markdown
  --spotlight-pack <path>           Founder fame spotlight pack markdown
  --command-center <path>           Founder fame command center markdown
  --credibility-ledger <path>       Credibility ledger markdown
  --week <label>                    Week label (default: inferred from breakout heading, then current ISO week)
  --product <text>                  Product name (default: Fluid Reader)
  --primary-channel <text>          Primary publishing channel (default: X / Threads)
  --backup-channel <text>           Backup publishing channel (default: LinkedIn)
  --cta <text>                      CTA line for proof-loop scripts
  --out <path>                      Output path (default: docs/campaigns/<week>-founder-fame-proof-loop.md)
  -h, --help                        Show help

Example:
  zsh scripts/generate_founder_fame_proof_loop.sh \
    --breakout-plan docs/campaigns/2026-W24-founder-fame-breakout-plan.md \
    --outreach-sprint docs/campaigns/2026-W24-founder-fame-outreach-sprint.md \
    --spotlight-pack docs/campaigns/2026-W24-founder-fame-spotlight-pack.md \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --credibility-ledger docs/campaigns/2026-W24-credibility-ledger.md \
    --out docs/campaigns/2026-W24-founder-fame-proof-loop.md
EOF
}

breakout_plan_path=""
outreach_sprint_path=""
spotlight_pack_path=""
command_center_path=""
credibility_ledger_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="Reply with your KPI bottleneck and I will share the exact command stack."
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --breakout-plan)
      breakout_plan_path="${2:-}"
      shift 2
      ;;
    --outreach-sprint)
      outreach_sprint_path="${2:-}"
      shift 2
      ;;
    --spotlight-pack)
      spotlight_pack_path="${2:-}"
      shift 2
      ;;
    --command-center)
      command_center_path="${2:-}"
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
    --cta)
      cta_text="${2:-}"
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

if [[ -z "$breakout_plan_path" ]]; then
  echo "Missing required option: --breakout-plan" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$breakout_plan_path" ]]; then
  echo "Required source file not found: $breakout_plan_path" >&2
  exit 1
fi

for optional_path in \
  "$outreach_sprint_path" \
  "$spotlight_pack_path" \
  "$command_center_path" \
  "$credibility_ledger_path"; do
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

extract_table_cell_by_first_column() {
  local source_path="$1"
  local section_heading="$2"
  local first_column_value="$3"
  local column_index="$4"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v heading="$section_heading" -v row="$first_column_value" -v col="$column_index" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      first = clean($2)
      if (first == "Day" || first == "Loop" || first == "Priority" || first ~ /^---/) next
      if (first == row) {
        value = clean($(col + 1))
        print value
        exit
      }
    }
  ' "$source_path"
}

extract_checklist_item() {
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
    in_section && /^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]+/ {
      count++
      if (count == target) {
        line = $0
        sub(/^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]+/, "", line)
        print line
        exit
      }
    }
  ' "$source_path"
}

extract_integer() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[0-9]+' | head -n1 || true)"
  echo "$number"
}

lowercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
}

normalize_lane_strategy() {
  local lane_raw="$1"
  local lane
  lane="$(lowercase_value "$lane_raw")"
  if print -r -- "$lane" | rg -q -- 'creator-led|creator-first'; then
    echo "creator-led"
    return
  fi
  if print -r -- "$lane" | rg -q -- 'guesting-led|guesting-first|booking-first'; then
    echo "guesting-led"
    return
  fi
  echo "balanced"
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$breakout_plan_path" "# Founder Fame Breakout Plan - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$outreach_sprint_path" "# Founder Fame Outreach Sprint - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-proof-loop.md"
fi

mkdir -p "$(dirname "$output_path")"

breakout_heading="$(extract_heading "$breakout_plan_path")"
outreach_heading="$(extract_heading "$outreach_sprint_path")"
spotlight_heading="$(extract_heading "$spotlight_pack_path")"
command_center_heading="$(extract_heading "$command_center_path")"
credibility_heading="$(extract_heading "$credibility_ledger_path")"

top_bet="$(extract_prefixed_value "$breakout_plan_path" "- Top bet: ")"
route_recommendation="$(extract_prefixed_value "$breakout_plan_path" "- Routing recommendation: ")"
hook_route="$(extract_prefixed_value "$breakout_plan_path" "- Breakout hook route: ")"
proof_signal="$(extract_prefixed_value "$breakout_plan_path" "- Strongest proof signal: ")"
risk_call="$(extract_prefixed_value "$breakout_plan_path" "- Primary risk call: ")"
lane_strategy_raw="$(extract_prefixed_value "$breakout_plan_path" "- Outreach lane strategy: ")"
narrative_route_winner="$(extract_prefixed_value "$breakout_plan_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$breakout_plan_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$breakout_plan_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$breakout_plan_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$breakout_plan_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$breakout_plan_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$breakout_plan_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$breakout_plan_path" "- Route mode: ")"
route_guardrail="$(extract_prefixed_value "$breakout_plan_path" "- Route guardrail: ")"
route_scale_action="$(extract_prefixed_value "$breakout_plan_path" "- Scale action: ")"

if [[ -z "$top_bet" ]]; then
  top_bet="$(extract_prefixed_value "$spotlight_pack_path" "- Top bet: ")"
fi
if [[ -z "$risk_call" ]]; then
  risk_call="$(extract_prefixed_value "$spotlight_pack_path" "- Primary risk call: ")"
fi
if [[ -z "$risk_call" ]]; then
  risk_call="$(extract_prefixed_value "$command_center_path" "- Primary risk call: ")"
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
  route_response_mode="$(extract_prefixed_value "$command_center_path" "- Route mode: ")"
fi
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$(extract_prefixed_value "$command_center_path" "Route guardrail: ")"
fi
if [[ -z "$route_guardrail" ]]; then
  route_guardrail="$(extract_prefixed_value "$spotlight_pack_path" "- Route guardrail: ")"
fi
if [[ -z "$route_alignment_signal" ]]; then
  route_alignment_signal="$(extract_prefixed_value "$spotlight_pack_path" "- Route alignment signal: ")"
fi
if [[ -z "$route_lane_status" ]]; then
  route_lane_status="$(extract_prefixed_value "$spotlight_pack_path" "- Route lane status: ")"
fi
if [[ -z "$route_response_mode" ]]; then
  route_response_mode="$(extract_prefixed_value "$spotlight_pack_path" "- Route response mode: ")"
fi

fame_readiness="$(extract_prefixed_value "$spotlight_pack_path" "- Fame readiness: ")"
if [[ -z "$fame_readiness" ]]; then
  fame_readiness="$(extract_prefixed_value "$command_center_path" "- Fame readiness: ")"
fi
execution_readiness="$(extract_prefixed_value "$spotlight_pack_path" "- Execution readiness: ")"
if [[ -z "$execution_readiness" ]]; then
  execution_readiness="$(extract_prefixed_value "$command_center_path" "- Execution readiness: ")"
fi

lane_strategy_scorecard="$(extract_prefixed_value "$outreach_sprint_path" "- Lane strategy: ")"
weekly_touch_target_total="$(extract_prefixed_value "$outreach_sprint_path" "- Weekly touch target total: ")"
creator_touch_target="$(extract_prefixed_value "$outreach_sprint_path" "- Creator touch target: ")"
guesting_touch_target="$(extract_prefixed_value "$outreach_sprint_path" "- Guesting touch target: ")"
daily_touch_floor="$(extract_prefixed_value "$outreach_sprint_path" "- Daily touch floor (Day 0-Day 2): ")"
practical_reply_target="$(extract_prefixed_value "$outreach_sprint_path" "- Practical reply target: ")"
creator_collab_target="$(extract_prefixed_value "$outreach_sprint_path" "- Creator collab-ready target: ")"
guesting_booking_target="$(extract_prefixed_value "$outreach_sprint_path" "- Guesting booking-stage target: ")"
outreach_recommendation_source="$(extract_prefixed_value "$outreach_sprint_path" "- Recommendation source: ")"
route_outreach_mode="$(extract_prefixed_value "$outreach_sprint_path" "- Route outreach mode: ")"
route_alignment_target="$(extract_prefixed_value "$outreach_sprint_path" "- Route alignment target: ")"
route_lane_trigger="$(extract_prefixed_value "$outreach_sprint_path" "- Route lane trigger: ")"
route_touch_floor_adjustment="$(extract_prefixed_value "$outreach_sprint_path" "- Route touch-floor adjustment: ")"

day0_public_move="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 0" 4)"
day1_public_move="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 1" 4)"
day2_public_move="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 2" 4)"
day0_outreach_move="$(extract_table_cell_by_first_column "$outreach_sprint_path" "## 7-Day Outreach Sprint Grid" "Day 0" 4)"
day1_outreach_move="$(extract_table_cell_by_first_column "$outreach_sprint_path" "## 7-Day Outreach Sprint Grid" "Day 1" 4)"
day2_outreach_move="$(extract_table_cell_by_first_column "$outreach_sprint_path" "## 7-Day Outreach Sprint Grid" "Day 2" 4)"
day0_success_signal="$(extract_table_cell_by_first_column "$outreach_sprint_path" "## 7-Day Outreach Sprint Grid" "Day 0" 5)"
day1_success_signal="$(extract_table_cell_by_first_column "$outreach_sprint_path" "## 7-Day Outreach Sprint Grid" "Day 1" 5)"
day2_success_signal="$(extract_table_cell_by_first_column "$outreach_sprint_path" "## 7-Day Outreach Sprint Grid" "Day 2" 5)"

proof_action_primary="$(extract_checklist_item "$breakout_plan_path" "## Execution Checklist" 1)"
proof_action_secondary="$(extract_checklist_item "$breakout_plan_path" "## Execution Checklist" 2)"
outreach_action_primary="$(extract_checklist_item "$outreach_sprint_path" "## Execution Checklist" 1)"
outreach_action_secondary="$(extract_checklist_item "$outreach_sprint_path" "## Execution Checklist" 2)"

credibility_strongest_metric="$(extract_prefixed_value "$credibility_ledger_path" "- Strongest metric: ")"
credibility_social_leads="$(extract_prefixed_value "$credibility_ledger_path" "- Social proof leads: ")"

top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "Narrative Compounding Loop")")"
route_recommendation="$(sanitize_inline "$(default_if_blank "$route_recommendation" "Keep one proof narrative until execution confidence is stable.")")"
hook_route="$(sanitize_inline "$(default_if_blank "$hook_route" "Proof-First Outcome Hook")")"
proof_signal="$(sanitize_inline "$(default_if_blank "$proof_signal" "$credibility_strongest_metric")")"
proof_signal="$(sanitize_inline "$(default_if_blank "$proof_signal" "n/a")")"
risk_call="$(sanitize_inline "$(default_if_blank "$risk_call" "n/a")")"
fame_readiness="$(sanitize_inline "$(default_if_blank "$fame_readiness" "n/a")")"
execution_readiness="$(sanitize_inline "$(default_if_blank "$execution_readiness" "n/a")")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "n/a")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "General narrative momentum mode")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "n/a")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "Route Review")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "$risk_call")")"
route_scale_action="$(sanitize_inline "$(default_if_blank "$route_scale_action" "Keep route lane locked while proof scripts scale.")")"

lane_strategy_raw_combined="${lane_strategy_scorecard:-$lane_strategy_raw}"
lane_strategy="$(normalize_lane_strategy "$lane_strategy_raw_combined")"
lane_strategy_label="$lane_strategy"
if [[ "$lane_strategy" == "creator-led" ]]; then
  lane_strategy_label="creator-led (creator-first compounding)"
elif [[ "$lane_strategy" == "guesting-led" ]]; then
  lane_strategy_label="guesting-led (booking-first compounding)"
else
  lane_strategy_label="balanced (creator + guesting parity)"
fi

weekly_touch_target_total="$(sanitize_inline "$(default_if_blank "$weekly_touch_target_total" "n/a")")"
creator_touch_target="$(sanitize_inline "$(default_if_blank "$creator_touch_target" "n/a")")"
guesting_touch_target="$(sanitize_inline "$(default_if_blank "$guesting_touch_target" "n/a")")"
daily_touch_floor="$(sanitize_inline "$(default_if_blank "$daily_touch_floor" "2")")"
practical_reply_target="$(sanitize_inline "$(default_if_blank "$practical_reply_target" "8")")"
creator_collab_target="$(sanitize_inline "$(default_if_blank "$creator_collab_target" "1")")"
guesting_booking_target="$(sanitize_inline "$(default_if_blank "$guesting_booking_target" "1")")"
outreach_recommendation_source="$(sanitize_inline "$(default_if_blank "$outreach_recommendation_source" "Capture outreach sprint outcomes before Friday review.")")"
route_outreach_mode="$(sanitize_inline "$(default_if_blank "$route_outreach_mode" "Route-Locked Outreach")")"
route_alignment_target="$(sanitize_inline "$(default_if_blank "$route_alignment_target" "Aligned")")"
route_lane_trigger="$(sanitize_inline "$(default_if_blank "$route_lane_trigger" "Escalate if route lane status degrades after one cycle.")")"
route_touch_floor_adjustment="$(sanitize_inline "$(default_if_blank "$route_touch_floor_adjustment" "0")")"

day0_public_move="$(sanitize_inline "$(default_if_blank "$day0_public_move" "Publish proof-first post and log practical replies.")")"
day1_public_move="$(sanitize_inline "$(default_if_blank "$day1_public_move" "Ship backup-channel reinforcement with one measurable signal.")")"
day2_public_move="$(sanitize_inline "$(default_if_blank "$day2_public_move" "Publish objection-closure follow-up with docs-backed proof.")")"
day0_outreach_move="$(sanitize_inline "$(default_if_blank "$day0_outreach_move" "Run Day 0 creator and guesting outreach wave.")")"
day1_outreach_move="$(sanitize_inline "$(default_if_blank "$day1_outreach_move" "Run Day 1 follow-up wave and track warm intros.")")"
day2_outreach_move="$(sanitize_inline "$(default_if_blank "$day2_outreach_move" "Run conversion wave focused on booked/collab-ready targets.")")"
day0_success_signal="$(sanitize_inline "$(default_if_blank "$day0_success_signal" "1 practical creator reply + 1 booking signal")")"
day1_success_signal="$(sanitize_inline "$(default_if_blank "$day1_success_signal" "1 warm intro or collab-ready handoff")")"
day2_success_signal="$(sanitize_inline "$(default_if_blank "$day2_success_signal" "2 meaningful conversations move forward")")"

proof_action_primary="$(sanitize_inline "$(default_if_blank "$proof_action_primary" "Ship Day 0 proof-first post with one measurable claim.")")"
proof_action_secondary="$(sanitize_inline "$(default_if_blank "$proof_action_secondary" "Publish backup-channel reinforcement within 24 hours.")")"
outreach_action_primary="$(sanitize_inline "$(default_if_blank "$outreach_action_primary" "Ship Day 0 proof-first post + creator outreach wave.")")"
outreach_action_secondary="$(sanitize_inline "$(default_if_blank "$outreach_action_secondary" "Complete Day 1 backup-channel reinforcement + follow-ups.")")"

credibility_social_leads="$(sanitize_inline "$(default_if_blank "$credibility_social_leads" "creator n/a, founder target n/a")")"

weekly_touch_numeric="$(extract_integer "$weekly_touch_target_total")"
if [[ -z "$weekly_touch_numeric" ]]; then
  weekly_touch_numeric="$(extract_integer "$creator_touch_target")"
  local_guesting_numeric="$(extract_integer "$guesting_touch_target")"
  if [[ -n "$weekly_touch_numeric" && -n "$local_guesting_numeric" ]]; then
    weekly_touch_numeric=$(( weekly_touch_numeric + local_guesting_numeric ))
  fi
fi
reply_target_numeric="$(extract_integer "$practical_reply_target")"

proof_loop_intensity="steady"
if [[ -n "$weekly_touch_numeric" && -n "$reply_target_numeric" && "$weekly_touch_numeric" -ge 12 && "$reply_target_numeric" -ge 12 ]]; then
  proof_loop_intensity="aggressive"
elif [[ -n "$weekly_touch_numeric" && "$weekly_touch_numeric" -ge 8 ]]; then
  proof_loop_intensity="compounding"
fi

route_proof_mode="Route-Locked Proof Compounding"
route_proof_lane_status="Stable"
route_proof_action="Keep proof posts anchored to ${narrative_ranked_opportunity} in ${execution_mode}."
route_proof_trigger="Escalate if route alignment signal degrades below Partial."
route_intensity_adjustment=0
route_signal_lower="$(lowercase_value "$route_alignment_signal")"
route_lane_lower="$(lowercase_value "$route_lane_status")"
if print -r -- "$route_signal_lower $route_lane_lower" | rg -q -- '(drifting|critical|signal missing|missing)'; then
  route_proof_mode="Route Correction Proof Loop"
  route_proof_lane_status="Critical"
  route_proof_action="Pause non-essential proof variants and run route-correction scripts for the next 24 hours."
  route_proof_trigger="Escalate immediately if route lane remains Critical after Day 0 log."
  route_intensity_adjustment=2
elif print -r -- "$route_signal_lower $route_lane_lower" | rg -q -- '(partial|watch|signal capture|fallback)'; then
  route_proof_mode="Route Re-Lock Proof Loop"
  route_proof_lane_status="Watch"
  route_proof_action="Re-lock winner, execution mode, and proof priority opportunity before Day 1 publish."
  route_proof_trigger="Escalate if route alignment remains Partial after Day 1 cycle."
  route_intensity_adjustment=1
fi

if (( route_intensity_adjustment >= 2 )); then
  if [[ "$proof_loop_intensity" == "steady" ]]; then
    proof_loop_intensity="compounding"
  elif [[ "$proof_loop_intensity" == "compounding" ]]; then
    proof_loop_intensity="aggressive"
  fi
elif (( route_intensity_adjustment == 1 )); then
  if [[ "$proof_loop_intensity" == "steady" ]]; then
    proof_loop_intensity="compounding"
  fi
fi

creator_touch_numeric="$(extract_integer "$creator_touch_target")"
guesting_touch_numeric="$(extract_integer "$guesting_touch_target")"
lane_mix_label="balanced"
if [[ -n "$creator_touch_numeric" && -n "$guesting_touch_numeric" ]]; then
  if (( creator_touch_numeric >= guesting_touch_numeric + 1 )); then
    lane_mix_label="creator-heavy"
  elif (( guesting_touch_numeric >= creator_touch_numeric + 1 )); then
    lane_mix_label="guesting-heavy"
  fi
fi

product_name="$(sanitize_inline "$product_name")"
primary_channel="$(sanitize_inline "$primary_channel")"
backup_channel="$(sanitize_inline "$backup_channel")"
cta_text="$(sanitize_inline "$cta_text")"
lane_strategy_label="$(sanitize_inline "$lane_strategy_label")"
proof_loop_intensity="$(sanitize_inline "$proof_loop_intensity")"
lane_mix_label="$(sanitize_inline "$lane_mix_label")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-proof-loop -->

# Founder Fame Proof Loop - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source breakout plan: ${breakout_plan_path}
Source outreach sprint: ${outreach_sprint_path:-n/a}
Source spotlight pack: ${spotlight_pack_path:-n/a}
Source command center: ${command_center_path:-n/a}
Source credibility ledger: ${credibility_ledger_path:-n/a}

## Snapshot

- Breakout plan: ${breakout_heading}
- Outreach sprint: ${outreach_heading}
- Spotlight pack: ${spotlight_heading}
- Command center: ${command_center_heading}
- Credibility ledger: ${credibility_heading}
- Core narrative bet: ${top_bet}
- Hook route: ${hook_route}
- Route recommendation: ${route_recommendation}
- Lane strategy: ${lane_strategy_label}
- Lane mix label: ${lane_mix_label}
- Proof loop intensity: ${proof_loop_intensity}
- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Primary risk call: ${risk_call}
- Strongest proof signal: ${proof_signal}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment signal: ${route_alignment_signal}
- Route lane status: ${route_lane_status}
- Route response mode: ${route_response_mode}

## Proof Loop Scorecard

| Loop | Current signal | This-week target |
| --- | --- | --- |
| Narrative focus | Bet: ${top_bet} | Keep one narrative in all primary + backup posts |
| Route integrity | ${narrative_route_winner} / ${route_alignment_signal} | Keep route lane at ${route_alignment_target} with no mode drift |
| Proof velocity | Signal: ${proof_signal} | Publish 2 proof-backed updates with measurable claims |
| Outreach cadence | Strategy: ${lane_strategy_label} | Hit touch targets (creator ${creator_touch_target}, guesting ${guesting_touch_target}) |
| Response quality | Practical reply target: ${practical_reply_target} | Convert practical replies into docs-backed follow-ups |
| Conversion | Collab/book targets: ${creator_collab_target}/${guesting_booking_target} | Move conversations to collab-ready and booking-stage |

## Narrative Route Proof Lane

- Route proof mode: ${route_proof_mode}
- Route winner and trend: ${narrative_route_winner} (${narrative_route_trend})
- Route priority opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route lane status: ${route_proof_lane_status}
- Route response mode: ${route_response_mode}
- Route outreach mode: ${route_outreach_mode}
- Route guardrail: ${route_guardrail}
- Route scale action: ${route_scale_action}
- Route lane trigger: ${route_lane_trigger}
- Route proof trigger: ${route_proof_trigger}
- Route touch-floor adjustment: ${route_touch_floor_adjustment}
- Route lane action now: ${route_proof_action}

## 72-Hour Loop Plan

| Day | Public proof move | Outreach move | Log signal |
| --- | --- | --- | --- |
| Day 0 | ${day0_public_move} | ${day0_outreach_move} | ${day0_success_signal} |
| Day 1 | ${day1_public_move} | ${day1_outreach_move} | ${day1_success_signal} |
| Day 2 | ${day2_public_move} | ${day2_outreach_move} | ${day2_success_signal} |

## Channel Proof Scripts

### Primary Channel Script (${primary_channel})

This week we are running **${top_bet}** with a ${hook_route} opener.
Proof signal to lead with: ${proof_signal}.
Risk guardrail: ${risk_call}.
Route: ${route_recommendation}.
Route mode: ${route_proof_mode}.

${cta_text}

### Backup Channel Script (${backup_channel})

Operator update:

- Fame readiness: ${fame_readiness}
- Execution readiness: ${execution_readiness}
- Lane strategy: ${lane_strategy_label}
- Current conversion focus: creator ${creator_collab_target}, guesting ${guesting_booking_target}
- Route lane status: ${route_proof_lane_status}
- Route guardrail: ${route_guardrail}

${cta_text}

## Conversion Signals to Log

- Weekly touch target total: ${weekly_touch_target_total}
- Creator touch target: ${creator_touch_target}
- Guesting touch target: ${guesting_touch_target}
- Daily touch floor (Day 0-Day 2): ${daily_touch_floor}
- Practical reply target: ${practical_reply_target}
- Creator collab-ready target: ${creator_collab_target}
- Guesting booking-stage target: ${guesting_booking_target}
- Recommendation source: ${outreach_recommendation_source}
- Social proof leads: ${credibility_social_leads}

## Daily Standup Prompts

1. Did yesterday’s proof post create practical replies instead of vanity engagement?
2. Which outreach lane compounded best in the last 24 hours (creator vs guesting)?
3. Which repeated objection can be closed today with one concrete proof line?
4. Which signal should be logged before Friday review to improve next-week defaults?
5. Is route lane status (${route_proof_lane_status}) stable enough to open new proof variants?

## Execution Checklist

- [ ] Execute proof move: ${proof_action_primary}
- [ ] Execute proof move: ${proof_action_secondary}
- [ ] Execute outreach move: ${outreach_action_primary}
- [ ] Execute outreach move: ${outreach_action_secondary}
- [ ] Hit daily touch floor by end of Day 2.
- [ ] Keep route lane at ${route_alignment_target} and execute: ${route_proof_action}
- [ ] Hit practical reply target before Friday review.
- [ ] Move creator and guesting conversations to target stages.
- [ ] Update Monday checklist owner defaults with proof-loop outcomes.
EOF

echo "Generated founder fame proof loop: $output_path"
