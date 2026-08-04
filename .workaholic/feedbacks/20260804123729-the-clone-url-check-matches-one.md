---
type: Feedback
title: The clone-URL check matches one remote form, not the repository
kind: concern
source: development
created_at: 2026-08-04T12:37:29+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-clone-url-check-matches-one
owner: 
mission: []
tickets: [20260802093000-request-backstop-substring-false-positive.md]
origin_pr: 180
origin_pr_url: https://github.com/qmu/workaholic/pull/180
origin_branch: work-20260804-112404
origin_commit: 6db80985
last_seen: 2026-08-04T12:37:29+09:00
---

# The clone-URL check matches one remote form, not the repository

## Description

It compares against `origin`'s exact string, so a body citing the same

## How to Fix

Derive both canonical forms from the parsed `owner/name` and match each,
