---
created_at: 2026-07-30T19:08:56+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain, Infrastructure]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260730-193046
---

# merge-pr.sh fails inside a claim worktree after the merge has landed, and extract-deferred-concerns.sh then pushes the concerns to a dead branch

## Overview

`/drive` §6 ships an `auto` unit **from that unit's claim worktree**. `merge-pr.sh` cannot run there, and the way it fails is worse than the failure itself.

Its last line is `git checkout main` ([merge-pr.sh](plugins/workaholic/skills/ship/scripts/merge-pr.sh) L20), which git refuses inside a linked worktree whenever `main` is checked out in the primary tree — always, in this repository's layout:

```
fatal: 'main' is already used by worktree at '/home/ec2-user/projects/workaholic'
```

That line runs **after** `gh pr merge` has already succeeded. So the script exits non-zero on a ship that merged, printing only the checkout error and no JSON — the caller cannot tell "the merge failed" from "the merge succeeded and the bookkeeping did not". Observed shipping PR #108 on 2026-07-30: the merge landed as `39b52709` while the script reported failure.

The consequence compounds two steps later. `extract-deferred-concerns.sh` commits the story's section-6 concerns and pushes; its header says *"so you normally end on `main` level with `origin/main`"* — an assumption that `merge-pr.sh`'s checkout succeeded. With the checkout skipped, the run is still on the claim branch, so the four concerns were committed and pushed **to the already-merged branch**, and the script truthfully reported `pushed: true`. The **open concern set is computed from records on `main`**, so all four were invisible to `/report`'s judge and `/propose` until they were republished by hand.

Both are one causal chain, and the chain is on `/drive`'s unattended `auto` path — where nobody is watching the exit code.

## Policies

