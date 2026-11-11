---
name: export-animation
description: Render a Motion (Framer Motion) + React/Vite animation to a .mov (or .gif) automatically — headless Chromium frame capture stitched with ffmpeg, no manual screen recording. Use when exporting, rendering, capturing, converting, or "turning into a video/MOV/GIF" a React/Motion animation, or batch-exporting many clips. macOS-oriented. Pairs with the `animate` skill, which designs the clip.
license: MIT
version: 1.0.0
---

# Export Animation — Motion/React clip → video file

Turn a Motion (Framer Motion) + React/Vite animation into a `.mov` or `.gif`
**automatically**: one command launches the dev server, drives the animation in a headless
browser, captures frames, and stitches them into a video. Deterministic, repeatable, and
scriptable across many clips — no QuickTime, no manual recording.

Use this **after** the clip looks right in the browser preview (see the `animate` skill).

## The scripts

The pipeline lives in this skill's `scripts/` directory — they are **not** inlined here, so
they stay runnable and version-controlled in one place:

| Script | Role |
|---|---|
| `scripts/setup.sh` | one-time: install `playwright` + chromium + `ffmpeg` in the project |
| `scripts/capture.mjs` | headless-Chromium frame capture; all knobs are env vars |
| `scripts/export.sh` | runs `capture.mjs` then stitches frames with `ffmpeg` |
| `scripts/useExportClock.js` | optional hook for bit-for-bit deterministic exports |

You can run them **in place** from the skill directory (they self-locate via
`$BASH_SOURCE`), or copy `scripts/` into the project if you prefer them committed alongside
the clip. Examples below assume you captured the skill dir into a variable:

```bash
SKILL="$(dirname "$(realpath path/to/this/SKILL.md)")"   # or just hardcode the path
```

## One-time setup

From the **target project root** (the Vite + React animations scaffold):

```bash
bash "$SKILL/scripts/setup.sh"
```

This installs `playwright` + `concurrently` + `wait-on` as devDependencies, downloads the
Chromium build, and installs `ffmpeg` via Homebrew if missing. On Linux, install `ffmpeg`
with the system package manager instead.

## Export in one command

The clean path keeps the dev server and capture in a single invocation. Add an `export`
script to the project's `package.json` (point it at the skill's `export.sh`, or at a local
copy):

```json
{
  "scripts": {
    "dev": "vite",
    "export": "concurrently -k -s first \"vite\" \"wait-on http://localhost:5173 && bash \\\"$SKILL/scripts/export.sh\\\"\""
  }
}
```

- `concurrently -k` kills the dev server once capture finishes.
- `-s first` makes the command exit with the capture step's status.
- `wait-on` blocks until the server responds before capturing.

Then run, tuning the clip's knobs via env vars:

```bash
OUT=clip.mov FORMAT=h264 PRESET=square FPS=60 DURATION=7 SELECTOR="svg" npm run export
```

### Manual two-terminal alternative

If you'd rather not touch `package.json`:

```bash
# terminal 1
npm run dev
# terminal 2 (from the project root)
OUT=clip.mov DURATION=7 SELECTOR="svg" bash "$SKILL/scripts/export.sh"
```

## Knobs (env vars)

Set these on the command; `export.sh` and `capture.mjs` read them.

| Var | Default | Meaning |
|---|---|---|
| `OUT` | `out.mov` | output file path |
| `FORMAT` | `h264` | `h264` (opaque, small) · `prores` (alpha master) · `gif` |
| `FPS` | `60` | frame rate |
| `DURATION` | `4` | seconds to capture — include the start/end holds |
| `SELECTOR` | `svg` | CSS selector of the animation root node |
| `PRESET` | `square` | viewport: `square` 1080² · `vertical` 1080×1350 · `wide` 1920×1080 |
| `DEVICE_SCALE` | `2` | retina sharpness; ffmpeg can downscale after |
| `DETERMINISTIC` | `false` | `true` to drive the timeline frame-exact (see below) |
| `OMIT_BG` | `true` | transparent PNGs (needs a transparent page background) |

## Deterministic vs real-time capture

- **Real-time (default)** — the script screenshots every `1/FPS` seconds while the animation
  autoplays. *Near*-perfect; timing can drift under machine load. Fine for most social clips.
- **Deterministic** — drop `useExportClock` (in `scripts/useExportClock.js`) into the
  animation root, compute every animated value from `window.__t`, and run with
  `DETERMINISTIC=true`. The script seeks `window.__seek(t)` once per frame for bit-for-bit
  reproducibility. Use when batching at scale or when exactness matters.

## Aspect / platform presets

Pick `PRESET` to match the destination (these mirror the aspect ratios in the `animate`
skill): `square` for square feeds, `vertical` for 4:5 vertical feeds, `wide` for blog/video.

## Batch exporting many clips

Parameterize the route/selector per clip (e.g. read `process.env.CLIP` in your app to pick
which animation to mount) and loop:

```bash
for name in attention backprop batching; do
  CLIP=$name OUT="$name.mov" DURATION=7 npm run export
done
```

## Notes and caveats

- `OMIT_BG=true` only yields real transparency if the page/element has **no opaque
  background**. Set the page background transparent in CSS for true alpha; otherwise capture
  with an opaque background and `FORMAT=h264`.
- ProRes 4444 files are large — deliver `h264` or `gif` for posting, keep ProRes only as a
  master if you need overlay compositing.
- Leave a **beat of stillness** at the start and end of the animation so loops and
  freeze-frames read cleanly (the `animate` skill bakes this in).
- Capture targets one node (`SELECTOR`). Give the animation a single root (`<svg>` or
  `<div id="stage">`) so the crop is exactly the canvas.
