#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame momentum brief from founder distribution artifacts.

Usage:
  zsh scripts/generate_founder_fame_momentum_brief.sh [options]

Required:
  --fame-pack <path>            Founder fame pack markdown
  --repurpose-plan <path>       Founder fame repurpose plan markdown

Optional:
  --transcript-ingestion <path> Founder fame transcript ingestion markdown
  --press-kit <path>            Founder press kit markdown
  --media-blast <path>          Founder media blast markdown
  --credibility-ledger <path>   Credibility ledger markdown
  --weight-profile <path>       Founder fame signal weight profile markdown
  --week <label>                Week label (default: inferred from fame pack heading, then current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-momentum-brief.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_momentum_brief.sh \
    --fame-pack docs/campaigns/2026-W23-founder-fame-pack.md \
    --repurpose-plan docs/campaigns/2026-W23-founder-fame-repurpose-plan.md \
    --transcript-ingestion docs/campaigns/2026-W23-founder-fame-transcript-ingestion.md \
    --weight-profile docs/campaigns/2026-W23-founder-fame-weight-profile.md \
    --out docs/campaigns/2026-W23-founder-fame-momentum-brief.md
EOF
}

fame_pack_path=""
repurpose_plan_path=""
transcript_ingestion_path=""
press_kit_path=""
media_blast_path=""
credibility_ledger_path=""
weight_profile_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --fame-pack)
      fame_pack_path="${2:-}"
      shift 2
      ;;
    --repurpose-plan)
      repurpose_plan_path="${2:-}"
      shift 2
      ;;
    --transcript-ingestion)
      transcript_ingestion_path="${2:-}"
      shift 2
      ;;
    --press-kit)
      press_kit_path="${2:-}"
      shift 2
      ;;
    --media-blast)
      media_blast_path="${2:-}"
      shift 2
      ;;
    --credibility-ledger)
      credibility_ledger_path="${2:-}"
      shift 2
      ;;
    --weight-profile)
      weight_profile_path="${2:-}"
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

for pair in \
  "fame_pack_path:$fame_pack_path" \
  "repurpose_plan_path:$repurpose_plan_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

for required_file in "$fame_pack_path" "$repurpose_plan_path"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

for optional_file in "$transcript_ingestion_path" "$press_kit_path" "$media_blast_path" "$credibility_ledger_path" "$weight_profile_path"; do
  if [[ -n "$optional_file" && ! -f "$optional_file" ]]; then
    echo "Optional source file not found: $optional_file" >&2
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

extract_week_from_fame_pack() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Pack - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Pack - "}"
}

extract_number() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true)"
  echo "$number"
}

clamp_score() {
  local value="$1"
  awk -v value="$value" 'BEGIN {
    adjusted = value + 0
    if (adjusted < 0) adjusted = 0
    if (adjusted > 100) adjusted = 100
    printf "%.0f", adjusted
  }'
}

round_number() {
  local value="$1"
  awk -v value="$value" 'BEGIN { printf "%.0f", value + 0 }'
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

extract_metric_line() {
  local source_path="$1"
  local metric_name="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi
  rg -m1 -F -- "- ${metric_name}: " "$source_path" || true
}

extract_metric_delta() {
  local source_path="$1"
  local metric_name="$2"
  local metric_line
  metric_line="$(extract_metric_line "$source_path" "$metric_name")"
  if [[ -z "$metric_line" ]]; then
    echo ""
    return
  fi
  print -r -- "$metric_line" | sed -nE 's/.*delta ([^,)]*).*/\1/p'
}

extract_metric_status() {
  local source_path="$1"
  local metric_name="$2"
  local metric_line
  metric_line="$(extract_metric_line "$source_path" "$metric_name")"
  if [[ -z "$metric_line" ]]; then
    echo ""
    return
  fi
  print -r -- "$metric_line" | sed -nE 's/.*status ([^,)]*).*/\1/p'
}

score_from_status() {
  local status_label="${1:l}"
  if [[ -z "$status_label" ]]; then
    echo ""
    return
  fi

  case "$status_label" in
    *on*track*)
      echo "86"
      ;;
    *at*risk*)
      echo "62"
      ;;
    *off*track*)
      echo "34"
      ;;
    *)
      echo "58"
      ;;
  esac
}

