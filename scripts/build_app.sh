#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

swift build -c release \
  -Xswiftc -Osize \
  -Xswiftc -gnone \
  -Xswiftc -remove-runtime-asserts \
  -Xswiftc -disable-cmo \
  -Xswiftc -Xfrontend -Xswiftc -disable-reflection-metadata \
  -Xswiftc -Xfrontend -Xswiftc -disable-concrete-type-metadata-mangled-name-accessors \
  -Xlinker -dead_strip \
  -Xlinker -no_compact_unwind \
  -Xlinker -no_function_starts

APP_DIR="$ROOT_DIR/.build/FluidReader.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$ROOT_DIR/.build/release/FluidReader" "$MACOS_DIR/FluidReader"
strip -STx "$MACOS_DIR/FluidReader"
strip -u "$MACOS_DIR/FluidReader"

cp "$ROOT_DIR/Assets/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>Fluid Reader</string>
  <key>CFBundleExecutable</key>
  <string>FluidReader</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>dev.oss.fluidreader</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Fluid Reader</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.productivity</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>Fluid Reader uses keyboard automation to copy the selected text and paste results into the frontmost app.</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026 Fluid Reader contributors. MIT License.</string>
</dict>
</plist>
PLIST

SIGN_IDENTITY="${FLUID_READER_SIGN_IDENTITY:--}"
SIGN_APP="${FLUID_READER_SIGN_APP:-1}"
if [[ "$SIGN_APP" != "0" ]]; then
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --sign "$SIGN_IDENTITY" "$APP_DIR" >/dev/null
  else
    # Developer ID release signing: hardened runtime and a secure timestamp
    # are both required for notarization.
    codesign --force --options runtime --timestamp \
      --sign "$SIGN_IDENTITY" "$APP_DIR" >/dev/null
  fi
fi

echo "$APP_DIR"
