---
title: Infrastructure Viewpoint
description: 外部依存関係、ファイルシステムレイアウト、インストール、環境要件
category: developer
modified_at: 2026-02-11T23:19:58+08:00
commit_hash: f7f779f
---

[English](infrastructure.md) | [Japanese](infrastructure_ja.md)

# Infrastructure Viewpoint

この viewpoint は、Workaholic plugin system の外部依存関係、ファイルシステム構成、インストール手順、実行環境要件について説明します。Workaholic は Claude Code plugin marketplace であり、command、subagent、skill、rule の階層化アーキテクチャを通じて ticket 駆動開発 workflow を提供します。

## External Dependencies

Workaholic は Claude Code plugin system を実行環境として依存し、version 管理、継続的統合、package 管理のためのいくつかの外部 tool や service と統合しています。

### Claude Code Runtime

Plugin system は Claude Code を host 環境として必要とします。Claude Code は plugin loading mechanism、command dispatch、Task tool による subagent invocation、hook による permission 管理を提供します。`.claude-plugin/marketplace.json` の marketplace configuration は、Claude Code が plugin を load するために使用する marketplace metadata、version、plugin list を指定します。

各 plugin directory には `.claude-plugin/plugin.json` ファイルが含まれており、plugin metadata(name、version、description、author 情報)を定義します。この configuration は Claude Code plugin specification format に従います。

### Version Control Tools

Git は必須の依存関係であり、branch 管理、commit 操作、repository context 収集のために system 全体で使用されます。Skills directory 内の shell script は git command を実行して、branch 名、base branch、commit hash、repository URL を抽出します。System は `origin` という名前の remote が存在し、default branch(通常は `main`)を持つ trunk-based workflow に従うことを前提としています。

GitHub CLI tool(`gh`)は、pull request をプログラム的に作成・更新するために create-pr skill で使用されます。`.github/workflows/release.yml` の release workflow も、version tag 付きの GitHub release を作成するために `gh` を使用します。

### Build and Validation Tools

Node.js version 20 は GitHub Actions validation workflow に必要です。Validation pipeline は、`marketplace.json` や `plugin.json` を含む configuration file の JSON parsing と validation に `jq` を使用します。

Plugin 自体は markdown configuration file と shell script のみで構成されているため、build step は不要です。Compilation や transpilation の step はありません。

### Continuous Integration Platform

GitHub Actions は以下の 2 つの workflow で CI/CD infrastructure を提供します:

1. **validate-plugins.yml** は push と pull request event で実行され、JSON configuration file の validation、必須 field の確認、skill file の存在確認、marketplace plugin と directory 構造の一致確認を行います。

2. **release.yml** は main branch への push と workflow dispatch event で実行されます。`marketplace.json` の version を最新の GitHub release と比較し、`.workaholic/release-notes/` から release note を抽出し、必要に応じて version tag 付きの新しい GitHub release を作成します。

## File System Layout

Repository は plugin source code と working artifact を分離する dual-directory 構造に従っています。

### Root Directory Structure

