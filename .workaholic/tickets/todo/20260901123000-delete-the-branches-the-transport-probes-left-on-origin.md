---
created_at: 2026-09-01T12:30:00+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff:
feedback: 20260830081659-stop-two-runs-from-claiming-and-driving-one-unit.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Delete the branches the transport probes left on origin

## Overview

**Minted mid-drive, 2026-09-01, from an observation outside the driving ticket's scope.** The
measurements that established *what the claim contends for* had to create a ref to learn that the
create was permitted and the delete was not. Two of those probe branches still stand on origin,
and the container that made them cannot remove them:

```
5b6427654b3c3ad955755e446a3474c81e22cfe8	refs/heads/wh-probe-20260831194543
304652b2b9f21b444f9b963a37c6e1462b2c1b66	refs/heads/wk-transport-probe-1788104778
```

Confirmed present by `git ls-remote origin` on 2026-09-01, four and one days after they were
pushed. They are recorded today only as a *Residue* paragraph inside
`20260830082251-make-the-claim-contend-for-one-ref-per-unit.md`, which is **blocked on an
operator ruling** — so the cleanup is bound to a ticket that may never be driven, and nothing in
the queue names it as work.

They match neither `work-*` nor `release/*`, so no claim scan sees them and no verdict is wrong
because of them. What they cost is smaller and real: they are two entries in every
`git ls-remote`, every branch list and every `list-branches` page, indistinguishable to a reader
from a branch somebody is using, in a repository where 268 of 302 branches were already
undeleted residue on 2026-09-01.

**This ticket is the cleanup, not the mechanism.** It does not touch the claim protocol, the
contended-ref question, or the blocked mission item those probes were measuring.

## Policies

- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:safety` — a job holding `contents: write` is a capability, and its bounds are the design

## Key Files

- `.github/workflows/claim-retirement.yml` — the one job in this repository that holds `contents: write` and deletes a branch
- `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` — the act it runs, bounded by `not_a_work_branch` / `release_branch` / `not_on_base` / `pull_request_open`
- `plugins/workaholic/skills/drive/reference/claims.md` — *What the claim contends for*, where the probes and their 403s are recorded
- `.workaholic/tickets/todo/20260830082251-make-the-claim-contend-for-one-ref-per-unit.md` — the *Residue* paragraph this ticket lifts the work out of

## Implementation Steps

1. Re-read `git ls-remote origin 'refs/heads/wh-probe-*' 'refs/heads/wk-transport-probe-*'`
   first. If both refs are already gone, the work is done by somebody else: say so, delete the
   *Residue* paragraph's standing ask from the mechanism ticket, and archive this one. Do not
   push a probe of any kind to re-establish the finding — the mechanism ticket says *read it, do
   not re-probe it*, and every permitted probe leaks another undeletable ref.
2. Decide **where the delete runs**, and record the choice with its bound. The container this
   loop runs in is refused the delete over both sanctioned transports (403, measured twice), so
   the only executors available are a person at a terminal and a workflow holding
   `contents: write`. Prefer the narrowest one that closes the case.
3. If the answer is the workflow: do **not** widen `delete-retired-claim-branch.sh`. Its refusal
   set is what makes it safe, and a branch that is neither a claim nor on the base is exactly
   what it refuses by design. A separate, `workflow_dispatch`-only job taking the branch name as
   an explicit input — deleting what it was handed and nothing it discovered — is the shape that
   deletes these two without giving any scheduled job a way to delete a third.
4. If the answer is a person: state it as a person's act rather than leaving it implied. Name
   the two refs and the exact command in a place a person reads — the run report reaches nobody
   after the container dies — and do not mark this ticket implemented on the strength of having
   written the instruction down.
5. Whichever path is taken, remove the standing ask from the mechanism ticket's *Residue*
   paragraph once the refs are gone, so a later reader is not sent after branches that no longer
   exist. Leave the **measurements** themselves in place: they are the finding, and they are
   still the reason nobody should re-probe.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `git ls-remote origin` names neither `wh-probe-20260831194543` nor
  `wk-transport-probe-1788104778`.
- No scheduled job gained the ability to delete a branch it discovered rather than one it was
  handed; `delete-retired-claim-branch.sh`'s refusal set is byte-identical.
- No new ref was pushed to origin in the course of the work.
- The mechanism ticket's *Residue* paragraph no longer asks for an act that is done, and its
  transport measurements are unchanged.

**Verification method** — the commands/tests/probes that prove them:

- `git ls-remote origin 'refs/heads/wh-probe-*' 'refs/heads/wk-transport-probe-*'` returns empty.
- `git diff` on `plugins/workaholic/skills/drive/scripts/delete-retired-claim-branch.sh` is empty,
  or the diff shows no refusal removed.
- `node scripts/test-workflow-scripts.mjs` passes.
- `sh scripts/e2e/loop-drill.sh verify-all` passes.

**Gate** — what must pass before approval:

- The two refs are gone, and nothing acquired a broader delete than it had.

## Considerations

- **A delete is irreversible and outward-facing**, which is the safety floor's own territory. The
  two refs named here are the whole scope; a job or a person that deletes by pattern rather than
  by name is how a cleanup becomes an incident. If a pattern is unavoidable, bound it to these
  two literal names.
- **The commits are not lost by the delete** — both are reachable objects with no work of their
  own (`304652b2` and `5b642765` were pushed as pointers to a then-current base commit, not as
  new work). Confirm that before deleting rather than assuming it: a probe branch that somebody
  later built on is no longer a probe branch.
- **This is not the mission's blocked item.** The mission's first acceptance item waits on an
  operator ruling about the contended ref; this ticket is driveable now and independent of that
  ruling in both directions.
