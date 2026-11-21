// Web-Messung mit Playwright (Issue #92): Laden kalt/warm, Bedienung, Ton.
//
// Aufruf (Server mit Kompression und Cache-Headern wie in deploy/ laeuft,
// z. B. der nginx-Container aus deploy/traefik/Dockerfile):
//   cd tool/perf && npm ci --ignore-scripts && npx playwright install --with-deps chromium
//   node web_perf.mjs --base http://127.0.0.1:8080 --out out --runs 5 [--audio]
//
// Profile:
//   mobile  412x823, DPR 1.75, CPU 4x langsamer, Netz wie Lighthouse "Slow 4G"
//           (DevTools-Drosselung: 562,5 ms Latenz, 1474,56 kbit/s runter, 675 hoch)
//   desktop 1350x940, DPR 1, ohne Drosselung
// Je Profil und Lauf ein frischer Browser-Kontext (leerer Cache):
//   1. Kaltstart: TTFB, FCP, LCP, CLS, Long Tasks, Flutter-Marken
//      (linefm:main ... linefm:first-frame, nur mit LINEFM_PERF_MARKS=true
//      gebaut), Event "flutter-first-frame", Zeitpunkt, an dem die statische
//      Huelle verschwindet, Uebertragung je Dateiart.
//   2. Warmstart: Service Worker aktiv, Seite neu laden, dieselben Werte.
//   3. Bedienung (eigener Kontext, Speicher-Hinweis bestaetigt, Autoplay aus):
//      Seitenwechsel und Scrollen per Mausklick auf Koordinaten, die vorab
//      ueber die Flutter-Semantik ermittelt wurden. Die Messlaeufe selbst
//      laufen OHNE eingeschaltete Semantik (die kostet Zeit). Gemessen:
//      Bildabstaende (requestAnimationFrame), Long Tasks, Event Timing
//      (Dauer vom Klick bis zum naechsten Bild, INP-Naeherung).
//   4. Ton (nur --audio, nur desktop): Klick auf Sender A bis "playing" am
//      Audio-Element, danach Wechsel auf Sender B. Wenige Einzelmessungen
//      gegen die echten laut.fm-Streams, kein Dauerabruf.
//
// Ergebnis: <out>/web-perf.json (Rohwerte je Lauf und Statistik).

import { mkdirSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { parseArgs } from 'node:util';

import { chromium } from 'playwright';

import { environment, stats } from './lib.mjs';

const { values: args } = parseArgs({
  options: {
    base: { type: 'string', default: 'http://127.0.0.1:8080' },
    out: { type: 'string', default: 'out' },
    runs: { type: 'string', default: '5' },
    profiles: { type: 'string', default: 'mobile,desktop' },
    audio: { type: 'boolean', default: false },
  },
});

const BASE = args.base.replace(/\/$/, '');
const OUT = resolve(args.out);
const RUNS = Math.max(1, Number.parseInt(args.runs, 10) || 5);

const PROFILES = {
  mobile: {
    viewport: { width: 412, height: 823 },
    deviceScaleFactor: 1.75,
    isMobile: true,
    hasTouch: true,
    cpu: 4,
    net: { latency: 562.5, downKbps: 1474.56, upKbps: 675 },
  },
  desktop: {
    viewport: { width: 1350, height: 940 },
    deviceScaleFactor: 1,
    isMobile: false,
    hasTouch: false,
    cpu: 1,
    net: null,
  },
};

const STATION_A = { slug: 'linefmrap', name: /\+RAP/ };
const STATION_B = { slug: 'linefmlofi', name: /\+LOFI/ };

// Laeuft vor jedem Skript der Seite.
const INIT = () => {
  const p = {
    fcp: null,
    lcp: null,
    cls: 0,
    longtasks: [],
    loaf: [],
    events: [],
    frames: [],
    media: [],
    ffEvent: null,
    shellHidden: null,
  };
  window.__perf = p;
  const obs = (type, fn, extra = {}) => {
    try {
      new PerformanceObserver((list) => list.getEntries().forEach(fn)).observe({ type, buffered: true, ...extra });
    } catch {
      /* Typ nicht unterstuetzt */
    }
  };
  obs('paint', (e) => {
    if (e.name === 'first-contentful-paint') p.fcp = e.startTime;
  });
  obs('largest-contentful-paint', (e) => {
    p.lcp = e.startTime;
  });
  obs('layout-shift', (e) => {
    if (!e.hadRecentInput) p.cls += e.value;
  });
  obs('longtask', (e) => p.longtasks.push({ start: e.startTime, dur: e.duration }));
  obs('long-animation-frame', (e) =>
    p.loaf.push({ start: e.startTime, dur: e.duration, blocking: e.blockingDuration }),
  );
  obs(
    'event',
    (e) =>
      p.events.push({
        name: e.name,
        start: e.startTime,
        dur: e.duration,
        input: e.processingStart - e.startTime,
        processing: e.processingEnd - e.processingStart,
        id: e.interactionId,
      }),
    { durationThreshold: 16 },
  );
  window.addEventListener('flutter-first-frame', () => {
    if (p.ffEvent === null) p.ffEvent = performance.now();
  });
  const loop = (t) => {
    p.frames.push(t);
    requestAnimationFrame(loop);
  };
  requestAnimationFrame(loop);
  document.addEventListener('DOMContentLoaded', () => {
    const shell = document.getElementById('static-shell');
    if (!shell) return;
    new MutationObserver(() => {
      if (shell.hidden && p.shellHidden === null) p.shellHidden = performance.now();
    }).observe(shell, { attributes: true });
  });
  // Audio-Elemente (just_audio im Web) beobachten: src-Setter und play().
  const tracked = new WeakSet();
  const push = (ev, el) => p.media.push({ ev, t: performance.now(), src: el.currentSrc || el.getAttribute('src') || '' });
  const track = (el) => {
    if (tracked.has(el)) return;
    tracked.add(el);
    for (const ev of ['loadstart', 'loadedmetadata', 'canplay', 'waiting', 'playing', 'pause', 'stalled', 'error']) {
      el.addEventListener(ev, () => push(ev, el));
    }
  };
  const desc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
  if (desc?.set) {
    Object.defineProperty(HTMLMediaElement.prototype, 'src', {
      ...desc,
      set(v) {
        track(this);
        desc.set.call(this, v);
        p.media.push({ ev: 'src', t: performance.now(), src: String(v) });
      },
    });
  }
  const play = HTMLMediaElement.prototype.play;
  HTMLMediaElement.prototype.play = function (...a) {
    track(this);
    push('play()', this);
    return play.apply(this, a);
  };
};

// Fuer Bedienung und Ton: Speicher-Hinweis bestaetigt, Autoplay aus (sonst
// startet der erste Klick den zuletzt gewaehlten Sender, siehe
// PlayerController.onUserInteraction).
const SEED = () => {
  try {
    if (localStorage.getItem('flutter.linefm-storage-notice-dismissed') === null) {
      localStorage.setItem('flutter.linefm-storage-notice-dismissed', 'true');
      localStorage.setItem('flutter.linefm-setting-autoplay', 'false');
    }
  } catch {
    /* ohne Speicher */
  }
};

async function newContext(browser, profile, { seed = false } = {}) {
  const pr = PROFILES[profile];
  const context = await browser.newContext({
    viewport: pr.viewport,
    deviceScaleFactor: pr.deviceScaleFactor,
    isMobile: pr.isMobile,
    hasTouch: pr.hasTouch,
    serviceWorkers: 'allow',
  });
  await context.addInitScript(INIT);
  if (seed) await context.addInitScript(SEED);
  const page = await context.newPage();
  const cdp = await context.newCDPSession(page);
  await cdp.send('Network.enable');
  if (pr.net) {
    await cdp.send('Network.emulateNetworkConditions', {
      offline: false,
      latency: pr.net.latency,
      downloadThroughput: (pr.net.downKbps * 1024) / 8,
      uploadThroughput: (pr.net.upKbps * 1024) / 8,
    });
  }
  if (pr.cpu > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: pr.cpu });
  return { context, page, cdp };
}

