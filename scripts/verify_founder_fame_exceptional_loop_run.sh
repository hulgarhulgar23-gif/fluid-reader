#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify founder fame exceptional-loop checklist-comment sync from local artifacts or live workflow run.

Usage:
  zsh scripts/verify_founder_fame_exceptional_loop_run.sh [options]

Options:
  --run-id <number|latest>       GitHub Actions run ID to inspect (default: latest completed Weekly Growth Review run)
  --exceptional-loop <path>      Local founder fame exceptional-loop markdown artifact path
  --comment <path>               Local founder fame exceptional-loop checklist comment markdown artifact path
  --repo <owner/repo>            Repository slug for live issue/run checks (default: inferred from git remote/env)
  --issue <number>               Monday checklist issue number for live checklist comment checks
  --strict                       Require live checklist issue checks (fails if issue cannot be resolved)
  --out <path>                   Output markdown report path (default: .build/growth/<run-id>-founder-fame-exceptional-loop-live-check.md)
  --download-dir <path>          Artifact download directory for live mode
  --keep-download                Keep downloaded artifact directory
  --sample                       Run local sample verification without GitHub API calls
  -h, --help                     Show help

Examples:
  zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
    --exceptional-loop docs/campaigns/2026-W24-founder-fame-exceptional-loop.md \
    --strict

  zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
    --run-id 12345678901 \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_founder_fame_exceptional_loop_run.sh \
    --repo your-org/your-repo \
    --issue 123 \
    --strict

  zsh scripts/verify_founder_fame_exceptional_loop_run.sh --sample
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

run_id=""
exceptional_loop_path=""
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
    --exceptional-loop)
      exceptional_loop_path="${2:-}"
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
  heading="$(rg -m1 '^# Founder Fame Exceptional Loop - ' "$source_path" || true)"
  if [[ -z "$heading" ]]; then
    echo "n/a"
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

