---
created_at: 2026-08-29T12:21:05+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: run-the-loop-s-own-proofs-on-every-turn
merge_policy:
verification_handoff: 
---

# Pin the drill verdict path offline

## Overview

Pin the whole path offline in `scripts/test-workflow-scripts.mjs` — runner → verdict → CI
wiring → the tick's reading — and **fail when a drill is added that the aggregate verb
cannot reach**. That last clause is what retires the eight presence assertions of the
shape `assertTrue("verify-expiry is in loop-drill.sh", /cmd_verify_expiry\(\)/.test(drill))`:
a regex proves a drill *exists* and never that it *passes*, and leaving both would be two
mechanisms claiming one job. The suite is what CI already runs, so the pin costs no new
executor.

## Policies

- `workaholic:implementation` / `policies/testing.md` — the guarantee is a fact a change can lose, not a claim in prose
- `workaholic:implementation` / `policies/coding-standards.md` — one mechanism per job

## Key Files

- `scripts/test-workflow-scripts.mjs` — holds the eight presence assertions (around
  lines 971, 2146, 2193, 26587, 27735 and their neighbours) and the two drill sub-suites
  that already execute `seed`/`reset`/`verify-specificate`/`verify-implement` hermetically
- `scripts/e2e/loop-drill.sh` — the dispatcher enumeration the pin reads
- `.github/workflows/validate-plugins.yml` — the CI wiring the pin asserts

## Implementation Steps

1. Add the reachability pin: enumerate `cmd_verify_*()` definitions and the dispatcher's
   `case` arms from the drill file, and fail when any is absent from the aggregate verb's
   set **and** absent from ticket 1's recorded classification. A new drill is then either
   run or deliberately classified — never silently unreached.
2. Pin the verdict shape: a fixture run of the verb yields one of `pass`/`fail`/`skipped:<reason>`
   per drill, and a non-zero exit if and only if some verdict is `fail`.
3. Pin the CI wiring by reading the workflow file: the verb is invoked, the job declares no
   secret, and the checkout is not shallow.
4. Pin the tick's reading: a green run yields no event and no question; a failing one
   yields exactly one question keyed `drill-failing:<drill>`; a degraded read is named.
5. Delete the eight presence assertions in the same change, and say in the commit why —
   the reachability pin strictly subsumes them.
6. Keep it hermetic: throwaway directories under the OS temp dir, no `gh`, no network, no
   touching the working tree — the suite's standing contract.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Adding a `cmd_verify_*` the verb cannot reach and that ticket 1 has not classified fails
  the suite.
- The verdict vocabulary and the exit-status rule are pinned.
- The CI wiring and the tick's four readings are pinned.
- The eight presence assertions are gone, with no drill losing coverage.
- The suite still calls no `gh`, makes no network call and leaves the working tree
  untouched.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` on the unmodified tree — green.
- The same with an unreachable drill added to a scratch copy — red, naming the drill.
- `grep -c 'is in loop-drill.sh' scripts/test-workflow-scripts.mjs` → 0.

**Gate** — what must pass before approval:

- All three probes behaved as stated, offline.

## Considerations

- The pin must read the **dispatcher**, not a list in the test — a list in the test is the
  ninth presence assertion under another name.
- A drill deliberately classified `needs_server` is reachable-by-classification rather than
  by execution; the pin has to accept that state explicitly or it will push someone to
  delete the classification instead of maintaining it.
