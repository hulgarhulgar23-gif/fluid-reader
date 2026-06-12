# Submission Notes

Use this page when applying for OSS maintainer access.

Current official page checked: 2026-06-12

- Form: https://openai.com/form/codex-for-oss/
- Program page: https://developers.openai.com/community/codex-for-oss

## Project

Fluid Reader

## Repository

https://github.com/hulgarhulgar23-gif/fluid-reader

## Live Pre-Submit Check

Run this before submitting the form:

```sh
zsh scripts/check_submission_live.sh
```

This checks that the repository URL above is publicly reachable through GitHub and is not archived. Do not add this network check to normal CI.

Before making the repository public, run:

```sh
zsh scripts/check_public_publish_ready.sh
```

This fails if local `main` is dirty, not pushed, or does not match the submission repository. Make the repo public only after this passes, then run `zsh scripts/check_submission_live.sh` again.

## Short Description

Fluid Reader is a local-first macOS reader and command app. It helps users read selected text, OCR screen content, copy useful results, save snippets, run quick local tools, and optionally ask an LLM about selected content.

## Why It Matters

Fluid Reader keeps the default path private and local:

- Screen capture stays on the Mac.
- OCR uses Apple Vision.
- Speech uses macOS voices.
- LLM support is optional and off by default.
- Support bundles avoid private reader content by default.

The project is useful for people who want a small, native, keyboard-first reader tool instead of a heavy cloud-first app.

## Maintainer Role

Primary maintainer and author.

## Current OpenAI Form Requirements

- GitHub username must be public.
- GitHub repository must be public.
- Role must be `Primary maintainer` or `Core maintainer`.
- Why does this repository qualify? has a 500 character max.
- How will you use API credits for your project? has a 500 character max.
- OpenAI Organization ID is required in the live form. Fill it in the form only; do not commit personal account IDs.
- Selected maintainers may receive six months of ChatGPT Pro with Codex, conditional Codex Security access, and API credits for core OSS work.

## OpenAI Form Answers

### Why does this repository qualify? (500 characters max)

<!-- openai-why-start -->
Fluid Reader is an active MIT macOS project for local-first screen reading, OCR, speech, snippets, support bundles, and optional LLM help. It matters because it gives keyboard-first accessibility/productivity tools without making cloud use the default. The repo now has release, safety, privacy, docs, and CI gates for real maintenance work.
<!-- openai-why-end -->

### How will you use API credits for your project? (500 characters max)

<!-- openai-api-start -->
Use API credits only for maintainer work: Codex-assisted issue triage, PR review, release checks, test/doc improvements, optional LLM safety review, and small automation around support bundles. The app remains useful without a key; credits help maintain the OSS workflow and review quality.
<!-- openai-api-end -->

### Anything else we should know? (500 characters max)

Fluid Reader is early but maintained actively. The project is small, native, MIT-licensed, private by default, and now has CI checks for size, docs, release packaging, Swift safety, public secret safety, and open-source submission readiness.

## Older OpenAI Form Answer

I maintain Fluid Reader, a local-first macOS command app for reading and acting on screen content. It uses native macOS APIs for OCR, speech, shortcuts, clipboard workflows, snippets, quick conversions, setup checks, and support bundles. LLM support is optional and off by default, so the app is still useful without an API key.

The project is open source under MIT. My goal is to keep it small, private by default, and easy for contributors to understand. Access to ChatGPT Pro/Codex would help me improve the codebase, fix issues faster, write clearer tests/docs, and keep the optional LLM path safe and well-reviewed.

## Anthropic Note

Anthropic's OSS program is stricter. Submit only if the project meets their current public criteria or if asking for an exception because the project is early but useful.
