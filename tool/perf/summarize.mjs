// Fasst die Messergebnisse (Issue #92) zu einer Markdown-Tabelle zusammen:
// Kennzahl | Median | Streuung | Ziel (= Median / 3 bei Zeiten) | Methode.
//
//   node summarize.mjs --in <ordner mit den Artefakten> --out perf-summary.md
//
// Liest, was vorhanden ist: web-perf.json, lighthouse/summary.json,
// sizes.json, windows-perf.json, android-sizes.json (beliebig tief im Ordner).
// Nur Node-Standardbibliothek.

import { existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { basename, join, resolve } from 'node:path';
import { parseArgs } from 'node:util';

import { stats } from './lib.mjs';

const { values: args } = parseArgs({
  options: {
    in: { type: 'string', default: 'out' },
    out: { type: 'string', default: 'perf-summary.md' },
    json: { type: 'string', default: '' },
  },
});

function find(dir, name) {
  if (!existsSync(dir)) return null;
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) {
      const hit = find(p, name);
      if (hit) return hit;
    } else if (entry === name && (name !== 'summary.json' || basename(dir) === 'lighthouse')) {
      return p;
    }
  }
  return null;
}

const load = (name) => {
  const p = find(resolve(args.in), name);
  return p ? JSON.parse(readFileSync(p, 'utf8')) : null;
};

const web = load('web-perf.json');
const lh = load('summary.json');
const sizes = load('sizes.json');
const win = load('windows-perf.json');
const android = load('android-sizes.json');

const de = (x, digits = 0) => (x === null || x === undefined || Number.isNaN(x) ? '–' : x.toLocaleString('de-DE', { maximumFractionDigits: digits, minimumFractionDigits: digits }));
const ms = (x) => (x === null || x === undefined ? '–' : x >= 1000 ? `${de(x / 1000, 2)} s` : `${de(x)} ms`);
const mb = (x) => (x === null || x === undefined ? '–' : `${de(x / 1e6, 2)} MB`);

const rows = [];
/** kind: time | bytes | score | cls | count | pct | mib */
function row(area, name, s, kind, method, link) {
  if (!s || !s.n) {
    rows.push({ area, name, median: 'nicht gemessen', spread: '–', target: '–', method, link, raw: null });
    return;
  }
  const f = { time: ms, bytes: mb, score: (x) => de(x), cls: (x) => de(x, 3), count: (x) => de(x), pct: (x) => `${de(x, 1)} %`, mib: (x) => `${de(x, 1)} MB` }[kind];
  const target = { time: ms(s.median / 3), bytes: mb(s.median / 3), score: '100', cls: '≤ 0,1 (Ziel ≤ 0,02)', count: '–', pct: '–', mib: '–' }[kind];
  rows.push({
    area,
    name,
    median: f(s.median),
    spread: s.n > 1 ? `${f(s.min)} – ${f(s.max)} (n=${s.n}, VK ${de(s.cv, 0)} %)` : `n=1`,
    target,
    method,
    link,
    raw: s,
  });
}

