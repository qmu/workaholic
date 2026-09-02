---
created_at: 2026-09-01T11:25:58+00:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on: 20260901112558-read-a-claim-branch-s-pull-request-state.md
mission: leave-only-live-work-in-the-unmerged-branch-list
merge_policy:
verification_handoff: 
---

# Name a merged branch as a retirement candidate

## Overview

PROPOSED. Seventeen of the thirty unmerged branches have a **merged** pull request. Squash-merge
means such a branch is never an ancestor of the base, so `--no-merged` lists it forever, and
`delete_branch_on_merge` — the only cleanup — is forward-only, so every branch merged before the
setting was applied stands permanently. Two weeks in, the "ready-to-run deletion command" the
`/workaholify` step prints is 17 lines long and nobody has run it.

A merged pull request is a **proof** in this repository's own sense: the tree established it and
looking again cannot make it false. So this is its own candidate reading beside `superseded_only`,
carrying its own word, feeding the CI act that already exists.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` / `policies/observability.md` — a degraded scan yields no candidates and its reason

## Key Files

- `plugins/workaholic/skills/drive/scripts/list-retirable-claims.sh` — the candidate reader this
  extends. Its header states the two rules that must survive: it is not a second oracle, and a
  degraded read yields no candidates **and its reason**, never a bare empty set.
- `plugins/workaholic/skills/drive/scripts/branch-pull-request-state.sh` — the previous ticket's
  reader, the only source of the `merged` fact.
- `plugins/workaholic/skills/drive/reference/claims.md` — where every word a claim script emits is
  classified proof or judgement, and where this candidate's word must be registered.
- `.github/workflows/claim-retirement.yml` — the executor; it owns no proof logic and should need
  no change beyond what the candidate list already feeds it.

## Implementation Steps

1. Extend `list-retirable-claims.sh` with a second candidate class: a `work-*` branch the oracle
   holds **no live row** for, whose pull request `branch-pull-request-state.sh` reads as `merged`.
   Carry a `candidate_reason` on every row (`superseded_only` | `pull_request_merged`) so the
   existing class is still told apart at a glance and no caller loses information.
2. Keep the live-row rule the library's, not a copy: resolve through `claims_unit_resolution`
   exactly as the existing class does. **A unit with any live row is never a candidate**, whatever
   its pull request says — a run may be driving a fresh claim over a merged predecessor.
3. Keep the degradation rule: a scan that could not reach the remote, or a pull-request read that
   answered `ok: false`, contributes **no candidate and its reason**. An unreadable pull request is
   not a merged one.
4. Register `pull_request_merged` in `drive/reference/claims.md` as a **proof**, with the argument
   written out: a merged pull request is a reading the tree established and cannot un-establish,
   which is the same standing `superseded` has and the reason a destructive act may rest on it.
5. State in `CLAUDE.md` that the forward-only cost of `delete_branch_on_merge` now has a
   backward-looking repair, and that the printed deletion command is no longer the only one.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- A `work-*` branch with a merged pull request and no live claim row appears as a candidate
  carrying `candidate_reason: pull_request_merged`.
- A branch with a live row never appears, whatever its pull request state.
- An unreadable pull-request read yields no candidate and names its reason.
- Existing `superseded_only` candidates are byte-identical apart from the added field.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` — hermetic rows for each of the four cases above.
- Diff the candidate output for a fixture with no merged branches against the pre-change output.

**Gate** — what must pass before approval:

- `node scripts/test-workflow-scripts.mjs` passes, including the claims-vocabulary assertions that
  fail on a word no table classifies.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` clean.

## Considerations

- The bounds live on the act, not here: `delete-retired-claim-branch.sh` already refuses
  `pull_request_open`, `not_on_base`, `not_a_work_branch` and `release_branch`, and the next ticket
  re-derives this candidate's own proof at the moment of the act.
- Deliberately **not** done: widening `superseded`. The ask says so explicitly, and the emptiness
  proof that verdict now carries is what makes `stranded` meaningful — a merged branch that still
  holds unlanded work is a real shape and must not be swept into the same word.

## Final Report

Development completed as planned.

`list-retirable-claims.sh` now answers **two** candidate classes and carries
`candidate_reason` on every row (`superseded_only` | `pull_request_merged`), so the original
class is told apart at a glance and no caller loses information. The second class is
enumerated from the **refs** rather than from the oracle's rows — a publish-tree publication
carries no claim commit, which is precisely why `superseded` never reached the 17 branches the
ask measured — filtered to the `work-YYYYMMDD-HHMMSS` pattern, and skipped for any branch the
first class already named, so no branch is read twice.

The live-row rule stays the library's: `claims_unit_resolution` is called over the same TSV
projection the existing class uses, and `live` / `single` / `ambiguous` all skip. An
`ok: false` from `branch-pull-request-state.sh` yields no candidate and lands in a new
`pull_request_unreadable[]` with its reason — an unreadable pull request is not a merged one,
and a bare omission would read exactly like a branch whose pull request is open.

`drive/reference/claims.md` gains *What made a branch a retirement candidate
(`candidate_reason`)* as a third keyed sub-table, both words classified **proof**, with the
argument written out and the explicit note that `superseded` was **not** widened — the
emptiness proof it now carries is what makes `stranded` meaningful. `CLAUDE.md`'s
`delete_branch_on_merge` bullet says the forward-only cost now has a backward-looking repair.
`.github/workflows/claim-retirement.yml` needed no change: it owns no proof logic and consumes
the candidate list it is handed.

**A pre-existing suite failure was found and is not this ticket's.** `node
scripts/test-workflow-scripts.mjs` fails the assertion `a subject no step raised reads
settled` at some hours and passes at others: `question-liveness.sh` answers `settled` only for
a step that reported `ok`, and `step-human-checkin.sh` reports `skipped`/`quiet_hours` inside
the speaking window. Measured against **an untouched `origin/main` checkout** at 13:20 UTC —
`5841 passed, 1 failed`, the same row — so it is not a regression from this change. Minted as
`20260901132500-make-the-liveness-row-independent-of-the-clock.md` and the run continued.

### Discovered Insights

- **Insight**: the candidate reader had to stop being driven by the oracle's rows and start
  being driven by the refs, and that is the whole reason the second class needed writing at
  all.
  **Context**: every existing claim reading starts from a `Claim …` commit, so a branch with
  none is invisible to all of them by construction — which is exactly the 17-branch population.
  A later reader tempted to "just widen `superseded`" should notice it cannot: that verdict is
  keyed on a unit, and these branches have none.
- **Insight**: `candidate_reason` is a third keyed vocabulary rather than a value inside an
  existing one, and the repository's own rule is why.
  **Context**: `claims.md` states that one column cannot classify two different questions. *Is
  this unit in flight* and *which proof put this branch on the delete list* are two questions,
  so they get two tables — and the second enters no precedence.
