#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a standalone draft-pack markdown from a founder fame next-move handoff.

Usage:
  zsh scripts/generate_founder_fame_next_move_draft_pack.sh [options]

Required:
  --next-move-handoff <path>   Founder fame next-move handoff markdown

Optional:
  --week <label>               Week label (default: inferred from handoff heading, then current ISO week)
  --out <path>                 Output path (default: docs/campaigns/<week>-founder-fame-next-move-draft-pack.md)
  -h, --help                   Show help

Example:
  zsh scripts/generate_founder_fame_next_move_draft_pack.sh \
    --next-move-handoff docs/campaigns/2026-W24-founder-fame-next-move-handoff.md \
    --out docs/campaigns/2026-W24-founder-fame-next-move-draft-pack.md
EOF
}

next_move_handoff_path=""
week_label=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --next-move-handoff)
      next_move_handoff_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
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

if [[ -z "$next_move_handoff_path" ]]; then
  echo "Missing required option: --next-move-handoff" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$next_move_handoff_path" ]]; then
  echo "Required source file not found: $next_move_handoff_path" >&2
  exit 1
fi

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

compact_line() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  while [[ "$value" == *"  "* ]]; do
    value="${value//  / }"
  done
  trim_value "$value"
}

clamp_line() {
  local value
  value="$(compact_line "$1")"
  local max_length="$2"
  if (( ${#value} <= max_length )); then
    echo "$value"
    return
  fi

  local keep=$((max_length - 3))
  if (( keep < 1 )); then
    keep=1
  fi
  echo "${value[1,$keep]}..."
}

extract_prefixed_value() {
  local source_path="$1"
  local prefix="$2"
  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi
  trim_value "${line#"$prefix"}"
}

extract_week_from_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame Next Move Handoff - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Next Move Handoff - "}"
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading "$next_move_handoff_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-next-move-draft-pack.md"
fi

action_label="$(extract_prefixed_value "$next_move_handoff_path" "Selected command:")"
if [[ -z "$action_label" ]]; then
  action_label="$(extract_prefixed_value "$next_move_handoff_path" "- In-app move:")"
fi
if [[ -z "$action_label" ]]; then
  action_label="$(extract_prefixed_value "$next_move_handoff_path" "Action:")"
fi
if [[ -z "$action_label" ]]; then
  action_label="Run Fame Next Move"
fi

artifact_link="$(extract_prefixed_value "$next_move_handoff_path" "Artifact link:")"
if [[ -z "$artifact_link" ]]; then
  artifact_link="$(extract_prefixed_value "$next_move_handoff_path" "- Source artifact:")"
fi
if [[ -z "$artifact_link" ]]; then
  artifact_link="[paste next-move artifact link]"
fi

checklist_target="$(extract_prefixed_value "$next_move_handoff_path" "Checklist target:")"
if [[ -z "$checklist_target" ]]; then
  checklist_target="$(extract_prefixed_value "$next_move_handoff_path" "- Checklist target:")"
fi
if [[ -z "$checklist_target" ]]; then
  checklist_target="Monday Publish Checklist <week>"
fi
checklist_target="${checklist_target//<week>/$week_label}"

owner_update="$(extract_prefixed_value "$next_move_handoff_path" "Owner update:")"
if [[ -z "$owner_update" ]]; then
  owner_update="Owner: <name> - shared update pending."
fi

x_draft="$(extract_prefixed_value "$next_move_handoff_path" "X draft (<=280):")"
if [[ -z "$x_draft" ]]; then
  x_draft="$(clamp_line "Week ${week_label}: ran ${action_label}. Top founder action is live and logged in ${checklist_target}. Reply 'playbook' for the exact loop." 280)"
fi

linkedin_draft="$(extract_prefixed_value "$next_move_handoff_path" "LinkedIn draft:")"
if [[ -z "$linkedin_draft" ]]; then
  linkedin_draft="$(compact_line "Founder ops update (${week_label}): we ran ${action_label}, logged the artifact in ${checklist_target}, and assigned the next owner action for the next distribution loop.")"
fi

checklist_comment_draft="$(extract_prefixed_value "$next_move_handoff_path" "Checklist comment draft:")"
if [[ -z "$checklist_comment_draft" ]]; then
  checklist_comment_draft="$(compact_line "Artifact link: ${artifact_link} | Owner update: ${owner_update}")"
fi

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-next-move-draft-pack -->
# Founder Fame Next Move Draft Pack - ${week_label}

Source handoff: ${next_move_handoff_path}
Source artifact: ${artifact_link}

## Draft Pack

X:
${x_draft}

LinkedIn:
${linkedin_draft}

Checklist:
${checklist_comment_draft}

## Operator Notes

- Paste these three blocks directly into your publishing and checklist tools.
- Refresh this draft pack whenever the selected command, artifact link, or owner update changes.
EOF

echo "Generated founder fame next-move draft pack: $output_path"
