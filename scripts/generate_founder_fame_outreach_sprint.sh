#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame outreach sprint from breakout and outreach signal artifacts.

Usage:
  zsh scripts/generate_founder_fame_outreach_sprint.sh [options]

Required:
  --breakout-plan <path>             Founder fame breakout plan markdown

Optional:
  --guesting-queue <path>            Founder guesting queue markdown
  --creator-target-list <path>       Creator target list markdown
  --distribution-plan <path>         7-day distribution follow-up plan markdown
  --media-blast <path>               Founder media blast markdown
  --week <label>                     Week label (default: inferred from breakout heading, then current ISO week)
  --product <text>                   Product name (default: Fluid Reader)
  --primary-channel <text>           Primary publishing channel (default: X / Threads)
  --backup-channel <text>            Backup publishing channel (default: LinkedIn)
  --cta <text>                       CTA line for outreach scripts
  --out <path>                       Output path (default: docs/campaigns/<week>-founder-fame-outreach-sprint.md)
  -h, --help                         Show help

Example:
  zsh scripts/generate_founder_fame_outreach_sprint.sh \
    --breakout-plan docs/campaigns/2026-W24-founder-fame-breakout-plan.md \
    --guesting-queue .build/founder/founder-guesting-queue-2026-W24.md \
    --creator-target-list docs/campaigns/2026-W24-creator-target-list.md \
    --distribution-plan docs/campaigns/2026-W24-distribution-plan.md \
    --media-blast .build/founder/founder-media-blast-2026-W24.md \
    --out docs/campaigns/2026-W24-founder-fame-outreach-sprint.md
EOF
}

breakout_plan_path=""
guesting_queue_path=""
creator_target_list_path=""
distribution_plan_path=""
media_blast_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="Reply with your audience and I will share one ready-to-send outreach script."
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --breakout-plan)
      breakout_plan_path="${2:-}"
      shift 2
      ;;
    --guesting-queue)
      guesting_queue_path="${2:-}"
      shift 2
      ;;
    --creator-target-list)
      creator_target_list_path="${2:-}"
      shift 2
      ;;
    --distribution-plan)
      distribution_plan_path="${2:-}"
      shift 2
      ;;
    --media-blast)
      media_blast_path="${2:-}"
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
  "$guesting_queue_path" \
  "$creator_target_list_path" \
  "$distribution_plan_path" \
  "$media_blast_path"; do
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
    in_section && /^### / && heading !~ /^### / { next }
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
      if (first == "Day" || first == "Rank" || first == "Loop" || first == "Dimension" || first == "Priority" || first ~ /^---/) next
      if (first == row) {
        cell = clean($(col + 1))
        print cell
        exit
      }
    }
  ' "$source_path"
}

