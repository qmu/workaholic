---
created_at: 2026-08-31T20:09:59+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: make-the-tick-s-questions-readable-and-close-them-in-the-thread
merge_policy:
verification_handoff: 
---

# Read what a recorded answer became

## Overview

Nothing can answer *what came of this answer*. The tick log records that an answer was
recorded and, when the answer asked for something, that an `[FB]` issue was filed — but
whether that issue became work, and whether that work landed, is read by nobody.

Add one reader, `moderate/scripts/answer-outcome.sh`, that composes what already exists and
derives nothing twice: the log's own `question-answers` line for the filing, and — for a
filed issue — that issue's state through the one transport. It writes nothing and gates
nothing; every value it answers is a judgement, because an issue can be reopened between
two reads.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/answer-outcome.sh` — new; the one reader.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the log's only parser, composed.
- `plugins/workaholic/skills/moderate/scripts/question-state.sh` — `answered` is the
  candidate set; read it rather than re-deriving it.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — the one GitHub transport.
- `plugins/workaholic/skills/drive/reference/claims.md` — where a vocabulary's
  proof-or-judgement classification lives, with its consumers enumerated.
- `scripts/test-workflow-scripts.mjs` — the classification pin.

## Implementation Steps

1. Take the candidate set from `question-state.sh`: the questions reading `answered`.
   Do not walk the log a second time for them.
2. Read each candidate's filing outcome off the `question-answers` line the step already
   writes (`filed: <issue>` / `not_filed: <reason>`), through `log-read.sh`.
3. Answer per question, three-valued and never collapsed:
   - `settled:<what>` — the answer filed nothing (nothing is owed, and the outcome is known
     immediately), or the filed issue is closed by a merged pull request.
   - `pending` — the issue is filed and still open. Nothing to say yet.
   - `unreadable:<reason>` — the log, the line or the issue could not be read. **Never**
     rendered as `settled`, and carrying null rather than zeroed fields.
4. Cost one bounded REST read per **filed, still-open** candidate and none for the rest.
5. Classify the vocabulary in `drive/reference/claims.md` as **all judgements**, with this
   reader's consumers enumerated, and extend the suite's pin to it: no consumer may merge,
   close, gate, hold work or re-ask on it.
6. Update `CLAUDE.md` and `workaholic:moderate` in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The reader writes nothing, creates no store, adds no field to any artifact, and walks
  the log through `log-read.sh` alone.
- `unreadable` is never rendered as `settled`, and carries null counts.
- An answer that filed nothing is `settled` immediately, without a network call.
- The vocabulary is classified with its consumers enumerated, and the suite fails on an
  unclassified word.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`.
- The reader run against a fixture log with each of the three outcomes present.

**Gate** — what must pass before approval:

- Every value is justified as a judgement rather than a proof, in the table, in one place.

## Considerations

- An issue reopened after its pull request merged makes a `settled` reading false on the
  next look. That is exactly why nothing may act on it — the reply it feeds is a statement
  about what happened, never a gate.
- The chain from question to issue is the log's own filed line, not a search: no cursor,
  no second marker, no second reader.

## Final Report

Development completed as planned.

`moderate/scripts/answer-outcome.sh` answers `settled:nothing_filed` / `settled:issue_closed` /
`pending` / `unreadable:<reason>` per answered question, composing `question-state.sh` for the
state, `log-read.sh` for the `question-answers-filed-<slug>` line, and `gather/scripts/gh-rest.sh`
for the one bounded issue read. It writes nothing, creates no store, adds no field to any
artifact and makes no network call at all for an answer that filed nothing.

All four outcomes were exercised against a fixture log before the vocabulary was written down:
`not_filed:` → `settled:nothing_filed` with no call; a real closed issue → `settled:issue_closed`
carrying `state_reason: completed`; a number GitHub does not have → `unreadable:not_found` with
the issue number still named; and no filing line at all → `pending` with `reason:
no_filing_line`.

The vocabulary is classified in `drive/reference/claims.md` as the **eighth** in that home, all
judgements, with its one consumer enumerated, and the suite's classification pin extended to it:
it parses the words out of the reader's own `emit` calls, fails on an unclassified word, on a
word the reader never emits, on any row called a `proof`, and on the consumer reaching an acting
call site.

### Discovered Insights

- **Insight**: The ticket asked for a three-valued answer, and a fourth case exists that must not
  join the vocabulary — a question with **no recorded answer**. Folding it into `unreadable`
  would be exactly the collapse `unreadable` exists to close, so it is a refusal (`ok: false`,
  `reason: not_answered:<state>`, empty `outcome`) rather than a word.
  **Context**: The same shape recurs across this repository's readers — `readable: false` versus
  an honest empty, `pending` versus `unavailable`. The rule that falls out is: a state that is
  *not a reading of the subject at all* is refused before the vocabulary, never inside it.

- **Insight**: `"closed by a merged pull request"` is not reachable from the issue endpoint; it
  needs the issue's timeline, which is a second bounded call per candidate. `state_reason` is
  what GitHub records instead (`completed` when a merging pull request closes it), and
  `not_planned` is equally an outcome the person who answered is owed.
  **Context**: The reading therefore settles on `closed` and carries `state_reason` verbatim, and
  the narrowing is stated in the script's header and the classification table rather than left
  for a later reader to discover as a bug.

- **Insight**: `scripts/test-workflow-scripts.mjs` pins that no script but `question-state.sh`
  and `ask-question.sh` may *execute* `question-state.sh` — a rule whose stated purpose is that
  no script records an answer and no script re-derives a question's life.
  **Context**: A composition is what that rule is *for* rather than against, so
  `answer-outcome.sh` joined the allowlist with the distinction written into the pin: what stays
  banned is a second **derivation** of the state and any reach for `record-answer.sh`.
