---
title: Architecture
description: Plugin structure and marketplace design
category: developer
modified_at: 2026-02-03T13:00:00+09:00
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
      drive-navigator.md      # Navigates and prioritizes tickets for /drive
      history-discoverer.md   # Searches archived tickets for related context
      overview-writer.md      # Generates overview content for stories
      performance-analyst.md  # Decision review for PR stories
      pr-creator.md           # Creates/updates GitHub PRs
      release-readiness.md    # Analyzes changes for release readiness
      scanner.md              # Invokes changelog-writer, spec-writer, terms-writer in parallel
      section-reviewer.md     # Generates story sections 5-8 from archived tickets
      source-discoverer.md    # Finds related source files and analyzes code flow
      spec-writer.md          # Updates .workaholic/specs/
      story-moderator.md      # Orchestrates scanner and story-writer in parallel
      story-writer.md         # Invokes overview-writer, section-reviewer, release-readiness, performance-analyst in parallel
      terms-writer.md         # Updates .workaholic/terms/
      ticket-moderator.md     # Analyzes tickets for duplicates, merges, and splits
      ticket-organizer.md     # Complete ticket workflow: discover, check duplicates, write
    commands/
      drive.md           # /drive command
      story.md           # /story command
      ticket.md          # /ticket command
    rules/
      diagrams.md        # Mermaid diagram requirements
      general.md         # Git workflow rules, markdown linking
      i18n.md            # Multi-language documentation rules
      shell.md           # POSIX shell script conventions
      typescript.md      # TypeScript coding standards
      workaholic.md      # Workaholic-specific conventions
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
        sh/
          create.sh        # Shell script for branch creation
      create-pr/
        SKILL.md
        sh/
          create-or-update.sh  # Creates or updates GitHub PRs
      create-ticket/
        SKILL.md           # Ticket creation with format and guidelines
      discover-history/
        SKILL.md           # Guidelines for searching archived tickets
        sh/
          search.sh        # Searches archived tickets by keywords
      discover-source/
        SKILL.md           # Guidelines for exploring source code
      drive-approval/
        SKILL.md           # Complete approval flow: request, revision, abandonment
      drive-workflow/
        SKILL.md           # Implementation workflow for tickets
      format-commit-message/
        SKILL.md           # Structured commit message format
      gather-ticket-metadata/
        SKILL.md           # Gathers ticket metadata in one call
        sh/
          gather.sh        # Shell script for metadata collection
      moderate-ticket/
        SKILL.md           # Guidelines for analyzing tickets for duplicates/merges/splits
      review-sections/
        SKILL.md           # Guidelines for generating story sections 5-8
      translate/
        SKILL.md           # Translation policies and .workaholic/ i18n enforcement
      update-ticket-frontmatter/
        SKILL.md           # Updates ticket YAML frontmatter fields
        sh/
          update.sh        # Shell script for frontmatter updates
      write-changelog/
        SKILL.md           # Changelog generation and writing guidelines
        sh/
          generate.sh      # Generates changelog entries from tickets
      write-final-report/
        SKILL.md           # Final report section for tickets
      write-overview/
        SKILL.md           # Guidelines for generating overview content
        sh/
          collect-commits.sh  # Collects commit data for overview
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
- **discover-history**: Guidelines for searching archived tickets to find related context
- **discover-source**: Guidelines for exploring source code to understand codebase context and find related files
- **drive-approval**: Complete approval flow for implementations including request, revision handling, and abandonment
- **drive-workflow**: Implementation workflow steps for processing tickets
- **format-commit-message**: Structured commit message format with title, motivation, UX, and architecture sections
- **gather-ticket-metadata**: Gathers ticket metadata (dates, commits, categories) in a single call
- **moderate-ticket**: Guidelines for analyzing existing tickets to detect duplicates, merge candidates, and split opportunities
- **review-sections**: Guidelines for generating story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas)
- **translate**: Translation policies and `.workaholic/` i18n enforcement (spec-writer, terms-writer, story-writer preload this)
- **update-ticket-frontmatter**: Updates ticket YAML frontmatter fields (effort, commit_hash, category)
- **write-changelog**: Generates changelog entries from archived tickets (grouping by category) and provides guidelines for updating CHANGELOG.md
- **write-final-report**: Writes final report section for tickets with optional discovered insights
- **write-overview**: Guidelines for generating overview, highlights, motivation, and journey sections for stories
- **write-spec**: Context gathering and guidelines for writing specification documents
- **write-story**: Metrics calculation, templates, and guidelines for branch stories
- **write-terms**: Context gathering and guidelines for terminology documents

