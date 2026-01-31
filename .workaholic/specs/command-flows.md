---
title: Command Execution Flows
description: How commands invoke agents and skills
category: developer
modified_at: 2026-01-31T19:07:11+09:00
commit_hash: 06ebf65
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

Implements queued tickets one by one with user approval at each step.

```mermaid
flowchart TD
    A[User: /drive] --> B[List tickets in todo/]
    B --> C{Tickets found?}
    C -->|No| D[Report: no tickets]
    C -->|Yes| E[For each ticket]
    E --> F[drive-workflow skill]
    F --> G[Read ticket]
    G --> H[Implement changes]
    H --> I[Ask for approval]
    I -->|Approve| J[Update effort + Final Report]
    I -->|Abandon| K[Discard changes]
    K --> L[Write Failure Analysis]
    L --> M[Move to fail/]
    J --> N[archive-ticket skill]
    N --> O[Archive + Commit]
    O --> P{More tickets?}
    M --> P
    P -->|Yes| E
    P -->|No| Q[Report summary]
```

### Components

| Component | Type | Purpose |
|-----------|------|---------|
| drive-workflow | Skill | Step-by-step implementation workflow |
| archive-ticket | Skill | Moves ticket to archive, updates changelog, commits |

### Notes

- Each ticket gets its own commit
- User must approve each implementation before commit
- "Abandon" preserves failure analysis for future reference
- Icebox mode retrieves deferred tickets on demand

## /story

Generates comprehensive documentation and creates/updates a pull request.

```mermaid
flowchart TD
    A[User: /story] --> B[Check branch]
    B --> C{Tickets in todo?}
    C -->|Yes| D[Move to icebox + commit]
    C -->|No| E[Phase 1: Parallel agents]
    D --> E

    subgraph Phase1[Phase 1 - Parallel]
        F[changelog-writer]
        G[spec-writer]
        H[terms-writer]
        I[release-readiness]
        PA[performance-analyst]
    end

    E --> F & G & H & I & PA

    F --> F1[write-changelog skill]
    G --> G1[write-spec skill]
    G --> G2[translate skill]
    H --> H1[write-terms skill]
    H --> H2[translate skill]
    I --> I1[assess-release-readiness skill]
    PA --> PA1[analyze-performance skill]

    F1 & G1 & G2 & H1 & H2 & I1 & PA1 --> J[Phase 2: story-writer]

    J --> J1[write-story skill]
    J --> J2[translate skill]

    J1 & J2 --> K[Commit docs]
    K --> L[Push branch]
    L --> M[pr-creator agent]
    M --> M1[create-pr skill]
    M1 --> N[Create/Update PR]
    N --> O[Display PR URL]
```

### Components

| Component | Type | Purpose |
|-----------|------|---------|
| changelog-writer | Agent (haiku) | Updates CHANGELOG.md from archived tickets |
| spec-writer | Agent (haiku) | Updates .workaholic/specs/ documentation |
| terms-writer | Agent (haiku) | Updates .workaholic/terms/ definitions |
| release-readiness | Agent (haiku) | Analyzes changes for release concerns |
| story-writer | Agent (haiku) | Generates PR narrative in 11 sections |
| performance-analyst | Agent | Evaluates decision-making quality |
| pr-creator | Agent (haiku) | Creates/updates GitHub PR |
| write-changelog | Skill | Changelog entry generation, categorization, and CHANGELOG.md updates |
| write-spec | Skill | Spec document format and guidelines |
| write-terms | Skill | Term document format and guidelines |
| write-story | Skill | Story document structure and templates |
| assess-release-readiness | Skill | Release readiness criteria |
| analyze-performance | Skill | Performance evaluation framework |
| create-pr | Skill | PR creation via gh CLI |
| translate | Skill | English to Japanese translation |

### Notes

- Phase 1 runs 5 agents in parallel for efficiency
- Phase 2 depends on release-readiness and performance-analyst outputs (sequential)
- Story file becomes the PR description body
- PR URL display is mandatory at completion
