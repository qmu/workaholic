---
title: Test Policy
description: 検証と妥当性確認の戦略 -- テストレベル、カバレッジ目標、正確性を保証するプロセス
category: developer
modified_at: 2026-03-10T00:00:00+00:00
commit_hash: f76bde2
---

[English](test.md) | [Japanese](test_ja.md)

# Test Policy

この文書は Workaholic repository における test と検証の実践について説明します。Workaholic は markdown ファイル、JSON 設定、shell script から構成される設定と文書の project です。従来の unit test や integration test ではなく、構造検証、runtime hook、出力検証に依存しています。

## Testing Framework

従来の testing framework は設定されていません。test 設定ファイル (jest.config, vitest.config, playwright.config, cypress.config, pytest.ini) は repository に存在しません。これは設定と文書の artifact のみから構成される Claude Code plugin marketplace としての project の性質に合致しています。

Shell script testing framework (bats, shunit2) や linting tool (shellcheck) は設定されていません。`plugins/drivin/skills/*/sh/*.sh`、`plugins/drivin/hooks/*.sh`、および `plugins/trippin/skills/*/sh/*.sh` の 24 個の shell script は、自動化された test や linting ではなく rule ファイルに文書化された POSIX sh 準拠標準に依存しています (`plugins/drivin/rules/shell.md`)。

Markdown linting tool (markdownlint-cli, remark-lint) は `.workaholic/` の 395 個の markdown ファイルに対して設定されていません。Markdown 品質は、自動化された検証ではなく、文書化された標準 (Mermaid 構文、見出し番号付け、link 形式) と code review によって実施されています (`plugins/drivin/rules/diagrams.md`、`plugins/drivin/rules/general.md`)。

## Testing Levels

### Structural Validation (CI)

`.github/workflows/validate-plugins.yml` workflow は main branch へのすべての push と pull request で実行されます。4つの検証ステップを実行します:

1. `.claude-plugin/marketplace.json` が `jq empty` を使用して有効な JSON であることを検証
2. 各 `plugins/*/.claude-plugin/plugin.json` が有効な JSON であり、必須の `name` と `version` フィールドを含むことを検証
3. `plugin.json` ファイルに宣言されたすべての skill ファイルが指定されたパスに存在することを確認
4. `marketplace.json` にリストされたすべての plugin が `plugins/` に対応するディレクトリを持つことを確認

すべての検証ステップは ubuntu-latest と Node.js 20 で実行されます (`.github/workflows/validate-plugins.yml` 行 10-103)。この workflow は drivin と trippin の両方の plugin を検証します。

### Runtime Validation (Hook)

`plugins/drivin/hooks/validate-ticket.sh` script は、すべての Write または Edit tool 操作の後に実行されます。`plugins/drivin/hooks/hooks.json` で 10 秒の timeout で設定されています。Hook は以下を検証します:

- ファイル位置: ticket は `.workaholic/tickets/todo/`、`.workaholic/tickets/icebox/`、または `.workaholic/tickets/archive/<branch>/` ディレクトリに存在する必要があります
- ファイル名形式: `YYYYMMDDHHmmss-*.md` パターンに一致する必要があります
- Frontmatter の存在: YAML frontmatter (`---`) で始まる必要があります
- 必須フィールド: `created_at` (ISO 8601 形式)、`author` (email、@anthropic.com でないこと)、`type` (enhancement|bugfix|refactoring|housekeeping)、`layer` (UX|Domain|Infrastructure|DB|Config の YAML 配列)
- オプションフィールド: `effort` (0.1h|0.25h|0.5h|1h|2h|4h)、`commit_hash` (7-40 文字の 16 進数)、`category` (Added|Changed|Removed)

Exit code 2 は操作をブロックし、exit code 0 は許可します (`plugins/drivin/hooks/validate-ticket.sh` 行 1-190)。

### Output Validation (Scan)

