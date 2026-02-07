---
title: Component Viewpoint
description: Internal structure, module boundaries, and decomposition
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](component.md) | [Japanese](component_ja.md)

# 1. Component Viewpoint

The Component Viewpoint describes the internal structure of the Workaholic plugin, its module boundaries, and how the system decomposes into commands, agents, skills, and rules. The core plugin contains 4 commands, 30 agents, 28 skills, and 6 rules, organized in a strict hierarchical architecture.

## 2. Component Hierarchy

### 2-1. Commands (4)

Commands are the user-facing entry points. Each is a thin orchestration layer.

| Command | File | Primary Subagent |
| --- | --- | --- |
| `/ticket` | `drive.md` | ticket-organizer |
| `/drive` | `drive.md` | drive-navigator |
| `/scan` | `scan.md` | scanner |
| `/report` | `report.md` | story-writer |

### 2-2. Agents (30)

Agents are grouped by their primary purpose:

**Ticket Management:**
- `ticket-organizer` -- Orchestrates ticket creation with parallel discovery
- `ticket-discoverer` -- Finds existing tickets to detect duplicates
- `drive-navigator` -- Prioritizes and orders tickets for implementation

**Documentation Generation (Scan):**
- `scanner` -- Orchestrates all 17 documentation agents
- `stakeholder-analyst`, `model-analyst`, `usecase-analyst`, `infrastructure-analyst`, `application-analyst`, `component-analyst`, `data-analyst`, `feature-analyst` -- 8 viewpoint spec writers
- `test-policy-analyst`, `security-policy-analyst`, `quality-policy-analyst`, `accessibility-policy-analyst`, `observability-policy-analyst`, `delivery-policy-analyst`, `recovery-policy-analyst` -- 7 policy writers
- `changelog-writer` -- Updates CHANGELOG.md from archived tickets
- `terms-writer` -- Updates term definitions

**Report Generation:**
- `story-writer` -- Generates development narrative and PR
- `overview-writer` -- Prepares story overview content
- `performance-analyst` -- Evaluates decision-making quality
- `section-reviewer` -- Reviews story sections 5-8
- `pr-creator` -- Creates or updates GitHub pull request
- `release-note-writer` -- Generates release notes
- `release-readiness` -- Assesses release preparedness

**Discovery:**
- `source-discoverer` -- Explores codebase structure
- `history-discoverer` -- Finds related historical tickets

### 2-3. Skills (28)

Skills are the knowledge layer, organized by domain:

**Analysis:** `analyze-performance`, `analyze-policy`, `analyze-viewpoint`
**Ticket Operations:** `archive-ticket`, `create-ticket`, `discover-ticket`, `discover-history`, `discover-source`, `update-ticket-frontmatter`
**Git Operations:** `commit`, `create-pr`, `gather-git-context`, `manage-branch`
**Documentation:** `write-changelog`, `write-final-report`, `write-overview`, `write-release-note`, `write-spec`, `write-story`, `write-terms`
**Workflow:** `drive-approval`, `drive-workflow`, `format-commit-message`, `gather-ticket-metadata`
**Quality:** `review-sections`, `validate-writer-output`
**i18n:** `translate`
**Release:** `assess-release-readiness`

Each skill directory contains a `SKILL.md` file and optionally an `sh/` directory with shell scripts.

### 2-4. Rules (6)

| Rule | Path Pattern | Purpose |
| --- | --- | --- |
| `general.md` | `**/*` | Commit policy, git rules, heading numbering |
| `diagrams.md` | Path-specific | Mermaid diagram requirements |
| `i18n.md` | Path-specific | Internationalization policy |
| `shell.md` | Path-specific | Shell scripting standards |
| `typescript.md` | Path-specific | TypeScript conventions |
| `workaholic.md` | Path-specific | .workaholic/ directory conventions |

### 2-5. Hooks (1)

A single PostToolUse hook validates ticket frontmatter on every Write or Edit operation, running `validate-ticket.sh` with a 10-second timeout.

## 3. Module Boundaries

The architecture enforces strict boundaries through the nesting policy:

| Caller | Can invoke | Cannot invoke |
| --- | --- | --- |
| Command | Skill, Subagent | -- |
| Subagent | Skill, Subagent | Command |
| Skill | Skill | Subagent, Command |

This creates a layered dependency graph where knowledge flows upward (skills are loaded by agents and commands) while control flows downward (commands invoke agents which invoke skills). Shell scripts are always bundled within skills and never written inline in agent or command markdown files.

## 4. Diagram

```mermaid
flowchart TD
    subgraph Commands
        ticket[/ticket]
        drive[/drive]
        scan[/scan]
        report[/report]
    end

    subgraph Agents
        TO[ticket-organizer]
        DN[drive-navigator]
        SC[scanner]
        SW[story-writer]
        VA[8 viewpoint analysts]
        PA[7 policy analysts]
        CW[changelog-writer]
        TW[terms-writer]
    end

    subgraph Skills
        DW[drive-workflow]
        DA[drive-approval]
        AV[analyze-viewpoint]
        AP[analyze-policy]
        WS[write-spec]
        WT[write-terms]
        WC[write-changelog]
        VW[validate-writer-output]
    end

    ticket --> TO
    drive --> DN
    scan --> SC
    report --> SW
    SC --> VA
    SC --> PA
    SC --> CW
    SC --> TW
    VA --> AV
    VA --> WS
    PA --> AP
    CW --> WC
    TW --> WT
    SC --> VW
```

## 5. Assumptions

- [Explicit] The component counts (4 commands, 30 agents, 28 skills, 6 rules) are derived from the filesystem listing.
- [Explicit] The nesting policy table is defined in `CLAUDE.md`.
- [Explicit] Shell scripts must be bundled in skills, never inline, as stated in `CLAUDE.md`'s "Shell Script Principle".
- [Inferred] The large number of specialized agents (30) compared to commands (4) reflects a design where each command fans out into many focused single-purpose agents, prioritizing separation of concerns over minimizing agent count.
- [Inferred] The single-plugin architecture (only `core`) suggests the marketplace infrastructure is designed for future multi-plugin expansion that has not yet occurred.
