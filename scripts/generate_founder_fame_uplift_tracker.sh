#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame uplift tracker from historical momentum briefs.

Usage:
  zsh scripts/generate_founder_fame_uplift_tracker.sh [options]

Optional:
  --campaign-dir <path>         Directory to scan for momentum briefs (default: docs/campaigns)
  --limit <count>               Max momentum briefs to analyze (default: 16)
  --week <label>                Week label (default: current ISO week)
  --product <text>              Product name (default: Fluid Reader)
  --out <path>                  Output path (default: docs/campaigns/<week>-founder-fame-uplift-tracker.md)
  -h, --help                    Show help

Example:
  zsh scripts/generate_founder_fame_uplift_tracker.sh \
    --campaign-dir docs/campaigns \
    --limit 12 \
    --out docs/campaigns/$(date +%Y-W%V)-founder-fame-uplift-tracker.md
EOF
}

campaign_dir="docs/campaigns"
limit_count=16
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

if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-uplift-tracker.md"
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

extract_number() {
  local raw_value="$1"
  local number
  number="$(print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true)"
  echo "$number"
}

extract_week_label() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Momentum Brief - ' "$source_path" || true)"
  if [[ -n "$heading" ]]; then
    echo "${heading#"# Founder Fame Momentum Brief - "}"
    return
  fi
  print -r -- "$source_path" | sed -nE 's/.*([0-9]{4}-W[0-9]{2}).*/\1/p'
}

bootstrap_multiplier_from_mean() {
  local mean_value="$1"
  if [[ -z "$mean_value" || "$mean_value" == "n/a" ]]; then
    echo "1.000"
    return
  fi

  awk -v mean="$mean_value" 'BEGIN {
    opportunity = 72 - (mean + 0)
    if (opportunity < 0) opportunity = 0
    multiplier = 1.0 + (opportunity * 0.0055)
    if (multiplier < 0.92) multiplier = 0.92
    if (multiplier > 1.22) multiplier = 1.22
    printf "%.3f", multiplier
  }'
}

bootstrap_focus_signal() {
  awk \
    -v momentum="$momentum_mean" \
    -v distribution="$distribution_mean" \
    -v kpi="$kpi_mean" \
    -v reply="$reply_mean" \
    -v transcript="$transcript_mean" \
    'BEGIN {
      values["momentum core"] = momentum + 0
      values["distribution health"] = distribution + 0
      values["KPI trendline"] = kpi + 0
      values["reply quality"] = reply + 0
      values["transcript quality"] = transcript + 0

      focus = "momentum core"
      min_value = values[focus]
      for (label in values) {
        if (values[label] < min_value) {
          min_value = values[label]
          focus = label
        }
      }

      opportunity = 72 - min_value
      if (opportunity < 0) opportunity = 0
      printf "%s|%.2f", focus, opportunity
    }'
}

samples_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-uplift-samples.${$}.${RANDOM}.txt"
ordered_samples_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-uplift-samples-ordered.${$}.${RANDOM}.txt"
stats_file="${TMPDIR:-/tmp}/fluidreader-founder-fame-uplift-stats.${$}.${RANDOM}.txt"

