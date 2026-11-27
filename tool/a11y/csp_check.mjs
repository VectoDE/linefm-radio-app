// CSP check of the web version: serves build/web with the Content-Security-Policy
// of the rendered nginx snippet (build/hosting/nginx/snippets/linefm-headers.conf),
// starts the app in Chromium and fails on any CSP violation or console error that
// mentions the policy. Also fails if the app does not render (no flutter-view) or
// if style-src still allows 'unsafe-inline'.
//
// Usage (after flutter build web, fetch_font_fallback and postbuild):
//   cd tool/a11y && npm ci && npx playwright install --with-deps chromium
//   node csp_check.mjs --web ../../build/web --hosting ../../build/hosting

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

/** CSP from the rendered nginx snippet (add_header Content-Security-Policy "..."). */
function nginxCsp() {
  const file = join(resolve(args.hosting), 'nginx', 'snippets', 'linefm-headers.conf');
  const match = readFileSync(file, 'utf8').match(/add_header\s+Content-Security-Policy\s+"([^"]+)"/);
  if (!match) throw new Error(`no Content-Security-Policy in ${file}`);
  // upgrade-insecure-requests would rewrite the http://127.0.0.1 test server.
  return match[1]
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

const csp = nginxCsp();
const styleSrc = csp.split('; ').find((d) => d.startsWith('style-src ')) ?? '';
const problems = [];
if (styleSrc.includes("'unsafe-inline'")) problems.push(`style-src still allows 'unsafe-inline': ${styleSrc}`);
if (!/'nonce-[A-Za-z0-9+/=]+'/.test(styleSrc)) problems.push(`style-src has no nonce: ${styleSrc}`);

const server = await serve(WEB, csp);
const base = `http://127.0.0.1:${server.address().port}/`;
const browser = await chromium.launch();
try {
  const page = await browser.newPage();
  const console_ = [];
  page.on('console', (m) => console_.push(`[${m.type()}] ${m.text()}`));
  page.on('pageerror', (e) => console_.push(`[pageerror] ${e.message}`));
  // Skip the start button of the static shell and record violations from the start.
  await page.addInitScript(() => {
    window.__cspViolations = [];
    document.addEventListener('securitypolicyviolation', (e) =>
      window.__cspViolations.push(`${e.effectiveDirective} ${e.blockedURI || 'inline'}`),
    );
    try {
      localStorage.setItem('linefm.started', '1');
    } catch {
      // Storage blocked: the shell then waits for a click, which the check reports.
    }
  });
  await page.goto(base, { waitUntil: 'load' });
  try {
    await page.waitForSelector('flutter-view', { state: 'attached', timeout: 60000 });
  } catch {
    problems.push('app did not render (no flutter-view within 60 s)');
  }
  // Let the first frames and lazy style elements settle.
  await page.waitForTimeout(5000);
  const violations = await page.evaluate(() => window.__cspViolations);
  for (const v of violations) problems.push(`CSP violation: ${v}`);
  for (const line of console_) {
    if (/Content Security Policy|Refused to/i.test(line)) problems.push(`console: ${line}`);
  }
  console.log(`style-src: ${styleSrc}`);
  console.log(`CSP violations: ${violations.length}`);
} finally {
  await browser.close();
  server.close();
}

if (problems.length > 0) {
  for (const p of problems) console.error(`::error::${p}`);
  process.exit(1);
}
console.log('CSP check passed: no violations, app rendered.');
