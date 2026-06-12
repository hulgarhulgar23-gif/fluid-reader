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

if [[ "$repo_url" != https://github.com/*/* ]]; then
  echo "Submission repo must be a GitHub URL: $repo_url"
  exit 1
fi

repo_path="${repo_url#https://github.com/}"
repo_path="${repo_path%.git}"
repo_path="${repo_path%/}"
repo_owner="${repo_path%%/*}"

profile_url="https://github.com/$repo_owner"
profile_api_url="https://api.github.com/users/$repo_owner"
profile_response_file="$(mktemp)"
response_file="$(mktemp)"
trap 'rm -f "$profile_response_file" "$response_file"' EXIT

profile_http_code="$(curl -L --silent --show-error --output "$profile_response_file" --write-out '%{http_code}' "$profile_api_url" || true)"

if [[ "$profile_http_code" != "200" ]]; then
  echo "GitHub username is not public or not reachable: $profile_url (HTTP $profile_http_code)"
  exit 1
fi

if ! grep -Fq '"type": "User"' "$profile_response_file"; then
  echo "GitHub username must point to a public user profile: $profile_url"
  exit 1
fi

api_url="https://api.github.com/repos/$repo_path"
http_code="$(curl -L --silent --show-error --output "$response_file" --write-out '%{http_code}' "$api_url" || true)"

if [[ "$http_code" != "200" ]]; then
  if command -v gh >/dev/null 2>&1; then
    private_status="$(gh repo view "$repo_path" --json isPrivate,visibility 2>/dev/null || true)"
    if [[ "$private_status" == *'"isPrivate":true'* ]]; then
      echo "GitHub repository exists but is private: $repo_url"
      exit 1
    fi
  fi

  echo "GitHub repository is not public or not reachable: $repo_url (HTTP $http_code)"
  exit 1
fi

if ! grep -Fq '"private": false' "$response_file"; then
  echo "GitHub repository must be public: $repo_url"
  exit 1
fi

if grep -Fq '"archived": true' "$response_file"; then
  echo "GitHub repository must not be archived: $repo_url"
  exit 1
fi

stars="$(sed -n 's/.*"stargazers_count": \([0-9][0-9]*\).*/\1/p' "$response_file" | head -n 1)"
forks="$(sed -n 's/.*"forks_count": \([0-9][0-9]*\).*/\1/p' "$response_file" | head -n 1)"
open_issues="$(sed -n 's/.*"open_issues_count": \([0-9][0-9]*\).*/\1/p' "$response_file" | head -n 1)"
pushed_at="$(sed -n 's/.*"pushed_at": "\([^"]*\)".*/\1/p' "$response_file" | head -n 1)"

echo "Submission live checks passed."
echo "GitHub profile: $profile_url"
echo "Repo: $repo_url"
echo "Stars: ${stars:-unknown}"
echo "Forks: ${forks:-unknown}"
echo "Open issues: ${open_issues:-unknown}"
echo "Last pushed: ${pushed_at:-unknown}"
