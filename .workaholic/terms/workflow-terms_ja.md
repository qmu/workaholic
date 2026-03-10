---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-03-10
commit_hash: f76bde2
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# ワークフロー用語

開発ワークフローにおけるアクションと操作。

## drive

driveは`.workaholic/tickets/todo/`からチケットを順次処理するオペレーションです。各チケットについて、記述された変更を実装し、ユーザー承認を要求し、作業をコミットし、チケットをアーカイブします。これにより、作業が実装前に記録され、完了後にドキュメント化される構造化された開発フローが作成されます。`/drive`コマンドで呼び出されます。関連用語：ticket、archive、commit。

## trip

tripは3つの専門agent（Planner、Architect、Constructor）による協調的なAgent Teamsセッションを起動して、創造的な方向性を探索し実装するオペレーションです。`/trip` commandは指示を受け取り、`trip/<trip-name>`ブランチ上に隔離されたgit worktreeを作成し、`.workaholic/.trips/<trip-name>/`下にアーティファクトディレクトリを初期化し、2フェーズのワークフローをオーケストレートします：フェーズ1（Specification）ではagentが相互レビューとモデレーションを通じてDirection、Model、Designアーティファクトを生成し、フェーズ2（Implementation）ではテスト、ビルド、レビューを行います。すべてのワークフローステップは`trip(<agent>): <step>`メッセージ形式を使用してworktreeブランチにgitコミットを生成します。trippinプラグインの`/trip` commandで呼び出されます。関連用語：trippin、agent-teams、worktree、direction、model、design。

## abandon

abandonは実装が実行不可能であることが判明した場合の`/drive`ワークフロー中の4つの承認オプションの1つです。選択された場合、コミットされていない実装変更を（`git restore`経由で）破棄し、何が試みられ何が失敗したかを記録するFailure Analysisセクションを要求し、チケットを`.workaholic/tickets/abandoned/`に移動し、分析を保存するためにコミットし、次のチケットに進みます。関連用語：ticket、failure-analysis、drive、approval。

## archive

archiveは完了したチケットをアクティブキュー（`.workaholic/tickets/todo/`）からブランチ固有のディレクトリ（`.workaholic/tickets/archive/<branch>/`）に移動します。これによりアクティブキューをクリアしながら実装記録を保存します。archive-ticketスキルはコミット成功後にこれを自動的に処理します。関連用語：ticket、drive、icebox。

## sync

sync操作は派生ドキュメント（specs、terms）を現在のコードベースの状態を反映するように更新します。変更を記録するコミットとは異なり、syncはドキュメントの正確性を確保します。`/report`コマンドはspec-writerとterms-writerサブエージェントを介して`.workaholic/`ディレクトリを自動的に同期します。関連用語：spec、terms。

## release

releaseはマーケットプレイスバージョンをインクリメントし、`.claude-plugin/marketplace.json`のバージョンメタデータを更新し、変更を公開します。`/release`コマンドはセマンティックバージョニングに従ってmajor、minor、patchのバージョンインクリメントをサポートし、適切なgitタグを作成します。関連用語：changelog、plugin。

## report

reportは現在のブランチに対してstory documentを生成し、GitHub pull requestを作成または更新するオペレーションです。`/report` commandはstory-writer subagentを呼び出してブランチの作業を包括的なPR説明に統合します。story生成の前に、`/report`はCLAUDE.md Version Management規約に従って自動的にpatchバージョンのバンプを実行し、マージされるすべてのPRがGitHub releaseをトリガーすることを確保します。このコマンドは完全なドキュメントscanをトリガーせずPR作成に焦点を当てているため、`/scan`よりも高速です。関連用語：story、changelog、release、story-writer、agent。

## story（廃止）

`/story` commandは削除されました。元の目的—完全なドキュメントscanとPR作成のオーケストレーション—は2つのコマンドに分割されました：ドキュメント更新用の`/scan`とPR作成用の`/report`。この分離により明確なコマンドセマンティクスが提供され、開発者は完全なscanまたは集中的なPR準備を選択できます。関連用語：report、scan。

## workflow

Workaholicのコンテキストでは、workflowはリリースプロセスとCI/CDタスクを自動化するGitHub Actionsワークフロー（`.github/workflows/`のYAMLファイル）を指します。ワークフローは`workflow_dispatch`を介して手動で、またはタグプッシュなどのイベント上で自動的にトリガーされます。releaseワークフローはバージョンバンプ、changelogの抽出、GitHub Releaseの作成を自動化します。関連用語：release、GitHub Actions。

## concurrent-execution

concurrent executionは複数の独立したエージェントが異なる場所に書き込み、依存関係がないときに並列で呼び出されるパターンです。オーケストレーションコマンドは単一のメッセージで複数のTaskツール呼び出しを送信し、同時作業を可能にします。例：`/story`はフェーズ1でchangelog-writer、spec-writer、terms-writer、release-readinessを同時に、フェーズ2でstory-writerを順次実行します。関連用語：agent、orchestrator、Task tool。

## scan

