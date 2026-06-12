#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify live Weekly Growth Review distribution-nudge behavior from workflow artifacts.

Usage:
  zsh scripts/verify_distribution_nudge_run.sh [options]

Options:
  --run-id <number|latest>     GitHub Actions run ID to inspect (default: latest completed Weekly Growth Review run)
  --repo <owner/repo>          Repository slug (default: inferred from git remote origin / env)
  --trace <path>               Use an existing local distribution-nudge trace markdown file
  --issue <number>             Monday checklist issue number for live comment/body checks
  --strict                     Require issue-level live checks (fails if issue cannot be resolved)
  --out <path>                 Output markdown report path (default: .build/growth/<run-id>-distribution-nudge-live-check.md)
  --download-dir <path>        Artifact download directory (default: temporary folder under .build/growth)
  --keep-download              Keep downloaded artifacts directory
  --sample                     Run local sample verification without GitHub API calls
  -h, --help                   Show this help

Examples:
  zsh scripts/verify_distribution_nudge_run.sh \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_distribution_nudge_run.sh \
    --run-id 12345678901 \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_distribution_nudge_run.sh \
    --trace .build/growth/2026-W24-distribution-nudge-trace.md \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_distribution_nudge_run.sh --sample
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

run_id=""
repo_slug=""
issue_number=""
output_path=""
download_dir=""
trace_input_path=""
keep_download=0
sample_mode=0
strict_mode=0

while (( $# > 0 )); do
  case "$1" in
    --run-id)
      run_id="${2:-}"
      shift 2
      ;;
    --repo)
      repo_slug="${2:-}"
      shift 2
      ;;
    --trace)
      trace_input_path="${2:-}"
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
      usage
      exit 1
      ;;
  esac
done

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
  local latest_json
  local latest_id

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

