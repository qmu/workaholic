---
name: gather-ticket-metadata
description: Gather ticket metadata in one call.
allowed-tools: Bash
user-invocable: false
---

# Gather Ticket Metadata

Gathers all dynamic metadata values needed for ticket frontmatter in a single shell script call.

## Usage

```bash
bash .claude/skills/gather-ticket-metadata/sh/gather.sh
```

## Output

JSON with all metadata values:

```json
{
  "created_at": "2026-01-31T19:25:46+09:00",
  "author": "developer@company.com",
  "filename_timestamp": "20260131192546"
}
```

## Fields

- **created_at**: ISO 8601 timestamp with timezone for frontmatter
- **author**: Git user email from repository config
- **filename_timestamp**: Timestamp for ticket filename (YYYYMMDDHHmmss format)
