---
created_at: 2026-09-06T02:28:55+09:00
status: done
author: a@qmu.jp
assignees: [a@qmu.jp]
depends_on:
mission: report-each-tick-in-the-originating-codex-chat
merge_policy:
verification_handoff: 
---

# Retire only the supervisor the native mode replaces

## Overview

Switching a repository from the external CLI supervisor to the native-parent branch while a
supervisor is still running leaves **two coordinators** against one repository — the state
`work/SKILL.md` already forbids for the desktop schedule and the CLI supervisor
(*Never run the desktop schedule and CLI supervisor against one repository at once*).

The cutover must therefore identify and retire **only that coordinator**, and account for the
workers it started, rather than stopping whatever it finds or leaving orphans behind. And the
external supervisor is **not deleted**: it stays as an explicitly different mode, with its
limitation written on its face.

## Policies

- `workaholic:implementation` / `policies/coding-standards.md` — style and structure conventions
- `workaholic:operation` — delivery paths and runtime behaviour of a running loop

## Key Files

- `plugins/workaholic/skills/work/SKILL.md` — the modes and the never-both rule, which gains
  the cutover procedure.
- `plugins/workaholic/skills/work/reference/other-agents.md` — *Running it from Codex CLI or the
  IDE*, which keeps the supervisor and states what it does not deliver.
- `plugins/workaholic/skills/work/scripts/codex-loop.sh` — the supervisor, its `--status`
  reading and its per-role locks, which are how a running coordinator and its workers are found.
- `scripts/codex-loop.sh` — the repository-local compatibility shim.

## Implementation Steps

1. Write the **cutover procedure**: before starting the native-parent branch, identify the
   coordinator being replaced through the supervisor's own `--status` reading, account for the
   workers it started, and retire that one — never a broader sweep of processes, and never a
   silent start beside a coordinator that is still running.
2. State what happens to a **worker still running** at cutover: it is named in the startup
   report and left to finish, and its role is not dispatched natively until it has, so no unit
   is driven twice.
3. Keep the external supervisor as an **explicitly different mode** whose row says plainly that
   its output is **not** claimed to reach the invoking conversation. Deleting it is refused: a
   cron or systemd environment with no conversation at all is exactly what it is for.
4. State the non-promise: no continuation is claimed after app closure, cancellation, or a hard
   harness limit, unless a resumption mechanism has been **tested**. An untested resumption is
   named as untested.
5. Record the never-both rule for this pair as it is already recorded for the desktop schedule
   and the CLI supervisor — one sentence, in the same place, rather than a second convention.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- The cutover procedure identifies one coordinator and accounts for its workers before starting.
- A worker still running at cutover is named and left to finish, and its role is not dispatched
  natively until it is done.
- The external supervisor still exists as a mode, and its row states that its output does not
  reach the invoking conversation.
- No promise of continuation after closure or cancellation appears anywhere without a tested
  mechanism named beside it.

**Verification method** — the commands/tests/probes that prove them:

- `node scripts/test-workflow-scripts.mjs`
- `node scripts/build-plugins/build.mjs && node scripts/build-plugins/verify.mjs`
- `sh scripts/codex-loop.sh --status` reads state and starts nothing.

**Gate** — what must pass before approval:

- `codex-loop.sh`'s behaviour is unchanged; this ticket documents the cutover and does not
  rewrite the supervisor.

## Considerations

- The supervisor's per-role locks are visible across runs that cannot see each other's agents,
  which is precisely why they are the instrument for finding what to retire.

## Final Report

Development completed as planned.

`work/SKILL.md` gains *Cutting over from the external supervisor*: identify the one coordinator
being replaced through `codex-loop.sh --status` (which reads state and starts nothing), account
for its workers, retire that one and nothing else; a worker still running is named in the startup
report, left to finish, and its role is not dispatched natively until it has. `other-agents.md`'s
*Running it from Codex CLI or the IDE* now opens with why the supervisor is kept and what it does
not promise, and the never-both sentence already in that file was **extended in place** to cover
this pair rather than becoming a second convention.

**The gate held**: `git diff` over `plugins/workaholic/skills/work/scripts/codex-loop.sh` and
`scripts/codex-loop.sh` is empty. The cutover reads the supervisor and rewrites nothing.
`sh scripts/codex-loop.sh --status` was run and reported `absent` with three idle workers,
starting nothing.

### Discovered Insights

- **Insight**: the per-role locks are the instrument for finding what to retire precisely because
  they are visible to a run that cannot see the previous run's agents.
  **Context**: it is the same property that made them the substitution for `ListAgents`, used for
  a second purpose — so the cutover needs no new mechanism, and a reader tempted to add a process
  scan should know a narrower reading already exists.
- **Insight**: refusing to delete the supervisor is a statement about environments, not about
  compatibility.
  **Context**: the native-parent branch needs a conversation to report into, and a cron entry has
  none — so the supervisor is not a legacy path being tolerated, it is the correct mode for a case
  the new one structurally cannot serve.
