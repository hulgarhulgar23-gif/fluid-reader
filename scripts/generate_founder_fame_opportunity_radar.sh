#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame opportunity radar from momentum and proof artifacts.

Usage:
  zsh scripts/generate_founder_fame_opportunity_radar.sh [options]

Required:
  --momentum-brief <path>        Founder fame momentum brief markdown

Optional:
  --weight-profile <path>        Founder fame weight profile markdown
  --uplift-tracker <path>        Founder fame uplift tracker markdown
  --winning-hook-library <path>  Weekly winning hook library markdown
  --credibility-ledger <path>    Weekly credibility ledger markdown
  --narrative-route-winner <text> Founder narrative route winner from Monday effectiveness
  --narrative-route-trend <text> Founder narrative route trend from Monday effectiveness
  --narrative-fame-velocity-score <value> Founder narrative fame velocity score (for ranking boost)
  --narrative-route-recommendation <text> Founder narrative recommendation line
  --week <label>                 Week label (default: inferred from momentum brief, then current ISO week)
  --product <text>               Product name (default: Fluid Reader)
  --out <path>                   Output path (default: docs/campaigns/<week>-founder-fame-opportunity-radar.md)
  -h, --help                     Show help

Example:
  zsh scripts/generate_founder_fame_opportunity_radar.sh \
    --momentum-brief docs/campaigns/2026-W24-founder-fame-momentum-brief.md \
    --weight-profile docs/campaigns/2026-W24-founder-fame-weight-profile.md \
    --uplift-tracker docs/campaigns/2026-W24-founder-fame-uplift-tracker.md \
    --winning-hook-library docs/campaigns/2026-W24-winning-hook-library.md \
    --credibility-ledger docs/campaigns/2026-W24-credibility-ledger.md \
    --out docs/campaigns/2026-W24-founder-fame-opportunity-radar.md
EOF
}

momentum_brief_path=""
weight_profile_path=""
uplift_tracker_path=""
winning_hook_library_path=""
credibility_ledger_path=""
narrative_route_winner=""
narrative_route_trend=""
narrative_fame_velocity_score=""
narrative_route_recommendation=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --momentum-brief)
      momentum_brief_path="${2:-}"
      shift 2
      ;;
    --weight-profile)
      weight_profile_path="${2:-}"
      shift 2
      ;;
    --uplift-tracker)
      uplift_tracker_path="${2:-}"
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
    --narrative-route-winner)
      narrative_route_winner="${2:-}"
      shift 2
      ;;
    --narrative-route-trend)
      narrative_route_trend="${2:-}"
      shift 2
      ;;
    --narrative-fame-velocity-score)
      narrative_fame_velocity_score="${2:-}"
      shift 2
      ;;
    --narrative-route-recommendation)
      narrative_route_recommendation="${2:-}"
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

if [[ -z "$momentum_brief_path" ]]; then
  echo "Missing required option: --momentum-brief" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$momentum_brief_path" ]]; then
  echo "Momentum brief file not found: $momentum_brief_path" >&2
  exit 1
fi

for optional_path in "$weight_profile_path" "$uplift_tracker_path" "$winning_hook_library_path" "$credibility_ledger_path"; do
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

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi

  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
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

extract_week_from_momentum_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Momentum Brief - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Momentum Brief - "}"
}

extract_numbered_line() {
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
        sub(/^[0-9]+\.[[:space:]]*/, "", $0)
        print $0
        exit
      }
    }
  ' "$source_path"
}