extract_numbered_line_from_section() {
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
        line = $0
        sub(/^[0-9]+\.[[:space:]]*/, "", line)
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

round_to_int() {
  local value="$1"
  awk -v value="$value" 'BEGIN { printf "%.0f", value + 0 }'
}

resolve_lane_strategy() {
  local explicit_lane_raw="$1"
  local creator_lane_raw="$2"
  local outreach_recommendation_raw="$3"
  local guesting_recommendation_raw="$4"
  local explicit_lane
  explicit_lane="$(lowercase_value "$explicit_lane_raw")"
  if print -r -- "$explicit_lane" | rg -q -- 'creator-led'; then
    echo "creator-led"
    return
  fi
  if print -r -- "$explicit_lane" | rg -q -- 'guesting-led'; then
    echo "guesting-led"
    return
  fi
  if print -r -- "$explicit_lane" | rg -q -- 'balanced'; then
    echo "balanced"
    return
  fi

  local combined
  combined="$(lowercase_value "${creator_lane_raw} ${outreach_recommendation_raw} ${guesting_recommendation_raw}")"

  if print -r -- "$combined" | rg -q -- '(creator[- ]first|creator[- ]led|creator[- ]heavy|creator[- ]priority|focus creator)'; then
    echo "creator-led"
    return
  fi

  if print -r -- "$combined" | rg -q -- '(guesting[- ]first|guesting[- ]led|guesting[- ]heavy|guesting[- ]priority|focus guesting|founder guesting)'; then
    echo "guesting-led"
    return
  fi

  if print -r -- "$combined" | rg -q -- 'creator' && ! print -r -- "$combined" | rg -q -- 'guesting'; then
    echo "creator-led"
    return
  fi

  if print -r -- "$combined" | rg -q -- 'guesting' && ! print -r -- "$combined" | rg -q -- 'creator'; then
    echo "guesting-led"
    return
  fi

  echo "balanced"
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$breakout_plan_path" "# Founder Fame Breakout Plan - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-outreach-sprint.md"
fi

mkdir -p "$(dirname "$output_path")"

breakout_heading="$(extract_heading "$breakout_plan_path")"
guesting_heading="$(extract_heading "$guesting_queue_path")"
creator_target_heading="$(extract_heading "$creator_target_list_path")"
distribution_heading="$(extract_heading "$distribution_plan_path")"
media_blast_heading="$(extract_heading "$media_blast_path")"

top_bet="$(extract_prefixed_value "$breakout_plan_path" "- Top bet: ")"
routing_recommendation="$(extract_prefixed_value "$breakout_plan_path" "- Routing recommendation: ")"
strongest_proof_signal="$(extract_prefixed_value "$breakout_plan_path" "- Strongest proof signal: ")"
breakout_hook_route="$(extract_prefixed_value "$breakout_plan_path" "- Breakout hook route: ")"
day0_objective="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 0" 2)"
day1_objective="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 1" 2)"
day0_move="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 0" 4)"
day1_move="$(extract_table_cell_by_first_column "$breakout_plan_path" "## 7-Day Fame Cadence" "Day 1" 4)"
narrative_route_winner="$(extract_prefixed_value "$breakout_plan_path" "- Narrative route winner: ")"
narrative_route_trend="$(extract_prefixed_value "$breakout_plan_path" "- Narrative route trend: ")"
narrative_fame_velocity="$(extract_prefixed_value "$breakout_plan_path" "- Narrative fame velocity: ")"
narrative_ranked_opportunity="$(extract_prefixed_value "$breakout_plan_path" "- Narrative-ranked opportunity: ")"
execution_mode="$(extract_prefixed_value "$breakout_plan_path" "- Execution mode: ")"
route_alignment_signal="$(extract_prefixed_value "$breakout_plan_path" "- Route alignment signal: ")"
route_lane_status="$(extract_prefixed_value "$breakout_plan_path" "- Route lane status: ")"
route_response_mode="$(extract_prefixed_value "$breakout_plan_path" "- Route mode: ")"
route_guardrail="$(extract_section_prefixed_value "$breakout_plan_path" "## Narrative Route Scale Plan" "- Route guardrail: ")"
route_scale_action="$(extract_section_prefixed_value "$breakout_plan_path" "## Narrative Route Scale Plan" "- Scale action: ")"
creator_burst_lane="$(extract_section_prefixed_value "$breakout_plan_path" "## Partnership Bursts" "- Creator burst lane: ")"
outreach_recommendation="$(extract_section_prefixed_value "$breakout_plan_path" "## Partnership Bursts" "- Outreach recommendation: ")"
variant_recommendation="$(extract_section_prefixed_value "$breakout_plan_path" "## Partnership Bursts" "- Variant recommendation: ")"
breakout_lane_strategy="$(extract_prefixed_value "$breakout_plan_path" "- Outreach lane strategy: ")"

