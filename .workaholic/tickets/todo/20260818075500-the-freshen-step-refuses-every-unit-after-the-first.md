---
created_at: 2026-08-18T07:55:00+00:00
author: a@qmu.jp
assignees: []
depends_on:
feedback: []
merge_policy:
verification_handoff: 
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
