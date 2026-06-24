---
created_at: 2026-06-24T14:02:07+09:00
author: a@qmu.jp
type: enhancement
layer: [Config]
effort:
commit_hash: 31dec7f
category: Added
depends_on:
---

# Harden ticket-structure enforcement so /ticket and /drive cannot create non-canonical ticket locations

## Overview

A consumer repo accumulated ticket-management rule violations under `.workaholic/tickets/`: an invented `done/` directory, archives nested at `todo/<user>/archive/`, and root-level `todo/` strays. Root cause was a combination of (a) running stale split plugins (`core`/`standards`/`work` v1.0.50) and (b) the fact that the only structural enforcement, `validate-ticket.sh`, is a **PostToolUse `Write|Edit`** hook and therefore never sees `bash mv`/`mkdir` — which is exactly how `archive.sh` and hand-built `done/` directories operate.

This ticket closes that enforcement gap with two changes, plus doc/test updates, so the same drift cannot recur on the current `workaholic` plugin:

1. **Tighten `validate-ticket.sh` location rules** — require `todo/<user>/` (reject root-level `todo/` strays), recognize `abandoned/` as canonical (currently a latent bug: abandoned tickets are rejected), and keep rejecting non-canonical subdirs like `done/` and nested `todo/<user>/archive/`.
2. **Add a PreToolUse `Bash` guard `guard-ticket-structure.sh`** (registered in `hooks.json`) that blocks `mv`/`cp`/`mkdir`/redirect commands placing a ticket into a non-canonical location under `.workaholic/tickets/` — the blind spot the Write/Edit hook misses.

Note: the companion fix of migrating the consumer repo's `.claude/settings.json` off the obsolete plugins onto `workaholic@workaholic` with `autoUpdate: true` has already been applied directly in that repo (different repo, config-only); this ticket covers only the reusable enforcement hardening in the `workaholic` plugin source.

## Policies

- `workaholic:implementation` / `policies/directory-structure.md` — the guard enforces "find files from structure, not exploration": tickets must stay in their canonical `todo/<user>/` | `icebox/` | `abandoned/` | `archive/<branch>/` slots.
- `workaholic:implementation` / `policies/coding-standards.md` — applies to all code work (shell-script style/conventions here).
- `workaholic:implementation` / `policies/policy-conformance-audit.md` — "automated checks as the first layer": this guard converts the canonical-layout policy into a machine-checkable PreToolUse block, the cheapest feedback path that prevents drift before it becomes structural.

## Key Files

- `plugins/workaholic/hooks/validate-ticket.sh` (lines 42-59) — current location-validation block. `^todo/([^/]+/)?[^/]+$` (L48) wrongly accepts root-level `todo/<ticket>.md` because the user segment is optional; there is **no** `abandoned/` arm so abandoned tickets hit the `else` and are rejected. Tighten to `^todo/[^/]+/[^/]+$`, add an `abandoned/` arm, update the error message at L55. The trailing `[^/]+$` already rejects deeper `todo/<user>/archive/...` nesting.
- `plugins/workaholic/hooks/guard-ticket-structure.sh` — **NEW** PreToolUse Bash guard. Reads stdin JSON, extracts `.tool_input.command`, and exits 2 when a mutating command (`mv`/`cp`/`mkdir`/`touch`/`tee`/`rsync`/redirect) places a ticket into a non-canonical literal location under `.workaholic/tickets/`. Mirror `validate-ticket.sh`'s `print_skill_reference` + exit-code contract.
- `plugins/workaholic/hooks/hooks.json` (lines 3-27) — add a new top-level `PreToolUse` array with matcher `Bash` and command `${CLAUDE_PLUGIN_ROOT}/hooks/guard-ticket-structure.sh` (timeout 10), matching the existing object shape; update the top-level `description`.
- `plugins/workaholic/skills/drive/SKILL.md` (lines 554-559) & `plugins/workaholic/skills/drive/scripts/archive.sh` (lines 32-52) — canonical writers of `abandoned/` and `archive/<branch>/`. The guard must NOT block these: `abandoned/` is allowlisted, and `archive.sh` uses a variable destination (`$ARCHIVE_DIR`) the guard cannot resolve, so variable/glob destinations are passed through.
- `CLAUDE.md` (line 23) — update the `hooks/` description in the Project Structure tree to mention the new `guard-ticket-structure.sh`.
- `scripts/test-workflow-scripts.mjs` — add hermetic smoke coverage for both the tightened `validate-ticket.sh` and the new guard (follow the existing `testPolicyLens` real-invocation pattern).

## Related History

The per-file location check and the per-user `todo/<user>/` convention already exist; this ticket adds the missing **Bash-move** enforcement layer and tightens two latent gaps. Reuse the established exit-2 / `print_skill_reference` discipline and the canonical path rules rather than reinventing them.

Past tickets that touched similar areas:

- [20260518235327-prohibit-tickets-outside-tickets-dir.md](.workaholic/tickets/archive/work-20260518-235327/20260518235327-prohibit-tickets-outside-tickets-dir.md) - Introduced the `validate-ticket.sh` reject-outside-tickets logic and the PostToolUse exit-2 / no-delete-side-effect discipline (same hook, same class of misplacement detection).
- [20260613090209-per-user-todo-subdirectories.md](.workaholic/tickets/archive/work-20260528-122941/20260613090209-per-user-todo-subdirectories.md) - Defined `todo/<user>/`, `sweep-todo.sh`, `archive.sh` path-stripping, and the `^todo/([^/]+/)?[^/]+$` regex this ticket tightens (same files, same invariant).
- [20260128224841-enforce-archive-script-usage.md](.workaholic/tickets/archive/feat-20260128-220712/20260128224841-enforce-archive-script-usage.md) - Addressed the `tickets/done/` invention but **prose-only** (drive SKILL); this ticket supplies the missing machine enforcement.
- [20260618115347-policy-lens-userpromptsubmit-hook.md](.workaholic/tickets/archive/work-20260618-115347/20260618115347-policy-lens-userpromptsubmit-hook.md) - Most recent `hooks.json` change; shows the current structure the new `PreToolUse` array slots into.

## Implementation Steps

1. **Tighten `validate-ticket.sh` location block** (L42-59): change the `todo` arm to `^todo/[^/]+/[^/]+$` (mandatory user segment), add an `elif` arm for `^abandoned/[^/]+$`, and update the error message to list the canonical set (`todo/<user>/`, `icebox/`, `abandoned/`, `archive/<branch>/`) and explicitly name `done/` and root-level `todo/` strays as disallowed. Keep the file `#!/bin/bash` (minimal in-place edit; full POSIX conversion of this legacy file is out of scope — see Considerations).
2. **Write `plugins/workaholic/hooks/guard-ticket-structure.sh`** as POSIX sh (`#!/bin/sh` + `set -eu`) per `rules/shell.md`:
   - Read stdin, `jq -r '.tool_input.command // empty'`.
   - Exit 0 if the command does not reference `.workaholic/tickets/`.
   - Exit 0 unless the command contains a mutating verb (`mv`/`cp`/`mkdir`/`touch`/`install`/`tee`/`rsync`) or an output redirect (`>`/`>>`) — read-only commands (`ls`/`cat`/`grep`/bundled `list-todo.sh`) must pass.
   - Extract every literal `.workaholic/tickets/<path>` token (`grep -oE`). For each, validate the first segment is one of `todo|icebox|abandoned|archive`, reject `todo/.../archive/...` nesting, and reject a bare `todo/<ticket>.md` root destination. Variable/glob destinations (e.g. `$ARCHIVE_DIR`) yield no literal match → pass.
   - On any violation, print a clear stderr message + `See:` skill reference and exit 2; otherwise exit 0.
   - `chmod +x` the script.
3. **Register the guard in `hooks.json`**: add a `PreToolUse` array (matcher `Bash`) before `PostToolUse`, and refresh the top-level `description`.
4. **Update `CLAUDE.md`** line 23 hooks description to mention `guard-ticket-structure.sh` (PreToolUse Bash, blocks non-canonical ticket moves).
5. **Add hermetic tests** to `scripts/test-workflow-scripts.mjs` covering: validate-ticket accepts `todo/<user>/`, `icebox/`, `abandoned/`, `archive/<branch>/` and rejects root-level `todo/` stray, `done/`, and nested `todo/<user>/archive/`; the guard blocks `mv … done/`, `mkdir … done`, nested-archive `mv`, and a redirect into `done/`, and allows canonical archive/todo-user/icebox/abandoned moves, variable destinations, and read-only commands.
6. **Verify**: `bash -n` both scripts, run the guard/validate cases by hand, then `node scripts/test-workflow-scripts.mjs` (all pass). No `outputs/` rebuild is required — hooks are Claude-Code-only and excluded from the build.

## Considerations

- **Guard must not block legitimate writers** (`plugins/workaholic/skills/drive/scripts/archive.sh` lines 32-52): `archive.sh` moves via a variable destination, so the guard inspects **literal** paths only and passes variable/glob destinations. `abandoned/` and `archive/<branch>/` are on the allowlist so drive's abandon step (`drive/SKILL.md` lines 554-559) and archive step are never blocked.
- **Guard must not block read-only commands** (`guard-ticket-structure.sh`): gate on mutating verbs/redirects so `ls`/`cat`/`find`/`git status`/bundled `list-todo.sh` referencing a (possibly messy) tickets tree still pass — otherwise a repo with pre-existing violations becomes unusable.
- **Two enforcement layers, one rule — drift risk** (`validate-ticket.sh` vs `guard-ticket-structure.sh`): the canonical-path rule is now encoded in two scripts. Keep the path-shape rules equivalent and note the duplication so future edits change both.
- **POSIX inconsistency** (`validate-ticket.sh`): `rules/shell.md` mandates POSIX `#!/bin/sh`, but the existing file is `#!/bin/bash` with `[[ ]]`/`=~`. This ticket keeps the minimal in-place tightening in bash and writes the new guard in POSIX sh; a full POSIX rewrite of `validate-ticket.sh` is deferred as separate housekeeping.
- **PostToolUse fail-open** (`guard-ticket-structure.sh`): a `jq`/parse failure on an unrelated command must exit 0 (fail-open) so the guard never blocks non-ticket work; only a confirmed non-canonical ticket destination exits 2.
- **Reaches consumer repos only after release**: with `autoUpdate: true` now set there, the hardened hooks take effect in a consumer repo only once a new plugin version is published via `/release` (separate, outward-facing step).