guesting_top_target="$(extract_prefixed_value "$guesting_queue_path" "- Guesting signal top target: ")"
guesting_top_format="$(extract_prefixed_value "$guesting_queue_path" "- Guesting signal top format: ")"
guesting_recommendation="$(extract_prefixed_value "$guesting_queue_path" "- Guesting signal recommendation: ")"
guesting_touch_goal="$(extract_prefixed_value "$guesting_queue_path" "- Weekly outreach touch goal: ")"
guesting_rank1="$(extract_numbered_line_from_section "$guesting_queue_path" "## Ranked Pitch Queue" 1)"
guesting_rank2="$(extract_numbered_line_from_section "$guesting_queue_path" "## Ranked Pitch Queue" 2)"
guesting_day0="$(extract_numbered_line_from_section "$guesting_queue_path" "## 7-Day Booking Sprint" 1)"
guesting_day1="$(extract_numbered_line_from_section "$guesting_queue_path" "## 7-Day Booking Sprint" 2)"

creator_top_segment="$(extract_prefixed_value "$creator_target_list_path" "- Top signal segment: ")"
creator_top_handle="$(extract_prefixed_value "$creator_target_list_path" "- Top signal handle: ")"
creator_signal_recommendation="$(extract_prefixed_value "$creator_target_list_path" "- Creator signal recommendation: ")"
creator_contact_day0="$(extract_numbered_line_from_section "$creator_target_list_path" "## Contact Sprint Plan" 1)"
creator_contact_day1="$(extract_numbered_line_from_section "$creator_target_list_path" "## Contact Sprint Plan" 2)"
creator_contact_day2="$(extract_numbered_line_from_section "$creator_target_list_path" "## Contact Sprint Plan" 3)"

distribution_lead_channel="$(extract_prefixed_value "$distribution_plan_path" "- Lead channel this week: ")"
distribution_support_channel="$(extract_prefixed_value "$distribution_plan_path" "- Support channel this week: ")"
distribution_reply_goal="$(extract_prefixed_value "$distribution_plan_path" "- First-24-hour practical reply goal: ")"
distribution_outreach_goal="$(extract_prefixed_value "$distribution_plan_path" "- Seven-day outreach follow-up goal: ")"
distribution_day0_deliverable="$(extract_table_cell_by_first_column "$distribution_plan_path" "## Day-by-Day Distribution Plan" "Day 0" 5)"
distribution_day1_deliverable="$(extract_table_cell_by_first_column "$distribution_plan_path" "## Day-by-Day Distribution Plan" "Day 1" 5)"
distribution_day2_deliverable="$(extract_table_cell_by_first_column "$distribution_plan_path" "## Day-by-Day Distribution Plan" "Day 2" 5)"

media_weekly_narrative="$(extract_prefixed_value "$media_blast_path" "- Weekly narrative: ")"
media_current_focus="$(extract_prefixed_value "$media_blast_path" "- Current focus: ")"