/** Netzmitschnitt ueber CDP: Bytes auf der Leitung je Anfrage. */
function recordNetwork(cdp) {
  const reqs = new Map();
  const onResponse = (e) => {
    const r = reqs.get(e.requestId) ?? {};
    reqs.set(e.requestId, {
      ...r,
      url: e.response.url,
      status: e.response.status,
      mime: e.response.mimeType,
      encoding: e.response.headers['content-encoding'] ?? e.response.headers['Content-Encoding'] ?? '',
      fromSW: !!e.response.fromServiceWorker,
      fromCache: !!e.response.fromDiskCache,
    });
  };
  const onFinished = (e) => {
    const r = reqs.get(e.requestId);
    if (r) r.bytes = e.encodedDataLength;
  };
  cdp.on('Network.responseReceived', onResponse);
  cdp.on('Network.loadingFinished', onFinished);
  return {
    stop() {
      cdp.off('Network.responseReceived', onResponse);
      cdp.off('Network.loadingFinished', onFinished);
      return [...reqs.values()].filter((r) => r.url && !r.url.startsWith('data:'));
    },
  };
}

function category(url) {
  const path = new URL(url).pathname;
  if (/main\.[0-9a-f]+\.dart\.wasm$/.test(path) || /main\.dart\.wasm$/.test(path)) return 'main.dart.wasm';
  if (/main\.[0-9a-f]+\.dart\.mjs$/.test(path) || /main\.dart\.mjs$/.test(path)) return 'main.dart.mjs';
  if (/main\.[0-9a-f]+\.dart\.js$/.test(path) || /main\.dart\.js$/.test(path)) return 'main.dart.js';
  if (path.includes('/canvaskit/')) return path.includes('skwasm') ? 'skwasm' : 'canvaskit';
  if (/\.(ttf|otf|woff2?)$/.test(path) || path.includes('/fonts/')) return 'fonts';
  if (/\.(png|jpe?g|webp|avif|gif|svg)$/.test(path)) return 'images';
  if (new URL(url).origin !== new URL(BASE).origin) return 'extern';
  return 'other';
}

function summarizeNetwork(list) {
  const own = list.filter((r) => new URL(r.url).origin === new URL(BASE).origin);
  const by = {};
  for (const r of list) {
    const c = category(r.url);
    by[c] ??= { requests: 0, bytes: 0 };
    by[c].requests += 1;
    by[c].bytes += r.bytes ?? 0;
  }
  return {
    requests: list.length,
    requestsOwn: own.length,
    bytes: list.reduce((a, r) => a + (r.bytes ?? 0), 0),
    bytesOwn: own.reduce((a, r) => a + (r.bytes ?? 0), 0),
    byCategory: by,
    renderer: list.some((r) => category(r.url) === 'skwasm')
      ? 'skwasm'
      : list.some((r) => category(r.url) === 'canvaskit')
        ? 'canvaskit'
        : 'unbekannt',
    uncompressed: own
      .filter((r) => /\.(wasm|mjs|js|json|html|ttf|otf)$/.test(new URL(r.url).pathname) && !r.encoding && (r.bytes ?? 0) > 1024)
      .map((r) => new URL(r.url).pathname),
  };
}

/** Wartet auf das erste Flutter-Bild (Dart-Marke oder Engine-Event), max. 120 s. */
async function waitFirstFrame(page) {
  await page.waitForFunction(
    () =>
      window.__perf?.ffEvent !== null ||
      performance.getEntriesByName('linefm:first-frame').length > 0 ||
      window.__perf?.shellHidden !== null,
    null,
    { timeout: 120_000, polling: 50 },
  );
}

/** Wartet, bis 3 s lang kein Long Task mehr kam (hoechstens 25 s). */
async function waitQuiet(page) {
  const until = Date.now() + 25_000;
  while (Date.now() < until) {
    const idle = await page.evaluate(() => {
      const lt = window.__perf.longtasks;
      const last = lt.length ? lt[lt.length - 1].start + lt[lt.length - 1].dur : 0;
      return performance.now() - last;
    });
    if (idle >= 3000) return;
    await page.waitForTimeout(250);
  }
}

