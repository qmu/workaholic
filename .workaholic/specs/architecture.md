---
title: Architecture
description: Plugin structure and marketplace design
category: developer
modified_at: 2026-01-29T13:30:00+09:00
commit_hash: 72f9d7a
---

[English](architecture.md) | [日本語](architecture_ja.md)

# Architecture

Workaholic is a Claude Code plugin marketplace. It contains no runtime code; plugins are markdown files with JSON metadata that Claude Code interprets as commands, rules, skills, and agents.

## Marketplace Structure

```mermaid
flowchart TD
    subgraph Marketplace
        M[.claude-plugin/marketplace.json]
    end
    subgraph Core Plugin
        P1[plugins/core/]
        C1[commands/]
        C2[rules/]
        C3[skills/]
        C4[agents/]
    end
    M --> P1
    P1 --> C1
    P1 --> C2
    P1 --> C3
    P1 --> C4
```

## Directory Layout

```
.claude-plugin/
  marketplace.json       # Marketplace metadata and plugin list

plugins/
  core/
    .claude-plugin/
      plugin.json        # Plugin metadata
    agents/
      changelog-writer.md     # Updates CHANGELOG.md from tickets
      history-discoverer.md   # Searches archived tickets for related context
      performance-analyst.md  # Decision review for PR stories
      pr-creator.md           # Creates/updates GitHub PRs
      release-readiness.md    # Analyzes changes for release readiness
      source-discoverer.md    # Finds related source files and analyzes code flow
      spec-writer.md          # Updates .workaholic/specs/
      story-writer.md         # Generates branch stories for PRs
      terms-writer.md         # Updates .workaholic/terms/
    commands/
      drive.md           # /drive command
      story.md           # /story command
      ticket.md          # /ticket command
    rules/
      diagrams.md      # Mermaid diagram requirements
      general.md       # Git workflow rules, markdown linking
      i18n.md          # Multi-language documentation rules
      shell.md         # POSIX shell script conventions
      typescript.md    # TypeScript coding standards
    skills/
      analyze-performance/
        SKILL.md           # Performance analysis framework
      archive-ticket/
        SKILL.md
        sh/
          archive.sh       # Shell script for commit workflow
      assess-release-readiness/
        SKILL.md           # Release readiness analysis guidelines
      create-branch/
        SKILL.md           # Creates timestamped topic branches
      create-pr/
        SKILL.md
        sh/
          create-or-update.sh  # Creates or updates GitHub PRs
      create-ticket/
        SKILL.md           # Ticket creation with format and guidelines
      discover-source/
        SKILL.md           # Guidelines for exploring source code
      drive-workflow/
        SKILL.md           # Implementation workflow for tickets
      generate-changelog/
        SKILL.md
        sh/
          generate.sh      # Generates changelog entries from tickets
      translate/
        SKILL.md           # Translation policies and .workaholic/ i18n enforcement
      write-changelog/
        SKILL.md           # Changelog writing guidelines
      write-spec/
        SKILL.md
        sh/
          gather.sh        # Gathers context and writes specs
      write-story/
        SKILL.md
        sh/
          calculate.sh     # Calculates metrics and writes stories
      write-terms/
        SKILL.md
        sh/
          gather.sh        # Gathers context and writes terms
```

## Plugin Types

### Commands

Commands are user-invocable via slash syntax (`/ticket`, `/drive`, `/story`). Each command is a markdown file with YAML frontmatter defining the name and description, followed by instructions that Claude follows when the command is invoked.

### Rules

Rules are always-on guidelines that Claude follows throughout the conversation. They define coding standards, documentation requirements, and best practices.

### Skills

Skills are complex capabilities that may include scripts or multiple files. They are invoked via the Skill tool and provide inline instructions. Many skills include bash scripts that handle mechanical operations, while agents handle decision-making. The core plugin includes:

