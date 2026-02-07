---
title: Data Viewpoint
description: Data formats, frontmatter schemas, and naming conventions
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](data.md) | [Japanese](data_ja.md)

# 1. Data Viewpoint

Data Viewpoint は、Workaholic システム全体で使用されるデータ形式、frontmatter スキーマ、ファイル命名規則、構造パターンを文書化します。すべての永続データは YAML frontmatter 付き markdown ファイルまたは JSON 設定ファイルとして保存され、git でバージョン管理されます。

## 2. Frontmatter Schemas

### 2-1. Ticket Frontmatter

```yaml
---
created_at: 2026-02-07T10:56:08+09:00    # ISO 8601 datetime
author: user@example.com                   # Git ユーザーメール
type: feature | fix | refactor | chore     # 変更タイプ
layer: command | agent | skill | rule | config | docs
effort: S | M | L                          # 見積もり工数
category: Added | Changed | Removed        # Changelog カテゴリ
commit_hash: abc1234                        # 実装後の短縮ハッシュ
---
```

### 2-2. Spec/Policy Frontmatter

```yaml
---
title: Document Title
description: Brief description
category: user | developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: abc1234
---
```

### 2-3. Terms Frontmatter

```yaml
---
title: Document Title
description: Brief description
category: developer
last_updated: 2026-02-07                  # 日付のみ（datetime ではない）
commit_hash: abc1234
---
```

Terms ファイルは `modified_at`（datetime 形式）ではなく `last_updated`（date 形式）を使用します。これは `.workaholic/terms/inconsistencies.md` に文書化された既知の不整合です。

## 3. File Naming Conventions

| コンテキスト | 規約 | 例 |
| --- | --- | --- |
| Tickets | `<timestamp>-<slug>.md` | `20260207035026-flatten-scan-writer-nesting.md` |
| Specs（viewpoint） | `<slug>.md` | `stakeholder.md`、`component.md` |
| Policies | `<slug>.md` | `test.md`、`security.md` |
| Terms | `<kebab-case>.md` | `core-concepts.md`、`workflow-terms.md` |
| Stories | `<branch-name>.md` | `drive-20260205-195920.md` |
| 翻訳 | `<name>_ja.md` | `stakeholder_ja.md`、`README_ja.md` |
| Commands | `<name>.md` | `drive.md`、`ticket.md` |
| Agents | `<kebab-case>.md` | `drive-navigator.md` |
| Skills | `SKILL.md` in `<kebab-case>/` | `write-spec/SKILL.md` |
| Shell scripts | `<name>.sh` in `sh/` | `gather.sh`、`validate.sh` |

## 4. Data Lifecycle

```mermaid
flowchart LR
    Create[todo/ で作成] --> Implement[/drive で実装]
    Implement --> Approve{承認?}
    Approve -->|はい| Archive[archive/branch/ にアーカイブ]
    Approve -->|Abandon| Abandoned[abandoned/ に移動]
    Approve -->|Feedback| Implement
    Create --> Icebox[icebox/ に延期]
    Icebox --> Implement
```

## 5. Assumptions

- [Explicit] ticket frontmatter フィールドと検証は `create-ticket` skill に文書化され、hook によって強制されます。
- [Explicit] datetime フィールドの `_at` サフィックス規約と翻訳の `_ja` サフィックスは `CLAUDE.md` と `translate` skill に文書化されています。
- [Explicit] ブランチ命名は `drive-` または `trip-` プレフィックスを使用します。
- [Inferred] spec の `modified_at`（datetime）と terms の `last_updated`（date）の不整合は、注目されているが解決されていない歴史的な成果物です。
- [Inferred] タイムスタンプ接頭辞の ticket 命名規約は、アルファベット順にリストしたときの時系列順序を保証し、drive-navigator の優先順位付けに重要です。
