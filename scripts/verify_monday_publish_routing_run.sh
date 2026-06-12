#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Verify Monday publish routing consistency from checklist/review artifacts or live issue data.

Usage:
  zsh scripts/verify_monday_publish_routing_run.sh [options]

Options:
  --checklist <path>           Local Monday publish checklist markdown path
  --review <path>              Weekly review markdown path (optional, enables script parity checks)
  --repo <owner/repo>          Repository slug for live issue fetch
  --issue <number>             Monday publish checklist issue number for live checks
  --strict                     Fail when required live checks cannot run
  --out <path>                 Output markdown report path
  --sample                     Run local sample verification without GitHub API calls
  -h, --help                   Show this help

Examples:
  zsh scripts/verify_monday_publish_routing_run.sh \
    --checklist .build/growth/2026-W24-monday-publish-checklist.md \
    --review .build/growth/2026-W24-review.md \
    --strict

  zsh scripts/verify_monday_publish_routing_run.sh \
    --repo your-org/your-repo \
    --issue 123 \
    --review .build/growth/2026-W24-review.md \
    --strict

  zsh scripts/verify_monday_publish_routing_run.sh --sample
EOF
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

checklist_path=""
review_path=""
repo_slug=""
issue_number=""
output_path=""
strict_mode=0
sample_mode=0

while (( $# > 0 )); do
  case "$1" in
    --checklist)
      checklist_path="${2:-}"
      shift 2
      ;;
    --review)
      review_path="${2:-}"
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

is_present() {
  local value="$1"
  local lowered
  lowered="$(lowercase_value "$value")"
  [[ -n "$value" && "$lowered" != "n/a" && "$lowered" != "none" && "$lowered" != "unknown" ]]
}

extract_bullet_field_from_text() {
  local text="$1"
  local label="$2"
  local line
  line="$(print -r -- "$text" | rg -m1 -F -- "- ${label}: " || true)"
  if [[ -z "$line" ]]; then
    echo "n/a"
    return
  fi
  line="$(trim_value "$line")"
  trim_value "${line#"- ${label}: "}"
}

extract_line_from_text() {
  local text="$1"
  local needle="$2"
  local line
  line="$(print -r -- "$text" | rg -m1 -F -- "$needle" || true)"
  trim_value "$line"
}

extract_code_block_after_anchor() {
  local text="$1"
  local anchor="$2"
  print -r -- "$text" | awk -v anchor="$anchor" '
    seen == 0 && index($0, anchor) > 0 { seen = 1; next }
    seen == 1 && $0 ~ /^```text[[:space:]]*$/ { block = 1; next }
    block == 1 && $0 ~ /^```[[:space:]]*$/ { exit }
    block == 1 { print }
  '
}

extract_channel_from_default_draft_line() {
  local line="$1"
  print -r -- "$line" | sed -nE 's/^- (Primary|Backup) default draft:[[:space:]]*(.+)[[:space:]]+\(Variant[[:space:]]+([A-C]|n\/a)\)[[:space:]]*$/\2/p'
}

