---
created_at: 2026-06-18T18:22:53+09:00
author: a@qmu.jp
type: housekeeping
layer: [Config, Infrastructure]
effort:
commit_hash:
category:
depends_on:
---

# Polish `/trip`: catch the trip surface up to recent architectural changes

## Overview

The `/trip` command surface — `commands/trip.md`, the `trip-protocol` skill, and the `planner`/`architect`/`constructor` Agent Teams members — already absorbed the single-plugin merge (it uses `workaholic:` namespaces, the anti-spelunking notice, and same-plugin `${CLAUDE_PLUGIN_ROOT}` paths with no `dist/`, `core:`, `standards:`, or `work:` references). But it has fallen behind on three concrete, post-merge changes that the other four workflow commands picked up. This ticket reconciles the trip surface with current reality without altering the trip protocol's behavior:

1. **Always-on policy lens.** `/trip` is the only workflow command outside the `hooks/policy-lens.sh` scope: `commands/trip.md` carries neither the `<!-- workaholic:policy-lens -->` marker nor a **Policy Lens** section, even though `trip-protocol` already soft-preloads the four policy skills. Add the marker and section so the lens fires for `/trip` like `/ticket`, `/report`, and `/ship`.
2. **Stale Trip Ship order.** `trip-protocol`'s **Trip Ship flow** still describes the pre-reorder ship essence (`pre-check → merge → extract carry-overs → deploy → verify`), directly contradicting the current `workaholic:ship` flow where the merge is the **last** step, gated on a pre-merge production confirmation with the `.workaholic/deployments/` hard gate. Rewrite that step so the trip-side prose mirrors the deploy-confirm-before-merge order.
3. **Obsolete plugin-name residue.** `trip-protocol`'s "Shell Scripts" table labels script homes as `core`/`work` (obsolete plugin names) and line 205 says the owning plugin is `(core)`. Relabel to the single `workaholic` plugin / owning skill.

Verified **not** drifted (no change required): the trip files reference no `todo/` path, so the per-user `todo/<user>/` queue migration does not affect trip prose; and the three Agent Teams members remain consistent with the current `## Architecture Policy` (Agent Teams exemption, one-level work, the "no new agents" completion rule).

## Key Files

- `plugins/workaholic/commands/trip.md` - Thin command entry; missing the `<!-- workaholic:policy-lens -->` marker and **Policy Lens** section the other four commands carry.
- `plugins/workaholic/skills/trip-protocol/SKILL.md` - Knowledge layer; holds the stale **Trip Ship flow** (line ~316), the `core`/`work` "Shell Scripts" table labels (lines ~35-46), and the `(core)` owning-plugin note (line ~205).
- `plugins/workaholic/hooks/policy-lens.sh` - Always-on lens injector; header comment (lines 2-3, 12-13) and injected context (line 31) enumerate only `/ticket, /report, /ship`. Matching is sentinel-based, so trip.md's marker is what actually opts it in; update the enumeration for accuracy.
- `plugins/workaholic/hooks/hooks.json` - Registers `policy-lens.sh` on `UserPromptSubmit` with no matcher; no change needed (scope lives in the sentinel + which commands carry the marker).
- `plugins/workaholic/skills/ship/SKILL.md` - The current ship reality the Trip Ship flow must mirror (merge last, `.workaholic/deployments/` confirmation gate). Reference only; not edited.
- `plugins/workaholic/agents/{planner,architect,constructor}.md` - Verified consistent; reference only, not edited.

## Related History

The trip surface last changed in the plugin-merge work; every post-merge change since then scoped to ticket/drive/report/ship and the hook/build layer, leaving `/trip` behind on exactly the three items above.

Past tickets that touched these areas:

