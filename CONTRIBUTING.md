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

Check whitespace:

```sh
git diff --check
```

If you change CI, check its safety gates:

```sh
zsh scripts/check_ci_hardening.sh
```

If you change CI hardening checks, run the fixture too:

```sh
zsh scripts/check_ci_hardening_fixture.sh
```

Check speed and app size:

```sh
zsh scripts/check_fast.sh
```

This fails if the app executable is larger than `2816K`.

Check for high-risk Swift code:

```sh
zsh scripts/check_swift_safety.sh
```

This fails on forced casts, forced try, and crash-only failures.

If you change Swift safety checks, run the fixture too:

```sh
zsh scripts/check_swift_safety_fixture.sh
```

Check for public-release safety:

```sh
zsh scripts/check_public_release_safety.sh
```

This fails on real key formats and local secret files.

Check open-source and submission readiness:

```sh
zsh scripts/check_open_source_ready.sh
```

This fails if required community files or privacy/submission notes are missing.

Before submitting to an OSS program, run the live repository check:

```sh
zsh scripts/check_submission_live.sh
```

This fails if the documented GitHub repository is not public or reachable.

Before making the GitHub repository public, run:

```sh
zsh scripts/check_public_publish_ready.sh
```

This fails if `main` is dirty, not pushed, or the release checks do not pass.

If you change the open-source readiness check, run the fixture too:

```sh
zsh scripts/check_open_source_ready_fixture.sh
```

If you change the live submission check, run the fixture too:

```sh
zsh scripts/check_submission_live_fixture.sh
```

If you change the public-publish readiness check, run the fixture too:

```sh
zsh scripts/check_public_publish_ready_fixture.sh
```

If you change public safety checks, run the fixture too:

```sh
zsh scripts/check_public_release_safety_fixture.sh
```

Check docs links:

```sh
zsh scripts/check_docs.sh
```

Check growth docs and workflow fixtures:

```sh
zsh scripts/check_growth.sh
```

Check release script fixtures:

```sh
zsh scripts/check_release_packaging_fixture.sh
```

If you change release launch or cleanup logic, run:

```sh
zsh scripts/check_release_exact_cleanup_fixture.sh
```

Before a release, check the app bundle, zip, metadata, size, and launch:

```sh
zsh scripts/verify_release.sh
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