extract_variant_from_default_draft_line() {
  local line="$1"
  print -r -- "$line" | sed -nE 's/^- (Primary|Backup) default draft:[[:space:]]*(.+)[[:space:]]+\(Variant[[:space:]]+([A-C]|n\/a)\)[[:space:]]*$/\3/p'
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

if (( sample_mode == 1 )) && [[ -n "$checklist_path" || -n "$review_path" || -n "$issue_number" ]]; then
  echo "--sample cannot be combined with --checklist, --review, or --issue." >&2
  exit 1
fi

mode="live"
checklist_source="issue"
if (( sample_mode == 1 )); then
  mode="sample"
  checklist_source="sample"
elif [[ -n "$checklist_path" ]]; then
  mode="checklist"
  checklist_source="file"
fi

if [[ -n "$issue_number" && ! "$issue_number" =~ ^[0-9]+$ ]]; then
  echo "--issue must be numeric. Received: $issue_number" >&2
  exit 1
fi

if (( sample_mode == 0 )) && [[ -z "$repo_slug" ]]; then
  repo_slug="$(detect_repo_slug)"
fi

if [[ "$mode" == "live" ]]; then
  if [[ -z "$repo_slug" || "$repo_slug" == "n/a" ]]; then
    echo "Unable to infer --repo from git remote/env. Pass --repo <owner/repo>." >&2
    exit 1
  fi
  if [[ -z "$issue_number" ]]; then
    if (( strict_mode == 1 )); then
      echo "--strict live mode requires --issue <number>." >&2
      exit 1
    fi
  fi
fi

if (( sample_mode == 1 )); then
  mkdir -p ".build/growth"
  sample_suffix="$(date '+%Y%m%d-%H%M%S')"
  checklist_path=".build/growth/sample-monday-publish-checklist-${sample_suffix}.md"
  review_path=".build/growth/sample-weekly-review-${sample_suffix}.md"

  cat > "$review_path" <<'EOF'
<!-- weekly-growth-review -->
# Weekly Growth Review

### Next-Week Channel Scripts

- Primary channel (`X / Threads`): Variant A

```text
REVIEW PRIMARY SCRIPT A
```

- Backup channel (`LinkedIn`): Variant B

```text
REVIEW BACKUP SCRIPT B
```

- Next-week variant recommendation: Lead with proof-first route while monitoring reply quality.
EOF

  cat > "$checklist_path" <<'EOF'
<!-- weekly-growth-monday-publish-checklist -->
# Monday Publish Checklist: 2099-W01

## First 24-Hour Reply Effectiveness

- Channel ROI preferred channel: backup
- Founder narrative preferred variant: A
- Founder narrative routing action: promoted-backup-to-primary

## Default Publish Drafts (Auto-Promoted)

- Source review artifact: .build/growth/sample-weekly-review.md [ROI lead: backup] [Narrative lead: Variant A]
- Primary default draft: X / Threads (Variant A)

```text
REVIEW PRIMARY SCRIPT A
```

- Backup default draft: LinkedIn (Variant B)

```text
REVIEW BACKUP SCRIPT B
```
EOF
fi

checklist_body=""
if [[ "$mode" == "live" ]]; then
  if command -v gh >/dev/null 2>&1 && [[ -n "$issue_number" ]]; then
    checklist_body="$(gh issue view "$issue_number" --repo "$repo_slug" --json body --jq '.body' 2>/dev/null || true)"
  fi
else
  if [[ -z "$checklist_path" || ! -f "$checklist_path" ]]; then
    echo "Checklist markdown not found: ${checklist_path:-n/a}" >&2
    exit 1
  fi
  checklist_body="$(cat "$checklist_path")"
fi

if [[ -z "$checklist_body" ]]; then
  checklist_body=""
fi

if [[ -n "$checklist_body" ]]; then
  if print -r -- "$checklist_body" | rg -Fq -- "<!-- weekly-growth-monday-publish-checklist -->"; then
    record_check "Checklist marker" "true" "weekly-growth-monday-publish-checklist marker found"
  else
    record_check "Checklist marker" "false" "weekly-growth-monday-publish-checklist marker missing"
  fi

  if print -r -- "$checklist_body" | rg -Fq -- "## Default Publish Drafts (Auto-Promoted)"; then
    record_check "Checklist default drafts section" "true" "section present"
  else
    record_check "Checklist default drafts section" "false" "section missing"
  fi
else
  record_check "Checklist marker" "$([[ "$strict_mode" == "1" ]] && echo false || echo true)" "skipped: checklist body unavailable"
  record_check "Checklist default drafts section" "$([[ "$strict_mode" == "1" ]] && echo false || echo true)" "skipped: checklist body unavailable"
fi

checklist_body_available=0
if [[ -n "$checklist_body" ]]; then
  checklist_body_available=1
fi

channel_roi_preferred_channel="n/a"
narrative_preferred_variant="n/a"
narrative_routing_action="n/a"
source_review_artifact="n/a"
primary_default_line=""
backup_default_line=""
primary_default_channel=""
primary_default_variant=""
backup_default_channel=""
backup_default_variant=""
primary_default_script=""
backup_default_script=""

if (( checklist_body_available == 1 )); then
  channel_roi_preferred_channel="$(extract_bullet_field_from_text "$checklist_body" "Channel ROI preferred channel")"
  narrative_preferred_variant="$(extract_bullet_field_from_text "$checklist_body" "Founder narrative preferred variant")"
  narrative_routing_action="$(extract_bullet_field_from_text "$checklist_body" "Founder narrative routing action")"
  source_review_artifact="$(extract_bullet_field_from_text "$checklist_body" "Source review artifact")"

  primary_default_line="$(extract_line_from_text "$checklist_body" "- Primary default draft:")"
  backup_default_line="$(extract_line_from_text "$checklist_body" "- Backup default draft:")"
  primary_default_channel="$(extract_channel_from_default_draft_line "$primary_default_line")"
  primary_default_variant="$(extract_variant_from_default_draft_line "$primary_default_line")"
  backup_default_channel="$(extract_channel_from_default_draft_line "$backup_default_line")"
  backup_default_variant="$(extract_variant_from_default_draft_line "$backup_default_line")"
  primary_default_script="$(trim_value "$(extract_code_block_after_anchor "$checklist_body" "- Primary default draft:")")"
  backup_default_script="$(trim_value "$(extract_code_block_after_anchor "$checklist_body" "- Backup default draft:")")"

  if is_present "$channel_roi_preferred_channel"; then
    record_check "Channel ROI preferred channel parsed" "true" "$channel_roi_preferred_channel"
  else
    record_check "Channel ROI preferred channel parsed" "false" "$channel_roi_preferred_channel"
  fi

  if is_present "$narrative_preferred_variant"; then
    if [[ "$narrative_preferred_variant" == [ABC] || "$(lowercase_value "$narrative_preferred_variant")" == "n/a" ]]; then
      record_check "Narrative preferred variant parsed" "true" "$narrative_preferred_variant"
    else
      record_check "Narrative preferred variant parsed" "false" "$narrative_preferred_variant"
    fi
  else
    record_check "Narrative preferred variant parsed" "false" "$narrative_preferred_variant"
  fi

  if [[ -n "$primary_default_variant" && -n "$backup_default_variant" ]]; then
    record_check "Default draft variant lines parsed" "true" "primary=${primary_default_variant}, backup=${backup_default_variant}"
  else
    record_check "Default draft variant lines parsed" "false" "primary line=${primary_default_line:-n/a}; backup line=${backup_default_line:-n/a}"
  fi

  if [[ -n "$primary_default_script" && -n "$backup_default_script" ]]; then
    record_check "Default draft script blocks parsed" "true" "primary/backup script blocks present"
  else
    record_check "Default draft script blocks parsed" "false" "missing primary or backup default script block"
  fi

  if is_present "$source_review_artifact"; then
    record_check "Source review artifact parsed" "true" "$source_review_artifact"
  else
    record_check "Source review artifact parsed" "false" "$source_review_artifact"
  fi

  roi_preference_lower="$(lowercase_value "$channel_roi_preferred_channel")"
  if [[ "$roi_preference_lower" == "backup" ]]; then
    if [[ "$source_review_artifact" == *"[ROI lead: backup]"* ]]; then
      record_check "ROI backup source annotation" "true" "source contains [ROI lead: backup]"
    else
      record_check "ROI backup source annotation" "false" "missing [ROI lead: backup] annotation"
    fi
  elif [[ "$roi_preference_lower" == "primary" ]]; then
    if [[ "$source_review_artifact" == *"[ROI lead: primary]"* ]]; then
      record_check "ROI primary source annotation" "true" "source contains [ROI lead: primary]"
    else
      record_check "ROI primary source annotation" "false" "missing [ROI lead: primary] annotation"
    fi
  else
    record_check "ROI source annotation" "true" "no strict ROI annotation requirement for preference=${channel_roi_preferred_channel:-n/a}"
  fi

  narrative_action_lower="$(lowercase_value "$narrative_routing_action")"
  narrative_variant_normalized="$(trim_value "$narrative_preferred_variant")"

  case "$narrative_action_lower" in
    already-primary)
      if [[ "$primary_default_variant" == "$narrative_variant_normalized" && "$source_review_artifact" == *"[Narrative lead confirmed: Variant ${narrative_variant_normalized}]"* ]]; then
        record_check "Narrative already-primary routing consistency" "true" "primary variant and source annotation align"
      else
        record_check "Narrative already-primary routing consistency" "false" "expected primary variant=${narrative_variant_normalized} and confirmed source annotation"
      fi
      ;;
    promoted-backup-to-primary)
      if [[ "$primary_default_variant" == "$narrative_variant_normalized" && "$source_review_artifact" == *"[Narrative lead: Variant ${narrative_variant_normalized}]"* ]]; then
        record_check "Narrative promoted-backup routing consistency" "true" "primary variant and source annotation align"
      else
        record_check "Narrative promoted-backup routing consistency" "false" "expected promoted-backup variant/source annotation alignment"
      fi
      ;;
    forced-primary-variant)
      if [[ "$primary_default_variant" == "$narrative_variant_normalized" && "$source_review_artifact" == *"[Narrative override: Variant ${narrative_variant_normalized}]"* ]]; then
        record_check "Narrative forced-primary routing consistency" "true" "primary variant and override source annotation align"
      else
        record_check "Narrative forced-primary routing consistency" "false" "expected forced-primary variant/source annotation alignment"
      fi
      ;;
    watchlist-only)
      if [[ "$source_review_artifact" == *"[Narrative"* ]]; then
        record_check "Narrative watchlist routing consistency" "false" "watchlist should not include narrative source override annotations"
      else
        record_check "Narrative watchlist routing consistency" "true" "no narrative override annotation present"
      fi
      ;;
    not-applied)
      if [[ "$(lowercase_value "$narrative_variant_normalized")" == "n/a" ]]; then
        record_check "Narrative not-applied routing consistency" "true" "narrative variant is n/a"
      else
        record_check "Narrative not-applied routing consistency" "false" "not-applied expects narrative variant n/a"
      fi
      ;;
    *)
      record_check "Narrative routing action recognized" "false" "$narrative_routing_action"
      ;;
  esac
