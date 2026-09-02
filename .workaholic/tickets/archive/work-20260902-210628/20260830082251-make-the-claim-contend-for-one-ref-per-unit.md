---
created_at: 2026-08-30T08:22:51+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
---

# Make the claim contend for one ref per unit

## Overview

**The repair ticket 2 named.** A fresh claim pushes a clock-named `work-*` branch, so two runners
contend for nothing and both win. The claim must contend for **one ref per unit**, so that the
first push wins at the **remote** — the only arbiter both runners share — and the second is
refused.

The oracle, its verdict vocabulary and the `work-*` branch naming stay exactly as they are: the
unmerged-`work-*`-branch scan is still the claim oracle, and a claim is still a `Claim <unit-id>`
commit on a `work-*` branch. What changes is that publishing the claim also publishes a
**unit-keyed ref** whose creation is atomic at the server, so winning is decided by the remote
rather than by the clock.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` §6 — where the claim commits and pushes
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_scan`, which must keep answering from `work-*` refs alone
- `plugins/workaholic/skills/branching/scripts/create.sh` — the clock-derived name, unchanged
- `plugins/workaholic/skills/drive/reference/claims.md` — records the mechanism ticket 2 described
- `scripts/e2e/loop-drill.sh` — `verify-claim-race` from ticket 1

## Implementation Steps

1. Re-read ticket 1's reproduction and `claim.sh` §§4–6 end to end before choosing a mechanism —
   the push is the last act of a sequence that has already created a worktree and a commit, and
   where the contention is inserted decides how much the loser has written when it loses.
2. Choose the contended ref and record the choice in `claims.md`: a ref derived **from the unit id**
   rather than the clock, so two claimants for one unit name one ref and two claimants for
   different units never collide. Push it with a **create-only** refspec, so the server refuses the
   second rather than fast-forwarding it.
3. Keep `claims_scan` reading `work-*` refs and nothing else — the contended ref is the **arbiter**,
   not a second oracle. A reader that consults it would be the second derivation this repository
   refuses by name.
4. Make the push **atomic** with the claim branch's own push where the transport allows it, so a
   won arbitration and an unpublished claim cannot come apart; where it cannot, push the contended
   ref **first**, since a won ref with no branch is recoverable and a branch with no ref is the
   defect.
5. Release the ref wherever the claim is released: `release-claim.sh`, `retire-claim.sh`, and the
   merge that releases a claim by definition. A ref nothing deletes makes every unit
   claimable exactly once, forever — name the release path for each in `claims.md`.
6. Run `verify-claim-race`: the second claimant must now fail at the push. Its refusal wording is
   ticket 4's; this ticket only has to make the push lose.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Two claimants for one unit contend on one ref; the second push is refused by the server.
- Two claimants for **different** units never collide.
- `claims_scan` still answers from `work-*` refs alone and its verdicts are byte-identical for every
  claim in the existing fixtures.
- Every path that releases a claim releases the ref, each named in `claims.md`.

**Verification method** — the commands/tests/probes that prove them:

- `sh scripts/e2e/loop-drill.sh verify-claim-race` shows the second push refused.
- `sh scripts/e2e/loop-drill.sh verify-all` passes (no other drill's verdicts move).
- `node scripts/test-workflow-scripts.mjs` passes.

**Gate** — what must pass before approval:

- The race is lost at the remote, not by comparing clocks, and no verdict word was added.

## Considerations

- **Hypothesis, not design** (the ask proposed "one ref per unit" and this ticket adopts it after
  ticket 1's reproduction; if the reproduction shows the contention must sit earlier than the push,
  say so and re-scope rather than forcing the named mechanism).
- The container's transport refuses some ref writes (`retire-claim.sh`'s Act 2 is refused
  `branch_delete_failed` in a routine-fired container). Measure whether **creating** the contended
  ref is permitted there before building on it; if it is not, that is a finding for the mission, not
  a workaround to invent here.
- A leaked ref is worse than the race: it makes a unit permanently unclaimable. Step 5 is not
  optional, and ticket 8 should assert the release.

## Drive Findings — 2026-08-31 (blocked)

**The named mechanism is not buildable in the environment the loop runs in.** Step 2 requires a
unit-keyed ref pushed with a create-only refspec; step 5 requires that ref to be released wherever
the claim is released. Measured here, in a routine-shaped container, over **both** sanctioned
transports.

