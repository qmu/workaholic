---
title: Work
description: Working artifacts index for Workaholic plugin marketplace
category: developer
last_updated: 2026-01-25
commit_hash: a87a013
---

[English](README.md) | [日本語](README_ja.md)

# Work

Workaholicプラグインマーケットプレイスの作業成果物ハブです。

- [specs/](specs/README_ja.md) - 現状のリファレンスドキュメント
- [stories/](stories/README_ja.md) - ブランチごとの開発ナラティブとPRの説明文
- [terminology/](terminology/README_ja.md) - プロジェクト全体で統一された用語定義
- [tickets/](tickets/README_ja.md) - 実装作業キューとアーカイブ

## Plugins

- [Core](../plugins/core/README.md) - 完全な開発ワークフロー (`/branch`, `/commit`, `/pull-request`, `/ticket`, `/drive`, `/sync-work`)

## Design Policy

### Cognitive Investment（認知投資）

開発者の認知負荷はソフトウェア生産性における主要なボトルネックです。Workaholicは構造化された知識成果物を生成することに積極的に投資し、この負荷を軽減します。このトレードオフは意図的なものです：ドキュメント作成への先行投資は、コンテキストスイッチの削減、オンボーディングの高速化、意思決定の改善という形で還元されます。

各成果物タイプには特定の認知的目的があります：

| 成果物     | 目的                         | 認知負荷を軽減する方法               |
| ---------- | ---------------------------- | ------------------------------------ |
| Tickets    | 変更リクエスト（将来・過去） | 実装前に意図を記録                   |
| Specs      | 現状のスナップショット       | 権威あるリファレンスを提供           |
| Stories    | 開発ナラティブ               | 意思決定のコンテキストを保存         |
