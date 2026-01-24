---
title: Workflow Terms
description: Actions and operations in the development workflow
category: developer
last_updated: 2026-01-24
commit_hash: 5275c02
---

[English](workflow-terms.md) | [日本語](workflow-terms_ja.md)

# Workflow Terms

Actions and operations in the development workflow.

## drive

Implement queued tickets one by one, committing each.

### Definition

The drive operation processes tickets from `.work/tickets/` sequentially. For each ticket, it implements the described changes, commits the work, and archives the ticket. This creates a structured development flow where work is captured before implementation and documented after completion.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Run `/drive` to implement", "Drive through the tickets"

### Related Terms

- ticket, archive, commit

## archive

Move completed work to long-term storage.

### Definition

Archiving moves completed tickets from the active queue (`.work/tickets/`) to branch-specific archive directories (`.work/tickets/archive/<branch>/`). This preserves the implementation record while clearing the active queue. The archive-ticket skill handles this automatically after successful commits.

### Usage Patterns

- **Directory names**: `.work/tickets/archive/`, `.work/tickets/archive/<branch>/`
- **File names**: Archived tickets retain original names
- **Code references**: "Archive the ticket", "Check archived tickets"

### Related Terms

- ticket, drive, icebox

## sync

Update documentation to match the current state.

### Definition

Sync operations update derived documentation (specs, terminology) to reflect the current codebase state. Unlike commits that record changes, syncs ensure documentation accuracy. The `/sync-doc-specs` and `/sync-terminology` commands perform different sync operations.

### Usage Patterns

- **Directory names**: N/A (action, not storage)
- **File names**: N/A
- **Code references**: "Sync the specs", "Run `/sync-doc-specs`"

### Related Terms

- spec, terminology

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