async function loadMetrics(page) {
  return page.evaluate(() => {
    const p = window.__perf;
    const nav = performance.getEntriesByType('navigation')[0];
    const marks = Object.fromEntries(
      performance
        .getEntriesByType('mark')
        .filter((m) => m.name.startsWith('linefm:'))
        .map((m) => [m.name.slice(7), m.startTime]),
    );
    const firstFrame = marks['first-frame'] ?? p.ffEvent ?? p.shellHidden;
    // Bedienbar (TTI-Naeherung): Ende des letzten Long Tasks vor einer
    // Ruhephase von 3 s, fruehestens das erste Flutter-Bild.
    let quiet = firstFrame ?? 0;
    for (const t of p.longtasks) {
      const end = t.start + t.dur;
      if (end > quiet && t.start < quiet + 3000) quiet = end;
    }
    const tbtFrom = p.fcp ?? 0;
    const tbt = p.longtasks
      .filter((t) => t.start >= tbtFrom && t.start <= quiet)
      .reduce((a, t) => a + Math.max(0, t.dur - 50), 0);
    return {
      ttfb: nav ? nav.responseStart : null,
      domContentLoaded: nav ? nav.domContentLoadedEventEnd : null,
      load: nav ? nav.loadEventEnd : null,
      fcp: p.fcp,
      lcp: p.lcp,
      cls: p.cls,
      dartMain: marks.main ?? null,
      runApp: marks['run-app'] ?? null,
      firstFrameMark: marks['first-frame'] ?? null,
      flutterFirstFrameEvent: p.ffEvent,
      shellHidden: p.shellHidden,
      firstFrame,
      interactive: quiet,
      tbt,
      longTasks: p.longtasks.length,
      longTaskMs: p.longtasks.reduce((a, t) => a + t.dur, 0),
      maxLongTask: p.longtasks.reduce((a, t) => Math.max(a, t.dur), 0),
      marks,
      hardwareConcurrency: navigator.hardwareConcurrency,
      wasmGC: typeof WebAssembly !== 'undefined',
    };
  });
}

async function measureLoad(browser, profile, run) {
  const { context, page, cdp } = await newContext(browser, profile);
  const result = { profile, run };
  try {
    let net = recordNetwork(cdp);
    await page.goto(`${BASE}/`, { waitUntil: 'load', timeout: 120_000 });
    await waitFirstFrame(page);
    await waitQuiet(page);
    result.cold = { ...(await loadMetrics(page)), network: summarizeNetwork(net.stop()) };

    // Warmstart: Service Worker abwarten, dann neu laden.
    const sw = await page
      .evaluate(
        () =>
          'serviceWorker' in navigator
            ? Promise.race([
                navigator.serviceWorker.ready.then(() => true),
                new Promise((ok) => setTimeout(() => ok(false), 15_000)),
              ])
            : false,
      )
      .catch(() => false);
    net = recordNetwork(cdp);
    await page.reload({ waitUntil: 'load', timeout: 120_000 });
    await waitFirstFrame(page);
    await waitQuiet(page);
    result.warm = {
      serviceWorker: sw,
      controlled: await page.evaluate(() => !!navigator.serviceWorker?.controller),
      ...(await loadMetrics(page)),
      network: summarizeNetwork(net.stop()),
    };
  } catch (e) {
    result.error = String(e?.message ?? e).slice(0, 500);
  } finally {
    await context.close();
  }
  return result;
}

