#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder KPI scoreboard markdown file.

Usage:
  zsh scripts/generate_founder_scoreboard.sh [options]

Required:
  --target-mrr <number>
  --target-margin <number>          Target margin percent
  --target-cac <number>
  --target-ltv-cac <number>
  --target-new-customers <number>
  --out <path>

Optional:
  --week <label>                    Week label (default: current ISO week)
  --actual-mrr <number>
  --actual-margin <number>
  --actual-cac <number>
  --actual-ltv-cac <number>
  --actual-new-customers <number>
  -h, --help

Example:
  zsh scripts/generate_founder_scoreboard.sh \
    --week "$(date +%Y-W%V)" \
    --target-mrr 50000 \
    --target-margin 55 \
    --target-cac 150 \
    --target-ltv-cac 3.5 \
    --target-new-customers 90 \
    --actual-mrr 48000 \
    --actual-margin 53 \
    --actual-cac 160 \
    --actual-ltv-cac 3.2 \
    --actual-new-customers 84 \
    --out .build/founder/scoreboard.md
EOF
}

week_label="$(date '+%Y-W%V')"
target_mrr=""
target_margin=""
target_cac=""
target_ltv_cac=""
target_new_customers=""
actual_mrr="n/a"
actual_margin="n/a"
actual_cac="n/a"
actual_ltv_cac="n/a"
actual_new_customers="n/a"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --target-mrr)
      target_mrr="${2:-}"
      shift 2
      ;;
    --target-margin)
      target_margin="${2:-}"
      shift 2
      ;;
    --target-cac)
      target_cac="${2:-}"
      shift 2
      ;;
    --target-ltv-cac)
      target_ltv_cac="${2:-}"
      shift 2
      ;;
    --target-new-customers)
      target_new_customers="${2:-}"
      shift 2
      ;;
    --actual-mrr)
      actual_mrr="${2:-}"
      shift 2
      ;;
    --actual-margin)
      actual_margin="${2:-}"
      shift 2
      ;;
    --actual-cac)
      actual_cac="${2:-}"
      shift 2
      ;;
    --actual-ltv-cac)
      actual_ltv_cac="${2:-}"
      shift 2
      ;;
    --actual-new-customers)
      actual_new_customers="${2:-}"
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

is_number() {
  local value="$1"
  awk -v v="$value" 'BEGIN { exit !(v ~ /^[-+]?[0-9]*\.?[0-9]+$/) }'
}

require_number() {
  local key="$1"
  local value="$2"
  if [[ -z "$value" ]] || ! is_number "$value"; then
    echo "Missing or invalid numeric value for ${key}." >&2
    exit 1
  fi
}

optional_number() {
  local key="$1"
  local value="$2"
  if [[ "$value" == "n/a" ]]; then
    return 0
  fi
  if ! is_number "$value"; then
    echo "Invalid numeric value for ${key}: $value" >&2
    exit 1
  fi
}

require_number "target_mrr" "$target_mrr"
require_number "target_margin" "$target_margin"
require_number "target_cac" "$target_cac"
require_number "target_ltv_cac" "$target_ltv_cac"
require_number "target_new_customers" "$target_new_customers"

optional_number "actual_mrr" "$actual_mrr"
optional_number "actual_margin" "$actual_margin"
optional_number "actual_cac" "$actual_cac"
optional_number "actual_ltv_cac" "$actual_ltv_cac"
optional_number "actual_new_customers" "$actual_new_customers"

if [[ -z "$output_path" ]]; then
  echo "Missing required --out path." >&2
  exit 1
fi

format_number() {
  awk -v v="$1" 'BEGIN { printf "%.2f", v }' | sed -E 's/\.00$//; s/([0-9])0$/\1/'
}

delta_value() {
  local target="$1"
  local actual="$2"
  if [[ "$actual" == "n/a" ]]; then
    echo "n/a"
    return
  fi

  local raw
  raw="$(awk -v t="$target" -v a="$actual" 'BEGIN { printf "%.6f", (a - t) }')"
  local formatted
  formatted="$(format_number "$raw")"
  if [[ "$formatted" == "0" ]]; then
    echo "0"
  elif [[ "$formatted" == -* ]]; then
    echo "$formatted"
  else
    echo "+$formatted"
  fi
}

