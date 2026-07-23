#!/usr/bin/env bash
# Render a page of the site to PNG at desktop and mobile widths.
#
#   scripts/screenshot.sh [page.html] [output-dir]
#
# Defaults: index.html, ./out
# Requires a Chromium/Chrome binary (checks $CHROME_BIN, then common paths).
set -euo pipefail

PAGE="${1:-index.html}"
OUTDIR="${2:-out}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/$PAGE" ]]; then
  echo "error: $PAGE not found in $ROOT" >&2
  exit 1
fi

# Find a browser binary
CHROME="${CHROME_BIN:-}"
if [[ -z "$CHROME" ]]; then
  for candidate in /opt/pw-browsers/chromium chromium chromium-browser google-chrome google-chrome-stable; do
    if command -v "$candidate" >/dev/null 2>&1; then CHROME="$candidate"; break; fi
  done
fi
if [[ -z "$CHROME" ]]; then
  echo "error: no Chromium/Chrome found; set CHROME_BIN" >&2
  exit 1
fi

mkdir -p "$OUTDIR"
NAME="$(basename "$PAGE" .html)"

shoot() { # width height outfile
  "$CHROME" --headless=new --disable-gpu --no-sandbox \
    --allow-file-access-from-files \
    --hide-scrollbars \
    --window-size="$1,$2" \
    --screenshot="$OUTDIR/$3" \
    --virtual-time-budget=15000 \
    "file://$ROOT/$PAGE" 2>/dev/null
  echo "wrote $OUTDIR/$3 (${1}px wide; trailing blank space is normal)"
}

# --allow-file-access-from-files: without it, CSS mask-image (the tinted
# logos) silently fails to render from file:// URLs.
# Mobile is shot at 500px: headless Chromium's minimum layout width is
# ~500px, so narrower windows just crop a 500px layout.
shoot 1440 4600 "$NAME-desktop.png"
shoot 500  3800 "$NAME-mobile.png"
