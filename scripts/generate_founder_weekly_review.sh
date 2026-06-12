#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder weekly KPI review markdown file.

Usage:
  zsh scripts/generate_founder_weekly_review.sh [options]

Required options:
  --mrr <number>                   Monthly recurring revenue
  --delivery-cost <number>         Monthly delivery/COGS cost
  --acquisition-spend <number>     Monthly acquisition spend
  --new-customers <number>         New customers in period
  --monthly-contribution <number>  Monthly contribution per customer
  --lifetime-months <number>       Expected customer lifetime in months
  --fixed-cost <number>            Fixed cost for break-even math
  --price <number>                 Unit price
  --variable-cost <number>         Unit variable cost
  --out <path>                     Output markdown path

Optional:
  --week <label>                   Week label (default: current ISO week)
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_weekly_review.sh \
    --week "$(date +%Y-W%V)" \
    --mrr 42000 \
    --delivery-cost 19000 \
    --acquisition-spend 12000 \
    --new-customers 80 \
    --monthly-contribution 75 \
    --lifetime-months 18 \
    --fixed-cost 10000 \
    --price 50 \
    --variable-cost 30 \
    --out .build/founder/weekly-review.md
EOF
}

week_label="$(date '+%Y-W%V')"
mrr=""
delivery_cost=""
acquisition_spend=""
new_customers=""
monthly_contribution=""
lifetime_months=""
fixed_cost=""
price=""
variable_cost=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --mrr)
      mrr="${2:-}"
      shift 2
      ;;
    --delivery-cost)
      delivery_cost="${2:-}"
      shift 2
      ;;
    --acquisition-spend)
      acquisition_spend="${2:-}"
      shift 2
      ;;
    --new-customers)
      new_customers="${2:-}"
      shift 2
      ;;
    --monthly-contribution)
      monthly_contribution="${2:-}"
      shift 2
      ;;
    --lifetime-months)
      lifetime_months="${2:-}"
      shift 2
      ;;
    --fixed-cost)
      fixed_cost="${2:-}"
      shift 2
      ;;
    --price)
      price="${2:-}"
      shift 2
      ;;
    --variable-cost)
      variable_cost="${2:-}"
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
  "mrr:$mrr" \
  "delivery_cost:$delivery_cost" \
  "acquisition_spend:$acquisition_spend" \
  "new_customers:$new_customers" \
  "monthly_contribution:$monthly_contribution" \
  "lifetime_months:$lifetime_months" \
  "fixed_cost:$fixed_cost" \
  "price:$price" \
  "variable_cost:$variable_cost" \
  "output_path:$output_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

format_number() {
  awk -v v="$1" 'BEGIN { printf "%.2f", v }' | sed -E 's/\.00$//; s/([0-9])0$/\1/'
}

safe_div() {
  local numerator="$1"
  local denominator="$2"
  awk -v n="$numerator" -v d="$denominator" 'BEGIN {
    if (d == 0) {
      print "n/a"
    } else {
      printf "%.6f", (n / d)
    }
  }'
}

safe_pct() {
  local numerator="$1"
  local denominator="$2"
  awk -v n="$numerator" -v d="$denominator" 'BEGIN {
    if (d == 0) {
      print "n/a"
    } else {
      printf "%.6f", ((n / d) * 100)
    }
  }'
}

margin_pct_raw="$(safe_pct "$(awk -v r="$mrr" -v c="$delivery_cost" 'BEGIN { print (r - c) }')" "$mrr")"
roi_pct_raw="$(safe_pct "$(awk -v r="$mrr" -v c="$delivery_cost" 'BEGIN { print (r - c) }')" "$delivery_cost")"
cac_raw="$(safe_div "$acquisition_spend" "$new_customers")"
ltv_raw="$(awk -v m="$monthly_contribution" -v l="$lifetime_months" 'BEGIN { printf "%.6f", (m * l) }')"
ltv_cac_ratio_raw="$(if [[ "$cac_raw" == "n/a" ]]; then echo "n/a"; else safe_div "$ltv_raw" "$cac_raw"; fi)"
breakeven_units_raw="$(safe_div "$fixed_cost" "$(awk -v p="$price" -v v="$variable_cost" 'BEGIN { print (p - v) }')")"

margin_pct="$(if [[ "$margin_pct_raw" == "n/a" ]]; then echo "n/a"; else format_number "$margin_pct_raw"; fi)"
roi_pct="$(if [[ "$roi_pct_raw" == "n/a" ]]; then echo "n/a"; else format_number "$roi_pct_raw"; fi)"
cac="$(if [[ "$cac_raw" == "n/a" ]]; then echo "n/a"; else format_number "$cac_raw"; fi)"
ltv="$(format_number "$ltv_raw")"
ltv_cac_ratio="$(if [[ "$ltv_cac_ratio_raw" == "n/a" ]]; then echo "n/a"; else format_number "$ltv_cac_ratio_raw"; fi)"
breakeven_units="$(if [[ "$breakeven_units_raw" == "n/a" ]]; then echo "n/a"; else format_number "$breakeven_units_raw"; fi)"

momentum_note="Balanced momentum."
if [[ "$ltv_cac_ratio" != "n/a" ]]; then
  if awk -v value="$ltv_cac_ratio" 'BEGIN { exit !(value < 3) }'; then
    momentum_note="LTV/CAC is below 3. Prioritize acquisition efficiency or retention lift."
  elif awk -v value="$ltv_cac_ratio" 'BEGIN { exit !(value >= 4) }'; then
    momentum_note="LTV/CAC is strong (>=4). Consider controlled acquisition expansion."
  fi
fi

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Weekly Review - ${week_label}

## Inputs

- MRR: ${mrr}
- Delivery cost: ${delivery_cost}
- Acquisition spend: ${acquisition_spend}
- New customers: ${new_customers}
- Monthly contribution per customer: ${monthly_contribution}
- Lifetime months: ${lifetime_months}
- Fixed cost: ${fixed_cost}
- Price: ${price}
- Variable cost: ${variable_cost}

## Computed KPIs

- Margin: ${margin_pct}%  (formula: \`margin ${mrr} ${delivery_cost}\`)
- ROI: ${roi_pct}%  (formula: \`roi ${mrr} ${delivery_cost}\`)
- CAC: ${cac}  (formula: \`cac ${acquisition_spend} ${new_customers}\`)
- LTV: ${ltv}  (formula: \`ltv ${monthly_contribution} ${lifetime_months}\`)
- LTV/CAC ratio: ${ltv_cac_ratio}
- Break-even units: ${breakeven_units}  (formula: \`breakeven ${fixed_cost} ${price} ${variable_cost}\`)

## Founder Readout

- ${momentum_note}
- If margin is low, improve delivery efficiency before scaling spend.
- If CAC rises week-over-week, tighten channels and messaging before budget increase.
- Re-check this sheet weekly with fresh inputs.
EOF

echo "Wrote founder weekly review to: $output_path"
