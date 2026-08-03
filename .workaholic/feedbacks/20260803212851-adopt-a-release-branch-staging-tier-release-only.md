---
type: Feedback
title: Adopt a release-branch staging tier: release/* only
kind: insight
source: discussion
created_at: 2026-08-03T21:28:51+09:00
author: a@qmu.jp
supersedes: 
---

# Adopt a release-branch staging tier: release/* only

The branching model gains exactly one new tier, `release/*`, and nothing else. `main`
stays the default and production branch; the per-unit claim/branch/worktree/PR mechanics
are untouched. This record exists so the next session does not re-propose the shapes that
were rejected, and so the promotion step can be placed without re-reading `/ship` end to
end.

## Rejected alternatives

**Full Git Flow (`develop` + `release/*` + `hotfix/*`).** Rejected because `develop`
duplicates `main` for a fleet whose units already merge one at a time behind a pull
request: it would add a second base, and with it the two questions the original mission
draft could not answer — what a claim means against two bases, and what `merge_policy`
means under two merge targets. Both questions disappear by not creating the second base.
`hotfix/*` was rejected on the same ground: with `main` deployable at every commit, a
hotfix is an ordinary unit.

**A `develop`-only tier (an integration branch, no release branch).** Rejected because it
solves the wrong half. The ask was QA-before-production *and* a durable "what shipped,
when" record; an integration branch gives a staging area whose identity is continuous and
therefore has nothing to attach a record to. A release branch is a bounded, nameable thing
carrying a specific set of `main` commits, which is exactly what the record needs.

**Chosen: `release/*` only**, cut from `main` at promotion time, held open as the QA
window, and confirmed. The durable record attaches to the release branch itself.

## Survey of `/ship`'s flow, per step

What each step reads, writes, and the ordering constraint it imposes. The constraints are
the deliverable; the steps themselves are in `plugins/workaholic/skills/ship/SKILL.md`.

1. **`pre-check.sh <branch>`** — reads the branch's pull request; writes nothing. Must
   precede everything: with no PR there is nothing to ship. It reports `merged: true` for
   an already-merged PR, and that case is un-re-gateable — the confirmation-before-merge
   order cannot be applied retroactively.
2. **`catchup-main.sh <base>`** — reads `origin/<base>`; writes a merge commit onto the
   work branch. **Must precede any deploy step**, so that what is deployed equals what will
   merge. It folds in the version-collision guard: the branch's target version must exceed
   the base's, or a deploy-on-merge release is idempotent and silently ships nothing. A
   `mechanical` conflict is routine reconciliation; only a `content` conflict halts.
3. **`scan-branch-safety.sh | gate-decision.sh`** — reads `git diff <base>..HEAD`; writes
   nothing. Must run **after** catch-up (it has to scan the reconciled diff) and **before**
   the merge. `secret` is non-overridable; `size`/`leak` are a human ruling.
4. **`read-deployments.sh` / `find-claude-md.sh` / `check-confirmation-capability.sh`** —
   read `.workaholic/deployments/*.md` and `CLAUDE.md`; write nothing. The hard gate (no
   confirmation method means halt) is **pre-merge** by design, so an unconfirmable change
   is stopped before it reaches the base rather than discovered after.
5. **Executing the confirmation** — reads production; writes nothing. **Pre-merge.** A
   confirmation that ran and failed is a failed ship and is not bypassable; the unmerged
   branch is the rollback.
6. **`record-evidence.sh`, the release-note writer, `commit-release-note.sh`,
   `create-or-update.sh`** — append `## Deployment Evidence` to
   `.workaholic/stories/<branch>.md`, write `.workaholic/release-notes/<branch>.md`, and
   update the pull request body. Must run **after** the confirmation (the evidence is of a
   result) and **before** the merge (both artifacts have to ride into it). A failed push
   here is a pre-merge hard stop.
7. **`merge-pr.sh <pr>`** — writes the merge onto the base. **Last**, gated on a passing
   confirmation, and irreversible. Its exit status reflects the merge and only the merge;
   the post-merge base checkout is a reported field, never a gate.
8. **`publish-release.sh <branch> <merge-commit> <tag> <notes>`** — reads
   `.github/workflows/`; writes a GitHub Release **targeting a commit**. Post-merge, gated
   on a successful merge, and defers to CI when a release workflow exists.
9. **`extract-deferred-concerns.sh <branch> <pr> <url> <base>`** — reads the merged story's
   section 6; writes `kind: concern` feedback records **on the base**. Post-merge by
   construction (the story must be merged first), and publishes through a publish tree when
   the runner is not standing on the base.

## Where the cut fits, and why it is not a step of the per-unit ship

Three constraints from the survey place it.

- **It is structurally post-merge.** A release branch is cut *from `main`*, so it cannot
  exist before the units it carries have merged. Its phase is the same as steps 8-9.
- **It must not re-enter steps 4-6.** The per-unit confirmation is proof about one branch
  before it lands; the release confirmation is proof about a batch already on `main`. They
  have different subjects, so the promotion adds a second confirmation rather than
  deferring or weakening the first. Nothing about the unit merge waits for the promotion —
  inverting the evidence-before-merge rule is the one thing a promotion step must not do.
- **Publishing needs re-pointing, not replacing.** `publish-release.sh` already targets a
  commit, so a confirmed release branch's tip is simply what it targets. The tier removes
  nothing.

Therefore the promotion is a **separate, explicitly-invoked phase that runs over `main`**,
not a step inside the per-unit ship. If it were a step, every `auto` unit would cut a
release branch and per-unit behaviour would change observably — which this work puts out of
scope. Landing a unit on `main` stays exactly what it is today; promoting a batch of landed
units to production becomes a distinct, recorded event.
