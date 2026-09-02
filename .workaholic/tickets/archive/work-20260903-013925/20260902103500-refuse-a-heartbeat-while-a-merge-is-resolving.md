---
created_at: 2026-09-02T10:35:00+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission:
merge_policy:
verification_handoff:
---

# Refuse a heartbeat while a merge is resolving

## Overview

MINTED MID-RUN (2026-09-02, by the `/implement` tick driving
`adjust-the-plan-hourly-not-only-report-it`). `heartbeat.sh` writes an empty commit against a
scratch index. During an **unresolved merge** git does not write an empty commit: it writes the
**merge commit**, taking the second parent from `MERGE_HEAD` and the tree from the index it was
given — the scratch one, which holds the branch's own pre-merge tree. The result records the base
as a parent while carrying **none of the base's content**, and `git merge origin/main` is a no-op
ever after because the base is now an ancestor.

**Measured on `work-20260902-083726`**: a run resolving a four-file content conflict beat its
heartbeat between the resolution and the commit. Commit `4c7749ef` is titled `Refresh heartbeat`,
has `origin/main`'s tip as its second parent, and has an **empty diff against its first parent** —
so the branch claimed to have merged a base whose 97 changed files it had silently reverted. The
run noticed only because `git commit --no-edit` then failed with *"Aborting commit due to empty
commit message"*, `MERGE_HEAD` was gone, and `git merge-base --is-ancestor origin/main HEAD`
answered yes when it should not have. It was repaired forward — the resolved tree was committed as
an ordinary commit on top, rewriting nothing — but a run that had not looked would have pushed a
branch that reverts the base.

The two mechanisms are individually correct and collide by construction: the heartbeat is *step 0
of every ticket* and is deliberately cheap and unconditional, and catching a branch up with the
base is exactly what a driving run is told to do when its pull request conflicts.

## Policies

<!-- The standard engineering policies this implementation would answer to.
     MANDATORY and never empty - validate-ticket.sh rejects an empty section.
     List at least the universal implementation policies plus whatever the
     layer selects. -->

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions

## Key Files

- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — the empty commit and its scratch index; the one place that must refuse.
- `plugins/workaholic/skills/ship/scripts/catchup-main.sh` — the sanctioned merge engine, which leaves a conflicted tree for the caller to resolve.
- `plugins/workaholic/skills/drive/reference/claims.md` — where the heartbeat's contract is stated (`a failed beat is reported, never fatal`).
- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` §0 — *Beat the heartbeat*, which says nothing about a merge in progress.

## Implementation Steps

1. Reproduce it first, offline: in a throwaway repository, start a conflicting merge, run
   `heartbeat.sh`, and show that the resulting commit is a merge commit whose diff against its
   first parent is empty. A repair written without that fixture proves nothing.
2. **Refuse rather than repair.** `heartbeat.sh` returns a beat or a named refusal and a failed
   beat is already *reported, never fatal* — so the honest fix is a refusal word
   (`merge_in_progress`) when `MERGE_HEAD` exists, with **nothing written**. Making the heartbeat
   clever enough to write the *right* merge commit would give a liveness signal a second job.
3. Say it in the caller's terms too: a run resolving a conflict is between steps, so
   `reference/ticket-workflow.md` §0 should name the one moment the beat does not apply.
4. Consider whether the same hazard reaches `archive.sh`'s own push-and-beat seam and any other
   caller of `heartbeat.sh`; name what it found either way rather than fixing only the measured
   path.
5. Leave the branch's own history alone: this ticket is about preventing the next occurrence, not
   about rewriting the one that happened.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- With `MERGE_HEAD` present, `heartbeat.sh` writes no commit and reports `merge_in_progress` by
  name, at exit 0.
- With no merge in progress it is byte-identical to today.
- The refusal is reported by its caller and is not fatal, exactly as a failed beat already is.
- `reference/ticket-workflow.md` §0 names the case.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — a row that starts a conflicting merge in a throwaway
  repository, beats, and asserts no commit and the named refusal; and a row asserting the
  no-merge path is unchanged.

**Gate** — what must pass before approval:

- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `node scripts/test-workflow-scripts.mjs`

## Considerations

- **The window is small and the loss is total.** It needs a beat between `git merge` and the
  commit that resolves it, which is exactly the window a run spends resolving a content conflict —
  the longest part of a catch-up, and the part where a long-running run is most likely to beat.
- **Do not make the heartbeat resolve the merge.** The branch tip is the one liveness authority
  (`reference/claims.md`), and a liveness signal that also writes content is how a second
  authority is born.
- This ticket carries **no `mission:` and no `feedback:` refs** on purpose: it is about the claim
  protocol rather than about the planner the minting unit was building. The stated cost
  (`workaholic:drive`, the failure contract) is that its finish line will be unposted when it is
  driven, because no stem resolves a thread for it.
