---
created_at: 2026-01-31T14:29:46+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort: 0.25h
commit_hash: 2c5b214
category: Changed
---

# Use Git User Email for Ticket Author Field

## Overview

When creating tickets, Claude uses a hardcoded `noreply@anthropic.com` instead of the actual user's email from `git config user.email`. The `create-ticket` skill says "Run the shell commands to fill `created_at` and `author`" but this instruction is not explicit enough, causing Claude to skip running the command.

## Key Files

- `plugins/core/skills/create-ticket/SKILL.md` - Lines 15-16 specify using git config, lines 25 says to run shell commands

## Related History

Historical tickets show git config usage in automation contexts but no prior fixes for this specific ticket author issue.

## Implementation

1. **Update create-ticket skill** to make the instruction more explicit:
   - Change from template syntax `<run: git config user.email>` to explicit "MUST run" instruction
   - Add a step: "Before writing the file, run these commands and capture output"
   - Show exact expected format: `author: a@qmu.jp` (example from git config)

2. **Add explicit step** in the frontmatter section:
   ```markdown
   ## Step 1: Capture Dynamic Values (REQUIRED)

   Run these commands FIRST:
   ```bash
   date -Iseconds        # → created_at value
   git config user.email # → author value
   ```

   Use the actual output in the frontmatter. Do NOT use placeholders or hardcoded values.
   ```

## Acceptance Criteria

- Tickets are created with actual git user.email value
- No hardcoded `noreply@anthropic.com` in ticket author fields

## Final Report

Development completed as planned.

**Changes Made**:
- Added explicit "Step 1: Capture Dynamic Values" section requiring commands to be run first
- Updated frontmatter template to show example values instead of `<run: command>` syntax
- Added explicit warning against hardcoded values like `noreply@anthropic.com`
- Updated field documentation to emphasize "run and use actual output"
