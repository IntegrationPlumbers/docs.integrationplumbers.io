// Converts the Jekyll docs repo into Starlight content.
// Usage: node scripts/convert.mjs <path-to-jekyll-repo>
import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';
const yaml = { load: (s) => YAML.parse(s) };

const SRC = path.resolve(process.argv[2]);
const ROOT = path.resolve(new URL('..', import.meta.url).pathname);
const DOCS = path.join(ROOT, 'src/content/docs');
const PUBLIC = path.join(ROOT, 'public');
const SITE = 'https://docs.integrationplumbers.io';

const PRODUCTS = {
  postgresql: {
    name: 'PostgreSQL',
    icon: 'postgresql',
    status: 'General Availability',
    summary: 'Close to 200 metrics per instance, plus five advisors for plans, plan drift, workload history, indexes, and vacuum.',
    supports: ['PostgreSQL 14 to 18', 'Patroni clusters'],
  },
  mysql: {
    name: 'MySQL',
    icon: 'mysql',
    status: 'General Availability',
    summary: 'MySQL servers, InnoDB Clusters, and ClusterSets as first-class targets, with replication, backup, and compliance coverage.',
    supports: ['MySQL 8.4 LTS', 'MySQL 9.7 LTS', 'InnoDB Cluster'],
  },
  mssql: {
    name: 'SQL Server',
    fullName: 'Microsoft SQL Server',
    icon: 'mssql',
    status: 'General Availability',
    summary: 'Availability, performance, queries, deadlocks, indexes, space, and AlwaysOn availability groups from one target type.',
    supports: ['SQL Server 2016 to 2025', 'Windows and Linux'],
  },
  db2: {
    name: 'IBM Db2',
    icon: 'db2',
    status: 'General Availability',
    summary: 'Db2 for Linux, UNIX, and Windows through the MON_GET table functions, with HADR, storage, locking, and compliance.',
    supports: ['Db2 LUW 12.1', 'Db2 LUW 11.5', 'HADR'],
  },
};

const rm = (p) => fs.rmSync(p, { recursive: true, force: true });
const mkdirp = (p) => fs.mkdirSync(p, { recursive: true });
const copy = (a, b) => { mkdirp(path.dirname(b)); fs.copyFileSync(a, b); };

rm(DOCS); mkdirp(DOCS);
for (const p of Object.keys(PRODUCTS)) rm(path.join(PUBLIC, p));

function splitFrontmatter(src) {
  const m = src.match(/^---\n([\s\S]*?)\n---\n?/);
  if (!m) return [{}, src];
  return [yaml.load(m[1]) || {}, src.slice(m[0].length)];
}

function plain(md) {
  return md
    .replace(/!\[[^\]]*\]\([^)]*\)/g, '')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/[*_`]/g, '')
    .replace(/<[^>]+>/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function firstSentence(body) {
  for (const para of body.split(/\n\s*\n/)) {
    const t = para.trim();
    if (!t || /^(#|!\[|>|\||<|-|\*\s|\d+\.\s|```|---)/.test(t)) continue;
    const p = plain(t);
    if (p.length < 25) continue;
    const s = p.match(/^.{25,}?[.!?](\s|$)/);
    let out = (s ? s[0] : p).trim();
    if (out.length > 220) out = out.slice(0, 217).replace(/\s+\S*$/, '') + '…';
    return out;
  }
  return '';
}

