---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-02-07
commit_hash: d5001a0
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# コアコンセプト

Workaholicプラグインシステムの基本的な構成要素。

## plugin

プラグインは、コマンド、スキル、ルール、エージェントを含む単一の配布可能なユニットとしてClaude Code拡張機能をパッケージ化します。各プラグインは`plugins/`下に独自のディレクトリ（例：`plugins/core/`）を持ち、`.claude-plugin/plugin.json`メタデータファイルを含みます。ドキュメントでは「coreプラグインをインストール」や「Coreプラグインコマンド」として参照されます。関連用語：command、skill、rule、agent。

## command

コマンドは特定のタスクを実行するユーザー呼び出し可能なスラッシュアクションであり、プラグインの主要なユーザーインターフェースです。ユーザーはスラッシュプレフィックス（例：`/ticket`、`/drive`、`/report`）でコマンドを呼び出します。各コマンドは`plugins/<name>/commands/`内のマークダウンファイル（`ticket.md`や`drive.md`など）で定義されます。関連用語：skill、plugin。

## skill

スキルは直接ユーザー呼び出しできないヘルパーサブルーチンで、コマンドや他の操作を内部的にサポートします。スキルは`plugins/<name>/skills/<skill-name>/`ディレクトリに定義され、`SKILL.md`定義とオプションの`sh/`シェルスクリプトディレクトリを含みます。スキルは`skills:`フロントマターフィールドを介してエージェントからプリロードできます。現在のユーティリティスキルにはarchive-ticket、create-branch、create-pr、discover-history、format-commit-message、drive-workflowがあります。コンテンツスキルにはwrite-story、write-spec、write-terms、write-changelog、create-ticketがあります。関連用語：command、plugin、agent。

## rule

ルールはプラグインのスコープ内でClaudeの動作を形成する永続的なガイドラインと制約を提供し、コーディング規約、ドキュメント要件、または動作制約を定義します。ルールは`plugins/<name>/rules/`に`general.md`や`typescript.md`などのファイルとして保存されます。関連用語：plugin、command。

## agent

エージェント（またはサブエージェント）は、特定のプロンプトとツールを持ち独自のコンテキストウィンドウで実行される特殊なAIサブプロセスで、親の会話のコンテキストを保持しながら集中タスクを処理します。エージェントは`plugins/<name>/agents/`に`spec-writer.md`、`story-writer.md`、`ticket-organizer.md`などのファイルで定義されます。コマンドはTaskツールを介してエージェントを呼び出します。一般的なタイプにはライターエージェント（ドキュメント生成）、アナリストエージェント（評価）、クリエイターエージェント（外部操作）、検索エージェント（関連作業の発見）があります。関連用語：plugin、command、skill、orchestrator。

## ticket-organizer

ticket-organizerは`/ticket`中に完全なチケット作成ワークフローを処理するサブエージェントです。機能説明を受け取り、並列発見タスク（アーカイブされたチケットの検索、ソースコードの探索、重複チェック）を実行し、適切な構造と関連履歴リンクを持つ新しいチケットファイルを作成します。`plugins/<name>/agents/ticket-organizer.md`で定義され、create-ticket、discover-history、discover-sourceスキルをプリロードします。関連用語：command、skill、ticket。

## orchestrator

オーケストレーターは複雑なワークフローを完了するために複数のエージェントを調整するコマンドで、インラインでタスクを実行する代わりに専門化された作業を委譲します。オーケストレーターは初期コンテキストを収集し、エージェントを（パフォーマンスのために並列で）呼び出し、出力を統合します。例えば、`/report`はchangelog-writer、story-writer、spec-writer、terms-writer、release-readinessを同時に、その後pr-creatorを順次オーケストレートします。これはパターンであり、ストレージ場所ではありません。関連用語：command、agent、concurrent-execution。

## deny

denyルールは`.claude/settings.json`の`permissions.deny`で設定され、サブエージェントを含むプロジェクト全体で特定のコマンドパターンをブロックするパーミッション設定です。エージェント固有の禁止事項とは異なり、denyルールは実行前に一元的に適用されます。例：`"Bash(git -C:*)"`はすべての`git -C`コマンドバリエーションをブロックします。関連用語：rule、agent。

## preload

プリロードはエージェントが初期化時にスキルコンテンツにアクセスするためのメカニズムです。エージェントの`skills:`フロントマターフィールド（例：`skills: [story-metrics, i18n]`）でスキルを指定することで、スキルのSKILL.mdコンテンツがエージェント生成時にコンテキストに含まれ、再利用可能な指示、スクリプト、フォーマットルールへのアクセスを提供します。関連用語：skill、agent、frontmatter。

## nesting-policy

nesting policyはコマンド、サブエージェント、スキル間で許可される呼び出しパターンと禁止される呼び出しパターンを定義し、オーケストレーションとナレッジの明確な分離を確保します。許可：コマンド→スキル（プリロード）、コマンド→サブエージェント（Taskツール）、サブエージェント→スキル（プリロード）、サブエージェント→サブエージェント（Taskツール）、スキル→スキル（プリロード）。禁止：スキル→サブエージェント、スキル→コマンド、サブエージェント→コマンド。指導原則は「薄いコマンドとサブエージェント（約20-100行）、包括的なスキル（約50-150行）」です。多段ネスト（例：scanner→spec-writer→architecture-analyst）は子の呼び出しが並列である場合に許容されます。ルートCLAUDE.mdのArchitecture Policyセクションにドキュメント化されています。関連用語：command、agent、skill、orchestrator。