/** Koordinaten der Ziele ueber die Flutter-Semantik (einmal je Profil). */
async function discoverTargets(browser, profile) {
  const { context, page } = await newContext(browser, profile, { seed: true });
  try {
    await page.goto(`${BASE}/`, { waitUntil: 'load', timeout: 120_000 });
    await waitFirstFrame(page);
    await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 60_000 });
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    await page.waitForFunction(() => document.querySelectorAll('flt-semantics').length > 10, null, { timeout: 30_000 });
    await page.waitForTimeout(1500);
    const nodes = await page.evaluate(() =>
      [...document.querySelectorAll('flt-semantics')]
        .map((el) => {
          const r = el.getBoundingClientRect();
          return {
            role: el.getAttribute('role') ?? '',
            name: (el.getAttribute('aria-label') || el.textContent || '').trim().slice(0, 80),
            x: r.x + r.width / 2,
            y: r.y + r.height / 2,
            w: r.width,
            h: r.height,
          };
        })
        .filter((n) => n.w > 0 && n.h > 0 && n.name),
    );
    const find = (re, roles = ['button', 'tab']) => nodes.find((n) => roles.includes(n.role) && re.test(n.name)) ?? null;
    return {
      nodes: nodes.slice(0, 120),
      targets: {
        verlauf: find(/^Verlauf$/i),
        favoriten: find(/^Favoriten/i),
        einstellungen: find(/^Einstellungen$/i),
        sender: find(/^Sender$/i),
        stationA: find(STATION_A.name, ['button']),
        stationB: find(STATION_B.name, ['button']),
      },
    };
  } finally {
    await context.close();
  }
}

function frameStats(frames, from, to) {
  const f = frames.filter((t) => t >= from && t <= to);
  const d = [];
  for (let i = 1; i < f.length; i++) d.push(f[i] - f[i - 1]);
  d.sort((a, b) => a - b);
  const q = (x) => (d.length ? d[Math.min(d.length - 1, Math.floor(x * d.length))] : null);
  return {
    frames: d.length,
    p50: q(0.5),
    p95: q(0.95),
    max: d.length ? d[d.length - 1] : null,
    over17: d.filter((x) => x > 17.5).length,
    over33: d.filter((x) => x > 34).length,
    over50: d.filter((x) => x > 50).length,
  };
}

async function measureInteraction(browser, profile, run, targets) {
  const { context, page } = await newContext(browser, profile, { seed: true });
  const result = { profile, run, steps: [] };
  try {
    await page.goto(`${BASE}/`, { waitUntil: 'load', timeout: 120_000 });
    await waitFirstFrame(page);
    await waitQuiet(page);
    const size = PROFILES[profile].viewport;
    const steps = [
      ['Seitenwechsel Verlauf', 'click', targets.verlauf],
      ['Seitenwechsel Favoriten', 'click', targets.favoriten],
      ['Seitenwechsel Einstellungen', 'click', targets.einstellungen],
      ['Scrollen Einstellungen', 'scroll', null],
      ['Seitenwechsel Sender', 'click', targets.sender],
      ['Scrollen Senderliste', 'scroll', null],
    ];
    for (const [name, kind, target] of steps) {
      if (kind === 'click' && !target) {
        result.steps.push({ name, skipped: 'Ziel nicht gefunden' });
        continue;
      }
      const t0 = await page.evaluate(() => performance.now());
      if (kind === 'click') {
        await page.mouse.click(target.x, target.y);
      } else {
        await page.mouse.move(size.width / 2, size.height / 2);
        for (let i = 0; i < 6; i++) {
          await page.mouse.wheel(0, i < 3 ? 400 : -400);
          await page.waitForTimeout(120);
        }
      }
      await page.waitForTimeout(1500);
      const t1 = await page.evaluate(() => performance.now());
      const data = await page.evaluate(
        ([a, b]) => ({
          frames: window.__perf.frames.filter((t) => t >= a && t <= b),
          longtasks: window.__perf.longtasks.filter((t) => t.start >= a && t.start <= b),
          events: window.__perf.events.filter((e) => e.start >= a - 5 && e.start <= b),
        }),
        [t0, t1],
      );
      const clicks = data.events.filter((e) => ['pointerdown', 'pointerup', 'click', 'mousedown', 'mouseup'].includes(e.name));
      result.steps.push({
        name,
        ...frameStats(data.frames, t0, t1),
        longTasks: data.longtasks.length,
        longTaskMs: data.longtasks.reduce((a, t) => a + t.dur, 0),
        maxLongTask: data.longtasks.reduce((a, t) => Math.max(a, t.dur), 0),
        inputToPaint: clicks.length ? Math.max(...clicks.map((e) => e.dur)) : kind === 'click' ? 16 : null,
        eventTimingEntries: clicks.length,
      });
    }
  } catch (e) {
    result.error = String(e?.message ?? e).slice(0, 500);
  } finally {
    await context.close();
  }
  return result;
}

