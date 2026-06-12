#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_workflow_dispatch_inputs.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_repo() {
  local repo_dir="$1"
  local input_count="$2"

  mkdir -p "$repo_dir/scripts" "$repo_dir/.github/workflows"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_workflow_dispatch_inputs.sh"
  chmod +x "$repo_dir/scripts/check_workflow_dispatch_inputs.sh"

  {
    echo "name: Fixture"
    echo ""
    echo "on:"
    echo "  workflow_dispatch:"
    echo "    inputs:"
    for index in $(seq 1 "$input_count"); do
      echo "      input_${index}:"
      echo "        description: 'Fixture input ${index}'"
      echo "        required: false"
      echo "        default: ''"
      echo "        type: string"
    done
    echo ""
    echo "jobs:"
    echo "  fixture:"
    echo "    runs-on: macos-14"
    echo "    steps:"
    echo "      - run: echo ok"
  } > "$repo_dir/.github/workflows/fixture.yml"
}

make_large_expression_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts" "$repo_dir/.github/workflows"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_workflow_dispatch_inputs.sh"
  chmod +x "$repo_dir/scripts/check_workflow_dispatch_inputs.sh"

  {
    echo "name: Large Expression Fixture"
    echo ""
    echo "on:"
    echo "  workflow_dispatch:"
    echo ""
    echo "jobs:"
    echo "  fixture:"
    echo "    runs-on: macos-14"
    echo "    steps:"
    echo "      - name: Large run"
    echo "        run: |"
    echo '          echo "${{ github.event_name }}"'
    for index in $(seq 1 1200); do
      echo "          echo fixture line ${index} with enough text to make this run block large"
    done
  } > "$repo_dir/.github/workflows/large-expression.yml"
}

expect_pass() {
  local repo_dir="$TMP_DIR/pass"
  local output

  make_repo "$repo_dir" 10

  if ! output="$(cd "$repo_dir" && zsh scripts/check_workflow_dispatch_inputs.sh 2>&1)"; then
    echo "Expected 10-input workflow fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Workflow dispatch input checks passed."* ]]; then
    echo "10-input workflow fixture did not print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail() {
  local repo_dir="$TMP_DIR/fail"
  local output
  local exit_code

  make_repo "$repo_dir" 11

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_workflow_dispatch_inputs.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected 11-input workflow fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"fixture.yml has 11 workflow_dispatch inputs"* ]]; then
    echo "11-input workflow fixture did not mention the input count."
    echo "$output"
    exit 1
  fi
}

expect_fail_large_expression() {
  local repo_dir="$TMP_DIR/large-expression"
  local output
  local exit_code

  make_large_expression_repo "$repo_dir"

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_workflow_dispatch_inputs.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected large expression workflow fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"large-expression.yml has a large run block with GitHub expressions"* ]]; then
    echo "Large expression workflow fixture did not mention the large run block."
    echo "$output"
    exit 1
  fi
}

expect_pass
expect_fail
expect_fail_large_expression

echo "Workflow dispatch input fixture checks passed."
