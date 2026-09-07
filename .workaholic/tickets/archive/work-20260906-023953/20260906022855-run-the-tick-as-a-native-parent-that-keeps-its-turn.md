---
created_at: 2026-09-06T02:28:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: 
---

# Run the tick as a native parent that keeps its turn

## Overview

The interactive coordinator branch selected by the previous ticket. The parent **keeps its
turn**: it derives the startup anchor once, runs a short first tick, and sends each tick's
report as **commentary rather than a final response**, returning to an interruptible wait
between boundaries. This is the branch that puts the loop's status where the operator started
it, which no amount of repair to the external supervisor can do — that supervisor has no
parent to call back into.

The clock terms are the ones `work/SKILL.md` already states and are not re-derived here: the
cadence is measured from **startup**, a boundary is the first `startup + k×interval` strictly
after now, and a slow tick costs the boundaries it overran rather than shifting the phase.
What is new is that the coordinator holds its own turn while doing it.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — the running loop's own reporting and recovery

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — *The coordinator owns the clock, and the work
  never holds it*; the native-parent branch is written beside those three terms.
- `plugins/workaholic/skills/work/reference/other-agents.md` — the substitution table and the
  measurements behind it.
- `plugins/workaholic/commands/infinite-development.md` — the tick body; its channel turn and
  its report are what the coordinator emits as commentary.

## Implementation Steps

1. Derive the **startup anchor once**, at the loop's start, and never re-derive it. Every later
   deadline is computed from it, so an early wake, a slow tick and a question answered mid-loop
   all leave the phase where it was.
2. Run a **short first tick** and emit its report immediately, so the operator sees the loop
   working before the first full interval elapses.
3. Emit every tick report as **commentary, not a final response** — the report names what the
   tick did, what was dispatched, and what came back.
4. Wait **interruptibly** between boundaries, in waits of at most 60 seconds and shorter when
   the next deadline is nearer. A five-minute blocking wait in the coordinator is refused by
   name: it makes a question unanswerable for the length of the wait.
5. **Recompute the remaining time after every early wake, and treat an early wake as not a tick
   boundary.** Process what the wake brought — user steering, newly available child outcomes —
   report it, and return to waiting for the same deadline.
6. At each **boundary**, run the channel turn and the dispatch decisions **regardless of whether
   any worker has finished**, then emit the tick report and return to waiting. Never
   synchronously await a worker across the next boundary.
7. Write the branch into `work/SKILL.md` beside the existing three clock terms, and state in
   `other-agents.md` what it restores that the external supervisor cannot: the report reaching
   the conversation the loop was started in.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The anchor is derived once; no step re-derives it, and no early wake moves it.
- Every tick report is commentary; no ordinary tick ends the parent's turn.
- No wait in the coordinator exceeds 60 seconds, and a wait is shortened when the deadline is
  nearer than that.
- A boundary's channel turn and dispatch happen whether or not a worker has returned.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- A read of `work/SKILL.md` showing the branch stated against the three clock terms.

**Gate** — what must pass before approval:

- The startup-anchored clock's existing wording is composed, not restated with different terms.

## Considerations

- The end-to-end evidence that this branch actually delivers into the chat is the mission's own
  acceptance ticket and is deliberately not claimed here.

## Final Report

Development completed as planned.

The branch is stated in `work/SKILL.md` as *The native-parent branch: the coordinator holds its
own turn*, placed immediately after the three clock terms and **composing** them rather than
restating them: its opening sentence says so in those words, and none of its six numbered terms
re-derives the anchor rule, the dispatch rule or the already-running refusal. `other-agents.md`
gains *What the native-parent branch restores* — the return path, which the 2026-09-05 repair to
the external supervisor could not reach because `codex exec` has no parent to call back into.

### Discovered Insights

- **Insight**: the 2026-09-05 repair (issues #984/#985) fixed both of the clock's terms and left
  a third property untouched that neither term names — *where the report goes*.
  **Context**: it is why a correct-looking repair still ended with the operator learning nothing,
  and why the supervisor's non-promise had to be written onto its own row rather than left to be
  discovered by whoever next reads `.codex-loop/`.
- **Insight**: the 60-second wait ceiling is a **refusal**, not a tuning constant — the number
  bounds how long a person's question can go unanswered, which is the property the whole cadence
  exists to protect, so a longer wait is wrong even where it would sleep less often.
  **Context**: a later reader tempted to sleep the whole interval for efficiency is re-creating
  the exact defect #984 measured, one layer up.
