---
type: Feedback
title: The by-filename fallback assumes ticket filenames stay unique
kind: concern
source: development
created_at: 2026-08-04T12:46:15+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-by-filename-fallback-assumes-ticket
owner: 
mission: []
tickets: [20260804023100-claim-survey-reads-wrong-coordinate.md]
origin_pr: 178
origin_pr_url: https://github.com/qmu/workaholic/pull/178
origin_branch: work-20260804-105730
origin_commit: 6264039f
last_seen: 2026-08-04T12:46:15+09:00
---

# The by-filename fallback assumes ticket filenames stay unique

## Description

The fallback trusts the `YYYYMMDDHHMMSS-slug.md` rule to make a ticket

## How to Fix

Either assert filename uniqueness in `layout-doctor.sh`, or report the
