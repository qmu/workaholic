---
type: Feedback
title: Quality Gate is prose-mandated, not hook-enforced
kind: concern
source: development
created_at: 2026-07-01T01:12:10+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: quality-gate-is-prose-mandated-not
owner: 
mission: 
tickets: []
origin_pr: 63
origin_pr_url: https://github.com/qmu/workaholic/pull/63
origin_branch: work-20260630-050446
origin_commit: 4ee61c5
last_seen: 2026-07-01T21:16:06+09:00
closed: resolved
resolved_by_pr: 87
resolved_by_commit: e12448d4
---

# Quality Gate is prose-mandated, not hook-enforced

## Description

The `## Quality Gate` section is mandatory in prose but not enforced by `validate-ticket.sh` (frontmatter+location only), matching the `## Policies` precedent (see [e27a450](https://github.com/qmu/workaholic/commit/e27a450)). A ticket can technically omit it.

## How to Fix

Deliberate design choice; if hard enforcement is wanted, add a body-section grep to `validate-ticket.sh` plus a smoke test.
