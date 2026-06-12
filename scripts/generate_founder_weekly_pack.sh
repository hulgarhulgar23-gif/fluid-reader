#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate the full founder weekly pack in one command:
weekly review -> week-over-week delta -> scoreboard -> update post -> fame pack -> press kit -> media blast -> guesting queue -> guesting sprint brief.

Usage:
  zsh scripts/generate_founder_weekly_pack.sh [options]

Required:
  --previous-review <path>         Previous weekly review markdown file
  --mrr <number>                   Monthly recurring revenue
  --delivery-cost <number>         Monthly delivery/COGS cost
  --acquisition-spend <number>     Monthly acquisition spend
  --new-customers <number>         New customers in period
  --monthly-contribution <number>  Monthly contribution per customer
  --lifetime-months <number>       Expected customer lifetime in months
  --fixed-cost <number>            Fixed cost for break-even math
  --price <number>                 Unit price
  --variable-cost <number>         Unit variable cost
  --target-mrr <number>            Scoreboard target MRR
  --target-margin <number>         Scoreboard target margin percent
  --target-cac <number>            Scoreboard target CAC
  --target-ltv-cac <number>        Scoreboard target LTV/CAC
  --target-new-customers <number>  Scoreboard target new customers

Optional:
  --week <label>                   Week label (default: current ISO week)
  --previous-label <text>          Override previous label in delta report
  --out-dir <path>                 Output directory (default: .build/founder)
  --product <text>                 Product name for update post draft
  --primary-channel <text>         Primary channel for update post draft
  --backup-channel <text>          Backup channel for update post draft
  --guesting-signal-entries <value>      Founder guesting signal entries from checklist comments
  --guesting-signal-replied <value>      Founder guesting replied count from signals
  --guesting-signal-booked <value>       Founder guesting booked count from signals
  --guesting-signal-published <value>    Founder guesting published count from signals
  --guesting-signal-top-format <text>    Founder guesting top format from signals
  --guesting-signal-top-target <text>    Founder guesting top target from signals
  --guesting-signal-enrichment-score <value> Founder guesting enrichment score from signals
  --guesting-signal-recommendation <text> Founder guesting recommendation from signals
  --cta <text>                     CTA line for update post draft
  -h, --help                       Show help

Example:
  zsh scripts/generate_founder_weekly_pack.sh \
    --week "2026-W23" \
    --previous-review .build/founder/weekly-review-2026-W22.md \
    --mrr 42000 \
    --delivery-cost 19000 \
    --acquisition-spend 12000 \
    --new-customers 80 \
    --monthly-contribution 75 \
    --lifetime-months 18 \
    --fixed-cost 10000 \
    --price 50 \
    --variable-cost 30 \
    --target-mrr 50000 \
    --target-margin 55 \
    --target-cac 150 \
    --target-ltv-cac 3.5 \
    --target-new-customers 90
EOF
}

week_label="$(date '+%Y-W%V')"
previous_review_path=""
previous_label=""
mrr=""
delivery_cost=""
acquisition_spend=""
new_customers=""
monthly_contribution=""
lifetime_months=""
fixed_cost=""
price=""
variable_cost=""
target_mrr=""
target_margin=""
target_cac=""
target_ltv_cac=""
target_new_customers=""
output_dir=".build/founder"
product_name=""
primary_channel=""
backup_channel=""
cta_text=""
guesting_signal_entries="n/a"
guesting_signal_replied="n/a"
guesting_signal_booked="n/a"
guesting_signal_published="n/a"
guesting_signal_top_format="n/a"
guesting_signal_top_target="n/a"
guesting_signal_enrichment_score="n/a"
guesting_signal_recommendation="Capture founder guesting signal comments before Friday review."

while (( $# > 0 )); do
  case "$1" in
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --previous-review)
      previous_review_path="${2:-}"
      shift 2
      ;;
    --previous-label)
      previous_label="${2:-}"
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
    --out-dir)
      output_dir="${2:-}"
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
    --guesting-signal-entries)
      guesting_signal_entries="${2:-}"
      shift 2
      ;;
    --guesting-signal-replied)
      guesting_signal_replied="${2:-}"
      shift 2
      ;;
    --guesting-signal-booked)
      guesting_signal_booked="${2:-}"
      shift 2
      ;;
    --guesting-signal-published)
      guesting_signal_published="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-format)
      guesting_signal_top_format="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-target)
      guesting_signal_top_target="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score)
      guesting_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --guesting-signal-recommendation)
      guesting_signal_recommendation="${2:-}"
      shift 2
      ;;
    --cta)
      cta_text="${2:-}"
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
  "previous_review_path:$previous_review_path" \
  "mrr:$mrr" \
  "delivery_cost:$delivery_cost" \
  "acquisition_spend:$acquisition_spend" \
  "new_customers:$new_customers" \
  "monthly_contribution:$monthly_contribution" \
  "lifetime_months:$lifetime_months" \
  "fixed_cost:$fixed_cost" \
  "price:$price" \
  "variable_cost:$variable_cost" \
  "target_mrr:$target_mrr" \
  "target_margin:$target_margin" \
  "target_cac:$target_cac" \
  "target_ltv_cac:$target_ltv_cac" \
  "target_new_customers:$target_new_customers" \
  "output_dir:$output_dir"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

