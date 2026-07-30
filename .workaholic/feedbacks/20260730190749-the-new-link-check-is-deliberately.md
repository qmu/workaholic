---
type: Feedback
title: The new link check is deliberately narrow, and the obvious "improvement" would break it
kind: concern
source: development
created_at: 2026-07-30T19:07:49+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-new-link-check-is-deliberately
owner: 
mission: []
tickets: [20260729121502-shrink-mission-skill-file.md]
origin_pr: 109
origin_pr_url: https://github.com/qmu/workaholic/pull/109
origin_branch: work-20260730-180928
origin_commit: 9910d689
last_seen: 2026-07-30T19:07:49+09:00
---

# The new link check is deliberately narrow, and the obvious "improvement" would break it

## Description

`verify.mjs` checks only markdown links into or out of a `reference/` dir (see [044a3f8b](https://github.com/qmu/workaholic/commit/044a3f8b) in `scripts/build-plugins/verify.mjs`). Broadened to every relative `.md` link it flags six correct paths — runtime artifact paths in the consuming project (`.workaholic/stories/<branch-name>.md`) and `<placeholder>` templates — and a containment check that cries wolf on correct prose gets deleted rather than fixed.

## How to Fix

The narrowing and its reason are written into the code as a comment, which is the mitigation. If broader coverage is ever wanted, the honest form is a distinction the checker can actually make — e.g. only check links whose target has no `<` and does not start with `.workaholic/` — decided once and stated, not discovered by whoever widens the regex.
