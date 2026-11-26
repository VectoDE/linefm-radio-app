// Summarizes the measurement results into a Markdown table:
// metric | median | spread | target (= median / 3 for times) | method.
//
//   node summarize.mjs --in <folder with the artifacts> --out perf-summary.md
//
// Reads whatever is present: web-perf.json, lighthouse/summary.json,
// sizes.json, windows-perf.json, android-sizes.json (at any depth in the folder).
// Node standard library only.

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

const de = (x, digits = 0) => (x === null || x === undefined || Number.isNaN(x) ? '–' : x.toLocaleString('en-US', { maximumFractionDigits: digits, minimumFractionDigits: digits }));
const ms = (x) => (x === null || x === undefined ? '–' : x >= 1000 ? `${de(x / 1000, 2)} s` : `${de(x)} ms`);
const mb = (x) => (x === null || x === undefined ? '–' : `${de(x / 1e6, 2)} MB`);

const rows = [];
/** kind: time | bytes | score | cls | count | pct | mib */
function row(area, name, s, kind, method, link) {
  if (!s || !s.n) {
    rows.push({ area, name, median: 'not measured', spread: '–', target: '–', method, link, raw: null });
    return;
  }
  const f = { time: ms, bytes: mb, score: (x) => de(x), cls: (x) => de(x, 3), count: (x) => de(x), pct: (x) => `${de(x, 1)} %`, mib: (x) => `${de(x, 1)} MB` }[kind];
  const target = { time: ms(s.median / 3), bytes: mb(s.median / 3), score: '100', cls: '≤ 0.1 (target ≤ 0.02)', count: '–', pct: '–', mib: '–' }[kind];
  rows.push({
    area,
    name,
    median: f(s.median),
    spread: s.n > 1 ? `${f(s.min)} – ${f(s.max)} (n=${s.n}, CV ${de(s.cv, 0)} %)` : `n=1`,
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
    const P = profile === 'mobile' ? 'Web mobile' : 'Web Desktop';
    const thr = profile === 'mobile' ? 'Playwright, slow 4G + CPU 4x (DevTools throttling)' : 'Playwright, no throttling';
    const c = S[`${profile}.cold`];
    const w = S[`${profile}.warm`];
    if (!c) continue;
    row(P, 'First Flutter frame, first visit', c.firstFrame, 'time', `${thr}; mark linefm:first-frame`, webLink);
    row(P, 'Interactive (idle after first frame), first visit', c.interactive, 'time', `${thr}; end of last long task before 3 s idle`, webLink);
    row(P, 'Static shell gone (runApp done), first visit', c.shellHidden, 'time', thr, webLink);
    row(P, 'Dart main() starts, first visit', c.dartMain, 'time', `${thr}; mark linefm:main`, webLink);
    row(P, 'FCP (static shell), first visit', c.fcp, 'time', thr, webLink);
    row(P, 'LCP, first visit', c.lcp, 'time', thr, webLink);
    row(P, 'TBT until interactive, first visit', c.tbt, 'time', `${thr}; sum (long task − 50 ms)`, webLink);
    row(P, 'Longest long task, first visit', c.maxLongTask, 'time', thr, webLink);
    row(P, 'Transferred, first visit', c.bytes, 'bytes', `${thr}; CDP encodedDataLength`, webLink);
    row(P, 'Requests, first visit', c.requests, 'count', thr, webLink);
    if (w) {
      row(P, 'First Flutter frame, repeat visit (SW/cache)', w.firstFrame, 'time', thr, webLink);
      row(P, 'Transferred, repeat visit', w.bytes, 'bytes', thr, webLink);
    }
    for (const [key, v] of Object.entries(S)) {
      if (!key.startsWith(`${profile}.step.`)) continue;
      const step = key.slice(`${profile}.step.`.length);
      if (step.startsWith('Page change')) {
        row(P, `${step}: click to next frame`, v.inputToPaint, 'time', `${thr}; Event Timing (INP approximation)`, webLink);
      }
      row(P, `${step}: frames > 33 ms`, v.over33, 'count', `${thr}; rAF gaps in 1.5 s`, webLink);
      row(P, `${step}: longest frame`, v.max, 'time', `${thr}; rAF gaps in 1.5 s`, webLink);
    }
  }
  for (const [key, v] of Object.entries(S)) {
    if (!key.startsWith('audio.')) continue;
    const label = key.slice(6);
    row('Web audio', `${label}: click to audio "playing"`, v.playing, 'time', `Playwright desktop, real laut.fm streams, ${v.ok}/${v.tried} runs with audio`, webLink);
    row('Web audio', `${label}: click to display "playing"`, v.markPlaying, 'time', 'Dart mark player-playing (at least 1 s, minConnectDuration)', webLink);
  }
}

const lhLink = lh?.environment?.runUrl ?? null;
if (lh) {
  for (const profile of ['mobile', 'desktop']) {
    const s = lh.stats[profile];
    if (!s) continue;
    const P = profile === 'mobile' ? 'Lighthouse mobile' : 'Lighthouse desktop';
    const m = `Lighthouse ${s.lighthouseVersion}, ${profile === 'mobile' ? 'default (simulated)' : '--preset=desktop'}, ${lh.runs} runs`;
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
    row(P, 'Total weight', s.metrics['total-byte-weight'], 'bytes', m, lhLink);
    row(P, 'Main-thread work', s.metrics['mainthread-work-breakdown'], 'time', m, lhLink);
  }
}

const winLink = win?.environment?.runUrl ?? null;
if (win) {
  const runs = (win.results ?? []).filter((r) => !r.warmup);
  const m = (r, k) => r.marksMs?.[k] ?? null;
  const W = 'Windows';
  const meth = `windows-latest, Release mit LINEFM_PERF_MARKS, ${runs.length} runs after warm-up`;
  row(W, 'Process start to window visible (= first frame)', stats(runs.map((r) => r.windowVisibleMs)), 'time', `${meth}; EnumWindows/IsWindowVisible`, winLink);
  row(W, 'Process start to Dart main()', stats(runs.map((r) => m(r, 'main'))), 'time', meth, winLink);
  row(W, 'Process start to audio ready', stats(runs.map((r) => m(r, 'audio-ready'))), 'time', meth, winLink);
  row(W, 'Process start to window/tray/hotkeys ready', stats(runs.map((r) => m(r, 'desktop-ready'))), 'time', meth, winLink);
  row(W, 'Process start to runApp', stats(runs.map((r) => m(r, 'run-app'))), 'time', meth, winLink);
  row(W, 'Process start to first frame rasterized (Dart)', stats(runs.map((r) => m(r, 'first-frame'))), 'time', meth, winLink);
  row(W, 'Working set after 30 s idle', stats(runs.map((r) => r.idleWorkingSetMB)), 'mib', meth, winLink);
  row(W, 'Private bytes after 30 s idle', stats(runs.map((r) => r.idlePrivateMB)), 'mib', meth, winLink);
  row(W, 'CPU at idle (% of one core, 10 s)', stats(runs.map((r) => r.idleCpuPct)), 'pct', meth, winLink);
  const audio = runs.flatMap((r) => r.audio ?? []);
  for (const [slug, label] of [['linefmrap', 'first station'], ['linefmlofi', 'station switch']]) {
    const a = audio.filter((x) => x.station === slug && String(x.endState).startsWith('player-playing'));
    row(W, `Audio (${label}): request to state "playing"`, stats(a.map((x) => x.requestToEndMs)), 'time', `${meth}; deep link via second launch, ${a.length}/${audio.filter((x) => x.station === slug).length} reached`, winLink);
    row(W, `Audio (${label}): CPU during playback`, stats(a.map((x) => x.playingCpuPct)), 'pct', meth, winLink);
  }
  if (win.package) {
    row(W, 'Release folder', stats([win.package.releaseBytes]), 'bytes', 'build/windows/x64/runner/Release', winLink);
    row(W, 'ZIP', stats([win.package.zipBytes]), 'bytes', 'Compress-Archive as in build.yml', winLink);
  }
}

if (android) {
  const L = android.environment?.runUrl ?? null;
  row('Android', 'APK arm64 (Release)', stats([android.apkArm64Bytes]), 'bytes', 'flutter build apk --target-platform android-arm64 --analyze-size', L);
  row('Android', 'AAB (Release)', stats([android.aabBytes]), 'bytes', 'flutter build appbundle', L);
}

if (sizes) {
  const g = sizes.groups;
  for (const name of ['main.dart.wasm', 'main.dart.mjs', 'skwasm (Wasm renderer)', 'Fonts (app)', 'Images']) {
    if (g[name]) row('Web build', `${name} (raw)`, stats([g[name].bytes]), 'bytes', 'File size build/web', null);
  }
  const startFiles = sizes.detail.filter((f) => /^main\..*\.(wasm|mjs)$/.test(f.path) || /skwasm\.(wasm|js)$/.test(f.path));
  const sum = (k) => startFiles.reduce((a, f) => a + f[k], 0);
  if (startFiles.length) {
    row('Web build', 'Startup files, Wasm path, gzip-5 (like nginx)', stats([sum('gzip5')]), 'bytes', startFiles.map((f) => f.path).join(', '), null);
    row('Web build', 'Startup files, Wasm path, Brotli-11 (precompressed)', stats([sum('brotli11')]), 'bytes', 'comparison, not shipped', null);
  }
}

const env = web?.environment ?? lh?.environment ?? win?.environment ?? {};
const lines = [];
lines.push('## Performance baseline');
lines.push('');
lines.push(`Commit \`${env.commit ?? '?'}\`${env.runUrl ? `, run ${env.runUrl}` : ''}.`);
if (web) lines.push(`Web: ${web.environment.runner.os} ${web.environment.runner.image ?? ''} ${web.environment.runner.imageVersion ?? ''}, ${web.environment.cpu.model} (${web.environment.cpu.cores} cores), Node ${web.environment.node}, Playwright's Chromium, server: nginx container from deploy/traefik (gzip 5, cache headers from deploy/nginx/snippets), HTTP/1.1 without TLS.`);
if (win) lines.push(`Windows: ${win.environment.os}, ${win.environment.cpu.model} (${win.environment.cpu.cores} cores), ${win.environment.memGiB} GiB.`);
lines.push('');
lines.push('Target = median / 3 (requirement: three times as fast). Spread = minimum – maximum, n, coefficient of variation. Lab values, not field data.');
lines.push('');
lines.push('| Area | Metric | Median | Spread | Target | Method |');
lines.push('|---|---|---|---|---|---|');
for (const r of rows) {
  lines.push(`| ${r.area} | ${r.name} | ${r.median} | ${r.spread} | ${r.target} | ${r.method}${r.link ? ` ([run](${r.link}))` : ''} |`);
}
if (lh) {
  for (const profile of ['mobile', 'desktop']) {
    const s = lh.stats[profile];
    if (s?.failedAudits?.length) lines.push('', `Lighthouse ${profile}, failed audits (at least one run): ${s.failedAudits.map((a) => `\`${a}\``).join(', ')}`);
  }
}
if (web) {
  const cold = web.results.load.find((r) => !r.error)?.cold;
  if (cold) {
    lines.push('', `Renderer on first visit (desktop/mobile, first run): ${cold.network.renderer}. Files served uncompressed > 1 KB: ${cold.network.uncompressed.length ? cold.network.uncompressed.join(', ') : 'none'}.`);
    lines.push('', 'Transfer per file type (first run, first visit):', '', '| Type | Requests | Bytes |', '|---|---|---|');
    for (const [k, v] of Object.entries(cold.network.byCategory)) lines.push(`| ${k} | ${v.requests} | ${mb(v.bytes)} |`);
  }
  const errors = [...web.results.load, ...web.results.interaction, ...web.results.audio].filter((r) => r.error);
  if (errors.length) lines.push('', `Failed web runs: ${errors.length} (${[...new Set(errors.map((e) => e.error.slice(0, 120)))].join(' | ')})`);
}
writeFileSync(resolve(args.out), `${lines.join('\n')}\n`);
if (args.json) writeFileSync(resolve(args.json), JSON.stringify(rows, null, 2));
console.log(lines.join('\n'));
