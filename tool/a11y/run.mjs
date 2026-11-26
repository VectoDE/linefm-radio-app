// axe check of the web version (A4).
//
// Usage (after flutter build web, fetch_font_fallback and postbuild):
//   cd tool/a11y && npm ci && npx playwright install --with-deps chromium
//   node run.mjs --web ../../build/web --out out
//
// Flow: small static server on 127.0.0.1 for build/web, Chromium via
// Playwright, enable Flutter semantics (the accessibility tree only appears
// then), navigate to a view, run axe-core with WCAG 2.0 to 2.2 (A, AA, AAA) and
// best practices. Views: stations, history, favorites,
// settings, storage-clearing dialog, alarm, alarm time dialog,
// about, player (narrow only, when wide it is embedded in the station list),
// sleep timer sheet and favorites export sheet; each at 390
// and 1280 px, light and dark. Plus imprint and privacy policy (de/en) as
// static pages.
//
// Per color scheme and width the app loads once; between views it goes back
// via Escape, "Back" and navigation to the home page (only if that
// fails is it reloaded; the report counts that under "reloads").
//
// Consent dialog (statistics) only with --consent and a dedicated build with
// test Umami values that lead nowhere (no real data):
//   flutter build web ... --dart-define=UMAMI_URL=http://127.0.0.1:9
//     --dart-define=UMAMI_WEBSITE_ID=00000000-0000-0000-0000-000000000000
//   node run.mjs --web ../../build/web --out out-consent --consent
// Requests to 127.0.0.1:9 are additionally dropped in the browser. CI
// builds only without telemetry, so the dialog does not appear there.
//
// Result: out/axe-report.json (with commit SHA, duration, "incomplete" =
// checks axe cannot decide), screenshots per view.
// Exit 1 as soon as any violation occurs (every level, baseline 0) or
// a view is unreachable. "incomplete" does not abort, but appears
// in the report and summary.

import { execFileSync } from 'node:child_process';
import { createReadStream, existsSync, mkdirSync, statSync, writeFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve, sep } from 'node:path';
import { parseArgs } from 'node:util';

import AxeBuilder from '@axe-core/playwright';
import { chromium } from 'playwright';

const { values: args } = parseArgs({
  options: {
    web: { type: 'string', default: '../../build/web' },
    out: { type: 'string', default: 'out' },
    only: { type: 'string', default: '' },
    consent: { type: 'boolean', default: false },
  },
});

const WEB = resolve(args.web);
const OUT = resolve(args.out);
const TAGS = ['wcag2a', 'wcag2aa', 'wcag2aaa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice'];
const THEMES = ['light', 'dark'];
const WIDTHS = [
  { name: 'm390', width: 390, height: 844 },
  { name: 'w1280', width: 1280, height: 800 },
];

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.xml': 'application/xml',
  '.webmanifest': 'application/manifest+json',
  '.bin': 'application/octet-stream',
};

function commitSha() {
  if (process.env.GITHUB_SHA) return process.env.GITHUB_SHA;
  try {
    return execFileSync('git', ['rev-parse', 'HEAD'], { encoding: 'utf8' }).trim();
  } catch {
    return 'unknown';
  }
}

/** Static server like the hosting targets: folder -> index.html, paths without extension -> SPA. */
function serve(root) {
  const server = createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    let decoded;
    try {
      decoded = decodeURIComponent(url.pathname);
    } catch {
      // Broken percent encoding (e.g. "%E0%A4%A"): reject the request instead of crashing.
      res.writeHead(400).end();
      return;
    }
    let path = normalize(join(root, decoded));
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
    });
    createReadStream(path).pipe(res);
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

/** Enable Flutter semantics and wait until the accessibility tree is in place. */
async function enableSemantics(page) {
  await page.waitForSelector('flt-semantics-placeholder, flt-semantics', {
    state: 'attached',
    timeout: 60_000,
  });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 10, null, {
    timeout: 30_000,
  });
  await page.waitForTimeout(800);
}

/** First node with one of the roles and a matching name. */
function byRole(page, role, name) {
  const roles = Array.isArray(role) ? role : [role];
  return roles
    .map((r) => page.getByRole(r, { name }))
    .reduce((a, b) => a.or(b))
    .first();
}

/**
 * Tap a semantics node (role + name), like a screen reader.
 * Flutter only creates nodes in the visible area; if the target is missing, the
 * content is moved on with the mouse wheel.
 */
