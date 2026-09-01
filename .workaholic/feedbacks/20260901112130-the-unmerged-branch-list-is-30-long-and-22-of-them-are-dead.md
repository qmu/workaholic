---
type: Feedback
title: The unmerged-branch list is 30 long and 22 of them are dead
kind: instruction
source: discussion
subject: person:a@qmu.jp
created_at: 2026-09-01T11:21:30+00:00
author: a@qmu.jp
supersedes: 
---

# The unmerged-branch list is 30 long and 22 of them are dead

Source: https://github.com/qmu/workaholic/issues/841

Measured on `qmu/workaholic`, 2026-09-01: `git branch -r --no-merged origin/main` returns **30** branches, and only five of them are anything a person should ever look at. Seventeen have a **merged** pull request, five have a pull request **closed unmerged** as superseded, two are open awaiting an operator ruling (#647, #694), two are orphan log branches by design, three are live claims from the current hour, and one is an autofix branch that opened no pull request at all.

**The 17 are the squash-merge and `delete_branch_on_merge` interacting.** A squash-merged branch is never an ancestor of the base, so `--no-merged` lists it forever; `delete_branch_on_merge` is the only cleanup and it is forward-only, so every branch merged before the setting was applied stands permanently. `CLAUDE.md` states the forward-only cost and says the standing branches are "reported with a ready-to-run deletion command and never deleted by the command" — after two weeks that report is 17 lines long and nobody has run it.

**The 5 are the operator paying by hand for duplicate implementation.** `#801`, `#802` and `#790` were all closed as superseded by `#800`; `#520` by `#519`; `#466` by `#465`. In each case two runs implemented the same defect twice, `main` took one, and a person had to read both, close the loser, and carry the good parts of it across by hand. `#802`'s closing comment reads "this branch and `main` repaired the same defect twice".

**Nothing retires either kind.** `retire-claim.sh` acts on the tree-derived `superseded` verdict alone, which none of these 22 branches reach: a merged branch's tickets are archived but the verdict needs the emptiness proof, and a hand-closed branch is not empty by construction. So the claim oracle keeps offering four of them as `stranded` / `report_undelivered`, `/moderate` asks about them every hour, and every `/implement` run re-reports them. The list is not a backlog; it is 22 dead entries the loop cannot tell from live ones.

**Separately: five pull requests outlived their head branch.** `#813`, `#799`, `#688`, `#635` and `#625` were open with no branch on the remote — GitHub does not close a pull request when its head branch is deleted, and such a pull request can never be merged by anyone. Their content was already on `main`, verified file by file, and they were closed by hand today. Nothing in the loop reads this state, so they had been sitting in the open set inflating every count that reads it.

## What the operator asks for

1. **A retirement path for a branch whose pull request merged, and for one whose pull request was closed unmerged.** Both are provable without a person — the pull request's own `merged_at` / `state`, plus the existing branch-emptiness machinery — and neither needs the `superseded` verdict widened. The destructive act already has a home in `.github/workflows/claim-retirement.yml`; this is two more candidate readings feeding it.
2. **A `/moderate` reading that names a headless open pull request.** A pull request whose head branch is gone is unmergeable by construction, so it is a fact about the repository, not a judgement, and it belongs beside `operator-pulls`.
3. **The duplicate-implementation cause.** The `work_waiting` + `open_proposal` gate is documented as giving "one mission per strategy in flight at a time", and it did not stop two runs writing the same fix five separate times. Whatever the gate is actually reading, it is not catching the case where the second run's ask arrives while the first run's work is on a branch rather than in the queue.
