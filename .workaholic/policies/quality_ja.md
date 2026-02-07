---
title: Quality Policy
description: Code quality standards, linting, formatting, and review processes
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](quality.md) | [Japanese](quality_ja.md)

# 1. Quality Policy

このドキュメントは Workaholic リポジトリで観測されるコード品質の実践を記述します。Workaholic の品質保証は従来のリンティングやフォーマットツールではなく、アーキテクチャ規約、rule ファイル、AI 駆動レビューに依存しています。

## 2. Architectural Quality Standards

### 2-1. 設計原則

[Explicit] アーキテクチャは `CLAUDE.md` に文書化された「薄い command と subagent、包括的な skill」原則に従います。Command は約50-100行、subagent は20-40行、skill は50-150行です。

### 2-2. Nesting Policy

[Explicit] 厳格なコンポーネント nesting 階層が循環依存を防ぎます。これはランタイムチェックではなくドキュメント規約によって強制されます。

### 2-3. Shell Script Principle

[Explicit] 複雑なインライン shell command は agent および command markdown ファイルで禁止されています。すべてのマルチステップまたは条件付き shell 操作は `skills/<name>/sh/<script>.sh` に抽出する必要があります。

## 3. Formatting Standards

### 3-1. 見出し番号付け

[Explicit] H2 と H3 見出しは番号付き形式を使用：`## 1. Section`、`### 1-1. Subsection`。

### 3-2. ファイル命名

[Explicit] ファイルは kebab-case 命名を使用し、`README.md` と `README_ja.md` は例外です。

### 3-3. 記述言語

[Explicit] `.workaholic/` 外のすべてのコード、コメント、コミットメッセージ、PR、ドキュメントは英語でなければなりません。

## 4. Review Processes

### 4-1. Human-in-the-Loop Approval

[Explicit] `/drive` での ticket 実装はコミット前に developer の明示的な承認が必要です。

### 4-2. Performance Analysis

[Explicit] `performance-analyst` subagent が `/report` 中に意思決定品質を評価します。

## 5. Observations

- [Explicit] 品質は自動ツールではなくアーキテクチャ規約とドキュメントルールで強制されます。
- [Explicit] Mermaid ダイアグラムが視覚的ドキュメントに必須で、ASCII アートは禁止されています。
- [Inferred] AI 駆動レビューへの依存は、AI 拡張開発ワークフローとしてのプロジェクトの性質を反映しています。

## 6. Gaps

- 観測されません：shellcheck や shell script リンティング。
- 観測されません：markdown リンティング（markdownlint、remark-lint）。
- 観測されません：nesting ポリシーやサイズ制約の自動チェック。
