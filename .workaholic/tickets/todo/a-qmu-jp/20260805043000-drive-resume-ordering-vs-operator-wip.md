---
created_at: 2026-08-05T04:30:00+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy:
---

# /drive resume ordering overrides the operator's actual WIP, and same-machine resume fails

## Overview

An attended `/drive` run this morning produced exactly the confusion the claim protocol
is meant to prevent, and the developer had to interrupt twice to ask "there is already a
PR — what are you doing?" and "why did you pick that? my WIP was the other one". Three
compounding behaviors caused it:

1. **Resumable-first ordering has no operator override.** The survey offered a stale
   claim (unit B — a `review`-policy unit that had *stopped at its open PR* the previous
   evening, with two follow-up tickets minted on its branch) as `resumable`, and the
   Unified Run mandates taking a resumable over claiming anything fresh — "a resumable
   unit left untaken forbids `ok`". Meanwhile the developer's actual WIP was a
   roadmap-active mission (mission A, 11/12 acceptance criteria met, whose next step is
   a CARRY resume ticket written the same evening precisely to be picked up next). The
   run spent its first ~40 minutes on unit B. Mechanically correct, humanly wrong: the
   repo's own convention for "this is where to resume" (a CARRY ticket inside an active
   mission) ranks *below* a heartbeat-lapsed claim in the offer, and the contract gives
   the runner no sanctioned way to prefer the operator's stated priority.

2. **"Parked at PR" is indistinguishable from "died mid-drive".** The resumability
   verdict already excludes a review unit whose queue is drained (`claimed_reported`),
   but a unit that stopped at its PR *with follow-up tickets still in `todo/` on the
   branch* looks identical to one that died. From the operator's seat, an open PR means
   "parked, waiting for a human"; the run reopening it reads as redoing finished work.
   The resume offer carries no PR context either — neither the survey row nor the
   takeover announcement mentions that the unit already has an open PR, so the operator
   cannot tell why it was picked up.

3. **`claim.sh resume` fails in the most common case: same machine, worktree still
   present.** It delegates to the worktree creator, which refuses with
   `worktree already exists` → `worktree_creation_failed`. A run resuming its *own*
   machine's claim (the narrow, safe case resumption was designed for) always hits
   this, and the agent had to hand-roll the takeover: the empty `Resume a PR-unit`
   commit via commit.sh, the push, and the notifier call — replicating claim.sh's
   internals by hand, which is exactly the failure mode the sanctioned scripts exist
   to prevent.

A fourth, smaller gap: the takeover announcement goes only through the Slack notifier.
With no token configured it is a silent no-op, so an *attended* operator learns about
the takeover only from tool chatter — the interactive narration duty is left entirely
to the agent, and when the agent under-narrates the operator sees an unexplained detour.

## Proposal

1. **Same-runner resume must work.** When the claim worktree already exists locally and
   its HEAD equals the pushed tip that the resumability decision observed, `claim.sh
   resume` should adopt it (publish the takeover commit on it) instead of failing
   through the creator. The race arbitration (push wins/loses) is unchanged.

2. **Let the operator's WIP outrank a takeover.** Options, smallest first:
   - Include the open-PR URL and the unit's last-commit summary in the `resumable[]`
     row and in the takeover announcement, so both agent and operator see what is being
     reopened and why.
   - Distinguish `resume_reason` for "stopped at its PR with follow-up tickets" from
     "died mid-drive" (e.g. `parked_with_pr` vs `heartbeat_lapsed`), and let the
     Unified Run treat `parked_with_pr` as *reportable* rather than *mandatory* — an
     attended run may defer it with a recorded decision instead of being forbidden `ok`.
   - Alternatively (or additionally): when an active mission's next ticket is a CARRY
     resume ticket, rank that mission's offer ahead of parked-with-pr takeovers. CARRY
     is already the human convention for "resume here"; the survey just cannot see it.

3. Keep the unattended contract intact: a truly dead unit (heartbeat lapsed, no PR, or
   queue undriven with no PR) stays a mandatory takeover exactly as today.

## Notes

- Related but distinct from `20260805033616-drive-land-unit-now.md` (landing a unit so
  a fresh session can resume): that ticket is about *publishing* WIP; this one is about
  the *offer ordering and resume mechanics* on the next run.
- Observed on 2026-08-05 during an attended morning run on a private client repository;
  the client-side specifics are intentionally not reproduced here.
