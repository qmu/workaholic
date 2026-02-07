---
title: Observability Policy
description: Logging, monitoring, metrics, and tracing practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](observability.md) | [Japanese](observability_ja.md)

# 1. Observability Policy

このドキュメントは Workaholic リポジトリで観測される可観測性の実践を記述します。Workaholic は従来のアプリケーション監視を持ちませんが、開発ナラティブ生成と story ドキュメントに埋め込まれたパフォーマンスメトリクスを通じて可観測性を実現しています。

## 2. Development Metrics

### 2-1. Performance Analysis

[Explicit] `performance-analyst` subagent が `/report` 生成中に意思決定品質を評価します。

### 2-2. Story Metrics

[Explicit] `write-story` skill が `started_at` と `ended_at` タイムスタンプ、ticket 数、commit 数、マルチデイ作業の営業日計算を含む story を生成します。

### 2-3. Changelog Tracking

[Explicit] `write-changelog` skill がアーカイブされた ticket からカテゴリ分けされた changelog エントリ（Added、Changed、Removed）を生成し、commit と ticket へのリンク付きの監査証跡を提供します。

## 3. Tracing

### 3-1. Ticket Traceability

[Explicit] すべての実装は ticket ライフサイクルを通じてトレース可能です：`todo/` での作成、`/drive` 中の実装、final report の追記、`archive/<branch>/` へのアーカイブ。

### 3-2. Concerns Traceability

[Explicit] ticket の concerns セクションは設計決定を起源まで遡るための識別可能な参照（`[Explicit]` または `[Inferred]` 接頭辞）を使用します。

## 4. Monitoring

観測されません。アプリケーション監視、アラート、ヘルスチェックインフラストラクチャは存在しません。永続的なサービスではなく Claude Code セッション内で実行される開発ツールとして適切です。

## 5. Observations

- [Explicit] 開発の可観測性は各ブランチの完全なナラティブを記録する story ドキュメントによって達成されます。
- [Explicit] changelog エントリが commit と ticket リンク付きのカテゴリ分けされた監査証跡を作成します。
- [Inferred] 可観測性モデルはリアルタイムではなく回顧的で、ライブ監視ではなく story と changelog による事後分析に焦点を当てています。

## 6. Gaps

- 観測されません：shell script やエージェント実行からの構造化ログ。
- 観測されません：テレメトリや使用分析。
- 観測されません：セッション間のエラー率追跡や障害監視。
