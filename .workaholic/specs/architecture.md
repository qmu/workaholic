---
title: Architecture
description: Plugin structure and marketplace design
category: developer
modified_at: 2026-02-07T03:26:29+09:00
commit_hash: d5001a0
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
      architecture-analyst.md # Analyzes repo from a viewpoint, writes .workaholic/specs/<slug>.md
      changelog-writer.md     # Updates CHANGELOG.md from tickets
      drive-navigator.md      # Navigates and prioritizes tickets for /drive
      history-discoverer.md   # Searches archived tickets for related context
      overview-writer.md      # Generates overview content for stories
      performance-analyst.md  # Decision review for PR stories
      policy-analyst.md       # Analyzes repo from a policy domain, writes .workaholic/policies/<slug>.md
      policy-writer.md        # Orchestrates 7 parallel policy-analyst subagents
      pr-creator.md           # Creates/updates GitHub PRs
      release-note-writer.md  # Writes release notes
      release-readiness.md    # Analyzes changes for release readiness
      scanner.md              # Invokes changelog-writer, spec-writer, terms-writer, policy-writer in parallel
      section-reviewer.md     # Generates story sections 5-8 from archived tickets
      source-discoverer.md    # Finds related source files and analyzes code flow
      spec-writer.md          # Orchestrates 8 parallel architecture-analyst subagents
      story-writer.md         # Invokes overview-writer, section-reviewer, release-readiness, performance-analyst in parallel
      terms-writer.md         # Updates .workaholic/terms/
      ticket-discoverer.md    # Analyzes tickets for duplicates, merges, and splits
      ticket-organizer.md     # Complete ticket workflow: discover, check duplicates, write
    commands/
      drive.md           # /drive command
      report.md          # /report command
      scan.md            # /scan command
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
        sh/
          calculate.sh     # Calculates performance metrics
      analyze-policy/
        SKILL.md           # Generic policy analysis framework
        sh/
          gather.sh        # Gathers policy-domain-specific context
      analyze-viewpoint/
        SKILL.md           # Generic viewpoint analysis framework
        sh/
          gather.sh        # Gathers viewpoint-specific context
          read-overrides.sh  # Reads CLAUDE.md for viewpoint overrides
      archive-ticket/
        SKILL.md
        sh/
          archive.sh       # Shell script for commit workflow
      assess-release-readiness/
        SKILL.md           # Release readiness analysis guidelines
      commit/
        SKILL.md           # Commit creation guidelines
        sh/
          commit.sh        # Shell script for commit operations
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
      discover-ticket/
        SKILL.md           # Guidelines for analyzing tickets for duplicates/merges/splits
      drive-approval/
        SKILL.md           # Complete approval flow: request, feedback, abandonment
      drive-workflow/
        SKILL.md           # Implementation workflow for tickets
      format-commit-message/
        SKILL.md           # Structured commit message format
      gather-git-context/
        SKILL.md           # Gathers all context for documentation subagents
        sh/
          gather.sh        # Shell script for context collection
      gather-ticket-metadata/
        SKILL.md           # Gathers ticket metadata in one call
        sh/
          gather.sh        # Shell script for metadata collection
      manage-branch/
        SKILL.md           # Check and create timestamped topic branches
        sh/
          check.sh         # Checks current branch status
          create.sh        # Shell script for branch creation
      review-sections/
        SKILL.md           # Guidelines for generating story sections 5-8
      translate/
        SKILL.md           # Translation policies and .workaholic/ i18n enforcement
      update-ticket-frontmatter/
        SKILL.md           # Updates ticket YAML frontmatter fields
        sh/
          update.sh        # Shell script for frontmatter updates
      validate-writer-output/
        SKILL.md           # Validates analyst output files before README update
        sh/
          validate.sh      # Checks file existence and non-emptiness
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
      write-release-note/
        SKILL.md           # Release note generation guidelines
      write-spec/
        SKILL.md
        sh/
          gather.sh        # Gathers context for spec writing
      write-story/
        SKILL.md           # Story content structure and guidelines
      write-terms/
        SKILL.md
        sh/
          gather.sh        # Gathers context for terms writing
