---
title: Core Concepts
description: Fundamental building blocks of the Workaholic plugin system
category: developer
last_updated: 2026-01-23
commit_hash: a0b2b29
---

[English](core-concepts.md) | [日本語](core-concepts_ja.md)

# コアコンセプト

Workaholicプラグインシステムの基本的な構成要素。

## plugin

Claude Code機能を拡張するコマンド、スキル、ルールのモジュラーコレクション。

### 定義

プラグインは関連する機能を単一の配布可能なユニットにパッケージ化します。各プラグインは`plugins/`下に独自のディレクトリを持ち、`plugin.json`メタデータを含む`.claude-plugin/`設定フォルダを含みます。プラグインはコマンド（ユーザー呼び出し可能）、スキル（ヘルパールーチン）、ルール（ガイドライン）を定義できます。

### 使用パターン

- **ディレクトリ名**: `plugins/core/`、`plugins/tdd/`
- **ファイル名**: `plugins/<name>/.claude-plugin/plugin.json`
- **コード参照**: 「tddプラグインをインストール」、「Coreプラグインコマンド」

### 関連用語

- command、skill、rule

## command

特定のタスクを実行するユーザー呼び出し可能なスラッシュコマンド。

### 定義

コマンドはプラグインの主要なユーザーインターフェースです。ユーザーはスラッシュプレフィックスで呼び出します（例：`/commit`、`/ticket`）。各コマンドはプラグインの`commands/`ディレクトリにマークダウンファイルを持ち、その動作と指示を定義します。

### 使用パターン

- **ディレクトリ名**: `plugins/<name>/commands/`
- **ファイル名**: `commit.md`、`pull-request.md`、`sync-doc-specs.md`
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
