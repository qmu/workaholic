---
title: Inconsistencies
description: Known terminology issues and potential resolutions
category: developer
last_updated: 2026-01-24
commit_hash: 6843f78
---

[English](inconsistencies.md) | [日本語](inconsistencies_ja.md)

# Inconsistencies

Known terminology issues and potential resolutions.

## "Spec" Terminology Overload

### Issue

The `/ticket` command description uses "implementation spec" to describe tickets, but "spec" has a distinct meaning in Workaholic (current state documentation in `.work/specs/`).

### Current Usage

- `/ticket` description: "Explore codebase and write implementation ticket"
- But historically referred to as "implementation spec" in some contexts
- `.work/specs/` contains current state documentation, not implementation plans

### Recommended Resolution

Consistently use "ticket" for implementation work requests and "spec" only for current state documentation. Update any remaining references to "implementation spec" to use "ticket" instead.

## Legacy "doc-specs" References

### Issue

Historical documentation may reference `/sync-doc-specs` which was renamed to `/sync-src-doc`.

### Current Usage

- Current command name: `sync-src-doc`
- Historical name: `sync-doc-specs`
- Targets: `.work/specs/` and `.work/terminology/`

### Recommended Resolution

Update any remaining references from `/sync-doc-specs` to `/sync-src-doc`. The new name better reflects the command's purpose: syncing source code to documentation.

## Historical `doc/` vs `.work/` Directory References

### Issue

Older documentation or comments may reference a `doc/` directory that was renamed to `.work/` in the current structure.

### Current Usage

- Current: `.work/` contains all working artifacts
- Historical: `doc/` may appear in older commits or external references

### Recommended Resolution

Ensure all current documentation references `.work/` consistently. When encountering `doc/` references, update them to `.work/`.

## "Archive" Dual Meaning

### Issue

"Archive" is used both as a verb (the action of archiving) and as a noun (the archive directory), which is standard but can cause confusion in instructions.

### Current Usage

- Verb: "Archive the ticket after completion"
- Noun: "Check the archive for previous tickets"
- Directory: `.work/tickets/archive/`

### Recommended Resolution

This is standard English usage and acceptable. When clarity is needed, prefer "archive directory" for the noun form and "archive" (verb) for the action.

## Legacy "TDD Plugin" References

### Issue

Historical documentation may reference a separate "TDD plugin" (`plugins/tdd/`) that has been merged into the core plugin.

### Current Usage

- Current: All commands, skills, and rules are in `plugins/core/`
- Historical: Some docs may reference `plugins/tdd/` or "TDD plugin"

### Recommended Resolution

Update any remaining references to the TDD plugin to refer to the core plugin instead. The ticket-driven development commands (`/ticket`, `/drive`, `/sync-src-doc`) are now part of the unified core plugin.
