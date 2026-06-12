#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a checklist-ready founder fame next-move handoff block.

Usage:
  zsh scripts/generate_founder_fame_next_move_handoff.sh [options]

Required:
  --command-center <path>      Founder fame command center markdown

Optional:
  --week <label>               Week label (default: current ISO week)
  --move-title <text>          In-app move label (default: Run Fame Next Move)
  --artifact-link <text>       Source artifact link/path (default: command center path)
  --checklist-target <text>    Checklist destination (default: Monday Publish Checklist <week>)
  --owner-update <text>        Owner update placeholder line
  --x-draft <text>             X draft override (<=280 chars)
  --linkedin-draft <text>      LinkedIn draft override
  --checklist-comment-draft <text> Checklist comment draft override
  --draft-pack-out <path>      Also generate a standalone draft-pack markdown
  --out <path>                 Output path (default: docs/campaigns/<week>-founder-fame-next-move-handoff.md)
  -h, --help                   Show help

Example:
  zsh scripts/generate_founder_fame_next_move_handoff.sh \
    --week 2026-W24 \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --out docs/campaigns/2026-W24-founder-fame-next-move-handoff.md
EOF
}

command_center_path=""
week_label="$(date '+%Y-W%V')"
move_title="Run Fame Next Move"
artifact_link=""
checklist_target="Monday Publish Checklist <week>"
owner_update_placeholder="Owner: <name> - shared update pending."
x_draft_override=""
linkedin_draft_override=""
checklist_comment_draft_override=""
draft_pack_output_path=""
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --command-center)
      command_center_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --move-title)
      move_title="${2:-}"
      shift 2
      ;;
    --artifact-link)
      artifact_link="${2:-}"
      shift 2
      ;;
    --checklist-target)
      checklist_target="${2:-}"
      shift 2
      ;;
    --owner-update)
      owner_update_placeholder="${2:-}"
      shift 2
      ;;
    --x-draft)
      x_draft_override="${2:-}"
      shift 2
      ;;
    --linkedin-draft)
      linkedin_draft_override="${2:-}"
      shift 2
      ;;
    --checklist-comment-draft)
      checklist_comment_draft_override="${2:-}"
      shift 2
      ;;
    --draft-pack-out)
      draft_pack_output_path="${2:-}"
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

if [[ -z "$command_center_path" ]]; then
  echo "Missing required option: --command-center" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$command_center_path" ]]; then
  echo "Required source file not found: $command_center_path" >&2
  exit 1
fi

if [[ -z "$artifact_link" ]]; then
  artifact_link="$command_center_path"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-next-move-handoff.md"
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

resolved_checklist_target="${checklist_target//<week>/$week_label}"
today_stamp="$(date '+%Y-%m-%d')"

x_draft="$(compact_line "$x_draft_override")"
if [[ -z "$x_draft" ]]; then
  x_draft="$(clamp_line "Week ${week_label}: ran ${move_title}. Top founder action is live and logged in ${resolved_checklist_target}. Reply 'playbook' for the exact loop." 280)"
fi

linkedin_draft="$(compact_line "$linkedin_draft_override")"
if [[ -z "$linkedin_draft" ]]; then
  linkedin_draft="$(compact_line "Founder ops update (${week_label}): we ran ${move_title}, logged the artifact in ${resolved_checklist_target}, and assigned the next owner action for the next distribution loop.")"
fi

checklist_comment_draft="$(compact_line "$checklist_comment_draft_override")"
if [[ -z "$checklist_comment_draft" ]]; then
  checklist_comment_draft="$(compact_line "Artifact link: ${artifact_link} | Owner update: ${owner_update_placeholder}")"
fi

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-next-move-handoff -->
# Founder Fame Next Move Handoff - ${week_label}

Date: ${today_stamp}
Action: Run Fame Next Move
Selected command: ${move_title}
Artifact link: ${artifact_link}
Checklist target: ${checklist_target}
Owner update: ${owner_update_placeholder}
X draft (<=280): ${x_draft}
LinkedIn draft: ${linkedin_draft}
Checklist comment draft: ${checklist_comment_draft}

## Action

- In-app move: ${move_title}
- Checklist target: ${checklist_target}
- Source artifact: ${artifact_link}

## Checklist Comment Draft

Founder fame next move handoff (${week_label})
Action: ${move_title}
Artifact link: ${artifact_link}
${owner_update_placeholder}

## Operator Notes

- Run this move immediately after command-center standup.
- Post artifact link plus owner update in the checklist comment.
- Re-run and repost whenever pulse risk or owner assignment changes.
EOF

if [[ -n "$draft_pack_output_path" ]]; then
  zsh scripts/generate_founder_fame_next_move_draft_pack.sh \
    --week "$week_label" \
    --next-move-handoff "$output_path" \
    --out "$draft_pack_output_path" >/dev/null
fi

echo "Generated founder fame next-move handoff: $output_path"
if [[ -n "$draft_pack_output_path" ]]; then
  echo "Generated founder fame next-move draft pack: $draft_pack_output_path"
fi
