---
created_at: 2026-08-27T14:24:44+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827142444-ask-the-operator-once-whether-an-arrived-direction-is-done.md
mission: say-when-a-direction-has-arrived
merge_policy:
verification_handoff: 
---

# Pin that no reading ever closes a direction

## Overview

PROPOSED. The strategy artifact has exactly three writers — `create.sh`, `amend.sh`, `close.sh` —
and `close.sh` has exactly one caller, `/specificate`'s *ended* announcement route. That rule is
**prose today**, and this mission is precisely the change that would tempt a fourth writer: a
reading that says a direction looks finished is one small step from a routine that closes it.

Pin it mechanically. A hermetic test fails when `close.sh` gains a caller outside that route, and
when `step-direction-health.sh` reaches **any** strategy writer at all.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `scripts/test-workflow-scripts.mjs` — the hermetic suite; the existing writer-set pin (which
  already fails on a fourth writer) is the shape to extend.
- `plugins/workaholic/skills/strategy/scripts/close.sh` — the single writer of an end state.
- `plugins/workaholic/skills/moderate/scripts/step-direction-health.sh` — the step under the pin.

## Implementation Steps

1. Read the existing writer-set pin in `test-workflow-scripts.mjs` — the one that fixes the
   strategy writers at `amend.sh`/`close.sh`/`create.sh` — and extend rather than duplicate it.
2. Add a check that the set of files invoking `close.sh` is exactly the `/specificate` *ended*
   route, failing with the offending path named.
3. Add a check that `step-direction-health.sh` invokes no strategy writer — name all three, so a
   later `amend.sh` call is caught as loudly as a `close.sh` one.
4. Prove the pin can fail: deliberately break each half, confirm the failure names the right file,
   restore.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The suite fails when `close.sh` is called from a new file, naming it.
- The suite fails when `step-direction-health.sh` calls any of the three writers.
- The suite passes on the tree as it stands.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- Each half deliberately broken and restored, with the failure output recorded.

**Gate** — what must pass before approval:

- Both halves demonstrated failing, not merely asserted to fail.

## Considerations

- The pin reads call sites textually. That is enough here — a wrapper indirecting the call would be
  the same violation with more moving parts, and worth failing on if it ever appears.