extract_section_prefixed_value() {
  local source_path="$1"
  local section_heading="$2"
  local prefix="$3"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi

  awk -v heading="$section_heading" -v prefix="$prefix" '
    $0 == heading { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^### / && $0 != heading { exit }
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

extract_checklist_line() {
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
    in_section && /^- \[ \]/ {
      count++
      if (count == target) {
        sub(/^- \[ \][[:space:]]*/, "", $0)
        print $0
        exit
      }
    }
  ' "$source_path"
}

extract_table_confidence_score() {
  local source_path="$1"
  local dimension="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -F'|' -v dimension="$dimension" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    $0 ~ /^\|/ {
      row_dimension = clean($2)
      confidence = clean($4)
      if (row_dimension == dimension) {
        gsub(/[^0-9.+-]/, "", confidence)
        print confidence
        exit
      }
    }
  ' "$source_path"
}

normalize_score() {
  local raw_value="$1"
  local fallback="$2"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    parsed="$fallback"
  fi
  awk -v value="$parsed" 'BEGIN {
    adjusted = value + 0
    if (adjusted < 0) adjusted = 0
    if (adjusted > 100) adjusted = 100
    printf "%.0f", adjusted
  }'
}

normalize_multiplier() {
  local raw_value="$1"
  local fallback="$2"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    parsed="$fallback"
  fi
  awk -v value="$parsed" 'BEGIN {
    adjusted = value + 0
    if (adjusted <= 0) adjusted = 1.0
    if (adjusted < 0.8) adjusted = 0.8
    if (adjusted > 1.35) adjusted = 1.35
    printf "%.3f", adjusted
  }'
}

average_two_scores() {
  local a="$1"
  local b="$2"
  awk -v a="$a" -v b="$b" 'BEGIN {
    printf "%.0f", ((a + 0) + (b + 0)) / 2.0
  }'
}

calculate_priority() {
  local impact="$1"
  local confidence="$2"
  local effort="$3"
  awk -v impact="$impact" -v confidence="$confidence" -v effort="$effort" 'BEGIN {
    priority = (impact * 0.52) + (confidence * 0.30) + ((100 - effort) * 0.18)
    if (priority < 0) priority = 0
    if (priority > 100) priority = 100
    printf "%.0f", priority
  }'
}

sanitize_cell() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//|//}"
  value="${value//\`/}"
  echo "$value"
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

