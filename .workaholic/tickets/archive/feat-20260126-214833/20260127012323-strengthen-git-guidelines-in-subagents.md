---
created_at: 2026-01-27T01:23:27+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.1h
commit_hash: b94045a
category: Added
---

# Consolidate git guidelines into a rule for all subagents

## Overview

Despite adding "Git Command Guidelines" to subagents (story-writer, spec-writer, terms-writer), the story-writer still uses `git -C` flag when running commands like `git rev-list --count main..HEAD`. The current approach of duplicating guidelines in each agent file is:

1. Not DRY - same text repeated in 3 files
2. Too weak - needs stronger, more emphatic language
3. Easy to miss when adding new agents

A better approach is to create a dedicated rule file that applies to all subagents.

## Key Files

- `plugins/core/rules/subagents.md` - NEW: Rule file for all subagent behavior
- `plugins/core/agents/story-writer.md` - Remove duplicated Git Command Guidelines section
- `plugins/core/agents/spec-writer.md` - Remove duplicated Git Command Guidelines section
- `plugins/core/agents/terms-writer.md` - Remove duplicated Git Command Guidelines section

## Implementation Steps

1. Create `plugins/core/rules/subagents.md` with strong git guidelines:

   ```markdown
   ---
   paths:
     - 'plugins/core/agents/**/*'
   ---

   # Subagent Rules

   ## CRITICAL: Git Command Format

   **NEVER use `git -C <path>` flag.** Always run git commands directly without path arguments:

   - WRONG: `git -C /path/to/repo rev-list --count main..HEAD`
   - RIGHT: `git rev-list --count main..HEAD`

   All git commands must run from the current working directory. The `-C` flag causes permission prompts and must not be used.
   ```

2. Remove the "Git Command Guidelines" section from `story-writer.md` (lines 18-20)

3. Remove the "Git Command Guidelines" section from `spec-writer.md` (lines 11-13)

4. Remove the "Git Command Guidelines" section from `terms-writer.md` (lines 11-13)

## Considerations

- The `paths` pattern `plugins/core/agents/**/*` ensures the rule applies when any agent file is active
- New agents automatically get the git guidelines without needing to add them manually
- The stronger wording with "CRITICAL" and explicit WRONG/RIGHT examples makes this a hard requirement
- All subagents benefit from this rule, even ones that don't currently run git commands

## Final Report

Development completed as planned.
