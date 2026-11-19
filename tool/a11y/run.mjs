// axe-Pruefung der Web-Version (A4).
//
// Aufruf (nach flutter build web, fetch_font_fallback und Postbuild):
//   cd tool/a11y && npm ci && npx playwright install --with-deps chromium
//   node run.mjs --web ../../build/web --out out
//
// Ablauf: kleiner statischer Server auf 127.0.0.1 fuer build/web, Chromium per
// Playwright, Flutter-Semantik einschalten (der Zugriffsbaum entsteht erst
// dann), Ansicht ansteuern, axe-core mit WCAG 2.0 bis 2.2 (A, AA, AAA) und Best
// Practices laufen lassen. Ansichten: Sender, Verlauf, Favoriten,
// Einstellungen, Dialog "Speicher loeschen", Wecker, Uhrzeit-Dialog des
// Weckers, Ueber, Player (nur schmal, breit ist er in die Senderliste
// eingebettet), Sheet "Sleeptimer" und Sheet "Favoriten exportieren"; je 390
// und 1280 px, hell und dunkel. Dazu Impressum und Datenschutz (de/en) als
// statische Seiten.
//
// Je Farbschema und Breite laedt die App einmal; zwischen den Ansichten geht es
// per Escape, "Zurueck" und Navigation zur Startseite zurueck (nur wenn das
// scheitert, wird neu geladen; der Bericht zaehlt das unter "reloads").
//
// Einwilligungsdialog (Statistik) nur mit --consent und einem eigenen Build mit
// Test-Umami-Werten, die nirgends hinfuehren (keine echten Daten):
//   flutter build web ... --dart-define=UMAMI_URL=http://127.0.0.1:9
//     --dart-define=UMAMI_WEBSITE_ID=00000000-0000-0000-0000-000000000000
//   node run.mjs --web ../../build/web --out out-consent --consent
// Anfragen an 127.0.0.1:9 werden zusaetzlich im Browser verworfen. Die CI
// baut nur ohne Telemetrie, dort erscheint der Dialog nicht.
//
// Ergebnis: out/axe-report.json (mit Commit-SHA, Laufzeit, "incomplete" =
// von axe nicht entscheidbare Pruefungen), Screenshots je Ansicht.
// Exit 1, sobald irgendein Verstoss auftritt (jede Stufe, Baseline 0) oder
// eine Ansicht nicht erreichbar ist. "incomplete" bricht nicht ab, steht aber
// in Bericht und Zusammenfassung.

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
    return 'unbekannt';
  }
}

