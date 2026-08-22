---
created_at: 2026-08-22T18:23:03+09:00
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