metric_delta_direction_score() {
  local metric_name="$1"
  local delta_value="$2"
  local delta_number
  delta_number="$(extract_number "$delta_value")"
  if [[ -z "$delta_number" ]]; then
    echo ""
    return
  fi

  clamp_score "$(awk -v metric="$metric_name" -v delta="$delta_number" 'BEGIN {
    score = 55
    if (metric == "CAC") {
      if (delta < 0) score = 86
      else if (delta > 0) score = 24
      else score = 60
    } else {
      if (delta > 0) score = 86
      else if (delta < 0) score = 24
      else score = 60
    }
    printf "%.4f", score
  }')"
}

average_scores() {
  local total=0
  local count=0
  local value
  for value in "$@"; do
    if [[ -n "$value" ]]; then
      total=$((total + value))
      count=$((count + 1))
    fi
  done
  if (( count == 0 )); then
    echo ""
    return
  fi
  echo $(( total / count ))
}

extract_slash_number() {
  local line_value="$1"
  local index="$2"
  if [[ -z "$line_value" || "$line_value" == "n/a" ]]; then
    echo ""
    return
  fi
  print -r -- "$line_value" | awk -F'/' -v idx="$index" '
    {
      if (idx > NF) exit
      value = $idx
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      gsub(/[^0-9.+-]/, "", value)
      if (value != "") print value
    }
  '
}

score_from_engagement_triplet() {
  local replies="$1"
  local objections="$2"
  local docs_updates="$3"

  if [[ -z "$replies" && -z "$objections" && -z "$docs_updates" ]]; then
    echo ""
    return
  fi

  if [[ -z "$replies" ]]; then replies=0; fi
  if [[ -z "$objections" ]]; then objections=0; fi
  if [[ -z "$docs_updates" ]]; then docs_updates=0; fi

  clamp_score "$(awk -v replies="$replies" -v objections="$objections" -v docs="$docs_updates" 'BEGIN {
    score = 46 + (replies * 1.2) + (objections * 0.8) + (docs * 6.5)
    printf "%.4f", score
  }')"
}