/** Statischer Server wie die Hosting-Ziele: Ordner -> index.html, Pfade ohne Endung -> SPA. */
function serve(root) {
  const server = createServer((req, res) => {
    const url = new URL(req.url, 'http://x');
    let decoded;
    try {
      decoded = decodeURIComponent(url.pathname);
    } catch {
      // Kaputte Prozent-Kodierung (z. B. "%E0%A4%A"): Anfrage ablehnen statt abstuerzen.
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

/** Erster Knoten mit einer der Rollen und passendem Namen. */
function byRole(page, role, name) {
  const roles = Array.isArray(role) ? role : [role];
  return roles
    .map((r) => page.getByRole(r, { name }))
    .reduce((a, b) => a.or(b))
    .first();
}

/**
 * Tippen auf einen Semantik-Knoten (Rolle + Name), wie ein Screenreader.
 * Flutter legt nur Knoten im sichtbaren Bereich an; fehlt das Ziel, wird der
 * Inhalt mit dem Mausrad weiterbewegt.
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
 * Erwartung je Ansicht: entweder eine h1 (belegt, dass die Navigation dort
 * angekommen ist, sonst wuerde axe die Startseite doppelt pruefen; null = keine
 * h1, Player schmal) oder ein Dialog mit Rolle und zugaenglichem Namen.
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
  // Im Web nur Texteingabe (siehe timeEntryMode in alarm_screen.dart).
  'dialog-wecker-uhrzeit': { dialog: ['dialog', /^Uhrzeit eingeben$/] },
  'sheet-sleeptimer': { dialog: ['dialog', /^Sleeptimer$/] },
  'sheet-favoriten-export': { dialog: ['dialog', /^Favoriten exportieren$/] },
  'dialog-einwilligung': { dialog: ['alertdialog', /^Statistik und Fehlerberichte$/] },
};

/** Erwartete h1 der statischen Rechtsseiten. */
const LEGAL = {
  '/impressum/': /^Impressum$/,
  '/datenschutz/': /^Datenschutzerklärung$/,
  '/impressum/en/': /^Imprint$/,
  '/datenschutz/en/': /^Privacy policy$/,
};

/**
 * Ansichten der App: Name -> Schritte ab Startseite (Sender). Reihenfolge so,
 * dass moeglichst wenig zurueckgesetzt werden muss. `seed` = vorher Favoriten
 * in den Speicher legen (der Export erscheint nur mit Favoriten).
 */
function appViews(wide) {
  // Nur Einwilligung: erscheint beim Start eines Builds mit Telemetrie.
  if (args.consent) return [['dialog-einwilligung', []]];
  // Schmal: untere Leiste (Sender, Player, Verlauf) plus Kopf (Favoriten,
  // Einstellungen). Breit: Navigationsleiste links mit Tabs.
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
  // Breit steckt der Player in der Senderliste, schmal ist er ein eigener Bereich.
  views.push([
    'sheet-sleeptimer',
    wide ? [['button', /^Sleeptimer einstellen$/]] : [['button', /^Player$/], ['button', /^Sleeptimer einstellen$/]],
  ]);
  views.push([
    'sheet-favoriten-export',
    // Mit Favoriten heisst der Knopf im Kopf "Favoriten, 1 Song".
    [[nav, /^Favoriten(,|$)/i], ['button', /^Favoriten exportieren$/]],
    { seed: true },
  ]);
  return views;
}

/** Ein Favorit plus Speicher-Einwilligung im Format von shared_preferences (Web). */
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
    console.error(`a11y: ${WEB}/index.html fehlt (zuerst flutter build web)`);
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
      `${violations.length ? 'FEHLER' : 'ok    '} ${entry.theme} ${entry.layout} ${entry.view}: ` +
        `${violations.length} Verstoesse, ${incomplete.length} unentschieden, h1=${JSON.stringify(s.h1)}`,
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

  /** App frisch laden (erster Aufruf oder wenn das Zuruecksetzen scheitert). */
  async function boot(page) {
    await page.goto(`${base}/`, { waitUntil: 'load' });
    await enableSemantics(page);
  }

  /** Zurueck zur Startseite: Dialoge schliessen, Unterseiten verlassen, Sender waehlen. */
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
    if (!ok) throw new Error(`Ansicht nicht erreicht: h1=${JSON.stringify(h1)}, erwartet ${want.h1 ?? 'keine'}`);
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
        // Test-Umami (--consent) zeigt ins Leere; trotzdem nichts durchlassen.
        await context.route(/^https?:\/\/127\.0\.0\.1:9\//, (route) => route.abort());
        const page = await context.newPage();
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
            console.log(`FEHLER ${theme} ${size.name} ${view}: nicht erreichbar (${String(error).split('\n')[0]})`);
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
              throw new Error(`HTTP ${response?.status() ?? 'ohne Antwort'}`);
            }
            const h1 = await page.locator('h1').allInnerTexts();
            if (h1.length !== 1 || !h1Want.test(h1[0].trim())) {
              throw new Error(`h1=${JSON.stringify(h1)}, erwartet ${h1Want}`);
            }
            await check(page, entry, t0);
          } catch (error) {
            results.push({ ...entry, error: String(error).split('\n')[0] });
            console.log(`FEHLER ${theme} ${size.name} ${view}: ${String(error).split('\n')[0]}`);
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
    gate: 'kein Verstoss (jede Stufe, Baseline 0), jede Ansicht erreichbar; incomplete wird berichtet',
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
    `a11y: ${report.summary.runs} Laeufe, ${report.summary.violations} Verstoesse, ` +
      `${report.summary.unreachable} nicht erreichbar, ${report.summary.incomplete} unentschieden ` +
      `(${report.summary.incompleteRules.join(', ') || '-'}), ${reloads} Neuladungen, ` +
      `${Math.round(report.durationMs / 1000)} s, Commit ${report.commit}`,
  );
  process.exit(failed.length ? 1 : 0);
}

await main();
