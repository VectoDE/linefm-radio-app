// Lighthouse-Laeufe: je Profil (mobil, desktop) N Laeufe gegen
// den lokal ausgelieferten Web-Build, simuliertes Throttling (Standard).
//
//   node lighthouse.mjs --url http://127.0.0.1:8080/ --out out/lighthouse --runs 5
//
// Browser: das Chromium von Playwright (gleicher Browser wie web_perf.mjs).
// Ergebnis: je Lauf <profil>-<n>.report.json/.html, dazu summary.json mit
// Median und Streuung je Kennzahl und Kategorie.

import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { parseArgs } from 'node:util';

import { chromium } from 'playwright';

import { environment, stats } from './lib.mjs';

const { values: args } = parseArgs({
  options: {
    url: { type: 'string', default: 'http://127.0.0.1:8080/' },
    out: { type: 'string', default: 'out/lighthouse' },
    runs: { type: 'string', default: '5' },
    profiles: { type: 'string', default: 'mobile,desktop' },
  },
});

const OUT = resolve(args.out);
const RUNS = Math.max(1, Number.parseInt(args.runs, 10) || 5);
const LH = resolve('node_modules/lighthouse/cli/index.js');

const METRICS = {
  'first-contentful-paint': 'FCP',
  'largest-contentful-paint': 'LCP',
  'total-blocking-time': 'TBT',
  'cumulative-layout-shift': 'CLS',
  'speed-index': 'Speed Index',
  'server-response-time': 'TTFB (Server)',
  'total-byte-weight': 'Gesamtgewicht',
  'mainthread-work-breakdown': 'Hauptthread',
  'bootup-time': 'JS-Ausfuehrung',
};

function extract(lhr) {
  const a = lhr.audits;
  const num = (id) => (a[id] && typeof a[id].numericValue === 'number' ? a[id].numericValue : null);
  const marks = (a['user-timings']?.details?.items ?? [])
    .filter((i) => i.timingType === 'Mark' && String(i.name).startsWith('linefm:'))
    .map((i) => [String(i.name).slice(7), i.startTime]);
  const failed = Object.values(lhr.categories)
    .flatMap((c) => c.auditRefs)
    .filter((r) => r.weight > 0 && a[r.id] && a[r.id].score !== null && a[r.id].score < 1)
    .map((r) => r.id);
  return {
    scores: Object.fromEntries(Object.entries(lhr.categories).map(([k, c]) => [k, c.score === null ? null : Math.round(c.score * 100)])),
    metrics: Object.fromEntries(Object.keys(METRICS).map((id) => [id, num(id)])),
    requests: a['network-requests']?.details?.items?.length ?? null,
    marks: Object.fromEntries(marks),
    failedAudits: [...new Set(failed)],
    lighthouseVersion: lhr.lighthouseVersion,
    benchmarkIndex: lhr.environment?.benchmarkIndex ?? null,
    userAgent: lhr.environment?.hostUserAgent ?? null,
    runWarnings: lhr.runWarnings ?? [],
  };
}

function main() {
  mkdirSync(OUT, { recursive: true });
  const chrome = chromium.executablePath();
  const profiles = args.profiles.split(',');
  const runs = [];
  for (const profile of profiles) {
    for (let i = 1; i <= RUNS; i++) {
      const base = join(OUT, `${profile}-${i}`);
      const cli = [
        LH,
        args.url,
        '--quiet',
        '--output=json',
        '--output=html',
        `--output-path=${base}`,
        '--only-categories=performance,accessibility,best-practices,seo',
        '--chrome-flags=--headless=new --no-sandbox --disable-dev-shm-usage',
        '--max-wait-for-load=90000',
      ];
      if (profile === 'desktop') cli.push('--preset=desktop');
      try {
        execFileSync(process.execPath, cli, { stdio: 'inherit', env: { ...process.env, CHROME_PATH: chrome }, timeout: 240_000 });
        const lhr = JSON.parse(readFileSync(`${base}.report.json`, 'utf8'));
        const r = { profile, run: i, ...extract(lhr) };
        runs.push(r);
        console.log(
          `${profile} ${i}: Perf ${r.scores.performance}, A11y ${r.scores.accessibility}, BP ${r.scores['best-practices']}, SEO ${r.scores.seo}, ` +
            `LCP ${Math.round(r.metrics['largest-contentful-paint'])} ms, TBT ${Math.round(r.metrics['total-blocking-time'])} ms`,
        );
      } catch (e) {
        runs.push({ profile, run: i, error: String(e?.message ?? e).slice(0, 300) });
        console.log(`${profile} ${i}: FEHLER ${String(e?.message ?? e).slice(0, 200)}`);
      }
    }
  }
  const agg = {};
  for (const profile of profiles) {
    const ok = runs.filter((r) => r.profile === profile && !r.error);
    if (!ok.length) continue;
    agg[profile] = {
      scores: Object.fromEntries(['performance', 'accessibility', 'best-practices', 'seo'].map((k) => [k, stats(ok.map((r) => r.scores[k]))])),
      metrics: Object.fromEntries(Object.keys(METRICS).map((k) => [k, stats(ok.map((r) => r.metrics[k]))])),
      requests: stats(ok.map((r) => r.requests)),
      firstFrameMark: stats(ok.map((r) => r.marks['first-frame'] ?? null)),
      failedAudits: [...new Set(ok.flatMap((r) => r.failedAudits))],
      benchmarkIndex: stats(ok.map((r) => r.benchmarkIndex)),
      lighthouseVersion: ok[0].lighthouseVersion,
    };
  }
  writeFileSync(
    join(OUT, 'summary.json'),
    JSON.stringify({ tool: 'tool/perf/lighthouse.mjs', url: args.url, runs: RUNS, environment: environment(), stats: agg, results: runs }, null, 2),
  );
  console.log(`lighthouse: ${join(OUT, 'summary.json')}`);
}

main();