extract_scoreboard_count() {
  local scoreboard_value="$1"
  local state_label="$2"
  if [[ -z "$scoreboard_value" || "$scoreboard_value" == "n/a" ]]; then
    echo ""
    return
  fi

  print -r -- "$scoreboard_value" | awk -v label="$state_label" '
    {
      pattern = "([0-9]+)[[:space:]]+" label
      if (match($0, pattern)) {
        value = substr($0, RSTART, RLENGTH)
        gsub(/[^0-9]/, "", value)
        print value
      }
    }
  '
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_fame_pack "$fame_pack_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-momentum-brief.md"
fi

fame_pack_heading="$(extract_heading "$fame_pack_path")"
repurpose_heading="$(extract_heading "$repurpose_plan_path")"
transcript_heading="$(extract_heading "$transcript_ingestion_path")"
press_heading="$(extract_heading "$press_kit_path")"
media_heading="$(extract_heading "$media_blast_path")"
credibility_heading="$(extract_heading "$credibility_ledger_path")"
weight_profile_heading="$(extract_heading "$weight_profile_path")"

momentum_score_line="$(extract_prefixed_value "$fame_pack_path" "- Momentum score: ")"
scoreboard_state="$(extract_prefixed_value "$fame_pack_path" "- Scoreboard state: ")"
weekly_summary="$(extract_prefixed_value "$fame_pack_path" "- Weekly summary: ")"
current_focus="$(extract_prefixed_value "$fame_pack_path" "- Current focus: ")"

metric_focus="$(extract_prefixed_value "$repurpose_plan_path" "- Metric focus: ")"
strongest_metric="$(extract_prefixed_value "$repurpose_plan_path" "- Strongest metric: ")"
weekly_narrative="$(extract_prefixed_value "$repurpose_plan_path" "- Weekly narrative: ")"
mix_recommendation="$(extract_prefixed_value "$repurpose_plan_path" "- Mix recommendation: ")"

quote_anchor_a="$(extract_prefixed_value "$repurpose_plan_path" "- Quote anchor A: ")"
objection_first="$(extract_prefixed_value "$repurpose_plan_path" "- Objection to handle first: ")"
clip_candidate_1="$(extract_prefixed_value "$repurpose_plan_path" "- First clip candidate: ")"

if [[ "$quote_anchor_a" == "n/a" ]]; then
  quote_anchor_a="$(extract_numbered_line "$transcript_ingestion_path" "## Transcript Quote Bank" 1)"
  quote_anchor_a="$(trim_value "$quote_anchor_a")"
fi
if [[ "$objection_first" == "n/a" ]]; then
  objection_first="$(extract_numbered_line "$transcript_ingestion_path" "## Objection Radar" 1)"
  objection_first="$(trim_value "$objection_first")"
fi
if [[ "$clip_candidate_1" == "n/a" ]]; then
  clip_candidate_1="$(extract_numbered_line "$transcript_ingestion_path" "## Clip Candidate List" 1)"
  clip_candidate_1="$(trim_value "$clip_candidate_1")"
fi

headline_a="$(extract_prefixed_value "$media_blast_path" "- Headline A: ")"
headline_b="$(extract_prefixed_value "$media_blast_path" "- Headline B: ")"
press_angle_1="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 1)"
press_angle_2="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 2)"

distribution_completion_score="$(extract_prefixed_value "$credibility_ledger_path" "- Distribution completion score: ")"
credibility_mix_recommendation="$(extract_prefixed_value "$credibility_ledger_path" "- Channel mix recommendation: ")"
engagement_metrics_line="$(extract_prefixed_value "$credibility_ledger_path" "- Engagement metrics (replies / objections / docs updates): ")"
transcript_quality_score_line="$(extract_prefixed_value "$transcript_ingestion_path" "- Transcript quality score: ")"
quote_candidates_detected_line="$(extract_prefixed_value "$transcript_ingestion_path" "- Quote candidates detected: ")"
objection_candidates_detected_line="$(extract_prefixed_value "$transcript_ingestion_path" "- Objection candidates detected: ")"
speaker_candidates_detected_line="$(extract_prefixed_value "$transcript_ingestion_path" "- Distinct speakers detected: ")"

outcome_reliability_score="$(extract_table_confidence_score "$credibility_ledger_path" "Outcome reliability")"
objection_resolution_score="$(extract_table_confidence_score "$credibility_ledger_path" "Objection resolution")"
distribution_consistency_signal_score="$(extract_table_confidence_score "$credibility_ledger_path" "Distribution consistency")"

profile_samples_line="$(extract_prefixed_value "$weight_profile_path" "- Samples analyzed: ")"
profile_mode_line="$(extract_prefixed_value "$weight_profile_path" "- Mode: ")"
profile_uplift_mode_line="$(extract_prefixed_value "$weight_profile_path" "- Uplift mode: ")"
profile_uplift_vector_line="$(extract_prefixed_value "$weight_profile_path" "- Applied uplift multipliers: ")"
profile_momentum_weight_line="$(extract_prefixed_value "$weight_profile_path" "- momentum weight: ")"
profile_distribution_weight_line="$(extract_prefixed_value "$weight_profile_path" "- distribution weight: ")"
profile_kpi_weight_line="$(extract_prefixed_value "$weight_profile_path" "- kpi trendline weight: ")"
profile_reply_weight_line="$(extract_prefixed_value "$weight_profile_path" "- reply quality weight: ")"
profile_transcript_weight_line="$(extract_prefixed_value "$weight_profile_path" "- transcript quality weight: ")"

momentum_weight="0.30"
distribution_weight="0.22"
kpi_trendline_weight="0.20"
reply_quality_weight="0.18"
transcript_quality_weight="0.10"
weight_profile_mode="default"
weight_profile_samples="n/a"
weight_profile_source="Default signal weights"
uplift_profile_mode="n/a"
applied_uplift_multipliers="n/a"

profile_momentum_weight="$(extract_number "$profile_momentum_weight_line")"
profile_distribution_weight="$(extract_number "$profile_distribution_weight_line")"
profile_kpi_weight="$(extract_number "$profile_kpi_weight_line")"
profile_reply_weight="$(extract_number "$profile_reply_weight_line")"
profile_transcript_weight="$(extract_number "$profile_transcript_weight_line")"
profile_samples_number="$(extract_number "$profile_samples_line")"

if [[ -n "$profile_samples_number" ]]; then
  weight_profile_samples="$profile_samples_number"
fi

if [[ -n "$weight_profile_path" ]]; then
  if [[ -n "$profile_momentum_weight" && -n "$profile_distribution_weight" && -n "$profile_kpi_weight" && -n "$profile_reply_weight" && -n "$profile_transcript_weight" ]]; then
    normalized_weights="$(awk \
      -v wm="$profile_momentum_weight" \
      -v wd="$profile_distribution_weight" \
      -v wk="$profile_kpi_weight" \
      -v wr="$profile_reply_weight" \
      -v wt="$profile_transcript_weight" \
      'BEGIN {
        sum = wm + wd + wk + wr + wt
        if (sum <= 0) exit 1
        printf "%.6f|%.6f|%.6f|%.6f|%.6f", wm / sum, wd / sum, wk / sum, wr / sum, wt / sum
      }' || true)"
    if [[ -n "$normalized_weights" ]]; then
      IFS='|' read -r momentum_weight distribution_weight kpi_trendline_weight reply_quality_weight transcript_quality_weight <<< "$normalized_weights"
      weight_profile_mode="adaptive"
      if [[ "$profile_mode_line" != "n/a" && -n "$profile_mode_line" ]]; then
        weight_profile_mode="$profile_mode_line"
      elif [[ "$weight_profile_samples" != "n/a" ]]; then
        weight_profile_mode="adaptive (${weight_profile_samples} samples)"
      fi
      weight_profile_source="$weight_profile_path"
    fi
  fi
  if [[ "$profile_uplift_mode_line" != "n/a" && -n "$profile_uplift_mode_line" ]]; then
    uplift_profile_mode="$profile_uplift_mode_line"
  fi
  if [[ "$profile_uplift_vector_line" != "n/a" && -n "$profile_uplift_vector_line" ]]; then
    applied_uplift_multipliers="$profile_uplift_vector_line"
  fi
