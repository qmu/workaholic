---
type: Feedback
title: Move branching model from GitHub Flow to Git Flow for QA and ship traceability
kind: instruction
source: slack
created_at: 2026-07-30T05:13:13+00:00
author: noreply@anthropic.com
supersedes: 
---

# Move branching model from GitHub Flow to Git Flow for QA and ship traceability

tamura_yoshiya raised this via Slack in `#dev-workaholic`, filed as GitHub issue
[#104](https://github.com/qmu/workaholic/issues/104): the ask is to move the branching model from
GitHub Flow toward a Git Flow model, primarily to strengthen QA and traceability around what
`/ship` actually ships and when.

## The current model, as verified

Reading `plugins/workaholic/commands/ship.md`, `plugins/workaholic/commands/drive.md`,
`plugins/workaholic/commands/report.md`, and the `workaholic:branching` skill
(`plugins/workaholic/skills/branching/SKILL.md`) confirms the current workflow is a
GitHub-Flow-style trunk-based model. Branches are always created by `branching/scripts/create.sh`
as `work-*` off of `main` (legacy `drive-*` and `trip/*` names are detected for backward
compatibility only and are never created anew). Per `workaholic:drive`'s Claims model, one unit
maps to one claim, one branch, one worktree, and one PR; `/drive` partitions work into these
units, claims and implements each in its own claim worktree, then routes it via
`effective-policy.sh` — `auto` goes straight through `/ship` (merge + teardown), `review` stops at
an open PR. `/ship` itself (`plugins/workaholic/skills/ship/SKILL.md`, Ship Flow §5) deploys and
confirms production from the work branch and merges the branch's PR directly into `main` as the
last step. Nowhere in these files, or in `docs/drive-loop-runbook.md` /
`docs/loop-engineering-workflow.md`, is there any `develop`, `release/*`, or `hotfix/*` branch —
every unit's branch merges straight to `main` via PR, which is the defining trait of GitHub Flow
rather than Git Flow.

## A correction to scope from the discussion

`/ship` does not currently produce zero artifacts. Ship Flow step 5 already generates a dated,
branch-named markdown file — it invokes the `workaholic:write-release-note` skill, which writes
`.workaholic/release-notes/<branch>.md` (or `-2.md`, `-3.md`, … for repeat ships on the same
branch), and `commit-release-note.sh` commits and pushes that file pre-merge so it rides into the
same merge as the shipped code. Post-merge, step 7's `publish-release.sh` turns that same note
(with frontmatter stripped) into a GitHub Release, unless CI already owns release publishing.
Separately, `record-evidence.sh` appends a "Deployment Evidence" block (deployer, target,
confirmation method, observed result, pass/fail) to that branch's story at
`.workaholic/stories/<branch>.md` before the merge, and that story's content is what
`create-or-update.sh` copies into the PR body. So today there is already a real pairing of an
in-repo `.workaholic/` markdown file plus the PR itself as evidence of a ship — it is just
structured around GitHub Releases and PR-body storytelling rather than a dedicated "ship record."

## The open design question

Given the existing release-notes/story mechanism described above, the concrete question raised is
whether that mechanism is sufficient once there is more than one branch tier between a
feature/claim branch and production, or whether it needs to be restructured. Under Git Flow, a
"ship" could mean a claim branch landing on `develop`, or a `release/*`/`hotfix/*` branch landing
on `main`, and the traceability requirement is that each such event still leaves behind two
durable, cross-referenced artifacts: a markdown record under `.workaholic/` (for in-repo history
you can grep and diff over time) and the GitHub pull request itself (for review and CI). Whether
that is best served by extending the existing `.workaholic/release-notes/` + story mechanism to
explicitly record which branch merged into which target and when, or by introducing a separate
ship-record document type distinct from the GitHub-Release-oriented release note, is an open
design question.

## Scoping note carried with the ask

This is a design/architecture change proposal, not an implementation ticket. Scope still needs to
be worked out by whoever picks it up: which branches Git Flow actually introduces here
(`develop`, `release/*`, `hotfix/*`, or some subset), how those interact with the existing
claim/worktree/`/drive` invariant of one unit to one claim to one branch to one worktree to one
PR, and how (or whether) the `.workaholic/` ship-record should be restructured versus reusing
release-notes/stories. Given how much machinery already exists around `/drive`, `/ship`, and
claim worktrees, this should probably start with a `/ticket` exploring that current machinery in
detail before any implementation is attempted.
