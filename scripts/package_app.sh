#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="${FLUID_READER_APP_PATH:-}"
if [[ -z "$APP_PATH" ]]; then
  APP_PATH="$(zsh "$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
fi
ZIP_PATH="${FLUID_READER_ZIP_PATH:-$ROOT_DIR/.build/FluidReader.zip}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle is missing: $APP_PATH" >&2
  exit 1
fi

rm -f "$ZIP_PATH"
mkdir -p "$(dirname "$ZIP_PATH")"
(cd "$(dirname "$APP_PATH")" && zip -qry "$ZIP_PATH" "$(basename "$APP_PATH")")

echo "$ZIP_PATH"
