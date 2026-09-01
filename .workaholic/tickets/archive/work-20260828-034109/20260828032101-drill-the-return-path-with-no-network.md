---
created_at: 2026-08-28T03:21:01+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: let-an-answer-in-the-thread-turn-back-into-the-loop-s-work
merge_policy:
verification_handoff: 
---

# Drill the return path with no network

## Overview

**PROPOSED.** One operator-runnable drill that walks the whole return path — ask → reply →
record → file → stamp — over local fixtures with the transport stubbed and **no network at
all**, plus a row that deliberately breaks the seam so the drill is proved able to fail.

This is the shape `verify-residue` and `verify-arrival` already established: a drill lives
in `scripts/e2e/loop-drill.sh` (operator tooling outside the plugin, because it assumes the
server's full `gh` and `qfs`), it is runnable on demand rather than by waiting for a tick,
and it carries a **breaker row** — a fixture that fires the moment the code is wired to the
wrong thing, so a drill that would pass over a broken implementation is caught.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testable-boundaries.md` — drill the seam that ships

## Key Files

- `scripts/e2e/loop-drill.sh` — the drill's home; read `verify-residue` and
  `verify-arrival` in full for the fixture, stubbing and breaker-row conventions.
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file
  blame table this drill must extend.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — the step sequence the drill walks.
- `plugins/workaholic/skills/moderate/scripts/record-answer.sh` — the writer whose effect
  the drill asserts.
- `plugins/workaholic/skills/propose/scripts/file-inbound-ask.sh` — the filer the drill
  stubs at the transport, never below it.
- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the drill complements it and
  does not replace it.

## Implementation Steps

1. **Read `verify-residue` and `verify-arrival` before writing.** The fixture layout, how
   the transport is stubbed, how a git-backed fixture is built and how a breaker row is
   labelled are all settled there; copying the shape is the point.
2. **Add `verify-return-path`** (or the name the drill's own convention selects) walking the
   five stages in order, asserting after each: the coordinate is recorded; the read names
   the right candidates; the answer is recorded and the state reads `answered`; an
   answer that asks for work files exactly one issue; the stamp lands.
3. **Assert the negatives, which are half the contract**: a machine's own reply is not an
   answer; a second tick over the same thread files nothing and stamps nothing; a candidate
   with no coordinate is named rather than searched for; a failed stamp changes nothing.
4. **Carry a breaker row, labelled as the intentional failure.** The natural one: wire the
   read at the **channel** instead of the question's own thread — the mistake that would
   silently reintroduce the history read this design avoids — and assert the drill fails.
5. **No network, and prove it**: the transport is stubbed and the drill makes no `gh` call
   and no Slack call. State this in the drill's header the way the existing drills do.
6. **Extend `docs/loop-drill-runbook.md`** with the procedure and the failure-reason → file
   blame rows, so a failing drill names the file to open.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One drill walks ask → reply → record → file → stamp and asserts each stage.
- The negatives above are asserted, not just the happy path.
- A labelled breaker row proves the drill can fail.
- The drill makes no network call of any kind and creates its fixtures locally.
- The runbook names the drill, its procedure and its blame rows.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-return-path` — passes on a correct tree.
- The same command with the breaker row enabled — fails, naming the seam.
- `node scripts/test-workflow-scripts.mjs` — still green.

**Gate** — what must pass before approval:

- The drill passes, and its breaker row fails, both demonstrated in the branch story.
- No network access is required to run it.

## Considerations

- **The drill is not a substitute for the hermetic pins.** The suite pins the seams; the
  drill proves they compose. Both, and the drill says so in its header.
- A stub that mimics Slack too loosely will pass over a real bug. Stub at the transport
  boundary the code actually calls, and assert the arguments it was called with — a stub
  that accepts anything proves nothing.
