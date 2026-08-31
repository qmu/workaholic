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

# Reply the answer and its outcome into the thread

## Overview

Post the shape. Per answered question whose outcome is known, one reply into **that
question's own thread**, on the coordinate `ask-question.sh --record-ask` already recorded
— no lookup, no search, `workaholic:notify`'s two-query bound untouched because no query is
made.

This is the ask's second half: after the follow-up work is done, the thread carries the
operator's answer as the loop recorded it and what came of it.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-question-answers.sh` — the step whose
  agent half posts it, and whose candidate derivation this extends.
- `plugins/workaholic/skills/moderate/scripts/answer-outcome.sh` — the reader.
- `plugins/workaholic/skills/moderate/scripts/lib/question-coordinate.sh` — the coordinate's
  one format.
- `plugins/workaholic/skills/moderate/scripts/log-append.sh` — the ledger line that makes a
  second reply impossible.
- `plugins/workaholic/skills/moderate/reference/workflow.md` §22 — the step's contract.
- `CLAUDE.md` — the step's note, updated in the same change.

## Implementation Steps

1. Derive candidates: a question reading `answered`, with a **recorded coordinate**, whose
   `answer-outcome.sh` reading is `settled`, and with no `human-checkin-outcome-<slug>`
   line already in the log.
2. Hand them back in `needs_agent`, as this step already does for its thread reads — Slack
   is a connector the session holds, not a script.
3. The agent posts one reply per candidate into that coordinate's thread, carrying the
   recorded answer and the outcome in the catalog's words.
4. Log each post under `human-checkin-outcome-<slug>` through `log-append.sh`, so a second
   reply is impossible by construction and the line reaches the base on
   `persist-log.sh`'s second run.
5. Keep it **never load-bearing**: a failed post is `outcome_post_failed: <reason>` and
   changes nothing about the recording, the filing, the question's state or the reading.
6. Apply the existing holds — quiet hours and the working-day gate — and hold rather than
   drop. A question with no recorded coordinate reads a **named absence** and is never
   searched for.
7. Report per candidate: posted, held, or the named reason it was not.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One reply per question, ever, into that question's own thread.
- `pending` and `unreadable` readings post nothing and are reported by name.
- Nothing is merged, closed, gated, re-asked or confirmed by this step, and no key, cap or
  hold moved.
- A coordinate-less question is named, never searched for.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`.
- The drill in the following ticket.

**Gate** — what must pass before approval:

- A second tick over the same fixture posts nothing at all.

## Considerations

- The step's `event` stays empty, for its existing reason: the agent acts after `run.sh`
  returns, so an event here would be a claim about a post not yet made.
- The dedup is the ledger line plus the `settled` reading, not a cursor: a question whose
  outcome is not yet known is simply a candidate again next tick.

## Final Report

Development completed as planned.

`step-question-answers.sh` derives a second candidate set in the pass it already makes over the
ledger: a question reading `answered`, with a recorded coordinate, whose `answer-outcome.sh`
reading is `settled:`, and with no `human-checkin-outcome-<slug>` line already in the log. The
person's own words ride the same pass, so the reply carries the answer as recorded rather than a
paraphrase. Only a `settled:` reading becomes a candidate; `pending` and `unreadable:<reason>`
are counted in the summary and post nothing.

The candidates go back in `needs_agent` with the shape, the holds, the record and the
never-load-bearing rule spelled out per candidate. The dedup is structural — the ledger line
plus the reading — so no cursor exists anywhere, and a second tick over the same fixture hands
back nothing at all.

Exercised against a fixture tick log: an answered question with a `not_filed:` line yields one
outcome candidate carrying the recorded words and the coordinate; adding the
`human-checkin-outcome-` line empties the set on the next tick; removing the filing line makes
it `1 not settled yet` with no candidate; and an absent log area stays an ordinary `ok`.

### Discovered Insights

- **Insight**: The answered slugs were already being derived here — to *exclude* them from the
  thread reads — so the second set is a projection of a pass that already existed rather than a
  new walk. That is what made a second step unnecessary and a second reader avoidable.
  **Context**: The general shape: when a step already computes a set in order to subtract it,
  the subtracted set is usually the candidate set some other question wants, and naming it costs
  nothing.

- **Insight**: The suite pins that this step "makes no gh call of any kind", and that stayed true
  literally while the step gained an indirect, bounded network read through the reader. The
  assertion was kept and its comment corrected rather than the assertion being widened.
  **Context**: A pin whose meaning has shifted under it is worse than no pin — the honest repair
  is to say in the comment what it now guarantees (no GitHub call written *here*, which is what
  would let one grow unbounded beside the Slack reads) rather than to let the name carry a claim
  it no longer makes.

- **Insight**: The holds are stated in the `needs_agent` bound rather than recomputed in the
  step, following `✅ 解消を確認` exactly. `ask-question.sh` was the wrong home for them here:
  its gate carries the per-tick and per-day **question** caps, and spending one on a reply that
  is not a question would silently reduce how many questions the tick can ask.
  **Context**: The clock gate already exists in two places (`ask-question.sh` and
  `step-human-checkin.sh`); a third copy is the drift this avoided.
