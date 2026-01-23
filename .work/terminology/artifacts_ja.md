---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-01-24
commit_hash: 6843f78
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# 成果物

開発ワークフロー中に生成されるドキュメント成果物。

## ticket

何を変更すべきかを記録する実装作業リクエスト。

### 定義

チケットは実装される作業の離散的な単位を定義します。コーディング開始前に意図、コンテキスト、実装ステップを記録します。チケットは変更に焦点を当て、実装後に何が異なるべきかを記述します。アクティブな場合は`.work/tickets/`、延期された場合は`.work/tickets/icebox/`、完了した場合は`.work/tickets/archive/<branch>/`に存在します。`/ticket`で作成されたチケットファイルは`/drive`コミット時に`git add -A`で自動的に含まれます。

### 使用パターン

- **ディレクトリ名**: `.work/tickets/`、`.work/tickets/archive/`
- **ファイル名**: `20260123-123456-feature-name.md`（タイムスタンプ接頭辞付き）
- **コード参照**: 「`/ticket`でチケットを作成」、「チケットをアーカイブ」

### 関連用語

- spec、story、changelog

## spec

権威あるリファレンススナップショットを提供する現状ドキュメント。

### 定義

スペックはコードベースの現在の現実をドキュメント化します。（変更を記述する）チケットとは異なり、スペックは現在存在するものを記述します。変更が行われた後に`/sync-src-doc`で更新され、現在の状態を反映します。スペックは単一の真実の情報源を提供することで認知負荷を軽減します。

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

ストーリーは、単一のブランチで複数のチケットにわたる開発作業の動機、進行、結果を統合します。ストーリーはPRワークフロー中に生成され、完全なPR説明文の内容を含みます：Summary（CHANGELOGから）、Motivation、Journey、Changes（詳細な説明）、Outcome、Performance（メトリクスと意思決定レビュー）、Notes。ストーリーの内容（YAMLフロントマターを除く）はPRボディとしてそのままGitHubにコピーされます。

### 使用パターン

- **ディレクトリ名**: `.work/stories/`
- **ファイル名**: `<branch-name>.md`
- **コード参照**: 「ブランチストーリーは...を記録する」、「ストーリーはPRに...コピーされる」

### 関連用語

- ticket、changelog

## changelog

何が変更され、なぜ変更されたかを説明するコミットレベルの変更記録。

### 定義

チェンジログはブランチごとおよびルートで集約された変更の履歴記録を維持します。各エントリにはコミットハッシュ、簡単な説明、元のチケットへのリンクが含まれます。ブランチチェンジログは`.work/changelogs/<branch>.md`に存在し、PR作成時に`CHANGELOG.md`に統合されます。

### 使用パターン

- **ディレクトリ名**: `.work/changelogs/`
- **ファイル名**: `<branch-name>.md`、ルート`CHANGELOG.md`
- **コード参照**: 「changelogに追加」、「CHANGELOGエントリ」

### 関連用語

- ticket、story