`plugins/drivin/skills/validate-writer-output/sh/validate.sh` script は、README index 更新が進む前に、期待される出力ファイルが存在し空でないことを確認します。以下を検証します:

- Viewpoint analyst 出力: `.workaholic/specs/` の 8 ファイル (ux.md, model.md, usecase.md, infrastructure.md, application.md, component.md, data.md, feature.md)
- Policy analyst 出力: `.workaholic/policies/` の 7 ファイル (test.md, security.md, quality.md, accessibility.md, observability.md, delivery.md, recovery.md)

ファイルごとのステータス (ok|missing|empty) と全体の pass/fail を含む JSON を返します (`plugins/drivin/skills/validate-writer-output/sh/validate.sh` 行 1-35、`plugins/drivin/commands/scan.md` 行 70-82)。

### Manual Review (Approval)

`/drive` command は、すべての ticket 実装に対して必須の承認フローを実装します。各 ticket の実装後、システムは `AskUserQuestion` を使用して選択可能なオプション (Approve、Approve and stop、Abandon、Other) で変更を開発者に提示します。この manual review がすべての commit を管理します (`plugins/drivin/commands/drive.md` と `plugins/drivin/skills/drive-approval/SKILL.md`)。

開発者がフィードバックを提供すると、ticket ファイルは code 変更の前に更新されます。Discussion セクションが timestamp、verbatim フィードバック、ticket 更新、方向変更の解釈とともに追加されます。その後の改訂は追跡可能性のために番号付けされます (Revision 1、Revision 2 など) (`plugins/drivin/skills/drive-approval/SKILL.md`)。

## Coverage Targets

観測されていません。Code coverage 測定 tool (nyc, c8, istanbul, coverage.py) や coverage 目標は設定されていません。

Project の検証戦略は、動作 test coverage ではなく構造の正確性 (有効な JSON、必須フィールド、ファイルの存在) に焦点を当てています。これは codebase の構成に合致しています: 設定ファイル (JSON)、文書ファイル (markdown)、実行可能 script (shell) には従来の unit test coverage を必要とする application ロジックがありません。

## Test Organization

観測されていません。Repository には test ディレクトリ (`__tests__/`、`test/`、`tests/`、`spec/`) や命名パターンに従う test ファイル (`*.test.js`、`*.spec.ts`、`*_test.py`) が含まれていません。

2つの plugin にまたがる 24 個の shell script には付随する test ファイルがありません。Drivin plugin では、21 個の shell script が `plugins/drivin/skills/*/sh/*.sh` と `plugins/drivin/hooks/*.sh` に存在します。Trippin plugin では、3 個の shell script が `plugins/trippin/skills/*/sh/*.sh` に存在します。Shell script は skill ドメインごとに整理されていますが、自動化された test coverage はありません。Script の正確性は、`plugins/drivin/rules/shell.md` に文書化された POSIX sh 準拠標準 (shebang `#!/bin/sh -eu`、禁止された bash 機能、inline 複雑性の禁止) と code review によって実施されています。

`.workaholic/` の 395 個の markdown ファイルは、コンテンツタイプ (specs、policies、tickets、terms) ごとに整理されていますが、構造チェック以外の自動化された検証はありません。Markdown 品質は、code review によって実施される文書化された標準 (Mermaid 構文、見出し番号付け、link 形式) に依存しています (`plugins/drivin/rules/diagrams.md`、`plugins/drivin/rules/general.md`)。

## Observations

検証戦略は、包括的な test coverage ではなく、主要な統合ポイントでの正確性を優先しています:

