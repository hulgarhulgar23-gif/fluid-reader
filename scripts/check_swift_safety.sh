#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if rg -n --glob '*.swift' '\bas!|\btry!|\bfatalError\s*\(|\bpreconditionFailure\s*\(' Sources/FluidReader Tests/FluidReaderTests; then
  echo "High-risk Swift code found. Avoid forced casts, forced try, and crash-only failures."
  exit 1
fi

if rg -n --pcre2 --glob '*.swift' ':[[:space:]]*[A-Za-z_][A-Za-z0-9_<>,. ]*!(?!=)[[:space:]]*(=|,|$)' Sources/FluidReader; then
  echo "High-risk Swift code found. Avoid implicitly unwrapped app properties."
  exit 1
fi

echo "Swift safety checks passed."
