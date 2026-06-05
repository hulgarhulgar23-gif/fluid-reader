#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

START_TIME="$(date +%s)"
APP_PATH="$(zsh "$ROOT_DIR/scripts/build_app.sh" | tail -n 1)"
END_TIME="$(date +%s)"
SIZE="$(du -sh "$APP_PATH" | awk '{print $1}')"

echo "Built: $APP_PATH"
echo "Size:  $SIZE"
echo "Time:  $((END_TIME - START_TIME))s"
