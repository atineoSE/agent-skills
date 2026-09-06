#!/usr/bin/env python3
"""Generate on-brand talk slide assets (background + title header).

Every brand value is a CLI parameter. Nothing about a specific event is baked
in — ask the user for the colors, fonts and logo, then pass them here.

Minimal run (only the two colors that cannot be guessed):
    ~/.venvs/imaging/bin/python generate.py \
        --accent "#8CBE3C" --bg-top "#14240E" \
        --title-white "The Open Source " --title-accent "Revolution" \
        --out OUTDIR

Full control:
    --bg-bottom --glow --grid --grid-alpha --white   palette overrides
    --font-heavy --font-bold --font-label            "PATH" or "PATH:TTC_INDEX"
    --logo --logo-trim                               optional logo mark
    --wordmark "Open|white" "South|accent"           lockup text next to the logo
    --subtitle "O P E N   S O U R C E"               small line under the wordmark

Colors accept "#RRGGBB", "RRGGBB", or "r,g,b".

A reusable profile may be kept in your own JSON file (not bundled with this
skill) and passed with --brand; any CLI flag overrides a value from it:
{
  "palette":  {"top":[r,g,b], "bottom":[r,g,b], "glow":[r,g,b],
               "grid":[r,g,b], "grid_alpha":14, "accent":[r,g,b], "white":[r,g,b]},
  "fonts":    {"heavy":["/path.ttc", idx], "bold":["/path.ttc", idx],
               "label":["/path.ttc", idx]},
  "logo":     "/path/to/logo.png",
  "logo_trim": true,
  "wordmark": [["Text","white"], ["More","accent"]],
  "subtitle": "..."
}
"""
import argparse, json, math, os, sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Font candidates tried, in order, when a face is not given explicitly.
FONT_FALLBACKS = {
    "heavy": [("/System/Library/Fonts/Avenir Next.ttc", 8),
              ("/System/Library/Fonts/HelveticaNeue.ttc", 2),
              ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 0),
              ("C:/Windows/Fonts/arialbd.ttf", 0)],
    "bold":  [("/System/Library/Fonts/Avenir Next.ttc", 0),
              ("/System/Library/Fonts/HelveticaNeue.ttc", 1),
              ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 0),
              ("C:/Windows/Fonts/arialbd.ttf", 0)],
    "label": [("/System/Library/Fonts/HelveticaNeue.ttc", 0),
              ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 0),
              ("C:/Windows/Fonts/arial.ttf", 0)],
}


def parse_color(s):
    """'#RRGGBB' | 'RRGGBB' | 'r,g,b' -> [r, g, b]."""
    if s is None:
        return None
    if isinstance(s, (list, tuple)):
        return [int(v) for v in s[:3]]
    s = s.strip()
    if "," in s:
        parts = [int(p) for p in s.split(",")]
        if len(parts) != 3:
            raise argparse.ArgumentTypeError(f"expected 'r,g,b', got {s!r}")
        return parts
    h = s.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    if len(h) != 6:
        raise argparse.ArgumentTypeError(f"expected '#RRGGBB' or 'r,g,b', got {s!r}")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]


def parse_font(s):
    """'PATH' or 'PATH:TTC_INDEX' -> [path, index]."""
    if s is None:
        return None
    if isinstance(s, (list, tuple)):
        return [s[0], int(s[1]) if len(s) > 1 else 0]
    head, sep, tail = s.rpartition(":")
    if sep and tail.isdigit():
        return [head, int(tail)]
    return [s, 0]


def resolve_font(spec, role):
    """Explicit spec wins; otherwise probe the fallbacks for this role."""
    if spec:
        return spec
    for path, idx in FONT_FALLBACKS.get(role, []):
        if os.path.exists(path):
            return [path, idx]
    return None


