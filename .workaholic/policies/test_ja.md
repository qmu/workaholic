---
title: Test Policy
description: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](test.md) | [Japanese](test_ja.md)

# 1. Test Policy

このドキュメントは Workaholic リポジトリで観測されるテストと検証の実践を記述します。Workaholic は従来の意味でのユニットテストや統合テストを必要とするアプリケーションコードを持たない設定・ドキュメントプロジェクト（markdown、JSON、shell script）です。

## 2. Testing Framework

[Explicit] リポジトリにテストフレームワーク（Jest、Vitest、Mocha、pytest 等）は設定されていません。テスト設定ファイルも存在しません。これは markdown と shell script のみで構成される Claude Code plugin というプロジェクトの性質と一致しています。

## 3. Testing Levels

### 3-1. 構造検証（CI）

[Explicit] `validate-plugins.yml` GitHub Action は `main` への全プッシュと pull request で構造検証を提供します。`marketplace.json` が有効な JSON であること、各 `plugin.json` が必須フィールドを含むこと、skill ファイルの存在、ディレクトリの対応を検証します。

### 3-2. ランタイム検証（Hook）

[Explicit] PostToolUse hook（`validate-ticket.sh`）が Write または Edit 操作ごとに10秒タイムアウトで実行されます。開発中の ticket frontmatter 形式と場所の継続的なランタイム検証を提供します。

### 3-3. 出力検証（Scan）

[Explicit] `validate-writer-output` skill は、README インデックス更新前に analyst subagent からの出力ファイルが存在し非空であることを検証します。

## 4. Coverage Targets

観測されません。コードカバレッジツールやターゲットは設定されていません。従来のアプリケーションコードが存在しないことを考慮すると適切です。

## 5. Observations

- [Explicit] CI パイプラインが PR ごとに JSON 構造と plugin の整合性を検証します。
- [Explicit] ランタイム hook が Claude Code セッション中に継続的な検証を提供します。
- [Explicit] scan プロセスがインデックスファイル更新前に出力を検証します。
- [Inferred] 検証戦略は、正確さが動作の正確さではなく構造的整合性（有効な JSON、必須フィールド、ファイル存在）を意味する設定重視のプロジェクトに適切です。

## 6. Gaps

- 観測されません：shell script テスト（shellcheck、bats テスト等）。
- 観測されません：markdown ファイルのリンティングやフォーマット検証。
- 観測されません：エンドツーエンド command ワークフローの統合テスト。
