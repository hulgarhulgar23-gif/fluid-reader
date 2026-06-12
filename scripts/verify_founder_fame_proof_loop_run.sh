#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify live Weekly Growth Review founder proof-loop behavior from workflow artifacts.

Usage:
  zsh scripts/verify_founder_fame_proof_loop_run.sh [options]

Options:
  --run-id <number|latest>     GitHub Actions run ID to inspect (default: latest completed Weekly Growth Review run)
  --repo <owner/repo>          Repository slug (default: inferred from git remote origin / env)
  --check <path>               Use an existing local founder proof-loop verification markdown file
  --issue <number>             Monday checklist issue number for live comment/body checks
  --strict                     Require issue-level live checks (fails if issue cannot be resolved)
  --out <path>                 Output markdown report path (default: .build/growth/<run-id>-founder-fame-proof-loop-live-check.md)
  --download-dir <path>        Artifact download directory (default: temporary folder under .build/growth)
  --keep-download              Keep downloaded artifacts directory
  --sample                     Run local sample verification without GitHub API calls
  -h, --help                   Show this help

Examples:
  zsh scripts/verify_founder_fame_proof_loop_run.sh \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_founder_fame_proof_loop_run.sh \
    --run-id 12345678901 \
    --repo your-org/your-repo \
    --strict

  zsh scripts/verify_founder_fame_proof_loop_run.sh \
    --check .build/founder/founder-fame-proof-loop-check-2026-W24.md \
    --repo your-org/your-repo \
    --issue 123 \
    --strict

  zsh scripts/verify_founder_fame_proof_loop_run.sh --sample
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

run_id=""
repo_slug=""
issue_number=""
output_path=""
download_dir=""
check_input_path=""
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
    --check)
      check_input_path="${2:-}"
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
  local value="$1"
  print -r -- "$value" | tr '[:upper:]' '[:lower:]'
}

extract_first_integer() {
  local value="$1"
  print -r -- "$value" | rg -o --pcre2 '[0-9]+' | head -n1 || true
}

