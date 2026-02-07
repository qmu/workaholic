---
title: Observability Policy
description: Logging, monitoring, metrics, and tracing practices
category: developer
modified_at: 2026-02-07T10:56:08+09:00
commit_hash: 12d9509
---

[English](observability.md) | [Japanese](observability_ja.md)

# 1. Observability Policy

This document describes the observability practices observed in the Workaholic repository. Workaholic has no traditional application monitoring, but implements observability through development narrative generation and performance metrics embedded in story documents.

## 2. Development Metrics

### 2-1. Performance Analysis

[Explicit] The `performance-analyst` subagent evaluates decision-making quality during `/report` generation. It analyzes development patterns across multiple viewpoints, providing feedback on the quality of decisions made during the branch's development lifecycle.

### 2-2. Story Metrics

[Explicit] The `write-story` skill generates stories that include `started_at` and `ended_at` timestamps, ticket counts, commit counts, and business-day calculations for multi-day work. These metrics provide retrospective visibility into development velocity.

### 2-3. Changelog Tracking

[Explicit] The `write-changelog` skill generates categorized changelog entries (Added, Changed, Removed) from archived tickets, providing an audit trail of all changes with links to both commits and tickets.

## 3. Tracing

### 3-1. Ticket Traceability

[Explicit] Every implementation is traceable through the ticket lifecycle: creation in `todo/`, implementation during `/drive`, final report appended, and archival to `archive/<branch>/`. Each archived ticket contains a `commit_hash` linking it to the implementing commit.

### 3-2. Concerns Traceability

[Explicit] Ticket concern sections use identifiable references (prefixed with `[Explicit]` or `[Inferred]`) to trace design decisions back to their origin.

## 4. Monitoring

Not observed. No application monitoring, alerting, or health checking infrastructure exists. This is appropriate for a development tool that runs within Claude Code sessions rather than as a persistent service.

## 5. Logging

Not observed. Shell scripts use `set -eu` for strict error handling but do not produce structured logs. Claude Code's conversation context serves as the implicit log of operations during a session.

## 6. Observations

- [Explicit] Development observability is achieved through story documents that capture the full narrative of each branch.
- [Explicit] Changelog entries create a categorized audit trail with commit and ticket links.
- [Explicit] The performance-analyst provides automated development quality feedback.
- [Inferred] The observability model is retrospective rather than real-time, focusing on post-hoc analysis through stories and changelogs rather than live monitoring.

## 7. Gaps

- Not observed: No structured logging from shell scripts or agent executions.
- Not observed: No telemetry or usage analytics.
- Not observed: No error rate tracking or failure monitoring across sessions.
- Not observed: No alerting mechanisms for CI/CD failures beyond GitHub's built-in notifications.
