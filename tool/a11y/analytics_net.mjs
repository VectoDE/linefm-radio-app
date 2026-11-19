// Netzpruefung "Reichweitenmessung mit Google" (P31, Consent Mode v2).
//
// Prueft im echten Web-Build (nach flutter build web, fetch_font_fallback und
// Postbuild), dass Google erst nach Zustimmung geladen wird:
//   --mode none  Build ohne GTM_ID/GA4_MEASUREMENT_ID: kein Dialog, keine
//                einzige Anfrage an Google, Consent-Standard trotzdem "denied".
//   --mode ids   Build mit Test-IDs (GTM-TEST000, G-TEST000000):
//                 1. vor der Zustimmung keine Anfrage an Google, axe im Dialog 0,
//                 2. "Ablehnen" -> weiterhin keine Anfrage, auch nach Neuladen,
//                 3. "Erlauben" -> gtm.js wird angefordert (im Test abgefangen
//                    und verworfen, es geht nichts ins Netz), nach Neuladen
//                    sofort wieder (gespeicherte Zustimmung).
// Jede Anfrage an Google-Hosts wird abgebrochen, bevor sie das Netz erreicht.
//
// Aufruf:
//   node analytics_net.mjs --web ../../build/web --mode none
//   node analytics_net.mjs --web ../../build/web_ga --mode ids
// Exit 1 bei jedem Verstoss.

import { createReadStream, existsSync, statSync } from 'node:fs';
import { createServer } from 'node:http';
import { extname, join, normalize, resolve, sep } from 'node:path';
import { parseArgs } from 'node:util';

import AxeBuilder from '@axe-core/playwright';
import { chromium } from 'playwright';

const { values: args } = parseArgs({
  options: {
    web: { type: 'string', default: '../../build/web' },
    mode: { type: 'string', default: 'none' },
  },
});
if (!['none', 'ids'].includes(args.mode)) {
  console.error('--mode muss none oder ids sein');
  process.exit(64);
}

const WEB = resolve(args.web);
const GOOGLE = /(^|\.)(google|googletagmanager|google-analytics|googleapis|gstatic|doubleclick|googlesyndication|googleadservices)\.[a-z.]+$/i;
const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff2': 'font/woff2',
  '.txt': 'text/plain; charset=utf-8',
  '.webmanifest': 'application/manifest+json',
  '.bin': 'application/octet-stream',
};

function serve(root) {
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
    res.writeHead(200, { 'Content-Type': MIME[extname(path)] ?? 'application/octet-stream', 'Cache-Control': 'no-cache' });
    createReadStream(path).pipe(res);
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

const failures = [];
function check(ok, msg) {
  console.log(`${ok ? 'OK    ' : 'FEHLER'} ${msg}`);
  if (!ok) failures.push(msg);
}

/** Neuer Kontext; jede Anfrage an Google wird notiert und verworfen. */
async function newContext(browser) {
  const context = await browser.newContext({ locale: 'de-DE', viewport: { width: 390, height: 844 }, serviceWorkers: 'block' });
  const google = [];
  await context.route('**/*', (route) => {
    const url = new URL(route.request().url());
    if (GOOGLE.test(url.hostname)) {
      google.push(url.href);
      return route.abort();
    }
    if (url.hostname !== '127.0.0.1') return route.abort(); // laut.fm usw.: hier unnoetig
    return route.continue();
  });
  return { context, google };
}

async function boot(page, base) {
  await page.goto(base, { waitUntil: 'load' });
  await page.waitForSelector('flt-semantics-placeholder, flt-semantics', { state: 'attached', timeout: 90_000 });
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 3, null, { timeout: 30_000 });
}

/** Consent-Standard steht in der Datenschicht, bevor irgendetwas geladen wird. */
async function defaultDenied(page) {
  return page.evaluate(() =>
    (window.dataLayer || []).some(
      (e) => e && e[0] === 'consent' && e[1] === 'default' && e[2] && e[2].analytics_storage === 'denied' && e[2].ad_storage === 'denied',
    ),
  );
}

const dialog = (page) => page.getByRole('alertdialog', { name: 'Reichweitenmessung mit Google' });
const button = (page, name) => dialog(page).getByRole('button', { name });

