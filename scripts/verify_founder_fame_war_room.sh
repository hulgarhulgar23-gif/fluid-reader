#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify founder fame war-room quality and launch readiness.

Usage:
  zsh scripts/verify_founder_fame_war_room.sh [options]

Options:
  --war-room <path>           Founder fame war-room markdown artifact to verify
  --strict                    Enforce stricter quality thresholds and placeholder rejection
  --out <path>                Output markdown report path (default: .build/growth/<war-room>-verification.md)
  --sample                    Verify against a built-in sample war room (no input file required)
  -h, --help                  Show help

Examples:
  zsh scripts/verify_founder_fame_war_room.sh \
    --war-room docs/campaigns/2026-W24-founder-fame-war-room.md

  zsh scripts/verify_founder_fame_war_room.sh \
    --war-room docs/campaigns/2026-W24-founder-fame-war-room.md \
    --strict

  zsh scripts/verify_founder_fame_war_room.sh --sample --strict
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

war_room_path=""
output_path=""
strict_mode=0
sample_mode=0
sample_path=""

while (( $# > 0 )); do
  case "$1" in
    --war-room)
      war_room_path="${2:-}"
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

if (( sample_mode == 1 )) && [[ -n "$war_room_path" ]]; then
  echo "--sample and --war-room cannot be used together." >&2
  exit 1
fi

if (( sample_mode == 1 )); then
  sample_path="${TMPDIR:-/tmp}/founder-fame-war-room-sample.${$}.${RANDOM}.md"
  cat > "$sample_path" <<'EOF'
<!-- founder-fame-war-room -->

# Founder Fame War Room - 2099-W01

Generated: 2099-01-01 00:00:00 +0000
Product: Fluid Reader
Source command center: docs/campaigns/2099-W01-founder-fame-command-center.md
Source next-move handoff: docs/campaigns/2099-W01-founder-fame-next-move-handoff.md
Source next-move draft pack: docs/campaigns/2099-W01-founder-fame-next-move-draft-pack.md
Source proof-loop check: docs/campaigns/2099-W01-founder-fame-proof-loop-check.md
Source narrative lab: docs/campaigns/2099-W01-founder-fame-narrative-lab.md

## Snapshot

- Command center: Founder Fame Command Center - 2099-W01
- Next-move handoff: Founder Fame Next Move Handoff - 2099-W01
- Next-move draft pack: Founder Fame Next Move Draft Pack - 2099-W01
- Proof-loop check: Founder Fame Proof Loop Verification
- Narrative lab: Founder Fame Narrative Lab - 2099-W01
- Top bet: Narrative Compounding Loop
- Execution readiness: 91/100 (Ready)
- Queue pressure: 24/100 (Monitor)
- Route alignment signal: Aligned
- Route response mode: Route Re-Lock
- Priority route: Route re-lock sequence
- Proof-loop verification: PASS (strict)

## Launch Control

- Run now: Run Fame Next Move
- Artifact link: docs/campaigns/2099-W01-founder-fame-next-move-handoff.md
- Checklist target: Monday Publish Checklist 2099-W01
- Owner update: Owner: Growth lead - shipped + shared in checklist.
- Primary risk call: Momentum dips when follow-up is delayed.
- Routing recommendation: Keep one proof narrative and close one blocker per cycle.

## Draft Pack

X:
Week 2099-W01: ran Run Fame Next Move. Proof-backed momentum is live and checklist updates are posted.

LinkedIn:
Founder ops update (2099-W01): we executed Run Fame Next Move, logged artifact evidence, and aligned owners on the next route checkpoint.

Checklist:
Artifact link: docs/campaigns/2099-W01-founder-fame-next-move-handoff.md | Owner update: Owner: Growth lead - shipped + shared in checklist.

## 90-Minute Execution Sprint

| Minute | Focus | Output |
| --- | --- | --- |
| 0-15 | Standup route lock | Confirm top bet and route signal with owner. |
| 15-40 | Run in-app next move | Execute Run Fame Next Move and capture artifact. |
| 40-65 | Publish draft pack | Post X + LinkedIn drafts and log checklist update. |
| 65-90 | Close proof loop | Verify PASS status and set next checkpoint. |

## Checklist Marker Block

```text
weekly-growth-founder-fame-war-room
week: 2099-W01
selected_command: Run Fame Next Move
artifact_link: docs/campaigns/2099-W01-founder-fame-next-move-handoff.md
checklist_target: Monday Publish Checklist 2099-W01
proof_status: PASS
route_signal: Aligned
```
EOF
  war_room_path="$sample_path"
fi

if [[ -z "$war_room_path" ]]; then
  echo "Missing required option: --war-room" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$war_room_path" ]]; then
  echo "War room file not found: $war_room_path" >&2
  exit 1
fi

if [[ ! -s "$war_room_path" ]]; then
  echo "War room file is empty: $war_room_path" >&2
  exit 1
fi

war_room_basename="$(basename "$war_room_path")"
war_room_slug="${war_room_basename%.md}"

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/${war_room_slug}-verification.md"
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
  local prefix="$1"
  local line
  line="$(rg -m1 -F -- "$prefix" "$war_room_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  trim_value "${line#"$prefix"}"
}

