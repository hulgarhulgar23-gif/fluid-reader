#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_ci_hardening.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

write_clean_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts" "$repo_dir/.github/workflows"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_ci_hardening.sh"
  chmod +x "$repo_dir/scripts/check_ci_hardening.sh"

  cat > "$repo_dir/.github/workflows/ci.yml" <<'EOF'
name: CI

on:
  pull_request:

permissions:
  contents: read

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - name: Check whitespace
        run: git diff --check
      - name: Check CI hardening
        run: zsh scripts/check_ci_hardening.sh
      - name: Check CI hardening fixtures
        run: zsh scripts/check_ci_hardening_fixture.sh
      - name: Check open-source readiness
        run: zsh scripts/check_open_source_ready.sh
      - name: Check open-source readiness fixtures
        run: zsh scripts/check_open_source_ready_fixture.sh
EOF
}

expect_pass() {
  local repo_dir="$TMP_DIR/clean"
  local output

  write_clean_repo "$repo_dir"

  if ! output="$(cd "$repo_dir" && zsh scripts/check_ci_hardening.sh 2>&1)"; then
    echo "Expected clean CI hardening fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"CI hardening checks passed."* ]]; then
    echo "Clean CI hardening fixture did not print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail_missing_text() {
  local name="$1"
  local text="$2"
  local expected="$3"
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  write_clean_repo "$repo_dir"
  TEXT_TO_REMOVE="$text" perl -0pi -e 's/\Q$ENV{TEXT_TO_REMOVE}\E//g' "$repo_dir/.github/workflows/ci.yml"

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_ci_hardening.sh 2>&1)"
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
}

expect_pass
expect_fail_missing_text "missing-permissions" $'permissions:\n' "CI must set explicit workflow token permissions."
expect_fail_missing_text "missing-read-only-contents" "contents: read" "CI must keep contents permission read-only."
expect_fail_missing_text "missing-whitespace-check" "git diff --check" "CI must check whitespace with git diff --check."
expect_fail_missing_text "missing-ci-hardening-check" "zsh scripts/check_ci_hardening.sh" "CI must run the CI hardening check."
expect_fail_missing_text "missing-ci-hardening-fixture" "zsh scripts/check_ci_hardening_fixture.sh" "CI must run the CI hardening fixture."
expect_fail_missing_text "missing-open-source-check" "zsh scripts/check_open_source_ready.sh" "CI must run the open-source readiness check."
expect_fail_missing_text "missing-open-source-fixture" "zsh scripts/check_open_source_ready_fixture.sh" "CI must run the open-source readiness fixture."

echo "CI hardening fixture checks passed."