async function main() {
  const server = await serve(WEB);
  const base = `http://127.0.0.1:${server.address().port}/`;
  const browser = await chromium.launch();
  try {
    if (args.mode === 'none') {
      const { context, google } = await newContext(browser);
      const page = await context.newPage();
      await boot(page, base);
      await page.waitForTimeout(6000);
      check(await defaultDenied(page), 'Consent-Standard "denied" in der Datenschicht');
      check((await dialog(page).count()) === 0, 'ohne IDs kein Google-Dialog');
      check(google.length === 0, `ohne IDs keine Anfrage an Google (${google.length}: ${google.join(', ')})`);
      await context.close();
    } else {
      // Ablehnen
      {
        const { context, google } = await newContext(browser);
        const page = await context.newPage();
        await boot(page, base);
        await dialog(page).waitFor({ state: 'attached', timeout: 30_000 });
        await page.waitForTimeout(3000);
        check(await defaultDenied(page), 'Consent-Standard "denied" vor der Wahl');
        // Barrierefreiheit des Dialogs (gleiche Regeln wie run.mjs).
        const axe = await new AxeBuilder({ page })
          .withTags(['wcag2a', 'wcag2aa', 'wcag2aaa', 'wcag21a', 'wcag21aa', 'wcag22aa', 'best-practice'])
          .analyze();
        check(
          axe.violations.length === 0,
          `axe im Google-Dialog: ${axe.violations.length} Verstoesse ${axe.violations.map((v) => v.id).join(', ')}`,
        );
        check(google.length === 0, `vor der Zustimmung keine Anfrage an Google (${google.join(', ')})`);
        await button(page, 'Ablehnen').evaluate((el) => el.click());
        await page.waitForTimeout(3000);
        check(google.length === 0, `nach "Ablehnen" keine Anfrage an Google (${google.join(', ')})`);
        await boot(page, base);
        await page.waitForTimeout(4000);
        check((await dialog(page).count()) === 0, 'nach "Ablehnen" und Neuladen kein erneuter Dialog');
        check(google.length === 0, `nach "Ablehnen" und Neuladen keine Anfrage (${google.join(', ')})`);
        await context.close();
      }
      // Erlauben
      {
        const { context, google } = await newContext(browser);
        const page = await context.newPage();
        await boot(page, base);
        await dialog(page).waitFor({ state: 'attached', timeout: 30_000 });
        check(google.length === 0, 'vor "Erlauben" keine Anfrage an Google');
        const gtm = page.waitForRequest((r) => r.url().startsWith('https://www.googletagmanager.com/gtm.js?id=GTM-TEST000'), {
          timeout: 15_000,
        });
        await button(page, 'Erlauben').evaluate((el) => el.click());
        check(await gtm.then(() => true, () => false), 'nach "Erlauben" wird gtm.js angefordert (abgefangen)');
        const update = await page.evaluate(() =>
          (window.dataLayer || []).some((e) => e && e[0] === 'consent' && e[1] === 'update' && e[2]?.analytics_storage === 'granted'),
        );
        check(update, 'Consent-Update analytics_storage=granted vor dem Laden');
        const adsGranted = await page.evaluate(() =>
          (window.dataLayer || []).some((e) => e && e[0] === 'consent' && e[2] && (e[2].ad_storage === 'granted' || e[2].ad_user_data === 'granted')),
        );
        check(!adsGranted, 'Werbe-Kategorien bleiben abgelehnt');
        const before = google.length;
        const again = page.waitForRequest((r) => r.url().includes('googletagmanager.com/gtm.js'), { timeout: 30_000 });
        await page.reload({ waitUntil: 'load' });
        check(await again.then(() => true, () => false), 'gespeicherte Zustimmung: nach Neuladen wieder geladen');
        await page.waitForTimeout(1000); // Route-Handler laeuft nach dem request-Ereignis
        check(google.length > before, 'zweite Anfrage abgefangen');
        check(google.every((u) => /^https:\/\/www\.googletagmanager\.com\//.test(u)), `nur googletagmanager.com angefragt (${[...new Set(google)].join(', ')})`);
        await context.close();
      }
    }
  } finally {
    await browser.close();
    server.close();
  }
  console.log(failures.length === 0 ? 'Netzpruefung: alles in Ordnung' : `Netzpruefung: ${failures.length} Verstoesse`);
  process.exit(failures.length === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
