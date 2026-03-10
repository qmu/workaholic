---
title: Command Reference
description: Complete documentation for all Workaholic commands
category: user
modified_at: 2026-03-10T01:13:03+09:00
commit_hash: f76bde2
---

[English](commands.md) | [日本語](commands_ja.md)

# コマンドリファレンス

Workaholicは2つのpluginを提供します：チケット駆動開発workflowの**drivin**と、AI指向の探索的・創造的開発workflowの**trippin**です。

## Gitワークフローコマンド

### /report

包括的なドキュメントを生成し、プルリクエストを作成または更新します。

```bash
/report
```

コマンドは2つのフェーズでドキュメント生成を調整します。フェーズ1では4つのサブエージェントが並列実行されます：changelog-writerが`CHANGELOG.md`を更新し、spec-writerが`.workaholic/specs/`を更新し、terms-writerが`.workaholic/terms/`を更新し、release-readinessがリリース準備のための変更を分析します。フェーズ2では、story-writerがrelease-readiness出力を使用してPRナラティブを生成します。最後に、pr-creatorが生成されたストーリーをボディとして使用してGitHub PRの作成を処理します。

PRの説明にはストーリードキュメントの内容が使用されます。ストーリーには以下の11セクションが含まれます：Overview、Motivation、Journey、Changes、Outcome、Historical Analysis、Concerns、Ideas、Performance、Release Preparation、Notes。Journeyセクションには変更をテーマや関心事ごとにグループ化したMermaidフローチャート（Topic Tree）が含まれ、レビュアーにナラティブの視覚的コンテキストを提供します。Changesセクションは各チケットを時系列順に個別のサブセクションとして記載します。Release Preparationセクションにはリリース準備の判定と懸念事項、リリース前後の手順が含まれます。ストーリードキュメントは`.workaholic/stories/<branch-name>.md`に保存され、PR説明文の単一の真実の情報源として機能します。パフォーマンスメトリクスは単一セッションの作業（8時間未満）には時間を、複数日にわたる作業にはbusiness dayを使用し、意味のある速度測定を提供します。

## チケット駆動開発コマンド

### /ticket

コードベースを調査し、実装仕様を記述します。`main`または`master`ブランチで実行すると、最初に自動的にトピックブランチを作成します。

```bash
/ticket add user authentication
/ticket icebox refactor database layer
```

Claudeは既存のパターンとアーキテクチャを理解するためにコードベースを読み、詳細な実装チケットを生成します。チケットには概要、変更するキーファイル、ステップバイステップの実装計画、考慮事項が含まれます。

`main`または`master`ブランチにいる場合、Claudeはブランチタイプ（feat/fix/refact）を選択するよう求め、チケットを作成する前に`feat-20260120-205418`のようなタイムスタンプ付きブランチを作成します。

チケットはタイムスタンプ付きで`.workaholic/tickets/todo/`に保存されます。`icebox`を使用すると、後で実装するチケットを`.workaholic/tickets/icebox/`に保存できます。

### /drive

キューに入っているチケットを上から順に実装します。

```bash
/drive
/drive icebox
```

Claudeは`.workaholic/tickets/todo/`からチケットを取り出し、一つずつ実装し、承認を求め、逸脱や発見を文書化するFinal Reportを作成し、次に進む前にコミットとアーカイブを行います。`icebox`引数を使用すると、延期されたチケットから選択できます。実装が失敗した場合は「Abandon」を選択すると、変更を破棄し、失敗分析を記録して、fail ディレクトリにチケットを移動した後、次に進みます。

## ドキュメント command

### /scan

すべての`.workaholic/`ドキュメント（spec、policy、term、changelog）を更新するフルドキュメントスキャンを実行します。

```bash
/scan
```

scan commandは15のドキュメントagentを2つのフェーズで実行します。フェーズ1では3つのmanager agent（project-manager、architecture-manager、quality-manager）を並列実行し、戦略的コンテキストを確立します。フェーズ2では12のleaderおよびwriter agentを並列実行し、ドメイン固有のドキュメントを生成します。

## 探索 command（Trippin Plugin）

### /trip

Planner、Architect、Constructorの3つの協調agentによるAgent Teamsセッションを起動し、Implosive Structure workflowを通じてコンセプトを探索・開発します。

```bash
/trip design a caching layer for the API
```

commandは隔離されたgit worktreeを作成し、`.workaholic/.trips/<trip-name>/`の下にartifactディレクトリを初期化し、3つのagentチームを起動します。フェーズ1（Specification）では、agentがDirection、Model、Designのartifactを相互レビューと合意形成を通じて作成します。フェーズ2（Implementation）では、テスト計画の作成、ビルド、レビュー、検証を行います。すべての離散的なステップがtripブランチ上でgit commitを生成します。

**前提条件**: Agent Teamsが`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`で有効化されている必要があります。

## ワークフローサマリー

一般的なdrivin workflowはこれらのcommandを組み合わせます：

1. `/ticket <description>` - 実装仕様を記述（mainブランチでは自動的にブランチを作成）
2. `/drive` - チケットを実装
3. `/scan` - ドキュメントを更新
4. `/report` - ドキュメントを生成し、レビュー用のPRを作成

trippin workflowは`/trip <instruction>`を使用して協調agentによる探索的開発を行います。

各チケットは独自のコミットを取得し、CHANGELOGがPRサマリーのためにすべての変更を追跡します。
