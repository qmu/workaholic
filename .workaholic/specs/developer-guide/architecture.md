---
title: Architecture
description: Plugin structure and marketplace design
category: developer
modified_at: 2026-01-27T21:13:30+09:00
commit_hash: 82335e6
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
      performance-analyst.md  # Decision review for PR stories
      pr-creator.md           # Creates/updates GitHub PRs
      release-readiness.md    # Analyzes changes for release readiness
      spec-writer.md          # Updates .workaholic/specs/
      story-writer.md         # Generates branch stories for PRs
      terms-writer.md         # Updates .workaholic/terms/
    commands/
      branch.md          # /branch command
      drive.md           # /drive command
      report.md          # /report command
      ticket.md          # /ticket command
    rules/
      diagrams.md      # Mermaid diagram requirements
      general.md       # Git workflow rules
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
      block-commands/
        SKILL.md           # Documents settings.json deny rules
      calculate-story-metrics/
        SKILL.md
        sh/
          calculate.sh     # Calculates performance metrics
      create-pr/
        SKILL.md           # PR creation instructions
      define-ticket-format/
        SKILL.md           # Ticket file structure conventions
      drive-workflow/
        SKILL.md           # Implementation workflow for tickets
      enforce-i18n/
        SKILL.md           # i18n requirements for .workaholic/ docs
      gather-spec-context/
        SKILL.md
        sh/
          gather.sh        # Gathers context for spec updates
      gather-terms-context/
        SKILL.md
        sh/
          gather.sh        # Gathers context for terms updates
      generate-changelog/
        SKILL.md
        sh/
          generate.sh      # Generates changelog entries from tickets
      manage-pr/
        SKILL.md
        sh/
          create-or-update.sh  # Creates or updates GitHub PRs
      translate/
        SKILL.md           # Translation policies for i18n
      write-changelog/
        SKILL.md           # Changelog writing guidelines
      write-spec/
        SKILL.md           # Spec writing guidelines
      write-story/
        SKILL.md           # Story writing templates and guidelines
      write-terms/
        SKILL.md           # Terms writing guidelines
```

## Plugin Types

### Commands

Commands are user-invocable via slash syntax (`/ticket`, `/drive`, `/report`). Each command is a markdown file with YAML frontmatter defining the name and description, followed by instructions that Claude follows when the command is invoked.

### Rules

Rules are always-on guidelines that Claude follows throughout the conversation. They define coding standards, documentation requirements, and best practices.

### Skills

Skills are complex capabilities that may include scripts or multiple files. They are invoked via the Skill tool and provide inline instructions. Many skills include bash scripts that handle mechanical operations, while agents handle decision-making. The core plugin includes:

- **analyze-performance**: Evaluation framework for decision-making quality across five dimensions
- **archive-ticket**: Handles the complete commit workflow (archive ticket, update frontmatter with commit hash/category, commit)
- **assess-release-readiness**: Guidelines for analyzing changes and determining release readiness
- **block-commands**: Documents how to use settings.json deny rules to block dangerous commands
- **calculate-story-metrics**: Calculates performance metrics (commits, duration, velocity) for branch stories
- **create-pr**: Instructions for creating pull requests with proper formatting
- **define-ticket-format**: Ticket file structure and frontmatter conventions
- **drive-workflow**: Implementation workflow steps for processing tickets
- **enforce-i18n**: Enforces translation requirements for `.workaholic/` documentation (spec-writer and terms-writer preload this)
- **gather-spec-context**: Gathers context (branch, tickets, specs, diff) for documentation updates
- **gather-terms-context**: Gathers context (branch, tickets, terms, diff) for terminology updates
- **generate-changelog**: Generates changelog entries from archived tickets, grouping by category
- **manage-pr**: Creates or updates GitHub PRs using the gh CLI
- **translate**: Translation policies for converting English markdown files to other languages (primarily Japanese)
- **write-changelog**: Guidelines for writing changelog entries
- **write-spec**: Guidelines for writing and updating specification documents
- **write-story**: Story content structure, templates, and writing guidelines
- **write-terms**: Guidelines for writing and updating terminology documents

### Agents

Agents are specialized subagents that can be spawned to handle complex tasks. They run in a subprocess with specific prompts and tools, preserving the main conversation's context window for interactive work. The core plugin includes:

- **changelog-writer**: Updates root `CHANGELOG.md` with entries from archived tickets, grouped by category (Added, Changed, Removed)
- **performance-analyst**: Evaluates decision-making quality across five viewpoints (Consistency, Intuitivity, Describability, Agility, Density) for PR stories
- **pr-creator**: Creates or updates GitHub pull requests using the story file as PR body, handling title derivation and `gh` CLI operations
- **release-readiness**: Analyzes changes for release readiness, providing verdict, concerns, and pre/post-release instructions
- **spec-writer**: Updates `.workaholic/specs/` documentation to reflect current codebase state
- **story-writer**: Generates branch stories in `.workaholic/stories/` that serve as the single source of truth for PR content, with eleven sections: Overview, Motivation, Journey (containing Topic Tree flowchart), Changes, Outcome, Historical Analysis, Concerns, Ideas, Performance, Release Preparation, and Notes
- **terms-writer**: Updates `.workaholic/terms/` to maintain consistent term definitions

## Dependency Graph

This diagram shows how commands, agents, and skills invoke each other at runtime.

```mermaid
flowchart LR
    subgraph Commands
        report[/report]
        drive[/drive]
        ticket[/ticket]
        branch[/branch]
    end

    subgraph Agents
        cw[changelog-writer]
        sw[story-writer]
        spw[spec-writer]
        tw[terms-writer]
        pc[pr-creator]
        pa[performance-analyst]
        rr[release-readiness]
    end

    subgraph Skills
        at[archive-ticket]
        gc[generate-changelog]
        csm[calculate-story-metrics]
        gsc[gather-spec-context]
        gtc[gather-terms-context]
        mp[manage-pr]
        dtf[define-ticket-format]
        dw[drive-workflow]
        ei[enforce-i18n]
        ws[write-story]
        wsp[write-spec]
        wt[write-terms]
        wc[write-changelog]
        cp[create-pr]
        ap[analyze-performance]
        arr[assess-release-readiness]
    end

    report --> cw & sw & spw & tw & pc
    drive --> at & dw
    ticket --> dtf

    cw --> gc & wc
    sw --> csm & ws
    sw --> pa & rr
    spw --> gsc & wsp
    spw --> ei
    tw --> gtc & wt
    tw --> ei
    pc --> mp & cp
    pa --> ap
    rr --> arr