resolve_narrative_preferred_opportunity() {
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

compute_narrative_priority_boost() {
  local route="$1"
  local trend lowered_trend velocity velocity_integer recommendation lowered_recommendation
  local boost=0

  if [[ "$route" == "n/a" ]]; then
    echo "0"
    return
  fi

  trend="$(trim_value "$2")"
  lowered_trend="${trend:l}"
  velocity="$(extract_number "$3")"
  velocity_integer=""
  if [[ -n "$velocity" ]]; then
    velocity_integer="$(awk -v value="$velocity" 'BEGIN { printf "%.0f", value + 0 }')"
  fi
  recommendation="$(trim_value "$4")"
  lowered_recommendation="${recommendation:l}"

  boost=4
  if [[ -n "$velocity_integer" ]]; then
    if (( velocity_integer >= 75 )); then
      boost=$((boost + 5))
    elif (( velocity_integer >= 65 )); then
      boost=$((boost + 3))
    elif (( velocity_integer >= 55 )); then
      boost=$((boost + 2))
    fi
  fi

  if [[ "$lowered_trend" == shifted\ from* ]]; then
    boost=$((boost + 2))
  fi

  if [[ "$lowered_recommendation" == *"scale it across both channels"* ]]; then
    boost=$((boost + 1))
  fi

  if (( boost > 12 )); then
    boost=12
  fi
  if (( boost < 0 )); then
    boost=0
  fi
  echo "$boost"
}

apply_priority_boost() {
  local value="$1"
  local boost="$2"
  awk -v value="$value" -v boost="$boost" 'BEGIN {
    adjusted = (value + 0) + (boost + 0)
    if (adjusted < 0) adjusted = 0
    if (adjusted > 100) adjusted = 100
    printf "%.0f", adjusted
  }'
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_momentum_heading "$momentum_brief_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-opportunity-radar.md"
fi

momentum_heading="$(extract_heading "$momentum_brief_path")"
weight_heading="$(extract_heading "$weight_profile_path")"
uplift_heading="$(extract_heading "$uplift_tracker_path")"
hook_heading="$(extract_heading "$winning_hook_library_path")"
credibility_heading="$(extract_heading "$credibility_ledger_path")"

readiness_line="$(extract_prefixed_value "$momentum_brief_path" "- Fame readiness score: ")"
momentum_core_line="$(extract_prefixed_value "$momentum_brief_path" "- Momentum core: ")"
distribution_health_line="$(extract_prefixed_value "$momentum_brief_path" "- Distribution health: ")"
kpi_trendline_line="$(extract_prefixed_value "$momentum_brief_path" "- KPI trendline: ")"
reply_quality_line="$(extract_prefixed_value "$momentum_brief_path" "- Reply quality: ")"
transcript_quality_line="$(extract_prefixed_value "$momentum_brief_path" "- Transcript quality: ")"
weakest_signal_line="$(extract_prefixed_value "$momentum_brief_path" "- Weakest signal now: ")"
routing_recommendation_line="$(extract_prefixed_value "$momentum_brief_path" "- Routing recommendation: ")"
primary_risk_call_line="$(extract_prefixed_value "$momentum_brief_path" "- Primary risk call: ")"
strongest_metric_line="$(extract_prefixed_value "$momentum_brief_path" "- Strongest metric: ")"

core_hook_line="$(extract_numbered_line "$momentum_brief_path" "## Narrative Stack" 1)"
first_objection_line="$(extract_numbered_line "$momentum_brief_path" "## Narrative Stack" 6)"
first_clip_line="$(extract_numbered_line "$momentum_brief_path" "## Narrative Stack" 7)"
friction_line="$(extract_prefixed_value "$momentum_brief_path" "- Friction to resolve first: ")"

weight_mode_line="$(extract_prefixed_value "$weight_profile_path" "- Mode: ")"
top_pressure_line="$(extract_prefixed_value "$weight_profile_path" "- Top pressure signal: ")"
applied_weight_vector_line="$(extract_prefixed_value "$weight_profile_path" "- Applied weight vector: ")"

uplift_mode_line="$(extract_prefixed_value "$uplift_tracker_path" "- Mode: ")"
top_leading_signal_line="$(extract_prefixed_value "$uplift_tracker_path" "- Top leading signal: ")"
uplift_momentum_line="$(extract_prefixed_value "$uplift_tracker_path" "- momentum uplift multiplier: ")"
uplift_distribution_line="$(extract_prefixed_value "$uplift_tracker_path" "- distribution uplift multiplier: ")"
uplift_kpi_line="$(extract_prefixed_value "$uplift_tracker_path" "- kpi trendline uplift multiplier: ")"
uplift_reply_line="$(extract_prefixed_value "$uplift_tracker_path" "- reply quality uplift multiplier: ")"
uplift_transcript_line="$(extract_prefixed_value "$uplift_tracker_path" "- transcript quality uplift multiplier: ")"

hook_a_type_line="$(extract_section_prefixed_value "$winning_hook_library_path" "### Hook A" "- Hook type: ")"
hook_a_channel_line="$(extract_section_prefixed_value "$winning_hook_library_path" "### Hook A" "- Lead channel: ")"
hook_a_seed_line="$(extract_section_prefixed_value "$winning_hook_library_path" "### Hook A" "- Script seed: ")"
hook_a_why_line="$(extract_section_prefixed_value "$winning_hook_library_path" "### Hook A" "- Why now: ")"
variant_recommendation_line="$(extract_prefixed_value "$winning_hook_library_path" "- Variant recommendation: ")"
outreach_recommendation_line="$(extract_prefixed_value "$winning_hook_library_path" "- Outreach recommendation: ")"

credibility_distribution_line="$(extract_prefixed_value "$credibility_ledger_path" "- Distribution completion score: ")"
credibility_mix_line="$(extract_prefixed_value "$credibility_ledger_path" "- Channel mix recommendation: ")"
proof_action_line="$(extract_checklist_line "$credibility_ledger_path" "## Next Proof Actions" 1)"
outcome_confidence_line="$(extract_table_confidence_score "$credibility_ledger_path" "Outcome reliability")"
objection_confidence_line="$(extract_table_confidence_score "$credibility_ledger_path" "Objection resolution")"
distribution_confidence_line="$(extract_table_confidence_score "$credibility_ledger_path" "Distribution consistency")"

readiness_score="$(normalize_score "$readiness_line" 54)"
momentum_score="$(normalize_score "$momentum_core_line" 60)"
distribution_score="$(normalize_score "$distribution_health_line" 50)"
kpi_score="$(normalize_score "$kpi_trendline_line" 55)"
reply_score="$(normalize_score "$reply_quality_line" 52)"
transcript_score="$(normalize_score "$transcript_quality_line" 60)"

momentum_multiplier="$(normalize_multiplier "$uplift_momentum_line" 1.000)"
distribution_multiplier="$(normalize_multiplier "$uplift_distribution_line" 1.000)"
kpi_multiplier="$(normalize_multiplier "$uplift_kpi_line" 1.000)"
reply_multiplier="$(normalize_multiplier "$uplift_reply_line" 1.000)"
transcript_multiplier="$(normalize_multiplier "$uplift_transcript_line" 1.000)"

outcome_confidence="$(normalize_score "$outcome_confidence_line" 58)"
objection_confidence="$(normalize_score "$objection_confidence_line" 55)"
distribution_confidence="$(normalize_score "$distribution_confidence_line" 52)"
narrative_confidence="$(average_two_scores "$outcome_confidence" "$objection_confidence")"

distribution_impact="$(awk -v score="$distribution_score" -v readiness="$readiness_score" -v multiplier="$distribution_multiplier" 'BEGIN {
  impact = ((100 - score) * multiplier) + ((100 - readiness) * 0.25)
  if (impact < 0) impact = 0
  if (impact > 100) impact = 100
  printf "%.0f", impact
}')"

