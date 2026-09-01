---
created_at: 2026-09-01T12:33:57+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: adjust-the-plan-hourly-not-only-report-it
merge_policy:
verification_handoff: 
---

# Name a mission at full acceptance with tickets left

## Overview

PROPOSED. `closable-missions` closes the one outcome that is arithmetic: acceptance fully
checked, nothing unlinked, queue empty. A mission at **full acceptance with tickets still
queued** fails the queue term, so it is closed by nobody and stays active indefinitely —
measured on the day this was filed. Whether those leftovers are work that still matters or work
the mission's own landed changes have mooted is a **judgement**, so the loop may not close it
and may not retire them. What it can do, and does not, is say so.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-closable-missions.sh` — the existing close, and where the near-miss is currently invisible.
- `plugins/workaholic/skills/mission/scripts/progress.sh` / `queue-size.sh` — the two terms; this ticket is about the case where the first clears and the second does not.
- `plugins/workaholic/skills/moderate/reference/workflow.md` — the step's spec and question contract.

## Implementation Steps

1. Show the case exists on this repository: find a mission whose acceptance is fully checked
   with `unlinked: 0` and whose queue is non-empty, and confirm no step names it today.
2. Add it as a **question**, not an act: the step already re-proves candidates in a publish
   tree and closes only what is arithmetic; this names the near-miss and asks the mission's
   owner whether the leftovers still matter.
3. Compose the question to the standing contract: **lead with what happened** in words a
   reader outside the repository understands, the identifier after it, and name the **one act**
   asked of the addressee. The mission slug and the ticket count ride the heading.
4. Key it per subject through `lib/question-id.sh` so one mission costs one question however
   many ticks see it, and attach the condition's age through `lib/read-age.sh` as the sibling
   steps do — the reader's words verbatim, an unreadable age named as unreadable.
5. **Nothing is closed, retired, abandoned or moved by this ticket.** `close.sh` stays the only
   writer of an end state and `archive.sh` still closes only `achieved`; the leftovers are
   named and left exactly where they are.
6. Degrade by name: an unreadable `progress.sh` or `queue-size.sh` is not a proof and yields no
   candidate, matching the existing step's own rule that an unreadable reader leaves the
   mission alone.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission at full acceptance with queued tickets produces exactly one question, once.
- Nothing is closed, retired or moved by the step in this case.
- The question names the mission, the leftover count and the one act asked.
- An unreadable reading yields no candidate and is named.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — candidate selection and the no-write assertion.
- The step run against a fixture mission in exactly that state.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **The ask wants more than this ticket gives, and that is deliberate.** It asks that the
  planner "close a mission, merge two, retire a ticket that landed work has mooted". Closing
  on arithmetic already happens. *Merging two missions* has no writer and asserts intent;
  *retiring a mooted ticket* requires judging that landed work covered it, which is a reading
  about behaviour rather than a file test — the repository has refused exactly that shape
  before. Both would need their own measured ask; naming the case is the honest first step and
  is what unblocks a person today.
- The human question budget is ten a day and already contended. This adds one key per stuck
  mission, which on the measured day would have been a small number — but if it is not, that
  is evidence for ticket 6's post rather than a reason to widen the cap here.
