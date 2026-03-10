---
title: Observability Policy
description: Logging、monitoring、metrics、および tracing の実践
category: developer
modified_at: 2026-03-10T12:00:00+00:00
commit_hash: f76bde2
---

[English](observability.md) | [Japanese](observability_ja.md)

# Observability Policy

この文書は Workaholic repository における observability の実践を説明します。Workaholic は、従来の application monitoring ではなく、開発ナラティブ生成、performance metrics、および監査証跡を通じて observability を実装しています。このシステムは現在、drivin（ticket 駆動開発）と trippin（探索 workflow）の 2 つの plugin にまたがり、それぞれが異なる observability パターンを提供しています。

## Logging Practices

### Error Handling

すべての shell script は、未定義変数や command 失敗時に即座に終了する厳格な error handling を shell option で強制しています。drivin plugin は 2 つのパターンを使用します: POSIX 準拠 script 用の `/bin/sh -eu`（`plugins/drivin/skills/*/sh/*.sh` 内の 20 個の skill script のうち 17 個）と、bash 固有の機能を必要とする script 用の `#!/usr/bin/env bash`（`plugins/drivin/skills/select-scan-agents/sh/select.sh` および `plugins/drivin/skills/validate-writer-output/sh/validate.sh`）。ticket validation hook は `#!/bin/bash` と `set -e` を使用します（実装: `plugins/drivin/hooks/validate-ticket.sh`）。trippin plugin はすべての 3 つの script で `#!/bin/bash` と `set -euo pipefail` を使用し（`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`、`init-trip.sh`、`trip-commit.sh`）、pipeline でのエラー伝播のために `pipefail` option を追加しています。

Shell script は、drivin plugin では操作をブロックするために、説明的なメッセージと exit code 2 で検証エラーを stderr に出力します（実装: `plugins/drivin/hooks/validate-ticket.sh` 39-42、50-53、66-68、86-94 行）。trippin plugin は構造化された JSON error message を stderr に exit code 1 で出力します（実装: `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh` 11-12、16-17、25-26、30-31 行）。

### Validation Logging

Ticket validation hook は、field 名、無効な値、および権威あるドキュメントへの参照を含む構造化された error message を記録します（実装: `plugins/drivin/hooks/validate-ticket.sh` の `print_skill_reference()` 関数と、`created_at`、`author`、`type`、`layer`、`effort`、`commit_hash`、`category` の検証ブロック）。

CI validation workflow は、JSON 検証結果と必須 field チェックを GitHub Actions 出力にログ記録します（実装: `.github/workflows/validate-plugins.yml` の "Validate marketplace.json"、"Validate plugin.json files"、"Check skill files exist"、"Validate marketplace plugins match directories" step）。

### Session Context

Claude Code の会話コンテキストが、session 中の操作の暗黙的なログとして機能します。file または外部システムへの構造化された logging は実装されていません。

## Metrics Collection

### Performance Metrics

`analyze-performance` skill は、git 履歴から開発速度 metrics を計算します（実装: `plugins/drivin/skills/analyze-performance/sh/calculate.sh`）:

- Base branch と HEAD の間の commit 数
- 開始および終了 timestamp（ISO 8601）
- 時間および日数での期間
- 1 時間あたりまたは 1 日あたりの commit 数での速度
- 複数日作業の営業日計算

これらの metrics は story frontmatter に含まれます（実装: `plugins/drivin/skills/write-story/SKILL.md`）。

### Story Metrics

Story 文書は、観測可能な metadata を持つ構造化された frontmatter を含みます（実装: `plugins/drivin/skills/write-story/SKILL.md`）:

- `branch`: Branch 名
- `started_at`: 最初の commit timestamp
- `ended_at`: 最後の commit timestamp
- `tickets_completed`: アーカイブされた ticket の数
- `commits`: 合計 commit 数
- `duration_hours`: 経過時間（時間）
- `duration_days`: commit があった暦日数
- `velocity`: 時間単位あたりの commit 数
- `velocity_unit`: "hour" または "day"

### Ticket Metrics

Ticket frontmatter は effort 見積もりを追跡します（実装: `plugins/drivin/skills/create-ticket/SKILL.md`）:

- `effort`: 時間での所要時間（0.1h、0.25h、0.5h、1h、2h、4h）
- `commit_hash`: Ticket を実装した git commit
- `category`: Changelog カテゴリ（Added、Changed、Removed）

## Tracing and Monitoring

### Ticket Traceability

すべての実装は ticket lifecycle を通じて追跡可能です（実装: `plugins/drivin/skills/archive-ticket/SKILL.md`）:

1. `.workaholic/tickets/todo/` での作成（`created_at` および `author` metadata 付き）
2. `/drive` command 実行中の実装
3. `effort`、`commit_hash`、`category` での frontmatter 更新
4. `.workaholic/tickets/archive/<branch>/` へのアーカイブ
5. Ticket path を commit URL にリンクする changelog エントリ

### Trip Commit Tracing

