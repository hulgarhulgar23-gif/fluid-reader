#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify founder fame war-room checklist-comment sync from local artifacts or live workflow run.

Usage:
  zsh scripts/verify_founder_fame_war_room_run.sh [options]

Options:
  --run-id <number|latest>     GitHub Actions run ID to inspect (default: latest completed Founder Fame Pack run)
  --war-room <path>            Local founder fame war-room markdown artifact path
  --comment <path>             Local founder fame war-room checklist comment markdown artifact path
  --repo <owner/repo>          Repository slug for live issue/run checks (default: inferred from git remote/env)
  --issue <number>             Monday checklist issue number for live checklist comment checks
  --strict                     Require live checklist issue checks (fails if issue cannot be resolved)
  --out <path>                 Output markdown report path (default: .build/growth/<run-id>-founder-fame-war-room-live-check.md)
  --download-dir <path>        Artifact download directory for live mode
  --keep-download              Keep downloaded artifact directory
  --sample                     Run local sample verification without GitHub API calls
  -h, --help                   Show help

Examples:
  zsh scripts/verify_founder_fame_war_room_run.sh \
    --war-room docs/campaigns/2026-W24-founder-fame-war-room.md \
    --strict

  zsh scripts/verify_founder_fame_war_room_run.sh \
    --run-id 12345678901 \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_founder_fame_war_room_run.sh \
    --repo your-org/your-repo \
    --issue 123 \
    --strict

  zsh scripts/verify_founder_fame_war_room_run.sh --sample
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

run_id=""
war_room_path=""
comment_path=""
repo_slug=""
issue_number=""
output_path=""
download_dir=""
keep_download=0
sample_mode=0
strict_mode=0

while (( $# > 0 )); do
  case "$1" in
    --run-id)
      run_id="${2:-}"
      shift 2
      ;;
    --war-room)
      war_room_path="${2:-}"
      shift 2
      ;;
    --comment)
      comment_path="${2:-}"
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
    --out)
      output_path="${2:-}"
      shift 2
      ;;
    --download-dir)
      download_dir="${2:-}"
      shift 2
      ;;
    --keep-download)
      keep_download=1
      shift
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
  local value="${1:-}"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
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
    echo "n/a"
    return
  fi
  trim_value "${heading#"# Founder Fame War Room - "}"
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

resolve_latest_run_id() {
  local repo="$1"
  local latest_json latest_id

  latest_json="$(gh run list \
    --repo "$repo" \
    --workflow "founder-fame-pack.yml" \
    --status completed \
    --limit 1 \
    --json databaseId \
    2>/dev/null || true)"
  latest_id="$(print -r -- "$latest_json" | jq -r 'if (type == "array" and length > 0) then (.[0].databaseId // "") else "" end')"
  if [[ -n "$latest_id" ]]; then
    echo "$latest_id"
    return
  fi

  latest_json="$(gh run list \
    --repo "$repo" \
    --workflow "Founder Fame Pack" \
    --status completed \
    --limit 1 \
    --json databaseId \
    2>/dev/null || true)"
  latest_id="$(print -r -- "$latest_json" | jq -r 'if (type == "array" and length > 0) then (.[0].databaseId // "") else "" end')"
  echo "$latest_id"
}

