---
created_at: 2026-08-18T07:00:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
feedback: []
merge_policy:
verification_handoff: 
claim: work-20260818-113659
---

# A run that merges cannot survey again

## Overview

<!-- MINTED MID-RUN by an /implement tick (2026-08-18, session cse_01HZ3yAB1n4f4qnE81c6Yeqs).
     The run drove and merged one unit, then could not survey for the next one. -->

An unattended `/implement` run in a Claude Code Web container drives **at most one PR-unit per
tick**, and the wall it hits is one the run puts up itself.

The container hands the session a checkout **detached at the then-current `origin/main` tip**.
`sync-main.sh` §1a admits exactly that shape: parked off the base, standing on the base's *exact
tip*, clean tree → `ok: true, off_base: true`. The run surveys, claims, drives, reports, and — on
a `review` unit — **merges**. That merge advances `origin/main`. The caller's checkout does not
move; nothing in the drive path moves it, and §1a's own comment says so explicitly ("moving the
caller's checkout is not this script's licence to take"). The proof that admitted the tick a
minute earlier now fails: HEAD is one merge *behind* the tip.

`sync-main.sh` returns `not_on_main`, which `workaholic:drive` §1 says **terminates `pending`**,
and it is right to: the stale survey is actively wrong, not merely old.

**Measured, this tick.** After merging PR #490, `plan-units.sh` reported `current: false` and
offered `20260818062340-rename-fullfill-to-prepare-release.md` as queued backlog — a ticket the
same run had archived four commits earlier. `git ls-tree origin/main .workaholic/tickets/todo/`
showed it gone. Claiming off that survey would have been a **double-pick**, the failure class
`loaded_version_behind_registry` was originally written to prevent (2026-08-04). The run stopped,
correctly, leaving one genuinely-queued ticket undriven for an hour.

**This is a throughput ceiling, not an occasional stall.** Every tick that merges anything ends
this way, by construction. A tick that merges nothing (all units demoted, blocked or handed off)
is unaffected — which is the inversion worth noticing: the run is penalised precisely for
succeeding.

## Policies

- `workaholic:operation` / `policies/observability.md` — the loop's throughput is an
  operator-visible property, and a ceiling nothing names reads as "there was no more work"
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/branching/scripts/sync-main.sh` — §1a is the admitting proof and its
  header states the constraint any fix must respect. Read the whole §1a comment before touching
  it: the exception deliberately rests on a checkable proof rather than a branch-name allowlist,
  and it deliberately mutates nothing.
- `plugins/workaholic/skills/drive/SKILL.md` §1 and `reference/survey.md` (the freshness table) —
  the caller's contract: `not_on_main` terminates `pending`. Whatever changes, the rule that a
  **stale survey is never surveyed** does not.
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` — already computes `current` by
  comparing `surveyed_sha` to `base_sha`, so the run has the fact it needs; what is missing is a
  sanctioned way to *act* on it.
- `plugins/workaholic/skills/drive/scripts/claim.sh` — worth reading as the counter-example: it
  fetches and cuts its worktree from `origin/main`, so the **drive** of a unit is already immune
  to a stale caller checkout. Only the survey is not.

## Implementation Steps

1. Reproduce it hermetically first, in `scripts/test-workflow-scripts.mjs`: a detached checkout at
   `origin/main`'s tip, clean; advance `origin/main` by one commit; assert `sync-main.sh` refuses
   `not_on_main` today. The test must fail before the fix.
2. Decide **where** the answer belongs, and record the reasoning. Two shapes, both plausible, and
   the choice is the substance of this ticket — see Open Decisions.
3. Whatever is chosen, preserve every property §1a was built on: the admission rests on a
   **mechanical proof**, never on a branch name; a **dirty** tree still refuses; a checkout
   carrying **local commits** still refuses; and a divergence a developer created is still a
   human's decision, never resolved by a script.
4. Do **not** make the survey tolerate staleness. `current: false` must keep forbidding `ok` and
   the run must keep refusing to claim off a stale read; this ticket is about removing the
   staleness, not about surveying through it.
5. Add a smoke assertion that two consecutive units can be surveyed and claimed across an
   intervening merge — the property the ticket exists to restore, stated as a test rather than
   as prose.

## Open Decisions

<!-- Recorded, not resolved: an unattended run may not rule on either of these. Both change a
     script's licence over the caller's checkout, which is exactly the kind of decision §1a's
     author declined to take unilaterally. -->