objection_impact="$(awk -v score="$reply_score" -v readiness="$readiness_score" -v multiplier="$reply_multiplier" 'BEGIN {
  impact = ((100 - score) * multiplier) + ((100 - readiness) * 0.20)
  if (impact < 0) impact = 0
  if (impact > 100) impact = 100
  printf "%.0f", impact
}')"

proof_impact="$(awk -v score="$kpi_score" -v readiness="$readiness_score" -v multiplier="$kpi_multiplier" 'BEGIN {
  impact = ((100 - score) * multiplier) + ((100 - readiness) * 0.18)
  if (impact < 0) impact = 0
  if (impact > 100) impact = 100
  printf "%.0f", impact
}')"

narrative_impact="$(awk -v transcript="$transcript_score" -v momentum="$momentum_score" -v multiplier="$transcript_multiplier" 'BEGIN {
  leverage = ((transcript * 0.55) + (momentum * 0.45)) * multiplier
  if (leverage < 0) leverage = 0
  if (leverage > 100) leverage = 100
  printf "%.0f", leverage
}')"

distribution_effort=62
objection_effort=46
proof_effort=51
narrative_effort=38

distribution_priority="$(calculate_priority "$distribution_impact" "$distribution_confidence" "$distribution_effort")"
objection_priority="$(calculate_priority "$objection_impact" "$objection_confidence" "$objection_effort")"
proof_priority="$(calculate_priority "$proof_impact" "$outcome_confidence" "$proof_effort")"
narrative_priority="$(calculate_priority "$narrative_impact" "$narrative_confidence" "$narrative_effort")"

normalized_narrative_route_winner="$(normalize_narrative_route "${narrative_route_winner:-}")"
narrative_route_trend_value="$(trim_value "${narrative_route_trend:-}")"
if [[ -z "$narrative_route_trend_value" ]]; then
  narrative_route_trend_value="n/a"
