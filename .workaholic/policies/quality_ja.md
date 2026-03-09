---
title: Quality Policy
description: Code quality standards, linting rules, review processes, and metrics used to maintain maintainability
category: developer
modified_at: 2026-03-10T12:00:00+00:00
commit_hash: f76bde2
---

[English](quality.md) | [Japanese](quality_ja.md)

# Quality Policy

この policy は Workaholic プロジェクトで保守性を維持するために使用される code 品質標準、linting ルール、review プロセス、metrics を文書化します。品質保証は CI validation、post-tool hook、設定 rule、performance 評価 framework を通じて実現されています。

## Linting and Formatting

### Shell Script Standards

すべての shell script は `shell.md` rule ファイルを通じて強制される POSIX sh 互換性標準に従う必要があります（`plugins/drivin/.claude-plugin/plugin.json` が `plugins/drivin/rules/` から rule を読み込みます）。

**Shebang 要件**: Script は strict mode を有効にするため `#!/bin/sh -eu` を使用する必要があります（`-e` はエラー時に終了、`-u` は未定義変数でエラー）。（`plugins/drivin/rules/shell.md` により強制。）

**禁止される bash 機能**: 配列、`[[ ]]`、`declare`、その他の bash 固有の構文は禁止されています。これにより bash を持たない Alpine Linux container で script が実行できることを保証します。（`plugins/drivin/rules/shell.md` により強制。）

**インライン複雑性の禁止**: Command と agent は複雑なインライン shell command を含むことができません。禁止される構文には条件文（`if`、`case`、`test`、`[ ]`、`[[ ]]`）、pipe とチェーン（`|`、`&&`、`||`）、テキスト処理（`sed`、`awk`、`grep`、`cut`）、ループ（`for`、`while`）、論理を含む変数展開（`${var:-default}`、`${var:+alt}`）が含まれます。すべてのマルチステップまたは条件付き操作は skill のバンドル script（`skills/<name>/sh/<script>.sh`）に抽出する必要があります。（`CLAUDE.md` Shell Script Principle により強制され、code review を通じて検証。）

**検証**: codebase 内に24個の shell script が存在します。drivin plugin の21個の script のうち、15個は `#!/bin/sh -eu` を使用し、3個は strict mode flags なしの `#!/bin/sh` を使用し（`branching/sh/check.sh`、`branching/sh/check-version-bump.sh`、`branching/sh/create.sh`）、1個の hook は `#!/bin/bash` を使用し（`hooks/validate-ticket.sh`）、2個は `#!/usr/bin/env bash` を使用しています（`select-scan-agents/sh/select.sh`、`validate-writer-output/sh/validate.sh`）。trippin plugin の3個の script はすべて `#!/bin/bash` と `set -euo pipefail` を使用しています（`trip-protocol/sh/ensure-worktree.sh`、`trip-protocol/sh/init-trip.sh`、`trip-protocol/sh/trip-commit.sh`）。（`find . -name "*.sh" -type f` により検証。）

### TypeScript Conventions

`typescript.md` rule は code review を通じて強制される coding 標準を定義します。

**Type safety**: `any` より `unknown` を優先し、type guard を優先して `as` type assertion を避けます。（`plugins/drivin/rules/typescript.md` により強制。）

**スタイル設定**: `interface` より `type` を使用し、`null` より `undefined` を優先し、単一使用の type は function signature に inline 化します。（`plugins/drivin/rules/typescript.md` により強制。）

**Dead code ポリシー**: 未使用の export、component、function は即座に削除します。code を編集する前に必ず使用箇所を grep します。（`plugins/drivin/rules/typescript.md` により強制。）

**Import 整理**: 相対 import（`../`）の代わりに path alias（例：`@lib/*`、`@utils/*`）を使用します。同一ディレクトリの import にのみ `./` を使用します。（`plugins/drivin/rules/typescript.md` により強制。）

**注記**: プロジェクトは現在 TypeScript ファイルを含まないため、これらの標準は将来の開発に備えたものです。

### Documentation Standards

**Mermaid 要件**: すべての diagram は ASCII art ではなく、fenced code block 内の Mermaid syntax を使用する必要があります。罫線文字（`+--+`、`|`、`└──`）、ASCII 矢印（`-->`、`==>`、`->`）、スペースによる手動配置は禁止されています。特殊文字（`/`、`{`、`}`、`[`、`]`）を含む node label は GitHub rendering エラーを防ぐため引用符で囲む必要があります。（`plugins/drivin/rules/diagrams.md` により強制。）

**見出し番号付け**: spec、term、story、skill では h2 と h3 レベルに番号付き見出しが必要です（例：`## 1. Section`、`### 1-1. Subsection`）。README と設定 doc は免除されます。（`plugins/drivin/rules/general.md` により強制。）

