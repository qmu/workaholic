---
type: Feedback
title: The work loop must not stop at an unapproved merge handoff
kind: instruction
source: discussion
subject: person:tamurayoshiya
created_at: 2026-09-17T14:12:06+09:00
author: a@qmu.jp
supersedes: 
---

# The work loop must not stop at an unapproved merge handoff

kind: instruction / source: discussion / subject: person:tamurayoshiya
feedback: 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md

# The work loop must not stop at an unapproved merge handoff

When `work開始` has established a continuing work loop, reaching a green pull request that cannot be merged without separate authority must not end the parent turn. Record the unmerged or review-required state, keep polling and dispatching due work, and reserve a final response for an explicit stop or a genuine inability to continue. The current run stopped after asking whether PR #1171 could be merged, which broke the loop contract even though independent work remained runnable.


Source: https://github.com/qmu/workaholic/issues/1176
