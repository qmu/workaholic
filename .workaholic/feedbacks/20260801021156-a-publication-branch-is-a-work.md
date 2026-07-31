---
type: Feedback
title: A publication branch is a work-* branch that no claim owns
kind: concern
source: development
created_at: 2026-08-01T02:11:56+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: a-publication-branch-is-a-work
owner: 
mission: []
tickets: [20260731163049-propose-surveys-repo-state-and-lands-on-a-branch.md]
origin_pr: 124
origin_pr_url: https://github.com/qmu/workaholic/pull/124
origin_branch: work-20260801-012313
origin_commit: ea3765b8
last_seen: 2026-08-01T02:11:56+09:00
---

# A publication branch is a work-* branch that no claim owns

## Description

Publication branches now share the `work-*` prefix with claim branches. They are correctly invisible to the claim scan — it keys on a `Claim <unit-id>` commit subject, which is pinned by a new test — but a human reading `git branch -r` can no longer tell a claim from a publication by name (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).

## How to Fix

If this becomes confusing in practice, `list-claims.sh` could grow a companion that lists unmerged publication branches. Not worth building before the confusion is observed.
