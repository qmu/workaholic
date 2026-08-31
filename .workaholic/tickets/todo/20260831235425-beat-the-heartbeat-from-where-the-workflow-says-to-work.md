---
created_at: 2026-08-31T23:54:25+00:00
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: stop-two-runs-from-claiming-and-driving-one-unit
merge_policy:
verification_handoff: 
feedback: 20260830081659-stop-two-runs-from-claiming-and-driving-one-unit.md, 20260821162443-an-autonomous-improvement-loop-run-by-the-routines.md
---

# Beat the heartbeat from where the workflow says to work

## Overview

**The beat that was made step 0 to stop a takeover does not land from the directory the
workflow says to run it in.** `heartbeat.sh` derives the unit's worktree as
`$(git rev-parse --show-toplevel)/.worktrees/<unit>`. Run from the main checkout that
resolves; run from **inside the unit's own worktree** — where `git rev-parse --show-toplevel`
answers the worktree's own root — it resolves to
`.worktrees/<unit>/.worktrees/<unit>`, which never exists, so the script reports
`{"beat": false, "reason": "no_worktree"}` and exits 0.

`drive/SKILL.md` §4 opens *"Inside the worktree, order the queue"* and then makes the beat
**step 0 of every ticket**. So the documented calling context is exactly the one in which the
beat silently does nothing — and it is never load-bearing by design, so nothing anywhere
says it did nothing.

**Measured 2026-08-31T23:5x UTC**, unit `stop-two-runs-from-claiming-and-driving-one-unit`,
same unit and same minute, only the working directory differing:

```
# cwd = /home/user/workaholic/.worktrees/stop-two-runs-from-claiming-and-driving-one-unit
{"beat": false, "unit": "stop-two-runs-…", "branch": "", "reason": "no_worktree"}

# cwd = /home/user/workaholic
{"beat": true,  "unit": "stop-two-runs-…", "branch": "work-20260830-124234", "reason": ""}
```

**Why this is the costly one.** The beat was promoted from a cadence to step 0 on
2026-08-31 (ticket `20260831150500`) precisely because a unit that is one long ticket
otherwise runs its whole implementation on the claim commit's own timestamp and loses its
own claim to the 30-minute `WORKAHOLIC_CLAIM_HEARTBEAT_STALE_MINUTES` resume window.
Measured then, on `batch-20260831141002`: resumed by a second tick at 33 minutes, and a
complete, validated, locally-committed implementation was discarded. A run that discharges
step 0 from inside the worktree gets that same outcome back with the step visibly taken.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:implementation` / `policies/machine-checkable-domain-gaps.md` — make the gap fail early
- `workaholic:operation` / `policies/runtime-behavior.md` — the running loop keeps serving and recovering

## Key Files

- `plugins/workaholic/skills/drive/scripts/heartbeat.sh` — the `repo_root` derivation and the `no_worktree` report
- `plugins/workaholic/skills/drive/SKILL.md` §4 — *"Inside the worktree"* plus *"Beat the heartbeat as the first act of every ticket"*
- `plugins/workaholic/skills/drive/reference/ticket-workflow.md` — step 0, where the beat is discharged
- `scripts/test-workflow-scripts.mjs` — where a hermetic assertion on the two working directories belongs

## Implementation Steps

1. Reproduce before changing anything: create a repository with a claim worktree, run
   `heartbeat.sh <unit>` from the main checkout and from inside `.worktrees/<unit>/`, and
   confirm the second answers `no_worktree` while the first beats.
2. Resolve the **main checkout's** root rather than the current tree's before composing
   `worktree_path` — `git rev-parse --git-common-dir` names the shared git directory from
   either tree, and its parent is the main checkout — so the same unit id resolves to one
   worktree from anywhere inside the repository. Do not resolve the branch a second way:
   the script's own header rules out guessing which branch the unit is on, and that rule is
   the reason the path is derived from the unit id at all.
3. Keep the beat **from the unit's own worktree** and keep the header's reasoning intact —
   what moves is only how the worktree is located, never which tree the empty commit is
   pushed from.
4. Keep every existing refusal word and the never-load-bearing contract: a genuinely absent
   worktree still answers `no_worktree` with `beat: false` and exit 0, and no failure of this
   script may abort a run.
5. Assert both working directories in `scripts/test-workflow-scripts.mjs`, so the beat is
   proved from the directory §4 tells the run to stand in and not only from the one that
   happens to work.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- `heartbeat.sh <unit>` beats from inside `.worktrees/<unit>/` and from the main checkout, and
  both report the same `branch`.
- A unit with no worktree still answers `beat: false` / `no_worktree` / exit 0 from either
  directory.
- No refusal word is added or renamed, and the script still pushes from the unit's own worktree.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs` passes, with a row asserting the beat from both
  working directories.
- `sh scripts/e2e/loop-drill.sh verify-all` passes — no other drill's verdict moves.

**Gate** — what must pass before approval:

- The beat lands from where the workflow says to work, proved by a check that fails if the
  `repo_root` derivation regresses.

## Considerations

- The fix is a **path derivation**, not a new calling convention: telling drivers to `cd` to the
  main checkout for one step would put the correction in every caller instead of the one script,
  and `drive/SKILL.md` §4's *inside the worktree* framing is right for everything else in the step.
- `git rev-parse --git-common-dir` answers a relative path from some trees; resolve it to an
  absolute path before taking its parent.
- A worktree nested at an unexpected depth, or a `.worktrees/` directory relocated by a caller,
  is out of scope — the repository fixes `.worktrees/<unit-id>/` in `claims.md`.
- Adjacent but **not** this ticket: whether a `beat: false` should be surfaced more loudly in the
  run report. The never-load-bearing contract is deliberate and is not reopened here.
