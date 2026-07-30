---
type: Feedback
title: The foundation commit is 772 changed lines, over the per-commit ceiling
kind: concern
source: development
created_at: 2026-07-30T18:57:14+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-foundation-commit-is-772-changed
owner: 
mission: []
tickets: [20260729183606-publish-tree-primitive.md, 20260729183607-ticket-publishes-to-main.md, 20260729183608-mission-publishes-to-main.md, 20260729183609-drive-surveys-current-main.md]
origin_pr: 108
origin_pr_url: https://github.com/qmu/workaholic/pull/108
origin_branch: work-20260730-171125
origin_commit: 39b52709
last_seen: 2026-07-30T18:57:14+09:00
---

# The foundation commit is 772 changed lines, over the per-commit ceiling

## Description

The release scan blocks at `override` tier: [1179d916](https://github.com/qmu/workaholic/commit/1179d916) is 772 non-generated changed lines against a 500 ceiling. Unlike the spec-commit case already in the stream (`the-ticket-batch-convention-structurally-collides`), this is an implementation commit — four new scripts, the decision record, the skill section, and ~200 lines of hermetic tests — so the ceiling is measuring what it was built to measure and the commit genuinely exceeds it. The unit routes to a PR regardless of the finding (all four members are `merge_policy: review`), so the block changed nothing about the route; it is recorded rather than overridden silently.

## How to Fix

Split a primitive-plus-tests commit at the seam between the scripts and their coverage next time — the tests are independently reviewable and would have kept both halves under the ceiling. If that split is not wanted, the honest alternative is raising `MAX_COMMIT_CHANGED_LINES` with a stated reason, not overriding it per commit.
