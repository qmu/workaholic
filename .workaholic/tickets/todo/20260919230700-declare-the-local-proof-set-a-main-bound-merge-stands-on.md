---
created_at: 2026-09-19T23:07:00+09:00
author: a@qmu.jp
assignees: []
depends_on:
mission:
merge_policy:
verification_handoff:
feedback: [https://github.com/qmu/workaholic/issues/1248]
claim: work-20260919-231306
---

# Declare the local proof set a main-bound merge stands on

## Overview

A pull request based on `main` is merged without its check runs ever being read. `branching/scripts/merge-gate-policy.sh` answers `remote_checks_required: false` for `main`/`master`, and `drive/scripts/branch-checks.sh` lines 92-97 return `pass development_main_local_proof` **before** it reaches `read-base-checks.sh`.

**That design is not what this ticket changes.** *`main` is the continuously auto-merged development branch and quality is gated at the `release/*` QA window* is a recorded decision (`CLAUDE.md`, *The release tier*), and `merge-gate-policy.sh`'s `release/*` arm keeps the full remote gate. Restoring the remote-CI gate for `main` is explicitly **out of scope** and must not be proposed as the repair.

The defect is in the substitute. The word `development_main_local_proof` asserts that a local proof stood in for the remote one, and **nothing anywhere establishes that any such proof ran, still less which one**. `CLAUDE.md`'s *Local Verification* section names six commands in prose, read by a human; the two places in the tree that actually run checks before a push each hard-code their own list of **three**:

- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh:404` — `build-plugins/verify.mjs`, `build-plugins/validate-metadata.mjs`, `test-workflow-scripts.mjs`
- `plugins/workaholic/skills/branching/scripts/prepare-publication.sh:226` — the same three, spelled a second time

Neither runs `node --test scripts/tests/agentic-loop/*.test.mjs`, `bash plugins/workaholic/hooks/layout-doctor.sh .`, or any part of `scripts/e2e/loop-drill.sh`. The set is spelled twice, is a strict subset of what CI's `validate` job runs, and no report names which of it a given unit executed.

**Measured, 2026-09-19** (workflow `Validate Plugins`, id 223779125, read over REST): six consecutive first-parent commits on `main` failed it — `f195a667f`, `915e115fd`, `6dcf73b41`, `d28e34429`, `52964b8c8`, `eb795c92f`, `3243c1c4f` — from 10:10:40Z to 11:45:28Z. The failing step on both ends of that range is job `validate`, step 9, **"Test agentic loop contracts and consumers"** — exactly the command neither fast-check set runs. Throughout that window `read-base-checks.sh` answered `unanswerable` for anything reading the base, so post-merge detection, the thing the release-tier decision leans on, did not fire either.

So the repair is to make the substitute a declared, single-spelled, reported thing: one list, one runner, and a run report that names what ran and what did not. A check that did not run is its own state and never a soft pass — the same rule `workaholic:ship` already holds for a deployment (*A failed or pending deployment is its own state*).

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — conventional project layout (all code work)
- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions (all code work)
- `workaholic:implementation` / `policies/command-scripts.md` — the change adds a POSIX `sh` script that owns a list two other scripts currently spell
- `workaholic:implementation` / `policies/test.md` — what the local proof set is, and why a subset of CI is not a proof
- `workaholic:implementation` / `policies/observability.md` — `not_run` is a reported state, never an absence
- `workaholic:operation` / `policies/ci-cd.md` — the relationship between what runs locally before a push and what CI runs after it

## Key Files

- `plugins/workaholic/skills/drive/scripts/branch-checks.sh` lines 88-97 — where the local-proof pass is emitted. **Do not change the gate's direction here**; it is the consumer that must be able to say what the proof was.
- `plugins/workaholic/skills/branching/scripts/merge-gate-policy.sh` — the one derivation of `remote_checks_required`. Unchanged by this ticket.
- `plugins/workaholic/skills/drive/scripts/catch-up-claim.sh` lines 372-415 — the first hard-coded set, with the two rulings that must survive: the checks run in a **clean environment** (the claim tunables unset) and their **output is kept to a log file** whose path rides the refusal.
- `plugins/workaholic/skills/branching/scripts/prepare-publication.sh` lines 222-233 — the second copy of the same list, which keeps neither of those two rulings.
- `.github/workflows/validate-plugins.yml` — the `validate` job whose steps the local set is measured against.
- `.github/workflows/loop-drills.yml` — the hermetic drill set CI runs on push.
- `CLAUDE.md`, *Local Verification* — the prose list that becomes a declaration.

## Related History

The check gate itself was added 2026-09-03 for the inverse defect — merging while a branch's own checks were still running or red (PR #957 merged three and a half minutes before its `Loop Drills` run completed, red; `main` carried it for four hours). `branch-checks.sh`'s own header records that measurement. The `main` arm that this ticket is about was carved out afterwards, and the substitute it assumes was never given a definition.

## Implementation Steps

1. Reproduce the gap before repairing it: run `merge-gate-policy.sh main` and `branch-checks.sh <pr>` against an open pull request based on `main` and record that the pass is emitted with `state: development` and no check run read; then diff the two hard-coded lists against `validate-plugins.yml`'s `validate` job and `loop-drills.yml`'s hermetic set, and record the difference (`workaholic:discover`, *Diagnosis-First Rule*).
2. Add `plugins/workaholic/skills/branching/scripts/local-proof.sh` as the **one** declaration of the set and the one runner of it. Each entry names the command, whether it is required, and its own refusal word. The set is the `validate` job's checks plus the hermetic drill entry point — decided, with its cost stated below — and it is spelled here and nowhere else.
3. Emit one JSON line: per check `{name, ran, ok, seconds, log}`, plus `complete` (every required check ran) and `ok`. A check that could not be run is `ran: false` with its own reason and never folds into a pass; a set that could not be read answers `readable: false` with **null** counts, never an empty array.
4. Carry both of `catch-up-claim.sh`'s rulings into the runner rather than leaving them at one call site: unset `WORKAHOLIC_CLAIM_STALE_HOURS`, `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` and `WORKAHOLIC_CLAIM_MERGED_LOOKUP` for the duration, and keep each check's output in a log file whose path rides the result.
5. Compose the runner at both existing sites, deleting both hard-coded lists. Every existing refusal word (`validation_failed:<check>`) keeps its exact spelling, so no caller's `case` arm moves.
6. Make the proof **reported**: the unit's run report and pull-request body name the checks that ran, their outcomes, and every `not_run` by name. A report that names no local proof is non-conformant on its face, in the same wording the destination report contract already uses. State the wording once and cite it.
7. Pin the set against CI: a row in `scripts/test-workflow-scripts.mjs` that reads the `validate` job's `run:` steps out of `.github/workflows/validate-plugins.yml` and fails when a step it names is absent from the declaration. The row names what it cannot see — a step whose command is built by interpolation.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `local-proof.sh` is the only place in `plugins/` naming `build-plugins/verify.mjs`, `build-plugins/validate-metadata.mjs` or `test-workflow-scripts.mjs` as a check to run (`grep` proves it; the two former lists are gone).
- Its declared set covers every `run:` step of `validate-plugins.yml`'s `validate` job that is a repository command, including `node --test scripts/tests/agentic-loop/*.test.mjs` and `layout-doctor.sh`.
- A check made to fail (temporarily shadowed) produces `ok: false` for that entry, `complete: true`, and the caller's byte-identical `validation_failed:<check>` refusal with nothing pushed.
- A check whose command is unavailable (`node` shadowed away) produces `ran: false` with its own reason — never `ok: true`, and never a silent skip.
- `branch-checks.sh`, `merge-gate-policy.sh` and every `release/*` behaviour are byte-identical: a `release/*`-based pull request still reads its remote checks and still refuses `checks_red` / `checks_pending`.
- The new test row fails when a step is deleted from the declaration while remaining in `validate-plugins.yml` (proved by making that edit and observing the failure, then reverting).

**Verification method** — the commands/tests/probes that prove them:

- `sh plugins/workaholic/skills/branching/scripts/local-proof.sh` from a clean checkout — the full set green, output pasted into the change's `verify`.
- The three negative probes above (shadowed check, shadowed `node`, deleted declaration row), each run in-session with its output recorded.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`.
- `node scripts/test-workflow-scripts.mjs`.
- `node --test scripts/tests/agentic-loop/*.test.mjs`.
- `bash plugins/workaholic/hooks/layout-doctor.sh .`.
- `sh scripts/e2e/loop-drill.sh verify-all`.

**Gate** — what must pass before approval:

- The full declared set green on the branch; the `Validate Plugins` run on the branch's own head green; the pull-request body naming every check that ran and every `not_run`.

## Considerations

- **Stated cost of including the agentic-loop suite in the pre-push set**: CI bounds it at five minutes (`timeout --signal=TERM --kill-after=30s 5m`), and `catch-up-claim.sh`'s own header records that several loop runners share one machine, so a check can lose to load in a way no single-session premise shows. The set carries the same timeout CI uses, and a timeout is a `ran: false` reason of its own rather than a failure — the kept log is what makes the next occurrence readable. Excluding it was rejected: it is the exact step whose absence turned `main` red six times in ninety-five minutes.
- Only the **hermetic** part of `loop-drill.sh` belongs in the pre-push set, matching what `loop-drills.yml` runs on push; the classified set (`verify-all`) stays a pre-approval gate and is named as such in the Quality Gate above, not in the declaration.
- `prepare-publication.sh` currently discards its checks' output (`>/dev/null 2>&1`, line 231). Composing the runner fixes that as a side effect; say so in the change rather than letting it read as an unrelated edit.
- This ticket adds no network read and no gate to the merge path. `branch-checks.sh` still emits the same pass for `main`; what changes is that the proof it names is now something a reader can ask about (`plugins/workaholic/skills/drive/scripts/branch-checks.sh` lines 88-97).
