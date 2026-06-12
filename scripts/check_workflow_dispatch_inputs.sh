#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

LIMIT=10
MAX_EXPRESSION_BLOCK_BYTES=20000
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

  long_expression_blocks="$(
    awk -v max_bytes="$MAX_EXPRESSION_BLOCK_BYTES" '
      function leading_spaces(line, copy) {
        copy = line
        sub(/[^ ].*$/, "", copy)
        return length(copy)
      }

      function finish_run_block() {
        if (in_run && block_length > max_bytes && has_expression) {
          print run_line
        }
        in_run = 0
        run_indent = 0
        run_line = 0
        block_length = 0
        has_expression = 0
      }

      /^[[:space:]]+run:[[:space:]]*\|[[:space:]]*$/ {
        finish_run_block()
        in_run = 1
        run_indent = leading_spaces($0)
        run_line = NR
        next
      }

      in_run {
        current_indent = leading_spaces($0)
        if ($0 !~ /^[[:space:]]*$/ && current_indent <= run_indent) {
          finish_run_block()
        }
      }

      in_run {
        block_length += length($0) + 1
        if (index($0, "${{") > 0) {
          has_expression = 1
        }
      }

      END {
        finish_run_block()
      }
    ' "$workflow"
  )"

  if [[ -n "$long_expression_blocks" ]]; then
    while IFS= read -r line_number; do
      [[ -n "$line_number" ]] || continue
      echo "$workflow has a large run block with GitHub expressions at line $line_number. Move expressions into env first."
    done <<< "$long_expression_blocks"
    failed=1
  fi
done

if (( failed != 0 )); then
  exit 1
fi

echo "Workflow dispatch input checks passed."
