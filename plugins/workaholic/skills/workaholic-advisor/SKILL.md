---
name: workaholic-advisor
description: Best practices for Claude Code configuration (.claude/, CLAUDE.md, commands, rules).
---

# Workaholic Advisor

Reference skill providing best practices for configuring Claude Code projects.

## Topics

| Topic | Description | Template |
|-------|-------------|----------|
| [commit](topics/commit.md) | /commit command best practices | `templates/commit-command.md` |
| [pull-request](topics/pull-request.md) | /pull-request command best practices | `templates/pull-request-command.md` |
| [tdd](topics/tdd.md) | /ticket and /drive workflow | `templates/ticket-command.md`, `templates/drive-command.md` |
| [rules](topics/rules.md) | TypeScript coding conventions | `templates/typescript-conventions.md` |
| [claude-md](topics/claude-md.md) | CLAUDE.md structure | `templates/claude-md.md` |

## How to Use

1. Read the relevant **topic** file for guidance and customization options
2. Read the **template** file for the actual content to create
3. Customize based on project analysis
4. Create the file in the user's project

## Common Workflow

```
1. Check if configuration already exists
2. Analyze project conventions (git log, package.json, etc.)
3. Read topic guide for customization questions
4. Read template for content structure
5. Propose customized version to user
6. Create/update the configuration file
```
