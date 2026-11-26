'use strict';

// Minimaler Service Worker: Offline-Huelle fuer die PWA-Installierbarkeit.
// Netz zuerst; nur same-origin GET. Audio-Streams und API-Aufrufe laufen
// cross-origin und werden nie abgefangen. __BUILD_ID__ setzt tool/web_postbuild.dart.
const BUILD_ID = '__BUILD_ID__';
const SHELL_CACHE = 'linefm-shell-' + BUILD_ID;
// Beide Caches tragen die Build-ID. Beim Aktivieren eines neuen Service Workers werden alle
// linefm-Caches anderer Builds geloescht, damit alte main.<hash>- und canvaskit-Dateien
// nicht dauerhaft Speicher belegen (Browser-Kontingent). Kosten: ein Neuladen pro Release.
const IMMUTABLE_CACHE = 'linefm-immutable-' + BUILD_ID;
const SHELL = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'analytics.js',
  'cast.js',
  'manifest.webmanifest',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
];
const SHELL_PATHS = new Set(SHELL.map((p) => new URL(p, self.registration.scope).pathname));
const IMMUTABLE = /\/(main\.[0-9a-f]{8}\.dart\.(js|wasm|mjs)|canvaskit\/[0-9a-f]{40}\/.+)$/;

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE)
      .then((cache) => cache.addAll(SHELL))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((k) => k.startsWith('linefm-') && k !== SHELL_CACHE && k !== IMMUTABLE_CACHE)
          .map((k) => caches.delete(k)),
      ))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (request.headers.has('range')) return;

  if (IMMUTABLE.test(url.pathname)) {
    event.respondWith(
      caches.open(IMMUTABLE_CACHE).then((cache) =>
        cache.match(request).then((hit) => hit || fetch(request).then((res) => {
          if (res.ok) cache.put(request, res.clone());
          return res;
        })),
      ),
    );
    return;
  }

  if (request.mode === 'navigate' || SHELL_PATHS.has(url.pathname)) {
    event.respondWith(
      fetch(request).then((res) => {
        if (res.ok) {
          const copy = res.clone();
          caches.open(SHELL_CACHE).then((cache) => cache.put(request, copy));
        }
        return res;
      }).catch(() => caches.match(request).then((hit) => hit || caches.match('index.html'))),
    );
  }
});
