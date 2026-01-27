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

- [feat-20260128-001720_ja.md](feat-20260128-001720_ja.md) - スキル統合: 8つのユーティリティスキルを主要スキルに統合、create-branchとcreate-ticketスキルを抽出、アーキテクチャネスティングポリシーを文書化、ストーリー翻訳とマークダウンリンクを追加 - 14チケット、27コミット
- [feat-20260123-032323_ja.md](feat-20260123-032323_ja.md) - ドキュメント体験の改善と.workaholic/ディレクトリの再構成
