---
created_at: 2026-08-29T15:24:20+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Drill the silent act offline and register the drill

## Overview

PROPOSED. The first ticket's reproduction proves the defect once; this ticket turns
it into a standing drill that fails whenever a green run stands in for an act that
did not take effect, and registers it so `verify-all` and the `Loop Drills` CI leg
carry it on every push.

The drill must be written against the **behaviour**, not a return shape: a refactor
that keeps the JSON and loses the effect reading has to fire it. That is what the
register calls a `bearing: "breaker"` row, and a drill without one is counted
`unproved`.

## Policies

- `workaholic:implementation` / `policies/testing.md` — a test that cannot fail proves nothing
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/e2e/loop-drill.sh` — the dispatcher; the new verb's `case` arm is what `verify-all`
  derives its set from
- `docs/loop-drill-runbook.md` §9 — the drill register, one table, read by `drill-register.sh`
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check run is named
  after the drill
- `scripts/test-workflow-scripts.mjs` — fails on a drill the register does not classify

## Implementation Steps

1. **Promote the first ticket's reproduction to a drill verb** over a bare local origin with the
   transport stubbed and **no network** — the property that lets it run on the hermetic CI leg with
   no credential.
2. **Drill both causes**, because both are instances of the same failure and the repair of one must
   not hide the other:
   - a turn whose candidate reading yielded nothing while the tree proves candidates stand;
   - a turn whose act was refused by one of its own words.
   Each must produce a named reading and reach the claim holder's question exactly once.
3. **Drill the changed-refusal narrowing**: two ticks with one word, then a third with a different
   word — one question, none, one.
4. **Write the breaker row against the behaviour.** Restore the inference — answer `taken` from a
   completed run's existence — and the drill must fail. A breaker written against the return shape
   would pass a refactor that keeps the shape and loses the bound, which is the failure the register
   exists to catch.
5. **Register the drill** in `docs/loop-drill-runbook.md` §9 with its classification (hermetic) so
   `verify-all` runs it and the CI matrix gains its leg. An unclassified drill is
   `skipped:unclassified` and the suite fails on it — do not leave it so.
6. **Add the failure-reason → file blame row** the runbook keeps beside the register, so a red leg
   points at the file to open.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The drill passes on the repaired tree and fails on a tree where the `taken` inference is restored.
- It runs with no network, no credential and no `gh`, and is classified hermetic in the register.
- `verify-all` includes it and `Loop Drills` gains a matrix leg named after it.
- It carries a `bearing: "breaker"` row, so it is not counted `unproved`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh <the new verb>` passes; the same run with the breaker applied exits
  non-zero.
- `sh scripts/e2e/loop-drill.sh verify-all` names the drill in its verdict list.
- `node scripts/test-workflow-scripts.mjs` passes, including the register-classification check.

**Gate** — what must pass before approval:

- The drill leaves nothing outside its fixture written — no ref, no file, no network call.

## Considerations

- **A drill is not the mission's answer, and the ask says so**: `verify-ci-retirement` is green
  today while the act it drills does not take effect in the world. This drill is admissible because
  it is written against the **effect**, not against the mechanism inside a fixture — if it were the
  latter it would be the rival move the ask already refused.
- The breaker must be applied to the real code path, not to a copy, or it proves the copy.
- Two causes mean two rows; resist collapsing them into one, since the repair of one is exactly
  what would silently drop the other.
