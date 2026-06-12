#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

files=()
for docs_root in README.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md docs .github; do
  if [[ -f "$docs_root" ]]; then
    files+=("$docs_root")
  elif [[ -d "$docs_root" ]]; then
    while IFS= read -r file; do
      files+=("$file")
    done < <(find "$docs_root" -type f -name '*.md' | sort)
  fi
done

if (( ${#files[@]} == 0 )); then
  echo "No markdown files found."
  exit 0
fi

broken=0

while IFS=$'\t' read -r file line link; do
  [[ -z "${link:-}" ]] && continue

  case "$link" in
    http://*|https://*|mailto:*|app://*|file://*|\#*)
      continue
      ;;
  esac

  target="${link%%#*}"
  target="${target%%\?*}"
  target="${target#<}"
  target="${target%>}"

  [[ -z "$target" ]] && continue

  base_dir="$(dirname "$file")"
  if [[ "$target" == /* ]]; then
    resolved="$target"
  else
    resolved="$base_dir/$target"
  fi

  if [[ ! -e "$resolved" ]]; then
    echo "Broken link in $file:$line -> $link"
    broken=1
  fi
done < <(
  perl -ne 'while (/\[[^\]]+\]\(([^)]+)\)/g) { print "$ARGV\t$.\t$1\n" }' "${files[@]}"
)

if (( broken != 0 )); then
  exit 1
fi

echo "Markdown links ok (${#files[@]} files)."
