---
title: Command Execution Flows
description: How commands invoke agents and skills
category: developer
modified_at: 2026-02-03T16:00:00+09:00
commit_hash: 3c87e62
---

[English](command-flows.md) | [日本語](command-flows_ja.md)

# Command Execution Flows

This document describes how each command orchestrates agents and skills during execution. Commands are thin orchestration layers that delegate work to specialized components.

## Architecture Overview

```
Command → Skills (preloaded)
        → Subagents (via Task tool) → Skills (preloaded)
```

- **Commands**: User-facing entry points that orchestrate workflows
- **Subagents**: Specialized workers invoked via Task tool (often using haiku model)
- **Skills**: Passive knowledge and scripts preloaded by commands/agents

## /ticket

Creates an implementation ticket with codebase exploration and historical context.

```mermaid
flowchart TD
    A[User: /ticket] --> B{On main branch?}
    B -->|Yes| C[Ask for prefix]
    C --> D[create-branch skill]
    D --> E[Create topic branch]
    B -->|No| F[Parse request]
    E --> F
    F --> G1[history-discoverer agent]
    F --> G2[source-discoverer agent]
    G1 --> H[discover-history skill]
    G2 --> I[discover-source skill]
    H --> J[Search archived tickets]
    I --> K[Find related source files]
    J --> L[Return related tickets]
    K --> M[Return file context]
    L --> N[create-ticket skill]
    M --> N
    N --> O[Explore codebase]
    O --> P[Write ticket file]
    P --> Q[Commit ticket]
```

### Components

| Component | Type | Purpose |
|-----------|------|---------|
| create-branch | Skill | Creates timestamped branch from main |
| history-discoverer | Agent (haiku) | Searches archived tickets for related context |
| source-discoverer | Agent (haiku) | Finds related source files and analyzes code flow |
| discover-history | Skill | Multi-keyword grep search script |
| discover-source | Skill | Source code exploration guidelines |
| create-ticket | Skill | Ticket format, frontmatter, and writing guidelines |

### Notes

- Branch creation happens automatically when on `main` or `master`
- History and source discovery run in parallel using haiku model for fast, cheap search
- Both discoveries complete before ticket creation
- Ticket is committed immediately unless invoked during `/drive`

## /drive

Implements queued tickets one by one with user approval at each step. The command directly executes the drive-workflow skill, preserving implementation context in the main conversation.

```mermaid
flowchart TD
    A[User: /drive] --> B[Check branch]
    B --> C[drive-navigator agent]
    C --> D[List tickets in todo/]
    D --> E{Tickets found?}
    E -->|No| F[Report: no tickets]
    E -->|Yes| G[For each ticket]
    G --> H[drive-workflow skill]
    H --> I[Read ticket]
    I --> J[Implement changes]
    J --> K[Ask for approval]
    K -->|Approve| L[Update effort + Final Report]
    K -->|Abandon| M[Discard changes]
    M --> N[Write Failure Analysis]
    N --> O[Move to abandoned/]
    L --> P[archive-ticket skill]
    P --> Q[Archive + Commit]
    Q --> R{More tickets?}
    O --> R
    R -->|Yes| G
    R -->|No| S[Report summary]
```

### Components

| Component | Type | Purpose |
|-----------|------|---------|
| drive-navigator | Agent (haiku) | Lists tickets in todo/ directory |
| drive-workflow | Skill | Step-by-step implementation workflow |
| archive-ticket | Skill | Moves ticket to archive, updates changelog, commits |

### Notes

- The drive command directly implements using the drive-workflow skill (no driver subagent)
- Implementation context is preserved in the main conversation for better visibility and debugging
- Each ticket gets its own commit
- User must approve each implementation before commit
- "Abandon" preserves failure analysis for future reference
- Icebox mode retrieves deferred tickets on demand

## /story

Generates comprehensive documentation and creates/updates a pull request using a two-tier parallel architecture.

```mermaid
flowchart TD
    A[User: /story] --> B[Check branch]
    B --> SM[story-moderator]

    SM --> P1[Parallel: scanner + story-writer]

    subgraph Scanner[scanner]
        F[changelog-writer]
        G[spec-writer]
        H[terms-writer]
        F --> F1[write-changelog skill]
        G --> G1[write-spec skill]
        G --> G2[translate skill]
        H --> H1[write-terms skill]
        H --> H2[translate skill]
    end

    subgraph StoryWriter[story-writer]
        OW[overview-writer]
        SR[section-reviewer]
        I[release-readiness]
        PA[performance-analyst]
        OW --> OW1[write-overview skill]
        SR --> SR1[review-sections skill]
        I --> I1[assess-release-readiness skill]
        PA --> PA1[analyze-performance skill]
        OW1 & SR1 & I1 & PA1 --> SW[write-story skill]
        SW --> SW2[translate skill]
        SW & SW2 --> PR[pr-creator agent]
        PR --> PR1[create-pr skill]
    end

    P1 --> Scanner
    P1 --> StoryWriter

    F1 & G1 & G2 & H1 & H2 --> SC[Scanner complete]
    PR1 --> SWC[story-writer complete]

    SC --> SM2[story-moderator complete]
    SWC --> SM2
    SM2 --> O[Display PR URL]
```

### Components

| Component | Type | Purpose |
|-----------|------|---------|
| story-moderator | Agent | Orchestrates scanner and story-writer in parallel |
| scanner | Agent | Invokes changelog-writer, spec-writer, terms-writer in parallel |
| story-writer | Agent | Generates story file and invokes pr-creator |
| changelog-writer | Agent (haiku) | Updates CHANGELOG.md from archived tickets |
| spec-writer | Agent (haiku) | Updates .workaholic/specs/ documentation |
| terms-writer | Agent (haiku) | Updates .workaholic/terms/ definitions |
| overview-writer | Agent | Generates overview, highlights, motivation, journey |
| section-reviewer | Agent | Generates sections 5-8 (Outcome, Historical Analysis, Concerns, Ideas) |
| release-readiness | Agent (haiku) | Analyzes changes for release concerns |
| performance-analyst | Agent | Evaluates decision-making quality |
| pr-creator | Agent (haiku) | Creates/updates GitHub PR |
| write-changelog | Skill | Changelog entry generation, categorization, and CHANGELOG.md updates |
| write-spec | Skill | Spec document format and guidelines |
| write-terms | Skill | Term document format and guidelines |
| write-story | Skill | Story document structure and templates (preloaded by story-writer) |
| assess-release-readiness | Skill | Release readiness criteria |
| analyze-performance | Skill | Performance evaluation framework |
| create-pr | Skill | PR creation via gh CLI |
| translate | Skill | English to Japanese translation |

### Notes

- Two-tier parallel architecture: story-moderator invokes scanner and story-writer in parallel
- Scanner group: changelog-writer, spec-writer, terms-writer (3 agents)
- Story group: overview-writer, section-reviewer, release-readiness, performance-analyst (4 agents)
- story-writer owns the write-story skill and invokes pr-creator after story generation
- Story file becomes the PR description body
- PR URL display is mandatory at completion
