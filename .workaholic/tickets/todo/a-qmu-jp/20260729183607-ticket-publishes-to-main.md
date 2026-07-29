---
created_at: 2026-07-29T18:36:07+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Domain]
effort:
commit_hash:
category:
depends_on: [20260729183606-publish-tree-primitive.md]
mission:
merge_policy: auto
---

# /ticket publishes to main instead of cutting a work branch

## Overview

`/ticket` currently cuts a branch before it writes anything: [create-ticket/SKILL.md](plugins/workaholic/skills/create-ticket/SKILL.md) Workflow Step 1 runs `branching/scripts/create.sh` whenever `check.sh` reports `on_main: true`, and [commands/ticket.md](plugins/workaholic/commands/ticket.md) Step 2 then stages and commits **without pushing**. A ticket therefore lands on a local, unpushed `work-*` branch that `/drive` cannot survey, that a second machine cannot see, and that a fresh clone does not contain. The branch was introduced to keep `main` tidy; under the claim protocol that job belongs to the executor, and the branch now only strands the work.

This ticket makes `/ticket` a pure **source**: it writes the ticket into a publish tree checked out at `origin/main`, commits it through the shared commit wrapper, pushes it to `main`, and tears the publish tree down — leaving the developer's branch and uncommitted work completely untouched. The developer can type `/ticket` mid-work on a dirty feature branch and the ticket still reaches the queue that the cron `/drive` loop drains.

Two prompts disappear with the branch. `/ticket`'s Step 0 worktree guard ("Continue here" vs "Switch to worktree") exists solely to stop a ticket being written against the main tree when the developer meant to be in a worktree; once every ticket goes to `main` by construction, the question has no answer that changes anything and must be retired rather than left asking something meaningless. That also removes one `AskUserQuestion`, which is the direction [rules/interaction.md](plugins/workaholic/rules/interaction.md) points.

## Policies

- `workaholic:implementation` / [directory-structure.md](plugins/workaholic/skills/implementation/policies/directory-structure.md) — tickets keep their existing home under `.workaholic/tickets/todo/<user>/`; only the checkout they are written into changes.
- `workaholic:implementation` / [coding-standards.md](plugins/workaholic/skills/implementation/policies/coding-standards.md) — POSIX `#!/bin/sh -eu` for anything scripted; per the Shell Script Principle the command markdown gains no conditionals.
- `workaholic:implementation` / [domain-layer-separation.md](plugins/workaholic/skills/implementation/policies/domain-layer-separation.md) — `/ticket` stays a thin entry point calling the publish-tree scripts; it must not re-implement fetch, commit, or push.
- `workaholic:design` / [modeless-design.md](plugins/workaholic/skills/design/policies/modeless-design.md) — this is the policy the change most directly serves: creating a ticket stops requiring the developer to first be in the right branch or worktree mode. Removing the Step 0 guard removes a mode question.
- `workaholic:planning` / [ai-native-future.md](plugins/workaholic/skills/planning/policies/ai-native-future.md) — the human seam survives the automation: `merge_policy` is still captured at creation (absent still reads as `review`), so publishing straight to `main` never implies unattended merging of the *work*.
- `workaholic:planning` / [terminology.md](plugins/workaholic/skills/planning/policies/terminology.md) — `branch_created` leaves the vocabulary of `/ticket` entirely; every mention in the skill, command, output contract, and docs goes in this same change.
- `workaholic:implementation` / [objective-documentation.md](plugins/workaholic/skills/implementation/policies/objective-documentation.md) — the `/ticket` row in `CLAUDE.md`'s command table and `README.md` describe the old flow and are corrected here, not later.

## Key Files

- [commands/ticket.md](plugins/workaholic/commands/ticket.md) — Step 0 worktree guard (~L49-55) is deleted; Step 1 "create a topic branch if on main" (~L61) becomes the publish-tree open; Step 2 "Commit and Present" (~L72-76) becomes commit-and-push through the publish tree. The prompt-label list (~L24) loses the worktree-guard entry.
- [create-ticket/SKILL.md](plugins/workaholic/skills/create-ticket/SKILL.md) — Workflow Step 1 "Check Branch" (~L144-150) is replaced by "Open the publish tree"; the Output Contract (~L262, ~L273) drops `branch_created`; the Allowed Locations section gains the sentence that the paths resolve inside the publish tree.
- [create-ticket/scripts/sweep-todo.sh](plugins/workaholic/skills/create-ticket/scripts/sweep-todo.sh) — the stray-ticket sweep must now run **inside the publish tree**, since that is where `todo/` is being written.
- [create-ticket/scripts/summary.sh](plugins/workaholic/skills/create-ticket/scripts/summary.sh) — read-only summary mode; it reads the *caller's* checkout and must keep doing so (a developer asking "what is in my queue" means their checkout).
- [branching/scripts/create.sh](plugins/workaholic/skills/branching/scripts/create.sh) — loses `/ticket` as a caller; it remains the claim-side branch creator and is not modified.
- [branching/scripts/check-worktrees.sh](plugins/workaholic/skills/branching/scripts/check-worktrees.sh) — its only consumer was the Step 0 guard; confirm whether it retains any caller after this change.
- [rules/interaction.md](plugins/workaholic/rules/interaction.md) — the standing rule that justifies retiring the guard prompt.
- [CLAUDE.md](CLAUDE.md), [README.md](README.md) — the `/ticket` row and workflow description.
- [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) — no test asserts `/ticket`'s branch-cut orchestration today; the new behaviour gets one.