if [[ ! -f "$previous_review_path" ]]; then
  echo "Previous review file not found: $previous_review_path" >&2
  exit 1
fi

is_number() {
  local value="$1"
  awk -v v="$value" 'BEGIN { exit !(v ~ /^[-+]?[0-9]*\.?[0-9]+$/) }'
}

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
  "target_mrr:$target_mrr" \
  "target_margin:$target_margin" \
  "target_cac:$target_cac" \
  "target_ltv_cac:$target_ltv_cac" \
  "target_new_customers:$target_new_customers"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if ! is_number "$value"; then
    echo "Invalid numeric value for ${key}: $value" >&2
    exit 1
  fi
done

safe_slug() {
  echo "$1" \
    | tr '[:space:]/:' '-' \
    | tr -cd '[:alnum:]_.-' \
    | sed -E 's/-+/-/g; s/^-+|-+$//g'
}

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

week_slug="$(safe_slug "$week_label")"
if [[ -z "$week_slug" ]]; then
  week_slug="$(date '+%Y-W%V')"
fi

review_out="${output_dir}/weekly-review-${week_slug}.md"
delta_out="${output_dir}/weekly-delta-${week_slug}.md"
scoreboard_out="${output_dir}/scoreboard-${week_slug}.md"
post_out="${output_dir}/founder-update-${week_slug}.md"
fame_pack_out="${output_dir}/founder-fame-pack-${week_slug}.md"
press_kit_out="${output_dir}/founder-press-kit-${week_slug}.md"
media_blast_out="${output_dir}/founder-media-blast-${week_slug}.md"
guesting_queue_out="${output_dir}/founder-guesting-queue-${week_slug}.md"
guesting_brief_out="${output_dir}/founder-guesting-brief-${week_slug}.md"

mkdir -p "$output_dir"

zsh scripts/generate_founder_weekly_review.sh \
  --week "$week_label" \
  --mrr "$mrr" \
  --delivery-cost "$delivery_cost" \
  --acquisition-spend "$acquisition_spend" \
  --new-customers "$new_customers" \
  --monthly-contribution "$monthly_contribution" \
  --lifetime-months "$lifetime_months" \
  --fixed-cost "$fixed_cost" \
  --price "$price" \
  --variable-cost "$variable_cost" \
  --out "$review_out"

delta_args=(
  --previous "$previous_review_path"
  --current "$review_out"
  --out "$delta_out"
  --label-current "$week_label"
)

if [[ -n "$previous_label" ]]; then
  delta_args+=(--label-prev "$previous_label")
fi

zsh scripts/generate_founder_weekly_delta.sh "${delta_args[@]}"

margin_raw="$(awk -v r="$mrr" -v c="$delivery_cost" 'BEGIN {
  if (r == 0) {
    print "n/a"
  } else {
    printf "%.6f", (((r - c) / r) * 100)
  }
}')"
cac_raw="$(safe_div "$acquisition_spend" "$new_customers")"
ltv_raw="$(awk -v m="$monthly_contribution" -v l="$lifetime_months" 'BEGIN { printf "%.6f", (m * l) }')"
ltv_cac_raw="$(if [[ "$cac_raw" == "n/a" ]]; then echo "n/a"; else safe_div "$ltv_raw" "$cac_raw"; fi)"

actual_margin="$(if [[ "$margin_raw" == "n/a" ]]; then echo "n/a"; else format_number "$margin_raw"; fi)"
actual_cac="$(if [[ "$cac_raw" == "n/a" ]]; then echo "n/a"; else format_number "$cac_raw"; fi)"
actual_ltv_cac="$(if [[ "$ltv_cac_raw" == "n/a" ]]; then echo "n/a"; else format_number "$ltv_cac_raw"; fi)"

zsh scripts/generate_founder_scoreboard.sh \
  --week "$week_label" \
  --target-mrr "$target_mrr" \
  --target-margin "$target_margin" \
  --target-cac "$target_cac" \
  --target-ltv-cac "$target_ltv_cac" \
  --target-new-customers "$target_new_customers" \
  --actual-mrr "$mrr" \
  --actual-margin "$actual_margin" \
  --actual-cac "$actual_cac" \
  --actual-ltv-cac "$actual_ltv_cac" \
  --actual-new-customers "$new_customers" \
  --out "$scoreboard_out"

post_args=(
  --scoreboard "$scoreboard_out"
  --delta "$delta_out"
  --week "$week_label"
  --out "$post_out"
)

if [[ -n "$product_name" ]]; then
  post_args+=(--product "$product_name")
fi
if [[ -n "$primary_channel" ]]; then
  post_args+=(--primary-channel "$primary_channel")
