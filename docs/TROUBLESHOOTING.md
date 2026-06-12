# Troubleshooting

Use this when Fluid Reader does not read, paste, ask, or move windows.

You can also open Commands and run `Copy Troubleshooting Guide`. That copied guide includes your current permission status, but it does not include private reader content.

## Fast Permission Recovery

If any read/paste/window command is blocked:

1. Open Commands.
2. Run `Setup Checklist`.
3. Open the missing permission row (`Screen Recording` or `Accessibility`).
4. Allow Fluid Reader in macOS settings.
5. Quit and reopen Fluid Reader.
6. Retry `Read Selected Text`, `Paste Last Text`, or a window command.

If it still fails, run `Copy Issue Bundle` before filing an issue.

## Selected Text Does Not Read

1. Open Commands.
2. Run `Accessibility Settings`.
3. Allow Fluid Reader.
4. Select text in another app.
5. Run `Read Selected Text`.

If it still fails, copy the text yourself and run `Read Clipboard Text`.

## Screen Pick Does Not Read Text

1. Open Commands.
2. Run `Screen Recording Settings`.
3. Allow Fluid Reader.
4. Try `Pick and Read` again.
5. Draw a tight shape around only the text.
6. Try a different OCR language from Commands.

If it still fails, run `Copy Issue Bundle` and open a bug report.

If you just allowed Screen Recording and screen pick still fails, quit and reopen Fluid Reader.

## Paste Does Not Work

1. Open Commands.
2. Run `Accessibility Settings`.
3. Allow Fluid Reader.
4. Click the app where you want text pasted.
5. Run `Paste Last Text`, `Paste Answer`, or `Paste Full Result`.

If paste still fails, run `Copy Last Text` or `Copy Answer`, then paste by hand.

If you just allowed Accessibility and paste still fails, quit and reopen Fluid Reader.

## Window Commands Do Not Work

1. Open Commands.
2. Run `Accessibility Settings`.
3. Allow Fluid Reader.
4. Click the app window you want to move.
5. Run `Window Left Half`, `Window Right Half`, `Window Maximize`, or `Window Center`.

If you just allowed Accessibility and window commands still fail, quit and reopen Fluid Reader.

## LLM Does Not Answer

1. Open Settings.
2. Turn on LLM.
3. Add an API key.
4. Check the model, provider, and endpoint.
5. Run `Copy Error Message` if the error text helps.

Run `Copy Issue Bundle` if the error is not clear.

## App Feels Stuck

1. Run `Stop Speech`.
2. Run `Show Reader`.
3. Run `Clear Reader`.
4. Run `Clear Local Reader Data` if you want to remove local reader state.

`Clear Local Reader Data` does not change settings or API keys.

## Good Bug Reports

Use the GitHub bug report template.

In Fluid Reader, open Commands and run `Copy Issue Bundle`. Paste that into the issue. It includes support info and the newest safe app events.

Good examples:

- Problem type: paste. Steps: copied text, opened Notes, ran `Paste Last Text`, nothing pasted.
- Problem type: screen pick/OCR. Steps: ran `Pick and Read`, drew around text, got no reader text.
- Problem type: LLM. Steps: turned on LLM, added API key, ran `Summary`, got an error.

Do not paste API keys, selected text, answers, screenshots, private documents, custom prompts, custom endpoints, or clipboard contents.

## Privacy

The public guide does not need private data.

`Copy Troubleshooting Guide` does not include API keys, selected text, answers, images, snippets, quick links, clipboard history, custom prompts, custom endpoints, clipboard contents, or recent item text.
