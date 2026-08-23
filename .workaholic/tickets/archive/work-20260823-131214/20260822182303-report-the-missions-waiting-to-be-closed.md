---
created_at: 2026-08-22T18:23:03+09:00
status: done
author: a@qmu.jp
assignees: 
depends_on:
mission: close-a-mission-the-run-can-prove-is-finished
merge_policy:
verification_handoff: 
---

# Report the missions waiting to be closed

## Overview

The sibling ticket closes a mission at the archive gate. That seam only fires when a run archives
the mission's last ticket, so it cannot catch a mission that reached full acceptance any other way
— items ticked by a different seam, a mission whose tickets were archived before the seam shipped,
or one finished on a branch that never ran the gate.

Eleven such missions had accumulated. Nobody was told. They were discovered because the mission
lens printed all of them on every prompt and the list had grown long enough to read as wrong.

The gap this ticket closes is the reporting one: **an accumulation must be visible before it is
large**. This is the ask's own stated alternative, kept as an addition rather than a substitute —
the seam handles the ordinary case, and this makes the residue legible instead of silent.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/mission/scripts/progress.sh` — the arithmetic each mission is judged
  by; the report composes it, never reimplements it.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — already walks every active mission and
  already knows which have queued tickets; the set is a projection of what it reads.
- `plugins/workaholic/skills/story/scripts/area-freshness.sh` — the precedent for a reporting-only
  upkeep seam read by `/story`: it reports mechanical facts and never writes.
- `plugins/workaholic/skills/moderate/scripts/run.sh` and its `step-*.sh` — the other candidate
  home; a step there contributes one report line.
- `plugins/workaholic/skills/drive/SKILL.md` §7 — where a run's own leftovers are reported.

## Implementation Steps

1. **Reproduce.** Put a mission into full acceptance without archiving a ticket through the gate,
   and confirm nothing anywhere names it.
2. Decide the home and record why: `/story`'s reporting backstops (beside `area-freshness.sh`,
   which is the exact precedent — reports, never writes) or a `/moderate` step. Prefer the one
   whose audience is the person who would act on it; a tick step is seen hourly, a story is seen
   at merge.
3. Compute the set by composing `progress.sh` and the survey's own queue read — no new parser of
   the `mission:` relation, which `read-relation.sh` owns.
4. Report each entry with the two facts that make it closable (`checked/total`, queued count) and
   nothing else. **Never close one from here**: this reports, it does not write — the sibling
   ticket owns the one case a machine may end.
5. Report a degraded read by name rather than as an empty set, the standing rule for every reader
   in this plugin.
6. Update the owning skill's `SKILL.md` and `CLAUDE.md` in the same commit.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A mission at full acceptance with an empty queue that the seam did not close is named, with its
  `checked/total` and queued count.
- The report writes nothing — no file, no commit, no status.
- A mission with unmet acceptance or a non-empty queue is absent from the set.
- An unreadable mission area is reported by name, never as an empty set.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A hermetic fixture with three missions (closable, unmet acceptance, queued) asserting exactly
  one entry.
- `git status` clean after the report runs.

**Gate** — what must pass before approval:

- All four criteria hold and the suite is clean.

## Considerations

- Drive this after its sibling: with the seam in place the set is normally empty, which is the
  state the report should be tuned against. Tuning it against today's eleven would make an
  ordinarily-silent report look like a list.
- Resist making this close anything, even when the arithmetic is identical to the sibling's. Two
  writers of an end state is exactly what `close.sh`'s single-writer rule exists to prevent.

## Final Report

Development completed as planned. `moderate/scripts/step-closable-missions.sh` is step 12 of the
tick: it names every active mission whose acceptance is fully checked with nothing queued, with
its `checked/total` and queued count, and **never closes one**.

### The home, ruled: this tick, not `/story`

`story/scripts/area-freshness.sh` is the exact precedent for a reporting-only upkeep seam and was
the real alternative. This tick wins on audience and on shape, and the ticket asked for the reason
to be recorded:

- **The residue accumulates over time, not at a merge.** A per-merge report names it only when
  somebody happens to merge something unrelated — which is precisely how eleven went unseen.
- **Closing a mission is the operator's act**, and this is the surface that reaches an operator
  hourly and keeps a dated log of what it saw.
- **It is silent by construction when the set is empty**: it contributes a report line and never a
  question, and the tick posts only when it has a question to ask. Tuning against today's residue
  would have made an ordinarily-silent report look like a list, which the Considerations warned of.

### The composition changed mid-drive, and the step's own test is why

The first implementation read the survey's `queue_drained` exclusion — the obvious composition,
and exactly this candidate set. The test then caught the report leaving
`M .workaholic/missions/active/<slug>/mission.md` in the index: `plan-units.sh` runs the living
migrations and **stages** what they change. A step whose contract is *writes nothing* may not
reach it through something that writes, so the set is now composed from three pure readers —
`summary.sh` (the active set with `checked`/`total`), `progress.sh` (`unlinked`) and
`queue-size.sh` (the queue count, which is the number `plan-units.sh` itself reads). Still no new
parser of the many-valued `mission:` relation.

**One exception to "writes nothing" is stated rather than hidden**: on a non-conformant tree — a
mission outside `active/`/`archive/`, or one carrying a legacy `status:` — the mission readers'
living migration converges it and stages the change, as any other mission-script touch does. That
is the migration's contract, not this step's behaviour; on a converged repository the index is left
byte-identical, which the test now asserts on a conformant fixture.

### It reports and never closes

Even though the arithmetic is identical to the sibling's. Two writers of an end state is exactly
what `close.sh`'s single-writer rule exists to prevent, and the sibling owns the one case a machine
may end. A degraded read is named (`missions_unreadable`, `missions_unparseable`,
`no_mission_reader`) and never rendered as an empty set; a mission whose progress cannot be read is
skipped rather than reported closable, and the scanned count says the rest.

**Measured live while driving it**: run against this repository it named exactly the two missions
completed today that were sitting `active` — `2 mission(s) finished and still open, of 9 active`.

**Verification**: `node scripts/test-workflow-scripts.mjs` — 3375 passed, 0 failed, with a
three-mission fixture (finished-and-open, unmet acceptance, still-queued) asserting exactly one
entry, that the mission stays active, that `git status` is clean afterwards, and that an unreadable
survey is `degraded` by name rather than an empty set.
