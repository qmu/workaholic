---
created_at: 2026-08-01T11:02:46+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: auto
claim: work-20260801-110823
---

# A unit that finished and is waiting at its PR is resumed again every tick, forever

## Overview

Resumability shipped on 2026-08-01 (`20260801031301`) and the hourly cloud runner
started using it within the hour. Measured the same day, it does the wrong thing to a
unit that is **already done**:

`batch-20260731185901` drove its ticket, wrote its story, and opened PR #142, whose
ticket carries `merge_policy: review` — so the unit correctly **stopped at the PR** and
its branch correctly stayed unmerged, because a review unit is unfinished until a human
merges it. The claim therefore stays in flight, its branch tip stops advancing, and
after 30 minutes the heartbeat lapses. The scan then sees *same identity + lapsed
heartbeat* and reports `resumable: true`.

Observed on `work-20260731-185904`:

| Resume commit | Time (UTC) | What followed it |
| ------------- | ---------- | ---------------- |
| `e52c2d7e` | 21:57 | Real work — reconciled with `main`, queued a ticket, recorded a concern |
| `b4db9607` | 22:57 | **Nothing** |
| `d3cbe7df` | 00:58 | **Nothing** |

The same pattern on `batch-20260731220959` (`17064b5f`, `d62d63f6`). So after the first
pass every tick re-takes a finished unit, adds one empty `Resume` commit to a branch a
human is reviewing, consumes a PR-unit slot, and guarantees the run reports `pending`.
It does not terminate: a `review` unit can legitimately sit for days.

**The defect is that the resumability verdict has no notion of "done".** It answers
"is anyone working this?" when the question it must also answer is "is there anything
left to work on?". A review unit waiting at its PR looks identical to a run that died —
and the `handoff` boundary added in the same batch (`20260801031304`) drew exactly this
distinction for *unit outcomes* while the *resumability* verdict never learned it.

## Policies

- `workaholic:development` / `policies/parallel-long-running-agents.md` — a coordination protocol that re-takes finished work is not coordinating; the loop burns a unit slot per tick on a unit nobody can advance.
- `workaholic:implementation` / `policies/observability.md` — a run that reports `pending` forever, for a reason no output names, is the masked failure the terminal token exists to prevent.
- `workaholic:implementation` / `policies/command-scripts.md` — the verdict lives in `lib/claims.sh` and all three consumers read it; the fix belongs there, not in one caller.
- `workaholic:implementation` / `policies/directory-structure.md`, `policies/coding-standards.md` — layout and POSIX `#!/bin/sh -eu` house style.

## Key Files

- `plugins/workaholic/skills/drive/scripts/lib/claims.sh` - computes `resumable`/`resume_reason`; the drained-queue condition belongs here
- `plugins/workaholic/skills/drive/scripts/plan-units.sh` - emits `resumable[]` and the `claimed_resumable` exclusion reason
- `plugins/workaholic/skills/drive/scripts/claim.sh` - the `resume` path, which must refuse a drained unit
- `plugins/workaholic/skills/drive/SKILL.md` - *Claims* section states the two resumption conditions; a third one must be stated there
- `scripts/test-workflow-scripts.mjs` - `testClaimResume` / `testResumeRace` / `testHeartbeat` are the existing cases

## Implementation Steps

1. Add a **third** resumption condition to the shared scan: the unit must still have
   something to drive. A claim is resumable only when at least one of its claimed
   artifacts is still an **undriven ticket on that branch** — i.e. still under
   `.workaholic/tickets/todo/` at the branch tip. `archive.sh` renames a driven ticket
   into `archive/<branch>/`, and the reader already follows that rename, so the
   information is present without any new bookkeeping.
2. Keep it **purely git**. Do not reach for `gh pr view`: the reader must degrade
   offline (`lib/claims.sh` header), and an open-PR probe would put a network call in
   the one scan every consumer depends on. The tree at the branch tip answers the
   question locally.
3. Name the new state rather than folding it into an existing one. A claim that is
   lapsed, same-identity, and **drained** is not `claim_active` (nothing is running)
   and not `foreign_identity` — it deserves its own `resume_reason`, e.g.
   `queue_drained`, so an operator reading a cron log sees "finished, waiting on a
   human" instead of an unexplained absence.
4. `plan-units.sh` keeps excluding such a unit, with a reason that says the same thing
   (the current `claimed_resumable` must not be reported for it).
5. `claim.sh resume` refuses it with the matching reason, so the writer and the reader
   still agree.