top_bet="$(sanitize_inline "$(default_if_blank "$top_bet" "Narrative Compounding Loop")")"
routing_recommendation="$(sanitize_inline "$(default_if_blank "$routing_recommendation" "Keep one proof narrative until execution confidence is stable.")")"
strongest_proof_signal="$(sanitize_inline "$(default_if_blank "$strongest_proof_signal" "n/a")")"
breakout_hook_route="$(sanitize_inline "$(default_if_blank "$breakout_hook_route" "Proof-First Outcome Hook")")"
day0_objective="$(sanitize_inline "$(default_if_blank "$day0_objective" "Ship top-bet proof post in the lead channel.")")"
day1_objective="$(sanitize_inline "$(default_if_blank "$day1_objective" "Reinforce execution narrative on backup channel.")")"
day0_move="$(sanitize_inline "$(default_if_blank "$day0_move" "Publish proof-first post and log first 10 practical replies.")")"
day1_move="$(sanitize_inline "$(default_if_blank "$day1_move" "Ship backup-channel reinforcement and one creator follow-up burst.")")"
narrative_route_winner="$(sanitize_inline "$(default_if_blank "$narrative_route_winner" "n/a")")"
narrative_route_trend="$(sanitize_inline "$(default_if_blank "$narrative_route_trend" "n/a")")"
narrative_fame_velocity="$(sanitize_inline "$(default_if_blank "$narrative_fame_velocity" "n/a")")"
narrative_ranked_opportunity="$(sanitize_inline "$(default_if_blank "$narrative_ranked_opportunity" "$top_bet")")"
execution_mode="$(sanitize_inline "$(default_if_blank "$execution_mode" "General narrative momentum mode")")"
route_alignment_signal="$(sanitize_inline "$(default_if_blank "$route_alignment_signal" "n/a")")"
route_lane_status="$(sanitize_inline "$(default_if_blank "$route_lane_status" "n/a")")"
route_response_mode="$(sanitize_inline "$(default_if_blank "$route_response_mode" "Route Review")")"
route_guardrail="$(sanitize_inline "$(default_if_blank "$route_guardrail" "$routing_recommendation")")"
route_scale_action="$(sanitize_inline "$(default_if_blank "$route_scale_action" "Keep route winner and ranked opportunity locked while outreach lanes scale.")")"
creator_burst_lane="$(sanitize_inline "$(default_if_blank "$creator_burst_lane" "creator n/a, founder target n/a")")"
outreach_recommendation="$(sanitize_inline "$(default_if_blank "$outreach_recommendation" "Focus outreach on warm creator conversations and one follow-up pass.")")"
variant_recommendation="$(sanitize_inline "$(default_if_blank "$variant_recommendation" "Keep one control variant and iterate one challenger.")")"

guesting_top_target="$(sanitize_inline "$(default_if_blank "$guesting_top_target" "top-priority founder guesting target")")"
guesting_top_format="$(sanitize_inline "$(default_if_blank "$guesting_top_format" "podcast")")"
guesting_recommendation="$(sanitize_inline "$(default_if_blank "$guesting_recommendation" "Capture at least 5 founder guesting signals before Friday review.")")"
guesting_touch_goal="$(sanitize_inline "$(default_if_blank "$guesting_touch_goal" "5")")"
guesting_rank1="$(sanitize_inline "$(default_if_blank "$guesting_rank1" "Tier-1 operator podcast hosts aligned with the current founder narrative.")")"
guesting_rank2="$(sanitize_inline "$(default_if_blank "$guesting_rank2" "Newsletter editors who feature measurable operator experiments.")")"
guesting_day0="$(sanitize_inline "$(default_if_blank "$guesting_day0" "Day 0: Send top 5 pitches (2 podcasts, 2 newsletters, 1 community lead).")")"
guesting_day1="$(sanitize_inline "$(default_if_blank "$guesting_day1" "Day 1: Follow up on non-responders with one proof artifact.")")"

creator_top_segment="$(sanitize_inline "$(default_if_blank "$creator_top_segment" "workflow/tutorial creators")")"
creator_top_handle="$(sanitize_inline "$(default_if_blank "$creator_top_handle" "@top-creator-handle")")"
creator_signal_recommendation="$(sanitize_inline "$(default_if_blank "$creator_signal_recommendation" "Capture creator signal comments in Monday checklist before Friday review.")")"
creator_contact_day0="$(sanitize_inline "$(default_if_blank "$creator_contact_day0" "Day 0: Send top-5 targets from rank 1-2.")")"
creator_contact_day1="$(sanitize_inline "$(default_if_blank "$creator_contact_day1" "Day 1: Follow up with non-responders from rank 1.")")"
creator_contact_day2="$(sanitize_inline "$(default_if_blank "$creator_contact_day2" "Day 2: Send rank 3 newsletter pitches with one metric proof.")")"