- `workaholic:implementation` / [observability.md](plugins/workaholic/skills/implementation/policies/observability.md) — the governing policy, twice over. A script that exits non-zero after succeeding at its primary job reports the opposite of what happened; and `pushed: true` naming no destination is a success signal that cannot be acted on. Both are the masked-failure shape this policy forbids.
- `workaholic:implementation` / [operational-planning.md](plugins/workaholic/skills/implementation/policies/operational-planning.md) — work the recovery backward from the concrete scenarios: shipping from a claim worktree (the `/drive` default), from the primary tree, and from a worktree whose branch was deleted under it.
- `workaholic:implementation` / [command-scripts.md](plugins/workaholic/skills/implementation/policies/command-scripts.md) — the merge seam is consolidated into one script so `/ship`, `/drive`, and a human all merge identically; that contract is void if the script only works in one of the two sanctioned locations.
- `workaholic:operation` / [ci-cd.md](plugins/workaholic/skills/operation/policies/ci-cd.md) — the interactive and unattended paths must be the same code path. Today the unattended one is the broken one.
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu` per [rules/shell.md](plugins/workaholic/rules/shell.md).

## Key Files

- [ship/scripts/merge-pr.sh](plugins/workaholic/skills/ship/scripts/merge-pr.sh) — the `git checkout main` at L20 and the exit-code semantics around `gh pr merge` at L15.
- [ship/scripts/extract-deferred-concerns.sh](plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh) — commits and pushes on whatever branch it finds; its header states the end-on-main assumption. Its `pushed` field needs a destination.
- [ship/SKILL.md](plugins/workaholic/skills/ship/SKILL.md) — Ship Flow steps 6 and 8. Step 8 already warns that a silent no-op here is indistinguishable from success (it happened on PR #86); this is the same defect in a new spelling — a successful push to the wrong branch.
- [drive/SKILL.md](plugins/workaholic/skills/drive/SKILL.md) — §6 routes an `auto` unit through ship *from the claim worktree*, which is the configuration that breaks.
- [branching/scripts/cleanup-mission-worktree.sh](plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh) — the teardown that follows; it must still run from the primary tree, so wherever the post-merge checkout lands is load-bearing for it too.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — no test exercises `merge-pr.sh` (it calls `gh`), which is why this shipped. The fixable part is the checkout behaviour, which needs no network.

## Related History

- [20260728221803-unify-drive-executor.md](.workaholic/tickets/archive/work-20260728-221717/20260728221803-unify-drive-executor.md) - Made `/drive` route `auto` units through `/ship` from the claim worktree, creating the configuration this defect lives in
- [20260729183609-drive-surveys-current-main.md](.workaholic/tickets/archive/work-20260730-171125/20260729183609-drive-surveys-current-main.md) - Established that a checkout's currency must be reported rather than assumed; the same lesson applies to "which branch am I on" after a merge
- [20260730180248-claim-reader-loses-artifacts-on-archive.md](.workaholic/tickets/todo/a-qmu-jp/20260730180248-claim-reader-loses-artifacts-on-archive.md) - The other in-flight defect found by driving this repository with its own loop; both are cases where a script's output was true and its meaning was wrong

## Implementation Steps

1. **Separate the merge's outcome from the bookkeeping's.** `merge-pr.sh` must emit its `{merged, pr_number, commit_hash}` JSON and exit 0 whenever `gh pr merge` succeeded, regardless of what happens afterwards. A post-merge step that fails is reported as a field (e.g. `checked_out: false` with a reason), never as the script's exit status: the merge is irreversible and the caller's most important question is whether it happened.

2. **Make the post-merge checkout work in both sanctioned locations, or stop doing it.** Three candidates — pick one and record why:
   - **Skip it when `main` is checked out elsewhere** (`git worktree list` already answers this) and report `checked_out: false, reason: "main_checked_out_elsewhere"`.
   - **Move the checkout out of the script** into the ship flow, which knows whether it is in a claim worktree.
   - **Drop it entirely** and let each caller decide, since `/drive` tears the worktree down straight afterwards anyway.

3. **Give `extract-deferred-concerns.sh` an explicit destination.** It must not infer "I am on `main`" from context. Either take the target branch as an argument and refuse to push anywhere else, or publish through the publish tree (`branching/scripts/publish-tree-commit.sh`) so the records reach `main` from any checkout — which is what the by-hand recovery did. Its JSON must name the branch it pushed to, so `pushed: true` becomes actionable.

4. **Report the destination in the ship summary.** Step 9 currently reports the extraction count and `pushed`; it must also report *where*, because the open-concern set is only correct if the records are on the base.

5. **Recover the strays if any remain.** The four concerns from PR #108 were republished by hand (commit `f4c6f15d`); check for others left on merged branches before this lands, and say plainly whether any were found.

6. **Cover the checkout behaviour without `gh`.** The merge itself needs the network, but "does this script leave a usable checkout, and does it report honestly, when `main` is held by another worktree" does not. Extract the post-merge step so it is callable and testable on its own, and pin: from a linked worktree it does not fail the script; from the primary tree it behaves as today.

## Quality Gate

**Acceptance criteria**

- `merge-pr.sh` run from a **claim worktree** on a repository whose primary tree holds `main` exits **0** and emits `{merged: true, ...}` when the merge succeeded. This is the criterion the ticket exists for.
- The same run reports the bookkeeping outcome as a **field**, naming why the checkout did not happen; the field is present in both the success and the skipped case.
- `merge-pr.sh` run from the **primary tree** behaves exactly as today (merge, then land on `main`), asserted so the fix is not a regression for the interactive path.
- A genuinely failed `gh pr merge` still exits non-zero with `{merged: false, ...}` — the fix must not turn a real merge failure into a success.
- `extract-deferred-concerns.sh` writes its records to the **base branch** regardless of the checkout it runs in, and its JSON names the destination branch. Running it from a claim worktree puts the concerns on `main`, not on the claim branch.
- `list-open-concerns.sh`, run from a fresh clone after a ship, sees every concern the shipped story's section 6 contained — the end-to-end property that was silently false.
- The ship summary (SKILL.md step 9) states the extraction destination alongside the count.
- No stray concern records remain on merged branches; if any were found, they are on `main` and the recovery is named in the Final Report.
- Every changed script is POSIX `#!/bin/sh -eu` and `hooks/posix-lint.sh` reports `conforming: true`.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, extended per implementation step 6: the post-merge step called from a linked worktree (does not fail, reports the skip) and from the primary tree (checks `main` out), plus an `extract-deferred-concerns.sh` case run from a worktree asserting the records land on the base branch and the JSON names it. No test may call `gh`.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` clean with no residual `outputs/` diff (`ship` ships in `outputs/workflows`).
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming.
- A live rehearsal on the **next** `auto` unit, or a supervised `/ship` from a claim worktree: confirm the JSON is emitted, the exit status is 0, and the concerns land on `main`.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The claim-worktree case is covered by a **named** test. This defect shipped precisely because no test exercises the script's non-network half.
- The step-2 ruling on the post-merge checkout is recorded in `ship/SKILL.md`, not only in code.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` the merge's exit status reflects **only the merge**. Anything after an irreversible action is reported, never allowed to mask it — this is the same principle as `plan-units.sh` reporting `current` instead of repairing it.
- `Decided:` `extract-deferred-concerns.sh` gets an **explicit destination** rather than a smarter guess. It currently infers its branch from context and was right only by accident; a script that pushes knowledge somewhere must name where.
- `Decided:` this is a **bugfix ahead of feature work on the ship path**. It is live on `/drive`'s unattended `auto` route, where the exit code nobody reads is the only signal, and it silently drops the concern records the whole feedback stream depends on.

## Considerations

- **The interactive path hides it.** Shipping from the primary tree works perfectly, which is why two PRs shipped today before it surfaced — the second was shipped from the primary tree deliberately, as a workaround. Every `auto` unit `/drive` ever ships takes the broken path.
- **`pushed: true` was not a lie, and that is the lesson.** The push succeeded; the destination was wrong. A boolean that answers "did the network call work" reads as "did the knowledge arrive". Naming the destination is cheaper than making the caller infer it.
- **The teardown depends on where the checkout lands.** `cleanup-mission-worktree.sh` must run from the primary tree (git cannot remove the worktree you are standing in), so whichever option step 2 picks, `/drive` §6's teardown still needs a defined cwd afterwards — state it wherever the ruling is recorded.
- **Consider whether `commit-release-note.sh` shares the assumption.** It pushes to the current branch, which is correct pre-merge (the note must ride into the merge). Confirm it is genuinely pre-merge in every path before leaving it alone.

## Final Report

Development completed as planned. `merge-pr.sh` now separates the merge's outcome from the
bookkeeping's: it emits its JSON and exits 0 whenever `gh pr merge` succeeded, reporting
the post-merge base checkout as `checked_out` plus a `checkout_reason`
(`base_checked_out_elsewhere` / `checkout_failed` / `pull_failed`), and it skips the
checkout outright when another worktree holds the base — the normal `/drive` layout, not
an error. `extract-deferred-concerns.sh` takes the base explicitly, reports the
`destination` it pushed to, and when it is not already on the base it extracts and
publishes **through a publish tree**, which also makes its dedup scan read the base's
records rather than the branch's. The step-2 ruling (the checkout stays best-effort and is
never load-bearing) is recorded in `ship/SKILL.md` step 6, and step 8 now says to pass the
base and read `destination`.

Verification: suite green at **1505 passed / 0 failed** with two new cases. The
coverage gap the ticket named is closed without touching `gh`:
`testShipWorksFromAClaimWorktree` builds a real linked worktree with the primary tree
holding `main`, proves a bare checkout of the base genuinely fails there (the original
defect), then runs the extraction from that worktree and asserts the record lands on
`origin/main`, is **absent** from the claim branch, leaves the claim worktree clean, tears
the publish tree down, and is idempotent on a second run.
`testShipExtractionOnBaseIsDirect` pins that the on-base path stays direct with no publish
tree involved. `posix-lint` conforming; `build.mjs` / `verify.mjs` /
`validate-metadata.mjs` clean; `layout-doctor` conforming.

Step 5 (recover the strays): a scan of every `Add deferred concerns from PR #…` commit in
the repository found **no remaining strays** — all 21 are reachable from `origin/main`.
PR #108's four records reached main through the by-hand recovery commit `f4c6f15d` before
this work began, which is why its extraction commit is not among them.

