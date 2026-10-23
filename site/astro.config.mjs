import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import sidebar from './src/sidebar.json' with { type: 'json' };
import { remarkHeadingIds } from './src/plugins/remark-heading-ids.mjs';

export default defineConfig({
  site: 'https://docs.integrationplumbers.io',
  // Keep the old Jekyll URL shape (/postgresql/getting-started.html) so existing links keep working.
  build: { format: 'file', assets: 'static' },
  trailingSlash: 'ignore',
  markdown: { remarkPlugins: [remarkHeadingIds] },
  integrations: [
    starlight({
      title: 'Integration Plumbers Docs',
      description: 'Documentation for the Integration Plumbers plug-ins for Oracle Enterprise Manager.',
      logo: {
        light: './src/assets/ip-logo-light.png',
        dark: './src/assets/ip-logo-dark.png',
        alt: 'Integration Plumbers',
        replacesTitle: true,
      },
      favicon: '/favicon.png',
      customCss: ['./src/styles/theme.css'],
      sidebar,
      tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 },
      pagination: true,
      lastUpdated: false,
      credits: false,
      components: {
        Sidebar: './src/components/Sidebar.astro',
        PageTitle: './src/components/PageTitle.astro',
        Footer: './src/components/Footer.astro',
        SocialIcons: './src/components/HeaderLinks.astro',
      },
      expressiveCode: {
        themes: ['github-dark-dimmed', 'github-light'],
        styleOverrides: {
          borderRadius: '8px',
          codeFontFamily: "'IBM Plex Mono', ui-monospace, SFMono-Regular, Menlo, monospace",
          uiFontFamily: "'IBM Plex Sans', system-ui, sans-serif",
        },
      },
    }),
  ],
});