fi
narrative_fame_velocity_score_value="$(trim_value "${narrative_fame_velocity_score:-}")"
if [[ -z "$narrative_fame_velocity_score_value" ]]; then
  narrative_fame_velocity_score_value="n/a"
fi
narrative_route_recommendation_value="$(trim_value "${narrative_route_recommendation:-}")"
if [[ -z "$narrative_route_recommendation_value" ]]; then
  narrative_route_recommendation_value="n/a"
fi
narrative_preferred_opportunity="$(resolve_narrative_preferred_opportunity "$normalized_narrative_route_winner")"
narrative_priority_boost="$(compute_narrative_priority_boost "$normalized_narrative_route_winner" "$narrative_route_trend_value" "$narrative_fame_velocity_score_value" "$narrative_route_recommendation_value")"
narrative_boost_reason="No narrative route winner detected; opportunity ranking uses default momentum + proof scoring."
if [[ "$narrative_preferred_opportunity" != "n/a" && "$narrative_priority_boost" != "0" ]]; then
  narrative_boost_reason="Narrative route winner (${normalized_narrative_route_winner}) boosts ${narrative_preferred_opportunity} by +${narrative_priority_boost} priority points."
fi

distribution_priority_base="$distribution_priority"
objection_priority_base="$objection_priority"
proof_priority_base="$proof_priority"
narrative_priority_base="$narrative_priority"
selected_priority_before="n/a"
selected_priority_after="n/a"

if [[ "$narrative_preferred_opportunity" == "Distribution Recovery Sprint" ]]; then
  distribution_priority="$(apply_priority_boost "$distribution_priority" "$narrative_priority_boost")"
  selected_priority_before="$distribution_priority_base"
  selected_priority_after="$distribution_priority"
elif [[ "$narrative_preferred_opportunity" == "Objection Crush Sequence" ]]; then
  objection_priority="$(apply_priority_boost "$objection_priority" "$narrative_priority_boost")"
  selected_priority_before="$objection_priority_base"
  selected_priority_after="$objection_priority"
elif [[ "$narrative_preferred_opportunity" == "KPI Proof Amplifier" ]]; then
  proof_priority="$(apply_priority_boost "$proof_priority" "$narrative_priority_boost")"
  selected_priority_before="$proof_priority_base"
  selected_priority_after="$proof_priority"
elif [[ "$narrative_preferred_opportunity" == "Narrative Compounding Loop" ]]; then
  narrative_priority="$(apply_priority_boost "$narrative_priority" "$narrative_priority_boost")"
  selected_priority_before="$narrative_priority_base"
  selected_priority_after="$narrative_priority"
fi

if [[ "$selected_priority_before" != "n/a" && "$selected_priority_after" != "n/a" ]]; then
  narrative_boost_reason="Narrative route winner (${normalized_narrative_route_winner}) boosts ${narrative_preferred_opportunity}: ${selected_priority_before} -> ${selected_priority_after} (+${narrative_priority_boost})."
fi

if [[ -z "$hook_a_seed_line" || "$hook_a_seed_line" == "n/a" ]]; then
  hook_a_seed_line="$core_hook_line"
fi
if [[ -z "$hook_a_seed_line" || "$hook_a_seed_line" == "n/a" ]]; then
  hook_a_seed_line="Founder proof-first narrative with one measurable outcome."
fi
if [[ -z "$proof_action_line" ]]; then
  proof_action_line="Publish one metric-backed proof post with exact workflow steps."
fi
if [[ -z "$first_objection_line" ]]; then
  first_objection_line="$friction_line"
fi
if [[ -z "$first_objection_line" || "$first_objection_line" == "n/a" ]]; then
  first_objection_line="Address the top objection with one proof-backed thread."
fi
if [[ -z "$first_clip_line" ]]; then
  first_clip_line="Cut one quote-led 20-40s founder clip."
fi