### Agents

Agents are specialized subagents that can be spawned to handle complex tasks. They run in a subprocess with specific prompts and tools, preserving the main conversation's context window for interactive work. The core plugin includes:

- **changelog-writer**: Updates root `CHANGELOG.md` with entries from archived tickets, grouped by category (Added, Changed, Removed)
- **drive-navigator**: Navigates and prioritizes tickets for the `/drive` command, handling listing, analysis, and user confirmation for ticket ordering
- **history-discoverer**: Searches archived tickets to find related context and prior decisions
- **overview-writer**: Analyzes commit history to generate structured overview content (overview, highlights, motivation, journey) for story files
- **performance-analyst**: Evaluates decision-making quality across five viewpoints (Consistency, Intuitivity, Describability, Agility, Density) for PR stories
- **pr-creator**: Creates or updates GitHub pull requests using the story file as PR body, handling title derivation and `gh` CLI operations
- **release-readiness**: Analyzes changes for release readiness, providing verdict, concerns, and pre/post-release instructions
- **scanner**: Invokes documentation scanning agents (changelog-writer, spec-writer, terms-writer) in parallel and returns their combined status
- **section-reviewer**: Generates story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas) by analyzing archived tickets
- **source-discoverer**: Explores codebase to find related source files and analyzes code flow context
- **spec-writer**: Updates `.workaholic/specs/` documentation to reflect current codebase state
- **story-moderator**: Top-level orchestrator for documentation generation. Invokes scanner and story-writer in parallel (two-tier architecture), then integrates their outputs into branch stories in `.workaholic/stories/` with eleven sections
- **story-writer**: Invokes story generation agents (overview-writer, section-reviewer, release-readiness, performance-analyst) in parallel and returns their combined outputs for integration
- **terms-writer**: Updates `.workaholic/terms/` to maintain consistent term definitions
- **ticket-moderator**: Analyzes existing tickets for duplicates, merge candidates, and split opportunities before creating new tickets
- **ticket-organizer**: Complete ticket creation workflow: discovers history and source context, checks for duplicates/overlaps, and writes implementation tickets

## Command Dependencies

These diagrams show how each command invokes agents and skills at runtime. Commands are thin orchestrators that delegate work to specialized components.

### /ticket Dependencies

```mermaid
flowchart LR
    subgraph Command
        ticket["/ticket"]
    end

    subgraph Agents
        to[ticket-organizer]
        hd[history-discoverer]
        sd[source-discoverer]
        tm[ticket-moderator]
    end

    subgraph Skills
        cb[create-branch]
        ct[create-ticket]
        dh[discover-history]
        ds[discover-source]
    end

    ticket --> to

    to --> hd & sd & tm
    to --> ct & cb

    hd --> dh
    sd --> ds
```

### /drive Dependencies

```mermaid
flowchart LR
    subgraph Command
        drive["/drive"]
    end

    subgraph Agents
        dn[drive-navigator]
    end

    subgraph Skills
        dw[drive-workflow]
        at[archive-ticket]
        da[drive-approval]
        wfr[write-final-report]
        fcm[format-commit-message]
        utf[update-ticket-frontmatter]
    end

    drive --> dn
    drive --> dw & at & da & wfr

    %% Skill-to-skill
    dw --> fcm
    at --> fcm
    wfr --> utf
```

