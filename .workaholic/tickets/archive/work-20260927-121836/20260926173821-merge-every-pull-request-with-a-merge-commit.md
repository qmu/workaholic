---
created_at: 2026-09-26T17:38:21+09:00
status: done
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

## Final Report

Development completed as planned. `merge-method.sh` answers `merge`; every REST call site and both agent-level merges already read it, and `merge-commit-body.sh` keeps composing the merge commit's title and body so `git log --first-parent main` reads one line per unit. The prose stating "every merge is a squash" (CLAUDE.md, drive SKILL/routing, implement command, commit skill, ship/moderate script comments) now states the merge-commit ruling and its cost.

### Discovered Insights

- **Insight**: `attribute-base-red.sh` walked every reachable commit of the base, which only equalled "one commit per pull request" under squash; it now walks `--first-parent`, so the bound is spent on the merge commits the base's checks actually ran on.
  **Context**: any per-commit reader over `main` must pick the first-parent line once merge commits land; the branch-internal commits have no base check runs.
- **Insight**: the repository already allows merge commits (`allow_merge_commit: true`), and `check-repo-settings.sh` deliberately touches no merge-method setting, so no settings change was needed.
  **Context**: the method is a per-call REST field, not a repository setting.

## Archive delivery evidence

Implementation archived; delivery is pending verification. This is not a landed claim.

Pre-archive head: `af4bcec33aa42ef1bfd6b217b5703f9a5101f88b`; observed base: `cef35848fa1d171699fb8d1812c1471a47222d3f`.

Committed-tree assessment (does not cover uncommitted implementation):

```json
{"branch":"work-20260927-121836","head":"af4bcec33aa42ef1bfd6b217b5703f9a5101f88b","base":"cef35848fa1d171699fb8d1812c1471a47222d3f","state":"landed","reason":"tree_effect_present","tree":"f16783562f781a56d430dbbfa9b16976375a452a","paths":[],"delivery_claim":"assessment_only_not_a_retirement_proof"}
```

Worktree/index paths at archival (including expected implementation):

```text
 D .workaholic/tickets/todo/20260926173821-merge-every-pull-request-with-a-merge-commit.md
 M CLAUDE.md
 M docs/agentic-loop-redesign.md
 M plugins/workaholic/commands/implement.md
 M plugins/workaholic/skills/branching/scripts/reap-worktrees.sh
 M plugins/workaholic/skills/commit/SKILL.md
 M plugins/workaholic/skills/commit/scripts/commit.sh
 M plugins/workaholic/skills/drive/SKILL.md
 M plugins/workaholic/skills/drive/reference/routing.md
 M plugins/workaholic/skills/drive/scripts/attribute-base-red.sh
 M plugins/workaholic/skills/gather/scripts/merge-commit-body.sh
 M plugins/workaholic/skills/gather/scripts/merge-method.sh
 M plugins/workaholic/skills/moderate/scripts/persist-log.sh
 M plugins/workaholic/skills/ship/scripts/extract-deferred-concerns.sh
 M plugins/workaholic/skills/ship/scripts/merge-pr.sh
 M scripts/test-workflow-scripts.mjs
 M scripts/tests/agentic-loop/delivery-report.test.mjs
?? .workaholic/tickets/archive/work-20260927-121836/
?? plugins/workaholic/skills/branching/scripts/prune-landed-branches.sh
```
