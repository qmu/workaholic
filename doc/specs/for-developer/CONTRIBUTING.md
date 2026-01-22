---
title: Contributing
description: How to add or modify plugins in Workaholic
category: developer
last_updated: 2026-01-23
---

# Contributing

This guide covers how to contribute to Workaholic, whether adding new commands, fixing bugs, or creating new plugins.

## Development Setup

Clone the repository and use the plugin commands to manage development:

```bash
git clone https://github.com/qmu/workaholic
cd workaholic
claude
```

## Important: Edit plugins/, Not .claude/

This repository develops plugins. All changes go to the `plugins/` directory, never to `.claude/` unless explicitly requested. The `.claude/` directory in user installations is managed by Claude Code.

## Workflow

Use the workaholic workflow to develop workaholic itself:

```mermaid
flowchart LR
    A[/ticket] --> B[/drive] --> C[/pull-request]
```

1. **Create a ticket**: `/ticket add new validation rule`
2. **Implement**: `/drive` - follows the ticket, commits when approved
3. **Create PR**: `/pull-request` - generates summary from CHANGELOG

## Adding a Command

Commands live in `plugins/<plugin>/commands/`. Create a markdown file:

```markdown
---
name: mycommand
description: Brief description of what it does
---

# My Command

Instructions for Claude to follow when this command is invoked.

## Instructions

1. First step
2. Second step
```

The `name` in frontmatter becomes the slash command (`/mycommand`).

## Adding an Agent

Agents live in `plugins/<plugin>/agents/`. They require additional frontmatter:

```markdown
---
name: my-agent
description: What this agent specializes in
tools: Read, Glob, Grep
model: haiku
---

# My Agent

Instructions for the agent.
```

The `tools` field limits what the agent can use. The `model` field specifies which Claude model to run.

## Adding a Rule

Rules live in `plugins/<plugin>/rules/`. They're always active:

```markdown
---
name: myrule
description: Coding standard this rule enforces
---

# My Rule

Guidelines Claude follows throughout the conversation.
```

## Adding a Skill

Skills are more complex and may include scripts. Create a directory:

```
plugins/<plugin>/skills/my-skill/
  SKILL.md           # Skill documentation
  scripts/
    run.sh           # Executable scripts
```

## Documentation Standards

Follow the standards in `plugins/core/rules/documentation.md`:

- YAML frontmatter on every markdown file
- Use Mermaid for diagrams
- Write prose paragraphs, not bullet fragments
- Maintain link hierarchy from root README

## Testing Changes

There's no build step for this project. To test:

1. Install your fork as a marketplace: `/plugin marketplace add youruser/workaholic`
2. Test the commands in a separate project
3. Verify behavior matches expectations

## Commit Messages

Follow the commit message rules:

- No prefixes (no `feat:`, `fix:`, etc.)
- Start with present-tense verb (Add, Update, Fix, Remove)
- Focus on why the change was made
- Keep title under 50 characters

## Pull Requests

Create PRs with `/pull-request`. The summary is auto-generated from the branch CHANGELOG. Ensure your PR:

- Has clear commit history (one ticket = one commit)
- Updates relevant documentation
- Follows existing patterns in the codebase
