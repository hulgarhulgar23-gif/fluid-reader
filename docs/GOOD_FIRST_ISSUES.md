# Good First Issues

Good first issues should make Fluid Reader more useful without making the app heavy.

Pick work that is small, easy to test, and safe for private user data.

## Good Fits

- Add command aliases from real search words.
- Turn a clear command request into a small command.
- Improve docs with safe examples.
- Add focused tests for existing helpers.
- Make error text clearer.
- Improve permission or setup wording.
- Add tiny clipboard or text helpers only if `check_fast.sh` still passes.

## Skip For First PRs

- New provider SDKs.
- Large UI rewrites.
- Telemetry.
- Sync.
- Big assets.
- Features that put private text into logs or issues.

## Before You Start

1. Read [ROADMAP.md](ROADMAP.md).
2. Read [ARCHITECTURE.md](ARCHITECTURE.md).
3. Try [DEMO.md](DEMO.md).
4. Read [COMMAND_DESIGN.md](COMMAND_DESIGN.md) before adding a command.
5. Say which file or command you want to change.
6. Keep the pull request small.
7. Run `swift test`.
8. Run `zsh scripts/check_docs.sh`.
9. Run `zsh scripts/check_fast.sh`.

## Good Labels

Use `good first issue` for work that has a clear file, clear expected result, and no private data risk.

Use `help wanted` for useful work that may need design or product choices.

Use command request issues to collect input, output, search words, and privacy notes before building a new command.
