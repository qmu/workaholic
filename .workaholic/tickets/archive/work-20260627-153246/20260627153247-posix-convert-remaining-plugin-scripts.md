---
created_at: 2026-06-27T15:32:47+09:00
author: a@qmu.jp
type: refactoring
layer: [Config, Infrastructure]
effort: 2h
commit_hash: 47ffe01
category: Changed
depends_on:
---

# Convert the remaining ~30 bash plugin scripts to POSIX sh (skills + the other hook)

## Overview

After the `validate-ticket.sh` outlier (`20260627153246`), **30 more scripts** under
`plugins/workaholic/` still violate `rules/shell.md` with `#!/bin/bash` (or one
`#!/usr/bin/env bash`). This ticket converts all of them to `#!/bin/sh -eu` pure POSIX so
the whole plugin honors the Alpine/no-bash standard. The distribution is bimodal — roughly
**17 scripts have zero bashisms** (a pure shebang swap) and the rest carry a handful each —
so the work is mechanical but broad. Two distinct verification profiles apply:

- **Shipped scripts (21):** part of the `create-ticket`/`drive`/`report`/`ship` closures that
  `build.mjs` copies verbatim into `outputs/workflows/`. `build.mjs` does **not** rewrite
  shebangs, so converting the source and running the **argument-less** `node
  scripts/build-plugins/build.mjs` flips the generated copies to POSIX automatically.
  These **require** an `outputs/` rebuild committed in lockstep or the Outputs Freshness CI fails.
- **Claude-only scripts (9):** `hooks/policy-lens.sh`, the 7 `trip-protocol/scripts/*` (trip is
  excluded from the build — Agent Teams, Claude-only), and `validate-writer-output/scripts/validate.sh`.
  Converted in place, **no** `outputs/` footprint.

This is re-enforcement of the existing `rules/shell.md`, regressed since the plugin merge.
`validate-ticket.sh` is intentionally **out of scope** (its own ticket) to keep that risky
rewrite reviewable.

## Policies

The standard engineering policies that govern this ticket. The implementing session **MUST**
read each linked policy hard copy before writing code and keep every change defensible against
that policy's Goal (目標), Responsibility (責務), and Practices (実践).

- `workaholic:implementation` / `policies/directory-structure.md` — keep every script's path and name unchanged; only the shebang/body changes (applies to all code work).
- `workaholic:implementation` / `policies/coding-standards.md` — fail-fast, declarative, no silent fall-through; `#!/bin/sh -eu` strict mode; explicit `case` handling (applies to all code work).
- `workaholic:implementation` / `policies/command-scripts.md` — every script must run identically for dev, CI, and a bash-less container; this is the core of the conversion.
- `workaholic:implementation` / `policies/containerization.md` — local = CI = production parity on a minimal Alpine image; the Alpine rationale behind `rules/shell.md`.
- `workaholic:implementation` / `policies/observability.md` — fail-loud: strict mode surfaces failures; JSON-emitting scripts keep emitting well-formed output.
- `workaholic:operation` / `policies/ci-cd.md` — reproducible local + CI verification: the same `build.mjs`/`verify.mjs`/`validate-metadata.mjs`/`test-workflow-scripts.mjs` gate; the committed `outputs/` diff is the regression check.

Repo-own rules (CLAUDE.md): the hard rule **`plugins/workaholic/rules/shell.md`** (`#!/bin/sh -eu`
**and** explicit `set -eu`); **Outputs Freshness** (regenerate + commit `outputs/` and
`hooks/policy-index.md` whenever a shipped script closure changes); **Shell Script Principle**
(no bashisms in markdown); **Skill Script Path Rule / Plugin Boundary Rule** (edit only
`plugins/workaholic` source via `${CLAUDE_PLUGIN_ROOT}`; never the marketplace copy).

## Key Files

Grouped by converter weight (from source discovery). All become `#!/bin/sh -eu` + explicit `set -eu`.

**Heaviest (manual review, mostly uncovered by tests):**
- `plugins/workaholic/skills/system-safety/scripts/detect.sh` — ~10 array-pattern hits (`declare -a`/`=( )`/`${arr[@]}`); the heaviest **array** rewrite → newline-delimited iteration or positional params. Ships into the `drive` closure. No test coverage — highest risk.
- `plugins/workaholic/skills/ship/scripts/backfill-carryover.sh` — 5×`[[ ]]`, 2×array, 1×`${BASH_SOURCE}`, 1×`local`. Second `${BASH_SOURCE}`→`$0` site. Ships into `ship`. No coverage.
- `plugins/workaholic/skills/report/scripts/list-active-carryovers.sh` — 7×`[[ ]]`, 4×`local`. Ships into `report`+`ship`. No coverage.
- `plugins/workaholic/skills/ship/scripts/check-todo.sh` — 3×array → POSIX iteration. Ships into `ship`. No coverage.
- `plugins/workaholic/skills/trip-protocol/scripts/find-gitignored-files.sh` and `sync-gitignored-files.sh` — 1×`<<<` each → pipe. Claude-only. No coverage.
- `plugins/workaholic/skills/trip-protocol/scripts/validate-dev-env.sh` — 1×array, 2×`local`. Claude-only.

