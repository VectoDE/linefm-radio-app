// Autoplay behaviour of the web build in real browser engines.
//
// Browsers block audio before a user action. The app must therefore start
// silently, show its start button ("Start radio") and begin playback only
// after a real click. Checked per engine:
//   1. before the click: navigator.userActivation.hasBeenActive is false, the
//      start button is visible, no media element is playing and no play() call
//      was rejected by the browser (NotAllowedError);
//   2. after a real mouse click on the button: the page is user-activated, the
//      button is gone and the app asked the media element to play.
// Audio itself is not asserted (the streams come from laut.fm and depend on
// the codecs of the engine); the result file records what happened.
//
// Usage (server running, see performance.yml):
//   cd tool/perf && npm ci --ignore-scripts && npx playwright install --with-deps chromium firefox webkit
//   node autoplay_browsers.mjs --base http://127.0.0.1:8080 --out out --browsers chromium,firefox,webkit,msedge
//
// msedge uses the installed Microsoft Edge (Playwright channel "msedge"). When
// it is not installed the browser is reported as "not installed" and the run
// continues; the other engines always have to pass.
import { mkdirSync, writeFileSync, appendFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { chromium, firefox, webkit } from 'playwright';

function parseArgs(argv) {
  const out = { base: 'http://127.0.0.1:8080', out: 'out', browsers: 'chromium,firefox,webkit,msedge' };
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    if (key in out) out[key] = argv[i + 1];
  }
  return out;
}

const args = parseArgs(process.argv.slice(2));
const OUT = resolve(args.out);
const BASE = args.base.replace(/\/$/, '');

const LAUNCHERS = {
  chromium: () => chromium.launch(),
  firefox: () => firefox.launch(),
  webkit: () => webkit.launch(),
  msedge: () => chromium.launch({ channel: 'msedge' }),
};

// Counts play() calls and the rejections the browser answers them with.
const INIT = () => {
  window.__autoplay = { playCalls: 0, rejected: 0, rejections: [] };
  const play = HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play = function (...a) {
    window.__autoplay.playCalls++;
    const result = play.apply(this, a);
    if (result && typeof result.catch === 'function') {
      result.catch((e) => {
        if (e && e.name === 'NotAllowedError') {
          window.__autoplay.rejected++;
          window.__autoplay.rejections.push(String(e.message).slice(0, 120));
        }
      });
    }
    return result;
  };
  try {
    // Same state as a returning visitor: engine starts on load, storage notice
    // confirmed. Autoplay stays at its default (on).
    localStorage.setItem('linefm.started', '1');
    localStorage.setItem('flutter.linefm-storage-notice-dismissed', 'true');
  } catch {
    /* no storage */
  }
};

const BUTTON = '^(Start radio|Radio starten)$';

/** Position of the start button in the Flutter semantics tree, or null. */
const findButton = (page) =>
  page.evaluate((src) => {
    const re = new RegExp(src, 'i');
    for (const el of document.querySelectorAll('flt-semantics')) {
      const name = (el.getAttribute('aria-label') || el.textContent || '').trim();
      if (!re.test(name)) continue;
      const r = el.getBoundingClientRect();
      if (r.width > 0 && r.height > 0) return { x: r.x + r.width / 2, y: r.y + r.height / 2, name };
    }
    return null;
  }, BUTTON);

const state = (page) =>
  page.evaluate(() => ({
    active: 'userActivation' in navigator ? navigator.userActivation.hasBeenActive : null,
    playing: [...document.querySelectorAll('audio,video')].filter((m) => !m.paused).length,
    mediaElements: document.querySelectorAll('audio,video').length,
    ...window.__autoplay,
  }));

async function waitFor(fn, what, timeout = 60_000) {
  const end = Date.now() + timeout;
  for (;;) {
    const v = await fn();
    if (v) return v;
    if (Date.now() > end) throw new Error(`timeout waiting for ${what}`);
    await new Promise((r) => setTimeout(r, 250));
  }
}

async function check(name) {
  const result = { browser: name, status: 'passed', failures: [], notes: [] };
  let browser;
  try {
    browser = await LAUNCHERS[name]();
  } catch (e) {
    if (name === 'msedge') return { ...result, status: 'not installed', notes: [String(e.message).split('\n')[0]] };
    throw e;
  }
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 800 }, locale: 'en-US' });
    await context.addInitScript(INIT);
    const page = await context.newPage();
    result.version = browser.version();
    await page.goto(`${BASE}/`, { waitUntil: 'load', timeout: 120_000 });
    await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 90_000 });
    // A script click does not count as a user action for the autoplay rules.
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    const button = await waitFor(() => findButton(page), 'the start button before any click', 90_000);
    result.notes.push(`button "${button.name}" found`);
    await page.screenshot({ path: join(OUT, `autoplay-${name}-before.png`) });

    const before = await state(page);
    result.before = before;
    if (before.active === true) result.failures.push('page was user-activated before the click');
    if (before.playing > 0) result.failures.push(`${before.playing} media element(s) playing before the click`);
    if (before.rejected > 0) result.failures.push(`browser rejected play() ${before.rejected} time(s): ${before.rejections.join('; ')}`);

    await page.mouse.click(button.x, button.y);
    await waitFor(async () => !(await findButton(page)), 'the start button to disappear', 20_000).catch(() => {
      result.failures.push('start button still visible 20 s after the click');
    });
    await page.waitForTimeout(2000);
    await page.screenshot({ path: join(OUT, `autoplay-${name}-after.png`) });
    const after = await state(page);
    result.after = after;
    if (after.active === false) result.failures.push('page not user-activated after the click');
    if (after.playCalls === 0 && after.mediaElements === 0) result.failures.push('no media element was asked to play after the click');
    if (after.rejected > 0) result.failures.push(`browser rejected play() after the click: ${after.rejections.join('; ')}`);
    if (after.active === null) result.notes.push('engine has no navigator.userActivation, activation not asserted');
  } catch (e) {
    result.failures.push(String(e.message ?? e).split('\n')[0]);
  } finally {
    await browser.close();
  }
  if (result.failures.length) result.status = 'failed';
  return result;
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const names = args.browsers.split(',').filter((n) => LAUNCHERS[n]);
  const results = [];
  for (const name of names) {
    const r = await check(name);
    results.push(r);
    console.log(`${name}: ${r.status}${r.failures.length ? ` (${r.failures.join(' | ')})` : ''}`);
  }
  writeFileSync(join(OUT, 'autoplay.json'), JSON.stringify({ base: BASE, results }, null, 2));
  if (process.env.GITHUB_STEP_SUMMARY) {
    const rows = results.map((r) => {
      const a = r.after;
      const detail = r.failures.length ? r.failures.join('; ') : r.notes.join('; ') || '-';
      return `| ${r.browser} ${r.version ?? ''} | ${r.status} | ${a ? `${a.playCalls} play() calls, ${a.playing} playing` : '-'} | ${detail} |`;
    });
    appendFileSync(
      process.env.GITHUB_STEP_SUMMARY,
      ['### Autoplay in browser engines', '', '| Browser | Result | After the click | Notes |', '|---|---|---|---|', ...rows, ''].join('\n'),
    );
  }
  if (results.some((r) => r.status === 'failed')) process.exit(1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
