---
name: animate
description: Draft a meaningful animated diagram for technical / AI / software-engineering content (social or blog) using Motion (Framer Motion) in React. Use when creating, drafting, designing, or storyboarding an animation, motion diagram, explainer clip, or animated figure — where motion should carry meaning, not decorate. Covers the narrative/timing/visual principles, which motion primitives to reach for (delegating to the framer-motion-* skills), how to preview it live, and how to hand off to export-animation for rendering to video.
license: MIT
version: 1.4.0
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

## Social promo clips (event announcements)

The same principles apply to promo videos for an event or a product (speaker, product idea,
logistics, call to action). Defaults that worked well:

- **Write the script first** as a beat table (time · on screen · motion) in a `script.md`
  next to the clip. Get approval before you build, and update the times after you tune them.
- **Reuse the brand assets the project already has** (for example a cover generator's
  input folder: speaker cutout PNG, logos, palette, font). Do not invent a new look.
- **Default to 15 s, speaker first.** The speaker must be visible in the first ~1 s,
  because feeds pick an early frame as the preview. One beat for the speaker and product,
  one for the product's core idea shown as a delta, and one for logistics and the CTA.
  Leave a still hold of ≥ 1.5 s at the end.
- **Give the key message its own beat.** The headline the client cares about (for
  example "First in-person unveiling") gets a full frame and dominates it. Do not use it
  as a sub-line under another beat.
- **Let terminal and code lines breathe.** Show about 0.7 s per output line and 0.3 s per
  tree line. A summary caption ("…does the rest") comes *after* the result it
  summarizes, not before.
- **Plan for the loop.** LinkedIn auto-loops videos under 30 s, and there is no off switch.
  Fade everything to the empty background in the last ~0.3 s, so the cut back to frame 0
  is seamless.
- **Use real names from the product's docs** in code or terminal mockups (files, tools,
  skills, example output). Don't invent example names. Check the docs before you build
  the scene, and say where any illustrative content is not from the docs.
- **Export a thumbnail PNG** of the settled speaker frame next to the MP4. LinkedIn and
  other platforms let you upload a custom thumbnail. This works better than a first frame
  that is still empty.
- **Make it silent.** All text is on screen, because feeds autoplay muted.
- **Portrait for feeds is 1080×1350 (4:5).** Use 1080×1920 (9:16) only for Reels and
  Stories.
- **Do not use emoji for dates.** The Apple calendar emoji renders "JUL 17". Draw a small
  date tile instead.
- **Keep one logo element across beats.** Introduce the product logo big, then dock it
  in the header by animating that same element. This keeps persistence of context.

## Motion gotchas

- **WAAPI ignores fake clocks.** Motion runs `opacity`, `transform`, `filter` and
  `clipPath` through the browser's Web Animations API, which follows real time. A capture
  that controls time (Playwright `page.clock`) must delete `Element.prototype.animate`
  before the page loads, so that Motion falls back to its rAF engine.
- **A child's own `transition` overrides the parent's `delayChildren`/`staggerChildren`.**
  If a child variant sets `transition`, give each child an explicit `delay`
  (`base + i * step`). Otherwise all children appear at once.
- **Beats from a timer.** Drive the beats with `setTimeout` from one `BEATS` array of
  start seconds, and mount each scene in its own `<AnimatePresence>`. Entries wait about
  0.35 s for exits to clear.
- **Preload before t = 0.** Load fonts with `document.fonts.load(...)` for each weight and
  decode images with `img.decode()`. Only then set `window.__ready = true` and start the
  timeline.

## Handoff to export

Once the clip reads well in the browser, render it to a shareable file (no manual screen
recording) with the **export-animation** skill, which captures frames in headless Chromium
and stitches them with ffmpeg. Match the export **preset** to the aspect ratio you designed
for (square / vertical / wide). See that skill for the one command.

**Frame-exact capture (preferred).** The export skill's default real-time capture loses
sync, because a screenshot takes longer than one frame. Use a capture script that controls
the clock instead:

```js
await page.addInitScript(() => { delete Element.prototype.animate; }); // no WAAPI
await page.clock.install({ time: 0 });
await page.clock.pauseAt(1000);           // frozen while the page loads
await page.goto(URL);
await page.waitForFunction(() => window.__ready === true);
const flush = () => page.evaluate(() => new Promise((r) => {   // let React commit
  const c = new MessageChannel(); c.port1.onmessage = () => r(); c.port2.postMessage(0);
}));
for (let i = 0; i < FPS * DURATION; i++) {
  // Always 1 frame, never big jumps. runFor rounds to whole ms (33.33 → 34, ~2% fast),
  // so step by integer differences:
  if (i > 0) await page.clock.runFor(Math.round(i * 1000 / FPS) - Math.round((i - 1) * 1000 / FPS));
  await flush();
  await page.locator("#stage").screenshot({ path: `frames/f-${String(i).padStart(4, "0")}.png` });
}
```

- **Check single frames the same way.** Add a `STILLS=3.5,10` mode that steps frame by
  frame but only screenshots the frames you ask for. Jumping seconds in one `runFor` makes
  React commit late, and the stills then look wrong.
- **Review with a contact sheet.** Combine the stills with `ffmpeg … xstack` and read it
  as one image. Check frames in the middle of transitions too, not only settled frames.
- **Encode for social:** `ffmpeg -framerate 30 -i frames/f-%04d.png -c:v libx264
  -pix_fmt yuv420p -crf 16 -movflags +faststart out.mp4`.
- **Claude Code sandbox:**
  - Headless Chrome (`chromium.launch({ channel: "chrome" })`) cannot start inside the
    sandbox, so run the capture outside it.
  - `npm install` needs `--cache "$TMPDIR/npm-cache"`.
  - zsh-only expansions such as `${(s:,:)VAR}` trip the safety check. Use plain lists.

A working example with `capture.mjs` and `src/Reel.jsx` is in Malaga-AI:
`sessions/sponsored_sessions/2026_11_26_Ortus/video/app/`.

## Keeping this skill current

Put lessons from each clip into **this skill**, not into Claude's memory. Do not write
memory files for animation work. Add the lesson to the right section above and bump
`version` in the frontmatter: patch for wording, minor for new guidance, major for a
changed workflow.