extract_trace_field() {
  local trace_path="$1"
  local label="$2"
  local line
  line="$(rg -F -m1 -- "- ${label}: " "$trace_path" || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  echo "${line#- ${label}: }"
}

normalize_text() {
  local value="$1"
  echo "${value:l}"
}

in_list() {
  local value="$1"
  shift
  for expected in "$@"; do
    if [[ "$value" == "$expected" ]]; then
      return 0
    fi
  done
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

timestamp="$(date '+%Y%m%d-%H%M%S')"
run_id_source="provided"
verification_mode="live"
if (( sample_mode == 1 )) && [[ -n "$trace_input_path" ]]; then
  echo "--sample and --trace cannot be used together." >&2
  exit 1
fi

if (( sample_mode == 1 )); then
  verification_mode="sample"
  if [[ -z "$run_id" ]]; then
    run_id="sample-${timestamp}"
    run_id_source="sample-generated"
  else
    run_id_source="sample-provided"
  fi
elif [[ -n "$trace_input_path" ]]; then
  verification_mode="trace"
  if [[ -z "$run_id" ]]; then
    run_id="trace-${timestamp}"
    run_id_source="trace-generated"
  else
    run_id_source="trace-provided"
  fi
else
  if [[ "$run_id" == "latest" || -z "$run_id" ]]; then
    run_id=""
    run_id_source="latest"
  fi
fi

if [[ -z "$repo_slug" ]]; then
  repo_slug="$(detect_repo_slug)"
fi

if [[ -z "$repo_slug" ]]; then
  if (( sample_mode == 1 )); then
    repo_slug="sample/repo"
  elif [[ -n "$issue_number" || "$strict_mode" == "1" ]]; then
    echo "Unable to infer --repo from git remote/env. Pass --repo <owner/repo>." >&2
    exit 1
  else
    repo_slug="n/a"
  fi
fi

trace_path=""
download_cleanup_path=""
comments_nudge_count="n/a"
comments_action_items_count="n/a"
issue_escalation_block_present="n/a"
run_name="n/a"
run_event="n/a"
run_status="n/a"
run_conclusion="n/a"
run_url="n/a"
issue_source="provided"
live_issue_checks_performed=0

if [[ "$verification_mode" == "sample" ]]; then
  local_trace_path=".build/growth/${run_id}-distribution-nudge-trace-sample.md"
  cat > "$local_trace_path" <<'EOF'
<!-- weekly-growth-distribution-nudge-trace -->
# Distribution Nudge Trace: 2099-W01

## Trigger Snapshot

- Source week: 2098-W52
- Checklist issue number: 123
- Nudge status: triggered
- Nudge reason: distribution score 52% below 75%; distribution status is in progress
- Threshold used: 75
- Distribution status (raw): in progress
- Distribution status (normalized): in progress
- Distribution score (raw): 52%
- Distribution score (numeric): 52
- Distribution score delta: -8pp
- Distribution days completed: 3/8
- Remaining distribution days: 5

## Automation Actions

- Nudge comment action: created
- Action-items comment action: created
- Escalation block action: upserted
- Escalation status: active
- Escalated Day 0-Day 2 task count: 2
- Escalated Day 0-Day 2 task labels: Day 0 launch proof-first post + initial replies completed. | Day 2 creator/community follow-up wave 1 completed.
- Duplicate nudge comments cleared: 0
- Duplicate action-items comments cleared: 0

## Routing Context

- ROI preferred channel: primary
- Channel mix recommendation: Maintain a primary-led 60/40 mix and complete Day-0 to Day-7 follow-up cadence.
- ROI routing recommendation: Lead with primary channel this week.
EOF
  trace_path="$local_trace_path"
  issue_number="${issue_number:-123}"
  issue_source="sample"
  comments_nudge_count="1"
  comments_action_items_count="1"
  issue_escalation_block_present="true"
  live_issue_checks_performed=1
elif [[ "$verification_mode" == "trace" ]]; then
  trace_path="$trace_input_path"
  if [[ ! -f "$trace_path" ]]; then
    echo "--trace file not found: $trace_path" >&2
    exit 1
  fi
else
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required for live verification." >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required for live verification." >&2
    exit 1
  fi

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
    download_dir=".build/growth/.tmp-distribution-nudge-live-${run_id}-${timestamp}"
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

  trace_path="$(find "$download_dir" -type f -name '*-distribution-nudge-trace.md' | head -n 1 || true)"
  if [[ -z "$trace_path" || ! -f "$trace_path" ]]; then
    echo "Could not find distribution nudge trace artifact for run $run_id." >&2
    exit 1
  fi
fi

mkdir -p ".build/growth"

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/${run_id}-distribution-nudge-live-check.md"
fi

trace_week="$(print -r -- "$(basename "$trace_path")" | sed -E 's/-distribution-nudge-trace.*$//')"
trace_issue_number="$(extract_trace_field "$trace_path" "Checklist issue number")"
nudge_status="$(extract_trace_field "$trace_path" "Nudge status")"
nudge_reason="$(extract_trace_field "$trace_path" "Nudge reason")"
threshold_used="$(extract_trace_field "$trace_path" "Threshold used")"
normalized_status="$(extract_trace_field "$trace_path" "Distribution status (normalized)")"
score_numeric="$(extract_trace_field "$trace_path" "Distribution score (numeric)")"
nudge_comment_action="$(extract_trace_field "$trace_path" "Nudge comment action")"
action_items_comment_action="$(extract_trace_field "$trace_path" "Action-items comment action")"
escalation_block_action="$(extract_trace_field "$trace_path" "Escalation block action")"
escalation_status="$(extract_trace_field "$trace_path" "Escalation status")"
escalated_task_count="$(extract_trace_field "$trace_path" "Escalated Day 0-Day 2 task count")"
duplicate_nudge_cleared="$(extract_trace_field "$trace_path" "Duplicate nudge comments cleared")"
duplicate_action_items_cleared="$(extract_trace_field "$trace_path" "Duplicate action-items comments cleared")"

if [[ -z "$issue_number" ]]; then
  if [[ "$trace_issue_number" =~ ^[0-9]+$ && ( "$verification_mode" == "live" || "$strict_mode" == "1" || "$sample_mode" == "1" ) ]]; then
    issue_number="$trace_issue_number"
    issue_source="trace"
  elif [[ "$trace_issue_number" =~ ^[0-9]+$ ]]; then
    issue_source="trace-skipped"
  else
    issue_source="none"
  fi
fi

if [[ -n "$issue_number" && ! "$issue_number" =~ ^[0-9]+$ ]]; then
  echo "--issue must be numeric. Received: $issue_number" >&2
  exit 1
fi

if (( sample_mode == 0 && strict_mode == 1 )) && [[ -z "$issue_number" ]]; then
  echo "--strict requires a resolvable issue number (pass --issue or include it in trace artifact)." >&2
  exit 1
fi

if (( sample_mode == 0 && strict_mode == 1 )) && [[ "$repo_slug" == "n/a" ]]; then
  echo "--strict requires --repo <owner/repo> when repository cannot be inferred." >&2
  exit 1
fi

if (( sample_mode == 0 )) && [[ -n "$issue_number" ]] && [[ "$repo_slug" != "n/a" ]]; then
  comments_json="$(gh api --paginate "/repos/${repo_slug}/issues/${issue_number}/comments?per_page=100" | jq -s 'add')"
  comments_nudge_count="$(print -r -- "$comments_json" | jq '[.[] | select((.body // "") | contains("<!-- weekly-growth-distribution-nudge -->"))] | length')"
  comments_action_items_count="$(print -r -- "$comments_json" | jq '[.[] | select((.body // "") | contains("<!-- weekly-growth-distribution-action-items -->"))] | length')"
  issue_body="$(gh api "/repos/${repo_slug}/issues/${issue_number}" --jq '.body // ""')"
  if print -r -- "$issue_body" | rg -Fq "<!-- weekly-growth-distribution-escalation-start -->"; then
    issue_escalation_block_present="true"
  else
    issue_escalation_block_present="false"
  fi
  live_issue_checks_performed=1
fi

record_check "Trace artifact exists" "true" "$trace_path"
record_check "Trace checklist issue field parsed" "$([[ "$trace_issue_number" =~ ^[0-9]+$ ]] && echo true || echo false)" "${trace_issue_number}"

if [[ "$verification_mode" == "live" ]]; then
  record_check "Workflow run identity" "$([[ "$run_name" == "Weekly Growth Review" ]] && echo true || echo false)" "${run_name}"
  record_check "Workflow run status is completed" "$([[ "$run_status" == "completed" ]] && echo true || echo false)" "${run_status}"
  record_check "Workflow event is expected" "$([[ "$run_event" == "schedule" || "$run_event" == "workflow_dispatch" ]] && echo true || echo false)" "${run_event}"
elif [[ "$verification_mode" == "trace" ]]; then
  record_check "Workflow run identity" "true" "trace mode (run lookup skipped)"
  record_check "Workflow run status is completed" "true" "trace mode (run lookup skipped)"
  record_check "Workflow event is expected" "true" "trace mode (run lookup skipped)"
else
  record_check "Workflow run identity" "true" "sample mode"
  record_check "Workflow run status is completed" "true" "sample mode"
  record_check "Workflow event is expected" "true" "sample mode"
fi

if [[ "$trace_week" == "n/a" || -z "$trace_week" ]]; then
  record_check "Trace week inferred from artifact name" "false" "Trace filename missing week prefix."
else
  record_check "Trace week inferred from artifact name" "true" "$trace_week"
fi

if [[ "$nudge_status" == "n/a" || -z "$nudge_status" ]]; then
  record_check "Trace nudge status parsed" "false" "Missing Nudge status in trace artifact."
else
  record_check "Trace nudge status parsed" "true" "$nudge_status"
fi

if [[ "$nudge_reason" == "n/a" || -z "$nudge_reason" ]]; then
  record_check "Trace nudge reason parsed" "false" "Missing Nudge reason in trace artifact."
else
  record_check "Trace nudge reason parsed" "true" "$nudge_reason"
fi

if [[ "$threshold_used" == "n/a" || -z "$threshold_used" ]]; then
  record_check "Trace threshold parsed" "false" "Missing Threshold used field."
else
  record_check "Trace threshold parsed" "true" "$threshold_used"
fi

if [[ "$score_numeric" == "n/a" || "$score_numeric" == "" ]]; then
  record_check "Trace score numeric parsed" "true" "score numeric unavailable (accepted when score cannot be parsed)."
else
  if [[ "$score_numeric" =~ ^[+-]?[0-9]+(\.[0-9]+)?$ ]]; then
    record_check "Trace score numeric parsed" "true" "$score_numeric"
  else
    record_check "Trace score numeric parsed" "false" "Expected numeric distribution score, got: $score_numeric"
  fi
fi

nudge_status_norm="$(normalize_text "$nudge_status")"
if [[ "$nudge_status_norm" == "triggered" ]]; then
  if in_list "$nudge_comment_action" "created" "updated"; then
    record_check "Nudge comment action matches triggered state" "true" "$nudge_comment_action"
  else
    record_check "Nudge comment action matches triggered state" "false" "Expected created/updated, got: $nudge_comment_action"
  fi
elif [[ "$nudge_status_norm" == "cleared" || "$nudge_status_norm" == "not-needed" ]]; then
  if in_list "$nudge_comment_action" "deleted" "not-present"; then
    record_check "Nudge comment action matches non-triggered state" "true" "$nudge_comment_action"
  else
    record_check "Nudge comment action matches non-triggered state" "false" "Expected deleted/not-present, got: $nudge_comment_action"
  fi
else
  record_check "Nudge status is recognized" "false" "Unexpected nudge status: $nudge_status"
fi

escalation_status_norm="$(normalize_text "$escalation_status")"
if [[ "$escalation_status_norm" == "active" ]]; then
  if in_list "$action_items_comment_action" "created" "updated"; then
    record_check "Action-items comment action matches active escalation" "true" "$action_items_comment_action"
  else
    record_check "Action-items comment action matches active escalation" "false" "Expected created/updated, got: $action_items_comment_action"
  fi
  if in_list "$escalation_block_action" "upserted" "unchanged"; then
    record_check "Escalation block action matches active escalation" "true" "$escalation_block_action"
  else
    record_check "Escalation block action matches active escalation" "false" "Expected upserted/unchanged, got: $escalation_block_action"
  fi
elif [[ "$escalation_status_norm" == "no-day0-2-gaps" || "$escalation_status_norm" == "cleared" ]]; then
  if in_list "$action_items_comment_action" "deleted" "not-present"; then
    record_check "Action-items comment action matches non-active escalation" "true" "$action_items_comment_action"
  else
    record_check "Action-items comment action matches non-active escalation" "false" "Expected deleted/not-present, got: $action_items_comment_action"
  fi
  if in_list "$escalation_block_action" "cleared" "not-present"; then
    record_check "Escalation block action matches non-active escalation" "true" "$escalation_block_action"
  else
    record_check "Escalation block action matches non-active escalation" "false" "Expected cleared/not-present, got: $escalation_block_action"
  fi
else
  record_check "Escalation status is recognized" "false" "Unexpected escalation status: $escalation_status"
fi

if [[ "$duplicate_nudge_cleared" =~ ^[0-9]+$ ]]; then
  record_check "Duplicate nudge clear count is numeric" "true" "$duplicate_nudge_cleared"
else
  record_check "Duplicate nudge clear count is numeric" "false" "$duplicate_nudge_cleared"
fi

if [[ "$duplicate_action_items_cleared" =~ ^[0-9]+$ ]]; then
  record_check "Duplicate action-items clear count is numeric" "true" "$duplicate_action_items_cleared"
else
  record_check "Duplicate action-items clear count is numeric" "false" "$duplicate_action_items_cleared"
fi

if [[ -n "$issue_number" ]]; then
  if [[ "$trace_issue_number" =~ ^[0-9]+$ && "$trace_issue_number" != "$issue_number" ]]; then
    record_check "Trace issue matches target issue" "false" "trace ${trace_issue_number}, target ${issue_number}"
  else
    record_check "Trace issue matches target issue" "true" "trace ${trace_issue_number}, target ${issue_number}"
  fi

  expected_nudge_count="0"
  expected_action_count="0"
  expected_escalation_presence="false"

  if [[ "$nudge_status_norm" == "triggered" ]]; then
    expected_nudge_count="1"
  fi
  if [[ "$escalation_status_norm" == "active" ]]; then
    expected_action_count="1"
    expected_escalation_presence="true"
  fi

  if (( live_issue_checks_performed == 1 )); then
    if [[ "$comments_nudge_count" == "$expected_nudge_count" ]]; then
      record_check "Issue nudge marker count aligns with trace status" "true" "actual ${comments_nudge_count}, expected ${expected_nudge_count}"
    else
      record_check "Issue nudge marker count aligns with trace status" "false" "actual ${comments_nudge_count}, expected ${expected_nudge_count}"
    fi

    if [[ "$comments_action_items_count" == "$expected_action_count" ]]; then
      record_check "Issue action-items marker count aligns with escalation status" "true" "actual ${comments_action_items_count}, expected ${expected_action_count}"
    else
      record_check "Issue action-items marker count aligns with escalation status" "false" "actual ${comments_action_items_count}, expected ${expected_action_count}"
    fi

    if [[ "$issue_escalation_block_present" == "$expected_escalation_presence" ]]; then
      record_check "Checklist escalation block presence aligns with escalation status" "true" "actual ${issue_escalation_block_present}, expected ${expected_escalation_presence}"
    else
      record_check "Checklist escalation block presence aligns with escalation status" "false" "actual ${issue_escalation_block_present}, expected ${expected_escalation_presence}"
    fi
  else
    if (( strict_mode == 1 )); then
      record_check "Live issue checks" "false" "Issue number resolved but repository slug is unavailable."
    else
      record_check "Live issue checks" "true" "Skipped issue API checks because repository slug is unavailable."
    fi
  fi
else
  if (( strict_mode == 1 )); then
    record_check "Live issue checks" "false" "Strict mode requires issue checks, but no issue number was resolved."
  else
    record_check "Live issue checks" "true" "Skipped (no --issue provided)."
  fi
fi

verdict="PASS"
if (( failure_count > 0 )); then
  verdict="FAIL"
fi

cat > "$output_path" <<EOF
# Distribution Nudge Live Verification: run ${run_id}

- Repository: ${repo_slug}
- Run ID: ${run_id}
- Run ID source: ${run_id_source}
- Issue number: ${issue_number:-n/a}
- Issue source: ${issue_source}
- Strict mode: $([[ "$strict_mode" == "1" ]] && echo "enabled" || echo "disabled")
- Mode: ${verification_mode}
- Trace artifact: ${trace_path}
- Run URL: ${run_url}

## Parsed Trace Fields

- Trace week: ${trace_week}
- Trace checklist issue number: ${trace_issue_number}
- Nudge status: ${nudge_status}
- Nudge reason: ${nudge_reason}
- Threshold used: ${threshold_used}
- Workflow name: ${run_name}
- Workflow event: ${run_event}
- Workflow status: ${run_status}
- Workflow conclusion: ${run_conclusion}
- Distribution status (normalized): ${normalized_status}
- Distribution score (numeric): ${score_numeric}
- Nudge comment action: ${nudge_comment_action}
- Action-items comment action: ${action_items_comment_action}
- Escalation block action: ${escalation_block_action}
- Escalation status: ${escalation_status}
- Escalated Day 0-Day 2 task count: ${escalated_task_count}
- Duplicate nudge comments cleared: ${duplicate_nudge_cleared}
- Duplicate action-items comments cleared: ${duplicate_action_items_cleared}

## Verification Checks

${(F)check_items}

## Verdict

- Result: ${verdict}
- Failed checks: ${failure_count}
EOF

echo "Wrote distribution nudge verification report: $output_path"

if [[ -n "$download_cleanup_path" && "$keep_download" != "1" ]]; then
  rm -rf "$download_cleanup_path"
fi

if (( failure_count > 0 )); then
  exit 1
fi
