---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-01-25
commit_hash: a87a013
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# 成果物

開発ワークフロー中に生成されるドキュメント成果物。

## ticket

何を変更すべきかを記録し、何が起こったかを記録する実装作業リクエスト。

### 定義

チケットは実装される作業の離散的な単位を定義します。コーディング開始前に意図、コンテキスト、実装ステップを記録します。チケットは変更に焦点を当て、実装後に何が異なるべきかを記述します。アクティブな場合は`.work/tickets/`、延期された場合は`.work/tickets/icebox/`、完了した場合は`.work/tickets/archive/<branch>/`に存在します。

チケットには構造化メタデータを持つYAMLフロントマターが含まれます：

- `date`: 作成日（ISO形式）
- `author`: 作成者のGitメール
- `type`: enhancement、bugfix、refactoring、housekeepingのいずれか
- `layer`: 影響を受けるアーキテクチャレイヤー（UX、Domain、Infrastructure、DB、Config）
- `effort`: 実装にかかった時間（完了後に記入）
- `commit_hash`: 短いgitハッシュ（コミット後にアーカイブスクリプトが設定）
- `category`: Added、Changed、Removed（コミットメッセージに基づいてアーカイブスクリプトが設定）

`/ticket`で作成されたチケットファイルは`/drive`コミット時に`git add -A`で自動的に含まれます。アーカイブされると、チケットは変更メタデータの単一の真実の情報源となり、個別のchangelogファイルが不要になります。

### 使用パターン

- **ディレクトリ名**: `.work/tickets/`、`.work/tickets/archive/`
- **ファイル名**: `20260123-123456-feature-name.md`（タイムスタンプ接頭辞付き）
- **コード参照**: 「`/ticket`でチケットを作成」、「チケットをアーカイブ」

### 関連用語

- spec、story

## spec

権威あるリファレンススナップショットを提供する現状ドキュメント。

### 定義

スペックはコードベースの現在の現実をドキュメント化します。（変更を記述する）チケットとは異なり、スペックは現在存在するものを記述します。変更が行われた後に`/sync-work`で更新され、現在の状態を反映します。スペックは単一の真実の情報源を提供することで認知負荷を軽減します。

### 使用パターン

- **ディレクトリ名**: `.work/specs/`
- **ファイル名**: `architecture.md`、`api-reference.md`
- **コード参照**: 「スペックを確認して...」、「スペックを更新して反映...」

### 関連用語

- ticket、story

### 不整合

- `/ticket`コマンドの説明で「implementation spec」と言及しており、ticketとspecの用語が混同されている

## story

PR説明文の単一の真実の情報源として機能する包括的なドキュメント。

### 定義

ストーリーは、単一のブランチで複数のチケットにわたる開発作業の動機、進行、結果を統合します。ストーリーはPRワークフロー中に生成され、完全なPR説明文の内容を含みます：Summary（チケットタイトルから）、Motivation、Journey、Changes（詳細な説明）、Outcome、Performance（メトリクスと意思決定レビュー）、Notes。ストーリーの内容（YAMLフロントマターを除く）はPRボディとしてそのままGitHubにコピーされます。

ストーリーはアーカイブされたチケットから直接データを収集し、フロントマターフィールド（`commit_hash`、`category`）とコンテンツセクション（Overview、Final Report）を抽出してナラティブを構築します。

### 使用パターン

- **ディレクトリ名**: `.work/stories/`
- **ファイル名**: `<branch-name>.md`
- **コード参照**: 「ブランチストーリーは...を記録する」、「ストーリーはPRに...コピーされる」

### 関連用語

- ticket

## changelog

すべてのブランチの変更履歴を集約するルートCHANGELOG.mdファイル。

### 定義

ルート`CHANGELOG.md`はすべてのブランチにわたるすべての変更の履歴記録を維持します。エントリはPR作成時にアーカイブされたチケットから生成されます。各エントリにはコミットハッシュ、簡単な説明、元のチケットへのリンクが含まれます。ブランチchangelog（`.work/changelogs/`）はもう存在せず、チケットが変更メタデータの単一の真実の情報源として機能します。

### 使用パターン

- **ファイル名**: ルート`CHANGELOG.md`のみ
- **コード参照**: 「CHANGELOGエントリ」、「ルートCHANGELOGを更新」

### 関連用語

- ticket、story
