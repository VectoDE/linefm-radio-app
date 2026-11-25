// Quality gate for the public web deploy.
//
//   node pagespeed_gate.mjs --url https://vectode.github.io/linefm-radio-app/ --out out/gate
//
// Source of the scores:
// - PAGESPEED_API_KEY set: PageSpeed Insights API (mobile and desktop, one call each,
//   the same lab engine as pagespeed.web.dev, run from Google's infrastructure).
// - otherwise: summary.json written by lighthouse.mjs (median of N local runs on the
//   runner), passed with --lighthouse-summary.
//
// Thresholds follow the performance standard: performance >= --min-performance
// (default 95), accessibility, best practices and SEO >= --min-other (default 100).
// --report-only (competitor comparison) records scores without failing.
// Exit code 1 if any category in any profile is below its threshold.

import { appendFileSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { parseArgs } from 'node:util';

const { values: args } = parseArgs({
  options: {
    url: { type: 'string' },
    out: { type: 'string', default: 'out/gate' },
    'lighthouse-summary': { type: 'string', default: '' },
    'min-performance': { type: 'string', default: '95' },
    'min-other': { type: 'string', default: '100' },
    'report-only': { type: 'boolean', default: false },
    name: { type: 'string', default: '' },
  },
});

const CATEGORIES = ['performance', 'accessibility', 'best-practices', 'seo'];
const PROFILES = ['mobile', 'desktop'];
const minPerf = Number(args['min-performance']);
const minOther = Number(args['min-other']);
const OUT = resolve(args.out);

async function fromPageSpeed(url, key) {
  const result = {};
  for (const strategy of PROFILES) {
    const q = new URLSearchParams({ url, strategy, key });
    for (const c of CATEGORIES) q.append('category', c);
    const res = await fetch(`https://www.googleapis.com/pagespeedonline/v5/runPagespeed?${q}`);
    const body = await res.json();
    if (!res.ok) throw new Error(`PageSpeed API ${strategy}: HTTP ${res.status} ${body?.error?.message ?? ''}`);
    writeFileSync(join(OUT, `${args.name ? `${args.name}-` : ''}pagespeed-${strategy}.json`), JSON.stringify(body, null, 2));
    const cats = body.lighthouseResult.categories;
    result[strategy] = Object.fromEntries(CATEGORIES.map((c) => [c, cats[c]?.score == null ? null : Math.round(cats[c].score * 100)]));
  }
  return result;
}

function fromLighthouse(path) {
  const summary = JSON.parse(readFileSync(path, 'utf8'));
  const result = {};
  for (const profile of PROFILES) {
    const s = summary.stats?.[profile];
    result[profile] = Object.fromEntries(CATEGORIES.map((c) => [c, s?.scores?.[c]?.median ?? null]));
  }
  return result;
}

async function main() {
  if (!args.url) throw new Error('--url is required');
  mkdirSync(OUT, { recursive: true });
  const key = process.env.PAGESPEED_API_KEY ?? '';
  let source;
  let scores;
  if (key) {
    source = 'PageSpeed Insights API';
    scores = await fromPageSpeed(args.url, key);
  } else {
    if (!args['lighthouse-summary']) throw new Error('No PAGESPEED_API_KEY and no --lighthouse-summary given');
    source = 'Lighthouse on the runner (median, PAGESPEED_API_KEY not set)';
    scores = fromLighthouse(resolve(args['lighthouse-summary']));
  }

  const failures = [];
  const rows = [];
  for (const profile of PROFILES) {
    for (const c of CATEGORIES) {
      const min = c === 'performance' ? minPerf : minOther;
      const v = scores[profile][c];
      const ok = v !== null && v >= min;
      if (!ok) failures.push(`${profile} ${c}: ${v ?? 'n/a'} < ${min}`);
      rows.push(`| ${profile} | ${c} | ${v ?? 'n/a'} | ${min} | ${ok ? 'pass' : 'FAIL'} |`);
    }
  }
  const md = [
    `### Web quality gate (${args.url})`,
    `Source: ${source}`,
    '',
    '| Profile | Category | Score | Minimum | Result |',
    '| --- | --- | --- | --- | --- |',
    ...rows,
    '',
  ].join('\n');
  writeFileSync(join(OUT, `${args.name ? `${args.name}-` : ''}gate.json`), JSON.stringify({ url: args.url, source, scores, minPerf, minOther, failures }, null, 2));
  writeFileSync(join(OUT, `${args.name ? `${args.name}-` : ''}gate.md`), md);
  if (process.env.GITHUB_STEP_SUMMARY) appendFileSync(process.env.GITHUB_STEP_SUMMARY, md);
  console.log(md);
  if (failures.length && !args['report-only']) {
    console.error(`Gate failed:\n${failures.join('\n')}`);
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(String(e?.stack ?? e));
  process.exit(1);
});
