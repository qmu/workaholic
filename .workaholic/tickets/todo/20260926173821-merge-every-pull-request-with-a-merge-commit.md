---
created_at: 2026-09-26T17:38:21+09:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: merge-pull-requests-so-landed-branches-read-as-merged
merge_policy:
verification_handoff: 
---

# Merge every pull request with a merge commit

## Overview

The developer asked the loop to stop squash-merging (issue #1279, 2026-09-26): landed `work-*`
branches must read as merged. Today `gather/scripts/merge-method.sh` answers `squash` (the
2026-09-01 ruling) and every REST merge site plus the two agent-level merges read it, so a landed
branch is never an ancestor of `main`. Switch the one derivation to `merge` so the merged branch
tip becomes an ancestor of the base, and keep `main` readable as one line per unit through the
merge commit's own title and body.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/gather/scripts/merge-method.sh` — the one derivation; answer `merge` and rewrite its header (the squash rationale becomes history, the new ruling and its cost are stated).
- `plugins/workaholic/skills/gather/scripts/merge-commit-body.sh` — composes `commit_title`/`commit_message`; keep composing them for a merge commit (story-derived title and body), so `git log --first-parent main` reads one line per unit.
- `plugins/workaholic/skills/ship/scripts/merge-pr.sh`, `branching/scripts/publish-tree-pr.sh`, `drive/scripts/retry-undelivered.sh`, `drive/scripts/catch-up-claim.sh`, `branching/scripts/settle-stranded-publication.sh`, `moderate/scripts/persist-log.sh` — the REST call sites; confirm each passes the derived method and a body valid for a merge commit.
- `plugins/workaholic/skills/drive/SKILL.md`, `drive/reference/routing.md`, `commands/implement.md`, `commands/infinite-development.md` — agent-level merges and prose naming squash.
- `plugins/workaholic/skills/workaholify/scripts/check-repo-settings.sh` — confirm `allow_merge_commit` is not disabled by the settings it applies (it is `true` on this repository today).
- `CLAUDE.md` (*Enforcement gates*: "Every merge is a squash"), `plugins/workaholic/rules/*.md` — the stated invariant.
- `scripts/test-workflow-scripts.mjs` — the suite pins the method word and refuses literal methods at call sites.

## Implementation Steps

1. Read the 2026-09-01 ruling in `merge-method.sh`'s header and every consumer listed in it; list each site that assumes squash (body composer, `content-reached-base.sh`, `claim-merged.sh`, `check-version-bump.sh`, `commit.sh`'s housekeeping marker comment).
2. Change `merge-method.sh` to print `merge`; rewrite its header to state the 2026-09-26 ruling (#1279), what it costs (branch-internal bookkeeping commits reach `main` as second-parent history) and how `--first-parent` keeps the trunk readable.
3. Keep `merge-commit-body.sh` feeding `commit_title`/`commit_message` for the merge commit, so the first-parent line is the unit's title rather than the forge's default `Merge pull request #N from ...`.
4. Update every prose surface stating "every merge is a squash" (CLAUDE.md, drive SKILL, routing, the command bodies) in the same change.
5. Update the suite's pins to the new word; keep the refusal of literal methods at call sites.
6. Run the local verification set and regenerate `outputs/` with `build.mjs`.

## Quality Gate

<!-- MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     Provisional until the mission is approved; the approval interrogation
     sharpens it. -->

**Acceptance criteria** — the checkable conditions that must hold:

- `merge-method.sh` prints `merge`, and every REST and agent-level merge site reads it (no literal method anywhere).
- A merge commit carries the composed title and body; `git log --first-parent` on a fixture shows one line per merged unit.
- No document still states that every merge is a squash.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` (updated pins pass).
- A hermetic fixture merge through `merge-pr.sh` against a fake REST endpoint shows `merge_method: merge` and the composed body in the request.
- `grep -rni "every merge is a squash" CLAUDE.md plugins/` returns nothing.

**Gate** — what must pass before approval:

- The local proof set (`branching/scripts/local-proof.sh`) answers `ok: true`.

## Considerations

- The squash ruling was the developer's own (2026-09-01); #1279 is the newer ruling by the same person and wins. The measured cost that motivated squash (bookkeeping commits on `main`) returns as second-parent history; that is the accepted cost, stated in the header rather than hidden.
- `superseded` stays tree-derived and needs no change; ancestry becomes an additional, stronger proof (the next ticket).
- Branches already squash-landed stay non-ancestors; history is not rewritten.
