# Architecture

Fluid Reader is a small native macOS app. Keep changes simple, local-first, and easy to test.

Read [ROADMAP.md](ROADMAP.md) before adding larger features.

## Main Flow

1. `FluidReaderMain.swift` starts the app.
2. `AppDelegate.swift` wires the menu bar, hotkeys, Commands, reader state, OCR, speech, LLM, and exports.
3. `CommandPaletteWindowController.swift` shows Commands and handles search, favorites, shortcuts, and ranking.
4. `ReaderWindowController.swift` shows text, answers, images, recent items, snippets, and quick buttons.
5. `SelectionController.swift` and `SelectionOverlayView.swift` handle screen picking.
6. `OCRService.swift` reads picked screen text with Apple Vision.
7. `SpeechService.swift` speaks text with macOS voices.
8. `OpenAIClient.swift` handles optional LLM and cloud voice calls.

## Local Stores

- `SettingsStore.swift` stores user settings.
- `ReaderState.swift` stores current text, answers, images, recent items, and snippets.
- `QuickLinkStore.swift` stores saved links.
- `ClipboardHistoryStore.swift` stores optional clipboard history.
- `ActivityLog.swift` stores safe support events.

Do not store API keys, selected text, answers, screenshots, snippets, quick links, clipboard history, custom prompts, custom endpoints, or clipboard contents in support reports unless the user copies them on purpose.

## Adding A Command

Read [COMMAND_DESIGN.md](COMMAND_DESIGN.md) before adding a user-facing command.

Most commands are built in `makeCommandPaletteActions()` inside `AppDelegate.swift`.

When adding a command:

- Give it a stable `id`.
- Use a short title and subtitle.
- Add useful search keywords.
- Add a clear disabled reason if it needs text, an answer, an image, a permission, or saved data.
- Keep private data out of activity logs.
- Add focused tests for pure logic.
- Update [COMMANDS.md](COMMANDS.md) if the command is user-facing.

Prefer small helper types for logic that can be tested without launching the app. Good examples are `ClipboardUtilities.swift`, `WebSearch.swift`, `LocalFilePath.swift`, `ResultExporter.swift`, and `SettingsBackup.swift`.

## Permissions

Screen pick needs Screen Recording permission.

Paste and window move commands need Accessibility permission.

LLM is off by default. Keep cloud features optional and clear.

## Release Checks

Run these before sending a pull request:

```sh
swift test
git diff --check
zsh scripts/check_ci_hardening.sh
zsh scripts/check_ci_hardening_fixture.sh
zsh scripts/check_swift_safety.sh
zsh scripts/check_swift_safety_fixture.sh
zsh scripts/check_public_release_safety.sh
zsh scripts/check_open_source_ready.sh
zsh scripts/check_open_source_ready_fixture.sh
zsh scripts/check_public_publish_ready_fixture.sh
zsh scripts/check_submission_live_fixture.sh
zsh scripts/check_public_release_safety_fixture.sh
zsh scripts/check_docs.sh
zsh scripts/check_growth.sh
zsh scripts/check_release_packaging_fixture.sh
zsh scripts/check_release_exact_cleanup_fixture.sh
zsh scripts/check_fast.sh
```

Before sharing a release zip, run:

```sh
zsh scripts/verify_release.sh
```

The app has a tight size gate. Avoid large bundled assets, provider SDKs, or broad dependencies.

`check_fast.sh` fails if the release executable is larger than `2816K` by default.

`verify_release.sh` also checks app metadata, bundle size, zip size, and launch.
