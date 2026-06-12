#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Upsert a founder fame war-room comment into Monday Publish Checklist issue.

Usage:
  zsh scripts/post_founder_fame_war_room_comment.sh [options]

Options:
  --war-room <path>           Founder fame war-room markdown artifact
  --action-queue <path>       Optional founder fame action-queue artifact for mission freshness context
  --week <label>              Week label override (default: inferred from war-room heading)
  --repo <owner/repo>         Repository slug (default: inferred from git remote or env)
  --issue <number>            Monday checklist issue number (default: auto-detect by week title)
  --strict                    Verify war-room with strict checks before posting
  --dry-run                   Do not call GitHub API; only render comment body
  --out <path>                Write rendered comment markdown (default: .build/founder/founder-fame-war-room-comment-<week>.md)
  --sample                    Use built-in sample war-room input
  -h, --help                  Show help

Examples:
  zsh scripts/post_founder_fame_war_room_comment.sh \
    --war-room docs/campaigns/2026-W24-founder-fame-war-room.md \
    --strict

  zsh scripts/post_founder_fame_war_room_comment.sh \
    --war-room docs/campaigns/2026-W24-founder-fame-war-room.md \
    --repo your-org/your-repo \
    --issue 123 \
    --strict

  zsh scripts/post_founder_fame_war_room_comment.sh \
    --sample \
    --dry-run
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

war_room_path=""
action_queue_path=""
week_label=""
repo_slug=""
issue_number=""
strict_mode=0
dry_run=0
output_path=""
sample_mode=0
sample_path=""

while (( $# > 0 )); do
  case "$1" in
    --war-room)
      war_room_path="${2:-}"
      shift 2
      ;;
    --action-queue)
      action_queue_path="${2:-}"
      shift 2
      ;;
    --week)
      week_label="${2:-}"
      shift 2
      ;;
    --repo)
      repo_slug="${2:-}"
      shift 2
      ;;
    --issue)
      issue_number="${2:-}"
      shift 2
      ;;
    --strict)
      strict_mode=1
      shift
      ;;
    --dry-run)
      dry_run=1
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

compact_line() {
  local value="$1"
  value="${value//$'\n'/ }"
  value="${value//$'\r'/ }"
  while [[ "$value" == *"  "* ]]; do
    value="${value//  / }"
  done
  trim_value "$value"
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

extract_week_from_heading() {
  local source_path="$1"
  local heading
  heading="$(rg -m1 '^# Founder Fame War Room - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame War Room - "}"
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

extract_marker_payload_block() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk '
    /^## Checklist Marker Block$/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section && /^```/ {
      if (in_fence == 0) {
        in_fence = 1
        next
      } else {
        exit
      }
    }
    in_section && in_fence { print }
  ' "$source_path"
}

