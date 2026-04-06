# Core

Shared commands and skills for cross-workflow operations. Provides context-aware commands and shared utilities used by other plugins.

## Commands

| Command | Description |
| ------- | ----------- |
| `/report` | Context-aware report generation and PR creation |
| `/ship` | Context-aware: merge PR, deploy, and verify |
| `/scan` | Full documentation scan (all agents) |

## Skills

| Skill | Description |
| ----- | ----------- |
| branching | Context detection and branch pattern matching for unified commands |
| ship | Ship workflow: PR merge, cloud.md deploy, and production verify |

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["core"]
}
```