```
/
├── .claude/                 # Claude Code configuration (symlink target)
│   ├── commands/            # Symlinked from plugins/core/commands/
│   ├── rules/               # Repository-scoped enforcement rules
│   │   ├── define-lead.md   # Lead agent schema enforcement
│   │   └── define-manager.md # Manager agent schema enforcement
│   ├── settings.json        # Claude Code permissions (denies git -C)
│   └── settings.local.json  # Local environment overrides
├── .claude-plugin/          # Marketplace configuration
│   └── marketplace.json     # Version and plugin registry
├── .github/                 # CI/CD workflows
│   └── workflows/
│       ├── release.yml      # Automated release creation
│       └── validate-plugins.yml  # Plugin validation on PR
├── .workaholic/             # Working artifacts (user/developer docs)
│   ├── guides/              # User-facing documentation
│   ├── policies/            # Policy analysis documents
│   ├── release-notes/       # Generated release notes
│   ├── specs/               # Viewpoint-based architecture specs
│   ├── stories/             # Development narratives per branch
│   ├── terms/               # Consistent term definitions
│   └── tickets/             # Work queue and archives
│       ├── todo/            # Pending implementation tickets
│       ├── icebox/          # Deferred tickets
│       ├── archive/         # Completed tickets by branch
│       └── abandoned/       # Cancelled tickets
├── plugins/                 # Plugin source directories
│   └── core/                # Core development plugin
│       ├── .claude-plugin/  # Plugin metadata
│       │   └── plugin.json  # Plugin configuration
│       ├── agents/          # Subagent definitions (markdown)
│       ├── commands/        # Command definitions (markdown)
│       ├── hooks/           # PostToolUse hooks
│       │   ├── hooks.json   # Hook configuration
│       │   └── validate-ticket.sh  # Ticket validation hook
│       ├── rules/           # Global rules (markdown)
│       └── skills/          # Reusable knowledge modules
│           └── <skill-name>/
│               ├── SKILL.md  # Skill documentation
│               └── sh/       # Bundled shell scripts
│                   └── *.sh  # Executable scripts
├── CHANGELOG.md             # Auto-generated changelog
├── CLAUDE.md                # Project instructions for Claude Code
└── README.md                # User-facing documentation
```

この構造は、plugin 開発が `plugins/` directory で行われ、Claude Code は plugin installation 時に確立された symlink を通じて `.claude/` から読み取るという原則を反映しています。

### Directory Purpose Classification

File system layout は関心事を 3 つのカテゴリに分離します:

**Configuration directories**(`.claude/`、`.claude-plugin/`、`.github/`)は、環境 configuration、marketplace metadata、CI/CD workflow を含みます。これらは system が実行環境とどのように統合するかを定義します。

**Working artifact directories**(`.workaholic/`)は、生成された documentation、ticket、開発 narrative を保存します。これらは version 管理された出力であり、将来の開発判断のための context を提供します。

**Source directories**(`plugins/core/`)は、command、subagent、skill、rule、hook を含む plugin 実装を含みます。これらは plugin の動作の権威ある source です。

### Schema Enforcement Rules

`.claude/rules/` directory には、agent と skill の構造を validation する path-scoped schema enforcement rule が含まれています。これらの rule は Claude Code によって load され、一致する file path に自動的に適用されます。

#### Lead Agent Schema

`define-lead.md` rule は lead agent skill と agent file の構造を強制します:

- **Skill path scope**: `plugins/core/skills/lead-*/SKILL.md`
- **Agent path scope**: `plugins/core/agents/*-lead.md`
- **Required sections**: Role、Responsibility、Default Policies(Implementation、Review、Documentation、Execution)

この schema に従う例には、`lead-infra`、`lead-security`、`lead-quality`、`lead-test`、`lead-a11y`、`lead-db`、`lead-delivery`、`lead-recovery`、`lead-observability`、`lead-ux` が含まれます。

#### Manager Agent Schema

`define-manager.md` rule は manager agent skill と agent file の構造を強制します:

- **Skill path scope**: `manage-project`、`manage-architecture`、`manage-quality` の明示的な path(utility skill である `manage-branch` とのマッチングを回避)
- **Agent path scope**: `plugins/core/agents/*-manager.md`
- **Required sections**: Role、Responsibility、Goal、Outputs、Default Policies(Implementation、Review、Documentation、Execution)
- **主な違い**: `Outputs` section は manager が lead が consume するために生成する構造化 artifact を定義

現在の manager には `project-manager`、`architecture-manager`、`quality-manager` が含まれます。これらは agent hierarchy において lead の上に位置し、strategic context を提供します。

### Skill Directory Structure Pattern

Skill は documentation と実行可能な shell script を bundle する標準化された layout に従います:

```
skills/<skill-name>/
├── SKILL.md              # Markdown documentation with frontmatter
└── sh/                   # Shell script directory
    ├── <action>.sh       # Primary script (e.g., gather.sh, validate.sh)
    └── ...               # Additional helper scripts if needed
```