def load_font(spec, size):
    if spec:
        try:
            return ImageFont.truetype(spec[0], size, index=spec[1])
        except OSError:
            print(f"warning: could not load font {spec[0]!r}; using default", file=sys.stderr)
    return ImageFont.load_default(size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_bg(W, H, P):
    """Base color darkening toward the bottom-right, plus an upper-right radial glow."""
    img = Image.new("RGB", (W, H))
    px = img.load()
    top, bot = P["top"], P["bottom"]
    glow = P["glow"]
    gx, gy = 0.80 * W, 0.22 * H          # glow centre (sits behind a speaker photo)
    R = 0.62 * math.hypot(W, H)
    for y in range(H):
        for x in range(W):
            t = max(0.0, min(1.0, 0.30 * (x / W) + 0.78 * (y / H) - 0.06))
            base = lerp(top, bot, t)
            d = math.hypot(x - gx, y - gy) / R
            g = max(0.0, 1.0 - d) ** 1.5
            px[x, y] = tuple(int(base[i] + (glow[i] - base[i]) * g * 0.9 + 0.5) for i in range(3))
    return img


def add_curves(img, P):
    """Faint square grid (92px @2400, scaled) + concentric swoosh arcs top-right
    and one balancing ring lower-left."""
    W, H = img.size
    acc = tuple(P["accent"])
    over = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dr = ImageDraw.Draw(over)
    grid = tuple(P["grid"])
    ga = int(P["grid_alpha"])
    s = max(1, round(92 * W / 2400))
    x = s
    while x < W:
        dr.line([(x, 0), (x, H)], fill=grid + (ga,), width=1); x += s
    y = s
    while y < H:
        dr.line([(0, y), (W, y)], fill=grid + (ga,), width=1); y += s
    # swoosh arcs
    ox, oy = W * 1.02, H * 0.04
    for i, r in enumerate(range(int(W * 0.18), int(W * 0.62), max(1, int(W * 0.085)))):
        a = 22 if i % 2 == 0 else 13
        dr.arc([ox - r, oy - r, ox + r, oy + r], 95, 205, fill=acc + (a,), width=3)
    r = int(W * 0.30); lx, ly = -W * 0.06, H * 1.04
    dr.arc([lx - r, ly - r, lx + r, ly + r], 300, 20, fill=acc + (12,), width=3)
    over = over.filter(ImageFilter.GaussianBlur(0.4))
    base = img.convert("RGBA")
    base.alpha_composite(over)
    return base.convert("RGB")


def draw_lockup(canvas, brand, x, y, logo_h):
    """Logo mark + wordmark + subtitle, set into the header's top-left."""
    P = brand["palette"]
    col_of = {"white": tuple(P["white"]), "accent": tuple(P["accent"])}
    dr = ImageDraw.Draw(canvas)
    tx = x
    logo_path = brand.get("logo")
    if logo_path:
        if os.path.exists(logo_path):
            logo = Image.open(logo_path).convert("RGBA")
            if brand.get("logo_trim"):
                logo = logo.crop(logo.getbbox())     # strip transparent padding
            lw = int(logo.width * (logo_h / logo.height))
            logo = logo.resize((lw, logo_h), Image.LANCZOS)
            canvas.alpha_composite(logo, (x, y))
            tx = x + lw + int(logo_h * 0.28)
        else:
            print(f"warning: logo not found at {logo_path!r}; drawing wordmark only",
                  file=sys.stderr)
    if not brand.get("wordmark"):
        return
    wf = load_font(brand["fonts"]["bold"], int(logo_h * 0.52))
    ty = y + int(logo_h * 0.10)
    cx = tx
    for txt, c in brand["wordmark"]:
        dr.text((cx, ty), txt, font=wf, fill=col_of.get(c, col_of["white"]))
        cx += dr.textlength(txt, font=wf)
    if brand.get("subtitle"):
        sf = load_font(brand["fonts"]["label"], int(logo_h * 0.17))
        dr.text((tx + 2, ty + int(logo_h * 0.60)), brand["subtitle"], font=sf, fill=col_of["accent"])


def build_brand(a):
    """Merge --brand JSON (if any) with CLI flags; CLI wins. Fill the rest."""
    brand = {}
    if a.brand:
        brand = json.load(open(a.brand))
    P = {k: parse_color(v) for k, v in brand.get("palette", {}).items() if k != "grid_alpha"}
    P["grid_alpha"] = brand.get("palette", {}).get("grid_alpha", 14)

    for key, val in (("top", a.bg_top), ("bottom", a.bg_bottom), ("glow", a.glow),
                     ("grid", a.grid), ("accent", a.accent), ("white", a.white)):
        if val is not None:
            P[key] = val
    if a.grid_alpha is not None:
        P["grid_alpha"] = a.grid_alpha

    missing = [k for k in ("accent", "top") if not P.get(k)]
    if missing:
        names = {"accent": "--accent", "top": "--bg-top"}
        raise SystemExit(
            "error: missing required brand color(s): "
            + ", ".join(names[m] for m in missing)
            + "\nSample them from the event flyer, or ask the user for the brand colors.")

    # Derive anything not supplied from the two colors that were.
    P.setdefault("bottom", lerp(P["top"], (0, 0, 0), 0.45))
    P.setdefault("glow", [min(255, int(c * 1.6)) for c in P["top"]])
    P.setdefault("white", [235, 245, 248])
    P.setdefault("grid", list(lerp(P["accent"], P["white"], 0.5)))
    brand["palette"] = P

    fonts = {k: parse_font(v) for k, v in brand.get("fonts", {}).items()}
    for role, val in (("heavy", a.font_heavy), ("bold", a.font_bold), ("label", a.font_label)):
        if val is not None:
            fonts[role] = val
    brand["fonts"] = {r: resolve_font(fonts.get(r), r) for r in ("heavy", "bold", "label")}

    if a.logo is not None:
        brand["logo"] = a.logo
    if a.logo_trim:
        brand["logo_trim"] = True
    if a.wordmark is not None:
        parts = []
        for item in a.wordmark:
            txt, sep, col = item.rpartition("|")
            if not sep:
                txt, col = item, "white"
            if col not in ("white", "accent"):
                raise SystemExit(f"error: wordmark color must be 'white' or 'accent', got {col!r}")
            parts.append([txt, col])
        brand["wordmark"] = parts
    brand.setdefault("wordmark", [])
    if a.subtitle is not None:
        brand["subtitle"] = a.subtitle
    return brand


def main():
    ap = argparse.ArgumentParser(
        description="Generate on-brand talk slide assets. All brand values are parameters.")
    ap.add_argument("--out", required=True, help="output directory")
    ap.add_argument("--brand", help="optional JSON profile of your own; CLI flags override it")

    g = ap.add_argument_group("brand palette")
    g.add_argument("--accent", type=parse_color, help="accent color, e.g. '#8CBE3C' (required)")
    g.add_argument("--bg-top", type=parse_color, help="background base color (required)")
    g.add_argument("--bg-bottom", type=parse_color, help="default: --bg-top darkened 45%%")
    g.add_argument("--glow", type=parse_color, help="default: --bg-top brightened")
    g.add_argument("--grid", type=parse_color, help="default: midpoint of accent and white")
    g.add_argument("--grid-alpha", type=int, help="grid opacity 0-255 (default 14)")
    g.add_argument("--white", type=parse_color, help="text white (default near-white)")

    g = ap.add_argument_group("fonts (PATH or PATH:TTC_INDEX; system fallbacks if omitted)")
    g.add_argument("--font-heavy", type=parse_font, help="title face")
    g.add_argument("--font-bold", type=parse_font, help="wordmark face")
    g.add_argument("--font-label", type=parse_font, help="eyebrow/subtitle face")

    g = ap.add_argument_group("lockup")
    g.add_argument("--logo", help="path to a logo PNG (optional)")
    g.add_argument("--logo-trim", action="store_true", help="crop transparent padding off the logo")
    g.add_argument("--wordmark", nargs="*", metavar="TEXT|COLOR",
                   help="e.g. --wordmark 'Open|white' 'Source|accent'")
    g.add_argument("--subtitle", help="small line under the wordmark")

    g = ap.add_argument_group("text and size")
    g.add_argument("--eyebrow", default="")
    g.add_argument("--title-white", default="")
    g.add_argument("--title-accent", default="")
    g.add_argument("--width", type=int, default=1920)
    g.add_argument("--height", type=int, default=1080)
    g.add_argument("--header-height", type=int, default=360)
    a = ap.parse_args()

    brand = build_brand(a)
    P = brand["palette"]
    WHITE, ACCENT = tuple(P["white"]), tuple(P["accent"])
    os.makedirs(a.out, exist_ok=True)

    # --- background ---
    bg = add_curves(make_bg(a.width, a.height, P), P)
    bg.save(os.path.join(a.out, f"background-{a.width}x{a.height}.png"))

    # --- transparent header (logo lockup + eyebrow + title) ---
    HW, HH = a.width, a.header_height
    hdr = Image.new("RGBA", (HW, HH), (0, 0, 0, 0))
    dr = ImageDraw.Draw(hdr)
    draw_lockup(hdr, brand, 70, 48, 84)
    if a.eyebrow:
        dr.text((74, 178), a.eyebrow, font=load_font(brand["fonts"]["label"], 30), fill=ACCENT)
    tf = load_font(brand["fonts"]["heavy"], 96)
    dr.text((70, 212), a.title_white, font=tf, fill=WHITE)
    w1 = dr.textlength(a.title_white, font=tf)
    dr.text((70 + w1, 212), a.title_accent, font=tf, fill=ACCENT)
    hdr.save(os.path.join(a.out, f"header-transparent-{HW}x{HH}.png"))

    # --- self-contained header band on the gradient ---
    band = add_curves(make_bg(HW, HH, P), P).convert("RGBA")
    band.alpha_composite(hdr)
    band.convert("RGB").save(os.path.join(a.out, f"header-{HW}x{HH}.png"))
    print("wrote assets to", a.out)


if __name__ == "__main__":
    main()
