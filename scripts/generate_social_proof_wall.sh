#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly social proof wall from growth review signals.

Usage:
  zsh scripts/generate_social_proof_wall.sh [options]

Options:
  --week <YYYY-Www>                       Sprint week label (default: current ISO week)
  --metric-focus <text>                   Metric focus line (default: Win Card copies and reply quality)
  --strongest-metric-label <text>         Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>         Strongest metric value (default: n/a)
  --primary-channel <text>                Primary channel label (default: X / Threads)
  --backup-channel <text>                 Backup channel label (default: LinkedIn)
  --win-card <value>                      Win Card copies value
  --win-card-delta <value>                WoW delta for Win Card copies
  --replies-sent <value>                  First 24-hour replies sent value
  --replies-sent-delta <value>            WoW delta for replies sent
  --outreach-replies <value>              Creator outreach replies value
  --outreach-collabs <value>              Creator collaborations value
  --outreach-cross-posts <value>          Creator/community cross-post value
  --primary-top-variant <A/B/C>           Top variant on primary channel
  --backup-top-variant <A/B/C>            Top variant on backup channel
  --creator-signal-top-handle <text>      Top creator handle from signal scoring
  --creator-signal-top-segment <text>     Top creator segment from signal scoring
  --guesting-signal-top-target <text>     Top founder guesting target from signal scoring
  --channel-mix-recommendation <text>     Channel mix recommendation line
  --variant-recommendation <text>         Variant recommendation line
  --outreach-recommendation <text>        Outreach recommendation line
  --out <path>                            Output markdown path (required)
  -h, --help                              Show this help

Example:
  zsh scripts/generate_social_proof_wall.sh \
    --week "$(date +%Y-W%V)" \
    --strongest-metric-label "Win Card copies" \
    --strongest-metric-value "42" \
    --creator-signal-top-handle "@buildwithamy" \
    --out .build/growth/$(date +%Y-W%V)-social-proof-wall.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
primary_channel="X / Threads"
backup_channel="LinkedIn"
win_card_value="n/a"
win_card_delta="n/a"
replies_sent="n/a"
replies_sent_delta="n/a"
outreach_replies="n/a"
outreach_collabs="n/a"
outreach_cross_posts="n/a"
primary_top_variant="n/a"
backup_top_variant="n/a"
creator_signal_top_handle="n/a"
creator_signal_top_segment="n/a"
guesting_signal_top_target="n/a"
channel_mix_recommendation="Keep channel mix balanced until distribution execution score is logged."
variant_recommendation="Keep current top-performing variant as default and iterate one challenger."
outreach_recommendation="Focus outreach on warm creator conversations and one follow-up pass."
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week="${2:-}"
      shift 2
      ;;
    --metric-focus)
      metric_focus="${2:-}"
      shift 2
      ;;
    --strongest-metric-label)
      strongest_metric_label="${2:-}"
      shift 2
      ;;
    --strongest-metric-value)
      strongest_metric_value="${2:-}"
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
    --win-card)
      win_card_value="${2:-}"
      shift 2
      ;;
    --win-card-delta)
      win_card_delta="${2:-}"
      shift 2
      ;;
    --replies-sent)
      replies_sent="${2:-}"
      shift 2
      ;;
    --replies-sent-delta)
      replies_sent_delta="${2:-}"
      shift 2
      ;;
    --outreach-replies)
      outreach_replies="${2:-}"
      shift 2
      ;;
    --outreach-collabs)
      outreach_collabs="${2:-}"
      shift 2
      ;;
    --outreach-cross-posts)
      outreach_cross_posts="${2:-}"
      shift 2
      ;;
    --primary-top-variant)
      primary_top_variant="${2:-}"
      shift 2
      ;;
    --backup-top-variant)
      backup_top_variant="${2:-}"
      shift 2
      ;;
    --creator-signal-top-handle)
      creator_signal_top_handle="${2:-}"
      shift 2
      ;;
    --creator-signal-top-segment)
      creator_signal_top_segment="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-target)
      guesting_signal_top_target="${2:-}"
      shift 2
      ;;
    --channel-mix-recommendation)
      channel_mix_recommendation="${2:-}"
      shift 2
      ;;
    --variant-recommendation)
      variant_recommendation="${2:-}"
      shift 2
      ;;
    --outreach-recommendation)
      outreach_recommendation="${2:-}"
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
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$output_path" ]]; then
  echo "--out is required" >&2
  usage
  exit 1
