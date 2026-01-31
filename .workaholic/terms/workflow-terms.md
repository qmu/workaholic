---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-01-31
commit_hash: 06ebf65
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# Workflow Terms

Actions and operations in the development workflow.

## drive

Implement queued tickets one by one, committing each.

### Definition

The drive operation processes tickets from `.workaholic/tickets/todo/` sequentially. For each ticket, it implements the described changes, commits the work, and archives the ticket. This creates a structured development flow where work is captured before implementation and documented after completion.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Run `/drive` to implement", "Drive through the tickets"

### Related Terms

- ticket, archive, commit

## abandon

Mark a ticket as abandoned and move it to the abandoned directory without committing implementation changes.

### Definition

Abandon is one of four approval options presented during `/drive` workflow when a developer completes a ticket implementation. When selected, abandon discards any uncommitted implementation changes (via `git restore .`), requires a Failure Analysis section to be appended to the ticket documenting what was attempted and why it failed, moves the ticket to `.workaholic/tickets/abandoned/`, commits the ticket move to preserve the analysis, and continues to the next ticket. This provides a graceful way to handle tickets that were fundamentally flawed or whose implementation proved unworkable.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/abandoned/`
- **File names**: Abandoned tickets retain original names in abandoned directory
- **Code references**: "Select Abandon during approval", "Ticket was abandoned"

### Related Terms

- ticket, failure-analysis, drive, approval

## archive

Move completed work to long-term storage.

### Definition

Archiving moves completed tickets from the active queue (`.workaholic/tickets/todo/`) to branch-specific archive directories (`.workaholic/tickets/archive/<branch>/`). This preserves the implementation record while clearing the active queue. The archive-ticket skill handles this automatically after successful commits.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/archive/`, `.workaholic/tickets/archive/<branch>/`
- **File names**: Archived tickets retain original names
- **Code references**: "Archive the ticket", "Check archived tickets"

### Related Terms

- ticket, drive, icebox

## sync

Update documentation to match the current state.

### Definition

Sync operations update derived documentation (specs, terms) to reflect the current codebase state. Unlike commits that record changes, syncs ensure documentation accuracy. The `/story` command automatically synchronizes the `.workaholic/` directory (specs and terms) with the current codebase via spec-writer and terms-writer subagents.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Sync the docs", "Documentation is synced during /report"

### Related Terms

- spec, terms

## release

Publish a new marketplace version.

### Definition

A release increments the marketplace version, updates version metadata, and publishes the changes. The `/release` command supports major, minor, and patch version increments following semantic versioning. Releases update `.claude-plugin/marketplace.json` and create appropriate git tags.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: `.claude-plugin/marketplace.json`, `CHANGELOG.md`
- **Code references**: "Create a release", "Run `/release patch`"

### Related Terms

- changelog, plugin

## story

Generate comprehensive documentation and create or update a GitHub PR.

### Definition

The story operation orchestrates multiple documentation agents concurrently to generate all artifacts (changelog, story, specs, terms), then creates or updates a GitHub pull request. This is the primary command for completing a feature branch and preparing it for review. The command `/story` replaced the earlier `/report` command to better reflect its primary output: a comprehensive story document that synthesizes the implementation narrative, decision-making process, and development journey.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Run `/story` to create PR", "Story generates documentation"

### Related Terms

- changelog, spec, terms, agent, orchestrator

## report (Deprecated)

Previous name for the `/story` command. See `story` for current definition.

### Definition

`/report` was renamed to `/story` to better reflect its primary output. The functionality remains the same - orchestrating documentation generation and PR creation - but the name now emphasizes the story document as the central artifact.

### Related Terms

- story

## workflow

An automated sequence of steps triggered by events or manual dispatch.

### Definition

In the context of Workaholic, workflow refers to GitHub Actions workflows (YAML files in `.github/workflows/`) that automate release processes and other CI/CD tasks. Workflows are triggered either manually via `workflow_dispatch` or automatically on events like tag pushes. The release workflow automates version bumping, changelog extraction, and GitHub Release creation, replacing manual `/release` command execution.

### Usage Patterns

- **Directory names**: `.github/workflows/`
- **File names**: `release.yml`, `test.yml`
- **Code references**: "Trigger the release workflow", "Workflow automates version bumping"

### Related Terms

- release, GitHub Actions

## concurrent-execution

Run multiple independent agents simultaneously for improved performance.

### Definition

Concurrent execution is a pattern where multiple agents are invoked in parallel when they write to different locations and have no dependencies on each other. The orchestrating command sends multiple Task tool invocations in a single message, allowing agents to work simultaneously. This significantly reduces total execution time compared to sequential processing.

Examples of concurrent execution:
- `/story` uses two-phase execution:
  - Phase 1: changelog-writer, spec-writer, terms-writer, and release-readiness run concurrently
  - Phase 2: story-writer runs with release-readiness output as input

Sequential execution is still required when outputs depend on prior results (e.g., story-writer needs release-readiness output, pr-creator runs after story-writer because it reads the story file).

### Usage Patterns

- **Directory names**: N/A (pattern, not storage)
- **File names**: N/A
- **Code references**: "Run agents concurrently", "Invoke in parallel", "Execute simultaneously"

### Related Terms

- agent, orchestrator, Task tool

## approval

A step in the drive workflow where the developer confirms or rejects implementation.

### Definition

Approval is a decision point in the `/drive` workflow that occurs after a ticket has been implemented and before it is committed. The workflow presents four options to the developer:
- **Approve**: Commit the implementation and continue to next ticket
- **Approve and stop**: Commit the implementation and stop driving
- **Needs changes**: Request modifications (discards uncommitted changes, keeps ticket in todo, asks for feedback)
- **Abandon**: Discard implementation changes, append Failure Analysis, move ticket to abandoned directory, continue to next ticket