distribution_lead_channel="$(sanitize_inline "$(default_if_blank "$distribution_lead_channel" "${primary_channel} (audience global)")")"
distribution_support_channel="$(sanitize_inline "$(default_if_blank "$distribution_support_channel" "${backup_channel} (audience global)")")"
distribution_reply_goal="$(sanitize_inline "$(default_if_blank "$distribution_reply_goal" "12")")"
distribution_outreach_goal="$(sanitize_inline "$(default_if_blank "$distribution_outreach_goal" "5")")"
distribution_day0_deliverable="$(sanitize_inline "$(default_if_blank "$distribution_day0_deliverable" "Publish one proof asset + command-led caption")")"
distribution_day1_deliverable="$(sanitize_inline "$(default_if_blank "$distribution_day1_deliverable" "Publish short variant + cross-link to Day 0 proof")")"
distribution_day2_deliverable="$(sanitize_inline "$(default_if_blank "$distribution_day2_deliverable" "Send top-priority outreach batch and one community comment")")"

media_weekly_narrative="$(sanitize_inline "$(default_if_blank "$media_weekly_narrative" "$top_bet")")"
media_current_focus="$(sanitize_inline "$(default_if_blank "$media_current_focus" "Turn one KPI bottleneck into one public proof narrative each week.")")"

weekly_outreach_goal_raw="$(extract_integer "$distribution_outreach_goal")"
weekly_reply_goal_raw="$(extract_integer "$distribution_reply_goal")"
guesting_touch_goal_raw="$(extract_integer "$guesting_touch_goal")"
creator_path_active="yes"
guesting_path_active="yes"
if [[ -z "$creator_target_list_path" ]]; then
  creator_path_active="no"
fi
if [[ -z "$guesting_queue_path" ]]; then
  guesting_path_active="no"
fi

weekly_outreach_goal="${weekly_outreach_goal_raw:-}"
if [[ -z "$weekly_outreach_goal" || "$weekly_outreach_goal" == "0" ]]; then
  weekly_outreach_goal=5
fi
weekly_reply_goal="${weekly_reply_goal_raw:-}"
if [[ -z "$weekly_reply_goal" || "$weekly_reply_goal" == "0" ]]; then
  weekly_reply_goal=12
fi
guesting_touch_goal_numeric="${guesting_touch_goal_raw:-}"
if [[ -z "$guesting_touch_goal_numeric" || "$guesting_touch_goal_numeric" == "0" ]]; then
  guesting_touch_goal_numeric="$weekly_outreach_goal"
fi

lane_strategy="$(resolve_lane_strategy "$breakout_lane_strategy" "$creator_burst_lane" "$outreach_recommendation" "$guesting_recommendation")"
if (( guesting_touch_goal_numeric > weekly_outreach_goal )); then
  lane_total_touches="$guesting_touch_goal_numeric"
else
  lane_total_touches="$weekly_outreach_goal"
fi
if (( lane_total_touches <= 0 )); then
  lane_total_touches=5
fi

creator_ratio="0.50"
guesting_ratio="0.50"
if [[ "$lane_strategy" == "creator-led" ]]; then
  creator_ratio="0.70"
  guesting_ratio="0.30"
elif [[ "$lane_strategy" == "guesting-led" ]]; then
  creator_ratio="0.35"
  guesting_ratio="0.65"
fi

creator_touch_target="$(round_to_int "$(awk -v total="$lane_total_touches" -v ratio="$creator_ratio" 'BEGIN { print total * ratio }')")"
if (( creator_touch_target < 1 )); then
  creator_touch_target=1
fi
guesting_touch_target=$(( lane_total_touches - creator_touch_target ))
if (( guesting_touch_target < 1 )); then
  guesting_touch_target=1
  creator_touch_target=$(( lane_total_touches - guesting_touch_target ))
  if (( creator_touch_target < 1 )); then
    creator_touch_target=1
    lane_total_touches=$(( creator_touch_target + guesting_touch_target ))
  fi
fi

if [[ "$creator_path_active" == "no" ]]; then
  creator_touch_target=0
  guesting_touch_target="$lane_total_touches"
