---
type: Feedback
title: Stop squash-merging so landed branches read as merged
kind: instruction
source: slack
subject: person:U03S55GC3
created_at: 2026-09-26T17:34:52+09:00
author: a@qmu.jp
supersedes: 
review_surface: 
---

# Stop squash-merging so landed branches read as merged

Source: https://github.com/qmu/workaholic/issues/1279
Slack: https://qmu.slack.com/archives/C0BLL9J7FMY/p1790408324029899?thread_ts=1790404749.639019&cid=C0BLL9J7FMY

In #dev-workaholic the developer asked whether the many unmerged `work-*` branches were a problem. The loop answered that the ~22 local `work-*` branches only look unmerged because every pull request is squash-merged (their content is already on `main`). The developer replied:

> だとしたらsquash mergeしないで欲しい
> ("In that case, please don't squash merge.")

The underlying concern: a branch whose work has landed should read as merged, so landed branches stop piling up looking unfinished. This supersedes the 2026-09-01 ruling that made every merge a squash (`gather/scripts/merge-method.sh`).
