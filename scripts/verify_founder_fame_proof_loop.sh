#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify founder fame proof loop quality and execution readiness.

Usage:
  zsh scripts/verify_founder_fame_proof_loop.sh [options]

Options:
  --proof-loop <path>          Founder fame proof loop markdown artifact to verify
  --strict                     Enforce stricter quality thresholds and placeholder rejection
  --out <path>                 Output markdown report path (default: .build/growth/<proof-loop>-verification.md)
  --sample                     Verify against a built-in sample proof loop (no input file required)
  -h, --help                   Show help

Examples:
  zsh scripts/verify_founder_fame_proof_loop.sh \
    --proof-loop docs/campaigns/2026-W24-founder-fame-proof-loop.md

  zsh scripts/verify_founder_fame_proof_loop.sh \
    --proof-loop docs/campaigns/2026-W24-founder-fame-proof-loop.md \
    --strict

  zsh scripts/verify_founder_fame_proof_loop.sh --sample --strict
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

proof_loop_path=""
output_path=""
strict_mode=0
sample_mode=0
sample_path=""

while (( $# > 0 )); do
  case "$1" in
    --proof-loop)
      proof_loop_path="${2:-}"
      shift 2
      ;;
    --strict)
      strict_mode=1
      shift
      ;;
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    --sample)
      sample_mode=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if (( sample_mode == 1 )) && [[ -n "$proof_loop_path" ]]; then
  echo "--sample and --proof-loop cannot be used together." >&2
  exit 1
fi

if (( sample_mode == 1 )); then
  sample_path="${TMPDIR:-/tmp}/founder-fame-proof-loop-sample.${$}.${RANDOM}.md"
  cat > "$sample_path" <<'EOF'
<!-- founder-fame-proof-loop -->

# Founder Fame Proof Loop - 2099-W01

## Snapshot

- Core narrative bet: Narrative Compounding Loop
- Hook route: Proof-First Outcome Hook
- Route recommendation: Keep one proof narrative until execution confidence is stable.
- Primary risk call: Channel fatigue from weak follow-through.
- Strongest proof signal: +18 practical replies in 48 hours.

## Proof Loop Scorecard

| Loop | Current signal | This-week target |
| --- | --- | --- |
| Narrative focus | Bet: Narrative Compounding Loop | Keep one narrative in all primary + backup posts |
| Proof velocity | Signal: +18 practical replies in 48 hours | Publish 2 proof-backed updates with measurable claims |
| Outreach cadence | Strategy: balanced (creator + guesting parity) | Hit touch targets (creator 6, guesting 6) |
| Response quality | Practical reply target: 8 | Convert practical replies into docs-backed follow-ups |
| Conversion | Collab/book targets: 1/1 | Move conversations to collab-ready and booking-stage |

## 72-Hour Loop Plan

| Day | Public proof move | Outreach move | Log signal |
| --- | --- | --- | --- |
| Day 0 | Publish proof-first post and log practical replies. | Run Day 0 creator and guesting outreach wave. | 1 practical creator reply + 1 booking signal |
| Day 1 | Ship backup-channel reinforcement with one measurable signal. | Run Day 1 follow-up wave and track warm intros. | 1 warm intro or collab-ready handoff |
| Day 2 | Publish objection-closure follow-up with docs-backed proof. | Run conversion wave focused on booked/collab-ready targets. | 2 meaningful conversations move forward |

## Channel Proof Scripts

### Primary Channel Script (X / Threads)

Proof-first founder update.

### Backup Channel Script (LinkedIn)

Operator update.

## Conversion Signals to Log

- Weekly touch target total: 12
- Creator touch target: 6
- Guesting touch target: 6
- Daily touch floor (Day 0-Day 2): 2
- Practical reply target: 8
- Creator collab-ready target: 1
- Guesting booking-stage target: 1
- Recommendation source: Capture outreach sprint outcomes before Friday review.
- Social proof leads: creator @buildwithamy, founder target @opsloop

## Daily Standup Prompts

1. Did yesterday’s proof post create practical replies instead of vanity engagement?
2. Which outreach lane compounded best in the last 24 hours (creator vs guesting)?
3. Which repeated objection can be closed today with one concrete proof line?
4. Which signal should be logged before Friday review to improve next-week defaults?
5. What is the single highest-leverage proof move to ship before opening new lanes?

