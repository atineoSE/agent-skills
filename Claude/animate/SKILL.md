---
name: animate
description: Draft a meaningful animated diagram for technical / AI / software-engineering content (social or blog) using Motion (Framer Motion) in React. Use when creating, drafting, designing, or storyboarding an animation, motion diagram, explainer clip, or animated figure — where motion should carry meaning, not decorate. Covers the narrative/timing/visual principles, which motion primitives to reach for (delegating to the framer-motion-* skills), how to preview it live, and how to hand off to export-animation for rendering to video.
license: MIT
version: 1.8.0
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
6. **Guidelines for short social clips** and common **Motion gotchas**.

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

## Short social clips (guidelines)

These apply to any short clip for a feed: an explainer, an announcement, a product demo.

**Process**
- **Script before code.** Write a beat table (time · on screen · motion) next to the clip
  and get approval before you build. Update it when the timings change.
- **Start from what exists.** Reuse the project's brand assets, palette and fonts. Check
  that every asset you need exists before you build, and list what is missing.
- **Use the logo variant made for your background.** Logos often come in light-background
  and dark-background versions. In a light-background version, outlines may use the same
  dark color as your canvas, so parts of the mark disappear and only the accent details
  show. Compare the rendered logo with the brand's reference image. If you only have the
  wrong variant, make a copy and change those colors. Thicken hairline strokes when the
  logo is rendered small: under ~1 px they fade.
- **Use real content.** Code, terminal and UI mockups use names from the real product or
  its docs. Check the source first, and say which parts are illustrative.
- **Review frames, not impressions.** Look at stills in the middle of transitions and at
  every settled beat, side by side on one contact sheet, before you render the full clip.

**Structure**
- **Lead with the strongest hook.** Feeds judge the clip on its first second. Show the main
  subject (person, product, result) in the first ~1 s, not an empty or title-only frame.
- **Open on a finished frame.** Players, link previews and chat apps often use an early
  frame of the video, not the uploaded thumbnail. Make frame 0 a complete, settled poster
  (no build-in), and start the motion after it. Still upload a custom thumbnail where the
  platform allows one.
- **The key message gets its own beat.** The line the audience must remember fills a frame
  and dominates it. It is never a sub-line under another beat.
- **Captions follow what they summarize.** A conclusion ("…and it just works") comes after
  the result is on screen, not before.
- **Short by default.** 15–20 s, one idea per beat. If a beat feels rushed, cut content or
  extend the clip; do not speed up the motion.

**Pacing**
- Give text time to be read: about 0.7 s per output or terminal line, 0.3 s per list or
  tree line, and at least 1.5 s of still hold on the final frame.
- Plan for the loop. Many feeds auto-loop short videos and the viewer cannot turn it off.
  End by fading back into the opening frame, so the cut back to frame 0 is seamless.

**Format**
- Design at the destination's aspect ratio: 4:5 for most feeds, 9:16 for stories and
  reels, 16:9 for blog and video.
  When a platform asks for "any vertical" video, design at 9:16: some uploaders reject
  4:5 (Eventbrite does; see the `eventbrite` skill). Lay the content out again for the
  taller frame instead of adding bars.
- Make it work muted. Feeds autoplay without sound, so all meaning must be on screen.
- Export a thumbnail of the best frame next to the video. Most platforms let you upload a
  custom cover, which is better than an early frame that is still building.
- Do not use emoji for content (dates, icons). They render differently on each platform.
  Draw the element instead.
- Keep one identity per element across beats. Move and resize the element to its new place
  instead of removing it and adding a copy.

## Motion gotchas

- **A child's own `transition` overrides the parent's `delayChildren`/`staggerChildren`.**
  If a child variant sets `transition`, give each child an explicit `delay`
  (`base + i * step`). Otherwise all children appear at once.
- **Drive beats from one timeline.** Keep the beat start times in one array and mount
  each scene in its own `<AnimatePresence>`. Let entries wait for exits to clear.
- **Preload before t = 0.** Wait for fonts (`document.fonts.load`) and images
  (`img.decode()`), then start the timeline. Signal ready (for example
  `window.__ready = true`) only after the opening frame is rendered. The export step waits
  for that signal, so frame 0 is never empty.
  Set the flag directly in an effect, not inside `requestAnimationFrame`: a frame-exact
  capture pauses a fake clock while it waits, so rAF never fires and the export times out.
- **Motion uses WAAPI for some properties.** `opacity`, `transform`, `filter` and
  `clipPath` can run on the browser's Web Animations API, in real time. A capture that
  controls time must account for this (see `export-animation`).

## Handoff to export

Once the clip reads well in the browser, render it to a shareable file (no manual screen
recording) with the **export-animation** skill. Use its **frame-exact** mode for any clip
with timed beats, because real-time capture drifts. Match the export preset to the aspect
ratio you designed for.

## Keeping this skill current

Put lessons from each clip into **this skill**, not into Claude's memory. Do not write
memory files for animation work. Add the lesson to the right section above as a general
guideline (no project names, no one-off examples) and bump `version` in the frontmatter:
patch for wording, minor for new guidance, major for a changed workflow.
