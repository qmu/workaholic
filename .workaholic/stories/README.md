---
title: Stories
description: Branch development narratives that serve as PR descriptions
category: developer
modified_at: 2026-01-26T14:30:00+09:00
commit_hash: 5452b2d
---

[English](README.md) | [日本語](README_ja.md)

# Stories

This directory contains comprehensive story documents that serve as the single source of truth for PR descriptions. Each story synthesizes archived tickets and CHANGELOG entries into a complete PR-ready document.

## Purpose

Stories are PR descriptions stored as files. When creating a pull request, the `/pull-request` command generates a story file and copies its content directly to GitHub. This eliminates duplication between story generation and PR description assembly.

Stories serve multiple purposes:

- **PR description**: Content is copied directly to GitHub PR body
- **Historical record**: Preserved in repository for future reference
- **Reviewer context**: Explains the "why" behind a body of work

## Story Format

Stories contain YAML frontmatter for metrics, followed by seven sections that form the PR body:

```markdown
---
branch: <branch-name>
started_at: YYYY-MM-DDTHH:MM:SS+TZ
ended_at: YYYY-MM-DDTHH:MM:SS+TZ
tickets_completed: <count>
commits: <count>
duration_hours: <number>
velocity: <number>
---

Refs #<issue-number>

## Summary

[Numbered list of changes from CHANGELOG]

## Motivation

[Why this work was needed]

## Journey

[How the work progressed]

## Changes

[Detailed explanation of each change]

## Outcome

[What was accomplished]

## Performance

[Metrics, pace analysis, decision review]

## Notes

[Additional context for reviewers]
```

## Stories

- [feat-20260126-214833.md](feat-20260126-214833.md) - Subagent architecture with concurrent execution, git -C prohibition via settings.json deny, skill extraction, bundled scripts for permission-free plugins, and infrastructure improvements (POSIX sh, topic tree flowchart, ticket directory reorganization) - 34 tickets, 86 commits
- [feat-20260126-131531.md](feat-20260126-131531.md) - Workaholic directory standardization and conventions
- [feat-20260124-200439.md](feat-20260124-200439.md) - Ticket metadata and single source of truth consolidation
- [feat-20260124-105903.md](feat-20260124-105903.md) - Rule modularization and PR workflow improvements
- [feat-20260123-032323.md](feat-20260123-032323.md) - Documentation experience improvements and .workaholic/ directory restructuring
