# Starlight Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Jekyll/slate theme of docs.integrationplumbers.io with Nathan's Astro Starlight site, built from this repo's unchanged Markdown and deployed to GitHub Pages by GitHub Actions.

**Architecture:** Nathan's project (https://github.com/IntegrationPlumbers/ip-docs-starlight, commit `cb83dfc`) lands in `site/`. Its converter reads the repo root (`<product>/*.md`, `_data/*_nav.yml`, new `_data/products.yml`) and writes generated Starlight content that is never committed. A deploy workflow builds and publishes `site/dist` on every push to `main`; a PR job builds, checks links and anchors, and checks URL parity. The Jekyll files are deleted.

**Tech Stack:** Node 24, Astro 7.4, Starlight 0.42, `yaml` (already a dependency), `node:test` for tests, GitHub Actions (`actions/configure-pages`, `upload-pages-artifact`, `deploy-pages`).

**Spec:** `docs/superpowers/specs/2026-10-23-starlight-migration-design.md`

A local clone of Nathan's repo with a successful test build is at
`/private/tmp/claude-501/-Users-andrebeaumont-Projects-docs-integrationplumbers-io/48ae3641-cf61-4f49-96fc-f8b3e619c707/scratchpad/starlight-src`. If it is gone, `gh repo clone IntegrationPlumbers/ip-docs-starlight`.

## Global Constraints

- Public repo: no lab hosts, task ids, Monday links or internal paths in any committed file. `scripts/lint-docs.sh` lists the forbidden patterns.
- Node 24 everywhere (`site/.nvmrc` = `24`, `engines.node` = `>=22.12.0`, workflow uses `node-version-file: site/.nvmrc`).
- Page text, URLs and anchors do not change. The only URL change: `/<product>/` becomes `/<product>.html` with a redirect at `/<product>/index.html`.
- Generated files are never committed: `site/src/content/docs/`, `site/public/<product>/`, `site/src/sidebar.json`, `site/src/products.json`, `site/dist/`, `site/.astro/`, `site/node_modules/`.
- Nathan's `Dockerfile`, `nginx.conf`, `.dockerignore` and `scripts/package-preview.py` are not copied.
- `scripts/lint-docs.sh`, `scripts/lint-changed.sh`, `scripts/check-anchors.sh` and the four `_data/*_nav.yml` files are not modified.
- Theme mode Auto, dark base, exactly as in Nathan's `theme.css`.
- Work on branch `feature/starlight-theme` from `main`. Commit after every task.

## Review Focus

1. An upstream push adds a page to `_data/mysql_nav.yml` but the `.md` is missing: the build must fail with a message naming the page, not emit a sidebar entry to a 404. Test in Task 3.
2. An `index.md` whose release line is reformatted so no `N.N.N.N.N for Enterprise Manager X` matches: the build must fail, not ship a landing page with no versions. Test in Task 3.
3. A Zoho article or email links `/postgresql/images/<file>.png`: the file must exist in `dist` at that exact path. Test in Task 3 and Task 6.
4. A deep link `/mysql/getting-started.html#before` (kramdown custom id) and a link to a heading whose auto-slug contains punctuation: the anchor must exist in the built page. Test in Task 5.
5. Search Console fetches `/sitemap.xml` and `/robots.txt`: both must exist with the content the spec fixes. Test in Task 4.

---

### Task 1: Land Nathan's project in `site/` and prove it builds from this repo

