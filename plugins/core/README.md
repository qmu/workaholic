# Core

Shared commands and skills for cross-workflow operations. Provides context-aware commands that auto-detect whether you are in a Drivin (ticket-driven) or Trippin (agent teams) workflow and route accordingly.

## Commands

| Command | Description |
| ------- | ----------- |
| `/report` | Context-aware report generation and PR creation |
| `/ship` | Context-aware: merge PR, deploy, verify (with worktree cleanup for trips) |

## Skills

| Skill | Description |
| ----- | ----------- |
| branching | Context detection and branch pattern matching for unified commands |

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["core"]
}
```
