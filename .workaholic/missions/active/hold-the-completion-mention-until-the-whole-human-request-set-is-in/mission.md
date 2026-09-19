---
type: Mission
title: Hold the completion mention until the whole human request set is in
slug: hold-the-completion-mention-until-the-whole-human-request-set-is-in
status: active
merge_policy:
created_at: 2026-09-19T10:01:08+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
assignee:
predicted_hours:
actual_hours:
feedback: [20260919100026-reconcile-every-accepted-request-before-a-completion-mention.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md]
tickets: []
stories: []
gate_type:
gate_target:
gate_assert:
claim: work-20260919-152739
---

# Hold the completion mention until the whole human request set is in

## Goal

The loop mentioned the operator when one unit merged while four requests from the same thread were
still queued. Its reconciliation folds at the **item** grain; a person's scope is a **thread**. Nothing rereads that thread first, and nothing tells a worker receipt from an
all-requests-complete notification.

## Experience

A completion mention means every accepted request in the thread is in, verified and delivered. One
short holds it, and scoped progress goes out naming what is left. The thread is reread immediately
before, so a request written while work ran is captured. A worker finish is evidence for the
parent, never its permission.

## Acceptance

<!-- PROPOSED - a sketch the reviewer replans drive-ready. -->

- [ ] The accepted set folds at the **thread** grain; one member short withholds the mention (#20260919100142-fold-the-accepted-request-set-at-the-thread-grain.md)
- [ ] The thread and its linked continuations are reread before the mention, and new requests are
      captured before observation state advances (#20260919100143-reread-the-thread-before-a-completion-mention.md)
- [ ] Worker receipt, scoped progress and completion mention are three acts; only an explicit
      human defer or cancel narrows the scope (#20260919100143-separate-a-worker-receipt-from-progress-and-from-completion.md)

## Changelog

<!-- Append-only, dated timeline. One line per event; never rewrite past lines. -->
