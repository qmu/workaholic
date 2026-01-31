---
title: Stories
description: Branch development narratives that serve as PR descriptions
category: developer
modified_at: 2026-01-26T14:30:00+09:00
commit_hash: 5452b2d
---

[English](README.md) | [日本語](README_ja.md)

# ストーリー

このディレクトリには、PRの説明文の単一の真実の情報源として機能する包括的なストーリードキュメントが含まれています。各ストーリーはアーカイブされたチケットとCHANGELOGエントリを完全なPR対応ドキュメントに統合します。

## 目的

ストーリーはファイルとして保存されたPRの説明文です。プルリクエストを作成する際、`/pull-request`コマンドはストーリーファイルを生成し、その内容を直接GitHubにコピーします。これにより、ストーリー生成とPR説明文の組み立ての間の重複が排除されます。

ストーリーは複数の目的を果たします：

- **PR説明文**: 内容はGitHub PRボディに直接コピーされる
- **履歴記録**: 将来の参照のためにリポジトリに保存
- **レビュアーコンテキスト**: 一連の作業の背後にある「なぜ」を説明

## ストーリーフォーマット

ストーリーはメトリクス用のYAMLフロントマターを含み、その後にPRボディを形成する7つのセクションが続きます：

```markdown
---
branch: <branch-name>
started_at: YYYY-MM-DDTHH:MM:SS+TZ
ended_at: YYYY-MM-DDTHH:MM:SS+TZ
tickets_completed: <count>
commits: <count>
duration_hours: <number>
velocity: <number>
---

Refs #<issue-number>

## Summary

[CHANGELOGからの変更の番号付きリスト]

## Motivation

[なぜこの作業が必要だったか]

## Journey

[作業がどのように進んだか]

## Changes

[各変更の詳細な説明]

## Outcome

[何が達成されたか]

## Performance

[メトリクス、ペース分析、意思決定レビュー]

## Notes

[レビュアーへの追加コンテキスト]
```

## ストーリー

- [feat-20260131-125844_ja.md](feat-20260131-125844_ja.md) - Skill モジュール化と並列最適化による architectural 改善: skill-to-skill nesting、drive-workflow を 4 つの skill に分割、isolated context 用の driver agent、performance-analyst を Phase 1 並列実行に移動、generate-changelog を統合、intelligent ticket prioritization、structured commit message、selective option 強制、dependency graph 再構成 - 19チケット、36コミット
- [feat-20260129-023941_ja.md](feat-20260129-023941_ja.md) - コアインフラストラクチャ改善とリリース自動化: 実用的なリリース準備評価、/ticket command への並列ソース検出、ticket 検証 hook、README での SDD 用語の明確化、GitHub Actions リリース workflow、パス参照の修正、Mermaid diagram レンダリング改善 - 10チケット、21コミット
- [feat-20260128-220712_ja.md](feat-20260128-220712_ja.md) - TiDD 哲学フレームワーク、command 単純化、検出ツール：TiDD 哲学で README を書き直し、/report を /story にリネーム、ディレクトリ構造をフラット化、branch 作成を /ticket に統合、history-discoverer subagent を追加、command-flows specification を作成、approval loop を単純化 - 8チケット、15コミット
- [feat-20260128-012023_ja.md](feat-20260128-012023_ja.md) - ドキュメント明確化、ワークフロー強化、技術的最適化: README に Motivation セクション追加、Cultivating Semantics 用語、numbered headings 形式化、失敗分析付き Abandon ワークフロー、Haiku subagent 最適化 - 9チケット、20コミット
- [feat-20260128-001720_ja.md](feat-20260128-001720_ja.md) - スキル統合: 8つのユーティリティスキルを主要スキルに統合、create-branchとcreate-ticketスキルを抽出、アーキテクチャネスティングポリシーを文書化、ストーリー翻訳とマークダウンリンクを追加 - 14チケット、27コミット
- [feat-20260123-032323_ja.md](feat-20260123-032323_ja.md) - ドキュメント体験の改善と.workaholic/ディレクトリの再構成
