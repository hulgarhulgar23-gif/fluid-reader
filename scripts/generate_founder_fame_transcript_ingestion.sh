#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame transcript-ingestion brief from interview transcript signals.

Usage:
  zsh scripts/generate_founder_fame_transcript_ingestion.sh [options]

Required:
  --transcript <path>           Interview transcript markdown/text

Optional:
  --interview-prep <path>       Founder fame interview prep markdown
  --media-blast <path>          Founder media blast markdown
  --week <label>                Week label (default: inferred from transcript/interview/media heading, then current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-transcript-ingestion.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_transcript_ingestion.sh \
    --transcript docs/campaigns/2026-W23-founder-interview-transcript.md \
    --interview-prep docs/campaigns/2026-W23-founder-fame-interview-prep.md \
    --media-blast docs/campaigns/2026-W23-founder-media-blast.md \
    --out docs/campaigns/2026-W23-founder-fame-transcript-ingestion.md
EOF
}

transcript_path=""
interview_prep_path=""
media_blast_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --transcript)
      transcript_path="${2:-}"
      shift 2
      ;;
    --interview-prep)
      interview_prep_path="${2:-}"
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

if [[ -z "$transcript_path" ]]; then
  echo "Missing required option: --transcript" >&2
  usage >&2
  exit 1
fi

for required_file in "$transcript_path"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

for optional_file in "$interview_prep_path" "$media_blast_path"; do
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

clamp_score() {
  local value="$1"
  awk -v value="$value" 'BEGIN {
    adjusted = value + 0
    if (adjusted < 0) adjusted = 0
    if (adjusted > 100) adjusted = 100
    printf "%.0f", adjusted
  }'
}