scanは`.workaholic/`ドキュメントをすべての17のドキュメントエージェントを並列で直接呼び出して更新するオペレーションです。`/scan` commandは8つのviewpoint analyst（stakeholder、model、usecase、infrastructure、application、component、data、feature）、7つのpolicy analyst（test、security、quality、accessibility、observability、delivery、recovery）、changelog-writer、terms-writerをcommand自体の中で同時Task呼び出しとしてオーケストレートします。この直接呼び出しパターン（以前のscannerサブエージェントに置き換わる）は、ユーザーにリアルタイムのエージェント毎の進捗可視性を提供します。各エージェントはWriteとEditパーミッションを保持するために`run_in_background: false`を使用する必要があります。すべてのエージェントが完了した後、出力は検証され、インデックスファイルが更新され、変更がステージングされコミットされます。関連用語：spec、terms、policy、changelog、concurrent-execution、viewpoint-analyst、policy-analyst、run_in_background。

## approval

approvalは実装後、コミット前に発生する`/drive`ワークフローの決定ポイントです。3つの選択可能なオプションが提示されます：Approve（コミットして続行）、Approve and stop（コミットしてセッション終了）、Abandon（変更を破棄、failure analysisを書き、abandonedに移動）。ユーザーは「Other」オプションを介して自由形式のフィードバックも提供でき、これによりticket-update-firstルールがトリガーされます：コード変更の前にチケットのImplementation Stepsを更新する必要があります。以前の「Needs revision」選択可能オプションはこの自由形式フィードバックアプローチに置き換えられました。関連用語：drive、ticket、abandon、commit、feedback。

## feedback

feedbackは`/drive`承認中にユーザーが実装の変更を望むときに提供する自由形式テキストです。定義済みオプションを選択する代わりに、ユーザーは「Other」を選択してフィードバックを入力します。drive-approvalスキルはticket-update-firstルールを強制します：コード変更の前にチケットのImplementation Stepsセクションを新しいまたは修正されたステップで更新する必要があります。トレーサビリティのためにDiscussionセクションがチケットに追加され、ユーザーフィードバック、チケット更新、方向変更、実行されたアクションを記録します。関連用語：approval、drive、ticket。

## release-readiness

release readinessはブランチの変更が即時リリースに適しているかどうかを評価するリリース前分析です。release-readinessサブエージェントは`/story`中に他のドキュメントエージェントと並行して実行され、懸念事項と指示を含む判定（ready/needs attention）を生成します。分析は破壊的変更、未完了の作業、テストステータス、セキュリティの懸念を考慮します。出力はストーリーのRelease Preparationセクションに表示されます。関連用語：release、story、agent。

## prioritization

prioritizationはチケットメタデータ（type、layer、effort）を分析し、`/drive`中の最適な実行のためにチケットを順序付けするプロセスです。Claude Codeは重大度（bugfix > enhancement > refactoring > housekeeping）、コンテキストグループ化（同じレイヤーのチケットを一緒に）、労力推定に基づいて推奨順序を決定します。ユーザーは提案された順序を表示して、受け入れるか、オーバーライドするか、個別のチケットを選択できます。関連用語：drive、ticket、context-grouping、severity。

## context-grouping

context groupingはチケット優先順位付け中の最適化戦略で、同じアーキテクチャレイヤー（Config、Infrastructure、Domain）のファイルを変更するチケットをグループ化して順次処理します。これにより認知負荷とコンテキスト切り替えのオーバーヘッドが削減され、開発者は特定のコードベース領域に焦点を維持できます。関連用語：prioritization、ticket、layer。

## severity

severityはチケットタイプに基づく優先順位付けの基準です：bugfix（破損した機能に対処）が最優先度、その後enhancement（新機能）、refactoring（コード改善）、housekeeping（保守）が続きます。これにより新機能の作業に進む前に重大な問題が解決されることを確保し、本番の安定性を維持します。関連用語：prioritization、ticket、type。

## structured-commit-message

structured commit messageは単純なtitleを超えて、下流のleadエージェントにコンテキストを提供する5つの詳細セクションを含みます。形式：Title（現在形動詞、50文字以内）、Description（動機と根拠、2-3文）、Changes（ユーザーが見える違いまたは「None」）、Test Planning（実行または必要な検証）、Release Preparation（配信とサポート要件）、Co-Authored-Byトレーラー。この拡張形式は以前の4セクション形式（Motivation、UX Change、Arch Change）を置き換え、test-lead、delivery-lead、security-lead、その他のドメインleadにより良いシグナルを提供します。commitスキルは`commit.sh`を介してメッセージの構築を処理し、format-commit-messageスキルのコンテンツはcommitスキルにマージされました。関連用語：commit、archive-ticket、commit skill。

## format-commit-message（廃止）

format-commit-messageスキルはコミットメッセージのフォーマットを定義する別個のスキルで、以前は`plugins/core/skills/format-commit-message/SKILL.md`にありました。二重メンテナンス負担を排除しプリロードリストを簡素化するため、commitスキルにマージされました。commitスキルは現在、コミットメッセージフォーマットの単一の権威ある情報源として、完全なセクション毎の記述ガイドライン（Title、Description、Changes、Test Planning、Release Preparation）を含んでいます。アーカイブされたチケットとストーリーにおける履歴参照は、履歴記録であるためそのまま残されています。関連用語：commit、structured-commit-message、skill。
