---
type: Feedback
title: Reconcile every accepted request before a completion mention
kind: instruction
source: development
subject: person:tamurayoshiya
created_at: 2026-09-19T10:00:26+09:00
author: a@qmu.jp
supersedes: 
---

# Reconcile every accepted request before a completion mention

Source: https://github.com/qmu/workaholic/issues/1146

A live Codex `/work` session exposed a mismatch between PR-unit completion and the operator's
completion expectation. Notify and drive organize finish events around individual **units**. The
coordinator mentioned the operator when an assistant UI unit merged and passed verification, while
**other accepted requests in the same continuing human thread** — sorting, pagination, forms,
identifiers — remained queued. The operator inspected the UI and had to ask whether everything was
really done. This was a coordinator reporting failure; **a green pull request is not evidence that
the human request set is complete.**

## The requested completion contract

- Immediately before a completion mention, **reread the full relevant human thread and its
  explicitly linked continuation threads**, checking pagination/truncation, and capture new
  requests **before advancing observation state**.
- Reconcile **every** accepted request with implementation, appropriate verification, and any
  required delivery evidence. A proposal, a closed issue or a single merged pull request is
  insufficient.
- If any accepted request remains queued, active, blocked or unverifiable, **withhold the
  completion mention**. Send clearly scoped progress without a completion mention when useful.
- Do not silently redefine scope around the latest worker or pull request. **Only an explicit
  human defer or cancel changes the accepted completion scope.**
- Distinguish a worker's terminal receipt, a scoped progress message, and a human-facing
  all-requests-complete notification. Keep the independent observation tick running during this
  reconciliation.

Support this in work/notify/drive guidance and notification decisions, **including low-context
workers**: the parent owns the complete human request ledger and the freshly reread thread,
whereas a bounded worker can only prove its own unit. This does not require copying all
conversation into every worker, or another scheduler. A worker finish should be **evidence for the
parent**, not automatic permission to send a completion mention.

Related low-context coordinator feedback: #1142. Unknown-thread discovery limitation: #1132 —
incomplete discovery must not be treated as proof of completeness.
