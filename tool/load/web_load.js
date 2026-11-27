// Load test for the static web build (k6).
//
// Runs only in CI (workflow load.yml) against the web build served on
// localhost with Cloudflare Pages semantics. Each virtual user loads the
// app shell and its start-up assets like a first visit, then repeats the
// shell request like a returning visitor (conditional request via ETag).
//
// Environment:
//   BASE_URL  target, default http://127.0.0.1:8788
//   PEAK_VUS  peak virtual users, default 200
//   STARTUP_PATHS  comma-separated start-up files of a first visit
import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE = __ENV.BASE_URL || 'http://127.0.0.1:8788';
const PEAK = parseInt(__ENV.PEAK_VUS || '200', 10);

// Files every first visit fetches before the app paints.
// The wasm build has hashed names, so the workflow passes them in STARTUP_PATHS.
const STARTUP = (__ENV.STARTUP_PATHS || '/flutter_bootstrap.js,/manifest.webmanifest')
  .split(',')
  .filter((p) => p);

export const options = {
  scenarios: {
    visitors: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: Math.round(PEAK / 4) },
        { duration: '30s', target: PEAK },
        { duration: '2m', target: PEAK },
        { duration: '30s', target: 0 },
      ],
      gracefulRampDown: '15s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{kind:shell}': ['p(95)<1000'],
    'http_req_duration{kind:asset}': ['p(95)<3000'],
    checks: ['rate>0.99'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  let etag;
  group('first visit', () => {
    const shell = http.get(`${BASE}/`, { tags: { kind: 'shell' } });
    check(shell, {
      'shell 200': (r) => r.status === 200,
      'shell is html': (r) => String(r.headers['Content-Type'] || '').includes('text/html'),
    });
    etag = shell.headers.Etag || shell.headers.ETag;
    const assets = http.batch(
      STARTUP.map((p) => ['GET', `${BASE}${p}`, null, { tags: { kind: 'asset' } }]),
    );
    assets.forEach((r) => check(r, { 'asset 200': (x) => x.status === 200 }));
  });
  sleep(1 + Math.random() * 2);
  group('return visit', () => {
    const headers = etag ? { 'If-None-Match': etag } : {};
    const again = http.get(`${BASE}/`, { headers, tags: { kind: 'shell' } });
    check(again, { 'return 200/304': (r) => r.status === 200 || r.status === 304 });
  });
  sleep(1 + Math.random() * 2);
}
