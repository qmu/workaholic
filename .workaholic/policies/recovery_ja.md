---
title: Recovery Policy
description: Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets
category: developer
modified_at: 2026-02-09T04:52:30+0000
commit_hash: d627919
---

[English](recovery.md) | [Japanese](recovery_ja.md)

# Recovery Policy

この文書は、Workaholic repository で観察された backup、recovery、data 復元の実践を記述します。database や永続的な service を持たない git で version 管理された project として、recovery は完全に git history と GitHub の infrastructure に依存します。

## Data Persistence

### Version Control as Primary Storage

すべての project data（markdown document、JSON configuration、shell script）は git で version 管理されています。すべての変更は atomic な commit として記録され、完全な audit trail と `git checkout` または `git revert` による任意の以前の状態への復元機能を提供します。(git version control system)

### Remote Repository Backup

Repository は GitHub の `git@github.com:qmu/workaholic.git` で host されており、project history 全体の remote backup を提供します。Pull request と branch push は GitHub の infrastructure を通じて追加の冗長性を作成します。(`.git/config`、GitHub remote hosting)

### Ticket Archival System

完了した ticket は削除されるのではなく、`.workaholic/tickets/archive/<branch>/` に archive されます。これにより、最終 report と実装詳細を含むすべての変更リクエストの完全な履歴が保持されます。archive-ticket skill（`plugins/core/skills/archive-ticket/sh/archive.sh`）は、ticket を `todo/` から `archive/<branch>/` に移動し、変更を commit し、commit hash と category で ticket frontmatter を更新することで archival workflow を実装します。(`plugins/core/skills/archive-ticket/sh/archive.sh`)

### Abandoned Ticket Preservation

実装できない ticket は、失敗分析とともに `.workaholic/tickets/abandoned/` に移動され、data 損失を防ぎ、意思決定の context を保持します。drive-approval skill は、失敗分析を生成し ticket を abandoned directory に移動する "Abandon" option を提供します。(`plugins/core/skills/drive-approval/SKILL.md`、`.workaholic/tickets/abandoned/`)

## Backup Strategy

### Git History as Continuous Backup

Git の commit history は、連続的な atomic な backup mechanism として機能します。各 commit は復元可能な checkpoint を表します。Repository は最近の履歴に 20 以上の commit を含み、頻繁な backup point を示しています。(git commit history)

### Branch-Based Redundancy

複数の branch が同時に存在し（main、drive-*、feat-*）、冗長性と branch 固有の問題からの復元能力を提供します。manage-branch skill は `<prefix>-YYYYMMdd-HHmmss` パターンで timestamp 付きの topic branch を作成します。(`plugins/core/skills/manage-branch/sh/create.sh`)

### CI Validation Before Merge

GitHub Actions workflow は main branch への merge 前にすべての変更を検証し、無効な状態が primary branch に入ることを防ぎます。validate-plugins workflow は push と pull request event で実行され、JSON の妥当性と file の存在を確認します。(`.github/workflows/validate-plugins.yml`)

### Automated Release Artifacts

Release workflow は version tag と release note を持つ GitHub release を作成し、名前付き recovery point を提供します。Release は marketplace version が増分されたときに main branch への push で trigger されます。(`.github/workflows/release.yml`)

## Migration Procedures

### Configuration File Validation

JSON configuration file（`marketplace.json`、`plugin.json`）は CI workflow を通じてすべての push で検証されます。検証は JSON syntax、必須 field（name、version）、file 参照を確認します。無効な configuration は merge を防ぎ、repository が有効な状態を保つことを保証します。(`.github/workflows/validate-plugins.yml` lines 22-59)

### Frontmatter Schema Enforcement

Ticket file は特定の schema（created_at、author、type、layer、effort）を持つ YAML frontmatter を必要とします。post-write hook は Write または Edit operation の後に ticket frontmatter format を検証します。検証失敗は exit code 2 で write operation を block し、無効な ticket data が commit されることを防ぎます。(`plugins/core/hooks/validate-ticket.sh`、`plugins/core/hooks/hooks.json`)

### Skill File Integrity Check

CI workflow は plugin.json で参照されるすべての skill file が存在することを確認し、壊れた skill 参照を防ぎます。この確認はすべての push と pull request で実行されます。(`.github/workflows/validate-plugins.yml` lines 61-79)

## Recovery Plan

### Error Recovery Through Script Safety

すべての shell script は `set -eu`（未定義変数と error exit を伴う strict mode）を使用し、部分的な実行が system を一貫性のない状態に残すことを防ぎます。script が失敗した場合、誤った data で続行するのではなく、直ちに停止します。(19 の shell script が `plugins/core/skills/*/sh/*.sh` と `plugins/core/hooks/*.sh` に存在)

### Pre-Commit Validation Gates

validate-writer-output skill は README index file を更新する前に、期待される output file が存在し空でないことを確認します。これにより、壊れた documentation link が導入されることを防ぎます。Skill は file ごとの status と全体的な pass/fail を含む JSON を返します。(`plugins/core/skills/validate-writer-output/sh/validate.sh`)

### Manual Approval Gate

`/drive` command は各 ticket の実装を commit する前に、開発者の明示的な承認を必要とします。drive-approval skill は選択可能な option を持つ承認 dialog を提示します："Approve"、"Approve and stop"、"Other"（feedback 用）、"Abandon"。これにより、開発者は git history に入る前に変更を拒否でき、pre-commit recovery mechanism として機能します。(`plugins/core/commands/drive.md` lines 48-71、`plugins/core/skills/drive-approval/SKILL.md`)

### Detached HEAD Protection

Commit skill は commit を許可する前に repository が名前付き branch 上にあることを確認し、detached HEAD 状態での偶発的な commit を防ぎます。Pre-flight check は `git branch --show-current` を実行し、空の場合は error で exit します。(`plugins/core/skills/commit/sh/commit.sh` lines 42-46)

### Marketplace-Directory Consistency Check

CI workflow は marketplace.json にリストされているすべての plugin に対応する directory があることを検証し、configuration の drift を防ぎます。この確認は marketplace.json の plugin 名と実際の plugin directory を比較します。(`.github/workflows/validate-plugins.yml` lines 81-102)

## Observations

Git versioning は標準的な git command による復元機能を持つ完全な project history を提供します。Ticket archival は branch 固有の directory にすべての変更リクエスト履歴を保持します。Shell script safety（`set -eu`）は 19 以上の script で部分的な失敗を防ぎます。複数の検証 gate（CI、hook、approval）は壊れた状態が commit されることを防ぎます。Project の純粋な file architecture（database なし、service なし）は、recovery が repository を clone するだけで済むことを意味します。

## Gaps

観察されず：手動の git operation 以外の正式な backup 検証または復元テスト手順はありません。観察されず：一般的な失敗シナリオ（repository の破損、commit の喪失、GitHub の停止）に対する文書化された recovery 手順はありません。観察されず：Repository に表示される branch protection rule はありません（GitHub web interface で設定されている可能性があります）。観察されず：CI 検証を超えた自動化された整合性チェックはありません。観察されず：RTO（Recovery Time Objective）または RPO（Recovery Point Objective）target は定義されていません。Project architecture がそれらを必要としない可能性があります。
