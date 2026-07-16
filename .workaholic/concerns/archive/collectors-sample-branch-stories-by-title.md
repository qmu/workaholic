---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
last_seen: 2026-07-01T21:16:06+09:00
first_seen: 2026-06-30T02:27:29+09:00
concern_id: collectors-sample-branch-stories-by-title
severity: moderate
status: accepted
resolved_by_pr: 
resolved_by_commit: 
closed_reason: Deliberate scale trade-off with an explicit ~100-story trigger; stories/ holds 66, below the concern's own threshold.
closed_at: 2026-07-16T17:06:06+09:00
---

# Collectors sample branch stories by title match; very large dirs may need indexing

## Description

The per-developer collectors read branch stories by sampling on title/theme match rather than reading all of them (the live repo already has ~50). A very large `stories/` directory could exceed the practical sampling window and miss a relevant story (`plugins/workaholic/skills/catch/SKILL.md`, Collect Developer step 3).

## How to Fix

If `stories/` grows past ~100 files, add a per-developer story index or a `stories/<developer-slug>/` partition.
