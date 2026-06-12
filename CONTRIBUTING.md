# Contributing

Thanks for helping Fluid Reader.

By contributing, you agree that your work is shared under the [MIT License](LICENSE).

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Build

```sh
swift build -c release
```

Build the app bundle:

```sh
zsh scripts/build_app.sh
```

The bundle uses ad-hoc signing by default. To use your own signing identity:

```sh
FLUID_READER_SIGN_IDENTITY="Apple Development: Your Name" zsh scripts/build_app.sh
```

## Test

```sh
swift test
```

Check speed and app size:

```sh
zsh scripts/check_fast.sh
```

This fails if the app is larger than `1024K`.

Check docs links:

```sh
zsh scripts/check_docs.sh
```

Pull requests run these checks in GitHub Actions on macOS.

## Report a bug

Use the bug report issue template.

Read [SUPPORT.md](SUPPORT.md) first for the quickest help path.

Read [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) first for common permission, paste, OCR, and LLM fixes.

In the app, open `Commands` and run `Copy Issue Bundle`. Paste that into the issue.

If you only need the basics, run `Copy Support Info` instead.

Do not share API keys, selected text, answers, screenshots, private documents, custom prompts, custom endpoints, or clipboard contents.

## Report a security problem

Read [SECURITY.md](SECURITY.md) first.

Do not open a public issue with secrets, private text, screenshots, API keys, or clipboard contents.

## Code style

- Keep the app small and fast.
- Prefer local macOS features when they work well.
- Keep LLM features optional.
- Add focused tests for new logic.
- Use simple words in user-facing text.

## Project map

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before adding commands, stores, permissions, or release changes.

Try [docs/DEMO.md](docs/DEMO.md) before changing core flows.

Read [docs/COMMAND_DESIGN.md](docs/COMMAND_DESIGN.md) before adding a command or search alias.

Read [docs/ROADMAP.md](docs/ROADMAP.md) when choosing what to build next.

Read [docs/GOOD_FIRST_ISSUES.md](docs/GOOD_FIRST_ISSUES.md) for small starter tasks.