opportunities_file="${TMPDIR:-/tmp}/fluidreader-founder-opportunity-radar.${$}.${RANDOM}.txt"
sorted_opportunities_file="${TMPDIR:-/tmp}/fluidreader-founder-opportunity-radar-sorted.${$}.${RANDOM}.txt"
cleanup() {
  rm -f "$opportunities_file" "$sorted_opportunities_file"
}
trap cleanup EXIT

touch "$opportunities_file"

echo "Distribution Recovery Sprint|$distribution_impact|$distribution_confidence|$distribution_effort|$distribution_priority|Distribution owner|$(sanitize_cell "$proof_action_line")|$(sanitize_cell "$hook_a_seed_line")|$(sanitize_cell "$primary_risk_call_line")" >> "$opportunities_file"
echo "Objection Crush Sequence|$objection_impact|$objection_confidence|$objection_effort|$objection_priority|Founder + community lead|$(sanitize_cell "$first_objection_line")|$(sanitize_cell "$hook_a_seed_line")|$(sanitize_cell "$friction_line")" >> "$opportunities_file"
echo "KPI Proof Amplifier|$proof_impact|$outcome_confidence|$proof_effort|$proof_priority|Founder + product marketing|$(sanitize_cell "$strongest_metric_line")|$(sanitize_cell "$variant_recommendation_line")|$(sanitize_cell "$routing_recommendation_line")" >> "$opportunities_file"
echo "Narrative Compounding Loop|$narrative_impact|$narrative_confidence|$narrative_effort|$narrative_priority|Content + media owner|$(sanitize_cell "$first_clip_line")|$(sanitize_cell "$hook_a_seed_line")|$(sanitize_cell "$outreach_recommendation_line")" >> "$opportunities_file"

sort -t'|' -k5,5nr "$opportunities_file" > "$sorted_opportunities_file"

extract_rank_line() {
  local rank="$1"
  sed -n "${rank}p" "$sorted_opportunities_file"
}

extract_field() {
  local line="$1"
  local index="$2"
  print -r -- "$line" | awk -F'|' -v index="$index" '{ print $index }'
}

rank1_line="$(extract_rank_line 1)"
rank2_line="$(extract_rank_line 2)"
rank3_line="$(extract_rank_line 3)"

rank1_name="$(extract_field "$rank1_line" 1)"
rank1_impact="$(extract_field "$rank1_line" 2)"
rank1_confidence="$(extract_field "$rank1_line" 3)"
rank1_effort="$(extract_field "$rank1_line" 4)"
rank1_priority="$(extract_field "$rank1_line" 5)"
rank1_owner="$(extract_field "$rank1_line" 6)"
rank1_first_move="$(extract_field "$rank1_line" 7)"
rank1_proof_anchor="$(extract_field "$rank1_line" 8)"
rank1_guardrail="$(extract_field "$rank1_line" 9)"

rank2_name="$(extract_field "$rank2_line" 1)"
rank2_impact="$(extract_field "$rank2_line" 2)"
rank2_confidence="$(extract_field "$rank2_line" 3)"
rank2_effort="$(extract_field "$rank2_line" 4)"
rank2_priority="$(extract_field "$rank2_line" 5)"
rank2_owner="$(extract_field "$rank2_line" 6)"
rank2_first_move="$(extract_field "$rank2_line" 7)"
rank2_proof_anchor="$(extract_field "$rank2_line" 8)"
rank2_guardrail="$(extract_field "$rank2_line" 9)"

rank3_name="$(extract_field "$rank3_line" 1)"
rank3_impact="$(extract_field "$rank3_line" 2)"
rank3_confidence="$(extract_field "$rank3_line" 3)"
rank3_effort="$(extract_field "$rank3_line" 4)"
rank3_priority="$(extract_field "$rank3_line" 5)"
rank3_owner="$(extract_field "$rank3_line" 6)"
rank3_first_move="$(extract_field "$rank3_line" 7)"
rank3_proof_anchor="$(extract_field "$rank3_line" 8)"
rank3_guardrail="$(extract_field "$rank3_line" 9)"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-opportunity-radar -->

