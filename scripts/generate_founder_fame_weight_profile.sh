#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate an adaptive founder fame signal-weight profile from recent momentum briefs.

Usage:
  zsh scripts/generate_founder_fame_weight_profile.sh [options]

Optional:
  --campaign-dir <path>         Directory to scan for momentum briefs (default: docs/campaigns)
  --limit <count>               Max momentum briefs to analyze (default: 12)
  --target-readiness <score>    Target readiness score used for pressure calc (default: 75)
  --uplift-tracker <path>       Founder fame uplift tracker markdown to bias weights toward observed lifts
  --week <label>                Week label (default: current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-weight-profile.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_weight_profile.sh \
    --campaign-dir docs/campaigns \
    --limit 8 \
    --uplift-tracker docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md \
    --out docs/campaigns/$(date +%Y-W%V)-founder-fame-weight-profile.md
EOF
}

campaign_dir="docs/campaigns"
limit_count=12
target_readiness=75
uplift_tracker_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --campaign-dir)
      campaign_dir="${2:-}"
      shift 2
      ;;
    --limit)
      limit_count="${2:-}"
      shift 2
      ;;
    --target-readiness)
      target_readiness="${2:-}"
      shift 2
      ;;
    --uplift-tracker)
      uplift_tracker_path="${2:-}"
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

if ! [[ "$limit_count" =~ ^[0-9]+$ ]] || (( limit_count <= 0 )); then
  echo "Invalid --limit value: $limit_count (must be a positive integer)" >&2
  exit 1
fi

if ! [[ "$target_readiness" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "Invalid --target-readiness value: $target_readiness (must be numeric)" >&2
  exit 1
fi

if [[ -n "$uplift_tracker_path" && ! -f "$uplift_tracker_path" ]]; then
  echo "Optional source file not found: $uplift_tracker_path" >&2
  exit 1
fi

if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-weight-profile.md"
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
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

extract_number() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true)"
  echo "$number"
}

base_momentum_weight="0.30"
base_distribution_weight="0.22"
base_kpi_weight="0.20"
base_reply_weight="0.18"
base_transcript_weight="0.10"

momentum_uplift_multiplier="1.000"
distribution_uplift_multiplier="1.000"
kpi_uplift_multiplier="1.000"
reply_uplift_multiplier="1.000"
transcript_uplift_multiplier="1.000"

uplift_tracker_heading="n/a"
uplift_mode="default"
uplift_source_label="none"

momentum_weight="$base_momentum_weight"
distribution_weight="$base_distribution_weight"
kpi_weight="$base_kpi_weight"
reply_weight="$base_reply_weight"
transcript_weight="$base_transcript_weight"

momentum_mean="n/a"
momentum_min="n/a"
momentum_max="n/a"
momentum_pressure="n/a"

distribution_mean="n/a"
distribution_min="n/a"
distribution_max="n/a"
distribution_pressure="n/a"

kpi_mean="n/a"
kpi_min="n/a"
kpi_max="n/a"
kpi_pressure="n/a"

reply_mean="n/a"
reply_min="n/a"
reply_max="n/a"
reply_pressure="n/a"

transcript_mean="n/a"
transcript_min="n/a"
transcript_max="n/a"
transcript_pressure="n/a"

readiness_mean="n/a"
readiness_min="n/a"
readiness_max="n/a"

sample_count=0
weight_mode="default (insufficient historical samples)"
top_pressure_signal="n/a"
top_pressure_value="n/a"