- [20260617005257-merge-plugins-into-workaholic.md](.workaholic/tickets/archive/work-20260617-000311/20260617005257-merge-plugins-into-workaholic.md) - The merge that last modified trip.md/trip-protocol/agents; explains why they already speak single-plugin but the "Shell Scripts" Location labels were left as `core`/`work`.
- [20260618115347-policy-lens-userpromptsubmit-hook.md](.workaholic/tickets/archive/work-20260618-115347/20260618115347-policy-lens-userpromptsubmit-hook.md) - Added the policy-lens hook scoped to /ticket, /report, /ship — /trip was omitted (the catch-up gap this ticket closes).
- [20260617231848-ship-confirm-in-production-before-merge.md](.workaholic/tickets/archive/work-20260617-231848/20260617231848-ship-confirm-in-production-before-merge.md) - Reordered /ship so deploy+confirm precede the merge; the Trip Ship flow predates this.
- [20260617210615-require-verified-deployment-confirmation-in-ship.md](.workaholic/tickets/archive/work-20260617-210627/20260617210615-require-verified-deployment-confirmation-in-ship.md) - Introduced the `.workaholic/deployments/` hard gate the rewritten Trip Ship flow must name.
- [20260617000302-rename-dist-to-outputs.md](.workaholic/tickets/archive/work-20260617-000311/20260617000302-rename-dist-to-outputs.md) - The `dist/`→`outputs/` rename (trip surface verified clean of `dist/`, but the same era left the `core`/`work` labels).
- [20260526011417-delete-task-subagent-files-and-update-architecture-policy.md](.workaholic/tickets/archive/work-20260518-235327/20260526011417-delete-task-subagent-files-and-update-architecture-policy.md) - Codified the one-level fan-out policy and the Agent Teams exemption for /trip's members — the rule the agents must stay consistent with (verified: they do).
- [20260403230427-unify-trip-report-to-drive-format.md](.workaholic/tickets/archive/drive-20260403-230430/20260403230427-unify-trip-report-to-drive-format.md) - Unified the trip report to the drive story format; the /report handoff contract (verified current).
- [20260309214650-implement-trip-command.md](.workaholic/tickets/archive/drive-20260302-213941/20260309214650-implement-trip-command.md) - Original /trip implementation; the foundational spec.

## Implementation Steps

1. **Add the policy lens to `/trip`** (`commands/trip.md`):
   - Insert the `<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->` comment immediately after the `# Trip` heading (same position as `commands/ship.md`).
   - Add a **Policy Lens** section near the end of the file, pointing at `workaholic:planning`/`design`/`implementation`/`operation` and noting that `trip-protocol` already soft-preloads them — phrased to fit the trip workflow (plan/design/build phases), not copied verbatim from the other commands.
2. **Update the hook's enumeration for accuracy** (`hooks/policy-lens.sh`): include `/trip` in the header comment (lines 2-3) and the injected `context` string (line 31), and change "three workflow commands" (line 12) to "four". Behavior is unchanged — matching is on the `workaholic:policy-lens` sentinel; this only keeps the prose honest. Do not add inline conditionals or otherwise touch the matching logic.
3. **Rewrite the Trip Ship flow step 2** (`trip-protocol/SKILL.md`, line ~316) to mirror the current ship order: pre-check → catch up with `main` → deploy (gated on a `.workaholic/deployments/` confirmation method or `CLAUDE.md` `## Verify`, halting if none) → execute the confirmation and record evidence → **merge LAST** → publish release / extract carry-overs, noting that a failed confirmation leaves the PR unmerged. Keep step 1 (gitignored sync) before it and steps 3-4 (cleanup, summarize) after it.
4. **Relabel obsolete plugin names** (`trip-protocol/SKILL.md`):
   - In the "Shell Scripts" table (lines ~37-46), change the `Location` column from `core`/`work` to the owning skill: `branching` for `ensure-worktree.sh`/`cleanup-worktree.sh`/`list-worktrees.sh`, `trip-protocol` for the rest (consistent with the "Script base paths" block at lines 48-50).
   - Fix the inaccurate header at line 33 ("All scripts use absolute paths from home directory.") to describe the `${CLAUDE_PLUGIN_ROOT}` same-plugin form actually used.
   - Change "(core)" to "(workaholic)" at line 205.
5. **Verify**: `node scripts/build-plugins/verify.mjs` and `node scripts/build-plugins/validate-metadata.mjs` (trip is excluded from the `outputs/` build, so no rebuild/`outputs/` diff is expected — confirm `git status outputs/` stays clean). Optionally exercise the policy-lens hook: confirm a prompt carrying the new trip marker is matched by `policy-lens.sh` (the `*workaholic:policy-lens*` case) and a trip prompt without it still no-ops.

