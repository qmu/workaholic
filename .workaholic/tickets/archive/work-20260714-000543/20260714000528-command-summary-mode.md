---
created_at: 2026-07-14T00:05:28+09:00
author: a@qmu.jp
type: enhancement
layer: [Infrastructure]
effort: 2h
commit_hash: 651bc53
category: Added
depends_on:
mission:
---

# Add `summary` Mode to /ticket, /trip, and /mission

## Overview

Give `/ticket`, `/trip`, and `/mission` a read-only **summary** mode that reports the current developer's *assigned work* for that command's own domain, instead of doing the command's usual action.

Trigger (decided with the developer — the only collision-free uniform contract):

- The explicit argument `summary` triggers the mode on all three: `/ticket summary`, `/trip summary`, `/mission summary`.
- Additionally, **bare `/ticket`** (empty argument) maps to summary, because `/ticket`'s empty-argument slot is currently free (it would otherwise attempt to spec an empty description).
- **Bare `/trip` and bare `/mission` are unchanged**: bare `/trip` keeps its context-aware queue-execute / design / nag routing, and bare `/mission` keeps listing *all* missions with computed progress. A summary on these two is reachable **only** via the explicit `summary` argument.

Scope is **per-domain** — each command summarizes its own lane, all scoped to the current user (`git config user.email` → `user-slug.sh`; missions matched by `assignee == user.email`):

- `/ticket summary` — the current user's assigned todo tickets: `.workaholic/tickets/todo/<user-slug>/*.md`, each with title, `type`, `layer`, and `depends_on`.
- `/mission summary` — the current user's assigned **active** missions with computed `checked/total` progress and the next unchecked `## Acceptance` item.
- `/trip summary` — the current user's in-flight trips (`.workaholic/trips/`) plus a snapshot of the todo queue a `/trip` would execute.

This is a **capability the developer requested**; there is no queue duplicate. It overlaps in spirit with `/catch` (by-*all*-developer, window-based report) and the always-on `mission-lens` hook, but neither gives a current-user, per-command, on-demand snapshot — so this is additive, and it must **reuse** their underlying scripts rather than author a fourth summarizer.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the summary logic and its read paths must follow the conventional plugin layout (knowledge + scripts under `skills/<name>/scripts/`, referenced via `${CLAUDE_PLUGIN_ROOT}`); applies to all code work.
- `workaholic:implementation` / `policies/coding-standards.md` — new/edited shell is POSIX `#!/bin/sh -eu`, no bashisms, machine-checked by `posix-lint.sh` and the dash-run smoke tests; applies to all code work.
- `workaholic:implementation` / `policies/objective-documentation.md` — the summary is **computed** from the ticket/mission/trip tree (like mission progress derived from `## Acceptance`), never a stored or guessed count; every reported number must be re-derivable from the filesystem.
- `workaholic:design` / `policies/modeless-design.md` — the `summary` argument (and bare `/ticket` mapping to summary) is a low-friction, self-explanatory default that must not silently change the two existing bare contracts (`/mission` list, `/trip` queue-execute).

## Key Files

- `plugins/workaholic/commands/ticket.md` - Add a pre-dispatch branch: when `$ARGUMENT` is empty or `summary`, run the summary section instead of the create-ticket workflow (respecting the "NEVER implement" guardrail — summary is read-only). Claude-only; no rebuild.
- `plugins/workaholic/commands/mission.md` - Add `summary` as a fourth dispatch mode (alongside empty=list, title=create, `close <slug>`=close). Bare stays list. Claude-only; no rebuild.
- `plugins/workaholic/commands/trip.md` - Route the explicit `summary` argument to the summary section **before** trip-protocol's "Determine execution mode" step, so queue-execute/design/nag routing is untouched. Claude-only; no rebuild.
- `plugins/workaholic/skills/create-ticket/SKILL.md` - Home for the `/ticket summary` section (the knowledge layer). **Built** into `outputs/workflows` → requires `build.mjs`.
- `plugins/workaholic/skills/mission/SKILL.md` - Home for the `/mission summary` section. **Built** → requires `build.mjs`.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - Home for the `/trip summary` section. Agent-Teams/Claude-only, **excluded** from the build → no rebuild.
- `plugins/workaholic/skills/gather/scripts/user-slug.sh` - Canonical current-user identity (`git user.email` → slug); the summary's "assigned to me" filter must derive identity through this, never reimplement it.
- `plugins/workaholic/skills/drive/scripts/list-todo.sh` - Existing enumerator of the current user's `todo/<user-slug>/` queue — reuse directly as the `/ticket summary` core.
- `plugins/workaholic/skills/mission/scripts/list.sh`, `progress.sh`, `next-acceptance.sh` - Existing mission enumeration + computed progress + next acceptance item; the `/mission summary` core (filter `list.sh` output to `assignee == user.email`, `status: active`).
- `plugins/workaholic/skills/catch/scripts/scan-window.sh` - Precedent for joining a developer's tickets+missions+commits; model the summary's join logic on it (do not run the full window scan for a per-user snapshot).
- `scripts/test-workflow-scripts.mjs` - Add the hermetic exact-set assertion (see Quality Gate).
- `CLAUDE.md`, `README.md`, `.workaholic/README.md` - Commands tables / behavior docs updated in the same commit (doc-update rule).

