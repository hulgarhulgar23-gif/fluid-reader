#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERIFY_RELEASE_SCRIPT="$ROOT_DIR/scripts/verify_release.sh"

if ! grep -Eq '^[[:space:]]+APP_STARTED=0$' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must reset APP_STARTED before polling launch state."
  exit 1
fi

if ! grep -Fq 'wait_for_no_fluidreader_exec()' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must wait for built FluidReader processes to exit."
  exit 1
fi

if ! grep -Fq 'terminate_fluidreader_execs "$EXEC_PATH"' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must clean up only the built executable."
  exit 1
fi

if grep -Fq 'pkill -x FluidReader' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must not kill unrelated FluidReader processes."
  exit 1
fi

if ! grep -Fq 'open -n "$APP_PATH"' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must launch a new instance of the built app."
  exit 1
fi

if ! grep -Fq 'fluidreader_pid_for_exec()' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must match the launched process to the built executable."
  exit 1
fi

if ! grep -Fq 'lsof -a -p "$pid" -d txt -Fn' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must read the process executable path without splitting spaces."
  exit 1
fi

if grep -Fq 'ps -p "$pid" -o command=' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must not split executable paths on spaces."
  exit 1
fi

if ! grep -Fq ' "$executable_path" -ef "$expected_exec" ' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must compare process path with the built executable."
  exit 1
fi

if [[ "$(grep -F 'terminate_fluidreader_execs "$EXEC_PATH"' "$VERIFY_RELEASE_SCRIPT" | wc -l | tr -d ' ')" -lt 2 ]]; then
  echo "Release verifier must clean before launch and after launch."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_release_exact_cleanup_fixture.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run exact release cleanup fixtures."
  exit 1
fi

if ! grep -Fq 'fluidreader_pid_for_exec "$EXEC_PATH"' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier launch check must use exact executable matching."
  exit 1
fi

if ! grep -Fq 'zsh "$ROOT_DIR/scripts/check_swift_safety.sh"' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must run Swift safety checks."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_swift_safety_fixture.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run Swift safety fixtures."
  exit 1
fi

if ! grep -Fq 'zsh "$ROOT_DIR/scripts/check_public_release_safety.sh"' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must run public release safety checks."
  exit 1
fi

if ! grep -Fq 'zsh "$ROOT_DIR/scripts/check_open_source_ready.sh"' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must run open-source readiness checks."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_public_release_safety_fixture.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run public release safety fixtures."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_ci_hardening.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run CI hardening checks."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_ci_hardening_fixture.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run CI hardening fixtures."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_open_source_ready.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run open-source readiness checks."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_open_source_ready_fixture.sh' "$ROOT_DIR/.github/workflows/ci.yml"; then
  echo "CI must run open-source readiness fixtures."
  exit 1
fi

if ! grep -Eq '\[\[ "\$APP_STARTED" != "1" \]\]' "$VERIFY_RELEASE_SCRIPT"; then
  echo "Release verifier must not trust inherited APP_STARTED state."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FAKE_APP="$TMP_DIR/Fake Fluid Reader.app"
FAKE_ZIP="$TMP_DIR/Fake Fluid Reader.zip"
mkdir -p "$FAKE_APP/Contents/MacOS"
printf 'fake app\n' > "$FAKE_APP/Contents/MacOS/FakeFluidReader"

ZIP_PATH="$(FLUID_READER_APP_PATH="$FAKE_APP" FLUID_READER_ZIP_PATH="$FAKE_ZIP" zsh "$ROOT_DIR/scripts/package_app.sh" | tail -n 1)"

if [[ "$ZIP_PATH" != "$FAKE_ZIP" ]]; then
  echo "Unexpected package path: $ZIP_PATH"
  exit 1
fi

if ! zipinfo -1 "$ZIP_PATH" | grep -qx 'Fake Fluid Reader.app/Contents/MacOS/FakeFluidReader'; then
  echo "Package did not include the provided app bundle."
  exit 1
fi

echo "Release packaging fixture checks passed."
