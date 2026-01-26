---
created_at: 2026-01-27T01:23:27+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Strengthen git guidelines in subagents to prevent -C flag usage

## Overview

Despite adding "Git Command Guidelines" to subagents (story-writer, spec-writer, terms-writer), the story-writer still uses `git -C` flag when running commands like `git rev-list --count main..HEAD`. The current guideline text is too weak - it needs to be more emphatic and positioned prominently.

The issue is that Claude Code's default behavior may add `-C` flags to git commands. The subagent instructions need to explicitly override this behavior with stronger language.

## Key Files

- `plugins/core/agents/story-writer.md` - Runs git rev-list, git log commands
- `plugins/core/agents/spec-writer.md` - Runs git branch, git diff, git rev-parse commands
- `plugins/core/agents/terms-writer.md` - Runs git branch, git diff, git rev-parse commands

## Implementation Steps

1. Update the "Git Command Guidelines" section in all three agent files to use stronger, more emphatic language:

   **Current text:**
   ```markdown
   ## Git Command Guidelines

   Run git commands from the working directory. Never use `git -C` flag.
   ```

   **New text:**
   ```markdown
   ## CRITICAL: Git Command Format

   **NEVER use `git -C <path>` flag.** Always run git commands directly without path arguments:

   - WRONG: `git -C /path/to/repo rev-list --count main..HEAD`
   - RIGHT: `git rev-list --count main..HEAD`

   All git commands must run from the current working directory. The `-C` flag causes permission prompts and must not be used.
   ```

2. The section should remain after the "Input" section (for story-writer) or at the start of Instructions (for spec-writer, terms-writer) - the position is fine, but the content needs to be stronger.

## Considerations

- The changelog-writer, pr-creator, and performance-analyst agents don't run git commands directly, so they don't need this section
- The stronger wording with "CRITICAL" and explicit WRONG/RIGHT examples should help Claude understand this is a hard requirement, not a soft suggestion
- Including the explanation "causes permission prompts" gives context for why this matters
