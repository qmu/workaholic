---
title: Test Policy
description: The verification and validation strategy -- testing levels, coverage targets, and processes that ensure correctness
category: developer
modified_at: 2026-02-09T12:00:00+09:00
commit_hash: d627919
---

[English](test.md) | [Japanese](test_ja.md)

# Test Policy

このドキュメントは Workaholic リポジトリのテストおよび検証の実践を記述します。Workaholic は markdown ファイル、JSON 設定、shell script から構成される設定・ドキュメントプロジェクトです。従来のユニットテストや統合テストではなく、構造検証、ランタイム hook、出力検証に依存しています。

## Testing Framework

テストフレームワークは設定されていません。テスト設定ファイル（jest.config、vitest.config、playwright.config、cypress.config）は存在しません。これは設定・ドキュメント成果物のみで構成される Claude Code plugin marketplace としてのプロジェクトの性質に合致しています。

## Testing Levels

### 構造検証（CI）

`.github/workflows/validate-plugins.yml` workflow が main branch への全 push と pull request で実行されます。4つの検証ステップを実行します：

1. `.claude-plugin/marketplace.json` が `jq empty` を使用して有効な JSON であることを検証
2. 各 `plugins/*/.claude-plugin/plugin.json` が有効な JSON であり必須の `name` および `version` フィールドを含むことを検証
3. `plugin.json` ファイルで宣言された全 skill ファイルが指定されたパスに存在することを確認
4. `marketplace.json` にリストされた全 plugin が `plugins/` に対応するディレクトリを持つことを検証

全検証ステップは ubuntu-latest で Node.js 20 を使用して実行されます（`.github/workflows/validate-plugins.yml` 10-102行目）。

### ランタイム検証（Hook）

`plugins/core/hooks/validate-ticket.sh` script が全 Write または Edit tool 操作の後に実行されます。`plugins/core/hooks/hooks.json` で10秒のタイムアウトで設定されています。hook は以下を検証します：

- ファイル位置：ticket は `todo/`、`icebox/`、または `archive/<branch>/` ディレクトリに存在する必要がある
- ファイル名形式：`YYYYMMDDHHmmss-*.md` パターンに一致する必要がある
- frontmatter の存在：YAML frontmatter（`---`）で始まる必要がある
- 必須フィールド：`created_at`（ISO 8601 形式）、`author`（email、@anthropic.com 以外）、`type`（enhancement|bugfix|refactoring|housekeeping）、`layer`（UX|Domain|Infrastructure|DB|Config の YAML 配列）
- オプションフィールド：`effort`（0.1h|0.25h|0.5h|1h|2h|4h）、`commit_hash`（7-40文字の16進数）、`category`（Added|Changed|Removed）

終了コード2は操作をブロックし、終了コード0は続行を許可します（`plugins/core/hooks/validate-ticket.sh` 1-189行目）。

### 出力検証（Scan）

`plugins/core/skills/validate-writer-output/sh/validate.sh` script は、README インデックス更新が進む前に期待される出力ファイルが存在し非空であることを確認します。以下を検証します：

- viewpoint analyst 出力：`.workaholic/specs/` の8ファイル（stakeholder.md、model.md、usecase.md、infrastructure.md、application.md、component.md、data.md、feature.md）
- policy analyst 出力：`.workaholic/policies/` の7ファイル（test.md、security.md、quality.md、accessibility.md、observability.md、delivery.md、recovery.md）

ファイル毎のステータス（ok|missing|empty）と全体の pass/fail を含む JSON を返します（`plugins/core/skills/validate-writer-output/sh/validate.sh` 1-35行目、`plugins/core/commands/scan.md` 64-74行目）。

## Coverage Targets

観測されません。コードカバレッジ測定ツール（nyc、c8、istanbul、coverage.py）やカバレッジターゲットは設定されていません。

## Test Organization

観測されません。リポジトリには test ディレクトリ（`__tests__/`、`test/`、`tests/`、`spec/`）や命名パターンに従う test ファイル（`*.test.js`、`*.spec.ts`、`*_test.py`）が含まれていません。

`plugins/core/skills/*/sh/*.sh` の19個の shell script には付属する test ファイルがありません。shell script は skill ドメイン毎に整理されていますが、自動テストカバレッジはありません。

## Observations

- CI pipeline は main へのマージ前に JSON 構造と plugin の整合性を検証します（`.github/workflows/validate-plugins.yml`）。
- ランタイム hook は ticket 形式が不正な場合に開発セッション中に即座にフィードバックを提供します（`plugins/core/hooks/hooks.json`、`plugins/core/hooks/validate-ticket.sh`）。
- scan command はインデックス更新の commit 前にドキュメント生成器の出力を検証し、壊れたリンクを防ぎます（`plugins/core/commands/scan.md` 64-74行目）。
- 検証戦略は動作の正確さよりも構造的正確性（有効な JSON、必須フィールド、ファイルの存在）を優先しており、設定リポジトリとしてのプロジェクトの性質に一致しています。
- 自動テストがないため、shell script ロジックでのリグレッションを防止できません。これは JSON スキーマ検証以外のリポジトリ内の唯一の実行可能コードです。

## Gaps

- 観測されません：19個のバンドルされた shell script に対する shell script linting ツール（shellcheck）や shell test framework（bats、shunit2）。
- 観測されません：100以上の markdown ファイルに対する markdown linting（markdownlint-cli、remark-lint）やフォーマット検証。
- 観測されません：エンドツーエンド command workflow（ticket → drive → report）の統合テスト。
- 観測されません：基本的な `jq empty` 構文チェックを超える JSON スキーマ検証。