cleanup() {
  rm -f "$samples_file" "$ordered_samples_file" "$stats_file"
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
  week_from_brief="$(extract_week_label "$brief_path")"
  momentum_core="$(extract_number "$(extract_prefixed_value "$brief_path" "- Momentum core: ")")"
  distribution_health="$(extract_number "$(extract_prefixed_value "$brief_path" "- Distribution health: ")")"
  kpi_trendline="$(extract_number "$(extract_prefixed_value "$brief_path" "- KPI trendline: ")")"
  reply_quality="$(extract_number "$(extract_prefixed_value "$brief_path" "- Reply quality: ")")"
  transcript_quality="$(extract_number "$(extract_prefixed_value "$brief_path" "- Transcript quality: ")")"
  readiness_score="$(extract_number "$(extract_prefixed_value "$brief_path" "- Fame readiness score: ")")"
  distribution_completion="$(extract_number "$(extract_prefixed_value "$brief_path" "- Distribution completion score: ")")"

  if [[ -z "$week_from_brief" || -z "$momentum_core" || -z "$distribution_health" || -z "$kpi_trendline" || -z "$reply_quality" || -z "$transcript_quality" || -z "$readiness_score" ]]; then
    continue
  fi

  if [[ -z "$distribution_completion" ]]; then
    distribution_completion=0
  fi

  echo "${week_from_brief}|${brief_path}|${readiness_score}|${momentum_core}|${distribution_health}|${kpi_trendline}|${reply_quality}|${transcript_quality}|${distribution_completion}" >> "$samples_file"
done

if [[ -s "$samples_file" ]]; then
  sort -t'|' -k1,1 "$samples_file" > "$ordered_samples_file"
else
  : > "$ordered_samples_file"
fi

sample_count="$(wc -l < "$ordered_samples_file" | tr -d ' ')"
if [[ -z "$sample_count" ]]; then
  sample_count=0
fi

mode="bootstrap (insufficient transitions)"
transition_count=0
avg_readiness_delta="n/a"
positive_delta_rate="n/a"
latest_readiness="n/a"
readiness_mean="n/a"
readiness_min="n/a"
readiness_max="n/a"
distribution_completion_mean="n/a"
distribution_completion_min="n/a"
distribution_completion_max="n/a"
top_leading_signal="n/a"
top_lift_value="n/a"

momentum_mean="n/a"
momentum_avg_delta="n/a"
momentum_strong_delta="n/a"
momentum_weak_delta="n/a"
momentum_lift="n/a"
momentum_uplift_multiplier="1.000"

distribution_mean="n/a"
distribution_avg_delta="n/a"
distribution_strong_delta="n/a"
distribution_weak_delta="n/a"
distribution_lift="n/a"
distribution_uplift_multiplier="1.000"

kpi_mean="n/a"
kpi_avg_delta="n/a"
kpi_strong_delta="n/a"
kpi_weak_delta="n/a"
kpi_lift="n/a"
kpi_uplift_multiplier="1.000"

reply_mean="n/a"
reply_avg_delta="n/a"
reply_strong_delta="n/a"
reply_weak_delta="n/a"
reply_lift="n/a"
reply_uplift_multiplier="1.000"

transcript_mean="n/a"
transcript_avg_delta="n/a"
transcript_strong_delta="n/a"
transcript_weak_delta="n/a"
transcript_lift="n/a"
transcript_uplift_multiplier="1.000"

if (( sample_count > 0 )); then
  awk -F'|' '
    BEGIN {
      signal[4] = "momentum"
      signal[5] = "distribution"
      signal[6] = "kpi"
      signal[7] = "reply"
      signal[8] = "transcript"
    }
    {
      count++
      readiness = $3 + 0
      distribution_completion = $9 + 0

      readiness_sum += readiness
      distribution_completion_sum += distribution_completion
      if (count == 1 || readiness < readiness_min) readiness_min = readiness
      if (count == 1 || readiness > readiness_max) readiness_max = readiness
      if (count == 1 || distribution_completion < distribution_completion_min) distribution_completion_min = distribution_completion
      if (count == 1 || distribution_completion > distribution_completion_max) distribution_completion_max = distribution_completion
      latest_readiness = readiness

      for (i = 4; i <= 8; i++) {
        value = $i + 0
        sample_sum[i] += value
        sample_count_signal[i]++
      }
    }
    END {
      if (count == 0) exit
      print "sample_count=" count
      print "transition_count=" (count > 1 ? count - 1 : 0)
      print "readiness_mean=" sprintf("%.1f", readiness_sum / count)
      print "readiness_min=" sprintf("%.1f", readiness_min)
      print "readiness_max=" sprintf("%.1f", readiness_max)
      print "distribution_completion_mean=" sprintf("%.1f", distribution_completion_sum / count)
      print "distribution_completion_min=" sprintf("%.1f", distribution_completion_min)
      print "distribution_completion_max=" sprintf("%.1f", distribution_completion_max)
      print "latest_readiness=" sprintf("%.1f", latest_readiness)

      for (s = 4; s <= 8; s++) {
        label = signal[s]
        mean_value = (sample_count_signal[s] > 0 ? sample_sum[s] / sample_count_signal[s] : 0)
        print label "_mean=" sprintf("%.1f", mean_value)
      }
    }' "$ordered_samples_file" > "$stats_file"

  # Detailed transition diagnostics with score deltas and uplift multipliers
  awk -F'|' '
    BEGIN {
      signal[4] = "momentum"
      signal[5] = "distribution"
      signal[6] = "kpi"
      signal[7] = "reply"
      signal[8] = "transcript"
    }
    {
      count++
      readiness[count] = $3 + 0
      for (s = 4; s <= 8; s++) {
        values[s, count] = $s + 0
      }
    }
    END {
      if (count < 2) {
        print "avg_readiness_delta=n/a"
        print "positive_delta_rate=n/a"
        print "top_leading_signal=n/a"
        print "top_lift_value=n/a"
        for (s = 4; s <= 8; s++) {
          label = signal[s]
          print label "_avg_delta=n/a"
          print label "_strong_delta=n/a"
          print label "_weak_delta=n/a"
          print label "_lift=n/a"
          print label "_uplift_multiplier=1.000"
        }
        exit
      }

      transitions = count - 1
      delta_sum = 0
      positive_deltas = 0

      for (i = 1; i < count; i++) {
        delta = readiness[i + 1] - readiness[i]
        delta_sum += delta
        if (delta > 0) positive_deltas++

        for (s = 4; s <= 8; s++) {
          score = values[s, i]
          pair_count[s]++
          delta_sum_signal[s] += delta

          if (score >= 70) {
            strong_count[s]++
            strong_delta_sum[s] += delta
          } else {
            weak_count[s]++
            weak_delta_sum[s] += delta
          }
        }
      }

      print "avg_readiness_delta=" sprintf("%.2f", delta_sum / transitions)
      print "positive_delta_rate=" sprintf("%.0f", (positive_deltas / transitions) * 100)

      top_label = "n/a"
      top_lift = -9999

      for (s = 4; s <= 8; s++) {
        label = signal[s]
        avg_delta = (pair_count[s] > 0 ? delta_sum_signal[s] / pair_count[s] : 0)
        strong_delta = (strong_count[s] > 0 ? strong_delta_sum[s] / strong_count[s] : avg_delta)
        weak_delta = (weak_count[s] > 0 ? weak_delta_sum[s] / weak_count[s] : avg_delta)
        lift = strong_delta - weak_delta

        mean_score = 0
        for (i = 1; i <= count; i++) {
          mean_score += values[s, i]
        }
        mean_score /= count

        opportunity = 70 - mean_score
        if (opportunity < 0) opportunity = 0
        lift_bonus = (lift > 0 ? lift : 0)

        if (transitions < 3) {
          multiplier = 1.0
        } else {
          multiplier = 1.0 + (opportunity * 0.006) + (lift_bonus * 0.030)
          if (multiplier < 0.80) multiplier = 0.80
          if (multiplier > 1.35) multiplier = 1.35
        }

        print label "_avg_delta=" sprintf("%.2f", avg_delta)
        print label "_strong_delta=" sprintf("%.2f", strong_delta)
        print label "_weak_delta=" sprintf("%.2f", weak_delta)
        print label "_lift=" sprintf("%.2f", lift)
        print label "_uplift_multiplier=" sprintf("%.3f", multiplier)

        if (lift > top_lift) {
          top_lift = lift
          if (label == "kpi") {
            top_label = "KPI trendline"
          } else if (label == "reply") {
            top_label = "reply quality"
          } else if (label == "transcript") {
            top_label = "transcript quality"
          } else if (label == "distribution") {
            top_label = "distribution health"
          } else {
            top_label = label
          }
        }
      }

      print "top_leading_signal=" top_label
      print "top_lift_value=" sprintf("%.2f", top_lift)
    }' "$ordered_samples_file" >> "$stats_file"

  while IFS='=' read -r key value || [[ -n "$key$value" ]]; do
    [[ -z "$key" ]] && continue
    case "$key" in
      transition_count) transition_count="${value}" ;;
      avg_readiness_delta) avg_readiness_delta="${value}" ;;
      positive_delta_rate) positive_delta_rate="${value}" ;;
      latest_readiness) latest_readiness="${value}" ;;
      readiness_mean) readiness_mean="${value}" ;;
      readiness_min) readiness_min="${value}" ;;
      readiness_max) readiness_max="${value}" ;;
      distribution_completion_mean) distribution_completion_mean="${value}" ;;
      distribution_completion_min) distribution_completion_min="${value}" ;;
      distribution_completion_max) distribution_completion_max="${value}" ;;
      top_leading_signal) top_leading_signal="${value}" ;;
      top_lift_value) top_lift_value="${value}" ;;
      momentum_mean) momentum_mean="${value}" ;;
      momentum_avg_delta) momentum_avg_delta="${value}" ;;
      momentum_strong_delta) momentum_strong_delta="${value}" ;;
      momentum_weak_delta) momentum_weak_delta="${value}" ;;
      momentum_lift) momentum_lift="${value}" ;;
      momentum_uplift_multiplier) momentum_uplift_multiplier="${value}" ;;
      distribution_mean) distribution_mean="${value}" ;;
      distribution_avg_delta) distribution_avg_delta="${value}" ;;
      distribution_strong_delta) distribution_strong_delta="${value}" ;;
      distribution_weak_delta) distribution_weak_delta="${value}" ;;
      distribution_lift) distribution_lift="${value}" ;;
      distribution_uplift_multiplier) distribution_uplift_multiplier="${value}" ;;
      kpi_mean) kpi_mean="${value}" ;;
      kpi_avg_delta) kpi_avg_delta="${value}" ;;
      kpi_strong_delta) kpi_strong_delta="${value}" ;;
      kpi_weak_delta) kpi_weak_delta="${value}" ;;
      kpi_lift) kpi_lift="${value}" ;;
      kpi_uplift_multiplier) kpi_uplift_multiplier="${value}" ;;
      reply_mean) reply_mean="${value}" ;;
      reply_avg_delta) reply_avg_delta="${value}" ;;
      reply_strong_delta) reply_strong_delta="${value}" ;;
      reply_weak_delta) reply_weak_delta="${value}" ;;
      reply_lift) reply_lift="${value}" ;;
      reply_uplift_multiplier) reply_uplift_multiplier="${value}" ;;
      transcript_mean) transcript_mean="${value}" ;;
      transcript_avg_delta) transcript_avg_delta="${value}" ;;
      transcript_strong_delta) transcript_strong_delta="${value}" ;;
      transcript_weak_delta) transcript_weak_delta="${value}" ;;
      transcript_lift) transcript_lift="${value}" ;;
      transcript_uplift_multiplier) transcript_uplift_multiplier="${value}" ;;
    esac
  done < "$stats_file"