if [[ -n "$uplift_tracker_path" ]]; then
  uplift_tracker_heading="$(extract_heading "$uplift_tracker_path")"
  uplift_mode_line="$(extract_prefixed_value "$uplift_tracker_path" "- Mode: ")"
  uplift_momentum_line="$(extract_prefixed_value "$uplift_tracker_path" "- momentum uplift multiplier: ")"
  uplift_distribution_line="$(extract_prefixed_value "$uplift_tracker_path" "- distribution uplift multiplier: ")"
  uplift_kpi_line="$(extract_prefixed_value "$uplift_tracker_path" "- kpi trendline uplift multiplier: ")"
  uplift_reply_line="$(extract_prefixed_value "$uplift_tracker_path" "- reply quality uplift multiplier: ")"
  uplift_transcript_line="$(extract_prefixed_value "$uplift_tracker_path" "- transcript quality uplift multiplier: ")"

  parsed_momentum_multiplier="$(extract_number "$uplift_momentum_line")"
  parsed_distribution_multiplier="$(extract_number "$uplift_distribution_line")"
  parsed_kpi_multiplier="$(extract_number "$uplift_kpi_line")"
  parsed_reply_multiplier="$(extract_number "$uplift_reply_line")"
  parsed_transcript_multiplier="$(extract_number "$uplift_transcript_line")"

  if [[ -n "$parsed_momentum_multiplier" ]]; then momentum_uplift_multiplier="$parsed_momentum_multiplier"; fi
  if [[ -n "$parsed_distribution_multiplier" ]]; then distribution_uplift_multiplier="$parsed_distribution_multiplier"; fi
  if [[ -n "$parsed_kpi_multiplier" ]]; then kpi_uplift_multiplier="$parsed_kpi_multiplier"; fi
  if [[ -n "$parsed_reply_multiplier" ]]; then reply_uplift_multiplier="$parsed_reply_multiplier"; fi
  if [[ -n "$parsed_transcript_multiplier" ]]; then transcript_uplift_multiplier="$parsed_transcript_multiplier"; fi

  if [[ "$uplift_mode_line" != "n/a" && -n "$uplift_mode_line" ]]; then
    uplift_mode="$uplift_mode_line"
  fi
  uplift_source_label="$uplift_tracker_path"
fi

samples_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-weight-profile-samples.${$}.${RANDOM}.txt"
stats_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-weight-profile-stats.${$}.${RANDOM}.txt"

cleanup() {
  rm -f "$samples_file" "$stats_file"
}
trap cleanup EXIT

touch "$samples_file"

