---
title: Delivery Policy
description: CI/CD pipeline、release process、deployment 実践
category: developer
modified_at: 2026-03-10T00:00:00+0000
commit_hash: f76bde2
---

[English](delivery.md) | [Japanese](delivery_ja.md)

# Delivery Policy

この文書は、Workaholic repository で観察された継続的インテグレーション、デリバリー、release の実践を記述します。Delivery は GitHub Actions workflow と plugin command によって自動化されています。Repository は ticket 駆動の開発 workflow に従い、実装作業は仕様から release まで構造化されたステージを通過します。2 つの plugin が異なる delivery workflow を提供します：Drivin は ticket 駆動開発、Trippin は協調的な探索に使用されます。

## CI/CD Pipeline

### Plugin Validation Workflow

`validate-plugins.yml` workflow (`on: push/pull_request: branches: [main]`) は `main` への push と pull request のたびに実行され、`ubuntu-latest` と Node.js 20 で 4 つの validation step を実行します：

1. **Marketplace JSON validation**: `.claude-plugin/marketplace.json` が文法的に正しい JSON であることを `jq empty` で検証します (step: "Validate marketplace.json")
2. **Plugin metadata validation**: `plugins/*/.claude-plugin/` 配下の各 `plugin.json` が必須 field (`name`, `version`) を含むことを `jq -r` での抽出と null check で検証します (step: "Validate plugin.json files")
3. **Skill file existence check**: `plugin.json` で参照される全ての skill file が disk 上に存在することを `jq -r '.skills[]?.path'` と file existence test で確認します (step: "Check skill files exist")
4. **Plugin directory consistency**: `marketplace.json` に列挙された全ての plugin が `plugins/` 内に対応する directory を持つことを確認します (step: "Validate marketplace plugins match directories")

Validation は `jq` を用いた shell script を使用します。Validation が失敗すると workflow は exit code 1 で終了します。

### CI Environment

CI は `ubuntu-latest` (`runs-on: ubuntu-latest`) と Node.js 20 (`uses: actions/setup-node@v4 with: node-version: '20'`) で実行されます。Environment は validation に標準的な Unix tool (`jq`, `awk`, `grep`, shell scripting) を使用し、compile や build は行いません。

### No Build Step

Build や compilation step は存在しません。Repository は markdown configuration file、shell script、JSON metadata を含みます。Validation は構造的整合性を確認しますが、変換や bundling は行いません。

## Build Process

### No Artifact Generation

観察されず。Claude Code plugin marketplace として、Workaholic は compiled artifact を生成しません。Source file が配布可能な asset です。

### Dependency Management

観察されず。`package.json`、`requirements.txt`、その他の dependency manifest は存在しません。Plugin は GitHub CLI (`gh`) と CI environment で利用可能な標準的な Unix tool にのみ依存します。

## Deployment Strategy

### Distribution via GitHub Release

Deployment は GitHub Release の作成を通じて行われます。ユーザーは packaged artifact をダウンロードするのではなく、marketplace repository を参照して plugin をインストールします。「deployment target」は GitHub Release であり、version を発見可能にします。

### Release Workflow Trigger

`release.yml` workflow は `main` への push または手動 dispatch で起動します (`on: push: branches: [main], workflow_dispatch`)。`ubuntu-latest` で `permissions: contents: write` を持って実行されます。

### Release Creation Logic

Workflow は `.claude-plugin/marketplace.json` 内の version を最新の GitHub Release tag と比較します：

1. **Extract current version**: `grep` と `cut` を使用して `marketplace.json` から `version` field を抽出します (step: "Get current version")
2. **Get latest release**: `gh release view --json tagName` を使用して最新の release tag を取得し、`v` prefix を除去します (step: "Get latest release version")
3. **Compare versions**: 現在の version が最新と異なる場合（または release が存在しない場合）、`needed=true` を設定します (step: "Check if release needed")
4. **Extract release notes**: `.workaholic/release-notes/` 内の生成済み release note を探します（`ls -t` で最新のものを取得）。存在しない場合は、最後の tag 以降の `git log` に fallback します (step: "Extract release notes")
5. **Create release**: `gh release create "v{version}" --title "v{version}" --notes-file /tmp/release_notes.txt --latest` を実行します (step: "Create GitHub Release")

