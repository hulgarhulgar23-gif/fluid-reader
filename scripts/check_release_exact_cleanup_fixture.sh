#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY_RELEASE_SCRIPT="$ROOT_DIR/scripts/verify_release.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

HELPER_SCRIPT="$TMP_DIR/release_helpers.zsh"
awk '/^swift build$/ { exit } { print }' "$VERIFY_RELEASE_SCRIPT" > "$HELPER_SCRIPT"

EXPECTED_EXEC="$TMP_DIR/Fake Fluid Reader.app/Contents/MacOS/FluidReader"
OTHER_EXEC="$TMP_DIR/Other FluidReader.app/Contents/MacOS/FluidReader"
mkdir -p "$(dirname "$EXPECTED_EXEC")" "$(dirname "$OTHER_EXEC")"
printf 'built\n' > "$EXPECTED_EXEC"
printf 'other\n' > "$OTHER_EXEC"

KILLED_PIDS=""

pid_was_killed() {
  local pid="$1"
  [[ " $KILLED_PIDS " == *" $pid "* ]]
}

pgrep() {
  if [[ "$*" == "-x FluidReader" ]]; then
    printf '111\n222\n333\n'
    return 0
  fi
  return 1
}

lsof() {
  local pid=""
  while (( $# > 0 )); do
    if [[ "$1" == "-p" ]]; then
      pid="$2"
      shift 2
      continue
    fi
    shift
  done

  case "$pid" in
    111)
      if ! pid_was_killed "$pid"; then
        printf 'n%s\n' "$EXPECTED_EXEC"
      fi
      ;;
    222)
      printf 'n%s\n' "$OTHER_EXEC"
      ;;
    333)
      ;;
  esac
}

kill() {
  local pid="$1"
  KILLED_PIDS="${KILLED_PIDS} ${pid}"
  return 0
}

sleep() {
  return 0
}

source "$HELPER_SCRIPT"

MATCHES="$(fluidreader_pids_for_exec "$EXPECTED_EXEC" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
if [[ "$MATCHES" != "111" ]]; then
  echo "Expected exact executable match to find only pid 111, got: $MATCHES"
  exit 1
fi

FIRST_MATCH="$(fluidreader_pid_for_exec "$EXPECTED_EXEC")"
if [[ "$FIRST_MATCH" != "111" ]]; then
  echo "Expected first exact executable match pid 111, got: $FIRST_MATCH"
  exit 1
fi

terminate_fluidreader_execs "$EXPECTED_EXEC"
if [[ "$KILLED_PIDS" != " 111" ]]; then
  echo "Expected cleanup to kill only pid 111, got:$KILLED_PIDS"
  exit 1
fi

if fluidreader_pid_for_exec "$EXPECTED_EXEC" >/dev/null; then
  echo "Expected built executable pid to be gone after cleanup."
  exit 1
fi

OTHER_MATCHES="$(fluidreader_pids_for_exec "$OTHER_EXEC" | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
if [[ "$OTHER_MATCHES" != "222" ]]; then
  echo "Expected unrelated executable to remain pid 222, got: $OTHER_MATCHES"
  exit 1
fi

echo "Release exact cleanup fixture checks passed."
