// axe-Pruefung der Web-Version (A4).
//
// Aufruf (nach flutter build web, fetch_font_fallback und Postbuild):
//   cd tool/a11y && npm ci && npx playwright install --with-deps chromium
//   node run.mjs --web ../../build/web --out out
//
// Ablauf: kleiner statischer Server auf 127.0.0.1 fuer build/web, Chromium per
// Playwright, Flutter-Semantik einschalten (der Zugriffsbaum entsteht erst
// dann), Ansicht ansteuern, axe-core mit WCAG 2.0 bis 2.2 (A, AA, AAA) und Best
// Practices laufen lassen. Ansichten: Sender, Player (nur schmal, breit ist er
// in die Senderliste eingebettet), Verlauf, Favoriten, Einstellungen, Wecker,
// Ueber, Dialog "Speicher loeschen"; je 390 und 1280 px, hell und dunkel. Dazu
// Impressum und Datenschutz (de/en) als statische Seiten.
//
// Ergebnis: out/axe-report.json (mit Commit-SHA), Screenshots je Ansicht.
// Exit 1, sobald ein Verstoss mit impact "serious" oder "critical" auftritt
// oder eine Ansicht nicht erreichbar ist.

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
  },
});

const WEB = resolve(args.web);
const OUT = resolve(args.out);
const TAGS = ['wcag2a', 'wcag2aa', 'wcag2aaa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice'];
const GATE = new Set(['serious', 'critical']);
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
    return 'unbekannt';
  }
}