fi
if [[ "$guesting_path_active" == "no" ]]; then
  guesting_touch_target=0
  creator_touch_target="$lane_total_touches"
fi
if [[ "$creator_path_active" == "no" && "$guesting_path_active" == "no" ]]; then
  creator_touch_target=0
  guesting_touch_target=0
fi

creator_collab_target=1
guesting_booking_target=1
if (( creator_touch_target >= 6 )); then
  creator_collab_target=2
fi
if (( guesting_touch_target >= 6 )); then
  guesting_booking_target=2
fi
daily_touch_floor="$(round_to_int "$(awk -v total="$lane_total_touches" 'BEGIN { print total / 3.0 }')")"
if (( daily_touch_floor < 2 )); then
  daily_touch_floor=2
fi

route_outreach_mode="Route-Locked Outreach"
route_alignment_target="Aligned"
route_lane_trigger="Escalate when route lane status drops below Watch in the next check-in."
route_touch_floor_adjustment=0
route_signal_lower="$(lowercase_value "$route_alignment_signal")"
route_lane_lower="$(lowercase_value "$route_lane_status")"
if print -r -- "$route_signal_lower $route_lane_lower" | rg -q -- '(drifting|critical|signal missing|missing)'; then
  route_outreach_mode="Route Correction Outreach"
  route_alignment_target="Partial or better"
  route_lane_trigger="Escalate immediately if route lane status remains Critical after one outreach cycle."
  route_touch_floor_adjustment=2
elif print -r -- "$route_signal_lower $route_lane_lower" | rg -q -- '(partial|watch|signal capture|fallback)'; then
  route_outreach_mode="Route Re-Lock Outreach"
  route_alignment_target="Aligned"
  route_lane_trigger="Escalate if route alignment remains Partial after Day 1 follow-up wave."
  route_touch_floor_adjustment=1
fi

if (( route_touch_floor_adjustment > 0 )); then
  daily_touch_floor=$(( daily_touch_floor + route_touch_floor_adjustment ))
  if (( daily_touch_floor > lane_total_touches )); then
    daily_touch_floor="$lane_total_touches"
  fi
fi
if (( daily_touch_floor < 2 )); then
  daily_touch_floor=2
fi

lane_mix_summary="creator ${creator_touch_target}, guesting ${guesting_touch_target}"
if [[ "$creator_path_active" == "no" ]]; then
  lane_mix_summary="creator overlay missing, guesting ${guesting_touch_target}"
fi
if [[ "$guesting_path_active" == "no" ]]; then
  lane_mix_summary="creator ${creator_touch_target}, guesting overlay missing"
fi
if [[ "$creator_path_active" == "no" && "$guesting_path_active" == "no" ]]; then
  lane_mix_summary="creator overlay missing, guesting overlay missing"
fi

lane_strategy_label="$lane_strategy"
if [[ "$lane_strategy" == "creator-led" ]]; then
  lane_strategy_label="creator-led (creator-first outreach week)"
elif [[ "$lane_strategy" == "guesting-led" ]]; then
  lane_strategy_label="guesting-led (booking-first outreach week)"
else
  lane_strategy_label="balanced (creator + guesting parity week)"
fi

product_name="$(sanitize_inline "$product_name")"
primary_channel="$(sanitize_inline "$primary_channel")"
backup_channel="$(sanitize_inline "$backup_channel")"
cta_text="$(sanitize_inline "$cta_text")"
lane_strategy_label="$(sanitize_inline "$lane_strategy_label")"
lane_mix_summary="$(sanitize_inline "$lane_mix_summary")"
route_outreach_mode="$(sanitize_inline "$route_outreach_mode")"
route_alignment_target="$(sanitize_inline "$route_alignment_target")"
route_lane_trigger="$(sanitize_inline "$route_lane_trigger")"
lane_total_touches="$(sanitize_inline "$lane_total_touches")"
creator_touch_target="$(sanitize_inline "$creator_touch_target")"
guesting_touch_target="$(sanitize_inline "$guesting_touch_target")"
weekly_reply_goal="$(sanitize_inline "$weekly_reply_goal")"
creator_collab_target="$(sanitize_inline "$creator_collab_target")"
guesting_booking_target="$(sanitize_inline "$guesting_booking_target")"
daily_touch_floor="$(sanitize_inline "$daily_touch_floor")"
route_touch_floor_adjustment="$(sanitize_inline "$route_touch_floor_adjustment")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

