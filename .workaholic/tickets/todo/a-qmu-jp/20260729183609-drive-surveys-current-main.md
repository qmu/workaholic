---
created_at: 2026-07-29T18:36:09+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain, Infrastructure]
effort:
commit_hash:
category:
depends_on: [20260729183607-ticket-publishes-to-main.md, 20260729183608-mission-publishes-to-main.md]
mission:
merge_policy: review
claim: work-20260730-171125
---

# /drive surveys a current main, and claim.sh drops its stranded-artifact workarounds

## Overview

Once `/ticket` and `/mission` publish to `main`, the executor becomes the only consumer that matters — and it currently reads the wrong thing. [plan-units.sh](plugins/workaholic/skills/drive/scripts/plan-units.sh) splits its sources: **claims** come from git refs through the shared reader (`lib/claims.sh` fetches and scans unmerged `origin/*` branches), but **artifacts** come from the local working tree — `find .workaholic/missions/active` (~L124-125) and `list-todo.sh` (~L162), both cwd-relative. Nothing in `/drive` or `claim.sh` ever fast-forwards the local checkout: `claims_fetch` updates remote-tracking refs only.

So publishing to `main` is necessary but not sufficient. A runner whose `main` is behind `origin/main` will simply not see a mission or ticket that another session pushed a minute ago — and it will not report why, because `plan-units.sh`'s `excluded[]` reasons (`not_approved`, `claimed`, `no_plan`, `mission_member`) have no entry for "your checkout is stale". A 5-minute cron tick that silently surveys yesterday's queue is the worst shape this bug can take: it looks healthy and does nothing.

This ticket closes that gap and then removes the workarounds the old model required. [claim.sh](plugins/workaholic/skills/drive/scripts/claim.sh) tolerates a mission with no `mission.md` in the main tree (~L80-82) and re-resolves the mission inside the worktree afterwards (~L157-162) — both exist purely because a mission could live on an unmerged branch. With missions on `main`, absence becomes a real error worth reporting rather than a normal case worth swallowing.

## Policies

- `workaholic:implementation` / [observability.md](plugins/workaholic/skills/implementation/policies/observability.md) — the governing policy. `plan-units.sh`'s per-drop reason, `list-claims.sh`'s JSON, and `/drive`'s `N units: X shipped, Y PR'd, Z blocked` reconciliation *are* this repository's observation surface. A ticket that exists but is invisible must appear in that output with a reason, never be silently absent.
- `workaholic:implementation` / [operational-planning.md](plugins/workaholic/skills/implementation/policies/operational-planning.md) — recovery is worked backward from concrete scenarios: a stale checkout, an offline runner, a diverged local `main`, two runners ticking simultaneously against the same fresh artifact.
- `workaholic:implementation` / [infrastructure-as-code.md](plugins/workaholic/skills/implementation/policies/infrastructure-as-code.md) — coordination state stays derivable from git refs; the survey must not depend on when a runner last happened to pull.
- `workaholic:implementation` / [domain-layer-separation.md](plugins/workaholic/skills/implementation/policies/domain-layer-separation.md) — one scan serves reader and writer (`lib/claims.sh`); the freshness step must not become a second, divergent implementation of "what does main say".
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu`; the freshness logic is a script, never inline conditionals in `commands/drive.md`.
- `workaholic:operation` / [ci-cd.md](plugins/workaholic/skills/operation/policies/ci-cd.md) — the cron path and a developer's interactive `/drive` must remain the identical code path; a freshness step that only the cron entry runs would break that.
- `workaholic:planning` / [ai-native-future.md](plugins/workaholic/skills/planning/policies/ai-native-future.md) — the unattended loop stays observable and interruptible: the honest terminal token (`ok` only when nothing claimable remains undone) must account for anything the survey could not see.
- `workaholic:implementation` / [objective-documentation.md](plugins/workaholic/skills/implementation/policies/objective-documentation.md) — the runbook's documented failure mode is being fixed, so the runbook entry is rewritten in this change rather than left describing a resolved symptom.

## Key Files

- [drive/scripts/plan-units.sh](plugins/workaholic/skills/drive/scripts/plan-units.sh) — the survey; the local-tree artifact reads at ~L124-125 and ~L162, and the `excluded[]` emission at ~L110-115 and ~L130/134/143/166/170.
- [commands/drive.md](plugins/workaholic/commands/drive.md) — where the freshness step is orchestrated, before the survey.
- [branching/scripts/sync-main.sh](plugins/workaholic/skills/branching/scripts/sync-main.sh) — built by the foundation ticket; reused here rather than reimplemented.
- [drive/scripts/claim.sh](plugins/workaholic/skills/drive/scripts/claim.sh) — the main-tree tolerance comment and branch (~L76-86) and the in-worktree re-resolution (~L157-162).
- [drive/scripts/lib/claims.sh](plugins/workaholic/skills/drive/scripts/lib/claims.sh) — `claims_fetch` (~L45-55) updates refs only; the boundary between "refs are current" and "the working tree is current" lives here and must stay explicit.
- [drive/scripts/list-todo.sh](plugins/workaholic/skills/drive/scripts/list-todo.sh) — cwd-relative queue reader; it reports whatever checkout it runs in, which is correct and stays so.
- [drive/SKILL.md](plugins/workaholic/skills/drive/SKILL.md) — the Unified Run survey section (~L39-59) and the Claims section (~L262-302), including the "the runner's main checkout stays clean between ticks" invariant (~L292-294) that this change must preserve.
- [drive-loop-runbook.md](docs/drive-loop-runbook.md) — §6's "approved missions exist but nothing is claimed" entry, whose stated cause this change eliminates.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — `makeClaimFixture` (~L7187) clones both runners fresh from origin, so a stale checkout is impossible by construction and the survey's local read has never been distinguished from an `origin/main` read. That is the coverage gap this ticket closes.