async function waitMedia(page, after, slug, timeout = 25_000) {
  try {
    await page.waitForFunction(
      ([a, s]) => window.__perf.media.some((m) => m.ev === 'playing' && m.t >= a && m.src.includes(s)),
      [after, slug],
      { timeout, polling: 20 },
    );
    return true;
  } catch {
    return false;
  }
}

async function measureAudio(browser, run, targets) {
  const profile = 'desktop';
  const { context, page } = await newContext(browser, profile, { seed: true });
  const result = { profile, run, switches: [] };
  try {
    if (!targets.stationA || !targets.stationB) throw new Error('Senderkarten nicht gefunden');
    await page.goto(`${BASE}/`, { waitUntil: 'load', timeout: 120_000 });
    await waitFirstFrame(page);
    await waitQuiet(page);
    for (const [label, target, station] of [
      ['Klick bis Ton (erster Sender)', targets.stationA, STATION_A],
      ['Senderwechsel bis Ton', targets.stationB, STATION_B],
    ]) {
      const before = await page.evaluate(() => performance.now());
      await page.mouse.click(target.x, target.y);
      const ok = await waitMedia(page, before, station.slug);
      await page.waitForTimeout(1500);
      const d = await page.evaluate(
        ([a, slug]) => {
          const ev = window.__perf.events.find((e) => e.name === 'pointerdown' && e.start >= a - 5);
          const click = ev ? ev.start : a;
          const media = window.__perf.media.filter((m) => m.t >= a);
          const first = (name) => media.find((m) => m.ev === name && (name === 'play()' || m.src.includes(slug)))?.t ?? null;
          const mark = (prefix) => {
            const m = performance.getEntriesByType('mark').find((x) => x.name.startsWith(`linefm:${prefix}`) && x.startTime >= a - 5);
            return m ? { name: m.name.slice(7), t: m.startTime } : null;
          };
          const rel = (t) => (t === null || t === undefined ? null : t - click);
          const url = mark('stream-url');
          return {
            click,
            srcSet: rel(first('src')),
            playCall: rel(first('play()')),
            loadstart: rel(first('loadstart')),
            canplay: rel(first('canplay')),
            playing: rel(first('playing')),
            markPlayRequest: rel(mark('play-request')?.t),
            markStreamUrl: url ? { kind: url.name, at: rel(url.t) } : null,
            markConnecting: rel(mark('player-connecting')?.t),
            markPlaying: rel(mark('player-playing')?.t),
            src: media.find((m) => m.ev === 'src')?.src ?? null,
          };
        },
        [before, station.slug],
      );
      result.switches.push({ label, station: station.slug, ok, ...d });
    }
  } catch (e) {
    result.error = String(e?.message ?? e).slice(0, 500);
  } finally {
    await context.close();
  }
  return result;
}