fi
if [[ -n "$backup_channel" ]]; then
  post_args+=(--backup-channel "$backup_channel")
fi
if [[ -n "$cta_text" ]]; then
  post_args+=(--cta "$cta_text")
fi

zsh scripts/generate_founder_update_post.sh "${post_args[@]}"

fame_pack_args=(
  --scoreboard "$scoreboard_out"
  --delta "$delta_out"
  --week "$week_label"
  --out "$fame_pack_out"
)

if [[ -n "$product_name" ]]; then
  fame_pack_args+=(--product "$product_name")
fi
if [[ -n "$primary_channel" ]]; then
  fame_pack_args+=(--primary-channel "$primary_channel")
fi
if [[ -n "$backup_channel" ]]; then
  fame_pack_args+=(--backup-channel "$backup_channel")
fi
if [[ -n "$cta_text" ]]; then
  fame_pack_args+=(--cta "$cta_text")
fi

zsh scripts/generate_founder_fame_pack.sh "${fame_pack_args[@]}"

press_kit_args=(
  --fame-pack "$fame_pack_out"
  --week "$week_label"
  --out "$press_kit_out"
)

if [[ -n "$product_name" ]]; then
  press_kit_args+=(--product "$product_name")
fi
if [[ -n "$primary_channel" ]]; then
  press_kit_args+=(--primary-channel "$primary_channel")
fi
if [[ -n "$backup_channel" ]]; then
  press_kit_args+=(--backup-channel "$backup_channel")
fi
if [[ -n "$cta_text" ]]; then
  press_kit_args+=(--cta "$cta_text")
fi

zsh scripts/generate_founder_press_kit.sh "${press_kit_args[@]}"

media_blast_args=(
  --fame-pack "$fame_pack_out"
  --press-kit "$press_kit_out"
  --update-post "$post_out"
  --week "$week_label"
  --out "$media_blast_out"
)

if [[ -n "$product_name" ]]; then
  media_blast_args+=(--product "$product_name")
fi
if [[ -n "$primary_channel" ]]; then
  media_blast_args+=(--primary-channel "$primary_channel")
fi
if [[ -n "$backup_channel" ]]; then
  media_blast_args+=(--backup-channel "$backup_channel")
fi
if [[ -n "$cta_text" ]]; then
  media_blast_args+=(--cta "$cta_text")
fi

zsh scripts/generate_founder_media_blast.sh "${media_blast_args[@]}"

guesting_queue_args=(
  --fame-pack "$fame_pack_out"
  --press-kit "$press_kit_out"
  --media-blast "$media_blast_out"
  --week "$week_label"
  --guesting-signal-entries "$guesting_signal_entries"
  --guesting-signal-replied "$guesting_signal_replied"
  --guesting-signal-booked "$guesting_signal_booked"
  --guesting-signal-published "$guesting_signal_published"
  --guesting-signal-top-format "$guesting_signal_top_format"
  --guesting-signal-top-target "$guesting_signal_top_target"
  --guesting-signal-enrichment-score "$guesting_signal_enrichment_score"
  --guesting-signal-recommendation "$guesting_signal_recommendation"
  --out "$guesting_queue_out"
)

if [[ -n "$product_name" ]]; then
  guesting_queue_args+=(--product "$product_name")
fi
if [[ -n "$primary_channel" ]]; then
  guesting_queue_args+=(--primary-channel "$primary_channel")
fi
if [[ -n "$backup_channel" ]]; then
  guesting_queue_args+=(--backup-channel "$backup_channel")
fi
if [[ -n "$cta_text" ]]; then
  guesting_queue_args+=(--cta "$cta_text")
fi

zsh scripts/generate_founder_guesting_queue.sh "${guesting_queue_args[@]}"

guesting_brief_args=(
  --guesting-queue "$guesting_queue_out"
  --fame-pack "$fame_pack_out"
  --media-blast "$media_blast_out"
  --week "$week_label"
  --out "$guesting_brief_out"
)

if [[ -n "$product_name" ]]; then
  guesting_brief_args+=(--product "$product_name")
fi
if [[ -n "$primary_channel" ]]; then
  guesting_brief_args+=(--primary-channel "$primary_channel")
fi
if [[ -n "$backup_channel" ]]; then
  guesting_brief_args+=(--backup-channel "$backup_channel")
fi
if [[ -n "$cta_text" ]]; then
  guesting_brief_args+=(--cta "$cta_text")
fi

zsh scripts/generate_founder_guesting_brief.sh "${guesting_brief_args[@]}"

cat <<EOF
Generated founder weekly pack:
- Review: $review_out
- Delta: $delta_out
- Scoreboard: $scoreboard_out
- Update post: $post_out
- Fame pack: $fame_pack_out
- Press kit: $press_kit_out
- Media blast: $media_blast_out
- Guesting queue: $guesting_queue_out
- Guesting sprint brief: $guesting_brief_out
EOF
