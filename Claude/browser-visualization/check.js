#!/usr/bin/env node
// Headless-Chromium page check: console/page errors, failed requests, <video>
// element load state, and a full-page screenshot. See SKILL.md for usage.
//
//   node check.js <url> [screenshot-out-path]
//
// Exits non-zero (with a printed reason) on: navigation failure, any
// pageerror, or any <video> with a non-null .error. Everything else
// (console errors, failed sub-requests) is reported but does not fail the
// run, since headless video-over-Range playback throws benign
// net::ERR_ABORTED noise even on fully-successful loads (see SKILL.md).

const path = require('path');
const fs = require('fs');
const { chromium } = require('playwright-core');

const CHROME_CANDIDATES = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/Applications/Chromium.app/Contents/MacOS/Chromium',
  '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/usr/bin/chromium-browser',
];

function findChrome() {
  for (const p of CHROME_CANDIDATES) {
    if (fs.existsSync(p)) return p;
  }
  return null; // fall back to playwright-core's bundled-browser resolution (usually absent unless installed)
}

async function main() {
  const url = process.argv[2];
  const out = process.argv[3] || './screenshot.png';
  if (!url) {
    console.error('Usage: node check.js <url> [screenshot-out-path]');
    process.exit(2);
  }

  const executablePath = findChrome();
  const browser = await chromium.launch({
    executablePath: executablePath || undefined,
    headless: true,
  });
  const page = await browser.newPage({ viewport: { width: 1400, height: 1000 } });

  const consoleErrors = [];
  const pageErrors = [];
  const failedRequests = [];

  page.on('console', (msg) => { if (msg.type() === 'error') consoleErrors.push(msg.text()); });
  page.on('pageerror', (err) => pageErrors.push(String(err)));
  page.on('requestfailed', (req) => {
    failedRequests.push({ url: req.url(), failure: req.failure()?.errorText });
  });
  page.on('response', (res) => {
    if (res.status() >= 400) failedRequests.push({ url: res.url(), status: res.status() });
  });

  let navError = null;
  try {
    await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
  } catch (e) {
    navError = String(e);
  }

  await page.waitForTimeout(1000);

  // Headless Chromium won't paint a <video>'s frame until something forces a
  // decode -- seek each briefly so the screenshot shows real thumbnails
  // instead of black boxes. Purely cosmetic; doesn't affect the checks below.
  await page.evaluate(async () => {
    const vids = Array.from(document.querySelectorAll('video'));
    await Promise.all(vids.map((v) => new Promise((resolve) => {
      const done = () => { v.removeEventListener('seeked', done); resolve(); };
      v.addEventListener('seeked', done);
      try { v.currentTime = Math.min(1, (v.duration || 2) * 0.15); } catch { resolve(); }
      setTimeout(resolve, 2000);
    })));
  }).catch(() => {});

  const videoInfo = await page.evaluate(() => (
    Array.from(document.querySelectorAll('video')).map((v) => ({
      src: (v.currentSrc || v.src || '').split('/').pop(),
      readyState: v.readyState,       // 4 = HAVE_ENOUGH_DATA (fully loaded/playable)
      networkState: v.networkState,
      duration: v.duration,
      error: v.error ? { code: v.error.code, message: v.error.message } : null,
      videoWidth: v.videoWidth,
      videoHeight: v.videoHeight,
    }))
  ));

  const pageMeta = await page.evaluate(() => ({
    title: document.title,
    bodyScrollWidth: document.body.scrollWidth,
    bodyClientWidth: document.body.clientWidth, // scrollWidth > clientWidth => horizontal overflow bug
  }));

  fs.mkdirSync(path.dirname(path.resolve(out)), { recursive: true });
  await page.screenshot({ path: out, fullPage: true });

  await browser.close();

  // Known-benign noise, filtered out of the "does this actually indicate a
  // problem" verdict but still shown in the raw report:
  const realFailedRequests = failedRequests.filter((r) => {
    if (r.url.endsWith('/favicon.ico') && r.status === 404) return false; // browser auto-requests this; pages here don't define one
    if (r.failure === 'net::ERR_ABORTED') return false; // normal for preload="metadata" videos renegotiating a Range request
    return true;
  });
  const brokenVideos = videoInfo.filter((v) => v.error || v.readyState < 2);

  const result = {
    url, screenshot: path.resolve(out),
    pageMeta, videoInfo, consoleErrors, pageErrors, failedRequests,
    verdict: {
      navError,
      realFailedRequests,
      brokenVideos: brokenVideos.map((v) => v.src),
      horizontalOverflow: pageMeta.bodyScrollWidth > pageMeta.bodyClientWidth,
      ok: !navError && pageErrors.length === 0 && brokenVideos.length === 0 && realFailedRequests.length === 0,
    },
  };

  console.log(JSON.stringify(result, null, 2));
  if (!result.verdict.ok) process.exit(1);
}

main().catch((e) => { console.error('FATAL:', e); process.exit(1); });
