---
created_at: 2026-08-28T03:20:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Record the coordinate a question was posted at

## Overview

**PROPOSED.** A later tick can only read a question's own thread if it knows where that
thread is. The agent knows the root `ts` and its reply's `ts` **at the moment it posts** —
so the coordinate is already in hand and never needs to be searched for later. This is
the same property that lets the inbound sweep's receipt need no lookup: the `slack-ref`
it writes *is* `<channel>:<ts>` (`workaholic:notify`, the receipt entry).

The coordinate rides the `human-checkin-ask-<slug>` line `ask-question.sh` already writes
through `log-append.sh`. **No new store, no new field on any artifact, and no search
later** — the mission's stated constraint, and the reason a coordinate recorded at post
time is strictly better than one recovered by a channel-history read the notify skill's
two-query bound would have to be widened for.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/single-writer.md` — one writer per record, composed rather than duplicated

## Key Files

- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — writes the ask line; the
  coordinate joins what it already records.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the log's only writer,
  append-only and idempotent per (tick, step); takes `--summary "<one line>"`.
- `plugins/workaholic/skills/moderate/scripts/log-read.sh` — the reader a later tick uses
  to recover the coordinate.
- `plugins/workaholic/skills/moderate/scripts/lib/question-id.sh` — the one derivation of
  the question id, shared by the gate, the writer and the reader.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the check-in's contract,
  where the agent is told to hand the coordinate back after posting.
- `scripts/test-workflow-scripts.mjs` — the pin.

## Implementation Steps

1. **Decide where on the line the coordinate sits, and keep it one line.** The log is
   line-oriented and `log-append.sh` takes a single `--summary`, so the coordinate is
   carried in that summary in a fixed, parseable form (`<channel>:<ts>`), not as a new
   flag on the log writer. Read `log-append.sh` and `record-answer.sh` first: the latter
   already flattens prose into one line, and the same constraint applies here.
2. **Have `ask-question.sh` accept the coordinate it is given**, not discover one. The
   script is the gate and the ledger; the agent posts. So the coordinate is an input the
   agent supplies after the post succeeds, and a question posted with no coordinate
   recorded is a real, ordinary state — the script must accept its absence and say so
   rather than refuse.
3. **Preserve the gate's behaviour exactly.** `already_asked`, `answered`, `outstanding`,
   the per-tick and per-day caps, the quiet-hours and working-day holds and the
   `human-checkin-reasked-` / `human-checkin-held-` lines are untouched. Adding a
   coordinate must not change which questions are asked or how often.
4. **Add the reader half**, so the next ticket does not invent a second parser: one
   function that, given a question key, returns the coordinate recorded for it (or a named
   absence), composing `log-read.sh` and `lib/question-id.sh` rather than re-deriving the
   id. One derivation of the id and one of the coordinate.
5. **State the contract in `reference/workflow.md`**: after posting a question, the agent
   hands back the `(channel, ts)` it posted at, and the tick records it on the ask line.
6. **Pin it**: a hermetic test that writes an ask line with a coordinate, reads it back,
   and asserts a question asked without one reads a named absence rather than an error.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The coordinate a question was posted at is recoverable from the tick log by its key.
- A question recorded with no coordinate reads a **named absence**, never an error and
  never a guessed coordinate.
- The ask gate's behaviour is byte-identical: same questions, same caps, same holds.
- No new store, no new field on any artifact, and no second derivation of the question id.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the new round-trip test.
- A diff review showing `log-append.sh`'s interface unchanged.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- The existing check-in tests pass unchanged, proving the gate did not move.

## Considerations

- **A coordinate is not load-bearing.** If the post succeeded and the coordinate was not
  recorded, the question is still asked and still gated; only the return path is
  unavailable for it. That must be a named state, because the alternative is a later tick
  searching for the thread — which is the channel-history read this design exists to avoid.
- The `ts` of the **reply** and of the **root** are different coordinates. Which one a
  thread read needs is the next ticket's question; record what the agent has, and name
  each rather than collapsing them.
