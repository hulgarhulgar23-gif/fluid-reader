# Fluid Reader

Fluid Reader is a small macOS menu-bar app. Press `Option + Shift + R`, draw around any screen content, and the app reads the text it finds.

The default mode is local:

- Screen capture stays on the Mac.
- OCR uses Apple Vision.
- Speech uses the macOS voices.
- LLM support is off until the user turns it on.

## Build

```sh
swift build -c release
```

To make a small `.app` bundle:

```sh
zsh scripts/build_app.sh
```

The app will be at:

```text
.build/FluidReader.app
```

To make a small zip for sharing:

```sh
zsh scripts/package_app.sh
```

The zip will be at:

```text
.build/FluidReader.zip
```

To check build, package size, and launch:

```sh
zsh scripts/verify_release.sh
```

## Use

1. Open `FluidReader.app`.
2. Allow Screen Recording when macOS asks.
3. Press `Option + Shift + R`.
4. Draw a freehand shape around the content.
5. Release the mouse to read it.

Open the menu-bar item to show the reader window, stop speech, or change settings.

## Feel

The app has small built-in sounds and haptic taps for pick, draw, capture, scan, and success. They are made in code, so there are no large audio files. You can turn them off or change the sound level in Settings.

The `Hit` slider controls how strong the reward moment feels. Higher values add a little more lift to sound, haptics, glow, and the success HUD.

The sound `Style` picker gives three generated palettes: `Soft`, `Glass`, and `Jackpot`.

The menu bar has a `Feel` submenu for quick tuning.

Inside `Feel`, use `Sound Style` to switch styles quickly and then run `Preview Feel`.

Use `Compare Styles` from the menu bar to hear `Soft`, `Glass`, and `Jackpot` back to back. It restores the old style after the comparison.

The `Hit Level` submenu gives quick presets: `Calm`, `Bright`, and `Max`.

Use `Big Win Preview` from the menu bar to switch to `Jackpot + Max` and play the strongest full preview.

Use `Preview Feel` from the menu bar, or `Test Full Feel` in Settings, to hear and see the full tap, scan, capture, and success loop without taking a screen pick.

A small floating HUD appears after capture, so local mode still gives a clear reward moment even when the reader window is hidden. While the app reads, the HUD shows three small moving reels. On success, they land into a three-symbol win with a short sparkle burst and a slightly longer hold.

The menu-bar icon flashes during pick, scan, success, and error states. The lasso also has a soft glow and moving glints while the user draws. The overlay fades in and out quickly, so capture and cancel do not feel abrupt.

## Speed

Fluid Reader is native Swift and has no bundled sound files. The release app is meant to stay small and fast to build. Run this check any time:

All sound styles are cached at launch, so style switching, comparison, and Big Win previews do not need to generate sound data during the interaction.

The app also warms the audio path with a silent generated sound at launch, which helps the first real tap feel instant.

The picker animation runs only while the overlay is open. Its lasso path is cached between point changes, so moving glints and glow do less work per frame.

```sh
zsh scripts/check_fast.sh
```

## Optional LLM

LLM is off by default. To use it, open Settings, turn on LLM, and add an OpenAI API key. The app can then ask about the selected text and image. Cloud voice for LLM answers is also optional, and its voice style can be changed in Settings.
