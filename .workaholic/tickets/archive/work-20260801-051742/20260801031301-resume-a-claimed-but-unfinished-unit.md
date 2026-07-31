---
created_at: 2026-08-01T03:13:01+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 4h
commit_hash:
category: Changed
depends_on: [20260801031300-survey-never-reports-a-silently-empty-backlog.md]
mission:
merge_policy: auto
claim: work-20260801-051742
---

# A claimed unit that is never finished cannot be resumed by anyone, though the design record says it can

## Overview

The design record states that in-flight state lives on the claim branch and that
"the next tick **re-claims and resumes** from what is pushed"
(`docs/loop-engineering-workflow.md` I5, echoed in `skills/mission/SKILL.md` and
`CLAUDE.md`). The implementation does the opposite, measured 2026-08-01:

- `plan-units.sh` drops every claimed unit as `excluded: claimed`;
- `claim.sh` refuses the same unit with `already_claimed`.

So **no survey ever offers it again** — not the same runner on its next tick, not
another runner, not a developer typing `/drive` locally. Past
`WORKAHOLIC_CLAIM_STALE_HOURS` the claim is only *reported* `stale: true`, and
nothing acts on that by design. Recovery today is a person doing
`git fetch && git checkout <branch>` by hand, or `release-claim.sh`, which is not
recovery at all — it deletes the remote branch.

The gap is survivable for a local runner whose `.worktrees/<unit>` is still on
disk. It is **not** survivable for an unattended cloud runner: there the worktree
lives only inside the sandbox, so when the session ends the pushed branch is the
sole surviving copy of the work and nothing routes anybody to it.

**The governing principle, stated by the developer (2026-08-01):** a *pushed
claim is the loop's work*. Merging to `main` means the runner implemented it;
work you intend to keep in your own hands should never have been pushed as a
claim in the first place. That is what makes same-identity resumption safe rather
than reckless — it does not license taking over a colleague's claim, and it does
not license interrupting a run that is **actively working**.

## Policies

- `workaholic:development` / `policies/parallel-long-running-agents.md` — several runners coordinate through the repository; a resumption path must not create the double-drive the claim protocol exists to prevent.
- `workaholic:development` / `policies/overnight-ai.md` — an unattended window's value depends on the work surviving the window; work that only exists inside a dead sandbox was never delivered.
- `workaholic:implementation` / `policies/observability.md` — a unit that silently leaves every future survey is a state no operator can see; resumability must be readable from the same JSON the survey already emits.
- `workaholic:implementation` / `policies/command-scripts.md` — the scan lives in `lib/claims.sh` and all three consumers read it; a resumption rule added to only one of them would let the reader and the writer disagree.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — layout and POSIX `#!/bin/sh -eu` house style for the touched scripts.

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` - excludes claimed units; must learn to offer resumable ones
- `plugins/workaholic/skills/drive/scripts/claim.sh` - refuses `already_claimed`; must gain a takeover path that is itself published
- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` - the single scan both the reader and the writer use; the resumability verdict belongs here
- `plugins/workaholic/skills/drive/scripts/list-claims.sh` - renders the scan; its JSON is where an operator reads the new state
- `plugins/workaholic/skills/drive/scripts/release-claim.sh` - the deliberate-discard path, unchanged, but the docs must stop implying it is recovery
- `plugins/workaholic/skills/branching/scripts/create-mission-worktree.sh` - a resumed unit needs its worktree re-created from the pushed branch, not from the base
- `docs/loop-engineering-workflow.md` - decision I5, the record this ticket makes true
- `plugins/workaholic/skills/drive/SKILL.md` - *Claims* section, the stated model
- `docs/drive-loop-runbook.md` - *Failure modes*, the stale-claim row

## Implementation Steps