```

## Plugin Types

### Commands

Commands are user-invocable via slash syntax (`/ticket`, `/drive`, `/report`). Each command is a markdown file with YAML frontmatter defining the name and description, followed by instructions that Claude follows when the command is invoked.

### Rules

Rules are always-on guidelines that Claude follows throughout the conversation. They define coding standards, documentation requirements, and best practices.

### Skills

Skills are complex capabilities that may include scripts or multiple files. They are invoked via the Skill tool and provide inline instructions. Many skills include bash scripts that handle mechanical operations, while agents handle decision-making. The core plugin includes:

- **analyze-performance**: Evaluation framework for decision-making quality across five dimensions
- **analyze-policy**: Generic framework for policy-based repository analysis with output templates and inference guidelines
- **analyze-viewpoint**: Generic framework for viewpoint-based architecture analysis with output templates, assumption rules, and context gathering
- **archive-ticket**: Handles the complete commit workflow (archive ticket, update frontmatter with commit hash/category, commit)
- **assess-release-readiness**: Guidelines for analyzing changes and determining release readiness
- **commit**: Commit creation guidelines with shell script for commit operations
- **create-pr**: Creates or updates GitHub PRs using the gh CLI with proper formatting
- **create-ticket**: Complete ticket creation workflow including format, exploration, and related history
- **discover-history**: Guidelines for searching archived tickets to find related context
- **discover-source**: Guidelines for exploring source code to understand codebase context and find related files
- **discover-ticket**: Guidelines for analyzing existing tickets to detect duplicates, merge candidates, and split opportunities
- **drive-approval**: Complete approval flow for implementations including request, feedback handling, and abandonment
- **drive-workflow**: Implementation workflow steps for processing tickets
- **format-commit-message**: Structured commit message format with title, motivation, UX, and architecture sections
- **gather-git-context**: Gathers all context for documentation subagents (branch, base branch, URL, archived tickets, git log) in a single call
- **gather-ticket-metadata**: Gathers ticket metadata (dates, commits, categories) in a single call
- **manage-branch**: Check and create timestamped topic branches with configurable prefix
- **review-sections**: Guidelines for generating story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas)
- **translate**: Translation policies and `.workaholic/` i18n enforcement (spec-writer, terms-writer, story-writer preload this)
- **update-ticket-frontmatter**: Updates ticket YAML frontmatter fields (effort, commit_hash, category)
- **validate-writer-output**: Validates that analyst subagent output files exist and are non-empty before README index updates
- **write-changelog**: Generates changelog entries from archived tickets (grouping by category) and provides guidelines for updating CHANGELOG.md
- **write-final-report**: Writes final report section for tickets with optional discovered insights
- **write-overview**: Guidelines for generating overview, highlights, motivation, and journey sections for stories
- **write-release-note**: Guidelines for generating release notes
- **write-spec**: Context gathering and guidelines for writing viewpoint-based specification documents
- **write-story**: Story content structure, templates, and guidelines for branch stories
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
- **architecture-analyst**: Receives a viewpoint definition from spec-writer, analyzes the repository from that perspective, and writes a viewpoint spec document
- **policy-analyst**: Receives a policy domain definition from policy-writer, analyzes the repository from that policy perspective, and writes a policy document
- **policy-writer**: Orchestrates 7 parallel policy-analyst subagents to generate policy documents under `.workaholic/policies/`
- **release-note-writer**: Generates release notes for new versions
- **scanner**: Invokes documentation scanning agents (changelog-writer, spec-writer, terms-writer, policy-writer) in parallel and returns their combined status
- **section-reviewer**: Generates story sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas) by analyzing archived tickets
- **source-discoverer**: Explores codebase to find related source files and analyzes code flow context
- **spec-writer**: Orchestrates 8 parallel architecture-analyst subagents to update `.workaholic/specs/` with viewpoint-based documentation
- **story-writer**: Orchestrates story generation by invoking overview-writer, section-reviewer, release-readiness, performance-analyst in parallel, then writes story file and invokes pr-creator
- **terms-writer**: Updates `.workaholic/terms/` to maintain consistent term definitions
- **ticket-discoverer**: Analyzes existing tickets for duplicates, merge candidates, and split opportunities before creating new tickets
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
        td[ticket-discoverer]
    end

    subgraph Skills
        mb[manage-branch]
        ct[create-ticket]
        dh[discover-history]
        ds[discover-source]
        dt[discover-ticket]
    end

    ticket --> to

    to --> hd & sd & td
    to --> ct & mb

    hd --> dh
    sd --> ds
    td --> dt
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

### /scan Dependencies

```mermaid
flowchart LR
    subgraph Command
        scan["/scan"]
    end

    subgraph Agents
        sc[scanner]
        cw[changelog-writer]
        spw[spec-writer]
        tw[terms-writer]
        pw[policy-writer]
        aa[architecture-analyst x8]
        pa[policy-analyst x7]
    end

    subgraph Skills
        wc[write-changelog]
        av[analyze-viewpoint]
        wsp[write-spec]
        ap[analyze-policy]
        wt[write-terms]
        vwo[validate-writer-output]
        tr[translate]
    end

    scan --> sc

    sc --> cw & spw & tw & pw

    cw --> wc
    spw --> aa
    aa --> av & wsp & tr
    spw --> vwo
    tw --> wt
    pw --> pa
    pa --> ap & tr
    pw --> vwo

    %% Skill-to-skill
    wt --> tr