else
  record_check "Routing field parsing" "true" "skipped: checklist body unavailable"
  record_check "Routing consistency checks" "true" "skipped: checklist body unavailable"
fi

review_mode="unavailable"
review_primary_script=""
review_backup_script=""

if [[ -n "$review_path" ]]; then
  if [[ -f "$review_path" ]]; then
    review_mode="file"
    review_body="$(cat "$review_path")"
    review_primary_script="$(trim_value "$(extract_code_block_after_anchor "$review_body" "- Primary channel")")"
    review_backup_script="$(trim_value "$(extract_code_block_after_anchor "$review_body" "- Backup channel")")"

    if print -r -- "$review_body" | rg -Fq -- "### Next-Week Channel Scripts"; then
      record_check "Review scripts section heading" "true" "present"
    else
      record_check "Review scripts section heading" "false" "missing"
    fi

    if [[ -n "$review_primary_script" && -n "$review_backup_script" ]]; then
      record_check "Review script blocks parsed" "true" "primary and backup scripts parsed"
    else
      record_check "Review script blocks parsed" "false" "missing primary or backup script block"
    fi

    if (( checklist_body_available == 1 )); then
      if [[ -n "$primary_default_script" && -n "$review_primary_script" && -n "$review_backup_script" ]]; then
        if [[ "$primary_default_script" == "$review_primary_script" || "$primary_default_script" == "$review_backup_script" ]]; then
          record_check "Primary default script parity with review" "true" "primary default matches one promoted review script"
        else
          record_check "Primary default script parity with review" "false" "primary default script mismatch vs promoted review scripts"
        fi
      else
        record_check "Primary default script parity with review" "false" "insufficient primary script data for parity check"
      fi
      if [[ -n "$backup_default_script" && -n "$review_primary_script" && -n "$review_backup_script" ]]; then
        if [[ "$backup_default_script" == "$review_primary_script" || "$backup_default_script" == "$review_backup_script" ]]; then
          record_check "Backup default script parity with review" "true" "backup default matches one promoted review script"
        else
          record_check "Backup default script parity with review" "false" "backup default script mismatch vs promoted review scripts"
        fi
      else
        record_check "Backup default script parity with review" "false" "insufficient backup script data for parity check"
      fi
    else
      record_check "Primary default script parity with review" "true" "skipped: checklist body unavailable"
      record_check "Backup default script parity with review" "true" "skipped: checklist body unavailable"
    fi
  else
    detail="review file not found (${review_path})"
    if (( strict_mode == 1 )); then
      record_check "Review artifact availability" "false" "$detail"
    else
      record_check "Review artifact availability" "true" "skipped: ${detail}"
    fi
  fi
