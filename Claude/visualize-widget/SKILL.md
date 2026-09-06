---
name: visualize-widget
version: 1.0.0
description: Build interactive HTML/SVG widgets that render inline in the claude.ai chat using the visualize:show_widget and visualize:read_me tools. Use this skill whenever the user asks to visualize data, build an interactive chart, create a calculator or explainer, render a dashboard, make a diagram, or produce any visual UI component in the chat. Also trigger for requests like "show me", "build me a widget", "make it interactive", "chart this", "animate this", or any task where a visual would be more effective than prose. Always prefer this over text-only explanations when the topic is inherently visual.
---

# Visualize widget skill

Renders self-contained HTML or SVG as a live interactive widget inline in the claude.ai chat interface.

## Tool interface

Two tools work together:

### `visualize:read_me`

Loads the full design system documentation into context. Call this once before your first `show_widget` call. Do not narrate or mention this call to the user — call it silently.

**Parameters:**
```
modules: string[]  — one or more of: "diagram", "mockup", "interactive", "data_viz", "art", "chart"
```

Pick all modules relevant to what you're building. The returned content is the authoritative source for design rules, CSS variables, color palettes, component patterns, and CDN allowlist. Everything below is a summary — always call `read_me` for the full spec.

### `visualize:show_widget`

Renders the widget. Returns a confirmation that the content is displayed; do not repeat or re-describe it in your response text.

**Parameters:**
```
title: string             — snake_case identifier, used as download filename. Make it specific.
loading_messages: string[] — 1–4 short strings (~5 words each) shown while rendering.
                             Playful/punny for light topics; plain/boring for serious ones.
i_have_seen_read_me: bool — must be true; confirms you called read_me first.
widget_code: string       — raw HTML fragment or SVG starting with <svg>. No DOCTYPE,
                             no <html>/<head>/<body> tags.
```

**Auto-detection:** if `widget_code` starts with `<svg`, it renders in SVG mode; otherwise HTML mode.

**`sendPrompt(text)`:** a global JS function available inside widgets. Calling it sends `text` to the chat as if the user typed it — use for drill-down buttons, e.g. `sendPrompt('Break down Q4 by region ↗')`.

**`openLink(url)`:** a global JS function that opens a URL via the host's link dialog.

---

## Design system (summary)

> Always call `read_me` for the full spec. This section is a quick reference only.

### Philosophy
- **Seamless**: widgets look native to claude.ai — no jarring embedded-app feel
- **Flat**: no gradients, shadows, blur, glow, or decorative textures
- **Compact**: visuals inline, explanatory prose in the chat response (never inside the widget)
- **Streaming-safe**: `<style>` first, content HTML next, `<script>` last

### CSS variables (auto-adapt to light/dark mode)
```
Backgrounds:  --color-background-primary (white)
              --color-background-secondary (surfaces)
              --color-background-tertiary (page bg)
              + semantic: -info / -danger / -success / -warning

Text:         --color-text-primary (black)
              --color-text-secondary (muted)
              --color-text-tertiary (hints)
              + semantic variants

Borders:      --color-border-tertiary  (default, 0.15α)
              --color-border-secondary (hover, 0.3α)
              --color-border-primary   (0.4α)

Layout:       --border-radius-md (8px)
              --border-radius-lg (12px — preferred for cards)
              --border-radius-xl (16px)

Fonts:        --font-sans, --font-serif, --font-mono
```

Never hardcode hex for text or backgrounds — use variables so dark mode works.

### Typography
- h1=22px, h2=18px, h3=16px — all `font-weight: 500`
- Body: 16px, weight 400, `line-height: 1.7`
- **Two weights only**: 400 and 500. Never 600 or 700.
- **Sentence case everywhere** — no Title Case, no ALL CAPS

### Hard no-list
- No gradients, drop shadows, blur, glow, or neon effects
- No `position: fixed` — breaks iframe height sizing
- No emoji (use CSS shapes or SVG paths)
- No font-size below 11px
- No `<!-- comments -->` or `/* comments */`
- No `<html>`, `<head>`, `<body>` wrapper tags
- No `localStorage` or `sessionStorage` (use React state or JS variables)
- No dark/colored outer container backgrounds (transparent only)

