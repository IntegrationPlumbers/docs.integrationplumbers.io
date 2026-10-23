import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { convert } from '../scripts/convert.mjs';

const fixture = fileURLToPath(new URL('./fixtures/minirepo', import.meta.url));
const tmpDirs = [];
const tmp = () => {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), 'ip-convert-'));
  tmpDirs.push(d);
  return d;
};
const setup = () => {
  const src = tmp();
  fs.cpSync(fixture, src, { recursive: true });
  return { src, site: tmp() };
};
after(() => { for (const d of tmpDirs) fs.rmSync(d, { recursive: true, force: true }); });

test('products.json carries products.yml fields plus parsed builds and date', async () => {
  const { src, site } = setup();
  await convert(src, site);
  const products = JSON.parse(fs.readFileSync(path.join(site, 'src/products.json'), 'utf8'));
  assert.deepEqual(products.pg, {
    key: 'pg',
    name: 'PostgreSQL',
    mark: 'Pg',
    status: 'General Availability',
    summary: 'Example summary for the fixture product.',
    supports: ['PostgreSQL 14 to 18', 'Example clusters'],
    builds: [{ build: '24.1.3.0.0', em: '24ai' }, { build: '13.5.17.0.0', em: '13.5' }],
    date: 'October 2026',
    title: 'PostgreSQL Plug-in',
  });
});

test('index.mdx description, llms.txt header and legal.md headings name the products from products.yml', async () => {
  const { src, site } = setup();
  await convert(src, site);
  const index = fs.readFileSync(path.join(site, 'src/content/docs/index.mdx'), 'utf8');
  assert.match(index, /PostgreSQL/);
  const llms = fs.readFileSync(path.join(site, 'public/llms.txt'), 'utf8').split('\n');
  assert.match(llms[2], /PostgreSQL/);
  const legal = fs.readFileSync(path.join(site, 'src/content/docs/legal.md'), 'utf8');
  assert.match(legal, /## PostgreSQL plug-in/);
});

test('a product folder with no products.yml entry fails the build', async () => {
  const { src, site } = setup();
  fs.mkdirSync(path.join(src, 'my'));
  fs.writeFileSync(path.join(src, 'my/index.md'), '# My\n');
  fs.writeFileSync(path.join(src, '_data/my_nav.yml'), 'groups: []\n');
  await assert.rejects(convert(src, site), /convert: .*my.*products\.yml/);
});

test('a nav entry whose page does not exist fails the build', async () => {
  const { src, site } = setup();
  fs.appendFileSync(path.join(src, '_data/pg_nav.yml'), '      - { title: "Ghost", url: /pg/ghost.html }\n');
  await assert.rejects(convert(src, site), /convert: nav page .*\/pg\/ghost\.html.* does not exist/);
});

test('an index.md with no parseable release line fails the build', async () => {
  const { src, site } = setup();
  const f = path.join(src, 'pg/index.md');
  fs.writeFileSync(f, fs.readFileSync(f, 'utf8').replace(/^\*General Availability.*\*$/m, '*Some release*'));
  await assert.rejects(convert(src, site), /convert: pg\/index\.md: no builds found/);
});

test('raw images are published at their old paths', async () => {
  const { src, site } = setup();
  const result = await convert(src, site);
  assert.ok(fs.existsSync(path.join(site, 'public/pg/images/a.png')));
  assert.ok(result.pages.includes('/pg/images/a.png'));
});

test('a page absent from the nav still converts and is not in sidebar.json', async () => {
  const { src, site } = setup();
  fs.writeFileSync(path.join(src, 'pg/orphan.md'), '---\ntitle: Orphan\nnav_order: 9\n---\n\n# Orphan\n\nThis page is not listed in the navigation file.\n');
  await convert(src, site);
  assert.ok(fs.existsSync(path.join(site, 'src/content/docs/pg/orphan.md')));
  assert.ok(!fs.readFileSync(path.join(site, 'src/sidebar.json'), 'utf8').includes('pg/orphan'));
});
