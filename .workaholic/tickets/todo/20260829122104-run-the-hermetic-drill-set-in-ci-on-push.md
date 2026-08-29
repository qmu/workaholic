---
created_at: 2026-08-29T12:21:04+00:00
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