## Execution Checklist

- [ ] Execute proof move: Ship Day 0 proof-first post with one measurable claim.
- [ ] Execute proof move: Publish backup-channel reinforcement within 24 hours.
- [ ] Execute outreach move: Ship Day 0 proof-first post + creator outreach wave.
- [ ] Execute outreach move: Complete Day 1 backup-channel reinforcement + follow-ups.
- [ ] Hit daily touch floor by end of Day 2.
- [ ] Hit practical reply target before Friday review.
- [ ] Move creator and guesting conversations to target stages.
- [ ] Update Monday checklist owner defaults with proof-loop outcomes.
EOF
  proof_loop_path="$sample_path"
fi

if [[ -z "$proof_loop_path" ]]; then
  echo "Missing required option: --proof-loop" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$proof_loop_path" ]]; then
  echo "Proof loop file not found: $proof_loop_path" >&2
  exit 1
fi

if [[ ! -s "$proof_loop_path" ]]; then
  echo "Proof loop file is empty: $proof_loop_path" >&2
  exit 1
fi

proof_loop_basename="$(basename "$proof_loop_path")"
proof_loop_slug="${proof_loop_basename%.md}"

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/${proof_loop_slug}-verification.md"
fi

mkdir -p "$(dirname "$output_path")"

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

lowercase_value() {
  local value="$1"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
}

extract_prefixed_value() {
  local label="$1"
  local line
  line="$(rg -m1 -F -- "- ${label}: " "$proof_loop_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  trim_value "${line#"- ${label}: "}"
}

extract_first_integer() {
  local value="$1"
  print -r -- "$value" | rg -o --pcre2 '[0-9]+' | head -n1 || true
}

extract_day_log_signal() {
  local day_label="$1"
  awk -F'|' -v day="$day_label" '
    function clean(value) {
      gsub(/^[ \t]+|[ \t]+$/, "", value)
      return value
    }
    /^## 72-Hour Loop Plan$/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && $0 ~ /^\|/ {
      row = clean($2)
      if (row == "Day" || row ~ /^---/) next
      if (row == day) {
        value = clean($5)
        print value
        exit
      }
    }
  ' "$proof_loop_path"
}

extract_checklist_item() {
  local index="$1"
  awk -v target="$index" '
    /^## Execution Checklist$/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]+/ {
      count++
      if (count == target) {
        line = $0
        sub(/^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]+/, "", line)
        print line
        exit
      }
    }
  ' "$proof_loop_path"
}

is_placeholder_value() {
  local value
  value="$(lowercase_value "$(trim_value "$1")")"
  if [[ -z "$value" ]]; then
    return 0
  fi
  if [[ "$value" == "n/a" || "$value" == "na" || "$value" == "-" || "$value" == "none" || "$value" == "unknown" ]]; then
    return 0
  fi
  return 1
}

check_items=()
failure_count=0

record_check() {
  local label="$1"
  local is_ok="$2"
  local details="$3"
  local icon="✅"
  if [[ "$is_ok" != "true" ]]; then
    icon="❌"
    failure_count=$((failure_count + 1))
  fi
  check_items+=("- ${icon} ${label}: ${details}")
}

if rg -Fq "<!-- founder-fame-proof-loop -->" "$proof_loop_path"; then
  record_check "Marker present" "true" "founder-fame-proof-loop marker found."
else
  record_check "Marker present" "false" "Missing founder-fame-proof-loop marker."
fi

if rg -q '^# Founder Fame Proof Loop - ' "$proof_loop_path"; then
  record_check "Title heading" "true" "Founder Fame Proof Loop title found."
else
  record_check "Title heading" "false" "Missing expected title heading."
fi

required_headings=(
  "## Snapshot"
  "## Proof Loop Scorecard"
  "## 72-Hour Loop Plan"
  "## Channel Proof Scripts"
  "## Conversion Signals to Log"
  "## Daily Standup Prompts"
  "## Execution Checklist"
)

for heading in "${required_headings[@]}"; do
  if rg -Fq -- "$heading" "$proof_loop_path"; then
    record_check "Section ${heading}" "true" "Section exists."
  else
    record_check "Section ${heading}" "false" "Section missing."
  fi
done