## viewpoint

viewpointはリポジトリを特定の視点から分析するための定義済みアーキテクチャレンズです。Workaholicは8つのviewpointを定義しています：stakeholder、model、usecase、infrastructure、application、component、data、feature。各viewpointには分析プロンプト、Mermaidダイアグラムタイプ、出力セクションがあります。`/scan`中にspec-writerが8つの並列architecture-analystサブエージェントをオーケストレートし、viewpointごとに`.workaholic/specs/<slug>.md`と`<slug>_ja.md`を生成します。viewpoint定義はspec-writerエージェント（呼び出し側）に存在し、analyze-viewpointスキルが汎用分析フレームワークを提供します。関連用語：spec、architecture-analyst、analyze-viewpoint、scan。

## architecture-analyst

architecture-analystはspec-writerからviewpoint定義を受け取り、その視点からリポジトリを分析する薄いサブエージェントです。analyze-viewpointスキルを使用してコンテキストを収集し、ユーザーのCLAUDE.mdからオーバーライドを読み取り、Mermaidダイアグラムと`[Explicit]`および`[Inferred]`の知識を区別するAssumptionsセクションを含むviewpointスペックドキュメントを書き込みます。`plugins/core/agents/architecture-analyst.md`で定義されています。関連用語：viewpoint、spec-writer、analyze-viewpoint。

## policy-analyst

policy-analystはpolicy-writerからポリシードメイン定義を受け取り、そのポリシー視点からリポジトリを分析する薄いサブエージェントです。analyze-policyスキルを使用してコンテキストを収集し、観察可能なプラクティスを記録し、`[Explicit]`と`[Inferred]`のアノテーション付きでポリシードキュメントを書き込みます。証拠が見つからないギャップは省略せず「Not observed」としてマークされます。`plugins/core/agents/policy-analyst.md`で定義されています。関連用語：policy、policy-writer、analyze-policy。

## scanner

scannerは4つのドキュメントライターを並列でオーケストレートするサブエージェントです：changelog-writer、spec-writer、terms-writer、policy-writer。gitコンテキスト（ブランチ、ベースブランチ、リポジトリURL、アーカイブされたチケット）を収集し、4つのライターすべてを同時にディスパッチし、ライターごとの成功/失敗ステータスを報告します。`/scan`コマンドによって呼び出されます。`plugins/core/agents/scanner.md`で定義されています。関連用語：orchestrator、concurrent-execution、scan。

## hook

フックはClaude Codeツールライフサイクルの特定のポイントでコードを実行するコールバックメカニズムです。Workaholicはファイル操作を検証するためにPostToolUseフックを使用します。フックは`plugins/<name>/hooks/hooks.json`で設定され、マッチング条件に基づいてシェルスクリプトを実行できます。Claude Codeはマニフェストエントリなしで標準ロケーションからhooks.jsonを自動的にロードします。関連用語：rule、plugin、PostToolUse。

## PostToolUse

PostToolUseはClaude Codeツール（WriteやEditなど）が正常に完了した後にトリガーされるフックライフサイクルイベントです。Workaholicでは、PostToolUseフックはチケットファイル操作を検証し、ファイルがフォーマットと場所の要件を満たしていることを確認します。`hooks/hooks.json`マッチャー設定で参照されます。関連用語：hook、rule、plugin。

## TiDD

TiDD（Ticket-Driven Development）はチケットが計画と完了した作業の単一の真実の情報源として機能するWorkaholicのコア哲学です。外部issue trackerではなく、チケットはコードと共にリポジトリ内に存在し、何を変更すべきか（Overview、Implementation Steps）、何が起こったか（Final Report）、何を学んだか（Discovered Insights）を記録します。ワークフローは規律を強制します：計画（チケット作成）、実装（drive）、ドキュメント化（story）。README.mdとプロジェクトドキュメントで参照されます。関連用語：ticket、drive、story、archive。

## context-window

context windowはエージェントが実行中に利用可能な隔離された会話メモリです。エージェントが隔離されたコンテキストで実行されるとき、メイン会話のコンテキストウィンドウをオーケストレーション用に保持しながら、実装の詳細を専用スペースで処理し、大量のファイル読み取りや複雑な分析からのコンテキスト汚染を防ぎます。関連用語：agent、orchestrator。

## validate-writer-output

validate-writer-outputスキルは、ライターオーケストレーターにおいてアナリストサブエージェント呼び出しとREADMEインデックス更新の間にバリデーションゲートを提供します。ディレクトリパスと期待されるファイル名のリストを受け取り、各ファイルが存在し空でないことをチェックし、ファイルごとのステータスと全体の合格/不合格結果を含むJSONを出力します。spec-writerとpolicy-writerの両方がこのスキルを使用して、存在しないドキュメントへのリンクでREADMEファイルを更新することを防ぎます。`plugins/core/skills/validate-writer-output/`で定義されています。関連用語：spec-writer、policy-writer、architecture-analyst、policy-analyst。

## driver（廃止）

driverは`/drive`ワークフロー中に個別のチケットを実装するための以前の中間サブエージェントで、現在はdrive-workflowスキルに置き換えられました。このパターンは可視性を向上させ、メイン会話コンテキストで修正履歴を保持するために削除されました。`/drive`コマンドは現在drive-workflowをインラインで直接呼び出します。関連用語：drive、drive-workflow、agent。
