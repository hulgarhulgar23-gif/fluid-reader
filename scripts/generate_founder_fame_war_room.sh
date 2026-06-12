#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Generate a founder fame war-room briefing from command-center + next-move artifacts.

Usage:
  zsh scripts/generate_founder_fame_war_room.sh [options]

Required:
  --command-center <path>        Founder fame command center markdown
  --next-move-handoff <path>     Founder fame next-move handoff markdown
  --next-move-draft-pack <path>  Founder fame next-move draft-pack markdown

Optional:
  --proof-loop-check <path>      Founder fame proof-loop verification markdown
  --narrative-lab <path>         Founder fame narrative lab markdown
  --week <label>                 Week label (default: inferred from command center, then handoff, then current ISO week)
  --product <text>               Product name (default: Fluid Reader)
  --out <path>                   Output path (default: docs/campaigns/<week>-founder-fame-war-room.md)
  -h, --help                     Show help

Example:
  zsh scripts/generate_founder_fame_war_room.sh \
    --command-center docs/campaigns/2026-W24-founder-fame-command-center.md \
    --next-move-handoff docs/campaigns/2026-W24-founder-fame-next-move-handoff.md \
    --next-move-draft-pack docs/campaigns/2026-W24-founder-fame-next-move-draft-pack.md \
    --proof-loop-check docs/campaigns/2026-W24-founder-fame-proof-loop-check.md \
    --narrative-lab docs/campaigns/2026-W24-founder-fame-narrative-lab.md \
    --out docs/campaigns/2026-W24-founder-fame-war-room.md
EOF
}

command_center_path=""
next_move_handoff_path=""
next_move_draft_pack_path=""
proof_loop_check_path=""
narrative_lab_path=""
week_label=""
product_name="Fluid Reader"
output_path=""

while (( $# > 0 )); do
  case "$1" in
    --command-center)
      command_center_path="${2:-}"
      shift 2
      ;;
    --next-move-handoff)
      next_move_handoff_path="${2:-}"
      shift 2
      ;;
    --next-move-draft-pack)
      next_move_draft_pack_path="${2:-}"
      shift 2
      ;;
    --proof-loop-check)
      proof_loop_check_path="${2:-}"
      shift 2
      ;;
    --narrative-lab)
      narrative_lab_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --product)
      product_name="${2:-}"
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

for required_pair in \
  "command-center:$command_center_path" \
  "next-move-handoff:$next_move_handoff_path" \
  "next-move-draft-pack:$next_move_draft_pack_path"; do
  required_name="${required_pair%%:*}"
  required_value="${required_pair#*:}"
  if [[ -z "$required_value" ]]; then
    echo "Missing required option: --${required_name}" >&2
    usage >&2
    exit 1
  fi
  if [[ ! -f "$required_value" ]]; then
    echo "Required source file not found: $required_value" >&2
    exit 1
  fi
done

for optional_pair in \
  "proof-loop-check:$proof_loop_check_path" \
  "narrative-lab:$narrative_lab_path"; do
  optional_value="${optional_pair#*:}"
  if [[ -n "$optional_value" && ! -f "$optional_value" ]]; then
    echo "Optional source file not found: $optional_value" >&2
    exit 1
  fi
done

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

sanitize_inline() {
  local value="$1"
  value="$(compact_line "$value")"
  value="${value//|//}"
  value="${value//\`/}"
  value="$(compact_line "$value")"
  echo "$value"
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
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  local line
  line="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi

  trim_value "${line#"$prefix"}"
}

extract_heading() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo "n/a"
    return
  fi

  local heading
  heading="$(rg -m1 '^# ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo "n/a"
    return
  fi
  echo "${heading#\# }"
}

extract_week_from_heading_prefix() {
  local source_path="$1"
  local prefix="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  local heading
  heading="$(rg -m1 -F -- "$prefix" "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"$prefix"}"
}

