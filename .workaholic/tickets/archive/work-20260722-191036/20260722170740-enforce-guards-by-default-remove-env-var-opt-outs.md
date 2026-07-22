---
created_at: 2026-07-22T17:07:40+09:00
author: a@qmu.jp
type: enhancement
layer: [Domain]
effort: 2h
commit_hash:
category: Changed
depends_on:
mission:
---

# Enforce the working-directory and layout guards by default, removing the env-var opt-outs

## Overview

Two guards ship **default-lax with an environment-variable escalation to blocking**:

- `hooks/guard-working-directory.sh` (`PreToolUse(Bash)`) — a top-level cwd-moving `cd` is
  **advisory** by default and blocks (`permissionDecision: "deny"`) only when
  `WORKAHOLIC_ENFORCE_CWD` is set.
- `hooks/validate-ticket.sh` (the `.workaholic/` layout gate) — a `Write`/`Edit` into an
  undesignated `.workaholic/` subdirectory **warns** (allows) by default and blocks (exit 2)
  only when `WORKAHOLIC_STRICT_LAYOUT` is set (or a committed `.workaholic/.strict-layout`
  marker exists).

**The env-var toggle is the wrong design for a guard.** It is a per-machine / per-shell
prerequisite that **fails open whenever it is not set** — a fresh clone, a different machine, a
differently-launched session, or a forgotten export all silently revert the guard to lax. The
configuration is absent exactly when the guard is needed. `.envrc`/direnv does not fix this: it
is another prerequisite (direnv installed, `direnv allow`, correct directory, evaluated before
launch and propagated to the hook subprocess) equally absent off the happy path. Moreover an LLM
agent **ignores advisory text** — the opt-in-blocking work
(`tickets/archive/.../20260720153729-guard-working-directory-opt-in-blocking.md`) already
recorded that "this advisory is insufficient to hold an agent to the ground rule" — so
default-advisory is structurally weak for the agent case these guards exist to constrain.

**Change: make both guards enforced (blocking) by default, with enforcement unconditional in
the plugin code** — so "plugin installed = guard active", zero prerequisite, identical on every
machine and fresh clone. Remove `WORKAHOLIC_ENFORCE_CWD` and `WORKAHOLIC_STRICT_LAYOUT`
entirely; there is no injectable environment-variable opt-in/opt-out. The **match sets are
unchanged** — a `( cd ... )` subshell, an absolute-path command, and a tool prefix
(`npm --prefix ...`) still pass the cwd guard silently, and the layout gate still fires only on
an undesignated subdirectory (ticket-shape and ticket-location rules stay always-blocking as
they are today).

## Prerequisite (blocks the layout flip) — the allowlist has already drifted

`.workaholic/strategies/` is a live, first-class artifact — the `workaholic:strategy` skill and
its `strategy/scripts/create.sh` write to `.workaholic/strategies/active/` — yet `strategies`
is **absent from both sources of truth**: `hooks/workaholic-layout-allowlist.txt` and the table
in `rules/workaholic.md`. Flipping the layout gate to default-block **without fixing this would
hard-block legitimate strategy writes**. So, in the same change (or a preceding step):

- Add `strategies` to `hooks/workaholic-layout-allowlist.txt` and to the mirror table in
  `rules/workaholic.md`.
- Run `hooks/layout-doctor.sh` against a real tree and reconcile **any** other live-but-unlisted
  directory before enabling the block.

(The policy that should have prevented this drift is the companion request; this ticket only
fixes the concrete allowlist so enforcement is safe to turn on.)

## Policies

- Keep **fail-open on a missing `jq`** in both hooks (a guard that cannot parse its input must
  not brick unrelated Bash). This is an availability safeguard, not an opt-out — no cwd/layout
  relaxation rides on it.
- The `.workaholic/.strict-layout` **file** marker is not an environment variable, but under
  default-block an opt-*in* marker is redundant. Recommended resolution: remove it with the env
  var so **no** opt-out (env or file) survives — matching the "no injectable opt-out" intent.
  The firm directive is the env-var removal; confirm the file-marker removal at implementation.
- This is a hard behavioral change, stated as a redefinition (the default flips), not a
  migration with a deprecation window.

## Quality Gate

- `WORKAHOLIC_ENFORCE_CWD` and `WORKAHOLIC_STRICT_LAYOUT` no longer appear anywhere in
  `plugins/` (grep-clean): not in the two hooks, not in `skills/workaholify/SKILL.md`,
  `commands/workaholify.md`, or `rules/workaholic.md`.
- A top-level cwd-moving `cd` is **denied** by `guard-working-directory.sh` with no env var set;
  a `( cd ... )` subshell, an absolute path, and a `--prefix` command still pass silently.
- A `Write`/`Edit` into an undesignated `.workaholic/` subdirectory is **blocked** by
  `validate-ticket.sh` with no env var and no marker; `strategies/` (and any directory
  `layout-doctor.sh` surfaces) is in the allowlist and the `rules/workaholic.md` table, so a
  legitimate strategy write passes.
- The hermetic tests are updated: the former advisory-mode / env-var / `.strict-layout` cases
  become default-deny cases; the suite is green.
- The docs describing the retired two-mode design are rewritten to the single enforced mode
  (`skills/workaholify/SKILL.md`, `commands/workaholify.md`, `rules/workaholic.md`).
- The plugin `version` fields are bumped per CLAUDE.md.

## Final Report

Development completed as planned. Both guards now block unconditionally (enforcement built into the plugin code, no injectable opt-out); `WORKAHOLIC_ENFORCE_CWD`, `WORKAHOLIC_STRICT_LAYOUT`, and the `.strict-layout` marker are removed and grep-clean across `plugins/`. The allowlist prerequisite was reconciled against a real `layout-doctor` run, and the retired two-mode design was rewritten out of every doc that described it.

### Discovered Insights

- **Insight**: `layout-doctor` surfaced more than the ticket's named `strategies` drift — `guides/` and `policies/` (live, git-tracked directories documented in `.workaholic/README.md` as project-local docs areas) and the release-scan root files `scan-allow`/`leak-denylist`. The ticket's Quality Gate ("any directory layout-doctor.sh surfaces is in the allowlist and the table") resolved the reconciliation without a developer decision.
  **Context**: The allowlist's stated "grounded in code" invariant (every entry created/read by a plugin script) does not hold for `guides/`/`policies/` — they are conventional documentation areas, not plugin artifacts. The allowlist comment now records this exception explicitly so a future maintainer running the grounding grep isn't surprised. The allowlist is permissive (permits, does not require), so consumers without those dirs are unaffected.
- **Insight**: Flipping `guard-working-directory.sh` to blocking took effect on the running session immediately — a subsequent top-level `cd` in this very drive was denied. Live-editing an active `PreToolUse(Bash)` guard changes the current agent's own tooling mid-run; use `( cd … )` subshells or absolute paths after such a change.
