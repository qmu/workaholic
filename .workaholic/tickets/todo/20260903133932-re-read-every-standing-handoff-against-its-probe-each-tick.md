---
created_at: 2026-09-03T13:39:32+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: make-a-verification-handoff-a-probe-re-run-at-claim-time
merge_policy:
verification_handoff: 
---

# Re-read every standing handoff against its probe each tick

## Overview

A declaration that has gone false must be named the hour it goes false, not the next time
somebody happens to claim the unit. `/moderate` already asks about every `awaiting_verification`
claim; this ticket makes that step re-probe rather than re-read the sentence.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/moderate/scripts/step-handoff-units.sh` — the `handoff-unit` question's step
- `plugins/workaholic/skills/moderate/reference/workflow.md` — that step's spec and its question wording
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` — supplies the `awaiting_verification` rows
- `plugins/workaholic/skills/drive/scripts/run-verification-probe.sh` — the runner this step composes

## Implementation Steps

1. In `step-handoff-units.sh`, run the probe for each `awaiting_verification` candidate through
   the runner — composed, never re-derived — and carry its answer onto the candidate.
2. **Bound the work**: at most `WORKAHOLIC_HANDOFF_PROBE_MAX` (default 5) probes per tick,
   the rest counted rather than cut, and the step reports the bound it hit. A tick that runs no
   probe because the bound was spent says so.
3. A candidate whose probe now reads **`clean`** is the finding this whole mission exists for:
   the question says the declared blocker no longer holds and names the one act — re-claim the
   unit. Compose it to the question contract: lead with what happened, the identifier after it,
   the verdict word never alone.
4. A candidate still `blocked` keeps today's question, now naming the probe's output and its
   exit status instead of only the sentence.
5. `unmeasured` and `unprobeable` keep today's wording and are counted; an `unreadable` probe is
   named as unreadable and the step reports `degraded` with that reason — never as *nothing
   changed*, which is the collapse this mission is removing.
6. The step still **asks and nothing else**: it claims nothing, merges nothing, re-drives
   nothing and stamps no frontmatter. Update its row in `moderate/reference/workflow.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Each `awaiting_verification` candidate carries a re-probed answer, up to the stated per-tick bound, with the remainder counted.
- A candidate that now probes clean produces a question naming that fact and the one act asked for.
- An unreadable probe reading is reported as degraded and never as an unchanged handoff.
- The step writes nothing and touches no claim.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — rows over a newly-clean candidate, a still-blocked one, an unmeasured one and a degraded read.
- `sh scripts/e2e/loop-drill.sh verify-all` — a breaker row written against the newly-clean behaviour.

**Gate** — what must pass before approval:

- No question key changes, so nothing already asked is re-asked by this change.

## Considerations

- This runs probes on the tick's own schedule, which is a cost per tick that no other
  `/moderate` step pays. The per-tick bound is what keeps it proportionate, and the bound is
  declared rather than tuned silently.

## Final Report

**Outcome**: implemented.

`/moderate`'s `handoff-units` step re-probes per candidate rather than re-reading the sentence, and
its spec in `moderate/reference/workflow.md` states the four readings: **`clean`** — the declaration
has gone false, and the step **says so** and asks the claim holder to take the unit back into the
ordinary route; **`blocking`** — unchanged, but the question quotes the probe's own output and exit
status; **`unmeasured`** — the question is exactly what it was, with the class named; **`unreadable`**
— named as unreadable and never as `clean`.

**The step still asks and does nothing else.** It clears no handoff, merges nothing and touches no
claim — the bound every step there carries. That is not a gap: the next `/implement` claim re-derives
the same `clean` and proceeds on it by itself, so the repair happens on the acting path rather than
in the asking one.

**Why a re-probe rather than the next claim**: a declaration that has gone false must be named the
hour it goes false, not the next time somebody happens to claim the unit — which for a parked unit is
never, since `awaiting_verification` excludes it from the offer. That circularity is what kept four
measured pull requests parked.

**Cost stated**: one bounded probe per `awaiting_verification` candidate, capped at 60s; a tick with
no such claims runs none, which is the ordinary hour.

**Verified**: `node scripts/test-workflow-scripts.mjs`.