cat > "$output_path" <<EOF
<!-- founder-fame-outreach-sprint -->

# Founder Fame Outreach Sprint - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source breakout plan: ${breakout_plan_path}
Source guesting queue: ${guesting_queue_path:-n/a}
Source creator target list: ${creator_target_list_path:-n/a}
Source distribution plan: ${distribution_plan_path:-n/a}
Source media blast: ${media_blast_path:-n/a}

## Snapshot

- Breakout plan: ${breakout_heading}
- Guesting queue: ${guesting_heading}
- Creator target list: ${creator_target_heading}
- Distribution plan: ${distribution_heading}
- Media blast: ${media_blast_heading}
- Core narrative bet: ${top_bet}
- Breakout hook route: ${breakout_hook_route}
- Strongest proof signal: ${strongest_proof_signal}
- Narrative route winner: ${narrative_route_winner}
- Narrative route trend: ${narrative_route_trend}
- Narrative fame velocity: ${narrative_fame_velocity}
- Narrative-ranked opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment signal: ${route_alignment_signal}
- Route lane status: ${route_lane_status}
- Route response mode: ${route_response_mode}
- Creator priority: ${creator_top_segment} / ${creator_top_handle}
- Guesting priority: ${guesting_top_format} / ${guesting_top_target}
- Lane strategy: ${lane_strategy_label}
- Weekly touch mix: ${lane_mix_summary}
- Reply goal this week: ${weekly_reply_goal}

## Outreach Thesis

- Objective: Turn breakout publishing momentum into daily creator + guesting conversations.
- Narrative anchor: ${media_weekly_narrative}
- Routing recommendation: ${routing_recommendation}
- Creator burst lane: ${creator_burst_lane}
- Outreach recommendation: ${outreach_recommendation}
- Variant recommendation: ${variant_recommendation}
- Signal recommendation: ${creator_signal_recommendation}

## Narrative Route Outreach Controls

- Route outreach mode: ${route_outreach_mode}
- Route winner and trend: ${narrative_route_winner} (${narrative_route_trend})
- Route priority opportunity: ${narrative_ranked_opportunity}
- Execution mode: ${execution_mode}
- Route alignment target: ${route_alignment_target}
- Route guardrail: ${route_guardrail}
- Route scale action: ${route_scale_action}
- Route touch-floor adjustment: ${route_touch_floor_adjustment}
- Route lane trigger: ${route_lane_trigger}

## Lane Allocation Scorecard

- Lane strategy: ${lane_strategy_label}
- Weekly touch target total: ${lane_total_touches}
- Creator touch target: ${creator_touch_target}
- Guesting touch target: ${guesting_touch_target}
- Daily touch floor (Day 0-Day 2): ${daily_touch_floor}
- Practical reply target: ${weekly_reply_goal}
- Creator collab-ready target: ${creator_collab_target}
- Guesting booking-stage target: ${guesting_booking_target}
- Recommendation source: ${outreach_recommendation}
- Route alignment target: ${route_alignment_target}
- Route outreach mode: ${route_outreach_mode}

## 7-Day Outreach Sprint Grid

