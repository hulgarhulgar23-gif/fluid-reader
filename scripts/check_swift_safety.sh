#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

grep_swift() {
  local pattern="$1"
  shift

  find "$@" -name '*.swift' -type f -exec grep -HEn "$pattern" {} + 2>/dev/null || true
}

search_swift() {
  local rg_pattern="$1"
  local grep_pattern="$2"
  shift 2

  if command -v rg >/dev/null 2>&1; then
    rg -n --glob '*.swift' "$rg_pattern" "$@"
    return
  fi

  local output
  output="$(grep_swift "$grep_pattern" "$@")"
  if [[ -n "$output" ]]; then
    print -r -- "$output"
    return 0
  fi

  return 1
}

search_implicit_unwraps() {
  if command -v rg >/dev/null 2>&1; then
    rg -n --pcre2 --glob '*.swift' ':[[:space:]]*[A-Za-z_][A-Za-z0-9_<>,. ]*!(?!=)[[:space:]]*(=|,|$)' Sources/FluidReader
    return
  fi

  local output
  output="$(grep_swift ':[[:space:]]*[A-Za-z_][A-Za-z0-9_<>,. ]*![[:space:]]*(=|,|$)' Sources/FluidReader | grep -Ev '!=' || true)"
  if [[ -n "$output" ]]; then
    print -r -- "$output"
    return 0
  fi

  return 1
}

if search_swift '\bas!|\btry!|\bfatalError\s*\(|\bpreconditionFailure\s*\(' '(^|[^A-Za-z0-9_])(as!|try!|fatalError[[:space:]]*\(|preconditionFailure[[:space:]]*\()' Sources/FluidReader Tests/FluidReaderTests; then
  echo "High-risk Swift code found. Avoid forced casts, forced try, and crash-only failures."
  exit 1
fi

if search_implicit_unwraps; then
  echo "High-risk Swift code found. Avoid implicitly unwrapped app properties."
  exit 1
fi

echo "Swift safety checks passed."