function aggregate(results) {
  const pick = (list, fn) => stats(list.map(fn));
  const out = {};
  for (const profile of Object.keys(PROFILES)) {
    const loads = results.load.filter((r) => r.profile === profile && !r.error);
    if (!loads.length) continue;
    const keys = ['ttfb', 'fcp', 'lcp', 'cls', 'dartMain', 'runApp', 'firstFrame', 'shellHidden', 'interactive', 'tbt', 'longTaskMs', 'maxLongTask'];
    for (const phase of ['cold', 'warm']) {
      const rows = loads.map((r) => r[phase]).filter(Boolean);
      out[`${profile}.${phase}`] = Object.fromEntries([
        ...keys.map((k) => [k, pick(rows, (r) => r[k])]),
        ['bytes', pick(rows, (r) => r.network.bytes)],
        ['requests', pick(rows, (r) => r.network.requests)],
      ]);
    }
    const inter = results.interaction.filter((r) => r.profile === profile && !r.error);
    const stepNames = [...new Set(inter.flatMap((r) => r.steps.map((s) => s.name)))];
    for (const name of stepNames) {
      const rows = inter.map((r) => r.steps.find((s) => s.name === name)).filter((s) => s && !s.skipped);
      out[`${profile}.step.${name}`] = {
        inputToPaint: pick(rows, (s) => s.inputToPaint),
        p95: pick(rows, (s) => s.p95),
        max: pick(rows, (s) => s.max),
        over33: pick(rows, (s) => s.over33),
        longTaskMs: pick(rows, (s) => s.longTaskMs),
      };
    }
  }
  const audio = results.audio.filter((r) => !r.error);
  for (const label of ['Klick bis Ton (erster Sender)', 'Senderwechsel bis Ton']) {
    const rows = audio.map((r) => r.switches.find((s) => s.label === label)).filter((s) => s && s.ok);
    if (!rows.length) continue;
    out[`audio.${label}`] = {
      playing: pick(rows, (s) => s.playing),
      playCall: pick(rows, (s) => s.playCall),
      markPlaying: pick(rows, (s) => s.markPlaying),
      ok: rows.length,
      tried: audio.length,
    };
  }
  return out;
}

async function main() {
  mkdirSync(OUT, { recursive: true });
  const started = Date.now();
  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
  const results = { load: [], interaction: [], audio: [], targets: {} };
  const profiles = args.profiles.split(',').filter((p) => PROFILES[p]);
  try {
    for (const profile of profiles) {
      for (let i = 1; i <= RUNS; i++) {
        const r = await measureLoad(browser, profile, i);
        results.load.push(r);
        console.log(
          `${profile} Laden ${i}: ` +
            (r.error ? `FEHLER ${r.error}` : `erstes Bild ${Math.round(r.cold.firstFrame)} ms kalt, ${Math.round(r.warm.firstFrame)} ms warm, ${r.cold.network.bytes} B`),
        );
      }
      let found;
      try {
        found = await discoverTargets(browser, profile);
      } catch (e) {
        found = { error: String(e?.message ?? e).slice(0, 300), targets: {} };
      }
      results.targets[profile] = found;
      console.log(`${profile} Ziele: ${JSON.stringify(Object.fromEntries(Object.entries(found.targets).map(([k, v]) => [k, v ? v.name : null])))}`);
      for (let i = 1; i <= RUNS; i++) {
        const r = await measureInteraction(browser, profile, i, found.targets);
        results.interaction.push(r);
        console.log(`${profile} Bedienung ${i}: ${r.error ?? r.steps.map((s) => `${s.name}=${s.skipped ? 'uebersprungen' : Math.round(s.inputToPaint ?? -1)}`).join(', ')}`);
      }
    }
    if (args.audio) {
      const targets = results.targets.desktop?.targets ?? (await discoverTargets(browser, 'desktop')).targets;
      for (let i = 1; i <= RUNS; i++) {
        const r = await measureAudio(browser, i, targets);
        results.audio.push(r);
        console.log(`Ton ${i}: ${r.error ?? r.switches.map((s) => `${s.label}=${s.ok ? Math.round(s.playing) + ' ms' : 'kein playing'}`).join(', ')}`);
      }
    }
  } finally {
    await browser.close();
  }
  const report = {
    tool: 'tool/perf/web_perf.mjs',
    environment: { ...environment(), browser: chromium.name(), base: BASE },
    runs: RUNS,
    profiles: Object.fromEntries(profiles.map((p) => [p, PROFILES[p]])),
    durationMs: Date.now() - started,
    stats: aggregate(results),
    results,
  };
  writeFileSync(join(OUT, 'web-perf.json'), JSON.stringify(report, null, 2));
  console.log(`web-perf: ${join(OUT, 'web-perf.json')} (${Math.round(report.durationMs / 1000)} s)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
