# Trippin

AI-oriented exploration and creative development workflow for Claude Code projects.

## Commands

| Command | Description |
| ------- | ----------- |
| `/trip <instruction>` | Launch Agent Teams session with Planner, Architect, and Constructor |
| `/report-trip` | Generate trip journey report and create/update PR |
| `/ship-trip` | Merge PR, clean up worktree, deploy, and verify |

## Skills

| Skill | Description |
| ----- | ----------- |
| trip-protocol | Two-phase collaborative workflow protocol and artifact conventions |
| write-trip-report | Generate trip journey report from agent artifacts |

## Rules

*No rules yet.*

## Installation

Add to your Claude Code configuration:

```json
{
  "plugins": ["trippin"]
}
```
