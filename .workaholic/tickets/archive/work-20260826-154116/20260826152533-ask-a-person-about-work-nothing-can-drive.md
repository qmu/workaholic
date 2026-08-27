---
created_at: 2026-08-26T15:25:33+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260826152533-say-when-a-survey-excluded-its-whole-backlog.md
mission: drive-the-work-the-loop-wrote-one-resolution-of-who-a-person-is
merge_policy:
verification_handoff: 
---

# Ask a person about work nothing can drive

## Overview

PROPOSED. Ticket 5 makes the reading visible in a run report. A run report is read by nobody on
the day it matters — the same reason `/propose`'s report was refused as the surface for
`strategy-pace`. `/implement` may not ask (no `AskUserQuestion`, at any step), so there is no
path from *the loop cannot drive its own output* to *a person is told*.

`/moderate` is that path, and this is the same shape `step-stalled-units.sh` took for a stalled
claim in 2026-08-23: a step reads a pure reader, hands candidates to the check-in as questions
addressed to a named person, keyed so each is asked exactly once.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-stalled-units.sh` — the precedent; read its
  header whole before writing this one, especially why it narrows what it asks about while
  counting everything in its summary.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the other recent
  reader-backed asking step; same shape, different reader.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the keyed asked-once gate.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — where a step is invoked and contributes
  its report line, `summary` and `event`.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — the reader (a pure read).
- `plugins/workaholic/skills/gather/scripts/identity.sh` — resolves an owner; an owner that
  resolves through **no** entry is the candidate.

## Implementation Steps

1. Add `step-<n>-undrivable-units.sh` reading `plan-units.sh` and, for each unit excluded
   `owned_by_other`, resolving the owner through `identity.sh`. A unit whose owner resolves
   through **no** mapping entry is a candidate; one owned by a colleague the mapping names is
   **not** — that is a colleague's queue, working exactly as designed.
2. Key each candidate once per unit through `ask-question.sh`, so the asked-once gate, the
   per-tick cap, the quiet hours and the working-day hold all apply unchanged. No second ledger.
3. Address it to the direction's assignee, as `step-direction-health.sh` does.
4. **It asks and nothing else** — it reassigns nothing, writes no artifact, lifts no gate. This
   is what keeps a reporting step from quietly becoming a writer.
5. Supply `summary` (log-facing) and `event` (root-facing) per `run.sh`'s contract. The summary
   must carry **no age and no timestamp**: the root's change-diff normalises out only a
   timestamp, a bare hex object name and a clock time, so a summary that increments every tick
   would mark the step changed every hour by construction — the correctness requirement
   `step-stalled-units.sh`'s header records.
6. Count every `owned_by_other` unit in the summary and narrow only what is **asked** about,
   so a reader gets the whole picture and the narrowing is visible in the same line.
7. Update `/moderate`'s step count and its documentation in the same change.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit excluded `owned_by_other` whose owner resolves through no mapping entry produces one
  question, addressed to the direction's assignee.
- A unit owned by a colleague the mapping names produces **no** question.
- The same unit is not asked about twice across ticks.
- The step writes nothing: no artifact, no reassignment, no gate lifted.
- The step's summary is stable across two ticks with unchanged state.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic cases over a fixture, including the
  asked-once gate across two ticks and the stable-summary assertion.
- `sh scripts/e2e/loop-drill.sh verify-moderate` — the tick-level drill.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- Two consecutive fixture ticks produce one question and an unchanged summary.

## Considerations

- **A colleague's queue must produce no question**, or this step becomes an hourly complaint
  about ordinary team ownership and is muted within a day. The mapping is what tells the two
  apart, which is why this ticket depends on ticket 1's reader rather than on the raw address.
- Ordering against ticket 5 is real: this reads `plan-units.sh` directly, so it does not need
  ticket 5's field — but landing 5 first means the fact is visible in the run report while this
  step is still being written. Kept as a `depends_on` for that reason, not a technical one.

## Final Report

Development completed as planned, with one named departure from the ticket's Key Files —
stated here because a later reader must not have to guess which of two statements is stale.

`step-undrivable-units.sh` reads the ownership chain, resolves each owner through
`identity.sh`, and hands every artifact owned by an address **no entry names** to the check-in
as a question addressed to the direction's assignee, keyed `undrivable-unit:<artifact path>`
so the asked-once gate, the per-tick cap, the quiet hours and the working-day hold all apply
unchanged. It is registered in `run.sh` between `stalled-units` and `closable-missions`, and
`/moderate`'s step count and both documents moved with it.

**The departure.** The ticket names `plan-units.sh` as "the reader (a pure read)". It is not
one: the survey reaches the mission readers, which carry this repository's living migrations
and **stage** what they converge — the same composition `step-closable-missions.sh` refused,
for the reason its own header records (*a step whose contract is writes nothing may not reach
it through something that writes*), caught by that step's test leaving a modified mission in
the index. The ticket's stated intent — step 4, *it asks and nothing else* — and the recorded
ruling agree with each other and against its Key Files, so the candidate set is derived from
the readers the survey itself uses for ownership (`owners.sh` over `identity.sh`), walking
`tickets/todo/` and `missions/active/` directly. No ownership rule is re-implemented; only the
enumeration is. The suite asserts the step reaches no writer and leaves the index untouched.

A second, smaller departure with the same cause: the finding is about the **repository**, not
the runner, so the runner's identity is never consulted. An owner no entry names is undrivable
by every account, and this tick is repository-scoped — one copy for the whole team — so keying
it on `owns.sh`'s three-way answer would make an hourly repository-wide question answer
differently depending on which container asked it.

Run against this repository the step names exactly the seven artifacts the mission's own
feedback record measured.

### Discovered Insights

- **Insight**: the summary must be stable across ticks with unchanged state, and that is a
  correctness requirement rather than a preference — the moderation root calls a step changed
  when its summary differs from the same step's an hour ago, and normalises out only a
  timestamp, a bare hex object name and a clock time.
  **Context**: `step-stalled-units.sh` records the measurement (`oldest stopped 27h` marked it
  changed hourly by construction). Any counter that can move without the finding moving has
  the same effect, so the summary carries counts of the finding and nothing else.

- **Insight**: a step that asks about a colleague's ordinary queue is muted within a day, and
  the asked-once ledger then delivers the one real finding inside a stream a person has learned
  to skip.
  **Context**: this is the same reasoning that made `superseded` claims a counted fact rather
  than a question in `stalled-units` three days earlier. The narrowing is not politeness; it is
  what keeps the question layer worth reading at all.
