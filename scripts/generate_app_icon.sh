#!/usr/bin/env zsh
# Regenerates Assets/AppIcon.icns from scripts/render_app_icon.swift.
# Run this only when the icon design changes; the .icns is committed.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

MASTER_PNG="$WORK_DIR/master-1024.png"
ICONSET_DIR="$WORK_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"

swift "$ROOT_DIR/scripts/render_app_icon.swift" "$MASTER_PNG"

# Keep the set small: the app ships in a strict size budget.
sips -z 16 16     "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
sips -z 32 32     "$MASTER_PNG" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
sips -z 32 32     "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
sips -z 64 64     "$MASTER_PNG" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
sips -z 128 128   "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
sips -z 256 256   "$MASTER_PNG" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
sips -z 256 256   "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
sips -z 512 512   "$MASTER_PNG" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
sips -z 512 512   "$MASTER_PNG" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null

mkdir -p "$ROOT_DIR/Assets"
iconutil -c icns "$ICONSET_DIR" -o "$ROOT_DIR/Assets/AppIcon.icns"

echo "$ROOT_DIR/Assets/AppIcon.icns"
du -h "$ROOT_DIR/Assets/AppIcon.icns" | awk '{print $1}'