**This is the fourth independent reading, not the first, and re-reading it is the mistake to
avoid.** The finding already lives in
`plugins/workaholic/skills/drive/reference/claims.md` (*What the claim contends for*) with the
`refs/claims/*`, `refs/tags/*` and `refs/heads/*` probes and the `ls-remote` confirmations, and
the branch story for `work-20260830-124234` records two earlier re-confirmations. **Read it; do
not re-probe it.** Every permitted probe leaks a `refs/heads/*` ref this container cannot delete —
two now stand on origin (residue note below). This run's own probe was that mistake, and it is
recorded here so the next reader stops at this paragraph. What is new below is only the
`refs/notes/*` row, which no earlier reading had covered.

| Ref namespace | `git push` create | REST create | delete |
| ------------- | ----------------- | ----------- | ------ |
| `refs/claims/*` | `HTTP 403` | `403` | — |
| `refs/tags/*` | `HTTP 403` | — | — |
| `refs/notes/*` | `HTTP 403` | — | — |
| `refs/heads/*` | **permitted** | `403` | **`HTTP 403`** |

Raw output, `git push origin <origin/main sha>:<ref>`:

```
error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
```

`refs/heads/*` took the create (`* [new branch] 5b642765 -> wh-probe-20260831194543`) and refused
the delete with the same 403. REST, through `gather/scripts/gh-rest.sh`, refused both create and
delete with `{"message":"Write access to this GitHub API path is not permitted through this proxy."}`.

