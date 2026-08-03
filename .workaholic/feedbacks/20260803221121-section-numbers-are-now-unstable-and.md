---
type: Feedback
title: Section numbers are now unstable, and nothing stops a future consumer keying on one
kind: concern
source: development
created_at: 2026-08-03T22:11:21+09:00
author: a@qmu.jp
supersedes:
severity: moderate
concern_id: section-numbers-are-now-unstable-and
owner: 
mission: [make-the-branch-story-concise-by-default]
tickets: [20260801185701-decide-the-fate-of-low-severity-concerns.md, 20260801185702-make-the-story-short-by-default.md]
origin_pr: 171
origin_pr_url: https://github.com/qmu/workaholic/pull/171
origin_branch: work-20260803-212338
origin_commit: 9084360e
last_seen: 2026-08-03T22:11:21+09:00
---

# Section numbers are now unstable, and nothing stops a future consumer keying on one

## Description

Numbering runs sequentially over whichever sections a story actually has, so Concerns is section 5 on one branch and 6 on another. Both current consumers were moved to name-matching and a test pins that (`scripts/test-workflow-scripts.mjs`, "story template mirrors agree"), but the test enumerates the two consumers it knows about. A third one added later can key on a number, and the failure is silent: no heading match is indistinguishable from a branch that raised no concerns.

## How to Fix

If a third consumer of the story structure appears, extract the heading matcher into one shared place rather than writing the regex a third time. Until then the named test is the guard, and it should gain any new consumer in the same change that adds it.
