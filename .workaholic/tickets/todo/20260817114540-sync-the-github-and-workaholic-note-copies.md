---
created_at: 2026-08-17T11:45:40+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260817114539-structure-the-note-as-the-release-record.md
mission: correct-the-release-note-automation-to-its-intended-design
merge_policy:
verification_handoff: 
---

# Sync the GitHub and workaholic note copies

## Overview

Expected action 4: the content lives both in GitHub's release-notes feature and under
`.workaholic`, and the two are **always identical**.

Two stores with one required content, one of which is a git tree whose conflicts are
resolved append-only and one of which is an external API. "Always identical" therefore needs
a named source of truth and a named reconciliation, or it becomes "usually identical, and
nobody can tell which one is wrong". That choice is this ticket's Open Decision, and it also
interacts with the previous ticket's self-reference problem: which copy is authoritative
decides whether a draft refresh has to touch git at all.

## Policies

- `workaholic:operation` / `policies/delivery.md` — the published artifact and its record must not disagree
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a divergence between two stores is reported, never silently repaired in one direction

## Key Files

- `plugins/workaholic/skills/ship/scripts/publish-release.sh` — publishes the GitHub Release
  today, deferring to CI where a release workflow exists.
- `.github/workflows/release.yml` — the CI half; it publishes on a version bump pushed to
  `main`, so it is a second writer of the GitHub side that this sync must not fight.
- `plugins/workaholic/skills/ship/scripts/read-release-notes.sh`,
  `commit-release-note.sh` — the `.workaholic` side's reader and writer.
- `plugins/workaholic/rules/shell.md` — **`gh release …` is REST-backed and stays**; `gh pr`,
  `gh issue` and `gh repo` are refused. This ticket is one of the few sanctioned users of
  `gh release`.
- `plugins/workaholic/skills/gather/scripts/gh-rest.sh` — for everything that is not
  `gh release`.

## Implementation Steps

1. Settle the Open Decision — nothing below can be built against an unnamed source of truth.
2. Implement the writer for the non-authoritative side, and make it a **projection**: it
   renders from the authoritative content and never merges.
3. Implement a comparison that reports divergence by name (which target, which section,
   which side is ahead) instead of repairing it blindly. A drafted note edited by a human on
   one side is a signal, not corruption.
4. Handle the two-writer reality on the GitHub side: `release.yml` publishes on a version
   bump. The sync must be idempotent against a release CI already created, and must never
   overwrite a *published* release's body with a draft's.
5. Use `gh release` for the GitHub side and `gh-rest.sh` for everything else.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- One side is declared authoritative in the skill text, and the code matches the declaration.
- A divergence is reported per target and section before anything is written.
- A published GitHub Release is never overwritten from a draft.
- Running the sync twice changes nothing the second time.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- A dry run against a target whose two copies are deliberately different: the divergence is
  named, not silently resolved.
- Two consecutive syncs: the second is a no-op.

**Gate** — what must pass before approval:

- The Open Decision resolved and recorded in the Final Report.

## Open Decisions

1. **Which copy is the source of truth?** Three coherent answers with different costs.
   (a) **`.workaholic` authoritative, GitHub projected**: fits the repository-as-coordination-medium
   model and makes the note reviewable in a pull request — but every draft refresh is a
   commit to `main`, which is the treadmill `workaholic:ship` §7 refused and the previous
   ticket's Open Decision is still wrestling with. (b) **GitHub authoritative (a draft
   release), `.workaholic` written only at release time**: no commit treadmill at all, and
   it matches "the GitHub release note is generated daily and updated as the release
   progresses" — but it weakens "always identical" to "identical once released", which is
   not what the ask says. (c) **Both authoritative for different sections** — the generated
   body from the base, the human's edits from GitHub — which is the most honest description
   of what will actually happen and the hardest to keep coherent. Ruling this decides the
   cadence ticket too.

## Considerations

- A GitHub **draft** release is invisible to consumers and free to rewrite, which makes it a
  natural home for a daily-regenerated document. That is the strongest argument for (b) and
  it should be weighed explicitly rather than dismissed for being less pure.
- This repository's `marketplace` target is deploy-on-merge with the release published from
  the merge commit, so the window between "drafted" and "released" is minutes. A consuming
  repository with a real staging tier has a window of days, and that is the case the design
  must serve.