fi

applied_weight_vector="$(awk \
  -v wm="$momentum_weight" \
  -v wd="$distribution_weight" \
  -v wk="$kpi_trendline_weight" \
  -v wr="$reply_quality_weight" \
  -v wt="$transcript_quality_weight" \
  'BEGIN {
    printf "momentum %.3f, distribution %.3f, KPI trendline %.3f, reply %.3f, transcript %.3f", wm, wd, wk, wr, wt
  }')"

if [[ "$metric_focus" == "n/a" ]]; then
  metric_focus="one KPI-backed founder proof narrative"
fi
if [[ "$strongest_metric" == "n/a" ]]; then
  strongest_metric="weekly strongest KPI signal"
fi
if [[ "$weekly_narrative" == "n/a" ]]; then
  weekly_narrative="$weekly_summary"
fi
if [[ "$weekly_narrative" == "n/a" ]]; then
  weekly_narrative="Balanced founder execution narrative with explicit proof."
fi
if [[ "$current_focus" == "n/a" ]]; then
  current_focus="Tighten weakest KPI before expanding channel spend."
fi
if [[ "$mix_recommendation" == "n/a" ]]; then
  mix_recommendation="$credibility_mix_recommendation"
fi
if [[ "$mix_recommendation" == "n/a" ]]; then
  mix_recommendation="Keep routing aligned to ROI and reply quality."
fi
if [[ -z "$quote_anchor_a" || "$quote_anchor_a" == "n/a" ]]; then
  quote_anchor_a="We tightened one bottleneck first, then scaled what proved repeatable."
fi
if [[ -z "$objection_first" || "$objection_first" == "n/a" ]]; then
  objection_first="How do you prove this is more than anecdotal founder momentum?"
fi
if [[ -z "$clip_candidate_1" || "$clip_candidate_1" == "n/a" ]]; then
  clip_candidate_1="00:10-00:40 | We tightened one bottleneck first, then scaled what proved repeatable."
fi
if [[ "$headline_a" == "n/a" ]]; then
  headline_a="Founder execution loop with measurable weekly proof."
fi
if [[ "$headline_b" == "n/a" ]]; then
  headline_b="One scoreboard, one narrative, one operator follow-up."
fi
if [[ -z "$press_angle_1" ]]; then
  press_angle_1="Founder KPI loop translates weekly execution into public proof."
fi
if [[ -z "$press_angle_2" ]]; then
  press_angle_2="Small-team operating cadence compounds reach without bloating process."
fi

momentum_score_number="$(extract_number "$momentum_score_line")"
distribution_score_number="$(extract_number "$distribution_completion_score")"
transcript_quality_score="$(extract_number "$transcript_quality_score_line")"
quote_candidates_detected="$(extract_number "$quote_candidates_detected_line")"
objection_candidates_detected="$(extract_number "$objection_candidates_detected_line")"
speaker_candidates_detected="$(extract_number "$speaker_candidates_detected_line")"