# Founder Fame Opportunity Radar - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source momentum brief: ${momentum_brief_path}
Source weight profile: ${weight_profile_path:-n/a}
Source uplift tracker: ${uplift_tracker_path:-n/a}
Source winning hook library: ${winning_hook_library_path:-n/a}
Source credibility ledger: ${credibility_ledger_path:-n/a}

## Snapshot

- Momentum brief: ${momentum_heading}
- Weight profile: ${weight_heading}
- Uplift tracker: ${uplift_heading}
- Winning hook library: ${hook_heading}
- Credibility ledger: ${credibility_heading}
- Fame readiness score: ${readiness_line}
- Weakest signal now: ${weakest_signal_line}
- Top pressure signal: ${top_pressure_line}
- Top leading signal: ${top_leading_signal_line}
- Weight mode: ${weight_mode_line}
- Uplift mode: ${uplift_mode_line}
- Applied weight vector: ${applied_weight_vector_line}
- Channel mix recommendation: ${credibility_mix_line}
- Routing recommendation: ${routing_recommendation_line}
- Founder narrative route winner: ${normalized_narrative_route_winner}
- Founder narrative route trend: ${narrative_route_trend_value}
- Founder narrative fame velocity score: ${narrative_fame_velocity_score_value}
- Founder narrative recommendation: ${narrative_route_recommendation_value}
- Narrative-ranked opportunity: ${narrative_preferred_opportunity} (+${narrative_priority_boost} priority boost)
- Narrative ranking reason: ${narrative_boost_reason}

## Ranked Opportunities

| Rank | Opportunity | Impact | Confidence | Effort | Priority | Suggested owner |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| 1 | ${rank1_name} | ${rank1_impact} | ${rank1_confidence} | ${rank1_effort} | ${rank1_priority} | ${rank1_owner} |
| 2 | ${rank2_name} | ${rank2_impact} | ${rank2_confidence} | ${rank2_effort} | ${rank2_priority} | ${rank2_owner} |
| 3 | ${rank3_name} | ${rank3_impact} | ${rank3_confidence} | ${rank3_effort} | ${rank3_priority} | ${rank3_owner} |

## Action Plans

### 1) ${rank1_name}

- First move: ${rank1_first_move}
- Proof anchor: ${rank1_proof_anchor}
- Guardrail: ${rank1_guardrail}

### 2) ${rank2_name}

- First move: ${rank2_first_move}
- Proof anchor: ${rank2_proof_anchor}
- Guardrail: ${rank2_guardrail}

### 3) ${rank3_name}

- First move: ${rank3_first_move}
- Proof anchor: ${rank3_proof_anchor}
- Guardrail: ${rank3_guardrail}

## Weekly Fame Bet

- Bet: ${rank1_name}
- Priority score: ${rank1_priority}/100
- Owner: ${rank1_owner}
- Ship in first 24 hours: ${rank1_first_move}
- Lead script seed: ${hook_a_type_line} on ${hook_a_channel_line}
- Hook seed: ${hook_a_seed_line}
- Why now: ${hook_a_why_line}
- Narrative route alignment: ${normalized_narrative_route_winner} -> ${narrative_preferred_opportunity} (+${narrative_priority_boost})

## Share Block

\`\`\`text
Founder fame opportunity radar (${week_label})
Top bet: ${rank1_name} (${rank1_priority}/100)
Owner: ${rank1_owner}
First move: ${rank1_first_move}
Guardrail: ${rank1_guardrail}
Routing: ${routing_recommendation_line}
Narrative route: ${normalized_narrative_route_winner} (boosted target: ${narrative_preferred_opportunity}, +${narrative_priority_boost})
Uplift mode: ${uplift_mode_line}
\`\`\`
EOF

echo "Wrote founder fame opportunity radar: $output_path"
