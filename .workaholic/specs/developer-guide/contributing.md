---
title: Contributing
description: How to add or modify plugins in Workaholic
category: developer
modified_at: 2026-01-27T18:34:06+09:00
commit_hash: 4b6b135
---

[English](contributing.md) | [日本語](contributing_ja.md)

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
    A[/ticket] --> B[/drive] --> C[/report]
```

1. **Create a ticket**: `/ticket add new validation rule`
2. **Implement**: `/drive` - follows the ticket, updates documentation, commits when approved
3. **Create PR**: `/report` - generates documentation and creates PR

Every implementation includes documentation updates. This is mandatory and cannot be skipped.

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
  sh/
    run.sh           # Executable scripts
```

## Documentation Standards

Documentation updates are mandatory for every change. The `/report` command automatically runs four documentation subagents in parallel (changelog-writer, story-writer, spec-writer, terms-writer), so documentation is always updated before PR creation.

Documentation standards enforced by the spec-writer and terms-writer subagents:

- YAML frontmatter on every markdown file (including `commit_hash` field)
- Use Mermaid for diagrams (ASCII art diagrams are prohibited)
- Write prose paragraphs, not bullet fragments
- Maintain link hierarchy from root README
- Update `modified_at` and `commit_hash` fields when modifying documents
- Place docs in correct subdirectory: `user-guide/` for user-facing, `developer-guide/` for architecture

Documentation is not optional. Every code change affects documentation in some way, whether updating existing docs, creating new ones, removing outdated files, or reorganizing the structure.

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

Create PRs with `/report`. The summary is auto-generated from the story file, which synthesizes archived tickets into a coherent narrative. Ensure your PR:

- Has clear commit history (one ticket = one commit)
- Includes documentation updates (handled automatically by subagents)
- Follows existing patterns in the codebase
