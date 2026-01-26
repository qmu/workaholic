---
created_at: 2026-01-27T01:42:58+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash:
category:
---

# Rename /pull-request to /report

## Overview

Rename the `/pull-request` command to `/report`. The new name better reflects that this command generates comprehensive documentation (changelog, story, specs, terms) in addition to creating a GitHub PR. "Report" emphasizes the documentation/narrative aspect of the workflow.

## Key Files

- `plugins/core/commands/pull-request.md` - Rename to `report.md` and update internal references
- `plugins/core/agents/pr-creator.md` - Keep as-is (internal implementation detail)
- `plugins/core/README.md` - Update command table from `/pull-request` to `/report`
- `plugins/core/rules/general.md` - Update reference from `/pull-request` to `/report`
- `plugins/core/skills/archive-ticket/SKILL.md` - Update reference in description rules
- `CLAUDE.md` - Update Commands table and project structure

## Implementation Steps

1. Rename `plugins/core/commands/pull-request.md` to `plugins/core/commands/report.md`
2. Update `plugins/core/commands/report.md`:
   - Change frontmatter `name: pull-request` to `name: report`
   - Update H1 heading from "# Pull Request" to "# Report"
   - Update description to emphasize documentation generation aspect
3. Update `plugins/core/README.md`:
   - Change `/pull-request` to `/report` in Commands table
4. Update `plugins/core/rules/general.md`:
   - Change `/pull-request` to `/report` in the commit rule
5. Update `plugins/core/skills/archive-ticket/SKILL.md`:
   - Change `/pull-request` reference to `/report` in Description Rules section
6. Update `CLAUDE.md`:
   - Change `/pull-request` to `/report` in Commands table
   - Update project structure comment (remove `pull-request` from commands list)

## Considerations

- The `pr-creator` agent name can remain unchanged - it's an internal implementation detail and accurately describes what that specific agent does (create/update GitHub PRs)
- Users familiar with `/pull-request` will need to learn the new `/report` command name
- The new name better represents the full scope of what the command does: generate documentation artifacts AND create a PR