if [[ -z "$momentum_score_number" ]]; then
  momentum_score_number=60
else
  momentum_score_number="$(round_number "$momentum_score_number")"
fi

if [[ -z "$distribution_score_number" ]]; then
  distribution_score_number="$distribution_consistency_signal_score"
fi
if [[ -z "$distribution_score_number" ]]; then
  distribution_score_number=70
else
  distribution_score_number="$(round_number "$distribution_score_number")"
fi

if [[ -n "$distribution_consistency_signal_score" ]]; then
  distribution_consistency_signal_score="$(round_number "$distribution_consistency_signal_score")"
fi
if [[ -n "$outcome_reliability_score" ]]; then
  outcome_reliability_score="$(round_number "$outcome_reliability_score")"
fi
if [[ -n "$objection_resolution_score" ]]; then
  objection_resolution_score="$(round_number "$objection_resolution_score")"
fi

if [[ -z "$transcript_quality_score" ]]; then
  if [[ -z "$quote_candidates_detected" ]]; then quote_candidates_detected=0; fi
  if [[ -z "$objection_candidates_detected" ]]; then objection_candidates_detected=0; fi
  if [[ -z "$speaker_candidates_detected" ]]; then speaker_candidates_detected=0; fi

  transcript_quality_score="$(clamp_score "$(awk \
    -v quotes="$quote_candidates_detected" \
    -v objections="$objection_candidates_detected" \
    -v speakers="$speaker_candidates_detected" \
    'BEGIN {
      quote_cap = (quotes > 8 ? 8 : quotes)
      objection_cap = (objections > 8 ? 8 : objections)
      speaker_cap = (speakers > 3 ? 3 : speakers)
      quote_objection_gap = (quotes > objections ? quotes - objections : objections - quotes)

      score = 18
      score += (quote_cap * 3.5)
      score += (objection_cap * 3.5)
      score += (speaker_cap * 8.5)
      score -= (quote_objection_gap * 1.8)
      printf "%.4f", score
    }')")"
fi

if [[ -z "$transcript_quality_score" || "$transcript_quality_score" == "n/a" ]]; then
  transcript_quality_score=40
  if [[ -n "$quote_anchor_a" && -n "$objection_first" && -n "$clip_candidate_1" ]]; then
    transcript_quality_score=78
  fi
else
  transcript_quality_score="$(round_number "$transcript_quality_score")"
fi

on_track_count="$(extract_scoreboard_count "$scoreboard_state" "on track")"
at_risk_count="$(extract_scoreboard_count "$scoreboard_state" "at risk")"
off_track_count="$(extract_scoreboard_count "$scoreboard_state" "off track")"
if [[ -z "$on_track_count" ]]; then on_track_count=0; fi
if [[ -z "$at_risk_count" ]]; then at_risk_count=0; fi
if [[ -z "$off_track_count" ]]; then off_track_count=0; fi

scoreboard_health_score="$(clamp_score "$(awk -v ontrack="$on_track_count" -v risk="$at_risk_count" -v offtrack="$off_track_count" 'BEGIN {
  score = 68 + (ontrack * 8.0) - (risk * 5.0) - (offtrack * 9.0)
  printf "%.4f", score
}')")"

distribution_health_score="$(average_scores "$distribution_score_number" "$distribution_consistency_signal_score" "$scoreboard_health_score")"
if [[ -z "$distribution_health_score" ]]; then
  distribution_health_score="$distribution_score_number"
fi

mrr_status_score="$(score_from_status "$(extract_metric_status "$fame_pack_path" "MRR")")"
cac_status_score="$(score_from_status "$(extract_metric_status "$fame_pack_path" "CAC")")"
ltv_cac_status_score="$(score_from_status "$(extract_metric_status "$fame_pack_path" "LTV/CAC")")"

mrr_delta_score="$(metric_delta_direction_score "MRR" "$(extract_metric_delta "$fame_pack_path" "MRR")")"
cac_delta_score="$(metric_delta_direction_score "CAC" "$(extract_metric_delta "$fame_pack_path" "CAC")")"
ltv_cac_delta_score="$(metric_delta_direction_score "LTV/CAC" "$(extract_metric_delta "$fame_pack_path" "LTV/CAC")")"

