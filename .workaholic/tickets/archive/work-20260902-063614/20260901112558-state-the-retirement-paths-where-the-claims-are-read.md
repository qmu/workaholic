---
created_at: 2026-09-01T11:25:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260901112558-drill-the-two-retirement-candidate-readings-offline.md
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# State the retirement paths where the claims are read

## Overview

PROPOSED. `CLAUDE.md` currently states the forward-only cost of `delete_branch_on_merge` and that
standing branches are *"reported with a ready-to-run deletion command and never deleted by the
command"* — after this mission that is no longer the whole truth, and outdated documentation is a
defect in this repository, not a follow-up. Three surfaces describe the retirement and each must
say what the mechanism now does.

## Policies

- `workaholic:implementation` / `policies/documentation.md` — the docs move with the change
- `workaholic:operation` / `policies/observability.md` — a stated cost stays stated

## Key Files

- `plugins/workaholic/skills/drive/reference/claims.md` — the one home for every word a claim
  script emits, keyed on the word, with each row called a proof or a judgement.
- `CLAUDE.md` — *The three acts on a claim* (the retirement paragraph) and the `/workaholify` §2
  paragraph carrying the forward-only cost.
- `plugins/workaholic/skills/drive/SKILL.md` — the Claims section.
- `docs/drive-loop-runbook.md` — the operator procedure for the CI retirement.
- `plugins/workaholic/skills/workaholify/scripts/check-repo-settings.sh` — whose printed deletion
  command is the sentence this change makes partly obsolete.

## Implementation Steps

1. In `drive/reference/claims.md`, state the three candidate classes together and what makes each
   one safe — emptiness for `superseded`, the tree for `pull_request_merged`, a person's recorded
   decision plus the emptiness term for `pull_request_closed_unmerged` — with the act's refusal
   words listed under each. Keep the proof/judgement classification explicit; the suite fails on a
   row that miscalls one.
2. In `CLAUDE.md`'s retirement paragraph, name the two new candidate readings and the act's new
   refusal words, and **amend the forward-only sentence**: the printed deletion command is now the
   recovery path for branches CI cannot take, not the only route.
3. In `/workaholify` §2's paragraph, keep the measured numbers and add what changed — that the
   backlog those numbers describe now drains through CI.
4. In `docs/drive-loop-runbook.md`, add the operator procedure: how to read the CI record for each
   class, and what each refusal word asks the operator to do.
5. Re-measure and state the outcome: run the branch count again after CI has taken a turn, and put
   the before/after in the mission's story. The ask opened with a measurement; the close should
   answer it with one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- All three candidate classes and every new refusal word appear in `claims.md`, each classified.
- `CLAUDE.md`'s forward-only sentence no longer states the printed command is the only cleanup.
- The runbook names one operator action per refusal word.
- The mission's story carries a before/after branch count.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — fails when a table classifies a word nothing emits, or
  a script emits a word no table classifies, which is what proves the documentation matches.
- `git branch -r --no-merged origin/main | wc -l` before and after.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- The re-measurement in step 5 is the only step here that depends on CI having run, so it may land
  a turn later than the rest of the ticket. Write the section with the before figure and the
  procedure, and fill the after figure when the workflow's next scheduled run has taken a turn.
- Nothing here changes behaviour. If a sentence cannot be written truthfully, that is a defect in
  the preceding tickets and belongs back there, not softened here.

## Final Report

Development completed as planned. Step 5's re-measurement did **not** have to wait a turn: CI had
already taken its turns overnight, so the after figure is real rather than a procedure.

### The re-measurement, before and after

| | `git branch -r --no-merged origin/main` | dead |
| - | --- | --- |
| 2026-09-01, when the ask was written | **30** | 22 — 17 with a merged pull request, 5 closed unmerged |
| 2026-09-02, after `claim-retirement.yml` had run | **7** | 1 |

The seven that remain are each alive or exempt by design: one fresh `closed_unmerged` candidate
(`work-20260902-033446`, which the next turn takes), two open pull requests
(`work-20260902-042305`, `work-20260902-043932`), two live claims, and the tick log's own two refs
(`workaholic-log` and the legacy `workaholic/moderation-log`), which match neither `work-*` nor
`release/*` and are invisible to the claim scan on purpose.

### Discovered Insights

- **Insight**: The sentence this ticket exists to amend had become false in two places, not one.
  `/workaholify` §2's *"the branches already standing … stay"* and `check-repo-settings.sh`'s own
  header both asserted that the printed deletion command is the only cleanup; both are now written
  as *this command leaves them alone, and CI drains the backlog independently*.
  **Context**: The behaviour statement lives in the script header as well as in `CLAUDE.md` and the
  skill, so amending only the two documents would have left the code's own header contradicting
  them — which is the shape this repository calls a defect rather than a follow-up.
- **Insight**: The proof/judgement home's own counts had drifted. `claims.md` called
  `candidate_reason` *"a third keyed vocabulary in this home"* while `CLAUDE.md` counted *"six
  further vocabularies"* plus *"a seventh"* and named neither of them that one.
  **Context**: The suite pins that every emitted word is classified and every classified word is
  emitted — it cannot see a wrong count. The counts are now `seven further` (one of which,
  `candidate_reason`, holds three proofs) and `an eighth` for the age table, and `claims.md` says
  *another* rather than a number it cannot keep.
- **Insight**: The emptiness reading is **evidence on the candidate row and a gate in the act**,
  and only on the closed-unmerged class.
  **Context**: That asymmetry is the whole reason `pull_request_closed_unmerged` is safe: the row
  records `branch_empty` three-valued so CI's own record can answer *how often does a hand-closed
  branch still hold work* from real data, while the act fails closed on an `unanswerable` — the
  direction issue #788 turned `superseded`. Documenting one without the other would read as a
  contradiction.