brief_candidates=()
if [[ -d "$campaign_dir" ]]; then
  brief_candidates=("${campaign_dir}"/*-founder-fame-momentum-brief*.md(N))
fi

selected_briefs=()
if (( ${#brief_candidates[@]} > 0 )); then
  while IFS= read -r candidate || [[ -n "$candidate" ]]; do
    [[ -z "$candidate" ]] && continue
    selected_briefs+=("$candidate")
    if (( ${#selected_briefs[@]} >= limit_count )); then
      break
    fi
  done < <(printf '%s\n' "${brief_candidates[@]}" | sort -r)
fi

for brief_path in "${selected_briefs[@]}"; do
  momentum_value="$(extract_number "$(extract_prefixed_value "$brief_path" "- Momentum core: ")")"
  distribution_value="$(extract_number "$(extract_prefixed_value "$brief_path" "- Distribution health: ")")"
  kpi_value="$(extract_number "$(extract_prefixed_value "$brief_path" "- KPI trendline: ")")"
  reply_value="$(extract_number "$(extract_prefixed_value "$brief_path" "- Reply quality: ")")"
  transcript_value="$(extract_number "$(extract_prefixed_value "$brief_path" "- Transcript quality: ")")"
  readiness_value="$(extract_number "$(extract_prefixed_value "$brief_path" "- Fame readiness score: ")")"

  if [[ -z "$momentum_value" || -z "$distribution_value" || -z "$kpi_value" || -z "$reply_value" || -z "$transcript_value" || -z "$readiness_value" ]]; then
    continue
  fi

  echo "${brief_path}|${momentum_value}|${distribution_value}|${kpi_value}|${reply_value}|${transcript_value}|${readiness_value}" >> "$samples_file"
done

sample_count="$(wc -l < "$samples_file" | tr -d ' ')"
if [[ -z "$sample_count" ]]; then
  sample_count=0
fi

if (( sample_count > 0 )); then
  awk -F'|' \
    -v target="$target_readiness" \
    -v wm="$base_momentum_weight" \
    -v wd="$base_distribution_weight" \
    -v wk="$base_kpi_weight" \
    -v wr="$base_reply_weight" \
    -v wt="$base_transcript_weight" \
    -v mmult="$momentum_uplift_multiplier" \
    -v dmult="$distribution_uplift_multiplier" \
    -v kmult="$kpi_uplift_multiplier" \
    -v rmult="$reply_uplift_multiplier" \
    -v tmult="$transcript_uplift_multiplier" \
    'BEGIN {
      signal[2] = "momentum"
      signal[3] = "distribution"
      signal[4] = "kpi"
      signal[5] = "reply"
      signal[6] = "transcript"
      base[2] = wm + 0
      base[3] = wd + 0
      base[4] = wk + 0
      base[5] = wr + 0
      base[6] = wt + 0
      uplift[2] = mmult + 0
      uplift[3] = dmult + 0
      uplift[4] = kmult + 0
      uplift[5] = rmult + 0
      uplift[6] = tmult + 0
      for (i = 2; i <= 6; i++) {
        if (uplift[i] <= 0) uplift[i] = 1
      }
    }
    {
      count++
      for (i = 2; i <= 6; i++) {
        value = $i + 0
        sum[i] += value
        if (count == 1 || value < min[i]) min[i] = value
        if (count == 1 || value > max[i]) max[i] = value
      }

      readiness = $7 + 0
      readiness_sum += readiness
      if (count == 1 || readiness < readiness_min) readiness_min = readiness
      if (count == 1 || readiness > readiness_max) readiness_max = readiness
    }
    END {
      if (count == 0) exit

      raw_sum = 0
      for (i = 2; i <= 6; i++) {
        mean[i] = sum[i] / count
        gap = target - mean[i]
        if (gap < 0) gap = 0
        volatility = max[i] - min[i]
        pressure[i] = (gap * 0.65) + (volatility * 0.35)

        if (count < 3) {
          raw_weight[i] = base[i] * uplift[i]
        } else {
          raw_weight[i] = base[i] * (1 + (pressure[i] / 100.0)) * uplift[i]
        }
        raw_sum += raw_weight[i]
      }

      if (raw_sum <= 0) raw_sum = 1
      for (i = 2; i <= 6; i++) {
        normalized_weight[i] = raw_weight[i] / raw_sum
      }

      printf "readiness_mean=%.1f\n", readiness_sum / count
      printf "readiness_min=%.1f\n", readiness_min
      printf "readiness_max=%.1f\n", readiness_max

      for (i = 2; i <= 6; i++) {
        label = signal[i]
        printf "%s_mean=%.1f\n", label, mean[i]
        printf "%s_min=%.1f\n", label, min[i]
        printf "%s_max=%.1f\n", label, max[i]
        printf "%s_pressure=%.1f\n", label, pressure[i]
        printf "%s_weight=%.3f\n", label, normalized_weight[i]
      }
    }' "$samples_file" > "$stats_file"

  while IFS='=' read -r key value || [[ -n "$key$value" ]]; do
    [[ -z "$key" ]] && continue
    case "$key" in
      readiness_mean) readiness_mean="$value" ;;
      readiness_min) readiness_min="$value" ;;
      readiness_max) readiness_max="$value" ;;
      momentum_mean) momentum_mean="$value" ;;
      momentum_min) momentum_min="$value" ;;
      momentum_max) momentum_max="$value" ;;
      momentum_pressure) momentum_pressure="$value" ;;
      momentum_weight) momentum_weight="$value" ;;
      distribution_mean) distribution_mean="$value" ;;
      distribution_min) distribution_min="$value" ;;
      distribution_max) distribution_max="$value" ;;
      distribution_pressure) distribution_pressure="$value" ;;
      distribution_weight) distribution_weight="$value" ;;
      kpi_mean) kpi_mean="$value" ;;
      kpi_min) kpi_min="$value" ;;
      kpi_max) kpi_max="$value" ;;
      kpi_pressure) kpi_pressure="$value" ;;
      kpi_weight) kpi_weight="$value" ;;
      reply_mean) reply_mean="$value" ;;
      reply_min) reply_min="$value" ;;
      reply_max) reply_max="$value" ;;
      reply_pressure) reply_pressure="$value" ;;
      reply_weight) reply_weight="$value" ;;
      transcript_mean) transcript_mean="$value" ;;
      transcript_min) transcript_min="$value" ;;
      transcript_max) transcript_max="$value" ;;
      transcript_pressure) transcript_pressure="$value" ;;
      transcript_weight) transcript_weight="$value" ;;
    esac
  done < "$stats_file"

  top_pressure_result="$(awk \
    -v momentum="$momentum_pressure" \
    -v distribution="$distribution_pressure" \
    -v kpi="$kpi_pressure" \
    -v reply="$reply_pressure" \
    -v transcript="$transcript_pressure" \
    'BEGIN {
      label = "momentum"
      value = momentum + 0
      if ((distribution + 0) > value) { value = distribution + 0; label = "distribution" }
      if ((kpi + 0) > value) { value = kpi + 0; label = "KPI trendline" }
      if ((reply + 0) > value) { value = reply + 0; label = "reply quality" }
      if ((transcript + 0) > value) { value = transcript + 0; label = "transcript quality" }
      printf "%s|%.1f", label, value
    }')"
  top_pressure_signal="${top_pressure_result%%|*}"
  top_pressure_value="${top_pressure_result#*|}"
fi

if (( sample_count >= 3 )); then
  weight_mode="adaptive"
fi

confidence_score="$(awk -v count="$sample_count" 'BEGIN {
  if (count <= 0) {
    score = 0
  } else {
    score = (count / 8.0) * 100.0
    if (score > 100) score = 100
  }
  printf "%.0f", score
}')"

applied_weight_vector="$(awk \
  -v wm="$momentum_weight" \
  -v wd="$distribution_weight" \
  -v wk="$kpi_weight" \
  -v wr="$reply_weight" \
  -v wt="$transcript_weight" \
  'BEGIN {
    printf "momentum %.3f, distribution %.3f, KPI trendline %.3f, reply %.3f, transcript %.3f", wm, wd, wk, wr, wt
  }')"

applied_uplift_vector="$(awk \
  -v momentum="$momentum_uplift_multiplier" \
  -v distribution="$distribution_uplift_multiplier" \
  -v kpi="$kpi_uplift_multiplier" \
  -v reply="$reply_uplift_multiplier" \
  -v transcript="$transcript_uplift_multiplier" \
  'BEGIN {
    printf "momentum %s, distribution %s, KPI trendline %s, reply %s, transcript %s", momentum, distribution, kpi, reply, transcript
  }')"

sample_preview="n/a"
if (( sample_count > 0 )); then
  sample_preview="$(awk -F'|' 'NR <= 3 { print "- " $1 }' "$samples_file")"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-weight-profile -->

# Founder Fame Weight Profile - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Campaign directory: ${campaign_dir}

## Snapshot

- Samples analyzed: ${sample_count}
- Target readiness score: ${target_readiness}
- Mode: ${weight_mode}
- Calibration confidence: ${confidence_score}/100
- Uplift tracker: ${uplift_tracker_heading}
- Uplift mode: ${uplift_mode}
- Uplift source: ${uplift_source_label}
- Top pressure signal: ${top_pressure_signal} (${top_pressure_value})
- Applied uplift multipliers: ${applied_uplift_vector}
- Applied weight vector: ${applied_weight_vector}
- Readiness mean/min/max: ${readiness_mean} / ${readiness_min} / ${readiness_max}

## Recommended Weights

- momentum weight: ${momentum_weight}
- distribution weight: ${distribution_weight}
- kpi trendline weight: ${kpi_weight}
- reply quality weight: ${reply_weight}
- transcript quality weight: ${transcript_weight}

## Signal Diagnostics

| Signal | Mean | Min | Max | Pressure | Recommended Weight |
| --- | ---: | ---: | ---: | ---: | ---: |
| Momentum core | ${momentum_mean} | ${momentum_min} | ${momentum_max} | ${momentum_pressure} | ${momentum_weight} |
| Distribution health | ${distribution_mean} | ${distribution_min} | ${distribution_max} | ${distribution_pressure} | ${distribution_weight} |
| KPI trendline | ${kpi_mean} | ${kpi_min} | ${kpi_max} | ${kpi_pressure} | ${kpi_weight} |
| Reply quality | ${reply_mean} | ${reply_min} | ${reply_max} | ${reply_pressure} | ${reply_weight} |
| Transcript quality | ${transcript_mean} | ${transcript_min} | ${transcript_max} | ${transcript_pressure} | ${transcript_weight} |

## Sample Inputs

${sample_preview}

## Calibration Notes

- If fewer than 3 valid momentum briefs are available, this profile preserves default base weights.
- Pressure combines readiness gap pressure (65%) and volatility pressure (35%).
- Uplift multipliers bias pressure-based weighting toward signals with observed next-week lift.
- Re-run weekly after Friday review to keep weighting aligned to observed bottlenecks.

## Share Block

\`\`\`text
Founder fame weight profile (${week_label})
Mode: ${weight_mode}
Samples: ${sample_count}
Uplift mode: ${uplift_mode}
Top pressure signal: ${top_pressure_signal} (${top_pressure_value})
Weights: ${applied_weight_vector}
\`\`\`
EOF

echo "Wrote founder fame weight profile: $output_path"
