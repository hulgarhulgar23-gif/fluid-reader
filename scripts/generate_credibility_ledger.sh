#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly credibility ledger from growth review signals.

Usage:
  zsh scripts/generate_credibility_ledger.sh [options]

Options:
  --week <YYYY-Www>                       Sprint week label (default: current ISO week)
  --metric-focus <text>                   Metric focus line (default: Win Card copies and reply quality)
  --strongest-metric-label <text>         Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>         Strongest metric value (default: n/a)
  --primary-channel <text>                Primary channel label (default: X / Threads)
  --backup-channel <text>                 Backup channel label (default: LinkedIn)
  --win-card <value>                      Win Card copies value
  --win-recap <value>                     Win Recap copies value
  --posts <value>                         Public posts shipped value
  --stories <value>                       User-generated stories value
  --installs <value>                      Inbound installs/trials value
  --replies-sent <value>                  First 24-hour replies sent value
  --objections-captured <value>           Objections captured value
  --docs-updates <value>                  Docs/workflow updates value
  --creator-signal-top-handle <text>      Top creator handle from signal scoring
  --guesting-signal-top-target <text>     Top founder guesting target from signal scoring
  --distribution-completion-score <value> Distribution completion score
  --channel-mix-recommendation <text>     Channel mix recommendation line
  --variant-recommendation <text>         Variant recommendation line
  --outreach-recommendation <text>        Outreach recommendation line
  --out <path>                            Output markdown path (required)
  -h, --help                              Show this help

Example:
  zsh scripts/generate_credibility_ledger.sh \
    --week "$(date +%Y-W%V)" \
    --strongest-metric-label "Win Card copies" \
    --strongest-metric-value "42" \
    --objections-captured "3" \
    --docs-updates "2" \
    --out .build/growth/$(date +%Y-W%V)-credibility-ledger.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
primary_channel="X / Threads"
backup_channel="LinkedIn"
win_card_value="n/a"
win_recap_value="n/a"
posts_value="n/a"
stories_value="n/a"
installs_value="n/a"
replies_sent="n/a"
objections_captured="n/a"
docs_updates="n/a"
creator_signal_top_handle="n/a"
guesting_signal_top_target="n/a"
distribution_completion_score="n/a"
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
    --win-recap)
      win_recap_value="${2:-}"
      shift 2
      ;;
    --posts)
      posts_value="${2:-}"
      shift 2
      ;;
    --stories)
      stories_value="${2:-}"
      shift 2
      ;;
    --installs)
      installs_value="${2:-}"
      shift 2
      ;;
    --replies-sent)
      replies_sent="${2:-}"
      shift 2
      ;;
    --objections-captured)
      objections_captured="${2:-}"
      shift 2
      ;;
    --docs-updates)
      docs_updates="${2:-}"
      shift 2
      ;;
    --creator-signal-top-handle)
      creator_signal_top_handle="${2:-}"
      shift 2
      ;;
    --guesting-signal-top-target)
      guesting_signal_top_target="${2:-}"
      shift 2
      ;;
    --distribution-completion-score)
      distribution_completion_score="${2:-}"
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
win_recap_number="$(extract_number "$win_recap_value")"
posts_number="$(extract_number "$posts_value")"
stories_number="$(extract_number "$stories_value")"
installs_number="$(extract_number "$installs_value")"
replies_number="$(extract_number "$replies_sent")"
objections_number="$(extract_number "$objections_captured")"
docs_updates_number="$(extract_number "$docs_updates")"
distribution_score_number="$(extract_number "$distribution_completion_score")"

if [[ -z "$win_card_number" ]]; then win_card_number=0; fi
if [[ -z "$win_recap_number" ]]; then win_recap_number=0; fi
if [[ -z "$posts_number" ]]; then posts_number=0; fi
if [[ -z "$stories_number" ]]; then stories_number=0; fi
if [[ -z "$installs_number" ]]; then installs_number=0; fi
if [[ -z "$replies_number" ]]; then replies_number=0; fi
if [[ -z "$objections_number" ]]; then objections_number=0; fi
if [[ -z "$docs_updates_number" ]]; then docs_updates_number=0; fi
if [[ -z "$distribution_score_number" ]]; then distribution_score_number=60; fi

reliability_score="$(clamp_score "$(awk -v win_card="$win_card_number" -v win_recap="$win_recap_number" -v posts="$posts_number" -v stories="$stories_number" -v installs="$installs_number" 'BEGIN {
  score = 50 + (win_card * 0.25) + (win_recap * 0.18) + (posts * 1.4) + (stories * 1.8) + (installs * 1.1)
  printf "%.4f", score
}')")"