6. Reconcile `drive/SKILL.md`'s *Claims* section — it currently states two conditions
   and must state three — and the `docs/drive-loop-runbook.md` failure-mode row.
7. Rebuild `outputs/` (`node scripts/build-plugins/build.mjs`).

## Quality Gate

**Acceptance criteria**

- A claim whose tickets are all archived on its branch is **never** offered as resumable, at any age, and `claim.sh resume` refuses it with a reason naming the drained queue.
- A claim with at least one ticket still in `todo/` on its branch is still offered once its heartbeat lapses — the recovery path from `20260801031301` keeps working.
- The three existing resumption cases stay green: fresh-heartbeat refusal, foreign-identity refusal, and worktree-at-branch-tip.
- `list-claims.sh` reports the new reason, so the state is readable without a survey.
- Driving a unit to its PR and then re-running the survey twice produces **no** second `Resume` commit on that branch.
- `drive/SKILL.md` and `docs/drive-loop-runbook.md` describe three conditions, in the same commit.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` green, with a new hermetic case that claims a batch, archives its ticket, lapses the heartbeat, and asserts the unit is **not** resumable and that `claim.sh resume` refuses — plus the existing cases unchanged.
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` with no residual `outputs/` diff.

**Gate**

- The suite is green including the drained-queue refusal. Without it the loop keeps adding empty commits to branches under human review, which is worse than the stall resumability was built to fix.

Decided: a drained-queue test rather than an open-PR probe — the scan must stay offline-capable and free of `gh`, and the branch tree answers the question locally (developer may override at /drive).

Decided: a distinct `resume_reason` rather than reusing `claim_active` — "nothing is running" and "nothing is left to run" call for different operator responses, and the reason vocabulary is read straight out of cron logs (developer may override at /drive).

## Considerations

- The empty `Resume` commits already on `work-20260731-185904` and `work-20260731-221002` are harmless but visible in PR #142's commit list; they need no cleanup, and force-pushing a branch under review to remove them would be worse than leaving them (`plugins/workaholic/skills/drive/scripts/claim.sh`).
- This is the second defect in the same verdict within a day (the first was the empty-field TSV collapse). Both were invisible without a targeted assertion, which argues for asserting the *shape* of every scan row and the *set* of offered units, not just individual fields (`plugins/workaholic/skills/drive/scripts/lib/claims.sh`).
- A blocked ticket that stays in `todo/` keeps its unit permanently non-drained, so it will remain resumable forever by this rule. That is correct as far as this ticket goes — the real answer there is the icebox, which is a developer act — but it means the two problems must not be conflated when reading a cron log (`plugins/workaholic/skills/drive/scripts/list-icebox.sh`).

## Final Report

Development completed as planned. The resumability verdict gained a third condition and
a `queue_drained` reason; the survey reports such a unit as `claimed_reported`.

### Discovered Insights

- **Insight**: The two coordinate spaces the scan already juggles turned out to be
  exactly what this needed. The row *reports* base-side artifact paths (the space both
  consumers compare in), but "is this ticket still undriven?" is only answerable at the
  **tip**, because driving a ticket *is* a rename out of `todo/`. Keeping the tip-side
  paths alongside the reported ones made the check three lines instead of a second
  rename walk.
  **Context**: The rename-following added on 2026-07-30 already computed the mapping;
  this change just stopped throwing half of it away.

- **Insight**: A batch and a mission answer "what is left to drive" from opposite
  directions, and no single path test covers both. A batch claims its *tickets*, so the
  question is whether any artifact is still under `todo/`. A mission claims only
  `mission.md`, which never lives there, so the question inverts: does any ticket at the
  tip still *name* the mission. Writing one rule for both would have silently declared
  every mission unit drained — the exact opposite failure, and a worse one, since it
  would disable recovery rather than over-trigger it.
  **Context**: `queue-size.sh` asks the mission half of this against the working tree;
  this asks it against the branch, which is what keeps the verdict offline-capable.

- **Insight**: `claimed_active` was the tempting place to fold the new state, and it
  would have been wrong in the way that matters to an operator reading a cron log:
  it says "a run is on it, wait", about a unit no run will ever touch again. The two
  states call for opposite responses — wait versus go review the PR — so they get
  different words.
  **Context**: This is the second time the reason vocabulary has been split for this
  reason (`claimed` → three names, now four). The pattern holds: a reason is worth its
  own word exactly when it implies a different next action.
