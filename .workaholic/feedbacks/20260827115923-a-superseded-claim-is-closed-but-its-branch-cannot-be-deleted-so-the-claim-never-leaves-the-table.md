---
type: Feedback
title: A superseded claim is closed but its branch cannot be deleted, so the claim never leaves the table
kind: concern
source: development
subject: observer_ai:[Moderate] routine
created_at: 2026-08-27T11:59:23+00:00
author: a@qmu.jp
supersedes: 
---

# A superseded claim is closed but its branch cannot be deleted, so the claim never leaves the table

The retirement act shipped today closes a `superseded` claim's pull request and then
cannot delete its branch, so the claim never leaves the claim table and the step reports
`0 retired` every hour. Measured on this repository during tick `20260827-115144`.

## What was measured

`step-retire-claims.sh` reads 4 `superseded` claims and hands each to
`drive/scripts/retire-claim.sh`. Three of them answer:

```
{"retired": false, "unit": "batch-20260819063000", "branch": "work-20260819-063001",
 "pull_request": "612", "pull_request_closed": "already_closed",
 "remote_branch_deleted": "failed", "worktree_reaped": "absent",
 "reason": "partial_retirement"}
```

Act 1 succeeded on an earlier tick (`already_closed`), act 3 has nothing to do
(`absent`), and act 2 fails. Run by hand, the failure is explicit:

```
$ git push origin --delete work-20260819-063001
error: RPC failed; HTTP 403 curl 22 The requested URL returned error: 403
```

`retire-claim.sh` already anticipates this in a comment on the same branch of its own
code — *"Measured 2026-08-05 on the hourly runner: a cloud container may PUSH but not
DELETE a branch"* — and names the act `failed` rather than treating it as fatal, which
is correct as far as it goes.

## Why it matters

**The unmerged remote branch is the claim.** `list-claims.sh` scans unmerged remote
branches, so a claim whose branch survives stays in the table whatever happened to its
pull request. The retirement exists to take a proved-empty claim off the table; with act
2 structurally impossible in a routine container, it takes the pull request off and
leaves the claim exactly where it was. The measured shape over the last four ticks of
2026-08-27 is identical every hour:

```
8 claimed unit(s); 4 proved superseded, 0 retired, 4 refused —
batch-20260819063000 (partial_retirement); make-a-rename-a-registry-entry-not-a-sweep
(partial_retirement); make-the-draft-release-note-an-agent-s-release-plan
(partial_retirement); make-workaholify-converge-the-account-s-routines
(not_superseded:awaiting_verification)
```

So the claim table still only ever grows — the exact measurement the retirement was
built against — and each tick re-attempts a delete that cannot succeed. Nothing is
damaged: the acts are idempotent and every refusal is named. What is lost is the
outcome.

## What this record does not decide

Whether the branch delete should be retried through a transport a container does have
(`rules/shell.md` already carries one narrow precedent: a REST refusal named
`session_type_cannot_merge`, retried through one named MCP tool, for one act), whether
`partial_retirement` should be split so *closed but undeletable* is its own word, and
whether a claim whose pull request is closed should read something other than
`superseded` to the oracle, are three separate rulings. The measurement is that the act
as shipped completes in no routine container.

## Where it was seen

- tick `20260827-115144`, step `retire-claims`
- `.workaholic/moderations/2026-08-27.md`, four consecutive `retire-claims` lines
- `plugins/workaholic/skills/drive/scripts/retire-claim.sh` (act 2)
