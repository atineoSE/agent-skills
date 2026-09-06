---
name: talk-slide-assets
version: 2.0.0
description: Generate on-brand slide assets (gradient backgrounds, title headers, social cards) for conference talks, matching a flyer's palette/fonts. Use when asked to extract a flyer background, make a slide header/title bar, or produce branded talk imagery as PNG.
user-invocable: true
allowed-tools: Read, Bash, Write, Edit
---

# Talk Slide Assets

Generate clean, reusable slide imagery (backgrounds, header/title bars) that match an
event's branding — typically reverse-engineered from a promo flyer the user already has.

This skill ships **no brand assets**. Every color, font and logo is a parameter you
supply per event. Collect them first (below), then generate.

## Brand inputs

Two are required; the rest have sensible defaults derived from them.

| Input | Flag | Required | Default if omitted |
|---|---|---|---|
| Accent color | `--accent` | **yes** | — |
| Background base color | `--bg-top` | **yes** | — |
| Background bottom | `--bg-bottom` | no | `--bg-top` darkened 45% |
| Glow color | `--glow` | no | `--bg-top` brightened |
| Grid color / opacity | `--grid`, `--grid-alpha` | no | accent↔white midpoint, alpha 14 |
| Text white | `--white` | no | near-white |
| Title / wordmark / label fonts | `--font-heavy`, `--font-bold`, `--font-label` | no | first system font found |
| Logo PNG | `--logo`, `--logo-trim` | no | no logo; wordmark only |
| Wordmark, subtitle | `--wordmark`, `--subtitle` | no | omitted |

Colors accept `#RRGGBB`, `RRGGBB`, or `r,g,b`. Fonts are `PATH` or `PATH:TTC_INDEX`.

**If the user has not specified the required inputs, ask before generating.** Do not
invent an event's colors. Two ways to get them:

1. **They have a flyer** — sample it (below) and confirm the sampled values with them.
2. **They don't** — ask for the accent and background colors, plus the logo path,
   wordmark text and font files if they want a full lockup.

### Sampling a flyer

```bash
~/.venvs/imaging/bin/python - <<'PY'
from PIL import Image; im=Image.open("FLYER.png").convert("RGB"); px=im.load(); W,H=im.size
for k,(x,y) in {"TL":(20,20),"BR":(W-20,H-20),"C":(W//2,H//2)}.items(): print(k,px[x,y])
PY
```

Corners give the background gradient. Find the accent by scanning for the brightest
saturated pixels. Show the user what you sampled before committing to it.

## Tooling (installed system-wide)

- **Persistent Pillow env:** `~/.venvs/imaging/bin/python` — use this for the generator
  script below. Don't build throwaway venvs.
- **ImageMagick:** `magick` — quick one-off ops (crop/resize/composite/`magick -size WxH gradient:`).
- **librsvg:** `rsvg-convert` — rasterize vector logos/SVGs to PNG crisply.

## Generating

`scripts/generate.py` produces:
- `background-1920x1080.png` — diagonal gradient + faint concentric swoosh arcs (no foreground)
- `header-1920x360.png` — self-contained title band on the gradient
- `header-transparent-1920x360.png` — logo lockup + title on transparency (overlay onto any slide)

Minimal — just the two required colors:
```bash
~/.venvs/imaging/bin/python scripts/generate.py \
  --accent "#8CBE3C" --bg-top "#14240E" \
  --eyebrow "THE FUTURE OF CODING IS OPEN" \
  --title-white "The Open Source " --title-accent "Coding Revolution" \
  --out /path/to/output-dir
```

With a full lockup:
```bash
~/.venvs/imaging/bin/python scripts/generate.py \
  --accent "#8CBE3C" --bg-top "#14240E" \
  --font-heavy "/System/Library/Fonts/Avenir Next.ttc:8" \
  --logo /path/to/event-logo.png --logo-trim \
  --wordmark "Open|white" "Source|accent" "Conf|white" \
  --subtitle "O P E N   S O U R C E   C O N F E R E N C E" \
  --title-white "The Open Source " --title-accent "Coding Revolution" \
  --out /path/to/output-dir
```

Run `--help` for the full flag list.

## Reusing a brand across runs

For an event you'll generate for repeatedly, keep a JSON profile **outside this repo**
(alongside that event's assets) and pass `--brand profile.json`. Any CLI flag overrides
a value in it. Schema is in the `generate.py` docstring. Nothing is bundled here —
brand assets belong with the event, not with the skill.

## Notes
- Fonts must be **upright** weights — verify the face name isn't `Italic`/`Oblique` before
  rendering. Enumerate faces in a `.ttc` with `ImageFont.truetype(path, 40, index=i).getname()`.
- Licensed brand fonts are the user's to supply; the script falls back to a system face
  and warns rather than failing if one is missing.
- "Extract the background" means a *clean* reusable background in the flyer's style (gradient +
  decorative arcs), not pixel-inpainting the text out of the flyer.
- Output at 1920×1080 (16:9). Pass `--width/--height` for other slide ratios.
