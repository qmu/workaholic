---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-01-28
commit_hash: fe3d558
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

Mark a ticket as failed and move it to the fail directory without committing implementation changes.

### Definition

Abandon is one of four approval options presented during `/drive` workflow when a developer completes a ticket implementation. When selected, abandon discards any uncommitted implementation changes (via `git restore .`), requires a Failure Analysis section to be appended to the ticket documenting what was attempted and why it failed, moves the ticket to `.workaholic/tickets/fail/`, commits the ticket move to preserve the analysis, and continues to the next ticket. This provides a graceful way to handle tickets that were fundamentally flawed or whose implementation proved unworkable.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/fail/`
- **File names**: Abandoned tickets retain original names in fail directory
- **Code references**: "Select Abandon during approval", "Ticket was abandoned in the fail directory"

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

Sync operations update derived documentation (specs, terms) to reflect the current codebase state. Unlike commits that record changes, syncs ensure documentation accuracy. The `/report` command automatically synchronizes the `.workaholic/` directory (specs and terms) with the current codebase via spec-writer and terms-writer subagents.

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

## report

Generate comprehensive documentation and create or update a GitHub PR.

### Definition

The report operation orchestrates multiple documentation agents concurrently to generate all artifacts (changelog, story, specs, terms), then creates or updates a GitHub pull request. This is the primary command for completing a feature branch and preparing it for review. The command `/report` replaced the earlier `/pull-request` command to better reflect that documentation generation is its primary purpose, with PR creation as the final step.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Run `/report` to create PR", "Report generates documentation"

### Related Terms

- story, changelog, spec, terms, agent, orchestrator

## concurrent-execution

Run multiple independent agents simultaneously for improved performance.

### Definition

Concurrent execution is a pattern where multiple agents are invoked in parallel when they write to different locations and have no dependencies on each other. The orchestrating command sends multiple Task tool invocations in a single message, allowing agents to work simultaneously. This significantly reduces total execution time compared to sequential processing.

Examples of concurrent execution:
- `/report` uses two-phase execution:
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
- **Abandon**: Discard implementation changes, append Failure Analysis, move ticket to fail directory, continue to next ticket

This gate ensures that only successfully implemented tickets are committed to history, while failed attempts are preserved in the fail directory with their analysis for future reference.

### Usage Patterns

- **Directory names**: N/A (workflow step, not storage)
- **File names**: N/A
- **Code references**: "Select Approve during approval", "The approval prompt offers...", "Approval options are..."

### Related Terms

- drive, ticket, abandon, commit

## release-readiness

Assess whether a branch is ready for release.

### Definition

Release readiness is a pre-release analysis that evaluates whether changes in a branch are suitable for immediate release. The release-readiness subagent runs during `/report` alongside other documentation agents and produces a verdict (ready/needs attention) with concerns and instructions. This helps maintainers understand what pre-release or post-release steps may be needed.

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
