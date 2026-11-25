// Groessen des Web-Builds (Issue #92): roh, gzip Stufe 5 (wie nginx in
// deploy/) und Brotli Stufe 11 (Vergleich: was Vorkomprimieren bringen wuerde).
//
//   node sizes.mjs --web ../../build/web --out out/sizes.json
//
// Nur Node-Standardbibliothek.

import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { parseArgs } from 'node:util';
import { brotliCompressSync, constants, gzipSync } from 'node:zlib';

import { environment } from './lib.mjs';

const { values: args } = parseArgs({
  options: {
    web: { type: 'string', default: '../../build/web' },
    out: { type: 'string', default: 'out/sizes.json' },
  },
});

const WEB = resolve(args.web);

function walk(dir) {
  return readdirSync(dir).flatMap((name) => {
    const p = join(dir, name);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
}

const files = walk(WEB).map((p) => ({ path: relative(WEB, p).replaceAll('\\', '/'), bytes: statSync(p).size }));

function group(path) {
  if (/^main\.[0-9a-f]+\.dart\.wasm$|^main\.dart\.wasm$/.test(path)) return 'main.dart.wasm';
  if (/^main\.[0-9a-f]+\.dart\.mjs$|^main\.dart\.mjs$/.test(path)) return 'main.dart.mjs';
  if (/^main\.[0-9a-f]+\.dart\.js$|^main\.dart\.js$/.test(path)) return 'main.dart.js (Rueckfall)';
  if (path.startsWith('canvaskit/') && path.includes('skwasm')) return 'skwasm (Wasm-Renderer)';
  if (path.startsWith('canvaskit/')) return 'canvaskit (Rueckfall)';
  if (path.startsWith('assets/fonts/fallback/')) return 'Ersatzschriften (nur bei Bedarf)';
  if (/\.(ttf|otf|woff2?)$/.test(path)) return 'Schriften (App)';
  if (/\.(png|jpe?g|webp|avif|gif|svg)$/.test(path)) return 'Bilder';
  if (path.startsWith('assets/audio/')) return 'Audio';
  return 'Sonstiges';
}

// Startrelevante Einzeldateien mit Kompressionsvergleich.
const detail = files
  .filter((f) => /^(main\.|flutter_bootstrap\.js|index\.html|analytics\.js)/.test(f.path) || /skwasm[^/]*\.(wasm|js|mjs)$/.test(f.path) || /^assets\/(FontManifest\.json|AssetManifest\.bin|NOTICES)$/.test(f.path) || (/^assets\/.*\.(ttf|otf)$/.test(f.path) && !f.path.includes('/fallback/')))
  .map((f) => {
    const buf = readFileSync(join(WEB, f.path));
    return {
      ...f,
      gzip5: gzipSync(buf, { level: 5 }).length,
      brotli11: brotliCompressSync(buf, {
        params: { [constants.BROTLI_PARAM_QUALITY]: 11, [constants.BROTLI_PARAM_SIZE_HINT]: buf.length },
      }).length,
    };
  })
  .sort((a, b) => b.bytes - a.bytes);

const groups = {};
for (const f of files) {
  const g = group(f.path);
  groups[g] ??= { files: 0, bytes: 0 };
  groups[g].files += 1;
  groups[g].bytes += f.bytes;
}

const largestImages = files
  .filter((f) => group(f.path) === 'Bilder')
  .sort((a, b) => b.bytes - a.bytes)
  .slice(0, 15);

writeFileSync(
  resolve(args.out),
  JSON.stringify(
    {
      tool: 'tool/perf/sizes.mjs',
      environment: environment(),
      total: { files: files.length, bytes: files.reduce((a, f) => a + f.bytes, 0) },
      groups,
      detail,
      largestImages,
    },
    null,
    2,
  ),
);
console.log(`sizes: ${files.length} Dateien, ${detail.length} startrelevante mit gzip/Brotli-Vergleich`);