```

## How Claude Code Loads Plugins

When a user installs the marketplace with `/plugin marketplace add qmu/workaholic`, Claude Code:

1. Reads `.claude-plugin/marketplace.json` to find available plugins
2. For each plugin, reads `plugins/<name>/.claude-plugin/plugin.json`
3. Loads commands, rules, and skills from the plugin directories
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
    Claude->>Filesystem: Write ticket to .workaholic/tickets/
    Claude-->>User: Ticket created
```

## Documentation Enforcement

Workaholic enforces comprehensive documentation through a parallel subagent architecture. The `/report` command orchestrates four documentation agents that run concurrently, each handling a specific domain.

### How It Works

```mermaid
flowchart TD
    A[/report command] --> B[Move remaining tickets to icebox]
    B --> C[Invoke 4 subagents in parallel]

    subgraph Parallel Documentation
        D[changelog-writer]
        E[story-writer]
        F[spec-writer]
        G[terms-writer]
    end

    C --> D
    C --> E
    C --> F
    C --> G

    D --> H[CHANGELOG.md]
    E --> I[.workaholic/stories/]
    F --> J[.workaholic/specs/]
    G --> K[.workaholic/terms/]

    H --> L[Commit docs]
    I --> L
    J --> L
    K --> L

    L --> M[pr-creator subagent]
    M --> N[Create/update PR]
```

Documentation is updated automatically during the `/report` workflow.

The subagent architecture provides several benefits:

1. **Parallel execution** - All four agents run simultaneously, reducing wait time
2. **Context isolation** - Each agent works in its own context window, preserving the main conversation
3. **Single responsibility** - Each agent handles one documentation domain
4. **Resilient to failures** - If one agent fails, others can still complete

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

## Command Prohibition

Dangerous commands can be blocked project-wide using `.claude/settings.json` deny rules. This is preferable to embedding prohibitions in individual agent instructions because it provides centralized enforcement that applies before command execution.

```json
{
  "permissions": {
    "deny": [
      "Bash(git -C:*)"
    ]
  }
}
```

The pattern `Bash(git -C:*)` uses prefix matching (`:*` suffix) to block any bash command starting with `git -C`. This prevents the `-C` flag from being used, which causes permission prompts when git operates outside the expected working directory.

When deciding between deny rules and agent instructions, use deny rules for commands that should never be allowed. Use agent instructions for context-specific guidance where warnings are sufficient.

## Version Management

Versions are tracked in two places:

- **Marketplace version**: `.claude-plugin/marketplace.json` - bumped with `/release`
- **Plugin versions**: `plugins/<name>/.claude-plugin/plugin.json` - updated when plugin changes

Keep these in sync when releasing.