const webLink = web?.environment?.runUrl ?? null;
if (web) {
  const S = web.stats;
  for (const profile of ['mobile', 'desktop']) {
    const P = profile === 'mobile' ? 'Web mobil' : 'Web Desktop';
    const thr = profile === 'mobile' ? 'Playwright, Slow-4G + CPU 4x (DevTools-Drosselung)' : 'Playwright, ohne Drosselung';
    const c = S[`${profile}.cold`];
    const w = S[`${profile}.warm`];
    if (!c) continue;
    row(P, 'Erstes Flutter-Bild, Erstaufruf', c.firstFrame, 'time', `${thr}; Marke linefm:first-frame`, webLink);
    row(P, 'Bedienbar (Ruhe nach erstem Bild), Erstaufruf', c.interactive, 'time', `${thr}; Ende letzter Long Task vor 3 s Ruhe`, webLink);
    row(P, 'Statische Huelle weg (runApp fertig), Erstaufruf', c.shellHidden, 'time', thr, webLink);
    row(P, 'Dart main() startet, Erstaufruf', c.dartMain, 'time', `${thr}; Marke linefm:main`, webLink);
    row(P, 'FCP (statische Huelle), Erstaufruf', c.fcp, 'time', thr, webLink);
    row(P, 'LCP, Erstaufruf', c.lcp, 'time', thr, webLink);
    row(P, 'TBT bis bedienbar, Erstaufruf', c.tbt, 'time', `${thr}; Summe (Long Task − 50 ms)`, webLink);
    row(P, 'Laengster Long Task, Erstaufruf', c.maxLongTask, 'time', thr, webLink);
    row(P, 'Uebertragen, Erstaufruf', c.bytes, 'bytes', `${thr}; CDP encodedDataLength`, webLink);
    row(P, 'Anfragen, Erstaufruf', c.requests, 'count', thr, webLink);
    if (w) {
      row(P, 'Erstes Flutter-Bild, wiederholter Aufruf (SW/Cache)', w.firstFrame, 'time', thr, webLink);
      row(P, 'Uebertragen, wiederholter Aufruf', w.bytes, 'bytes', thr, webLink);
    }
    for (const [key, v] of Object.entries(S)) {
      if (!key.startsWith(`${profile}.step.`)) continue;
      const step = key.slice(`${profile}.step.`.length);
      if (step.startsWith('Seitenwechsel')) {
        row(P, `${step}: Klick bis naechstes Bild`, v.inputToPaint, 'time', `${thr}; Event Timing (INP-Naeherung)`, webLink);
      }
      row(P, `${step}: Bilder > 33 ms`, v.over33, 'count', `${thr}; rAF-Abstaende in 1,5 s`, webLink);
      row(P, `${step}: laengstes Bild`, v.max, 'time', `${thr}; rAF-Abstaende in 1,5 s`, webLink);
    }
  }
  for (const [key, v] of Object.entries(S)) {
    if (!key.startsWith('audio.')) continue;
    const label = key.slice(6);
    row('Web Ton', `${label}: Klick bis Audio "playing"`, v.playing, 'time', `Playwright Desktop, echte laut.fm-Streams, ${v.ok}/${v.tried} Laeufe mit Ton`, webLink);
    row('Web Ton', `${label}: Klick bis Anzeige "spielt"`, v.markPlaying, 'time', 'Dart-Marke player-playing (mind. 1 s, minConnectDuration)', webLink);
  }
}

const lhLink = lh?.environment?.runUrl ?? null;
if (lh) {
  for (const profile of ['mobile', 'desktop']) {
    const s = lh.stats[profile];
    if (!s) continue;
    const P = profile === 'mobile' ? 'Lighthouse mobil' : 'Lighthouse Desktop';
    const m = `Lighthouse ${s.lighthouseVersion}, ${profile === 'mobile' ? 'Standard (simuliert)' : '--preset=desktop'}, ${lh.runs} Laeufe`;
    row(P, 'Performance', s.scores.performance, 'score', m, lhLink);
    row(P, 'Accessibility', s.scores.accessibility, 'score', m, lhLink);
    row(P, 'Best Practices', s.scores['best-practices'], 'score', m, lhLink);
    row(P, 'SEO', s.scores.seo, 'score', m, lhLink);
    row(P, 'FCP', s.metrics['first-contentful-paint'], 'time', m, lhLink);
    row(P, 'LCP', s.metrics['largest-contentful-paint'], 'time', m, lhLink);
    row(P, 'TBT', s.metrics['total-blocking-time'], 'time', m, lhLink);
    row(P, 'CLS', s.metrics['cumulative-layout-shift'], 'cls', m, lhLink);
    row(P, 'Speed Index', s.metrics['speed-index'], 'time', m, lhLink);
    row(P, 'TTFB (Server)', s.metrics['server-response-time'], 'time', m, lhLink);
    row(P, 'Gesamtgewicht', s.metrics['total-byte-weight'], 'bytes', m, lhLink);
    row(P, 'Hauptthread-Arbeit', s.metrics['mainthread-work-breakdown'], 'time', m, lhLink);
  }
}