**Markdown link**: ドキュメント内で `.md` ファイルを参照する場合、backtick ではなく markdown link（`[filename.md](path/to/file.md)`）を使用します。これは特に安定した doc（spec、term、story）に適用されます。（`plugins/drivin/rules/general.md` により強制。）

### Multi-Language Documentation

**i18n 強制**: `.workaholic/` 内のすべてのファイルは対応する日本語翻訳（`_ja.md` suffix）を持つ必要があります。各言語の README は同じ言語のドキュメントにリンクし、並列 link 構造を作成する必要があります。プロジェクトは CLAUDE.md 言語設定を尊重します - 主要言語が日本語の場合、`_ja.md` 翻訳は生成されません（主要コンテンツと重複するため）。（`plugins/drivin/rules/i18n.md` により強制され、`translate` skill を通じて検証。）

**言語分離**: Code と code comment、commit message、pull request、`.workaholic/` 外のドキュメントは英語のみを使用します。`.workaholic/` ディレクトリは英語と日本語の両方をサポートします。（`CLAUDE.md` Written Language セクションにより強制。）

## Code Review

### Manual Review Process

**承認 workflow**: `/drive` command は必須の承認フローを実装します。各 ticket の実装後、system は `AskUserQuestion` を使用して選択可能な option（Approve、Approve and stop、Abandon、Other）で変更を developer に提示します。free-form feedback は "Other" option を通じてサポートされます。（`plugins/drivin/commands/drive.md` と `plugins/drivin/skills/drive-approval/SKILL.md` により強制。）

**改訂追跡**: Developer が feedback を提供すると、code 変更の前に ticket ファイルが更新されます。Discussion セクションが timestamp、verbatim feedback、ticket 更新、方向性変更の解釈とともに追加されます。後続の改訂は番号付けされます（Revision 1、Revision 2 など）。（`plugins/drivin/skills/drive-approval/SKILL.md` Section 3 により強制。）

**放棄ドキュメント**: 実装が放棄されると、Failure Analysis セクションが ticket に追加され、試行されたこと、失敗した理由、将来の試行のための洞察が文書化されます。変更は `git restore` で破棄され、ticket は `.workaholic/tickets/abandoned/` にアーカイブされます。（`plugins/drivin/skills/drive-approval/SKILL.md` Section 4 により強制。）

### Automated Review

**Ticket validation hook**: PostToolUse hook（`plugins/drivin/hooks/validate-ticket.sh`）がすべての Write または Edit 操作で 10 秒の timeout で ticket frontmatter を検証します。ファイル名形式（YYYYMMDDHHmmss-*.md）、ディレクトリ位置（todo/、icebox/、または archive/<branch>/）、frontmatter の存在、必須フィールド（ISO 8601 形式の created_at、@anthropic.com を除く email としての author、列挙値からの type、YAML 配列としての layer、有効な形式からの effort、git hash としての commit_hash、列挙値からの category）をチェックします。（`plugins/drivin/hooks/validate-ticket.sh` により強制され、`plugins/drivin/.claude-plugin/plugin.json` に登録。）

**CI validation**: `validate-plugins.yml` workflow は main への push と pull request で実行されます。`marketplace.json` と `plugin.json` ファイルの JSON syntax を検証し、必須フィールド（name、version）をチェックし、skill ファイル path が存在することを確認し、marketplace plugin がディレクトリ構造と一致することを保証します。（`.github/workflows/validate-plugins.yml` により強制。）

**Output validation**: README index を更新する前に、`validate-writer-output` skill が analyst subagent の出力ファイルが存在し空でないことを検証します。ファイルごとのステータス（ok、missing、empty）と全体の pass/fail flag を返します。validation が失敗すると README 更新がブロックされます。（`plugins/drivin/skills/validate-writer-output/SKILL.md` により強制。）

## Quality Metrics

### Complexity Constraints

**Component サイズポリシー**: Command は orchestration のみ（~50-100行）、subagent は orchestration のみ（~20-40行）、skill は包括的な知識（~50-150行）。この「薄い command と subagent、包括的な skill」原則は関心の分離を強制します。（`CLAUDE.md` Design Principle により強制。）

**Nesting 境界**: アーキテクチャは厳格な invocation 境界を強制します。Command は skill と subagent を invoke できます。Subagent は skill と他の subagent を invoke できますが command は invoke できません。Skill は他の skill を invoke できますが subagent や command は invoke できません。（`CLAUDE.md` Component Nesting Rules により強制。）

### Decision Quality Evaluation

`analyze-performance` skill は development branch の意思決定を5つの次元で評価します。

**Consistency**: 決定は確立されたパターンに従いましたか？類似の問題は類似の方法で解決されましたか？pivot は優柔不断に揺れるのではなく、より良いソリューションに収束しましたか？

**Intuitivity**: ソリューションは明白で理解しやすかったですか？決定は一般的な期待と一致しましたか？別の developer がその選択を自然だと感じるでしょうか？