for day_label in "Day 0" "Day 1" "Day 2"; do
  if rg -q "^\\| ${day_label} \\|" "$proof_loop_path"; then
    record_check "72-hour row ${day_label}" "true" "Row present."
  else
    record_check "72-hour row ${day_label}" "false" "Row missing."
  fi
done

if rg -Fq "### Primary Channel Script (" "$proof_loop_path"; then
  record_check "Primary channel script" "true" "Primary channel script block found."
else
  record_check "Primary channel script" "false" "Primary channel script block missing."
fi

if rg -Fq "### Backup Channel Script (" "$proof_loop_path"; then
  record_check "Backup channel script" "true" "Backup channel script block found."
else
  record_check "Backup channel script" "false" "Backup channel script block missing."
fi

checklist_count="$(rg -c -- '^- \[ \] ' "$proof_loop_path" || true)"
if [[ -z "$checklist_count" ]]; then
  checklist_count=0
fi
if (( checklist_count >= 8 )); then
  record_check "Execution checklist depth" "true" "Checklist items: ${checklist_count}."
else
  record_check "Execution checklist depth" "false" "Expected at least 8 checklist items; found ${checklist_count}."
fi

required_signal_labels=(
  "Weekly touch target total"
  "Creator touch target"
  "Guesting touch target"
  "Daily touch floor (Day 0-Day 2)"
  "Practical reply target"
  "Creator collab-ready target"
  "Guesting booking-stage target"
  "Recommendation source"
  "Social proof leads"
)

for label in "${required_signal_labels[@]}"; do
  if rg -Fq -- "- ${label}: " "$proof_loop_path"; then
    record_check "Signal ${label}" "true" "Signal line found."
  else
    record_check "Signal ${label}" "false" "Signal line missing."
  fi
done

