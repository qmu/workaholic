---
created_at: 2026-07-31T16:30:49+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash:
category:
depends_on:
mission:
merge_policy: review
---

# Make /propose survey the whole repository state and land its proposal as a mission with tickets on a work branch

## Overview

`/propose` today reads one input and writes one output: feedback records added between the runner-local `proposal-cursor` and `origin/main` go in, a `status: draft` mission pushed straight to `main` comes out. That is too narrow to answer the question a developer actually opens the repository with — *what should I do next* — and it publishes its answer to `main` where no merge event exists to announce it.

This ticket widens the batch's inputs, makes it emit the ticket set alongside the mission, and moves its output onto a `work-*` branch behind a pull request. The third change is the load-bearing one: **every workaholic artifact — feedback, mission, ticket — is committed on a `work-*` branch and reaches `main` through a merged pull request**, so the merge event is what notifies Slack. That is the project standard, and it supersedes the publish-to-`main` path recorded as decision J1 (2026-07-30) for artifact creation.

## Policies

The standard engineering policies that govern this ticket.

- `workaholic:implementation` / `policies/directory-structure.md` — the batch's scripts live under the propose skill's `scripts/`, and the new readers must not grow a second copy of a reader that already exists (`read-relation.sh`, `list-todo.sh`, `mission-owners.sh`)
- `workaholic:implementation` / `policies/coding-standards.md` — the scripts are POSIX `#!/bin/sh -eu` per `rules/shell.md`; all multi-step logic is extracted to bundled scripts, never inlined into skill markdown
- `workaholic:implementation` / `policies/objective-documentation.md` — the judgment bar must be restated in verifiable terms once the inputs broaden, or "conservative" silently stops meaning anything
- `workaholic:operation` / `policies/ci-cd.md` — the proposal now arrives as a pull request, so its branch passes the same CI gates every other branch does before it can merge

## Key Files

- `plugins/workaholic/skills/propose/SKILL.md` - the batch's contract: the cursor, the judgment bar, the draft schema, the scripts index. Every change here is documented in the same commit
- `plugins/workaholic/skills/propose/scripts/new-feedback.sh` - the current window; joined by the new state readers rather than replaced
- `plugins/workaholic/skills/propose/scripts/scaffold-draft.sh` - the draft writer; must gain the ticket set and lose the assumption that its output lands on `main`
- `plugins/workaholic/skills/propose/scripts/cursor.sh` - the processed-commit cursor; its advance-only-on-success contract must survive the branch/PR path
- `plugins/workaholic/commands/propose.md` - the command body that orchestrates the batch
- `plugins/workaholic/skills/branching/scripts/create.sh` - the only sanctioned brancher (`work-YYYYMMDD-HHMMSS`), enforced by `hooks/guard-git-branch.sh`
- `plugins/workaholic/skills/report/scripts/create-or-update.sh` - the sanctioned PR creator the batch must reach for rather than calling `gh` itself
- `plugins/workaholic/skills/propose/scripts/notify-slack.sh` - the existing notifier; announcing the PR is not the same event as announcing the merge
- `CLAUDE.md` - carries the J1 statement ("The claim is the only creator of a branch or a worktree") and the publish-tree section, both of which this change contradicts and must update
- `docs/proposal-loop-runbook.md` - the 15-minute cron entry's runbook

## Related History

The proposal batch and its cursor were built as a headless, silence-is-valid loop; the publish-tree path it now uses arrived one day before this ticket, so the two have barely coexisted.

Past work that touched this area:

- Decision J1/J2 (2026-07-30) — artifact creation publishes to `main` through a `.publish/` tree and creates no branch, so that a fresh clone and every runner sees an artifact the moment it exists. This ticket reverses that for artifact creation, and the reversal must be recorded, not silently applied
- Decision C1–C4/B1 — the cursor is runner-local and advances only after a successful push; the claim protocol is the multi-runner answer

## Implementation Steps

