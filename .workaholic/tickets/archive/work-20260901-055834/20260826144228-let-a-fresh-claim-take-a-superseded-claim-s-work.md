---
created_at: 2026-08-26T14:42:28+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
claim: work-20260901-055834
---

# Let a fresh claim take a superseded claim's work

## Overview

MEASURED, on this repository, by the `[Implement]` tick of 2026-08-26 14:40 UTC.

The 2026-08-26 `superseded` change shipped its **survey** half and not its
**claim** half, so the work it frees is reachable by no path at all — the exact
symptom the change was written to cure, moved one step later.

`plan-units.sh` says it in its own words (`is_superseded`, lines 299-315):

> `claimed_superseded` says the unit's work already reached the base — so the
> claim is a dead branch, and the queued tickets sitting behind it are ordinary
> backlog that nothing is driving. … **THIS FREES THE WORK; IT DOES NOT REVIVE
> THE BRANCH.** … a run that takes the freed tickets claims them **FRESH** — a
> new branch, a new worktree, a new pull request. That is the only correct
> route: the old branch cannot land.

`claim.sh`'s in-flight check (§3, lines 318-343) never consults the claim's
reason. It compares the requested unit id against **every** row `claims_scan`
returns and refuses on a match:

```sh
if [ "$held_unit" = "$unit" ]; then
    fail "already_claimed" …
fi
```

A `superseded` row is still a row, so the fresh claim the survey's own comment
prescribes is refused as though the dead branch were in flight.

**Measured, verbatim.** The survey offered exactly one unit:

```json
"resurveyed": [{"kind": "mission",
                "id": "make-workaholify-converge-the-account-s-routines",
                "claim": "work-20260819-113836"}],
"missions": [{"slug": "make-workaholify-converge-the-account-s-routines",
              "checked": 2, "total": 3, …}],
"backlog": []
```

and the claim of that same slug answered:

```json
{"claimed": false, "reason": "already_claimed",
 "unit": "make-workaholify-converge-the-account-s-routines",
 "holder_branch": "work-20260819-113836", "holder_unit": "…"}
```