### /story Dependencies

```mermaid
flowchart LR
    subgraph Command
        story["/story"]
    end

    subgraph Agents
        sm[story-moderator]
        sc[scanner]
        sw[story-writer]
        cw[changelog-writer]
        spw[spec-writer]
        tw[terms-writer]
        rr[release-readiness]
        pa[performance-analyst]
        ow[overview-writer]
        sr[section-reviewer]
        pc[pr-creator]
    end

    subgraph Skills
        ws[write-story]
        wc[write-changelog]
        wsp[write-spec]
        wt[write-terms]
        arr[assess-release-readiness]
        ap[analyze-performance]
        wo[write-overview]
        rs[review-sections]
        tr[translate]
        cp[create-pr]
    end

    story --> sm
    story --> pc

    sm --> sc & sw

    sc --> cw & spw & tw
    sw --> rr & pa & ow & sr

    cw --> wc
    spw --> wsp
    tw --> wt
    rr --> arr
    pa --> ap
    ow --> wo
    sr --> rs
    sm --> ws
    pc --> cp

    %% Skill-to-skill
    ws --> tr
    wsp --> tr
    wt --> tr
```

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

Workaholic enforces comprehensive documentation through a two-tier parallel subagent architecture. The `/story` command delegates to story-moderator, which orchestrates two groups in parallel: scanner (documentation scanning) and story-writer (story generation), then integrates their outputs.

### How It Works

```mermaid
flowchart TD
    A["/story command"] --> SM[story-moderator]

    SM --> P1[Phase 1: Invoke 2 groups in parallel]

    subgraph Scanner Group
        SC[scanner]
        D[changelog-writer]
        F[spec-writer]
        G[terms-writer]
    end

    subgraph Story Group
        SW[story-writer]
        RR[release-readiness]
        PA[performance-analyst]
        OW[overview-writer]
        SR[section-reviewer]
    end

    P1 --> SC
    P1 --> SW

    SC --> D & F & G
    SW --> RR & PA & OW & SR

    D --> H[CHANGELOG.md]
    F --> J[.workaholic/specs/]
    G --> K[.workaholic/terms/]
    RR --> RL[Release JSON]
    PA --> PM[Performance markdown]
    OW --> OJ[Overview JSON]
    SR --> SJ[Sections JSON]

    H --> P2[Phase 2: Integrate & Write Story]
    J --> P2
    K --> P2
    RL --> P2
    PM --> P2
    OJ --> P2
    SJ --> P2

    P2 --> I[.workaholic/stories/]
    I --> L[Return to /story]

    L --> M[pr-creator subagent]
    M --> N[Create/update PR]
```

Documentation is updated automatically during the `/story` workflow.

The two-tier subagent architecture provides several benefits:

1. **Parallel execution** - Two groups run simultaneously, with each group running its agents in parallel
2. **Context isolation** - Scanner agents don't need story context; story-writer agents don't need changelog/spec/terms context
3. **Failure isolation** - If scanner fails, story-writer output is still valid, and vice versa
4. **Single responsibility** - Each agent handles one documentation domain
5. **Central orchestration** - Story-moderator is the hub that coordinates both groups and integrates outputs

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
| Subagent | Skill, Subagent    | Command             |
| Skill    | Skill              | Subagent, Command   |

Subagent → Subagent is allowed only in parallel (no sequential chains). Commands and subagents are the orchestration layer, defining workflow steps and invoking other components. Skills are the knowledge layer, containing templates, guidelines, rules, and bash scripts. Skills can preload other skills for composable knowledge (e.g., write-spec preloads translate for i18n enforcement). This separation prevents sequential nesting and context explosion while keeping comprehensive knowledge centralized in skills.

## Version Management

Versions are tracked in two places:

- **Marketplace version**: `.claude-plugin/marketplace.json` - bumped with `/release`
- **Plugin versions**: `plugins/<name>/.claude-plugin/plugin.json` - updated when plugin changes

Keep these in sync when releasing.
