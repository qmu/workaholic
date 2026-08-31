---
created_at: 2026-08-31T11:31:18+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: notice-a-periodic-artifact-that-stopped-being-produced
merge_policy:
verification_handoff: 
---

# Read whether a declared cadence is current

## Overview

One reader answers, per declared cadence, whether its newest artifact is younger than
its period allows. It writes nothing and decides nothing about who to tell — that is the
step's job — and it must never render a read it could not make as a lapse, which is the
one way this reading can do harm.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- The declaration the previous ticket settled — read through whatever single reader that
  ticket established, never re-parsed here.
- `plugins/workaholic/skills/strategy/scripts/attributed-work.sh` — the shape to copy for
  a degraded read: `readable: false` with a named reason and **null** counts.


## Implementation Steps

1. For each declared cadence, resolve its pattern to the **newest** matching artifact and
   compare its age against the declared period.
2. Answer per cadence: `current`, `lapsed` (with the age and the period), or
   **`unreadable`** with a named reason and a **null** age — never a zero and never
   `lapsed`, because a wrong `lapsed` sends a person after a routine that is working.
3. A repository with **no** declaration answers an empty set with a named empty reason,
   which is a real answer and not a degradation — the `no_log_source` split
   `step-workload-logs.sh` already draws.
4. Write nothing, touch no artifact, make no network call, and stage nothing: this is a
   pure read of the tree.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A cadence whose newest artifact is older than its period reads `lapsed` with the age
  and the period; a current one reads `current`.
- An unresolvable pattern reads `unreadable` with a named reason and a null age.
- No declaration yields an empty set with a named reason, exit 0.
- The script writes nothing and stages nothing.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh scripts/e2e/loop-drill.sh verify-cadence-lapse`

**Gate** — what must pass before approval:

- One reader; the declaration is not parsed a second time anywhere.


## Considerations

- The period's grain (hours or days) follows from the declaration's shape and should be
  whatever the previous ticket settled, not re-decided here.
- "Newest matching artifact" is a filesystem read, not a git read: a file restored from
  history is current for this purpose, which is the honest answer to *is it still being
  produced* only if the producer writes into the tree. Say so rather than assuming.


## Final Report

Development completed as planned, with one deviation recorded below. `cadence-state.sh` is the
one reader: it composes the declaration the previous ticket settled, resolves each pattern to
the newest artifact and answers `current`, `lapsed` (with the age and the period) or
`unreadable` with a named reason and a **null** age. A repository declaring nothing answers an
empty set with `empty_reason: no_cadence_declared`, exit 0. It writes nothing, stages nothing
and makes no network call.

**The deviation, and the measurement behind it.** The ticket's Considerations framed "newest
matching artifact" as a filesystem read. That is useless in the environment this runs in: a
routine's container is a fresh clone and git stamps every checked-out file with the checkout's
own time. Measured 2026-08-31 inside a routine container on this repository — 1843 files
carrying the image's bake date and 481 the freshen's, with
`.workaholic/moderations/2026-08-26.md` showing an mtime of that morning — an mtime reading
answers `current` for every cadence, always, which is the same silent failure this mission
exists to fix. The age is therefore the newest **commit** that touched the pattern. The
ticket's caveat inverts and is stated in the script's header rather than assumed.

### Discovered Insights

- **Insight**: file mtimes carry no information in a routine-fired container; every file in the
  checkout shares one of two timestamps (the image bake and the freshen).
  **Context**: any future reading tempted to use `mtime`, `find -newer` or `stat` to answer
  *how old is this* will read as *brand new* in production and be correct only on a developer's
  own machine. Git commit time is the only age that survives a clone.
