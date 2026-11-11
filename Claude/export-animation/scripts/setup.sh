#!/usr/bin/env bash
# setup.sh — one-time setup in the target Vite project: install the headless
# capture deps and ffmpeg. Run from the project root. macOS-oriented (uses brew
# for ffmpeg); on Linux install ffmpeg via the system package manager instead.
set -euo pipefail

npm install -D playwright concurrently wait-on
npx playwright install chromium

if ! command -v ffmpeg >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install ffmpeg
  else
    echo "ffmpeg not found and Homebrew is unavailable." >&2
    echo "Install ffmpeg manually, then re-run the export." >&2
    exit 1
  fi
fi

echo "Export pipeline ready (playwright + chromium + ffmpeg)."
