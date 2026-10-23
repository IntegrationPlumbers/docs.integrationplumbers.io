// For GitHub Pages: old product URLs (/postgresql/) resolve to the new landing pages
// (/postgresql.html). Every other old URL (/postgresql/getting-started.html) is unchanged.
import fs from 'node:fs';
import path from 'node:path';

const dist = process.argv[2] ? path.resolve(process.argv[2]) : path.resolve(new URL('../dist', import.meta.url).pathname);
for (const p of ['postgresql', 'mysql', 'mssql', 'db2']) {
  const html = `<!doctype html><meta charset="utf-8"><title>Redirecting</title>
<link rel="canonical" href="/${p}.html"><meta http-equiv="refresh" content="0; url=../${p}.html">
<script>location.replace('../${p}.html' + location.hash)</script>
<a href="../${p}.html">Continue to the ${p} guide</a>`;
  fs.writeFileSync(path.join(dist, p, 'index.html'), html);
}
console.log('wrote product index redirects');
