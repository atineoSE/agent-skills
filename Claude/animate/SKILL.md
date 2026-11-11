---
name: animate
description: Draft a meaningful animated diagram for technical / AI / software-engineering content (social or blog) using Motion (Framer Motion) in React. Use when creating, drafting, designing, or storyboarding an animation, motion diagram, explainer clip, or animated figure — where motion should carry meaning, not decorate. Covers the narrative/timing/visual principles, which motion primitives to reach for (delegating to the framer-motion-* skills), how to preview it live, and how to hand off to export-animation for rendering to video.
license: MIT
version: 1.1.0
---

# Animate — meaningful motion for technical diagrams

## When to use this skill

Use when the task is to **draft or design an animation** that explains a technical idea
(AI, distributed systems, software engineering) for social media or a blog — anywhere a
still diagram would bury the insight. This skill owns the *editorial and motion-design
decisions*; the **framer-motion-\*** skills own the *API mechanics*; the
**export-animation** skill owns *rendering to video*.

The framer-motion-\* skills come from
[C-Jeril/framer-motion-skills](https://github.com/C-Jeril/framer-motion-skills). If they
are not installed, tell the user to get them there.

If the user just wants Framer Motion API help (how does `layoutId` work?), skip straight to
the relevant framer-motion-\* skill. Use this skill when the deliverable is a *clip that
teaches something*.

## What this skill includes

1. A **guiding philosophy** and four narrative principles for deciding what moves and when.
2. **Timing/easing** and **visual-style** defaults tuned for legibility over spectacle.
3. A map from **motion primitives → the framer-motion-\* skill** that documents each.
4. **Worked example patterns** for common technical topics.
5. The **preview/visualize** workflow (Vite dev server) and the **handoff to export**.

## Guiding philosophy

The animation exists to drive home a message a static diagram would bury. **Motion is a
teaching tool, not a flourish.** Every choice serves clarity over spectacle.

### Narrative principles

- **Sequence over simultaneity.** A static diagram dumps everything at once and forces the
  viewer to find the entry point. Animation controls reading order: reveal one node, then
  its dependency, then the data flowing between them. Pacing *is* the explanation — the
  single biggest lever for clarity.
- **Show the delta, not the end state.** The insight is usually a *transformation*
  (before/after, naive/optimized, sync/parallel). A still shows the result; animation shows
  the change, which is where understanding lives.
- **One idea per beat.** Each step advances exactly one concept. If the viewer can't name
  what just changed, too much was packed in. Minimalism is a discipline, not an aesthetic.
- **Persistence of context.** Don't reset the canvas between steps. Keep stable elements in
  place and animate only what changes, so the viewer's mental model accumulates rather than
  restarts.

## Timing and easing

- Slow enough to read; no bounce or overshoot **unless the bounce itself means something**.
- Calm, restrained easing (`easeOut` for reveals; gentle springs only when motion
  represents physical settling).
- Stagger sequential reveals so reading order is unambiguous (`staggerChildren`, or
  incremental `delay`).
- Leave a **beat of stillness at the start and end** so freeze-frames and loops read cleanly.

## Visual style

- Dark canvas, small high-contrast palette; reserve **one accent color** for the element
  currently "in focus."
- Make line weight and opacity **encode meaning** (thickness/opacity ∝ attention weight or
  data volume), not just decoration.
- Design the canvas at the **target platform's aspect ratio**: 1:1 or 4:5 for feeds, 16:9
  for blog/video. (These map to the export presets — see `export-animation`.)

## Motion primitives → which framer-motion skill to use

Reach for the primitive that fits the beat, and pull the matching skill for the exact API:

| Beat you're animating | Primitive | Skill to consult |
|---|---|---|
| Enter/exit as you step through beats | `AnimatePresence`, `initial/animate/exit` | **framer-motion-layout**, **framer-motion-react** |
| An element keeps its identity while moving (monolith → microservices) | `layout`, `layoutId` | **framer-motion-layout** |
| Sequential, ordered reveals | `variants` + `staggerChildren` | **framer-motion-variants** |
| Core transforms, springs, keyframes, motion values | `motion.*`, `useMotionValue`, `useTransform`, `useSpring` | **framer-motion-core** |
| Drawing arrows / connection lines progressively | `pathLength` on SVG paths | **framer-motion-core** (motion values) |
| Fire steps on scroll (blog format) | `useInView`, `useScroll` | **framer-motion-scroll** |
| Interactive demo (drag/hover to explain) | `whileHover`, `whileTap`, `drag` | **framer-motion-gestures** |
| Respect accessibility | `useReducedMotion` (pass `undefined` to variants/initial/transition when reduced) | **framer-motion-core** |

When you start writing the component, read the specific skill(s) above for the props and
gotchas rather than recalling the API from memory.

## Worked example patterns

- **Attention mechanism** — tokens in a row; weighted lines fan from the query token,
  opacity/thickness ∝ attention score.
- **Backpropagation** — forward pass lights up left→right; gradient flows back right→left in
  a different color.
- **Request batching / debouncing** — erratic request dots strain a server, then queue,
  merge into one, and arrive together on the "after" beat.
- **Distributed latency** — a single request hops between services with realistic relative
  delays, revealing the bottleneck.
- **CAP / consistency** — a write lands on one replica and propagates with visible lag,
  during which a read returns stale data.

## Implementation setup

- The library is now **`motion`**; for React import from **`motion/react`**:
  `import { motion, AnimatePresence } from "motion/react"`. Older tutorials using
  `framer-motion` use the same API under the pre-rebrand name.
- Build each clip as a **self-contained React + Vite component**. First look for an
  existing scaffold in the project (a Vite + React app with `motion` in its
  `package.json`; the project's `CLAUDE.md` often names it). If there is one, drop the
  component into its `src/` and render it from `App.jsx`. If there is none, create one:
  `npm create vite@latest animations -- --template react`, then `npm install motion`.
- Make the animation root a single node (an `<svg>` or a container `<div id="stage">`) so
  the export step can target it with one selector.

## How to visualize (preview)

Run the Vite dev server and watch the clip live with hot reload — tune timing against the
running animation, which is the only reliable way to get pacing right:

```bash
cd <scaffold>    # the animations scaffold from the setup step
npm install      # first time only
npm run dev      # serves http://localhost:5173
```

Open **http://localhost:5173**, edit the component in `<scaffold>/src/`, and the preview
updates on save. Iterate until each beat reads cleanly and the start/end holds are in place.

> If a project skill named `run` exists, you can also use it to launch the dev server and
> screenshot the result; otherwise the two commands above are the canonical preview path.

## Handoff to export

Once the clip reads well in the browser, render it to a shareable file (no manual screen
recording) with the **export-animation** skill, which captures frames in headless Chromium
and stitches them with ffmpeg. Match the export **preset** to the aspect ratio you designed
for (square / vertical / wide). See that skill for the one command.