- **CI pipeline 検証**: Main への merge 前に drivin と trippin の両方の plugin の JSON 構造と plugin 整合性を検証します (`.github/workflows/validate-plugins.yml`)。壊れた marketplace 設定が main branch に入ることを防ぎます。
- **Runtime hook 検証**: Ticket 形式が正しくない場合、開発セッション中に即座にフィードバックを提供します (`plugins/drivin/hooks/validate-ticket.sh`)。Commit 時ではなく書き込み時に不正な形式の ticket をブロックします。
- **Output 検証**: Index 更新を commit する前に、文書生成器の出力を検証して壊れた link を防ぎます (`plugins/drivin/commands/scan.md` 行 70-82)。README ファイルが存在する文書にのみ link することを保証します。
- **Manual approval gate**: 各 ticket 実装を commit する前に開発者の review を要求します (`plugins/drivin/skills/drive-approval/SKILL.md`)。正確性と品質に関する人間の判断を提供します。

検証戦略は設定 repository としての project の性質に合致しています。設定と文書の artifact に対しては、動作の正確性よりも構造の正確性 (有効な JSON、必須フィールド、ファイルの存在) がより重要です。

24 個の script にわたる shell script の shebang 準拠状況はさまざまです。Drivin の 21 個の script のうち、15 個が標準の `#!/bin/sh -eu` を使用し、3 個が strict mode フラグなしの `#!/bin/sh` を使用し、2 個が `#!/usr/bin/env bash` を使用し、1 個が `#!/bin/bash` を使用しています。Trippin の 3 個の script はすべて `#!/bin/bash` を使用しています。Shell script testing の欠如は、バンドルされた script のロジック regression が runtime まで検出されないことを意味します。ただし、script は複雑なビジネスロジックではなく、主にデータ変換 (git context 収集、ticket metadata 抽出、branch 作成) であるため、regression リスクは低減されています。

Trippin plugin は worktree 管理と trip protocol 操作のための新しいカテゴリの shell script を導入しています。これらの script は、plugin 設定の CI 構造検証以外の自動化された testing メカニズムではカバーされていません。

## Gaps

**Shell script linting**: 24 個のバンドルされた shell script に対して shellcheck または shell test framework (bats、shunit2) は設定されていません。Script の正確性は、自動化された linting ではなく、文書化された POSIX sh 準拠標準と code review に依存しています。

**Markdown linting**: 395 個の markdown ファイルに対して markdownlint-cli または remark-lint は設定されていません。Markdown 品質は、自動化された検証ではなく、文書化された標準 (Mermaid 構文、見出し番号付け、link 形式) と code review に依存しています。

**Integration testing**: End-to-end command workflow testing は存在しません。`/ticket` から `/drive` から `/report` への workflow は、自動化された integration test ではなく手動使用によって検証されています。同様に、trippin plugin の `/trip` command にも自動化された workflow testing はありません。

**JSON schema validation**: JSON 検証は基本的な構文チェック (`jq empty`) のみを使用します。必須フィールドの存在を超える構造の JSON schema 検証は存在しません。より複雑な schema 制約 (フィールド型、許可された値、相互依存関係) は実施されていません。

**Shell script unit tests**: 24 個の shell script には付随する unit test がありません。Script 内の関数 (検証、解析、変換) は独立して test されていません。Script の正確性は、開発と review 中の手動 test に依存しています。

**Regression test suite**: Bug 修正が修正されたままであることを検証する regression test suite は存在しません。唯一の regression 防止メカニズムは CI 構造検証であり、設定/構造 regression を検出しますが、script の動作 regression は検出しません。

**Performance testing**: Shell script のパフォーマンス benchmark または test は存在しません。Script 実行時間とリソース使用量は測定または検証されていません。

**Contract testing**: Component (commands、agents、skills) 間の contract testing は存在しません。呼び出し元を壊す interface 変更は、自動化された contract test ではなく、manual review と runtime エラーによって検出されます。

**Trippin plugin validation hook**: Trippin plugin には runtime 検証のための独自の PostToolUse hook がありません。Drivin plugin のみが hook を通じて ticket 検証を提供しています。Trippin 固有の artifact に対する同等の runtime 検証は存在しません。
