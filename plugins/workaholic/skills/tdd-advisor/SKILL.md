---
name: tdd-advisor
description: Best practices for spec-driven development with /ticket and /drive commands.
---

# TDD Advisor

Reference skill for proposing `/ticket` and `/drive` commands to enable spec-driven development workflow.

## Overview

This skill provides templates for two commands that work together:

1. **`/ticket`** - Write implementation specs before coding
2. **`/drive`** - Implement specs one by one with approval gates

## Workflow

```
User: /ticket add dark mode

Claude: [explores codebase, writes spec to doc/specs/20260115-add-dark-mode.md]

User: /drive

Claude: [implements spec, asks for review, commits, archives]
```

## When to Propose

Propose these commands when:
- Project has no spec-driven workflow
- User wants structured implementation process
- Team needs approval gates before commits

## Reference Templates

See `references/` directory for command templates:
- `ticket-command-template.md` - Template for /ticket command
- `drive-command-template.md` - Template for /drive command
