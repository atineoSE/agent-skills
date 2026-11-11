#!/usr/bin/env bash
# export.sh — capture frames from the running dev server and stitch them into a
# video. Run from the target project root, with the dev server already serving
# (or use the npm "export" script in the SKILL that starts it via concurrently).
#
#   OUT=clip.mov FORMAT=h264 PRESET=square DURATION=7 bash export.sh
#
# Env knobs (all optional; capture.mjs reads the rest):
#   OUT         output file                         (default out.mov)
#   FORMAT      h264 | prores | gif                 (default h264)
#   FPS         frames per second                   (default 60)
#   FRAMES_DIR  frame input dir                     (default frames)
set -euo pipefail

FPS="${FPS:-60}"
FRAMES_DIR="${FRAMES_DIR:-frames}"
OUT="${OUT:-out.mov}"
FORMAT="${FORMAT:-h264}"

# Resolve this script's directory so capture.mjs is found whether the scripts
# live in the project or are referenced in place from the skill.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

node "$DIR/capture.mjs"

case "$FORMAT" in
  h264)   # smallest, widely compatible (opaque)
    ffmpeg -y -framerate "$FPS" -i "$FRAMES_DIR/f-%04d.png" \
      -c:v libx264 -pix_fmt yuv420p -crf 18 "$OUT" ;;
  prores) # ProRes 4444 with alpha — overlay on any background (large files)
    ffmpeg -y -framerate "$FPS" -i "$FRAMES_DIR/f-%04d.png" \
      -c:v prores_ks -profile:v 4444 -pix_fmt yuva444p10le "$OUT" ;;
  gif)    # looping GIF
    ffmpeg -y -framerate "$FPS" -i "$FRAMES_DIR/f-%04d.png" \
      -vf "fps=30,scale=800:-1:flags=lanczos" "$OUT" ;;
  *)
    echo "Unknown FORMAT: $FORMAT (use h264 | prores | gif)" >&2; exit 1 ;;
esac

echo "Done -> $OUT"