| Day | Goal | Lane | Core move | Success signal |
| --- | --- | --- | --- | --- |
| Day 0 | ${day0_objective} | ${distribution_lead_channel} + creator DMs | ${day0_move}; ${distribution_day0_deliverable} | 1 practical creator reply + 1 booking signal |
| Day 1 | ${day1_objective} | ${distribution_support_channel} + follow-up queue | ${day1_move}; ${distribution_day1_deliverable} | 1 warm intro or collab-ready handoff |
| Day 2 | Execute creator conversion wave | Creator target sprint | ${creator_contact_day2}; ${distribution_day2_deliverable} | 2 meaningful creator conversations move forward |
| Day 3 | Trigger guesting booking wave 1 | Podcasts + newsletters | ${guesting_rank1} | 1 booking-stage conversation |
| Day 4 | Trigger guesting booking wave 2 | Newsletters + communities | ${guesting_rank2} | 1 additional high-fit response |
| Day 5 | Publish proof recap + outreach ask | Primary + backup channels | Publish one recap with ${strongest_proof_signal} and direct outreach CTA | Outreach replies trend toward ${distribution_outreach_goal} |
| Day 6 | Lock next-week default script stack | Standup + issue update | Promote winner variant and assign owners for next sprint | Monday defaults are owner-assigned |

## Creator Conversation Blocks

### Primary Creator DM (${primary_channel})

This week’s creator pitch from ${product_name}: **${top_bet}**.

- Top segment: ${creator_top_segment}
- Priority handle: ${creator_top_handle}
- Hook lane: ${breakout_hook_route}
- First move: ${creator_contact_day0}

${cta_text}

### Creator Follow-Up (${backup_channel})

- Day 1 follow-up: ${creator_contact_day1}
- Signal reminder: ${creator_signal_recommendation}
- Proof line: ${strongest_proof_signal}
- Routing line: ${routing_recommendation}

${cta_text}

## Guesting Booking Blocks

- Priority format: ${guesting_top_format}
- Priority target: ${guesting_top_target}
- Recommendation: ${guesting_recommendation}
- Touch goal this week: ${guesting_touch_goal}
- Day 0 booking action: ${guesting_day0}
- Day 1 booking action: ${guesting_day1}

### Guesting Pitch Seed

Founder operating story for ${week_label}: ${media_weekly_narrative}.
Core proof signal: ${strongest_proof_signal}.
Current execution focus: ${media_current_focus}.
Ask: one booking slot for a practical founder teardown with measurable outcomes.

## Follow-Up Cadence

1. ${creator_contact_day0}
2. ${creator_contact_day1}
3. ${creator_contact_day2}
4. ${guesting_day0}
5. ${guesting_day1}
6. Publish one proof recap and tag top-priority collaborators.
7. Update Monday checklist with outcomes and next-week default variant.

## Daily Standup Prompts

1. Which outreach action today compounds the core narrative fastest?
2. Did yesterday’s outbound create practical replies, not vanity engagement?
3. Which objection repeated across creator and guesting conversations?
4. Which target moved to booked/collab-ready stage?
5. Is route lane status (${route_lane_status}) stable enough to open a new outreach lane?

## Execution Checklist

- [ ] Ship Day 0 proof-first post + creator outreach wave.
- [ ] Complete Day 1 backup-channel reinforcement + follow-ups.
- [ ] Send at least ${lane_total_touches} outreach touches this week (${lane_mix_summary}).
- [ ] Hit daily touch floor of ${daily_touch_floor} during Day 0-Day 2.
- [ ] Keep route lane at ${route_alignment_target} while executing outreach touch targets.
- [ ] Handle at least ${weekly_reply_goal} practical replies with command-level guidance.
- [ ] Move ${creator_collab_target} creator conversations to collab-ready.
- [ ] Move ${guesting_booking_target} guesting conversations to booking-stage.
- [ ] Trigger one guesting booking conversation by Day 3.
- [ ] Trigger one additional high-fit guesting response by Day 4.
- [ ] Promote one winning script variant into next-week default.
- [ ] Log outcomes in Monday checklist before Friday review.
EOF

echo "Generated founder fame outreach sprint: $output_path"