```

### /report Dependencies

```mermaid
flowchart LR
    subgraph Command
        report["/report"]
    end

    subgraph Agents
        sw[story-writer]
        rr[release-readiness]
        pa[performance-analyst]
        ow[overview-writer]
        sr[section-reviewer]
        pc[pr-creator]
    end

    subgraph Skills
        ws[write-story]
        arr[assess-release-readiness]
        ap[analyze-performance]
        wo[write-overview]
        rs[review-sections]
        tr[translate]
        cp[create-pr]
    end

    report --> sw

    sw --> rr & pa & ow & sr & pc

    rr --> arr
    pa --> ap
    ow --> wo
    sr --> rs
    sw --> ws
    pc --> cp

    %% Skill-to-skill
    ws --> tr
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

Workaholic enforces comprehensive documentation through two separate commands: `/scan` for documentation maintenance and `/report` for story generation and PR creation. This decoupled architecture allows independent documentation updates without requiring a PR.

### How It Works

```mermaid
flowchart TD
    subgraph scan["/scan command"]
        SC[scanner]
        D[changelog-writer]
        F[spec-writer]
        G[terms-writer]
        PW[policy-writer]

        SC --> D & F & G & PW

        D --> H[CHANGELOG.md]
        F --> J[.workaholic/specs/]
        G --> K[.workaholic/terms/]
        PW --> L2[.workaholic/policies/]
    end

    subgraph report["/report command"]
        SW[story-writer]
        RR[release-readiness]
        PA[performance-analyst]
        OW[overview-writer]
        SR[section-reviewer]
        PC[pr-creator]

        SW --> RR & PA & OW & SR

        RR --> RL[Release JSON]
        PA --> PM[Performance markdown]
        OW --> OJ[Overview JSON]
        SR --> SJ[Sections JSON]

        RL --> P3[Write story file]
        PM --> P3
        OJ --> P3
        SJ --> P3

        P3 --> I[.workaholic/stories/]
        I --> PC
        PC --> N[Create/update PR]
    end
```

The `/scan` command updates documentation (changelog, specs, terms) independently. The `/report` command generates stories and creates PRs. Users who want documentation updates without PR creation can run `/scan` independently.

This decoupled architecture provides several benefits:

1. **Independent execution** - Documentation can be updated without creating a PR
2. **Simpler architecture** - Each command has a single responsibility
3. **Parallel agents** - Scanner runs 4 agents in parallel; story-writer runs 4 agents in parallel
4. **Clear workflow** - Typical flow: `/ticket` → `/drive` → `/scan` → `/report`

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
