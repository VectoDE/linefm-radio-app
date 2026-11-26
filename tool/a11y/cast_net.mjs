// Browser check "Google Cast in the web version" without a real Chromecast.
//
// Runs against the real web build (after flutter build web, fetch_font_fallback
// and the postbuild) and serves it with the Content-Security-Policy from
// build/hosting/cloudflare/_headers, so the check covers the CSP as deployed.
// The Google Cast sender script is never fetched: the route for
// https://www.gstatic.com/cv/js/sender/v1/cast_sender.js is answered with a
// small fake Cast SDK (window.chrome.cast, window.cast.framework) that records
// what the app sends to the "receiver". Every other request to Google is
// aborted and counted, laut.fm and other hosts are aborted as well, so nothing
// leaves the machine.
//
// Checks:
//  1. Before consent no request to Google, the cast button is visible and
//     asks for consent first.
//  2. "Decline": still no request, also after a reload.
//  3. "Allow": cast_sender.js is requested (from the fake), the decision is
//     stored, the browser picker entry appears, the fake session receives
//     loadMedia with the live stream URL, audio/mpeg, LIVE and metadata, and
//     the button names the connected device.
//  4. Revoking in the settings ends the session, reloads the page and stores
//     "denied"; afterwards no further request to Google.
//  5. No CSP violation during the whole run.
//
// Usage:
//   cd tool/a11y && npm ci && npx playwright install --with-deps chromium
//   node cast_net.mjs --web ../../build/web --hosting ../../build/hosting
// Exit 1 on any failed check.

import { createReadStream, existsSync, readFileSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve, sep } from 'node:path';
import { parseArgs } from 'node:util';

import { chromium } from 'playwright';

const { values: args } = parseArgs({
  options: {
    web: { type: 'string', default: '../../build/web' },
    hosting: { type: 'string', default: '../../build/hosting' },
  },
});

const WEB = resolve(args.web);
const SENDER = 'https://www.gstatic.com/cv/js/sender/v1/cast_sender.js';
const GOOGLE = /(^|\.)(google|googletagmanager|google-analytics|googleapis|gstatic|doubleclick|googlesyndication|googleadservices)\.[a-z.]+$/i;
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.webmanifest': 'application/manifest+json',
  '.bin': 'application/octet-stream',
};

/** CSP of the "/*" block in the rendered Cloudflare headers file. */
function deployedCsp() {
  const file = join(resolve(args.hosting), 'cloudflare', '_headers');
  const line = readFileSync(file, 'utf8')
    .split(/\r?\n/)
    .find((l) => /^\s+Content-Security-Policy:/.test(l));
  if (!line) throw new Error(`no Content-Security-Policy in ${file}`);
  // upgrade-insecure-requests would rewrite the http://127.0.0.1 test server.
  return line
    .replace(/^\s+Content-Security-Policy:\s*/, '')
    .split(';')
    .map((d) => d.trim())
    .filter((d) => d && d !== 'upgrade-insecure-requests')
    .join('; ');
}

