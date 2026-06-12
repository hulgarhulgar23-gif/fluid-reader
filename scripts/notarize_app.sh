#!/usr/bin/env zsh
# Notarizes and staples a signed FluidReader.app, then re-zips it.
#
# Prerequisites (one-time):
#   1. Enroll in the Apple Developer Program.
#   2. Create a "Developer ID Application" certificate in Xcode or at
#      developer.apple.com and install it in your login keychain.
#   3. Store notary credentials once:
#        xcrun notarytool store-credentials fluid-reader-notary \
#          --apple-id "you@example.com" --team-id TEAMID1234
#
# Usage:
#   FLUID_READER_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID1234)" \
#     zsh scripts/build_app.sh
#   zsh scripts/notarize_app.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_PATH="${FLUID_READER_APP_PATH:-$ROOT_DIR/.build/FluidReader.app}"
ZIP_PATH="${FLUID_READER_ZIP_PATH:-$ROOT_DIR/.build/FluidReader.zip}"
NOTARY_PROFILE="${FLUID_READER_NOTARY_PROFILE:-fluid-reader-notary}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle is missing: $APP_PATH" >&2
  echo "Run scripts/build_app.sh with FLUID_READER_SIGN_IDENTITY set first." >&2
  exit 1
fi

SIGNATURE="$(codesign -dv "$APP_PATH" 2>&1 || true)"
if [[ "$SIGNATURE" == *"Signature=adhoc"* ]]; then
  echo "App is ad-hoc signed; notarization requires a Developer ID signature." >&2
  echo "Rebuild with FLUID_READER_SIGN_IDENTITY=\"Developer ID Application: ...\"." >&2
  exit 1
fi

SUBMIT_ZIP="$(mktemp -d)/FluidReader-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$SUBMIT_ZIP"

echo "Submitting to Apple notary service (profile: $NOTARY_PROFILE)..."
xcrun notarytool submit "$SUBMIT_ZIP" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "Stapling ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
rm -f "$SUBMIT_ZIP"

echo "Notarized app: $APP_PATH"
echo "Distributable zip: $ZIP_PATH"
