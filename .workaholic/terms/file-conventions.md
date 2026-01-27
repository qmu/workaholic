---
title: File Conventions
description: Naming patterns and directory structures used in Workaholic
category: developer
last_updated: 2026-01-27
commit_hash: 921a9a3
---

[English](file-conventions.md) | [日本語](file-conventions_ja.md)

# File Conventions

Naming patterns and directory structures used in Workaholic.

## kebab-case

Lowercase words separated by hyphens for file and directory naming.

### Definition

Kebab-case is the standard naming convention for files and directories in Workaholic. It uses lowercase letters with hyphens separating words (e.g., `ticket.md`, `report.md`). This convention ensures consistency and avoids issues with case-sensitive filesystems.

### Usage Patterns

- **Directory names**: `core-concepts/`, `file-conventions/`
- **File names**: `ticket.md`, `report.md`, `archive-ticket.md`
- **Code references**: "Use kebab-case for file names"

### Exceptions

- `README.md` uses uppercase by convention
- `CHANGELOG.md` uses uppercase by convention
- `CLAUDE.md` uses uppercase by convention

### Related Terms

- frontmatter

## frontmatter

YAML metadata block at the start of markdown files.

### Definition

Frontmatter is a YAML block delimited by `---` at the beginning of markdown files. It contains metadata like title, description, category, last_updated, and commit_hash. All documentation files in `.workaholic/` require frontmatter for consistency and tracking.

### Usage Patterns

- **Directory names**: N/A (file content, not naming)
- **File names**: Present in all `.md` files under `.workaholic/`
- **Code references**: "Add frontmatter to the file", "Update the commit_hash in frontmatter"

### Standard Fields

```yaml
---
title: Document Title
description: Brief description
category: user | developer
last_updated: YYYY-MM-DD
commit_hash: <short-hash>
---
```

### Related Terms

- kebab-case

## todo

Storage for active work items waiting to be implemented.

### Definition

The todo directory holds tickets that are queued for implementation. When a ticket is created via `/ticket`, it is placed in `.workaholic/tickets/todo/`. During `/drive`, tickets are processed from this directory in sorted order (by timestamp prefix). After successful implementation and commit, tickets move from todo to archive.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/todo/`
- **File names**: Tickets retain original names with timestamp prefix
- **Code references**: "Queue in todo", "Process tickets from todo"

### Related Terms

- icebox, archive, ticket

## icebox

Storage for deferred work items.

### Definition

The icebox holds tickets that are not currently being worked on but should be preserved for future consideration. When creating a PR, unfinished tickets are moved from `.workaholic/tickets/todo/` to `.workaholic/tickets/icebox/` rather than being deleted. This prevents loss of planned work while clearing the active queue.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/icebox/`
- **File names**: Iceboxed tickets retain original names
- **Code references**: "Move to icebox", "Check the icebox for..."

### Related Terms

- archive, ticket

## archive

Storage for completed work items.

### Definition

In the context of file conventions, archive directories store completed tickets organized by branch name. The path `.workaholic/tickets/archive/<branch>/` contains all tickets that were implemented during work on that branch. Archives provide historical context for understanding past development.

### Usage Patterns

- **Directory names**: `.workaholic/tickets/archive/`, `.workaholic/tickets/archive/<branch>/`
- **File names**: Archived files retain original names
- **Code references**: "Check the archive", "Read archived tickets"

### Related Terms

- icebox, ticket
