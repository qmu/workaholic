---
created_at: 2026-08-27T20:21:18+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: ask-for-the-one-act-a-declared-handoff-is-waiting-on
merge_policy:
verification_handoff: 
---

# Add the moderate step handoff-units

## Overview

PROPOSED. `awaiting_verification` appears nowhere outside `drive/` — no `/moderate` step reads
it, so a unit the loop declared it cannot verify reaches a person through nothing at all.
Measured 2026-08-27: three units parked on a human act, queued since 2026-08-18, 2026-08-19 and
2026-08-26, each naming its own blocker in its own ticket, none mentioned to the account holder
since the hour it routed.

`step-handoff-units.sh` hands every `awaiting_verification` claim to the check-in as a question
addressed to the **claim holder**, keyed `handoff-unit:<unit>` so it is asked exactly once,
quoting the declared reason from the previous ticket's reading. It asks and nothing else.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — a degraded read is reported by name, never as a step that found nothing

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-undelivered-units.sh` — the template on
  every axis: candidate filter on `resume_reason`, per-candidate lookup, `needs_agent` shape,
  the `emit` helper, and the header that states which sibling it follows on which axis.
- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — NEW.
- `plugins/workaholic/skills/moderate/scripts/run.sh` — `STEPS` (line ~70) is the ordered step
  list and the log's step keys; the new id goes in it.
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — the candidate source; a pure read.
- `plugins/workaholic/skills/moderate/scripts/ask-question.sh` — the asked-once ledger the key
  is spent through; the per-tick cap, quiet hours and working-day hold all apply unchanged.

## Implementation Steps

1. Write `step-handoff-units.sh` on `step-undelivered-units.sh`'s shape: read `list-claims.sh`
   once, refuse a degraded scan by name (`no_claim_reader`, `claims_unreadable`,
   `claims_unparseable`, `origin_unreachable`, `shallow_history`), and filter candidates on
   `resume_reason == "awaiting_verification"`.
2. Resolve each candidate's declared reason and pull request through the previous ticket's
   reading — one lookup per candidate, an unanswerable read leaving coordinates unstated.
3. Emit `needs_agent` with `key: "handoff-unit:" + unit`, the owner (the claim's `author`), the
   declared reason verbatim, and a `compose` line that says the unit is finished as far as the
   loop can take it and names the one act it waits on. Address it to the **claim holder**;
   never consult the running identity.
4. Summary counts every claimed unit and names how many are awaiting verification. It carries
   **no age and no timestamp** — the root's change diff normalises only a timestamp, a bare hex
   object name and a clock time, so an age would make the step changed hourly by construction
   (`step-stalled-units.sh`'s header records the measured failure).
5. Register the step in `run.sh`'s `STEPS`, beside `undelivered-units`.
6. It reads `list-claims.sh` and never `plan-units.sh`: the survey reaches the mission readers,
   which carry the living migrations and **stage** what they converge, and a step whose contract
   is *writes nothing* may not reach it through something that writes.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Every `awaiting_verification` claim produces exactly one question, addressed to the claim
  holder, carrying the declared reason verbatim
- A second tick over the same unit asks nothing (the `handoff-unit:<unit>` ledger key)
- The step writes nothing anywhere but its own tick-log line, and touches no claim
- A degraded claim scan asks nothing and is reported by name
- `run.sh` invokes it and it contributes a report line on every tick

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `sh plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh --tick <id>` over a
  fixture holding one `awaiting_verification` claim
- `grep -n plan-units plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — empty

**Gate** — what must pass before approval:

- The hermetic suite passes, and the step is provably read-only

## Considerations

- The step follows `stalled-units` on **whose** question it is (the holder drove the unit and
  can run the verification or hand it on) and `undrivable-units` on the other two axes — the
  running identity is never consulted, and the survey is never read. State that in the header.
- It asks and never acts. Nothing here clears a handoff, retries a verification, merges the
  pull request or withdraws the declaration: `awaiting_verification` is a **judgement**, and a
  consumer may only report it or ask about it.

## Final Report

`step-handoff-units.sh` written on `step-undelivered-units.sh`'s shape: one `list-claims.sh`
read, every degraded scan refused by name (`no_claim_reader`, `claims_unreadable`,
`claims_unparseable`, `origin_unreachable`, `shallow_history`), candidates filtered on
`resume_reason == "awaiting_verification"`.

- **The reason and the pull request** come from the previous ticket's reading
  (`drive/scripts/declared-handoff-detail.sh`) — one resolution per candidate; an
  `unanswerable` lookup leaves the coordinates unstated and keeps the candidate.
- **`needs_agent`** is keyed `handoff-unit:<unit>`, addressed to the claim's own `author`, and
  carries the declared reason verbatim. The running identity is never consulted.
- **A candidate whose reason could not be resolved is counted, not asked about** — asking
  somebody to satisfy a verification nobody named is worse than not asking.
- **Summary** counts every claimed unit and how many await a declared verification, with no age
  and no timestamp (`step-stalled-units.sh`'s recorded correctness reason).
- Registered in `run.sh`'s `STEPS` beside `undelivered-units`, and its contract stated in
  `moderate/reference/workflow.md` §21 — a step run.sh drives without one fails the suite.

Verified live against this repository's own claim set: 8 claimed units, 1 awaiting a declared
verification, the question addressed to `a@qmu.jp`, quoting the declared reason verbatim and
linking PR #647 — the measured unit this mission exists for.
`node scripts/test-workflow-scripts.mjs` — 4111 passed, 0 failed.
`grep -n plan-units step-handoff-units.sh` returns only the header line **stating the refusal**,
which is the sibling's own shape; there is no call site.