各 skill の `SKILL.md` には、skill 名、description、allowed tool、user-invocability を指定する frontmatter が含まれます。`sh/` directory 内の bundled shell script は、command や subagent markdown file に inline で記述すると shell script principle に違反する複雑な multi-step 操作の permission-free 実行を提供します。

#### Skill Categories by Purpose

Skill は architecture において 4 つの異なる目的を果たします:

**Lead と manager domain skill** は role 固有の責任と policy を定義します。これらの skill は agent によって preload され、user によって直接 invoke されることはありません。例には `lead-infra`(infrastructure 関心事)、`manage-architecture`(system 構造)、`manage-quality`(quality 基準)が含まれます。

**Cross-cutting policy skill** は複数の agent に適用される behavioral policy を定義します。`leaders-policy` skill は全ての lead agent に Prior Term Consistency と Vendor Neutrality rule を提供します。`managers-policy` skill は manager agent に Strategic Focus rule を追加します。

**Workflow operation skill** は bundled shell script で multi-step process を orchestrate します。例には `gather-git-context`(branch、base_branch、repo_url を含む JSON を出力)、`archive-ticket`(ticket の移動、commit 作成、frontmatter 更新)、`select-scan-agents`(diff 分析に基づいて invoke する agent を決定)が含まれます。

**Documentation generation skill** は構造化 document を記述するための template と guideline を提供します。例には `write-spec`(viewpoint ベースの architecture spec)、`analyze-viewpoint`(汎用 viewpoint 分析 framework)、`translate`(markdown file の i18n policy)が含まれます。

### Symlink Architecture

`.claude/` directory は Claude Code plugin installation target として機能します。Marketplace plugin がインストールされると、Claude Code は `.claude/` から `plugins/core/` 内の実際の plugin source への symlink を作成します。これにより、repository は plugin source を Claude Code configuration directory とは別に維持しながら、Claude Code が plugin を正しく load できるようになります。

Symlink 構造は以下の通りです:

```
.claude/commands -> plugins/core/commands
.claude/agents -> plugins/core/agents
.claude/skills -> plugins/core/skills
.claude/rules -> plugins/core/rules
```

このアーキテクチャにより、開発は `plugins/` で行い、Claude Code は `.claude/` で動作することが可能になり、`CLAUDE.md` に記載された重要なルール「`plugins/` を編集し、`.claude/` は編集しない」に従います。

## Installation

Installation は `/plugin` command interface を使用した Claude Code plugin marketplace system を通じて行われます。

### Installation Command

User は以下を使用して Workaholic marketplace をインストールします:

```bash
claude
/plugin marketplace add qmu/workaholic
```

この command は Claude Code に repository から marketplace configuration を fetch し、`marketplace.json` file を parse して marketplace を register するよう指示します。Marketplace reference `qmu/workaholic` は、owner email `a@qmu.jp` に基づいて GitHub repository `tamurayoshiya/workaholic` にマップされます。

### Plugin Activation

Marketplace installation 後、user は Claude Code interface を通じて plugin を有効化する必要があります。Plugin system は auto-update mode をサポートしており、release された新しい version を自動的に受け取るために推奨されます。

有効化されると、Claude Code は:

1. `.claude/` directory が存在しない場合は作成
2. `.claude/` から `plugins/core/` subdirectory への symlink を確立
3. `commands/*.md` file から command definition を load
4. `agents/*.md` file から subagent を register
5. `skills/*/SKILL.md` file から runtime で skill を利用可能に
6. `rules/*.md` file から global rule を適用
7. `hooks/hooks.json` から PostToolUse hook をインストール

### Hook Installation

Plugin は Write または Edit 操作後に ticket file format と location を validation する PostToolUse hook をインストールします。`plugins/core/hooks/hooks.json` の hook configuration は、Write と Edit tool の matcher を指定し、10 秒の timeout で `validate-ticket.sh` script を実行します。

この hook は ticket naming convention(YYYYMMDDHHmmss-*.md pattern)と location 制約(`todo/`、`icebox/`、または `archive/<branch>/` directory に存在する必要がある)を強制します。Validation script は frontmatter field をチェックします: `created_at`(ISO 8601 format)、`author`(email format、anthropic.com domain を拒否)、`type`(enhancement/bugfix/refactoring/housekeeping)、`layer`(UX/Domain/Infrastructure/DB/Config)、`effort`(0.1h/0.25h/0.5h/1h/2h/4h)、`commit_hash`(7-40 hex 文字)、`category`(Added/Changed/Removed)。

