#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly viral experiment board from growth review signals.

Usage:
  zsh scripts/generate_viral_experiment_board.sh [options]

Options:
  --week <YYYY-Www>                        Sprint week label (default: current ISO week)
  --metric-focus <text>                    Metric focus line (default: Win Card copies and reply quality)
  --strongest-metric-label <text>          Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>          Strongest metric value (default: n/a)
  --win-card-delta <value>                 WoW delta for Win Card copies
  --installs-delta <value>                 WoW delta for inbound installs/trials
  --outreach-reply-rate <value>            Current creator outreach reply rate
  --outreach-reply-rate-delta <value>      WoW delta for outreach reply rate (pp)
  --outreach-collab-rate <value>           Current creator collaboration rate
  --outreach-collab-rate-delta <value>     WoW delta for collaboration rate (pp)
  --creator-signal-enrichment-score <value> Current creator enrichment score
  --creator-signal-enrichment-score-delta <value> WoW delta for creator enrichment score (pp)
  --guesting-signal-enrichment-score <value> Current founder guesting enrichment score
  --guesting-signal-enrichment-score-delta <value> WoW delta for guesting enrichment score (pp)
  --distribution-completion-score <value>  Distribution completion score
  --distribution-completion-score-delta <value> WoW delta for distribution completion score (pp)
  --channel-roi-preferred-channel <primary|backup|balanced> Preferred routing lead
  --channel-mix-recommendation <text>      Channel mix recommendation line
  --out <path>                             Output markdown path (required)
  -h, --help                               Show this help

Example:
  zsh scripts/generate_viral_experiment_board.sh \
    --week "$(date +%Y-W%V)" \
    --metric-focus "Win Card copies and installs" \
    --strongest-metric-label "Win Card copies" \
    --strongest-metric-value "42" \
    --out .build/growth/$(date +%Y-W%V)-viral-experiment-board.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
win_card_delta="n/a"
installs_delta="n/a"
outreach_reply_rate="n/a"
outreach_reply_rate_delta="n/a"
outreach_collab_rate="n/a"
outreach_collab_rate_delta="n/a"
creator_signal_enrichment_score="n/a"
creator_signal_enrichment_score_delta="n/a"
guesting_signal_enrichment_score="n/a"
guesting_signal_enrichment_score_delta="n/a"
distribution_completion_score="n/a"
distribution_completion_score_delta="n/a"
channel_roi_preferred_channel="balanced"
channel_mix_recommendation="Keep channel mix balanced until distribution execution score is logged."
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
    --win-card-delta)
      win_card_delta="${2:-}"
      shift 2
      ;;
    --installs-delta)
      installs_delta="${2:-}"
      shift 2
      ;;
    --outreach-reply-rate)
      outreach_reply_rate="${2:-}"
      shift 2
      ;;
    --outreach-reply-rate-delta)
      outreach_reply_rate_delta="${2:-}"
      shift 2
      ;;
    --outreach-collab-rate)
      outreach_collab_rate="${2:-}"
      shift 2
      ;;
    --outreach-collab-rate-delta)
      outreach_collab_rate_delta="${2:-}"
      shift 2
      ;;
    --creator-signal-enrichment-score)
      creator_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --creator-signal-enrichment-score-delta)
      creator_signal_enrichment_score_delta="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score)
      guesting_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score-delta)
      guesting_signal_enrichment_score_delta="${2:-}"
      shift 2
      ;;
    --distribution-completion-score)
      distribution_completion_score="${2:-}"
      shift 2
      ;;
    --distribution-completion-score-delta)
      distribution_completion_score_delta="${2:-}"
      shift 2
      ;;
    --channel-roi-preferred-channel)
      channel_roi_preferred_channel="${2:-}"
      shift 2
      ;;
    --channel-mix-recommendation)
      channel_mix_recommendation="${2:-}"
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

normalize_channel_preference() {
  local raw_value="$1"
  local lowered="${raw_value:l}"
  if [[ "$lowered" == "primary" || "$lowered" == *"lead with primary"* || "$lowered" == *"primary channel"* ]]; then
    echo "primary"
    return
  fi
  if [[ "$lowered" == "backup" || "$lowered" == *"lead with backup"* || "$lowered" == *"backup channel"* ]]; then
    echo "backup"
    return
  fi
  echo "balanced"
}

is_ge() {
  local left="$1"
  local right="$2"
  awk -v left="$left" -v right="$right" 'BEGIN { if ((left + 0) >= (right + 0)) print "1"; else print "0" }'
}