detect_repo_slug() {
  local origin_url
  origin_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$origin_url" ]]; then
    if [[ "$origin_url" == git@github.com:* ]]; then
      local value="${origin_url#git@github.com:}"
      echo "${value%.git}"
      return
    fi

    if [[ "$origin_url" == https://github.com/* ]]; then
      local value="${origin_url#https://github.com/}"
      echo "${value%.git}"
      return
    fi
  fi

  if [[ -n "${GITHUB_REPOSITORY:-}" && "${GITHUB_REPOSITORY}" == */* ]]; then
    echo "${GITHUB_REPOSITORY}"
    return
  fi

  if [[ -n "${GH_REPO:-}" && "${GH_REPO}" == */* ]]; then
    echo "${GH_REPO}"
    return
  fi

  if command -v gh >/dev/null 2>&1; then
    local gh_repo
    gh_repo="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)"
    if [[ -n "$gh_repo" && "$gh_repo" == */* ]]; then
      echo "$gh_repo"
      return
    fi
  fi

  echo ""
}

resolve_checklist_issue_number() {
  local repo="$1"
  local week="$2"
  if [[ -z "$repo" || -z "$week" ]]; then
    echo ""
    return
  fi

  local issues_json exact_number contains_number
  issues_json="$(gh issue list \
    --repo "$repo" \
    --state open \
    --search "\"Monday Publish Checklist ${week}\" in:title" \
    --json number,title,updatedAt \
    2>/dev/null || true)"
  if [[ -z "$issues_json" ]]; then
    issues_json="[]"
  fi

  exact_number="$(print -r -- "$issues_json" | jq -r --arg week "$week" '
    [ .[]
      | select((.title // "") == ("Monday Publish Checklist " + $week))
      | .number
    ] | first // empty
  ')"
  if [[ -n "$exact_number" ]]; then
    echo "$exact_number"
    return
  fi

  contains_number="$(print -r -- "$issues_json" | jq -r --arg week "$week" '
    [ .[]
      | select((.title // "") | test("Monday Publish Checklist\\s+" + $week))
      | .number
    ] | first // empty
  ')"
  echo "$contains_number"
}

upsert_issue_comment() {
  local repo="$1"
  local issue="$2"
  local marker="$3"
  local body="$4"

  local comments_json existing_comment_id body_file payload_file
  comments_json="$(gh api "repos/${repo}/issues/${issue}/comments?per_page=100" 2>/dev/null || true)"
  if [[ -z "$comments_json" ]]; then
    comments_json="[]"
  fi
  existing_comment_id="$(print -r -- "$comments_json" | jq -r --arg marker "$marker" '
    [ .[]
      | select((.body // "") | contains($marker))
      | .id
    ] | first // empty
  ')"

  body_file="${TMPDIR:-/tmp}/founder-fame-war-room-comment.${$}.${RANDOM}.md"
  payload_file="${TMPDIR:-/tmp}/founder-fame-war-room-comment.${$}.${RANDOM}.json"
  print -r -- "$body" > "$body_file"
  jq -n --arg body "$body" '{body: $body}' > "$payload_file"

  if [[ -n "$existing_comment_id" ]]; then
    gh api \
      --method PATCH \
      "repos/${repo}/issues/comments/${existing_comment_id}" \
      --input "$payload_file" >/dev/null
    rm -f "$body_file" "$payload_file"
    echo "updated:${existing_comment_id}"
    return
  fi

  gh issue comment "$issue" --repo "$repo" --body-file "$body_file" >/dev/null
  rm -f "$body_file" "$payload_file"
  echo "created:new"
}

if (( sample_mode == 1 )); then
  sample_path="${TMPDIR:-/tmp}/founder-fame-war-room-comment-sample.${$}.${RANDOM}.md"
  cat > "$sample_path" <<'EOF'
<!-- founder-fame-war-room -->

# Founder Fame War Room - 2099-W01

## Launch Control

- Run now: Run Fame Next Move
- Artifact link: docs/campaigns/2099-W01-founder-fame-next-move-handoff.md
- Checklist target: Monday Publish Checklist 2099-W01
- Owner update: Owner: Growth lead - shipped update posted.
- Primary risk call: Momentum dips when follow-up lags.
- Routing recommendation: Keep one proof narrative and close one blocker per cycle.

## Draft Pack

Checklist:
Artifact link: docs/campaigns/2099-W01-founder-fame-next-move-handoff.md | Owner update: Owner: Growth lead - shipped update posted.

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

if [[ -n "$action_queue_path" && ! -f "$action_queue_path" ]]; then
  echo "Action queue file not found: $action_queue_path" >&2
  exit 1
fi

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading "$war_room_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path=".build/founder/founder-fame-war-room-comment-${week_label}.md"
fi

if (( strict_mode == 1 )); then
  zsh scripts/verify_founder_fame_war_room.sh --war-room "$war_room_path" --strict >/dev/null
fi

run_now="$(extract_prefixed_value "$war_room_path" "- Run now: ")"
artifact_link="$(extract_prefixed_value "$war_room_path" "- Artifact link: ")"
checklist_target="$(extract_prefixed_value "$war_room_path" "- Checklist target: ")"
owner_update="$(extract_prefixed_value "$war_room_path" "- Owner update: ")"
proof_status="$(extract_prefixed_value "$war_room_path" "- Proof-loop verification: ")"
route_signal="$(extract_prefixed_value "$war_room_path" "- Route alignment signal: ")"
routing_recommendation="$(extract_prefixed_value "$war_room_path" "- Routing recommendation: ")"
checklist_draft="$(extract_labeled_block "$war_room_path" "Checklist:")"
marker_payload="$(extract_marker_payload_block "$war_room_path")"
mission_source="n/a (action queue not provided)"
mission_freshness="n/a (action queue not provided)"
mission_guardrail="n/a"
if [[ -n "$action_queue_path" ]]; then
  mission_source="$(extract_prefixed_value "$action_queue_path" "- Daily mission source: ")"
  mission_freshness="$(extract_prefixed_value "$action_queue_path" "- Mission freshness: ")"
  mission_guardrail="$(extract_prefixed_value "$action_queue_path" "- Freshness guardrail: ")"
  [[ -z "$mission_source" ]] && mission_source="n/a (missing Daily mission source in action queue)"
  [[ -z "$mission_freshness" ]] && mission_freshness="n/a (missing Mission freshness in action queue)"
  [[ -z "$mission_guardrail" ]] && mission_guardrail="n/a (missing Freshness guardrail in action queue)"
fi

if [[ -z "$run_now" || -z "$artifact_link" || -z "$checklist_target" ]]; then
  echo "War room is missing required launch-control fields (run/artifact/checklist)." >&2
  exit 1
fi

if [[ -z "$marker_payload" ]] || ! print -r -- "$marker_payload" | rg -Fq "weekly-growth-founder-fame-war-room"; then
  echo "War room is missing checklist marker payload block." >&2
  exit 1
fi

if [[ -z "$checklist_draft" ]]; then
  checklist_draft="Artifact link: ${artifact_link} | Owner update: ${owner_update}"
fi

marker="<!-- weekly-growth-founder-fame-war-room-comment -->"
generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

comment_body="${marker}
## Founder Fame War Room Update (${week_label})

- Run now: ${run_now}
- Artifact link: ${artifact_link}
- Checklist target: ${checklist_target}
- Owner update: ${owner_update}
- Proof status: ${proof_status}
- Route signal: ${route_signal}
- Routing recommendation: ${routing_recommendation}
- Daily mission source: ${mission_source}
- Daily mission freshness: ${mission_freshness}
- Mission freshness guardrail: ${mission_guardrail}
- Generated: ${generated_at}

### Checklist Draft

${checklist_draft}

### Marker Payload

\`\`\`text
${marker_payload}
\`\`\`"

mkdir -p "$(dirname "$output_path")"
print -r -- "$comment_body" > "$output_path"
echo "Wrote founder fame war-room comment draft: $output_path"

if (( dry_run == 1 )); then
  echo "Dry run enabled; skipping GitHub issue upsert."
  if [[ -n "$sample_path" && -f "$sample_path" ]]; then
    rm -f "$sample_path"
  fi
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required for live issue upsert. Use --dry-run to only render comment draft." >&2
  if [[ -n "$sample_path" && -f "$sample_path" ]]; then
    rm -f "$sample_path"
  fi
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for live issue upsert. Use --dry-run to only render comment draft." >&2
  if [[ -n "$sample_path" && -f "$sample_path" ]]; then
    rm -f "$sample_path"
  fi
  exit 1
fi

if [[ -z "$repo_slug" ]]; then
  repo_slug="$(detect_repo_slug)"
fi
if [[ -z "$repo_slug" ]]; then
  echo "Could not infer repository slug. Provide --repo <owner/repo>." >&2
  if [[ -n "$sample_path" && -f "$sample_path" ]]; then
    rm -f "$sample_path"
  fi
  exit 1
fi

if [[ -z "$issue_number" ]]; then
  issue_number="$(resolve_checklist_issue_number "$repo_slug" "$week_label")"
fi
if [[ -z "$issue_number" ]]; then
  echo "Could not locate Monday Publish Checklist ${week_label}. Provide --issue <number>." >&2
  if [[ -n "$sample_path" && -f "$sample_path" ]]; then
    rm -f "$sample_path"
  fi
  exit 1
fi

upsert_result="$(upsert_issue_comment "$repo_slug" "$issue_number" "$marker" "$comment_body")"
echo "Upserted founder fame war-room comment: ${upsert_result} (repo: ${repo_slug}, issue: ${issue_number})"

if [[ -n "$sample_path" && -f "$sample_path" ]]; then
  rm -f "$sample_path"
fi
