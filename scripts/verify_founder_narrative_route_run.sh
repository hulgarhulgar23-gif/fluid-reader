#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify live Weekly Growth Review founder narrative-route sync behavior.

Usage:
  zsh scripts/verify_founder_narrative_route_run.sh [options]

Options:
  --trace <path>               Founder narrative trace artifact path
  --repo <owner/repo>          Repository slug for GitHub live checks
  --checklist-issue <number>   Previous Monday checklist issue number
  --sprint-issue <number>      Weekly sprint issue number
  --review <path>              Weekly review markdown path
  --strict                     Fail when live issue checks cannot run
  --out <path>                 Output markdown report path
  --sample                     Run local sample verification without GitHub API calls
  -h, --help                   Show this help

Examples:
  zsh scripts/verify_founder_narrative_route_run.sh \
    --trace .build/growth/2026-W24-founder-narrative-route-trace.md \
    --repo your-org/your-repo \
    --checklist-issue 123 \
    --sprint-issue 456 \
    --review .build/growth/2026-W24-review.md \
    --strict

  zsh scripts/verify_founder_narrative_route_run.sh --sample
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

trace_path=""
repo_slug=""
checklist_issue_number=""
sprint_issue_number=""
review_path=""
output_path=""
strict_mode=0
sample_mode=0

while (( $# > 0 )); do
  case "$1" in
    --trace)
      trace_path="${2:-}"
      shift 2
      ;;
    --repo)
      repo_slug="${2:-}"
      shift 2
      ;;
    --checklist-issue)
      checklist_issue_number="${2:-}"
      shift 2
      ;;
    --sprint-issue)
      sprint_issue_number="${2:-}"
      shift 2
      ;;
    --review)
      review_path="${2:-}"
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

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  echo "$value"
}

lowercase_value() {
  print -r -- "${1:-}" | tr '[:upper:]' '[:lower:]'
}

