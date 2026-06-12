#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly winning hook library from growth review signals.

Usage:
  zsh scripts/generate_winning_hook_library.sh [options]

Options:
  --week <YYYY-Www>                       Sprint week label (default: current ISO week)
  --metric-focus <text>                   Metric focus line (default: Win Card copies and reply quality)
  --strongest-metric-label <text>         Strongest metric label (default: Win Card copies)
  --strongest-metric-value <text>         Strongest metric value (default: n/a)
  --primary-channel <text>                Primary channel label (default: X / Threads)
  --backup-channel <text>                 Backup channel label (default: LinkedIn)
  --primary-top-variant <A/B/C>           Current top variant on primary channel
  --backup-top-variant <A/B/C>            Current top variant on backup channel
  --primary-variant-win-trend <text>      Current win trend on primary channel
  --backup-variant-win-trend <text>       Current win trend on backup channel
  --primary-channel-roi-score <value>     Primary channel ROI score
  --backup-channel-roi-score <value>      Backup channel ROI score
  --channel-roi-preferred-channel <text>  Preferred lead route (primary/backup/balanced)
  --channel-roi-recommendation <text>     ROI routing recommendation line
  --channel-mix-recommendation <text>     Channel mix recommendation line
  --variant-recommendation <text>         Variant recommendation line
  --outreach-recommendation <text>        Outreach recommendation line
  --creator-signal-enrichment-score <value> Creator enrichment score
  --guesting-signal-enrichment-score <value> Founder guesting enrichment score
  --win-card-delta <value>                WoW delta for Win Card copies
  --installs-delta <value>                WoW delta for installs/trials
  --out <path>                            Output markdown path (required)
  -h, --help                              Show this help

Example:
  zsh scripts/generate_winning_hook_library.sh \
    --week "$(date +%Y-W%V)" \
    --strongest-metric-label "Win Card copies" \
    --strongest-metric-value "42" \
    --primary-top-variant "A" \
    --backup-top-variant "B" \
    --out .build/growth/$(date +%Y-W%V)-winning-hook-library.md
EOF
}

week="$(date '+%Y-W%V')"
metric_focus="Win Card copies and reply quality"
strongest_metric_label="Win Card copies"
strongest_metric_value="n/a"
primary_channel="X / Threads"
backup_channel="LinkedIn"
primary_top_variant="n/a"
backup_top_variant="n/a"
primary_variant_win_trend="n/a"
backup_variant_win_trend="n/a"
primary_channel_roi_score="n/a"
backup_channel_roi_score="n/a"
channel_roi_preferred_channel="balanced"
channel_roi_recommendation=""
channel_mix_recommendation="Keep channel mix balanced until distribution execution score is logged."
variant_recommendation="Keep current top-performing variant as default and iterate one challenger."
outreach_recommendation="Focus outreach on warm creator conversations and one follow-up pass."
creator_signal_enrichment_score="n/a"
guesting_signal_enrichment_score="n/a"
win_card_delta="n/a"
installs_delta="n/a"
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
    --primary-top-variant)
      primary_top_variant="${2:-}"
      shift 2
      ;;
    --backup-top-variant)
      backup_top_variant="${2:-}"
      shift 2
      ;;
    --primary-variant-win-trend)
      primary_variant_win_trend="${2:-}"
      shift 2
      ;;
    --backup-variant-win-trend)
      backup_variant_win_trend="${2:-}"
      shift 2
      ;;
    --primary-channel-roi-score)
      primary_channel_roi_score="${2:-}"
      shift 2
      ;;
    --backup-channel-roi-score)
      backup_channel_roi_score="${2:-}"
      shift 2
      ;;
    --channel-roi-preferred-channel)
      channel_roi_preferred_channel="${2:-}"
      shift 2
      ;;
    --channel-roi-recommendation)
      channel_roi_recommendation="${2:-}"
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
    --creator-signal-enrichment-score)
      creator_signal_enrichment_score="${2:-}"
      shift 2
      ;;
    --guesting-signal-enrichment-score)
      guesting_signal_enrichment_score="${2:-}"
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

primary_roi_score_number="$(extract_number "$primary_channel_roi_score")"
backup_roi_score_number="$(extract_number "$backup_channel_roi_score")"
creator_score_number="$(extract_number "$creator_signal_enrichment_score")"
guesting_score_number="$(extract_number "$guesting_signal_enrichment_score")"
win_card_delta_number="$(extract_number "$win_card_delta")"
installs_delta_number="$(extract_number "$installs_delta")"