async function activate(page, role, name) {
  const target = byRole(page, role, name);
  const size = page.viewportSize();
  for (let i = 0; i < 12 && (await target.count()) === 0; i++) {
    await page.mouse.move(size.width / 2, size.height / 2);
    await page.mouse.wheel(0, size.height * 0.6);
    await page.waitForTimeout(400);
  }
  await target.waitFor({ state: 'attached', timeout: 15_000 });
  await target.evaluate((el) => el.click());
  await page.waitForTimeout(900);
}

/** Structure for the report: h1, landmarks. */
function structure(page) {
  return page.evaluate(() => {
    const text = (el) => (el.getAttribute('aria-label') || el.textContent || '').trim().slice(0, 60);
    const h1 = [...document.querySelectorAll('h1, [role="heading"][aria-level="1"]')]
      .filter((el) => !el.closest('[aria-hidden="true"], [hidden]'))
      .map(text);
    const landmarks = [
      ...document.querySelectorAll(
        'main, nav, header, footer, aside, [role="main"], [role="navigation"], [role="banner"], ' +
          '[role="contentinfo"], [role="complementary"], [role="region"][aria-label]',
      ),
    ]
      .filter((el) => !el.closest('[aria-hidden="true"], [hidden]'))
      .map((el) => `${el.getAttribute('role') || el.tagName.toLowerCase()} ${el.getAttribute('aria-label') || ''}`.trim());
    return { h1, landmarks };
  });
}

/**
 * Expectation per view: either an h1 (proves that navigation arrived there,
 * otherwise axe would check the home page twice; null = no
 * h1, narrow player) or a dialog with role and accessible name.
 */
const EXPECT = {
  sender: { h1: /^ALLE SENDER$/i },
  verlauf: { h1: /^ZULETZT GESPIELT$/i },
  favoriten: { h1: /^FAVORITEN$/i },
  einstellungen: { h1: /^EINSTELLUNGEN$/i },
  wecker: { h1: /^WECKER$/i },
  ueber: { h1: /^ÜBER LINEFM RADIO$/i },
  player: { h1: null },
  'dialog-speicher-loeschen': { dialog: ['alertdialog', /^Speicher löschen\?$/] },
  // On the web text entry only (see timeEntryMode in alarm_screen.dart).
  'dialog-wecker-uhrzeit': { dialog: ['dialog', /^Uhrzeit eingeben$/] },
  'sheet-sleeptimer': { dialog: ['dialog', /^Sleeptimer$/] },
  'sheet-favoriten-export': { dialog: ['dialog', /^Favoriten exportieren$/] },
  'dialog-einwilligung': { dialog: ['alertdialog', /^Statistik und Fehlerberichte$/] },
};

/** Expected h1 of the static legal pages. */
const LEGAL = {
  '/impressum/': /^Impressum$/,
  '/datenschutz/': /^Datenschutzerklärung$/,
  '/impressum/en/': /^Imprint$/,
  '/datenschutz/en/': /^Privacy policy$/,
};

/**
 * Views of the app: name -> steps from the home page (stations). Order chosen
 * so that as little as possible has to be reset. `seed` = put favorites into
 * storage beforehand (the export only appears with favorites).
 */
function appViews(wide) {
  // Consent only: appears at the start of a build with telemetry.
  if (args.consent) return [['dialog-einwilligung', []]];
  // Narrow: bottom bar (stations, player, history) plus header (favorites,
  // settings). Wide: navigation bar on the left with tabs.
  const nav = ['button', 'tab'];
  const settings = [nav, /^Einstellungen$/i];
  const views = [
    ['sender', []],
    ['verlauf', [[nav, /^Verlauf$/i]]],
    ['favoriten', [[nav, /^Favoriten$/i]]],
    ['einstellungen', [settings]],
    ['dialog-speicher-loeschen', [settings, ['button', /^Speicher löschen$/]]],
    ['wecker', [settings, ['button', /^Wecker/]]],
    ['dialog-wecker-uhrzeit', [settings, ['button', /^Wecker/], ['button', /^Wecker hinzufügen$/]]],
    ['ueber', [settings, ['button', /^Über LINEFM Radio/]]],
  ];
  if (!wide) views.push(['player', [['button', /^Player$/]]]);
  // When wide, the player sits in the station list; when narrow it is its own area.
  views.push([
    'sheet-sleeptimer',
    wide ? [['button', /^Sleeptimer einstellen$/]] : [['button', /^Player$/], ['button', /^Sleeptimer einstellen$/]],
  ]);
  views.push([
    'sheet-favoriten-export',
    // With favorites the button in the header is called "Favoriten, 1 Song".
    [[nav, /^Favoriten(,|$)/i], ['button', /^Favoriten exportieren$/]],
    { seed: true },
  ]);
  return views;
}

