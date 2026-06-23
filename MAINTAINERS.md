# Maintainers

Fluid Reader is actively maintained in public.

## Primary maintainer

- GitHub: `hulgarhulgar23-gif`
- Role: primary maintainer and author

## What maintainers do

- Triage bug reports, support issues, and command ideas
- Review pull requests for privacy, security, local-first behavior, tests, size, and code quality
- Run release checks before public releases
- Keep the website, release notes, Homebrew cask, and support docs in sync
- Keep support bundles and issue flows safe for private data
- Own review routing through `.github/CODEOWNERS` and dependency updates through `.github/dependabot.yml`

## Before merge

- Run `swift test`
- Run `zsh scripts/check_open_source_ready.sh`
- Run `zsh scripts/check_public_release_safety.sh`
- If CI or safety checks changed, run the matching fixture checks from `CONTRIBUTING.md`

## Before release

- Run `zsh scripts/verify_release.sh`
- Run `zsh scripts/check_submission_live.sh` before OSS-program submissions
- Upload `FluidReader.zip` to GitHub Releases
- Update the Homebrew cask `sha256` when the release asset changes

## Support and security

- Start with [SUPPORT.md](SUPPORT.md) for user help and safe issue bundles
- Start with [SECURITY.md](SECURITY.md) for private or security-sensitive reports
- Do not ask users to paste API keys, private reader text, screenshots, or clipboard contents into public issues
