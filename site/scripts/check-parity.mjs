import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';

const GLOBAL = [
  '/index.html',
  '/legal.html',
  '/llms.txt',
  '/sitemap.xml',
  '/sitemap-index.xml',
  '/robots.txt',
  '/404.html',
  '/CNAME',
];
const ASSET_DIRS = ['images', 'ai', 'downloads'];

function walkFiles(dir, rel = '', out = []) {
  for (const e of fs.readdirSync(path.join(dir, rel), { withFileTypes: true })) {
    const r = rel ? `${rel}/${e.name}` : e.name;
    if (e.isDirectory()) walkFiles(dir, r, out);
    else if (e.isFile()) out.push(r);
  }
  return out;
}

export function expectedPaths(srcRoot) {
  const products = YAML.parse(fs.readFileSync(path.join(srcRoot, '_data/products.yml'), 'utf8'));
  const out = [];
  for (const p of Object.keys(products)) {
    out.push(`/${p}.html`, `/${p}/index.html`, `/${p}/index.md`);
    const pdir = path.join(srcRoot, p);
    for (const e of fs.readdirSync(pdir, { withFileTypes: true })) {
      if (!e.isFile() || !e.name.endsWith('.md')) continue;
      const slug = e.name.slice(0, -3);
      if (slug === 'index') continue;
      out.push(`/${p}/${slug}.html`, `/${p}/${slug}.md`);
    }
    for (const sub of ASSET_DIRS) {
      const sdir = path.join(pdir, sub);
      if (!fs.existsSync(sdir)) continue;
      for (const f of walkFiles(sdir)) out.push(`/${p}/${sub}/${f}`);
    }
  }
  out.push(...GLOBAL);
  return [...new Set(out)].sort();
}

export function missingPaths(srcRoot, distDir, extra = []) {
  const all = [...expectedPaths(srcRoot), ...extra];
  return [...new Set(all.filter((p) => !fs.existsSync(path.join(distDir, p))))].sort();
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  const i = args.indexOf('--urls');
  let extra = [];
  if (i !== -1) {
    extra = fs
      .readFileSync(args[i + 1], 'utf8')
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean);
    args.splice(i, 2);
  }
  const [srcRoot, dist] = args;
  if (!srcRoot || !dist) {
    console.error('usage: check-parity.mjs <srcRoot> <dist> [--urls file]');
    process.exit(2);
  }
  const missing = missingPaths(srcRoot, dist, extra);
  if (missing.length) {
    for (const p of missing) console.log(`missing: ${p}`);
    process.exit(1);
  }
  const total = new Set([...expectedPaths(srcRoot), ...extra]).size;
  console.log(`parity ok (${total} paths)`);
}
