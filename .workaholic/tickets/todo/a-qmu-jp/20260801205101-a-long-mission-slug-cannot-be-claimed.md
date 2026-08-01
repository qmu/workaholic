---
created_at: 2026-08-01T20:51:01+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: auto
claim: work-20260801-205224
---

# A mission whose slug is long cannot be claimed at all, and the refusal says nothing

## Overview

`claim.sh` publishes a claim with the commit subject `Claim <unit-id>`, and `commit.sh`
enforces the 50-character subject rule on every commit it makes. For a **mission** unit the
unit id is the slug, so any slug longer than 44 characters produces an over-long subject,
`commit.sh` refuses it, and the claim fails.

Measured 2026-08-01 on a live `/drive`. Four of the five active missions are affected —
that is, **80% of the roadmap is undrivable**:

| Subject length | Verdict | Mission |
| -------------: | ------- | ------- |
| 77 | reject | `make-scheduled-routines-a-configurable-inspectable-part-of-a-repository` |
| 67 | reject | `make-acceptance-ticking-measure-satisfaction-not-marker-shape` |
| 65 | reject | `make-the-per-commit-changed-lines-ceiling-a-rule-that-holds` |
| 64 | reject | `adopt-a-git-flow-branching-model-with-durable-ship-records` |
| 46 | pass | `make-the-branch-story-concise-by-default` |

Nothing warns at mission creation, and nothing in the refusal names the cause: the run sees
`{"claimed": false, "reason": "commit_failed"}` and no mention of a subject, a length, or a
slug. The failure is reported as if the commit seam had broken.

**Two defects compound, and the second is worse.** `abort_claim` cannot undo the failed
claim: `claim.sh` writes the `claim:` stamp into `mission.md` *before* committing, so at
teardown the worktree is dirty, and `cleanup-mission-worktree.sh` correctly refuses to
discard uncommitted work. Every failed claim of this kind therefore **strands a worktree
and a local `work-*` branch**, and the next attempt fails differently
(`worktree_creation_failed`, "worktree already exists"), burying the original cause. Clearing
it by hand needs a targeted `git checkout` of the stamp — a destructive operation the drive
contract otherwise forbids a run from performing.

## Policies

- `workaholic:implementation` / `policies/observability.md` — `commit_failed` for a refused *subject* is a masked failure: the reported cause is not the actual one, and the actual one is knowable.
- `workaholic:implementation` / `policies/error-handling.md` — a slug长 enough to breach the subject limit is a foreseeable input, not an exceptional one; it deserves a contract.
- `workaholic:development` / `policies/parallel-long-running-agents.md` — a claim that cannot be published is a unit no runner can ever take; the coordination protocol silently loses the work.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu`.

## Key Files

- `plugins/workaholic/skills/drive/scripts/claim.sh` - builds `Claim ${unit}` and stamps before committing
- `plugins/workaholic/skills/commit/scripts/check-subject.sh` - the canonical 50-char rule, correctly applied
- `plugins/workaholic/skills/mission/scripts/slug.sh` - derives the slug; the natural place for a length bound
- `plugins/workaholic/skills/mission/scripts/create.sh` - where a too-long slug could be refused at authoring time
- `plugins/workaholic/skills/branching/scripts/cleanup-mission-worktree.sh` - refuses a dirty worktree, which is right, and is why teardown cannot recover
- `scripts/test-workflow-scripts.mjs` - the claim suite uses the short fixture slug `m1`, which is why this was never caught

## Implementation Steps

1. **Do not weaken the subject rule.** It is enforced in three layers and shared by one
   validator on purpose. The subject is what must change, or the slug is.
2. Decide the subject shape. The claim scan keys on `^Claim [^ ]+$` and reads the unit id
   back out of the subject, so the id must stay recoverable — that constraint is the whole
   design and any answer must preserve it. Candidates: bound the slug at creation so
   `Claim <slug>` always fits; or carry the unit id in a **trailer** and give the subject a
   fixed short form, updating `lib/claims.sh`'s parser in the same change.
3. **Make the refusal name its cause.** Whatever the fix, `claim.sh` must distinguish a
   rejected subject from a broken commit seam — `commit_failed` with no detail sent this
   run looking at the wrong layer.
4. **Fix the teardown ordering.** Stamp *after* the commit is known to be possible, or make
   `abort_claim` able to undo its own stamp. A claim that cannot be published must leave
   nothing behind; that is already the stated contract ("a refused claim leaves nothing
   behind"), and it is currently false for this path.
5. If the answer bounds the slug, provide the migration for the four existing missions —
   renaming a mission directory touches `mission:` relations on tickets, so it is not a
   `mv`.

## Quality Gate

**Acceptance criteria**

- A mission with a slug of any length that `slug.sh` can produce is claimable, or is refused **at creation** with a named reason — never accepted and then undrivable.
- The four missions listed above are claimable after the change, without their acceptance criteria or ticket relations being lost.
- A claim refused for a rejected subject reports a reason naming the subject, not a bare `commit_failed`.
- A refused claim leaves **no** worktree and **no** local branch behind, for this failure path as well as the others — asserted, since the contract already claims it.
- `lib/claims.sh` still recovers the unit id from a claim, and `list-claims.sh`/`plan-units.sh` report the same units as before for short-slug claims.
- The 50-character subject rule is unchanged in all three enforcement layers.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with new hermetic cases using a **long** mission slug (the fixture's `m1` is why this was missed): claiming succeeds, the reader reports the unit, and a deliberately unpublishable claim leaves no worktree or branch.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual `outputs/` diff.

**Gate**

- The long-slug claim round-trips: claimed, read back by `list-claims.sh` with the right unit id, and released. And the no-debris assertion passes — a stranded worktree turns one blocked unit into a repository a later run cannot claim in at all.

Decided: fix the claim seam rather than renaming the four missions by hand — renaming is a migration touching every ticket's `mission:` relation, and it would leave the next long slug broken in exactly the same way (developer may override at /drive).

Decided: the subject rule stays as it is. It is shared by three enforcement layers through one validator specifically so they cannot drift, and relaxing it for one caller is how that guarantee is lost (developer may override at /drive).

## Considerations

- The hermetic claim fixture uses `m1`. Every claim test passes today and would keep passing through this entire defect — the same shape as the `gh`-stub gap, where the fixture encoded the easy case. Add the long slug to the fixture, not just to one new test.
- `create-mission-worktree.sh` bounds the slug to `^[a-z0-9][a-z0-9-]*$` but not its length, so the worktree is created successfully and only the commit fails — which is why the debris appears at the last possible moment.
