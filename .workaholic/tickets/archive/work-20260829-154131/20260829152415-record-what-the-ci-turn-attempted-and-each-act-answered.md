---
created_at: 2026-08-29T15:24:15+00:00
status: done
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

## Final Report

Development completed as planned.

**The surface is a check-run annotation**, and the choice was measured before anything was built
on it. `GET /repos/{o}/{r}/check-runs/{id}/annotations` answers in full through
`gather/scripts/gh-rest.sh` — no blob redirect, no credential beyond the read the tick already
holds — verified against this repository's own run 33260493563 on 2026-08-29. Beside it, the job
log endpoint returned a signed `productionresultssa19.blob.core.windows.net` URL whose fetch
failed, reproducing the ticket's measurement exactly.

The three alternatives are refused by name in the workflow's header and in the recorder's:

| Candidate | Why not |
| --------- | ------- |
| the job log | a signed blob redirect the container cannot follow — what exists today, and the defect |
| `$GITHUB_STEP_SUMMARY` | renders in the UI, exposed by **no** REST endpoint, so no later tick can read it |
| a check run of our own | `POST .../check-runs` needs `checks: write`, **wider** than this job's `contents: write` |
| a commit to `main` | the hourly-`main`-writer class `workaholic:ship` §7 has refused twice |

A `::notice::` annotation needs **no permission at all** — it is a workflow command rather than
an API call — so the job's grant is unchanged at `contents: write`.

**Recording is a third call.** `drive/scripts/record-ci-retirement-turn.sh` is handed the two
documents the job already produced (`list-retirable-claims.sh`'s reading, and one
`delete-retired-claim-branch.sh` line per candidate) and copies their words. It derives nothing
and owns no vocabulary, so the workflow's *owns no proof logic* header sentence stays true.

Two behaviours changed in the workflow beyond the new step. The degraded-reading branch used to
`exit 0` **before anything was recorded** — which is precisely the turn whose silence the report
measured — so it is now an `else` and the record is reached on every path; and the recording step
carries `if: always()`, so a turn that dies mid-loop still says what it attempted.

**A refused act still leaves the run green**, unchanged. What changed is that the refusal is
legible.

### Discovered Insights

- **Insight**: a `::notice::` annotation is the only run-attached surface that is both writable
  with no added permission and readable through plain REST with no redirect.
  **Context**: step summaries have no REST endpoint and check runs need `checks: write`. Any
  later "record something about a CI run for the loop to read" lands here for the same reasons.
- **Insight**: the truncation bound fails **safe** by construction — a unit past
  `WORKAHOLIC_CI_RECORD_MAX` (default 20) has no entry, so the consumer reads it `unreadable`,
  and `unreadable` suppresses no question.
  **Context**: that is why a bound was acceptable at all; a bound that silently answered `taken`
  past its limit would reintroduce the very defect.
- **Insight**: values written into an annotation line are sanitized rather than escaped
  (`[^A-Za-z0-9._:/@+-]` → `_`), because the whole vocabulary is unit ids, branch names and
  closed-set refusal words.
  **Context**: the consumer parses the line back on spaces and `=`, so a stray quote or newline
  would split a record rather than corrupt one field.
