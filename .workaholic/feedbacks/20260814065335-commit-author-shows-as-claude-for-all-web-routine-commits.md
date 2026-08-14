---
type: Feedback
title: Commit author shows as Claude for all Web Routine commits
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-14T06:53:35+00:00
author: a@qmu.jp
supersedes: 
---

# Commit author shows as Claude for all Web Routine commits

When commits are implemented via a Claude Code Web routine, the commit author is always recorded as "Claude", for every commit, regardless of which routine or person actually originated the change. This makes it impossible to trace a given commit back to the specific routine or person that produced it, which hurts auditability and debugging when several routines are active. The requested behavior is that commit author metadata — or another identifying field, for example a commit message trailer — reflect the originating routine or user, so commits can be attributed correctly.

Source: https://github.com/qmu/workaholic/issues/453