resolve_checklist_issue_number() {
  local repo="$1"
  local week="$2"
  if [[ -z "$repo" || "$repo" == "n/a" || -z "$week" || "$week" == "n/a" ]]; then
    echo ""
    return
  fi

  local issues_json exact_number contains_number
  issues_json="$(gh issue list \
    --repo "$repo" \
    --state all \
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
      | select((.title // "") | contains("Monday Publish Checklist " + $week))
      | .number
    ] | first // empty
  ')"
  echo "$contains_number"
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

timestamp="$(date '+%Y%m%d-%H%M%S')"
mode="live"
run_id_source="provided"
issue_source="provided"
download_cleanup_path=""
auto_generated_expected_comment=0

if (( sample_mode == 1 )) && [[ -n "$war_room_path" || -n "$comment_path" ]]; then
  echo "--sample cannot be combined with --war-room or --comment." >&2
  exit 1
fi

if (( sample_mode == 1 )); then
  mode="sample"
  if [[ -z "$run_id" ]]; then
    run_id="sample-${timestamp}"
    run_id_source="sample-generated"
  else
    run_id_source="sample-provided"
  fi
else
  if [[ -n "$war_room_path" ]]; then
    mode="war-room"
    if [[ -z "$run_id" ]]; then
      run_id="local-${timestamp}"
      run_id_source="war-room-generated"
    else
      run_id_source="war-room-provided"
    fi
  else
    mode="live"
    if [[ "$run_id" == "latest" || -z "$run_id" ]]; then
      run_id=""
      run_id_source="latest"
    fi
  fi
fi

if [[ -z "$repo_slug" ]]; then
  repo_slug="$(detect_repo_slug)"
fi
if [[ -z "$repo_slug" ]]; then
  repo_slug="n/a"
fi

if [[ -n "$issue_number" && ! "$issue_number" =~ ^[0-9]+$ ]]; then
  echo "--issue must be numeric. Received: $issue_number" >&2
  exit 1
fi

if [[ "$mode" == "live" ]]; then
  if [[ "$repo_slug" == "n/a" ]]; then
    echo "Unable to infer --repo from git remote/env. Pass --repo <owner/repo>." >&2
    exit 1
  fi
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required for live mode." >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for live mode." >&2
    exit 1
  fi
fi

if (( strict_mode == 1 )) && [[ "$mode" == "sample" ]]; then
  strict_mode=0
fi

run_name="n/a"
run_event="n/a"
run_status="n/a"
run_conclusion="n/a"
run_url="n/a"

if [[ "$mode" == "sample" ]]; then
  mkdir -p ".build/growth"
  war_room_path=".build/growth/${run_id}-founder-fame-war-room-sample.md"
  comment_path=".build/growth/${run_id}-founder-fame-war-room-comment-sample.md"

  cat > "$war_room_path" <<'EOF'
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

  zsh scripts/post_founder_fame_war_room_comment.sh \
    --war-room "$war_room_path" \
    --strict \
    --dry-run \
    --out "$comment_path" >/dev/null

  issue_number="${issue_number:-123}"
  issue_source="sample"
elif [[ "$mode" == "live" ]]; then
  if [[ -z "$run_id" ]]; then
    run_id="$(resolve_latest_run_id "$repo_slug")"
    if [[ -z "$run_id" ]]; then
      echo "Could not resolve latest completed Founder Fame Pack run for repo ${repo_slug}." >&2
      exit 1
    fi
  fi
  if [[ ! "$run_id" =~ ^[0-9]+$ ]]; then
    echo "--run-id must be numeric or 'latest'. Received: $run_id" >&2
    exit 1
  fi

  if [[ -z "$download_dir" ]]; then
    download_dir=".build/growth/.tmp-founder-fame-war-room-live-${run_id}-${timestamp}"
  fi
  mkdir -p "$download_dir"
  download_cleanup_path="$download_dir"

  run_json="$(gh api "/repos/${repo_slug}/actions/runs/${run_id}")"
  run_name="$(print -r -- "$run_json" | jq -r '.name // "n/a"')"
  run_event="$(print -r -- "$run_json" | jq -r '.event // "n/a"')"
  run_status="$(print -r -- "$run_json" | jq -r '.status // "n/a"')"
  run_conclusion="$(print -r -- "$run_json" | jq -r '.conclusion // "n/a"')"
  run_url="$(print -r -- "$run_json" | jq -r '.html_url // "n/a"')"

  artifact_name="founder-fame-pack-${run_id}"
  gh run download "$run_id" \
    --repo "$repo_slug" \
    --name "$artifact_name" \
    --dir "$download_dir" >/dev/null

  if [[ -z "$war_room_path" ]]; then
    war_room_path="$(find "$download_dir" -type f -name '*founder-fame-war-room-*.md' ! -name '*founder-fame-war-room-check-*.md' ! -name '*founder-fame-war-room-comment-*.md' | head -n 1 || true)"
  fi
  if [[ -z "$comment_path" ]]; then
    comment_path="$(find "$download_dir" -type f -name '*founder-fame-war-room-comment-*.md' | head -n 1 || true)"
  fi
fi

if [[ -z "$war_room_path" || ! -f "$war_room_path" ]]; then
  echo "Founder fame war-room artifact not found. Provide --war-room <path> or use live mode with available artifact." >&2
  exit 1
fi

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/${run_id}-founder-fame-war-room-live-check.md"
fi
mkdir -p "$(dirname "$output_path")"

week_label="$(extract_week_from_heading "$war_room_path")"
run_now="$(extract_prefixed_value "$war_room_path" "- Run now: ")"
artifact_link="$(extract_prefixed_value "$war_room_path" "- Artifact link: ")"
checklist_target="$(extract_prefixed_value "$war_room_path" "- Checklist target: ")"
proof_status="$(extract_prefixed_value "$war_room_path" "- Proof-loop verification: ")"
route_signal="$(extract_prefixed_value "$war_room_path" "- Route alignment signal: ")"
marker_payload="$(extract_marker_payload_block "$war_room_path")"
marker_payload_line="$(print -r -- "$marker_payload" | awk 'NF {print; exit}' || true)"

record_check "War-room artifact exists" "true" "$war_room_path"

if [[ "$week_label" == "n/a" || -z "$week_label" ]]; then
  record_check "War-room week parsed" "false" "Could not parse '# Founder Fame War Room - <week>' heading."
else
  record_check "War-room week parsed" "true" "$week_label"
fi

missing_launch_fields=()
[[ -z "$run_now" ]] && missing_launch_fields+=("Run now")
[[ -z "$artifact_link" ]] && missing_launch_fields+=("Artifact link")
[[ -z "$checklist_target" ]] && missing_launch_fields+=("Checklist target")
if (( ${#missing_launch_fields[@]} == 0 )); then
  record_check "Launch-control fields present" "true" "run_now=${run_now}; artifact_link=${artifact_link}; checklist_target=${checklist_target}"
else
  record_check "Launch-control fields present" "false" "Missing: ${(j:, :)missing_launch_fields}"
fi

if [[ -n "$marker_payload" ]] && print -r -- "$marker_payload" | rg -Fq "weekly-growth-founder-fame-war-room"; then
  record_check "War-room marker payload block present" "true" "weekly-growth-founder-fame-war-room"
else
  record_check "War-room marker payload block present" "false" "Missing checklist marker payload block."
fi

expected_comment_path=".build/growth/.tmp-founder-fame-war-room-comment-expected-${run_id}-${timestamp}.md"
set +e
zsh scripts/post_founder_fame_war_room_comment.sh \
  --war-room "$war_room_path" \
  --strict \
  --dry-run \
  --out "$expected_comment_path" >/dev/null
render_exit_code=$?
set -e

if (( render_exit_code == 0 )) && [[ -s "$expected_comment_path" ]]; then
  record_check "Expected checklist comment render" "true" "$expected_comment_path"
else
  record_check "Expected checklist comment render" "false" "post_founder_fame_war_room_comment.sh render failed (exit ${render_exit_code})."
fi

if [[ -z "$comment_path" ]] && [[ -s "$expected_comment_path" ]]; then
  comment_path="$expected_comment_path"
  auto_generated_expected_comment=1
fi

comment_marker='<!-- weekly-growth-founder-fame-war-room-comment -->'
if [[ -n "$comment_path" && -f "$comment_path" ]]; then
  if rg -Fq -- "$comment_marker" "$comment_path"; then
    record_check "Checklist comment marker present" "true" "${comment_marker}"
  else
    record_check "Checklist comment marker present" "false" "Missing ${comment_marker}"
  fi

  if [[ -n "$run_now" ]] && rg -Fq -- "Run now: ${run_now}" "$comment_path"; then
    record_check "Checklist comment mirrors run-now action" "true" "${run_now}"
  else
    record_check "Checklist comment mirrors run-now action" "false" "Run-now field missing or mismatched."
  fi

  if [[ -n "$artifact_link" ]] && rg -Fq -- "Artifact link: ${artifact_link}" "$comment_path"; then
    record_check "Checklist comment mirrors artifact link" "true" "${artifact_link}"
  else
    record_check "Checklist comment mirrors artifact link" "false" "Artifact link missing or mismatched."
  fi

  if [[ -n "$checklist_target" ]] && rg -Fq -- "Checklist target: ${checklist_target}" "$comment_path"; then
    record_check "Checklist comment mirrors checklist target" "true" "${checklist_target}"
  else
    record_check "Checklist comment mirrors checklist target" "false" "Checklist target missing or mismatched."
  fi

  if [[ -n "$marker_payload_line" ]] && rg -Fq -- "$marker_payload_line" "$comment_path"; then
    record_check "Checklist comment includes marker payload" "true" "$marker_payload_line"
  else
    record_check "Checklist comment includes marker payload" "false" "Marker payload not present in comment."
  fi
else
  record_check "Checklist comment artifact available" "false" "No comment artifact found or rendered."
fi

if [[ -z "$issue_number" ]] && [[ "$mode" != "sample" ]] && [[ "$repo_slug" != "n/a" ]]; then
  resolved_issue_number="$(resolve_checklist_issue_number "$repo_slug" "$week_label")"
  if [[ -n "$resolved_issue_number" ]]; then
    issue_number="$resolved_issue_number"
    issue_source="title-search"
  else
    issue_source="none"
  fi
fi

if [[ -n "$issue_number" ]]; then
  record_check "Checklist issue number resolved" "true" "$issue_number"
else
  if (( strict_mode == 1 )); then
    record_check "Checklist issue number resolved" "false" "Strict mode requires a resolved checklist issue."
  else
    record_check "Checklist issue number resolved" "true" "Skipped (no issue resolved)."
  fi
fi

live_comment_checks_performed=0
live_marker_comment_count="n/a"
if [[ -n "$issue_number" && "$repo_slug" != "n/a" && "$mode" != "sample" ]]; then
  if ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    record_check "Live checklist comment checks" "false" "gh + jq are required for issue comment checks."
  else
    comments_json="$(gh api --paginate "/repos/${repo_slug}/issues/${issue_number}/comments?per_page=100" | jq -s 'add // []')"
    live_marker_comment_count="$(print -r -- "$comments_json" | jq --arg marker "$comment_marker" '[.[] | select((.body // "") | contains($marker))] | length')"
    latest_comment_body="$(print -r -- "$comments_json" | jq -r --arg marker "$comment_marker" '
      [ .[] | select((.body // "") | contains($marker)) ]
      | sort_by((.updated_at // .created_at // ""))
      | reverse
      | (.[0].body // "")
    ')"
    live_comment_checks_performed=1

    if [[ "$live_marker_comment_count" == "1" ]]; then
      record_check "Live checklist marker comment count" "true" "actual ${live_marker_comment_count}, expected 1"
    else
      record_check "Live checklist marker comment count" "false" "actual ${live_marker_comment_count}, expected 1"
    fi

    if [[ -n "$run_now" ]] && [[ "$latest_comment_body" == *"Run now: ${run_now}"* ]]; then
      record_check "Live checklist comment mirrors run-now action" "true" "$run_now"
    else
      record_check "Live checklist comment mirrors run-now action" "false" "Run-now field missing or mismatched in live checklist comment."
    fi

    if [[ -n "$artifact_link" ]] && [[ "$latest_comment_body" == *"Artifact link: ${artifact_link}"* ]]; then
      record_check "Live checklist comment mirrors artifact link" "true" "$artifact_link"
    else
      record_check "Live checklist comment mirrors artifact link" "false" "Artifact link missing or mismatched in live checklist comment."
    fi

    if [[ -n "$checklist_target" ]] && [[ "$latest_comment_body" == *"Checklist target: ${checklist_target}"* ]]; then
      record_check "Live checklist comment mirrors checklist target" "true" "$checklist_target"
    else
      record_check "Live checklist comment mirrors checklist target" "false" "Checklist target missing or mismatched in live checklist comment."
    fi

    if [[ -n "$marker_payload_line" ]] && [[ "$latest_comment_body" == *"$marker_payload_line"* ]]; then
      record_check "Live checklist comment includes marker payload" "true" "$marker_payload_line"
    else
      record_check "Live checklist comment includes marker payload" "false" "Marker payload missing in live checklist comment."
    fi
  fi
else
  if (( strict_mode == 1 )); then
    record_check "Live checklist comment checks" "false" "Strict mode requires live issue comment checks."
  else
    record_check "Live checklist comment checks" "true" "Skipped (no live issue provided/resolved)."
  fi
fi

if [[ "$mode" == "live" ]]; then
  record_check "Workflow run identity" "$([[ "$run_name" == "Founder Fame Pack" ]] && echo true || echo false)" "${run_name}"
  record_check "Workflow run status is completed" "$([[ "$run_status" == "completed" ]] && echo true || echo false)" "${run_status}"
  record_check "Workflow event is expected" "$([[ "$run_event" == "schedule" || "$run_event" == "workflow_dispatch" ]] && echo true || echo false)" "${run_event}"
else
  record_check "Workflow run identity" "true" "${mode} mode (run lookup skipped)"
  record_check "Workflow run status is completed" "true" "${mode} mode (run lookup skipped)"
  record_check "Workflow event is expected" "true" "${mode} mode (run lookup skipped)"
fi

verdict="PASS"
if (( failure_count > 0 )); then
  verdict="FAIL"
fi

cat > "$output_path" <<EOF
# Founder War Room Live Verification: run ${run_id}

- Repository: ${repo_slug}
- Run ID: ${run_id}
- Run ID source: ${run_id_source}
- Mode: ${mode}
- Strict mode: $([[ "$strict_mode" == "1" ]] && echo "enabled" || echo "disabled")
- War-room artifact: ${war_room_path}
- Checklist comment artifact: ${comment_path:-n/a}
- Issue number: ${issue_number:-n/a}
- Issue source: ${issue_source}
- Run URL: ${run_url}

## Parsed War-Room Fields

- Week: ${week_label}
- Run now: ${run_now:-n/a}
- Artifact link: ${artifact_link:-n/a}
- Checklist target: ${checklist_target:-n/a}
- Proof status: ${proof_status:-n/a}
- Route signal: ${route_signal:-n/a}
- Marker payload key: ${marker_payload_line:-n/a}
- Live marker comment count: ${live_marker_comment_count}

## Verification Checks

${(F)check_items}

## Verdict

- Result: ${verdict}
- Failed checks: ${failure_count}
EOF

echo "Wrote founder war-room live verification report: $output_path"

if [[ -n "$download_cleanup_path" && "$keep_download" != "1" ]]; then
  rm -rf "$download_cleanup_path"
fi

if (( auto_generated_expected_comment == 1 )); then
  rm -f "$expected_comment_path"
fi

if (( failure_count > 0 )); then
  exit 1
fi
