---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-01-27
commit_hash: f034f63
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# Workflow Terms

Actions and operations in the development workflow.

## drive

Implement queued tickets one by one, committing each.

### Definition

The drive operation processes tickets from `.workaholic/tickets/` sequentially. For each ticket, it implements the described changes, commits the work, and archives the ticket. This creates a structured development flow where work is captured before implementation and documented after completion.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Run `/drive` to implement", "Drive through the tickets"

### Related Terms

- ticket, archive, commit

## archive

Move completed work to long-term storage.

### Definition

Archiving moves completed tickets from the active queue (`.workaholic/tickets/`) to branch-specific archive directories (`.workaholic/tickets/archive/<branch>/`). This preserves the implementation record while clearing the active queue. The archive-ticket skill handles this automatically after successful commits.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/archive/`, `.workaholic/tickets/archive/<branch>/`
- **File names**: Archived tickets retain original names
- **Code references**: "Archive the ticket", "Check archived tickets"

### Related Terms

- ticket, drive, icebox

## sync

Update documentation to match the current state.

### Definition

Sync operations update derived documentation (specs, terms) to reflect the current codebase state. Unlike commits that record changes, syncs ensure documentation accuracy. The `/pull-request` command automatically synchronizes the `.workaholic/` directory (specs and terms) with the current codebase via spec-writer and terms-writer subagents.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Sync the docs", "Documentation is synced during /pull-request"

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

## concurrent-execution

Run multiple independent agents simultaneously for improved performance.

### Definition

Concurrent execution is a pattern where multiple agents are invoked in parallel when they write to different locations and have no dependencies on each other. The orchestrating command sends multiple Task tool invocations in a single message, allowing agents to work simultaneously. This significantly reduces total execution time compared to sequential processing.

Examples of concurrent execution:
- `/pull-request` runs changelog-writer, story-writer, spec-writer, terms-writer concurrently

Sequential execution is still required when outputs depend on prior results (e.g., pr-creator runs after story-writer because it reads the story file).

### Usage Patterns

- **Directory names**: N/A (pattern, not storage)
- **File names**: N/A
- **Code references**: "Run agents concurrently", "Invoke in parallel", "Execute simultaneously"

### Related Terms

- agent, orchestrator, Task tool
