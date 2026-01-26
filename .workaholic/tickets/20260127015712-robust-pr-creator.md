---
created_at: 2026-01-27T01:57:12+09:00
author: a@qmu.jp
type: bugfix
layer: [Config]
effort:
commit_hash:
category:
---

# Make pr-creator always succeed on first attempt

## Overview

The pr-creator subagent frequently fails when creating or updating PRs due to shell escaping issues with HEREDOC and the multi-step process. Simplify to a robust single-shot approach that always works.

## Key Files

- `plugins/core/agents/pr-creator.md` - Main file to simplify

## Implementation Steps

1. Change instruction to always use `--body-file` approach (never HEREDOC for body)
2. Use a simple file-based workflow:
   - Write story content (without frontmatter) to temp file first
   - Use `--body-file` for both create and edit
3. Simplify title derivation - just extract first list item from Summary section
4. Combine PR existence check and operation into fewer steps
5. Remove redundant/complex sed command examples

## Considerations

- The `--body-file` approach is immune to shell escaping issues
- Temp file should be cleaned up after use (or use predictable path like `/tmp/pr-body.md`)
- Keep the agent instructions minimal and clear to reduce LLM interpretation errors