kpi_status_score="$(average_scores "$mrr_status_score" "$cac_status_score" "$ltv_cac_status_score")"
kpi_delta_direction_score="$(average_scores "$mrr_delta_score" "$cac_delta_score" "$ltv_cac_delta_score")"
kpi_trendline_score="$(average_scores "$kpi_status_score" "$kpi_delta_direction_score")"
if [[ -z "$kpi_trendline_score" ]]; then
  kpi_trendline_score="$momentum_score_number"
fi

engagement_replies="$(extract_slash_number "$engagement_metrics_line" 1)"
engagement_objections="$(extract_slash_number "$engagement_metrics_line" 2)"
engagement_docs_updates="$(extract_slash_number "$engagement_metrics_line" 3)"
engagement_quality_score="$(score_from_engagement_triplet "$engagement_replies" "$engagement_objections" "$engagement_docs_updates")"

reply_quality_score="$(average_scores "$objection_resolution_score" "$engagement_quality_score" "$outcome_reliability_score")"
if [[ -z "$reply_quality_score" ]]; then
  reply_quality_score=58
fi

evidence_signal_count=0
if [[ "$momentum_score_line" != "n/a" ]]; then evidence_signal_count=$((evidence_signal_count + 1)); fi
if [[ "$distribution_completion_score" != "n/a" || -n "$distribution_consistency_signal_score" ]]; then evidence_signal_count=$((evidence_signal_count + 1)); fi
if [[ -n "$kpi_status_score" || -n "$kpi_delta_direction_score" ]]; then evidence_signal_count=$((evidence_signal_count + 1)); fi
if [[ -n "$objection_resolution_score" || -n "$engagement_quality_score" || -n "$outcome_reliability_score" ]]; then evidence_signal_count=$((evidence_signal_count + 1)); fi
if [[ "$transcript_quality_score_line" != "n/a" || "$transcript_heading" != "n/a" ]]; then evidence_signal_count=$((evidence_signal_count + 1)); fi

evidence_coverage_score="$(clamp_score "$(awk -v count="$evidence_signal_count" 'BEGIN {
  score = (count / 5.0) * 100
  printf "%.4f", score
}')")"

fame_readiness_score="$(clamp_score "$(awk \
  -v momentum="$momentum_score_number" \
  -v distribution="$distribution_health_score" \
  -v trendline="$kpi_trendline_score" \
  -v reply="$reply_quality_score" \
  -v transcript="$transcript_quality_score" \
  -v momentum_weight="$momentum_weight" \
  -v distribution_weight="$distribution_weight" \
  -v trendline_weight="$kpi_trendline_weight" \
  -v reply_weight="$reply_quality_weight" \
  -v transcript_weight="$transcript_quality_weight" \
  'BEGIN {
    weight_sum = momentum_weight + distribution_weight + trendline_weight + reply_weight + transcript_weight
    if (weight_sum <= 0) weight_sum = 1
    score = ((momentum * momentum_weight) + (distribution * distribution_weight) + (trendline * trendline_weight) + (reply * reply_weight) + (transcript * transcript_weight)) / weight_sum
    printf "%.4f", score
  }')")"

weakest_signal_label="momentum core"
weakest_signal_score="$momentum_score_number"
if (( distribution_health_score < weakest_signal_score )); then
  weakest_signal_label="distribution health"
  weakest_signal_score="$distribution_health_score"
fi
if (( kpi_trendline_score < weakest_signal_score )); then
  weakest_signal_label="KPI trendline"
  weakest_signal_score="$kpi_trendline_score"
fi
if (( reply_quality_score < weakest_signal_score )); then
  weakest_signal_label="reply quality"
  weakest_signal_score="$reply_quality_score"
fi
if (( transcript_quality_score < weakest_signal_score )); then
  weakest_signal_label="transcript quality"
  weakest_signal_score="$transcript_quality_score"
fi

readiness_tier="Emerging"
if (( fame_readiness_score >= 80 )); then
  readiness_tier="Breakout Ready"
elif (( fame_readiness_score >= 65 )); then
  readiness_tier="Compounding"
fi

risk_line="Momentum is compounding; keep execution tight and protect reply quality."
if (( fame_readiness_score < 55 )); then
  risk_line="Momentum is fragile; weakest signal is ${weakest_signal_label} (${weakest_signal_score}/100). Tighten one proof narrative before expanding channels."
elif (( fame_readiness_score < 70 )); then
  risk_line="Momentum is rising but inconsistent; weakest signal is ${weakest_signal_label} (${weakest_signal_score}/100). Close this gap before adding new bets."