fi

extract_number() {
  local raw_value="$1"
  print -r -- "$raw_value" | rg -o --pcre2 '[+-]?\d+(?:\.\d+)?' | head -n1 || true
}

format_number() {
  local raw_value="$1"
  awk -v raw_value="$raw_value" 'BEGIN {
    value = raw_value + 0
    if (value == int(value)) printf "%d", int(value); else printf "%.1f", value
  }'
}

format_signed_number() {
  local raw_value="$1"
  awk -v raw_value="$raw_value" 'BEGIN {
    value = raw_value + 0
    if (value > 0) {
      if (value == int(value)) printf "+%d", int(value); else printf "+%.1f", value
    } else {
      if (value == int(value)) printf "%d", int(value); else printf "%.1f", value
    }
  }'
}

format_or_na() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  echo "$(format_number "$parsed")"
}

format_delta_or_na() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  echo "$(format_signed_number "$parsed")"
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

win_card_number="$(extract_number "$win_card_value")"
win_card_delta_number="$(extract_number "$win_card_delta")"
replies_sent_number="$(extract_number "$replies_sent")"
replies_sent_delta_number="$(extract_number "$replies_sent_delta")"
outreach_replies_number="$(extract_number "$outreach_replies")"
outreach_collabs_number="$(extract_number "$outreach_collabs")"
outreach_cross_posts_number="$(extract_number "$outreach_cross_posts")"

if [[ -z "$win_card_number" ]]; then win_card_number=0; fi
if [[ -z "$win_card_delta_number" ]]; then win_card_delta_number=0; fi
if [[ -z "$replies_sent_number" ]]; then replies_sent_number=0; fi
if [[ -z "$replies_sent_delta_number" ]]; then replies_sent_delta_number=0; fi
if [[ -z "$outreach_replies_number" ]]; then outreach_replies_number=0; fi
if [[ -z "$outreach_collabs_number" ]]; then outreach_collabs_number=0; fi
if [[ -z "$outreach_cross_posts_number" ]]; then outreach_cross_posts_number=0; fi

score_outcome="$(clamp_score "$(awk -v base="58" -v win_card="$win_card_number" -v delta="$win_card_delta_number" 'BEGIN {
  score = base + (win_card * 0.2) + (delta * 3.2)
  printf "%.4f", score
}')")"

score_reply="$(clamp_score "$(awk -v base="55" -v replies="$replies_sent_number" -v delta="$replies_sent_delta_number" 'BEGIN {
  score = base + (replies * 0.35) + (delta * 2.4)
  printf "%.4f", score
}')")"

score_creator="$(clamp_score "$(awk -v base="54" -v replies="$outreach_replies_number" -v collabs="$outreach_collabs_number" -v cross_posts="$outreach_cross_posts_number" 'BEGIN {
  score = base + (replies * 1.6) + (collabs * 3.2) + (cross_posts * 2.0)
  printf "%.4f", score
}')")"

score_founder="$(clamp_score "$(awk -v base="52" -v target="$guesting_signal_top_target" 'BEGIN {
  score = base
  if (target != "n/a" && target != "") score += 12
  printf "%.4f", score
}')")"

score_variant="$(clamp_score "$(awk -v base="53" -v primary_variant="$primary_top_variant" -v backup_variant="$backup_top_variant" 'BEGIN {
  score = base
  if (primary_variant != "n/a" && primary_variant != "") score += 8
  if (backup_variant != "n/a" && backup_variant != "") score += 6
  printf "%.4f", score
}')")"

declare -a proof_cards
proof_cards=(
  "${score_outcome}|Outcome Snapshot|${primary_channel}|${strongest_metric_label} reached ${strongest_metric_value}.|Use as opening proof in weekly highlight post.|${score_outcome}"
  "${score_reply}|Reply Momentum|${primary_channel}|${replies_sent} replies in first 24h (Δ ${replies_sent_delta}).|Use as engagement credibility in thread follow-ups.|${score_reply}"
  "${score_creator}|Creator Echo|${backup_channel}|${outreach_replies} creator replies, ${outreach_collabs} collabs, ${outreach_cross_posts} cross-posts.|Use to pitch social proof loops to new creators.|${score_creator}"
  "${score_founder}|Founder Discovery|${backup_channel}|Top guesting target this week: ${guesting_signal_top_target}.|Use in founder build-log and guesting outreach.|${score_founder}"
  "${score_variant}|Variant Reliability|${primary_channel}|Primary ${primary_top_variant}, backup ${backup_top_variant}.|Use as why-this-copy in routing decisions.|${score_variant}"
)

