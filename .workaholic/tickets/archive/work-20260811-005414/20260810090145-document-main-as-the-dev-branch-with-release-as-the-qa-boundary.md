---
created_at: 2026-08-10T09:01:45+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: auto-merge-propose-and-implement-prs-under-a-dev-release-branch-split
merge_policy:
---

# Document main as the dev branch with release/* as the QA boundary

## Overview

FB `20260810090035` frames the auto-merge change as enabled by splitting the
current "main + feature branch" model into a development branch and a
release branch. This repository already has half of that: the `release/*`
tier (`branching/scripts/cut-release-branch.sh`, `.workaholic/releases/`,
decisions L1-L3) is exactly "the QA window between merged-onto-main and
released-to-production." What is missing is the explicit statement that
`main` itself is now the *continuously auto-merged development branch* (once
the companion ticket lands) and that `release/*` — not per-PR review — is
where quality is actually gated before production. This ticket updates the
docs to say that plainly, and checks whether the existing tier's assumptions
(cut only when the batch quality bar is already met, since `main` was
previously human-reviewed commit by commit) still hold once `main` accepts
unreviewed merges.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:operation` / `policies/deployment-and-release.md` — the release-branch/production boundary this ticket documents
- `workaholic:development` / `policies/managing-change-history.md` — distributing the branch-model change as a plugin update

## Key Files

- `CLAUDE.md` (`### The release tier (release/*)` section, decisions L1-L3) — needs a paragraph on `main`'s new role once the companion ticket lands
- `plugins/workaholic/skills/branching/SKILL.md` — the branching model description
- `plugins/workaholic/rules/workaholic.md` — general repo conventions, if it names the branch model
- `docs/loop-engineering-workflow.md` — the strategic narrative this direction most naturally extends

## Implementation Steps

1. Add a short section (near the existing `release/*` tier documentation)
   stating explicitly: `main` is the continuously auto-merged development
   branch; `release/*` is the pre-production QA/release boundary; nothing
   about the per-unit claim/branch/worktree/PR mechanics changes (there is
   still exactly one merge target for a unit, per the existing L1-L3
   framing).
2. Re-examine `cut-release-branch.sh`'s and the release-tier's stated
   assumptions for anything that quietly relied on `main` being
   human-reviewed commit by commit, and note explicitly whether any of them
   need to change (this ticket documents; it does not have to fix what it
   finds — file follow-on tickets for anything load-bearing).
3. Cross-link this section from wherever `/propose`'s and `/implement`'s
   changed merge behavior is documented (the companion ticket), so a reader
   following either lands on the whole picture.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `CLAUDE.md`'s release-tier section (and any other doc naming the branch model) states `main` = dev branch, `release/*` = QA/release boundary, without contradicting the untouched per-unit claim/branch mechanics.
- Any release-tier assumption found to rely on human-reviewed `main` is either fixed or filed as a named follow-on ticket — not silently left inconsistent.

**Verification method** — the commands/tests/probes that prove them:

- Read the updated docs against the actual behavior once the companion auto-merge ticket lands.
- `node scripts/build-plugins/verify.mjs` (doc/skill consistency where applicable).

**Gate** — what must pass before approval:

- Docs updated in the same change per `CLAUDE.md`'s *Update the docs in the same change*.

## Considerations

- This is a documentation/consistency ticket, not a new branching mechanism — the `release/*` tier already exists; this only names `main`'s changed role once the companion ticket lands. Sequence it alongside or after that ticket, not before, so it does not describe a state the code does not yet have.
- If step 2 finds the release cut currently assumes a reviewed `main`, that finding may itself argue for tightening `cut-release-branch.sh` rather than just documenting the gap — file that as its own ticket rather than expanding this one's scope.
