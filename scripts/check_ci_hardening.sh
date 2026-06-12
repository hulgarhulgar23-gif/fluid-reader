#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

CI_WORKFLOW="$ROOT_DIR/.github/workflows/ci.yml"

if ! grep -Eq '^permissions:$' "$CI_WORKFLOW"; then
  echo "CI must set explicit workflow token permissions."
  exit 1
fi

if ! grep -Eq '^[[:space:]]+contents:[[:space:]]+read$' "$CI_WORKFLOW"; then
  echo "CI must keep contents permission read-only."
  exit 1
fi

if ! grep -Fq 'git diff --check' "$CI_WORKFLOW"; then
  echo "CI must check whitespace with git diff --check."
  exit 1
fi

if ! grep -Fq 'brew list ripgrep' "$CI_WORKFLOW"; then
  echo "CI must install ripgrep before running growth checks."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_ci_hardening.sh' "$CI_WORKFLOW"; then
  echo "CI must run the CI hardening check."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_ci_hardening_fixture.sh' "$CI_WORKFLOW"; then
  echo "CI must run the CI hardening fixture."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_workflow_dispatch_inputs.sh' "$CI_WORKFLOW"; then
  echo "CI must run the workflow dispatch input limit check."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_workflow_dispatch_inputs_fixture.sh' "$CI_WORKFLOW"; then
  echo "CI must run the workflow dispatch input limit fixture."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_open_source_ready.sh' "$CI_WORKFLOW"; then
  echo "CI must run the open-source readiness check."
  exit 1
fi

if ! grep -Fq 'zsh scripts/check_open_source_ready_fixture.sh' "$CI_WORKFLOW"; then
  echo "CI must run the open-source readiness fixture."
  exit 1
fi

echo "CI hardening checks passed."
