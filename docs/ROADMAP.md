# Roadmap

Fluid Reader should feel like a small, fast command app for reading and acting on screen content.

The goal is not to copy another app. The goal is to keep the same useful idea: one shortcut, fast search, useful actions, and low friction.

## Product Rules

- Keep the first action fast.
- Keep local mode strong.
- Keep LLM features optional.
- Keep user-facing words simple.
- Keep private data out of reports and logs.
- Keep the app small enough for `check_fast.sh`.
- Prefer native macOS APIs over large dependencies.

## Now

These are the best near-term areas.

- More Commands aliases based on real user searches.
- More typed helper aliases, based on real user searches.
- Better saved items: keyboard-first polish for snippet and quick-link rename/edit flows.
- Better issue help: add clearer issue examples from real reports.
- Better first run: clearer permission recovery text.

## Next

These are useful after the current app size has more room.

- Command groups, so users can scan actions by kind.
- More window actions, such as thirds and move to next display.
- More local OCR helpers, such as copy detected text blocks separately.
- A small command import/export format for saved prompts and quick links.
- Better keyboard control in the reader window.

## Later

These need more care or more size budget.

- Extension-style command plugins.
- More LLM providers.
- OCR post-processing per language.
- Optional sync between Macs.
- Signed release automation.

## Not Now

These do not fit the current app.

- Bundled model files.
- Large sound, image, or animation assets.
- Heavy SDKs for each provider.
- Public telemetry.
- Features that require private data in issues by default.

## Picking Work

Good work is small, testable, and useful without setup.

Before opening a pull request:

1. Check this roadmap.
2. Read [ARCHITECTURE.md](ARCHITECTURE.md).
3. Try the short flow in [DEMO.md](DEMO.md).
4. Read [GOOD_FIRST_ISSUES.md](GOOD_FIRST_ISSUES.md) for small starter tasks.
5. Update [COMMANDS.md](COMMANDS.md) if users see a new command.
6. Run `swift test`.
7. Run `zsh scripts/check_fast.sh`.
