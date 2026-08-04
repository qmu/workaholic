---
created_at: 2026-08-04T18:00:33+00:00
author: a@qmu.jp
type: bugfix
layer: [Infrastructure]
effort:
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: review
claim: work-20260804-194735
---

# The claim scan reports merged branches as in-flight claims in a shallow clone

## Overview

`skills/drive/scripts/lib/claims.sh` decides "is this branch still in flight" with

```sh
_cs_ahead=$(git rev-list --count "${_cs_base}..${_cs_ref}" 2>/dev/null || echo 0)
[ "$_cs_ahead" -gt 0 ] || continue
```

That test is correct only in a **complete** clone. In a shallow one the merge base is outside the
grafted history, so `base..ref` cannot be reduced and git counts the whole visible range — a branch
whose commits all reached the base still reports a large positive `ahead`. The scan then treats it
as an unmerged branch, finds the `Claim …` commit in its history, and emits a claim for a PR-unit
that was merged and shipped days ago.

`claims_fetch` runs `git fetch --prune --quiet origin`, which does **not** deepen a shallow
repository, so nothing in the read path ever repairs this. Neither `claims.sh`, `plan-units.sh`,
`list-claims.sh` nor any doc mentions shallowness at all — the scan silently assumes complete
history and reports its output with full confidence.

## Why this is not theoretical

Measured on the hourly unattended runner, 2026-08-04 18:00 UTC, in the cloud container it normally
runs in. `git rev-parse --is-shallow-repository` was `true` on the container's fresh clone before
this run fetched anything.

The first survey of the tick reported:

```json
"resumable": [{"unit": "batch-20260730180927", "branch": "claude/sharp-rubin-xiorxm",
               "author": "a@qmu.jp", "stale": true, "artifacts": []}]
```

`git rev-list --count origin/main..origin/claude/sharp-rubin-xiorxm` returned **154** while shallow.
After `git fetch --unshallow`, the same command returned **0** and `git merge-base` resolved to the
branch tip: the branch is fully merged into `main`. Re-running `plan-units.sh` on the now-complete
clone returned `"resumable": []`.

So the unit was offered for resumption solely because the clone was shallow, and it passed the
identity gate (same `a@qmu.jp`) and the heartbeat gate (last commit 2026-07-30) that are supposed
to make resumption safe.

## Consequences

Two, and both bite the unattended runner specifically:

1. **A merged unit is offered for takeover.** `/drive`'s contract treats `resumable[]` as claimable,
   so the next step is `claim.sh resume batch-20260730180927` — creating a worktree on a merged
   branch and pushing a `Resume` commit onto shipped history. This is the same class of harm the
   `queue_drained` reason was introduced to prevent, reached by a different route.
2. **The tick can never report `ok`.** `ok` requires no untaken resumable unit. A phantom that
   re-appears on every fresh container makes the honest terminal token permanently `pending`, which
   breaks the `/goal /drive ok` caller contract and trains the operator to ignore `pending`.

The exposure is wide rather than incidental: this repository has ~180 remote branches that are
merged but never deleted, and every one of them carrying a `Claim` commit inside the shallow window
is a candidate phantom. Which ones surface depends on the container's clone depth, so the symptom
is intermittent across ticks — the worst shape for diagnosis.

## Policies

- workaholic:implementation / observability — the scan reports a computed verdict (`resumable`,
  `claimed`) with no indication that the input history was truncated. A value that reads true and is
  not is exactly the silent-wrong-answer class this policy exists to prevent.
- workaholic:operation — the consumer is an unattended hourly runner whose next action on this
  output is a push to a shared remote, so the wrong answer reaches published refs rather than
  stopping at a log line.

## Implementation Steps

1. In `claims.sh`, detect truncated history once per scan:
   `git rev-parse --is-shallow-repository`.
2. Prefer **repair over degradation** in the reader: when the repository is shallow and origin is
   reachable, deepen it (`git fetch --unshallow`, or `--depth` escalation) inside `claims_fetch` so
   the merged/unmerged test is answerable. Deepening is idempotent and costs one fetch per container
   lifetime, not per scan.
3. When it is shallow and cannot be deepened (unreachable origin), **degrade loudly rather than
   inventing claims**: carry a `shallow: true` field out through `claims_scan` into
   `list-claims.sh` and `plan-units.sh`, and suppress the `resumable` verdict for any branch whose
   merge base is unreachable — an unanswerable question must not render as `heartbeat_lapsed`.
4. `plan-units.sh` must treat `shallow: true` the way it already treats `current: false`: it
   **forbids `ok`**, because a survey computed over truncated history has not established that
   nothing claimable remains.
5. Document the assumption where the scan states its model — `claims.sh`'s header currently asserts
   "the set of claims in flight is exactly the set of remote branches carrying commits not yet on
   the base" without noting that this requires complete history.
6. Update `CLAUDE.md`'s claim-protocol section and `docs/drive-loop-runbook.md` in the same commit,
   per the docs-in-the-same-change rule.

## Quality Gate

1. In a deliberately shallow clone (`git clone --depth 1`) of a fixture whose remote carries a
   merged branch with a `Claim` commit, `list-claims.sh` reports **no** claim for that branch —
   verified in `test-workflow-scripts.mjs`, which today creates only complete fixture repositories
   and therefore cannot observe this defect at all.
2. In the same fixture with origin made unreachable, the scan reports `shallow: true` and emits no
   `resumable` verdict, and `plan-units.sh` refuses `ok`.
3. `plan-units.sh` over a shallow clone of this repository returns `resumable: []` for
   `batch-20260730180927` without any manual `--unshallow`.
4. A genuinely unmerged claim is still reported as claimed and resumable in both a shallow and a
   complete clone — the fix must not buy correctness by blinding the reader.

## Considerations

- Step 2 and step 3 are deliberately different answers to the same condition. Deepening is right
  when it is possible because it restores the reader's actual question; suppression is the fallback
  when it is not. Doing only the second would leave the hourly runner permanently unable to see its
  own genuinely resumable units in a container that starts shallow.
- The test-suite gap is the reason this survived: every existing fixture is a complete clone, so no
  test exercises the one condition the production runner always starts in. The fixture change is as
  much the deliverable as the code change.
- This ticket was minted by the hourly unattended runner as an unqueued problem met mid-run, per
  `/drive`'s failure contract. The runner did not resume the phantom unit; it unshallowed its own
  checkout, re-surveyed, and confirmed nothing was claimable.
