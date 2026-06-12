#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame operations brief from growth + founder artifacts.

Usage:
  zsh scripts/generate_founder_fame_ops_brief.sh [options]

Required:
  --distribution-plan <path>   7-day distribution plan markdown
  --social-proof-wall <path>   Weekly social proof wall markdown

Optional:
  --week <label>               Week label (default: current ISO week)
  --fame-pack <path>           Founder fame pack markdown
  --media-blast <path>         Founder media blast markdown
  --guesting-brief <path>      Founder guesting sprint brief markdown
  --out <path>                 Output path (default: docs/campaigns/<week>-founder-fame-ops-brief.md)
  -h, --help                   Show help

Example:
  zsh scripts/generate_founder_fame_ops_brief.sh \
    --week "2026-W23" \
    --distribution-plan docs/campaigns/2026-W23-distribution-plan.md \
    --social-proof-wall docs/campaigns/2026-W23-social-proof-wall.md \
    --fame-pack docs/campaigns/2026-W23-founder-fame-pack.md \
    --media-blast docs/campaigns/2026-W23-founder-media-blast.md \
    --guesting-brief docs/campaigns/2026-W23-founder-guesting-brief.md
EOF
}

week="$(date '+%Y-W%V')"
distribution_plan_path=""
social_proof_wall_path=""
fame_pack_path=""
media_blast_path=""
guesting_brief_path=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week="${2:-}"
      shift 2
      ;;
    --distribution-plan)
      distribution_plan_path="${2:-}"
      shift 2
      ;;
    --social-proof-wall)
      social_proof_wall_path="${2:-}"
      shift 2
      ;;
    --fame-pack)
      fame_pack_path="${2:-}"
      shift 2
      ;;
    --media-blast)
      media_blast_path="${2:-}"
      shift 2
      ;;
    --guesting-brief)
      guesting_brief_path="${2:-}"
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
  "distribution_plan_path:$distribution_plan_path" \
  "social_proof_wall_path:$social_proof_wall_path"; do
  key="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "Missing required option: $key" >&2
    usage >&2
    exit 1
  fi
done

for required_path in "$distribution_plan_path" "$social_proof_wall_path"; do
  if [[ ! -f "$required_path" ]]; then
    echo "Required source file not found: $required_path" >&2
    exit 1
  fi
done

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week}-founder-fame-ops-brief.md"
fi

normalize_source_label() {
  local candidate="$1"
  if [[ -z "$candidate" || ! -f "$candidate" ]]; then
    echo "n/a"
  else
    echo "$candidate"
  fi
}

extract_heading() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi

  local heading_line
  heading_line="$(rg -m1 '^# ' "$source_path" || true)"
  if [[ -z "$heading_line" ]]; then
    echo "n/a"
  else
    echo "${heading_line#\# }"
  fi
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

  line="${line#"$prefix"}"
  line="${line#"${line%%[![:space:]]*}"}"
  echo "$line"
}

distribution_heading="$(extract_heading "$distribution_plan_path")"
proof_wall_heading="$(extract_heading "$social_proof_wall_path")"
fame_pack_heading="$(extract_heading "$fame_pack_path")"
media_blast_heading="$(extract_heading "$media_blast_path")"
guesting_heading="$(extract_heading "$guesting_brief_path")"

metric_focus="$(extract_prefixed_value "$social_proof_wall_path" "Metric focus: ")"
strongest_metric="$(extract_prefixed_value "$social_proof_wall_path" "- Strongest metric: ")"
top_creator_signal="$(extract_prefixed_value "$social_proof_wall_path" "- Top creator signal: ")"
top_guesting_target="$(extract_prefixed_value "$social_proof_wall_path" "- Top founder guesting target: ")"
proof_mix_recommendation="$(extract_prefixed_value "$social_proof_wall_path" "- Channel mix recommendation: ")"

