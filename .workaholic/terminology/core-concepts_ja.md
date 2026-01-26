---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-01-27
commit_hash: b262207
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# コアコンセプト

Workaholicプラグインシステムの基本的な構成要素。

## plugin

Claude Code機能を拡張するコマンド、スキル、ルール、エージェントのモジュラーコレクション。

### 定義

プラグインは関連する機能を単一の配布可能なユニットにパッケージ化します。各プラグインは`plugins/`下に独自のディレクトリを持ち、`plugin.json`メタデータを含む`.claude-plugin/`設定フォルダを含みます。プラグインはコマンド（ユーザー呼び出し可能）、スキル（ヘルパールーチン）、ルール（ガイドライン）、エージェント（特殊なサブエージェント）を定義できます。

### 使用パターン

- **ディレクトリ名**: `plugins/core/`
- **ファイル名**: `plugins/<name>/.claude-plugin/plugin.json`
- **コード参照**: 「coreプラグインをインストール」、「Coreプラグインコマンド」

### 関連用語

- command、skill、rule、agent

## command

特定のタスクを実行するユーザー呼び出し可能なスラッシュコマンド。

### 定義

コマンドはプラグインの主要なユーザーインターフェースです。ユーザーはスラッシュプレフィックスで呼び出します（例：`/commit`、`/ticket`）。各コマンドはプラグインの`commands/`ディレクトリにマークダウンファイルを持ち、その動作と指示を定義します。

### 使用パターン

- **ディレクトリ名**: `plugins/<name>/commands/`
- **ファイル名**: `commit.md`、`pull-request.md`、`sync-work.md`
- **コード参照**: 「`/commit`を実行して...」、「`/ticket`コマンド...」

### 関連用語

- skill、plugin

## skill

直接ユーザー呼び出しできないヘルパーサブルーチン。

### 定義

スキルはコマンドや他の操作をサポートする内部ルーチンです。コマンドとは異なり、ユーザーはスラッシュプレフィックスでスキルを直接呼び出すことはできません。通常、コマンドによって呼び出されるか、自動的にトリガーされます。スキルはプラグインの`skills/`ディレクトリで定義されます。

### 使用パターン

- **ディレクトリ名**: `plugins/<name>/skills/`
- **ファイル名**: `archive-ticket.md`
- **コード参照**: 「archive-ticketスキルは...を処理する」

### 関連用語

- command、plugin

## rule

プラグインコンテキスト内でClaudeの動作を形成するガイドラインと制約。

### 定義

ルールはプラグインのスコープ内で作業する際にClaudeが従う永続的なガイドラインを提供します。コーディング規約、ドキュメント要件、または動作制約を定義します。ルールはプラグインの`rules/`ディレクトリに保存されます。

### 使用パターン

- **ディレクトリ名**: `plugins/<name>/rules/`
- **ファイル名**: `general.md`、`typescript.md`
- **コード参照**: 「generalルールに従って...」

### 関連用語

- plugin、command

## agent

フォーカスされたタスクを独自のコンテキストウィンドウで処理するために生成される特殊なサブエージェント。

### 定義

エージェント（サブエージェントとも呼ばれる）は特定のプロンプトとツールを持つAIサブプロセスで実行されます。親の会話のコンテキストを保持しながら、大量のファイル読み取りや複雑な分析を独自のコンテキストウィンドウで実行します。コマンドはTaskツールを介してエージェントを呼び出し、構造化された出力を受け取ります。エージェントは他のエージェントを呼び出すこともできます（サブエージェントチェーン）。エージェントはプラグインの`agents/`ディレクトリで定義されます。

一般的なエージェントタイプ:
- **ライターエージェント**: ドキュメントを生成（spec-writer、terminology-writer、story-writer、changelog-writer）
- **アナリストエージェント**: 評価と分析を実行（performance-analyst）
- **クリエイターエージェント**: 外部操作を実行（pr-creator）

### 使用パターン

- **ディレクトリ名**: `plugins/<name>/agents/`
- **ファイル名**: `performance-analyst.md`、`spec-writer.md`、`story-writer.md`、`changelog-writer.md`、`pr-creator.md`、`terminology-writer.md`
- **コード参照**: 「story-writerエージェントを呼び出す」、「changelog-writerエージェントが処理する...」、「Taskツールでエージェントを起動」

### 関連用語

- plugin、command、skill、orchestrator

## orchestrator

複雑なワークフローを完了するために複数のエージェントを調整するコマンド。

### 定義

オーケストレーターは、インラインでタスクを実行する代わりに、専門化された作業を複数のエージェントに委譲するコマンドです。オーケストレーターは初期コンテキストを収集し、エージェントを（パフォーマンスのために並列で）呼び出し、その出力を統合します。このパターンは、複雑なマルチステップワークフローを可能にしながら、メイン会話のコンテキストウィンドウを保持します。

例:
- `/sync-workaholic`はspec-writerとterminology-writerを並列でオーケストレート
- `/pull-request`はchangelog-writer、story-writer、spec-writer、terminology-writerを同時に、その後pr-creatorを順次オーケストレート

### 使用パターン

- **ディレクトリ名**: N/A（パターンであり、ストレージではない）
- **ファイル名**: N/A
- **コード参照**: 「コマンドはオーケストレーターとして機能する」、「エージェントを並列でオーケストレート」

### 関連用語

- command、agent、concurrent execution