## Related History

- [20260728221803-unify-drive-executor.md](.workaholic/tickets/archive/work-20260728-221717/20260728221803-unify-drive-executor.md) - Built `plan-units.sh` and the Unified Run; the survey being fixed here
- [20260728221802-add-claim-protocol-scripts.md](.workaholic/tickets/archive/work-20260728-221717/20260728221802-add-claim-protocol-scripts.md) - Built `claim.sh` / `lib/claims.sh`, including the main-tree tolerance this ticket removes
- [20260728210302-add-proposal-batch-command-and-skill.md](.workaholic/tickets/archive/work-20260728-210259/20260728210302-add-proposal-batch-command-and-skill.md) - `/propose`'s fetch-and-fast-forward guard, the shape reused here

## Implementation Steps

1. **Add a freshness step to [commands/drive.md](plugins/workaholic/commands/drive.md), before the survey.** Run `branching/scripts/sync-main.sh` (built by the foundation ticket) so the runner's `main` is fast-forwarded to `origin/main` before `plan-units.sh` reads it. Same step for interactive and cron invocations — they are one code path.

2. **Decide the behaviour for each `sync-main.sh` failure, and report every one.** `/drive` issues no `AskUserQuestion`, so each outcome is a reported decision:
   - `no_origin` — survey the local tree and say so; the run's terminal token cannot be `ok` on the strength of a survey that could not see the remote.
   - `not_on_main` / `dirty_workspace` — the runner is not in a surveyable state; report it and terminate with `pending`, never silently survey a branch.
   - `diverged` — a human decision; report and terminate with `pending`. Never merge or reset.
   In all cases the reason is visible in the run's output, because an unattended tick that reports nothing is indistinguishable from one that had nothing to do.

3. **Keep `plan-units.sh` a pure reader.** The freshness step belongs to the command, not the survey: a script named "plan units" that mutates the checkout is a surprise, and `plan-units.sh` is called in contexts where reading must be side-effect-free. If the survey needs to *state* its freshness, add a reported field (e.g. the base SHA it surveyed) rather than a fetch.

4. **Make the survey account for what it could not see.** Whatever `plan-units.sh` reports must let `/drive` reconcile honestly: the terminal `ok` means "nothing claimable remains undone", and it may only be emitted when the survey ran against a checkout known current with `origin/main`.

5. **Remove `claim.sh`'s stranded-artifact tolerance** (~L76-86). A mission with no `mission.md` in the main tree is no longer normal — it is an error. Report it as a distinct, named failure reason instead of proceeding. Re-examine the in-worktree re-resolution (~L157-162): the stamp still belongs to the worktree checkout, so the re-resolution may still be required for correctness — **verify before deleting**, and if it stays, replace its comment with the real reason rather than the stranded-artifact one.

6. **Rewrite [drive-loop-runbook.md](docs/drive-loop-runbook.md) §6.** The "approved missions exist but nothing is claimed / its tickets live in an unmerged worktree" entry describes a cause that no longer exists. Replace it with the causes that now can occur: a stale or diverged runner checkout, a claim in flight, a mission not yet approved.

7. **Close the test-fixture gap.** `makeClaimFixture` clones both runners fresh, so no test can currently fail on a stale checkout. Add a fixture that seeds an artifact on `origin/main`, leaves clone A deliberately behind, and asserts the survey either sees it after the freshness step or reports precisely why it did not.

8. **Update the docs in this same change**: [drive/SKILL.md](plugins/workaholic/skills/drive/SKILL.md)'s survey and Claims sections, the `/drive` row in [CLAUDE.md](CLAUDE.md)'s command table and its claim-protocol prose, and [README.md](README.md) where the loop is described.

9. **Rebuild the generated artifacts** — `drive` and `branching` ship in `outputs/workflows`; run the argument-less `node scripts/build-plugins/build.mjs` and commit the result.

## Quality Gate

**Acceptance criteria**

