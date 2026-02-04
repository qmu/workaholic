---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-02-04
commit_hash:
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# ワークフロー用語

開発ワークフローにおけるアクションと操作。

## drive

driveは`.workaholic/tickets/todo/`からチケットを順次処理するオペレーションです。各チケットについて、記述された変更を実装し、ユーザー承認を要求し、作業をコミットし、チケットをアーカイブします。これにより、作業が実装前に記録され、完了後にドキュメント化される構造化された開発フローが作成されます。`/drive`コマンドで呼び出されます。関連用語：ticket、archive、commit。

## abandon

abandonは実装が実行不可能であることが判明した場合の`/drive`ワークフロー中の4つの承認オプションの1つです。選択された場合、コミットされていない実装変更を（`git restore`経由で）破棄し、何が試みられ何が失敗したかを記録するFailure Analysisセクションを要求し、チケットを`.workaholic/tickets/abandoned/`に移動し、分析を保存するためにコミットし、次のチケットに進みます。関連用語：ticket、failure-analysis、drive、approval。

## archive

archiveは完了したチケットをアクティブキュー（`.workaholic/tickets/todo/`）からブランチ固有のディレクトリ（`.workaholic/tickets/archive/<branch>/`）に移動します。これによりアクティブキューをクリアしながら実装記録を保存します。archive-ticketスキルはコミット成功後にこれを自動的に処理します。関連用語：ticket、drive、icebox。

## sync

sync操作は派生ドキュメント（specs、terms）を現在のコードベースの状態を反映するように更新します。変更を記録するコミットとは異なり、syncはドキュメントの正確性を確保します。`/report`コマンドはspec-writerとterms-writerサブエージェントを介して`.workaholic/`ディレクトリを自動的に同期します。関連用語：spec、terms。

## release

releaseはマーケットプレイスバージョンをインクリメントし、`.claude-plugin/marketplace.json`のバージョンメタデータを更新し、変更を公開します。`/release`コマンドはセマンティックバージョニングに従ってmajor、minor、patchのバージョンインクリメントをサポートし、適切なgitタグを作成します。関連用語：changelog、plugin。

## story

storyは複数のドキュメントエージェントを同時にオーケストレートしてすべての成果物（changelog、story、specs、terms）を生成し、その後GitHub pull requestを作成または更新するオペレーションです。これはフィーチャーブランチを完了し、レビューのために準備するための主要なコマンドです。`/story`コマンドは以前の`/report`コマンドを置き換え、ストーリードキュメントが中心的な成果物であることをより適切に反映しています。関連用語：changelog、spec、terms、agent、orchestrator。

## report（廃止）

reportは`/story`コマンドの以前の名前でした。機能は同じまま—ドキュメント生成とPR作成のオーケストレーション—ですが、名前は中心的な成果物としてストーリードキュメントを強調するようになりました。関連用語：story。

## workflow

Workaholicのコンテキストでは、workflowはリリースプロセスとCI/CDタスクを自動化するGitHub Actionsワークフロー（`.github/workflows/`のYAMLファイル）を指します。ワークフローは`workflow_dispatch`を介して手動で、またはタグプッシュなどのイベント上で自動的にトリガーされます。releaseワークフローはバージョンバンプ、changelogの抽出、GitHub Releaseの作成を自動化します。関連用語：release、GitHub Actions。

## concurrent-execution

concurrent executionは複数の独立したエージェントが異なる場所に書き込み、依存関係がないときに並列で呼び出されるパターンです。オーケストレーションコマンドは単一のメッセージで複数のTaskツール呼び出しを送信し、同時作業を可能にします。例：`/story`はフェーズ1でchangelog-writer、spec-writer、terms-writer、release-readinessを同時に、フェーズ2でstory-writerを順次実行します。関連用語：agent、orchestrator、Task tool。

## approval

approvalは実装後、コミット前に発生する`/drive`ワークフローの決定ポイントです。4つのオプションが提示されます：Approve（コミットして続行）、Approve and stop（コミットしてセッション終了）、Needs changes（修正を要求）、Abandon（変更を破棄、failure analysisを書き、abandonedに移動）。このゲートは正常に実装されたチケットのみがhistoryにコミットされることを確保します。関連用語：drive、ticket、abandon、commit。

## release-readiness

release readinessはブランチの変更が即時リリースに適しているかどうかを評価するリリース前分析です。release-readinessサブエージェントは`/story`中に他のドキュメントエージェントと並行して実行され、懸念事項と指示を含む判定（ready/needs attention）を生成します。分析は破壊的変更、未完了の作業、テストステータス、セキュリティの懸念を考慮します。出力はストーリーのRelease Preparationセクションに表示されます。関連用語：release、story、agent。

## prioritization

prioritizationはチケットメタデータ（type、layer、effort）を分析し、`/drive`中の最適な実行のためにチケットを順序付けするプロセスです。Claude Codeは重大度（bugfix > enhancement > refactoring > housekeeping）、コンテキストグループ化（同じレイヤーのチケットを一緒に）、労力推定に基づいて推奨順序を決定します。ユーザーは提案された順序を表示して、受け入れるか、オーバーライドするか、個別のチケットを選択できます。関連用語：drive、ticket、context-grouping、severity。

## context-grouping

context groupingはチケット優先順位付け中の最適化戦略で、同じアーキテクチャレイヤー（Config、Infrastructure、Domain）のファイルを変更するチケットをグループ化して順次処理します。これにより認知負荷とコンテキスト切り替えのオーバーヘッドが削減され、開発者は特定のコードベース領域に焦点を維持できます。関連用語：prioritization、ticket、layer。

## severity

severityはチケットタイプに基づく優先順位付けの基準です：bugfix（破損した機能に対処）が最優先度、その後enhancement（新機能）、refactoring（コード改善）、housekeeping（保守）が続きます。これにより新機能の作業に進む前に重大な問題が解決されることを確保し、本番の安定性を維持します。関連用語：prioritization、ticket、type。

## structured-commit-message

structured commit messageは単純なtitleを超えて、変更の「理由」と範囲を記録する詳細セクションを含みます。形式：title（現在形動詞）、detail（理由を説明する1-2文）、UX changes（ユーザー向け影響）、Arch changes（アーキテクチャ影響）、Co-Authored-Byトレーラー。空のセクションは「None」を使用します。`/drive`ワークフロー中に作成されるコミット。関連用語：commit、archive-ticket、format-commit-message skill。

## ux-changes

ux changesは構造化コミットメッセージの「UX:」セクションに記録されたユーザー表示影響です。これはユーザーが異なる表示またはエクスペリエンスを受け取る内容を記述します：新しいコマンド、オプション、動作、出力形式の変更、またはエラーメッセージ。ユーザー向けの変更がない場合、フィールドは「None」を含みます。ユーザーガイド更新の生成に役立ちます。関連用語：structured-commit-message、commit、arch-changes。

## arch-changes

arch changesは構造化コミットメッセージの「Arch:」セクションに記録された開発者向けおよび構造的影響です。これは新しいファイル、コンポーネント、抽象化、修正されたインターフェース、データ構造、またはワークフロー関係を記述します。アーキテクチャ変更がない場合、フィールドは「None」を含みます。仕様更新の生成に役立ちます。関連用語：structured-commit-message、commit、ux-changes。
