---
created_at: 2026-08-29T12:21:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Exercise the breaker rows and report a drill that cannot fail

## Overview

Make a drill that has stopped being able to fail report as a failure rather than count as
a pass. **Measured**: the breaker rows already exist and are already load-bearing — a
drill's breaker row asserts that a deliberately broken copy of the seam produces a
failure, and when the breaker stops breaking that row itself goes `false` and the drill
exits 1. What is missing is **discoverability**: the rows carry no convention. Five are
named `*_breaker` (`checkin_breaker`, `ci_retirement_breaker`, `findings_breaker`,
`reconcile_breaker`, `return_path_breaker`) and about a dozen more are named after what
they assert (`retire_refuses_a_judgement`, `base_health_can_fail`,
`residue_reads_the_active_area`, `catch_up_refuses_a_foreign_claim`, …), so nothing can
answer *which drills have a breaker* or *which have none*. A drill with no breaker is not
failing — it is unproved, and it must not read as green in ticket 2's verdict.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — one convention, single-sourced
- `workaholic:implementation` / `policies/error-handling.md` — an unproved drill is named, never assumed sound

## Key Files

- `scripts/e2e/loop-drill.sh` — the `add_row` contract (`{check, pass, detail, bearing}`)
  and the ~17 rows that today assert a broken copy fails, under no shared name
- `docs/loop-drill-runbook.md` — where the per-drill breaker state is recorded beside
  ticket 1's classification

## Implementation Steps

1. Enumerate the existing breaker rows by reading the drill file, and confirm the claim
   above per drill: which drills assert a deliberately broken copy fails, and which assert
   nothing of the kind.
2. Choose one discoverable marker and apply it to every such row without changing what any
   row asserts — the cheapest is the `bearing` field the rows already carry (a third value
   beside `load`/`advisory`), which needs no rename and no second list. Renaming ~17 rows
   to a `*_breaker` convention is the alternative; it is louder in the source and changes
   every affected drill's output keys, so decide on that trade and record which was taken.
3. Have ticket 2's aggregate verb read the marker: a drill whose breaker row is `false`
   is already `fail` and stays so; a drill carrying **no** breaker row is reported in its
   own right — `unproved`, counted separately and never inside the passing total.
4. Record per drill in the runbook whether it carries a breaker, so the gap is visible to
   a person as well as to the verb.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every drill's breaker rows are discoverable mechanically, with no hand-kept list.
- A drill whose breaker no longer breaks yields `fail` from the aggregate verb.
- A drill carrying no breaker is reported as unproved and is not counted as passing.
- No row's assertion changed: each drill's `pass`/`fail` outcome over an unmodified tree
  is byte-identical to before.

**Verification method** — the commands/tests/probes that prove them:

- The aggregate verb over the unmodified tree, diffed against its pre-change output.
- A drill whose breaker is deliberately neutered, proving `fail` rather than `pass`.
- A drill with its breaker row removed, proving `unproved` rather than `pass`.

**Gate** — what must pass before approval:

- The unmodified-tree diff is empty except for the new marker/report fields, and both
  negative cases above produce the stated verdict.

## Considerations

- The tempting design is a separate breaker harness that re-runs each drill against a
  broken copy. It is refused: the drills already do this inside themselves, and a second
  mechanism would be a second place the two could disagree.
- `unproved` is deliberately not `fail` — a drill nobody wrote a breaker for is a gap in
  coverage, not a broken mechanism, and conflating them makes the failure signal noisy on
  the day it matters.

## Final Report

Development completed as planned.

The claim in the Overview was confirmed by reading the drill file: 19 of the 30 drills
carry a row asserting that a deliberately broken copy of the seam fails, and 11 do not.
Five of those rows were named `*_breaker`; the other fourteen were named after what they
assert (`retire_refuses_a_judgement`, `base_health_can_fail`,
`residue_reads_the_active_area`, `catch_up_refuses_a_foreign_claim`, …), so nothing could
answer *which drills have a breaker* and *which have none*.

**The marker is the `bearing` field the rows already carry** — a third value beside
`load`/`advisory` — applied to all 45 `add_row` call sites of those 19 drills, both
branches of each row. `add_row` treats `breaker` as load-bearing exactly as `load`, so
every drill's `pass`/`fail` outcome over an unmodified tree is unchanged; the only
addition to a drill's own output is the `breakers` count in `emit_verdict`. The
alternative — renaming ~17 rows to a `*_breaker` convention — was refused because it
changes every affected drill's output keys, which the runbook's pasted verdicts and this
repository's own regression suite read, to say something a field says for free.

`verify-all` reads the marker: a drill whose breaker row is `false` was already `fail` and
stays so, and a drill carrying **no** breaker row is reported `breaker: "absent"` and
counted as **`unproved`** — outside the passing total, never inside it. `unproved` is
deliberately not `fail`: a drill nobody wrote a breaker for is a gap in coverage, not a
broken mechanism, and conflating them makes the failure signal noisy on the day it matters.

The per-drill breaker state is recorded for a person in the register's `Breaker` column;
**no code reads that column** — the machine derives it from the rows themselves, so the
column cannot drift into a hand-kept list.

Measured on the unmodified tree: 19 proved, 9 unproved (11 without a breaker minus the two
`needs_server` rows, which are never invoked), 0 failed.

### Discovered Insights

- **Insight**: The breaker rows were already load-bearing and already worked — when a
  breaker stops breaking, its own row goes `false` and the drill exits 1. What was missing
  was never enforcement, only **discoverability**.
  **Context**: The tempting design was a separate harness re-running each drill against a
  broken copy; it is refused because the drills already do this inside themselves and a
  second mechanism would be a second place the two could disagree. The cheap fix was a
  field on a row that already existed.
