# Power User Guide

Fluid Reader is most useful when you treat Commands as the first stop for small work.

Open Commands with `Option + Shift + Space`, type what you want, press `Return`, and keep going.

## First 10 Things To Try

1. Select text and run `Read Selected Text`.
2. Type `2 + 3 * 4`.
3. Type `10 km to miles`.
4. Type `09:00 UTC to local`.
5. Type `#ff8800`.
6. Select a URL and run `Copy Selected Clean URL`.
7. Select JSON and run `Copy Selected Pretty JSON`.
8. Select messy text and run `Single Space Selected`.
9. Search an app name, such as `Safari`, `Terminal`, or `Notes`.
10. Run `Copy Issue Bundle` to see the safe support report.

## Daily Use

Use Fluid Reader as a small command layer over every Mac app.

- Read selected text without switching apps.
- Pick text from the screen when selection does not work.
- Ask a short LLM question about current text, clipboard text, or a picked image.
- Copy answers, quotes, code blocks, checklists, bullets, and tables.
- Paste the last text or answer back into the app you were using.
- Save snippets and links for reuse.
- Open files, folders, URLs, and apps from one place.
- Move the last active window with quick window commands.

## Typed Answers

You can type small questions straight into Commands.

- Math: `2 + 3 * 4`, `sqrt(81)`, `pi * 2`
- Units: `10 km to miles`, `2 cups to ml`, `8 fl oz to ml`
- Time zones: `09:00 UTC to local`, `14:30 UTC+8 to UTC`
- Colors: `#ff8800`, `rgb(255, 136, 0)`, `hsl(32, 100%, 50%)`
- URLs: paste or type a URL to open it, clean it, or copy it as Markdown
- Paths: type `/Users/me/Downloads/file.pdf` or `~/Desktop` to open or reveal it

## Text Cleanup

Use selected-text commands when the source text is already highlighted.

- Format or minify JSON.
- Encode or decode Base64.
- Make slugs, snake case, constant case, camel case, or Pascal case.
- Uppercase, lowercase, title case, or single-space text.
- Remove terminal colors from logs.
- Trim, join, reverse, sort, or dedupe lines.
- Turn lines into bullets, numbered lists, checklists, or Markdown tables.
- Clean copied CSV or TSV.
- Count lines, words, and characters.

Use clipboard commands for the same work when the text is already copied.

## Link Work

Good link flows:

1. Select a URL.
2. Run `Copy Selected Clean URL`.
3. Run `Copy Selected URL as Markdown Link`.
4. Run `Save Selected as Link` if you will use it again.

For text with many links, run `Copy Selected URLs`, `Copy Selected Domains`, or `Copy Selected Emails`.

## Notes And Replies

Useful writing flows:

- Select rough notes and run `Copy Selected as Bullets`.
- Select a task list and run `Copy Selected as Checklist`.
- Select logs or code and run `Copy Selected as Code Block`.
- Select quoted text and run `Copy Selected as Quote`.
- If LLM is on, run `Summary`, `Action Items`, `Rewrite`, or `Reply Draft`.

## Developer Work

Fluid Reader is useful as a tiny scratchpad while coding.

- Convert time zones for release notes and meetings.
- Convert units and colors while working on UI.
- Clean JSON from APIs or logs.
- Decode or encode Base64.
- Strip ANSI colors from terminal output.
- Make slugs and case variants for names, files, keys, and ids.
- Extract URLs, domains, and emails from pasted text.
- Save useful snippets for commands, notes, or issue replies.

## Local-First Trust

The default mode is local.

- Screen capture stays on the Mac.
- OCR uses Apple Vision.
- Speech uses macOS voices.
- LLM support is off until the user turns it on.
- Support reports skip API keys, selected text, answers, images, snippets, links, clipboard history, custom prompts, custom endpoints, and clipboard contents.

Use `Copy Support Info`, `Copy Activity Log`, or `Copy Issue Bundle` when you need help without leaking private content by default.

## Fast Demo

Use this path to show the value in less than three minutes:

1. Select text and run `Read Selected Text`.
2. Type `sqrt(81)`.
3. Type `8 fl oz to ml`.
4. Type `14:30 UTC+8 to UTC`.
5. Type `#ff8800`.
6. Select a messy paragraph and run `Copy Selected as Bullets`.
7. Select a URL and run `Copy Selected Clean URL`.
8. Search `folder` and open Downloads.
9. Search an app name and open it.
10. Run `Copy Issue Bundle` and point out what private data is skipped.

## Make It Better

The best open source work is small and useful.

- Add search aliases from real user words.
- Add small commands that help often.
- Improve setup and error text.
- Add tests for helpers.
- Keep private data out of logs and reports.
- Keep the app under the release size cap.

Before adding a visible command, read [COMMAND_DESIGN.md](COMMAND_DESIGN.md) and update [COMMANDS.md](COMMANDS.md).
