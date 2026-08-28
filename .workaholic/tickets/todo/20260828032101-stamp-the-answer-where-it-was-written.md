---
created_at: 2026-08-28T03:21:01+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Stamp the answer where it was written

## Overview

**PROPOSED.** A person who answers in the thread has no way to tell whether the loop read
them. The stamp is the catalog's **reaction on the answer message — reaction only, never a
reply**: a reply into a thread the person is already reading is the hourly restatement this
repository has retired posts for twice, while a reaction says *received* at a glance in the
one place they are already looking.

It rides the coordinate already in hand, so **no lookup and no second query** — the same
property as the sweep's receipt (`workaholic:notify`, the receipt entry, whose reaction is
named once in that catalog and read from there by everything else).

**Never load-bearing.** The answer is recorded and any issue is filed before the stamp is
attempted; a failure is reported as `ack_failed: <reason>` and changes nothing about the
recording, the question's state, or the filing.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/bounded-external-calls.md` — no lookup, named failures

## Key Files

- `plugins/workaholic/skills/notify/reference/notifications.md` — the catalog; the single
  source for the reaction's name, and the precedent for a receipt that is never
  load-bearing. Read the `/propose` receipt entry in full.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — where this step's contract
  and its reported outcomes belong.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the report line.
- `plugins/workaholic/skills/workaholify/routines/moderate.md` — the routine template,
  whose named post shapes are the prompt's ceiling and are drift-pinned.
- `scripts/test-workflow-scripts.mjs` — the drift pin between the catalog and the template.

## Implementation Steps

1. **Read the catalog's receipt entry in full first.** It settles the reaction-versus-reply
   question, the single-source rule for the emoji name, the no-lookup property and the
   never-load-bearing rule. This ticket applies that shape to a second event; it does not
   re-decide it.
2. **Name the reaction once, in the catalog**, and have the routine template and the drift
   pin read it from there. Whether it is the same emoji the sweep uses or its own is a
   judgement to make in the catalog — one event keeps one vocabulary, and these are two
   different events (a capture, and an answer read).
3. **Stamp the answer message on the coordinate already in hand.** No search, no channel
   history, no thread lookup: the message was just read at a known coordinate.
4. **Only an answer this run actually recorded.** An answer an earlier tick already
   recorded gets nothing — its stamp is on the message from the tick that read it, and a
   second one an hour later is the hourly restatement. A not-recorded candidate gets
   nothing either.
5. **Post no reply, anywhere, for this event.** State that in the step's header, because
   the tempting change a month from now is to add one.
6. **Report the outcome per answer** — stamped, or `ack_failed: <reason>` — beside the
   recording's and the filing's own outcomes. Three facts, three reports.
7. **Extend the routine template's named shapes** if and only if the catalog now names a
   shape the template must authorize, and keep the drift pin passing.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An answer this run recorded carries the catalog's reaction on the answer message.
- No reply is posted for this event, in any thread.
- An answer an earlier tick recorded gets no second stamp.
- A failed stamp is reported `ack_failed: <reason>` and changes nothing else.
- The reaction's name has exactly one source, and the template matches it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — the catalog↔template drift pin passes.
- A test asserting a stamp failure leaves the recorded answer and any filed issue intact.
- A grep-level assertion that this path posts no message.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` green.
- The catalog names the reaction once and nothing restates it.

## Considerations

- **Two audiences, and this serves only one.** A reaction carries no link and is invisible
  to anyone reading the issue rather than the thread. That is accepted here: the person
  who wrote the answer is reading the thread, and the issue is where everyone else looks.
- If the answer produced an issue, the person may want its link. Resist adding a reply for
  it — the issue is assigned and GitHub notifies; a reply would be the same noise twice,
  which is the argument that shaped this whole catalog.
