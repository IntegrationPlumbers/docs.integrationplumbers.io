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
