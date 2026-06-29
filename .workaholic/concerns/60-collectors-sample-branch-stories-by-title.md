---
origin_pr: 60
origin_pr_url: https://github.com/qmu/workaholic/pull/60
origin_branch: work-20260630-011820
origin_commit: 7a2c78d
created_at: 2026-06-30T02:27:29+09:00
severity: low
status: active
resolved_by_pr:
resolved_by_commit:
---

# Collectors sample branch stories by title match; very large dirs may need indexing

## Description

The per-developer collectors read branch stories by sampling on title/theme match rather than reading all of them (the live repo already has ~50). A very large `stories/` directory could exceed the practical sampling window and miss a relevant story (`plugins/workaholic/skills/catch/SKILL.md`, Collect Developer step 3).

## How to Fix

If `stories/` grows past ~100 files, add a per-developer story index or a `stories/<developer-slug>/` partition.