### Configuration Files

Installation process はいくつかの configuration file を作成または更新します:

**`.claude/settings.json`** は permission 設定を含みます。Default configuration は、shell script principle を回避する可能性のある directory-scoped git 操作を防ぐために、bash command pattern `git -C:*` を deny します。

**`.claude/settings.local.json`** は、version 管理された configuration に影響を与えることなく、developer が設定を local で override できるようにします。この file は `.gitignore` にリストされています。

### Version Synchronization

Installation は以下で version が同期されていることを validation します:

- `.claude-plugin/marketplace.json` の root `version` field
- `plugins/core/.claude-plugin/plugin.json` の plugin `version` field

両方の file は同じ version 番号(現在は `1.0.34`)を指定する必要があります。Version bump は一貫性を維持するために両方の file を同時に更新します。

## Environment Requirements

System は正しく動作するために特定の実行環境とファイルシステム permission を必要とします。

### Runtime Platform

Claude Code は bash または zsh shell を持つ POSIX 互換 system 上で実行されている必要があります。Skill 内の bundled shell script は `/bin/sh -eu` shebang と POSIX 準拠の構文を使用しており、異なる Unix-like 環境間での互換性を保証します。

System は macOS(Darwin 24.6.0)でテストされていますが、bash、git、および標準の Unix utility を提供する Linux distribution でも動作するはずです。

### Required Shell Utilities

Script は PATH で利用可能な標準の Unix utility に依存します:

- `git` - version 管理操作
- `jq` - validation workflow と hook script での JSON parsing
- `sed`、`grep`、`cut`、`tr`、`awk` - テキスト処理
- `date` - timestamp 生成
- `mkdir`、`mv`、`ls` - ファイルシステム操作
- `cat`、`echo` - 出力生成

Shell script はこれらの utility が標準的な動作と exit code に従うことを前提としています。`gather-git-context` script は URL 変換と JSON escape のために POSIX 準拠の sed 構文を使用します。`validate-ticket.sh` hook は `[[ ]]` conditional や regex matching などの bash 固有の feature を使用します。

### Git Repository Requirements

System は以下を持つ Git repository 内で動作する必要があります:

- GitHub repository を指す `origin` という名前の remote
- HEAD branch として構成された default branch(通常は `main`)
- Branch の作成、変更の commit、remote への push のための書き込みアクセス
- Ticket 操作中は detached HEAD state にならないこと

Archive-ticket skill は ticket をアーカイブする前に named branch が存在することを validation し、detached HEAD scenario からのデータ損失を防ぎます。Gather-git-context script は `git remote show origin` から base branch を抽出し、表示目的で SSH URL を HTTPS format に変換します。

### File System Permissions

System は以下への読み書きアクセスを必要とします:

- `.workaholic/` directory と全 subdirectory - ticket、spec、guide、policy、term、story、release note の保存
- `CHANGELOG.md` - 自動 changelog 更新
- `CLAUDE.md`、`README.md`、`plugins/core/README.md` - documentation 更新
- `.claude-plugin/marketplace.json` と `plugins/core/.claude-plugin/plugin.json` - version 管理

PostToolUse hook は ticket write を validation するために `plugins/core/hooks/validate-ticket.sh` への実行 permission を必要とします。`plugins/core/skills/*/sh/` directory 内の全ての bundled shell script は実行 permission を必要とします。

### GitHub Authentication

Release workflow と create-pr skill は `GITHUB_TOKEN` secret を通じた GitHub 認証を必要とします。GitHub Actions は CI 環境でこれを自動的に提供します。Local 開発では `gh` CLI tool が `gh auth login` を介して認証されている必要があります。

### Permission Model

Claude Code は settings.json configuration を通じて permission を強制します。Default permission model:

