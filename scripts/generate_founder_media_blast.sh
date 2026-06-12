#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder media blast plan from fame pack + press kit + update post artifacts.

Usage:
  zsh scripts/generate_founder_media_blast.sh [options]

Required:
  --fame-pack <path>       Founder fame pack markdown
  --press-kit <path>       Founder press kit markdown
  --update-post <path>     Founder update post pack markdown
  --out <path>             Output markdown path

Optional:
  --week <label>           Week label override (default: inferred from fame pack)
  --product <text>         Product name (default: Fluid Reader)
  --primary-channel <text> Primary channel label (default: X / Threads)
  --backup-channel <text>  Backup channel label (default: LinkedIn)
  --cta <text>             CTA line for outreach blocks
  -h, --help               Show help

Example:
  zsh scripts/generate_founder_media_blast.sh \
    --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
    --press-kit .build/founder/founder-press-kit-2026-W23.md \
    --update-post .build/founder/founder-update-2026-W23.md \
    --out .build/founder/founder-media-blast-2026-W23.md
EOF
}

fame_pack_path=""
press_kit_path=""
update_post_path=""
output_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="If this helps, reply with your KPI bottleneck and I will share the exact weekly execution command stack."

while (( $# > 0 )); do
  case "$1" in
    --fame-pack)
      fame_pack_path="${2:-}"
      shift 2
      ;;
    --press-kit)
      press_kit_path="${2:-}"
      shift 2
      ;;
    --update-post)
      update_post_path="${2:-}"
      shift 2
      ;;
    --out)
      output_path="${2:-}"
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
  "press_kit_path:$press_kit_path" \
  "update_post_path:$update_post_path" \
  "output_path:$output_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

for required_file in "$fame_pack_path" "$press_kit_path" "$update_post_path"; do
  if [[ ! -f "$required_file" ]]; then
    echo "Required file not found: $required_file" >&2
    exit 1
  fi
done

trim() {
  echo "$1" | sed -E 's/^ +| +$//g'
}

extract_heading_suffix() {
  local file="$1"
  local prefix="$2"
  local label
  label="$(sed -n "s/^# ${prefix} - //p" "$file" | head -n 1)"
  if [[ -z "$label" ]]; then
    echo "n/a"
  else
    echo "$label"
  fi
}

extract_bullet_value() {
  local file="$1"
  local key="$2"
  local line
  line="$(grep -E "^- ${key}:" "$file" | head -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  local prefix="- ${key}:"
  trim "${line#${prefix}}"
}

extract_numbered_line() {
  local file="$1"
  local section_heading="$2"
  local index="$3"
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
  ' "$file"
}

fame_heading="$(extract_heading_suffix "$fame_pack_path" "Founder Fame Pack")"
press_heading="$(extract_heading_suffix "$press_kit_path" "Founder Press Kit")"
update_heading="$(extract_heading_suffix "$update_post_path" "Founder Update Post Pack")"

if [[ -z "$week_label" ]]; then
  week_label="$fame_heading"
