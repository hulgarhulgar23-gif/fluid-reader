#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_open_source_ready.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

write_clean_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts" "$repo_dir/docs" "$repo_dir/.github/ISSUE_TEMPLATE"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_open_source_ready.sh"
  chmod +x "$repo_dir/scripts/check_open_source_ready.sh"
  printf '#!/usr/bin/env zsh\n' > "$repo_dir/scripts/check_public_publish_ready.sh"

  cat > "$repo_dir/README.md" <<'EOF'
# Fluid Reader

Fluid Reader is a local-first macOS reader and launcher.
Screen capture stays on the Mac.
LLM support is off until the user turns it on.
OpenAI API key
EOF

  cat > "$repo_dir/LICENSE" <<'EOF'
MIT License
EOF

  cat > "$repo_dir/SECURITY.md" <<'EOF'
# Security

Do not open a public issue for secrets.
Do not send API keys.
EOF

  cat > "$repo_dir/SUPPORT.md" <<'EOF'
# Support

Copy Issue Bundle
Do not paste API keys.
EOF

  cat > "$repo_dir/CODE_OF_CONDUCT.md" <<'EOF'
# Code of Conduct

Keep private data out of issues.
EOF

  cat > "$repo_dir/CONTRIBUTING.md" <<'EOF'
# Contributing

MIT License
Code of Conduct
zsh scripts/check_open_source_ready.sh
zsh scripts/check_public_publish_ready.sh
EOF

  cat > "$repo_dir/docs/SUBMISSION.md" <<'EOF'
# Submission Notes

Use this page when applying for OSS maintainer access.
https://openai.com/form/codex-for-oss/
https://developers.openai.com/community/codex-for-oss
GitHub username must be public.
GitHub repository must be public.
Why does this repository qualify? has a 500 character max.
How will you use API credits for your project? has a 500 character max.
OpenAI Organization ID is required in the live form.
six months of ChatGPT Pro with Codex
OpenAI Form Answer
The project is open source under MIT.
LLM support is optional and off by default
<!-- openai-why-start -->
Fluid Reader is an active MIT macOS app for local-first OCR, speech, snippets, support bundles, and optional LLM help.
<!-- openai-why-end -->
<!-- openai-api-start -->
Use API credits for maintainer issue triage, PR review, release checks, docs, tests, and optional LLM safety review.
<!-- openai-api-end -->
EOF

  cat > "$repo_dir/.github/pull_request_template.md" <<'EOF'
- [ ] I ran `zsh scripts/check_open_source_ready.sh`
- [ ] I did not add private data
EOF

  cat > "$repo_dir/.github/ISSUE_TEMPLATE/bug_report.md" <<'EOF'
Copy Issue Bundle
Do not paste API keys.
EOF

  cat > "$repo_dir/.github/ISSUE_TEMPLATE/command_request.md" <<'EOF'
## Privacy
EOF
}

expect_pass() {
  local repo_dir="$TMP_DIR/clean"
  local output

  write_clean_repo "$repo_dir"

  if ! output="$(cd "$repo_dir" && zsh scripts/check_open_source_ready.sh 2>&1)"; then
    echo "Expected clean open-source fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Open-source readiness checks passed."* ]]; then
    echo "Clean open-source fixture did not print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail_missing_file() {
  local name="$1"
  local missing_file="$2"
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  write_clean_repo "$repo_dir"
  rm -f "$repo_dir/$missing_file"

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_open_source_ready.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected $name fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Missing required open-source file: $missing_file"* ]]; then
    echo "Expected $name fixture to mention missing file: $missing_file"
    echo "$output"
    exit 1
  fi
}

expect_fail_missing_text() {
  local name="$1"
  local file_path="$2"
  local expected="$3"
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  write_clean_repo "$repo_dir"
  EXPECTED_TEXT="$expected" perl -0pi -e 's/\Q$ENV{EXPECTED_TEXT}\E//g' "$repo_dir/$file_path"

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_open_source_ready.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected $name fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Missing required text in $file_path: $expected"* ]]; then
    echo "Expected $name fixture to mention missing text: $expected"
    echo "$output"
    exit 1
  fi
}

expect_pass
expect_fail_missing_file "missing-submission" "docs/SUBMISSION.md"
expect_fail_missing_file "missing-security" "SECURITY.md"
expect_fail_missing_text "missing-local-first-readme" "README.md" "Screen capture stays on the Mac."
expect_fail_missing_text "missing-optional-llm-readme" "README.md" "LLM support is off until the user turns it on."
expect_fail_missing_text "missing-submission-answer" "docs/SUBMISSION.md" "OpenAI Form Answer"
expect_fail_missing_text "missing-public-github-profile" "docs/SUBMISSION.md" "GitHub username must be public."
expect_fail_missing_text "missing-api-credit-limit" "docs/SUBMISSION.md" "How will you use API credits for your project? has a 500 character max."
expect_fail_missing_text "missing-security-privacy" "SECURITY.md" "Do not send API keys"
expect_fail_missing_text "missing-pr-template-privacy" ".github/pull_request_template.md" "I did not add private data"

long_answer_repo="$TMP_DIR/long-answer"
write_clean_repo "$long_answer_repo"
LONG_SUBMISSION_ANSWER="$(printf 'a%.0s' {1..501})" perl -0pi -e 's/(<!-- openai-why-start -->).*?(<!-- openai-why-end -->)/$1\n$ENV{LONG_SUBMISSION_ANSWER}\n$2/s' "$long_answer_repo/docs/SUBMISSION.md"
set +e
long_output="$(cd "$long_answer_repo" && zsh scripts/check_open_source_ready.sh 2>&1)"
long_exit_code=$?
set -e

if (( long_exit_code == 0 )); then
  echo "Expected long submission answer fixture to fail."
  echo "$long_output"
  exit 1
fi

if [[ "$long_output" != *"Submission answer is too long: why this repository qualifies"* ]]; then
  echo "Expected long submission answer fixture to mention answer length."
  echo "$long_output"
  exit 1
fi

echo "Open-source readiness fixture checks passed."
