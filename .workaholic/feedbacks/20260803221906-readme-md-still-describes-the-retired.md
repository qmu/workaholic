---
type: Feedback
title: README.md still describes the retired `/mission approve` flow
kind: concern
source: development
created_at: 2026-08-03T22:19:06+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: readme-md-still-describes-the-retired
owner: 
mission: [make-acceptance-ticking-measure-satisfaction-not-marker-shape]
tickets: [20260801185301-decide-the-acceptance-to-artifact-link.md, 20260801185302-establish-the-link-when-tickets-are-emitted.md, 20260801185303-make-the-ticker-measure-satisfaction.md]
origin_pr: 173
origin_pr_url: https://github.com/qmu/workaholic/pull/173
origin_branch: work-20260803-212324
origin_commit: be2a3beb
last_seen: 2026-08-03T22:19:06+09:00
---

# README.md still describes the retired `/mission approve` flow

## Description

Pre-existing drift found while working, unrelated to this change: `README.md`'s mission row and its walkthrough still describe `status: draft → approved` and `/mission approve`, both retired by decision K1 on 2026-07-31. `CLAUDE.md` and the mission skill are correct.

## How to Fix

Update the two `README.md` passages to the one in-flight state and the merge-is-the-approval rule. Left out here to keep this branch's diff to the acceptance machinery.
