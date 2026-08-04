---
created_at: 2026-08-05T03:36:16+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 2h
commit_hash:
category: Added
depends_on:
mission:
merge_policy:
claim: work-20260804-195932
---

# Add a sanctioned "land this unit now" flow for developer-present sessions

## Overview

When a developer is present and says "wrap this unit up so a fresh session can resume
immediately", the plugin has no path for it. The two existing routes both fail that ask:

- `auto` ships unattended — but the unit's policy was `review`, so it does not apply.
- `review` stops at a PR — but the artifacts a fresh `/drive` needs (tickets minted
  mid-run, which the Unified Run correctly commits on the claim branch) stay invisible
  to every other session until a human merges the PR *out of band*. "Published" work
  is not claimable work.

In practice the agent ended up hand-rolling the landing: local `git merge` of the claim
branch into main, a manual recovery when origin/main had moved (non-fast-forward), a
manual `cleanup-mission-worktree.sh`, and a manual remote-branch delete. That is exactly
the kind of sequence the sanctioned scripts exist to own — every step has a script, but
nothing composes them, so the composition was improvised under time pressure.

The `review` policy's own rationale ("a human must look") is satisfied *in person* in
this scenario: the developer is standing in the session issuing the instruction. The
missing piece is a flow that treats an explicit, present-developer instruction as the
review.

## Proposal

A `/drive land <unit-id>` (or a ship-flow variant) that, **only on explicit developer
instruction in an interactive session**:

1. catches up with origin/main (absorbing a moved base, the step that was fumbled by hand),
2. merges the claim branch into main and pushes,
3. releases the claim by that merge and tears the worktree/branch down via the existing
   cleanup scripts,
4. reports that the unit's artifacts are now on main and claimable.

It must refuse in headless/cron context — the whole point is that the human is the review.
The release-scan block/secret gates apply unchanged.

## Policies

- `rules/general.md` — the sanctioned-scripts principle: compositions the runs need
  should exist as scripts, not be improvised
- `skills/drive/SKILL.md` — Unified Run §6 (routing) is where this third route belongs

## Quality Gate

**Acceptance criteria**:

- A single sanctioned command lands a claimed unit to main from an interactive session,
  including the moved-base case, and leaves the survey offering the unit's leftover
  tickets immediately afterwards
- Headless invocation refuses with a clear reason
- No hand-rolled `git merge`/push is needed for this scenario anymore

**Verification method**: exercise on a scratch unit — claim, mint a ticket mid-run, land,
then `plan-units.sh` shows the ticket claimable; repeat with origin/main advanced by
another commit to cover the non-fast-forward path.

## Considerations

- Related friction observed in the same session: **resumable-first ordering** sends the
  next run to a stale claim whose remaining queue is a single already-`blocked` ticket,
  ahead of a freshly relevant mission. A resumable unit whose leftover todo tickets were
  all recorded `blocked` in prior runs might reasonably rank behind fresh units, or the
  resume should fast-path to handoff. Possibly its own ticket; noted here for context.
- Mid-run minted tickets being invisible until merge is by design (J1) and this proposal
  does not change it — it shortens the distance to the merge instead.

## Final Report

Development completed as planned. `land-unit.sh` composes the existing scripts —
`catchup-main.sh` for the base, `scan-branch-safety.sh` for the gates,
`cleanup-mission-worktree.sh` for the teardown, `sync-main.sh` for the visibility — and
adds only the ordering and the human gate around them.

### Discovered Insights

- **Insight**: The landing push is `git push origin <branch>:main`, not a local
  `git merge` into `main`. A local merge mutates the caller's checkout *before* the push,
  so a rejected push leaves it ahead of origin, and the only cheap repair for that state
  is `git reset --hard` — which the drive safety floor forbids outright.
  **Context**: `publish-tree-commit.sh` already lands this way for the same reason. Any
  future seam that needs to put a branch on the base should reach for the ref-push idiom
  rather than reinventing a local merge; the retry story falls out of it for free, because
  a rejection has changed nothing anywhere.

- **Insight**: `land-unit.sh` is the inverse of `release-claim.sh` in teardown order, and
  the inversion is load-bearing in both directions. Release tears the worktree down before
  dropping the claim, so a refused teardown never advertises a free unit over unpushed
  work; land pushes first, because a failed teardown after a successful land loses nothing
  while an early teardown would destroy the branch still to be pushed.
  **Context**: The two scripts look symmetrical enough that a future reader may try to
  unify their order. They must not be unified — the asymmetry follows from which side of
  the operation is irreversible.

- **Insight**: The headless backstop is checked *before* the `--developer-present` flag and
  cannot be overridden by it. The flag is an instruction, not evidence; only the
  environment marker is something the caller did not choose in the moment.
  **Context**: `authorize-routine-change.sh` reaches the same conclusion by a different
  route (a digest that proves content, not presence). Neither script can prove a human was
  in the room, and neither is sold as doing so — what they buy is that the unsafe path is
  never reached by omission.

- **Insight**: The scan emits its top-level `verdict` with a space after the colon and its
  finding objects without one (`"severity":"hard"`). A consumer matching on the pretty form
  silently never sees a hard finding.
  **Context**: This bit once during implementation. Any new consumer of
  `scan-branch-safety.sh` should match the compact form for per-finding fields.