const winLink = win?.environment?.runUrl ?? null;
if (win) {
  const runs = (win.results ?? []).filter((r) => !r.warmup);
  const m = (r, k) => r.marksMs?.[k] ?? null;
  const W = 'Windows';
  const meth = `windows-latest, Release mit LINEFM_PERF_MARKS, ${runs.length} Laeufe nach Aufwaermen`;
  row(W, 'Prozessstart bis Fenster sichtbar (= erstes Bild)', stats(runs.map((r) => r.windowVisibleMs)), 'time', `${meth}; EnumWindows/IsWindowVisible`, winLink);
  row(W, 'Prozessstart bis Dart main()', stats(runs.map((r) => m(r, 'main'))), 'time', meth, winLink);
  row(W, 'Prozessstart bis Audio bereit', stats(runs.map((r) => m(r, 'audio-ready'))), 'time', meth, winLink);
  row(W, 'Prozessstart bis Fenster/Tray/Hotkeys bereit', stats(runs.map((r) => m(r, 'desktop-ready'))), 'time', meth, winLink);
  row(W, 'Prozessstart bis runApp', stats(runs.map((r) => m(r, 'run-app'))), 'time', meth, winLink);
  row(W, 'Prozessstart bis erstes Bild gerastert (Dart)', stats(runs.map((r) => m(r, 'first-frame'))), 'time', meth, winLink);
  row(W, 'Working Set nach 30 s Leerlauf', stats(runs.map((r) => r.idleWorkingSetMB)), 'mib', meth, winLink);
  row(W, 'Private Bytes nach 30 s Leerlauf', stats(runs.map((r) => r.idlePrivateMB)), 'mib', meth, winLink);
  row(W, 'CPU im Leerlauf (% eines Kerns, 10 s)', stats(runs.map((r) => r.idleCpuPct)), 'pct', meth, winLink);
  const audio = runs.flatMap((r) => r.audio ?? []);
  for (const [slug, label] of [['linefmrap', 'erster Sender'], ['linefmlofi', 'Senderwechsel']]) {
    const a = audio.filter((x) => x.station === slug && String(x.endState).startsWith('player-playing'));
    row(W, `Ton (${label}): Anforderung bis Zustand "spielt"`, stats(a.map((x) => x.requestToEndMs)), 'time', `${meth}; Deep Link per zweitem Start, ${a.length}/${audio.filter((x) => x.station === slug).length} erreicht`, winLink);
    row(W, `Ton (${label}): CPU beim Abspielen`, stats(a.map((x) => x.playingCpuPct)), 'pct', meth, winLink);
  }
  if (win.package) {
    row(W, 'Release-Ordner', stats([win.package.releaseBytes]), 'bytes', 'build/windows/x64/runner/Release', winLink);
    row(W, 'ZIP', stats([win.package.zipBytes]), 'bytes', 'Compress-Archive wie build.yml', winLink);
  }
}

if (android) {
  const L = android.environment?.runUrl ?? null;
  row('Android', 'APK arm64 (Release)', stats([android.apkArm64Bytes]), 'bytes', 'flutter build apk --target-platform android-arm64 --analyze-size', L);
  row('Android', 'AAB (Release)', stats([android.aabBytes]), 'bytes', 'flutter build appbundle', L);
}