- **Denies**: directory-scoped git 操作を防ぐために `git -C` command を deny
- **Allows**: 現在の directory での直接 git command を含む他の全ての Bash command を allow
- **Validates**: PostToolUse hook を通じて `.workaholic/tickets/` file への Write と Edit 操作を validate

この permission model は、複雑な inline git 操作を非実用的にすることで shell script principle を強制し、developer が代わりに bundled skill script にロジックを抽出することを奨励します。

### Environment Variables

Shell script は標準の環境変数を使用します:

- `CLAUDE_PLUGIN_ROOT` は Claude Code によって plugin directory を指すように設定され、hook が validation script を見つけるために使用
- 標準の git 環境変数(GIT_AUTHOR_NAME、GIT_AUTHOR_EMAIL など)は commit 操作で尊重される

基本操作にカスタム環境変数は不要です。

### Agent Orchestration

System は現在、manager が lead に strategic context を提供する 2 層の agent hierarchy を採用しています:

**Manager tier** agent(`project-manager`、`architecture-manager`、`quality-manager`)は `/scan` 操作時に最初に実行されます。これらは codebase を分析し、business context、system architecture、quality 基準を定義する構造化出力を生成します。

**Lead tier** agent(11 の domain 固有 lead、`infra-lead`、`security-lead`、`quality-lead` など)は manager output を consume して domain 固有の documentation を生成します。これらは domain skill(`lead-<specialty>`)と cross-cutting `leaders-policy` skill の両方を preload します。

この orchestration pattern により、lead は独立して strategic context を導出するのではなく、一貫した strategic context を受け取ることができます。`/scan` command は実行順序を調整し、lead の前に manager を invoke します。

## Assumptions

[Explicit] `.claude-plugin/marketplace.json` file は version 1.0.34 と owner email a@qmu.jp を指定しており、現在の marketplace version と ownership を示しています。

[Explicit] `.github/workflows/` の GitHub Actions workflow は Node.js 20 を必要とし、workflow YAML file で指定されているように JSON validation に `jq` を使用します。

[Explicit] Shell script は `/bin/sh -eu` shebang と POSIX 準拠の構文を使用しており、`gather-git-context/sh/gather.sh` で観察されます。Ticket validation hook は bash 固有の regex feature のために `/bin/bash` を使用します。

[Explicit] `plugins/core/hooks/hooks.json` の PostToolUse hook configuration は 10 秒の timeout で Write と Edit 操作を validation します。

[Explicit] `.claude/settings.json` file は Bash command pattern `git -C:*` を明示的に deny します。

[Explicit] `define-manager.md` schema enforcement rule は、utility skill である `manage-branch` とのマッチングを回避するために glob pattern ではなく明示的な skill path を使用します。

[Explicit] Manager agent(`project-manager`、`architecture-manager`、`quality-manager`)は `managers-policy` skill を preload し、lead agent は `leaders-policy` skill を preload します。

[Inferred] `.claude/` から `plugins/core/` への symlink architecture は、project 構造ルール「`plugins/` を編集し、`.claude/` は編集しない」と marketplace installation pattern から推測されますが、明示的な symlink 作成 code は観察されませんでした。

[Inferred] GitHub CLI tool(`gh`)は、create-pr skill が `gh pr create` command を参照していることに基づいて PR 作成に必要ですが、明示的なインストール documentation は存在しません。

[Inferred] Release workflow は workflow script logic `ls -t .workaholic/release-notes/*.md | grep -v README.md | head -1` に基づいて、`.workaholic/release-notes/` 内の最も最近変更された file から release note を抽出します。

[Inferred] Permission model は、`CLAUDE.md` の複雑な inline command を禁止する architecture policy に基づいて、inline conditional よりも shell script 抽出を優先し、`git -C` denial pattern を通じて強制されます。

[Inferred] Ticket validation hook は path 制約を強制することで任意の location への偶発的な ticket write を防ぎ、ticket が指定された directory に整理された状態を保つことを保証します。

[Inferred] Manager tier は lead agent 間での strategic 分析の重複を減らすために導入されました。この変更以前は、各 lead が独立して business と architectural context を導出していました。