elif (( weakest_signal_score < 72 )); then
  risk_line="Momentum is compounding but one signal still lags: ${weakest_signal_label} (${weakest_signal_score}/100). Resolve it before scaling cadence."
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-momentum-brief -->

# Founder Fame Momentum Brief - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source fame pack: ${fame_pack_path}
Source repurpose plan: ${repurpose_plan_path}
Source transcript ingestion: ${transcript_ingestion_path:-n/a}
Source press kit: ${press_kit_path:-n/a}
Source media blast: ${media_blast_path:-n/a}
Source credibility ledger: ${credibility_ledger_path:-n/a}
Source weight profile: ${weight_profile_path:-n/a}

## Snapshot

- Founder fame pack: ${fame_pack_heading}
- Repurpose plan: ${repurpose_heading}
- Transcript ingestion: ${transcript_heading}
- Press kit: ${press_heading}
- Media blast: ${media_heading}
- Credibility ledger: ${credibility_heading}
- Weight profile: ${weight_profile_heading}
- Metric focus: ${metric_focus}
- Strongest metric: ${strongest_metric}
- Weekly narrative: ${weekly_narrative}
- Current focus: ${current_focus}
- Weight profile mode: ${weight_profile_mode}
- Weight profile sample count: ${weight_profile_samples}
- Uplift profile mode: ${uplift_profile_mode}
- Applied uplift multipliers: ${applied_uplift_multipliers}
- Applied signal weights: ${applied_weight_vector}

## Fame Readiness Score

- Momentum score signal: ${momentum_score_line}
- Distribution completion score: ${distribution_completion_score}
- Distribution health score: ${distribution_health_score}/100
- KPI trendline score: ${kpi_trendline_score}/100
- Reply quality score: ${reply_quality_score}/100
- Transcript quality score: ${transcript_quality_score}/100
- Evidence coverage score: ${evidence_coverage_score}/100
- Fame readiness score: ${fame_readiness_score}/100 (${readiness_tier})
- Routing recommendation: ${mix_recommendation}

## Signal Fusion Breakdown

- Momentum core: ${momentum_score_number}/100 from founder fame pack momentum.
- Distribution health: ${distribution_health_score}/100 from completion + consistency + scoreboard pressure.
- KPI trendline: ${kpi_trendline_score}/100 from MRR/CAC/LTV-CAC status and delta direction.
- Reply quality: ${reply_quality_score}/100 from objection resolution and engagement metrics.
- Transcript quality: ${transcript_quality_score}/100 from quote/objection/speaker extraction quality.
- Weight source: ${weight_profile_source}.
- Uplift source mode: ${uplift_profile_mode}.
- Weakest signal now: ${weakest_signal_label} (${weakest_signal_score}/100).

## Narrative Stack

1. Core hook: ${headline_a}
2. Supporting hook: ${headline_b}
3. Press angle A: ${press_angle_1}
4. Press angle B: ${press_angle_2}
5. Proof quote anchor: ${quote_anchor_a}
6. First objection to handle: ${objection_first}
7. First clip candidate: ${clip_candidate_1}

## Risk Radar

- Scoreboard state: ${scoreboard_state}
- Weekly summary: ${weekly_summary}
- Primary risk call: ${risk_line}
- Friction to resolve first: ${objection_first}
- Guardrail: do not add new channels until this week’s proof loop closes.

## Next 48 Hours

- [ ] Publish one quote-led clip from the first clip candidate.
- [ ] Publish one objection-handling proof thread using the first objection.
- [ ] Publish one press-angle recap post using Hook A + strongest metric.
- [ ] Capture top reply objections and add one docs/product clarification.

## Founder Share Block

\`\`\`text
Founder momentum brief (${week_label})
Readiness: ${fame_readiness_score}/100 (${readiness_tier})
Focus: ${metric_focus}
Proof: ${strongest_metric}
Narrative: ${weekly_narrative}
Quote anchor: ${quote_anchor_a}
First objection to handle: ${objection_first}
Weakest signal: ${weakest_signal_label} (${weakest_signal_score}/100)
Weight mode: ${weight_profile_mode}
Uplift mode: ${uplift_profile_mode}
Mix call: ${mix_recommendation}
\`\`\`
EOF

echo "Wrote founder fame momentum brief: $output_path"