/** Statischer Server wie die Hosting-Ziele: Ordner -> index.html, Pfade ohne Endung -> SPA. */
function serve(root) {
  const server = createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    let path = normalize(join(root, decodeURIComponent(url.pathname)));
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

/** Flutter-Semantik einschalten und warten, bis der Zugriffsbaum steht. */
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

/**
 * Tippen auf einen Semantik-Knoten (Rolle + Name), wie ein Screenreader.
 * Flutter legt nur Knoten im sichtbaren Bereich an; fehlt das Ziel, wird der
 * Inhalt mit dem Mausrad weiterbewegt.
 */
async function activate(page, role, name) {
  const roles = Array.isArray(role) ? role : [role];
  const target = roles
    .map((r) => page.getByRole(r, { name }))
    .reduce((a, b) => a.or(b))
    .first();
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

/** Struktur fuer den Bericht: h1, Landmarks. */
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
 * Erwartete h1 je Ansicht: belegt, dass die Navigation wirklich dort angekommen
 * ist (sonst wuerde axe die Startseite doppelt pruefen). null = keine h1
 * erwartet (Player schmal: der Sendername ist die Hauptinformation).
 */
const EXPECT_H1 = {
  sender: /^ALLE SENDER$/i,
  verlauf: /^ZULETZT GESPIELT$/i,
  favoriten: /^FAVORITEN$/i,
  einstellungen: /^EINSTELLUNGEN$/i,
  wecker: /^WECKER$/i,
  ueber: /^ÜBER LINEFM RADIO$/i,
  player: null,
};

/** Ansichten der App: Name -> Schritte ab Startseite (Sender). */
function appViews(wide) {
  // Schmal: untere Leiste (Sender, Player, Verlauf) plus Kopf (Favoriten,
  // Einstellungen). Breit: Navigationsleiste links mit Tabs.
  const nav = ['button', 'tab'];
  const views = {
    sender: [],
    verlauf: [[nav, /^Verlauf$/i]],
    favoriten: [[nav, /^Favoriten$/i]],
    einstellungen: [[nav, /^Einstellungen$/i]],
    wecker: [
      [nav, /^Einstellungen$/i],
      ['button', /^Wecker/],
    ],
    ueber: [
      [nav, /^Einstellungen$/i],
      ['button', /^Über LINEFM Radio/],
    ],
    'dialog-speicher-loeschen': [
      [nav, /^Einstellungen$/i],
      ['button', /^Speicher löschen$/],
    ],
  };
  if (!wide) views.player = [['button', /^Player$/]];
  return views;
}

async function main() {
  if (!existsSync(join(WEB, 'index.html'))) {
    console.error(`a11y: ${WEB}/index.html fehlt (zuerst flutter build web)`);
    process.exit(2);
  }
  mkdirSync(OUT, { recursive: true });
  const server = await serve(WEB);
  const base = `http://127.0.0.1:${server.address().port}`;
  const browser = await chromium.launch();
  const results = [];
  const only = args.only ? new Set(args.only.split(',')) : null;

  async function check(page, entry) {
    const axe = await new AxeBuilder({ page }).withTags(TAGS).analyze();
    const violations = axe.violations.map((v) => ({
      id: v.id,
      impact: v.impact,
      help: v.help,
      nodes: v.nodes.length,
      targets: v.nodes.slice(0, 5).map((n) => n.target.join(' ')),
    }));
    const shot = `${entry.kind}-${entry.theme}-${entry.layout}-${entry.view}.png`;
    await page.screenshot({ path: join(OUT, shot) });
    const s = await structure(page);
    results.push({ ...entry, screenshot: shot, axeVersion: axe.testEngine.version, ...s, violations });
    const gate = violations.filter((v) => GATE.has(v.impact)).length;
    console.log(
      `${gate ? 'FEHLER' : 'ok    '} ${entry.theme} ${entry.layout} ${entry.view}: ` +
        `${violations.length} Verstoesse (${gate} serious/critical), h1=${JSON.stringify(s.h1)}`,
    );
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
        for (const [view, steps] of Object.entries(appViews(wide))) {
          if (only && !only.has(view)) continue;
          const page = await context.newPage();
          const entry = { kind: 'app', theme, layout: size.name, width: size.width, view, url: '/' };
          try {
            await page.goto(`${base}/`, { waitUntil: 'load' });
            await enableSemantics(page);
            for (const [role, name] of steps) await activate(page, role, name);
            if (view.startsWith('dialog')) {
              await page
                .locator('[role="dialog"], [role="alertdialog"]')
                .first()
                .waitFor({ state: 'attached', timeout: 10_000 });
            }
            if (view in EXPECT_H1) {
              const { h1 } = await structure(page);
              const want = EXPECT_H1[view];
              const ok = want === null ? h1.length === 0 : h1.length === 1 && want.test(h1[0]);
              if (!ok) throw new Error(`Ansicht nicht erreicht: h1=${JSON.stringify(h1)}, erwartet ${want ?? 'keine'}`);
            }
            await check(page, entry);
          } catch (error) {
            const nodes = await page
              .evaluate(() =>
                [...document.querySelectorAll('flt-semantics[role], flt-semantics [role]')]
                  .map((e) => `${e.getAttribute('role')}:${(e.getAttribute('aria-label') || e.textContent || '').trim().slice(0, 40)}`)
                  .slice(0, 80),
              )
              .catch(() => []);
            results.push({ ...entry, error: String(error).split('\n')[0], semanticsNodes: nodes });
            console.log(`FEHLER ${theme} ${size.name} ${view}: nicht erreichbar (${String(error).split('\n')[0]})`);
          }
          await page.close();
        }
        for (const url of ['/impressum/', '/datenschutz/', '/impressum/en/', '/datenschutz/en/']) {
          const view = url.replaceAll('/', '-').replace(/^-|-$/g, '');
          if (only && !only.has(view)) continue;
          const page = await context.newPage();
          await page.goto(`${base}${url}`, { waitUntil: 'load' });
          await check(page, { kind: 'legal', theme, layout: size.name, width: size.width, view, url });
          await page.close();
        }
        await context.close();
      }
    }
  } finally {
    await browser.close();
    server.close();
  }

  const failed = results.filter((r) => r.error || r.violations.some((v) => GATE.has(v.impact)));
  const report = {
    commit: commitSha(),
    generated: new Date().toISOString(),
    tool: { playwright: (await import('playwright/package.json', { with: { type: 'json' } })).default.version },
    tags: TAGS,
    gate: 'keine Verstoesse mit impact serious oder critical, jede Ansicht erreichbar',
    summary: {
      runs: results.length,
      failed: failed.length,
      violations: results.reduce((n, r) => n + (r.violations?.length ?? 0), 0),
      seriousOrCritical: results.reduce(
        (n, r) => n + (r.violations?.filter((v) => GATE.has(v.impact)).length ?? 0),
        0,
      ),
    },
    results,
  };
  writeFileSync(join(OUT, 'axe-report.json'), `${JSON.stringify(report, null, 2)}\n`);
  console.log(
    `a11y: ${report.summary.runs} Laeufe, ${report.summary.violations} Verstoesse, ` +
      `${report.summary.seriousOrCritical} serious/critical, Commit ${report.commit}`,
  );
  process.exit(failed.length ? 1 : 0);
}

await main();
