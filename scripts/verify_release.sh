#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

fluidreader_pids_for_exec() {
  local expected_exec="$1"
  local executable_path
  local pid

  for pid in $(pgrep -x FluidReader 2>/dev/null || true); do
    executable_path="$(lsof -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -n 1)"
    if [[ -n "$executable_path" && "$executable_path" -ef "$expected_exec" ]]; then
      echo "$pid"
    fi
  done
}

fluidreader_pid_for_exec() {
  local expected_exec="$1"
  local match

  match="$(fluidreader_pids_for_exec "$expected_exec" | head -n 1)"
  if [[ -n "$match" ]]; then
    echo "$match"
    return 0
  fi

  return 1
}

wait_for_no_fluidreader_exec() {
  local expected_exec="$1"

  for _ in {1..40}; do
    if ! fluidreader_pid_for_exec "$expected_exec" >/dev/null; then
      return 0
    fi
    sleep 0.25
  done

  echo "Built FluidReader did not exit cleanly."
  return 1
}

terminate_fluidreader_execs() {
  local expected_exec="$1"
  local found=0
  local pid

  while IFS= read -r pid; do
    if [[ -n "$pid" ]]; then
      found=1
      kill "$pid" 2>/dev/null || true
    fi
  done < <(fluidreader_pids_for_exec "$expected_exec")

  if (( found == 0 )); then
    return 0
  fi

  wait_for_no_fluidreader_exec "$expected_exec"
}

swift build
zsh "$ROOT_DIR/scripts/check_public_release_safety.sh"
zsh "$ROOT_DIR/scripts/check_open_source_ready.sh"
zsh "$ROOT_DIR/scripts/check_swift_safety.sh"

if [[ "${FLUID_READER_SKIP_TESTS:-0}" != "1" ]]; then
  swift test
else
  echo "Tests skipped"
fi

APP_PATH="$(zsh "$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
ZIP_PATH="$(FLUID_READER_APP_PATH="$APP_PATH" zsh "$ROOT_DIR/scripts/package_app.sh" | tail -n 1)"
PLIST_PATH="$APP_PATH/Contents/Info.plist"
EXEC_PATH="$APP_PATH/Contents/MacOS/FluidReader"

APP_BYTES="$(du -sk "$APP_PATH" | awk '{print $1}')"
ZIP_BYTES="$(du -sk "$ZIP_PATH" | awk '{print $1}')"
MAX_APP_SIZE_KB="${MAX_APP_SIZE_KB:-2816}"

if [[ ! -x "$EXEC_PATH" ]]; then
  echo "App executable is missing or cannot run."
  exit 1
fi

plutil -lint "$PLIST_PATH" >/dev/null

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST_PATH")"
APP_MODE="$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$PLIST_PATH")"
MIN_SYSTEM="$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$PLIST_PATH")"

if [[ "$BUNDLE_ID" != "dev.oss.fluidreader" ]]; then
  echo "Bundle id is wrong: $BUNDLE_ID"
  exit 1
fi

if [[ "$APP_MODE" != "true" ]]; then
  echo "App is not set as a menu-bar app."
  exit 1
fi

if [[ "$MIN_SYSTEM" != "14.0" ]]; then
  echo "Minimum macOS version is wrong: $MIN_SYSTEM"
  exit 1
fi

if (( APP_BYTES > MAX_APP_SIZE_KB )); then
  echo "App is too large: ${APP_BYTES}K (max ${MAX_APP_SIZE_KB}K)"
  exit 1
fi

if (( ZIP_BYTES > 1280 )); then
  echo "Zip is too large: ${ZIP_BYTES}K"
  exit 1
fi

if [[ "${FLUID_READER_SKIP_LAUNCH_CHECK:-0}" != "1" ]]; then
  APP_STARTED=0
  APP_PID=""
  terminate_fluidreader_execs "$EXEC_PATH"
  open -n "$APP_PATH"

  for _ in {1..40}; do
    if APP_PID="$(fluidreader_pid_for_exec "$EXEC_PATH")"; then
      APP_STARTED=1
      break
    fi
    sleep 0.25
  done

  if [[ "$APP_STARTED" != "1" ]]; then
    echo "Launch check failed"
    exit 1
  fi

  terminate_fluidreader_execs "$EXEC_PATH"
else
  echo "Launch check skipped"
fi

echo "App: $APP_PATH (${APP_BYTES}K)"
echo "Zip: $ZIP_PATH (${ZIP_BYTES}K)"
echo "Release check passed"
