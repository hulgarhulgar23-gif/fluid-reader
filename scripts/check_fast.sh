#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

START_TIME="$(date +%s)"
APP_PATH="$(FLUID_READER_SIGN_APP=0 zsh "$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
END_TIME="$(date +%s)"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/FluidReader"
SIZE_BYTES="$(stat -f '%z' "$EXECUTABLE_PATH")"
SIZE_KB="$(((SIZE_BYTES + 1023) / 1024))"
MAX_APP_SIZE_KB="${MAX_APP_SIZE_KB:-2816}"

echo "Built: $APP_PATH"
echo "Executable size: ${SIZE_KB}K (${SIZE_BYTES} bytes / ${MAX_APP_SIZE_KB}K max)"
echo "Time:  $((END_TIME - START_TIME))s"

if (( SIZE_KB > MAX_APP_SIZE_KB )); then
  echo "Executable is too large for the fast check."
  exit 1
fi
