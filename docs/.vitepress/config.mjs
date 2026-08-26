import { defineConfig } from 'vitepress'

// The docs site is intentionally minimal: one explanatory article plus the
// pre-existing runbooks, served from the docs/ tree as-is.
export default defineConfig({
  lang: 'ja',
  title: 'Workaholic',
  description: 'AI エージェントが開発作業を自律的に進めるための仕組みのドキュメント',
  ignoreDeadLinks: true,
  themeConfig: {
    nav: [{ text: 'ルーティンループ', link: '/routine-loop' }],
    sidebar: [
      {
        text: '解説',
        items: [{ text: 'ルーティンループ', link: '/routine-loop' }],
      },
      {
        text: 'ランブック',
        items: [
          { text: 'ループエンジニアリング', link: '/loop-engineering-workflow' },
          { text: 'プロポーザルループ', link: '/proposal-loop-runbook' },
          { text: 'ドライブループ', link: '/drive-loop-runbook' },
          { text: 'ループドリル', link: '/loop-drill-runbook' },
        ],
      },
    ],
    outline: { level: [2, 3], label: '目次' },
  },
})
