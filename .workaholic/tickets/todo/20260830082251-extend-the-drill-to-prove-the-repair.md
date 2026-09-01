---
created_at: 2026-08-30T08:22:51+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Extend the drill to prove the repair

## Overview

Ticket 1 proved the defect. This ticket turns that drill over to prove the **repair**, and adds the
`bearing: "breaker"` row without which the drill is `unproved` — counted outside the passing total
by `verify-all`, a gap in coverage rather than a broken mechanism.

The whole path, end to end, with no network and no credential: two runners survey → one wins at the
remote → the loser refuses by its own word having written nothing → the winner drives and merges →
the twin reads `superseded` at the mission grain from the tree → the existing retirement path
reaches it → the person is told once, with both branches named.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early

## Key Files

- `scripts/e2e/loop-drill.sh` — `verify-claim-race`, extended
- `docs/loop-drill-runbook.md` §9 — the register row's `bearing` column and its failure-reason→file blame entry
- `plugins/workaholic/skills/drive/scripts/drill-register.sh` — the register's one reader
- `scripts/test-workflow-scripts.mjs` — fails on an unclassified drill
- `.github/workflows/loop-drills.yml` — one matrix leg per drill, so the red check is named after this one

## Implementation Steps

1. Invert ticket 1's assertions to their post-repair form: **one** winner branch on origin, the
   loser holding no branch, no worktree and no commit, and **no** duplicate archive under a second
   branch directory.
2. Assert the loser's refusal **word** (ticket 4) rather than merely that it failed, and assert the
   contended ref is **released** when the claim is released — a leaked ref makes a unit permanently
   unclaimable, which is a worse failure than the race.
3. Assert the mission-grain `superseded` reading (ticket 6) **from the tree, with the transport
   stubbed to answer nothing**, so the drill proves the network-free path rather than passing through
   the fallback.
4. Assert the retirement path reaches the twin: `list-retirable-claims.sh` names it and
   `retire-claim.sh` accepts it — through the existing scripts, unchanged, which is what "retired by
   machinery that already exists" has to mean.
5. Assert the person is told once (ticket 7) over **two** ticks, with both branches named, and that
   the sibling step is silent on the same unit.
6. Write the **breaker row against the behaviour, not the return shape**: restore the clock-derived
   contention — the pre-repair `create.sh` name pushed with no unit-keyed ref — and the drill must go
   red. A breaker written against a return shape survives a refactor that keeps the shape and loses
   the bound; this repository has recorded that failure twice.
7. Register the drill's `bearing` row and its blame entry in `docs/loop-drill-runbook.md` §9, and
   confirm `verify-all` counts it in the passing total rather than as `unproved`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The drill proves the whole path — win, clean loss, superseded twin, retirement, one question — with no network and no credential.
- The breaker row is written against the behaviour and is **proved able to fail** on the pre-repair mechanism.
- The register carries the row with its `bearing` entry, so `verify-all` counts it rather than reporting `unproved`.
- Every other drill's verdict is byte-identical.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` passes on the repaired tree.
- The breaker row, applied to the repaired tree, makes it fail — demonstrated, not asserted.
- `sh scripts/e2e/loop-drill.sh verify-all` passes and counts the drill in its passing total.
- `node scripts/test-workflow-scripts.mjs` passes.
- `Loop Drills` is green, with this drill as its own matrix leg.

**Gate** — what must pass before approval:

- The repair has a proof that can fail, and CI runs it on every push.

## Considerations

- **A drill that cannot fail proves nothing.** Step 6 is the ticket, not a formality: run the breaker
  and show the red, rather than reasoning that it would.
- The drill is hermetic by requirement, not by preference — `loop-drills.yml` runs with no credential
  and no permission beyond the default read, so any `gh` reach must be stubbed.

## Drive Findings — 2026-08-31 (blocked)

**Step 7 was already satisfied before this run; steps 1-6 are blocked upstream.**

*Step 7 — already done.* `verify-claim-race` is registered in `docs/loop-drill-runbook.md` §9
(`hermetic`, breaker `yes`, mission `stop-two-runs-from-claiming-and-driving-one-unit`),
`drill-register.sh drill verify-claim-race` resolves it, and the drill is **not** `unproved`:

```
{"ok": true, "stage": "claim-race", "verdict": "pass",
 "load_bearing": {"passed": 13, "failed": 0}, "advisory": 0, "breakers": 1, "rows": []}
```

It came in with ticket `20260830082251-reproduce-the-claim-race-offline-in-a-drill.md`, so
`verify-all` already counts it in the passing total.

*Steps 1-6 — blocked.* Every one asserts the **post-repair** form: one winner branch on origin
with the loser holding none, the loser's refusal **word**, and the contended ref **released** on
claim release. None of those exist — the mechanism ticket
`20260830082251-make-the-claim-contend-for-one-ref-per-unit.md` is blocked because this
container's transport refuses ref creation outside `refs/heads/*` and refuses the delete inside
it (full measurement recorded there), and the refusal-word ticket is blocked behind it. Inverting
the drill's assertions now would make a passing drill red against behaviour the repository does
not have, which is a broken mechanism rather than the coverage gap this ticket exists to close.

Unblocked by: a ruling on the mechanism ticket's re-scope. The drill as it stands proves the
repair that **did** land (the `archive.sh` re-check and the `raced-units` question) and its
breaker row is written against that behaviour.