fi

if [[ -z "$transition_count" ]]; then
  transition_count=0
fi

if (( sample_count > 0 && transition_count == 0 )); then
  mode="bootstrap-pressure"
  momentum_uplift_multiplier="$(bootstrap_multiplier_from_mean "$momentum_mean")"
  distribution_uplift_multiplier="$(bootstrap_multiplier_from_mean "$distribution_mean")"
  kpi_uplift_multiplier="$(bootstrap_multiplier_from_mean "$kpi_mean")"
  reply_uplift_multiplier="$(bootstrap_multiplier_from_mean "$reply_mean")"
  transcript_uplift_multiplier="$(bootstrap_multiplier_from_mean "$transcript_mean")"

  bootstrap_focus="$(bootstrap_focus_signal)"
  if [[ -n "$bootstrap_focus" && "$bootstrap_focus" == *"|"* ]]; then
    top_leading_signal="${bootstrap_focus%%|*}"
    top_lift_value="${bootstrap_focus#*|}"
  fi
fi

if (( transition_count >= 3 )); then
  mode="predictive"
elif (( transition_count >= 1 )); then
  mode="early-signal"
fi

calibration_confidence="$(awk -v samples="$sample_count" -v transitions="$transition_count" 'BEGIN {
  sample_component = samples * 9.0
  if (sample_component > 45) sample_component = 45
  transition_component = transitions * 18.0
  if (transition_component > 55) transition_component = 55
  score = sample_component + transition_component
  if (score > 100) score = 100
  if (score < 0) score = 0
  printf "%.0f", score
}')"

