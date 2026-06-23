---
name: Command request
about: Suggest a command or search alias
title: "[Command] "
labels: enhancement, command-request
assignees: ""
---

## Command idea

What should the command do?

Good examples:

- Convert typed time like `9:30 UTC to local`.
- Clean copied text by removing duplicate lines.
- Open a common folder from Commands.
- Add a search alias so `dedupe` finds `Unique Lines Clipboard`.

Before filing, read [docs/COMMAND_DESIGN.md](../../docs/COMMAND_DESIGN.md).

## Input

Pick one: selected text, clipboard, reader text, answer, image, app/window, no input, other.

Example: clipboard text.

## Output or action

What should happen after the command runs?

Example: copy cleaned text to the clipboard and show `Copied`.

## Search words

What would you type to find this command?

Example: `dedupe`, `remove duplicates`, `unique lines`.

## Privacy

Should this command avoid selected text, answers, screenshots, API keys, clipboard contents, or private files?

Example: It can read clipboard text, but it must not save it to logs or reports.

## Current workaround

What do you do today?
