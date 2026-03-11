# Trippin

AI-oriented exploration and creative development workflow for Claude Code projects.

## Commands

| Command | Description |
| ------- | ----------- |
| `/trip <instruction>` | Launch Agent Teams session with Planner, Architect, and Constructor |
| `/report` | Context-aware report generation and PR creation |
| `/ship-trip` | Merge PR, clean up worktree, deploy, and verify |

## Skills

| Skill | Description |
| ----- | ----------- |
| trip-protocol | Two-phase collaborative workflow protocol and artifact conventions |
| ship | Ship workflow - merge PR, deploy via cloud.md, and verify production |
| write-trip-report | Generate trip journey report from agent artifacts |
| branching | Context detection and branch pattern matching for unified commands |

## Rules

*No rules yet.*

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["trippin"]
}
```
