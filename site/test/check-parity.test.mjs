import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { expectedPaths, missingPaths } from '../scripts/check-parity.mjs';

const fixture = path.join(path.dirname(fileURLToPath(import.meta.url)), 'fixtures/minirepo');
const tmpDirs = [];
after(() => {
  for (const d of tmpDirs) fs.rmSync(d, { recursive: true, force: true });
});

function distWithout(omit = []) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'ip-parity-'));
  tmpDirs.push(d);
  for (const p of expectedPaths(fixture)) {
    if (omit.includes(p)) continue;
    const f = path.join(d, p);
    fs.mkdirSync(path.dirname(f), { recursive: true });
    fs.writeFileSync(f, '');
  }
  return d;
}

test('expectedPaths lists pages, markdown copies, assets and globals from the source tree', () => {
  // The shared fixture has no orphan page; add one to a copy.
  const src = fs.mkdtempSync(path.join(os.tmpdir(), 'ip-parity-src-'));
  tmpDirs.push(src);
  fs.cpSync(fixture, src, { recursive: true });
  fs.writeFileSync(path.join(src, 'pg/orphan.md'), '---\ntitle: Orphan\n---\n\n# Orphan\n');
  const got = expectedPaths(src);
  for (const p of [
    '/pg.html',
    '/pg/index.html',
    '/pg/getting-started.html',
    '/pg/getting-started.md',
    '/pg/orphan.html',
    '/pg/images/a.png',
    '/pg/ai/troubleshooting.md',
    '/index.html',
    '/robots.txt',
    '/CNAME',
  ]) {
    assert.ok(got.includes(p), `missing expectation ${p}`);
  }
  assert.ok(!got.includes('/pg/ai/troubleshooting.html'));
});

test('missingPaths returns only the absent path', () => {
  const dist = distWithout(['/pg/getting-started.md']);
  assert.deepEqual(missingPaths(fixture, dist), ['/pg/getting-started.md']);
});

test('missingPaths checks extra paths too', () => {
  const dist = distWithout();
  assert.ok(missingPaths(fixture, dist, ['/zzz.html']).includes('/zzz.html'));
});