Version が変更されていない場合、workflow は release 作成をスキップします。

### No Staging Environment

観察されず。Staging、preview、pre-production environment は存在しません。全ての変更は直接 `main` にマージされ、次の release の一部になります。

## Release Process

### Version Management

3 つの version file が同期されている必要があります：

- `.claude-plugin/marketplace.json` - root の `version` field と `plugins[].version` entry
- `plugins/drivin/.claude-plugin/plugin.json` - Drivin plugin の `version` field
- `plugins/trippin/.claude-plugin/plugin.json` - Trippin plugin の `version` field

`/release` command が version の同期を処理します。`major`、`minor`、または `patch`（default）を引数として受け取り、version を semantic に increment し、全ての version field を更新します。CLAUDE.md の Version Management section が version file の権威あるリストと bump 手順を文書化しています。

### Release Command Workflow

`/release` command は以下の順序で実行されます：

1. `.claude-plugin/marketplace.json` から現在の version を読み取る
2. 引数に基づいて version を increment する（default: `patch`）
3. `.claude-plugin/marketplace.json` の `version` field を更新
4. `plugins/drivin/.claude-plugin/plugin.json` の `version` field を更新
5. `plugins/trippin/.claude-plugin/plugin.json` の `version` field を更新
6. `marketplace.json` 内の `plugins` array の plugin version entry を更新
7. `Bump version to v{new_version}` というメッセージで commit
8. Remote に push

Release command は semantic versioning を使用します（例：`1.0.38`）。

### Automated Release Notes

Release workflow は git log 抽出よりも `.workaholic/release-notes/<branch-name>.md` の生成済み release note を優先します。`release-note-writer` subagent（`plugins/drivin/agents/release-note-writer.md`）は `/report` command を通じて PR 作成時に release note を生成します。

Release note 生成は release 時ではなく PR 作成時に行われます。Workflow は利用可能な場合、事前生成された note を使用します。

### Manual Version Bump Required

Version bump は自動ではなく手動です（開発者が `/release` command を実行）。GitHub workflow は version の変更を検出しますが、作成はしません。これにより意図しない version 変更からの偶発的な release を防ぎます。

## Branch Strategy

### Branch Naming Convention

開発 branch は以下のパターンに従います：

- `drive-<YYYYMMDD>-<HHMMSS>` - ticket 駆動開発 branch（`branching` skill で作成：`create.sh drive`）
- `trip-<YYYYMMDD>-<HHMMSS>` - main branch から直接作成される探索 branch（`branching` skill で作成：`create.sh trip`）
- `trip/<trip-name>` - Trippin plugin の `ensure-worktree.sh` script によって Agent Teams session 用に作成される worktree 分離 branch

Base branch は `main` です。全ての pull request は `main` を target とします。Drive branch の作成と状態確認は `branching` skill（`plugins/drivin/skills/branching/SKILL.md`）と bundled shell script で処理されます。Trippin plugin は `trip-protocol` skill（`plugins/trippin/skills/trip-protocol/SKILL.md`）を通じて独自の branch 作成を管理します。

### PR Creation Workflow

`/report` command（`plugins/drivin/commands/report.md`）が PR 作成を orchestrate します：

1. `branching` skill を使用して version が既に bump されているかを確認（`bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/branching/sh/check-version-bump.sh`）。`already_bumped` が `true` の場合（main から分岐後の現在の branch に「Bump version」commit が存在する場合）、bump をスキップ。そうでない場合、CLAUDE.md の Version Management に従って version を bump（patch increment）。
2. `story-writer` subagent を invoke（`subagent_type: "drivin:story-writer"`, `model: "opus"`）
3. story-writer の結果から PR URL を表示

`story-writer` subagent（`plugins/drivin/agents/story-writer.md`）は branch story を生成し、commit し、`pr-creator` と `release-note-writer` を順次 invoke し、PR URL を出力します。

Version bump の冪等性 check により、同じ branch で `/report` が複数回呼び出された際の二重 bump を防ぎます（`plugins/drivin/skills/branching/sh/check-version-bump.sh` で実装され、`git log main..HEAD --oneline --grep="Bump version"` を使用）。

