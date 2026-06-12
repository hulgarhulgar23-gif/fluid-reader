#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SCRIPT="$ROOT_DIR/scripts/check_submission_live.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

write_repo() {
  local repo_dir="$1"
  local repo_url="$2"
  local profile_body="$3"
  local profile_code="$4"
  local repo_body="$5"
  local repo_code="$6"
  local gh_body="${7:-}"

  mkdir -p "$repo_dir/scripts" "$repo_dir/docs" "$repo_dir/bin"
  cp "$SOURCE_SCRIPT" "$repo_dir/scripts/check_submission_live.sh"
  chmod +x "$repo_dir/scripts/check_submission_live.sh"

  cat > "$repo_dir/docs/SUBMISSION.md" <<EOF
# Submission Notes

## Repository

$repo_url
EOF

  cat > "$repo_dir/bin/curl" <<EOF
#!/usr/bin/env zsh
set -euo pipefail

output_file=""
url=""
while (( \$# > 0 )); do
  case "\$1" in
    --output)
      output_file="\$2"
      shift 2
      ;;
    --write-out)
      shift 2
      ;;
    *)
      if [[ "\$1" == https://api.github.com/* ]]; then
        url="\$1"
      fi
      shift
      ;;
  esac
done

if [[ "\$url" == https://api.github.com/users/* ]]; then
  if [[ -n "\$output_file" ]]; then
    cat > "\$output_file" <<'BODY'
$profile_body
BODY
  fi
  printf '$profile_code'
  exit 0
fi

if [[ "\$url" == https://api.github.com/repos/* ]]; then
  if [[ -n "\$output_file" ]]; then
    cat > "\$output_file" <<'BODY'
$repo_body
BODY
  fi
  printf '$repo_code'
  exit 0
fi

printf '500'
EOF
  chmod +x "$repo_dir/bin/curl"

  cat > "$repo_dir/bin/gh" <<EOF
#!/usr/bin/env zsh
set -euo pipefail
cat <<'BODY'
$gh_body
BODY
EOF
  chmod +x "$repo_dir/bin/gh"
}

expect_pass() {
  local repo_dir="$TMP_DIR/pass"
  local output
  local profile_body
  local repo_body

  profile_body='{"login": "example", "type": "User", "user_view_type": "public"}'
  repo_body='{"private": false, "archived": false, "stargazers_count": 3, "forks_count": 1, "open_issues_count": 2, "pushed_at": "2026-06-12T00:00:00Z"}'
  write_repo "$repo_dir" "https://github.com/example/fluid-reader" "$profile_body" "200" "$repo_body" "200"

  if ! output="$(cd "$repo_dir" && PATH="$repo_dir/bin:$PATH" zsh scripts/check_submission_live.sh 2>&1)"; then
    echo "Expected live submission fixture to pass."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"Submission live checks passed."* ]]; then
    echo "Live submission fixture did not print pass message."
    echo "$output"
    exit 1
  fi
}

expect_fail() {
  local name="$1"
  local repo_url="$2"
  local profile_body="$3"
  local profile_code="$4"
  local repo_body="$5"
  local repo_code="$6"
  local expected="$7"
  local gh_body="${8:-}"
  local repo_dir="$TMP_DIR/$name"
  local output
  local exit_code

  write_repo "$repo_dir" "$repo_url" "$profile_body" "$profile_code" "$repo_body" "$repo_code" "$gh_body"

  set +e
  output="$(cd "$repo_dir" && PATH="$repo_dir/bin:$PATH" zsh scripts/check_submission_live.sh 2>&1)"
  exit_code=$?
  set -e

  if (( exit_code == 0 )); then
    echo "Expected $name fixture to fail."
    echo "$output"
    exit 1
  fi

  if [[ "$output" != *"$expected"* ]]; then
    echo "Expected $name fixture to mention: $expected"
    echo "$output"
    exit 1
  fi
}

expect_pass
expect_fail "missing-public-profile" "https://github.com/example/fluid-reader" '{"message":"Not Found"}' "404" '{}' "404" "GitHub username is not public or not reachable"
expect_fail "missing-public-repo" "https://github.com/example/missing" '{"login": "example", "type": "User"}' "200" '{"message":"Not Found"}' "404" "GitHub repository is not public or not reachable"
expect_fail "private-repo-from-gh" "https://github.com/example/private" '{"login": "example", "type": "User"}' "200" '{"message":"Not Found"}' "404" "GitHub repository exists but is private" '{"isPrivate":true,"visibility":"PRIVATE"}'
expect_fail "private-repo" "https://github.com/example/private" '{"login": "example", "type": "User"}' "200" '{"private": true, "archived": false}' "200" "GitHub repository must be public"
expect_fail "archived-repo" "https://github.com/example/archived" '{"login": "example", "type": "User"}' "200" '{"private": false, "archived": true}' "200" "GitHub repository must not be archived"

echo "Submission live fixture checks passed."
