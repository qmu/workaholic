---
created_at: 2026-08-01T03:13:05+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 0.5h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: auto
claim: work-20260731-201257
---

# close-publish-tree.sh refuses to close after the standard PR publish path

## Overview

`publish-tree-pr.sh` is **the default publication path** for every workaholic
artifact (decision J4): it commits on `publish-main` and pushes that local branch
to a remote `work-*` branch behind a pull request. `close-publish-tree.sh` then
refuses to tear the tree down, because its only success condition is that
`publish-main` is an ancestor of `refs/remotes/origin/<base>`:

```sh
if git merge-base --is-ancestor "$PUBLISH_BRANCH" "$remote_ref"; then :
else  # -> {"ok": false, "reason": "unpublished_commits", ...}
```

After a PR publish the commit is on `origin/work-*` and, by construction, **not**
on `origin/main` until somebody merges the pull request — which J4 explicitly
says is a human act with no deadline. So the documented two-line closing
sequence in `commands/ticket.md` and `skills/create-ticket/SKILL.md`
(`publish-tree-pr.sh` then `close-publish-tree.sh`) **always ends in a refusal**,
and every `/ticket`, `/mission`, and `/fb` run leaves `.publish/` and a
`publish-main` branch behind.

Reproduced live 2026-08-01: publishing two feedback records through
`publish-tree-pr.sh` returned `pr_url` for PR #135, and the immediately following
`close-publish-tree.sh` returned
`{"ok": false, "reason": "unpublished_commits"}`.

The refusal's intent is right and must survive — it exists so a *genuinely
unpublished* commit (the `diverged` shape) is never destroyed by a bookkeeping
call. The defect is that its test asks the wrong question: it checks "did this
reach the base?" when what it needs to know is "is this reachable from **any**
pushed ref?".

## Policies

- `workaholic:implementation` / `policies/command-scripts.md` — the script owns this decision; its predicate must express the property the caller actually depends on, not a proxy that happens to hold on one of two paths.
- `workaholic:implementation` / `policies/observability.md` — a documented sequence whose last step always fails trains its callers to ignore the failure, which is how the one refusal that matters gets ignored too.
- `workaholic:implementation` / `policies/test.md` — the two publish paths are a two-case matrix and the suite must cover both, since covering only the direct path is what let this ship.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — layout and POSIX `#!/bin/sh -eu` house style.

## Key Files

- `plugins/workaholic/skills/branching/scripts/close-publish-tree.sh` - lines 54-61 hold the ancestry test to fix
- `plugins/workaholic/skills/branching/scripts/publish-tree-pr.sh` - reports the `branch` it pushed to; the ref the close test must consider
- `plugins/workaholic/skills/branching/scripts/publish-tree-commit.sh` - the direct-to-base path, whose current behavior must not change
- `plugins/workaholic/skills/branching/SKILL.md` - the publish-tree contract (decision J2)
- `plugins/workaholic/commands/ticket.md` - Step 2 documents the publish-then-close sequence
- `plugins/workaholic/skills/create-ticket/SKILL.md` - Workflow Step 1, same sequence
- `scripts/test-workflow-scripts.mjs` - hermetic branching-script suite

## Implementation Steps

1. Replace the base-only ancestry test with a **reachability** test: `publish-main` is safe to delete when its tip is contained in *some* remote-tracking ref of `origin` — the base, or the `work-*` branch a PR publish just pushed. `git branch --remotes --contains <sha>` answers it directly and needs no state passed between the two scripts.
2. Keep the refusal for the case it was written for: a `publish-main` tip reachable from **no** remote ref is still `unpublished_commits`, still refuses, and still removes nothing. Reproduce that state in a test (commit into the publish tree, do not publish, then close) so the guard is proven to still bite.
3. Keep `dirty_publish_tree` exactly as it is.
4. Sharpen the refusal `detail` to name what it looked for, so the message distinguishes "never pushed anywhere" from the old, confusing "not on main" — an operator who reads the current text after a successful PR publish reasonably concludes the publish failed.
5. Check whether callers were written around the broken behavior. `commands/ticket.md` currently instructs *not* to close on a publish failure and to close otherwise; confirm that instruction still reads correctly once closing succeeds on the PR path, and correct it in the same commit if not.
6. Add the missing note to `branching/SKILL.md`: a publish tree closed after a PR publish leaves the work on the remote `work-*` branch, which is the intended end state — the tree is disposable, the branch is the artifact.
7. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`) — the branching scripts ship into the workflows bundle.

## Quality Gate

**Acceptance criteria**

- Open a publish tree, write a file, publish through `publish-tree-pr.sh` (with `gh` stubbed), then `close-publish-tree.sh` returns `ok: true` with `removed: true` and `branch_deleted: true`.
- Open a publish tree, write a file, publish through `publish-tree-commit.sh`, then close — unchanged from today: `ok: true`.
- Open a publish tree, commit into it **without** publishing, then close — still `ok: false, reason: "unpublished_commits"`, and neither the worktree nor the branch is removed.
- A dirty publish tree still refuses with `dirty_publish_tree` and removes nothing.
- Closing when the publish tree is already gone is still idempotent (`removed: false`).
- The refusal `detail` names that no remote ref contains the tip, rather than referring only to the base.
- `branching/SKILL.md` and, if step 5 finds them stale, `commands/ticket.md` / `create-ticket/SKILL.md` are corrected in the same commit.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with one hermetic case per acceptance bullet above. The suite already builds throwaway repositories with a local `origin`, so the PR path is exercised with `gh` stubbed on `PATH` and no network call.
- End-to-end in-session confirmation on this repository: run the documented `publish-tree-pr.sh` → `close-publish-tree.sh` sequence once and observe `ok: true` and `.publish/` gone.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — no residual `outputs/` diff.

**Gate**

- The suite is green **including the never-published refusal case** — this fix widens a safety predicate, so the proof that it still refuses the dangerous state is the part that must not be skipped.

Decided: a live in-session run of the documented sequence is included on top of the hermetic suite — unlike the other tickets in this batch, the defect is precisely that the *documented sequence* fails end to end, and the suite's stubbed `gh` cannot demonstrate the real path was fixed (developer may override at /drive).

Decided: reachability from any `origin/*` ref rather than threading the pushed branch name from `publish-tree-pr.sh` into `close-publish-tree.sh` — the scripts stay independently callable, and a caller that publishes and then closes in a later session still closes correctly (developer may override at /drive).

## Considerations

- Widening the predicate means a tip reachable from *any* stale remote-tracking ref counts as published. Fetch state is the input, so a long-lived stale ref could in principle make an unpublished tip look published; the risk is bounded because `publish-tree-pr.sh` pushes immediately before the close (`plugins/workaholic/skills/branching/scripts/close-publish-tree.sh`).
- `open-publish-tree.sh` resets `publish-main` to `origin/<base>` on every open, so a leftover tree from a refused close is not lost work — but it *is* how a second artifact could ride into an unrelated publish if a caller reuses the tree without reopening. Fixing the close removes the situation rather than documenting around it (`plugins/workaholic/skills/branching/scripts/open-publish-tree.sh`).
- Independent of the rest of this batch — it touches only the branching scripts and can be driven in any order.
