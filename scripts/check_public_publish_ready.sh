#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

SUBMISSION_DOC="$ROOT_DIR/docs/SUBMISSION.md"

repo_url="$(awk '
  /^## Repository$/ { in_repo = 1; next }
  in_repo && /^https:\/\/github.com\// { print; exit }
' "$SUBMISSION_DOC")"

if [[ -z "$repo_url" ]]; then
  echo "Submission doc must include a GitHub repository URL."
  exit 1
fi

repo_path="${repo_url#https://github.com/}"
repo_path="${repo_path%.git}"
repo_path="${repo_path%/}"

remote_url="$(git remote get-url origin)"
normalized_remote="${remote_url%.git}"
normalized_repo="${repo_url%.git}"

if [[ "$normalized_remote" != "$normalized_repo" ]]; then
  echo "Origin remote does not match submission repo."
  echo "Origin: $remote_url"
  echo "Submission: $repo_url"
  exit 1
fi

current_branch="$(git branch --show-current)"
if [[ "$current_branch" != "main" ]]; then
  echo "Publish from main only. Current branch: ${current_branch:-unknown}"
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree must be clean before making the repository public."
  echo "Commit and push the release-ready state first."
  exit 1
fi

git fetch --quiet origin main

local_head="$(git rev-parse HEAD)"
remote_head="$(git rev-parse origin/main)"

if [[ "$local_head" != "$remote_head" ]]; then
  echo "Local main must match origin/main before making the repository public."
  echo "Local: $local_head"
  echo "Origin: $remote_head"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required to check repository visibility."
  exit 1
fi

repo_status="$(gh repo view "$repo_path" --json isPrivate,visibility 2>/dev/null || true)"
if [[ -z "$repo_status" ]]; then
  echo "Could not read GitHub repository status: $repo_url"
  exit 1
fi

zsh "$ROOT_DIR/scripts/check_public_release_safety.sh"
zsh "$ROOT_DIR/scripts/check_open_source_ready.sh"
zsh "$ROOT_DIR/scripts/check_docs.sh"
zsh "$ROOT_DIR/scripts/check_fast.sh"
APP_STARTED=1 zsh "$ROOT_DIR/scripts/verify_release.sh"

if [[ "$repo_status" == *'"isPrivate":true'* ]]; then
  echo "Public publish precheck passed."
  echo "Repository is still private. Make it public, then run:"
  echo "zsh scripts/check_submission_live.sh"
else
  zsh "$ROOT_DIR/scripts/check_submission_live.sh"
  echo "Public publish precheck passed."
fi
