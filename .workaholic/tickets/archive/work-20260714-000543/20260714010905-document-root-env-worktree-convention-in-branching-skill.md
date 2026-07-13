---
created_at: 2026-07-14T01:09:05+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort: 0.25h
commit_hash: ea09d21
category: Changed
depends_on:
---

# Document the root .env credential convention as AI-facing guidance in the branching skill

## Context

Development credentials live in ONE git-ignored `.env` at the repository
root (convention adopted 2026-07-13). The mechanics are already implemented
in scripts and are on `main`:

- `skills/branching/scripts/ensure-worktree.sh` COPIES the root `.env` into
  every new worktree (commit `8fba48f`, "Add root .env copy to the worktree
  creation protocol") — a copy, not a symlink, so worktrees diverge
  credentials independently; silently skipped when the root has no `.env`.
- In consuming repos, `serve-poc.sh` / `serve-guide.sh` source the root
  `.env` (caller env wins).

The gap: this convention exists ONLY as script behavior plus a script
comment. There is **no AI-facing guidance prose in any `SKILL.md`** — a
grep of `skills/branching/SKILL.md` for `.env`/credential returns nothing.
So an AI creating a branch/worktree, or working inside one, has no
skill-level statement of the convention and cannot infer:

1. the root `.env` is the SINGLE credential source (not per-package,
   not per-worktree-authored);
2. `create.sh` / `ensure-worktree.sh` already carry it into a NEW worktree;
3. a worktree that PREDATES the convention, or was created outside
   `ensure-worktree.sh`, needs a manual `cp <repo-root>/.env .env` before it
   can serve/authenticate.

The developer's intent (2026-07-14): the "a worktree needs the `.env`" fact
should live as **guidance to the AI in a skill**, not only inside a script —
so the AI knows to bring the `.env` along (or `cp` it into a pre-existing
worktree) as a matter of judgment, not only when it happens to call
`ensure-worktree.sh`.

## Policies

- `workaholic:implementation` / `objective-documentation` — state the
  convention as verifiable fact (which script copies it, where the file
  lives), not aspiration.
- `workaholic:design` / `self-explanatory-ui` — the convention must be
  discoverable from the skill without reading the shell script.

## Implementation Steps

1. Add a short **Credentials / root `.env`** guidance block to
   `plugins/workaholic/skills/branching/SKILL.md` stating: the root
   git-ignored `.env` is the single credential source; `create.sh` /
   `ensure-worktree.sh` copy it into new worktrees (a copy, so worktrees
   diverge independently; skipped when absent); and a worktree created
   before this convention or outside `ensure-worktree.sh` needs a manual
   `cp <repo-root>/.env .env`.
2. Cross-link from `skills/trip-protocol/SKILL.md` (its worktree-cleanup step
   already PRESERVES gitignored `.env`) so the create-side and cleanup-side
   guidance are symmetric and discoverable from either.
3. If the plugin build mirrors skills into `outputs/` (there are
   `outputs/workflows/skills/*/branching/scripts/ensure-worktree.sh` copies),
   regenerate `outputs/` (`node scripts/build-plugins/build.mjs` or the repo's
   canonical build) so the shipped copy carries the new prose.

## Quality Gate

- `skills/branching/SKILL.md` names the root `.env` convention and the
  manual-`cp` fallback for pre-existing worktrees, in prose an AI reads
  before acting.
- No script behavior changes (the copy already works on `main`); this is
  documentation only.
- If `outputs/` is regenerated, the plugin build/validation stays green.

## Considerations

- **Guidance only — do NOT change `ensure-worktree.sh`'s behavior.** The copy
  already landed on `main` via `8fba48f`; this ticket adds the AI-facing
  description the script alone does not provide.
- **Branch `work-20260713-144839` (local + `origin`) is now redundant** — its
  `.env`-copy change is already on `main` (`8fba48f`). It should be deleted,
  NOT shipped. (This supersedes the "ship the workaholic `.env` branch"
  follow-up carried in the plgg resume ticket
  `20260714004350-resume-poc-verdicts-and-workaholic-env-ship.md`.)

## Final Report

Development completed as planned. Added a "Credentials — root `.env`" guidance block to `branching/SKILL.md` (single credential source; `ensure-worktree.sh` copies it into new worktrees as a copy, skipped when absent; pre-existing/externally-created worktrees need a manual `cp <repo-root>/.env .env`) and a symmetric cross-link in `trip-protocol/SKILL.md`'s worktree gitignored-file handling. No script behavior changed; `build.mjs` yields no `outputs/` diff (branching `SKILL.md` is not mirrored) and `posix-lint` stays clean.