`work-20260819-113836` is `resume_reason: superseded`, `resumable: false`,
`stale: true`, last commit 2026-08-21. `claim.sh resume` refuses it too, by
name and correctly (`superseded`, lines 160-161: *"There is nothing left to
drive"*). So the mission is offered, cannot be claimed fresh, and cannot be
resumed. The tick claimed nothing and reported `pending` with work queued.

Three further claims here carry the same reason
(`make-the-draft-release-note-an-agent-s-release-plan`,
`batch-20260819063000`, `make-a-rename-a-registry-entry-not-a-sweep`), so this
is not a one-off shape.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` — §3 *Refuse a unit (or an
  artifact) already in flight*, lines 318-343. The unit-id branch and the
  artifact-overlap branch both need the reason test; the artifact branch is
  what a **batch** unit hits, since its own id is freshly minted and can never
  collide.
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` — `claims_scan`'s row
  format already carries `_held_reason` (field 7), which `claim.sh` reads into
  a discarded variable today. The datum is present; nothing reads it.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — `is_superseded` /
  `note_resurveyed`, lines 299-333: the survey-side rule this must match.
- `plugins/workaholic/skills/drive/SKILL.md` — §1's `superseded` bullet and §3's
  *`already_claimed` → drop the unit and continue (the protocol working)*. The
  second sentence is what makes the defect invisible to a reader: for this one
  reason the refusal is **not** the protocol working, and the skill should say
  so where a driving run reads it.
- `plugins/workaholic/skills/drive/reference/claims.md` — the refusal vocabulary.
- `scripts/e2e/loop-drill.sh` — `verify-merged-claim` drills the four *readings*
  over a squash-merged fixture; it does not drill the **claim** that must
  follow. This ticket's proof belongs beside it.

## Implementation Steps

1. **Reproduce first, in a hermetic fixture, before changing anything.** Build
   the shape `verify-merged-claim` already builds — a unit whose content reached
   the base by another route — and assert that `plan-units.sh` reports it in
   `resurveyed[]` **and** that `claim.sh` on that same unit refuses
   `already_claimed`. That failing assertion is the defect; it is what the fix
   flips.
2. **Make the in-flight check read the reason it already has.** In `claim.sh`
   §3, a row whose reason is `superseded` is stepped over rather than refused —
   at **both** grains, the unit-id match and the artifact overlap, because a
   mission claim stamps `mission.md` while the freed tickets are matched by
   path. Read the reason from `claims_scan`'s existing field; do not re-derive
   the verdict, and do not add a second scan — one oracle, one derivation
   (`claims_superseded` / `claim-merged.sh`), consulted by both callers.
3. **Step over only that one reason.** `claimed_active`, `claimed_by_other`,
   `claimed_reported`, `claimed_resumable` and `queue_drained` refuse exactly as
   they do today. The narrowness is the safety argument: only a claim *proved*
   to hold nothing is passed.
4. **Change nothing about the old branch.** No delete, no pull-request close, no
   `release-claim.sh`. `superseded` is reported and never acted on, and the new
   claim is a new branch, a new worktree and a new pull request. Confirm the old
   branch is still present and untouched after the fresh claim succeeds.
5. **Decide and state what the new claim's own row does to the old one.** After
   the fresh claim there are two unmerged branches for one unit id, one
   `superseded` and one live. Confirm `claims_scan`'s later readers — the
   survey's exclusions and `claim.sh`'s own next run — pick the live one and do
   not re-free the unit under the dead row. If they cannot, that is this
   ticket's real work and step 2 is the easy half.
6. **Say it where a driving run reads it.** `drive/SKILL.md` §3's
   *"`already_claimed` → drop the unit and continue"* gains the exception, and
   `reference/claims.md` records the refusal's one non-refusing reason.
7. **Add the drill.** Extend `scripts/e2e/loop-drill.sh` so the merged-claim
   fixture proves the *claim* as well as the reading, with no network.
8. **Update the documentation in the same change**: `CLAUDE.md`'s claim-protocol
   bullet (which today states the survey half and stops), `README.md` if it
   states either half, and `reference/claims.md`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A unit named in `plan-units.sh`'s `resurveyed[]` can be claimed by
  `claim.sh`, on a fresh branch and worktree, with the superseded branch left
  in place.
- Every other claim reason still refuses `already_claimed`, unchanged.
- The old branch, its worktree and its pull request are untouched by the fresh
  claim; nothing here deletes or closes anything.
- With a live claim and a superseded claim both present for one unit id, the
  next survey reads the live one and does not re-free the unit.
- `drive/SKILL.md` §3, `reference/claims.md` and `CLAUDE.md` agree on the one
  reason that does not refuse.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — carries the new hermetic case from
  step 1, asserting the refusal before the fix and the claim after it.
- `sh scripts/e2e/loop-drill.sh verify-merged-claim` — extended per step 7, no
  network.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs
  && node scripts/build-plugins/validate-metadata.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .`

**Gate** — what must pass before approval:

- The reproduction of step 1 is recorded in the Final Report, including the
  verbatim refusal it produced before the fix.
- No script gains a second derivation of the superseded verdict.

## Considerations

- **This is the claim half of a two-half change, not a new rule.** The survey
  half landed on 2026-08-26 with its reasoning written out; nothing here
  re-argues it. What is added is that `claim.sh` obeys the same verdict the
  survey already computed.
- **Do not fix it by relaxing the refusal generally.** `already_claimed` is the
  protocol working for every other reason, and a broad relaxation is how two
  runners end up driving one unit. The reason test is the whole point.
- **Do not fix it by deleting or closing the dead branch.** `superseded` is
  *reported and never acted on* — that is a stated property of the claim
  protocol, and the operator closes such a claim out. A run that tidied the
  branch to make its own claim succeed would be acting on it.
- **Do not fix it in `plan-units.sh` by withdrawing the offer.** Withdrawing it
  restores exactly the measured 2026-08-26 defect: a mission `active` at 2/3
  acceptance with queued tickets that no survey would offer.
- **A batch unit hits the artifact branch, not the unit-id branch.** Its id is
  minted from the clock and cannot collide, so a batch of freed tickets is
  refused on the *overlap* check instead. Both branches need the reason test or
  the fix covers only mission units — which is the grain that happened to be
  measured.
- **The blocked mission's own ticket declares `verification_handoff:`**, so the
  unit it unblocks will take the handoff route rather than merge. That does not
  reduce the defect: the unit cannot reach the handoff route either.

## Final Report

Development completed as planned, with one finding that changed what the work was.

**Steps 2-6 had already landed on 2026-08-27**, while this ticket was queued behind a
stranded publication (PR #635, opened 2026-08-26, delivered by this run five days later).
`claim.sh` §3 already carries the `superseded` skip **before** both grains — the unit-id
match and the artifact overlap — reading `_held_reason` from `claims_scan`'s existing row
rather than re-deriving anything, and `reference/claims.md` and `CLAUDE.md` already state
it. So this run verified those steps rather than re-implementing them, and did the one
step that was genuinely outstanding: **step 7, the drill**.

**Step 1, the reproduction, verbatim.** `verify-merged-claim` proved the four *readings*
and never the **claim**, so it would have passed over a fully reverted fix. Confirmed by
deleting the `superseded` skip from `claim.sh` and re-running the extended drill:

```json
{"claimed": false, "reason": "already_claimed", "unit": "drilled",
 "holder_branch": "work-20260101-000000", "holder_unit": "drilled"}
```

That is the defect verbatim — the survey names the unit in `resurveyed[]` and the fresh
claim the survey's own comment prescribes is refused as though the dead branch were in
flight. With the skip restored the same row reads `"claimed": true`. The breaker row stayed
**true** across both runs, which is what makes it a breaker rather than a second copy of the
behaviour row: only `merged_claim_fresh_claim` moved.

**Step 7.** Three rows added to `cmd_verify_merged_claim`, still hermetic — no network, no
credential, the same stubbed transport, and the checkout byte-identical:

- `merged_claim_live_refuses` (`bearing: breaker`) — with no merged pull request the claim
  is not superseded and the fresh claim is still refused `already_claimed`.
- `merged_claim_fresh_claim` — with the lookup answering `merged` the claim goes through.
- `merged_claim_branch_untouched` — the superseded branch is still on the origin afterwards.

The two claim rows differ in **one fact** — whether the stubbed lookup answers `merged` —
with the fixture, the identity and the collapsed heartbeat window held constant, so what
the breaker breaks is the behaviour and not a return shape.

**Step 5 needed no work.** `claims_unit_resolution` already resolves a unit held by a live
claim and a superseded one to the live row, and the suite already pins the two-branch shape.

**Step 8.** `drive/SKILL.md` §3 gained the exception (it said only "`already_claimed` → drop
the unit and continue (the protocol working)", which is what made the defect invisible to a
reader); `docs/loop-drill-runbook.md` gained the three blame-table rows, the §5i paragraph
and the register flip to `Breaker: yes`. `CLAUDE.md` and `reference/claims.md` already
agreed and were left alone.

### Discovered Insights

- **Insight**: `verify-merged-claim` carried **no** `bearing: "breaker"` row before this
  change, so the drill register classified it `unproved` — a gap counted outside the passing
  total. The drill reported `verdict: pass, breakers: 0` the whole time.
  **Context**: `unproved` is the register's word for *this drill has never been shown able to
  fail*, and it is easy to miss precisely because the drill is green. The three rows added
  here close it as a side effect of proving the claim: `verify-all` now reports 30 proved
  where it reported 29, with the same 0 failures.

- **Insight**: A ticket can outlive its own defect. This one was written 2026-08-26, the fix
  landed 2026-08-27, and the ticket reached `todo/` on 2026-09-01 because the publication
  carrying it sat `clean` and undelivered for five days.
  **Context**: A driving run must verify a ticket's premise against the tree before
  implementing it — re-applying an already-landed change would have been the failure mode
  here. The queue's arrival order is not evidence about the code's current state.
