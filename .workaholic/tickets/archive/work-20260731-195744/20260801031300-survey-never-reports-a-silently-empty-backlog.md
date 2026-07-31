---
created_at: 2026-08-01T03:13:00+09:00
author: a@qmu.jp
type: bugfix
layer: [Domain]
effort: 1h
commit_hash:
category: Changed
depends_on:
mission:
merge_policy: auto
claim: work-20260731-195744
---

# A survey that cannot resolve the developer reports an empty backlog instead of a failure

## Overview

`plan-units.sh` reads the developer's queue with
`for t in $(sh "${SCRIPT_DIR}/list-todo.sh" 2>/dev/null || true)`. `list-todo.sh`
resolves the queue directory through `user-slug.sh`, which **exits non-zero when
`git config user.email` is unset**. That exit is swallowed by the `|| true`: the
survey emits `backlog: []`, names nothing in `excluded[]`, and the run reports
"nothing claimable" and terminates **`ok`**.

Measured 2026-08-01 while designing an hourly unattended cloud runner. A fresh
cloud checkout starts with no configured git identity, so **every tick would
report a healthy, empty queue while the queue was full** — the masked failure
`workaholic:implementation` / `observability` exists to forbid, and the worst
shape an unattended tick can take: it is indistinguishable in the log from a
correct idle tick.

Nothing upstream catches it either. `/drive` step 0 (`sync-main.sh`) checks the
branch and the working tree but never the identity, and `plan-units.sh` reports
`current` for *freshness* only — there is no field that says "I could not read
the backlog at all".

The fix is to make the two states distinguishable: **an empty queue and an
unreadable queue must never render identically**.

## Policies

- `workaholic:implementation` / `policies/observability.md` — a run whose outcome cannot be grasped from outside is the defect; a swallowed exit that renders as a normal idle tick is exactly a masked failure.
- `workaholic:implementation` / `policies/command-scripts.md` — the survey's contract is its JSON; a new state gets a named key, not an inferred absence.
- `workaholic:implementation` / `policies/directory-structure.md` — conventional layout for the touched scripts.
- `workaholic:implementation` / `policies/coding-standards.md` — POSIX `#!/bin/sh -eu` house style (`rules/shell.md`); these scripts run on Alpine, never bash.
- `workaholic:development` / `policies/overnight-ai.md` — an unattended run's report is the only thing a developer reads afterwards; a confident wrong report is worse than a loud failure.

## Key Files

- `plugins/workaholic/skills/drive/scripts/plan-units.sh` - line 223 swallows the failure; owns the survey JSON contract this ticket extends
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` - must distinguish "no queue directory" from "cannot resolve the user"
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` - the canonical slug rule; its loud exit is correct and stays unchanged
- `plugins/workaholic/skills/drive/SKILL.md` - *Unified Run* §1 documents the survey contract and §7 the terminal token table
- `plugins/workaholic/commands/drive.md` - step 0/1 table of reported decisions
- `docs/drive-loop-runbook.md` - *Failure modes* table, where a runner operator looks first
- `scripts/test-workflow-scripts.mjs` - hermetic suite that builds throwaway repos

## Implementation Steps

1. Leave `user-slug.sh` as it is. Failing loudly on an unset identity is the correct behavior and is relied on elsewhere.
2. In `list-todo.sh`, separate the two outcomes: a missing `todo/<user>/` directory stays "exit 0, no output"; an **unresolvable identity** exits non-zero with a short reason on stderr. Do not print a JSON error to stdout — the script's contract is one path per line.
3. In `plan-units.sh`, stop discarding the status. Capture `list-todo.sh`'s exit code, and on failure add two things to the emitted object: a top-level `backlog_error: "<reason>"` (empty string when the read succeeded) and the resolved `user_slug` (empty when unresolvable), so a reader can see *whose* queue was surveyed.
4. Keep `backlog: []` in that case — the survey genuinely has no backlog to offer — but the accompanying `backlog_error` is what makes the emptiness honest.
5. In `commands/drive.md` and `drive/SKILL.md` §7, give `backlog_error` the same treatment `current: false` already has: **it forbids `ok`**. Add the row to the terminal-token table and the reported-decision table.
6. Add a `docs/drive-loop-runbook.md` *Failure modes* row: "every tick reports 0 units / `ok` but the queue is full" → the runner has no `git config user.email`, so `plan-units.sh` reports `backlog_error: identity_unresolved`.
7. Extend `scripts/test-workflow-scripts.mjs` with the assertions in the gate below.
8. Rebuild the cross-agent artifacts (`node scripts/build-plugins/build.mjs`) — the drive scripts ship into `outputs/workflows` and the `Outputs Freshness` CI workflow fails on any diff.

## Quality Gate

**Acceptance criteria**

- In a throwaway repository with `git config --unset user.email`, `plan-units.sh` exits 0 and emits a **non-empty** `backlog_error`; the JSON is distinguishable from the success case by that field alone.
- In a throwaway repository with an identity set and no `todo/<user>/` directory, `plan-units.sh` emits an **empty/absent** `backlog_error` and `backlog: []`.
- `plan-units.sh` emits the resolved `user_slug` in both success and failure shapes (empty string when unresolvable).
- `list-todo.sh` exits non-zero on an unresolvable identity and exits 0 with no output on a missing queue directory.
- `drive/SKILL.md` §7 and `commands/drive.md` both state that a non-empty `backlog_error` forbids `ok`, and `docs/drive-loop-runbook.md` carries the failure-mode row — all in the same commit as the code.
- `outputs/workflows` is regenerated and `node scripts/build-plugins/verify.mjs` passes.

**Verification method**

- `node scripts/test-workflow-scripts.mjs` is green, with new assertions covering each acceptance bullet above (the suite already creates throwaway repos, so unsetting the identity is a local operation with no effect on the working tree).
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs` — no `outputs/` diff remains uncommitted.
- `bash plugins/workaholic/hooks/layout-doctor.sh .` reports `conforming: true`.

**Gate**

- The suite is green, the build is clean, and the three documents tell the truth about the new field before the PR is opened.

Decided: hermetic suite only (`node scripts/test-workflow-scripts.mjs`) — the change is script-internal with no runtime surface, and the suite already builds throwaway repositories, so a live run would prove nothing extra (developer may override at /drive).

Decided: report the failure rather than fall back to scanning every user's `todo/` directory — a fallback would silently drive another developer's queue, which is a worse outcome than doing nothing (developer may override at /drive).

Decided: `backlog_error` is a top-level key rather than an `excluded[]` entry — `excluded[]` names artifacts the survey *saw and dropped*, and this condition is that the survey never learned any artifact exists, the same reason `current` is a property of the survey rather than of an item (developer may override at /drive).

## Considerations

- The survey is called from inside claim worktrees and must stay side-effect-free; adding a field is safe, resolving or repairing the identity here is not (`plugins/workaholic/skills/drive/scripts/plan-units.sh` header).
- Every consumer of the survey JSON must tolerate the new keys. `commands/drive.md` reads it as prose, so the risk is low, but check for any other reader before landing (`plugins/workaholic/skills/drive/`).
- This ticket does **not** give a runner an identity — that is environment provisioning, and the plugin cannot invent an email. It only guarantees the absence is reported rather than swallowed.
