// Before/after table for the hosting configuration: Lighthouse against a stock nginx
// (default settings: no compression, no cache headers) versus the project's server
// (deploy/traefik image: gzip, cache rules, ETag). Both runs serve the same web build.
//
//   node hosting_compare.mjs --before out/lighthouse-baseline --after out/lighthouse --out out/hosting-compare.md
//
// Reads the summary.json files written by lighthouse.mjs. Reports only, never fails on a value.

import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { parseArgs } from 'node:util';

const { values: args } = parseArgs({
  options: {
    before: { type: 'string' },
    after: { type: 'string' },
    out: { type: 'string', default: 'out/hosting-compare.md' },
  },
});

const load = (dir) => JSON.parse(readFileSync(join(resolve(dir), 'summary.json'), 'utf8'));
const before = load(args.before);
const after = load(args.after);

const ms = (v) => (v == null ? 'n/a' : `${Math.round(v)} ms`);
const mb = (v) => (v == null ? 'n/a' : `${(v / 1024 / 1024).toFixed(2)} MB`);
const score = (v) => (v == null ? 'n/a' : String(Math.round(v)));
const delta = (b, a) => {
  if (b == null || a == null || b === 0) return 'n/a';
  const pct = ((a - b) / b) * 100;
  return `${pct > 0 ? '+' : ''}${pct.toFixed(0)} %`;
};

const rows = [
  ['Performance score', (s) => s.scores.performance.median, score],
  ['First Contentful Paint', (s) => s.metrics['first-contentful-paint'].median, ms],
  ['Largest Contentful Paint', (s) => s.metrics['largest-contentful-paint'].median, ms],
  ['Total Blocking Time', (s) => s.metrics['total-blocking-time'].median, ms],
  ['Speed Index', (s) => s.metrics['speed-index'].median, ms],
  ['Transferred (first load)', (s) => s.metrics['total-byte-weight'].median, mb],
];

const lines = [
  '### Hosting before/after (Lighthouse medians)',
  '',
  `Before: stock nginx, no compression, no cache headers. After: deploy/traefik image. ${after.runs} runs per profile, same build, same runner.`,
  '',
];
for (const profile of Object.keys(after.stats)) {
  const b = before.stats[profile];
  const a = after.stats[profile];
  if (!b || !a) continue;
  lines.push(`**${profile}**`, '', '| Metric | Before | After | Change |', '|---|---|---|---|');
  for (const [label, get, fmt] of rows) {
    const vb = get(b);
    const va = get(a);
    lines.push(`| ${label} | ${fmt(vb)} | ${fmt(va)} | ${delta(vb, va)} |`);
  }
  lines.push('');
}
const text = lines.join('\n');
writeFileSync(resolve(args.out), text);
console.log(text);
