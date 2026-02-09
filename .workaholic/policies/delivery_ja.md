---
title: Delivery Policy
description: CI/CD pipeline、release process、deployment 実践
category: developer
modified_at: 2026-02-09T04:52:24+09:00
commit_hash: d627919
---

[English](delivery.md) | [Japanese](delivery_ja.md)

# Delivery Policy

この文書は、Workaholic repository で観察された継続的インテグレーション、デリバリー、release の実践を記述します。Delivery は GitHub Actions workflow と plugin command によって自動化されています。repository は ticket 駆動の開発 workflow に従い、実装作業は仕様から release まで構造化されたステージを通過します。

## CI/CD Pipeline

### Plugin Validation Workflow

`validate-plugins.yml` workflow は `main` への push と pull request のたびに実行されます (`on: push/pull_request: branches: [main]`)。`ubuntu-latest` と Node.js 20 で 4 つの validation step を実行します：

1. **Marketplace JSON validation**: `.claude-plugin/marketplace.json` が文法的に正しい JSON であることを `jq empty` で検証します (step: "Validate marketplace.json")
2. **Plugin metadata validation**: 各 `plugin.json` が必須 field (`name`, `version`) を含むことを `jq -r` での抽出と null check で検証します (step: "Validate plugin.json files")
3. **Skill file existence check**: `plugin.json` で参照される全ての skill file が disk 上に存在することを `jq -r '.skills[]?.path'` と file existence test で確認します (step: "Check skill files exist")
4. **Plugin directory consistency**: `marketplace.json` に列挙された全ての plugin が `plugins/` 内に対応する directory を持つことを確認します (step: "Validate marketplace plugins match directories")

Validation は `jq` を用いた shell script を使用します。validation が失敗すると workflow は exit code 1 で終了します。

### CI Environment

CI は `ubuntu-latest` (`runs-on: ubuntu-latest`) と Node.js 20 (`uses: actions/setup-node@v4 with: node-version: '20'`) で実行されます。environment は validation に標準的な Unix tool (`jq`, `awk`, `grep`, shell scripting) を使用し、compile や build は行いません。

### No Build Step

Build や compilation step は存在しません。repository は markdown configuration file、shell script、JSON metadata を含みます。Validation は構造的整合性を確認しますが、変換や bundling は行いません。

## Build Process

### No Artifact Generation

観察されず。Claude Code plugin として、Workaholic は compiled artifact を生成しません。source file が配布可能な asset です。

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

2 つの version file が同期されている必要があります：

- `.claude-plugin/marketplace.json` - root の `version` field と `plugins[].version` entry
- `plugins/core/.claude-plugin/plugin.json` - plugin の `version` field

`/release` command (`.claude/commands/release.md`) が version の同期を処理します。`major`、`minor`、または `patch`（default）を引数として受け取り、version を semantic に increment し、全ての version field を更新します。

### Release Command Workflow

`/release` command は以下の順序で実行されます：

1. `.claude-plugin/marketplace.json` から現在の version を読み取る
2. 引数に基づいて version を increment する（default: `patch`）
3. `.claude-plugin/marketplace.json` の `version` field を更新
4. `plugins/core/.claude-plugin/plugin.json` の `version` field を更新
5. `marketplace.json` 内の `plugins` array の plugin version entry を更新
6. `plugins/core/commands/sync-work.md` を読み取って指示に従い、documentation を同期
7. `Release v{new_version}` というメッセージで commit
8. Remote に push

Release command は semantic versioning を使用します（例：`1.0.33`）。

### Automated Release Notes

Release workflow は git log 抽出よりも `.workaholic/release-notes/<branch-name>.md` の生成済み release note を優先します。`release-note-writer` subagent（`story-writer.md` で参照される `plugins/core/agents/release-note-writer.md`）は `/report` command を通じて PR 作成時に release note を生成します。

Release note 生成は release 時ではなく PR 作成時に行われます。Workflow は利用可能な場合、事前生成された note を使用します。

### Manual Version Bump Required

Version bump は自動ではなく手動です（開発者が `/release` command を実行）。GitHub workflow は version の変更を検出しますが、作成はしません。これにより意図しない version 変更からの偶発的な release を防ぎます。

## Branch Strategy

### Branch Naming Convention