## Related History

The three commands already diverge on what a bare/empty argument means, which is exactly why the summary trigger cannot be uniform bare invocation: `/mission` bare already lists missions, `/trip` bare already runs context-aware queue-execute, and `/ticket` requires a description. The existing `/catch` report and the `mission-lens` hook already summarize per-user assigned work through `user-slug.sh`, `list.sh`/`progress.sh`/`next-acceptance.sh`, and `drive/list-todo.sh` — this ticket composes those primitives rather than adding a new ownership rule.

Past tickets that touched similar areas:

- [20260123030823-sync-doc-specs-command.md](.workaholic/tickets/archive/main/20260123030823-sync-doc-specs-command.md) - Command/skill dispatch and doc-sync (same layer: Infrastructure).
- [20260122150455-ticket-update-first-guidance.md](.workaholic/tickets/archive/main/20260122150455-ticket-update-first-guidance.md) - Changed `/ticket` command behavior (same file: `commands/ticket.md`).

## Implementation Steps

1. **Add the shared/current-user summarizer scripts** under the relevant built skills' `scripts/` dirs (POSIX `#!/bin/sh -eu`, referenced via `${CLAUDE_PLUGIN_ROOT}`), composing existing helpers — do **not** reimplement identity or progress:
   - Tickets: reuse `drive/scripts/list-todo.sh` (already current-user scoped); emit each ticket's title/`type`/`layer`/`depends_on` from frontmatter.
   - Missions: a script that runs `mission/scripts/list.sh` and filters to `assignee == git user.email` and `status: active`, carrying `checked/total` and next acceptance item.
   - Trip: a script listing `.workaholic/trips/` in-flight entries plus the todo-queue snapshot.
2. **Add a `## Summary` section to each skill** (`create-ticket`, `mission`, `trip-protocol`) documenting the mode: what it reports, that it is read-only, and how it formats the output. Knowledge lives in the skills (thin-command principle); the commands only route the argument.
3. **Wire the command dispatch** (thin, ~a few lines each):
   - `ticket.md`: empty **or** `summary` argument → run the create-ticket summary section; otherwise the existing create workflow.
   - `mission.md`: `summary` argument → run the mission summary section (new 4th mode); empty stays list.
   - `trip.md`: `summary` argument → run the trip summary section **before** the execution-mode determination; bare stays context-aware.
4. **Add the hermetic exact-set test** to `scripts/test-workflow-scripts.mjs` (see Quality Gate) covering the current-user filtering for tickets and missions.
5. **Update docs in the same commit**: the Commands tables in `CLAUDE.md` and `README.md`, and `.workaholic/README.md` where command behavior is described — note the `summary` argument, the bare-`/ticket` mapping, and that bare `/mission`/`/trip` are unchanged.
6. **Rebuild + verify**: `node scripts/build-plugins/build.mjs` (create-ticket + mission are built), then `verify.mjs`, `validate-metadata.mjs`, and `test-workflow-scripts.mjs`. trip-protocol changes need no rebuild.

## Quality Gate

**Acceptance criteria** — the checkable conditions that must hold:

- Seed a throwaway repo where user **A** owns tickets `t1,t2` under `todo/a-slug/` and active mission `m1` (assignee A), and user **B** owns ticket `t3` under `todo/b-slug/` and active mission `m2` (assignee B). Running the summary as A enumerates **exactly** `{t1, t2}` for tickets and `{m1}` for missions, and **excludes** `t3` and `m2`. Running as B yields the complementary set.
- `/ticket summary` and bare `/ticket` produce the ticket summary; `/mission summary` produces the mission summary while bare `/mission` still lists all missions; `/trip summary` produces the trip summary while bare `/trip` still performs its existing queue-execute/design/nag routing.
- Every reported mission `checked/total` equals the value recomputed by `progress.sh` for that mission (computed, not stored).