status_higher_better() {
  local target="$1"
  local actual="$2"
  if [[ "$actual" == "n/a" ]]; then
    echo "Pending"
    return
  fi

  if awk -v t="$target" -v a="$actual" 'BEGIN { exit !(a >= t) }'; then
    echo "On Track"
  elif awk -v t="$target" -v a="$actual" 'BEGIN { exit !(a >= (t * 0.9)) }'; then
    echo "At Risk"
  else
    echo "Off Track"
  fi
}

status_lower_better() {
  local target="$1"
  local actual="$2"
  if [[ "$actual" == "n/a" ]]; then
    echo "Pending"
    return
  fi

  if awk -v t="$target" -v a="$actual" 'BEGIN { exit !(a <= t) }'; then
    echo "On Track"
  elif awk -v t="$target" -v a="$actual" 'BEGIN { exit !(a <= (t * 1.1)) }'; then
    echo "At Risk"
  else
    echo "Off Track"
  fi
}

mrr_status="$(status_higher_better "$target_mrr" "$actual_mrr")"
margin_status="$(status_higher_better "$target_margin" "$actual_margin")"
cac_status="$(status_lower_better "$target_cac" "$actual_cac")"
ltv_cac_status="$(status_higher_better "$target_ltv_cac" "$actual_ltv_cac")"
customers_status="$(status_higher_better "$target_new_customers" "$actual_new_customers")"

mrr_delta="$(delta_value "$target_mrr" "$actual_mrr")"
margin_delta="$(delta_value "$target_margin" "$actual_margin")"
cac_delta="$(delta_value "$target_cac" "$actual_cac")"
ltv_cac_delta="$(delta_value "$target_ltv_cac" "$actual_ltv_cac")"
customers_delta="$(delta_value "$target_new_customers" "$actual_new_customers")"

on_track_count=0
at_risk_count=0
off_track_count=0

for kpi_status in "$mrr_status" "$margin_status" "$cac_status" "$ltv_cac_status" "$customers_status"; do
  case "$kpi_status" in
    "On Track")
      on_track_count=$((on_track_count + 1))
      ;;
    "At Risk")
      at_risk_count=$((at_risk_count + 1))
      ;;
    "Off Track")
      off_track_count=$((off_track_count + 1))
      ;;
  esac
done

summary="Balanced scoreboard. Keep improving weakest KPI."
if (( off_track_count >= 2 )); then
  summary="Multiple KPIs are off track. Focus on one core bottleneck this week."
elif (( on_track_count >= 4 && off_track_count == 0 )); then
  summary="Strong week. Most KPIs are on track."
fi

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder KPI Scoreboard - ${week_label}

## Snapshot

- On Track: ${on_track_count}
- At Risk: ${at_risk_count}
- Off Track: ${off_track_count}
- Summary: ${summary}

## KPI Table

| KPI | Target | Actual | Delta (Actual - Target) | Status | Direction |
|---|---:|---:|---:|---|---|
| MRR | ${target_mrr} | ${actual_mrr} | ${mrr_delta} | ${mrr_status} | Higher is better |
| Margin % | ${target_margin} | ${actual_margin} | ${margin_delta} | ${margin_status} | Higher is better |
| CAC | ${target_cac} | ${actual_cac} | ${cac_delta} | ${cac_status} | Lower is better |
| LTV/CAC | ${target_ltv_cac} | ${actual_ltv_cac} | ${ltv_cac_delta} | ${ltv_cac_status} | Higher is better |
| New customers | ${target_new_customers} | ${actual_new_customers} | ${customers_delta} | ${customers_status} | Higher is better |

## Weekly Actions

1. Keep one KPI owner per metric.
2. If any KPI is \`Off Track\`, choose one recovery experiment.
3. Re-run this scoreboard after updates and share with the team.
EOF

echo "Wrote founder scoreboard to: $output_path"