1. Extend the shared scan (`lib/claims.sh`) so each claim row carries what a resumption decision needs: the claim commit's **author identity**, the branch tip time already present, and a derived `resumable` verdict with its reason. One scan, one verdict — the surveyor and the writer must never compute it separately.
2. Decide liveness **without a lock file and without a server** (the protocol forbids both). Recommended design: the driving run refreshes a lightweight heartbeat on its own claim branch at a bounded interval, and a unit is resumable only when that heartbeat is older than a short threshold (minutes — `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES`, defaulting well under an hour so an hourly routine recovers within one tick). The existing 24-hour `stale` remains what it is: a *report*, not the resumption trigger.
3. Scope resumption to the **same identity**: a claim whose author is the current `git config user.email` may be resumed; another developer's claim is never offered and never taken. Record in the SKILL why — a pushed claim is loop work, but only *your* loop's work.
4. Teach `plan-units.sh` to offer resumable units as a distinct group (e.g. `resumable[]`, separate from `missions[]`/`backlog[]`), and to keep excluding the rest as `claimed`. A unit that is claimed and **not** resumable keeps its current `excluded` entry with a reason that now distinguishes `claimed_active` from `claimed_by_other`.
5. Give `claim.sh` a takeover path (`claim.sh resume <unit-id>`) that publishes the takeover as a commit on the same branch, so two runners racing to resume resolve in git exactly as `branch_collision` already resolves a fresh claim — the loser retries next tick, and nothing is decided by a clock read locally.
6. Re-create the worktree from the **pushed branch tip**, not from `origin/main`, so the resumed run continues from the work that survives rather than restarting it.
7. Make `/drive` drive a resumed unit through the ordinary Unified Run: its remaining tickets are whatever is still in `todo/` on that branch, and `/report`'s `create-or-update.sh` already updates the existing PR rather than opening a second one.
8. Reconcile the documents in the same commit: `docs/loop-engineering-workflow.md` I5, `skills/drive/SKILL.md` *Claims*, `skills/mission/SKILL.md`, `CLAUDE.md`'s claim-protocol section, and the `docs/drive-loop-runbook.md` stale-claim row must all describe the mechanism that now exists.
9. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`).

## Quality Gate

**Acceptance criteria**

- A claim whose heartbeat is fresh is **never** offered as resumable, and `claim.sh resume` on it refuses with a reason naming the active run. Concurrent local and cloud runs on one unit is the failure this must make impossible.
- A claim whose heartbeat is stale **and** whose author is the current identity is offered by `plan-units.sh` and can be taken by `claim.sh resume`, which publishes the takeover.
- A claim authored by a different identity is never offered and never taken, at any age.
- A resumed unit's worktree is created at the **pushed branch tip** — the resumed run sees the earlier run's commits, and its tickets already archived on that branch are not re-driven.
- `list-claims.sh` reports the resumability verdict and its reason, so the state is readable without running a survey.
- Two runners racing to resume the same unit end with exactly one takeover; the loser reports a retryable reason and claims nothing.
- `release-claim.sh` behavior is unchanged, and no document any longer describes it as the recovery path for an interrupted unit.
- `docs/loop-engineering-workflow.md` I5, `drive/SKILL.md`, `mission/SKILL.md`, `CLAUDE.md`, and `docs/drive-loop-runbook.md` describe the implemented mechanism, in the same commit.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic cases per acceptance bullet: fresh-heartbeat refusal, stale-heartbeat takeover, foreign-identity refusal, worktree-at-branch-tip, and the two-runner race (simulated by two takeover attempts against one throwaway remote).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — `outputs/` regenerated with no residual diff.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate**

- The suite is green, the build is clean, and the *fresh-heartbeat refusal* case is present and passing — that assertion is the one this ticket exists for; without it the change trades a recoverable stall for a concurrent-write corruption.

Decided: hermetic suite only — the claim protocol's whole surface is git operations against throwaway repositories, which the existing suite already exercises; a live cloud run would add latency, not evidence (developer may override at /drive).

Decided: same-identity scope rather than any-identity — it preserves the doctrine's real concern (never silently duplicate a colleague's in-flight work) while making the unattended runner able to recover its own dropped work, which is the stated need (developer may override at /drive).

Decided: a heartbeat threshold in minutes rather than reusing the 24-hour `stale` window — an hourly routine that recovers its own dropped unit only after a day is not a recovery path; `stale` keeps its separate, reported-never-acted-on meaning (developer may override at /drive).

## Considerations

- The heartbeat writes to the claim branch, so it must be cheap and must not pollute the branch's story: prefer a ref or a trailer-only commit shape over a file the PR diff would show (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).
- Same-identity scoping means a runner impersonating the developer's email inherits the developer's claims. That is the intended reading of "the runner is a@qmu.jp", but it is worth stating in the SKILL so nobody configures a shared identity by accident (`plugins/workaholic/skills/drive/SKILL.md`).
- `archive.sh` renames a driven ticket and the reader already follows the rename to report a base-side path; a resumed unit exercises that path harder than any current flow, so the existing rename assertions must stay green (`plugins/workaholic/skills/drive/scripts/archive.sh`).
- This ticket changes what `ok` can mean: a resumable unit left unclaimed is claimable work outstanding, so it must land on the `pending` side of the terminal-token table (`plugins/workaholic/skills/drive/SKILL.md` §7).
- Depends on the survey contract change in `20260801031300-survey-never-reports-a-silently-empty-backlog.md`; both edit `plan-units.sh`'s emitted object.

## Final Report

Development completed as planned. Every acceptance bullet has a hermetic case, including
the fresh-heartbeat refusal the Gate singles out.

### Discovered Insights

- **Insight**: A tab is an **IFS whitespace character**, so `read` with `IFS=<tab>`
  collapses a run of tabs into one delimiter. Adding `resume_reason` as an empty
  middle field therefore made the field vanish and shifted every later field left:
  `plan-units.sh` received the artifact list in the reason slot and an *empty*
  artifact list — which would have let the survey offer tickets a claim already held,
  the exact double-pick the protocol exists to prevent. It was caught only because a
  new assertion checked `resumable[].artifacts`, not because anything failed loudly.
  The fix is a rule, now stated in `lib/claims.sh`: **no field of the row may be empty
  except the last**, and the variable-length artifact list is last precisely because a
  trailing empty field is the one case `read` handles correctly.
  **Context**: Any future field added to this TSV faces the same trap, and it is
  silent — the row still parses, just wrongly.

- **Insight**: Re-fetching leaves a takeover race half-open. The worktree creator
  fetches the claim branch, so a runner that lost by a second would check out the
  *winner's* new tip and its takeover would push as a clean fast-forward — two runners
  driving one unit, each believing it won. The push rejection alone does not cover it.
  The close is to pin the tip the resumability decision was made on and compare it to
  the created HEAD; a mismatch is `resume_race_lost`.
  **Context**: The general shape — "decide on state A, then act on state B because
  something re-read in between" — applies to any check-then-act across a fetch.

- **Insight**: The heartbeat needed no new artifact at all. Making the **branch tip
  itself** the liveness signal satisfies every constraint the protocol imposes (no lock
  file, no server, nothing that leaks when a runner dies) because the signal rides the
  one artifact a merge or a release already cleans up — and an empty commit changes no
  file, so it never reaches the PR diff. It also makes ordinary work commits refresh
  liveness for free, which is the correct semantics: a run that is committing is alive.
  **Context**: The alternatives considered were a custom ref namespace (not fetched by
  the default refspec) and a separate heartbeat branch (new cleanup obligation, i.e. a
  new leak). Both were worse for reasons that are properties of git, not of taste.

- **Insight**: `commit.sh --allow-empty` was added rather than calling `git commit`
  directly, so the takeover and heartbeat markers still pass the subject gate and carry
  the trailers. It is deliberately opt-in: without the flag "nothing staged" stays the
  warning it always was, so an ordinary commit whose staging silently failed can never
  masquerade as a successful empty one.
  **Context**: This is the first non-file-changing commit the plugin writes, and the
  two callers of it are both coordination markers.
