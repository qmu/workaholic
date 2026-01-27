---
created_at: 2026-01-27T19:37:10+09:00
author: a@qmu.jp
type: refactoring
layer: [Config]
effort:
commit_hash: 7ff6ae9
category: Changed
---

# Bundle Shell Scripts for Permission-Free Skills

## Overview

Revert the incorrect approach of adding allow rules to `.claude/settings.json` and instead bundle shell scripts as part of skills. The settings file is user-local and not part of the plugin distribution, so plugin users would still experience permission prompts. The correct solution is to use bundled shell scripts (like `spec-context` does) which are part of the plugin.

## Key Files

- `.claude/settings.json` - Revert allow rules added by dfa2685
- `.workaholic/tickets/archive/feat-20260126-214833/20260127184127-add-auto-approve-permissions.md` - Delete incorrect ticket
- `plugins/core/agents/story-writer.md` - Replace `ls` bash command with Glob tool
- `plugins/core/agents/terms-writer.md` - Use new terms-context skill instead of inline bash
- `plugins/core/skills/terms-context/SKILL.md` - Create new skill definition
- `plugins/core/skills/terms-context/sh/gather.sh` - Create bundled shell script

## Implementation Steps

1. **Revert `.claude/settings.json`**
   - Remove the 18 allow rules added by commit dfa2685
   - Keep only the deny rule for `Bash(git -C:*)`

2. **Delete archived ticket**
   - Remove `.workaholic/tickets/archive/feat-20260126-214833/20260127184127-add-auto-approve-permissions.md`

3. **Fix `plugins/core/agents/story-writer.md`**
   - Lines 24-28: Replace `ls -1 .workaholic/tickets/archive/<branch-name>/*.md` with Glob tool instruction
   - Agent already has Glob in its allowed tools

4. **Create `plugins/core/skills/terms-context/SKILL.md`**
   - Follow the pattern from `plugins/core/skills/spec-context/SKILL.md`
   - Declare `allowed-tools: Bash` and `user-invocable: false`
   - Document the gather.sh script usage

5. **Create `plugins/core/skills/terms-context/sh/gather.sh`**
   - Based on `plugins/core/skills/spec-context/sh/gather.sh`
   - Output sections: BRANCH, TICKETS, TERMS (not SPECS), DIFF, COMMIT
   - Use `find .workaholic/terms` instead of `find .workaholic/specs`

6. **Update `plugins/core/agents/terms-writer.md`**
   - Add `terms-context` to skills list in frontmatter
   - Section 1 (lines 15-38): Replace inline bash with `bash .claude/skills/terms-context/sh/gather.sh`
   - Section 2 (lines 40-52): Remove `find` command, reference TERMS output from script
   - Lines 115-119: Remove `git rev-parse`, use COMMIT output from script
   - Line 157: Update to reference context output

## Considerations

- The `story-writer.md` fix is simple - just use Glob instead of ls (already in allowed tools)
- The `terms-writer.md` fix requires a new skill with bundled script
- Follow the existing `spec-context` pattern exactly for consistency
- After this change, `/report` should work without permission prompts for fresh plugin installs