abs_number() {
  local value="$1"
  awk -v value="$value" 'BEGIN { if (value + 0 < 0) printf "%.4f", -(value + 0); else printf "%.4f", value + 0 }'
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

format_number() {
  local raw_value="$1"
  awk -v raw_value="$raw_value" 'BEGIN {
    value = raw_value + 0
    if (value == int(value)) {
      printf "%d", int(value)
    } else {
      printf "%.1f", value
    }
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

format_percent_or_na() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  echo "$(format_number "$parsed")%"
}

format_pp_delta_or_na() {
  local raw_value="$1"
  local parsed
  parsed="$(extract_number "$raw_value")"
  if [[ -z "$parsed" ]]; then
    echo "n/a"
    return
  fi
  echo "$(format_signed_number "$parsed")pp"
}

channel_preference="$(normalize_channel_preference "$channel_roi_preferred_channel")"

win_card_delta_number="$(extract_number "$win_card_delta")"
installs_delta_number="$(extract_number "$installs_delta")"
reply_rate_delta_number="$(extract_number "$outreach_reply_rate_delta")"
collab_rate_delta_number="$(extract_number "$outreach_collab_rate_delta")"
creator_signal_score_number="$(extract_number "$creator_signal_enrichment_score")"
creator_signal_score_delta_number="$(extract_number "$creator_signal_enrichment_score_delta")"
guesting_signal_score_number="$(extract_number "$guesting_signal_enrichment_score")"
guesting_signal_score_delta_number="$(extract_number "$guesting_signal_enrichment_score_delta")"
distribution_score_number="$(extract_number "$distribution_completion_score")"
distribution_score_delta_number="$(extract_number "$distribution_completion_score_delta")"

if [[ -z "$creator_signal_score_number" ]]; then
  creator_signal_score_number=55
fi
if [[ -z "$guesting_signal_score_number" ]]; then
  guesting_signal_score_number=50
fi
if [[ -z "$distribution_score_number" ]]; then
  distribution_score_number=60
fi
if [[ -z "$reply_rate_delta_number" ]]; then
  reply_rate_delta_number=0
fi
if [[ -z "$collab_rate_delta_number" ]]; then
  collab_rate_delta_number=0
fi
if [[ -z "$win_card_delta_number" ]]; then
  win_card_delta_number=0
fi
if [[ -z "$installs_delta_number" ]]; then
  installs_delta_number=0
fi
if [[ -z "$creator_signal_score_delta_number" ]]; then
  creator_signal_score_delta_number=0
fi
if [[ -z "$guesting_signal_score_delta_number" ]]; then
  guesting_signal_score_delta_number=0
fi
if [[ -z "$distribution_score_delta_number" ]]; then
  distribution_score_delta_number=0
fi

if [[ -z "$channel_mix_recommendation" ]]; then
  case "$channel_preference" in
    primary)
      channel_mix_recommendation="Maintain a primary-led 60/40 mix until Monday reply quality stabilizes."
      ;;
    backup)
      channel_mix_recommendation="Maintain a backup-led 60/40 mix until Monday reply quality stabilizes."
      ;;
    *)
      channel_mix_recommendation="Maintain a balanced 50/50 mix until one channel clearly outperforms."
      ;;
  esac
fi

hook_urgency="$(awk -v win_delta="$win_card_delta_number" -v installs_delta="$installs_delta_number" 'BEGIN {
  urgency = 0
  if (win_delta < 0) urgency += (-win_delta) * 5
  if (installs_delta < 0) urgency += (-installs_delta) * 4
  if (win_delta > 0) urgency += 4
  if (installs_delta > 0) urgency += 3
  printf "%.4f", urgency
}')"
creator_urgency="$(awk -v collab_delta="$collab_rate_delta_number" -v creator_score="$creator_signal_score_number" -v creator_delta="$creator_signal_score_delta_number" 'BEGIN {
  urgency = (100 - creator_score) * 0.22
  if (collab_delta < 0) urgency += (-collab_delta) * 3.5
  if (creator_delta > 0) urgency += creator_delta * 0.4
  printf "%.4f", urgency
}')"
guesting_urgency="$(awk -v guesting_score="$guesting_signal_score_number" -v guesting_delta="$guesting_signal_score_delta_number" 'BEGIN {
  urgency = (100 - guesting_score) * 0.25
  if (guesting_delta < 0) urgency += (-guesting_delta) * 2.0
  if (guesting_delta > 0) urgency += guesting_delta * 0.35
  printf "%.4f", urgency
}')"
distribution_urgency="$(awk -v distribution_score="$distribution_score_number" -v distribution_delta="$distribution_score_delta_number" 'BEGIN {
  urgency = 0
  if (distribution_score < 75) urgency += (75 - distribution_score) * 0.65
  if (distribution_delta < 0) urgency += (-distribution_delta) * 2.2
  printf "%.4f", urgency
}')"
channel_urgency="$(awk -v reply_delta="$reply_rate_delta_number" -v win_delta="$win_card_delta_number" -v collab_delta="$collab_rate_delta_number" 'BEGIN {
  urgency = (reply_delta < 0 ? -reply_delta : reply_delta) * 1.1
  urgency += (win_delta < 0 ? -win_delta : win_delta) * 1.0
  urgency += (collab_delta < 0 ? -collab_delta : collab_delta) * 0.8
  printf "%.4f", urgency
}')"