if [[ -z "$primary_roi_score_number" ]]; then
  primary_roi_score_number=60
fi
if [[ -z "$backup_roi_score_number" ]]; then
  backup_roi_score_number=58
fi
if [[ -z "$creator_score_number" ]]; then
  creator_score_number=55
fi
if [[ -z "$guesting_score_number" ]]; then
  guesting_score_number=50
fi
if [[ -z "$win_card_delta_number" ]]; then
  win_card_delta_number=0
fi
if [[ -z "$installs_delta_number" ]]; then
  installs_delta_number=0
fi

preferred_route="$(normalize_channel_preference "$channel_roi_preferred_channel")"

if [[ -z "$channel_roi_recommendation" ]]; then
  if (( $(awk -v primary="$primary_roi_score_number" -v backup="$backup_roi_score_number" 'BEGIN { print (primary >= backup) ? 1 : 0 }') )); then
    channel_roi_recommendation="Lead with $primary_channel while preserving one reinforcement post in $backup_channel."
  else
    channel_roi_recommendation="Lead with $backup_channel while preserving one reinforcement post in $primary_channel."
  fi
fi

proof_lead_channel="$primary_channel"
workflow_lead_channel="$backup_channel"
objection_lead_channel="$backup_channel"
creator_lead_channel="$primary_channel"
guesting_lead_channel="$backup_channel"

if [[ "$preferred_route" == "primary" ]]; then
  proof_lead_channel="$primary_channel"
  workflow_lead_channel="$primary_channel"
  objection_lead_channel="$backup_channel"
  creator_lead_channel="$primary_channel"
  guesting_lead_channel="$backup_channel"
elif [[ "$preferred_route" == "backup" ]]; then
  proof_lead_channel="$backup_channel"
  workflow_lead_channel="$backup_channel"
  objection_lead_channel="$primary_channel"
  creator_lead_channel="$backup_channel"
  guesting_lead_channel="$primary_channel"
fi

score_proof="$(clamp_score "$(awk -v base="58" -v win_delta="$win_card_delta_number" -v installs_delta="$installs_delta_number" 'BEGIN {
  score = base
  if (win_delta > 0) score += win_delta * 3.0
  if (installs_delta > 0) score += installs_delta * 2.5
  if (win_delta < 0) score += win_delta * 1.5
  if (installs_delta < 0) score += installs_delta * 1.3
  printf "%.4f", score
}')")"

score_workflow="$(clamp_score "$(awk -v base="55" -v primary_roi="$primary_roi_score_number" -v backup_roi="$backup_roi_score_number" 'BEGIN {
  spread = primary_roi - backup_roi
  if (spread < 0) spread = -spread
  score = base + (spread * 0.35)
  printf "%.4f", score
}')")"

score_objection="$(clamp_score "$(awk -v base="52" -v creator_score="$creator_score_number" -v guesting_score="$guesting_score_number" 'BEGIN {
  confidence_gap = 100 - ((creator_score + guesting_score) / 2)
  score = base + (confidence_gap * 0.28)
  printf "%.4f", score
}')")"

score_creator="$(clamp_score "$(awk -v base="54" -v creator_score="$creator_score_number" 'BEGIN {
  score = base + ((100 - creator_score) * 0.42)
  printf "%.4f", score
}')")"

score_guesting="$(clamp_score "$(awk -v base="53" -v guesting_score="$guesting_score_number" 'BEGIN {
  score = base + ((100 - guesting_score) * 0.45)
  printf "%.4f", score
}')")"

declare -a hooks
hooks=(
  "${score_proof}|Proof-First Outcome Hook|${proof_lead_channel}|I cut [task] from [before] to [after] using ${strongest_metric_label}.|Strongest metric and install momentum are the fastest trust driver.|${score_proof}"
  "${score_workflow}|Workflow-First Demo Hook|${workflow_lead_channel}|3-step flow: open command, run workflow, share result in under 60s.|Variant trend and channel ROI suggest process-first framing can scale.|${score_workflow}"
  "${score_objection}|Objection-Handler Hook|${objection_lead_channel}|Local-first by default, optional AI when needed, practical output either way.|Confidence objections still block conversion without proactive handling.|${score_objection}"
  "${score_creator}|Creator Collaboration Hook|${creator_lead_channel}|Looking for 3 creators to run this workflow and publish side-by-side results.|Creator enrichment score indicates high leverage in targeted partnerships.|${score_creator}"
  "${score_guesting}|Founder Storyline Hook|${guesting_lead_channel}|Founder build-log: what changed this week, what shipped, and what learned.|Guesting enrichment score indicates room to compound founder reach.|${score_guesting}"
)

