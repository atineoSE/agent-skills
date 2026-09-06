---
name: browser-visualization
description: Headlessly load a locally-served page in a real Chrome, check for console/page errors and broken resources (including <video> load state), and capture a full-page screenshot. Use when asked to "check it in a browser," review an HTML page or local site, or verify a UI/frontend change actually renders — anywhere a visual/functional check of a local page is needed but there's no interactive GUI browser available.
version: 1.0.0
---

# Browser visualization — headless page check

Drives the system's real Google Chrome headlessly via `playwright-core`,
against any page already being served locally (a dev server, a static-file
server, whatever). Produces: console/page-error report, per-`<video>`
load-state check, broken-resource list, and a full-page screenshot you can
actually look at.

This skill is project-agnostic — it takes a URL and a screenshot path, and
makes no assumptions about which repo or app you're checking.

## Why this exists, not something else

Two other paths were tried and rejected before landing here — know this so
you don't re-attempt them expecting a different result on macOS:

- **`chrome-cli`** (AppleScript-driven, controls the real GUI Chrome) can
  open tabs, list windows, get position/size — but its `execute`/`source`
  commands (anything requiring JS access) need **View → Developer → Allow
  JavaScript from Apple Events** manually toggled in Chrome's menu bar.
  `defaults write com.google.Chrome AllowJavaScriptFromAppleEvents -bool
  true` does **not** work on current Chrome versions — the toggle has to be
  clicked. UI-scripting that click via `osascript`/System Events additionally
  requires Accessibility permission for whatever process is running the
  automation, which isn't granted by default and can't be granted from
  inside a sandboxed shell.
- **`screencapture`** (macOS's native screenshot tool) needs Screen Recording
  permission for the host app in System Settings → Privacy & Security. Also
  not granted by default, also not grantable from inside the shell.

Both are real options *if* the user grants those two OS-level permissions —
but they're one-time manual steps outside automation's reach, so don't
depend on them. `playwright-core` pointed at the same installed Chrome binary
sidesteps both: headless launch needs neither permission, and it gives
programmatic console/error/DOM access for free instead of AppleScript's
all-or-nothing JS gate.

## Setup (already done once; re-run only if `node_modules` is missing here)

```bash
cd ~/.claude/skills/browser-visualization   # symlinked to this skill's real location
npm install   # installs playwright-core only — no browser binary download,
              # it launches the system's existing Google Chrome via executablePath
```

`node_modules/` here is git-ignored. No `playwright install` / browser
download needed — `check.js` points `executablePath` straight at
`/Applications/Google Chrome.app/...` (or Chromium/Edge as fallbacks; see
`CHROME_CANDIDATES` in the script). Because this skill lives in the shared,
symlinked skills directory rather than inside any one project, this one
`npm install` makes the dependency available to every project without a
per-project `node_modules` — that's the "system-wide" part.

## Use it

The target page must already be reachable over HTTP. If it includes
`<video>` elements, the server needs to support HTTP Range requests (plain
`python3 -m http.server` does **not** — video seeking/loading silently
breaks). Then:

```bash
node ~/.claude/skills/browser-visualization/check.js <url> [screenshot-out-path]
```

Example, against anything already running on a local port:

```bash
node ~/.claude/skills/browser-visualization/check.js \
  http://127.0.0.1:3000/ /tmp/check.png
```

It prints a JSON report to stdout and exits non-zero if `verdict.ok` is
false. Then **read the screenshot with the `Read` tool** — the JSON tells
you whether it's broken, but only looking at the image confirms it actually
looks right (layout, spacing, dark/light theme, nothing overlapping).

## Reading the JSON report

- **`verdict.ok`** — the actionable answer. `true` means: page navigated,
  zero `pageerror`s, every `<video>` loaded (`readyState >= 2`, no `.error`),
  and no failed request beyond the known-benign ones filtered out below.
- **`verdict.realFailedRequests`** / **`verdict.brokenVideos`** — what
  actually failed, with the noise already stripped out (see next section).
- **`videoInfo[].readyState`** — the authority on whether a `<video>`
  actually loaded. `4` = `HAVE_ENOUGH_DATA` (fully playable). Trust this
  over `failedRequests`, not the other way around (see below).
- **`pageMeta.bodyScrollWidth > pageMeta.bodyClientWidth`** →
  `verdict.horizontalOverflow: true` — a real layout bug (something's
  pushing the page wider than the viewport), surfaced automatically.

## Known-benign noise — don't chase these

The script already filters both of these out of `verdict`, but they still
show up in the raw `consoleErrors`/`failedRequests` arrays, so don't mistake
raw-array entries for real failures:

- **`GET /favicon.ico` → 404.** Most local dev pages don't define a
  favicon; the browser requests it automatically. Harmless unless the app
  is specifically expected to serve one.
- **`net::ERR_ABORTED` on a media file** under `requestfailed`. Normal for
  `<video preload="metadata">` (and similar): the browser fires an initial
  request, aborts it, and re-requests with a `Range` header once it knows
  it needs more data. Looks like a failure in the request log even when the
  video loads perfectly — **cross-check `videoInfo[].readyState` before
  concluding anything's actually broken.** A video with `readyState: 4`,
  correct `videoWidth`/`videoHeight`, and `error: null` loaded fine, full
  stop, regardless of what `requestfailed` says.

## The video-thumbnail seek trick

Headless Chromium doesn't paint a `<video>`'s first frame until something
forces a decode — screenshotting immediately after load gives black boxes
where every video should be, even when the video loaded fine. Fixed by
seeking each `<video>` to ~15% of its duration (capped at 1s) right before
the screenshot; `check.js` already does this. If you write a one-off
variant of this script, keep that step — a screenshot full of black
rectangles is easy to misread as broken video sources.

## Extending the checks

`check.js` is generic (any URL — validated against both a static reference
page with a dozen `<video>` elements and a JS-heavy interactive page with
SVG overlays and live canvas/SVG charts, both rendered correctly). For a
page-specific check beyond what it already does (e.g. "click through these
5 steps and screenshot each," "verify this list has exactly N items"), copy
its `page.evaluate(...)` pattern rather than starting a new driver from
scratch — `page`, the error collectors, and the screenshot step are already
wired up.

## Changelog

- **1.0.0** (2026-08-09) — Initial version, generalized from a project-
  specific driver after validating it against a static multi-`<video>`
  reference page and an interactive JS page (SVG overlays, live charts,
  scrubber) — both rendered correctly with zero real errors. `chrome-cli`/
  AppleScript and `screencapture` were tried first and rejected; see "Why
  this exists, not something else" above.