if (sizes) {
  const g = sizes.groups;
  for (const name of ['main.dart.wasm', 'main.dart.mjs', 'skwasm (Wasm-Renderer)', 'Schriften (App)', 'Bilder']) {
    if (g[name]) row('Web-Build', `${name} (roh)`, stats([g[name].bytes]), 'bytes', 'Dateigroesse build/web', null);
  }
  const startFiles = sizes.detail.filter((f) => /^main\..*\.(wasm|mjs)$/.test(f.path) || /skwasm\.(wasm|js)$/.test(f.path));
  const sum = (k) => startFiles.reduce((a, f) => a + f[k], 0);
  if (startFiles.length) {
    row('Web-Build', 'Startdateien Wasm-Weg gzip-5 (wie nginx)', stats([sum('gzip5')]), 'bytes', startFiles.map((f) => f.path).join(', '), null);
    row('Web-Build', 'Startdateien Wasm-Weg Brotli-11 (vorkomprimiert)', stats([sum('brotli11')]), 'bytes', 'Vergleich, nicht ausgeliefert', null);
  }
}

const env = web?.environment ?? lh?.environment ?? win?.environment ?? {};
const lines = [];
lines.push('## Performance-Ausgangswerte (#92)');
lines.push('');
lines.push(`Commit \`${env.commit ?? '?'}\`${env.runUrl ? `, Lauf ${env.runUrl}` : ''}.`);
if (web) lines.push(`Web: ${web.environment.runner.os} ${web.environment.runner.image ?? ''} ${web.environment.runner.imageVersion ?? ''}, ${web.environment.cpu.model} (${web.environment.cpu.cores} Kerne), Node ${web.environment.node}, Chromium von Playwright, Server: nginx-Container aus deploy/traefik (gzip 5, Cache-Header aus deploy/nginx/snippets), HTTP/1.1 ohne TLS.`);
if (win) lines.push(`Windows: ${win.environment.os}, ${win.environment.cpu.model} (${win.environment.cpu.cores} Kerne), ${win.environment.memGiB} GiB.`);
lines.push('');
lines.push('Ziel = Median / 3 (Vorgabe: dreimal so schnell). Streuung = Minimum – Maximum, n, Variationskoeffizient. Labor-Werte, keine Felddaten.');
lines.push('');
lines.push('| Bereich | Kennzahl | Median | Streuung | Ziel | Messmethode |');
lines.push('|---|---|---|---|---|---|');
for (const r of rows) {
  lines.push(`| ${r.area} | ${r.name} | ${r.median} | ${r.spread} | ${r.target} | ${r.method}${r.link ? ` ([Lauf](${r.link}))` : ''} |`);
}
if (lh) {
  for (const profile of ['mobile', 'desktop']) {
    const s = lh.stats[profile];
    if (s?.failedAudits?.length) lines.push('', `Lighthouse ${profile}, nicht bestandene Audits (mind. ein Lauf): ${s.failedAudits.map((a) => `\`${a}\``).join(', ')}`);
  }
}
if (web) {
  const cold = web.results.load.find((r) => !r.error)?.cold;
  if (cold) {
    lines.push('', `Renderer im Erstaufruf (desktop/mobil, erster Lauf): ${cold.network.renderer}. Unkomprimiert ausgelieferte Dateien > 1 KB: ${cold.network.uncompressed.length ? cold.network.uncompressed.join(', ') : 'keine'}.`);
    lines.push('', 'Uebertragung je Dateiart (erster Lauf, Erstaufruf):', '', '| Art | Anfragen | Bytes |', '|---|---|---|');
    for (const [k, v] of Object.entries(cold.network.byCategory)) lines.push(`| ${k} | ${v.requests} | ${mb(v.bytes)} |`);
  }
  const errors = [...web.results.load, ...web.results.interaction, ...web.results.audio].filter((r) => r.error);
  if (errors.length) lines.push('', `Fehlgeschlagene Web-Laeufe: ${errors.length} (${[...new Set(errors.map((e) => e.error.slice(0, 120)))].join(' | ')})`);
}
writeFileSync(resolve(args.out), `${lines.join('\n')}\n`);
if (args.json) writeFileSync(resolve(args.json), JSON.stringify(rows, null, 2));
console.log(lines.join('\n'));
