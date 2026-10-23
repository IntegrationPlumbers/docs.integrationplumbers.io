// For GitHub Pages: old product URLs (/postgresql/) resolve to the new landing pages
// (/postgresql.html). Every other old URL (/postgresql/getting-started.html) is unchanged.
// Also aliases Starlight's sitemap-index.xml as /sitemap.xml (Search Console is configured with it).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function postbuild(distDir, productKeys) {
  for (const p of productKeys) {
    const html = `<!doctype html><meta charset="utf-8"><title>Redirecting</title>
<link rel="canonical" href="/${p}.html"><meta http-equiv="refresh" content="0; url=../${p}.html">
<script>location.replace('../${p}.html' + location.hash)</script>
<a href="../${p}.html">Continue to the ${p} guide</a>`;
    fs.writeFileSync(path.join(distDir, p, 'index.html'), html);
  }
  const index = path.join(distDir, 'sitemap-index.xml');
  if (!fs.existsSync(index)) {
    throw new Error(`postbuild: ${index} not found; the build produced no sitemap`);
  }
  fs.copyFileSync(index, path.join(distDir, 'sitemap.xml'));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const dist = process.argv[2] ? path.resolve(process.argv[2]) : path.resolve(here, '../dist');
  const products = JSON.parse(fs.readFileSync(path.join(here, '../src/products.json'), 'utf8'));
  postbuild(dist, Object.keys(products));
  console.log('wrote product index redirects');
}
