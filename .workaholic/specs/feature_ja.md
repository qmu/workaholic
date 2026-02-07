---
title: Feature Viewpoint
description: Feature inventory, capability matrix, and configuration
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](feature.md) | [Japanese](feature_ja.md)

# 1. Feature Viewpoint

Feature Viewpoint は、Workaholic plugin が提供する機能のインベントリを command 別および横断的関心事別に整理し、システムが何をできるか、機能がどのように設定されるか、各機能がどこに実装されているかを文書化します。

## 2. Command Features

### 2-1. Ticket 作成（/ticket）

| 機能 | 説明 | 実装 |
| --- | --- | --- |
| 自然言語入力 | 自由形式の変更説明を受け付け | `ticket.md` command |
| 並列ディスカバリー | コードベース、ticket、履歴を同時に探索 | `ticket-organizer` agent |
| 重複検出 | 同じ変更の既存 ticket を特定 | `ticket-discoverer` agent |
| 関連履歴 | コンテキストのための歴史的 ticket へのリンク | `history-discoverer` agent |
| Frontmatter 検証 | 書き込みごとに ticket 構造を検証 | `hooks.json` PostToolUse hook |
| 自動ブランチ作成 | main で実行時にブランチを作成 | `manage-branch` skill |
| 著者検証 | git メールを使用、Anthropic アドレスを拒否 | `create-ticket` skill |

### 2-2. Ticket 実装（/drive）

| 機能 | 説明 | 実装 |
| --- | --- | --- |
| インテリジェント優先順位付け | 依存関係と影響度で ticket を並べ替え | `drive-navigator` agent |
| 順次実装 | ticket を1つずつ処理 | `drive-workflow` skill |
| Human-in-the-loop 承認 | ticket ごとに明示的承認を要求 | `drive-approval` skill |
| フィードバックループ | 再実装のための自由形式フィードバックを受け付け | `drive-approval` skill |
| 分析付き放棄 | 放棄時に失敗分析を生成 | `drive-approval` skill |
| 最終レポート | 実装サマリーを ticket に追記 | `write-final-report` skill |
| 自動アーカイブ | 承認された ticket をコミット付きでアーカイブ | `archive-ticket` skill |
| 継続ループ | 各バッチ後に新 ticket を再チェック | `drive.md` Phase 3 |
| Icebox 処理 | オプションで延期された ticket を処理 | `drive-navigator` agent |

### 2-3. ドキュメント更新（/scan）

| 機能 | 説明 | 実装 |
| --- | --- | --- |
| 8つの viewpoint spec | 8つの視点からのアーキテクチャ分析 | 8つの `*-analyst` agent |
| 7つの policy ドキュメント | 7つのドメインにわたるリポジトリ実践分析 | 7つの `*-policy-analyst` agent |
| Changelog 生成 | アーカイブされた ticket からカテゴリ別エントリ | `changelog-writer` agent |
| Terms 更新 | 一貫した用語管理 | `terms-writer` agent |
| 並列実行 | 17のエージェントすべてが同時実行 | `scanner` agent |
| 出力検証 | インデックス更新前にファイル存在を確認 | `validate-writer-output` skill |
| i18n ミラーリング | すべてのドキュメントの日本語翻訳 | `translate` skill |

### 2-4. レポート生成（/report）

| 機能 | 説明 | 実装 |
| --- | --- | --- |
| Story 生成 | ナラティブ開発履歴 | `story-writer` agent |
| パフォーマンス分析 | 意思決定品質評価 | `performance-analyst` agent |
| PR 作成/更新 | GitHub pull request 管理 | `pr-creator` agent |
| リリース準備 | リリース準備状況の評価 | `release-readiness` agent |

## 3. Cross-Cutting Features

### 3-1. 国際化

`.workaholic/` 内のすべてのドキュメントは対応する `_ja.md` 日本語翻訳を持つ必要があります。`translate` skill がコードブロック、frontmatter キー、ファイルパス、技術用語を保持しながら散文コンテンツを翻訳するポリシーを提供します。

### 3-2. Shell Script バンドリング

すべてのマルチステップまたは条件付き shell 操作は `skills/<name>/sh/<script>.sh` のバンドルスクリプトに抽出されます。

### 3-3. 検証

システムは複数の検証レイヤーを含みます：ticket frontmatter の PostToolUse hook、JSON マニフェストと plugin 構造の CI workflow、scan 中の README インデックス更新前の出力検証。

## 4. Configuration

| メカニズム | 場所 | 目的 |
| --- | --- | --- |
| `CLAUDE.md` | リポジトリルート | プロジェクト全体の指示とアーキテクチャポリシー |
| `marketplace.json` | `.claude-plugin/` | Marketplace メタデータとバージョン |
| `plugin.json` | `plugins/core/.claude-plugin/` | Plugin メタデータとバージョン |
| `hooks.json` | `plugins/core/hooks/` | PostToolUse hook 設定 |
| `settings.json` | `.claude/` | Claude Code ランタイム設定 |
| Rule ファイル | `plugins/core/rules/` | パス固有の動作制約 |

## 5. Assumptions

- [Explicit] 機能セットは command ファイル、agent 定義、skill ドキュメントから導出されています。
- [Explicit] scan での17の並列エージェント、4つの command、完全な agent インベントリはソースファイルに文書化されています。
- [Explicit] README.md の git 警告は Workaholic の自律的 git 操作を明示的に述べています。
- [Inferred] 機能セットは ticket-driven development を通じて有機的に成長しており、CHANGELOG.md に複数ブランチにわたる反復的な追加と改良が示されています。
- [Inferred] 一部の機能（`/release` command など）は `CLAUDE.md` で言及されていますが command ファイルとしては存在せず、専用 command ではなく会話レベルの指示で処理される可能性を示唆しています。