multiplier_vector="$(awk \
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
  sample_preview="$(awk -F'|' 'NR <= 4 { printf "- %s | readiness %s | source %s\n", $1, $3, $2 }' "$ordered_samples_file")"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-uplift-tracker -->

# Founder Fame Uplift Tracker - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Campaign directory: ${campaign_dir}

## Snapshot

- Samples analyzed: ${sample_count}
- Transitions analyzed: ${transition_count}
- Mode: ${mode}
- Calibration confidence: ${calibration_confidence}/100
- Latest readiness score: ${latest_readiness}
- Average readiness delta (next-week): ${avg_readiness_delta}
- Positive delta rate: ${positive_delta_rate}%
- Top leading signal: ${top_leading_signal} (lift ${top_lift_value})
- Readiness mean/min/max: ${readiness_mean} / ${readiness_min} / ${readiness_max}
- Distribution completion mean/min/max: ${distribution_completion_mean} / ${distribution_completion_min} / ${distribution_completion_max}

## Uplift Multipliers

- momentum uplift multiplier: ${momentum_uplift_multiplier}
- distribution uplift multiplier: ${distribution_uplift_multiplier}
- kpi trendline uplift multiplier: ${kpi_uplift_multiplier}
- reply quality uplift multiplier: ${reply_uplift_multiplier}
- transcript quality uplift multiplier: ${transcript_uplift_multiplier}
- Applied multiplier vector: ${multiplier_vector}

