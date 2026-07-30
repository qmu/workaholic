---
type: Feedback
title: A pure relocation cannot fit under the per-commit size ceiling by construction
kind: concern
source: development
created_at: 2026-07-30T19:07:49+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: a-pure-relocation-cannot-fit-under
owner: 
mission: []
tickets: [20260729121502-shrink-mission-skill-file.md]
origin_pr: 109
origin_pr_url: https://github.com/qmu/workaholic/pull/109
origin_branch: work-20260730-180928
origin_commit: 9910d689
last_seen: 2026-07-30T19:07:49+09:00
---

# A pure relocation cannot fit under the per-commit size ceiling by construction

## Description

The release scan blocks at `override` tier: 701 non-generated changed lines against a 500 ceiling (see [044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b)). `MAX_COMMIT_CHANGED_LINES` sums added **plus** deleted lines, so moving 260 lines from one file to another costs 520 before a single line of real work — a refactor-by-relocation is structurally incapable of passing, however well-scoped it is. This is a third instance of the same rule being overridden (the stream already holds `the-ticket-batch-convention-structurally-collides` for spec commits, and PR #108's foundation commit for an implementation commit), and the metric's stated purpose is to make commit count a comparable throughput unit — which a pure move inflates without adding throughput.

## How to Fix

Decide the rule deliberately rather than overriding it a third time: either exempt a commit whose diff is dominated by pure renames/moves (git already detects them — `--find-renames` would report this commit's relocation as such), or count added lines only. A rule that is always overridden stops measuring anything, and this is now the pattern rather than the exception.
