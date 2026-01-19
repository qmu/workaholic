---
name: workaholic-advisor
description: Best practices for Claude Code configuration (.claude/, CLAUDE.md, commands, skills, rules).
---

# Workaholic Advisor

Reference skill providing best practices for configuring Claude Code projects.

## Topics

| Topic | Type | Target Path | Condition | Template(s) |
| ----- | ---- | ----------- | --------- | ----------- |
| [commit](topics/commit.md) | command | `.claude/commands/commit.md` | Always | `templates/commit-command.md` |
| [pull-request](topics/pull-request.md) | command | `.claude/commands/pull-request.md` | Always | `templates/pull-request-command.md` |
| [tdd](topics/tdd.md) | command | `.claude/commands/ticket.md`, `.claude/commands/drive.md` | Always | `templates/ticket-command.md`, `templates/drive-command.md` |
| [archive-ticket](topics/archive-ticket.md) | skill | `.claude/skills/archive-ticket/` | If /drive exists | `templates/archive-ticket-skill.md`, `templates/archive-ticket-script.sh` |
| [general](topics/general.md) | rule | `.claude/rules/general.md` | Always | `templates/general-rules.md` |
| [rules](topics/rules.md) | rule | `.claude/rules/typescript.md` | If TypeScript project | `templates/typescript-conventions.md` |
| [claude-md](topics/claude-md.md) | file | `CLAUDE.md` | Always (add missing sections) | `templates/claude-md.md` |

## How to Use

1. Read the **topic** file to understand:
   - What it provides
   - When to propose it (condition)
   - Customization options
2. Check if the **target path** exists in the user's project
3. If MISSING and condition is met, read the **template** and create it

## Legacy Detection

| Legacy Path | Current Path | Action |
| ----------- | ------------ | ------ |
| `.claude/commands/spec.md` | `.claude/commands/ticket.md` | Rename |
| `.claude/commands/impl-spec.md` | `.claude/commands/drive.md` | Rename |

## Skill Structure

Skills require a directory with SKILL.md and optional scripts:

```
.claude/skills/<name>/
├── SKILL.md
└── scripts/
    └── <script>.sh
```
