#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_public_release_safety.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_public_release_safety.sh"
  chmod +x "$repo_dir/scripts/check_public_release_safety.sh"
  printf '# Fixture\n' > "$repo_dir/README.md"
}

expect_pass() {
  local name="$1"
  local repo_dir="$TMP_DIR/$name"
  local output

  make_repo "$repo_dir"
  mkdir -p "$repo_dir/config"
  printf 'OPENAI_API_KEY=\n' > "$repo_dir/.env.example"
  printf 'PUBLIC_SETTING=true\n' > "$repo_dir/config/app.sample"

  if ! output="$(cd "$repo_dir" && zsh scripts/check_public_release_safety.sh 2>&1)"; then
    echo "Expected clean fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Public release safety checks passed."* ]]; then
    echo "Clean fixture did not print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  local file_path="$2"
  local content="$3"
  local expected="$4"
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  make_repo "$repo_dir"
  mkdir -p "$(dirname "$repo_dir/$file_path")"
  printf '%s\n' "$content" > "$repo_dir/$file_path"

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_public_release_safety.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected $name fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected $name fixture to mention: $expected"
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Public release safety checks failed."* ]]; then
    echo "Expected $name fixture to print failure summary."
    echo "$output"
    exit 1
  fi
}

expect_pass "clean"
OPENAI_FAKE="sk-""proj-""abcdefghijklmnopqrstuvwxyz1234567890"
GITHUB_FAKE="github_""pat_""abcdefghijklmnopqrstuvwxyz1234567890"
AWS_FAKE="AKIA""1234567890ABCDEF"
GOOGLE_FAKE="AI""za1234567890abcdefghijklmnopqrstuvwxy"
SLACK_FAKE="xox""b-1234567890-abcdefghi1234567890"
PRIVATE_KEY_FAKE="-----BEGIN ""PRIVATE KEY-----"

expect_fail "openai-key" "notes.txt" "$OPENAI_FAKE" "Possible OpenAI API key found."
expect_fail "github-token" "notes.txt" "$GITHUB_FAKE" "Possible GitHub token found."
expect_fail "aws-key" "notes.txt" "$AWS_FAKE" "Possible AWS access key found."
expect_fail "google-key" "notes.txt" "$GOOGLE_FAKE" "Possible Google API key found."
expect_fail "slack-token" "notes.txt" "$SLACK_FAKE" "Possible Slack token found."
expect_fail "private-key" "id_test" "$PRIVATE_KEY_FAKE" "Possible private key block found."
expect_fail "env-file" ".env.local" "OPENAI_API_KEY=placeholder" "Sensitive local file must not ship: .env.local"
expect_fail "pem-file" "certs/test.pem" "placeholder" "Sensitive local file must not ship: certs/test.pem"

echo "Public release safety fixture checks passed."