extract_markdown_field() {
  local file_path="$1"
  local label="$2"
  local line
  line="$(rg -m1 -F -- "- ${label}: " "$file_path" || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  trim_value "${line#"- ${label}: "}"
}

extract_week_from_check_path() {
  local file_path="$1"
  local base candidate
  base="$(basename "$file_path")"
  candidate="$(print -r -- "$base" | sed -nE 's/^.*founder-fame-proof-loop-check-([A-Za-z0-9._-]+)\.md$/\1/p')"
  if [[ -n "$candidate" ]]; then
    echo "$candidate"
    return
  fi

  local proof_loop_field
  proof_loop_field="$(extract_markdown_field "$file_path" "Proof loop")"
  candidate="$(print -r -- "$proof_loop_field" | sed -nE 's#^.*founder-fame-proof-loop-([A-Za-z0-9._-]+)\.md.*$#\1#p')"
  if [[ -n "$candidate" ]]; then
    echo "$candidate"
    return
  fi

  echo "n/a"
}

extract_bullet_field_from_text() {
  local text="$1"
  local label="$2"
  local line
  line="$(print -r -- "$text" | rg -m1 -- "^[[:space:]]*- ${label}: " || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  line="$(trim_value "$line")"
  trim_value "${line#"- ${label}: "}"
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

contains_csv_value() {
  local csv="$1"
  local needle="$2"
  local value normalized
  normalized="$(lowercase_value "$needle")"
  IFS=',' read -rA values <<< "$csv"
  for value in "${values[@]}"; do
    if [[ "$(lowercase_value "$(trim_value "$value")")" == "$normalized" ]]; then
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
if (( sample_mode == 1 )) && [[ -n "$check_input_path" ]]; then
  echo "--sample and --check cannot be used together." >&2
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
elif [[ -n "$check_input_path" ]]; then
  verification_mode="check"
  if [[ -z "$run_id" ]]; then
    run_id="check-${timestamp}"
    run_id_source="check-generated"
  else
    run_id_source="check-provided"
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
  elif [[ "$verification_mode" == "live" || -n "$issue_number" || "$strict_mode" == "1" ]]; then
    echo "Unable to infer --repo from git remote/env. Pass --repo <owner/repo>." >&2
    exit 1
  else
    repo_slug="n/a"
  fi
fi

report_path=""
download_cleanup_path=""
trace_week="n/a"
run_name="n/a"
run_event="n/a"
run_status="n/a"
run_conclusion="n/a"
run_url="n/a"
issue_source="provided"
live_issue_checks_performed=0
incident_checks_performed=0
comments_failure_count="n/a"
comments_critical_count="n/a"
open_incident_count="n/a"
incident_primary_number="n/a"
incident_primary_state="n/a"
incident_primary_failure_count="n/a"
incident_primary_critical_threshold="n/a"
incident_primary_critical_status="n/a"
incident_primary_labels_csv="n/a"

if [[ "$verification_mode" == "sample" ]]; then
  local_report_path=".build/founder/${run_id}-founder-fame-proof-loop-check-sample.md"
  mkdir -p "$(dirname "$local_report_path")"
  cat > "$local_report_path" <<'EOF'
# Founder Fame Proof Loop Verification

- Generated: 2099-01-01 00:00:00 +0000
- Proof loop: `/tmp/founder-fame-proof-loop-2099-W01.md`
- Mode: strict
- Input type: sample
- Status: FAIL
- Failures: 2

## Checks
- ✅ Marker present: founder-fame-proof-loop marker found.
- ✅ Title heading: Founder Fame Proof Loop title found.
- ❌ Strict practical reply target: Practical reply target must be >=6 (current: 4).
- ❌ Strict Day 2 log signal: Day 2 log signal is placeholder.
EOF
  report_path="$local_report_path"
  trace_week="2099-W01"
  issue_number="${issue_number:-123}"
  issue_source="sample"
  comments_failure_count="1"
  comments_critical_count="1"
  live_issue_checks_performed=1
  incident_checks_performed=1
  open_incident_count="1"
  incident_primary_number="991"
  incident_primary_state="open"
  incident_primary_failure_count="3"
  incident_primary_critical_threshold="3"
  incident_primary_critical_status="active"
  incident_primary_labels_csv="growth-incident,growth-critical"
elif [[ "$verification_mode" == "check" ]]; then
  report_path="$check_input_path"
  if [[ ! -f "$report_path" ]]; then
    echo "--check file not found: $report_path" >&2
    exit 1
  fi
  if [[ ! -s "$report_path" ]]; then
    echo "--check file is empty: $report_path" >&2
    exit 1
  fi
  trace_week="$(extract_week_from_check_path "$report_path")"
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
    download_dir=".build/growth/.tmp-founder-proof-loop-live-${run_id}-${timestamp}"
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

  report_path="$(find "$download_dir" -type f -name '*founder-fame-proof-loop-check-*.md' | head -n 1 || true)"
  if [[ -z "$report_path" || ! -f "$report_path" ]]; then
    echo "Could not find founder fame proof-loop check artifact for run $run_id." >&2
    exit 1
  fi
  trace_week="$(extract_week_from_check_path "$report_path")"
fi

mkdir -p ".build/growth"

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/${run_id}-founder-fame-proof-loop-live-check.md"
fi

report_status="$(extract_markdown_field "$report_path" "Status")"
report_failures="$(extract_markdown_field "$report_path" "Failures")"
report_status_norm="$(lowercase_value "$report_status")"

if [[ -z "$issue_number" ]]; then
  if (( sample_mode == 0 )); then
    resolved_issue="$(resolve_checklist_issue_number "$repo_slug" "$trace_week")"
    if [[ -n "$resolved_issue" ]]; then
      issue_number="$resolved_issue"
      issue_source="title-search"
    else
      issue_source="none"
    fi
  fi
fi

if [[ -n "$issue_number" && ! "$issue_number" =~ ^[0-9]+$ ]]; then
  echo "--issue must be numeric. Received: $issue_number" >&2
  exit 1
fi

if (( sample_mode == 0 && strict_mode == 1 )) && [[ -z "$issue_number" ]]; then
  echo "--strict requires a resolvable issue number (pass --issue or ensure Monday checklist title includes trace week)." >&2
  exit 1
fi

if (( sample_mode == 0 && strict_mode == 1 )) && [[ "$repo_slug" == "n/a" ]]; then
  echo "--strict requires --repo <owner/repo> when repository cannot be inferred." >&2
  exit 1
fi

if (( sample_mode == 0 )) && [[ -n "$issue_number" ]] && [[ "$repo_slug" != "n/a" ]]; then
  comments_json="$(gh api --paginate "/repos/${repo_slug}/issues/${issue_number}/comments?per_page=100" | jq -s 'add // []')"
  comments_failure_count="$(print -r -- "$comments_json" | jq '[.[] | select((.body // "") | contains("<!-- weekly-growth-founder-fame-proof-loop-verifier-failure -->"))] | length')"
  comments_critical_count="$(print -r -- "$comments_json" | jq '[.[] | select((.body // "") | contains("<!-- weekly-growth-founder-fame-proof-loop-verifier-critical -->"))] | length')"
  live_issue_checks_performed=1
fi

if (( sample_mode == 0 )) && [[ "$repo_slug" != "n/a" ]] && [[ "$trace_week" != "n/a" ]]; then
  incident_issues_raw="$(gh issue list \
    --repo "$repo_slug" \
    --state all \
    --search "\"Growth Incident: Founder Fame Proof Loop Verifier ${trace_week}\" in:title" \
    --json number,state,title,body,labels,updatedAt \
    2>/dev/null || true)"
  if [[ -z "$incident_issues_raw" ]]; then
    incident_issues_raw="[]"
  fi

  incident_issues_json="$(print -r -- "$incident_issues_raw" | jq --arg week "$trace_week" '
    [ .[]
      | select((.body // "") | contains("<!-- weekly-growth-founder-fame-proof-loop-verifier-incident -->"))
      | select((.title // "") | contains("Growth Incident: Founder Fame Proof Loop Verifier " + $week))
    ]
  ')"

  incident_checks_performed=1
  open_incident_count="$(print -r -- "$incident_issues_json" | jq '[.[] | select((.state // "" | ascii_downcase) == "open")] | length')"
  incident_primary_json="$(print -r -- "$incident_issues_json" | jq 'sort_by(.number) | reverse | .[0] // empty')"
  if [[ -n "$incident_primary_json" ]]; then
    incident_primary_number="$(print -r -- "$incident_primary_json" | jq -r '.number // "n/a"')"
    incident_primary_state="$(print -r -- "$incident_primary_json" | jq -r '.state // "n/a"' | tr '[:upper:]' '[:lower:]')"
    incident_primary_labels_csv="$(print -r -- "$incident_primary_json" | jq -r '[.labels[]?.name] | join(",")')"
    incident_primary_body="$(print -r -- "$incident_primary_json" | jq -r '.body // ""')"
    incident_primary_failure_count="$(extract_first_integer "$(extract_bullet_field_from_text "$incident_primary_body" "Failure occurrences for this week")")"
    incident_primary_critical_threshold="$(extract_first_integer "$(extract_bullet_field_from_text "$incident_primary_body" "Critical threshold")")"
    incident_primary_critical_status="$(lowercase_value "$(extract_bullet_field_from_text "$incident_primary_body" "Critical escalation status")")"
    if [[ -z "$incident_primary_failure_count" ]]; then incident_primary_failure_count="n/a"; fi
    if [[ -z "$incident_primary_critical_threshold" ]]; then incident_primary_critical_threshold="n/a"; fi
    if [[ -z "$incident_primary_critical_status" || "$incident_primary_critical_status" == "n/a" ]]; then
      incident_primary_critical_status="n/a"
    fi
  fi
fi

record_check "Founder proof-loop check artifact exists" "true" "$report_path"

if [[ "$report_status_norm" == "pass" || "$report_status_norm" == "fail" ]]; then
  record_check "Founder report status parsed" "true" "$report_status"
else
  record_check "Founder report status parsed" "false" "Expected PASS/FAIL, got: ${report_status}"
fi

if [[ "$report_failures" =~ ^[0-9]+$ ]]; then
  record_check "Founder report failure count parsed" "true" "$report_failures"
else
  record_check "Founder report failure count parsed" "false" "Expected numeric failures, got: ${report_failures}"
fi

if [[ "$verification_mode" == "live" ]]; then
  record_check "Workflow run identity" "$([[ "$run_name" == "Weekly Growth Review" ]] && echo true || echo false)" "${run_name}"
  record_check "Workflow run status is completed" "$([[ "$run_status" == "completed" ]] && echo true || echo false)" "${run_status}"
  record_check "Workflow event is expected" "$([[ "$run_event" == "schedule" || "$run_event" == "workflow_dispatch" ]] && echo true || echo false)" "${run_event}"
elif [[ "$verification_mode" == "check" ]]; then
  record_check "Workflow run identity" "true" "check mode (run lookup skipped)"
  record_check "Workflow run status is completed" "true" "check mode (run lookup skipped)"
  record_check "Workflow event is expected" "true" "check mode (run lookup skipped)"
else
  record_check "Workflow run identity" "true" "sample mode"
  record_check "Workflow run status is completed" "true" "sample mode"
  record_check "Workflow event is expected" "true" "sample mode"
fi

if [[ "$trace_week" == "n/a" || -z "$trace_week" ]]; then
  if [[ "$verification_mode" == "live" ]]; then
    record_check "Founder trace week inferred" "false" "Could not infer week from check artifact."
  else
    record_check "Founder trace week inferred" "true" "Week inference unavailable in non-live mode input (accepted)."
  fi
else
  record_check "Founder trace week inferred" "true" "$trace_week"
fi

if [[ -n "$issue_number" ]]; then
  record_check "Checklist issue number resolved" "true" "${issue_number}"
else
  if (( strict_mode == 1 )); then
    record_check "Checklist issue number resolved" "false" "Strict mode requires issue resolution."
  else
    record_check "Checklist issue number resolved" "true" "Skipped (no issue resolved)."
  fi
fi

verification_failed=0
if [[ "$report_status_norm" == "fail" ]]; then
  verification_failed=1
fi

if [[ -n "$issue_number" ]]; then
  if (( live_issue_checks_performed == 1 )); then
    expected_failure_comment_count="0"
    if (( verification_failed == 1 )); then
      expected_failure_comment_count="1"
    fi
    if [[ "$comments_failure_count" == "$expected_failure_comment_count" ]]; then
      record_check "Checklist failure comment count aligns with founder verification status" "true" "actual ${comments_failure_count}, expected ${expected_failure_comment_count}"
    else
      record_check "Checklist failure comment count aligns with founder verification status" "false" "actual ${comments_failure_count}, expected ${expected_failure_comment_count}"
    fi
  else
    if (( strict_mode == 1 )); then
      record_check "Live checklist issue checks" "false" "Issue number resolved but checklist comment checks were not performed."
    else
      record_check "Live checklist issue checks" "true" "Skipped issue comment checks."
    fi
  fi
else
  if (( strict_mode == 1 )); then
    record_check "Live checklist issue checks" "false" "Strict mode requires issue checks."
  else
    record_check "Live checklist issue checks" "true" "Skipped (no issue number)."
  fi
fi

if (( incident_checks_performed == 1 )); then
  if [[ "$open_incident_count" =~ ^[0-9]+$ ]]; then
    expected_open_incidents="0"
    if (( verification_failed == 1 )); then
      expected_open_incidents="1"
    fi
    if [[ "$open_incident_count" == "$expected_open_incidents" ]]; then
      record_check "Open founder incident count aligns with founder verification status" "true" "actual ${open_incident_count}, expected ${expected_open_incidents}"
    else
      record_check "Open founder incident count aligns with founder verification status" "false" "actual ${open_incident_count}, expected ${expected_open_incidents}"
    fi
  else
    record_check "Open founder incident count parsed" "false" "${open_incident_count}"
  fi

  if (( verification_failed == 1 )); then
    if [[ "$incident_primary_number" == "n/a" ]]; then
      record_check "Founder incident issue exists on failure" "false" "No incident issue found for week ${trace_week}."
    else
      record_check "Founder incident issue exists on failure" "true" "#${incident_primary_number}"
    fi
  else
    if [[ "$incident_primary_number" == "n/a" ]]; then
      record_check "Founder incident issue discovery" "true" "No incident issue found for week ${trace_week} (accepted on pass)."
    else
      record_check "Founder incident issue discovery" "true" "Latest incident #${incident_primary_number} (${incident_primary_state})."
    fi
  fi

  if [[ "$incident_primary_number" != "n/a" ]]; then
    if [[ "$incident_primary_failure_count" =~ ^[0-9]+$ ]]; then
      record_check "Founder incident failure count parsed" "true" "${incident_primary_failure_count}"
    else
      record_check "Founder incident failure count parsed" "false" "${incident_primary_failure_count}"
    fi

    if [[ "$incident_primary_critical_threshold" =~ ^[0-9]+$ ]]; then
      record_check "Founder incident critical threshold parsed" "true" "${incident_primary_critical_threshold}"
    else
      record_check "Founder incident critical threshold parsed" "false" "${incident_primary_critical_threshold}"
    fi

    if [[ "$incident_primary_critical_status" == "active" || "$incident_primary_critical_status" == "monitoring" ]]; then
      record_check "Founder incident critical status recognized" "true" "${incident_primary_critical_status}"
    else
      record_check "Founder incident critical status recognized" "false" "${incident_primary_critical_status}"
    fi

    if contains_csv_value "$incident_primary_labels_csv" "growth-incident"; then
      record_check "Founder incident has growth-incident label" "true" "${incident_primary_labels_csv}"
    else
      record_check "Founder incident has growth-incident label" "false" "${incident_primary_labels_csv}"
    fi

    if [[ "$incident_primary_critical_status" == "active" ]]; then
      if contains_csv_value "$incident_primary_labels_csv" "growth-critical"; then
        record_check "Founder incident has growth-critical label when critical is active" "true" "${incident_primary_labels_csv}"
      else
        record_check "Founder incident has growth-critical label when critical is active" "false" "${incident_primary_labels_csv}"
      fi

      if (( live_issue_checks_performed == 1 )); then
        if [[ "$comments_critical_count" == "1" ]]; then
          record_check "Founder critical checklist comment count aligns with active critical incident" "true" "actual ${comments_critical_count}, expected 1"
        else
          record_check "Founder critical checklist comment count aligns with active critical incident" "false" "actual ${comments_critical_count}, expected 1"
        fi
      fi
    elif [[ "$incident_primary_critical_status" == "monitoring" ]]; then
      if contains_csv_value "$incident_primary_labels_csv" "growth-critical"; then
        record_check "Founder incident removes growth-critical label when not active" "false" "${incident_primary_labels_csv}"
      else
        record_check "Founder incident removes growth-critical label when not active" "true" "${incident_primary_labels_csv}"
      fi

      if (( live_issue_checks_performed == 1 )); then
        if [[ "$comments_critical_count" == "0" ]]; then
          record_check "Founder critical checklist comment count aligns with monitoring incident" "true" "actual ${comments_critical_count}, expected 0"
        else
          record_check "Founder critical checklist comment count aligns with monitoring incident" "false" "actual ${comments_critical_count}, expected 0"
        fi
      fi
    fi
  fi
else
  if (( strict_mode == 1 )); then
    record_check "Founder incident issue checks" "false" "Strict mode requires incident reconciliation checks."
  else
    record_check "Founder incident issue checks" "true" "Skipped (repository unavailable or week unresolved)."
  fi
fi

if (( verification_failed == 0 )) && (( live_issue_checks_performed == 1 )); then
  if [[ "$comments_critical_count" == "0" ]]; then
    record_check "Founder critical checklist comments cleared on verification pass" "true" "actual ${comments_critical_count}, expected 0"
  else
    record_check "Founder critical checklist comments cleared on verification pass" "false" "actual ${comments_critical_count}, expected 0"
  fi
fi

verdict="PASS"
if (( failure_count > 0 )); then
  verdict="FAIL"
fi

cat > "$output_path" <<EOF
# Founder Proof Loop Live Verification: run ${run_id}

- Repository: ${repo_slug}
- Run ID: ${run_id}
- Run ID source: ${run_id_source}
- Issue number: ${issue_number:-n/a}
- Issue source: ${issue_source}
- Strict mode: $([[ "$strict_mode" == "1" ]] && echo "enabled" || echo "disabled")
- Mode: ${verification_mode}
- Founder check artifact: ${report_path}
- Run URL: ${run_url}

## Parsed Founder Fields

- Trace week: ${trace_week}
- Founder verification status: ${report_status}
- Founder verification failures: ${report_failures}
- Workflow name: ${run_name}
- Workflow event: ${run_event}
- Workflow status: ${run_status}
- Workflow conclusion: ${run_conclusion}
- Checklist failure comment marker count: ${comments_failure_count}
- Checklist critical comment marker count: ${comments_critical_count}
- Open founder incident count: ${open_incident_count}
- Primary founder incident number: ${incident_primary_number}
- Primary founder incident state: ${incident_primary_state}
- Primary founder incident failure count: ${incident_primary_failure_count}
- Primary founder incident critical threshold: ${incident_primary_critical_threshold}
- Primary founder incident critical status: ${incident_primary_critical_status}
- Primary founder incident labels: ${incident_primary_labels_csv}

## Verification Checks

${(F)check_items}

## Verdict

- Result: ${verdict}
- Failed checks: ${failure_count}
EOF

echo "Wrote founder proof-loop live verification report: $output_path"

if [[ -n "$download_cleanup_path" && "$keep_download" != "1" ]]; then
  rm -rf "$download_cleanup_path"
fi

if (( failure_count > 0 )); then
  exit 1
fi
