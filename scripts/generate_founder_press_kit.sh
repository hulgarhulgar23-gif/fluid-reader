#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a founder press kit from a founder fame pack markdown artifact.

Usage:
  zsh scripts/generate_founder_press_kit.sh [options]

Required:
  --fame-pack <path>       Fame pack markdown from generate_founder_fame_pack.sh
  --out <path>             Output markdown path

Optional:
  --week <label>           Week label override (default: inferred from fame pack heading)
  --product <text>         Product name (default: Fluid Reader)
  --primary-channel <text> Primary channel label (default: X / Threads)
  --backup-channel <text>  Backup channel label (default: LinkedIn)
  --cta <text>             CTA line used in outreach snippets
  -h, --help               Show help

Example:
  zsh scripts/generate_founder_press_kit.sh \
    --fame-pack .build/founder/founder-fame-pack-2026-W23.md \
    --out .build/founder/founder-press-kit-2026-W23.md
EOF
}

fame_pack_path=""
output_path=""
week_label=""
product_name="Fluid Reader"
primary_channel="X / Threads"
backup_channel="LinkedIn"
cta_text="If this is useful, reply and I will share the exact weekly KPI and distribution execution workflow."

while (( $# > 0 )); do
  case "$1" in
    --fame-pack)
      fame_pack_path="${2:-}"
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
  "output_path:$output_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

if [[ ! -f "$fame_pack_path" ]]; then
  echo "Fame pack file not found: $fame_pack_path" >&2
  exit 1
fi

trim() {
  echo "$1" | sed -E 's/^ +| +$//g'
}

extract_heading_label() {
  local file="$1"
  local label
  label="$(sed -n 's/^# Founder Fame Pack - //p' "$file" | head -n 1)"
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
  local value="${line#${prefix}}"
  trim "$value"
}

source_heading="$(extract_heading_label "$fame_pack_path")"
if [[ -z "$week_label" ]]; then
  week_label="$source_heading"
fi
if [[ -z "$week_label" || "$week_label" == "n/a" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

momentum_score="$(extract_bullet_value "$fame_pack_path" "Momentum score")"
scoreboard_state="$(extract_bullet_value "$fame_pack_path" "Scoreboard state")"
focus_line="$(extract_bullet_value "$fame_pack_path" "Current focus")"
mrr_line="$(extract_bullet_value "$fame_pack_path" "MRR")"
cac_line="$(extract_bullet_value "$fame_pack_path" "CAC")"
ltv_cac_line="$(extract_bullet_value "$fame_pack_path" "LTV/CAC")"

if [[ "$momentum_score" == "n/a" ]]; then momentum_score="n/a (tier unknown)"; fi
if [[ "$scoreboard_state" == "n/a" ]]; then scoreboard_state="n/a"; fi
if [[ "$focus_line" == "n/a" ]]; then focus_line="Tighten one KPI bottleneck and publish proof weekly."; fi
if [[ "$mrr_line" == "n/a" ]]; then mrr_line="n/a"; fi
if [[ "$cac_line" == "n/a" ]]; then cac_line="n/a"; fi
if [[ "$ltv_cac_line" == "n/a" ]]; then ltv_cac_line="n/a"; fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Press Kit - ${week_label}

Generated: ${generated_on}
Product: ${product_name}
Source fame pack: ${source_heading}

## Narrative Snapshot

- Momentum signal: ${momentum_score}
- Scoreboard state: ${scoreboard_state}
- Current focus: ${focus_line}
- Metric proof points: MRR (${mrr_line}), CAC (${cac_line}), LTV/CAC (${ltv_cac_line})

## Headline Angles

1. "${product_name} posts measurable weekly momentum without bloating the stack."
2. "Founder execution loop: one KPI scoreboard, one fame pack, one focused experiment."
3. "Local-first product, public proof cadence: weekly metrics to distribution playbook."

## Press Release Lead

${product_name} released a founder execution workflow that turns weekly KPI movement into publish-ready market narratives. The new process starts from weekly review and scoreboard inputs, then produces a founder fame pack and press kit that teams can ship across channels in the same week.

Current momentum: ${momentum_score}. Current operating focus: ${focus_line}

## Podcast Pitch

Subject: Founder operator story: from KPI drift to weekly fame loop

Body:
I run ${product_name} and built a weekly execution loop that converts KPI deltas into ship-ready narratives and distribution plans.
The current signal is ${momentum_score}, with a clear focus on ${focus_line}.
If useful for your audience, I can break down the exact operating cadence and mistakes we fixed.

## Newsletter Pitch

Working title: "How we turned weekly KPI reviews into a compounding distribution engine"

- Hook: Most founder updates are vague; ours are scoreboard-backed and execution-tied.
- Core claim: one weekly pipeline now outputs review, delta, scoreboard, update post, fame pack, and press kit.
- Evidence: ${mrr_line}; ${cac_line}; ${ltv_cac_line}
- Takeaway: one bottleneck metric, one weekly narrative, one distribution sprint.

## DM Outreach Snippets

### Primary (${primary_channel})

Quick founder update from ${product_name}: we are running a weekly KPI-to-distribution loop with momentum at ${momentum_score}. Current focus: ${focus_line}. ${cta_text}

### Backup (${backup_channel})

I share one founder execution snapshot each week with real KPI movement and the exact experiment focus. This week: ${momentum_score}, focus on ${focus_line}. ${cta_text}

## Interview Talking Points

1. Why weekly scoreboard discipline beats ad-hoc launch posting.
2. How to frame CAC and LTV/CAC movement without vanity metrics.
3. How to keep momentum narrative tied to one concrete experiment.
4. Why distribution sequencing matters as much as product progress.
5. How small teams can run this cadence without adding headcount.

## 48-Hour Media Sprint

1. Publish one headline angle + metric proof point.
2. Send podcast + newsletter pitch with the same signal framing.
3. Run creator/community DMs using channel-specific snippets.
4. Collect objections and update next-week FAQ block.
5. Convert highest-signal response into one docs or product update.
EOF

echo "Wrote founder press kit: $output_path"