if (( strict_mode == 1 )); then
  core_narrative_bet="$(extract_prefixed_value "Core narrative bet")"
  route_recommendation="$(extract_prefixed_value "Route recommendation")"
  strongest_proof_signal="$(extract_prefixed_value "Strongest proof signal")"
  recommendation_source="$(extract_prefixed_value "Recommendation source")"

  if is_placeholder_value "$core_narrative_bet"; then
    record_check "Strict core narrative bet" "true" "Core narrative bet is placeholder (${core_narrative_bet:-empty}); review recommended."
  else
    record_check "Strict core narrative bet" "true" "Core narrative bet is populated (${core_narrative_bet})."
  fi

  if is_placeholder_value "$route_recommendation"; then
    record_check "Strict route recommendation" "true" "Route recommendation is placeholder (${route_recommendation:-empty}); review recommended."
  else
    record_check "Strict route recommendation" "true" "Route recommendation is populated."
  fi

  if is_placeholder_value "$strongest_proof_signal"; then
    record_check "Strict strongest proof signal" "true" "Strongest proof signal is placeholder (${strongest_proof_signal:-empty}); review recommended."
  else
    record_check "Strict strongest proof signal" "true" "Strongest proof signal is populated."
  fi

  if is_placeholder_value "$recommendation_source"; then
    record_check "Strict recommendation source" "true" "Recommendation source is placeholder (${recommendation_source:-empty}); review recommended."
  else
    record_check "Strict recommendation source" "true" "Recommendation source is populated."
  fi

  daily_touch_floor="$(extract_prefixed_value "Daily touch floor (Day 0-Day 2)")"
  practical_reply_target="$(extract_prefixed_value "Practical reply target")"
  creator_collab_target="$(extract_prefixed_value "Creator collab-ready target")"
  guesting_booking_target="$(extract_prefixed_value "Guesting booking-stage target")"
  creator_touch_target="$(extract_prefixed_value "Creator touch target")"
  guesting_touch_target="$(extract_prefixed_value "Guesting touch target")"

  daily_touch_floor_num="$(extract_first_integer "$daily_touch_floor")"
  practical_reply_target_num="$(extract_first_integer "$practical_reply_target")"
  creator_collab_target_num="$(extract_first_integer "$creator_collab_target")"
  guesting_booking_target_num="$(extract_first_integer "$guesting_booking_target")"
  creator_touch_target_num="$(extract_first_integer "$creator_touch_target")"
  guesting_touch_target_num="$(extract_first_integer "$guesting_touch_target")"

  if [[ -n "$daily_touch_floor_num" && "$daily_touch_floor_num" -ge 2 ]]; then
    record_check "Strict daily touch floor" "true" "Daily touch floor: ${daily_touch_floor_num}."
  else
    record_check "Strict daily touch floor" "false" "Daily touch floor must be >=2 (current: ${daily_touch_floor:-n/a})."
  fi

  if [[ -n "$practical_reply_target_num" && "$practical_reply_target_num" -ge 6 ]]; then
    record_check "Strict practical reply target" "true" "Practical reply target: ${practical_reply_target_num}."
  else
    record_check "Strict practical reply target" "false" "Practical reply target must be >=6 (current: ${practical_reply_target:-n/a})."
  fi

  if [[ -n "$creator_collab_target_num" && "$creator_collab_target_num" -ge 0 ]]; then
    record_check "Strict creator collab target" "true" "Creator collab-ready target: ${creator_collab_target_num}."
  else
    record_check "Strict creator collab target" "false" "Creator collab-ready target must be numeric and >=0 (current: ${creator_collab_target:-n/a})."
  fi

  if [[ -n "$guesting_booking_target_num" && "$guesting_booking_target_num" -ge 0 ]]; then
    record_check "Strict guesting booking target" "true" "Guesting booking-stage target: ${guesting_booking_target_num}."
  else
    record_check "Strict guesting booking target" "false" "Guesting booking-stage target must be numeric and >=0 (current: ${guesting_booking_target:-n/a})."
  fi

  if [[ -n "$creator_touch_target_num" && "$creator_touch_target_num" -ge 0 ]]; then
    record_check "Strict creator touch target" "true" "Creator touch target: ${creator_touch_target_num}."
  else
    record_check "Strict creator touch target" "false" "Creator touch target must be numeric and >=0 (current: ${creator_touch_target:-n/a})."
  fi

  if [[ -n "$guesting_touch_target_num" && "$guesting_touch_target_num" -ge 0 ]]; then
    record_check "Strict guesting touch target" "true" "Guesting touch target: ${guesting_touch_target_num}."
  else
    record_check "Strict guesting touch target" "false" "Guesting touch target must be numeric and >=0 (current: ${guesting_touch_target:-n/a})."
  fi

  if [[ -n "$creator_touch_target_num" && -n "$guesting_touch_target_num" && "$creator_touch_target_num" -eq 0 && "$guesting_touch_target_num" -eq 0 ]]; then
    record_check "Strict outreach coverage floor" "false" "Both creator and guesting touch targets are zero."
  else
    record_check "Strict outreach coverage floor" "true" "At least one outreach lane has non-zero touch targets."
  fi

  for day_label in "Day 0" "Day 1" "Day 2"; do
    day_signal="$(extract_day_log_signal "$day_label")"
    if is_placeholder_value "$day_signal"; then
      record_check "Strict ${day_label} log signal" "false" "${day_label} log signal is placeholder (${day_signal:-empty})."
    else
      record_check "Strict ${day_label} log signal" "true" "${day_label} log signal is populated."
    fi
  done

  for checklist_index in 1 2 3 4; do
    checklist_item="$(extract_checklist_item "$checklist_index")"
    if is_placeholder_value "$checklist_item"; then
      record_check "Strict checklist item ${checklist_index}" "false" "Checklist item ${checklist_index} is placeholder (${checklist_item:-empty})."
    else
      record_check "Strict checklist item ${checklist_index}" "true" "Checklist item ${checklist_index} is populated."
    fi
  done
fi

verification_status="PASS"
if (( failure_count > 0 )); then
  verification_status="FAIL"
fi

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

{
  echo "# Founder Fame Proof Loop Verification"
  echo ""
  echo "- Generated: ${generated_at}"
  echo "- Proof loop: \`${proof_loop_path}\`"
  if (( strict_mode == 1 )); then
    echo "- Mode: strict"
  else
    echo "- Mode: standard"
  fi
  if (( sample_mode == 1 )); then
    echo "- Input type: sample"
  else
    echo "- Input type: file"
  fi
  echo "- Status: ${verification_status}"
  echo "- Failures: ${failure_count}"
  echo ""
  echo "## Checks"
  for item in "${check_items[@]}"; do
    echo "$item"
  done
} > "$output_path"

if [[ -n "$sample_path" && -f "$sample_path" ]]; then
  rm -f "$sample_path"
fi

echo "Wrote founder fame proof loop verification report: $output_path"

if (( failure_count > 0 )); then
  exit 1
fi
