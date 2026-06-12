#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Upsert a founder fame exceptional-loop comment into Monday Publish Checklist issue.

Usage:
  zsh scripts/post_founder_fame_exceptional_loop_comment.sh [options]

Options:
  --exceptional-loop <path>   Founder fame exceptional-loop markdown artifact
  --action-queue <path>       Optional founder fame action-queue artifact for mission freshness context
  --week <label>              Week label override (default: inferred from exceptional-loop heading)
  --repo <owner/repo>         Repository slug (default: inferred from git remote or env)
  --issue <number>            Monday checklist issue number (default: auto-detect by week title)
  --dry-run                   Do not call GitHub API; only render comment body
  --out <path>                Write rendered comment markdown (default: .build/founder/founder-fame-exceptional-loop-comment-<week>.md)
  --sample                    Use built-in sample exceptional-loop input
  -h, --help                  Show help

Examples:
  zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
    --exceptional-loop docs/campaigns/2026-W24-founder-fame-exceptional-loop.md \
    --dry-run

  zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
    --exceptional-loop docs/campaigns/2026-W24-founder-fame-exceptional-loop.md \
    --repo your-org/your-repo \
    --issue 123
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

exceptional_loop_path=""
action_queue_path=""
week_label=""
repo_slug=""
issue_number=""
dry_run=0
output_path=""
sample_mode=0
sample_path=""

while (( $# > 0 )); do
  case "$1" in
    --exceptional-loop)
      exceptional_loop_path="${2:-}"
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
  heading="$(rg -m1 '^# Founder Fame Exceptional Loop - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo ""
    return
  fi
  trim_value "${heading#"# Founder Fame Exceptional Loop - "}"
}

extract_marker_payload_block() {
  local source_path="$1"
  if [[ -z "$source_path" || ! -f "$source_path" ]]; then
    echo ""
    return
  fi

  awk '
    /^## Operator Marker Block$/ { in_section = 1; next }
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

  body_file="${TMPDIR:-/tmp}/founder-fame-exceptional-loop-comment.${$}.${RANDOM}.md"
  payload_file="${TMPDIR:-/tmp}/founder-fame-exceptional-loop-comment.${$}.${RANDOM}.json"
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

cleanup() {
  if [[ -n "$sample_path" && -f "$sample_path" ]]; then
    rm -f "$sample_path"
  fi
}
trap cleanup EXIT

if (( sample_mode == 1 )); then
  sample_path="${TMPDIR:-/tmp}/founder-fame-exceptional-loop-comment-sample.${$}.${RANDOM}.md"
  cat > "$sample_path" <<'EOF'
<!-- founder-fame-exceptional-loop -->

# Founder Fame Exceptional Loop - 2099-W01

## Signal Snapshot

- Latest score: 88.0
- Window velocity (4 runs): +22.0
- Route mode: Accelerate
- Exceptional readiness: Momentum Building

## Public Narrative Hooks

- Checklist update seed: Route mode: Accelerate | Readiness: Momentum Building | Latest score: 88.0 | Velocity(4): +22.0

## Operator Marker Block

```text
weekly-growth-founder-fame-exceptional-loop
week: 2099-W01
route_mode: Accelerate
readiness: Momentum Building
latest_score: 88.0
window_average: 82.0
window_velocity: +22.0
momentum_streak: 2
elite_streak: 1
```
EOF
  exceptional_loop_path="$sample_path"
fi

if [[ -z "$exceptional_loop_path" ]]; then
  echo "Missing required option: --exceptional-loop" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "$exceptional_loop_path" ]]; then
  echo "Exceptional loop file not found: $exceptional_loop_path" >&2
  exit 1
fi

if [[ -n "$action_queue_path" && ! -f "$action_queue_path" ]]; then
  echo "Action queue file not found: $action_queue_path" >&2
  exit 1
fi

if [[ -z "$week_label" ]]; then
  week_label="$(extract_week_from_heading "$exceptional_loop_path")"
fi
if [[ -z "$week_label" ]]; then
  week_label="$(date '+%Y-W%V')"
fi

if [[ -z "$output_path" ]]; then
  output_path=".build/founder/founder-fame-exceptional-loop-comment-${week_label}.md"
fi

route_mode="$(extract_prefixed_value "$exceptional_loop_path" "- Route mode: ")"
readiness="$(extract_prefixed_value "$exceptional_loop_path" "- Exceptional readiness: ")"
latest_score="$(extract_prefixed_value "$exceptional_loop_path" "- Latest score: ")"
checklist_seed="$(extract_prefixed_value "$exceptional_loop_path" "- Checklist update seed: ")"
window_velocity_line="$(rg -m1 '^- Window velocity ' "$exceptional_loop_path" || true)"
window_velocity="n/a"
if [[ -n "$window_velocity_line" ]]; then
  window_velocity="$(trim_value "${window_velocity_line#*:}")"
fi
marker_payload="$(extract_marker_payload_block "$exceptional_loop_path")"
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

if [[ -z "$route_mode" || -z "$readiness" || -z "$latest_score" ]]; then
  echo "Exceptional loop is missing required signal snapshot fields (route/readiness/score)." >&2
  exit 1
fi

if [[ -z "$marker_payload" ]] || ! print -r -- "$marker_payload" | rg -Fq "weekly-growth-founder-fame-exceptional-loop"; then
  echo "Exceptional loop is missing operator marker payload block." >&2
  exit 1
fi

if [[ -z "$checklist_seed" ]]; then
  checklist_seed="Route mode: ${route_mode} | Readiness: ${readiness} | Latest score: ${latest_score} | Velocity: ${window_velocity}"
fi

marker="<!-- weekly-growth-founder-fame-exceptional-loop-comment -->"
generated_at="$(date '+%Y-%m-%d %H:%M:%S %z')"

comment_body="${marker}
## Founder Fame Exceptional Loop Update (${week_label})

- Route mode: ${route_mode}
- Exceptional readiness: ${readiness}
- Latest score: ${latest_score}
- Window velocity: ${window_velocity}
- Daily mission source: ${mission_source}
- Daily mission freshness: ${mission_freshness}
- Mission freshness guardrail: ${mission_guardrail}
- Generated: ${generated_at}

### Checklist Draft

${checklist_seed}

### Marker Payload

\`\`\`text
${marker_payload}
\`\`\`"

mkdir -p "$(dirname "$output_path")"
print -r -- "$comment_body" > "$output_path"
echo "Wrote founder fame exceptional-loop comment draft: $output_path"

if (( dry_run == 1 )); then
  echo "Dry run enabled; skipping GitHub issue upsert."
  exit 0
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required for live issue upsert. Use --dry-run to only render comment draft." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for live issue upsert. Use --dry-run to only render comment draft." >&2
  exit 1
fi

if [[ -z "$repo_slug" ]]; then
  repo_slug="$(detect_repo_slug)"
fi
if [[ -z "$repo_slug" ]]; then
  echo "Could not infer repository slug. Provide --repo <owner/repo>." >&2
  exit 1
fi

if [[ -z "$issue_number" ]]; then
  issue_number="$(resolve_checklist_issue_number "$repo_slug" "$week_label")"
fi
if [[ -z "$issue_number" ]]; then
  echo "Could not locate Monday Publish Checklist ${week_label}. Provide --issue <number>." >&2
  exit 1
fi

upsert_result="$(upsert_issue_comment "$repo_slug" "$issue_number" "$marker" "$comment_body")"
echo "Upserted founder fame exceptional-loop comment: ${upsert_result} (repo: ${repo_slug}, issue: ${issue_number})"