## Patches

> **Note**: Line numbers are approximate; apply by context.

### `plugins/workaholic/commands/trip.md`

```diff
--- a/plugins/workaholic/commands/trip.md
+++ b/plugins/workaholic/commands/trip.md
@@
 # Trip
 
+<!-- workaholic:policy-lens — opts this command into the always-on engineering-policy lens injected by hooks/policy-lens.sh (UserPromptSubmit). Keep this marker. -->
+
 **Notice:** When user input contains `/trip` -- whether "run /trip", "start /trip", "take a /trip", or similar -- they likely want this command.
@@
 Follow the preloaded **workaholic:trip-protocol** skill `## Trip Command Procedure` for the full five-step orchestration: Pre-check, Create or Resume Trip, Initialize Trip Artifacts, Validate Dev Environment, Launch Agent Teams (with verbatim team-lead instruction), Present Results.
+
+**Policy Lens**: The `hooks/policy-lens.sh` UserPromptSubmit hook injects the engineering-policy lens automatically on every `/trip` run — load and apply `workaholic:planning`, `workaholic:design`, `workaholic:implementation`, and `workaholic:operation` so the trip's planning, design, build, and ship-handoff decisions are judged against the project's policies. The `workaholic:trip-protocol` skill already soft-preloads these; the marker above makes the lens always-on for `/trip`, consistent with the other workflow commands.
```

### `plugins/workaholic/hooks/policy-lens.sh`

```diff
--- a/plugins/workaholic/hooks/policy-lens.sh
+++ b/plugins/workaholic/hooks/policy-lens.sh
@@
 # UserPromptSubmit hook: the always-on engineering-policy LENS for the Workaholic
-# workflow commands (/ticket, /report, /ship).
+# workflow commands (/ticket, /report, /ship, /trip).
@@
-# typed. The three workflow commands therefore opt in by carrying the stable
+# typed. The four workflow commands therefore opt in by carrying the stable
 # sentinel `workaholic:policy-lens` in their markdown; we match on that marker
@@
-context='[Workaholic engineering-policy lens] You are running a Workaholic workflow command (ticket / report / ship). Apply the project'"'"'s engineering policies as your judging lens before you scope, judge, or ship.
+context='[Workaholic engineering-policy lens] You are running a Workaholic workflow command (ticket / report / ship / trip). Apply the project'"'"'s engineering policies as your judging lens before you scope, judge, or ship.
```

### `plugins/workaholic/skills/trip-protocol/SKILL.md`

```diff
--- a/plugins/workaholic/skills/trip-protocol/SKILL.md
+++ b/plugins/workaholic/skills/trip-protocol/SKILL.md
@@ ## Shell Scripts
-All scripts use absolute paths from home directory.
-
-| Script | Location | Usage |
-| ------ | -------- | ----- |
-| `ensure-worktree.sh <trip-name>` | core | Create isolated worktree and branch |
-| `cleanup-worktree.sh <trip-name>` | core | Remove worktree and branch after PR merge |
-| `list-worktrees.sh` | core | List existing worktrees with PR status (JSON) |
-| `init-trip.sh <trip-name> [instruction]` | work | Create artifact directories and plan.md |
-| `validate-dev-env.sh <worktree_path>` | work | Check env files, dependencies, ports |
-| `read-plan.sh <trip-path>` | work | Read plan state as JSON |
-| `trip-commit.sh <agent> <phase> <step> <description>` | work | Commit with `[Agent] description` format |
-| `log-event.sh <trip-path> <agent> <event-type> <target> <impact>` | work | Append to event-log.md |
-| `find-gitignored-files.sh <worktree-path>` | work | Discover gitignored files in a worktree that differ from main (JSON) |
-| `sync-gitignored-files.sh <worktree-path> <main-repo-root> <files-json>` | work | Copy selected gitignored files from worktree to main repo root |
+All script paths use the same-plugin `${CLAUDE_PLUGIN_ROOT}/skills/<name>/scripts/` form (see Script base paths below).
+
+| Script | Location | Usage |
+| ------ | -------- | ----- |
+| `ensure-worktree.sh <trip-name>` | branching | Create isolated worktree and branch |
+| `cleanup-worktree.sh <trip-name>` | branching | Remove worktree and branch after PR merge |
+| `list-worktrees.sh` | branching | List existing worktrees with PR status (JSON) |
+| `init-trip.sh <trip-name> [instruction]` | trip-protocol | Create artifact directories and plan.md |
+| `validate-dev-env.sh <worktree_path>` | trip-protocol | Check env files, dependencies, ports |
+| `read-plan.sh <trip-path>` | trip-protocol | Read plan state as JSON |
+| `trip-commit.sh <agent> <phase> <step> <description>` | trip-protocol | Commit with `[Agent] description` format |
+| `log-event.sh <trip-path> <agent> <event-type> <target> <impact>` | trip-protocol | Append to event-log.md |
+| `find-gitignored-files.sh <worktree-path>` | trip-protocol | Discover gitignored files in a worktree that differ from main (JSON) |
+| `sync-gitignored-files.sh <worktree-path> <main-repo-root> <files-json>` | trip-protocol | Copy selected gitignored files from worktree to main repo root |
@@ ## Trip Command Procedure
-Procedural body for `/trip` (executed from the work-side command via this preloaded skill). All script paths use same-plugin form because they resolve from this skill's owning plugin (core).
+Procedural body for `/trip` (executed from the work-side command via this preloaded skill). All script paths use same-plugin form because they resolve from this skill's owning plugin (workaholic).
@@ ### Trip Ship flow
 1. **Sync gitignored files** (above) from `.worktrees/<branch>/` to the main repo root.