### PR Creation Script

`plugins/drivin/skills/create-pr/sh/create-or-update.sh` script が PR 操作を処理します：

1. `.workaholic/stories/<branch-name>.md` から YAML frontmatter を `awk` で除去
2. `gh pr list --head "$BRANCH"` を使用して PR が存在するか確認
3. PR が存在しない場合：`gh pr create --title "$TITLE" --body-file /tmp/pr-body.md` で作成
4. PR が存在する場合：GitHub REST API を使用して `gh api repos/{REPO}/pulls/{NUMBER} --method PATCH` で更新

Script は GraphQL Projects deprecation error を避けるため、更新に REST API を使用します（script 内のコメント：`# Update existing PR via REST API (avoids GraphQL Projects deprecation error)`）。

### Ticket-Driven Workflow

`/drive` command（`plugins/drivin/commands/drive.md`）は `.workaholic/tickets/todo/` から ticket を順次実装します。各 ticket について：

1. Ticket の仕様に従って変更を実装
2. Ticket の title と overview を表示した選択可能な option でユーザー承認を要求
3. Ticket frontmatter を effort と Final Report で更新
4. `archive-ticket` skill を使用して `.workaholic/tickets/archive/<branch>/` に ticket を archive
5. 構造化された message format を使用して commit（`commit` skill から）

`/drive` command は各 ticket を個別に commit し、実装された ticket ごとに commit を作成します。`/drive` の開始時の branch 作成は `branching` skill（`plugins/drivin/skills/branching/sh/check.sh` と `create.sh`）を使用します。

### Trippin Exploration Workflow

`/trip` command（`plugins/trippin/commands/trip.md`）は協調的な探索のために Agent Teams session を起動します。Worktree 分離の workflow に従います：

1. **Worktree 作成**: `ensure-worktree.sh` を実行して `.worktrees/<trip-name>/` に分離された git worktree を `trip/<trip-name>` branch 上に作成
2. **Artifact 初期化**: `init-trip.sh` を実行して `.workaholic/.trips/<trip-name>/` に direction、model、design のサブディレクトリを含む artifact directory 構造を作成
3. **Agent Teams 起動**: Implosive Structure protocol に従う 3 人のチーム（Planner、Architect、Constructor）を作成し、Specification（内部ループ）と Implementation（外部ループ）の 2 つの phase を実行
4. **Step ごとの commit**: 全ての discrete workflow step が `trip-commit.sh` を通じて `trip(<agent>): <step>` format の git commit を生成

Trippin plugin は experimental flag `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` の有効化が必要です。全ての作業は worktree branch に分離され、完了後にユーザーが merge または検査できます。

## Commit Message Structure

### Structured Format (Drivin)

全ての Drivin commit は `commit` skill（`plugins/drivin/skills/commit/SKILL.md` と `commit/sh/commit.sh`）によって強制される構造化 message format を使用します。Format は 5 つの section を含みます：

