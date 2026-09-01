---
created_at: 2026-08-29T12:21:04+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Run the hermetic drill set in CI on push

## Overview

Run ticket 2's aggregate verb in CI on push, so a merge that breaks a mechanism an earlier
turn proved fails the merge rather than waiting for a person to type a command. Today
`Validate Plugins` runs `node scripts/test-workflow-scripts.mjs` (which executes exactly
`verify-specificate` and `verify-implement` through its own throwaway repositories) plus
the manifest and layout checks; it never invokes `loop-drill.sh`. **A workflow is a
legitimate executor for what the container cannot do** — the precedent is
`.github/workflows/claim-retirement.yml`, admitted on exactly that ground — and this needs
less: no key, no network, no wider permission than the default read.

## Policies

- `workaholic:operation` / `policies/delivery.md` — the gate runs where the merge happens
- `workaholic:implementation` / `policies/error-handling.md` — a failure names itself

## Key Files

- `.github/workflows/validate-plugins.yml` — runs on `push`/`pull_request` to `main`,
  already carries the checkout and Node; the candidate host
- `.github/workflows/claim-retirement.yml` — the precedent for a narrowly-permissioned
  workflow of its own, and the shape to follow if this gets its own file
- `scripts/e2e/loop-drill.sh` — the verb being wired

## Implementation Steps

1. Decide the host and record the reason: a step in `Validate Plugins` (one workflow, one
   red X, no new setup for a consuming repository) against a workflow of its own (an
   independent runtime, so a slow drill set does not lengthen every manifest check). Prefer
   the existing workflow unless the measured wall-clock from ticket 2 argues otherwise.
2. Define the checkout explicitly rather than inheriting a shallow one — `fetch-depth: 0`,
   as `claim-retirement.yml` does — because several drills build git-backed fixtures and
   one (`verify-corpus-boundary`) grows a corpus past the `xargs` batching boundary.
3. Grant no credential: no `ANTHROPIC_API_KEY`, no wider `permissions:` than the default
   read. If any row needs one it was classified `skipped:needs_server` by ticket 1 and is
   not in the set.
4. Fail the job on the verb's non-zero exit and on nothing else — a `skipped` row must not
   fail the merge, or the gate is disabled within a week.
5. Print the per-drill verdict document in the job log so a red run is diagnosable without
   re-running anything locally.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The hermetic drill set runs on every push and pull request to `main`.
- A real drill failure fails the job; a run whose only non-passes are skips does not.
- The job needs no API key and no permission beyond the default read.
- The per-drill verdicts are visible in the job log.

**Verification method** — the commands/tests/probes that prove them:

- A branch carrying a deliberately broken seam, proving the job goes red and names the
  drill.
- The same job on an unmodified branch, proving green.
- The workflow file read for its `permissions:` and its absence of secrets.

**Gate** — what must pass before approval:

- Both CI runs above behaved as stated, and the workflow declares no secret.

## Considerations

- Wall clock is the real risk: ~28 drills each building a throwaway git fixture is not
  free, and this runs on every push. Ticket 2's per-drill timeout bounds the worst case;
  if the total is still too long, the honest options are parallelism within the job or a
  narrower push trigger — never quietly dropping rows, which reproduces the defect.
- The drill file's header says it lives outside the plugin because it assumes the server's
  full `gh` and `qfs`. Ticket 1 establishes for which rows that is still true; this ticket
  must update that header rather than leave it contradicting the workflow beside it.

## Final Report

Development completed as planned.

**The host is a workflow of its own**, `.github/workflows/loop-drills.yml`, and the reason
is **not** wall clock — the whole set measured ~2m20s sequentially, which `Validate
Plugins` could have absorbed. It is that **a check run is named after its job**, so a
matrix leg per drill makes the drill's own name the thing that goes red. That is what lets
ticket 6's `/moderate` step name the failing drill and the mission that shipped it from
`read-base-checks.sh` alone — no extra call, no log parsing, and no permission beyond the
default read. A single step inside another job would go red as "Validate Plugins", which
names neither. The parallelism the matrix gives is the answer to the wall-clock risk the
ticket named, not the reason for the split.

The matrix is **derived**: an `enumerate` job runs `verify-all --list --kind hermetic` and
the `drill` job fans out over `fromJSON` of it, with `name: ${{ matrix.drill }}` so the
check run is exactly the drill name. A list in the YAML would be the second hand-kept
enumeration this mission exists to remove, and ticket 8's pin fails when a drill the verb
cannot reach is added.

`fetch-depth: 0` on both jobs, because several drills build git-backed fixtures and
`verify-corpus-boundary` grows a corpus past the `xargs` batching boundary. No secret is
declared and `permissions: contents: read` is the whole grant. `fail-fast: false`, so one
red drill does not hide the others. The job fails on the verb's non-zero exit and on
nothing else, so a `skipped` row can never fail the merge.

Only the **hermetic** set runs: `reads_checkout` drills answer a question about the tree
they ran in and `needs_server` drills take an issue number only `seed` can mint, and both
are named skips in the verb's own output rather than quiet omissions.

The drill file's header — which claimed the whole file assumes the server's full `gh` and
`qfs` — was corrected in the same change, as the ticket required.

### Discovered Insights

- **Insight**: The decision that looks like a wall-clock trade is really a **naming** one.
  The only mechanism that surfaces a per-drill name to a REST reader with no extra
  permission is one check run per drill, and the only way to get one check run per drill in
  GitHub Actions without a token is one **job** per drill.
  **Context**: Ticket 6's whole design rests on it: without the matrix its question could
  only say "something in the drill set failed", which is the finding it exists to replace.
