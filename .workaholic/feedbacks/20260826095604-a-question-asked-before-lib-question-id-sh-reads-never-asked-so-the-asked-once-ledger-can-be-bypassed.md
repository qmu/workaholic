---
type: Feedback
title: A question asked before lib/question-id.sh reads never_asked so the asked-once ledger can be bypassed
kind: instruction
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-26T09:56:04+00:00
author: a@qmu.jp
supersedes: 
---

# A question asked before lib/question-id.sh reads never_asked so the asked-once ledger can be bypassed

# A question asked before lib/question-id.sh reads never_asked, so the asked-once ledger can be bypassed

The check-in's ledger matches a question by the slug `lib/question-id.sh` derives — `<truncated key><digest>`. Log lines written before that library shipped (2026-08-23) carry the **raw key** as their step id instead, so the reader looks for a slug the log does not contain and answers `never_asked` for a question that was demonstrably asked.

Measured on tick `20260826-095103` (2026-08-26, this repository). `connector-coverage-gmail-drive` was asked in #dev-workaholic on 2026-08-18 and logged as `human-checkin-ask-connector-coverage-gmail-drive`; it has never been answered. Today `question-state.sh --key connector-coverage-gmail-drive` returns `{"state": "never_asked", "slug": "connector-coverage-gmail-2420674644"}` and `ask-question.sh` returns `ask: true`. Nothing changed about the question; only the id derivation did. The tick declined to post, so the person was not asked a second time, but the gate that should have refused did not.

The same tick shows a second, independent way the ledger's key and the reader's key diverge: `question-liveness.sh` matches the key as an exact string inside the owning step's `needs_agent` payload, and a key the agent composed (`connector-coverage-gmail-drive`) is never named there — the step returns `{"surface": "gmail", "action": "probe_connector"}`. With the real array spliced in, that key still reads `settled` while Gmail and Drive are measurably still unreachable from this session (both `connected: true`, `enabledInChat: false`). That is a different cause from the one recorded in `20260826065731-question-liveness-reads-an-array-run-sh-never-emits-so-every-asked-question-reads-settled.md`, and splicing the arrays in does not fix it.

Both point at one contract: the id a question is stored under and the id every reader looks for must be derived in one place, and a key a step does not literally emit needs a liveness answer of `unknown` rather than `settled`.