function serve(root, csp) {
  const server = createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    let path;
    try {
      path = normalize(join(root, decodeURIComponent(url.pathname)));
    } catch {
      res.writeHead(400).end();
      return;
    }
    if (!path.startsWith(root + sep) && path !== root) {
      res.writeHead(403).end();
      return;
    }
    if (existsSync(path) && statSync(path).isDirectory()) path = join(path, 'index.html');
    if (!existsSync(path)) {
      if (extname(url.pathname)) {
        res.writeHead(404).end();
        return;
      }
      path = join(root, 'index.html');
    }
    res.writeHead(200, {
      'Content-Type': MIME[extname(path)] ?? 'application/octet-stream',
      'Cache-Control': 'no-cache',
      'Content-Security-Policy': csp,
    });
    createReadStream(path).pipe(res);
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

// Fake Cast SDK: the subset of the Web Sender API that web/cast.js uses
// (developers.google.com/cast/docs/reference/web_sender). Records into
// window.__fakeCast; sessionStorage keeps "session ended" across the reload.
const FAKE_SDK = `(function () {
  var log = (window.__fakeCast = { loads: [], stops: 0, volumes: [], ended: 0, options: null });
  var listeners = {};
  var state = 'NOT_CONNECTED';
  var current = null;
  var media = null;
  function fire(type) {
    (listeners[type] || []).forEach(function (fn) { fn({ type: type }); });
  }
  function changed() {
    fire('sessionstatechanged');
    fire('caststatechanged');
  }
  function Session() {}
  Session.prototype.getCastDevice = function () {
    return { label: 'fake-receiver-1', friendlyName: 'Test%20Speaker' };
  };
  Session.prototype.loadMedia = function (req) {
    log.loads.push(JSON.parse(JSON.stringify(req.media)));
    media = {
      stop: function (_req, ok) { log.stops++; ok(); },
    };
    return Promise.resolve(undefined);
  };
  Session.prototype.getMediaSession = function () { return media; };
  Session.prototype.setVolume = function (v) { log.volumes.push(v); };
  var ctx = {
    setOptions: function (o) { log.options = { receiverApplicationId: o.receiverApplicationId, autoJoinPolicy: o.autoJoinPolicy }; },
    addEventListener: function (type, fn) { (listeners[type] = listeners[type] || []).push(fn); },
    getCastState: function () { return state; },
    getCurrentSession: function () { return current; },
    requestSession: function () {
      state = 'CONNECTING';
      changed();
      return new Promise(function (ok) {
        setTimeout(function () {
          current = new Session();
          state = 'CONNECTED';
          changed();
          ok(undefined);
        }, 50);
      });
    },
    endCurrentSession: function () {
      log.ended++;
      try { sessionStorage.setItem('fakeCastEnded', String(log.ended)); } catch (e) {}
      current = null;
      media = null;
      state = 'NOT_CONNECTED';
      changed();
    },
  };
  window.chrome = window.chrome || {};
  window.chrome.cast = {
    AutoJoinPolicy: { ORIGIN_SCOPED: 'origin_scoped' },
    Image: function (url) { this.url = url; },
    media: {
      DEFAULT_MEDIA_RECEIVER_APP_ID: 'CC1AD845',
      StreamType: { LIVE: 'LIVE' },
      MusicTrackMediaMetadata: function () { this.metadataType = 3; },
      MediaInfo: function (id, type) { this.contentId = id; this.contentType = type; },
      LoadRequest: function (info) { this.media = info; },
      StopRequest: function () {},
    },
  };
  window.cast = {
    framework: {
      CastContext: { getInstance: function () { return ctx; } },
      CastContextEventType: { CAST_STATE_CHANGED: 'caststatechanged', SESSION_STATE_CHANGED: 'sessionstatechanged' },
    },
  };
  setTimeout(function () {
    if (window.__onGCastApiAvailable) window.__onGCastApiAvailable(true);
  }, 0);
})();
`;

const failures = [];
function check(ok, msg) {
  console.log(`${ok ? 'OK  ' : 'FAIL'} ${msg}`);
  if (!ok) failures.push(msg);
}

const csp = [];

/** New context: Google requests are recorded, the sender script is faked. */
async function newContext(browser) {
  const context = await browser.newContext({ locale: 'de-DE', viewport: { width: 1280, height: 800 }, serviceWorkers: 'block' });
  await context.exposeBinding('__reportCsp', (_source, text) => csp.push(text));
  await context.addInitScript(() => {
    try {
      localStorage.setItem('linefm.started', '1');
    } catch {
      /* no storage */
    }
    // Headless Chromium may lack window.chrome; Chrome and Edge always have it.
    if (!window.chrome) window.chrome = {};
    document.addEventListener('securitypolicyviolation', (e) => {
      window.__reportCsp(`${e.violatedDirective} ${e.blockedURI}`);
    });
  });
  const google = [];
  const senders = [];
  await context.route('**/*', (route) => {
    const url = new URL(route.request().url());
    if (url.href.startsWith(SENDER)) {
      senders.push(url.href);
      return route.fulfill({ status: 200, contentType: 'text/javascript; charset=utf-8', body: FAKE_SDK });
    }
    if (GOOGLE.test(url.hostname)) {
      google.push(url.href);
      return route.abort();
    }
    if (url.hostname !== '127.0.0.1') return route.abort();
    return route.continue();
  });
  context.on('console', (msg) => {
    if (/Content.Security.Policy/i.test(msg.text())) csp.push(msg.text());
  });
  return { context, google, senders };
}

async function boot(page, base) {
  if (base) await page.goto(base, { waitUntil: 'load' });
  await page.waitForSelector('flt-semantics-placeholder, flt-semantics', { state: 'attached', timeout: 90_000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 3, null, { timeout: 30_000 });
}

async function tap(locator, timeout = 20_000) {
  await locator.first().waitFor({ state: 'attached', timeout });
  await locator.first().evaluate((el) => el.click());
}

const castButton = (page) => page.getByRole('button', { name: /^Auf Gerät übertragen$/ });
const dialog = (page) => page.getByRole('alertdialog', { name: 'Übertragen mit Google Cast' });

async function openSettings(page) {
  const name = /^Einstellungen$/i;
  await tap(page.getByRole('button', { name }).or(page.getByRole('tab', { name })));
  await page.waitForTimeout(1200);
}

/** Switch "Google Cast (Chromecast)"; scrolls until Flutter builds it. */
async function findCastSwitch(page) {
  const name = /Google Cast \(Chromecast\)/;
  const target = page.getByRole('switch', { name }).or(page.getByRole('checkbox', { name })).first();
  const size = page.viewportSize();
  for (let i = 0; i < 14 && (await target.count()) === 0; i++) {
    await page.mouse.move(size.width / 2, size.height / 2);
    await page.mouse.wheel(0, size.height * 0.5);
    await page.waitForTimeout(400);
  }
  await target.waitFor({ state: 'attached', timeout: 15_000 });
  return target;
}

async function main() {
  const server = await serve(WEB, deployedCsp());
  const base = `http://127.0.0.1:${server.address().port}/`;
  const browser = await chromium.launch();
  try {
    // Decline
    {
      const { context, google, senders } = await newContext(browser);
      const page = await context.newPage();
      await boot(page, base);
      await page.waitForTimeout(3000);
      check(await page.evaluate(() => !!window.linefmCast && window.linefmCast.supported()), 'cast.js loaded and reports support');
      check(google.length + senders.length === 0, `before consent no request to Google (${google.join(', ')})`);
      await tap(castButton(page));
      await dialog(page).waitFor({ state: 'attached', timeout: 15_000 });
      check(senders.length === 0, 'consent dialog shown before anything loads');
      await tap(dialog(page).getByRole('button', { name: 'Ablehnen' }));
      await page.waitForTimeout(3000);
      check(google.length + senders.length === 0, 'after "Decline" no request to Google');
      await boot(page, base);
      await page.waitForTimeout(3000);
      check(google.length + senders.length === 0, 'after "Decline" and reload no request to Google');
      await context.close();
    }
    // Allow, cast, revoke
    {
      const { context, google, senders } = await newContext(browser);
      const page = await context.newPage();
      await boot(page, base);
      await page.waitForTimeout(2000);
      check(senders.length === 0, 'before "Allow" the sender script is not requested');
      await tap(castButton(page));
      await dialog(page).waitFor({ state: 'attached', timeout: 15_000 });
      const sender = page.waitForRequest((r) => r.url().startsWith(SENDER), { timeout: 15_000 });
      await tap(dialog(page).getByRole('button', { name: 'Erlauben' }));
      check(await sender.then(() => true, () => false), 'after "Allow" cast_sender.js is requested (fake SDK)');
      check((await page.evaluate(() => localStorage.getItem('linefm.googleCast'))) === 'granted', 'consent stored ("granted")');
      await tap(page.getByRole('button', { name: 'Gerät auswählen' }));
      const loaded = await page
        .waitForFunction(() => window.__fakeCast && window.__fakeCast.loads.length > 0, null, { timeout: 20_000 })
        .then(() => true, () => false);
      check(loaded, 'fake session received loadMedia');
      const fake = await page.evaluate(() => window.__fakeCast);
      const media = fake.loads[0] ?? {};
      check(fake.options?.receiverApplicationId === 'CC1AD845', `Default Media Receiver (${fake.options?.receiverApplicationId})`);
      check(/^https:\/\/([a-z0-9-]+\.)?stream\.laut\.fm\/[a-z0-9_-]+/i.test(media.contentId ?? ''), `stream URL ${media.contentId}`);
      check(media.contentType === 'audio/mpeg', `content type ${media.contentType}`);
      check(media.streamType === 'LIVE', `stream type ${media.streamType}`);
      check(!!media.metadata?.title && !!media.metadata?.artist && !!media.metadata?.albumName,
        `metadata title/artist/station (${media.metadata?.title} / ${media.metadata?.artist} / ${media.metadata?.albumName})`);
      const connected = page.getByRole('button', { name: 'Verbunden mit Test Speaker' });
      check(await connected.first().waitFor({ state: 'attached', timeout: 10_000 }).then(() => true, () => false),
        'cast button names the connected device');

      await openSettings(page);
      const toggle = await findCastSwitch(page);
      check((await toggle.getAttribute('aria-checked')) === 'true', 'settings switch "Google Cast" is on');
      const reloaded = page.waitForEvent('load', { timeout: 15_000 });
      const before = google.length + senders.length;
      await toggle.evaluate((el) => el.click());
      check(await reloaded.then(() => true, () => false), 'revoking reloads the page (loaded SDK is discarded)');
      await boot(page);
      await page.waitForTimeout(4000);
      check((await page.evaluate(() => sessionStorage.getItem('fakeCastEnded'))) === '1', 'revoking ended the cast session');
      check((await page.evaluate(() => localStorage.getItem('linefm.googleCast'))) === 'denied', 'revocation stored ("denied")');
      check(google.length + senders.length === before, 'after revoking no further request to Google');
      check(await page.evaluate(() => typeof window.cast === 'undefined'), 'no Cast SDK on the page after revoking');
      await context.close();
    }
  } finally {
    await browser.close();
    server.close();
  }
  check(csp.length === 0, `no CSP violations (${csp.join(' | ')})`);
  console.log(failures.length === 0 ? 'Cast check: all passed' : `Cast check: ${failures.length} failed`);
  process.exit(failures.length === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  if (csp.length > 0) console.error(`CSP violations: ${csp.join(' | ')}`);
  process.exit(1);
});