1. **Broaden the inputs.** Add readers for the three new signals beside `new-feedback.sh`: the active missions with their status and progress, the current `todo/` queue, and the commit subjects/bodies on `main` since the cursor. Each is a pure read emitting JSON. Reuse the existing readers (`mission/scripts/list.sh`, `drive/scripts/list-todo.sh`, `gather/scripts/collect-commits.sh` or equivalent) instead of re-parsing frontmatter — the propose skill already states that nothing parses a relation itself.
2. **Restate the judgment bar for the wider input.** The current bar is written against feedback alone and rests on an asymmetry argument (a false negative costs one cron cycle; a false positive spams the channel) that assumed a narrow signal. Write the bar for the new inputs explicitly: what in a commit log or an open queue does and does not warrant a proposal, and what "already covered" means now that in-flight tickets and unapproved drafts are both visible.
3. **Emit the ticket set with the mission.** Extend `scaffold-draft.sh` (or a sibling) to write the ordered tickets the proposal implies into `todo/<user>/`, each carrying the `mission:` relation to the draft. Note the safety property that makes this sound: `plan-units.sh` excludes any ticket carrying a `mission:` relation from the backlog offer as `mission_member`, regardless of the mission's status — so proposed tickets are unclaimable until the mission is approved, with no new gate required.
4. **Land the output on a `work-*` branch.** Replace the push-to-`main` seam with: `branching/scripts/create.sh` for the branch, the existing commit seam for the artifacts, then `report/scripts/create-or-update.sh` for the pull request. The batch stays headless — it asks nothing, and a failure aborts with a machine-readable reason.
5. **Keep the cursor honest across the new path.** The cursor may advance only once the proposal is durably published — decide and record whether that means "the PR is open" or "the PR is merged", because the difference decides whether an unmerged proposal is re-proposed next tick.
6. **Generalize the standard to the other artifact writers.** `/ticket`, `/fb`, and `/mission` currently publish to `main` through the publish tree. Bring them onto the same `work-*` + PR path so the standard holds for every artifact, or record explicitly which writers are exempt and why.
7. **Update the documentation in the same change.** `CLAUDE.md` (the J1 statement, the publish-tree section, the `/propose` and `/ticket` command table rows), `plugins/workaholic/skills/propose/SKILL.md`, `plugins/workaholic/skills/branching/SKILL.md`, and `docs/proposal-loop-runbook.md` all describe the superseded behavior.
8. **Rebuild the generated artifacts.** `node scripts/build-plugins/build.mjs`, since the propose and branching skills ship into `outputs/workflows`.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `/propose` run that decides to propose leaves `origin/main` unchanged, creates exactly one branch matching `work-[0-9]{8}-[0-9]{6}`, and opens exactly one pull request carrying both the draft mission and its tickets.
- A `/propose` run that decides to stay silent creates no branch, no pull request, and no artifact — silence remains a first-class outcome.
- Every ticket the batch emits carries a `mission:` relation to the draft it belongs to, and `plan-units.sh` reports each of them as `excluded` with `reason: mission_member` — proving the proposal is unclaimable before approval.
- The batch issues no `AskUserQuestion` on any path, and every abort emits a machine-readable reason.
- The cursor does not advance on a run whose branch creation, commit, push, or PR creation failed.
- `hooks/validate-ticket.sh`, `hooks/validate-mission.sh`, and `hooks/validate-feedback.sh` all accept the artifacts the batch writes.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` is green, with new hermetic cases covering: the propose-path branch/PR shape, the silent path writing nothing, the `mission_member` exclusion of emitted tickets, and the cursor not advancing on a failed publish.
- `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs` pass.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.
- A live `/propose` run in this repository produces a reviewable pull request, and `git log origin/main` shows no direct proposal commit.

**Gate** — what must pass before approval:

- The suite is green, the scripts are POSIX-conforming, the documentation listed in step 7 tells the truth, and the live run above is demonstrated in-session.

## Considerations

- This reverses decision J1 for artifact creation (`CLAUDE.md`, the *Claim protocol* section). J1's motive was that an artifact must be visible to every runner and fresh clone the moment it exists; a proposal behind an unmerged PR is deliberately *not* yet visible, which is the point of review. Both cannot be true of one commit, so the decision record must say which wins and for which artifacts, rather than leaving two contradictory statements in the repository.
- The publish tree (`.publish/`, decision J2) exists so a developer typing `/ticket` mid-work on a dirty branch does not have their checkout disturbed. Moving the writers onto `work-*` branches must preserve that property — `create.sh` switches the current checkout's branch, which is exactly what the publish tree was built to avoid (`plugins/workaholic/skills/branching/SKILL.md`).
- Broader inputs on a 15-minute cron will find *something* proposable most ticks unless the bar is genuinely tightened; the failure mode is a channel full of proposals nobody reads, which is the trust erosion the current bar's asymmetry argument was written to prevent (`plugins/workaholic/skills/propose/SKILL.md`, *The judgment bar*).
- Slack notification on the merge event needs a source. A merged PR notifies only if something watches for it — a GitHub webhook/Action, or the merging path calling the notifier. `notify-slack.sh` announces when *called*, and nothing calls it on a merge performed by a human in the GitHub UI (`plugins/workaholic/skills/propose/scripts/notify-slack.sh`).