## Related History

- [20260129012614-auto-branch-on-ticket.md](.workaholic/tickets/archive/feat-20260128-220712/20260129012614-auto-branch-on-ticket.md) - Introduced exactly the behaviour this ticket removes (retired `/branch`, made `/ticket` auto-cut a topic branch on main)
- [20260613090209-per-user-todo-subdirectories.md](.workaholic/tickets/archive/work-20260528-122941/20260613090209-per-user-todo-subdirectories.md) - Partitioned `todo/<user>/` so one developer's unarchived tickets do not leak onto another's branch; the partition stays useful for assignment, but its branch-leak rationale dissolves once every ticket is on main
- [20260728221803-unify-drive-executor.md](.workaholic/tickets/archive/work-20260728-221717/20260728221803-unify-drive-executor.md) - Built `plan-units.sh`, the survey that consumes the backlog this command produces

## Implementation Steps

1. **Delete Step 0, the worktree guard**, from [commands/ticket.md](plugins/workaholic/commands/ticket.md), together with its entry in the project-label prompt list. Replace nothing — the question is moot once every ticket is published to `main`. Record the removal's reason in the command's prose so a later reader does not restore it.

2. **Replace Workflow Step 1 in [create-ticket/SKILL.md](plugins/workaholic/skills/create-ticket/SKILL.md).** "Check Branch" becomes "Open the publish tree": run `branching/scripts/open-publish-tree.sh`, take its `path`, and treat that path as the root every subsequent write resolves against. Delete the branch-name rule paragraph from this step (it belongs to the claim side and is stated in `branching/SKILL.md`) and the already-on-a-topic-branch paragraph. State plainly that `/ticket` **never creates a branch**.

3. **Route the writes into the publish tree.** The stray-ticket sweep (Step 1.5) and the ticket writes (Step 5) both target `<publish_path>/.workaholic/tickets/…`. Use `( cd <publish_path> && … )` subshells for the scripts, as `/mission` does today — `guard-working-directory.sh` tolerates that form, and `guard-repo-confinement.sh` accepts the path because a registered worktree is inside the repository by its own definition.

4. **Keep summary mode reading the caller's checkout.** Bare `/ticket` and `/ticket summary` answer "what is assigned to me", which is a question about the developer's own checkout, not about `origin/main`. It must not open a publish tree — it writes nothing and should stay instant and offline-tolerant. Note this divergence explicitly in the skill so it is not "fixed" later.

5. **Rewrite Step 2, "Commit and Present".** Stage and commit inside the publish tree via `branching/scripts/publish-tree-commit.sh` with the existing subject `Add ticket for <short-description>`, then close the publish tree. Present the ticket path, the pushed commit, and the fact that it is already on `main` and claimable by the next `/drive` tick. Keep the existing "skip commit if invoked during `/drive`" carve-out — a deferred ticket minted mid-run belongs on the claim branch and reaches `main` when the PR merges, which is correct and must not be re-routed through a publish tree.

6. **Handle the publish failures the primitive reports.** `no_origin` and `diverged` are reported to the developer with the ticket left intact in the publish tree and an explicit statement that it is **not yet on `main`**. A silent failure here is the worst outcome available: the developer believes work is queued when it is not.

7. **Drop `branch_created` from the Output Contract** in the skill and from the command's step description. Nothing downstream consumes it once no branch is created.

8. **Add hermetic coverage** to [test-workflow-scripts.mjs](scripts/test-workflow-scripts.mjs) for the orchestration this ticket introduces — currently no test exercises `/ticket`'s branch behaviour at all.

9. **Update the docs in this same change**: the `/ticket` row in [CLAUDE.md](CLAUDE.md)'s command table (it still describes creation-time branching), the Development Workflow section, [README.md](README.md), and [.workaholic/README.md](.workaholic/README.md) where it describes where tickets live and how they reach `/drive`.

10. **Rebuild the generated artifacts** — `create-ticket` ships in `outputs/workflows`, so run the argument-less `node scripts/build-plugins/build.mjs` and commit the result.

## Quality Gate

**Acceptance criteria**

