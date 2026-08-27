---
created_at: 2026-08-27T16:20:03+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827162002-classify-the-base-reading-as-a-judgement-and-pin-it.md
mission: read-whether-the-base-survived-what-the-loop-merged
merge_policy:
verification_handoff: 
---

# Drill the base reading with no network

## Overview

<!-- PROPOSED. -->

Add `sh scripts/e2e/loop-drill.sh verify-base-health`: the operator-facing drill that
proves the whole reading on demand rather than by waiting for the base to break. It
runs over a **stubbed transport with no network at all**, like `verify-retire`,
`verify-delivery-retry` and `verify-merged-claim` before it.

It carries **one fixture that deliberately breaks the seam**, so the drill can be *seen*
to fail. Every drill in this file has one for the same reason: a drill that has never
failed proves nothing about the thing it claims to check.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/test.md` — each case states what it verifies

## Key Files

- `scripts/e2e/loop-drill.sh` — add `cmd_verify_base_health` and its `verify-base-health)`
  arm in the dispatch case at the foot of the file.
- `scripts/e2e/loop-drill.sh` — read `cmd_verify_retire` and `cmd_verify_delivery_retry`
  first: they are the closest precedents (a proof-versus-judgement act, a stubbed
  transport, a deliberately broken seam).
- `docs/loop-drill-runbook.md` — the operator procedure and the failure-reason → file
  blame table; add this verb's rows.
- The scripts from tickets 1–5 — the drill's subjects.

## Implementation Steps

1. Read an existing drill end to end before writing this one, and reuse its fixture
   scaffolding rather than inventing a second style.
2. Stub the GitHub transport on `PATH` so **no network call is made**. Assert that, do
   not assume it: a drill that silently reaches the network is not the drill this is.
3. Drill the reader (ticket 1): `green`, `red` with failing check names, and each
   `unanswerable` reason — including a commit with **no checks at all**, which must not
   read as green.
4. Drill the attribution walk (ticket 2): a red tip attributed to a mid-walk merge with
   its pull request and author, and the **`unattributable` tail** where the walk exhausts
   its bound without reaching a green commit.
5. Drill the asked-once gate (ticket 3): two consecutive simulated ticks over one red
   commit produce exactly **one** question, keyed `base-red:<commit>`; and a degraded
   read asks nothing.
6. Drill that the reading **gates nothing** (tickets 5 and 6): a simulated driving run
   over a red base reports its terminal token byte-identically to the same run over a
   green one, and nothing is reverted, re-run, held or blocked.
7. Add the **deliberately broken seam**: one fixture where a consumer acts on the reading,
   or the reader answers green for a commit with no checks — and assert the drill reports
   failure. Label it plainly in the output so an operator reading a red drill knows which
   case is the intentional one.
8. Register `verify-base-health)` in the dispatch case and document the verb in
   `docs/loop-drill-runbook.md` with its failure-reason → file blame rows.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `sh scripts/e2e/loop-drill.sh verify-base-health` passes with no network call
- all three reader states, both attribution outcomes, and the asked-once gate are drilled
- the gates-nothing property is drilled by comparing tokens across a red and a green base
- the deliberately broken fixture makes the drill fail, and is labelled as intentional
- the runbook names the verb and its blame rows

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-base-health`
- the same, with the broken fixture enabled — must fail
- `node scripts/test-workflow-scripts.mjs` — unchanged and still passing

**Gate** — what must pass before approval:

- the drill is observed both passing and failing
- no network call is made in either run

## Considerations

- The drill is **operator tooling outside the plugin**: it assumes the server's full `gh`
  and `qfs` and ships to no other agent. Keep it there; the hermetic suite is the part
  that must run everywhere.
- Do not duplicate `test-workflow-scripts.mjs`. The suite pins the contracts; the drill
  walks the chain end to end for a person who wants to see it work.
