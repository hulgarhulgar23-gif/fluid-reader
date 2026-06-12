#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_swift_safety.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

make_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts" "$repo_dir/Sources/FluidReader" "$repo_dir/Tests/FluidReaderTests"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_swift_safety.sh"
  chmod +x "$repo_dir/scripts/check_swift_safety.sh"
}

expect_pass() {
  local repo_dir="$TMP_DIR/clean"
  local output

  make_repo "$repo_dir"
  printf 'let value = optionalValue as? String\n' > "$repo_dir/Sources/FluidReader/Safe.swift"

  if ! output="$(cd "$repo_dir" && zsh scripts/check_swift_safety.sh 2>&1)"; then
    echo "Expected clean Swift safety fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Swift safety checks passed."* ]]; then
    echo "Clean Swift safety fixture did not print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  local content="$2"
  local expected="$3"
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  make_repo "$repo_dir"
  printf '%s\n' "$content" > "$repo_dir/Sources/FluidReader/Bad.swift"

  set +e
  output="$(cd "$repo_dir" && zsh scripts/check_swift_safety.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected $name Swift safety fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected $name Swift safety fixture to mention: $expected"
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"High-risk Swift code found."* ]]; then
    echo "Expected $name Swift safety fixture to print failure summary."
    echo "$output"
    exit 1
  fi
}

FORCED_CAST="let value = object as""! String"
FORCED_TRY="let value = try""! loadValue()"
FATAL_ERROR="fatal""Error(\"bad\")"
PRECONDITION_FAILURE="precondition""Failure(\"bad\")"
IMPLICITLY_UNWRAPPED="private var panel: NS""Panel!"

expect_pass
expect_fail "forced-cast" "$FORCED_CAST" "Bad.swift:1:"
expect_fail "forced-try" "$FORCED_TRY" "Bad.swift:1:"
expect_fail "fatal-error" "$FATAL_ERROR" "Bad.swift:1:"
expect_fail "precondition-failure" "$PRECONDITION_FAILURE" "Bad.swift:1:"
expect_fail "implicitly-unwrapped" "$IMPLICITLY_UNWRAPPED" "Bad.swift:1:"

echo "Swift safety fixture checks passed."