- Running `/ticket "<description>"` from a **dirty feature branch** produces a ticket that is present on `origin/main` and leaves the caller's checkout byte-identical: same branch, same staged and untracked sets, same file contents. This is the criterion the whole change exists for.
- Running `/ticket` from a clean `main` produces the same result and does **not** fast-forward, rebase, or otherwise mutate the caller's `main` as a side effect of publishing.
- No `work-*` branch is created by any `/ticket` invocation, and `create.sh` is not called anywhere in the `/ticket` path.
- The published ticket validates: `hooks/validate-ticket.sh` passes on it (frontmatter, `todo/<user>/` location, non-empty `## Policies` and `## Quality Gate`), and it carries `merge_policy` exactly as answered at creation, with an unanswered value left empty and reading as `review`.
- A ticket published this way is visible to `plan-units.sh` from a *different* clone that has fetched — i.e. it is genuinely claimable by another runner, which is the end-to-end point of the change.
- `/ticket`'s Step 0 worktree-guard `AskUserQuestion` is gone; the run issues no prompt about branches or worktrees. The remaining prompts (moderation, Quality Gate interrogation, mission association, merge policy, ambiguity) still carry the `[<project label>]` prefix and still pass `guard-askuserquestion-label.sh`.
- Bare `/ticket` / `/ticket summary` still lists the caller's own queue from the caller's checkout, opens no publish tree, writes nothing, and works with no network.
- A `/ticket` invoked during a `/drive` run still writes to the claim branch and does not open a publish tree.
- `no_origin` and `diverged` are surfaced to the developer with an explicit "not yet on main"; neither is swallowed and neither loses the ticket body.
- `branch_created` appears nowhere in `plugins/` or `outputs/`.
- Every document listed in implementation step 9 describes the new flow; no document still says `/ticket` creates a branch.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, extended with: publish-from-dirty-branch leaves the caller's checkout unchanged; the ticket lands on `origin/main`; a second clone's `plan-units.sh` sees it after fetch; no `work-*` branch is produced; summary mode reads the caller's checkout and touches no remote.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs && node scripts/build-plugins/validate-metadata.mjs` clean with no residual `outputs/` diff.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- `grep -rn 'branch_created' plugins/ outputs/` returns nothing.
- A live in-session rehearsal in this repository: from a dirty feature branch, run `/ticket` end to end, confirm the ticket is on `origin/main`, confirm `git status` on the feature branch is unchanged, then remove the rehearsal ticket.

**Gate**

- The full `## Local Verification` command set from [CLAUDE.md](CLAUDE.md) passes.
- The caller-checkout-untouched invariant is asserted by a named test, not only observed in the rehearsal.
- The dependency ([20260729183606-publish-tree-primitive.md](.workaholic/tickets/todo/a-qmu-jp/20260729183606-publish-tree-primitive.md)) is merged first; this ticket does not re-implement any part of the publish sequence.

**Decided** (recorded rather than asked; override at review time):

- `Decided:` the Step 0 worktree guard is **removed, not reworded** — its stated rationale ("prevents creating tickets against the main tree when the user may intend to work within a claim worktree") is exactly the concern this change eliminates, and a prompt whose every answer produces the same outcome is worse than no prompt.
- `Decided:` **summary mode keeps reading the caller's checkout** — it answers a question about the developer's own working state, and forcing a fetch would make a read-only listing fail offline.
- `Decided:` the `/drive`-invoked carve-out is **kept** — a deferred ticket minted mid-run belongs in the PR that discovered it, and routing it to `main` separately would split one unit of work across two merges.
- `Decided:` verification is the **hermetic suite plus one live rehearsal in this repository**, matching the dependency's gate; the repository is its own consumer, so the real path is cheap to exercise.

## Considerations

- **The per-user `todo/<user>/` partition loses its original rationale but keeps its function** (`plugins/workaholic/skills/create-ticket/SKILL.md`, Allowed Locations). It was introduced so one developer's unarchived tickets would not leak onto another's branch; with every ticket on `main` there are no branches to leak between. The partition still expresses assignment and `list-todo.sh` still scopes the queue by it, so keep it — but the *stated reason* in the skill is now false and should be rewritten to "assignment", not left as-is.
- **`check-worktrees.sh` may become caller-less** (`plugins/workaholic/skills/branching/scripts/check-worktrees.sh`). Check before deleting: `/mission` and other flows may still use it, and the publish tree itself will now appear in its output. If it survives, confirm nothing treats the publish tree as a claim worktree.
- **Two `/ticket` runs in quick succession share one publish tree** (`plugins/workaholic/skills/branching/scripts/open-publish-tree.sh`). The primitive resets on open and refuses a dirty publish tree, so the second run either publishes cleanly or refuses loudly — but the interleaving deserves a test rather than an assumption, since two agent sessions on this server is the normal case, not an edge one.
- **`validate-ticket.sh` resolves a ticket's `mission:` relation in the ticket's own checkout** (`plugins/workaholic/hooks/validate-ticket.sh`). With tickets written into the publish tree and missions also published to `main` (the sibling ticket), that resolution now succeeds in the common case for the first time — but the hook fires `PostToolUse` on the *write*, so confirm it resolves against the publish tree and not the caller's checkout.