extract_labeled_block() {
  local label="$1"
  awk -v label="$label" '
    $0 == label { in_block = 1; next }
    in_block {
      if ($0 ~ /^## /) exit
      if ($0 == "X:" || $0 == "LinkedIn:" || $0 == "Checklist:") exit
      if ($0 == "" && seen_content == 0) next
      if ($0 != "") seen_content = 1
      print $0
    }
  ' "$war_room_path" | awk 'NF {print; found=1; exit} END {if (!found) print ""}'
}

extract_first_integer() {
  local value="$1"
  print -r -- "$value" | rg -o --pcre2 '[0-9]+' | head -n1 || true
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

if rg -Fq "<!-- founder-fame-war-room -->" "$war_room_path"; then
  record_check "Marker present" "true" "founder-fame-war-room marker found."
else
  record_check "Marker present" "false" "Missing founder-fame-war-room marker."
fi

if rg -q '^# Founder Fame War Room - ' "$war_room_path"; then
  record_check "Title heading" "true" "Founder Fame War Room title found."
else
  record_check "Title heading" "false" "Missing expected title heading."
fi

required_headings=(
  "## Snapshot"
  "## Launch Control"
  "## Draft Pack"
  "## 90-Minute Execution Sprint"
  "## Checklist Marker Block"
)

for heading in "${required_headings[@]}"; do
  if rg -Fq -- "$heading" "$war_room_path"; then
    record_check "Section ${heading}" "true" "Section exists."
  else
    record_check "Section ${heading}" "false" "Section missing."
  fi
done

if rg -q "^- Run now: " "$war_room_path"; then
  record_check "Run-now line" "true" "Run-now line found."
else
  record_check "Run-now line" "false" "Run-now line missing."
fi

if rg -q "^- Artifact link: " "$war_room_path"; then
  record_check "Artifact line" "true" "Artifact line found."
else
  record_check "Artifact line" "false" "Artifact line missing."
fi

if rg -q "^- Checklist target: " "$war_room_path"; then
  record_check "Checklist target line" "true" "Checklist target line found."
else
  record_check "Checklist target line" "false" "Checklist target line missing."
fi

if rg -q "^- Owner update: " "$war_room_path"; then
  record_check "Owner update line" "true" "Owner update line found."
else
  record_check "Owner update line" "false" "Owner update line missing."
fi

for label in "X:" "LinkedIn:" "Checklist:"; do
  if rg -Fq -- "$label" "$war_room_path"; then
    record_check "Draft block ${label}" "true" "Draft block found."
  else
    record_check "Draft block ${label}" "false" "Draft block missing."
  fi
done

for minute_label in "0-15" "15-40" "40-65" "65-90"; do
  if rg -q "^\\| ${minute_label} \\|" "$war_room_path"; then
    record_check "Sprint row ${minute_label}" "true" "Row present."
  else
    record_check "Sprint row ${minute_label}" "false" "Row missing."
  fi
done

if rg -Fq "weekly-growth-founder-fame-war-room" "$war_room_path"; then
  record_check "Checklist marker" "true" "weekly-growth-founder-fame-war-room marker found."
else
  record_check "Checklist marker" "false" "weekly-growth-founder-fame-war-room marker missing."
fi

if (( strict_mode == 1 )); then
  run_now="$(extract_prefixed_value "- Run now: ")"
  artifact_link="$(extract_prefixed_value "- Artifact link: ")"
  checklist_target="$(extract_prefixed_value "- Checklist target: ")"
  proof_status="$(extract_prefixed_value "- Proof-loop verification: ")"
  route_signal="$(extract_prefixed_value "- Route alignment signal: ")"

  if is_placeholder_value "$run_now"; then
    record_check "Strict run-now command" "false" "Run-now command is placeholder (${run_now:-empty})."
  else
    record_check "Strict run-now command" "true" "Run-now command is populated."
  fi

  if is_placeholder_value "$artifact_link"; then
    record_check "Strict artifact link" "false" "Artifact link is placeholder (${artifact_link:-empty})."
  else
    record_check "Strict artifact link" "true" "Artifact link is populated."
  fi

  if [[ "$checklist_target" == *"Monday Publish Checklist"* ]]; then
    record_check "Strict checklist target" "true" "Checklist target is routed to Monday checklist."
  else
    record_check "Strict checklist target" "false" "Checklist target must include Monday Publish Checklist (current: ${checklist_target:-empty})."
  fi

  if [[ "$proof_status" == PASS* ]]; then
    record_check "Strict proof status" "true" "Proof-loop verification is PASS."
  else
    record_check "Strict proof status" "false" "Proof-loop verification must start with PASS (current: ${proof_status:-empty})."
  fi

  if is_placeholder_value "$route_signal"; then
    record_check "Strict route signal" "false" "Route alignment signal is placeholder (${route_signal:-empty})."
  else
    record_check "Strict route signal" "true" "Route alignment signal is populated."
  fi

  x_draft="$(extract_labeled_block "X:")"
  linked_in_draft="$(extract_labeled_block "LinkedIn:")"
  checklist_draft="$(extract_labeled_block "Checklist:")"

  x_length="${#x_draft}"
  if (( x_length > 0 && x_length <= 280 )); then
    record_check "Strict X draft length" "true" "X draft length is ${x_length} (<=280)."
  else
    record_check "Strict X draft length" "false" "X draft must be 1..280 chars (current: ${x_length})."
  fi

  for pair in \
    "Strict LinkedIn draft:$(trim_value "$linked_in_draft")" \
    "Strict checklist draft:$(trim_value "$checklist_draft")"; do
    label="${pair%%:*}"
    value="${pair#*:}"
    if is_placeholder_value "$value"; then
      record_check "$label" "false" "${label#Strict } is placeholder (${value:-empty})."
    else
      record_check "$label" "true" "${label#Strict } is populated."
    fi
  done

  if rg -Fq "selected_command:" "$war_room_path" \
    && rg -Fq "artifact_link:" "$war_room_path" \
    && rg -Fq "checklist_target:" "$war_room_path"; then
    record_check "Strict marker payload" "true" "Checklist marker payload fields are present."
  else
    record_check "Strict marker payload" "false" "Checklist marker payload is missing one or more required fields."
  fi
fi

verification_status="PASS"
if (( failure_count > 0 )); then
  verification_status="FAIL"
fi

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

{
  echo "# Founder Fame War Room Verification"
  echo ""
  echo "- Generated: ${generated_at}"
  echo "- War room: \`${war_room_path}\`"
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

echo "Wrote founder fame war-room verification report: $output_path"

if (( failure_count > 0 )); then
  exit 1
fi