extract_trace_field() {
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

is_present() {
  local value="$1"
  local lowered
  lowered="$(lowercase_value "$value")"
  [[ -n "$value" && "$lowered" != "n/a" && "$lowered" != "none" && "$lowered" != "unknown" ]]
}

check_items=()
failure_count=0

record_check() {
  local label="$1"
  local is_ok="$2"
  local detail="$3"
  local icon="✅"
  if [[ "$is_ok" != "true" ]]; then
    icon="❌"
    failure_count=$((failure_count + 1))
  fi
  check_items+=("- ${icon} ${label}: ${detail}")
}

if (( sample_mode == 1 )); then
  strict_mode=0
  sample_suffix="$(date '+%Y%m%d-%H%M%S')"
  mkdir -p ".build/growth"
  trace_path=".build/growth/sample-founder-narrative-route-trace-${sample_suffix}.md"
  review_path=".build/growth/sample-founder-review-${sample_suffix}.md"
  cat > "$trace_path" <<'EOF'
<!-- weekly-growth-founder-narrative-route-trace -->
# Founder Narrative Route Trace: sample

## Source Snapshot

- Source week: 2026-W24
- Checklist issue number: 101
- Sprint issue number: 55
- Review artifact path: .build/growth/sample-founder-review.md

## Parsed Narrative Outputs

- Founder narrative route winner: Behind-the-scenes route
- Founder narrative route winner delta: Proof-first route -> Behind-the-scenes route
- Founder narrative route trend: shifted from Proof-first route to Behind-the-scenes route
- Founder narrative fame velocity score: 78%
- Founder narrative fame velocity score delta: +14pp
- Founder narrative launch posture: Stabilize and scale
- Founder narrative route mode: Route Re-Lock
- Founder narrative route alignment target: Aligned by Day 1
- Founder narrative route lane status: Watch
- Founder narrative route guardrail: Keep every route update tied to one measurable proof artifact.
- Founder narrative next standup action: Log one route winner and one failed route in standup notes.
- Founder narrative route control recommendation: Re-lock winner, execution mode, and opportunity before next publish.
- Founder narrative recommendation: Keep Behind-the-scenes route as lead narrative route and scale it across both channels while preserving proof guardrails.
- Founder narrative distribution strategy: Re-lock cadence: lead with winner reinforcement, follow with conversion proof.
- Founder narrative Day 0 lead lane: X / Threads (Global, 13:00 UTC)
- Founder narrative Day 0 support lane: LinkedIn (US, 15:00-17:00 local)
- Founder narrative distribution recommendation: Run re-lock cadence with Day 0 lead X / Threads and support LinkedIn for confidence reinforcement.
- Founder narrative first 48h execution plan: Day 0: lead with winner re-lock post on X / Threads. Day 1: reinforce confidence with replies on LinkedIn. Day 2: publish one proof-backed winner recap.
EOF

  cat > "$review_path" <<'EOF'
<!-- weekly-growth-review -->
# Weekly Growth Review

### Founder Narrative Route Signals

- Founder narrative route winner: Behind-the-scenes route (Δ Proof-first route -> Behind-the-scenes route)
- Founder narrative route trend: shifted from Proof-first route to Behind-the-scenes route
- Founder narrative route mode: Route Re-Lock
- Founder narrative route lane status: Watch
- Founder narrative route control recommendation: Re-lock winner, execution mode, and opportunity before next publish.
- Founder narrative recommendation: Keep Behind-the-scenes route as lead narrative route and scale it across both channels while preserving proof guardrails.
- Founder narrative distribution strategy: Re-lock cadence: lead with winner reinforcement, follow with conversion proof.
- Founder narrative Day 0 lead lane: X / Threads (Global, 13:00 UTC)
- Founder narrative Day 0 support lane: LinkedIn (US, 15:00-17:00 local)
- Founder narrative distribution recommendation: Run re-lock cadence with Day 0 lead X / Threads and support LinkedIn for confidence reinforcement.
- Founder narrative first 48h execution plan: Day 0: lead with winner re-lock post on X / Threads. Day 1: reinforce confidence with replies on LinkedIn. Day 2: publish one proof-backed winner recap.
EOF
fi

if [[ -z "$trace_path" || ! -f "$trace_path" ]]; then
  echo "Founder narrative route trace artifact not found. Pass --trace <path>." >&2
  exit 1
fi

trace_marker='<!-- weekly-growth-founder-narrative-route-trace -->'
if rg -Fq -- "$trace_marker" "$trace_path"; then
  record_check "Trace marker" "true" "found ${trace_marker}"
else
  record_check "Trace marker" "false" "missing ${trace_marker}"
fi

source_week="$(extract_trace_field "$trace_path" "Source week")"
trace_checklist_issue="$(extract_trace_field "$trace_path" "Checklist issue number")"
trace_sprint_issue="$(extract_trace_field "$trace_path" "Sprint issue number")"
trace_review_path="$(extract_trace_field "$trace_path" "Review artifact path")"
narrative_route_winner="$(extract_trace_field "$trace_path" "Founder narrative route winner")"
narrative_route_winner_delta="$(extract_trace_field "$trace_path" "Founder narrative route winner delta")"
narrative_route_trend="$(extract_trace_field "$trace_path" "Founder narrative route trend")"
narrative_fame_velocity_score="$(extract_trace_field "$trace_path" "Founder narrative fame velocity score")"
narrative_launch_posture="$(extract_trace_field "$trace_path" "Founder narrative launch posture")"
narrative_route_mode="$(extract_trace_field "$trace_path" "Founder narrative route mode")"
narrative_route_alignment_target="$(extract_trace_field "$trace_path" "Founder narrative route alignment target")"
narrative_route_lane_status="$(extract_trace_field "$trace_path" "Founder narrative route lane status")"
narrative_route_guardrail="$(extract_trace_field "$trace_path" "Founder narrative route guardrail")"
narrative_next_standup_action="$(extract_trace_field "$trace_path" "Founder narrative next standup action")"
narrative_route_control_recommendation="$(extract_trace_field "$trace_path" "Founder narrative route control recommendation")"
narrative_route_recommendation="$(extract_trace_field "$trace_path" "Founder narrative recommendation")"
narrative_distribution_strategy="$(extract_trace_field "$trace_path" "Founder narrative distribution strategy")"
narrative_distribution_day0_lead="$(extract_trace_field "$trace_path" "Founder narrative Day 0 lead lane")"
narrative_distribution_day0_support="$(extract_trace_field "$trace_path" "Founder narrative Day 0 support lane")"
narrative_distribution_recommendation="$(extract_trace_field "$trace_path" "Founder narrative distribution recommendation")"
narrative_distribution_first_48h_plan="$(extract_trace_field "$trace_path" "Founder narrative first 48h execution plan")"

if [[ -z "$checklist_issue_number" || "$checklist_issue_number" == "n/a" ]]; then
  checklist_issue_number="$trace_checklist_issue"
fi
if [[ -z "$sprint_issue_number" || "$sprint_issue_number" == "n/a" ]]; then
  sprint_issue_number="$trace_sprint_issue"
fi
if [[ -z "$review_path" || "$review_path" == "n/a" ]]; then
  review_path="$trace_review_path"
fi

if is_present "$narrative_route_winner"; then
  if is_present "$narrative_route_trend" && is_present "$narrative_route_recommendation" && is_present "$narrative_route_mode" && is_present "$narrative_route_lane_status" && is_present "$narrative_distribution_recommendation" && is_present "$narrative_distribution_first_48h_plan"; then
    record_check "Parsed narrative outputs" "true" "winner=${narrative_route_winner}, trend=${narrative_route_trend}, mode=${narrative_route_mode}, distribution=${narrative_distribution_strategy}"
  else
    record_check "Parsed narrative outputs" "false" "winner present but trend/recommendation/mode/lane-status/distribution recommendation/first-48h plan missing"
  fi
else
  if [[ "$narrative_route_recommendation" == *"Capture founder fame narrative lab comment"* ]]; then
    record_check "Parsed narrative outputs" "true" "winner missing with capture recommendation fallback"
  else
    record_check "Parsed narrative outputs" "false" "winner missing without fallback recommendation"
  fi
fi

if [[ -n "$review_path" && "$review_path" != "n/a" && -f "$review_path" ]]; then
  review_heading='### Founder Narrative Route Signals'
  if rg -Fq -- "$review_heading" "$review_path"; then
    record_check "Review section heading" "true" "found ${review_heading}"
  else
    record_check "Review section heading" "false" "missing ${review_heading}"
  fi

  for required_line in \
    "- Founder narrative route winner:" \
    "- Founder narrative route trend:" \
    "- Founder narrative route mode:" \
    "- Founder narrative route control recommendation:" \
    "- Founder narrative recommendation:" \
    "- Founder narrative distribution strategy:" \
    "- Founder narrative distribution recommendation:" \
    "- Founder narrative first 48h execution plan:"; do
    if rg -Fq -- "$required_line" "$review_path"; then
      record_check "Review field ${required_line}" "true" "present"
    else
      record_check "Review field ${required_line}" "false" "missing"
    fi
  done

  if is_present "$narrative_route_winner"; then
    if rg -Fq -- "$narrative_route_winner" "$review_path"; then
      record_check "Review winner value" "true" "winner value propagated"
    else
      record_check "Review winner value" "false" "winner value not found in review"
    fi
  else
    record_check "Review winner value" "true" "skipped because winner is n/a"
  fi
else
  detail="review artifact unavailable (${review_path:-n/a})"
  if (( strict_mode == 1 )); then
    record_check "Review artifact check" "false" "$detail"
  else
    record_check "Review artifact check" "true" "skipped: ${detail}"
  fi
fi

can_run_live_checks=1
if (( sample_mode == 1 )); then
  can_run_live_checks=0
elif [[ -z "$repo_slug" || "$repo_slug" == "n/a" ]]; then
  can_run_live_checks=0
elif ! command -v gh >/dev/null 2>&1; then
  can_run_live_checks=0
fi

if (( can_run_live_checks == 1 )) && is_present "$checklist_issue_number"; then
  checklist_comments="$(gh issue view "$checklist_issue_number" --repo "$repo_slug" --json comments --jq '.comments[].body' 2>/dev/null || true)"
  if [[ -z "$checklist_comments" ]]; then
    detail="unable to fetch checklist comments for issue #${checklist_issue_number}"
    if (( strict_mode == 1 )); then
      record_check "Checklist narrative marker" "false" "$detail"
    else
      record_check "Checklist narrative marker" "true" "skipped: ${detail}"
    fi
  else
    checklist_marker='<!-- weekly-growth-founder-fame-narrative-lab -->'
    if print -r -- "$checklist_comments" | rg -Fq -- "$checklist_marker"; then
      record_check "Checklist narrative marker" "true" "found ${checklist_marker}"
    else
      record_check "Checklist narrative marker" "false" "missing ${checklist_marker}"
    fi

    if print -r -- "$checklist_comments" | rg -Fq -- "- Priority route:"; then
      record_check "Checklist priority route field" "true" "present"
    else
      record_check "Checklist priority route field" "false" "missing"
    fi

    if print -r -- "$checklist_comments" | rg -Fq -- "- Fame velocity score:"; then
      record_check "Checklist fame velocity field" "true" "present"
    else
      record_check "Checklist fame velocity field" "false" "missing"
    fi

    if print -r -- "$checklist_comments" | rg -Fq -- "- Route lab mode:"; then
      record_check "Checklist route mode field" "true" "present"
    else
      record_check "Checklist route mode field" "false" "missing"
    fi

    if print -r -- "$checklist_comments" | rg -Fq -- "- Distribution strategy:"; then
      record_check "Checklist distribution strategy field" "true" "present"
    else
      record_check "Checklist distribution strategy field" "false" "missing"
    fi

    if print -r -- "$checklist_comments" | rg -Fq -- "- First 48h execution plan:"; then
      record_check "Checklist first-48h execution plan field" "true" "present"
    else
      record_check "Checklist first-48h execution plan field" "false" "missing"
    fi

    if print -r -- "$checklist_comments" | rg -Fq -- "| Day 0 |"; then
      record_check "Checklist Day 0 calendar row" "true" "present"
    else
      record_check "Checklist Day 0 calendar row" "false" "missing"
    fi
  fi
else
  detail="live checklist check unavailable (repo=${repo_slug:-n/a}, issue=${checklist_issue_number:-n/a})"
  if (( strict_mode == 1 )); then
    record_check "Checklist narrative marker" "false" "$detail"
  else
    record_check "Checklist narrative marker" "true" "skipped: ${detail}"
  fi
fi

if (( can_run_live_checks == 1 )) && is_present "$sprint_issue_number"; then
  sprint_body="$(gh issue view "$sprint_issue_number" --repo "$repo_slug" --json body --jq '.body' 2>/dev/null || true)"
  if [[ -z "$sprint_body" ]]; then
    detail="unable to fetch sprint issue body for #${sprint_issue_number}"
    if (( strict_mode == 1 )); then
      record_check "Sprint sync block" "false" "$detail"
    else
      record_check "Sprint sync block" "true" "skipped: ${detail}"
    fi
  else
    sprint_marker='<!-- weekly-growth-reply-effectiveness -->'
    if print -r -- "$sprint_body" | rg -Fq -- "$sprint_marker"; then
      record_check "Sprint sync marker" "true" "found ${sprint_marker}"
    else
      record_check "Sprint sync marker" "false" "missing ${sprint_marker}"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative route winner: ${narrative_route_winner}"; then
      record_check "Sprint route winner field" "true" "winner value synced"
    else
      record_check "Sprint route winner field" "false" "winner value missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative route trend: ${narrative_route_trend}"; then
      record_check "Sprint route trend field" "true" "trend value synced"
    else
      record_check "Sprint route trend field" "false" "trend value missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative route mode: ${narrative_route_mode}"; then
      record_check "Sprint route mode field" "true" "mode value synced"
    else
      record_check "Sprint route mode field" "false" "mode value missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative recommendation: ${narrative_route_recommendation}"; then
      record_check "Sprint route recommendation field" "true" "recommendation synced"
    else
      record_check "Sprint route recommendation field" "false" "recommendation missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative route control recommendation: ${narrative_route_control_recommendation}"; then
      record_check "Sprint route control recommendation field" "true" "control recommendation synced"
    else
      record_check "Sprint route control recommendation field" "false" "control recommendation missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative distribution strategy: ${narrative_distribution_strategy}"; then
      record_check "Sprint distribution strategy field" "true" "distribution strategy synced"
    else
      record_check "Sprint distribution strategy field" "false" "distribution strategy missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative distribution recommendation: ${narrative_distribution_recommendation}"; then
      record_check "Sprint distribution recommendation field" "true" "distribution recommendation synced"
    else
      record_check "Sprint distribution recommendation field" "false" "distribution recommendation missing or stale"
    fi

    if print -r -- "$sprint_body" | rg -Fq -- "- Founder narrative first 48h execution plan: ${narrative_distribution_first_48h_plan}"; then
      record_check "Sprint distribution first-48h plan field" "true" "first-48h plan synced"
    else
      record_check "Sprint distribution first-48h plan field" "false" "first-48h plan missing or stale"
    fi
  fi
else
  detail="live sprint check unavailable (repo=${repo_slug:-n/a}, issue=${sprint_issue_number:-n/a})"
  if (( strict_mode == 1 )); then
    record_check "Sprint sync block" "false" "$detail"
  else
    record_check "Sprint sync block" "true" "skipped: ${detail}"
  fi
fi

report_status="PASS"
if (( failure_count > 0 )); then
  report_status="FAIL"
fi

if [[ -z "$output_path" ]]; then
  week_slug="$source_week"
  if [[ -z "$week_slug" || "$week_slug" == "n/a" ]]; then
    week_slug="unknown-week"
  fi
  output_path=".build/growth/${week_slug}-founder-narrative-route-live-check.md"
fi

mkdir -p "$(dirname "$output_path")"
{
  echo "<!-- weekly-growth-founder-narrative-route-live-check -->"
  echo "# Founder Narrative Route Live Check"
  echo
  echo "- Status: ${report_status}"
  echo "- Strict mode: $([[ "$strict_mode" == "1" ]] && echo "true" || echo "false")"
  echo "- Source week: ${source_week:-n/a}"
  echo "- Trace artifact: ${trace_path}"
  echo "- Review artifact: ${review_path:-n/a}"
  echo "- Repo: ${repo_slug:-n/a}"
  echo "- Checklist issue: ${checklist_issue_number:-n/a}"
  echo "- Sprint issue: ${sprint_issue_number:-n/a}"
  echo "- Failure count: ${failure_count}"
  echo
  echo "## Parsed Values"
  echo
  echo "- Route winner: ${narrative_route_winner}"
  echo "- Route winner delta: ${narrative_route_winner_delta}"
  echo "- Route trend: ${narrative_route_trend}"
  echo "- Fame velocity score: ${narrative_fame_velocity_score}"
  echo "- Launch posture: ${narrative_launch_posture}"
  echo "- Route mode: ${narrative_route_mode}"
  echo "- Route alignment target: ${narrative_route_alignment_target}"
  echo "- Route lane status: ${narrative_route_lane_status}"
  echo "- Route guardrail: ${narrative_route_guardrail}"
  echo "- Next standup action: ${narrative_next_standup_action}"
  echo "- Route control recommendation: ${narrative_route_control_recommendation}"
  echo "- Recommendation: ${narrative_route_recommendation}"
  echo "- Distribution strategy: ${narrative_distribution_strategy}"
  echo "- Distribution Day 0 lead lane: ${narrative_distribution_day0_lead}"
  echo "- Distribution Day 0 support lane: ${narrative_distribution_day0_support}"
  echo "- Distribution recommendation: ${narrative_distribution_recommendation}"
  echo "- Distribution first 48h execution plan: ${narrative_distribution_first_48h_plan}"
  echo
  echo "## Checks"
  echo
  printf '%s\n' "${check_items[@]}"
} > "$output_path"

echo "Founder narrative route live check report: $output_path"

if (( failure_count > 0 )); then
  echo "Founder narrative route live verification failed with ${failure_count} issue(s)." >&2
  exit 1
fi