ranked_lines="$(printf '%s\n' "${hooks[@]}" | sort -t'|' -k1,1nr -k2,2)"

top_hook_names=()
top_hook_channels=()
top_hook_scripts=()
top_hook_reasons=()

while IFS='|' read -r _ hook_name lead_channel script_seed reason _; do
  [[ -z "$hook_name" ]] && continue
  top_hook_names+=("$hook_name")
  top_hook_channels+=("$lead_channel")
  top_hook_scripts+=("$script_seed")
  top_hook_reasons+=("$reason")
  if (( ${#top_hook_names[@]} >= 3 )); then
    break
  fi
done <<< "$ranked_lines"

while (( ${#top_hook_names[@]} < 3 )); do
  top_hook_names+=("Hook candidate")
  top_hook_channels+=("$primary_channel")
  top_hook_scripts+=("Share one concrete before/after with a measured outcome.")
  top_hook_reasons+=("Fallback suggestion until fresh signal data is available.")
done

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
mkdir -p "$(dirname "$output_path")"

{
  echo "<!-- weekly-growth-winning-hook-library -->"
  echo
  echo "# Winning Hook Library: $week"
  echo
  echo "Generated: $generated_on"
  echo "Metric focus: $metric_focus"
  echo
  echo "## Signal Snapshot"
  echo
  echo "- Strongest metric: $strongest_metric_label ($strongest_metric_value)"
  echo "- Win Card delta: $(format_signed_number "$win_card_delta_number")"
  echo "- Installs delta: $(format_signed_number "$installs_delta_number")"
  echo "- Primary top variant: $primary_top_variant ($primary_variant_win_trend)"
  echo "- Backup top variant: $backup_top_variant ($backup_variant_win_trend)"
  echo "- Primary channel ROI score: $(format_percent_or_na "$primary_channel_roi_score")"
  echo "- Backup channel ROI score: $(format_percent_or_na "$backup_channel_roi_score")"
  echo "- Creator enrichment score: $(format_percent_or_na "$creator_signal_enrichment_score")"
  echo "- Founder guesting enrichment score: $(format_percent_or_na "$guesting_signal_enrichment_score")"
  echo "- Preferred route: $preferred_route"
  echo "- Channel route recommendation: $channel_roi_recommendation"
  echo "- Channel mix recommendation: $channel_mix_recommendation"
  echo
  echo "## Ranked Hooks"
  echo
  echo "| Rank | Hook | Best channel | Script seed | Why now | Priority score |"
  echo "| --- | --- | --- | --- | --- | --- |"
  rank=1
  while IFS='|' read -r _ hook_name lead_channel script_seed reason priority_score; do
    [[ -z "$hook_name" ]] && continue
    echo "| $rank | $hook_name | $lead_channel | $script_seed | $reason | $priority_score |"
    rank=$(( rank + 1 ))
  done <<< "$ranked_lines"
  echo
  echo "## Copy-Ready Hook Seeds"
  echo
  echo "### Hook A"
  echo
  echo "- Hook type: ${top_hook_names[1]}"
  echo "- Lead channel: ${top_hook_channels[1]}"
  echo "- Script seed: ${top_hook_scripts[1]}"
  echo "- Why now: ${top_hook_reasons[1]}"
  echo
  echo "### Hook B"
  echo
  echo "- Hook type: ${top_hook_names[2]}"
  echo "- Lead channel: ${top_hook_channels[2]}"
  echo "- Script seed: ${top_hook_scripts[2]}"
  echo "- Why now: ${top_hook_reasons[2]}"
  echo
  echo "### Hook C"
  echo
  echo "- Hook type: ${top_hook_names[3]}"
  echo "- Lead channel: ${top_hook_channels[3]}"
  echo "- Script seed: ${top_hook_scripts[3]}"
  echo "- Why now: ${top_hook_reasons[3]}"
  echo
  echo "## Routing Notes"
  echo
  echo "- Variant recommendation: $variant_recommendation"
  echo "- Outreach recommendation: $outreach_recommendation"
  echo
  echo "## Execution Checklist"
  echo
  echo "- [ ] Assign owner + publish slot for Hook A and Hook B"
  echo "- [ ] Ship one hook on lead channel before mid-week checkpoint"
  echo "- [ ] Keep one control variable fixed per hook test"
  echo "- [ ] Promote the highest-performing hook into Monday defaults"
} > "$output_path"

echo "Wrote winning hook library: $output_path"
