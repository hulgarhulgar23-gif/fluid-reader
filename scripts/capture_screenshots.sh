#!/usr/bin/env zsh
# Capture real app screenshots for the landing page (docs/index.html).
#
# Requirements (macOS will prompt as needed):
#   - Screen Recording permission for the terminal app running this script
#   - Accessibility / Automation permission (System Events, TextEdit)
#   - Screen Recording permission for FluidReader.app itself (for Pick & Read)
#
# Usage:  scripts/capture_screenshots.sh
# Output: docs/assets/shot-reader.png, docs/assets/shot-palette.png

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"
OUT_DIR="$ROOT_DIR/docs/assets"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# --- 0. Preflight: do we have screen recording? -----------------------------
if ! screencapture -x "$TMP_DIR/preflight.png" 2>/dev/null; then
  echo "ERROR: This terminal lacks Screen Recording permission." >&2
  echo "Grant it in System Settings > Privacy & Security > Screen & System Audio Recording, restart the terminal, and re-run." >&2
  exit 1
fi

# --- 1. Swift helper: window lookup + synthetic mouse drag -------------------
cat > "$TMP_DIR/helper.swift" <<'SWIFT'
import AppKit
import CoreGraphics

let args = CommandLine.arguments
func fail(_ msg: String) -> Never { FileHandle.standardError.write((msg + "\n").data(using: .utf8)!); exit(1) }

switch args.count > 1 ? args[1] : "" {
case "windows":
    // windows <ownerSubstring> -> lines: "<windowID> <width> <height> <title>"
    let owner = args.count > 2 ? args[2] : ""
    guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { fail("no window list") }
    for info in list {
        guard let name = info[kCGWindowOwnerName as String] as? String,
              name.localizedCaseInsensitiveContains(owner),
              let id = info[kCGWindowNumber as String] as? Int,
              let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
              let w = bounds["Width"], let h = bounds["Height"],
              w > 50, h > 50
        else { continue }
        let title = (info[kCGWindowName as String] as? String) ?? ""
        print("\(id) \(Int(w)) \(Int(h)) \(title)")
    }
case "drag":
    // drag <x1> <y1> <x2> <y2>  (global screen coordinates, top-left origin)
    guard args.count == 6,
          let x1 = Double(args[2]), let y1 = Double(args[3]),
          let x2 = Double(args[4]), let y2 = Double(args[5]) else { fail("usage: drag x1 y1 x2 y2") }
    let start = CGPoint(x: x1, y: y1), end = CGPoint(x: x2, y: y2)
    func post(_ type: CGEventType, _ p: CGPoint) {
        CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
        usleep(30_000)
    }
    post(.mouseMoved, start)
    usleep(200_000)
    post(.leftMouseDown, start)
    let steps = 25
    for i in 1...steps {
        let t = Double(i) / Double(steps)
        post(.leftMouseDragged, CGPoint(x: x1 + (x2 - x1) * t, y: y1 + (y2 - y1) * t))
    }
    post(.leftMouseUp, end)
default:
    fail("usage: helper windows <owner> | drag x1 y1 x2 y2")
}
SWIFT
swiftc -O -o "$TMP_DIR/helper" "$TMP_DIR/helper.swift"
HELPER="$TMP_DIR/helper"

capture_largest_window() {
  # capture_largest_window <ownerSubstring> <outPath>
  local owner="$1" out="$2" line
  line="$("$HELPER" windows "$owner" | sort -k2,2n -k3,3n | tail -1)" || true
  if [[ -z "$line" ]]; then
    echo "WARN: no window found for '$owner'" >&2
    return 1
  fi
  local id="${line%% *}"
  screencapture -o -l"$id" "$out"
  echo "captured: $out ($line)"
}

key_combo() {
  # key_combo <keycode>   (always with option+shift)
  osascript -e "tell application \"System Events\" to key code $1 using {option down, shift down}"
}

# --- 2. Build and launch the app ---------------------------------------------
echo "Building FluidReader.app..."
APP_PATH="$(scripts/build_app.sh | tail -1)"

# Skip the first-run setup checklist so it doesn't cover the shots.
defaults write dev.oss.fluidreader didShowFirstRunSetupChecklist -bool true

pkill -x FluidReader 2>/dev/null || true
sleep 1
open "$APP_PATH"
sleep 3

# --- 3. Sample content in TextEdit for Pick & Read --------------------------
cat > "$TMP_DIR/sample.txt" <<'TXT'
The quickest way to read anything on screen.

Fluid Reader uses on-device OCR to turn whatever you
draw around into spoken words. PDFs, images, screenshots,
video frames - if you can see it, you can hear it.

No account. No cloud. Just your Mac.
TXT
open -a TextEdit "$TMP_DIR/sample.txt"
sleep 2
osascript -e 'tell application "TextEdit" to set bounds of front window to {120, 120, 860, 560}' \
          -e 'tell application "TextEdit" to activate'
sleep 1

# --- 4. Shot 1: Pick & Read (⌥⇧R, then drag around the text) ----------------
echo "Triggering Pick & Read (⌥⇧R)..."
key_combo 15   # R
sleep 1.5
"$HELPER" drag 150 170 830 520
echo "Waiting for OCR + reader window..."
sleep 5
capture_largest_window "FluidReader" "$OUT_DIR/shot-reader.png" \
  || capture_largest_window "Fluid Reader" "$OUT_DIR/shot-reader.png" || true

# Close reader window
osascript -e 'tell application "System Events" to key code 53' # esc
sleep 1

# --- 5. Shot 2: Command palette (⌥⇧Space) ------------------------------------
echo "Opening command palette (⌥⇧Space)..."
key_combo 49   # space
sleep 2
capture_largest_window "FluidReader" "$OUT_DIR/shot-palette.png" \
  || capture_largest_window "Fluid Reader" "$OUT_DIR/shot-palette.png" || true
osascript -e 'tell application "System Events" to key code 53' # esc

# --- 6. Cleanup ---------------------------------------------------------------
pkill -x FluidReader 2>/dev/null || true
osascript -e 'tell application "TextEdit" to close front window saving no' 2>/dev/null || true

echo ""
echo "Done. Review:"
ls -la "$OUT_DIR"/shot-*.png 2>/dev/null || echo "  (no shots captured - check permissions and re-run)"