- **analyze-performance**: Evaluation framework for decision-making quality across five dimensions
- **archive-ticket**: Handles the complete commit workflow (archive ticket, update frontmatter with commit hash/category, commit)
- **assess-release-readiness**: Guidelines for analyzing changes and determining release readiness
- **create-branch**: Creates timestamped topic branches with configurable prefix
- **create-pr**: Creates or updates GitHub PRs using the gh CLI with proper formatting
- **create-ticket**: Complete ticket creation workflow including format, exploration, and related history
- **discover-source**: Guidelines for exploring source code to understand codebase context and find related files
- **drive-workflow**: Implementation workflow steps for processing tickets
- **generate-changelog**: Generates changelog entries from archived tickets, grouping by category
- **translate**: Translation policies and `.workaholic/` i18n enforcement (spec-writer, terms-writer, story-writer preload this)
- **write-changelog**: Guidelines for writing changelog entries
- **write-spec**: Context gathering and guidelines for writing specification documents
- **write-story**: Metrics calculation, templates, and guidelines for branch stories
- **write-terms**: Context gathering and guidelines for terminology documents

### Agents

Agents are specialized subagents that can be spawned to handle complex tasks. They run in a subprocess with specific prompts and tools, preserving the main conversation's context window for interactive work. The core plugin includes:

- **changelog-writer**: Updates root `CHANGELOG.md` with entries from archived tickets, grouped by category (Added, Changed, Removed)
- **history-discoverer**: Searches archived tickets to find related context and prior decisions
- **performance-analyst**: Evaluates decision-making quality across five viewpoints (Consistency, Intuitivity, Describability, Agility, Density) for PR stories
- **pr-creator**: Creates or updates GitHub pull requests using the story file as PR body, handling title derivation and `gh` CLI operations
- **release-readiness**: Analyzes changes for release readiness, providing verdict, concerns, and pre/post-release instructions
- **source-discoverer**: Explores codebase to find related source files and analyzes code flow context
- **spec-writer**: Updates `.workaholic/specs/` documentation to reflect current codebase state
- **story-writer**: Generates branch stories in `.workaholic/stories/` that serve as the single source of truth for PR content, with eleven sections: Overview, Motivation, Journey (containing Topic Tree flowchart), Changes, Outcome, Historical Analysis, Concerns, Ideas, Performance, Release Preparation, and Notes
- **terms-writer**: Updates `.workaholic/terms/` to maintain consistent term definitions

## Dependency Graph

This diagram shows how commands, agents, and skills invoke each other at runtime.

```mermaid
flowchart LR
    subgraph Commands
        story[/story]
        drive[/drive]
        ticket[/ticket]
    end

    subgraph Agents
        cw[changelog-writer]
        sw[story-writer]
        spw[spec-writer]
        tw[terms-writer]
        hd[history-discoverer]
        sd[source-discoverer]
        pc[pr-creator]
        pa[performance-analyst]
        rr[release-readiness]
    end

    subgraph Skills
        at[archive-ticket]
        gc[generate-changelog]
        cb[create-branch]
        ct[create-ticket]
        dh[discover-history]
        ds[discover-source]
        dw[drive-workflow]
        tr[translate]
        ws[write-story]
        wsp[write-spec]
        wt[write-terms]
        wc[write-changelog]
        cp[create-pr]
        ap[analyze-performance]
        arr[assess-release-readiness]
    end

    story --> cw & spw & tw & rr
    story -.-> sw
    story --> pc
    drive --> at & dw
    ticket --> ct & hd & sd
    ticket --> cb

    hd --> dh
    sd --> ds
    cw --> gc & wc
    sw --> ws & tr
    sw --> pa
    spw --> wsp & tr
    tw --> wt & tr
    pc --> cp
    pa --> ap
    rr --> arr
```

Note: The `/story` command runs four agents in parallel (changelog-writer, spec-writer, terms-writer, release-readiness), then runs story-writer with the release-readiness output, and finally runs pr-creator. The `/ticket` command runs history-discoverer and source-discoverer in parallel to find related tickets and code context.

## How Claude Code Loads Plugins

When a user installs the marketplace with `/plugin marketplace add qmu/workaholic`, Claude Code:

1. Reads `.claude-plugin/marketplace.json` to find available plugins
2. For each plugin, reads `plugins/<name>/.claude-plugin/plugin.json`
3. Loads commands, rules, and skills from the plugin directories
4. Auto-loads `hooks/hooks.json` from the plugin directory if it exists (standard location)
5. Makes commands available as slash commands in the conversation