開発 branch は以下のパターンに従います：

- `drive-<YYYYMMDD>-<HHMMSS>` - ticket 駆動開発 branch
- `trip-<YYYYMMDD>-<HHMMSS>` - 代替 branch タイプ（明示的に文書化されていない）

Base branch は `main` です。全ての pull request は `main` を target とします。

### PR Creation Workflow

`/report` command（`plugins/core/commands/report.md` で参照）が PR 作成を orchestrate します：

1. CLAUDE.md の Version Management に従って version を bump（patch increment）
2. `story-writer` subagent を invoke（`subagent_type: "core:story-writer"`, `model: "opus"`）
3. story-writer の結果から PR URL を表示

`story-writer` subagent（`plugins/core/agents/story-writer.md`）は branch story を生成し、commit し、`pr-creator` subagent を `release-note-writer` と並行して invoke し、PR URL を出力します。

### PR Creation Script

`plugins/core/skills/create-pr/sh/create-or-update.sh` script が PR 操作を処理します：

1. `.workaholic/stories/<branch-name>.md` から YAML frontmatter を `awk` で除去
2. `gh pr list --head "$BRANCH"` を使用して PR が存在するか確認
3. PR が存在しない場合：`gh pr create --title "$TITLE" --body-file /tmp/pr-body.md` で作成
4. PR が存在する場合：GitHub REST API を使用して `gh api repos/{REPO}/pulls/{NUMBER} --method PATCH` で更新

Script は GraphQL Projects deprecation error を避けるため、更新に REST API を使用します（script 内のコメント：`# Update existing PR via REST API (avoids GraphQL Projects deprecation error)`）。

### Ticket-Driven Workflow

`/drive` command は `.workaholic/tickets/todo/` から ticket を順次実装します。各 ticket について：

1. Ticket の仕様に従って変更を実装
2. 選択可能な option でユーザー承認を要求
3. Ticket frontmatter を effort と Final Report で更新
4. `archive-ticket` skill を使用して `.workaholic/tickets/archive/<branch>/` に ticket を archive
5. 構造化された message format を使用して commit（`archive-ticket/SKILL.md` で参照される `format-commit-message` skill から）

`/drive` command は各 ticket を個別に commit し、実装された ticket ごとに commit を作成します。

## Artifact Promotion Flow

### No Multi-Environment Promotion

観察されず。Environment 間（dev → staging → production）の artifact promotion は存在しません。`main` branch の source file が正規版です。

### Version as Promotion Gate

Version increment が promotion gate として機能します。Increment された version で `main` にマージすると release 作成が trigger されます。Release workflow が最終的な promotion step として機能します。

## Observations

- CI validation は behavioral testing や type checking ではなく、構造的整合性（valid JSON、必須 field、file existence）に焦点を当てている
- Release process は半自動：開発者が `/release` で version を bump、GitHub workflow がマージ時に release を作成
- Version file は単一の source of truth から派生するのではなく、command による手動同期が必要
- Release note は PR 作成時（`/report` 経由）に生成され、release 時に GitHub workflow によって使用される
- PR の作成と更新は deprecated GraphQL endpoint を避けるため、異なるメカニズム（CLI vs REST API）を使用
- 各 ticket 実装は `/drive` 中に個別の commit を作成し、粒度の細かい変更追跡を可能にする
- Branch story 生成は Task tool を使用して 6 つの subagent を並行 invoke（story content 用に 4 つ、PR 操作用に 2 つ）
- `/scan` command は `.workaholic/` documentation を更新するため、17 の documentation agent を並行 invoke（全て `model: "sonnet"`）
- Documentation 生成は code 変更から切り離され、`/scan` を通じて明示的に trigger される

## Gaps

- 観察されず：Release 前に plugin の変更をテストするための staging または preview environment がない
- 観察されず：新しい version の canary または段階的 rollout メカニズムがない
- 観察されず：Release が問題を引き起こした場合の自動 rollback 機能がない
- 観察されず：Release 前に changelog が更新されていることを確認する changelog validation がない
- 観察されず：CI での自動 dependency scanning または security vulnerability check がない
- 観察されず：CI pipeline での performance benchmarking または regression detection がない
- 観察されず：Release deployment 後の自動 smoke test または integration test がない
