#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

require_file() {
  local file_path="$1"

  if [[ ! -f "$file_path" ]]; then
    echo "Missing required open-source file: $file_path"
    exit 1
  fi
}

require_text() {
  local file_path="$1"
  local text="$2"

  if ! grep -Fq "$text" "$file_path"; then
    echo "Missing required text in $file_path: $text"
    exit 1
  fi
}

submission_answer() {
  local start_marker="$1"
  local end_marker="$2"

  awk -v start="$start_marker" -v end="$end_marker" '
    index($0, start) { inside = 1; next }
    index($0, end) { inside = 0; next }
    inside { print }
  ' "docs/SUBMISSION.md" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

require_submission_answer() {
  local name="$1"
  local start_marker="$2"
  local end_marker="$3"
  local answer
  local answer_length

  answer="$(submission_answer "$start_marker" "$end_marker")"
  answer_length="${#answer}"

  if [[ -z "$answer" ]]; then
    echo "Missing required submission answer: $name"
    exit 1
  fi

  if (( answer_length > 500 )); then
    echo "Submission answer is too long: $name (${answer_length}/500)"
    exit 1
  fi
}

require_file "README.md"
require_file "LICENSE"
require_file "SECURITY.md"
require_file "SUPPORT.md"
require_file "CODE_OF_CONDUCT.md"
require_file "CONTRIBUTING.md"
require_file "docs/SUBMISSION.md"
require_file ".github/pull_request_template.md"
require_file ".github/ISSUE_TEMPLATE/bug_report.md"
require_file ".github/ISSUE_TEMPLATE/command_request.md"
require_file "scripts/check_public_publish_ready.sh"

require_text "LICENSE" "MIT License"

require_text "README.md" "Fluid Reader is a small macOS menu-bar app."
require_text "README.md" "Screen capture stays on the Mac."
require_text "README.md" "LLM support is off until the user turns it on."
require_text "README.md" "OpenAI API key"

require_text "docs/SUBMISSION.md" "Use this page when applying for OSS maintainer access."
require_text "docs/SUBMISSION.md" "OpenAI Form Answer"
require_text "docs/SUBMISSION.md" "The project is open source under MIT."
require_text "docs/SUBMISSION.md" "LLM support is optional and off by default"
require_text "docs/SUBMISSION.md" "https://openai.com/form/codex-for-oss/"
require_text "docs/SUBMISSION.md" "https://developers.openai.com/community/codex-for-oss"
require_text "docs/SUBMISSION.md" "GitHub username must be public."
require_text "docs/SUBMISSION.md" "GitHub repository must be public."
require_text "docs/SUBMISSION.md" "Why does this repository qualify? has a 500 character max."
require_text "docs/SUBMISSION.md" "How will you use API credits for your project? has a 500 character max."
require_text "docs/SUBMISSION.md" "OpenAI Organization ID is required in the live form."
require_text "docs/SUBMISSION.md" "six months of ChatGPT Pro with Codex"
require_submission_answer "why this repository qualifies" "<!-- openai-why-start -->" "<!-- openai-why-end -->"
require_submission_answer "API credits use" "<!-- openai-api-start -->" "<!-- openai-api-end -->"

require_text "SECURITY.md" "Do not open a public issue for secrets"
require_text "SECURITY.md" "Do not send API keys"
require_text "SUPPORT.md" "Copy Issue Bundle"
require_text "SUPPORT.md" "Do not paste API keys"
require_text "CODE_OF_CONDUCT.md" "Keep private data out of issues"

require_text "CONTRIBUTING.md" "MIT License"
require_text "CONTRIBUTING.md" "Code of Conduct"
require_text "CONTRIBUTING.md" "zsh scripts/check_open_source_ready.sh"
require_text "CONTRIBUTING.md" "zsh scripts/check_public_publish_ready.sh"

require_text ".github/pull_request_template.md" "zsh scripts/check_open_source_ready.sh"
require_text ".github/pull_request_template.md" "I did not add private data"
require_text ".github/ISSUE_TEMPLATE/bug_report.md" "Copy Issue Bundle"
require_text ".github/ISSUE_TEMPLATE/bug_report.md" "Do not paste API keys"
require_text ".github/ISSUE_TEMPLATE/command_request.md" "## Privacy"

echo "Open-source readiness checks passed."