**Medium (`[[ ]]`/`=~` on git output) — all ship into all four closures, none test-covered except detect-context/check-workspace:**
- `plugins/workaholic/skills/branching/scripts/`: `detect-context.sh` (3×`[[ ]]`, 4×`local`; **test-covered** `testDetectContext`), `check-worktrees.sh`, `list-worktrees.sh`, `list-all-worktrees.sh`, `eject-worktree.sh` (`[[ ]]`+`=~`), `cleanup-worktree.sh` (`local`), `check-workspace.sh` (**test-covered**, 0 bashisms), `adopt-worktree.sh` (0), `ensure-worktree.sh` (0).
- `plugins/workaholic/skills/report/scripts/apply-carryover-verdicts.sh` — 5×`[[ ]]`, 2×array; **test-covered** (`testApplyVerdicts`). Ships `report`+`ship`.
- `plugins/workaholic/skills/ship/scripts/extract-carryover.sh` — 4×`[[ ]]`; **test-covered** (`testExtractCarryover`). Ships `ship`.

**Trivial shebang-swaps (0 bashisms):**
- `plugins/workaholic/hooks/policy-lens.sh` (Claude-only; **test-covered** `testPolicyLens`).
- `plugins/workaholic/skills/check-deps/scripts/check.sh` (drive closure).
- `plugins/workaholic/skills/ship/scripts/`: `publish-release.sh` (**test-covered**), `commit-release-note.sh`, `find-claude-md.sh`, `pre-check.sh`, `merge-pr.sh` (1×`local`).
- `plugins/workaholic/skills/trip-protocol/scripts/`: `init-trip.sh`, `log-event.sh`, `read-plan.sh`, `trip-commit.sh` (Claude-only).
- `plugins/workaholic/skills/validate-writer-output/scripts/validate.sh` — the only `#!/usr/bin/env bash` → `#!/bin/sh -eu`.

**Build / verification:**
- `scripts/build-plugins/build.mjs` — copies scripts verbatim (no shebang rewrite); run argument-less to regenerate. **No change needed.**
- `scripts/build-plugins/verify.mjs`, `validate-metadata.mjs`, `scripts/test-workflow-scripts.mjs` — the gate.
- `outputs/workflows/skills/{create-ticket,drive,report,ship}/...` — the 21 generated copies that must flip to POSIX after rebuild (CI-guarded by `.github/workflows/outputs-freshness.yml`).

## Related History

Same lineage as the foundation hook ticket; this is the bulk of the re-enforcement.

Past tickets that touched similar areas:

- [20260127103522-posix-shell-compatibility.md](.workaholic/tickets/archive/feat-20260126-214833/20260127103522-posix-shell-compatibility.md) - The origin of `rules/shell.md`; reuse its array→string and length-check recipes verbatim.
- [20260406193606-rename-sh-directories-to-scripts.md](.workaholic/tickets/archive/work-20260406-193458/20260406193606-rename-sh-directories-to-scripts.md) - Why the original ticket's `sh/` paths are now `scripts/`; the corpus moved/grew, which is how bash shebangs re-accumulated.
- [20260319163918-migrate-hardcoded-plugin-paths-to-variable.md](.workaholic/tickets/archive/trip/trip-20260319-040153/20260319163918-migrate-hardcoded-plugin-paths-to-variable.md) - Precedent for a sweeping, path-preserving edit across this same script corpus without breaking inter-script sourcing.

## Implementation Steps

1. **Do the test-covered scripts first** (free regression net): `branching/detect-context.sh`, `branching/check-workspace.sh`, `ship/publish-release.sh`, `report/apply-carryover-verdicts.sh`, `ship/extract-carryover.sh`, `hooks/policy-lens.sh`. Convert each (shebang + `set -eu`, then any `[[ ]]`/`=~`/array/`local`), running `node scripts/test-workflow-scripts.mjs` after each to confirm green.
2. **Convert the uncovered shipped scripts under manual review**: the remaining `branching/` worktree scripts (×7), `check-deps/check.sh`, `system-safety/detect.sh` (the array-heavy one), `report/list-active-carryovers.sh`, and the `ship/` scripts (`backfill-carryover.sh`, `check-todo.sh`, `commit-release-note.sh`, `find-claude-md.sh`, `merge-pr.sh`, `pre-check.sh`). For each, eyeball the JSON it emits before/after with a crafted input and diff the output.
3. **Convert the Claude-only scripts**: `trip-protocol/scripts/*` (×7) and `validate-writer-output/scripts/validate.sh`. The two `<<<` sites (`find-gitignored-files.sh`, `sync-gitignored-files.sh`) become `printf '%s\n' … | while read`; mind the subshell if any `exit`/accumulation happens inside.
4. **Apply the standard rewrites** consistently (per `rules/shell.md` and the 20260127103522 playbook): `[[ x =~ re ]]`→`case`/`grep -qE`; `[[ -z/-n/-f ]]`→`[ ]`; bash arrays→newline-delimited strings iterated with `printf|while read` or positional params (`set -- …`); `${arr[@]}`/`${#arr[@]}`→iteration / `[ -n ]`; `${BASH_SOURCE}`→`$0`; drop `local`; audit each for `set -u` safety (`${VAR:-}`).
5. **Regenerate the bundle**: run the **argument-less** `node scripts/build-plugins/build.mjs`. Confirm the 21 shipped copies under `outputs/workflows/` now show `#!/bin/sh -eu` (the source flip propagated) and `hooks/policy-index.md` is unchanged-or-regenerated cleanly.
6. **Run the full local gate**: `node scripts/build-plugins/verify.mjs` (self-contained), `node scripts/build-plugins/validate-metadata.mjs` (manifests aligned), `node scripts/test-workflow-scripts.mjs` (all green). Stage `plugins/` **and** the regenerated `outputs/` together.