1. **Should `sync-main.sh` be allowed to move a detached, clean, strictly-behind checkout to the
   base tip?** It is not a merge and not a reset — it discards nothing, because a detached clean
   HEAD with no local commits holds nothing to discard, and the same "provably absent rationale"
   test §5 already uses for the realign case would apply. Against it: the script's header states
   flatly that moving the caller's checkout is not its licence, and widening that is a standing
   grant, not a one-off.
2. **Or should the run re-derive freshness after each merge instead?** The drive loop knows it
   merged; it could re-open the survey against `origin/main` directly (as `claim.sh` already
   does) rather than through the caller's tree, leaving `sync-main.sh` untouched. Against it:
   that is a second freshness path beside the one the contract names, and two of those eventually
   disagree — the exact failure mode this repository cites for restating a rule twice.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A run that surveys, claims, drives and **merges** one unit can survey again in the same run and
  see the base's real queue — with the merged unit's ticket **absent** from the backlog.
- A stale survey is still never acted on: `current: false` still forbids `ok`, and no path claims
  a unit off a read known stale.
- Every existing `sync-main.sh` refusal is unchanged: dirty tree, local commits, genuine
  divergence, no origin, unreachable origin.
- The chosen Open Decision is recorded with its reasoning in the Final Report, and the rejected
  shape is answered rather than ignored.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — including the step-1 reproduction and the step-5
  two-units-across-a-merge assertion, both demonstrated failing before the fix
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs`
- `bash plugins/workaholic/hooks/layout-doctor.sh .` → `conforming: true`
- `sh scripts/e2e/loop-drill.sh verify-implement --json`

**Gate** — what must pass before approval:

- All of the above, plus the Final Report naming which Open Decision was taken and why the other
  was not.

## Considerations

- **The cost is measurable and worth measuring before deciding.** Every `[Implement]` tick since
  the immediate-merge route landed (2026-08-11) has been able to drive one unit at most. How much
  queue that left standing is answerable from the archive's per-branch ticket counts, and the
  number belongs in the Final Report — it is the argument for whichever fix is chosen.
- **`off_base` was itself a narrowing of a refusal, added on measurement** (2026-08-12, after
  ticks died before surveying with work queued). This ticket is the same shape of finding one tick
  later in the run, and any fix should read that section's reasoning as a template rather than
  overwrite it.
- **A tick that merges nothing does not hit this**, so the symptom is invisible in exactly the
  runs an operator is most likely to inspect.
- This ticket carries no `feedback:` reference: nobody reported it, a run tripped over it.

## Final Report

Development completed as planned, **jointly with
`20260818075500-the-freshen-step-refuses-every-unit-after-the-first.md`** — the same defect
minted twice by two ticks (this one measured it after merging PR #490, the other after PR #492).
They were driven as one PR-unit because one change answers both; the full reasoning, the rejected
alternative and the measurement live in that ticket's Final Report, and this report states the
decision and what it means for this ticket's own gate.

### The Open Decision, resolved

**1. May `sync-main.sh` move a detached, clean, strictly-behind checkout to the base tip? → Yes,
and that is what shipped (§1b).** This ticket's own framing is what carried it: "it is not a merge
and not a reset — it discards nothing, because a detached clean HEAD with no local commits holds
nothing to discard, and the same *provably absent rationale* test §5 already uses would apply."
That is exactly the argument §5 was admitted on, applied to a narrower shape, and the standing-grant
objection is answered by the **detached** requirement — a *named* off-base branch behind the base is
a developer's branch and still refuses, byte-unchanged, so the grant does not widen to any ref a
person created.

**2. Or should the run re-derive freshness after each merge instead? → Rejected, for this ticket's
own stated reason.** A second freshness path beside the one the contract names is two rules that
eventually disagree. It is also more than a script change: every consumer of the survey uses the
returned ticket **paths** against the checkout, so a survey reading `origin/main` directly would
hand `claim.sh` paths the rest of the run cannot act on.

**The survey was not taught to tolerate staleness** (this ticket's Step 4, and its second acceptance
criterion): `current: false` still forbids `ok`, no path claims off a read known stale, and the fix
removes the staleness instead of surveying through it. The regression fixture proves the difference
by advancing `origin/main` through an *archive* — what a merged unit does — and asserting the
merged unit's ticket is **absent** from the next survey's backlog.

### Discovered Insights

- **Insight**: this ticket and `20260818075500` are the same finding minted by two consecutive
  ticks, neither of which could see the other's work.
  **Context**: a run mints into a publish tree behind a pull request, so a defect the loop keeps
  hitting gets re-minted every tick until one of those tickets is merged *and* driven. The duplicate
  is the failure contract working as designed, not a bug — but it means a recurring structural
  defect costs one ticket per tick until it is fixed, which is itself an argument for driving this
  class first.