## Signal Diagnostics

| Signal | Mean Score | Avg Next-Week Delta | Strong-Bucket Delta | Weak-Bucket Delta | Lift (Strong-Weak) | Uplift Multiplier |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Momentum core | ${momentum_mean} | ${momentum_avg_delta} | ${momentum_strong_delta} | ${momentum_weak_delta} | ${momentum_lift} | ${momentum_uplift_multiplier} |
| Distribution health | ${distribution_mean} | ${distribution_avg_delta} | ${distribution_strong_delta} | ${distribution_weak_delta} | ${distribution_lift} | ${distribution_uplift_multiplier} |
| KPI trendline | ${kpi_mean} | ${kpi_avg_delta} | ${kpi_strong_delta} | ${kpi_weak_delta} | ${kpi_lift} | ${kpi_uplift_multiplier} |
| Reply quality | ${reply_mean} | ${reply_avg_delta} | ${reply_strong_delta} | ${reply_weak_delta} | ${reply_lift} | ${reply_uplift_multiplier} |
| Transcript quality | ${transcript_mean} | ${transcript_avg_delta} | ${transcript_strong_delta} | ${transcript_weak_delta} | ${transcript_lift} | ${transcript_uplift_multiplier} |

## Sample Inputs

${sample_preview}

## Calibration Notes

- With zero transitions, multipliers use snapshot-pressure bootstrap from current signal means.
- With one or more transitions, multipliers shift toward observed strong-vs-weak next-week lift.
- Strong/weak buckets use a 70-point split on each signal.
- Re-run weekly after new momentum briefs to improve predictive confidence.

## Share Block

\`\`\`text
Founder fame uplift tracker (${week_label})
Mode: ${mode}
Samples: ${sample_count}
Transitions: ${transition_count}
Top leading signal: ${top_leading_signal} (lift ${top_lift_value})
Multipliers: ${multiplier_vector}
\`\`\`
EOF

echo "Wrote founder fame uplift tracker: $output_path"