resolution_score="$(clamp_score "$(awk -v objections="$objections_number" -v docs_updates="$docs_updates_number" -v replies="$replies_number" 'BEGIN {
  score = 48 + (objections * 1.7) + (docs_updates * 5.0) + (replies * 0.9)
  printf "%.4f", score
}')")"

creator_validation_score=52
if [[ "$creator_signal_top_handle" != "n/a" && -n "$creator_signal_top_handle" ]]; then
  creator_validation_score=74
fi

founder_validation_score=50
if [[ "$guesting_signal_top_target" != "n/a" && -n "$guesting_signal_top_target" ]]; then
  founder_validation_score=72
fi

distribution_consistency_score="$(clamp_score "$distribution_score_number")"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

{
  echo "<!-- weekly-growth-credibility-ledger -->"
  echo
  echo "# Credibility Ledger: $week"
  echo
  echo "Generated: $generated_on"
  echo "Metric focus: $metric_focus"
  echo
  echo "## Trust Snapshot"
  echo
  echo "- Strongest metric: $strongest_metric_label ($strongest_metric_value)"
  echo "- Primary / backup channels: $primary_channel / $backup_channel"
  echo "- Outcome metrics (Win Card / Win Recap / installs): $(format_or_na "$win_card_value") / $(format_or_na "$win_recap_value") / $(format_or_na "$installs_value")"
  echo "- Engagement metrics (replies / objections / docs updates): $(format_or_na "$replies_sent") / $(format_or_na "$objections_captured") / $(format_or_na "$docs_updates")"
  echo "- Social proof leads: creator \`$creator_signal_top_handle\`, founder target \`$guesting_signal_top_target\`"
  echo "- Distribution completion score: $(format_percent_or_na "$distribution_completion_score")"
  echo "- Channel mix recommendation: $channel_mix_recommendation"
  echo
  echo "## Verified Signals"
  echo
  echo "| Dimension | Evidence | Confidence score | Next proof step |"
  echo "| --- | --- | --- | --- |"
  echo "| Outcome reliability | Win Card \`$(format_or_na "$win_card_value")\`, Win Recap \`$(format_or_na "$win_recap_value")\`, installs \`$(format_or_na "$installs_value")\` | $reliability_score | Repost one measured before/after with exact workflow steps. |"
  echo "| Objection resolution | Objections \`$(format_or_na "$objections_captured")\`, docs updates \`$(format_or_na "$docs_updates")\`, replies \`$(format_or_na "$replies_sent")\` | $resolution_score | Publish one objection-response thread and link the docs update. |"
  echo "| Creator validation | Top creator signal handle \`$creator_signal_top_handle\` | $creator_validation_score | Convert one creator signal into a quote-backed post. |"
  echo "| Founder external validation | Top guesting target \`$guesting_signal_top_target\` | $founder_validation_score | Ship one founder build-log mention with the guesting target. |"
  echo "| Distribution consistency | Completion score \`$(format_percent_or_na "$distribution_completion_score")\` | $distribution_consistency_score | Close one missing follow-up slot and log final status. |"
  echo
  echo "## Objection Resolution Log"
  echo
  echo "- Captured objections this week: $(format_or_na "$objections_captured")"
  echo "- Docs/workflow updates shipped: $(format_or_na "$docs_updates")"
  echo "- Active reply throughput (24h): $(format_or_na "$replies_sent")"
  echo "- Variant routing note: $variant_recommendation"
  echo "- Outreach routing note: $outreach_recommendation"
  echo
  echo "## Credibility Quotes"
  echo
  echo "- \"Measured outcomes and fast replies make our product claims believable.\""
  echo "- \"We turn objections into docs updates in the same week.\""
  echo "- \"Creator and founder signals now reinforce each other instead of running separately.\""
  echo "- \"Distribution consistency is tracked as rigor, not intuition.\""
  echo
  echo "## Next Proof Actions"
  echo
  echo "- [ ] Publish one metric-backed proof post on $primary_channel"
  echo "- [ ] Publish one credibility follow-up on $backup_channel"
  echo "- [ ] Resolve at least one objection with a linked docs update"
  echo "- [ ] Carry top credibility signal into next Monday defaults"
} > "$output_path"

echo "Wrote credibility ledger: $output_path"