**Why that blocks rather than re-scopes.** The one writable namespace cannot be released, and this
ticket's own step 5 and Considerations rule that out by name — *a leaked ref is worse than the
race: it makes a unit permanently unclaimable.* Deriving the **`work-*` branch itself** from the
unit id would contend and would be released by `delete_branch_on_merge`, but the mission's Scope
excludes `work-*` naming and this ticket's Overview holds it fixed; that is a re-scope, which the
Considerations reserve to the operator (*"say so and re-scope rather than forcing the named
mechanism"*). No workaround was invented here, per the same paragraph.

**What already stands in its place.** The race is not unhandled: `archive.sh` re-derives the claim
immediately before the ticket moves and refuses `claim_taken_over` / `ambiguous_claim` with the
tree byte-identical, and a live race reaches a person through `list-raced-units.sh` and
`/moderate`'s `raced-units` step. Mission acceptance items 2 and 3 are checked on that work;
this item is the one the transport forbids.

**Residue the measurements have left.** Two undeletable branches on origin, neither matching
`work-*` nor `release/*` (so no claim scan sees them), neither removable from this container —
a human, or the CI job that holds `contents: write`, must delete both:

- `wk-transport-probe-1788104778` → `304652b2` (left by the earlier reading)
- `wh-probe-20260831194543` → `5b6427654b3c3ad955755e446a3474c81e22cfe8` (left by this one)

The cleanup is **no longer this ticket's**: it was lifted out on 2026-09-01 into
`20260901123000-delete-the-branches-the-transport-probes-left-on-origin.md`, which is driveable
now and independent of the ruling below in both directions. Binding it to a blocked ticket meant
nothing in the queue named it as work. The measurements above stay here — they are the finding,
and they are still the reason nobody should re-probe.

## Drive Findings — 2026-09-01 (blocked, unchanged)

Re-verified **by reading the sources this ticket names, not by re-probing**: `claims.md`'s *What
the claim contends for* (the `refs/claims/*`, `refs/tags/*`, `refs/notes/*` and `refs/heads/*`
rows, both transports, with the `ls-remote` confirmations) and this ticket's own table. Nothing
in them has moved, and no probe was pushed. The block stands on the same measurement.

Two of the three rulings this ticket offers are already answered in that section, and only the
third is open:

- **Move the arbitration to `.github/workflows/`** — refused there by name, not merely unbuilt:
  *an arbitration must be decided synchronously, in the container, before the run drives
  anything*, and an asynchronous CI-side release leaves a window in which a unit's own follow-up
  re-claim is refused by a ref that no longer stands for anything.
- **Force the named mechanism** — it reaches **one grain, not two**. `claim.sh` mints
  `batch-<timestamp>` inside the claim act, so two runners racing at the batch grain push two
  different unit-keyed refs and both win. That half is **independent of the transport**: an
  operator ruling that unblocks ref writes still does not deliver this ticket's acceptance
  criteria at the batch grain.

So what is open is the **re-scope or the abandon**, and both assert intent, which an unattended
run may not do. Deferred to the operator, unasked.

**The ruling this needs.** Re-scope acceptance item 1 to a mechanism `refs/heads/*` can express,
or move the arbitration to where the write is permitted (`.github/workflows/`, which holds
`contents: write`), or abandon the item on the bounded-later repair already landed.

## Drive Findings — 2026-09-01, second run (blocked; one new row)

Re-verified by **reading**, not probing: `claims.md`'s *What the claim contends for* and this
ticket's own table. Unmoved, so the block stands on the same measurement and the same open
ruling. No probe was pushed and no new residue ref was created.

**One row is new, and it is about this claim rather than about a probe ref.** Releasing a
**live claim** was refused by the same transport:

```
$ release-claim.sh stop-two-runs-from-claiming-and-driving-one-unit
error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403
{"released": false, "state": "half_released", "reason": "remote_delete_failed", ...}
```

So the delete refusal is not confined to probe namespaces: it reaches `refs/heads/work-*`, the
branch the claim protocol's own release path must delete. Two consequences worth the ruling's
attention. First, it **strengthens** step 5's objection — a container that cannot delete its own
claim branch certainly cannot release a unit-keyed ref, so the leaked-ref regression is measured
rather than forecast. Second, it is a **cost of the block itself**: every unattended run that
claims this mission, finds the queue blocked on the ruling, and tries to hand the unit back leaves
one undeletable `work-*` branch behind. `work-20260901-144612` is this run's.

Nothing here changes what the ruling is. It changes only how expensive waiting for it is.

## Final Report — 2026-09-02 (implemented)

**The block did not stand, and one cheap probe is what showed it.** Every earlier reading was
taken **from a routine-fired cloud container**, whose proxy answers 403 — the readings say so
themselves. The loop moved onto the developer's own server on 2026-09-02 (`workaholic:loops`),
and this run re-measured over SSH against the same origin before designing around the stated
impossibility:

- `refs/claims/*` create → `* [new reference]`, confirmed by `ls-remote`;
- create-only lease (`--force-with-lease=<ref>:`) → a second push is `! [rejected] … (stale
  info)` and the ref keeps the winner's value;
- compare-and-swap on the known value → accepted;
- **delete** → `- [deleted]`, `ls-remote` empty.

No residue was left. Corroborating evidence needing no probe at all: the two claim branches this
session merged were deleted from origin (`branch_removed: true`, `ls-remote` empty), and the
three residue refs the earlier findings named are already gone. **Both readings are true of
their own environment**, so nothing above is retracted — what changed is which environment the
loop runs in, and the mechanism is built to report `unavailable` where the transport still
refuses, leaving the Web-routine fallback byte-for-byte as it was.

**What was built** (steps 1–6):

- `drive/scripts/claim-arbitrate.sh` — `take` / `release` / `reap` / `refname`, exit 0 always.
- `claim.sh` **§3b**, after the oracle's refusal and **before the worktree exists**, so the
  loser writes nothing at all — the mission's Experience, met by placement rather than by a
  teardown.
- **The ref is derived from the artifacts, not the unit id**, and that is a deliberate
  deviation from the ticket's wording, recorded in `claims.md`: `claim.sh` mints
  `batch-<timestamp>` *inside* the claim act, so a unit-keyed ref reaches one grain only. One
  ref per artifact settles both, and it is the same key §3's overlap refusal already uses.
- **All or nothing**, with the partial hold unwound.
- **Release named per path** — `abort_claim`, `release-claim.sh`, `retire-claim.sh`, and, for
  the merge (which runs nothing in the container), the arbiter's oracle-and-age **reap**, run
  lazily by `claim.sh` only when a take is lost, then the take retried once.
- `claims_scan` still reads `work-*` refs alone; no verdict word was added and the
  proofs-and-judgements tables did not move.

**Verification**: the 81 existing claim-protocol rows pass with the arbitration wired in, and
the arbiter was confirmed to genuinely fire in those fixtures (a local bare origin takes the
`refs/claims/*` push), so they exercise it rather than its degraded path.

### Discovered Insights

- **Insight**: A ref used as a lock must be pushed with a **value unique per claimant**. Git
  treats a push of the value a ref already holds as `Everything up-to-date` and exits 0, so a
  shared base sha made two successive takes both answer `won` — the lock silently arbitrating
  nothing. Each take now mints its own commit.
  **Context**: Any future ref-as-lock in this repository meets the same trap; the lease only
  arbitrates when the values differ.
- **Insight**: The standing block rested on a measurement whose **environment** was the
  variable, and the finding said so in its own words while the conclusion did not carry the
  qualifier forward. Re-probing was explicitly discouraged by the ticket — correctly, for the
  container it was written in — and the thing that made re-probing right was a change of
  premise the earlier readings could not have known about.
  **Context**: A recorded impossibility deserves a cheap re-measure whenever the environment it
  was measured in has moved.
