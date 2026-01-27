---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-01-27
commit_hash: 82335e6
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# ワークフロー用語

開発ワークフローにおけるアクションと操作。

## drive

キューに入ったチケットを一つずつ実装し、それぞれをコミット。

### 定義

driveオペレーションは`.workaholic/tickets/todo/`からチケットを順次処理します。各チケットについて、記述された変更を実装し、作業をコミットし、チケットをアーカイブします。これにより、作業が実装前に記録され、完了後にドキュメント化される構造化された開発フローが作成されます。

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「`/drive`を実行して実装」、「チケットをdriveする」

### 関連用語

- ticket、archive、commit

## archive

完了した作業を長期保存に移動。

### 定義

アーカイブは完了したチケットをアクティブキュー（`.workaholic/tickets/todo/`）からブランチ固有のアーカイブディレクトリ（`.workaholic/tickets/archive/<branch>/`）に移動します。これにより、アクティブキューをクリアしながら実装記録を保存します。archive-ticketスキルはコミット成功後にこれを自動的に処理します。

### 使用パターン

- **ディレクトリ名**: `.workaholic/tickets/archive/`、`.workaholic/tickets/archive/<branch>/`
- **ファイル名**: アーカイブされたチケットは元の名前を保持
- **コード参照**: 「チケットをアーカイブ」、「アーカイブされたチケットを確認」

### 関連用語

- ticket、drive、icebox

## sync

ドキュメントを現在の状態に合わせて更新。

### 定義

sync操作は派生ドキュメント（specs、terms）を現在のコードベースの状態を反映するように更新します。変更を記録するコミットとは異なり、syncはドキュメントの正確性を確保します。`/report`コマンドはspec-writerとterms-writerサブエージェントを介して`.workaholic/`ディレクトリ（specsとterms）を現在のコードベースと自動的に同期します。

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「docsをsyncする」、「/report中にドキュメントが同期される」

### 関連用語

- spec、terms

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

## report

包括的なドキュメントを生成し、GitHub PRを作成または更新。

### 定義

reportオペレーションは複数のドキュメントエージェントを同時にオーケストレートしてすべての成果物（changelog、story、specs、terms）を生成し、その後GitHub pull requestを作成または更新します。これはフィーチャーブランチを完了し、レビューのために準備するための主要なコマンドです。`/report`コマンドは以前の`/pull-request`コマンドを置き換え、ドキュメント生成が主要な目的であり、PR作成が最終ステップであることをより適切に反映しています。

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「`/report`を実行してPRを作成」、「Reportはドキュメントを生成」

### 関連用語

- story、changelog、spec、terms、agent、orchestrator

## concurrent-execution

パフォーマンス向上のために複数の独立したエージェントを同時に実行。

### 定義

concurrent execution（並行実行）は、異なる場所に書き込み、互いに依存関係がない複数のエージェントを並列で呼び出すパターンです。オーケストレーションコマンドは単一のメッセージで複数のTaskツール呼び出しを送信し、エージェントが同時に作業できるようにします。これにより、順次処理と比較して合計実行時間が大幅に短縮されます。

concurrent executionの例:
- `/report`はchangelog-writer、story-writer、spec-writer、terms-writer、release-readinessを同時実行

出力が先行する結果に依存する場合は、順次実行が依然として必要です（例：pr-creatorはstory-writerの後に実行される。ストーリーファイルを読み取るため）。

### 使用パターン

- **ディレクトリ名**: N/A（パターンであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「エージェントを同時実行」、「並列で呼び出す」、「同時に実行」

### 関連用語

- agent、orchestrator、Task tool

## release-readiness

ブランチがリリース可能かどうかを評価。

### 定義

release readiness（リリース準備完了度）は、ブランチの変更が即時リリースに適しているかどうかを評価するリリース前分析です。release-readinessサブエージェントは`/report`中に他のドキュメントエージェントと並行して実行され、懸念事項と指示を含む判定（ready/needs attention）を生成します。これにより、メンテナーはリリース前またはリリース後に必要なステップを理解できます。

分析は以下を考慮します：
- 破壊的変更（APIまたは設定の変更）
- 未完了の作業（TODO/FIXMEコメント）
- テストステータス（テストが存在する場合）
- セキュリティの懸念（シークレット、資格情報）

### 使用パターン

- **ディレクトリ名**: N/A（アクションであり、ストレージではない）
- **ファイル名**: 出力はストーリーのRelease Preparationセクションに表示
- **コード参照**: 「リリース準備完了度を確認」、「release-readinessエージェントが評価...」

### 関連用語

- release、story、agent