## Considerations

- **Outputs lockstep is mandatory** for the 21 shipped scripts: source + `outputs/` must be committed together or `.github/workflows/outputs-freshness.yml` fails. The Claude-only 9 produce no `outputs/` diff — if they do, the build closure changed unexpectedly. (`scripts/build-plugins/build.mjs`)
- **Arrays are the main semantic rewrite, not the shebang.** `system-safety/detect.sh` (~10 array hits) and `check-todo.sh` need real restructuring to newline-delimited iteration; a blind shebang swap would break them under dash. Neither is test-covered — verify their JSON output by hand. (`plugins/workaholic/skills/system-safety/scripts/detect.sh`, `plugins/workaholic/skills/ship/scripts/check-todo.sh`)
- **`set -u` on optional vars.** Many JSON-emitting scripts read optional inputs; guard with `${VAR:-}` so `-u` does not abort on a legitimately-absent value.
- **The harness runs under `bash`** so it cannot prove POSIX-compliance for the ~24 uncovered scripts — manual `sh`/`dash` execution during development is the real check until the gate-hardening ticket (`20260627153248`) switches the harness to `sh`. Do not rely on bash-only green.
- **`<<<` subshell trap** in the two trip-protocol scripts: a piped `while` runs in a subshell; if the loop accumulates state or exits, restructure so the effect survives the pipe. (`plugins/workaholic/skills/trip-protocol/scripts/find-gitignored-files.sh`)
- **Behavior-preserving refactor**: identical exit codes, JSON shape, and stderr. The `drive`/`report`/`ship` critical path runs these in production, so a regression is high-impact.
- **Independent of the `validate-ticket.sh` ticket** (`20260627153246`): disjoint files (that hook vs these scripts), so no ordering dependency — but the gate-hardening ticket depends on **both** completing.

## Final Report

Development completed as planned. All 30 remaining scripts are now `#!/bin/sh -eu` + explicit
`set -eu`, leaving zero bash shebangs anywhere under `plugins/workaholic/` (and zero in the
regenerated `outputs/workflows/` bundle). The 21 shipped copies flipped automatically via the
argument-less `build.mjs` (it copies shebangs verbatim). Full gate green: `verify.mjs`
(self-contained), `validate-metadata.mjs` (version-aligned), and `test-workflow-scripts.mjs`
(140/0). Every script was spot-run under `sh` and produced byte-identical output to the bash
original. 80 files changed (30 source + 50 outputs).

### Discovered Insights

- **Insight**: The recurring correctness hazard was **not** the shebang but bash's
  `< <(process substitution)`, which several scripts (check-worktrees, list-worktrees,
  list-all-worktrees, eject-worktree) used specifically to keep a `while` loop in the *current*
  shell so its counters/accumulators persist. POSIX has no `< <(...)`, and the naive pipe
  replacement (`cmd | while …`) runs the loop in a subshell and silently loses all mutations.
  The fix is a here-doc fed from a captured variable (`done <<EOF` / `$var` / `EOF`), which keeps
  the loop in the current shell. The same subshell trap governs the `<<<`→pipe and array→loop
  rewrites. Any future POSIX conversion in this repo should reach for the here-doc pattern, not a pipe.
  **Context**: branching worktree scripts, `apply-carryover-verdicts.sh`, `check-todo.sh`,
  `system-safety/detect.sh`, and the two trip-protocol gitignore scripts.
- **Insight**: `echo -n` is a real portability bug, not cosmetic: under dash (the POSIX `/bin/sh`
  on Alpine) `echo -n` prints the literal `-n`. `list-active-carryovers.sh` built its JSON with
  `echo -n` and would have emitted `-n{...}` on Alpine. All such sites became `printf '%s'`.
  Likewise `${var:0:2}` substring slicing (check-workspace) and `${var//a/b}` substitution
  (init-trip) are bash-only and became `cut`/`grep` and `sed`. These silent-wrong-output bugs are
  exactly what a green run under this host's bash-masquerading-as-`sh` cannot catch — reinforcing
  the need for the gate-hardening ticket (`20260627153248`) to run the harness under real `dash`.
  **Context**: a PR #56 carry-over concern (`56-validate-ticket-sh-remains-bash`) flagged the
  POSIX inconsistency this and ticket `20260627153246` resolve; `/report` should mark it resolved.
