---
title: Artifacts
description: Documentation artifacts generated during development workflows
category: developer
last_updated: 2026-01-23
commit_hash: a0b2b29
---

[English](artifacts.md) | [日本語](artifacts_ja.md)

# Artifacts

Documentation artifacts generated during development workflows.

## ticket

An implementation work request that captures what should change.

### Definition

A ticket defines a discrete unit of work to be implemented. It captures intent, context, and implementation steps before coding begins. Tickets are change-focused, describing what should be different after implementation. They live in `.work/tickets/` when active, `.work/tickets/icebox/` when deferred, and `.work/tickets/archive/<branch>/` when completed.

### Usage Patterns

- **Directory names**: `.work/tickets/`, `.work/tickets/archive/`
- **File names**: `20260123-123456-feature-name.md` (timestamp-prefixed)
- **Code references**: "Create a ticket with `/ticket`", "Archive the ticket"

### Related Terms

- spec, story, changelog

## spec

Current state documentation that provides an authoritative reference snapshot.

### Definition

Specs document the present reality of the codebase. Unlike tickets (which describe changes), specs describe what exists now. They are updated via `/sync-doc-specs` to reflect the current state after changes are made. Specs reduce cognitive load by providing a single source of truth.

### Usage Patterns

- **Directory names**: `.work/specs/`
- **File names**: `architecture.md`, `api-reference.md`
- **Code references**: "Check the spec for...", "Update specs to reflect..."

### Related Terms

- ticket, story

### Inconsistencies

- The `/ticket` command description mentions "implementation spec" which conflates ticket and spec terminology

## story

A development narrative that captures the journey of work on a branch.

### Definition

A story synthesizes the motivation, progression, and outcome of development work across multiple tickets on a single branch. Stories are generated during the PR workflow and include performance metrics. They help future developers understand not just what was built, but why and how decisions were made.

### Usage Patterns

- **Directory names**: `.work/stories/`
- **File names**: `<branch-name>.md`
- **Code references**: "The branch story captures...", "Story metrics show..."

### Related Terms

- ticket, changelog

## changelog

A commit-level record of changes explaining what changed and why.

### Definition

Changelogs maintain a historical record of changes per branch and aggregated at the root. Each entry includes a commit hash, brief description, and link to the originating ticket. Branch changelogs live in `.work/changelogs/<branch>.md` and are consolidated to `CHANGELOG.md` during PR creation.

### Usage Patterns

- **Directory names**: `.work/changelogs/`
- **File names**: `<branch-name>.md`, root `CHANGELOG.md`
- **Code references**: "Add to changelog", "CHANGELOG entries"

### Related Terms

- ticket, story
