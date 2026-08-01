---
type: Feedback
title: The runner image still has no `gh`
kind: concern
source: development
created_at: 2026-08-01T18:19:23+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: the-runner-image-still-has-no
owner: 
mission: 
tickets: [20260731220639-gh-is-absent-in-the-cloud-runner.md]
origin_pr: 158
origin_pr_url: https://github.com/qmu/workaholic/pull/158
origin_branch: work-20260801-134910
origin_commit: 43c042a1
last_seen: 2026-08-01T18:19:23+09:00
---

# The runner image still has no `gh`

## Description

Every cloud tick still cannot open or merge a pull request; it can only push a branch and report why it stopped. The guards make that honest and safe, but they do not make the loop able to finish an `auto` unit on its own — such a unit is demoted to the PR path on every run (`docs/drive-loop-runbook.md`).

## How to Fix

Install `gh` in the Claude-Code-on-the-web container image, or provision a token and accept the API-fallback alternative that was rejected here. Until then, treat `auto` as unreachable for cloud-only units and expect a human at every merge.