function rewriteLinks(body, product) {
  // Absolute links to the live site become site-local.
  body = body.replace(/\]\(https?:\/\/docs\.integrationplumbers\.io(\/[^)\s]*)\)/g, '](\$1)');
  // Relative .md links become absolute .html URLs (keeps the old URL shape).
  body = body.replace(/\]\((?!https?:|\/|#|mailto:)([^)\s]+?)\.md(#[^)\s]*)?\)/g, (_m, file, hash = '') => {
    if (file.startsWith('ai/')) return `](/${product}/${file}.md${hash})`;
    const slug = file.replace(/^\.\//, '');
    return `](/${product}/${slug === 'index' ? '' : slug + '.html'}${hash})`;
  });
  // Other relative non-image links (downloads) become absolute.
  body = body.replace(/(?<!!)\]\((?!https?:|\/|#|mailto:|images\/)([^)\s]+)\)/g, `](/${product}/$1)`);
  // Root-relative .md links to other products.
  body = body.replace(/\]\(\/(postgresql|mysql|mssql|db2)\/([^)\s#]+)\.md(#[^)\s]*)?\)/g, (_m, p, f, h = '') =>
    f.startsWith('ai/') ? `](/${p}/${f}.md${h})` : `](/${p}/${f}.html${h})`);
  return body;
}

function copyHtmlMedia(body, product) {
  // Raw-HTML media (video src/poster, img in HTML) are served from public/ as-is.
  const re = /<(?:video|source|img)\b[^>]*>/g;
  for (const tag of body.match(re) || []) {
    for (const m of tag.matchAll(/\b(?:src|poster)="([^"]+)"/g)) {
      const ref = m[1];
      if (/^(https?:|data:|\/)/.test(ref)) continue;
      const from = path.join(SRC, product, ref);
      if (fs.existsSync(from)) copy(from, path.join(PUBLIC, product, ref));
      else console.warn(`missing media ${product}/${ref}`);
    }
  }
}

const llms = [];
const h1Slugs = {}; // '/postgresql/foo.html' -> slug of that page's old H1
const slugify = (t) => t.toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu, '').trim().replace(/\s/g, '-');
const legal = {};
const sidebar = [];
const landing = {};

for (const [product, info] of Object.entries(PRODUCTS)) {
  const dir = path.join(SRC, product);
  const nav = yaml.load(fs.readFileSync(path.join(SRC, `_data/${product}_nav.yml`), 'utf8'));
  const outDir = path.join(DOCS, product);
  mkdirp(outDir);
  mkdirp(path.join(PUBLIC, product));

  // Markdown images are optimized by Astro, so copy the image tree beside the content.
  if (fs.existsSync(path.join(dir, 'images'))) {
    fs.cpSync(path.join(dir, 'images'), path.join(outDir, 'images'), {
      recursive: true,
      filter: (f) => !/\.(mp4|webm)$/i.test(f),
    });
  }
  // Static extras published as plain files: AI guides and downloads.
  for (const extra of ['ai', 'downloads']) {
    const p = path.join(dir, extra);
    if (fs.existsSync(p)) fs.cpSync(p, path.join(PUBLIC, product, extra), { recursive: true });
  }

  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.md'));
  for (const file of files) {
    const slug = file.replace(/\.md$/, '');
    const [fm, raw] = splitFrontmatter(fs.readFileSync(path.join(dir, file), 'utf8'));
    let body = raw.replace(/\r\n/g, '\n');

    const h1 = body.match(/^#\s+(.+?)\s*(\{#[^}]+\})?\s*$/m);
    let title = (h1 ? h1[1] : fm.title || slug).trim();
    if (h1) body = body.replace(h1[0], '');

    const extra = {};
    h1Slugs[`/${product}/${slug === 'index' ? '' : slug + '.html'}`] = slugify(title);
    if (slug === 'index') {
      title = fm.title || title;
      // Title block: logo, company line, guide title, italic release lines.
      body = body.replace(/^!\[Logo\][^\n]*\n/m, '');
      body = body.replace(/^## Integration Plumbers\s*\n/m, '');
      body = body.replace(/^### Oracle Enterprise Manager Plug-?in for [^\n]*User Guide\s*\n/m, '');
      const releaseLines = [];
      body = body.replace(/^\*[^*\n][^\n]*\*\s*\n(\*[^*\n][^\n]*\*\s*\n)?/m, (m) => {
        releaseLines.push(...m.trim().split('\n').map((l) => l.trim().replace(/^\*|\*$/g, '').replace(/`/g, '').trim()));
        return '';
      });
      // Legal notice moves to its own page.
      body = body.replace(/<details>\s*<summary>Legal Notice<\/summary>([\s\S]*?)<\/details>\s*\n/, (_m, inner) => {
        legal[product] = inner.trim();
        return '';
      });
      if (!legal[product]) {
        // PostgreSQL keeps it as a bold heading followed by paragraphs.
        body = body.replace(/^\*\*Legal Notice\*\*\s*\n([\s\S]*?)(?=\n(?:The |## ))/m, (_m, inner) => {
          legal[product] = inner.trim();
          return '';
        });
      }
      const rel = releaseLines.join(' · ');
      const builds = [...rel.matchAll(/(\d+\.\d+\.\d+\.\d+\.\d+)\s+for Enterprise Manager\s+([\w.]+)/g)].map((m) => ({ build: m[1], em: m[2] }));
      const date = (rel.match(/(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}/) || [])[0];
      extra.product = { key: product, name: info.fullName || info.name, status: info.status, builds, date, supports: info.supports };
      landing[product] = { ...info, key: product, builds, date, title };
    }

    body = body.replace(/^\s*\n+/, '');
    body = rewriteLinks(body, product);
    copyHtmlMedia(body, product);

    const description = firstSentence(body) || info.summary;
    const front = [
      '---',
      `title: ${JSON.stringify(title)}`,
      `description: ${JSON.stringify(description)}`,
      extra.product ? `product: ${JSON.stringify(extra.product)}` : null,
      `editUrl: ${JSON.stringify(`https://github.com/IntegrationPlumbers/docs.integrationplumbers.io/blob/main/${product}/${file}`)}`,
      '---',
      '',
    ].filter((l) => l !== null).join('\n');
    fs.writeFileSync(path.join(outDir, `${slug}.md`), front + body);
    // Plain Markdown copy for "Copy page" / "View Markdown" and AI assistants.
    fs.writeFileSync(path.join(PUBLIC, product, `${slug}.md`), `# ${title}\n\n${body}`);
    llms.push(`- [${title}](${SITE}/${product}/${slug}.md): ${description}`);
  }

  sidebar.push({
    label: info.name,
    collapsed: true,
    items: nav.groups.map((g) => ({
      label: g.name,
      items: g.pages.map((pg) => {
        const u = pg.url.replace(/^\//, '').replace(/\.html$/, '').replace(/\/$/, '');
        return { label: pg.title, slug: u };
      }),
    })),
  });
}

// Links to a page's old H1 anchor now point at the page itself (Starlight renders the title).
for (const product of Object.keys(PRODUCTS)) {
  const dir = path.join(DOCS, product);
  for (const f of fs.readdirSync(dir).filter((n) => n.endsWith('.md'))) {
    const fp = path.join(dir, f);
    const src = fs.readFileSync(fp, 'utf8');
    const out = src.replace(/\]\((\/[a-z0-9]+\/[^)#\s]*)#([^)\s]+)\)/g, (m, url, frag) => (h1Slugs[url] === frag ? `](${url})` : m));
    if (out !== src) fs.writeFileSync(fp, out);
  }
}

// Legal page collects each product's notice.
const legalMd = [
  '---',
  'title: "Legal notices"',
  'description: "Legal notices and trademarks for Integration Plumbers plug-in documentation."',
  '---',
  '',
  ...Object.entries(legal).flatMap(([p, t]) => [`## ${PRODUCTS[p].fullName || PRODUCTS[p].name} plug-in`, '', t, '']),
].join('\n');
fs.writeFileSync(path.join(DOCS, 'legal.md'), legalMd);

fs.writeFileSync(
  path.join(DOCS, 'index.mdx'),
  [
    '---',
    'title: "Integration Plumbers documentation"',
    'description: "Documentation for the Integration Plumbers plug-ins for Oracle Enterprise Manager: PostgreSQL, MySQL, Microsoft SQL Server, and IBM Db2."',
    'template: splash',
    'editUrl: false',
    'tableOfContents: false',
    '---',
    '',
    "import ProductGrid from '../../components/ProductGrid.astro';",
    '',
    '<ProductGrid />',
    '',
  ].join('\n'),
);

fs.writeFileSync(
  path.join(PUBLIC, 'llms.txt'),
  [
    '# Integration Plumbers documentation',
    '',
    '> Guides for the Integration Plumbers plug-ins for Oracle Enterprise Manager 13.5 and 24ai: PostgreSQL, MySQL, Microsoft SQL Server, and IBM Db2. Every page is available as Markdown at the URLs below.',
    '',
    '## Pages',
    '',
    ...llms,
    '',
  ].join('\n'),
);

fs.writeFileSync(path.join(ROOT, 'src/sidebar.json'), JSON.stringify(sidebar, null, 2));
fs.writeFileSync(path.join(ROOT, 'src/products.json'), JSON.stringify(landing, null, 2));
console.log('products:', Object.keys(landing).map((k) => `${k} ${landing[k].builds.map((b) => b.build).join('/')} ${landing[k].date}`).join(' | '));
console.log('legal notices:', Object.keys(legal).join(', '));
