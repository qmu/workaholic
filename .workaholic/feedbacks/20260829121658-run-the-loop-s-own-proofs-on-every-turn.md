---
type: Feedback
title: Run the loop's own proofs on every turn
kind: instruction
source: development
subject: observer_ai:[Propose] routine
created_at: 2026-08-29T12:16:58+00:00
author: a@qmu.jp
supersedes: 
---

# Run the loop's own proofs on every turn

The [Propose] routine asks that the loop run its own proofs on every turn, unattended, at the seam it already merges through.

Source: https://github.com/qmu/workaholic/issues/721

## The ask

`scripts/e2e/loop-drill.sh` holds 30 commands, 28 of them `verify-*` — one per mechanism this
direction has built since 2026-08-21. Each was written to be hermetic (no network, a stubbed
transport, a git-backed fixture) and each carries a deliberately broken breaker row asserted to
fail, so the drill's own ability to fail is part of its design.

Nothing runs them. `Validate Plugins` executes exactly two (`verify-specificate`,
`verify-implement`, through the hermetic suite) and relates to seven others only by a regex
presence check, which proves a drill exists and never that it passes. The remaining drills run
only when a person types the command — while the loop merges roughly one mission an hour onto
`main`, and the archive gate closes a mission `achieved` on arithmetic, never on the mechanism
still working.

What must become true:

- The drill has an aggregate verb with a machine verdict per command — `pass`, `fail`, or
  `skipped:<reason>` — running the hermetic set with no key, no network and no `gh`/`qfs`, and
  exiting non-zero only on a real failure. A skip is a named fact, never a silent pass.
- Which drills are hermetic is measured before anything is wired, per drill, rather than assumed
  from their headers.
- The breaker rows are exercised: a drill that has stopped being able to fail is reported as a
  failure, not counted as a pass.
- CI runs the hermetic set on push, and a failure names the mission that shipped the drill.
- `/moderate` reads the last completed run's verdicts and asks a person only about a drill that is
  failing or has gone unrunnable — never a per-tick green line.
- `test-workflow-scripts.mjs` pins the whole path offline and fails when a drill is added that the
  aggregate verb cannot reach, retiring the seven presence regexes.

It adds no field to any artifact, creates no second inbox, and introduces no new gate: the drill
verdict is reported evidence, never a condition on a close, a merge or a claim.

## The experience it demands

A merge that breaks a mechanism an earlier turn proved is caught by the loop itself, on that
merge, and the failure names both the drill and the mission that shipped it. A drill that has
quietly stopped being able to fail is reported as a failure rather than counted as a pass. A
drill that cannot run without the server says so by name and is never mistaken for a green one.
And a person is told only when something is failing — never that everything is fine.

## What it is chosen against

The attribution residue — four active missions and eleven queued tickets belonging to no
direction. Refused because its remaining blocker is a human ruling by design and the path to that
human landed yesterday (`standing-rulings`, `undrivable-units`, `direction-arrived`). The drills
have no route at all.
