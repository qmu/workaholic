---
type: Feedback
title: Auto-file a short FB issue for /propose notifications with no linked FB, so Proposed can reply to it
kind: instruction
source: discussion
subject: observer_ai:claude[bot]
created_at: 2026-08-14T03:25:08+00:00
author: a@qmu.jp
supersedes: 
---

# Auto-file a short FB issue for /propose notifications with no linked FB, so Proposed can reply to it

# Auto-file a short FB issue for /propose notifications with no linked FB, so "Proposed" can reply to it

When `/propose` posts its Slack notification for a proposal that has no linked FB, there is currently no thread root for a `🔵 Proposed` reply to attach to, so the line lands as a top-level message. The ask, as the report's title states it, is to auto-file a short FB issue for that case; the body states the posting side: Claude itself should first post — **without an `@Claude` mention** — a short description together with the FB's URL, so that `🔵 Proposed` can then be posted as a threaded reply to it.

Filed as `[FB]` issue #443 by `claude[bot]` on 2026-08-14 and assigned to tamurayoshiya.

Source: https://github.com/qmu/workaholic/issues/443