/** One favorite plus storage consent in the shared_preferences format (web). */
async function seedFavorites(page) {
  await page.evaluate(() => {
    const favorites = [
      {
        key: 'linefm:pruefung:a11y',
        station: 'linefm',
        stationSlug: 'linefm',
        title: 'a11y',
        artist: 'Pruefung',
      },
    ];
    localStorage.setItem('flutter.linefm-storage-notice-dismissed', 'true');
    localStorage.setItem('flutter.linefm-favorites', JSON.stringify(JSON.stringify(favorites)));
  });
}

async function main() {
  if (!existsSync(join(WEB, 'index.html'))) {
    console.error(`a11y: ${WEB}/index.html is missing (run flutter build web first)`);
    process.exit(2);
  }
  const started = Date.now();
  mkdirSync(OUT, { recursive: true });
  const server = await serve(WEB);
  const base = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch();
  const results = [];
  const only = args.only ? new Set(args.only.split(',')) : null;
  let reloads = 0;

  async function check(page, entry, t0) {
    const axe = await new AxeBuilder({ page }).withTags(TAGS).analyze();
    const pick = (list) =>
      list.map((v) => ({
        id: v.id,
        impact: v.impact,
        help: v.help,
        nodes: v.nodes.length,
        targets: v.nodes.slice(0, 5).map((n) => n.target.join(' ')),
      }));
    const violations = pick(axe.violations);
    const incomplete = pick(axe.incomplete);
    const shot = `${entry.kind}-${entry.theme}-${entry.layout}-${entry.view}.png`;
    await page.screenshot({ path: join(OUT, shot) });
    const s = await structure(page);
    results.push({
      ...entry,
      screenshot: shot,
      axeVersion: axe.testEngine.version,
      ms: Date.now() - t0,
      ...s,
      violations,
      incomplete,
    });
    console.log(
      `${violations.length ? 'ERROR' : 'ok   '} ${entry.theme} ${entry.layout} ${entry.view}: ` +
        `${violations.length} violations, ${incomplete.length} incomplete, h1=${JSON.stringify(s.h1)}`,
    );
  }

  async function semanticsDump(page) {
    return page
      .evaluate(() =>
        [...document.querySelectorAll('flt-semantics[role], flt-semantics [role]')]
          .map((e) => `${e.getAttribute('role')}:${(e.getAttribute('aria-label') || e.textContent || '').trim().slice(0, 40)}`)
          .slice(0, 80),
      )
      .catch(() => []);
  }

  /** Load the app fresh (first call or when the reset fails). */
  async function boot(page) {
    await page.goto(`${base}/`, { waitUntil: 'load' });
    await enableSemantics(page);
  }

  /** Back to the home page: close dialogs, leave subpages, pick stations. */
  async function home(page) {
    const open = page.locator('[role="dialog"], [role="alertdialog"]');
    for (let i = 0; i < 3 && (await open.count()) > 0; i++) {
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
    }
    const back = page.getByRole('button', { name: /^Zurück$/ }).first();
    for (let i = 0; i < 3 && (await back.count()) > 0; i++) {
      await back.evaluate((el) => el.click());
      await page.waitForTimeout(700);
    }
    const sender = byRole(page, ['button', 'tab'], /^Sender$/i);
    if ((await sender.count()) > 0) {
      await sender.evaluate((el) => el.click());
      await page.waitForTimeout(700);
    }
    const { h1 } = await structure(page);
    return (await open.count()) === 0 && h1.length === 1 && EXPECT.sender.h1.test(h1[0]);
  }

  async function verify(page, view) {
    const want = EXPECT[view];
    if (want.dialog) {
      const [role, name] = want.dialog;
      await page.getByRole(role, { name }).waitFor({ state: 'attached', timeout: 10_000 });
      return;
    }
    const { h1 } = await structure(page);
    const ok = want.h1 === null ? h1.length === 0 : h1.length === 1 && want.h1.test(h1[0]);
    if (!ok) throw new Error(`View not reached: h1=${JSON.stringify(h1)}, expected ${want.h1 ?? 'none'}`);
  }

  try {
    for (const theme of THEMES) {
      for (const size of WIDTHS) {
        const context = await browser.newContext({
          viewport: { width: size.width, height: size.height },
          colorScheme: theme,
          locale: 'de-DE',
          reducedMotion: 'reduce',
        });
        const wide = size.width >= 840;
        // Test Umami (--consent) points nowhere; let nothing through anyway.
        await context.route(/^https?:\/\/127\.0\.0\.1:9\//, (route) => route.abort());
        const page = await context.newPage();
        // Static shell as a first-time visitor sees it: the engine starts only
        // on intent (web/flutter_bootstrap.js), so it is a page of its own.
        if (!only || only.has('shell')) {
          const entry = { kind: 'shell', theme, layout: size.name, width: size.width, view: 'shell', url: '/' };
          const t0 = Date.now();
          try {
            await page.goto(`${base}/`, { waitUntil: 'load' });
            await page.waitForSelector('#start-app.ready', { timeout: 15_000 });
            await check(page, entry, t0);
          } catch (error) {
            const message = String(error).split(/\r?\n/)[0];
            results.push({ ...entry, error: message });
            console.log(`ERROR ${theme} ${size.name} shell: ${message}`);
          }
        }
        // From here on behave like a returning visitor: the app starts on load.
        await context.addInitScript(() => {
          try {
            localStorage.setItem('linefm.started', '1');
          } catch {
            /* no storage */
          }
        });
        let fresh = false;
        for (const [view, steps, opts = {}] of appViews(wide)) {
          if (only && !only.has(view)) continue;
          const entry = { kind: 'app', theme, layout: size.name, width: size.width, view, url: '/' };
          const t0 = Date.now();
          try {
            if (opts.seed) {
              if (!fresh) await boot(page);
              await seedFavorites(page);
              await boot(page);
              reloads++;
            } else if (!fresh) {
              await boot(page);
            } else if (!(await home(page))) {
              await boot(page);
              reloads++;
            }
            fresh = true;
            for (const [role, name] of steps) await activate(page, role, name);
            await verify(page, view);
            await check(page, entry, t0);
          } catch (error) {
            results.push({ ...entry, error: String(error).split('\n')[0], semanticsNodes: await semanticsDump(page) });
            console.log(`ERROR ${theme} ${size.name} ${view}: unreachable (${String(error).split('\n')[0]})`);
            fresh = false;
          }
        }
        for (const [url, h1Want] of Object.entries(args.consent ? {} : LEGAL)) {
          const view = url.replaceAll('/', '-').replace(/^-|-$/g, '');
          if (only && !only.has(view)) continue;
          const entry = { kind: 'legal', theme, layout: size.name, width: size.width, view, url };
          const t0 = Date.now();
          try {
            const response = await page.goto(`${base}${url}`, { waitUntil: 'load' });
            if (!response || response.status() !== 200) {
              throw new Error(`HTTP ${response?.status() ?? 'no response'}`);
            }
            const h1 = await page.locator('h1').allInnerTexts();
            if (h1.length !== 1 || !h1Want.test(h1[0].trim())) {
              throw new Error(`h1=${JSON.stringify(h1)}, expected ${h1Want}`);
            }
            await check(page, entry, t0);
          } catch (error) {
            results.push({ ...entry, error: String(error).split('\n')[0] });
            console.log(`ERROR ${theme} ${size.name} ${view}: ${String(error).split('\n')[0]}`);
          }
        }
        await context.close();
      }
    }
  } finally {
    await browser.close();
    server.close();
  }

  const failed = results.filter((r) => r.error || r.violations.length > 0);
  const count = (key) => results.reduce((n, r) => n + (r[key]?.length ?? 0), 0);
  const report = {
    commit: commitSha(),
    generated: new Date().toISOString(),
    durationMs: Date.now() - started,
    tool: { playwright: (await import('playwright/package.json', { with: { type: 'json' } })).default.version },
    tags: TAGS,
    gate: 'no violation (every level, baseline 0), every view reachable; incomplete is reported',
    summary: {
      runs: results.length,
      failed: failed.length,
      unreachable: results.filter((r) => r.error).length,
      violations: count('violations'),
      seriousOrCritical: results.reduce(
        (n, r) => n + (r.violations?.filter((v) => v.impact === 'serious' || v.impact === 'critical').length ?? 0),
        0,
      ),
      incomplete: count('incomplete'),
      incompleteRules: [...new Set(results.flatMap((r) => (r.incomplete ?? []).map((v) => v.id)))].sort(),
      reloads,
    },
    results,
  };
  writeFileSync(join(OUT, 'axe-report.json'), `${JSON.stringify(report, null, 2)}\n`);
  console.log(
    `a11y: ${report.summary.runs} runs, ${report.summary.violations} violations, ` +
      `${report.summary.unreachable} unreachable, ${report.summary.incomplete} incomplete ` +
      `(${report.summary.incompleteRules.join(', ') || '-'}), ${reloads} reloads, ` +
      `${Math.round(report.durationMs / 1000)} s, Commit ${report.commit}`,
  );
  process.exit(failed.length ? 1 : 0);
}

await main();
