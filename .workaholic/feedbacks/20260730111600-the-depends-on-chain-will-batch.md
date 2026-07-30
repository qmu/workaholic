---
type: Feedback
title: The `depends_on` chain will batch all four tickets into one PR-unit
kind: concern
source: development
created_at: 2026-07-30T11:16:00+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-depends-on-chain-will-batch
owner: 
mission: []
tickets: []
origin_pr: 103
origin_pr_url: https://github.com/qmu/workaholic/pull/103
origin_branch: work-20260729-193859
origin_commit: 2e7f1b00
last_seen: 2026-07-30T11:16:00+09:00
---

# The `depends_on` chain will batch all four tickets into one PR-unit

## Description

The four tickets form a strict chain via their `depends_on` frontmatter (see [fa8033d3](https://github.com/qmu/workaholic/commit/fa8033d3) in `.workaholic/tickets/todo/a-qmu-jp/`), and `drive/SKILL.md` names `depends_on` as "the one signal strong enough to group on by itself — a dependent ticket in a separate PR is a PR that cannot merge." So `/drive` will plausibly claim all four as a single PR-unit and open one PR rewriting branching, `/ticket`, `/mission`, and `/drive` together — precisely the PR shape the same section warns reviewers cannot review as one thing. Switching to `merge_policy: review` ([2a049721](https://github.com/qmu/workaholic/commit/2a049721)) means a human now sees it, but does not make it smaller.

## How to Fix

Add an explicit note to the foundation ticket that it is intended to merge as its own unit ahead of the callers — the callers' gates already require "the dependency is merged first", which cannot be satisfied inside a single combined PR anyway.