-2. **Run the ship essence**: follow `workaholic:ship`'s **Ship Flow** (pre-check → merge → extract carry-overs → deploy → verify) for the worktree's branch/PR.
+2. **Run the ship essence**: follow `workaholic:ship`'s **Ship Flow** for the worktree's branch/PR. The merge is the LAST step, gated on a passing pre-merge production confirmation: pre-check → catch up with `main` → deploy (gated on a `.workaholic/deployments/` confirmation method or `CLAUDE.md` `## Verify`; halt-and-ask if none) → execute the confirmation and record evidence → **merge LAST** → publish release / extract carry-overs. A failed confirmation leaves the PR unmerged (that is the rollback).
 3. **Clean up worktree**: `bash ${CLAUDE_PLUGIN_ROOT}/skills/branching/scripts/cleanup-worktree.sh "<branch>"`; report what was cleaned up.
```

## Considerations

- **Implementation policy is the only binding lens** (`workaholic:implementation`): this is Config/Infrastructure documentation work — `directory-structure` (edit `plugins/`, never `.claude/` or `outputs/`) and `coding-standards` apply. `design`/`operation`/`planning` do not bind (no UX, no production runtime/delivery change, not a new feature).
- **Agent Teams exemption holds** — `/trip` and its `planner`/`architect`/`constructor` members are exempt from the Component Nesting and One-Level Fan-Out tables; this ticket must not introduce per-workflow agent files or change the members' role (verified consistent, `plugins/workaholic/agents/`).
- **Shell Script Principle** — keep the policy-lens.sh edits to prose/enumeration only; do not add inline conditionals, pipes, or loops, and do not alter the `case` matching logic (`plugins/workaholic/hooks/policy-lens.sh`).
- **No `outputs/` rebuild** — `/trip` is deliberately excluded from the `outputs/` cross-agent build (Agent Teams, Claude-only), so none of these edits should change `outputs/`; confirm `git status outputs/` stays clean after `build.mjs`. No version bump is implied by this change.
- **Thin command / comprehensive skill** — keep `commands/trip.md` orchestration-only; the Policy Lens addition is a short pointer, and the substantive lens knowledge stays in the policy skills `trip-protocol` already preloads.
- **Sentinel-based matching** — the functional opt-in is the `workaholic:policy-lens` marker in `commands/trip.md`; the `policy-lens.sh` enumeration edits are documentation accuracy only, so the two must land together to avoid a command that claims the lens in prose but isn't matched (`plugins/workaholic/hooks/policy-lens.sh`).