ranked_cards="$(printf '%s\n' "${proof_cards[@]}" | sort -t'|' -k1,1nr -k2,2)"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

{
  echo "<!-- weekly-growth-social-proof-wall -->"
  echo
  echo "# Weekly Social Proof Wall: $week"
  echo
  echo "Generated: $generated_on"
  echo "Metric focus: $metric_focus"
  echo
  echo "## Signal Snapshot"
  echo
  echo "- Strongest metric: $strongest_metric_label ($strongest_metric_value)"
  echo "- Win Card copies: $(format_or_na "$win_card_value") (Δ $(format_delta_or_na "$win_card_delta"))"
  echo "- Replies sent (24h): $(format_or_na "$replies_sent") (Δ $(format_delta_or_na "$replies_sent_delta"))"
  echo "- Creator replies/collabs/cross-posts: $(format_or_na "$outreach_replies") / $(format_or_na "$outreach_collabs") / $(format_or_na "$outreach_cross_posts")"
  echo "- Top creator signal: $creator_signal_top_handle ($creator_signal_top_segment)"
  echo "- Top founder guesting target: $guesting_signal_top_target"
  echo "- Primary / backup top variants: $primary_top_variant / $backup_top_variant"
  echo "- Channel mix recommendation: $channel_mix_recommendation"
  echo
  echo "## Ranked Proof Cards"
  echo
  echo "| Rank | Proof card | Best channel | Evidence seed | Usage note | Priority score |"
  echo "| --- | --- | --- | --- | --- | --- |"
  rank=1
  while IFS='|' read -r _ card channel evidence usage priority_score; do
    [[ -z "$card" ]] && continue
    echo "| $rank | $card | $channel | $evidence | $usage | $priority_score |"
    rank=$(( rank + 1 ))
  done <<< "$ranked_cards"
  echo
  echo "## Quote Bank"
  echo
  echo "- \"This week we moved $strongest_metric_label with a measurable signal: $strongest_metric_value.\""
  echo "- \"${primary_channel} and ${backup_channel} both converted because the proof stayed concrete.\""
  echo "- \"Top creator signal this week: ${creator_signal_top_handle} in ${creator_signal_top_segment}.\""
  echo "- \"Founder discovery focus this week: ${guesting_signal_top_target}.\""
  echo "- \"Variant momentum says keep ${primary_top_variant}/${backup_top_variant} in rotation while testing one challenger.\""
  echo
  echo "## Repost Snippets"
  echo
  echo "### Primary Channel Snippet (${primary_channel})"
  echo
  echo "\`\`\`text"
  echo "Proof wall update (${week}):"
  echo "- ${strongest_metric_label}: ${strongest_metric_value}"
  echo "- Replies in first 24h: ${replies_sent} (Δ ${replies_sent_delta})"
  echo "- Creator signal lead: ${creator_signal_top_handle}"
  echo
  echo "${variant_recommendation}"
  echo "\`\`\`"
  echo
  echo "### Backup Channel Snippet (${backup_channel})"
  echo
  echo "\`\`\`text"
  echo "Weekly social proof wall (${week}):"
  echo "- Measured outcome: ${strongest_metric_label} = ${strongest_metric_value}"
  echo "- Creator motion: ${outreach_replies} replies / ${outreach_collabs} collabs / ${outreach_cross_posts} cross-posts"
  echo "- Founder discovery lead: ${guesting_signal_top_target}"
  echo
  echo "${outreach_recommendation}"
  echo "\`\`\`"
  echo
  echo "## Wall Checklist"
  echo
  echo "- [ ] Publish one proof card on ${primary_channel}"
  echo "- [ ] Publish one proof card on ${backup_channel}"
  echo "- [ ] Reuse one quote from the quote bank in a reply thread"
  echo "- [ ] Carry winning evidence into next Monday defaults"
} > "$output_path"

echo "Wrote social proof wall: $output_path"
