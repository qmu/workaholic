---
title: Architecture
description: Plugin structure and marketplace design
category: developer
last_updated: 2026-01-23
---

# Architecture

Workaholic is a Claude Code plugin marketplace. It contains no runtime code; plugins are markdown files with JSON metadata that Claude Code interprets as commands, agents, rules, and skills.

## Marketplace Structure

```mermaid
flowchart TD
    subgraph Marketplace
        M[.claude-plugin/marketplace.json]
    end
    subgraph Plugins
        P1[plugins/core/]
        P2[plugins/tdd/]
    end
    subgraph Core Plugin
        C1[commands/]
        C2[agents/]
        C3[rules/]
    end
    subgraph TDD Plugin
        T1[commands/]
        T2[skills/]
    end
    M --> P1
    M --> P2
    P1 --> C1
    P1 --> C2
    P1 --> C3
    P2 --> T1
    P2 --> T2
```

## Directory Layout

```
.claude-plugin/
  marketplace.json       # Marketplace metadata and plugin list

plugins/
  core/
    .claude-plugin/
      plugin.json        # Plugin metadata
    commands/
      branch.md          # /branch command
      commit.md          # /commit command
      pull-request.md    # /pull-request command
    agents/
      discover-project.md
      discover-claude-dir.md
    rules/
      general.md
      typescript.md
      documentation.md

  tdd/
    .claude-plugin/
      plugin.json        # Plugin metadata
    commands/
      ticket.md          # /ticket command
      drive.md           # /drive command
    skills/
      archive-ticket/
        SKILL.md
        scripts/
          archive.sh     # Shell script for commit workflow
```

## Plugin Types

### Commands

Commands are user-invocable via slash syntax (`/commit`, `/ticket`). Each command is a markdown file with YAML frontmatter defining the name and description, followed by instructions that Claude follows when the command is invoked.

### Agents

Agents are subagent types that can be spawned with the Task tool. They specialize in specific tasks like exploring codebases or writing documentation. Agents define which tools they can use and what model to run on.

### Rules

Rules are always-on guidelines that Claude follows throughout the conversation. They define coding standards, documentation requirements, and best practices.

### Skills

Skills are more complex capabilities that may include scripts or multiple files. The `archive-ticket` skill includes a shell script that handles the complete commit workflow.

## How Claude Code Loads Plugins

When a user installs the marketplace with `/plugin marketplace add qmu/workaholic`, Claude Code:

1. Reads `.claude-plugin/marketplace.json` to find available plugins
2. For each plugin, reads `plugins/<name>/.claude-plugin/plugin.json`
3. Loads commands, agents, rules, and skills from the plugin directories
4. Makes commands available as slash commands in the conversation

## Data Flow

```mermaid
sequenceDiagram
    participant User
    participant Claude
    participant Plugin
    participant Filesystem

    User->>Claude: /ticket add auth
    Claude->>Plugin: Load ticket.md
    Plugin-->>Claude: Command instructions
    Claude->>Filesystem: Explore codebase
    Claude->>Filesystem: Write ticket to doc/tickets/
    Claude-->>User: Ticket created
```

## Version Management

Versions are tracked in two places:

- **Marketplace version**: `.claude-plugin/marketplace.json` - bumped with `/release`
- **Plugin versions**: `plugins/<name>/.claude-plugin/plugin.json` - updated when plugin changes

Keep these in sync when releasing.
