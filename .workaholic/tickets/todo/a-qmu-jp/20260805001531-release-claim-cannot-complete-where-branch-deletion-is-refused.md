---
created_at: 2026-08-05T00:15:31+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
---

# release-claim.sh half-releases a unit where the runner may push but not delete a branch

## Overview

`drive/scripts/release-claim.sh` tears the worktree down **first**, then deletes the remote
claim branch. That order is deliberate and correct — a refused teardown must never publish
"this unit is free" over unpushed work — but it assumes the second step can only fail
transiently. In the Claude Code on the web container the hourly runner uses, **branch
deletion is refused outright while pushes succeed**, so the second step can never succeed and
the script leaves a state it has no way back from:

- the worktree is gone,
- the remote claim branch is still there, so the claim is still live,
- and the unit is offered as `resumable` to every later tick, forever.

Re-running the script does not help: it deletes the worktree again (already gone) and hits
the same refusal. There is no path from inside the loop to a released claim.

## Measured, 2026-08-05T00:14Z

```
$ bash drive/scripts/release-claim.sh batch-20260804225826
error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
{"released": false, "reason": "remote_delete_failed", "unit": "batch-20260804225826", "branch": "work-20260804-225829"}

$ git push origin --delete work-20260804-225829      # retry, same session
send-pack: unexpected disconnect while reading sideband packet
fatal: the remote end hung up unexpectedly
Everything up-to-date
```

It is a permission boundary rather than a hiccup: the same session had already pushed a claim
commit, several work commits and a story to this remote without trouble, and the delete failed
twice. `curl "$HTTPS_PROXY/__agentproxy/status"` reports `recentRelayFailures: []` — the proxy
does not consider the refusal an error. The GitHub MCP server, the agent's other route to the
API, exposes `create_branch` but **no** delete-branch tool, so there is no fallback path.

`work-20260804-225829` is on the remote now, released by nothing, and a human with a browser is
currently the only thing that can remove it.

## Why the leftover is not merely untidy

The unit it holds is already finished. `batch-20260804225826` claimed
`20260804180033-claim-scan-invents-claims-in-a-shallow-clone.md` at 22:58 — a ticket
`batch-20260804194729` had claimed at 19:47, driven, and merged as `a3b32875`. So the branch
now reserves an artifact that is **archived on `main`**, while its own tip still shows the
ticket in `todo/` because the branch was cut from an older base.

That is exactly the shape `claims_has_work` reads as "work remains". Every future tick will
offer this unit as `resumable`, each takeover will re-create a worktree, discover the ticket is
already archived on the base, and be unable to release it again — and **an untaken resumable
unit forbids `ok`**, so the terminal token is pinned to `pending` by a unit that cannot be
finished or freed. The duplicate claim itself is explained and already fixed (the shallow-clone
defect, `a3b32875`); what this ticket is about is that the loop has no way to clean up after it.

## Policies

- workaholic:operation — the affected consumer is the unattended runner, and the failure leaves
  published remote state that only a human can correct.
- workaholic:implementation / observability — `{"released": false}` is honest about the call but
  says nothing about the *composite* state it left behind (worktree gone, claim live). A caller
  cannot tell "nothing happened" from "half of it happened".

## Implementation Steps

1. Make the outcome legible: `release-claim.sh` already reports `worktree_removed` and
   `remote_branch_deleted` — ensure both are populated on the failure path and add a
   `state: released | half_released | untouched` so a caller can act on the composite rather
   than infer it from two booleans.
2. Decide and record what a `half_released` unit means to the survey. The cheap, honest option
   is to leave the claim visible and let the operator delete the branch; the alternative — a
   tombstone commit on the claim branch that `claims_scan` reads as released — is a second
   release mechanism and should not be adopted without a deliberate ruling, since the whole
   protocol rests on "unmerged branch = live claim".
3. Consider ordering: when the remote delete is refused, the worktree is already gone. If
   step 2 keeps the claim live, the teardown should arguably be *skipped* on a unit whose
   branch cannot be deleted, so a resumption has a worktree to resume into rather than
   rebuilding one each time.
4. Do **not** make the script report success on a refused delete. A claim nobody can see is
   not released, and reporting otherwise is the one failure this protocol must not have.

## Quality Gate

**Acceptance Criteria**

1. With branch deletion refused (a fixture remote that rejects deletes), `release-claim.sh`
   reports the composite state explicitly and never reports `released: true`.
2. The worktree/branch outcome it reports matches the filesystem and the remote exactly.
3. A unit left half-released is distinguishable from an untouched one in the script's output.
4. The behaviour on a remote that permits deletion is unchanged.

**Verification Method**

- Extend `scripts/test-workflow-scripts.mjs` with a hermetic fixture whose "remote" refuses
  branch deletion (a bare repo with `receive.denyDeletes=true`), and assert on the JSON.
- `node scripts/test-workflow-scripts.mjs` passes.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `drive` is in
  the `outputs/workflows` closure, so the bundle must be rebuilt in the same commit.

**Gate**

All four criteria hold and the smoke suite passes.

## Considerations

- `receive.denyDeletes=true` on a bare repo reproduces this locally without any network, which
  is what makes it testable at all — the production condition is a proxy the suite cannot reach.
- **Operator action needed once, independent of this ticket:** delete
  `work-20260804-225829` on the remote. Nothing in the loop can do it, and until it is gone the
  hourly runner cannot report `ok`.
- Found by the hourly unattended runner while releasing a duplicate claim it had resumed and
  found already finished on the base.