fi
if [[ -z "$week_label" || "$week_label" == "n/a" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

momentum_score="$(extract_bullet_value "$fame_pack_path" "Momentum score")"
scoreboard_state="$(extract_bullet_value "$fame_pack_path" "Scoreboard state")"
focus_line="$(extract_bullet_value "$fame_pack_path" "Current focus")"

update_summary="$(extract_bullet_value "$update_post_path" "Weekly summary")"
update_mrr="$(extract_bullet_value "$update_post_path" "MRR")"
update_cac="$(extract_bullet_value "$update_post_path" "CAC")"
update_ltv_cac="$(extract_bullet_value "$update_post_path" "LTV/CAC")"

headline_1="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 1)"
headline_2="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 2)"
headline_3="$(extract_numbered_line "$press_kit_path" "## Headline Angles" 3)"

if [[ -z "$momentum_score" || "$momentum_score" == "n/a" ]]; then
  momentum_score="n/a"
fi
if [[ -z "$scoreboard_state" || "$scoreboard_state" == "n/a" ]]; then
  scoreboard_state="n/a"
fi
if [[ -z "$focus_line" || "$focus_line" == "n/a" ]]; then
  focus_line="Ship one focused KPI repair experiment and publish proof within 72 hours."
fi
if [[ -z "$update_summary" || "$update_summary" == "n/a" ]]; then
  update_summary="Weekly summary unavailable; re-run founder update post generation."
fi
if [[ -z "$update_mrr" || "$update_mrr" == "n/a" ]]; then
  update_mrr="n/a"
fi
if [[ -z "$update_cac" || "$update_cac" == "n/a" ]]; then
  update_cac="n/a"
fi
if [[ -z "$update_ltv_cac" || "$update_ltv_cac" == "n/a" ]]; then
  update_ltv_cac="n/a"
fi
if [[ -z "$headline_1" ]]; then
  headline_1="Founder KPI loop translates weekly execution into public proof.";
fi
if [[ -z "$headline_2" ]]; then
  headline_2="Small-team operating cadence compounds reach without bloating process.";
fi
if [[ -z "$headline_3" ]]; then
  headline_3="One weekly narrative, one KPI bottleneck, one measurable experiment.";
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Media Blast - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source fame pack: ${fame_heading}
Source press kit: ${press_heading}
Source update post: ${update_heading}

## Blast Objective

- Momentum signal: ${momentum_score}
- Scoreboard state: ${scoreboard_state}
- Weekly narrative: ${update_summary}
- Current focus: ${focus_line}

## Channel Sequence

1. Day 1 (${primary_channel}): publish primary KPI narrative + first proof point.
2. Day 2 (${primary_channel}): post objection-handling thread with metric context.
3. Day 3 (${backup_channel}): publish reformatted operator recap.
4. Day 4 (${primary_channel}): ship workflow breakdown with one command stack screenshot.
5. Day 5 (${backup_channel}): publish lesson-learned + next experiment preview.
6. Day 6 (Community): distribute creator/community DM wave with one clear ask.
7. Day 7 (Recap): post what changed + what ships next week.

## Content Queue

- Headline A: ${headline_1}
- Headline B: ${headline_2}
- Headline C: ${headline_3}
- KPI card: MRR (${update_mrr})
- Efficiency card: CAC (${update_cac})
- Unit economics card: LTV/CAC (${update_ltv_cac})

## Creator DM Wave

- Segment 1 (operator creators): ask for workflow feedback + one quote.
- Segment 2 (community mods): offer short AMA-style breakdown.
- Segment 3 (newsletter writers): pitch one metrics-backed founder story.
- CTA script: ${cta_text}

## Community Reply Ops

- Response SLA: reply to high-signal comments within 4 hours.
- Objection queue: cluster into pricing, onboarding, and proof gaps.
- FAQ updates: convert recurring objections into docs updates weekly.
- Escalation trigger: if one objection appears 5+ times, publish dedicated answer post.

## Daily KPI Capture

- Reach KPI: impressions / views per post by channel.
- Quality KPI: meaningful replies and follow-up conversations.
- Conversion KPI: installs / trials attributed to blast posts.
- Pipeline KPI: creator replies, collaborations, cross-posts.
- Learning KPI: new objections converted into product/docs tasks.

## Escalation Playbook

1. If reach drops for 2 consecutive posts, rotate headline angle and opening hook.
2. If replies rise but conversions lag, tighten CTA and add one concrete next step.
3. If CAC narrative draws skepticism, publish transparent assumptions in a follow-up.
4. If no channel outperforms, rebalance to 50/50 and run a 7-day controlled test.
5. If one channel outperforms by >20%, reallocate next-week blast capacity toward it.
EOF

echo "Wrote founder media blast: $output_path"
