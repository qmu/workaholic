# Stranded claim recovery

`archive.sh` marks implementation complete and records pre-archive head/base,
committed-tree assessment and dirty paths. It explicitly leaves delivery unverified;
ordinary unmerged implementation still archives. `status: done` does not prove landing.

A `stranded` claim is a candidate, not proof of unique code. The existing retirement
oracle and all deletion gates remain unchanged. `assess-claim-residue.sh` synthesizes
a three-way merge without modifying any ref/worktree, then compares its product paths
with the base. `landed` means no remaining product effects, `pending` means effects need
review, and `unknown` means no conclusion (including content conflict). All are observations,
never new retirement permission. Bookkeeping under `.workaholic` is excluded from replay.

Implement can take one such offer without a Slack response:

1. Read `list-claims.sh`; choose this identity's `stranded` row and observe its remote head.
2. Run `recover-stranded-claim.sh <unit> <branch> <head>`. It rechecks the oracle and remote
   head, claims `refs/claims/recovery-<hash(branch,head)>` with an absent-ref lease, creates
   a separate worktree and stages only the clean residual effects on the observed base.
3. Inspect effects against the source tickets, test, then commit through `commit.sh`.
   Write a review file outside the worktree naming tickets, disposition and actual tests.
4. Run `publish-stranded-recovery.sh <key> <review-file>` in that tree. It verifies the
   immutable claim trailers and ancestry, requires an existing PR to remain open and draft,
   runs the canonical safety scan/gate against the pinned base, pushes only the scanned
   head to the recovery branch, and creates
   a draft PR with exact source/base SHAs, or returns the existing review. No automatic
   merge, discard, source-branch update, release or deletion follows.

`recovery_already_claimed` names the coordination ref. Fetch it and read the
`Recovery-Branch` trailer to find its existing worktree or draft. After the heartbeat stale interval, the same identity
may call `recover-stranded-claim.sh --resume <unit> <branch> <head>`. A compare-and-swap
takeover records a new coordination commit and reconstructs the pinned base/source
effects in another clone when publication never happened. Active or foreign recoveries
and dirty existing worktrees are refused; dirty work is preserved for inspection. A changed source head has a distinct key. A publication
failure leaves the prepared tree and claim intact and publication is safely retryable.
An `assessment_unanswerable` records the conflict/unreadable evidence and claims nothing;
resolve it in a new review worktree, preserving the original refs. Do not call it lost work.
A holder question may supply intent but is not the sole recovery mechanism.