**Files:**
- Create: `site/package.json`, `site/package-lock.json`, `site/astro.config.mjs`, `site/src/**` (all of Nathan's `src/`), `site/scripts/convert.mjs`, `site/scripts/postbuild-pages.mjs`, `site/public/CNAME`, `site/public/favicon.png`, `site/.nvmrc`
- Modify: `.gitignore` (root)

**Interfaces:**
- Produces: `npm run build` in `site/` (= convert `..` + `astro build` + postbuild) writing `site/dist/`. Later tasks change the scripts but keep the npm script names: `convert`, `build`, `dev`, `preview`, `check`, `test`.

- [ ] **Step 1: Branch**

```bash
git checkout -b feature/starlight-theme main
```

- [ ] **Step 2: Copy Nathan's project**

From the clone, copy `package.json`, `package-lock.json`, `astro.config.mjs`, `src/`, `scripts/convert.mjs`, `scripts/postbuild-pages.mjs`, `public/CNAME`, `public/favicon.png` into `site/`. Do not copy `Dockerfile`, `nginx.conf`, `.dockerignore`, `scripts/package-preview.py`, `README.md`, `node_modules/`, `dist/`, `src/content/`, `public/<product>/`.

- [ ] **Step 3: Edit `site/package.json`**

Set `"name": "ip-docs-site"`, `"private": true`, remove `main`, `keywords`, `author`, `license`, `description`. Add `"engines": { "node": ">=22.12.0" }`. Scripts:

```json
"convert": "node scripts/convert.mjs ..",
"build": "npm run convert && astro build && node scripts/postbuild-pages.mjs dist",
"dev": "npm run convert && astro dev",
"preview": "astro preview",
"check": "node scripts/check-links.mjs dist && node scripts/check-parity.mjs .. dist",
"test": "node --test test/"
```

(`check` fails until Tasks 5 and 6 exist; that is expected.) Create `site/.nvmrc` containing `24`.

- [ ] **Step 4: Make `postbuild-pages.mjs` take the dist path as `process.argv[2]`** (default `../dist` relative to the script, as now).

- [ ] **Step 5: Root `.gitignore`**

Append:

```
site/node_modules/
site/dist/
site/.astro/
site/src/content/docs/
site/src/sidebar.json
site/src/products.json
site/public/*/
```

- [ ] **Step 6: Build**

Run: `cd site && npm ci && npm run build`
Expected: converter prints `products: postgresql ... | mysql ... | mssql ... | db2 ...` and `legal notices: postgresql, mysql, mssql, db2`, no `missing media` lines; Astro prints `77 page(s) built`; `wrote product index redirects`. `git status` shows no generated files.

- [ ] **Step 7: Commit**

```bash
git add site .gitignore
git commit -m "site: add Nathan's Astro Starlight project under site/, built from the repo root"
```

---

### Task 2: Product metadata moves to `_data/products.yml`

**Files:**
- Create: `_data/products.yml`
- Modify: `site/scripts/convert.mjs`, `site/src/components/ProductMark.astro`, `site/src/components/PageTitle.astro`
- Create: `site/test/fixtures/minirepo/` (one product `pg`: `_data/products.yml`, `_data/pg_nav.yml`, `pg/index.md` with a release line `*General Availability · \`24.1.3.0.0\` for Enterprise Manager 24ai · \`13.5.17.0.0\` for Enterprise Manager 13.5*` and a `<details><summary>Legal Notice</summary>…</details>` block, `pg/getting-started.md` with a `## Before {#before}` heading, `pg/images/a.png` (any 1×1 PNG), `pg/ai/troubleshooting.md` without front matter)
- Test: `site/test/convert.test.mjs`

**Interfaces:**
- Produces: `export async function convert(srcRoot, siteRoot)` in `site/scripts/convert.mjs`. Reads `${srcRoot}/_data/products.yml`; writes `${siteRoot}/src/content/docs/**`, `${siteRoot}/public/<product>/**`, `${siteRoot}/public/llms.txt`, `${siteRoot}/src/sidebar.json`, `${siteRoot}/src/products.json`. Returns `{ products: Record<string, Product>, pages: string[] }` where `pages` is the list of dist-relative paths it expects to exist after the build (used by Task 6). Throws `Error` with a message starting `convert:` on any strictness failure (Task 3). CLI: `node scripts/convert.mjs <srcRoot>` runs `convert(srcRoot, <dir of script>/..)`, prints the error and exits 1 on throw.
- `_data/products.yml` shape, keyed by product folder:

```yaml
postgresql:
  name: PostgreSQL
  mark: Pg
  status: General Availability
  summary: Close to 200 metrics per instance, plus five advisors for plans, plan drift, workload history, indexes, and vacuum.
  supports: [PostgreSQL 14 to 18, Patroni clusters]
mssql:
  name: SQL Server
  fullName: Microsoft SQL Server
  mark: Ms
  ...
```

`name`, `mark`, `status`, `summary`, `supports` required; `fullName` optional. Values for all four products are copied verbatim from Nathan's `PRODUCTS` constant and `ProductMark.astro` labels (`Pg`, `My`, `Ms`, `Db2`). Order in the file is the order on the home page and in the sidebar switcher.

- [ ] **Step 1: Write the failing tests** in `site/test/convert.test.mjs` (use `node:test`, `node:assert/strict`; each test copies the fixture to `fs.mkdtempSync` and uses a second temp dir as `siteRoot`)

```js
test('products.json carries products.yml fields plus parsed builds and date', ...)
  // after convert(fixture, site): JSON.parse(site/src/products.json).pg deep-equals
  // { key:'pg', name:'PostgreSQL', mark:'Pg', status:'General Availability', summary:..., supports:[...],
  //   builds:[{build:'24.1.3.0.0',em:'24ai'},{build:'13.5.17.0.0',em:'13.5'}], date:'October 2026', title:'PostgreSQL Plug-in' }
test('index.mdx description, llms.txt header and legal.md headings name the products from products.yml', ...)
  // index.mdx contains 'PostgreSQL'; llms.txt line 3 contains 'PostgreSQL'; legal.md contains '## PostgreSQL plug-in'
test('a product folder with no products.yml entry fails the build', ...)
  // add dir `my/` with index.md, no yml entry: await assert.rejects(convert(...), /convert: .*my.*products\.yml/)
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `cd site && npm test`
Expected: FAIL (`convert` is not exported / `products.yml` not read).

- [ ] **Step 3: Refactor `convert.mjs`**

Wrap the script body in `export async function convert(srcRoot, siteRoot)`; replace the `PRODUCTS` constant with `YAML.parse` of `${srcRoot}/_data/products.yml`; product folders are the keys of that file, in file order; any directory under `srcRoot` that contains an `index.md` and a `_data/<dir>_nav.yml` but has no entry throws `convert: product "<dir>" has no entry in _data/products.yml`. Build the names list `names = products.map(p => p.fullName ?? p.name)` joined as `A, B, C, and D`; use it in the `index.mdx` description, the `llms.txt` blockquote, and the Legal page headings (already per product). Add the CLI guard (`import.meta.url` vs `process.argv[1]`). Write `_data/products.yml` with the four products.

- [ ] **Step 4: Components read `mark` and names from `products.json`**

`ProductMark.astro`: drop the `labels` constant; `import products from '../products.json'` and render `products[product]?.mark ?? product.slice(0, 2)`.
`PageTitle.astro` home hero lead: replace the literal product list with the same `A, B, C, and D` join over `Object.values(products)`; keep the rest of the sentence verbatim.

- [ ] **Step 5: Run tests, then a full build**

Run: `cd site && npm test && npm run build`
Expected: tests PASS; build output identical in page count (77); `dist/index.html` still lists the four products in the same order.

- [ ] **Step 6: Commit**

```bash
git add _data/products.yml site
git commit -m "site: product card metadata lives in _data/products.yml; converter is a module with tests"
```

---

### Task 3: Converter strictness and old image paths

**Files:**
- Modify: `site/scripts/convert.mjs`
- Test: `site/test/convert.test.mjs`

**Interfaces:**
- Consumes: `convert(srcRoot, siteRoot)` from Task 2.
- Produces: the same function, now also copying `${srcRoot}/<product>/images/**` to `${siteRoot}/public/<product>/images/**` unchanged (videos included; Nathan already copies videos referenced by `<video>` tags, so this supersedes that for the `images` tree). `pages` in the return value includes those image paths.

- [ ] **Step 1: Write the failing tests**

```js
test('a nav entry whose page does not exist fails the build', ...)
  // append { title: "Ghost", url: /pg/ghost.html } to pg_nav.yml: rejects /convert: nav page .*\/pg\/ghost\.html.* does not exist/
test('an index.md with no parseable release line fails the build', ...)
  // replace the release line with '*Some release*': rejects /convert: pg\/index\.md: no builds found/
test('raw images are published at their old paths', ...)
  // after convert: fs.existsSync(`${site}/public/pg/images/a.png`) and result.pages includes '/pg/images/a.png'
test('a page absent from the nav still converts and is not in sidebar.json', ...)
  // add pg/orphan.md: src/content/docs/pg/orphan.md exists; sidebar.json has no 'pg/orphan'
```

- [ ] **Step 2: Run tests, verify the three new strictness/image tests fail**

Run: `cd site && npm test`

- [ ] **Step 3: Implement** in `convert.mjs`: after reading each nav, check every `g.pages[].url` maps to an existing `.md` (strip leading `/`, `.html` → `.md`, trailing `/` → `/index.md`), else throw. After parsing `builds`, throw if empty. Copy the raw `images` tree to `public/<product>/images` with `fs.cpSync` (no filter). Push every copied file's dist path into `pages`.

- [ ] **Step 4: Run tests and build**

Run: `cd site && npm test && npm run build && ls dist/postgresql/images | head -3`
Expected: PASS; the `images` directory exists under each product in `dist`.

- [ ] **Step 5: Commit**

```bash
git add site
git commit -m "site: converter fails on missing nav pages or builds; images keep their old URLs"
```

---

### Task 4: robots.txt and sitemap.xml

**Files:**
- Create: `site/public/robots.txt`
- Modify: `site/scripts/postbuild-pages.mjs`
- Test: `site/test/postbuild.test.mjs`

**Interfaces:**
- Produces: `export function postbuild(distDir, productKeys)` in `postbuild-pages.mjs`: writes the four redirect files (as now) and copies `${distDir}/sitemap-index.xml` to `${distDir}/sitemap.xml`. CLI: `node scripts/postbuild-pages.mjs <dist>` reads product keys from `src/products.json`.

- [ ] **Step 1: Write the failing test**

```js
test('postbuild writes product redirects and sitemap.xml', ...)
  // temp dist with sitemap-index.xml containing '<x/>': after postbuild(dist, ['pg']):
  // dist/pg/index.html contains 'url=../pg.html'; dist/sitemap.xml equals '<x/>'
```

- [ ] **Step 2: Run test, verify it fails**; **Step 3: implement**; `site/public/robots.txt` content exactly:

```
User-agent: *
Allow: /
Sitemap: https://docs.integrationplumbers.io/sitemap-index.xml
```

- [ ] **Step 4: Run tests and build; verify**

Run: `cd site && npm test && npm run build && ls dist/sitemap.xml dist/robots.txt`

- [ ] **Step 5: Commit** `git commit -m "site: robots.txt and a sitemap.xml alias for Search Console"`

---

### Task 5: Internal link and anchor checker

**Files:**
- Create: `site/scripts/check-links.mjs`
- Test: `site/test/check-links.test.mjs` (fixture dist built in the test with `fs.writeFileSync`)

**Interfaces:**
- Produces: `export function checkLinks(distDir): { file: string, url: string, reason: 'missing-file' | 'missing-anchor' }[]`. Scans every `.html` under `distDir`; for each `href="…"` and `src="…"` (and `poster="…"`) that is not `http(s):`, `mailto:`, `tel:`, `data:` or `javascript:`, resolves it against the page's path (root-relative `/x` or relative `x`, `?query` stripped); a path resolves if `path`, `path.html`, or `path/index.html` exists in `distDir`; when a fragment is present and the target is an `.html` file, the target must contain `id="<fragment>"` (decoded). A bare `#frag` checks the current page. CLI exits 1 and prints one line per finding `file → url (reason)`, exits 0 with `links ok (N checked)` otherwise.

- [ ] **Step 1: Write the failing tests**

```js
test('resolves root-relative, relative, extensionless and directory links', ...)   // no findings
test('reports a link to a missing file', ...)                                       // reason 'missing-file'
test('reports a fragment whose id is not in the target page', ...)                  // reason 'missing-anchor'
test('ignores external, mailto and data URLs', ...)
```

- [ ] **Step 2: Run, verify fail**; **Step 3: implement**; **Step 4: run tests, then run against the real build**

Run: `cd site && npm test && npm run build && node scripts/check-links.mjs dist`
Expected: `links ok (N checked)`. If it reports findings, they are real regressions from the conversion: fix the converter (not the checker) or, if a finding is pre-existing in the Markdown, list it in the PR description.

- [ ] **Step 5: Commit** `git commit -m "site: internal link and anchor check over dist"`

---

### Task 6: URL parity check

**Files:**
- Create: `site/scripts/check-parity.mjs`
- Test: `site/test/check-parity.test.mjs`

**Interfaces:**
- Consumes: `convert()`'s `pages` list is not used here; parity derives expectations from the source tree so it is independent of the converter.
- Produces: `export function expectedPaths(srcRoot): string[]` listing, for each product in `_data/products.yml`: `/<p>.html`, `/<p>/index.html`, `/<p>/index.md`, and for every other `<p>/*.md`: `/<p>/<slug>.html` and `/<p>/<slug>.md`; every file under `<p>/images`, `<p>/ai`, `<p>/downloads` at its original path; plus `/index.html`, `/legal.html`, `/llms.txt`, `/sitemap.xml`, `/sitemap-index.xml`, `/robots.txt`, `/404.html`, `/CNAME`. `export function missingPaths(srcRoot, distDir, extra = []): string[]` returns expected (plus `extra`) paths absent from `distDir`. CLI: `node scripts/check-parity.mjs <srcRoot> <dist> [--urls file]`; `--urls` adds one path per line (used once with the live sitemap); exits 1 listing missing paths.

- [ ] **Step 1: Write the failing tests** against the Task 2 fixture plus a temp dist (`expectedPaths` includes `/pg/getting-started.html`, `/pg/images/a.png`, `/pg/ai/troubleshooting.md`; `missingPaths` returns `['/pg/getting-started.md']` when only that file is absent).

- [ ] **Step 2: Run, verify fail**; **Step 3: implement**; **Step 4: run tests, build, run parity, then the one-off live comparison**

```bash
cd site && npm test && npm run build && node scripts/check-parity.mjs .. dist
curl -s https://docs.integrationplumbers.io/sitemap.xml | grep -oE '<loc>[^<]+' | sed 's#<loc>https://docs.integrationplumbers.io##; s#/$#/index.html#' > /tmp/live-urls.txt
node scripts/check-parity.mjs .. dist --urls /tmp/live-urls.txt
```
Expected: both runs print `parity ok (N paths)`. (The live list has 77 entries; `/README.md` and any Jekyll-only paths it lists are expected misses and go in the PR description.)

- [ ] **Step 5: Commit** `git commit -m "site: URL parity check against the source tree"`

---

### Task 7: GitHub Actions: deploy on main, build and check on PRs

**Files:**
- Create: `.github/workflows/deploy-pages.yml`
- Modify: `.github/workflows/static-checks.yml` (add a job; leave `checks` and `docs-lint` untouched)

- [ ] **Step 1: `deploy-pages.yml`**

Triggers `push` to `main` and `workflow_dispatch`. `permissions: contents: read, pages: write, id-token: write`. `concurrency: group: pages, cancel-in-progress: false`. Job `build`: `actions/checkout@v4`, `actions/setup-node@v4` with `node-version-file: site/.nvmrc`, `cache: npm`, `cache-dependency-path: site/package-lock.json`; `npm ci`, `npm run build`, `npm run check` with `working-directory: site`; `actions/configure-pages@v5` with `enablement: true`; `actions/upload-pages-artifact@v3` with `path: site/dist`. Job `deploy`: `needs: build`, `environment: github-pages` (url from the deploy step output), `actions/deploy-pages@v4`. `timeout-minutes: 15` on both.

- [ ] **Step 2: `static-checks.yml`: add job `site-build`** with the same checkout/node/`npm ci`/`npm test`/`npm run build`/`npm run check` steps, then `actions/upload-artifact@v4` `name: site-dist`, `path: site/dist`, `retention-days: 7`. `timeout-minutes: 15`. Add a comment above it in the file's existing style saying what it gates.

- [ ] **Step 3: Validate the YAML**

Run: `python3 -c "import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]; print('ok')" .github/workflows/deploy-pages.yml .github/workflows/static-checks.yml`
Expected: `ok`. (`actionlint` if installed: no findings.)

- [ ] **Step 4: Commit** `git commit -m "ci: build and check the Starlight site on PRs; deploy it to GitHub Pages from main"`

---

### Task 8: Remove the Jekyll site and rewrite the README

**Files:**
- Delete: `_config.yml`, `_layouts/default.html`, `Gemfile`, `Gemfile.lock`, `_site/` (tracked), `assets/ip-logo-trans.png`, `assets/ip-logo-white.png`, `assets/zoom_bg_white.png`
- Keep: root `CNAME`, `scripts/`, `_data/`, all product directories, `.github/`
- Modify: `README.md`, `.gitignore` (drop the `Gemfile.lock` line)

- [ ] **Step 1: Delete** with `git rm -r` (and `git rm -r --cached _site` if `_site` is also present locally untracked, then delete it).

- [ ] **Step 2: Confirm nothing references the removed files**

Run: `grep -rnE "assets/|_layouts|_config|jekyll" --include='*.md' --include='*.yml' --include='*.sh' --include='*.mjs' --include='*.astro' . | grep -vE '^\./(docs/superpowers|site/node_modules|_site)'`
Expected: only hits inside `scripts/lint-docs.sh` comments (if any) that describe GitHub Pages behaviour; update such a comment if it is now wrong (the `ai/*.md` "no front matter" rationale still holds: the converter copies them raw).

- [ ] **Step 3: README.md**: what the repo is, that the site is Astro Starlight built from the root Markdown by `site/scripts/convert.mjs`, the layout (`<product>/*.md`, `_data/<product>_nav.yml`, `_data/products.yml`, `site/`), how pages arrive from the plug-in repos, how to preview (`cd site && npm ci && npm run build && npm run preview`), how to run tests and checks, and that merge to `main` deploys. Credit Nathan's repo. No internal hostnames or ids.

- [ ] **Step 4: Full verification**

Run: `cd site && npm ci && npm test && npm run build && npm run check && cd .. && git status --short`
Expected: all pass; status shows only intended deletions/edits, no generated files.

- [ ] **Step 5: Commit** `git commit -m "chore: remove the Jekyll site; README describes the Starlight build"`

---

### Task 9: Browser spot check and PR

**Files:** none (verification), then PR.

- [ ] **Step 1: Serve and compare**

Run: `cd site && npm run preview` (serves `dist/` on http://localhost:4321). With the `browse` skill binary at `~/.claude/skills/gstack/browse/dist/browse`, screenshot at 1400×900 and 390×844, in light and dark (`localStorage.setItem('starlight-theme','light'|'dark')` then reload), the home page and `/postgresql/getting-started.html`, `/mysql/getting-started.html`, `/mssql/getting-started.html`, `/db2/getting-started.html`, `/legal.html`. Compare against the same pages on http://ip-docs-web-ikeukj-c26849-172-233-213-159.sslip.io/. Also fetch `http://localhost:4321/mysql/ai/troubleshooting.md` and confirm it is raw Markdown, and `http://localhost:4321/mysql/` and confirm the redirect.
Expected: no visual difference beyond content newer than Nathan's build; search opens with Ctrl+K and finds "license key".

- [ ] **Step 2: Push and open the PR**

Use the `ip-dev-plugin:pr-create` skill if it fits (no Monday task id exists for this work; say so). Title: `site: replace the Jekyll theme with Nathan's Astro Starlight site, deployed from GitHub Actions`. Body: link the spec and plan, credit `IntegrationPlumbers/ip-docs-starlight@cb83dfc`, list what was left out (Dokploy files), the accepted URL change, the parity-check misses from Task 6, and the one manual step: GitHub Pages source must be "GitHub Actions" (the workflow tries `enablement: true`; if the deploy job fails on that step, a repo admin flips Settings → Pages → Source). Ask Nathan for review.

- [ ] **Step 3: After merge** (user or Nathan merges): watch the `deploy-pages` run; then verify on the live domain: home page is the new design, `/mysql/` redirects, `/mysql/getting-started.html#before` lands on the heading, `/mysql/ai/troubleshooting.md` is raw Markdown, `/sitemap.xml` and `/robots.txt` exist, search works. Update the project memory file `local_preview_procedure.md` to the npm procedure and tell the user the Zoho KB screenshot workflow now captures the new look.