resolve_latest_run_id() {
  local repo="$1"
  local latest_json latest_id

  latest_json="$(gh run list \
    --repo "$repo" \
    --workflow "weekly-growth-review.yml" \
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
    --workflow "Weekly Growth Review" \
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

if (( sample_mode == 1 )) && [[ -n "$exceptional_loop_path" || -n "$comment_path" ]]; then
  echo "--sample cannot be combined with --exceptional-loop or --comment." >&2
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
  if [[ -n "$exceptional_loop_path" ]]; then
    mode="exceptional-loop"
    if [[ -z "$run_id" ]]; then
      run_id="local-${timestamp}"
      run_id_source="exceptional-loop-generated"
    else
      run_id_source="exceptional-loop-provided"
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
  exceptional_loop_path=".build/growth/${run_id}-founder-fame-exceptional-loop-sample.md"
  comment_path=".build/growth/${run_id}-founder-fame-exceptional-loop-comment-sample.md"

  cat > "$exceptional_loop_path" <<'EOF'
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

  zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
    --exceptional-loop "$exceptional_loop_path" \
    --dry-run \
    --out "$comment_path" >/dev/null

  issue_number="${issue_number:-123}"
  issue_source="sample"
elif [[ "$mode" == "live" ]]; then
  if [[ -z "$run_id" ]]; then
    run_id="$(resolve_latest_run_id "$repo_slug")"
    if [[ -z "$run_id" ]]; then
      echo "Could not resolve latest completed Weekly Growth Review run for repo ${repo_slug}." >&2
      exit 1
    fi
  fi
  if [[ ! "$run_id" =~ ^[0-9]+$ ]]; then
    echo "--run-id must be numeric or 'latest'. Received: $run_id" >&2
    exit 1
  fi

  if [[ -z "$download_dir" ]]; then
    download_dir=".build/growth/.tmp-founder-fame-exceptional-loop-live-${run_id}-${timestamp}"
  fi
  mkdir -p "$download_dir"
  download_cleanup_path="$download_dir"

  run_json="$(gh api "/repos/${repo_slug}/actions/runs/${run_id}")"
  run_name="$(print -r -- "$run_json" | jq -r '.name // "n/a"')"
  run_event="$(print -r -- "$run_json" | jq -r '.event // "n/a"')"
  run_status="$(print -r -- "$run_json" | jq -r '.status // "n/a"')"
  run_conclusion="$(print -r -- "$run_json" | jq -r '.conclusion // "n/a"')"
  run_url="$(print -r -- "$run_json" | jq -r '.html_url // "n/a"')"

  artifact_name="weekly-growth-review-${run_id}"
  gh run download "$run_id" \
    --repo "$repo_slug" \
    --name "$artifact_name" \
    --dir "$download_dir" >/dev/null

  if [[ -z "$exceptional_loop_path" ]]; then
    exceptional_loop_path="$(find "$download_dir" -type f -name '*founder-fame-exceptional-loop-*.md' ! -name '*founder-fame-exceptional-loop-comment-*.md' ! -name '*founder-fame-exceptional-loop-live-check-*.md' | head -n 1 || true)"
  fi
  if [[ -z "$comment_path" ]]; then
    comment_path="$(find "$download_dir" -type f -name '*founder-fame-exceptional-loop-comment-*.md' | head -n 1 || true)"
  fi
fi

if [[ -z "$exceptional_loop_path" || ! -f "$exceptional_loop_path" ]]; then
  echo "Founder fame exceptional-loop artifact not found. Provide --exceptional-loop <path> or use live mode with available artifact." >&2
  exit 1
fi

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/${run_id}-founder-fame-exceptional-loop-live-check.md"
fi
mkdir -p "$(dirname "$output_path")"

week_label="$(extract_week_from_heading "$exceptional_loop_path")"
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
marker_payload_line="$(print -r -- "$marker_payload" | awk 'NF {print; exit}' || true)"

record_check "Exceptional-loop artifact exists" "true" "$exceptional_loop_path"

if [[ "$week_label" == "n/a" || -z "$week_label" ]]; then
  record_check "Exceptional-loop week parsed" "false" "Could not parse '# Founder Fame Exceptional Loop - <week>' heading."
else
  record_check "Exceptional-loop week parsed" "true" "$week_label"
fi

missing_signal_fields=()
[[ -z "$route_mode" ]] && missing_signal_fields+=("Route mode")
[[ -z "$readiness" ]] && missing_signal_fields+=("Exceptional readiness")
[[ -z "$latest_score" ]] && missing_signal_fields+=("Latest score")
if [[ "$window_velocity" == "n/a" || -z "$window_velocity" ]]; then
  missing_signal_fields+=("Window velocity")
fi
if (( ${#missing_signal_fields[@]} == 0 )); then
  record_check "Signal snapshot fields present" "true" "route_mode=${route_mode}; readiness=${readiness}; latest_score=${latest_score}; window_velocity=${window_velocity}"
else
  record_check "Signal snapshot fields present" "false" "Missing: ${(j:, :)missing_signal_fields}"
fi

if [[ -n "$checklist_seed" ]]; then
  record_check "Checklist seed present" "true" "$checklist_seed"
else
  record_check "Checklist seed present" "false" "Missing checklist update seed."
fi

if [[ -n "$marker_payload" ]] && print -r -- "$marker_payload" | rg -Fq "weekly-growth-founder-fame-exceptional-loop"; then
  record_check "Exceptional-loop marker payload block present" "true" "weekly-growth-founder-fame-exceptional-loop"
else
  record_check "Exceptional-loop marker payload block present" "false" "Missing operator marker payload block."
fi

expected_comment_path=".build/growth/.tmp-founder-fame-exceptional-loop-comment-expected-${run_id}-${timestamp}.md"
set +e
zsh scripts/post_founder_fame_exceptional_loop_comment.sh \
  --exceptional-loop "$exceptional_loop_path" \
  --dry-run \
  --out "$expected_comment_path" >/dev/null
render_exit_code=$?
set -e

if (( render_exit_code == 0 )) && [[ -s "$expected_comment_path" ]]; then
  record_check "Expected checklist comment render" "true" "$expected_comment_path"
else
  record_check "Expected checklist comment render" "false" "post_founder_fame_exceptional_loop_comment.sh render failed (exit ${render_exit_code})."
fi

if [[ -z "$comment_path" ]] && [[ -s "$expected_comment_path" ]]; then
  comment_path="$expected_comment_path"
  auto_generated_expected_comment=1
fi

comment_marker='<!-- weekly-growth-founder-fame-exceptional-loop-comment -->'
if [[ -n "$comment_path" && -f "$comment_path" ]]; then
  if rg -Fq -- "$comment_marker" "$comment_path"; then
    record_check "Checklist comment marker present" "true" "${comment_marker}"
  else
    record_check "Checklist comment marker present" "false" "Missing ${comment_marker}"
  fi

  if [[ -n "$route_mode" ]] && rg -Fq -- "- Route mode: ${route_mode}" "$comment_path"; then
    record_check "Checklist comment mirrors route mode" "true" "${route_mode}"
  else
    record_check "Checklist comment mirrors route mode" "false" "Route mode missing or mismatched."
  fi

  if [[ -n "$readiness" ]] && rg -Fq -- "- Exceptional readiness: ${readiness}" "$comment_path"; then
    record_check "Checklist comment mirrors readiness" "true" "${readiness}"
  else
    record_check "Checklist comment mirrors readiness" "false" "Exceptional readiness missing or mismatched."
  fi

  if [[ -n "$latest_score" ]] && rg -Fq -- "- Latest score: ${latest_score}" "$comment_path"; then
    record_check "Checklist comment mirrors latest score" "true" "${latest_score}"
  else
    record_check "Checklist comment mirrors latest score" "false" "Latest score missing or mismatched."
  fi

  if [[ "$window_velocity" != "n/a" ]] && rg -Fq -- "- Window velocity: ${window_velocity}" "$comment_path"; then
    record_check "Checklist comment mirrors window velocity" "true" "${window_velocity}"
  else
    record_check "Checklist comment mirrors window velocity" "false" "Window velocity missing or mismatched."
  fi

  if [[ -n "$checklist_seed" ]] && rg -Fq -- "$checklist_seed" "$comment_path"; then
    record_check "Checklist comment mirrors checklist seed" "true" "$checklist_seed"
  else
    record_check "Checklist comment mirrors checklist seed" "false" "Checklist seed missing or mismatched."
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

    if [[ -n "$route_mode" ]] && [[ "$latest_comment_body" == *"- Route mode: ${route_mode}"* ]]; then
      record_check "Live checklist comment mirrors route mode" "true" "$route_mode"
    else
      record_check "Live checklist comment mirrors route mode" "false" "Route mode missing or mismatched in live checklist comment."
    fi

    if [[ -n "$readiness" ]] && [[ "$latest_comment_body" == *"- Exceptional readiness: ${readiness}"* ]]; then
      record_check "Live checklist comment mirrors readiness" "true" "$readiness"
    else
      record_check "Live checklist comment mirrors readiness" "false" "Exceptional readiness missing or mismatched in live checklist comment."
    fi

    if [[ -n "$latest_score" ]] && [[ "$latest_comment_body" == *"- Latest score: ${latest_score}"* ]]; then
      record_check "Live checklist comment mirrors latest score" "true" "$latest_score"
    else
      record_check "Live checklist comment mirrors latest score" "false" "Latest score missing or mismatched in live checklist comment."
    fi

    if [[ "$window_velocity" != "n/a" ]] && [[ "$latest_comment_body" == *"- Window velocity: ${window_velocity}"* ]]; then
      record_check "Live checklist comment mirrors window velocity" "true" "$window_velocity"
    else
      record_check "Live checklist comment mirrors window velocity" "false" "Window velocity missing or mismatched in live checklist comment."
    fi

    if [[ -n "$checklist_seed" ]] && [[ "$latest_comment_body" == *"$checklist_seed"* ]]; then
      record_check "Live checklist comment mirrors checklist seed" "true" "$checklist_seed"
    else
      record_check "Live checklist comment mirrors checklist seed" "false" "Checklist seed missing or mismatched in live checklist comment."
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
  record_check "Workflow run identity" "$([[ "$run_name" == "Weekly Growth Review" ]] && echo true || echo false)" "${run_name}"
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
# Founder Exceptional Loop Live Verification: run ${run_id}

- Repository: ${repo_slug}
- Run ID: ${run_id}
- Run ID source: ${run_id_source}
- Mode: ${mode}
- Strict mode: $([[ "$strict_mode" == "1" ]] && echo "enabled" || echo "disabled")
- Exceptional-loop artifact: ${exceptional_loop_path}
- Checklist comment artifact: ${comment_path:-n/a}
- Issue number: ${issue_number:-n/a}
- Issue source: ${issue_source}
- Run URL: ${run_url}

## Parsed Exceptional-Loop Fields

- Week: ${week_label}
- Route mode: ${route_mode:-n/a}
- Exceptional readiness: ${readiness:-n/a}
- Latest score: ${latest_score:-n/a}
- Window velocity: ${window_velocity}
- Checklist seed: ${checklist_seed:-n/a}
- Marker payload key: ${marker_payload_line:-n/a}
- Live marker comment count: ${live_marker_comment_count}

## Verification Checks

${(F)check_items}

## Verdict

- Result: ${verdict}
- Failed checks: ${failure_count}
EOF

echo "Wrote founder exceptional-loop live verification report: $output_path"

if [[ -n "$download_cleanup_path" && "$keep_download" != "1" ]]; then
  rm -rf "$download_cleanup_path"
fi

if (( auto_generated_expected_comment == 1 )); then
  rm -f "$expected_comment_path"
fi

if (( failure_count > 0 )); then
  exit 1
fi
