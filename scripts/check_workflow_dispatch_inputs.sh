#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

LIMIT=10
failed=0

for workflow in .github/workflows/*.yml .github/workflows/*.yaml(N); do
  [[ -e "$workflow" ]] || continue

  count="$(
    awk '
      /^    inputs:/ {
        in_inputs = 1
        next
      }
      in_inputs && /^[^ ]/ {
        in_inputs = 0
      }
      in_inputs && /^      [A-Za-z0-9_][A-Za-z0-9_-]*:[[:space:]]*$/ {
        count++
      }
      END {
        print count + 0
      }
    ' "$workflow"
  )"

  if (( count > LIMIT )); then
    echo "$workflow has $count workflow_dispatch inputs. Keep at most $LIMIT."
    failed=1
  fi
done

if (( failed != 0 )); then
  exit 1
fi

echo "Workflow dispatch input checks passed."
