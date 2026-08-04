---
type: Feedback
title: The `resume-*` lint keys on a filename and has never fired
kind: concern
source: development
created_at: 2026-08-04T12:43:13+09:00
author: a@qmu.jp
supersedes:
severity: low
concern_id: the-resume-lint-keys-on-a
owner: 
mission: [make-acceptance-ticking-measure-satisfaction-not-marker-shape]
tickets: [20260803213000-audit-the-gates-for-shape-dependent-green.md]
origin_pr: 182
origin_pr_url: https://github.com/qmu/workaholic/pull/182
origin_branch: work-20260804-113856
origin_commit: ab64a1cc
last_seen: 2026-08-04T12:43:13+09:00
---

# The `resume-*` lint keys on a filename and has never fired

## Description

`validate-ticket.sh:440-455` selects the lint by a `resume-` filename

## How to Fix

Nothing, unless the condition is observed. Widening the key would add
