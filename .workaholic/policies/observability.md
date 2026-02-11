---
title: Observability Policy
description: Logging, monitoring, metrics, and tracing practices
category: developer
modified_at: 2026-02-12T00:20:11+09:00
commit_hash: f7f779f
---

[English](observability.md) | [Japanese](observability_ja.md)

# Observability Policy

This document describes the observability practices in the Workaholic repository. Workaholic implements observability through development narrative generation, performance metrics, and audit trails rather than traditional application monitoring.

## Logging Practices

### Error Handling

All shell scripts use `set -eu` for strict error handling, causing immediate exit on undefined variables or command failures (implementation: all 19 shell scripts in `plugins/core/skills/*/sh/*.sh` and `plugins/core/hooks/validate-ticket.sh`).

Shell scripts output validation errors to stderr with descriptive messages and exit code 2 to block operations (implementation: `plugins/core/hooks/validate-ticket.sh` lines 39-42, 50-53, 66-68, 86-94).

### Validation Logging

The ticket validation hook logs structured error messages with field names, invalid values, and references to authoritative documentation (implementation: `plugins/core/hooks/validate-ticket.sh` function `print_skill_reference()` and validation blocks for `created_at`, `author`, `type`, `layer`, `effort`, `commit_hash`, and `category`).

CI validation workflows log JSON validation results and required field checks to GitHub Actions output (implementation: `.github/workflows/validate-plugins.yml` steps "Validate marketplace.json", "Validate plugin.json files", "Check skill files exist").

### Session Context

Claude Code conversation context serves as the implicit log of operations during a session. No structured logging to files or external systems is implemented.

## Metrics Collection

### Performance Metrics

The `analyze-performance` skill calculates development velocity metrics from git history (implementation: `plugins/core/skills/analyze-performance/sh/calculate.sh`):

- Commit count between base branch and HEAD
- Start and end timestamps (ISO 8601)
- Duration in hours and days
- Velocity in commits per hour or commits per day
- Business day calculations for multi-day work

These metrics are included in story frontmatter (implementation: `plugins/core/skills/write-story/SKILL.md` lines 206-219).

### Story Metrics

Story documents include structured frontmatter with observable metadata (implementation: `plugins/core/skills/write-story/SKILL.md`):

- `branch`: Branch name
- `started_at`: First commit timestamp
- `ended_at`: Last commit timestamp
- `tickets_completed`: Count of archived tickets
- `commits`: Total commit count
- `duration_hours`: Elapsed time in hours
- `duration_days`: Calendar days with commits
- `velocity`: Commits per time unit
- `velocity_unit`: "hour" or "day"

### Ticket Metrics

Ticket frontmatter tracks effort estimation (implementation: `plugins/core/skills/create-ticket/SKILL.md` lines 174-178):

- `effort`: Time spent in hours (0.1h, 0.25h, 0.5h, 1h, 2h, 4h)
- `commit_hash`: Git commit implementing the ticket
- `category`: Changelog category (Added, Changed, Removed)

## Tracing and Monitoring

### Ticket Traceability

Every implementation is traceable through the ticket lifecycle (implementation: `plugins/core/skills/archive-ticket/SKILL.md`):

1. Creation in `.workaholic/tickets/todo/` with `created_at` and `author` metadata
2. Implementation during `/drive` command execution
3. Frontmatter update with `effort`, `commit_hash`, and `category`
4. Archival to `.workaholic/tickets/archive/<branch>/`
5. Changelog entry linking ticket path to commit URL

### Concerns Traceability

Ticket concerns sections use commit hash and file path references (implementation: `plugins/core/skills/create-ticket/SKILL.md` Considerations format):

```
- <description> (see [hash](<repo-url>/commit/<hash>) in path/to/file.ext)
```

Story concerns sections extract these references from tickets (implementation: `plugins/core/skills/review-sections/SKILL.md` line 44, `plugins/core/skills/write-story/SKILL.md` lines 113-125).

### Changelog Audit Trail

The changelog provides a categorized audit trail of all changes (implementation: `plugins/core/skills/write-changelog/sh/generate.sh`):

- Groups entries by category: Added, Changed, Removed
- Links each entry to GitHub commit URL
- Links each entry to archived ticket file
- Organizes by branch with optional issue number linking

### Historical Context Tracing

The `discover-history` skill searches previous tickets for related work (implementation: `plugins/core/skills/discover-history/SKILL.md`), enabling stories to include historical analysis sections that reference past decisions and patterns.

### Frontmatter-Based Tracking

All documentation files in `.workaholic/` include YAML frontmatter with `commit_hash` fields linking content to specific git revisions (implementation: `plugins/core/skills/write-spec/SKILL.md` lines 84-91, `plugins/core/skills/write-terms/SKILL.md` lines 80-85, `plugins/core/skills/analyze-policy/SKILL.md` lines 77-89).

## Alerting

### CI Validation Alerts

GitHub Actions workflows fail and notify on validation errors (implementation: `.github/workflows/validate-plugins.yml`):

- Invalid JSON in marketplace or plugin manifests
- Missing required fields in plugin.json
- Missing skill files referenced in manifests
- Mismatched plugin directories and marketplace entries

### Git Hook Alerts

The ticket validation hook blocks Write and Edit operations with exit code 2 and descriptive error messages for (implementation: `plugins/core/hooks/validate-ticket.sh`):

- Invalid file locations (not in todo/, icebox/, or archive/)
- Invalid filename format (not YYYYMMDDHHmmss-*.md)
- Missing or malformed frontmatter
- Invalid field values (created_at, author, type, layer, effort, commit_hash, category)
- Anthropic.com email addresses (must use actual git user.email)

### Validation Script Alerts

The `update-ticket-frontmatter` script validates effort values at write time, preventing bypass of the validation hook (implementation: ticket `20260207170806-fix-effort-invalid-value-root-cause.md` and referenced update script).

## Observations

Development observability is achieved through story documents that capture the full narrative of each branch (implementation: `plugins/core/skills/write-story/SKILL.md`).

Changelog entries create a categorized audit trail with commit and ticket links (implementation: `plugins/core/skills/write-changelog/SKILL.md`).

The performance-analyst provides automated development quality feedback across five dimensions: Consistency, Intuitivity, Describability, Agility, and Density (implementation: `plugins/core/skills/analyze-performance/SKILL.md` lines 30-56).

Release notes provide high-level summaries extracted from stories (implementation: `plugins/core/skills/write-release-note/SKILL.md`).

The observability model is retrospective rather than real-time, focusing on post-hoc analysis through stories, changelogs, and release notes rather than live monitoring.

## Gaps

No structured logging to files or external systems. Shell scripts output to stderr but do not maintain log files.

No telemetry or usage analytics collection.

No error rate tracking or failure monitoring across sessions.

No alerting mechanisms for CI/CD failures beyond GitHub's built-in notifications.

No runtime monitoring. This is appropriate for a development tool that runs within Claude Code sessions rather than as a persistent service.

No distributed tracing. All operations execute within a single Claude Code session context.
