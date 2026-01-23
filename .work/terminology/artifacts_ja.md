---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-01-23
commit_hash: a0b2b29
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# 成果物

開発ワークフロー中に生成されるドキュメント成果物。

## ticket

何を変更すべきかを記録する実装作業リクエスト。

### 定義

チケットは実装される作業の離散的な単位を定義します。コーディング開始前に意図、コンテキスト、実装ステップを記録します。チケットは変更に焦点を当て、実装後に何が異なるべきかを記述します。アクティブな場合は`.work/tickets/`、延期された場合は`.work/tickets/icebox/`、完了した場合は`.work/tickets/archive/<branch>/`に存在します。

### 使用パターン

- **ディレクトリ名**: `.work/tickets/`、`.work/tickets/archive/`
- **ファイル名**: `20260123-123456-feature-name.md`（タイムスタンプ接頭辞付き）
- **コード参照**: 「`/ticket`でチケットを作成」、「チケットをアーカイブ」

### 関連用語

- spec、story、changelog

## spec

権威あるリファレンススナップショットを提供する現状ドキュメント。

### 定義

スペックはコードベースの現在の現実をドキュメント化します。（変更を記述する）チケットとは異なり、スペックは現在存在するものを記述します。変更が行われた後に`/sync-doc-specs`で更新され、現在の状態を反映します。スペックは単一の真実の情報源を提供することで認知負荷を軽減します。

### 使用パターン

- **ディレクトリ名**: `.work/specs/`
- **ファイル名**: `architecture.md`、`api-reference.md`
- **コード参照**: 「スペックを確認して...」、「スペックを更新して反映...」

### 関連用語

- ticket、story

### 不整合

- `/ticket`コマンドの説明で「implementation spec」と言及しており、ticketとspecの用語が混同されている

## story

ブランチでの作業の旅を記録する開発ナラティブ。

### 定義

ストーリーは、単一のブランチで複数のチケットにわたる開発作業の動機、進行、結果を統合します。ストーリーはPRワークフロー中に生成され、パフォーマンスメトリクスを含みます。将来の開発者が何が構築されたかだけでなく、なぜ、どのように決定が行われたかを理解するのに役立ちます。

### 使用パターン

- **ディレクトリ名**: `.work/stories/`
- **ファイル名**: `<branch-name>.md`
- **コード参照**: 「ブランチストーリーは...を記録する」、「ストーリーメトリクスは...を示す」

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