else
  record_check "Review artifact availability" "true" "skipped: no --review path provided"
fi

verdict="PASS"
if (( failure_count > 0 )); then
  verdict="FAIL"
fi

if [[ -z "$output_path" ]]; then
  output_path=".build/growth/monday-publish-routing-live-check.md"
fi

mkdir -p "$(dirname "$output_path")"
{
  echo "<!-- weekly-growth-monday-publish-routing-live-check -->"
  echo "# Monday Publish Routing Live Verification"
  echo
  echo "- Repository: ${repo_slug:-n/a}"
  echo "- Issue number: ${issue_number:-n/a}"
  echo "- Strict mode: $([[ "$strict_mode" == "1" ]] && echo "enabled" || echo "disabled")"
  echo "- Mode: ${mode}"
  echo "- Checklist source: ${checklist_source}"
  echo "- Checklist artifact: ${checklist_path:-n/a}"
  echo "- Review artifact: ${review_path:-n/a}"
  echo
  echo "## Parsed Routing Fields"
  echo
  echo "- Channel ROI preferred channel: ${channel_roi_preferred_channel}"
  echo "- Narrative preferred variant: ${narrative_preferred_variant}"
  echo "- Narrative routing action: ${narrative_routing_action}"
  echo "- Source review artifact: ${source_review_artifact}"
  echo "- Primary default channel: ${primary_default_channel:-n/a}"
  echo "- Primary default variant: ${primary_default_variant:-n/a}"
  echo "- Backup default channel: ${backup_default_channel:-n/a}"
  echo "- Backup default variant: ${backup_default_variant:-n/a}"
  echo "- Review parse mode: ${review_mode}"
  echo
  echo "## Verification Checks"
  echo
  printf '%s\n' "${check_items[@]}"
  echo
  echo "## Verdict"
  echo
  echo "- Result: ${verdict}"
  echo "- Failed checks: ${failure_count}"
} > "$output_path"

echo "Wrote Monday publish routing live verification report: $output_path"

if (( failure_count > 0 )); then
  exit 1
fi
