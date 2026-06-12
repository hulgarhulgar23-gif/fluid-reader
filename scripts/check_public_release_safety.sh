#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

FAILED=0
COMMON_GLOBS=(
  --hidden
  --glob '!.git/**'
  --glob '!.build/**'
  --glob '!.swiftpm/**'
  --glob '!DerivedData/**'
  --glob '!**/*.png'
  --glob '!**/*.jpg'
  --glob '!**/*.jpeg'
  --glob '!**/*.gif'
  --glob '!**/*.zip'
  --glob '!**/*.app/**'
)

scan_pattern() {
  local label="$1"
  local pattern="$2"

  if rg -n --pcre2 "${COMMON_GLOBS[@]}" -- "$pattern" .; then
    echo "Possible ${label} found."
    FAILED=1
  fi
}

scan_pattern "OpenAI API key" '(?<![A-Za-z0-9_-])sk-(proj-)?[A-Za-z0-9_-]{20,}'
scan_pattern "GitHub token" '(?<![A-Za-z0-9_])(github_pat_[A-Za-z0-9_]{20,}|gh[opsu]_[A-Za-z0-9_]{20,})'
scan_pattern "AWS access key" '(?<![A-Z0-9])AKIA[0-9A-Z]{16}(?![A-Z0-9])'
scan_pattern "Google API key" '(?<![A-Za-z0-9_-])AIza[0-9A-Za-z_-]{35}(?![A-Za-z0-9_-])'
scan_pattern "Slack token" '(?<![A-Za-z0-9-])xox[baprs]-[A-Za-z0-9-]{20,}'
scan_pattern "private key block" '-----BEGIN (RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY-----'

while IFS= read -r path; do
  case "$path" in
    *.example|*.sample|*.template)
      continue
      ;;
  esac
  echo "Sensitive local file must not ship: $path"
  FAILED=1
done < <(
  rg --files --hidden \
    --glob '!.git/**' \
    --glob '!.build/**' \
    --glob '!.swiftpm/**' \
    --glob '!DerivedData/**' |
    rg --pcre2 '(^|/)(\.env($|\.)|id_(rsa|dsa|ecdsa|ed25519)$|[^/]+\.(pem|p12|pfx|key|mobileprovision)$)' || true
)

if (( FAILED != 0 )); then
  echo "Public release safety checks failed."
  exit 1
fi

echo "Public release safety checks passed."
