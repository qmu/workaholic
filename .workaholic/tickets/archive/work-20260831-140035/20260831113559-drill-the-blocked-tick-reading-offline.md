---
created_at: 2026-08-31T11:35:59+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-an-unattended-tick-from-waiting-on-a-person
merge_policy:
verification_handoff: 
---

# Drill the blocked-tick reading offline

## Overview

The reading this mission adds fires only when a tick dies — the rarest path there is, and
the one nobody will exercise by hand. Prove it offline, with a breaker written against the
behaviour rather than the return shape.


## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher's `case` arms, which `verify-all` derives
  its set from.
- `docs/loop-drill-runbook.md` §9 — the drill register; an unclassified drill is
  `skipped:unclassified` and the suite fails on it.


## Implementation Steps

1. Add `verify-blocked-tick` over a throwaway repository: run a tick, kill it after the
   opening persist, and prove the base carries the opening.
2. Prove the next tick names it exactly once across two ticks, that a complete previous
   section produces no question and no event, and that an unreadable log is `degraded` by
   name and asks nobody.
3. Add a **breaker** row written against the **behaviour**: remove the early persist and
   the row must fire, because the base then carries nothing to notice.
4. Keep it hermetic — no network, no `gh`, no Slack post — so it joins the set
   `.github/workflows/loop-drills.yml` runs on every push.
5. Register it in §9 in the same commit, with its classification.


## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-blocked-tick` passes, makes no network call and
  needs no credential.
- Its breaker row is proved able to fail on the real script's source.
- The register classifies it and `verify-all` includes it; it is not `unproved`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-blocked-tick`
- `sh scripts/e2e/loop-drill.sh verify-all`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- Registered in §9 in the same commit as the drill itself.


## Considerations

- Killing a tick mid-run inside a drill needs a deterministic stopping point; use the
  step boundary the early persist already creates rather than a timeout, or the drill
  passes or fails by how fast the machine is.


## Final Report

Development completed as planned. `verify-blocked-tick` drills both halves together, because
neither is worth anything alone: eight load-bearing rows prove that a tick stopped after its first
step leaves its opening on the base, that the tick before last is named exactly once with its own
key, that a complete previous section is silent, that the question fires once across two ticks
through the existing gate, that an unreadable log is `degraded` by name and asks nobody, that a
repository with no log is `skipped` rather than degraded, and that nothing outside the fixture is
written. It is hermetic — a **bare local origin** (a `git push` to a file path needs no network),
the log written through `log-append.sh`, the real writer, and no `gh`, Slack or credential — so it
joins the set CI runs on every push, and it is registered in `docs/loop-drill-runbook.md` §9 in the
same commit.

**The stopping point is the step boundary, not a timeout**, exactly as the ticket asked: a tick is
"killed" by running it with `--only open-log`, which is precisely the state a tick that died after
its first step leaves behind, so the drill cannot pass or fail by how fast the machine is.

The breaker is written against the **behaviour**: the opening persist is disabled in a copy of
`run.sh` and the base must then carry nothing for that tick. It fires.

**One neighbouring drill needed a one-line correction**, found by running the set: `verify-moderate`
derives its expected log-line count from `run.sh`'s `STEPS` plus one for the closing persist, and
there are now two persists. It derives `+ 2`.

### Discovered Insights

- **Insight**: `log-read.sh` answers `read: false` for exactly one condition — a missing log
  directory — which is the *healthy* `skipped` case, not a degradation.
  **Context**: the first fixture for "an unreadable log" made `moderations` a file and got
  `skipped`/`no_log_area`, which is correct behaviour and proved nothing. The reachable degradation
  is a reader whose output the step cannot parse, and the drill exercises that instead. A drill
  asserting a branch the code cannot reach is worse than no drill.
