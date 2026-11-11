// capture.mjs — render a running Motion/React/Vite animation to PNG frames
// using headless Chromium. Every knob is env-overridable so one script serves
// every clip. Run from the target project root (so `frames/` lands there).
//
//   FPS=60 DURATION=7 SELECTOR="svg" PRESET=square node capture.mjs
//
// Env knobs:
//   FPS            frames per second                      (default 60)
//   DURATION       seconds of animation to capture        (default 4)
//   URL            dev server URL                          (default http://localhost:5173)
//   SELECTOR       CSS selector of the animation root      (default "svg")
//   PRESET         square | vertical | wide                (default square)
//   DEVICE_SCALE   deviceScaleFactor for retina sharpness  (default 2)
//   FRAMES_DIR     output dir for PNG frames               (default "frames")
//   DETERMINISTIC  "true" to drive window.__seek per frame (default false)
//   OMIT_BG        "true" for transparent PNGs             (default true)
import { createRequire } from "module";
import fs from "fs";

// Resolve playwright from the *project* (cwd) so this script can live in the
// skill directory and still find the dependency installed in the project.
const require = createRequire(`${process.cwd()}/`);
const { chromium } = require("playwright");

const FPS = Number(process.env.FPS ?? 60);
const DURATION = Number(process.env.DURATION ?? 4);
const URL = process.env.URL ?? "http://localhost:5173";
const SELECTOR = process.env.SELECTOR ?? "svg";
const PRESET = process.env.PRESET ?? "square";
const DEVICE_SCALE = Number(process.env.DEVICE_SCALE ?? 2);
const FRAMES_DIR = process.env.FRAMES_DIR ?? "frames";
const DETERMINISTIC = process.env.DETERMINISTIC === "true";
const OMIT_BG = (process.env.OMIT_BG ?? "true") === "true";

const PRESETS = {
  square: { width: 1080, height: 1080 },
  vertical: { width: 1080, height: 1350 },
  wide: { width: 1920, height: 1080 },
};
const viewport = PRESETS[PRESET] ?? PRESETS.square;

fs.rmSync(FRAMES_DIR, { recursive: true, force: true });
fs.mkdirSync(FRAMES_DIR, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport, deviceScaleFactor: DEVICE_SCALE });
await page.goto(URL, { waitUntil: "networkidle" });

// Deterministic mode: wait for the export clock the component installs, then
// drive the timeline frame-by-frame (see useExportClock.js).
if (DETERMINISTIC) {
  await page.waitForFunction(() => window.__ready === true, null, { timeout: 10000 });
}

const el = page.locator(SELECTOR).first();
await el.waitFor();

const total = Math.round(FPS * DURATION);
for (let i = 0; i < total; i++) {
  if (DETERMINISTIC) {
    const t = i / FPS;
    await page.evaluate((t) => window.__seek(t), t);
    await page.waitForTimeout(0); // let React commit the frame
  } else {
    await page.waitForTimeout(1000 / FPS);
  }
  await el.screenshot({
    path: `${FRAMES_DIR}/f-${String(i).padStart(4, "0")}.png`,
    omitBackground: OMIT_BG,
  });
}

await browser.close();
console.log(`Captured ${total} frames -> ${FRAMES_DIR}/`);