**Describability**: 最終的な名前はうまく決まりましたか？より良い選択肢が発見されたときに命名改善が行われましたか？用語は意味の衝突を避け、将来の拡張をサポートしましたか？

**Agility**: Developer は予期しない問題にどれだけうまく対応しましたか？効果的に反復し、学んだ教訓を後続の作業に組み込みましたか？必要なときに迅速に方向修正が行われましたか？

**Density**: Code は意味を経済的に表現していますか？概念的価値とテキスト表面積の比率は高いですか？ソリューションは冗長な足場、冗長な抽象化、希薄な意味論なしに目的を達成していますか？

各次元は評価（Strong、Adequate、Needs Improvement）と1-2文の証拠に基づく分析を受けます。評価は生産的な反復（より良いソリューションへの収束）と優柔不断な揺れを区別します。（`plugins/drivin/skills/analyze-performance/SKILL.md` により強制され、story-writer agent により invoke。）

### Performance Metrics

`analyze-performance` skill の `calculate.sh` script は定量的な branch metrics を計算します。

- Commit 数
- 期間（時間と営業日）
- 開始と終了の timestamp
- Velocity（時間単位あたりの commit）

これらの metrics は git 履歴から計算され、透明性のため branch story に含まれます。（`plugins/drivin/skills/analyze-performance/sh/calculate.sh` により強制され、story-writer agent により invoke。）

## Type Safety

**Build step なし**: これは設定/ドキュメント project であり、build step は不要です。Type checking は現在の codebase には適用されません。（`CLAUDE.md` Type Checking セクションに文書化。）

**将来の TypeScript サポート**: `typescript.md` rule は TypeScript ファイルが project に追加されたときに適用される type safety 標準（`any` より `unknown` を優先、`as` assertion を避ける）を定義します。（`plugins/drivin/rules/typescript.md` により強制。）

## Observations

プロジェクトは複数の補完的なメカニズムを通じて品質を強制します。

1. **Rule ファイル**が shell script、TypeScript、diagram、i18n、一般規約の標準を定義
2. **PostToolUse hook**がすべての write 操作で ticket 形式と frontmatter を検証
3. **CI workflow**が JSON 設定と plugin 構造を検証
4. **Manual 承認フロー**が各 ticket 実装をコミットする前に developer review を要求
5. **Performance 評価**が5つの次元で決定品質を評価
6. **Component サイズ制約**が行数推奨を通じて関心の分離を強制
7. **アーキテクチャ境界**が不適切な層間依存を防止

Shell script のコンプライアンスは2つの plugin で異なります。drivin plugin では21個の script のうち15個が strict mode 付き POSIX sh に従いますが、3個の branching script は strict mode flags が欠落し、3個の script は bash を使用しています。trippin plugin の3個の script はすべて `set -euo pipefail` 付き bash を使用しており、これは git worktree 操作に bash 機能を必要とする意図的な選択を反映しています。ドキュメント標準（Mermaid、見出し番号付け、markdown link）は自動強制ではなく code review に依存します。TypeScript 標準は定義されていますが、codebase に TypeScript ファイルが含まれていないため未使用です。

この branch で plugin ディレクトリが `core` から `drivin` に改名され、すべての内部参照が更新されました。新しい `trippin` plugin が追加され、drivin plugin の shell rule で確立された POSIX sh 標準ではなく bash 規約に従う独自の shell script を持っています。

## Gaps

**自動 linting**: ESLint、Prettier、shellcheck の設定は存在しません。Linting は自動ツールではなくドキュメント（rule ファイル）と code review を通じて強制されます。

**複雑性 metrics**: 自動複雑性閾値（循環的複雑度、認知的複雑度、最大関数長）は設定されていません。複雑性制約はツールではなくドキュメントベースの行数推奨（command で ~50-100行）に依存します。

**重複検出**: 自動重複検出は設定されていません。重複防止はアーキテクチャポリシー（再利用可能な知識層としての skill）と code review に依存します。

**カバレッジ要件**: test coverage 閾値やレポートメカニズムは存在しません。プロジェクトは主に設定/ドキュメントであり、test coverage を必要とするアプリケーション code はありません。

**Pre-commit hook**: フォーマットや linting 強制のための pre-commit hook（例：husky、lint-staged）は存在しません。品質ゲートは git hook ではなく PostToolUse hook（ticket validation）と CI workflow（plugin validation）を通じて行われます。

**ドキュメント linting**: Mermaid syntax validation と markdown link チェックは自動化されていません。これらは code review と手動検証に依存します。

**Plugin 間 shell 標準の一貫性**: drivin plugin は `shell.md` rule を通じて POSIX sh を強制していますが、trippin plugin は bash script を使用しています。plugin 間で共有される shell 標準 rule は存在せず、trippin plugin は drivin の shell rule を読み込んでいません。
