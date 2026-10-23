# docs.integrationplumbers.io

Product documentation for the Integration Plumbers Oracle Enterprise Manager plug-ins (PostgreSQL, MySQL, SQL Server, Db2). The Markdown here is built into a static [Astro Starlight](https://starlight.astro.build) site by `site/` and published at https://docs.integrationplumbers.io.

## Layout

- `<product>/*.md`: the guide pages for one product (`postgresql`, `mysql`, `mssql`, `db2`). Each product folder has an `index.md` landing page.
- `<product>/images`, `<product>/ai`, `<product>/downloads`: screenshots and video, raw Markdown files for AI assistants, and downloadable files. They are published as-is.
- `_data/<product>_nav.yml`: the page order and sidebar grouping for one product.
- `_data/products.yml`: one entry per product, in home-page order. Fields: `name`, `mark` (short badge text), `status`, `summary`, `supports` (list), and optionally `fullName`.
- `site/`: the Starlight project. `site/scripts/convert.mjs` reads everything above and generates the site content; nothing it generates is committed.
- `scripts/`: the page lint (`lint-docs.sh`, `lint-changed.sh`, `check-anchors.sh`). CI runs them on the guide pages a PR changes.
- `CNAME`: the custom domain.

## How pages arrive

The pages are generated in each plug-in's own repository and opened here as pull requests. The Markdown and the nav files are owned upstream: do not hand-edit `_data/mysql_nav.yml`, it is generated. Fix the page or the generator in the plug-in repository instead. The rules in `scripts/lint-docs.sh` (front matter, forbidden terms, relative links, images) apply to every page.

## Preview locally

Needs Node 24 (`site/.nvmrc`).

```
cd site
npm ci
npm run build
npm run preview
```

`npm run dev` serves the site with live reload. Both commands run the converter first, so edits to the root Markdown are picked up on the next run.

## Tests and checks

Run these from `site/`:

- `npm test` runs the unit tests for the converter, the post-build step, and the two checks (`node --test`).
- `npm run check` runs against a finished build (`site/dist`). `check-links.mjs` verifies every internal link and anchor. `check-parity.mjs` verifies every URL the previous site served still exists.

The converter stops with a `convert:` error when the source tree is inconsistent:

- `nav page ... does not exist`: a nav entry points at a page that is not in the product folder.
- `product "..." has no entry in _data/products.yml`: a product folder exists but is not listed in `products.yml`.
- `<product>/index.md: no builds found`: the landing page has no release line for the converter to read.
- `product "..." ... is missing "<field>"`: a `products.yml` entry lacks a required field.

## Deploy

A push to `main` runs the `deploy-pages` workflow, which builds `site/` and publishes `site/dist` to GitHub Pages. Pull requests run the `site-build` job in `static-checks`, which runs `npm test`, builds the site, and runs `npm run check`, next to the secrets scan and the page lint. Before the first merge to `main`, a repository admin must set Settings → Pages → Source to "GitHub Actions"; until then GitHub's legacy branch build would render the repo without a theme. The `deploy` job runs only on `main`, so a manual run from another branch fails fast. If a `deploy-pages` run fails, the previous deployment stays live. To undo a bad deploy, revert the merge commit on `main`.

## Credits

The Starlight theme, components, and converter come from Nathan's project, [IntegrationPlumbers/ip-docs-starlight](https://github.com/IntegrationPlumbers/ip-docs-starlight) (commit `cb83dfc`).
