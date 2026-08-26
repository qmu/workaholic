---
created_at: 2026-08-26T04:20:21+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: attribute-an-inbound-ask-to-the-direction-it-answers
merge_policy:
verification_handoff: 
---

# Decide and report the direction for an ask that names none

## Overview

PROPOSED. Even with both writers stamping the line, an ask can arrive naming no direction
— a human typing into the GitHub UI, another tool, an older issue. Today `/specificate`
reads `read-ask-feedback-refs.sh`, gets `line_found: false`, carries nothing and reports
`carried:none` — honest about the *line* and silent about the *direction*.

The ask asks for one more step, and it costs no new reader: step 5b **already** reads the
`active` strategy set and the `subject: person:` records those strategies cite, for the
operator-record check, and those Aims are already binding on the run. Asking which Aim an
ask falls under adds no reader, no relation and no field to any artifact.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/specificate/reference/workflow.md` — steps 3b, 5b, 7, 9, 10
  and 13, the whole path the decision rides
- `plugins/workaholic/skills/specificate/SKILL.md` — *Carry the ask's own feedback refs
  forward*, where the carry's reporting obligation is stated
- `plugins/workaholic/skills/specificate/scripts/check-carry-floor.sh` — the floor, which
  must keep checking only refs the **ask** carried
- `plugins/workaholic/commands/specificate.md`
- `scripts/test-workflow-scripts.mjs`

## Implementation Steps

1. Add the decision to step 7's judgment, after step 5b: when `line_found` is false, decide
   which `active` strategy's Aim the ask falls under — an explicit slug first, then the
   judgment against the Aims already in hand — or decide none.
2. When a direction is decided, carry **that strategy's** `feedback:` refs onto the emitted
   artifact alongside this run's record, through the same variadic scaffold arguments
   step 3b already uses. No new flag, no new field.
3. Report it on both surfaces beside `carried:`/`dropped:` — the run report line and the
   pull-request body — as `direction:<slug>` with how it was decided (`slug` or `aim`), or
   `direction:unattributed`. A record-only outcome reports the direction it would have
   carried, exactly as it already reports the refs it would have carried.
4. **Leave the floor alone.** `check-carry-floor.sh` proves the *ask's own* resolved refs
   landed; a direction this run judged is a judgment, not a promise the ask made, so
   flooring it would turn a reported reading into a publish refusal.
5. Extend the hermetic suite: an ask with no line and a matching Aim carries that
   strategy's refs and reports `direction:<slug>`; an ask matching none reports
   `direction:unattributed` and carries nothing; an ask **with** a line is unchanged.
6. Update `CLAUDE.md`'s `/specificate` row and rebuild `outputs/`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- An ask with no `feedback:` line that answers a live direction emits work carrying that
  direction's refs, and both surfaces name the decision
- An ask answering no live direction reports `direction:unattributed` and carries nothing
- An ask that carries a line behaves exactly as today, floor included

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`

**Gate** — what must pass before approval:

- `check-carry-floor.sh` is unchanged in behaviour and still keyed on the ask's own refs
- No artifact gains a field; the retired `strategy:` relation does not return

## Considerations

- **The precedence between a line and a judgment**: when the ask carries a line, that line
  wins outright and the judgment does not run. The writer's explicit statement beats the
  reader's inference, and it keeps `/propose`'s path byte-identical.
- A judged direction is weaker evidence than a carried one, which is why it is reported
  with **how** it was decided. A later reader can then tell a stamped attribution from an
  inferred one without a new field.
- An unreadable strategy set at step 5b is already reported by name there; this step must
  not collapse it into `unattributed`.