This gate ensures that only successfully implemented tickets are committed to history, while failed attempts are preserved in the abandoned directory with their analysis for future reference.

### Usage Patterns

- **Directory names**: N/A (workflow step, not storage)
- **File names**: N/A
- **Code references**: "Select Approve during approval", "The approval prompt offers...", "Approval options are..."

### Related Terms

- drive, ticket, abandon, commit

## release-readiness

Assess whether a branch is ready for release.

### Definition

Release readiness is a pre-release analysis that evaluates whether changes in a branch are suitable for immediate release. The release-readiness subagent runs during `/story` alongside other documentation agents and produces a verdict (ready/needs attention) with concerns and instructions. This helps maintainers understand what pre-release or post-release steps may be needed.

The analysis considers:
- Breaking changes (API or configuration changes)
- Incomplete work (TODO/FIXME comments)
- Test status (if tests exist)
- Security concerns (secrets, credentials)

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: Output appears in story's Release Preparation section
- **Code references**: "Check release readiness", "The release-readiness agent evaluates..."

### Related Terms

- release, story, agent

## prioritization

Intelligent ordering of tickets based on severity, context, and effort.

### Definition

Prioritization is the process of analyzing ticket metadata (type, layer, effort) and ordering tickets for optimal execution. During `/drive`, Claude Code analyzes tickets in the todo queue and determines a recommended execution order based on severity (bugfixes > enhancements > refactoring > housekeeping), context grouping (tickets affecting the same layers are processed together), and effort estimates. Users see the proposed order before starting and can accept, override, or pick individual tickets. This replaces simple alphabetical listing with intelligent processing that reduces context switching and maximizes efficiency.

### Usage Patterns

- **Directory names**: N/A (operation, not storage)
- **File names**: Logic in `plugins/core/commands/drive.md`
- **Code references**: "Prioritize the tickets", "Proposed priority order", "Context grouping for prioritization"

### Related Terms

- drive, ticket, context-grouping, severity

## context-grouping

Processing tickets that affect the same architectural layers together to minimize context switching.

### Definition

Context grouping is an optimization strategy used during ticket prioritization. Tickets that modify files in the same architectural layers (e.g., Config, Infrastructure, Domain) are grouped and processed sequentially to reduce cognitive load and context switching overhead. This improves efficiency by allowing developers to maintain focus on a specific area of the codebase rather than jumping between unrelated layers.

### Usage Patterns

- **Directory names**: N/A (strategy, not storage)
- **File names**: Referenced in ticket layer metadata
- **Code references**: "Group tickets by context", "Tickets in the same layer", "Minimize context switching"

### Related Terms

- prioritization, ticket, layer

## severity

A ranking system for ticket types: bugfix > enhancement > refactoring > housekeeping.

### Definition

Severity is a prioritization criterion based on the ticket's type field. Bugfixes (addressing broken functionality) take highest priority, followed by enhancements (new features), refactoring (code improvements), and housekeeping (maintenance tasks). This ensures critical issues are resolved first before working on new functionality, maintaining production stability.

### Usage Patterns

- **Directory names**: N/A (ranking, not storage)
- **File names**: Ticket type in frontmatter
- **Code references**: "Severity ranking", "Bugfixes take precedence", "Ordered by severity"

### Related Terms

- prioritization, ticket, type

## structured-commit-message

An enhanced commit message format with title, detail, and categorized change sections.

### Definition

Structured commit messages extend beyond a simple title to include detailed sections that capture the "why" and scope of changes. The format includes: title (present-tense verb, what changed), detail (1-2 sentences explaining why), UX changes (user-facing impacts), and Arch changes (architecture/developer-facing impacts). This structure enables better documentation generation and clearer communication about change impact. Empty sections use "None" instead of being omitted, ensuring consistency.

Format:
```
<title>

<detail>

UX: <ux-changes>
Arch: <arch-changes>

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Usage Patterns

- **Directory names**: N/A (format specification)
- **File names**: Commits created during `/drive` workflow
- **Code references**: "Use structured commit message", "UX and Arch sections", "Commit format includes four parts"

### Related Terms

- commit, archive-ticket, format-commit-message skill

## ux-changes

User-facing impacts and changes documented in a commit message.

### Definition

UX changes are the user-visible or user-experience impacts of an implementation, documented in the "UX:" section of a structured commit message. These describe what users will see or experience differently, including new commands, options, behaviors, output format changes, or error messages. If a commit has no user-facing changes, the field contains "None". This section helps generate user guide updates by clearly identifying user-impacting changes.

### Usage Patterns

- **Directory names**: N/A (commit message section)
- **File names**: Commits during `/drive`
- **Code references**: "Document UX changes", "User-facing impact", "UX section of commit message"

### Related Terms

- structured-commit-message, commit, arch-changes

## arch-changes

Developer-facing and architectural impacts documented in a commit message.

### Definition

Architecture changes are the developer-facing and structural impacts of an implementation, documented in the "Arch:" section of a structured commit message. These describe new files, components, abstractions, modified interfaces, data structures, or workflow relationships. If a commit has no architectural changes, the field contains "None". This section helps generate specification updates by clearly identifying system architecture impacts.

### Usage Patterns

- **Directory names**: N/A (commit message section)
- **File names**: Commits during `/drive`
- **Code references**: "Document architecture changes", "Arch section impact", "Developer-facing changes"

### Related Terms

- structured-commit-message, commit, ux-changes