### Plugin Manifest Fields

The `plugin.json` file contains metadata about the plugin:

```json
{
  "name": "core",
  "description": "Plugin description",
  "version": "1.0.0",
  "author": {
    "name": "author name",
    "email": "author@example.com"
  }
}
```

**Important**: The `hooks` field should NOT be declared in `plugin.json` when hooks are in the standard location (`hooks/hooks.json`). Claude Code automatically detects and loads hooks from this location. Declaring the hooks field in the manifest when they're also at the standard location causes a "Duplicate hooks file detected" error.

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
    Claude->>Filesystem: Write ticket to .workaholic/tickets/
    Claude-->>User: Ticket created
```

## Documentation Enforcement

Workaholic enforces comprehensive documentation through a parallel subagent architecture. The `/story` command orchestrates documentation agents in two phases: four agents run in parallel first, then story-writer runs with the release-readiness output.

### How It Works

```mermaid
flowchart TD
    A[/story command] --> B[Move remaining tickets to icebox]
    B --> C[Phase 1: Invoke 4 subagents in parallel]

    subgraph Phase 1 - Parallel
        D[changelog-writer]
        F[spec-writer]
        G[terms-writer]
        RR[release-readiness]
    end

    C --> D
    C --> F
    C --> G
    C --> RR

    D --> H[CHANGELOG.md]
    F --> J[.workaholic/specs/]
    G --> K[.workaholic/terms/]
    RR --> RL[Release JSON]

    H --> P2[Phase 2: story-writer]
    J --> P2
    K --> P2
    RL --> P2

    P2 --> I[.workaholic/stories/]
    I --> L[Commit docs]

    L --> M[pr-creator subagent]
    M --> N[Create/update PR]
```

Documentation is updated automatically during the `/story` workflow.

The subagent architecture provides several benefits:

1. **Parallel execution** - Four agents run simultaneously in Phase 1, reducing wait time
2. **Context isolation** - Each agent works in its own context window, preserving the main conversation
3. **Single responsibility** - Each agent handles one documentation domain
4. **Data dependency handling** - Story-writer receives release-readiness output in Phase 2

### Critical Requirements

All documentation agents enforce strict requirements:

- **Document every change** - No exceptions, no judgment calls about what's "worth" documenting
- **Never skip documentation** - "Internal implementation detail" is never a valid reason
- **Always report updates** - Must specify which files were created or modified
- **"No updates needed" is unacceptable** - Every change affects documentation somehow

### Design Policy

Documentation is mandatory, not optional. This reflects Workaholic's core principle of **cognitive investment**: developer cognitive load is the primary bottleneck in software productivity, so we invest heavily in generating structured knowledge artifacts to reduce this load.

The three primary artifact types are:

- **Tickets** - Change requests with structured metadata (date, author, type, layer, effort, commit_hash, category)
- **Specs** - Current state snapshots serving as reference documentation
- **Stories** - Narrative accounts of the developer journey per branch

Tickets serve as the single source of truth for change metadata. The root `CHANGELOG.md` is generated from archived tickets during PR creation.

## Architecture Policy

Workaholic follows strict nesting rules for component invocations to maintain a clean separation between orchestration and knowledge.

| Caller   | Can invoke         | Cannot invoke       |
| -------- | ------------------ | ------------------- |
| Command  | Skill, Subagent    | -                   |
| Subagent | Skill              | Subagent, Command   |
| Skill    | -                  | Subagent, Command   |

Commands and subagents are the orchestration layer, defining workflow steps and invoking other components. Skills are the knowledge layer, containing templates, guidelines, rules, and bash scripts. This separation prevents deep nesting and context explosion while keeping comprehensive knowledge centralized in skills.

## Version Management

Versions are tracked in two places:

- **Marketplace version**: `.claude-plugin/marketplace.json` - bumped with `/release`
- **Plugin versions**: `plugins/<name>/.claude-plugin/plugin.json` - updated when plugin changes

Keep these in sync when releasing.
