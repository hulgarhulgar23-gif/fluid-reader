# Command Design

Commands should make common work fast from one shortcut.

Use this guide before adding a new command or search alias.

## Good Commands

A good command:

- Solves one clear task.
- Has a short name.
- Works fast.
- Works without setup when possible.
- Keeps private data local unless the user asks to send or export it.
- Fits the app size limit.

Good examples:

- Copy a safe support report.
- Clean a URL.
- Save selected text as a snippet.
- Open a saved link.
- Move the front window.

## Skip Or Delay

Do not add a command if it needs:

- A large SDK.
- A bundled model.
- Public telemetry.
- Private text in logs or issue reports.
- A broad UI rewrite.

Put bigger ideas in [ROADMAP.md](ROADMAP.md) first.

## Command Shape

Most commands live in `makeCommandPaletteActions()` in `Sources/FluidReader/AppDelegate.swift`.

Each command needs:

- Stable `id`.
- Short `title`.
- Clear `subtitle`.
- Useful `keywords`.
- A disabled reason if it needs text, an answer, an image, saved data, or a permission.
- A small action that calls tested helper code when possible.

Keep titles action-first:

- `Copy Support Info`
- `Save Clipboard as Link`
- `Window Left Half`

Avoid vague names:

- `Tools`
- `Helper`
- `Magic`

## Search Words

Add words people might type, not only code words.

For example, a URL cleanup command can include:

- `url`
- `link`
- `clean`
- `tracking`
- `utm`

Aliases are good first issues when they come from real user search words.

## Privacy

Before adding a command, decide what data it can touch.

Private by default:

- API keys
- Selected text
- Answers
- Screenshots
- Snippets
- Quick links
- Clipboard history
- Custom prompts
- Custom endpoints
- Clipboard contents

Support commands must not include private data unless the user copies it on purpose.

## Tests And Docs

Add pure logic to a small helper type when you can. Then add focused tests.

Update [COMMANDS.md](COMMANDS.md) when users can see the new command.

For command requests, ask for:

- Input
- Output or action
- Search words
- Privacy limits
- Current workaround

Before a pull request, run:

```sh
swift test
zsh scripts/check_docs.sh
zsh scripts/check_fast.sh
```
