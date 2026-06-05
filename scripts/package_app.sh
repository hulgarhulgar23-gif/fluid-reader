#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="$(zsh "$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
ZIP_PATH="$ROOT_DIR/.build/FluidReader.zip"

rm -f "$ZIP_PATH"
(cd "$(dirname "$APP_PATH")" && zip -qry "$ZIP_PATH" "$(basename "$APP_PATH")")

echo "$ZIP_PATH"
