---
title: Recovery Policy
description: Backup, disaster recovery, and data restoration practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](recovery.md) | [Japanese](recovery_ja.md)

# 1. Recovery Policy

このドキュメントは Workaholic リポジトリで観測されるバックアップ、リカバリ、データ復元の実践を記述します。データベースや永続サービスを持たない git バージョン管理プロジェクトとして、リカバリは完全に git 履歴と GitHub のインフラストラクチャに依存しています。

## 2. Version Control as Backup

### 2-1. Git History

[Explicit] すべてのプロジェクトデータ（markdown ドキュメント、JSON 設定、shell script）は git でバージョン管理されています。すべての変更は原子的コミットとして記録され、完全な監査証跡と `git checkout` や `git revert` による任意の以前の状態の復元機能を提供します。

### 2-2. Remote Backup

[Explicit] リポジトリは GitHub（`https://github.com/qmu/workaholic`）でホストされ、プロジェクト全体の履歴のリモートバックアップを提供します。

### 2-3. Ticket Archival

[Explicit] 完了した ticket は削除されるのではなく `.workaholic/tickets/archive/<branch>/` にアーカイブされます。すべての変更要求の完全な履歴を保持します。

## 3. Error Recovery

### 3-1. Shell Script Safety

[Explicit] すべての shell script は `set -eu`（厳格モード）を使用し、部分的な実行がシステムを不整合な状態に置くことを防ぎます。

### 3-2. Validation Before Update

[Explicit] `validate-writer-output` skill が README インデックスファイル更新前に出力ファイルの存在と非空を確認します。

### 3-3. Approval Gate

[Explicit] `/drive` command が各 ticket の実装のコミット前に developer の明示的な承認を要求します。

### 3-4. Abandon Option

[Explicit] `/drive` 中の "Abandon" オプションにより、実装できない ticket をスキップし、失敗分析を生成して abandoned ディレクトリに移動できます。

## 4. Observations

- [Explicit] git バージョニングが復元機能付きの完全なプロジェクト履歴を提供します。
- [Explicit] ticket アーカイブがすべての変更要求履歴を保持します。
- [Explicit] shell script の安全性（`set -eu`）が部分的な障害を防ぎます。
- [Inferred] プロジェクトの純粋なファイルアーキテクチャ（データベースなし、サービスなし）は、リカバリがリポジトリのクローンと同じくらいシンプルであることを意味し、正式な災害復旧計画を不要にしています。

## 5. Gaps

- 観測されません：正式なバックアップ検証やリストアテスト。
- 観測されません：一般的な障害シナリオの文書化されたリカバリ手順。
- 観測されません：リポジトリに見えるブランチ保護ルール（GitHub 上で設定されている可能性あり）。
