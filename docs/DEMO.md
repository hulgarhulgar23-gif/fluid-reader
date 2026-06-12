# Demo

Use this when showing Fluid Reader to a new user, tester, or contributor.

See [WORKFLOWS.md](WORKFLOWS.md) for task-based examples after the demo.

## One Minute

1. Select text in any app.
2. Press `Option + Shift + Space`.
3. Run `Read Selected Text`.
4. Open Commands again.
5. Type `2 + 3 * 4` and copy the answer.
6. Type `10 km to miles` and copy the conversion.
7. Type `09:00 UTC to local` and copy the time.
8. Type `#ff8800` and copy HEX, RGB, and HSL.
9. Run `Ask Anything` if LLM is on.

## Three Minutes

Show the daily workflow:

1. Run `Pick and Read` with no selected text.
2. Draw around screen text.
3. Run `Copy Text as Quote`.
4. Run `Save Text as Snippet`.
5. Search `snippet` and copy the saved item.
6. Run `Open Clipboard URL` or `Search Clipboard Web`.
7. Run `Window Left Half` or `Window Right Half`.

Show the trust workflow:

1. Run `Setup Checklist`.
2. Run `Copy Support Info`.
3. Run `Copy Issue Bundle`.
4. Point out that private reader content is skipped.

## What To Say

Fluid Reader is a small local-first macOS command app. One shortcut can read, ask, copy, paste, save, open, convert, and help file useful bug reports. LLM is optional, and local mode works without an API key.

## Demo Rules

- Do not show private documents.
- Do not show API keys.
- Keep examples short.
- Keep the app under the release size cap with `zsh scripts/check_fast.sh`.
