---
created_at: 2026-08-29T15:24:15+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: read-back-whether-the-loop-s-own-act-took-effect
merge_policy:
verification_handoff: 
---

# Record what the CI turn attempted and each act answered

## Overview

PROPOSED. The CI executor already produces the answer a later tick needs — the
candidate set with its own `ok`/`reason`, and one
`{"deleted", "unit", "branch", "state", "reason"}` per candidate — and puts it
**only in a job log**. The log is reachable only through a redirect to blob storage
the loop's container cannot follow (measured 2026-08-29: the REST logs endpoint
returns a signed blob URL and the fetch fails), so the verdict is written where no
reading can consult it.

This ticket makes the turn record **what it attempted and what each act answered**,
per candidate, somewhere a later tick can read. The ask's constraint binds: **no new
store, no field on any artifact, no second oracle** — the record must ride the run
the tick is already reading.

## Policies

- `workaholic:implementation` / `policies/observability.md` — an act's outcome must be readable
- `workaholic:operation` / `policies/delivery.md` — CI is the executor where the write is permitted
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `.github/workflows/claim-retirement.yml` — the turn; today it `cat`s the candidates and loops
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act, already
  emitting a closed-vocabulary `state`/`reason` per candidate and always exiting 0
- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader whose
  own `ok`/`reason` must be recorded too (a `[]` with a reason is an attempt outcome)
- `plugins/workaholic/skills/drive/scripts/ci-retirement-turn.sh` — the consumer the next ticket
  reworks; named here only so the record's shape is chosen for it

## Implementation Steps

1. **Choose the surface the run itself carries**, and record the choice with its reasons. The
   candidates are surfaces already attached to the run the tick reads — the job summary
   (`$GITHUB_STEP_SUMMARY`), a check run's output, or the run's own conclusion — and the bar is
   that a later tick can read it through `gather/scripts/gh-rest.sh` with no blob redirect, no
   credential the tick lacks, and no new file in the tree. Reject any option needing a commit to
   `main`: that is the hourly-`main`-writer class this repository has refused twice.
2. **Record the candidate reading first**, not only the per-act answers: `ok`, `reason`, and the
   number of candidates. A turn that found nothing and a turn that found three and was refused are
   different facts, and the measured failure is the first one.
3. **Record one entry per candidate** carrying the unit, the branch and
   `delete-retired-claim-branch.sh`'s own `state` and `reason` **verbatim**. The vocabulary is that
   script's, closed and already documented; do not translate it, and do not add a word here.
4. **Keep the workflow owning no proof logic** — it calls the reader and the act, exactly as its
   header states. Recording is a third call, never a re-derivation.
5. **A refusal still does not fail the run**, unchanged. The header's sentence stays true; what
   changes is that the refusal is now legible, which is the whole repair.
6. Make the record **idempotent per run** and bounded in size, so a turn with many candidates
   cannot overflow whatever surface step 1 chose; state the bound and what happens past it.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A completed turn's record names the candidate reading (`ok`, `reason`, count) and, per candidate,
  the unit, the branch and the act's own `state`/`reason`.
- The record is readable through `gather/scripts/gh-rest.sh` alone — no blob redirect, no
  credential beyond what the tick already holds.
- Nothing is committed to the tree, no artifact gains a field, and the workflow's permissions stay
  `contents: write` and nothing wider.
- A refused act still leaves the run green.

**Verification method** — the commands/tests/probes that prove them:

- The offline reproduction from the first ticket, extended to assert the record's presence and
  contents for both a `[]` candidate reading and a refused act.
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- `sh scripts/e2e/loop-drill.sh verify-ci-retirement` passes.
- The workflow file's own header states the recording surface and why it was chosen over the
  alternatives, in the style its existing header already uses.

## Considerations

- **The job log is not a candidate.** It is what exists today, and the measurement is that a
  container cannot read it.
- Whether a refusal should make the run **red** is a real question and is deliberately **not**
  taken here: it would change what `base-health` and `drill-health` read, which is a separate
  decision with its own blast radius. The ask asks for the verdict to be *readable*, not for CI's
  colour to move.
- The bound in step 6 matters because the candidate set is unbounded in principle; a truncated
  record must say it truncated rather than read as a short one.