### CDN allowlist (CSP-enforced — only these domains load)
- `cdnjs.cloudflare.com`
- `esm.sh`
- `cdn.jsdelivr.net`
- `unpkg.com`

Load libraries as UMD globals via `<script src="...">`, then use the global in a plain `<script>` that follows (no `type="module"`).

### Color palette — 9 ramps, 7 stops each

| Class | 50 | 200 | 400 | 600 | 800 |
|---|---|---|---|---|---|
| `c-purple` | #EEEDFE | #AFA9EC | #7F77DD | #534AB7 | #3C3489 |
| `c-teal`   | #E1F5EE | #5DCAA5 | #1D9E75 | #0F6E56 | #085041 |
| `c-coral`  | #FAECE7 | #F0997B | #D85A30 | #993C1D | #712B13 |
| `c-pink`   | #FBEAF0 | #ED93B1 | #D4537E | #993556 | #72243E |
| `c-gray`   | #F1EFE8 | #B4B2A9 | #888780 | #5F5E5A | #444441 |
| `c-blue`   | #E6F1FB | #85B7EB | #378ADD | #185FA5 | #0C447C |
| `c-green`  | #EAF3DE | #97C459 | #639922 | #3B6D11 | #27500A |
| `c-amber`  | #FAEEDA | #EF9F27 | #BA7517 | #854F0B | #633806 |
| `c-red`    | #FCEBEB | #F09595 | #E24B4A | #A32D2D | #791F1F |

Apply `c-{ramp}` to `<g>` elements in SVG — dark mode is automatic. Text on colored fills must use the 800/900 stop from the same ramp, never plain black. Use 2–3 colors per diagram max; gray for neutral/structural nodes.

---

## Common patterns

### Interactive explainer (sliders + live chart)
```html
<div style="display: flex; align-items: center; gap: 12px; margin-bottom: 10px;">
  <label style="font-size: 13px; color: var(--color-text-secondary); width: 120px;">Years</label>
  <input type="range" min="1" max="40" value="20" id="years" style="flex: 1;" />
  <span style="font-size: 13px; font-weight: 500; min-width: 40px;" id="years-out">20</span>
</div>
```
Bind `input` events on all controls → single `update()` function → recompute → redraw.

### Metric cards
```html
<div style="background: var(--color-background-secondary); border-radius: var(--border-radius-md); padding: 1rem;">
  <p style="font-size: 13px; color: var(--color-text-secondary); margin: 0 0 4px;">Label</p>
  <p style="font-size: 26px; font-weight: 500; margin: 0;" id="value">$0</p>
</div>
```
Use in a grid: `grid-template-columns: 1fr 1fr; gap: 12px`.

### Chart.js setup
```html
<div style="position: relative; width: 100%; height: 280px;">
  <canvas id="myChart"></canvas>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.js"></script>
<script>
  const chart = new Chart(document.getElementById('myChart'), {
    type: 'bar',
    data: { labels: [], datasets: [] },
    options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false } } }
  });
</script>
```
- Height on the wrapper `<div>`, never on `<canvas>`
- Call `chart.destroy()` before recreating on data changes
- Disable default legend; build custom HTML legend above the canvas
- Canvas cannot resolve CSS variables — use hardcoded hex for dataset colors

### Custom HTML legend
```html
<div style="display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 8px; font-size: 12px; color: var(--color-text-secondary);">
  <span style="display: flex; align-items: center; gap: 4px;">
    <span style="width: 10px; height: 10px; border-radius: 2px; background: #378ADD;"></span>Series A
  </span>
</div>
```

### Number formatting
Every number that reaches the screen must be formatted — never let raw JS floats render:
```js
function fmt(n) { return '$' + Math.round(n).toLocaleString(); }
```
Set `step="1"` (or `step="0.1"`) on range inputs to prevent fractional readouts.

### sendPrompt drill-down button
```html
<button onclick="sendPrompt('Break this down by category ↗')">Explore further ↗</button>
```

---

## What goes where

| Content type | Goes in... |
|---|---|
| Explanatory prose, key insights | Chat response text |
| Visual, chart, controls, UI | `widget_code` |
| Definitions, formulas (live) | Inside the widget |
| Definitions, formulas (static) | Chat response text |

Never put paragraphs of explanation inside the widget. Never put the visual in the chat text.