- A mission or ticket pushed to `origin/main` by one clone is surveyed as claimable by a second clone whose local `main` was behind, in a single `/drive` invocation with no manual `git pull`. This is the criterion the ticket exists for.
- The freshness step runs on the interactive and the cron path identically — there is one code path, verifiable by inspection of `commands/drive.md`.
- Each `sync-main.sh` failure (`no_origin`, `not_on_main`, `dirty_workspace`, `diverged`) produces a distinct, visible reason in the run output, and none of them terminates with `ok`.
- `/drive` still issues **no** `AskUserQuestion` anywhere, including on every new failure path.
- `plan-units.sh` performs no fetch, no checkout mutation, and no push — running it twice leaves the working tree identical.
- The runner's main checkout is still clean between ticks (the invariant `drive/SKILL.md` records and `/propose` depends on): a completed `/drive` run leaves no `claim:` stamp and no artifact modification on `main`.
- A claim's `claim:` stamp is still branch-only and absent from the main tree's copy of the artifact — publishing artifacts to `main` must not have leaked claim state onto `main`.
- `claim.sh` reports a named error when a mission's `mission.md` is absent from the main tree, instead of proceeding; the stranded-artifact comment is gone.
- If the in-worktree re-resolution is retained, its comment states the actual reason (the stamp belongs to the worktree checkout), not the retired one.
- Concurrent tick: two runners surveying the same freshly published unit still result in exactly one claim, with the loser reporting `already_claimed` rather than double-picking.
- Offline: the reader still degrades (reports `fetched: false` and answers from last-known refs) and the writer still fails loudly. A false "unclaimed" is never produced.
- `drive-loop-runbook.md` §6 no longer cites a cause that cannot occur.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, extended with a stale-checkout fixture (seed on `origin/main`, hold clone A behind, assert the survey sees it after the freshness step), a diverged-local-main case, a `no_origin` case, and a concurrent-claim case over a freshly published unit.
- Existing claim-protocol assertions still pass unchanged — in particular "claiming leaves the main checkout clean" and "the claim stamp is absent from the main tree's mission.md" (~L7240-7247), which are the invariants most at risk from this change.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` clean with no residual `outputs/` diff.
- `bash plugins/workaholic/hooks/posix-lint.sh` conforming; `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- A live rehearsal against a **throwaway clone** (never this repository itself — an unattended run must not push scratch commits to its `origin/main`): publish a throwaway ticket to `origin/main`, confirm a `/drive` survey in a deliberately-behind checkout picks it up and reports the base SHA it surveyed, then release the claim.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The stale-checkout case is covered by a named test — this ticket is specifically about a failure the existing fixture design cannot express, so an untested fix does not close it.
- Both dependencies ([20260729183607](.workaholic/tickets/todo/a-qmu-jp/20260729183607-ticket-publishes-to-main.md), [20260729183608](.workaholic/tickets/todo/a-qmu-jp/20260729183608-mission-publishes-to-main.md)) are merged first — surveying a current `main` is only meaningful once artifacts are published there.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` the freshness step lives in **`commands/drive.md`, not inside `plan-units.sh`** — a survey script that mutates the checkout is a side effect callers cannot anticipate, and keeping the mutation at the orchestration layer preserves `plan-units.sh` as a pure reader.
- `Decided:` a fast-forward failure **terminates with `pending`, never merges or resets** — this matches the repository's standing stance that staleness is reported and never auto-broken, and a reset would discard a developer's local commits on `main`.
- `Decided:` `no_origin` **surveys locally but cannot report `ok`** — a single-machine repository should still be drivable, but a survey that could not consult the remote has not established that nothing claimable remains.
- `Decided:` `claim.sh`'s in-worktree re-resolution is **verified before removal, not removed on sight** — it may still be load-bearing for stamping the worktree's own copy, and deleting a correct behaviour because its comment cited a retired reason would be a regression.
- `Decided:` verification is the **hermetic suite plus one live rehearsal against a throwaway clone**, matching the sibling tickets.

## Considerations

- **The freshness step introduces the first checkout mutation into `/drive`** (`plugins/workaholic/commands/drive.md`). Everything else the run does happens in a claim worktree. Confirm the fast-forward cannot disturb a concurrent session in the same repository — notably a `/propose` tick, which requires a clean `main` and runs on its own 15-minute schedule against the same checkout.
- **`/propose` and `/drive` now both fast-forward the same `main`** (`plugins/workaholic/commands/propose.md`, `plugins/workaholic/commands/drive.md`). Two crons on 15- and 5-minute schedules against one checkout was already true, but each gains a mutation. The failure to look for is one tick fast-forwarding while the other is mid-write; both guard on a clean tree, which should be sufficient, but it deserves a stated argument rather than an assumption.
- **`list-todo.sh` stays cwd-relative and that is correct** (`plugins/workaholic/skills/drive/scripts/list-todo.sh`). It reports the checkout it runs in; the freshness step makes that checkout current. Do not make it read refs — inside a claim worktree it must report the worktree's queue.
- **The `excluded[]` vocabulary is a user-facing contract** (`plugins/workaholic/skills/drive/scripts/plan-units.sh`). Any new reason added here appears in cron output and in the runbook, so it is named once and used identically in both, per the terminology policy.