truncate_value() {
  local value="$1"
  local max_length="${2:-180}"
  if (( ${#value} > max_length )); then
    echo "${value[1,$((max_length - 3))]}..."
  else
    echo "$value"
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

extract_week_from_transcript() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi

  local week_match
  week_match="$(echo "$heading" | sed -nE 's/.*([0-9]{4}-W[0-9]{2}).*/\1/p')"
  if [[ -n "$week_match" ]]; then
    echo "$week_match"
    return
  fi
  echo ""
}

extract_week_from_interview_prep() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Interview Prep:' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Interview Prep:"}"
}

extract_week_from_media_blast() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Media Blast - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Media Blast - "}"
}

normalize_candidate_key() {
  local value="$1"
  value="$(print -r -- "$value" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9 ]+/ /g; s/[[:space:]]+/ /g; s/^ +| +$//g')"
  if (( ${#value} > 96 )); then
    value="${value[1,96]}"
  fi
  echo "$value"
}

is_noise_candidate() {
  local line_value="$1"
  local lower_value="${line_value:l}"

  if [[ "$lower_value" == source:* || "$lower_value" == recorded:* || "$lower_value" == notes:* ]]; then
    return 0
  fi
  if [[ "$lower_value" == *"[music]"* || "$lower_value" == *"[applause]"* || "$lower_value" == *"[laughter]"* ]]; then
    return 0
  fi
  if [[ "$lower_value" == *"thanks for watching"* || "$lower_value" == *"like and subscribe"* || "$lower_value" == *"link in bio"* ]]; then
    return 0
  fi
  if [[ "$lower_value" == *"sponsored by"* || "$lower_value" == *"ad break"* || "$lower_value" == *"promo code"* ]]; then
    return 0
  fi
  if (( ${#lower_value} < 80 )); then
    case "$lower_value" in
      um|uh|hmm|mm|yeah|right|okay|ok|"you know"|um*|uh*|hmm*|mm*|yeah*|right*|okay*|ok*|"you know"*)
        return 0
        ;;
    esac
  fi

  return 1
}

is_objection_candidate() {
  local line_value="$1"
  local lower_value="${line_value:l}"

  if [[ "$line_value" == *"?"* ]]; then
    return 0
  fi

  if [[ "$lower_value" == *objection* || "$lower_value" == *concern* || "$lower_value" == *risk* ]]; then
    return 0
  fi
  if [[ "$lower_value" == *pricing* || "$lower_value" == *price* || "$lower_value" == *adoption* || "$lower_value" == *retention* || "$lower_value" == *churn* ]]; then
    return 0
  fi
  if [[ "$lower_value" == *prove* || "$lower_value" == *proof* || "$lower_value" == *skeptic* || "$lower_value" == *doubt* ]]; then
    return 0
  fi
  if [[ "$lower_value" == *"how do"* || "$lower_value" == *"why does"* || "$lower_value" == *"what if"* || "$lower_value" == *"what happens"* ]]; then
    return 0
  fi

  return 1
}

calculate_transcript_quality_components() {
  local quote_total="$1"
  local objection_total="$2"
  local speaker_total="$3"
  local timecode_total="$4"
  local duplicate_total="$5"
  local noise_total="$6"
  local raw_total="$7"

  awk \
    -v quotes="$quote_total" \
    -v objections="$objection_total" \
    -v speakers="$speaker_total" \
    -v timecodes="$timecode_total" \
    -v duplicates="$duplicate_total" \
    -v noise="$noise_total" \
    -v raw="$raw_total" \
    'BEGIN {
      quote_score = (quotes / 8.0) * 100.0
      if (quote_score > 100) quote_score = 100
      if (quote_score < 0) quote_score = 0

      objection_score = (objections / 8.0) * 100.0
      if (objection_score > 100) objection_score = 100
      if (objection_score < 0) objection_score = 0

      speaker_score = (speakers / 3.0) * 100.0
      if (speaker_score > 100) speaker_score = 100
      if (speaker_score < 0) speaker_score = 0

      timecode_score = (timecodes / 8.0) * 100.0
      if (timecode_score > 100) timecode_score = 100
      if (timecode_score < 0) timecode_score = 0

      hygiene_penalty = (duplicates * 7.0) + (noise * 5.0)
      if (hygiene_penalty > 70) hygiene_penalty = 70
      hygiene_score = 100.0 - hygiene_penalty
      if (hygiene_score < 0) hygiene_score = 0

      quote_objection_gap = (quotes > objections ? quotes - objections : objections - quotes)
      balance_penalty = quote_objection_gap * 2.0
      if (balance_penalty > 16) balance_penalty = 16

      depth_penalty = 0
      if (raw < 10) depth_penalty += (10 - raw) * 0.8
      if (quotes < 3) depth_penalty += (3 - quotes) * 2.0
      if (objections < 2) depth_penalty += (2 - objections) * 3.0
      if (speakers < 2) depth_penalty += (2 - speakers) * 6.0
      if (timecodes < 3) depth_penalty += (3 - timecodes) * 2.0

      weighted_score = (quote_score * 0.25) + (objection_score * 0.25) + (speaker_score * 0.18) + (timecode_score * 0.18) + (hygiene_score * 0.14)
      total_score = weighted_score - balance_penalty - depth_penalty
      if (total_score < 0) total_score = 0
      if (total_score > 100) total_score = 100

      printf "%.0f|%.0f|%.0f|%.0f|%.0f|%.0f|%.0f|%.0f", total_score, quote_score, objection_score, speaker_score, timecode_score, hygiene_score, balance_penalty, depth_penalty
    }'
}

calculate_transcript_quality_score() {
  local quality_components="$1"
  echo "${quality_components%%|*}"
}

quote_priority_score() {
  local speaker_value="$1"
  local line_value="$2"
  local lower_value="${line_value:l}"
  local score=52

  if [[ "${speaker_value:l}" == *founder* ]]; then
    score=$((score + 22))
  elif [[ "${speaker_value:l}" == *host* ]]; then
    score=$((score + 6))
  fi

  if [[ "$line_value" == *"?"* ]]; then
    score=$((score - 18))
  fi

  if [[ "$lower_value" == *metric* || "$lower_value" == *kpi* || "$lower_value" == *proof* || "$lower_value" == *experiment* || "$lower_value" == *workflow* || "$lower_value" == *objection* || "$lower_value" == *distribution* ]]; then
    score=$((score + 14))
  fi

  if [[ "$lower_value" == welcome* || "$lower_value" == *"last one"* || "$lower_value" == *"give listeners one action"* ]]; then
    score=$((score - 24))
  fi

  clamp_score "$score"
}

objection_priority_score() {
  local speaker_value="$1"
  local line_value="$2"
  local lower_value="${line_value:l}"
  local score=42

  if [[ "$line_value" == *"?"* ]]; then
    score=$((score + 12))
  fi
  if [[ "$lower_value" == *objection* || "$lower_value" == *concern* || "$lower_value" == *risk* || "$lower_value" == *skeptic* || "$lower_value" == *"cherry-picked"* || "$lower_value" == *"vanity posting"* ]]; then
    score=$((score + 26))
  fi
  if [[ "$lower_value" == *pricing* || "$lower_value" == *price* || "$lower_value" == *adoption* || "$lower_value" == *retention* || "$lower_value" == *churn* || "$lower_value" == *conversion* || "$lower_value" == *flat* ]]; then
    score=$((score + 18))
  fi
  if [[ "$lower_value" == *"how do you answer"* || "$lower_value" == *"how do you prove"* || "$lower_value" == *"what do you do"* || "$lower_value" == *"actually keep up"* ]]; then
    score=$((score + 14))
  fi

  if [[ "${speaker_value:l}" == *host* ]]; then
    score=$((score + 6))
  fi

  if [[ "$lower_value" == *"what changed after"* || "$lower_value" == *"what metric convinced"* || "$lower_value" == welcome* || "$lower_value" == *"last one"* ]]; then
    score=$((score - 30))
  fi

  clamp_score "$score"
}

clip_priority_score() {
  local line_value="$1"
  local lower_value="${line_value:l}"
  local score=50

  if [[ "$lower_value" == *"founder:"* ]]; then
    score=$((score + 20))
  elif [[ "$lower_value" == *"host:"* ]]; then
    score=$((score + 5))
  fi
  if [[ "$line_value" == *"?"* ]]; then
    score=$((score - 18))
  fi
  if [[ "$lower_value" == *metric* || "$lower_value" == *kpi* || "$lower_value" == *proof* || "$lower_value" == *objection* || "$lower_value" == *workflow* || "$lower_value" == *experiment* || "$lower_value" == *cta* ]]; then
    score=$((score + 14))
  fi
  if [[ "$lower_value" == *"welcome back"* || "$lower_value" == *"last one"* ]]; then
    score=$((score - 26))
  fi

  clamp_score "$score"
}

collect_transcript_signal_rows() {
  local source_path="$1"
  awk '
    BEGIN { in_code = 0 }
    /^```/ { in_code = !in_code; next }
    in_code { next }
    /^#/ { next }
    /^[[:space:]]*$/ { next }
    {
      line = $0
      sub(/^[[:space:]]*[-*][[:space:]]*/, "", line)
      sub(/^[[:space:]]*[0-9]+\.[[:space:]]*/, "", line)
      sub(/^[0-9]+:[0-9]{2}(:[0-9]{2})?[[:space:]]+/, "", line)
      gsub(/[[:space:]]+/, " ", line)
      sub(/^[[:space:]]+/, "", line)
      sub(/[[:space:]]+$/, "", line)
      if (length(line) < 18) next
      lower = tolower(line)
      if (lower ~ /^source[: ]/) next
      if (lower ~ /^recorded[: ]/) next

      speaker = ""
      content = line
      colon_index = index(line, ":")
      if (colon_index > 1 && colon_index <= 42) {
        possible_speaker = substr(line, 1, colon_index - 1)
        if (possible_speaker ~ /^[A-Za-z][A-Za-z0-9 ._&\/-]*$/) {
          speaker = possible_speaker
          content = substr(line, colon_index + 1)
        }
      }

      sub(/^[[:space:]]+/, "", content)
      sub(/[[:space:]]+$/, "", content)
      if (length(content) < 20) next

      printf "%s\034%s\n", speaker, content
    }
  ' "$source_path"
}

collect_timecode_candidates() {
  local source_path="$1"
  rg --no-heading -n '[0-9]{1,2}:[0-9]{2}(:[0-9]{2})?' "$source_path" 2>/dev/null | sed -E 's/^[0-9]+://'
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_transcript "$transcript_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_interview_prep "$interview_prep_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_media_blast "$media_blast_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-transcript-ingestion.md"
fi

transcript_heading="$(extract_heading "$transcript_path")"
interview_heading="$(extract_heading "$interview_prep_path")"
media_heading="$(extract_heading "$media_blast_path")"

metric_focus="$(extract_prefixed_value "$interview_prep_path" "- Metric focus: ")"
strongest_metric="$(extract_prefixed_value "$interview_prep_path" "- Strongest metric: ")"
priority_format_target="$(extract_prefixed_value "$interview_prep_path" "- Priority format / target: ")"
weekly_narrative="$(extract_prefixed_value "$media_blast_path" "- Weekly narrative: ")"
current_focus="$(extract_prefixed_value "$media_blast_path" "- Current focus: ")"
cta_script="$(extract_prefixed_value "$media_blast_path" "- CTA script: ")"

if [[ "$metric_focus" == "n/a" ]]; then
  metric_focus="one KPI-backed founder proof narrative"
fi
if [[ "$strongest_metric" == "n/a" ]]; then
  strongest_metric="weekly strongest KPI signal"
fi
if [[ "$priority_format_target" == "n/a" ]]; then
  priority_format_target="podcast / top-priority founder guesting target"
fi
if [[ "$weekly_narrative" == "n/a" ]]; then
  weekly_narrative="Balanced founder execution narrative with explicit proof."
fi
if [[ "$current_focus" == "n/a" ]]; then
  current_focus="Tighten weakest KPI before expanding channel spend."
fi
if [[ "$cta_script" == "n/a" ]]; then
  cta_script="Reply with your KPI bottleneck and I’ll share the exact command stack."
fi

quote_candidates=()
objection_candidates=()
typeset -A quote_candidate_keys=()
typeset -A objection_candidate_keys=()
typeset -A detected_speakers=()
quote_candidate_scored_entries=()
objection_candidate_scored_entries=()

raw_signal_count=0
duplicate_filtered_count=0
noise_filtered_count=0

while IFS=$'\034' read -r speaker_line candidate_line || [[ -n "$speaker_line$candidate_line" ]]; do
  raw_signal_count=$((raw_signal_count + 1))
  if (( raw_signal_count > 400 )); then
    break
  fi

  speaker_line="$(trim_value "$speaker_line")"
  candidate_line="$(trim_value "$candidate_line")"
  [[ -z "$candidate_line" ]] && continue

  if [[ -n "$speaker_line" ]]; then
    speaker_key="$(normalize_candidate_key "$speaker_line")"
    if [[ -n "$speaker_key" ]]; then
      detected_speakers["$speaker_key"]=1
    fi
  fi

  if is_noise_candidate "$candidate_line"; then
    noise_filtered_count=$((noise_filtered_count + 1))
    continue
  fi

  quote_display="$candidate_line"
  if [[ -n "$speaker_line" ]]; then
    quote_display="${speaker_line}: ${candidate_line}"
  fi
  quote_display="$(truncate_value "$quote_display" 180)"
  quote_key="$(normalize_candidate_key "$quote_display")"
  if [[ -n "$quote_key" ]]; then
    if [[ -n "${quote_candidate_keys[$quote_key]-}" ]]; then
      duplicate_filtered_count=$((duplicate_filtered_count + 1))
    else
      quote_candidate_keys["$quote_key"]=1
      quote_score="$(quote_priority_score "$speaker_line" "$candidate_line")"
      quote_candidate_scored_entries+=("${quote_score}|${quote_display}")
    fi
  fi

  if is_objection_candidate "$candidate_line"; then
    objection_display="$candidate_line"
    if [[ -n "$speaker_line" ]]; then
      objection_display="${speaker_line}: ${candidate_line}"
    fi
    objection_display="$(truncate_value "$objection_display" 180)"
    objection_key="$(normalize_candidate_key "$objection_display")"
    if [[ -n "$objection_key" && -z "${objection_candidate_keys[$objection_key]-}" ]]; then
      objection_candidate_keys["$objection_key"]=1
      objection_score="$(objection_priority_score "$speaker_line" "$candidate_line")"
      objection_candidate_scored_entries+=("${objection_score}|${objection_display}")
    fi
  fi
done < <(collect_transcript_signal_rows "$transcript_path")

if (( ${#quote_candidate_scored_entries[@]} > 0 )); then
  quote_candidates=()
  while IFS= read -r scored_entry || [[ -n "$scored_entry" ]]; do
    [[ -z "$scored_entry" ]] && continue
    quote_candidates+=("${scored_entry#*|}")
    if (( ${#quote_candidates[@]} >= 8 )); then
      break
    fi
  done < <(printf '%s\n' "${quote_candidate_scored_entries[@]}" | sort -t'|' -k1,1nr)
fi

if (( ${#objection_candidate_scored_entries[@]} > 0 )); then
  objection_candidates=()
  while IFS= read -r scored_entry || [[ -n "$scored_entry" ]]; do
    [[ -z "$scored_entry" ]] && continue
    objection_candidates+=("${scored_entry#*|}")
    if (( ${#objection_candidates[@]} >= 8 )); then
      break
    fi
  done < <(printf '%s\n' "${objection_candidate_scored_entries[@]}" | sort -t'|' -k1,1nr)
fi

timecode_candidates=()
typeset -A timecode_candidate_keys=()
clip_candidate_scored_entries=()
while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="$(trim_value "$line")"
  [[ -z "$trimmed" ]] && continue
  normalized_timecode="$(normalize_candidate_key "$trimmed")"
  if [[ -n "$normalized_timecode" && -n "${timecode_candidate_keys[$normalized_timecode]-}" ]]; then
    continue
  fi
  if [[ -n "$normalized_timecode" ]]; then
    timecode_candidate_keys["$normalized_timecode"]=1
  fi
  clip_display="$(truncate_value "$trimmed" 140)"
  clip_score="$(clip_priority_score "$clip_display")"
  clip_candidate_scored_entries+=("${clip_score}|${clip_display}")
  if (( ${#clip_candidate_scored_entries[@]} >= 12 )); then
    break
  fi
done < <(collect_timecode_candidates "$transcript_path")

if (( ${#clip_candidate_scored_entries[@]} > 0 )); then
  timecode_candidates=()
  while IFS= read -r scored_entry || [[ -n "$scored_entry" ]]; do
    [[ -z "$scored_entry" ]] && continue
    timecode_candidates+=("${scored_entry#*|}")
    if (( ${#timecode_candidates[@]} >= 8 )); then
      break
    fi
  done < <(printf '%s\n' "${clip_candidate_scored_entries[@]}" | sort -t'|' -k1,1nr)
fi

quote_count="${#quote_candidates[@]}"
objection_count="${#objection_candidates[@]}"
speaker_count="${#detected_speakers[@]}"
timecode_count="${#timecode_candidates[@]}"
quality_components="$(calculate_transcript_quality_components "$quote_count" "$objection_count" "$speaker_count" "$timecode_count" "$duplicate_filtered_count" "$noise_filtered_count" "$raw_signal_count")"
IFS='|' read -r transcript_quality_score quote_depth_score objection_depth_score speaker_diversity_score clip_readiness_score hygiene_score balance_penalty_score depth_penalty_score <<< "$quality_components"
transcript_quality_score="$(calculate_transcript_quality_score "$quality_components")"

quality_weakest_dimension="quote depth"
quality_weakest_dimension_score="$quote_depth_score"
if (( objection_depth_score < quality_weakest_dimension_score )); then
  quality_weakest_dimension="objection depth"
  quality_weakest_dimension_score="$objection_depth_score"
fi
if (( speaker_diversity_score < quality_weakest_dimension_score )); then
  quality_weakest_dimension="speaker diversity"
  quality_weakest_dimension_score="$speaker_diversity_score"
fi
if (( clip_readiness_score < quality_weakest_dimension_score )); then
  quality_weakest_dimension="clip readiness"
  quality_weakest_dimension_score="$clip_readiness_score"
fi
if (( hygiene_score < quality_weakest_dimension_score )); then
  quality_weakest_dimension="signal hygiene"
  quality_weakest_dimension_score="$hygiene_score"
fi

quality_primary_risk="Signal quality is healthy; maintain speaker tags and clip timecodes."
quality_guardrail_action="Keep collecting objections and route them into next interview prep."
if (( transcript_quality_score < 55 )); then
  quality_primary_risk="Signal quality is weak; transcript lacks enough clean quote and objection density."
  quality_guardrail_action="Request a cleaner transcript export with speaker labels and explicit timecodes."
elif (( transcript_quality_score < 72 )); then
  quality_primary_risk="Signal quality is moderate; one weak dimension could dilute repurpose output."
  quality_guardrail_action="Add one host/founder quote pass and one objection pass before clipping."
fi
if (( speaker_count < 2 )); then
  quality_primary_risk="Speaker diversity is low; quotes may be too founder-only for strong credibility framing."
  quality_guardrail_action="Tag host + founder speakers before repurpose planning."
fi
if (( timecode_count < 2 )); then
  quality_guardrail_action="Add explicit timestamp markers so clips can ship within the first 24 hours."
fi
if (( quality_weakest_dimension_score < 68 )); then
  quality_primary_risk="Transcript quality bottleneck detected: ${quality_weakest_dimension} (${quality_weakest_dimension_score}/100)."
  case "$quality_weakest_dimension" in
    "quote depth")
      quality_guardrail_action="Add two founder proof lines that include metrics, experiments, or explicit workflow outcomes."
      ;;
    "objection depth")
      quality_guardrail_action="Capture at least two host/market objections and route direct answers into thread copy."
      ;;
    "speaker diversity")
      quality_guardrail_action="Tag speaker labels consistently and keep both founder + host/operator voices in the source transcript."
      ;;
    "clip readiness")
      quality_guardrail_action="Add at least three explicit timestamp markers around top quotes so clips ship faster."
      ;;
    "signal hygiene")
      quality_guardrail_action="Clean duplicates/noise from transcript export before extraction to preserve signal quality."
      ;;
  esac
fi

quote_1="${quote_candidates[1]:-We tightened one bottleneck first, then scaled what proved repeatable.}"
quote_2="${quote_candidates[2]:-Weekly scoreboards keep us honest on which channels deserve more effort.}"
quote_3="${quote_candidates[3]:-Distribution is a system: one proof, one follow-up, one measurable next step.}"

objection_1="${objection_candidates[1]:-How do you prove this is more than anecdotal founder momentum?}"
objection_2="${objection_candidates[2]:-What did you stop doing to keep channel effort focused?}"
objection_3="${objection_candidates[3]:-How quickly can a small team repeat this every week?}"

clip_1="${timecode_candidates[1]:-00:10-00:40 | ${quote_1}}"
clip_2="${timecode_candidates[2]:-00:45-01:20 | ${quote_2}}"
clip_3="${timecode_candidates[3]:-01:25-01:55 | ${quote_3}}"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-transcript-ingestion -->

# Founder Fame Transcript Ingestion - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source transcript: ${transcript_path}
Source interview prep: ${interview_prep_path:-n/a}
Source media blast: ${media_blast_path:-n/a}

## Snapshot

- Transcript heading: ${transcript_heading}
- Interview prep heading: ${interview_heading}
- Media blast heading: ${media_heading}
- Metric focus: ${metric_focus}
- Strongest metric: ${strongest_metric}
- Weekly narrative: ${weekly_narrative}
- Current focus: ${current_focus}
- Priority format / target: ${priority_format_target}
- Quote candidates detected: ${quote_count}
- Objection candidates detected: ${objection_count}
- Distinct speakers detected: ${speaker_count}
- Duplicate lines filtered: ${duplicate_filtered_count}
- Noisy lines filtered: ${noise_filtered_count}
- Transcript quality score: ${transcript_quality_score}/100

## Transcript Quote Bank

1. ${quote_1}
2. ${quote_2}
3. ${quote_3}

## Objection Radar

1. ${objection_1}
2. ${objection_2}
3. ${objection_3}

## Clip Candidate List

1. ${clip_1}
2. ${clip_2}
3. ${clip_3}

## Quality Diagnostics

- Raw candidate lines reviewed: ${raw_signal_count}
- Distinct speakers detected: ${speaker_count}
- Duplicate candidates filtered: ${duplicate_filtered_count}
- Noisy candidates filtered: ${noise_filtered_count}
- Quote depth score: ${quote_depth_score}/100
- Objection depth score: ${objection_depth_score}/100
- Speaker diversity score: ${speaker_diversity_score}/100
- Clip readiness score: ${clip_readiness_score}/100
- Signal hygiene score: ${hygiene_score}/100
- Balance penalty: -${balance_penalty_score}
- Depth penalty: -${depth_penalty_score}
- Weakest quality dimension: ${quality_weakest_dimension} (${quality_weakest_dimension_score}/100)
- Primary quality risk: ${quality_primary_risk}
- Guardrail action: ${quality_guardrail_action}

## Repurpose Priority Mapping

1. Clip priority: Use Quote 1 + Clip Candidate 1 with CTA "${cta_script}".
2. Thread priority: Turn Quote 2 + Objection 1 into a three-post proof thread.
3. Recap priority: Reframe Quote 3 + Objection 2 for operator recap and newsletter excerpt.

## Follow-up Actions

- [ ] Confirm quote/clip selections with founder before editing.
- [ ] Cut one short clip and one backup cut from the top two candidates.
- [ ] Publish one objection-handling thread within 24 hours of the appearance.
- [ ] Log new objections and feed them into next week’s interview prep.

## Share Block

\`\`\`text
Founder transcript ingestion (${week_label})
Metric focus: ${metric_focus}
Strongest proof: ${strongest_metric}
Top quote: ${quote_1}
Top objection: ${objection_1}
First clip candidate: ${clip_1}
Transcript quality score: ${transcript_quality_score}/100
Quality bottleneck: ${quality_weakest_dimension} (${quality_weakest_dimension_score}/100)
\`\`\`
EOF

echo "Wrote founder fame transcript ingestion: $output_path"