lead_channel="$(extract_prefixed_value "$distribution_plan_path" "- Lead channel this week: ")"
support_channel="$(extract_prefixed_value "$distribution_plan_path" "- Support channel this week: ")"
primary_roi="$(extract_prefixed_value "$distribution_plan_path" "- Primary channel ROI score: ")"
backup_roi="$(extract_prefixed_value "$distribution_plan_path" "- Backup channel ROI score: ")"
routing_note="$(extract_prefixed_value "$distribution_plan_path" "- ROI routing note: ")"
distribution_mix_recommendation="$(extract_prefixed_value "$distribution_plan_path" "- Channel mix recommendation: ")"
reply_goal="$(extract_prefixed_value "$distribution_plan_path" "- First-24-hour practical reply goal: ")"
outreach_goal="$(extract_prefixed_value "$distribution_plan_path" "- Seven-day outreach follow-up goal: ")"

scoreboard_state="$(extract_prefixed_value "$fame_pack_path" "- Scoreboard state: ")"
weekly_summary="$(extract_prefixed_value "$fame_pack_path" "- Weekly summary: ")"
weekly_narrative="$(extract_prefixed_value "$media_blast_path" "- Weekly narrative: ")"
guesting_readiness="$(extract_prefixed_value "$guesting_brief_path" "- Guesting readiness score: ")"
guesting_touch_goal="$(extract_prefixed_value "$guesting_brief_path" "- Weekly touch goal: ")"
guesting_priority_target="$(extract_prefixed_value "$guesting_brief_path" "- Priority target: ")"

mix_recommendation="$distribution_mix_recommendation"
if [[ "$proof_mix_recommendation" != "n/a" ]]; then
  mix_recommendation="$proof_mix_recommendation"
fi

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
# Founder Fame Ops Brief: $week

Generated: $generated_on
Source distribution plan: $(normalize_source_label "$distribution_plan_path")
Source social proof wall: $(normalize_source_label "$social_proof_wall_path")
Source founder fame pack: $(normalize_source_label "$fame_pack_path")
Source founder media blast: $(normalize_source_label "$media_blast_path")
Source founder guesting brief: $(normalize_source_label "$guesting_brief_path")

## Routing and Proof Snapshot

- Distribution plan: $distribution_heading
- Social proof wall: $proof_wall_heading
- Metric focus: $metric_focus
- Strongest metric: $strongest_metric
- Lead channel: $lead_channel
- Support channel: $support_channel
- Primary ROI score: $primary_roi
- Backup ROI score: $backup_roi
- Top creator signal: $top_creator_signal
- Top guesting target: $top_guesting_target
- Reply goal (24h): $reply_goal
- Outreach goal (7d): $outreach_goal

## Founder Overlay

- Founder fame pack: $fame_pack_heading
- Founder media blast: $media_blast_heading
- Founder guesting brief: $guesting_heading
- Scoreboard state: $scoreboard_state
- Weekly summary: $weekly_summary
- Weekly narrative: $weekly_narrative
- Guesting readiness: $guesting_readiness
- Weekly touch goal: $guesting_touch_goal
- Priority guesting target: $guesting_priority_target

## Next 24 Hours

1. Publish proof-first message in lead channel with strongest metric.
2. Ship support-channel follow-up using weekly narrative and one concrete CTA.
3. Reply to practical questions until reply goal is met.
4. Log top objections and convert one into docs/workflow clarity.

## 7-Day Fame Sprint

- Day 0-1: lock proof narrative and practical reply quality.
- Day 2-3: run creator/community follow-ups and objection-handling repost.
- Day 4-5: push second outreach wave and docs conversion update.
- Day 6-7: publish recap, collaboration ask, and route learnings to next cycle.
- Routing note: $routing_note
- Mix recommendation: $mix_recommendation

## Copy Block

\`\`\`text
Founder fame ops update ($week):
- Focus: $metric_focus
- Proof: $strongest_metric
- Lead/support channels: $lead_channel / $support_channel
- Scoreboard state: $scoreboard_state
- This week mix call: $mix_recommendation
\`\`\`
EOF

echo "Wrote founder fame ops brief: $output_path"