```
<title>

Description: <why this change was needed, including motivation and rationale>

Changes: <what users will experience differently>

Test Planning: <what verification was done or should be done>

Release Preparation: <what is needed to ship and support afterward>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Section Guidelines

各 section（title を除く）は、lead agent が diff を読まずに行動するための十分な signal を提供する短い段落（3-5 文）である必要があります：

- **Title**: 現在形の動詞、何が変更されたか（50 文字以内）。`feat:` や `[fix]` などの prefix は使用しない。
- **Description**: なぜこの変更が必要だったか。問題または gap から始める。何が作業を trigger したかを説明。選択されたアプローチと根拠を述べる。
- **Changes**: ユーザーが異なって体験すること。観察可能な違いを具体的に記述。内部のみの場合は「None」と簡潔な説明を記述。
- **Test Planning**: 実行された検証または実行すべき検証。手動 check、自動 test、edge case を記述。trivial な場合のみ「None」と記述。
- **Release Preparation**: Ship とサポートに必要なこと。Migration、config 変更、documentation 更新、monitoring をカバー。単純な場合は「None」と簡潔な説明を記述。

### Commit Script

`plugins/drivin/skills/commit/sh/commit.sh` script が commit workflow を実装します：

1. **Pre-flight check**: Branch 上にあることを確認（detached HEAD でない）
2. **Staging**: File が指定されている場合はそれらのみを stage。File が指定されていない場合は追跡されている全ての変更を stage（`git add -u`）。`git add -A` は使用しない。
3. **Review**: Stage された変更の diff summary を表示
4. **Commit**: 構造化 message で commit を作成

Script は file が既に stage されている場合のための `--skip-staging` flag を受け付けます。

### Trip Commit Format (Trippin)

Trippin plugin は `plugins/trippin/skills/trip-protocol/sh/trip-commit.sh` を通じて独自の commit format を使用します。Message format は `trip(<agent>): <step>` で、phase 情報を body に含みます。これにより 3 つの agent 間の協調プロセスをたどる linear commit history が生成されます。

### Archive Workflow

`plugins/drivin/skills/archive-ticket/sh/archive.sh` script が ticket の archive を処理します：

1. Ticket を `todo/` または `icebox/` から `archive/<branch>/` に移動
2. Archive された ticket を含む全ての変更を stage（`git add -A`）
3. `--skip-staging` flag で commit script に委譲
4. Ticket frontmatter を commit hash と category で更新
5. Frontmatter 更新を含めるために commit を amend

Script は commit title から category を推測します（Add/Create/Implement -> "Added"、Remove/Delete -> "Removed"、default -> "Changed"）。

## Story Generation and PR Description

### Story Writer Agent

`story-writer` subagent（`plugins/drivin/agents/story-writer.md`）は 5 つの phase で story 生成を orchestrate します：

**Phase 0: Gather Context**
- `gather-git-context` skill を使用して branch、base_branch、repo_url、archived_tickets、git_log を取得

**Phase 1: Invoke Story Generation Agents**
- Task tool を介して 4 つの agent を並行 invoke（1 つのメッセージで 4 つの tool call）：
  - `release-readiness` (model: opus) - branch の release readiness を分析
  - `performance-analyst` (model: opus) - 意思決定の quality を評価
  - `overview-writer` (model: opus) - overview、highlights、motivation、journey を生成
  - `section-reviewer` (model: opus) - section 5-8（Outcome、Historical Analysis、Concerns、Ideas）を生成

**Phase 2: Write Story File**
- Archive された ticket から source data を収集
- `write-story` skill template に従って `.workaholic/stories/<branch-name>.md` を記述
- `.workaholic/stories/README.md` index を更新

**Phase 3: Commit and Push Story**
- Story file を stage（`git add .workaholic/stories/`）
- `Add branch story for <branch-name>` というメッセージで commit
- Branch を push（`git push -u origin <branch-name>`）

**Phase 4: Create PR and Generate Release Note（順次実行）**
- まず `pr-creator` を invoke（`subagent_type: "drivin:pr-creator"`, `model: "opus"`）：story file を読み取り、title を導出、`gh` CLI 操作を実行、PR URL を返す
- 次に `release-note-writer` を invoke（`subagent_type: "drivin:release-note-writer"`, `model: "haiku"`）：pr-creator から PR URL を受け取り、story file を読み取り、簡潔な release note を生成、`.workaholic/release-notes/<branch-name>.md` に書き込む
- pr-creator response から PR URL を capture

**Phase 5: Commit and Push Release Notes**
- Release note を stage（`git add .workaholic/release-notes/`）
- `Add release notes for <branch-name>` というメッセージで commit
- 変更を push

### Story Content Structure

Story file（`write-story` skill template）は frontmatter 付きの 11 section を含みます：

```yaml
---
branch: <branch-name>
started_at: <from performance-analyst metrics>
ended_at: <from performance-analyst metrics>
tickets_completed: <count of tickets>
commits: <from performance-analyst metrics>
duration_hours: <from performance-analyst metrics>
duration_days: <from performance-analyst metrics if available>
velocity: <from performance-analyst metrics>
velocity_unit: <from performance-analyst metrics>
---
```

並行 agent 出力から populate される section：

1. **Overview**（overview-writer から）- 2-3 文の要約 + 3 つの highlight
2. **Motivation**（overview-writer から）- commit context から「なぜ」を統合した段落
3. **Journey**（overview-writer から）- Mermaid flowchart + prose summary
4. **Changes**（archived ticket から）- commit hash link 付きの ticket ごとの subsection
5. **Outcome**（section-reviewer から）- 何が達成されたか
6. **Historical Analysis**（section-reviewer から）- 過去の関連作業からの context
7. **Concerns**（section-reviewer から）- リスク、トレードオフ、発見された問題
8. **Ideas**（section-reviewer から）- 将来の作業のための enhancement suggestion
9. **Performance**（performance-analyst から）- metrics JSON + decision review markdown
10. **Release Preparation**（release-readiness から）- verdict、concerns、pre/post-release instructions
11. **Notes**（optional）- reviewer のための追加 context

Story file は PR description として機能します（YAML frontmatter は `create-or-update.sh` によって除去されます）。

## Documentation Generation

### Scan Command

`/scan` command（`plugins/drivin/commands/scan.md`）は全ての `.workaholic/` documentation（changelog、specs、terms、policies）を更新します。3 つの manager agent、次に 13 の leader/writer agent を並行 invoke します：

**Phase 1: Gather Context**
- `gather-git-context` skill を使用して branch、base_branch、repo_url を取得
- Commit hash を取得（`git rev-parse --short HEAD`）

**Phase 2: Select Agents**
- `select-scan-agents` skill を実行：`bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/select-scan-agents/sh/select.sh full`
- JSON 出力を parse して manager と leader agent のリストを取得

**Phase 3a: Invoke Manager Agents in Parallel**
- 並行 Task tool call で 1 つのメッセージで 3 つの manager を invoke（各 model: sonnet）：
  - `project-manager` - base branch を渡す
  - `architecture-manager` - base branch を渡す
  - `quality-manager` - base branch を渡す
- 続行前に全ての manager の完了を待つ

**Phase 3b: Invoke Leader and Writer Agents in Parallel**
- 並行 Task tool call で 1 つのメッセージで 13 の leader/writer を invoke（各 model: sonnet）：
  - `ux-lead`、`model-analyst`、`infra-lead`、`db-lead`（viewpoint lead）
  - `test-lead`、`security-lead`、`quality-lead`、`a11y-lead`、`observability-lead`、`delivery-lead`、`recovery-lead`（policy lead）
  - `changelog-writer`、`terms-writer`（content writer）
- 全ての invocation は `run_in_background: false` を使用する必要があります（agent は interactive prompt access を必要とする Write/Edit permission が必要）

**Phase 4: Validate Output**
- `validate-writer-output` skill を使用して viewpoint spec 出力を検証
- `validate-writer-output` skill を使用して policy 出力を検証

**Phase 5: Update Index Files**
- Spec validation が pass した場合、`.workaholic/specs/README.md` と `README_ja.md` を更新
- Policy validation が pass した場合、`.workaholic/policies/README.md` と `README_ja.md` を更新

**Phase 6: Stage and Commit**
- 全ての documentation を commit：`git add CHANGELOG.md .workaholic/specs/ .workaholic/terms/ .workaholic/policies/ .workaholic/constraints/ && git commit -m "Update documentation"`

**Phase 7: Report Results**
- どの agent が成功、失敗、またはスキップされたかを示す per-agent status を report

### Policy Analysis

`analyze-policy` skill（`plugins/drivin/skills/analyze-policy/SKILL.md`）は特定の policy domain から repository を分析するための汎用 framework を提供します。Bundled script を使用して context を収集します：

```bash
bash ~/.claude/plugins/marketplaces/workaholic/plugins/drivin/skills/analyze-policy/sh/gather.sh <policy-slug> [base-branch]
```

Policy document は厳格な推論ルールに従います：**実装されているもののみを文書化**。全ての policy statement は実際に実装され実行可能な codebase 内の何か - CI check、hook、script、linter rule、または test - を記述する必要があります。各 statement の後に、それを実装するメカニズムを引用します。Gap は省略するのではなく「Not observed」で明確にマークします。

## Artifact Promotion Flow

### No Multi-Environment Promotion

観察されず。Environment 間（dev -> staging -> production）の artifact promotion は存在しません。`main` branch の source file が正規版です。

### Version as Promotion Gate

Version increment が promotion gate として機能します。Increment された version で `main` にマージすると release 作成が trigger されます。Release workflow が最終的な promotion step として機能します。

## Observations

- CI validation は behavioral testing や type checking ではなく、構造的整合性（valid JSON、必須 field、file existence）に焦点を当てている
- Release process は半自動：開発者が `/release` で version を bump、GitHub workflow がマージ時に release を作成
- 3 つの version file が単一の source of truth から派生するのではなく、command による手動同期が必要：marketplace.json root、drivin plugin.json、trippin plugin.json
- Release note は PR 作成時（`/report` 経由）に生成され、release 時に GitHub workflow によって使用される
- PR の作成と更新は deprecated GraphQL endpoint を避けるため、異なるメカニズム（CLI vs REST API）を使用
- 各 ticket 実装は `/drive` 中に個別の commit を作成し、粒度の細かい変更追跡を可能にする
- Story 生成は 6 つの subagent を invoke：story content 用に 4 つを並行、その後 pr-creator と release-note-writer を順次実行（release note に PR URL を含めるため pr-creator を先に実行）
- `/scan` command は `.workaholic/` documentation を更新するため、16 の documentation agent を invoke（最初に 3 つの manager、次に 13 の leader/writer）
- Documentation 生成は code 変更から切り離され、`/scan` を通じて明示的に trigger される
- Commit message 構造は lead agent が diff を読まずに parse できる構造化 section（Description、Changes、Test Planning、Release Preparation）を提供
- Archive workflow は ticket を archive directory に移動した後にのみ `git add -A` を使用し、その後 frontmatter 更新のために特定の file を stage
- Git hook は active でない（`.git/hooks/` には sample hook のみ存在）
- Commit script は他の contributor の uncommitted file を誤って stage しないよう `git add -A` を使用しない
- Commit workflow に multi-contributor 認識が組み込まれている：他の人の uncommitted work を含めないよう、commit 前に staged 変更を review
- Version bump の冪等性 check により、同じ branch で `/report` が複数回実行された際の二重 bump を防ぐ（`branching` skill 経由で `git log main..HEAD --oneline --grep="Bump version"` を使用）
- Branch 操作（check、create、version bump detection）は markdown file 内の inline command ではなく、`branching` skill の shell script に抽出される
- `/scan` command は manager constraint file を capture するため、commit step に `.workaholic/constraints/` を含む
- Trippin plugin は git worktree を分離に使用し、協調プロセスの完全なトレースを生成する commit-per-step discipline を持つ第 2 の delivery workflow を導入
- Trippin の Agent Teams session は experimental flag `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が必要
- Plugin directory が `core` から `drivin` にリネームされ、全ての subagent_type 参照が `core:` prefix から `drivin:` prefix に更新された
- `select-scan-agents` の partial mode は変更された file に基づいてどの agent を invoke するかを決定する path ベースのヒューリスティックを使用し、`plugins/drivin/` path を参照

## Gaps

- 観察されず：Release 前に plugin の変更をテストするための staging または preview environment がない
- 観察されず：新しい version の canary または段階的 rollout メカニズムがない
- 観察されず：Release が問題を引き起こした場合の自動 rollback 機能がない
- 観察されず：Release 前に changelog が更新されていることを確認する changelog validation がない
- 観察されず：CI での自動 dependency scanning または security vulnerability check がない
- 観察されず：CI pipeline での performance benchmarking または regression detection がない
- 観察されず：Release deployment 後の自動 smoke test または integration test がない
- 観察されず：Pre-commit または pre-push validation のための git hook がない（sample hook のみ存在）
- 観察されず：Commit message format の自動強制がない（構造は git hook ではなく、commit skill による convention で強制される）
- 観察されず：Trippin trip branch 用の PR 作成や story 生成 workflow がない（Drivin branch のみが `/report` を使用）
- 観察されず：Trip 完了後の worktree directory の自動クリーンアップがない