**Verification method** — the commands/tests/probes that prove them:

- A new case in `node scripts/test-workflow-scripts.mjs` builds the two-user throwaway repo, invokes the current-user ticket + mission summarizer scripts as A (and as B), and asserts the exact included/excluded sets above; it never touches the working tree or the network.
- `node scripts/build-plugins/build.mjs` then `node scripts/build-plugins/verify.mjs` run clean (outputs/ in sync); `node scripts/build-plugins/validate-metadata.mjs` passes.
- `posix-lint` passes on every new/edited script.

**Gate** — what must pass before approval:

- The full local suite is green: `build.mjs` produces no `outputs/` diff, `verify.mjs` + `validate-metadata.mjs` + `test-workflow-scripts.mjs` all pass, and posix-lint is clean.
- The three summary modes and the two preserved bare contracts (`/mission` list, `/trip` queue-execute) are demonstrated in-session against this repo.
- The Commands tables in `CLAUDE.md`/`README.md` and `.workaholic/README.md` describe the new mode (doc-drift backstop would otherwise flag it).

## Considerations

- The bare-`/ticket` → summary mapping must not weaken the command's hard "NEVER implement / only create tickets" guardrail — summary is strictly read-only and creates nothing (`plugins/workaholic/commands/ticket.md`).
- Do **not** redefine bare `/mission` or bare `/trip`; a regression there is a breaking change to documented behavior (`plugins/workaholic/commands/mission.md`, `plugins/workaholic/commands/trip.md`, `plugins/workaholic/skills/trip-protocol/SKILL.md` "Determine execution mode").
- Reuse `user-slug.sh` / `list-todo.sh` / mission `list.sh`+`progress.sh`+`next-acceptance.sh` rather than duplicating the identity/ownership rules — a second copy would drift from the queue-routing scripts (`plugins/workaholic/skills/gather/scripts/user-slug.sh`).
- Keep the mode read-only and non-interactive: no `AskUserQuestion`, so no `[<project label>]` prefix obligation; if a prompt is ever added it must carry the label (`hooks/guard-askuserquestion-label.sh`).
- Remember the asymmetric build impact: create-ticket + mission are built into `outputs/workflows` (rebuild required), trip-protocol is not (`scripts/build-plugins/build.mjs`).
- Consider whether `/trip summary`'s value overlaps enough with `/catch` and the mission-lens that it should instead defer to `/catch` for the trip view — decide during implementation, but the ticket's default is the per-domain trip snapshot (`plugins/workaholic/skills/catch/SKILL.md`).

## Final Report

Development completed as planned. All three summary modes were wired (bare `/ticket` + `/ticket summary`, `/mission summary`, `/trip summary`), the two preserved bare contracts (`/mission` list, `/trip` queue-execute) were left untouched, docs updated, and the hermetic two-user exact-set test added (8 assertions; full suite 440 passed / 0 failed; build/verify/validate-metadata/posix-lint clean).

### Discovered Insights

- **Insight**: Reusing another skill's script pulls that skill's entire build closure into the reusing skill's `outputs/workflows` bundle. `create-ticket/scripts/summary.sh` calling `drive/scripts/list-todo.sh` expanded create-ticket's built closure to `[branching, check-deps, commit, create-ticket, drive, gather, mission, okf, system-safety]`, adding several new bundled `scripts/` dirs under `outputs/workflows/skills/create-ticket/`.
  **Context**: `build.mjs`'s `computeClosure` is transitive over `${SCRIPT_DIR}/../../<x>/scripts/` references, so a single cross-skill reuse can materially grow the committed outputs. It's correct (self-containment) and auto-handled, but any future cross-skill script reuse should expect a larger `outputs/` diff and a bigger portable bundle — weigh that against inlining a tiny helper.
- **Insight**: A `summary` keyword mode must be dispatched **before** a command's "non-empty argument = create/title" branch, or the literal word `summary` is swallowed as content (a mission titled "summary", an empty-description ticket). The three commands each needed the summary check ordered ahead of their existing arg handling.
  **Context**: `/mission`'s create branch treats any non-empty `$ARGUMENT` as a title, so `commands/mission.md` explicitly documents "match `summary` first"; the same ordering rule applies to `/trip` (route `summary` before "Determine execution mode") and `/ticket` (short-circuit before the create workflow).
