---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-01-24
commit_hash: 5275c02
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# ワークフロー用語

開発ワークフローにおけるアクションと操作。

## drive

キューに入ったチケットを一つずつ実装し、それぞれをコミット。

### 定義

driveオペレーションは`.work/tickets/`からチケットを順次処理します。各チケットについて、記述された変更を実装し、作業をコミットし、チケットをアーカイブします。これにより、作業が実装前に記録され、完了後にドキュメント化される構造化された開発フローが作成されます。

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「`/drive`を実行して実装」、「チケットをdriveする」

### 関連用語

- ticket、archive、commit

## archive

完了した作業を長期保存に移動。

### 定義

アーカイブは完了したチケットをアクティブキュー（`.work/tickets/`）からブランチ固有のアーカイブディレクトリ（`.work/tickets/archive/<branch>/`）に移動します。これにより、アクティブキューをクリアしながら実装記録を保存します。archive-ticketスキルはコミット成功後にこれを自動的に処理します。

### 使用パターン

- **ディレクトリ名**: `.work/tickets/archive/`、`.work/tickets/archive/<branch>/`
- **ファイル名**: アーカイブされたチケットは元の名前を保持
- **コード参照**: 「チケットをアーカイブ」、「アーカイブされたチケットを確認」

### 関連用語

- ticket、drive、icebox

## sync

ドキュメントを現在の状態に合わせて更新。

### 定義

sync操作は派生ドキュメント（specs、terminology）を現在のコードベースの状態を反映するように更新します。変更を記録するコミットとは異なり、syncはドキュメントの正確性を確保します。`/sync-doc-specs`と`/sync-terminology`コマンドは異なるsync操作を実行します。

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「specsをsyncする」、「`/sync-doc-specs`を実行」

### 関連用語

- spec、terminology

## release

新しいマーケットプレイスバージョンを公開。

### 定義

リリースはマーケットプレイスバージョンをインクリメントし、バージョンメタデータを更新し、変更を公開します。`/release`コマンドはセマンティックバージョニングに従ってmajor、minor、patchのバージョンインクリメントをサポートします。リリースは`.claude-plugin/marketplace.json`を更新し、適切なgitタグを作成します。

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: `.claude-plugin/marketplace.json`、`CHANGELOG.md`
- **コード参照**: 「リリースを作成」、「`/release patch`を実行」

### 関連用語

- changelog、plugin
