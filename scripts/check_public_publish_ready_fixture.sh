#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_public_publish_ready.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

write_repo() {
  local repo_dir="$1"

  mkdir -p "$repo_dir/scripts" "$repo_dir/docs" "$repo_dir/bin"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_public_publish_ready.sh"
  chmod +x "$repo_dir/scripts/check_public_publish_ready.sh"

  cat > "$repo_dir/docs/SUBMISSION.md" <<'DOC'
# Submission Notes

## Repository

https://github.com/example/fluid-reader
DOC

  for script_name in \
    check_public_release_safety.sh \
    check_open_source_ready.sh \
    check_docs.sh \
    check_fast.sh \
    verify_release.sh \
    check_submission_live.sh; do
    cat > "$repo_dir/scripts/$script_name" <<'SCRIPT'
#!/usr/bin/env zsh
set -euo pipefail
echo "stub passed"
SCRIPT
    chmod +x "$repo_dir/scripts/$script_name"
  done

  cat > "$repo_dir/bin/git" <<'SCRIPT'
#!/usr/bin/env zsh
set -euo pipefail

case "$*" in
  "remote get-url origin")
    print -r -- "${FIXTURE_REMOTE_URL:-https://github.com/example/fluid-reader.git}"
    ;;
  "branch --show-current")
    print -r -- "${FIXTURE_BRANCH:-main}"
    ;;
  "status --porcelain")
    print -r -- "${FIXTURE_STATUS:-}"
    ;;
  "fetch --quiet origin main")
    exit 0
    ;;
  "rev-parse HEAD")
    print -r -- "${FIXTURE_LOCAL_HEAD:-abc123}"
    ;;
  "rev-parse origin/main")
    print -r -- "${FIXTURE_REMOTE_HEAD:-abc123}"
    ;;
  *)
    echo "Unexpected git call: $*" >&2
    exit 1
    ;;
esac
SCRIPT
  chmod +x "$repo_dir/bin/git"

  cat > "$repo_dir/bin/gh" <<'SCRIPT'
#!/usr/bin/env zsh
set -euo pipefail
if [[ "${FIXTURE_GH_EMPTY:-0}" == "1" ]]; then
  exit 0
fi

if [[ -n "${FIXTURE_GH_STATUS:-}" ]]; then
  print -r -- "$FIXTURE_GH_STATUS"
else
  print -r -- '{"isPrivate":true,"visibility":"PRIVATE"}'
fi
SCRIPT
  chmod +x "$repo_dir/bin/gh"
}

expect_pass() {
  local name="$1"
  local repo_dir="$TMP_DIR/$name"
  local output

  write_repo "$repo_dir"

  if ! output="$(cd "$repo_dir" && PATH="$repo_dir/bin:$PATH" zsh scripts/check_public_publish_ready.sh 2>&1)"; then
    echo "Expected $name fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Public publish precheck passed."* ]]; then
    echo "Expected $name fixture to print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  local expected="$2"
  shift 2
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  write_repo "$repo_dir"

  set +e
  output="$(cd "$repo_dir" && PATH="$repo_dir/bin:$PATH" "$@" zsh scripts/check_public_publish_ready.sh 2>&1)"
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

expect_pass "private-ready"
expect_fail "dirty-tree" "Working tree must be clean" env FIXTURE_STATUS=" M README.md"
expect_fail "wrong-branch" "Publish from main only" env FIXTURE_BRANCH="feature/test"
expect_fail "remote-mismatch" "Origin remote does not match submission repo." env FIXTURE_REMOTE_URL="https://github.com/example/other.git"
expect_fail "not-pushed" "Local main must match origin/main" env FIXTURE_REMOTE_HEAD="def456"
expect_fail "missing-gh-status" "Could not read GitHub repository status" env FIXTURE_GH_EMPTY=1

echo "Public publish readiness fixture checks passed."
