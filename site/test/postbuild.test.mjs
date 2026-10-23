import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { postbuild } from '../scripts/postbuild-pages.mjs';

const tmpDirs = [];
const tmpDist = () => {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'ip-postbuild-'));
  tmpDirs.push(d);
  fs.mkdirSync(path.join(d, 'pg'));
  return d;
};
after(() => {
  for (const d of tmpDirs) fs.rmSync(d, { recursive: true, force: true });
});

test('postbuild writes product redirects and sitemap.xml', () => {
  const dist = tmpDist();
  fs.writeFileSync(path.join(dist, 'sitemap-index.xml'), '<x/>');
  postbuild(dist, ['pg']);
  assert.match(fs.readFileSync(path.join(dist, 'pg', 'index.html'), 'utf8'), /url=\.\.\/pg\.html/);
  assert.equal(fs.readFileSync(path.join(dist, 'sitemap.xml'), 'utf8'), '<x/>');
});

test('postbuild throws when sitemap-index.xml is missing', () => {
  const dist = tmpDist();
  assert.throws(() => postbuild(dist, ['pg']), /^Error: postbuild:/);
});
