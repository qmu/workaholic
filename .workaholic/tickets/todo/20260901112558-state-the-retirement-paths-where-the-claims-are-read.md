---
created_at: 2026-09-01T11:25:58+00:00
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