Trippin plugin は探索 session のための構造化された commit tracing を実装しています（実装: `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`）。各 commit は `trip(<agent>): <step>` フォーマットに従い、body に `Phase: <phase>` とオプションの説明を含みます。commit 出力は commit hash、agent 名、step の説明を含む JSON を返し、探索の進捗のプログラム的な追跡を可能にします。

### Concerns Traceability

Ticket concerns section は commit hash と file path の参照を使用します（実装: `plugins/drivin/skills/create-ticket/SKILL.md` Considerations フォーマット）:

```
- <description> (see [hash](<repo-url>/commit/<hash>) in path/to/file.ext)
```

Story concerns section は、ticket からこれらの参照を抽出します（実装: `plugins/drivin/skills/review-sections/SKILL.md`、`plugins/drivin/skills/write-story/SKILL.md`）。

### Changelog Audit Trail

Changelog は、すべての変更のカテゴリ別監査証跡を提供します（実装: `plugins/drivin/skills/write-changelog/sh/generate.sh`）:

- カテゴリ別にエントリをグループ化: Added、Changed、Removed
- 各エントリを GitHub commit URL にリンク
- 各エントリをアーカイブされた ticket file にリンク
- オプションの issue 番号リンクを使用して branch 別に整理

### Historical Context Tracing

`discover-history` skill は、関連する作業について以前の ticket を検索します（実装: `plugins/drivin/skills/discover-history/SKILL.md`）。これにより、story に過去の決定とパターンを参照する歴史的分析セクションを含めることができます。

### Frontmatter-Based Tracking

`.workaholic/` 内のすべてのドキュメント file には、コンテンツを特定の git revision にリンクする `commit_hash` field を持つ YAML frontmatter が含まれています（実装: `plugins/drivin/skills/write-spec/SKILL.md`、`plugins/drivin/skills/write-terms/SKILL.md`、`plugins/drivin/skills/analyze-policy/SKILL.md`）。

## Alerting

### CI Validation Alerts

GitHub Actions workflow は検証エラー時に失敗し通知します（実装: `.github/workflows/validate-plugins.yml`）:

- Marketplace または plugin manifest での無効な JSON
- plugin.json での必須 field の欠落
- Manifest で参照されている欠落した skill file
- 不一致の plugin directory と marketplace エントリ

### Git Hook Alerts

Ticket validation hook は、以下の場合に Write および Edit 操作を exit code 2 と説明的な error message でブロックします（実装: `plugins/drivin/hooks/validate-ticket.sh`）:

- 無効な file 場所（todo/、icebox/、または archive/ にない）
- 無効な filename フォーマット（YYYYMMDDHHmmss-*.md でない）
- 欠落または不正な frontmatter
- 無効な field 値（created_at、author、type、layer、effort、commit_hash、category）
- Anthropic.com の email address（実際の git user.email を使用する必要があります）

### Validation Script Alerts

`update-ticket-frontmatter` script は、書き込み時に effort 値を検証し、validation hook のバイパスを防止します（実装: `plugins/drivin/skills/update-ticket-frontmatter/sh/update.sh`）。

### Worktree Validation Alerts

Trippin plugin は探索 session を作成する前に worktree と branch の状態を検証します（実装: `plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`）。Worktree が既に存在する場合、branch 名が競合する場合、または git repository の外部で command が実行された場合に、構造化された JSON error message が stderr に出力されます。

## Observations

開発の observability は、各 branch の完全なナラティブをキャプチャする story 文書を通じて達成されます（実装: `plugins/drivin/skills/write-story/SKILL.md`）。

Changelog エントリは、commit および ticket link を含むカテゴリ別監査証跡を作成します（実装: `plugins/drivin/skills/write-changelog/SKILL.md`）。

Performance-analyst は、Consistency、Intuitivity、Describability、Agility、Density の 5 つの次元にわたって自動開発品質フィードバックを提供します（実装: `plugins/drivin/skills/analyze-performance/SKILL.md` 30-56 行）。

Release note は、story から抽出された高レベルの要約を提供します（実装: `plugins/drivin/skills/write-release-note/SKILL.md`）。

Trippin plugin は、探索 workflow の observability メカニズムとして構造化された commit message を導入しています。`trip(<agent>): <step>` フォーマットと phase metadata を使用して、git 履歴から探索 session の事後的な再構成を可能にします。

Observability model は、live monitoring ではなく、story、changelog、および release note を通じた事後分析に焦点を当てた、retrospective なものです。

## Gaps

File または外部システムへの構造化された logging はありません。Shell script は stderr に出力しますが、log file は維持しません。

Telemetry または使用状況分析の収集はありません。

Session 間でのエラー率追跡または障害監視はありません。

GitHub の組み込み通知を超えた CI/CD 障害の alerting メカニズムはありません。

Runtime monitoring はありません。これは、永続的なサービスではなく Claude Code session 内で実行される開発ツールに適しています。

Distributed tracing はありません。すべての操作は単一の Claude Code session コンテキスト内で実行されます。

Trippin plugin には commit レベルの tracing 以外の observability インスツルメンテーションがありません。探索 session には、drivin plugin で利用可能な story および changelog メカニズムがありません。
