---
created_at: 2026-08-18T07:55:00+00:00
status: done
author: a@qmu.jp
assignees: []
depends_on:
feedback: []
merge_policy:
verification_handoff: 
claim: work-20260818-113659
---

# The freshen step refuses every unit after the first

## Overview

<!-- MINTED MID-RUN by an /implement unit (branch `work-20260818-073640`), under the failure
     contract's "an observation outside the current ticket's scope becomes a ticket". -->

`sync-main.sh` §1a lets a checkout parked off the base survey anyway, but **only while it stands
on the base's exact tip**. A cloud container's checkout is exactly that shape — detached HEAD at
`origin/main`'s tip, clean — so the first freshen of a run passes with `off_base: true`.

Then the run merges its first unit's pull request, `origin/main` advances, and the detached
checkout is now *behind*. Every later freshen in the same run returns
`{"ok": false, "reason": "not_on_main", "branch": ""}` — which `workaholic:drive` §1 terminates
`pending` on — and `plan-units.sh` reports `current: false` while still offering the ticket the
run archived minutes earlier.

**Measured, not hypothesised.** On 2026-08-18 the `[Implement]` tick surveyed two unrelated
tickets, drove and merged the first (PR #492, base `671aa8e4` → `80714fc6`), and then could not
survey for the second: the same checkout that passed §1a at 07:36 refused `not_on_main` at 07:54,
with a claimable ticket queued and nothing wrong with the tree. The run ended `pending` having
driven one of two units, and the obstacle was **the run's own success**.

The shape is one-directional: an `/implement` run in a detached container drives **at most one
PR-unit per tick**, whatever the survey offered, and the reason it stops is invisible in the
routine's finish line because the second unit was never claimed.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a run that stops for a repairable reason
  must not read like a run that found nothing to do

## Key Files

- `plugins/workaholic/skills/branching/scripts/sync-main.sh` — §1 and §1a. The proof at §1a is
  "HEAD == `origin/<base>` tip, tree clean"; read its header comment before touching it, which
  records why every other off-base shape refuses (ticket `20260812215500`, 2026-08-12).
- `plugins/workaholic/skills/drive/SKILL.md` §1 and §7 — the caller: `not_on_main` terminates
  `pending`, and `current: false` forbids `ok`. Whatever this ticket changes, the run must keep
  refusing to survey a checkout it cannot vouch for.
- `plugins/workaholic/skills/drive/reference/survey.md` — the refusal table's `not_on_main` row
  carries the 2026-08-12 narrowing verbatim; the sequel belongs beside it.
- `scripts/test-workflow-scripts.mjs` — the hermetic harness already builds a repository whose
  local base diverges from `origin` (`mission worktree starts from the merged base (fetch-first)`),
  which is the fixture shape a detached-and-behind checkout needs.

## Implementation Steps

1. Reproduce first: a fixture with a **detached** HEAD on `origin/main`'s tip and a clean tree,
   asserting `ok: true` / `off_base: true`; then advance `origin/main` by one commit and assert
   the current script answers `not_on_main`. The second assertion must hold before the fix.
2. Decide the rule and state it in `sync-main.sh`'s header, where §1a's reasoning already lives.
   The candidate is narrow: a **detached, clean** HEAD that is a strict **ancestor** of
   `origin/<base>` carries no local work to lose, so fast-forwarding the checkout to the base tip
   destroys nothing — which is a different act from the `git reset --hard` §1 forbids, and must be
   argued as such rather than assumed. Any of dirty / ahead / diverged / on a named branch keeps
   refusing `not_on_main` exactly as today.
3. Whatever is decided, the caller must be able to tell "freshened by fast-forward" from "was
   already current" — report it in the JSON (`advanced` already exists) so the run report can say
   the checkout moved rather than implying it never needed to.
4. Re-run the step-1 fixture and the full smoke suite.

## Open Decisions

<!-- Recorded, not resolved: this run minted the ticket while driving something else. -->

1. **Fast-forward the checkout, or leave the base alone and let the survey read `origin/main`
   directly?** The second is the larger change and the more honest one — `plan-units.sh` already
   fetches, and a survey that reads the *base ref* instead of the *working tree* would not care
   what the container checked out. It is also the riskier one, because every consumer of the
   surveyed tree (the ticket paths the claim then uses) assumes the checkout. Recording both
   rather than picking: the first is a three-line change to one script, the second is a contract
   change to the survey.
2. **Should the run instead re-freshen only between units?** It already does — that is where this
   was measured. The question is whether a mid-run freshen failure should terminate the run at all
   when the *first* one passed, or degrade to "survey what is known and stop offering", which
   `workaholic:drive` §7 has no vocabulary for today.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A detached, clean checkout that is a strict ancestor of `origin/<base>` no longer terminates the
  run at `not_on_main` — and the JSON says how the checkout came to be current.
- Every other off-base shape (dirty, ahead, diverged, a named non-base branch) still refuses
  `not_on_main`, byte-unchanged.
- No local commit is ever discarded by the new path — proven by a fixture where the detached HEAD
  carries a commit `origin/<base>` does not, which must still refuse.
- An `/implement` run in a detached container can drive a second PR-unit after merging its first.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`, including the new detached-and-behind fixture,
  demonstrated failing against the unfixed script first
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`

**Gate** — what must pass before approval:

- All of the above, plus the Final Report resolving both Open Decisions explicitly, with the
  reasoning for the one not taken.

## Considerations

- **The blast radius is the whole unattended loop's throughput.** `/implement`'s contract is
  "keep going until nothing is claimable"; in a cloud container it has been silently capped at one
  unit per tick for as long as §1a has existed (2026-08-12). How many past ticks stopped this way
  is answerable from the routine's session logs and worth a look while fixing this.
- **Do not "fix" this by relaxing §1's refusal in the caller.** The refusal is what keeps a run
  from surveying a tree it cannot vouch for; the defect is that a provably-safe shape is being
  refused, not that refusing is wrong.
- This ticket was minted by a run driving an unrelated documentation change, which is why it
  carries no `feedback:` reference — nobody reported it; a run tripped over it.

## Final Report

Development completed as planned. `sync-main.sh` gained **§1b**, the sequel to §1a: a **detached**,
clean HEAD that is a strict **ancestor** of `origin/<base>` is fast-forwarded onto the base tip and
reported `ok: true` with `advanced: true`, `fast_forwarded: true` and `previous_sha`. Every other
off-base shape refuses `not_on_main` byte-unchanged.

Driven together with `20260818070000-a-run-that-merges-cannot-survey-again.md`, which reports the
same defect from the other side (that run measured it after merging PR #490; this one after PR
#492). One fix answers both; each ticket's own Open Decisions are resolved below.

### The Open Decisions, resolved

**1. Fast-forward the checkout, or let the survey read `origin/main` directly? → Fast-forward the
checkout (§1b).** The rejected shape is answered rather than ignored: reading the base ref instead
of the working tree would give the repository **two** freshness paths beside the one the contract
names, and the ticket's own text says why that is worse ("two of those eventually disagree"). It is
also not a localized change — every consumer of the survey uses the returned ticket **paths**
against the checkout (`claim.sh` stages those exact paths), so a survey that read `origin/main`
would return paths the rest of the run cannot act on without a second checkout. The fast-forward is
three lines in one script and keeps one freshness path.

**Why it is not the licence the header withholds.** §1a's comment says "moving the caller's
checkout is not this script's licence to take" — written about §1a, where HEAD already *equalled*
the tip, so moving it would have been risk for no gain. §1b is the header's own rationale applied,
not widened: the refusals rest on "a reset would discard a developer's local commits", and a
detached clean HEAD that is a strict ancestor holds nothing to discard — no branch points at it, no
commit on it is absent from the base, no edit is pending. `git checkout --detach <base-tip>` is a
fast-forward of the working tree, the same operation §4 already performs on a base branch, and it
refuses on its own if anything would be overwritten. **Detached is load-bearing**: a *named*
off-base branch behind the base is a developer's branch, and moving it would rewrite a ref a person
created and silently change which branch they are on — so it keeps refusing, which the suite
asserts directly.

**2. Should a mid-run freshen failure terminate the run when the first one passed? → No vocabulary
change; the question is moot for this shape.** `workaholic:drive` §7 has no "degrade to survey what
is known" state, and this fix removes the staleness rather than teaching the run to tolerate it —
which is what Implementation Step 4 and ticket `20260818070000`'s Step 4 both require. A freshen
that *still* fails mid-run now means a shape §1b deliberately refuses (dirty, ahead, diverged, a
named branch), and those are exactly the states a run must not survey through. Inventing a partial
state for them would reintroduce the staleness tolerance through the caller.

### Measured, as both tickets asked

Since the immediate-merge route landed (2026-08-11), the archive carries **41 PR-units across 41
branches in 26 UTC hours that saw any drive at all — and 20 of those 26 hours carried exactly one
unit**. The three ticks before this one (`work-20260818-063646`, `-073640`, `-083716`) each archived
exactly one ticket. The number is suggestive rather than proof — an attended `/drive` from a
non-detached checkout never hit this, and the archive does not record which entry point drove a
branch — but it is the shape the ceiling predicts, and this run itself is the direct evidence: it
was the fourth consecutive tick to face a four-ticket queue.

### Discovered Insights

- **Insight**: the two `not_on_main` cases §1a and §1b admit are the *same* container, eighteen
  minutes apart — the difference is only whether the run has merged anything yet.
  **Context**: §1a was written from a measurement taken at a tick's *start*, so the exact-tip proof
  looked total. The defect only exists after a merge, which is why five days passed before anyone
  saw it and why a tick that merges nothing still looks healthy. When a proof is derived from a
  measurement, check whether the run's own actions can falsify it later in the same run.
- **Insight**: the reproduction is only visible against the **base**, never against the checkout.
  **Context**: the regression fixture advances `origin/main` by *archiving* a ticket — what a merged
  unit actually does — and then asserts `plan-units.sh` no longer offers it. Asserting on
  `sync-main.sh`'s JSON alone would have passed a fix that moved HEAD without making the survey
  correct, which is the property the loop actually needs.
