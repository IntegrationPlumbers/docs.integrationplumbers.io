import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SKIP = /^(?:https?:|\/\/|mailto:|tel:|data:|javascript:)/i;
const ATTR = /\b(?:href|src|poster)\s*=\s*(?:"([^"]*)"|'([^']*)')/gi;

function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.name.endsWith('.html')) out.push(p);
  }
  return out;
}

const decode = (s) => {
  const t = s.replace(/&amp;/g, '&');
  try {
    return decodeURIComponent(t);
  } catch {
    return t;
  }
};

function isFile(p) {
  try {
    return fs.statSync(p).isFile();
  } catch {
    return false;
  }
}

function resolveTarget(distDir, pageDir, urlPath) {
  const base = urlPath.startsWith('/') ? path.join(distDir, urlPath) : path.join(pageDir, urlPath);
  const trimmed = base.replace(/[\\/]+$/, '');
  const candidates = urlPath.endsWith('/')
    ? [path.join(trimmed, 'index.html')]
    : [trimmed, `${trimmed}.html`, path.join(trimmed, 'index.html')];
  return candidates.find(isFile) ?? null;
}

function hasAnchor(html, frag) {
  const re = /\b(?:id|name)\s*=\s*(?:"([^"]*)"|'([^']*)')/gi;
  for (const m of html.matchAll(re)) {
    if (decode(m[1] ?? m[2]) === frag) return true;
  }
  return false;
}

export function scanLinks(distDir) {
  const findings = [];
  let checked = 0;
  const cache = new Map();
  const read = (f) => {
    if (!cache.has(f)) cache.set(f, fs.readFileSync(f, 'utf8'));
    return cache.get(f);
  };
  for (const file of walk(distDir)) {
    const rel = path.relative(distDir, file).split(path.sep).join('/');
    const html = read(file);
    for (const m of html.matchAll(ATTR)) {
      const raw = (m[1] ?? m[2]).trim();
      if (raw === '' || SKIP.test(raw)) continue;
      checked++;
      const noQuery = raw.replace(/\?[^#]*/, '');
      const hash = noQuery.indexOf('#');
      const pathPart = hash === -1 ? noQuery : noQuery.slice(0, hash);
      const frag = hash === -1 ? '' : decode(noQuery.slice(hash + 1));
      let target;
      if (pathPart === '') target = file;
      else target = resolveTarget(distDir, path.dirname(file), decode(pathPart));
      if (!target) {
        findings.push({ file: rel, url: raw, reason: 'missing-file' });
        continue;
      }
      // Hash-preserving redirect stubs (postbuild-pages.mjs): follow to the real page.
      const stub = target.endsWith('.html') && read(target).match(/location\.replace\('([^']+)'\s*\+\s*location\.hash\)/);
      if (stub) target = resolveTarget(distDir, path.dirname(target), stub[1]) ?? target;
      if (frag && target.endsWith('.html') && !hasAnchor(read(target), frag)) {
        findings.push({ file: rel, url: raw, reason: 'missing-anchor' });
      }
    }
  }
  return { findings, checked };
}

export function checkLinks(distDir) {
  return scanLinks(distDir).findings;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const dist = process.argv[2] ? path.resolve(process.argv[2]) : path.resolve(here, '../dist');
  const { findings, checked } = scanLinks(dist);
  if (findings.length) {
    for (const f of findings) console.log(`${f.file} → ${f.url} (${f.reason})`);
    process.exit(1);
  }
  console.log(`links ok (${checked} checked)`);
}
