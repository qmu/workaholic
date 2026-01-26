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
