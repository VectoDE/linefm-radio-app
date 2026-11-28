// TLS front for the CI web container, like Traefik in production: terminates
// HTTPS on loopback and passes requests and responses to the plain HTTP
// nginx container unchanged (status, headers and body as nginx sends them).
// Used by the autoplay check so every browser sees the real security headers,
// including CSP "upgrade-insecure-requests", over HTTPS.
//
//   node tls_proxy.mjs --cert cert.pem --key key.pem --listen 8443 --upstream 8080
import { readFileSync } from 'node:fs';
import { request } from 'node:http';
import { createServer } from 'node:https';
import { parseArgs } from 'node:util';

const { values: args } = parseArgs({
  options: {
    cert: { type: 'string' },
    key: { type: 'string' },
    listen: { type: 'string', default: '8443' },
    upstream: { type: 'string', default: '8080' },
  },
});
if (!args.cert || !args.key) {
  console.error('usage: node tls_proxy.mjs --cert <pem> --key <pem> [--listen 8443] [--upstream 8080]');
  process.exit(2);
}

const HOST = '127.0.0.1';
const server = createServer({ cert: readFileSync(args.cert), key: readFileSync(args.key) }, (req, res) => {
  const upstream = request(
    { host: HOST, port: Number(args.upstream), method: req.method, path: req.url, headers: req.headers },
    (up) => {
      res.writeHead(up.statusCode ?? 502, up.statusMessage, up.rawHeaders);
      up.pipe(res);
    },
  );
  upstream.on('error', (e) => {
    if (!res.headersSent) res.writeHead(502, { 'content-type': 'text/plain' });
    res.end(`upstream error: ${e.message}\n`);
  });
  req.pipe(upstream);
});
server.listen(Number(args.listen), HOST, () => {
  console.log(`tls_proxy: https://${HOST}:${args.listen} -> http://${HOST}:${args.upstream}`);
});
