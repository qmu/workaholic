---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-03-10
commit_hash: f76bde2
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# コアコンセプト

Workaholicプラグインシステムの基本的な構成要素。

## plugin

プラグインは、コマンド、スキル、ルール、エージェントを含む単一の配布可能なユニットとしてClaude Code拡張機能をパッケージ化します。各プラグインは`plugins/`下に独自のディレクトリ（例：`plugins/drivin/`、`plugins/trippin/`）を持ち、`.claude-plugin/plugin.json`メタデータファイルを含みます。マーケットプレイスには現在2つのプラグインがあります：drivin（チケット駆動開発ワークフロー）とtrippin（AI指向の探索と創造的開発）。プラグイン名はCI検証のためディレクトリ名と一致する必要があります。関連用語：command、skill、rule、agent、drivin、trippin。

## drivin

drivinは主要な開発プラグイン（旧名称「core」）で、`/ticket`、`/drive`、`/report`、`/scan`、`/release`コマンドを含むチケット駆動開発ワークフローを提供します。`plugins/drivin/`に配置され、設定は`plugins/drivin/.claude-plugin/plugin.json`にあり、構造化された開発のためのすべてのagent、skill、ruleを含みます。「core」から「drivin」への改名により、すべての`subagent_type: "core:*"`参照が`"drivin:*"`に、すべてのインストール済みプラグインパスが`~/.claude/plugins/marketplaces/workaholic/plugins/core/`から`~/.claude/plugins/marketplaces/workaholic/plugins/drivin/`に更新されました。アーカイブされたチケットとストーリーの過去の参照は「core」名を保持しています。関連用語：plugin、trippin、TiDD。

## trippin

trippinは探索と創造的開発プラグインで、3つの専門agent（Planner、Architect、Constructor）による協調的なAgent Teamsセッションを起動する`/trip` commandを提供します。`plugins/trippin/`に配置され、設定は`plugins/trippin/.claude-plugin/plugin.json`にあり、`.workaholic/.trips/`でのファイルシステムベースのアーティファクト交換を通じて3つのagentが協力します。メインの作業ツリーとの干渉を防ぐため、隔離されたgit worktreeで動作します。`trip-*`ブランチプレフィックス規約はdrivinの`drive-*`ブランチと並行してプラグイン名と一致しています。関連用語：plugin、drivin、trip、worktree、agent-teams。

## agent-teams