### Discovered Insights

- **Insight**: The publish tree turned out to be the right answer for a reason the ticket
  did not anticipate. Its step 3 offered "take the target branch as an argument and refuse
  to push anywhere else" as the simpler option — but that cannot work here: after the
  merge, `origin/main` contains a merge commit that is *not* an ancestor of the claim
  branch's HEAD, so `git push origin HEAD:main` is correctly rejected non-fast-forward.
  The only way to write to the base from a merged branch's checkout is a checkout **of the
  base**, which is precisely what a publish tree is.
  **Context**: The two options were not equivalent-but-different; one was impossible. Worth
  knowing before the next script needs to write to the base from elsewhere.

- **Insight**: Routing by re-entering the same script inside the publish tree (guarded by
  one env var) avoided restructuring the extractor at all — the Python half already uses
  paths relative to cwd, so running it *in* the publish tree makes both its dedup scan and
  its writes land there for free. The only thing that had to cross the boundary was the
  story's absolute path.
  **Context**: When a script is already cwd-relative, changing *where it runs* is cheaper
  and less risky than teaching it about a second root.

- **Insight**: The re-entry initially skipped silently, and the cause was ordering, not
  logic: the pre-existing `if [ ! -f "$story_file" ]` check sat *above* the point where the
  re-entered run learns the story's real location, so it looked for the story inside the
  publish tree and reported `no_story_file`. The fix was to resolve the override
  immediately after `story_file` is assigned.
  **Context**: When adding a parameter that changes what an early guard tests, the
  parameter has to be resolved before that guard — not merely before its first use.

- **Insight**: One test assertion was wrong rather than the code: the concern's filename
  slug truncates, so matching the full title (`…-reach-the-base`) failed against the real
  `…-reach-the`. It looked exactly like the destination bug it was written to catch, which
  is the hazard — an assertion that fails for a cosmetic reason in the same place a real
  defect would.
  **Context**: Match a stable prefix, not a full generated name, when the generator is
  allowed to truncate.
