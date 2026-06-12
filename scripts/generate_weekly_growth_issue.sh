#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Generate a weekly growth sprint issue body markdown file.

Usage:
  zsh scripts/generate_weekly_growth_issue.sh [options]

Options:
  --week <YYYY-Www>         Sprint week label (default: current ISO week)
  --campaign <path>         Campaign pack markdown path (optional)
  --primary <text>          Primary channel label
  --backup <text>           Backup channel label
  --metric <text>           Primary metric focus
  --prev-week <YYYY-Www>    Previous week label (optional)
  --prev-baseline-week <YYYY-Www> Previous baseline week for deltas (optional)
  --prev-win-card <value>   Previous week Win Card copies
  --prev-win-card-delta <value> Previous week Win Card delta
  --prev-win-recap <value>  Previous week Win Recap copies
  --prev-win-recap-delta <value> Previous week Win Recap delta
  --prev-posts <value>      Previous week public posts shipped
  --prev-posts-delta <value> Previous week public posts delta
  --prev-stories <value>    Previous week user-generated stories
  --prev-stories-delta <value> Previous week user-generated stories delta
  --prev-installs <value>   Previous week inbound installs/trials
  --prev-installs-delta <value> Previous week inbound installs/trials delta
  --out <path>              Output markdown path (required)
  -h, --help                Show this help

Example:
  zsh scripts/generate_weekly_growth_issue.sh \
    --week "$(date +%Y-W%V)" \
    --campaign .build/growth/$(date +%Y-W%V)-campaign.md \
    --primary "X / Threads" \
    --backup "LinkedIn" \
    --metric "Win Card copies" \
    --out .build/growth/$(date +%Y-W%V)-issue.md
EOF
}

week="$(date '+%Y-W%V')"
campaign_path=""
primary_channel="X / Threads"
backup_channel="LinkedIn"
metric_focus="Win Card copies and reply quality"
previous_week=""
previous_baseline_week=""
previous_win_card=""
previous_win_card_delta=""
previous_win_recap=""
previous_win_recap_delta=""
previous_posts=""
previous_posts_delta=""
previous_stories=""
previous_stories_delta=""
previous_installs=""
previous_installs_delta=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --week)
      week="${2:-}"
      shift 2
      ;;
    --campaign)
      campaign_path="${2:-}"
      shift 2
      ;;
    --primary)
      primary_channel="${2:-}"
      shift 2
      ;;
    --backup)
      backup_channel="${2:-}"
      shift 2
      ;;
    --metric)
      metric_focus="${2:-}"
      shift 2
      ;;
    --prev-week)
      previous_week="${2:-}"
      shift 2
      ;;
    --prev-baseline-week)
      previous_baseline_week="${2:-}"
      shift 2
      ;;
    --prev-win-card)
      previous_win_card="${2:-}"
      shift 2
      ;;
    --prev-win-card-delta)
      previous_win_card_delta="${2:-}"
      shift 2
      ;;
    --prev-win-recap)
      previous_win_recap="${2:-}"
      shift 2
      ;;
    --prev-win-recap-delta)
      previous_win_recap_delta="${2:-}"
      shift 2
      ;;
    --prev-posts)
      previous_posts="${2:-}"
      shift 2
      ;;
    --prev-posts-delta)
      previous_posts_delta="${2:-}"
      shift 2
      ;;
    --prev-stories)
      previous_stories="${2:-}"
      shift 2
      ;;
    --prev-stories-delta)
      previous_stories_delta="${2:-}"
      shift 2
      ;;
    --prev-installs)
      previous_installs="${2:-}"
      shift 2
      ;;
    --prev-installs-delta)
      previous_installs_delta="${2:-}"
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

mkdir -p "$(dirname "$output_path")"

generated_on="$(date '+%Y-%m-%d %H:%M:%S %Z')"
preview_section=""
if [[ -n "$campaign_path" && -f "$campaign_path" ]]; then
  preview_section=$(
    cat <<EOF
## Campaign Draft Preview

\`\`\`markdown
$(sed -n '1,80p' "$campaign_path")
\`\`\`
EOF
  )
fi

previous_section=""
if [[ -n "$previous_week" ]]; then
  baseline_note=""
  if [[ -n "$previous_baseline_week" ]]; then
    baseline_note=" vs $previous_baseline_week"
  fi

  format_delta_suffix() {
    local delta_value="$1"
    local baseline_value="$2"
    if [[ -n "$delta_value" ]]; then
      printf " (%s%s)" "$delta_value" "$baseline_value"
    fi
  }

  previous_win_card_suffix="$(format_delta_suffix "$previous_win_card_delta" "$baseline_note")"
  previous_win_recap_suffix="$(format_delta_suffix "$previous_win_recap_delta" "$baseline_note")"
  previous_posts_suffix="$(format_delta_suffix "$previous_posts_delta" "$baseline_note")"
  previous_stories_suffix="$(format_delta_suffix "$previous_stories_delta" "$baseline_note")"
  previous_installs_suffix="$(format_delta_suffix "$previous_installs_delta" "$baseline_note")"

  previous_section=$(
    cat <<EOF
## Previous Week Snapshot ($previous_week)

- Win Card copies: ${previous_win_card:-n/a}${previous_win_card_suffix}
- Win Recap copies: ${previous_win_recap:-n/a}${previous_win_recap_suffix}
- Public posts shipped: ${previous_posts:-n/a}${previous_posts_suffix}
- User-generated stories: ${previous_stories:-n/a}${previous_stories_suffix}
- Inbound installs/trials: ${previous_installs:-n/a}${previous_installs_suffix}
EOF
  )
fi

cat > "$output_path" <<EOF
# Weekly Growth Sprint: $week

Generated: $generated_on

## Focus

- Primary channel: $primary_channel
- Backup channel: $backup_channel
- Metric focus: $metric_focus

## Execution Checklist

- [ ] Run \`zsh scripts/run_launch_day.sh --skip-tests\`.
- [ ] Publish Monday before/after post.
- [ ] Publish Wednesday command spotlight post.
- [ ] Publish Friday workflow thread.
- [ ] Reply to practical questions within 24 hours.
- [ ] Capture top 3 replies/questions.
- [ ] Convert one repeated question into a docs update.
- [ ] Open one \`Win story\` issue from real user proof.

## Measurement Log

- Win Card copies:
- Win Recap copies:
- Public posts shipped:
- User-generated stories:
- Inbound installs/trials:

## End-of-Week Notes

- Best-performing hook:
- Most reusable workflow:
- What to double down next week:

$previous_section

$preview_section
EOF

echo "Wrote weekly growth issue body: $output_path"
