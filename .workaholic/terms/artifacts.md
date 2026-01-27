---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-01-27
commit_hash: 82335e6
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# Artifacts

Documentation artifacts generated during development workflows.

## ticket

An implementation work request that captures what should change and records what happened.

### Definition

A ticket defines a discrete unit of work to be implemented. It captures intent, context, and implementation steps before coding begins. Tickets are change-focused, describing what should be different after implementation. They live in `.workaholic/tickets/todo/` when active, `.workaholic/tickets/icebox/` when deferred, and `.workaholic/tickets/archive/<branch>/` when completed.

Tickets include YAML frontmatter with structured metadata:

- `created_at`: Creation timestamp (ISO 8601 datetime)
- `author`: Git email of the creator
- `type`: enhancement, bugfix, refactoring, or housekeeping
- `layer`: Architectural layers affected (UX, Domain, Infrastructure, DB, Config)
- `effort`: Time spent on implementation (filled after completion)
- `commit_hash`: Short git hash (set by archive script after commit)
- `category`: Added, Changed, or Removed (set by archive script based on commit message)

Ticket files created by `/ticket` are automatically included in `/drive` commits via `git add -A`. When archived, the ticket becomes the single source of truth for change metadata, eliminating the need for separate changelog files.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/todo/`, `.workaholic/tickets/icebox/`, `.workaholic/tickets/archive/`
- **File names**: `20260123-123456-feature-name.md` (timestamp-prefixed)
- **Code references**: "Create a ticket with `/ticket`", "Archive the ticket"

### Related Terms

- spec, story

## spec

Current state documentation that provides an authoritative reference snapshot.

### Definition

Specs document the present reality of the codebase. Unlike tickets (which describe changes), specs describe what exists now. They are updated via the spec-writer subagent (invoked by `/report`) to reflect the current state after changes are made. Specs reduce cognitive load by providing a single source of truth.

### Usage Patterns

- **Directory names**: `.workaholic/specs/`
- **File names**: `architecture.md`, `api-reference.md`
- **Code references**: "Check the spec for...", "Update specs to reflect..."

### Related Terms

- ticket, story

### Inconsistencies

- The `/ticket` command description mentions "implementation spec" which conflates ticket and spec terminology

## story

A comprehensive document that serves as the single source of truth for PR descriptions.

### Definition

A story synthesizes the motivation, progression, and outcome of development work across multiple tickets on a single branch. Stories are generated during the PR workflow and contain the complete PR description content across 11 sections: Summary (with overview paragraph), Motivation, Journey (with embedded Topic Tree flowchart), Changes (with categorized subsections), Outcome, Performance (with embedded metrics), Decisions (key architectural choices), Risks (trade-offs and mitigations), Release Preparation (releasability verdict and instructions), and Notes. The story content (minus YAML frontmatter) is copied directly to GitHub as the PR body.

Stories gather data directly from archived tickets, extracting frontmatter fields (`commit_hash`, `category`) and content sections (Overview, Final Report) to build the narrative.

### Usage Patterns

- **Directory names**: `.workaholic/stories/`
- **File names**: `<branch-name>.md`
- **Code references**: "The branch story captures...", "Story is copied to PR..."

### Related Terms

- ticket

## changelog

The root CHANGELOG.md file that aggregates all historical changes.

### Definition

The root `CHANGELOG.md` maintains a historical record of all changes across all branches. Entries are generated from archived tickets during PR creation. Each entry includes a commit hash, brief description, and link to the originating ticket. Branch changelogs (`.workaholic/changelogs/`) no longer exist; tickets serve as the single source of truth for change metadata.

### Usage Patterns

- **File names**: Root `CHANGELOG.md` only
- **Code references**: "CHANGELOG entries", "Update root CHANGELOG"

### Related Terms

- ticket, story

## journey

A narrative section in a story that summarizes the development progression and decision-making.

### Definition

The journey is section 3 of a story document that provides a high-level narrative of how development progressed. It focuses on phases and pivots rather than individual ticket details, typically 100-200 words. The journey answers "how did we get here?" while the Changes section (section 4) provides the detailed "what changed?". The Topic Tree flowchart is embedded at the beginning of the Journey section, providing a visual overview that complements the narrative.

Note: Stories now have 11 sections total (Summary, Motivation, Journey, Changes, Outcome, Performance, Decisions, Risks, Release Preparation, Notes) but the Journey section remains at position 3.

### Usage Patterns

- **Directory names**: N/A (section within story files)
- **File names**: Appears in `.workaholic/stories/<branch-name>.md`
- **Code references**: "The Journey section describes...", "Keep Journey summarized"

### Related Terms

- story, topic-tree, changes

## topic-tree

A visual flowchart diagram showing the structure and progression of changes in a story.

### Definition

The topic tree is a Mermaid flowchart embedded within the Journey section (section 3) of a story that provides a visual overview of how tickets relate to each other. It groups tickets by concern/purpose using subgraphs, shows decision-making progression with arrows, and helps PR reviewers quickly understand the scope and structure of changes before reading the narrative text.

Format:
```mermaid
flowchart LR
  subgraph ConcernA[First Concern]
    t1[Ticket 1] --> t2[Ticket 2]
  end
  subgraph ConcernB[Second Concern]
    t3[Ticket 3] & t4[Ticket 4]
  end
  ConcernA --> ConcernB
```

The flowchart uses left-to-right layout (`flowchart LR`) with subgraphs representing concerns or themes. Arrows indicate decision progression (A led to B), while `&` syntax shows parallel/independent work.

### Usage Patterns

- **Directory names**: N/A (content within story files)
- **File names**: Appears in `.workaholic/stories/<branch-name>.md`
- **Code references**: "Generate topic tree for the story", "The topic tree shows..."

### Related Terms

- story, ticket, Mermaid

## changes

A detailed section in a story that lists every ticket/commit with its description.

### Definition

The changes section is section 4 of a story document that provides a comprehensive list of all changes made during the branch's development. Unlike the Journey section (which provides a summarized narrative), Changes lists one subsection per ticket/commit in the format: `### 4.N. <Ticket title> ([hash](commit-url))`. Each subsection contains a brief 1-2 sentence description from the ticket's Overview, serving as the detailed "what changed?" companion to Journey's "how did we get here?"

### Usage Patterns

- **Directory names**: N/A (section within story files)
- **File names**: Appears in `.workaholic/stories/<branch-name>.md`
- **Code references**: "The Changes section lists...", "One subsection per ticket in Changes"

### Related Terms

- story, journey, ticket, commit
