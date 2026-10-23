import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { checkLinks } from '../scripts/check-links.mjs';

const tmpDirs = [];
const tmpDist = (files) => {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'ip-links-'));
  tmpDirs.push(d);
  for (const [rel, body] of Object.entries(files)) {
    const p = path.join(d, rel);
    fs.mkdirSync(path.dirname(p), { recursive: true });
    fs.writeFileSync(p, body);
  }
  return d;
};
after(() => {
  for (const d of tmpDirs) fs.rmSync(d, { recursive: true, force: true });
});

test('resolves root-relative, relative, extensionless and directory links', () => {
  const dist = tmpDist({
    'index.html': '<a href="/pg/a.html">a</a><a href="pg/a">b</a><a href="/pg/">c</a><img src="/static/x.png">',
    'pg/a.html': "<h2 id=\"before\">x</h2><a href='b.html#top'>b</a><a href=\"../index.html\">home</a><a href=\"/pg/a.html?x=1#before\">self</a>",
    'pg/b.html': '<h1 id="top">t</h1><a href="a.html#before">back</a>',
    'pg/index.html': '<a href="../pg.html">p</a>',
    'pg.html': '<a href="/pg/a%2Ehtml#before">enc</a>',
    'static/x.png': 'png',
  });
  assert.deepEqual(checkLinks(dist), []);
});

test('reports a link to a missing file', () => {
  const dist = tmpDist({
    'index.html': '<a href="/nope.html">x</a><video poster="/gone.png"></video><a href="/dir">d</a>',
    'dir/other.html': '',
  });
  const f = checkLinks(dist);
  assert.deepEqual(f.map((x) => [x.file, x.url, x.reason]), [
    ['index.html', '/nope.html', 'missing-file'],
    ['index.html', '/gone.png', 'missing-file'],
    ['index.html', '/dir', 'missing-file'],
  ]);
});

test('reports a fragment whose id is not in the target page', () => {
  const dist = tmpDist({
    'index.html': '<a href="/a.html#nope">x</a><a href="/a.html#a%20b">y</a><a href="/a.html#ok&amp;1">z</a>',
    'a.html': '<h2 id="a b">t</h2><a name="x"></a><h2 id=\'ok&1\'>',
  });
  const f = checkLinks(dist);
  assert.deepEqual(f.map((x) => [x.url, x.reason]), [['/a.html#nope', 'missing-anchor']]);
});

test('ignores external, mailto, tel, javascript, data and protocol-relative URLs', () => {
  const dist = tmpDist({
    'index.html': [
      '<a href="https://example.com/x#y">',
      '<a href="http://example.com">',
      '<a href="mailto:a@b.c">',
      '<a href="tel:+1555">',
      '<a href="javascript:void(0)">',
      '<img src="data:image/png;base64,AAAA">',
      '<a href="//cdn.example.com/x.js">',
      '<a href="">',
    ].join(''),
  });
  assert.deepEqual(checkLinks(dist), []);
});

test('a bare #frag checks the current page', () => {
  const dist = tmpDist({
    'p.html': '<h2 id="here">h</h2><a href="#here">ok</a><a href="#gone">bad</a><a name="legacy"></a><a href="#legacy">ok2</a>',
  });
  const f = checkLinks(dist);
  assert.deepEqual(f.map((x) => [x.file, x.url, x.reason]), [['p.html', '#gone', 'missing-anchor']]);
});

test('follows hash-preserving redirect stubs to the real page', () => {
  const stub = "<script>location.replace('../pg.html' + location.hash)</script>";
  const dist = tmpDist({
    'pg/index.html': stub,
    'pg.html': '<h2 id="intro">i</h2>',
    'a.html': '<a href="/pg/#intro">ok</a><a href="/pg/#nope">bad</a>',
  });
  assert.deepEqual(checkLinks(dist).map((x) => [x.url, x.reason]), [['/pg/#nope', 'missing-anchor']]);
});