Agent Teamsは複数のAIエージェントが独立したcontext windowで協力して作業できる実験的なClaude Code機能（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`）です。Workaholicでは、trippinプラグインの`/trip` commandがAgent Teamsを使用して3つのagent（Planner、Architect、Constructor）を起動し、直接のコンテキスト共有ではなくファイルシステムアーティファクトを通じて通信します。各agentは独立して動作し、`.workaholic/.trips/<trip-name>/`から他のagentの出力を読み取ります。関連用語：trippin、trip、context-window。

## worktree

worktreeはtrippinプラグインがtripセッションをメインの作業ツリーから隔離するために使用するgit機能です。`ensure-worktree.sh`スクリプトは現在のHEADから`trip/<trip-name>`ブランチ上の`.worktrees/trip-<trip-name>/`に専用のworktreeを作成します。この隔離により、tripの探索がメインチェックアウトの未コミット作業に影響を与えないことが保証されます。trip内のすべての個別のワークフローステップはworktreeブランチにgitコミットを生成し、協調プロセスの完全なトレースを作成します。関連用語：trippin、trip。

## command

コマンドは特定のタスクを実行するユーザー呼び出し可能なスラッシュアクションであり、プラグインの主要なユーザーインターフェースです。ユーザーはスラッシュプレフィックス（例：`/ticket`、`/drive`、`/report`）でコマンドを呼び出します。各コマンドは`plugins/<name>/commands/`内のマークダウンファイル（`ticket.md`や`drive.md`など）で定義されます。関連用語：skill、plugin。

## skill

スキルは直接ユーザー呼び出しできないヘルパーサブルーチンで、コマンドや他の操作を内部的にサポートします。スキルは`plugins/<name>/skills/<skill-name>/`ディレクトリに定義され、`SKILL.md`定義とオプションの`sh/`シェルスクリプトディレクトリを含みます。スキルは`skills:`フロントマターフィールドを介してエージェントからプリロードできます。現在のユーティリティスキルにはarchive-ticket、branching、create-pr、discover-history、drive-workflowがあります。コンテンツスキルにはwrite-story、write-spec、write-terms、write-changelog、create-ticketがあります。横断的なprincipleスキルにはmanagers-principleとleaders-principleがあります。関連用語：command、plugin、agent、principle。

## rule

ルールはプラグインのスコープ内でClaudeの動作を形成する永続的なガイドラインと制約を提供し、コーディング規約、ドキュメント要件、または動作制約を定義します。ルールは`plugins/<name>/rules/`に`general.md`や`typescript.md`などのファイルとして保存されます。関連用語：plugin、command。

## agent

エージェント（またはサブエージェント）は、特定のプロンプトとツールを持ち独自のコンテキストウィンドウで実行される特殊なAIサブプロセスで、親の会話のコンテキストを保持しながら集中タスクを処理します。エージェントは`plugins/<name>/agents/`に`spec-writer.md`、`story-writer.md`、`ticket-organizer.md`、または`architecture-manager.md`や`quality-lead.md`のような階層的エージェントなどのファイルで定義されます。コマンドはTaskツールを介してエージェントを呼び出します。一般的なタイプにはライターエージェント（ドキュメント生成）、アナリストエージェント（評価）、クリエイターエージェント（外部操作）、検索エージェント（関連作業の発見）、階層的エージェント（managerとlead）があります。エージェント階層にはmanager（戦略的出力）、lead（ドメイン固有の実装）、汎用エージェントが含まれます。関連用語：plugin、command、skill、orchestrator、manager、lead。

## ticket-organizer

ticket-organizerは`/ticket`中に完全なチケット作成ワークフローを処理するサブエージェントです。機能説明を受け取り、並列発見タスク（アーカイブされたチケットの検索、ソースコードの探索、重複チェック）を実行し、適切な構造と関連履歴リンクを持つ新しいチケットファイルを作成します。`plugins/<name>/agents/ticket-organizer.md`で定義され、branching、create-ticket、discover-history、discover-sourceスキルをプリロードします。関連用語：command、skill、ticket。

## orchestrator

オーケストレーターは複雑なワークフローを完了するために複数のエージェントを調整するコマンドで、インラインでタスクを実行する代わりに専門化された作業を委譲します。オーケストレーターは初期コンテキストを収集し、エージェントを（パフォーマンスのために並列で）呼び出し、出力を統合します。例えば、`/report`はchangelog-writer、story-writer、spec-writer、terms-writer、release-readinessを同時に、その後pr-creatorを順次オーケストレートします。これはパターンであり、ストレージ場所ではありません。関連用語：command、agent、concurrent-execution。

## deny

denyルールは`.claude/settings.json`の`permissions.deny`で設定され、サブエージェントを含むプロジェクト全体で特定のコマンドパターンをブロックするパーミッション設定です。エージェント固有の禁止事項とは異なり、denyルールは実行前に一元的に適用されます。例：`"Bash(git -C:*)"`はすべての`git -C`コマンドバリエーションをブロックします。関連用語：rule、agent。

## preload

プリロードはエージェントが初期化時にスキルコンテンツにアクセスするためのメカニズムです。エージェントの`skills:`フロントマターフィールド（例：`skills: [story-metrics, i18n]`）でスキルを指定することで、スキルのSKILL.mdコンテンツがエージェント生成時にコンテキストに含まれ、再利用可能な指示、スクリプト、フォーマットルールへのアクセスを提供します。関連用語：skill、agent、frontmatter。

## branching

branchingスキルは現在のgitブランチ状態をチェックし、必要に応じてタイムスタンプ付きトピックブランチを作成するユーティリティ操作を提供します。`plugins/drivin/skills/branching/`に定義され、バンドルされたシェルスクリプト（`sh/check.sh`、`sh/create.sh`、`sh/check-version-bump.sh`）を含み、manager tierのmanage-プレフィックス規約との命名衝突を避けるため以前のbranchingスキルから置き換えられました。このスキルはticket-organizerによってプリロードされ、バージョンバンプ検出のためにreport commandで参照されます。関連用語：skill、ticket-organizer、manager。

## constraint

constraintはleadエージェントの決定空間を狭める規範的な境界で、managers-principleで定義されたConstraint Settingワークフローに従ってmanagerエージェントによって生成されます。constraintは`.workaholic/constraints/<domain>.md`に保存され、domainはmanagerの領域（project、architecture、quality）と一致します。各constraintファイルはfrontmatter、要約、および何が制限されるか、根拠、どのleaderが影響を受けるか、反証可能な基準、レビュートリガーを指定するconstraintエントリを含む構造化されたテンプレートに従います。constraintはpolicyと意味的に異なります：constraintはmanagerによって生成された戦略的な境界で、policyは`.workaholic/policies/`に保存された実装されたプラクティスのleaderによって生成された観察的ドキュメントです。関連用語：manager、lead、managers-principle、policy。

## principle

principleはtier（managerまたはlead）のすべてのエージェントに適用される横断的な行動ルールで、生成された出力ドキュメントではなくprincipleスキルにエンコードされます。2つのprincipleスキルが存在します：managers-principle（Constraint Settingワークフロー、Strategic Focus）とleaders-principle（Prior Term Consistency、Vendor Neutrality）。「principle」という用語は、`.workaholic/policies/`で実装されたプラクティスを文書化するleaderによって生成された出力アーティファクトを指す「policy」と、これらの基本的な行動ルールを区別します。この用語の変更により、managers-principleとleaders-principleスキルがmanagers-principleとleaders-principleに名前変更されたときの意味的曖昧さが解決されました。関連用語：managers-principle、leaders-principle、policy、skill。

## nesting-policy

nesting policyはコマンド、サブエージェント、スキル間で許可される呼び出しパターンと禁止される呼び出しパターンを定義し、オーケストレーションとナレッジの明確な分離を確保します。許可：コマンド→スキル（プリロード）、コマンド→サブエージェント（Taskツール）、サブエージェント→スキル（プリロード）、サブエージェント→サブエージェント（Taskツール）、スキル→スキル（プリロード）。禁止：スキル→サブエージェント、スキル→コマンド、サブエージェント→コマンド。指導原則は「薄いコマンドとサブエージェント（約20-100行）、包括的なスキル（約50-150行）」です。多段ネスト（例：scanner→spec-writer→architecture-analyst）は子の呼び出しが並列である場合に許容されます。ルートCLAUDE.mdのArchitecture Policyセクションにドキュメント化されています。関連用語：command、agent、skill、orchestrator。

## viewpoint

viewpointはリポジトリを特定の視点から分析するための定義済みアーキテクチャレンズです。Workaholicは8つのviewpointを定義しています：stakeholder、model、usecase、infrastructure、application、component、data、feature。各viewpointには分析プロンプト、Mermaidダイアグラムタイプ、出力セクションがあります。`/scan`中にspec-writerが8つの並列architecture-analystサブエージェントをオーケストレートし、viewpointごとに`.workaholic/specs/<slug>.md`と`<slug>_ja.md`を生成します。viewpoint定義はspec-writerエージェント（呼び出し側）に存在し、analyze-viewpointスキルが汎用分析フレームワークを提供します。関連用語：spec、architecture-analyst、analyze-viewpoint、scan。

## viewpoint-analyst

viewpoint-analyst（例：stakeholder-analyst、model-analyst）は特定のviewpoint視点からリポジトリを分析する薄いサブエージェントです。analyze-viewpointスキルを使用してコンテキストを収集し、ユーザーのCLAUDE.mdからオーバーライドを読み取り、Mermaidダイアグラムと`[Explicit]`および`[Inferred]`の知識を区別するAssumptionsセクションを含むviewpointスペックドキュメントを書き込みます。8つのviewpointそれぞれに`plugins/drivin/agents/<slug>-analyst.md`で定義された専用のanalystエージェントがあります。中間のwriterを介さずscannerから直接呼び出されます。関連用語：viewpoint、scanner、analyze-viewpoint。

## policy-analyst

policy-analyst（例：test-policy-analyst、security-policy-analyst）は特定のポリシードメイン視点からリポジトリを分析する薄いサブエージェントです。analyze-policyスキルを使用してコンテキストを収集し、コードベースに実際に実装され実行可能なポリシーのみを文書化します。各ポリシーステートメントは強制メカニズム（CI check、git hook、linter rule、自動化されたscript、またはtest）を引用する必要があります。README や CLAUDE.md にのみ文書化されコード強制のない願望的なプラクティスは除外されます。証拠が見つからないギャップは省略せず「Not observed」としてマークされます。7つのポリシードメインそれぞれに`plugins/drivin/agents/<slug>-policy-analyst.md`で定義された専用のanalystエージェントがあります。中間のサブエージェントを介さず`/scan` commandから直接呼び出されます。関連用語：policy、scan、analyze-policy。

## scanner（廃止）

scannerは17のドキュメントエージェントを並列でオーケストレートしていたサブエージェントです。このオーケストレーションはリアルタイムのエージェント毎の進捗可視性を提供するために`/scan` commandに直接移行されました。scanner エージェントファイル（`plugins/drivin/agents/scanner.md`）は削除され、`/scan` commandが17すべてのエージェント（8つのviewpoint analyst、7つのpolicy analyst、changelog-writer、terms-writer）を並列Task tool呼び出しを使って直接呼び出すようになりました。この2レベルから1レベルへのネスティングの平坦化により、同じ並列実行パターンを維持しながらユーザーの透明性が向上します。関連用語：scan、orchestrator、concurrent-execution。

## run_in_background

run_in_background パラメータはコマンドをバックグラウンドで実行するかどうかを制御するBash toolのオプションです。`true`に設定すると、コマンドは非同期で実行され、完了時にユーザーに通知されます。しかし、バックグラウンド実行には重要な制約があります：バックグラウンドモードで実行されるエージェントはWriteとEdit toolのパーミッションが自動的に拒否され、ファイル操作ができなくなります。Write/Editパーミッションを必要とするscan agentや他のドキュメントwriterの場合、`run_in_background`は明示的に`false`（デフォルト）に設定する必要があります。`/scan` commandは17すべてのエージェントのTask呼び出しで`run_in_background: false`を使用しなければならないという明示的な制約を含んでいます。関連用語：agent、Task tool、scan。

## hook

フックはClaude Codeツールライフサイクルの特定のポイントでコードを実行するコールバックメカニズムです。Workaholicはファイル操作を検証するためにPostToolUseフックを使用します。フックは`plugins/<name>/hooks/hooks.json`で設定され、マッチング条件に基づいてシェルスクリプトを実行できます。Claude Codeはマニフェストエントリなしで標準ロケーションからhooks.jsonを自動的にロードします。関連用語：rule、plugin、PostToolUse。

## PostToolUse

PostToolUseはClaude Codeツール（WriteやEditなど）が正常に完了した後にトリガーされるフックライフサイクルイベントです。Workaholicでは、PostToolUseフックはチケットファイル操作を検証し、ファイルがフォーマットと場所の要件を満たしていることを確認します。`hooks/hooks.json`マッチャー設定で参照されます。関連用語：hook、rule、plugin。

## TiDD

TiDD（Ticket-Driven Development）はチケットが計画と完了した作業の単一の真実の情報源として機能するWorkaholicのコア哲学です。外部issue trackerではなく、チケットはコードと共にリポジトリ内に存在し、何を変更すべきか（Overview、Implementation Steps）、何が起こったか（Final Report）、何を学んだか（Discovered Insights）を記録します。ワークフローは規律を強制します：計画（チケット作成）、実装（drive）、ドキュメント化（story）。README.mdとプロジェクトドキュメントで参照されます。関連用語：ticket、drive、story、archive。

## context-window

context windowはエージェントが実行中に利用可能な隔離された会話メモリです。エージェントが隔離されたコンテキストで実行されるとき、メイン会話のコンテキストウィンドウをオーケストレーション用に保持しながら、実装の詳細を専用スペースで処理し、大量のファイル読み取りや複雑な分析からのコンテキスト汚染を防ぎます。関連用語：agent、orchestrator。

## manager

managerはleadの上位に位置する戦略的エージェントで、leaderが依存する高レベルの出力を生成します。managerは`.claude/rules/define-manager.md`のdefine-managerスキーマによって定義され、Role、Responsibility、Goal、Outputs、Default Policiesのセクションが必要です。3つのmanagerが存在します：project-manager（ビジネスコンテキスト、ステークホルダー、タイムライン）、architecture-manager（システム構造、コンポーネント、レイヤー）、quality-manager（品質基準、保証プロセス）。各managerは`plugins/drivin/skills/`に対応する`manage-<domain>`スキルと、`plugins/drivin/agents/*-manager.md`に薄いエージェントファイルを持ちます。managerは横断的な行動原則のためにmanagers-principleスキルをプリロードし、Constraint Settingワークフローに従って`.workaholic/constraints/<domain>.md`に構造化されたconstraintファイルを生成します。関連用語：lead、define-manager、managers-principle、constraint、agent、skill。

## lead

leadはプロジェクトの特定の側面に責任を持つドメイン固有のエージェントで、managerの出力を消費して情報に基づいたドメイン決定を行います。leadは`.claude/rules/define-lead.md`のdefine-leadスキーマによって定義され、Role、Responsibility、Goal、Default Policiesのセクションが必要です。現在のleadにはarchitecture-lead、security-lead、quality-lead、test-lead、a11y-lead、ux-lead、db-lead、delivery-lead、infra-lead、observability-lead、recovery-leadが含まれます。各leadは`plugins/drivin/skills/`に対応する`lead-<speciality>`スキルと、`plugins/drivin/agents/*-lead.md`に薄いエージェントファイルを持ちます。leadはPrior Term Consistencyを含む横断的な行動原則のためにleaders-principleスキルをプリロードします。関連用語：manager、define-lead、leaders-principle、agent、skill。

## define-manager

define-managerは`.claude/rules/define-manager.md`にあるスキーマ強制ルールで、managerスキルとエージェントファイルの構造を検証します。フロントマターを介したpath-scopedにより`plugins/drivin/skills/manage-*/SKILL.md`と`plugins/drivin/agents/*-manager.md`に適用されます。スキーマは5つのセクション（Role、Responsibility、Goal、Outputs、Default Policies）と4つのポリシーサブセクション（Implementation、Review、Documentation、Execution）を要求します。Outputsセクションはmanagerに固有で、leaderが消費する構造化された成果物を定義します。関連用語：manager、define-lead、schema、rule。

## define-lead

define-leadは`.claude/rules/define-lead.md`にあるスキーマ強制ルールで、leadスキルとエージェントファイルの構造を検証します。フロントマターを介したpath-scopedにより`plugins/drivin/skills/lead-*/SKILL.md`と`plugins/drivin/agents/*-lead.md`に適用されます。スキーマは4つのセクション（Role、Responsibility、Goal、Default Policies）と4つのポリシーサブセクション（Implementation、Review、Documentation、Execution）を要求します。define-managerと異なり、leadはドメイン固有のドキュメントを生成するため戦略的成果物ではなくOutputsセクションを持ちません。関連用語：lead、define-manager、schema、rule。

## managers-principle

managers-principleはすべてのmanagerエージェントがプリロードする横断的な行動原則スキルで、leaders-principleと並行しています。`plugins/drivin/skills/managers-principle/SKILL.md`で定義され、2つの原則セクションを含みます：Constraint Setting（制約の特定、提案、生成のためのワークフロー）とStrategic Focus（managerはleaderが消費可能な実行可能な出力を生成し、願望的なステートメントではない）。各managerエージェントはフロントマターで最初にプリロードするスキルとしてmanagers-principleをリストします。関連用語：manager、leaders-principle、skill、principle。

## leaders-principle

leaders-principleはすべてのleadエージェントがプリロードする横断的な行動原則スキルで、managers-principleと並行しています。`plugins/drivin/skills/leaders-principle/SKILL.md`で定義され、Prior Term ConsistencyとVendor Neutralityの原則を含みます。Prior Term Consistencyはleadが既存の用語を尊重し、複数語の表現よりも1語を好み、成果物全体で普遍的な言語を維持することを要求します。各leadエージェントはフロントマターで最初にプリロードするスキルとしてleaders-principleをリストします。関連用語：lead、managers-principle、skill、principle。

## driver（廃止）

driverは`/drive`ワークフロー中に個別のチケットを実装するための以前の中間サブエージェントで、現在はdrive-workflowスキルに置き換えられました。このパターンは可視性を向上させ、メイン会話コンテキストで修正履歴を保持するために削除されました。`/drive`コマンドは現在drive-workflowをインラインで直接呼び出します。関連用語：drive、drive-workflow、agent。
