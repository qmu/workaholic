---
created_at: 2026-08-27T23:22:22+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260827232222-ask-the-holder-for-the-branches-left-undeleted.md
mission: finish-the-retirement-the-loop-cannot-complete
merge_policy:
verification_handoff: 
---

# Drill the blocked retirement with no network

## Overview

`verify-retire` drills the retirement's three acts and the refusal of a judgement by
its own verdict word. It does not drill the case that has been true in production on
every tick since the mechanism landed: the delete refused, the other two acts
standing. A behaviour nothing drills is a behaviour the next change can lose.

Extend the drill with a row whose delete is refused, over local fixtures with the
transport stubbed and no network — plus one row that deliberately breaks the seam,
so the drill is proved able to fail.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/testing-strategy.md` — a property is drilled, not asserted

## Key Files

- `scripts/e2e/loop-drill.sh` — `cmd_verify_retire`, the local bare origin and the
  PATH stub it already builds; the new rows extend that fixture rather than adding one.
- `docs/loop-drill-runbook.md` — the failure-reason→file blame table the new rows join.
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` — the writer under drill.
- `plugins/workaholic/skills/moderate/scripts/step-retire-claims.sh` — the caller
  whose summary and question the drill reads.

## Implementation Steps

1. Add a fixture whose branch delete is refused while its pull-request close
   succeeds — the production shape — using the existing stub seam, with no network.
2. Assert the **named word** from ticket 2 is what comes back, not a generic refusal.
3. Assert the **two acts that stand** are named in the caller's summary (ticket 4).
4. Assert the **question key** and its asked-once gate (ticket 5): one question on
   the first tick, none on the second, addressed to the claim holder and naming the branch.
5. Assert **nothing already done is undone**: the closed pull request stays closed,
   the claim is not released, the verdict stays `superseded`, and a re-run takes only
   the one remaining act.
6. Assert the **summary is stable** across two ticks over the unchanged fixture (ticket 6).
7. Add one row that deliberately breaks the seam — the drill must fail when the
   behaviour is lost, and that row is labelled as the intentional failure.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The blocked-delete row drills the named word, the standing acts, the question key,
  its asked-once gate, and that nothing done is undone.
- The drill makes no network call and runs from a clean checkout.
- The deliberately broken row fails, proving the drill can.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-retire`
- `node scripts/test-workflow-scripts.mjs`

**Gate** — what must pass before approval:

- `verify-retire` passes on the honest rows and fails on the broken one, both shown.

## Considerations

- The drill is operator tooling outside the plugin and assumes the server's full
  `gh` and `qfs`; the new rows must keep that assumption and add no other.
- Ticket 3 may land as a recording-only finding. The drill must not assume a retry
  exists — it drills the blocked path, which is true either way.

## Final Report

Development completed as planned.

`verify-retire` gains a blocked-delete phase over the **existing** fixture — the same local bare
origin and `PATH` stub, no second fixture and no network. The refusal is reproduced by the bare
repository's own **`update` hook**, scoped to one ref: git runs receive-pack locally over the file
transport, so this is the same server-side path a remote refusal takes, and scoping it to one ref
lets a retirable claim be retired in the *same tick*.

Three superseded claims are held back from the earlier rows (their tickets stay queued until the
blocked phase) so each reaches a **different** outcome in one tick:

| Unit | Outcome |
| ---- | ------- |
| `batch-blocked` | refused **on the delete** |
| `batch-retirable` | retired |
| `batch-closefail` | refused on an act that is **not** the delete |

Nine rows were added (steps 1–7 and a no-network guard):

- `retire_blocked_fixture` — load-bearing; stops the drill if the shape is not under test.
- `retire_blocked_names_the_act` — the **named word** `branch_delete_failed`, not a generic refusal.
- `retire_blocked_undoes_nothing` — a re-run leaves the pull request closed, re-attempts only the
  delete, and the branch and its `superseded` verdict both stand.
- `retire_blocked_reports_what_stands` — the caller's summary names the acts that stand.
- `retire_blocked_asks_the_holder` — the question, its key, its addressee and the branch.
- `retire_blocked_asked_once` — `ask-question.sh` over two consecutive ticks.
- `retire_blocked_summary_stable` — an identical summary and no event across two ticks.
- `retire_blocked_only_the_blocked` — **the deliberately broken row**.
- `retire_no_network` — `gh` resolves to the stub.

**Each seam was verified to fail**, not asserted: collapsing the reason back to one word failed 4
rows; widening the candidate set to every refusal failed the breaker row and nothing else;
prefixing the summary with `$(date +%s)` failed the stability row and nothing else.

The drill keeps its existing assumptions (the server's full `gh` and `qfs`, operator tooling
outside the plugin) and adds none. Ticket 3 landed as a recording-only finding, and nothing here
assumes a retry exists — the blocked path is true either way.

### Discovered Insights

- **Insight**: the first version of the breaker row carried only `batch-retirable` — a unit that
  was *retired* — and **passed against a seam deliberately broken to "any refusal"**, because in
  that tick the only refused unit *was* the blocked one. `batch-closefail` exists solely to close
  that hole.
  **Context**: a breaker row proves only what its fixture can distinguish. A candidate set has as
  many ways to be widened as it has terms, and each needs a fixture row that differs on exactly
  that term — checking the row goes red is the only way to know which ones it covers.
- **Insight**: a bare repository's `update` hook is a precise, hermetic way to make one specific
  git operation fail server-side. It reproduces a remote refusal on the real code path with no
  network, no proxy and no credentials, and it can be scoped to a single ref.
  **Context**: reusable for any drill that needs a *partial* transport failure rather than an
  offline one — non-fast-forward refusals, protected-branch pushes, refused force-updates.
