---
created_at: 2026-01-29T01:26:14+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: b5f6e41
category: Changed
---

# Auto-create Branch When Running /ticket on Main

## Overview

Remove the standalone `/branch` command and integrate branch creation into `/ticket`. When `/ticket` is invoked while on `main` (or another non-topic branch), automatically create a topic branch before writing the ticket. This reduces the workflow from two commands (`/branch` then `/ticket`) to one (`/ticket`).

## Key Files

- `plugins/core/commands/branch.md` - Remove this command
- `plugins/core/commands/ticket.md` - Add branch check and auto-creation logic
- `plugins/core/skills/create-branch/SKILL.md` - Keep skill (used by ticket command now)
- `README.md` - Update Quick Start table (remove /branch)
- `CLAUDE.md` - Update Commands table (remove /branch)
- `plugins/core/README.md` - Update Commands table (remove /branch)
- `.workaholic/guides/commands.md` - Remove /branch section
- `.workaholic/guides/commands_ja.md` - Remove /branch section

## Related History

The `/branch` command was recently refactored to use the create-branch skill, making the skill reusable.

Past tickets that touched similar areas:

- [20260128002536-extract-create-branch-skill.md](.workaholic/tickets/archive/feat-20260128-001720/20260128002536-extract-create-branch-skill.md) - Extracted create-branch skill (enables this change)
- [20260127210804-update-readme-for-users.md](.workaholic/tickets/archive/feat-20260126-214833/20260127210804-update-readme-for-users.md) - Updated README with /branch in Quick Start

## Implementation Steps

1. Update `plugins/core/commands/ticket.md`:
   - Add create-branch to skills list in frontmatter
   - Add new step 0 "Check Branch" before "Understand the Request":
     ```markdown
     0. **Check Branch**

        Check current branch: `git branch --show-current`

        If on `main` or `master` (not a topic branch):
        1. Ask user for branch prefix (feat/fix/refact) via AskUserQuestion
        2. Run: `bash .claude/skills/create-branch/sh/create.sh <prefix>`
        3. Confirm: "Created branch: <branch-name>"
        4. Continue to step 1

        Topic branch pattern: `feat-*`, `fix-*`, `refact-*`
     ```

2. Remove `plugins/core/commands/branch.md`

3. Update `README.md`:
   - Remove `/branch` row from Quick Start table
   - Update Typical Session example to start with `/ticket` directly

4. Update `CLAUDE.md`:
   - Remove `/branch` row from Commands table

5. Update `plugins/core/README.md`:
   - Remove `/branch` row from Commands table

6. Update `.workaholic/guides/commands.md`:
   - Remove the `### /branch` section entirely
   - Update workflow summary to show `/ticket` as the starting point

7. Update `.workaholic/guides/commands_ja.md`:
   - Remove the `### /branch` section entirely
   - Update workflow summary

8. Keep `plugins/core/skills/create-branch/` unchanged (still needed)

## Considerations

- Breaking change: users who relied on `/branch` standalone need to use `/ticket` instead
- The create-branch skill remains available for any future use
- Detection logic: any branch not matching `feat-*`, `fix-*`, or `refact-*` triggers branch creation
- This simplifies the typical workflow from 4 commands to 3: `/ticket` → `/drive` → `/story`

## Final Report

Development completed as planned.