extract_labeled_block() {
  local source_path="$1"
  local label="$2"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk -v label="$label" '
    $0 == label { in_block = 1; next }
    in_block {
      if ($0 ~ /^## /) exit
      if ($0 == "X:" || $0 == "LinkedIn:" || $0 == "Checklist:") exit
      if ($0 == "" && seen_content == 0) next
      if ($0 != "") seen_content = 1
      print $0
    }
  ' "$source_path" | awk 'NF {print; found=1; exit} END {if (!found) print ""}'
}

default_if_blank() {
  local value="$1"
  local fallback="$2"
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$fallback"
  fi
}

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$command_center_path" "# Founder Fame Command Center - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading_prefix "$next_move_handoff_path" "# Founder Fame Next Move Handoff - ")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path="docs/campaigns/${week_label}-founder-fame-war-room.md"
fi

selected_command="$(extract_prefixed_value "$next_move_handoff_path" "Selected command: ")"
if [[ -z "$selected_command" ]]; then
  selected_command="$(extract_prefixed_value "$next_move_handoff_path" "- In-app move: ")"
fi
if [[ -z "$selected_command" ]]; then
  selected_command="$(extract_prefixed_value "$next_move_handoff_path" "Action: ")"
fi
selected_command="$(default_if_blank "$selected_command" "Run Fame Next Move")"

artifact_link="$(extract_prefixed_value "$next_move_handoff_path" "Artifact link: ")"
if [[ -z "$artifact_link" ]]; then
  artifact_link="$(extract_prefixed_value "$next_move_handoff_path" "- Source artifact: ")"
fi
artifact_link="$(default_if_blank "$artifact_link" "[paste next-move artifact link]")"

checklist_target="$(extract_prefixed_value "$next_move_handoff_path" "Checklist target: ")"
if [[ -z "$checklist_target" ]]; then
  checklist_target="$(extract_prefixed_value "$next_move_handoff_path" "- Checklist target: ")"
fi
checklist_target="$(default_if_blank "$checklist_target" "Monday Publish Checklist <week>")"
checklist_target="${checklist_target//<week>/$week_label}"

owner_update="$(extract_prefixed_value "$next_move_handoff_path" "Owner update: ")"
if [[ -z "$owner_update" ]]; then
  owner_update="Owner: <name> - shared update pending."
fi

x_draft="$(extract_prefixed_value "$next_move_handoff_path" "X draft (<=280): ")"
if [[ -z "$x_draft" ]]; then
  x_draft="$(extract_labeled_block "$next_move_draft_pack_path" "X:")"
fi
if [[ -z "$x_draft" ]]; then
  x_draft="$(clamp_line "Week ${week_label}: ran ${selected_command}. Top founder action is live and logged in ${checklist_target}. Reply 'playbook' for the exact loop." 280)"
fi

linkedin_draft="$(extract_prefixed_value "$next_move_handoff_path" "LinkedIn draft: ")"
if [[ -z "$linkedin_draft" ]]; then
  linkedin_draft="$(extract_labeled_block "$next_move_draft_pack_path" "LinkedIn:")"
fi
if [[ -z "$linkedin_draft" ]]; then
  linkedin_draft="Founder ops update (${week_label}): we ran ${selected_command}, logged the artifact in ${checklist_target}, and assigned the next owner action."
fi

checklist_comment_draft="$(extract_prefixed_value "$next_move_handoff_path" "Checklist comment draft: ")"
if [[ -z "$checklist_comment_draft" ]]; then
  checklist_comment_draft="$(extract_labeled_block "$next_move_draft_pack_path" "Checklist:")"
fi
if [[ -z "$checklist_comment_draft" ]]; then
  checklist_comment_draft="Artifact link: ${artifact_link} | Owner update: ${owner_update}"
fi

top_bet="$(extract_prefixed_value "$command_center_path" "- Top bet: ")"
execution_readiness="$(extract_prefixed_value "$command_center_path" "- Execution readiness: ")"
queue_pressure="$(extract_prefixed_value "$command_center_path" "- Queue pressure: ")"
primary_risk_call="$(extract_prefixed_value "$command_center_path" "- Primary risk call: ")"
routing_recommendation="$(extract_prefixed_value "$command_center_path" "- Routing recommendation: ")"
route_alignment_signal="$(extract_prefixed_value "$command_center_path" "- Route alignment signal: ")"

proof_status="$(extract_prefixed_value "$proof_loop_check_path" "- Status: ")"
proof_mode="$(extract_prefixed_value "$proof_loop_check_path" "- Mode: ")"
route_response_mode="$(extract_prefixed_value "$narrative_lab_path" "- Route response mode: ")"
priority_route="$(extract_prefixed_value "$narrative_lab_path" "- Priority route: ")"

top_bet="$(default_if_blank "$top_bet" "n/a")"
execution_readiness="$(default_if_blank "$execution_readiness" "n/a")"
queue_pressure="$(default_if_blank "$queue_pressure" "n/a")"
primary_risk_call="$(default_if_blank "$primary_risk_call" "n/a")"
routing_recommendation="$(default_if_blank "$routing_recommendation" "n/a")"
route_alignment_signal="$(default_if_blank "$route_alignment_signal" "n/a")"
proof_status="$(default_if_blank "$proof_status" "n/a")"
proof_mode="$(default_if_blank "$proof_mode" "n/a")"
route_response_mode="$(default_if_blank "$route_response_mode" "n/a")"
priority_route="$(default_if_blank "$priority_route" "n/a")"

command_center_heading="$(extract_heading "$command_center_path")"
handoff_heading="$(extract_heading "$next_move_handoff_path")"
draft_pack_heading="$(extract_heading "$next_move_draft_pack_path")"
proof_loop_heading="$(extract_heading "$proof_loop_check_path")"
narrative_lab_heading="$(extract_heading "$narrative_lab_path")"

generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

mkdir -p "$(dirname "$output_path")"

cat > "$output_path" <<EOF
<!-- founder-fame-war-room -->

# Founder Fame War Room - ${week_label}

Generated: ${generated_at}
Product: ${product_name}
Source command center: ${command_center_path}
Source next-move handoff: ${next_move_handoff_path}
Source next-move draft pack: ${next_move_draft_pack_path}
Source proof-loop check: ${proof_loop_check_path:-n/a}
Source narrative lab: ${narrative_lab_path:-n/a}

## Snapshot

- Command center: ${command_center_heading}
- Next-move handoff: ${handoff_heading}
- Next-move draft pack: ${draft_pack_heading}
- Proof-loop check: ${proof_loop_heading}
- Narrative lab: ${narrative_lab_heading}
- Top bet: ${top_bet}
- Execution readiness: ${execution_readiness}
- Queue pressure: ${queue_pressure}
- Route alignment signal: ${route_alignment_signal}
- Route response mode: ${route_response_mode}
- Priority route: ${priority_route}
- Proof-loop verification: ${proof_status} (${proof_mode})

## Launch Control

- Run now: ${selected_command}
- Artifact link: ${artifact_link}
- Checklist target: ${checklist_target}
- Owner update: ${owner_update}
- Primary risk call: ${primary_risk_call}
- Routing recommendation: ${routing_recommendation}

## Draft Pack

X:
${x_draft}

LinkedIn:
${linkedin_draft}

Checklist:
${checklist_comment_draft}

## 90-Minute Execution Sprint

| Minute | Focus | Output |
| --- | --- | --- |
| 0-15 | Standup route lock | Confirm top bet (${top_bet}) + route signal (${route_alignment_signal}) with owner. |
| 15-40 | Run in-app next move | Execute ${selected_command} and capture artifact at ${artifact_link}. |
| 40-65 | Publish draft pack | Post X + LinkedIn drafts and log checklist update in ${checklist_target}. |
| 65-90 | Close proof loop | Verify status (${proof_status}) and schedule the next route checkpoint (${route_response_mode}). |

## Checklist Marker Block

\`\`\`text
weekly-growth-founder-fame-war-room
week: ${week_label}
selected_command: $(sanitize_inline "$selected_command")
artifact_link: $(sanitize_inline "$artifact_link")
checklist_target: $(sanitize_inline "$checklist_target")
proof_status: $(sanitize_inline "$proof_status")
route_signal: $(sanitize_inline "$route_alignment_signal")
\`\`\`
EOF

echo "Generated founder fame war room: $output_path"
