---
type: Feedback
title: Propose at the capture seam, not from a merged-main window
kind: instruction
source: discussion
created_at: 2026-08-04T22:13:28+09:00
author: a@qmu.jp
supersedes: 
---

# Propose at the capture seam, not from a merged-main window

Ruled by the developer on 2026-08-04, superseding the batch-seat design shipped the same day. The propose act is not fixed to any single output: the [Propose] capture routine judges the ask in the session that receives it, and emits — in one publish-tree PR — the feedback record together with whatever the judgment warrants: a mission with its ticket set, a loose ticket, or the record alone when no work is warranted. Feedback-only is one possible outcome, never the routine's definition. The [Propose Batch] cron template is removed as unnecessary, and the defect it compensated for is named: /propose was built to read only feedback already merged to main, so the record just written was invisible to it by design and a later sweeper had to exist at all. That window model — the shared pushed cursor ref and the merged-main window — is retired with it. Merging the capture PR remains the approval, and it now approves the record and its proposal in one act.
