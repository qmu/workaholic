---
title: Recovery Policy
description: Data backup schedules, retention policies, disaster recovery procedures, and RTO/RPO targets
category: developer
modified_at: 2026-03-10T00:00:00+00:00
commit_hash: f76bde2
---

[English](recovery.md) | [Japanese](recovery_ja.md)

# Recovery Policy

この文書は、Workaholic repository で観察された backup、recovery、data 復元の実践を記述します。database や永続的な service を持たない git で version 管理された project として、recovery は完全に git history と GitHub の infrastructure に依存します。Repository は現在 2 つの plugin を含みます -- ticket 駆動開発のための drivin と AI 指向の探索のための trippin -- それぞれが独自の recovery mechanism を提供します。

## Data Persistence

### Version Control as Primary Storage

すべての project data（markdown document、JSON configuration、shell script、git configuration を含む）は git で version 管理されています。すべての変更は atomic な commit として記録され、完全な audit trail と git checkout または git revert による任意の以前の状態への復元機能を提供します。Repository はすべての configuration を text file に含み、binary 依存関係はありません。(git version control system、`.git/config`)

### Remote Repository Backup

Repository は GitHub の git@github.com:qmu/workaholic.git で host されており、project history 全体の remote backup を提供します。Pull request と branch push は GitHub の infrastructure を通じて追加の冗長性を作成します。Remote repository が信頼できる backup として機能し、local clone は作業用 copy を提供します。(`.git/config` の remote.origin.url field、GitHub remote hosting)

### Ticket Archival System

完了した ticket は削除されるのではなく、`.workaholic/tickets/archive/<branch>/` に archive されます。これにより、最終 report と実装詳細を含むすべての変更リクエストの完全な履歴が保持されます。archive-ticket skill は、ticket を `todo/` から `archive/<branch>/` に移動し、変更を commit し、commit hash と category で ticket frontmatter を更新することで archival workflow を実装します。Archive workflow は atomic です：ticket を移動、すべての変更を stage、commit skill 経由で commit、frontmatter を更新、commit を amend します。(`plugins/drivin/skills/archive-ticket/sh/archive.sh`)

### Abandoned Ticket Preservation

実装できない ticket は、失敗分析とともに `.workaholic/tickets/abandoned/` に移動され、data 損失を防ぎ、意思決定の context を保持します。drive-approval skill は、失敗分析を生成し ticket を abandoned directory に移動する "Abandon" option を提供します。これにより、失敗した作業も将来の参照のために文書化されることが保証されます。(`plugins/drivin/skills/drive-approval/SKILL.md`、`.workaholic/tickets/abandoned/`)

### Branch-Based State Snapshots

Repository はすべての feature 作業に対して `<prefix>-YYYYMMdd-HHmmss` パターンに従う timestamp 付き topic branch を使用します。各 branch は進行中の作業の復元可能な snapshot を表します。複数の branch が同時に存在し、冗長性と branch 固有の問題からの復元能力を提供します。branching skill はこれらの timestamp 付き branch を自動的に作成します。(`plugins/drivin/skills/branching/sh/create.sh`)

### Trip Artifact Versioning

trippin plugin は version 管理された追記専用パターンを使用して、すべての共同設計 artifact を保持します。各 revision は以前の version を上書きするのではなく、新しい番号付き file（direction-v1.md、direction-v2.md など）を作成します。Artifact は `.workaholic/.trips/<trip-name>/` に directions、models、designs の subdirectory とともに保存されます。これにより、完全な共同 review 履歴が commit された version の sequence として保持され、任意の中間設計状態の recovery が可能になります。(`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`、`plugins/trippin/skills/trip-protocol/SKILL.md`)

### Worktree-Based Session Isolation

