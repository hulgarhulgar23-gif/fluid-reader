#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

swift build
swift test

APP_PATH="$(zsh "$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
ZIP_PATH="$(zsh "$ROOT_DIR/scripts/package_app.sh" | tail -n 1)"
PLIST_PATH="$APP_PATH/Contents/Info.plist"
EXEC_PATH="$APP_PATH/Contents/MacOS/FluidReader"

APP_BYTES="$(du -sk "$APP_PATH" | awk '{print $1}')"
ZIP_BYTES="$(du -sk "$ZIP_PATH" | awk '{print $1}')"

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

if (( APP_BYTES > 1024 )); then
  echo "App is too large: ${APP_BYTES}K"
  exit 1
fi

if (( ZIP_BYTES > 512 )); then
  echo "Zip is too large: ${ZIP_BYTES}K"
  exit 1
fi

open "$APP_PATH"

for _ in {1..20}; do
  if pgrep -fl "$APP_PATH/Contents/MacOS/FluidReader" >/dev/null; then
    APP_STARTED=1
    break
  fi
  sleep 0.25
done

if [[ "${APP_STARTED:-0}" != "1" ]]; then
  echo "Launch check failed"
  exit 1
fi

pkill -x FluidReader || true

echo "App: $APP_PATH (${APP_BYTES}K)"
echo "Zip: $ZIP_PATH (${ZIP_BYTES}K)"
echo "Release check passed"
