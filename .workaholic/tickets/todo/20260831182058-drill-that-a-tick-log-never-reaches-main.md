---
created_at: 2026-08-31T18:20:58+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: take-the-moderation-tick-s-log-off-main
merge_policy:
verification_handoff: 
---

# Drill that a tick log never reaches main

## Overview

PROPOSED. The second of the ask's two drills, and the regression guard for the
whole mission: one that **fails when a tick log reaches `main` again**. Ticket 7
proves the log arrives where it should; this proves it does not arrive where it
should not. They are different failures — a change could satisfy the first and
still write to both — so they are different drills, which also lets
`/moderate`'s `drill-health` step name which property broke.

This is the drill that gives the mission a life beyond its own merge. The
behaviour being guarded is easy to reintroduce by accident: any future caller that
composes `publish-tree-commit.sh` with a `.workaholic/moderations/` path, or a
merged branch that carries a day file, puts the log back on `main` without
anybody noticing until the commit count climbs again.

Same three register rules as ticket 7: classified `hermetic` and measured as
such, a `bearing: "breaker"` row or it is counted `unproved`, and the register row
in the same change or `test-workflow-scripts.mjs` fails it `skipped:unclassified`.

## Policies

- `workaholic:implementation` / `policies/testing-strategy.md` — a proof that cannot fail proves nothing
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — an operational log is read, not reviewed

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher and the new `verify-*` arm.
- `docs/loop-drill-runbook.md` §9 — the drill register.
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — its one reader.
- `.github/workflows/loop-drills.yml` — the per-drill matrix leg.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the whole tick, whose
  every write this drill inspects.
- `plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh` — the seam
  a regression would most likely come back through.

## Implementation Steps

1. Build a fixture that runs a whole tick — not just the persist — against a
   throwaway repository with a local bare `origin`, no network, no `gh`, no
   credential.
2. Assert the property directly on the tree, not on a script's return value:
   after the tick, no commit reachable from the base branch touches
   `.workaholic/moderations/`. Deriving the assertion from git is what makes it
   survive a refactor of the scripts it guards.
3. Assert it over the whole run, so a write from **any** step is caught, not only
   from `persist-log.sh`.
4. Keep the one legitimate base write visible and passing: the feedback records
   ticket 3 keeps on `main`. The drill must distinguish a record commit from a log
   commit, or it will fail the intended design.
5. Add the register row in the same change — `hermetic`, `Breaker: yes`, this
   mission's slug.
6. Write the breaker against the behaviour: a build whose persist writes the day
   file to the base. The drill must fail against it.
7. Confirm the CI matrix leg is named after the drill, so `drill-health` can name
   it to a person.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- After a full drilled tick, no commit on the base branch touches
  `.workaholic/moderations/`, and the drill asserts this from git.
- A tick that writes a feedback record still passes the drill.
- The breaker fails the drill.
- `hermetic` is measured (no network, no `gh`, no credential, twice), not
  asserted; the register carries the row and the drill is neither
  `skipped:unclassified` nor `unproved`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-all`
- The drill run twice with `PATH` stripped of `gh` and no proxy.
- `node scripts/test-workflow-scripts.mjs`
- `git log --oneline <base> -- .workaholic/moderations/` inside the fixture,
  asserted empty for the drilled range.

**Gate** — what must pass before approval:

- The breaker was run and observed to fail the drill, **and** the record-commit
  case was run and observed to pass it. A drill that fails the intended design is
  worse than none.

## Considerations

- Depending on ticket 5's ruling, `main` may still carry the historical day
  files. Scope the assertion to the drilled range — commits the tick itself made —
  not to the whole history, or the drill fails on a repository that kept its
  archive.
- This drill is the mission's acceptance made mechanical. If it cannot be written
  hermetically, say so loudly rather than downgrading it to `needs_server`, where
  CI never runs it and it guards nothing.

## Final Report

Development completed as planned. `verify-log-off-main` ships with its register row, its CI
matrix leg and a breaker that was run and observed to fail the drill.

Five load-bearing rows, all passing:

1. **A whole drilled tick** — `run.sh`, not just the persist — then the assertion taken
   straight off git: no commit the tick added to the base touches `.workaholic/moderations/`.
   Deriving it from git is what makes it survive a refactor of the scripts it guards, and
   running the whole tick is what catches a write from **any** step.
2. The tick really did log (to the ref), so row 1 is not passing because nothing ran.
3. **The one legitimate base write still passes**: a tick that wrote a feedback record lands
   it on the base while its log still does not. A drill that failed the intended design would
   be worse than none.
4. The breaker.
5. Nothing was written outside the fixture.

**Scoped to the drilled range.** Ticket 5 ruled the historical day files stay on `main`, so
the assertion covers only what the tick itself added — `<seed>..main` — not the whole
history, which would fail on any repository that kept its archive.

**`hermetic` is measured, not asserted**: run twice with `gh` shimmed to exit 127, no proxy
and no `ANTHROPIC_API_KEY`; identical row counts both times.

### Discovered Insights

- **Insight**: the honest breaker for this property is not a mangled publisher but **the
  regression itself** — a caller that composes `publish-tree-commit.sh` with a
  `.workaholic/moderations/` path, which is exactly what the closing act did before this
  mission. It uses the real publish-tree seam, so it cannot pass against a shape the seam
  never produces.
  **Context**: the first attempt (a copy of the publisher pushing to `refs/heads/main`) put
  nothing on the base, because the log commit is an orphan and the push was rejected as a
  non-fast-forward. A breaker has to actually commit; recorded in the runbook.

- **Insight**: keeping the record-commit row is what stops this drill from being a trap. The
  mission deliberately leaves one base writer in the tick, and a drill asserting "no base
  commit at all" would have gone red on the intended design the first time a tick filed a
  finding.
  **Context**: it also pins the split from ticket 3 mechanically rather than only in prose.