trippin plugin は各探索 session を `.worktrees/<trip-name>/` の専用 git worktree で分離し、`trip/<trip-name>` という名前の branch を使用します。これにより、trip の作業が main working tree に干渉することを防ぎ、クリーンな recovery 境界を提供します：trip session が失敗した場合、primary checkout に影響を与えることなく worktree を削除できます。ensure-worktree script は作成前に worktree も branch も存在しないことを検証し、偶発的な上書きを防ぎます。(`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`)

## Backup Strategy

### Git History as Continuous Backup

Git の commit history は、連続的な atomic な backup mechanism として機能します。各 commit は完全な content と metadata を持つ復元可能な checkpoint を表します。Repository は初期開発から現在の作業までのすべての commit を含み、完全な復元 path を示しています。すべての commit は strict mode の shell script と Description、Changes、Test Planning、Release Preparation section を持つ multi-section commit message を使用します。(`plugins/drivin/skills/commit/sh/commit.sh`)

### Commit-per-Step Traceability in Trips

trippin plugin は、すべての離散的な workflow step が trip branch で git commit を生成する commit-per-step rule を強制します。これにより、各 direction の draft、review、revision、consensus 確認を含む共同 process 全体をトレースする fine-grained な commit history が作成されます。trip-commit script は `trip(<agent>): <step>` 形式の構造化された commit message を生成し、body に phase を記録することで、各 agent の貢献の復元可能な record を提供します。(`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)

### Multi-Contributor Commit Attribution

Commit skill は自動的にすべての commit に Co-Authored-By trailer を追加し、Claude が実装を支援する場合でも適切な attribution を保証します。これにより、recovery context と audit trail のための contribution history が保持されます。すべての commit message の body に "Co-Authored-By: Claude <noreply@anthropic.com>" が含まれます。(`plugins/drivin/skills/commit/sh/commit.sh` lines 95-97)

### CI Validation Before Merge

GitHub Actions workflow は main branch への merge 前にすべての変更を検証し、無効な状態が primary branch に入ることを防ぎます。validate-plugins workflow は push と pull request event で実行され、JSON の妥当性、必須 field、file の存在、plugin-directory の一貫性を確認します。Workflow は glob pattern (`plugins/*/.claude-plugin/plugin.json`) を使用して drivin と trippin の両方の plugin を自動的にカバーし、marketplace の拡張に応じて検証がスケールすることを保証します。検証失敗は merge を block し、main branch が既知の良好な状態を保つことを保証します。(`.github/workflows/validate-plugins.yml`)

### Automated Release Artifacts

Release workflow は version tag と release note を持つ GitHub release を作成し、各 version increment で名前付き recovery point を提供します。Release は marketplace version が変更されたときに main branch への push で trigger されます。Workflow は `.workaholic/release-notes/` directory から release note を抽出するか、git log にフォールバックし、version tag を持つ GitHub release を作成し、latest としてマークします。(`.github/workflows/release.yml`)

### Release Note Generation

生成された release note は GitHub release を作成する前に `.workaholic/release-notes/` directory に保存されます。write-release-note skill は story file から簡潔な release note を生成し、これが release workflow で使用されます。これにより、release documentation が code と一緒に version 管理され復元可能であることが保証されます。(`plugins/drivin/skills/write-release-note/SKILL.md`、`.github/workflows/release.yml` lines 62-86)

## Migration Procedures

### Configuration File Validation

marketplace.json と plugin.json を含む JSON configuration file は CI workflow を通じてすべての push で検証されます。検証は JSON syntax、name と version などの必須 field、file 参照を確認します。無効な configuration は merge を防ぎ、repository が有効な状態を保つことを保証します。Workflow は JSON parsing と検証に jq を使用します。検証は glob ベースの file discovery を通じて複数の plugin（drivin と trippin）をカバーするようになりました。(`.github/workflows/validate-plugins.yml` lines 22-59)

### Frontmatter Schema Enforcement

Ticket file は ISO 8601 format の created_at、email address としての author、enhancement/bugfix/refactoring/housekeeping のいずれかの type、UX/Domain/Infrastructure/DB/Config 値を持つ YAML array としての layer、0.1h/0.25h/0.5h/1h/2h/4h のいずれかまたは空の effort を含む特定の schema を持つ YAML frontmatter を必要とします。post-write hook は Write または Edit operation の後に ticket frontmatter format を検証します。検証失敗は exit code 2 で write operation を block し、無効な ticket data が commit されることを防ぎます。検証は anthropic.com の email も拒否し、実際のユーザーの git email を要求します。(`plugins/drivin/hooks/validate-ticket.sh`、`plugins/drivin/hooks/hooks.json`)

### Skill File Integrity Check

CI workflow は plugin.json で参照されるすべての skill file が存在することを確認し、壊れた skill 参照を防ぎます。この確認はすべての push と pull request で実行され、plugin.json から skill path を抽出し file の存在を確認します。欠落している skill file は CI 失敗を引き起こします。(`.github/workflows/validate-plugins.yml` lines 61-79)

### Marketplace-Directory Consistency Check

CI workflow は marketplace.json にリストされているすべての plugin に plugins/ 内の対応する directory があることを検証し、configuration の drift を防ぎます。この確認は jq と ls を使用して marketplace.json の plugin 名と実際の plugin directory を比較します。欠落している directory は CI 失敗を引き起こします。(`.github/workflows/validate-plugins.yml` lines 81-102)

### Version Synchronization Across Plugins

Version 番号は 3 つの file 間で同期を保つ必要があります：`.claude-plugin/marketplace.json` の root version、`plugins/drivin/.claude-plugin/plugin.json`、`plugins/trippin/.claude-plugin/plugin.json`。Version bump はすべての file を同時に更新して一貫性を維持します。CI workflow は個々の plugin.json file を検証しますが、file 間の version 一貫性は CLAUDE.md に文書化された release workflow の規約によって強制されます。(`.claude-plugin/marketplace.json`、`plugins/drivin/.claude-plugin/plugin.json`、`plugins/trippin/.claude-plugin/plugin.json`、`CLAUDE.md` version management section)

## Recovery Plan

### Error Recovery Through Script Safety

すべての shell script は未定義変数検出と error exit を伴う strict mode を使用し、部分的な実行が system を一貫性のない状態に残すことを防ぎます。Script が失敗した場合、誤った data で続行するのではなく、直ちに停止します。drivin plugin はその 21 の shell script で `set -eu`（POSIX sh）を使用し、trippin plugin はその 3 の shell script で `set -euo pipefail`（bash）を使用して、両方の plugin で一貫した安全性を保証します。(`plugins/drivin/skills/*/sh/*.sh`、`plugins/drivin/hooks/*.sh`、`plugins/trippin/skills/*/sh/*.sh`)

### Pre-Commit Validation Gates

validate-writer-output skill は README index file を更新する前に、期待される output file が存在し空でないことを確認します。これにより、壊れた documentation link が導入されることを防ぎます。Skill は file ごとの status と全体的な pass/fail を含む JSON を返し、caller が commit 前に中止できるようにします。(`plugins/drivin/skills/validate-writer-output/sh/validate.sh`)

### Manual Approval Gate

drive command は各 ticket の実装を commit する前に、開発者の明示的な承認を必要とします。drive-approval skill は Approve、Approve and stop、Abandon を含む選択可能な option を持つ承認 dialog を提示します。承認 prompt は ticket の title と overview を含む必要があり、値が欠落または placeholder のままの prompt を提示することは失敗条件として強制されます。これにより、開発者が常に十分な context を持って承認判断を行えることが保証され、pre-commit recovery mechanism として機能します。(`plugins/drivin/commands/drive.md`、`plugins/drivin/skills/drive-approval/SKILL.md`)

### Detached HEAD Protection

Commit skill は commit を許可する前に repository が名前付き branch 上にあることを確認し、detached HEAD 状態での偶発的な commit を防ぎます。Pre-flight check は git branch --show-current を実行し、空の場合は error で exit します。これにより、復元が困難な孤立した commit が防止されます。(`plugins/drivin/skills/commit/sh/commit.sh` lines 43-48)

### Staged Change Verification

Commit skill は commit を作成する前に何かが stage されているかを確認し、空の commit を防ぎ、予期しない working tree state を開発者に警告します。変更が stage されていない場合、警告を出力し成功で exit し、開発者が git status で調査できるようにします。(`plugins/drivin/skills/commit/sh/commit.sh` lines 70-77)

### Atomic Archive Workflow

archive-ticket skill は ticket を移動し、すべての変更を stage し、--skip-staging flag を使用して commit skill 経由で commit し、commit hash と category で frontmatter を更新し、commit を amend する atomic workflow を実装します。これにより、ticket archival が all-or-nothing で部分的な状態がないことが保証されます。(`plugins/drivin/skills/archive-ticket/sh/archive.sh`)

### Worktree Pre-Creation Validation

trippin plugin は worktree を作成する前に前提条件を検証します：現在の directory が git repository 内にあることを確認し、worktree がまだ存在しないことを確認し、対象 branch がまだ存在しないことを確認します。これらのガードにより、偶発的な上書きが防止され、各 trip がクリーンな状態から開始されることが保証されます。(`plugins/trippin/skills/trip-protocol/sh/ensure-worktree.sh`)

### Trip Name Validation

Trip 初期化 script は trip 名が厳格な小文字英数字とハイフンのパターン（先頭・末尾のハイフンは不可）に従うことを検証し、trip directory が既に存在する名前を拒否します。これにより、filesystem の競合が防止され、一貫した復元可能な directory 構造が保証されます。(`plugins/trippin/skills/trip-protocol/sh/init-trip.sh`)

### No-Change Commit Guard in Trips

trip-commit script は commit を試みる前に未 commit の変更（staged、unstaged、untracked）を確認します。変更が検出されない場合、失敗するのではなく commit が行われなかったことを示す JSON response を返し、不要な commit を防ぎ、呼び出し元の agent に明確な feedback を提供します。(`plugins/trippin/skills/trip-protocol/sh/trip-commit.sh`)

## Observations

Git versioning は標準的な git command による復元機能を持つ完全な project history を提供します。Ticket archival は branch 固有の directory にすべての変更リクエスト履歴を保持します。strict mode を使用した shell script safety は両方の plugin の 24 の script で部分的な失敗を防ぎます。CI、hook、manual approval を含む複数の検証 gate は壊れた状態が commit されることを防ぎます。database や service を持たない project の純粋な file architecture は、recovery が repository を clone するだけで済むことを意味します。Timestamp 付き topic branch は進行中の作業の復元可能な snapshot を提供します。Description、Changes、Test Planning、Release Preparation section を持つ multi-section commit message は詳細な recovery context を提供します。trippin plugin は追加の recovery mechanism として worktree 分離と commit-per-step traceability を追加し、探索 session が main working tree から独立して復元可能であることを保証します。trip の version 管理された追記専用 artifact パターンは、すべての設計反復における完全な共同 review 履歴を保持します。

## Gaps

観察されず：手動の git operation 以外の正式な backup 検証または復元テスト手順はありません。観察されず：repository の破損、commit の喪失、GitHub の停止などの一般的な失敗シナリオに対する文書化された recovery 手順はありません。観察されず：repository に表示される branch protection rule はありません（GitHub web interface で設定されている可能性があります）。観察されず：CI 検証を超えた自動化された整合性チェックはありません。観察されず：RTO Recovery Time Objective または RPO Recovery Point Objective target は定義されていません。Project architecture がそれらを必要としない可能性があります。観察されず：issue、pull request comment、project board などの GitHub 固有の metadata の backup はありません。観察されず：災害復旧 runbook や incident 対応手順はありません。観察されず：完了または中止された trip session の worktree cleanup 自動化はありません。