score_hook="$(clamp_score "$(awk -v base="56" -v urgency="$hook_urgency" 'BEGIN { printf "%.4f", base + urgency }')")"
score_creator="$(clamp_score "$(awk -v base="54" -v urgency="$creator_urgency" 'BEGIN { printf "%.4f", base + urgency }')")"
score_guesting="$(clamp_score "$(awk -v base="52" -v urgency="$guesting_urgency" 'BEGIN { printf "%.4f", base + urgency }')")"
score_distribution="$(clamp_score "$(awk -v base="55" -v urgency="$distribution_urgency" 'BEGIN { printf "%.4f", base + urgency }')")"
score_channel="$(clamp_score "$(awk -v base="50" -v urgency="$channel_urgency" -v preference="$channel_preference" 'BEGIN {
  bonus = 0
  if (preference == "balanced") bonus = 6
  if (preference == "primary" || preference == "backup") bonus = 3
  printf "%.4f", base + urgency + bonus
}')")"

if [[ "$channel_preference" == "primary" ]]; then
  channel_route_label="primary-led"
elif [[ "$channel_preference" == "backup" ]]; then
  channel_route_label="backup-led"
else
  channel_route_label="balanced"
fi

declare -a experiments
experiments=(
  "${score_hook}|Hook Angle Escalation|Refreshing opening hook + CTA around ${strongest_metric_label} will improve share and install velocity.|Growth lead|Win Card delta and install delta turn positive|${channel_route_label} support|${score_hook}"
  "${score_creator}|Creator Collab Loop|Doubling high-intent creator follow-ups will raise collaboration conversion this week.|Creator partnerships owner|Collaboration rate delta and creator score trend up|creator loop|${score_creator}"
  "${score_guesting}|Founder Guesting Flywheel|Turning best guesting format into repeat pitch scripts will increase external discovery.|Founder comms owner|Guesting enrichment score and booked/published count rise|guesting flywheel|${score_guesting}"
  "${score_distribution}|Distribution Cadence Compression|Compressing Day 0-Day 4 follow-ups into tighter windows will recover completion score.|Distribution owner|Distribution completion score rises above 75%|distribution cadence|${score_distribution}"
  "${score_channel}|Channel Route Challenge|Running a lead/support route challenge will clarify next default channel mix.|Channel ops owner|Reply-rate delta and CTR proxy improve on one route|route challenge|${score_channel}"
)

ranked_lines="$(printf '%s\n' "${experiments[@]}" | sort -t'|' -k1,1nr -k2,2)"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

{
  echo "<!-- weekly-growth-viral-experiment-board -->"
  echo
  echo "# Viral Experiment Board: $week"
  echo
  echo "Generated: $generated_on"
  echo "Metric focus: $metric_focus"
  echo
  echo "## Signal Snapshot"
  echo
  echo "- Strongest metric: $strongest_metric_label ($strongest_metric_value)"
  echo "- Win Card delta: $(format_signed_number "$win_card_delta_number")"
  echo "- Installs delta: $(format_signed_number "$installs_delta_number")"
  echo "- Creator reply rate: $(format_percent_or_na "$outreach_reply_rate") (Δ $(format_pp_delta_or_na "$outreach_reply_rate_delta"))"
  echo "- Creator collaboration rate: $(format_percent_or_na "$outreach_collab_rate") (Δ $(format_pp_delta_or_na "$outreach_collab_rate_delta"))"
  echo "- Creator enrichment score: $(format_percent_or_na "$creator_signal_enrichment_score") (Δ $(format_pp_delta_or_na "$creator_signal_enrichment_score_delta"))"
  echo "- Founder guesting enrichment score: $(format_percent_or_na "$guesting_signal_enrichment_score") (Δ $(format_pp_delta_or_na "$guesting_signal_enrichment_score_delta"))"
  echo "- Distribution completion score: $(format_percent_or_na "$distribution_completion_score") (Δ $(format_pp_delta_or_na "$distribution_completion_score_delta"))"
  echo "- Preferred channel route: $channel_preference"
  echo "- Channel mix recommendation: $channel_mix_recommendation"
  echo
  echo "## Ranked Experiments"
  echo
  echo "| Rank | Experiment | Hypothesis | Owner | Leading indicator | Priority score |"
  echo "| --- | --- | --- | --- | --- | --- |"
  rank=1
  while IFS='|' read -r _ experiment_name hypothesis owner leading_indicator _ priority_score; do
    [[ -z "$experiment_name" ]] && continue
    echo "| $rank | $experiment_name | $hypothesis | $owner | $leading_indicator | $priority_score |"
    rank=$(( rank + 1 ))
  done <<< "$ranked_lines"
  echo
  echo "## Execution Cadence"
  echo
  echo "1. Monday: ship top 2 experiments with explicit owners + deadlines."
  echo "2. Tuesday/Wednesday: checkpoint leading indicators and keep one control variable fixed."
  echo "3. Thursday: prune one underperforming branch and double down on the best performer."
  echo "4. Friday: record winner/loser notes in weekly review and promote winner into Monday defaults."
  echo
  echo "## Tracking Checklist"
  echo
  echo "- [ ] Assigned owner + due date for each top-3 experiment"
  echo "- [ ] Logged first signal check within 48 hours"
  echo "- [ ] Declared one winning experiment by Friday review"
  echo "- [ ] Promoted winner into next Monday publish defaults"
} > "$output_path"

echo "Wrote viral experiment board: $output_path"
